-- forward declaration (no hoisted globals)
findContactPoints_PolygonPolygon = null
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

function test()


-- 2D Physics Engine Benchmark
-- A rigid body dynamics simulation with broad-phase (spatial hash) and narrow-phase
-- (SAT) collision detection, sequential impulse constraint solver, joints, and friction.
-- Style: vectors as plain tables, mix of local functions and upvalues, math-heavy.

M = {sqrt = math.sqrt, abs = math.abs, min = math.min, max = math.max, cos = math.cos, sin = math.sin, atan2 = math.atan2 or math.atan, pi = math.pi, huge = math.huge, floor = math.floor}

-- Deterministic PRNG
prng_state = 12345
function random()
    prng_state = (prng_state * 1103515245 + 12345) % 2147483648
    return prng_state / 2147483648
end

function randomRange(lo, hi)
    return lo + random() * (hi - lo)
end

function resetRandom()
    prng_state = 12345
end

-- ============================================================================
-- Vector operations (no metatables - just functions on {x, y} tables)
-- ============================================================================

function vec(x, y)
    return {x = x, y = y}
end

function vecAdd(a, b)
    return {x = a.x + b.x, y = a.y + b.y}
end

function vecSub(a, b)
    return {x = a.x - b.x, y = a.y - b.y}
end

function vecMul(v, s)
    return {x = v.x * s, y = v.y * s}
end

function vecDiv(v, s)
    return {x = v.x / s, y = v.y / s}
end

function vecDot(a, b)
    return a.x * b.x + a.y * b.y
end

function vecCross(a, b)
    return a.x * b.y - a.y * b.x
end

function vecCrossScalar(v, s)
    return {x = -s * v.y, y = s * v.x}
end

function scalarCrossVec(s, v)
    return {x = -s * v.y, y = s * v.x}
end

function vecLen(v)
    return M.sqrt(v.x * v.x + v.y * v.y)
end

function vecLenSq(v)
    return v.x * v.x + v.y * v.y
end

function vecNormalize(v)
    len = M.sqrt(v.x * v.x + v.y * v.y)
    if len < 1e-10 then return {x = 0, y = 0} end
    return {x = v.x / len, y = v.y / len}
end

function vecNeg(v)
    return {x = -v.x, y = -v.y}
end

function vecPerp(v)
    return {x = -v.y, y = v.x}
end

function vecRotate(v, angle)
    c = M.cos(angle)
    s = M.sin(angle)
    return {x = v.x * c - v.y * s, y = v.x * s + v.y * c}
end

function vecLerp(a, b, t)
    return {x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t}
end

function vecDist(a, b)
    dx = b.x - a.x
    dy = b.y - a.y
    return M.sqrt(dx * dx + dy * dy)
end

function vecDistSq(a, b)
    dx = b.x - a.x
    dy = b.y - a.y
    return dx * dx + dy * dy
end

function vecClamp(v, maxLen)
    lenSq = v.x * v.x + v.y * v.y
    if lenSq > maxLen * maxLen then
        len = M.sqrt(lenSq)
        return {x = v.x * maxLen / len, y = v.y * maxLen / len}
    end
    return v
end

function vecEqual(a, b, eps)
    eps = eps or 1e-6
    return M.abs(a.x - b.x) < eps and M.abs(a.y - b.y) < eps
end

-- ============================================================================
-- Matrix 2x2 operations (for rotations)
-- ============================================================================

function mat2(angle)
    c = M.cos(angle)
    s = M.sin(angle)
    return {m00 = c, m01 = -s, m10 = s, m11 = c}
end

function mat2MulVec(m, v)
    return {x = m.m00 * v.x + m.m01 * v.y, y = m.m10 * v.x + m.m11 * v.y}
end

function mat2Transpose(m)
    return {m00 = m.m00, m01 = m.m10, m10 = m.m01, m11 = m.m11}
end

-- ============================================================================
-- Shape definitions
-- ============================================================================

SHAPE_CIRCLE = 1
SHAPE_POLYGON = 2

function createCircle(radius)
    return {
        type = SHAPE_CIRCLE,
        radius = radius,
        area = M.pi * radius * radius
    }
end

function computePolygonArea(vertices)
    area = 0
    n = #vertices
    for i = 1, n do
        j = (i % n) + 1
        area = area + vertices[i].x * vertices[j].y
        area = area - vertices[j].x * vertices[i].y
    end
    return M.abs(area) / 2
end

function computePolygonCentroid(vertices)
    cx, cy = 0, 0
    n = #vertices
    area = 0
    for i = 1, n do
        j = (i % n) + 1
        cross = vertices[i].x * vertices[j].y - vertices[j].x * vertices[i].y
        area = area + cross
        cx = cx + (vertices[i].x + vertices[j].x) * cross
        cy = cy + (vertices[i].y + vertices[j].y) * cross
    end
    area = area / 2
    if M.abs(area) < 1e-10 then return vec(0, 0) end
    cx = cx / (6 * area)
    cy = cy / (6 * area)
    return vec(cx, cy)
end

function computePolygonMOI(vertices, mass)
    n = #vertices
    numerator = 0
    denominator = 0
    for i = 1, n do
        j = (i % n) + 1
        vi = vertices[i]
        vj = vertices[j]
        cross = M.abs(vecCross(vi, vj))
        numerator = numerator + cross * (vecDot(vi, vi) + vecDot(vi, vj) + vecDot(vj, vj))
        denominator = denominator + cross
    end
    if denominator < 1e-10 then return mass end
    return mass * numerator / (6 * denominator)
end

function computePolygonNormals(vertices)
    normals = {}
    n = #vertices
    for i = 1, n do
        j = (i % n) + 1
        edge = vecSub(vertices[j], vertices[i])
        normal = vecNormalize(vecPerp(edge))
        normals[i] = normal
    end
    return normals
end

function createPolygon(vertices)
    centroid = computePolygonCentroid(vertices)
    centered = {}
    for i = 1, #vertices do
        centered[i] = vecSub(vertices[i], centroid)
    end
    normals = computePolygonNormals(centered)
    area = computePolygonArea(centered)
    return {
        type = SHAPE_POLYGON,
        vertices = centered,
        normals = normals,
        vertexCount = #centered,
        area = area,
        centroidOffset = centroid
    }
end

function createBox(halfWidth, halfHeight)
    vertices = {
        vec(-halfWidth, -halfHeight),
        vec(halfWidth, -halfHeight),
        vec(halfWidth, halfHeight),
        vec(-halfWidth, halfHeight)
    }
    return createPolygon(vertices)
end

function createRegularPolygon(radius, sides)
    vertices = {}
    for i = 1, sides do
        angle = (i - 1) * 2 * M.pi / sides - M.pi / 2
        vertices[i] = vec(radius * M.cos(angle), radius * M.sin(angle))
    end
    return createPolygon(vertices)
end

-- ============================================================================
-- Rigid Body
-- ============================================================================

bodyIdCounter = 0

function createBody(shape, x, y, density, isStatic)
    bodyIdCounter = bodyIdCounter + 1
    mass, invMass, inertia, invInertia = null, null, null, null
    if isStatic then
        mass = 0
        invMass = 0
        inertia = 0
        invInertia = 0
    else
        mass = shape.area * density
        invMass = 1 / mass
        if shape.type == SHAPE_CIRCLE then
            inertia = 0.5 * mass * shape.radius * shape.radius
        else
            inertia = computePolygonMOI(shape.vertices, mass)
        end
        invInertia = 1 / inertia
    end

    return {
        id = bodyIdCounter,
        shape = shape,
        position = vec(x, y),
        velocity = vec(0, 0),
        angle = 0,
        angularVelocity = 0,
        force = vec(0, 0),
        torque = 0,
        mass = mass,
        invMass = invMass,
        inertia = inertia,
        invInertia = invInertia,
        isStatic = isStatic or false,
        restitution = 0.3,
        staticFriction = 0.6,
        dynamicFriction = 0.4,
        linearDamping = 0.01,
        angularDamping = 0.01,
        gravityScale = 1.0,
        userData = null
    }
end

function bodyApplyForce(body, force)
    body.force = vecAdd(body.force, force)
end

function bodyApplyForceAtPoint(body, force, point)
    body.force = vecAdd(body.force, force)
    r = vecSub(point, body.position)
    body.torque = body.torque + vecCross(r, force)
end

function bodyApplyImpulse(body, impulse, contactPoint)
    if body.isStatic then return end
    body.velocity = vecAdd(body.velocity, vecMul(impulse, body.invMass))
    r = vecSub(contactPoint, body.position)
    body.angularVelocity = body.angularVelocity + body.invInertia * vecCross(r, impulse)
end

function bodyGetVelocityAtPoint(body, point)
    r = vecSub(point, body.position)
    return vecAdd(body.velocity, scalarCrossVec(body.angularVelocity, r))
end

function bodyGetTransformedVertices(body)
    shape = body.shape
    if shape.type != SHAPE_POLYGON then return null end
    rot = mat2(body.angle)
    transformed = {}
    for i = 1, shape.vertexCount do
        v = mat2MulVec(rot, shape.vertices[i])
        transformed[i] = vecAdd(v, body.position)
    end
    return transformed
end

function bodyGetTransformedNormals(body)
    shape = body.shape
    if shape.type != SHAPE_POLYGON then return null end
    rot = mat2(body.angle)
    transformed = {}
    for i = 1, shape.vertexCount do
        transformed[i] = mat2MulVec(rot, shape.normals[i])
    end
    return transformed
end

function bodyGetAABB(body)
    shape = body.shape
    if shape.type == SHAPE_CIRCLE then
        r = shape.radius
        return {
            minX = body.position.x - r,
            minY = body.position.y - r,
            maxX = body.position.x + r,
            maxY = body.position.y + r
        }
    else
        verts = bodyGetTransformedVertices(body)
        minX, minY = M.huge, M.huge
        maxX, maxY = -M.huge, -M.huge
        for i = 1, #verts do
            v = verts[i]
            if v.x < minX then minX = v.x end
            if v.y < minY then minY = v.y end
            if v.x > maxX then maxX = v.x end
            if v.y > maxY then maxY = v.y end
        end
        return {minX = minX, minY = minY, maxX = maxX, maxY = maxY}
    end
end

-- ============================================================================
-- Spatial Hash (broad-phase)
-- ============================================================================

function createSpatialHash(cellSize)
    return {
        cellSize = cellSize,
        invCellSize = 1 / cellSize,
        cells = {},
        bodyToCells = {}
    }
end

function spatialHashKey(hash, x, y)
    return x * 73856093 + y * 19349663
end

function spatialHashClear(hash)
    hash.cells = {}
    hash.bodyToCells = {}
end

