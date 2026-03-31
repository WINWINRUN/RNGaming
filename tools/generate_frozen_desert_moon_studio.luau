local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local terrain = Workspace.Terrain

local seed = 515151
local worldRadius = 336
local clearHeight = 720
local clearCenterY = 80
local cellSize = 24
local baseY = -124
local spawnHeight = 112
local spawnInnerRadius = 36
local spawnFlattenRadius = 96

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end

	if value > maxValue then
		return maxValue
	end

	return value
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function smoothstep(edge0, edge1, value)
	if edge0 == edge1 then
		return value >= edge1 and 1 or 0
	end

	local alpha = clamp((value - edge0) / (edge1 - edge0), 0, 1)
	return alpha * alpha * (3 - 2 * alpha)
end

local function fractal2D(x, z, scale, octaves, lacunarity, persistence, noiseSeed)
	local total = 0
	local amplitude = 1
	local amplitudeSum = 0
	local currentScale = scale

	for octave = 0, octaves - 1 do
		total += math.noise((x / currentScale), (z / currentScale), noiseSeed + octave * 0.173) * amplitude
		amplitudeSum += amplitude
		amplitude *= persistence
		currentScale /= lacunarity
	end

	if amplitudeSum == 0 then
		return 0
	end

	return total / amplitudeSum
end

local function hash01(x, z, noiseSeed)
	local value = math.noise(x * 0.127, z * 0.191, noiseSeed)
	return clamp(value * 0.5 + 0.5, 0, 1)
end

local function getHeightAt(x, z)
	local distance = math.sqrt(x * x + z * z)
	local continental = fractal2D(x, z, 280, 4, 2.0, 0.48, seed * 0.001 + 11)
	local detail = fractal2D(x, z, 88, 3, 2.0, 0.45, seed * 0.001 + 47)
	local ridge = 1 - math.abs(fractal2D(x, z, 146, 3, 2.0, 0.5, seed * 0.001 + 89))
	local dunes = fractal2D(x, z, 54, 2, 2.0, 0.42, seed * 0.001 + 131)

	local height = 110 + continental * 66 + detail * 18 + ridge * 24 + dunes * 12
	local edgeDrop = smoothstep(252, worldRadius, distance) * 174
	height -= edgeDrop

	if distance < spawnFlattenRadius then
		local flattenAlpha = smoothstep(spawnInnerRadius, spawnFlattenRadius, distance)
		height = lerp(spawnHeight, height, flattenAlpha)
	end

	return math.max(height, baseY + cellSize)
end

