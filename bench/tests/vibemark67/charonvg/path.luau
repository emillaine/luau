#!native
Matrix = require("./matrix")

Path = {}
Path.__index = Path

Path.MOVE_TO = 0
Path.LINE_TO = 1
Path.CUBIC_TO = 2
Path.CLOSE = 3

MOVE_TO = Path.MOVE_TO
LINE_TO = Path.LINE_TO
CUBIC_TO = Path.CUBIC_TO
CLOSE = Path.CLOSE

PI = math.pi
TWO_PI = PI * 2
HALF_PI = PI / 2
KAPPA = 0.55228474983079339840

function Path.create()
    return setmetatable({
        cmds = {},
        data = {},
        startX = 0,
        startY = 0,
        numContours = 0,
        numCurves = 0,
    }, Path)
end

function Path:moveTo(x, y)
    cmds, data = self.cmds, self.data
    cmds[cmds.count + 1] = MOVE_TO
    data[data.count + 1] = x
    data[data.count + 1] = y
    self.startX = x
    self.startY = y
    self.numContours = self.numContours + 1
end

function Path:lineTo(x, y)
    cmds, data = self.cmds, self.data
    if cmds.count == 0 then
        self:moveTo(x, y)
        return
    end
    cmds[cmds.count + 1] = LINE_TO
    data[data.count + 1] = x
    data[data.count + 1] = y
end

function Path:cubicTo(x1, y1, x2, y2, x3, y3)
    cmds, data = self.cmds, self.data
    if cmds.count == 0 then
        self:moveTo(0, 0)
    end
    cmds[cmds.count + 1] = CUBIC_TO
    data[data.count + 1] = x1
    data[data.count + 1] = y1
    data[data.count + 1] = x2
    data[data.count + 1] = y2
    data[data.count + 1] = x3
    data[data.count + 1] = y3
    self.numCurves = self.numCurves + 1
end

function Path:quadTo(x1, y1, x2, y2)
    cx, cy = self:getCurrentPoint()
    cp1x = cx + 2 / 3 * (x1 - cx)
    cp1y = cy + 2 / 3 * (y1 - cy)
    cp2x = x2 + 2 / 3 * (x1 - x2)
    cp2y = y2 + 2 / 3 * (y1 - y2)
    self:cubicTo(cp1x, cp1y, cp2x, cp2y, x2, y2)
end

function Path:close()
    cmds, data = self.cmds, self.data
    if cmds.count == 0 then
        return
    end
    cmds[cmds.count + 1] = CLOSE
    data[data.count + 1] = self.startX
    data[data.count + 1] = self.startY
end

function Path:getCurrentPoint()
    data = self.data
    n = data.count
    if n < 2 then
        return 0, 0
    end
    return data[n - 1], data[n]
end

function Path:reset()
    self.cmds = {}
    self.data = {}
    self.startX = 0
    self.startY = 0
    self.numContours = 0
    self.numCurves = 0
end

# Shape helpers

function Path:addRect(x, y, w, h)
    self:moveTo(x, y)
    self:lineTo(x + w, y)
    self:lineTo(x + w, y + h)
    self:lineTo(x, y + h)
    self:close()
end

function Path:addRoundRect(x, y, w, h, rx, ry)
    rx = math.min(rx, w / 2)
    ry = math.min(ry, h / 2)
    if rx == 0 and ry == 0 then
        self:addRect(x, y, w, h)
        return
    end

    right = x + w
    bottom = y + h
    cpx = rx * KAPPA
    cpy = ry * KAPPA

    self:moveTo(x + rx, y)
    self:lineTo(right - rx, y)
    self:cubicTo(right - rx + cpx, y, right, y + ry - cpy, right, y + ry)
    self:lineTo(right, bottom - ry)
    self:cubicTo(right, bottom - ry + cpy, right - rx + cpx, bottom, right - rx, bottom)
    self:lineTo(x + rx, bottom)
    self:cubicTo(x + rx - cpx, bottom, x, bottom - ry + cpy, x, bottom - ry)
    self:lineTo(x, y + ry)
    self:cubicTo(x, y + ry - cpy, x + rx - cpx, y, x + rx, y)
    self:close()
end

