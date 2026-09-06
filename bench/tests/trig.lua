function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    function updateTransforms(matrixArray, amount, offset, scale, time)
        i = 0

        for x=0,amount-1 do
        for y=0,amount-1 do
        for z=0,amount-1 do
            tx = offset - x
            ty = offset - y
            tz = offset - z

            rx = 0
            ry = ( math.sin( x / 4 + time ) + math.sin( y / 4 + time ) + math.sin( z / 4 + time ) )
            rz = ry * 2

            ch = math.cos(rx)
            sh = math.sin(rx)
            ca = math.cos(ry)
            sa = math.sin(ry)
            cb = math.cos(rz)
            sb = math.sin(rz)

            m00 = ch * ca
            m01 = sh*sb - ch*sa*cb
            m02 = ch*sa*sb + sh*cb
            m10 = sa
            m11 = ca*cb
            m12 = -ca*sb
            m20 = -sh*ca
            m21 = sh*sa*cb + ch*sb
            m22 = -sh*sa*sb + ch*cb

            matrixArray[i * 16 + 1] = m00 * scale
            matrixArray[i * 16 + 2] = m01 * scale
            matrixArray[i * 16 + 3] = m02 * scale
            matrixArray[i * 16 + 4] = 0
            matrixArray[i * 16 + 5] = m10 * scale
            matrixArray[i * 16 + 6] = m11 * scale
            matrixArray[i * 16 + 7] = m12 * scale
            matrixArray[i * 16 + 8] = 0
            matrixArray[i * 16 + 9] = m20 * scale
            matrixArray[i * 16 + 10] = m21 * scale
            matrixArray[i * 16 + 11] = m22 * scale
            matrixArray[i * 16 + 12] = 0
            matrixArray[i * 16 + 13] = tx
            matrixArray[i * 16 + 14] = ty
            matrixArray[i * 16 + 15] = tz
            matrixArray[i * 16 + 16] = 1

            i = i + 1
        end
        end
        end
    end

    N = 40
    array = table.create(N*N*N*16)

    ts0 = os.clock()

    updateTransforms(array, N, -N/2, 0.5, 1/60)

    ts1 = os.clock()

    return ts1-ts0
end

bench.runCode(test, "trig")