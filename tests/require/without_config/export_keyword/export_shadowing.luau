-- exported bindings follow shadowing rules: bare assigns reuse the in-scope
-- binding (updating the export); only `const`/nested scopes shadow it
function foo()
    return "local"
end

export function foo()
    return "exported"
end

fruit = "apple"
export fruit

export animal = "dog"
animal = "cat"
animal = "bird"
