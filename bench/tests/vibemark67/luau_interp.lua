-- forward declarations (implicit-local dialect has no hoisted globals)
callClosure = null
callFunction = null
evalArgList = null
evalBinop = null
evalCall = null
evalExprMulti = null
evalMethodCall = null
evalTableConstructor = null
evalUnop = null
execAssign = null
execBlock = null
execFuncDef = null
execGenFor = null
execIf = null
execLocal = null
execLocalFunc = null
execNumFor = null
execRepeat = null
execReturn = null
execStat = null
execWhile = null
interpToString = null
lexCountLongBracket = null
lexSkipLongString = null
parseCallArgs = null
parseFuncBody = null
parseTableConstructor = null
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

function test()

-- Luau Interpreter in Luau (meta-circular) benchmark
-- A full Luau interpreter: lexer, parser, evaluator with metatables, standard library
-- Target runtimes: Luau (lute)

floor = math.floor
mabs = math.abs
msqrt = math.sqrt
msin = math.sin
mcos = math.cos
mlog = math.log
mexp = math.exp
mmax = math.max
mmin = math.min
mpi = math.pi
mhuge = math.huge
mceil = math.ceil
mrandom = math.random
sformat = string.format
ssub = string.sub
sbyte = string.byte
schar = string.char
srep = string.rep
slen = string.len
sfind = string.find
slower = string.lower
supper = string.upper
tinsert = table.insert
tremove = table.remove
tconcat = table.concat
tsort = table.sort
tmove = table.move or function(a, f, e, t, dest)
    dest = dest or a
    if t > f then
        for i = e, f, -1 do dest[t + (i - f)] = a[i] end
    else
        for i = f, e do dest[t + (i - f)] = a[i] end
    end
    return dest
end
unpack_ = table.unpack or unpack
clock = os.clock

-- ============================================================================
-- TOKEN TYPES
-- ============================================================================

TK_EOF = "EOF"
TK_NUMBER = "NUMBER"
TK_STRING = "STRING"
TK_NAME = "NAME"
TK_PLUS = "+"
TK_MINUS = "-"
TK_STAR = "*"
TK_SLASH = "/"
TK_DSLASH = "//"
TK_PERCENT = "%"
TK_CARET = "^"
TK_DOTDOT = ".."
TK_EQ = "=="
TK_NEQ = "~="
TK_LT = "<"
TK_GT = ">"
TK_LE = "<="
TK_GE = ">="
TK_ASSIGN = "="
TK_HASH = "#"
TK_DOT = "."
TK_COLON = ":"
TK_COMMA = ","
TK_SEMI = ";"
TK_LPAREN = "("
TK_RPAREN = ")"
TK_LBRACE = "{"
TK_RBRACE = "}"
TK_LBRACKET = "["
TK_RBRACKET = "]"
TK_DOTS = "..."

-- Keywords as token types
TK_LOCAL = "local"
TK_FUNCTION = "function"
TK_IF = "if"
TK_THEN = "then"
TK_ELSE = "else"
TK_ELSEIF = "elseif"
TK_END = "end"
TK_WHILE = "while"
TK_DO = "do"
TK_FOR = "for"
TK_IN = "in"
TK_RETURN = "return"
TK_NIL = "null"
TK_TRUE = "true"
TK_FALSE = "false"
TK_AND = "and"
TK_OR = "or"
TK_NOT = "not"
TK_REPEAT = "repeat"
TK_UNTIL = "until"
TK_BREAK = "break"
TK_CONTINUE = "continue"

-- Keyword lookup table
KEYWORDS = {}
KEYWORDS["local"] = TK_LOCAL
KEYWORDS["function"] = TK_FUNCTION
KEYWORDS["if"] = TK_IF
KEYWORDS["then"] = TK_THEN
KEYWORDS["else"] = TK_ELSE
KEYWORDS["elseif"] = TK_ELSEIF
KEYWORDS["end"] = TK_END
KEYWORDS["while"] = TK_WHILE
KEYWORDS["do"] = TK_DO
KEYWORDS["for"] = TK_FOR
KEYWORDS["in"] = TK_IN
KEYWORDS["return"] = TK_RETURN
KEYWORDS["null"] = TK_NIL
KEYWORDS["true"] = TK_TRUE
KEYWORDS["false"] = TK_FALSE
KEYWORDS["and"] = TK_AND
KEYWORDS["or"] = TK_OR
KEYWORDS["not"] = TK_NOT
KEYWORDS["repeat"] = TK_REPEAT
KEYWORDS["until"] = TK_UNTIL
KEYWORDS["break"] = TK_BREAK
KEYWORDS["continue"] = TK_CONTINUE

-- ============================================================================
-- LEXER
-- ============================================================================

function newLexer(source)
    lex = {}
    lex.source = source
    lex.pos = 1
    lex.len = slen(source)
    lex.line = 1
    lex.token = null
    lex.value = null
    return lex
end

function lexPeekChar(lex)
    if lex.pos > lex.len then return null end
    return ssub(lex.source, lex.pos, lex.pos)
end

function lexNextChar(lex)
    ch = ssub(lex.source, lex.pos, lex.pos)
    lex.pos = lex.pos + 1
    if ch == "\n" then lex.line = lex.line + 1 end
    return ch
end

function lexSkipWhitespace(lex)
    while lex.pos <= lex.len do
        ch = ssub(lex.source, lex.pos, lex.pos)
        if ch == " " or ch == "\t" or ch == "\r" or ch == "\n" then
            if ch == "\n" then lex.line = lex.line + 1 end
            lex.pos = lex.pos + 1
        else if ch == "-" and lex.pos + 1 <= lex.len and ssub(lex.source, lex.pos + 1, lex.pos + 1) == "-" then
            -- comment
            lex.pos = lex.pos + 2
            if lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) == "[" then
                lvl = lexCountLongBracket(lex)
                if lvl >= 0 then
                    lexSkipLongString(lex, lvl)
                else
                    -- line comment
                    while lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) != "\n" do
                        lex.pos = lex.pos + 1
                    end
                end
            else
                while lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) != "\n" do
                    lex.pos = lex.pos + 1
                end
            end
        else
            break
        end
    end
end

function lexCountLongBracket(lex)
    p = lex.pos
    if p > lex.len or ssub(lex.source, p, p) != "[" then return -1 end
    p = p + 1
    count = 0
    while p <= lex.len and ssub(lex.source, p, p) == "=" do
        count = count + 1
        p = p + 1
    end
    if p <= lex.len and ssub(lex.source, p, p) == "[" then
        return count
    end
    return -1
end

