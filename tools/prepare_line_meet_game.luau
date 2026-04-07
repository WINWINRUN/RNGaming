local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ROOT_NAME = "LineMeetGame"
local RUNTIME_SCRIPT_NAME = "LineMeetGameRuntime"
local CLIENT_SCRIPT_NAME = "LineMeetGameClient"

local runtimeSource = [=[
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Chat = game:GetService("Chat")

local root = Workspace:WaitForChild("LineMeetGame")
local queueSlotsFolder = root:WaitForChild("QueueSlots")
local board = root:WaitForChild("QueueBoard")
local boardGui = board:WaitForChild("QueueBoardGui")
local statusLabel = boardGui:WaitForChild("StatusLabel")
local nowServingLabel = boardGui:WaitForChild("NowServingLabel")
local countdownLabel = boardGui:WaitForChild("CountdownLabel")
local queueCountLabel = boardGui:WaitForChild("QueueCountLabel")
local joinPad = root:WaitForChild("JoinPad")
local joinPrompt = joinPad:WaitForChild("JoinPrompt")
local meetSpot = root:WaitForChild("MeetSpot")
local exitPad = root:WaitForChild("ExitPad")
local crewmateStage = root:WaitForChild("CrewmateStage")
local meetPromptPart = crewmateStage:WaitForChild("MeetPromptPart")
local meetPrompt = meetPromptPart:WaitForChild("MeetPrompt")
local confettiAnchor = crewmateStage:WaitForChild("ConfettiAnchor")
local confetti = confettiAnchor:FindFirstChildOfClass("ParticleEmitter")
local crewmateHead = crewmateStage:FindFirstChild("CrewmateRig") and crewmateStage.CrewmateRig:FindFirstChild("Head")

local queueSlots = {}
for _, child in ipairs(queueSlotsFolder:GetChildren()) do
    if child:IsA("BasePart") and child.Name:match("^LineSlot") then
        table.insert(queueSlots, child)
    end
end
table.sort(queueSlots, function(left, right)
    return left.Name < right.Name
end)

local maxSlots = root:GetAttribute("MaxSlots") or #queueSlots
local advanceInterval = root:GetAttribute("AdvanceInterval") or 5
local rewardAmount = root:GetAttribute("RewardAmount") or 35
local meetingTimeout = root:GetAttribute("MeetingTimeout") or 12
local currencyName = root:GetAttribute("CurrencyName") or "MoonCredits"

local queue = {}
local activeGuest = nil
local countdown = advanceInterval
local activeGuestDeadline = 0
local sessionId = root:GetAttribute("SessionId")

local function findQueueIndex(player)
    for index, queuedPlayer in ipairs(queue) do
        if queuedPlayer == player then
            return index
        end
    end

    return nil
end

local function awardPlayer(player, amount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return false
    end

    local wallet = leaderstats:FindFirstChild(currencyName)
    if not wallet or not wallet:IsA("IntValue") then
        return false
    end

    wallet.Value += amount
    return true
end

local function bubbleChat(message)
    if not crewmateHead then
        return
    end

    pcall(function()
        Chat:Chat(crewmateHead, message, Enum.ChatColor.Red)
    end)
end

local function pivotPlayerToPart(player, targetPart)
    local character = player.Character
    if not character or not character.Parent then
        return
    end

    local humRoot = character:FindFirstChild("HumanoidRootPart")
    if not humRoot then
        return
    end

    local lift = (targetPart.Size.Y * 0.5) + 3
    local position = targetPart.Position + Vector3.new(0, lift, 0)
    local facing = targetPart.Position + targetPart.CFrame.LookVector * 8
    character:PivotTo(CFrame.lookAt(position, facing))
end

local function updatePlayerState(player, queuePosition, isMeeting)
    player:SetAttribute("LineMeetPosition", queuePosition or 0)
    player:SetAttribute("LineMeetMeetingActive", isMeeting == true)
end

local function updateEveryoneState()
    for _, player in ipairs(Players:GetPlayers()) do
        local queueIndex = findQueueIndex(player)
        updatePlayerState(player, queueIndex, activeGuest == player)
    end
end

local function updateBoard(statusText)
    local status = statusText
    if not status or status == "" then
        if activeGuest then
            status = "Front of line is meeting Red Crewmate."
        elseif #queue > 0 then
            status = "The line is moving. Hold your spot."
        else
            status = "Line open. Join the queue to meet Red Crewmate."
        end
    end

    local nowServing = activeGuest and activeGuest.Name or "Nobody yet"
    local countdownText
    if activeGuest then
        countdownText = string.format("Meeting window: %ss", math.max(activeGuestDeadline, 0))
    elseif #queue > 0 then
        countdownText = string.format("Next shuffle in: %ss", math.max(countdown, 0))
    else
        countdownText = "Next shuffle begins once someone joins."
    end

    root:SetAttribute("QueueCount", #queue)
    root:SetAttribute("Countdown", activeGuest and math.max(activeGuestDeadline, 0) or math.max(countdown, 0))
    root:SetAttribute("StatusText", status)
    root:SetAttribute("NowServingText", nowServing)

    statusLabel.Text = status
    nowServingLabel.Text = "Now Serving: " .. nowServing
    countdownLabel.Text = countdownText
    queueCountLabel.Text = string.format("Players in Line: %d / %d", #queue, maxSlots)
end

local function repositionQueue()
    for index, queuedPlayer in ipairs(queue) do
        local slotPart = queueSlots[index]
        if slotPart then
            pivotPlayerToPart(queuedPlayer, slotPart)
        end
    end

    updateEveryoneState()
    updateBoard()
end

local function removeFromQueue(player)
    local queueIndex = findQueueIndex(player)
    if queueIndex then
        table.remove(queue, queueIndex)
    end

    if activeGuest == player then
        activeGuest = nil
        activeGuestDeadline = 0
        meetPrompt.Enabled = false
    end

    repositionQueue()
end

local function celebrate()
    if not confetti then
        return
    end

    confetti:Emit(60)
end

local function finishMeeting(player, message, rewardMultiplier)
    if activeGuest ~= player then
        return
    end

    local appliedReward = rewardAmount
    if rewardMultiplier then
        appliedReward = math.floor(rewardAmount * rewardMultiplier)
    end

    meetPrompt.Enabled = false
    activeGuest = nil
    activeGuestDeadline = 0

    if appliedReward > 0 then
        awardPlayer(player, appliedReward)
        celebrate()
    end

    pivotPlayerToPart(player, exitPad)
    bubbleChat(message)

    countdown = math.min(countdown, 2)
    repositionQueue()
end

local function advanceQueue()
    if activeGuest or #queue == 0 then
        updateBoard()
        return
    end

    activeGuest = table.remove(queue, 1)
    activeGuestDeadline = meetingTimeout
    pivotPlayerToPart(activeGuest, meetSpot)
    meetPrompt.Enabled = true
    bubbleChat("Next! Step up and say hi.")

    updateEveryoneState()
    updateBoard(string.format("%s reached the front of the line.", activeGuest.Name))
end

joinPrompt.Triggered:Connect(function(player)
    if player == activeGuest or findQueueIndex(player) then
        updateBoard(player.Name .. " is already part of the line.")
        return
    end

    if #queue >= math.min(maxSlots, #queueSlots) then
        updateBoard("Line is full. Wait for the queue to move.")
        return
    end

    table.insert(queue, player)
    countdown = math.min(countdown, 3)
    pivotPlayerToPart(player, queueSlots[#queue])
    bubbleChat(player.Name .. " joined the line.")
    repositionQueue()
end)

meetPrompt.Triggered:Connect(function(player)
    if player ~= activeGuest then
        updateBoard(player.Name .. " cut the line and got bounced.")
        return
    end

    finishMeeting(
        player,
        string.format("Thanks for waiting, %s. Emergency meeting approved.", player.Name),
        1
    )
end)

Players.PlayerRemoving:Connect(function(player)
    removeFromQueue(player)
end)

Players.PlayerAdded:Connect(function(player)
    updatePlayerState(player, 0, false)
    player.CharacterAdded:Connect(function()
        task.wait(0.35)
        if activeGuest == player then
            pivotPlayerToPart(player, meetSpot)
        else
            local queueIndex = findQueueIndex(player)
            local slotPart = queueIndex and queueSlots[queueIndex]
            if slotPart then
                pivotPlayerToPart(player, slotPart)
            end
        end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    updatePlayerState(player, 0, false)
    player.CharacterAdded:Connect(function()
        task.wait(0.35)
        if activeGuest == player then
            pivotPlayerToPart(player, meetSpot)
        else
            local queueIndex = findQueueIndex(player)
            local slotPart = queueIndex and queueSlots[queueIndex]
            if slotPart then
                pivotPlayerToPart(player, slotPart)
            end
        end
    end)
end

updateBoard()
meetPrompt.Enabled = false

task.spawn(function()
    while root.Parent and root:GetAttribute("SessionId") == sessionId do
        task.wait(1)

        if activeGuest then
            activeGuestDeadline -= 1
            if activeGuestDeadline <= 0 then
                finishMeeting(
                    activeGuest,
                    "The crewmate waved politely and sent the next guest forward.",
                    0.4
                )
            else
                updateBoard()
            end
        elseif #queue > 0 then
            countdown -= 1
            if countdown <= 0 then
                countdown = advanceInterval
                advanceQueue()
            else
                updateBoard()
            end
        else
            countdown = advanceInterval
            updateBoard()
        end
    end
end)
]=]

local clientSource = [=[
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local root = Workspace:WaitForChild("LineMeetGame")

local screenGui = playerGui:FindFirstChild("LineMeetHud")
if screenGui then
    screenGui:Destroy()
end

screenGui = Instance.new("ScreenGui")
screenGui.Name = "LineMeetHud"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 18
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.fromScale(0.5, 0.03)
panel.Size = UDim2.new(0, 440, 0, 92)
panel.BackgroundColor3 = Color3.fromRGB(25, 29, 38)
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(214, 50, 51)
stroke.Thickness = 2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.new(1, -36, 0, 24)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(248, 249, 252)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Line To Meet Red Crewmate"
title.Parent = panel

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(18, 40)
status.Size = UDim2.new(1, -36, 0, 18)
status.Font = Enum.Font.Gotham
status.TextSize = 15
status.TextColor3 = Color3.fromRGB(211, 221, 235)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Join the line to start."
status.Parent = panel

local detail = Instance.new("TextLabel")
detail.BackgroundTransparency = 1
detail.Position = UDim2.fromOffset(18, 60)
detail.Size = UDim2.new(1, -36, 0, 18)
detail.Font = Enum.Font.GothamBold
detail.TextSize = 16
detail.TextColor3 = Color3.fromRGB(177, 243, 255)
detail.TextXAlignment = Enum.TextXAlignment.Left
detail.Text = "Waiting for queue data..."
detail.Parent = panel

local function refresh()
    local queuePosition = player:GetAttribute("LineMeetPosition") or 0
    local isMeeting = player:GetAttribute("LineMeetMeetingActive") == true
    local queueCount = root:GetAttribute("QueueCount") or 0
    local countdown = root:GetAttribute("Countdown") or 0
    local statusText = root:GetAttribute("StatusText") or "Join the line to meet Red Crewmate."
    local rewardAmount = root:GetAttribute("RewardAmount") or 35

    status.Text = statusText

    if isMeeting then
        detail.Text = string.format("You made it. Say hi to Red Crewmate for %d reward.", rewardAmount)
        detail.TextColor3 = Color3.fromRGB(255, 219, 115)
    elseif queuePosition > 0 then
        detail.Text = string.format("You are #%d in line. Queue size: %d. Next move in %ss.", queuePosition, queueCount, countdown)
        detail.TextColor3 = Color3.fromRGB(177, 243, 255)
    else
        detail.Text = string.format("Use the Join Line prompt. Reward at the front: %d.", rewardAmount)
        detail.TextColor3 = Color3.fromRGB(163, 241, 180)
    end
end

player:GetAttributeChangedSignal("LineMeetPosition"):Connect(refresh)
player:GetAttributeChangedSignal("LineMeetMeetingActive"):Connect(refresh)
root:GetAttributeChangedSignal("QueueCount"):Connect(refresh)
root:GetAttributeChangedSignal("Countdown"):Connect(refresh)
root:GetAttributeChangedSignal("StatusText"):Connect(refresh)

refresh()
]=]

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
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

local function makeSurfaceBoard(parent, name, size, cframe)
    local board = makePart(parent, name, size, cframe, {
        Color = Color3.fromRGB(26, 30, 40),
        Material = Enum.Material.SmoothPlastic,
    })

    local gui = Instance.new("SurfaceGui")
    gui.Name = name .. "Gui"
    gui.Face = Enum.NormalId.Front
    gui.CanvasSize = Vector2.new(900, 540)
    gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    gui.Parent = board

    return board, gui
end

local function makeBoardLabel(parent, name, position, size, text, font, textSize, textColor)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Position = position
    label.Size = size
    label.Font = font
    label.Text = text
    label.TextColor3 = textColor
    label.TextScaled = false
    label.TextSize = textSize
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function makeCylinder(parent, name, size, cframe, color)
    local part = makePart(parent, name, size, cframe, {
        Color = color,
        Material = Enum.Material.Metal,
    })
    part.Shape = Enum.PartType.Cylinder
    return part
end

local function createBarrier(parent, leftPosition, rightPosition)
    local postColor = Color3.fromRGB(210, 216, 226)
    local ropeColor = Color3.fromRGB(214, 50, 51)

    local leftPost = makeCylinder(parent, "LeftPost", Vector3.new(0.8, 3.2, 0.8), CFrame.new(leftPosition) * CFrame.Angles(0, 0, math.rad(90)), postColor)
    local rightPost = makeCylinder(parent, "RightPost", Vector3.new(0.8, 3.2, 0.8), CFrame.new(rightPosition) * CFrame.Angles(0, 0, math.rad(90)), postColor)

    local midpoint = (leftPosition + rightPosition) * 0.5
    local length = (rightPosition - leftPosition).Magnitude
    local rope = makePart(parent, "Rope", Vector3.new(length, 0.22, 0.22), CFrame.lookAt(midpoint, rightPosition) * CFrame.new(0, 1.4, 0), {
        Color = ropeColor,
        Material = Enum.Material.Neon,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
    })
    rope.Shape = Enum.PartType.Cylinder

    return leftPost, rightPost, rope
end

local function createCrewmateRig(parent, basePosition)
    local rig = Instance.new("Model")
    rig.Name = "CrewmateRig"
    rig.Parent = parent

    local root = makePart(rig, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(basePosition + Vector3.new(0, 4.2, 0)), {
        Transparency = 1,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
    })

    makePart(rig, "Body", Vector3.new(4.4, 5.1, 3.5), root.CFrame, {
        Color = Color3.fromRGB(194, 41, 46),
        Material = Enum.Material.SmoothPlastic,
    })

    makePart(rig, "Head", Vector3.new(3.8, 1.9, 3.2), root.CFrame * CFrame.new(0, 2.45, -0.05), {
        Color = Color3.fromRGB(194, 41, 46),
        Material = Enum.Material.SmoothPlastic,
    })

    makePart(rig, "Backpack", Vector3.new(1.4, 3.2, 2.5), root.CFrame * CFrame.new(0, 0.1, -2.5), {
        Color = Color3.fromRGB(155, 29, 35),
        Material = Enum.Material.SmoothPlastic,
    })

    makePart(rig, "Visor", Vector3.new(2.6, 1.5, 1.2), root.CFrame * CFrame.new(0.55, 0.8, 2.35), {
        Color = Color3.fromRGB(177, 243, 255),
        Material = Enum.Material.Glass,
    })

    makePart(rig, "LeftLeg", Vector3.new(1.45, 2.2, 1.55), root.CFrame * CFrame.new(-0.95, -3.4, 0), {
        Color = Color3.fromRGB(137, 22, 28),
        Material = Enum.Material.SmoothPlastic,
    })

    makePart(rig, "RightLeg", Vector3.new(1.45, 2.2, 1.55), root.CFrame * CFrame.new(0.95, -3.4, 0), {
        Color = Color3.fromRGB(137, 22, 28),
        Material = Enum.Material.SmoothPlastic,
    })

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = rig

    rig.PrimaryPart = root
    return rig
end

local function ensureScript(parent, className, scriptName, source)
    local existing = parent:FindFirstChild(scriptName)
    if existing then
        existing:Destroy()
    end

    local scriptObject = Instance.new(className)
    scriptObject.Name = scriptName
    scriptObject.Source = source
    scriptObject.Parent = parent
    return scriptObject
end

local existingRoot = Workspace:FindFirstChild(ROOT_NAME)
if existingRoot then
    existingRoot:Destroy()
end

local existingRuntime = ServerScriptService:FindFirstChild(RUNTIME_SCRIPT_NAME)
if existingRuntime then
    existingRuntime:Destroy()
end

local starterScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if not starterScripts then
    error("StarterPlayerScripts is missing from this place.")
end

local existingClient = starterScripts:FindFirstChild(CLIENT_SCRIPT_NAME)
if existingClient then
    existingClient:Destroy()
end

local generatedSpawn = Workspace:FindFirstChild("GeneratedSpawn")
local origin = Vector3.new(0, 185, 0)
if generatedSpawn and generatedSpawn:IsA("BasePart") then
    origin = generatedSpawn.Position + Vector3.new(0, 0, 72)
end

local configModule = ReplicatedStorage:FindFirstChild("Config")
local currencyName = "MoonCredits"
if configModule and configModule:IsA("ModuleScript") then
    local ok, config = pcall(require, configModule)
    if ok and type(config) == "table" and type(config.CurrencyName) == "string" then
        currencyName = config.CurrencyName
    end
end

local root = Instance.new("Folder")
root.Name = ROOT_NAME
root.Parent = Workspace
root:SetAttribute("MaxSlots", 8)
root:SetAttribute("AdvanceInterval", 5)
root:SetAttribute("RewardAmount", 35)
root:SetAttribute("MeetingTimeout", 12)
root:SetAttribute("CurrencyName", currencyName)
root:SetAttribute("SessionId", tostring(os.clock()))
root:SetAttribute("StatusText", "Line open. Join the queue to meet Red Crewmate.")
root:SetAttribute("QueueCount", 0)
root:SetAttribute("Countdown", 5)

local floor = makePart(root, "Floor", Vector3.new(92, 1, 144), CFrame.new(origin), {
    Color = Color3.fromRGB(37, 43, 55),
    Material = Enum.Material.Metal,
})

local walkway = makePart(root, "Walkway", Vector3.new(26, 0.4, 100), CFrame.new(origin + Vector3.new(0, 0.75, 6)), {
    Color = Color3.fromRGB(66, 75, 93),
    Material = Enum.Material.SmoothPlastic,
})

local stripe = makePart(root, "WalkwayStripe", Vector3.new(4, 0.1, 100), walkway.CFrame + Vector3.new(0, 0.26, 0), {
    Color = Color3.fromRGB(214, 50, 51),
    Material = Enum.Material.Neon,
    CanCollide = false,
    CanTouch = false,
    CanQuery = false,
})

local startArch = Instance.new("Model")
startArch.Name = "StartArch"
startArch.Parent = root

makePart(startArch, "LeftPillar", Vector3.new(2.4, 10, 2.4), CFrame.new(origin + Vector3.new(-14, 5, 54)), {
    Color = Color3.fromRGB(214, 50, 51),
    Material = Enum.Material.SmoothPlastic,
})
makePart(startArch, "RightPillar", Vector3.new(2.4, 10, 2.4), CFrame.new(origin + Vector3.new(14, 5, 54)), {
    Color = Color3.fromRGB(214, 50, 51),
    Material = Enum.Material.SmoothPlastic,
})

local archSign, archGui = makeSurfaceBoard(startArch, "ArchSign", Vector3.new(24, 4.5, 0.8), CFrame.new(origin + Vector3.new(0, 9.3, 54)))
makeBoardLabel(
    archGui,
    "ArchTitle",
    UDim2.fromOffset(0, 0),
    UDim2.new(1, 0, 0, 110),
    "Emergency Meeting Queue",
    Enum.Font.GothamBlack,
    44,
    Color3.fromRGB(248, 249, 252)
)
makeBoardLabel(
    archGui,
    "ArchSubtitle",
    UDim2.fromOffset(0, 110),
    UDim2.new(1, 0, 0, 70),
    "Wait politely and meet Red Crewmate at the end.",
    Enum.Font.Gotham,
    24,
    Color3.fromRGB(200, 220, 245)
)

local joinPad = makePart(root, "JoinPad", Vector3.new(16, 1, 12), CFrame.new(origin + Vector3.new(0, 1, 54)), {
    Color = Color3.fromRGB(255, 208, 92),
    Material = Enum.Material.Neon,
})

local joinPrompt = Instance.new("ProximityPrompt")
joinPrompt.Name = "JoinPrompt"
joinPrompt.ActionText = "Join Line"
joinPrompt.ObjectText = "Queue Start"
joinPrompt.MaxActivationDistance = 12
joinPrompt.HoldDuration = 0.15
joinPrompt.RequiresLineOfSight = false
joinPrompt.Parent = joinPad

local joinBoard, joinBoardGui = makeSurfaceBoard(root, "JoinBoard", Vector3.new(16, 5, 0.8), CFrame.new(origin + Vector3.new(28, 4, 54)))
makeBoardLabel(
    joinBoardGui,
    "JoinTitle",
    UDim2.fromOffset(40, 30),
    UDim2.new(1, -80, 0, 64),
    "How To Play",
    Enum.Font.GothamBlack,
    34,
    Color3.fromRGB(248, 249, 252)
)
makeBoardLabel(
    joinBoardGui,
    "JoinBody",
    UDim2.fromOffset(40, 106),
    UDim2.new(1, -80, 0, 220),
    "1. Join the line.\n2. Wait for each shuffle.\n3. Say hi to Red Crewmate.\n4. Grab your reward and exit.",
    Enum.Font.Gotham,
    24,
    Color3.fromRGB(217, 226, 239)
)

local queueBoard, queueBoardGui = makeSurfaceBoard(root, "QueueBoard", Vector3.new(20, 8, 0.8), CFrame.new(origin + Vector3.new(-30, 5, 16)))
queueBoardGui.Name = "QueueBoardGui"
makeBoardLabel(
    queueBoardGui,
    "TitleLabel",
    UDim2.fromOffset(42, 28),
    UDim2.new(1, -84, 0, 60),
    "Queue Status",
    Enum.Font.GothamBlack,
    38,
    Color3.fromRGB(248, 249, 252)
)
makeBoardLabel(
    queueBoardGui,
    "StatusLabel",
    UDim2.fromOffset(42, 102),
    UDim2.new(1, -84, 0, 120),
    "Line open. Join the queue to meet Red Crewmate.",
    Enum.Font.Gotham,
    24,
    Color3.fromRGB(217, 226, 239)
)
makeBoardLabel(
    queueBoardGui,
    "NowServingLabel",
    UDim2.fromOffset(42, 234),
    UDim2.new(1, -84, 0, 48),
    "Now Serving: Nobody yet",
    Enum.Font.GothamBold,
    26,
    Color3.fromRGB(255, 219, 115)
)
makeBoardLabel(
    queueBoardGui,
    "CountdownLabel",
    UDim2.fromOffset(42, 292),
    UDim2.new(1, -84, 0, 48),
    "Next shuffle begins once someone joins.",
    Enum.Font.GothamBold,
    24,
    Color3.fromRGB(177, 243, 255)
)
makeBoardLabel(
    queueBoardGui,
    "QueueCountLabel",
    UDim2.fromOffset(42, 350),
    UDim2.new(1, -84, 0, 48),
    "Players in Line: 0 / 8",
    Enum.Font.GothamBold,
    24,
    Color3.fromRGB(163, 241, 180)
)

local slotsFolder = Instance.new("Folder")
slotsFolder.Name = "QueueSlots"
slotsFolder.Parent = root

local slotLayout = {
    Vector3.new(0, 1.1, 38),
    Vector3.new(10, 1.1, 26),
    Vector3.new(-10, 1.1, 26),
    Vector3.new(-10, 1.1, 14),
    Vector3.new(10, 1.1, 14),
    Vector3.new(10, 1.1, 2),
    Vector3.new(-10, 1.1, 2),
    Vector3.new(0, 1.1, -10),
}

for index, offset in ipairs(slotLayout) do
    local slotPart = makePart(slotsFolder, string.format("LineSlot%02d", index), Vector3.new(12, 0.6, 8), CFrame.new(origin + offset), {
        Color = (index % 2 == 0) and Color3.fromRGB(86, 98, 120) or Color3.fromRGB(74, 84, 103),
        Material = Enum.Material.SmoothPlastic,
    })

    local slotGui = Instance.new("SurfaceGui")
    slotGui.Face = Enum.NormalId.Top
    slotGui.CanvasSize = Vector2.new(420, 260)
    slotGui.Parent = slotPart

    local slotLabel = Instance.new("TextLabel")
    slotLabel.Size = UDim2.fromScale(1, 1)
    slotLabel.BackgroundTransparency = 1
    slotLabel.Font = Enum.Font.GothamBlack
    slotLabel.TextScaled = true
    slotLabel.TextColor3 = Color3.fromRGB(237, 241, 248)
    slotLabel.Text = string.format("#%d", index)
    slotLabel.Parent = slotGui
end

local leftBarrierX = -17
local rightBarrierX = 17
local barrierRows = { 38, 26, 14, 2, -10 }
for _, zOffset in ipairs(barrierRows) do
    createBarrier(root, origin + Vector3.new(leftBarrierX, 0.1, zOffset), origin + Vector3.new(leftBarrierX, 0.1, zOffset - 8))
    createBarrier(root, origin + Vector3.new(rightBarrierX, 0.1, zOffset), origin + Vector3.new(rightBarrierX, 0.1, zOffset - 8))
end

local stage = Instance.new("Model")
stage.Name = "CrewmateStage"
stage.Parent = root

makePart(stage, "StageBase", Vector3.new(32, 2, 22), CFrame.new(origin + Vector3.new(0, 1.4, -32)), {
    Color = Color3.fromRGB(30, 35, 47),
    Material = Enum.Material.Metal,
})
makePart(stage, "StageTrim", Vector3.new(28, 0.3, 18), CFrame.new(origin + Vector3.new(0, 2.6, -32)), {
    Color = Color3.fromRGB(214, 50, 51),
    Material = Enum.Material.Neon,
    CanCollide = false,
})
local meetSpot = makePart(root, "MeetSpot", Vector3.new(8, 1, 8), CFrame.new(origin + Vector3.new(0, 3.1, -24)), {
    Color = Color3.fromRGB(126, 208, 255),
    Material = Enum.Material.Neon,
})
local stageSign, stageGui = makeSurfaceBoard(stage, "StageSign", Vector3.new(18, 4.5, 0.8), CFrame.new(origin + Vector3.new(0, 7.6, -40)))
makeBoardLabel(
    stageGui,
    "StageTitle",
    UDim2.fromOffset(0, 22),
    UDim2.new(1, 0, 0, 72),
    "Meet Red Crewmate",
    Enum.Font.GothamBlack,
    40,
    Color3.fromRGB(248, 249, 252)
)
makeBoardLabel(
    stageGui,
    "StageBody",
    UDim2.fromOffset(40, 110),
    UDim2.new(1, -80, 0, 120),
    "When you reach the front, step onto the blue pad and use the prompt.",
    Enum.Font.Gotham,
    24,
    Color3.fromRGB(217, 226, 239)
)

createCrewmateRig(stage, origin + Vector3.new(0, 2.6, -33))

local meetPromptPart = makePart(stage, "MeetPromptPart", Vector3.new(8, 8, 8), CFrame.new(origin + Vector3.new(0, 6.3, -24)), {
    Transparency = 1,
    CanCollide = false,
    CanTouch = false,
    CanQuery = false,
})

local meetPrompt = Instance.new("ProximityPrompt")
meetPrompt.Name = "MeetPrompt"
meetPrompt.ActionText = "Say Hi"
meetPrompt.ObjectText = "Red Crewmate"
meetPrompt.MaxActivationDistance = 10
meetPrompt.HoldDuration = 0.15
meetPrompt.RequiresLineOfSight = false
meetPrompt.Enabled = false
meetPrompt.Parent = meetPromptPart

local confettiAnchor = makePart(stage, "ConfettiAnchor", Vector3.new(1, 1, 1), CFrame.new(origin + Vector3.new(0, 10, -32)), {
    Transparency = 1,
    CanCollide = false,
    CanTouch = false,
    CanQuery = false,
})

local confetti = Instance.new("ParticleEmitter")
confetti.Name = "Confetti"
confetti.Texture = "rbxasset://textures/particles/sparkles_main.dds"
confetti.Rate = 0
confetti.Lifetime = NumberRange.new(1.2, 1.8)
confetti.Speed = NumberRange.new(12, 16)
confetti.SpreadAngle = Vector2.new(180, 180)
confetti.Rotation = NumberRange.new(0, 360)
confetti.RotSpeed = NumberRange.new(-40, 40)
confetti.LightEmission = 0.7
confetti.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(214, 50, 51)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 219, 115)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(126, 208, 255)),
})
confetti.Parent = confettiAnchor

local exitPad = makePart(root, "ExitPad", Vector3.new(14, 1, 10), CFrame.new(origin + Vector3.new(0, 1, -52)), {
    Color = Color3.fromRGB(163, 241, 180),
    Material = Enum.Material.Neon,
})
local exitBoard, exitGui = makeSurfaceBoard(root, "ExitBoard", Vector3.new(12, 4.5, 0.8), CFrame.new(origin + Vector3.new(18, 4.1, -52)))
makeBoardLabel(
    exitGui,
    "ExitTitle",
    UDim2.fromOffset(0, 20),
    UDim2.new(1, 0, 0, 60),
    "Reward Exit",
    Enum.Font.GothamBlack,
    36,
    Color3.fromRGB(248, 249, 252)
)
makeBoardLabel(
    exitGui,
    "ExitBody",
    UDim2.fromOffset(28, 98),
    UDim2.new(1, -56, 0, 120),
    "Players who finish the meeting get dropped here with bonus MoonCredits.",
    Enum.Font.Gotham,
    22,
    Color3.fromRGB(217, 226, 239)
)

local spawnLocation = root:FindFirstChild("LineSpawn")
if spawnLocation then
    spawnLocation:Destroy()
end

spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "LineSpawn"
spawnLocation.Size = Vector3.new(10, 1, 10)
spawnLocation.CFrame = CFrame.new(origin + Vector3.new(0, 3, 66))
spawnLocation.Anchored = true
spawnLocation.TopSurface = Enum.SurfaceType.Smooth
spawnLocation.BottomSurface = Enum.SurfaceType.Smooth
spawnLocation.Material = Enum.Material.Neon
spawnLocation.Color = Color3.fromRGB(177, 243, 255)
spawnLocation.Neutral = true
spawnLocation.CanCollide = true
spawnLocation.Parent = root

ensureScript(ServerScriptService, "Script", RUNTIME_SCRIPT_NAME, runtimeSource)
ensureScript(starterScripts, "LocalScript", CLIENT_SCRIPT_NAME, clientSource)

print(string.format(
    "[RNGaming] Generated %s with %d queue pads, runtime scripts, and spawn at (%.1f, %.1f, %.1f).",
    ROOT_NAME,
    #slotLayout,
    spawnLocation.Position.X,
    spawnLocation.Position.Y,
    spawnLocation.Position.Z
))
