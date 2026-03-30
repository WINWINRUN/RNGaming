
local ModelLibrary = require(script.Parent:WaitForChild("ModelLibrary"))

local BuildTestFolder = {}

local SAMPLE_MODELS = {
    {builder = "createFloatingPine", position = Vector3.new(0, 0, 0)},
    {builder = "createCrystalCluster", position = Vector3.new(48, 0, 0)},
    {builder = "createStoneArch", position = Vector3.new(106, 0, 0)},
    {builder = "createMarketStand", position = Vector3.new(170, 0, 0)},
    {builder = "createCloudPad", position = Vector3.new(232, 0, 0)},
}

function BuildTestFolder.build(parent)
    local generatedFolder = parent:FindFirstChild("GeneratedModels")
    if generatedFolder then
        generatedFolder:Destroy()
    end

    generatedFolder = Instance.new("Folder")
    generatedFolder.Name = "GeneratedModels"
    generatedFolder.Parent = parent

    for _, entry in ipairs(SAMPLE_MODELS) do
        local builder = ModelLibrary[entry.builder]
        if builder then
            builder(generatedFolder, entry.position)
        end
    end

    return generatedFolder
end

return BuildTestFolder