function lexSkipLongString(lex, level)
    -- skip opening [==..==[
    lex.pos = lex.pos + 1 + level + 1
    while lex.pos <= lex.len do
        ch = ssub(lex.source, lex.pos, lex.pos)
        if ch == "\n" then lex.line = lex.line + 1 end
        if ch == "]" then
            p2 = lex.pos + 1
            cnt = 0
            while p2 <= lex.len and ssub(lex.source, p2, p2) == "=" do
                cnt = cnt + 1
                p2 = p2 + 1
            end
            if cnt == level and p2 <= lex.len and ssub(lex.source, p2, p2) == "]" then
                lex.pos = p2 + 1
                return
            end
        end
        lex.pos = lex.pos + 1
    end
end

function lexReadLongString(lex, level)
    -- skip opening [==..==[
    lex.pos = lex.pos + 1 + level + 1
    -- skip immediate newline
    if lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) == "\n" then
        lex.line = lex.line + 1
        lex.pos = lex.pos + 1
    end
    parts = {}
    while lex.pos <= lex.len do
        ch = ssub(lex.source, lex.pos, lex.pos)
        if ch == "\n" then lex.line = lex.line + 1 end
        if ch == "]" then
            p2 = lex.pos + 1
            cnt = 0
            while p2 <= lex.len and ssub(lex.source, p2, p2) == "=" do
                cnt = cnt + 1
                p2 = p2 + 1
            end
            if cnt == level and p2 <= lex.len and ssub(lex.source, p2, p2) == "]" then
                lex.pos = p2 + 1
                return tconcat(parts)
            end
        end
        tinsert(parts, ch)
        lex.pos = lex.pos + 1
    end
    error("unfinished long string at line " .. lex.line)
end

function lexIsDigit(ch)
    b = sbyte(ch)
    return b >= 48 and b <= 57
end

function lexIsAlpha(ch)
    b = sbyte(ch)
    return (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b == 95
end

function lexIsAlnum(ch)
    b = sbyte(ch)
    return (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b == 95 or (b >= 48 and b <= 57)
end

function lexReadNumber(lex)
    start = lex.pos
    ch = ssub(lex.source, lex.pos, lex.pos)
    if ch == "0" and lex.pos + 1 <= lex.len then
        nxt = ssub(lex.source, lex.pos + 1, lex.pos + 1)
        if nxt == "x" or nxt == "X" then
            lex.pos = lex.pos + 2
            while lex.pos <= lex.len do
                c = ssub(lex.source, lex.pos, lex.pos)
                b = sbyte(c)
                if (b >= 48 and b <= 57) or (b >= 65 and b <= 70) or (b >= 97 and b <= 102) or c == "_" then
                    lex.pos = lex.pos + 1
                else
                    break
                end
            end
            raw = ssub(lex.source, start, lex.pos - 1)
            -- remove underscores
            clean = ""
            for i = 1, slen(raw) do
                c = ssub(raw, i, i)
                if c != "_" then clean = clean .. c end
            end
            return tonumber(clean)
        else if nxt == "b" or nxt == "B" then
            lex.pos = lex.pos + 2
            while lex.pos <= lex.len do
                c = ssub(lex.source, lex.pos, lex.pos)
                if c == "0" or c == "1" or c == "_" then
                    lex.pos = lex.pos + 1
                else
                    break
                end
            end
            raw = ssub(lex.source, start + 2, lex.pos - 1)
            clean = ""
            for i = 1, slen(raw) do
                c = ssub(raw, i, i)
                if c != "_" then clean = clean .. c end
            end
            val = 0
            for i = 1, slen(clean) do
                val = val * 2 + (sbyte(clean, i, i) - 48)
            end
            return val
        end
    end
    -- decimal
    while lex.pos <= lex.len do
        c = ssub(lex.source, lex.pos, lex.pos)
        if lexIsDigit(c) or c == "_" then
            lex.pos = lex.pos + 1
        else
            break
        end
    end
    if lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) == "." then
        lex.pos = lex.pos + 1
        while lex.pos <= lex.len do
            c = ssub(lex.source, lex.pos, lex.pos)
            if lexIsDigit(c) or c == "_" then
                lex.pos = lex.pos + 1
            else
                break
            end
        end
    end
    if lex.pos <= lex.len then
        c = ssub(lex.source, lex.pos, lex.pos)
        if c == "e" or c == "E" then
            lex.pos = lex.pos + 1
            if lex.pos <= lex.len then
                c2 = ssub(lex.source, lex.pos, lex.pos)
                if c2 == "+" or c2 == "-" then lex.pos = lex.pos + 1 end
            end
            while lex.pos <= lex.len and lexIsDigit(ssub(lex.source, lex.pos, lex.pos)) do
                lex.pos = lex.pos + 1
            end
        end
    end
    raw = ssub(lex.source, start, lex.pos - 1)
    clean = ""
    for i = 1, slen(raw) do
        c = ssub(raw, i, i)
        if c != "_" then clean = clean .. c end
    end
    return tonumber(clean)
end

function lexReadString(lex, quote)
    lex.pos = lex.pos + 1 -- skip opening quote
    parts = {}
    while lex.pos <= lex.len do
        ch = ssub(lex.source, lex.pos, lex.pos)
        if ch == quote then
            lex.pos = lex.pos + 1
            return tconcat(parts)
        else if ch == "\\" then
            lex.pos = lex.pos + 1
            esc = ssub(lex.source, lex.pos, lex.pos)
            lex.pos = lex.pos + 1
            if esc == "n" then tinsert(parts, "\n")
            else if esc == "t" then tinsert(parts, "\t")
            else if esc == "r" then tinsert(parts, "\r")
            else if esc == "\\" then tinsert(parts, "\\")
            else if esc == "\"" then tinsert(parts, "\"")
            else if esc == "'" then tinsert(parts, "'")
            else if esc == "0" then tinsert(parts, "\0")
            else if esc == "\n" then
                lex.line = lex.line + 1
                tinsert(parts, "\n")
            else if lexIsDigit(esc) then
                numstr = esc
                for _ = 1, 2 do
                    if lex.pos <= lex.len and lexIsDigit(ssub(lex.source, lex.pos, lex.pos)) then
                        numstr = numstr .. ssub(lex.source, lex.pos, lex.pos)
                        lex.pos = lex.pos + 1
                    end
                end
                tinsert(parts, schar(tonumber(numstr)))
            else
                tinsert(parts, esc)
            end
        else if ch == "\n" then
            error("unfinished string at line " .. lex.line)
        else
            tinsert(parts, ch)
            lex.pos = lex.pos + 1
        end
    end
    error("unfinished string at line " .. lex.line)
end

function lexNext(lex)
    lexSkipWhitespace(lex)
    if lex.pos > lex.len then
        lex.token = TK_EOF
        lex.value = null
        return
    end
    ch = ssub(lex.source, lex.pos, lex.pos)

    -- Numbers
    if lexIsDigit(ch) then
        lex.value = lexReadNumber(lex)
        lex.token = TK_NUMBER
        return
    end

    -- Identifiers and keywords
    if lexIsAlpha(ch) then
        start = lex.pos
        while lex.pos <= lex.len and lexIsAlnum(ssub(lex.source, lex.pos, lex.pos)) do
            lex.pos = lex.pos + 1
        end
        word = ssub(lex.source, start, lex.pos - 1)
        kw = KEYWORDS[word]
        if kw then
            lex.token = kw
            lex.value = word
        else
            lex.token = TK_NAME
            lex.value = word
        end
        return
    end

    -- Strings
    if ch == "\"" or ch == "'" then
        lex.value = lexReadString(lex, ch)
        lex.token = TK_STRING
        return
    end

    -- Long strings
    if ch == "[" then
        lvl = lexCountLongBracket(lex)
        if lvl >= 0 then
            lex.value = lexReadLongString(lex, lvl)
            lex.token = TK_STRING
            return
        end
    end

    -- Operators and punctuation
    lex.pos = lex.pos + 1
    if ch == "+" then lex.token = TK_PLUS; lex.value = null
    else if ch == "*" then lex.token = TK_STAR; lex.value = null
    else if ch == "%" then lex.token = TK_PERCENT; lex.value = null
    else if ch == "^" then lex.token = TK_CARET; lex.value = null
    else if ch == "#" then lex.token = TK_HASH; lex.value = null
    else if ch == "," then lex.token = TK_COMMA; lex.value = null
    else if ch == ";" then lex.token = TK_SEMI; lex.value = null
    else if ch == "(" then lex.token = TK_LPAREN; lex.value = null
    else if ch == ")" then lex.token = TK_RPAREN; lex.value = null
    else if ch == "{" then lex.token = TK_LBRACE; lex.value = null
    else if ch == "}" then lex.token = TK_RBRACE; lex.value = null
    else if ch == "]" then lex.token = TK_RBRACKET; lex.value = null
    else if ch == "[" then lex.token = TK_LBRACKET; lex.value = null
    else if ch == "-" then
        lex.token = TK_MINUS; lex.value = null
    else if ch == "/" then
        if lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) == "/" then
            lex.pos = lex.pos + 1
            lex.token = TK_DSLASH; lex.value = null
        else
            lex.token = TK_SLASH; lex.value = null
        end
    else if ch == "." then
        if lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) == "." then
            lex.pos = lex.pos + 1
            if lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) == "." then
                lex.pos = lex.pos + 1
                lex.token = TK_DOTS; lex.value = null
            else
                lex.token = TK_DOTDOT; lex.value = null
            end
        else if lex.pos <= lex.len and lexIsDigit(ssub(lex.source, lex.pos, lex.pos)) then
            -- number starting with dot like .5
            lex.pos = lex.pos - 1 -- back up to include the dot
            -- Actually read as number
            start = lex.pos
            lex.pos = lex.pos + 1 -- skip dot
            while lex.pos <= lex.len and lexIsDigit(ssub(lex.source, lex.pos, lex.pos)) do
                lex.pos = lex.pos + 1
            end
            if lex.pos <= lex.len then
                c = ssub(lex.source, lex.pos, lex.pos)
                if c == "e" or c == "E" then
                    lex.pos = lex.pos + 1
                    if lex.pos <= lex.len then
                        c2 = ssub(lex.source, lex.pos, lex.pos)
                        if c2 == "+" or c2 == "-" then lex.pos = lex.pos + 1 end
                    end
                    while lex.pos <= lex.len and lexIsDigit(ssub(lex.source, lex.pos, lex.pos)) do
                        lex.pos = lex.pos + 1
                    end
                end
            end
            lex.value = tonumber(ssub(lex.source, start, lex.pos - 1))
            lex.token = TK_NUMBER
        else
            lex.token = TK_DOT; lex.value = null
        end
    else if ch == ":" then
        lex.token = TK_COLON; lex.value = null
    else if ch == "=" then
        if lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) == "=" then
            lex.pos = lex.pos + 1
            lex.token = TK_EQ; lex.value = null
        else
            lex.token = TK_ASSIGN; lex.value = null
        end
    else if ch == "~" then
        if lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) == "=" then
            lex.pos = lex.pos + 1
            lex.token = TK_NEQ; lex.value = null
        else
            error("unexpected character '~' at line " .. lex.line)
        end
    else if ch == "<" then
        if lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) == "=" then
            lex.pos = lex.pos + 1
            lex.token = TK_LE; lex.value = null
        else
            lex.token = TK_LT; lex.value = null
        end
    else if ch == ">" then
        if lex.pos <= lex.len and ssub(lex.source, lex.pos, lex.pos) == "=" then
            lex.pos = lex.pos + 1
            lex.token = TK_GE; lex.value = null
        else
            lex.token = TK_GT; lex.value = null
        end
    else
        error("unexpected character '" .. ch .. "' at line " .. lex.line)
    end
end

-- ============================================================================
-- AST NODE CONSTRUCTORS
-- ============================================================================

function astNode(tag, fields)
    fields.tag = tag
    return fields
end

-- ============================================================================
-- PARSER
-- ============================================================================

function newParser(source)
    parser = {}
    parser.lex = newLexer(source)
    lexNext(parser.lex)
    return parser
end

function parserError(parser, msg)
    error("parse error at line " .. parser.lex.line .. ": " .. msg .. " (got " .. tostring(parser.lex.token) .. ")")
end

function parserExpect(parser, tk)
    if parser.lex.token != tk then
        parserError(parser, "expected '" .. tk .. "'")
    end
    val = parser.lex.value
    lexNext(parser.lex)
    return val
end

function parserCheck(parser, tk)
    return parser.lex.token == tk
end

function parserMatch(parser, tk)
    if parser.lex.token == tk then
        val = parser.lex.value
        lexNext(parser.lex)
        return true, val
    end
    return false, null
end

-- Forward declarations
parseExpr = null
parseBlock = null
parseStat = null

function parsePrimaryExpr(parser)
    tk = parser.lex.token
    node = null
    if tk == TK_NAME then
        node = astNode("Var", {name = parser.lex.value})
        lexNext(parser.lex)
    else if tk == TK_LPAREN then
        lexNext(parser.lex)
        node = parseExpr(parser)
        parserExpect(parser, TK_RPAREN)
        node = astNode("Paren", {expr = node})
    else
        parserError(parser, "expected name or '('")
    end
    return node
end

function parseSuffixExpr(parser)
    node = parsePrimaryExpr(parser)
    while true do
        tk = parser.lex.token
        if tk == TK_DOT then
            lexNext(parser.lex)
            field = parserExpect(parser, TK_NAME)
            node = astNode("Index", {obj = node, key = astNode("String", {value = field})})
        else if tk == TK_LBRACKET then
            lexNext(parser.lex)
            key = parseExpr(parser)
            parserExpect(parser, TK_RBRACKET)
            node = astNode("Index", {obj = node, key = key})
        else if tk == TK_COLON then
            lexNext(parser.lex)
            method = parserExpect(parser, TK_NAME)
            args = parseCallArgs(parser)
            node = astNode("MethodCall", {obj = node, method = method, args = args})
        else if tk == TK_LPAREN or tk == TK_LBRACE or tk == TK_STRING then
            args = parseCallArgs(parser)
            node = astNode("Call", {func = node, args = args})
        else
            break
        end
    end
    return node
end

function parseCallArgs(parser)
    tk = parser.lex.token
    if tk == TK_LPAREN then
        lexNext(parser.lex)
        args = {}
        if not parserCheck(parser, TK_RPAREN) then
            tinsert(args, parseExpr(parser))
            while parserCheck(parser, TK_COMMA) do
                lexNext(parser.lex)
                tinsert(args, parseExpr(parser))
            end
        end
        parserExpect(parser, TK_RPAREN)
        return args
    else if tk == TK_LBRACE then
        return {parseTableConstructor(parser)}
    else if tk == TK_STRING then
        val = parser.lex.value
        lexNext(parser.lex)
        return {astNode("String", {value = val})}
    else
        parserError(parser, "expected function arguments")
    end
