# forward declarations (implicit-local dialect has no hoisted globals)
callFunction = null
evalAssign = null
evalBinary = null
evalBlock = null
evalCall = null
evalClassDecl = null
evalField = null
evalMethod = null
evalNode = null
evalUnary = null
lookupMethod = null
parseAddSub = null
parseAnd = null
parseArgs = null
parseClass = null
parseComparison = null
parseEquality = null
parseExpr = null
parseFor = null
parseIf = null
parseMulDiv = null
parseOr = null
parsePostfix = null
parsePrimary = null
parseStatement = null
parseUnary = null
parseWhile = null
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

function test()


# Zef language interpreter benchmark
# A complete interpreter for the Zef programming language.
# Compatible with: Luau (lute), Lua 5.1+, LuaJIT

clock = os.clock
floor = math.floor
concat = table.concat
sub = string.sub
byte = string.byte
char = string.char
find = string.find
format = string.format

# ============================================================================
# LEXER
# ============================================================================

# Token types
TK_NUMBER = 1
TK_STRING = 2
TK_IDENT = 3
TK_LPAREN = 4
TK_RPAREN = 5
TK_LBRACE = 6
TK_RBRACE = 7
TK_LBRACKET = 8
TK_RBRACKET = 9
TK_COMMA = 10
TK_SEMI = 11
TK_DOT = 12
TK_PLUS = 13
TK_MINUS = 14
TK_STAR = 15
TK_SLASH = 16
TK_PERCENT = 17
TK_GT = 18
TK_LT = 19
TK_GE = 20
TK_LE = 21
TK_EQ = 22
TK_NE = 23
TK_AND = 24
TK_OR = 25
TK_NOT = 26
TK_ASSIGN = 27
TK_COLON = 28
TK_EOF = 29

# Keywords
KW_MY = "my"
KW_FN = "fn"
KW_CLASS = "class"
KW_IF = "if"
KW_ELSE = "else"
KW_WHILE = "while"
KW_FOR = "for"
KW_BREAK = "break"
KW_RETURN = "return"
KW_NULL = "null"
KW_TRUE = "true"
KW_FALSE = "false"
KW_READABLE = "readable"
KW_PRINTLN = "println"

function isAlpha(c)
    return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95
end

function isDigit(c)
    return c >= 48 and c <= 57
end

function isAlnum(c)
    return isAlpha(c) or isDigit(c)
end

function tokenize(source)
    tokens = {}
    pos = 1
    len = source.count
    tcount = 0

    while pos <= len do
        c = byte(source, pos)

        # Skip whitespace
        if c == 32 or c == 9 or c == 10 or c == 13 then
            pos = pos + 1

        # Skip single-line comments
        else if c == 47 and pos < len and byte(source, pos + 1) == 47 then
            pos = pos + 2
            while pos <= len and byte(source, pos) != 10 do
                pos = pos + 1
            end

        # Numbers
        else if isDigit(c) then
            start = pos
            while pos <= len and isDigit(byte(source, pos)) do
                pos = pos + 1
            end
            if pos <= len and byte(source, pos) == 46 then
                pos = pos + 1
                while pos <= len and isDigit(byte(source, pos)) do
                    pos = pos + 1
                end
            end
            tcount = tcount + 1
            tokens[tcount] = {TK_NUMBER, tonumber(sub(source, start, pos - 1))}

        # Strings
        else if c == 34 then
            pos = pos + 1
            parts = {}
            pcount = 0
            while pos <= len and byte(source, pos) != 34 do
                ch = byte(source, pos)
                if ch == 92 then # backslash
                    pos = pos + 1
                    esc = byte(source, pos)
                    if esc == 110 then pcount = pcount + 1; parts[pcount] = "\n"
                    else if esc == 116 then pcount = pcount + 1; parts[pcount] = "\t"
                    else if esc == 34 then pcount = pcount + 1; parts[pcount] = "\""
                    else if esc == 92 then pcount = pcount + 1; parts[pcount] = "\\"
                    else pcount = pcount + 1; parts[pcount] = char(esc)
                    end
                else
                    pcount = pcount + 1
                    parts[pcount] = char(ch)
                end
                pos = pos + 1
            end
            pos = pos + 1 # skip closing quote
            tcount = tcount + 1
            tokens[tcount] = {TK_STRING, concat(parts)}

        # Identifiers and keywords
        else if isAlpha(c) then
            start = pos
            while pos <= len and isAlnum(byte(source, pos)) do
                pos = pos + 1
            end
            word = sub(source, start, pos - 1)
            tcount = tcount + 1
            tokens[tcount] = {TK_IDENT, word}

        # Two-character operators
        else if c == 62 and pos < len and byte(source, pos + 1) == 61 then
            tcount = tcount + 1; tokens[tcount] = {TK_GE}; pos = pos + 2
        else if c == 60 and pos < len and byte(source, pos + 1) == 61 then
            tcount = tcount + 1; tokens[tcount] = {TK_LE}; pos = pos + 2
        else if c == 61 and pos < len and byte(source, pos + 1) == 61 then
            tcount = tcount + 1; tokens[tcount] = {TK_EQ}; pos = pos + 2
        else if c == 33 and pos < len and byte(source, pos + 1) == 61 then
            tcount = tcount + 1; tokens[tcount] = {TK_NE}; pos = pos + 2
        else if c == 38 and pos < len and byte(source, pos + 1) == 38 then
            tcount = tcount + 1; tokens[tcount] = {TK_AND}; pos = pos + 2
        else if c == 124 and pos < len and byte(source, pos + 1) == 124 then
            tcount = tcount + 1; tokens[tcount] = {TK_OR}; pos = pos + 2

        # Single-character operators
        else if c == 40 then tcount = tcount + 1; tokens[tcount] = {TK_LPAREN}; pos = pos + 1
        else if c == 41 then tcount = tcount + 1; tokens[tcount] = {TK_RPAREN}; pos = pos + 1
        else if c == 123 then tcount = tcount + 1; tokens[tcount] = {TK_LBRACE}; pos = pos + 1
        else if c == 125 then tcount = tcount + 1; tokens[tcount] = {TK_RBRACE}; pos = pos + 1
        else if c == 91 then tcount = tcount + 1; tokens[tcount] = {TK_LBRACKET}; pos = pos + 1
        else if c == 93 then tcount = tcount + 1; tokens[tcount] = {TK_RBRACKET}; pos = pos + 1
        else if c == 44 then tcount = tcount + 1; tokens[tcount] = {TK_COMMA}; pos = pos + 1
        else if c == 59 then tcount = tcount + 1; tokens[tcount] = {TK_SEMI}; pos = pos + 1
        else if c == 46 then tcount = tcount + 1; tokens[tcount] = {TK_DOT}; pos = pos + 1
        else if c == 43 then tcount = tcount + 1; tokens[tcount] = {TK_PLUS}; pos = pos + 1
        else if c == 45 then tcount = tcount + 1; tokens[tcount] = {TK_MINUS}; pos = pos + 1
        else if c == 42 then tcount = tcount + 1; tokens[tcount] = {TK_STAR}; pos = pos + 1
        else if c == 47 then tcount = tcount + 1; tokens[tcount] = {TK_SLASH}; pos = pos + 1
        else if c == 37 then tcount = tcount + 1; tokens[tcount] = {TK_PERCENT}; pos = pos + 1
        else if c == 62 then tcount = tcount + 1; tokens[tcount] = {TK_GT}; pos = pos + 1
        else if c == 60 then tcount = tcount + 1; tokens[tcount] = {TK_LT}; pos = pos + 1
        else if c == 33 then tcount = tcount + 1; tokens[tcount] = {TK_NOT}; pos = pos + 1
        else if c == 61 then tcount = tcount + 1; tokens[tcount] = {TK_ASSIGN}; pos = pos + 1
        else if c == 58 then tcount = tcount + 1; tokens[tcount] = {TK_COLON}; pos = pos + 1
        else
            pos = pos + 1 # skip unknown
        end
    end

    tcount = tcount + 1
    tokens[tcount] = {TK_EOF}
    return tokens
