# forward declarations (implicit-local dialect has no hoisted globals)
btreeCollectKeys = null
btreeCount = null
btreeHeight = null
btreeInsertNonFull = null
btreeKeyLess = null
btreeRangeScan = null
btreeSearch = null
btreeSplitChild = null
compareValues = null
evalComparison = null
evalLike = null
resolveColumn = null
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

function test()

# SQL benchmark: a SQLite-like query engine with tokenizer, parser, executor,
# B-tree indexes, JOINs, aggregates, and comprehensive test queries.
# Target runtimes: Luau (lute)

# ===== Utility aliases (local) =====
floor = math.floor
mabs = math.abs
msqrt = math.sqrt
mmin = math.min
mmax = math.max
sfmt = string.format
ssub = string.sub
sbyte = string.byte
schar = string.char
sfind = string.find
slower = string.lower
supper = string.upper
slen = string.len
srep = string.rep
tinsert = table.insert
tremove = table.remove
tsort = table.sort
tconcat = table.concat
clock = os.clock

bxor = bit32.bxor
blshift = bit32.lshift
brshift = bit32.rshift

# ===== Seeded PRNG =====
PRNG = {}
PRNG.__index = PRNG

function PRNG.new(seed)
    return setmetatable({ state = seed or 12345 }, PRNG)
end

function PRNG:next()
    # xorshift32
    x = self.state
    x = bxor(x, blshift(x, 13))
    x = bxor(x, brshift(x, 17))
    x = bxor(x, blshift(x, 5))
    self.state = x
    return x
end

function PRNG:nextInt(lo, hi)
    x = self:next()
    # bit32 returns unsigned 32-bit values (0 to 4294967295)
    return lo + (x % (hi - lo + 1))
end

function PRNG:nextFloat()
    x = self:next()
    return x / 4294967296
end

function PRNG:choice(tbl)
    return tbl[self:nextInt(1, tbl.count)]
end

# ===== Token Types =====
TK_KEYWORD = "KEYWORD"
TK_IDENT = "IDENT"
TK_NUMBER = "NUMBER"
TK_STRING = "STRING"
TK_OP = "OP"
TK_LPAREN = "LPAREN"
TK_RPAREN = "RPAREN"
TK_COMMA = "COMMA"
TK_SEMI = "SEMI"
TK_STAR = "STAR"
TK_DOT = "DOT"
TK_EOF = "EOF"

# ===== Token =====
Token = {}
Token.__index = Token

function Token.new(typ, val, pos)
    return setmetatable({ type = typ, value = val, pos = pos or 0 }, Token)
end

function Token:__tostring()
    return sfmt("Token(%s, %s)", self.type, tostring(self.value))
end

# ===== SQL Keywords =====
SQL_KEYWORDS = {}
function initKeywords()
    kws = {
        "SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES", "CREATE", "TABLE",
        "DROP", "DELETE", "UPDATE", "SET", "AND", "OR", "NOT", "IN", "LIKE",
        "ORDER", "BY", "ASC", "DESC", "LIMIT", "OFFSET", "GROUP", "HAVING",
        "AS", "ON", "JOIN", "INNER", "LEFT", "RIGHT", "OUTER", "CROSS",
        "NULL", "IS", "BETWEEN", "EXISTS", "DISTINCT", "COUNT", "SUM", "AVG",
        "MIN", "MAX", "INTEGER", "TEXT", "REAL", "PRIMARY", "KEY", "INDEX",
        "IF", "ELSE", "CASE", "WHEN", "THEN", "END", "UNION", "ALL"
    }
    for _, kw in next, kws do
        SQL_KEYWORDS[kw] = true
    end
end
initKeywords()

# ===== Tokenizer =====
Tokenizer = {}
Tokenizer.__index = Tokenizer

function Tokenizer.new(sql)
    return setmetatable({
        src = sql,
        pos = 1,
        len = slen(sql),
        tokens = {}
    }, Tokenizer)
end

function Tokenizer:peek()
    if self.pos > self.len then return null end
    return sbyte(self.src, self.pos)
end

function Tokenizer:advance()
    c = sbyte(self.src, self.pos)
    self.pos = self.pos + 1
    return c
end

function Tokenizer:skipWhitespace()
    while self.pos <= self.len do
        c = sbyte(self.src, self.pos)
        if c == 32 or c == 9 or c == 10 or c == 13 then
            self.pos = self.pos + 1
        else if c == 45 and self.pos + 1 <= self.len and sbyte(self.src, self.pos + 1) == 45 then
            # line comment
            self.pos = self.pos + 2
            while self.pos <= self.len and sbyte(self.src, self.pos) != 10 do
                self.pos = self.pos + 1
            end
        else
            break
        end
    end
end

function Tokenizer:isAlpha(c)
    return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95
end

function Tokenizer:isDigit(c)
    return c >= 48 and c <= 57
end

function Tokenizer:isAlnum(c)
    return self:isAlpha(c) or self:isDigit(c)
end

function Tokenizer:readIdent()
    start = self.pos
    while self.pos <= self.len and self:isAlnum(sbyte(self.src, self.pos)) do
        self.pos = self.pos + 1
    end
    return ssub(self.src, start, self.pos - 1)
end

function Tokenizer:readNumber()
    start = self.pos
    hasDot = false
    while self.pos <= self.len do
        c = sbyte(self.src, self.pos)
        if self:isDigit(c) then
            self.pos = self.pos + 1
        else if c == 46 and not hasDot then
            hasDot = true
            self.pos = self.pos + 1
        else
            break
        end
    end
    return tonumber(ssub(self.src, start, self.pos - 1))
end

function Tokenizer:readString(quote)
    self.pos = self.pos + 1  # skip opening quote
    parts = {}
    while self.pos <= self.len do
        c = sbyte(self.src, self.pos)
        if c == quote then
            # check for escaped quote (double quote)
            if self.pos + 1 <= self.len and sbyte(self.src, self.pos + 1) == quote then
                tinsert(parts, schar(quote))
                self.pos = self.pos + 2
            else
                self.pos = self.pos + 1
                break
            end
        else
            tinsert(parts, schar(c))
            self.pos = self.pos + 1
        end
    end
    return tconcat(parts)
end

function Tokenizer:tokenize()
    while true do
        self:skipWhitespace()
        if self.pos > self.len then
            tinsert(self.tokens, Token.new(TK_EOF, null, self.pos))
            break
        end
        startPos = self.pos
        c = sbyte(self.src, self.pos)

        if self:isAlpha(c) then
            ident = self:readIdent()
            upper = supper(ident)
            if SQL_KEYWORDS[upper] then
                tinsert(self.tokens, Token.new(TK_KEYWORD, upper, startPos))
            else
                tinsert(self.tokens, Token.new(TK_IDENT, ident, startPos))
            end
        else if self:isDigit(c) then
            num = self:readNumber()
            tinsert(self.tokens, Token.new(TK_NUMBER, num, startPos))
        else if c == 39 then  # single quote
            str = self:readString(39)
            tinsert(self.tokens, Token.new(TK_STRING, str, startPos))
        else if c == 34 then  # double quote (identifier)
            str = self:readString(34)
            tinsert(self.tokens, Token.new(TK_IDENT, str, startPos))
        else if c == 40 then  # (
            tinsert(self.tokens, Token.new(TK_LPAREN, "(", startPos))
            self.pos = self.pos + 1
        else if c == 41 then  # )
            tinsert(self.tokens, Token.new(TK_RPAREN, ")", startPos))
            self.pos = self.pos + 1
        else if c == 44 then  # ,
            tinsert(self.tokens, Token.new(TK_COMMA, ",", startPos))
            self.pos = self.pos + 1
        else if c == 59 then  # ;
            tinsert(self.tokens, Token.new(TK_SEMI, ";", startPos))
            self.pos = self.pos + 1
        else if c == 42 then  # *
            tinsert(self.tokens, Token.new(TK_STAR, "*", startPos))
            self.pos = self.pos + 1
        else if c == 46 then  # .
            tinsert(self.tokens, Token.new(TK_DOT, ".", startPos))
            self.pos = self.pos + 1
        else if c == 60 then  # < or <= or <>
            self.pos = self.pos + 1
            if self.pos <= self.len then
                nc = sbyte(self.src, self.pos)
                if nc == 61 then  # <=
                    tinsert(self.tokens, Token.new(TK_OP, "<=", startPos))
                    self.pos = self.pos + 1
                else if nc == 62 then  # <>
                    tinsert(self.tokens, Token.new(TK_OP, "<>", startPos))
                    self.pos = self.pos + 1
                else
                    tinsert(self.tokens, Token.new(TK_OP, "<", startPos))
                end
            else
                tinsert(self.tokens, Token.new(TK_OP, "<", startPos))
            end
        else if c == 62 then  # > or >=
            self.pos = self.pos + 1
            if self.pos <= self.len and sbyte(self.src, self.pos) == 61 then
                tinsert(self.tokens, Token.new(TK_OP, ">=", startPos))
                self.pos = self.pos + 1
            else
                tinsert(self.tokens, Token.new(TK_OP, ">", startPos))
            end
        else if c == 61 then  # =
            tinsert(self.tokens, Token.new(TK_OP, "=", startPos))
            self.pos = self.pos + 1
        else if c == 33 then  # !=
            self.pos = self.pos + 1
            if self.pos <= self.len and sbyte(self.src, self.pos) == 61 then
                tinsert(self.tokens, Token.new(TK_OP, "!=", startPos))
                self.pos = self.pos + 1
            else
                tinsert(self.tokens, Token.new(TK_OP, "!", startPos))
            end
        else if c == 43 then  # +
            tinsert(self.tokens, Token.new(TK_OP, "+", startPos))
            self.pos = self.pos + 1
        else if c == 45 then  # -
            tinsert(self.tokens, Token.new(TK_OP, "-", startPos))
            self.pos = self.pos + 1
        else if c == 47 then  # /
            tinsert(self.tokens, Token.new(TK_OP, "/", startPos))
            self.pos = self.pos + 1
        else if c == 37 then  # %
            tinsert(self.tokens, Token.new(TK_OP, "%", startPos))
            self.pos = self.pos + 1
        else
            # skip unknown
            self.pos = self.pos + 1
        end
    end
    return self.tokens
end

# ===== AST Node Types =====
# We use plain tables with a "kind" field for AST nodes

function mkNode(kind, props)
    props = props or {}
    props.kind = kind
    return props
end

# ===== Parser =====
Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
    return setmetatable({
        tokens = tokens,
        pos = 1,
        len = tokens.count
    }, Parser)
end

function Parser:current()
    if self.pos > self.len then
        return Token.new(TK_EOF, null, 0)
    end
    return self.tokens[self.pos]
end

function Parser:peek()
    return self:current()
end

function Parser:peekType()
    return self:current().type
end

function Parser:peekValue()
    return self:current().value
end

function Parser:advance()
    t = self:current()
    self.pos = self.pos + 1
    return t
end

function Parser:expect(typ, val)
    t = self:current()
    if t.type != typ then
        error(sfmt("Parser: expected %s got %s at pos %d", typ, t.type, t.pos))
    end
    if val and t.value != val then
        error(sfmt("Parser: expected value '%s' got '%s' at pos %d", val, tostring(t.value), t.pos))
    end
    self.pos = self.pos + 1
    return t
end

function Parser:match(typ, val)
    t = self:current()
    if t.type == typ and (val == null or t.value == val) then
        self.pos = self.pos + 1
        return t
    end
    return null
end

function Parser:matchKeyword(kw)
    return self:match(TK_KEYWORD, kw)
end

function Parser:isKeyword(kw)
    t = self:current()
    return t.type == TK_KEYWORD and t.value == kw
end

function Parser:parse()
    stmts = {}
    while self:peekType() != TK_EOF do
        stmt = self:parseStatement()
        if stmt then
            tinsert(stmts, stmt)
        end
        self:match(TK_SEMI)
    end
    return stmts
end

function Parser:parseStatement()
    t = self:current()
    if t.type == TK_KEYWORD then
        if t.value == "SELECT" then
            return self:parseSelect()
        else if t.value == "INSERT" then
            return self:parseInsert()
        else if t.value == "CREATE" then
            return self:parseCreate()
        else if t.value == "DELETE" then
            return self:parseDelete()
        else if t.value == "UPDATE" then
            return self:parseUpdate()
        end
    end
    error(sfmt("Parser: unexpected token %s '%s'", t.type, tostring(t.value)))
end

function Parser:parseSelect()
    self:expect(TK_KEYWORD, "SELECT")
    distinct = false
    if self:matchKeyword("DISTINCT") then
        distinct = true
    end
    columns = self:parseSelectColumns()
    from = null
    joins = {}
    whereClause = null
    groupBy = null
    having = null
    orderBy = null
    limitVal = null
    offsetVal = null

    if self:matchKeyword("FROM") then
        from = self:parseTableRef()
        # parse JOINs
        while self:isKeyword("JOIN") or self:isKeyword("INNER") or self:isKeyword("LEFT") or self:isKeyword("CROSS") do
            tinsert(joins, self:parseJoin())
        end
    end
    if self:matchKeyword("WHERE") then
        whereClause = self:parseExpr()
    end
    if self:matchKeyword("GROUP") then
        self:expect(TK_KEYWORD, "BY")
        groupBy = self:parseExprList()
    end
    if self:matchKeyword("HAVING") then
        having = self:parseExpr()
    end
    if self:matchKeyword("ORDER") then
        self:expect(TK_KEYWORD, "BY")
        orderBy = self:parseOrderByList()
    end
    if self:matchKeyword("LIMIT") then
        limitVal = self:expect(TK_NUMBER).value
    end
    if self:matchKeyword("OFFSET") then
        offsetVal = self:expect(TK_NUMBER).value
    end

    return mkNode("SELECT", {
        distinct = distinct,
        columns = columns,
        from = from,
        joins = joins,
        where = whereClause,
        groupBy = groupBy,
        having = having,
        orderBy = orderBy,
        limitVal = limitVal,
        offsetVal = offsetVal
    })
