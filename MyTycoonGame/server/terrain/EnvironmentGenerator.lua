local Workspace = game:GetService("Workspace")
local Noise = require(script.Parent.Noise)

local EnvironmentGenerator = {}

local function getManagedCenter(profile)
    local center = profile.ManagedCenter
    return Vector3.new(center.X, center.Y, center.Z)
end

local function getOrCreateRootFolder(folderName)
    local existing = Workspace:FindFirstChild(folderName)
    if existing then
        existing:Destroy()
    end

    local root = Instance.new("Folder")
    root.Name = folderName
    root.Parent = Workspace
    return root
end

local function ensureCategory(parent, name)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function createPart(parent, name, size, cframe, color, material, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Transparency = transparency or 0
    part.Parent = parent
    return part
end

local function createTree(parent, position, scale, seedValue)
    local tree = Instance.new("Model")
    tree.Name = "GeneratedTree"
    tree.Parent = parent

    local trunkColor = Color3.fromRGB(89 + seedValue % 18, 65, 42)
    local canopyColor = Color3.fromRGB(75, 127 + seedValue % 20, 70)

    createPart(tree, "Trunk", Vector3.new(1.4 * scale, 8 * scale, 1.4 * scale), CFrame.new(position + Vector3.new(0, 4 * scale, 0)), trunkColor, Enum.Material.Wood, 0)
    createPart(tree, "CanopyLower", Vector3.new(5.5 * scale, 4.5 * scale, 5.5 * scale), CFrame.new(position + Vector3.new(0, 8.5 * scale, 0)), canopyColor, Enum.Material.Grass, 0).Shape = Enum.PartType.Ball
    createPart(tree, "CanopyUpper", Vector3.new(4.2 * scale, 3.6 * scale, 4.2 * scale), CFrame.new(position + Vector3.new(0, 11.2 * scale, 0)), canopyColor:Lerp(Color3.new(1, 1, 1), 0.06), Enum.Material.Grass, 0).Shape = Enum.PartType.Ball
    tree:PivotTo(CFrame.new(position))
    return tree
end

local function createBush(parent, position, scale, seedValue)
    local bush = Instance.new("Model")
    bush.Name = "GeneratedBush"
    bush.Parent = parent
    local baseColor = Color3.fromRGB(69, 118 + seedValue % 24, 64)
    createPart(bush, "BushCore", Vector3.new(4.2 * scale, 2.4 * scale, 4.2 * scale), CFrame.new(position + Vector3.new(0, 1.2 * scale, 0)), baseColor, Enum.Material.Grass, 0).Shape = Enum.PartType.Ball
    createPart(bush, "BushAccent", Vector3.new(2.6 * scale, 2.0 * scale, 2.6 * scale), CFrame.new(position + Vector3.new(1.1 * scale, 1.7 * scale, 0)), baseColor:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.Grass, 0).Shape = Enum.PartType.Ball
    bush:PivotTo(CFrame.new(position))
    return bush
end

local function createRockCluster(parent, position, scale, seedValue)
    local rock = Instance.new("Model")
    rock.Name = "GeneratedRockCluster"
    rock.Parent = parent
    local baseColor = Color3.fromRGB(109 + seedValue % 20, 107 + seedValue % 14, 108 + seedValue % 10)
    createPart(rock, "RockA", Vector3.new(3.4 * scale, 2.6 * scale, 3.8 * scale), CFrame.new(position + Vector3.new(-0.8 * scale, 1.3 * scale, 0.6 * scale)) * CFrame.Angles(0.12, 0.25, -0.1), baseColor, Enum.Material.Slate, 0)
    createPart(rock, "RockB", Vector3.new(2.8 * scale, 2.0 * scale, 2.8 * scale), CFrame.new(position + Vector3.new(1.0 * scale, 1.0 * scale, -0.6 * scale)) * CFrame.Angles(-0.08, -0.3, 0.14), baseColor:Lerp(Color3.new(1, 1, 1), 0.06), Enum.Material.Rock, 0)
    rock:PivotTo(CFrame.new(position))
    return rock
end

local function createCactus(parent, position, scale, seedValue)
    local cactus = Instance.new("Model")
    cactus.Name = "GeneratedCactus"
    cactus.Parent = parent
    local color = Color3.fromRGB(84, 133 + seedValue % 25, 78)
    createPart(cactus, "Body", Vector3.new(1.8 * scale, 7.2 * scale, 1.8 * scale), CFrame.new(position + Vector3.new(0, 3.6 * scale, 0)), color, Enum.Material.SmoothPlastic, 0)
    createPart(cactus, "ArmLeft", Vector3.new(1.1 * scale, 3.0 * scale, 1.1 * scale), CFrame.new(position + Vector3.new(-1.2 * scale, 3.2 * scale, 0)) * CFrame.Angles(0, 0, math.rad(30)), color, Enum.Material.SmoothPlastic, 0)
    createPart(cactus, "ArmRight", Vector3.new(1.1 * scale, 2.4 * scale, 1.1 * scale), CFrame.new(position + Vector3.new(1.0 * scale, 4.3 * scale, 0)) * CFrame.Angles(0, 0, math.rad(-35)), color, Enum.Material.SmoothPlastic, 0)
    cactus:PivotTo(CFrame.new(position))
    return cactus
end

local function createLandmark(parent, position, scale, profileName)
    local landmark = Instance.new("Model")
    landmark.Name = "GeneratedLandmark"
    landmark.Parent = parent
    local baseColor = profileName == "DesertCanyon" and Color3.fromRGB(173, 129, 84) or Color3.fromRGB(126, 129, 137)
    createPart(landmark, "Base", Vector3.new(8 * scale, 2 * scale, 8 * scale), CFrame.new(position + Vector3.new(0, scale, 0)), baseColor, Enum.Material.Rock, 0)
    createPart(landmark, "PillarA", Vector3.new(1.8 * scale, 7.5 * scale, 1.8 * scale), CFrame.new(position + Vector3.new(-2.1 * scale, 5 * scale, 0)), baseColor:Lerp(Color3.new(1, 1, 1), 0.04), Enum.Material.Slate, 0)
    createPart(landmark, "PillarB", Vector3.new(1.8 * scale, 6.2 * scale, 1.8 * scale), CFrame.new(position + Vector3.new(2.1 * scale, 4.4 * scale, 0)), baseColor:Lerp(Color3.new(1, 1, 1), 0.1), Enum.Material.Slate, 0)
    createPart(landmark, "Beam", Vector3.new(6.8 * scale, 1.3 * scale, 1.5 * scale), CFrame.new(position + Vector3.new(0, 8.1 * scale, 0)), baseColor, Enum.Material.Slate, 0)
    landmark:PivotTo(CFrame.new(position))
    return landmark
end

local function buildRaycastParams(environmentRoot)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { environmentRoot }
    params.IgnoreWater = false
    return params
end

local function shouldSkipSpawn(profile, position)
    local center = getManagedCenter(profile)
    local offset = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
    return offset.Magnitude < (profile.Spawn.FlattenRadius + 18)
end

local function spawnProp(profile, categories, position, material, randomness)
    local seedValue = math.floor(randomness * 1000)
    if material == Enum.Material.Water then
        return nil
    end

    if profile.Name == "DesertCanyon" then
        if randomness < profile.Props.TreeDensity then
            return createCactus(categories.Trees, position, 1.0 + randomness, seedValue)
        end
        if randomness < profile.Props.TreeDensity + profile.Props.RockDensity then
            return createRockCluster(categories.Rocks, position, 1.1 + randomness * 0.6, seedValue)
        end
        if randomness > 1 - profile.Props.LandmarkDensity then
            return createLandmark(categories.Landmarks, position, 1.0 + randomness, profile.Name)
        end
        return nil
    end

    if material == Enum.Material.Rock or material == Enum.Material.Slate then
        if randomness < profile.Props.RockDensity then
            return createRockCluster(categories.Rocks, position, 0.9 + randomness * 0.8, seedValue)
        end
        if randomness > 1 - profile.Props.LandmarkDensity then
            return createLandmark(categories.Landmarks, position, 0.9 + randomness * 0.7, profile.Name)
        end
        return nil
    end

    if material == Enum.Material.Snow then
        if randomness < profile.Props.TreeDensity * 0.5 then
            return createTree(categories.Trees, position, 0.92 + randomness * 0.4, seedValue)
        end
        if randomness < profile.Props.TreeDensity * 0.5 + profile.Props.RockDensity then
            return createRockCluster(categories.Rocks, position, 1.0 + randomness * 0.5, seedValue)
        end
        return nil
    end

    if randomness < profile.Props.TreeDensity then
        return createTree(categories.Trees, position, 0.95 + randomness * 0.55, seedValue)
    end
    if randomness < profile.Props.TreeDensity + profile.Props.BushDensity then
        return createBush(categories.Bushes, position, 0.95 + randomness * 0.5, seedValue)
    end
    if randomness < profile.Props.TreeDensity + profile.Props.BushDensity + profile.Props.RockDensity then
        return createRockCluster(categories.Rocks, position, 0.9 + randomness * 0.5, seedValue)
    end
    if randomness > 1 - profile.Props.LandmarkDensity then
        return createLandmark(categories.Landmarks, position, 0.9 + randomness * 0.6, profile.Name)
    end
    return nil
end

function EnvironmentGenerator.generate(profile, seed, config, options)
    local environmentRoot = getOrCreateRootFolder(config.GeneratedEnvironmentFolderName)
    local categories = {
        Trees = ensureCategory(environmentRoot, "Trees"),
        Bushes = ensureCategory(environmentRoot, "Bushes"),
        Rocks = ensureCategory(environmentRoot, "Rocks"),
        Landmarks = ensureCategory(environmentRoot, "Landmarks"),
    }
    local raycastParams = buildRaycastParams(environmentRoot)
    local center = getManagedCenter(profile)
    local stride = profile.Props.ScatterStride
    local halfSize = profile.WorldSize * 0.5
    local propCount = 0

    for x = center.X - halfSize, center.X + halfSize, stride do
        for z = center.Z - halfSize, center.Z + halfSize, stride do
            local randomness = Noise.hash01(math.floor(x / stride), math.floor(z / stride), seed + 887)
            if randomness > 0.78 then
                local origin = Vector3.new(x, profile.ClearMaxY - 4, z)
                local direction = Vector3.new(0, -(profile.ClearMaxY - profile.ClearMinY + 180), 0)
                local result = Workspace:Raycast(origin, direction, raycastParams)
                if result and not shouldSkipSpawn(profile, result.Position) and result.Normal.Y >= 0.65 then
                    local placed = spawnProp(profile, categories, result.Position, result.Material, randomness)
                    if placed then
                        propCount = propCount + 1
                    end
                end
            end
        end
        task.wait()
    end

    return {PropCount = propCount}
end

return EnvironmentGenerator
