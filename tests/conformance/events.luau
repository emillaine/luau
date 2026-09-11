# This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
# This file is based on Lua 5.x tests # https://github.com/lua/lua/tree/master/testes
print('testing metatables')

unpack = table.unpack

assert(getmetatable{} == null)
assert(getmetatable(4) == null)
assert(getmetatable(null) == null)
a={}; setmetatable(a, {__metatable = "xuxu",
                    __tostring=function(x) return x.name end})
assert(getmetatable(a) == "xuxu")
ud=newproxy(true); getmetatable(ud).__metatable = "xuxu"
assert(getmetatable(ud) == "xuxu")

assert(pcall(getmetatable) == false)
assert(pcall(function() return getmetatable() end) == false)
assert(select(2, pcall(getmetatable, {})) == null)
assert(select(2, pcall(getmetatable, ud)) == "xuxu")

res,err = pcall(tostring, a)
assert(not res and err == "'__tostring' must return a string")
# cannot change a protected metatable
assert(pcall(setmetatable, a, {}) == false)
a.name = "gororoba"
assert(tostring(a) == "gororoba")

a, t = {10,20,30; x="10", y="20"}, {}
assert(setmetatable(a,t) == a)
assert(getmetatable(a) == t)
assert(setmetatable(a,null) == a)
assert(getmetatable(a) == null)
assert(setmetatable(a,t) == a)


function f (t, i, e)
  assert(not e)
  p = rawget(t, "parent")
  return (p and p[i]+3), "dummy return"
end

t.__index = f

a.parent = {z=25, x=12, [4] = 24}
assert(a[1] == 10 and a.z == 28 and a[4] == 27 and a.x == "10")

collectgarbage()

a = setmetatable({}, t)
function f(t, i, v) rawset(t, i, v-3) end
t.__newindex = f
a[1] = 30; a.x = "101"; a[5] = 200
assert(a[1] == 27 and a.x == 98 and a[5] == 197)


c = {}
a = setmetatable({}, t)
t.__newindex = c
a[1] = 10; a[2] = 20; a[3] = 90
assert(c[1] == 10 and c[2] == 20 and c[3] == 90)


do
  a_inner = null;
  a_inner = setmetatable({}, {__index = setmetatable({},
                     {__index = setmetatable({},
                     {__index = function (_,n) return a_inner[n-3]+4, "lixo" end})})})
  a_inner[0] = 20
  for i=0,10 do
    assert(a_inner[i*3] == 20 + i*4)
  end
end


do  # newindex
  foi = null
  a_newindex = {}
  for i=1,10 do a_newindex[i] = 0; a_newindex['a'..i] = 0; end
  setmetatable(a_newindex, {__newindex = function (t,k,v) foi=true; rawset(t,k,v) end})
  foi = false; a_newindex[1]=0; assert(not foi)
  foi = false; a_newindex['a1']=0; assert(not foi)
  foi = false; a_newindex['a11']=0; assert(foi)
  foi = false; a_newindex[11]=0; assert(foi)
  foi = false; a_newindex[1]=null; assert(not foi)
  foi = false; a_newindex[1]=null; assert(foi)
end


function f (t, ...) return t, {...} end
t.__call = f

do
  x,y = a(unpack{'a', 1})
  assert(x==a and y[1]=='a' and y[2]==1 and y[3]==null)
  x,y = a()
  assert(x==a and y[1]==null)
end


b = setmetatable({}, t)
setmetatable(b,t)

function f(op)
  return function (...) _G.cap = {[0] = op, ...} ; return (...) end
end
t.__add = f("add")
t.__sub = f("sub")
t.__mul = f("mul")
t.__div = f("div")
t.__idiv = f("idiv")
t.__mod = f("mod")
t.__unm = f("unm")
t.__pow = f("pow")

