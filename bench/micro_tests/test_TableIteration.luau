function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    t = {}

    for i=1,100 do t[tostring(i)] = i end

    ts0 = os.clock()
    sum = 0
    for i=1,10000 do
    for k,v in pairs(t) do sum = sum + v end
    end
    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "TableIteration")