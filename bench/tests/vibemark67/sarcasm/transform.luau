--!nonstrict
-- The GIMSO transform (architecture-independent): rewrite a lifted yolo function into a
-- memory-safe Fil-C fast-entrypoint body (IR nodes), plus metadata for glue/prologue/
-- epilogue emission. The walk and every invisicap sequence (access checks, pointer loads/
-- stores with the FUGC store barrier, calls, pollchecks, allocations) live here ONCE; the
-- actual instructions are produced through a per-arch codegen `cg` (arm64_codegen /
-- x86_64_codegen), so the safety-critical logic is single-source across ISAs.
--
-- transformFunction(name, sigDesc, body, backend) where backend = { cg = <codegen module>,
-- frame = <frame module> }.

lift = require("./lift")
ptrflow = require("./ptrflow")
sig = require("./sig")
build = require("./build")
framePass = require("./frame")

transform = {}

-- `;! alloca ...` annotation parser (architecture-independent).
function parseAlloca(ann)
	if not ann then return nil end
	n = string.match(ann, "^alloca%s+size%s*%(%s*(.-)%s*%)$")
	if n then return { kind = "size", name = n } end
	rn = string.match(ann, "^alloca%s+result%s*%(%s*(.-)%s*%)$")
	if rn then return { kind = "result", name = rn } end
	sz = string.match(ann, "^alloca%s+result%s+size=(%w+)$")
	if sz then
		v = tonumber(sz)
		if not v then error("sarcasm: bad alloca size literal: " .. sz) end
		return { kind = "resultSize", size = v }
	end
	if string.find(ann, "alloca", 1, true) then
		error("sarcasm: unrecognized alloca annotation: " .. ann)
	end
	return nil
end

-- The register operand of a store that is not the memory operand (the stored value).
function storeValueOperand(stmt, mem)
	for _, op in stmt.operands do
		if op.kind == "reg" and op != mem then return op end
	end
	return nil
end

