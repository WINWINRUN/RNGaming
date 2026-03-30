
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local TycoonManager = {}

function TycoonManager:start()
    print("[TycoonManager] Initializing tycoon template")
end

return TycoonManager
