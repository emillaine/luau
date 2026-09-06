function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

function test()

    --The Computer Language Benchmarks Game
    -- https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
    --contributed by Mike Pall

    PI = 3.141592653589793
    SOLAR_MASS = 4 * PI * PI
    DAYS_PER_YEAR = 365.24

    type Body = { pos: vector, vel: vector, mass: number }
    
    bodies = {
        { --Sun
            pos = vector.create(0, 0, 0),
            vel = vector.create(0, 0, 0),
            mass = SOLAR_MASS
        },
        { --Jupiter
            pos = vector.create(4.84143144246472090e+00, -1.16032004402742839e+00, -1.03622044471123109e-01),
            vel = vector.create(1.66007664274403694e-03 * DAYS_PER_YEAR, 7.69901118419740425e-03 * DAYS_PER_YEAR, -6.90460016972063023e-05 * DAYS_PER_YEAR),
            mass = 9.54791938424326609e-04 * SOLAR_MASS
        },
        { --Saturn
            pos = vector.create(8.34336671824457987e+00, 4.12479856412430479e+00, -4.03523417114321381e-01),
            vel = vector.create(-2.76742510726862411e-03 * DAYS_PER_YEAR, 4.99852801234917238e-03 * DAYS_PER_YEAR, 2.30417297573763929e-05 * DAYS_PER_YEAR),
            mass = 2.85885980666130812e-04 * SOLAR_MASS
        },
        { --Uranus
            pos = vector.create(1.28943695621391310e+01, -1.51111514016986312e+01, -2.23307578892655734e-01),
            vel = vector.create(2.96460137564761618e-03 * DAYS_PER_YEAR, 2.37847173959480950e-03 * DAYS_PER_YEAR, -2.96589568540237556e-05 * DAYS_PER_YEAR),
            mass = 4.36624404335156298e-05 * SOLAR_MASS
        },
        { --Neptune
            pos = vector.create(1.53796971148509165e+01, -2.59193146099879641e+01, 1.79258772950371181e-01),
            vel = vector.create(2.68067772490389322e-03 * DAYS_PER_YEAR, 1.62824170038242295e-03 * DAYS_PER_YEAR, -9.51592254519715870e-05 * DAYS_PER_YEAR),
            mass = 5.15138902046611451e-05 * SOLAR_MASS
        }
    }

    function advance(bodies: {Body}, nbody: number, dt: number)
        for i = 1, nbody do
            bi = bodies[i]
            bipos, bimass = bi.pos, bi.mass
            bivel = bi.vel

            for j = i + 1, nbody do
                bj = bodies[j]

                dpos = bipos - bj.pos
                distance = vector.magnitude(dpos)

                mag = dt / (distance * distance * distance)
                bim, bjm = bimass * mag, bj.mass * mag

                bivel -= dpos * bjm
                bj.vel += dpos * bim
            end
            
            bi.vel = bivel
        end

        for i = 1, nbody do
            bi = bodies[i]
            bi.pos += dt * bi.vel
        end
    end

    function offsetMomentum(bodies: {Body}, nbody: number)
        p = vector.create(0, 0, 0)

        for i = 1, nbody do
            bi = bodies[i]
            p += bi.vel * bi.mass
        end

        bodies[1].vel = -p / SOLAR_MASS
    end

    function energy(bodies: {Body}, nbody: number)
        e = 0

        for i = 1, nbody do
            bi = bodies[i]
            vel = bi.vel
            e += 0.5 * bi.mass * vector.dot(vel, vel)

            for j = i + 1, nbody do
                bj = bodies[j]
                distance = vector.magnitude(bi.pos - bj.pos)
                e -= (bi.mass * bj.mass) / distance
            end
        end

        return e
    end

    N = 20000
    nbody = #bodies

    ts0 = os.clock()
    offsetMomentum(bodies, nbody)
    for i = 1, N do advance(bodies, nbody, 0.01) end
    ts1 = os.clock()

    assert(math.abs(energy(bodies, nbody) + 0.169085) < 1e-4)

    return ts1 - ts0
end

bench.runCode(test, "n-body-vec")
