local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local TycoonConfig = require(ReplicatedStorage:WaitForChild("TycoonConfig"))
local NpcShopService = require(ServerScriptService:WaitForChild("NpcShopService"))

local TycoonService = {}

local REMOTE_FOLDER_NAME = "TycoonRemotes"
local STATE_EVENT_NAME = "StateUpdated"
local TOAST_EVENT_NAME = "Toast"
local REQUEST_STATE_NAME = "RequestState"
local ACTION_EVENT_NAME = "RequestAction"

local WORLD_FOLDER_NAME = TycoonConfig.WorldFolderName
local WORLD_PLOTS_NAME = "Plots"
local WORLD_HUB_NAME = "Hub"

local started = false
local plotStates = {}
local plotRefs = {}
local userToPlotId = {}
local promptBindings = setmetatable({}, { __mode = "k" })
local walletConnections = setmetatable({}, { __mode = "k" })
local stateRemote = nil
local toastRemote = nil
local requestStateFunction = nil
local actionRemote = nil

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function createSurfaceLabel(parent, face, textColor, font)
    local gui = Instance.new("SurfaceGui")
    gui.Face = face
    gui.CanvasSize = Vector2.new(300, 160)
    gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    gui.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = font or Enum.Font.GothamBold
    label.TextColor3 = textColor or Color3.fromRGB(245, 248, 255)
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui

    return label
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

    local rows = {
        { y = 0.34, width = 0.5 },
        { y = 0.54, width = 0.65 },
        { y = 0.74, width = 0.42 },
    }

    for _, row in ipairs(rows) do
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
    part.Reflectance = options.Reflectance or 0
    part.CanCollide = options.CanCollide ~= false
    part.CanQuery = options.CanQuery ~= false
    part.CanTouch = options.CanTouch ~= false
    if options.Shape then
        part.Shape = options.Shape
    end
    part.Parent = parent
    return part
end

local function createPrompt(parent, actionText, objectText, attributes)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = 0.1
    prompt.Style = Enum.ProximityPromptStyle.Default
    prompt.Parent = parent

    for key, value in pairs(attributes or {}) do
        prompt:SetAttribute(key, value)
    end

    return prompt
end

