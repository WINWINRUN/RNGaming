local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local npcFolder = ServerStorage:WaitForChild("NPCs")
local starterScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local ItemFactorySource = [==[
local ItemFactory = {}

local SHAPE_MAP = {
    Ball = Enum.PartType.Ball,
    Block = Enum.PartType.Block,
    Cylinder = Enum.PartType.Cylinder,
}

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function createTaskTabletGraphic(parent)
    local bezel = Instance.new("Frame")
    bezel.Name = "Bezel"
    bezel.AnchorPoint = Vector2.new(0.5, 0.5)
    bezel.Position = UDim2.fromScale(0.5, 0.5)
    bezel.Size = UDim2.fromScale(0.86, 0.82)
    bezel.BackgroundColor3 = Color3.fromRGB(21, 30, 41)
    bezel.BorderSizePixel = 0
    bezel.Parent = parent
    addCorner(bezel, 18)

    local screen = Instance.new("Frame")
    screen.Name = "Screen"
    screen.AnchorPoint = Vector2.new(0.5, 0.5)
    screen.Position = UDim2.fromScale(0.5, 0.5)
    screen.Size = UDim2.fromScale(0.84, 0.78)
    screen.BackgroundColor3 = Color3.fromRGB(126, 208, 255)
    screen.BorderSizePixel = 0
    screen.Parent = bezel
    addCorner(screen, 14)

    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Position = UDim2.fromScale(0.08, 0.06)
    header.Size = UDim2.fromScale(0.84, 0.18)
    header.Font = Enum.Font.GothamBold
    header.Text = "TASKS"
    header.TextColor3 = Color3.fromRGB(13, 33, 56)
    header.TextScaled = true
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = screen

    local layout = {
        { y = 0.34, width = 0.5 },
        { y = 0.54, width = 0.65 },
        { y = 0.74, width = 0.42 },
    }

    for _, row in ipairs(layout) do
        local checkbox = Instance.new("Frame")
        checkbox.BackgroundColor3 = Color3.fromRGB(19, 94, 126)
        checkbox.BorderSizePixel = 0
        checkbox.Position = UDim2.fromScale(0.08, row.y)
        checkbox.Size = UDim2.fromScale(0.11, 0.1)
        checkbox.Parent = screen
        addCorner(checkbox, 8)

        local line = Instance.new("Frame")
        line.BackgroundColor3 = Color3.fromRGB(16, 61, 92)
        line.BorderSizePixel = 0
        line.Position = UDim2.fromScale(0.25, row.y + 0.02)
        line.Size = UDim2.fromScale(row.width, 0.06)
        line.Parent = screen
        addCorner(line, 8)
    end
end

local function decorateHandle(handle, itemDef)
    if itemDef.ScreenStyle ~= "TaskTablet" then
        return
    end

    for _, face in ipairs({ Enum.NormalId.Top, Enum.NormalId.Bottom }) do
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Name = "HandleScreen" .. face.Name
        surfaceGui.Face = face
        surfaceGui.CanvasSize = Vector2.new(256, 160)
        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surfaceGui.PixelsPerStud = 120
        surfaceGui.AlwaysOnTop = true
        surfaceGui.Parent = handle

        createTaskTabletGraphic(surfaceGui)
    end
end

local function createHandle(itemId, itemDef)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Anchored = false
    handle.CanCollide = false
    handle.CanQuery = false
    handle.CanTouch = false
    handle.Massless = true
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth
    handle.Size = itemDef.HandleSize or Vector3.new(1, 1, 1)
    handle.Color = itemDef.Color or Color3.fromRGB(240, 240, 255)
    handle.Material = itemDef.Material or Enum.Material.SmoothPlastic
    handle.Shape = SHAPE_MAP[itemDef.HandleShape or "Block"] or Enum.PartType.Block
    handle:SetAttribute("CatalogItemId", itemId)
    decorateHandle(handle, itemDef)
    return handle
end

function ItemFactory.createTool(itemId, itemDef)
    local tool = Instance.new("Tool")
    tool.Name = itemDef.DisplayName or itemId
    tool.ToolTip = itemDef.ToolTip or itemId
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool:SetAttribute("CatalogItemId", itemId)
    tool:SetAttribute("CatalogPrice", itemDef.Price or 0)

    local handle = createHandle(itemId, itemDef)
    handle.Parent = tool

    return tool
end

return ItemFactory
]==]

