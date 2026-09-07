# --bench-args: --fflags=DebugLuauUserDefinedClasses,DebugLuauUserDefinedClassesRuntime,LuauCallFeedback,LuauEmitCallFeedback
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

class Number
    public x
    function Get(self)
        return self.x
    end
end

function test()

    ts0 = os.clock()
    for i=1,1_000_000 do
        n = Number.new({ x = 42 })
    end
    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "OOP: class constructor")