end

function parseTableConstructor(parser)
    parserExpect(parser, TK_LBRACE)
    fields = {}
    while not parserCheck(parser, TK_RBRACE) do
        field = {}
        if parserCheck(parser, TK_LBRACKET) then
            lexNext(parser.lex)
            field.key = parseExpr(parser)
            parserExpect(parser, TK_RBRACKET)
            parserExpect(parser, TK_ASSIGN)
            field.value = parseExpr(parser)
            field.kind = "bracket"
        else if parserCheck(parser, TK_NAME) then
            -- Could be name=value or just an expression
            savedPos = parser.lex.pos
            savedLine = parser.lex.line
            savedToken = parser.lex.token
            savedValue = parser.lex.value
            name = parser.lex.value
            lexNext(parser.lex)
            if parserCheck(parser, TK_ASSIGN) then
                lexNext(parser.lex)
                field.key = astNode("String", {value = name})
                field.value = parseExpr(parser)
                field.kind = "name"
            else
                -- Restore state and parse as expression
                parser.lex.pos = savedPos
                parser.lex.line = savedLine
                parser.lex.token = savedToken
                parser.lex.value = savedValue
                field.value = parseExpr(parser)
                field.kind = "seq"
            end
        else
            field.value = parseExpr(parser)
            field.kind = "seq"
        end
        tinsert(fields, field)
        if not parserMatch(parser, TK_COMMA) then
            parserMatch(parser, TK_SEMI)
        end
    end
    parserExpect(parser, TK_RBRACE)
    return astNode("Table", {fields = fields})
end

function parseSimpleExpr(parser)
    tk = parser.lex.token
    if tk == TK_NUMBER then
        val = parser.lex.value
        lexNext(parser.lex)
        return astNode("Number", {value = val})
    else if tk == TK_STRING then
        val = parser.lex.value
        lexNext(parser.lex)
        return astNode("String", {value = val})
    else if tk == TK_NIL then
        lexNext(parser.lex)
        return astNode("Nil", {})
    else if tk == TK_TRUE then
        lexNext(parser.lex)
        return astNode("Bool", {value = true})
    else if tk == TK_FALSE then
        lexNext(parser.lex)
        return astNode("Bool", {value = false})
    else if tk == TK_DOTS then
        lexNext(parser.lex)
        return astNode("Dots", {})
    else if tk == TK_LBRACE then
        return parseTableConstructor(parser)
    else if tk == TK_FUNCTION then
        lexNext(parser.lex)
        return parseFuncBody(parser)
    else
        return parseSuffixExpr(parser)
    end
end

function parseUnaryExpr(parser)
    tk = parser.lex.token
    if tk == TK_NOT then
        lexNext(parser.lex)
        expr = parseUnaryExpr(parser)
        return astNode("Unop", {op = "not", expr = expr})
    else if tk == TK_MINUS then
        lexNext(parser.lex)
        expr = parseUnaryExpr(parser)
        return astNode("Unop", {op = "-", expr = expr})
    else if tk == TK_HASH then
        lexNext(parser.lex)
        expr = parseUnaryExpr(parser)
        return astNode("Unop", {op = "#", expr = expr})
    else
        return parseSimpleExpr(parser)
    end
end

