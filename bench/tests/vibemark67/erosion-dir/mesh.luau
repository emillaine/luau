-- Mesh generation from heightmap (vertices and normals)

export type Mesh = {
    vertices: {number},
    normals: {number},
    vertexCount: number,
}

function generateMesh(heightmap: {number}, size: number, scale: number): Mesh
    vertexCount = (size - 1) * (size - 1) * 6
    vertices = table.create(vertexCount * 3, 0)
    normals = table.create(vertexCount * 3, 0)
    vIdx = 1
    nIdx = 1

    for y = 0, size - 2 do
        for x = 0, size - 2 do
            h00 = heightmap[y * size + x + 1]
            h10 = heightmap[y * size + x + 2]
            h01 = heightmap[(y + 1) * size + x + 1]
            h11 = heightmap[(y + 1) * size + x + 2]

            x0 = x * scale
            x1 = (x + 1) * scale
            z0 = y * scale
            z1 = (y + 1) * scale

            -- Triangle 1: (x0,h00,z0), (x1,h10,z0), (x0,h01,z1)
            vertices[vIdx] = x0; vertices[vIdx+1] = h00 * scale; vertices[vIdx+2] = z0
            vertices[vIdx+3] = x1; vertices[vIdx+4] = h10 * scale; vertices[vIdx+5] = z0
            vertices[vIdx+6] = x0; vertices[vIdx+7] = h01 * scale; vertices[vIdx+8] = z1

            ux = x1 - x0; uy = (h10 - h00) * scale; uz = 0
            vx = 0; vy = (h01 - h00) * scale; vz = z1 - z0
            nx = uy * vz - uz * vy
            ny = uz * vx - ux * vz
            nz = ux * vy - uy * vx
            nLen = math.sqrt(nx*nx + ny*ny + nz*nz)
            if nLen > 0 then nx /= nLen; ny /= nLen; nz /= nLen end
            normals[nIdx] = nx; normals[nIdx+1] = ny; normals[nIdx+2] = nz
            normals[nIdx+3] = nx; normals[nIdx+4] = ny; normals[nIdx+5] = nz
            normals[nIdx+6] = nx; normals[nIdx+7] = ny; normals[nIdx+8] = nz
            vIdx += 9
            nIdx += 9

            -- Triangle 2: (x1,h10,z0), (x1,h11,z1), (x0,h01,z1)
            vertices[vIdx] = x1; vertices[vIdx+1] = h10 * scale; vertices[vIdx+2] = z0
            vertices[vIdx+3] = x1; vertices[vIdx+4] = h11 * scale; vertices[vIdx+5] = z1
            vertices[vIdx+6] = x0; vertices[vIdx+7] = h01 * scale; vertices[vIdx+8] = z1

            ux = 0; uy = (h11 - h10) * scale; uz = z1 - z0
            vx = x0 - x1; vy = (h01 - h10) * scale; vz = z1 - z0
            nx = uy * vz - uz * vy
            ny = uz * vx - ux * vz
            nz = ux * vy - uy * vx
            nLen = math.sqrt(nx*nx + ny*ny + nz*nz)
            if nLen > 0 then nx /= nLen; ny /= nLen; nz /= nLen end
            normals[nIdx] = nx; normals[nIdx+1] = ny; normals[nIdx+2] = nz
            normals[nIdx+3] = nx; normals[nIdx+4] = ny; normals[nIdx+5] = nz
            normals[nIdx+6] = nx; normals[nIdx+7] = ny; normals[nIdx+8] = nz
            vIdx += 9
            nIdx += 9
        end
    end

    return {
        vertices = vertices,
        normals = normals,
        vertexCount = vertexCount,
    }
end

function computeStats(heightmap: {number}, size: number): (number, number, number)
    minH = heightmap[1]
    maxH = heightmap[1]
    sumH = 0
    n = size * size
    for i = 1, n do
        h = heightmap[i]
        if h < minH then minH = h end
        if h > maxH then maxH = h end
        sumH += h
    end
    return minH, maxH, sumH / n
end

return {
    generateMesh = generateMesh,
    computeStats = computeStats,
}