end

# ============================================================================
# PARSER
# ============================================================================

# AST node types
ND_NUMBER = "num"
ND_STRING = "str"
ND_NULL = "null"
ND_BOOL = "bool"
ND_IDENT = "ident"
ND_BINARY = "binary"
ND_UNARY = "unary"
ND_ASSIGN = "assign"
ND_VARDECL = "vardecl"
ND_CALL = "call"
ND_INDEX = "index"
ND_FIELD = "field"
ND_METHOD = "method"
ND_ARRAY = "array"
ND_FUNC = "func"
ND_RETURN = "return"
ND_IF = "if"
ND_WHILE = "while"
ND_FOR = "for"
ND_BREAK = "break"
ND_BLOCK = "block"
ND_CLASS = "class"
ND_PRINTLN = "println"

function createParser(tokens)
    p = {}
    p.tokens = tokens
    p.pos = 1
    return p
end

function peek(p)
    return p.tokens[p.pos]
end

function peekType(p)
    return p.tokens[p.pos][1]
end

function advance(p)
    t = p.tokens[p.pos]
    p.pos = p.pos + 1
    return t
end

function expect(p, tktype)
    t = p.tokens[p.pos]
    if t[1] != tktype then
        error("Parser error: expected token type " .. tostring(tktype) .. " got " .. tostring(t[1]) .. " at pos " .. p.pos)
    end
    p.pos = p.pos + 1
    return t
end

function expectIdent(p, val)
    t = p.tokens[p.pos]
    if t[1] != TK_IDENT or t[2] != val then
        error("Parser error: expected '" .. val .. "' at pos " .. p.pos)
    end
    p.pos = p.pos + 1
    return t
end

function isIdent(p, val)
    t = p.tokens[p.pos]
    return t[1] == TK_IDENT and t[2] == val
end

function matchToken(p, tktype)
    if p.tokens[p.pos][1] == tktype then
        p.pos = p.pos + 1
        return true
    end
    return false
end

# Parse a parameter list: (a, b, c)
function parseParams(p)
    expect(p, TK_LPAREN)
    params = {}
    pc = 0
    if peekType(p) != TK_RPAREN then
        pc = pc + 1
        params[pc] = expect(p, TK_IDENT)[2]
        while matchToken(p, TK_COMMA) do
            pc = pc + 1
            params[pc] = expect(p, TK_IDENT)[2]
        end
    end
    expect(p, TK_RPAREN)
    return params
end

# Parse a block: { stmts }
function parseBlock(p)
    expect(p, TK_LBRACE)
    stmts = {}
    sc = 0
    while peekType(p) != TK_RBRACE and peekType(p) != TK_EOF do
        sc = sc + 1
        stmts[sc] = parseStatement(p)
    end
    expect(p, TK_RBRACE)
    return {ND_BLOCK, stmts}
end

# Parse function body: either { block } or single expression
function parseFuncBody(p)
    if peekType(p) == TK_LBRACE then
        return parseBlock(p)
    else
        # expression-bodied function
        expr = parseExpr(p)
        return {ND_BLOCK, {{ND_RETURN, expr}}}
    end
end

function parseStatement(p)
    tk = peek(p)

    # Variable declaration: my x = expr
    if tk[1] == TK_IDENT and tk[2] == KW_MY then
        advance(p)
        name = expect(p, TK_IDENT)[2]
        expect(p, TK_ASSIGN)
        val = parseExpr(p)
        matchToken(p, TK_SEMI)
        return {ND_VARDECL, name, val}

    # Function declaration: fn name(args) { body }
    else if tk[1] == TK_IDENT and tk[2] == KW_FN then
        advance(p)
        name = expect(p, TK_IDENT)[2]
        params = parseParams(p)
        body = parseFuncBody(p)
        matchToken(p, TK_SEMI)
        return {ND_VARDECL, name, {ND_FUNC, params, body, name}}

    # Class declaration
    else if tk[1] == TK_IDENT and tk[2] == KW_CLASS then
        return parseClass(p)

    # If statement
    else if tk[1] == TK_IDENT and tk[2] == KW_IF then
        return parseIf(p)

    # While statement
    else if tk[1] == TK_IDENT and tk[2] == KW_WHILE then
        return parseWhile(p)

    # For statement: for (init; cond; step) { body }
    else if tk[1] == TK_IDENT and tk[2] == KW_FOR then
        return parseFor(p)

    # Break statement
    else if tk[1] == TK_IDENT and tk[2] == KW_BREAK then
        advance(p)
        matchToken(p, TK_SEMI)
        return {ND_BREAK}

    # Return statement
    else if tk[1] == TK_IDENT and tk[2] == KW_RETURN then
        advance(p)
        val = null
        if peekType(p) != TK_SEMI and peekType(p) != TK_RBRACE and peekType(p) != TK_EOF then
            val = parseExpr(p)
        end
        matchToken(p, TK_SEMI)
        return {ND_RETURN, val}

    # println
    else if tk[1] == TK_IDENT and tk[2] == KW_PRINTLN then
        advance(p)
        expect(p, TK_LPAREN)
        val = parseExpr(p)
        expect(p, TK_RPAREN)
        matchToken(p, TK_SEMI)
        return {ND_PRINTLN, val}

    # Expression statement (assignment or call)
    else
        expr = parseExpr(p)
        # Check for assignment
        if peekType(p) == TK_ASSIGN then
            advance(p)
            val = parseExpr(p)
            matchToken(p, TK_SEMI)
            return {ND_ASSIGN, expr, val}
        end
        matchToken(p, TK_SEMI)
        return expr
    end
end

