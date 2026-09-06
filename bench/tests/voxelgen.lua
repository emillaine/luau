function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../bench_support")

-- Based on voxel terrain generator by Stickmasterluke

kSelectedBiomes = {
    ['Mountains'] = true,
    ['Canyons'] = true,
    ['Dunes'] = true,
    ['Arctic'] = true,
    ['Lavaflow'] = true,
    ['Hills'] = true,
    ['Plains'] = true,
    ['Marsh'] = true,
    ['Water'] = true,
}

---------Directly used in Generation---------
masterSeed = 618033988
mapWidth = 32
mapHeight = 32
biomeSize = 16
generateCaves = true
waterLevel = .48
surfaceThickness = .018
biomes = {}
---------------------------------------------

rock = "Rock"
snow = "Snow"
ice = "Glacier"
grass = "Grass"
ground = "Ground"
mud = "Mud"
slate = "Slate"
concrete = "Concrete"
lava = "CrackedLava"
basalt = "Basalt"
air = "Air"
sand = "Sand"
sandstone = "Sandstone"
water = "Water"

math.randomseed(6180339)
theseed={}
for i=1,999 do
    table.insert(theseed,math.random())
end

function getPerlin(x,y,z,seed,scale,raw)
    seed = seed or 0
    scale = scale or 1
    if not raw then
        return math.noise(x/scale+(seed*17)+masterSeed,y/scale-masterSeed,z/scale-seed*seed)*.5 + .5 -- accounts for bleeding from interpolated line
    else
        return math.noise(x/scale+(seed*17)+masterSeed,y/scale-masterSeed,z/scale-seed*seed)
    end
end

