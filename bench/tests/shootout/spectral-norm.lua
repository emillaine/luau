--[[
MIT License

Copyright (c) 2017 Gabriel de Quadros Ligneul

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
-- The Computer Language Benchmarks Game
-- http://benchmarksgame.alioth.debian.org/
-- contributed by Mike Pall

function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

function test()

function A(i, j)
  ij = i+j-1
  return 1.0 / (ij * (ij-1) * 0.5 + i)
end

function Av(x, y, N)
  for i=1,N do
    a = 0
    for j=1,N do a = a + x[j] * A(i, j) end
    y[i] = a
  end
end

function Atv(x, y, N)
  for i=1,N do
    a = 0
    for j=1,N do a = a + x[j] * A(j, i) end
    y[i] = a
  end
end

function AtAv(x, y, t, N)
  Av(x, t, N)
  Atv(t, y, N)
end

N = tonumber(arg and arg[1]) or 100
u, v, t = {}, {}, {}
for i=1,N do u[i] = 1 end

for i=1,10 do AtAv(u, v, t, N) AtAv(v, u, t, N) end

vBv, vv = 0, 0
for i=1,N do
  ui, vi = u[i], v[i]
  vBv = vBv + ui*vi
  vv = vv + vi*vi
end
result = math.sqrt(vBv / vv)
print(string.format("%0.9f\n", result))

assert(N != 100 or math.abs(result - 1.274219991) < 1e-6)

end

bench.runCode(test, "spectral-norm")
