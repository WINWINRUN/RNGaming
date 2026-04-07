local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldPromptSpec = require(ReplicatedStorage:WaitForChild("WorldPromptSpec"))
local ModularWorldAssets = require(ReplicatedStorage:WaitForChild("ModularWorldAssets"))

local PromptWorldService = {}

local ROOT_NAME = "GeneratedPromptWorld"
local STEM_ROTATION = CFrame.Angles(0, 0, math.rad(90))
local MOUNTAIN_SECTION_NAMES = {
    "SummitCrown",
    "CentralSpine",
    "WestRange",
    "WestValley",
    "EastRange",
    "EastValley",
    "LakeBasin",
}

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

local function gaussian1(value, center, width)
    local delta = (value - center) / width
    return math.exp(-(delta * delta))
end

local function gaussian2(x, z, centerX, centerZ, widthX, widthZ)
    local deltaX = (x - centerX) / widthX
    local deltaZ = (z - centerZ) / widthZ
    return math.exp(-((deltaX * deltaX) + (deltaZ * deltaZ)))
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

local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if folder then
        folder:Destroy()
    end
    folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
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

    for _, name in ipairs({
        "GeneratedEnvironment",
        "GeneratedSpawn",
        "GeneratedTerrainInfo",
        "GeneratedPromptWorldLighting",
        "GeneratedPromptWorldEffects",
    }) do
        local child = Workspace:FindFirstChild(name)
        if child then
            child:Destroy()
        end
    end

    Workspace.Terrain:Clear()
    for _, attributeName in ipairs({
        "PromptWorldWaterTerrainSegments",
        "PromptWorldWaterfallCount",
        "PromptWorldSmoothAccentCount",
        "PromptWorldRockAccentCount",
        "PromptWorldBumpAccentCount",
    }) do
        Workspace:SetAttribute(attributeName, 0)
    end
end

local function applyLighting(assetStyles, worldSpec)
    local mountainWorld = worldSpec.terrain == "mountains"

    Lighting.ClockTime = mountainWorld and 17.6 or 18.75
    Lighting.Brightness = 3.2
    Lighting.Ambient = Color3.fromRGB(72, 78, 102)
    Lighting.OutdoorAmbient = Color3.fromRGB(132, 146, 182)
    Lighting.EnvironmentDiffuseScale = 0.56
    Lighting.EnvironmentSpecularScale = 0.48
    Lighting.ExposureCompensation = 0.24
    Lighting.ShadowSoftness = 0.35
    Lighting.GlobalShadows = true

    local atmosphere = Lighting:FindFirstChild("GeneratedPromptAtmosphere")
    if atmosphere then
        atmosphere:Destroy()
    end
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "GeneratedPromptAtmosphere"
    atmosphere.Color = colorFromRGB(assetStyles.PrimaryAccentColorRGB, Color3.fromRGB(92, 104, 124))
    atmosphere.Decay = colorFromRGB(assetStyles.SecondaryAccentColorRGB, Color3.fromRGB(58, 82, 142))
    atmosphere.Density = mountainWorld and 0.28 or (worldSpec.mood == "eerie" and 0.34 or 0.22)
    atmosphere.Offset = 0.04
    atmosphere.Glare = mountainWorld and 0.12 or 0.1
    atmosphere.Haze = mountainWorld and 1.1 or 1.35
    atmosphere.Parent = Lighting

    local colorCorrection = Lighting:FindFirstChild("GeneratedPromptColorCorrection")
    if colorCorrection then
        colorCorrection:Destroy()
    end
    colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "GeneratedPromptColorCorrection"
    colorCorrection.Brightness = 0.08
    colorCorrection.Contrast = 0.16
    colorCorrection.Saturation = worldSpec.mood == "eerie" and -0.05 or 0
    colorCorrection.TintColor = colorFromRGB(assetStyles.PrimaryAccentColorRGB, Color3.fromRGB(92, 104, 124))
    colorCorrection.Parent = Lighting

    local bloom = Lighting:FindFirstChild("GeneratedPromptBloom")
    if bloom then
        bloom:Destroy()
    end
    bloom = Instance.new("BloomEffect")
    bloom.Name = "GeneratedPromptBloom"
    bloom.Intensity = mountainWorld and 0.52 or 0.45
    bloom.Size = 28
    bloom.Threshold = 1.2
    bloom.Parent = Lighting
end

local function addGround(root, worldRadius, palette)
    local floorFolder = ensureFolder(root, "Ground")
    makeVerticalCylinder(floorFolder, "WorldBase", worldRadius, 18, CFrame.new(0, -9, 0), {
        Material = Enum.Material.Slate,
        Color = palette.Base,
    })

    makeVerticalCylinder(floorFolder, "ForestPlate", worldRadius * 0.66, 12, CFrame.new(0, -2, 0), {
        Material = Enum.Material.Ground,
        Color = palette.Primary,
    })

    makeVerticalCylinder(floorFolder, "InnerClearing", worldRadius * 0.25, 4, CFrame.new(0, 0.3, 0), {
        Material = Enum.Material.SmoothPlastic,
        Color = palette.Highlight,
        Transparency = 0.12,
    })

    makeVerticalCylinder(floorFolder, "RuinRing", worldRadius * 0.92, 2, CFrame.new(0, 0.45, 0), {
        Material = Enum.Material.Metal,
        Color = palette.Secondary,
        Transparency = 0.2,
    })

    return floorFolder
end

local function addPathSegment(parent, name, fromPosition, toPosition, thickness, color)
    local delta = toPosition - fromPosition
    local distance = delta.Magnitude
    if distance <= 0.5 then
        return
    end

    local midpoint = fromPosition:Lerp(toPosition, 0.5)
    local cframe = CFrame.lookAt(midpoint, toPosition)
    makePart(parent, name, Vector3.new(thickness, 0.8, distance), cframe, {
        Material = Enum.Material.Slate,
        Color = color,
    })
end

local function addSampledPath(parent, namePrefix, nodes, thickness, color)
    for index = 1, #nodes - 1 do
        addPathSegment(parent, string.format("%s%02d", namePrefix, index), nodes[index], nodes[index + 1], thickness, color)
    end
end

local function addSteppedPath(parent, namePrefix, nodes, thickness, color)
    local partIndex = 1
    for index = 1, #nodes - 1 do
        local fromPosition = nodes[index]
        local toPosition = nodes[index + 1]
        local delta = toPosition - fromPosition
        local horizontalDelta = Vector3.new(delta.X, 0, delta.Z)
        local horizontalDistance = horizontalDelta.Magnitude
        local stepCount = math.max(1, math.ceil(math.max(horizontalDistance / 26, math.abs(delta.Y) / 4)))

        for stepIndex = 0, stepCount - 1 do
            local startAlpha = stepIndex / stepCount
            local endAlpha = (stepIndex + 1) / stepCount
            local stepStart = fromPosition:Lerp(toPosition, startAlpha)
            local stepEnd = fromPosition:Lerp(toPosition, endAlpha)
            local stepHorizontal = Vector3.new(stepEnd.X - stepStart.X, 0, stepEnd.Z - stepStart.Z)
            local stepDistance = math.max(6, stepHorizontal.Magnitude + 1.5)
            local stepMidpoint = Vector3.new(
                (stepStart.X + stepEnd.X) * 0.5,
                stepStart.Y + ((stepEnd.Y - stepStart.Y) * 0.5),
                (stepStart.Z + stepEnd.Z) * 0.5
            )
            local lookTarget = stepMidpoint + (stepHorizontal.Magnitude > 0.5 and stepHorizontal.Unit or Vector3.new(0, 0, -1))
            local cframe = CFrame.lookAt(Vector3.new(stepMidpoint.X, stepMidpoint.Y, stepMidpoint.Z), Vector3.new(lookTarget.X, stepMidpoint.Y, lookTarget.Z))

            makePart(parent, string.format("%s%02d", namePrefix, partIndex), Vector3.new(thickness, 1.2, stepDistance), cframe, {
                Material = Enum.Material.Slate,
                Color = color,
            })
            partIndex += 1
        end
    end