local function getWallet(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return nil
    end

    return leaderstats:FindFirstChild(Config.CurrencyName)
end

local function getHubCenter()
    local generatedSpawn = Workspace:FindFirstChild("GeneratedSpawn")
    if generatedSpawn and generatedSpawn:IsA("BasePart") then
        return Vector3.new(
            generatedSpawn.Position.X,
            generatedSpawn.Position.Y - (generatedSpawn.Size.Y * 0.5) - 0.75,
            generatedSpawn.Position.Z
        )
    end

    return Vector3.new(0, 184, 0)
end

local function getPlotPosition(index, center)
    local angle = -math.pi * 0.5 + ((index - 1) / TycoonConfig.PlotCount) * math.pi * 2
    local offset = Vector3.new(math.cos(angle) * TycoonConfig.PlotRadius, 0, math.sin(angle) * TycoonConfig.PlotRadius)
    local position = center + offset
    local flatLookAt = Vector3.new(center.X, position.Y, center.Z)
    local plotCFrame = CFrame.lookAt(position, flatLookAt)
    return position, plotCFrame
end

local function getOwnedPlotState(player)
    local plotId = player and userToPlotId[player.UserId]
    return plotId and plotStates[plotId] or nil
end

local function initializePlotStates()
    table.clear(plotStates)
    table.clear(plotRefs)
    table.clear(userToPlotId)

    for index = 1, TycoonConfig.PlotCount do
        plotStates[index] = {
            PlotId = index,
            DisplayName = TycoonConfig.getPlotName(index),
            AccentColor = TycoonConfig.getPlotColor(index),
            OwnerUserId = nil,
            OwnerName = nil,
            PendingCash = 0,
            IncomePerSecond = 0,
            PurchasedUpgrades = {},
        }
    end
end

local function isUpgradeAvailable(plotState, upgradeId)
    if not plotState or plotState.PurchasedUpgrades[upgradeId] then
        return false
    end

    for _, upgrade in ipairs(TycoonConfig.Upgrades) do
        if upgrade.Id == upgradeId then
            return plotState.OwnerUserId ~= nil
        end

        if not plotState.PurchasedUpgrades[upgrade.Id] then
            return false
        end
    end

    return false
end

local function getNextUpgrade(plotState)
    if not plotState then
        return nil
    end

    for _, upgrade in ipairs(TycoonConfig.Upgrades) do
        if not plotState.PurchasedUpgrades[upgrade.Id] then
            return upgrade
        end
    end

    return nil
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

    stateRemote = folder:FindFirstChild(STATE_EVENT_NAME)
    if not stateRemote then
        stateRemote = Instance.new("RemoteEvent")
        stateRemote.Name = STATE_EVENT_NAME
        stateRemote.Parent = folder
    end

    toastRemote = folder:FindFirstChild(TOAST_EVENT_NAME)
    if not toastRemote then
        toastRemote = Instance.new("RemoteEvent")
        toastRemote.Name = TOAST_EVENT_NAME
        toastRemote.Parent = folder
    end

    requestStateFunction = folder:FindFirstChild(REQUEST_STATE_NAME)
    if not requestStateFunction then
        requestStateFunction = Instance.new("RemoteFunction")
        requestStateFunction.Name = REQUEST_STATE_NAME
        requestStateFunction.Parent = folder
    end

    actionRemote = folder:FindFirstChild(ACTION_EVENT_NAME)
    if not actionRemote then
        actionRemote = Instance.new("RemoteEvent")
        actionRemote.Name = ACTION_EVENT_NAME
        actionRemote.Parent = folder
    end
end

local function fireToast(player, text, color)
    if toastRemote and player then
        toastRemote:FireClient(player, {
            Text = text,
            Color = color or Color3.fromRGB(245, 248, 255),
        })
    end
end

local function buildPlotSnapshot(plotState, viewerUserId)
    local pendingCash = math.floor(plotState.PendingCash + 0.5)
    local isOwnedByYou = viewerUserId ~= nil and plotState.OwnerUserId == viewerUserId
    local statusText

    if not plotState.OwnerUserId then
        statusText = "Open"
    elseif isOwnedByYou then
        statusText = "Yours"
    else
        statusText = "Claimed"
    end

    return {
        PlotId = plotState.PlotId,
        DisplayName = plotState.DisplayName,
        AccentColor = plotState.AccentColor,
        OwnerName = plotState.OwnerName,
        IsClaimed = plotState.OwnerUserId ~= nil,
        IsOwnedByYou = isOwnedByYou,
        PendingCash = pendingCash,
        IncomePerSecond = plotState.IncomePerSecond,
        StatusText = statusText,
    }
end

local function buildUpgradeState(plotState)
    local upgrades = {}

    for _, upgrade in ipairs(TycoonConfig.Upgrades) do
        table.insert(upgrades, {
            Id = upgrade.Id,
            DisplayName = upgrade.DisplayName,
            Cost = upgrade.Cost,
            IncomePerSecond = upgrade.IncomePerSecond,
            PreviewStyle = upgrade.PreviewStyle,
            Purchased = plotState and plotState.PurchasedUpgrades[upgrade.Id] or false,
            Available = plotState and isUpgradeAvailable(plotState, upgrade.Id) or false,
        })
    end

    return upgrades
end

local function buildPlayerState(player)
    local wallet = getWallet(player)
    local plotState = getOwnedPlotState(player)
    local nextUpgrade = getNextUpgrade(plotState)
    local plots = {}

    for _, state in ipairs(plotStates) do
        table.insert(plots, buildPlotSnapshot(state, player.UserId))
    end

    return {
        CurrencyName = Config.CurrencyName,
        WalletBalance = wallet and wallet.Value or 0,
        OwnedPlotId = plotState and plotState.PlotId or nil,
        OwnedPlotName = plotState and plotState.DisplayName or nil,
        IncomePerSecond = plotState and plotState.IncomePerSecond or 0,
        PendingCash = plotState and math.floor(plotState.PendingCash + 0.5) or 0,
        HintText = plotState
            and (nextUpgrade
                and string.format("Walk onto the build pad for %s.", nextUpgrade.DisplayName)
                or "Your plot is complete. Keep collecting your cash.")
            or "Claim an open plot to begin your Among Us tycoon.",
        NextUpgrade = nextUpgrade and {
            DisplayName = nextUpgrade.DisplayName,
            Cost = nextUpgrade.Cost,
            IncomePerSecond = nextUpgrade.IncomePerSecond,
        } or nil,
        OwnedPlotUpgrades = buildUpgradeState(plotState),
        Plots = plots,
    }
end

local function sendStateToPlayer(player)
    if stateRemote and player and player.Parent == Players then
        stateRemote:FireClient(player, buildPlayerState(player))
    end
end

local function broadcastAllStates()
    for _, player in ipairs(Players:GetPlayers()) do
        sendStateToPlayer(player)
    end
end

local function createCrewmate(parent, name, color, rootCFrame)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    local root = makePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), rootCFrame, {
        Transparency = 1,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
    })

    makePart(model, "Body", Vector3.new(4.2, 5, 3.4), root.CFrame, {
        Color = color,
        Material = Enum.Material.SmoothPlastic,
    })

    makePart(model, "Head", Vector3.new(3.7, 1.8, 3.1), root.CFrame * CFrame.new(0, 2.4, -0.05), {
        Color = color,
        Material = Enum.Material.SmoothPlastic,
    })

    makePart(model, "Backpack", Vector3.new(1.4, 3, 2.4), root.CFrame * CFrame.new(0, 0.15, -2.45), {
        Color = color:Lerp(Color3.fromRGB(35, 35, 35), 0.25),
        Material = Enum.Material.SmoothPlastic,
    })

    makePart(model, "Visor", Vector3.new(2.5, 1.4, 1.1), root.CFrame * CFrame.new(0.5, 0.85, 2.28), {
        Color = Color3.fromRGB(177, 243, 255),
        Material = Enum.Material.Glass,
    })

    makePart(model, "LeftLeg", Vector3.new(1.35, 2.1, 1.5), root.CFrame * CFrame.new(-0.9, -3.35, 0), {
        Color = color:Lerp(Color3.fromRGB(15, 15, 15), 0.3),
        Material = Enum.Material.SmoothPlastic,
    })

    makePart(model, "RightLeg", Vector3.new(1.35, 2.1, 1.5), root.CFrame * CFrame.new(0.9, -3.35, 0), {
        Color = color:Lerp(Color3.fromRGB(15, 15, 15), 0.3),
        Material = Enum.Material.SmoothPlastic,
    })

    model.PrimaryPart = root
    return model