function parseClass(p)
    advance(p) # skip 'class'
    name = expect(p, TK_IDENT)[2]
    parent = null
    if matchToken(p, TK_COLON) then
        parent = expect(p, TK_IDENT)[2]
    end
    expect(p, TK_LBRACE)

    fields = {}
    fcount = 0
    methods = {}
    mcount = 0
    constructor = null

    while peekType(p) != TK_RBRACE and peekType(p) != TK_EOF do
        tk2 = peek(p)
        if tk2[1] == TK_IDENT and tk2[2] == KW_READABLE then
            advance(p)
            fname = expect(p, TK_IDENT)[2]
            matchToken(p, TK_SEMI)
            fcount = fcount + 1
            fields[fcount] = fname
        else if tk2[1] == TK_IDENT and tk2[2] == KW_FN then
            advance(p)
            # Check if it's a named method or constructor
            if peekType(p) == TK_LPAREN then
                # Constructor: fn(args) { body }
                params = parseParams(p)
                body = parseFuncBody(p)
                matchToken(p, TK_SEMI)
                constructor = {params, body}
            else
                # Named method: fn name(args) { body }
                mname = expect(p, TK_IDENT)[2]
                params = parseParams(p)
                body = parseFuncBody(p)
                matchToken(p, TK_SEMI)
                mcount = mcount + 1
                methods[mcount] = {mname, params, body}
            end
        else
            # skip unexpected
            advance(p)
        end
    end
    expect(p, TK_RBRACE)
    matchToken(p, TK_SEMI)
    return {ND_CLASS, name, parent, fields, methods, constructor}
end

function parseIf(p)
    advance(p) # skip 'if'
    expect(p, TK_LPAREN)
    cond = parseExpr(p)
    expect(p, TK_RPAREN)
    thenBlock = parseBlock(p)
    elseBlock = null
    if isIdent(p, KW_ELSE) then
        advance(p)
        if isIdent(p, KW_IF) then
            elseBlock = parseIf(p)
        else
            elseBlock = parseBlock(p)
        end
    end
    return {ND_IF, cond, thenBlock, elseBlock}
end

function parseWhile(p)
    advance(p) # skip 'while'
    expect(p, TK_LPAREN)
    cond = parseExpr(p)
    expect(p, TK_RPAREN)
    body = parseBlock(p)
    return {ND_WHILE, cond, body}
end

function parseFor(p)
    advance(p) # skip 'for'
    expect(p, TK_LPAREN)
    # init: my x = expr or expr
    init = null
    if isIdent(p, KW_MY) then
        advance(p)
        name = expect(p, TK_IDENT)[2]
        expect(p, TK_ASSIGN)
        val = parseExpr(p)
        init = {ND_VARDECL, name, val}
    else
        expr = parseExpr(p)
        if peekType(p) == TK_ASSIGN then
            advance(p)
            val = parseExpr(p)
            init = {ND_ASSIGN, expr, val}
        else
            init = expr
        end
    end
    expect(p, TK_SEMI)
    # condition
    cond = parseExpr(p)
    expect(p, TK_SEMI)
    # step: usually assignment
    stepExpr = parseExpr(p)
    step = null
    if peekType(p) == TK_ASSIGN then
        advance(p)
        val = parseExpr(p)
        step = {ND_ASSIGN, stepExpr, val}
    else
        step = stepExpr
    end
    expect(p, TK_RPAREN)
    body = parseBlock(p)
    return {ND_FOR, init, cond, step, body}
end

function parseExpr(p)
    return parseOr(p)
end

function parseOr(p)
    left = parseAnd(p)
    while peekType(p) == TK_OR do
        advance(p)
        right = parseAnd(p)
        left = {ND_BINARY, "||", left, right}
    end
    return left
end

function parseAnd(p)
    left = parseEquality(p)
    while peekType(p) == TK_AND do
        advance(p)
        right = parseEquality(p)
        left = {ND_BINARY, "&&", left, right}
    end
    return left
end

function parseEquality(p)
    left = parseComparison(p)
    while true do
        tt = peekType(p)
        if tt == TK_EQ then
            advance(p); left = {ND_BINARY, "==", left, parseComparison(p)}
        else if tt == TK_NE then
            advance(p); left = {ND_BINARY, "!=", left, parseComparison(p)}
        else
            break
        end
    end
    return left
end

function parseComparison(p)
    left = parseAddSub(p)
    while true do
        tt = peekType(p)
        if tt == TK_GT then
            advance(p); left = {ND_BINARY, ">", left, parseAddSub(p)}
        else if tt == TK_LT then
            advance(p); left = {ND_BINARY, "<", left, parseAddSub(p)}
        else if tt == TK_GE then
            advance(p); left = {ND_BINARY, ">=", left, parseAddSub(p)}
        else if tt == TK_LE then
            advance(p); left = {ND_BINARY, "<=", left, parseAddSub(p)}
        else
            break
        end
    end
    return left
end

function parseAddSub(p)
    left = parseMulDiv(p)
    while true do
        tt = peekType(p)
        if tt == TK_PLUS then
            advance(p); left = {ND_BINARY, "+", left, parseMulDiv(p)}
        else if tt == TK_MINUS then
            advance(p); left = {ND_BINARY, "-", left, parseMulDiv(p)}
        else
            break
        end
    end
    return left
end

function parseMulDiv(p)
    left = parseUnary(p)
    while true do
        tt = peekType(p)
        if tt == TK_STAR then
            advance(p); left = {ND_BINARY, "*", left, parseUnary(p)}
        else if tt == TK_SLASH then
            advance(p); left = {ND_BINARY, "/", left, parseUnary(p)}
        else if tt == TK_PERCENT then
            advance(p); left = {ND_BINARY, "%", left, parseUnary(p)}
        else
            break
        end
    end
    return left
end

function parseUnary(p)
    tt = peekType(p)
    if tt == TK_NOT then
        advance(p)
        operand = parseUnary(p)
        return {ND_UNARY, "!", operand}
    else if tt == TK_MINUS then
        advance(p)
        operand = parseUnary(p)
        return {ND_UNARY, "-", operand}
    end
    return parsePostfix(p)
end

function parsePostfix(p)
    expr = parsePrimary(p)
    while true do
        tt = peekType(p)
        if tt == TK_DOT then
            advance(p)
            field = expect(p, TK_IDENT)[2]
            # Check if it's a method call
            if peekType(p) == TK_LPAREN then
                args = parseArgs(p)
                expr = {ND_METHOD, expr, field, args}
            else
                expr = {ND_FIELD, expr, field}
            end
        else if tt == TK_LBRACKET then
            advance(p)
            idx = parseExpr(p)
            expect(p, TK_RBRACKET)
            expr = {ND_INDEX, expr, idx}
        else if tt == TK_LPAREN then
            args = parseArgs(p)
            expr = {ND_CALL, expr, args}
        else
            break
        end
    end
    return expr
end

function parseArgs(p)
    expect(p, TK_LPAREN)
    args = {}
    ac = 0
    if peekType(p) != TK_RPAREN then
        ac = ac + 1
        args[ac] = parseExpr(p)
        while matchToken(p, TK_COMMA) do
            ac = ac + 1
            args[ac] = parseExpr(p)
        end
    end
    expect(p, TK_RPAREN)
    return args
end