function Path:addEllipse(cx, cy, rx, ry)
    cpx = rx * KAPPA
    cpy = ry * KAPPA

    self:moveTo(cx, cy - ry)
    self:cubicTo(cx + cpx, cy - ry, cx + rx, cy - cpy, cx + rx, cy)
    self:cubicTo(cx + rx, cy + cpy, cx + cpx, cy + ry, cx, cy + ry)
    self:cubicTo(cx - cpx, cy + ry, cx - rx, cy + cpy, cx - rx, cy)
    self:cubicTo(cx - rx, cy - cpy, cx - cpx, cy - ry, cx, cy - ry)
    self:close()
end

function Path:addCircle(cx, cy, r)
    self:addEllipse(cx, cy, r, r)
end

function Path:addArc(cx, cy, r, a0, a1, ccw)
    da = a1 - a0
    if not ccw then
        if da < 0 then
            da = da % TWO_PI
        end
        if da > TWO_PI then
            da = TWO_PI
        end
    else
        if da > 0 then
            da = -(-da % TWO_PI)
        end
        if da < -TWO_PI then
            da = -TWO_PI
        end
    end

    nsegs = math.max(1, math.ceil(math.abs(da) / HALF_PI))
    segAngle = da / nsegs

    startX = cx + r * math.cos(a0)
    startY = cy + r * math.sin(a0)
    if self.cmds.count == 0 then
        self:moveTo(startX, startY)
    else
        self:lineTo(startX, startY)
    end

    for i = 1, nsegs do
        angle = a0 + segAngle * i
        prevAngle = a0 + segAngle * (i - 1)
        halfSeg = segAngle / 2
        t = (4 / 3) * math.tan(halfSeg / 2)

        cos0 = math.cos(prevAngle)
        sin0 = math.sin(prevAngle)
        cos1 = math.cos(angle)
        sin1 = math.sin(angle)

        cp1x = cx + r * (cos0 - t * sin0)
        cp1y = cy + r * (sin0 + t * cos0)
        cp2x = cx + r * (cos1 + t * sin1)
        cp2y = cy + r * (sin1 - t * cos1)
        ex = cx + r * cos1
        ey = cy + r * sin1

        self:cubicTo(cp1x, cp1y, cp2x, cp2y, ex, ey)
    end
end

# SVG arc-to endpoint parameterization
function Path:arcTo(rx, ry, angle, largeArc, sweep, x, y)
    cx, cy = self:getCurrentPoint()

    if rx == 0 or ry == 0 then
        self:lineTo(x, y)
        return
    end

    if cx == x and cy == y then
        return
    end

    rx = math.abs(rx)
    ry = math.abs(ry)

    sinA = math.sin(angle)
    cosA = math.cos(angle)

    dx2 = (cx - x) / 2
    dy2 = (cy - y) / 2

    x1p = cosA * dx2 + sinA * dy2
    y1p = -sinA * dx2 + cosA * dy2

    x1p2 = x1p * x1p
    y1p2 = y1p * y1p
    rx2 = rx * rx
    ry2 = ry * ry

    lambda = x1p2 / rx2 + y1p2 / ry2
    if lambda > 1 then
        s = math.sqrt(lambda)
        rx = s * rx
        ry = s * ry
        rx2 = rx * rx
        ry2 = ry * ry
    end

    num = rx2 * ry2 - rx2 * y1p2 - ry2 * x1p2
    den = rx2 * y1p2 + ry2 * x1p2
    if den == 0 then
        self:lineTo(x, y)
        return
    end
    sq = math.sqrt(math.max(0, num / den))
    if largeArc == sweep then
        sq = -sq
    end

    cxp = sq * rx * y1p / ry
    cyp = -sq * ry * x1p / rx

    centerX = cosA * cxp - sinA * cyp + (cx + x) / 2
    centerY = sinA * cxp + cosA * cyp + (cy + y) / 2

    function vecAngle(ux, uy, vx, vy)
        dot = ux * vx + uy * vy
        len = math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
        if len == 0 then
            return 0
        end
        cos_val = dot / len
        cos_val = math.max(-1, math.min(1, cos_val))
        a = math.acos(cos_val)
        if ux * vy - uy * vx < 0 then
            a = -a
        end
        return a
    end

    th1 = vecAngle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
    dth = vecAngle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)

    if not sweep and dth > 0 then
        dth = dth - TWO_PI
    else if sweep and dth < 0 then
        dth = dth + TWO_PI
    end

    nsegs = math.ceil(math.abs(dth) / (HALF_PI + 0.001))
    segAngle = dth / nsegs

    for i = 1, nsegs do
        ta = th1 + segAngle * (i - 1)
        tb = th1 + segAngle * i
        t = (4 / 3) * math.tan((tb - ta) / 4)

        cos_a = math.cos(ta)
        sin_a = math.sin(ta)
        cos_b = math.cos(tb)
        sin_b = math.sin(tb)

        p1x = rx * cos_a
        p1y = ry * sin_a
        p2x = rx * cos_b
        p2y = ry * sin_b

        cp1x = p1x - t * rx * sin_a
        cp1y = p1y + t * ry * cos_a
        cp2x = p2x + t * rx * sin_b
        cp2y = p2y - t * ry * cos_b

        function transformBack(px, py)
            return cosA * px - sinA * py + centerX, sinA * px + cosA * py + centerY
        end

        c1x, c1y = transformBack(cp1x, cp1y)
        c2x, c2y = transformBack(cp2x, cp2y)
        ex, ey = transformBack(p2x, p2y)

        self:cubicTo(c1x, c1y, c2x, c2y, ex, ey)
    end
