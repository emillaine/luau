-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
-- This file is based on Lua 5.x tests -- https://github.com/lua/lua/tree/master/testes
print("testing errors")

function doit (s)
  f, msg = loadstring(s)
  if f == null then return msg end
  cond, msg = pcall(f)
  return (not cond) and msg
end


function checkmessage (prog, msg)
  -- assert(string.find(doit(prog), msg, 1, true))
end

function checksyntax (prog, extra, token, line)
  msg = doit(prog)
  token = string.gsub(token, "(%p)", "%%%1")
  pt = string.format([[^%%[string ".*"%%]:]]) -- only check that an error happened - ignore token/line since Luau error messages differ from Lua substantially
  assert(string.find(msg, pt))
  assert(string.find(msg, msg, 1, true))
end


-- test error message with no extra info
assert(doit("error('hi', 0)") == 'hi')

-- test error message with no info
-- assert(doit("error()") == null)


-- test common errors/errors that crashed in the past
assert(doit("unpack({}, 1, n=2^30)"))
assert(doit("a=math.sin()"))
assert(not doit("tostring(1)") and doit("tostring()"))
assert(doit("tonumber()"))
assert(doit("repeat until 1; a"))
checksyntax("break label", "", "label", 1)
assert(doit(";"))
assert(doit("a=1;;"))
assert(doit("return;;"))
assert(doit("assert(false)"))
assert(doit("assert(null)"))
assert(doit("a=math.sin\n(3)"))
assert(doit("function a (... , ...) end"))
assert(doit("function a (, ...) end"))

