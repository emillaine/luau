-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
print("safeenv reset")

function envChangeInMetamethod()
	-- declare constant so that at O2 this test doesn't interfere with constant folding which we can't deoptimize
	ten = nil
	ten = 10

	a = setmetatable({}, {
		__index = function()
			getfenv().math = { abs = function(n) return n*n end }
			return 2
		end
	})

	b = a.x

	assert(math.abs(ten) == 100)
end

envChangeInMetamethod()

return"OK"
