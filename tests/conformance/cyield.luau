# This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
print('testing yields from C functions')

function ecall(fn, ...)
    ok, err = pcall(fn, ...)
    print(ok, err)
    assert(not ok)
    return err:sub(err:find(": ") + 2, err.count)
end

function resume(co, ...)
    ok, result = coroutine.resume(co)
    print(ok, result)
    assert(ok)
    return result
end

function eresume(co, ...)
    ok, err = coroutine.resume(co)
    print(ok, err)
    assert(not ok)
    return err:sub(err:find(": ") + 2, err.count)
end

# Regular yield from a C function
do
    co = coroutine.wrap(singleYield)
    assert(co() == 2)
    assert(co() == 4)
end

# Multiple yields from a C function
do
    co = coroutine.wrap(multipleYields)
    assert(co(10) == 11)
    assert(co() == 12)
    assert(co() == 13)
    assert(co() == 14)
end

# Multiple yields from a C function (unused extra arguments)
do
    co = coroutine.wrap(multipleYields)
    assert(co(10, -1) == 11)
    assert(co(-1, -2) == 12)
    assert(co(-1, -2) == 13)
    assert(co(-1, -2) == 14)
end

# Multiple yields from nested yieldable C functions
do
    co = coroutine.wrap(multipleYieldsWithNestedCall)
    assert(co(10, true) == 105)
    assert(co() == 115)
    assert(co() == 210)
    assert(co() == 220)
end

# Multiple yields from nested yieldable C functions (unused extra arguments)
do
    co = coroutine.wrap(multipleYieldsWithNestedCall)
    assert(co(10, true, -1) == 105)
    assert(co(-1, -2) == 115)
    assert(co(-1, -2) == 210)
    assert(co(-1, -2) == 220)
end

do
    co = coroutine.wrap(multipleYieldsWithNestedCall)
    assert(co(10, false) == 110)
    assert(co() == 210)
    assert(co() == 220)
end

function nonyieldable(x, y)
    return x / y
end

function yieldable(x, y)
    a, b = coroutine.yield(x + y)

    for i = 1,10 do
        a, b = coroutine.yield(a * b)
    end

    coroutine.yield(a - b)
    return x / y
end

# yieldable Luau function that acts as a pass-through
do
    co = coroutine.create(function(x, y)
        return yieldable(x, y)
    end)

    s, x = coroutine.resume(co, 1, 2)
    assert(s)
    assert(x == 3)

    for i = 1, 10 do
        s, x = coroutine.resume(co, 4, 8)
        assert(s)
        assert(x == 32)
    end

    s, x = coroutine.resume(co, 10, 5)
    assert(s)
    assert(x == 5)
    s, x = coroutine.resume(co)
    assert(s)
    assert(x == 0.5)
end

# yieldable C function that acts as a pass-through (regular)
function passthroughcheck(f)
    x = f(nonyieldable, 1, 2)
    assert(x == 0.5)
end

passthroughcheck(passthroughCall)
passthroughcheck(passthroughCallMoreResults)
passthroughcheck(passthroughCallArgReuse)
passthroughcheck(passthroughCallVaradic)
passthroughcheck(passthroughCallWithState)

# yieldable C function that acts as a pass-through (yield)
function passthroughcheckyield(f)
    co = coroutine.create(function(x, y)
        return f(yieldable, x, y)
    end)

    s, x = coroutine.resume(co, 1, 2)
    assert(s)
    assert(x == 3)

    for i = 1, 10 do
        s, x = coroutine.resume(co, 4, 8)
        assert(s)
        assert(x == 32)
    end

    s, x = coroutine.resume(co, 10, 5)
    assert(s)
    assert(x == 5)
    s, x = coroutine.resume(co)
    assert(s)
    assert(x == 0.5)
end

passthroughcheckyield(passthroughCall)
passthroughcheckyield(passthroughCallMoreResults)
passthroughcheckyield(passthroughCallArgReuse)
passthroughcheckyield(passthroughCallVaradic)
passthroughcheckyield(passthroughCallWithState)

# yieldable C function that acts as a pass-through (regular, pcall to Luau)
function nonyieldablepcall(x, y)
    status, result = pcall(nonyieldable, x, y)
    assert(status)
    return result
end

function passthroughcheckpcall(f)
    x = f(nonyieldablepcall, 1, 2)
    assert(x == 0.5)
end

