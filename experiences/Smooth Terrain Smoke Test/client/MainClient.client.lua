local Workspace = game:GetService("Workspace")

local function reportPromptWorld()
    local title = Workspace:GetAttribute("PromptWorldTitle")
    local renderStyle = Workspace:GetAttribute("PromptWorldRenderStyle")
    local terrain = Workspace:GetAttribute("PromptWorldTerrain")
    if title and renderStyle and terrain then
        print(string.format("[PromptWorld] %s (%s terrain, %s renderer)", title, tostring(terrain), tostring(renderStyle)))
    end
end

Workspace:GetAttributeChangedSignal("PromptWorldTitle"):Connect(reportPromptWorld)
Workspace:GetAttributeChangedSignal("PromptWorldRenderStyle"):Connect(reportPromptWorld)
Workspace:GetAttributeChangedSignal("PromptWorldTerrain"):Connect(reportPromptWorld)
reportPromptWorld()
