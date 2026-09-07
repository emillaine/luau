#!nonstrict
# sarcasm: SAfe Runtime Capability-enforced Assembler. Rewrites annotated Yolo-C ARM64
# assembly into memory-safe, Fil-C-linkable assembly, then (by default) invokes `as`.

# fs = require("@lute/fs")
# process = require("@lute/process")

# Shared modules.
sig = require("./sig")
transform = require("./transform")
regalloc = require("./regalloc")
emit = require("./emit")
build = require("./build")
detect = require("./detect")

# Per-architecture module pairs (arm64_* / x86_64_*).
arm64_parse = require("./arm64_parse")
x86_64_parse = require("./x86_64_parse")
arm64_glue = require("./arm64_glue")
x86_64_glue = require("./x86_64_glue")
arm64_codegen = require("./arm64_codegen")
x86_64_codegen = require("./x86_64_codegen")
arm64_frame = require("./arm64_frame")
x86_64_frame = require("./x86_64_frame")
arm64_render = require("./arm64_render")
x86_64_render = require("./x86_64_render")

sarcasm = {}

# Keys of a table in ascending order. Used wherever iteration order over a set/map would
# otherwise leak the VM's hash order into emitted assembly (spill reload/store ordering,
# callsite-thunk ordering). Handles mixed key types defensively.
function sortedKeys(t)
	out = {}
	for k in t do out[out.count + 1] = k end
	table.sort(out, function(a, b)
		ta, tb = type(a), type(b)
		if ta != tb then return ta < tb end
		return a < b
	end)
	return out
end

# Per-architecture backend bundle. `spillReload`/`spillStore` build the load/store IR for
# a spilled temp at frame offset `off`; `emitFip` renders (x86 always emits AT&T output).
function makeTarget(arch, syntax)
	if arch == "x86_64" then
		backend = { cg = x86_64_codegen, frame = x86_64_frame }
		return {
			arch = "x86_64", syntax = syntax,
			transformFunction = function(nm, sd, body) return transform.transformFunction(nm, sd, body, backend) end,
			emitFip = function(out, tr, cr) return emit.emitFip(out, tr, cr, x86_64_render, "att") end,
			glue = x86_64_glue,
			allocatable = x86_64_codegen.ALLOCATABLE,
			spillReload = function(f, off)
				n = build.insn("mov", { build.rt(f), build.memx(build.rp(4), { dispVal = off != 0 and off or null }) }, { defs = {f} })
				n.spillReload = true; n.spillOff = off; n.spillTemp = f; return n
			end,
			spillStore = function(f, off)
				n = build.insn("mov", { build.memx(build.rp(4), { dispVal = off != 0 and off or null }), build.rt(f) }, { uses = {f} })
				n.spillStore = true; n.spillOff = off; n.spillTemp = f; return n
			end,
		}
	end
	backend = { cg = arm64_codegen, frame = arm64_frame }
	return {
		arch = "arm64", syntax = null,
		transformFunction = function(nm, sd, body) return transform.transformFunction(nm, sd, body, backend) end,
		emitFip = function(out, tr, cr) return emit.emitFip(out, tr, cr, arm64_render, null) end,
		glue = arm64_glue,
		allocatable = arm64_codegen.ALLOCATABLE,
		spillReload = function(f, off)
			n = build.insn("ldr", { build.rt(f), build.mem(build.sp(), off) }, { defs = {f} })
			n.spillReload = true; n.spillOff = off; n.spillTemp = f; return n
		end,
		spillStore = function(f, off)
			n = build.insn("str", { build.rt(f), build.mem(build.sp(), off) }, { uses = {f} })
			n.spillStore = true; n.spillOff = off; n.spillTemp = f; return n
		end,
	}
end

