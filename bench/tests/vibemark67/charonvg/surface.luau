--!native
Color = require("./color")

Surface = {}
Surface.__index = Surface

MAX_DIM = 32768

function Surface.create(width, height)
    assert(width > 0 and width <= MAX_DIM, "invalid width")
    assert(height > 0 and height <= MAX_DIM, "invalid height")
    width = math.floor(width)
    height = math.floor(height)
    stride = width * 4
    data = buffer.create(stride * height)
    return setmetatable({
        _width = width,
        _height = height,
        _stride = stride,
        _data = data,
    }, Surface)
end

function Surface:getWidth()
    return self._width
end

function Surface:getHeight()
    return self._height
end

function Surface:getStride()
    return self._stride
end

function Surface:getData()
    return self._data
end

function Surface:clear(color)
    size = self._stride * self._height
    if not color then
        buffer.fill(self._data, 0, 0, size)
        return
    end
    a = math.floor(color.a * 255 + 0.5)
    r = math.floor(color.r * a + 0.5)
    g = math.floor(color.g * a + 0.5)
    b = math.floor(color.b * a + 0.5)
    -- Fast path: if all bytes are the same value, use buffer.fill
    if a == r and r == g and g == b then
        buffer.fill(self._data, 0, a, size)
        return
    end
    pixel = bit32.bor(bit32.lshift(a, 24), bit32.lshift(r, 16), bit32.lshift(g, 8), b)
    data = self._data
    -- Write first pixel, then copy in doubling chunks
    buffer.writeu32(data, 0, pixel)
    written = 4
    while written < size do
        chunk = written
        if chunk > size - written then
            chunk = size - written
        end
        buffer.copy(data, written, data, 0, chunk)
        written = written + chunk
    end
end

function Surface:getPixel(x, y)
    if x < 0 or x >= self._width or y < 0 or y >= self._height then
        return 0, 0, 0, 0
    end
    offset = y * self._stride + x * 4
    pixel = buffer.readu32(self._data, offset)
    a = bit32.rshift(pixel, 24)
    r = bit32.band(bit32.rshift(pixel, 16), 0xFF)
    g = bit32.band(bit32.rshift(pixel, 8), 0xFF)
    b = bit32.band(pixel, 0xFF)
    -- Unpremultiply
    if a == 0 then
        return 0, 0, 0, 0
    else if a == 255 then
        return r, g, b, a
    else
        r = math.floor(r * 255 / a + 0.5)
        g = math.floor(g * 255 / a + 0.5)
        b = math.floor(b * 255 / a + 0.5)
        return r, g, b, a
    end
end

function Surface:setPixel(x, y, r, g, b, a)
    if x < 0 or x >= self._width or y < 0 or y >= self._height then
        return
    end
    -- Premultiply
    pr = math.floor(r * a / 255 + 0.5)
    pg = math.floor(g * a / 255 + 0.5)
    pb = math.floor(b * a / 255 + 0.5)
    pixel = bit32.bor(bit32.lshift(a, 24), bit32.lshift(pr, 16), bit32.lshift(pg, 8), pb)
    offset = y * self._stride + x * 4
    buffer.writeu32(self._data, offset, pixel)
end

function Surface.convertARGBtoRGBA(dst, src, width, height, stride)
    for y = 0, height - 1 do
        rowOff = y * stride
        for x = 0, width - 1 do
            off = rowOff + x * 4
            pixel = buffer.readu32(src, off)
            a = bit32.rshift(pixel, 24)
            r = bit32.band(bit32.rshift(pixel, 16), 0xFF)
            g = bit32.band(bit32.rshift(pixel, 8), 0xFF)
            b = bit32.band(pixel, 0xFF)
            -- Unpremultiply
            if a > 0 and a < 255 then
                r = math.min(255, math.floor(r * 255 / a + 0.5))
                g = math.min(255, math.floor(g * 255 / a + 0.5))
                b = math.min(255, math.floor(b * 255 / a + 0.5))
            end
            -- Write as RGBA byte order
            buffer.writeu8(dst, off, r)
            buffer.writeu8(dst, off + 1, g)
            buffer.writeu8(dst, off + 2, b)
            buffer.writeu8(dst, off + 3, a)
        end
    end