-- Operator precedence table
-- Precedence levels (higher = tighter binding):
-- 1: or
-- 2: and
-- 3: < > <= >= ~= ==
-- 4: ..
-- 5: + -
-- 6: * / // %
-- 7: unary (not - #)
-- 8: ^

function getBinopPrecedence(tk)
    if tk == TK_OR then return 1
    else if tk == TK_AND then return 2
    else if tk == TK_LT or tk == TK_GT or tk == TK_LE or tk == TK_GE or tk == TK_NEQ or tk == TK_EQ then return 3
    else if tk == TK_DOTDOT then return 4
    else if tk == TK_PLUS or tk == TK_MINUS then return 5
    else if tk == TK_STAR or tk == TK_SLASH or tk == TK_DSLASH or tk == TK_PERCENT then return 6
    else if tk == TK_CARET then return 8
    else return -1
    end
end

function isRightAssoc(tk)
    return tk == TK_CARET or tk == TK_DOTDOT
end

function parseBinopExpr(parser, minPrec)
    lhs = parseUnaryExpr(parser)
    while true do
        tk = parser.lex.token
        prec = getBinopPrecedence(tk)
        if prec < minPrec then break end
        op = tk
        lexNext(parser.lex)
        nextMinPrec = null
        if isRightAssoc(op) then
            nextMinPrec = prec
        else
            nextMinPrec = prec + 1
        end
        rhs = parseBinopExpr(parser, nextMinPrec)
        lhs = astNode("Binop", {op = op, left = lhs, right = rhs})
    end
    return lhs
end

parseExpr = function(parser)
    return parseBinopExpr(parser, 1)
end

function parseFuncBody(parser)
    parserExpect(parser, TK_LPAREN)
    params = {}
    hasVarargs = false
    if not parserCheck(parser, TK_RPAREN) then
        if parserCheck(parser, TK_DOTS) then
            hasVarargs = true
            lexNext(parser.lex)
        else
            tinsert(params, parserExpect(parser, TK_NAME))
            while parserCheck(parser, TK_COMMA) do
                lexNext(parser.lex)
                if parserCheck(parser, TK_DOTS) then
                    hasVarargs = true
                    lexNext(parser.lex)
                    break
                end
                tinsert(params, parserExpect(parser, TK_NAME))
            end
        end
    end
    parserExpect(parser, TK_RPAREN)
    body = parseBlock(parser)
    parserExpect(parser, TK_END)
    return astNode("Function", {params = params, varargs = hasVarargs, body = body})
end

function parseExprList(parser)
    list = {}
    tinsert(list, parseExpr(parser))
    while parserCheck(parser, TK_COMMA) do
        lexNext(parser.lex)
        tinsert(list, parseExpr(parser))
    end
    return list
end

function parseNameList(parser)
    list = {}
    tinsert(list, parserExpect(parser, TK_NAME))
    while parserCheck(parser, TK_COMMA) do
        lexNext(parser.lex)
        tinsert(list, parserExpect(parser, TK_NAME))
    end
    return list
end

function parseLvalueList(parser)
    list = {}
    tinsert(list, parseSuffixExpr(parser))
    while parserCheck(parser, TK_COMMA) do
        lexNext(parser.lex)
        tinsert(list, parseSuffixExpr(parser))
    end
    return list
end

parseStat = function(parser)
    tk = parser.lex.token

    if tk == TK_LOCAL then
        lexNext(parser.lex)
        if parserCheck(parser, TK_FUNCTION) then
            lexNext(parser.lex)
            name = parserExpect(parser, TK_NAME)
            func = parseFuncBody(parser)
            return astNode("LocalFunc", {name = name, func = func})
        else
            names = parseNameList(parser)
            values = null
            if parserMatch(parser, TK_ASSIGN) then
                values = parseExprList(parser)
            end
            return astNode("Local", {names = names, values = values})
        end
    else if tk == TK_FUNCTION then
        lexNext(parser.lex)
        -- function name or function t.name or function t:name
        name = parserExpect(parser, TK_NAME)
        indexChain = {name}
        isMethod = false
        while parserCheck(parser, TK_DOT) do
            lexNext(parser.lex)
            tinsert(indexChain, parserExpect(parser, TK_NAME))
        end
        if parserCheck(parser, TK_COLON) then
            lexNext(parser.lex)
            tinsert(indexChain, parserExpect(parser, TK_NAME))
            isMethod = true
        end
        func = parseFuncBody(parser)
        return astNode("FuncDef", {names = indexChain, isMethod = isMethod, func = func})
    else if tk == TK_IF then
        lexNext(parser.lex)
        clauses = {}
        cond = parseExpr(parser)
        parserExpect(parser, TK_THEN)
        body = parseBlock(parser)
        tinsert(clauses, {cond = cond, body = body})
        while parserCheck(parser, TK_ELSEIF) do
            lexNext(parser.lex)
            cond = parseExpr(parser)
            parserExpect(parser, TK_THEN)
            body = parseBlock(parser)
            tinsert(clauses, {cond = cond, body = body})
        end
        elseBody = null
        if parserMatch(parser, TK_ELSE) then
            elseBody = parseBlock(parser)
        end
        parserExpect(parser, TK_END)
        return astNode("If", {clauses = clauses, elseBody = elseBody})
    else if tk == TK_WHILE then
        lexNext(parser.lex)
        cond = parseExpr(parser)
        parserExpect(parser, TK_DO)
        body = parseBlock(parser)
        parserExpect(parser, TK_END)
        return astNode("While", {cond = cond, body = body})
    else if tk == TK_REPEAT then
        lexNext(parser.lex)
        body = parseBlock(parser)
        parserExpect(parser, TK_UNTIL)
        cond = parseExpr(parser)
        return astNode("Repeat", {body = body, cond = cond})
    else if tk == TK_FOR then
        lexNext(parser.lex)
        firstName = parserExpect(parser, TK_NAME)
        if parserCheck(parser, TK_ASSIGN) then
            -- numeric for
            lexNext(parser.lex)
            start = parseExpr(parser)
            parserExpect(parser, TK_COMMA)
            limit = parseExpr(parser)
            step = null
            if parserMatch(parser, TK_COMMA) then
                step = parseExpr(parser)
            end
            parserExpect(parser, TK_DO)
            body = parseBlock(parser)
            parserExpect(parser, TK_END)
            return astNode("NumFor", {var = firstName, start = start, limit = limit, step = step, body = body})
        else
            -- generic for
            names = {firstName}
            while parserCheck(parser, TK_COMMA) do
                lexNext(parser.lex)
                tinsert(names, parserExpect(parser, TK_NAME))
            end
            parserExpect(parser, TK_IN)
            iterExprs = parseExprList(parser)
            parserExpect(parser, TK_DO)
            body = parseBlock(parser)
            parserExpect(parser, TK_END)
            return astNode("GenFor", {names = names, iters = iterExprs, body = body})
        end
    else if tk == TK_DO then
        lexNext(parser.lex)
        body = parseBlock(parser)
        parserExpect(parser, TK_END)
        return astNode("Do", {body = body})
    else if tk == TK_RETURN then
        lexNext(parser.lex)
        values = {}
        if not parserCheck(parser, TK_END) and not parserCheck(parser, TK_ELSE) and not parserCheck(parser, TK_ELSEIF) and not parserCheck(parser, TK_UNTIL) and not parserCheck(parser, TK_EOF) and not parserCheck(parser, TK_SEMI) then
            values = parseExprList(parser)
        end
        parserMatch(parser, TK_SEMI)
        return astNode("Return", {values = values})
    else if tk == TK_BREAK then
        lexNext(parser.lex)
        return astNode("Break", {})
    else if tk == TK_CONTINUE then
        lexNext(parser.lex)
        return astNode("Continue", {})
    else
        -- expression statement (assignment or function call)
        suffixes = parseLvalueList(parser)
        if parserCheck(parser, TK_ASSIGN) then
            lexNext(parser.lex)
            values = parseExprList(parser)
            return astNode("Assign", {targets = suffixes, values = values})
        else
            -- must be a function call
            if #suffixes == 1 then
                return astNode("ExprStat", {expr = suffixes[1]})
            else
                parserError(parser, "expected assignment or function call")
            end
        end
    end
end

function isBlockEnd(tk)
    return tk == TK_END or tk == TK_ELSE or tk == TK_ELSEIF or tk == TK_UNTIL or tk == TK_EOF
end

parseBlock = function(parser)
    stmts = {}
    while not isBlockEnd(parser.lex.token) do
        stmt = parseStat(parser)
        tinsert(stmts, stmt)
        parserMatch(parser, TK_SEMI)
    end
    return stmts
end

function parseProgram(source)
    parser = newParser(source)
    block = parseBlock(parser)
    if parser.lex.token != TK_EOF then
        parserError(parser, "expected EOF")
    end
    return block
end

-- ============================================================================
-- EVALUATOR
-- ============================================================================

-- Signals
SIGNAL_BREAK = {type = "break"}
SIGNAL_CONTINUE = {type = "continue"}

function newSignalReturn(vals)
    return {type = "return", values = vals}
end

-- Environment
function newEnv(parent)
    env = {}
    env.vars = {}
    env.parent = parent
    return env
end

function envGet(env, name)
    e = env
    while e do
        v = e.vars[name]
        if v != null then
            return v[1] -- stored as {value} to allow null distinction
        end
        e = e.parent
    end
    return null
end

function envSet(env, name, value)
    e = env
    while e do
        if e.vars[name] != null then
            e.vars[name] = {value}
            return true
        end
        e = e.parent
    end
    return false
end

function envDefine(env, name, value)
    env.vars[name] = {value}
end

-- Closure
function newClosure(node, env, globals)
    cl = {}
    cl.node = node
    cl.env = env
    cl.globals = globals
    return cl
end

-- Interpreter state
function newInterp()
    interp = {}
    interp.globals = {}
    interp.output = {}
    interp.callDepth = 0
    return interp
end

-- Get metafield
function getMetafield(interp, val, field)
    if type(val) == "table" then
        mt = interp.metatables[val]
        if mt then
            handler = rawget(mt, field)
            return handler
        end
    end
    return null
end

-- Arithmetic metamethod helper
function arith(interp, op, a, b)
    metafield = null
    if op == "+" then metafield = "__add"
    else if op == "-" then metafield = "__sub"
    else if op == "*" then metafield = "__mul"
    else if op == "/" then metafield = "__div"
    else if op == "//" then metafield = "__idiv"
    else if op == "%" then metafield = "__mod"
    else if op == "^" then metafield = "__pow"
    end
    handler = getMetafield(interp, a, metafield) or getMetafield(interp, b, metafield)
    if handler then
        results = callFunction(interp, handler, {a, b})
        if results and #results > 0 then return results[1] end
        return null
    end
    error("attempt to perform arithmetic on a " .. type(a) .. " value")
end

-- Table indexing with __index metamethod
function tableIndex(interp, tbl, key)
    val = rawget(tbl, key)
    if val != null then return val end
    mt = interp.metatables[tbl]
    if mt then
        idx = rawget(mt, "__index")
        if idx != null then
            if type(idx) == "table" then
                return tableIndex(interp, idx, key)
            else if type(idx) == "function" or (type(idx) == "table" and idx._isClosure) then
                results = callFunction(interp, idx, {tbl, key})
                if results and #results > 0 then return results[1] end
                return null
            end
        end
    end
    return null
end

-- Table newindex with __newindex metamethod
function tableNewIndex(interp, tbl, key, value)
    existing = rawget(tbl, key)
    if existing != null then
        rawset(tbl, key, value)
        return
    end
    mt = interp.metatables[tbl]
    if mt then
        ni = rawget(mt, "__newindex")
        if ni != null then
            if type(ni) == "function" or (type(ni) == "table" and ni._isClosure) then
                callFunction(interp, ni, {tbl, key, value})
                return
            else if type(ni) == "table" then
                tableNewIndex(interp, ni, key, value)
                return
            end
        end
    end
    rawset(tbl, key, value)
end

-- Call a function (native or closure)
function callFunction(interp, func, args)
    if type(func) == "function" then
        return {func(unpack_(args or {}))}
    end
    if type(func) == "table" and func._isClosure then
        return callClosure(interp, func, args or {})
    end
    -- try __call metamethod
    if type(func) == "table" then
        mt = interp.metatables[func]
        if mt then
            callMeta = rawget(mt, "__call")
            if callMeta then
                newArgs = {func}
                if args then
                    for i = 1, #args do
                        newArgs[#newArgs + 1] = args[i]
                    end
                end
                return callFunction(interp, callMeta, newArgs)
            end
        end
    end
    error("attempt to call a " .. type(func) .. " value")
end

function callClosure(interp, closure, args)
    interp.callDepth = interp.callDepth + 1
    if interp.callDepth > 200 then
        interp.callDepth = interp.callDepth - 1
        error("stack overflow")
    end
    funcNode = closure.node
    localEnv = newEnv(closure.env)
    -- Bind parameters
    paramCount = #funcNode.params
    for i = 1, paramCount do
        argVal = null
        if args and i <= #args then argVal = args[i] end
        envDefine(localEnv, funcNode.params[i], argVal)
    end
    -- Bind varargs
    if funcNode.varargs then
        varargsList = {}
        if args then
            for i = paramCount + 1, #args do
                varargsList[#varargsList + 1] = args[i]
            end
        end
        envDefine(localEnv, "...", varargsList)
    end
    result = execBlock(interp, funcNode.body, localEnv)
    interp.callDepth = interp.callDepth - 1
    if result and result.type == "return" then
        return result.values
    end
    return {}
end

-- Evaluate expression - returns single value
function evalExpr(interp, node, env)
    results = evalExprMulti(interp, node, env)
    if results and #results > 0 then return results[1] end
    return null
end

-- Evaluate expression - returns multiple values (only for last position)
function evalExprMulti(interp, node, env)
    tag = node.tag
    if tag == "Number" then
        return {node.value}
    else if tag == "String" then
        return {node.value}
    else if tag == "Nil" then
        return {null}
    else if tag == "Bool" then
        return {node.value}
    else if tag == "Dots" then
        varargs = envGet(env, "...")
        if varargs then return varargs end
        return {}
    else if tag == "Var" then
        val = envGet(env, node.name)
        if val == null then
            val = interp.globals[node.name]
        end
        return {val}
    else if tag == "Paren" then
        val = evalExpr(interp, node.expr, env)
        return {val}
    else if tag == "Unop" then
        return {evalUnop(interp, node, env)}
    else if tag == "Binop" then
        return {evalBinop(interp, node, env)}
    else if tag == "Index" then
        obj = evalExpr(interp, node.obj, env)
        key = evalExpr(interp, node.key, env)
        if type(obj) == "table" then
            return {tableIndex(interp, obj, key)}
        end
        error("attempt to index a " .. type(obj) .. " value")
    else if tag == "Call" then
        return evalCall(interp, node, env)
    else if tag == "MethodCall" then
        return evalMethodCall(interp, node, env)
    else if tag == "Table" then
        return {evalTableConstructor(interp, node, env)}
    else if tag == "Function" then
        cl = newClosure(node, env, interp.globals)
        cl._isClosure = true
        return {cl}
    else
        error("unknown expression node: " .. tostring(tag))
    end
end

function evalUnop(interp, node, env)
    val = evalExpr(interp, node.expr, env)
    op = node.op
    if op == "-" then
        if type(val) == "number" then return -val end
        handler = getMetafield(interp, val, "__unm")
        if handler then
            r = callFunction(interp, handler, {val})
            if r and #r > 0 then return r[1] end
            return null
        end
        error("attempt to perform arithmetic on a " .. type(val) .. " value")
    else if op == "#" then
        if type(val) == "string" then return slen(val) end
        if type(val) == "table" then
            handler = getMetafield(interp, val, "__len")
            if handler then
                r = callFunction(interp, handler, {val})
                if r and #r > 0 then return r[1] end
                return null
            end
            return #val
        end
        error("attempt to get length of a " .. type(val) .. " value")
    else if op == "not" then
        return not val
    end
end

function evalBinop(interp, node, env)
    op = node.op

    -- Short-circuit operators
    if op == TK_AND then
        left = evalExpr(interp, node.left, env)
        if not left then return left end
        return evalExpr(interp, node.right, env)
    else if op == TK_OR then
        left = evalExpr(interp, node.left, env)
        if left then return left end
        return evalExpr(interp, node.right, env)
    end

    left = evalExpr(interp, node.left, env)
    right = evalExpr(interp, node.right, env)

    if op == TK_PLUS then
        if type(left) == "number" and type(right) == "number" then return left + right end
        return arith(interp, "+", left, right)
    else if op == TK_MINUS then
        if type(left) == "number" and type(right) == "number" then return left - right end
        return arith(interp, "-", left, right)
    else if op == TK_STAR then
        if type(left) == "number" and type(right) == "number" then return left * right end
        return arith(interp, "*", left, right)
    else if op == TK_SLASH then
        if type(left) == "number" and type(right) == "number" then return left / right end
        return arith(interp, "/", left, right)
    else if op == TK_DSLASH then
        if type(left) == "number" and type(right) == "number" then return floor(left / right) end
        return arith(interp, "//", left, right)
    else if op == TK_PERCENT then
        if type(left) == "number" and type(right) == "number" then return left % right end
        return arith(interp, "%", left, right)
    else if op == TK_CARET then
        if type(left) == "number" and type(right) == "number" then return left ^ right end
        return arith(interp, "^", left, right)
    else if op == TK_DOTDOT then
        if (type(left) == "string" or type(left) == "number") and (type(right) == "string" or type(right) == "number") then
            return tostring(left) .. tostring(right)
        end
        handler = getMetafield(interp, left, "__concat") or getMetafield(interp, right, "__concat")
        if handler then
            r = callFunction(interp, handler, {left, right})
            if r and #r > 0 then return r[1] end
            return null
        end
        error("attempt to concatenate a " .. type(left) .. " value")
    else if op == TK_EQ then
        if left == right then return true end
        if type(left) != type(right) then return false end
        handler = getMetafield(interp, left, "__eq")
        if handler then
            r = callFunction(interp, handler, {left, right})
            if r and #r > 0 then return r[1] end
            return false
        end
        return false
    else if op == TK_NEQ then
        if left == right then return false end
        if type(left) != type(right) then return true end
        handler = getMetafield(interp, left, "__eq")
        if handler then
            r = callFunction(interp, handler, {left, right})
            if r and #r > 0 then return not r[1] end
            return true
        end
        return true
    else if op == TK_LT then
        if type(left) == "number" and type(right) == "number" then return left < right end
        if type(left) == "string" and type(right) == "string" then return left < right end
        handler = getMetafield(interp, left, "__lt") or getMetafield(interp, right, "__lt")
        if handler then
            r = callFunction(interp, handler, {left, right})
            if r and #r > 0 then return r[1] end
            return false
        end
        error("attempt to compare two " .. type(left) .. " values")
    else if op == TK_GT then
        if type(left) == "number" and type(right) == "number" then return left > right end
        if type(left) == "string" and type(right) == "string" then return left > right end
        handler = getMetafield(interp, right, "__lt") or getMetafield(interp, left, "__lt")
        if handler then
            r = callFunction(interp, handler, {right, left})
            if r and #r > 0 then return r[1] end
            return false
        end
        error("attempt to compare two " .. type(left) .. " values")
    else if op == TK_LE then
        if type(left) == "number" and type(right) == "number" then return left <= right end
        if type(left) == "string" and type(right) == "string" then return left <= right end
        handler = getMetafield(interp, left, "__le") or getMetafield(interp, right, "__le")
        if handler then
            r = callFunction(interp, handler, {left, right})
            if r and #r > 0 then return r[1] end
            return false
        end
        error("attempt to compare two " .. type(left) .. " values")
    else if op == TK_GE then
        if type(left) == "number" and type(right) == "number" then return left >= right end
        if type(left) == "string" and type(right) == "string" then return left >= right end
        handler = getMetafield(interp, right, "__le") or getMetafield(interp, left, "__le")
        if handler then
            r = callFunction(interp, handler, {right, left})
            if r and #r > 0 then return r[1] end
            return false
        end
        error("attempt to compare two " .. type(left) .. " values")
    end
    error("unknown binop: " .. tostring(op))
end

function evalCall(interp, node, env)
    func = evalExpr(interp, node.func, env)
    args = evalArgList(interp, node.args, env)
    return callFunction(interp, func, args)
end

function evalMethodCall(interp, node, env)
    obj = evalExpr(interp, node.obj, env)
    method = null
    if type(obj) == "table" then
        method = tableIndex(interp, obj, node.method)
    else
        error("attempt to index a " .. type(obj) .. " value")
    end
    args = evalArgList(interp, node.args, env)
    tinsert(args, 1, obj)
    return callFunction(interp, method, args)
end

function evalArgList(interp, argNodes, env)
    args = {}
    if not argNodes or #argNodes == 0 then return args end
    -- All args except last: take single value
    for i = 1, #argNodes - 1 do
        args[#args + 1] = evalExpr(interp, argNodes[i], env)
    end
    -- Last arg: expand multiple returns
    lastResults = evalExprMulti(interp, argNodes[#argNodes], env)
    if lastResults then
        for i = 1, #lastResults do
            args[#args + 1] = lastResults[i]
        end
    end
    return args
end

function evalTableConstructor(interp, node, env)
    tbl = {}
    arrayIdx = 1
    fields = node.fields
    for i = 1, #fields do
        field = fields[i]
        if field.kind == "bracket" then
            key = evalExpr(interp, field.key, env)
            val = null
            if i == #fields then
                multi = evalExprMulti(interp, field.value, env)
                val = multi and multi[1] or null
            else
                val = evalExpr(interp, field.value, env)
            end
            rawset(tbl, key, val)
        else if field.kind == "name" then
            key = field.key.value
            val = evalExpr(interp, field.value, env)
            rawset(tbl, key, val)
        else
            -- sequential
            if i == #fields then
                -- last item: expand multi-return
                multi = evalExprMulti(interp, field.value, env)
                if multi then
                    for j = 1, #multi do
                        rawset(tbl, arrayIdx, multi[j])
                        arrayIdx = arrayIdx + 1
                    end
                end
            else
                val = evalExpr(interp, field.value, env)
                rawset(tbl, arrayIdx, val)
                arrayIdx = arrayIdx + 1
            end
        end
    end
    return tbl
end

-- Execute a block, return a signal or null
function execBlock(interp, stmts, env)
    for i = 1, #stmts do
        result = execStat(interp, stmts[i], env)
        if result then return result end
    end
    return null
end

-- Execute a statement
function execStat(interp, node, env)
    tag = node.tag

    if tag == "Local" then
        return execLocal(interp, node, env)
    else if tag == "LocalFunc" then
        return execLocalFunc(interp, node, env)
    else if tag == "Assign" then
        return execAssign(interp, node, env)
    else if tag == "FuncDef" then
        return execFuncDef(interp, node, env)
    else if tag == "If" then
        return execIf(interp, node, env)
    else if tag == "While" then
        return execWhile(interp, node, env)
    else if tag == "Repeat" then
        return execRepeat(interp, node, env)
    else if tag == "NumFor" then
        return execNumFor(interp, node, env)
    else if tag == "GenFor" then
        return execGenFor(interp, node, env)
    else if tag == "Do" then
        blockEnv = newEnv(env)
        return execBlock(interp, node.body, blockEnv)
    else if tag == "Return" then
        return execReturn(interp, node, env)
    else if tag == "Break" then
        return SIGNAL_BREAK
    else if tag == "Continue" then
        return SIGNAL_CONTINUE
    else if tag == "ExprStat" then
        evalExprMulti(interp, node.expr, env)
        return null
    else
        error("unknown statement: " .. tostring(tag))
    end
end

function execLocal(interp, node, env)
    names = node.names
    values = node.values
    if values then
        vals = {}
        -- Evaluate all except last for single value
        for i = 1, #values - 1 do
            vals[#vals + 1] = evalExpr(interp, values[i], env)
        end
        -- Last value: expand multi-return
        if #values > 0 then
            lastResults = evalExprMulti(interp, values[#values], env)
            if lastResults then
                for i = 1, #lastResults do
                    vals[#vals + 1] = lastResults[i]
                end
            end
        end
        for i = 1, #names do
            envDefine(env, names[i], vals[i])
        end
    else
        for i = 1, #names do
            envDefine(env, names[i], null)
        end
    end
    return null
end

function execLocalFunc(interp, node, env)
    -- Define name first (for recursion)
    envDefine(env, node.name, null)
    cl = newClosure(node.func, env, interp.globals)
    cl._isClosure = true
    envDefine(env, node.name, cl)
    return null
end

function execAssign(interp, node, env)
    targets = node.targets
    values = node.values
    vals = {}
    -- Evaluate all except last for single value
    for i = 1, #values - 1 do
        vals[#vals + 1] = evalExpr(interp, values[i], env)
    end
    -- Last value: expand multi-return
    if #values > 0 then
        lastResults = evalExprMulti(interp, values[#values], env)
        if lastResults then
            for i = 1, #lastResults do
                vals[#vals + 1] = lastResults[i]
            end
        end
    end
    for i = 1, #targets do
        target = targets[i]
        val = vals[i]
        if target.tag == "Var" then
            if not envSet(env, target.name, val) then
                interp.globals[target.name] = val
            end
        else if target.tag == "Index" then
            obj = evalExpr(interp, target.obj, env)
            key = evalExpr(interp, target.key, env)
            if type(obj) == "table" then
                tableNewIndex(interp, obj, key, val)
            else
                error("attempt to index a " .. type(obj) .. " value")
            end
        else
            error("invalid assignment target: " .. tostring(target.tag))
        end
    end
    return null
end

function execFuncDef(interp, node, env)
    funcNode = node.func
    if node.isMethod then
        -- Add implicit self parameter
        newParams = {"self"}
        for i = 1, #funcNode.params do
            newParams[#newParams + 1] = funcNode.params[i]
        end
        funcNode = {tag = funcNode.tag, params = newParams, varargs = funcNode.varargs, body = funcNode.body}
    end
    cl = newClosure(funcNode, env, interp.globals)
    cl._isClosure = true

    names = node.names
    if #names == 1 then
        -- Simple global function
        if not envSet(env, names[1], cl) then
            interp.globals[names[1]] = cl
        end
    else
        -- Dot chain: function a.b.c()
        obj = null
        v = envGet(env, names[1])
        if v == null then v = interp.globals[names[1]] end
        obj = v
        for i = 2, #names - 1 do
            obj = tableIndex(interp, obj, names[i])
        end
        tableNewIndex(interp, obj, names[#names], cl)
    end
    return null
end

function execIf(interp, node, env)
    for i = 1, #node.clauses do
        clause = node.clauses[i]
        cond = evalExpr(interp, clause.cond, env)
        if cond and cond != false then
            blockEnv = newEnv(env)
            return execBlock(interp, clause.body, blockEnv)
        end
    end
    if node.elseBody then
        blockEnv = newEnv(env)
        return execBlock(interp, node.elseBody, blockEnv)
    end
    return null
end

function execWhile(interp, node, env)
    while true do
        cond = evalExpr(interp, node.cond, env)
        if not cond or cond == false then break end
        blockEnv = newEnv(env)
        result = execBlock(interp, node.body, blockEnv)
        if result then
            if result == SIGNAL_BREAK then break end
            if result == SIGNAL_CONTINUE then
                -- continue, just loop
            else
                return result -- return signal
            end
        end
    end
    return null
end

function execRepeat(interp, node, env)
    while true do
        blockEnv = newEnv(env)
        result = execBlock(interp, node.body, blockEnv)
        if result then
            if result == SIGNAL_BREAK then break end
            if result == SIGNAL_CONTINUE then
                -- evaluate condition before continuing
                cond = evalExpr(interp, node.cond, blockEnv)
                if cond and cond != false then break end
            else
                return result
            end
        else
            cond = evalExpr(interp, node.cond, blockEnv)
            if cond and cond != false then break end
        end
    end
    return null
end

function execNumFor(interp, node, env)
    startVal = evalExpr(interp, node.start, env)
    limitVal = evalExpr(interp, node.limit, env)
    stepVal = 1
    if node.step then stepVal = evalExpr(interp, node.step, env) end
    if type(startVal) != "number" or type(limitVal) != "number" or type(stepVal) != "number" then
        error("'for' limit must be a number")
    end
    if stepVal == 0 then error("'for' step is zero") end

    i = startVal
    while true do
        if stepVal > 0 then
            if i > limitVal then break end
        else
            if i < limitVal then break end
        end
        blockEnv = newEnv(env)
        envDefine(blockEnv, node.var, i)
        result = execBlock(interp, node.body, blockEnv)
        if result then
            if result == SIGNAL_BREAK then break end
            if result == SIGNAL_CONTINUE then
                -- continue
            else
                return result
            end
        end
        i = i + stepVal
    end
    return null
end

function execGenFor(interp, node, env)
    iterExprs = evalArgList(interp, node.iters, env)
    iterFunc = iterExprs[1]
    state = iterExprs[2]
    control = iterExprs[3]

    while true do
        results = callFunction(interp, iterFunc, {state, control})
        if not results or results[1] == null then break end
        control = results[1]
        blockEnv = newEnv(env)
        for i = 1, #node.names do
            envDefine(blockEnv, node.names[i], results[i])
        end
        result = execBlock(interp, node.body, blockEnv)
        if result then
            if result == SIGNAL_BREAK then break end
            if result == SIGNAL_CONTINUE then
                -- continue
            else
                return result
            end
        end
    end
    return null
end

function execReturn(interp, node, env)
    values = node.values
    if not values or #values == 0 then
        return newSignalReturn({})
    end
    vals = {}
    for i = 1, #values - 1 do
        vals[#vals + 1] = evalExpr(interp, values[i], env)
    end
    -- Last value: expand multi-return
    lastResults = evalExprMulti(interp, values[#values], env)
    if lastResults then
        for i = 1, #lastResults do
            vals[#vals + 1] = lastResults[i]
        end
    end
    return newSignalReturn(vals)
end

-- ============================================================================
-- STANDARD LIBRARY
-- ============================================================================

function setupStdlib(interp)
    interp.metatables = {} -- table -> metatable mapping
    G = interp.globals

    G["print"] = function(...)
        args = {...}
        n = select("#", ...)
        parts = {}
        for i = 1, n do
            parts[i] = interpToString(interp, args[i])
        end
        tinsert(interp.output, tconcat(parts, "\t"))
    end

    G["tostring"] = function(v)
        return interpToString(interp, v)
    end

    G["tonumber"] = function(v, base)
        if base then
            return tonumber(v, base)
        end
        return tonumber(v)
    end

    G["type"] = function(v)
        if type(v) == "table" and v._isClosure then
            return "function"
        end
        return type(v)
    end

    G["error"] = function(msg, level)
        error(msg)
    end

    G["assert"] = function(v, msg, ...)
        if not v then
            error(msg or "assertion failed!")
        end
        return v, msg, ...
    end

    G["select"] = function(n, ...)
        args = {...}
        if n == "#" then return select("#", ...) end
        if type(n) != "number" then error("bad argument #1 to 'select'") end
        results = {}
        for i = n, select("#", ...) do
            results[#results + 1] = args[i]
        end
        return unpack_(results)
    end

    G["unpack"] = function(tbl, i, j)
        i = i or 1
        j = j or #tbl
        return unpack_(tbl, i, j)
    end

    G["rawget"] = function(t, k)
        return rawget(t, k)
    end

    G["rawset"] = function(t, k, v)
        rawset(t, k, v)
        return t
    end

    G["rawequal"] = function(a, b)
        return rawequal(a, b)
    end

    G["setmetatable"] = function(t, mt)
        if type(t) != "table" then error("bad argument #1 to 'setmetatable' (table expected)") end
        interp.metatables[t] = mt
        return t
    end

    G["getmetatable"] = function(t)
        if type(t) == "table" then
            mt = interp.metatables[t]
            if mt then
                mtmt = rawget(mt, "__metatable")
                if mtmt != null then return mtmt end
                return mt
            end
        end
        return null
    end

    G["pcall"] = function(f, ...)
        args = {...}
        ok, result = pcall(function()
            return callFunction(interp, f, args)
        end)
        if ok then
            if result and #result > 0 then
                ret = {true}
                for i = 1, #result do ret[#ret + 1] = result[i] end
                return unpack_(ret)
            end
            return true
        else
            return false, result
        end
    end

    G["ipairs"] = function(t)
        i = 0
        return function(tbl, idx)
            i = i + 1
            v = rawget(t, i)
            if v != null then
                return i, v
            end
            return null
        end, t, 0
    end

    G["pairs"] = function(t)
        -- We return next, t, null for generic for
        return G["next"], t, null
    end

    G["next"] = function(t, k)
        return next(t, k)
    end

    -- String library
    strLib = {}
    strLib.len = function(s) return slen(s) end
    strLib.sub = function(s, i, j) return ssub(s, i, j) end
    strLib.byte = function(s, i, j) return sbyte(s, i or 1, j or (i or 1)) end
    strLib.char = function(...) return schar(...) end
    strLib.rep = function(s, n) return srep(s, n) end
    strLib.reverse = function(s)
        t = {}
        for i = slen(s), 1, -1 do t[#t + 1] = ssub(s, i, i) end
        return tconcat(t)
    end
    strLib.lower = function(s) return slower(s) end
    strLib.upper = function(s) return supper(s) end
    strLib.find = function(s, pattern, init, plain)
        return sfind(s, pattern, init, plain)
    end
    strLib.format = function(fmt, ...)
        return sformat(fmt, ...)
    end
    strLib.gsub = function(s, pattern, repl, n)
        -- Simple plain-text replacement
        result = {}
        pos = 1
        count = 0
        patLen = slen(pattern)
        while pos <= slen(s) do
            if n and count >= n then
                tinsert(result, ssub(s, pos))
                pos = slen(s) + 1
                break
            end
            found = sfind(s, pattern, pos, true)
            if found then
                tinsert(result, ssub(s, pos, found - 1))
                if type(repl) == "string" then
                    tinsert(result, repl)
                else if type(repl) == "function" then
                    r = repl(ssub(s, found, found + patLen - 1))
                    tinsert(result, r or "")
                else
                    tinsert(result, tostring(repl))
                end
                count = count + 1
                pos = found + patLen
            else
                tinsert(result, ssub(s, pos))
                break
            end
        end
        return tconcat(result), count
    end
    G["string"] = strLib

    -- Table library
    tblLib = {}
    tblLib.insert = function(t, ...)
        args = {...}
        n = select("#", ...)
        if n == 1 then
            tinsert(t, args[1])
        else if n == 2 then
            tinsert(t, args[1], args[2])
        end
    end
    tblLib.remove = function(t, pos)
        return tremove(t, pos)
    end
    tblLib.sort = function(t, comp)
        if comp then
            tsort(t, function(a, b)
                r = callFunction(interp, comp, {a, b})
                if r and #r > 0 then return r[1] end
                return false
            end)
        else
            tsort(t)
        end
    end
    tblLib.concat = function(t, sep, i, j)
        return tconcat(t, sep, i, j)
    end
    tblLib.move = function(a, f, e, t2, dest)
        dest = dest or a
        return tmove(a, f, e, t2, dest)
    end
    tblLib.unpack = function(t, i, j)
        i = i or 1
        j = j or #t
        return unpack_(t, i, j)
    end
    G["table"] = tblLib

    -- Math library
    mathLib = {}
    mathLib.floor = floor
    mathLib.ceil = mceil
    mathLib.sqrt = msqrt
    mathLib.abs = mabs
    mathLib.sin = msin
    mathLib.cos = mcos
    mathLib.pi = mpi
    mathLib.huge = mhuge
    mathLib.max = mmax
    mathLib.min = mmin
    mathLib.log = mlog
    mathLib.exp = mexp
    mathLib.random = function(m, n)
        if m == null then return mrandom() end
        if n == null then return mrandom(m) end
        return mrandom(m, n)
    end
    G["math"] = mathLib
end

function interpToString(interp, val)
    if val == null then return "null" end
    if type(val) == "boolean" then
        if val then return "true" else return "false" end
    end
    if type(val) == "number" then
        if val == floor(val) and mabs(val) < 1e15 then
            return sformat("%d", val)
        end
        return tostring(val)
    end
    if type(val) == "string" then return val end
    if type(val) == "table" then
        if val._isClosure then return "function" end
        handler = getMetafield(interp, val, "__tostring")
        if handler then
            r = callFunction(interp, handler, {val})
            if r and #r > 0 then return tostring(r[1]) end
            return ""
        end
        return "table"
    end
    if type(val) == "function" then return "function" end
    return tostring(val)
end

-- ============================================================================
-- RUN PROGRAM
-- ============================================================================

function runProgram(source)
    interp = newInterp()
    setupStdlib(interp)
    ast = parseProgram(source)
    env = newEnv(null)
    execBlock(interp, ast, env)
    return interp.output
end

-- ============================================================================
-- TEST PROGRAMS
-- ============================================================================

TEST_PROGRAMS = {}

-- Test 1: Fibonacci (recursive + memoized)
TEST_PROGRAMS[1] = [[
local function fib(n)
    if n <= 1 then return n end
    return fib(n - 1) + fib(n - 2)
end

print(fib(0))
print(fib(1))
print(fib(5))
print(fib(10))

-- Memoized version
local memo = {}
local function fibMemo(n)
    if memo[n] then return memo[n] end
    if n <= 1 then
        memo[n] = n
        return n
    end
    memo[n] = fibMemo(n - 1) + fibMemo(n - 2)
    return memo[n]
end

print(fibMemo(20))
print(fibMemo(25))
print(fibMemo(30))
]]

-- Test 2: OOP with metatables
TEST_PROGRAMS[2] = [[
-- Base class
local Animal = {}
Animal.__index = Animal

function Animal.new(name, sound)
    local self = setmetatable({}, Animal)
    self.name = name
    self.sound = sound
    return self
end

function Animal:speak()
    return self.name .. " says " .. self.sound
end

function Animal:getName()
    return self.name
end

-- Derived class
local Dog = setmetatable({}, {__index = Animal})
Dog.__index = Dog

function Dog.new(name)
    local self = Animal.new(name, "Woof")
    return setmetatable(self, Dog)
end

function Dog:fetch(item)
    return self.name .. " fetches the " .. item
end

local a = Animal.new("Cat", "Meow")
print(a:speak())
print(a:getName())

local d = Dog.new("Rex")
print(d:speak())
print(d:fetch("ball"))
print(d:getName())

-- Test inheritance chain
local Puppy = setmetatable({}, {__index = Dog})
Puppy.__index = Puppy

function Puppy.new(name)
    local self = Dog.new(name)
    return setmetatable(self, Puppy)
end

function Puppy:play()
    return self.name .. " plays!"
end

local p = Puppy.new("Spot")
print(p:speak())
print(p:fetch("stick"))
print(p:play())
]]

-- Test 3: Quicksort
TEST_PROGRAMS[3] = [[
local function quicksort(arr, low, high)
    if low < high then
        local pivot = arr[high]
        local i = low - 1
        for j = low, high - 1 do
            if arr[j] <= pivot then
                i = i + 1
                arr[i], arr[j] = arr[j], arr[i]
            end
        end
        arr[i + 1], arr[high] = arr[high], arr[i + 1]
        local pi = i + 1
        quicksort(arr, low, pi - 1)
        quicksort(arr, pi + 1, high)
    end
end

local data = {38, 27, 43, 3, 9, 82, 10, 1, 57, 23, 15, 72, 4, 99, 41}
quicksort(data, 1, #data)

local result = ""
for i = 1, #data do
    if i > 1 then result = result .. "," end
    result = result .. tostring(data[i])
end
print(result)

-- Sort strings
local words = {"banana", "apple", "cherry", "date", "elderberry", "fig"}
table.sort(words)
local result2 = ""
for i = 1, #words do
    if i > 1 then result2 = result2 .. "," end
    result2 = result2 .. words[i]
end
print(result2)

-- Custom sort (descending)
local nums = {5, 2, 8, 1, 9, 3, 7, 4, 6}
table.sort(nums, function(a, b) return a > b end)
local result3 = ""
for i = 1, #nums do
    if i > 1 then result3 = result3 .. "," end
    result3 = result3 .. tostring(nums[i])
end
print(result3)
]]

-- Test 4: String manipulation
TEST_PROGRAMS[4] = [[
-- Split function
local function split(s, delim)
    local result = {}
    local pos = 1
    while true do
        local found = string.find(s, delim, pos, true)
        if not found then
            table.insert(result, string.sub(s, pos))
            break
        end
        table.insert(result, string.sub(s, pos, found - 1))
        pos = found + string.len(delim)
    end
    return result
end

-- Trim
local function trim(s)
    local start = 1
    local finish = string.len(s)
    while start <= finish do
        local ch = string.sub(s, start, start)
        if ch == " " or ch == "\t" or ch == "\n" then
            start = start + 1
        else
            break
        end
    end
    while finish >= start do
        local ch = string.sub(s, finish, finish)
        if ch == " " or ch == "\t" or ch == "\n" then
            finish = finish - 1
        else
            break
        end
    end
    return string.sub(s, start, finish)
end

-- Replace
local function replace(s, old, new)
    local result, count = string.gsub(s, old, new)
    return result
end

local parts = split("hello,world,foo,bar", ",")
for i = 1, #parts do
    print(parts[i])
end

print(trim("  hello world  "))
print(trim("\t\ttabs\t\t"))

print(replace("hello world hello", "hello", "hi"))

-- String reverse and case
print(string.reverse("abcdef"))
print(string.upper("hello"))
print(string.lower("WORLD"))

-- String repeat
print(string.rep("ab", 4))

-- String byte/char
print(string.byte("A"))
print(string.char(72, 101, 108, 108, 111))
]]

-- Test 5: Closure-based iterators
TEST_PROGRAMS[5] = [[
-- Range iterator
local function range(start, stop, step)
    step = step or 1
    local current = start - step
    return function()
        current = current + step
        if step > 0 then
            if current > stop then return null end
        else
            if current < stop then return null end
        end
        return current
    end
end

-- Filter
local function filter(iter, pred)
    return function()
        while true do
            local val = iter()
            if val == null then return null end
            if pred(val) then return val end
        end
    end
end

-- Map
local function map(iter, func)
    return function()
        local val = iter()
        if val == null then return null end
        return func(val)
    end
end

-- Collect to array
local function collect(iter)
    local result = {}
    while true do
        local val = iter()
        if val == null then break end
        table.insert(result, val)
    end
    return result
end

-- Test range
local r = collect(range(1, 10))
local s = ""
for i = 1, #r do
    if i > 1 then s = s .. "," end
    s = s .. tostring(r[i])
end
print(s)

-- Filter even numbers
local evens = collect(filter(range(1, 20), function(x) return x % 2 == 0 end))
s = ""
for i = 1, #evens do
    if i > 1 then s = s .. "," end
    s = s .. tostring(evens[i])
end
print(s)

-- Map: square
local squares = collect(map(range(1, 5), function(x) return x * x end))
s = ""
for i = 1, #squares do
    if i > 1 then s = s .. "," end
    s = s .. tostring(squares[i])
end
print(s)

-- Chain: filter then map
local result = collect(map(filter(range(1, 10), function(x) return x % 3 == 0 end), function(x) return x * 10 end))
s = ""
for i = 1, #result do
    if i > 1 then s = s .. "," end
    s = s .. tostring(result[i])
end
print(s)

-- Range with negative step
local down = collect(range(10, 1, -1))
s = ""
for i = 1, #down do
    if i > 1 then s = s .. "," end
    s = s .. tostring(down[i])
end
print(s)
]]

-- Test 6: Linked list with metamethods
TEST_PROGRAMS[6] = [[
local List = {}
List.__index = List

function List.new()
    local self = setmetatable({}, List)
    self.head = null
    self.size = 0
    return self
end

function List:push(val)
    self.head = {value = val, next = self.head}
    self.size = self.size + 1
end

function List:pop()
    if not self.head then return null end
    local val = self.head.value
    self.head = self.head.next
    self.size = self.size - 1
    return val
end

function List:toArray()
    local result = {}
    local node = self.head
    while node do
        table.insert(result, node.value)
        node = node.next
    end
    return result
end

List.__len = function(self)
    return self.size
end

List.__tostring = function(self)
    local arr = self:toArray()
    local parts = {}
    for i = 1, #arr do
        parts[i] = tostring(arr[i])
    end
    return "List[" .. table.concat(parts, ", ") .. "]"
end

List.__concat = function(a, b)
    local result = List.new()
    -- Add b's elements first (they'll be reversed)
    local arrB = b:toArray()
    for i = #arrB, 1, -1 do
        result:push(arrB[i])
    end
    -- Add a's elements
    local arrA = a:toArray()
    for i = #arrA, 1, -1 do
        result:push(arrA[i])
    end
    return result
end

local l = List.new()
l:push(1)
l:push(2)
l:push(3)
print(tostring(l))
print(#l)

local popped = l:pop()
print(popped)
print(tostring(l))

-- Test concat metamethod
local l2 = List.new()
l2:push(4)
l2:push(5)
local l3 = l .. l2
print(tostring(l3))
print(#l3)
]]

-- Test 7: Module pattern
TEST_PROGRAMS[7] = [[
-- Math utilities module
local MathUtils = {}

function MathUtils.factorial(n)
    if n <= 1 then return 1 end
    return n * MathUtils.factorial(n - 1)
end

function MathUtils.isPrime(n)
    if n < 2 then return false end
    if n == 2 then return true end
    if n % 2 == 0 then return false end
    local i = 3
    while i * i <= n do
        if n % i == 0 then return false end
        i = i + 2
    end
    return true
end

function MathUtils.gcd(a, b)
    while b ~= 0 do
        a, b = b, a % b
    end
    return a
end

-- String utilities module
local StringUtils = {}

function StringUtils.startsWith(s, prefix)
    return string.sub(s, 1, string.len(prefix)) == prefix
end

function StringUtils.endsWith(s, suffix)
    local sLen = string.len(s)
    local suffLen = string.len(suffix)
    if suffLen > sLen then return false end
    return string.sub(s, sLen - suffLen + 1) == suffix
end

function StringUtils.padLeft(s, width, ch)
    ch = ch or " "
    while string.len(s) < width do
        s = ch .. s
    end
    return s
end

-- Array utilities module
local ArrayUtils = {}

function ArrayUtils.sum(arr)
    local total = 0
    for i = 1, #arr do total = total + arr[i] end
    return total
end

function ArrayUtils.contains(arr, val)
    for i = 1, #arr do
        if arr[i] == val then return true end
    end
    return false
end

function ArrayUtils.reversed(arr)
    local result = {}
    for i = #arr, 1, -1 do
        table.insert(result, arr[i])
    end
    return result
end

-- Use the modules
print(MathUtils.factorial(5))
print(MathUtils.factorial(10))
print(tostring(MathUtils.isPrime(17)))
print(tostring(MathUtils.isPrime(15)))
print(MathUtils.gcd(48, 18))

print(tostring(StringUtils.startsWith("hello world", "hello")))
print(tostring(StringUtils.endsWith("hello world", "world")))
print(StringUtils.padLeft("42", 6, "0"))

local arr = {10, 20, 30, 40, 50}
print(ArrayUtils.sum(arr))
print(tostring(ArrayUtils.contains(arr, 30)))
print(tostring(ArrayUtils.contains(arr, 99)))
local rev = ArrayUtils.reversed(arr)
local s = ""
for i = 1, #rev do
    if i > 1 then s = s .. "," end
    s = s .. tostring(rev[i])
end
print(s)
]]

-- Test 8: Coroutine-like state machine using closures
TEST_PROGRAMS[8] = [[
-- State machine for a simple traffic light
local function trafficLight()
    local states = {"red", "green", "yellow"}
    local current = 1
    local count = 0

    return {
        next = function()
            count = count + 1
            current = current + 1
            if current > 3 then current = 1 end
        end,
        state = function()
            return states[current]
        end,
        count = function()
            return count
        end
    }
end

local light = trafficLight()
print(light.state())
light.next()
print(light.state())
light.next()
print(light.state())
light.next()
print(light.state())

-- Generator-like pattern using closures
local function counter(start, step)
    local val = start - step
    return function()
        val = val + step
        return val
    end
end

local c = counter(10, 5)
print(c())
print(c())
print(c())
print(c())

-- Accumulator
local function makeAccumulator(init)
    local total = init or 0
    return {
        add = function(n) total = total + n end,
        get = function() return total end,
        reset = function() total = 0 end
    }
end

local acc = makeAccumulator(0)
acc.add(10)
acc.add(20)
acc.add(30)
print(acc.get())
acc.add(-5)
print(acc.get())

-- Pipeline state machine
local function pipeline(...)
    local stages = {...}
    return function(input)
        local val = input
        for i = 1, #stages do
            val = stages[i](val)
        end
        return val
    end
end

local proc = pipeline(
    function(x) return x * 2 end,
    function(x) return x + 10 end,
    function(x) return x * x end
)
print(proc(3))
print(proc(5))
]]

-- Test 9: Numeric algorithms (matrix multiply, Newton's method)
TEST_PROGRAMS[9] = [[
-- Matrix multiplication
local function matNew(rows, cols, val)
    local m = {}
    for i = 1, rows do
        m[i] = {}
        for j = 1, cols do
            m[i][j] = val or 0
        end
    end
    m.rows = rows
    m.cols = cols
    return m
end

local function matMul(a, b)
    local result = matNew(a.rows, b.cols, 0)
    for i = 1, a.rows do
        for j = 1, b.cols do
            local sum = 0
            for k = 1, a.cols do
                sum = sum + a[i][k] * b[k][j]
            end
            result[i][j] = sum
        end
    end
    return result
end

local function matPrint(m)
    local lines = {}
    for i = 1, m.rows do
        local row = {}
        for j = 1, m.cols do
            table.insert(row, tostring(m[i][j]))
        end
        table.insert(lines, table.concat(row, " "))
    end
    print(table.concat(lines, "; "))
end

-- Test: 2x2 matrix multiply
local a = matNew(2, 2)
a[1][1] = 1; a[1][2] = 2
a[2][1] = 3; a[2][2] = 4

local b = matNew(2, 2)
b[1][1] = 5; b[1][2] = 6
b[2][1] = 7; b[2][2] = 8

local c = matMul(a, b)
matPrint(c)

-- 3x3 identity * matrix
local id = matNew(3, 3, 0)
id[1][1] = 1; id[2][2] = 1; id[3][3] = 1

local m = matNew(3, 3)
m[1][1] = 1; m[1][2] = 2; m[1][3] = 3
m[2][1] = 4; m[2][2] = 5; m[2][3] = 6
m[3][1] = 7; m[3][2] = 8; m[3][3] = 9

local r = matMul(id, m)
matPrint(r)

-- Newton's method for sqrt
local function newtonSqrt(n, tolerance)
    tolerance = tolerance or 0.0001
    local guess = n / 2
    for iter = 1, 100 do
        local newGuess = (guess + n / guess) / 2
        local diff = newGuess - guess
        if diff < 0 then diff = -diff end
        if diff < tolerance then
            return newGuess
        end
        guess = newGuess
    end
    return guess
end

-- Test Newton's sqrt
local sqrt2 = newtonSqrt(2)
local sqrt9 = newtonSqrt(9)
local sqrt100 = newtonSqrt(100)
-- Round to 4 decimal places
local function round4(x)
    return math.floor(x * 10000 + 0.5) / 10000
end
print(round4(sqrt2))
print(round4(sqrt9))
print(round4(sqrt100))

-- Newton's method for finding roots
-- f(x) = x^2 - 4, root at x=2
local function findRoot(f, df, x0, tol)
    tol = tol or 0.0001
    local x = x0
    for i = 1, 100 do
        local fx = f(x)
        local dfx = df(x)
        if dfx == 0 then break end
        local xNew = x - fx / dfx
        local diff = xNew - x
        if diff < 0 then diff = -diff end
        if diff < tol then return xNew end
        x = xNew
    end
    return x
end

local root = findRoot(
    function(x) return x * x - 4 end,
    function(x) return 2 * x end,
    3.0
)
print(round4(root))
]]

-- Test 10: Repeat/until, continue, break, varargs, pcall, multiple returns
TEST_PROGRAMS[10] = [[
-- repeat/until
local i = 0
local sum = 0
repeat
    i = i + 1
    sum = sum + i
until i >= 10
print(sum)

-- continue in for loop
local evens = {}
for x = 1, 20 do
    if x % 2 ~= 0 then continue end
    table.insert(evens, x)
end
local s = ""
for i = 1, #evens do
    if i > 1 then s = s .. "," end
    s = s .. tostring(evens[i])
end
print(s)

-- break in while
local found = -1
local j = 0
while j < 100 do
    j = j + 1
    if j * j > 50 then
        found = j
        break
    end
end
print(found)

-- varargs
local function vsum(...)
    local args = {...}
    local total = 0
    for i = 1, #args do
        total = total + args[i]
    end
    return total
end
print(vsum(1, 2, 3, 4, 5))
print(vsum(10, 20))

-- select with varargs
local function countArgs(...)
    return select("#", ...)
end
print(countArgs(1, 2, 3))
print(countArgs())

-- multiple returns
local function multiRet()
    return 10, 20, 30
end
local a, b, c = multiRet()
print(a)
print(b)
print(c)

-- multiple assignment discards extras
local x, y = multiRet()
print(x)
print(y)

-- pcall success
local ok, val = pcall(function() return 42 end)
print(tostring(ok))
print(val)

-- pcall failure
local ok2, err = pcall(function() error("oops") end)
print(tostring(ok2))

-- nested functions and closures
local function makeCounter()
    local n = 0
    return function()
        n = n + 1
        return n
    end
end
local c1 = makeCounter()
local c2 = makeCounter()
print(c1())
print(c1())
print(c2())
print(c1())
]]

-- Test 11: do/end blocks, numeric for step, complex table operations
TEST_PROGRAMS[11] = [[
-- do/end block scoping
local x = 10
do
    local x = 20
    print(x)
end
print(x)

-- numeric for with step
local s = ""
for i = 0, 20, 5 do
    if s ~= "" then s = s .. "," end
    s = s .. tostring(i)
end
print(s)

-- negative step
s = ""
for i = 10, 1, -2 do
    if s ~= "" then s = s .. "," end
    s = s .. tostring(i)
end
print(s)

-- table.remove and table.insert
local arr = {1, 2, 3, 4, 5}
table.remove(arr, 3)
local r1 = ""
for i = 1, #arr do
    if i > 1 then r1 = r1 .. "," end
    r1 = r1 .. tostring(arr[i])
end
print(r1)

table.insert(arr, 2, 99)
local r2 = ""
for i = 1, #arr do
    if i > 1 then r2 = r2 .. "," end
    r2 = r2 .. tostring(arr[i])
end
print(r2)

-- table.concat
local words = {"hello", "world", "from", "luau"}
print(table.concat(words, " "))

-- Nested tables
local grid = {}
for i = 1, 3 do
    grid[i] = {}
    for j = 1, 3 do
        grid[i][j] = i * 10 + j
    end
end
local gs = ""
for i = 1, 3 do
    for j = 1, 3 do
        if gs ~= "" then gs = gs .. "," end
        gs = gs .. tostring(grid[i][j])
    end
end
print(gs)

-- String format
print(string.format("%d + %d = %d", 3, 4, 7))
print(string.format("%s is %d", "age", 25))

-- Math operations
print(math.floor(3.7))
print(math.ceil(3.2))
print(math.abs(-42))
print(math.max(1, 5, 3, 2, 4))
print(math.min(10, 3, 7, 1, 8))
]]

-- ============================================================================
-- EXPECTED OUTPUTS
-- ============================================================================

EXPECTED_OUTPUTS = {}

EXPECTED_OUTPUTS[1] = {
    "0", "1", "5", "55", "6765", "75025", "832040"
}

EXPECTED_OUTPUTS[2] = {
    "Cat says Meow", "Cat", "Rex says Woof", "Rex fetches the ball", "Rex",
    "Spot says Woof", "Spot fetches the stick", "Spot plays!"
}

EXPECTED_OUTPUTS[3] = {
    "1,3,4,9,10,15,23,27,38,41,43,57,72,82,99",
    "apple,banana,cherry,date,elderberry,fig",
    "9,8,7,6,5,4,3,2,1"
}

EXPECTED_OUTPUTS[4] = {
    "hello", "world", "foo", "bar",
    "hello world", "tabs",
    "hi world hi",
    "fedcba", "HELLO", "world",
    "abababab",
    "65", "Hello"
}

EXPECTED_OUTPUTS[5] = {
    "1,2,3,4,5,6,7,8,9,10",
    "2,4,6,8,10,12,14,16,18,20",
    "1,4,9,16,25",
    "30,60,90",
    "10,9,8,7,6,5,4,3,2,1"
}

EXPECTED_OUTPUTS[6] = {
    "List[3, 2, 1]", "3", "3", "List[2, 1]",
    "List[2, 1, 5, 4]", "4"
}

EXPECTED_OUTPUTS[7] = {
    "120", "3628800", "true", "false", "6",
    "true", "true", "000042",
    "150", "true", "false",
    "50,40,30,20,10"
}

EXPECTED_OUTPUTS[8] = {
    "red", "green", "yellow", "red",
    "10", "15", "20", "25",
    "60", "55",
    "256", "400"
}

EXPECTED_OUTPUTS[9] = {
    "19 22; 43 50",
    "1 2 3; 4 5 6; 7 8 9",
    "1.4142", "3", "10",
    "2"
}

EXPECTED_OUTPUTS[10] = {
    "55",
    "2,4,6,8,10,12,14,16,18,20",
    "8",
    "15", "30",
    "3", "0",
    "10", "20", "30",
    "10", "20",
    "true", "42",
    "false",
    "1", "2", "1", "3"
}

EXPECTED_OUTPUTS[11] = {
    "20", "10",
    "0,5,10,15,20",
    "10,8,6,4,2",
    "1,2,4,5",
    "1,99,2,4,5",
    "hello world from luau",
    "11,12,13,21,22,23,31,32,33",
    "3 + 4 = 7",
    "age is 25",
    "3", "4", "42", "5", "1"
}

-- ============================================================================
-- CHECKSUM AND BENCHMARK HARNESS
-- ============================================================================

function computeChecksum(outputLines)
    hash = 5381
    for i = 1, #outputLines do
        line = outputLines[i]
        for j = 1, slen(line) do
            c = sbyte(line, j)
            hash = ((hash * 33) + c) % 4294967296
        end
        hash = ((hash * 33) + 10) % 4294967296 -- newline
    end
    return hash
end

function verifyOutputs()
    for idx = 1, #TEST_PROGRAMS do
        output = runProgram(TEST_PROGRAMS[idx])
        expected = EXPECTED_OUTPUTS[idx]
        if #output != #expected then
            error("Test " .. idx .. " output count mismatch: got " .. #output .. " expected " .. #expected)
        end
        for i = 1, #expected do
            if output[i] != expected[i] then
                error("Test " .. idx .. " line " .. i .. " mismatch: got '" .. tostring(output[i]) .. "' expected '" .. expected[i] .. "'")
            end
        end
    end
end

for i = 1, 10 do
    verifyOutputs()
end

end

bench.runCode(test, "luau_interp")
