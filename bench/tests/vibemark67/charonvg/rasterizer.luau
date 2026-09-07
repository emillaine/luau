#!native
Matrix = require("./matrix")
Path = require("./path")

Rasterizer = {}

PIXEL_BITS = 8
ONE_PIXEL = 256
PIXEL_MASK = 255

sort = table.sort

function trunc(x)
    if x >= 0 then
        return bit32.rshift(x, PIXEL_BITS)
    else
        return -(bit32.rshift(-x, PIXEL_BITS)) - 1
    end
end

function fract(x)
    if x >= 0 then
        return bit32.band(x, PIXEL_MASK)
    else
        return ONE_PIXEL - bit32.band(-x, PIXEL_MASK)
    end
end

function idiv(a, b)
    q = a / b
    if q >= 0 then
        return math.floor(q)
    else
        return -math.floor(-q)
    end
end

# Rasterizer state with stateful current cell
function createRaster()
    return {
        cells = {}, # cells[y] = { [x] = {cover, area}, ... }
        cellX = -1,
        cellY = -1,
        area = 0,
        cover = 0,
        minY = math.huge,
        maxY = -math.huge,
    }
end

function flushCell(ras)
    cx, cy = ras.cellX, ras.cellY
    if cx < -16384 or cx > 16384 then
        return
    end
    a, c = ras.area, ras.cover
    if a == 0 and c == 0 then
        return
    end
    row = ras.cells[cy]
    if not row then
        row = {}
        ras.cells[cy] = row
    end
    cell = row[cx]
    if cell then
        cell[1] = cell[1] + c
        cell[2] = cell[2] + a
    else
        row[cx] = { c, a }
    end
end

function setCell(ras, ex, ey)
    if ex != ras.cellX or ey != ras.cellY then
        flushCell(ras)
        ras.cellX = ex
        ras.cellY = ey
        ras.area = 0
        ras.cover = 0
    end
end

function renderScanline(ras, ey, x1, y1, x2, y2)
    ex1 = trunc(x1)
    ex2 = trunc(x2)

    if y1 == y2 then
        setCell(ras, ex2, ey)
        return
    end

    fx1 = fract(x1)
    fx2 = fract(x2)

    if ex1 == ex2 then
        dy = y2 - y1
        ras.area = ras.area + (fx1 + fx2) * dy
        ras.cover = ras.cover + dy
        return
    end

    dx = x2 - x1
    dy = y2 - y1
    p, first, incr = null, null, null

    if dx > 0 then
        p = (ONE_PIXEL - fx1) * dy
        first = ONE_PIXEL
        incr = 1
    else
        p = fx1 * dy
        first = 0
        incr = -1
        dx = -dx
    end

    delta = idiv(p, dx)
    mod = p - delta * dx
    if mod < 0 then
        mod = mod + dx
        delta = delta - 1
    end

    ras.area = ras.area + (fx1 + first) * delta
    ras.cover = ras.cover + delta
    y1 = y1 + delta
    ex1 = ex1 + incr
    setCell(ras, ex1, ey)

    if ex1 != ex2 then
        p = ONE_PIXEL * dy
        lift = idiv(p, dx)
        rem = p - lift * dx
        if rem < 0 then
            rem = rem + dx
            lift = lift - 1
        end

        while ex1 != ex2 do
            delta = lift
            mod = mod + rem
            if mod >= dx then
                mod = mod - dx
                delta = delta + 1
            end

            ras.area = ras.area + ONE_PIXEL * delta
            ras.cover = ras.cover + delta
            y1 = y1 + delta
            ex1 = ex1 + incr
            setCell(ras, ex1, ey)
        end
    end

    lastFx1 = ONE_PIXEL - first
    dy = y2 - y1
    ras.area = ras.area + (lastFx1 + fx2) * dy
    ras.cover = ras.cover + dy
end

