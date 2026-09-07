# tests for if-local syntax

# basic truthy path
do
    if const x = 42 then
        assert(x == 42)
    else
        assert(false)
    end
end

# falsy path (null)
do
    entered = false
    if const x = null then
        entered = true
    end
    assert(not entered)
end

# falsy path (false)
do
    entered = false
    if const x = false then
        entered = true
    end
    assert(not entered)
end

# else branch taken when falsy
do
    result = "none"
    if const x = null then
        result = "then"
    else
        result = "else"
    end
    assert(result == "else")
end

# variable scoping: not visible after end
do
    x = "outer"
    if const x = "inner" then
        assert(x == "inner")
    end
    assert(x == "outer")
end

# variable scoping: not visible in else
do
    x = "outer"
    if const x = null then
        assert(false)
    else
        assert(x == "outer")
    end
end

# else if with independent bindings
do
    result = ""
    if const x = null then
        result = "first"
    else if const y = "hello" then
        assert(y == "hello")
        result = "second"
    else
        result = "else"
    end
    assert(result == "second")
end

# else if falls through correctly
do
    result = ""
    if const x = null then
        result = "first"
    else if const y = false then
        result = "second"
    else
        result = "else"
    end
    assert(result == "else")
end

# if const basic
do
    if const x = 100 then
        assert(x == 100)
    end
end

# truthy values: numbers, strings, tables
do
    if const x = 0 then
        assert(x == 0)
    else
        assert(false)
    end

    if const x = "" then
        assert(x == "")
    else
        assert(false)
    end

    t = {}
    if const x = t then
        assert(x == t)
    else
        assert(false)
    end
end

# function return value
do
    function maybeGet(flag)
        if flag then
            return "found"
        end
        return null
    end

    if const val = maybeGet(true) then
        assert(val == "found")
    end

    entered = false
    if const val = maybeGet(false) then
        entered = true
    end
    assert(not entered)
end

# nested if-local
do
    function getUser()
        return { email = "test@example.com" }
    end

    if const user = getUser() then
        if const email = user.email then
            assert(email == "test@example.com")
        end
    end
end

# shadowing outer variable
do
    x = 10
    if const x = 20 then
        assert(x == 20)
    end
    assert(x == 10)
end

# upvalue capture from then-block
do
    captured = null
    if const x = "hello" then
        captured = function() return x end
    end
    assert(captured() == "hello")
end

# pcall success: binds the success boolean (true), takes then-branch
do
    if const ok = pcall(function() end) then
        assert(ok == true)
    else
        assert(false)
    end
end

# pcall failure: binds the success boolean (false), takes else-branch
do
    result = "none"
    if const ok = pcall(function() error("boom") end) then
        result = "then"
    else
        result = "else"
    end
    assert(result == "else")
end

# xpcall success: binds the success boolean (true)
do
    if const ok = xpcall(function() return 5 end, function() return "handled" end) then
        assert(ok == true)
    else
        assert(false)
    end
end

# xpcall failure: handler runs, success boolean is false, takes else-branch
do
    handlerRan = false
    result = "none"
    if const ok = xpcall(function() error("boom") end, function() handlerRan = true return "handled" end) then
        result = "then"
    else
        result = "else"
    end
    assert(result == "else")
    assert(handlerRan)
end

# multiple return values: the condition is a single-value binding, so only the first is kept
do
    function multi()
        return 1, 2, 3
    end
    if const a = multi() then
        assert(a == 1)
    else
        assert(false)
    end
end

# multiple return values whose first value is falsy: else-branch taken
do
    function multiFalsy()
        return null, "err"
    end
    result = "none"
    if const a = multiFalsy() then
        result = "then"
    else
        result = "else"
    end
    assert(result == "else")
end

# multireturn truncation is observable: a trailing truthy value must not keep the then-branch alive
do
    function falseThenTrue()
        return false, true
    end
    entered = false
    if const a = falseThenTrue() then
        entered = true
    end
    assert(not entered)
end

return "OK"
