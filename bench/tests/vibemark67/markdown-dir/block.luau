-- Block-level parsing for Markdown

ast = require("./ast")

function trimRight(s: string): string
    return (string.gsub(s, "%s+$", ""))
end

function trimLeft(s: string): string
    return (string.gsub(s, "^%s+", ""))
end

function trim(s: string): string
    return trimLeft(trimRight(s))
end

function startsWith(s: string, prefix: string): boolean
    return string.sub(s, 1, #prefix) == prefix
end

function countLeading(line: string, char: string): number
    count = 0
    for i = 1, #line do
        if string.sub(line, i, i) == char then
            count += 1
        else
            break
        end
    end
    return count
end

function isBlankLine(line: string): boolean
    return trim(line) == ""
end

function isThematicBreak(line: string): boolean
    stripped = string.gsub(trim(line), " ", "")
    if #stripped < 3 then return false end
    ch = string.sub(stripped, 1, 1)
    if ch != "*" and ch != "-" and ch != "_" then return false end
    for i = 1, #stripped do
        if string.sub(stripped, i, i) != ch then return false end
    end
    return true
end

function isATXHeading(line: string): (number?, string?)
    trimmed = trimLeft(line)
    indent = #line - #trimmed
    if indent > 3 then return null, null end
    level = countLeading(trimmed, "#")
    if level < 1 or level > 6 then return null, null end
    if #trimmed > level and string.sub(trimmed, level + 1, level + 1) != " " then
        return null, null
    end
    content = trim(string.sub(trimmed, level + 1))
    content = string.gsub(content, "%s+#+%s*$", "")
    content = string.gsub(content, "^#+$", "")
    return level, content
end

function isFencedCodeStart(line: string): (string?, string?)
    trimmed = trimLeft(line)
    indent = #line - #trimmed
    if indent > 3 then return null, null end
    ch = string.sub(trimmed, 1, 1)
    if ch != "`" and ch != "~" then return null, null end
    fenceLen = countLeading(trimmed, ch)
    if fenceLen < 3 then return null, null end
    fence = string.rep(ch, fenceLen)
    info = trim(string.sub(trimmed, fenceLen + 1))
    if ch == "`" and string.find(info, "`") then return null, null end
    return fence, info
end

function isFencedCodeEnd(line: string, fence: string): boolean
    trimmed = trimLeft(line)
    indent = #line - #trimmed
    if indent > 3 then return false end
    ch = string.sub(fence, 1, 1)
    fenceLen = countLeading(trimmed, ch)
    if fenceLen < #fence then return false end
    rest = trim(string.sub(trimmed, fenceLen + 1))
    return rest == ""
end

function isBlockquoteLine(line: string): (boolean, string)
    trimmed = trimLeft(line)
    indent = #line - #trimmed
    if indent > 3 then return false, line end
    if string.sub(trimmed, 1, 1) == ">" then
        rest = string.sub(trimmed, 2)
        if string.sub(rest, 1, 1) == " " then
            rest = string.sub(rest, 2)
        end
        return true, rest
    end
    return false, line
end

function isOrderedListItem(line: string): (number?, string?)
    trimmed = trimLeft(line)
    indent = #line - #trimmed
    if indent > 3 then return null, null end
    num, rest = string.match(trimmed, "^(%d+)([%.%)])")
    if num and rest then
        afterMarker = string.sub(trimmed, #num + 2)
        if afterMarker == "" or string.sub(afterMarker, 1, 1) == " " then
            content = if #afterMarker > 0 then string.sub(afterMarker, 2) else ""
            return tonumber(num), content
        end
    end
    return null, null
end

function isBulletListItem(line: string): (string?, string?)
    trimmed = trimLeft(line)
    indent = #line - #trimmed
    if indent > 3 then return null, null end
    ch = string.sub(trimmed, 1, 1)
    if ch == "-" or ch == "*" or ch == "+" then
        if #trimmed == 1 then return ch, "" end
        if string.sub(trimmed, 2, 2) == " " then
            return ch, string.sub(trimmed, 3)
        end
    end
    return null, null
end

function isSetextHeading(line: string): number?
    trimmed = trim(line)
    if #trimmed == 0 then return null end
    ch = string.sub(trimmed, 1, 1)
    if ch != "=" and ch != "-" then return null end
    for i = 1, #trimmed do
        if string.sub(trimmed, i, i) != ch then return null end
    end
    return if ch == "=" then 1 else 2
end

export type BlockParser = {
    lines: {string},
    pos: number,
    refDefs: {[string]: {dest: string, title: string}},
}

function createBlockParser(text: string): BlockParser
    lines = {}
    current = 1
    while current <= #text do
        nlPos = string.find(text, "\n", current, true)
        if nlPos then
            table.insert(lines, string.sub(text, current, nlPos - 1))
            current = nlPos + 1
        else
            table.insert(lines, string.sub(text, current))
            current = #text + 1
        end
    end
    return {
        lines = lines,
        pos = 1,
        refDefs = {},
    }
end

function parseLinkRef(parser: BlockParser, startPos: number): boolean
    line = parser.lines[startPos]
    if not line then return false end
    label = string.match(line, "^%[([^%]]+)%]:%s*(.+)")
    if not label then return false end
    rest = string.match(line, "^%[[^%]]+%]:%s*(.+)")
    if not rest then return false end
    dest = string.match(rest, "^<?([^>%s]+)>?")
    if not dest then return false end
    parser.refDefs[string.lower(label)] = {dest = dest, title = ""}
    parser.pos = startPos + 1
    return true
end

function parseBlocks(parser: BlockParser): ast.Node
    doc = ast.createDocument()

    while parser.pos <= #parser.lines do
        line = parser.lines[parser.pos]

        if isBlankLine(line) then
            parser.pos += 1
        else if isThematicBreak(line) then
            ast.addChild(doc, ast.createThematicBreak())
            parser.pos += 1
        else
            level, content = isATXHeading(line)
            if level and content then
                ast.addChild(doc, ast.createHeading(level, content))
                parser.pos += 1
            else
                fence, info = isFencedCodeStart(line)
                if fence and info then
                    parser.pos += 1
                    codeLines = {}
                    while parser.pos <= #parser.lines do
                        codeLine = parser.lines[parser.pos]
                        if isFencedCodeEnd(codeLine, fence) then
                            parser.pos += 1
                            break
                        end
                        table.insert(codeLines, codeLine)
                        parser.pos += 1
                    end
                    ast.addChild(doc, ast.createCodeBlock(table.concat(codeLines, "\n"), info))
                else
                    isQuote, quoteContent = isBlockquoteLine(line)
                    if isQuote then
                        quoteLines = {}
                        while parser.pos <= #parser.lines do
                            ql = parser.lines[parser.pos]
                            isQ, qc = isBlockquoteLine(ql)
                            if isQ then
                                table.insert(quoteLines, qc)
                                parser.pos += 1
                            else if not isBlankLine(ql) then
                                table.insert(quoteLines, ql)
                                parser.pos += 1
                            else
                                break
                            end
                        end
                        subParser = createBlockParser(table.concat(quoteLines, "\n"))
                        subDoc = parseBlocks(subParser)
                        bq = ast.createBlockquote()
                        for _, child in subDoc.children do
                            ast.addChild(bq, child)
                        end
                        ast.addChild(doc, bq)
                    else
                        bullet, bulletContent = isBulletListItem(line)
                        if bullet then
                            list = ast.createList(false, 1)
                            while parser.pos <= #parser.lines do
                                ll = parser.lines[parser.pos]
                                b, bc = isBulletListItem(ll)
                                if b then
                                    item = ast.createListItem()
                                    itemLines = {bc}
                                    parser.pos += 1
                                    while parser.pos <= #parser.lines do
                                        il = parser.lines[parser.pos]
                                        if isBlankLine(il) then
                                            list.tight = false
                                            parser.pos += 1
                                            break
                                        end
                                        nb, _ = isBulletListItem(il)
                                        if nb then break end
                                        table.insert(itemLines, trimLeft(il))
                                        parser.pos += 1
                                    end
                                    itemParser = createBlockParser(table.concat(itemLines, "\n"))
                                    itemDoc = parseBlocks(itemParser)
                                    for _, child in itemDoc.children do
                                        ast.addChild(item, child)
                                    end
                                    ast.addChild(list, item)
                                else
                                    break
                                end
                            end
                            ast.addChild(doc, list)
                        else
                            num, olContent = isOrderedListItem(line)
                            if num then
                                list = ast.createList(true, num)
                                while parser.pos <= #parser.lines do
                                    ll = parser.lines[parser.pos]
                                    n, oc = isOrderedListItem(ll)
                                    if n then
                                        item = ast.createListItem()
                                        itemLines = {oc}
                                        parser.pos += 1
                                        while parser.pos <= #parser.lines do
                                            il = parser.lines[parser.pos]
                                            if isBlankLine(il) then
                                                list.tight = false
                                                parser.pos += 1
                                                break
                                            end
                                            nn, _ = isOrderedListItem(il)
                                            if nn then break end
                                            table.insert(itemLines, trimLeft(il))
                                            parser.pos += 1
                                        end
                                        itemParser = createBlockParser(table.concat(itemLines, "\n"))
                                        itemDoc = parseBlocks(itemParser)
                                        for _, child in itemDoc.children do
                                            ast.addChild(item, child)
                                        end
                                        ast.addChild(list, item)
                                    else
                                        break
                                    end
                                end
                                ast.addChild(doc, list)
                            else
                                if not parseLinkRef(parser, parser.pos) then
                                    paraLines = {}
                                    while parser.pos <= #parser.lines do
                                        pl = parser.lines[parser.pos]
                                        if isBlankLine(pl) then break end
                                        if isThematicBreak(pl) then break end
                                        h, _ = isATXHeading(pl)
                                        if h then break end
                                        f, _ = isFencedCodeStart(pl)
                                        if f then break end
                                        bul, _ = isBulletListItem(pl)
                                        if bul then break end
                                        oNum, _ = isOrderedListItem(pl)
                                        if oNum then break end

                                        if #paraLines > 0 then
                                            setextLevel = isSetextHeading(pl)
                                            if setextLevel then
                                                headingContent = table.concat(paraLines, " ")
                                                ast.addChild(doc, ast.createHeading(setextLevel, trim(headingContent)))
                                                parser.pos += 1
                                                paraLines = {}
                                                break
                                            end
                                        end

                                        table.insert(paraLines, pl)
                                        parser.pos += 1
                                    end
                                    if #paraLines > 0 then
                                        content = table.concat(paraLines, "\n")
                                        ast.addChild(doc, ast.createParagraph(trim(content)))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return doc
end

return {
    createBlockParser = createBlockParser,
    parseBlocks = parseBlocks,
}
