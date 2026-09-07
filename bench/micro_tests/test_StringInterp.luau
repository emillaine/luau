function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

bench.runCode(function()
    for j=1,1e6 do
        _ = "j=" .. tostring(j)
    end
end, "interp: tostring")

bench.runCode(function()
    for j=1,1e6 do
        _ = "j=" .. j
    end
end, "interp: concat")

bench.runCode(function()
    for j=1,1e6 do
        _ = string.format("j=%f", j)
    end
end, "interp: %f format")

bench.runCode(function()
    for j=1,1e6 do
        _ = string.format("j=%d", j)
    end
end, "interp: %d format")

bench.runCode(function()
    for j=1,1e6 do
        _ = string.format("j=%*", j)
    end
end, "interp: %* format")

bench.runCode(function()
    for j=1,1e6 do
        _ = `j={j}`
    end
end, "interp: interp number")

bench.runCode(function()
    ok = "hello!"
    for j=1,1e6 do
        _ = string.format("j=%s", ok)
    end
end, "interp: %s format")

bench.runCode(function()
	ok = "hello!"
    for j=1,1e6 do
        _ = `j={ok}`
    end
end, "interp: interp string")