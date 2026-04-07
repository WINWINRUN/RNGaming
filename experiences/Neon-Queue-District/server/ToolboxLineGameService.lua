local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local PromptPipelineBuilder = require(script.Parent:WaitForChild("PromptPipelineBuilder"))

local ToolboxLineGameService = {}

local ROOT_NAME = "ToolboxLineGame"
local ROOT_Y = 0
local PLAYER_HEIGHT_OFFSET = 3.5

local started = false
local root = nil
local activePlan = nil
local joinPrompt = nil
local meetPrompt = nil
local meetSpot = nil
local exitSpot = nil
local characterAnchor = nil
local environmentAnchor = nil

local slotTiles = {}
local slotPromptParts = {}
local slotPrompts = {}
local slotOwners = {}
local playerSlot = {}

local function clearTable(target)
    for key in pairs(target) do
        target[key] = nil
    end
end

local function getRewardForSlot(slot)
    return Config.RewardBase + ((Config.SlotCount - slot) * Config.RewardStep)
end

local function getAdvanceCostForSlot(slot)
    if slot <= 1 then
        return 0
    end

    return Config.AdvanceBaseCost + ((Config.SlotCount - slot) * Config.AdvanceCostStep)
end

local function getWallet(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local wallet = leaderstats:FindFirstChild(Config.CurrencyName)
    if not wallet then
        wallet = Instance.new("IntValue")
        wallet.Name = Config.CurrencyName
        wallet.Value = 0
        wallet.Parent = leaderstats
    end

    return wallet
end

local function getSlotOccupant(slot)
    local userId = slotOwners[slot]
    if not userId then
        return nil
    end

    return Players:GetPlayerByUserId(userId)
end

local function setStatus(text)
    if not root then
        return
    end

    local occupied = 0
    for _, userId in pairs(slotOwners) do
        if userId then
            occupied += 1
        end
    end

    root:SetAttribute("StatusText", text)
    root:SetAttribute("OpenSlots", Config.SlotCount - occupied)
    root:SetAttribute("QueueCapacity", Config.SlotCount)
    root:SetAttribute("MeetBonus", Config.MeetBonus)
end

local function getTileCFrame(slot)
    if activePlan and activePlan.SlotCFrames and activePlan.SlotCFrames[slot] then
        return activePlan.SlotCFrames[slot]
    end

    local progressionIndex = Config.SlotCount - slot
    local rowIndex = math.floor(progressionIndex / Config.SlotsPerRow)
    local indexInRow = progressionIndex % Config.SlotsPerRow
    local z = rowIndex * Config.RowSpacing
    local xOffset = indexInRow * Config.TileSpacing
    local xMin = -((Config.SlotsPerRow - 1) * Config.TileSpacing * 0.5)
    local x

    if rowIndex % 2 == 0 then
        x = xMin + xOffset
    else
        x = -xMin - xOffset
    end

    return CFrame.new(x, ROOT_Y + 1.1, (activePlan and activePlan.JoinPad and activePlan.JoinPad.CFrame.Position.Z - 18 or 58) - z)
end

local function makePart(parent, name, size, cframe, options)
    options = options or {}

    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = options.Anchored ~= false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Material = options.Material or Enum.Material.SmoothPlastic
    part.Color = options.Color or Color3.fromRGB(220, 220, 220)
    part.Transparency = options.Transparency or 0
    part.CanCollide = options.CanCollide ~= false
    part.CanTouch = options.CanTouch ~= false
    part.CanQuery = options.CanQuery ~= false
    part.Parent = parent
    return part
end

local function makeDescriptorPart(parent, descriptor)
    local options = {
        Anchored = descriptor.Anchored,
        Material = descriptor.Material,
        Color = descriptor.Color,
        Transparency = descriptor.Transparency,
        CanCollide = descriptor.CanCollide,
        CanTouch = descriptor.CanTouch,
        CanQuery = descriptor.CanQuery,
    }
    return makePart(parent, descriptor.Name, descriptor.Size, descriptor.CFrame, options)
end

local function addTileLabel(tile, slot)
    local reward = getRewardForSlot(slot)
    local cost = getAdvanceCostForSlot(slot)

    local gui = Instance.new("SurfaceGui")
    gui.Name = "TileLabel"
    gui.Face = Enum.NormalId.Top
    gui.CanvasSize = Vector2.new(512, 512)
    gui.Parent = tile

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 0, 0, 32)
    title.Size = UDim2.new(1, 0, 0, 110)
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = Color3.fromRGB(247, 248, 252)
    title.TextScaled = true
    title.Text = string.format("#%d", slot)
    title.Parent = gui

    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Position = UDim2.new(0, 24, 0, 170)
    rewardLabel.Size = UDim2.new(1, -48, 0, 90)
    rewardLabel.Font = Enum.Font.GothamBold
    rewardLabel.TextColor3 = Color3.fromRGB(166, 241, 184)
    rewardLabel.TextScaled = true
    rewardLabel.Text = string.format("+%d %s/s", reward, Config.CurrencyName)
    rewardLabel.Parent = gui

    local costLabel = Instance.new("TextLabel")
    costLabel.BackgroundTransparency = 1
    costLabel.Position = UDim2.new(0, 24, 0, 280)
    costLabel.Size = UDim2.new(1, -48, 0, 120)
    costLabel.Font = Enum.Font.GothamBold
    costLabel.TextColor3 = Color3.fromRGB(255, 219, 115)
    costLabel.TextScaled = true
    if slot > 1 then
        costLabel.Text = string.format("Move: %d %s", cost, Config.CurrencyName)
    else
        costLabel.Text = string.format("Meet Bonus: %d", Config.MeetBonus)
    end
    costLabel.Parent = gui
