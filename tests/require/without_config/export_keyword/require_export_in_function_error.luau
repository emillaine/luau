# verify export inside function body causes error
success, err = pcall(function()
    m = require("./export_in_function_error")
end)

assert(not success, "should fail when using export inside function")

return true
