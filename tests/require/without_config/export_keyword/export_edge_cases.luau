export x = 5
x = x + 1

export s = "a"
s = s .. "b"

export n
n = 42

export step = 0
step = step + 1
step = step + 1
step = step + 1

export sum = 0
for i = 1, 3 do
    sum += i
end

export prod = 1
i = 1
while i <= 4 do
    prod = prod * i
    i += 1
end

export t = { x = 1 }
t = { x = t.x + 1 }

export a = 1
b = nil
a, b = a + 1, a + 2

export closure = 0
closure = (function() return closure + 1 end)()

export fw
function fw()
    return "forward"
end

export f = math.max

function inner(...)
    return f(...)
end

assert(inner("3", 7) == 7)