function parsePrimary(p)
    tk = peek(p)

    if tk[1] == TK_NUMBER then
        advance(p)
        return {ND_NUMBER, tk[2]}

    else if tk[1] == TK_STRING then
        advance(p)
        return {ND_STRING, tk[2]}

    else if tk[1] == TK_IDENT then
        val = tk[2]
        if val == KW_NULL then
            advance(p)
            return {ND_NULL}
        else if val == KW_TRUE then
            advance(p)
            return {ND_BOOL, true}
        else if val == KW_FALSE then
            advance(p)
            return {ND_BOOL, false}
        else if val == KW_FN then
            advance(p)
            # Lambda: fn(args) { body } or fn(args) expr
            params = parseParams(p)
            body = parseFuncBody(p)
            return {ND_FUNC, params, body, null}
        else
            advance(p)
            return {ND_IDENT, val}
        end

    else if tk[1] == TK_LPAREN then
        advance(p)
        expr = parseExpr(p)
        expect(p, TK_RPAREN)
        return expr

    else if tk[1] == TK_LBRACKET then
        advance(p)
        elems = {}
        ec = 0
        if peekType(p) != TK_RBRACKET then
            ec = ec + 1
            elems[ec] = parseExpr(p)
            while matchToken(p, TK_COMMA) do
                ec = ec + 1
                elems[ec] = parseExpr(p)
            end
        end
        expect(p, TK_RBRACKET)
        return {ND_ARRAY, elems}

    else
        error("Parser error: unexpected token type " .. tostring(tk[1]) .. " val=" .. tostring(tk[2]) .. " at pos " .. p.pos)
    end
end

function parseProgram(p)
    stmts = {}
    sc = 0
    while peekType(p) != TK_EOF do
        sc = sc + 1
        stmts[sc] = parseStatement(p)
    end
    return {ND_BLOCK, stmts}
end

# ============================================================================
# EVALUATOR
# ============================================================================

# Sentinels for return and break
RETURN_SENTINEL = {}
BREAK_SENTINEL = {}

# Output buffer
OutputBuffer = {}
OutputCount = 0

function resetOutput()
    OutputBuffer = {}
    OutputCount = 0
end

function getOutput()
    return concat(OutputBuffer, "\n")
end

function appendOutput(s)
    OutputCount = OutputCount + 1
    OutputBuffer[OutputCount] = s
end

# Environment
function newEnv(parent)
    return {vars = {}, parent = parent}
end

function envGet(env, name)
    e = env
    while e do
        v = e.vars[name]
        if v != null then
            return v
        end
        e = e.parent
    end
    return null
end

function envSet(env, name, val)
    e = env
    while e do
        if e.vars[name] != null then
            e.vars[name] = val
            return
        end
        e = e.parent
    end
    error("Undefined variable: " .. tostring(name))
end

function envDeclare(env, name, val)
    env.vars[name] = val
end

# Value helpers
function isTruthy(val)
    if val == null or val == 0 or val == false then return false end
    if val == true then return true end
    if type(val) == "number" then return val != 0 end
    return true
end

function toZefString(val)
    if val == null then return "null" end
    if type(val) == "boolean" then
        if val then return "true" else return "false" end
    end
    if type(val) == "number" then
        if val == floor(val) then
            return format("%d", val)
        end
        return tostring(val)
    end
    if type(val) == "string" then return val end
    if type(val) == "table" then
        if val._isArray then
            parts = {}
            for i = 1, val._size do
                parts[i] = toZefString(val._data[i])
            end
            return "[" .. concat(parts, ", ") .. "]"
        end
        if val._isInstance then
            cls = val._class
            # Check for toString method
            toStr = lookupMethod(val, "toString")
            if toStr then
                return callFunction(toStr, {val}, null)
            end
            return "<" .. (cls._name or "object") .. ">"
        end
        if val._isFunc then
            return "<fn>"
        end
        return "<table>"
    end
    return tostring(val)
end

function makeArray(elems)
    arr = {_isArray = true, _data = {}, _size = 0}
    if elems then
        for i = 1, elems.count do
            arr._data[i] = elems[i]
            arr._size = i
        end
    end
    return arr
end

function arrayPush(arr, val)
    arr._size = arr._size + 1
    arr._data[arr._size] = val
end

function arrayGet(arr, idx)
    # 0-based indexing for Zef
    return arr._data[idx + 1]
end

function arraySet(arr, idx, val)
    arr._data[idx + 1] = val
end

# Class / instance helpers
function makeClass(name, parent, fields, methods, constructor)
    cls = {
        _isClass = true,
        _name = name,
        _parent = parent,
        _fields = fields,
        _methods = methods,
        _constructor = constructor,
    }
    return cls
end

function makeInstance(cls)
    inst = {_isInstance = true, _class = cls, _fields = {}}
    return inst
end

function lookupMethod(inst, methodName)
    cls = inst._class
    while cls do
        meths = cls._methods
        if meths[methodName] then
            return meths[methodName]
        end
        cls = cls._parent
    end
    return null
end

function lookupField(inst, fieldName)
    return inst._fields[fieldName]
end

# Function value
function makeFunc(params, body, closure, name)
    return {_isFunc = true, _params = params, _body = body, _closure = closure, _name = name}
end

# Call a function value
function callFunction(func, args, thisObj)
    env = newEnv(func._closure)
    params = func._params
    for i = 1, params.count do
        envDeclare(env, params[i], args[i])
    end
    if thisObj then
        envDeclare(env, "this", thisObj)
    end
    result = evalNode(func._body, env)
    if type(result) == "table" and result[1] == RETURN_SENTINEL then
        return result[2]
    end
    return null
end

