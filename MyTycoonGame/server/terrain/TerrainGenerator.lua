local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain

local Noise = require(script.Parent.Noise)
local BiomeLibrary = require(script.Parent.BiomeLibrary)

local TerrainGenerator = {}

local function getManagedCenter(profile)
    local center = profile.ManagedCenter
    return Vector3.new(center.X, center.Y, center.Z)
end

local function getManagedClearCenter(profile)
    local center = getManagedCenter(profile)
    local y = profile.ClearMinY + (profile.ClearMaxY - profile.ClearMinY) * 0.5
    return Vector3.new(center.X, y, center.Z)
end

local function getReservedZone(profile, config)
    local flatRadius = config.TerrainReservedFlatRadius
    if type(flatRadius) ~= "number" or flatRadius <= 0 then
        return nil
    end

    local blendRadius = config.TerrainReservedBlendRadius
    if type(blendRadius) ~= "number" then
        blendRadius = math.max(profile.Spawn.FlattenRadius, 48)
    end

    return {
        Height = profile.Spawn.Height,
        FlatRadius = math.max(flatRadius, profile.Spawn.FlattenRadius),
        OuterRadius = math.max(flatRadius, profile.Spawn.FlattenRadius) + math.max(blendRadius, 0),
    }
end

local function buildClearFootprint(center, worldSize, clearMinY, clearMaxY)
    local y = clearMinY + (clearMaxY - clearMinY) * 0.5
    return {
        Center = Vector3.new(center.X, y, center.Z),
        Size = Vector3.new(worldSize, clearMaxY - clearMinY, worldSize),
    }
end

local function getPreviousClearFootprint()
    local worldSize = Workspace:GetAttribute("RNGamingTerrainWorldSize")
    local clearMinY = Workspace:GetAttribute("RNGamingTerrainClearMinY")
    local clearMaxY = Workspace:GetAttribute("RNGamingTerrainClearMaxY")
    local centerX = Workspace:GetAttribute("RNGamingTerrainCenterX")
    local centerY = Workspace:GetAttribute("RNGamingTerrainCenterY")
    local centerZ = Workspace:GetAttribute("RNGamingTerrainCenterZ")

    if type(worldSize) ~= "number"
        or type(clearMinY) ~= "number"
        or type(clearMaxY) ~= "number"
        or type(centerX) ~= "number"
        or type(centerY) ~= "number"
        or type(centerZ) ~= "number" then
        return nil
    end

    return buildClearFootprint(
        {
            X = centerX,
            Y = centerY,
            Z = centerZ,
        },
        worldSize,
        clearMinY,
        clearMaxY
    )
end

local function clearFootprint(footprint)
    if not footprint then
        return
    end

    Terrain:FillBlock(CFrame.new(footprint.Center), footprint.Size, Enum.Material.Air)
end

local function createColumnSummary()
    return {
        ColumnCount = 0,
        WaterColumns = 0,
        MinimumHeight = math.huge,
        MaximumHeight = -math.huge,
    }
end

local function updateColumnSummary(summary, height, waterLevel)
    summary.ColumnCount = summary.ColumnCount + 1
    summary.MinimumHeight = math.min(summary.MinimumHeight, height)
    summary.MaximumHeight = math.max(summary.MaximumHeight, height)
    if height < waterLevel then
        summary.WaterColumns = summary.WaterColumns + 1
    end
end

local function clearGeneratedFolder(folderName)
    local existing = Workspace:FindFirstChild(folderName)
    if existing then
        existing:Destroy()
    end
end

function TerrainGenerator.clearManagedRegion(profile, config)
    local currentFootprint = buildClearFootprint(profile.ManagedCenter, profile.WorldSize, profile.ClearMinY, profile.ClearMaxY)
    local previousFootprint = getPreviousClearFootprint()

    clearFootprint(previousFootprint)
    clearFootprint(currentFootprint)
    clearGeneratedFolder(config.GeneratedEnvironmentFolderName)

    local spawn = Workspace:FindFirstChild("GeneratedSpawn")
    if spawn then
        spawn:Destroy()
    end
end