end

function Parser:parseSelectColumns()
    cols = {}
    if self:current().type == TK_STAR then
        self:advance()
        tinsert(cols, mkNode("STAR_COL"))
        if self:match(TK_COMMA) then
            # more columns after *? Unusual but handle
            rest = self:parseSelectColumns()
            for _, c in next, rest do tinsert(cols, c) end
        end
        return cols
    end
    while true do
        expr = self:parseExpr()
        alias = null
        if self:matchKeyword("AS") then
            alias = self:expect(TK_IDENT).value
        else if self:peekType() == TK_IDENT and not self:isKeyword("FROM") and not self:isKeyword("WHERE") then
            # implicit alias
            alias = self:advance().value
        end
        tinsert(cols, mkNode("COLUMN", { expr = expr, alias = alias }))
        if not self:match(TK_COMMA) then break end
    end
    return cols
end

function Parser:parseTableRef()
    name = self:expect(TK_IDENT).value
    alias = null
    if self:matchKeyword("AS") then
        alias = self:expect(TK_IDENT).value
    else if self:peekType() == TK_IDENT and not self:isKeyword("WHERE") and not self:isKeyword("ON")
           and not self:isKeyword("JOIN") and not self:isKeyword("INNER") and not self:isKeyword("LEFT")
           and not self:isKeyword("ORDER") and not self:isKeyword("GROUP") and not self:isKeyword("LIMIT")
           and not self:isKeyword("CROSS") then
        alias = self:advance().value
    end
    return mkNode("TABLE_REF", { name = name, alias = alias })
end

function Parser:parseJoin()
    joinType = "INNER"
    if self:matchKeyword("INNER") then
        joinType = "INNER"
    else if self:matchKeyword("LEFT") then
        joinType = "LEFT"
        self:matchKeyword("OUTER")
    else if self:matchKeyword("CROSS") then
        joinType = "CROSS"
    end
    self:expect(TK_KEYWORD, "JOIN")
    tableRef = self:parseTableRef()
    onExpr = null
    if self:matchKeyword("ON") then
        onExpr = self:parseExpr()
    end
    return mkNode("JOIN", { joinType = joinType, table = tableRef, on = onExpr })
end

function Parser:parseOrderByList()
    items = {}
    while true do
        expr = self:parseExpr()
        dir = "ASC"
        if self:matchKeyword("ASC") then
            dir = "ASC"
        else if self:matchKeyword("DESC") then
            dir = "DESC"
        end
        tinsert(items, mkNode("ORDER_ITEM", { expr = expr, dir = dir }))
        if not self:match(TK_COMMA) then break end
    end
    return items
end

function Parser:parseExprList()
    exprs = {}
    while true do
        tinsert(exprs, self:parseExpr())
        if not self:match(TK_COMMA) then break end
    end
    return exprs
end

function Parser:parseExpr()
    return self:parseOr()
end

function Parser:parseOr()
    left = self:parseAnd()
    while self:isKeyword("OR") do
        self:advance()
        right = self:parseAnd()
        left = mkNode("BINOP", { op = "OR", left = left, right = right })
    end
    return left
end

function Parser:parseAnd()
    left = self:parseNot()
    while self:isKeyword("AND") do
        self:advance()
        right = self:parseNot()
        left = mkNode("BINOP", { op = "AND", left = left, right = right })
    end
    return left
end

function Parser:parseNot()
    if self:isKeyword("NOT") then
        self:advance()
        expr = self:parseNot()
        return mkNode("UNOP", { op = "NOT", operand = expr })
    end
    return self:parseComparison()
end

function Parser:parseComparison()
    left = self:parseAddSub()
    t = self:current()

    if t.type == TK_OP then
        op = t.value
        if op == "=" or op == "!=" or op == "<>" or op == "<" or op == ">" or op == "<=" or op == ">=" then
            self:advance()
            right = self:parseAddSub()
            if op == "<>" then op = "!=" end
            return mkNode("BINOP", { op = op, left = left, right = right })
        end
    else if t.type == TK_KEYWORD then
        if t.value == "LIKE" then
            self:advance()
            right = self:parseAddSub()
            return mkNode("BINOP", { op = "LIKE", left = left, right = right })
        else if t.value == "IN" then
            self:advance()
            self:expect(TK_LPAREN)
            vals = self:parseExprList()
            self:expect(TK_RPAREN)
            return mkNode("IN_EXPR", { expr = left, values = vals })
        else if t.value == "IS" then
            self:advance()
            if self:matchKeyword("NOT") then
                self:expect(TK_KEYWORD, "NULL")
                return mkNode("BINOP", { op = "IS NOT NULL", left = left, right = mkNode("NULL_LIT") })
            else
                self:expect(TK_KEYWORD, "NULL")
                return mkNode("BINOP", { op = "IS NULL", left = left, right = mkNode("NULL_LIT") })
            end
        else if t.value == "BETWEEN" then
            self:advance()
            lo = self:parseAddSub()
            self:expect(TK_KEYWORD, "AND")
            hi = self:parseAddSub()
            return mkNode("BETWEEN", { expr = left, lo = lo, hi = hi })
        end
    end
    return left
end

function Parser:parseAddSub()
    left = self:parseMulDiv()
    while true do
        t = self:current()
        if t.type == TK_OP and (t.value == "+" or t.value == "-") then
            self:advance()
            right = self:parseMulDiv()
            left = mkNode("BINOP", { op = t.value, left = left, right = right })
        else
            break
        end
    end
    return left
end

function Parser:parseMulDiv()
    left = self:parseUnary()
    while true do
        t = self:current()
        if t.type == TK_OP and (t.value == "*" or t.value == "/" or t.value == "%") then
            self:advance()
            right = self:parseUnary()
            left = mkNode("BINOP", { op = t.value, left = left, right = right })
        else if t.type == TK_STAR then
            self:advance()
            right = self:parseUnary()
            left = mkNode("BINOP", { op = "*", left = left, right = right })
        else
            break
        end
    end
    return left
end

function Parser:parseUnary()
    t = self:current()
    if t.type == TK_OP and t.value == "-" then
        self:advance()
        expr = self:parsePrimary()
        return mkNode("UNOP", { op = "NEG", operand = expr })
    end
    return self:parsePrimary()
end

function Parser:parsePrimary()
    t = self:current()

    if t.type == TK_NUMBER then
        self:advance()
        return mkNode("NUMBER_LIT", { value = t.value })
    else if t.type == TK_STRING then
        self:advance()
        return mkNode("STRING_LIT", { value = t.value })
    else if t.type == TK_KEYWORD and t.value == "NULL" then
        self:advance()
        return mkNode("NULL_LIT")
    else if t.type == TK_LPAREN then
        self:advance()
        expr = self:parseExpr()
        self:expect(TK_RPAREN)
        return expr
    else if t.type == TK_KEYWORD and (t.value == "COUNT" or t.value == "SUM" or t.value == "AVG" or t.value == "MIN" or t.value == "MAX") then
        funcName = t.value
        self:advance()
        self:expect(TK_LPAREN)
        argExpr = null
        isStar = false
        if self:current().type == TK_STAR then
            self:advance()
            isStar = true
        else
            argExpr = self:parseExpr()
        end
        self:expect(TK_RPAREN)
        return mkNode("AGG_FUNC", { func = funcName, arg = argExpr, star = isStar })
    else if t.type == TK_IDENT then
        name = t.value
        self:advance()
        # check for table.column
        if self:current().type == TK_DOT then
            self:advance()
            col = self:current()
            if col.type == TK_IDENT or col.type == TK_STAR then
                self:advance()
                if col.type == TK_STAR then
                    return mkNode("QUALIFIED_STAR", { table_name = name })
                end
                return mkNode("COLUMN_REF", { table_name = name, column = col.value })
            end
        end
        # check for function call
        if self:current().type == TK_LPAREN then
            self:advance()
            args = {}
            if self:current().type != TK_RPAREN then
                args = self:parseExprList()
            end
            self:expect(TK_RPAREN)
            return mkNode("FUNC_CALL", { name = name, args = args })
        end
        return mkNode("COLUMN_REF", { table_name = null, column = name })
    else if t.type == TK_STAR then
        self:advance()
        return mkNode("STAR_COL")
    end

    error(sfmt("Parser: unexpected in expression: %s '%s' at pos %d", t.type, tostring(t.value), t.pos))
end

function Parser:parseInsert()
    self:expect(TK_KEYWORD, "INSERT")
    self:expect(TK_KEYWORD, "INTO")
    tableName = self:expect(TK_IDENT).value
    columns = null
    if self:current().type == TK_LPAREN then
        self:advance()
        columns = {}
        while true do
            tinsert(columns, self:expect(TK_IDENT).value)
            if not self:match(TK_COMMA) then break end
        end
        self:expect(TK_RPAREN)
    end
    self:expect(TK_KEYWORD, "VALUES")
    rows = {}
    while true do
        self:expect(TK_LPAREN)
        vals = self:parseExprList()
        self:expect(TK_RPAREN)
        tinsert(rows, vals)
        if not self:match(TK_COMMA) then break end
    end
    return mkNode("INSERT", { table_name = tableName, columns = columns, rows = rows })
end

function Parser:parseCreate()
    self:expect(TK_KEYWORD, "CREATE")
    if self:matchKeyword("TABLE") then
        return self:parseCreateTable()
    else if self:matchKeyword("INDEX") then
        return self:parseCreateIndex()
    end
    error("Parser: expected TABLE or INDEX after CREATE")
end

function Parser:parseCreateTable()
    tableName = self:expect(TK_IDENT).value
    self:expect(TK_LPAREN)
    cols = {}
    while true do
        colName = self:expect(TK_IDENT).value
        colType = "TEXT"
        if self:current().type == TK_KEYWORD then
            kv = self:current().value
            if kv == "INTEGER" or kv == "TEXT" or kv == "REAL" then
                colType = kv
                self:advance()
            end
        end
        isPK = false
        if self:matchKeyword("PRIMARY") then
            self:expect(TK_KEYWORD, "KEY")
            isPK = true
        end
        tinsert(cols, { name = colName, colType = colType, primaryKey = isPK })
        if not self:match(TK_COMMA) then break end
        # check for trailing paren
        if self:current().type == TK_RPAREN then break end
    end
    self:expect(TK_RPAREN)
    return mkNode("CREATE_TABLE", { table_name = tableName, columns = cols })
end

function Parser:parseCreateIndex()
    indexName = self:expect(TK_IDENT).value
    self:expect(TK_KEYWORD, "ON")
    tableName = self:expect(TK_IDENT).value
    self:expect(TK_LPAREN)
    cols = {}
    while true do
        tinsert(cols, self:expect(TK_IDENT).value)
        if not self:match(TK_COMMA) then break end
    end
    self:expect(TK_RPAREN)
    return mkNode("CREATE_INDEX", { index_name = indexName, table_name = tableName, columns = cols })
end

function Parser:parseDelete()
    self:expect(TK_KEYWORD, "DELETE")
    self:expect(TK_KEYWORD, "FROM")
    tableName = self:expect(TK_IDENT).value
    whereClause = null
    if self:matchKeyword("WHERE") then
        whereClause = self:parseExpr()
    end
    return mkNode("DELETE", { table_name = tableName, where = whereClause })
end

function Parser:parseUpdate()
    self:expect(TK_KEYWORD, "UPDATE")
    tableName = self:expect(TK_IDENT).value
    self:expect(TK_KEYWORD, "SET")
    assignments = {}
    while true do
        col = self:expect(TK_IDENT).value
        self:expect(TK_OP, "=")
        val = self:parseExpr()
        tinsert(assignments, { column = col, value = val })
        if not self:match(TK_COMMA) then break end
    end
    whereClause = null
    if self:matchKeyword("WHERE") then
        whereClause = self:parseExpr()
    end
    return mkNode("UPDATE", { table_name = tableName, assignments = assignments, where = whereClause })
end

# ===== B-Tree Index =====
BTREE_ORDER = 8  # max children per node

BTreeNode = {}
BTreeNode.__index = BTreeNode

function BTreeNode.new(isLeaf)
    return setmetatable({
        isLeaf = isLeaf,
        keys = {},      # {key, rowIndex} pairs
        children = {},  # child nodes (for internal nodes)
        numKeys = 0
    }, BTreeNode)
end

BTree = {}
BTree.__index = BTree

function BTree.new()
    return setmetatable({
        root = BTreeNode.new(true)
    }, BTree)
end

function BTree:insert(key, rowIndex)
    root = self.root
    if root.numKeys >= BTREE_ORDER - 1 then
        newRoot = BTreeNode.new(false)
        newRoot.children[1] = root
        btreeSplitChild(newRoot, 1)
        self.root = newRoot
        btreeInsertNonFull(newRoot, key, rowIndex)
    else
        btreeInsertNonFull(root, key, rowIndex)
    end