end

# Transform all points in the path
function Path:transform(matrix)
    data = self.data
    for i = 1, data.count, 2 do
        x, y = data[i], data[i + 1]
        data[i], data[i + 1] = matrix:mapPoint(x, y)
    end
    self.startX, self.startY = matrix:mapPoint(self.startX, self.startY)
end

# Append another path with optional transform
function Path:addPath(source, matrix)
    srcCmds = source.cmds
    srcData = source.data
    di = 1
    for ci = 1, srcCmds.count do
        cmd = srcCmds[ci]
        if cmd == MOVE_TO or cmd == LINE_TO or cmd == CLOSE then
            x, y = srcData[di], srcData[di + 1]
            if matrix then
                x, y = matrix:mapPoint(x, y)
            end
            if cmd == MOVE_TO then
                self:moveTo(x, y)
            else if cmd == LINE_TO then
                self:lineTo(x, y)
            else
                self:close()
            end
            di = di + 2
        else if cmd == CUBIC_TO then
            x1, y1 = srcData[di], srcData[di + 1]
            x2, y2 = srcData[di + 2], srcData[di + 3]
            x3, y3 = srcData[di + 4], srcData[di + 5]
            if matrix then
                x1, y1 = matrix:mapPoint(x1, y1)
                x2, y2 = matrix:mapPoint(x2, y2)
                x3, y3 = matrix:mapPoint(x3, y3)
            end
            self:cubicTo(x1, y1, x2, y2, x3, y3)
            di = di + 6
        end
    end
end

function Path:clone()
    new = Path.create()
    cmds, data = self.cmds, self.data
    nc, nd = new.cmds, new.data
    for i = 1, cmds.count do
        nc[i] = cmds[i]
    end
    for i = 1, data.count do
        nd[i] = data[i]
    end
    new.startX = self.startX
    new.startY = self.startY
    new.numContours = self.numContours
    new.numCurves = self.numCurves
    return new
end

# Traverse the path, calling callback(cmd, x1, y1, ...) for each command
function Path:traverse(callback)
    cmds = self.cmds
    data = self.data
    di = 1
    for ci = 1, cmds.count do
        cmd = cmds[ci]
        if cmd == MOVE_TO then
            callback(MOVE_TO, data[di], data[di + 1])
            di = di + 2
        else if cmd == LINE_TO then
            callback(LINE_TO, data[di], data[di + 1])
            di = di + 2
        else if cmd == CUBIC_TO then
            callback(CUBIC_TO, data[di], data[di + 1], data[di + 2], data[di + 3], data[di + 4], data[di + 5])
            di = di + 6
        else if cmd == CLOSE then
            callback(CLOSE, data[di], data[di + 1])
            di = di + 2
        end
    end
end

# Adaptive de Casteljau flattening
FLATTEN_THRESHOLD = 0.25

