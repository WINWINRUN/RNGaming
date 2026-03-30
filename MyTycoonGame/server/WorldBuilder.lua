
local Workspace = game:GetService("Workspace")

local WorldBuilder = {}

local WORLD_NAME = "SkyIslandHub"
local WALK_TOP_Y = 130
local PATH_HEIGHT = 8
local BRIDGE_HEIGHT = 2
local CYLINDER_ROTATION = CFrame.Angles(0, 0, math.rad(90))

local COLORS = {
    Path = Color3.fromRGB(116, 132, 146),
    PathTrim = Color3.fromRGB(80, 93, 105),
    Rail = Color3.fromRGB(104, 79, 58),
    Grass = Color3.fromRGB(114, 186, 89),
    Stone = Color3.fromRGB(108, 112, 123),
    StoneDark = Color3.fromRGB(73, 77, 87),
    Cloud = Color3.fromRGB(244, 248, 255),
    Shop = Color3.fromRGB(255, 194, 76),
    RNG = Color3.fromRGB(109, 206, 255),
    Light = Color3.fromRGB(255, 244, 187),
    LaneTop = Color3.fromRGB(244, 190, 96),
    LaneBottom = Color3.fromRGB(106, 208, 255),
    Text = Color3.fromRGB(36, 40, 48),
}

local ISLAND_LAYOUT = {
    {name = "TopLeftIsland", position = Vector3.new(-220, WALK_TOP_Y, -148), radius = 46, accent = Color3.fromRGB(164, 229, 121)},
    {name = "TopCenterIsland", position = Vector3.new(0, WALK_TOP_Y, -164), radius = 52, accent = Color3.fromRGB(159, 225, 255)},
    {name = "TopRightIsland", position = Vector3.new(220, WALK_TOP_Y, -148), radius = 46, accent = Color3.fromRGB(173, 235, 139)},
    {name = "BottomLeftIsland", position = Vector3.new(-220, WALK_TOP_Y, 148), radius = 46, accent = Color3.fromRGB(255, 215, 123)},
    {name = "BottomCenterIsland", position = Vector3.new(0, WALK_TOP_Y, 164), radius = 52, accent = Color3.fromRGB(255, 207, 135)},
    {name = "BottomRightIsland", position = Vector3.new(220, WALK_TOP_Y, 148), radius = 46, accent = Color3.fromRGB(255, 221, 147)},
}

local function createInstance(className, parent, properties)
    local instance = Instance.new(className)

    for key, value in pairs(properties or {}) do
        instance[key] = value
    end

    instance.Parent = parent
    return instance
end

local function createPart(parent, properties)
    local defaults = {
        Anchored = true,
        TopSurface = Enum.SurfaceType.Smooth,
        BottomSurface = Enum.SurfaceType.Smooth,
        Material = Enum.Material.SmoothPlastic,
    }

    for key, value in pairs(properties or {}) do
        defaults[key] = value
    end

    return createInstance("Part", parent, defaults)
end

local function addSurfaceLabel(part, face, text, textColor)
    local surfaceGui = createInstance("SurfaceGui", part, {
        Face = face,
        AlwaysOnTop = true,
        PixelsPerStud = 45,
        SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
    })

    createInstance("TextLabel", surfaceGui, {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Text = text,
        TextColor3 = textColor,
        TextScaled = true,
        TextStrokeColor3 = Color3.fromRGB(248, 250, 255),
        TextStrokeTransparency = 0.5,
    })
end

local function createSign(parent, name, cframe, size, text, accentColor)
    local sign = createPart(parent, {
        Name = name,
        Size = size,
        CFrame = cframe,
        Material = Enum.Material.WoodPlanks,
        Color = accentColor,
    })

    addSurfaceLabel(sign, Enum.NormalId.Front, text, COLORS.Text)
    addSurfaceLabel(sign, Enum.NormalId.Back, text, COLORS.Text)
    return sign
end