end

function btreeSplitChild(parent, idx)
    fullChild = parent.children[idx]
    mid = floor((BTREE_ORDER - 1) / 2) + 1
    newNode = BTreeNode.new(fullChild.isLeaf)

    # move upper half keys to new node
    j = 1
    for i = mid + 1, fullChild.numKeys do
        newNode.keys[j] = fullChild.keys[i]
        fullChild.keys[i] = null
        j = j + 1
    end
    newNode.numKeys = j - 1

    # move upper half children if internal
    if not fullChild.isLeaf then
        j = 1
        for i = mid + 1, fullChild.numKeys + 1 do
            newNode.children[j] = fullChild.children[i]
            fullChild.children[i] = null
            j = j + 1
        end
    end

    midKey = fullChild.keys[mid]
    fullChild.keys[mid] = null
    fullChild.numKeys = mid - 1

    # shift parent's children and keys
    for i = parent.numKeys + 1, idx + 1, -1 do
        parent.children[i + 1] = parent.children[i]
    end
    parent.children[idx + 1] = newNode

    for i = parent.numKeys, idx, -1 do
        parent.keys[i + 1] = parent.keys[i]
    end
    parent.keys[idx] = midKey
    parent.numKeys = parent.numKeys + 1
end

function btreeInsertNonFull(node, key, rowIndex)
    if node.isLeaf then
        i = node.numKeys
        while i >= 1 and btreeKeyLess(key, node.keys[i][1]) do
            node.keys[i + 1] = node.keys[i]
            i = i - 1
        end
        node.keys[i + 1] = { key, rowIndex }
        node.numKeys = node.numKeys + 1
    else
        i = node.numKeys
        while i >= 1 and btreeKeyLess(key, node.keys[i][1]) do
            i = i - 1
        end
        i = i + 1
        if node.children[i].numKeys >= BTREE_ORDER - 1 then
            btreeSplitChild(node, i)
            if btreeKeyLess(node.keys[i][1], key) then
                i = i + 1
            end
        end
        btreeInsertNonFull(node.children[i], key, rowIndex)
    end
end

function btreeKeyLess(a, b)
    if type(a) == "number" and type(b) == "number" then
        return a < b
    end
    return tostring(a) < tostring(b)
end

function btreeKeyEqual(a, b)
    if type(a) == "number" and type(b) == "number" then
        return a == b
    end
    return tostring(a) == tostring(b)
end

function BTree:search(key)
    return btreeSearch(self.root, key)
end

function btreeSearch(node, key)
    results = {}
    if node == null then return results end

    i = 1
    while i <= node.numKeys and btreeKeyLess(node.keys[i][1], key) do
        i = i + 1
    end

    if i <= node.numKeys and btreeKeyEqual(node.keys[i][1], key) then
        tinsert(results, node.keys[i][2])
        # check for duplicates in adjacent positions
        j = i + 1
        while j <= node.numKeys and btreeKeyEqual(node.keys[j][1], key) do
            tinsert(results, node.keys[j][2])
            j = j + 1
        end
    end

    if not node.isLeaf then
        childResults = btreeSearch(node.children[i], key)
        for _, r in next, childResults do
            tinsert(results, r)
        end
    end

    return results
end

function BTree:rangeScan(lo, hi)
    results = {}
    btreeRangeScan(self.root, lo, hi, results)
    return results
end

function btreeRangeScan(node, lo, hi, results)
    if node == null then return end

    for i = 1, node.numKeys do
        k = node.keys[i][1]
        if not node.isLeaf then
            if lo == null or not btreeKeyLess(k, lo) then
                btreeRangeScan(node.children[i], lo, hi, results)
            end
        end
        inRange = true
        if lo != null and btreeKeyLess(k, lo) then inRange = false end
        if hi != null and btreeKeyLess(hi, k) then inRange = false end
        if inRange then
            tinsert(results, node.keys[i][2])
        end
    end
    if not node.isLeaf then
        lastKey = node.keys[node.numKeys]
        if lastKey and (hi == null or not btreeKeyLess(hi, lastKey[1])) then
            btreeRangeScan(node.children[node.numKeys + 1], lo, hi, results)
        end
    end
end

# ===== Table Storage =====
TableStore = {}
TableStore.__index = TableStore

function TableStore.new(name, columns)
    colMap = {}
    for i, col in next, columns do
        colMap[col.name] = i
    end
    return setmetatable({
        name = name,
        columns = columns,
        colMap = colMap,
        rows = {},
        indexes = {},
        nextRowId = 1
    }, TableStore)
end

function TableStore:insertRow(values)
    rowId = self.nextRowId
    self.nextRowId = rowId + 1
    self.rows[rowId] = values

    # update indexes
    for colName, idx in next, self.indexes do
        colIdx = self.colMap[colName]
        if colIdx and values[colIdx] != null then
            idx:insert(values[colIdx], rowId)
        end
    end
    return rowId
end

function TableStore:createIndex(colName)
    tree = BTree.new()
    colIdx = self.colMap[colName]
    if colIdx then
        for rowId, row in next, self.rows do
            if row[colIdx] != null then
                tree:insert(row[colIdx], rowId)
            end
        end
    end
    self.indexes[colName] = tree
end

function TableStore:getColumnIndex(colName)
    return self.colMap[colName]
end

function TableStore:deleteRow(rowId)
    self.rows[rowId] = null
end

# ===== Database =====
Database = {}
Database.__index = Database

function Database.new()
    return setmetatable({
        tables = {}
    }, Database)
end

function Database:createTable(name, columns)
    store = TableStore.new(name, columns)
    self.tables[name] = store
    return store
end

function Database:getTable(name)
    return self.tables[name]
end

function Database:dropTable(name)
    self.tables[name] = null
end

# ===== Query Executor =====
Executor = {}
Executor.__index = Executor

function Executor.new(db)
    return setmetatable({
        db = db
    }, Executor)
end

function Executor:execute(sql)
    tokenizer = Tokenizer.new(sql)
    tokens = tokenizer:tokenize()
    parser = Parser.new(tokens)
    stmts = parser:parse()
    lastResult = null
    for _, stmt in next, stmts do
        lastResult = self:executeStatement(stmt)
    end
    return lastResult
end

function Executor:executeStatement(stmt)
    if stmt.kind == "CREATE_TABLE" then
        return self:execCreateTable(stmt)
    else if stmt.kind == "CREATE_INDEX" then
        return self:execCreateIndex(stmt)
    else if stmt.kind == "INSERT" then
        return self:execInsert(stmt)
    else if stmt.kind == "SELECT" then
        return self:execSelect(stmt)
    else if stmt.kind == "DELETE" then
        return self:execDelete(stmt)
    else if stmt.kind == "UPDATE" then
        return self:execUpdate(stmt)
    end
    error("Executor: unknown statement kind: " .. tostring(stmt.kind))
end

function Executor:execCreateTable(stmt)
    cols = {}
    for _, c in next, stmt.columns do
        tinsert(cols, { name = c.name, colType = c.colType, primaryKey = c.primaryKey })
    end
    self.db:createTable(stmt.table_name, cols)
    return { type = "OK", message = "Table created" }
end

function Executor:execCreateIndex(stmt)
    tbl = self.db:getTable(stmt.table_name)
    if not tbl then error("Table not found: " .. stmt.table_name) end
    for _, colName in next, stmt.columns do
        tbl:createIndex(colName)
    end
    return { type = "OK", message = "Index created" }
end

function Executor:execInsert(stmt)
    tbl = self.db:getTable(stmt.table_name)
    if not tbl then error("Table not found: " .. stmt.table_name) end
    count = 0
    for _, rowExprs in next, stmt.rows do
        values = {}
        for i, expr in next, rowExprs do
            values[i] = self:evalLiteral(expr)
        end
        # reorder if columns specified
        if stmt.columns then
            reordered = {}
            for i, colName in next, stmt.columns do
                colIdx = tbl:getColumnIndex(colName)
                if colIdx then
                    reordered[colIdx] = values[i]
                end
            end
            tbl:insertRow(reordered)
        else
            tbl:insertRow(values)
        end
        count = count + 1
    end
    return { type = "OK", message = sfmt("%d row(s) inserted", count) }
end

function Executor:evalLiteral(expr)
    if expr.kind == "NUMBER_LIT" then return expr.value
    else if expr.kind == "STRING_LIT" then return expr.value
    else if expr.kind == "NULL_LIT" then return null
    else if expr.kind == "UNOP" and expr.op == "NEG" then
        v = self:evalLiteral(expr.operand)
        if type(v) == "number" then return -v end
        return null
    end
    return null
end

function Executor:execDelete(stmt)
    tbl = self.db:getTable(stmt.table_name)
    if not tbl then error("Table not found: " .. stmt.table_name) end
    count = 0
    toDelete = {}
    for rowId, row in next, tbl.rows do
        ctx = self:makeRowContext(tbl, row, null, null)
        if stmt.where == null or self:evalExpr(stmt.where, ctx) then
            tinsert(toDelete, rowId)
        end
    end
    for _, rowId in next, toDelete do
        tbl:deleteRow(rowId)
        count = count + 1
    end
    return { type = "OK", message = sfmt("%d row(s) deleted", count) }
end

function Executor:execUpdate(stmt)
    tbl = self.db:getTable(stmt.table_name)
    if not tbl then error("Table not found: " .. stmt.table_name) end
    count = 0
    for rowId, row in next, tbl.rows do
        ctx = self:makeRowContext(tbl, row, null, null)
        if stmt.where == null or self:evalExpr(stmt.where, ctx) then
            for _, assign in next, stmt.assignments do
                colIdx = tbl:getColumnIndex(assign.column)
                if colIdx then
                    row[colIdx] = self:evalExpr(assign.value, ctx)
                end
            end
            count = count + 1
        end
    end
    return { type = "OK", message = sfmt("%d row(s) updated", count) }
end

function Executor:makeRowContext(tbl, row, joinTables, joinRows)
    ctx = {
        tables = {},
        resolve = resolveColumn
    }
    ctx.tables[tbl.name] = { tbl = tbl, row = row }
    if joinTables and joinRows then
        for i, jt in next, joinTables do
            if joinRows[i] then
                alias = jt.alias or jt.name
                ctx.tables[alias] = { tbl = self.db:getTable(jt.name), row = joinRows[i] }
            end
        end
    end
    return ctx
end

function resolveColumn(ctx, tableName, colName)
    if tableName then
        entry = ctx.tables[tableName]
        if entry and entry.tbl then
            colIdx = entry.tbl:getColumnIndex(colName)
            if colIdx and entry.row then
                return entry.row[colIdx]
            end
        end
        return null
    end
    # search all tables
    for _, entry in next, ctx.tables do
        if entry.tbl then
            colIdx = entry.tbl:getColumnIndex(colName)
            if colIdx and entry.row then
                return entry.row[colIdx]
            end
        end
    end
    return null
end

function Executor:execSelect(stmt)
    # Get base table rows
    tbl = null
    baseAlias = null
    rows = {}

    if stmt.from then
        tbl = self.db:getTable(stmt.from.name)
        if not tbl then error("Table not found: " .. stmt.from.name) end
        baseAlias = stmt.from.alias or stmt.from.name

        # Try index scan for simple WHERE on indexed column
        useIndex = false
        if stmt.where and stmt.joins.count == 0 and stmt.where.kind == "BINOP" and stmt.where.op == "=" then
            indexCol = self:getIndexableColumn(stmt.where, tbl)
            if indexCol then
                val = self:getCompareValue(stmt.where, indexCol.colName)
                if val != null then
                    idx = tbl.indexes[indexCol.colName]
                    if idx then
                        rowIds = idx:search(val)
                        for _, rowId in next, rowIds do
                            if tbl.rows[rowId] then
                                tinsert(rows, tbl.rows[rowId])
                            end
                        end
                        useIndex = true
                    end
                end
            end
        end

        if not useIndex then
            for _, row in next, tbl.rows do
                tinsert(rows, row)
            end
        end
    else
        # No FROM clause - single row with no columns
        rows = { {} }
        tbl = TableStore.new("__dual", {})
    end

    # Process JOINs
    joinTableInfo = {}
    if stmt.joins and stmt.joins.count > 0 then
        for _, join in next, stmt.joins do
            joinTbl = self.db:getTable(join.table.name)
            if not joinTbl then error("Table not found: " .. join.table.name) end
            joinAlias = join.table.alias or join.table.name
            tinsert(joinTableInfo, { name = join.table.name, alias = joinAlias, tbl = joinTbl, join = join })
        end

        # Perform nested loop join
        rows = self:performJoins(tbl, baseAlias, rows, joinTableInfo, stmt)
    else
        # Filter with WHERE (if not already done by index)
        if stmt.where then
            filtered = {}
            for _, row in next, rows do
                ctx = { tables = {}, resolve = resolveColumn }
                ctx.tables[baseAlias] = { tbl = tbl, row = row }
                if self:evalExpr(stmt.where, ctx) then
                    tinsert(filtered, row)
                end
            end
            rows = filtered
        end
    end

    # GROUP BY
    if stmt.groupBy then
        return self:execGroupBy(stmt, tbl, baseAlias, rows, joinTableInfo)
    end

    # Check if there are aggregate functions without GROUP BY
    if self:hasAggregates(stmt.columns) then
        return self:execAggregateNoGroup(stmt, tbl, baseAlias, rows, joinTableInfo)
    end

    # ORDER BY
    if stmt.orderBy then
        rows = self:applyOrderBy(stmt.orderBy, rows, tbl, baseAlias, joinTableInfo)
    end

    # DISTINCT
    if stmt.distinct then
        rows = self:applyDistinct(stmt, rows, tbl, baseAlias, joinTableInfo)
    end

    # LIMIT / OFFSET
    if stmt.offsetVal then
        newRows = {}
        for i = stmt.offsetVal + 1, rows.count do
            tinsert(newRows, rows[i])
        end
        rows = newRows
    end
    if stmt.limitVal then
        newRows = {}
        for i = 1, mmin(stmt.limitVal, rows.count) do
            tinsert(newRows, rows[i])
        end
        rows = newRows
    end

    # Project columns
    resultCols = self:getResultColumns(stmt.columns, tbl, baseAlias, joinTableInfo)
    resultRows = {}
    for _, row in next, rows do
        resultRow = self:projectRow(stmt.columns, row, tbl, baseAlias, joinTableInfo, rows)
        tinsert(resultRows, resultRow)
    end

    return {
        type = "RESULT_SET",
        columns = resultCols,
        rows = resultRows
    }