function flattenCubic(callback, x1, y1, x2, y2, x3, y3, x4, y4)
    # Stack-based iterative approach (max depth 32)
    stack = {}
    top = 0

    top = top + 1
    stack[top] = { x1, y1, x2, y2, x3, y3, x4, y4 }

    while top > 0 do
        b = stack[top]
        top = top - 1

        bx1, by1, bx2, by2, bx3, by3, bx4, by4 = b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8]

        dx = bx4 - bx1
        dy = by4 - by1
        l = math.sqrt(dx * dx + dy * dy)

        flat = null
        if l > 1 then
            d1 = math.abs(dx * (by2 - by1) - dy * (bx2 - bx1))
            d2 = math.abs(dx * (by3 - by1) - dy * (bx3 - bx1))
            flat = (d1 + d2) < FLATTEN_THRESHOLD * l
        else
            d1 = math.abs(bx2 - bx1) + math.abs(by2 - by1)
            d2 = math.abs(bx3 - bx1) + math.abs(by3 - by1)
            flat = (d1 + d2) < FLATTEN_THRESHOLD
        end

        if flat or top >= 31 then
            callback(LINE_TO, bx4, by4)
        else
            # de Casteljau split
            mx12 = (bx1 + bx2) * 0.5
            my12 = (by1 + by2) * 0.5
            mx23 = (bx2 + bx3) * 0.5
            my23 = (by2 + by3) * 0.5
            mx34 = (bx3 + bx4) * 0.5
            my34 = (by3 + by4) * 0.5
            mx123 = (mx12 + mx23) * 0.5
            my123 = (my12 + my23) * 0.5
            mx234 = (mx23 + mx34) * 0.5
            my234 = (my23 + my34) * 0.5
            mx1234 = (mx123 + mx234) * 0.5
            my1234 = (my123 + my234) * 0.5

            # Push right half first (so left is processed first)
            top = top + 1
            stack[top] = { mx1234, my1234, mx234, my234, mx34, my34, bx4, by4 }
            top = top + 1
            stack[top] = { bx1, by1, mx12, my12, mx123, my123, mx1234, my1234 }
        end
    end
end

function Path:traverseFlatten(callback)
    if self.numCurves == 0 then
        self:traverse(callback)
        return
    end

    cmds = self.cmds
    data = self.data
    di = 1
    curX, curY = 0, 0

    for ci = 1, cmds.count do
        cmd = cmds[ci]
        if cmd == MOVE_TO then
            callback(MOVE_TO, data[di], data[di + 1])
            curX, curY = data[di], data[di + 1]
            di = di + 2
        else if cmd == LINE_TO then
            callback(LINE_TO, data[di], data[di + 1])
            curX, curY = data[di], data[di + 1]
            di = di + 2
        else if cmd == CUBIC_TO then
            x1, y1 = data[di], data[di + 1]
            x2, y2 = data[di + 2], data[di + 3]
            x3, y3 = data[di + 4], data[di + 5]
            flattenCubic(callback, curX, curY, x1, y1, x2, y2, x3, y3)
            curX, curY = x3, y3
            di = di + 6
        else if cmd == CLOSE then
            callback(CLOSE, data[di], data[di + 1])
            curX, curY = data[di], data[di + 1]
            di = di + 2
        end
    end
end

