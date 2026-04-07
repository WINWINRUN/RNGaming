local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local MOUSE_UNLOCK_BIND = "NpcShopMouseUnlock"

local function reportTerrain()
    local profile = Workspace:GetAttribute("RNGamingTerrainProfile")
    local seed = Workspace:GetAttribute("RNGamingTerrainSeed")
    if profile and seed then
        print(string.format("[RNGaming] Active terrain profile: %s (seed %s)", profile, tostring(seed)))
    end
end

Workspace:GetAttributeChangedSignal("RNGamingTerrainProfile"):Connect(reportTerrain)
reportTerrain()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NpcShopGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 20
screenGui.Enabled = false
screenGui.Parent = playerGui

local overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(7, 9, 15)
overlay.BackgroundTransparency = 0.34
overlay.AutoButtonColor = false
overlay.Modal = true
overlay.Text = ""
overlay.Active = true
overlay.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.72, 0, 0.72, 0)
panel.BackgroundColor3 = Color3.fromRGB(24, 29, 39)
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = overlay

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(340, 340)
sizeConstraint.MaxSize = Vector2.new(560, 440)
sizeConstraint.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(214, 50, 51)
stroke.Thickness = 2
stroke.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 84)
header.BackgroundColor3 = Color3.fromRGB(194, 41, 46)
header.BorderSizePixel = 0
header.Parent = panel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 18)
headerCorner.Parent = header

local headerMask = Instance.new("Frame")
headerMask.Size = UDim2.new(1, 0, 0, 22)
headerMask.Position = UDim2.new(0, 0, 1, -22)
headerMask.BorderSizePixel = 0
headerMask.BackgroundColor3 = Color3.fromRGB(194, 41, 46)
headerMask.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Position = UDim2.fromOffset(22, 14)
titleLabel.Size = UDim2.new(1, -80, 0, 28)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 28
titleLabel.TextColor3 = Color3.fromRGB(247, 248, 252)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "Emergency Meeting Shop"
titleLabel.Parent = header

local greetingLabel = Instance.new("TextLabel")
greetingLabel.Name = "Greeting"
greetingLabel.Position = UDim2.fromOffset(22, 44)
greetingLabel.Size = UDim2.new(1, -160, 0, 26)
greetingLabel.BackgroundTransparency = 1
greetingLabel.Font = Enum.Font.Gotham
greetingLabel.TextSize = 14
greetingLabel.TextColor3 = Color3.fromRGB(255, 231, 231)
greetingLabel.TextWrapped = true
greetingLabel.TextXAlignment = Enum.TextXAlignment.Left
greetingLabel.Text = "Browse suspiciously useful sandbox gear."
greetingLabel.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -18, 0, 16)
closeButton.Size = UDim2.fromOffset(42, 42)
closeButton.BackgroundColor3 = Color3.fromRGB(130, 24, 29)
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextSize = 20
closeButton.TextColor3 = Color3.fromRGB(255, 245, 245)
closeButton.AutoButtonColor = true
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

local walletLabel = Instance.new("TextLabel")
walletLabel.Name = "Wallet"
walletLabel.Position = UDim2.fromOffset(24, 98)
walletLabel.Size = UDim2.new(1, -48, 0, 24)
walletLabel.BackgroundTransparency = 1
walletLabel.Font = Enum.Font.GothamBold
walletLabel.TextSize = 18
walletLabel.TextColor3 = Color3.fromRGB(177, 243, 255)
walletLabel.TextXAlignment = Enum.TextXAlignment.Left
walletLabel.Text = "MoonCredits: 0"
walletLabel.Parent = panel

local itemsFrame = Instance.new("ScrollingFrame")
itemsFrame.Name = "Items"
itemsFrame.Position = UDim2.fromOffset(22, 132)
itemsFrame.Size = UDim2.new(1, -44, 1, -196)
itemsFrame.BackgroundColor3 = Color3.fromRGB(15, 19, 28)
itemsFrame.BorderSizePixel = 0
itemsFrame.ScrollBarThickness = 6
itemsFrame.CanvasSize = UDim2.fromOffset(0, 0)
itemsFrame.Active = true
itemsFrame.Parent = panel