# Split parsed statements into functions. A function starts at a label carrying a
# `;! signature` annotation and ends at its `.size NAME, .-NAME` directive. Every
# symbol declared as a function (`.type NAME, %function` / `@function`) that is defined
# here (has a label) MUST carry a signature annotation; otherwise we cannot make it
# memory-safe, so it is a compile-time error rather than a silently dropped function.
# Returns { functions = { {name, sigAnn, body={stmts}} }, consumed }.
function splitFunctions(stmts)
	# pass 1: collect declared function symbols
	funcSyms = {}
	for _, st in stmts do
		if st.kind == "directive" and st.name == ".type" then
			nm, kind = string.match(st.args, "^%s*([%w_.$]+)%s*,%s*(.+)$")
			if nm and kind and string.find(kind, "function", 1, true) then
				funcSyms[nm] = true
			end
		end
	end

	# pass 2: split into functions, enforcing that declared functions are annotated
	functions = {}
	consumed = {}
	cur = null
	for idx, st in stmts do
		if st.kind == "label" then
			hasSig = st.annotation != null and string.find(st.annotation, "%(") != null
			if hasSig then
				cur = { name = st.name, sigAnn = st.annotation, body = { st }, startIdx = idx }
				table.insert(functions, cur)
				consumed[idx] = cur
			else if funcSyms[st.name] then
				error("sarcasm: function '" .. st.name .. "' has no ;! signature annotation "
					.. "(add one to its label, e.g. `" .. st.name .. ": ;! int(ptr)`)")
			else if cur then
				table.insert(cur.body, st)
				consumed[idx] = cur
			end
		else if cur then
			table.insert(cur.body, st)
			consumed[idx] = cur
			if st.kind == "directive" and st.name == ".size" then
				cur = null
			end
		end
	end
	return functions, consumed
end
sarcasm.splitFunctions = splitFunctions

# Build the regalloc instruction array from transform IR nodes.
function buildRaInsns(nodes)
	ra = {}
	for _, node in nodes do
		if node.kind == "label" then
			table.insert(ra, { defs = {}, uses = {}, isLabelDef = node.name, fallsThrough = true })
		else if node.kind == "insn" then
			control = node.control or (node.c and node.c.control) or "none"
			targets = node.targets or (node.c and node.c.targets)
			fallsThrough = node.fallsThrough
			if fallsThrough == null then fallsThrough = node.c and node.c.fallsThrough end
			if fallsThrough == null then fallsThrough = true end
			table.insert(ra, {
				defs = node.defTemps or {},
				uses = node.useTemps or {},
				move = node.move,
				targets = targets,
				fallsThrough = fallsThrough,
			})
		else if node.kind == "epilogue" then
			table.insert(ra, { defs = {}, uses = node.useTemps or {}, fallsThrough = true })
		else if node.kind == "rootstore" then
			table.insert(ra, { defs = {}, uses = node.useTemps or {}, fallsThrough = true })
		else if node.kind == "prologue" then
			table.insert(ra, { defs = {}, uses = {}, fallsThrough = true })
		else
			table.insert(ra, { defs = {}, uses = {}, fallsThrough = true })
		end
	end
	return ra
end

# Redirect every reference to a spilled temp in `node` to its fresh replacement.
function remapNodeTemps(node, remap)
	function replList(list)
		if list then for i, t in list do if remap[t] then list[i] = remap[t] end end end
	end
	replList(node.defTemps)
	replList(node.useTemps)
	if node.move then
		if remap[node.move.dst] then node.move.dst = remap[node.move.dst] end
		if remap[node.move.src] then node.move.src = remap[node.move.src] end
	end
	function remapOp(op)
		if not op then return end
		if op.kind == "reg" then
			if op.tempRef and remap[op.tempRef] then op.tempRef = remap[op.tempRef] end
			if node.opTemp and node.opTemp[op] and remap[node.opTemp[op]] then
				node.opTemp[op] = remap[node.opTemp[op]]
			end
		else if op.kind == "mem" then
			remapOp(op.base); remapOp(op.index)
		end
	end
	ops = node.stmt and node.stmt.operands or node.operands
	if ops then for _, op in ops do remapOp(op) end end
end

# Rewrite spilled temps: around each def/use of a spilled temp, insert a store/reload
# through a fresh short-lived temp (tagged so the emitter can eliminate redundant
# reloads and size the frame). Returns the new node list.
function rewriteSpills(nodes, spilledSet, slotOf, allocTemp, spillBase, target)
	out = {}
	for _, node in nodes do
		if node.kind != "insn" then
			table.insert(out, node)
			continue
		end
		remap, isUse, isDef = {}, {}, {}
		for _, t in (node.useTemps or {}) do
			if spilledSet[t] then remap[t] = remap[t] or allocTemp(); isUse[t] = true end
		end
		for _, t in (node.defTemps or {}) do
			if spilledSet[t] then remap[t] = remap[t] or allocTemp(); isDef[t] = true end
		end
		if not next(remap) then
			table.insert(out, node)
			continue
		end
		for _, t in sortedKeys(remap) do
			if isUse[t] then
				table.insert(out, target.spillReload(remap[t], spillBase + 8 * slotOf[t]))
			end
		end
		remapNodeTemps(node, remap)
		table.insert(out, node)
		for _, t in sortedKeys(remap) do
			if isDef[t] then
				table.insert(out, target.spillStore(remap[t], spillBase + 8 * slotOf[t]))
			end
		end
	end
	return out
