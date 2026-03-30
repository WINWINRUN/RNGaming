
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local function onPlayerAdded(player)
    print("[Server] Player joined:", player.Name)
end

local function requireServerModule(moduleName)
    local module = ServerScriptService:FindFirstChild(moduleName)

    if module and module:IsA("ModuleScript") then
        return require(module)
    end

    return nil
end

local function buildTestWorldModels()
    local testFolder = ServerStorage:FindFirstChild("TestWorldModels")
    if not testFolder then
        return
    end

    local buildModule = testFolder:FindFirstChild("BuildTestFolder")
    if not buildModule or not buildModule:IsA("ModuleScript") then
        return
    end

    local ok, builder = pcall(require, buildModule)
    if not ok then
        warn("[Server] Failed to load test world model builder:", builder)
        return
    end

    if type(builder) == "table" and builder.build then
        builder.build(testFolder)
        print("[Server] Generated sample models in ServerStorage/TestWorldModels")
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)

local function setupGame()
    print("[Server] Starting MyTycoon (tycoon)")

    if Config.Template == "tycoon" then
        print("[Server] Preparing tycoon systems")
        requireServerModule("Leaderstats")

        local TycoonManager = requireServerModule("TycoonManager")
        if TycoonManager and TycoonManager.start then
            TycoonManager:start()
        end
    elseif Config.Template == "obstacle_course" then
        print("[Server] Preparing obstacle course systems")
        local CheckpointManager = requireServerModule("CheckpointManager")
        if CheckpointManager and CheckpointManager.initialize then
            CheckpointManager:initialize()
        end
    elseif Config.Template == "waiting_in_line" then
        print("[Server] Preparing waiting-in-line systems")
        requireServerModule("QueueManager")
    elseif Config.Template == "turn_based_battle" then
        print("[Server] Preparing turn-based battle systems")
        requireServerModule("BattleManager")
    else
        print("[Server] Basic game started")
        local BasicServer = requireServerModule("BasicServer")
        if BasicServer and BasicServer.start then
            BasicServer:start()
        end
    end
end

buildTestWorldModels()
setupGame()
