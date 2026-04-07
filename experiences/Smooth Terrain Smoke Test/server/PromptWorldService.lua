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
    }) do
        Workspace:SetAttribute(attributeName, nil)
    end
end

local function applyLighting(assetStyles, worldSpec)
    Lighting.ClockTime = 15.3
    Lighting.Brightness = 2.4
    Lighting.Ambient = Color3.fromRGB(86, 96, 114)
    Lighting.OutdoorAmbient = Color3.fromRGB(132, 150, 176)
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
    atmosphere.Density = worldSpec.terrain == "mountains" and 0.3 or 0.26
    atmosphere.Offset = 0.04
    atmosphere.Glare = 0.09
    atmosphere.Haze = worldSpec.terrain == "mountains" and 1.35 or 1.55
    atmosphere.Parent = Lighting

    local bloom = Lighting:FindFirstChild("GeneratedPromptBloom")
    if bloom then
        bloom:Destroy()
    end
    bloom = Instance.new("BloomEffect")
    bloom.Name = "GeneratedPromptBloom"
    bloom.Intensity = 0.28
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

local function deriveLayout(worldSpec, seed)
    local scaleMap = {
        small = 896,
        medium = 1152,
        large = 1408,
    }
    local worldSize = scaleMap[worldSpec.scale or "large"] or 1152
    local terrainKind = "frontier"
    if worldSpec.terrain == "mountains" then
        terrainKind = "mountains"
    elseif worldSpec.terrain == "islands" then
        terrainKind = "islands"
    elseif string.find(string.lower(worldSpec.theme or ""), "desert", 1, true) then
        terrainKind = "canyon"
    end

    local waterLevel = 18
    if terrainKind == "mountains" then
        waterLevel = -40
    elseif terrainKind == "islands" then
        waterLevel = 28
    elseif terrainKind == "canyon" then
        waterLevel = -56
    end

    return {
        seed = seed,
        terrainKind = terrainKind,
        worldSize = worldSize,
        cellSize = 8,
        baseY = terrainKind == "mountains" and -208 or -160,
        topsoilDepth = 8,
        waterLevel = waterLevel,
        snowLine = terrainKind == "mountains" and 210 or 999,
        spawnCenter = Vector3.new(0, 0, worldSize * 0.34),
        spawnHeight = terrainKind == "mountains" and 78 or 56,
        spawnFlattenRadius = 92,
        mountainRangeCount = math.max(3, worldSpec.mountain_range_count or 3),
        valleyCount = math.max(2, worldSpec.valley_count or 2),
        lakeCenter = Vector3.new(0, 0, worldSize * 0.22),
        peakCenter = Vector3.new(0, 0, -(worldSize * 0.22)),
        hasLake = worldSpec.water_feature == "lake" or terrainKind == "mountains",
        waterFeature = worldSpec.water_feature or "",
    }
end

local function sampleMountainHeight(layout, x, z)
    local xNorm = x / (layout.worldSize * 0.5)
    local zNorm = z / (layout.worldSize * 0.5)
    local northWeight = 1 - inverseLerp(-1, 1, zNorm)

    local baseSlope = 18 + (northWeight * 42)
    local westRidge = gaussian1(xNorm, -0.58, 0.24) * (78 + (northWeight * 54))
    local centralRidge = gaussian1(xNorm, 0, 0.2) * (110 + (northWeight * 78))
    local eastRidge = gaussian1(xNorm, 0.58, 0.24) * (78 + (northWeight * 54))
    local westValley = gaussian1(xNorm, -0.22, 0.1) * (46 + (northWeight * 24))
    local eastValley = gaussian1(xNorm, 0.22, 0.1) * (46 + (northWeight * 24))
    local summitMass = gaussian2(xNorm, zNorm, 0, -0.44, 0.24, 0.18) * 154
    local peakCrown = gaussian2(xNorm, zNorm, 0, -0.28, 0.18, 0.14) * 84
    local lakeBasin = layout.hasLake and gaussian2(xNorm, zNorm, 0, 0.5, 0.24, 0.16) * 124 or 0

    local macroNoise = fractal2D(x, z, 280, 4, 2, 0.5, layout.seed + 31) * 18
    local ridgeNoise = ridge2D(x, z, 180, 3, 2, 0.5, layout.seed + 173) * 14

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

local function sampleHeight(layout, x, z)
    if layout.terrainKind == "mountains" then
        return sampleMountainHeight(layout, x, z)
    end
    if layout.terrainKind == "islands" then
        return sampleIslandHeight(layout, x, z)
    end
    if layout.terrainKind == "canyon" then
        return sampleCanyonHeight(layout, x, z)
    end
    return sampleFrontierHeight(layout, x, z)
end

local function sampleMoisture(layout, x, z)
    return clamp((fractal2D(x, z, 260, 3, 2, 0.5, layout.seed + 401) + 1) * 0.5, 0, 1)
end

