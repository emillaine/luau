--!native
Path = require("./path")

Stroker = {}

PI = math.pi

function Stroker.stroke(path, width, cap, join, miterLimit)
    cap = cap or "butt"
    join = join or "miter"
    miterLimit = miterLimit or 10
    radius = width / 2

    result = Path.create()

    -- Collect flattened contours
    contours = {}
    current = nil

    path:traverseFlatten(function(cmd, ...)
        if cmd == Path.MOVE_TO then
            x, y = ...
            current = { { x, y } }
            contours[#contours + 1] = current
        else if cmd == Path.LINE_TO then
            x, y = ...
            if current then
                current[#current + 1] = { x, y }
            end
        else if cmd == Path.CLOSE then
            if current and #current > 1 then
                current.closed = true
            end
        end
    end)

    for _, contour in ipairs(contours) do
        repeat
            n = #contour
            if n < 2 then
                break
            end

            -- Remove duplicate consecutive points
            pts = { contour[1] }
            for i = 2, n do
                prev = pts[#pts]
                cur = contour[i]
                if cur[1] != prev[1] or cur[2] != prev[2] then
                    pts[#pts + 1] = cur
                end
            end
            n = #pts
            if n < 2 then
                break
            end

            closed = contour.closed
            if closed then
                first = pts[1]
                last = pts[n]
                if first[1] == last[1] and first[2] == last[2] then
                    n = n - 1
                    pts[n + 1] = nil
                end
                if n < 2 then
                    break
                end
            end

            -- Compute normals for each segment
            normals = {}
            for i = 1, n - 1 do
                dx = pts[i + 1][1] - pts[i][1]
                dy = pts[i + 1][2] - pts[i][2]
                len = math.sqrt(dx * dx + dy * dy)
                if len > 0 then
                    normals[i] = { -dy / len, dx / len }
                else
                    normals[i] = { 0, 1 }
                end
            end
            if closed then
                dx = pts[1][1] - pts[n][1]
                dy = pts[1][2] - pts[n][2]
                len = math.sqrt(dx * dx + dy * dy)
                if len > 0 then
                    normals[n] = { -dy / len, dx / len }
                else
                    normals[n] = normals[n - 1] or { 0, 1 }
                end
            end

            -- Build left and right offset contours
            left = {}
            right = {}

            function addArc(arr, cx, cy, startAngle, endAngle, r)
                da = endAngle - startAngle
                if da > PI then
                    da = da - PI * 2
                end
                if da < -PI then
                    da = da + PI * 2
                end
                steps = math.max(2, math.ceil(math.abs(da) / (PI / 8)))
                for i = 1, steps do
                    a = startAngle + da * (i / steps)
                    arr[#arr + 1] = { cx + math.cos(a) * r, cy + math.sin(a) * r }
                end
            end

            function addJoin(pt, n1, n2, side)
                nx1, ny1 = n1[1], n1[2]
                nx2, ny2 = n2[1], n2[2]

                if join == "round" then
                    sign = side == "left" and 1 or -1
                    a1 = math.atan2(ny1 * sign, nx1 * sign)
                    a2 = math.atan2(ny2 * sign, nx2 * sign)
                    arr = side == "left" and left or right
                    arr[#arr + 1] = { pt[1] + nx1 * sign * radius, pt[2] + ny1 * sign * radius }
                    addArc(arr, pt[1], pt[2], a1, a2, radius)
                else if join == "bevel" then
                    if side == "left" then
                        left[#left + 1] = { pt[1] + nx1 * radius, pt[2] + ny1 * radius }
                        left[#left + 1] = { pt[1] + nx2 * radius, pt[2] + ny2 * radius }
                    else
                        right[#right + 1] = { pt[1] - nx1 * radius, pt[2] - ny1 * radius }
                        right[#right + 1] = { pt[1] - nx2 * radius, pt[2] - ny2 * radius }
                    end
                else
                    -- Miter join
                    mx = nx1 + nx2
                    my = ny1 + ny2
                    len = math.sqrt(mx * mx + my * my)
                    if len < 1e-10 then
                        if side == "left" then
                            left[#left + 1] = { pt[1] + nx2 * radius, pt[2] + ny2 * radius }
                        else
                            right[#right + 1] = { pt[1] - nx2 * radius, pt[2] - ny2 * radius }
                        end
                    else
                        mx = mx / len
                        my = my / len
                        dot = mx * nx1 + my * ny1
                        if dot < 1e-10 then
                            dot = 1e-10
                        end
                        miterLen = radius / dot
                        if miterLen / radius > miterLimit then
                            if side == "left" then
                                left[#left + 1] = { pt[1] + nx1 * radius, pt[2] + ny1 * radius }
                                left[#left + 1] = { pt[1] + nx2 * radius, pt[2] + ny2 * radius }
                            else
                                right[#right + 1] = { pt[1] - nx1 * radius, pt[2] - ny1 * radius }
                                right[#right + 1] = { pt[1] - nx2 * radius, pt[2] - ny2 * radius }
                            end
                        else
                            if side == "left" then
                                left[#left + 1] = { pt[1] + mx * miterLen, pt[2] + my * miterLen }
                            else
                                right[#right + 1] = { pt[1] - mx * miterLen, pt[2] - my * miterLen }
                            end
                        end
                    end
                end
            end

            -- First point
            if closed then
                addJoin(pts[1], normals[n], normals[1], "left")
                addJoin(pts[1], normals[n], normals[1], "right")
            else
                nx, ny = normals[1][1], normals[1][2]
                left[#left + 1] = { pts[1][1] + nx * radius, pts[1][2] + ny * radius }
                right[#right + 1] = { pts[1][1] - nx * radius, pts[1][2] - ny * radius }

                -- Start cap
                if cap == "square" then
                    dx = pts[2][1] - pts[1][1]
                    dy = pts[2][2] - pts[1][2]
                    slen = math.sqrt(dx * dx + dy * dy)
                    if slen > 0 then
                        tx, ty = -dx / slen * radius, -dy / slen * radius
                        left[1] = { left[1][1] + tx, left[1][2] + ty }
                        right[1] = { right[1][1] + tx, right[1][2] + ty }
                    end
                end
            end

            -- Interior points
            for i = 2, n - 1 do
                addJoin(pts[i], normals[i - 1], normals[i], "left")
                addJoin(pts[i], normals[i - 1], normals[i], "right")
            end

            -- Last point
            if closed then
                addJoin(pts[n], normals[n - 1], normals[n], "left")
                addJoin(pts[n], normals[n - 1], normals[n], "right")
            else
                nx, ny = normals[n - 1][1], normals[n - 1][2]
                left[#left + 1] = { pts[n][1] + nx * radius, pts[n][2] + ny * radius }
                right[#right + 1] = { pts[n][1] - nx * radius, pts[n][2] - ny * radius }

                -- End cap
                if cap == "square" then
                    dx = pts[n][1] - pts[n - 1][1]
                    dy = pts[n][2] - pts[n - 1][2]
                    len = math.sqrt(dx * dx + dy * dy)
                    if len > 0 then
                        tx, ty = dx / len * radius, dy / len * radius
                        left[#left] = { left[#left][1] + tx, left[#left][2] + ty }
                        right[#right] = { right[#right][1] + tx, right[#right][2] + ty }
                    end
                end
            end

            -- Emit the stroke outline
            if #left > 0 then
                if closed then
                    -- Two separate closed contours (outer + inner) for clean nonzero fill
                    result:moveTo(right[1][1], right[1][2])
                    for i = 2, #right do
                        result:lineTo(right[i][1], right[i][2])
                    end
                    result:close()
                    result:moveTo(left[#left][1], left[#left][2])
                    for i = #left - 1, 1, -1 do
                        result:lineTo(left[i][1], left[i][2])
                    end
                    result:close()
                else
                    -- Open path: left forward, end cap, right backward, start cap
                    result:moveTo(left[1][1], left[1][2])
                    for i = 2, #left do
                        result:lineTo(left[i][1], left[i][2])
                    end
                    -- End cap (from last left point to last right point)
                    if cap == "round" then
                        endNx, endNy = normals[n - 1][1], normals[n - 1][2]
                        endAngle = math.atan2(endNy, endNx)
                        nsteps = 8
                        for i = 1, nsteps - 1 do
                            a = endAngle - PI * (i / nsteps)
                            result:lineTo(pts[n][1] + math.cos(a) * radius, pts[n][2] + math.sin(a) * radius)
                        end
                    end
                    for i = #right, 1, -1 do
                        result:lineTo(right[i][1], right[i][2])
                    end
                    -- Start cap (from first right point back to first left point)
                    if cap == "round" then
                        startNx, startNy = normals[1][1], normals[1][2]
                        startAngle = math.atan2(-startNy, -startNx)
                        nsteps = 8
                        for i = 1, nsteps - 1 do
                            a = startAngle - PI * (i / nsteps)
                            result:lineTo(pts[1][1] + math.cos(a) * radius, pts[1][2] + math.sin(a) * radius)
                        end
                    end
                    result:close()
                end
            end

        until true
    end

    return result
end

return Stroker
