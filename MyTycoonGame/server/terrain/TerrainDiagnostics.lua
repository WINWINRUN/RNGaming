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
    Workspace:SetAttribute("RNGamingTerrainProfileKey", summary.ProfileKey)
    Workspace:SetAttribute("RNGamingTerrainVariantName", summary.VariantName)
    Workspace:SetAttribute("RNGamingTerrainSeed", summary.Seed)
    Workspace:SetAttribute("RNGamingTerrainPropCount", summary.PropCount or 0)
    Workspace:SetAttribute("RNGamingTerrainGenerationId", summary.GenerationId)
    Workspace:SetAttribute("RNGamingTerrainCenterX", summary.ManagedCenter and summary.ManagedCenter.X or nil)
    Workspace:SetAttribute("RNGamingTerrainCenterY", summary.ManagedCenter and summary.ManagedCenter.Y or nil)
    Workspace:SetAttribute("RNGamingTerrainCenterZ", summary.ManagedCenter and summary.ManagedCenter.Z or nil)
    Workspace:SetAttribute("RNGamingTerrainWorldSize", summary.WorldSize)
    Workspace:SetAttribute("RNGamingTerrainClearMinY", summary.ClearMinY)
    Workspace:SetAttribute("RNGamingTerrainClearMaxY", summary.ClearMaxY)

    local folder = getOrCreateFolder()
    addValue(folder, "StringValue", "ProfileName", summary.ProfileName)
    addValue(folder, "StringValue", "ProfileKey", summary.ProfileKey or "")
    addValue(folder, "StringValue", "VariantName", summary.VariantName or "")
    addValue(folder, "StringValue", "BaseProfileName", summary.BaseProfileName or "")
    addValue(folder, "IntValue", "Seed", summary.Seed)
    addValue(folder, "StringValue", "GenerationId", summary.GenerationId or "")
    addValue(folder, "IntValue", "ColumnCount", summary.ColumnCount or 0)
    addValue(folder, "IntValue", "IslandCount", summary.IslandCount or 0)
    addValue(folder, "IntValue", "PropCount", summary.PropCount or 0)
    addValue(folder, "NumberValue", "CenterX", summary.ManagedCenter and summary.ManagedCenter.X or 0)
    addValue(folder, "NumberValue", "CenterY", summary.ManagedCenter and summary.ManagedCenter.Y or 0)
    addValue(folder, "NumberValue", "CenterZ", summary.ManagedCenter and summary.ManagedCenter.Z or 0)
    addValue(folder, "NumberValue", "WorldSize", summary.WorldSize or 0)
    addValue(folder, "NumberValue", "ClearMinY", summary.ClearMinY or 0)
    addValue(folder, "NumberValue", "ClearMaxY", summary.ClearMaxY or 0)
    addValue(folder, "NumberValue", "MinimumHeight", summary.MinimumHeight or 0)
    addValue(folder, "NumberValue", "MaximumHeight", summary.MaximumHeight or 0)
    addValue(folder, "NumberValue", "WaterCoverage", summary.WaterCoverage or 0)
    addValue(folder, "NumberValue", "SpawnHeight", summary.SpawnHeight or 0)
end

function TerrainDiagnostics.clear()
    Workspace:SetAttribute("RNGamingTerrainProfile", nil)
    Workspace:SetAttribute("RNGamingTerrainProfileKey", nil)
    Workspace:SetAttribute("RNGamingTerrainVariantName", nil)
    Workspace:SetAttribute("RNGamingTerrainSeed", nil)
    Workspace:SetAttribute("RNGamingTerrainPropCount", nil)
    Workspace:SetAttribute("RNGamingTerrainGenerationId", nil)
    Workspace:SetAttribute("RNGamingTerrainCenterX", nil)
    Workspace:SetAttribute("RNGamingTerrainCenterY", nil)
    Workspace:SetAttribute("RNGamingTerrainCenterZ", nil)
    Workspace:SetAttribute("RNGamingTerrainWorldSize", nil)
    Workspace:SetAttribute("RNGamingTerrainClearMinY", nil)
    Workspace:SetAttribute("RNGamingTerrainClearMaxY", nil)
    local folder = Workspace:FindFirstChild("GeneratedTerrainInfo")
    if folder then
        folder:Destroy()
    end
end

return TerrainDiagnostics
