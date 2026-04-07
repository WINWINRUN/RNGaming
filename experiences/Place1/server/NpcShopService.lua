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