local itemsCorner = Instance.new("UICorner")
itemsCorner.CornerRadius = UDim.new(0, 16)
itemsCorner.Parent = itemsFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 12)
listPadding.PaddingBottom = UDim.new(0, 12)
listPadding.PaddingLeft = UDim.new(0, 12)
listPadding.PaddingRight = UDim.new(0, 12)
listPadding.Parent = itemsFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = itemsFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Position = UDim2.new(0, 24, 1, -36)
statusLabel.Size = UDim2.new(1, -48, 0, 24)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 15
statusLabel.TextColor3 = Color3.fromRGB(226, 233, 244)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "Walk up to the vendor and browse the shop."
statusLabel.Parent = panel

local currentShopData = nil
local purchaseInFlight = false
local purchaseFunction = nil
local previousMouseLockEnabled = nil
local previousCameraMode = nil

local function setStatus(text, color)
    statusLabel.Text = text
    statusLabel.TextColor3 = color or Color3.fromRGB(226, 233, 244)
end

local function forceCursorUnlocked()
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

local function startShopInputMode()
    if previousMouseLockEnabled == nil then
        local ok, value = pcall(function()
            return localPlayer.DevEnableMouseLock
        end)
        if ok then
            previousMouseLockEnabled = value
            pcall(function()
                localPlayer.DevEnableMouseLock = false
            end)
        end
    end

    if previousCameraMode == nil then
        local ok, value = pcall(function()
            return localPlayer.CameraMode
        end)
        if ok then
            previousCameraMode = value
            pcall(function()
                localPlayer.CameraMode = Enum.CameraMode.Classic
            end)
        end
    end

    forceCursorUnlocked()
    RunService:BindToRenderStep(MOUSE_UNLOCK_BIND, Enum.RenderPriority.Camera.Value + 1, forceCursorUnlocked)
end

local function stopShopInputMode()
    RunService:UnbindFromRenderStep(MOUSE_UNLOCK_BIND)

    if previousMouseLockEnabled ~= nil then
        pcall(function()
            localPlayer.DevEnableMouseLock = previousMouseLockEnabled
        end)
        previousMouseLockEnabled = nil
    end

    if previousCameraMode ~= nil then
        pcall(function()
            localPlayer.CameraMode = previousCameraMode
        end)
        previousCameraMode = nil
    end

    forceCursorUnlocked()
end

local function hideShop()
    currentShopData = nil
    screenGui.Enabled = false
    stopShopInputMode()
end

closeButton.MouseButton1Click:Connect(hideShop)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    itemsFrame.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 24)
end)

local function getFailureMessage(reason, itemName, currencyName)
    local currency = currencyName or "credits"

    if reason == "AlreadyOwned" then
        return string.format("You already own %s.", itemName)
    end
    if reason == "NotEnoughCurrency" then
        return string.format("Not enough %s for %s.", currency, itemName)
    end
    if reason == "BackpackMissing" then
        return "Your backpack is missing. Respawn and try again."
    end
    if reason == "WalletMissing" then
        return string.format("Your %s wallet is missing.", currency)
    end
    if reason == "UnknownVendor" or reason == "UnknownItem" or reason == "InvalidRequest" then
        return "The shop request was rejected by the server."
    end

    return "Purchase failed."
end