end

local function createBillboard(parent, titleText, bodyText, width)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(width or 260, 120)
    billboard.AlwaysOnTop = true
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
    billboard.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(23, 27, 36)
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(239, 183, 64)
    stroke.Thickness = 2
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(14, 12)
    title.Size = UDim2.new(1, -28, 0, 30)
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = Color3.fromRGB(247, 248, 252)
    title.TextScaled = true
    title.Text = titleText
    title.Parent = frame

    local body = Instance.new("TextLabel")
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(14, 46)
    body.Size = UDim2.new(1, -28, 1, -58)
    body.Font = Enum.Font.GothamBold
    body.TextColor3 = Color3.fromRGB(209, 220, 236)
    body.TextScaled = true
    body.TextWrapped = true
    body.Text = bodyText
    body.Parent = frame
end

local function ensureRoot()
    local existingRoot = Workspace:FindFirstChild(ROOT_NAME)
    if existingRoot and existingRoot:IsA("Model") then
        root = existingRoot
        return root
    end

    root = Instance.new("Model")
    root.Name = ROOT_NAME
    root.Parent = Workspace
    return root
end

local function destroyChildren(instance)
    for _, child in ipairs(instance:GetChildren()) do
        child:Destroy()
    end
end

local function getModelPivot(model)
    local ok, pivot = pcall(function()
        return model:GetPivot()
    end)

    if ok then
        return pivot
    end

    return CFrame.new()
end

local function repositionModel(model, cframe)
    pcall(function()
        model:PivotTo(cframe)
    end)
end

local function destroyUnwantedImports(preferredRoom)
    for _, child in ipairs(Workspace:GetChildren()) do
        if not child:IsA("Model") or child == root then
            continue
        end

        if child.Name == "Camera" or child.Name == "Terrain" then
            continue
        end

        if child.Name == "AmongUsRedCrewmate" or child.Name == "QueueBarrier" or child.Name == preferredRoom then
            continue
        end

        child:Destroy()
    end
end

