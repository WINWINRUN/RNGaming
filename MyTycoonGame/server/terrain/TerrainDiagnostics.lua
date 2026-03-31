local Workspace = game:GetService("Workspace")

local TerrainDiagnostics = {}

local function getOrCreateFolder()
    local folder = Workspace:FindFirstChild("GeneratedTerrainInfo")
    if folder then
        folder:Destroy()
    end
    folder = Instance.new("Folder")
    folder.Name = "GeneratedTerrainInfo"
    folder.Parent = Workspace
    return folder
end

local function addValue(parent, className, name, value)
    local instance = Instance.new(className)
    instance.Name = name
    instance.Value = value
    instance.Parent = parent
    return instance
end

function TerrainDiagnostics.publish(summary)
    Workspace:SetAttribute("RNGamingTerrainProfile", summary.ProfileName)
    Workspace:SetAttribute("RNGamingTerrainSeed", summary.Seed)
    Workspace:SetAttribute("RNGamingTerrainPropCount", summary.PropCount or 0)

    local folder = getOrCreateFolder()
    addValue(folder, "StringValue", "ProfileName", summary.ProfileName)
    addValue(folder, "IntValue", "Seed", summary.Seed)
    addValue(folder, "IntValue", "ColumnCount", summary.ColumnCount or 0)
    addValue(folder, "IntValue", "IslandCount", summary.IslandCount or 0)
    addValue(folder, "IntValue", "PropCount", summary.PropCount or 0)
    addValue(folder, "NumberValue", "MinimumHeight", summary.MinimumHeight or 0)
    addValue(folder, "NumberValue", "MaximumHeight", summary.MaximumHeight or 0)
    addValue(folder, "NumberValue", "WaterCoverage", summary.WaterCoverage or 0)
    addValue(folder, "NumberValue", "SpawnHeight", summary.SpawnHeight or 0)
end

function TerrainDiagnostics.clear()
    Workspace:SetAttribute("RNGamingTerrainProfile", nil)
    Workspace:SetAttribute("RNGamingTerrainSeed", nil)
    Workspace:SetAttribute("RNGamingTerrainPropCount", nil)
    local folder = Workspace:FindFirstChild("GeneratedTerrainInfo")
    if folder then
        folder:Destroy()
    end
end

return TerrainDiagnostics