local function estimateSlope(layout, x, z)
    local step = layout.cellSize
    local left = sampleHeight(layout, x - step, z)
    local right = sampleHeight(layout, x + step, z)
    local up = sampleHeight(layout, x, z - step)
    local down = sampleHeight(layout, x, z + step)
    return math.max(math.abs(left - right), math.abs(up - down)) / (step * 2)
end

local function resolveMaterials(layout, x, z, height, moisture, slope)
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

local function fillColumn(layout, column)
    local bodyTop = math.max(layout.baseY + layout.cellSize, column.Height - layout.topsoilDepth)
    local bodyHeight = bodyTop - layout.baseY
    local topHeight = math.max(layout.cellSize, column.Height - bodyTop)

    if bodyHeight > 0 then
        Terrain:FillBlock(
            CFrame.new(column.X, layout.baseY + (bodyHeight * 0.5), column.Z),
            Vector3.new(layout.cellSize, bodyHeight, layout.cellSize),
            column.BodyMaterial
        )
    end

    Terrain:FillBlock(
        CFrame.new(column.X, bodyTop + (topHeight * 0.5), column.Z),
        Vector3.new(layout.cellSize, topHeight, layout.cellSize),
        column.SurfaceMaterial
    )

    if column.Height < layout.waterLevel then
        local waterHeight = layout.waterLevel - column.Height
        Terrain:FillBlock(
            CFrame.new(column.X, column.Height + (waterHeight * 0.5), column.Z),
            Vector3.new(layout.cellSize, waterHeight, layout.cellSize),
            Enum.Material.Water
        )
    end
end

local function applySmoothingPass(layout, columns)
    local stride = 4
    for ix = 1, #columns, stride do
        for iz = 1, #columns[ix], stride do
            local column = columns[ix][iz]
            Terrain:FillBall(
                Vector3.new(column.X, column.Height + (layout.cellSize * 0.35), column.Z),
                layout.cellSize * 1.7,
                column.SurfaceMaterial
            )
        end

        if ix % 12 == 1 then
            task.wait()
        end
    end
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
    local cellCount = math.floor(layout.worldSize / layout.cellSize)
    local halfSize = layout.worldSize * 0.5
    local columns = {}
    local totalColumns = 0

    for ix = 1, cellCount do
        columns[ix] = {}
        local worldX = -halfSize + ((ix - 0.5) * layout.cellSize)
        for iz = 1, cellCount do
            local worldZ = -halfSize + ((iz - 0.5) * layout.cellSize)
            local height = sampleHeight(layout, worldX, worldZ)
            local moisture = sampleMoisture(layout, worldX, worldZ)
            local slope = estimateSlope(layout, worldX, worldZ)
            local bodyMaterial, surfaceMaterial = resolveMaterials(layout, worldX, worldZ, height, moisture, slope)
            local column = {
                X = worldX,
                Z = worldZ,
                Height = height,
                Moisture = moisture,
                Slope = slope,
                BodyMaterial = bodyMaterial,
                SurfaceMaterial = surfaceMaterial,
            }
            columns[ix][iz] = column
            fillColumn(layout, column)
            totalColumns += 1
        end

        if ix % 8 == 0 then
            task.wait()
        end
    end

    applySmoothingPass(layout, columns)

    if layout.hasLake then
        Terrain:FillBall(layout.lakeCenter + Vector3.new(0, layout.waterLevel - 10, 0), layout.worldSize * 0.08, Enum.Material.Water)
    end

    Workspace:SetAttribute("PromptWorldTerrainColumnCount", totalColumns)
    Workspace:SetAttribute("PromptWorldTerrainCellSize", layout.cellSize)
    return columns
end