function spatialHashInsert(hash, body)
    aabb = bodyGetAABB(body)
    invCell = hash.invCellSize
    minCX = M.floor(aabb.minX * invCell)
    minCY = M.floor(aabb.minY * invCell)
    maxCX = M.floor(aabb.maxX * invCell)
    maxCY = M.floor(aabb.maxY * invCell)

    myCells = {}
    for cx = minCX, maxCX do
        for cy = minCY, maxCY do
            key = spatialHashKey(hash, cx, cy)
            cell = hash.cells[key]
            if not cell then
                cell = {}
                hash.cells[key] = cell
            end
            cell[#cell + 1] = body
            myCells[#myCells + 1] = key
        end
    end
    hash.bodyToCells[body.id] = myCells
end

function spatialHashQuery(hash, aabb)
    invCell = hash.invCellSize
    minCX = M.floor(aabb.minX * invCell)
    minCY = M.floor(aabb.minY * invCell)
    maxCX = M.floor(aabb.maxX * invCell)
    maxCY = M.floor(aabb.maxY * invCell)

    seen = {}
    results = {}
    for cx = minCX, maxCX do
        for cy = minCY, maxCY do
            key = spatialHashKey(hash, cx, cy)
            cell = hash.cells[key]
            if cell then
                for i = 1, #cell do
                    b = cell[i]
                    if not seen[b.id] then
                        seen[b.id] = true
                        results[#results + 1] = b
                    end
                end
            end
        end
    end
    return results
end

function spatialHashFindPairs(hash, bodies)
    spatialHashClear(hash)
    for i = 1, #bodies do
        spatialHashInsert(hash, bodies[i])
    end

    foundPairs = {}
    pairSet = {}

    -- Collect cell keys into an array and sort them for deterministic iteration
    cellKeys = {}
    for key in next, hash.cells do
        cellKeys[#cellKeys + 1] = key
    end
    table.sort(cellKeys)

    for ki = 1, #cellKeys do
        cell = hash.cells[cellKeys[ki]]
        n = #cell
        for i = 1, n do
            for j = i + 1, n do
                a = cell[i]
                b = cell[j]
                if not (a.isStatic and b.isStatic) then
                    pairKey = null
                    if a.id < b.id then
                        pairKey = a.id * 100000 + b.id
                    else
                        pairKey = b.id * 100000 + a.id
                    end
                    if not pairSet[pairKey] then
                        pairSet[pairKey] = true
                        if a.id < b.id then
                            foundPairs[#foundPairs + 1] = {a = a, b = b}
                        else
                            foundPairs[#foundPairs + 1] = {a = b, b = a}
                        end
                    end
                end
            end
        end
    end
    return foundPairs
end

-- ============================================================================
-- AABB overlap test
-- ============================================================================

function aabbOverlap(a, b)
    aabb1 = bodyGetAABB(a)
    aabb2 = bodyGetAABB(b)
    return aabb1.maxX >= aabb2.minX and aabb1.minX <= aabb2.maxX and
           aabb1.maxY >= aabb2.minY and aabb1.minY <= aabb2.maxY
end

-- ============================================================================
-- Narrow-phase: SAT (Separating Axis Theorem)
-- ============================================================================

function projectPolygonOnAxis(vertices, axis)
    min = vecDot(vertices[1], axis)
    max = min
    for i = 2, #vertices do
        proj = vecDot(vertices[i], axis)
        if proj < min then min = proj end
        if proj > max then max = proj end
    end
    return min, max
end

function projectCircleOnAxis(center, radius, axis)
    proj = vecDot(center, axis)
    return proj - radius, proj + radius
end

function findPolygonPolygonContacts(bodyA, bodyB)
    vertsA = bodyGetTransformedVertices(bodyA)
    vertsB = bodyGetTransformedVertices(bodyB)
    normalsA = bodyGetTransformedNormals(bodyA)
    normalsB = bodyGetTransformedNormals(bodyB)

    minOverlap = M.huge
    separatingNormal = null
    referenceBody = null
    incidentBody = null

    for i = 1, #normalsA do
        axis = normalsA[i]
        minA, maxA = projectPolygonOnAxis(vertsA, axis)
        minB, maxB = projectPolygonOnAxis(vertsB, axis)

        if maxA < minB or maxB < minA then
            return null
        end

        overlap = M.min(maxA - minB, maxB - minA)
        if overlap < minOverlap then
            minOverlap = overlap
            separatingNormal = axis
            referenceBody = bodyA
            incidentBody = bodyB
        end
    end

    for i = 1, #normalsB do
        axis = normalsB[i]
        minA, maxA = projectPolygonOnAxis(vertsA, axis)
        minB, maxB = projectPolygonOnAxis(vertsB, axis)

        if maxA < minB or maxB < minA then
            return null
        end

        overlap = M.min(maxA - minB, maxB - minA)
        if overlap < minOverlap then
            minOverlap = overlap
            separatingNormal = axis
            referenceBody = bodyB
            incidentBody = bodyA
        end
    end

    direction = vecSub(bodyB.position, bodyA.position)
    if vecDot(direction, separatingNormal) < 0 then
        separatingNormal = vecNeg(separatingNormal)
    end

    contacts = findContactPoints_PolygonPolygon(vertsA, vertsB, separatingNormal)

    return {
        bodyA = bodyA,
        bodyB = bodyB,
        normal = separatingNormal,
        penetration = minOverlap,
        contacts = contacts,
        friction = M.sqrt(bodyA.dynamicFriction * bodyB.dynamicFriction),
        restitution = M.max(bodyA.restitution, bodyB.restitution)
    }
end

function findContactPoints_PolygonPolygon(vertsA, vertsB, normal)
    contacts = {}

    function findSupport(vertices, direction)
        maxProj = -M.huge
        best = null
        for i = 1, #vertices do
            proj = vecDot(vertices[i], direction)
            if proj > maxProj then
                maxProj = proj
                best = vertices[i]
            end
        end
        return best
    end

    function findIncidentEdge(vertices, refNormal)
        n = #vertices
        minDot = M.huge
        edgeIdx = 1
        for i = 1, n do
            j = (i % n) + 1
            edge = vecSub(vertices[j], vertices[i])
            edgeNormal = vecNormalize(vecPerp(edge))
            d = vecDot(edgeNormal, refNormal)
            if d < minDot then
                minDot = d
                edgeIdx = i
            end
        end
        j = (edgeIdx % n) + 1
        return vertices[edgeIdx], vertices[j]
    end

    function clipSegment(v1, v2, normal, offset)
        out = {}
        d1 = vecDot(normal, v1) - offset
        d2 = vecDot(normal, v2) - offset
        if d1 >= 0 then out[#out + 1] = v1 end
        if d2 >= 0 then out[#out + 1] = v2 end
        if d1 * d2 < 0 then
            t = d1 / (d1 - d2)
            out[#out + 1] = vecLerp(v1, v2, t)
        end
        return out
    end

    supportA = findSupport(vertsA, normal)
    supportB = findSupport(vertsB, vecNeg(normal))

    e1, e2 = findIncidentEdge(vertsB, normal)

    nA = #vertsA
    refIdx = 1
    maxProj = -M.huge
    for i = 1, nA do
        proj = vecDot(vertsA[i], normal)
        if proj > maxProj then
            maxProj = proj
            refIdx = i
        end
    end

    refV1 = vertsA[refIdx]
    refV2 = vertsA[(refIdx % nA) + 1]
    refEdge = vecNormalize(vecSub(refV2, refV1))
    refNormal = vecPerp(refEdge)

    offset1 = vecDot(refEdge, refV1)
    offset2 = vecDot(refEdge, refV2)

    clipped = clipSegment(e1, e2, refEdge, offset1)
    if #clipped < 2 then
        contacts[1] = supportB
        return contacts
    end

    clipped = clipSegment(clipped[1], clipped[2], vecNeg(refEdge), -offset2)
    if #clipped < 2 then
        contacts[1] = supportB
        return contacts
    end

    refOffset = vecDot(refNormal, refV1)
    for i = 1, #clipped do
        sep = vecDot(refNormal, clipped[i]) - refOffset
        if sep <= 0 then
            contacts[#contacts + 1] = clipped[i]
        end
    end

    if #contacts == 0 then
        contacts[1] = supportB
    end

    return contacts
end

function findCircleCircleContacts(bodyA, bodyB)
    diff = vecSub(bodyB.position, bodyA.position)
    dist = vecLen(diff)
    radiusSum = bodyA.shape.radius + bodyB.shape.radius

    if dist >= radiusSum then return null end

    normal = null
    if dist < 1e-10 then
        normal = vec(1, 0)
    else
        normal = vecDiv(diff, dist)
    end

    penetration = radiusSum - dist
    contactPoint = vecAdd(bodyA.position, vecMul(normal, bodyA.shape.radius - penetration / 2))

    return {
        bodyA = bodyA,
        bodyB = bodyB,
        normal = normal,
        penetration = penetration,
        contacts = {contactPoint},
        friction = M.sqrt(bodyA.dynamicFriction * bodyB.dynamicFriction),
        restitution = M.max(bodyA.restitution, bodyB.restitution)
    }
end

function findCirclePolygonContacts(circleBody, polyBody)
    shape = polyBody.shape
    verts = bodyGetTransformedVertices(polyBody)
    normals = bodyGetTransformedNormals(polyBody)
    center = circleBody.position
    radius = circleBody.shape.radius

    minOverlap = M.huge
    separatingNormal = null
    axisType = null

    for i = 1, #normals do
        axis = normals[i]
        minP, maxP = projectPolygonOnAxis(verts, axis)
        minC, maxC = projectCircleOnAxis(center, radius, axis)
        if maxP < minC or maxC < minP then return null end
        overlap = M.min(maxP - minC, maxC - minP)
        if overlap < minOverlap then
            minOverlap = overlap
            separatingNormal = axis
            axisType = "face"
        end
    end

    closestDist = M.huge
    closestVertex = null
    for i = 1, #verts do
        d = vecDistSq(center, verts[i])
        if d < closestDist then
            closestDist = d
            closestVertex = verts[i]
        end
    end

    vertexAxis = vecNormalize(vecSub(center, closestVertex))
    minP, maxP = projectPolygonOnAxis(verts, vertexAxis)
    minC, maxC = projectCircleOnAxis(center, radius, vertexAxis)
    if maxP < minC or maxC < minP then return null end
    overlap = M.min(maxP - minC, maxC - minP)
    if overlap < minOverlap then
        minOverlap = overlap
        separatingNormal = vertexAxis
        axisType = "vertex"
    end

    direction = vecSub(center, polyBody.position)
    if vecDot(direction, separatingNormal) < 0 then
        separatingNormal = vecNeg(separatingNormal)
    end

    contactPoint = vecSub(center, vecMul(separatingNormal, radius - minOverlap / 2))

    return {
        bodyA = circleBody,
        bodyB = polyBody,
        normal = separatingNormal,
        penetration = minOverlap,
        contacts = {contactPoint},
        friction = M.sqrt(circleBody.dynamicFriction * polyBody.dynamicFriction),
        restitution = M.max(circleBody.restitution, polyBody.restitution)
    }
end

function detectCollision(bodyA, bodyB)
    shapeA = bodyA.shape.type
    shapeB = bodyB.shape.type

    if shapeA == SHAPE_CIRCLE and shapeB == SHAPE_CIRCLE then
        return findCircleCircleContacts(bodyA, bodyB)
    else if shapeA == SHAPE_POLYGON and shapeB == SHAPE_POLYGON then
        return findPolygonPolygonContacts(bodyA, bodyB)
    else if shapeA == SHAPE_CIRCLE and shapeB == SHAPE_POLYGON then
        return findCirclePolygonContacts(bodyA, bodyB)
    else if shapeA == SHAPE_POLYGON and shapeB == SHAPE_CIRCLE then
        manifold = findCirclePolygonContacts(bodyB, bodyA)
        if manifold then
            manifold.normal = vecNeg(manifold.normal)
            manifold.bodyA = bodyA
            manifold.bodyB = bodyB
        end
        return manifold
    end
    return null
end

-- ============================================================================
-- Constraint Solver (Sequential Impulses)
-- ============================================================================

function preSolveContact(manifold, dt)
    bodyA = manifold.bodyA
    bodyB = manifold.bodyB
    normal = manifold.normal
    tangent = vecPerp(normal)

    manifold.tangent = tangent

    for i = 1, #manifold.contacts do
        contact = manifold.contacts[i]
        cp = {}
        cp.point = contact
        cp.rA = vecSub(contact, bodyA.position)
        cp.rB = vecSub(contact, bodyB.position)

        rnA = vecCross(cp.rA, normal)
        rnB = vecCross(cp.rB, normal)
        kNormal = bodyA.invMass + bodyB.invMass +
                        bodyA.invInertia * rnA * rnA +
                        bodyB.invInertia * rnB * rnB
        cp.massNormal = 1 / kNormal

        rtA = vecCross(cp.rA, tangent)
        rtB = vecCross(cp.rB, tangent)
        kTangent = bodyA.invMass + bodyB.invMass +
                         bodyA.invInertia * rtA * rtA +
                         bodyB.invInertia * rtB * rtB
        cp.massTangent = 1 / kTangent

        relVel = vecSub(
            vecAdd(bodyB.velocity, scalarCrossVec(bodyB.angularVelocity, cp.rB)),
            vecAdd(bodyA.velocity, scalarCrossVec(bodyA.angularVelocity, cp.rA))
        )
        velAlongNormal = vecDot(relVel, normal)

        cp.bias = 0
        baumgarte = 0.2
        slop = 0.005
        if manifold.penetration > slop then
            cp.bias = -baumgarte / dt * (manifold.penetration - slop)
        end

        cp.velocityBias = 0
        if velAlongNormal < -1.0 then
            cp.velocityBias = -manifold.restitution * velAlongNormal
        end

        cp.normalImpulse = 0
        cp.tangentImpulse = 0

        manifold.contacts[i] = cp
    end
end

function solveContact(manifold)
    bodyA = manifold.bodyA
    bodyB = manifold.bodyB
    normal = manifold.normal
    tangent = manifold.tangent

    for i = 1, #manifold.contacts do
        cp = manifold.contacts[i]

        relVel = vecSub(
            vecAdd(bodyB.velocity, scalarCrossVec(bodyB.angularVelocity, cp.rB)),
            vecAdd(bodyA.velocity, scalarCrossVec(bodyA.angularVelocity, cp.rA))
        )

        velAlongNormal = vecDot(relVel, normal)
        normalImpulse = cp.massNormal * (-velAlongNormal + cp.bias + cp.velocityBias)

        oldNormalImpulse = cp.normalImpulse
        cp.normalImpulse = M.max(oldNormalImpulse + normalImpulse, 0)
        normalImpulse = cp.normalImpulse - oldNormalImpulse

        impulse = vecMul(normal, normalImpulse)
        bodyA.velocity = vecSub(bodyA.velocity, vecMul(impulse, bodyA.invMass))
        bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * vecCross(cp.rA, impulse)
        bodyB.velocity = vecAdd(bodyB.velocity, vecMul(impulse, bodyB.invMass))
        bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * vecCross(cp.rB, impulse)

        relVel = vecSub(
            vecAdd(bodyB.velocity, scalarCrossVec(bodyB.angularVelocity, cp.rB)),
            vecAdd(bodyA.velocity, scalarCrossVec(bodyA.angularVelocity, cp.rA))
        )

        velAlongTangent = vecDot(relVel, tangent)
        tangentImpulse = cp.massTangent * (-velAlongTangent)

        maxFriction = manifold.friction * cp.normalImpulse
        oldTangentImpulse = cp.tangentImpulse
        cp.tangentImpulse = M.max(-maxFriction, M.min(oldTangentImpulse + tangentImpulse, maxFriction))
        tangentImpulse = cp.tangentImpulse - oldTangentImpulse

        frictionImpulse = vecMul(tangent, tangentImpulse)
        bodyA.velocity = vecSub(bodyA.velocity, vecMul(frictionImpulse, bodyA.invMass))
        bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * vecCross(cp.rA, frictionImpulse)
        bodyB.velocity = vecAdd(bodyB.velocity, vecMul(frictionImpulse, bodyB.invMass))
        bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * vecCross(cp.rB, frictionImpulse)
    end
end

-- ============================================================================
-- Joints
-- ============================================================================

function createDistanceJoint(bodyA, bodyB, anchorA, anchorB, distance)
    return {
        type = "distance",
        bodyA = bodyA,
        bodyB = bodyB,
        localAnchorA = anchorA,
        localAnchorB = anchorB,
        targetDistance = distance,
        stiffness = 100.0,
        damping = 5.0,
        impulse = 0
    }
end

function createRevoluteJoint(bodyA, bodyB, anchorA, anchorB)
    return {
        type = "revolute",
        bodyA = bodyA,
        bodyB = bodyB,
        localAnchorA = anchorA,
        localAnchorB = anchorB,
        impulse = vec(0, 0),
        motorSpeed = 0,
        maxMotorTorque = 0,
        motorEnabled = false,
        motorImpulse = 0
    }
end

function createPrismaticJoint(bodyA, bodyB, anchorA, anchorB, axis)
    return {
        type = "prismatic",
        bodyA = bodyA,
        bodyB = bodyB,
        localAnchorA = anchorA,
        localAnchorB = anchorB,
        localAxis = axis,
        impulse = 0,
        motorSpeed = 0,
        maxMotorForce = 0,
        motorEnabled = false
    }
end

function solveDistanceJoint(joint, dt)
    bodyA = joint.bodyA
    bodyB = joint.bodyB

    worldAnchorA = vecAdd(bodyA.position, vecRotate(joint.localAnchorA, bodyA.angle))
    worldAnchorB = vecAdd(bodyB.position, vecRotate(joint.localAnchorB, bodyB.angle))

    delta = vecSub(worldAnchorB, worldAnchorA)
    currentDist = vecLen(delta)
    if currentDist < 1e-10 then return end

    direction = vecDiv(delta, currentDist)
    error = currentDist - joint.targetDistance

    rA = vecSub(worldAnchorA, bodyA.position)
    rB = vecSub(worldAnchorB, bodyB.position)

    rnA = vecCross(rA, direction)
    rnB = vecCross(rB, direction)
    invEffectiveMass = bodyA.invMass + bodyB.invMass +
                             bodyA.invInertia * rnA * rnA +
                             bodyB.invInertia * rnB * rnB

    relVel = vecSub(
        vecAdd(bodyB.velocity, scalarCrossVec(bodyB.angularVelocity, rB)),
        vecAdd(bodyA.velocity, scalarCrossVec(bodyA.angularVelocity, rA))
    )
    velAlongDir = vecDot(relVel, direction)

    springForce = -joint.stiffness * error
    dampingForce = -joint.damping * velAlongDir
    lambda = (springForce + dampingForce) * dt / invEffectiveMass

    impulse = vecMul(direction, lambda)
    bodyApplyImpulse(bodyA, vecNeg(impulse), worldAnchorA)
    bodyApplyImpulse(bodyB, impulse, worldAnchorB)
end

function solveRevoluteJoint(joint, dt)
    bodyA = joint.bodyA
    bodyB = joint.bodyB

    worldAnchorA = vecAdd(bodyA.position, vecRotate(joint.localAnchorA, bodyA.angle))
    worldAnchorB = vecAdd(bodyB.position, vecRotate(joint.localAnchorB, bodyB.angle))

    rA = vecSub(worldAnchorA, bodyA.position)
    rB = vecSub(worldAnchorB, bodyB.position)

    error = vecSub(worldAnchorB, worldAnchorA)
    baumgarte = 0.2
    correction = vecMul(error, baumgarte / dt)

    relVel = vecSub(
        vecAdd(bodyB.velocity, scalarCrossVec(bodyB.angularVelocity, rB)),
        vecAdd(bodyA.velocity, scalarCrossVec(bodyA.angularVelocity, rA))
    )

    Cdot = vecAdd(relVel, correction)

    k11 = bodyA.invMass + bodyB.invMass +
                bodyA.invInertia * rA.y * rA.y + bodyB.invInertia * rB.y * rB.y
    k12 = -(bodyA.invInertia * rA.x * rA.y + bodyB.invInertia * rB.x * rB.y)
    k22 = bodyA.invMass + bodyB.invMass +
                bodyA.invInertia * rA.x * rA.x + bodyB.invInertia * rB.x * rB.x

    det = k11 * k22 - k12 * k12
    if M.abs(det) < 1e-10 then return end
    invDet = 1 / det

    lambda = vec(
        -(k22 * Cdot.x - k12 * Cdot.y) * invDet,
        -(k11 * Cdot.y - k12 * Cdot.x) * invDet
    )

    bodyA.velocity = vecSub(bodyA.velocity, vecMul(lambda, bodyA.invMass))
    bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * vecCross(rA, lambda)
    bodyB.velocity = vecAdd(bodyB.velocity, vecMul(lambda, bodyB.invMass))
    bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * vecCross(rB, lambda)

    if joint.motorEnabled then
        Cdot_motor = bodyB.angularVelocity - bodyA.angularVelocity - joint.motorSpeed
        motorMass = bodyA.invInertia + bodyB.invInertia
        if motorMass > 0 then
            motorLambda = -Cdot_motor / motorMass
            oldImpulse = joint.motorImpulse
            joint.motorImpulse = M.max(-joint.maxMotorTorque * dt,
                                          M.min(oldImpulse + motorLambda, joint.maxMotorTorque * dt))
            motorLambda = joint.motorImpulse - oldImpulse
            bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * motorLambda
            bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * motorLambda
        end
    end
end

function solvePrismaticJoint(joint, dt)
    bodyA = joint.bodyA
    bodyB = joint.bodyB

    worldAnchorA = vecAdd(bodyA.position, vecRotate(joint.localAnchorA, bodyA.angle))
    worldAnchorB = vecAdd(bodyB.position, vecRotate(joint.localAnchorB, bodyB.angle))
    worldAxis = vecRotate(joint.localAxis, bodyA.angle)
    perpAxis = vecPerp(worldAxis)

    rA = vecSub(worldAnchorA, bodyA.position)
    rB = vecSub(worldAnchorB, bodyB.position)

    delta = vecSub(worldAnchorB, worldAnchorA)
    perpError = vecDot(delta, perpAxis)

    relVel = vecSub(
        vecAdd(bodyB.velocity, scalarCrossVec(bodyB.angularVelocity, rB)),
        vecAdd(bodyA.velocity, scalarCrossVec(bodyA.angularVelocity, rA))
    )
    perpVel = vecDot(relVel, perpAxis)

    baumgarte = 0.2
    bias = baumgarte / dt * perpError

    rpA = vecCross(rA, perpAxis)
    rpB = vecCross(rB, perpAxis)
    effectiveMass = bodyA.invMass + bodyB.invMass +
                          bodyA.invInertia * rpA * rpA +
                          bodyB.invInertia * rpB * rpB

    if effectiveMass < 1e-10 then return end

    lambda = -(perpVel + bias) / effectiveMass

    impulse = vecMul(perpAxis, lambda)
    bodyA.velocity = vecSub(bodyA.velocity, vecMul(impulse, bodyA.invMass))
    bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * vecCross(rA, impulse)
    bodyB.velocity = vecAdd(bodyB.velocity, vecMul(impulse, bodyB.invMass))
    bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * vecCross(rB, impulse)
end

function solveJoint(joint, dt)
    if joint.type == "distance" then
        solveDistanceJoint(joint, dt)
    else if joint.type == "revolute" then
        solveRevoluteJoint(joint, dt)
    else if joint.type == "prismatic" then
        solvePrismaticJoint(joint, dt)
    end
end

-- ============================================================================
-- World
-- ============================================================================

function createWorld(gravity, cellSize)
    return {
        bodies = {},
        joints = {},
        gravity = gravity or vec(0, -9.81),
        spatialHash = createSpatialHash(cellSize or 2.0),
        manifolds = {},
        iterations = 10,
        dt = 1 / 60
    }
end

function worldAddBody(world, body)
    world.bodies[#world.bodies + 1] = body
    return body
end

function worldAddJoint(world, joint)
    world.joints[#world.joints + 1] = joint
    return joint
end

function worldStep(world, dt)
    dt = dt or world.dt
    bodies = world.bodies
    gravity = world.gravity

    for i = 1, #bodies do
        body = bodies[i]
        if not body.isStatic then
            gravForce = vecMul(gravity, body.mass * body.gravityScale)
            body.velocity = vecAdd(body.velocity, vecMul(vecAdd(body.force, gravForce), body.invMass * dt))
            body.angularVelocity = body.angularVelocity + body.torque * body.invInertia * dt
            body.velocity = vecMul(body.velocity, 1 / (1 + body.linearDamping * dt))
            body.angularVelocity = body.angularVelocity / (1 + body.angularDamping * dt)
        end
        body.force = vec(0, 0)
        body.torque = 0
    end

    pairs = spatialHashFindPairs(world.spatialHash, bodies)

    manifolds = {}
    for i = 1, #pairs do
        pair = pairs[i]
        if aabbOverlap(pair.a, pair.b) then
            manifold = detectCollision(pair.a, pair.b)
            if manifold then
                manifolds[#manifolds + 1] = manifold
            end
        end
    end

    for i = 1, #manifolds do
        preSolveContact(manifolds[i], dt)
    end

    for iter = 1, world.iterations do
        for i = 1, #manifolds do
            solveContact(manifolds[i])
        end
        for i = 1, #world.joints do
            solveJoint(world.joints[i], dt)
        end
    end

    for i = 1, #bodies do
        body = bodies[i]
        if not body.isStatic then
            body.position = vecAdd(body.position, vecMul(body.velocity, dt))
            body.angle = body.angle + body.angularVelocity * dt
        end
    end

    world.manifolds = manifolds
end

-- ============================================================================
-- Ray casting
-- ============================================================================

function raycastCircle(origin, direction, maxDist, body)
    center = body.position
    radius = body.shape.radius
    oc = vecSub(origin, center)
    a = vecDot(direction, direction)
    b = 2 * vecDot(oc, direction)
    c = vecDot(oc, oc) - radius * radius
    discriminant = b * b - 4 * a * c
    if discriminant < 0 then return null end
    sqrtD = M.sqrt(discriminant)
    t = (-b - sqrtD) / (2 * a)
    if t < 0 then t = (-b + sqrtD) / (2 * a) end
    if t < 0 or t > maxDist then return null end
    point = vecAdd(origin, vecMul(direction, t))
    normal = vecNormalize(vecSub(point, center))
    return {t = t, point = point, normal = normal, body = body}
end

function raycastPolygon(origin, direction, maxDist, body)
    verts = bodyGetTransformedVertices(body)
    n = #verts
    tMin = maxDist
    hitNormal = null
    hit = false

    for i = 1, n do
        j = (i % n) + 1
        edgeStart = verts[i]
        edgeEnd = verts[j]
        edge = vecSub(edgeEnd, edgeStart)
        denom = direction.x * edge.y - direction.y * edge.x
        if M.abs(denom) > 1e-10 then
            toStart = vecSub(edgeStart, origin)
            t = (toStart.x * edge.y - toStart.y * edge.x) / denom
            u = (toStart.x * direction.y - toStart.y * direction.x) / denom
            if t >= 0 and t < tMin and u >= 0 and u <= 1 then
                tMin = t
                hitNormal = vecNormalize(vecPerp(edge))
                if vecDot(hitNormal, direction) > 0 then
                    hitNormal = vecNeg(hitNormal)
                end
                hit = true
            end
        end
    end

    if not hit then return null end
    point = vecAdd(origin, vecMul(direction, tMin))
    return {t = tMin, point = point, normal = hitNormal, body = body}
end

function worldRaycast(world, origin, direction, maxDist)
    maxDist = maxDist or 1000
    closest = null
    for i = 1, #world.bodies do
        body = world.bodies[i]
        result = null
        if body.shape.type == SHAPE_CIRCLE then
            result = raycastCircle(origin, direction, maxDist, body)
        else
            result = raycastPolygon(origin, direction, maxDist, body)
        end
        if result then
            if not closest or result.t < closest.t then
                closest = result
            end
        end
    end
    return closest
end

function worldRaycastAll(world, origin, direction, maxDist)
    maxDist = maxDist or 1000
    results = {}
    for i = 1, #world.bodies do
        body = world.bodies[i]
        result = null
        if body.shape.type == SHAPE_CIRCLE then
            result = raycastCircle(origin, direction, maxDist, body)
        else
            result = raycastPolygon(origin, direction, maxDist, body)
        end
        if result then
            results[#results + 1] = result
        end
    end
    table.sort(results, function(a, b) return a.t < b.t end)
    return results
end

-- ============================================================================
-- Continuous Collision Detection (TOI - Time of Impact)
-- ============================================================================

function computeTOI(bodyA, bodyB, dt)
    relVel = vecSub(bodyB.velocity, bodyA.velocity)
    relSpeed = vecLen(relVel)
    if relSpeed < 1e-6 then return 1.0 end

    maxIterations = 8
    toi = 1.0
    tLo = 0
    tHi = 1.0

    for iter = 1, maxIterations do
        tMid = (tLo + tHi) / 2
        posA = vecAdd(bodyA.position, vecMul(bodyA.velocity, tMid * dt))
        posB = vecAdd(bodyB.position, vecMul(bodyB.velocity, tMid * dt))

        dist = null
        if bodyA.shape.type == SHAPE_CIRCLE and bodyB.shape.type == SHAPE_CIRCLE then
            dist = vecDist(posA, posB) - bodyA.shape.radius - bodyB.shape.radius
        else
            dist = 0
            tempA = {position = posA, angle = bodyA.angle + bodyA.angularVelocity * tMid * dt,
                          shape = bodyA.shape, id = bodyA.id}
            tempB = {position = posB, angle = bodyB.angle + bodyB.angularVelocity * tMid * dt,
                          shape = bodyB.shape, id = bodyB.id}
            aabbA = bodyGetAABB(tempA)
            aabbB = bodyGetAABB(tempB)
            overlapX = M.min(aabbA.maxX, aabbB.maxX) - M.max(aabbA.minX, aabbB.minX)
            overlapY = M.min(aabbA.maxY, aabbB.maxY) - M.max(aabbA.minY, aabbB.minY)
            if overlapX > 0 and overlapY > 0 then
                dist = -M.min(overlapX, overlapY)
            else
                dist = M.max(-overlapX, -overlapY)
            end
        end

        if dist < 0.001 then
            tHi = tMid
            toi = tMid
        else
            tLo = tMid
        end

        if tHi - tLo < 0.001 then break end
    end

    return toi
end

-- ============================================================================
-- Island Solver and Sleeping
-- ============================================================================


function bodyCanSleep(body)
    if body.isStatic then return true end
    linSpeed = vecLen(body.velocity)
    angSpeed = M.abs(body.angularVelocity)
    return linSpeed < 0.1 and angSpeed < 0.05
end

function buildIslands(bodies, manifolds)
    visited = {}
    islands = {}
    bodyToManifolds = {}

    for i = 1, #manifolds do
        m = manifolds[i]
        idA = m.bodyA.id
        idB = m.bodyB.id
        if not bodyToManifolds[idA] then bodyToManifolds[idA] = {} end
        if not bodyToManifolds[idB] then bodyToManifolds[idB] = {} end
        bodyToManifolds[idA][#bodyToManifolds[idA] + 1] = m
        bodyToManifolds[idB][#bodyToManifolds[idB] + 1] = m
    end

    for i = 1, #bodies do
        startBody = bodies[i]
        if not visited[startBody.id] and not startBody.isStatic then
            island = {bodies = {}, manifolds = {}}
            stack = {startBody}
            visited[startBody.id] = true

            while #stack > 0 do
                body = stack[#stack]
                stack[#stack] = null
                island.bodies[#island.bodies + 1] = body

                ms = bodyToManifolds[body.id]
                if ms then
                    for j = 1, #ms do
                        m = ms[j]
                        seenManifold = false
                        for k = 1, #island.manifolds do
                            if island.manifolds[k] == m then seenManifold = true; break end
                        end
                        if not seenManifold then
                            island.manifolds[#island.manifolds + 1] = m
                        end
                        other = null
                        if m.bodyA.id == body.id then other = m.bodyB else other = m.bodyA end
                        if not visited[other.id] and not other.isStatic then
                            visited[other.id] = true
                            stack[#stack + 1] = other
                        end
                    end
                end
            end

            islands[#islands + 1] = island
        end
    end

    return islands
end

-- ============================================================================
-- Weld Joint (locks two bodies together)
-- ============================================================================

function createWeldJoint(bodyA, bodyB, anchorA, anchorB)
    referenceAngle = bodyB.angle - bodyA.angle
    return {
        type = "weld",
        bodyA = bodyA,
        bodyB = bodyB,
        localAnchorA = anchorA,
        localAnchorB = anchorB,
        referenceAngle = referenceAngle,
        impulse = vec(0, 0),
        angularImpulse = 0,
        stiffness = 0,
        damping = 0
    }
end

function solveWeldJoint(joint, dt)
    bodyA = joint.bodyA
    bodyB = joint.bodyB

    worldAnchorA = vecAdd(bodyA.position, vecRotate(joint.localAnchorA, bodyA.angle))
    worldAnchorB = vecAdd(bodyB.position, vecRotate(joint.localAnchorB, bodyB.angle))

    rA = vecSub(worldAnchorA, bodyA.position)
    rB = vecSub(worldAnchorB, bodyB.position)

    posError = vecSub(worldAnchorB, worldAnchorA)
    angError = bodyB.angle - bodyA.angle - joint.referenceAngle

    baumgarte = 0.3
    posCorrection = vecMul(posError, baumgarte / dt)
    angCorrection = angError * baumgarte / dt

    relVel = vecSub(
        vecAdd(bodyB.velocity, scalarCrossVec(bodyB.angularVelocity, rB)),
        vecAdd(bodyA.velocity, scalarCrossVec(bodyA.angularVelocity, rA))
    )

    Cdot = vecAdd(relVel, posCorrection)

    k11 = bodyA.invMass + bodyB.invMass +
                bodyA.invInertia * rA.y * rA.y + bodyB.invInertia * rB.y * rB.y
    k12 = -(bodyA.invInertia * rA.x * rA.y + bodyB.invInertia * rB.x * rB.y)
    k22 = bodyA.invMass + bodyB.invMass +
                bodyA.invInertia * rA.x * rA.x + bodyB.invInertia * rB.x * rB.x

    det = k11 * k22 - k12 * k12
    if M.abs(det) < 1e-10 then return end
    invDet = 1 / det

    lambda = vec(
        -(k22 * Cdot.x - k12 * Cdot.y) * invDet,
        -(k11 * Cdot.y - k12 * Cdot.x) * invDet
    )

    bodyA.velocity = vecSub(bodyA.velocity, vecMul(lambda, bodyA.invMass))
    bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * vecCross(rA, lambda)
    bodyB.velocity = vecAdd(bodyB.velocity, vecMul(lambda, bodyB.invMass))
    bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * vecCross(rB, lambda)

    angMass = bodyA.invInertia + bodyB.invInertia
    if angMass > 0 then
        relAngVel = bodyB.angularVelocity - bodyA.angularVelocity
        angLambda = -(relAngVel + angCorrection) / angMass
        bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * angLambda
        bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * angLambda
    end
end

-- ============================================================================
-- Rope Joint (max distance constraint)
-- ============================================================================

function createRopeJoint(bodyA, bodyB, anchorA, anchorB, maxLength)
    return {
        type = "rope",
        bodyA = bodyA,
        bodyB = bodyB,
        localAnchorA = anchorA,
        localAnchorB = anchorB,
        maxLength = maxLength,
        impulse = 0
    }
end

function solveRopeJoint(joint, dt)
    bodyA = joint.bodyA
    bodyB = joint.bodyB

    worldAnchorA = vecAdd(bodyA.position, vecRotate(joint.localAnchorA, bodyA.angle))
    worldAnchorB = vecAdd(bodyB.position, vecRotate(joint.localAnchorB, bodyB.angle))

    delta = vecSub(worldAnchorB, worldAnchorA)
    currentDist = vecLen(delta)
    if currentDist <= joint.maxLength then return end
    if currentDist < 1e-10 then return end

    direction = vecDiv(delta, currentDist)
    error = currentDist - joint.maxLength

    rA = vecSub(worldAnchorA, bodyA.position)
    rB = vecSub(worldAnchorB, bodyB.position)

    rnA = vecCross(rA, direction)
    rnB = vecCross(rB, direction)
    invEffectiveMass = bodyA.invMass + bodyB.invMass +
                             bodyA.invInertia * rnA * rnA +
                             bodyB.invInertia * rnB * rnB

    if invEffectiveMass < 1e-10 then return end

    relVel = vecSub(
        vecAdd(bodyB.velocity, scalarCrossVec(bodyB.angularVelocity, rB)),
        vecAdd(bodyA.velocity, scalarCrossVec(bodyA.angularVelocity, rA))
    )
    velAlongDir = vecDot(relVel, direction)

    baumgarte = 0.3
    bias = baumgarte / dt * error
    lambda = -(velAlongDir + bias) / invEffectiveMass

    oldImpulse = joint.impulse
    joint.impulse = M.max(0, oldImpulse + lambda)
    lambda = joint.impulse - oldImpulse

    impulse = vecMul(direction, lambda)
    bodyApplyImpulse(bodyA, vecNeg(impulse), worldAnchorA)
    bodyApplyImpulse(bodyB, impulse, worldAnchorB)
end

-- ============================================================================
-- Wheel Joint (spring + revolute, for vehicles)
-- ============================================================================

function createWheelJoint(bodyA, bodyB, anchorA, anchorB, axis)
    return {
        type = "wheel",
        bodyA = bodyA,
        bodyB = bodyB,
        localAnchorA = anchorA,
        localAnchorB = anchorB,
        localAxis = axis,
        springStiffness = 50.0,
        springDamping = 5.0,
        motorSpeed = 0,
        maxMotorTorque = 0,
        motorEnabled = false,
        springImpulse = 0,
        motorImpulse = 0
    }
end

function solveWheelJoint(joint, dt)
    bodyA = joint.bodyA
    bodyB = joint.bodyB

    worldAnchorA = vecAdd(bodyA.position, vecRotate(joint.localAnchorA, bodyA.angle))
    worldAnchorB = vecAdd(bodyB.position, vecRotate(joint.localAnchorB, bodyB.angle))
    worldAxis = vecRotate(joint.localAxis, bodyA.angle)
    perpAxis = vecPerp(worldAxis)

    rA = vecSub(worldAnchorA, bodyA.position)
    rB = vecSub(worldAnchorB, bodyB.position)

    delta = vecSub(worldAnchorB, worldAnchorA)
    springError = vecDot(delta, worldAxis)

    relVel = vecSub(
        vecAdd(bodyB.velocity, scalarCrossVec(bodyB.angularVelocity, rB)),
        vecAdd(bodyA.velocity, scalarCrossVec(bodyA.angularVelocity, rA))
    )
    springVel = vecDot(relVel, worldAxis)

    raAxis = vecCross(rA, worldAxis)
    rbAxis = vecCross(rB, worldAxis)
    springMass = bodyA.invMass + bodyB.invMass +
                       bodyA.invInertia * raAxis * raAxis +
                       bodyB.invInertia * rbAxis * rbAxis

    if springMass > 1e-10 then
        springForce = -joint.springStiffness * springError - joint.springDamping * springVel
        lambda = springForce * dt / springMass
        impulse = vecMul(worldAxis, lambda)
        bodyA.velocity = vecSub(bodyA.velocity, vecMul(impulse, bodyA.invMass))
        bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * vecCross(rA, impulse)
        bodyB.velocity = vecAdd(bodyB.velocity, vecMul(impulse, bodyB.invMass))
        bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * vecCross(rB, impulse)
    end

    perpError = vecDot(delta, perpAxis)
    perpVel = vecDot(relVel, perpAxis)
    raPerp = vecCross(rA, perpAxis)
    rbPerp = vecCross(rB, perpAxis)
    perpMass = bodyA.invMass + bodyB.invMass +
                     bodyA.invInertia * raPerp * raPerp +
                     bodyB.invInertia * rbPerp * rbPerp

    if perpMass > 1e-10 then
        bias = 0.2 / dt * perpError
        lambda = -(perpVel + bias) / perpMass
        impulse = vecMul(perpAxis, lambda)
        bodyA.velocity = vecSub(bodyA.velocity, vecMul(impulse, bodyA.invMass))
        bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * vecCross(rA, impulse)
        bodyB.velocity = vecAdd(bodyB.velocity, vecMul(impulse, bodyB.invMass))
        bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * vecCross(rB, impulse)
    end

    if joint.motorEnabled then
        motorMass = bodyA.invInertia + bodyB.invInertia
        if motorMass > 0 then
            Cdot = bodyB.angularVelocity - bodyA.angularVelocity - joint.motorSpeed
            motorLambda = -Cdot / motorMass
            oldImpulse = joint.motorImpulse
            joint.motorImpulse = M.max(-joint.maxMotorTorque * dt,
                                          M.min(oldImpulse + motorLambda, joint.maxMotorTorque * dt))
            motorLambda = joint.motorImpulse - oldImpulse
            bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * motorLambda
            bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * motorLambda
        end
    end
end

-- ============================================================================
-- Gear Joint (couples two revolute joints)
-- ============================================================================

function createGearJoint(jointA, jointB, ratio)
    return {
        type = "gear",
        jointA = jointA,
        jointB = jointB,
        bodyA = jointA.bodyB,
        bodyB = jointB.bodyB,
        bodyGround = jointA.bodyA,
        ratio = ratio,
        impulse = 0
    }
end

function solveGearJoint(joint, dt)
    bodyA = joint.bodyA
    bodyB = joint.bodyB
    ratio = joint.ratio

    angVelA = bodyA.angularVelocity
    angVelB = bodyB.angularVelocity
    Cdot = angVelA + ratio * angVelB

    mass = bodyA.invInertia + ratio * ratio * bodyB.invInertia
    if mass < 1e-10 then return end

    lambda = -Cdot / mass
    joint.impulse = joint.impulse + lambda

    bodyA.angularVelocity = bodyA.angularVelocity + bodyA.invInertia * lambda
    bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * lambda * ratio
end

-- ============================================================================
-- Convex Hull computation (Andrew's monotone chain)
-- ============================================================================

function computeConvexHull(points)
    n = #points
    if n < 3 then return points end

    table.sort(points, function(a, b)
        if a.x == b.x then return a.y < b.y end
        return a.x < b.x
    end)

    hull = {}
    k = 0

    for i = 1, n do
        while k >= 2 and vecCross(vecSub(hull[k], hull[k-1]), vecSub(points[i], hull[k-1])) <= 0 do
            k = k - 1
        end
        k = k + 1
        hull[k] = points[i]
    end

    lower = k + 1
    for i = n - 1, 1, -1 do
        while k >= lower and vecCross(vecSub(hull[k], hull[k-1]), vecSub(points[i], hull[k-1])) <= 0 do
            k = k - 1
        end
        k = k + 1
        hull[k] = points[i]
    end

    result = {}
    for i = 1, k - 1 do
        result[i] = hull[i]
    end
    return result
end

-- ============================================================================
-- Minkowski Difference support (for GJK-like queries)
-- ============================================================================

function support(shape, position, angle, direction)
    if shape.type == SHAPE_CIRCLE then
        norm = vecNormalize(direction)
        return vecAdd(position, vecMul(norm, shape.radius))
    else
        rot = mat2(angle)
        invRot = mat2Transpose(rot)
        localDir = mat2MulVec(invRot, direction)
        best = shape.vertices[1]
        bestDot = vecDot(best, localDir)
        for i = 2, shape.vertexCount do
            d = vecDot(shape.vertices[i], localDir)
            if d > bestDot then
                bestDot = d
                best = shape.vertices[i]
            end
        end
        return vecAdd(mat2MulVec(rot, best), position)
    end
end

function minkowskiSupport(bodyA, bodyB, direction)
    pointA = support(bodyA.shape, bodyA.position, bodyA.angle, direction)
    pointB = support(bodyB.shape, bodyB.position, bodyB.angle, vecNeg(direction))
    return vecSub(pointA, pointB)
end

-- ============================================================================
-- Point-in-shape queries
-- ============================================================================

function pointInCircle(point, body)
    dist = vecDist(point, body.position)
    return dist <= body.shape.radius
end

function pointInPolygon(point, body)
    verts = bodyGetTransformedVertices(body)
    n = #verts
    for i = 1, n do
        j = (i % n) + 1
        edge = vecSub(verts[j], verts[i])
        toPoint = vecSub(point, verts[i])
        if vecCross(edge, toPoint) < 0 then
            return false
        end
    end
    return true
end

function pointInBody(point, body)
    if body.shape.type == SHAPE_CIRCLE then
        return pointInCircle(point, body)
    else
        return pointInPolygon(point, body)
    end
end

function worldQueryPoint(world, point)
    results = {}
    for i = 1, #world.bodies do
        if pointInBody(point, world.bodies[i]) then
            results[#results + 1] = world.bodies[i]
        end
    end
    return results
end

-- ============================================================================
-- AABB query
-- ============================================================================

function worldQueryAABB(world, queryAABB)
    results = {}
    for i = 1, #world.bodies do
        bodyAABB = bodyGetAABB(world.bodies[i])
        if bodyAABB.maxX >= queryAABB.minX and bodyAABB.minX <= queryAABB.maxX and
           bodyAABB.maxY >= queryAABB.minY and bodyAABB.minY <= queryAABB.maxY then
            results[#results + 1] = world.bodies[i]
        end
    end
    return results
end

-- ============================================================================
-- Distance computation between shapes
-- ============================================================================

function closestPointOnSegment(point, segStart, segEnd)
    seg = vecSub(segEnd, segStart)
    t = vecDot(vecSub(point, segStart), seg) / vecDot(seg, seg)
    t = M.max(0, M.min(1, t))
    return vecAdd(segStart, vecMul(seg, t))
end

function distancePointToPolygon(point, body)
    verts = bodyGetTransformedVertices(body)
    n = #verts
    minDist = M.huge
    for i = 1, n do
        j = (i % n) + 1
        closest = closestPointOnSegment(point, verts[i], verts[j])
        dist = vecDist(point, closest)
        if dist < minDist then minDist = dist end
    end
    return minDist
end

function distanceBetweenBodies(bodyA, bodyB)
    if bodyA.shape.type == SHAPE_CIRCLE and bodyB.shape.type == SHAPE_CIRCLE then
        d = vecDist(bodyA.position, bodyB.position) - bodyA.shape.radius - bodyB.shape.radius
        return M.max(0, d)
    else if bodyA.shape.type == SHAPE_CIRCLE then
        d = distancePointToPolygon(bodyA.position, bodyB) - bodyA.shape.radius
        return M.max(0, d)
    else if bodyB.shape.type == SHAPE_CIRCLE then
        d = distancePointToPolygon(bodyB.position, bodyA) - bodyB.shape.radius
        return M.max(0, d)
    else
        vertsA = bodyGetTransformedVertices(bodyA)
        vertsB = bodyGetTransformedVertices(bodyB)
        minDist = M.huge
        for i = 1, #vertsA do
            for j = 1, #vertsB do
                nB = #vertsB
                j2 = (j % nB) + 1
                closest = closestPointOnSegment(vertsA[i], vertsB[j], vertsB[j2])
                d = vecDist(vertsA[i], closest)
                if d < minDist then minDist = d end
            end
        end
        for i = 1, #vertsB do
            for j = 1, #vertsA do
                nA = #vertsA
                j2 = (j % nA) + 1
                closest = closestPointOnSegment(vertsB[i], vertsA[j], vertsA[j2])
                d = vecDist(vertsB[i], closest)
                if d < minDist then minDist = d end
            end
        end
        return minDist
    end
end

-- ============================================================================
-- Extended World step with joints
-- ============================================================================

function solveJointExtended(joint, dt)
    if joint.type == "distance" then
        solveDistanceJoint(joint, dt)
    else if joint.type == "revolute" then
        solveRevoluteJoint(joint, dt)
    else if joint.type == "prismatic" then
        solvePrismaticJoint(joint, dt)
    else if joint.type == "weld" then
        solveWeldJoint(joint, dt)
    else if joint.type == "rope" then
        solveRopeJoint(joint, dt)
    else if joint.type == "wheel" then
        solveWheelJoint(joint, dt)
    else if joint.type == "gear" then
        solveGearJoint(joint, dt)
    end
end

function worldStepExtended(world, dt)
    dt = dt or world.dt
    bodies = world.bodies
    gravity = world.gravity

    for i = 1, #bodies do
        body = bodies[i]
        if not body.isStatic then
            gravForce = vecMul(gravity, body.mass * body.gravityScale)
            body.velocity = vecAdd(body.velocity, vecMul(vecAdd(body.force, gravForce), body.invMass * dt))
            body.angularVelocity = body.angularVelocity + body.torque * body.invInertia * dt
            body.velocity = vecMul(body.velocity, 1 / (1 + body.linearDamping * dt))
            body.angularVelocity = body.angularVelocity / (1 + body.angularDamping * dt)
        end
        body.force = vec(0, 0)
        body.torque = 0
    end

    bpPairs = spatialHashFindPairs(world.spatialHash, bodies)

    manifolds = {}
    for i = 1, #bpPairs do
        pair = bpPairs[i]
        if aabbOverlap(pair.a, pair.b) then
            manifold = detectCollision(pair.a, pair.b)
            if manifold then
                manifolds[#manifolds + 1] = manifold
            end
        end
    end

    for i = 1, #manifolds do
        preSolveContact(manifolds[i], dt)
    end

    for iter = 1, world.iterations do
        for i = 1, #manifolds do
            solveContact(manifolds[i])
        end
        for i = 1, #world.joints do
            solveJointExtended(world.joints[i], dt)
        end
    end

    for i = 1, #bodies do
        body = bodies[i]
        if not body.isStatic then
            body.position = vecAdd(body.position, vecMul(body.velocity, dt))
            body.angle = body.angle + body.angularVelocity * dt
        end
    end

    world.manifolds = manifolds
end

-- ============================================================================
-- Scenario 1: Box Stack (tests resting contacts and friction)
-- ============================================================================

function createBoxStackScenario()
    world = createWorld(vec(0, -20), 3.0)

    ground = createBody(createBox(50, 1), 0, -1, 1, true)
    ground.restitution = 0.0
    worldAddBody(world, ground)

    wallLeft = createBody(createBox(1, 30), -15, 15, 1, true)
    worldAddBody(world, wallLeft)
    wallRight = createBody(createBox(1, 30), 15, 15, 1, true)
    worldAddBody(world, wallRight)

    for row = 0, 9 do
        numBoxes = 10 - row
        startX = -(numBoxes - 1) * 1.1 / 2
        for col = 0, numBoxes - 1 do
            x = startX + col * 1.1
            y = 0.5 + row * 1.05
            box = createBody(createBox(0.5, 0.5), x, y, 2.0, false)
            box.restitution = 0.0
            box.staticFriction = 0.7
            box.dynamicFriction = 0.5
            worldAddBody(world, box)
        end
    end

    return world
end

-- ============================================================================
-- Scenario 2: Pendulum Chain (tests revolute joints)
-- ============================================================================

function createPendulumScenario()
    world = createWorld(vec(0, -10), 4.0)

    anchor = createBody(createCircle(0.3), 0, 15, 1, true)
    worldAddBody(world, anchor)

    numLinks = 12
    linkLength = 1.5
    prevBody = anchor

    for i = 1, numLinks do
        x = i * linkLength
        y = 15
        link = createBody(createBox(0.6, 0.2), x, y, 3.0, false)
        link.restitution = 0.1
        link.angularDamping = 0.05
        worldAddBody(world, link)

        jointAnchorA = vec(0.3, 0)
        jointAnchorB = vec(-0.3, 0)
        if i == 1 then
            jointAnchorA = vec(0, 0)
        end
        joint = createRevoluteJoint(prevBody, link, jointAnchorA, jointAnchorB)
        worldAddJoint(world, joint)

        prevBody = link
    end

    ball = createBody(createCircle(1.0), numLinks * linkLength + 1.5, 15, 5.0, false)
    ball.restitution = 0.5
    worldAddBody(world, ball)
    lastJoint = createRevoluteJoint(prevBody, ball, vec(0.3, 0), vec(-0.5, 0))
    worldAddJoint(world, lastJoint)

    for i = 1, numLinks + 2 do
        body = world.bodies[i + 1]
        if body and not body.isStatic then
            body.velocity = vec(0, -5)
        end
    end

    return world
end

-- ============================================================================
-- Scenario 3: Ball Pit (tests broad-phase with many circles)
-- ============================================================================

function createBallPitScenario()
    world = createWorld(vec(0, -15), 2.0)

    floor = createBody(createBox(20, 1), 0, -1, 1, true)
    floor.restitution = 0.4
    worldAddBody(world, floor)

    leftWall = createBody(createBox(1, 15), -11, 7, 1, true)
    leftWall.restitution = 0.4
    worldAddBody(world, leftWall)
    rightWall = createBody(createBox(1, 15), 11, 7, 1, true)
    rightWall.restitution = 0.4
    worldAddBody(world, rightWall)

    rampShape = createPolygon({
        vec(-5, -0.5), vec(5, 0.5), vec(5, -0.5)
    })
    ramp = createBody(rampShape, -3, 10, 1, true)
    worldAddBody(world, ramp)
    ramp2Shape = createPolygon({
        vec(-5, 0.5), vec(5, -0.5), vec(-5, -0.5)
    })
    ramp2 = createBody(ramp2Shape, 3, 6, 1, true)
    worldAddBody(world, ramp2)

    resetRandom()
    for i = 1, 80 do
        radius = randomRange(0.3, 0.8)
        x = randomRange(-8, 8)
        y = randomRange(12, 30)
        ball = createBody(createCircle(radius), x, y, 1.5, false)
        ball.restitution = randomRange(0.3, 0.8)
        ball.dynamicFriction = randomRange(0.2, 0.5)
        worldAddBody(world, ball)
    end

    return world
end

-- ============================================================================
-- Scenario 4: Domino Chain (tests sequential collisions)
-- ============================================================================

function createDominoScenario()
    world = createWorld(vec(0, -10), 2.5)

    ground = createBody(createBox(40, 1), 0, -1, 1, true)
    ground.restitution = 0.0
    ground.staticFriction = 0.8
    worldAddBody(world, ground)

    numDominoes = 25
    spacing = 1.2
    startX = -(numDominoes * spacing) / 2

    for i = 0, numDominoes - 1 do
        x = startX + i * spacing
        domino = createBody(createBox(0.15, 1.0), x, 1.0, 4.0, false)
        domino.restitution = 0.0
        domino.staticFriction = 0.6
        domino.dynamicFriction = 0.4
        worldAddBody(world, domino)
    end

    pusher = createBody(createCircle(0.5), startX - 1.5, 1.5, 10.0, false)
    pusher.velocity = vec(8, 0)
    pusher.restitution = 0.0
    worldAddBody(world, pusher)

    rampX = startX + numDominoes * spacing + 2
    rampVerts = {
        vec(-2, 0), vec(2, 2), vec(2, 0)
    }
    rampBody = createBody(createPolygon(rampVerts), rampX, 0, 1, true)
    worldAddBody(world, rampBody)

    return world
end

-- ============================================================================
-- Scenario 5: Billiards (tests circle-circle collisions and rebounds)
-- ============================================================================

function createBilliardsScenario()
    world = createWorld(vec(0, 0), 3.0)
    world.gravity = vec(0, 0)

    tableW = 20
    tableH = 10
    cushionThickness = 0.5

    topCushion = createBody(createBox(tableW / 2 + cushionThickness, cushionThickness),
                                   0, tableH / 2 + cushionThickness, 1, true)
    topCushion.restitution = 0.85
    worldAddBody(world, topCushion)

    bottomCushion = createBody(createBox(tableW / 2 + cushionThickness, cushionThickness),
                                      0, -tableH / 2 - cushionThickness, 1, true)
    bottomCushion.restitution = 0.85
    worldAddBody(world, bottomCushion)

    leftCushion = createBody(createBox(cushionThickness, tableH / 2 + cushionThickness),
                                    -tableW / 2 - cushionThickness, 0, 1, true)
    leftCushion.restitution = 0.85
    worldAddBody(world, leftCushion)

    rightCushion = createBody(createBox(cushionThickness, tableH / 2 + cushionThickness),
                                     tableW / 2 + cushionThickness, 0, 1, true)
    rightCushion.restitution = 0.85
    worldAddBody(world, rightCushion)

    ballRadius = 0.4
    ballDensity = 2.0

    cueBall = createBody(createCircle(ballRadius), -6, 0, ballDensity, false)
    cueBall.restitution = 0.95
    cueBall.linearDamping = 0.3
    cueBall.dynamicFriction = 0.1
    cueBall.velocity = vec(15, 0.5)
    worldAddBody(world, cueBall)

    rackX = 4
    rackY = 0
    ballSpacing = ballRadius * 2.05
    row = 0
    col = 0
    ballCount = 0
    for r = 0, 4 do
        for c = 0, r do
            x = rackX + r * ballSpacing * 0.866
            y = rackY + (c - r / 2) * ballSpacing
            ball = createBody(createCircle(ballRadius), x, y, ballDensity, false)
            ball.restitution = 0.95
            ball.linearDamping = 0.3
            ball.dynamicFriction = 0.1
            worldAddBody(world, ball)
            ballCount = ballCount + 1
        end
    end

    return world
end

-- ============================================================================
-- Scenario 6: Mixed Shapes Tumbler (polygon variety + rotation)
-- ============================================================================

function createTumblerScenario()
    world = createWorld(vec(0, -10), 3.0)

    containerSize = 8
    wallThickness = 0.3

    bottom = createBody(createBox(containerSize, wallThickness), 0, -containerSize, 1, true)
    worldAddBody(world, bottom)
    top = createBody(createBox(containerSize, wallThickness), 0, containerSize, 1, true)
    worldAddBody(world, top)
    left = createBody(createBox(wallThickness, containerSize), -containerSize, 0, 1, true)
    worldAddBody(world, left)
    right = createBody(createBox(wallThickness, containerSize), containerSize, 0, 1, true)
    worldAddBody(world, right)

    resetRandom()
    shapes = {}
    for i = 1, 40 do
        shapeType = M.floor(random() * 4)
        x = randomRange(-6, 6)
        y = randomRange(-4, 6)
        body = null

        if shapeType == 0 then
            body = createBody(createCircle(randomRange(0.3, 0.7)), x, y, 2.0, false)
        else if shapeType == 1 then
            hw = randomRange(0.3, 0.8)
            hh = randomRange(0.3, 0.8)
            body = createBody(createBox(hw, hh), x, y, 2.0, false)
        else if shapeType == 2 then
            body = createBody(createRegularPolygon(randomRange(0.4, 0.7), 5), x, y, 2.0, false)
        else
            body = createBody(createRegularPolygon(randomRange(0.4, 0.7), 6), x, y, 2.0, false)
        end

        body.angle = randomRange(0, M.pi * 2)
        body.restitution = randomRange(0.1, 0.5)
        body.dynamicFriction = randomRange(0.3, 0.6)
        worldAddBody(world, body)
    end

    return world
end

-- ============================================================================
-- Scenario 7: Bridge with distance joints
-- ============================================================================

function createBridgeScenario()
    world = createWorld(vec(0, -10), 3.0)

    numSegments = 15
    segmentWidth = 1.2
    segmentHeight = 0.2
    bridgeY = 8
    bridgeStartX = -(numSegments * segmentWidth) / 2

    leftAnchor = createBody(createBox(1, 1), bridgeStartX - 1.5, bridgeY, 1, true)
    worldAddBody(world, leftAnchor)
    rightAnchor = createBody(createBox(1, 1), bridgeStartX + numSegments * segmentWidth + 1.5, bridgeY, 1, true)
    worldAddBody(world, rightAnchor)

    prevBody = leftAnchor
    segments = {}
    for i = 1, numSegments do
        x = bridgeStartX + (i - 0.5) * segmentWidth
        seg = createBody(createBox(segmentWidth / 2 - 0.05, segmentHeight), x, bridgeY, 3.0, false)
        seg.linearDamping = 0.1
        seg.angularDamping = 0.2
        worldAddBody(world, seg)
        segments[i] = seg

        joint = createDistanceJoint(prevBody, seg,
            vec(segmentWidth / 2, 0), vec(-segmentWidth / 2 + 0.05, 0),
            0.1)
        joint.stiffness = 200
        joint.damping = 10
        worldAddJoint(world, joint)
        prevBody = seg
    end

    lastJoint = createDistanceJoint(prevBody, rightAnchor,
        vec(segmentWidth / 2, 0), vec(-1, 0), 0.1)
    lastJoint.stiffness = 200
    lastJoint.damping = 10
    worldAddJoint(world, lastJoint)

    heavyBall = createBody(createCircle(0.8), 0, bridgeY + 5, 8.0, false)
    heavyBall.restitution = 0.2
    worldAddBody(world, heavyBall)

    ground = createBody(createBox(30, 1), 0, -1, 1, true)
    worldAddBody(world, ground)

    return world
end

-- ============================================================================
-- Scenario 8: Newton's Cradle (tests energy transfer)
-- ============================================================================

function createCradleScenario()
    world = createWorld(vec(0, -10), 2.0)

    numBalls = 7
    ballRadius = 0.5
    stringLength = 6
    spacing = ballRadius * 2.01
    anchorY = 12
    startX = -(numBalls - 1) * spacing / 2

    for i = 0, numBalls - 1 do
        x = startX + i * spacing
        ballY = anchorY - stringLength

        anchor = createBody(createCircle(0.1), x, anchorY, 1, true)
        worldAddBody(world, anchor)

        ball = createBody(createCircle(ballRadius), x, ballY, 8.0, false)
        ball.restitution = 0.99
        ball.linearDamping = 0.001
        ball.dynamicFriction = 0.01
        worldAddBody(world, ball)

        joint = createDistanceJoint(anchor, ball, vec(0, 0), vec(0, 0), stringLength)
        joint.stiffness = 500
        joint.damping = 2
        worldAddJoint(world, joint)
    end

    firstBall = world.bodies[3]
    firstBall.position = vec(startX - 3, anchorY - stringLength + 3)
    firstBall.velocity = vec(5, -3)

    return world
end

-- ============================================================================
-- Scenario 9: Vehicle on terrain (wheel joints + uneven ground)
-- ============================================================================

function createVehicleScenario()
    world = createWorld(vec(0, -10), 4.0)

    terrainPoints = {}
    terrainSegments = 40
    terrainWidth = 60
    segWidth = terrainWidth / terrainSegments
    resetRandom()

    height = 0
    for i = 0, terrainSegments do
        height = height + randomRange(-0.5, 0.5)
        if height < -3 then height = -3 end
        if height > 3 then height = 3 end
        terrainPoints[i + 1] = vec(-terrainWidth / 2 + i * segWidth, height)
    end

    for i = 1, terrainSegments do
        p1 = terrainPoints[i]
        p2 = terrainPoints[i + 1]
        midX = (p1.x + p2.x) / 2
        midY = (p1.y + p2.y) / 2
        dx = p2.x - p1.x
        dy = p2.y - p1.y
        len = M.sqrt(dx * dx + dy * dy)
        angle = M.atan2(dy, dx)

        seg = createBody(createBox(len / 2, 0.3), midX, midY - 0.3, 1, true)
        seg.angle = angle
        seg.restitution = 0.1
        seg.staticFriction = 0.9
        worldAddBody(world, seg)
    end

    chassisW = 2.5
    chassisH = 0.5
    chassis = createBody(createBox(chassisW, chassisH), -20, 4, 3.0, false)
    chassis.linearDamping = 0.05
    worldAddBody(world, chassis)

    wheelRadius = 0.6
    wheelDensity = 2.0
    frontWheel = createBody(createCircle(wheelRadius), -20 + chassisW - 0.3, 3, wheelDensity, false)
    frontWheel.dynamicFriction = 0.9
    frontWheel.restitution = 0.1
    worldAddBody(world, frontWheel)

    rearWheel = createBody(createCircle(wheelRadius), -20 - chassisW + 0.3, 3, wheelDensity, false)
    rearWheel.dynamicFriction = 0.9
    rearWheel.restitution = 0.1
    worldAddBody(world, rearWheel)

    frontJoint = createWheelJoint(chassis, frontWheel,
        vec(chassisW - 0.3, -chassisH), vec(0, 0), vec(0, 1))
    frontJoint.springStiffness = 80
    frontJoint.springDamping = 8
    worldAddJoint(world, frontJoint)

    rearJoint = createWheelJoint(chassis, rearWheel,
        vec(-chassisW + 0.3, -chassisH), vec(0, 0), vec(0, 1))
    rearJoint.springStiffness = 80
    rearJoint.springDamping = 8
    rearJoint.motorEnabled = true
    rearJoint.motorSpeed = -15
    rearJoint.maxMotorTorque = 50
    worldAddJoint(world, rearJoint)

    return world
end

-- ============================================================================
-- Scenario 10: Wrecking ball (rope joint + heavy ball + structure)
-- ============================================================================

function createWreckingBallScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(30, 1), 0, -1, 1, true)
    worldAddBody(world, ground)

    towerX = 5
    brickW = 0.8
    brickH = 0.4
    for row = 0, 7 do
        numBricks = 4
        for col = 0, numBricks - 1 do
            x = towerX + (col - (numBricks - 1) / 2) * (brickW * 2 + 0.05)
            y = 0.4 + row * (brickH * 2 + 0.02)
            brick = createBody(createBox(brickW, brickH), x, y, 2.0, false)
            brick.restitution = 0.0
            brick.staticFriction = 0.6
            worldAddBody(world, brick)
        end
    end

    craneX = -10
    craneY = 15
    anchor = createBody(createCircle(0.2), craneX, craneY, 1, true)
    worldAddBody(world, anchor)

    ropeLength = 12
    numRopeLinks = 8
    linkLen = ropeLength / numRopeLinks
    prevBody = anchor
    for i = 1, numRopeLinks do
        x = craneX
        y = craneY - i * linkLen
        link = createBody(createBox(0.15, linkLen / 2 - 0.05), x, y, 1.0, false)
        link.angularDamping = 0.1
        worldAddBody(world, link)

        joint = createRevoluteJoint(prevBody, link,
            vec(0, i == 1 and 0 or -linkLen / 2 + 0.05),
            vec(0, linkLen / 2 - 0.05))
        worldAddJoint(world, joint)
        prevBody = link
    end

    ballRadius = 1.2
    ball = createBody(createCircle(ballRadius), craneX, craneY - ropeLength - ballRadius, 15.0, false)
    ball.restitution = 0.1
    worldAddBody(world, ball)

    ballJoint = createRevoluteJoint(prevBody, ball, vec(0, -linkLen / 2), vec(0, 0))
    worldAddJoint(world, ballJoint)

    ball.velocity = vec(12, 5)

    return world
end

-- ============================================================================
-- Scenario 11: Gear train (coupled revolute joints)
-- ============================================================================

function createGearTrainScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(20, 1), 0, -1, 1, true)
    worldAddBody(world, ground)

    gearData = {
        {x = 0, y = 5, radius = 1.0, sides = 12, density = 3.0},
        {x = 2.2, y = 5, radius = 0.7, sides = 9, density = 3.0},
        {x = 3.9, y = 5, radius = 1.2, sides = 14, density = 3.0},
        {x = 6.3, y = 5, radius = 0.5, sides = 8, density = 3.0},
        {x = 7.5, y = 5, radius = 0.9, sides = 11, density = 3.0},
    }

    gearBodies = {}
    gearJoints = {}

    for i = 1, #gearData do
        gd = gearData[i]
        gear = createBody(createRegularPolygon(gd.radius, gd.sides), gd.x, gd.y, gd.density, false)
        gear.angularDamping = 0.02
        worldAddBody(world, gear)
        gearBodies[i] = gear

        pivot = createBody(createCircle(0.1), gd.x, gd.y, 1, true)
        worldAddBody(world, pivot)

        joint = createRevoluteJoint(pivot, gear, vec(0, 0), vec(0, 0))
        if i == 1 then
            joint.motorEnabled = true
            joint.motorSpeed = 5
            joint.maxMotorTorque = 100
        end
        worldAddJoint(world, joint)
        gearJoints[i] = joint
    end

    for i = 1, #gearBodies - 1 do
        ratio = -gearData[i].radius / gearData[i + 1].radius
        gj = createGearJoint(gearJoints[i], gearJoints[i + 1], ratio)
        worldAddJoint(world, gj)
    end

    return world
end

-- ============================================================================
-- Scenario 12: Cloth simulation (grid of distance joints)
-- ============================================================================

function createClothScenario()
    world = createWorld(vec(0, -5), 2.0)

    cols = 10
    rows = 8
    spacing = 0.8
    startX = -(cols - 1) * spacing / 2
    startY = 12

    particles = {}
    for r = 0, rows - 1 do
        particles[r] = {}
        for c = 0, cols - 1 do
            x = startX + c * spacing
            y = startY - r * spacing
            isFixed = (r == 0) and (c == 0 or c == cols - 1 or c == M.floor(cols / 2))
            p = createBody(createCircle(0.1), x, y, 0.5, isFixed)
            p.linearDamping = 0.3
            p.angularDamping = 0.5
            worldAddBody(world, p)
            particles[r][c] = p
        end
    end

    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            if c < cols - 1 then
                joint = createDistanceJoint(
                    particles[r][c], particles[r][c + 1],
                    vec(0, 0), vec(0, 0), spacing)
                joint.stiffness = 150
                joint.damping = 3
                worldAddJoint(world, joint)
            end
            if r < rows - 1 then
                joint = createDistanceJoint(
                    particles[r][c], particles[r + 1][c],
                    vec(0, 0), vec(0, 0), spacing)
                joint.stiffness = 150
                joint.damping = 3
                worldAddJoint(world, joint)
            end
        end
    end

    obstacle = createBody(createCircle(2.0), 0, 7, 1, true)
    worldAddBody(world, obstacle)

    return world
end

-- ============================================================================
-- Scenario 13: Conveyor belt (applying tangential force at contacts)
-- ============================================================================

function createConveyorScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(25, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    belt1 = createBody(createBox(6, 0.3), -5, 2, 1, true)
    belt1.angle = -0.15
    belt1.dynamicFriction = 0.9
    belt1.userData = {beltSpeed = 3.0}
    worldAddBody(world, belt1)

    belt2 = createBody(createBox(6, 0.3), 7, 4, 1, true)
    belt2.angle = 0.1
    belt2.dynamicFriction = 0.9
    belt2.userData = {beltSpeed = -2.0}
    worldAddBody(world, belt2)

    belt3 = createBody(createBox(5, 0.3), -2, 7, 1, true)
    belt3.angle = -0.05
    belt3.dynamicFriction = 0.9
    belt3.userData = {beltSpeed = 4.0}
    worldAddBody(world, belt3)

    resetRandom()
    for i = 1, 20 do
        shapeChoice = M.floor(random() * 3)
        x = randomRange(-8, -4)
        y = randomRange(9, 14)
        body = null
        if shapeChoice == 0 then
            body = createBody(createCircle(randomRange(0.2, 0.5)), x, y, 2.0, false)
        else if shapeChoice == 1 then
            body = createBody(createBox(randomRange(0.2, 0.5), randomRange(0.2, 0.5)), x, y, 2.0, false)
        else
            body = createBody(createRegularPolygon(randomRange(0.3, 0.5), 5), x, y, 2.0, false)
        end
        body.dynamicFriction = 0.5
        body.restitution = 0.2
        worldAddBody(world, body)
    end

    return world
end

-- ============================================================================
-- Scenario 14: Catapult (prismatic joint + release mechanism)
-- ============================================================================

function createCatapultScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(30, 1), 0, -1, 1, true)
    worldAddBody(world, ground)

    baseX = -10
    baseY = 0

    base = createBody(createBox(2, 0.5), baseX, baseY + 0.5, 1, true)
    worldAddBody(world, base)

    arm = createBody(createBox(4, 0.2), baseX, baseY + 1.5, 3.0, false)
    worldAddBody(world, arm)

    pivot = createRevoluteJoint(base, arm, vec(0, 0.5), vec(-2, 0))
    worldAddJoint(world, pivot)

    counterweight = createBody(createBox(0.8, 0.8), baseX - 3, baseY + 2, 20.0, false)
    worldAddBody(world, counterweight)
    cwJoint = createWeldJoint(arm, counterweight, vec(-2.5, 0), vec(0, 0))
    worldAddJoint(world, cwJoint)

    projectile = createBody(createCircle(0.4), baseX + 3.5, baseY + 2, 1.0, false)
    projectile.restitution = 0.3
    worldAddBody(world, projectile)

    cupJoint = createDistanceJoint(arm, projectile, vec(3.5, 0.2), vec(0, 0), 0.3)
    cupJoint.stiffness = 300
    cupJoint.damping = 5
    worldAddJoint(world, cupJoint)

    targetX = 10
    for row = 0, 4 do
        for col = 0, 3 do
            x = targetX + col * 0.8
            y = 0.3 + row * 0.6
            target = createBody(createBox(0.35, 0.25), x, y, 1.5, false)
            target.restitution = 0.1
            worldAddBody(world, target)
        end
    end

    arm.angularVelocity = -8

    return world
end

-- ============================================================================
-- Scenario 15: Pinball machine (flippers, bumpers, ball)
-- ============================================================================

function createPinballScenario()
    world = createWorld(vec(0, -8), 2.5)

    tableAngle = 0.1
    tableW = 10
    tableH = 20

    leftWall = createBody(createBox(0.3, tableH / 2), -tableW / 2 - 0.3, tableH / 2, 1, true)
    worldAddBody(world, leftWall)
    rightWall = createBody(createBox(0.3, tableH / 2), tableW / 2 + 0.3, tableH / 2, 1, true)
    worldAddBody(world, rightWall)
    topWall = createBody(createBox(tableW / 2, 0.3), 0, tableH + 0.3, 1, true)
    worldAddBody(world, topWall)

    drainVerts = {
        vec(-tableW / 2, 0), vec(-2, -1.5), vec(2, -1.5), vec(tableW / 2, 0)
    }
    for i = 1, 3 do
        mid = vecLerp(drainVerts[i], drainVerts[i + 1], 0.5)
        dx = drainVerts[i + 1].x - drainVerts[i].x
        dy = drainVerts[i + 1].y - drainVerts[i].y
        len = M.sqrt(dx * dx + dy * dy)
        wall = createBody(createBox(len / 2, 0.2), mid.x, mid.y, 1, true)
        wall.angle = M.atan2(dy, dx)
        worldAddBody(world, wall)
    end

    bumperPositions = {
        {x = 0, y = 14}, {x = -2.5, y = 12}, {x = 2.5, y = 12},
        {x = -1.5, y = 9}, {x = 1.5, y = 9}, {x = 0, y = 7},
        {x = -3, y = 6}, {x = 3, y = 6}
    }

    for i = 1, #bumperPositions do
        bp = bumperPositions[i]
        bumper = createBody(createCircle(0.6), bp.x, bp.y, 1, true)
        bumper.restitution = 1.2
        worldAddBody(world, bumper)
    end

    leftFlipper = createBody(createBox(1.5, 0.2), -2, 2, 5.0, false)
    leftFlipper.angularDamping = 2.0
    worldAddBody(world, leftFlipper)
    lfPivot = createRevoluteJoint(leftWall, leftFlipper, vec(0.3, 2), vec(-1.2, 0))
    lfPivot.motorEnabled = true
    lfPivot.motorSpeed = 20
    lfPivot.maxMotorTorque = 200
    worldAddJoint(world, lfPivot)

    rightFlipper = createBody(createBox(1.5, 0.2), 2, 2, 5.0, false)
    rightFlipper.angularDamping = 2.0
    worldAddBody(world, rightFlipper)
    rfPivot = createRevoluteJoint(rightWall, rightFlipper, vec(-0.3, 2), vec(1.2, 0))
    rfPivot.motorEnabled = true
    rfPivot.motorSpeed = -20
    rfPivot.maxMotorTorque = 200
    worldAddJoint(world, rfPivot)

    ball = createBody(createCircle(0.35), 4, 18, 2.0, false)
    ball.restitution = 0.7
    ball.linearDamping = 0.05
    ball.velocity = vec(-3, -2)
    worldAddBody(world, ball)

    ball2 = createBody(createCircle(0.35), -3, 16, 2.0, false)
    ball2.restitution = 0.7
    ball2.linearDamping = 0.05
    ball2.velocity = vec(2, -4)
    worldAddBody(world, ball2)

    return world
end

-- ============================================================================
-- Scenario 16: Rube Goldberg machine
-- ============================================================================

function createRubeGoldbergScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(40, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    ramp1 = createBody(createBox(4, 0.2), -12, 8, 1, true)
    ramp1.angle = -0.3
    worldAddBody(world, ramp1)

    ball1 = createBody(createCircle(0.4), -15, 10, 3.0, false)
    ball1.restitution = 0.5
    worldAddBody(world, ball1)

    seesaw = createBody(createBox(3, 0.15), -6, 4, 2.0, false)
    worldAddBody(world, seesaw)
    seesawPivot = createBody(createCircle(0.1), -6, 4, 1, true)
    worldAddBody(world, seesawPivot)
    seesawJoint = createRevoluteJoint(seesawPivot, seesaw, vec(0, 0), vec(0, 0))
    worldAddJoint(world, seesawJoint)

    weight = createBody(createBox(0.5, 0.5), -8.5, 5, 8.0, false)
    worldAddBody(world, weight)

    ramp2 = createBody(createBox(3, 0.2), -2, 6, 1, true)
    ramp2.angle = 0.25
    worldAddBody(world, ramp2)

    ramp3 = createBody(createBox(3, 0.2), 3, 4, 1, true)
    ramp3.angle = -0.2
    worldAddBody(world, ramp3)

    numDominoes = 8
    for i = 0, numDominoes - 1 do
        x = 7 + i * 0.9
        domino = createBody(createBox(0.1, 0.7), x, 0.7, 3.0, false)
        domino.staticFriction = 0.5
        worldAddBody(world, domino)
    end

    pendulumAnchor = createBody(createCircle(0.1), 5, 10, 1, true)
    worldAddBody(world, pendulumAnchor)
    pendulumBall = createBody(createCircle(0.5), 5, 6, 5.0, false)
    worldAddBody(world, pendulumBall)
    pendulumJoint = createDistanceJoint(pendulumAnchor, pendulumBall, vec(0, 0), vec(0, 0), 4)
    pendulumJoint.stiffness = 500
    pendulumJoint.damping = 1
    worldAddJoint(world, pendulumJoint)

    bucket = createBody(createBox(1, 0.1), 15, 3, 2.0, false)
    worldAddBody(world, bucket)
    bucketLeft = createBody(createBox(0.1, 0.5), 14, 3.5, 2.0, false)
    worldAddBody(world, bucketLeft)
    bucketRight = createBody(createBox(0.1, 0.5), 16, 3.5, 2.0, false)
    worldAddBody(world, bucketRight)
    bwl = createWeldJoint(bucket, bucketLeft, vec(-1, 0), vec(0, -0.4))
    worldAddJoint(world, bwl)
    bwr = createWeldJoint(bucket, bucketRight, vec(1, 0), vec(0, -0.4))
    worldAddJoint(world, bwr)

    bucketRope = createRopeJoint(ground, bucket, vec(15, 8), vec(0, 0), 5)
    worldAddJoint(world, bucketRope)

    return world
end

-- ============================================================================
-- Scenario 17: Granular material (many small circles)
-- ============================================================================

function createGranularScenario()
    world = createWorld(vec(0, -10), 1.5)

    funnel_left = createBody(createBox(3, 0.2), -3, 12, 1, true)
    funnel_left.angle = 0.6
    worldAddBody(world, funnel_left)
    funnel_right = createBody(createBox(3, 0.2), 3, 12, 1, true)
    funnel_right.angle = -0.6
    worldAddBody(world, funnel_right)

    channel_left = createBody(createBox(0.2, 4), -0.8, 8, 1, true)
    worldAddBody(world, channel_left)
    channel_right = createBody(createBox(0.2, 4), 0.8, 8, 1, true)
    worldAddBody(world, channel_right)

    container_left = createBody(createBox(0.2, 3), -4, 1.5, 1, true)
    worldAddBody(world, container_left)
    container_right = createBody(createBox(0.2, 3), 4, 1.5, 1, true)
    worldAddBody(world, container_right)
    container_bottom = createBody(createBox(4, 0.2), 0, -0.7, 1, true)
    worldAddBody(world, container_bottom)

    deflector = createBody(createRegularPolygon(0.8, 3), 0, 5, 1, true)
    worldAddBody(world, deflector)

    resetRandom()
    for i = 1, 60 do
        radius = randomRange(0.15, 0.3)
        x = randomRange(-1.5, 1.5)
        y = randomRange(13, 20)
        grain = createBody(createCircle(radius), x, y, 2.5, false)
        grain.restitution = 0.1
        grain.dynamicFriction = 0.4
        grain.linearDamping = 0.02
        worldAddBody(world, grain)
    end

    return world
end

-- ============================================================================
-- Scenario 18: Ragdoll (connected body segments)
-- ============================================================================

function createRagdollScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(20, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    platform = createBody(createBox(3, 0.2), 0, 8, 1, true)
    worldAddBody(world, platform)

    function makeRagdoll(startX, startY, scale)
        headRadius = 0.3 * scale
        torsoW = 0.35 * scale
        torsoH = 0.6 * scale
        limbW = 0.15 * scale
        upperLimbH = 0.4 * scale
        lowerLimbH = 0.35 * scale

        head = createBody(createCircle(headRadius), startX, startY, 2.0, false)
        head.angularDamping = 0.3
        worldAddBody(world, head)

        torso = createBody(createBox(torsoW, torsoH), startX, startY - headRadius - torsoH, 3.0, false)
        worldAddBody(world, torso)
        neckJoint = createRevoluteJoint(head, torso,
            vec(0, -headRadius), vec(0, torsoH))
        worldAddJoint(world, neckJoint)

        upperArmL = createBody(createBox(limbW, upperLimbH),
            startX - torsoW - limbW, startY - headRadius - 0.1, 1.5, false)
        worldAddBody(world, upperArmL)
        shoulderL = createRevoluteJoint(torso, upperArmL,
            vec(-torsoW, torsoH - 0.1), vec(0, upperLimbH))
        worldAddJoint(world, shoulderL)

        lowerArmL = createBody(createBox(limbW, lowerLimbH),
            startX - torsoW - limbW, startY - headRadius - 0.1 - upperLimbH * 2, 1.0, false)
        worldAddBody(world, lowerArmL)
        elbowL = createRevoluteJoint(upperArmL, lowerArmL,
            vec(0, -upperLimbH), vec(0, lowerLimbH))
        worldAddJoint(world, elbowL)

        upperArmR = createBody(createBox(limbW, upperLimbH),
            startX + torsoW + limbW, startY - headRadius - 0.1, 1.5, false)
        worldAddBody(world, upperArmR)
        shoulderR = createRevoluteJoint(torso, upperArmR,
            vec(torsoW, torsoH - 0.1), vec(0, upperLimbH))
        worldAddJoint(world, shoulderR)

        lowerArmR = createBody(createBox(limbW, lowerLimbH),
            startX + torsoW + limbW, startY - headRadius - 0.1 - upperLimbH * 2, 1.0, false)
        worldAddBody(world, lowerArmR)
        elbowR = createRevoluteJoint(upperArmR, lowerArmR,
            vec(0, -upperLimbH), vec(0, lowerLimbH))
        worldAddJoint(world, elbowR)

        upperLegL = createBody(createBox(limbW, upperLimbH),
            startX - torsoW * 0.5, startY - headRadius - torsoH * 2 - 0.1, 2.0, false)
        worldAddBody(world, upperLegL)
        hipL = createRevoluteJoint(torso, upperLegL,
            vec(-torsoW * 0.5, -torsoH), vec(0, upperLimbH))
        worldAddJoint(world, hipL)

        lowerLegL = createBody(createBox(limbW, lowerLimbH),
            startX - torsoW * 0.5, startY - headRadius - torsoH * 2 - upperLimbH * 2 - 0.1, 1.5, false)
        worldAddBody(world, lowerLegL)
        kneeL = createRevoluteJoint(upperLegL, lowerLegL,
            vec(0, -upperLimbH), vec(0, lowerLimbH))
        worldAddJoint(world, kneeL)

        upperLegR = createBody(createBox(limbW, upperLimbH),
            startX + torsoW * 0.5, startY - headRadius - torsoH * 2 - 0.1, 2.0, false)
        worldAddBody(world, upperLegR)
        hipR = createRevoluteJoint(torso, upperLegR,
            vec(torsoW * 0.5, -torsoH), vec(0, upperLimbH))
        worldAddJoint(world, hipR)

        lowerLegR = createBody(createBox(limbW, lowerLimbH),
            startX + torsoW * 0.5, startY - headRadius - torsoH * 2 - upperLimbH * 2 - 0.1, 1.5, false)
        worldAddBody(world, lowerLegR)
        kneeR = createRevoluteJoint(upperLegR, lowerLegR,
            vec(0, -upperLimbH), vec(0, lowerLimbH))
        worldAddJoint(world, kneeR)
    end

    makeRagdoll(-3, 12, 1.0)
    makeRagdoll(0, 14, 1.2)
    makeRagdoll(3, 11, 0.9)

    return world
end

-- ============================================================================
-- Scenario 19: Breakable joint chain (stress test)
-- ============================================================================

function createBreakableChainScenario()
    world = createWorld(vec(0, -10), 2.5)

    ground = createBody(createBox(20, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    numChains = 5
    linksPerChain = 10
    chainSpacing = 4
    startX = -(numChains - 1) * chainSpacing / 2

    for chain = 0, numChains - 1 do
        x = startX + chain * chainSpacing
        anchor = createBody(createCircle(0.2), x, 15, 1, true)
        worldAddBody(world, anchor)

        prev = anchor
        for link = 1, linksPerChain do
            linkBody = createBody(createBox(0.3, 0.15), x, 15 - link * 0.7, 2.0, false)
            linkBody.angularDamping = 0.1
            worldAddBody(world, linkBody)

            joint = createDistanceJoint(prev, linkBody,
                vec(0, link == 1 and 0 or -0.15), vec(0, 0.15), 0.4)
            joint.stiffness = 200
            joint.damping = 5
            worldAddJoint(world, joint)
            prev = linkBody
        end

        weight = createBody(createCircle(0.6), x, 15 - (linksPerChain + 1) * 0.7, 10.0, false)
        worldAddBody(world, weight)
        endJoint = createDistanceJoint(prev, weight, vec(0, -0.15), vec(0, 0.3), 0.3)
        endJoint.stiffness = 200
        endJoint.damping = 5
        worldAddJoint(world, endJoint)
    end

    striker = createBody(createCircle(1.0), -15, 8, 20.0, false)
    striker.velocity = vec(20, 0)
    striker.restitution = 0.3
    worldAddBody(world, striker)

    return world
end

-- ============================================================================
-- Scenario 20: Stacking with varying shapes (stress test for solver)
-- ============================================================================

function createMixedStackScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(20, 0.5), 0, -0.5, 1, true)
    ground.staticFriction = 0.9
    worldAddBody(world, ground)

    resetRandom()
    y = 0.5
    for layer = 1, 15 do
        numItems = M.max(1, 6 - M.floor(layer / 3))
        totalWidth = numItems * 1.8
        startX = -totalWidth / 2

        for item = 0, numItems - 1 do
            x = startX + item * 1.8 + 0.9
            shapeChoice = M.floor(random() * 4)
            body = null

            if shapeChoice == 0 then
                body = createBody(createCircle(randomRange(0.3, 0.6)), x, y + 0.5, 2.0, false)
            else if shapeChoice == 1 then
                body = createBody(createBox(randomRange(0.4, 0.8), randomRange(0.3, 0.5)), x, y + 0.4, 2.0, false)
            else if shapeChoice == 2 then
                body = createBody(createRegularPolygon(randomRange(0.3, 0.6), 5), x, y + 0.5, 2.0, false)
            else
                body = createBody(createRegularPolygon(randomRange(0.3, 0.6), 3), x, y + 0.5, 2.0, false)
            end

            body.restitution = 0.0
            body.staticFriction = 0.7
            body.dynamicFriction = 0.5
            worldAddBody(world, body)
        end
        y = y + 1.1
    end

    return world
end

-- ============================================================================
-- Additional raycast and query test scenario
-- ============================================================================

function createRaycastTestScenario()
    world = createWorld(vec(0, 0), 3.0)
    world.gravity = vec(0, 0)

    resetRandom()
    for i = 1, 30 do
        x = randomRange(-15, 15)
        y = randomRange(-10, 10)
        shapeChoice = M.floor(random() * 3)
        body = null
        if shapeChoice == 0 then
            body = createBody(createCircle(randomRange(0.5, 1.5)), x, y, 1.0, true)
        else if shapeChoice == 1 then
            body = createBody(createBox(randomRange(0.5, 2.0), randomRange(0.5, 2.0)), x, y, 1.0, true)
        else
            body = createBody(createRegularPolygon(randomRange(0.5, 1.5), M.floor(random() * 4) + 3), x, y, 1.0, true)
        end
        body.angle = randomRange(0, M.pi * 2)
        worldAddBody(world, body)
    end

    rayResults = {}
    numRays = 50
    for i = 1, numRays do
        angle = (i - 1) * M.pi * 2 / numRays
        dir = vec(M.cos(angle), M.sin(angle))
        hit = worldRaycast(world, vec(0, 0), dir, 20)
        if hit then
            rayResults[#rayResults + 1] = hit.t
        end
    end

    aabbResults = worldQueryAABB(world, {minX = -5, minY = -5, maxX = 5, maxY = 5})
    pointResults = worldQueryPoint(world, vec(0, 0))

    return world, #rayResults, #aabbResults, #pointResults
end

-- ============================================================================
-- Particle System (Verlet integration, no rotation)
-- ============================================================================

function createParticle(x, y, mass, radius)
    return {
        pos = vec(x, y),
        prevPos = vec(x, y),
        acc = vec(0, 0),
        mass = mass,
        invMass = mass > 0 and 1 / mass or 0,
        radius = radius,
        pinned = false
    }
end

function createParticleConstraint(p1, p2, restLength, stiffness)
    return {
        p1 = p1,
        p2 = p2,
        restLength = restLength,
        stiffness = stiffness or 1.0
    }
end

function particleSystemStep(particles, constraints, gravity, dt, bounds)
    for i = 1, #particles do
        p = particles[i]
        if not p.pinned then
            p.acc = vecAdd(p.acc, gravity)
            vel = vecSub(p.pos, p.prevPos)
            vel = vecMul(vel, 0.99)
            p.prevPos = {x = p.pos.x, y = p.pos.y}
            p.pos = vecAdd(vecAdd(p.pos, vel), vecMul(p.acc, dt * dt))
            p.acc = vec(0, 0)
        end
    end

    iterations = 4
    for iter = 1, iterations do
        for i = 1, #constraints do
            c = constraints[i]
            diff = vecSub(c.p2.pos, c.p1.pos)
            dist = vecLen(diff)
            if dist > 0.001 then
                error = (dist - c.restLength) / dist
                correction = vecMul(diff, error * 0.5 * c.stiffness)
                if not c.p1.pinned then
                    c.p1.pos = vecAdd(c.p1.pos, correction)
                end
                if not c.p2.pinned then
                    c.p2.pos = vecSub(c.p2.pos, correction)
                end
            end
        end

        for i = 1, #particles do
            p = particles[i]
            if not p.pinned and bounds then
                if p.pos.x - p.radius < bounds.minX then p.pos.x = bounds.minX + p.radius end
                if p.pos.x + p.radius > bounds.maxX then p.pos.x = bounds.maxX - p.radius end
                if p.pos.y - p.radius < bounds.minY then p.pos.y = bounds.minY + p.radius end
                if p.pos.y + p.radius > bounds.maxY then p.pos.y = bounds.maxY - p.radius end
            end
        end

        for i = 1, #particles do
            for j = i + 1, #particles do
                p1 = particles[i]
                p2 = particles[j]
                diff = vecSub(p2.pos, p1.pos)
                dist = vecLen(diff)
                minDist = p1.radius + p2.radius
                if dist < minDist and dist > 0.001 then
                    overlap = (minDist - dist) / dist
                    correction = vecMul(diff, overlap * 0.5)
                    if not p1.pinned then
                        p1.pos = vecSub(p1.pos, correction)
                    end
                    if not p2.pinned then
                        p2.pos = vecAdd(p2.pos, correction)
                    end
                end
            end
        end
    end
end

function checksumParticles(particles)
    sum = 0
    for i = 1, #particles do
        sum = sum + particles[i].pos.x * 100 + particles[i].pos.y * 100
    end
    return M.floor(sum * 100) / 100
end

-- ============================================================================
-- Scenario 21: Particle rope (Verlet)
-- ============================================================================

function createParticleRopeScenario()
    numParticles = 40
    spacing = 0.5
    particles = {}
    constraints = {}

    for i = 1, numParticles do
        p = createParticle((i - 1) * spacing, 10, 1.0, 0.1)
        if i == 1 then p.pinned = true end
        particles[i] = p
    end

    for i = 1, numParticles - 1 do
        constraints[i] = createParticleConstraint(particles[i], particles[i + 1], spacing, 1.0)
    end

    gravity = vec(0, -10)
    bounds = {minX = -5, minY = -5, maxX = 25, maxY = 15}

    for step = 1, 60 do
        particleSystemStep(particles, constraints, gravity, 1/60, bounds)
    end

    return checksumParticles(particles)
end

-- ============================================================================
-- Scenario 22: Particle cloth (2D grid with Verlet)
-- ============================================================================

function createParticleClothScenario()
    cols = 15
    rows = 12
    spacing = 0.4
    particles = {}
    constraints = {}

    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            idx = r * cols + c + 1
            p = createParticle(c * spacing, 8 - r * spacing, 1.0, 0.05)
            if r == 0 and (c == 0 or c == cols - 1 or c == M.floor(cols / 2)) then
                p.pinned = true
            end
            particles[idx] = p
        end
    end

    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            idx = r * cols + c + 1
            if c < cols - 1 then
                constraints[#constraints + 1] = createParticleConstraint(
                    particles[idx], particles[idx + 1], spacing, 0.9)
            end
            if r < rows - 1 then
                constraints[#constraints + 1] = createParticleConstraint(
                    particles[idx], particles[idx + cols], spacing, 0.9)
            end
            if c < cols - 1 and r < rows - 1 then
                diagLen = spacing * 1.414
                constraints[#constraints + 1] = createParticleConstraint(
                    particles[idx], particles[idx + cols + 1], diagLen, 0.5)
            end
            if c > 0 and r < rows - 1 then
                diagLen = spacing * 1.414
                constraints[#constraints + 1] = createParticleConstraint(
                    particles[idx], particles[idx + cols - 1], diagLen, 0.5)
            end
        end
    end

    gravity = vec(0, -5)
    bounds = {minX = -3, minY = -3, maxX = 10, maxY = 10}

    for step = 1, 50 do
        particleSystemStep(particles, constraints, gravity, 1/60, bounds)
    end

    return checksumParticles(particles)
end

-- ============================================================================
-- Scenario 23: Soft body (particle-based circle)
-- ============================================================================

function createSoftBodyScenario()
    numRings = 3
    particlesPerRing = {12, 8, 4}
    ringRadii = {2.0, 1.3, 0.6}
    centerX, centerY = 0, 8

    allParticles = {}
    allConstraints = {}

    center = createParticle(centerX, centerY, 2.0, 0.15)
    allParticles[1] = center

    for ring = 1, numRings do
        n = particlesPerRing[ring]
        r = ringRadii[ring]
        startIdx = #allParticles + 1
        for i = 1, n do
            angle = (i - 1) * 2 * M.pi / n
            px = centerX + r * M.cos(angle)
            py = centerY + r * M.sin(angle)
            p = createParticle(px, py, 1.0, 0.12)
            allParticles[#allParticles + 1] = p
        end

        for i = 0, n - 1 do
            idx1 = startIdx + i
            idx2 = startIdx + (i + 1) % n
            dist = vecDist(allParticles[idx1].pos, allParticles[idx2].pos)
            allConstraints[#allConstraints + 1] = createParticleConstraint(
                allParticles[idx1], allParticles[idx2], dist, 0.8)
        end

        for i = 0, n - 1 do
            idx = startIdx + i
            dist = vecDist(allParticles[idx].pos, center.pos)
            allConstraints[#allConstraints + 1] = createParticleConstraint(
                allParticles[idx], center, dist, 0.6)
        end
    end

    for i = 1, particlesPerRing[1] do
        outerIdx = 1 + i
        innerIdx = 1 + particlesPerRing[1] + M.floor((i - 1) * particlesPerRing[2] / particlesPerRing[1]) + 1
        if innerIdx <= 1 + particlesPerRing[1] + particlesPerRing[2] then
            dist = vecDist(allParticles[outerIdx].pos, allParticles[innerIdx].pos)
            allConstraints[#allConstraints + 1] = createParticleConstraint(
                allParticles[outerIdx], allParticles[innerIdx], dist, 0.5)
        end
    end

    gravity = vec(0, -10)
    bounds = {minX = -5, minY = -2, maxX = 5, maxY = 12}

    for step = 1, 60 do
        particleSystemStep(allParticles, allConstraints, gravity, 1/60, bounds)
    end

    return checksumParticles(allParticles)
end

-- ============================================================================
-- Buoyancy simulation
-- ============================================================================

function computeSubmergedArea(body, waterLevel)
    if body.shape.type == SHAPE_CIRCLE then
        r = body.shape.radius
        depth = waterLevel - (body.position.y - r)
        if depth <= 0 then return 0, vec(0, 0) end
        if depth >= 2 * r then return M.pi * r * r, body.position end
        ratio = depth / (2 * r)
        area = M.pi * r * r * ratio
        centroidY = body.position.y - r + depth / 2
        return area, vec(body.position.x, centroidY)
    else
        verts = bodyGetTransformedVertices(body)
        n = #verts
        submergedVerts = {}
        for i = 1, n do
            if verts[i].y <= waterLevel then
                submergedVerts[#submergedVerts + 1] = verts[i]
            end
        end
        for i = 1, n do
            j = (i % n) + 1
            v1 = verts[i]
            v2 = verts[j]
            if (v1.y <= waterLevel) != (v2.y <= waterLevel) then
                t = (waterLevel - v1.y) / (v2.y - v1.y)
                submergedVerts[#submergedVerts + 1] = vecLerp(v1, v2, t)
            end
        end
        if #submergedVerts < 3 then return 0, vec(0, 0) end

        cx, cy = 0, 0
        for i = 1, #submergedVerts do
            cx = cx + submergedVerts[i].x
            cy = cy + submergedVerts[i].y
        end
        cx = cx / #submergedVerts
        cy = cy / #submergedVerts

        table.sort(submergedVerts, function(a, b)
            angA = M.atan2(a.y - cy, a.x - cx)
            angB = M.atan2(b.y - cy, b.x - cx)
            return angA < angB
        end)

        area = computePolygonArea(submergedVerts)
        centroid = computePolygonCentroid(submergedVerts)
        return area, centroid
    end
end

function applyBuoyancy(body, waterLevel, waterDensity, dragCoeff)
    if body.isStatic then return end
    subArea, buoyancyCenter = computeSubmergedArea(body, waterLevel)
    if subArea <= 0 then return end

    buoyancyForce = vec(0, waterDensity * subArea * 10)
    bodyApplyForceAtPoint(body, buoyancyForce, buoyancyCenter)

    vel = bodyGetVelocityAtPoint(body, buoyancyCenter)
    dragForce = vecMul(vel, -dragCoeff * subArea)
    bodyApplyForceAtPoint(body, dragForce, buoyancyCenter)

    body.angularVelocity = body.angularVelocity * (1 - 0.02 * subArea)
end

-- ============================================================================
-- Scenario 24: Buoyancy pool
-- ============================================================================

function createBuoyancyScenario()
    world = createWorld(vec(0, -10), 3.0)

    poolLeft = createBody(createBox(0.5, 5), -8, 2.5, 1, true)
    worldAddBody(world, poolLeft)
    poolRight = createBody(createBox(0.5, 5), 8, 2.5, 1, true)
    worldAddBody(world, poolRight)
    poolBottom = createBody(createBox(8, 0.5), 0, -2, 1, true)
    worldAddBody(world, poolBottom)

    resetRandom()
    floaters = {}
    for i = 1, 15 do
        shapeChoice = M.floor(random() * 3)
        x = randomRange(-6, 6)
        y = randomRange(3, 8)
        body = null
        if shapeChoice == 0 then
            body = createBody(createCircle(randomRange(0.3, 0.8)), x, y, randomRange(0.3, 1.5), false)
        else if shapeChoice == 1 then
            body = createBody(createBox(randomRange(0.4, 1.0), randomRange(0.3, 0.6)), x, y, randomRange(0.3, 1.5), false)
        else
            body = createBody(createRegularPolygon(randomRange(0.4, 0.7), 5), x, y, randomRange(0.3, 1.5), false)
        end
        body.restitution = 0.2
        worldAddBody(world, body)
        floaters[#floaters + 1] = body
    end

    world.waterLevel = 5.0
    world.waterDensity = 1.0
    world.dragCoeff = 2.0
    world.floaters = floaters

    return world
end

-- ============================================================================
-- Scenario 25: Tornado / vortex (radial force field)
-- ============================================================================

function createTornadoScenario()
    world = createWorld(vec(0, -5), 3.0)

    ground = createBody(createBox(20, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    wallL = createBody(createBox(0.5, 10), -10, 5, 1, true)
    worldAddBody(world, wallL)
    wallR = createBody(createBox(0.5, 10), 10, 5, 1, true)
    worldAddBody(world, wallR)
    ceiling = createBody(createBox(20, 0.5), 0, 15, 1, true)
    worldAddBody(world, ceiling)

    debris = {}
    resetRandom()
    for i = 1, 40 do
        x = randomRange(-8, 8)
        y = randomRange(0.5, 3)
        body = null
        sc = M.floor(random() * 3)
        if sc == 0 then
            body = createBody(createCircle(randomRange(0.2, 0.5)), x, y, 1.5, false)
        else if sc == 1 then
            body = createBody(createBox(randomRange(0.2, 0.6), randomRange(0.2, 0.6)), x, y, 1.5, false)
        else
            body = createBody(createRegularPolygon(randomRange(0.2, 0.5), M.floor(random() * 3) + 3), x, y, 1.5, false)
        end
        body.linearDamping = 0.1
        body.angularDamping = 0.1
        worldAddBody(world, body)
        debris[#debris + 1] = body
    end

    world.vortexCenter = vec(0, 7)
    world.vortexStrength = 30
    world.debris = debris

    return world
end

-- ============================================================================
-- Scenario 26: Pyramid stress test (many resting contacts)
-- ============================================================================

function createLargePyramidScenario()
    world = createWorld(vec(0, -10), 2.0)
    world.iterations = 15

    ground = createBody(createBox(30, 0.5), 0, -0.5, 1, true)
    ground.staticFriction = 0.9
    worldAddBody(world, ground)

    baseWidth = 20
    boxSize = 0.45
    spacing = boxSize * 2.05
    row = 0
    y = 0.5

    while true do
        numBoxes = baseWidth - row
        if numBoxes <= 0 then break end
        startX = -(numBoxes - 1) * spacing / 2
        for col = 0, numBoxes - 1 do
            x = startX + col * spacing
            box = createBody(createBox(boxSize, boxSize), x, y, 2.0, false)
            box.restitution = 0.0
            box.staticFriction = 0.7
            box.dynamicFriction = 0.5
            worldAddBody(world, box)
        end
        y = y + spacing
        row = row + 1
    end

    return world
end

-- ============================================================================
-- Scenario 27: Marble run (ramps + funnels + obstacles)
-- ============================================================================

function createMarbleRunScenario()
    world = createWorld(vec(0, -10), 2.5)

    ramps = {
        {x = -5, y = 18, w = 6, angle = -0.2},
        {x = 5, y = 15, w = 6, angle = 0.25},
        {x = -4, y = 12, w = 5, angle = -0.15},
        {x = 4, y = 9, w = 5, angle = 0.2},
        {x = -3, y = 6, w = 5, angle = -0.25},
        {x = 3, y = 3, w = 4, angle = 0.15},
    }

    for i = 1, #ramps do
        r = ramps[i]
        ramp = createBody(createBox(r.w / 2, 0.15), r.x, r.y, 1, true)
        ramp.angle = r.angle
        ramp.restitution = 0.3
        worldAddBody(world, ramp)

        lip = createBody(createBox(0.15, 0.3), r.x + r.w / 2 * M.cos(r.angle), r.y + r.w / 2 * M.sin(r.angle), 1, true)
        worldAddBody(world, lip)
    end

    obstacles = {
        {x = 0, y = 16.5, type = "circle", r = 0.4},
        {x = -2, y = 13.5, type = "triangle", r = 0.5},
        {x = 2, y = 10.5, type = "circle", r = 0.3},
        {x = -1, y = 7.5, type = "pentagon", r = 0.4},
        {x = 1, y = 4.5, type = "circle", r = 0.35},
    }

    for i = 1, #obstacles do
        o = obstacles[i]
        body = null
        if o.type == "circle" then
            body = createBody(createCircle(o.r), o.x, o.y, 1, true)
        else if o.type == "triangle" then
            body = createBody(createRegularPolygon(o.r, 3), o.x, o.y, 1, true)
        else
            body = createBody(createRegularPolygon(o.r, 5), o.x, o.y, 1, true)
        end
        body.restitution = 0.6
        worldAddBody(world, body)
    end

    floor = createBody(createBox(10, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, floor)

    collector_l = createBody(createBox(0.2, 1), -3, 0.7, 1, true)
    worldAddBody(world, collector_l)
    collector_r = createBody(createBox(0.2, 1), 3, 0.7, 1, true)
    worldAddBody(world, collector_r)

    resetRandom()
    for i = 1, 25 do
        radius = randomRange(0.2, 0.4)
        x = randomRange(-7, -3)
        y = randomRange(19, 22)
        marble = createBody(createCircle(radius), x, y, 2.5, false)
        marble.restitution = randomRange(0.3, 0.7)
        marble.dynamicFriction = 0.2
        worldAddBody(world, marble)
    end

    return world
end

-- ============================================================================
-- Scenario 28: Explosion (radial impulse)
-- ============================================================================

function createExplosionScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(25, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    wallSpacing = 3
    for wall = 1, 4 do
        wallX = wall * wallSpacing - 7.5
        for row = 0, 5 do
            for col = 0, 2 do
                x = wallX + col * 0.7
                y = 0.3 + row * 0.6
                brick = createBody(createBox(0.3, 0.25), x, y, 2.0, false)
                brick.restitution = 0.1
                brick.staticFriction = 0.6
                worldAddBody(world, brick)
            end
        end
    end

    explosionCenter = vec(0, 1)
    explosionRadius = 8
    explosionForce = 500

    for i = 1, #world.bodies do
        body = world.bodies[i]
        if not body.isStatic then
            toBody = vecSub(body.position, explosionCenter)
            dist = vecLen(toBody)
            if dist < explosionRadius and dist > 0.1 then
                falloff = 1 - dist / explosionRadius
                force = vecMul(vecNormalize(toBody), explosionForce * falloff * falloff)
                bodyApplyForce(body, force)
            end
        end
    end

    return world
end

-- ============================================================================
-- Scenario 29: Pulley system
-- ============================================================================

function createPulleyScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(20, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    pulleyAnchor1 = createBody(createCircle(0.3), -5, 12, 1, true)
    worldAddBody(world, pulleyAnchor1)
    pulleyAnchor2 = createBody(createCircle(0.3), 5, 12, 1, true)
    worldAddBody(world, pulleyAnchor2)

    weight1 = createBody(createBox(1, 1), -5, 6, 5.0, false)
    worldAddBody(world, weight1)
    rope1 = createRopeJoint(pulleyAnchor1, weight1, vec(0, 0), vec(0, 0.5), 6)
    worldAddJoint(world, rope1)

    weight2 = createBody(createBox(0.8, 0.8), 5, 8, 3.0, false)
    worldAddBody(world, weight2)
    rope2 = createRopeJoint(pulleyAnchor2, weight2, vec(0, 0), vec(0, 0.4), 4)
    worldAddJoint(world, rope2)

    crossbar = createBody(createBox(5.5, 0.15), 0, 12.3, 1.0, false)
    crossbar.gravityScale = 0
    worldAddBody(world, crossbar)
    cj1 = createDistanceJoint(pulleyAnchor1, crossbar, vec(0, 0.3), vec(-5, 0), 0.1)
    cj1.stiffness = 300
    cj1.damping = 10
    worldAddJoint(world, cj1)
    cj2 = createDistanceJoint(pulleyAnchor2, crossbar, vec(0, 0.3), vec(5, 0), 0.1)
    cj2.stiffness = 300
    cj2.damping = 10
    worldAddJoint(world, cj2)

    platform = createBody(createBox(3, 0.2), -5, 4.5, 2.0, false)
    worldAddBody(world, platform)
    pj = createDistanceJoint(weight1, platform, vec(0, -0.5), vec(0, 0.2), 1.0)
    pj.stiffness = 200
    pj.damping = 5
    worldAddJoint(world, pj)

    for i = 1, 5 do
        box = createBody(createBox(0.3, 0.3), -5 + (i - 3) * 0.65, 5.5, 1.5, false)
        worldAddBody(world, box)
    end

    return world
end

-- ============================================================================
-- Scenario 30: Elastic collision chain (demonstrates energy conservation)
-- ============================================================================

function createElasticChainScenario()
    world = createWorld(vec(0, 0), 3.0)
    world.gravity = vec(0, 0)

    wallTop = createBody(createBox(15, 0.3), 0, 5, 1, true)
    wallTop.restitution = 1.0
    worldAddBody(world, wallTop)
    wallBot = createBody(createBox(15, 0.3), 0, -5, 1, true)
    wallBot.restitution = 1.0
    worldAddBody(world, wallBot)
    wallL = createBody(createBox(0.3, 5), -15, 0, 1, true)
    wallL.restitution = 1.0
    worldAddBody(world, wallL)
    wallR = createBody(createBox(0.3, 5), 15, 0, 1, true)
    wallR.restitution = 1.0
    worldAddBody(world, wallR)

    resetRandom()
    for i = 1, 30 do
        radius = randomRange(0.3, 0.7)
        x = randomRange(-12, 12)
        y = randomRange(-3, 3)
        ball = createBody(createCircle(radius), x, y, 2.0, false)
        ball.restitution = 0.98
        ball.linearDamping = 0.0
        ball.dynamicFriction = 0.0
        ball.velocity = vec(randomRange(-5, 5), randomRange(-5, 5))
        worldAddBody(world, ball)
    end

    return world
end

-- ============================================================================
-- Material property tables (realistic physical properties)
-- ============================================================================

D = {}
D.materials = {
    steel = {density = 7.8, restitution = 0.6, staticFriction = 0.74, dynamicFriction = 0.57},
    aluminum = {density = 2.7, restitution = 0.7, staticFriction = 0.61, dynamicFriction = 0.47},
    wood_oak = {density = 0.6, restitution = 0.4, staticFriction = 0.62, dynamicFriction = 0.48},
    wood_pine = {density = 0.4, restitution = 0.3, staticFriction = 0.56, dynamicFriction = 0.42},
    rubber = {density = 1.1, restitution = 0.85, staticFriction = 1.0, dynamicFriction = 0.8},
    ice = {density = 0.92, restitution = 0.3, staticFriction = 0.1, dynamicFriction = 0.03},
    concrete = {density = 2.4, restitution = 0.2, staticFriction = 0.75, dynamicFriction = 0.6},
    glass = {density = 2.5, restitution = 0.65, staticFriction = 0.94, dynamicFriction = 0.4},
    plastic = {density = 1.2, restitution = 0.5, staticFriction = 0.4, dynamicFriction = 0.3},
    leather = {density = 0.86, restitution = 0.35, staticFriction = 0.6, dynamicFriction = 0.48},
    cork = {density = 0.12, restitution = 0.6, staticFriction = 0.5, dynamicFriction = 0.4},
    titanium = {density = 4.5, restitution = 0.55, staticFriction = 0.36, dynamicFriction = 0.3},
    copper = {density = 8.9, restitution = 0.4, staticFriction = 0.53, dynamicFriction = 0.36},
    lead = {density = 11.3, restitution = 0.15, staticFriction = 0.43, dynamicFriction = 0.3},
    teflon = {density = 2.2, restitution = 0.3, staticFriction = 0.04, dynamicFriction = 0.04},
    sandstone = {density = 2.3, restitution = 0.15, staticFriction = 0.7, dynamicFriction = 0.55},
    marble = {density = 2.7, restitution = 0.5, staticFriction = 0.6, dynamicFriction = 0.4},
    granite = {density = 2.75, restitution = 0.25, staticFriction = 0.65, dynamicFriction = 0.5},
    bone = {density = 1.9, restitution = 0.35, staticFriction = 0.45, dynamicFriction = 0.3},
    cartilage = {density = 1.1, restitution = 0.7, staticFriction = 0.03, dynamicFriction = 0.02},
}

function applyMaterial(body, materialName)
    mat = D.materials[materialName]
    if not mat then return end
    body.restitution = mat.restitution
    body.staticFriction = mat.staticFriction
    body.dynamicFriction = mat.dynamicFriction
end

-- ============================================================================
-- Scenario 31: Material interaction test
-- ============================================================================

function createMaterialTestScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(25, 0.5), 0, -0.5, 1, true)
    applyMaterial(ground, "concrete")
    worldAddBody(world, ground)

    ramp = createBody(createBox(8, 0.2), 0, 5, 1, true)
    ramp.angle = -0.3
    applyMaterial(ramp, "ice")
    worldAddBody(world, ramp)

    materialNames = {"steel", "rubber", "wood_oak", "ice", "glass", "plastic",
                           "cork", "leather", "teflon", "copper"}

    for i = 1, #materialNames do
        mat = D.materials[materialNames[i]]
        x = -6 + (i - 1) * 1.2
        body = createBody(createBox(0.4, 0.4), x, 7, mat.density, false)
        applyMaterial(body, materialNames[i])
        worldAddBody(world, body)
    end

    return world
end

-- ============================================================================
-- Pre-defined complex polygon shapes for testing
-- ============================================================================

D.complexShapes = {
    star = function()
        verts = {}
        for i = 1, 10 do
            angle = (i - 1) * M.pi / 5 - M.pi / 2
            r = (i % 2 == 1) and 1.0 or 0.4
            verts[i] = vec(r * M.cos(angle), r * M.sin(angle))
        end
        return computeConvexHull(verts)
    end,
    arrow = function()
        return {
            vec(0, 1.5), vec(0.8, 0.5), vec(0.3, 0.5),
            vec(0.3, -1.5), vec(-0.3, -1.5), vec(-0.3, 0.5), vec(-0.8, 0.5)
        }
    end,
    diamond = function()
        return {vec(0, 1.2), vec(0.8, 0), vec(0, -1.2), vec(-0.8, 0)}
    end,
    trapezoid = function()
        return {vec(-0.5, 0.5), vec(0.5, 0.5), vec(1.0, -0.5), vec(-1.0, -0.5)}
    end,
    lshape = function()
        return computeConvexHull({
            vec(-0.5, 1.0), vec(0.0, 1.0), vec(0.0, 0.0),
            vec(1.0, 0.0), vec(1.0, -0.5), vec(-0.5, -0.5)
        })
    end,
    chevron = function()
        return computeConvexHull({
            vec(0, 1.0), vec(0.6, 0.3), vec(0.6, -0.3),
            vec(0, -1.0), vec(-0.6, -0.3), vec(-0.6, 0.3)
        })
    end,
    cross = function()
        return computeConvexHull({
            vec(-0.3, 1.0), vec(0.3, 1.0), vec(0.3, 0.3),
            vec(1.0, 0.3), vec(1.0, -0.3), vec(0.3, -0.3),
            vec(0.3, -1.0), vec(-0.3, -1.0), vec(-0.3, -0.3),
            vec(-1.0, -0.3), vec(-1.0, 0.3), vec(-0.3, 0.3)
        })
    end,
    kite = function()
        return {vec(0, 1.5), vec(0.7, 0.2), vec(0, -0.8), vec(-0.7, 0.2)}
    end,
    parallelogram = function()
        return {vec(-0.3, 0.5), vec(0.7, 0.5), vec(0.3, -0.5), vec(-0.7, -0.5)}
    end,
    shield = function()
        return computeConvexHull({
            vec(-0.8, 0.8), vec(0.8, 0.8), vec(1.0, 0.0),
            vec(0.5, -0.8), vec(0, -1.2), vec(-0.5, -0.8), vec(-1.0, 0.0)
        })
    end
}

-- ============================================================================
-- Scenario 32: Complex polygon collisions
-- ============================================================================

function createComplexPolygonScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(20, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    shapeNames = {"star", "arrow", "diamond", "trapezoid", "lshape",
                        "chevron", "cross", "kite", "parallelogram", "shield"}

    resetRandom()
    for i = 1, #shapeNames do
        verts = D.complexShapes[shapeNames[i]]()
        shape = createPolygon(verts)
        x = -8 + (i - 1) * 1.8
        y = randomRange(5, 12)
        body = createBody(shape, x, y, 2.0, false)
        body.angle = randomRange(0, M.pi)
        body.restitution = 0.3
        worldAddBody(world, body)
    end

    for i = 1, 5 do
        verts = D.complexShapes[shapeNames[i]]()
        shape = createPolygon(verts)
        x = randomRange(-6, 6)
        body = createBody(shape, x, 15 + i, 3.0, false)
        body.velocity = vec(randomRange(-3, 3), -5)
        body.angularVelocity = randomRange(-2, 2)
        worldAddBody(world, body)
    end

    return world
end

-- ============================================================================
-- Continuous rotation angle normalization and angular limit helper
-- ============================================================================

function normalizeAngle(angle)
    while angle > M.pi do angle = angle - 2 * M.pi end
    while angle < -M.pi do angle = angle + 2 * M.pi end
    return angle
end

function clampAngularVelocity(body, maxOmega)
    if body.angularVelocity > maxOmega then
        body.angularVelocity = maxOmega
    else if body.angularVelocity < -maxOmega then
        body.angularVelocity = -maxOmega
    end
end

-- ============================================================================
-- Position correction (separate pass for penetration resolution)
-- ============================================================================

function solvePositionConstraints(manifolds, bodies)
    slop = 0.005
    maxCorrection = 0.2
    baumgarte = 0.4
    corrected = false

    for i = 1, #manifolds do
        m = manifolds[i]
        bodyA = m.bodyA
        bodyB = m.bodyB

        if m.penetration > slop then
            correction = M.min((m.penetration - slop) * baumgarte, maxCorrection)
            totalInvMass = bodyA.invMass + bodyB.invMass
            if totalInvMass > 0 then
                moveA = correction * bodyA.invMass / totalInvMass
                moveB = correction * bodyB.invMass / totalInvMass
                if not bodyA.isStatic then
                    bodyA.position = vecSub(bodyA.position, vecMul(m.normal, moveA))
                end
                if not bodyB.isStatic then
                    bodyB.position = vecAdd(bodyB.position, vecMul(m.normal, moveB))
                end
                corrected = true
            end
        end
    end

    return corrected
end

-- ============================================================================
-- Warm starting (cache impulses between frames)
-- ============================================================================

D.warmStartCache = {}

function getWarmStartKey(idA, idB)
    if idA < idB then return idA * 100000 + idB end
    return idB * 100000 + idA
end

function applyWarmStart(manifold)
    key = getWarmStartKey(manifold.bodyA.id, manifold.bodyB.id)
    cached = D.warmStartCache[key]
    if not cached then return end

    bodyA = manifold.bodyA
    bodyB = manifold.bodyB
    normal = manifold.normal

    for i = 1, M.min(#manifold.contacts, #cached) do
        cp = manifold.contacts[i]
        prev = cached[i]
        if cp.rA and prev.normalImpulse then
            impulse = vecMul(normal, prev.normalImpulse * 0.8)
            bodyA.velocity = vecSub(bodyA.velocity, vecMul(impulse, bodyA.invMass))
            bodyA.angularVelocity = bodyA.angularVelocity - bodyA.invInertia * vecCross(cp.rA, impulse)
            bodyB.velocity = vecAdd(bodyB.velocity, vecMul(impulse, bodyB.invMass))
            bodyB.angularVelocity = bodyB.angularVelocity + bodyB.invInertia * vecCross(cp.rB, impulse)
        end
    end
end

function saveWarmStart(manifold)
    key = getWarmStartKey(manifold.bodyA.id, manifold.bodyB.id)
    data = {}
    for i = 1, #manifold.contacts do
        cp = manifold.contacts[i]
        data[i] = {normalImpulse = cp.normalImpulse, tangentImpulse = cp.tangentImpulse}
    end
    D.warmStartCache[key] = data
end

-- ============================================================================
-- Scenario 33: Large-scale stress test (many bodies, many contacts)
-- ============================================================================

function createStressTestScenario()
    world = createWorld(vec(0, -10), 2.0)
    world.iterations = 8

    ground = createBody(createBox(30, 0.5), 0, -0.5, 1, true)
    ground.staticFriction = 0.8
    worldAddBody(world, ground)

    wallL = createBody(createBox(0.3, 15), -10, 7.5, 1, true)
    worldAddBody(world, wallL)
    wallR = createBody(createBox(0.3, 15), 10, 7.5, 1, true)
    worldAddBody(world, wallR)

    resetRandom()
    for i = 1, 100 do
        x = randomRange(-9, 9)
        y = randomRange(1, 25)
        shapeChoice = M.floor(random() * 4)
        body = null
        if shapeChoice == 0 then
            body = createBody(createCircle(randomRange(0.2, 0.5)), x, y, 2.0, false)
        else if shapeChoice == 1 then
            body = createBody(createBox(randomRange(0.2, 0.6), randomRange(0.2, 0.6)), x, y, 2.0, false)
        else if shapeChoice == 2 then
            body = createBody(createRegularPolygon(randomRange(0.2, 0.5), 5), x, y, 2.0, false)
        else
            body = createBody(createRegularPolygon(randomRange(0.2, 0.5), 6), x, y, 2.0, false)
        end
        body.restitution = randomRange(0.0, 0.4)
        body.dynamicFriction = randomRange(0.3, 0.7)
        body.angle = randomRange(0, M.pi * 2)
        worldAddBody(world, body)
    end

    return world
end

-- ============================================================================
-- Scenario 34: Castle structure (detailed brick placement)
-- ============================================================================

function createCastleScenario()
    world = createWorld(vec(0, -10), 2.5)

    ground = createBody(createBox(40, 1), 0, -1, 1, true)
    ground.staticFriction = 0.9
    worldAddBody(world, ground)

    brickW = 0.6
    brickH = 0.3
    mortar = 0.02

    function placeBrick(x, y, w, h, density, isStatic)
        w = w or brickW
        h = h or brickH
        density = density or 3.0
        isStatic = isStatic or false
        b = createBody(createBox(w, h), x, y, density, isStatic)
        b.restitution = 0.0
        b.staticFriction = 0.75
        b.dynamicFriction = 0.6
        worldAddBody(world, b)
        return b
    end

    towerX = -12
    towerWidth = 4
    towerHeight = 12
    brickPerRow = M.floor(towerWidth / (brickW * 2 + mortar))

    for row = 0, towerHeight - 1 do
        y = 0.3 + row * (brickH * 2 + mortar)
        offset = (row % 2 == 0) and 0 or (brickW + mortar / 2)
        for col = 0, brickPerRow do
            x = towerX - towerWidth / 2 + offset + col * (brickW * 2 + mortar)
            if x >= towerX - towerWidth / 2 and x <= towerX + towerWidth / 2 then
                placeBrick(x, y)
            end
        end
    end

    for row = 0, 3 do
        y = 0.3 + towerHeight * (brickH * 2 + mortar) + row * (brickH * 2 + mortar)
        for col = 0, brickPerRow + 1 do
            x = towerX - towerWidth / 2 - brickW + col * (brickW * 2 + mortar)
            if col % 2 == 0 or row < 2 then
                placeBrick(x, y)
            end
        end
    end

    tower2X = 12
    for row = 0, towerHeight - 1 do
        y = 0.3 + row * (brickH * 2 + mortar)
        offset = (row % 2 == 0) and 0 or (brickW + mortar / 2)
        for col = 0, brickPerRow do
            x = tower2X - towerWidth / 2 + offset + col * (brickW * 2 + mortar)
            if x >= tower2X - towerWidth / 2 and x <= tower2X + towerWidth / 2 then
                placeBrick(x, y)
            end
        end
    end

    for row = 0, 3 do
        y = 0.3 + towerHeight * (brickH * 2 + mortar) + row * (brickH * 2 + mortar)
        for col = 0, brickPerRow + 1 do
            x = tower2X - towerWidth / 2 - brickW + col * (brickW * 2 + mortar)
            if col % 2 == 0 or row < 2 then
                placeBrick(x, y)
            end
        end
    end

    wallStartX = towerX + towerWidth / 2 + brickW
    wallEndX = tower2X - towerWidth / 2 - brickW
    wallHeight = 8
    wallBricksPerRow = M.floor((wallEndX - wallStartX) / (brickW * 2 + mortar))
    for row = 0, wallHeight - 1 do
        y = 0.3 + row * (brickH * 2 + mortar)
        offset = (row % 2 == 0) and 0 or (brickW + mortar / 2)
        for col = 0, wallBricksPerRow do
            x = wallStartX + offset + col * (brickW * 2 + mortar)
            if x <= wallEndX then
                placeBrick(x, y)
            end
        end
    end

    gateX = (towerX + tower2X) / 2
    gateWidth = 3
    gateHeight = 4
    archHeight = wallHeight
    for row = gateHeight, archHeight do
        y = 0.3 + row * (brickH * 2 + mortar)
        rowWidth = gateWidth * (1 - (row - gateHeight) / (archHeight - gateHeight + 1) * 0.3)
        numBricks = M.floor(rowWidth / (brickW * 2 + mortar)) + 1
        for col = 0, numBricks do
            x = gateX - rowWidth / 2 + col * (brickW * 2 + mortar)
            placeBrick(x, y, brickW * 0.8, brickH * 0.8)
        end
    end

    cannonball = createBody(createCircle(0.8), -20, 5, 15.0, false)
    cannonball.velocity = vec(20, 3)
    cannonball.restitution = 0.1
    worldAddBody(world, cannonball)

    return world
end

-- ============================================================================
-- Scenario 35: Clockwork mechanism (many gears and linkages)
-- ============================================================================

function createClockworkScenario()
    world = createWorld(vec(0, 0), 4.0)
    world.gravity = vec(0, 0)

    gears = {}
    pivots = {}
    joints = {}

    gearLayout = {
        {x = 0, y = 0, r = 2.0, teeth = 20, speed = 1.0},
        {x = 3.5, y = 0, r = 1.5, teeth = 15, speed = -1.33},
        {x = 3.5, y = 3.0, r = 1.0, teeth = 10, speed = 2.0},
        {x = 6.0, y = 0, r = 1.2, teeth = 12, speed = 1.67},
        {x = 6.0, y = -2.5, r = 0.8, teeth = 8, speed = -2.5},
        {x = 0, y = -3.5, r = 1.8, teeth = 18, speed = -1.11},
        {x = -3.0, y = -2.0, r = 1.0, teeth = 10, speed = 2.0},
        {x = -3.0, y = 1.5, r = 1.3, teeth = 13, speed = -1.54},
        {x = -5.5, y = 0, r = 0.9, teeth = 9, speed = 2.22},
        {x = 0, y = 4.0, r = 1.6, teeth = 16, speed = -1.25},
        {x = -2.5, y = 4.5, r = 0.7, teeth = 7, speed = 2.86},
        {x = 2.5, y = 4.0, r = 1.1, teeth = 11, speed = 1.82},
    }

    for i = 1, #gearLayout do
        gl = gearLayout[i]
        gear = createBody(createRegularPolygon(gl.r, gl.teeth), gl.x, gl.y, 3.0, false)
        gear.angularDamping = 0.01
        gear.linearDamping = 10
        worldAddBody(world, gear)
        gears[i] = gear

        pivot = createBody(createCircle(0.1), gl.x, gl.y, 1, true)
        worldAddBody(world, pivot)
        pivots[i] = pivot

        joint = createRevoluteJoint(pivot, gear, vec(0, 0), vec(0, 0))
        if i == 1 then
            joint.motorEnabled = true
            joint.motorSpeed = gl.speed * 3
            joint.maxMotorTorque = 200
        end
        worldAddJoint(world, joint)
        joints[i] = joint
    end

    gearConnections = {
        {1, 2}, {2, 3}, {2, 4}, {4, 5}, {1, 6}, {6, 7}, {1, 8}, {8, 9},
        {1, 10}, {10, 11}, {10, 12}
    }

    for i = 1, #gearConnections do
        conn = gearConnections[i]
        a = conn[1]
        b = conn[2]
        ratio = -gearLayout[a].r / gearLayout[b].r
        gj = createGearJoint(joints[a], joints[b], ratio)
        worldAddJoint(world, gj)
    end

    crankGear = gears[5]
    crankLength = 2.0
    crankArm = createBody(createBox(crankLength / 2, 0.1), gearLayout[5].x + crankLength / 2, gearLayout[5].y, 1.5, false)
    worldAddBody(world, crankArm)
    crankJoint = createRevoluteJoint(crankGear, crankArm, vec(0.6, 0), vec(-crankLength / 2, 0))
    worldAddJoint(world, crankJoint)

    piston = createBody(createBox(0.3, 0.5), gearLayout[5].x + crankLength + 1, gearLayout[5].y, 2.0, false)
    worldAddBody(world, piston)
    pistonJoint = createRevoluteJoint(crankArm, piston, vec(crankLength / 2, 0), vec(0, 0))
    worldAddJoint(world, pistonJoint)

    guide = createBody(createBox(0.1, 2), gearLayout[5].x + crankLength + 1, gearLayout[5].y, 1, true)
    worldAddBody(world, guide)
    slideJoint = createPrismaticJoint(guide, piston, vec(0, 0), vec(0, 0), vec(0, 1))
    worldAddJoint(world, slideJoint)

    escapementWheel = createBody(createRegularPolygon(1.5, 15), -6, -4, 4.0, false)
    escapementWheel.angularDamping = 0.01
    worldAddBody(world, escapementWheel)
    escPivot = createBody(createCircle(0.1), -6, -4, 1, true)
    worldAddBody(world, escPivot)
    escJoint = createRevoluteJoint(escPivot, escapementWheel, vec(0, 0), vec(0, 0))
    escJoint.motorEnabled = true
    escJoint.motorSpeed = 0.5
    escJoint.maxMotorTorque = 10
    worldAddJoint(world, escJoint)

    pendulumLength = 4
    pendulumBob = createBody(createCircle(0.4), -6, -4 - pendulumLength, 5.0, false)
    worldAddBody(world, pendulumBob)
    pendJoint = createDistanceJoint(escPivot, pendulumBob, vec(0, 0), vec(0, 0), pendulumLength)
    pendJoint.stiffness = 500
    pendJoint.damping = 0.5
    worldAddJoint(world, pendJoint)

    pendulumBob.position = vec(-6 + 1.5, -4 - pendulumLength + 0.5)

    return world
end

-- ============================================================================
-- Scenario 36: Trebuchet with projectile arc
-- ============================================================================

function createTrebuchetScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(40, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    baseX = -15
    baseY = 0

    frameLeft = createBody(createBox(0.2, 3), baseX - 1.5, baseY + 3, 1, true)
    worldAddBody(world, frameLeft)
    frameRight = createBody(createBox(0.2, 3), baseX + 1.5, baseY + 3, 1, true)
    worldAddBody(world, frameRight)
    frameTop = createBody(createBox(2, 0.2), baseX, baseY + 6.2, 1, true)
    worldAddBody(world, frameTop)

    armLength = 8
    armPivotRatio = 0.3
    arm = createBody(createBox(armLength / 2, 0.15), baseX, baseY + 6, 3.0, false)
    worldAddBody(world, arm)

    armPivot = createRevoluteJoint(frameTop, arm, vec(0, 0),
        vec(-armLength / 2 + armLength * armPivotRatio, 0))
    worldAddJoint(world, armPivot)

    counterweightMass = 30
    cwX = baseX - armLength * (1 - armPivotRatio) + armLength * armPivotRatio
    counterweight = createBody(createBox(0.8, 0.8), cwX, baseY + 5, counterweightMass, false)
    worldAddBody(world, counterweight)
    cwRope = createDistanceJoint(arm, counterweight,
        vec(-armLength / 2 + armLength * armPivotRatio - 1, 0), vec(0, 0.4), 1.0)
    cwRope.stiffness = 500
    cwRope.damping = 5
    worldAddJoint(world, cwRope)

    projX = baseX + armLength * (1 - armPivotRatio) - 0.5
    projectile = createBody(createCircle(0.3), projX, baseY + 1, 2.0, false)
    projectile.restitution = 0.3
    worldAddBody(world, projectile)

    slingLength = 3
    slingJoint = createRopeJoint(arm, projectile,
        vec(armLength / 2 - armLength * armPivotRatio, 0), vec(0, 0), slingLength)
    worldAddJoint(world, slingJoint)

    arm.angle = 0.5
    arm.angularVelocity = -2

    targetX = 15
    for row = 0, 5 do
        for col = 0, 4 do
            x = targetX + col * 0.7
            y = 0.25 + row * 0.5
            target = createBody(createBox(0.3, 0.2), x, y, 1.5, false)
            target.restitution = 0.05
            target.staticFriction = 0.6
            worldAddBody(world, target)
        end
    end

    return world
end

-- ============================================================================
-- Scenario 37: Fluid-like particle simulation (SPH-inspired)
-- ============================================================================

function createFluidScenario()
    world = createWorld(vec(0, -10), 1.5)

    containerW = 8
    containerH = 10

    bottom = createBody(createBox(containerW / 2, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, bottom)
    leftW = createBody(createBox(0.3, containerH / 2), -containerW / 2 - 0.3, containerH / 2, 1, true)
    worldAddBody(world, leftW)
    rightW = createBody(createBox(0.3, containerH / 2), containerW / 2 + 0.3, containerH / 2, 1, true)
    worldAddBody(world, rightW)

    obstacleVerts = {vec(-1.5, -0.3), vec(1.5, 0.3), vec(1.5, -0.3)}
    obstacle = createBody(createPolygon(obstacleVerts), 0, 5, 1, true)
    worldAddBody(world, obstacle)

    particleRadius = 0.2
    particleSpacing = particleRadius * 2.2
    startX = -containerW / 2 + 1
    startY = 7

    resetRandom()
    for row = 0, 11 do
        for col = 0, 11 do
            x = startX + col * particleSpacing + randomRange(-0.02, 0.02)
            y = startY + row * particleSpacing + randomRange(-0.02, 0.02)
            p = createBody(createCircle(particleRadius), x, y, 1.0, false)
            p.restitution = 0.0
            p.dynamicFriction = 0.1
            p.linearDamping = 0.3
            worldAddBody(world, p)
        end
    end

    return world
end

-- ============================================================================
-- Scenario 38: Windmill with blades and falling objects
-- ============================================================================

function createWindmillScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(20, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    towerBase = createBody(createBox(1.5, 4), 0, 4, 1, true)
    worldAddBody(world, towerBase)

    hubX = 0
    hubY = 9
    hub = createBody(createCircle(0.3), hubX, hubY, 5.0, false)
    hub.angularDamping = 0.02
    worldAddBody(world, hub)

    hubPivot = createBody(createCircle(0.1), hubX, hubY, 1, true)
    worldAddBody(world, hubPivot)
    hubJoint = createRevoluteJoint(hubPivot, hub, vec(0, 0), vec(0, 0))
    hubJoint.motorEnabled = true
    hubJoint.motorSpeed = 3
    hubJoint.maxMotorTorque = 50
    worldAddJoint(world, hubJoint)

    numBlades = 4
    bladeLength = 3.5
    bladeWidth = 0.15
    for i = 1, numBlades do
        angle = (i - 1) * M.pi * 2 / numBlades
        bladeX = hubX + (bladeLength / 2 + 0.3) * M.cos(angle)
        bladeY = hubY + (bladeLength / 2 + 0.3) * M.sin(angle)
        blade = createBody(createBox(bladeLength / 2, bladeWidth), bladeX, bladeY, 2.0, false)
        blade.angle = angle
        worldAddBody(world, blade)

        wj = createWeldJoint(hub, blade,
            vec(0.3 * M.cos(angle), 0.3 * M.sin(angle)),
            vec(-bladeLength / 2, 0))
        worldAddJoint(world, wj)
    end

    resetRandom()
    for i = 1, 20 do
        x = randomRange(-8, 8)
        y = randomRange(14, 22)
        sc = M.floor(random() * 3)
        body = null
        if sc == 0 then
            body = createBody(createCircle(randomRange(0.2, 0.4)), x, y, 2.0, false)
        else if sc == 1 then
            body = createBody(createBox(randomRange(0.2, 0.5), randomRange(0.2, 0.5)), x, y, 2.0, false)
        else
            body = createBody(createRegularPolygon(randomRange(0.2, 0.4), 5), x, y, 2.0, false)
        end
        body.restitution = 0.3
        worldAddBody(world, body)
    end

    return world
end

-- ============================================================================
-- Scenario 39: Multi-body vehicle (car with suspension)
-- ============================================================================

function createDetailedVehicleScenario()
    world = createWorld(vec(0, -10), 3.0)

    terrainSegs = {
        {x = -20, y = 0}, {x = -15, y = 0}, {x = -10, y = 0.5}, {x = -5, y = 0.3},
        {x = 0, y = 0}, {x = 5, y = -0.2}, {x = 8, y = 0.5}, {x = 10, y = 1.5},
        {x = 12, y = 2.0}, {x = 14, y = 1.8}, {x = 16, y = 1.0}, {x = 18, y = 0.5},
        {x = 20, y = 0}, {x = 25, y = 0},
    }

    for i = 1, #terrainSegs - 1 do
        p1 = terrainSegs[i]
        p2 = terrainSegs[i + 1]
        midX = (p1.x + p2.x) / 2
        midY = (p1.y + p2.y) / 2
        dx = p2.x - p1.x
        dy = p2.y - p1.y
        len = M.sqrt(dx * dx + dy * dy)
        seg = createBody(createBox(len / 2, 0.3), midX, midY - 0.3, 1, true)
        seg.angle = M.atan2(dy, dx)
        seg.staticFriction = 0.9
        worldAddBody(world, seg)
    end

    carX = -18
    carY = 2

    chassis = createBody(createPolygon({
        vec(-2.0, -0.3), vec(-1.8, 0.3), vec(-0.5, 0.5),
        vec(1.5, 0.5), vec(2.0, 0.2), vec(2.0, -0.3)
    }), carX, carY, 4.0, false)
    chassis.linearDamping = 0.05
    worldAddBody(world, chassis)

    fenderFront = createBody(createBox(0.6, 0.15), carX + 1.8, carY - 0.1, 1.0, false)
    worldAddBody(world, fenderFront)
    fwj = createWeldJoint(chassis, fenderFront, vec(1.8, -0.1), vec(0, 0))
    worldAddJoint(world, fwj)

    fenderRear = createBody(createBox(0.6, 0.15), carX - 1.6, carY - 0.1, 1.0, false)
    worldAddBody(world, fenderRear)
    rwj = createWeldJoint(chassis, fenderRear, vec(-1.6, -0.1), vec(0, 0))
    worldAddJoint(world, rwj)

    wheelR = 0.45
    wheelDensity = 3.0

    frontWheel = createBody(createCircle(wheelR), carX + 1.5, carY - 0.8, wheelDensity, false)
    frontWheel.dynamicFriction = 0.9
    frontWheel.restitution = 0.1
    worldAddBody(world, frontWheel)

    rearWheel = createBody(createCircle(wheelR), carX - 1.5, carY - 0.8, wheelDensity, false)
    rearWheel.dynamicFriction = 0.9
    rearWheel.restitution = 0.1
    worldAddBody(world, rearWheel)

    fwJoint = createWheelJoint(chassis, frontWheel,
        vec(1.5, -0.5), vec(0, 0), vec(0, 1))
    fwJoint.springStiffness = 100
    fwJoint.springDamping = 10
    worldAddJoint(world, fwJoint)

    rwJoint = createWheelJoint(chassis, rearWheel,
        vec(-1.5, -0.5), vec(0, 0), vec(0, 1))
    rwJoint.springStiffness = 100
    rwJoint.springDamping = 10
    rwJoint.motorEnabled = true
    rwJoint.motorSpeed = -20
    rwJoint.maxMotorTorque = 80
    worldAddJoint(world, rwJoint)

    return world
end

-- ============================================================================
-- Scenario 40: Bowling alley
-- ============================================================================

function createBowlingScenario()
    world = createWorld(vec(0, -10), 3.0)

    laneLength = 25
    laneWidth = 3
    lane = createBody(createBox(laneLength / 2, 0.3), 0, -0.3, 1, true)
    lane.staticFriction = 0.2
    lane.dynamicFriction = 0.1
    worldAddBody(world, lane)

    gutterL = createBody(createBox(laneLength / 2, 0.15), 0, 0, 1, true)
    gutterL.angle = 0
    worldAddBody(world, gutterL)

    backwall = createBody(createBox(laneWidth, 0.3), laneLength / 2 - 0.5, 1, 1, true)
    backwall.restitution = 0.3
    worldAddBody(world, backwall)

    pinRadius = 0.15
    pinHeight = 0.5
    pinDensity = 2.0
    pinSpacing = pinRadius * 3.5
    pinStartX = laneLength / 2 - 3
    pinStartY = 0.5

    pinPositions = {}
    for row = 0, 3 do
        for col = 0, row do
            x = pinStartX + row * pinSpacing * 0.866
            y = pinStartY + (col - row / 2) * pinSpacing
            pinPositions[#pinPositions + 1] = {x = x, y = y}
        end
    end

    for i = 1, #pinPositions do
        pp = pinPositions[i]
        pin = createBody(createBox(pinRadius, pinHeight / 2), pp.x, pp.y + pinHeight / 2, pinDensity, false)
        pin.restitution = 0.3
        pin.staticFriction = 0.5
        worldAddBody(world, pin)
    end

    ballRadius = 0.35
    ball = createBody(createCircle(ballRadius), -laneLength / 2 + 2, 0.35, 7.0, false)
    ball.velocity = vec(12, 0.3)
    ball.angularVelocity = -5
    ball.restitution = 0.2
    ball.dynamicFriction = 0.05
    worldAddBody(world, ball)

    return world
end

-- ============================================================================
-- Scenario 41: Earthquake simulation (shaking ground)
-- ============================================================================

function createEarthquakeScenario()
    world = createWorld(vec(0, -10), 2.5)

    ground = createBody(createBox(25, 0.5), 0, -0.5, 1, true)
    ground.staticFriction = 0.7
    worldAddBody(world, ground)

    buildingX = -8
    buildingFloors = 6
    buildingWidth = 4
    floorHeight = 1.2
    columnWidth = 0.2
    columnHeight = floorHeight / 2 - 0.1

    for floor = 0, buildingFloors - 1 do
        baseY = floor * floorHeight + 0.5

        leftCol = createBody(createBox(columnWidth, columnHeight),
            buildingX - buildingWidth / 2 + columnWidth, baseY + columnHeight, 4.0, false)
        leftCol.staticFriction = 0.6
        worldAddBody(world, leftCol)

        rightCol = createBody(createBox(columnWidth, columnHeight),
            buildingX + buildingWidth / 2 - columnWidth, baseY + columnHeight, 4.0, false)
        rightCol.staticFriction = 0.6
        worldAddBody(world, rightCol)

        midCol = createBody(createBox(columnWidth, columnHeight),
            buildingX, baseY + columnHeight, 4.0, false)
        midCol.staticFriction = 0.6
        worldAddBody(world, midCol)

        slab = createBody(createBox(buildingWidth / 2 + 0.2, 0.1),
            buildingX, baseY + floorHeight - 0.1, 5.0, false)
        slab.staticFriction = 0.6
        worldAddBody(world, slab)
    end

    tower2X = 5
    towerFloors = 8
    towerWidth = 2.5

    for floor = 0, towerFloors - 1 do
        baseY = floor * 1.0 + 0.5
        leftCol = createBody(createBox(0.15, 0.4),
            tower2X - towerWidth / 2 + 0.15, baseY + 0.4, 4.0, false)
        leftCol.staticFriction = 0.6
        worldAddBody(world, leftCol)

        rightCol = createBody(createBox(0.15, 0.4),
            tower2X + towerWidth / 2 - 0.15, baseY + 0.4, 4.0, false)
        rightCol.staticFriction = 0.6
        worldAddBody(world, rightCol)

        slab = createBody(createBox(towerWidth / 2, 0.08),
            tower2X, baseY + 0.88, 3.0, false)
        slab.staticFriction = 0.6
        worldAddBody(world, slab)
    end

    return world
end

-- ============================================================================
-- Scenario 42: Pachinko machine (many pegs, falling balls)
-- ============================================================================

function createPachinkoScenario()
    world = createWorld(vec(0, -8), 2.0)

    boardW = 12
    boardH = 18
    pegRadius = 0.2
    pegSpacing = 1.2

    leftWall = createBody(createBox(0.3, boardH / 2), -boardW / 2 - 0.3, boardH / 2, 1, true)
    worldAddBody(world, leftWall)
    rightWall = createBody(createBox(0.3, boardH / 2), boardW / 2 + 0.3, boardH / 2, 1, true)
    worldAddBody(world, rightWall)
    bottom = createBody(createBox(boardW / 2, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, bottom)

    numRows = M.floor(boardH / pegSpacing) - 2
    for row = 0, numRows - 1 do
        y = boardH - 2 - row * pegSpacing
        numPegs = M.floor(boardW / pegSpacing) - 1
        offset = (row % 2 == 0) and 0 or (pegSpacing / 2)
        for col = 0, numPegs - 1 do
            x = -boardW / 2 + pegSpacing + offset + col * pegSpacing
            if x > -boardW / 2 + 0.5 and x < boardW / 2 - 0.5 then
                peg = createBody(createCircle(pegRadius), x, y, 1, true)
                peg.restitution = 0.5
                worldAddBody(world, peg)
            end
        end
    end

    numSlots = 8
    slotWidth = boardW / numSlots
    for i = 1, numSlots - 1 do
        x = -boardW / 2 + i * slotWidth
        divider = createBody(createBox(0.1, 0.8), x, 0.8, 1, true)
        worldAddBody(world, divider)
    end

    resetRandom()
    ballRadius = 0.25
    for i = 1, 15 do
        x = randomRange(-boardW / 2 + 1, boardW / 2 - 1)
        y = boardH + i * 0.6
        ball = createBody(createCircle(ballRadius), x, y, 3.0, false)
        ball.restitution = 0.4
        ball.dynamicFriction = 0.1
        worldAddBody(world, ball)
    end

    return world
end

-- ============================================================================
-- Scenario 43: Spring lattice (many interconnected springs)
-- ============================================================================

function createSpringLatticeScenario()
    world = createWorld(vec(0, -5), 2.0)

    cols = 8
    rows = 8
    spacing = 1.2
    startX = -(cols - 1) * spacing / 2
    startY = 5

    ground = createBody(createBox(15, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, ground)

    nodes = {}
    for r = 0, rows - 1 do
        nodes[r] = {}
        for c = 0, cols - 1 do
            x = startX + c * spacing
            y = startY + r * spacing
            isFixed = (r == rows - 1) and (c == 0 or c == cols - 1)
            node = createBody(createCircle(0.15), x, y, 1.5, isFixed)
            node.linearDamping = 0.2
            worldAddBody(world, node)
            nodes[r][c] = node
        end
    end

    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            if c < cols - 1 then
                j = createDistanceJoint(nodes[r][c], nodes[r][c + 1],
                    vec(0, 0), vec(0, 0), spacing)
                j.stiffness = 80
                j.damping = 3
                worldAddJoint(world, j)
            end
            if r < rows - 1 then
                j = createDistanceJoint(nodes[r][c], nodes[r + 1][c],
                    vec(0, 0), vec(0, 0), spacing)
                j.stiffness = 80
                j.damping = 3
                worldAddJoint(world, j)
            end
            if c < cols - 1 and r < rows - 1 then
                diagDist = spacing * 1.414
                j = createDistanceJoint(nodes[r][c], nodes[r + 1][c + 1],
                    vec(0, 0), vec(0, 0), diagDist)
                j.stiffness = 40
                j.damping = 2
                worldAddJoint(world, j)
            end
        end
    end

    impactBall = createBody(createCircle(0.8), 0, startY + rows * spacing + 3, 10.0, false)
    impactBall.velocity = vec(0, -8)
    impactBall.restitution = 0.5
    worldAddBody(world, impactBall)

    return world
end

-- ============================================================================
-- Scenario 44: Cannon with multiple projectiles
-- ============================================================================

function createCannonScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(35, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    targetWallX = 15
    wallRows = 10
    wallCols = 5
    for row = 0, wallRows - 1 do
        for col = 0, wallCols - 1 do
            x = targetWallX + col * 0.65
            y = 0.3 + row * 0.5
            brick = createBody(createBox(0.3, 0.2), x, y, 2.5, false)
            brick.restitution = 0.05
            brick.staticFriction = 0.6
            worldAddBody(world, brick)
        end
    end

    cannonX = -15
    cannonY = 2
    cannonAngle = 0.5

    resetRandom()
    numProjectiles = 8
    for i = 1, numProjectiles do
        speed = randomRange(18, 25)
        angle = cannonAngle + randomRange(-0.1, 0.1)
        delay = (i - 1) * 0.3
        vx = speed * M.cos(angle)
        vy = speed * M.sin(angle)
        startX = cannonX + vx * delay
        startY = cannonY + vy * delay - 0.5 * 10 * delay * delay

        proj = createBody(createCircle(0.3), startX, startY, 8.0, false)
        proj.velocity = vec(vx, vy - 10 * delay)
        proj.restitution = 0.2
        worldAddBody(world, proj)
    end

    return world
end

-- ============================================================================
-- Scenario 45: Wrecking yard (heavy machinery + debris)
-- ============================================================================

function createWreckingYardScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(30, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    resetRandom()
    debrisCount = 50
    for i = 1, debrisCount do
        x = randomRange(-15, 15)
        y = randomRange(0.5, 2)
        sc = M.floor(random() * 4)
        body = null
        if sc == 0 then
            body = createBody(createCircle(randomRange(0.1, 0.4)), x, y, randomRange(1, 5), false)
        else if sc == 1 then
            body = createBody(createBox(randomRange(0.2, 0.8), randomRange(0.1, 0.4)), x, y, randomRange(1, 5), false)
        else if sc == 2 then
            body = createBody(createRegularPolygon(randomRange(0.2, 0.5), 5), x, y, randomRange(1, 5), false)
        else
            body = createBody(createRegularPolygon(randomRange(0.2, 0.5), 3), x, y, randomRange(1, 5), false)
        end
        body.restitution = randomRange(0.0, 0.3)
        body.staticFriction = randomRange(0.4, 0.8)
        worldAddBody(world, body)
    end

    craneX = 0
    craneY = 15
    craneBase = createBody(createBox(1, 0.5), craneX, craneY, 1, true)
    worldAddBody(world, craneBase)

    numCableLinks = 6
    linkLen = 1.5
    prevLink = craneBase
    for i = 1, numCableLinks do
        link = createBody(createBox(0.1, linkLen / 2 - 0.05),
            craneX, craneY - i * linkLen, 1.0, false)
        link.angularDamping = 0.2
        worldAddBody(world, link)
        j = createRevoluteJoint(prevLink, link,
            vec(0, i == 1 and -0.5 or -linkLen / 2 + 0.05), vec(0, linkLen / 2 - 0.05))
        worldAddJoint(world, j)
        prevLink = link
    end

    wreckingBall = createBody(createCircle(1.5), craneX, craneY - numCableLinks * linkLen - 1.5, 25.0, false)
    wreckingBall.restitution = 0.2
    worldAddBody(world, wreckingBall)
    bj = createRevoluteJoint(prevLink, wreckingBall, vec(0, -linkLen / 2), vec(0, 0.5))
    worldAddJoint(world, bj)

    wreckingBall.velocity = vec(8, -5)

    return world
end

-- ============================================================================
-- Cubic Bezier Spline system (for path-based scenarios)
-- ============================================================================

function bezierPoint(p0, p1, p2, p3, t)
    u = 1 - t
    uu = u * u
    uuu = uu * u
    tt = t * t
    ttt = tt * t
    return vec(
        uuu * p0.x + 3 * uu * t * p1.x + 3 * u * tt * p2.x + ttt * p3.x,
        uuu * p0.y + 3 * uu * t * p1.y + 3 * u * tt * p2.y + ttt * p3.y
    )
end

function bezierTangent(p0, p1, p2, p3, t)
    u = 1 - t
    uu = u * u
    tt = t * t
    return vec(
        3 * uu * (p1.x - p0.x) + 6 * u * t * (p2.x - p1.x) + 3 * tt * (p3.x - p2.x),
        3 * uu * (p1.y - p0.y) + 6 * u * t * (p2.y - p1.y) + 3 * tt * (p3.y - p2.y)
    )
end

function bezierLength(p0, p1, p2, p3, segments)
    segments = segments or 20
    len = 0
    prev = p0
    for i = 1, segments do
        t = i / segments
        curr = bezierPoint(p0, p1, p2, p3, t)
        len = len + vecDist(prev, curr)
        prev = curr
    end
    return len
end

function createSpline(controlPoints)
    spline = {
        points = controlPoints,
        numSegments = M.floor((#controlPoints - 1) / 3)
    }
    return spline
end

function splinePointAt(spline, t)
    seg = M.floor(t * spline.numSegments)
    if seg >= spline.numSegments then seg = spline.numSegments - 1 end
    localT = t * spline.numSegments - seg
    base = seg * 3 + 1
    return bezierPoint(
        spline.points[base], spline.points[base + 1],
        spline.points[base + 2], spline.points[base + 3], localT)
end

function splineTangentAt(spline, t)
    seg = M.floor(t * spline.numSegments)
    if seg >= spline.numSegments then seg = spline.numSegments - 1 end
    localT = t * spline.numSegments - seg
    base = seg * 3 + 1
    return vecNormalize(bezierTangent(
        spline.points[base], spline.points[base + 1],
        spline.points[base + 2], spline.points[base + 3], localT))
end

-- ============================================================================
-- Predefined track splines for scenarios
-- ============================================================================

D.trackSplines = {
    oval = createSpline({
        vec(-10, 0), vec(-10, 5), vec(-5, 8), vec(0, 8),
        vec(0, 8), vec(5, 8), vec(10, 5), vec(10, 0),
        vec(10, 0), vec(10, -5), vec(5, -8), vec(0, -8),
        vec(0, -8), vec(-5, -8), vec(-10, -5), vec(-10, 0),
    }),
    figure8 = createSpline({
        vec(0, 0), vec(3, 3), vec(6, 5), vec(8, 3),
        vec(8, 3), vec(10, 1), vec(8, -2), vec(5, -3),
        vec(5, -3), vec(2, -4), vec(-2, -4), vec(-5, -3),
        vec(-5, -3), vec(-8, -2), vec(-10, 1), vec(-8, 3),
        vec(-8, 3), vec(-6, 5), vec(-3, 3), vec(0, 0),
    }),
    roller = createSpline({
        vec(-15, 5), vec(-12, 5), vec(-10, 10), vec(-8, 10),
        vec(-8, 10), vec(-6, 10), vec(-4, 3), vec(-2, 3),
        vec(-2, 3), vec(0, 3), vec(2, 8), vec(4, 8),
        vec(4, 8), vec(6, 8), vec(8, 2), vec(10, 2),
        vec(10, 2), vec(12, 2), vec(14, 6), vec(15, 5),
    }),
}

-- ============================================================================
-- Scenario 46: Race track (bodies following spline path)
-- ============================================================================

function createRaceTrackScenario()
    world = createWorld(vec(0, -10), 4.0)

    spline = D.trackSplines.oval
    numSegments = 40
    trackWidth = 1.5

    for i = 0, numSegments - 1 do
        t1 = i / numSegments
        t2 = (i + 1) / numSegments
        p1 = splinePointAt(spline, t1)
        p2 = splinePointAt(spline, t2)
        mid = vecLerp(p1, p2, 0.5)
        dx = p2.x - p1.x
        dy = p2.y - p1.y
        len = M.sqrt(dx * dx + dy * dy)
        angle = M.atan2(dy, dx)

        seg = createBody(createBox(len / 2 + 0.1, 0.2), mid.x, mid.y, 1, true)
        seg.angle = angle
        seg.staticFriction = 0.9
        worldAddBody(world, seg)

        tangent = vecNormalize(vec(dx, dy))
        normal = vecPerp(tangent)
        wallInner = createBody(createBox(len / 2, 0.1),
            mid.x - normal.x * trackWidth, mid.y - normal.y * trackWidth, 1, true)
        wallInner.angle = angle
        wallInner.restitution = 0.5
        worldAddBody(world, wallInner)

        wallOuter = createBody(createBox(len / 2, 0.1),
            mid.x + normal.x * trackWidth, mid.y + normal.y * trackWidth, 1, true)
        wallOuter.angle = angle
        wallOuter.restitution = 0.5
        worldAddBody(world, wallOuter)
    end

    for i = 1, 4 do
        t = (i - 1) * 0.25
        pos = splinePointAt(spline, t)
        car = createBody(createBox(0.6, 0.3), pos.x, pos.y + 0.5, 3.0, false)
        car.dynamicFriction = 0.4
        car.restitution = 0.3
        tang = splineTangentAt(spline, t)
        car.velocity = vecMul(tang, 8 + i * 2)
        worldAddBody(world, car)
    end

    return world
end

-- ============================================================================
-- Scenario 47: Roller coaster track
-- ============================================================================

function createRollerCoasterScenario()
    world = createWorld(vec(0, -10), 3.0)

    spline = D.trackSplines.roller
    numRailSegs = 50

    for i = 0, numRailSegs - 1 do
        t1 = i / numRailSegs
        t2 = (i + 1) / numRailSegs
        p1 = splinePointAt(spline, t1)
        p2 = splinePointAt(spline, t2)
        mid = vecLerp(p1, p2, 0.5)
        dx = p2.x - p1.x
        dy = p2.y - p1.y
        len = M.sqrt(dx * dx + dy * dy)
        angle = M.atan2(dy, dx)

        rail = createBody(createBox(len / 2 + 0.05, 0.1), mid.x, mid.y, 1, true)
        rail.angle = angle
        rail.restitution = 0.1
        rail.staticFriction = 0.05
        worldAddBody(world, rail)
    end

    for i = 0, 9 do
        t = i / 50
        pos = splinePointAt(spline, t)
        support = createBody(createBox(0.1, pos.y / 2), pos.x, pos.y / 2 - 0.5, 1, true)
        worldAddBody(world, support)
    end

    ground = createBody(createBox(20, 0.3), 0, -0.8, 1, true)
    worldAddBody(world, ground)

    startPos = splinePointAt(spline, 0)
    cart = createBody(createBox(0.8, 0.3), startPos.x, startPos.y + 0.5, 5.0, false)
    cart.dynamicFriction = 0.02
    cart.restitution = 0.2
    tang = splineTangentAt(spline, 0)
    cart.velocity = vecMul(tang, 12)
    worldAddBody(world, cart)

    return world
end

-- ============================================================================
-- Scenario 48: Destruction derby (cars crashing)
-- ============================================================================

function createDestructionDerbyScenario()
    world = createWorld(vec(0, -10), 4.0)

    arenaRadius = 12
    numWallSegs = 24
    for i = 0, numWallSegs - 1 do
        a1 = i * 2 * M.pi / numWallSegs
        a2 = (i + 1) * 2 * M.pi / numWallSegs
        p1 = vec(arenaRadius * M.cos(a1), arenaRadius * M.sin(a1))
        p2 = vec(arenaRadius * M.cos(a2), arenaRadius * M.sin(a2))
        mid = vecLerp(p1, p2, 0.5)
        dx = p2.x - p1.x
        dy = p2.y - p1.y
        len = M.sqrt(dx * dx + dy * dy)
        angle = M.atan2(dy, dx)
        wall = createBody(createBox(len / 2, 0.4), mid.x, mid.y, 1, true)
        wall.angle = angle
        wall.restitution = 0.5
        worldAddBody(world, wall)
    end

    ground = createBody(createBox(arenaRadius, 0.3), 0, -arenaRadius - 0.3, 1, true)
    worldAddBody(world, ground)

    numCars = 8
    for i = 1, numCars do
        angle = (i - 1) * 2 * M.pi / numCars
        radius = 8
        x = radius * M.cos(angle)
        y = radius * M.sin(angle)

        car = createBody(createBox(1.2, 0.5), x, y, 5.0, false)
        car.angle = angle + M.pi
        car.restitution = 0.4
        car.dynamicFriction = 0.5

        speed = 10
        car.velocity = vec(-speed * M.cos(angle), -speed * M.sin(angle))
        worldAddBody(world, car)

        frontBumper = createBody(createBox(0.15, 0.55), x + 1.3 * M.cos(angle + M.pi), y + 1.3 * M.sin(angle + M.pi), 3.0, false)
        frontBumper.restitution = 0.6
        worldAddBody(world, frontBumper)
    end

    obstacles = {
        {x = 0, y = 0, r = 1.0}, {x = 3, y = 3, r = 0.6},
        {x = -3, y = 3, r = 0.6}, {x = 3, y = -3, r = 0.6},
        {x = -3, y = -3, r = 0.6},
    }
    for i = 1, #obstacles do
        o = obstacles[i]
        obs = createBody(createCircle(o.r), o.x, o.y, 1, true)
        obs.restitution = 0.7
        worldAddBody(world, obs)
    end

    return world
end

-- ============================================================================
-- Scenario 49: Assembly line (conveyor + sorting)
-- ============================================================================

function createAssemblyLineScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(30, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, ground)

    belts = {
        {x = -12, y = 2, w = 5, angle = 0, speed = 3},
        {x = -4, y = 2, w = 4, angle = -0.15, speed = 2},
        {x = 3, y = 1.5, w = 4, angle = 0, speed = 3.5},
        {x = 10, y = 1.5, w = 4, angle = 0.1, speed = 2.5},
    }

    for i = 1, #belts do
        b = belts[i]
        belt = createBody(createBox(b.w / 2, 0.15), b.x, b.y, 1, true)
        belt.angle = b.angle
        belt.dynamicFriction = 0.8
        worldAddBody(world, belt)

        lipL = createBody(createBox(0.1, 0.2), b.x - b.w / 2 - 0.1, b.y + 0.2, 1, true)
        worldAddBody(world, lipL)
        lipR = createBody(createBox(0.1, 0.2), b.x + b.w / 2 + 0.1, b.y + 0.2, 1, true)
        worldAddBody(world, lipR)
    end

    sorterX = 6
    sorterY = 4
    sorterArm = createBody(createBox(1.5, 0.1), sorterX, sorterY, 2.0, false)
    worldAddBody(world, sorterArm)
    sorterPivot = createBody(createCircle(0.1), sorterX, sorterY, 1, true)
    worldAddBody(world, sorterPivot)
    sj = createRevoluteJoint(sorterPivot, sorterArm, vec(0, 0), vec(0, 0))
    sj.motorEnabled = true
    sj.motorSpeed = 2
    sj.maxMotorTorque = 20
    worldAddJoint(world, sj)

    resetRandom()
    for i = 1, 25 do
        x = -15 + randomRange(-1, 1)
        y = 4 + i * 0.8
        choice = M.floor(random() * 4)
        body = null
        if choice == 0 then
            body = createBody(createCircle(randomRange(0.2, 0.4)), x, y, 2.0, false)
        else if choice == 1 then
            body = createBody(createBox(0.3, 0.3), x, y, 2.0, false)
        else if choice == 2 then
            body = createBody(createRegularPolygon(0.3, 5), x, y, 2.0, false)
        else
            body = createBody(createRegularPolygon(0.25, 3), x, y, 2.0, false)
        end
        body.restitution = 0.2
        body.dynamicFriction = 0.3
        worldAddBody(world, body)
    end

    return world
end

-- ============================================================================
-- Scenario 50: Suspension bridge with traffic
-- ============================================================================

function createSuspensionBridgeScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(35, 0.5), 0, -0.5, 1, true)
    worldAddBody(world, ground)

    bridgeLength = 24
    bridgeY = 8
    numDeckSegs = 20
    segWidth = bridgeLength / numDeckSegs
    startX = -bridgeLength / 2

    leftTower = createBody(createBox(0.5, 5), startX - 1, bridgeY + 2.5, 1, true)
    worldAddBody(world, leftTower)
    rightTower = createBody(createBox(0.5, 5), -startX + 1, bridgeY + 2.5, 1, true)
    worldAddBody(world, rightTower)

    leftAnchor = createBody(createBox(0.3, 0.3), startX - 1, bridgeY + 5.5, 1, true)
    worldAddBody(world, leftAnchor)
    rightAnchor = createBody(createBox(0.3, 0.3), -startX + 1, bridgeY + 5.5, 1, true)
    worldAddBody(world, rightAnchor)

    deckSegs = {}
    prevSeg = null
    for i = 1, numDeckSegs do
        x = startX + (i - 0.5) * segWidth
        seg = createBody(createBox(segWidth / 2 - 0.02, 0.12), x, bridgeY, 3.0, false)
        seg.linearDamping = 0.1
        seg.angularDamping = 0.2
        worldAddBody(world, seg)
        deckSegs[i] = seg

        if prevSeg then
            j = createRevoluteJoint(prevSeg, seg,
                vec(segWidth / 2 - 0.02, 0), vec(-segWidth / 2 + 0.02, 0))
            worldAddJoint(world, j)
        else
            anchorJoint = createRevoluteJoint(leftTower, seg,
                vec(0.5, -2.5), vec(-segWidth / 2, 0))
            worldAddJoint(world, anchorJoint)
        end
        prevSeg = seg
    end
    lastAnchorJoint = createRevoluteJoint(rightTower, deckSegs[numDeckSegs],
        vec(-0.5, -2.5), vec(segWidth / 2, 0))
    worldAddJoint(world, lastAnchorJoint)

    numCables = 10
    for i = 1, numCables do
        segIdx = M.floor(i * numDeckSegs / (numCables + 1))
        if segIdx < 1 then segIdx = 1 end
        if segIdx > numDeckSegs then segIdx = numDeckSegs end
        seg = deckSegs[segIdx]
        x = startX + (segIdx - 0.5) * segWidth
        cableLen = 5 - M.abs(x) / bridgeLength * 3

        anchorBody = (x < 0) and leftAnchor or rightAnchor
        anchorLocalX = x - ((x < 0) and (startX - 1) or (-startX + 1))
        cable = createDistanceJoint(anchorBody, seg,
            vec(anchorLocalX * 0.3, 0), vec(0, 0), cableLen)
        cable.stiffness = 150
        cable.damping = 5
        worldAddJoint(world, cable)
    end

    for i = 1, 4 do
        x = startX + i * bridgeLength / 5
        car = createBody(createBox(1.0, 0.4), x, bridgeY + 0.6, 5.0, false)
        car.velocity = vec(3, 0)
        car.dynamicFriction = 0.5
        worldAddBody(world, car)
    end

    return world
end

-- ============================================================================
-- Predefined obstacle courses (large data)
-- ============================================================================

D.obstacleCourseData = {
    {type = "box", x = -12.5, y = 1.0, w = 0.5, h = 1.0, angle = 0, static = true},
    {type = "box", x = -11.0, y = 1.5, w = 0.5, h = 1.5, angle = 0, static = true},
    {type = "box", x = -9.5, y = 1.0, w = 1.0, h = 0.3, angle = -0.2, static = true},
    {type = "circle", x = -8.0, y = 2.0, r = 0.5, static = true},
    {type = "box", x = -6.5, y = 0.5, w = 0.3, h = 2.0, angle = 0, static = true},
    {type = "polygon", x = -5.0, y = 1.5, sides = 5, r = 0.7, static = true},
    {type = "box", x = -3.5, y = 2.0, w = 1.5, h = 0.2, angle = 0.3, static = true},
    {type = "circle", x = -2.0, y = 1.0, r = 0.4, static = true},
    {type = "box", x = -0.5, y = 2.5, w = 0.4, h = 0.4, angle = 0.785, static = true},
    {type = "box", x = 1.0, y = 1.0, w = 2.0, h = 0.2, angle = -0.15, static = true},
    {type = "circle", x = 3.0, y = 2.0, r = 0.6, static = true},
    {type = "polygon", x = 4.5, y = 1.5, sides = 6, r = 0.5, static = true},
    {type = "box", x = 6.0, y = 1.0, w = 0.5, h = 1.5, angle = 0.1, static = true},
    {type = "box", x = 7.5, y = 2.5, w = 1.0, h = 0.2, angle = -0.25, static = true},
    {type = "circle", x = 9.0, y = 1.5, r = 0.7, static = true},
    {type = "box", x = 10.5, y = 1.0, w = 0.3, h = 2.5, angle = 0, static = true},
    {type = "polygon", x = 12.0, y = 2.0, sides = 3, r = 0.8, static = true},
    {type = "box", x = -12.0, y = 4.0, w = 1.5, h = 0.2, angle = 0.2, static = true},
    {type = "circle", x = -10.0, y = 4.5, r = 0.5, static = true},
    {type = "box", x = -8.0, y = 3.5, w = 0.5, h = 1.0, angle = 0, static = true},
    {type = "polygon", x = -6.0, y = 4.0, sides = 4, r = 0.6, static = true},
    {type = "box", x = -4.0, y = 5.0, w = 2.0, h = 0.15, angle = -0.1, static = true},
    {type = "circle", x = -2.0, y = 4.0, r = 0.3, static = true},
    {type = "box", x = 0, y = 4.5, w = 0.8, h = 0.8, angle = 0.4, static = true},
    {type = "box", x = 2.0, y = 3.5, w = 1.0, h = 0.2, angle = 0.15, static = true},
    {type = "polygon", x = 4.0, y = 4.0, sides = 5, r = 0.4, static = true},
    {type = "circle", x = 6.0, y = 5.0, r = 0.8, static = true},
    {type = "box", x = 8.0, y = 4.0, w = 0.4, h = 1.5, angle = -0.2, static = true},
    {type = "box", x = 10.0, y = 4.5, w = 1.5, h = 0.2, angle = 0.3, static = true},
    {type = "circle", x = 12.0, y = 3.5, r = 0.5, static = true},
    {type = "box", x = -11.0, y = 7.0, w = 0.5, h = 0.5, angle = 0, static = true},
    {type = "box", x = -9.0, y = 6.5, w = 1.0, h = 0.2, angle = -0.3, static = true},
    {type = "circle", x = -7.0, y = 7.0, r = 0.6, static = true},
    {type = "polygon", x = -5.0, y = 6.0, sides = 6, r = 0.5, static = true},
    {type = "box", x = -3.0, y = 7.5, w = 1.5, h = 0.15, angle = 0.2, static = true},
    {type = "circle", x = -1.0, y = 6.5, r = 0.4, static = true},
    {type = "box", x = 1.0, y = 7.0, w = 0.6, h = 1.2, angle = 0, static = true},
    {type = "polygon", x = 3.0, y = 6.0, sides = 3, r = 0.7, static = true},
    {type = "box", x = 5.0, y = 7.0, w = 1.0, h = 0.2, angle = -0.15, static = true},
    {type = "circle", x = 7.0, y = 7.5, r = 0.5, static = true},
    {type = "box", x = 9.0, y = 6.5, w = 0.4, h = 1.8, angle = 0.1, static = true},
    {type = "polygon", x = 11.0, y = 7.0, sides = 5, r = 0.6, static = true},
}

function createObstacleCourseScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(15, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, ground)

    for i = 1, #D.obstacleCourseData do
        d = D.obstacleCourseData[i]
        body = null
        if d.type == "box" then
            body = createBody(createBox(d.w, d.h), d.x, d.y, 1, d.static)
            if d.angle then body.angle = d.angle end
        else if d.type == "circle" then
            body = createBody(createCircle(d.r), d.x, d.y, 1, d.static)
        else if d.type == "polygon" then
            body = createBody(createRegularPolygon(d.r, d.sides), d.x, d.y, 1, d.static)
        end
        if body then
            body.restitution = 0.4
            worldAddBody(world, body)
        end
    end

    resetRandom()
    for i = 1, 15 do
        x = randomRange(-13, -10)
        y = randomRange(8, 14)
        ball = createBody(createCircle(randomRange(0.2, 0.5)), x, y, 2.0, false)
        ball.restitution = 0.5
        ball.velocity = vec(randomRange(2, 6), randomRange(-2, 2))
        worldAddBody(world, ball)
    end

    return world
end

-- ============================================================================
-- Predefined building layout data (for city scenario)
-- ============================================================================

D.buildingLayouts = {
    {x = -20, floors = 4, width = 3, style = "brick"},
    {x = -16, floors = 6, width = 2.5, style = "column"},
    {x = -12, floors = 3, width = 4, style = "brick"},
    {x = -7, floors = 8, width = 2, style = "column"},
    {x = -3, floors = 5, width = 3.5, style = "brick"},
    {x = 2, floors = 7, width = 2.5, style = "column"},
    {x = 6, floors = 4, width = 3, style = "brick"},
    {x = 10, floors = 6, width = 3, style = "column"},
    {x = 15, floors = 3, width = 4.5, style = "brick"},
    {x = 20, floors = 5, width = 2, style = "column"},
}

function createCityBlockScenario()
    world = createWorld(vec(0, -10), 3.0)

    ground = createBody(createBox(30, 0.5), 0, -0.5, 1, true)
    ground.staticFriction = 0.8
    worldAddBody(world, ground)

    for bi = 1, #D.buildingLayouts do
        bld = D.buildingLayouts[bi]
        bx = bld.x
        bw = bld.width
        floorH = 1.0

        if bld.style == "brick" then
            brickW = 0.5
            brickH = 0.25
            bricksPerRow = M.floor(bw / (brickW * 2)) + 1

            for floor = 0, bld.floors - 1 do
                y = 0.25 + floor * (brickH * 2 + 0.01)
                offset = (floor % 2 == 0) and 0 or brickW
                for col = 0, bricksPerRow - 1 do
                    x = bx - bw / 2 + offset + col * brickW * 2
                    if x >= bx - bw / 2 and x <= bx + bw / 2 then
                        brick = createBody(createBox(brickW * 0.9, brickH * 0.9), x, y, 2.5, false)
                        brick.restitution = 0.0
                        brick.staticFriction = 0.7
                        worldAddBody(world, brick)
                    end
                end
            end
        else
            colW = 0.15
            slabH = 0.08

            for floor = 0, bld.floors - 1 do
                baseY = floor * floorH + 0.5

                lc = createBody(createBox(colW, floorH / 2 - slabH),
                    bx - bw / 2 + colW, baseY + floorH / 2 - slabH, 3.0, false)
                lc.staticFriction = 0.6
                worldAddBody(world, lc)

                rc = createBody(createBox(colW, floorH / 2 - slabH),
                    bx + bw / 2 - colW, baseY + floorH / 2 - slabH, 3.0, false)
                rc.staticFriction = 0.6
                worldAddBody(world, rc)

                slab = createBody(createBox(bw / 2 + 0.1, slabH),
                    bx, baseY + floorH - slabH, 4.0, false)
                slab.staticFriction = 0.6
                worldAddBody(world, slab)
            end
        end
    end

    return world
end

-- ============================================================================
-- Terrain generation functions
-- ============================================================================

function generateHillTerrain(startX, endX, segments, amplitude, frequency, baseY)
    points = {}
    segWidth = (endX - startX) / segments
    for i = 0, segments do
        x = startX + i * segWidth
        y = baseY + amplitude * M.sin(x * frequency) + amplitude * 0.5 * M.sin(x * frequency * 2.3 + 1.7)
        points[i + 1] = vec(x, y)
    end
    return points
end

function generateStepTerrain(startX, endX, numSteps, stepHeight, baseY)
    points = {}
    stepWidth = (endX - startX) / numSteps
    for i = 0, numSteps do
        x = startX + i * stepWidth
        y = baseY + M.floor(i / 2) * stepHeight
        points[#points + 1] = vec(x, y)
        if i < numSteps then
            points[#points + 1] = vec(x + stepWidth, y)
        end
    end
    return points
end

function buildTerrainBodies(world, points)
    for i = 1, #points - 1 do
        p1 = points[i]
        p2 = points[i + 1]
        midX = (p1.x + p2.x) / 2
        midY = (p1.y + p2.y) / 2
        dx = p2.x - p1.x
        dy = p2.y - p1.y
        len = M.sqrt(dx * dx + dy * dy)
        if len > 0.01 then
            seg = createBody(createBox(len / 2, 0.2), midX, midY, 1, true)
            seg.angle = M.atan2(dy, dx)
            seg.staticFriction = 0.8
            worldAddBody(world, seg)
        end
    end
end

-- ============================================================================
-- Scenario 51: Hill terrain with rolling objects
-- ============================================================================

function createHillTerrainScenario()
    world = createWorld(vec(0, -10), 3.0)

    terrain = generateHillTerrain(-20, 20, 60, 2.0, 0.3, 0)
    buildTerrainBodies(world, terrain)

    resetRandom()
    for i = 1, 20 do
        x = randomRange(-18, -10)
        y = 5 + randomRange(0, 3)
        choice = M.floor(random() * 3)
        body = null
        if choice == 0 then
            body = createBody(createCircle(randomRange(0.3, 0.7)), x, y, 2.0, false)
        else if choice == 1 then
            body = createBody(createBox(randomRange(0.3, 0.6), randomRange(0.3, 0.6)), x, y, 2.0, false)
        else
            body = createBody(createRegularPolygon(randomRange(0.3, 0.5), 5), x, y, 2.0, false)
        end
        body.restitution = 0.3
        body.dynamicFriction = 0.3
        worldAddBody(world, body)
    end

    return world
end

-- ============================================================================
-- Scenario 52: Step terrain with bouncing balls
-- ============================================================================

function createStepTerrainScenario()
    world = createWorld(vec(0, -10), 3.0)

    terrain = generateStepTerrain(-15, 15, 12, 0.8, 0)
    buildTerrainBodies(world, terrain)

    wallL = createBody(createBox(0.3, 5), -16, 5, 1, true)
    worldAddBody(world, wallL)
    wallR = createBody(createBox(0.3, 10), 16, 8, 1, true)
    worldAddBody(world, wallR)

    resetRandom()
    for i = 1, 30 do
        x = randomRange(-14, 14)
        y = randomRange(8, 15)
        ball = createBody(createCircle(randomRange(0.2, 0.5)), x, y, 2.0, false)
        ball.restitution = randomRange(0.5, 0.9)
        ball.dynamicFriction = 0.2
        worldAddBody(world, ball)
    end

    return world
end

-- ============================================================================
-- Predefined joint configurations for mechanical tests
-- ============================================================================

D.mechanismConfigs = {
    fourbar = {
        bodies = {
            {x = 0, y = 0, w = 0.1, h = 0.1, static = true},
            {x = 3, y = 0, w = 1.5, h = 0.1, static = false},
            {x = 6, y = 2, w = 1.2, h = 0.1, static = false},
            {x = 3, y = 4, w = 1.5, h = 0.1, static = false},
            {x = 0, y = 4, w = 0.1, h = 0.1, static = true},
        },
        joints = {
            {type = "revolute", a = 1, b = 2, ax = 0, ay = 0, bx = -1.5, by = 0},
            {type = "revolute", a = 2, b = 3, ax = 1.5, ay = 0, bx = -1.2, by = 0},
            {type = "revolute", a = 3, b = 4, ax = 1.2, ay = 0, bx = 1.5, by = 0},
            {type = "revolute", a = 4, b = 5, ax = -1.5, ay = 0, bx = 0, by = 0},
        }
    },
    crank_slider = {
        bodies = {
            {x = 0, y = 5, w = 0.1, h = 0.1, static = true},
            {x = 1.5, y = 5, w = 1.0, h = 0.08, static = false},
            {x = 4, y = 5, w = 1.5, h = 0.08, static = false},
            {x = 6, y = 5, w = 0.4, h = 0.3, static = false},
        },
        joints = {
            {type = "revolute", a = 1, b = 2, ax = 0, ay = 0, bx = -1.0, by = 0},
            {type = "revolute", a = 2, b = 3, ax = 1.0, ay = 0, bx = -1.5, by = 0},
            {type = "revolute", a = 3, b = 4, ax = 1.5, ay = 0, bx = 0, by = 0},
            {type = "prismatic", a = 1, b = 4, ax = 0, ay = 0, bx = 0, by = 0, axisX = 1, axisY = 0},
        }
    },
    scotch_yoke = {
        bodies = {
            {x = 0, y = 10, w = 0.1, h = 0.1, static = true},
            {x = 1, y = 10, w = 0.8, h = 0.08, static = false},
            {x = 3, y = 10, w = 1.0, h = 0.3, static = false},
        },
        joints = {
            {type = "revolute", a = 1, b = 2, ax = 0, ay = 0, bx = -0.8, by = 0},
            {type = "prismatic", a = 1, b = 3, ax = 0, ay = 0, bx = 0, by = 0, axisX = 1, axisY = 0},
            {type = "revolute", a = 2, b = 3, ax = 0.8, ay = 0, bx = 0, by = 0},
        }
    },
}

function createMechanismScenario()
    world = createWorld(vec(0, 0), 3.0)
    world.gravity = vec(0, 0)

    for mechName, config in next, D.mechanismConfigs do
        bodies = {}
        for i = 1, #config.bodies do
            bd = config.bodies[i]
            body = createBody(createBox(bd.w, bd.h), bd.x, bd.y, 2.0, bd.static)
            worldAddBody(world, body)
            bodies[i] = body
        end

        for i = 1, #config.joints do
            jd = config.joints[i]
            a = bodies[jd.a]
            b = bodies[jd.b]
            if jd.type == "revolute" then
                j = createRevoluteJoint(a, b, vec(jd.ax, jd.ay), vec(jd.bx, jd.by))
                if i == 1 then
                    j.motorEnabled = true
                    j.motorSpeed = 3
                    j.maxMotorTorque = 50
                end
                worldAddJoint(world, j)
            else if jd.type == "prismatic" then
                axis = vec(jd.axisX or 1, jd.axisY or 0)
                j = createPrismaticJoint(a, b, vec(jd.ax, jd.ay), vec(jd.bx, jd.by), axis)
                worldAddJoint(world, j)
            end
        end
    end

    return world
end

-- ============================================================================
-- Energy and momentum analysis
-- ============================================================================

function computeKineticEnergy(world)
    ke = 0
    for i = 1, #world.bodies do
        body = world.bodies[i]
        if not body.isStatic then
            linKE = 0.5 * body.mass * vecLenSq(body.velocity)
            angKE = 0.5 * body.inertia * body.angularVelocity * body.angularVelocity
            ke = ke + linKE + angKE
        end
    end
    return ke
end

function computeMomentum(world)
    px, py = 0, 0
    for i = 1, #world.bodies do
        body = world.bodies[i]
        if not body.isStatic then
            px = px + body.mass * body.velocity.x
            py = py + body.mass * body.velocity.y
        end
    end
    return vec(px, py)
end

function computeAngularMomentum(world, origin)
    origin = origin or vec(0, 0)
    L = 0
    for i = 1, #world.bodies do
        body = world.bodies[i]
        if not body.isStatic then
            r = vecSub(body.position, origin)
            p = vecMul(body.velocity, body.mass)
            L = L + vecCross(r, p)
            L = L + body.inertia * body.angularVelocity
        end
    end
    return L
end

function computeCenterOfMass(world)
    totalMass = 0
    cx, cy = 0, 0
    for i = 1, #world.bodies do
        body = world.bodies[i]
        if not body.isStatic then
            totalMass = totalMass + body.mass
            cx = cx + body.position.x * body.mass
            cy = cy + body.position.y * body.mass
        end
    end
    if totalMass > 0 then
        return vec(cx / totalMass, cy / totalMass), totalMass
    end
    return vec(0, 0), 0
end

-- ============================================================================
-- Scenario 53: Energy conservation test
-- ============================================================================

function createEnergyTestScenario()
    world = createWorld(vec(0, 0), 4.0)
    world.gravity = vec(0, 0)

    wallTop = createBody(createBox(10, 0.2), 0, 8, 1, true)
    wallTop.restitution = 1.0
    worldAddBody(world, wallTop)
    wallBot = createBody(createBox(10, 0.2), 0, -8, 1, true)
    wallBot.restitution = 1.0
    worldAddBody(world, wallBot)
    wallL = createBody(createBox(0.2, 8), -10, 0, 1, true)
    wallL.restitution = 1.0
    worldAddBody(world, wallL)
    wallR = createBody(createBox(0.2, 8), 10, 0, 1, true)
    wallR.restitution = 1.0
    worldAddBody(world, wallR)

    resetRandom()
    for i = 1, 20 do
        ball = createBody(createCircle(0.4), randomRange(-8, 8), randomRange(-6, 6), 2.0, false)
        ball.restitution = 1.0
        ball.dynamicFriction = 0.0
        ball.linearDamping = 0.0
        ball.velocity = vec(randomRange(-5, 5), randomRange(-5, 5))
        worldAddBody(world, ball)
    end

    return world
end

-- ============================================================================
-- Predefined simulation test cases with expected physics behavior
-- ============================================================================

D.testCases = {
    {
        name = "free_fall",
        setup = function()
            w = createWorld(vec(0, -10), 5.0)
            ball = createBody(createCircle(0.5), 0, 10, 1.0, false)
            ball.linearDamping = 0
            worldAddBody(w, ball)
            return w
        end,
        steps = 10,
        check = function(world)
            ball = world.bodies[1]
            return ball.position.y < 10 and ball.velocity.y < 0
        end
    },
    {
        name = "elastic_collision",
        setup = function()
            w = createWorld(vec(0, 0), 5.0)
            w.gravity = vec(0, 0)
            a = createBody(createCircle(0.5), -3, 0, 1.0, false)
            a.velocity = vec(5, 0)
            a.restitution = 1.0
            a.linearDamping = 0
            worldAddBody(w, a)
            b = createBody(createCircle(0.5), 3, 0, 1.0, false)
            b.velocity = vec(-5, 0)
            b.restitution = 1.0
            b.linearDamping = 0
            worldAddBody(w, b)
            return w
        end,
        steps = 15,
        check = function(world)
            a = world.bodies[1]
            b = world.bodies[2]
            return a.velocity.x < 0 and b.velocity.x > 0
        end
    },
    {
        name = "stack_stability",
        setup = function()
            w = createWorld(vec(0, -10), 3.0)
            w.iterations = 15
            ground = createBody(createBox(5, 0.5), 0, -0.5, 1, true)
            ground.staticFriction = 0.9
            worldAddBody(w, ground)
            for i = 1, 5 do
                box = createBody(createBox(0.4, 0.4), 0, i * 0.85, 2.0, false)
                box.staticFriction = 0.7
                box.restitution = 0.0
                worldAddBody(w, box)
            end
            return w
        end,
        steps = 30,
        check = function(world)
            for i = 2, #world.bodies do
                if world.bodies[i].position.x > 2 or world.bodies[i].position.x < -2 then
                    return false
                end
            end
            return true
        end
    },
    {
        name = "circle_on_slope",
        setup = function()
            w = createWorld(vec(0, -10), 5.0)
            slope = createBody(createBox(5, 0.2), 0, 3, 1, true)
            slope.angle = -0.3
            slope.staticFriction = 0.2
            worldAddBody(w, slope)
            ball = createBody(createCircle(0.3), -3, 5, 2.0, false)
            ball.dynamicFriction = 0.1
            worldAddBody(w, ball)
            return w
        end,
        steps = 20,
        check = function(world)
            return world.bodies[2].velocity.x > 0
        end
    },
    {
        name = "pendulum_swing",
        setup = function()
            w = createWorld(vec(0, -10), 3.0)
            anchor = createBody(createCircle(0.1), 0, 10, 1, true)
            worldAddBody(w, anchor)
            bob = createBody(createCircle(0.3), 3, 10, 3.0, false)
            worldAddBody(w, bob)
            j = createDistanceJoint(anchor, bob, vec(0, 0), vec(0, 0), 3)
            j.stiffness = 500
            j.damping = 0.5
            worldAddJoint(w, j)
            return w
        end,
        steps = 30,
        check = function(world)
            return M.abs(world.bodies[2].position.x) < 3.5
        end
    },
}

function runTestCases()
    allPassed = true
    for i = 1, #D.testCases do
        tc = D.testCases[i]
        bodyIdCounter = 0
        world = tc.setup()
        for step = 1, tc.steps do
            worldStep(world, 1/60)
        end
        if not tc.check(world) then
            allPassed = false
        end
    end
    return allPassed
end

-- ============================================================================
-- Additional predefined body configurations
-- ============================================================================

D.predefWorlds = {}

D.predefWorlds.tower_of_circles = function()
    world = createWorld(vec(0, -10), 2.0)
    ground = createBody(createBox(10, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, ground)
    for i = 1, 30 do
        radius = 0.4 - i * 0.005
        if radius < 0.15 then radius = 0.15 end
        ball = createBody(createCircle(radius), 0, i * radius * 2 + 0.5, 2.0, false)
        ball.restitution = 0.0
        ball.staticFriction = 0.8
        worldAddBody(world, ball)
    end
    return world
end

D.predefWorlds.falling_grid = function()
    world = createWorld(vec(0, -10), 2.0)
    ground = createBody(createBox(12, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, ground)
    cols = 8
    rows = 8
    spacing = 1.0
    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            x = (c - cols / 2) * spacing + 0.5
            y = 5 + r * spacing
            body = createBody(createBox(0.35, 0.35), x, y, 2.0, false)
            body.restitution = 0.1
            worldAddBody(world, body)
        end
    end
    return world
end

D.predefWorlds.spinning_shapes = function()
    world = createWorld(vec(0, -10), 3.0)
    ground = createBody(createBox(15, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, ground)
    resetRandom()
    for i = 1, 20 do
        x = randomRange(-10, 10)
        y = randomRange(5, 15)
        sides = M.floor(random() * 5) + 3
        body = createBody(createRegularPolygon(randomRange(0.3, 0.8), sides), x, y, 2.0, false)
        body.angularVelocity = randomRange(-10, 10)
        body.restitution = 0.4
        worldAddBody(world, body)
    end
    return world
end

D.predefWorlds.heavy_on_light = function()
    world = createWorld(vec(0, -10), 3.0)
    ground = createBody(createBox(8, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, ground)
    for i = 1, 8 do
        density = 0.5 + (8 - i) * 2
        body = createBody(createBox(2 - i * 0.15, 0.3), 0, i * 0.65, density, false)
        body.restitution = 0.0
        body.staticFriction = 0.7
        worldAddBody(world, body)
    end
    return world
end

D.predefWorlds.chain_curtain = function()
    world = createWorld(vec(0, -10), 2.0)
    numChains = 10
    linksPerChain = 8
    chainSpacing = 1.5
    startX = -(numChains - 1) * chainSpacing / 2

    for c = 0, numChains - 1 do
        x = startX + c * chainSpacing
        anchor = createBody(createCircle(0.1), x, 12, 1, true)
        worldAddBody(world, anchor)
        prev = anchor
        for l = 1, linksPerChain do
            link = createBody(createBox(0.2, 0.1), x, 12 - l * 0.5, 1.5, false)
            link.angularDamping = 0.3
            worldAddBody(world, link)
            j = createDistanceJoint(prev, link, vec(0, -0.1), vec(0, 0.1), 0.3)
            j.stiffness = 200
            j.damping = 5
            worldAddJoint(world, j)
            prev = link
        end
    end
    return world
end

D.predefWorlds.avalanche = function()
    world = createWorld(vec(0, -10), 2.0)
    slopeAngle = -0.4
    slope = createBody(createBox(15, 0.3), 0, 5, 1, true)
    slope.angle = slopeAngle
    slope.staticFriction = 0.3
    worldAddBody(world, slope)
    ground = createBody(createBox(20, 0.3), 5, -2, 1, true)
    worldAddBody(world, ground)
    resetRandom()
    for i = 1, 40 do
        x = randomRange(-12, -2)
        y = 6 + randomRange(0, 4)
        r = randomRange(0.15, 0.4)
        ball = createBody(createCircle(r), x, y, 2.0, false)
        ball.restitution = 0.2
        ball.dynamicFriction = 0.3
        worldAddBody(world, ball)
    end
    return world
end

D.predefWorlds.trampoline = function()
    world = createWorld(vec(0, -10), 3.0)
    frame_l = createBody(createBox(0.2, 1), -4, 1, 1, true)
    worldAddBody(world, frame_l)
    frame_r = createBody(createBox(0.2, 1), 4, 1, 1, true)
    worldAddBody(world, frame_r)
    numSegs = 12
    segWidth = 8 / numSegs
    prev = frame_l
    for i = 1, numSegs do
        x = -4 + (i - 0.5) * segWidth
        seg = createBody(createBox(segWidth / 2 - 0.02, 0.05), x, 1.5, 0.5, false)
        worldAddBody(world, seg)
        j = createDistanceJoint(prev, seg, vec(0.2, 0), vec(-segWidth / 2, 0), 0.05)
        j.stiffness = 300
        j.damping = 5
        worldAddJoint(world, j)
        prev = seg
    end
    lastJ = createDistanceJoint(prev, frame_r, vec(segWidth / 2, 0), vec(-0.2, 0), 0.05)
    lastJ.stiffness = 300
    lastJ.damping = 5
    worldAddJoint(world, lastJ)
    ball = createBody(createCircle(0.5), 0, 8, 5.0, false)
    ball.restitution = 0.8
    worldAddBody(world, ball)
    return world
end

D.predefWorlds.domino_spiral = function()
    world = createWorld(vec(0, -10), 3.0)
    ground = createBody(createBox(15, 0.3), 0, -0.3, 1, true)
    worldAddBody(world, ground)
    numDominoes = 30
    spiralRadius = 5
    for i = 0, numDominoes - 1 do
        angle = i * 0.25
        r = spiralRadius - i * 0.1
        if r < 1 then r = 1 end
        x = r * M.cos(angle)
        y = 0.7
        domino = createBody(createBox(0.1, 0.6), x, y, 3.0, false)
        domino.angle = angle + M.pi / 2
        domino.staticFriction = 0.5
        worldAddBody(world, domino)
    end
    pusher = createBody(createCircle(0.3), spiralRadius + 0.5, 1, 8.0, false)
    pusher.velocity = vec(-5, 0)
    worldAddBody(world, pusher)
    return world
end

-- ============================================================================
-- Run simulation and checksum
-- ============================================================================

function checksumWorld(world)
    sum = 0
    for i = 1, #world.bodies do
        body = world.bodies[i]
        sum = sum + body.position.x * 1000
        sum = sum + body.position.y * 1000
        sum = sum + body.velocity.x * 100
        sum = sum + body.velocity.y * 100
        sum = sum + body.angle * 500
        sum = sum + body.angularVelocity * 50
    end
    return M.floor(sum * 1000) / 1000
end

function runScenario(createFn, steps, name)
    bodyIdCounter = 0
    world = createFn()
    for step = 1, steps do
        worldStep(world, 1 / 60)
    end
    return checksumWorld(world)
end

function runScenarioExtended(createFn, steps, name)
    bodyIdCounter = 0
    world = createFn()
    for step = 1, steps do
        worldStepExtended(world, 1 / 60)
    end
    return checksumWorld(world)
end

function runScenariosGroup1()
    result = 0
    result = result + runScenario(createBoxStackScenario, 8, "BoxStack")
    result = result + runScenario(createPendulumScenario, 6, "Pendulum")
    result = result + runScenario(createBallPitScenario, 6, "BallPit")
    result = result + runScenario(createDominoScenario, 10, "Domino")
    result = result + runScenario(createBilliardsScenario, 5, "Billiards")
    result = result + runScenario(createTumblerScenario, 5, "Tumbler")
    result = result + runScenario(createBridgeScenario, 6, "Bridge")
    result = result + runScenario(createCradleScenario, 5, "Cradle")
    result = result + runScenarioExtended(createVehicleScenario, 8, "Vehicle")
    result = result + runScenarioExtended(createWreckingBallScenario, 6, "WreckingBall")
    result = result + runScenarioExtended(createGearTrainScenario, 5, "GearTrain")
    result = result + runScenarioExtended(createClothScenario, 5, "Cloth")
    result = result + runScenarioExtended(createConveyorScenario, 5, "Conveyor")
    result = result + runScenarioExtended(createCatapultScenario, 8, "Catapult")
    result = result + runScenarioExtended(createPinballScenario, 6, "Pinball")
    result = result + runScenarioExtended(createRubeGoldbergScenario, 8, "RubeGoldberg")
    result = result + runScenarioExtended(createGranularScenario, 5, "Granular")
    result = result + runScenarioExtended(createRagdollScenario, 6, "Ragdoll")
    result = result + runScenarioExtended(createBreakableChainScenario, 5, "BreakableChain")
    result = result + runScenarioExtended(createMixedStackScenario, 5, "MixedStack")
    return result
end

function runScenariosGroup2()
    bodyIdCounter = 0
    _, rayCount, aabbCount, pointCount = createRaycastTestScenario()
    result = rayCount * 1000 + aabbCount * 100 + pointCount

    result = result + createParticleRopeScenario()
    result = result + createParticleClothScenario()
    result = result + createSoftBodyScenario()

    bodyIdCounter = 0
    world = createBuoyancyScenario()
    for step = 1, 10 do
        for fi = 1, #world.floaters do
            applyBuoyancy(world.floaters[fi], world.waterLevel, world.waterDensity, world.dragCoeff)
        end
        worldStep(world, 1/60)
    end
    result = result + checksumWorld(world)

    bodyIdCounter = 0
    world = createTornadoScenario()
    for step = 1, 12 do
        for di = 1, #world.debris do
            body = world.debris[di]
            if not body.isStatic then
                toCenter = vecSub(world.vortexCenter, body.position)
                dist = vecLen(toCenter)
                if dist > 0.5 then
                    tangent = vecPerp(vecNormalize(toCenter))
                    tangentialForce = vecMul(tangent, world.vortexStrength * body.mass / dist)
                    radialForce = vecMul(toCenter, 5 * body.mass / (dist * dist))
                    bodyApplyForce(body, vecAdd(tangentialForce, radialForce))
                end
            end
        end
        worldStep(world, 1/60)
    end
    result = result + checksumWorld(world)

    result = result + runScenario(createLargePyramidScenario, 4, "LargePyramid")
    result = result + runScenario(createMarbleRunScenario, 6, "MarbleRun")
    result = result + runScenario(createExplosionScenario, 5, "Explosion")
    result = result + runScenarioExtended(createPulleyScenario, 5, "Pulley")
    result = result + runScenario(createElasticChainScenario, 5, "ElasticChain")
    result = result + runScenario(createMaterialTestScenario, 5, "MaterialTest")
    result = result + runScenario(createComplexPolygonScenario, 6, "ComplexPolygon")
    result = result + runScenario(createStressTestScenario, 4, "StressTest")
    result = result + runScenario(createCastleScenario, 4, "Castle")
    result = result + runScenarioExtended(createClockworkScenario, 5, "Clockwork")
    result = result + runScenarioExtended(createTrebuchetScenario, 6, "Trebuchet")
    result = result + runScenario(createFluidScenario, 4, "Fluid")
    result = result + runScenarioExtended(createWindmillScenario, 5, "Windmill")
    result = result + runScenarioExtended(createDetailedVehicleScenario, 6, "DetailedVehicle")
    return result
end

function runScenariosGroup3()
    result = 0
    result = result + runScenario(createBowlingScenario, 8, "Bowling")
    result = result + runScenario(createEarthquakeScenario, 4, "Earthquake")
    result = result + runScenario(createPachinkoScenario, 5, "Pachinko")
    result = result + runScenarioExtended(createSpringLatticeScenario, 4, "SpringLattice")
    result = result + runScenario(createCannonScenario, 6, "Cannon")
    result = result + runScenario(createWreckingYardScenario, 4, "WreckingYard")
    result = result + runScenario(createRaceTrackScenario, 5, "RaceTrack")
    result = result + runScenario(createRollerCoasterScenario, 5, "RollerCoaster")
    result = result + runScenario(createDestructionDerbyScenario, 5, "DestructionDerby")
    result = result + runScenarioExtended(createAssemblyLineScenario, 5, "AssemblyLine")
    result = result + runScenarioExtended(createSuspensionBridgeScenario, 5, "SuspensionBridge")
    result = result + runScenario(createObstacleCourseScenario, 5, "ObstacleCourse")
    result = result + runScenario(createCityBlockScenario, 4, "CityBlock")
    result = result + runScenario(createHillTerrainScenario, 5, "HillTerrain")
    result = result + runScenario(createStepTerrainScenario, 5, "StepTerrain")
    result = result + runScenarioExtended(createMechanismScenario, 5, "Mechanism")
    result = result + runScenario(createEnergyTestScenario, 5, "EnergyTest")
    result = result + runScenario(D.predefWorlds.tower_of_circles, 5, "TowerCircles")
    result = result + runScenario(D.predefWorlds.falling_grid, 4, "FallingGrid")
    result = result + runScenario(D.predefWorlds.spinning_shapes, 5, "SpinningShapes")
    result = result + runScenario(D.predefWorlds.heavy_on_light, 5, "HeavyOnLight")
    result = result + runScenarioExtended(D.predefWorlds.chain_curtain, 4, "ChainCurtain")
    result = result + runScenario(D.predefWorlds.avalanche, 5, "Avalanche")
    result = result + runScenarioExtended(D.predefWorlds.trampoline, 5, "Trampoline")
    result = result + runScenario(D.predefWorlds.domino_spiral, 5, "DominoSpiral")

    tcResult = runTestCases()
    result = result + (tcResult and 1 or 0)

    return result
end

function runAllScenarios()
    result = 0
    result = result + runScenariosGroup1()
    result = result + runScenariosGroup2()
    result = result + runScenariosGroup3()
    return result
end

-- First run to establish expected values
result = runAllScenarios()
expected = 21502896.173
if math.abs(result - expected) > expected * 1e-3 then
    error("Bad checksum " .. result)
end

end

bench.runCode(test, "physics")