# Dashed path traversal
function Path:traverseDashed(offset, dashes, callback)
    ndashes = dashes.count
    if ndashes == 0 then
        self:traverseFlatten(callback)
        return
    end

    totalDash = 0
    for i = 1, ndashes do
        totalDash = totalDash + dashes[i]
    end
    if totalDash <= 0 then
        self:traverseFlatten(callback)
        return
    end

    # Normalize offset
    offset = offset % totalDash
    if offset < 0 then
        offset = offset + totalDash
    end

    # Find starting dash index and phase
    dashIndex = 1
    dashRemaining = dashes[1]
    drawing = true

    while offset > 0 do
        if offset < dashRemaining then
            dashRemaining = dashRemaining - offset
            offset = 0
        else
            offset = offset - dashRemaining
            dashIndex = dashIndex % ndashes + 1
            dashRemaining = dashes[dashIndex]
            drawing = not drawing
        end
    end

    curX, curY = 0, 0
    needsMoveTo = true

    function dashSegment(x, y)
        dx = x - curX
        dy = y - curY
        dist = math.sqrt(dx * dx + dy * dy)

        if dist == 0 then
            return
        end

        while dist > 0 do
            if dist < dashRemaining then
                dashRemaining = dashRemaining - dist
                if drawing then
                    if needsMoveTo then
                        callback(MOVE_TO, curX, curY)
                        needsMoveTo = false
                    end
                    callback(LINE_TO, x, y)
                end
                curX, curY = x, y
                dist = 0
            else
                t = dashRemaining / dist
                splitX = curX + dx * t
                splitY = curY + dy * t

                if drawing then
                    if needsMoveTo then
                        callback(MOVE_TO, curX, curY)
                        needsMoveTo = false
                    end
                    callback(LINE_TO, splitX, splitY)
                end

                curX, curY = splitX, splitY
                dx = x - curX
                dy = y - curY
                dist = math.sqrt(dx * dx + dy * dy)

                dashIndex = dashIndex % ndashes + 1
                dashRemaining = dashes[dashIndex]
                drawing = not drawing
                needsMoveTo = true
            end
        end
    end

    self:traverseFlatten(function(cmd, ...)
        if cmd == MOVE_TO then
            mx, my = ...
            curX, curY = mx, my
            needsMoveTo = true
        else if cmd == LINE_TO then
            lx, ly = ...
            dashSegment(lx, ly)
        else if cmd == CLOSE then
            clx, cly = ...
            dashSegment(clx, cly)
        end
    end)
end

function Path:cloneFlatten()
    new = Path.create()
    self:traverseFlatten(function(cmd, ...)
        if cmd == MOVE_TO then
            x, y = ...
            new:moveTo(x, y)
        else if cmd == LINE_TO then
            x, y = ...
            new:lineTo(x, y)
        else if cmd == CLOSE then
            new:close()
        end
    end)
    return new
end

function Path:cloneDashed(offset, dashes)
    new = Path.create()
    self:traverseDashed(offset, dashes, function(cmd, ...)
        if cmd == MOVE_TO then
            x, y = ...
            new:moveTo(x, y)
        else if cmd == LINE_TO then
            x, y = ...
            new:lineTo(x, y)
        else if cmd == CLOSE then
            new:close()
        end
    end)
    return new
end

# Bounding box and path length
function Path:extents(tight)
    minX, minY = math.huge, math.huge
    maxX, maxY = -math.huge, -math.huge
    totalLength = 0
    prevX, prevY = null, null

    function processPoint(x, y)
        if x < minX then
            minX = x
        end
        if x > maxX then
            maxX = x
        end
        if y < minY then
            minY = y
        end
        if y > maxY then
            maxY = y
        end
    end

    function accumulateLength(x, y)
        if prevX then
            dx = x - prevX
            dy = y - prevY
            totalLength = totalLength + math.sqrt(dx * dx + dy * dy)
        end
        prevX, prevY = x, y
    end

    function doTraverse(callback)
        if tight then
            self:traverseFlatten(callback)
        else
            self:traverse(callback)
        end
    end

    doTraverse(function(cmd, ...)
        if cmd == MOVE_TO then
            x, y = ...
            processPoint(x, y)
            prevX, prevY = x, y
        else if cmd == LINE_TO then
            x, y = ...
            processPoint(x, y)
            accumulateLength(x, y)
        else if cmd == CUBIC_TO then
            x1, y1, x2, y2, x3, y3 = ...
            processPoint(x1, y1)
            processPoint(x2, y2)
            processPoint(x3, y3)
            prevX, prevY = x3, y3
        else if cmd == CLOSE then
            x, y = ...
            accumulateLength(x, y)
        end
    end)

    if minX == math.huge then
        return { x = 0, y = 0, w = 0, h = 0 }, 0
    end
    return { x = minX, y = minY, w = maxX - minX, h = maxY - minY }, totalLength
end

function Path:length()
    _, len = self:extents(true)
    return len
end

# SVG path string parsing

function isWs(c)
    return c == 32 or c == 9 or c == 10 or c == 13
end

function isNum(c)
    return c >= 48 and c <= 57
end

function skipWs(str, pos)
    while pos <= str.count and isWs(string.byte(str, pos)) do
        pos = pos + 1
    end
    return pos
end

function skipWsOrComma(str, pos)
    pos = skipWs(str, pos)
    if pos <= str.count and string.byte(str, pos) == 44 then
        pos = pos + 1
        pos = skipWs(str, pos)
    end
    return pos
