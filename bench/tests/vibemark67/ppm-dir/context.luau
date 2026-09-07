# Context modeling for PPM compression

ALPHABET_SIZE = 257 # 256 bytes + 1 escape symbol
ESCAPE_SYMBOL = 257
MAX_ORDER = 4

export type ContextNode = {
    counts: {number},
    total: number,
    children: {[number]: ContextNode},
}

export type PPMModel = {
    root: ContextNode,
    maxOrder: number,
}

function createNode(): ContextNode
    return {
        counts = table.create(ALPHABET_SIZE, 0),
        total = 0,
        children = {},
    }
end

function createModel(maxOrder: number?): PPMModel
    return {
        root = createNode(),
        maxOrder = maxOrder or MAX_ORDER,
    }
end

function getContext(model: PPMModel, history: {number}, order: number): ContextNode?
    node = model.root
    histLen = history.count
    startIdx = histLen - order + 1
    if startIdx < 1 then return null end

    for i = startIdx, histLen do
        sym = history[i]
        child = node.children[sym]
        if not child then
            return null
        end
        node = child
    end
    return node
end

function ensureContext(model: PPMModel, history: {number}, order: number): ContextNode
    node = model.root
    histLen = history.count
    startIdx = histLen - order + 1
    if startIdx < 1 then startIdx = 1 end

    for i = startIdx, histLen do
        sym = history[i]
        child = node.children[sym]
        if not child then
            child = createNode()
            node.children[sym] = child
        end
        node = child
    end
    return node
end

function getSymbolProbability(node: ContextNode, symbol: number): (number, number, number)
    cumLow = 0
    for i = 1, symbol - 1 do
        cumLow += node.counts[i]
    end
    cumHigh = cumLow + node.counts[symbol]
    total = node.total
    return cumLow, cumHigh, total
end

function getEscapeProbability(node: ContextNode): (number, number, number)
    numSeen = 0
    for i = 1, ALPHABET_SIZE - 1 do
        if node.counts[i] > 0 then
            numSeen += 1
        end
    end
    escapeCount = math.max(1, numSeen)
    total = node.total + escapeCount
    cumLow = node.total
    cumHigh = total
    return cumLow, cumHigh, total
end

function getSymbolProbabilityWithEscape(node: ContextNode, symbol: number): (number, number, number, boolean)
    if node.counts[symbol] == 0 then
        cumLow, cumHigh, total = getEscapeProbability(node)
        return cumLow, cumHigh, total, true
    end

    numSeen = 0
    for i = 1, ALPHABET_SIZE - 1 do
        if node.counts[i] > 0 then
            numSeen += 1
        end
    end
    escapeCount = math.max(1, numSeen)
    total = node.total + escapeCount

    cumLow = 0
    for i = 1, symbol - 1 do
        cumLow += node.counts[i]
    end
    cumHigh = cumLow + node.counts[symbol]
    return cumLow, cumHigh, total, false
end

function decodeSymbolFromContext(node: ContextNode, target: number, total: number): (number, number, number, boolean)
    numSeen = 0
    for i = 1, ALPHABET_SIZE - 1 do
        if node.counts[i] > 0 then
            numSeen += 1
        end
    end
    escapeCount = math.max(1, numSeen)

    cum = 0
    for i = 1, ALPHABET_SIZE - 1 do
        if node.counts[i] > 0 then
            if target < cum + node.counts[i] then
                return i, cum, cum + node.counts[i], false
            end
            cum += node.counts[i]
        end
    end
    return ESCAPE_SYMBOL, node.total, total, true
end

function updateModel(model: PPMModel, history: {number}, symbol: number)
    for order = 0, math.min(model.maxOrder, history.count) do
        node = ensureContext(model, history, order)
        node.counts[symbol] += 1
        node.total += 1
    end
    model.root.counts[symbol] += 1
    model.root.total += 1
end

function getTotalWithEscape(node: ContextNode): number
    numSeen = 0
    for i = 1, ALPHABET_SIZE - 1 do
        if node.counts[i] > 0 then
            numSeen += 1
        end
    end
    return node.total + math.max(1, numSeen)
end

return {
    createModel = createModel,
    getContext = getContext,
    getSymbolProbabilityWithEscape = getSymbolProbabilityWithEscape,
    decodeSymbolFromContext = decodeSymbolFromContext,
    updateModel = updateModel,
    getTotalWithEscape = getTotalWithEscape,
    ALPHABET_SIZE = ALPHABET_SIZE,
    ESCAPE_SYMBOL = ESCAPE_SYMBOL,
    MAX_ORDER = MAX_ORDER,
}
