# --bench-args: --fflags=DebugLuauUserDefinedClasses,DebugLuauUserDefinedClassesRuntime,LuauCallFeedback,LuauEmitCallFeedback
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

class Number
    public value
    function Get(self)
        return self.value
    end
end

function test()

    n = Number.new({ value = 42 })

    ts0 = os.clock()
    for i=1,10_000_000 do
        _ = n:Get()
    end
    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "OOP: method call classes")