# Main eval
function evalNode(node, env)
    ntype = node[1]

    if ntype == ND_NUMBER then
        return node[2]

    else if ntype == ND_STRING then
        return node[2]

    else if ntype == ND_NULL then
        return 0

    else if ntype == ND_BOOL then
        if node[2] then return 1 else return 0 end

    else if ntype == ND_IDENT then
        val = envGet(env, node[2])
        if val == null then return 0 end
        return val

    else if ntype == ND_ARRAY then
        elems = node[2]
        vals = {}
        for i = 1, elems.count do
            vals[i] = evalNode(elems[i], env)
        end
        return makeArray(vals)

    else if ntype == ND_FUNC then
        return makeFunc(node[2], node[3], env, node[4])

    else if ntype == ND_BINARY then
        return evalBinary(node, env)

    else if ntype == ND_UNARY then
        return evalUnary(node, env)

    else if ntype == ND_CALL then
        return evalCall(node, env)

    else if ntype == ND_METHOD then
        return evalMethod(node, env)

    else if ntype == ND_FIELD then
        return evalField(node, env)

    else if ntype == ND_INDEX then
        obj = evalNode(node[2], env)
        idx = evalNode(node[3], env)
        if type(obj) == "table" and obj._isArray then
            return arrayGet(obj, idx)
        end
        return 0

    else if ntype == ND_VARDECL then
        val = evalNode(node[3], env)
        envDeclare(env, node[2], val)
        return null

    else if ntype == ND_ASSIGN then
        return evalAssign(node, env)

    else if ntype == ND_BLOCK then
        return evalBlock(node, env)

    else if ntype == ND_IF then
        cond = evalNode(node[2], env)
        if isTruthy(cond) then
            result = evalNode(node[3], env)
            if type(result) == "table" then
                if result[1] == RETURN_SENTINEL or result[1] == BREAK_SENTINEL then
                    return result
                end
            end
        else if node[4] then
            result = evalNode(node[4], env)
            if type(result) == "table" then
                if result[1] == RETURN_SENTINEL or result[1] == BREAK_SENTINEL then
                    return result
                end
            end
        end
        return null

    else if ntype == ND_WHILE then
        while true do
            cond = evalNode(node[2], env)
            if not isTruthy(cond) then break end
            result = evalNode(node[3], env)
            if type(result) == "table" then
                if result[1] == RETURN_SENTINEL then return result end
                if result[1] == BREAK_SENTINEL then break end
            end
        end
        return null

    else if ntype == ND_FOR then
        # for (init; cond; step) { body }
        forEnv = newEnv(env)
        evalNode(node[2], forEnv) # init
        while true do
            cond = evalNode(node[3], forEnv)
            if not isTruthy(cond) then break end
            result = evalNode(node[5], forEnv)
            if type(result) == "table" then
                if result[1] == RETURN_SENTINEL then return result end
                if result[1] == BREAK_SENTINEL then break end
            end
            evalNode(node[4], forEnv) # step
        end
        return null

    else if ntype == ND_BREAK then
        return {BREAK_SENTINEL}

    else if ntype == ND_RETURN then
        val = null
        if node[2] then
            val = evalNode(node[2], env)
        end
        return {RETURN_SENTINEL, val}

    else if ntype == ND_CLASS then
        return evalClassDecl(node, env)

    else if ntype == ND_PRINTLN then
        val = evalNode(node[2], env)
        appendOutput(toZefString(val))
        return null

    else
        return null
    end
end

function evalBlock(node, env)
    stmts = node[2]
    for i = 1, stmts.count do
        result = evalNode(stmts[i], env)
        if type(result) == "table" then
            if result[1] == RETURN_SENTINEL or result[1] == BREAK_SENTINEL then
                return result
            end
        end
    end
    return null
end

function evalBinary(node, env)
    op = node[2]

    # Short-circuit for && and ||
    if op == "&&" then
        left = evalNode(node[3], env)
        if not isTruthy(left) then return 0 end
        right = evalNode(node[4], env)
        if isTruthy(right) then return 1 else return 0 end
    else if op == "||" then
        left = evalNode(node[3], env)
        if isTruthy(left) then return 1 end
        right = evalNode(node[4], env)
        if isTruthy(right) then return 1 else return 0 end
    end

    left = evalNode(node[3], env)
    right = evalNode(node[4], env)

    # Operator overloading for objects
    if type(left) == "table" and left._isInstance then
        methodName = null
        if op == "+" then methodName = "add"
        else if op == "-" then methodName = "sub"
        else if op == "*" then methodName = "mul"
        else if op == "/" then methodName = "div"
        end
        if methodName then
            m = lookupMethod(left, methodName)
            if m then
                return callFunction(m, {left, right}, left)
            end
        end
    end

    # String concatenation with +
    if op == "+" and (type(left) == "string" or type(right) == "string") then
        return toZefString(left) .. toZefString(right)
    end

    if op == "+" then return left + right
    else if op == "-" then return left - right
    else if op == "*" then return left * right
    else if op == "/" then
        if right == 0 then return 0 end
        return left / right
    else if op == "%" then return left % right
    else if op == ">" then return (left > right) and 1 or 0
    else if op == "<" then return (left < right) and 1 or 0
    else if op == ">=" then return (left >= right) and 1 or 0
    else if op == "<=" then return (left <= right) and 1 or 0
    else if op == "==" then
        if left == right then return 1 else return 0 end
    else if op == "!=" then
        if left != right then return 1 else return 0 end
    end
    return 0
end

function evalUnary(node, env)
    op = node[2]
    val = evalNode(node[3], env)
    if op == "!" then
        return isTruthy(val) and 0 or 1
    else if op == "-" then
        return -val
    end
    return 0
end

function evalCall(node, env)
    callee = evalNode(node[2], env)
    argNodes = node[3]
    args = {}
    for i = 1, argNodes.count do
        args[i] = evalNode(argNodes[i], env)
    end

    if type(callee) == "table" then
        if callee._isFunc then
            return callFunction(callee, args, null)
        else if callee._isClass then
            # Instantiate
            inst = makeInstance(callee)
            # Initialize fields
            cls = callee
            while cls do
                fields = cls._fields
                for i = 1, fields.count do
                    if inst._fields[fields[i]] == null then
                        inst._fields[fields[i]] = 0
                    end
                end
                cls = cls._parent
            end
            # Call constructor
            if callee._constructor then
                ctor = callee._constructor
                cenv = newEnv(ctor._closure)
                cparams = ctor._params
                for i = 1, cparams.count do
                    envDeclare(cenv, cparams[i], args[i])
                end
                envDeclare(cenv, "this", inst)
                result = evalNode(ctor._body, cenv)
                # ignore return from constructor
            end
            return inst
        end
    end
    return 0
end

function evalMethod(node, env)
    obj = evalNode(node[2], env)
    methodName = node[3]
    argNodes = node[4]
    args = {}
    for i = 1, argNodes.count do
        args[i] = evalNode(argNodes[i], env)
    end

    # Array methods
    if type(obj) == "table" and obj._isArray then
        if methodName == "push" then
            arrayPush(obj, args[1])
            return null
        else if methodName == "size" then
            return obj._size
        else if methodName == "get" then
            return arrayGet(obj, args[1])
        else if methodName == "set" then
            arraySet(obj, args[1], args[2])
            return null
        end
    end

    # String methods
    if type(obj) == "string" then
        if methodName == "size" then
            return obj.count
        else if methodName == "toString" then
            return obj
        else if methodName == "charAt" then
            idx = args[1]
            return sub(obj, idx + 1, idx + 1)
        end
    end

    # Number methods
    if type(obj) == "number" then
        if methodName == "toString" then
            return toZefString(obj)
        end
    end

    # Instance methods
    if type(obj) == "table" and obj._isInstance then
        m = lookupMethod(obj, methodName)
        if m then
            # Prepend 'this' = obj
            return callFunction(m, {obj, unpack(args)}, obj)
        end
    end

    return 0
end

function evalField(node, env)
    obj = evalNode(node[2], env)
    field = node[3]

    # Array fields
    if type(obj) == "table" and obj._isArray then
        if field == "size" then
            return obj._size
        end
    end

    # String fields
    if type(obj) == "string" then
        if field == "size" then
            return obj.count
        end
    end

    # Instance fields
    if type(obj) == "table" and obj._isInstance then
        val = obj._fields[field]
        if val != null then
            return val
        end
        # Check if it's a method (return bound method)
        m = lookupMethod(obj, field)
        if m then
            # Return a bound method
            bound = makeFunc(m._params, m._body, m._closure, m._name)
            # We'll handle 'this' binding at call site
            bound._boundThis = obj
            return bound
        end
        return 0
    end

    return 0
