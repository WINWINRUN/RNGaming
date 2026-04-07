local Workspace = game:GetService("Workspace")

local function reportTerrain()
    local profile = Workspace:GetAttribute("RNGamingTerrainProfile")
    local seed = Workspace:GetAttribute("RNGamingTerrainSeed")
    if profile and seed then
        print(string.format("[RNGaming] Active terrain profile: %s (seed %s)", profile, tostring(seed)))
    end
end

Workspace:GetAttributeChangedSignal("RNGamingTerrainProfile"):Connect(reportTerrain)
reportTerrain()
