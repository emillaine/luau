function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

tensorMod = require("./neural-dir/tensor")
layers = require("./neural-dir/layers")
activations = require("./neural-dir/activations")
optimizer = require("./neural-dir/optimizer")

function test()

# Neural network benchmark: train a multi-layer network on procedurally generated data

Tensor = tensorMod.Tensor

BATCH_SIZE = 32
INPUT_SIZE = 64
HIDDEN1_SIZE = 128
HIDDEN2_SIZE = 64
OUTPUT_SIZE = 10
NUM_EPOCHS = 5
NUM_BATCHES = 5

seed = 42424242

function generateBatch(batchSize: number, inputSize: number, outputSize: number): (typeof(Tensor.new(1,1)), typeof(Tensor.new(1,1)), number)
    input = null
    input, seed = Tensor.randomNormal(batchSize, inputSize, seed, 1.0)
    targets = Tensor.new(batchSize, outputSize)
    for i = 1, batchSize do
        sum = 0
        offset = (i - 1) * inputSize
        for j = 1, inputSize do
            sum += input.data[offset + j]
        end
        classIdx = (math.floor(math.abs(sum * 100)) % outputSize) + 1
        targets.data[(i - 1) * outputSize + classIdx] = 1
    end
    return input, targets, seed
end

dense1 = null
dense1, seed = layers.createDense(INPUT_SIZE, HIDDEN1_SIZE, seed)
dense2 = null
dense2, seed = layers.createDense(HIDDEN1_SIZE, HIDDEN2_SIZE, seed)
dense3 = null
dense3, seed = layers.createDense(HIDDEN2_SIZE, OUTPUT_SIZE, seed)

adam1 = optimizer.createAdam(0.001)
adam2 = optimizer.createAdam(0.001)
adam3 = optimizer.createAdam(0.001)

totalLoss = 0
totalBatches = 0

for epoch = 1, NUM_EPOCHS do
    epochLoss = 0

    for batch = 1, NUM_BATCHES do
        input, targets = null, null
        input, targets, seed = generateBatch(BATCH_SIZE, INPUT_SIZE, OUTPUT_SIZE)

        # Forward pass
        z1 = layers.denseForward(dense1, input)
        a1 = activations.applyActivation(z1, "relu")

        z2 = layers.denseForward(dense2, a1)
        a2 = activations.applyActivation(z2, "leaky_relu")

        z3 = layers.denseForward(dense3, a2)
        output = activations.softmax(z3)

        # Loss (cross-entropy approximated by MSE for simplicity)
        loss = Tensor.meanSquaredError(output, targets)
        epochLoss += loss

        # Backward pass
        gradOutput = Tensor.sub(output, targets):mulScalar(2.0 / (BATCH_SIZE * OUTPUT_SIZE))

        gradZ3 = gradOutput
        gradA2 = layers.denseBackward(dense3, gradZ3)
        gradZ2 = Tensor.hadamard(gradA2, activations.applyActivationDeriv(z2, "leaky_relu"))
        gradA1 = layers.denseBackward(dense2, gradZ2)
        gradZ1 = Tensor.hadamard(gradA1, activations.applyActivationDeriv(z1, "relu"))
        layers.denseBackward(dense1, gradZ1)

        # Adam updates
        optimizer.adamUpdate(adam1, dense1.weights, dense1.dWeights, dense1.mW, dense1.vW)
        optimizer.adamUpdate(adam1, dense1.bias, dense1.dBias, dense1.mB, dense1.vB)
        optimizer.adamUpdate(adam2, dense2.weights, dense2.dWeights, dense2.mW, dense2.vW)
        optimizer.adamUpdate(adam2, dense2.bias, dense2.dBias, dense2.mB, dense2.vB)
        optimizer.adamUpdate(adam3, dense3.weights, dense3.dWeights, dense3.mW, dense3.vW)
        optimizer.adamUpdate(adam3, dense3.bias, dense3.dBias, dense3.mB, dense3.vB)

        totalBatches += 1
    end

    totalLoss += epochLoss / NUM_BATCHES
end

avgLoss = totalLoss / NUM_EPOCHS
print(string.format("Neural benchmark complete: %d epochs, %d batches, avg_loss=%.17g", NUM_EPOCHS, totalBatches, avgLoss))

if avgLoss != 0.099400851977591437 then
    error("Bad result")
end

end

bench.runCode(test, "neural")