end

function evalAssign(node, env)
    target = node[2]
    val = evalNode(node[3], env)

    if target[1] == ND_IDENT then
        envSet(env, target[2], val)
    else if target[1] == ND_FIELD then
        obj = evalNode(target[2], env)
        if type(obj) == "table" and obj._isInstance then
            obj._fields[target[3]] = val
        end
    else if target[1] == ND_INDEX then
        obj = evalNode(target[2], env)
        idx = evalNode(target[3], env)
        if type(obj) == "table" and obj._isArray then
            arraySet(obj, idx, val)
        end
    end
    return null
end

function evalClassDecl(node, env)
    name = node[2]
    parentName = node[3]
    fieldNames = node[4]
    methodDefs = node[5]
    ctorDef = node[6]

    parentCls = null
    if parentName then
        parentCls = envGet(env, parentName)
    end

    methods = {}
    for i = 1, methodDefs.count do
        mdef = methodDefs[i]
        mname = mdef[1]
        mparams = mdef[2]
        mbody = mdef[3]
        # Method params include 'this' as first implicit param
        fullParams = {"this"}
        for j = 1, mparams.count do
            fullParams[j + 1] = mparams[j]
        end
        methods[mname] = makeFunc(fullParams, mbody, env, mname)
    end

    constructor = null
    if ctorDef then
        constructor = makeFunc(ctorDef[1], ctorDef[2], env, name)
    end

    cls = makeClass(name, parentCls, fieldNames, methods, constructor)
    envDeclare(env, name, cls)
    return null
end

# ============================================================================
# RUN HELPER
# ============================================================================

function runProgram(source)
    tokens = tokenize(source)
    parser = createParser(tokens)
    ast = parseProgram(parser)
    env = newEnv(null)
    resetOutput()
    evalNode(ast, env)
    return getOutput()
end

# ============================================================================
# TEST PROGRAMS
# ============================================================================

# Program 1: Linked List
PROG_LINKED_LIST = [[
class Node {
    readable val;
    readable nxt;
    fn(v, n) {
        this.val = v;
        this.nxt = n;
    }
}

fn makeList(n) {
    my head = null;
    my i = 0;
    while (i < n) {
        head = Node(i, head);
        i = i + 1;
    }
    return head;
}

fn sumList(node) {
    my total = 0;
    my curr = node;
    while (curr != 0) {
        total = total + curr.val;
        curr = curr.nxt;
    }
    return total;
}

fn reverseList(node) {
    my prev = null;
    my curr = node;
    while (curr != 0) {
        my nxt = curr.nxt;
        curr.nxt = prev;
        prev = curr;
        curr = nxt;
    }
    return prev;
}

fn listToString(node) {
    my result = "";
    my curr = node;
    my first = 1;
    while (curr != 0) {
        if (first) {
            result = result + curr.val.toString();
            first = 0;
        } else {
            result = result + "," + curr.val.toString();
        }
        curr = curr.nxt;
    }
    return result;
}

my list = makeList(10);
println(sumList(list));
my rev = reverseList(list);
println(listToString(rev));
println(sumList(rev));

my list2 = makeList(20);
println(sumList(list2));
]]

EXPECTED_LINKED_LIST = "45\n0,1,2,3,4,5,6,7,8,9\n45\n190"

# Program 2: Binary Tree
PROG_BINARY_TREE = [[
class TreeNode {
    readable val;
    readable left;
    readable right;
    fn(v) {
        this.val = v;
        this.left = null;
        this.right = null;
    }
}

fn insert(root, v) {
    if (root == 0) {
        return TreeNode(v);
    }
    if (v < root.val) {
        root.left = insert(root.left, v);
    } else {
        root.right = insert(root.right, v);
    }
    return root;
}

fn inorder(node) {
    if (node == 0) {
        return "";
    }
    my left = inorder(node.left);
    my mid = node.val.toString();
    my right = inorder(node.right);
    my result = "";
    if (left != "") {
        result = left + "," + mid;
    } else {
        result = mid;
    }
    if (right != "") {
        result = result + "," + right;
    }
    return result;
}

fn treeDepth(node) {
    if (node == 0) {
        return 0;
    }
    my ld = treeDepth(node.left);
    my rd = treeDepth(node.right);
    if (ld > rd) {
        return ld + 1;
    }
    return rd + 1;
}

fn treeSum(node) {
    if (node == 0) {
        return 0;
    }
    return node.val + treeSum(node.left) + treeSum(node.right);
}

my root = null;
my vals = [5, 3, 8, 1, 4, 7, 9, 2, 6, 0];
my i = 0;
while (i < vals.size) {
    root = insert(root, vals[i]);
    i = i + 1;
}

println(inorder(root));
println(treeDepth(root));
println(treeSum(root));
]]

EXPECTED_BINARY_TREE = "0,1,2,3,4,5,6,7,8,9\n4\n45"

# Program 3: Shapes with inheritance
PROG_SHAPES = [[
class Shape {
    readable name;
    fn() {
        this.name = "shape";
    }
    fn area() {
        return 0;
    }
    fn describe() {
        return this.name + ": area=" + this.area().toString();
    }
}

class Circle : Shape {
    readable radius;
    fn(r) {
        this.name = "circle";
        this.radius = r;
    }
    fn area() {
        return 3 * this.radius * this.radius;
    }
}

class Rectangle : Shape {
    readable width;
    readable height;
    fn(w, h) {
        this.name = "rectangle";
        this.width = w;
        this.height = h;
    }
    fn area() {
        return this.width * this.height;
    }
}

class Square : Rectangle {
    fn(s) {
        this.name = "square";
        this.width = s;
        this.height = s;
    }
}

my shapes = [Circle(5), Rectangle(3, 4), Square(6), Circle(2)];
my totalArea = 0;
my i = 0;
while (i < shapes.size) {
    my s = shapes[i];
    println(s.describe());
    totalArea = totalArea + s.area();
    i = i + 1;
}
println(totalArea);

// Test operator overloading
class Vec {
    readable x;
    readable y;
    fn(x, y) {
        this.x = x;
        this.y = y;
    }
    fn add(other) {
        return Vec(this.x + other.x, this.y + other.y);
    }
    fn toString() {
        return "(" + this.x.toString() + "," + this.y.toString() + ")";
    }
}

my v1 = Vec(1, 2);
my v2 = Vec(3, 4);
my v3 = v1 + v2;
println(v3.toString());
]]

EXPECTED_SHAPES = "circle: area=75\nrectangle: area=12\nsquare: area=36\ncircle: area=12\n135\n(4,6)"

