local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Chat = game:GetService("Chat")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local LineMeetGameService = {}

local ROOT_NAME = "LineMeetGame"
local ADVANCE_INTERVAL = 5
local REWARD_AMOUNT = 35
local MEETING_TIMEOUT = 12

local started = false
local queue = {}
local activeGuest = nil
local countdown = ADVANCE_INTERVAL
local activeGuestDeadline = 0

local root = nil
local joinPrompt = nil
local meetPrompt = nil
local meetSpot = nil
local exitPad = nil
local crewmateHead = nil
local confetti = nil
local queueSlots = {}

local function findQueueIndex(player)
    for index, queuedPlayer in ipairs(queue) do
        if queuedPlayer == player then
            return index
        end
    end

    return nil
end

local function getWallet(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return nil
    end

    return leaderstats:FindFirstChild(Config.CurrencyName)
end

local function awardPlayer(player, amount)
    local wallet = getWallet(player)
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
        updatePlayerState(player, findQueueIndex(player), activeGuest == player)
    end
end

local function updateWorldState(statusText)
    local status = statusText
    if not status or status == "" then
        if activeGuest then
            status = "Red Crewmate is greeting the front of the line."
        elseif #queue > 0 then
            status = "Hold your place. The queue is moving."
        else
            status = "Join the line to meet Red Crewmate."
        end
    end

    root:SetAttribute("QueueCount", #queue)
    root:SetAttribute("Countdown", activeGuest and activeGuestDeadline or countdown)
    root:SetAttribute("StatusText", status)
    root:SetAttribute("RewardAmount", REWARD_AMOUNT)
end

local function repositionQueue()
    for index, queuedPlayer in ipairs(queue) do
        local slotPart = queueSlots[index]
        if slotPart then
            pivotPlayerToPart(queuedPlayer, slotPart)
        end
    end

    updateEveryoneState()
    updateWorldState()
end

local function ensureConfetti()
    if confetti then
        return
    end

    local stage = root:FindFirstChild("CrewmateStage")
    local anchor = stage and stage:FindFirstChild("ConfettiAnchor")
    if not anchor or not anchor:IsA("BasePart") then
        return
    end

    confetti = anchor:FindFirstChildOfClass("ParticleEmitter")
    if confetti then
        return
    end

    confetti = Instance.new("ParticleEmitter")
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
    confetti.Parent = anchor
end

local function removeFromQueue(player)
    local queueIndex = findQueueIndex(player)
    if queueIndex then
        table.remove(queue, queueIndex)
    end

    if activeGuest == player then
        activeGuest = nil
        activeGuestDeadline = 0
        if meetPrompt then
            meetPrompt.Enabled = false
        end
    end

    repositionQueue()
end

local function finishMeeting(player, message, rewardMultiplier)
    if activeGuest ~= player then
        return
    end

    local appliedReward = REWARD_AMOUNT
    if rewardMultiplier then
        appliedReward = math.floor(REWARD_AMOUNT * rewardMultiplier)
    end

    activeGuest = nil
    activeGuestDeadline = 0
    if meetPrompt then
        meetPrompt.Enabled = false
    end

    if appliedReward > 0 then
        awardPlayer(player, appliedReward)
        if confetti then
            confetti:Emit(60)
        end
    end

    if exitPad then
        pivotPlayerToPart(player, exitPad)
    end

    bubbleChat(message)
    countdown = math.min(countdown, 2)
    repositionQueue()
end

local function advanceQueue()
    if activeGuest or #queue == 0 then
        updateWorldState()
        return
    end

    activeGuest = table.remove(queue, 1)
    activeGuestDeadline = MEETING_TIMEOUT

    if meetSpot then
        pivotPlayerToPart(activeGuest, meetSpot)
    end

    if meetPrompt then
        meetPrompt.Enabled = true
    end

    bubbleChat("Next! Step up and say hi.")
    updateEveryoneState()
    updateWorldState(string.format("%s reached the front of the line.", activeGuest.Name))
end

function LineMeetGameService.start()
    if started then
        return
    end

    started = true

    root = Workspace:WaitForChild(ROOT_NAME, 10)
    if not root then
        warn("[RNGaming] LineMeetGame model not found in Workspace.")
        return
    end

    local queueSlotsFolder = root:WaitForChild("QueueSlots", 10)
    joinPrompt = root:WaitForChild("JoinPad", 10) and root.JoinPad:FindFirstChild("JoinPrompt")
    meetSpot = root:WaitForChild("MeetSpot", 10)
    exitPad = root:WaitForChild("ExitPad", 10)

    local stage = root:WaitForChild("CrewmateStage", 10)
    local promptPart = stage and stage:FindFirstChild("MeetPromptPart")
    meetPrompt = promptPart and promptPart:FindFirstChild("MeetPrompt")

    local rig = stage and stage:FindFirstChild("CrewmateRig")
    crewmateHead = rig and rig:FindFirstChild("Head")

    if queueSlotsFolder then
        for _, child in ipairs(queueSlotsFolder:GetChildren()) do
            if child:IsA("BasePart") and child.Name:match("^LineSlot") then
                table.insert(queueSlots, child)
            end
        end

        table.sort(queueSlots, function(left, right)
            return left.Name < right.Name
        end)
    end

    if not joinPrompt or not meetPrompt or not meetSpot or not exitPad or #queueSlots == 0 then
        warn("[RNGaming] LineMeetGame is missing prompts, pads, or slots.")
        return
    end

    ensureConfetti()

    root:SetAttribute("QueueCount", 0)
    root:SetAttribute("Countdown", ADVANCE_INTERVAL)
    root:SetAttribute("RewardAmount", REWARD_AMOUNT)
    root:SetAttribute("StatusText", "Join the line to meet Red Crewmate.")

    meetPrompt.Enabled = false

    joinPrompt.Triggered:Connect(function(player)
        if player == activeGuest or findQueueIndex(player) then
            updateWorldState(player.Name .. " is already in line.")
            return
        end

        if #queue >= #queueSlots then
            updateWorldState("Line is full. Wait for the next shuffle.")
            return
        end

        table.insert(queue, player)
        countdown = math.min(countdown, 3)
        repositionQueue()
        bubbleChat(player.Name .. " joined the line.")
    end)

    meetPrompt.Triggered:Connect(function(player)
        if player ~= activeGuest then
            updateWorldState(player.Name .. " tried to skip the line.")
            return
        end

        finishMeeting(
            player,
            string.format("Thanks for waiting, %s. Emergency meeting approved.", player.Name),
            1
        )
    end)

    Players.PlayerRemoving:Connect(removeFromQueue)

    local function bindCharacterRespawn(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.35)

            if activeGuest == player then
                pivotPlayerToPart(player, meetSpot)
                return
            end

            local queueIndex = findQueueIndex(player)
            local slotPart = queueIndex and queueSlots[queueIndex]
            if slotPart then
                pivotPlayerToPart(player, slotPart)
            end
        end)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayerState(player, 0, false)
        bindCharacterRespawn(player)
    end

    Players.PlayerAdded:Connect(function(player)
        updatePlayerState(player, 0, false)
        bindCharacterRespawn(player)
    end)

    updateWorldState()

    task.spawn(function()
        while root and root.Parent do
            task.wait(1)

            if activeGuest then
                activeGuestDeadline -= 1
                if activeGuestDeadline <= 0 then
                    finishMeeting(
                        activeGuest,
                        "The crewmate waved politely and called the next guest.",
                        0.4
                    )
                else
                    updateWorldState()
                end
            elseif #queue > 0 then
                countdown -= 1
                if countdown <= 0 then
                    countdown = ADVANCE_INTERVAL
                    advanceQueue()
                else
                    updateWorldState()
                end
            else
                countdown = ADVANCE_INTERVAL
                updateWorldState()
            end
        end
    end)
end

return LineMeetGameService