end

local function buildEmergencyButton(parent, baseCFrame)
    local model = Instance.new("Model")
    model.Name = "EmergencyButtonPress"
    model.Parent = parent

    makePart(model, "Desk", Vector3.new(14, 2.8, 10), baseCFrame * CFrame.new(0, 1.4, 0), {
        Color = Color3.fromRGB(72, 84, 102),
        Material = Enum.Material.Metal,
    })

    makePart(model, "ButtonBase", Vector3.new(5.5, 1.2, 5.5), baseCFrame * CFrame.new(0, 3.1, 0), {
        Color = Color3.fromRGB(222, 222, 226),
        Material = Enum.Material.SmoothPlastic,
        Shape = Enum.PartType.Cylinder,
    })

    makePart(model, "Button", Vector3.new(3.8, 1.6, 3.8), baseCFrame * CFrame.new(0, 4.1, 0), {
        Color = Color3.fromRGB(214, 50, 51),
        Material = Enum.Material.Neon,
        Shape = Enum.PartType.Cylinder,
    })

    return model
end

local function buildTaskTabletDesk(parent, baseCFrame)
    local model = Instance.new("Model")
    model.Name = "TaskTabletDesk"
    model.Parent = parent

    makePart(model, "Desk", Vector3.new(13, 2, 9), baseCFrame * CFrame.new(0, 1, 0), {
        Color = Color3.fromRGB(70, 82, 98),
        Material = Enum.Material.Metal,
    })

    makePart(model, "Stand", Vector3.new(1.4, 3.6, 1.4), baseCFrame * CFrame.new(0, 3, 0), {
        Color = Color3.fromRGB(24, 34, 49),
        Material = Enum.Material.Metal,
    })

    local tablet = makePart(model, "Tablet", Vector3.new(5.2, 0.35, 3.8), baseCFrame * CFrame.new(0, 4.9, 0), {
        Color = Color3.fromRGB(126, 208, 255),
        Material = Enum.Material.Glass,
    })

    local screenGui = Instance.new("SurfaceGui")
    screenGui.Face = Enum.NormalId.Top
    screenGui.CanvasSize = Vector2.new(256, 160)
    screenGui.Parent = tablet
    createTaskTabletGraphic(screenGui)

    return model
end

local function buildSnackBar(parent, baseCFrame)
    local model = Instance.new("Model")
    model.Name = "CrewmateSnackBar"
    model.Parent = parent

    makePart(model, "Counter", Vector3.new(13, 4, 7), baseCFrame * CFrame.new(0, 2, 0), {
        Color = Color3.fromRGB(98, 74, 49),
        Material = Enum.Material.WoodPlanks,
    })

    for index, color in ipairs({
        Color3.fromRGB(255, 201, 89),
        Color3.fromRGB(255, 134, 89),
        Color3.fromRGB(132, 248, 181),
    }) do
        makePart(model, "Snack" .. index, Vector3.new(1.8, 1.8, 1.8), baseCFrame * CFrame.new(-2.8 + ((index - 1) * 2.8), 5.3, 0), {
            Color = color,
            Material = Enum.Material.Neon,
            Shape = Enum.PartType.Ball,
        })
    end

    return model
end

local function buildVent(parent, baseCFrame)
    local model = Instance.new("Model")
    model.Name = "VentNetwork"
    model.Parent = parent

    makePart(model, "Frame", Vector3.new(12, 1.1, 12), baseCFrame * CFrame.new(0, 0.55, 0), {
        Color = Color3.fromRGB(72, 84, 96),
        Material = Enum.Material.Metal,
    })

    for index = 1, 6 do
        makePart(model, "Slat" .. index, Vector3.new(1.2, 1.25, 10), baseCFrame * CFrame.new(-4.4 + ((index - 1) * 1.76), 0.68, 0), {
            Color = Color3.fromRGB(36, 42, 52),
            Material = Enum.Material.Metal,
        })
    end

    return model
end

