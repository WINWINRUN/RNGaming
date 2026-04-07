local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local WalletService = {}
local started = false

local function ensureWallet(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local wallet = leaderstats:FindFirstChild(Config.CurrencyName)
    if not wallet then
        wallet = Instance.new("IntValue")
        wallet.Name = Config.CurrencyName
        wallet.Value = Config.StarterCurrency
        wallet.Parent = leaderstats
    end
end

function WalletService.start()
    if started then
        return
    end

    started = true

    for _, player in ipairs(Players:GetPlayers()) do
        ensureWallet(player)
    end

    Players.PlayerAdded:Connect(ensureWallet)
end

return WalletService
