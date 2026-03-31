local BiomeLibrary = {}

local BIOMES = {
    TemperateFrontier = {
        Shore = {Name = "Shore", SurfaceMaterial = Enum.Material.Sand, BodyMaterial = Enum.Material.Ground, PropStyle = "Shore"},
        Meadow = {Name = "Meadow", SurfaceMaterial = Enum.Material.Grass, BodyMaterial = Enum.Material.Ground, PropStyle = "Meadow"},
        Forest = {Name = "Forest", SurfaceMaterial = Enum.Material.LeafyGrass, BodyMaterial = Enum.Material.Ground, PropStyle = "Forest"},
        Cliff = {Name = "Cliff", SurfaceMaterial = Enum.Material.Rock, BodyMaterial = Enum.Material.Slate, PropStyle = "Cliff"},
        Alpine = {Name = "Alpine", SurfaceMaterial = Enum.Material.Snow, BodyMaterial = Enum.Material.Rock, PropStyle = "Alpine"},
    },
    DesertCanyon = {
        Shore = {Name = "Shore", SurfaceMaterial = Enum.Material.Sand, BodyMaterial = Enum.Material.Sandstone, PropStyle = "Desert"},
        Dunes = {Name = "Dunes", SurfaceMaterial = Enum.Material.Sand, BodyMaterial = Enum.Material.Sandstone, PropStyle = "Desert"},
        Mesa = {Name = "Mesa", SurfaceMaterial = Enum.Material.CrackedLava, BodyMaterial = Enum.Material.Sandstone, PropStyle = "Mesa"},
        Cliff = {Name = "Cliff", SurfaceMaterial = Enum.Material.Rock, BodyMaterial = Enum.Material.Slate, PropStyle = "Cliff"},
    },
    SkyArchipelago = {
        Meadow = {Name = "Meadow", SurfaceMaterial = Enum.Material.Grass, BodyMaterial = Enum.Material.Ground, PropStyle = "SkyMeadow"},
        Grove = {Name = "Grove", SurfaceMaterial = Enum.Material.LeafyGrass, BodyMaterial = Enum.Material.Ground, PropStyle = "SkyGrove"},
        Cliff = {Name = "Cliff", SurfaceMaterial = Enum.Material.Rock, BodyMaterial = Enum.Material.Slate, PropStyle = "Cliff"},
        Summit = {Name = "Summit", SurfaceMaterial = Enum.Material.Snow, BodyMaterial = Enum.Material.Rock, PropStyle = "Alpine"},
    },
}

function BiomeLibrary.resolveBiome(profile, column)
    local profileBiomes = BIOMES[profile.Name]
    if not profileBiomes then
        return {Name = "Default", SurfaceMaterial = Enum.Material.Grass, BodyMaterial = Enum.Material.Ground, PropStyle = "Meadow"}
    end

    if profile.Kind == "SkyIslands" then
        if column.slope >= 1.15 then
            return profileBiomes.Cliff
        end
        if column.height >= profile.Spawn.Height + 26 then
            return profileBiomes.Summit
        end
        if column.moisture >= 0.58 then
            return profileBiomes.Grove
        end
        return profileBiomes.Meadow
    end

    if column.height <= profile.WaterLevel + 6 then
        return profileBiomes.Shore
    end
    if column.slope >= 1.1 then
        return profileBiomes.Cliff
    end
    if profile.Name == "DesertCanyon" then
        if column.height >= profile.Spawn.Height + 34 then
            return profileBiomes.Mesa
        end
        return profileBiomes.Dunes
    end
    if column.height >= profile.SnowLine then
        return profileBiomes.Alpine
    end
    if column.moisture >= 0.58 then
        return profileBiomes.Forest
    end
    return profileBiomes.Meadow
end

return BiomeLibrary
