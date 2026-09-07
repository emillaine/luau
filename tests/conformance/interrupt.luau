# This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
print("testing interrupts")

# this function will be called by C code with a special interrupt handler that validates hit locations
_G.test = function()
	function foo()
		for i=1,10 do end
		return
	end

	foo()

	function bar()
		i = 0
		while i < 10 do
			i += i + 1
		end
	end

	bar()

	function baz()
	end

	baz()
end

# these functions will be called by C code with a special interrupt handler that terminates after a few invocations
_G.infloop1 = function()
	while true do end
end

_G.infloop2 = function()
	while true do continue end
end

_G.infloop3 = function()
	repeat until false
end

_G.infloop4 = function()
	repeat continue until false
end

_G.infloop5 = function()
	for i=0,0,0 do end
end

_G.infloop6 = function()
	for i=0,0,0 do continue end
end

_G.infloop7 = function()
	for i=1,math.huge do end
end

_G.infloop8 = function()
	for i=1,math.huge do continue end
end

_G.infloop9 = function()
	# technically not a loop, but an exponentially recursive function
	function boom()
		boom()
		boom()
	end
	boom()
end

_G.infloop10 = function()
	for l0=4096,0,0 do
		repeat
			continue
		until function<t0>() end
	end
end

haystack = string.rep("x", 100)
pattern = string.rep("x?", 100) .. string.rep("x", 100)

_G.hang1 = function()
	string.find(haystack, pattern)
end

_G.hang2 = function()
	string.match(haystack, pattern)
end

_G.hang3 = function()
	string.gsub(haystack, pattern, "%0")
end

_G.hang4 = function()
	for k, v in string.gmatch(haystack, pattern) do
	end
end

_G.hang5 = function()
	x = string.rep('x', 1000)
	string.match(x, string.rep('x.*', 100) .. 'y')
end

_G.hang6 = function()
	# the reason an interrupt in RETURN is needed, CALL alone is not enough
	obj = setmetatable({}, {
		__index = function(obj, n)
			return if n < 2 then 1 else obj[n - 1] + obj[n - 2]
		end
	})

	print(obj[100])
end

_G.hang7 = function()
	# technically not a loop, but an exponentially recursive function
	function l0()
		pcall(l0)
		pcall(l0)
	end

	l0()
end

_G.hangpcall = function()
	for i = 1,100 do
		status, msg = pcall(string.find, haystack, pattern)
		assert(status == false)
		assert(msg == "timeout")
	end
end

return "OK"