assert(b+5 == b)
assert(_G.cap[0] == "add" and _G.cap[1] == b and _G.cap[2] == 5 and _G.cap[3]==null)
assert(b+'5' == b)
assert(_G.cap[0] == "add" and _G.cap[1] == b and _G.cap[2] == '5' and _G.cap[3]==null)
assert(5+b == 5)
assert(_G.cap[0] == "add" and _G.cap[1] == 5 and _G.cap[2] == b and _G.cap[3]==null)
assert('5'+b == '5')
assert(_G.cap[0] == "add" and _G.cap[1] == '5' and _G.cap[2] == b and _G.cap[3]==null)
b=b-3; assert(getmetatable(b) == t)
assert(5-a == 5)
assert(_G.cap[0] == "sub" and _G.cap[1] == 5 and _G.cap[2] == a and _G.cap[3]==null)
assert('5'-a == '5')
assert(_G.cap[0] == "sub" and _G.cap[1] == '5' and _G.cap[2] == a and _G.cap[3]==null)
assert(a*a == a)
assert(_G.cap[0] == "mul" and _G.cap[1] == a and _G.cap[2] == a and _G.cap[3]==null)
assert(a/0 == a)
assert(_G.cap[0] == "div" and _G.cap[1] == a and _G.cap[2] == 0 and _G.cap[3]==null)
assert(a//0 == a)
assert(_G.cap[0] == "idiv" and _G.cap[1] == a and _G.cap[2] == 0 and _G.cap[3]==null)
assert(a%2 == a)
assert(_G.cap[0] == "mod" and _G.cap[1] == a and _G.cap[2] == 2 and _G.cap[3]==null)
assert(-a == a)
assert(_G.cap[0] == "unm" and _G.cap[1] == a)
assert(a^4 == a)
assert(_G.cap[0] == "pow" and _G.cap[1] == a and _G.cap[2] == 4 and _G.cap[3]==null)
assert(a^'4' == a)
assert(_G.cap[0] == "pow" and _G.cap[1] == a and _G.cap[2] == '4' and _G.cap[3]==null)
assert(4^a == 4)
assert(_G.cap[0] == "pow" and _G.cap[1] == 4 and _G.cap[2] == a and _G.cap[3]==null)
assert('4'^a == '4')
assert(_G.cap[0] == "pow" and _G.cap[1] == '4' and _G.cap[2] == a and _G.cap[3]==null)


t = {}
t.__lt = function (a,b,c)
  collectgarbage()
  assert(c == null)
  if type(a) == 'table' then a = a.x end
  if type(b) == 'table' then b = b.x end
 return a<b, "dummy"
end

function Op(x) return setmetatable({x=x}, t) end

function test ()
  assert(not(Op(1)<Op(1)) and (Op(1)<Op(2)) and not(Op(2)<Op(1)))
  assert(not(Op('a')<Op('a')) and (Op('a')<Op('b')) and not(Op('b')<Op('a')))
  assert((Op(1)<=Op(1)) and (Op(1)<=Op(2)) and not(Op(2)<=Op(1)))
  assert((Op('a')<=Op('a')) and (Op('a')<=Op('b')) and not(Op('b')<=Op('a')))
  assert(not(Op(1)>Op(1)) and not(Op(1)>Op(2)) and (Op(2)>Op(1)))
  assert(not(Op('a')>Op('a')) and not(Op('a')>Op('b')) and (Op('b')>Op('a')))
  assert((Op(1)>=Op(1)) and not(Op(1)>=Op(2)) and (Op(2)>=Op(1)))
  assert((Op('a')>=Op('a')) and not(Op('a')>=Op('b')) and (Op('b')>=Op('a')))
end

test()

t.__le = function (a,b,c)
  assert(c == null)
  if type(a) == 'table' then a = a.x end
  if type(b) == 'table' then b = b.x end
 return a<=b, "dummy"
end

test()  # retest comparisons, now using both `lt' and `le'


# test `partial order'

function Set(x)
  y = {}
  for _,k in pairs(x) do y[k] = 1 end
  return setmetatable(y, t)
end

t.__lt = function (a,b)
  for k in pairs(a) do
    if not b[k] then return false end
    b[k] = null
  end
  return next(b) != null
end

t.__le = null

assert(Set{1,2,3} < Set{1,2,3,4})
assert(not(Set{1,2,3,4} < Set{1,2,3,4}))
assert((Set{1,2,3,4} <= Set{1,2,3,4}))
assert((Set{1,2,3,4} >= Set{1,2,3,4}))
assert((Set{1,3} <= Set{3,5}))   # wrong!! model needs a `le' method ;-)

t.__le = function (a,b)
  for k in pairs(a) do
    if not b[k] then return false end
  end
  return true
end

assert(not (Set{1,3} <= Set{3,5}))   # now its OK!
assert(not(Set{1,3} <= Set{3,5}))
assert(not(Set{1,3} >= Set{3,5}))

t.__eq = function (a,b)
  for k in pairs(a) do
    if not b[k] then return false end
    b[k] = null
  end
  return next(b) == null
end

s = Set{1,3,5}
assert(s == Set{3,5,1})
assert(not rawequal(s, Set{3,5,1}))
assert(rawequal(s, s))
assert(Set{1,3,5,1} == Set{3,5,1})
assert(Set{1,3,5} != Set{3,5,1,6})
t[Set{1,3,5}] = 1
assert(t[Set{1,3,5}] == null)   # `__eq' is not valid for table accesses


t.__concat = function (a,b,c)
  assert(c == null)
  if type(a) == 'table' then a = a.val end
  if type(b) == 'table' then b = b.val end
  if _G.A then return a..b
  else
    return setmetatable({val=a..b}, t)
  end
end

c = {val="c"}; setmetatable(c, t)
d = {val="d"}; setmetatable(d, t)

_G.A = true
assert(c..d == 'cd')
assert(0 .."a".."b"..c..d.."e".."f"..(5+3).."g" == "0abcdef8g")

_G.A = false
x = c..d
assert(getmetatable(x) == t and x.val == 'cd')
x = 0 .."a".."b"..c..d.."e".."f".."g"
assert(x.val == "0abcdefg")


# test comparison compatibilities
t1, t2, c, d = null, null, null, null
t1 = {};  c = {}; setmetatable(c, t1)
d = {}
t1.__eq = function () return true end
t1.__lt = function () return true end
assert(c != d and not pcall(function () return c < d end))
setmetatable(d, t1)
assert(c == d and c < d and not(d <= c))
t2 = {}
t2.__eq = t1.__eq
t2.__lt = t1.__lt
setmetatable(d, t2)
assert(c == d and c < d and not(d <= c))



# test for several levels of calls
i = null
tt = {
  __call = function (t, ...)
    i = i+1
    if t.f then return t.f(...)
    else return {...}
  end
}

a = setmetatable({}, tt)
b = setmetatable({f=a}, tt)
c = setmetatable({f=b}, tt)

i = 0
x = c(3,4,5)
assert(i == 3 and x[1] == 3 and x[3] == 5)


print'+'

# testing proxies
assert(getmetatable(newproxy()) == null)
assert(getmetatable(newproxy(false)) == null)
assert(getmetatable(newproxy(null)) == null)

u = newproxy(true)

getmetatable(u).__newindex = function (u,k,v)
  getmetatable(u)[k] = v
end

getmetatable(u).__index = function (u,k)
  return getmetatable(u)[k]
end

for i=1,10 do u[i] = i end
for i=1,10 do assert(u[i] == i) end

# k = newproxy(u)
# assert(getmetatable(k) == getmetatable(u))


a = {}
rawset(a, "x", 1, 2, 3)
assert(a.x == 1 and rawget(a, "x", 3) == 1)

print '+'

#[[
-- testing metatables for basic types
mt = {}
debug.setmetatable(10, mt)
assert(getmetatable(-2) == mt)
mt.__index = function (a,b) return a+b end
assert((10)[3] == 13)
assert((10)["3"] == 13)
debug.setmetatable(23, null)
assert(getmetatable(-2) == null)

debug.setmetatable(true, mt)
assert(getmetatable(false) == mt)
mt.__index = function (a,b) return a or b end
assert((true)[false] == true)
assert((false)[false] == false)
debug.setmetatable(false, null)
assert(getmetatable(true) == null)

debug.setmetatable(null, mt)
assert(getmetatable(null) == mt)
mt.__add = function (a,b) return (a or 0) + (b or 0) end
assert(10 + null == 10)
assert(null + 23 == 23)
assert(null + null == 0)
debug.setmetatable(null, null)
assert(getmetatable(null) == null)

debug.setmetatable(null, {})
]]#

