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

local function generateFreshSeed()
    local guid = HttpService:GenerateGUID(false):gsub("%-", "")
    local head = tonumber(guid:sub(1, 8), 16)
    if head and head > 0 then
        local normalized = head % 2147483000
        if normalized > 0 then
            return normalized
        end
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

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, item in pairs(value) do
        copy[key] = deepCopy(item)
    end
    return copy
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function roundToStep(value, step)
    if type(step) ~= "number" or step <= 0 then
        return math.floor(value + 0.5)
    end

    return math.floor((value / step) + 0.5) * step
end

local function getProfileNames()
    local names = {}
    for name in pairs(TerrainProfiles.Profiles) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

local function chooseProfileName(profileName, seed, options)
    local generationOptions = options or {}
    local requestedName = generationOptions.ProfileName or profileName or Config.DefaultTerrainProfile
    local profileMode = string.lower(tostring(
        generationOptions.ProfileMode
        or Config.TerrainProfileMode
        or "Fixed"
    ))

    if TerrainProfiles.Profiles[requestedName] then
        return requestedName
    end

    if requestedName == "Random" or requestedName == "Any" then
        profileMode = "random"
    end

    if profileMode == "random" or profileMode == "shuffle" or profileMode == "mixed" then
        local names = getProfileNames()
        local rng = Random.new(seed + 907)
        return names[rng:NextInteger(1, #names)]
    end

    if TerrainProfiles.Profiles[Config.DefaultTerrainProfile] then
        return Config.DefaultTerrainProfile
    end

    return getProfileNames()[1]
end

local VARIANT_PREFIXES = {
    "Drift",
    "Signal",
    "Echo",
    "Shatter",
    "Nova",
    "Pulse",
    "Glass",
    "Orbit",
    "Hollow",
    "Vector",
}

local VARIANT_SUFFIXES = {
    "Front",
    "Basin",
    "Reach",
    "Shelf",
    "Ridge",
    "Crown",
    "Sprawl",
    "Circuit",
    "Delta",
    "Spine",
}

local function chooseVariantName(rng)
    return string.format(
        "%s %s",
        VARIANT_PREFIXES[rng:NextInteger(1, #VARIANT_PREFIXES)],
        VARIANT_SUFFIXES[rng:NextInteger(1, #VARIANT_SUFFIXES)]
    )
end

local function applyCommonProfileRemix(profile, rng)
    local cellSize = profile.CellSize or 8
    local reservedRadius = math.max(0, tonumber(Config.TerrainReservedFlatRadius) or 0)
    local reservedBlend = math.max(0, tonumber(Config.TerrainReservedBlendRadius) or 0)
    local minimumWorldSize = math.max(profile.WorldSize, ((reservedRadius + reservedBlend) * 2) + (cellSize * 12))

    profile.WorldSize = math.max(roundToStep(profile.WorldSize * rng:NextNumber(0.94, 1.18), cellSize), minimumWorldSize)
    profile.ClearMinY = math.min(profile.ClearMinY, profile.BaseY - 72)
    profile.ClearMaxY = math.max(profile.ClearMaxY, profile.Spawn.Height + 220)

    if profile.Props then
        profile.Props.ScatterStride = clamp(
            roundToStep((profile.Props.ScatterStride or 20) * rng:NextNumber(0.85, 1.15), 1),
            14,
            30
        )
        profile.Props.TreeDensity = clamp((profile.Props.TreeDensity or 0) * rng:NextNumber(0.65, 1.45), 0, 0.45)
        profile.Props.BushDensity = clamp((profile.Props.BushDensity or 0) * rng:NextNumber(0.65, 1.5), 0, 0.28)
        profile.Props.RockDensity = clamp((profile.Props.RockDensity or 0) * rng:NextNumber(0.8, 1.35), 0.02, 0.3)
        profile.Props.LandmarkDensity = clamp((profile.Props.LandmarkDensity or 0.02) * rng:NextNumber(0.8, 1.45), 0.01, 0.08)
    end
end

local function applyHeightmapRemix(profile, rng)
    local cellSize = profile.CellSize or 8

    profile.BaseHeight = roundToStep(profile.BaseHeight * rng:NextNumber(0.82, 1.2), 1)
    profile.HeightAmplitude = clamp(roundToStep(profile.HeightAmplitude * rng:NextNumber(0.7, 1.4), 1), 42, 148)
    profile.DetailAmplitude = clamp(roundToStep(profile.DetailAmplitude * rng:NextNumber(0.75, 1.5), 1), 8, 40)
    profile.RidgeAmplitude = clamp(roundToStep(profile.RidgeAmplitude * rng:NextNumber(0.65, 1.6), 1), 10, 54)

    if profile.WaterLevel and profile.WaterLevel > -900 then
        profile.WaterLevel = roundToStep(profile.WaterLevel + rng:NextInteger(-28, 44), 1)
    end

    if profile.SnowLine and profile.SnowLine < 900 then
        profile.SnowLine = roundToStep(profile.SnowLine + rng:NextInteger(-18, 28), 1)
    end

    if profile.Noise then
        profile.Noise.ContinentalScale = clamp(roundToStep(profile.Noise.ContinentalScale * rng:NextNumber(0.72, 1.28), cellSize), 136, 520)
        profile.Noise.DetailScale = clamp(roundToStep(profile.Noise.DetailScale * rng:NextNumber(0.72, 1.32), cellSize), 48, 164)
        profile.Noise.RidgeScale = clamp(roundToStep(profile.Noise.RidgeScale * rng:NextNumber(0.74, 1.36), cellSize), 88, 260)
        profile.Noise.MoistureScale = clamp(roundToStep(profile.Noise.MoistureScale * rng:NextNumber(0.76, 1.34), cellSize), 140, 320)
        profile.Noise.Lacunarity = clamp(profile.Noise.Lacunarity * rng:NextNumber(0.92, 1.08), 1.82, 2.3)
        profile.Noise.Persistence = clamp(profile.Noise.Persistence * rng:NextNumber(0.9, 1.1), 0.38, 0.62)
    end

    if profile.Edge then
        profile.Edge.InnerRadius = clamp(roundToStep(profile.Edge.InnerRadius + rng:NextInteger(-34, 28), cellSize), profile.Spawn.FlattenRadius + 96, profile.WorldSize * 0.48)
        profile.Edge.OuterRadius = clamp(roundToStep(profile.Edge.OuterRadius + rng:NextInteger(-16, 54), cellSize), profile.Edge.InnerRadius + 72, profile.WorldSize * 0.58)
        profile.Edge.Drop = clamp(roundToStep(profile.Edge.Drop + rng:NextInteger(-24, 42), 1), 108, 260)
    end

    if profile.River then
        local allowRiver = profile.Name ~= "FrozenDesertMoon" and profile.Name ~= "SpaceWaterfallCliffs"
        if allowRiver then
            profile.River.Enabled = rng:NextNumber() >= 0.32
            profile.River.Scale = clamp(roundToStep(profile.River.Scale * rng:NextNumber(0.82, 1.26), cellSize), 88, 260)
            profile.River.Width = clamp(profile.River.Width * rng:NextNumber(0.75, 1.35), 0.06, 0.2)
            profile.River.Depth = clamp(roundToStep(profile.River.Depth * rng:NextNumber(0.72, 1.4), 1), 6, 28)
        end
    end

    if profile.Spawn then
        profile.Spawn.Height = clamp(roundToStep(profile.Spawn.Height + rng:NextInteger(-12, 14), 1), profile.BaseY + 42, profile.BaseHeight + profile.HeightAmplitude + 26)
        profile.Spawn.InnerBlendRadius = clamp(roundToStep(profile.Spawn.InnerBlendRadius + rng:NextInteger(-8, 10), 1), 20, 56)
        profile.Spawn.FlattenRadius = clamp(roundToStep(profile.Spawn.FlattenRadius + rng:NextInteger(-10, 16), 1), profile.Spawn.InnerBlendRadius + 24, 128)
    end
end

local function applySkyIslandRemix(profile, rng)
    local cellSize = profile.CellSize or 8

    profile.BaseHeight = roundToStep(profile.BaseHeight * rng:NextNumber(0.9, 1.18), 1)
    profile.IslandCount = clamp((profile.IslandCount or 6) + rng:NextInteger(-2, 2), 4, 10)
    profile.RingRadius = clamp(roundToStep((profile.RingRadius or 180) * rng:NextNumber(0.82, 1.18), cellSize), 148, 320)
    profile.RingJitter = clamp(roundToStep((profile.RingJitter or 40) * rng:NextNumber(0.78, 1.28), 1), 18, 84)
    profile.IslandRadius = clamp(roundToStep((profile.IslandRadius or 52) * rng:NextNumber(0.76, 1.24), 1), 34, 96)
    profile.IslandRadiusJitter = clamp(roundToStep((profile.IslandRadiusJitter or 14) * rng:NextNumber(0.75, 1.35), 1), 8, 30)
    profile.IslandDepth = clamp(roundToStep((profile.IslandDepth or 100) * rng:NextNumber(0.82, 1.24), 1), 60, 220)
    profile.AltitudeJitter = clamp(roundToStep((profile.AltitudeJitter or 24) * rng:NextNumber(0.8, 1.36), 1), 12, 52)
    profile.TopThickness = clamp(roundToStep((profile.TopThickness or 18) * rng:NextNumber(0.84, 1.28), 1), 14, 40)
    profile.TopBulge = clamp(roundToStep((profile.TopBulge or 10) * rng:NextNumber(0.8, 1.4), 1), 6, 26)

    if profile.PrimaryIslandRadius then
        profile.PrimaryIslandRadius = clamp(roundToStep(profile.PrimaryIslandRadius * rng:NextNumber(0.86, 1.16), 1), 84, 172)
    end
    if profile.PrimaryIslandAltitude then
        profile.PrimaryIslandAltitude = clamp(roundToStep(profile.PrimaryIslandAltitude + rng:NextInteger(-18, 28), 1), 180, 300)
    end

    if profile.Waterfall then
        profile.Waterfall.Enabled = rng:NextNumber() >= 0.22
        profile.Waterfall.EdgeOffset = clamp(roundToStep((profile.Waterfall.EdgeOffset or 78) * rng:NextNumber(0.84, 1.18), 1), 52, 120)
        profile.Waterfall.Height = clamp(roundToStep((profile.Waterfall.Height or 152) * rng:NextNumber(0.84, 1.22), 1), 96, 220)
        profile.Waterfall.Width = clamp(roundToStep((profile.Waterfall.Width or 22) * rng:NextNumber(0.72, 1.34), 1), 12, 34)
        profile.Waterfall.Thickness = clamp(roundToStep((profile.Waterfall.Thickness or 5) * rng:NextNumber(0.8, 1.28), 1), 3, 10)
        profile.Waterfall.MistRadius = clamp(roundToStep((profile.Waterfall.MistRadius or 18) * rng:NextNumber(0.84, 1.3), 1), 10, 28)
    end

    if profile.Spawn then
        profile.Spawn.Height = clamp(roundToStep(profile.Spawn.Height + rng:NextInteger(-10, 16), 1), profile.BaseHeight - 24, profile.BaseHeight + 40)
        profile.Spawn.InnerBlendRadius = clamp(roundToStep(profile.Spawn.InnerBlendRadius + rng:NextInteger(-6, 10), 1), 20, 44)
        profile.Spawn.FlattenRadius = clamp(roundToStep(profile.Spawn.FlattenRadius + rng:NextInteger(-8, 14), 1), profile.Spawn.InnerBlendRadius + 22, 104)
    end
end

local function resolveProfile(profileName, seed, options)
    local baseProfileName = chooseProfileName(profileName, seed, options)
    local profile = TerrainProfiles.getProfile(baseProfileName)
    local generationOptions = options or {}
    local variantMode = string.lower(tostring(
        generationOptions.VariantMode
        or Config.TerrainVariantMode
        or "None"
    ))

    profile.Name = profile.Name or baseProfileName

    if variantMode ~= "remix" and variantMode ~= "random" then
        profile.RuntimeBaseProfileName = baseProfileName
        profile.RuntimeVariantName = "Default Layout"
        profile.RuntimeProfileLabel = profile.DisplayName or profile.Name
        return profile
    end

    local remix = deepCopy(profile)
    local rng = Random.new(seed + 1701)

    applyCommonProfileRemix(remix, rng)
    if remix.Kind == "SkyIslands" then
        applySkyIslandRemix(remix, rng)
    else
        applyHeightmapRemix(remix, rng)
    end

    remix.RuntimeBaseProfileName = baseProfileName
    remix.RuntimeVariantName = chooseVariantName(rng)
    remix.RuntimeProfileLabel = string.format("%s - %s", remix.DisplayName or remix.Name, remix.RuntimeVariantName)
    return remix
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
    local generationOptions = options or {}
    local resolvedSeed = resolveSeed(seed, generationOptions)
    local profile = resolveProfile(profileName, resolvedSeed, generationOptions)
    local modeLabel = generationOptions.Mode or "Unknown"

    assertGenerationAllowed(modeLabel)

    local terrainSummary = TerrainGenerator.generate(profile, resolvedSeed, Config, generationOptions)
    local environmentSummary = EnvironmentGenerator.generate(profile, resolvedSeed, Config, generationOptions)
    LightingController.apply(profile)
    local spawn = SpawnPlanner.place(profile)
    local summary = {
        ProfileName = profile.RuntimeProfileLabel or profile.DisplayName or profile.Name,
        ProfileKey = profile.Name,
        VariantName = profile.RuntimeVariantName,
        BaseProfileName = profile.RuntimeBaseProfileName or profile.Name,
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
    local profile = TerrainProfiles.getProfile(profileName or Config.DefaultTerrainProfile)
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
