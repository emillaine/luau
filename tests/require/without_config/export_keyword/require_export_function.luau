# verify exported functions can be required and called
m = require("./export_function")

assert(m.add(1, 2) == 3, "add function should work")
assert(m.add(10, 20) == 30, "add function should work with larger numbers")
assert(m.greet("World") == "Hello, World", "greet function should work")
assert(m.noop() == null, "noop function should return null")

return true
