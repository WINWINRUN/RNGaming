local ServerScriptService = game:GetService("ServerScriptService")

local NpcShopService = require(ServerScriptService:WaitForChild("NpcShopService"))
local created = NpcShopService.spawnVendorInWorkspace(true)

assert(created, "Failed to create the Among Us vendor in Workspace.VendorStalls")
print("[RNGaming] Created AmongUsVendorSpot in Workspace.VendorStalls")
