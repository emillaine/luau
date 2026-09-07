# Alpha-beta search with iterative deepening, quiescence, and transposition table

boardMod = require("./board")
movegen = require("./movegen")
eval = require("./eval")

INFINITY = 999999
MATE_SCORE = 100000

TT_EXACT = 0
TT_ALPHA = 1
TT_BETA = 2

type TTEntry = {
    hash: number,
    depth: number,
    score: number,
    flag: number,
    bestFrom: number,
    bestTo: number,
}

ttSize = 65536
ttMask = ttSize - 1
tt = table.create(ttSize, null)

nodesSearched = 0

function ttProbe(hash: number, depth: number, alpha: number, beta: number): (number?, number?, number?)
    idx = bit32.band(hash, ttMask) + 1
    entry = tt[idx]
    if entry and entry.hash == hash then
        if entry.depth >= depth then
            if entry.flag == TT_EXACT then
                return entry.score, entry.bestFrom, entry.bestTo
            else if entry.flag == TT_ALPHA and entry.score <= alpha then
                return alpha, entry.bestFrom, entry.bestTo
            else if entry.flag == TT_BETA and entry.score >= beta then
                return beta, entry.bestFrom, entry.bestTo
            end
        end
        return null, entry.bestFrom, entry.bestTo
    end
    return null, null, null
end

function ttStore(hash: number, depth: number, score: number, flag: number, bestFrom: number, bestTo: number)
    idx = bit32.band(hash, ttMask) + 1
    tt[idx] = {
        hash = hash,
        depth = depth,
        score = score,
        flag = flag,
        bestFrom = bestFrom,
        bestTo = bestTo,
    }
end

function mvvLva(move: movegen.Move): number
    if move.capture == boardMod.EMPTY then return 0 end
    captureVal = eval.pieceValues[bit32.band(move.capture, 7)] or 0
    return captureVal * 10
end

function orderMoves(moves: {movegen.Move}, ttFrom: number?, ttTo: number?)
    scores = table.create(moves.count, 0)
    for i, move in moves do
        s = mvvLva(move)
        if ttFrom and ttTo and move.from == ttFrom and move.to == ttTo then
            s += 1000000
        end
        scores[i] = s
    end

    for i = 1, moves.count - 1 do
        bestIdx = i
        bestScore = scores[i]
        for j = i + 1, moves.count do
            if scores[j] > bestScore then
                bestIdx = j
                bestScore = scores[j]
            end
        end
        if bestIdx != i then
            moves[i], moves[bestIdx] = moves[bestIdx], moves[i]
            scores[i], scores[bestIdx] = scores[bestIdx], scores[i]
        end
    end
end

function quiescence(board: boardMod.Board, alpha: number, beta: number, depth: number): number
    nodesSearched += 1
    standPat = eval.evaluate(board)
    if standPat >= beta then return beta end
    if depth <= -6 then return standPat end
    if standPat > alpha then alpha = standPat end

    moves = movegen.generateLegalMoves(board)
    for _, move in moves do
        if move.capture == boardMod.EMPTY then continue end

        newBoard = movegen.makeMove(board, move)
        score = -quiescence(newBoard, -beta, -alpha, depth - 1)

        if score >= beta then return beta end
        if score > alpha then alpha = score end
    end

    return alpha
end

function alphaBeta(board: boardMod.Board, depth: number, alpha: number, beta: number, ply: number): number
    if depth <= 0 then
        return quiescence(board, alpha, beta, 0)
    end

    nodesSearched += 1

    ttScore, ttFrom, ttTo = ttProbe(board.zobrist, depth, alpha, beta)
    if ttScore then return ttScore end

    moves = movegen.generateLegalMoves(board)
    if moves.count == 0 then
        if movegen.isInCheck(board) then
            return -(MATE_SCORE - ply)
        end
        return 0
    end

    orderMoves(moves, ttFrom, ttTo)

    bestFrom = moves[1].from
    bestTo = moves[1].to
    ttFlag = TT_ALPHA
    bestScore = -INFINITY

    for _, move in moves do
        newBoard = movegen.makeMove(board, move)
        score = -alphaBeta(newBoard, depth - 1, -beta, -alpha, ply + 1)

        if score > bestScore then
            bestScore = score
            bestFrom = move.from
            bestTo = move.to
        end

        if score >= beta then
            ttStore(board.zobrist, depth, beta, TT_BETA, move.from, move.to)
            return beta
        end
        if score > alpha then
            alpha = score
            ttFlag = TT_EXACT
        end
    end

    ttStore(board.zobrist, depth, alpha, ttFlag, bestFrom, bestTo)
    return alpha
end

function search(board: boardMod.Board, maxDepth: number): (movegen.Move?, number, number)
    nodesSearched = 0
    bestMove = null
    bestScore = -INFINITY

    for depth = 1, maxDepth do
        moves = movegen.generateLegalMoves(board)
        if moves.count == 0 then break end

        _, ttFrom, ttTo = ttProbe(board.zobrist, 0, -INFINITY, INFINITY)
        orderMoves(moves, ttFrom, ttTo)

        alpha = -INFINITY
        beta = INFINITY
        currentBest = null
        currentScore = -INFINITY

        for _, move in moves do
            newBoard = movegen.makeMove(board, move)
            score = -alphaBeta(newBoard, depth - 1, -beta, -alpha, 1)

            if score > currentScore then
                currentScore = score
                currentBest = move
            end
            if score > alpha then
                alpha = score
            end
        end

        if currentBest then
            bestMove = currentBest
            bestScore = currentScore
        end
    end

    return bestMove, bestScore, nodesSearched
end

function clearTT()
    for i = 1, ttSize do
        tt[i] = null
    end
end

return {
    search = search,
    clearTT = clearTT,
}
