#!nonstrict
# Iterated Register Coalescing (Appel & George) over a generic instruction list.
#
# The allocator consumes a "machine function" describing instructions in terms of
# abstract temporaries (temps). It computes liveness over a CFG built from labels and
# branch instructions, builds the interference graph, and colors temps into the
# physical GPR set, coalescing moves and spilling when necessary.
#
# Instruction contract (each entry of func.insns):
#   { defs = {tempId...}, uses = {tempId...},
#     move = { dst = tempId, src = tempId } | null,   # reg-reg copy (coalesce candidate)
#     isLabelDef = "name" | null,                      # this insn is a label definition
#     targets = { "name"... } | null,                  # explicit branch targets
#     fallsThrough = bool }                            # control can fall to next insn
#
# func.temps: tempId -> { precolor = physRegName | null, spillSlot = n | null, spillCost = num }
# The caller assigns temp ids (integers). Precolored temps model fixed physical regs.
#
# Returns: { color = { tempId -> physRegName }, spilled = { tempId... } }
# The driver re-runs after inserting spill code (handled by the caller) if spilled is
# non-empty; here we implement the classic actual-spill rewrite inline via a callback.

regalloc = {}

# This allocator is architecture-agnostic: the allocatable GPR set (the K colors) is
# supplied by the caller via `opts.allocatable` (arm64_isa.ALLOCATABLE / x86_64_isa.ALLOCATABLE).
# Register-set knowledge (allocatable / caller- / callee-saved, reg numbers) lives in the
# per-arch isa modules, not here.

# Helpers #----------------------------------------------------------------

function newSet(): { [any]: boolean }
	return {}
end
function setAdd(s, x) s[x] = true end
function setHas(s, x) return s[x] == true end

# Deterministic iteration order for sets keyed by temp ids / move indices (integers).
# `pairs`/generalized-`for` order over these follows the VM's hash function, which would
# otherwise make the coloring (and thus the emitted register assignment) depend on hash
# order. Iterating in sorted key order makes allocation reproducible.
function sortedList(set)
	out = {}
	for k in set do out[out.count + 1] = k end
	table.sort(out)
	return out
end

# Build basic blocks from the instruction list.
# Returns blocks = { { first=i, last=j, succ={blockIdx...}, insns={i..j} } }, and
# labelToBlock mapping.
function buildCFG(insns)
	n = insns.count
	# leaders: first insn, any label def, any insn after a branch.
	labelAt = {}          # label name -> insn index
	for i, ins in insns do
		if ins.isLabelDef then
			labelAt[ins.isLabelDef] = i
		end
	end
	# Determine block starts.
	isLeader = {}
	isLeader[1] = true
	for i, ins in insns do
		if ins.isLabelDef then isLeader[i] = true end
		if ins.targets or (ins.fallsThrough == false) then
			if i + 1 <= n then isLeader[i + 1] = true end
		end
	end
	# Create blocks.
	blocks = {}
	blockOfInsn = {}
	cur = null
	for i = 1, n do
		if isLeader[i] or i == 1 then
			cur = { first = i, last = i, insns = {} }
			table.insert(blocks, cur)
		end
		cur.last = i
		table.insert(cur.insns, i)
		blockOfInsn[i] = blocks.count
	end
	# Successors.
	labelToBlock = {}
	for bi, b in blocks do
		firstIns = insns[b.first]
		# a block may start with multiple stacked labels; map all leading labels
	end
	for name, idx in labelAt do
		labelToBlock[name] = blockOfInsn[idx]
	end
	for bi, b in blocks do
		b.succ = {}
		lastIns = insns[b.last]
		addFall = true
		if lastIns.targets then
			for _, t in lastIns.targets do
				tb = labelToBlock[t]
				if tb then table.insert(b.succ, tb) end
			end
			addFall = lastIns.fallsThrough != false
		end
		if lastIns.fallsThrough == false then addFall = false end
		if addFall and bi + 1 <= blocks.count then
			table.insert(b.succ, bi + 1)
		end
	end
	return blocks, labelToBlock, blockOfInsn