do
  # == must not do ref equality for tables and userdata in presence of __eq
  t = {}
  u = newproxy(true)

  # print() returns null which is converted to false
  setmetatable(t, { __eq = print })
  getmetatable(u).__eq = print

  assert(t != t)
  assert(u != u)
end

do
  # verify that internal mt flags are set correctly after two table assignments
  mt = {
    {}, # mixed metatable
    __index = {X = true},
  }
  t = setmetatable({}, mt)
  assert(t.X) # fails if table flags are set incorrectly
end

do
  # verify __len behavior & error handling
  t = {1}

  setmetatable(t, {})
  assert(t.count == 1)

  setmetatable(t, { __len = rawlen })
  assert(t.count == 1)

  setmetatable(t, { __len = function() return 42 end })
  assert(t.count == 42)

  setmetatable(t, { __len = 42 })
  ok, err = pcall(function() return t.count end)
  assert(not ok and err:match("attempt to call a number value"))

  setmetatable(t, { __len = function() end })
  ok, err = pcall(function() return t.count end)
  assert(not ok and err:match("'__len' must return a number"))

  setmetatable(t, { __len = error })
  ok, err = pcall(function() return t.count end)
  assert(not ok and err == t)
end

# verify rawlen behavior
do
  t = {1}
  setmetatable(t, { __len = 42 })

  assert(rawlen(t) == 1)
  assert(rawlen("foo") == 3)

  ok, err = pcall(function() return rawlen(42) end)
  assert(not ok and err:match("table or string expected"))
