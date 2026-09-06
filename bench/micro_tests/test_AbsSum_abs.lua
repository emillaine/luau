function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    abs = math.abs
    ts0 = os.clock()
    sum = 0
    for i=-500000,500000 do sum = sum + abs(i) end
    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "AbsSum: abs")