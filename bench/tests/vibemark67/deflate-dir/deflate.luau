-- DEFLATE compressor and decompressor

bitstream = require("./bitstream")
huffman = require("./huffman")
lz77 = require("./lz77")

lengthBase = {
    3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258,
}
lengthExtra = {
    0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0,
}
distBase = {
    1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,
    1025,1537,2049,3073,4097,6145,8193,12289,16385,24577,
}
distExtra = {
    0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,
}

function lengthToCode(length: number): (number, number, number)
    for i = 1, #lengthBase do
        if i == #lengthBase or lengthBase[i + 1] > length then
            code = 257 + i
            extra = lengthExtra[i]
            extraBits = length - lengthBase[i]
            return code, extra, extraBits
        end
    end
    return 286, 0, 0
end

function distToCode(dist: number): (number, number, number)
    for i = 1, #distBase do
        if i == #distBase or distBase[i + 1] > dist then
            code = i
            extra = distExtra[i]
            extraBits = dist - distBase[i]
            return code, extra, extraBits
        end
    end
    return 30, 0, 0
end

function compress(data: {number}): {number}
    writer = bitstream.BitWriter.new()
    tokens = lz77.compress(data)
    litTree = huffman.buildFixedLitTree()
    distTree = huffman.buildFixedDistTree()

    writer:writeBits(1, 1) -- final block
    writer:writeBits(1, 2) -- fixed Huffman

    for _, token in tokens do
        if token.literal then
            huffman.writeCode(writer, litTree, token.literal + 1)
        else
            match = token.match as lz77.Match
            lenCode, lenExtra, lenExtraBits = lengthToCode(match.length)
            huffman.writeCode(writer, litTree, lenCode)
            if lenExtra > 0 then
                writer:writeBits(lenExtraBits, lenExtra)
            end
            dCode, dExtra, dExtraBits = distToCode(match.distance)
            huffman.writeCode(writer, distTree, dCode)
            if dExtra > 0 then
                writer:writeBits(dExtraBits, dExtra)
            end
        end
    end

    huffman.writeCode(writer, litTree, 257) -- end of block (symbol 256 is at index 257)
    return writer:getBytes()
end

function decompress(compressed: {number}, originalSize: number): {number}
    reader = bitstream.BitReader.new(compressed)
    output = table.create(originalSize, 0)
    outPos = 1

    bfinal = reader:readBits(1)
    btype = reader:readBits(2)

    litTree = huffman.buildFixedLitTree()
    distTree = huffman.buildFixedDistTree()
    litLookup = huffman.buildLookup(litTree.lengths, litTree.codes, 288, litTree.maxLen)
    distLookup = huffman.buildLookup(distTree.lengths, distTree.codes, 32, distTree.maxLen)

    while true do
        sym = huffman.decodeSymbol(reader, litLookup, litTree.maxLen)
        if sym == 257 then
            break
        else if sym <= 256 then
            output[outPos] = sym - 1
            outPos += 1
        else
            lenIdx = sym - 257
            length = lengthBase[lenIdx]
            extra = lengthExtra[lenIdx]
            if extra > 0 then
                length += reader:readBits(extra)
            end

            distSym = huffman.decodeSymbol(reader, distLookup, distTree.maxLen)
            dist = distBase[distSym]
            dExtra = distExtra[distSym]
            if dExtra > 0 then
                dist += reader:readBits(dExtra)
            end

            for i = 1, length do
                output[outPos] = output[outPos - dist]
                outPos += 1
            end
        end
    end

    return output
end

return {
    compress = compress,
    decompress = decompress,
}
