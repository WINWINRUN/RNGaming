local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TycoonHud"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 18, 1, -18)
panel.Size = UDim2.new(0.29, 0, 0.74, 0)
panel.BackgroundColor3 = Color3.fromRGB(19, 23, 31)
panel.BorderSizePixel = 0
panel.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(320, 360)
sizeConstraint.MaxSize = Vector2.new(430, 620)
sizeConstraint.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(214, 50, 51)
stroke.Thickness = 2
stroke.Parent = panel

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 74)
header.BackgroundColor3 = Color3.fromRGB(194, 41, 46)
header.BorderSizePixel = 0
header.Parent = panel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 18)
headerCorner.Parent = header

local headerMask = Instance.new("Frame")
headerMask.Position = UDim2.new(0, 0, 1, -18)
headerMask.Size = UDim2.new(1, 0, 0, 18)
headerMask.BackgroundColor3 = header.BackgroundColor3
headerMask.BorderSizePixel = 0
headerMask.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Position = UDim2.fromOffset(18, 12)
titleLabel.Size = UDim2.new(1, -36, 0, 28)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "Among Us Tycoon"
titleLabel.TextColor3 = Color3.fromRGB(248, 249, 252)
titleLabel.TextSize = 24
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local subTitleLabel = Instance.new("TextLabel")
subTitleLabel.Position = UDim2.fromOffset(18, 42)
subTitleLabel.Size = UDim2.new(1, -36, 0, 18)
subTitleLabel.BackgroundTransparency = 1
subTitleLabel.Font = Enum.Font.Gotham
subTitleLabel.Text = "Claim a plot, build the ship, collect the cash."
subTitleLabel.TextColor3 = Color3.fromRGB(255, 232, 233)
subTitleLabel.TextSize = 13
subTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subTitleLabel.Parent = header

local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.Position = UDim2.fromOffset(14, 84)
body.Size = UDim2.new(1, -28, 1, -98)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.CanvasSize = UDim2.fromOffset(0, 0)
body.ScrollBarThickness = 6
body.Parent = panel

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Padding = UDim.new(0, 12)
bodyLayout.Parent = body

local bodyPadding = Instance.new("UIPadding")
bodyPadding.PaddingBottom = UDim.new(0, 8)
bodyPadding.Parent = body

local summaryCard = Instance.new("Frame")
summaryCard.Name = "SummaryCard"
summaryCard.Size = UDim2.new(1, 0, 0, 154)
summaryCard.BackgroundColor3 = Color3.fromRGB(29, 34, 45)
summaryCard.BorderSizePixel = 0
summaryCard.Parent = body

local summaryCorner = Instance.new("UICorner")
summaryCorner.CornerRadius = UDim.new(0, 16)
summaryCorner.Parent = summaryCard

local summaryStroke = Instance.new("UIStroke")
summaryStroke.Color = Color3.fromRGB(72, 86, 110)
summaryStroke.Transparency = 0.2
summaryStroke.Parent = summaryCard

local function makeSummaryLabel(yOffset, size, color, font)
    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(16, yOffset)
    label.Size = UDim2.new(1, -32, 0, size)
    label.BackgroundTransparency = 1
    label.Font = font or Enum.Font.GothamBold
    label.TextColor3 = color
    label.TextSize = size
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = summaryCard
    return label
end

local ownedPlotLabel = makeSummaryLabel(14, 18, Color3.fromRGB(247, 248, 252), Enum.Font.GothamBlack)
local walletLabel = makeSummaryLabel(42, 16, Color3.fromRGB(177, 243, 255))
local incomeLabel = makeSummaryLabel(66, 16, Color3.fromRGB(163, 241, 180))
local pendingLabel = makeSummaryLabel(90, 16, Color3.fromRGB(255, 214, 120))
local nextUpgradeLabel = makeSummaryLabel(114, 15, Color3.fromRGB(215, 223, 236), Enum.Font.Gotham)
nextUpgradeLabel.TextWrapped = true

local summaryActionButton = Instance.new("TextButton")
summaryActionButton.Name = "SummaryAction"
summaryActionButton.AnchorPoint = Vector2.new(1, 1)
summaryActionButton.Position = UDim2.new(1, -16, 1, -14)
summaryActionButton.Size = UDim2.fromOffset(132, 34)
summaryActionButton.AutoButtonColor = true
summaryActionButton.BorderSizePixel = 0
summaryActionButton.Font = Enum.Font.GothamBold
summaryActionButton.Text = "Claim A Plot"
summaryActionButton.TextSize = 14
summaryActionButton.Parent = summaryCard

