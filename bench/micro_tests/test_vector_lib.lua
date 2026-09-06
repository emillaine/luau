function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

bench.runCode(function()
	for i=1,1000000 do
		vector.create(i, 2, 3)
		vector.create(i, 2, 3)
		vector.create(i, 2, 3)
		vector.create(i, 2, 3)
		vector.create(i, 2, 3)
	end
end, "vector: create")

-- TODO: add more tests