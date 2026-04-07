local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModularWorldAssets = require(ReplicatedStorage:WaitForChild("ModularWorldAssets"))

local PromptPipelineBuilder = {}

local function colorFromRGB(rgb, fallback)
    if type(rgb) == "table" and #rgb >= 3 then
        return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
    end
    return fallback or Color3.fromRGB(220, 220, 220)
end

local function addDescriptor(list, name, size, cframe, options)
    options = options or {}

    table.insert(list, {
        Name = name,
        Size = size,
        CFrame = cframe,
        Anchored = options.Anchored ~= false,
        Material = options.Material or Enum.Material.SmoothPlastic,
        Color = options.Color or Color3.fromRGB(220, 220, 220),
        Transparency = options.Transparency or 0,
        CanCollide = options.CanCollide ~= false,
        CanTouch = options.CanTouch ~= false,
        CanQuery = options.CanQuery ~= false,
    })
end

local function addGate(list, name, position, width, height, color)
    local postOffset = math.max(6, (width * 0.5) - 3)
    addDescriptor(list, name .. "LeftPost", Vector3.new(2, height, 2), CFrame.new(position + Vector3.new(-postOffset, height * 0.5, 0)), {
        Material = Enum.Material.Metal,
        Color = color,
    })
    addDescriptor(list, name .. "RightPost", Vector3.new(2, height, 2), CFrame.new(position + Vector3.new(postOffset, height * 0.5, 0)), {
        Material = Enum.Material.Metal,
        Color = color,
    })
    addDescriptor(list, name .. "Beam", Vector3.new(width, 1.4, 2.2), CFrame.new(position + Vector3.new(0, height, 0)), {
        Material = Enum.Material.Neon,
        Color = color,
    })
end

local function addMarker(list, name, position, height, color)
    addDescriptor(list, name .. "Base", Vector3.new(4, 0.6, 4), CFrame.new(position + Vector3.new(0, 0.3, 0)), {
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(36, 40, 50),
    })
    addDescriptor(list, name .. "Pillar", Vector3.new(1.4, height, 1.4), CFrame.new(position + Vector3.new(0, height * 0.5, 0)), {
        Material = Enum.Material.Neon,
        Color = color,
    })
end

local function getZoneColor(assetStyles, zoneRole)
    local zoneColors = assetStyles.ZoneColors or {}
    return colorFromRGB(zoneColors[zoneRole], Color3.fromRGB(180, 180, 190))
end

local function getSlotCFrame(config, layout, slot)
    local progressionIndex = config.SlotCount - slot
    local rowIndex = math.floor(progressionIndex / config.SlotsPerRow)
    local indexInRow = progressionIndex % config.SlotsPerRow
    local z = (layout.queue_start_z or 58) - (rowIndex * config.RowSpacing)
    local xOffset = indexInRow * config.TileSpacing
    local xMin = -((config.SlotsPerRow - 1) * config.TileSpacing * 0.5)
    local x

    if rowIndex % 2 == 0 then
        x = xMin + xOffset
    else
        x = -xMin - xOffset
    end

    return CFrame.new(x, 1.1, z)
end