# Program 4: Closures and HOF
PROG_CLOSURES = [[
fn makeCounter(start) {
    my count = start;
    fn inc() {
        count = count + 1;
        return count;
    }
    fn get() {
        return count;
    }
    fn reset() {
        count = start;
    }
    return [fn() { count = count + 1; return count; }, fn() { return count; }, fn() { count = start; }];
}

my counter = makeCounter(0);
my inc = counter[0];
my get = counter[1];
my reset = counter[2];

println(inc());
println(inc());
println(inc());
println(get());
reset();
println(get());

fn map(arr, f) {
    my result = [];
    my i = 0;
    while (i < arr.size) {
        result.push(f(arr[i]));
        i = i + 1;
    }
    return result;
}

fn filter(arr, pred) {
    my result = [];
    my i = 0;
    while (i < arr.size) {
        if (pred(arr[i])) {
            result.push(arr[i]);
        }
        i = i + 1;
    }
    return result;
}

fn reduce(arr, init, f) {
    my acc = init;
    my i = 0;
    while (i < arr.size) {
        acc = f(acc, arr[i]);
        i = i + 1;
    }
    return acc;
}

my nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

my doubled = map(nums, fn(x) x * 2);
println(reduce(doubled, 0, fn(a, b) a + b));

my evens = filter(nums, fn(x) x % 2 == 0);
println(reduce(evens, 0, fn(a, b) a + b));

// Compose functions
fn compose(f, g) {
    return fn(x) { return f(g(x)); };
}

my addOne = fn(x) x + 1;
my double = fn(x) x * 2;
my doubleAddOne = compose(addOne, double);
println(doubleAddOne(5));

// Currying
fn adder(a) {
    return fn(b) a + b;
}
my add5 = adder(5);
println(add5(10));
println(add5(20));
]]

EXPECTED_CLOSURES = "1\n2\n3\n3\n0\n110\n30\n11\n15\n25"

# Program 5: Sorting
PROG_SORTING = [[
fn swap(arr, i, j) {
    my tmp = arr[i];
    arr[i] = arr[j];
    arr[j] = tmp;
}

fn bubbleSort(arr) {
    my n = arr.size;
    my i = 0;
    while (i < n) {
        my j = 0;
        while (j < n - i - 1) {
            if (arr[j] > arr[j + 1]) {
                swap(arr, j, j + 1);
            }
            j = j + 1;
        }
        i = i + 1;
    }
    return arr;
}

fn quickSort(arr, lo, hi) {
    if (lo < hi) {
        my pivot = arr[hi];
        my i = lo - 1;
        my j = lo;
        while (j < hi) {
            if (arr[j] <= pivot) {
                i = i + 1;
                swap(arr, i, j);
            }
            j = j + 1;
        }
        i = i + 1;
        swap(arr, i, hi);
        quickSort(arr, lo, i - 1);
        quickSort(arr, i + 1, hi);
    }
}

fn arrToString(arr) {
    my result = "";
    my i = 0;
    while (i < arr.size) {
        if (i > 0) {
            result = result + ",";
        }
        result = result + arr[i].toString();
        i = i + 1;
    }
    return result;
}

// Test bubble sort
my a1 = [9, 3, 7, 1, 5, 8, 2, 6, 4, 0];
bubbleSort(a1);
println(arrToString(a1));

// Test quicksort
my a2 = [15, 3, 12, 7, 19, 1, 8, 14, 5, 11, 2, 17, 6, 13, 4, 10, 9, 16, 18, 0];
quickSort(a2, 0, a2.size - 1);
println(arrToString(a2));

// Sum sorted arrays
fn sumArr(arr) {
    my total = 0;
    my i = 0;
    while (i < arr.size) {
        total = total + arr[i];
        i = i + 1;
    }
    return total;
}

println(sumArr(a1));
println(sumArr(a2));

// Insertion sort
fn insertionSort(arr) {
    my i = 1;
    while (i < arr.size) {
        my key = arr[i];
        my j = i - 1;
        while (j >= 0 && arr[j] > key) {
            arr[j + 1] = arr[j];
            j = j - 1;
        }
        arr[j + 1] = key;
        i = i + 1;
    }
    return arr;
}

my a3 = [20, 18, 16, 14, 12, 10, 8, 6, 4, 2, 19, 17, 15, 13, 11, 9, 7, 5, 3, 1];
insertionSort(a3);
println(arrToString(a3));
println(sumArr(a3));
]]

EXPECTED_SORTING = "0,1,2,3,4,5,6,7,8,9\n0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19\n45\n190\n1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20\n210"