function transform.transformFunction(name, sigDesc, body, backend)
	cgm = backend.cg          -- codegen module (static config + make)
	framePolicy = backend.frame  -- per-arch frame policy (analyzeFrame + rewrite)
	cc = cgm.cc

	returnRegs = sigDesc.isVoid and {} or {0}
	funcLine = (body[1] and body[1].line) or 0
	curLine = funcLine

	-- Fixed-size stack allocations establish sp-relative "regions" [base, base+size); gcc -O0
	-- re-derives the buffer address per use, so we redirect such sp math into the allocation.
	allocaRegions = {}
	for _, st in body do
		if st.kind == "insn" then
			al = parseAlloca(st.annotation)
			if al and al.kind == "resultSize" then
				base = cgm.allocaRegionBase(st)
				if base then table.insert(allocaRegions, { base = base, size = al.size, stmt = st }) end
			end
		end
	end
	function regionOf(spOff)
		for _, r in allocaRegions do
			if spOff >= r.base and spOff < r.base + r.size then return r end
		end
		return nil
	end

	body = framePass.preprocess(body, allocaRegions, framePolicy)

	-- per-call signature info
	callSigCache = {}
	function callSigOf(stmt)
		ann = stmt.annotation
		if not ann then return nil end
		if callSigCache[stmt] == nil then callSigCache[stmt] = sig.parseSignature(ann) end
		return callSigCache[stmt]
	end
	function callInfo(stmt)
		cs = callSigOf(stmt)
		if not cs then return nil end
		argRegs = {}
		for k = 1, cs.argWords do table.insert(argRegs, cc.yoloArg(k)) end
		return { argRegs = argRegs, resultReg = cs.isVoid and nil or 0 }
	end

	lf = lift.liftFunction(body, { classify = cgm.classify, returnRegs = returnRegs, callInfo = callInfo })

	temps = lf.temps
	nextTemp = lf.nextTemp
	function allocTemp(desc)
		nextTemp += 1
		temps[nextTemp] = desc or {}
		return nextTemp
	end

	-- Precolored physical-register temps: ONE node per machine register (as IRC requires).
	pregTemps = {}
	function pColored(num)
		if not pregTemps[num] then
			pregTemps[num] = allocTemp({ precolor = cgm.precolorName(num), phys = num })
		end
		return pregTemps[num]
	end

	-- Seeds for pointer flow: pointer args occupy their yolo argument registers.
	argPtrTemps = {}
	argInfo = {}
	for k, ty in sigDesc.argTypes do
		yreg = cc.yoloArg(k)
		et = lf.entryTemp[yreg]
		argInfo[k] = { isPtr = (ty == 7), yoloReg = yreg, entryTemp = et }
		if ty == 7 and et then table.insert(argPtrTemps, et) end
	end

	-- classify nodes: load-ptr / store-ptr / call / alloca.
	loadPtrDefs, storePtrNodes, callNodes, allocaNodes, allocaResultDefs = {}, {}, {}, {}, {}
	sizeNames = {}
	for _, node in lf.nodes do
		if node.kind == "insn" then
			ann = node.stmt.annotation
			al = parseAlloca(ann)
			if al then
				allocaNodes[node] = al
				if al.kind == "size" then
					if sizeNames[al.name] then error("sarcasm: duplicate `alloca size (" .. al.name .. ")`") end
					sizeNames[al.name] = true
				else
					allocaResultDefs[node] = true
				end
			else if node.c.control == "call" and ann then callNodes[node] = ann
			else if ann == "load ptr" then loadPtrDefs[node] = true
			else if ann == "store ptr" then storePtrNodes[node] = true end
		end
	end

	pf = ptrflow.analyze(lf,
		{ argPtrTemps = argPtrTemps, loadPtrDefs = loadPtrDefs, allocaResultDefs = allocaResultDefs },
		allocTemp, { baseMnemonic = cgm.baseMnemonic })

	-- Link each fixed-size alloca-result node to its region; give the region a stable pointer
	-- temp for redirecting sp-relative math and a shared lower (the result's seeded lower).
	-- Iterate in body order (allocaNodes is keyed by node identity, whose `pairs` order is
	-- hash-dependent; region pointer temps are allocated here, so a stable order keeps temp
	-- ids — and therefore register allocation — reproducible).
	for _, node in lf.nodes do
		al = allocaNodes[node]
		if al and al.kind == "resultSize" then
			for _, r in allocaRegions do
				if r.stmt == node.stmt then al.region = r; break end
			end
			r = al.region
			if r and not r.ptrTemp then
				r.ptrTemp = allocTemp({ role = "regionptr" })
				resultIv = node.defTemps and node.defTemps[1]
				r.loTemp = resultIv and pf.lowerTemp[resultIv]
				pf.isPtr[r.ptrTemp] = true
				if r.loTemp then pf.lowerTemp[r.ptrTemp] = r.loTemp end
			end
		end
	end

	-- loop headers (targets of back edges) get a pollcheck
	loopHeaderLabels = {}
	for _, node in lf.nodes do
		if node.kind == "insn" and node.c.targets and #node.c.targets > 0 then
			for _, t in node.c.targets do
				ti = lf.labelToFlow[t]
				if ti and ti <= node.fi then loopHeaderLabels[t] = true end
			end
		end
	end

	out = {}
	function emit(n) table.insert(out, n) end
	vMyth = allocTemp({ role = "myth" })
	temps[vMyth].spillCost = 1e9
	originSym = ".Lfilc_origin_" .. name

	emit({ kind = "prologue", name = name })

	cg = cgm.make({ emit = emit, allocTemp = allocTemp, pColored = pColored, pf = pf, temps = temps })

	-- GC root slots
	rootTemps, loToSlot = {}, {}
	function rootSlotFor(loT)
		if loToSlot[loT] == nil then
			table.insert(rootTemps, loT)
			loToSlot[loT] = #rootTemps - 1
			if temps[loT] then temps[loT].spillCost = 1e9 end
		end
		return loToSlot[loT]
	end
	function emitRootStore(loT) emit({ kind = "rootstore", temp = loT, index = rootSlotFor(loT), useTemps = { loT } }) end

	-- entry CC unpacking: myth <- myth reg; params from CC iv/lo regs into their yolo webs.
	cg.move(vMyth, pColored(cc.myth), true)
	for k, ty in sigDesc.argTypes do
		info = argInfo[k]
		if info.entryTemp then
			cg.move(info.entryTemp, pColored(cc.argIv(k)), true)
			if info.isPtr then
				loT = pf.lowerTemp[info.entryTemp]
				cg.move(loT, pColored(cc.argLo(k)), true)
				emitRootStore(loT)
			end
		end
	end

	-- access-fail stubs (bookkeeping here; the stub body is arch-specific via cg.failStub).
	accessOrigins, failStubs, failCounter = {}, {}, 0
	function failLabelFor(ivTemp, loTemp, size, align, isWrite)
		failCounter += 1
		aco = ".Lfilc_aco_" .. name .. "_" .. failCounter
		lbl = ".Lfail_" .. name .. "_" .. failCounter
		table.insert(accessOrigins, { sym = aco, size = size, align = align, write = isWrite and true or false, line = curLine })
		cg.failStub(failStubs, lbl, ivTemp, loTemp, aco)
		return lbl
	end

	-- access check for a precomputed effective address (capLo==nil => null cap, always traps).
	function emitAccessCheck(effTemp, capLo, size, align, isWrite)
		if capLo == nil then
			cg.jump(failLabelFor(effTemp, nil, size, align, isWrite))
			return
		end
		lbl = failLabelFor(effTemp, capLo, size, align, isWrite)
		cg.branchZero(capLo, lbl)                 -- null capability
		cg.cmpBranch(effTemp, capLo, "ult", lbl)  -- eff < lower
		upper = allocTemp({ role = "scratch" })
		cg.load(upper, capLo, -16, 8)             -- upper = [lower-16]
		if size > 1 then
			hi = allocTemp({ role = "scratch" })
			cg.addImm(hi, effTemp, size)          -- hi = eff + size
			cg.cmpBranch(hi, upper, "ugt", lbl)   -- eff+size > upper
		else
			cg.cmpBranch(effTemp, upper, "uge", lbl)  -- eff >= upper
		end
		if align > 1 then cg.testMaskBranch(effTemp, align - 1, "ne", lbl) end
	end

	-- invisicap pointer load: load (dstIv, dstLo) from the address of `mem`.
	ptrldCounter = 0
	function emitPtrLoad(node, mem, dstIv, dstLo)
		ptrldCounter += 1
		tag = name .. "_" .. ptrldCounter
		effTemp, baseLo = cg.computeAddr(node, mem)
		emitAccessCheck(effTemp, baseLo, 8, 8)
		if baseLo == nil then cg.moveZero(dstLo); cg.moveZero(dstIv); return end
		offInObj = allocTemp({ role = "offobj" })
		cg.subReg(offInObj, effTemp, baseLo)                       -- offInObj = eff - lower
		aux = allocTemp({ role = "aux" })
		cg.load(aux, baseLo, -8, 8); cg.maskLow48(aux)             -- aux = [lower-8] & 0xffffffffffff
		nullL, haveL, direct = ".Lnulllo_" .. tag, ".Lhavelo_" .. tag, ".Ldirlo_" .. tag
		cg.branchZero(aux, nullL)
		auxE = allocTemp({ role = "auxentry" })
		cg.loadIndexed(auxE, aux, offInObj, 1, 8)                  -- auxE = [aux + offInObj]
		cg.testMaskBranch(auxE, 1, "eq", direct)                   -- bit0 clear -> direct
		boxp = allocTemp({ role = "box" })
		cg.move(boxp, auxE); cg.andImmInPlace(boxp, -2); cg.load(dstLo, boxp, 8, 8)  -- box: lower=[(auxE&~1)+8]
		cg.jump(haveL)
		cg.label(direct); cg.move(dstLo, auxE, true); cg.jump(haveL)
		cg.label(nullL); cg.moveZero(dstLo)
		cg.label(haveL); cg.load(dstIv, effTemp, 0, 8)             -- dstIv = [eff]
	end

	-- invisicap pointer store (aux allocation + readonly reject + FUGC store barrier).
	ptrstCounter = 0
	function emitPtrStore(node, mem, valIv, valLo)
		ptrstCounter += 1
		tag = name .. "_st_" .. ptrstCounter
		effTemp, baseLo = cg.computeAddr(node, mem)
		if baseLo == nil then emitAccessCheck(effTemp, nil, 8, 8, true); return end
		if valLo == nil then valLo = allocTemp({ role = "nulllo" }); cg.moveZero(valLo) end
		lbl = failLabelFor(effTemp, baseLo, 8, 8, true)
		cg.branchZero(baseLo, lbl)
		cg.testMaskBranch(effTemp, 7, "ne", lbl)                   -- alignment
		cg.cmpBranch(effTemp, baseLo, "ult", lbl)                  -- lower bound
		auxword = allocTemp({ role = "auxword" })
		cg.load(auxword, baseLo, -8, 8)
		cg.testMaskBranch(auxword, "0x6000000000000", "ne", lbl)   -- read-only/special reject
		upper = allocTemp({ role = "scratch" })
		cg.load(upper, baseLo, -16, 8)
		hi = allocTemp({ role = "scratch" })
		cg.addImm(hi, effTemp, 8); cg.cmpBranch(hi, upper, "ugt", lbl)  -- upper bound
		offInObj = allocTemp({ role = "offobj" })
		cg.subReg(offInObj, effTemp, baseLo)
		aux = allocTemp({ role = "aux" })
		cg.move(aux, auxword); cg.maskLow48(aux)
		needAux, barrier, doBarrier, storeLbl, doneLbl =
			".Lneedaux_" .. tag, ".Lbarrier_" .. tag, ".Ldobar_" .. tag, ".Lstore_" .. tag, ".Ldone_" .. tag
		cg.branchZero(aux, needAux)
		cg.label(barrier)
		cg.markingStateNonzeroBranch(doBarrier)
		cg.label(storeLbl)
		cg.storeIndexed(valLo, aux, offInObj, 1)
		cg.store(valIv, effTemp, 0)
		cg.jump(doneLbl)
		-- need-aux: filc_object_ensure_aux_ptr_outline(myth, lower-16) -> aux
		cg.label(needAux)
		header = allocTemp({ role = "scratch" })
		cg.subImm(header, baseLo, 16)
		cg.move(pColored(cc.rtArg(1)), vMyth)
		cg.move(pColored(cc.rtArg(2)), header)
		cg.call("filc_object_ensure_aux_ptr_outline", { pColored(cc.rtArg(1)), pColored(cc.rtArg(2)) }, cg.callerSavedClobbers())
		cg.move(aux, pColored(cc.rtRet))
		cg.jump(barrier)
		-- do-barrier: filc_store_barrier_for_lower_slow(myth, lower)
		cg.label(doBarrier)
		cg.move(pColored(cc.rtArg(1)), vMyth)
		cg.move(pColored(cc.rtArg(2)), valLo)
		cg.call("filc_store_barrier_for_lower_slow", { pColored(cc.rtArg(1)), pColored(cc.rtArg(2)) }, cg.callerSavedClobbers())
		cg.jump(storeLbl)
		cg.label(doneLbl)
	end

	-- pollcheck: myth flags at [myth+8], bits 0xe.
	pollCounter = 0
	function emitPollcheck()
		pollCounter += 1
		okLbl = ".Lpollok_" .. name .. "_" .. pollCounter
		flags = allocTemp({ role = "scratch" })
		cg.load(flags, vMyth, 8, 1)
		cg.testMaskBranch(flags, 0xe, "eq", okLbl, 32)
		cg.move(pColored(cc.rtArg(1)), vMyth)
		cg.leaGlobal(cc.rtArg(2), originSym)
		cg.call("filc_pollcheck_slow", { pColored(cc.rtArg(1)), pColored(cc.rtArg(2)) }, cg.callerSavedClobbers())
		cg.label(okLbl)
	end

	excLabel = nil
	function ensureExcLabel() if not excLabel then excLabel = ".Lexc_" .. name end return excLabel end
	calledExterns = {}

	-- move the web's capability (its lower, or null) into a physical register.
	function emitCapMove(destReg, web)
		pDest = pColored(destReg)
		loT = web and pf.lowerTemp[web]
		if loT then cg.move(pDest, loT) else cg.moveZero(pDest) end
		return pDest
	end

	function emitCall(node)
		cs = callSigOf(node.stmt)
		callee = node.stmt.operands[1].text
		calledExterns[callee] = { name = callee, sig = cs.signature, sigDesc = cs,
			sigName = "pizlonatedFI" .. cs.signature .. "_" .. callee }
		argTemps = {}
		for _, r in node.c.uses do if r.argReg then argTemps[r.num] = node.opTemp[r] end end
		cg.move(pColored(cc.myth), vMyth)
		callUses = { pColored(cc.myth) }
		for k = 1, cs.argWords do
			aTemp = argTemps[cc.yoloArg(k)]
			cg.move(pColored(cc.argIv(k)), aTemp)
			table.insert(callUses, pColored(cc.argIv(k)))
			if cs.argTypes[k] == 7 then table.insert(callUses, emitCapMove(cc.argLo(k), aTemp)) end
		end
		cg.call("pizlonatedFI" .. cs.signature .. "_" .. callee, callUses, cg.callerSavedClobbers())
		cg.exceptionBranch(ensureExcLabel())
		if not cs.isVoid then
			cg.move(node.defTemps[1], pColored(cc.retIv))
		end
	end

	-- Stack allocations. `;! alloca size (x)` captures the byte size; `;! alloca result (x)` /
	-- `;! alloca result size=N` becomes filc_allocate(myth, size); payload = allocation+16.
	allocaSizes = {}
	function emitAlloca(node, al)
		if al.kind == "size" then
			sizeOp = cgm.allocaSizeOperand(node.stmt)
			sizeTemp = allocTemp({ role = "allocasize" })
			if sizeOp and sizeOp.kind == "reg" then cg.move(sizeTemp, node.opTemp[sizeOp], true)
			else if sizeOp and sizeOp.kind == "imm" then cg.moveImm(sizeTemp, sizeOp.value or tonumber(sizeOp.text))
			else error("sarcasm: `alloca size` instruction has no size operand: " .. node.stmt.raw) end
			allocaSizes[al.name] = sizeTemp
			return
		end
		cg.move(pColored(cc.rtArg(1)), vMyth)
		if al.kind == "result" then
			sizeTemp = allocaSizes[al.name]
			if not sizeTemp then
				error("sarcasm: `alloca result (" .. al.name .. ")` has no preceding `alloca size (" .. al.name .. ")`")
			end
			cg.move(pColored(cc.rtArg(2)), sizeTemp)
		else
			cg.moveImm(pColored(cc.rtArg(2)), al.size)
		end
		cg.call("filc_allocate", { pColored(cc.rtArg(1)), pColored(cc.rtArg(2)) }, cg.callerSavedClobbers())
		resultIv = node.defTemps and node.defTemps[1]
		if not resultIv then error("sarcasm: `alloca result` instruction has no destination register: " .. node.stmt.raw) end
		ret = pColored(cc.rtRet)  -- allocation base; payload = base + 16
		if al.region then
			r = al.region
			cg.effAddr(resultIv, ret, 16)
			if r.loTemp then cg.effAddr(r.loTemp, ret, 16) end
			cg.effAddr(r.ptrTemp, ret, 16)
			if r.loTemp then emitRootStore(r.loTemp) end
		else
			resultLo = pf.lowerTemp[resultIv]
			cg.effAddr(resultIv, ret, 16)
			cg.effAddr(resultLo, ret, 16)
			emitRootStore(resultLo)
		end
	end

	-- Redirect an sp-relative address computation that lands inside a fixed alloca region to
	-- the allocation pointer (gcc -O0). Arch-specific; returns true if it replaced the node.
	function emitRegionRedirect(node)
		if #allocaRegions == 0 or not cg.regionRedirect then return false end
		return cg.regionRedirect(node, regionOf)
	end

	-- Walk the lifted body.
	for _, node in lf.nodes do
		if node.kind == "label" then
			if node.name != name and not string.match(node.name, "^%.LF[BE]") then
				emit(node)
				if loopHeaderLabels[node.name] then emitPollcheck() end
			end
		else if node.kind == "other" then
			-- drop directives
		else if node.kind == "insn" then
			c = node.c
			curLine = (node.stmt and node.stmt.line) or curLine
			if allocaNodes[node] then
				emitAlloca(node, allocaNodes[node])
			else if c.control == "return" then
				if not sigDesc.isVoid then
					retTemp = nil
					for _, r in c.uses do if r.retReg then retTemp = node.opTemp[r] end end
					if retTemp then cg.move(pColored(cc.retIv), retTemp) end
					if sigDesc.retIsPtr then emitCapMove(cc.retLo, retTemp) end
				end
				cg.clearRetFlag()
				emit({ kind = "epilogue", name = name, useTemps = { vMyth } })
				emit(build.insn("ret", {}, { control = "return", fallsThrough = false }))
			else if c.control == "call" and callNodes[node] then
				emitCall(node)
			else if emitRegionRedirect(node) then
				-- sp-relative address computation redirected into an alloca region
			else
				mem = cgm.memOperand(node.stmt)
				if cg.lowerSpecial(node, mem) then
					-- arch-specific passthrough lowering (e.g. x86 cltq -> movslq, lea passthrough)
				else if loadPtrDefs[node] then
					dstIv = node.defTemps[1]
					dstLo = pf.lowerTemp[dstIv]
					emitPtrLoad(node, mem, dstIv, dstLo)
					emitRootStore(dstLo)
				else if storePtrNodes[node] then
					valOp = storeValueOperand(node.stmt, mem)
					valIv = valOp and node.opTemp[valOp] or nil
					valLo = valIv and pf.lowerTemp[valIv] or nil
					emitPtrStore(node, mem, valIv, valLo)
				else if mem then
					cg.checkMemInsn(node, mem)
					effTemp, capLo = cg.computeAddr(node, mem)
					size, align = cgm.accessSizeAlign(node.stmt)
					isWrite = cgm.isStoreInsn(node.stmt)
					emitAccessCheck(effTemp, capLo, size, align, isWrite)
					emit(node)
				else
					emit(node)
				end
			end
		else
			emit(node)
		end
	end

	if excLabel then
		emit(build.label(excLabel))
		emit({ kind = "epilogue", name = name, useTemps = { vMyth } })
		emit(build.insn("ret", {}, { control = "return", fallsThrough = false }))
	end
	for _, s in failStubs do emit(s) end

	-- Sorted by callee name: calledExterns is keyed by callee, and this list drives the
	-- order of emitted extern/glue directives, so it must not depend on hash order.
	externsList = {}
	for _, e in calledExterns do table.insert(externsList, e) end
	table.sort(externsList, function(a, b) return a.name < b.name end)

	return {
		name = name, sigDesc = sigDesc, fipNodes = out, temps = temps, vMyth = vMyth,
		originSym = originSym, numRoots = #rootTemps, funcLine = funcLine, nextTemp = nextTemp,
		rootTemps = rootTemps, accessOrigins = accessOrigins, calledExterns = externsList,
		lf = lf, pf = pf,
	}
end

return transform
