-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
print('testing lua_exception')

-- Verify that no exception is generated
_G.empty_function = function()
end

_G.pass_number_to_error = function()
    -- Verify the error value of 42 is part of the exception's string.
    error(42)
end

_G.pass_string_to_error = function()
    -- Verify the error value of "string argument" is part of the exception's string.
    error("string argument")
end

_G.pass_table_to_error = function()
    -- Pass a table to `error`. A table is used since it is won't be
    -- convertable to a string using `lua_tostring`.
    error({field="value"})
end

_G.infinite_recursion_error = function()
    -- Generate a stack overflow error
    infinite_recursion_error()
end

_G.large_allocation_error = function()
    -- Create a table that will require more memory than the test's memory
    -- allocator will allow.
    table.create(1000000)
end

return('OK')