local function addMushroom(parent, index, position, height, stemRadius, capRadius, palette, rng)
    local folder = createModel(parent, string.format("Mushroom%03d", index))
    makeVerticalCylinder(folder, "Stem", stemRadius, height, CFrame.new(position + Vector3.new(0, height * 0.5, 0)), {
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(216, 205, 188),
    })

    local capColors = {
        Color3.fromRGB(198, 77, 124),
        Color3.fromRGB(138, 101, 210),
        Color3.fromRGB(78, 156, 186),
        Color3.fromRGB(214, 128, 82),
    }
    local capColor = capColors[(index % #capColors) + 1]
    makeVerticalCylinder(folder, "Cap", capRadius, math.max(4, capRadius * 0.2), CFrame.new(position + Vector3.new(0, height + (capRadius * 0.14), 0)), {
        Material = Enum.Material.SmoothPlastic,
        Color = capColor,
    })
    local glow = makeVerticalCylinder(folder, "Glow", capRadius * 0.74, math.max(3, capRadius * 0.12), CFrame.new(position + Vector3.new(0, height + (capRadius * 0.3), 0)), {
        Material = Enum.Material.Neon,
        Color = palette.Highlight,
        Transparency = 0.2,
        CastShadow = false,
    })
    if index <= 8 then
        addPointLight(glow, "CapGlow", palette.Highlight, 1.9, math.max(18, capRadius * 2.4))
    end

    for spotIndex = 1, rng:NextInteger(4, 7) do
        local angle = (spotIndex / 6) * math.pi * 2 + rng:NextNumber(-0.22, 0.22)
        local radius = capRadius * rng:NextNumber(0.2, 0.65)
        local spotPosition = position + Vector3.new(math.cos(angle) * radius, height + (capRadius * 0.18), math.sin(angle) * radius)
        makeBall(folder, "Spot" .. spotIndex, Vector3.new(1.4, 1.4, 1.4), CFrame.new(spotPosition), {
            Material = Enum.Material.Neon,
            Color = palette.Highlight,
            Transparency = 0.1,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
            CastShadow = false,
        })
    end
end

local function buildRuinGate(parent, name, position, facing, scale, palette)
    local folder = createModel(parent, name)
    local sideOffset = Vector3.new(math.cos(facing + math.pi * 0.5) * 18 * scale, 0, math.sin(facing + math.pi * 0.5) * 18 * scale)
    makePart(folder, "LeftPillar", Vector3.new(10, 44, 10) * scale, CFrame.new(position - sideOffset + Vector3.new(0, 22 * scale, 0)), {
        Material = Enum.Material.Metal,
        Color = palette.Secondary,
    })
    makePart(folder, "RightPillar", Vector3.new(10, 44, 10) * scale, CFrame.new(position + sideOffset + Vector3.new(0, 22 * scale, 0)), {
        Material = Enum.Material.Metal,
        Color = palette.Secondary,
    })
    makePart(folder, "TopBeam", Vector3.new(44, 8, 10) * scale, CFrame.new(position + Vector3.new(0, 46 * scale, 0)), {
        Material = Enum.Material.Metal,
        Color = palette.Base,
    })
    local core = makeBall(folder, "GateCore", Vector3.new(8, 8, 8) * scale, CFrame.new(position + Vector3.new(0, 28 * scale, 0)), {
        Material = Enum.Material.Neon,
        Color = palette.Highlight,
        Transparency = 0.14,
        CastShadow = false,
    })
    addPointLight(core, "CoreGlow", palette.Highlight, 2.4, 26 * scale)
end

local function buildRuins(parent, layout, palette, rng)
    local ruins = createModel(parent, "AncientRuins")
    local anchors = {
        terrainPosition(layout, -(layout.worldSize * 0.18), -40, 0),
        terrainPosition(layout, layout.worldSize * 0.18, -68, 0),
        terrainPosition(layout, 0, layout.terrainKind == "mountains" and -190 or -60, 0),
    }

    for index, anchor in ipairs(anchors) do
        buildRuinGate(ruins, string.format("RuinGate%02d", index), anchor, math.rad((index - 1) * 120), rng:NextNumber(0.82, 1.18), palette)
    end
end

local function buildMushrooms(parent, layout, palette, rng)
    local forest = createModel(parent, "MushroomForest")
    local count = 54
    local centerZ = layout.terrainKind == "mountains" and (layout.peakCenter.Z + 110) or -40
    local radius = layout.worldSize * 0.16

    for index = 1, count do
        local angle = rng:NextNumber(0, math.pi * 2)
        local radial = math.sqrt(rng:NextNumber()) * radius
        local x = math.cos(angle) * radial
        local z = centerZ + (math.sin(angle) * radial * 0.7)
        local basePosition = terrainPosition(layout, x, z, 0)
        local height = clamp(18 + rng:NextNumber(6, 28), 16, 58)
        local stemRadius = clamp(height * 0.08, 2, 8)
        local capRadius = stemRadius * rng:NextNumber(2.8, 4.6)
        addMushroom(forest, index, basePosition, height, stemRadius, capRadius, palette, rng)
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

local function publishAttributes(title, worldSpec, layout, generationSeed)
    Workspace:SetAttribute("PromptWorldTitle", title)
    Workspace:SetAttribute("PromptWorldTheme", worldSpec.theme)
    Workspace:SetAttribute("PromptWorldTerrain", worldSpec.terrain)
    Workspace:SetAttribute("PromptWorldScale", worldSpec.scale)
    Workspace:SetAttribute("PromptWorldRadius", layout.worldSize * 0.5)
    Workspace:SetAttribute("PromptWorldGenerationSeed", generationSeed)
    Workspace:SetAttribute("PromptWorldRenderStyle", "smooth")
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

    buildTerrain(root, layout, worldSpec)
    buildWaterFeatures(root, layout, palette)

    local moduleFamilies = worldSpec.module_families or {}
    if worldSpec.flora_style == "mushroom-forest" or table.find(moduleFamilies, "mushroom_grove") then
        buildMushrooms(root, layout, palette, rng)
    end

    if table.find(moduleFamilies, "robot_ruin") or table.find(moduleFamilies, "fallen_colossus") or string.find(string.lower(worldSpec.theme or ""), "ancient", 1, true) then
        buildRuins(root, layout, palette, rng)
    end

    placeSpawn(root, layout)
    publishAttributes(display.Title or "Prompt World", worldSpec, layout, seed)
    return root
end

function PromptWorldService.generateInStudio()
    return buildWorld()
end

function PromptWorldService.start()
    return buildWorld()
end

return PromptWorldService
