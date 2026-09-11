# single-line `if` without `end`
x = 0
if true then x = 1
assert(x == 1)

if false then x = 2
assert(x == 1)

if false then x = 2 else x = 3
assert(x == 3)

if true then x = 4 else x = 5
assert(x == 4)

# else-if chain on one line
y = 0
if false then y = 1 else if true then y = 2 else y = 3
assert(y == 2)

if false then y = 1 else if false then y = 2 else y = 3
assert(y == 3)

# rest of line is the body
a = 0
b = 0
if true then a = 1; b = 2
assert(a == 1 and b == 2)

# trailing `end` is still accepted
if true then a = 10 end
assert(a == 10)

if false then a = 11 else a = 12 end
assert(a == 12)

# nested single-line ifs; dangling else binds to innermost
z = 0
if true then if true then z = 1
assert(z == 1)

z = 0
if true then if false then z = 1 else z = 2
assert(z == 2)

# single-line conditionals inside functions and loops
function sign(n) if n > 0 then return 1 else if n < 0 then return -1 else return 0 end end
assert(sign(10) == 1)
assert(sign(-10) == -1)
assert(sign(0) == 0)

sum = 0
for i = 1, 5 do
    if i % 2 == 0 then sum += i
end
assert(sum == 6)

# mixed: single-line `then`, block `else`
w = 0
if false then w = 1
else
    w = 7
end
assert(w == 7)

# multi-line bodies still require `end` and keep working
q = 0
if true
    q = 42
end
assert(q == 42)

return 'OK'
