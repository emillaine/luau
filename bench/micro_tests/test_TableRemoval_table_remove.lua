function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    ts0 = os.clock()

    iterations = 25000

    t = table.create(iterations, 100)

    for j=1,100 do
        table.remove(t, 1)
    end

    assert(t.count == (iterations - 100))

    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "TableRemoval: table.remove")
