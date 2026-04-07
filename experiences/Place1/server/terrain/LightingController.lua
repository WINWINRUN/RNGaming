local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LightingController = {}

local function ensureChild(parent, className, name)
    local child = parent:FindFirstChild(name)
    if child and child.ClassName == className then
        return child
    end
    if child then
        child:Destroy()
    end
    child = Instance.new(className)
    child.Name = name
    child.Parent = parent
    return child
end

local function colorFromRGB(rgb)
    return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function trySet(target, propertyName, value)
    local ok = pcall(function()
        target[propertyName] = value
    end)
    return ok
end

function LightingController.apply(profile)
    local settings = profile.Lighting
    trySet(Lighting, "Technology", Enum.Technology.Future)
    trySet(Lighting, "ClockTime", settings.ClockTime)
    trySet(Lighting, "Brightness", settings.Brightness)
    trySet(Lighting, "ExposureCompensation", settings.ExposureCompensation)
    trySet(Lighting, "Ambient", colorFromRGB(settings.AmbientRGB))
    trySet(Lighting, "OutdoorAmbient", colorFromRGB(settings.OutdoorAmbientRGB))
    trySet(Lighting, "EnvironmentDiffuseScale", settings.EnvironmentDiffuseScale)
    trySet(Lighting, "EnvironmentSpecularScale", settings.EnvironmentSpecularScale)
    trySet(Lighting, "GlobalShadows", true)

    local atmosphere = ensureChild(Lighting, "Atmosphere", "GeneratedAtmosphere")
    trySet(atmosphere, "Color", colorFromRGB(settings.AtmosphereColorRGB))
    trySet(atmosphere, "Decay", colorFromRGB(settings.AtmosphereDecayRGB))
    trySet(atmosphere, "Density", settings.AtmosphereDensity)
    trySet(atmosphere, "Offset", settings.AtmosphereOffset)
    trySet(atmosphere, "Glare", settings.AtmosphereGlare)
    trySet(atmosphere, "Haze", settings.AtmosphereHaze)

    local colorCorrection = ensureChild(Lighting, "ColorCorrectionEffect", "GeneratedColorCorrection")
    trySet(colorCorrection, "Brightness", settings.ColorCorrectionBrightness)
    trySet(colorCorrection, "Contrast", settings.ColorCorrectionContrast)
    trySet(colorCorrection, "Saturation", settings.ColorCorrectionSaturation)
    trySet(colorCorrection, "TintColor", colorFromRGB(settings.ColorCorrectionTintRGB))

    local terrain = Workspace.Terrain
    local clouds = terrain:FindFirstChild("GeneratedClouds")
    if clouds and not clouds:IsA("Clouds") then
        clouds:Destroy()
        clouds = nil
    end
    if not clouds then
        clouds = Instance.new("Clouds")
        clouds.Name = "GeneratedClouds"
        clouds.Parent = terrain
    end
    trySet(clouds, "Cover", settings.CloudCover)
    trySet(clouds, "Density", settings.CloudDensity)
    trySet(clouds, "Color", colorFromRGB(settings.CloudColorRGB))
end

return LightingController
