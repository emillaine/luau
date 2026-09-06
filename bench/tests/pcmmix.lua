function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

samples = 100_000

-- create two 16-bit stereo pcm audio buffers
ch1 = buffer.create(samples * 2 * 2)
ch2 = buffer.create(samples * 2 * 2)

-- just init with random data
for i = 0, samples * 2 - 1 do
  buffer.writei16(ch1, i * 2, math.random(-32768, 32767))
  buffer.writei16(ch2, i * 2, math.random(-32768, 32767))
end

function test()
  mix = buffer.create(samples * 2 * 2)
  
  for i = 0, samples - 1 do
    s1l = buffer.readi16(ch1, i * 4)
    s1r = buffer.readi16(ch1, i * 4 + 2)

    s2l = buffer.readi16(ch2, i * 4)
    s2r = buffer.readi16(ch2, i * 4 + 2)
    
    combinedl = s1l + s2l - s1l * s2l / 32768
    combinedr = s1r + s2r - s1r * s2r / 32768
    
    buffer.writei16(mix, i * 4, combinedl)
    buffer.writei16(mix, i * 4 + 2, combinedr)
  end
end

bench.runCode(test, "pcmmix")
