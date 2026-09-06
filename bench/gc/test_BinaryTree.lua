function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

  -- The Computer Language Benchmarks Game
  -- http://benchmarksgame.alioth.debian.org/
  -- contributed by Mike Pall

  function BottomUpTree(item, depth)
    if depth > 0 then
      i = item + item
      depth = depth - 1
      left, right = BottomUpTree(i-1, depth), BottomUpTree(i, depth)
      return { item, left, right }
    else
      return { item }
    end
  end

  function ItemCheck(tree)
    if tree[2] then
      return tree[1] + ItemCheck(tree[2]) - ItemCheck(tree[3])
    else
      return tree[1]
    end
  end

  N = 10
  mindepth = 4
  maxdepth = mindepth + 2
  if maxdepth < N then maxdepth = N end

  ts0 = os.clock()

  do
    stretchdepth = maxdepth + 1
    stretchtree = BottomUpTree(0, stretchdepth)
  end

  longlivedtree = BottomUpTree(0, maxdepth)

  for depth=mindepth,maxdepth,2 do
    iterations = 2 ^ (maxdepth - depth + mindepth)
    check = 0
    for i=1,iterations do
      check = check + ItemCheck(BottomUpTree(1, depth)) +
              ItemCheck(BottomUpTree(-1, depth))
    end
  end

  ts1 = os.clock()

  return ts1 - ts0
end

bench.runCode(test, "BinaryTree")