# This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
# This file is based on Lua 5.x tests # https://github.com/lua/lua/tree/master/testes
print("testing functions and calls")

# get the opportunity to test 'type' too ;)

assert(type(1<2) == 'boolean')
assert(type(true) == 'boolean' and type(false) == 'boolean')
assert(type(null) == 'null' and type(-3) == 'number' and type'x' == 'string' and
       type{} == 'table' and type(type) == 'function')

assert(type(assert) == type(print))
f = null
function f (x) return a:x (x) end
assert(type(f) == 'function')

pack = table.pack
unpack = table.unpack

# testing local-function recursion
fact = false
do
  const res = 1
  const function fact (n)
    if n==0 then return res
    else return n*fact(n-1)
  end
  assert(fact(5) == 120)
end
assert(fact == false)

# testing declarations
a = {i = 10}
self = 20
function a:x (x) return x+self.i end
function a.y (x) return x+self end

assert(a:x(1)+10 == a.y(1))

a.t = {i=-100}
a["t"].x = function (self, a,b) return self.i+a+b end

assert(a.t:x(2,3) == -95)

do
  a = {x=0}
  function a:add (x) self.x, a.y = self.x+x, 20; return self end
  assert(a:add(10):add(20):add(30).x == 60 and a.y == 20)
end

a = {b={c={}}}

function a.b.c.f1 (x) return x+1 end
function a.b.c:f2 (x,y) self[x] = y end
assert(a.b.c.f1(4) == 5)
a.b.c:f2('k', 12); assert(a.b.c.k == 12)

print('+')

t = null   # 'declare' t
function f(a,b,c) d = 'a'; t={a,b,c,d} end

f(      # this line change must be valid
  1,2)
assert(t[1] == 1 and t[2] == 2 and t[3] == null and t[4] == 'a')
f(1,2,   # this one too
      3,4)
assert(t[1] == 1 and t[2] == 2 and t[3] == 3 and t[4] == 'a')

function fat(x)
  if x <= 1 then return 1
  else return x*loadstring("return _G.fat(" .. x-1 .. ")")()
end
_G.fat = fat

assert(loadstring "loadstring 'assert(_G.fat(6)==720)' () ")()
a = loadstring('return _G.fat(5), 3')
a,b = a()
assert(a == 120 and b == 3)
print('+')

function err_on_n (n)
  if n==0 then error(); exit(1);
  else err_on_n (n-1); exit(1);
end

function dummy (n)
  if n > 0 then
    assert(not pcall(err_on_n, n))
    dummy(n-1)
  end
end

dummy(10)

function deep (n)
  if n>0 then deep(n-1) end
end
deep(10)
deep(200)

# testing tail call
function deep (n) if n>0 then return deep(n-1) else return 101 end end
assert(deep(10000) == 101)
a = {}
function a:deep (n) if n>0 then return self:deep(n-1) else return 101 end end
assert(a:deep(10000) == 101)

print('+')


a = null
(function (x) a=x end)(23)
assert(a == 23 and (function (x) return x*2 end)(20) == 40)


x,y,z,a = null, null, null, null
a = {}; lim = 2000
for i=1, lim do a[i]=i end
assert(select(lim, unpack(a)) == lim and select('#', unpack(a)) == lim)
x = unpack(a)
assert(x == 1)
x = {unpack(a)}
assert(table.getn(x) == lim and x[1] == 1 and x[lim] == lim)
x = {unpack(a, lim-2)}
assert(table.getn(x) == 3 and x[1] == lim-2 and x[3] == lim)
x = {unpack(a, 10, 6)}
assert(next(x) == null)   # no elements
x = {unpack(a, 11, 10)}
assert(next(x) == null)   # no elements
x,y = unpack(a, 10, 10)
assert(x == 10 and y == null)
x,y,z = unpack(a, 10, 11)
assert(x == 10 and y == 11 and z == null)
a,x = unpack{1}
assert(a==1 and x==null)
a,x = unpack({1,2}, 1, 1)
assert(a==1 and x==null)


# testing closures

# fixed-point operator
Y = function (le)
      function a (f)
        return le(function (x) return f(f)(x) end)
      end
      return a(a)
    end


# non-recursive factorial

F = function (f)
      return function (n)
               if n == 0 then return 1
               else return n*f(n-1) end
             end
    end

fat = Y(F)

assert(fat(0) == 1 and fat(4) == 24 and Y(F)(5)==5*Y(F)(4))

function g (z)
  function f (a,b,c,d)
    return function (x,y) return a+b+c+d+a+x+y+z end
  end
  return f(z,z+1,z+2,z+3)
end

f = g(10)
assert(f(9, 16) == 10+11+12+13+10+9+16+10)

Y, F, f = null
print('+')

# testing multiple returns

function unlpack (t, i)
  i = i or 1
  if (i <= table.getn(t)) then
    return t[i], unlpack(t, i+1)
  end
end

function equaltab (t1, t2)
  assert(table.getn(t1) == table.getn(t2))
  for i,v1 in ipairs(t1) do
    assert(v1 == t2[i])
  end
end

function f() return 1,2,30,4 end
function ret2 (a,b) return a,b end

a,b,c,d = unlpack{1,2,3}
assert(a==1 and b==2 and c==3 and d==null)
a = {1,2,3,4,false,10,'alo',false,assert}
equaltab(pack(unlpack(a)), a)
equaltab(pack(unlpack(a), -1), {1,-1})
a,b,c,d = ret2(f()), ret2(f())
assert(a==1 and b==1 and c==2 and d==null)
a,b,c,d = unlpack(pack(ret2(f()), ret2(f())))
assert(a==1 and b==1 and c==2 and d==null)
a,b,c,d = unlpack(pack(ret2(f()), (ret2(f()))))
assert(a==1 and b==1 and c==null and d==null)

a = ret2{ unlpack{1,2,3}, unlpack{3,2,1}, unlpack{"a", "b"}}
assert(a[1] == 1 and a[2] == 3 and a[3] == "a" and a[4] == "b")


# testing calls with 'incorrect' arguments
rawget({}, "x", 1)
rawset({}, "x", 1, 2)
assert(math.sin(1,2) == math.sin(1))
table.sort({10,9,8,4,19,23,0,0}, function (a,b) return a<b end, "extra arg")


# test for bug in parameter adjustment
assert((function () return null end)(4) == null)
assert((function () a = null; return a end)(4) == null)
assert((function (a) return a end)() == null)

 # test for a bug in clobbering stack variables 
 # this call to print will clobber x and y if the call to f is not properly setup
function clobber()
   print("abcdefg", "hijklmnop")

end

x = { }
y = { }

x[1] = 1234
x[2] = 4567

clobber()

assert(x[1] == 1234)
assert(x[2] == 4567)

# C-stack overflow while handling C-stack overflow
if not limitedstack then
  function loop ()
    assert(pcall(loop))
  end

  err, msg = xpcall(loop, loop)
  assert(not err and string.find(msg, "error"))
end

# testing deep nested calls with a large thread stack
if not limitedstack then
  function recurse(n, ...) return n <= 1 and (1 + ({...}).count) or recurse(n-1, table.unpack(table.create(4000, 1))) + 1 end

  ok, msg = pcall(recurse, 19000)
  assert(not ok and string.find(msg, "too many results to unpack"))
end

return('OK')