local function buildHeightmapColumns(profile, seed, config)
    local cellSize = profile.CellSize
    local cellCount = math.floor(profile.WorldSize / cellSize)
    local halfSize = profile.WorldSize * 0.5
    local center = getManagedCenter(profile)
    local reservedZone = getReservedZone(profile, config or {})
    local columns = {}
    local summary = createColumnSummary()

    for ix = 1, cellCount do
        columns[ix] = {}
        local worldX = center.X - halfSize + (ix - 0.5) * cellSize

        for iz = 1, cellCount do
            local worldZ = center.Z - halfSize + (iz - 0.5) * cellSize
            local dx = worldX - center.X
            local dz = worldZ - center.Z
            local distance = math.sqrt(dx * dx + dz * dz)

            local continental = Noise.fractal2D(
                worldX,
                worldZ,
                profile.Noise.ContinentalScale,
                profile.Noise.ContinentalOctaves,
                profile.Noise.Lacunarity,
                profile.Noise.Persistence,
                seed + 11
            )
            local detail = Noise.fractal2D(
                worldX,
                worldZ,
                profile.Noise.DetailScale,
                profile.Noise.DetailOctaves,
                profile.Noise.Lacunarity,
                profile.Noise.Persistence,
                seed + 173
            )
            local ridge = Noise.ridge2D(
                worldX,
                worldZ,
                profile.Noise.RidgeScale,
                3,
                profile.Noise.Lacunarity,
                profile.Noise.Persistence,
                seed + 307
            )
            local moisture = (Noise.fractal2D(
                worldX,
                worldZ,
                profile.Noise.MoistureScale,
                3,
                profile.Noise.Lacunarity,
                profile.Noise.Persistence,
                seed + 419
            ) + 1) * 0.5

            local height = profile.BaseHeight
                + continental * profile.HeightAmplitude
                + detail * profile.DetailAmplitude
                + ridge * profile.RidgeAmplitude

            if profile.River.Enabled then
                local riverNoise = math.abs(Noise.fractal2D(
                    worldX,
                    worldZ,
                    profile.River.Scale,
                    2,
                    2,
                    0.5,
                    seed + 557
                ))
                if riverNoise < profile.River.Width then
                    local riverAlpha = 1 - riverNoise / profile.River.Width
                    height = height - riverAlpha * profile.River.Depth
                end
            end

            local edgeAlpha = Noise.smoothstep(profile.Edge.InnerRadius, profile.Edge.OuterRadius, distance)
            height = height - edgeAlpha * profile.Edge.Drop

            local spawnAlpha = Noise.smoothstep(
                profile.Spawn.InnerBlendRadius,
                profile.Spawn.FlattenRadius,
                distance
            )
            if distance < profile.Spawn.FlattenRadius then
                height = Noise.lerp(profile.Spawn.Height, height, spawnAlpha)
            end

            if reservedZone and distance < reservedZone.OuterRadius then
                local reservedAlpha = Noise.smoothstep(
                    reservedZone.FlatRadius,
                    reservedZone.OuterRadius,
                    distance
                )
                height = Noise.lerp(reservedZone.Height, height, reservedAlpha)
            end

            height = math.max(height, profile.BaseY + cellSize)

            columns[ix][iz] = {
                x = worldX,
                z = worldZ,
                height = height,
                moisture = moisture,
                slope = 0,
                biome = nil,
            }
            updateColumnSummary(summary, height, profile.WaterLevel)
        end

        if ix % 12 == 0 then
            task.wait()
        end
    end

    for ix = 1, cellCount do
        for iz = 1, cellCount do
            local left = columns[math.max(ix - 1, 1)][iz].height
            local right = columns[math.min(ix + 1, cellCount)][iz].height
            local up = columns[ix][math.max(iz - 1, 1)].height
            local down = columns[ix][math.min(iz + 1, cellCount)].height
            local slope = math.max(math.abs(left - right), math.abs(up - down)) / cellSize
            local column = columns[ix][iz]
            column.slope = slope
            column.biome = BiomeLibrary.resolveBiome(profile, column)
        end
    end

    if summary.ColumnCount > 0 then
        summary.WaterCoverage = summary.WaterColumns / summary.ColumnCount
    else
        summary.WaterCoverage = 0
    end

    return columns, summary
end

