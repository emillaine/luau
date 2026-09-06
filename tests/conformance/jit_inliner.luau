-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details

const INLINING_THREASHOLD = 64

do
    function compute(a, b)
        c = a + b
        d = c * 4.0
        e = d - 0.5
        f = e / 2.0
        g = f * 4.0
        h = g + 1.0
        i = h - 0.5
        j = i + 8.5
        k = j * 2.0
        return k
    end

    function caller()
        return compute(2.0, 0.5)
    end

    for _ = 1, INLINING_THREASHOLD do
        assert(caller() == 56.0)
    end
end

do
    function clamp(x, lo, hi)
        if x < lo then return lo
        else if x > hi then return hi
        else return x end
    end

    function selectPath(mode, a, b, c)
        if mode == 1 then return a + b
        else if mode == 2 then return a * c
        else return 0 end
    end

    for i = 0, INLINING_THREASHOLD do
        v = selectPath(2, i, 10, 3)
        w = clamp(v, 0, 1000)
        assert(w == i * 3)
    end
end

do
    function inlinee()
        function inner() return 67 end
        return 42 + inner()
    end

    function caller()
        inlinee()
    end

    for _ = 1, INLINING_THREASHOLD do
        caller()
    end
end

do
    -- select("#", ...) / select(i, ...) inside a vararg function (Immutable.Append pattern).
    -- select fuses to a FASTCALL with GETVARARGS between it and the paired CALL; inlining it would
    -- shift the CALL and break the FASTCALL skip offset. The inliner must refuse to inline `append`.
    function append(list, ...)
        new = {}
        len = list.count
        for key = 1, len do
            new[key] = list[key]
        end
        for i = 1, select("#", ...) do
            new[len + i] = select(i, ...)
        end
        return new
    end

    function run()
        r = append({ 1, 2 }, 7, 8, 9)
        return r.count * 10000 + r[3] * 100 + r[5]
    end

    for _ = 1, INLINING_THREASHOLD do
        assert(run() == 50709, "vararg select must not be miscompiled by inlining")
    end
end

_G.fuzzfail_infinite1 = function()
    function foo(x)
        repeat
            x = null
            (function(...) end)()
        until x

        -- unreachable SCC that closes upvalues
        repeat
            y = {}
        until not function() y = null end
    end

    for _ in foo do end
end

_G.fuzzfail_infinite2 = function()
    f = function(...) end
    x = 1
    while true do
        f(1, function(...)
            x *= x
        end)
    end
end

return 'OK'
