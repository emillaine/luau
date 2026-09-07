#!native
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")
cvg = require("./charonvg/main")

W, H = 800, 600

function renderDemo()
    surface = cvg.Surface.create(W, H)
    surface:clear(cvg.Color.WHITE)
    ctx = cvg.Canvas.create(surface)

    ctx:setLinearGradient(40, 40, 200, 160, "pad", {
        { offset = 0, color = cvg.Color.rgb(1, 0.2, 0) },
        { offset = 0.5, color = cvg.Color.rgb(1, 1, 0) },
        { offset = 1, color = cvg.Color.rgb(1, 0.2, 0) },
    })
    ctx:fillRect(40, 40, 160, 120)
    ctx:setRgb(0.5, 0, 0)
    ctx:setLineWidth(4)
    ctx:strokeRect(40, 40, 160, 120)

    ctx:setRadialGradient(260, 120, 80, 240, 100, 0, "pad", {
        { offset = 0, color = cvg.Color.rgb(0.8, 0.9, 1) },
        { offset = 1, color = cvg.Color.rgb(0, 0, 0.8) },
    })
    ctx:circle(260, 120, 80)
    ctx:fill()
    ctx:setRgb(0, 0, 0.5)
    ctx:setLineWidth(4)
    ctx:circle(260, 120, 80)
    ctx:stroke()

    ctx:setRgba(0, 0.8, 0.2, 0.7)
    ctx:roundRect(80, 200, 240, 140, 30, 30)
    ctx:fill()
    ctx:setRgb(0, 0.3, 0)
    ctx:setLineWidth(3)
    ctx:roundRect(80, 200, 240, 140, 30, 30)
    ctx:stroke()

    ctx:setRgba(1, 0.9, 0, 0.5)
    ctx:ellipse(200, 200, 120, 70)
    ctx:fill()
    ctx:setRgb(0.5, 0.4, 0)
    ctx:setLineWidth(3)
    ctx:ellipse(200, 200, 120, 70)
    ctx:stroke()

    star = cvg.Path.create()
    cx, cy = 100, 110
    outerR, innerR = 70, 28
    for i = 0, 9 do
        angle = math.pi / 2 + i * math.pi / 5
        r = (i % 2 == 0) and outerR or innerR
        px = cx + r * math.cos(angle)
        py = cy - r * math.sin(angle)
        if i == 0 then
            star:moveTo(px, py)
        else
            star:lineTo(px, py)
        end
    end
    star:close()

    ctx:setRgba(0.6, 0, 0.8, 0.8)
    ctx:fillPath(star)
    ctx:setRgb(0.3, 0, 0.4)
    ctx:setLineWidth(3)
    ctx:strokePath(star)

    #return surface
end

# Warmup
renderDemo()


bench.runCode(renderDemo, "charonvg-scene")

