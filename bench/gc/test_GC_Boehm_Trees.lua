#!nonstrict
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

stretchTreeDepth = 18 # about 16Mb
longLivedTreeDepth = 16 # about 4Mb
arraySize = 500000 #about 4Mb
minTreeDepth = 4
maxTreeDepth = 16

# Nodes used by a tree of a given size
function treeSize(i)
    return bit32.lshift(1, i + 1) - 1
end

function getNumIters(i)
    return 2 * treeSize(stretchTreeDepth) / treeSize(i)
end

# Build tree top down, assigning to older objects. 
function populate(depth, thisNode)
    if depth <= 0 then
        return
    end

    depth = depth - 1
    thisNode.left  = {}
    thisNode.right = {}
    populate(depth, thisNode.left)
    populate(depth, thisNode.right)
end

# Build tree bottom-up
function makeTree(depth)
    if depth <= 0 then
        return {}
    end

    return { left = makeTree(depth - 1), right = makeTree(depth - 1) }
end

function timeConstruction(depth)
    numIters = getNumIters(depth)
    tempTree = {}

    for i = 1, numIters do
        tempTree = {}
        populate(depth, tempTree)
        tempTree = null
    end

    for i = 1, numIters do
        tempTree = makeTree(depth)
        tempTree = null
    end
end

function test()
    # Stretch the memory space quickly
    _tempTree = makeTree(stretchTreeDepth)
    _tempTree = null

    # Create a long lived object
    longLivedTree = {}
    populate(longLivedTreeDepth, longLivedTree)

    # Create long-lived array, filling half of it
    array = {}
    for i = 1, arraySize/2 do
        array[i] = 1.0 / i
    end

    for d = minTreeDepth,maxTreeDepth,2 do
        timeConstruction(d)
    end
end

bench.runs = 6
bench.extraRuns = 2

bench.runCode(test, "GC: Boehm tree")
