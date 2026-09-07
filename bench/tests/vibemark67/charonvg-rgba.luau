#!native
svg = require("./charonvg/main")
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

Surface = svg.Surface
Color = svg.Color
Canvas = svg.Canvas

W, H = 800, 600
s = Surface.create(W, H)
s:clear(Color.WHITE)
ctx = Canvas.create(s)

# Create a realistic mixed surface (opaque bg + semi-transparent shapes)
ctx:setRgba(0.8, 0.2, 0.4, 0.7)
ctx:circle(400, 300, 250)
ctx:fill()
ctx:setRgba(0.2, 0.6, 1.0, 0.5)
ctx:circle(300, 250, 150)
ctx:fill()

# Warmup
s:getRGBA()

function test()
    for i=1,10 do
        s:getRGBA()
    end
end

bench.runCode(test, "charonvg-rgba")
