-- Adam optimizer

tensorMod = require("./tensor")
Tensor = tensorMod.Tensor

export type AdamState = {
    lr: number,
    beta1: number,
    beta2: number,
    epsilon: number,
    t: number,
}

function createAdam(lr: number?): AdamState
    return {
        lr = lr or 0.001,
        beta1 = 0.9,
        beta2 = 0.999,
        epsilon = 1e-8,
        t = 0,
    }
end

function adamUpdate(
    state: AdamState,
    param: typeof(Tensor.new(1,1)),
    grad: typeof(Tensor.new(1,1)),
    m: typeof(Tensor.new(1,1)),
    v: typeof(Tensor.new(1,1))
)
    state.t += 1
    t = state.t
    beta1 = state.beta1
    beta2 = state.beta2
    lr = state.lr
    eps = state.epsilon

    bc1 = 1 - math.pow(beta1, t)
    bc2 = 1 - math.pow(beta2, t)

    for i = 1, #param.data do
        g = grad.data[i]
        m.data[i] = beta1 * m.data[i] + (1 - beta1) * g
        v.data[i] = beta2 * v.data[i] + (1 - beta2) * g * g
        mHat = m.data[i] / bc1
        vHat = v.data[i] / bc2
        param.data[i] -= lr * mHat / (math.sqrt(vHat) + eps)
    end
end

function adamUpdateScalars(
    state: AdamState,
    params: {number},
    grads: {number},
    m: {number},
    v: {number}
)
    state.t += 1
    t = state.t
    beta1 = state.beta1
    beta2 = state.beta2
    lr = state.lr
    eps = state.epsilon

    bc1 = 1 - math.pow(beta1, t)
    bc2 = 1 - math.pow(beta2, t)

    for i = 1, #params do
        g = grads[i]
        m[i] = beta1 * m[i] + (1 - beta1) * g
        v[i] = beta2 * v[i] + (1 - beta2) * g * g
        mHat = m[i] / bc1
        vHat = v[i] / bc2
        params[i] -= lr * mHat / (math.sqrt(vHat) + eps)
    end
end

return {
    createAdam = createAdam,
    adamUpdate = adamUpdate,
    adamUpdateScalars = adamUpdateScalars,
}