local function arrangeCreatorStoreAssets()
    local preferredRoomName = Workspace:FindFirstChild("AmongUsRoom") and "AmongUsRoom" or "SpaceStationRoom"
    destroyUnwantedImports(preferredRoomName)

    local room = Workspace:FindFirstChild(preferredRoomName)
    local crewmate = Workspace:FindFirstChild("AmongUsRedCrewmate")
    local barrier = Workspace:FindFirstChild("QueueBarrier")

    if room and room:IsA("Model") and environmentAnchor then
        repositionModel(room, CFrame.new(environmentAnchor.Position + Vector3.new(0, 0, -26)))
    end

    if crewmate and crewmate:IsA("Model") and characterAnchor then
        repositionModel(crewmate, CFrame.new(characterAnchor.Position) * CFrame.Angles(0, math.rad(180), 0))
    end

    if barrier and barrier:IsA("Model") then
        local sourceFolder = root:FindFirstChild("CreatorStoreBarrierRun")
        if sourceFolder then
            sourceFolder:Destroy()
        end

        sourceFolder = Instance.new("Folder")
        sourceFolder.Name = "CreatorStoreBarrierRun"
        sourceFolder.Parent = root

        local anchorPositions = {}
        for row = 0, math.floor((Config.SlotCount - 1) / Config.SlotsPerRow) do
            local z = 58 - (row * Config.RowSpacing)
            table.insert(anchorPositions, Vector3.new(-67, ROOT_Y, z))
            table.insert(anchorPositions, Vector3.new(67, ROOT_Y, z))
        end

        for index, position in ipairs(anchorPositions) do
            local model = index == 1 and barrier or barrier:Clone()
            model.Parent = sourceFolder
            repositionModel(model, CFrame.new(position))
        end
    end
end

local function buildWorld()
    ensureRoot()
    destroyChildren(root)
    clearTable(slotTiles)
    clearTable(slotPromptParts)
    clearTable(slotPrompts)
    activePlan = PromptPipelineBuilder.buildPlan(Config)

    root:SetAttribute("RewardCurrencyName", Config.CurrencyName)
    root:SetAttribute("SlotCount", Config.SlotCount)
    root:SetAttribute("GameTitle", activePlan.Display.Title)
    root:SetAttribute("GameGoalText", activePlan.Display.GoalText)
    root:SetAttribute("WorldPrompt", activePlan.Display.WorldPrompt)
    root:SetAttribute("GameplayPrompt", activePlan.Display.GameplayPrompt)
    root:SetAttribute("FinaleRole", activePlan.Display.FinaleRole)
    root:SetAttribute("RouteModuleCount", activePlan.Display.RouteModuleCount)

    local generated = Instance.new("Folder")
    generated.Name = "GeneratedWorld"
    generated.Parent = root

    for _, descriptor in ipairs(activePlan.DecorParts) do
        makeDescriptorPart(generated, descriptor)
    end

    local joinPad = makeDescriptorPart(generated, activePlan.JoinPad)
    joinPrompt = Instance.new("ProximityPrompt")
    joinPrompt.Name = "JoinPrompt"
    joinPrompt.ActionText = "Join The Back"
    joinPrompt.ObjectText = Config.GameTitle
    joinPrompt.HoldDuration = 0.15
    joinPrompt.MaxActivationDistance = 12
    joinPrompt.RequiresLineOfSight = false
    joinPrompt.Parent = joinPad

    createBillboard(joinPad, "Back Of Line", Config.QueueIntroText, 320)

    local exitPad = makeDescriptorPart(generated, activePlan.ExitPad)
    exitSpot = exitPad
    createBillboard(exitPad, "Winner Exit", Config.GameGoalText, 320)

    meetSpot = makeDescriptorPart(generated, activePlan.MeetSpot)

    local meetPromptPart = makeDescriptorPart(generated, activePlan.MeetPromptPart)
    meetPrompt = Instance.new("ProximityPrompt")
    meetPrompt.Name = "MeetPrompt"
    meetPrompt.ActionText = Config.FinalePromptText
    meetPrompt.ObjectText = "Front Of Line"
    meetPrompt.HoldDuration = 0.15
    meetPrompt.MaxActivationDistance = 12
    meetPrompt.RequiresLineOfSight = false
    meetPrompt.Enabled = false
    meetPrompt.Parent = meetPromptPart

    characterAnchor = makeDescriptorPart(generated, activePlan.CharacterAnchor)

    environmentAnchor = makeDescriptorPart(generated, activePlan.EnvironmentAnchor)

    local queueFolder = Instance.new("Folder")
    queueFolder.Name = "QueueTiles"
    queueFolder.Parent = generated

    for slot = 1, Config.SlotCount do
        local progress = (Config.SlotCount - slot) / math.max(Config.SlotCount - 1, 1)
        local startColor = activePlan.SlotVisuals and activePlan.SlotVisuals.GradientStart or Color3.fromRGB(68, 92, 124)
        local endColor = activePlan.SlotVisuals and activePlan.SlotVisuals.GradientEnd or Color3.fromRGB(208, 168, 70)
        local tile = makePart(queueFolder, string.format("Slot%02d", slot), Vector3.new(10, 0.65, 8), activePlan.SlotCFrames[slot] or getTileCFrame(slot), {
            Material = Enum.Material.SmoothPlastic,
            Color = startColor:Lerp(endColor, progress),
        })
        slotTiles[slot] = tile
        addTileLabel(tile, slot)

        local promptPart = makePart(queueFolder, string.format("SlotPrompt%02d", slot), Vector3.new(4, 4, 4), tile.CFrame * CFrame.new(0, 4.2, 0), {
            Transparency = 1,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
        })
        slotPromptParts[slot] = promptPart

        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "AdvancePrompt"
        prompt.ActionText = slot == 1 and "Meet Character" or string.format("Move To #%d", slot - 1)
        prompt.ObjectText = string.format("Slot #%d", slot)
        prompt.HoldDuration = 0.15
        prompt.MaxActivationDistance = 8
        prompt.RequiresLineOfSight = false
        prompt.Enabled = false
        prompt.Parent = promptPart
        slotPrompts[slot] = prompt
    end

    local frontSign = makeDescriptorPart(generated, activePlan.FrontSign)
    createBillboard(frontSign, activePlan.FrontSign.Title, activePlan.FrontSign.Body, 340)

    local rulesSign = makeDescriptorPart(generated, activePlan.RulesSign)
    createBillboard(rulesSign, activePlan.RulesSign.Title, activePlan.RulesSign.Body, 340)

    setStatus("Line open. Claim the back slot and start earning " .. Config.CurrencyName .. ".")
    arrangeCreatorStoreAssets()
