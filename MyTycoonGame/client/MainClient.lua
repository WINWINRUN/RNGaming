
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Config"))

print("[Client] Loaded MyTycoon for " .. player.Name)

if Config.Template == "tycoon" then
    print("[Client] Tycoon UI and controls can be initialized here")
elseif Config.Template == "obstacle_course" then
    print("[Client] Obby UI and checkpoint display can be initialized here")
else
    print("[Client] Basic game client is ready")
end
