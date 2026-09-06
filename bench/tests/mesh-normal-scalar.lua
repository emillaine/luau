--!strict
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

function test()

    type Vertex = {
        pX: number, pY: number, pZ: number,
        uvX: number, uvY: number, uvZ: number,
        nX: number, nY: number, nZ: number,
        tX: number, tY: number, tZ: number,
        bX: number, bY: number, bZ: number,
        h: number
    }

    grid_size = 100

    mesh = {
        vertices = table.create(grid_size * grid_size),
        indices = table.create((grid_size - 1) * (grid_size - 1) * 6),
        triangle_cone_p = table.create((grid_size - 1) * (grid_size - 1) * 2),
        triangle_cone_n = table.create((grid_size - 1) * (grid_size - 1) * 2)
    }

    function init_vertices()
        i = 1
        for y = 1,grid_size do
            for x = 1,grid_size do
                v = {}

                v.pX = x
                v.pY = y
                v.pZ = math.cos(x) + math.sin(y)

                v.uvX = (x-1)/(grid_size-1)
                v.uvY = (y-1)/(grid_size-1)
                v.uvZ = 0

                v.nX = 0
                v.nY = 0
                v.nZ = 0

                v.bX = 0
                v.bY = 0
                v.bZ = 0

                v.tX = 0
                v.tY = 0
                v.tZ = 0

                v.h = 0

                mesh.vertices[i] = v
                i += 1
            end
        end
    end

    function init_indices()
        i = 1
        for y = 1,grid_size-1 do
            for x = 1,grid_size-1 do
                mesh.indices[i] = x + (y-1)*grid_size
                i += 1
                mesh.indices[i] = x + y*grid_size
                i += 1
                mesh.indices[i] = (x+1) + (y-1)*grid_size
                i += 1
                mesh.indices[i] = (x+1) + (y-1)*grid_size
                i += 1
                mesh.indices[i] = x + y*grid_size
                i += 1
                mesh.indices[i] = (x+1) + y*grid_size
                i += 1
            end
        end
    end

    function calculate_normals()
        norm_sum = 0

        for i = 1,#mesh.indices,3 do
            a = mesh.vertices[mesh.indices[i]]
            b = mesh.vertices[mesh.indices[i + 1]]
            c = mesh.vertices[mesh.indices[i + 2]]

            abx = a.pX - b.pX
            aby = a.pY - b.pY
            abz = a.pZ - b.pZ

            acx = a.pX - c.pX
            acy = a.pY - c.pY
            acz = a.pZ - c.pZ

            nx = aby * acz - abz * acy;
            ny = abz * acx - abx * acz;
            nz = abx * acy - aby * acx;

            a.nX += nx
            a.nY += ny
            a.nZ += nz

            b.nX += nx
            b.nY += ny
            b.nZ += nz

            c.nX += nx
            c.nY += ny
            c.nZ += nz
        end

        for _,v in mesh.vertices do
            magnitude = math.sqrt(v.nX * v.nX + v.nY * v.nY + v.nZ * v.nZ)

            v.nX /= magnitude
            v.nY /= magnitude
            v.nZ /= magnitude

            norm_sum += v.nX * v.nX + v.nY * v.nY + v.nZ * v.nZ
        end

        return norm_sum
    end

    function compute_triangle_cones()
        mesh_area = 0

        pos = 1

        for i = 1,#mesh.indices,3 do
            p0 = mesh.vertices[mesh.indices[i]]
            p1 = mesh.vertices[mesh.indices[i + 1]]
            p2 = mesh.vertices[mesh.indices[i + 2]]

            p10x = p1.pX - p0.pX
            p10y = p1.pY - p0.pY
            p10z = p1.pZ - p0.pZ
            p20x = p2.pX - p0.pX
            p20y = p2.pY - p0.pY
            p20z = p2.pZ - p0.pZ

            normalx = p10y * p20z - p10z * p20y;
            normaly = p10z * p20x - p10x * p20z;
            normalz = p10x * p20y - p10y * p20x;

            area = math.sqrt(normalx * normalx + normaly * normaly + normalz * normalz)
            invarea = if area == 0 then 0 else 1 / area;

            rx = (p0.pX + p1.pX + p2.pX) / 3
            ry = (p0.pY + p1.pY + p2.pY) / 3
            rz = (p0.pZ + p1.pZ + p2.pZ) / 3

            mesh.triangle_cone_p[pos] = { x = rx, y = ry, z = rz }
            mesh.triangle_cone_n[pos] = { x = normalx * invarea, y = normaly * invarea, z = normalz * invarea}
            pos += 1

            mesh_area += area
        end

        return mesh_area
    end

    function compute_tangent_space()
        checksum = 0

        for i = 1,#mesh.indices,3 do
            a = mesh.vertices[mesh.indices[i]]
            b = mesh.vertices[mesh.indices[i + 1]]
            c = mesh.vertices[mesh.indices[i + 2]]

            x1 = b.pX - a.pX
            x2 = c.pX - a.pX
            y1 = b.pY - a.pY
            y2 = c.pY - a.pY
            z1 = b.pZ - a.pZ
            z2 = c.pZ - a.pZ

            s1 = b.uvX - a.uvX
            s2 = c.uvX - a.uvX
            t1 = b.uvY - a.uvY
            t2 = c.uvY - a.uvY

            r = 1.0 / (s1 * t2 - s2 * t1);
            sdirX = (t2 * x1 - t1 * x2) * r
            sdirY = (t2 * y1 - t1 * y2) * r
            sdirZ = (t2 * z1 - t1 * z2) * r
            tdirX = (s1 * x2 - s2 * x1) * r
            tdirY = (s1 * y2 - s2 * y1) * r
            tdirZ = (s1 * z2 - s2 * z1) * r

            a.tX += sdirX
            a.tY += sdirY
            a.tZ += sdirZ
            b.tX += sdirX
            b.tY += sdirY
            b.tZ += sdirZ
            c.tX += sdirX
            c.tY += sdirY
            c.tZ += sdirZ

            a.bX += tdirX
            a.bY += tdirY
            a.bZ += tdirZ
            b.bX += tdirX
            b.bY += tdirY
            b.bZ += tdirZ
            c.bX += tdirX
            c.bY += tdirY
            c.bZ += tdirZ
        end

        for _,v in mesh.vertices do
            tX = v.tX
            tY = v.tY
            tZ = v.tZ

            -- Gram-Schmidt orthogonalize
            ndt = v.nX * tX + v.nY * tY + v.nZ * tZ
            tmnsX = tX - v.nX * ndt
            tmnsY = tY - v.nY * ndt
            tmnsZ = tZ - v.nZ * ndt
            l = math.sqrt(tmnsX * tmnsX + tmnsY * tmnsY + tmnsZ * tmnsZ)

            invl = 1 / l
            v.tX = tmnsX * invl
            v.tY = tmnsY * invl
            v.tZ = tmnsZ * invl

            normalx = v.nY * tZ - v.nZ * tY;
            normaly = v.nZ * tX - v.nX * tZ;
            normalz = v.nX * tY - v.nY * tX;

            ht = normalx * v.bX + normaly * v.bY + normalz * v.bZ

            v.h = ht < 0 and -1 or 1

            checksum += v.tX + v.h
        end

        return checksum
    end

    init_vertices()
    init_indices()
    calculate_normals()
    compute_triangle_cones()
    checksum = compute_tangent_space()

    assert(math.abs(checksum + 1323.4993) < 1e-2)
end

bench.runCode(test, "mesh-normal-scalar")
