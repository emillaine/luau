function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    function pack(...)
        return {n = select('#', ...), ...}
    end

    ts0 = os.clock()

    for i=1,100000 do
        t = pack(1,2,3,4,5,6,7,8,9,10)
    end

    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "TableMarshal: {n=select,...}")