end

function Executor:performJoins(baseTbl, baseAlias, baseRows, joinTableInfo, stmt)
    currentRows = {}
    # Each element: { baseRow, joinRow1, joinRow2, ... }
    for _, row in next, baseRows do
        tinsert(currentRows, { base = row, joins = {} })
    end

    for ji, jinfo in next, joinTableInfo do
        newRows = {}
        for _, cr in next, currentRows do
            matched = false
            for _, jrow in next, jinfo.tbl.rows do
                ctx = { tables = {}, resolve = resolveColumn }
                ctx.tables[baseAlias] = { tbl = baseTbl, row = cr.base }
                # add previously joined tables
                for pi = 1, ji - 1 do
                    prevInfo = joinTableInfo[pi]
                    ctx.tables[prevInfo.alias] = { tbl = prevInfo.tbl, row = cr.joins[pi] }
                end
                ctx.tables[jinfo.alias] = { tbl = jinfo.tbl, row = jrow }

                pass = true
                if jinfo.join.on then
                    pass = self:evalExpr(jinfo.join.on, ctx)
                end
                if pass then
                    matched = true
                    newJoins = {}
                    for k, v in next, cr.joins do newJoins[k] = v end
                    newJoins[ji] = jrow
                    tinsert(newRows, { base = cr.base, joins = newJoins })
                end
            end
            if not matched and jinfo.join.joinType == "LEFT" then
                newJoins = {}
                for k, v in next, cr.joins do newJoins[k] = v end
                newJoins[ji] = null
                tinsert(newRows, { base = cr.base, joins = newJoins })
            end
        end
        currentRows = newRows
    end

    # Apply WHERE
    if stmt.where then
        filtered = {}
        for _, cr in next, currentRows do
            ctx = { tables = {}, resolve = resolveColumn }
            ctx.tables[baseAlias] = { tbl = baseTbl, row = cr.base }
            for ji, jinfo in next, joinTableInfo do
                ctx.tables[jinfo.alias] = { tbl = jinfo.tbl, row = cr.joins[ji] }
            end
            if self:evalExpr(stmt.where, ctx) then
                tinsert(filtered, cr)
            end
        end
        currentRows = filtered
    end

    # Flatten for simpler downstream processing - store join data in a side table
    # We'll use a combined row approach: base row + metadata
    flatRows = {}
    for _, cr in next, currentRows do
        combined = {}
        # base columns
        for i, v in next, cr.base do combined[i] = v end
        # mark as joined row
        combined.__joins = cr.joins
        combined.__base = cr.base
        tinsert(flatRows, combined)
    end
    return flatRows
end

function Executor:getIndexableColumn(whereNode, tbl)
    if whereNode.kind != "BINOP" or whereNode.op != "=" then return null end
    left = whereNode.left
    right = whereNode.right
    if left.kind == "COLUMN_REF" and (right.kind == "NUMBER_LIT" or right.kind == "STRING_LIT") then
        if tbl.indexes[left.column] then
            return { colName = left.column, side = "left" }
        end
    end
    if right.kind == "COLUMN_REF" and (left.kind == "NUMBER_LIT" or left.kind == "STRING_LIT") then
        if tbl.indexes[right.column] then
            return { colName = right.column, side = "right" }
        end
    end
    return null
end

function Executor:getCompareValue(whereNode, colName)
    left = whereNode.left
    right = whereNode.right
    if left.kind == "COLUMN_REF" and left.column == colName then
        if right.kind == "NUMBER_LIT" then return right.value end
        if right.kind == "STRING_LIT" then return right.value end
    end
    if right.kind == "COLUMN_REF" and right.column == colName then
        if left.kind == "NUMBER_LIT" then return left.value end
        if left.kind == "STRING_LIT" then return left.value end
    end
    return null
end

function Executor:hasAggregates(columns)
    for _, col in next, columns do
        if col.kind == "COLUMN" and col.expr and col.expr.kind == "AGG_FUNC" then
            return true
        end
    end
    return false
end

function Executor:execAggregateNoGroup(stmt, tbl, baseAlias, rows, joinTableInfo)
    resultRow = {}
    resultCols = {}
    for ci, col in next, stmt.columns do
        if col.kind == "COLUMN" and col.expr then
            colAlias = col.alias or sfmt("col%d", ci)
            tinsert(resultCols, colAlias)
            if col.expr.kind == "AGG_FUNC" then
                val = self:computeAggregate(col.expr, rows, tbl, baseAlias, joinTableInfo)
                tinsert(resultRow, val)
            else
                # non-aggregate in aggregate query: take first row value
                if rows.count > 0 then
                    ctx = self:makeCtxForRow(rows[1], tbl, baseAlias, joinTableInfo)
                    tinsert(resultRow, self:evalExpr(col.expr, ctx))
                else
                    tinsert(resultRow, null)
                end
            end
        else if col.kind == "STAR_COL" then
            tinsert(resultCols, "*")
            tinsert(resultRow, null)
        end
    end
    return { type = "RESULT_SET", columns = resultCols, rows = { resultRow } }
end

function Executor:execGroupBy(stmt, tbl, baseAlias, rows, joinTableInfo)
    # Group rows
    groups = {}
    groupOrder = {}
    for _, row in next, rows do
        ctx = self:makeCtxForRow(row, tbl, baseAlias, joinTableInfo)
        keyParts = {}
        for _, gexpr in next, stmt.groupBy do
            val = self:evalExpr(gexpr, ctx)
            tinsert(keyParts, tostring(val))
        end
        gkey = tconcat(keyParts, "\0")
        if not groups[gkey] then
            groups[gkey] = {}
            tinsert(groupOrder, gkey)
        end
        tinsert(groups[gkey], row)
    end

    # Evaluate HAVING and project
    resultCols = {}
    resultRows = {}
    colsBuilt = false

    for _, gkey in next, groupOrder do
        groupRows = groups[gkey]
        firstRow = groupRows[1]
        ctx = self:makeCtxForRow(firstRow, tbl, baseAlias, joinTableInfo)

        # Check HAVING
        passHaving = true
        if stmt.having then
            havingVal = self:evalExprWithAgg(stmt.having, groupRows, tbl, baseAlias, joinTableInfo, ctx)
            if not havingVal then
                passHaving = false
            end
        end

        if passHaving then
            resultRow = {}
            for ci, col in next, stmt.columns do
                if col.kind == "COLUMN" and col.expr then
                    colAlias = col.alias or self:exprToName(col.expr, ci)
                    if not colsBuilt then tinsert(resultCols, colAlias) end
                    if col.expr.kind == "AGG_FUNC" then
                        val = self:computeAggregate(col.expr, groupRows, tbl, baseAlias, joinTableInfo)
                        tinsert(resultRow, val)
                    else
                        tinsert(resultRow, self:evalExpr(col.expr, ctx))
                    end
                end
            end
            colsBuilt = true
            tinsert(resultRows, resultRow)
        end
    end

    # ORDER BY on result
    if stmt.orderBy then
        resultRows = self:applyOrderByResult(stmt.orderBy, resultRows, resultCols, stmt)
    end

    # LIMIT
    if stmt.limitVal then
        limited = {}
        for i = 1, mmin(stmt.limitVal, resultRows.count) do
            tinsert(limited, resultRows[i])
        end
        resultRows = limited
    end

    return { type = "RESULT_SET", columns = resultCols, rows = resultRows }
end

function Executor:makeCtxForRow(row, tbl, baseAlias, joinTableInfo)
    ctx = { tables = {}, resolve = resolveColumn }
    baseRow = row
    if row.__base then baseRow = row.__base end
    ctx.tables[baseAlias] = { tbl = tbl, row = baseRow }
    if row.__joins and joinTableInfo then
        for ji, jinfo in next, joinTableInfo do
            ctx.tables[jinfo.alias] = { tbl = jinfo.tbl, row = row.__joins[ji] }
        end
    end
    return ctx
end

function Executor:computeAggregate(aggNode, groupRows, tbl, baseAlias, joinTableInfo)
    fn = aggNode.func
    if fn == "COUNT" then
        if aggNode.star then
            return groupRows.count
        end
        count = 0
        for _, row in next, groupRows do
            ctx = self:makeCtxForRow(row, tbl, baseAlias, joinTableInfo)
            val = self:evalExpr(aggNode.arg, ctx)
            if val != null then count = count + 1 end
        end
        return count
    else if fn == "SUM" then
        sum = 0
        for _, row in next, groupRows do
            ctx = self:makeCtxForRow(row, tbl, baseAlias, joinTableInfo)
            val = self:evalExpr(aggNode.arg, ctx)
            if type(val) == "number" then sum = sum + val end
        end
        return sum
    else if fn == "AVG" then
        sum = 0
        count = 0
        for _, row in next, groupRows do
            ctx = self:makeCtxForRow(row, tbl, baseAlias, joinTableInfo)
            val = self:evalExpr(aggNode.arg, ctx)
            if type(val) == "number" then
                sum = sum + val
                count = count + 1
            end
        end
        if count == 0 then return null end
        return sum / count
    else if fn == "MIN" then
        result = null
        for _, row in next, groupRows do
            ctx = self:makeCtxForRow(row, tbl, baseAlias, joinTableInfo)
            val = self:evalExpr(aggNode.arg, ctx)
            if val != null and (result == null or val < result) then
                result = val
            end
        end
        return result
    else if fn == "MAX" then
        result = null
        for _, row in next, groupRows do
            ctx = self:makeCtxForRow(row, tbl, baseAlias, joinTableInfo)
            val = self:evalExpr(aggNode.arg, ctx)
            if val != null and (result == null or val > result) then
                result = val
            end
        end
        return result
    end
    return null
end

function Executor:evalExprWithAgg(expr, groupRows, tbl, baseAlias, joinTableInfo, ctx)
    if expr.kind == "AGG_FUNC" then
        return self:computeAggregate(expr, groupRows, tbl, baseAlias, joinTableInfo)
    else if expr.kind == "BINOP" then
        if expr.op == "AND" then
            left = self:evalExprWithAgg(expr.left, groupRows, tbl, baseAlias, joinTableInfo, ctx)
            right = self:evalExprWithAgg(expr.right, groupRows, tbl, baseAlias, joinTableInfo, ctx)
            return left and right
        else if expr.op == "OR" then
            left = self:evalExprWithAgg(expr.left, groupRows, tbl, baseAlias, joinTableInfo, ctx)
            right = self:evalExprWithAgg(expr.right, groupRows, tbl, baseAlias, joinTableInfo, ctx)
            return left or right
        else
            left = self:evalExprWithAgg(expr.left, groupRows, tbl, baseAlias, joinTableInfo, ctx)
            right = self:evalExprWithAgg(expr.right, groupRows, tbl, baseAlias, joinTableInfo, ctx)
            return evalComparison(expr.op, left, right)
        end
    end
    return self:evalExpr(expr, ctx)
end

function Executor:applyOrderBy(orderBy, rows, tbl, baseAlias, joinTableInfo)
    sorted = {}
    for i, r in next, rows do sorted[i] = r end
    tsort(sorted, function(a, b)
        for _, item in next, orderBy do
            ctxA = self:makeCtxForRow(a, tbl, baseAlias, joinTableInfo)
            ctxB = self:makeCtxForRow(b, tbl, baseAlias, joinTableInfo)
            va = self:evalExpr(item.expr, ctxA)
            vb = self:evalExpr(item.expr, ctxB)
            cmp = compareValues(va, vb)
            if cmp != 0 then
                if item.dir == "DESC" then
                    return cmp > 0
                else
                    return cmp < 0
                end
            end
        end
        return false
    end)
    return sorted
end

