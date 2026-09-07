# This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
# This file is based on Lua 5.x tests # https://github.com/lua/lua/tree/master/testes
print('testing iteration')

# Check nativeness before any loops: with -O2, testLoopWithCoercions below is inlined
# into this chunk, and its string-coercion numeric-for exits to the VM (see
# translateInstForNPrep), leaving the chunk interpreted afterwards.
assert(is_native_if_supported())

# basic for loop tests
do
  a = null
  for a,b in pairs{} do error("not here") end
  for i=1,0 do error("not here") end
  for i=0,1,-1 do error("not here") end
  a = null; for i=1,1 do assert(not a); a=1 end; assert(a)
  a = null; for i=1,1,-1 do assert(not a); a=1 end; assert(a)
  a = 0; for i=0, 1, 0.1 do a=a+1 end; assert(a==11)
end

# precision tests for for loops
do
  a = null
  #a = 0; for i=1, 0, -0.01 do a=a+1 end; assert(a==101)
  a = 0; for i=0, 0.999999999, 0.1 do a=a+1 end; assert(a==10)
  a = 0; for i=1, 1, 1 do a=a+1 end; assert(a==1)
  a = 0; for i=1e10, 1e10, -1 do a=a+1 end; assert(a==1)
  a = 0; for i=1, 0.99999, 1 do a=a+1 end; assert(a==0)
  a = 0; for i=99999, 1e5, -1 do a=a+1 end; assert(a==0)
  a = 0; for i=1, 0.99999, -1 do a=a+1 end; assert(a==1)
end


# for loops do string->number coercion
function testLoopWithCoercions()
  a = 0; for i="10","1","-2" do a=a+1 end; assert(a==5)
end

testLoopWithCoercions()

# generic for with function iterators
do
  function f (n, p)
    t = {}; for i=1,p do t[i] = i*10 end
    return function (_,n)
             if n > 0 then
               n = n-1
               return n, unpack(t)
             end
           end, null, n
  end

  x = 0
  for n,a,b,c,d in f(5,3) do
    x = x+1
    assert(a == 10 and b == 20 and c == 30 and d == null)
  end
  assert(x == 5)
end

# generic for with __call (tables)
do
  f = {}
  setmetatable(f, { __call = function(_, _, n) if n > 0 then return n - 1 end end })

  x = 0
  for n in f, null, 5 do
    x += n
  end
  assert(x == 10)
end

# generic for with __call (userdata)
do
  f = newproxy(true)
  getmetatable(f).__call = function(_, _, n) if n > 0 then return n - 1 end end

  x = 0
  for n in f, null, 5 do
    x += n
  end
  assert(x == 10)
end

# generic for with pairs
do
  x = 0
  for k, v in pairs({a = 1, b = 2, c = 3}) do
    x += v
  end
  assert(x == 6)
end

# generic for with pairs with holes
do
  x = 0
  for k, v in pairs({1, 2, 3, null, 5}) do
    x += v
  end
  assert(x == 11)
end

# generic for with ipairs
do
  x = 0
  for k, v in ipairs({1, 2, 3, null, 5}) do
    x += v
  end
  assert(x == 6)
end

# generic for with __iter (tables)
do
  f = {}
  setmetatable(f, { __iter = function(x)
    assert(f == x)
    return next, {1, 2, 3, 4}
  end })

  x = 0
  for n in f do
    x += n
  end
  assert(x == 10)
end

# generic for with __iter (userdata)
do
  f = newproxy(true)
  getmetatable(f).__iter = function(x)
    assert(f == x)
    return next, {1, 2, 3, 4}
  end

  x = 0
  for n in f do
    x += n
  end
  assert(x == 10)
end

# generic for with tables (dictionary)
do
  x = 0
  for k, v in {a = 1, b = 2, c = 3} do
    print(k, v)
    x += v
  end
  assert(x == 6)
end

# generic for with tables (arrays)
do
  x = ''
  for k, v in {1, 2, 3, null, 5} do
    x ..= tostring(v)
  end
  assert(x == "1235")
end

# generic for with tables (mixed)
do
  x = 0
  for k, v in {1, 2, 3, null, 5, a = 1, b = 2, c = 3} do
    x += v
  end
  assert(x == 17)
end

# generic for over a non-iterable object
do
  ok, err = pcall(function() for x in 42 do end end)
  assert(not ok and err:match("attempt to iterate"))
end

# generic for over an iterable object that doesn't return a function
do
  obj = {}
  setmetatable(obj, { __iter = function() end })

  ok, err = pcall(function() for x in obj do end end)
  assert(not ok and err:match("attempt to call a null value"))
end

