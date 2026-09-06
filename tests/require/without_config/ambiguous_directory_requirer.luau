local result = require("./ambiguous/directory/dependency")
result[result.count+1] = "required into module"
return result
