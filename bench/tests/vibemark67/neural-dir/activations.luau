# Activation functions and their derivatives

tensorMod = require("./tensor")
Tensor = tensorMod.Tensor

function relu(x: number): number
    return if x > 0 then x else 0
end

function reluDeriv(x: number): number
    return if x > 0 then 1 else 0
end

function sigmoid(x: number): number
    if x > 20 then return 1 end
    if x < -20 then return 0 end
    return 1 / (1 + math.exp(-x))
end

function sigmoidDeriv(x: number): number
    s = sigmoid(x)
    return s * (1 - s)
end

function tanh_(x: number): number
    if x > 20 then return 1 end
    if x < -20 then return -1 end
    e2x = math.exp(2 * x)
    return (e2x - 1) / (e2x + 1)
end

function tanhDeriv(x: number): number
    t = tanh_(x)
    return 1 - t * t
end

function leakyRelu(x: number): number
    return if x > 0 then x else 0.01 * x
end

function leakyReluDeriv(x: number): number
    return if x > 0 then 1 else 0.01
end

function applyActivation(t: typeof(Tensor.new(1,1)), name: string): typeof(Tensor.new(1,1))
    if name == "relu" then
        return t:apply(relu)
    else if name == "sigmoid" then
        return t:apply(sigmoid)
    else if name == "tanh" then
        return t:apply(tanh_)
    else if name == "leaky_relu" then
        return t:apply(leakyRelu)
    end
    return t:clone()
end

function applyActivationDeriv(t: typeof(Tensor.new(1,1)), name: string): typeof(Tensor.new(1,1))
    if name == "relu" then
        return t:apply(reluDeriv)
    else if name == "sigmoid" then
        return t:apply(sigmoidDeriv)
    else if name == "tanh" then
        return t:apply(tanhDeriv)
    else if name == "leaky_relu" then
        return t:apply(leakyReluDeriv)
    end
    result = Tensor.new(t.rows, t.cols)
    result:fill(1)
    return result
end

function softmax(t: typeof(Tensor.new(1,1))): typeof(Tensor.new(1,1))
    result = Tensor.new(t.rows, t.cols)
    for i = 1, t.rows do
        offset = (i - 1) * t.cols
        maxVal = t.data[offset + 1]
        for j = 2, t.cols do
            if t.data[offset + j] > maxVal then
                maxVal = t.data[offset + j]
            end
        end
        sum = 0
        for j = 1, t.cols do
            e = math.exp(t.data[offset + j] - maxVal)
            result.data[offset + j] = e
            sum += e
        end
        for j = 1, t.cols do
            result.data[offset + j] /= sum
        end
    end
    return result
end

return {
    applyActivation = applyActivation,
    applyActivationDeriv = applyActivationDeriv,
    softmax = softmax,
    relu = relu,
    sigmoid = sigmoid,
}
