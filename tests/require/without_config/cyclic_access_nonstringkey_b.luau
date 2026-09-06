A = require("./cyclic_access_nonstringkey_a")
key = {} -- table key; not convertible to string via lua_tostring
_ = A[key] -- A's placeholder is locked; triggers CyclicDependencyError with 'unknown' key
export dummy = true
