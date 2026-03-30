
local ModelLibrary = {}

local CYLINDER_ROTATION = CFrame.Angles(0, 0, math.rad(90))

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

local function createRootPart(parent, position)
    return createPart(parent, {
        Name = "Root",
        Size = Vector3.new(1, 1, 1),
        Position = position,
        Transparency = 1,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
    })
end

function ModelLibrary.createFloatingPine(parent, origin)
    local model = createInstance("Model", parent, {Name = "FloatingPine"})
    local root = createRootPart(model, origin)

    createPart(model, {
        Name = "IslandCore",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(20, 14, 20),
        Position = origin + Vector3.new(0, -2, 0),
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(97, 102, 112),
    })

    createPart(model, {
        Name = "GrassCap",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(3, 18, 18),
        CFrame = CFrame.new(origin + Vector3.new(0, 4, 0)) * CYLINDER_ROTATION,
        Material = Enum.Material.Grass,
        Color = Color3.fromRGB(112, 186, 92),
    })

    createPart(model, {
        Name = "Trunk",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(10, 3.5, 3.5),
        CFrame = CFrame.new(origin + Vector3.new(0, 10, 0)) * CYLINDER_ROTATION,
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(117, 84, 57),
    })

    createPart(model, {
        Name = "CanopyBase",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(11, 11, 11),
        Position = origin + Vector3.new(0, 15, 0),
        Material = Enum.Material.Grass,
        Color = Color3.fromRGB(78, 149, 73),
    })

    createPart(model, {
        Name = "CanopyLeft",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(8, 8, 8),
        Position = origin + Vector3.new(-3.5, 14, 1.5),
        Material = Enum.Material.Grass,
        Color = Color3.fromRGB(88, 161, 82),
    })

    createPart(model, {
        Name = "CanopyRight",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(8, 8, 8),
        Position = origin + Vector3.new(3.5, 14, -1.5),
        Material = Enum.Material.Grass,
        Color = Color3.fromRGB(88, 161, 82),
    })

    model.PrimaryPart = root
    return model
end

function ModelLibrary.createCrystalCluster(parent, origin)
    local model = createInstance("Model", parent, {Name = "CrystalCluster"})
    local root = createRootPart(model, origin)
    local crystalData = {
        {offset = Vector3.new(0, 6, 0), size = Vector3.new(3, 12, 3), color = Color3.fromRGB(86, 236, 255), rotation = CFrame.Angles(math.rad(6), 0, math.rad(8))},
        {offset = Vector3.new(-4, 4, 2), size = Vector3.new(2.5, 8, 2.5), color = Color3.fromRGB(122, 255, 251), rotation = CFrame.Angles(math.rad(-8), math.rad(18), math.rad(-6))},
        {offset = Vector3.new(3, 3.5, -3), size = Vector3.new(2, 7, 2), color = Color3.fromRGB(132, 198, 255), rotation = CFrame.Angles(math.rad(10), math.rad(-22), math.rad(5))},
        {offset = Vector3.new(5, 2.8, 1), size = Vector3.new(1.8, 5.5, 1.8), color = Color3.fromRGB(168, 255, 255), rotation = CFrame.Angles(math.rad(-12), math.rad(8), math.rad(-10))},
    }

    createPart(model, {
        Name = "RockBase",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(4, 16, 16),
        CFrame = CFrame.new(origin) * CYLINDER_ROTATION,
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(89, 94, 106),
    })

    for index, crystal in ipairs(crystalData) do
        createPart(model, {
            Name = "Crystal" .. index,
            Size = crystal.size,
            CFrame = CFrame.new(origin + crystal.offset) * crystal.rotation,
            Material = Enum.Material.Neon,
            Color = crystal.color,
        })
    end

    model.PrimaryPart = root
    return model
end

function ModelLibrary.createStoneArch(parent, origin)
    local model = createInstance("Model", parent, {Name = "StoneArch"})
    local root = createRootPart(model, origin)

    createPart(model, {
        Name = "LeftPillar",
        Size = Vector3.new(5, 22, 5),
        Position = origin + Vector3.new(-8, 11, 0),
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(102, 107, 119),
    })

    createPart(model, {
        Name = "RightPillar",
        Size = Vector3.new(5, 22, 5),
        Position = origin + Vector3.new(8, 11, 0),
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(102, 107, 119),
    })

    createPart(model, {
        Name = "TopBeam",
        Size = Vector3.new(24, 4, 6),
        Position = origin + Vector3.new(0, 22, 0),
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(120, 127, 140),
    })

    createPart(model, {
        Name = "RuneStone",
        Size = Vector3.new(14, 2, 5),
        Position = origin + Vector3.new(0, 15, 0),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(123, 207, 255),
        CanCollide = false,
    })

    model.PrimaryPart = root
    return model
end

function ModelLibrary.createMarketStand(parent, origin)
    local model = createInstance("Model", parent, {Name = "MarketStand"})
    local root = createRootPart(model, origin)
    local postOffsets = {
        Vector3.new(-6, 6, -4),
        Vector3.new(6, 6, -4),
        Vector3.new(-6, 6, 4),
        Vector3.new(6, 6, 4),
    }

    createPart(model, {
        Name = "Base",
        Size = Vector3.new(18, 1, 14),
        Position = origin,
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(115, 85, 58),
    })

    createPart(model, {
        Name = "Counter",
        Size = Vector3.new(16, 4, 5),
        Position = origin + Vector3.new(0, 2.5, 4.5),
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(136, 98, 65),
    })

    for index, offset in ipairs(postOffsets) do
        createPart(model, {
            Name = "Post" .. index,
            Size = Vector3.new(1.5, 12, 1.5),
            Position = origin + offset,
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(104, 72, 48),
        })
    end

    createPart(model, {
        Name = "Roof",
        Size = Vector3.new(20, 2, 16),
        Position = origin + Vector3.new(0, 13, 0),
        Material = Enum.Material.Fabric,
        Color = Color3.fromRGB(232, 182, 72),
    })

    model.PrimaryPart = root
    return model
end

function ModelLibrary.createCloudPad(parent, origin)
    local model = createInstance("Model", parent, {Name = "CloudPad"})
    local root = createRootPart(model, origin)
    local cloudOffsets = {
        Vector3.new(-4, 2, 0),
        Vector3.new(4, 2, 1),
        Vector3.new(0, 2.5, -3),
        Vector3.new(0, 2, 4),
    }

    createPart(model, {
        Name = "Pad",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(2, 18, 18),
        CFrame = CFrame.new(origin + Vector3.new(0, 3, 0)) * CYLINDER_ROTATION,
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(255, 243, 161),
    })

    for index, offset in ipairs(cloudOffsets) do
        createPart(model, {
            Name = "Cloud" .. index,
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(8, 8, 8),
            Position = origin + offset,
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(244, 247, 255),
            Transparency = 0.08,
        })
    end

    createPart(model, {
        Name = "Beacon",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(3, 3, 3),
        Position = origin + Vector3.new(0, 8, 0),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(120, 223, 255),
        CanCollide = false,
    })

    model.PrimaryPart = root
    return model
end

return ModelLibrary
