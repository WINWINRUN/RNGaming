
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local TycoonManager = {}

function TycoonManager:start()
    print("[TycoonManager] Initializing tycoon template")
    WorldBuilder:build()
end

return TycoonManager
