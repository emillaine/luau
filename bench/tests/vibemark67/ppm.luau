function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

ppm = require("./ppm-dir/ppm")

function test()

# PPM benchmark: compress and decompress a procedurally generated corpus

function generateCorpus(size: number, seed: number): {number}
    data = table.create(size, 0)
    phrases = {
        "the quick brown fox jumps over the lazy dog ",
        "to be or not to be that is the question ",
        "all that glitters is not gold ",
        "a journey of a thousand miles begins with a single step ",
        "in the beginning was the word and the word was with god ",
        "it was the best of times it was the worst of times ",
        "call me ishmael some years ago never mind how long precisely ",
        "it is a truth universally acknowledged that a single man ",
        "happy families are all alike every unhappy family is unhappy ",
        "the world is full of obvious things which nobody ever observes ",
    }
    pos = 1
    while pos <= size do
        seed = bit32.band(seed * 1103515245 + 12345, 0x7FFFFFFF)
        phraseIdx = (seed % phrases.count) + 1
        phrase = phrases[phraseIdx]
        for i = 1, phrase.count do
            if pos > size then break end
            data[pos] = string.byte(phrase, i)
            pos += 1
        end
        seed = bit32.band(seed * 1103515245 + 12345, 0x7FFFFFFF)
        if seed % 10 == 0 then
            seed = bit32.band(seed * 1103515245 + 12345, 0x7FFFFFFF)
            upper = (seed % 26) + 65
            if pos <= size then
                data[pos] = upper
                pos += 1
            end
        end
    end
    return data
end

CORPUS_SIZE = 4096
ITERATIONS = 3
SEED = 314159

corpus = generateCorpus(CORPUS_SIZE, SEED)
totalCompressed = 0
totalDecompressed = 0
verified = true

for iter = 1, ITERATIONS do
    compressed = ppm.compress(corpus)
    totalCompressed += compressed.count

    decompressed = ppm.decompress(compressed, corpus.count)
    totalDecompressed += decompressed.count

    if decompressed.count != corpus.count then
        verified = false
    else
        for i = 1, corpus.count do
            if decompressed[i] != corpus[i] then
                verified = false
                break
            end
        end
    end
end

ratio = totalCompressed / (CORPUS_SIZE * ITERATIONS) * 100
print(string.format("PPM benchmark complete: %d iterations, size=%d, ratio=%.1f%%, verified=%s",
    ITERATIONS, CORPUS_SIZE, ratio, tostring(verified)))
if not verified then
    error("NOT VERIFIED")
end

end

bench.runCode(test, "ppm")
