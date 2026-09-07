# PPM compressor and decompressor

arithmetic = require("./arithmetic")
context = require("./context")

function compress(data: {number}): {number}
    model = context.createModel(context.MAX_ORDER)
    encoder = arithmetic.Encoder.new()
    history = {}

    for _, symbol in data do
        encoded = false
        for order = math.min(context.MAX_ORDER, history.count), 0, -1 do
            node = context.getContext(model, history, order)
            if node and node.total > 0 then
                cumLow, cumHigh, total, escaped =
                    context.getSymbolProbabilityWithEscape(node, symbol + 1)
                encoder:encode(cumLow, cumHigh, total)
                if not escaped then
                    encoded = true
                    break
                end
            else
                total = context.ALPHABET_SIZE
                cumLow = symbol
                cumHigh = symbol + 1
                encoder:encode(cumLow, cumHigh, total)
                encoded = true
                break
            end
        end

        if not encoded then
            total = context.ALPHABET_SIZE
            encoder:encode(symbol, symbol + 1, total)
        end

        context.updateModel(model, history, symbol + 1)
        table.insert(history, symbol + 1)
        if history.count > context.MAX_ORDER then
            table.remove(history, 1)
        end
    end

    eofSymbol = 256
    for order = math.min(context.MAX_ORDER, history.count), 0, -1 do
        node = context.getContext(model, history, order)
        if node and node.total > 0 then
            cumLow, cumHigh, total, escaped =
                context.getSymbolProbabilityWithEscape(node, eofSymbol + 1)
            encoder:encode(cumLow, cumHigh, total)
            if not escaped then break end
        else
            encoder:encode(eofSymbol, eofSymbol + 1, context.ALPHABET_SIZE)
            break
        end
    end

    encoder:finish()
    return encoder:getBytes()
end

function decompress(compressed: {number}, originalSize: number): {number}
    model = context.createModel(context.MAX_ORDER)
    decoder = arithmetic.Decoder.new(compressed)
    history = {}
    output = table.create(originalSize, 0)
    outPos = 1

    while outPos <= originalSize do
        symbol = -1

        for order = math.min(context.MAX_ORDER, history.count), 0, -1 do
            node = context.getContext(model, history, order)
            if node and node.total > 0 then
                total = context.getTotalWithEscape(node)
                target = decoder:getTarget(total)
                sym, cumLow, cumHigh, escaped =
                    context.decodeSymbolFromContext(node, target, total)
                decoder:decode(cumLow, cumHigh, total)
                if not escaped then
                    symbol = sym - 1
                    break
                end
            else
                total = context.ALPHABET_SIZE
                target = decoder:getTarget(total)
                decoder:decode(target, target + 1, total)
                symbol = target
                break
            end
        end

        if symbol == -1 then
            total = context.ALPHABET_SIZE
            target = decoder:getTarget(total)
            decoder:decode(target, target + 1, total)
            symbol = target
        end

        if symbol >= 256 then break end

        output[outPos] = symbol
        outPos += 1

        context.updateModel(model, history, symbol + 1)
        table.insert(history, symbol + 1)
        if history.count > context.MAX_ORDER then
            table.remove(history, 1)
        end
    end

    return output
end

return {
    compress = compress,
    decompress = decompress,
}
