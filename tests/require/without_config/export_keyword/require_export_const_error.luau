# verify reassigning exported value causes error
success, err = pcall(function()
    m = require("./export_const_error")
end)

assert(not success, "should fail when reassigning exported value")

return true