end

function parseNumber(str, pos)
    len = str.count
    sign = 1

    if pos > len then
        return null
    end
    c = string.byte(str, pos)
    if c == 43 then
        pos = pos + 1
    else if c == 45 then
        pos = pos + 1
        sign = -1
    end

    if pos > len then
        return null
    end
    c = string.byte(str, pos)
    if c != 46 and not isNum(c) then
        return null
    end

    integer = 0
    while pos <= len do
        c = string.byte(str, pos)
        if not isNum(c) then
            break
        end
        integer = integer * 10 + (c - 48)
        pos = pos + 1
    end

    fraction = 0
    if pos <= len and string.byte(str, pos) == 46 then
        pos = pos + 1
        divisor = 1
        while pos <= len do
            c = string.byte(str, pos)
            if not isNum(c) then
                break
            end
            fraction = fraction * 10 + (c - 48)
            divisor = divisor * 10
            pos = pos + 1
        end
        fraction = fraction / divisor
    end

    exponent = 0
    expsign = 1
    if pos <= len then
        c = string.byte(str, pos)
        if c == 101 or c == 69 then
            pos = pos + 1
            if pos <= len then
                c = string.byte(str, pos)
                if c == 43 then
                    pos = pos + 1
                else if c == 45 then
                    pos = pos + 1
                    expsign = -1
                end
            end
            if pos > len or not isNum(string.byte(str, pos)) then
                return null
            end
            while pos <= len do
                c = string.byte(str, pos)
                if not isNum(c) then
                    break
                end
                exponent = exponent * 10 + (c - 48)
                pos = pos + 1
            end
        end
    end

    value = sign * (integer + fraction)
    if exponent != 0 then
        value = value * (10 ^ (expsign * exponent))
    end
    return value, pos
end

function parseFlag(str, pos)
    pos = skipWsOrComma(str, pos)
    if pos > str.count then
        return null
    end
    c = string.byte(str, pos)
    if c == 48 then
        return false, pos + 1
    end
    if c == 49 then
        return true, pos + 1
    end
    return null
end

