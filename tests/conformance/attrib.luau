-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
-- This file is based on Lua 5.x tests -- https://github.com/lua/lua/tree/master/testes
print("testing assignments, logical operators, and constructors")

unpack = table.unpack

res, res2 = 27

a, b = 1, 2+3
assert(a==1 and b==5)
a={}
function f() return 10, 11, 12 end
a.x, b, a[1] = 1, 2, f()
assert(a.x==1 and b==2 and a[1]==10)
a[f()], b, a[f()+3] = f(), a, 'x'
assert(a[10] == 10 and b == a and a[13] == 'x')

do
  const f_inner = function (n) x = {}; for i=1,n do x[i]=i end;
                         return unpack(x) end;
  a_inner,b_inner,c_inner = null, null, null
  a_inner,b_inner = 0, f_inner(1)
  assert(a_inner == 0 and b_inner == 1)
  _G.A,b_inner = 0, f_inner(1)
  assert(_G.A == 0 and b_inner == 1)
  a_inner,b_inner,c_inner = 0,5,f_inner(4)
  assert(a_inner==0 and b_inner==5 and c_inner==1)
  a_inner,b_inner,c_inner = 0,5,f_inner(0)
  assert(a_inner==0 and b_inner==5 and c_inner==null)
end


a, b, c, d = 1 and null, 1 or null, (1 and (null or 1)), 6
assert(not a and b and c and d==6)

d = 20
a, b, c, d = f()
assert(a==10 and b==11 and c==12 and d==null)
a,b = f(), 1, 2, 3, f()
assert(a==10 and b==1)

assert(a<b == false and a>b == true)
assert((10 and 2) == 2)
assert((10 or 2) == 10)
assert((10 or assert(null)) == 10)
assert(not (null and assert(null)))
assert((null or "alo") == "alo")
assert((null and 10) == null)
assert((false and 10) == false)
assert((true or 10) == true)
assert((false or 10) == 10)
assert(false != null)
assert(null != false)
assert(not null == true)
assert(not not null == false)
assert(not not 1 == true)
assert(not not a == true)
assert(not not (6 or null) == true)
assert(not not (null and 56) == false)
assert(not not (null and true) == false)
print('+')

a = {}
a[true] = 20
a[false] = 10
assert(a[1<2] == 20 and a[1>2] == 10)

function f(a) return a end

a = {}
for i=3000,-3000,-1 do a[i] = i; end
a[10e30] = "alo"; a[true] = 10; a[false] = 20
assert(a[10e30] == 'alo' and a[not 1] == 20 and a[10<20] == 10)
for i=3000,-3000,-1 do assert(a[i] == i); end
a[print] = assert
a[f] = print
a[a] = a
assert(a[a][a][a][a][print] == assert)
a[print](a[a[f]] == a[print])
a = null

a = {10,9,8,7,6,5,4,3,2; [-3]='a', [f]=print, a='a', b='ab'}
a, a.x, a.y = a, a[-3]
assert(a[1]==10 and a[-3]==a.a and a[f]==print and a.x=='a' and not a.y)
a[1], f(a)[2], b, c = {['alo']=assert}, 10, a[1], a[f], 6, 10, 23, f(a), 2
a[1].alo(a[2]==10 and b==10 and c==print)

a[2^31] = 10; a[2^31+1] = 11; a[-2^31] = 12;
a[2^32] = 13; a[-2^32] = 14; a[2^32+1] = 15; a[10^33] = 16;

assert(a[2^31] == 10 and a[2^31+1] == 11 and a[-2^31] == 12 and
       a[2^32] == 13 and a[-2^32] == 14 and a[2^32+1] == 15 and
       a[10^33] == 16)

a = null


do
  a_inner2,i_inner,j_inner,b_inner2 = null, null, null, null
  a_inner2 = {'a', 'b'}; i_inner=1; j_inner=2; b_inner2=a_inner2
  i_inner, a_inner2[i_inner], a_inner2, j_inner, a_inner2[j_inner], a_inner2[i_inner+j_inner] = j_inner, i_inner, i_inner, b_inner2, j_inner, i_inner
  assert(i_inner == 2 and b_inner2[1] == 1 and a_inner2 == 1 and j_inner == b_inner2 and b_inner2[2] == 2 and
         b_inner2[3] == 1)
end

return('OK')
