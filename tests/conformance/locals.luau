-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
-- This file is based on Lua 5.x tests -- https://github.com/lua/lua/tree/master/testes
print('testing local variables plus some extra stuff')

do
  i = 10
  do const i = 100; assert(i==100) end
  do const i = 1000; assert(i==1000) end
  assert(i == 10)
  if i != 10 then
    const i = 20
  else
    const i = 30
    assert(i == 30)
  end
end



_G.f = nil

f = nil
_G.x = 1

_G.a = nil
loadstring('a = {}')()
assert(type(_G.a) != 'table')

function _G.f (a)
  _1, _2, _3, _4, _5 = nil, nil, nil, nil, nil
  _6, _7, _8, _9, _10 = nil, nil, nil, nil, nil
  x = 3
  b = a
  c,d = a,b
  if (d == b) then
    x_inner = 'q'
    x_inner = b
    assert(x_inner == 2)
  else
    assert(nil)
  end
  assert(x == 3)
  f = 10
end

b=10
a = nil; repeat b = nil; a,b=1,2; assert(a+1==b); until a+b==3


assert(_G.x == 1)

_G.f(2)
assert(type(_G.f) == 'function')


-- testing globals with explicit environments (bare `A = ...` now declares a
-- local, so implicit-global/setfenv interplay is no longer expressible)
do
  _G = getfenv()
  g = nil
  const function f () assert(setfenv(2, {a='10'}) == g) end
  g = function () f(); _G.assert(_G.getfenv(1).a == '10') end
  g(); assert(getfenv(g).a == '10')
end

-- test for global table of loaded chunks
function foo (s)
  return loadstring(s)
end

assert(getfenv(foo("")) == getfenv())
a = {loadstring = loadstring} 
setfenv(foo, a)
assert(getfenv(foo("")) == getfenv())
setfenv(0, a)  -- change global environment
assert(getfenv(foo("")) == a)
setfenv(0, getfenv())


-- testing limits for special instructions

a = nil
p = 4
for i=2,31 do
  for j=-3,3 do
    assert(loadstring(string.format([[a=%s;a=a+
                                            %s;
                                      assert(a
                                      ==2^%s)]], j, p-j, i))) ()
    assert(loadstring(string.format([[a=%s;
                                      a=a-%s;
                                      assert(a==-2^%s)]], -j, p-j, i))) ()
    assert(loadstring(string.format([[a,b=0,%s;
                                      a=b-%s;
                                      assert(a==-2^%s)]], -j, p-j, i))) ()
  end
  p =2*p
end

print'+'


if rawget(_G, "querytab") then
  -- testing clearing of dead elements from tables
  collectgarbage("stop")   -- stop GC
  a = {[{}] = 4, [3] = 0, alo = 1, 
             a1234567890123456789012345678901234567890 = 10}

  t = querytab(a)

  for k,_ in pairs(a) do a[k] = nil end
  collectgarbage()   -- restore GC and collect dead fields in `a'
  for i=0,t-1 do
    k = querytab(a, i)
    assert(k == nil or type(k) == 'number' or k == 'alo')
  end
end

return('OK')
