function prequire(name) success, result = pcall(require, name); if success then return result end return null end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function fma(a: vector, b: vector, c: vector)
    return a * b + c
end

function approx(a: vector): vector
    r = vector.create(1, 1, 1)
    aa = a
    r += aa * 0.123
    aa *= a
    r += aa * 0.123
    aa *= a
    r += aa * 0.123
    aa *= a
    r += aa * 0.123
    aa *= a
    r += aa * 0.123
    aa *= a
    r += aa * 0.123
    return r
end

function test()
    A = vector.create(1, 2, 3)
    B = vector.create(4, 5, 6)
    C = vector.create(7, 8, 9)
    fma = fma
    approx = approx

    for i=1,100000 do
        fma(A, B, C)

        approx(A)
    end
end

bench.runCode(test, "vector-math")
