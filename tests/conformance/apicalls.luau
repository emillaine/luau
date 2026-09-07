# This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
print('testing function calls through API')

_G.add = function(a, b)
  return a + b
end

m = { __eq = function(a, b) return a.a == b.a end }

_G.create_with_tm = function(x)
  return setmetatable({ a = x }, m)
end

gen = 0
_G.incuv = function()
  gen += 1
  return gen
end

_G.pi = 3.1415926
_G.getpi = function()
  return pi
end

_G.largealloc = function()
  table.create(1000000)
end

_G.oops = function()
  return "oops"
end

_G.getnresults = function(n)
  return table.unpack(table.create(n, 1))
end

return('OK')
