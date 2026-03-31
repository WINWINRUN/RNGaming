local toolbar = plugin:CreateToolbar("RNGaming Terrain")
local generateButton = toolbar:CreateButton("Generate Terrain", "Generate the configured terrain profile inside the managed region.", "")
local randomizeButton = toolbar:CreateButton("Generate New Seed", "Generate the configured terrain profile with a new seed.", "")
local clearButton = toolbar:CreateButton("Clear Region", "Clear the managed terrain region and generated environment.", "")

local function withBootstrap(callback)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")
    local Config = require(ReplicatedStorage:WaitForChild("Config"))
    local TerrainBootstrap = require(ServerScriptService:WaitForChild("TerrainBootstrap"))
    callback(TerrainBootstrap, Config)
end

generateButton.Click:Connect(function()
    local ok, result = pcall(function()
        withBootstrap(function(TerrainBootstrap, Config)
            local summary = TerrainBootstrap.generateInStudio(Config.DefaultTerrainProfile, Config.DefaultSeed)
            print(string.format("[RNGaming] Generated %s with seed %s", summary.ProfileName, tostring(summary.Seed)))
        end)
    end)
    if not ok then
        warn("[RNGaming] Generate Terrain failed:", result)
    end
end)

randomizeButton.Click:Connect(function()
    local ok, result = pcall(function()
        withBootstrap(function(TerrainBootstrap, Config)
            local seed = math.floor(os.time() % 1000000)
            local summary = TerrainBootstrap.generateInStudio(Config.DefaultTerrainProfile, seed)
            print(string.format("[RNGaming] Generated %s with new seed %s", summary.ProfileName, tostring(summary.Seed)))
        end)
    end)
    if not ok then
        warn("[RNGaming] Generate New Seed failed:", result)
    end
end)

clearButton.Click:Connect(function()
    local ok, result = pcall(function()
        withBootstrap(function(TerrainBootstrap, Config)
            TerrainBootstrap.clearManagedRegion(Config.DefaultTerrainProfile)
            print("[RNGaming] Cleared the managed terrain region.")
        end)
    end)
    if not ok then
        warn("[RNGaming] Clear Region failed:", result)
    end
end)