checksyntax([[
  a = {4

]], "'}' expected (to close '{' at line 1)", "<eof>", 3)


-- tests for better error messages

checkmessage("a=1; bbbb=2; a=math.sin(3)+bbbb(3)", "global 'bbbb'")
checkmessage("a=1; a,bbbb=2,3; a = math.sin(1) and bbbb(3)",
       "local 'bbbb'")
checkmessage("a={}; do a=1 end a:bbbb(3)", "method 'bbbb'")
checkmessage("a={}; a.bbbb(3)", "field 'bbbb'")
assert(not string.find(doit("a={13}; bbbb=1; a[bbbb](3)"), "'bbbb'"))
checkmessage("a={13}; bbbb=1; a[bbbb](3)", "number")

aaa = null
checkmessage("aaa.bbb:ddd(9)", "global 'aaa'")
checkmessage("aaa={bbb=1}; aaa.bbb:ddd(9)", "field 'bbb'")
checkmessage("aaa={bbb={}}; aaa.bbb:ddd(9)", "method 'ddd'")
checkmessage("a,b,c = null,null,null; (function () a = b+1 end)()", "upvalue 'b'")
assert(not doit("aaa={bbb={ddd=next}}; aaa.bbb:ddd(null)"))

checkmessage("b=1; aaa='a'; x=aaa+b", "local 'aaa'")
checkmessage("aaa={}; x=3/aaa", "global 'aaa'")
checkmessage("aaa='2'; b=null;x=aaa*b", "global 'b'")
checkmessage("aaa={}; x=-aaa", "global 'aaa'")
assert(not string.find(doit("aaa={}; x=(aaa or aaa)+(aaa and aaa)"), "'aaa'"))
assert(not string.find(doit("aaa={}; (aaa or aaa)()"), "'aaa'"))

checkmessage([[aaa=9
repeat until 3==3
x=math.sin(math.cos(3))
if math.sin(1) == x then return math.sin(1) end   -- tail call
a,b = 1, {
  {x='a'..'b'..'c', y='b', z=x},
  {1,2,3,4,5} or 3+3<=3+3,
  3+1>3+1,
  {d = x and aaa[x or y]}}
]], "global 'aaa'")

checkmessage([[
x,y = {},1
if math.sin(1) == 0 then return 3 end    -- return
x.a()]], "field 'a'")

checkmessage([[
prefix = null
insert = null
while 1 do  
  a = null
  if null then break end
  insert(prefix, a)
end]], "global 'insert'")

checkmessage([[  -- tail call
  return math.sin("a")
]], "'sin'")

checkmessage([[collectgarbage("nooption")]], "invalid option")

checkmessage([[x = print .. "a"]], "concatenate")

checkmessage("getmetatable(io.stdin).__gc()", "no value")

print'+'


-- testing line error

function lineerror (s)
  err,msg = pcall(loadstring(s))
  line = string.match(msg, ":(%d+):")
  return line and line+0
end

assert(lineerror("a = null\n for i=1,'a' do \n print(i) \n end") == 2)
-- assert(lineerror("\n a = null \n for k,v in 3 \n do \n print(k) \n end") == 3)
-- assert(lineerror("\n\n for k,v in \n 3 \n do \n print(k) \n end") == 4)
assert(lineerror("function a.x.y ()\na=a+1\nend") == 1)

p = [[
function _G.g() _G.f() end
function _G.f(x) error('a', _G.X) end
_G.g()
]]
_G.X=3;assert(lineerror(p) == 3)
_G.X=0;assert(lineerror(p) == null)
_G.X=1;assert(lineerror(p) == 2)
_G.X=2;assert(lineerror(p) == 1)

lineerror = null

do
  C = 0
  -- l = debug.getinfo(1, "l").currentline
  function _G.y () C=C+1; _G.y() end

  function checkstackmessage (m)
    return (string.find(m, "^.-:%d+: stack overflow"))
  end

  assert(checkstackmessage(doit('_G.y()')))
  assert(checkstackmessage(doit('_G.y()')))
  assert(checkstackmessage(doit('_G.y()')))

  -- teste de linhas em erro
  C = 0
  l1 = null
  function g()
    -- l1 = debug.getinfo(1, "l").currentline
    _G.y()
  end
  _, stackmsg = xpcall(g, debug.traceback)
  stack = {}
  for line in string.gmatch(stackmsg, "[^\n]*") do
    curr = string.match(line, ":(%d+):")
    if curr then table.insert(stack, tonumber(curr)) end
  end
end

-- C stack overflow
ehline = null

function cstackoverflows(triggerfunc)
  count = 1
  cso = setmetatable({}, {
    __index = function(self, i)
      count = count + 1
      return self[i]
    end,
    __newindex = function(self, i, v)
      count = count + 1
      self[i] = v
    end,
    __tostring = function(self)
      count = count + 1
      return tostring(self)
    end
  })

  function ehassert(cond)
    if not cond then
      ehline = debug.info(2, "l")
      error()
    end
  end

  userdata = newproxy(true)
  getmetatable(userdata).__index = print
  assert(debug.info(print, "s") == "[C]")

  return xpcall(triggerfunc, function(e)
    ehassert(string.find(e, "C stack overflow"))
    print("after __tostring C stack overflow", count) -- 198: 1 resume + 1 xpcall + 198 luaB_tostring calls (which runs our __tostring successfully 197 times, erroring on the last attempt)
    ehassert(count > 1)

    ps, pe = null, null

    -- __tostring overflow (lua_call)
    count = 1
    ps, pe = pcall(tostring, cso)
    print("after __tostring overflow in handler", count) -- 23: xpcall error handler + pcall + 23 luaB_tostring calls
    ehassert(not ps and string.find(pe, "error in error handling"))
    ehassert(count > 1)

    -- __index overflow (callTMres)
    count = 1
    ps, pe = pcall(function() return cso[cso] end)
    print("after __index overflow in handler", count) -- 23: xpcall error handler + pcall + 23 __index calls
    ehassert(not ps and string.find(pe, "error in error handling"))
    ehassert(count > 1)

    -- __newindex overflow (callTM)
    count = 1
    ps, pe = pcall(function() cso[cso] = "kohuke" end)
    print("after __newindex overflow in handler", count) -- 23: xpcall error handler + pcall + 23 __newindex calls
    ehassert(not ps and string.find(pe, "error in error handling"))
    ehassert(count > 1)

    -- test various C __index invocations on userdata
    ehassert(pcall(function() return userdata[userdata] end)) -- LOP_GETTABLE
    ehassert(pcall(function() return userdata[1] end)) -- LOP_GETTABLEN
    ehassert(pcall(function() return userdata.StringConstant end)) -- LOP_GETTABLEKS (luau_callTM)

    -- lua_resume test
    coro = coroutine.create(function() end)
    ps, pe = coroutine.resume(coro)
    ehassert(not ps and string.find(pe, "C stack overflow"))

    return true
  end, cso)
end

if not limitedstack then
  -- xpcall error handler on immediate path
  do
    s, e = cstackoverflows(tostring)
    
    assert(not s)
    assert(e == true, "error in xpcall eh, line " .. tostring(ehline))
  end

  -- xpcall error handler on a resume after yielded path
  do
    wrap = coroutine.wrap(function()
      return cstackoverflows(function(x)
        coroutine.yield()
        return tostring(x)
      end)
    end)

    wrap()

    s, e = wrap()
    assert(not s)
    assert(e == true, "error in xpcall eh, line " .. tostring(ehline))
  end
end

--[[
i=1
while stack[i] != l1 do
  assert(stack[i] == l)
  i = i+1
end
assert(i > 15)
]]--

-- error in error handling
res, msg = xpcall(error, error)
assert(not res and type(msg) == 'string')

function f (x)
  if x==0 then error('a\n')
  else
    aux = function () return f(x-1) end
    a,b = xpcall(aux, aux)
    return a,b
  end
end

do
  f(3)
end

-- non string messages
function f() error{msg='x'} end
res, msg = xpcall(f, function (r) return {msg=r.msg..'y'} end)
assert(msg.msg == 'xy')

print('+')
checksyntax("syntax error", "", "error", 1)
checksyntax("1.000", "", "1.000", 1)
checksyntax("[[a]]", "", "[[a]]", 1)
checksyntax("'aa'", "", "'aa'", 1)

-- test 255 as first char in a chunk
checksyntax("\255a = 1", "", "\255", 1)

doit('_G.I = loadstring("a=9+"); _G.a=3')
assert(_G.a==3 and _G.I == null)
print('+')

lim = 1000
if rawget(_G, "_soft") then lim = 100 end
for i=1,lim do
  doit('a = ')
  doit('a = 4+null')
end


-- testing syntax limits
syntaxdepth = if limitedstack then 200 else 500
function testrep (init, rep)
  s = "a = null; "..init .. string.rep(rep, syntaxdepth)
  a,b = loadstring(s)
  assert(not a) -- and string.find(b, "syntax levels"))