function renderLine(ras, fromX, fromY, toX, toY)
    ey1 = trunc(fromY)
    ey2 = trunc(toY)

    if ey1 < ras.minY then
        ras.minY = ey1
    end
    if ey2 < ras.minY then
        ras.minY = ey2
    end
    if ey1 > ras.maxY then
        ras.maxY = ey1
    end
    if ey2 > ras.maxY then
        ras.maxY = ey2
    end

    fy1 = fract(fromY)
    fy2 = fract(toY)

    if ey1 == ey2 then
        renderScanline(ras, ey1, fromX, fy1, toX, fy2)
        return
    end

    dx = toX - fromX
    dy = toY - fromY

    if dx == 0 then
        ex = trunc(fromX)
        twoFx = fract(fromX) * 2
        first, delta = null, null

        if dy > 0 then
            first = ONE_PIXEL
        else
            first = 0
        end

        delta = first - fy1
        ras.area = ras.area + twoFx * delta
        ras.cover = ras.cover + delta

        stepDelta = first + first - ONE_PIXEL
        stepArea = twoFx * stepDelta

        if dy > 0 then
            ey1 = ey1 + 1
            setCell(ras, ex, ey1)
            while ey1 < ey2 do
                ras.area = ras.area + stepArea
                ras.cover = ras.cover + stepDelta
                ey1 = ey1 + 1
                setCell(ras, ex, ey1)
            end
        else
            ey1 = ey1 - 1
            setCell(ras, ex, ey1)
            while ey1 > ey2 do
                ras.area = ras.area + stepArea
                ras.cover = ras.cover + stepDelta
                ey1 = ey1 - 1
                setCell(ras, ex, ey1)
            end
        end

        delta = fy2 - ONE_PIXEL + first
        ras.area = ras.area + twoFx * delta
        ras.cover = ras.cover + delta
        return
    end

    p, first, incr = null, null, null

    if dy > 0 then
        p = (ONE_PIXEL - fy1) * dx
        first = ONE_PIXEL
        incr = 1
    else
        p = fy1 * dx
        first = 0
        incr = -1
        dy = -dy
    end

    delta = idiv(p, dy)
    mod = p - delta * dy
    if mod < 0 then
        mod = mod + dy
        delta = delta - 1
    end

    x = fromX + delta
    renderScanline(ras, ey1, fromX, fy1, x, first)

    ey1 = ey1 + incr
    setCell(ras, trunc(x), ey1)

    if ey1 != ey2 then
        p = ONE_PIXEL * dx
        lift = idiv(p, dy)
        rem = p - lift * dy
        if rem < 0 then
            rem = rem + dy
            lift = lift - 1
        end

        while ey1 != ey2 do
            delta = lift
            mod = mod + rem
            if mod >= dy then
                mod = mod - dy
                delta = delta + 1
            end

            x2 = x + delta
            renderScanline(ras, ey1, x, ONE_PIXEL - first, x2, first)
            x = x2

            ey1 = ey1 + incr
            setCell(ras, trunc(x), ey1)
        end
    end

    renderScanline(ras, ey1, x, ONE_PIXEL - first, toX, fy2)
end

function renderCubic(ras, x1, y1, x2, y2, x3, y3, x4, y4, depth)
    if depth > 32 then
        renderLine(ras, x1, y1, x4, y4)
        return
    end

    dx = x4 - x1
    dy = y4 - y1
    d2 = math.abs((x2 - x4) * dy - (y2 - y4) * dx)
    d3 = math.abs((x3 - x4) * dy - (y3 - y4) * dx)

    if (d2 + d3) * (d2 + d3) <= (dx * dx + dy * dy) then
        renderLine(ras, x1, y1, x4, y4)
        return
    end

    x12 = (x1 + x2) * 0.5
    y12 = (y1 + y2) * 0.5
    x23 = (x2 + x3) * 0.5
    y23 = (y2 + y3) * 0.5
    x34 = (x3 + x4) * 0.5
    y34 = (y3 + y4) * 0.5
    x123 = (x12 + x23) * 0.5
    y123 = (y12 + y23) * 0.5
    x234 = (x23 + x34) * 0.5
    y234 = (y23 + y34) * 0.5
    x1234 = (x123 + x234) * 0.5
    y1234 = (y123 + y234) * 0.5

    renderCubic(ras, x1, y1, x12, y12, x123, y123, x1234, y1234, depth + 1)
    renderCubic(ras, x1234, y1234, x234, y234, x34, y34, x4, y4, depth + 1)
end

# Coverage conversion (inlined in sweep for speed)
COVERAGE_SHIFT = 9

# Sweep cells to produce spans
function sweep(ras, fillRule, clipMinX, clipMaxX, clipMinY, clipMaxY)
    spans = {}
    nspans = 0
    cells = ras.cells
    isEvenOdd = fillRule == "evenodd"

    for ey = ras.minY, ras.maxY do
        if ey >= clipMinY and ey < clipMaxY then
            row = cells[ey]
            if row then
                # Collect and sort x keys
                xs = {}
                nxs = 0
                for x in pairs(row) do
                    nxs = nxs + 1
                    xs[nxs] = x
                end
                sort(xs)

                cover = 0
                for i = 1, nxs do
                    x = xs[i]
                    cell = row[x]
                    cellCover = cell[1]
                    cellArea = cell[2]

                    # Gap span before this cell
                    if i > 1 then
                        prevX = xs[i - 1] + 1
                        if prevX < x and cover != 0 then
                            cov = bit32.rshift(math.abs(cover * 512), COVERAGE_SHIFT)
                            if isEvenOdd then
                                cov = bit32.band(cov, 511)
                                if cov > 256 then
                                    cov = 512 - cov
                                else if cov == 256 then
                                    cov = 255
                                end
                            else
                                if cov >= 256 then
                                    cov = 255
                                end
                            end
                            if cov > 0 then
                                sx = math.max(prevX, clipMinX)
                                ex = math.min(x, clipMaxX)
                                if sx < ex then
                                    nspans = nspans + 1
                                    spans[nspans] = { x = sx, y = ey, len = ex - sx, coverage = cov }
                                end
                            end
                        end
                    end

                    # Cell span
                    cover = cover + cellCover
                    area = cover * 512 - cellArea
                    cov = bit32.rshift(math.abs(area), COVERAGE_SHIFT)
                    if isEvenOdd then
                        cov = bit32.band(cov, 511)
                        if cov > 256 then
                            cov = 512 - cov
                        else if cov == 256 then
                            cov = 255
                        end
                    else
                        if cov >= 256 then
                            cov = 255
                        end
                    end
                    if cov > 0 then
                        sx = math.max(x, clipMinX)
                        ex = math.min(x + 1, clipMaxX)
                        if sx < ex then
                            nspans = nspans + 1
                            spans[nspans] = { x = sx, y = ey, len = ex - sx, coverage = cov }
                        end
                    end
                end
            end
        end
    end

    return spans
