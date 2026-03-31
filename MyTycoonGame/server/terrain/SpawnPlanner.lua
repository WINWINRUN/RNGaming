local Workspace = game:GetService("Workspace")

local SpawnPlanner = {}

local function getManagedCenter(profile)
    local center = profile.ManagedCenter
    return Vector3.new(center.X, center.Y, center.Z)
end

function SpawnPlanner.place(profile)
    local existing = Workspace:FindFirstChild("GeneratedSpawn")
    if existing then
        existing:Destroy()
    end

    local center = getManagedCenter(profile)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "GeneratedSpawn"
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.CanCollide = true
    spawn.Color = Color3.fromRGB(104, 226, 255)
    spawn.Material = Enum.Material.Neon
    spawn.Transparency = 0.3
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.CFrame = CFrame.new(center.X, profile.Spawn.Height + 3, center.Z)
    spawn.Parent = Workspace
    return spawn
end

return SpawnPlanner