function Executor:applyOrderByResult(orderBy, resultRows, resultCols, stmt)
    # Map order-by expressions to result column indices
    sorted = {}
    for i, r in next, resultRows do sorted[i] = r end

    # Build column name to index mapping
    colIndexMap = {}
    for i, name in next, resultCols do
        colIndexMap[name] = i
        colIndexMap[slower(name)] = i
    end

    tsort(sorted, function(a, b)
        for _, item in next, orderBy do
            colIdx = null
            if item.expr.kind == "COLUMN_REF" then
                colIdx = colIndexMap[item.expr.column] or colIndexMap[slower(item.expr.column)]
            end
            if colIdx then
                va = a[colIdx]
                vb = b[colIdx]
                cmp = compareValues(va, vb)
                if cmp != 0 then
                    if item.dir == "DESC" then return cmp > 0
                    else return cmp < 0 end
                end
            end
        end
        return false
    end)
    return sorted
end

function Executor:applyDistinct(stmt, rows, tbl, baseAlias, joinTableInfo)
    seen = {}
    result = {}
    for _, row in next, rows do
        projected = self:projectRow(stmt.columns, row, tbl, baseAlias, joinTableInfo, rows)
        key = ""
        for _, v in next, projected do
            key = key .. tostring(v) .. "\0"
        end
        if not seen[key] then
            seen[key] = true
            tinsert(result, row)
        end
    end
    return result
end

function compareValues(a, b)
    if a == null and b == null then return 0 end
    if a == null then return -1 end
    if b == null then return 1 end
    if type(a) == "number" and type(b) == "number" then
        if a < b then return -1 else if a > b then return 1 else return 0 end
    end
    sa = tostring(a)
    sb = tostring(b)
    if sa < sb then return -1 else if sa > sb then return 1 else return 0 end
end

function Executor:getResultColumns(columns, tbl, baseAlias, joinTableInfo)
    result = {}
    for ci, col in next, columns do
        if col.kind == "STAR_COL" then
            for _, c in next, tbl.columns do
                tinsert(result, c.name)
            end
            if joinTableInfo then
                for _, jinfo in next, joinTableInfo do
                    for _, c in next, jinfo.tbl.columns do
                        tinsert(result, jinfo.alias .. "." .. c.name)
                    end
                end
            end
        else if col.kind == "COLUMN" then
            alias = col.alias or self:exprToName(col.expr, ci)
            tinsert(result, alias)
        end
    end
    return result
end

function Executor:exprToName(expr, idx)
    if expr.kind == "COLUMN_REF" then
        if expr.table_name then
            return expr.table_name .. "." .. expr.column
        end
        return expr.column
    else if expr.kind == "AGG_FUNC" then
        if expr.star then return expr.func .. "(*)" end
        return expr.func .. "(" .. self:exprToName(expr.arg, idx) .. ")"
    end
    return sfmt("expr%d", idx)
end

function Executor:projectRow(columns, row, tbl, baseAlias, joinTableInfo, allRows)
    ctx = self:makeCtxForRow(row, tbl, baseAlias, joinTableInfo)
    result = {}
    for _, col in next, columns do
        if col.kind == "STAR_COL" then
            baseRow = row
            if row.__base then baseRow = row.__base end
            for i = 1, tbl.columns.count do
                tinsert(result, baseRow[i])
            end
            if joinTableInfo and row.__joins then
                for ji, jinfo in next, joinTableInfo do
                    jrow = row.__joins[ji]
                    if jrow then
                        for i = 1, jinfo.tbl.columns.count do
                            tinsert(result, jrow[i])
                        end
                    else
                        for _ = 1, jinfo.tbl.columns.count do
                            tinsert(result, null)
                        end
                    end
                end
            end
        else if col.kind == "COLUMN" and col.expr then
            if col.expr.kind == "AGG_FUNC" then
                val = self:computeAggregate(col.expr, allRows, tbl, baseAlias, joinTableInfo)
                tinsert(result, val)
            else
                tinsert(result, self:evalExpr(col.expr, ctx))
            end
        end
    end
    return result
end

function Executor:evalExpr(expr, ctx)
    if expr == null then return null end

    if expr.kind == "NUMBER_LIT" then
        return expr.value
    else if expr.kind == "STRING_LIT" then
        return expr.value
    else if expr.kind == "NULL_LIT" then
        return null
    else if expr.kind == "COLUMN_REF" then
        return ctx:resolve(expr.table_name, expr.column)
    else if expr.kind == "BINOP" then
        return self:evalBinop(expr, ctx)
    else if expr.kind == "UNOP" then
        return self:evalUnop(expr, ctx)
    else if expr.kind == "IN_EXPR" then
        val = self:evalExpr(expr.expr, ctx)
        for _, v in next, expr.values do
            vv = self:evalExpr(v, ctx)
            if val == vv then return true end
        end
        return false
    else if expr.kind == "BETWEEN" then
        val = self:evalExpr(expr.expr, ctx)
        lo = self:evalExpr(expr.lo, ctx)
        hi = self:evalExpr(expr.hi, ctx)
        if val == null or lo == null or hi == null then return false end
        return val >= lo and val <= hi
    else if expr.kind == "FUNC_CALL" then
        return self:evalFuncCall(expr, ctx)
    else if expr.kind == "AGG_FUNC" then
        # When evaluated in a non-aggregate context, just return null or column value
        if expr.arg then
            return self:evalExpr(expr.arg, ctx)
        end
        return null
    end
    return null
end

function Executor:evalBinop(expr, ctx)
    op = expr.op
    if op == "AND" then
        left = self:evalExpr(expr.left, ctx)
        if not left then return false end
        return self:evalExpr(expr.right, ctx) and true or false
    else if op == "OR" then
        left = self:evalExpr(expr.left, ctx)
        if left then return true end
        return self:evalExpr(expr.right, ctx) and true or false
    end

    left = self:evalExpr(expr.left, ctx)
    right = self:evalExpr(expr.right, ctx)

    if op == "+" then
        if type(left) == "number" and type(right) == "number" then return left + right end
        return null
    else if op == "-" then
        if type(left) == "number" and type(right) == "number" then return left - right end
        return null
    else if op == "*" then
        if type(left) == "number" and type(right) == "number" then return left * right end
        return null
    else if op == "/" then
        if type(left) == "number" and type(right) == "number" and right != 0 then return left / right end
        return null
    else if op == "%" then
        if type(left) == "number" and type(right) == "number" and right != 0 then return left % right end
        return null
    end

    return evalComparison(op, left, right)
end

function evalComparison(op, left, right)
    if op == "=" then
        if left == null and right == null then return true end
        return left == right
    else if op == "!=" then
        if left == null and right == null then return false end
        return left != right
    else if op == "<" then
        if left == null or right == null then return false end
        return left < right
    else if op == ">" then
        if left == null or right == null then return false end
        return left > right
    else if op == "<=" then
        if left == null or right == null then return false end
        return left <= right
    else if op == ">=" then
        if left == null or right == null then return false end
        return left >= right
    else if op == "LIKE" then
        return evalLike(left, right)
    else if op == "IS NULL" then
        return left == null
    else if op == "IS NOT NULL" then
        return left != null
    end
    return false
end

function evalLike(str, pattern)
    if str == null or pattern == null then return false end
    str = tostring(str)
    pattern = tostring(pattern)
    # Convert SQL LIKE pattern to Lua pattern
    luaPat = "^"
    for i = 1, slen(pattern) do
        c = ssub(pattern, i, i)
        if c == "%" then
            luaPat = luaPat .. ".*"
        else if c == "_" then
            luaPat = luaPat .. "."
        else if c == "." or c == "(" or c == ")" or c == "[" or c == "]" or c == "^" or c == "$" or c == "+" or c == "-" or c == "?" then
            luaPat = luaPat .. "%" .. c
        else
            luaPat = luaPat .. c
        end
    end
    luaPat = luaPat .. "$"
    return sfind(str, luaPat) != null
end

function Executor:evalUnop(expr, ctx)
    val = self:evalExpr(expr.operand, ctx)
    if expr.op == "NOT" then
        return not val
    else if expr.op == "NEG" then
        if type(val) == "number" then return -val end
        return null
    end
    return null
end

function Executor:evalFuncCall(expr, ctx)
    name = supper(expr.name)
    args = {}
    for _, a in next, expr.args do
        tinsert(args, self:evalExpr(a, ctx))
    end
    if name == "ABS" then
        return mabs(args[1] or 0)
    else if name == "UPPER" then
        return supper(tostring(args[1] or ""))
    else if name == "LOWER" then
        return slower(tostring(args[1] or ""))
    else if name == "LENGTH" then
        return slen(tostring(args[1] or ""))
    else if name == "SUBSTR" or name == "SUBSTRING" then
        s = tostring(args[1] or "")
        start = args[2] or 1
        len = args[3]
        if len then
            return ssub(s, start, start + len - 1)
        end
        return ssub(s, start)
    else if name == "COALESCE" then
        for _, v in next, args do
            if v != null then return v end
        end
        return null
    else if name == "IFNULL" then
        if args[1] != null then return args[1] end
        return args[2]
    else if name == "ROUND" then
        n = args[1] or 0
        d = args[2] or 0
        mult = 10 ^ d
        return floor(n * mult + 0.5) / mult
    else if name == "REPLACE" then
        s = tostring(args[1] or "")
        old = tostring(args[2] or "")
        new = tostring(args[3] or "")
        return string.gsub(s, old, new)
    end
    return null
end

# ===== Data Generation =====
function generateTestData(db, rng)
    # Create users table
    db:createTable("users", {
        { name = "id", colType = "INTEGER", primaryKey = true },
        { name = "name", colType = "TEXT" },
        { name = "email", colType = "TEXT" },
        { name = "age", colType = "INTEGER" },
        { name = "city", colType = "TEXT" },
        { name = "score", colType = "REAL" },
        { name = "active", colType = "INTEGER" }
    })

    # Create products table
    db:createTable("products", {
        { name = "id", colType = "INTEGER", primaryKey = true },
        { name = "name", colType = "TEXT" },
        { name = "category", colType = "TEXT" },
        { name = "price", colType = "REAL" },
        { name = "stock", colType = "INTEGER" },
        { name = "rating", colType = "REAL" }
    })

    # Create orders table
    db:createTable("orders", {
        { name = "id", colType = "INTEGER", primaryKey = true },
        { name = "user_id", colType = "INTEGER" },
        { name = "product_id", colType = "INTEGER" },
        { name = "quantity", colType = "INTEGER" },
        { name = "total", colType = "REAL" },
        { name = "status", colType = "TEXT" },
        { name = "order_date", colType = "TEXT" }
    })

    # Generate users
    firstNames = { "Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Hank",
                         "Ivy", "Jack", "Karen", "Leo", "Mona", "Nick", "Olive", "Paul",
                         "Quinn", "Rose", "Sam", "Tina" }
    lastNames = { "Smith", "Jones", "Brown", "Davis", "Wilson", "Taylor", "Clark",
                        "Hall", "Allen", "Young", "King", "Wright", "Lopez", "Hill", "Green" }
    cities = { "New York", "Los Angeles", "Chicago", "Houston", "Phoenix",
                     "Philadelphia", "San Antonio", "San Diego", "Dallas", "Austin" }

    usersTbl = db:getTable("users")
    for i = 1, 100 do
        firstName = rng:choice(firstNames)
        lastName = rng:choice(lastNames)
        fullName = firstName .. " " .. lastName
        email = slower(firstName) .. "." .. slower(lastName) .. i .. "@example.com"
        age = rng:nextInt(18, 75)
        city = rng:choice(cities)
        score = floor(rng:nextFloat() * 10000) / 100
        active = rng:nextInt(0, 1)
        usersTbl:insertRow({ i, fullName, email, age, city, score, active })
    end

    # Generate products
    categories = { "Electronics", "Books", "Clothing", "Food", "Sports", "Home", "Toys", "Garden" }
    adjectives = { "Premium", "Basic", "Deluxe", "Ultra", "Mini", "Super", "Pro", "Eco" }
    productNouns = { "Widget", "Gadget", "Tool", "Device", "Kit", "Set", "Pack", "Bundle" }

    productsTbl = db:getTable("products")
    for i = 1, 50 do
        adj = rng:choice(adjectives)
        noun = rng:choice(productNouns)
        pname = adj .. " " .. noun .. " " .. i
        category = rng:choice(categories)
        price = floor(rng:nextFloat() * 50000 + 100) / 100
        stock = rng:nextInt(0, 500)
        rating = floor(rng:nextFloat() * 50) / 10
        productsTbl:insertRow({ i, pname, category, price, stock, rating })
    end

    # Generate orders
    statuses = { "pending", "shipped", "delivered", "cancelled", "returned" }
    ordersTbl = db:getTable("orders")
    for i = 1, 200 do
        userId = rng:nextInt(1, 100)
        productId = rng:nextInt(1, 50)
        quantity = rng:nextInt(1, 10)
        productRow = productsTbl.rows[productId]
        price = productRow and productRow[4] or 10.0
        total = floor(price * quantity * 100) / 100
        status = rng:choice(statuses)
        month = rng:nextInt(1, 12)
        day = rng:nextInt(1, 28)
        orderDate = sfmt("2024-%02d-%02d", month, day)
        ordersTbl:insertRow({ i, userId, productId, quantity, total, status, orderDate })
    end

    # Create indexes
    usersTbl:createIndex("id")
    usersTbl:createIndex("city")
    usersTbl:createIndex("age")
    productsTbl:createIndex("id")
    productsTbl:createIndex("category")
    ordersTbl:createIndex("id")
    ordersTbl:createIndex("user_id")
    ordersTbl:createIndex("product_id")
    ordersTbl:createIndex("status")
