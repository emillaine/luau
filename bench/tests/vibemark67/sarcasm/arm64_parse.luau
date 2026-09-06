--!nonstrict
-- sarcasm assembly parser for ARM64 GNU-as / clang assembly.
--
-- Produces a flat list of "statements". Each statement is one of:
--   { kind = "blank",     text = <original> }
--   { kind = "label",     name = <string>, annotation = <string?> }
--   { kind = "directive", name = ".text", args = <string>, raw = <string>, annotation = <string?> }
--   { kind = "insn",      mnemonic = "ldr", operands = { <operand>... }, cond = <string?>,
--                         annotation = <string?>, raw = <string> }
--
-- Operands are structured:
--   { kind = "reg",  name = "x0", rc = "gpr"|"neon"|"sp"|"zr", width = 32|64|..., shift = <shift?> }
--   { kind = "imm",  text = "5381", value = <number?> }
--   { kind = "sym",  text = "foo+16", reloc = <string?> }   -- reloc e.g. "lo12","got","got_lo12"
--   { kind = "mem",  base = <reg>, index = <operand?>, writeback = "pre"|"post"|null,
--                    shift = <shift?>, text = <original> }
-- A shift is { op = "lsl"|"lsr"|"asr"|"ror"|"uxtb"|... , amount = <number?>, amountText = <string?> }

parse = {}

SHIFT_OPS = {
	lsl = true, lsr = true, asr = true, ror = true, msl = true,
	uxtb = true, uxth = true, uxtw = true, uxtx = true,
	sxtb = true, sxth = true, sxtw = true, sxtx = true,
}

-- Registers ---------------------------------------------------------------

-- Classify a bare register token. Returns a reg operand table, or null.
function classifyReg(tok: string)
	low = string.lower(tok)
	if low == "sp" then
		return { kind = "reg", name = "sp", rc = "sp", width = 64 }
	end
	if low == "wsp" then
		return { kind = "reg", name = "wsp", rc = "sp", width = 32 }
	end
	if low == "xzr" then
		return { kind = "reg", name = "xzr", rc = "zr", width = 64 }
	end
	if low == "wzr" then
		return { kind = "reg", name = "wzr", rc = "zr", width = 32 }
	end
	prefix, num = string.match(low, "^([a-z]+)(%d+)$")
	if prefix and num then
		n = tonumber(num)
		if prefix == "x" and n <= 30 then
			return { kind = "reg", name = low, rc = "gpr", width = 64, num = n }
		else if prefix == "w" and n <= 30 then
			return { kind = "reg", name = low, rc = "gpr", width = 32, num = n }
		else if (prefix == "v" or prefix == "q" or prefix == "d" or prefix == "s" or prefix == "h" or prefix == "b") and n <= 31 then
			return { kind = "reg", name = low, rc = "neon", width = 128, num = n }
		end
	end
	return null
end
parse.classifyReg = classifyReg

-- Given a gpr num and desired width, return the canonical name.
function parse.gprName(num: number, width: number): string
	if width == 32 then
		return "w" .. tostring(num)
	end
	return "x" .. tostring(num)
end

-- Operand tokenization ----------------------------------------------------

-- Split an operand string into top-level comma-separated fields, respecting
-- [] and () nesting.
function splitTopLevel(s: string): { string }
	out = {}
	depth = 0
	cur = {}
	i = 1
	n = #s
	while i <= n do
		c = string.sub(s, i, i)
		if c == "[" or c == "(" then
			depth += 1
			table.insert(cur, c)
		else if c == "]" or c == ")" then
			depth -= 1
			table.insert(cur, c)
		else if c == "," and depth == 0 then
			table.insert(out, table.concat(cur))
			cur = {}
		else
			table.insert(cur, c)
		end
		i += 1
	end
	table.insert(out, table.concat(cur))
	-- trim
	for idx, field in out do
		out[idx] = (string.gsub(field, "^%s*(.-)%s*$", "%1"))
	end
	return out
end
parse.splitTopLevel = splitTopLevel

-- Parse a shift/extend field like "lsl 5", "lsl #5", "uxtb", "sxtw".
function parseShift(field: string)
	op, rest = string.match(field, "^(%a+)%s*(.*)$")
	if not op or not SHIFT_OPS[string.lower(op)] then
		return null
	end
	op = string.lower(op)
	rest = (string.gsub(rest, "^%s*(.-)%s*$", "%1"))
	amount, amountText = null, null
	if rest != "" then
		amountText = rest
		numtxt = (string.gsub(rest, "^#", ""))
		amount = tonumber(numtxt)
	end
	return { op = op, amount = amount, amountText = amountText }
end

-- Parse a single (non-memory, non-shift) operand field.
function parseSimple(field: string)
	-- register?
	reg = classifyReg(field)
	if reg then
		return reg
	end
	-- immediate: #num, num, 0x..., -num
	imm = string.match(field, "^#(.+)$")
	if imm then
		return { kind = "imm", text = imm, value = tonumber(imm) }
	end
	if string.match(field, "^-?%d") or string.match(field, "^0[xX]") then
		return { kind = "imm", text = field, value = tonumber(field) }
	end
	-- reloc-decorated symbol: :lo12:sym, :got:sym, etc.
	reloc, sym = string.match(field, "^:(%w+):(.+)$")
	if reloc then
		return { kind = "sym", text = sym, reloc = reloc }
	end
	-- plain symbol / label / expression
	return { kind = "sym", text = field }
