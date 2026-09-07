# export inside function body should error
function test()
    export inside = "function"
end

test()
