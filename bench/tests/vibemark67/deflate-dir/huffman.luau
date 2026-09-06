-- Huffman coding for DEFLATE

bitstream = require("./bitstream")

export type HuffTree = {
    codes: {number},
    lengths: {number},
    maxLen: number,
}

function buildFromLengths(lengths: {number}, maxSymbol: number): HuffTree
    maxLen = 0
    for i = 1, maxSymbol do
        if lengths[i] and lengths[i] > maxLen then
            maxLen = lengths[i]
        end
    end
    if maxLen == 0 then maxLen = 1 end

    blCount = table.create(maxLen + 1, 0)
    for i = 1, maxSymbol do
        len = lengths[i] or 0
        if len > 0 then
            blCount[len + 1] = (blCount[len + 1] or 0) + 1
        end
    end

    nextCode = table.create(maxLen + 2, 0)
    code = 0
    for bits = 1, maxLen do
        code = bit32.lshift(code + (blCount[bits] or 0), 1)
        nextCode[bits + 1] = code
    end

    codes = table.create(maxSymbol, 0)
    for i = 1, maxSymbol do
        len = lengths[i] or 0
        if len > 0 then
            codes[i] = nextCode[len + 1]
            nextCode[len + 1] += 1
        end
    end

    return {
        codes = codes,
        lengths = lengths,
        maxLen = maxLen,
    }
end

function writeCode(writer: bitstream.BitWriter, tree: HuffTree, symbol: number)
    len = tree.lengths[symbol] or 0
    code = tree.codes[symbol] or 0
    reversed = 0
    for i = 1, len do
        reversed = bit32.bor(bit32.lshift(reversed, 1), bit32.band(code, 1))
        code = bit32.rshift(code, 1)
    end
    writer:writeBits(reversed, len)
end

function buildDecodeTable(tree: HuffTree, maxSymbol: number): {{symbol: number, length: number}}
    tableSize = bit32.lshift(1, tree.maxLen)
    decodeTable = table.create(tableSize)

    for sym = 1, maxSymbol do
        len = tree.lengths[sym] or 0
        if len > 0 then
            code = tree.codes[sym]
            reversed = 0
            for i = 1, len do
                reversed = bit32.bor(bit32.lshift(reversed, 1), bit32.band(code, 1))
                code = bit32.rshift(code, 1)
            end
            fill = bit32.lshift(1, tree.maxLen - len)
            for i = 0, fill - 1 do
                idx = bit32.bor(reversed, bit32.lshift(i, len))
                decodeTable[idx + 1] = {symbol = sym, length = len}
            end
        end
    end

    return decodeTable
end

function buildLookup(lengths: {number}, codes: {number}, maxSymbol: number, maxLen: number): {number}
    tableSize = bit32.lshift(1, maxLen)
    lookup = table.create(tableSize, 0)
    for sym = 1, maxSymbol do
        len = lengths[sym] or 0
        if len > 0 then
            code = codes[sym]
            reversed = 0
            for i = 1, len do
                reversed = bit32.bor(bit32.lshift(reversed, 1), bit32.band(code, 1))
                code = bit32.rshift(code, 1)
            end
            fill = bit32.lshift(1, maxLen - len)
            for i = 0, fill - 1 do
                idx = bit32.bor(reversed, bit32.lshift(i, len)) + 1
                lookup[idx] = bit32.bor(bit32.lshift(sym, 8), len)
            end
        end
    end
    return lookup
end

function decodeSymbol(reader: bitstream.BitReader, lookup: {number}, maxLen: number): number
    while reader.bitCount < maxLen do
        if reader.pos > #reader.data then
            reader.bitCount += 8
        else
            reader.bitBuf = bit32.bor(reader.bitBuf, bit32.lshift(reader.data[reader.pos], reader.bitCount))
            reader.pos += 1
            reader.bitCount += 8
        end
    end
    peekBits = bit32.band(reader.bitBuf, bit32.lshift(1, maxLen) - 1)
    entry = lookup[peekBits + 1]
    sym = bit32.rshift(entry, 8)
    len = bit32.band(entry, 0xFF)
    reader.bitBuf = bit32.rshift(reader.bitBuf, len)
    reader.bitCount -= len
    return sym
end

function buildFixedLitTree(): HuffTree
    lengths = table.create(288, 0)
    for i = 1, 144 do lengths[i] = 8 end
    for i = 145, 256 do lengths[i] = 9 end
    for i = 257, 280 do lengths[i] = 7 end
    for i = 281, 288 do lengths[i] = 8 end
    return buildFromLengths(lengths, 288)
end

function buildFixedDistTree(): HuffTree
    lengths = table.create(32, 5)
    return buildFromLengths(lengths, 32)
end

return {
    buildFromLengths = buildFromLengths,
    writeCode = writeCode,
    buildDecodeTable = buildDecodeTable,
    buildLookup = buildLookup,
    decodeSymbol = decodeSymbol,
    buildFixedLitTree = buildFixedLitTree,
    buildFixedDistTree = buildFixedDistTree,
}