# Program 6: Fibonacci, memoization, iterators, for loops, break
PROG_ADVANCED = [[
// Recursive fibonacci
fn fib(n) {
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

println(fib(0));
println(fib(1));
println(fib(5));
println(fib(10));

// Memoized fibonacci using array
fn makeFibMemo() {
    my cache = [0, 1];
    return fn(n) {
        // Fill cache up to n
        my i = cache.size;
        while (i <= n) {
            my val = cache[i - 1] + cache[i - 2];
            cache.push(val);
            i = i + 1;
        }
        return cache[n];
    };
}

my fibMemo = makeFibMemo();
println(fibMemo(20));
println(fibMemo(25));
println(fibMemo(30));

// For loop with break - find first prime > 50
fn isPrime(n) {
    if (n < 2) { return 0; }
    if (n == 2) { return 1; }
    if (n % 2 == 0) { return 0; }
    my i = 3;
    while (i * i <= n) {
        if (n % i == 0) {
            return 0;
        }
        i = i + 2;
    }
    return 1;
}

// Find primes using for loop
my primeCount = 0;
my primeSum = 0;
for (my i = 2; i < 100; i = i + 1) {
    if (isPrime(i)) {
        primeCount = primeCount + 1;
        primeSum = primeSum + i;
    }
}
println(primeCount);
println(primeSum);

// For loop with break
my firstPrimeOver50 = 0;
for (my i = 51; i < 100; i = i + 1) {
    if (isPrime(i)) {
        firstPrimeOver50 = i;
        break;
    }
}
println(firstPrimeOver50);

// Iterator pattern with closures
fn range(start, stop, step) {
    my current = start;
    return fn() {
        if (current >= stop) {
            return null;
        }
        my val = current;
        current = current + step;
        return val;
    };
}

my iter = range(1, 11, 2);
my total = 0;
my val = iter();
while (val != 0) {
    total = total + val;
    val = iter();
}
// 1+3+5+7+9 = 25
println(total);

// Matrix multiplication (2D arrays via array of arrays)
fn makeMatrix(rows, cols, val) {
    my m = [];
    for (my i = 0; i < rows; i = i + 1) {
        my row = [];
        for (my j = 0; j < cols; j = j + 1) {
            row.push(val);
        }
        m.push(row);
    }
    return m;
}

fn matMul(a, b, n) {
    my c = makeMatrix(n, n, 0);
    for (my i = 0; i < n; i = i + 1) {
        for (my j = 0; j < n; j = j + 1) {
            my sum = 0;
            for (my k = 0; k < n; k = k + 1) {
                sum = sum + a[i][k] * b[k][j];
            }
            c[i][j] = sum;
        }
    }
    return c;
}

// Create identity-like matrix
my m1 = makeMatrix(3, 3, 0);
m1[0][0] = 1; m1[0][1] = 2; m1[0][2] = 3;
m1[1][0] = 4; m1[1][1] = 5; m1[1][2] = 6;
m1[2][0] = 7; m1[2][1] = 8; m1[2][2] = 9;

my m2 = makeMatrix(3, 3, 0);
m2[0][0] = 9; m2[0][1] = 8; m2[0][2] = 7;
m2[1][0] = 6; m2[1][1] = 5; m2[1][2] = 4;
m2[2][0] = 3; m2[2][1] = 2; m2[2][2] = 1;

my result = matMul(m1, m2, 3);
println(result[0][0]);
println(result[1][1]);
println(result[2][2]);

// GCD and LCM
fn gcd(a, b) {
    while (b != 0) {
        my t = b;
        b = a % b;
        a = t;
    }
    return a;
}

fn lcm(a, b) {
    return (a * b) / gcd(a, b);
}

println(gcd(48, 36));
println(gcd(100, 75));
println(lcm(12, 18));

// Nested for loops computing a sum
my tripleSum = 0;
for (my i = 1; i <= 5; i = i + 1) {
    for (my j = 1; j <= 5; j = j + 1) {
        tripleSum = tripleSum + i * j;
    }
}
println(tripleSum);
]]

EXPECTED_ADVANCED = "0\n1\n5\n55\n6765\n75025\n832040\n25\n1060\n53\n25\n30\n69\n90\n12\n25\n36\n225"

# Program 7: String processing and more class features
PROG_STRINGS = [[
// String builder class
class StringBuilder {
    readable parts;
    readable count;
    fn() {
        this.parts = [];
        this.count = 0;
    }
    fn append(s) {
        this.parts.push(s);
        this.count = this.count + 1;
        return this;
    }
    fn build() {
        my result = "";
        for (my i = 0; i < this.count; i = i + 1) {
            result = result + this.parts[i];
        }
        return result;
    }
}

my sb = StringBuilder();
sb.append("Hello");
sb.append(" ");
sb.append("World");
sb.append("!");
println(sb.build());
println(sb.count);

// Stack implementation using size tracking
class Stack {
    readable items;
    readable sz;
    fn() {
        this.items = [];
        this.sz = 0;
    }
    fn push(val) {
        // Always append and track size
        if (this.sz == this.items.size) {
            this.items.push(val);
        } else {
            this.items[this.sz] = val;
        }
        this.sz = this.sz + 1;
    }
    fn pop() {
        if (this.sz == 0) { return null; }
        this.sz = this.sz - 1;
        return this.items[this.sz];
    }
    fn peek() {
        if (this.sz == 0) { return null; }
        return this.items[this.sz - 1];
    }
    fn isEmpty() {
        return this.sz == 0;
    }
}

my stack = Stack();
stack.push(10);
stack.push(20);
stack.push(30);
println(stack.peek());
println(stack.pop());
println(stack.pop());
println(stack.peek());
println(stack.isEmpty());

// Queue using two stacks
class Queue {
    readable inStack;
    readable outStack;
    fn() {
        this.inStack = Stack();
        this.outStack = Stack();
    }
    fn enqueue(val) {
        this.inStack.push(val);
    }
    fn dequeue() {
        if (this.outStack.isEmpty()) {
            while (!this.inStack.isEmpty()) {
                this.outStack.push(this.inStack.pop());
            }
        }
        return this.outStack.pop();
    }
}

my q = Queue();
q.enqueue(1);
q.enqueue(2);
q.enqueue(3);
q.enqueue(4);
println(q.dequeue());
println(q.dequeue());
q.enqueue(5);
println(q.dequeue());
println(q.dequeue());
println(q.dequeue());

// Compute string hash
fn hashString(s) {
    my h = 0;
    for (my i = 0; i < s.size; i = i + 1) {
        h = h * 31 + i + 1;
    }
    return h % 1000000;
}

println(hashString("hello"));
println(hashString("world"));
println(hashString("zef language"));

// Number to various representations
fn intToString(n) {
    if (n == 0) { return "0"; }
    my result = "";
    my neg = 0;
    if (n < 0) {
        neg = 1;
        n = 0 - n;
    }
    while (n > 0) {
        my digit = n % 10;
        result = digit.toString() + result;
        n = (n - digit) / 10;
    }
    if (neg) {
        result = "-" + result;
    }
    return result;
}

println(intToString(12345));
println(intToString(-99));
println(intToString(0));

// Collatz sequence
fn collatzLength(n) {
    my steps = 0;
    while (n != 1) {
        if (n % 2 == 0) {
            n = n / 2;
        } else {
            n = 3 * n + 1;
        }
        steps = steps + 1;
    }
    return steps;
}

println(collatzLength(27));
println(collatzLength(1));
println(collatzLength(7));
]]

EXPECTED_STRINGS = "Hello World!\n4\n30\n30\n20\n10\n0\n1\n2\n3\n4\n5\n986115\n986115\n161156\n12345\n-99\n0\n111\n0\n16"

# ============================================================================
# CHECKSUM AND BENCHMARK RUNNER
# ============================================================================

function checksumString(s)
    h = 5381
    for i = 1, s.count do
        h = h * 33 + byte(s, i)
        # Keep it in reasonable range to avoid precision issues
        h = h % 1000000007
    end
    return h
end

function runTest(name, source, expected)
    output = runProgram(source)
    if output != expected then
        print("FAIL: " .. name)
        print("Expected:")
        print(expected)
        print("Got:")
        print(output)
        error("Test failed: " .. name)
    end
    return checksumString(output)
end

function runAllTests()
    totalChecksum = 0
    totalChecksum = totalChecksum + runTest("LinkedList", PROG_LINKED_LIST, EXPECTED_LINKED_LIST)
    totalChecksum = totalChecksum + runTest("BinaryTree", PROG_BINARY_TREE, EXPECTED_BINARY_TREE)
    totalChecksum = totalChecksum + runTest("Shapes", PROG_SHAPES, EXPECTED_SHAPES)
    totalChecksum = totalChecksum + runTest("Closures", PROG_CLOSURES, EXPECTED_CLOSURES)
    totalChecksum = totalChecksum + runTest("Sorting", PROG_SORTING, EXPECTED_SORTING)
    totalChecksum = totalChecksum + runTest("Advanced", PROG_ADVANCED, EXPECTED_ADVANCED)
    totalChecksum = totalChecksum + runTest("Strings", PROG_STRINGS, EXPECTED_STRINGS)
    return totalChecksum
end

# ============================================================================
# MAIN
# ============================================================================

# Run once to validate
expectedChecksum = 3067968536

# Benchmark loop
iterations = 10
startTime = clock()
for iter = 1, iterations do
    cs = runAllTests()
    if cs != expectedChecksum then
        error("Checksum mismatch on iteration " .. iter)
    end
end
elapsed = clock() - startTime

print(format("Zef benchmark: all %d iterations passed. Time: %.3fs", iterations, elapsed))


end

bench.runCode(test, "zef")