end

# Pack spill slots by coloring their interference graph: two spilled values whose live
# ranges never overlap can share one stack offset. Without this, every spilled temp gets a
# unique slot and frames balloon (e.g. large-arm64 needed ~7.7 KB). We build a
# slot-variable view of the final code (a spill store defines its slot, a reload uses it),
# run the same backward liveness the register allocator uses, then greedily color slots
# (a slot's store interferes with everything live across it). Rewrites each spill node's
# offset and returns the packed slot count.
function packSpillSlots(tr, spillBase, numSlots, target)
	if numSlots <= 1 then return numSlots end
	function slotIdOf(off) return math.floor((off - spillBase) / 8) end

	# slot-variable insns parallel to fipNodes, preserving the CFG (labels + control flow).
	slotInsns = {}
	for _, node in tr.fipNodes do
		if node.kind == "label" then
			table.insert(slotInsns, { defs = {}, uses = {}, isLabelDef = node.name, fallsThrough = true })
		else if node.kind == "insn" then
			control = node.control or (node.c and node.c.control) or "none"
			targets = node.targets or (node.c and node.c.targets)
			ft = node.fallsThrough
			if ft == null then ft = node.c and node.c.fallsThrough end
			if ft == null then ft = true end
			defs, uses = {}, {}
			if node.spillStore then defs = { slotIdOf(node.spillOff) } end
			if node.spillReload then uses = { slotIdOf(node.spillOff) } end
			table.insert(slotInsns, { defs = defs, uses = uses, targets = targets, fallsThrough = ft })
		else
			table.insert(slotInsns, { defs = {}, uses = {}, fallsThrough = true })
		end
	end

	liveOut = regalloc.liveOut(slotInsns)
	# interference: a slot's store (its only def point) interferes with every slot live
	# across that store. This def-to-live-out construction is the standard, complete
	# interference relation (the register allocator uses the same one): any two slots that
	# are ever simultaneously live get an edge at whichever's store sees the other live. It
	# only does work at spill stores, so it's linear in the spill traffic (an all-pairs
	# build would be quadratic in the live set at every instruction).
	adj = {}
	for s = 0, numSlots - 1 do adj[s] = {} end
	for i, ins in slotInsns do
		if ins.defs[1] != null then
			lo = liveOut[i]
			if lo then
				for _, d in ins.defs do
					for t in lo do if t != d then adj[d][t] = true; adj[t][d] = true end end
				end
			end
		end
	end
	# greedy graph coloring (colors = compact slot offsets)
	color = {}
	ncolors = 0
	for s = 0, numSlots - 1 do
		used = {}
		for t in adj[s] do if color[t] != null then used[color[t]] = true end end
		c = 0
		while used[c] do c += 1 end
		color[s] = c
		if c + 1 > ncolors then ncolors = c + 1 end
	end
	# Rewrite spill nodes to their packed offset. The offset lives inside the memory
	# operand (target-specific shape), so rebuild the node via the target constructor rather
	# than poking a field; that keeps the rendered address and the reload-elim key in sync.
	for i, node in tr.fipNodes do
		if node.kind == "insn" and node.spillReload then
			tr.fipNodes[i] = target.spillReload(node.spillTemp, spillBase + 8 * color[slotIdOf(node.spillOff)])
		else if node.kind == "insn" and node.spillStore then
			tr.fipNodes[i] = target.spillStore(node.spillTemp, spillBase + 8 * color[slotIdOf(node.spillOff)])
		end
	end
	return ncolors
end