end
regalloc.buildCFG = buildCFG

# Liveness: compute live-out set (of temps) for each instruction.
function computeLiveness(insns, blocks)
	# block-level def/use
	for _, b in blocks do
		use = newSet()
		def = newSet()
		for _, i in b.insns do
			ins = insns[i]
			for _, u in (ins.uses or {}) do
				if not def[u] then use[u] = true end
			end
			for _, d in (ins.defs or {}) do
				def[d] = true
			end
		end
		b.useSet = use
		b.defSet = def
		b.liveIn = newSet()
		b.liveOut = newSet()
	end
	# iterate to fixpoint (backward)
	changed = true
	while changed do
		changed = false
		for bi = blocks.count, 1, -1 do
			b = blocks[bi]
			newOut = newSet()
			for _, s in b.succ do
				for t in blocks[s].liveIn do newOut[t] = true end
			end
			# liveIn = use ∪ (out − def)
			newIn = newSet()
			for t in b.useSet do newIn[t] = true end
			for t in newOut do
				if not b.defSet[t] then newIn[t] = true end
			end
			# detect change
			function differ(a, c)
				for t in a do if not c[t] then return true end end
				for t in c do if not a[t] then return true end end
				return false
			end
			if differ(newIn, b.liveIn) or differ(newOut, b.liveOut) then
				changed = true
				b.liveIn = newIn
				b.liveOut = newOut
			end
		end
	end
	# per-instruction live-out (backward within block)
	liveOutOf = {}
	for _, b in blocks do
		live = newSet()
		for t in b.liveOut do live[t] = true end
		for idx = b.insns.count, 1, -1 do
			i = b.insns[idx]
			ins = insns[i]
			# live-out of instruction i = current live
			lo = newSet()
			for t in live do lo[t] = true end
			liveOutOf[i] = lo
			# transfer: live = use ∪ (live − def)
			for _, d in (ins.defs or {}) do live[d] = null end
			for _, u in (ins.uses or {}) do live[u] = true end
		end
	end
	return liveOutOf
end
regalloc.computeLiveness = computeLiveness

# Per-instruction live-out sets for a generic insn list (defs/uses may be any variable ids,
# e.g. spill-slot ids). Builds the CFG and runs the backward liveness fixpoint. Returns
# liveOutOf[i] = set of variables live after instruction i.
function regalloc.liveOut(insns)
	return computeLiveness(insns, buildCFG(insns))
end

