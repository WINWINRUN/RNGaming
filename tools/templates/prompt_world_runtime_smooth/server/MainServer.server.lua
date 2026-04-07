local ServerScriptService = game:GetService("ServerScriptService")

local PromptWorldService = require(ServerScriptService:WaitForChild("PromptWorldService"))

local ok, result = pcall(function()
    return PromptWorldService.start()
end)

if not ok then
    warn("[PromptWorld] World generation failed:", result)
    return
end

if result then
    print(string.format("[PromptWorld] Generated world '%s'", tostring(result.Name)))
end
