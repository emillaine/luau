result = proxyrequire("./dependency", "@"..debug.info(1, "s"))
result[result.count+1] = "required into proxy_requirer"
return result
