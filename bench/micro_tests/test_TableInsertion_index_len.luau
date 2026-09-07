function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    ts0 = os.clock()

    for i=1,300 do
        t = {}
        for j=1,1000 do
            t[t.count+1] = j
        end
    end

    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "TableInsertion: t[#t+1]")