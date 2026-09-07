function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()
    t = table.create(250001, 0)

    for i=1,250000 do
        t[i] = i
    end

    t2 = table.create(250001, 100)

    ts0 = os.clock()
    table.move(t, 1, 250000, 1, t2)
    ts1 = os.clock()

    for i=1,250000-1 do
        assert(t2[i] == i)
    end

    return ts1-ts0
end

bench.runCode(test, "TableMove: table.create")
