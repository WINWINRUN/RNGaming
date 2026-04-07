local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Terrain = Workspace.Terrain

local WorldPromptSpec = require(ReplicatedStorage:WaitForChild("WorldPromptSpec"))
local ModularWorldAssets = require(ReplicatedStorage:WaitForChild("ModularWorldAssets"))

local PromptWorldService = {}

local ROOT_NAME = "GeneratedPromptWorld"
local STEM_ROTATION = CFrame.Angles(0, 0, math.rad(90))

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function lerp(a, b, alpha)
    return a + ((b - a) * alpha)
end

local function inverseLerp(minimum, maximum, value)
    if minimum == maximum then
        return 0
    end
    return clamp((value - minimum) / (maximum - minimum), 0, 1)
end

local function smoothstep(minimum, maximum, value)
    local alpha = inverseLerp(minimum, maximum, value)
    return alpha * alpha * (3 - (2 * alpha))
end

local function gaussian1(value, center, width)
    local delta = (value - center) / width
    return math.exp(-(delta * delta))
end

local function gaussian2(x, z, centerX, centerZ, widthX, widthZ)
    local deltaX = (x - centerX) / widthX
    local deltaZ = (z - centerZ) / widthZ
    return math.exp(-((deltaX * deltaX) + (deltaZ * deltaZ)))
end

local function fractal2D(x, z, scale, octaves, lacunarity, persistence, seed)
    local amplitude = 1
    local frequency = 1 / scale
    local total = 0
    local normalization = 0

    for octave = 1, octaves do
        total += math.noise((x * frequency) + (seed * 0.0000013), (z * frequency) - (seed * 0.0000007), octave * 0.17) * amplitude
        normalization += amplitude
        amplitude *= persistence
        frequency *= lacunarity
    end

    if normalization <= 0 then
        return 0
    end

    return total / normalization
end

local function ridge2D(x, z, scale, octaves, lacunarity, persistence, seed)
    local value = fractal2D(x, z, scale, octaves, lacunarity, persistence, seed)
    return 1 - math.abs(value)
end

local function colorFromRGB(rgb, fallback)
    if type(rgb) == "table" and #rgb >= 3 then
        return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
    end
    return fallback or Color3.fromRGB(255, 255, 255)
end

local function clamp01(value)
    return clamp(value, 0, 1)
end

local function tintColor(color, redShift, greenShift, blueShift)
    return Color3.new(
        clamp01(color.R + redShift),
        clamp01(color.G + greenShift),
        clamp01(color.B + blueShift)
    )
end

local function blendColor(first, second, alpha)
    return Color3.new(
        lerp(first.R, second.R, alpha),
        lerp(first.G, second.G, alpha),
        lerp(first.B, second.B, alpha)
    )
end

local function randomOffsetColor(rng, baseColor, range)
    return tintColor(
        baseColor,
        rng:NextNumber(-range, range),
        rng:NextNumber(-range, range),
        rng:NextNumber(-range, range)
    )
end

local function seedFromText(text)
    local seed = 146959810
    for index = 1, #text do
        seed = (seed * 16777619 + string.byte(text, index)) % 2147483647
    end
    return seed
end

local function resolveGenerationSeed()
    local generation = ModularWorldAssets.Generation
    if generation and type(generation.Seed) == "number" then
        local normalized = math.floor(math.abs(generation.Seed))
        if normalized == 0 then
            return 1
        end
        return ((normalized - 1) % 2147483646) + 1
    end

    return seedFromText(WorldPromptSpec.prompt or ModularWorldAssets.Prompts and ModularWorldAssets.Prompts.WorldPrompt or "PromptWorld")
end

local function resolveOriginalitySignature(seed)
    local generation = ModularWorldAssets.Generation
    if generation and type(generation.AssetSignature) == "string" and #generation.AssetSignature > 0 then
        return generation.AssetSignature
    end
    return string.format("%08X", (seed * 2654435761) % 4294967295)
end

local function createModel(parent, name)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    return model
end

local function makePart(parent, name, size, cframe, options)
    options = options or {}

    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = options.Anchored ~= false
    part.Material = options.Material or Enum.Material.SmoothPlastic
    part.Color = options.Color or Color3.fromRGB(220, 220, 220)
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Transparency = options.Transparency or 0
    part.CanCollide = options.CanCollide ~= false
    part.CanTouch = options.CanTouch ~= false
    part.CanQuery = options.CanQuery ~= false
    if options.CastShadow ~= nil then
        part.CastShadow = options.CastShadow
    end
    if options.Shape then
        part.Shape = options.Shape
    end
    part.Parent = parent
    return part
end

local function makeVerticalCylinder(parent, name, radius, height, cframe, options)
    return makePart(parent, name, Vector3.new(height, radius * 2, radius * 2), cframe * STEM_ROTATION, {
        Anchored = options and options.Anchored,
        Material = options and options.Material,
        Color = options and options.Color,
        Transparency = options and options.Transparency,
        CanCollide = options and options.CanCollide,
        CanTouch = options and options.CanTouch,
        CanQuery = options and options.CanQuery,
        CastShadow = options and options.CastShadow,
        Shape = Enum.PartType.Cylinder,
    })
end

local function makeBall(parent, name, size, cframe, options)
    return makePart(parent, name, size, cframe, {
        Anchored = options and options.Anchored,
        Material = options and options.Material,
        Color = options and options.Color,
        Transparency = options and options.Transparency,
        CanCollide = options and options.CanCollide,
        CanTouch = options and options.CanTouch,
        CanQuery = options and options.CanQuery,
        CastShadow = options and options.CastShadow,
        Shape = Enum.PartType.Ball,
    })
end

local function addPointLight(parent, name, color, brightness, range)
    local light = parent:FindFirstChild(name)
    if light then
        light:Destroy()
    end

    light = Instance.new("PointLight")
    light.Name = name
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = true
    light.Parent = parent
    return light
end

local function clearLegacyWorld()
    local existing = Workspace:FindFirstChild(ROOT_NAME)
    if existing then
        existing:Destroy()
    end

    Terrain:Clear()

    for _, attributeName in ipairs({
        "PromptWorldTitle",
        "PromptWorldTheme",
        "PromptWorldTerrain",
        "PromptWorldScale",
        "PromptWorldRadius",
        "PromptWorldGenerationSeed",
        "PromptWorldRenderStyle",
        "PromptWorldTerrainColumnCount",
        "PromptWorldTerrainCellSize",
        "PromptWorldWaterFeature",
        "PromptWorldOptimizationFlow",
        "PromptWorldOriginalityMode",
        "PromptWorldOriginalitySignature",
        "PromptWorldMushroomCount",
        "PromptWorldHeroMushroomCount",
        "PromptWorldRuinClusterCount",
        "PromptWorldHeroLightCount",
        "PromptWorldCreatorStoreFoliage",
        "PromptWorldCreatorStoreTreeAsset",
        "PromptWorldCreatorStoreTreeCount",
        "PromptWorldCreatorStoreAssetCount",
        "PromptWorldCreatorStorePlacedInstanceCount",
        "PromptWorldCreatorStoreAssetUsage",
    }) do
        Workspace:SetAttribute(attributeName, nil)
    end
end

local function applyLighting(assetStyles, worldSpec)
    local isSnow = worldSpec.terrain == "snow"
    Lighting.ClockTime = isSnow and 14.8 or 15.3
    Lighting.Brightness = isSnow and 2.7 or 2.4
    Lighting.Ambient = isSnow and Color3.fromRGB(106, 122, 146) or Color3.fromRGB(86, 96, 114)
    Lighting.OutdoorAmbient = isSnow and Color3.fromRGB(170, 186, 210) or Color3.fromRGB(132, 150, 176)
    Lighting.EnvironmentDiffuseScale = 0.46
    Lighting.EnvironmentSpecularScale = 0.34
    Lighting.ExposureCompensation = 0.06
    Lighting.ShadowSoftness = 0.32
    Lighting.GlobalShadows = true

    local atmosphere = Lighting:FindFirstChild("GeneratedPromptAtmosphere")
    if atmosphere then
        atmosphere:Destroy()
    end
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "GeneratedPromptAtmosphere"
    atmosphere.Color = colorFromRGB(assetStyles.PrimaryAccentColorRGB, Color3.fromRGB(188, 212, 228))
    atmosphere.Decay = colorFromRGB(assetStyles.SecondaryAccentColorRGB, Color3.fromRGB(116, 138, 164))
    atmosphere.Density = isSnow and 0.22 or (worldSpec.terrain == "mountains" and 0.3 or 0.26)
    atmosphere.Offset = 0.04
    atmosphere.Glare = isSnow and 0.16 or 0.09
    atmosphere.Haze = isSnow and 0.95 or (worldSpec.terrain == "mountains" and 1.35 or 1.55)
    atmosphere.Parent = Lighting

    local bloom = Lighting:FindFirstChild("GeneratedPromptBloom")
    if bloom then
        bloom:Destroy()
    end
    bloom = Instance.new("BloomEffect")
    bloom.Name = "GeneratedPromptBloom"
    bloom.Intensity = isSnow and 0.18 or 0.28
    bloom.Size = 22
    bloom.Threshold = 1.25
    bloom.Parent = Lighting

    local colorCorrection = Lighting:FindFirstChild("GeneratedPromptColorCorrection")
    if colorCorrection then
        colorCorrection:Destroy()
    end
    colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "GeneratedPromptColorCorrection"
    colorCorrection.Brightness = 0.02
    colorCorrection.Contrast = 0.08
    colorCorrection.Saturation = 0
    colorCorrection.TintColor = Color3.fromRGB(255, 250, 245)
    colorCorrection.Parent = Lighting
