local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local root = Workspace:WaitForChild("LineMeetGame")

local existingGui = playerGui:FindFirstChild("LineMeetHud")
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
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
        detail.Text = string.format("You made it. Say hi to Red Crewmate for %d credits.", rewardAmount)
        detail.TextColor3 = Color3.fromRGB(255, 219, 115)
    elseif queuePosition > 0 then
        detail.Text = string.format("You are #%d in line. Queue size: %d. Next move in %ss.", queuePosition, queueCount, countdown)
        detail.TextColor3 = Color3.fromRGB(177, 243, 255)
    else
        detail.Text = string.format("Use the Join Line prompt. Reward at the front: %d credits.", rewardAmount)
        detail.TextColor3 = Color3.fromRGB(163, 241, 180)
    end
end

player:GetAttributeChangedSignal("LineMeetPosition"):Connect(refresh)
player:GetAttributeChangedSignal("LineMeetMeetingActive"):Connect(refresh)
root:GetAttributeChangedSignal("QueueCount"):Connect(refresh)
root:GetAttributeChangedSignal("Countdown"):Connect(refresh)
root:GetAttributeChangedSignal("StatusText"):Connect(refresh)
root:GetAttributeChangedSignal("RewardAmount"):Connect(refresh)

refresh()
