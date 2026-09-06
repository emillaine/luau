-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
print("testing native integer register spills")

function test_many_locals(
    p0: integer, p1: integer, p2: integer, p3: integer
): integer
    assert(is_native())

    -- create many live values from various operations
    a = integer.add(p0, p1)
    b = integer.sub(p0, p1)
    c = integer.bxor(p2, p3)
    d = integer.band(p0, p3)
    e = integer.bor(p1, p2)
    f = integer.add(p2, p3)
    g = integer.bxor(a, b)
    h = integer.band(c, d)
    i = integer.bor(e, f)
    j = integer.add(a, c)
    k = integer.sub(b, d)
    l = integer.bxor(e, g)
    m = integer.band(f, h)
    n = integer.bor(g, i)
    o = integer.add(h, j)
    p = integer.sub(i, k)
    q = integer.bxor(j, l)
    r = integer.band(k, m)
    s = integer.bor(l, n)
    t = integer.add(m, o)

    -- invalidates restore locations for old values.
    a = integer.add(a, t)
    b = integer.bxor(b, s)
    c = integer.band(c, r)
    d = integer.bor(d, q)
    e = integer.sub(e, p)
    f = integer.add(f, o)
    g = integer.bxor(g, n)
    h = integer.band(h, m)
    i = integer.bor(i, l)
    j = integer.add(j, k)

    k = integer.bxor(a, integer.add(b, c))
    l = integer.band(d, integer.sub(e, f))
    m = integer.bor(g, integer.bxor(h, i))
    n = integer.add(j, integer.band(k, l))
    o = integer.sub(m, integer.bor(n, a))

    return integer.bxor(
        integer.bxor(integer.bxor(a, b), integer.bxor(c, d)),
        integer.bxor(integer.bxor(e, f), integer.bxor(g, h)),
        integer.bxor(integer.bxor(i, j), integer.bxor(k, l)),
        integer.bxor(integer.bxor(m, n), integer.bxor(o, p)),
        integer.bxor(integer.bxor(q, r), integer.bxor(s, t))
    )
end

function test_division_pressure(
    p0: integer, p1: integer, p2: integer, p3: integer
): integer
    assert(is_native())

    a = integer.add(p0, p1)
    b = integer.sub(p0, p1)
    c = integer.bxor(p2, p3)
    d = integer.band(p0, p3)
    e = integer.bor(p1, p2)
    f = integer.add(p2, p3)
    g = integer.bxor(a, b)
    h = integer.add(c, d)
    i = integer.bor(e, f)
    j = integer.bxor(g, h)
    k = integer.add(i, a)
    l = integer.bor(b, c)

    -- each div clobbers RAX+RDX, requiring spills of other live INT64 values
    d1 = integer.div(a, p1)
    d2 = integer.div(b, p2)
    d3 = integer.rem(c, p3)
    d4 = integer.mod(f, p0)
    d5 = integer.udiv(integer.bor(e, 1i), p1)

    return integer.bxor(
        integer.bxor(integer.bxor(a, b), integer.bxor(c, d)),
        integer.bxor(integer.bxor(e, f), integer.bxor(g, h)),
        integer.bxor(integer.bxor(i, j), integer.bxor(k, l)),
        integer.bxor(integer.bxor(d1, d2), integer.bxor(d3, d4)),
        d5
    )
end