# Color the function, spilling to the stack and re-running IRC until it converges.
# Sets tr.numSpillSlots and returns the final coloring.
function allocateWithSpilling(tr, target)
	nextTemp = tr.nextTemp or 0
	function allocTemp()
		nextTemp += 1
		tr.temps[nextTemp] = { spillCost = 1e9 }  # reload temps are short-lived; never re-spill
		return nextTemp
	end
	slotOf, numSlots = {}, 0
	spillBase = 16 + 8 * (tr.numRoots or 0)
	for _ = 1, 32 do
		# spill-cost heuristic: cost ~ number of def/use occurrences, so IRC prefers
		# spilling rarely-used temps (a value used once is cheap to reload; a value used
		# many times, like a base pointer, is kept in a register). noSpill temps keep 1e9.
		cnt = {}
		for _, node in tr.fipNodes do
			for _, t in (node.defTemps or {}) do cnt[t] = (cnt[t] or 0) + 1 end
			for _, t in (node.useTemps or {}) do cnt[t] = (cnt[t] or 0) + 1 end
		end
		for t, d in tr.temps do
			if (d.spillCost or 0) < 1e9 then d.spillCost = math.max(cnt[t] or 1, 1) end
		end
		cr = regalloc.color(buildRaInsns(tr.fipNodes), tr.temps, { allocatable = target.allocatable })
		if cr.spilled.count == 0 then
			# allocation converged; pack spill slots (reuse offsets for non-overlapping slots)
			tr.numSpillSlots = packSpillSlots(tr, spillBase, numSlots, target)
			return cr
		end
		spilledSet = {}
		for _, t in cr.spilled do
			spilledSet[t] = true
			if slotOf[t] == null then slotOf[t] = numSlots; numSlots += 1 end
		end
		tr.fipNodes = rewriteSpills(tr.fipNodes, spilledSet, slotOf, allocTemp, spillBase, target)
	end
	error("sarcasm: register allocation did not converge (excessive register pressure)")
end

# Compile one parsed input into output assembly text. `debug` (from -g) makes origins
# carry source file/line/column (pointing at the input assembly) for runtime diagnostics.
function sarcasm.compile(stmts, fileDirective, debug, target)
	target = target or makeTarget("arm64", null)
	glue = target.glue
	functions = splitFunctions(stmts)
	out = {}
	if fileDirective then table.insert(out, "\t.file\t\"" .. fileDirective .. "\"") end
	table.insert(out, "\t.text")

	calledExterns = {}   # sig-name -> desc, for callsite thunks
	definedFI = {}       # FI symbols defined here (skip resolver thunks for these)

	for _, fn in functions do
		sigDesc = sig.parseSignature(fn.sigAnn)
		# body = statements after the function label up to (not incl) .size
		body = {}
		for _, st in fn.body do table.insert(body, st) end
		tr = target.transformFunction(fn.name, sigDesc, body)

		# allocate registers (spilling to the stack + re-running IRC as needed)
		colorResult = allocateWithSpilling(tr, target)

		# source-location info for -g origins (points at the input assembly)
		fnDbg = debug and { filename = fileDirective or "?", funcLine = tr.funcLine or 0 } or null

		# emit getter, FIP body, generic thunk, FO/origins, access origins, alias
		glue.getter(out, fn.name)
		target.emitFip(out, tr, colorResult)
		glue.genericThunk(out, sigDesc.signature, sigDesc.argWords, sigDesc.retWords, sigDesc.retIsPtr)
		glue.foAndOrigins(out, fn.name, sigDesc.signature, tr.numRoots, fnDbg)
		for _, ao in tr.accessOrigins do
			glue.accessOrigin(out, ao.sym, ao.size, ao.align, fn.name, ao.write,
				debug and { line = ao.line or 0 } or null)
		end
		glue.alias(out, fn.name, sigDesc.signature)
		definedFI["pizlonatedFI" .. sigDesc.signature .. "_" .. fn.name] = true

		for _, ext in tr.calledExterns do
			calledExterns[ext.sigName] = ext
		end
	end

	# Emit weak/hidden callsite resolver thunks for called externals (deduped, and only
	# when we don't define the same FI symbol locally).
	for _, sigName in sortedKeys(calledExterns) do
		if not definedFI[sigName] then
			glue.callsiteThunk(out, calledExterns[sigName].name, calledExterns[sigName].sigDesc)
		end
	end

	table.insert(out, "\t.section\t\".note.GNU-stack\",\"\",@progbits")
	return table.concat(out, "\n") .. "\n"
end

PROGNAME = "sarcasm"
VERSION = "0.1.0"

USAGE = "usage: " .. PROGNAME .. " [-o <file>] [-g] [-S|--no-assemble] [--as <command>] <input.s>"