end

# ===== Checksum Utility =====
function checksumResult(result)
    if result == null then return 0 end
    if result.type == "OK" then
        return slen(result.message)
    end
    if result.type != "RESULT_SET" then return 0 end

    hash = 7
    # Include column names
    for _, col in next, result.columns do
        for i = 1, slen(col) do
            hash = (hash * 31 + sbyte(col, i)) % 1000000007
        end
    end
    # Include row data
    for _, row in next, result.rows do
        for _, val in next, row do
            s = tostring(val)
            for i = 1, slen(s) do
                hash = (hash * 31 + sbyte(s, i)) % 1000000007
            end
        end
        hash = (hash * 17 + row.count) % 1000000007
    end
    hash = (hash * 13 + result.rows.count) % 1000000007
    return hash
end

# ===== Test Queries =====
function getTestQueries()
    queries = {}

    # Query 1: Simple SELECT *
    tinsert(queries, "SELECT * FROM users LIMIT 10")

    # Query 2: SELECT with WHERE
    tinsert(queries, "SELECT name, age, city FROM users WHERE age > 50")

    # Query 3: SELECT with AND
    tinsert(queries, "SELECT name, score FROM users WHERE age >= 30 AND age <= 50 AND active = 1")

    # Query 4: SELECT with OR
    tinsert(queries, "SELECT name, city FROM users WHERE city = 'New York' OR city = 'Chicago'")

    # Query 5: SELECT with LIKE
    tinsert(queries, "SELECT name, email FROM users WHERE name LIKE 'A%'")

    # Query 6: ORDER BY ASC
    tinsert(queries, "SELECT name, score FROM users ORDER BY score ASC LIMIT 15")

    # Query 7: ORDER BY DESC
    tinsert(queries, "SELECT name, age FROM users ORDER BY age DESC LIMIT 10")

    # Query 8: COUNT aggregate
    tinsert(queries, "SELECT COUNT(*) AS total_users FROM users")

    # Query 9: SUM aggregate
    tinsert(queries, "SELECT SUM(score) AS total_score FROM users WHERE active = 1")

    # Query 10: AVG aggregate
    tinsert(queries, "SELECT AVG(age) AS avg_age FROM users")

    # Query 11: MIN/MAX
    tinsert(queries, "SELECT MIN(price) AS cheapest, MAX(price) AS most_expensive FROM products")

    # Query 12: GROUP BY with COUNT
    tinsert(queries, "SELECT city, COUNT(*) AS cnt FROM users GROUP BY city ORDER BY cnt DESC")

    # Query 13: GROUP BY with SUM
    tinsert(queries, "SELECT status, SUM(total) AS revenue FROM orders GROUP BY status")

    # Query 14: GROUP BY with HAVING
    tinsert(queries, "SELECT city, AVG(age) AS avg_age FROM users GROUP BY city HAVING AVG(age) > 35")

    # Query 15: INNER JOIN
    tinsert(queries, "SELECT u.name, o.total, o.status FROM users u INNER JOIN orders o ON u.id = o.user_id WHERE o.total > 100 LIMIT 20")

    # Query 16: JOIN with aggregate
    tinsert(queries, "SELECT u.city, COUNT(*) AS order_count FROM users u INNER JOIN orders o ON u.id = o.user_id GROUP BY u.city")

    # Query 17: Multi-table JOIN
    tinsert(queries, "SELECT u.name, p.name, o.quantity FROM users u INNER JOIN orders o ON u.id = o.user_id INNER JOIN products p ON p.id = o.product_id LIMIT 15")

    # Query 18: IN expression
    tinsert(queries, "SELECT name, category, price FROM products WHERE category IN ('Electronics', 'Books', 'Sports')")

    # Query 19: BETWEEN
    tinsert(queries, "SELECT name, price FROM products WHERE price BETWEEN 50 AND 200 ORDER BY price ASC")

    # Query 20: Complex WHERE with arithmetic
    tinsert(queries, "SELECT name, price, stock, price * stock AS inventory_value FROM products WHERE stock > 100 ORDER BY price DESC LIMIT 10")

    # Query 21: DISTINCT
    tinsert(queries, "SELECT DISTINCT city FROM users ORDER BY city ASC")

    # Query 22: Subexpression in WHERE
    tinsert(queries, "SELECT name, score FROM users WHERE score > 50 AND (city = 'Austin' OR city = 'Dallas')")

    # Query 23: GROUP BY multiple columns
    tinsert(queries, "SELECT city, active, COUNT(*) AS cnt FROM users GROUP BY city, active ORDER BY cnt DESC LIMIT 15")

    # Query 24: Aggregate with JOIN and GROUP BY
    tinsert(queries, "SELECT p.category, SUM(o.total) AS cat_revenue, COUNT(*) AS num_orders FROM products p INNER JOIN orders o ON p.id = o.product_id GROUP BY p.category ORDER BY cat_revenue DESC")

    # Query 25: NOT condition
    tinsert(queries, "SELECT name, age FROM users WHERE NOT age < 40 ORDER BY age ASC LIMIT 10")

    # Query 26: Multiple aggregates
    tinsert(queries, "SELECT city, MIN(age) AS youngest, MAX(age) AS oldest, AVG(score) AS avg_score FROM users GROUP BY city ORDER BY avg_score DESC")

    # Query 27: JOIN with WHERE and ORDER BY
    tinsert(queries, "SELECT u.name, o.total, o.order_date FROM users u INNER JOIN orders o ON u.id = o.user_id WHERE o.status = 'delivered' ORDER BY o.total DESC LIMIT 20")

    # Query 28: Products with high rating and stock
    tinsert(queries, "SELECT name, category, price, rating FROM products WHERE rating > 3 AND stock > 50 ORDER BY rating DESC")

    # Query 29: Count by category with having
    tinsert(queries, "SELECT category, COUNT(*) AS num_products, AVG(price) AS avg_price FROM products GROUP BY category HAVING COUNT(*) > 4")

    # Query 30: Complex join aggregation
    tinsert(queries, "SELECT u.city, SUM(o.total) AS city_revenue, AVG(o.quantity) AS avg_qty FROM users u INNER JOIN orders o ON u.id = o.user_id GROUP BY u.city ORDER BY city_revenue DESC LIMIT 5")

    # Query 31: Users who placed orders for electronics
    tinsert(queries, "SELECT u.name, p.category, o.total FROM users u INNER JOIN orders o ON u.id = o.user_id INNER JOIN products p ON p.id = o.product_id WHERE p.category = 'Electronics' ORDER BY o.total DESC LIMIT 10")

    # Query 32: Score distribution
    tinsert(queries, "SELECT active, COUNT(*) AS cnt, SUM(score) AS total_score, MIN(score) AS min_s, MAX(score) AS max_s FROM users GROUP BY active")

    # Query 33: Order quantities per product
    tinsert(queries, "SELECT p.name, SUM(o.quantity) AS total_qty, COUNT(*) AS order_count FROM products p INNER JOIN orders o ON p.id = o.product_id GROUP BY p.name ORDER BY total_qty DESC LIMIT 10")

    # Query 34: Users with no filter, large offset
    tinsert(queries, "SELECT name, age, city FROM users ORDER BY name ASC LIMIT 10 OFFSET 50")

    # Query 35: Arithmetic in select
    tinsert(queries, "SELECT name, price, stock, price * stock AS value, price * 0.9 AS discounted FROM products WHERE price > 100 ORDER BY value DESC LIMIT 10")

    # Query 36: IS NOT NULL check (all rows have values, but tests the path)
    tinsert(queries, "SELECT name, email FROM users WHERE email IS NOT NULL AND score > 80 ORDER BY score DESC LIMIT 10")

    # Query 37: Multi-condition join
    tinsert(queries, "SELECT u.name, o.status, o.total FROM users u INNER JOIN orders o ON u.id = o.user_id WHERE u.active = 1 AND o.total > 50 ORDER BY o.total DESC LIMIT 15")

    # Query 38: LIKE with middle pattern
    tinsert(queries, "SELECT name, email FROM users WHERE email LIKE '%smith%'")

    # Query 39: Group by order status with totals
    tinsert(queries, "SELECT status, COUNT(*) AS num_orders, SUM(total) AS sum_total, AVG(total) AS avg_total, MAX(total) AS max_total FROM orders GROUP BY status ORDER BY sum_total DESC")

    # Query 40: Complex nested conditions
    tinsert(queries, "SELECT name, age, city, score FROM users WHERE (age > 30 AND score > 50) OR (age < 25 AND city = 'Phoenix') ORDER BY score DESC LIMIT 15")

    return queries
end

# ===== Query Plan / Optimizer =====
# Simple cost-based query plan estimator
QueryPlanner = {}
QueryPlanner.__index = QueryPlanner

function QueryPlanner.new(db)
    return setmetatable({ db = db }, QueryPlanner)
end

function QueryPlanner:estimateCost(stmt)
    if stmt.kind != "SELECT" then return 1 end
    cost = 0

    # Base table scan cost
    if stmt.from then
        tbl = self.db:getTable(stmt.from.name)
        if tbl then
            rowCount = 0
            for _ in next, tbl.rows do rowCount = rowCount + 1 end
            cost = cost + rowCount

            # Check if index can be used
            if stmt.where then
                indexUsable = self:canUseIndex(stmt.where, tbl)
                if indexUsable then
                    cost = cost * 0.1  # index reduces cost significantly
                end
            end
        end
    end

    # JOIN cost estimation (nested loop)
    if stmt.joins then
        for _, join in next, stmt.joins do
            joinTbl = self.db:getTable(join.table.name)
            if joinTbl then
                joinRows = 0
                for _ in next, joinTbl.rows do joinRows = joinRows + 1 end
                cost = cost * joinRows * 0.5
            end
        end
    end

    # GROUP BY cost
    if stmt.groupBy then
        cost = cost + cost * 0.3
    end

    # ORDER BY cost (sort)
    if stmt.orderBy then
        n = mmax(cost, 1)
        cost = cost + n * floor(msqrt(n))  # approximate n*log(n)
    end

    return floor(cost)
end

function QueryPlanner:canUseIndex(whereNode, tbl)
    if whereNode.kind == "BINOP" and whereNode.op == "=" then
        if whereNode.left.kind == "COLUMN_REF" then
            if tbl.indexes[whereNode.left.column] then
                return true
            end
        end
        if whereNode.right.kind == "COLUMN_REF" then
            if tbl.indexes[whereNode.right.column] then
                return true
            end
        end
    end
    if whereNode.kind == "BINOP" and (whereNode.op == "AND" or whereNode.op == "OR") then
        return self:canUseIndex(whereNode.left, tbl) or self:canUseIndex(whereNode.right, tbl)
    end
    return false
end

function QueryPlanner:suggestIndexes(stmt)
    suggestions = {}
    if stmt.kind != "SELECT" then return suggestions end
    if stmt.where then
        self:collectIndexCandidates(stmt.where, suggestions)
    end
    if stmt.joins then
        for _, join in next, stmt.joins do
            if join.on then
                self:collectIndexCandidates(join.on, suggestions)
            end
        end
    end
    return suggestions
end

function QueryPlanner:collectIndexCandidates(node, suggestions)
    if node.kind == "BINOP" then
        if node.op == "=" then
            if node.left.kind == "COLUMN_REF" then
                tinsert(suggestions, { table_name = node.left.table_name, column = node.left.column })
            end
            if node.right.kind == "COLUMN_REF" then
                tinsert(suggestions, { table_name = node.right.table_name, column = node.right.column })
            end
        end
        if node.left then self:collectIndexCandidates(node.left, suggestions) end
        if node.right then self:collectIndexCandidates(node.right, suggestions) end
    end
end

# ===== Statistics Collector =====
# Collects statistics about tables for query optimization
StatsCollector = {}
StatsCollector.__index = StatsCollector

function StatsCollector.new(db)
    return setmetatable({ db = db, stats = {} }, StatsCollector)
end

function StatsCollector:analyze(tableName)
    tbl = self.db:getTable(tableName)
    if not tbl then return null end

    tblStats = {
        rowCount = 0,
        columns = {}
    }

    # Count rows
    for _ in next, tbl.rows do
        tblStats.rowCount = tblStats.rowCount + 1
    end

    # Per-column stats
    for ci, col in next, tbl.columns do
        colStats = {
            name = col.name,
            nullCount = 0,
            distinctCount = 0,
            minVal = null,
            maxVal = null,
            avgVal = null
        }

        distinct = {}
        sum = 0
        numCount = 0

        for _, row in next, tbl.rows do
            val = row[ci]
            if val == null then
                colStats.nullCount = colStats.nullCount + 1
            else
                distinct[tostring(val)] = true
                if type(val) == "number" then
                    sum = sum + val
                    numCount = numCount + 1
                    if colStats.minVal == null or val < colStats.minVal then
                        colStats.minVal = val
                    end
                    if colStats.maxVal == null or val > colStats.maxVal then
                        colStats.maxVal = val
                    end
                else if type(val) == "string" then
                    if colStats.minVal == null or val < colStats.minVal then
                        colStats.minVal = val
                    end
                    if colStats.maxVal == null or val > colStats.maxVal then
                        colStats.maxVal = val
                    end
                end
            end
        end

        dc = 0
        for _ in next, distinct do dc = dc + 1 end
        colStats.distinctCount = dc
        if numCount > 0 then
            colStats.avgVal = sum / numCount
        end
        tblStats.columns[col.name] = colStats
    end

    self.stats[tableName] = tblStats
    return tblStats
