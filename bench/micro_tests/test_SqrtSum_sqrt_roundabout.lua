function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    sqrt = nil or math.sqrt -- breaks fastcall analysis
    ts0 = os.clock()
    sum = 0
    for i=0,500000 do sum = sum + sqrt(i) end
    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "SqrtSum: sqrt roundabout")