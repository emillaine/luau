-- LZ77 match finding with hash-chained sliding window

WINDOW_SIZE = 32768
MAX_MATCH = 258
MIN_MATCH = 3
HASH_BITS = 15
HASH_SIZE = bit32.lshift(1, HASH_BITS)
HASH_MASK = HASH_SIZE - 1

export type Match = {
    length: number,
    distance: number,
}

export type LZ77Token = {
    literal: number?,
    match: Match?,
}

function hashFunc(data: {number}, pos: number): number
    if pos + 2 > #data then return 0 end
    h = bit32.bxor(data[pos], bit32.lshift(data[pos + 1], 5), bit32.lshift(data[pos + 2], 10))
    return bit32.band(h, HASH_MASK)
end

function findMatch(data: {number}, pos: number, head: {number}, prev: {number}, maxChain: number): Match?
    bestLen = MIN_MATCH - 1
    bestDist = 0
    dataLen = #data
    maxLen = math.min(MAX_MATCH, dataLen - pos + 1)

    if maxLen < MIN_MATCH then return nil end

    hash = hashFunc(data, pos)
    chainPos = head[hash + 1]
    chainCount = 0
    windowStart = math.max(1, pos - WINDOW_SIZE)

    while chainPos >= windowStart and chainCount < maxChain do
        chainCount += 1
        if data[chainPos + bestLen] == data[pos + bestLen] then
            len = 0
            while len < maxLen and data[chainPos + len] == data[pos + len] do
                len += 1
            end
            if len > bestLen then
                bestLen = len
                bestDist = pos - chainPos
                if len == maxLen then break end
            end
        end
        prevIdx = ((chainPos - 1) % WINDOW_SIZE) + 1
        chainPos = prev[prevIdx]
        if chainPos < windowStart then break end
    end

    if bestLen >= MIN_MATCH then
        return {length = bestLen, distance = bestDist}
    end
    return nil
end

function compress(data: {number}): {LZ77Token}
    tokens = {}
    head = table.create(HASH_SIZE, 0)
    prev = table.create(WINDOW_SIZE, 0)
    pos = 1
    dataLen = #data

    while pos <= dataLen do
        match = nil
        if pos + MIN_MATCH - 1 <= dataLen then
            match = findMatch(data, pos, head, prev, 64)
        end

        if match then
            table.insert(tokens, {literal = nil, match = match})
            for i = 0, match.length - 1 do
                if pos + i + 2 <= dataLen then
                    hash = hashFunc(data, pos + i)
                    idx = ((pos + i - 1) % WINDOW_SIZE) + 1
                    prev[idx] = head[hash + 1]
                    head[hash + 1] = pos + i
                end
            end
            pos += match.length
        else
            table.insert(tokens, {literal = data[pos], match = nil})
            if pos + 2 <= dataLen then
                hash = hashFunc(data, pos)
                idx = ((pos - 1) % WINDOW_SIZE) + 1
                prev[idx] = head[hash + 1]
                head[hash + 1] = pos
            end
            pos += 1
        end
    end

    return tokens
end

return {
    compress = compress,
    MIN_MATCH = MIN_MATCH,
    MAX_MATCH = MAX_MATCH,
    WINDOW_SIZE = WINDOW_SIZE,
}
