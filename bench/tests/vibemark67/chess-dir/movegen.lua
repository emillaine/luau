# Move generation for chess

boardMod = require("./board")
Board = boardMod.Board
EMPTY = boardMod.EMPTY
PAWN = boardMod.PAWN
KNIGHT = boardMod.KNIGHT
BISHOP = boardMod.BISHOP
ROOK = boardMod.ROOK
QUEEN = boardMod.QUEEN
KING = boardMod.KING
WHITE = boardMod.WHITE
BLACK = boardMod.BLACK
WK_CASTLE = boardMod.WK_CASTLE
WQ_CASTLE = boardMod.WQ_CASTLE
BK_CASTLE = boardMod.BK_CASTLE
BQ_CASTLE = boardMod.BQ_CASTLE

export type Move = {
    from: number,
    to: number,
    promotion: number,
    capture: number,
    flags: number, # 1=castle, 2=ep, 4=double push
}

FLAG_CASTLE = 1
FLAG_EP = 2
FLAG_DOUBLE = 4

knightOffsets = {-17, -15, -10, -6, 6, 10, 15, 17}
bishopDirs = {-9, -7, 7, 9}
rookDirs = {-8, -1, 1, 8}
queenDirs = {-9, -8, -7, -1, 1, 7, 8, 9}
kingDirs = {-9, -8, -7, -1, 1, 7, 8, 9}

function isOnBoard(sq: number): boolean
    return sq >= 1 and sq <= 64
end

function sameRankOrValid(from: number, to: number, dir: number): boolean
    fromFile = ((from - 1) % 8) + 1
    toFile = ((to - 1) % 8) + 1
    fileDiff = math.abs(toFile - fromFile)
    if dir == -1 or dir == 1 then
        return fileDiff == 1
    end
    if dir == -8 or dir == 8 then
        return fileDiff == 0
    end
    return fileDiff <= 1
end

function knightValid(from: number, to: number): boolean
    if not isOnBoard(to) then return false end
    fromFile = ((from - 1) % 8) + 1
    fromRank = math.floor((from - 1) / 8) + 1
    toFile = ((to - 1) % 8) + 1
    toRank = math.floor((to - 1) / 8) + 1
    fd = math.abs(toFile - fromFile)
    rd = math.abs(toRank - fromRank)
    return (fd == 1 and rd == 2) or (fd == 2 and rd == 1)
end

function addMove(moves: {Move}, from: number, to: number, capture: number, promotion: number, flags: number)
    table.insert(moves, {
        from = from,
        to = to,
        promotion = promotion,
        capture = capture,
        flags = flags,
    })
end

function generatePawnMoves(board: boardMod.Board, moves: {Move}, sq: number, color: number)
    dir = if color == WHITE then 8 else -8
    startRank = if color == WHITE then 2 else 7
    promoRank = if color == WHITE then 8 else 1
    enemy = if color == WHITE then BLACK else WHITE
    rank = math.floor((sq - 1) / 8) + 1
    file = ((sq - 1) % 8) + 1

    forward = sq + dir
    if isOnBoard(forward) and board.squares[forward] == EMPTY then
        toRank = math.floor((forward - 1) / 8) + 1
        if toRank == promoRank then
            for _, promo in {QUEEN, ROOK, BISHOP, KNIGHT} do
                addMove(moves, sq, forward, EMPTY, promo, 0)
            end
        else
            addMove(moves, sq, forward, EMPTY, 0, 0)
            if rank == startRank then
                double = sq + dir * 2
                if board.squares[double] == EMPTY then
                    addMove(moves, sq, double, EMPTY, 0, FLAG_DOUBLE)
                end
            end
        end
    end

    for _, captDir in {dir - 1, dir + 1} do
        target = sq + captDir
        if isOnBoard(target) then
            tf = ((target - 1) % 8) + 1
            if math.abs(tf - file) == 1 then
                piece = board.squares[target]
                if piece != EMPTY and bit32.band(piece, 24) == enemy then
                    toRank = math.floor((target - 1) / 8) + 1
                    if toRank == promoRank then
                        for _, promo in {QUEEN, ROOK, BISHOP, KNIGHT} do
                            addMove(moves, sq, target, piece, promo, 0)
                        end
                    else
                        addMove(moves, sq, target, piece, 0, 0)
                    end
                else if target == board.epSquare then
                    epPawn = bit32.bor(enemy, PAWN)
                    addMove(moves, sq, target, epPawn, 0, FLAG_EP)
                end
            end
        end
    end
end

function generateSlidingMoves(board: boardMod.Board, moves: {Move}, sq: number, color: number, dirs: {number})
    enemy = if color == WHITE then BLACK else WHITE
    for _, dir in dirs do
        current = sq
        while true do
            next = current + dir
            if not isOnBoard(next) then break end
            if not sameRankOrValid(current, next, dir) then break end
            piece = board.squares[next]
            if piece == EMPTY then
                addMove(moves, sq, next, EMPTY, 0, 0)
            else if bit32.band(piece, 24) == enemy then
                addMove(moves, sq, next, piece, 0, 0)
                break
            else
                break
            end
            current = next
        end
    end