local function createCloudCluster(parent, center, scale)
    local offsets = {
        Vector3.new(-1.6, 0.0, 0.0),
        Vector3.new(-0.6, 0.3, -0.7),
        Vector3.new(0.5, 0.25, 0.4),
        Vector3.new(1.4, 0.05, -0.25),
        Vector3.new(0.0, 0.45, 0.8),
    }

    for index, offset in ipairs(offsets) do
        local sizeMultiplier = 0.85 + (index * 0.1)

        createPart(parent, {
            Name = "Cloud" .. index,
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(scale, scale, scale) * sizeMultiplier,
            Position = center + Vector3.new(offset.X * scale, offset.Y * scale, offset.Z * scale),
            Material = Enum.Material.SmoothPlastic,
            Color = COLORS.Cloud,
            Transparency = 0.18,
            CanCollide = false,
            CastShadow = false,
        })
    end
end

local function createLightPost(parent, name, position)
    createPart(parent, {
        Name = name .. "Post",
        Size = Vector3.new(2, 6, 2),
        Position = Vector3.new(position.X, WALK_TOP_Y + 3, position.Z),
        Material = Enum.Material.WoodPlanks,
        Color = COLORS.Rail,
    })

    createPart(parent, {
        Name = name .. "Glow",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(1.6, 1.6, 1.6),
        Position = Vector3.new(position.X, WALK_TOP_Y + 7, position.Z),
        Material = Enum.Material.Neon,
        Color = COLORS.Light,
        CanCollide = false,
    })
end

local function createBridge(parent, name, startPosition, endPosition)
    local bridgeModel = createInstance("Model", parent, {Name = name})
    local deckCenterY = WALK_TOP_Y - (BRIDGE_HEIGHT / 2)
    local midpoint = Vector3.new(
        (startPosition.X + endPosition.X) / 2,
        deckCenterY,
        (startPosition.Z + endPosition.Z) / 2
    )
    local lookTarget = Vector3.new(endPosition.X, deckCenterY, endPosition.Z)
    local bridgeCFrame = CFrame.lookAt(midpoint, lookTarget)
    local length = (Vector3.new(endPosition.X, 0, endPosition.Z) - Vector3.new(startPosition.X, 0, startPosition.Z)).Magnitude

    createPart(bridgeModel, {
        Name = "Deck",
        Size = Vector3.new(18, BRIDGE_HEIGHT, length),
        CFrame = bridgeCFrame,
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(139, 109, 79),
    })

    createPart(bridgeModel, {
        Name = "LeftRail",
        Size = Vector3.new(2, 4, length),
        CFrame = bridgeCFrame * CFrame.new(-8, 3, 0),
        Material = Enum.Material.WoodPlanks,
        Color = COLORS.Rail,
    })

    createPart(bridgeModel, {
        Name = "RightRail",
        Size = Vector3.new(2, 4, length),
        CFrame = bridgeCFrame * CFrame.new(8, 3, 0),
        Material = Enum.Material.WoodPlanks,
        Color = COLORS.Rail,
    })

    createLightPost(bridgeModel, name .. "Start", startPosition)
    createLightPost(bridgeModel, name .. "End", endPosition)
end

local function createSegwayLane(parent, name, zPosition, color, velocity, labelText)
    local lane = createPart(parent, {
        Name = name,
        Size = Vector3.new(620, 1.2, 14),
        Position = Vector3.new(0, WALK_TOP_Y + 0.6, zPosition),
        Material = Enum.Material.Metal,
        Color = color,
        AssemblyLinearVelocity = velocity,
        CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.35, 0.2),
    })

    addSurfaceLabel(lane, Enum.NormalId.Top, labelText, COLORS.Text)

    createPart(parent, {
        Name = name .. "StartCap",
        Size = Vector3.new(8, 3, 18),
        Position = Vector3.new(-310, WALK_TOP_Y + 1.5, zPosition),
        Material = Enum.Material.Neon,
        Color = color,
    })

    createPart(parent, {
        Name = name .. "EndCap",
        Size = Vector3.new(8, 3, 18),
        Position = Vector3.new(310, WALK_TOP_Y + 1.5, zPosition),
        Material = Enum.Material.Neon,
        Color = color,
    })
end