local function fillColumn(profile, column)
    local cellSize = profile.CellSize
    local baseY = profile.BaseY
    local bodyTop = math.max(baseY + cellSize, column.height - profile.TopsoilDepth)
    local bodyHeight = bodyTop - baseY
    local topHeight = math.max(cellSize, column.height - bodyTop)
    local biome = column.biome

    if bodyHeight > 0 then
        Terrain:FillBlock(
            CFrame.new(column.x, baseY + bodyHeight * 0.5, column.z),
            Vector3.new(cellSize, bodyHeight, cellSize),
            biome.BodyMaterial
        )
    end

    Terrain:FillBlock(
        CFrame.new(column.x, bodyTop + topHeight * 0.5, column.z),
        Vector3.new(cellSize, topHeight, cellSize),
        biome.SurfaceMaterial
    )

    if column.height < profile.WaterLevel then
        local waterHeight = profile.WaterLevel - column.height
        Terrain:FillBlock(
            CFrame.new(column.x, column.height + waterHeight * 0.5, column.z),
            Vector3.new(cellSize, waterHeight, cellSize),
            Enum.Material.Water
        )
    end
end

local function applyHeightmapColumns(profile, columns)
    for ix, columnRow in ipairs(columns) do
        for _, column in ipairs(columnRow) do
            fillColumn(profile, column)
        end

        if ix % 12 == 0 then
            task.wait()
        end
    end
end

local function buildIslandDescriptors(profile, seed)
    local center = getManagedCenter(profile)
    local descriptors = {}
    local totalIslands = profile.IslandCount

    table.insert(descriptors, {
        Position = Vector3.new(center.X, profile.PrimaryIslandAltitude or profile.Spawn.Height, center.Z),
        Radius = profile.PrimaryIslandRadius or (profile.IslandRadius + 10),
        Altitude = profile.PrimaryIslandAltitude or profile.Spawn.Height,
    })

    for index = 1, totalIslands - 1 do
        local angleNoise = Noise.hash01(index, totalIslands, seed + 61)
        local angle = ((index - 1) / math.max(totalIslands - 1, 1)) * math.pi * 2 + angleNoise * 0.45
        local radialOffset = (Noise.hash01(index, totalIslands, seed + 73) - 0.5) * profile.RingJitter
        local altitudeOffset = (Noise.hash01(index, totalIslands, seed + 89) - 0.5) * profile.AltitudeJitter
        local radiusOffset = (Noise.hash01(index, totalIslands, seed + 101) - 0.5) * profile.IslandRadiusJitter

        local radialDistance = profile.RingRadius + radialOffset
        local altitude = profile.BaseHeight + altitudeOffset
        local radius = profile.IslandRadius + radiusOffset

        table.insert(descriptors, {
            Position = Vector3.new(
                center.X + math.cos(angle) * radialDistance,
                altitude,
                center.Z + math.sin(angle) * radialDistance
            ),
            Radius = radius,
            Altitude = altitude,
        })
    end

    return descriptors
end

local function applySkyIslands(profile, seed)
    local descriptors = buildIslandDescriptors(profile, seed)
    local minimumHeight = math.huge
    local maximumHeight = -math.huge

    for _, descriptor in ipairs(descriptors) do
        local position = descriptor.Position
        local radius = descriptor.Radius

        Terrain:FillBall(position, radius, Enum.Material.Ground)
        Terrain:FillBlock(
            CFrame.new(position.X, position.Y + profile.TopThickness * 0.25, position.Z),
            Vector3.new(radius * 1.8, profile.TopThickness, radius * 1.8),
            Enum.Material.Grass
        )

        for layer = 1, 5 do
            local alpha = layer / 5
            local undersideRadius = radius * (1 - alpha * 0.45)
            local y = position.Y - alpha * profile.IslandDepth
            Terrain:FillBall(Vector3.new(position.X, y, position.Z), undersideRadius, Enum.Material.Rock)
        end

        minimumHeight = math.min(minimumHeight, position.Y - profile.IslandDepth)
        maximumHeight = math.max(maximumHeight, position.Y + profile.TopThickness)
    end

    return {
        ColumnCount = 0,
        IslandCount = #descriptors,
        MinimumHeight = minimumHeight,
        MaximumHeight = maximumHeight,
        WaterCoverage = 0,
    }
end

function TerrainGenerator.generate(profile, seed, config, options)
    local generationOptions = options or {}
    local shouldClear = generationOptions.ClearManagedRegion
    if shouldClear == nil then
        shouldClear = config.ClearManagedRegionBeforeGenerate
    end

    if shouldClear then
        TerrainGenerator.clearManagedRegion(profile, config)
    end

    if profile.Kind == "SkyIslands" then
        return applySkyIslands(profile, seed)
    end

    local columns, summary = buildHeightmapColumns(profile, seed, config)
    applyHeightmapColumns(profile, columns)
    return summary
end

return TerrainGenerator
