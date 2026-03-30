
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local TOOLBAR_ICON = "rbxassetid://14978048121"
local DEFAULT_FOLDER_NAME = "TestWorldPreview"

local toolbar = plugin:CreateToolbar("RNGaming")
local spawnButton = toolbar:CreateButton(
    "SpawnTestModels",
    "Clone the generated test models into Workspace for previewing.",
    TOOLBAR_ICON,
    "Spawn Test Models"
)
local clearButton = toolbar:CreateButton(
    "ClearTestModels",
    "Remove the Workspace preview folder created by the test model plugin.",
    TOOLBAR_ICON,
    "Clear Test Preview"
)

spawnButton.ClickableWhenViewportHidden = true
clearButton.ClickableWhenViewportHidden = true

local function getConfig()
    local configModule = ReplicatedStorage:FindFirstChild("Config")
    if configModule and configModule:IsA("ModuleScript") then
        local ok, config = pcall(require, configModule)
        if ok and type(config) == "table" then
            return config
        end
    end

    return {}
end

local function getPreviewFolderName()
    local config = getConfig()
    local groupName = config.GroupName or "RNGaming"
    return groupName .. "_" .. DEFAULT_FOLDER_NAME
end

local function getTestFolder()
    local testFolder = ServerStorage:FindFirstChild("TestWorldModels")
    if not testFolder then
        error("TestWorldModels was not found in ServerStorage. Connect Rojo and sync the project first.")
    end

    return testFolder
end

local function getBuildModule(testFolder)
    testFolder = testFolder or getTestFolder()

    local buildModule = testFolder:FindFirstChild("BuildTestFolder")
    if not buildModule or not buildModule:IsA("ModuleScript") then
        error("BuildTestFolder module is missing from ServerStorage/TestWorldModels.")
    end

    return buildModule
end

local function clearPreview()
    local previewFolder = Workspace:FindFirstChild(getPreviewFolderName())
    if previewFolder then
        previewFolder:Destroy()
        ChangeHistoryService:SetWaypoint("Clear Test World Preview")
    end
end

local function cloneChildren(source, target)
    for _, child in ipairs(source:GetChildren()) do
        child:Clone().Parent = target
    end
end

local function spawnSyncedModels(testFolder, previewFolder)
    local syncedFolder = testFolder:FindFirstChild("SyncedModels")
    if not syncedFolder then
        return false
    end

    local placedAny = false
    local worldModel = syncedFolder:FindFirstChild("SkyIslandHub") or syncedFolder:FindFirstChild("SkyIslandHubPreview")
    if worldModel then
        worldModel:Clone().Parent = previewFolder
        placedAny = true
    end

    local galleryFolder = Instance.new("Folder")
    galleryFolder.Name = "SyncedModelGallery"
    galleryFolder.Parent = previewFolder

    local nextX = -144
    for _, child in ipairs(syncedFolder:GetChildren()) do
        if child ~= worldModel and child.Name ~= "SkyIslandHubPreview" then
            local clone = child:Clone()
            clone.Parent = galleryFolder

            if clone:IsA("Model") then
                clone:PivotTo(CFrame.new(nextX, 42, 210))
            elseif clone:IsA("BasePart") then
                clone.CFrame = CFrame.new(nextX, 42, 210)
            end

            nextX = nextX + 72
            placedAny = true
        end
    end

    if not placedAny then
        galleryFolder:Destroy()
    end

    return placedAny
end

local function spawnRuntimeModels(testFolder, previewFolder)
    local buildModule = getBuildModule(testFolder)
    local ok, builder = pcall(require, buildModule)
    if not ok then
        error(builder)
    end

    local generatedFolder = builder.build(testFolder)
    cloneChildren(generatedFolder, previewFolder)
end

local function spawnPreview()
    local testFolder = getTestFolder()
    clearPreview()

    local previewFolder = Instance.new("Folder")
    previewFolder.Name = getPreviewFolderName()
    previewFolder.Parent = Workspace

    local spawnedSynced = spawnSyncedModels(testFolder, previewFolder)
    if not spawnedSynced then
        spawnRuntimeModels(testFolder, previewFolder)
    end

    local config = getConfig()
    if config.GroupId then
        previewFolder:SetAttribute("GroupId", config.GroupId)
    end
    if config.GroupName then
        previewFolder:SetAttribute("GroupName", config.GroupName)
    end

    Selection:Set({previewFolder})
    ChangeHistoryService:SetWaypoint("Spawn Test World Preview")
end

spawnButton.Click:Connect(function()
    local ok, result = pcall(spawnPreview)
    if not ok then
        warn("[SpawnTestModels.plugin] " .. tostring(result))
    end
end)

clearButton.Click:Connect(function()
    local ok, result = pcall(clearPreview)
    if not ok then
        warn("[SpawnTestModels.plugin] " .. tostring(result))
    end
end)