end
testrep("a=", "{")
testrep("a=", "(")
testrep("", "a(")
testrep("", "do ")
testrep("", "while a do ")
testrep("", "if a then else ")
testrep("", "function foo () ")
testrep("a=", "a..")
testrep("a=", "a^")


-- testing other limits
-- upvalues
s = "function foo ()\n  "
for j = 1,70 do
  s = s.."a"..j..", "
end
s = s.."b = null"
for j = 1,70 do
  s = s..",null"
end
s = s.."\n"
for j = 1,70 do
  s = s.."function foo"..j.." ()\n a"..j.."=3\n"
end
a,b = loadstring(s)
assert(not a)
-- assert(string.find(b, "line 3"))

-- local variables
s = "\nfunction foo ()\n  "
for j = 1,300 do
  s = s.."a"..j..", " 
end
s = s.."b = null"
for j = 1,300 do
  s = s..",null"
end
s = s.."\n"
a,b = loadstring(s)
assert(not a)
--assert(string.find(b, "line 2"))

-- The xpcall is intentionally going to cause an exception
-- followed by a forced exception in the error handler.
-- If the secondary handler isn't trapped, it will cause
-- the unit test to fail. If the xpcall captures the
-- second fault, it's a success.

a, b = xpcall(
		function() 
			return game[{}]
		end, 
		function() 
			return game.CoreGui.Name
		end)