local function createTerminal(parent, name, center, labelText, accentColor)
    local terminal = createInstance("Model", parent, {Name = name})
    local signOffset = center.X < 0 and -68 or 68
    local signPosition = center + Vector3.new(signOffset, 28, 0)
    local signCFrame = CFrame.lookAt(signPosition, Vector3.new(0, signPosition.Y, 0))

    createPart(terminal, {
        Name = "Pad",
        Size = Vector3.new(104, 2, 74),
        Position = Vector3.new(center.X, WALK_TOP_Y + 1, center.Z),
        Material = Enum.Material.SmoothPlastic,
        Color = accentColor,
        Transparency = 0.08,
    })

    createPart(terminal, {
        Name = "Booth",
        Size = Vector3.new(34, 20, 30),
        Position = Vector3.new(center.X, WALK_TOP_Y + 10, center.Z),
        Material = Enum.Material.WoodPlanks,
        Color = COLORS.Rail,
    })

    createPart(terminal, {
        Name = "PortalFrame",
        Size = Vector3.new(40, 24, 4),
        Position = Vector3.new(center.X, WALK_TOP_Y + 14, center.Z - 18),
        Material = Enum.Material.Neon,
        Color = accentColor,
        CanCollide = false,
    })

    createSign(terminal, name .. "Sign", signCFrame, Vector3.new(4, 56, 34), labelText, accentColor)
end

local function createSkyIsland(parent, islandInfo)
    local island = createInstance("Model", parent, {Name = islandInfo.name})
    local islandCenter = islandInfo.position
    local radius = islandInfo.radius
    local topCenter = Vector3.new(islandCenter.X, WALK_TOP_Y - 5, islandCenter.Z)
    local landingPadCenter = Vector3.new(islandCenter.X, WALK_TOP_Y - 0.5, islandCenter.Z)
    local detailOffsets = {
        Vector3.new(-radius * 0.24, 2.5, -radius * 0.18),
        Vector3.new(radius * 0.28, 2.5, radius * 0.12),
        Vector3.new(radius * 0.08, 2.5, -radius * 0.3),
    }

    createPart(island, {
        Name = "GrassTop",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(10, radius * 2, radius * 2),
        CFrame = CFrame.new(topCenter) * CYLINDER_ROTATION,
        Material = Enum.Material.Grass,
        Color = COLORS.Grass,
    })

    createPart(island, {
        Name = "StoneShelf",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(16, radius * 2.14, radius * 2.14),
        CFrame = CFrame.new(islandCenter - Vector3.new(0, 8, 0)) * CYLINDER_ROTATION,
        Material = Enum.Material.Slate,
        Color = COLORS.Stone,
    })

    createPart(island, {
        Name = "UndersideCore",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(radius * 1.08, radius * 1.08, radius * 1.08),
        Position = islandCenter - Vector3.new(0, radius * 0.72, 0),
        Material = Enum.Material.Slate,
        Color = COLORS.StoneDark,
    })

    createPart(island, {
        Name = "LandingPad",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(1, radius * 0.92, radius * 0.92),
        CFrame = CFrame.new(landingPadCenter) * CYLINDER_ROTATION,
        Material = Enum.Material.SmoothPlastic,
        Color = islandInfo.accent,
        Transparency = 0.08,
    })

    for index, offset in ipairs(detailOffsets) do
        createPart(island, {
            Name = "AccentStone" .. index,
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(7, 7, 7),
            Position = Vector3.new(islandCenter.X, WALK_TOP_Y + 2.5, islandCenter.Z) + offset,
            Material = Enum.Material.Slate,
            Color = COLORS.Stone,
        })
    end

    createCloudCluster(island, islandCenter - Vector3.new(0, radius * 0.92, 0), radius * 0.24)
end