HELP = table.concat({
	PROGNAME .. " " .. VERSION .. " — SAfe Runtime Capability-enforced Assembler",
	"",
	"Rewrites annotated Yolo-C ARM64 assembly into memory-safe, Fil-C-linkable",
	"assembly, then assembles it with `as` (a drop-in-ish assembler replacement).",
	"",
	USAGE,
	"",
	"Options:",
	"  -o <file>          Output object file (default: <input>.o).",
	"                     With -S, the assembly output path (default: <input>.yolo.s).",
	"  -g                 Emit source file/line/column debug info in Fil-C origins",
	"                     (points at the input assembly) for better runtime diagnostics.",
	"  -S, --no-assemble  Emit transformed assembly only; do not run the assembler.",
	"  --as <command>     Assembler to invoke in the default mode (default: as).",
	"      --version      Print version information and exit.",
	"  -h, --help         Print this help and exit.",
	"",
	"Input is ARM64 assembly annotated with ;! directives, e.g.:",
	"  hash:  ;! unsigned(ptr)        (function label: Fil-C signature)",
	"  ldr x1, [x0]  ;! load ptr      (pointer load from memory)",
	"  str x1, [x0]  ;! store ptr     (pointer store to memory)",
	"  bl foo        ;! int(ptr, size_t)   (call: callee signature)",
	"",
	"Only ARM64 is supported. Assembly that cannot be proven safe is rejected.",
}, "\n")

# Report a command-line usage error (clean message, no stack trace); exit code 2.
function usageError(msg: string): number
	print(PROGNAME .. ": error: " .. msg)
	print("Try '" .. PROGNAME .. " #help' for more information.")
	return 2
end

# Report a processing diagnostic (clean message, no stack trace); exit code 1.
function diag(msg: string): number
	print(PROGNAME .. ": " .. msg)
	return 1
end

# CLI: as-like. Args: [-o OUT] [-S|#no-assemble] [--as CMD] INPUT.s
function sarcasm.main(argv)
	input, output, noAssemble, asCmd, debug = null, null, false, "as", false
	i = 2
	while i <= argv.count do
		a = argv[i]
		if a == "-h" or a == "--help" then
			print(HELP); return 0
		else if a == "--version" then
			print(PROGNAME .. " " .. VERSION); return 0
		else if a == "-o" then
			i += 1; output = argv[i]
			if not output then return usageError("option '-o' requires an argument") end
		else if a == "-g" then
			debug = true
		else if a == "-S" or a == "--no-assemble" then
			noAssemble = true
		else if a == "--as" then
			i += 1; asCmd = argv[i]
			if not asCmd then return usageError("option '--as' requires an argument") end
		else if string.sub(a, 1, 1) == "-" then
			return usageError("unrecognized option '" .. a .. "'")
		else
			if input then
				return usageError("more than one input file given ('" .. input .. "' and '" .. a .. "')")
			end
			input = a
		end
		i += 1
	end
	if not input then
		print(USAGE)
		print("Try '" .. PROGNAME .. " --help' for more information.")
		return 2
	end
	if not fs.exists(input) then
		return diag(input .. ": no such file")
	end

	text = fs.read(fs.open(input, "r"))
	arch, syntax = detect.detect(text)
	target = makeTarget(arch, syntax)
	stmts = (arch == "x86_64") and x86_64_parse.parseString(text, syntax) or arm64_parse.parseString(text)
	fileName = string.match(input, "([^/]+)$")
	ok, asm = pcall(sarcasm.compile, stmts, fileName, debug, target)
	if not ok then
		msg = tostring(asm)
		# Errors we raise deliberately are prefixed "sarcasm:" and are user-facing:
		# present them cleanly. Anything else is an unexpected internal error, which we
		# re-raise so the underlying stack trace is preserved for debugging.
		idx = string.find(msg, "sarcasm:", 1, true)
		if idx then
			return diag(input .. ": " .. string.sub(msg, idx + 8):gsub("^%s+", ""))
		end
		error(msg, 0)
	end

	function stripExt(p) return (string.gsub(p, "%.[%w]+$", "")) end

	if noAssemble then
		outFile = output or (stripExt(input) .. ".yolo.s")
		fs.write(fs.open(outFile, "w+"), asm)
		return 0
	end

	# default: write temp .yolo.s next to the .o then run `as` to produce the object.
	objOut = output or (stripExt(input) .. ".o")
	tmpAsm = stripExt(objOut) .. ".yolo.s"
	fs.write(fs.open(tmpAsm, "w+"), asm)
	res = process.run({ asCmd, tmpAsm, "-o", objOut })
	if not res.ok then
		print(res.stderr)
		return res.exitcode != 0 and res.exitcode or 1
	end
	return 0
end

function sarcasm.bench(fileName, input, output)
	arch, syntax = detect.detect(input)
	target = makeTarget(arch, syntax)
	stmts = (arch == "x86_64") and x86_64_parse.parseString(input, syntax) or arm64_parse.parseString(input)
	ok, asm = pcall(sarcasm.compile, stmts, fileName, true, target)
        if not ok then
                error("Unexpected error running benchmark")
        end
        if asm != output then
                error("Unexpected output: " .. asm)
        end
end

return sarcasm