function getNoise(x,y,z,seed1)
    x = x or 0
    y = y or 0
    z = z or 0
    seed1 = seed1 or 7
    wtf=x+y+z+seed1+masterSeed + (masterSeed-x)*(seed1+z) + (seed1-y)*(masterSeed+z)      -- + x*(y+z) + z*(masterSeed+seed1) + seed1*(x+y)           --x+y+z+seed1+masterSeed + x*y*masterSeed-y*z+(z+masterSeed)*x  --((x+y)*(y-seed1)*seed1)-(x+z)*seed2+x*11+z*23-y*17
    return theseed[(math.floor(wtf%(#theseed)))+1]
end

function thresholdFilter(value, bottom, size)
    if value <= bottom then
        return 0
    else if value >= bottom+size then
        return 1
    else
        return (value-bottom)/size
    end
end

function ridgedFilter(value)  --absolute and flip for ridges. and normalize
    return value<.5 and value*2 or 2-value*2
end

function ridgedFlippedFilter(value)                   --unflipped
    return value < .5 and 1-value*2 or value*2-1
end

function advancedRidgedFilter(value, cutoff)
    cutoff = cutoff or .5
    value = value - cutoff
    return 1 - (value < 0 and -value or value) * 1/(1-cutoff)
end

function fractalize(operation,x,y,z, operationCount, scale, offset, gain)
    operationCount = operationCount or 3
    scale = scale or .5
    offset = 0
    gain = gain or 1
    totalValue = 0
    totalScale = 0
    for i=1, operationCount do
        thisScale = scale^(i-1)
        totalScale = totalScale + thisScale
        totalValue = totalValue + (offset + gain * operation(x,y,z,i))*thisScale
    end
    return totalValue/totalScale
end

function mountainsOperation(x,y,z,i)
    return ridgedFilter(getPerlin(x,y,z,100+i,(1/i)*160))
end

canyonBandingMaterial = {rock,mud,sand,sand,sandstone,sandstone,sandstone,sandstone,sandstone,sandstone,}

function findBiomeInfo(choiceBiome,x,y,z,verticalGradientTurbulence)
    choiceBiomeValue = .5
    choiceBiomeSurface = grass
    choiceBiomeFill = rock
    if choiceBiome == 'City' then
        choiceBiomeValue = .55
        choiceBiomeSurface = concrete
        choiceBiomeFill = slate
    else if choiceBiome == 'Water' then
        choiceBiomeValue = .36+getPerlin(x,y,z,2,50)*.08
        choiceBiomeSurface = 
            (1-verticalGradientTurbulence < .44 and slate)
            or sand
    else if choiceBiome == 'Marsh' then
        preLedge = getPerlin(x+getPerlin(x,0,z,5,7,true)*10+getPerlin(x,0,z,6,30,true)*50,0,z+getPerlin(x,0,z,9,7,true)*10+getPerlin(x,0,z,10,30,true)*50,2,70)   --could use some turbulence
        grassyLedge = thresholdFilter(preLedge,.65,0)
        largeGradient = getPerlin(x,y,z,4,100)
        smallGradient = getPerlin(x,y,z,3,20)
        smallGradientThreshold = thresholdFilter(smallGradient,.5,0)
        choiceBiomeValue = waterLevel-.04
            +preLedge*grassyLedge*.025
            +largeGradient*.035
            +smallGradient*.025
        choiceBiomeSurface =
            (grassyLedge >= 1 and grass)
            or (1-verticalGradientTurbulence < waterLevel-.01 and mud)
            or (1-verticalGradientTurbulence < waterLevel+.01 and ground)
            or grass
        choiceBiomeFill = slate
    else if choiceBiome == 'Plains' then
        rivulet = ridgedFlippedFilter(getPerlin(x+getPerlin(x,y,z,17,40)*25,0,z+getPerlin(x,y,z,19,40)*25,2,200))
        rivuletThreshold = thresholdFilter(rivulet,.01,0)

        rockMap = thresholdFilter(ridgedFlippedFilter(getPerlin(x,0,z,101,7)),.3,.7)      --rocks
            * thresholdFilter(getPerlin(x,0,z,102,50),.6,.05)                                   --zoning

        choiceBiomeValue = .5           --.51
        +getPerlin(x,y,z,2,100)*.02     --.05
        +rivulet*.05                    --.02
        +rockMap*.05        --.03
        +rivuletThreshold*.005

        verticalGradient = 1-((y-1)/(mapHeight-1))
        surfaceGradient = verticalGradient*.5 + choiceBiomeValue*.5
        thinSurface = surfaceGradient > .5-surfaceThickness*.4 and surfaceGradient < .5+surfaceThickness*.4
        choiceBiomeSurface =
            (rockMap>0 and rock)
            or (not thinSurface and mud)
            or (thinSurface and rivuletThreshold <=0 and water)
            or (1-verticalGradientTurbulence < waterLevel-.01 and sand)
            or grass
        choiceBiomeFill =
            (rockMap>0 and rock)
            or sandstone
    else if choiceBiome == 'Canyons' then
        canyonNoise = ridgedFlippedFilter(getPerlin(x,0,z,2,200))
        canyonNoiseTurbed = ridgedFlippedFilter(getPerlin(x+getPerlin(x,0,z,5,20,true)*20,0,z+getPerlin(x,0,z,9,20,true)*20,2,200))
        sandbank = thresholdFilter(canyonNoiseTurbed,0,.05)
        canyonTop = thresholdFilter(canyonNoiseTurbed,.125,0)
        mesaSlope = thresholdFilter(canyonNoise,.33,.12)
        mesaTop = thresholdFilter(canyonNoiseTurbed,.49,0)
        choiceBiomeValue = .42
            +getPerlin(x,y,z,2,70)*.05
            +canyonNoise*.05
            +sandbank*.04                                       --canyon bottom slope
            +thresholdFilter(canyonNoiseTurbed,.05,0)*.08       --canyon cliff
            +thresholdFilter(canyonNoiseTurbed,.05,.075)*.04    --canyon cliff top slope
            +canyonTop*.01                                      --canyon cliff top ledge

            +thresholdFilter(canyonNoiseTurbed,.0575,.2725)*.01 --plane slope

            +mesaSlope*.06          --mesa slope
            +thresholdFilter(canyonNoiseTurbed,.45,0)*.14       --mesa cliff
            +thresholdFilter(canyonNoiseTurbed,.45,.04)*.025    --mesa cap
            +mesaTop*.02                                        --mesa top ledge
        choiceBiomeSurface =
            (1-verticalGradientTurbulence < waterLevel+.015 and sand)       --this for biome blending in to lakes
            or (sandbank>0 and sandbank<1 and sand)                         --this for canyonbase sandbanks
            --or (canyonTop>0 and canyonTop<=1 and mesaSlope<=0 and grass)      --this for grassy canyon tops
            --or (mesaTop>0 and mesaTop<=1 and grass)                           --this for grassy mesa tops
            or sandstone
        choiceBiomeFill = canyonBandingMaterial[math.ceil((1-getNoise(1,y,2))*10)]
    else if choiceBiome == 'Hills' then
        rivulet = ridgedFlippedFilter(getPerlin(x+getPerlin(x,y,z,17,20)*20,0,z+getPerlin(x,y,z,19,20)*20,2,200))^(1/2)
        largeHills = getPerlin(x,y,z,3,60)
        choiceBiomeValue = .48
            +largeHills*.05
                +(.05
                +largeHills*.1
                +getPerlin(x,y,z,4,25)*.125)
                *rivulet
        surfaceMaterialGradient = (1-verticalGradientTurbulence)*.9 + rivulet*.1
        choiceBiomeSurface =
            (surfaceMaterialGradient < waterLevel-.015 and mud)
            or (surfaceMaterialGradient < waterLevel and ground)
            or grass
        choiceBiomeFill = slate
    else if choiceBiome == 'Dunes' then
        duneTurbulence = getPerlin(x,0,z,227,20)*24
        layer1 = ridgedFilter(getPerlin(x,0,z,201,40))
        layer2 = ridgedFilter(getPerlin(x/10+duneTurbulence,0,z+duneTurbulence,200,48))
        choiceBiomeValue = .4+.1*(layer1 + layer2)
        choiceBiomeSurface = sand
        choiceBiomeFill = sandstone
    else if choiceBiome == 'Mountains' then
        rivulet = ridgedFlippedFilter(getPerlin(x+getPerlin(x,y,z,17,20)*20,0,z+getPerlin(x,y,z,19,20)*20,2,200))
        choiceBiomeValue = -.4      --.3
            +fractalize(mountainsOperation,x,y/20,z, 8, .65)*1.2
            +rivulet*.2
        choiceBiomeSurface =
            (verticalGradientTurbulence < .275 and snow)
            or (verticalGradientTurbulence < .35 and rock)
            or (verticalGradientTurbulence < .4 and ground)
            or (1-verticalGradientTurbulence < waterLevel and rock)
            or (1-verticalGradientTurbulence < waterLevel+.01 and mud)
            or (1-verticalGradientTurbulence < waterLevel+.015 and ground)
            or grass
    else if choiceBiome == 'Lavaflow' then
        crackX = x+getPerlin(x,y*.25,z,21,8,true)*5
        crackY = y+getPerlin(x,y*.25,z,22,8,true)*5
        crackZ = z+getPerlin(x,y*.25,z,23,8,true)*5
        crack1 = ridgedFilter(getPerlin(crackX+getPerlin(x,y,z,22,30,true)*30,crackY,crackZ+getPerlin(x,y,z,24,30,true)*30,2,120))
        crack2 = ridgedFilter(getPerlin(crackX,crackY,crackZ,3,40))*(crack1*.25+.75)
        crack3 = ridgedFilter(getPerlin(crackX,crackY,crackZ,4,20))*(crack2*.25+.75)

        generalHills = thresholdFilter(getPerlin(x,y,z,9,40),.25,.5)*getPerlin(x,y,z,10,60)

        cracks = math.max(0,1-thresholdFilter(crack1,.975,0)-thresholdFilter(crack2,.925,0)-thresholdFilter(crack3,.9,0))

        spires = thresholdFilter(getPerlin(crackX/40,crackY/300,crackZ/30,123,1),.6,.4)

        choiceBiomeValue = waterLevel+.02
            +cracks*(.5+generalHills*.5)*.02
            +generalHills*.05
            +spires*.3
            +((1-verticalGradientTurbulence > waterLevel+.01 or spires>0) and .04 or 0)         --This lets it lip over water

        choiceBiomeFill = (spires>0 and rock) or (cracks<1 and lava) or basalt
        choiceBiomeSurface = (choiceBiomeFill == lava and 1-verticalGradientTurbulence < waterLevel and basalt) or choiceBiomeFill
    else if choiceBiome == 'Arctic' then
        preBoundary = getPerlin(x+getPerlin(x,0,z,5,8,true)*5,y/8,z+getPerlin(x,0,z,9,8,true)*5,2,20)
        --local cliffs = thresholdFilter(preBoundary,.5,0)
        boundary = ridgedFilter(preBoundary)
        roughChunks = getPerlin(x,y/4,z,436,2)
        boundaryMask = thresholdFilter(boundary,.8,.1)    --,.7,.25)
        boundaryTypeMask = getPerlin(x,0,z,6,74)-.5
        boundaryComp = 0
        if boundaryTypeMask < 0 then                            --divergent
            boundaryComp = (boundary > (1+boundaryTypeMask*.5) and -.17 or 0)
                            --* boundaryTypeMask*-2
        else                                                    --convergent
            boundaryComp = boundaryMask*.1*roughChunks
                            * boundaryTypeMask
        end
        choiceBiomeValue = .55
            +boundary*.05*boundaryTypeMask      --.1    --soft slope up or down to boundary
            +boundaryComp                               --convergent/divergent effects
            +getPerlin(x,0,z,123,25)*.025   --*cliffs   --gentle rolling slopes

        choiceBiomeSurface = (1-verticalGradientTurbulence < waterLevel-.1 and ice) or (boundaryMask>.6 and boundaryTypeMask>.1 and roughChunks>.5 and ice) or snow
        choiceBiomeFill = ice
    end
    return choiceBiomeValue, choiceBiomeSurface, choiceBiomeFill
end

function findBiomeTransitionValue(biome,weight,value,averageValue)
    if biome == 'Arctic' then
        return (weight>.2 and 1 or 0)*value
    else if biome == 'Canyons' then
        return (weight>.7 and 1 or 0)*value
    else if biome == 'Mountains' then
        weight = weight^3         --This improves the ease of mountains transitioning to other biomes
        return averageValue*(1-weight)+value*weight
    else
        return averageValue*(1-weight)+value*weight
    end
end

function generate()
    mapWidth = mapWidth
    biomeSize = biomeSize
    biomeBlendPercent = .25   --(biomeSize==50 or biomeSize == 100) and .5 or .25
    biomeBlendPercentInverse = 1-biomeBlendPercent
    biomeBlendDistortion = biomeBlendPercent
    smoothScale = .5/mapHeight

    biomes = {}
    for i,v in pairs(kSelectedBiomes) do
        if v then
            table.insert(biomes,i)
        end
    end
    if #biomes<=0 then
        table.insert(biomes,'Hills')
    end
    table.sort(biomes)
    --local oMap = {}
    --local mMap = {}
    for x = 1, mapWidth do
        oMapX = {}
        --oMap[x] = oMapX
        mMapX = {}
        --mMap[x] = mMapX
        for z = 1, mapWidth do
            biomeNoCave = false
            cellToBiomeX = x/biomeSize + getPerlin(x,0,z,233,biomeSize*.3)*.25 + getPerlin(x,0,z,235,biomeSize*.05)*.075
            cellToBiomeZ = z/biomeSize + getPerlin(x,0,z,234,biomeSize*.3)*.25 + getPerlin(x,0,z,236,biomeSize*.05)*.075
            closestDistance = 1000000
            biomePoints = {}
            for vx=-1,1 do
                for vz=-1,1 do
                    gridPointX = math.floor(cellToBiomeX+vx+.5)
                    gridPointZ = math.floor(cellToBiomeZ+vz+.5)
                    --local pointX, pointZ = getBiomePoint(gridPointX,gridPointZ)
                    pointX = gridPointX+(getNoise(gridPointX,gridPointZ,53)-.5)*.75   --de-uniforming grid for vornonoi
                    pointZ = gridPointZ+(getNoise(gridPointX,gridPointZ,73)-.5)*.75

                    dist = math.sqrt((pointX-cellToBiomeX)^2 + (pointZ-cellToBiomeZ)^2)
                    if dist < closestDistance then
                        closestDistance = dist
                    end
                    table.insert(biomePoints,{
                        x = pointX,
                        z = pointZ,
                        dist = dist,
                        biomeNoise = getNoise(gridPointX,gridPointZ),
                        weight = 0
                    })
                end
            end
            weightTotal = 0
            weightPoints = {}
            for _,point in pairs(biomePoints) do
                weight = point.dist == closestDistance and 1 or ((closestDistance / point.dist)-biomeBlendPercentInverse)/biomeBlendPercent
                if weight > 0 then
                    weight = weight^2.1       --this smooths the biome transition from linear to cubic InOut
                    weightTotal = weightTotal + weight
                    biome = biomes[math.ceil(#biomes*(1-point.biomeNoise))]   --inverting the noise so that it is limited as (0,1]. One less addition operation when finding a random list index
                    weightPoints[biome] = {
                        weight = weightPoints[biome] and weightPoints[biome].weight + weight or weight
                    }
                end
            end
            for biome,info in pairs(weightPoints) do
                info.weight = info.weight / weightTotal
                if biome == 'Arctic' then       --biomes that don't have caves that breach the surface
                    biomeNoCave = true
                end
            end


            for y = 1, mapHeight do
                oMapY = oMapX[y] or {}
                oMapX[y] = oMapY
                mMapY = mMapX[y] or {}
                mMapX[y] = mMapY

                --[[local oMapY = {}
                oMapX[y] = oMapY
                local mMapY = {}
                mMapX[z] = mMapY]]


                verticalGradient = 1-((y-1)/(mapHeight-1))
                caves = 0
                verticalGradientTurbulence = verticalGradient*.9 + .1*getPerlin(x,y,z,107,15)
                choiceValue = 0
                choiceSurface = lava
                choiceFill = rock

                if verticalGradient > .65 or verticalGradient < .1 then
                    --under surface of every biome; don't get biome data; waste of time.
                    choiceValue = .5
                else if #biomes == 1 then
                    choiceValue, choiceSurface, choiceFill = findBiomeInfo(biomes[1],x,y,z,verticalGradientTurbulence)
                else
                    averageValue = 0
                    --local findChoiceMaterial = -getNoise(x,y,z,19)
                    for biome,info in pairs(weightPoints) do
                        biomeValue, biomeSurface, biomeFill = findBiomeInfo(biome,x,y,z,verticalGradientTurbulence)
                        info.biomeValue = biomeValue
                        info.biomeSurface = biomeSurface
                        info.biomeFill = biomeFill
                        value = biomeValue * info.weight
                        averageValue = averageValue + value
                        --[[if findChoiceMaterial < 0 and findChoiceMaterial + weight >= 0 then
                            choiceMaterial = biomeMaterial
                        end
                        findChoiceMaterial = findChoiceMaterial + weight]]
                    end
                    for biome,info in pairs(weightPoints) do
                        value = findBiomeTransitionValue(biome,info.weight,info.biomeValue,averageValue)
                        if value > choiceValue then
                            choiceValue = value
                            choiceSurface = info.biomeSurface
                            choiceFill = info.biomeFill
                        end
                    end
                end

                preCaveComp = verticalGradient*.5 + choiceValue*.5

                surface = preCaveComp > .5-surfaceThickness and preCaveComp < .5+surfaceThickness

                if generateCaves                                                                --user wants caves
                    and (not biomeNoCave or verticalGradient > .65)                             --biome allows caves or deep enough
                        and not (surface and (1-verticalGradient) < waterLevel+.005)            --caves only breach surface above waterlevel
                            and not (surface and (1-verticalGradient) > waterLevel+.58) then    --caves don't go too high so that they don't cut up mountain tops
                                ridged2 = ridgedFilter(getPerlin(x,y,z,4,30))
                                caves2 = thresholdFilter(ridged2,.84,.01)
                                ridged3 = ridgedFilter(getPerlin(x,y,z,5,30))
                                caves3 = thresholdFilter(ridged3,.84,.01)
                                ridged4 = ridgedFilter(getPerlin(x,y,z,6,30))
                                caves4 = thresholdFilter(ridged4,.84,.01)
                                caveOpenings = (surface and 1 or 0) * thresholdFilter(getPerlin(x,0,z,143,62),.35,0)  --.45
                                caves = caves2 * caves3 * caves4 - caveOpenings
                                caves = caves < 0 and 0 or caves > 1 and 1 or caves
                end

                comp = preCaveComp - caves

                smoothedResult = thresholdFilter(comp,.5,smoothScale)

                ---below water level                  -above surface        -no terrain
                if 1-verticalGradient < waterLevel and preCaveComp <= .5 and smoothedResult <= 0 then
                    smoothedResult = 1
                    choiceSurface = water
                    choiceFill = water
                    surface = true
                end

                oMapY[z] = (y == 1 and 1) or smoothedResult
                mMapY[z] = (y == 1 and lava) or (smoothedResult <= 0 and air) or (surface and choiceSurface) or choiceFill
            end
        end

        -- local regionStart = Vector3.new(mapWidth*-2+(x-1)*4,mapHeight*-2,mapWidth*-2)
        -- local regionEnd = Vector3.new(mapWidth*-2+x*4,mapHeight*2,mapWidth*2)
        -- local mapRegion = Region3.new(regionStart, regionEnd)
        -- terrain:WriteVoxels(mapRegion, 4, {mMapX}, {oMapX})
    end
end

bench.runCode(generate, "voxelgen")