passthroughcheckpcall(passthroughCall)
passthroughcheckpcall(passthroughCallMoreResults)
passthroughcheckpcall(passthroughCallArgReuse)
passthroughcheckpcall(passthroughCallVaradic)
passthroughcheckpcall(passthroughCallWithState)

# yieldable C function that acts as a pass-through (regular, pcall to C)
function nonyieldablepcallc(x, y)
    status, result = pcall(assert, x / y)
    assert(status)
    return result
end

function passthroughcheckpcallc(f)
    x = f(nonyieldablepcallc, 1, 2)
    assert(x == 0.5)
end

passthroughcheckpcallc(passthroughCall)
passthroughcheckpcallc(passthroughCallMoreResults)
passthroughcheckpcallc(passthroughCallArgReuse)
passthroughcheckpcallc(passthroughCallVaradic)
passthroughcheckpcallc(passthroughCallWithState)

# yieldable C function that acts as a pass-through (regular, direct pcall)
function passthroughcheckpcallcdirect(f)
    status, x = f(pcall, function(y) return 1 / y end, 2)
    assert(status)
    assert(x == 0.5)
end

# only variadic functions are tested here because pcall returns status as well
passthroughcheckpcallcdirect(passthroughCallVaradic)
passthroughcheckpcallcdirect(passthroughCallWithState)

# test that error throws correctly restore C call counter
if not limitedstack then
	function errf()
		error("boom")
	end

	for i = 1, 100 do
		ok, err = pcall(function() passthroughCallVaradic(errf) end)
		assert(not ok)
		assert(string.find(err, "boom"), `iter {i}: expected boom, got {err}`)
	end

	count = 0
	function foo()
		count += 1
		pcall(1)
		coroutine.wrap(foo)()
	end
	ok2 = pcall(foo)
	assert(not ok2)
	assert(count == 200, `expected count == 200 (MAXCCALLS), got {count}`)
end

function ok_simple()
    return 100
end

function err_simple()
    error("error_sync")
end

function yield_then_ok()
    coroutine.yield(15)
    return 5
end

function yield_then_err()
    coroutine.yield(25)
    error("error_async")
end

assert(pcallThenCall(ok_simple, ok_simple) == 100 * 100)
assert(ecall(pcallThenCall, ok_simple, err_simple) == "error_sync")

assert(pcallThenCall(err_simple, ok_simple) == -100)
assert(ecall(pcallThenCall, err_simple, err_simple) == "error_sync")

do
    co = coroutine.create(function() return pcallThenCall(ok_simple, yield_then_ok) end)
    
    assert(resume(co) == 15)
    assert(resume(co) == 100 * 5)
end

do
    co = coroutine.create(function() return pcallThenCall(ok_simple, yield_then_err) end)
    
    assert(resume(co) == 25)
    assert(eresume(co) == "error_async")
end

do
    co = coroutine.create(function() return pcallThenCall(yield_then_ok, ok_simple) end)

    assert(resume(co) == 15)
    assert(resume(co) == 5 * 100)
end

do
    co = coroutine.create(function() return pcallThenCall(yield_then_ok, err_simple) end)
    
    assert(resume(co) == 15)
    assert(eresume(co) == "error_sync")
end

do
    co = coroutine.create(function() return pcallThenCall(yield_then_ok, yield_then_ok) end)
    
    assert(resume(co) == 15)
    assert(resume(co) == 15)
    assert(resume(co) == 5 * 5)
end

do
    co = coroutine.create(function() return pcallThenCall(yield_then_ok, yield_then_err) end)

    assert(resume(co) == 15)
    assert(resume(co) == 25)
    assert(eresume(co) == "error_async")
end

do
    co = coroutine.create(function() return pcallThenCall(yield_then_err, yield_then_ok) end)

    assert(resume(co) == 25)
    assert(resume(co) == 15)
    assert(resume(co) == -1 * 5)
end

do
    co = coroutine.create(function() return pcallThenCall(err_simple, yield_then_ok) end)

    assert(resume(co) == 15)
    assert(resume(co) == -1 * 5)
end

# extra tests where second call in continuation is also protected
do
    co = coroutine.create(function() return pcallThenPcall(yield_then_ok, ok_simple) end)

    assert(resume(co) == 15)
    assert(resume(co) == 5 * 100)
end

assert(pcallThenPcall(ok_simple, err_simple) == 100 * -1)

return "OK"
