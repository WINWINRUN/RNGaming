local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local ROOT_NAME = "GeneratedPromptWorld"
local TEMPLATE_FOLDER_NAME = "CreatorStoreFoliageTemplates"
local TREE_MODEL_NAME = "SnowPineTree"
local TREE_QUERY = "snow pine tree"
local FOLIAGE_FOLDER_NAME = "CreatorStoreFoliage"

local root = Workspace:FindFirstChild(ROOT_NAME)
assert(root, "GeneratedPromptWorld was not found in Workspace.")

local radius = Workspace:GetAttribute("PromptWorldRadius")
assert(type(radius) == "number" and radius > 0, "PromptWorldRadius is missing.")

local generationSeed = Workspace:GetAttribute("PromptWorldGenerationSeed")
local seed = type(generationSeed) == "number" and generationSeed or 1
local rng = Random.new(seed + 4017)

local function ensureFolder(parent: Instance, name: string): Folder
    local existing = parent:FindFirstChild(name)
    if existing and existing:IsA("Folder") then
        return existing
    end

    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function removeScripts(instance: Instance)
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BaseScript") then
            descendant:Destroy()
        end
    end
end

local function resolveMarketplaceMetadata(query: string)
    local ok, results = pcall(function()
        return InsertService:GetFreeModels(query, 0)
    end)
    if not ok or type(results) ~= "table" or not results[1] or not results[1].Results or not results[1].Results[1] then
        return nil
    end

    local result = results[1].Results[1]
    return {
        query = query,
        marketplace_name = result.Name,
        asset_id = result.AssetId,
        asset_version_id = result.AssetVersionId,
        creator_name = result.CreatorName,
        library_url = string.format("https://www.roblox.com/library/%d", result.AssetId),
    }
end

local templateFolder = ensureFolder(ServerStorage, TEMPLATE_FOLDER_NAME)
local visibleInsertedTree = Workspace:FindFirstChild(TREE_MODEL_NAME)
local treeTemplate = templateFolder:FindFirstChild(TREE_MODEL_NAME)

if visibleInsertedTree and visibleInsertedTree:IsA("Model") then
    removeScripts(visibleInsertedTree)
    if treeTemplate then
        treeTemplate:Destroy()
    end
    visibleInsertedTree.Parent = templateFolder
    treeTemplate = visibleInsertedTree
end

assert(treeTemplate and treeTemplate:IsA("Model"), "SnowPineTree template was not found. Insert the Creator Store tree first.")

local foliageFolder = root:FindFirstChild(FOLIAGE_FOLDER_NAME)
if foliageFolder then
    foliageFolder:Destroy()
end
foliageFolder = Instance.new("Folder")
foliageFolder.Name = FOLIAGE_FOLDER_NAME
foliageFolder.Parent = root

local giantFolder = ensureFolder(foliageFolder, "GiantTrees")
local smallFolder = ensureFolder(foliageFolder, "SmallTrees")

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {foliageFolder, templateFolder}
raycastParams.IgnoreWater = true

type Candidate = {
    position: Vector3,
    normal: Vector3,
    height: number,
}

local candidates: {Candidate} = {}
for _ = 1, 900 do
    local angle = rng:NextNumber(0, math.pi * 2)
    local radial = math.sqrt(rng:NextNumber()) * radius * 0.9
    local x = math.cos(angle) * radial
    local z = math.sin(angle) * radial
    local origin = Vector3.new(x, 900, z)
    local result = Workspace:Raycast(origin, Vector3.new(0, -1800, 0), raycastParams)
    if result and result.Material ~= Enum.Material.Water and result.Position.Y > -220 then
        if result.Normal.Y > 0.8 then
            table.insert(candidates, {
                position = result.Position,
                normal = result.Normal,
                height = result.Position.Y,
            })
        end
    end
end

table.sort(candidates, function(a, b)
    return a.height < b.height
end)

assert(#candidates > 0, "No foliage candidates were found on the terrain.")

local function getSlice(maxPercent: number): {Candidate}
    local sliceCount = math.max(1, math.floor(#candidates * maxPercent))
    local slice = table.create(sliceCount)
    for index = 1, sliceCount do
        slice[index] = candidates[index]
    end
    return slice
end

local giantCandidates = getSlice(0.72)
local smallCandidates = getSlice(0.88)
local occupiedPositions: {Vector3} = {}

local function isFarEnough(position: Vector3, minimumDistance: number): boolean
    for _, occupied in ipairs(occupiedPositions) do
        if (Vector3.new(occupied.X, 0, occupied.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude < minimumDistance then
            return false
        end
    end
    return true
end

local function placeTree(targetFolder: Folder, candidate: Candidate, scale: number, minimumDistance: number)
    if not isFarEnough(candidate.position, minimumDistance) then
        return false
    end

    local clone = treeTemplate:Clone()
    clone.Parent = targetFolder
    clone:ScaleTo(scale)
    local _, size = clone:GetBoundingBox()
    local yaw = rng:NextNumber(0, math.pi * 2)
    local tilt = math.rad(rng:NextNumber(-3, 3))
    local pivot = CFrame.new(candidate.position + Vector3.new(0, size.Y * 0.5, 0))
        * CFrame.Angles(tilt, yaw, 0)
    clone:PivotTo(pivot)

    table.insert(occupiedPositions, candidate.position)
    return true
end

local function populate(targetFolder: Folder, sourceCandidates: {Candidate}, targetCount: number, scaleMin: number, scaleMax: number, minimumDistance: number)
    local placed = 0
    local attempts = 0
    while placed < targetCount and attempts < (#sourceCandidates * 5) do
        attempts += 1
        local candidate = sourceCandidates[rng:NextInteger(1, #sourceCandidates)]
        if placeTree(targetFolder, candidate, rng:NextNumber(scaleMin, scaleMax), minimumDistance) then
            placed += 1
        end
    end
    return placed
end

local giantPlaced = populate(giantFolder, giantCandidates, 70, 1.8, 3.6, 34)
local smallPlaced = populate(smallFolder, smallCandidates, 42, 0.75, 1.35, 18)
local metadata = resolveMarketplaceMetadata(TREE_QUERY)
local placedCount = giantPlaced + smallPlaced
local usagePayload = {
    {
        asset_role = "tree_foliage",
        inserted_model_name = TREE_MODEL_NAME,
        query = TREE_QUERY,
        placement_count = placedCount,
    },
}

if metadata then
    usagePayload[1].identification_number = metadata.asset_id
    usagePayload[1].marketplace_name = metadata.marketplace_name
    usagePayload[1].asset_id = metadata.asset_id
    usagePayload[1].asset_version_id = metadata.asset_version_id
    usagePayload[1].creator_name = metadata.creator_name
    usagePayload[1].library_url = metadata.library_url
end

Workspace:SetAttribute("PromptWorldCreatorStoreTreeAsset", TREE_MODEL_NAME)
Workspace:SetAttribute("PromptWorldCreatorStoreTreeCount", placedCount)
Workspace:SetAttribute("PromptWorldCreatorStoreAssetCount", #usagePayload)
Workspace:SetAttribute("PromptWorldCreatorStorePlacedInstanceCount", placedCount)
Workspace:SetAttribute("PromptWorldCreatorStoreAssetUsage", HttpService:JSONEncode(usagePayload))

print(string.format("Creator Store snow foliage placed: giant=%d small=%d asset=%s", giantPlaced, smallPlaced, TREE_MODEL_NAME))
