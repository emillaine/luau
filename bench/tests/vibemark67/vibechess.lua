function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

boardMod = require("./chess-dir/board")
movegen = require("./chess-dir/movegen")
search = require("./chess-dir/search")

function test()

-- Chess engine benchmark: searches a set of positions to fixed depth

Board = boardMod.Board
WHITE = boardMod.WHITE
BLACK = boardMod.BLACK
PAWN = boardMod.PAWN
KNIGHT = boardMod.KNIGHT
BISHOP = boardMod.BISHOP
ROOK = boardMod.ROOK
QUEEN = boardMod.QUEEN
KING = boardMod.KING
EMPTY = boardMod.EMPTY
WK_CASTLE = boardMod.WK_CASTLE
WQ_CASTLE = boardMod.WQ_CASTLE
BK_CASTLE = boardMod.BK_CASTLE
BQ_CASTLE = boardMod.BQ_CASTLE

pieceFromChar = {
    P = bit32.bor(WHITE, PAWN), N = bit32.bor(WHITE, KNIGHT),
    B = bit32.bor(WHITE, BISHOP), R = bit32.bor(WHITE, ROOK),
    Q = bit32.bor(WHITE, QUEEN), K = bit32.bor(WHITE, KING),
    p = bit32.bor(BLACK, PAWN), n = bit32.bor(BLACK, KNIGHT),
    b = bit32.bor(BLACK, BISHOP), r = bit32.bor(BLACK, ROOK),
    q = bit32.bor(BLACK, QUEEN), k = bit32.bor(BLACK, KING),
}

function parseFEN(fen: string): boardMod.Board
    b = Board.new()
    parts = string.split(fen, " ")
    ranks = string.split(parts[1], "/")

    for rankIdx = 1, 8 do
        rankStr = ranks[rankIdx]
        file = 1
        for i = 1, #rankStr do
            ch = string.sub(rankStr, i, i)
            digit = tonumber(ch)
            if digit then
                file += digit
            else
                sq = (8 - rankIdx) * 8 + file
                b.squares[sq] = pieceFromChar[ch] or EMPTY
                file += 1
            end
        end
    end

    b.whiteToMove = (parts[2] == "w")

    if parts[3] and parts[3] != "-" then
        castling = parts[3]
        if string.find(castling, "K") then b.castling = bit32.bor(b.castling, WK_CASTLE) end
        if string.find(castling, "Q") then b.castling = bit32.bor(b.castling, WQ_CASTLE) end
        if string.find(castling, "k") then b.castling = bit32.bor(b.castling, BK_CASTLE) end
        if string.find(castling, "q") then b.castling = bit32.bor(b.castling, BQ_CASTLE) end
    end

    if parts[4] and parts[4] != "-" then
        epFile = string.byte(parts[4], 1) - string.byte("a", 1) + 1
        epRank = tonumber(string.sub(parts[4], 2, 2)) or 0
        b.epSquare = (epRank - 1) * 8 + epFile
    end

    b.halfmoveClock = tonumber(parts[5]) or 0
    b.fullmoveNumber = tonumber(parts[6]) or 1
    b:computeZobrist()
    return b
end

positions = {
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
--    "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
--    "r1bqkbnr/pppppppp/2n5/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 1 2",
--    "rnbqkb1r/pp1p1ppp/2p2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 4",
    "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQ1RK1 b kq - 5 5",
--    "r2q1rk1/ppp2ppp/2np1n2/2b1p1B1/2B1P1b1/2NP1N2/PPP2PPP/R2Q1RK1 w - - 6 9",
--    "r1bq1rk1/pppnnppp/4p3/3pP3/1b1P4/2NB1N2/PPP2PPP/R1BQ1RK1 w - - 0 8",
    "rnb1k2r/pppp1ppp/5n2/2b1p1q1/2B1P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 4 5",
--    "2r3k1/pp3ppp/2n2n2/3pp3/1b2P3/2N1BN2/PPP2PPP/R3K2R w KQ - 0 12",
--    "r1bqk2r/2ppbppp/p1n2n2/1p2p3/4P3/1B3N2/PPPP1PPP/RNBQR1K1 b kq - 1 7",
--    "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10",
--    "rnbq1rk1/ppp1ppbp/5np1/3p4/2PP4/2N2N2/PP2PPPP/R1BQKB1R w KQ - 0 5",
}

SEARCH_DEPTH = 3
ITERATIONS = 1

totalNodes = 0
totalPositions = 0

for iter = 1, ITERATIONS do
    for i, fen in positions do
        search.clearTT()
        board = parseFEN(fen)
        bestMove, score, nodes = search.search(board, SEARCH_DEPTH)
        totalNodes += nodes
        totalPositions += 1
    end
end

if totalNodes != 6132 then
    error("Bad totalNodes: " .. totalNodes)
end
if totalPositions != 3 then
    error("Bad totalPositions: " .. totalPositions)
end

end

bench.runCode(test, "vibechess")
