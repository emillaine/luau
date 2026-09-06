result = require("./nested_inits")
result[result.count+1] = "required into module"
return result
