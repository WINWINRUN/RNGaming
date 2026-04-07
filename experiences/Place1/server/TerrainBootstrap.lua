local HttpService = game:GetService("HttpService")
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

local function generateFreshSeed()
    local guid = HttpService:GenerateGUID(false):gsub("%-", "")
    local head = tonumber(guid:sub(1, 8), 16)
    if head and head > 0 then
        return head
    end

    local fallback = DateTime.now().UnixTimestampMillis % 2147483000
    if fallback <= 0 then
        fallback = 515151
    end
    return fallback
end

local function resolveSeed(seed, options)
    if type(seed) == "number" then
        return math.floor(seed)
    end

    if seed == "fresh" then
        return generateFreshSeed()
    end

    local generationOptions = options or {}
    local seedMode = string.lower(tostring(
        generationOptions.SeedMode
        or Config.TerrainSeedMode
        or "Fixed"
    ))

    if seedMode == "fresh" or seedMode == "random" then
        return generateFreshSeed()
    end

    return Config.DefaultSeed
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
    local generationOptions = options or {}
    local resolvedSeed = resolveSeed(seed, generationOptions)
    local modeLabel = generationOptions.Mode or "Unknown"

    assertGenerationAllowed(modeLabel)

    local terrainSummary = TerrainGenerator.generate(profile, resolvedSeed, Config, generationOptions)
    local environmentSummary = EnvironmentGenerator.generate(profile, resolvedSeed, Config, generationOptions)
    LightingController.apply(profile)
    local spawn = SpawnPlanner.place(profile)
    local summary = {
        ProfileName = profile.Name,
        Seed = resolvedSeed,
        GenerationId = HttpService:GenerateGUID(false),
        ManagedCenter = {
            X = profile.ManagedCenter.X,
            Y = profile.ManagedCenter.Y,
            Z = profile.ManagedCenter.Z,
        },
        WorldSize = profile.WorldSize,
        ClearMinY = profile.ClearMinY,
        ClearMaxY = profile.ClearMaxY,
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

    return TerrainBootstrap.generate(Config.DefaultTerrainProfile, nil, {
        Mode = "ServerStart",
    })
end

function TerrainBootstrap.generateInStudio(profileName, seed)
    return TerrainBootstrap.generate(profileName, seed, {
        Mode = "Studio",
    })
end

return TerrainBootstrap