end

local function deriveOptimizationProfile(worldSpec, worldSize, terrainKind)
    local isLarge = worldSpec.scale == "large"
    local isMedium = worldSpec.scale == "medium"
    local profile = {
        RenderResolution = 4,
        ControlCellSize = isLarge and 28 or (isMedium and 24 or 20),
        TopsoilDepth = isLarge and 8 or 6,
        InterpolatedDetailScale = terrainKind == "mountains" and 96 or 120,
        InterpolatedDetailAmplitude = terrainKind == "mountains" and 4 or 3,
        ControlBlurPasses = terrainKind == "mountains" and 2 or 3,
        ControlBlurStrength = terrainKind == "mountains" and 0.48 or 0.56,
        ThermalIterations = terrainKind == "mountains" and 2 or 3,
        ThermalTalus = terrainKind == "mountains" and 14 or 10,
        ThermalStrength = terrainKind == "mountains" and 0.18 or 0.22,
        DrainageIterations = terrainKind == "mountains" and 2 or 1,
        DrainageStrength = terrainKind == "mountains" and 0.6 or 0.35,
        RowYieldInterval = isLarge and 4 or 6,
        TerrainChunkCells = isLarge and 20 or 24,
        HeroMushroomCount = terrainKind == "forest" and (isLarge and 18 or 12) or 0,
        AmbientMushroomCount = terrainKind == "forest" and (isLarge and 40 or 24) or 0,
        FarMushroomCount = terrainKind == "forest" and (isLarge and 24 or 12) or 0,
        HeroLightBudget = terrainKind == "forest" and 10 or 6,
        RuinClusterCount = isLarge and 5 or 3,
        HeroRuinCount = isLarge and 2 or 1,
        RuinShardBudget = isLarge and 7 or 5,
        OriginalityMode = "fresh-procedural-assets",
        OptimizationFlow = "topographic-heightfield erosion chunked-voxels hero-budgets",
    }

    if terrainKind == "mountains" then
        profile.HeroMushroomCount = 8
        profile.AmbientMushroomCount = 12
        profile.FarMushroomCount = 0
        profile.HeroLightBudget = 6
    end

    return profile
end

local function randomPolarPosition(rng, minimumRadius, maximumRadius, zBias)
    local angle = rng:NextNumber(0, math.pi * 2)
    local radial = rng:NextNumber(minimumRadius, maximumRadius)
    return {
        x = math.cos(angle) * radial,
        z = (math.sin(angle) * radial) + (zBias or 0),
    }
end

local function deriveForestVariation(rng)
    local mounds = {}
    local clearings = {}
    local scars = {}

    for _ = 1, rng:NextInteger(5, 7) do
        local center = randomPolarPosition(rng, 0.08, 0.5, -rng:NextNumber(0.04, 0.18))
        table.insert(mounds, {
            x = center.x,
            z = center.z,
            widthX = rng:NextNumber(0.12, 0.28),
            widthZ = rng:NextNumber(0.1, 0.24),
            height = rng:NextNumber(24, 68),
        })
    end

    for _ = 1, rng:NextInteger(3, 5) do
        local center = randomPolarPosition(rng, 0.02, 0.44, rng:NextNumber(-0.16, 0.18))
        table.insert(clearings, {
            x = center.x,
            z = center.z,
            widthX = rng:NextNumber(0.1, 0.2),
            widthZ = rng:NextNumber(0.08, 0.18),
            depth = rng:NextNumber(16, 34),
        })
    end

    for index = 1, rng:NextInteger(2, 4) do
        table.insert(scars, {
            offsetX = rng:NextNumber(-220, 220),
            offsetZ = rng:NextNumber(-220, 220),
            scale = rng:NextNumber(150, 280),
            width = rng:NextNumber(0.06, 0.12),
            depth = rng:NextNumber(10, 24),
            seed = 600 + (index * 73) + rng:NextInteger(0, 120),
        })
    end

    return {
        SpineZ = rng:NextNumber(-0.12, 0.12),
        SpineWidth = rng:NextNumber(0.2, 0.34),
        SpineHeight = rng:NextNumber(16, 46),
        MacroScale = rng:NextNumber(220, 360),
        MacroAmplitude = rng:NextNumber(18, 34),
        RidgeScale = rng:NextNumber(130, 220),
        RidgeAmplitude = rng:NextNumber(10, 18),
        CanopyBias = rng:NextNumber(8, 20),
        EdgeDrop = rng:NextNumber(84, 138),
        Mounds = mounds,
        Clearings = clearings,
        Scars = scars,
    }
end