end

function StatsCollector:getSelectivity(tableName, colName, op, value)
    tblStats = self.stats[tableName]
    if not tblStats then return 0.5 end
    colStats = tblStats.columns[colName]
    if not colStats then return 0.5 end

    if op == "=" then
        if colStats.distinctCount == 0 then return 0 end
        return 1.0 / colStats.distinctCount
    else if op == "<" or op == "<=" then
        if colStats.minVal == null or colStats.maxVal == null then return 0.5 end
        if type(value) != "number" then return 0.5 end
        range = colStats.maxVal - colStats.minVal
        if range == 0 then return 0.5 end
        return (value - colStats.minVal) / range
    else if op == ">" or op == ">=" then
        if colStats.minVal == null or colStats.maxVal == null then return 0.5 end
        if type(value) != "number" then return 0.5 end
        range = colStats.maxVal - colStats.minVal
        if range == 0 then return 0.5 end
        return (colStats.maxVal - value) / range
    end
    return 0.5
end

# ===== Virtual Table (View-like materialization) =====
VirtualTable = {}
VirtualTable.__index = VirtualTable

function VirtualTable.new(name, query, db)
    return setmetatable({
        name = name,
        query = query,
        db = db
    }, VirtualTable)
end

function VirtualTable:materialize()
    executor = Executor.new(self.db)
    return executor:execute(self.query)
end

# ===== Expression Evaluator Cache =====
# Caches evaluated expressions for repeated evaluation on same row
ExprCache = {}
ExprCache.__index = ExprCache

function ExprCache.new()
    return setmetatable({ cache = {} }, ExprCache)
end

function ExprCache:getKey(expr)
    if expr.kind == "COLUMN_REF" then
        return (expr.table_name or "") .. "." .. expr.column
    else if expr.kind == "NUMBER_LIT" then
        return "N:" .. tostring(expr.value)
    else if expr.kind == "STRING_LIT" then
        return "S:" .. expr.value
    end
    return null  # not cacheable
end

function ExprCache:get(expr)
    key = self:getKey(expr)
    if key and self.cache[key] != null then
        return self.cache[key], true
    end
    return null, false
end

function ExprCache:set(expr, value)
    key = self:getKey(expr)
    if key then
        self.cache[key] = value
    end
end

function ExprCache:clear()
    self.cache = {}
end

# ===== Hash Join Implementation =====
# For equi-joins, hash join is faster than nested loop
HashJoin = {}
HashJoin.__index = HashJoin

function HashJoin.new()
    return setmetatable({}, HashJoin)
end

function HashJoin:execute(leftRows, rightRows, leftKeyFn, rightKeyFn)
    # Build hash table on right side
    hashTable = {}
    for _, rrow in next, rightRows do
        key = rightKeyFn(rrow)
        if key != null then
            keyStr = tostring(key)
            if not hashTable[keyStr] then
                hashTable[keyStr] = {}
            end
            tinsert(hashTable[keyStr], rrow)
        end
    end

    # Probe with left side
    results = {}
    for _, lrow in next, leftRows do
        key = leftKeyFn(lrow)
        if key != null then
            keyStr = tostring(key)
            matches = hashTable[keyStr]
            if matches then
                for _, rrow in next, matches do
                    tinsert(results, { left = lrow, right = rrow })
                end
            end
        end
    end
    return results
end

# ===== Sort-Merge Join =====
SortMergeJoin = {}
SortMergeJoin.__index = SortMergeJoin

function SortMergeJoin.new()
    return setmetatable({}, SortMergeJoin)
end

function SortMergeJoin:execute(leftRows, rightRows, leftKeyFn, rightKeyFn)
    # Sort both sides
    sortedLeft = {}
    for i, r in next, leftRows do sortedLeft[i] = r end
    tsort(sortedLeft, function(a, b)
        ka = leftKeyFn(a)
        kb = leftKeyFn(b)
        return compareValues(ka, kb) < 0
    end)

    sortedRight = {}
    for i, r in next, rightRows do sortedRight[i] = r end
    tsort(sortedRight, function(a, b)
        ka = rightKeyFn(a)
        kb = rightKeyFn(b)
        return compareValues(ka, kb) < 0
    end)

    # Merge
    results = {}
    li = 1
    ri = 1
    while li <= sortedLeft.count and ri <= sortedRight.count do
        lk = leftKeyFn(sortedLeft[li])
        rk = rightKeyFn(sortedRight[ri])
        cmp = compareValues(lk, rk)
        if cmp < 0 then
            li = li + 1
        else if cmp > 0 then
            ri = ri + 1
        else
            # Match: collect all matching from right
            matchStart = ri
            while ri <= sortedRight.count and compareValues(rightKeyFn(sortedRight[ri]), lk) == 0 do
                ri = ri + 1
            end
            # For each matching left row
            while li <= sortedLeft.count and compareValues(leftKeyFn(sortedLeft[li]), lk) == 0 do
                for j = matchStart, ri - 1 do
                    tinsert(results, { left = sortedLeft[li], right = sortedRight[j] })
                end
                li = li + 1
            end
        end
    end
    return results
end

# ===== Buffer Pool / Page Cache Simulation =====
# Simulates a database buffer pool with LRU eviction
BufferPool = {}
BufferPool.__index = BufferPool

function BufferPool.new(capacity)
    return setmetatable({
        capacity = capacity or 64,
        pages = {},
        accessOrder = {},
        hitCount = 0,
        missCount = 0
    }, BufferPool)
end

function BufferPool:get(pageId)
    if self.pages[pageId] then
        self.hitCount = self.hitCount + 1
        self:touch(pageId)
        return self.pages[pageId]
    end
    self.missCount = self.missCount + 1
    return null
end

function BufferPool:put(pageId, data)
    if self.pages[pageId] then
        self.pages[pageId] = data
        self:touch(pageId)
        return
    end
    # Evict if full
    count = 0
    for _ in next, self.pages do count = count + 1 end
    if count >= self.capacity then
        self:evictLRU()
    end
    self.pages[pageId] = data
    tinsert(self.accessOrder, pageId)
end

function BufferPool:touch(pageId)
    for i, id in next, self.accessOrder do
        if id == pageId then
            tremove(self.accessOrder, i)
            tinsert(self.accessOrder, pageId)
            return
        end
    end
    tinsert(self.accessOrder, pageId)
end

function BufferPool:evictLRU()
    if self.accessOrder.count > 0 then
        evictId = self.accessOrder[1]
        tremove(self.accessOrder, 1)
        self.pages[evictId] = null
    end
end

function BufferPool:getHitRate()
    total = self.hitCount + self.missCount
    if total == 0 then return 0 end
    return self.hitCount / total
end

# ===== WAL (Write-Ahead Log) Simulation =====
WAL = {}
WAL.__index = WAL

function WAL.new()
    return setmetatable({
        entries = {},
        lsn = 0,  # log sequence number
        checkpointLSN = 0
    }, WAL)
end

function WAL:append(operation, tableName, data)
    self.lsn = self.lsn + 1
    tinsert(self.entries, {
        lsn = self.lsn,
        op = operation,
        table_name = tableName,
        data = data,
        committed = false
    })
    return self.lsn
end

function WAL:commit(lsn)
    for _, entry in next, self.entries do
        if entry.lsn == lsn then
            entry.committed = true
            break
        end
    end
end

function WAL:checkpoint()
    newEntries = {}
    for _, entry in next, self.entries do
        if not entry.committed then
            tinsert(newEntries, entry)
        end
    end
    self.entries = newEntries
    self.checkpointLSN = self.lsn
end

function WAL:getUncommitted()
    result = {}
    for _, entry in next, self.entries do
        if not entry.committed then
            tinsert(result, entry)
        end
    end
    return result
end

# ===== Transaction Manager =====
TxManager = {}
TxManager.__index = TxManager

function TxManager.new(wal)
    return setmetatable({
        wal = wal,
        nextTxId = 1,
        activeTx = {}
    }, TxManager)
end

function TxManager:begin()
    txId = self.nextTxId
    self.nextTxId = txId + 1
    self.activeTx[txId] = {
        id = txId,
        operations = {},
        startLSN = self.wal.lsn
    }
    return txId
end

function TxManager:addOperation(txId, op, tableName, data)
    tx = self.activeTx[txId]
    if not tx then error("Transaction not found: " .. txId) end
    lsn = self.wal:append(op, tableName, data)
    tinsert(tx.operations, lsn)
    return lsn
end

function TxManager:commit(txId)
    tx = self.activeTx[txId]
    if not tx then error("Transaction not found: " .. txId) end
    for _, lsn in next, tx.operations do
        self.wal:commit(lsn)
    end
    self.activeTx[txId] = null
end

function TxManager:rollback(txId)
    tx = self.activeTx[txId]
    if not tx then return end
    # Mark operations as rolled back (just remove from WAL perspective)
    self.activeTx[txId] = null
end

# ===== Extended B-Tree with bulk loading =====
function BTree:bulkLoad(sortedPairs)
    # For pre-sorted data, build tree bottom-up
    self.root = BTreeNode.new(true)
    for _, kv in next, sortedPairs do
        self:insert(kv[1], kv[2])
    end
end

function BTree:count()
    return btreeCount(self.root)
end

function btreeCount(node)
    if node == null then return 0 end
    c = node.numKeys
    if not node.isLeaf then
        for i = 1, node.numKeys + 1 do
            if node.children[i] then
                c = c + btreeCount(node.children[i])
            end
        end
    end
    return c
end

function BTree:height()
    return btreeHeight(self.root)
end

function btreeHeight(node)
    if node == null then return 0 end
    if node.isLeaf then return 1 end
    return 1 + btreeHeight(node.children[1])
end

function BTree:getAllKeys()
    result = {}
    btreeCollectKeys(self.root, result)
    return result
end

function btreeCollectKeys(node, result)
    if node == null then return end
    if node.isLeaf then
        for i = 1, node.numKeys do
            tinsert(result, node.keys[i])
        end
    else
        for i = 1, node.numKeys do
            btreeCollectKeys(node.children[i], result)
            tinsert(result, node.keys[i])
        end
        btreeCollectKeys(node.children[node.numKeys + 1], result)
    end
end

# ===== Additional test data tables =====
function generateExtendedData(db, rng)
    # Create categories table for normalization tests
    db:createTable("categories", {
        { name = "id", colType = "INTEGER", primaryKey = true },
        { name = "name", colType = "TEXT" },
        { name = "parent_id", colType = "INTEGER" },
        { name = "depth", colType = "INTEGER" }
    })

    catsTbl = db:getTable("categories")
    catNames = { "Electronics", "Books", "Clothing", "Food", "Sports", "Home", "Toys", "Garden",
                       "Computers", "Phones", "Fiction", "NonFiction", "Mens", "Womens", "Organic",
                       "Frozen", "Team", "Individual", "Kitchen", "Bath", "Board", "Outdoor", "Indoor", "Flowers" }
    for i = 1, 24 do
        parentId = 0
        depth = 1
        if i > 8 then
            parentId = rng:nextInt(1, 8)
            depth = 2
        end
        catsTbl:insertRow({ i, catNames[i], parentId, depth })
    end

    # Create reviews table
    db:createTable("reviews", {
        { name = "id", colType = "INTEGER", primaryKey = true },
        { name = "user_id", colType = "INTEGER" },
        { name = "product_id", colType = "INTEGER" },
        { name = "rating", colType = "INTEGER" },
        { name = "comment", colType = "TEXT" }
    })

    reviewsTbl = db:getTable("reviews")
    comments = {
        "Great product!", "Not bad", "Could be better", "Excellent value",
        "Disappointed", "Amazing quality", "Would buy again", "Terrible",
        "Just okay", "Highly recommend", "Waste of money", "Perfect fit",
        "Broke after a week", "Best purchase ever", "Mediocre at best"
    }
    for i = 1, 150 do
        userId = rng:nextInt(1, 100)
        productId = rng:nextInt(1, 50)
        rating = rng:nextInt(1, 5)
        comment = rng:choice(comments)
        reviewsTbl:insertRow({ i, userId, productId, rating, comment })
    end

    # Create indexes on extended tables
    catsTbl:createIndex("id")
    catsTbl:createIndex("parent_id")
    reviewsTbl:createIndex("id")
    reviewsTbl:createIndex("user_id")
    reviewsTbl:createIndex("product_id")
    reviewsTbl:createIndex("rating")
end

