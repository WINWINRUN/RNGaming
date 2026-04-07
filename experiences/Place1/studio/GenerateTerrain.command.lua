local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local TerrainBootstrap = require(ServerScriptService:WaitForChild("TerrainBootstrap"))

local ok, result = pcall(function()
    local profileName = Config.DefaultTerrainProfile
    local seed = nil
    return TerrainBootstrap.generateInStudio(profileName, seed)
end)

if ok then
    print(string.format(
        "[RNGaming] Generated terrain profile %s with seed %s. Props: %s",
        result.ProfileName,
        tostring(result.Seed),
        tostring(result.PropCount)
    ))
else
    warn(result)
end
