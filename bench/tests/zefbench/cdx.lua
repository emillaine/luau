function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

function test()


-- CDlua collision detection benchmark, ported from fpizlo's JS version to Lua using declawd
-- Ported from JavaScript: PerformanceTests/JetStream2/cdjs
-- Original copyright (c) 2001-2010 Purdue University; (C) 2015-2016 Apple Inc.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--  * Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
--  * Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
--  * Neither the name of the Purdue University nor the
--    names of its contributors may be used to endorse or promote products
--    derived from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-- ==================== Constants ====================

MIN_X = 0
MIN_Y = 0
MAX_X = 1000
MAX_Y = 1000
MIN_Z = 0
MAX_Z = 10
PROXIMITY_RADIUS = 1
GOOD_VOXEL_SIZE = PROXIMITY_RADIUS * 2

-- ==================== Utilities ====================

function compareNumbers(a, b)
    if a == b then return 0 end
    if a < b then return -1 end
    if a > b then return 1 end
    -- NaN is considered smaller than non-NaN
    if a == a then return 1 end
    return -1
end

-- Truncate toward zero, equivalent to JavaScript's | 0 operator
function intTrunc(x)
    i = math.modf(x)
    return i
end

-- ==================== CallSign ====================

CallSign_mt = {}
CallSign_mt.__index = CallSign_mt

function CallSign_mt:compareTo(other)
    if self._value < other._value then return -1
    else if self._value > other._value then return 1
    else return 0 end
end

function CallSign_new(value)
    return setmetatable({ _value = value }, CallSign_mt)
end

-- ==================== Vector2D ====================

Vector2D_mt = {}
Vector2D_mt.__index = Vector2D_mt

function Vector2D_new(x, y)
    return setmetatable({ x = x or 0, y = y or 0 }, Vector2D_mt)
end

function Vector2D_mt:compareTo(other)
    result = compareNumbers(self.x, other.x)
    if result != 0 then return result end
    return compareNumbers(self.y, other.y)
end

function Vector2D_mt.__add(a, b)
    return Vector2D_new(a.x + b.x, a.y + b.y)
end

function Vector2D_mt.__sub(a, b)
    return Vector2D_new(a.x - b.x, a.y - b.y)
end

-- ==================== Vector3D ====================

Vector3D_mt = {}
Vector3D_mt.__index = Vector3D_mt

function Vector3D_new(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, Vector3D_mt)
end