local function buildReactor(parent, baseCFrame)
    local model = Instance.new("Model")
    model.Name = "ReactorCore"
    model.Parent = parent

    makePart(model, "Base", Vector3.new(13, 2.4, 13), baseCFrame * CFrame.new(0, 1.2, 0), {
        Color = Color3.fromRGB(54, 60, 78),
        Material = Enum.Material.Metal,
    })

    makePart(model, "Core", Vector3.new(5.4, 8.5, 5.4), baseCFrame * CFrame.new(0, 6, 0), {
        Color = Color3.fromRGB(103, 255, 234),
        Material = Enum.Material.Neon,
        Shape = Enum.PartType.Cylinder,
    })

    for index = 1, 4 do
        local angle = (index - 1) * (math.pi * 0.5)
        local offset = Vector3.new(math.cos(angle) * 4.5, 4.4, math.sin(angle) * 4.5)
        makePart(model, "Support" .. index, Vector3.new(1, 7, 1), baseCFrame * CFrame.new(offset), {
            Color = Color3.fromRGB(160, 167, 180),
            Material = Enum.Material.Metal,
        })
    end

    return model
end

local function buildCloneBay(parent, baseCFrame, accentColor)
    local model = Instance.new("Model")
    model.Name = "CrewmateCloneBay"
    model.Parent = parent

    makePart(model, "Platform", Vector3.new(15, 2, 11), baseCFrame * CFrame.new(0, 1, 0), {
        Color = Color3.fromRGB(56, 62, 76),
        Material = Enum.Material.Metal,
    })

    for index = 1, 2 do
        local xOffset = index == 1 and -3.5 or 3.5
        makePart(model, "TubeBase" .. index, Vector3.new(3.4, 1.2, 3.4), baseCFrame * CFrame.new(xOffset, 2.6, 0), {
            Color = Color3.fromRGB(100, 108, 126),
            Material = Enum.Material.Metal,
        })

        makePart(model, "TubeGlass" .. index, Vector3.new(2.8, 6.4, 2.8), baseCFrame * CFrame.new(xOffset, 6.2, 0), {
            Color = Color3.fromRGB(164, 255, 255),
            Material = Enum.Material.Glass,
            Transparency = 0.25,
        })
    end

    createCrewmate(model, "CloneMascot", accentColor, baseCFrame * CFrame.new(0, 6, 0))
    return model
end

local function buildUpgradeMachine(parent, upgradeDef, baseCFrame, accentColor)
    if upgradeDef.PreviewStyle == "EmergencyButton" then
        return buildEmergencyButton(parent, baseCFrame)
    end
    if upgradeDef.PreviewStyle == "TaskTablet" then
        return buildTaskTabletDesk(parent, baseCFrame)
    end
    if upgradeDef.PreviewStyle == "SnackBar" then
        return buildSnackBar(parent, baseCFrame)
    end
    if upgradeDef.PreviewStyle == "Vent" then
        return buildVent(parent, baseCFrame)
    end
    if upgradeDef.PreviewStyle == "Reactor" then
        return buildReactor(parent, baseCFrame)
    end
    if upgradeDef.PreviewStyle == "CloneBay" then
        return buildCloneBay(parent, baseCFrame, accentColor)
    end

    local fallback = Instance.new("Model")
    fallback.Name = upgradeDef.Id
    fallback.Parent = parent
    makePart(fallback, "Fallback", Vector3.new(8, 4, 8), baseCFrame * CFrame.new(0, 2, 0), {
        Color = accentColor,
        Material = Enum.Material.Neon,
    })
    return fallback
end

local function getOrCreateWorld(forceReplace)
    local existing = Workspace:FindFirstChild(WORLD_FOLDER_NAME)
    if existing and forceReplace then
        existing:Destroy()
        existing = nil
    end

    if existing then
        return existing
    end

    local folder = Instance.new("Folder")
    folder.Name = WORLD_FOLDER_NAME
    folder.Parent = Workspace
    return folder
end

local function createHub(world, center)
    local hubFolder = Instance.new("Folder")
    hubFolder.Name = WORLD_HUB_NAME
    hubFolder.Parent = world

    makePart(hubFolder, "MeetingPad", Vector3.new(52, 2, 52), CFrame.new(center + Vector3.new(0, 1, 0)), {
        Color = Color3.fromRGB(52, 58, 72),
        Material = Enum.Material.Metal,
        Shape = Enum.PartType.Cylinder,
    })

    makePart(hubFolder, "MeetingRing", Vector3.new(42, 2.4, 42), CFrame.new(center + Vector3.new(0, 1.2, 0)), {
        Color = Color3.fromRGB(214, 50, 51),
        Material = Enum.Material.Neon,
        Shape = Enum.PartType.Cylinder,
        Transparency = 0.2,
    })

    makePart(hubFolder, "CenterTable", Vector3.new(16, 2.2, 16), CFrame.new(center + Vector3.new(0, 3.1, 0)), {
        Color = Color3.fromRGB(86, 93, 110),
        Material = Enum.Material.Metal,
        Shape = Enum.PartType.Cylinder,
    })

    makePart(hubFolder, "CenterButton", Vector3.new(7, 1.6, 7), CFrame.new(center + Vector3.new(0, 5.1, 0)), {
        Color = Color3.fromRGB(214, 50, 51),
        Material = Enum.Material.Neon,
        Shape = Enum.PartType.Cylinder,
    })

    local sign = makePart(hubFolder, "TycoonSign", Vector3.new(22, 8, 1), CFrame.new(center + Vector3.new(0, 11, -22)), {
        Color = Color3.fromRGB(24, 28, 38),
        Material = Enum.Material.SmoothPlastic,
    })

    local label = createSurfaceLabel(sign, Enum.NormalId.Front, Color3.fromRGB(247, 248, 252), Enum.Font.GothamBlack)
    label.Text = "AMONG US\nTYCOON"

    local detail = createSurfaceLabel(sign, Enum.NormalId.Back, Color3.fromRGB(177, 243, 255), Enum.Font.GothamBold)
    detail.Text = "Claim. Build. Collect."
