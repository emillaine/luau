function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

noise = require("./erosion-dir/noise")
erosion = require("./erosion-dir/erosion")
mesh = require("./erosion-dir/mesh")

function test()

# Erosion benchmark: terrain generation with hydraulic and thermal erosion on a grid

GRID_SIZE = 256
NOISE_SCALE = 4.0
NOISE_OCTAVES = 6
HYDRAULIC_ITERATIONS = 50000
THERMAL_ITERATIONS = 20
SEED = 987654

heightmap = noise.generateHeightmap(GRID_SIZE, NOISE_SCALE, NOISE_OCTAVES)

minH, maxH, avgH = mesh.computeStats(heightmap, GRID_SIZE)

heightmap = erosion.hydraulicErosion(heightmap, GRID_SIZE, HYDRAULIC_ITERATIONS, SEED)

heightmap = erosion.thermalErosion(heightmap, GRID_SIZE, THERMAL_ITERATIONS, 0.01)

minH2, maxH2, avgH2 = mesh.computeStats(heightmap, GRID_SIZE)

terrainMesh = mesh.generateMesh(heightmap, GRID_SIZE, 1.0)

print(string.format("Erosion benchmark complete: grid=%dx%d, vertices=%d",
    GRID_SIZE, GRID_SIZE, terrainMesh.vertexCount))
print(string.format("  Before erosion: min=%.17g max=%.17g avg=%.17g", minH, maxH, avgH))
print(string.format("  After erosion:  min=%.17g max=%.17g avg=%.17g", minH2, maxH2, avgH2))

if minH2 != 0.30927880669503277 then
    error("Bad min")
end
if maxH2 != 0.78981177822856874 then
    error("Bad max")
end
if avgH2 != 0.48523436474051113 then
    error("Bad average")
end

end

bench.runCode(test, "erosion")
