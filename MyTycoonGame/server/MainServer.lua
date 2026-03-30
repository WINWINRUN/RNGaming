
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local function onPlayerAdded(player)
    print("[Server] Player joined:", player.Name)
end

Players.PlayerAdded:Connect(onPlayerAdded)

local function setupGame()
    print("[Server] Starting MyTycoon (tycoon)")

    if Config.Template == "tycoon" then
        print("[Server] Preparing tycoon systems")
    elseif Config.Template == "obstacle_course" then
        print("[Server] Preparing obstacle course systems")
    else
        print("[Server] Basic game started")
    end
end

setupGame()