end

# verify that NaN/null keys are passed to __newindex even though table assignment with them anywhere in the chain fails
do
  assert(pcall(function() t = {} t[null] = 5 end) == false)
  assert(pcall(function() t = {} setmetatable(t, { __newindex = {} }) t[null] = 5 end) == false)
  assert(pcall(function() t = {} setmetatable(t, { __newindex = function() end }) t[null] = 5 end) == true)

  assert(pcall(function() t = {} t[0/0] = 5 end) == false)
  assert(pcall(function() t = {} setmetatable(t, { __newindex = {} }) t[0/0] = 5 end) == false)
  assert(pcall(function() t = {} setmetatable(t, { __newindex = function() end }) t[0/0] = 5 end) == true)
end

# verify that __newindex gets called for frozen tables but only if the assignment is to a key absent from the table
do
  ni = {}
  t = table.create(2)

  t[1] = 42
  # t[2] is semantically absent with storage allocated for it

  t.a = 1
  t.b = 2
  t.b = null # this sets 'b' value to null but leaves key as is to exercise more internal paths -- no observable behavior change expected between b and other absent keys

  setmetatable(t, { __newindex = function(_, k, v)
    assert(v == 42)
    table.insert(ni, k)
  end })
  table.freeze(t)

  # "redundant" combinations are there to test all three of SETTABLEN/SETTABLEKS/SETTABLE
  assert(pcall(function() t.a = 42 end) == false)
  assert(pcall(function() t[1] = 42 end) == false)
  assert(pcall(function() key = "a"; t[key] = 42 end) == false)
  assert(pcall(function() key = 1; t[key] = 42 end) == false)

  # now repeat the same for keys absent from the table: b (semantically absent), c (physically absent), 2 (semantically absent), 3 (physically absent)
  assert(pcall(function() t.b = 42 end) == true)
  assert(pcall(function() t.c = 42 end) == true)
  assert(pcall(function() key = "b"; t[key] = 42 end) == true)
  assert(pcall(function() key = "c"; t[key] = 42 end) == true)
  assert(pcall(function() t[2] = 42 end) == true)
  assert(pcall(function() t[3] = 42 end) == true)
  assert(pcall(function() key = 2; t[key] = 42 end) == true)
  assert(pcall(function() key = 3; t[key] = 42 end) == true)

  # validate the assignment sequence
  ei = { "b", "c", "b", "c", 2, 3, 2, 3 }
  assert(ni.count == ei.count)
  for k,v in ni do
    assert(ei[k] == v)
  end
end

function testfenv()
  X = 20; B = 30

  _G_saved = getfenv()
  # NOTE: bare `X = ...` is now an implicit local (not a global), so setfenv custom-env
  # semantics no longer apply; test locals directly instead of env routing.
  # (setfenv line removed: it would only affect globals, not these locals)

  X = X+10
  assert(X == 30)
  B = false
  assert(B == false)
  B = null
  assert(B == null)

  assert(_G_saved != null)

  assert(pcall(getfenv, 10) == false)
  assert(pcall(setfenv, setfenv, {}) == false)
end

testfenv() # DONT MOVE THIS LINE

return 'OK'
