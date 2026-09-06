-- mutually recursive functions with exported forward declarations
export a, b

function a()
    return b() + 1
end

function b()
    return 42
end