end

local function refreshPlotVisuals(plotId)
    local plotState = plotStates[plotId]
    local refs = plotRefs[plotId]
    if not plotState or not refs then
        return
    end

    local isOwned = plotState.OwnerUserId ~= nil
    local pendingCash = math.floor(plotState.PendingCash + 0.5)

    refs.Floor.Color = isOwned
        and plotState.AccentColor:Lerp(Color3.fromRGB(38, 42, 52), 0.55)
        or Color3.fromRGB(48, 52, 64)

    refs.ClaimPrompt.Enabled = not isOwned
    refs.CollectPrompt.Enabled = isOwned and pendingCash > 0

    refs.ClaimLabel.Text = isOwned
        and string.format("CLAIMED\n%s", plotState.OwnerName or "Owner")
        or "CLAIM\nPLOT"

    refs.CollectLabel.Text = isOwned
        and string.format("COLLECT\n%d", pendingCash)
        or "COLLECT\nLOCKED"

    if isOwned then
        refs.SignDetail.Text = string.format(
            "Owner: %s\nIncome: %d / sec\nPending: %d",
            plotState.OwnerName or "Owner",
            plotState.IncomePerSecond,
            pendingCash
        )
    else
        refs.SignDetail.Text = "Unclaimed\nUse the claim pad to begin."
    end

    for _, upgrade in ipairs(TycoonConfig.Upgrades) do
        local buttonRefs = refs.UpgradeButtons[upgrade.Id]
        local buttonState

        if plotState.PurchasedUpgrades[upgrade.Id] then
            buttonState = "Built"
        elseif isUpgradeAvailable(plotState, upgrade.Id) then
            buttonState = "Available"
        else
            buttonState = "Locked"
        end

        if buttonState == "Built" then
            buttonRefs.Part.Transparency = 1
            buttonRefs.Part.CanQuery = false
            buttonRefs.Part.CanTouch = false
            buttonRefs.Prompt.Enabled = false
            buttonRefs.Label.Text = "BUILT"

            if not refs.Machines[upgrade.Id] then
                refs.Machines[upgrade.Id] = buildUpgradeMachine(
                    refs.MachinesFolder,
                    upgrade,
                    refs.PlotCFrame * CFrame.new(upgrade.RelativePosition + Vector3.new(0, 0.1, 0)),
                    plotState.AccentColor
                )
            end
        elseif buttonState == "Available" then
            buttonRefs.Part.Transparency = 0.08
            buttonRefs.Part.CanQuery = true
            buttonRefs.Part.CanTouch = true
            buttonRefs.Prompt.Enabled = true
            buttonRefs.Label.Text = string.format(
                "%s\n%d %s\n+%d / sec",
                upgrade.DisplayName,
                upgrade.Cost,
                Config.CurrencyName,
                upgrade.IncomePerSecond
            )

            if refs.Machines[upgrade.Id] then
                refs.Machines[upgrade.Id]:Destroy()
                refs.Machines[upgrade.Id] = nil
            end
        else
            buttonRefs.Part.Transparency = isOwned and 0.45 or 0.55
            buttonRefs.Part.CanQuery = true
            buttonRefs.Part.CanTouch = true
            buttonRefs.Prompt.Enabled = false
            buttonRefs.Label.Text = plotState.OwnerUserId and "LOCKED\nFinish the previous build." or "LOCKED\nClaim the plot first."

            if refs.Machines[upgrade.Id] then
                refs.Machines[upgrade.Id]:Destroy()
                refs.Machines[upgrade.Id] = nil
            end
        end
    end
end

