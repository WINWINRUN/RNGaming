local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local ExperienceGuard = require(ReplicatedStorage:WaitForChild("ExperienceGuard"))
local TerrainBootstrap = require(ServerScriptService:WaitForChild("TerrainBootstrap"))

if not ExperienceGuard.canRunHere(Config) then
    warn("[RNGaming] Terrain generation skipped because this place is not allowed by Config.lua")
    return
end

local ok, result = pcall(function()
    return TerrainBootstrap.start()
end)

if not ok then
    warn("[RNGaming] Terrain bootstrap failed:", result)
    return
end

if result then
    print(string.format("[RNGaming] Terrain ready with profile %s and seed %s", result.ProfileName, tostring(result.Seed)))
else
    print("[RNGaming] Terrain scaffold loaded. AutoGenerateOnServerStart is disabled.")
end