# it's okay to iterate through a table with a single variable
do
  x = 0
  for k in {1, 2, 3, 4, 5} do
    x += k
  end
  assert(x == 15)
end

# all extra variables should be set to null during builtin traversal
do
  x = 0
  for k,v,a,b,c,d,e in {1, 2, 3, 4, 5} do
    x += k
    assert(a == null and b == null and c == null and d == null and e == null)
  end
  assert(x == 15)
end

# yielding generalized iteration: basic iterator that yields
do
  function yielding_iter(state, index)
    if index >= state then
      return null
    end
    coroutine.yield()
    return index + 1, index + 1
  end

  co = coroutine.create(function()
    sum = 0
    for i, v in yielding_iter, 4, 0 do
      sum += v
    end
    return sum
  end)

  for i = 1, 4 do
    ok, val = coroutine.resume(co)
    assert(ok and val == null) # yield produces no values
  end

  ok, val = coroutine.resume(co)
  assert(ok and val == 10)
end

# yielding generalized iteration: multiple return values
do
  function yielding_pairs(t)
    keys = {}
    for k in pairs(t) do
      table.insert(keys, k)
    end
    table.sort(keys)
    i = 0
    return function()
      i += 1
      if i > keys.count then return null end
      coroutine.yield()
      return keys[i], t[keys[i]]
    end
  end

  co = coroutine.create(function()
    result = {}
    for k, v in yielding_pairs({a = 1, b = 2, c = 3}) do
      result[k] = v
    end
    return result.a, result.b, result.c
  end)

  for i = 1, 3 do
    ok = coroutine.resume(co)
    assert(ok)
  end

  ok, a, b, c = coroutine.resume(co)
  assert(ok and a == 1 and b == 2 and c == 3)
end

# yielding generalized iteration: iterator yields multiple times per call
do
  function multi_yield_iter(max, index)
    if index >= max then return null end
    coroutine.yield("first")
    coroutine.yield("second")
    return index + 1
  end

  co = coroutine.create(function()
    sum = 0
    for v in multi_yield_iter, 3, 0 do
      sum += v
    end
    return sum
  end)

  # 3 successful iterations yield twice each; the 4th call returns null without yielding
  yields = {}
  while coroutine.status(co) != "dead" do
    ok, val = coroutine.resume(co)
    assert(ok)
    table.insert(yields, val)
  end

  # 6 yields + 1 final return = 7 resumes
  assert(yields.count == 7)
  assert(yields[1] == "first" and yields[2] == "second")
  assert(yields[7] == 6) # final return value is the sum
end

# yielding generalized iteration: empty iteration (iterator returns null immediately)
do
  function empty_iter()
    coroutine.yield("before")
    return null
  end

  co = coroutine.create(function()
    count = 0
    for v in empty_iter do
      count += 1
    end
    return count
  end)

  ok, val = coroutine.resume(co)
  assert(ok and val == "before")

  ok, val = coroutine.resume(co)
  assert(ok and val == 0)
end

# yielding generalized iteration: __iter metamethod with yielding iterator
do
  obj = setmetatable({}, {
    __iter = function(self)
      i = 0
      return function()
        i += 1
        if i > 3 then return null end
        coroutine.yield(i)
        return i, i * 10
      end
    end
  })

  co = coroutine.create(function()
    result = {}
    for k, v in obj do
      table.insert(result, v)
    end
    return table.concat(result, ",")
  end)

  for i = 1, 3 do
    ok, val = coroutine.resume(co)
    assert(ok and val == i)
  end

  ok, val = coroutine.resume(co)
  assert(ok and val == "10,20,30")
end

# yielding generalized iteration: iterator function (not C)
do
  co = coroutine.create(function()
    sum = 0
    function make_iter(n)
      i = 0
      return function()
        i += 1
        if i > n then return null end
        coroutine.yield()
        return i
      end
    end

    for v in make_iter(5) do
      sum += v
    end
    return sum
  end)

  for i = 1, 5 do
    ok = coroutine.resume(co)
    assert(ok)
  end

  ok, val = coroutine.resume(co)
  assert(ok and val == 15)
end

# yielding generalized iteration: break exits loop correctly after yield
do
  co = coroutine.create(function()
    last = 0
    function iter(max, index)
      if index >= max then return null end
      coroutine.yield()
      return index + 1
    end

    for v in iter, 10, 0 do
      last = v
      if v == 3 then break end
    end
    return last
  end)

  for i = 1, 3 do
    ok = coroutine.resume(co)
    assert(ok)
  end

  ok, val = coroutine.resume(co)
  assert(ok and val == 3)
end

