function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

deflate = require("./deflate-dir/deflate")

function test()

# DEFLATE benchmark: compress and decompress procedurally generated text

function generateCorpus(size: number): {number}
    data = table.create(size, 0)
    seed = 73921
    words = {
        "the ", "quick ", "brown ", "fox ", "jumps ", "over ", "lazy ", "dog ",
        "and ", "then ", "runs ", "away ", "from ", "big ", "cat ", "who ",
        "was ", "sleeping ", "under ", "old ", "oak ", "tree ", "near ",
        "river ", "bank ", "where ", "fish ", "swim ", "all ", "day ",
        "long ", "until ", "night ", "falls ", "upon ", "land ",
        "bringing ", "peace ", "quiet ", "darkness ", "throughout ",
        "entire ", "valley ", "below ", "mountain ", "peaks ",
        "covered ", "with ", "fresh ", "white ", "snow ",
    }
    pos = 1
    while pos <= size do
        seed = bit32.band(seed * 1103515245 + 12345, 0x7FFFFFFF)
        wordIdx = (seed % words.count) + 1
        word = words[wordIdx]
        for i = 1, word.count do
            if pos > size then break end
            data[pos] = string.byte(word, i)
            pos += 1
        end
        seed = bit32.band(seed * 1103515245 + 12345, 0x7FFFFFFF)
        if seed % 20 == 0 and pos <= size then
            data[pos] = 10 # newline
            pos += 1
        end
    end
    return data
end

CORPUS_SIZE = 65536
ITERATIONS = 5

corpus = generateCorpus(CORPUS_SIZE)
totalCompressed = 0
totalDecompressed = 0
verified = true

for iter = 1, ITERATIONS do
    compressed = deflate.compress(corpus)
    totalCompressed += compressed.count

    decompressed = deflate.decompress(compressed, corpus.count)
    totalDecompressed += decompressed.count

    if decompressed.count != corpus.count then
        verified = false
    else
        for i = 1, math.min(1000, corpus.count) do
            if decompressed[i] != corpus[i] then
                verified = false
                break
            end
        end
    end
end

ratio = totalCompressed / (CORPUS_SIZE * ITERATIONS) * 100
print(string.format("Deflate benchmark complete: %d iterations, ratio=%.1f%%, verified=%s",
    ITERATIONS, ratio, tostring(verified)))

if not verified then
    error("NOT VERIFIED")
end

end

bench.runCode(test, "deflate")