# ===== Extended queries =====
function getExtendedQueries()
    queries = {}

    # Query E1: Review statistics per product
    tinsert(queries, "SELECT product_id, COUNT(*) AS num_reviews, AVG(rating) AS avg_rating, MIN(rating) AS min_r, MAX(rating) AS max_r FROM reviews GROUP BY product_id ORDER BY avg_rating DESC LIMIT 10")

    # Query E2: Users with most reviews
    tinsert(queries, "SELECT user_id, COUNT(*) AS review_count FROM reviews GROUP BY user_id HAVING COUNT(*) > 2 ORDER BY review_count DESC")

    # Query E3: Join reviews with users
    tinsert(queries, "SELECT u.name, r.rating, r.comment FROM users u INNER JOIN reviews r ON u.id = r.user_id WHERE r.rating = 5 LIMIT 15")

    # Query E4: Join reviews with products
    tinsert(queries, "SELECT p.name, r.rating, r.comment FROM products p INNER JOIN reviews r ON p.id = r.product_id WHERE r.rating <= 2 ORDER BY r.rating ASC LIMIT 10")

    # Query E5: Categories with children
    tinsert(queries, "SELECT name, depth FROM categories WHERE depth = 2 ORDER BY name ASC")

    # Query E6: Products grouped by price range (via arithmetic)
    tinsert(queries, "SELECT category, COUNT(*) AS cnt, MIN(price) AS min_p, MAX(price) AS max_p FROM products WHERE price > 0 GROUP BY category ORDER BY cnt DESC")

    # Query E7: Orders per user per status
    tinsert(queries, "SELECT user_id, status, COUNT(*) AS cnt, SUM(total) AS sum_total FROM orders GROUP BY user_id, status ORDER BY sum_total DESC LIMIT 20")

    # Query E8: High-value orders with user info
    tinsert(queries, "SELECT u.name, u.city, o.total, o.status FROM users u INNER JOIN orders o ON u.id = o.user_id WHERE o.total > 200 AND u.active = 1 ORDER BY o.total DESC LIMIT 10")

    # Query E9: Product rating distribution
    tinsert(queries, "SELECT rating, COUNT(*) AS cnt FROM reviews GROUP BY rating ORDER BY rating ASC")

    # Query E10: Average order value by city
    tinsert(queries, "SELECT u.city, AVG(o.total) AS avg_order, COUNT(*) AS num_orders FROM users u INNER JOIN orders o ON u.id = o.user_id GROUP BY u.city ORDER BY avg_order DESC")

    # Query E11: Products never ordered (via NOT IN approach using BETWEEN)
    tinsert(queries, "SELECT name, price FROM products WHERE stock BETWEEN 0 AND 5 ORDER BY price DESC")

    # Query E12: LIKE with suffix
    tinsert(queries, "SELECT name, email FROM users WHERE email LIKE '%@example.com' AND age > 40 LIMIT 15")

    # Query E13: Complex multi-join
    tinsert(queries, "SELECT u.name, p.name, r.rating FROM users u INNER JOIN reviews r ON u.id = r.user_id INNER JOIN products p ON p.id = r.product_id WHERE r.rating >= 4 LIMIT 20")

    # Query E14: Arithmetic expressions in group by result
    tinsert(queries, "SELECT category, SUM(price * stock) AS total_inventory FROM products GROUP BY category ORDER BY total_inventory DESC")

    # Query E15: Orders in date range
    tinsert(queries, "SELECT id, user_id, total, order_date FROM orders WHERE order_date > '2024-06-01' AND order_date < '2024-09-01' ORDER BY order_date ASC LIMIT 20")

    return queries
end

# ===== Stress test queries (repeated complex operations) =====
function getStressQueries()
    queries = {}

    # Stress 1: Large GROUP BY
    tinsert(queries, "SELECT user_id, COUNT(*) AS oc, SUM(total) AS st, AVG(total) AS at FROM orders GROUP BY user_id ORDER BY st DESC")

    # Stress 2: Join all three main tables
    tinsert(queries, "SELECT u.city, p.category, SUM(o.quantity) AS total_qty FROM users u INNER JOIN orders o ON u.id = o.user_id INNER JOIN products p ON p.id = o.product_id GROUP BY u.city, p.category ORDER BY total_qty DESC LIMIT 20")

    # Stress 3: Aggregates with having
    tinsert(queries, "SELECT user_id, SUM(total) AS user_total FROM orders GROUP BY user_id HAVING SUM(total) > 500 ORDER BY user_total DESC")

    # Stress 4: Multiple conditions
    tinsert(queries, "SELECT name, age, city, score FROM users WHERE age > 25 AND age < 60 AND score > 20 AND active = 1 ORDER BY score DESC LIMIT 25")

    # Stress 5: Products with reviews join
    tinsert(queries, "SELECT p.name, p.price, COUNT(*) AS rc, AVG(r.rating) AS ar FROM products p INNER JOIN reviews r ON p.id = r.product_id GROUP BY p.name, p.price ORDER BY ar DESC LIMIT 15")

    return queries
end

# ===== B-Tree stress test =====
function btreeStressTest(rng)
    tree = BTree.new()
    checksum = 0

    # Insert 500 random values
    for i = 1, 500 do
        key = rng:nextInt(1, 10000)
        tree:insert(key, i)
    end

    # Search for various keys
    for i = 1, 200 do
        key = rng:nextInt(1, 10000)
        results = tree:search(key)
        checksum = (checksum + results.count * i) % 1000000007
    end

    # Range scans
    for i = 1, 50 do
        lo = rng:nextInt(1, 5000)
        hi = lo + rng:nextInt(100, 2000)
        results = tree:rangeScan(lo, hi)
        checksum = (checksum + results.count * (i + 200)) % 1000000007
    end

    # Verify tree properties
    height = tree:height()
    count = tree:count()
    checksum = (checksum + height * 1000 + count) % 1000000007

    return checksum
end

# ===== Buffer pool stress test =====
function bufferPoolStressTest(rng)
    pool = BufferPool.new(32)
    checksum = 0

    # Simulate page accesses with locality
    for i = 1, 1000 do
        pageId = null
        if rng:nextFloat() < 0.7 then
            # Access recently used page (locality)
            pageId = sfmt("page_%d", rng:nextInt(mmax(1, i - 20), i))
        else
            # Random access
            pageId = sfmt("page_%d", rng:nextInt(1, i))
        end

        data = pool:get(pageId)
        if data == null then
            # Simulate loading page
            data = { id = pageId, content = srep("x", 64), accessed = i }
            pool:put(pageId, data)
        end
        checksum = (checksum + i) % 1000000007
    end

    hitRate = pool:getHitRate()
    checksum = (checksum + floor(hitRate * 10000)) % 1000000007
    return checksum
end

# ===== WAL / Transaction stress test =====
function walStressTest(rng)
    wal = WAL.new()
    txMgr = TxManager.new(wal)
    checksum = 0

    for i = 1, 100 do
        txId = txMgr:begin()
        numOps = rng:nextInt(1, 5)
        for j = 1, numOps do
            op = rng:nextInt(1, 3) == 1 and "INSERT" or (rng:nextInt(1, 2) == 1 and "UPDATE" or "DELETE")
            txMgr:addOperation(txId, op, "test_table", { row = i * 100 + j })
        end
        # 80% commit, 20% rollback
        if rng:nextFloat() < 0.8 then
            txMgr:commit(txId)
        else
            txMgr:rollback(txId)
        end
        checksum = (checksum + wal.lsn) % 1000000007
    end

    # Checkpoint
    wal:checkpoint()
    uncommitted = wal:getUncommitted()
    checksum = (checksum + uncommitted.count * 7) % 1000000007

    return checksum
end

# ===== Hash Join benchmark =====
function hashJoinBenchmark(db)
    usersTbl = db:getTable("users")
    ordersTbl = db:getTable("orders")

    userRows = {}
    for _, row in next, usersTbl.rows do
        tinsert(userRows, row)
    end
    orderRows = {}
    for _, row in next, ordersTbl.rows do
        tinsert(orderRows, row)
    end

    hj = HashJoin.new()
    results = hj:execute(
        userRows, orderRows,
        function(r) return r[1] end,  # users.id
        function(r) return r[2] end   # orders.user_id
    )

    checksum = 0
    for i, r in next, results do
        val = (r.left[1] or 0) + (r.right[5] or 0)  # user id + order total
        checksum = (checksum + floor(val * i)) % 1000000007
    end
    return checksum
end

# ===== Sort-Merge Join benchmark =====
function sortMergeJoinBenchmark(db)
    usersTbl = db:getTable("users")
    ordersTbl = db:getTable("orders")

    userRows = {}
    for _, row in next, usersTbl.rows do
        tinsert(userRows, row)
    end
    orderRows = {}
    for _, row in next, ordersTbl.rows do
        tinsert(orderRows, row)
    end

    smj = SortMergeJoin.new()
    results = smj:execute(
        userRows, orderRows,
        function(r) return r[1] end,  # users.id
        function(r) return r[2] end   # orders.user_id
    )

    checksum = 0
    for i, r in next, results do
        val = (r.left[1] or 0) + (r.right[5] or 0)
        checksum = (checksum + floor(val * i)) % 1000000007
    end
    return checksum
end

# ===== Query Plan cost estimation benchmark =====
function queryPlanBenchmark(db)
    planner = QueryPlanner.new(db)
    queries = getTestQueries()
    checksum = 0

    for qi, sql in next, queries do
        tokenizer = Tokenizer.new(sql)
        tokens = tokenizer:tokenize()
        parser = Parser.new(tokens)
        stmts = parser:parse()
        for _, stmt in next, stmts do
            cost = planner:estimateCost(stmt)
            checksum = (checksum + cost * qi) % 1000000007
            suggestions = planner:suggestIndexes(stmt)
            checksum = (checksum + suggestions.count * qi * 7) % 1000000007
        end
    end
    return checksum
end

# ===== Statistics collector benchmark =====
function statsBenchmark(db)
    collector = StatsCollector.new(db)
    checksum = 0

    collector:analyze("users")
    collector:analyze("products")
    collector:analyze("orders")
    collector:analyze("reviews")
    collector:analyze("categories")

    # Use selectivity estimates
    tests = {
        { "users", "age", "=", 30 },
        { "users", "age", ">", 50 },
        { "users", "age", "<", 25 },
        { "products", "price", "=", 100 },
        { "products", "price", ">", 200 },
        { "orders", "total", "<", 50 },
        { "orders", "total", ">", 300 },
    }

    for i, test in next, tests do
        sel = collector:getSelectivity(test[1], test[2], test[3], test[4])
        checksum = (checksum + floor(sel * 10000) * i) % 1000000007
    end

    # Check row counts
    for tblName, tblStats in next, collector.stats do
        checksum = (checksum + tblStats.rowCount * slen(tblName)) % 1000000007
    end

    return checksum
end

# ===== Run benchmark =====
function runBenchmark()
    numIterations = 5
    totalChecksum = 0
    expectedChecksum = null

    for iter = 1, numIterations do
        rng = PRNG.new(42)
        db = Database.new()
        generateTestData(db, rng)
        generateExtendedData(db, rng)

        executor = Executor.new(db)
        iterChecksum = 0

        # Run main queries
        queries = getTestQueries()
        for qi, sql in next, queries do
            ok, result = pcall(function() return executor:execute(sql) end)
            if not ok then
                error(sfmt("Query %d failed: %s\nSQL: %s", qi, tostring(result), sql))
            end
            cs = checksumResult(result)
            iterChecksum = (iterChecksum + cs * qi) % 1000000007
        end

        # Run extended queries
        extQueries = getExtendedQueries()
        for qi, sql in next, extQueries do
            ok, result = pcall(function() return executor:execute(sql) end)
            if not ok then
                error(sfmt("Extended query %d failed: %s\nSQL: %s", qi, tostring(result), sql))
            end
            cs = checksumResult(result)
            iterChecksum = (iterChecksum + cs * (qi + 100)) % 1000000007
        end

        # Run stress queries
        stressQueries = getStressQueries()
        for qi, sql in next, stressQueries do
            ok, result = pcall(function() return executor:execute(sql) end)
            if not ok then
                error(sfmt("Stress query %d failed: %s\nSQL: %s", qi, tostring(result), sql))
            end
            cs = checksumResult(result)
            iterChecksum = (iterChecksum + cs * (qi + 200)) % 1000000007
        end

        # B-Tree stress test
        btreeCS = btreeStressTest(rng)
        iterChecksum = (iterChecksum + btreeCS) % 1000000007

        # Buffer pool stress test
        bpCS = bufferPoolStressTest(rng)
        iterChecksum = (iterChecksum + bpCS) % 1000000007

        # WAL / Transaction stress test
        walCS = walStressTest(rng)
        iterChecksum = (iterChecksum + walCS) % 1000000007

        # Hash join benchmark
        hjCS = hashJoinBenchmark(db)
        iterChecksum = (iterChecksum + hjCS) % 1000000007

        # Sort-merge join benchmark
        smjCS = sortMergeJoinBenchmark(db)
        iterChecksum = (iterChecksum + smjCS) % 1000000007

        # Query plan benchmark
        qpCS = queryPlanBenchmark(db)
        iterChecksum = (iterChecksum + qpCS) % 1000000007

        # Stats benchmark
        stCS = statsBenchmark(db)
        iterChecksum = (iterChecksum + stCS) % 1000000007

        if expectedChecksum == null then
            expectedChecksum = iterChecksum
        else
            if iterChecksum != expectedChecksum then
                error(sfmt("Checksum mismatch on iteration %d: got %d, expected %d", iter, iterChecksum, expectedChecksum))
            end
        end
        totalChecksum = (totalChecksum + iterChecksum) % 1000000007
    end

    return numIterations, totalChecksum
end

# ===== Main =====
startTime = clock()
iterations, checksum = runBenchmark()
elapsed = clock() - startTime

print(sfmt("SQL benchmark: all %d iterations passed. (checksum=%d, time=%.3fs)", iterations, checksum, elapsed))

if checksum != 489223023 then
    error("Wrong checksum")
end

end

bench.runCode(test, "sql")
