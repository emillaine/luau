#!nonstrict
# Lift a function's parsed body into a virtual-register IR built from register "webs"
# (reaching-definitions connected components). Each web becomes a temp so the IRC
# allocator can reallocate the whole GPR file.
#
# Input: `body` = array of parsed statements (labels + insns) for one function.
# Output: {
#   nodes = { <node>... },       -- one per statement, in order (labels kept as markers)
#   temps = { tempId -> {reg=num, precolor=null} },
#   insnDefTemps/UseTemps via node.defTemps / node.useTemps
#   node fields: kind="insn"/"label", stmt=<parsed>, defTemps={}, useTemps={},
#                opTemps = { <operand occurrence> -> tempId } keyed by identity
# }

arm64 = require("./arm64_isa")

lift = {}

# Keys of a set, in ascending order. Used where the iteration order over a
# register-number-keyed set would otherwise leak the VM's hash order into temp-id
# assignment (and hence into the final register allocation / emitted assembly).
function sortedKeys(set)
	out = {}
	for k in set do out[out.count + 1] = k end
	table.sort(out)
	return out
end

# Union-find.
function makeUF()
	parent = {}
	function find(x)
		while parent[x] and parent[x] != x do
			parent[x] = parent[parent[x]] or parent[x]
			x = parent[x]
		end
		return x
	end
	function union(a, b)
		ra, rb = find(a), find(b)
		if ra != rb then parent[rb] = ra end
		return find(a)
	end
	function ensure(x) if parent[x] == null then parent[x] = x end end
	return { find = find, union = union, ensure = ensure, parent = parent }
end

