# This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details

_G.require = function(path)
    if path == "a" then
        return {
            make = function()
                return 1
            end,
            foo = 42,
        }
    else
        if path == "b" then
            return {
                bar = 7,
            }
        else
            if path == "c" then
                return {
                    print = function()
                        return "imported"
                    end,
                }
            else
                error("unknown module " .. tostring(path))
            end
        end
    end
end

import "a"
assert(make() == 1)
assert(foo == 42)

# imported names win over _G
_G.make = function()
    return 99
end
assert(make() == 1)

import "b"
assert(bar == 7)
assert(foo == 42)

# nested function still sees wildcard imports
function nested()
    return make() + bar
end
assert(nested() == 8)

# imported names win over builtins cached at load time
import "c"
assert(print() == "imported")

return "OK"
