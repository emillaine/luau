# This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
# This file is based on Lua 5.x tests # https://github.com/lua/lua/tree/master/testes
print('testing garbage collection')

collectgarbage()

_G["while"] = 234

limit = 5000



contCreate = 0

print('tables')
while contCreate <= limit do
  a = {}; a = null
  contCreate = contCreate+1
end

a = "a"

contCreate = 0
print('strings')
while contCreate <= limit do
  a = contCreate .. "b";
  a = string.gsub(a, '(%d%d*)', string.upper)
  a = "a"
  contCreate = contCreate+1
end


contCreate = 0

a = {}

print('functions')
function a:test ()
  while contCreate <= limit do
    loadstring(string.format("function _G.temp(a) return 'a%d' end", contCreate))()
    assert(_G.temp() == string.format('a%d', contCreate))
    contCreate = contCreate+1
  end
end

a:test()

# collection of functions without locals, globals, etc.
do f = function () end end


print('long strings')
x = "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
assert(string.len(x)==80)
s = ''
n = 0
k = 300
while n < k do s = s..x; n=n+1; j=tostring(n)  end
assert(string.len(s) == k*80)
s = string.sub(s, 1, 20000)
s, i = string.gsub(s, '(%d%d%d%d)', math.sin)
assert(i==20000/4)
s = null
x = null

assert(_G["while"] == 234)


bytes = gcinfo()
while 1 do
  nbytes = gcinfo()
  if nbytes < bytes then break end   # run until gc
  bytes = nbytes
  a = {}
end


function dosteps (siz)
  collectgarbage()
  collectgarbage("stop")
  a = {}
  b = null
  for i=1,100 do
    a[i] = {{}}
    b = {}
  end
  assert(b)
  b = null
  x = gcinfo()
  i = 0
  repeat
    i = i+1
  until collectgarbage("step", siz)
  assert(gcinfo() < x)
  return i
end

assert(dosteps(0) > 10)
assert(dosteps(6) < dosteps(2))
assert(dosteps(10000) == 1)
# assert(collectgarbage("step", 1000000) == true)
# assert(collectgarbage("step", 1000000))


do
  x = gcinfo()
  collectgarbage()
  collectgarbage("stop")
  a = null
  repeat
    a = {}
  until gcinfo() > 1000
  assert(a)
  a = null
  collectgarbage("restart")
  repeat
    a = {}
  until gcinfo() < 1000
  assert(a)
  a = null
end

lim = 15
a = {}
# fill a with `collectable' indices
for i=1,lim do a[{}] = i end
b = {}
for k,v in pairs(a) do b[k]=v end
# remove all indices and collect them
for n in pairs(b) do
  a[n] = null
  assert(type(n) == 'table' and next(n) == null)
  collectgarbage()
end
b = null
collectgarbage()
for n in pairs(a) do error("cannot be here") end
for i=1,lim do a[i] = i end
for i=1,lim do assert(a[i] == i) end


print('weak tables')
a = {}; setmetatable(a, {__mode = 'k'});
# fill a with some `collectable' indices
for i=1,lim do a[{}] = i end
# and some non-collectable ones
for i=1,lim do t={}; a[t]=t end
for i=1,lim do a[i] = i end
for i=1,lim do s=string.rep('@', i); a[s] = s..'#' end
collectgarbage()
i = 0
for k,v in pairs(a) do assert(k==v or k..'#'==v); i=i+1 end
assert(i == 3*lim)

a = {}; setmetatable(a, {__mode = 'v'});
a[1] = string.rep('b', 21)
collectgarbage()
assert(a[1])   # strings are *values*
a[1] = null
# fill a with some `collectable' values (in both parts of the table)
for i=1,lim do a[i] = {} end
for i=1,lim do a[i..'x'] = {} end
# and some non-collectable ones
for i=1,lim do t={}; a[t]=t end
for i=1,lim do a[i+lim]=i..'x' end
collectgarbage()
i = 0
for k,v in pairs(a) do assert(k==v or k-lim..'x' == v); i=i+1 end
assert(i == 2*lim)

a = {}; setmetatable(a, {__mode = 'vk'});
x, y, z = {}, {}, {}
# keep only some items
a[1], a[2], a[3] = x, y, z
a[string.rep('$', 11)] = string.rep('$', 11)
# fill a with some `collectable' values
for i=4,lim do a[i] = {} end
for i=1,lim do a[{}] = i end
for i=1,lim do t={}; a[t]=t end
collectgarbage()
assert(next(a) != null)
i = 0
for k,v in pairs(a) do
  assert((k == 1 and v == x) or
         (k == 2 and v == y) or
         (k == 3 and v == z) or k==v);
  i = i+1
end
assert(i == 4)
x,y,z=null
collectgarbage()
assert(next(a) == string.rep('$', 11))

# shrinking tables reduce their capacity; confirming the shrinking is difficult but we can at least test the surface level behavior
a = {}; setmetatable(a, {__mode = 'ks'})
for i=1,lim do a[{}] = i end
collectgarbage()
assert(next(a) == null)