local NpcCatalogSource = [==[
return {
    AmongUsVendor = {
        DisplayName = "Red Crewmate",
        StallName = "Emergency Meeting Shop",
        Greeting = "Suspiciously good gear for a very temporary Place1 sandbox.",
        Items = {
            EmergencyButton = {
                DisplayName = "Emergency Button",
                Price = 25,
                ToolTip = "A portable panic button for dramatic tycoon decisions.",
                HandleSize = Vector3.new(1.5, 0.6, 1.5),
                HandleShape = "Cylinder",
                Color = Color3.fromRGB(214, 50, 51),
                Material = Enum.Material.SmoothPlastic,
            },
            TaskTablet = {
                DisplayName = "Task Tablet",
                Price = 15,
                ToolTip = "A tiny console loaded with definitely-complete tasks.",
                HandleSize = Vector3.new(1.6, 0.35, 1.1),
                HandleShape = "Block",
                Color = Color3.fromRGB(126, 208, 255),
                Material = Enum.Material.Glass,
                PreviewStyle = "TaskTablet",
                ScreenStyle = "TaskTablet",
            },
            CrewmateSnack = {
                DisplayName = "Crewmate Snack",
                Price = 10,
                ToolTip = "Emergency calories for long shifts and longer alibis.",
                HandleSize = Vector3.new(1.1, 1.1, 1.1),
                HandleShape = "Ball",
                Color = Color3.fromRGB(255, 201, 89),
                Material = Enum.Material.Neon,
            },
        },
        DisplayOrder = {
            "EmergencyButton",
            "TaskTablet",
            "CrewmateSnack",
        },
    },
}
]==]

local MainClientSource = [==[
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
]==]