local function createPlot(worldFolder, center, plotState)
    local plotsFolder = worldFolder:FindFirstChild(WORLD_PLOTS_NAME)
    if not plotsFolder then
        plotsFolder = Instance.new("Folder")
        plotsFolder.Name = WORLD_PLOTS_NAME
        plotsFolder.Parent = worldFolder
    end

    local plotPosition, plotCFrame = getPlotPosition(plotState.PlotId, center)
    local plotModel = Instance.new("Model")
    plotModel.Name = string.format("Plot_%02d", plotState.PlotId)
    plotModel.Parent = plotsFolder

    local floor = makePart(plotModel, "Floor", TycoonConfig.PlotSize, CFrame.new(plotPosition + Vector3.new(0, TycoonConfig.PlotSize.Y * 0.5, 0)), {
        Color = Color3.fromRGB(48, 52, 64),
        Material = Enum.Material.Metal,
    })

    plotModel.PrimaryPart = floor

    makePart(plotModel, "BorderNorth", Vector3.new(TycoonConfig.PlotSize.X, 3, 3), plotCFrame * CFrame.new(0, 1.5, -TycoonConfig.PlotSize.Z * 0.5 + 1.5), {
        Color = plotState.AccentColor,
        Material = Enum.Material.Neon,
    })
    makePart(plotModel, "BorderSouth", Vector3.new(TycoonConfig.PlotSize.X, 3, 3), plotCFrame * CFrame.new(0, 1.5, TycoonConfig.PlotSize.Z * 0.5 - 1.5), {
        Color = Color3.fromRGB(32, 36, 45),
        Material = Enum.Material.Metal,
    })
    makePart(plotModel, "BorderLeft", Vector3.new(3, 3, TycoonConfig.PlotSize.Z), plotCFrame * CFrame.new(-TycoonConfig.PlotSize.X * 0.5 + 1.5, 1.5, 0), {
        Color = Color3.fromRGB(32, 36, 45),
        Material = Enum.Material.Metal,
    })
    makePart(plotModel, "BorderRight", Vector3.new(3, 3, TycoonConfig.PlotSize.Z), plotCFrame * CFrame.new(TycoonConfig.PlotSize.X * 0.5 - 1.5, 1.5, 0), {
        Color = Color3.fromRGB(32, 36, 45),
        Material = Enum.Material.Metal,
    })

    local signPost = makePart(plotModel, "PlotSignPost", Vector3.new(1.6, 14, 1.6), plotCFrame * CFrame.new(0, 7, -TycoonConfig.PlotSize.Z * 0.5 + 8), {
        Color = Color3.fromRGB(74, 81, 97),
        Material = Enum.Material.Metal,
    })
    local signBoard = makePart(plotModel, "PlotSign", Vector3.new(18, 7, 1), signPost.CFrame * CFrame.new(0, 2.5, 0), {
        Color = Color3.fromRGB(22, 26, 35),
        Material = Enum.Material.SmoothPlastic,
    })

    local signTitle = createSurfaceLabel(signBoard, Enum.NormalId.Front, Color3.fromRGB(247, 248, 252), Enum.Font.GothamBlack)
    signTitle.Text = plotState.DisplayName
    local signDetail = createSurfaceLabel(signBoard, Enum.NormalId.Back, Color3.fromRGB(177, 243, 255), Enum.Font.GothamBold)

    local claimPad = makePart(plotModel, "ClaimPad", Vector3.new(16, 1.2, 14), plotCFrame * CFrame.new(-24, 0.6, -28), {
        Color = plotState.AccentColor,
        Material = Enum.Material.Neon,
    })
    local claimLabel = createSurfaceLabel(claimPad, Enum.NormalId.Top, Color3.fromRGB(19, 24, 32), Enum.Font.GothamBlack)
    local claimPrompt = createPrompt(claimPad, TycoonConfig.ClaimPromptText, plotState.DisplayName, {
        TycoonAction = "ClaimPlot",
        PlotId = plotState.PlotId,
    })

    local collectPad = makePart(plotModel, "CollectPad", Vector3.new(16, 1.2, 14), plotCFrame * CFrame.new(24, 0.6, -28), {
        Color = Color3.fromRGB(94, 222, 230),
        Material = Enum.Material.Neon,
    })
    local collectLabel = createSurfaceLabel(collectPad, Enum.NormalId.Top, Color3.fromRGB(14, 29, 34), Enum.Font.GothamBlack)
    local collectPrompt = createPrompt(collectPad, TycoonConfig.CollectPromptText, plotState.DisplayName, {
        TycoonAction = "CollectCash",
        PlotId = plotState.PlotId,
    })

    local machinesFolder = Instance.new("Folder")
    machinesFolder.Name = "Machines"
    machinesFolder.Parent = plotModel

    local upgradeButtons = {}
    local machines = {}
    for _, upgrade in ipairs(TycoonConfig.Upgrades) do
        local button = makePart(plotModel, upgrade.Id .. "Button", Vector3.new(16, 1.2, 12), plotCFrame * CFrame.new(upgrade.RelativePosition), {
            Color = plotState.AccentColor,
            Material = Enum.Material.SmoothPlastic,
            Transparency = 0.08,
        })
        local label = createSurfaceLabel(button, Enum.NormalId.Top, Color3.fromRGB(245, 248, 255), Enum.Font.GothamBold)
        local prompt = createPrompt(button, upgrade.PromptText, plotState.DisplayName, {
            TycoonAction = "BuyUpgrade",
            PlotId = plotState.PlotId,
            UpgradeId = upgrade.Id,
        })

        upgradeButtons[upgrade.Id] = {
            Part = button,
            Prompt = prompt,
            Label = label,
        }
    end

    createCrewmate(plotModel, "PlotMascot", plotState.AccentColor, plotCFrame * CFrame.new(0, 4.2, 28))

    plotRefs[plotState.PlotId] = {
        Model = plotModel,
        PlotCFrame = plotCFrame,
        Floor = floor,
        SignDetail = signDetail,
        ClaimLabel = claimLabel,
        ClaimPrompt = claimPrompt,
        CollectLabel = collectLabel,
        CollectPrompt = collectPrompt,
        UpgradeButtons = upgradeButtons,
        MachinesFolder = machinesFolder,
        Machines = machines,
    }

    refreshPlotVisuals(plotState.PlotId)
