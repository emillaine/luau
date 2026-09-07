a = require("./cyclic_a") # short-circuits; returns cyclic_a's export table
export value = "b_value"
export aRef = a # store reference without accessing a's fields (they aren't set yet)
# Safe to read a.value here because a is fully loaded by call time.
export function getA()
    return a.value
end
