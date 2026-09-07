# Hydraulic and thermal erosion simulation

function hydraulicErosion(
    heightmap: {number},
    size: number,
    iterations: number,
    seed: number
): {number}
    map = table.create(size * size, 0)
    table.move(heightmap, 1, size * size, 1, map)

    inertia = 0.05
    capacity = 4.0
    deposition = 0.3
    erosionRate = 0.3
    evaporation = 0.01
    gravity = 4.0
    minSlope = 0.01
    maxDropletLife = 30

    for iter = 1, iterations do
        seed = bit32.band(seed * 1103515245 + 12345, 0x7FFFFFFF)
        px = (seed % (size - 2)) + 1
        seed = bit32.band(seed * 1103515245 + 12345, 0x7FFFFFFF)
        py = (seed % (size - 2)) + 1

        posX = px + 0.5
        posY = py + 0.5
        dirX = 0.0
        dirY = 0.0
        speed = 1.0
        water = 1.0
        sediment = 0.0

        for life = 1, maxDropletLife do
            cellX = math.floor(posX)
            cellY = math.floor(posY)

            if cellX < 1 or cellX >= size - 1 or cellY < 1 or cellY >= size - 1 then
                break
            end

            offsetX = posX - cellX
            offsetY = posY - cellY

            idx00 = cellY * size + cellX + 1
            idx10 = cellY * size + cellX + 2
            idx01 = (cellY + 1) * size + cellX + 1
            idx11 = (cellY + 1) * size + cellX + 2

            h00 = map[idx00]
            h10 = map[idx10]
            h01 = map[idx01]
            h11 = map[idx11]

            gradX = (h10 - h00) * (1 - offsetY) + (h11 - h01) * offsetY
            gradY = (h01 - h00) * (1 - offsetX) + (h11 - h10) * offsetX

            dirX = dirX * inertia - gradX * (1 - inertia)
            dirY = dirY * inertia - gradY * (1 - inertia)

            dirLen = math.sqrt(dirX * dirX + dirY * dirY)
            if dirLen < 0.0001 then
                seed = bit32.band(seed * 1103515245 + 12345, 0x7FFFFFFF)
                angle = (seed % 628) / 100.0
                dirX = math.cos(angle)
                dirY = math.sin(angle)
                dirLen = 1
            end
            dirX /= dirLen
            dirY /= dirLen

            newPosX = posX + dirX
            newPosY = posY + dirY

            newCellX = math.floor(newPosX)
            newCellY = math.floor(newPosY)
            if newCellX < 1 or newCellX >= size - 1 or newCellY < 1 or newCellY >= size - 1 then
                break
            end

            newOffX = newPosX - newCellX
            newOffY = newPosY - newCellY
            nIdx00 = newCellY * size + newCellX + 1
            nIdx10 = newCellY * size + newCellX + 2
            nIdx01 = (newCellY + 1) * size + newCellX + 1
            nIdx11 = (newCellY + 1) * size + newCellX + 2

            newHeight = map[nIdx00] * (1 - newOffX) * (1 - newOffY)
                + map[nIdx10] * newOffX * (1 - newOffY)
                + map[nIdx01] * (1 - newOffX) * newOffY
                + map[nIdx11] * newOffX * newOffY

            oldHeight = h00 * (1 - offsetX) * (1 - offsetY)
                + h10 * offsetX * (1 - offsetY)
                + h01 * (1 - offsetX) * offsetY
                + h11 * offsetX * offsetY

            heightDiff = newHeight - oldHeight

            sedimentCapacity = math.max(-heightDiff, minSlope) * speed * water * capacity
            if sedimentCapacity < 0 then sedimentCapacity = 0 end

            if sediment > sedimentCapacity or heightDiff > 0 then
                amount = null
                if heightDiff > 0 then
                    amount = math.min(heightDiff, sediment)
                else
                    amount = (sediment - sedimentCapacity) * deposition
                end
                sediment -= amount

                map[idx00] += amount * (1 - offsetX) * (1 - offsetY)
                map[idx10] += amount * offsetX * (1 - offsetY)
                map[idx01] += amount * (1 - offsetX) * offsetY
                map[idx11] += amount * offsetX * offsetY
            else
                amount = math.min((sedimentCapacity - sediment) * erosionRate, -heightDiff)
                sediment += amount

                map[idx00] -= amount * (1 - offsetX) * (1 - offsetY)
                map[idx10] -= amount * offsetX * (1 - offsetY)
                map[idx01] -= amount * (1 - offsetX) * offsetY
                map[idx11] -= amount * offsetX * offsetY
            end

            speed = math.sqrt(math.max(0, speed * speed + heightDiff * gravity))
            water *= (1 - evaporation)
            posX = newPosX
            posY = newPosY
        end
    end

    return map
end

function thermalErosion(
    heightmap: {number},
    size: number,
    iterations: number,
    talusAngle: number
): {number}
    map = table.create(size * size, 0)
    table.move(heightmap, 1, size * size, 1, map)

    dt = 0.5
    neighbors = {{-1,0}, {1,0}, {0,-1}, {0,1}, {-1,-1}, {1,-1}, {-1,1}, {1,1}}
    dists = {1, 1, 1, 1, 1.414, 1.414, 1.414, 1.414}

    for iter = 1, iterations do
        for y = 1, size - 2 do
            for x = 1, size - 2 do
                idx = y * size + x + 1
                h = map[idx]
                maxDiff = 0
                totalDiff = 0
                diffs = table.create(8, 0)

                for n = 1, 8 do
                    nx = x + neighbors[n][1]
                    ny = y + neighbors[n][2]
                    nIdx = ny * size + nx + 1
                    diff = h - map[nIdx]
                    threshold = talusAngle * dists[n]
                    if diff > threshold then
                        excess = diff - threshold
                        diffs[n] = excess
                        totalDiff += excess
                        if diff > maxDiff then maxDiff = diff end
                    end
                end

                if totalDiff > 0 then
                    moveAmount = dt * maxDiff * 0.5
                    for n = 1, 8 do
                        if diffs[n] > 0 then
                            share = diffs[n] / totalDiff * moveAmount
                            nx = x + neighbors[n][1]
                            ny = y + neighbors[n][2]
                            nIdx = ny * size + nx + 1
                            map[idx] -= share
                            map[nIdx] += share
                        end
                    end
                end
            end
        end
    end

    return map
end

return {
    hydraulicErosion = hydraulicErosion,
    thermalErosion = thermalErosion,
}