local summaryActionCorner = Instance.new("UICorner")
summaryActionCorner.CornerRadius = UDim.new(0, 12)
summaryActionCorner.Parent = summaryActionButton

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, 0, 0, 46)
hintLabel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
hintLabel.BorderSizePixel = 0
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextColor3 = Color3.fromRGB(210, 219, 231)
hintLabel.TextSize = 14
hintLabel.TextWrapped = true
hintLabel.TextXAlignment = Enum.TextXAlignment.Left
hintLabel.TextYAlignment = Enum.TextYAlignment.Center
hintLabel.Parent = body

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 14)
hintCorner.Parent = hintLabel

local function makeSectionTitle(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(247, 248, 252)
    label.TextSize = 17
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = body
    return label
end

makeSectionTitle("Upgrade Queue")

local upgradesContainer = Instance.new("Frame")
upgradesContainer.Size = UDim2.new(1, 0, 0, 60)
upgradesContainer.BackgroundTransparency = 1
upgradesContainer.Parent = body

local upgradesLayout = Instance.new("UIListLayout")
upgradesLayout.Padding = UDim.new(0, 8)
upgradesLayout.Parent = upgradesContainer

makeSectionTitle("Plot Board")

local plotsContainer = Instance.new("Frame")
plotsContainer.Size = UDim2.new(1, 0, 0, 60)
plotsContainer.BackgroundTransparency = 1
plotsContainer.Parent = body

local plotsLayout = Instance.new("UIListLayout")
plotsLayout.Padding = UDim.new(0, 8)
plotsLayout.Parent = plotsContainer

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 16)
toast.Size = UDim2.new(0, 420, 0, 44)
toast.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
toast.BackgroundTransparency = 0.12
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamBold
toast.TextColor3 = Color3.fromRGB(247, 248, 252)
toast.TextSize = 18
toast.TextTransparency = 1
toast.Visible = false
toast.Parent = screenGui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 14)
toastCorner.Parent = toast

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(194, 41, 46)
toastStroke.Thickness = 2
toastStroke.Transparency = 1
toastStroke.Parent = toast

local showToast
local toastToken = 0
local latestState = nil
local actionRemote = nil
local requestStateRemote = nil

local function updateCanvas(frame, layout)
    frame.Size = UDim2.new(1, 0, 0, math.max(layout.AbsoluteContentSize.Y, 1))
end

bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    body.CanvasSize = UDim2.fromOffset(0, bodyLayout.AbsoluteContentSize.Y + 18)
end)

upgradesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    updateCanvas(upgradesContainer, upgradesLayout)
end)

plotsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    updateCanvas(plotsContainer, plotsLayout)
end)

local function clearGenerated(container)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function createCard(parent, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = Color3.fromRGB(29, 34, 45)
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 14)
    cardCorner.Parent = card

    return card
end

local function setButtonState(button, text, enabled, backgroundColor, textColor)
    button.Text = text
    button.Active = enabled
    button.Selectable = enabled
    button.AutoButtonColor = enabled
    button.BackgroundColor3 = backgroundColor
    button.TextColor3 = textColor
end

local function createActionButton(parent, size, position)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.Parent = parent

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 12)
    buttonCorner.Parent = button

    return button
end

local function requestAction(actionName, payload)
    if not actionRemote then
        showToast({
            Text = "Tycoon controls are still connecting.",
            Color = Color3.fromRGB(255, 214, 120),
        })
        return
    end

    payload = payload or {}
    payload.Action = actionName
    actionRemote:FireServer(payload)
end

function showToast(payload)
    toastToken += 1
    local token = toastToken

    toast.Text = payload.Text or ""
    toast.TextColor3 = payload.Color or Color3.fromRGB(247, 248, 252)
    toast.Visible = true
    toast.TextTransparency = 1
    toast.BackgroundTransparency = 0.35
    toastStroke.Transparency = 1

    TweenService:Create(toast, TweenInfo.new(0.18), {
        TextTransparency = 0,
        BackgroundTransparency = 0.12,
    }):Play()
    TweenService:Create(toastStroke, TweenInfo.new(0.18), {
        Transparency = 0.15,
    }):Play()

    task.delay(2.8, function()
        if token ~= toastToken then
            return
        end

        TweenService:Create(toast, TweenInfo.new(0.22), {
            TextTransparency = 1,
            BackgroundTransparency = 0.35,
        }):Play()
        TweenService:Create(toastStroke, TweenInfo.new(0.22), {
            Transparency = 1,
        }):Play()

        task.delay(0.25, function()
            if token == toastToken then
                toast.Visible = false
            end
        end)
    end)
