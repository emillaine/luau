export a = 0
export b = 0

trap = table.freeze({})

pcall(function()
    a, trap.x, b = 1, 2, 3
end)

export function readA() return a end
export function readB() return b end