local function buildGeneralPath(parent)
    local pathModel = createInstance("Model", parent, {Name = "GeneralPath"})

    createPart(pathModel, {
        Name = "Causeway",
        Size = Vector3.new(760, PATH_HEIGHT, 92),
        Position = Vector3.new(0, WALK_TOP_Y - (PATH_HEIGHT / 2), 0),
        Material = Enum.Material.Slate,
        Color = COLORS.Path,
    })

    local plaza = createPart(pathModel, {
        Name = "CenterPlaza",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(10, 118, 118),
        CFrame = CFrame.new(0, WALK_TOP_Y - 5, 0) * CYLINDER_ROTATION,
        Material = Enum.Material.Slate,
        Color = COLORS.PathTrim,
    })

    addSurfaceLabel(plaza, Enum.NormalId.Top, "GENERAL PATH", Color3.fromRGB(239, 244, 248))

    createPart(pathModel, {
        Name = "NorthRail",
        Size = Vector3.new(760, 4, 4),
        Position = Vector3.new(0, WALK_TOP_Y + 2, -48),
        Material = Enum.Material.WoodPlanks,
        Color = COLORS.Rail,
    })

    createPart(pathModel, {
        Name = "SouthRail",
        Size = Vector3.new(760, 4, 4),
        Position = Vector3.new(0, WALK_TOP_Y + 2, 48),
        Material = Enum.Material.WoodPlanks,
        Color = COLORS.Rail,
    })

    createPart(pathModel, {
        Name = "CentralTrim",
        Size = Vector3.new(760, 1, 8),
        Position = Vector3.new(0, WALK_TOP_Y + 0.5, 0),
        Material = Enum.Material.SmoothPlastic,
        Color = COLORS.PathTrim,
        CanCollide = false,
    })

    createInstance("SpawnLocation", pathModel, {
        Name = "HubSpawn",
        Size = Vector3.new(18, 1, 18),
        Position = Vector3.new(0, WALK_TOP_Y + 0.5, 0),
        Anchored = true,
        Neutral = true,
        Duration = 0,
        Enabled = true,
        Material = Enum.Material.Neon,
        Color = COLORS.Light,
    })

    createSegwayLane(pathModel, "ShopToRNGLane", -18, COLORS.LaneTop, Vector3.new(22, 0, 0), "SHOP -> RNG")
    createSegwayLane(pathModel, "RNGToShopLane", 18, COLORS.LaneBottom, Vector3.new(-22, 0, 0), "RNG -> SHOP")

    createTerminal(pathModel, "ShopArea", Vector3.new(-332, WALK_TOP_Y, 0), "SHOP", COLORS.Shop)
    createTerminal(pathModel, "RNGArea", Vector3.new(332, WALK_TOP_Y, 0), "RNG", COLORS.RNG)
end

local function buildIslands(parent, bridgeParent)
    for _, islandInfo in ipairs(ISLAND_LAYOUT) do
        createSkyIsland(parent, islandInfo)

        local pathZ = islandInfo.position.Z < 0 and -52 or 52
        local islandBridgeZ = islandInfo.position.Z < 0
            and islandInfo.position.Z + (islandInfo.radius * 0.66)
            or islandInfo.position.Z - (islandInfo.radius * 0.66)

        createBridge(
            bridgeParent,
            islandInfo.name .. "Bridge",
            Vector3.new(islandInfo.position.X, WALK_TOP_Y, pathZ),
            Vector3.new(islandInfo.position.X, WALK_TOP_Y, islandBridgeZ)
        )
    end
end

local function buildAtmosphere(parent)
    local cloudFields = {
        {position = Vector3.new(-320, WALK_TOP_Y - 26, -220), scale = 18},
        {position = Vector3.new(320, WALK_TOP_Y - 24, -220), scale = 20},
        {position = Vector3.new(-320, WALK_TOP_Y - 24, 220), scale = 20},
        {position = Vector3.new(320, WALK_TOP_Y - 26, 220), scale = 18},
        {position = Vector3.new(0, WALK_TOP_Y - 34, -240), scale = 22},
        {position = Vector3.new(0, WALK_TOP_Y - 34, 240), scale = 22},
    }

    for index, field in ipairs(cloudFields) do
        local cloudGroup = createInstance("Model", parent, {Name = "CloudField" .. index})
        createCloudCluster(cloudGroup, field.position, field.scale)
    end
end

function WorldBuilder:build()
    local existing = Workspace:FindFirstChild(WORLD_NAME)
    if existing then
        existing:Destroy()
    end

    local world = createInstance("Model", Workspace, {Name = WORLD_NAME})
    local structures = createInstance("Folder", world, {Name = "Structures"})
    local islands = createInstance("Folder", world, {Name = "Islands"})
    local bridges = createInstance("Folder", world, {Name = "Bridges"})
    local atmosphere = createInstance("Folder", world, {Name = "Atmosphere"})

    buildGeneralPath(structures)
    buildIslands(islands, bridges)
    buildAtmosphere(atmosphere)

    print("[WorldBuilder] Generated sky island hub world.")
end

return WorldBuilder
