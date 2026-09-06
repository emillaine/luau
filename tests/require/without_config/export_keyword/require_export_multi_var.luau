-- verify multi-variable export works
m = require("./export_multi_var")

assert(m.a == 10, "a should be exported")
assert(m.b == 20, "b should be exported")
assert(m.c == 30, "c should be exported")
assert(m.d == null, "uninitialized exported locals should default to null")

return true