function Path.parse(str)
    if type(str) != "string" or str.count == 0 then
        return null
    end

    p = Path.create()
    pos = skipWs(str, 1)
    len = str.count
    curX, curY = 0, 0
    startX, startY = 0, 0
    lastCpX, lastCpY = 0, 0
    lastCmd = null

    while pos <= len do
        c = string.byte(str, pos)
        cmd = null

        if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) then
            cmd = string.char(c)
            pos = pos + 1
        else if lastCmd then
            # implicit repeat
            if lastCmd == "M" then
                cmd = "L"
            else if lastCmd == "m" then
                cmd = "l"
            else
                cmd = lastCmd
            end
        else
            return null
        end

        pos = skipWsOrComma(str, pos)

        if cmd == "M" or cmd == "m" then
            x, y = null, null
            x, pos = parseNumber(str, pos)
            if not x then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y, pos = parseNumber(str, pos)
            if not y then
                return null
            end
            if cmd == "m" then
                x, y = curX + x, curY + y
            end
            p:moveTo(x, y)
            curX, curY = x, y
            startX, startY = x, y
            lastCpX, lastCpY = curX, curY
        else if cmd == "L" or cmd == "l" then
            x, y = null, null
            x, pos = parseNumber(str, pos)
            if not x then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y, pos = parseNumber(str, pos)
            if not y then
                return null
            end
            if cmd == "l" then
                x, y = curX + x, curY + y
            end
            p:lineTo(x, y)
            curX, curY = x, y
            lastCpX, lastCpY = curX, curY
        else if cmd == "H" or cmd == "h" then
            x = null
            x, pos = parseNumber(str, pos)
            if not x then
                return null
            end
            if cmd == "h" then
                x = curX + x
            end
            p:lineTo(x, curY)
            curX = x
            lastCpX, lastCpY = curX, curY
        else if cmd == "V" or cmd == "v" then
            y = null
            y, pos = parseNumber(str, pos)
            if not y then
                return null
            end
            if cmd == "v" then
                y = curY + y
            end
            p:lineTo(curX, y)
            curY = y
            lastCpX, lastCpY = curX, curY
        else if cmd == "C" or cmd == "c" then
            x1, y1, x2, y2, x3, y3 = null, null, null, null, null, null
            x1, pos = parseNumber(str, pos)
            if not x1 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y1, pos = parseNumber(str, pos)
            if not y1 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            x2, pos = parseNumber(str, pos)
            if not x2 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y2, pos = parseNumber(str, pos)
            if not y2 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            x3, pos = parseNumber(str, pos)
            if not x3 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y3, pos = parseNumber(str, pos)
            if not y3 then
                return null
            end
            if cmd == "c" then
                x1, y1 = curX + x1, curY + y1
                x2, y2 = curX + x2, curY + y2
                x3, y3 = curX + x3, curY + y3
            end
            p:cubicTo(x1, y1, x2, y2, x3, y3)
            lastCpX, lastCpY = x2, y2
            curX, curY = x3, y3
        else if cmd == "S" or cmd == "s" then
            x2, y2, x3, y3 = null, null, null, null
            x2, pos = parseNumber(str, pos)
            if not x2 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y2, pos = parseNumber(str, pos)
            if not y2 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            x3, pos = parseNumber(str, pos)
            if not x3 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y3, pos = parseNumber(str, pos)
            if not y3 then
                return null
            end
            if cmd == "s" then
                x2, y2 = curX + x2, curY + y2
                x3, y3 = curX + x3, curY + y3
            end
            x1 = 2 * curX - lastCpX
            y1 = 2 * curY - lastCpY
            p:cubicTo(x1, y1, x2, y2, x3, y3)
            lastCpX, lastCpY = x2, y2
            curX, curY = x3, y3
        else if cmd == "Q" or cmd == "q" then
            x1, y1, x2, y2 = null, null, null, null
            x1, pos = parseNumber(str, pos)
            if not x1 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y1, pos = parseNumber(str, pos)
            if not y1 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            x2, pos = parseNumber(str, pos)
            if not x2 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y2, pos = parseNumber(str, pos)
            if not y2 then
                return null
            end
            if cmd == "q" then
                x1, y1 = curX + x1, curY + y1
                x2, y2 = curX + x2, curY + y2
            end
            p:quadTo(x1, y1, x2, y2)
            lastCpX, lastCpY = x1, y1
            curX, curY = x2, y2
        else if cmd == "T" or cmd == "t" then
            x2, y2 = null, null
            x2, pos = parseNumber(str, pos)
            if not x2 then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y2, pos = parseNumber(str, pos)
            if not y2 then
                return null
            end
            if cmd == "t" then
                x2, y2 = curX + x2, curY + y2
            end
            x1 = 2 * curX - lastCpX
            y1 = 2 * curY - lastCpY
            p:quadTo(x1, y1, x2, y2)
            lastCpX, lastCpY = x1, y1
            curX, curY = x2, y2
        else if cmd == "A" or cmd == "a" then
            rx, ry, angle, largeArc, sweep, x, y = null, null, null, null, null, null, null
            rx, pos = parseNumber(str, pos)
            if not rx then
                return null
            end
            pos = skipWsOrComma(str, pos)
            ry, pos = parseNumber(str, pos)
            if not ry then
                return null
            end
            pos = skipWsOrComma(str, pos)
            angle, pos = parseNumber(str, pos)
            if not angle then
                return null
            end
            largeArc, pos = parseFlag(str, pos)
            if largeArc == null then
                return null
            end
            sweep, pos = parseFlag(str, pos)
            if sweep == null then
                return null
            end
            pos = skipWsOrComma(str, pos)
            x, pos = parseNumber(str, pos)
            if not x then
                return null
            end
            pos = skipWsOrComma(str, pos)
            y, pos = parseNumber(str, pos)
            if not y then
                return null
            end
            if cmd == "a" then
                x, y = curX + x, curY + y
            end
            p:arcTo(rx, ry, angle * PI / 180, largeArc, sweep, x, y)
            curX, curY = x, y
            lastCpX, lastCpY = curX, curY
        else if cmd == "Z" or cmd == "z" then
            p:close()
            curX, curY = startX, startY
            lastCpX, lastCpY = curX, curY
        else
            return null
        end

        lastCmd = cmd
        pos = skipWsOrComma(str, pos)
    end

    return p
end

return Path
