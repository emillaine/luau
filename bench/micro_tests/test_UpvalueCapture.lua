function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

	tab = {}

	ts0 = os.clock()

	for i=1, 1_000_000 do
		j = i + 1
		tab[i] = function() return i,j end
	end

	ts1 = os.clock()

	return ts1-ts0
end

bench.runCode(test, "UpvalueCapture")