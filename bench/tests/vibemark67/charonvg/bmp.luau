--!native
Bmp = {}

function writeU16(buf, offset, value)
    buffer.writeu8(buf, offset, bit32.band(value, 0xFF))
    buffer.writeu8(buf, offset + 1, bit32.band(bit32.rshift(value, 8), 0xFF))
end

function writeU32(buf, offset, value)
    buffer.writeu8(buf, offset, bit32.band(value, 0xFF))
    buffer.writeu8(buf, offset + 1, bit32.band(bit32.rshift(value, 8), 0xFF))
    buffer.writeu8(buf, offset + 2, bit32.band(bit32.rshift(value, 16), 0xFF))
    buffer.writeu8(buf, offset + 3, bit32.band(bit32.rshift(value, 24), 0xFF))
end

function Bmp.write(surface, filename)
    width = surface:getWidth()
    height = surface:getHeight()
    data = surface:getData()
    srcStride = surface:getStride()

    rowSize = width * 3
    -- BMP rows must be 4-byte aligned
    padding = (4 - (rowSize % 4)) % 4
    paddedRowSize = rowSize + padding
    pixelDataSize = paddedRowSize * height
    headerSize = 14 + 40 -- BITMAPFILEHEADER + BITMAPINFOHEADER
    fileSize = headerSize + pixelDataSize

    buf = buffer.create(fileSize)

    -- BITMAPFILEHEADER (14 bytes)
    buffer.writeu8(buf, 0, 0x42) -- 'B'
    buffer.writeu8(buf, 1, 0x4D) -- 'M'
    writeU32(buf, 2, fileSize)
    writeU16(buf, 6, 0)
    writeU16(buf, 8, 0)
    writeU32(buf, 10, headerSize)

    -- BITMAPINFOHEADER (40 bytes)
    writeU32(buf, 14, 40) -- header size
    writeU32(buf, 18, width) -- width
    writeU32(buf, 22, height) -- height (positive = bottom-up)
    writeU16(buf, 26, 1) -- planes
    writeU16(buf, 28, 24) -- bits per pixel (24-bit RGB)
    writeU32(buf, 30, 0) -- compression = BI_RGB
    writeU32(buf, 34, pixelDataSize) -- image size
    writeU32(buf, 38, 2835) -- x ppm
    writeU32(buf, 42, 2835) -- y ppm
    writeU32(buf, 46, 0) -- colors used
    writeU32(buf, 50, 0) -- important colors

    -- Write pixel data (BMP is bottom-up, 24-bit BGR)
    for y = 0, height - 1 do
        srcRow = y * srcStride
        dstRow = headerSize + (height - 1 - y) * paddedRowSize
        for x = 0, width - 1 do
            pixel = buffer.readu32(data, srcRow + x * 4)
            a = bit32.rshift(pixel, 24)
            r = bit32.band(bit32.rshift(pixel, 16), 0xFF)
            g = bit32.band(bit32.rshift(pixel, 8), 0xFF)
            b = bit32.band(pixel, 0xFF)
            -- Unpremultiply and composite over white background for display
            if a == 0 then
                r, g, b = 255, 255, 255
            else if a < 255 then
                r = math.min(255, math.floor(r * 255 / a + 0.5))
                g = math.min(255, math.floor(g * 255 / a + 0.5))
                b = math.min(255, math.floor(b * 255 / a + 0.5))
                -- Blend over white
                r = math.floor(r * a / 255 + 255 * (255 - a) / 255 + 0.5)
                g = math.floor(g * a / 255 + 255 * (255 - a) / 255 + 0.5)
                b = math.floor(b * a / 255 + 255 * (255 - a) / 255 + 0.5)
            end
            dstOff = dstRow + x * 3
            buffer.writeu8(buf, dstOff, b)
            buffer.writeu8(buf, dstOff + 1, g)
            buffer.writeu8(buf, dstOff + 2, r)
        end
        -- Padding bytes (already zeroed by buffer.create)
    end

    if not filename then
        return buf
    end
    iolib = (rawget(_G, "io") or {}).open
    if not iolib then
        return buf
    end
    f = iolib(filename, "wb")
    if not f then
        return nil
    end
    f:write(buffer.tostring(buf))
    f:close()
    return buf
end

function Bmp.encode(surface)
    return Bmp.write(surface, nil)
end

return Bmp