# The core IRC coloring. Returns color map and spill list.
# `temps` maps tempId -> descriptor. physical precolored temps have .precolor.
function regalloc.color(insns, temps, opts)
	opts = opts or {}
	# Per-target register set (caller-supplied); K is the color count.
	ALLOCATABLE = opts.allocatable or error("regalloc.color: opts.allocatable is required")
	K = ALLOCATABLE.count
	blocks = buildCFG(insns)
	liveOutOf = computeLiveness(insns, blocks)

	# Interference graph.
	adj = {}            # tempId -> set of tempId
	adjList = {}        # tempId -> array
	degree = {}
	moveList = {}       # tempId -> set of move-insn indices
	worklistMoves = {}  # set of move-insn indices
	alias = {}          # coalesced alias
	nodes = {}          # all temp ids seen

	function ensureNode(t)
		if not nodes[t] then
			nodes[t] = true
			adj[t] = newSet()
			adjList[t] = {}
			degree[t] = 0
			moveList[t] = newSet()
		end
	end

	for t in temps do ensureNode(t) end
	for _, ins in insns do
		for _, d in (ins.defs or {}) do ensureNode(d) end
		for _, u in (ins.uses or {}) do ensureNode(u) end
	end

	function precolored(t) return temps[t] and temps[t].precolor != null end

	function addEdge(u, v)
		if u == v or adj[u][v] then return end
		adj[u][v] = true
		adj[v][u] = true
		if not precolored(u) then
			table.insert(adjList[u], v)
			degree[u] = degree[u] + 1
		end
		if not precolored(v) then
			table.insert(adjList[v], u)
			degree[v] = degree[v] + 1
		end
	end

	# Build moves + interference from liveness.
	for i, ins in insns do
		live = newSet()
		for t in (liveOutOf[i] or {}) do live[t] = true end
		if ins.move then
			# uses of a move don't interfere with its def
			for _, u in (ins.uses or {}) do live[u] = null end
			setAdd(moveList[ins.move.dst], i)
			setAdd(moveList[ins.move.src], i)
			worklistMoves[i] = true
		end
		for _, d in (ins.defs or {}) do live[d] = true end
		for _, d in (ins.defs or {}) do
			for l in live do addEdge(l, d) end
		end
	end

	# Coloring worklists.
	precoloredSet = newSet()
	initial = {}
	for _, t in sortedList(nodes) do
		if precolored(t) then precoloredSet[t] = true
		else table.insert(initial, t) end
	end

	selectStack = {}
	onStack = newSet()
	coalescedNodes = newSet()
	coloredNodes = newSet()
	spilledNodes = {}
	frozenMoves = newSet()
	activeMoves = newSet()
	constrainedMoves = newSet()
	coalescedMoves = newSet()

	simplifyWorklist = {}
	freezeWorklist = {}
	spillWorklist = {}

	function inArray(arr, x)
		for idx, v in arr do if v == x then return idx end end
		return null
	end
	function removeFrom(arr, x)
		idx = inArray(arr, x)
		if idx then table.remove(arr, idx) end
	end

	function nodeMoves(t)
		out = {}
		for m in moveList[t] do
			if activeMoves[m] or worklistMoves[m] then out[m] = true end
		end
		return out
	end
	function moveRelated(t)
		return next(nodeMoves(t)) != null
	end

	# adjacent = adjacent nodes not on select stack / coalesced
	function adjacent(t)
		out = {}
		for _, v in adjList[t] do
			if not onStack[v] and not coalescedNodes[v] then out[v] = true end
		end
		return out
	end

	# build initial worklists
	for _, t in initial do
		if degree[t] >= K then
			table.insert(spillWorklist, t)
		else if moveRelated(t) then
			table.insert(freezeWorklist, t)
		else
			table.insert(simplifyWorklist, t)
		end
	end

	function enableMoves(nodesSet)
		for t in nodesSet do
			for m in nodeMoves(t) do
				if activeMoves[m] then
					activeMoves[m] = null
					worklistMoves[m] = true
				end
			end
		end
	end

	function decrementDegree(t)
		d = degree[t]
		degree[t] = d - 1
		if d == K and not precolored(t) then
			s = adjacent(t)
			s[t] = true
			enableMoves(s)
			removeFrom(spillWorklist, t)
			if moveRelated(t) then
				table.insert(freezeWorklist, t)
			else
				table.insert(simplifyWorklist, t)
			end
		end
	end

	function simplify()
		t = table.remove(simplifyWorklist)
		table.insert(selectStack, t)
		onStack[t] = true
		for _, v in sortedList(adjacent(t)) do
			decrementDegree(v)
		end
	end

	function getAlias(t)
		while coalescedNodes[t] do t = alias[t] end
		return t
	end

	function addWorklist(t)
		if not precolored(t) and not moveRelated(t) and degree[t] < K then
			removeFrom(freezeWorklist, t)
			table.insert(simplifyWorklist, t)
		end
	end

	function ok(t, r)
		# George criterion helper
		return degree[t] < K or precolored(t) or adj[t][r]
	end

	function conservative(u, v)
		# Briggs: count high-degree neighbors of the combined node
		seen = newSet()
		cnt = 0
		for w in adjacent(u) do
			if not seen[w] then seen[w] = true; if degree[w] >= K then cnt += 1 end end
		end
		for w in adjacent(v) do
			if not seen[w] then seen[w] = true; if degree[w] >= K then cnt += 1 end end
		end
		return cnt < K
	end

	function combine(u, v)
		removeFrom(freezeWorklist, v)
		removeFrom(spillWorklist, v)
		coalescedNodes[v] = true
		alias[v] = u
		for m in moveList[v] do moveList[u][m] = true end
		for _, w in sortedList(adjacent(v)) do
			addEdge(w, u)
			decrementDegree(w)
		end
		if degree[u] >= K and inArray(freezeWorklist, u) then
			removeFrom(freezeWorklist, u)
			table.insert(spillWorklist, u)
		end
	end

	function coalesce()
		m = null
		for _, mm in sortedList(worklistMoves) do m = mm; break end
		worklistMoves[m] = null
		mv = insns[m].move
		x = getAlias(mv.dst)
		y = getAlias(mv.src)
		u, v = null, null
		if precolored(y) then u, v = y, x else u, v = x, y end
		if u == v then
			coalescedMoves[m] = true
			addWorklist(u)
		else if precolored(v) or adj[u][v] then
			constrainedMoves[m] = true
			addWorklist(u); addWorklist(v)
		else
			canCoalesce = null
			if precolored(u) then
				canCoalesce = true
				for w in adjacent(v) do
					if not ok(w, u) then canCoalesce = false break end
				end
			else
				canCoalesce = conservative(u, v)
			end
			if canCoalesce then
				coalescedMoves[m] = true
				combine(u, v)
				addWorklist(u)
			else
				activeMoves[m] = true
			end
		end
	end

	function freezeMoves(u)
		for _, m in sortedList(nodeMoves(u)) do
			activeMoves[m] = null
			worklistMoves[m] = null
			frozenMoves[m] = true
			mv = insns[m].move
			v = getAlias(mv.src)
			if getAlias(mv.dst) == getAlias(u) then v = getAlias(mv.dst) == u and getAlias(mv.src) or getAlias(mv.src) end
			other = (getAlias(mv.dst) == getAlias(u)) and getAlias(mv.src) or getAlias(mv.dst)
			if not moveRelated(other) and degree[other] < K and not precolored(other) then
				removeFrom(freezeWorklist, other)
				table.insert(simplifyWorklist, other)
			end
		end
	end

	function freeze()
		u = table.remove(freezeWorklist)
		table.insert(simplifyWorklist, u)
		freezeMoves(u)
	end

	function selectSpill()
		# pick highest-degree (cheap heuristic) to spill optimistically
		best, bestIdx, bestScore = null, null, null
		for idx, t in spillWorklist do
			cost = (temps[t] and temps[t].spillCost) or 1
			score = degree[t] / math.max(cost, 0.0001)
			if not bestScore or score > bestScore then
				bestScore = score; best = t; bestIdx = idx
			end
		end
		table.remove(spillWorklist, bestIdx)
		table.insert(simplifyWorklist, best)
		freezeMoves(best)
	end

	# main loop
	while true do
		if simplifyWorklist.count > 0 then simplify()
		else if next(worklistMoves) then coalesce()
		else if freezeWorklist.count > 0 then freeze()
		else if spillWorklist.count > 0 then selectSpill()
		else break end
	end

	# assign colors
	color = {}
	for t in precoloredSet do color[t] = temps[t].precolor end

	actualSpills = {}
	while selectStack.count > 0 do
		t = table.remove(selectStack)
		onStack[t] = null
		okColors = {}
		for _, r in ALLOCATABLE do okColors[r] = true end
		for _, w in adjList[t] do
			aw = getAlias(w)
			if coloredNodes[aw] or precoloredSet[aw] then
				if color[aw] then okColors[color[aw]] = null end
			end
		end
		chosen = null
		for _, r in ALLOCATABLE do
			if okColors[r] then chosen = r break end
		end
		if not chosen then
			table.insert(actualSpills, t)
		else
			coloredNodes[t] = true
			color[t] = chosen
		end
	end
	for t in coalescedNodes do
		color[t] = color[getAlias(t)]
	end

	return { color = color, spilled = actualSpills, blocks = blocks, aliasOf = getAlias }
end

return regalloc