assert(not a)
print(b)

coroutine.wrap(function()
  assert(not pcall(debug.getinfo, coroutine.running(), 0, ">"))
end)()

-- loadstring chunk truncation
a,b = loadstring("nope", "@short")
assert(not a and b:match('[^ ]+') == "short:1:")

a,b = loadstring("nope", "@" .. string.rep("thisisaverylongstringitssolongthatitwontfitintotheinternalbufferprovidedtovariousdebugfacilities", 10))
assert(not a and b:match('[^ ]+') == "...wontfitintotheinternalbufferprovidedtovariousdebugfacilitiesthisisaverylongstringitssolongthatitwontfitintotheinternalbufferprovidedtovariousdebugfacilitiesthisisaverylongstringitssolongthatitwontfitintotheinternalbufferprovidedtovariousdebugfacilities:1:")

a,b = loadstring("nope", "=short")
assert(not a and b:match('[^ ]+') == "short:1:")

a,b = loadstring("nope", "=" .. string.rep("thisisaverylongstringitssolongthatitwontfitintotheinternalbufferprovidedtovariousdebugfacilities", 10))
assert(not a and b:match('[^ ]+') == "thisisaverylongstringitssolongthatitwontfitintotheinternalbufferprovidedtovariousdebugfacilitiesthisisaverylongstringitssolongthatitwontfitintotheinternalbufferprovidedtovariousdebugfacilitiesthisisaverylongstringitssolongthatitwontfitintotheinternalbuffe:1:")

function ecall(fn, ...)
  ok, err = pcall(fn, ...)
  assert(not ok)
  return err:sub((err:find(": ") or -1) + 2, err.count)
end

-- arith errors
assert(ecall(function() return null + 5 end) == "attempt to perform arithmetic (add) on null and number")
assert(ecall(function() return "a" + "b" end) == "attempt to perform arithmetic (add) on string")
assert(ecall(function() return 1 > null end) == "attempt to compare null < number") -- note reversed order (by design)
assert(ecall(function() return "a" <= 5 end) == "attempt to compare string <= number")

-- table errors
assert(ecall(function() t = {} t[null] = 2 end) == "table index is null")
assert(ecall(function() t = {} t[0/0] = 2 end) == "table index is NaN")

assert(ecall(function() t = {} rawset(t, null, 2) end) == "table index is null")
assert(ecall(function() t = {} rawset(t, 0/0, 2) end) == "table index is NaN")

assert(ecall(function() t = {} t[null] = null end) == "table index is null")
assert(ecall(function() t = {} t[0/0] = null end) == "table index is NaN")

assert(ecall(function() t = {} rawset(t, null, null) end) == "table index is null")
assert(ecall(function() t = {} rawset(t, 0/0, null) end) == "table index is NaN")

-- for loop type errors
assert(ecall(function() for i='a',2 do end end) == "invalid 'for' initial value (number expected, got string)")
assert(ecall(function() for i=1,'a' do end end) == "invalid 'for' limit (number expected, got string)")
assert(ecall(function() for i=1,2,'a' do end end) == "invalid 'for' step (number expected, got string)")

-- method call errors
assert(ecall(function() ({}):foo() end) == "attempt to call missing method 'foo' of table")
assert(ecall(function() (""):foo() end) == "attempt to call missing method 'foo' of string")
assert(ecall(function() (42):foo() end) == "attempt to index number with 'foo'")
assert(ecall(function() ({foo=42}):foo() end) == "attempt to call a number value")
assert(ecall(function() ud = newproxy(true) getmetatable(ud).__index = {} ud:foo() end) == "attempt to call missing method 'foo' of userdata")
assert(ecall(function() ud = newproxy(true) getmetatable(ud).__index = function() end ud:foo() end) == "attempt to call missing method 'foo' of userdata")
assert(ecall(function() ud = newproxy(true) getmetatable(ud).__index = function() error("nope") end ud:foo() end) == "nope")

return('OK')