end

function Surface:getRGBA()
    total = self._width * self._height
    src = self._data
    dst = buffer.create(total * 4)
    size = total * 4

    lastIn0 = -1
    lastIn1 = -2
    lastOut0 = 0
    lastOut1 = 0

    pairsEnd = size - 7
    i = 0
    while i < pairsEnd do
        p0 = buffer.readu32(src, i)
        p1 = buffer.readu32(src, i + 4)
        if p0 == lastIn0 and p1 == lastIn1 then
            buffer.writeu32(dst, i, lastOut0)
            buffer.writeu32(dst, i + 4, lastOut1)
        else
            a = bit32.rshift(p0, 24)
            r = bit32.band(bit32.rshift(p0, 16), 0xFF)
            g = bit32.band(bit32.rshift(p0, 8), 0xFF)
            b = bit32.band(p0, 0xFF)
            if a > 0 and a < 255 then
                inv = 255 / a
                r = math.floor(r * inv + 0.5)
                g = math.floor(g * inv + 0.5)
                b = math.floor(b * inv + 0.5)
                if r > 255 then
                    r = 255
                end
                if g > 255 then
                    g = 255
                end
                if b > 255 then
                    b = 255
                end
            end
            lastOut0 = bit32.bor(r, bit32.lshift(g, 8), bit32.lshift(b, 16), bit32.lshift(a, 24))
            buffer.writeu32(dst, i, lastOut0)

            a = bit32.rshift(p1, 24)
            r = bit32.band(bit32.rshift(p1, 16), 0xFF)
            g = bit32.band(bit32.rshift(p1, 8), 0xFF)
            b = bit32.band(p1, 0xFF)
            if a > 0 and a < 255 then
                inv = 255 / a
                r = math.floor(r * inv + 0.5)
                g = math.floor(g * inv + 0.5)
                b = math.floor(b * inv + 0.5)
                if r > 255 then
                    r = 255
                end
                if g > 255 then
                    g = 255
                end
                if b > 255 then
                    b = 255
                end
            end
            lastOut1 = bit32.bor(r, bit32.lshift(g, 8), bit32.lshift(b, 16), bit32.lshift(a, 24))
            buffer.writeu32(dst, i + 4, lastOut1)

            lastIn0 = p0
            lastIn1 = p1
        end
        i = i + 8
    end

    -- Handle remainder
    while i < size do
        pixel = buffer.readu32(src, i)
        a = bit32.rshift(pixel, 24)
        r = bit32.band(bit32.rshift(pixel, 16), 0xFF)
        g = bit32.band(bit32.rshift(pixel, 8), 0xFF)
        b = bit32.band(pixel, 0xFF)
        if a > 0 and a < 255 then
            inv = 255 / a
            r = math.floor(r * inv + 0.5)
            g = math.floor(g * inv + 0.5)
            b = math.floor(b * inv + 0.5)
            if r > 255 then
                r = 255
            end
            if g > 255 then
                g = 255
            end
            if b > 255 then
                b = 255
            end
        end
        buffer.writeu32(dst, i, bit32.bor(r, bit32.lshift(g, 8), bit32.lshift(b, 16), bit32.lshift(a, 24)))
        i = i + 4
    end
    return dst
end

function Surface.convertRGBAtoARGB(dst, src, width, height, stride)
    for y = 0, height - 1 do
        rowOff = y * stride
        for x = 0, width - 1 do
            off = rowOff + x * 4
            r = buffer.readu8(src, off)
            g = buffer.readu8(src, off + 1)
            b = buffer.readu8(src, off + 2)
            a = buffer.readu8(src, off + 3)
            -- Premultiply
            if a < 255 then
                r = math.floor(r * a / 255 + 0.5)
                g = math.floor(g * a / 255 + 0.5)
                b = math.floor(b * a / 255 + 0.5)
            end
            pixel = bit32.bor(bit32.lshift(a, 24), bit32.lshift(r, 16), bit32.lshift(g, 8), b)
            buffer.writeu32(dst, off, pixel)
        end
    end
end

return Surface
