# This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
print("testing stdlib method-call syntax")

function checkerror(msg, f, ...)
	s, err = pcall(f, ...)
	assert(not s and string.find(err, msg))
end

# tables: t:method(...) matches table.method(t, ...)
t = {}
t:insert(1)
t:insert(2)
t:insert(1, 0)
assert(t[1] == 0 and t[2] == 1 and t[3] == 2)
assert(t:concat(",") == "0,1,2")
assert(t:find(1) == 2)
r = t:remove(1)
assert(r == 0 and t[1] == 1)
s = {3, 1, 2}
s:sort()
assert(s[1] == 1 and s[2] == 2 and s[3] == 3)
src = {1, 2, 3}
dst = {}
src:move(1, 3, 1, dst)
assert(dst[1] == 1 and dst[2] == 2 and dst[3] == 3)
x, y, z = src:unpack()
assert(x == 1 and y == 2 and z == 3)
cc = src:clone()
assert(cc[1] == 1 and cc[2] == 2 and cc[3] == 3)
f = {1}
f:freeze()
assert(f:isfrozen() == true)
m = {1, 2, 3}
m:clear()
assert(m.count == 0)

# field in the table wins over the library
t2 = {insert = function(self, x) return 99 end}
assert(t2:insert(1) == 99)

# own metatable __index wins over the library
u = {}
setmetatable(u, {__index = {insert = function(self, x) return 7 end}})
assert(u:insert(1) == 7)

# constructors are not methods
c = {}
checkerror("missing method", function() c:create(3) end)
checkerror("missing method", function() c:pack(1) end)

# dot forms keep working
d = {}
table.insert(d, 5)
assert(d[1] == 5)

# plain tables still have no metatable
assert(getmetatable({}) == null)

# buffers: buf:method(...) matches buffer.method(buf, ...)
b1 = buffer.create(8)
b2 = buffer.create(8)
b1:fill(0, 7)
assert(b1:readu8(3) == 7)
assert(b1:len() == 8)
b2:copy(0, b1, 0, 8)
assert(b2:readu8(3) == 7)
b1:writestring(0, "hi")
assert(b1:readstring(0, 2) == "hi")
b1:writeu16(0, 0x1234)
assert(b1:readu16(0) == 0x1234)
assert(buffer.len(buffer.create(4)) == 4)

# buffer constructors are not methods
ok = pcall(function() b1:create(8) end)
assert(ok == false)
ok = pcall(function() b1:fromstring("hi") end)
assert(ok == false)

# vectors: v:method(...) matches vector.method(v, ...)
a = vector.create(1, 0, 0)
e = vector.create(0, 1, 0)
assert(a:dot(e) == 0)
assert(a:cross(e).z == 1)
assert(a:normalize().x == 1)
assert(a:magnitude() == 1)
assert(a:lerp(e, 0.5).x == 0.5)
assert(a:floor().x == 1)
assert(a:ceil().x == 1)
assert(a:abs().x == 1)
assert(a:sign().x == 1)
assert(vector.magnitude(vector.create(3, 4, 0)) == 5)

# components still work
assert(a.x == 1 and a.y == 0 and a.z == 0)

# vector constructor is not a method
ok = pcall(function() a:create(1, 2, 3) end)
assert(ok == false)

# strings are unaffected
assert(("hello"):upper() == "HELLO")

return "OK"