function lift.liftFunction(body, opts)
	opts = opts or {}
	classify = opts.classify or arm64.classify  # per-target instruction semantics
	returnRegs = opts.returnRegs  # array of reg nums that `ret` reads (AAPCS return)
	# Separate into ordered instruction list; keep label markers.
	insns = {}      # { {stmt, classify, index} } real instructions, 1-based
	labelIndex = {} # label name -> position in `insns` (the following insn) ; we use a marker approach
	nodes = {}      # ordered nodes matching `body` (labels + insns)
	# We build a parallel array `flow` of just instructions for dataflow, and record
	# for each label the index of the next instruction (its CFG entry).
	flow = {}
	labelToFlow = {}
	pendingLabels = {}
	for _, st in body do
		if st.kind == "label" then
			table.insert(pendingLabels, st.name)
			table.insert(nodes, { kind = "label", name = st.name })
		else if st.kind == "insn" then
			c = classify(st)
			if c.control == "return" and returnRegs then
				for _, rn in returnRegs do
					table.insert(c.uses, { kind = "reg", rc = "gpr", num = rn, width = 64, name = "x" .. rn, retReg = true })
				end
			end
			if c.control == "call" and opts.callInfo then
				ci = opts.callInfo(st)
				if ci then
					for _, rn in (ci.argRegs or {}) do
						table.insert(c.uses, { kind = "reg", rc = "gpr", num = rn, width = 64, name = "x" .. rn, argReg = true })
					end
					if ci.resultReg != null then
						table.insert(c.defs, { kind = "reg", rc = "gpr", num = ci.resultReg, width = 64, name = "x" .. ci.resultReg, resultReg = true })
					end
				end
			end
			fi = flow.count + 1
			table.insert(flow, { stmt = st, c = c, fi = fi })
			for _, ln in pendingLabels do labelToFlow[ln] = fi end
			pendingLabels = {}
			table.insert(nodes, { kind = "insn", stmt = st, c = c, fi = fi })
		else
			table.insert(nodes, { kind = "other", stmt = st })
		end
	end
	n = flow.count

	# CFG successors over flow indices. Index 0 = virtual ENTRY -> flows to 1.
	succ = {}
	for i = 1, n do succ[i] = {} end
	for i = 1, n do
		c = flow[i].c
		added = {}
		if c.targets then
			for _, t in c.targets do
				ti = labelToFlow[t]
				if ti then table.insert(succ[i], ti); added[ti] = true end
			end
		end
		if c.fallsThrough != false and i + 1 <= n then
			table.insert(succ[i], i + 1)
		end
	end
	# predecessors
	pred = {}
	for i = 0, n do pred[i] = {} end
	table.insert(pred[1] or {}, 0)  # entry
	pred[1] = pred[1] or {}
	if n >= 1 then table.insert(pred[1], 0) end
	for i = 1, n do
		for _, s in succ[i] do table.insert(pred[s], i) end
	end

	# Def sites. Each def of reg num at flow i is a site id. ENTRY (i=0) defs all regs.
	sites = {}          # id -> { fi, reg }
	siteId = {}         # key "fi:reg" -> id
	function keyOf(fi, reg) return tostring(fi) .. ":" .. tostring(reg) end
	function addSite(fi, reg)
		k = keyOf(fi, reg)
		if siteId[k] then return siteId[k] end
		id = sites.count + 1
		sites[id] = { fi = fi, reg = reg }
		siteId[k] = id
		return id
	end
	# Which regs are used anywhere (to bound entry pseudo-defs).
	usedRegs = {}
	for i = 1, n do
		for _, r in flow[i].c.uses do usedRegs[r.num] = true end
		for _, r in flow[i].c.defs do usedRegs[r.num] = true end
	end
	# ENTRY defs for every used reg.
	entrySites = {}
	for _, reg in sortedKeys(usedRegs) do
		id = addSite(0, reg)
		entrySites[reg] = id
	end
	# Real def sites.
	for i = 1, n do
		for _, r in flow[i].c.defs do addSite(i, r.num) end
	end

	# GEN/KILL per flow index (over site ids). GEN[i] = sites defined at i.
	gen = {}
	defRegs = {}
	for i = 0, n do gen[i] = {}; defRegs[i] = {} end
	for reg, id in entrySites do gen[0][id] = true; defRegs[0][reg] = true end
	for i = 1, n do
		for _, r in flow[i].c.defs do
			gen[i][addSite(i, r.num)] = true
			defRegs[i][r.num] = true
		end
	end

	# Reaching definitions fixpoint (per flow index).
	IN, OUT = {}, {}
	for i = 0, n do IN[i] = {}; OUT[i] = {} end
	# OUT[0] = gen[0]
	for id in gen[0] do OUT[0][id] = true end
	changed = true
	while changed do
		changed = false
		for i = 1, n do
			newIn = {}
			for _, p in pred[i] do
				for id in OUT[p] do newIn[id] = true end
			end
			newOut = {}
			for id in gen[i] do newOut[id] = true end
			for id in newIn do
				s = sites[id]
				if not defRegs[i][s.reg] then newOut[id] = true end
			end
			# compare
			function differ(a, b)
				for k in a do if not b[k] then return true end end
				for k in b do if not a[k] then return true end end
				return false
			end
			if differ(newIn, IN[i]) or differ(newOut, OUT[i]) then
				changed = true; IN[i] = newIn; OUT[i] = newOut
			end
		end
	end

	# Build webs: union def-sites reaching common uses.
	uf = makeUF()
	for id = 1, sites.count do uf.ensure(id) end
	# reaching defs of reg at instruction i = { id in IN[i] : sites[id].reg == reg }
	function reachingDefs(i, reg)
		out = {}
		for id in IN[i] do if sites[id].reg == reg then table.insert(out, id) end end
		return out
	end
	# For each use, union reaching defs.
	useWeb = {}  # "fi:reg" -> web root (for the use occurrence)
	for i = 1, n do
		for _, r in flow[i].c.uses do
			ds = reachingDefs(i, r.num)
			if ds.count > 0 then
				root = ds[1]
				for k = 2, ds.count do root = uf.union(root, ds[k]) end
				useWeb[keyOf(i, r.num)] = uf.find(root)
			end
		end
	end
	# RMW: only genuine read-modify-write regs (writeback bases, movk/bfi) must share a
	# single register for use+def. A load whose destination reuses the base register is
	# NOT rmw (base and dest are independent values), so it is not unioned here.
	for i = 1, n do
		for _, rn in (flow[i].c.rmw or {}) do
			uw = useWeb[keyOf(i, rn)]
			dw = uf.find(addSite(i, rn))
			if uw then uf.union(uw, dw) end
		end
	end

	# Assign temp ids per web root.
	temps = {}
	rootToTemp = {}
	nextTemp = 0
	function tempFor(root)
		if not rootToTemp[root] then
			nextTemp += 1
			rootToTemp[root] = nextTemp
			temps[nextTemp] = { reg = sites[root].reg }
		end
		return rootToTemp[root]
	end
	# entry temps
	entryTemp = {}   # reg num -> temp id (the live-in value)
	for _, reg in sortedKeys(entrySites) do
		entryTemp[reg] = tempFor(uf.find(entrySites[reg]))
	end

	# Annotate nodes with def/use temps and per-operand temp mapping.
	for _, node in nodes do
		if node.kind == "insn" then
			i = node.fi
			c = node.c
			node.defTemps = {}
			node.useTemps = {}
			node.opTemp = {}   # reg-operand table -> tempId
			for _, r in c.defs do
				t = tempFor(uf.find(addSite(i, r.num)))
				table.insert(node.defTemps, t)
				node.opTemp[r] = t
			end
			for _, r in c.uses do
				uw = useWeb[keyOf(i, r.num)]
				# re-canonicalize: later unions may have merged this web.
				t = uw and tempFor(uf.find(uw)) or (entryTemp[r.num])
				if t then
					table.insert(node.useTemps, t)
					node.opTemp[r] = t
				end
			end
		end
	end

	return {
		nodes = nodes,
		flow = flow,
		temps = temps,
		entryTemp = entryTemp,
		succ = succ,
		labelToFlow = labelToFlow,
		nextTemp = nextTemp,
	}
end

return lift
