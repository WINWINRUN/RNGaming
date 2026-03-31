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

function LightingController.apply(profile)
    local settings = profile.Lighting
    Lighting.Technology = Enum.Technology.Future
    Lighting.ClockTime = settings.ClockTime
    Lighting.Brightness = settings.Brightness
    Lighting.ExposureCompensation = settings.ExposureCompensation
    Lighting.Ambient = colorFromRGB(settings.AmbientRGB)
    Lighting.OutdoorAmbient = colorFromRGB(settings.OutdoorAmbientRGB)
    Lighting.EnvironmentDiffuseScale = settings.EnvironmentDiffuseScale
    Lighting.EnvironmentSpecularScale = settings.EnvironmentSpecularScale
    Lighting.GlobalShadows = true

    local atmosphere = ensureChild(Lighting, "Atmosphere", "GeneratedAtmosphere")
    atmosphere.Color = colorFromRGB(settings.AtmosphereColorRGB)
    atmosphere.Decay = colorFromRGB(settings.AtmosphereDecayRGB)
    atmosphere.Density = settings.AtmosphereDensity
    atmosphere.Offset = settings.AtmosphereOffset
    atmosphere.Glare = settings.AtmosphereGlare
    atmosphere.Haze = settings.AtmosphereHaze

    local colorCorrection = ensureChild(Lighting, "ColorCorrectionEffect", "GeneratedColorCorrection")
    colorCorrection.Brightness = settings.ColorCorrectionBrightness
    colorCorrection.Contrast = settings.ColorCorrectionContrast
    colorCorrection.Saturation = settings.ColorCorrectionSaturation
    colorCorrection.TintColor = colorFromRGB(settings.ColorCorrectionTintRGB)

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
    clouds.Cover = settings.CloudCover
    clouds.Density = settings.CloudDensity
    clouds.Color = colorFromRGB(settings.CloudColorRGB)
end

return LightingController
