local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local ExperienceGuard = require(ReplicatedStorage:WaitForChild("ExperienceGuard"))
local TerrainProfiles = require(ReplicatedStorage:WaitForChild("TerrainProfiles"))

local terrainFolder = ServerScriptService:WaitForChild("terrain")
local TerrainGenerator = require(terrainFolder:WaitForChild("TerrainGenerator"))
local EnvironmentGenerator = require(terrainFolder:WaitForChild("EnvironmentGenerator"))
local LightingController = require(terrainFolder:WaitForChild("LightingController"))
local SpawnPlanner = require(terrainFolder:WaitForChild("SpawnPlanner"))
local TerrainDiagnostics = require(terrainFolder:WaitForChild("TerrainDiagnostics"))

local TerrainBootstrap = {}

local function resolveProfile(profileName)
    local profile = TerrainProfiles.getProfile(profileName or Config.DefaultTerrainProfile)
    profile.Name = profile.Name or profileName or Config.DefaultTerrainProfile
    return profile
end

local function resolveSeed(seed)
    if seed == nil then
        return Config.DefaultSeed
    end

    return seed
end

local function assertGenerationAllowed(modeLabel)
    if ExperienceGuard.canRunHere(Config) then
        return
    end

    error(string.format(
        "[RNGaming] %s terrain generation is blocked because this project is locked to a different place. Update AllowedPlaceIds in Config.lua or lock the project to the correct PlaceId.",
        tostring(modeLabel)
    ))
end

function TerrainBootstrap.generate(profileName, seed, options)
    local profile = resolveProfile(profileName)
    local resolvedSeed = resolveSeed(seed)
    local generationOptions = options or {}
    local modeLabel = generationOptions.Mode or "Unknown"

    assertGenerationAllowed(modeLabel)

    local terrainSummary = TerrainGenerator.generate(profile, resolvedSeed, Config, generationOptions)
    local environmentSummary = EnvironmentGenerator.generate(profile, resolvedSeed, Config, generationOptions)
    LightingController.apply(profile)
    local spawn = SpawnPlanner.place(profile)
    local summary = {
        ProfileName = profile.Name,
        Seed = resolvedSeed,
        ColumnCount = terrainSummary.ColumnCount or 0,
        IslandCount = terrainSummary.IslandCount or 0,
        MinimumHeight = terrainSummary.MinimumHeight,
        MaximumHeight = terrainSummary.MaximumHeight,
        WaterCoverage = terrainSummary.WaterCoverage or 0,
        PropCount = environmentSummary.PropCount or 0,
        SpawnHeight = spawn and spawn.Position.Y or nil,
    }

    TerrainDiagnostics.publish(summary)
    return summary
end

function TerrainBootstrap.clearManagedRegion(profileName)
    assertGenerationAllowed("Studio")
    local profile = resolveProfile(profileName)
    TerrainGenerator.clearManagedRegion(profile, Config)
    TerrainDiagnostics.clear()
end

function TerrainBootstrap.start()
    if not Config.AutoGenerateOnServerStart then
        return nil
    end

    return TerrainBootstrap.generate(Config.DefaultTerrainProfile, Config.DefaultSeed, {
        Mode = "ServerStart",
    })
end

function TerrainBootstrap.generateInStudio(profileName, seed)
    return TerrainBootstrap.generate(profileName, seed, {
        Mode = "Studio",
    })
end

return TerrainBootstrap