local function makePart(parent, name, size, cframe, color, material, transparency, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = canCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

local function clearPrevious()
	local generatedEnvironment = Workspace:FindFirstChild("GeneratedEnvironment")
	if generatedEnvironment then
		generatedEnvironment:Destroy()
	end

	local generatedSpawn = Workspace:FindFirstChild("GeneratedSpawn")
	if generatedSpawn then
		generatedSpawn:Destroy()
	end

	local generatedInfo = Workspace:FindFirstChild("GeneratedTerrainInfo")
	if generatedInfo then
		generatedInfo:Destroy()
	end

	terrain:FillBlock(
		CFrame.new(0, clearCenterY, 0),
		Vector3.new(worldRadius * 2 + 120, clearHeight, worldRadius * 2 + 120),
		Enum.Material.Air
	)
end

local function buildTerrain()
	local columns = 0

	for x = -worldRadius, worldRadius, cellSize do
		for z = -worldRadius, worldRadius, cellSize do
			local centerX = x + cellSize * 0.5
			local centerZ = z + cellSize * 0.5
			local height = getHeightAt(centerX, centerZ)
			local bodyHeight = math.max(cellSize, height - baseY - 10)
			local topHeight = 10

			terrain:FillBlock(
				CFrame.new(centerX, baseY + bodyHeight * 0.5, centerZ),
				Vector3.new(cellSize, bodyHeight, cellSize),
				Enum.Material.Sandstone
			)

			local topMaterial = Enum.Material.Glacier
			if height > 152 then
				topMaterial = Enum.Material.Snow
			end

			terrain:FillBlock(
				CFrame.new(centerX, height - topHeight * 0.5, centerZ),
				Vector3.new(cellSize, topHeight, cellSize),
				topMaterial
			)

			columns += 1
		end
	end

	for index = 1, 7 do
		local angle = (index / 7) * math.pi * 2 + hash01(index, seed, 0.18) * 0.3
		local radius = 168 + hash01(index, seed, 0.29) * 92
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local y = getHeightAt(x, z) + 16
		terrain:FillBall(Vector3.new(x, y, z), 34 + hash01(index, seed, 0.51) * 18, Enum.Material.Rock)
		terrain:FillBlock(
			CFrame.new(x, y + 12, z),
			Vector3.new(44, 18, 44),
			Enum.Material.Snow
		)
	end

	return columns
end

local function buildEnvironment()
	local root = Instance.new("Folder")
	root.Name = "GeneratedEnvironment"
	root.Parent = Workspace

	local rocksFolder = Instance.new("Folder")
	rocksFolder.Name = "Rocks"
	rocksFolder.Parent = root

	local shardsFolder = Instance.new("Folder")
	shardsFolder.Name = "IceShards"
	shardsFolder.Parent = root

	local effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "Effects"
	effectsFolder.Parent = root

	local propCount = 0

	for x = -worldRadius + 24, worldRadius - 24, 32 do
		for z = -worldRadius + 24, worldRadius - 24, 32 do
			local roll = hash01(x * 0.1, z * 0.1, seed * 0.001 + 3.7)
			if roll > 0.83 then
				local height = getHeightAt(x, z)
				local position = Vector3.new(x, height + 2, z)

				if roll < 0.9 then
					local scale = 0.85 + hash01(x, z, seed * 0.001 + 9.1) * 0.65
					local baseColor = Color3.fromRGB(146, 189, 255)
					makePart(
						shardsFolder,
						"IceShardA",
						Vector3.new(1.6 * scale, 8.2 * scale, 1.5 * scale),
						CFrame.new(position + Vector3.new(0, 4.1 * scale, 0))
							* CFrame.Angles(math.rad(-7), math.rad(13), math.rad(10)),
						baseColor,
						Enum.Material.Glass,
						0.12,
						true
					)
					makePart(
						shardsFolder,
						"IceShardB",
						Vector3.new(1.0 * scale, 5.2 * scale, 1.1 * scale),
						CFrame.new(position + Vector3.new(-0.8 * scale, 2.6 * scale, 0.3 * scale))
							* CFrame.Angles(math.rad(8), math.rad(-9), math.rad(-8)),
						baseColor:Lerp(Color3.new(1, 1, 1), 0.12),
						Enum.Material.Neon,
						0.22,
						false
					)
				else
					local scale = 0.9 + hash01(x, z, seed * 0.001 + 12.7) * 0.55
					local baseColor = Color3.fromRGB(118, 123, 132)
					makePart(
						rocksFolder,
						"RockA",
						Vector3.new(4.0 * scale, 2.8 * scale, 3.4 * scale),
						CFrame.new(position + Vector3.new(0, 1.4 * scale, 0))
							* CFrame.Angles(0.08, 0.24, -0.12),
						baseColor,
						Enum.Material.Slate,
						0,
						true
					)
				end

				propCount += 1
			end
		end
	end

	local moonDistance = 468
	local moonPosition = Vector3.new(-moonDistance, 310, -moonDistance * 0.32)
	makePart(
		effectsFolder,
		"MoonHalo",
		Vector3.new(170, 170, 170),
		CFrame.new(moonPosition),
		Color3.fromRGB(162, 196, 255),
		Enum.Material.Neon,
		0.76,
		false
	).Shape = Enum.PartType.Ball
	makePart(
		effectsFolder,
		"MoonCore",
		Vector3.new(116, 116, 116),
		CFrame.new(moonPosition),
		Color3.fromRGB(235, 242, 255),
		Enum.Material.SmoothPlastic,
		0.03,
		false
	).Shape = Enum.PartType.Ball

	for index = 1, 120 do
		local angle = hash01(index, seed, 2.3) * math.pi * 2
		local radius = 360 + hash01(index, seed, 2.9) * 220
		local y = 234 + hash01(index, seed, 3.7) * 190
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local size = 1 + hash01(index, seed, 4.1) * 2.8
		makePart(
			effectsFolder,
			"Star" .. tostring(index),
			Vector3.new(size, size, size),
			CFrame.new(x, y, z),
			Color3.fromRGB(225, 236, 255),
			Enum.Material.Neon,
			0.14,
			false
		).Shape = Enum.PartType.Ball
	end

	return propCount
end

local function configureLighting()
	Lighting.Technology = Enum.Technology.Future
	Lighting.ClockTime = 1.8
	Lighting.Brightness = 1.4
	Lighting.ExposureCompensation = -0.08
	Lighting.Ambient = Color3.fromRGB(32, 40, 62)
	Lighting.OutdoorAmbient = Color3.fromRGB(49, 62, 93)
	Lighting.EnvironmentDiffuseScale = 0.24
	Lighting.EnvironmentSpecularScale = 0.38
	Lighting.GlobalShadows = true

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
	atmosphere.Color = Color3.fromRGB(120, 144, 198)
	atmosphere.Decay = Color3.fromRGB(24, 29, 49)
	atmosphere.Density = 0.1
	atmosphere.Offset = 0.02
	atmosphere.Glare = 0.02
	atmosphere.Haze = 0.54

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
	colorCorrection.Brightness = -0.04
	colorCorrection.Contrast = 0.2
	colorCorrection.Saturation = -0.09
	colorCorrection.TintColor = Color3.fromRGB(214, 226, 255)

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
	clouds.Cover = 0.05
	clouds.Density = 0.08
	clouds.Color = Color3.fromRGB(214, 225, 255)
end

local function createSpawn()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "GeneratedSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.CanCollide = true
	spawn.Color = Color3.fromRGB(176, 221, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.28
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, spawnHeight + 3, 0)
	spawn.Parent = Workspace
end

clearPrevious()
configureLighting()
local columns = buildTerrain()
local props = buildEnvironment()
createSpawn()

Workspace:SetAttribute("RNGamingTerrainProfile", "FrozenDesertMoon")
Workspace:SetAttribute("RNGamingTerrainSeed", seed)
Workspace:SetAttribute("RNGamingTerrainPropCount", props)

print("Generated profile: FrozenDesertMoon")
print("Seed: " .. tostring(seed))
print("Columns: " .. tostring(columns))
print("Props: " .. tostring(props))
