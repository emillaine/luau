function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    Number = {}
    Number.__index = Number

    function Number.new(v)
        self = {
            value = v
        }
        setmetatable(self, Number)
        return self
    end

    function Number:Get()
        return self.value
    end

    n = Number.new(42)

    ts0 = os.clock()
    for i=1,10_000_000 do
        _ = n:Get()
    end
    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "OOP: method call")