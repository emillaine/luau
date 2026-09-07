# --bench-args: --fflags=DebugLuauUserDefinedClasses,DebugLuauUserDefinedClassesRuntime,LuauCallFeedback,LuauEmitCallFeedback
function prequire(name)
    success, result = pcall(require, name)
    return success and result
end
bench = script and require(script.Parent.bench_support)
    or prequire("bench_support")
    or require("../bench_support")

class Number
    public value

    function Swap(self, other)
        tmp = other.value
        other.value = self.value
        self.value = tmp
    end
end


bench.runCode(function()

    numbers = {}

    for i = 1, 100 do
        numbers[i] = Number.new({ value = math.random() })
    end

    for i = 1, 100_000 do
        for j = 1, 100 do
            numbers[j]:Swap(numbers[math.random(100)])
        end
    end

end, "OOP: field random access classes")