end

function generateKnightMoves(board: boardMod.Board, moves: {Move}, sq: number, color: number)
    enemy = if color == WHITE then BLACK else WHITE
    for _, offset in knightOffsets do
        target = sq + offset
        if knightValid(sq, target) then
            piece = board.squares[target]
            if piece == EMPTY then
                addMove(moves, sq, target, EMPTY, 0, 0)
            else if bit32.band(piece, 24) == enemy then
                addMove(moves, sq, target, piece, 0, 0)
            end
        end
    end
end

function generateKingMoves(board: boardMod.Board, moves: {Move}, sq: number, color: number)
    enemy = if color == WHITE then BLACK else WHITE
    for _, dir in kingDirs do
        target = sq + dir
        if isOnBoard(target) and sameRankOrValid(sq, target, dir) then
            piece = board.squares[target]
            if piece == EMPTY then
                addMove(moves, sq, target, EMPTY, 0, 0)
            else if bit32.band(piece, 24) == enemy then
                addMove(moves, sq, target, piece, 0, 0)
            end
        end
    end

    if color == WHITE then
        if bit32.band(board.castling, WK_CASTLE) != 0 then
            if board.squares[6] == EMPTY and board.squares[7] == EMPTY then
                addMove(moves, sq, 7, EMPTY, 0, FLAG_CASTLE)
            end
        end
        if bit32.band(board.castling, WQ_CASTLE) != 0 then
            if board.squares[4] == EMPTY and board.squares[3] == EMPTY and board.squares[2] == EMPTY then
                addMove(moves, sq, 3, EMPTY, 0, FLAG_CASTLE)
            end
        end
    else
        if bit32.band(board.castling, BK_CASTLE) != 0 then
            if board.squares[62] == EMPTY and board.squares[63] == EMPTY then
                addMove(moves, sq, 63, EMPTY, 0, FLAG_CASTLE)
            end
        end
        if bit32.band(board.castling, BQ_CASTLE) != 0 then
            if board.squares[60] == EMPTY and board.squares[59] == EMPTY and board.squares[58] == EMPTY then
                addMove(moves, sq, 59, EMPTY, 0, FLAG_CASTLE)
            end
        end
    end
end

function generatePseudoLegalMoves(board: boardMod.Board): {Move}
    moves = {}
    color = board:friendlyColor()
    for sq = 1, 64 do
        piece = board.squares[sq]
        if piece != EMPTY and bit32.band(piece, 24) == color then
            ptype = bit32.band(piece, 7)
            if ptype == PAWN then
                generatePawnMoves(board, moves, sq, color)
            else if ptype == KNIGHT then
                generateKnightMoves(board, moves, sq, color)
            else if ptype == BISHOP then
                generateSlidingMoves(board, moves, sq, color, bishopDirs)
            else if ptype == ROOK then
                generateSlidingMoves(board, moves, sq, color, rookDirs)
            else if ptype == QUEEN then
                generateSlidingMoves(board, moves, sq, color, queenDirs)
            else if ptype == KING then
                generateKingMoves(board, moves, sq, color)
            end
        end
    end
    return moves
end

function isSquareAttacked(board: boardMod.Board, sq: number, byColor: number): boolean
    enemy = byColor

    for _, offset in knightOffsets do
        target = sq + offset
        if knightValid(sq, target) then
            piece = board.squares[target]
            if piece != EMPTY and bit32.band(piece, 24) == enemy and bit32.band(piece, 7) == KNIGHT then
                return true
            end
        end
    end

    for _, dir in bishopDirs do
        current = sq
        while true do
            next = current + dir
            if not isOnBoard(next) then break end
            if not sameRankOrValid(current, next, dir) then break end
            piece = board.squares[next]
            if piece != EMPTY then
                if bit32.band(piece, 24) == enemy then
                    pt = bit32.band(piece, 7)
                    if pt == BISHOP or pt == QUEEN then return true end
                end
                break
            end
            current = next
        end
    end

    for _, dir in rookDirs do
        current = sq
        while true do
            next = current + dir
            if not isOnBoard(next) then break end
            if not sameRankOrValid(current, next, dir) then break end
            piece = board.squares[next]
            if piece != EMPTY then
                if bit32.band(piece, 24) == enemy then
                    pt = bit32.band(piece, 7)
                    if pt == ROOK or pt == QUEEN then return true end
                end
                break
            end
            current = next
        end
    end

    for _, dir in kingDirs do
        target = sq + dir
        if isOnBoard(target) and sameRankOrValid(sq, target, dir) then
            piece = board.squares[target]
            if piece != EMPTY and bit32.band(piece, 24) == enemy and bit32.band(piece, 7) == KING then
                return true
            end
        end
    end

    pawnDir = if enemy == WHITE then -8 else 8
    for _, captDir in {pawnDir - 1, pawnDir + 1} do
        target = sq + captDir
        if isOnBoard(target) then
            tf = ((target - 1) % 8) + 1
            sf = ((sq - 1) % 8) + 1
            if math.abs(tf - sf) == 1 then
                piece = board.squares[target]
                if piece != EMPTY and bit32.band(piece, 24) == enemy and bit32.band(piece, 7) == PAWN then
                    return true
                end
            end
        end
    end

    return false
