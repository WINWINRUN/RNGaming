local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TerrainBootstrap = require(ServerScriptService:WaitForChild("TerrainBootstrap"))
local TycoonService = require(ServerScriptService:WaitForChild("TycoonService"))

TerrainBootstrap.generateInStudio(nil, nil)

local result = TycoonService.prepareInStudio(true)
print(string.format(
    "[RNGaming] Prepared Among Us tycoon sandbox with %d plots at %s",
    result and result.PlotCount or 0,
    result and tostring(result.Center) or "nil"
))
