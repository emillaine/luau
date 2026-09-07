# AST node types for CommonMark-like parser

export type Node = {
    type: string,
    children: {Node},
    content: string,
    level: number,
    info: string,
    tight: boolean,
    start: number,
    delimiter: string,
    title: string,
    destination: string,
    label: string,
}

function createNode(nodeType: string): Node
    return {
        type = nodeType,
        children = {},
        content = "",
        level = 0,
        info = "",
        tight = true,
        start = 1,
        delimiter = "",
        title = "",
        destination = "",
        label = "",
    }
end

function addChild(parent: Node, child: Node)
    table.insert(parent.children, child)
end

function createDocument(): Node
    return createNode("document")
end

function createParagraph(content: string): Node
    n = createNode("paragraph")
    n.content = content
    return n
end

function createHeading(level: number, content: string): Node
    n = createNode("heading")
    n.level = level
    n.content = content
    return n
end

function createCodeBlock(content: string, info: string): Node
    n = createNode("code_block")
    n.content = content
    n.info = info
    return n
end

function createBlockquote(): Node
    return createNode("blockquote")
end

function createList(ordered: boolean, start: number): Node
    n = createNode(if ordered then "ordered_list" else "bullet_list")
    n.start = start
    return n
end

function createListItem(): Node
    return createNode("list_item")
end

function createThematicBreak(): Node
    return createNode("thematic_break")
end

function createText(text: string): Node
    n = createNode("text")
    n.content = text
    return n
end

function createEmphasis(): Node
    return createNode("emphasis")
end

function createStrong(): Node
    return createNode("strong")
end

function createCode(content: string): Node
    n = createNode("code")
    n.content = content
    return n
end

function createLink(dest: string, title: string): Node
    n = createNode("link")
    n.destination = dest
    n.title = title
    return n
end

function createImage(dest: string, title: string): Node
    n = createNode("image")
    n.destination = dest
    n.title = title
    return n
end

function createHtmlBlock(content: string): Node
    n = createNode("html_block")
    n.content = content
    return n
end

function createSoftBreak(): Node
    return createNode("softbreak")
end

function createHardBreak(): Node
    return createNode("hardbreak")
end

return {
    createNode = createNode,
    addChild = addChild,
    createDocument = createDocument,
    createParagraph = createParagraph,
    createHeading = createHeading,
    createCodeBlock = createCodeBlock,
    createBlockquote = createBlockquote,
    createList = createList,
    createListItem = createListItem,
    createThematicBreak = createThematicBreak,
    createText = createText,
    createEmphasis = createEmphasis,
    createStrong = createStrong,
    createCode = createCode,
    createLink = createLink,
    createImage = createImage,
    createHtmlBlock = createHtmlBlock,
    createSoftBreak = createSoftBreak,
    createHardBreak = createHardBreak,
}