end

local function resetPlot(plotId)
    local plotState = plotStates[plotId]
    if not plotState then
        return
    end

    if plotState.OwnerUserId then
        userToPlotId[plotState.OwnerUserId] = nil
    end

    plotState.OwnerUserId = nil
    plotState.OwnerName = nil
    plotState.PendingCash = 0
    plotState.IncomePerSecond = 0
    plotState.PurchasedUpgrades = {}
    refreshPlotVisuals(plotId)
end

local function claimPlot(player, plotId)
    local plotState = plotStates[plotId]
    if not plotState then
        return
    end

    if plotState.OwnerUserId then
        fireToast(player, string.format("%s is already claimed.", plotState.DisplayName), Color3.fromRGB(255, 158, 158))
        return
    end

    local existingPlot = getOwnedPlotState(player)
    if existingPlot then
        fireToast(player, string.format("You already own %s.", existingPlot.DisplayName), Color3.fromRGB(255, 214, 120))
        return
    end

    plotState.OwnerUserId = player.UserId
    plotState.OwnerName = player.DisplayName ~= "" and player.DisplayName or player.Name
    plotState.PendingCash = 0
    plotState.IncomePerSecond = TycoonConfig.BaseIncomePerSecond
    plotState.PurchasedUpgrades = {}
    userToPlotId[player.UserId] = plotState.PlotId

    refreshPlotVisuals(plotId)
    broadcastAllStates()
    fireToast(player, string.format("Claimed %s.", plotState.DisplayName), plotState.AccentColor)
end

local function collectCash(player, plotId)
    local plotState = plotStates[plotId]
    if not plotState or plotState.OwnerUserId ~= player.UserId then
        fireToast(player, "That is not your collection pad.", Color3.fromRGB(255, 158, 158))
        return
    end

    local amount = math.floor(plotState.PendingCash + 0.5)
    if amount <= 0 then
        fireToast(player, "No cash is waiting yet.", Color3.fromRGB(255, 214, 120))
        return
    end

    local wallet = getWallet(player)
    if not wallet then
        fireToast(player, "Your wallet is missing.", Color3.fromRGB(255, 158, 158))
        return
    end

    wallet.Value += amount
    plotState.PendingCash = 0
    refreshPlotVisuals(plotId)
    broadcastAllStates()
    fireToast(player, string.format("+%d %s", amount, Config.CurrencyName), Color3.fromRGB(163, 241, 180))
end

local function purchaseUpgrade(player, plotId, upgradeId)
    local plotState = plotStates[plotId]
    local upgrade = TycoonConfig.getUpgradeById(upgradeId)
    if not plotState or not upgrade then
        return
    end

    if plotState.OwnerUserId ~= player.UserId then
        fireToast(player, "That build pad belongs to another crewmate.", Color3.fromRGB(255, 158, 158))
        return
    end

    if plotState.PurchasedUpgrades[upgrade.Id] then
        fireToast(player, string.format("%s is already built.", upgrade.DisplayName), Color3.fromRGB(255, 214, 120))
        return
    end

    if not isUpgradeAvailable(plotState, upgrade.Id) then
        fireToast(player, "Finish the previous room first.", Color3.fromRGB(255, 214, 120))
        return
    end

    local wallet = getWallet(player)
    if not wallet then
        fireToast(player, "Your wallet is missing.", Color3.fromRGB(255, 158, 158))
        return
    end

    if wallet.Value < upgrade.Cost then
        fireToast(player, string.format("You need %d %s.", upgrade.Cost, Config.CurrencyName), Color3.fromRGB(255, 158, 158))
        return
    end

    wallet.Value -= upgrade.Cost
    plotState.PurchasedUpgrades[upgrade.Id] = true
    plotState.IncomePerSecond += upgrade.IncomePerSecond

    refreshPlotVisuals(plotId)
    broadcastAllStates()
    fireToast(
        player,
        string.format("%s built. Income is now %d / sec.", upgrade.DisplayName, plotState.IncomePerSecond),
        plotState.AccentColor
    )
