function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function mmul(matrix1, matrix2)
    shapeRows = #matrix1
    shapeColumns = #matrix2[1]
    result = table.create(shapeRows)
    for i = 1, shapeRows do
        result[i] = table.create(shapeColumns)
        for j = 1, shapeColumns do
            sum = 0
            for k = 1, shapeColumns do
                sum = sum + matrix1[i][k] * matrix2[k][j]
            end
            result[i][j] = sum
        end
    end
    return result
end

function test()
    n = 100

    mat = table.create(n)
    for i = 1, n do
        t = table.create(n)
        for k = 1, n do
            t[k] = math.random()
        end
        mat[i] = t
    end

    startTime = os.clock()

    result = mmul(mat, mat)

    return os.clock() - startTime
end

bench.runCode(test, "matrixmult")
