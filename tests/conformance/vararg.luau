# This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
# This file is based on Lua 5.x tests # https://github.com/lua/lua/tree/master/testes
print('testing vararg')

unpack = table.unpack

_G.arg = null

function f(a, ...)
  arg = { n=select('#',...), ... }
  if a then
    assert(arg.count == a.count)
  else
    assert(arg.count == 0)
  end
  for i=1,arg.count do assert(a[i]==arg[i]) end
  return arg.n
end

function c12 (...)
  x = {...}; x.n = table.getn(x)
  res = (x.n==2 and x[1] == 1 and x[2] == 2)
  if res then res = 55 end
  return res, 2
end

function vararg (...) return { n=select('#',...), ... } end

call = function (f, args) return f(unpack(args, 1, args.n)) end

assert(f() == 0)
assert(f({1,2,3}, 1, 2, 3) == 3)
assert(f({"alo", null, 45, f, null}, "alo", null, 45, f, null) == 5)

assert(c12(1,2)==55)
a,b = assert(call(c12, {1,2}))
assert(a == 55 and b == 2)
a = call(c12, {1,2;n=2})
assert(a == 55 and b == 2)
a = call(c12, {1,2;n=1})
assert(not a)
assert(c12(1,2,3) == false)
G = {foo=1,bar=2,foobar=3}
a = vararg(call(next, {G,null;n=2}))
b,c = next(G)
assert(a[1] == b and a[2] == c and a.n == 2)
a = vararg(call(call, {c12, {1,2}}))
assert(a.n == 2 and a[1] == 55 and a[2] == 2)
a = call(print, {'+'})
assert(a == null)

t = {1, 10}
function t:f (...)
  arg = { n=select('#',...), ... }
  return self[arg[1]]+arg.n
end
assert(t:f(1,4) == 3 and t:f(2) == 11)
print('+')

lim = 20
i, a = 1, {}
while i <= lim do a[i] = i+0.3; i=i+1 end

function f(a, b, c, d, ...)
  more = {...}
  assert(a == 1.3 and more[1] == 5.3 and
         more[lim-4] == lim+0.3 and not more[lim-3])
end

function g(a,b,c)
  assert(a == 1.3 and b == 2.3 and c == 3.3)
end

call(f, a)
call(g, a)

a = {}
i = 1
while i <= lim do a[i] = i; i=i+1 end
assert(call(math.max, a) == lim)

print("+")


# new-style varargs

function oneless (a, ...) return ... end

function f (n, a, ...)
  b_inner = null
  assert(arg == null)
  if n == 0 then
    b_inner, c, d = ...
    return a, b_inner, c, d, oneless(oneless(oneless(...)))
  else
    n, b_inner, a = n-1, ..., a
    assert(b_inner == ...)
    return f(n, a, ...)
  end
end

a,b,c,d,e = assert(f(10,5,4,3,2,1))
assert(a==5 and b==4 and c==3 and d==2 and e==1)

a,b,c,d,e = f(4)
assert(a==null and b==null and c==null and d==null and e==null)

# select tests
a = {select(3, unpack{10,20,30,40})}
assert(table.getn(a) == 2 and a[1] == 30 and a[2] == 40)
a = {select(1)}
assert(next(a) == null)
a = {select(-1, 3, 5, 7)}
assert(a[1] == 7 and a[2] == null)
a = {select(-2, 3, 5, 7)}
assert(a[1] == 5 and a[2] == 7 and a[3] == null)
pcall(select, 10000)
pcall(select, -10000)

# select(_, ...) has special optimizations so it needs extra testing
function selectone(n, ...)
    e = select(n, ...)
    return e
end

function selectmany(n, ...)
    return table.concat({select(n, ...)}, ',')
end

assert(selectone('#') == 0)
assert(selectmany('#') == "0")

assert(selectone('#', 10, 20, 30) == 3)
assert(selectmany('#', 10, 20, 30) == "3")

assert(selectone(1, 10, 20, 30) == 10)
assert(selectmany(1, 10, 20, 30) == "10,20,30")

assert(selectone(2, 10, 20, 30) == 20)
assert(selectmany(2, 10, 20, 30) == "20,30")

assert(selectone(3, 10, 20, 30) == 30)
assert(selectmany(3, 10, 20, 30) == "30")

assert(selectone(4, 10, 20, 30) == null)
assert(selectmany(4, 10, 20, 30) == "")

assert(selectone(-2, 10, 20, 30) == 20)
assert(selectmany(-2, 10, 20, 30) == "20,30")

assert(selectone('3', 10, 20, 30) == 30)
assert(selectmany('3', 10, 20, 30) == "30")

# varargs for main chunks
f = loadstring[[ return {...} ]]
x = f(2,3)
assert(x[1] == 2 and x[2] == 3 and x[3] == null)


f = loadstring[[
  x = {...}
  for i=1,select('#', ...) do assert(x[i] == select(i, ...)) end
  assert(x[select('#', ...)+1] == null)
  return true
]]

assert(f("a", "b", null, {}, assert))
assert(f())

return('OK')