end

local function updatePlayerAttributes(player)
    local slot = playerSlot[player.UserId] or 0
    local income = slot > 0 and getRewardForSlot(slot) or 0
    local cost = slot > 1 and getAdvanceCostForSlot(slot) or 0
    player:SetAttribute("ToolboxLineSlot", slot)
    player:SetAttribute("ToolboxLineIncome", income)
    player:SetAttribute("ToolboxLineAdvanceCost", cost)
end

local function unlockCharacter(player)
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        humanoid.AutoRotate = true
    end
    if hrp then
        hrp.Anchored = false
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function lockCharacterToSlot(player, slot)
    local tile = slotTiles[slot]
    local character = player.Character
    if not tile or not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then
        return
    end

    local basePosition = tile.Position + Vector3.new(0, (tile.Size.Y * 0.5) + PLAYER_HEIGHT_OFFSET, 0)
    local facing = basePosition + Vector3.new(0, 0, -8)

    hrp.Anchored = false
    character:PivotTo(CFrame.lookAt(basePosition, facing))
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.AutoRotate = false
    hrp.Anchored = true
end

local function updateSlotPrompts()
    for slot = 1, Config.SlotCount do
        local prompt = slotPrompts[slot]
        if not prompt then
            continue
        end

        local occupant = getSlotOccupant(slot)
        if occupant then
            if slot == 1 then
                prompt.Enabled = false
            else
                local cost = getAdvanceCostForSlot(slot)
                prompt.Enabled = true
                prompt.ActionText = string.format("Pay %d %s", cost, Config.CurrencyName)
                prompt.ObjectText = string.format("Move To #%d", slot - 1)
            end
        else
            prompt.Enabled = false
            prompt.ActionText = "Empty"
            prompt.ObjectText = string.format("Slot #%d", slot)
        end
    end

    if meetPrompt then
        meetPrompt.Enabled = getSlotOccupant(1) ~= nil
    end
end

local function updateAllPlayerData()
    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayerAttributes(player)
    end
    updateSlotPrompts()
end