-- shifts require RCX
function test_shift_pressure(
    p0: integer, p1: integer, p2: integer, p3: integer
): integer
    assert(is_native())

    a = integer.add(p0, p1)
    b = integer.sub(p0, p1)
    c = integer.bxor(p2, p3)
    d = integer.band(p0, p3)
    e = integer.bor(p1, p2)
    f = integer.add(p2, p3)
    g = integer.bxor(a, b)
    h = integer.add(c, d)
    i = integer.bor(e, f)
    j = integer.bxor(g, h)
    k = integer.add(i, a)
    l = integer.bor(b, c)

    sh1 = integer.band(p0, 7i)  -- 0..7
    sh2 = integer.band(p1, 15i) -- 0..15
    sh3 = integer.band(p2, 31i) -- 0..31
    sh4 = integer.band(p3, 63i) -- 0..63

    s1 = integer.lshift(a, sh1)
    s2 = integer.rshift(b, sh2)
    s3 = integer.arshift(c, sh3)
    s4 = integer.lrotate(d, sh4)
    s5 = integer.rrotate(e, sh1)
    s6 = integer.lshift(f, sh2)
    s7 = integer.rshift(g, sh3)
    s8 = integer.arshift(h, sh4)

    return integer.bxor(
        integer.bxor(integer.bxor(a, b), integer.bxor(c, d)),
        integer.bxor(integer.bxor(e, f), integer.bxor(g, h)),
        integer.bxor(integer.bxor(i, j), integer.bxor(k, l)),
        integer.bxor(integer.bxor(s1, s2), integer.bxor(s3, s4)),
        integer.bxor(integer.bxor(s5, s6), integer.bxor(s7, s8))
    )
end

-- regalloc may need to spill registers while in the loop
function test_loop_spill(
    p0: integer, p1: integer, p2: integer, p3: integer,
    iters: number
): integer
    assert(is_native())

    a = integer.add(p0, p1)
    b = integer.sub(p0, p1)
    c = integer.bxor(p2, p3)
    d = integer.band(p0, p3)
    e = integer.bor(p1, p2)
    f = integer.add(p2, p3)
    g = integer.bxor(a, b)
    h = integer.add(c, d)
    i = integer.bor(e, f)
    j = integer.bxor(g, h)
    k = integer.add(i, a)
    l = integer.bor(b, c)

    for iter = 1, iters do
        -- create register pressure within the loop
        a = integer.add(a, integer.bxor(b, c))
        b = integer.sub(b, integer.band(d, e))
        c = integer.bxor(c, integer.bor(f, g))
        d = integer.add(d, integer.bxor(h, i))
        e = integer.sub(e, integer.band(j, k))
        f = integer.bor(f, integer.add(l, a))
        g = integer.band(g, integer.sub(b, c))
        h = integer.bxor(h, integer.add(d, e))
        i = integer.bor(i, integer.sub(f, g))
        j = integer.add(j, integer.bxor(h, i))
        k = integer.sub(k, integer.band(j, a))
        l = integer.bxor(l, integer.bor(k, b))
    end

    return integer.bxor(
        integer.bxor(integer.bxor(a, b), integer.bxor(c, d)),
        integer.bxor(integer.bxor(e, f), integer.bxor(g, h)),
        integer.bxor(integer.bxor(i, j), integer.bxor(k, l))
    )
end

function test_mixed_pressure(
    p0: integer, p1: integer, p2: integer, p3: integer
): integer
    assert(is_native())

    a = integer.add(p0, p1)
    b = integer.sub(p0, p1)
    c = integer.bxor(p2, p3)
    d = integer.band(p0, p3)
    e = integer.bor(p1, p2)
    f = integer.add(p2, p3)
    g = integer.bxor(a, b)
    h = integer.add(c, d)
    i = integer.bor(e, f)
    j = integer.bxor(g, h)
    k = integer.add(i, a)
    l = integer.bor(b, c)

    m = integer.bxor(a, b, c, d, e)
    n = integer.band(f, g, h, i, j)
    o = integer.bor(k, l, a, b, c)

    d1 = integer.div(integer.add(a, 100i), p1)
    d2 = integer.idiv(integer.add(b, 200i), p2)

    sh = integer.band(p0, 7i)
    s1 = integer.lshift(m, sh)
    s2 = integer.rshift(n, sh)

    x = integer.add(d1, s1)
    y = integer.bxor(d2, s2)
    z = integer.band(x, y)

    return integer.bxor(
        integer.bxor(integer.bxor(a, b), integer.bxor(c, d)),
        integer.bxor(integer.bxor(e, f), integer.bxor(g, h)),
        integer.bxor(integer.bxor(i, j), integer.bxor(k, l)),
        integer.bxor(integer.bxor(m, n), integer.bxor(o, d1)),
        integer.bxor(integer.bxor(d2, s1), integer.bxor(s2, z))
    )