end

local function handleClientAction(player, payload)
    if type(payload) ~= "table" then
        return
    end

    local action = payload.Action
    if type(action) ~= "string" then
        return
    end

    if action == "ClaimPlot" then
        local plotId = tonumber(payload.PlotId)
        if plotId then
            claimPlot(player, plotId)
        end
        return
    end

    if action == "CollectCash" then
        local plotId = tonumber(payload.PlotId)
        if not plotId then
            local ownedPlot = getOwnedPlotState(player)
            plotId = ownedPlot and ownedPlot.PlotId or nil
        end

        if plotId then
            collectCash(player, plotId)
        end
        return
    end

    if action == "BuyUpgrade" then
        local plotId = tonumber(payload.PlotId)
        if not plotId then
            local ownedPlot = getOwnedPlotState(player)
            plotId = ownedPlot and ownedPlot.PlotId or nil
        end

        local upgradeId = payload.UpgradeId
        if plotId and type(upgradeId) == "string" then
            purchaseUpgrade(player, plotId, upgradeId)
        end
    end
end

local function bindPrompt(prompt)
    if promptBindings[prompt] then
        return
    end

    promptBindings[prompt] = true
    prompt.Triggered:Connect(function(player)
        local action = prompt:GetAttribute("TycoonAction")
        local plotId = prompt:GetAttribute("PlotId")

        if type(plotId) ~= "number" then
            return
        end

        if action == "ClaimPlot" then
            claimPlot(player, plotId)
            return
        end

        if action == "CollectCash" then
            collectCash(player, plotId)
            return
        end

        if action == "BuyUpgrade" then
            local upgradeId = prompt:GetAttribute("UpgradeId")
            if type(upgradeId) == "string" then
                purchaseUpgrade(player, plotId, upgradeId)
            end
        end
    end)
end

local function prepareWorld(forceReplace)
    local world = getOrCreateWorld(forceReplace)
    local center = getHubCenter()

    Workspace:SetAttribute("AmongUsTycoonPlotCount", TycoonConfig.PlotCount)
    Workspace:SetAttribute("AmongUsTycoonCenterX", center.X)
    Workspace:SetAttribute("AmongUsTycoonCenterY", center.Y)
    Workspace:SetAttribute("AmongUsTycoonCenterZ", center.Z)

    createHub(world, center)
    for _, plotState in ipairs(plotStates) do
        createPlot(world, center, plotState)
    end

    NpcShopService.spawnVendorInWorkspace(true)

    for _, refs in pairs(plotRefs) do
        bindPrompt(refs.ClaimPrompt)
        bindPrompt(refs.CollectPrompt)
        for _, buttonRefs in pairs(refs.UpgradeButtons) do
            bindPrompt(buttonRefs.Prompt)
        end
    end

    return {
        PlotCount = TycoonConfig.PlotCount,
        Center = center,
    }
end

local function bindWallet(player)
    if walletConnections[player] then
        walletConnections[player]:Disconnect()
        walletConnections[player] = nil
    end

    local wallet = getWallet(player)
    if wallet then
        walletConnections[player] = wallet.Changed:Connect(function()
            sendStateToPlayer(player)
        end)
    end
end

local function releasePlayerPlot(player)
    local plotId = userToPlotId[player.UserId]
    if not plotId then
        return
    end

    resetPlot(plotId)
    broadcastAllStates()
end

local function startIncomeLoop()
    task.spawn(function()
        while started do
            task.wait(TycoonConfig.IncomeTickSeconds)

            local anyChanged = false
            for _, plotState in ipairs(plotStates) do
                if plotState.OwnerUserId then
                    plotState.PendingCash += plotState.IncomePerSecond * TycoonConfig.IncomeTickSeconds
                    refreshPlotVisuals(plotState.PlotId)
                    anyChanged = true
                end
            end

            if anyChanged then
                broadcastAllStates()
            end
        end
    end)
end

function TycoonService.prepareInStudio(forceReplace)
    initializePlotStates()
    return prepareWorld(forceReplace == nil and true or forceReplace)
end

function TycoonService.start()
    if started then
        return
    end

    started = true
    initializePlotStates()
    ensureRemotes()

    requestStateFunction.OnServerInvoke = function(player)
        return buildPlayerState(player)
    end

    actionRemote.OnServerEvent:Connect(handleClientAction)

    prepareWorld(true)

    for _, player in ipairs(Players:GetPlayers()) do
        bindWallet(player)
        task.delay(1, function()
            if player.Parent == Players then
                sendStateToPlayer(player)
            end
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        task.delay(1, function()
            if player.Parent == Players then
                bindWallet(player)
                sendStateToPlayer(player)
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if walletConnections[player] then
            walletConnections[player]:Disconnect()
            walletConnections[player] = nil
        end

        releasePlayerPlot(player)
    end)

    startIncomeLoop()
end

return TycoonService
