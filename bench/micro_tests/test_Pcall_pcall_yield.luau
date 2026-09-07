function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    function test() coroutine.yield() return 1 end

    ts0 = os.clock()
    for i=0,100000 do
        co = coroutine.create(function() return pcall(test) end)
        coroutine.resume(co)
        coroutine.resume(co)
    end
    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "Pcall: pcall yield")