end

local function renderState(state)
    latestState = state
    ownedPlotLabel.Text = state.OwnedPlotName and ("Plot: " .. state.OwnedPlotName) or "Plot: Unclaimed"
    walletLabel.Text = string.format("%s: %d", state.CurrencyName or "Credits", state.WalletBalance or 0)
    incomeLabel.Text = string.format("Income / sec: %d", state.IncomePerSecond or 0)
    pendingLabel.Text = string.format("Pending cash: %d", state.PendingCash or 0)

    if state.NextUpgrade then
        nextUpgradeLabel.Text = string.format(
            "Next upgrade: %s (%d %s, +%d / sec)",
            state.NextUpgrade.DisplayName or "Upgrade",
            state.NextUpgrade.Cost or 0,
            state.CurrencyName or "Credits",
            state.NextUpgrade.IncomePerSecond or 0
        )
    else
        nextUpgradeLabel.Text = state.OwnedPlotName and "Next upgrade: Plot completed." or "Next upgrade: Claim a plot first."
    end

    hintLabel.Text = "  " .. (state.HintText or "Claim a plot to begin.")

    if state.OwnedPlotId and (state.PendingCash or 0) > 0 then
        setButtonState(
            summaryActionButton,
            string.format("Collect %d", state.PendingCash or 0),
            true,
            Color3.fromRGB(94, 222, 230),
            Color3.fromRGB(16, 24, 30)
        )
    elseif state.OwnedPlotId then
        setButtonState(
            summaryActionButton,
            "Claimed Plot",
            false,
            Color3.fromRGB(70, 78, 94),
            Color3.fromRGB(229, 235, 244)
        )
    else
        setButtonState(
            summaryActionButton,
            "Claim A Plot",
            false,
            Color3.fromRGB(70, 78, 94),
            Color3.fromRGB(229, 235, 244)
        )
    end

    clearGenerated(upgradesContainer)
    for _, upgrade in ipairs(state.OwnedPlotUpgrades or {}) do
        local card = createCard(upgradesContainer, 58)

        local accent = Instance.new("Frame")
        accent.Position = UDim2.fromOffset(12, 10)
        accent.Size = UDim2.fromOffset(12, 38)
        accent.BorderSizePixel = 0
        accent.BackgroundColor3 = upgrade.Purchased and Color3.fromRGB(92, 198, 116)
            or (upgrade.Available and Color3.fromRGB(94, 222, 230) or Color3.fromRGB(92, 100, 116))
        accent.Parent = card

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Position = UDim2.fromOffset(34, 9)
        nameLabel.Size = UDim2.new(1, -154, 0, 20)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextColor3 = Color3.fromRGB(247, 248, 252)
        nameLabel.TextSize = 15
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Text = upgrade.DisplayName or upgrade.Id or "Upgrade"
        nameLabel.Parent = card

        local detailLabel = Instance.new("TextLabel")
        detailLabel.Position = UDim2.fromOffset(34, 29)
        detailLabel.Size = UDim2.new(1, -154, 0, 18)
        detailLabel.BackgroundTransparency = 1
        detailLabel.Font = Enum.Font.Gotham
        detailLabel.TextColor3 = Color3.fromRGB(202, 211, 224)
        detailLabel.TextSize = 13
        detailLabel.TextXAlignment = Enum.TextXAlignment.Left
        detailLabel.Text = string.format("%d %s | +%d / sec", upgrade.Cost or 0, state.CurrencyName or "Credits", upgrade.IncomePerSecond or 0)
        detailLabel.Parent = card

        local statusButton = createActionButton(card, UDim2.fromOffset(98, 30), UDim2.new(1, -110, 0.5, -15))

        if upgrade.Purchased then
            setButtonState(
                statusButton,
                "Built",
                false,
                Color3.fromRGB(59, 112, 73),
                Color3.fromRGB(240, 255, 242)
            )
        elseif upgrade.Available then
            local canAfford = (state.WalletBalance or 0) >= (upgrade.Cost or 0)
            setButtonState(
                statusButton,
                canAfford and "Build" or "Need More",
                true,
                canAfford and Color3.fromRGB(94, 222, 230) or Color3.fromRGB(255, 194, 107),
                Color3.fromRGB(18, 28, 35)
            )

            statusButton.MouseButton1Click:Connect(function()
                requestAction("BuyUpgrade", {
                    PlotId = state.OwnedPlotId,
                    UpgradeId = upgrade.Id,
                })
            end)
        else
            setButtonState(
                statusButton,
                "Locked",
                false,
                Color3.fromRGB(70, 78, 94),
                Color3.fromRGB(229, 235, 244)
            )
        end
    end

    clearGenerated(plotsContainer)
    for _, plot in ipairs(state.Plots or {}) do
        local card = createCard(plotsContainer, 64)

        local accent = Instance.new("Frame")
        accent.Size = UDim2.fromOffset(12, 44)
        accent.Position = UDim2.fromOffset(12, 10)
        accent.BorderSizePixel = 0
        accent.BackgroundColor3 = plot.AccentColor or Color3.fromRGB(255, 255, 255)
        accent.Parent = card

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Position = UDim2.fromOffset(34, 9)
        nameLabel.Size = UDim2.new(1, -160, 0, 20)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextColor3 = Color3.fromRGB(247, 248, 252)
        nameLabel.TextSize = 15
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Text = plot.DisplayName or ("Plot " .. tostring(plot.PlotId))
        nameLabel.Parent = card

        local ownerText = plot.OwnerName and ("Owner: " .. plot.OwnerName) or "Owner: Open"
        local detailLabel = Instance.new("TextLabel")
        detailLabel.Position = UDim2.fromOffset(34, 30)
        detailLabel.Size = UDim2.new(1, -160, 0, 22)
        detailLabel.BackgroundTransparency = 1
        detailLabel.Font = Enum.Font.Gotham
        detailLabel.TextColor3 = Color3.fromRGB(202, 211, 224)
        detailLabel.TextSize = 13
        detailLabel.TextXAlignment = Enum.TextXAlignment.Left
        detailLabel.Text = string.format("%s | Pending %d | %d / sec", ownerText, plot.PendingCash or 0, plot.IncomePerSecond or 0)
        detailLabel.Parent = card

        local statusButton = createActionButton(card, UDim2.fromOffset(100, 32), UDim2.new(1, -112, 0.5, -16))

        if plot.IsOwnedByYou then
            if (plot.PendingCash or 0) > 0 then
                setButtonState(
                    statusButton,
                    "Collect",
                    true,
                    Color3.fromRGB(94, 222, 230),
                    Color3.fromRGB(16, 24, 30)
                )

                statusButton.MouseButton1Click:Connect(function()
                    requestAction("CollectCash", {
                        PlotId = plot.PlotId,
                    })
                end)
            else
                setButtonState(
                    statusButton,
                    "Owned",
                    false,
                    Color3.fromRGB(59, 112, 73),
                    Color3.fromRGB(240, 255, 242)
                )
            end
        elseif plot.IsClaimed then
            setButtonState(
                statusButton,
                "Claimed",
                false,
                Color3.fromRGB(80, 90, 108),
                Color3.fromRGB(240, 244, 252)
            )
        else
            local canClaim = not state.OwnedPlotId
            setButtonState(
                statusButton,
                canClaim and "Claim" or "Open",
                canClaim,
                canClaim and Color3.fromRGB(94, 222, 230) or Color3.fromRGB(70, 78, 94),
                canClaim and Color3.fromRGB(16, 24, 30) or Color3.fromRGB(229, 235, 244)
            )

            if canClaim then
                statusButton.MouseButton1Click:Connect(function()
                    requestAction("ClaimPlot", {
                        PlotId = plot.PlotId,
                    })
                end)
            end
        end
    end
end

summaryActionButton.MouseButton1Click:Connect(function()
    if latestState and latestState.OwnedPlotId and (latestState.PendingCash or 0) > 0 then
        requestAction("CollectCash", {
            PlotId = latestState.OwnedPlotId,
        })
    end
end)

task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild("TycoonRemotes", 20)
    if not remotes then
        hintLabel.Text = "  Tycoon controls could not connect to the server."
        return
    end

    local stateRemote = remotes:WaitForChild("StateUpdated")
    local toastRemote = remotes:WaitForChild("Toast")
    requestStateRemote = remotes:WaitForChild("RequestState")
    actionRemote = remotes:WaitForChild("RequestAction")

    stateRemote.OnClientEvent:Connect(renderState)
    toastRemote.OnClientEvent:Connect(showToast)

    local ok, state = pcall(function()
        return requestStateRemote:InvokeServer()
    end)

    if ok and state then
        renderState(state)
        print("[RNGaming] Tycoon HUD connected.")
    else
        hintLabel.Text = "  Tycoon state failed to load from the server."
    end
end)
