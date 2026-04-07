local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local root = Workspace:WaitForChild("ToolboxLineGame")

local existing = playerGui:FindFirstChild("ToolboxLineGameHud")
if existing then
    existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ToolboxLineGameHud"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 20
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.fromScale(0.5, 0.025)
panel.Size = UDim2.new(0, 620, 0, 112)
panel.BackgroundColor3 = Color3.fromRGB(18, 23, 30)
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(239, 183, 64)
stroke.Thickness = 2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.new(1, -36, 0, 26)
title.Font = Enum.Font.GothamBlack
title.TextColor3 = Color3.fromRGB(247, 248, 252)
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = root:GetAttribute("GameTitle") or "Prompt Pipeline Queue"
title.Parent = panel

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(18, 40)
status.Size = UDim2.new(1, -36, 0, 20)
status.Font = Enum.Font.Gotham
status.TextColor3 = Color3.fromRGB(210, 220, 235)
status.TextSize = 15
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

local detail = Instance.new("TextLabel")
detail.BackgroundTransparency = 1
detail.Position = UDim2.fromOffset(18, 64)
detail.Size = UDim2.new(1, -36, 0, 20)
detail.Font = Enum.Font.GothamBold
detail.TextColor3 = Color3.fromRGB(177, 243, 255)
detail.TextSize = 16
detail.TextXAlignment = Enum.TextXAlignment.Left
detail.Parent = panel

local balance = Instance.new("TextLabel")
balance.BackgroundTransparency = 1
balance.Position = UDim2.fromOffset(18, 86)
balance.Size = UDim2.new(1, -36, 0, 18)
balance.Font = Enum.Font.GothamBold
balance.TextColor3 = Color3.fromRGB(163, 241, 180)
balance.TextSize = 15
balance.TextXAlignment = Enum.TextXAlignment.Left
balance.Parent = panel

local walletConnection = nil

local function bindWallet()
    if walletConnection then
        walletConnection:Disconnect()
        walletConnection = nil
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    local wallet = leaderstats and leaderstats:FindFirstChild(root:GetAttribute("RewardCurrencyName") or "Tickets")
    if wallet then
        walletConnection = wallet:GetPropertyChangedSignal("Value"):Connect(function()
            balance.Text = string.format("Balance: %d %s", wallet.Value, wallet.Name)
        end)
        balance.Text = string.format("Balance: %d %s", wallet.Value, wallet.Name)
        return
    end

    balance.Text = "Balance: loading..."
end

local function refresh()
    local slot = player:GetAttribute("ToolboxLineSlot") or 0
    local income = player:GetAttribute("ToolboxLineIncome") or 0
    local advanceCost = player:GetAttribute("ToolboxLineAdvanceCost") or 0
    local statusText = root:GetAttribute("StatusText") or "Claim the back slot and start earning."
    local openSlots = root:GetAttribute("OpenSlots") or 0
    local capacity = root:GetAttribute("QueueCapacity") or 50
    local meetBonus = root:GetAttribute("MeetBonus") or 5000
    local titleText = root:GetAttribute("GameTitle") or "Prompt Pipeline Queue"
    local goalText = root:GetAttribute("GameGoalText") or "Move through the loop and reach the finale."
    local finaleRole = root:GetAttribute("FinaleRole") or "host"
    local currencyName = root:GetAttribute("RewardCurrencyName") or "Tickets"

    title.Text = titleText

    status.Text = string.format("%s  Open slots: %d / %d", statusText, openSlots, capacity)

    if slot <= 0 then
        detail.Text = goalText
        detail.TextColor3 = Color3.fromRGB(177, 243, 255)
    elseif slot == 1 then
        detail.Text = string.format("Front of line. Income: %d/s. Meet the %s for %d %s.", income, tostring(finaleRole), meetBonus, currencyName)
        detail.TextColor3 = Color3.fromRGB(255, 219, 115)
    else
        detail.Text = string.format("Slot #%d. Income: %d/s. Next move costs %d %s.", slot, income, advanceCost, currencyName)
        detail.TextColor3 = Color3.fromRGB(163, 241, 180)
    end

    bindWallet()
end

player:GetAttributeChangedSignal("ToolboxLineSlot"):Connect(refresh)
player:GetAttributeChangedSignal("ToolboxLineIncome"):Connect(refresh)
player:GetAttributeChangedSignal("ToolboxLineAdvanceCost"):Connect(refresh)
root:GetAttributeChangedSignal("StatusText"):Connect(refresh)
root:GetAttributeChangedSignal("OpenSlots"):Connect(refresh)
root:GetAttributeChangedSignal("QueueCapacity"):Connect(refresh)
root:GetAttributeChangedSignal("RewardCurrencyName"):Connect(refresh)
root:GetAttributeChangedSignal("MeetBonus"):Connect(refresh)
root:GetAttributeChangedSignal("GameTitle"):Connect(refresh)
root:GetAttributeChangedSignal("GameGoalText"):Connect(refresh)
root:GetAttributeChangedSignal("FinaleRole"):Connect(refresh)
player.ChildAdded:Connect(function(child)
    if child.Name == "leaderstats" then
        bindWallet()
    end
end)

refresh()