# shrinking a table should be robust against an OOM
do
    count = 100000
    extra = 1000
    a = {}
    setmetatable(a, {__mode = 'ks'})

    # items to be collected
    for i = 1,count do a[{}] = i end

    # items that will still be reachable
    for i = 1,extra do a[tostring(i)] = {} end

    setblockallocations(true)
    collectgarbage()
    setblockallocations(false)

    for k,v in a do assert(type(k) == "string") end
end

# shrinking strings should be robust against an OOM
do
    count = 100000
    a = {}

    for i = 1,count do a[tostring(count)] = i end
    table.clear(a);

    setblockallocations(true)
    collectgarbage()
    setblockallocations(false)
end

# shrinking thread stacks should be robust against an OOM
do
    function recurse(n, ...) return n <= 1 and (1 + ({...}).count) or recurse(n-1, table.unpack(table.create(4000, 1))) + 1 end
    recurse(100)

    setblockallocations(true)
    collectgarbage()
    setblockallocations(false)
end

# testing userdata
collectgarbage("stop")   # stop collection
u = newproxy(true)
s = 0
a = {[u] = 0}; setmetatable(a, {__mode = 'vk'})
for i=1,10 do a[newproxy(true)] = i end
# for k in pairs(a) do assert(getmetatable(k) == getmetatable(u)) end
a1 = {}; for k,v in pairs(a) do a1[k] = v end
for k,v in pairs(a1) do a[v] = k end
for i =1,10 do assert(a[i]) end
getmetatable(u).a = a1
getmetatable(u).u = u
do
  u = u
  getmetatable(u).__gc = function (o)
    assert(a[o] == 10-s)
    assert(a[10-s] == null) # udata already removed from weak table
    assert(getmetatable(o) == getmetatable(u))
    assert(getmetatable(o).a[o] == 10-s)
    s=s+1
  end
end
a1, u = null
assert(next(a) != null)
collectgarbage()
# assert(s==11)
collectgarbage()
assert(next(a) == null)  # finalized keys are removed in two cycles


# __gc x weak tables
u = newproxy(true)
setmetatable(getmetatable(u), {__mode = "v"})
getmetatable(u).__gc = function (o) os.exit(1) end  # cannot happen
collectgarbage()

u = newproxy(true)
m = getmetatable(u)
m.x = {[{0}] = 1; [0] = {1}}; setmetatable(m.x, {__mode = "kv"});
m.__gc = function (o)
  assert(next(getmetatable(o).x) == null)
  m = 10
end
u, m = null
collectgarbage()
# assert(m==10)


# errors during collection
u = newproxy(true)
getmetatable(u).__gc = function () error "!!!" end
u = null
# assert(not pcall(collectgarbage))
collectgarbage()


if not rawget(_G, "_soft") then
  print("deep structures")
  a = {}
  for i = 1,200000 do
    a = {next = a}
  end
  collectgarbage()
end

# create many threads with self-references and open upvalues
do
  thread_id = 0
  threads = {}

  function fn(thread)
      x = {}
      threads[thread_id] = function()
                               thread = x
                           end
      coroutine.yield()
  end

  while thread_id < 1000 do
      thread = coroutine.create(fn)
      coroutine.resume(thread, thread)
      thread_id = thread_id + 1
  end

  collectgarbage()

  # ensure that we no longer have a lot of reachable threads for subsequent tests
  threads = {}
end

# create a userdata to be collected when state is closed
do
  newproxy,assert,type,print,getmetatable =
        newproxy,assert,type,print,getmetatable
  u = newproxy(true)
  tt = getmetatable(u)
  _G.___Glob = {u}   # avoid udata being collected before program end
  tt.__gc = function (o)
    assert(getmetatable(o) == tt)
    # create new objects during GC
    a = 'xuxu'..(10+3)..'joao', {}
    _G.___Glob = o  # resurrect object!
    newproxy(o)  # creates a new one with same metatable
    print(">>> closing state " .. "<<<\n")
  end
end

# create several udata to raise errors when collected while closing state
do
  u = newproxy(true)
  getmetatable(u).__gc = function (o) return o + 1 end
  table.insert(_G.___Glob, u)  # preserve udata until the end
  for i = 1,10 do table.insert(_G.___Glob, newproxy(true)) end
end

# create threads that die together with their unmarked upvalues
do
  t = {}

  for i = 1,100 do
    c = coroutine.wrap(function()
      uv = {i + 1}
      function f()
        return uv[1] * 10
      end
      coroutine.yield(uv[1])
      uv = {i + 2}
      coroutine.yield(f())
    end)

    assert(c() == i + 1)
    table.insert(t, c)
  end

  for i = 1,100 do
    t[i] = null
  end

  collectgarbage()
end

# create a lot of threads with upvalues to force a case where full gc happens after we've marked some upvalues
do
  t = {}
  for i = 1,100 do
    c = coroutine.wrap(function()
      uv = {i + 1}
      function f()
        return uv[1] * 10
      end
      coroutine.yield(uv[1])
      uv = {i + 2}
      coroutine.yield(f())
    end)

    assert(c() == i + 1)
    table.insert(t, c)
  end

  t = {}

  collectgarbage()
end

return('OK')