end

function Rasterizer.rasterize(path, matrix, clipRect, fillRule)
    fillRule = fillRule or "nonzero"

    clipMinX = clipRect and clipRect.x or 0
    clipMinY = clipRect and clipRect.y or 0
    clipMaxX = clipRect and (clipRect.x + clipRect.w) or 32768
    clipMaxY = clipRect and (clipRect.y + clipRect.h) or 32768

    ras = createRaster()

    cmds = path.cmds
    data = path.data
    di = 1
    curX, curY = 0, 0
    startX, startY = 0, 0

    for ci = 1, cmds.count do
        cmd = cmds[ci]
        if cmd == Path.MOVE_TO then
            px, py = data[di], data[di + 1]
            di = di + 2
            if matrix then
                px, py = matrix:mapPoint(px, py)
            end
            curX = math.floor(px * ONE_PIXEL + 0.5)
            curY = math.floor(py * ONE_PIXEL + 0.5)
            startX, startY = curX, curY
            setCell(ras, trunc(curX), trunc(curY))
        else if cmd == Path.LINE_TO then
            px, py = data[di], data[di + 1]
            di = di + 2
            if matrix then
                px, py = matrix:mapPoint(px, py)
            end
            nx = math.floor(px * ONE_PIXEL + 0.5)
            ny = math.floor(py * ONE_PIXEL + 0.5)
            renderLine(ras, curX, curY, nx, ny)
            curX, curY = nx, ny
        else if cmd == Path.CUBIC_TO then
            x1, y1 = data[di], data[di + 1]
            x2, y2 = data[di + 2], data[di + 3]
            x3, y3 = data[di + 4], data[di + 5]
            di = di + 6
            if matrix then
                x1, y1 = matrix:mapPoint(x1, y1)
                x2, y2 = matrix:mapPoint(x2, y2)
                x3, y3 = matrix:mapPoint(x3, y3)
            end
            nx1 = math.floor(x1 * ONE_PIXEL + 0.5)
            ny1 = math.floor(y1 * ONE_PIXEL + 0.5)
            nx2 = math.floor(x2 * ONE_PIXEL + 0.5)
            ny2 = math.floor(y2 * ONE_PIXEL + 0.5)
            nx3 = math.floor(x3 * ONE_PIXEL + 0.5)
            ny3 = math.floor(y3 * ONE_PIXEL + 0.5)
            renderCubic(ras, curX, curY, nx1, ny1, nx2, ny2, nx3, ny3, 0)
            curX, curY = nx3, ny3
        else if cmd == Path.CLOSE then
            di = di + 2
            if curX != startX or curY != startY then
                renderLine(ras, curX, curY, startX, startY)
            end
            curX, curY = startX, startY
        end
    end

    flushCell(ras)
    return sweep(ras, fillRule, clipMinX, clipMaxX, clipMinY, clipMaxY)
end

function Rasterizer.intersectSpans(a, b)
    result = {}
    nresult = 0
    ai, bi = 1, 1
    na, nb = a.count, b.count

    while ai <= na and bi <= nb do
        aSpan = a[ai]
        bSpan = b[bi]

        if bSpan.y > aSpan.y then
            ai = ai + 1
        else if aSpan.y > bSpan.y then
            bi = bi + 1
        else
            ax1 = aSpan.x
            ax2 = ax1 + aSpan.len
            bx1 = bSpan.x
            bx2 = bx1 + bSpan.len

            if bx2 <= ax1 then
                bi = bi + 1
            else if ax2 <= bx1 then
                ai = ai + 1
            else
                x = math.max(ax1, bx1)
                len = math.min(ax2, bx2) - x
                if len > 0 then
                    nresult = nresult + 1
                    result[nresult] = {
                        x = x,
                        y = aSpan.y,
                        len = len,
                        coverage = math.floor(aSpan.coverage * bSpan.coverage / 255),
                    }
                end
                if ax2 < bx2 then
                    ai = ai + 1
                else
                    bi = bi + 1
                end
            end
        end
    end

    return result
end

return Rasterizer