local function deriveSnowVariation(pillarCount, rng)
    local pillarSeeds = {
        {-0.34, -0.28},
        {0.34, -0.26},
        {-0.28, 0.2},
        {0.28, 0.24},
        {-0.04, -0.34},
        {0.02, 0.34},
    }
    local pillars = {}
    local resolvedCount = math.max(1, math.min(pillarCount or 4, #pillarSeeds))

    for index = 1, resolvedCount do
        local seedPosition = pillarSeeds[index]
        pillars[index] = {
            x = seedPosition[1] + rng:NextNumber(-0.04, 0.04),
            z = seedPosition[2] + rng:NextNumber(-0.05, 0.05),
            flatRadius = rng:NextNumber(0.07, 0.11),
            outerRadius = rng:NextNumber(0.14, 0.19),
            shoulderRadius = rng:NextNumber(0.22, 0.28),
            topHeight = rng:NextNumber(176, 238),
            shoulderHeight = rng:NextNumber(54, 88),
            crownNoiseScale = rng:NextNumber(24, 46),
        }
    end

    return {
        Pillars = pillars,
        DriftScale = rng:NextNumber(180, 260),
        DriftAmplitude = rng:NextNumber(8, 18),
        RidgeScale = rng:NextNumber(100, 160),
        RidgeAmplitude = rng:NextNumber(4, 10),
        BasinDepth = rng:NextNumber(16, 28),
        EdgeDrop = rng:NextNumber(92, 128),
        PillarBridgeHeight = rng:NextNumber(14, 28),
    }
end

local function deriveLayout(worldSpec, seed)
    local rng = Random.new(seed)
    local scaleMap = {
        small = 896,
        medium = 1152,
        large = 1408,
    }
    local worldSize = scaleMap[worldSpec.scale or "large"] or 1152
    local terrainKind = "frontier"
    if worldSpec.terrain == "mountains" then
        terrainKind = "mountains"
    elseif worldSpec.terrain == "snow" then
        terrainKind = "snow"
    elseif worldSpec.terrain == "forest" then
        terrainKind = "forest"
    elseif worldSpec.terrain == "islands" then
        terrainKind = "islands"
    elseif string.find(string.lower(worldSpec.theme or ""), "desert", 1, true) then
        terrainKind = "canyon"
    end

    local optimization = deriveOptimizationProfile(worldSpec, worldSize, terrainKind)

    local waterLevel = 18
    if terrainKind == "mountains" then
        waterLevel = -40
    elseif terrainKind == "snow" then
        waterLevel = -96
    elseif terrainKind == "islands" then
        waterLevel = 28
    elseif terrainKind == "canyon" then
        waterLevel = -56
    end

    return {
        seed = seed,
        terrainKind = terrainKind,
        worldSize = worldSize,
        cellSize = optimization.RenderResolution,
        baseY = (terrainKind == "mountains" or terrainKind == "snow") and -208 or -160,
        topsoilDepth = optimization.TopsoilDepth,
        waterLevel = waterLevel,
        snowLine = (terrainKind == "mountains" or terrainKind == "snow") and 210 or 999,
        spawnCenter = terrainKind == "snow" and Vector3.new(0, 0, worldSize * 0.4) or Vector3.new(0, 0, worldSize * 0.34),
        spawnHeight = (terrainKind == "mountains" or terrainKind == "snow") and 78 or 56,
        spawnFlattenRadius = 92,
        mountainRangeCount = math.max(terrainKind == "snow" and 4 or 3, worldSpec.mountain_range_count or 3),
        valleyCount = math.max(2, worldSpec.valley_count or 2),
        lakeCenter = Vector3.new(0, 0, worldSize * 0.22),
        peakCenter = terrainKind == "snow" and Vector3.new(0, 0, -(worldSize * 0.08)) or Vector3.new(0, 0, -(worldSize * 0.22)),
        hasLake = worldSpec.water_feature == "lake" or terrainKind == "mountains",
        hasWaterBodies = worldSpec.water_feature == "lake" or terrainKind == "mountains" or terrainKind == "islands",
        waterFeature = worldSpec.water_feature or "",
        optimization = optimization,
        originalitySignature = resolveOriginalitySignature(seed),
        variation = {
            WestRidgeCenter = -0.58 + rng:NextNumber(-0.08, 0.08),
            CentralRidgeCenter = rng:NextNumber(-0.05, 0.05),
            EastRidgeCenter = 0.58 + rng:NextNumber(-0.08, 0.08),
            ValleyOffset = rng:NextNumber(0.17, 0.28),
            SummitX = rng:NextNumber(-0.08, 0.08),
            SummitZ = -0.44 + rng:NextNumber(-0.08, 0.05),
            PeakCrownZ = -0.28 + rng:NextNumber(-0.06, 0.05),
            LakeX = rng:NextNumber(-0.08, 0.08),
            LakeZ = 0.5 + rng:NextNumber(-0.06, 0.04),
            MacroScale = rng:NextNumber(220, 340),
            MacroAmplitude = rng:NextNumber(14, 24),
            RidgeScale = rng:NextNumber(150, 220),
            RidgeAmplitude = rng:NextNumber(10, 18),
            Forest = deriveForestVariation(rng),
            Snow = deriveSnowVariation(worldSpec.ice_pillar_count or 4, rng),
        },
    }
end

local function sampleMountainHeight(layout, x, z)
    local xNorm = x / (layout.worldSize * 0.5)
    local zNorm = z / (layout.worldSize * 0.5)
    local northWeight = 1 - inverseLerp(-1, 1, zNorm)
    local variation = layout.variation

    local baseSlope = 18 + (northWeight * 42)
    local westRidge = gaussian1(xNorm, variation.WestRidgeCenter, 0.24) * (78 + (northWeight * 54))
    local centralRidge = gaussian1(xNorm, variation.CentralRidgeCenter, 0.2) * (110 + (northWeight * 78))
    local eastRidge = gaussian1(xNorm, variation.EastRidgeCenter, 0.24) * (78 + (northWeight * 54))
    local westValley = gaussian1(xNorm, -variation.ValleyOffset, 0.1) * (46 + (northWeight * 24))
    local eastValley = gaussian1(xNorm, variation.ValleyOffset, 0.1) * (46 + (northWeight * 24))
    local summitMass = gaussian2(xNorm, zNorm, variation.SummitX, variation.SummitZ, 0.24, 0.18) * 154
    local peakCrown = gaussian2(xNorm, zNorm, variation.SummitX, variation.PeakCrownZ, 0.18, 0.14) * 84
    local lakeBasin = layout.hasLake and gaussian2(xNorm, zNorm, variation.LakeX, variation.LakeZ, 0.24, 0.16) * 124 or 0

    local macroNoise = fractal2D(x, z, variation.MacroScale, 4, 2, 0.5, layout.seed + 31) * variation.MacroAmplitude
    local ridgeNoise = ridge2D(x, z, variation.RidgeScale, 3, 2, 0.5, layout.seed + 173) * variation.RidgeAmplitude

    local height = 28
        + baseSlope
        + westRidge
        + centralRidge
        + eastRidge
        + summitMass
        + peakCrown
        - westValley
        - eastValley
        - lakeBasin
        + macroNoise
        + ridgeNoise

    local spawnDx = x - layout.spawnCenter.X
    local spawnDz = z - layout.spawnCenter.Z
    local spawnDistance = math.sqrt((spawnDx * spawnDx) + (spawnDz * spawnDz))
    if spawnDistance < layout.spawnFlattenRadius then
        local alpha = smoothstep(layout.spawnFlattenRadius * 0.45, layout.spawnFlattenRadius, spawnDistance)
        height = lerp(layout.spawnHeight, height, alpha)
    end

    return clamp(height, layout.baseY + 36, 280)
end

local function sampleForestHeight(layout, x, z)
    local xNorm = x / (layout.worldSize * 0.5)
    local zNorm = z / (layout.worldSize * 0.5)
    local radial = math.sqrt((xNorm * xNorm) + (zNorm * zNorm))
    local variation = layout.variation.Forest

    local moundHeight = 0
    for _, mound in ipairs(variation.Mounds) do
        moundHeight += gaussian2(xNorm, zNorm, mound.x, mound.z, mound.widthX, mound.widthZ) * mound.height
    end

    local clearingDepth = 0
    for _, clearing in ipairs(variation.Clearings) do
        clearingDepth += gaussian2(xNorm, zNorm, clearing.x, clearing.z, clearing.widthX, clearing.widthZ) * clearing.depth
    end

    local scarCut = 0
    for _, scar in ipairs(variation.Scars) do
        local scarNoise = math.abs(fractal2D(x + scar.offsetX, z + scar.offsetZ, scar.scale, 2, 2, 0.5, layout.seed + scar.seed))
        if scarNoise < scar.width then
            scarCut += (1 - (scarNoise / scar.width)) * scar.depth
        end
    end

    local worldSpine = gaussian1(zNorm, variation.SpineZ, variation.SpineWidth) * variation.SpineHeight
    local canopyNoise = fractal2D(x, z, variation.MacroScale, 4, 2, 0.5, layout.seed + 71) * variation.MacroAmplitude
    local ridgeNoise = ridge2D(x, z, variation.RidgeScale, 3, 2, 0.5, layout.seed + 139) * variation.RidgeAmplitude
    local edgeDrop = smoothstep(0.72, 1.02, radial) * variation.EdgeDrop

    local height = 86
        + variation.CanopyBias
        + worldSpine
        + moundHeight
        + canopyNoise
        + ridgeNoise
        - clearingDepth
        - scarCut
        - edgeDrop

    local spawnDx = x - layout.spawnCenter.X
    local spawnDz = z - layout.spawnCenter.Z
    local spawnDistance = math.sqrt((spawnDx * spawnDx) + (spawnDz * spawnDz))
    if spawnDistance < layout.spawnFlattenRadius then
        local alpha = smoothstep(layout.spawnFlattenRadius * 0.45, layout.spawnFlattenRadius, spawnDistance)
        height = lerp(layout.spawnHeight, height, alpha)
    end

    return clamp(height, layout.baseY + 30, 238)
end

local function pillarContribution(distance, flatRadius, outerRadius, shoulderRadius, topHeight, shoulderHeight)
    if distance <= flatRadius then
        return topHeight + shoulderHeight
    end
    if distance <= outerRadius then
        local alpha = smoothstep(flatRadius, outerRadius, distance)
        return lerp(topHeight + shoulderHeight, shoulderHeight, alpha)
    end
    if distance <= shoulderRadius then
        local alpha = smoothstep(outerRadius, shoulderRadius, distance)
        return lerp(shoulderHeight, 0, alpha)
    end
    return 0
end

local function sampleSnowHeight(layout, x, z)
    local xNorm = x / (layout.worldSize * 0.5)
    local zNorm = z / (layout.worldSize * 0.5)
    local radial = math.sqrt((xNorm * xNorm) + (zNorm * zNorm))
    local variation = layout.variation.Snow

    local baseSnow = 44
        + (fractal2D(x, z, variation.DriftScale, 4, 2, 0.5, layout.seed + 211) * variation.DriftAmplitude)
        + (ridge2D(x, z, variation.RidgeScale, 2, 2, 0.5, layout.seed + 317) * variation.RidgeAmplitude)

    local centralBasin = gaussian2(xNorm, zNorm, 0, -0.02, 0.34, 0.26) * variation.BasinDepth
    local pillarHeight = 0

    for _, pillar in ipairs(variation.Pillars) do
        local distance = math.sqrt(((xNorm - pillar.x) * (xNorm - pillar.x)) + ((zNorm - pillar.z) * (zNorm - pillar.z)))
        pillarHeight += pillarContribution(
            distance,
            pillar.flatRadius,
            pillar.outerRadius,
            pillar.shoulderRadius,
            pillar.topHeight,
            pillar.shoulderHeight
        )
    end

    local northBridge = gaussian2(xNorm, zNorm, 0, -0.26, 0.18, 0.1) * variation.PillarBridgeHeight
    local southBridge = gaussian2(xNorm, zNorm, 0, 0.24, 0.16, 0.1) * (variation.PillarBridgeHeight * 0.7)
    local edgeDrop = smoothstep(0.84, 1.02, radial) * variation.EdgeDrop

    local spawnDx = x - layout.spawnCenter.X
    local spawnDz = z - layout.spawnCenter.Z
    local spawnDistance = math.sqrt((spawnDx * spawnDx) + (spawnDz * spawnDz))

    local height = baseSnow + pillarHeight + northBridge + southBridge - centralBasin - edgeDrop
    if spawnDistance < layout.spawnFlattenRadius then
        local alpha = smoothstep(layout.spawnFlattenRadius * 0.35, layout.spawnFlattenRadius, spawnDistance)
        height = lerp(layout.spawnHeight, height, alpha)
    end

    return clamp(height, layout.baseY + 30, 324)
end

local function sampleIslandHeight(layout, x, z)
    local distance = math.sqrt((x * x) + (z * z))
    local radius = layout.worldSize * 0.42
    local radial = 1 - clamp(distance / radius, 0, 1)
    local dome = smoothstep(0, 1, radial) * 168
    local crater = gaussian2(x / radius, z / radius, 0.08, -0.06, 0.18, 0.16) * 42
    local noise = fractal2D(x, z, 240, 4, 2, 0.5, layout.seed + 53) * 20
    local ridgeNoise = ridge2D(x, z, 132, 3, 2, 0.5, layout.seed + 307) * 10
    return clamp(layout.waterLevel - 24 + dome + ridgeNoise + noise - crater, layout.baseY + 28, 210)
end

local function sampleCanyonHeight(layout, x, z)
    local plateau = 108 + (fractal2D(x, z, 320, 4, 2, 0.48, layout.seed + 97) * 24)
    local canyonA = math.abs(fractal2D(x, z, 148, 3, 2, 0.5, layout.seed + 211))
    local canyonB = math.abs(fractal2D(x + 210, z - 140, 184, 2, 2, 0.5, layout.seed + 263))
    local canyonCut = 0
    if canyonA < 0.12 then
        canyonCut += (1 - (canyonA / 0.12)) * 120
    end
    if canyonB < 0.09 then
        canyonCut += (1 - (canyonB / 0.09)) * 66
    end
    return clamp(plateau - canyonCut, layout.baseY + 28, 220)
end

local function sampleFrontierHeight(layout, x, z)
    local hills = fractal2D(x, z, 300, 4, 2, 0.5, layout.seed + 67) * 58
    local ridges = ridge2D(x, z, 180, 3, 2, 0.5, layout.seed + 149) * 18
    local basin = gaussian2(x / (layout.worldSize * 0.5), z / (layout.worldSize * 0.5), 0, 0.18, 0.28, 0.22) * 34
    local riverLine = math.abs(fractal2D(x, z, 176, 2, 2, 0.5, layout.seed + 281))
    local riverCut = riverLine < 0.11 and (1 - (riverLine / 0.11)) * 24 or 0
    return clamp(72 + hills + ridges - basin - riverCut, layout.baseY + 28, 190)
end

local function sampleSeedHeight(layout, x, z)
    if layout.terrainKind == "mountains" then
        return sampleMountainHeight(layout, x, z)
    end
    if layout.terrainKind == "snow" then
        return sampleSnowHeight(layout, x, z)
    end
    if layout.terrainKind == "forest" then
        return sampleForestHeight(layout, x, z)
    end
    if layout.terrainKind == "islands" then
        return sampleIslandHeight(layout, x, z)
    end
    if layout.terrainKind == "canyon" then
        return sampleCanyonHeight(layout, x, z)
    end
    return sampleFrontierHeight(layout, x, z)
end

local function sampleSeedMoisture(layout, x, z)
    return clamp((fractal2D(x, z, 260, 3, 2, 0.5, layout.seed + 401) + 1) * 0.5, 0, 1)
end

local function alignDown(value, step)
    return math.floor(value / step) * step
end

local function alignUp(value, step)
    return math.ceil(value / step) * step
end

local function createScalarGrid(countX, countZ, initialValue)
    local grid = table.create(countX)
    for ix = 1, countX do
        local row = table.create(countZ)
        for iz = 1, countZ do
            row[iz] = initialValue
        end
        grid[ix] = row
    end
    return grid
end

local function copyScalarGrid(source)
    local copy = table.create(#source)
    for ix = 1, #source do
        local row = table.create(#source[ix])
        for iz = 1, #source[ix] do
            row[iz] = source[ix][iz]
        end
        copy[ix] = row
    end
    return copy
end

local function blurHeightGrid(grid, passes, blendStrength)
    local countX = #grid
    local countZ = #grid[1]

    for _ = 1, passes do
        local nextGrid = copyScalarGrid(grid)
        for ix = 2, countX - 1 do
            for iz = 2, countZ - 1 do
                local weightedAverage =
                    (grid[ix][iz] * 4)
                    + ((grid[ix - 1][iz] + grid[ix + 1][iz] + grid[ix][iz - 1] + grid[ix][iz + 1]) * 2)
                    + (grid[ix - 1][iz - 1] + grid[ix + 1][iz - 1] + grid[ix - 1][iz + 1] + grid[ix + 1][iz + 1])
                weightedAverage /= 16
                nextGrid[ix][iz] = lerp(grid[ix][iz], weightedAverage, blendStrength)
            end
        end
        grid = nextGrid
    end

    return grid
end

local function applyThermalErosion(grid, talus, strength, iterations)
    local countX = #grid
    local countZ = #grid[1]

    for _ = 1, iterations do
        local deltas = createScalarGrid(countX, countZ, 0)
        for ix = 2, countX - 1 do
            for iz = 2, countZ - 1 do
                local current = grid[ix][iz]
                local transfers = {}
                local totalTransfer = 0

                for offsetX = -1, 1 do
                    for offsetZ = -1, 1 do
                        if not (offsetX == 0 and offsetZ == 0) then
                            local neighborX = ix + offsetX
                            local neighborZ = iz + offsetZ
                            local delta = current - grid[neighborX][neighborZ]
                            if delta > talus then
                                local transfer = (delta - talus) * strength
                                totalTransfer += transfer
                                table.insert(transfers, {
                                    X = neighborX,
                                    Z = neighborZ,
                                    Amount = transfer,
                                })
                            end
                        end
                    end
                end

                if totalTransfer > 0 then
                    deltas[ix][iz] -= totalTransfer
                    for _, transfer in ipairs(transfers) do
                        deltas[transfer.X][transfer.Z] += transfer.Amount
                    end
                end
            end
        end

        for ix = 2, countX - 1 do
            for iz = 2, countZ - 1 do
                grid[ix][iz] += deltas[ix][iz]
            end
        end
    end

    return grid
end

local function applyDrainageErosion(grid, moistureGrid, strength, iterations)
    local countX = #grid
    local countZ = #grid[1]

    for _ = 1, iterations do
        local nextGrid = copyScalarGrid(grid)
        for ix = 2, countX - 1 do
            for iz = 2, countZ - 1 do
                local current = grid[ix][iz]
                local wetness = moistureGrid[ix][iz]
                local lowestHeight = current
                local lowestX = ix
                local lowestZ = iz

                for offsetX = -1, 1 do
                    for offsetZ = -1, 1 do
                        if not (offsetX == 0 and offsetZ == 0) then
                            local neighborX = ix + offsetX
                            local neighborZ = iz + offsetZ
                            local neighborHeight = grid[neighborX][neighborZ]
                            if neighborHeight < lowestHeight then
                                lowestHeight = neighborHeight
                                lowestX = neighborX
                                lowestZ = neighborZ
                            end
                        end
                    end
                end

                local drop = current - lowestHeight
                if drop > 0 and wetness > 0.46 then
                    local erosion = math.min(drop * 0.18, wetness * strength * 3.4)
                    nextGrid[ix][iz] -= erosion
                    nextGrid[lowestX][lowestZ] += erosion * 0.22
                end
            end
        end
        grid = nextGrid
    end

    return grid
end

local function buildTopography(layout)
    local controlCellSize = layout.optimization.ControlCellSize
    local worldMin = -(layout.worldSize * 0.5)
    local controlCount = math.floor(layout.worldSize / controlCellSize) + 1
    local heights = createScalarGrid(controlCount, controlCount, 0)
    local moistures = createScalarGrid(controlCount, controlCount, 0)
    local minimumHeight = math.huge
    local maximumHeight = -math.huge

    for ix = 1, controlCount do
        local worldX = worldMin + ((ix - 1) * controlCellSize)
        for iz = 1, controlCount do
            local worldZ = worldMin + ((iz - 1) * controlCellSize)
            local height = sampleSeedHeight(layout, worldX, worldZ)
            local moisture = sampleSeedMoisture(layout, worldX, worldZ)
            heights[ix][iz] = height
            moistures[ix][iz] = moisture
            minimumHeight = math.min(minimumHeight, height)
            maximumHeight = math.max(maximumHeight, height)
        end

        if ix % layout.optimization.RowYieldInterval == 0 then
            task.wait()
        end
    end

    heights = blurHeightGrid(heights, layout.optimization.ControlBlurPasses, layout.optimization.ControlBlurStrength)
    heights = applyThermalErosion(
        heights,
        layout.optimization.ThermalTalus,
        layout.optimization.ThermalStrength,
        layout.optimization.ThermalIterations
    )
    heights = applyDrainageErosion(
        heights,
        moistures,
        layout.optimization.DrainageStrength,
        layout.optimization.DrainageIterations
    )

    minimumHeight = math.huge
    maximumHeight = -math.huge
    for ix = 1, controlCount do
        for iz = 1, controlCount do
            minimumHeight = math.min(minimumHeight, heights[ix][iz])
            maximumHeight = math.max(maximumHeight, heights[ix][iz])
        end
    end

    return {
        Heights = heights,
        Moistures = moistures,
        Count = controlCount,
        CellSize = controlCellSize,
        MinX = worldMin,
        MinZ = worldMin,
        MaxX = worldMin + ((controlCount - 1) * controlCellSize),
        MaxZ = worldMin + ((controlCount - 1) * controlCellSize),
        MinHeight = minimumHeight,
        MaxHeight = maximumHeight,
    }
end

local function sampleGridBilinear(grid, topography, x, z)
    local normalizedX = clamp((x - topography.MinX) / topography.CellSize, 0, topography.Count - 1)
    local normalizedZ = clamp((z - topography.MinZ) / topography.CellSize, 0, topography.Count - 1)
    local x0 = math.clamp(math.floor(normalizedX) + 1, 1, topography.Count)
    local z0 = math.clamp(math.floor(normalizedZ) + 1, 1, topography.Count)
    local x1 = math.clamp(x0 + 1, 1, topography.Count)
    local z1 = math.clamp(z0 + 1, 1, topography.Count)
    local alphaX = normalizedX - math.floor(normalizedX)
    local alphaZ = normalizedZ - math.floor(normalizedZ)

    local row0 = lerp(grid[x0][z0], grid[x1][z0], alphaX)
    local row1 = lerp(grid[x0][z1], grid[x1][z1], alphaX)
    return lerp(row0, row1, alphaZ)
end

local function sampleHeight(layout, x, z)
    if not layout.topography then
        return sampleSeedHeight(layout, x, z)
    end

    local baseHeight = sampleGridBilinear(layout.topography.Heights, layout.topography, x, z)
    local detail = fractal2D(
        x,
        z,
        layout.optimization.InterpolatedDetailScale,
        2,
        2,
        0.5,
        layout.seed + 883
    ) * layout.optimization.InterpolatedDetailAmplitude

    return clamp(baseHeight + detail, layout.baseY + layout.cellSize, layout.topography.MaxHeight + 24)
end

local function sampleMoisture(layout, x, z)
    if not layout.topography then
        return sampleSeedMoisture(layout, x, z)
    end
    return sampleGridBilinear(layout.topography.Moistures, layout.topography, x, z)
end

local function estimateSlope(layout, x, z)
    local step = layout.cellSize * 2
    local left = sampleHeight(layout, x - step, z)
    local right = sampleHeight(layout, x + step, z)
    local up = sampleHeight(layout, x, z - step)
    local down = sampleHeight(layout, x, z + step)
    return math.max(math.abs(left - right), math.abs(up - down)) / (step * 2)
end

local function resolveMaterials(layout, x, z, height, moisture, slope)
    if layout.terrainKind == "snow" then
        if slope > 1.8 then
            return Enum.Material.Rock, Enum.Material.Glacier
        end
        if height > layout.baseY + 170 then
            return Enum.Material.Glacier, Enum.Material.Snow
        end
        return Enum.Material.Rock, Enum.Material.Snow
    end
    if height > layout.snowLine then
        return Enum.Material.Rock, Enum.Material.Snow
    end
    if layout.terrainKind == "canyon" then
        if slope > 2.1 then
            return Enum.Material.Rock, Enum.Material.Rock
        end
        return Enum.Material.Sandstone, Enum.Material.Sand
    end
    if layout.terrainKind == "islands" and height < layout.waterLevel + 16 then
        return Enum.Material.Sand, Enum.Material.Sand
    end
    if slope > 2.3 then
        return Enum.Material.Rock, Enum.Material.Rock
    end
    if moisture > 0.56 then
        return Enum.Material.Ground, Enum.Material.Grass
    end
    return Enum.Material.Rock, Enum.Material.Ground
end

local function writeTerrainChunk(layout, chunkMinX, chunkMaxX, chunkMinZ, chunkMaxZ, minY, maxY)
    local resolution = layout.cellSize
    local cellsX = math.floor((chunkMaxX - chunkMinX) / resolution)
    local cellsY = math.floor((maxY - minY) / resolution)
    local cellsZ = math.floor((chunkMaxZ - chunkMinZ) / resolution)
    local materials = table.create(cellsX)
    local occupancies = table.create(cellsX)
    local columns = table.create(cellsX)

    for ix = 1, cellsX do
        materials[ix] = table.create(cellsY)
        occupancies[ix] = table.create(cellsY)
        columns[ix] = table.create(cellsZ)

        local worldX = chunkMinX + ((ix - 0.5) * resolution)
        for iy = 1, cellsY do
            materials[ix][iy] = table.create(cellsZ)
            occupancies[ix][iy] = table.create(cellsZ)
        end

        for iz = 1, cellsZ do
            local worldZ = chunkMinZ + ((iz - 0.5) * resolution)
            local height = sampleHeight(layout, worldX, worldZ)
            local moisture = sampleMoisture(layout, worldX, worldZ)
            local slope = estimateSlope(layout, worldX, worldZ)
            local bodyMaterial, surfaceMaterial = resolveMaterials(layout, worldX, worldZ, height, moisture, slope)
            columns[ix][iz] = {
                Height = height,
                BodyMaterial = bodyMaterial,
                SurfaceMaterial = surfaceMaterial,
            }
        end
    end

    for ix = 1, cellsX do
        for iy = 1, cellsY do
            local voxelBottom = minY + ((iy - 1) * resolution)
            local voxelTop = voxelBottom + resolution
            for iz = 1, cellsZ do
                local column = columns[ix][iz]
                local solidOccupancy = clamp((column.Height - voxelBottom) / resolution, 0, 1)
                local material = Enum.Material.Air
                local occupancy = 0

                if solidOccupancy > 0 then
                    occupancy = solidOccupancy
                    if voxelTop >= column.Height - layout.topsoilDepth then
                        material = column.SurfaceMaterial
                    else
                        material = column.BodyMaterial
                    end
                elseif layout.hasWaterBodies and column.Height < layout.waterLevel and voxelBottom < layout.waterLevel then
                    occupancy = clamp((layout.waterLevel - voxelBottom) / resolution, 0, 1)
                    material = Enum.Material.Water
                end

                materials[ix][iy][iz] = material
                occupancies[ix][iy][iz] = occupancy
            end
        end

        if ix % layout.optimization.RowYieldInterval == 0 then
            task.wait()
        end
    end

    local region = Region3.new(
        Vector3.new(chunkMinX, minY, chunkMinZ),
        Vector3.new(chunkMaxX, maxY, chunkMaxZ)
    )
    Terrain:WriteVoxels(region, resolution, materials, occupancies)
    return cellsX * cellsZ
end

local function fillTerrainRibbon(nodes, width, thickness)
    local count = 0
    for index = 1, #nodes - 1 do
        local fromPosition = nodes[index]
        local toPosition = nodes[index + 1]
        local delta = toPosition - fromPosition
        local distance = delta.Magnitude
        if distance > 0.5 then
            local midpoint = fromPosition:Lerp(toPosition, 0.5)
            local upVector = math.abs(delta.Unit:Dot(Vector3.new(0, 1, 0))) > 0.94 and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
            Terrain:FillBlock(CFrame.lookAt(midpoint, toPosition, upVector), Vector3.new(width, thickness, distance), Enum.Material.Water)
            count += 1
        end
    end
    return count
end

local function addWaterfallSheet(parent, name, topPosition, bottomPosition, width, palette)
    local drop = topPosition - bottomPosition
    local height = math.max(14, math.abs(drop.Y) + 6)
    local midpoint = Vector3.new(
        (topPosition.X + bottomPosition.X) * 0.5,
        (topPosition.Y + bottomPosition.Y) * 0.5,
        (topPosition.Z + bottomPosition.Z) * 0.5
    )
    local horizontalTarget = Vector3.new(bottomPosition.X, midpoint.Y, bottomPosition.Z)
    if (horizontalTarget - midpoint).Magnitude < 0.5 then
        horizontalTarget = midpoint + Vector3.new(0, 0, -1)
    end
    local facing = CFrame.lookAt(midpoint, horizontalTarget)
    local sheet = createModel(parent, name)

    local shell = makePart(sheet, "Shell", Vector3.new(width, height, 3.6), facing, {
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(104, 176, 220),
        Transparency = 0.14,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    local core = makePart(sheet, "Core", Vector3.new(width * 0.5, height, 1.4), facing * CFrame.new(0, 0, -0.7), {
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(178, 234, 255),
        Transparency = 0.24,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    addPointLight(core, "WaterGlow", palette.Highlight, 2.2, math.max(20, width * 1.8))
    makeBall(sheet, "Mist", Vector3.new(width * 0.7, width * 0.42, width * 0.7), CFrame.new(bottomPosition + Vector3.new(0, 4.2, 0)), {
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(180, 236, 255),
        Transparency = 0.48,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    return shell
end

local function terrainPosition(layout, x, z, lift)
    return Vector3.new(x, sampleHeight(layout, x, z) + (lift or 0), z)
end

local function buildTerrain(root, layout, worldSpec)
    local topography = buildTopography(layout)
    layout.topography = topography

    local halfSize = layout.worldSize * 0.5
    local chunkSpan = layout.optimization.TerrainChunkCells * layout.cellSize
    local chunkCount = math.ceil(layout.worldSize / chunkSpan)
    local minY = alignDown(layout.baseY, layout.cellSize)
    local maxY = alignUp(topography.MaxHeight + 28, layout.cellSize)
    local totalColumns = 0

    for chunkXIndex = 1, chunkCount do
        local chunkMinX = alignDown(-halfSize + ((chunkXIndex - 1) * chunkSpan), layout.cellSize)
        local chunkMaxX = math.min(alignUp(chunkMinX + chunkSpan, layout.cellSize), halfSize)
        for chunkZIndex = 1, chunkCount do
            local chunkMinZ = alignDown(-halfSize + ((chunkZIndex - 1) * chunkSpan), layout.cellSize)
            local chunkMaxZ = math.min(alignUp(chunkMinZ + chunkSpan, layout.cellSize), halfSize)
            totalColumns += writeTerrainChunk(layout, chunkMinX, chunkMaxX, chunkMinZ, chunkMaxZ, minY, maxY)
        end
        task.wait()
    end

    Workspace:SetAttribute("PromptWorldTerrainColumnCount", totalColumns)
    Workspace:SetAttribute("PromptWorldTerrainCellSize", layout.cellSize)
    return topography
end

local function deriveMushroomSpeciesLibrary(palette, rng)
    local speciesLibrary = {}
    local capStyles = {"dome", "saucer", "bell", "tiered"}
    local colorAnchors = {
        blendColor(palette.Highlight, palette.Secondary, 0.35),
        blendColor(palette.Primary, palette.Highlight, 0.48),
        tintColor(palette.Base, 0.18, 0.06, 0.22),
        tintColor(palette.Secondary, 0.24, -0.02, 0.08),
        tintColor(palette.Highlight, 0.12, -0.08, 0.18),
    }

    for index = 1, 6 do
        local capBase = colorAnchors[((index - 1) % #colorAnchors) + 1]
        speciesLibrary[index] = {
            CapStyle = capStyles[rng:NextInteger(1, #capStyles)],
            StemColor = randomOffsetColor(rng, Color3.fromRGB(216, 205, 188), 0.06),
            CapColor = randomOffsetColor(rng, capBase, 0.1),
            UndersideColor = randomOffsetColor(rng, blendColor(capBase, Color3.fromRGB(255, 240, 220), 0.45), 0.06),
            GlowColor = randomOffsetColor(rng, blendColor(palette.Highlight, capBase, 0.42), 0.08),
            CollarColor = randomOffsetColor(rng, blendColor(palette.Base, Color3.fromRGB(240, 234, 220), 0.5), 0.05),
            CapThickness = rng:NextNumber(0.12, 0.26),
            CapWidth = rng:NextNumber(2.8, 5.2),
            SpotCount = rng:NextInteger(0, 7),
            FinCount = rng:NextInteger(0, 5),
            HasCollar = rng:NextNumber() > 0.35,
            GlowEnabled = rng:NextNumber() > 0.22,
            LeanPitch = rng:NextNumber(-8, 8),
            LeanRoll = rng:NextNumber(-8, 8),
        }
    end

    return speciesLibrary
end

local function deriveMushroomClusters(layout, rng)
    local optimization = layout.optimization
    local clusters = {}
    local heroClusters = math.max(2, math.floor(optimization.HeroMushroomCount / 8))
    local ambientClusters = math.max(2, math.floor(optimization.AmbientMushroomCount / 12))
    local farClusters = optimization.FarMushroomCount > 0 and 2 or 0
    local centerZBias = layout.terrainKind == "mountains" and (layout.peakCenter.Z / layout.worldSize) or -0.06
    local clusterSpecs = {
        {Count = optimization.HeroMushroomCount, Groups = heroClusters, DetailTier = "hero"},
        {Count = optimization.AmbientMushroomCount, Groups = ambientClusters, DetailTier = "ambient"},
        {Count = optimization.FarMushroomCount, Groups = farClusters, DetailTier = "far"},
    }

    for _, spec in ipairs(clusterSpecs) do
        if spec.Count > 0 and spec.Groups > 0 then
            local placed = 0
            for groupIndex = 1, spec.Groups do
                local remaining = spec.Count - placed
                local groupCount = groupIndex == spec.Groups and remaining or math.max(4, math.floor(spec.Count / spec.Groups))
                placed += groupCount
                local center = randomPolarPosition(rng, 0.06, 0.34, centerZBias + rng:NextNumber(-0.12, 0.12))
                table.insert(clusters, {
                    Count = groupCount,
                    DetailTier = spec.DetailTier,
                    Radius = layout.worldSize * rng:NextNumber(0.05, 0.11),
                    CenterX = center.x * layout.worldSize,
                    CenterZ = center.z * layout.worldSize,
                })
            end
        end
    end

    return clusters
end

local function addMushroom(parent, index, position, height, stemRadius, capRadius, species, detailTier, stats, optimization, rng)
    local folder = createModel(parent, string.format("Mushroom%03d", index))
    local stemCFrame = CFrame.new(position + Vector3.new(0, height * 0.5, 0))
        * CFrame.Angles(math.rad(species.LeanPitch), 0, math.rad(species.LeanRoll))

    makeVerticalCylinder(folder, "Stem", stemRadius, height, stemCFrame, {
        Material = Enum.Material.SmoothPlastic,
        Color = species.StemColor,
    })

    local capBaseHeight = math.max(3, capRadius * species.CapThickness)
    local capBaseY = position.Y + height + (capBaseHeight * 0.55)
    local capBaseCFrame = CFrame.new(position.X, capBaseY, position.Z)

    if species.CapStyle == "dome" then
        makeVerticalCylinder(folder, "CapBase", capRadius, capBaseHeight, capBaseCFrame, {
            Material = Enum.Material.SmoothPlastic,
            Color = species.CapColor,
        })
        makeBall(folder, "CapCrown", Vector3.new(capRadius * 1.55, capRadius * 1.18, capRadius * 1.55), CFrame.new(position.X, capBaseY + (capBaseHeight * 0.3), position.Z), {
            Material = Enum.Material.SmoothPlastic,
            Color = species.CapColor,
        })
    elseif species.CapStyle == "tiered" then
        makeVerticalCylinder(folder, "CapLower", capRadius, capBaseHeight, capBaseCFrame, {
            Material = Enum.Material.SmoothPlastic,
            Color = species.CapColor,
        })
        makeVerticalCylinder(folder, "CapUpper", capRadius * 0.72, capBaseHeight * 0.86, CFrame.new(position.X, capBaseY + (capBaseHeight * 0.48), position.Z), {
            Material = Enum.Material.SmoothPlastic,
            Color = tintColor(species.CapColor, 0.06, 0.04, 0.06),
        })
    elseif species.CapStyle == "bell" then
        makeVerticalCylinder(folder, "CapShell", capRadius * 0.92, capBaseHeight * 1.2, capBaseCFrame, {
            Material = Enum.Material.SmoothPlastic,
            Color = species.CapColor,
        })
        makeVerticalCylinder(folder, "CapLip", capRadius * 1.04, math.max(2, capBaseHeight * 0.26), CFrame.new(position.X, capBaseY - (capBaseHeight * 0.26), position.Z), {
            Material = Enum.Material.SmoothPlastic,
            Color = tintColor(species.CapColor, -0.04, -0.04, -0.02),
        })
    else
        makeVerticalCylinder(folder, "Cap", capRadius, math.max(3, capBaseHeight * 0.74), capBaseCFrame, {
            Material = Enum.Material.SmoothPlastic,
            Color = species.CapColor,
        })
    end

    makeVerticalCylinder(folder, "Undercap", capRadius * 0.78, math.max(2, capBaseHeight * 0.24), CFrame.new(position.X, position.Y + height + (capBaseHeight * 0.08), position.Z), {
        Material = Enum.Material.SmoothPlastic,
        Color = species.UndersideColor,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
    })

    if species.HasCollar and detailTier ~= "far" then
        makeVerticalCylinder(folder, "Collar", stemRadius * 1.26, math.max(1.2, stemRadius * 0.6), CFrame.new(position.X, position.Y + (height * 0.62), position.Z), {
            Material = Enum.Material.SmoothPlastic,
            Color = species.CollarColor,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
        })
    end

    if detailTier ~= "far" and species.SpotCount > 0 then
        local targetSpotCount = detailTier == "hero" and species.SpotCount or math.max(1, math.floor(species.SpotCount * 0.5))
        for spotIndex = 1, targetSpotCount do
            local angle = rng:NextNumber(0, math.pi * 2)
            local radius = capRadius * rng:NextNumber(0.2, 0.64)
            local spotScale = detailTier == "hero" and rng:NextNumber(0.9, 1.8) or rng:NextNumber(0.7, 1.2)
            makeBall(folder, "Spot" .. spotIndex, Vector3.new(spotScale, spotScale, spotScale), CFrame.new(position.X + (math.cos(angle) * radius), position.Y + height + (capBaseHeight * 0.46), position.Z + (math.sin(angle) * radius)), {
                Material = detailTier == "hero" and Enum.Material.Neon or Enum.Material.SmoothPlastic,
                Color = detailTier == "hero" and species.GlowColor or species.UndersideColor,
                Transparency = detailTier == "hero" and 0.06 or 0,
                CanCollide = false,
                CanTouch = false,
                CanQuery = false,
                CastShadow = false,
            })
        end
    end

    if detailTier == "hero" and species.FinCount > 0 then
        for finIndex = 1, species.FinCount do
            local angle = (finIndex / species.FinCount) * math.pi * 2
            local finOffset = Vector3.new(math.cos(angle) * capRadius * 0.52, height + (capBaseHeight * 0.12), math.sin(angle) * capRadius * 0.52)
            makePart(folder, "Fin" .. finIndex, Vector3.new(capRadius * 0.14, capRadius * 0.72, capRadius * 0.44), CFrame.new(position + finOffset) * CFrame.Angles(0, -angle, math.rad(rng:NextNumber(-12, 12))), {
                Material = Enum.Material.Neon,
                Color = species.GlowColor,
                Transparency = 0.2,
                CanCollide = false,
                CanTouch = false,
                CanQuery = false,
                CastShadow = false,
            })
        end
    end

    if detailTier ~= "far" and species.GlowEnabled then
        local glow = makeVerticalCylinder(folder, "Glow", capRadius * 0.7, math.max(2.4, capBaseHeight * 0.3), CFrame.new(position.X, position.Y + height + (capBaseHeight * 0.32), position.Z), {
            Material = Enum.Material.Neon,
            Color = species.GlowColor,
            Transparency = detailTier == "hero" and 0.16 or 0.26,
            CastShadow = false,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
        })
        if detailTier == "hero" and stats.HeroLightCount < optimization.HeroLightBudget then
            addPointLight(glow, "CapGlow", species.GlowColor, 1.8, math.max(18, capRadius * 2.3))
            stats.HeroLightCount += 1
        end
    end

    stats.MushroomCount += 1
    if detailTier == "hero" then
        stats.HeroMushroomCount += 1
    end
end

local function deriveRuinDescriptors(layout, rng)
    local descriptors = {}
    local kinds = {"arch", "halo", "colossus", "shards"}
    for index = 1, layout.optimization.RuinClusterCount do
        local center = randomPolarPosition(rng, 0.12, 0.34, layout.terrainKind == "forest" and -0.08 or -0.16)
        table.insert(descriptors, {
            Kind = kinds[((index - 1) % #kinds) + 1],
            Hero = index <= layout.optimization.HeroRuinCount,
            Position = terrainPosition(layout, center.x * layout.worldSize, center.z * layout.worldSize, 0),
            Rotation = rng:NextNumber(0, math.pi * 2),
            Scale = rng:NextNumber(0.82, 1.42),
            ShardCount = rng:NextInteger(3, layout.optimization.RuinShardBudget),
        })
    end
    return descriptors
end

local function buildArchRuin(parent, name, descriptor, palette, stats)
    local folder = createModel(parent, name)
    local scale = descriptor.Scale
    local sideOffset = Vector3.new(math.cos(descriptor.Rotation + math.pi * 0.5) * 18 * scale, 0, math.sin(descriptor.Rotation + math.pi * 0.5) * 18 * scale)
    local leftLean = CFrame.Angles(0, 0, math.rad(-4 * scale))
    local rightLean = CFrame.Angles(0, 0, math.rad(5 * scale))

    makePart(folder, "LeftPillar", Vector3.new(10, 40, 10) * scale, CFrame.new(descriptor.Position - sideOffset + Vector3.new(0, 20 * scale, 0)) * leftLean, {
        Material = Enum.Material.Metal,
        Color = palette.Secondary,
    })
    makePart(folder, "RightPillar", Vector3.new(9, 44, 11) * scale, CFrame.new(descriptor.Position + sideOffset + Vector3.new(0, 22 * scale, 0)) * rightLean, {
        Material = Enum.Material.Metal,
        Color = tintColor(palette.Secondary, -0.06, -0.04, -0.02),
    })
    makePart(folder, "TopBeamA", Vector3.new(18, 7, 9) * scale, CFrame.new(descriptor.Position + Vector3.new(-10 * scale, 44 * scale, 0)), {
        Material = Enum.Material.Metal,
        Color = palette.Base,
    })
    makePart(folder, "TopBeamB", Vector3.new(14, 6, 8) * scale, CFrame.new(descriptor.Position + Vector3.new(10 * scale, 46 * scale, 0)) * CFrame.Angles(0, 0, math.rad(12)), {
        Material = Enum.Material.Metal,
        Color = tintColor(palette.Base, -0.04, -0.02, -0.02),
    })

    if descriptor.Hero then
        local core = makeBall(folder, "Core", Vector3.new(7, 7, 7) * scale, CFrame.new(descriptor.Position + Vector3.new(0, 28 * scale, 0)), {
            Material = Enum.Material.Neon,
            Color = palette.Highlight,
            Transparency = 0.16,
            CastShadow = false,
        })
        if stats.HeroLightCount < 12 then
            addPointLight(core, "CoreGlow", palette.Highlight, 2.2, 26 * scale)
            stats.HeroLightCount += 1
        end
    end
end

local function buildHaloRuin(parent, name, descriptor, palette)
    local folder = createModel(parent, name)
    local radius = 24 * descriptor.Scale
    local segmentCount = 5
    for segmentIndex = 1, segmentCount do
        local angle = descriptor.Rotation + ((segmentIndex / segmentCount) * math.pi * 2)
        local position = descriptor.Position + Vector3.new(math.cos(angle) * radius, 14 * descriptor.Scale + math.sin(segmentIndex) * 3, math.sin(angle) * radius)
        makePart(folder, "RingSegment" .. segmentIndex, Vector3.new(16, 6, 8) * descriptor.Scale, CFrame.new(position) * CFrame.Angles(0, -angle, math.rad(18)), {
            Material = Enum.Material.Metal,
            Color = tintColor(palette.Base, -0.08, -0.04, -0.02),
        })
    end
    makeVerticalCylinder(folder, "Plinth", 10 * descriptor.Scale, 8 * descriptor.Scale, CFrame.new(descriptor.Position + Vector3.new(0, 4 * descriptor.Scale, 0)), {
        Material = Enum.Material.Metal,
        Color = palette.Secondary,
    })
end

local function buildColossusRuin(parent, name, descriptor, palette)
    local folder = createModel(parent, name)
    local forward = Vector3.new(math.cos(descriptor.Rotation), 0, math.sin(descriptor.Rotation))
    for index = 1, 4 do
        local segmentPosition = descriptor.Position + (forward * ((index - 2) * 14 * descriptor.Scale)) + Vector3.new(0, math.max(4, 12 - (index * 2)) * descriptor.Scale, 0)
        makePart(folder, "Frame" .. index, Vector3.new(14, 8, 10) * descriptor.Scale, CFrame.new(segmentPosition) * CFrame.Angles(math.rad(index * 11), -descriptor.Rotation, math.rad(index * 6)), {
            Material = Enum.Material.Metal,
            Color = index % 2 == 0 and palette.Base or palette.Secondary,
        })
    end
    makeBall(folder, "CoreSkull", Vector3.new(10, 10, 10) * descriptor.Scale, CFrame.new(descriptor.Position + (forward * 28 * descriptor.Scale) + Vector3.new(0, 12 * descriptor.Scale, 0)), {
        Material = Enum.Material.Metal,
        Color = tintColor(palette.Highlight, -0.18, -0.08, -0.12),
    })
end

local function buildShardRuin(parent, name, descriptor, palette, rng)
    local folder = createModel(parent, name)
    for shardIndex = 1, descriptor.ShardCount do
        local angle = rng:NextNumber(0, math.pi * 2)
        local radial = rng:NextNumber(10, 34) * descriptor.Scale
        local position = descriptor.Position + Vector3.new(math.cos(angle) * radial, rng:NextNumber(6, 20) * descriptor.Scale, math.sin(angle) * radial)
        makePart(folder, "Shard" .. shardIndex, Vector3.new(rng:NextNumber(4, 9), rng:NextNumber(14, 38), rng:NextNumber(4, 8)) * descriptor.Scale, CFrame.new(position) * CFrame.Angles(math.rad(rng:NextNumber(-30, 30)), -angle, math.rad(rng:NextNumber(-22, 22))), {
            Material = Enum.Material.Metal,
            Color = shardIndex % 2 == 0 and palette.Base or palette.Secondary,
        })
    end
end

local function buildRuins(parent, layout, palette, rng, stats)
    local ruins = createModel(parent, "AncientRuins")
    local descriptors = deriveRuinDescriptors(layout, rng)
    stats.RuinClusterCount = #descriptors

    for index, descriptor in ipairs(descriptors) do
        if descriptor.Kind == "arch" then
            buildArchRuin(ruins, string.format("RuinArch%02d", index), descriptor, palette, stats)
        elseif descriptor.Kind == "halo" then
            buildHaloRuin(ruins, string.format("RuinHalo%02d", index), descriptor, palette)
        elseif descriptor.Kind == "colossus" then
            buildColossusRuin(ruins, string.format("FallenColossus%02d", index), descriptor, palette)
        else
            buildShardRuin(ruins, string.format("RuinShards%02d", index), descriptor, palette, rng)
        end
    end
end

local function buildMushrooms(parent, layout, palette, rng, stats)
    local forest = createModel(parent, "MushroomForest")
    local clusters = deriveMushroomClusters(layout, rng)
    local speciesLibrary = deriveMushroomSpeciesLibrary(palette, rng)
    local mushroomIndex = 0

    for _, cluster in ipairs(clusters) do
        for _ = 1, cluster.Count do
            mushroomIndex += 1
            local angle = rng:NextNumber(0, math.pi * 2)
            local radial = math.sqrt(rng:NextNumber()) * cluster.Radius
            local x = cluster.CenterX + (math.cos(angle) * radial)
            local z = cluster.CenterZ + (math.sin(angle) * radial * 0.72)
            local basePosition = terrainPosition(layout, x, z, 0)
            local species = speciesLibrary[rng:NextInteger(1, #speciesLibrary)]
            local heightScale = cluster.DetailTier == "hero" and rng:NextNumber(1.1, 1.6) or (cluster.DetailTier == "ambient" and rng:NextNumber(0.85, 1.2) or rng:NextNumber(0.6, 0.92))
            local height = clamp((16 + rng:NextNumber(6, 26)) * heightScale, 14, cluster.DetailTier == "hero" and 76 or 54)
            local stemRadius = clamp(height * rng:NextNumber(0.07, 0.1), 1.8, 8.2)
            local capRadius = stemRadius * species.CapWidth
            addMushroom(forest, mushroomIndex, basePosition, height, stemRadius, capRadius, species, cluster.DetailTier, stats, layout.optimization, rng)
        end
    end
end

local function buildWaterFeatures(root, layout, palette)
    local waterFolder = createModel(root, "WaterFeatures")
    local terrainSegmentCount = 0

    if layout.hasLake then
        local lakeRadiusX = layout.worldSize * 0.11
        local lakeRadiusZ = layout.worldSize * 0.08
        Terrain:FillBlock(
            CFrame.new(layout.lakeCenter.X, layout.waterLevel - 4, layout.lakeCenter.Z),
            Vector3.new(lakeRadiusX * 2, 16, lakeRadiusZ * 2),
            Enum.Material.Water
        )
        local lakeGlow = makePart(waterFolder, "LakeGlow", Vector3.new(lakeRadiusX * 1.6, 2, lakeRadiusZ * 1.2), CFrame.new(layout.lakeCenter.X, layout.waterLevel + 1.2, layout.lakeCenter.Z), {
            Material = Enum.Material.Glass,
            Color = Color3.fromRGB(98, 168, 210),
            Transparency = 0.26,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
            CastShadow = false,
        })
        addPointLight(lakeGlow, "LakeGlowLight", palette.Highlight, 2.2, 96)
    end

    if layout.terrainKind == "mountains" and layout.hasLake then
        local westStream = {
            terrainPosition(layout, -(layout.worldSize * 0.12), 82, 2),
            terrainPosition(layout, -(layout.worldSize * 0.16), 154, 1.6),
            Vector3.new(-(layout.worldSize * 0.08), layout.waterLevel + 8, layout.lakeCenter.Z - (layout.worldSize * 0.09)),
            Vector3.new(-(layout.worldSize * 0.06), layout.waterLevel + 2, layout.lakeCenter.Z - (layout.worldSize * 0.03)),
        }
        local eastStream = {
            terrainPosition(layout, layout.worldSize * 0.12, 82, 2),
            terrainPosition(layout, layout.worldSize * 0.16, 154, 1.6),
            Vector3.new(layout.worldSize * 0.08, layout.waterLevel + 8, layout.lakeCenter.Z - (layout.worldSize * 0.09)),
            Vector3.new(layout.worldSize * 0.06, layout.waterLevel + 2, layout.lakeCenter.Z - (layout.worldSize * 0.03)),
        }

        terrainSegmentCount += fillTerrainRibbon(westStream, 18, 8)
        terrainSegmentCount += fillTerrainRibbon(eastStream, 18, 8)
        addWaterfallSheet(waterFolder, "WestFalls", westStream[3] + Vector3.new(0, 3, 0), westStream[4] + Vector3.new(0, 2, 0), 24, palette)
        addWaterfallSheet(waterFolder, "EastFalls", eastStream[3] + Vector3.new(0, 3, 0), eastStream[4] + Vector3.new(0, 2, 0), 24, palette)
    end

    Workspace:SetAttribute("PromptWorldWaterTerrainSegments", terrainSegmentCount)
    Workspace:SetAttribute("PromptWorldWaterFeature", layout.waterFeature)
end

local function placeSpawn(root, layout)
    local spawnFolder = createModel(root, "Spawn")
    local spawnPosition = terrainPosition(layout, layout.spawnCenter.X, layout.spawnCenter.Z, 4)

    Terrain:FillBlock(
        CFrame.new(layout.spawnCenter.X, layout.spawnHeight - 2, layout.spawnCenter.Z),
        Vector3.new(36, 6, 36),
        Enum.Material.Ground
    )

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "PromptSpawn"
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.Material = Enum.Material.Neon
    spawn.Color = Color3.fromRGB(126, 208, 255)
    spawn.Transparency = 0.18
    spawn.CFrame = CFrame.new(spawnPosition + Vector3.new(0, 2.8, 0))
    spawn.Parent = spawnFolder
    addPointLight(spawn, "SpawnLight", spawn.Color, 2.8, 28)
end

local function publishAttributes(title, worldSpec, layout, generationSeed, stats)
    Workspace:SetAttribute("PromptWorldTitle", title)
    Workspace:SetAttribute("PromptWorldTheme", worldSpec.theme)
    Workspace:SetAttribute("PromptWorldTerrain", worldSpec.terrain)
    Workspace:SetAttribute("PromptWorldScale", worldSpec.scale)
    Workspace:SetAttribute("PromptWorldRadius", layout.worldSize * 0.5)
    Workspace:SetAttribute("PromptWorldGenerationSeed", generationSeed)
    Workspace:SetAttribute("PromptWorldRenderStyle", "smooth")
    Workspace:SetAttribute("PromptWorldOptimizationFlow", layout.optimization.OptimizationFlow)
    Workspace:SetAttribute("PromptWorldOriginalityMode", layout.optimization.OriginalityMode)
    Workspace:SetAttribute("PromptWorldOriginalitySignature", layout.originalitySignature)
    Workspace:SetAttribute("PromptWorldMushroomCount", stats.MushroomCount)
    Workspace:SetAttribute("PromptWorldHeroMushroomCount", stats.HeroMushroomCount)
    Workspace:SetAttribute("PromptWorldRuinClusterCount", stats.RuinClusterCount)
    Workspace:SetAttribute("PromptWorldHeroLightCount", stats.HeroLightCount)
    Workspace:SetAttribute("PromptWorldCreatorStoreFoliage", worldSpec.creator_store_foliage == true)
end

local function buildWorld()
    clearLegacyWorld()

    local worldSpec = ModularWorldAssets.World and ModularWorldAssets.World.WorldSpec or {}
    local assetStyles = ModularWorldAssets.AssetStyles or {}
    local display = ModularWorldAssets.Display or {}
    local seed = resolveGenerationSeed()
    local rng = Random.new(seed)
    local palette = {
        Base = colorFromRGB(assetStyles.BaseplateColorRGB, Color3.fromRGB(120, 121, 128)),
        Primary = colorFromRGB(assetStyles.PrimaryAccentColorRGB, Color3.fromRGB(92, 104, 124)),
        Secondary = colorFromRGB(assetStyles.SecondaryAccentColorRGB, Color3.fromRGB(58, 82, 142)),
        Highlight = Color3.fromRGB(120, 222, 255),
    }

    applyLighting(assetStyles, worldSpec)

    local root = createModel(Workspace, ROOT_NAME)
    local layout = deriveLayout(worldSpec, seed)
    local stats = {
        MushroomCount = 0,
        HeroMushroomCount = 0,
        RuinClusterCount = 0,
        HeroLightCount = 0,
    }

    buildTerrain(root, layout, worldSpec)
    buildWaterFeatures(root, layout, palette)

    local moduleFamilies = worldSpec.module_families or {}
    if worldSpec.flora_style == "mushroom-forest" or table.find(moduleFamilies, "mushroom_grove") then
        buildMushrooms(root, layout, palette, rng, stats)
    end

    if table.find(moduleFamilies, "robot_ruin") or table.find(moduleFamilies, "fallen_colossus") or string.find(string.lower(worldSpec.theme or ""), "ancient", 1, true) then
        buildRuins(root, layout, palette, rng, stats)
    end

    placeSpawn(root, layout)
    publishAttributes(display.Title or "Prompt World", worldSpec, layout, seed, stats)
    return root
end

function PromptWorldService.generateInStudio()
    return buildWorld()
end

function PromptWorldService.start()
    return buildWorld()
end

return PromptWorldService
