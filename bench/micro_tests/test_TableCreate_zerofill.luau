function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

	ts0 = os.clock()
	for i=1,100000 do
		t = table.create(100)
		for j=1,100 do t[j] = 0 end
	end
	ts1 = os.clock()

	return ts1-ts0
end

bench.runCode(test, "TableCreate: zerofill")