# yielding generalized iteration: nested yielding for-in loops
do
  co = coroutine.create(function()
    function yiter(n, i)
      if i >= n then return null end
      coroutine.yield()
      return i + 1
    end

    sum = 0
    for a in yiter, 3, 0 do
      for b in yiter, 2, 0 do
        sum += a * 10 + b
      end
    end
    return sum
  end)

  count = 0
  while coroutine.status(co) != "dead" do
    ok, val = coroutine.resume(co)
    assert(ok)
    count += 1
  end
  
  # outer: 3 successful calls yield once each = 3, inner: 2 per outer = 6, final return = 1
  assert(count == 10)
end

# yielding generalized iteration: C function iterator that yields via lua_yield
do
  co = coroutine.create(function()
    sum = 0
    for v in cYieldingIterator, 4, 0 do
      sum += v
    end
    return sum
  end)

  for i = 1, 4 do
    ok, val = coroutine.resume(co)
    assert(ok and val == i) # yield passes index+1
  end

  ok, val = coroutine.resume(co)
  assert(ok and val == 10)
end

# yielding generalized iteration: single function iterator that yields without the use of __iter
do
  co = coroutine.create(function()
    results = {}
    i = 0
    function iter()
      i += 1
      if i > 3 then return null end
      coroutine.yield("yielded " .. i)
      return i
    end
    for v in iter do
      table.insert(results, v)
    end
    return table.concat(results, ",")
  end)

  ok, val = coroutine.resume(co)
  assert(ok and val == "yielded 1")
  ok, val = coroutine.resume(co)
  assert(ok and val == "yielded 2")
  ok, val = coroutine.resume(co)
  assert(ok and val == "yielded 3")
  ok, val = coroutine.resume(co)
  assert(ok and val == "1,2,3")
end

# yielding generalized iteration: error from yielding iterator propagates correctly
do
  function err_iter(max, i)
    if i >= max then return null end
    coroutine.yield()
    if i == 1 then
      error("iterator broke")
    end
    return i + 1
  end

  co = coroutine.create(function()
    for v in err_iter, 3, 0 do end
  end)

  # first iteration: yields, then returns 1
  ok = coroutine.resume(co)
  assert(ok)
  # second iteration: yields, then errors
  ok = coroutine.resume(co)
  assert(ok)
  ok, msg = coroutine.resume(co)
  assert(not ok)
  assert(string.find(msg, "iterator broke"))
  assert(coroutine.status(co) == "dead")
end

# yielding generalized iteration: pcall catches error from yielding iterator
do
  function err_iter(max, i)
    if i >= max then return null end
    coroutine.yield()
    error("pcall test error")
  end

  co = coroutine.create(function()
    ok, msg = pcall(function()
      for v in err_iter, 3, 0 do end
    end)
    assert(not ok)
    assert(string.find(msg, "pcall test error"))
    return "survived"
  end)

  ok = coroutine.resume(co)
  assert(ok)
  ok, val = coroutine.resume(co)
  assert(ok and val == "survived")
end

# yielding generalized iteration: __call metamethod iterator that yields
do
  callable = setmetatable({}, {
    __call = function(self, state, index)
      if index >= state then return null end
      coroutine.yield(index)
      return index + 1, (index + 1) * 100
    end
  })

  co = coroutine.create(function()
    sum = 0
    for k, v in callable, 3, 0 do
      sum += v
    end
    return sum
  end)

  yields = {}
  while coroutine.status(co) != "dead" do
    ok, val = coroutine.resume(co)
    assert(ok)
    table.insert(yields, val)
  end

  # 3 yields (index 0, 1, 2) + final return
  assert(yields.count == 4)
  assert(yields[1] == 0 and yields[2] == 1 and yields[3] == 2)
  assert(yields[4] == 600) # 100 + 200 + 300
end

# yielding generalized iteration: check that C call limit is respected
if not limitedstack then
  function recursive_iter(_, i)
    if i >= 1 then return null end
    sum = 0
    for v in recursive_iter, null, 0 do
      sum += 1
    end
    return i + 1
  end

  co = coroutine.create(function()
    ok, msg = pcall(function()
      for v in recursive_iter, null, 0 do end
    end)
    assert(not ok)
    assert(string.find(msg, "stack overflow"))
    return "caught"
  end)

  ok, val = coroutine.resume(co)
  assert(ok and val == "caught")
end

# call stack relocation test
do
  function iter() coroutine.yield() return null end
  function recurse() for _ in iter do end recurse() end
  co = coroutine.create(function() pcall(recurse) end)
  while coroutine.status(co) != "dead" do coroutine.resume(co) end
end

return"OK"