end

-- Parse a memory operand starting with '['.
function parseMem(field: string, postIndex: string?)
	writeback = null
	inner = field
	if string.sub(inner, -1) == "!" then
		writeback = "pre"
		inner = string.sub(inner, 1, -2)
	end
	-- strip [ ]
	inner = string.match(inner, "^%[(.*)%]$") or inner
	inner = (string.gsub(inner, "^%s*(.-)%s*$", "%1"))
	parts = splitTopLevel(inner)
	base = parseSimple(parts[1])
	mem = { kind = "mem", base = base, text = field, writeback = writeback }
	if #parts >= 2 then
		-- second part is index/offset; third (if any) is a shift/extend on the index
		idx = parts[2]
		sh = parseShift(idx)
		if sh then
			mem.shift = sh
		else
			mem.index = parseSimple(idx)
		end
		if #parts >= 3 then
			mem.shift = parseShift(parts[3])
		end
	end
	if postIndex then
		mem.writeback = "post"
		sh = parseShift(postIndex)
		if sh then
			mem.postShift = sh
		else
			mem.index = parseSimple(postIndex)
		end
	end
	return mem
end

-- Parse the full operand list of an instruction.
function parseOperands(s: string)
	s = (string.gsub(s, "^%s*(.-)%s*$", "%1"))
	if s == "" then
		return {}
	end
	fields = splitTopLevel(s)
	operands = {}
	i = 1
	while i <= #fields do
		field = fields[i]
		if field == "" then
			i += 1
		else if string.sub(field, 1, 1) == "[" then
			-- memory operand; check for post-index (a following field that is
			-- not a shift and this bracket has no '!').
			if string.sub(field, -1) != "!" and i + 1 <= #fields and not parseShift(fields[i + 1]) then
				table.insert(operands, parseMem(field, fields[i + 1]))
				i += 2
			else
				table.insert(operands, parseMem(field, null))
				i += 1
			end
		else
			sh = parseShift(field)
			if sh and #operands > 0 then
				-- attach to previous operand
				operands[#operands].shift = sh
			else
				table.insert(operands, parseSimple(field))
			end
			i += 1
		end
	end
	return operands
end
parse.parseOperands = parseOperands

-- Line splitting ----------------------------------------------------------

-- Remove a trailing // comment that is not inside a string literal.
function stripLineComment(s: string): string
	inStr = false
	i = 1
	n = #s
	while i <= n do
		c = string.sub(s, i, i)
		if c == '"' then
			inStr = not inStr
		else if not inStr and c == "/" and string.sub(s, i + 1, i + 1) == "/" then
			return string.sub(s, 1, i - 1)
		end
		i += 1
	end
	return s
end

-- Split off a ;! annotation (returns code, annotation-or-null).
function splitAnnotation(s: string): (string, string?)
	idx = string.find(s, ";!", 1, true)
	if idx then
		code = string.sub(s, 1, idx - 1)
		ann = string.sub(s, idx + 2)
		ann = (string.gsub(ann, "^%s*(.-)%s*$", "%1"))
		return code, ann
	end
	return s, null
end

function trim(s: string): string
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- Parse one source line into zero or more statements, appending to `out`.
function parseLine(rawLine: string, out)
	code, annotation = splitAnnotation(rawLine)
	code = stripLineComment(code)
	trimmed = trim(code)

	if trimmed == "" then
		if annotation then
			-- annotation on an otherwise-blank line: attach to a blank marker
			table.insert(out, { kind = "blank", text = rawLine, annotation = annotation })
		else
			table.insert(out, { kind = "blank", text = rawLine })
		end
		return
	end

	-- Peel labels off the front: NAME:
	while true do
		name, rest = string.match(trimmed, "^([%w_.$][%w_.$@]*):%s*(.*)$")
		if not name then
			break
		end
		table.insert(out, { kind = "label", name = name })
		trimmed = trim(rest)
		if trimmed == "" then
			break
		end
	end

	-- Attach annotation to the last produced statement for this line (if any),
	-- but if there's remaining code, it will be attached below instead.
	if trimmed == "" then
		if annotation and #out > 0 then
			out[#out].annotation = annotation
		end
		return
	end

	-- Directive or instruction.
	mnemonic, rest = string.match(trimmed, "^([%.%w_][%w_.]*)%s*(.*)$")
	if not mnemonic then
		table.insert(out, { kind = "directive", name = trimmed, args = "", raw = trimmed, annotation = annotation })
		return
	end
	rest = trim(rest)

	if string.sub(mnemonic, 1, 1) == "." then
		table.insert(out, {
			kind = "directive",
			name = mnemonic,
			args = rest,
			raw = trimmed,
			annotation = annotation,
		})
		return
	end

	-- Instruction. Split optional condition suffix off branch mnemonics like b.hs.
	operands = parseOperands(rest)
	table.insert(out, {
		kind = "insn",
		mnemonic = mnemonic,
		operands = operands,
		annotation = annotation,
		raw = trimmed,
	})
end

function parse.parseString(text: string)
	out = {}
	-- normalize CRLF
	text = (string.gsub(text, "\r\n", "\n"))
	lineNo = 0
	for line in (text .. "\n"):gmatch("(.-)\n") do
		lineNo += 1
		before = #out
		parseLine(line, out)
		-- stamp every statement produced from this source line with its line number
		for k = before + 1, #out do out[k].line = lineNo end
	end
	return out
end

return parse
