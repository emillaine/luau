# Inline parsing for Markdown (emphasis, code spans, links, images)

ast = require("./ast")

function parseInlines(text: string, refDefs: {[string]: {dest: string, title: string}}?): {ast.Node}
    nodes = {}
    pos = 1
    len = text.count
    currentText = ""

    function flushText()
        if currentText.count > 0 then
            table.insert(nodes, ast.createText(currentText))
            currentText = ""
        end
    end

    while pos <= len do
        ch = string.sub(text, pos, pos)

        if ch == "\\" and pos < len then
            next = string.sub(text, pos + 1, pos + 1)
            if string.find("\\`*_{}[]()#+-.!|~", next, 1, true) then
                currentText ..= next
                pos += 2
            else
                currentText ..= ch
                pos += 1
            end
        else if ch == "`" then
            tickCount = 0
            tickStart = pos
            while pos <= len and string.sub(text, pos, pos) == "`" do
                tickCount += 1
                pos += 1
            end
            closer = string.rep("`", tickCount)
            closePos = string.find(text, closer, pos, true)
            if closePos then
                isClose = true
                if closePos + tickCount <= len and string.sub(text, closePos + tickCount, closePos + tickCount) == "`" then
                    actualEnd = closePos
                    while actualEnd <= len do
                        actualEnd = string.find(text, closer, actualEnd, true)
                        if not actualEnd then
                            isClose = false
                            break
                        end
                        if actualEnd + tickCount > len or string.sub(text, actualEnd + tickCount, actualEnd + tickCount) != "`" then
                            closePos = actualEnd
                            break
                        end
                        actualEnd += 1
                    end
                end
                if isClose and closePos then
                    flushText()
                    code = string.sub(text, pos, closePos - 1)
                    code = string.gsub(code, "\n", " ")
                    if code.count > 1 and string.sub(code, 1, 1) == " " and string.sub(code, -1) == " " then
                        code = string.sub(code, 2, -2)
                    end
                    table.insert(nodes, ast.createCode(code))
                    pos = closePos + tickCount
                else
                    currentText ..= string.sub(text, tickStart, tickStart + tickCount - 1)
                end
            else
                currentText ..= string.sub(text, tickStart, tickStart + tickCount - 1)
            end
        else if (ch == "*" or ch == "_") then
            delimChar = ch
            delimCount = 0
            delimStart = pos
            while pos <= len and string.sub(text, pos, pos) == delimChar do
                delimCount += 1
                pos += 1
            end

            canOpen = pos <= len and string.sub(text, pos, pos) != " "
            canClose = delimStart > 1 and string.sub(text, delimStart - 1, delimStart - 1) != " "

            if delimCount >= 2 and canOpen then
                closePattern = string.rep(delimChar, 2)
                closePos = string.find(text, closePattern, pos, true)
                if closePos then
                    flushText()
                    innerText = string.sub(text, pos, closePos - 1)
                    strong = ast.createStrong()
                    innerNodes = parseInlines(innerText, refDefs)
                    for _, n in innerNodes do
                        ast.addChild(strong, n)
                    end
                    table.insert(nodes, strong)
                    pos = closePos + 2
                    if delimCount > 2 then
                        currentText ..= string.rep(delimChar, delimCount - 2)
                    end
                else
                    currentText ..= string.rep(delimChar, delimCount)
                end
            else if delimCount >= 1 and canOpen then
                closePos = string.find(text, delimChar, pos, true)
                if closePos then
                    flushText()
                    innerText = string.sub(text, pos, closePos - 1)
                    em = ast.createEmphasis()
                    innerNodes = parseInlines(innerText, refDefs)
                    for _, n in innerNodes do
                        ast.addChild(em, n)
                    end
                    table.insert(nodes, em)
                    pos = closePos + 1
                    if delimCount > 1 then
                        currentText ..= string.rep(delimChar, delimCount - 1)
                    end
                else
                    currentText ..= string.rep(delimChar, delimCount)
                end
            else
                currentText ..= string.rep(delimChar, delimCount)
            end
        else if ch == "[" or (ch == "!" and pos < len and string.sub(text, pos + 1, pos + 1) == "[") then
            isImage = ch == "!"
            labelStart = if isImage then pos + 2 else pos + 1
            bracketDepth = 1
            labelEnd = labelStart
            while labelEnd <= len and bracketDepth > 0 do
                bc = string.sub(text, labelEnd, labelEnd)
                if bc == "[" then bracketDepth += 1
                else if bc == "]" then bracketDepth -= 1
                end
                if bracketDepth > 0 then labelEnd += 1 end
            end

            if bracketDepth == 0 and labelEnd <= len then
                label = string.sub(text, labelStart, labelEnd - 1)
                afterLabel = labelEnd + 1
                if afterLabel <= len and string.sub(text, afterLabel, afterLabel) == "(" then
                    parenEnd = string.find(text, ")", afterLabel, true)
                    if parenEnd then
                        linkContent = string.sub(text, afterLabel + 1, parenEnd - 1)
                        dest = linkContent
                        title = ""
                        titleMatch = string.match(linkContent, '^(.-)%s+"(.-)"$')
                        if titleMatch then
                            dest = titleMatch
                            title = string.match(linkContent, '"(.-)"$') or ""
                        end
                        dest = string.gsub(dest, "^%s+", "")
                        dest = string.gsub(dest, "%s+$", "")
                        if string.sub(dest, 1, 1) == "<" and string.sub(dest, -1) == ">" then
                            dest = string.sub(dest, 2, -2)
                        end

                        flushText()
                        node = null
                        if isImage then
                            node = ast.createImage(dest, title)
                            ast.addChild(node, ast.createText(label))
                        else
                            node = ast.createLink(dest, title)
                            linkInlines = parseInlines(label, refDefs)
                            for _, n in linkInlines do
                                ast.addChild(node, n)
                            end
                        end
                        table.insert(nodes, node)
                        pos = parenEnd + 1
                    else
                        currentText ..= ch
                        pos = if isImage then pos + 1 else pos + 1
                    end
                else if afterLabel <= len and string.sub(text, afterLabel, afterLabel) == "[" then
                    refEnd = string.find(text, "]", afterLabel + 1, true)
                    if refEnd then
                        refLabel = string.sub(text, afterLabel + 1, refEnd - 1)
                        if refLabel == "" then refLabel = label end
                        ref = refDefs and refDefs[string.lower(refLabel)]
                        if ref then
                            flushText()
                            node = null
                            if isImage then
                                node = ast.createImage(ref.dest, ref.title)
                                ast.addChild(node, ast.createText(label))
                            else
                                node = ast.createLink(ref.dest, ref.title)
                                linkInlines = parseInlines(label, refDefs)
                                for _, n in linkInlines do
                                    ast.addChild(node, n)
                                end
                            end
                            table.insert(nodes, node)
                            pos = refEnd + 1
                        else
                            currentText ..= ch
                            pos += 1
                        end
                    else
                        currentText ..= ch
                        pos += 1
                    end
                else
                    ref = refDefs and refDefs[string.lower(label)]
                    if ref then
                        flushText()
                        node = null
                        if isImage then
                            node = ast.createImage(ref.dest, ref.title)
                            ast.addChild(node, ast.createText(label))
                        else
                            node = ast.createLink(ref.dest, ref.title)
                            linkInlines = parseInlines(label, refDefs)
                            for _, n in linkInlines do
                                ast.addChild(node, n)
                            end
                        end
                        table.insert(nodes, node)
                        pos = afterLabel
                    else
                        currentText ..= ch
                        pos += 1
                    end
                end
            else
                currentText ..= ch
                pos += 1
            end
        else if ch == "&" then
            entity = string.match(text, "^&(#?%w+);", pos)
            if entity then
                decoded = ""
                if string.sub(entity, 1, 1) == "#" then
                    numStr = string.sub(entity, 2)
                    num = null
                    if string.sub(numStr, 1, 1) == "x" or string.sub(numStr, 1, 1) == "X" then
                        num = tonumber(string.sub(numStr, 2), 16)
                    else
                        num = tonumber(numStr)
                    end
                    if num and num > 0 and num < 128 then
                        decoded = string.char(num)
                    else
                        decoded = "&" .. entity .. ";"
                    end
                else
                    entities = {
                        amp = "&", lt = "<", gt = ">", quot = '"',
                        apos = "'", nbsp = " ", copy = "(c)", reg = "(r)",
                    }
                    decoded = entities[entity] or ("&" .. entity .. ";")
                end
                currentText ..= decoded
                pos += entity.count + 2
            else
                currentText ..= ch
                pos += 1
            end
        else if ch == "<" then
            autolink = string.match(text, "^<([%w]+://[^>]+)>", pos)
            if autolink then
                flushText()
                link = ast.createLink(autolink, "")
                ast.addChild(link, ast.createText(autolink))
                table.insert(nodes, link)
                pos += autolink.count + 2
            else
                emailLink = string.match(text, "^<([%w%.%-]+@[%w%.%-]+)>", pos)
                if emailLink then
                    flushText()
                    link = ast.createLink("mailto:" .. emailLink, "")
                    ast.addChild(link, ast.createText(emailLink))
                    table.insert(nodes, link)
                    pos += emailLink.count + 2
                else
                    currentText ..= ch
                    pos += 1
                end
            end
        else if ch == "\n" then
            if currentText.count >= 2 and string.sub(currentText, -2) == "  " then
                currentText = string.sub(currentText, 1, -3)
                flushText()
                table.insert(nodes, ast.createHardBreak())
            else
                flushText()
                table.insert(nodes, ast.createSoftBreak())
            end
            pos += 1
        else
            currentText ..= ch
            pos += 1
        end
    end

    flushText()
    return nodes
end

return {
    parseInlines = parseInlines,
}
