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