end

function makeMove(board: boardMod.Board, move: Move): boardMod.Board
    b = board:clone()
    piece = b.squares[move.from]
    color = bit32.band(piece, 24)

    b.squares[move.from] = EMPTY
    b.squares[move.to] = piece

    if move.promotion != 0 then
        b.squares[move.to] = bit32.bor(color, move.promotion)
    end

    if bit32.band(move.flags, FLAG_EP) != 0 then
        epPawnSq = move.to + (if color == WHITE then -8 else 8)
        b.squares[epPawnSq] = EMPTY
    end

    if bit32.band(move.flags, FLAG_CASTLE) != 0 then
        if move.to == 7 then
            b.squares[8] = EMPTY
            b.squares[6] = bit32.bor(WHITE, ROOK)
        else if move.to == 3 then
            b.squares[1] = EMPTY
            b.squares[4] = bit32.bor(WHITE, ROOK)
        else if move.to == 63 then
            b.squares[64] = EMPTY
            b.squares[62] = bit32.bor(BLACK, ROOK)
        else if move.to == 59 then
            b.squares[57] = EMPTY
            b.squares[60] = bit32.bor(BLACK, ROOK)
        end
    end

    if bit32.band(move.flags, FLAG_DOUBLE) != 0 then
        b.epSquare = move.from + (if color == WHITE then 8 else -8)
    else
        b.epSquare = 0
    end

    if bit32.band(piece, 7) == KING then
        if color == WHITE then
            b.castling = bit32.band(b.castling, bit32.bnot(bit32.bor(WK_CASTLE, WQ_CASTLE)))
        else
            b.castling = bit32.band(b.castling, bit32.bnot(bit32.bor(BK_CASTLE, BQ_CASTLE)))
        end
    end
    if move.from == 1 or move.to == 1 then
        b.castling = bit32.band(b.castling, bit32.bnot(WQ_CASTLE))
    end
    if move.from == 8 or move.to == 8 then
        b.castling = bit32.band(b.castling, bit32.bnot(WK_CASTLE))
    end
    if move.from == 57 or move.to == 57 then
        b.castling = bit32.band(b.castling, bit32.bnot(BQ_CASTLE))
    end
    if move.from == 64 or move.to == 64 then
        b.castling = bit32.band(b.castling, bit32.bnot(BK_CASTLE))
    end

    if bit32.band(piece, 7) == PAWN or move.capture != EMPTY then
        b.halfmoveClock = 0
    else
        b.halfmoveClock = b.halfmoveClock + 1
    end

    if not b.whiteToMove then
        b.fullmoveNumber = b.fullmoveNumber + 1
    end
    b.whiteToMove = not b.whiteToMove
    b:computeZobrist()
    return b
end

function generateLegalMoves(board: boardMod.Board): {Move}
    pseudo = generatePseudoLegalMoves(board)
    legal = {}
    color = board:friendlyColor()
    enemy = board:enemyColor()

    for _, move in pseudo do
        if bit32.band(move.flags, FLAG_CASTLE) != 0 then
            kingSq = move.from
            if isSquareAttacked(board, kingSq, enemy) then continue end
            step = if move.to > move.from then 1 else -1
            mid = kingSq + step
            if isSquareAttacked(board, mid, enemy) then continue end
            if isSquareAttacked(board, move.to, enemy) then continue end
        end

        newBoard = makeMove(board, move)
        kingSq = newBoard:findKing(color)
        if kingSq > 0 and not isSquareAttacked(newBoard, kingSq, enemy) then
            table.insert(legal, move)
        end
    end
    return legal
end

function isInCheck(board: boardMod.Board): boolean
    color = board:friendlyColor()
    enemy = board:enemyColor()
    kingSq = board:findKing(color)
    if kingSq == 0 then return true end
    return isSquareAttacked(board, kingSq, enemy)
end

return {
    generateLegalMoves = generateLegalMoves,
    generatePseudoLegalMoves = generatePseudoLegalMoves,
    isSquareAttacked = isSquareAttacked,
    isInCheck = isInCheck,
    makeMove = makeMove,
    FLAG_CASTLE = FLAG_CASTLE,
    FLAG_EP = FLAG_EP,
    FLAG_DOUBLE = FLAG_DOUBLE,
}