local function clearItemRows()
    for _, child in ipairs(itemsFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function addRounded(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function createPreviewCard(parent)
    local preview = Instance.new("Frame")
    preview.Name = "Preview"
    preview.Position = UDim2.fromOffset(34, 14)
    preview.Size = UDim2.fromOffset(64, 64)
    preview.BackgroundColor3 = Color3.fromRGB(18, 23, 34)
    preview.BorderSizePixel = 0
    preview.Parent = parent
    addRounded(preview, 14)
    return preview
end

local function renderTaskTabletPreview(parent)
    local bezel = Instance.new("Frame")
    bezel.AnchorPoint = Vector2.new(0.5, 0.5)
    bezel.Position = UDim2.fromScale(0.5, 0.5)
    bezel.Size = UDim2.fromScale(0.8, 0.86)
    bezel.BackgroundColor3 = Color3.fromRGB(28, 37, 49)
    bezel.BorderSizePixel = 0
    bezel.Parent = parent
    addRounded(bezel, 12)

    local screen = Instance.new("Frame")
    screen.AnchorPoint = Vector2.new(0.5, 0.5)
    screen.Position = UDim2.fromScale(0.5, 0.5)
    screen.Size = UDim2.fromScale(0.82, 0.76)
    screen.BackgroundColor3 = Color3.fromRGB(126, 208, 255)
    screen.BorderSizePixel = 0
    screen.Parent = bezel
    addRounded(screen, 10)

    local header = Instance.new("TextLabel")
    header.BackgroundTransparency = 1
    header.Position = UDim2.fromScale(0.1, 0.06)
    header.Size = UDim2.fromScale(0.82, 0.22)
    header.Font = Enum.Font.GothamBold
    header.Text = "TASK"
    header.TextScaled = true
    header.TextColor3 = Color3.fromRGB(17, 41, 67)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = screen

    for index, width in ipairs({ 0.48, 0.62, 0.38 }) do
        local y = 0.33 + (index - 1) * 0.2

        local checkbox = Instance.new("Frame")
        checkbox.BackgroundColor3 = Color3.fromRGB(18, 93, 124)
        checkbox.BorderSizePixel = 0
        checkbox.Position = UDim2.fromScale(0.1, y)
        checkbox.Size = UDim2.fromScale(0.12, 0.08)
        checkbox.Parent = screen
        addRounded(checkbox, 8)

        local line = Instance.new("Frame")
        line.BackgroundColor3 = Color3.fromRGB(17, 62, 95)
        line.BorderSizePixel = 0
        line.Position = UDim2.fromScale(0.28, y + 0.01)
        line.Size = UDim2.fromScale(width, 0.05)
        line.Parent = screen
        addRounded(line, 8)
    end
end

local function renderGenericPreview(parent, item)
    local shape = Instance.new("Frame")
    shape.AnchorPoint = Vector2.new(0.5, 0.5)
    shape.Position = UDim2.fromScale(0.5, 0.5)
    shape.Size = UDim2.fromScale(0.62, 0.62)
    shape.BackgroundColor3 = item.AccentColor or Color3.fromRGB(255, 255, 255)
    shape.BorderSizePixel = 0
    shape.Parent = parent
    addRounded(shape, 16)
end

local function renderItemPreview(item, parent)
    if item.PreviewStyle == "TaskTablet" then
        renderTaskTabletPreview(parent)
        return
    end

    renderGenericPreview(parent, item)
end

local function renderShop(shopData)
    currentShopData = shopData
    startShopInputMode()
    screenGui.Enabled = true

    titleLabel.Text = shopData.StallName or shopData.DisplayName or "Shop"
    greetingLabel.Text = string.format("%s says: %s", shopData.DisplayName or "Vendor", shopData.Greeting or "Take a look around.")
    walletLabel.Text = string.format("%s: %d", shopData.CurrencyName or "Credits", shopData.WalletBalance or 0)

    clearItemRows()

    for _, item in ipairs(shopData.Items or {}) do
        local row = Instance.new("Frame")
        row.Name = "ItemRow"
        row.Size = UDim2.new(1, 0, 0, 92)
        row.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
        row.BorderSizePixel = 0
        row.Parent = itemsFrame

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 14)
        rowCorner.Parent = row

        local preview = createPreviewCard(row)
        renderItemPreview(item, preview)

        local accent = Instance.new("Frame")
        accent.Size = UDim2.fromOffset(10, 68)
        accent.Position = UDim2.fromOffset(12, 12)
        accent.BackgroundColor3 = item.AccentColor or Color3.fromRGB(255, 255, 255)
        accent.BorderSizePixel = 0
        accent.Parent = row

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        local itemName = Instance.new("TextLabel")
        itemName.Position = UDim2.fromOffset(112, 12)
        itemName.Size = UDim2.new(1, -258, 0, 26)
        itemName.BackgroundTransparency = 1
        itemName.Font = Enum.Font.GothamBold
        itemName.TextSize = 19
        itemName.TextColor3 = Color3.fromRGB(247, 248, 252)
        itemName.TextXAlignment = Enum.TextXAlignment.Left
        itemName.Text = item.DisplayName or item.ItemId or "Item"
        itemName.Parent = row

        local itemDescription = Instance.new("TextLabel")
        itemDescription.Position = UDim2.fromOffset(112, 40)
        itemDescription.Size = UDim2.new(1, -278, 0, 38)
        itemDescription.BackgroundTransparency = 1
        itemDescription.Font = Enum.Font.Gotham
        itemDescription.TextSize = 13
        itemDescription.TextWrapped = true
        itemDescription.TextColor3 = Color3.fromRGB(200, 209, 222)
        itemDescription.TextXAlignment = Enum.TextXAlignment.Left
        itemDescription.TextYAlignment = Enum.TextYAlignment.Top
        itemDescription.Text = item.ToolTip or ""
        itemDescription.Parent = row

        local buyButton = Instance.new("TextButton")
        buyButton.AnchorPoint = Vector2.new(1, 0.5)
        buyButton.Position = UDim2.new(1, -14, 0.5, 0)
        buyButton.Size = UDim2.fromOffset(130, 44)
        buyButton.BorderSizePixel = 0
        buyButton.Font = Enum.Font.GothamBold
        buyButton.TextSize = 16
        buyButton.Parent = row

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 12)
        buttonCorner.Parent = buyButton

        if item.Owned then
            buyButton.BackgroundColor3 = Color3.fromRGB(59, 112, 73)
            buyButton.TextColor3 = Color3.fromRGB(240, 255, 242)
            buyButton.Text = "Owned"
        else
            buyButton.BackgroundColor3 = item.AccentColor or Color3.fromRGB(214, 50, 51)
            buyButton.TextColor3 = Color3.fromRGB(16, 22, 31)
            buyButton.Text = string.format("Buy %d", item.Price or 0)
            buyButton.MouseButton1Click:Connect(function()
                if purchaseInFlight or not currentShopData or not purchaseFunction then
                    return
                end

                purchaseInFlight = true
                setStatus(string.format("Buying %s...", item.DisplayName or item.ItemId or "item"), Color3.fromRGB(177, 243, 255))

                local ok, response = pcall(function()
                    return purchaseFunction:InvokeServer(currentShopData.VendorId, item.ItemId)
                end)

                purchaseInFlight = false

                if not ok then
                    setStatus("The purchase request failed to reach the server.", Color3.fromRGB(255, 152, 152))
                    return
                end

                if response and response.ShopData then
                    renderShop(response.ShopData)
                end

                if response and response.Success then
                    setStatus(string.format("%s added to your backpack.", item.DisplayName or item.ItemId or "Item"), Color3.fromRGB(163, 241, 180))
                else
                    setStatus(getFailureMessage(response and response.Reason, item.DisplayName or item.ItemId or "item", currentShopData and currentShopData.CurrencyName), Color3.fromRGB(255, 152, 152))
                end
            end)
        end
    end
end

task.spawn(function()
    local remotesFolder = ReplicatedStorage:WaitForChild("NpcShopRemotes", 20)
    if not remotesFolder then
        return
    end

    local openShopRemote = remotesFolder:WaitForChild("OpenShop")
    purchaseFunction = remotesFolder:WaitForChild("PurchaseItem")

    openShopRemote.OnClientEvent:Connect(function(shopData)
        renderShop(shopData)
        setStatus("Choose an item to buy.", Color3.fromRGB(226, 233, 244))
    end)
end)