function Vector3D_mt.__add(a, b)
    return Vector3D_new(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vector3D_mt.__sub(a, b)
    return Vector3D_new(a.x - b.x, a.y - b.y, a.z - b.z)
end

function Vector3D_mt.__mul(a, b)
    if type(a) == "number" then
        return Vector3D_new(b.x * a, b.y * a, b.z * a)
    else
        return Vector3D_new(a.x * b, a.y * b, a.z * b)
    end
end

function Vector3D_mt:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

function Vector3D_mt:squaredMagnitude()
    return self:dot(self)
end

function Vector3D_mt:magnitude()
    return math.sqrt(self:squaredMagnitude())
end

-- ==================== Motion ====================

function Motion_new(callsign, posOne, posTwo)
    return { callsign = callsign, posOne = posOne, posTwo = posTwo }
end

function Motion_delta(m)
    return m.posTwo - m.posOne
end

function Motion_findIntersection(motion1, motion2)
    init1 = motion1.posOne
    init2 = motion2.posOne
    vec1 = Motion_delta(motion1)
    vec2 = Motion_delta(motion2)
    radius = PROXIMITY_RADIUS

    -- This is a 4D intersection test accounting for constant-speed motion
    -- over the interval. We solve for times v where dist(P1(v), P2(v)) = r.

    -- a = (V2 - V1)^T * (V2 - V1)
    a = (vec2 - vec1):squaredMagnitude()

    if a != 0 then
        -- b = 2 * <I1-I2, V1-V2>
        b = 2 * (init1 - init2):dot(vec1 - vec2)
        -- c = -r^2 + (I2 - I1)^T * (I2 - I1)
        c = -radius * radius + (init2 - init1):squaredMagnitude()

        discr = b * b - 4 * a * c
        if discr < 0 then return nil end

        v1 = (-b - math.sqrt(discr)) / (2 * a)
        v2 = (-b + math.sqrt(discr)) / (2 * a)

        if v1 <= v2 and ((v1 <= 1 and 1 <= v2) or
                         (v1 <= 0 and 0 <= v2) or
                         (0 <= v1 and v2 <= 1)) then
            v = nil
            if v1 <= 0 then
                -- Collision started before this frame; report at frame start
                v = 0
            else
                -- Collision started during this frame; report at that moment
                v = v1
            end

            result1 = init1 + vec1 * v
            result2 = init2 + vec2 * v
            result  = (result1 + result2) * 0.5

            if result.x >= MIN_X and result.x <= MAX_X and
               result.y >= MIN_Y and result.y <= MAX_Y and
               result.z >= MIN_Z and result.z <= MAX_Z then
                return result
            end
        end

        return nil
    end

    -- Planes have same speed and move in parallel (or are stationary);
    -- distance is constant, computed from initial positions
    dist = (init2 - init1):magnitude()
    if dist <= radius then
        return (init1 + init2) * 0.5
    end

    return nil
end

-- ==================== RedBlackTree ====================

function RBNode_new(key, value)
    return { key = key, value = value, left = nil, right = nil, parent = nil, color = "red" }
end

function treeMinimum(x)
    while x.left do x = x.left end
    return x
end

function treeMaximum(x)
    while x.right do x = x.right end
    return x
end

function RBNode_successor(x)
    if x.right then return treeMinimum(x.right) end
    y = x.parent
    while y and x == y.right do
        x = y
        y = y.parent
    end
    return y
end

RBTree = {}
RBTree.__index = RBTree

function RedBlackTree_new()
    return setmetatable({ _root = nil }, RBTree)
end

function RBTree:_leftRotate(x)
    y = x.right
    x.right = y.left
    if y.left then y.left.parent = x end
    y.parent = x.parent
    if not x.parent then
        self._root = y
    else if x == x.parent.left then
        x.parent.left = y
    else
        x.parent.right = y
    end
    y.left = x
    x.parent = y
    return y
end

function RBTree:_rightRotate(y)
    x = y.left
    y.left = x.right
    if x.right then x.right.parent = y end
    x.parent = y.parent
    if not y.parent then
        self._root = x
    else if y == y.parent.left then
        y.parent.left = x
    else
        y.parent.right = x
    end
    x.right = y
    y.parent = x
    return x
end

function RBTree:_findNode(key)
    current = self._root
    while current do
        cmp = key:compareTo(current.key)
        if cmp == 0 then return current
        else if cmp < 0 then current = current.left
        else current = current.right
        end
    end
    return nil
end

function RBTree:_treeInsert(key, value)
    y = nil
    x = self._root
    while x do
        y = x
        cmp = key:compareTo(x.key)
        if cmp < 0 then
            x = x.left
        else if cmp > 0 then
            x = x.right
        else
            oldValue = x.value
            x.value = value
            return { isNewEntry = false, oldValue = oldValue }
        end
    end
    z = RBNode_new(key, value)
    z.parent = y
    if not y then
        self._root = z
    else if key:compareTo(y.key) < 0 then
        y.left = z
    else
        y.right = z
    end
    return { isNewEntry = true, newNode = z }
end

function RBTree:put(key, value)
    insertionResult = self:_treeInsert(key, value)
    if not insertionResult.isNewEntry then
        return insertionResult.oldValue
    end
    x = insertionResult.newNode

    while x != self._root and x.parent.color == "red" do
        if x.parent == x.parent.parent.left then
            y = x.parent.parent.right
            if y and y.color == "red" then
                -- Case 1
                x.parent.color = "black"
                y.color = "black"
                x.parent.parent.color = "red"
                x = x.parent.parent
            else
                if x == x.parent.right then
                    -- Case 2
                    x = x.parent
                    self:_leftRotate(x)
                end
                -- Case 3
                x.parent.color = "black"
                x.parent.parent.color = "red"
                self:_rightRotate(x.parent.parent)
            end
        else
            -- Mirror of above with left/right exchanged
            y = x.parent.parent.left
            if y and y.color == "red" then
                -- Case 1
                x.parent.color = "black"
                y.color = "black"
                x.parent.parent.color = "red"
                x = x.parent.parent
            else
                if x == x.parent.left then
                    -- Case 2
                    x = x.parent
                    self:_rightRotate(x)
                end
                -- Case 3
                x.parent.color = "black"
                x.parent.parent.color = "red"
                self:_leftRotate(x.parent.parent)
            end
        end
    end

    self._root.color = "black"
    return nil
end

function RBTree:get(key)
    node = self:_findNode(key)
    if not node then return nil end
    return node.value
end

function RBTree:forEach(callback)
    if not self._root then return end
    current = treeMinimum(self._root)
    while current do
        callback(current.key, current.value)
        current = RBNode_successor(current)
    end
end

function RBTree:_removeFixup(x, xParent)
    while x != self._root and (not x or x.color == "black") do
        if x == xParent.left then
            w = xParent.right
            if w.color == "red" then
                -- Case 1
                w.color = "black"
                xParent.color = "red"
                self:_leftRotate(xParent)
                w = xParent.right
            end
            if (not w.left or w.left.color == "black")
               and (not w.right or w.right.color == "black") then
                -- Case 2
                w.color = "red"
                x = xParent
                xParent = x.parent
            else
                if not w.right or w.right.color == "black" then
                    -- Case 3
                    w.left.color = "black"
                    w.color = "red"
                    self:_rightRotate(w)
                    w = xParent.right
                end
                -- Case 4
                w.color = xParent.color
                xParent.color = "black"
                if w.right then w.right.color = "black" end
                self:_leftRotate(xParent)
                x = self._root
                xParent = x.parent
            end
        else
            -- Mirror of above with left/right exchanged
            w = xParent.left
            if w.color == "red" then
                -- Case 1
                w.color = "black"
                xParent.color = "red"
                self:_rightRotate(xParent)
                w = xParent.left
            end
            if (not w.right or w.right.color == "black")
               and (not w.left or w.left.color == "black") then
                -- Case 2
                w.color = "red"
                x = xParent
                xParent = x.parent
            else
                if not w.left or w.left.color == "black" then
                    -- Case 3
                    w.right.color = "black"
                    w.color = "red"
                    self:_leftRotate(w)
                    w = xParent.left
                end
                -- Case 4
                w.color = xParent.color
                xParent.color = "black"
                if w.left then w.left.color = "black" end
                self:_rightRotate(xParent)
                x = self._root
                xParent = x.parent
            end
        end
    end
    if x then x.color = "black" end
end

function RBTree:remove(key)
    z = self:_findNode(key)
    if not z then return nil end

    -- y is the node to unlink from the tree
    y = nil
    if not z.left or not z.right then
        y = z
    else
        y = RBNode_successor(z)
    end

    -- x is y's only child (possibly nil), which may replace y
    x = nil
    if y.left then x = y.left
    else x = y.right
    end

    xParent = nil
    if x then
        x.parent = y.parent
        xParent = x.parent
    else
        xParent = y.parent
    end

    if not y.parent then
        self._root = x
    else if y == y.parent.left then
        y.parent.left = x
    else
        y.parent.right = x
    end

    if y != z then
        if y.color == "black" then
            self:_removeFixup(x, xParent)
        end
        y.parent = z.parent
        y.color = z.color
        y.left = z.left
        y.right = z.right
        if z.left then z.left.parent = y end
        if z.right then z.right.parent = y end
        if z.parent then
            if z.parent.left == z then z.parent.left = y
            else z.parent.right = y
            end
        else
            self._root = y
        end
    else if y.color == "black" then
        self:_removeFixup(x, xParent)
    end

    return z.value
end

-- ==================== Simulator ====================

function Simulator_new(numAircraft)
    aircraft = {}
    for i = 0, numAircraft - 1 do
        aircraft[i + 1] = CallSign_new("foo" .. tostring(i))
    end
    return { _aircraft = aircraft }
end

function Simulator_simulate(sim, time)
    frame = {}
    aircraft = sim._aircraft
    -- JS iterates i = 0, 2, 4, ..., numAircraft-2 (0-indexed pairs)
    -- Lua aircraft is 1-indexed, so luaI = 1, 3, 5, ...; jsI = luaI - 1
    for luaI = 1, #aircraft - 1, 2 do
        jsI = luaI - 1
        table.insert(frame, {
            callsign = aircraft[luaI],
            position = Vector3D_new(time, math.cos(time) * 2 + jsI * 3, 10)
        })
        table.insert(frame, {
            callsign = aircraft[luaI + 1],
            position = Vector3D_new(time, math.sin(time) * 2 + jsI * 3, 10)
        })
    end
    return frame
end

-- ==================== Voxel map / collision reduction ====================

VOXEL_SIZE = GOOD_VOXEL_SIZE
HORIZONTAL = Vector2D_new(VOXEL_SIZE, 0)
VERTICAL   = Vector2D_new(0, VOXEL_SIZE)

function voxelHash(position)
    xDiv = intTrunc(position.x / VOXEL_SIZE)
    yDiv = intTrunc(position.y / VOXEL_SIZE)
    result = Vector2D_new()
    result.x = VOXEL_SIZE * xDiv
    result.y = VOXEL_SIZE * yDiv
    if position.x < 0 then result.x = result.x - VOXEL_SIZE end
    if position.y < 0 then result.y = result.y - VOXEL_SIZE end
    return result
end

function drawMotionOnVoxelMap(voxelMap, motion)
    seen = RedBlackTree_new()

    function putIntoMap(voxel)
        array = voxelMap:get(voxel)
        if not array then
            array = {}
            voxelMap:put(voxel, array)
        end
        table.insert(array, motion)
    end

    function isInVoxel(voxel)
        if voxel.x > MAX_X or voxel.x < MIN_X or
           voxel.y > MAX_Y or voxel.y < MIN_Y then
            return false
        end

        init = motion.posOne
        fin  = motion.posTwo
        v_s  = VOXEL_SIZE
        r    = PROXIMITY_RADIUS / 2

        v_x = voxel.x
        x0  = init.x
        xv  = fin.x - init.x

        v_y = voxel.y
        y0  = init.y
        yv  = fin.y - init.y

        low_x  = (v_x - r - x0) / xv
        high_x = (v_x + v_s + r - x0) / xv
        if xv < 0 then low_x, high_x = high_x, low_x end

        low_y  = (v_y - r - y0) / yv
        high_y = (v_y + v_s + r - y0) / yv
        if yv < 0 then low_y, high_y = high_y, low_y end

        return (
            ((xv == 0 and v_x <= x0 + r and x0 - r <= v_x + v_s) or
             ((low_x <= 1 and 1 <= high_x) or (low_x <= 0 and 0 <= high_x) or
              (0 <= low_x and high_x <= 1))) and
            ((yv == 0 and v_y <= y0 + r and y0 - r <= v_y + v_s) or
             ((low_y <= 1 and 1 <= high_y) or (low_y <= 0 and 0 <= high_y) or
              (0 <= low_y and high_y <= 1))) and
            (xv == 0 or yv == 0 or
             (low_y <= high_x and high_x <= high_y) or
             (low_y <= low_x and low_x <= high_y) or
             (low_x <= low_y and high_y <= high_x))
        )
    end

    function recurse(nextVoxel)
        if not isInVoxel(nextVoxel) then return end
        if seen:put(nextVoxel, true) then return end  -- already visited
        putIntoMap(nextVoxel)
        recurse(nextVoxel - HORIZONTAL)
        recurse(nextVoxel + HORIZONTAL)
        recurse(nextVoxel - VERTICAL)
        recurse(nextVoxel + VERTICAL)
        recurse(nextVoxel - HORIZONTAL - VERTICAL)
        recurse(nextVoxel - HORIZONTAL + VERTICAL)
        recurse(nextVoxel + HORIZONTAL - VERTICAL)
        recurse(nextVoxel + HORIZONTAL + VERTICAL)
    end

    recurse(voxelHash(motion.posOne))
end

function reduceCollisionSet(motions)
    voxelMap = RedBlackTree_new()
    for i = 1, #motions do
        drawMotionOnVoxelMap(voxelMap, motions[i])
    end
    result = {}
    voxelMap:forEach(function(key, value)
        if #value > 1 then
            table.insert(result, value)
        end
    end)
    return result
end

-- ==================== CollisionDetector ====================

function CollisionDetector_new()
    return { _state = RedBlackTree_new() }
end

function CollisionDetector_handleNewFrame(detector, frame)
    motions = {}
    seen = RedBlackTree_new()

    for i = 1, #frame do
        aircraft = frame[i]
        oldPosition = detector._state:put(aircraft.callsign, aircraft.position)
        newPosition = aircraft.position
        seen:put(aircraft.callsign, true)

        if not oldPosition then
            -- Newly introduced aircraft treated as stationary
            oldPosition = newPosition
        end

        table.insert(motions, Motion_new(aircraft.callsign, oldPosition, newPosition))
    end

    -- Remove aircraft no longer present
    toRemove = {}
    detector._state:forEach(function(callsign, position)
        if not seen:get(callsign) then
            table.insert(toRemove, callsign)
        end
    end)
    for i = 1, #toRemove do
        detector._state:remove(toRemove[i])
    end

    allReduced = reduceCollisionSet(motions)
    collisions = {}
    for reductionIndex = 1, #allReduced do
        reduced = allReduced[reductionIndex]
        for i = 1, #reduced do
            motion1 = reduced[i]
            for j = i + 1, #reduced do
                motion2 = reduced[j]
                collision = Motion_findIntersection(motion1, motion2)
                if collision then
                    table.insert(collisions, {
                        aircraft = { motion1.callsign, motion2.callsign },
                        position = collision
                    })
                end
            end
        end
    end

    return collisions
end

-- ==================== Benchmark entry point ====================

function benchmarkImpl(configuration)
    numAircraft       = configuration.numAircraft
    numFrames         = configuration.numFrames
    expectedCollisions = configuration.expectedCollisions
    exclude           = configuration.exclude

    simulator = Simulator_new(numAircraft)
    detector  = CollisionDetector_new()
    results   = {}

    for i = 0, numFrames - 1 do
        time = i / 10

        -- [frame start: insert frame-time measurement here]
        collisions = CollisionDetector_handleNewFrame(
            detector,
            Simulator_simulate(simulator, time)
        )
        -- [frame end: insert frame-time measurement here]

        table.insert(results, { numCollisions = #collisions })
    end

    -- Discard the first `exclude` results (mirrors JS results.splice(0, exclude))
    for i = 1, exclude do
        table.remove(results, 1)
    end

    -- Check results.
    actualCollisions = 0
    for i = 1, #results do
        actualCollisions = actualCollisions + results[i].numCollisions
    end
    if actualCollisions != expectedCollisions then
        error("Bad number of collisions: " .. actualCollisions ..
              " (expected " .. expectedCollisions .. ")")
    end
end

function benchmark()
    benchmarkImpl({
        numAircraft       = 1000,
        numFrames         = 70,
        expectedCollisions = 4326,
        exclude           = 0,
    })
end

benchmark()

end

bench.runCode(test, "cdx")
