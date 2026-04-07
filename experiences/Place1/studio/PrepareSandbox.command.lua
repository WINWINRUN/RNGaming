local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local NpcShopService = require(ServerScriptService:WaitForChild("NpcShopService"))
local TerrainBootstrap = require(ServerScriptService:WaitForChild("TerrainBootstrap"))

local summary = TerrainBootstrap.generateInStudio(Config.DefaultTerrainProfile, nil)

local vendor = NpcShopService.spawnVendorInWorkspace(true)
print(string.format(
    "PreparedSandbox profile=%s seed=%s spawn=%s vendor=%s env=%s",
    tostring(summary and summary.ProfileName or Config.DefaultTerrainProfile),
    tostring(summary and summary.Seed or "nil"),
    tostring(Workspace:FindFirstChild("GeneratedSpawn") ~= nil),
    tostring(vendor ~= nil),
    tostring(summary ~= nil)
))
