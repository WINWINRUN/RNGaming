local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local TerrainProfiles = require(ReplicatedStorage:WaitForChild("TerrainProfiles"))

local terrainFolder = ServerScriptService:WaitForChild("terrain")
local TerrainGenerator = require(terrainFolder:WaitForChild("TerrainGenerator"))
local EnvironmentGenerator = require(terrainFolder:WaitForChild("EnvironmentGenerator"))
local SpawnPlanner = require(terrainFolder:WaitForChild("SpawnPlanner"))
local TerrainDiagnostics = require(terrainFolder:WaitForChild("TerrainDiagnostics"))

local profileName = "FrozenDesertMoon"
local seed = 515151
local profile = TerrainProfiles.getProfile(profileName)
profile.Name = profileName

local terrainSummary = TerrainGenerator.generate(profile, seed, Config, {
	Mode = "StudioBridge",
})
local environmentSummary = EnvironmentGenerator.generate(profile, seed, Config, {
	Mode = "StudioBridge",
})
local spawn = SpawnPlanner.place(profile)

pcall(function()
	Lighting.ClockTime = profile.Lighting.ClockTime
end)
pcall(function()
	Lighting.Brightness = profile.Lighting.Brightness
end)
pcall(function()
	Lighting.ExposureCompensation = profile.Lighting.ExposureCompensation
end)
pcall(function()
	Lighting.Ambient = Color3.fromRGB(unpack(profile.Lighting.AmbientRGB))
end)
pcall(function()
	Lighting.OutdoorAmbient = Color3.fromRGB(unpack(profile.Lighting.OutdoorAmbientRGB))
end)
pcall(function()
	Lighting.EnvironmentDiffuseScale = profile.Lighting.EnvironmentDiffuseScale
end)
pcall(function()
	Lighting.EnvironmentSpecularScale = profile.Lighting.EnvironmentSpecularScale
end)

pcall(function()
	local atmosphere = Lighting:FindFirstChild("GeneratedAtmosphere")
	if atmosphere and not atmosphere:IsA("Atmosphere") then
		atmosphere:Destroy()
		atmosphere = nil
	end
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "GeneratedAtmosphere"
		atmosphere.Parent = Lighting
	end
	atmosphere.Color = Color3.fromRGB(unpack(profile.Lighting.AtmosphereColorRGB))
	atmosphere.Decay = Color3.fromRGB(unpack(profile.Lighting.AtmosphereDecayRGB))
	atmosphere.Density = profile.Lighting.AtmosphereDensity
	atmosphere.Offset = profile.Lighting.AtmosphereOffset
	atmosphere.Glare = profile.Lighting.AtmosphereGlare
	atmosphere.Haze = profile.Lighting.AtmosphereHaze
end)

pcall(function()
	local colorCorrection = Lighting:FindFirstChild("GeneratedColorCorrection")
	if colorCorrection and not colorCorrection:IsA("ColorCorrectionEffect") then
		colorCorrection:Destroy()
		colorCorrection = nil
	end
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "GeneratedColorCorrection"
		colorCorrection.Parent = Lighting
	end
	colorCorrection.Brightness = profile.Lighting.ColorCorrectionBrightness
	colorCorrection.Contrast = profile.Lighting.ColorCorrectionContrast
	colorCorrection.Saturation = profile.Lighting.ColorCorrectionSaturation
	colorCorrection.TintColor = Color3.fromRGB(unpack(profile.Lighting.ColorCorrectionTintRGB))
end)

pcall(function()
	local clouds = Workspace.Terrain:FindFirstChild("GeneratedClouds")
	if clouds and not clouds:IsA("Clouds") then
		clouds:Destroy()
		clouds = nil
	end
	if not clouds then
		clouds = Instance.new("Clouds")
		clouds.Name = "GeneratedClouds"
		clouds.Parent = Workspace.Terrain
	end
	clouds.Cover = profile.Lighting.CloudCover
	clouds.Density = profile.Lighting.CloudDensity
	clouds.Color = Color3.fromRGB(unpack(profile.Lighting.CloudColorRGB))
end)

TerrainDiagnostics.publish({
	ProfileName = profileName,
	Seed = seed,
	ColumnCount = terrainSummary.ColumnCount or 0,
	IslandCount = terrainSummary.IslandCount or 0,
	MinimumHeight = terrainSummary.MinimumHeight,
	MaximumHeight = terrainSummary.MaximumHeight,
	WaterCoverage = terrainSummary.WaterCoverage or 0,
	PropCount = environmentSummary.PropCount or 0,
	SpawnHeight = spawn and spawn.Position.Y or 0,
})

print("GENERATED=" .. tostring(profileName))
print("SEED=" .. tostring(seed))
print("PROPS=" .. tostring(environmentSummary.PropCount or 0))
print("COLUMNS=" .. tostring(terrainSummary.ColumnCount or 0))
