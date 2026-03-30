
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local testFolder = ServerStorage:WaitForChild("TestWorldModels")
local previewFolder = Workspace:FindFirstChild("CommandBarTestWorldPreview")

if previewFolder then
    previewFolder:Destroy()
end

previewFolder = Instance.new("Folder")
previewFolder.Name = "CommandBarTestWorldPreview"
previewFolder.Parent = Workspace

local syncedFolder = testFolder:FindFirstChild("SyncedModels")
if syncedFolder and #syncedFolder:GetChildren() > 0 then
    local worldModel = syncedFolder:FindFirstChild("SkyIslandHub") or syncedFolder:FindFirstChild("SkyIslandHubPreview")
    if worldModel then
        worldModel:Clone().Parent = previewFolder
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
        end
    end
else
    local buildModule = require(testFolder:WaitForChild("BuildTestFolder"))
    local generatedFolder = buildModule.build(testFolder)

    for _, child in ipairs(generatedFolder:GetChildren()) do
        child:Clone().Parent = previewFolder
    end
end

print("Spawned CommandBarTestWorldPreview in Workspace")
