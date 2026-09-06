function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()
    t = {}

    max = 10000
    iters = 50000

    for i = 1,iters do
        is = tostring(i)
        input = string.rep(is, 1000 / #is)

        t[is] = input

        -- remove old entries
        if i > max then
            t[tostring(i - max)] = null
        end
    end
end

bench.runCode(test, "GC: hashtable keys and values")