function PromptPipelineBuilder.buildPlan(config)
    local layout = ModularWorldAssets.Layout or {}
    local display = ModularWorldAssets.Display or {}
    local world = ModularWorldAssets.World or {}
    local integratedWorldSpec = world.IntegratedWorldSpec or {}
    local zoneAllocations = world.ZoneAllocations or {}
    local assetStyles = ModularWorldAssets.AssetStyles or {}
    local prompts = ModularWorldAssets.Prompts or {}

    local rows = math.ceil(config.SlotCount / config.SlotsPerRow)
    local slotCFrames = {}
    for slot = 1, config.SlotCount do
        slotCFrames[slot] = getSlotCFrame(config, layout, slot)
    end

    local queueStartZ = layout.queue_start_z or 58
    local frontZ = layout.queue_front_z or (queueStartZ - ((rows - 1) * config.RowSpacing))
    local queueWidth = ((config.SlotsPerRow - 1) * config.TileSpacing) + 18
    local joinZ = queueStartZ + 18
    local meetZ = frontZ - 16
    local exitZ = meetZ - 28
    local worldCenterZ = (joinZ + exitZ) * 0.5
    local baseWidth = layout.baseplate_width or (queueWidth + 54)
    local baseDepth = layout.baseplate_depth or ((rows * config.RowSpacing) + 84)
    local sideRailOffset = (queueWidth * 0.5) + 10
    local signOffsetX = math.min((baseWidth * 0.5) - 10, sideRailOffset + 10)
    local decorParts = {}

    addDescriptor(decorParts, "Baseplate", Vector3.new(baseWidth, 1, baseDepth), CFrame.new(0, 0, worldCenterZ), {
        Material = Enum.Material.Slate,
        Color = colorFromRGB(assetStyles.BaseplateColorRGB, Color3.fromRGB(45, 50, 62)),
    })

    addDescriptor(decorParts, "QueueLane", Vector3.new(queueWidth + 8, 0.2, (queueStartZ - frontZ) + 24), CFrame.new(0, 0.65, (queueStartZ + frontZ) * 0.5), {
        Material = Enum.Material.SmoothPlastic,
        Color = colorFromRGB(assetStyles.QueueLaneColorRGB, Color3.fromRGB(42, 47, 60)),
    })

    addDescriptor(decorParts, "SideRailLeft", Vector3.new(2, 5, (queueStartZ - frontZ) + 28), CFrame.new(-sideRailOffset, 2.8, (queueStartZ + frontZ) * 0.5), {
        Material = Enum.Material.Metal,
        Color = colorFromRGB(assetStyles.SideRailColorRGB, Color3.fromRGB(70, 76, 92)),
    })
    addDescriptor(decorParts, "SideRailRight", Vector3.new(2, 5, (queueStartZ - frontZ) + 28), CFrame.new(sideRailOffset, 2.8, (queueStartZ + frontZ) * 0.5), {
        Material = Enum.Material.Metal,
        Color = colorFromRGB(assetStyles.SideRailColorRGB, Color3.fromRGB(70, 76, 92)),
    })

    for row = 0, rows - 1 do
        local rowZ = queueStartZ - (row * config.RowSpacing)
        addDescriptor(decorParts, string.format("QueueRowPlate%02d", row + 1), Vector3.new(queueWidth, 0.4, 10), CFrame.new(0, 0.9, rowZ), {
            Material = Enum.Material.SmoothPlastic,
            Color = colorFromRGB(assetStyles.QueueRowPlateColorRGB, Color3.fromRGB(53, 58, 72)),
        })
    end

    local gateCount = math.max(2, math.min(6, math.floor(config.SlotCount / 10)))
    for gateIndex = 1, gateCount do
        local alpha = gateIndex / (gateCount + 1)
        local gateZ = queueStartZ - (((queueStartZ - frontZ) + 8) * alpha)
        addGate(decorParts, string.format("CheckpointGate%02d", gateIndex), Vector3.new(0, 0, gateZ), queueWidth + 6, 9, colorFromRGB(assetStyles.CheckpointGateColorRGB, Color3.fromRGB(239, 183, 64)))
    end

    for index, zone in ipairs(zoneAllocations) do
        local zoneRole = zone.zone_role
        local zoneColor = getZoneColor(assetStyles, zoneRole)
        if zoneRole == "spawn_entry" then
            local depth = math.max(14, 10 + zone.module_budget)
            addDescriptor(decorParts, "SpawnPlatform", Vector3.new(queueWidth + 18, 0.8, depth), CFrame.new(0, 1.05, joinZ), {
                Material = Enum.Material.SmoothPlastic,
                Color = zoneColor,
            })
        elseif zoneRole == "income_nodes" then
            local markerCount = math.max(2, math.min(5, math.floor(zone.module_budget / 2)))
            for markerIndex = 1, markerCount do
                local alpha = markerIndex / (markerCount + 1)
                local markerZ = queueStartZ - ((queueStartZ - frontZ) * alpha)
                local markerX = markerIndex % 2 == 0 and -(sideRailOffset - 6) or (sideRailOffset - 6)
                addMarker(decorParts, string.format("IncomeMarker%02d", markerIndex), Vector3.new(markerX, 0, markerZ), 7, zoneColor)
            end
        elseif zoneRole == "finale_pad" then
            local finaleWidth = queueWidth + 22
            local finaleDepth = math.max(20, 12 + zone.module_budget)
            addDescriptor(decorParts, "FinalePlatform", Vector3.new(finaleWidth, 1.2, finaleDepth), CFrame.new(0, 1.25, meetZ), {
                Material = Enum.Material.Neon,
                Color = zoneColor,
            })
            addDescriptor(decorParts, "FinaleBackdrop", Vector3.new(finaleWidth + 6, 16, 2), CFrame.new(0, 8.5, meetZ - (finaleDepth * 0.5) - 3), {
                Material = Enum.Material.Metal,
                Color = colorFromRGB(assetStyles.StructureMetalColorRGB, Color3.fromRGB(56, 62, 76)),
            })
            addDescriptor(decorParts, "FinaleTowerLeft", Vector3.new(4, 18, 4), CFrame.new(-(finaleWidth * 0.5) - 4, 9.5, meetZ - 1), {
                Material = Enum.Material.Metal,
                Color = colorFromRGB(assetStyles.AccentMetalColorRGB, Color3.fromRGB(77, 85, 104)),
            })
            addDescriptor(decorParts, "FinaleTowerRight", Vector3.new(4, 18, 4), CFrame.new((finaleWidth * 0.5) + 4, 9.5, meetZ - 1), {
                Material = Enum.Material.Metal,
                Color = colorFromRGB(assetStyles.AccentMetalColorRGB, Color3.fromRGB(77, 85, 104)),
            })
        elseif zoneRole == "exit_reset" then
            addDescriptor(decorParts, "ExitLane", Vector3.new(queueWidth * 0.7, 0.6, 22), CFrame.new(0, 1.0, exitZ), {
                Material = Enum.Material.Neon,
                Color = zoneColor,
            })
        elseif zoneRole == "queue_slots" and index == 2 then
            addDescriptor(decorParts, "QueueBackdropLeft", Vector3.new(8, 8, (queueStartZ - frontZ) + 20), CFrame.new(-(sideRailOffset + 8), 4.5, (queueStartZ + frontZ) * 0.5), {
                Material = Enum.Material.Metal,
                Color = colorFromRGB(assetStyles.BackdropColorRGB, Color3.fromRGB(60, 66, 84)),
            })
            addDescriptor(decorParts, "QueueBackdropRight", Vector3.new(8, 8, (queueStartZ - frontZ) + 20), CFrame.new(sideRailOffset + 8, 4.5, (queueStartZ + frontZ) * 0.5), {
                Material = Enum.Material.Metal,
                Color = colorFromRGB(assetStyles.BackdropColorRGB, Color3.fromRGB(60, 66, 84)),
            })
        end
    end

    local laneMidZ = (queueStartZ + frontZ) * 0.5

    return {
        Display = {
            Title = display.Title or "Prompt Pipeline Queue",
            GoalText = display.GoalText or "",
            QueueIntroText = display.QueueIntroText or "",
            FinalePromptText = display.FinalePromptText or "Meet the host",
            WorldPrompt = prompts.WorldPrompt or "",
            GameplayPrompt = prompts.GameplayPrompt or "",
            FinaleRole = display.FinaleRole or "host",
            RouteModuleCount = integratedWorldSpec.module_count or config.SlotCount,
        },
        SlotVisuals = {
            GradientStart = colorFromRGB(assetStyles.QueueSlotGradientStartRGB, Color3.fromRGB(68, 92, 124)),
            GradientEnd = colorFromRGB(assetStyles.QueueSlotGradientEndRGB, Color3.fromRGB(208, 168, 70)),
        },
        DecorParts = decorParts,
        SlotCFrames = slotCFrames,
        JoinPad = {
            Name = "JoinPad",
            Size = Vector3.new(18, 1, 14),
            CFrame = CFrame.new(0, 1.2, joinZ),
            Material = Enum.Material.Neon,
            Color = getZoneColor(assetStyles, "spawn_entry"),
        },
        ExitPad = {
            Name = "ExitPad",
            Size = Vector3.new(20, 1, 16),
            CFrame = CFrame.new(0, 1.2, exitZ),
            Material = Enum.Material.Neon,
            Color = getZoneColor(assetStyles, "exit_reset"),
        },
        MeetSpot = {
            Name = "MeetSpot",
            Size = Vector3.new(14, 1, 14),
            CFrame = CFrame.new(0, 1.2, meetZ),
            Material = Enum.Material.Neon,
            Color = getZoneColor(assetStyles, "finale_pad"),
        },
        MeetPromptPart = {
            Name = "MeetPromptPart",
            Size = Vector3.new(12, 8, 12),
            CFrame = CFrame.new(0, 5.5, meetZ),
            Transparency = 1,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
        },
        CharacterAnchor = {
            Name = "CharacterAnchor",
            Size = Vector3.new(1, 1, 1),
            CFrame = CFrame.new(0, 4, meetZ - 10),
            Transparency = 1,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
        },
        EnvironmentAnchor = {
            Name = "EnvironmentAnchor",
            Size = Vector3.new(1, 1, 1),
            CFrame = CFrame.new(0, 1, meetZ - 16),
            Transparency = 1,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
        },
        FrontSign = {
            Name = "FrontSignPost",
            Size = Vector3.new(12, 12, 2),
            CFrame = CFrame.new(0, 6, meetZ - 30),
            Material = Enum.Material.Metal,
            Color = colorFromRGB(assetStyles.StructureMetalColorRGB, Color3.fromRGB(56, 62, 76)),
            Title = display.FinalePromptText or "Finale",
            Body = display.GoalText or "Reach the front, collect the reward, and clear the lane.",
        },
        RulesSign = {
            Name = "RulesSignPost",
            Size = Vector3.new(10, 10, 2),
            CFrame = CFrame.new(-signOffsetX, 5, queueStartZ + 8),
            Material = Enum.Material.Metal,
            Color = colorFromRGB(assetStyles.StructureMetalColorRGB, Color3.fromRGB(56, 62, 76)),
            Title = "How It Works",
            Body = display.QueueIntroText or "Claim a slot and follow the route.",
        },
        QueueLaneMidZ = laneMidZ,
    }
end

return PromptPipelineBuilder