local NpcShopServiceSource = [==[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local NpcCatalog = require(ServerStorage:WaitForChild("NPCs"):WaitForChild("NpcCatalog"))
local ItemFactory = require(script.Parent:WaitForChild("ItemFactory"))

local NpcShopService = {}

local vendorBindings = setmetatable({}, { __mode = "k" })
local started = false
local openShopRemote = nil
local purchaseFunction = nil

local REMOTE_FOLDER_NAME = "NpcShopRemotes"
local OPEN_REMOTE_NAME = "OpenShop"
local PURCHASE_FUNCTION_NAME = "PurchaseItem"
local DEFAULT_VENDOR_ID = "AmongUsVendor"
local VENDOR_CONTAINER_NAME = "VendorStalls"
local VENDOR_MODEL_NAME = "AmongUsVendorSpot"

local function getDefaultVendorId()
    if NpcCatalog[DEFAULT_VENDOR_ID] then
        return DEFAULT_VENDOR_ID
    end

    return next(NpcCatalog)
end

local function getWallet(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return nil
    end

    return leaderstats:FindFirstChild(Config.CurrencyName)
end

local function playerOwnsItem(player, itemId)
    local function scan(container)
        if not container then
            return false
        end

        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") and child:GetAttribute("CatalogItemId") == itemId then
                return true
            end
        end

        return false
    end

    return scan(player:FindFirstChild("Backpack"))
        or scan(player:FindFirstChild("StarterGear"))
        or scan(player.Character)
end

local function grantItem(player, itemId, itemDef)
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        return false, "BackpackMissing"
    end

    local liveTool = ItemFactory.createTool(itemId, itemDef)
    liveTool.Parent = backpack

    local starterGear = player:FindFirstChild("StarterGear")
    if starterGear then
        local persistentTool = ItemFactory.createTool(itemId, itemDef)
        persistentTool.Parent = starterGear
    end

    return true
end

local function getDisplayOrder(vendorConfig)
    local order = {}
    local seen = {}

    for _, itemId in ipairs(vendorConfig.DisplayOrder or {}) do
        if vendorConfig.Items[itemId] then
            table.insert(order, itemId)
            seen[itemId] = true
        end
    end

    for itemId in pairs(vendorConfig.Items) do
        if not seen[itemId] then
            table.insert(order, itemId)
        end
    end

    return order
end

local function buildShopData(player, vendorId)
    local vendorConfig = NpcCatalog[vendorId]
    if not vendorConfig then
        return nil
    end

    local wallet = getWallet(player)
    local items = {}

    for _, itemId in ipairs(getDisplayOrder(vendorConfig)) do
        local itemDef = vendorConfig.Items[itemId]
        table.insert(items, {
            ItemId = itemId,
            DisplayName = itemDef.DisplayName or itemId,
            Price = itemDef.Price or 0,
            ToolTip = itemDef.ToolTip or "No description available.",
            Owned = playerOwnsItem(player, itemId),
            AccentColor = itemDef.Color or Color3.fromRGB(220, 220, 220),
            PreviewStyle = itemDef.PreviewStyle,
        })
    end

    return {
        VendorId = vendorId,
        DisplayName = vendorConfig.DisplayName or vendorId,
        StallName = vendorConfig.StallName or vendorConfig.DisplayName or vendorId,
        Greeting = vendorConfig.Greeting or "Vendor",
        CurrencyName = Config.CurrencyName,
        WalletBalance = wallet and wallet.Value or 0,
        Items = items,
    }
end

local function purchaseItem(player, vendorId, itemId)
    local vendorConfig = NpcCatalog[vendorId]
    if not vendorConfig then
        return false, "UnknownVendor"
    end

    local itemDef = vendorConfig.Items[itemId]
    if not itemDef then
        return false, "UnknownItem"
    end

    if playerOwnsItem(player, itemId) then
        return false, "AlreadyOwned"
    end

    local wallet = getWallet(player)
    if not wallet then
        return false, "WalletMissing"
    end

    local price = itemDef.Price or 0
    if wallet.Value < price then
        return false, "NotEnoughCurrency"
    end

    wallet.Value = wallet.Value - price
    return grantItem(player, itemId, itemDef)
end

local function ensureRemoteFolder()
    local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
    if folder then
        return folder
    end

    folder = Instance.new("Folder")
    folder.Name = REMOTE_FOLDER_NAME
    folder.Parent = ReplicatedStorage
    return folder
end

local function ensureRemotes()
    local folder = ensureRemoteFolder()

    openShopRemote = folder:FindFirstChild(OPEN_REMOTE_NAME)
    if not openShopRemote then
        openShopRemote = Instance.new("RemoteEvent")
        openShopRemote.Name = OPEN_REMOTE_NAME
        openShopRemote.Parent = folder
    end

    purchaseFunction = folder:FindFirstChild(PURCHASE_FUNCTION_NAME)
    if not purchaseFunction then
        purchaseFunction = Instance.new("RemoteFunction")
        purchaseFunction.Name = PURCHASE_FUNCTION_NAME
        purchaseFunction.Parent = folder
    end
end

local function openShopForPlayer(player, vendorId)
    local shopData = buildShopData(player, vendorId)
    if not shopData or not openShopRemote then
        return
    end

    openShopRemote:FireClient(player, shopData)
end

local function ensureVendorBillboard(model, vendorConfig)
    local head = model:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    local billboard = head:FindFirstChild("VendorBillboard")
    if billboard then
        return
    end

    billboard = Instance.new("BillboardGui")
    billboard.Name = "VendorBillboard"
    billboard.Size = UDim2.fromOffset(240, 70)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.7, 0)
    billboard.AlwaysOnTop = true

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 28)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = vendorConfig.DisplayName or "Vendor"
    nameLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
    nameLabel.TextStrokeTransparency = 0.6
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    local detailLabel = Instance.new("TextLabel")
    detailLabel.Name = "DetailLabel"
    detailLabel.Position = UDim2.fromOffset(0, 28)
    detailLabel.Size = UDim2.new(1, 0, 0, 42)
    detailLabel.BackgroundTransparency = 1
    detailLabel.Text = vendorConfig.Greeting or "Vendor"
    detailLabel.TextColor3 = Color3.fromRGB(210, 228, 255)
    detailLabel.TextStrokeTransparency = 0.82
    detailLabel.TextWrapped = true
    detailLabel.TextScaled = true
    detailLabel.Font = Enum.Font.Gotham
    detailLabel.Parent = billboard

    billboard.Parent = head
end

local function ensureVendorPrompt(model, vendorConfig)
    local promptPart = model:FindFirstChild("ShopPromptPart")
        or model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart

    if not promptPart or not promptPart:IsA("BasePart") then
        return nil
    end

    local prompt = promptPart:FindFirstChild("ShopPrompt")
    if prompt and not prompt:IsA("ProximityPrompt") then
        prompt:Destroy()
        prompt = nil
    end

    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.Name = "ShopPrompt"
        prompt.Parent = promptPart
    end

    prompt.ActionText = "Open Shop"
    prompt.ObjectText = vendorConfig.DisplayName or "Vendor"
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = 0.15
    prompt.RequiresLineOfSight = false
    return prompt
end

local function bindVendor(model)
    if vendorBindings[model] then
        return
    end

    local vendorId = model:GetAttribute("VendorId")
    local vendorConfig = NpcCatalog[vendorId]
    if not vendorConfig then
        return
    end

    local prompt = ensureVendorPrompt(model, vendorConfig)
    if not prompt then
        return
    end

    ensureVendorBillboard(model, vendorConfig)
    prompt.Triggered:Connect(function(player)
        openShopForPlayer(player, vendorId)
    end)

    vendorBindings[model] = true
end

local function makePart(parent, name, size, cframe, options)
    options = options or {}

    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Material = options.Material or Enum.Material.SmoothPlastic
    part.Color = options.Color or Color3.fromRGB(220, 220, 220)
    part.Transparency = options.Transparency or 0
    part.CanCollide = options.CanCollide ~= false
    part.CanQuery = options.CanQuery ~= false
    part.CanTouch = options.CanTouch ~= false
    if options.Shape then
        part.Shape = options.Shape
    end
    part.Parent = parent
    return part
end

local function getBasePosition()
    local basePosition = Vector3.new(0, 186, -20)
    local generatedSpawn = Workspace:FindFirstChild("GeneratedSpawn")
    if generatedSpawn and generatedSpawn:IsA("BasePart") then
        basePosition = generatedSpawn.Position + Vector3.new(18, 0, 10)
    end

    return basePosition
end

local function createItemDisplays(parent, vendorConfig, basePosition)
    local offsets = { -3.4, 0, 3.4 }
    local displayOrder = getDisplayOrder(vendorConfig)

    for index, itemId in ipairs(displayOrder) do
        local itemDef = vendorConfig.Items[itemId]
        local xOffset = offsets[index] or ((index - 1) * 3.1)
        local accentColor = itemDef.Color or Color3.fromRGB(200, 200, 200)

        makePart(parent, itemId .. "Pad", Vector3.new(2.2, 0.5, 2.2), CFrame.new(basePosition + Vector3.new(xOffset, 2.6, 2.4)), {
            Color = Color3.fromRGB(54, 60, 74),
            Material = Enum.Material.Metal,
        })

        makePart(parent, itemId .. "Display", Vector3.new(1.2, 1.2, 1.2), CFrame.new(basePosition + Vector3.new(xOffset, 3.6, 2.4)), {
            Color = accentColor,
            Material = Enum.Material.Neon,
        })
    end
end

local function createVendorRig(parent, vendorId, basePosition)
    local rig = Instance.new("Model")
    rig.Name = "AmongUsVendorRig"
    rig:SetAttribute("VendorId", vendorId)
    rig.Parent = parent

    local root = makePart(rig, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(basePosition + Vector3.new(0, 4.2, 0)), {
        Transparency = 1,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
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

    makePart(rig, "ShopPromptPart", Vector3.new(4.5, 4.5, 4.5), root.CFrame * CFrame.new(0, 0.4, 4.7), {
        Transparency = 1,
        CanCollide = false,
        CanTouch = false,
    })

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = rig

    rig.PrimaryPart = root
    return rig
end

function NpcShopService.spawnVendorInWorkspace(forceReplace)
    local vendorId = getDefaultVendorId()
    local vendorConfig = vendorId and NpcCatalog[vendorId]
    if not vendorConfig then
        return nil
    end

    local container = Workspace:FindFirstChild(VENDOR_CONTAINER_NAME)
    if not container then
        container = Instance.new("Folder")
        container.Name = VENDOR_CONTAINER_NAME
        container.Parent = Workspace
    end

    local existing = container:FindFirstChild(VENDOR_MODEL_NAME)
    if existing then
        if not forceReplace then
            return existing
        end

        existing:Destroy()
    end

    local basePosition = getBasePosition()
    local stall = Instance.new("Model")
    stall.Name = VENDOR_MODEL_NAME
    stall.Parent = container

    makePart(stall, "Platform", Vector3.new(18, 1, 11), CFrame.new(basePosition + Vector3.new(0, -0.5, 0)), {
        Color = Color3.fromRGB(34, 38, 48),
        Material = Enum.Material.Metal,
    })

    makePart(stall, "Counter", Vector3.new(10.5, 2.8, 2.4), CFrame.new(basePosition + Vector3.new(0, 1.4, 3.7)), {
        Color = Color3.fromRGB(71, 79, 96),
        Material = Enum.Material.Metal,
    })

    local sign = makePart(stall, "ShopSign", Vector3.new(11, 2.4, 0.6), CFrame.new(basePosition + Vector3.new(0, 7.1, 4.8)), {
        Color = Color3.fromRGB(23, 27, 35),
        Material = Enum.Material.SmoothPlastic,
    })

    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign

    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromScale(1, 1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Text = vendorConfig.StallName or "Shop"
    title.TextColor3 = Color3.fromRGB(235, 244, 255)
    title.Parent = signGui

    createVendorRig(stall, vendorId, basePosition + Vector3.new(0, 0, -0.3))
    createItemDisplays(stall, vendorConfig, basePosition)

    return stall
end

local function tryBind(instance)
    if instance:IsA("Model") and instance:GetAttribute("VendorId") then
        bindVendor(instance)
    end
end

function NpcShopService.start()
    if started then
        return
    end

    started = true
    ensureRemotes()

    purchaseFunction.OnServerInvoke = function(player, vendorId, itemId)
        if type(vendorId) ~= "string" or type(itemId) ~= "string" then
            return {
                Success = false,
                Reason = "InvalidRequest",
            }
        end

        local ok, reason = purchaseItem(player, vendorId, itemId)
        return {
            Success = ok,
            Reason = reason,
            ShopData = buildShopData(player, vendorId),
        }
    end

    NpcShopService.spawnVendorInWorkspace(false)

    for _, instance in ipairs(Workspace:GetDescendants()) do
        tryBind(instance)
    end

    Workspace.DescendantAdded:Connect(tryBind)
end

return NpcShopService
]==]

npcFolder:WaitForChild("NpcCatalog").Source = NpcCatalogSource
ServerScriptService:WaitForChild("NpcShopService").Source = NpcShopServiceSource
ServerScriptService:WaitForChild("ItemFactory").Source = ItemFactorySource
starterScripts:WaitForChild("MainClient").Source = MainClientSource
print("[RNGaming] Synced shop mouse fix and task tablet visuals into the open place")

