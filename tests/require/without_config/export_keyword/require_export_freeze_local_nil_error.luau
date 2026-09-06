m = require("./export_freeze_local_nil_error")

assert(m.value == 42, "local table=null should not affect export finalization")

return true