local function placePlayerInSlot(player, slot)
    local oldSlot = playerSlot[player.UserId]
    if oldSlot then
        slotOwners[oldSlot] = nil
    end

    playerSlot[player.UserId] = slot
    slotOwners[slot] = player.UserId
    lockCharacterToSlot(player, slot)
    updateAllPlayerData()

    if slot == 1 then
        setStatus(player.Name .. " reached the front of the line.")
    else
        setStatus(player.Name .. " moved to slot #" .. tostring(slot) .. ".")
    end
end

local function removePlayerFromLine(player, statusText)
    local slot = playerSlot[player.UserId]
    if slot then
        slotOwners[slot] = nil
        playerSlot[player.UserId] = nil
    end

    unlockCharacter(player)
    updateAllPlayerData()
    setStatus(statusText or "A slot opened up in the line.")
end

local function findJoinSlot()
    for slot = Config.SlotCount, 1, -1 do
        if not slotOwners[slot] then
            return slot
        end
    end

    return nil
end

local function tryJoinLine(player)
    if playerSlot[player.UserId] then
        setStatus(player.Name .. " is already in line.")
        return
    end

    local joinSlot = findJoinSlot()
    if not joinSlot then
        setStatus("The line is full. All " .. tostring(Config.SlotCount) .. " tiles are occupied.")
        return
    end

    getWallet(player)
    placePlayerInSlot(player, joinSlot)
end

local function tryAdvancePlayer(player)
    local slot = playerSlot[player.UserId]
    if not slot or slot <= 1 then
        return
    end

    if slotOwners[slot - 1] then
        setStatus("Slot #" .. tostring(slot - 1) .. " is occupied. Wait for it to open.")
        return
    end

    local wallet = getWallet(player)
    local cost = getAdvanceCostForSlot(slot)
    if wallet.Value < cost then
        setStatus(player.Name .. " needs " .. tostring(cost) .. " " .. Config.CurrencyName .. " to move ahead.")
        return
    end

    wallet.Value -= cost
    placePlayerInSlot(player, slot - 1)
end

local function tryMeetCharacter(player)
    local slot = playerSlot[player.UserId]
    if slot ~= 1 then
        setStatus(player.Name .. " has to reach slot #1 first.")
        return
    end

    local wallet = getWallet(player)
    wallet.Value += Config.MeetBonus

    removePlayerFromLine(player, player.Name .. " cleared the finale and took the jackpot.")

    local character = player.Character
    if character and exitSpot then
        character:PivotTo(CFrame.new(exitSpot.Position + Vector3.new(0, PLAYER_HEIGHT_OFFSET, 0)))
    end
end

local function bindCharacter(player)
    getWallet(player)

    player.CharacterAdded:Connect(function()
        task.wait(0.4)

        local slot = playerSlot[player.UserId]
        if slot then
            lockCharacterToSlot(player, slot)
        else
            unlockCharacter(player)
        end
    end)
end

function ToolboxLineGameService.buildWorldInStudio()
    buildWorld()
    return root
end

function ToolboxLineGameService.start()
    if started then
        return
    end

    started = true
    buildWorld()

    joinPrompt.Triggered:Connect(tryJoinLine)
    meetPrompt.Triggered:Connect(tryMeetCharacter)

    for slot, prompt in pairs(slotPrompts) do
        prompt.Triggered:Connect(function(player)
            if playerSlot[player.UserId] ~= slot then
                setStatus(player.Name .. " can only use the prompt on their own tile.")
                return
            end

            tryAdvancePlayer(player)
        end)
    end

    Players.PlayerAdded:Connect(bindCharacter)
    Players.PlayerRemoving:Connect(function(player)
        removePlayerFromLine(player, player.Name .. " left the line.")
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        bindCharacter(player)
        updatePlayerAttributes(player)
    end

    updateSlotPrompts()
    setStatus("Line open. Claim the back slot and start earning " .. Config.CurrencyName .. ".")

    task.spawn(function()
        while root and root.Parent do
            task.wait(1)

            for _, player in ipairs(Players:GetPlayers()) do
                local slot = playerSlot[player.UserId]
                if slot then
                    local wallet = getWallet(player)
                    wallet.Value += getRewardForSlot(slot)
                end
            end

            updateAllPlayerData()
        end
    end)
end

return ToolboxLineGameService
