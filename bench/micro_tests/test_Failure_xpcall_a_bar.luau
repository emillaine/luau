function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    function test(a) return a.bar end
    function err(e) return e end

    ts0 = os.clock()
    for i=0,10000 do xpcall(test, err) end
    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "Failure: xpcall a.bar")