end

local function addBridge(parent, name, position, width, length, color)
    makePart(parent, name .. "Deck", Vector3.new(width, 1.2, length), CFrame.new(position), {
        Material = Enum.Material.Metal,
        Color = color,
    })
    makePart(parent, name .. "RailLeft", Vector3.new(1, 3, length), CFrame.new(position + Vector3.new(-(width * 0.5), 2, 0)), {
        Material = Enum.Material.Metal,
        Color = color,
    })
    makePart(parent, name .. "RailRight", Vector3.new(1, 3, length), CFrame.new(position + Vector3.new(width * 0.5, 2, 0)), {
        Material = Enum.Material.Metal,
        Color = color,
    })
end

local function addWaterRibbonSegment(parent, name, fromPosition, toPosition, width, thickness, color)
    local delta = toPosition - fromPosition
    local distance = delta.Magnitude
    if distance <= 0.5 then
        return nil
    end

    local midpoint = fromPosition:Lerp(toPosition, 0.5)
    local cframe = CFrame.lookAt(midpoint, toPosition)
    local segment = makePart(parent, name, Vector3.new(width, thickness, distance), cframe, {
        Material = Enum.Material.Glass,
        Color = color,
        Transparency = 0.18,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
    })
    makePart(parent, name .. "Foam", Vector3.new(math.max(2, width * 0.42), math.max(0.35, thickness * 0.28), distance), cframe * CFrame.new(0, thickness * 0.18, 0), {
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(182, 236, 255),
        Transparency = 0.42,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    return segment
end

local function addWaterRibbon(parent, namePrefix, nodes, width, palette)
    for index = 1, #nodes - 1 do
        local segment = addWaterRibbonSegment(parent, string.format("%s%02d", namePrefix, index), nodes[index], nodes[index + 1], width, 2.6, Color3.fromRGB(94, 168, 216))
        if segment and index % 2 == 1 then
            addPointLight(segment, "WaterGlow", palette.Highlight, 1.7, math.max(28, width * 2.5))
        end
    end
end

local function fillTerrainSegment(fromPosition, toPosition, width, thickness, material)
    local delta = toPosition - fromPosition
    local distance = delta.Magnitude
    if distance <= 0.5 then
        return 0
    end

    local midpoint = fromPosition:Lerp(toPosition, 0.5)
    local direction = delta.Unit
    local worldUp = Vector3.new(0, 1, 0)
    local upVector = math.abs(direction:Dot(worldUp)) > 0.94 and Vector3.new(0, 0, 1) or worldUp
    Workspace.Terrain:FillBlock(CFrame.lookAt(midpoint, toPosition, upVector), Vector3.new(width, thickness, distance), material)
    return 1
end

local function fillTerrainRibbon(nodes, width, thickness, material)
    local segmentCount = 0
    for index = 1, #nodes - 1 do
        segmentCount += fillTerrainSegment(nodes[index], nodes[index + 1], width, thickness, material)
    end
    return segmentCount
end

local function addWaterfallMist(parent, name, position, scale, palette)
    local mist = makeBall(parent, name, Vector3.new(scale, scale * 0.7, scale), CFrame.new(position), {
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(174, 230, 255),
        Transparency = 0.5,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    addPointLight(mist, "MistGlow", palette.Highlight, 1.8, math.max(18, scale * 1.8))
    return mist
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

    local shell = makePart(sheet, "Shell", Vector3.new(width, height, 3.8), facing, {
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(104, 176, 220),
        Transparency = 0.12,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    local core = makePart(sheet, "Core", Vector3.new(width * 0.54, height, 1.4), facing * CFrame.new(0, 0, -0.8), {
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(172, 230, 255),
        Transparency = 0.24,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    addPointLight(core, "WaterfallGlow", palette.Highlight, 2.3, math.max(24, width * 1.8))

    makePart(sheet, "TopLip", Vector3.new(width * 0.78, 2.2, 5.6), CFrame.new(topPosition + Vector3.new(0, 1.4, 0)), {
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(120, 188, 228),
        Transparency = 0.16,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    makePart(sheet, "BottomFoam", Vector3.new(width * 0.92, 2.6, 8), CFrame.new(bottomPosition + Vector3.new(0, 1.3, 0)), {
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(204, 244, 255),
        Transparency = 0.28,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    addWaterfallMist(sheet, "BottomMist", bottomPosition + Vector3.new(0, 4.5, 0), width * 0.8, palette)

    return shell
end

local function addVisibleSmoothMound(parent, name, position, radius, color)
    local mound = createModel(parent, name)
    makeBall(mound, "Base", Vector3.new(radius * 2.2, radius * 1.2, radius * 2.2), CFrame.new(position + Vector3.new(0, radius * 0.34, 0)), {
        Material = Enum.Material.Ground,
        Color = color,
    })
    makeBall(mound, "ShoulderA", Vector3.new(radius * 1.2, radius * 0.7, radius * 1.2), CFrame.new(position + Vector3.new(radius * 0.32, radius * 0.44, -(radius * 0.18))), {
        Material = Enum.Material.Ground,
        Color = color,
    })
    makeBall(mound, "ShoulderB", Vector3.new(radius, radius * 0.58, radius), CFrame.new(position + Vector3.new(-(radius * 0.26), radius * 0.4, radius * 0.2)), {
        Material = Enum.Material.Ground,
        Color = color,
    })
end

local function addVisibleBumpCluster(parent, name, position, clusterSize, palette, rng)
    local cluster = createModel(parent, name)
    local bumpColor = Color3.fromRGB(124, 130, 138)

    for blobIndex = 1, rng:NextInteger(4, 6) do
        local angle = ((blobIndex - 1) / 5) * math.pi * 2 + rng:NextNumber(-0.35, 0.35)
        local radiusOffset = rng:NextNumber(clusterSize * 0.14, clusterSize * 0.6)
        local offset = Vector3.new(math.cos(angle) * radiusOffset, 0, math.sin(angle) * radiusOffset)
        local blobRadius = clusterSize * rng:NextNumber(0.38, 0.72)
        makeBall(cluster, "Bump" .. blobIndex, Vector3.new(blobRadius * 1.9, blobRadius * 1.1, blobRadius * 1.9), CFrame.new(position + offset + Vector3.new(0, blobRadius * 0.26, 0)), {
            Material = Enum.Material.Rock,
            Color = bumpColor,
        })
    end

    makeBall(cluster, "Core", Vector3.new(clusterSize * 0.9, clusterSize * 0.42, clusterSize * 0.9), CFrame.new(position + Vector3.new(0, clusterSize * 0.2, 0)), {
        Material = Enum.Material.Slate,
        Color = palette.Base,
    })
end

local function stabilizeDownhillNodes(nodes, minimumDrop)
    local adjusted = {}
    local drop = minimumDrop or 2

    for index, node in ipairs(nodes) do
        if index == 1 then
            adjusted[index] = node
        else
            local previous = adjusted[index - 1]
            adjusted[index] = Vector3.new(node.X, math.min(node.Y, previous.Y - drop), node.Z)
        end
    end

    return adjusted
end

local function addMushroom(parent, index, position, height, stemRadius, capRadius, palette, rng)
    local stemColor = Color3.fromRGB(214, 203, 183)
    local capColors = {
        Color3.fromRGB(198, 77, 124),
        Color3.fromRGB(138, 101, 210),
        Color3.fromRGB(78, 156, 186),
        Color3.fromRGB(214, 128, 82),
    }
    local capColor = capColors[(index % #capColors) + 1]
    local folder = Instance.new("Folder")
    folder.Name = string.format("Mushroom%03d", index)
    folder.Parent = parent

    makeVerticalCylinder(folder, "Stem", stemRadius, height, CFrame.new(position + Vector3.new(0, (height * 0.5), 0)), {
        Material = Enum.Material.SmoothPlastic,
        Color = stemColor,
    })

    makeVerticalCylinder(folder, "StemFlare", stemRadius * 1.2, math.max(6, height * 0.1), CFrame.new(position + Vector3.new(0, 3, 0)), {
        Material = Enum.Material.SmoothPlastic,
        Color = stemColor,
    })

    for layer = 1, 3 do
        local layerRadius = capRadius * (1 - ((layer - 1) * 0.18))
        local layerHeight = clamp(capRadius * 0.16, 3, 9)
        local yOffset = height + ((layer - 1) * (layerHeight * 0.45))
        local capLayer = makeVerticalCylinder(folder, "CapLayer" .. layer, layerRadius, layerHeight, CFrame.new(position + Vector3.new(0, yOffset, 0)), {
            Material = layer == 3 and Enum.Material.Neon or Enum.Material.SmoothPlastic,
            Color = layer == 3 and palette.Highlight or capColor,
            Transparency = layer == 3 and 0.18 or 0,
        })
        if layer == 3 and index <= 12 then
            addPointLight(capLayer, "CapGlow", palette.Highlight, 2.2, math.max(22, capRadius * 2.6))
        end
    end

    local spotCount = rng:NextInteger(5, 10)
    for spotIndex = 1, spotCount do
        local angle = (spotIndex / spotCount) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
        local radius = capRadius * rng:NextNumber(0.2, 0.7)
        local spotPosition = position + Vector3.new(math.cos(angle) * radius, height + (capRadius * 0.16), math.sin(angle) * radius)
        makeBall(folder, "Spore" .. spotIndex, Vector3.new(1.2, 1.2, 1.2) * rng:NextNumber(0.9, 1.5), CFrame.new(spotPosition), {
            Material = Enum.Material.Neon,
            Color = palette.Highlight,
            Transparency = 0.08,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
        })
    end
end

local function buildMushroomForest(root, worldSpec, palette, rng, worldRadius)
    local forestFolder = ensureFolder(root, "MushroomForest")
    local forestRadius = worldRadius * 0.58
    local mushroomCount = clamp(math.floor((worldSpec.module_count or 36) * 1.9), 60, 150)

    for index = 1, mushroomCount do
        local angle = rng:NextNumber(0, math.pi * 2)
        local radialBias = math.sqrt(rng:NextNumber()) * forestRadius
        local position = Vector3.new(math.cos(angle) * radialBias, 0, math.sin(angle) * radialBias)
        local noise = math.noise(position.X * 0.02, position.Z * 0.02, 0.15)
        local height = clamp(28 + (noise * 18) + rng:NextNumber(0, 34), 22, 90)
        if index <= 10 then
            height += 26
        end
        local stemRadius = clamp(height * 0.08, 3, 11)
        local capRadius = stemRadius * rng:NextNumber(2.6, 4.8)
        addMushroom(forestFolder, index, position, height, stemRadius, capRadius, palette, rng)
    end

    return forestRadius
end

local function addRobotSegment(parent, name, size, cframe, palette, transparency)
    return makePart(parent, name, size, cframe, {
        Material = Enum.Material.Metal,
        Color = palette.Secondary,
        Transparency = transparency or 0,
    })
end

local function addEnergyCore(parent, name, position, radius, palette)
    local core = makeBall(parent, name, Vector3.new(radius, radius, radius), CFrame.new(position), {
        Material = Enum.Material.Neon,
        Color = palette.Highlight,
        Transparency = 0.08,
    })
    addPointLight(core, "EnergyGlow", palette.Highlight, 3.6, radius * 2.8)
end

local function buildFallenColossus(parent, position, facing, scale, palette, rng)
    local folder = Instance.new("Folder")
    folder.Name = "FallenColossus"
    folder.Parent = parent

    local torso = addRobotSegment(folder, "Torso", Vector3.new(22, 34, 16) * scale, CFrame.new(position + Vector3.new(0, 16 * scale, 0)) * CFrame.Angles(0, facing, math.rad(rng:NextNumber(-14, 14))), palette)
    local headOffset = Vector3.new(math.cos(facing) * 12 * scale, 26 * scale, math.sin(facing) * 12 * scale)
    addRobotSegment(folder, "Head", Vector3.new(12, 12, 12) * scale, CFrame.new(position + headOffset) * CFrame.Angles(0, facing, 0), palette, 0.04)
    addEnergyCore(folder, "EyeCore", position + headOffset + Vector3.new(0, 1.5 * scale, 0), 5 * scale, palette)

    for limbIndex = 1, 4 do
        local side = limbIndex <= 2 and -1 or 1
        local along = limbIndex % 2 == 0 and -1 or 1
        local limbPosition = position + Vector3.new(side * 22 * scale, 8 * scale, along * 18 * scale)
        addRobotSegment(folder, "Limb" .. limbIndex, Vector3.new(28, 7, 8) * scale, CFrame.new(limbPosition) * CFrame.Angles(math.rad(rng:NextNumber(-40, 40)), facing + math.rad(rng:NextNumber(-40, 40)), 0), palette)
    end

    return torso
end

local function buildRuinGate(parent, position, facing, scale, palette)
    local folder = Instance.new("Folder")
    folder.Name = "AncientGate"
    folder.Parent = parent

    local sideOffset = Vector3.new(math.cos(facing + math.pi * 0.5) * 18 * scale, 0, math.sin(facing + math.pi * 0.5) * 18 * scale)
    addRobotSegment(folder, "LeftPillar", Vector3.new(10, 44, 10) * scale, CFrame.new(position - sideOffset + Vector3.new(0, 22 * scale, 0)), palette)
    addRobotSegment(folder, "RightPillar", Vector3.new(10, 44, 10) * scale, CFrame.new(position + sideOffset + Vector3.new(0, 22 * scale, 0)), palette)
    addRobotSegment(folder, "TopBeam", Vector3.new(44, 8, 10) * scale, CFrame.new(position + Vector3.new(0, 46 * scale, 0)), palette)
    addEnergyCore(folder, "GateCore", position + Vector3.new(0, 28 * scale, 0), 8 * scale, palette)

    return folder
end

local function buildRibRuin(parent, position, facing, scale, palette, rng)
    local folder = Instance.new("Folder")
    folder.Name = "RibRuin"
    folder.Parent = parent

    for ribIndex = 1, 6 do
        local angle = facing + math.rad(-50 + (ribIndex * 18))
        local ribPosition = position + Vector3.new(math.cos(angle) * 16 * scale, 8 * scale, math.sin(angle) * 16 * scale)
        addRobotSegment(folder, "Rib" .. ribIndex, Vector3.new(4, 28, 8) * scale, CFrame.new(ribPosition) * CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), angle, math.rad(26)), palette)
    end

    addRobotSegment(folder, "Spine", Vector3.new(30, 6, 8) * scale, CFrame.new(position + Vector3.new(0, 5 * scale, 0)) * CFrame.Angles(0, facing, math.rad(rng:NextNumber(-10, 10))), palette)
    return folder
end

local function buildRuinRing(root, worldSpec, palette, rng, worldRadius)
    local ruinFolder = ensureFolder(root, "AncientRobotRuins")
    local ruinRadius = worldRadius * 0.83
    local clusterCount = clamp(math.floor((worldSpec.landmark_count or 4) * 2), 6, 10)

    for clusterIndex = 1, clusterCount do
        local angle = ((clusterIndex - 1) / clusterCount) * math.pi * 2
        local position = Vector3.new(math.cos(angle) * ruinRadius, 0, math.sin(angle) * ruinRadius)
        local scale = rng:NextNumber(0.8, 1.35)
        local kind = clusterIndex % 3
        if kind == 1 then
            buildFallenColossus(ruinFolder, position, angle + math.pi, scale, palette, rng)
        elseif kind == 2 then
            buildRuinGate(ruinFolder, position, angle + math.pi, scale, palette)
        else
            buildRibRuin(ruinFolder, position, angle + math.pi, scale, palette, rng)
        end
    end

    return ruinRadius
end

local function buildAncientCore(root, palette)
    local coreFolder = ensureFolder(root, "AncientCore")
    makeVerticalCylinder(coreFolder, "CorePlaza", 42, 6, CFrame.new(0, 1.2, 0), {
        Material = Enum.Material.Slate,
        Color = palette.Secondary,
    })
    makeVerticalCylinder(coreFolder, "CoreDais", 22, 10, CFrame.new(0, 4.2, 0), {
        Material = Enum.Material.Metal,
        Color = palette.Base,
    })
    addEnergyCore(coreFolder, "MachineCore", Vector3.new(0, 22, 0), 18, palette)

    for armIndex = 1, 4 do
        local angle = (armIndex - 1) * (math.pi * 0.5)
        local armPosition = Vector3.new(math.cos(angle) * 26, 12, math.sin(angle) * 26)
        addRobotSegment(coreFolder, "CoreArm" .. armIndex, Vector3.new(24, 5, 6), CFrame.new(armPosition) * CFrame.Angles(math.rad(20), angle, math.rad(armIndex % 2 == 0 and 18 or -18)), palette)
    end
end

local function buildPaths(root, palette, worldRadius)
    local pathFolder = ensureFolder(root, "Paths")
    local center = Vector3.new(0, 1.1, 0)
    local southGate = Vector3.new(0, 1.1, worldRadius * 0.72)
    local northGate = Vector3.new(0, 1.1, -worldRadius * 0.72)
    local eastGate = Vector3.new(worldRadius * 0.72, 1.1, 0)
    local westGate = Vector3.new(-worldRadius * 0.72, 1.1, 0)

    addPathSegment(pathFolder, "SouthSpine", southGate, center, 12, palette.Highlight)
    addPathSegment(pathFolder, "NorthSpine", northGate, center, 10, palette.Primary)
    addPathSegment(pathFolder, "EastSpine", eastGate, center, 10, palette.Primary)
    addPathSegment(pathFolder, "WestSpine", westGate, center, 10, palette.Primary)
    addBridge(pathFolder, "AncientBridge", Vector3.new(0, 3.2, worldRadius * 0.18), 18, 42, palette.Secondary)

    return southGate
end

local function isMountainWorld(worldSpec)
    if worldSpec.terrain == "mountains" then
        return true
    end
    return type(worldSpec.world_structure) == "string" and string.find(worldSpec.world_structure, "mountain", 1, true) ~= nil
end

local function buildMountainLayout(worldSpec, seed)
    local moduleCount = math.max(worldSpec.module_count or 96, 96)
    local cellSize = math.max(10, math.floor(((worldSpec.grid_size or 24) + 16) * 0.25))
    local widthCells = clamp(math.floor(moduleCount * 1.52), 144, 192)
    local depthCells = clamp(math.floor(moduleCount * 2.04), 192, 256)
    local worldWidth = widthCells * cellSize
    local worldDepth = depthCells * cellSize
    local summitCenter = Vector3.new(0, 0, -worldDepth * 0.3)
    local peakCenter = summitCenter + Vector3.new(0, 0, -(cellSize * 0.85))

    return {
        seed = seed,
        cellSize = cellSize,
        widthCells = widthCells,
        depthCells = depthCells,
        worldWidth = worldWidth,
        worldDepth = worldDepth,
        terrainFloor = -300,
        maxPeakHeight = 900,
        waterLevel = -86,
        mountainRangeCount = math.max(3, worldSpec.mountain_range_count or 3),
        valleyCount = math.max(2, worldSpec.valley_count or 2),
        waterFeature = worldSpec.water_feature or "",
        sectionMode = worldSpec.section_mode or "contiguous-sections",
        summitCenter = summitCenter,
        peakCenter = peakCenter,
        peakRadius = worldWidth * 0.058,
        summitRadius = worldWidth * 0.09,
        lakeCenter = Vector3.new(0, 0, worldDepth * 0.36),
        lakeRadiusX = worldWidth * 0.19,
        lakeRadiusZ = worldDepth * 0.125,
        sectionNames = MOUNTAIN_SECTION_NAMES,
    }
end

local function sampleMountainHeight(layout, x, z)
    local xNorm = x / (layout.worldWidth * 0.5)
    local zNorm = z / (layout.worldDepth * 0.5)
    local northWeight = 1 - inverseLerp(-1, 1, zNorm)
    local peakZNorm = layout.peakCenter.Z / (layout.worldDepth * 0.5)

    local baseSlope = -150 + (northWeight * 198)
    local westRidge = gaussian1(xNorm, -0.64, 0.17) * (138 + (northWeight * 156))
    local centralRidge = gaussian1(xNorm, 0, 0.18) * (210 + (northWeight * 248))
    local eastRidge = gaussian1(xNorm, 0.64, 0.17) * (138 + (northWeight * 156))
    local westValley = gaussian1(xNorm, -0.31, 0.095) * (92 + (northWeight * 72))
    local eastValley = gaussian1(xNorm, 0.31, 0.095) * (92 + (northWeight * 72))
    local summitDome = gaussian2(xNorm, zNorm, 0, -0.6, 0.23, 0.15) * 286
    local summitShoulder = gaussian2(xNorm, zNorm, 0, -0.58, 0.29, 0.2) * 560
    local summitShelf = gaussian2(xNorm, zNorm, 0, -0.4, 0.2, 0.1) * 42
    local peakCrown = gaussian2(xNorm, zNorm, 0, peakZNorm, 0.28, 0.22) * 250
    local peakBench = gaussian2(xNorm, zNorm, 0, peakZNorm + 0.05, 0.36, 0.28) * 120
    local lakeBasin = gaussian2(xNorm, zNorm, 0, 0.72, 0.28, 0.15) * 214
    local westValleyShelf = gaussian2(xNorm, zNorm, -0.28, 0.12, 0.2, 0.18) * 56
    local eastValleyShelf = gaussian2(xNorm, zNorm, 0.28, 0.12, 0.2, 0.18) * 56
    local lowerShelf = gaussian2(xNorm, zNorm, 0, 0.1, 0.44, 0.26) * 34

    local centralMeander = math.noise(z * 0.0017, layout.seed * 0.00000037) * 0.03
    local splitAlpha = inverseLerp(-0.08, 0.62, zNorm)
    local westStreamCenter = lerp(-0.04, -0.24, splitAlpha) + (math.noise(z * 0.0015, layout.seed * 0.00000081) * 0.02)
    local eastStreamCenter = lerp(0.04, 0.24, splitAlpha) + (math.noise(z * 0.0015, layout.seed * 0.00000107) * 0.02)
    local summitRunoff = gaussian1(xNorm, centralMeander, 0.05) * gaussian1(zNorm, -0.2, 0.34) * 34
    local westStreamCut = gaussian1(xNorm, westStreamCenter, 0.055) * gaussian1(zNorm, 0.24, 0.42) * 46
    local eastStreamCut = gaussian1(xNorm, eastStreamCenter, 0.055) * gaussian1(zNorm, 0.24, 0.42) * 46
    local splitBasin = gaussian2(xNorm, zNorm, 0, 0.02, 0.12, 0.1) * 24
    local lakeInletCut = gaussian1(xNorm, 0, 0.18) * gaussian1(zNorm, 0.58, 0.18) * 20

    local macroNoise = math.noise(x * 0.0039, z * 0.0039, layout.seed * 0.0000013) * 24
    local microNoise = math.noise(x * 0.0098, z * 0.0098, layout.seed * 0.0000021) * 11

    local height = baseSlope
        + westRidge
        + centralRidge
        + eastRidge
        + summitDome
        + summitShoulder
        + summitShelf
        + peakCrown
        + peakBench
        + lowerShelf
        - westValley
        - eastValley
        - westValleyShelf
        - eastValleyShelf
        - summitRunoff
        - westStreamCut
        - eastStreamCut
        - splitBasin
        - lakeInletCut
        - lakeBasin
        + macroNoise
        + microNoise

    local crownMask = gaussian2(xNorm, zNorm, 0, -0.58, 0.16, 0.1)
    if crownMask > 0.08 then
        height = lerp(height, 620, clamp(crownMask * 0.32, 0, 0.32))
    end

    local peakMask = gaussian2(xNorm, zNorm, 0, peakZNorm, 0.26, 0.2)
    if peakMask > 0.04 then
        height = lerp(height, 760, clamp(peakMask * 0.62, 0, 0.62))
    end

    local lakeMask = gaussian2(xNorm, zNorm, 0, 0.72, 0.28, 0.15)
    if lakeMask > 0.1 then
        height = lerp(height, layout.waterLevel - 22, clamp(lakeMask * 0.84, 0, 0.84))
    end

    return clamp(height, layout.terrainFloor + 24, layout.maxPeakHeight)
end

local function terrainPosition(layout, x, z, lift)
    return Vector3.new(x, sampleMountainHeight(layout, x, z) + (lift or 0), z)
end

local function mountainSurfaceStyle(layout, palette, x, z, height)
    if z > layout.lakeCenter.Z - (layout.cellSize * 4) and height < layout.waterLevel + 12 then
        return Enum.Material.Rock, Color3.fromRGB(90, 98, 104)
    end
    if height > 720 then
        return Enum.Material.Rock, Color3.fromRGB(168, 172, 180)
    end
    if height > 520 then
        return Enum.Material.Rock, Color3.fromRGB(158, 164, 172)
    end
    if height > 340 then
        return Enum.Material.Rock, Color3.fromRGB(150, 156, 164)
    end
    if height > 280 then
        return Enum.Material.Rock, Color3.fromRGB(138, 144, 152)
    end
    if z < layout.summitCenter.Z + (layout.cellSize * 10) then
        return Enum.Material.Slate, palette.Primary
    end
    if math.abs(x) < layout.worldWidth * 0.12 and z < layout.lakeCenter.Z then
        return Enum.Material.Ground, Color3.fromRGB(88, 104, 94)
    end
    return Enum.Material.Slate, palette.Base
end

local function classifyMountainSection(layout, x, z)
    if z >= layout.lakeCenter.Z - (layout.cellSize * 4) then
        return "LakeBasin"
    end
    if z <= layout.summitCenter.Z + (layout.summitRadius * 1.05) then
        return "SummitCrown"
    end
    if x <= -(layout.worldWidth * 0.23) then
        return "WestRange"
    end
    if x < -(layout.worldWidth * 0.06) then
        return "WestValley"
    end
    if x >= layout.worldWidth * 0.23 then
        return "EastRange"
    end
    if x > layout.worldWidth * 0.06 then
        return "EastValley"
    end
    return "CentralSpine"
end

local function createMountainSections(parent, layout)
    local sectionsRoot = createModel(parent, "TerrainSections")
    local sections = {}
    for _, name in ipairs(layout.sectionNames) do
        local sectionModel = createModel(sectionsRoot, name)
        sectionModel:SetAttribute("SectionName", name)
        sectionModel:SetAttribute("SectionMode", layout.sectionMode)
        sections[name] = sectionModel
    end
    return sections
end

local function buildMountainLake(section, layout)
    local water = makePart(section, "LakeWater", Vector3.new(layout.lakeRadiusX * 2, 8, layout.lakeRadiusZ * 2), CFrame.new(0, layout.waterLevel, layout.lakeCenter.Z), {
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(84, 145, 184),
        Transparency = 0.26,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    addPointLight(water, "LakeGlow", Color3.fromRGB(108, 168, 210), 2.2, 110)

    makePart(section, "LakeCore", Vector3.new(layout.lakeRadiusX * 0.7, 2, layout.lakeRadiusZ * 0.45), CFrame.new(0, layout.waterLevel - 3, layout.lakeCenter.Z), {
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(110, 190, 222),
        Transparency = 0.55,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
end

local function pickMountainAccentAnchor(layout, rng, validator)
    for _ = 1, 90 do
        local x = rng:NextNumber(-(layout.worldWidth * 0.4), layout.worldWidth * 0.4)
        local z = rng:NextNumber(layout.summitCenter.Z - (layout.summitRadius * 0.45), layout.lakeCenter.Z - (layout.cellSize * 1.6))
        local y = sampleMountainHeight(layout, x, z)
        local sectionName = classifyMountainSection(layout, x, z)
        if validator(x, z, y, sectionName) then
            return Vector3.new(x, y, z), sectionName
        end
    end
    return nil, nil
end

local function addRockSpire(parent, name, position, height, palette, rng)
    local spire = createModel(parent, name)
    local baseRadius = clamp(height * 0.08, 4, 10)
    local rockColor = Color3.fromRGB(122, 128, 136)

    Workspace.Terrain:FillBall(position + Vector3.new(0, baseRadius * 0.28, 0), baseRadius * 1.35, Enum.Material.Rock)

    makeVerticalCylinder(spire, "Base", baseRadius * 1.2, height * 0.34, CFrame.new(position + Vector3.new(0, height * 0.16, 0)), {
        Material = Enum.Material.Rock,
        Color = rockColor,
    })
    makeVerticalCylinder(spire, "Mid", baseRadius * 0.78, height * 0.3, CFrame.new(position + Vector3.new(0, height * 0.46, 0)), {
        Material = Enum.Material.Slate,
        Color = palette.Base,
    })
    makeVerticalCylinder(spire, "Tip", baseRadius * 0.42, height * 0.26, CFrame.new(position + Vector3.new(0, height * 0.73, 0)) * CFrame.Angles(math.rad(rng:NextNumber(-4, 4)), 0, math.rad(rng:NextNumber(-7, 7))), {
        Material = Enum.Material.Rock,
        Color = Color3.fromRGB(146, 152, 160),
    })
    makePart(spire, "Shard", Vector3.new(baseRadius * 1.15, height * 0.18, baseRadius * 0.55), CFrame.new(position + Vector3.new(0, height * 0.88, 0)) * CFrame.Angles(math.rad(rng:NextNumber(-10, 10)), math.rad(rng:NextNumber(0, 180)), math.rad(rng:NextNumber(-20, 20))), {
        Material = Enum.Material.Rock,
        Color = rockColor,
    })
end

local function buildMountainTerrainAccents(root, layout, palette, rng)
    local accentRoot = createModel(root, "TerrainAccents")
    local smoothFolder = createModel(accentRoot, "SmoothPoints")
    local rockFolder = createModel(accentRoot, "RockPoints")
    local bumpFolder = createModel(accentRoot, "BumpyPoints")

    local smoothCount = 0
    local rockCount = 0
    local bumpCount = 0

    for index = 1, 18 do
        local anchor, sectionName = pickMountainAccentAnchor(layout, rng, function(_, _, y, section)
            return section ~= "LakeBasin" and y > -30 and y < 360
        end)
        if anchor then
            local radius = rng:NextNumber(18, 34)
            local material = (sectionName == "WestValley" or sectionName == "EastValley") and Enum.Material.Ground or Enum.Material.Rock
            Workspace.Terrain:FillBall(anchor + Vector3.new(0, radius * 0.16, 0), radius, material)
            Workspace.Terrain:FillBall(anchor + Vector3.new(radius * 0.18, radius * 0.06, -(radius * 0.14)), radius * 0.56, material)
            smoothCount += 1
            addVisibleSmoothMound(
                smoothFolder,
                string.format("SmoothMound%02d", index),
                anchor,
                radius,
                (sectionName == "WestValley" or sectionName == "EastValley") and Color3.fromRGB(96, 110, 96) or Color3.fromRGB(118, 124, 132)
            )
        end
    end

    for index = 1, 12 do
        local anchor = pickMountainAccentAnchor(layout, rng, function(_, _, y, section)
            return section ~= "LakeBasin" and y > -20 and y < 260
        end)
        if anchor then
            local clusterSize = rng:NextNumber(12, 22)
            local blobCount = rng:NextInteger(3, 5)
            for blobIndex = 1, blobCount do
                local angle = ((blobIndex - 1) / blobCount) * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
                local radiusOffset = rng:NextNumber(clusterSize * 0.2, clusterSize * 0.7)
                local offset = Vector3.new(math.cos(angle) * radiusOffset, 0, math.sin(angle) * radiusOffset)
                local blobRadius = clusterSize * rng:NextNumber(0.45, 0.9)
                Workspace.Terrain:FillBall(anchor + offset + Vector3.new(0, blobRadius * 0.12, 0), blobRadius, Enum.Material.Rock)
            end
            bumpCount += 1
            addVisibleBumpCluster(bumpFolder, string.format("BumpCluster%02d", index), anchor, clusterSize, palette, rng)
        end
    end

    for index = 1, 11 do
        local anchor = pickMountainAccentAnchor(layout, rng, function(_, _, y, section)
            return (section == "SummitCrown" or section == "WestRange" or section == "EastRange" or section == "CentralSpine") and y > 140
        end)
        if anchor then
            addRockSpire(rockFolder, string.format("RockSpire%02d", index), anchor, rng:NextNumber(44, 86), palette, rng)
            rockCount += 1
        end
    end

    Workspace:SetAttribute("PromptWorldSmoothAccentCount", smoothCount)
    Workspace:SetAttribute("PromptWorldRockAccentCount", rockCount)
    Workspace:SetAttribute("PromptWorldBumpAccentCount", bumpCount)
end

local function buildMountainWaterways(root, layout, palette)
    local waterFolder = ensureFolder(root, "Waterways")
    local floodFolder = createModel(waterFolder, "ValleyFlood")
    local waterfallFolder = createModel(waterFolder, "Waterfalls")
    local westBranch = stabilizeDownhillNodes({
        terrainPosition(layout, -(layout.worldWidth * 0.12), 120, 1.2),
        terrainPosition(layout, -(layout.worldWidth * 0.16), 180, 1.1),
        terrainPosition(layout, -(layout.worldWidth * 0.2), layout.lakeCenter.Z - (layout.lakeRadiusZ * 1.05), 1.2),
        Vector3.new(-(layout.lakeRadiusX * 0.42), layout.waterLevel + 2.2, layout.lakeCenter.Z - (layout.lakeRadiusZ * 0.58)),
    }, 1.6)
    local eastBranch = stabilizeDownhillNodes({
        terrainPosition(layout, layout.worldWidth * 0.12, 120, 1.2),
        terrainPosition(layout, layout.worldWidth * 0.16, 180, 1.1),
        terrainPosition(layout, layout.worldWidth * 0.2, layout.lakeCenter.Z - (layout.lakeRadiusZ * 1.05), 1.2),
        Vector3.new(layout.lakeRadiusX * 0.42, layout.waterLevel + 2.2, layout.lakeCenter.Z - (layout.lakeRadiusZ * 0.58)),
    }, 1.6)
    local westFalls = stabilizeDownhillNodes({
        westBranch[#westBranch - 1],
        Vector3.new(-(layout.lakeRadiusX * 0.4), westBranch[#westBranch - 1].Y - 22, layout.lakeCenter.Z - (layout.lakeRadiusZ * 0.74)),
        Vector3.new(-(layout.lakeRadiusX * 0.34), layout.waterLevel + 2.6, layout.lakeCenter.Z - (layout.lakeRadiusZ * 0.36)),
    }, 8.5)
    local eastFalls = stabilizeDownhillNodes({
        eastBranch[#eastBranch - 1],
        Vector3.new(layout.lakeRadiusX * 0.4, eastBranch[#eastBranch - 1].Y - 22, layout.lakeCenter.Z - (layout.lakeRadiusZ * 0.74)),
        Vector3.new(layout.lakeRadiusX * 0.34, layout.waterLevel + 2.6, layout.lakeCenter.Z - (layout.lakeRadiusZ * 0.36)),
    }, 8.5)

    local terrainWaterSegments = 0
    terrainWaterSegments += fillTerrainRibbon(westBranch, 16, 6, Enum.Material.Water)
    terrainWaterSegments += fillTerrainRibbon(eastBranch, 16, 6, Enum.Material.Water)
    terrainWaterSegments += fillTerrainRibbon(westFalls, 13, 7, Enum.Material.Water)
    terrainWaterSegments += fillTerrainRibbon(eastFalls, 13, 7, Enum.Material.Water)

    addWaterRibbon(waterFolder, "WestBranch", westBranch, 18, palette)
    addWaterRibbon(waterFolder, "EastBranch", eastBranch, 18, palette)
    addWaterRibbon(waterfallFolder, "WestFalls", westFalls, 14, palette)
    addWaterRibbon(waterfallFolder, "EastFalls", eastFalls, 14, palette)
    addWaterfallSheet(waterfallFolder, "WestFallsSheet", westFalls[1] + Vector3.new(0, 4, 0), westFalls[#westFalls] + Vector3.new(0, 2.4, 0), 24, palette)
    addWaterfallSheet(waterfallFolder, "EastFallsSheet", eastFalls[1] + Vector3.new(0, 4, 0), eastFalls[#eastFalls] + Vector3.new(0, 2.4, 0), 24, palette)

    for zIndex = 0, layout.depthCells - 1 do
        local zAlpha = zIndex / (layout.depthCells - 1)
        local z = (zAlpha - 0.5) * layout.worldDepth
        for xIndex = 0, layout.widthCells - 1 do
            local xAlpha = xIndex / (layout.widthCells - 1)
            local x = (xAlpha - 0.5) * layout.worldWidth
            local sectionName = classifyMountainSection(layout, x, z)
            local topY = sampleMountainHeight(layout, x, z)
            local isValleySection = sectionName == "WestValley" or sectionName == "EastValley"
            local inLowerValley = z > 90 and z < layout.lakeCenter.Z + (layout.lakeRadiusZ * 0.78)
            local isValleyBottom = topY <= 75

            if isValleySection and inLowerValley and isValleyBottom then
                local waterHeight = 5.2
                local water = makePart(
                    floodFolder,
                    string.format("Flood_%02d_%02d", xIndex, zIndex),
                    Vector3.new(layout.cellSize + 1.2, waterHeight, layout.cellSize + 1.2),
                    CFrame.new(x, topY + (waterHeight * 0.5) + 0.9, z),
                    {
                        Material = Enum.Material.Glass,
                        Color = Color3.fromRGB(90, 162, 206),
                        Transparency = 0.2,
                        CanCollide = false,
                        CanTouch = false,
                        CanQuery = false,
                        CastShadow = false,
                    }
                )

                if (xIndex + zIndex) % 26 == 0 then
                    addPointLight(water, "ValleyGlow", palette.Highlight, 1.2, 24)
                end
            end
        end
    end

    Workspace:SetAttribute("PromptWorldWaterTerrainSegments", terrainWaterSegments)
    Workspace:SetAttribute("PromptWorldWaterfallCount", 2)
end

local function buildMountainTerrain(root, layout, palette)
    local sections = createMountainSections(root, layout)

    for zIndex = 0, layout.depthCells - 1 do
        local zAlpha = zIndex / (layout.depthCells - 1)
        local z = (zAlpha - 0.5) * layout.worldDepth
        for xIndex = 0, layout.widthCells - 1 do
            local xAlpha = xIndex / (layout.widthCells - 1)
            local x = (xAlpha - 0.5) * layout.worldWidth
            local topY = sampleMountainHeight(layout, x, z)
            local columnHeight = topY - layout.terrainFloor
            local sectionName = classifyMountainSection(layout, x, z)
            local material, color = mountainSurfaceStyle(layout, palette, x, z, topY)

            makePart(
                sections[sectionName],
                string.format("Tile_%02d_%02d", xIndex, zIndex),
                Vector3.new(layout.cellSize, columnHeight, layout.cellSize),
                CFrame.new(x, layout.terrainFloor + (columnHeight * 0.5), z),
                {
                    Material = material,
                    Color = color,
                }
            )
        end
    end

    if layout.waterFeature == "lake" then
        buildMountainLake(sections.LakeBasin, layout)
    end
end

local function buildMountainPaths(root, layout, palette)
    local pathFolder = ensureFolder(root, "Paths")
    local function ascentNode(x, z, targetY, clearance)
        local terrainY = sampleMountainHeight(layout, x, z)
        return Vector3.new(x, math.max(terrainY + (clearance or 6), targetY), z)
    end
    local function rampNode(x, z, targetY)
        return Vector3.new(x, targetY, z)
    end

    local trailhead = terrainPosition(layout, 0, layout.lakeCenter.Z - 150, 6)
    local trailTarget = trailhead.Y
    local summitTarget = math.min(layout.maxPeakHeight - 30, 860)
    local ascentNodes = {
        trailhead,
        ascentNode(-(layout.worldWidth * 0.12), layout.lakeCenter.Z - 110, lerp(trailTarget, summitTarget, 0.08), 6),
        ascentNode(layout.worldWidth * 0.1, layout.lakeCenter.Z - 65, lerp(trailTarget, summitTarget, 0.14), 6),
        ascentNode(-(layout.worldWidth * 0.14), layout.lakeCenter.Z - 10, lerp(trailTarget, summitTarget, 0.2), 6),
        ascentNode(layout.worldWidth * 0.13, 50, lerp(trailTarget, summitTarget, 0.27), 6),
        ascentNode(-(layout.worldWidth * 0.16), 10, lerp(trailTarget, summitTarget, 0.34), 7),
        ascentNode(layout.worldWidth * 0.15, -44, lerp(trailTarget, summitTarget, 0.41), 7),
        ascentNode(-(layout.worldWidth * 0.1), -108, lerp(trailTarget, summitTarget, 0.47), 7),
        ascentNode(layout.worldWidth * 0.08, -170, lerp(trailTarget, summitTarget, 0.52), 7),
        ascentNode(-(layout.summitRadius * 0.38), layout.summitCenter.Z + (layout.cellSize * 10.5), lerp(trailTarget, summitTarget, 0.57), 8),
        ascentNode(layout.summitRadius * 0.34, layout.summitCenter.Z + (layout.cellSize * 9.4), lerp(trailTarget, summitTarget, 0.62), 8),
        ascentNode(-(layout.summitRadius * 0.28), layout.summitCenter.Z + (layout.cellSize * 8.2), lerp(trailTarget, summitTarget, 0.67), 8),
        ascentNode(layout.summitRadius * 0.24, layout.summitCenter.Z + (layout.cellSize * 7.1), lerp(trailTarget, summitTarget, 0.72), 8),
        ascentNode(-(layout.summitRadius * 0.2), layout.summitCenter.Z + (layout.cellSize * 6.1), lerp(trailTarget, summitTarget, 0.77), 9),
        ascentNode(layout.summitRadius * 0.16, layout.summitCenter.Z + (layout.cellSize * 5.2), lerp(trailTarget, summitTarget, 0.82), 9),
        rampNode(-(layout.summitRadius * 0.28), layout.summitCenter.Z + (layout.cellSize * 4.8), 540),
        rampNode(layout.summitRadius * 0.26, layout.summitCenter.Z + (layout.cellSize * 4.0), 590),
        rampNode(-(layout.summitRadius * 0.22), layout.summitCenter.Z + (layout.cellSize * 3.2), 640),
        rampNode(layout.summitRadius * 0.18, layout.summitCenter.Z + (layout.cellSize * 2.5), 690),
        rampNode(-(layout.summitRadius * 0.14), layout.peakCenter.Z + (layout.cellSize * 1.9), 740),
        rampNode(layout.summitRadius * 0.1, layout.peakCenter.Z + (layout.cellSize * 1.5), 780),
        rampNode(-(layout.summitRadius * 0.06), layout.peakCenter.Z + (layout.cellSize * 1.1), 815),
        rampNode(layout.summitRadius * 0.03, layout.peakCenter.Z + (layout.cellSize * 0.8), 840),
        rampNode(0, layout.peakCenter.Z + (layout.cellSize * 0.55), summitTarget),
    }
    local saddleMid = terrainPosition(layout, 0, 10, 8)
    local lakeFront = Vector3.new(0, layout.waterLevel + 5, layout.lakeCenter.Z + 10)

    addSteppedPath(pathFolder, "SummitAscent", ascentNodes, 18, palette.Highlight)

    addSampledPath(pathFolder, "LakeDescent", {
        saddleMid,
        lakeFront,
    }, 18, palette.Highlight)

    addSampledPath(pathFolder, "WestValleyRun", {
        saddleMid,
        terrainPosition(layout, -120, 44, 6),
        terrainPosition(layout, -250, 90, 6),
        terrainPosition(layout, -360, 24, 7),
    }, 12, palette.Primary)

    addSampledPath(pathFolder, "EastValleyRun", {
        saddleMid,
        terrainPosition(layout, 120, 44, 6),
        terrainPosition(layout, 250, 90, 6),
        terrainPosition(layout, 360, 24, 7),
    }, 12, palette.Primary)

    addSampledPath(pathFolder, "LakeShoreWalk", {
        terrainPosition(layout, -160, layout.lakeCenter.Z + 42, 4),
        lakeFront,
        terrainPosition(layout, 160, layout.lakeCenter.Z + 42, 4),
    }, 12, palette.Secondary)

    addBridge(pathFolder, "WestValleyBridge", terrainPosition(layout, -220, -40, 34), 22, 170, palette.Secondary)
    addBridge(pathFolder, "EastValleyBridge", terrainPosition(layout, 220, -40, 34), 22, 170, palette.Secondary)

    return trailhead + Vector3.new(0, 2, 18)
end

local function buildMountainCore(root, layout, palette)
    local summitCore = terrainPosition(layout, 0, layout.summitCenter.Z, 0)
    local coreFolder = ensureFolder(root, "AncientCore")

    makeVerticalCylinder(coreFolder, "CorePlaza", 62, 8, CFrame.new(summitCore + Vector3.new(0, 4, 0)), {
        Material = Enum.Material.Slate,
        Color = palette.Secondary,
    })
    makeVerticalCylinder(coreFolder, "CoreDais", 28, 12, CFrame.new(summitCore + Vector3.new(0, 9, 0)), {
        Material = Enum.Material.Metal,
        Color = palette.Base,
    })
    addEnergyCore(coreFolder, "MachineCore", summitCore + Vector3.new(0, 34, 0), 20, palette)

    for armIndex = 1, 4 do
        local angle = (armIndex - 1) * (math.pi * 0.5)
        local armPosition = summitCore + Vector3.new(math.cos(angle) * 34, 18, math.sin(angle) * 34)
        addRobotSegment(coreFolder, "CoreArm" .. armIndex, Vector3.new(30, 5, 8), CFrame.new(armPosition) * CFrame.Angles(math.rad(20), angle, math.rad(armIndex % 2 == 0 and 18 or -18)), palette)
    end
end

local function buildMountainMushroomForest(root, worldSpec, layout, palette, rng)
    local forestFolder = ensureFolder(root, "MushroomForest")
    local summitCount = clamp(math.floor((worldSpec.module_count or 96) * 0.95), 80, 150)

    for index = 1, summitCount do
        local angle = rng:NextNumber(0, math.pi * 2)
        local radial = math.sqrt(rng:NextNumber()) * (layout.summitRadius * 0.92)
        local offsetX = math.cos(angle) * radial * 0.92
        local offsetZ = math.sin(angle) * radial * 0.7
        local worldX = layout.summitCenter.X + offsetX
        local worldZ = layout.summitCenter.Z + offsetZ
        local basePosition = Vector3.new(worldX, sampleMountainHeight(layout, worldX, worldZ), worldZ)
        local localNoise = math.noise(worldX * 0.013, worldZ * 0.013, 0.2)
        local height = clamp(34 + (localNoise * 16) + rng:NextNumber(8, 36), 26, 96)
        if index <= 12 then
            height += 32
        end
        local stemRadius = clamp(height * 0.085, 3, 12)
        local capRadius = stemRadius * rng:NextNumber(2.8, 4.9)
        addMushroom(forestFolder, index, basePosition, height, stemRadius, capRadius, palette, rng)
    end

    local valleyCenters = {
        Vector3.new(-(layout.worldWidth * 0.18), 0, 90),
        Vector3.new(layout.worldWidth * 0.18, 0, 90),
    }
    local runningIndex = summitCount
    for valleyIndex, valleyCenter in ipairs(valleyCenters) do
        for clusterIndex = 1, 18 do
            runningIndex += 1
            local angle = rng:NextNumber(0, math.pi * 2)
            local radius = rng:NextNumber(20, layout.cellSize * 2.8)
            local worldX = valleyCenter.X + (math.cos(angle) * radius)
            local worldZ = valleyCenter.Z + (math.sin(angle) * radius)
            local basePosition = Vector3.new(worldX, sampleMountainHeight(layout, worldX, worldZ), worldZ)
            local height = clamp(18 + rng:NextNumber(4, 18) + (valleyIndex * 2), 16, 42)
            local stemRadius = clamp(height * 0.09, 2, 5)
            local capRadius = stemRadius * rng:NextNumber(2.4, 3.6)
            addMushroom(forestFolder, runningIndex, basePosition, height, stemRadius, capRadius, palette, rng)
        end
    end
end

local function buildMountainRuins(root, layout, palette, rng)
    local ruinFolder = ensureFolder(root, "AncientRobotRuins")

    local ruinPlacements = {
        {kind = "gate", x = 0, z = layout.peakCenter.Z + (layout.cellSize * 1.55), facing = math.pi, scale = 1.12},
        {kind = "gate", x = -(layout.summitRadius * 0.28), z = layout.peakCenter.Z - (layout.cellSize * 1.05), facing = math.rad(26), scale = 0.96},
        {kind = "gate", x = layout.summitRadius * 0.24, z = layout.peakCenter.Z - (layout.cellSize * 1.55), facing = math.rad(204), scale = 0.92},
        {kind = "colossus", x = -(layout.summitRadius * 0.34), z = layout.peakCenter.Z + (layout.cellSize * 0.35), facing = math.rad(48), scale = 1.08},
        {kind = "colossus", x = layout.summitRadius * 0.31, z = layout.peakCenter.Z - (layout.cellSize * 0.4), facing = math.rad(218), scale = 1.14},
        {kind = "colossus", x = layout.summitRadius * 0.08, z = layout.peakCenter.Z + (layout.cellSize * 2.2), facing = math.rad(182), scale = 1.02},
        {kind = "rib", x = -(layout.summitRadius * 0.22), z = layout.peakCenter.Z + (layout.cellSize * 2.4), facing = math.rad(128), scale = 1},
        {kind = "rib", x = layout.summitRadius * 0.27, z = layout.peakCenter.Z + (layout.cellSize * 1.2), facing = math.rad(292), scale = 1.04},
        {kind = "rib", x = -(layout.summitRadius * 0.1), z = layout.peakCenter.Z - (layout.cellSize * 2.1), facing = math.rad(14), scale = 0.96},
    }

    for _, placement in ipairs(ruinPlacements) do
        local basePosition = terrainPosition(layout, placement.x, placement.z, 0)
        if placement.kind == "gate" then
            buildRuinGate(ruinFolder, basePosition, placement.facing, placement.scale, palette)
        elseif placement.kind == "colossus" then
            buildFallenColossus(ruinFolder, basePosition, placement.facing, placement.scale, palette, rng)
        else
            buildRibRuin(ruinFolder, basePosition, placement.facing, placement.scale, palette, rng)
        end
    end
end

local function placeSpawn(root, spawnPosition)
    local spawnFolder = ensureFolder(root, "Spawn")
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "PromptSpawn"
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.Material = Enum.Material.Neon
    spawn.Color = Color3.fromRGB(126, 208, 255)
    spawn.Transparency = 0.18
    spawn.CFrame = CFrame.new(spawnPosition + Vector3.new(0, 3.2, 10))
    spawn.Parent = spawnFolder
    addPointLight(spawn, "SpawnLight", spawn.Color, 2.8, 28)
end

local function publishAttributes(title, worldSpec, worldRadius, generationSeed, layout)
    Workspace:SetAttribute("PromptWorldTitle", title)
    Workspace:SetAttribute("PromptWorldTheme", worldSpec.theme)
    Workspace:SetAttribute("PromptWorldTerrain", worldSpec.terrain)
    Workspace:SetAttribute("PromptWorldScale", worldSpec.scale)
    Workspace:SetAttribute("PromptWorldModuleCount", worldSpec.module_count)
    Workspace:SetAttribute("PromptWorldRadius", worldRadius)
    Workspace:SetAttribute("PromptWorldGenerationSeed", generationSeed)

    if layout then
        Workspace:SetAttribute("PromptWorldSectionMode", layout.sectionMode or "single-zone")
        Workspace:SetAttribute("PromptWorldSectionCount", layout.sectionNames and #layout.sectionNames or 1)
        Workspace:SetAttribute("PromptWorldMountainRangeCount", layout.mountainRangeCount or 0)
        Workspace:SetAttribute("PromptWorldValleyCount", layout.valleyCount or 0)
        Workspace:SetAttribute("PromptWorldWaterFeature", layout.waterFeature or "")
    else
        Workspace:SetAttribute("PromptWorldSectionMode", "single-zone")
        Workspace:SetAttribute("PromptWorldSectionCount", 1)
        Workspace:SetAttribute("PromptWorldMountainRangeCount", 0)
        Workspace:SetAttribute("PromptWorldValleyCount", 0)
        Workspace:SetAttribute("PromptWorldWaterFeature", "")
    end
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

    local root = Instance.new("Model")
    root.Name = ROOT_NAME
    root.Parent = Workspace

    if isMountainWorld(worldSpec) then
        local layout = buildMountainLayout(worldSpec, seed)
        local worldRadius = math.max(layout.worldWidth, layout.worldDepth) * 0.5

        buildMountainTerrain(root, layout, palette)
        buildMountainWaterways(root, layout, palette)
        buildMountainCore(root, layout, palette)
        buildMountainMushroomForest(root, worldSpec, layout, palette, rng)
        buildMountainRuins(root, layout, palette, rng)
        local spawnPosition = buildMountainPaths(root, layout, palette)
        placeSpawn(root, spawnPosition)
        publishAttributes(display.Title or "Prompt World", worldSpec, worldRadius, seed, layout)
    else
        local worldRadius = math.max(240, (worldSpec.module_count or 36) * 6)
        addGround(root, worldRadius, palette)
        buildPaths(root, palette, worldRadius)
        buildAncientCore(root, palette)

        if worldSpec.flora_style == "mushroom-forest" or table.find(worldSpec.module_families or {}, "mushroom_grove") then
            buildMushroomForest(root, worldSpec, palette, rng, worldRadius)
        end

        if table.find(worldSpec.module_families or {}, "robot_ruin") or table.find(worldSpec.module_families or {}, "fallen_colossus") then
            buildRuinRing(root, worldSpec, palette, rng, worldRadius)
        end

        placeSpawn(root, Vector3.new(0, 0, worldRadius * 0.74))
        publishAttributes(display.Title or "Prompt World", worldSpec, worldRadius, seed, nil)
    end

    return root
end

function PromptWorldService.generateInStudio()
    return buildWorld()
end

function PromptWorldService.start()
    return buildWorld()
end

return PromptWorldService