end

-- 30 live locals must require register spilling
function test_extreme_pressure(
    p0: integer, p1: integer, p2: integer, p3: integer
): integer
    assert(is_native())

    a = integer.add(p0, p1)
    b = integer.sub(p0, p1)
    c = integer.mul(p2, 3i)
    d = integer.bxor(p0, p3)
    e = integer.band(p1, p2)
    f = integer.bor(p2, p3)
    g = integer.bnot(p0)
    h = integer.lshift(p1, 3i)
    i = integer.rshift(p2, 2i)
    j = integer.arshift(p3, 1i)
    k = integer.lrotate(p0, 7i)
    l = integer.rrotate(p1, 5i)
    m = integer.add(a, b)
    n = integer.bxor(c, d)
    o = integer.band(e, f)

    p = integer.bor(g, h)
    q = integer.add(i, j)
    r = integer.sub(k, l)
    s = integer.bxor(m, n)
    t = integer.band(o, p)
    u = integer.bor(q, r)
    v = integer.add(s, t)
    w = integer.sub(u, a)
    x = integer.bxor(v, b)
    y = integer.band(w, c)
    z = integer.bor(x, d)
    a2 = integer.add(y, e)
    b2 = integer.sub(z, f)
    c2 = integer.bxor(a2, g)
    d2 = integer.band(b2, h)

    div1 = integer.div(integer.bor(a, 100i), p1)
    div2 = integer.div(integer.bor(m, 200i), p2)

    sh = integer.band(p0, 3i)
    sh1 = integer.lshift(n, sh)
    sh2 = integer.rshift(o, sh)

    t1 = integer.bxor(integer.bxor(a, b), integer.bxor(c, d))
    t2 = integer.bxor(integer.bxor(e, f), integer.bxor(g, h))
    t3 = integer.bxor(integer.bxor(i, j), integer.bxor(k, l))
    t4 = integer.bxor(integer.bxor(m, n), integer.bxor(o, p))
    t5 = integer.bxor(integer.bxor(q, r), integer.bxor(s, t))
    t6 = integer.bxor(integer.bxor(u, v), integer.bxor(w, x))
    t7 = integer.bxor(integer.bxor(y, z), integer.bxor(a2, b2))
    t8 = integer.bxor(integer.bxor(c2, d2), integer.bxor(div1, div2))
    t9 = integer.bxor(sh1, sh2)
    return integer.bxor(
        integer.bxor(t1, t2, t3, t4, t5),
        integer.bxor(t6, t7, t8, t9)
    )
end

-- values with significant upper 32 bits to detect truncation for incorrect spill widths
V0 = 0x1234567890ABCDEFi
V1 = 0xFEDCBA0987654321i
V2 = 0x0011223344556677i
V3 = 0x8899AABBCCDDEEFFi
V4 = 0xA5A5A5A5_5A5A5A5Ai

r1 = test_many_locals(V0, V1, V2, V3)
r2 = test_division_pressure(V0, V1, V2, V3)
r3 = test_shift_pressure(V0, V1, V2, V3)
r4 = test_loop_spill(V0, V1, V2, V3, 2)
r5 = test_mixed_pressure(V0, V1, V2, V3)
r6 = test_extreme_pressure(V0, V1, V2, V3)

assert(type(r1) == "integer")
assert(type(r2) == "integer")
assert(type(r3) == "integer")
assert(type(r4) == "integer")
assert(type(r5) == "integer")
assert(type(r6) == "integer")

assert(test_many_locals(V0, V1, V2, V3) == r1)
assert(test_division_pressure(V0, V1, V2, V3) == r2)
assert(test_shift_pressure(V0, V1, V2, V3) == r3)
assert(test_loop_spill(V0, V1, V2, V3, 2) == r4)

return "OK"
