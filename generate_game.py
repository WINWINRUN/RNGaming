import argparse
import json
import os
import textwrap
from pathlib import Path

PROJECT_TEMPLATES = {
    "basic": {
        "description": "Generic starter game scaffold.",
        "features": ["player join handling", "shared config", "starter client/server"]
    },
    "tycoon": {
        "description": "Tycoon-style sky island hub with money, leaderstats, island bridges, and shop-to-RNG travel lanes.",
        "features": ["leaderstats", "sky island world builder", "shop and RNG travel lanes"]
    },
    "obstacle_course": {
        "description": "Obstacle course base with checkpoints and player progress.",
        "features": ["checkpoint manager", "obby UI", "spawn support"]
    },
    "waiting_in_line": {
        "description": "Waiting-in-line game with queue mechanics, RNG pets, and line-jumping effects.",
        "features": ["player queue", "pet rolling", "move ahead/back effects"]
    },
    "turn_based_battle": {
        "description": "Turn-based battle game with player actions and combat state.",
        "features": ["battle state", "player turns", "attack/defend actions"]
    }
}

BASE_FILES = {
    "server/MainServer.lua": textwrap.dedent("""
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
            print("[Server] Starting {game_name} ({template})")

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
    """),
    "client/MainClient.lua": textwrap.dedent("""
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local player = Players.LocalPlayer
        local Config = require(ReplicatedStorage:WaitForChild("Config"))

        print("[Client] Loaded {game_name} for " .. player.Name)

        if Config.Template == "tycoon" then
            print("[Client] Tycoon UI and controls can be initialized here")
        elseif Config.Template == "obstacle_course" then
            print("[Client] Obby UI and checkpoint display can be initialized here")
        elseif Config.Template == "waiting_in_line" then
            print("[Client] Waiting in line client hooks can be initialized here")
        elseif Config.Template == "turn_based_battle" then
            print("[Client] Turn-based battle client hooks can be initialized here")
        else
            print("[Client] Basic game client is ready")
        end
    """),
    "shared/Config.lua": textwrap.dedent("""
        local Config = {{
            GameName = "{game_name}",
            Template = "{template}",
            Author = "{author}",
            Version = "{version}",
            GroupId = {group_id_literal},
            GroupName = {group_name_literal},
        }}

        return Config
    """)
}

COMMON_FILES = {
    "test/ModelLibrary.lua": textwrap.dedent("""
        local ModelLibrary = {}

        local CYLINDER_ROTATION = CFrame.Angles(0, 0, math.rad(90))

        local function createInstance(className, parent, properties)
            local instance = Instance.new(className)

            for key, value in pairs(properties or {}) do
                instance[key] = value
            end

            instance.Parent = parent
            return instance
        end

        local function createPart(parent, properties)
            local defaults = {
                Anchored = true,
                TopSurface = Enum.SurfaceType.Smooth,
                BottomSurface = Enum.SurfaceType.Smooth,
                Material = Enum.Material.SmoothPlastic,
            }

            for key, value in pairs(properties or {}) do
                defaults[key] = value
            end

            return createInstance("Part", parent, defaults)
        end

        local function createRootPart(parent, position)
            return createPart(parent, {
                Name = "Root",
                Size = Vector3.new(1, 1, 1),
                Position = position,
                Transparency = 1,
                CanCollide = false,
                CanQuery = false,
                CanTouch = false,
            })
        end

        function ModelLibrary.createFloatingPine(parent, origin)
            local model = createInstance("Model", parent, {Name = "FloatingPine"})
            local root = createRootPart(model, origin)

            createPart(model, {
                Name = "IslandCore",
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(20, 14, 20),
                Position = origin + Vector3.new(0, -2, 0),
                Material = Enum.Material.Slate,
                Color = Color3.fromRGB(97, 102, 112),
            })

            createPart(model, {
                Name = "GrassCap",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(3, 18, 18),
                CFrame = CFrame.new(origin + Vector3.new(0, 4, 0)) * CYLINDER_ROTATION,
                Material = Enum.Material.Grass,
                Color = Color3.fromRGB(112, 186, 92),
            })

            createPart(model, {
                Name = "Trunk",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(10, 3.5, 3.5),
                CFrame = CFrame.new(origin + Vector3.new(0, 10, 0)) * CYLINDER_ROTATION,
                Material = Enum.Material.Wood,
                Color = Color3.fromRGB(117, 84, 57),
            })

            createPart(model, {
                Name = "CanopyBase",
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(11, 11, 11),
                Position = origin + Vector3.new(0, 15, 0),
                Material = Enum.Material.Grass,
                Color = Color3.fromRGB(78, 149, 73),
            })

            createPart(model, {
                Name = "CanopyLeft",
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(8, 8, 8),
                Position = origin + Vector3.new(-3.5, 14, 1.5),
                Material = Enum.Material.Grass,
                Color = Color3.fromRGB(88, 161, 82),
            })

            createPart(model, {
                Name = "CanopyRight",
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(8, 8, 8),
                Position = origin + Vector3.new(3.5, 14, -1.5),
                Material = Enum.Material.Grass,
                Color = Color3.fromRGB(88, 161, 82),
            })

            model.PrimaryPart = root
            return model
        end

        function ModelLibrary.createCrystalCluster(parent, origin)
            local model = createInstance("Model", parent, {Name = "CrystalCluster"})
            local root = createRootPart(model, origin)
            local crystalData = {
                {offset = Vector3.new(0, 6, 0), size = Vector3.new(3, 12, 3), color = Color3.fromRGB(86, 236, 255), rotation = CFrame.Angles(math.rad(6), 0, math.rad(8))},
                {offset = Vector3.new(-4, 4, 2), size = Vector3.new(2.5, 8, 2.5), color = Color3.fromRGB(122, 255, 251), rotation = CFrame.Angles(math.rad(-8), math.rad(18), math.rad(-6))},
                {offset = Vector3.new(3, 3.5, -3), size = Vector3.new(2, 7, 2), color = Color3.fromRGB(132, 198, 255), rotation = CFrame.Angles(math.rad(10), math.rad(-22), math.rad(5))},
                {offset = Vector3.new(5, 2.8, 1), size = Vector3.new(1.8, 5.5, 1.8), color = Color3.fromRGB(168, 255, 255), rotation = CFrame.Angles(math.rad(-12), math.rad(8), math.rad(-10))},
            }

            createPart(model, {
                Name = "RockBase",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(4, 16, 16),
                CFrame = CFrame.new(origin) * CYLINDER_ROTATION,
                Material = Enum.Material.Slate,
                Color = Color3.fromRGB(89, 94, 106),
            })

            for index, crystal in ipairs(crystalData) do
                createPart(model, {
                    Name = "Crystal" .. index,
                    Size = crystal.size,
                    CFrame = CFrame.new(origin + crystal.offset) * crystal.rotation,
                    Material = Enum.Material.Neon,
                    Color = crystal.color,
                })
            end

            model.PrimaryPart = root
            return model
        end

        function ModelLibrary.createStoneArch(parent, origin)
            local model = createInstance("Model", parent, {Name = "StoneArch"})
            local root = createRootPart(model, origin)

            createPart(model, {
                Name = "LeftPillar",
                Size = Vector3.new(5, 22, 5),
                Position = origin + Vector3.new(-8, 11, 0),
                Material = Enum.Material.Slate,
                Color = Color3.fromRGB(102, 107, 119),
            })

            createPart(model, {
                Name = "RightPillar",
                Size = Vector3.new(5, 22, 5),
                Position = origin + Vector3.new(8, 11, 0),
                Material = Enum.Material.Slate,
                Color = Color3.fromRGB(102, 107, 119),
            })

            createPart(model, {
                Name = "TopBeam",
                Size = Vector3.new(24, 4, 6),
                Position = origin + Vector3.new(0, 22, 0),
                Material = Enum.Material.Slate,
                Color = Color3.fromRGB(120, 127, 140),
            })

            createPart(model, {
                Name = "RuneStone",
                Size = Vector3.new(14, 2, 5),
                Position = origin + Vector3.new(0, 15, 0),
                Material = Enum.Material.Neon,
                Color = Color3.fromRGB(123, 207, 255),
                CanCollide = false,
            })

            model.PrimaryPart = root
            return model
        end

        function ModelLibrary.createMarketStand(parent, origin)
            local model = createInstance("Model", parent, {Name = "MarketStand"})
            local root = createRootPart(model, origin)
            local postOffsets = {
                Vector3.new(-6, 6, -4),
                Vector3.new(6, 6, -4),
                Vector3.new(-6, 6, 4),
                Vector3.new(6, 6, 4),
            }

            createPart(model, {
                Name = "Base",
                Size = Vector3.new(18, 1, 14),
                Position = origin,
                Material = Enum.Material.WoodPlanks,
                Color = Color3.fromRGB(115, 85, 58),
            })

            createPart(model, {
                Name = "Counter",
                Size = Vector3.new(16, 4, 5),
                Position = origin + Vector3.new(0, 2.5, 4.5),
                Material = Enum.Material.WoodPlanks,
                Color = Color3.fromRGB(136, 98, 65),
            })

            for index, offset in ipairs(postOffsets) do
                createPart(model, {
                    Name = "Post" .. index,
                    Size = Vector3.new(1.5, 12, 1.5),
                    Position = origin + offset,
                    Material = Enum.Material.Wood,
                    Color = Color3.fromRGB(104, 72, 48),
                })
            end

            createPart(model, {
                Name = "Roof",
                Size = Vector3.new(20, 2, 16),
                Position = origin + Vector3.new(0, 13, 0),
                Material = Enum.Material.Fabric,
                Color = Color3.fromRGB(232, 182, 72),
            })

            model.PrimaryPart = root
            return model
        end

        function ModelLibrary.createCloudPad(parent, origin)
            local model = createInstance("Model", parent, {Name = "CloudPad"})
            local root = createRootPart(model, origin)
            local cloudOffsets = {
                Vector3.new(-4, 2, 0),
                Vector3.new(4, 2, 1),
                Vector3.new(0, 2.5, -3),
                Vector3.new(0, 2, 4),
            }

            createPart(model, {
                Name = "Pad",
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(2, 18, 18),
                CFrame = CFrame.new(origin + Vector3.new(0, 3, 0)) * CYLINDER_ROTATION,
                Material = Enum.Material.Neon,
                Color = Color3.fromRGB(255, 243, 161),
            })

            for index, offset in ipairs(cloudOffsets) do
                createPart(model, {
                    Name = "Cloud" .. index,
                    Shape = Enum.PartType.Ball,
                    Size = Vector3.new(8, 8, 8),
                    Position = origin + offset,
                    Material = Enum.Material.SmoothPlastic,
                    Color = Color3.fromRGB(244, 247, 255),
                    Transparency = 0.08,
                })
            end

            createPart(model, {
                Name = "Beacon",
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(3, 3, 3),
                Position = origin + Vector3.new(0, 8, 0),
                Material = Enum.Material.Neon,
                Color = Color3.fromRGB(120, 223, 255),
                CanCollide = false,
            })

            model.PrimaryPart = root
            return model
        end

        return ModelLibrary
    """),
    "test/BuildTestFolder.lua": textwrap.dedent("""
        local ModelLibrary = require(script.Parent:WaitForChild("ModelLibrary"))

        local BuildTestFolder = {}

        local SAMPLE_MODELS = {
            {builder = "createFloatingPine", position = Vector3.new(0, 0, 0)},
            {builder = "createCrystalCluster", position = Vector3.new(48, 0, 0)},
            {builder = "createStoneArch", position = Vector3.new(106, 0, 0)},
            {builder = "createMarketStand", position = Vector3.new(170, 0, 0)},
            {builder = "createCloudPad", position = Vector3.new(232, 0, 0)},
        }

        function BuildTestFolder.build(parent)
            local generatedFolder = parent:FindFirstChild("GeneratedModels")
            if generatedFolder then
                generatedFolder:Destroy()
            end

            generatedFolder = Instance.new("Folder")
            generatedFolder.Name = "GeneratedModels"
            generatedFolder.Parent = parent

            for _, entry in ipairs(SAMPLE_MODELS) do
                local builder = ModelLibrary[entry.builder]
                if builder then
                    builder(generatedFolder, entry.position)
                end
            end

            return generatedFolder
        end

        return BuildTestFolder
    """),
    "studio/SpawnTestModels.plugin.lua": textwrap.dedent("""
        local ChangeHistoryService = game:GetService("ChangeHistoryService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Selection = game:GetService("Selection")
        local ServerStorage = game:GetService("ServerStorage")
        local Workspace = game:GetService("Workspace")

        local TOOLBAR_ICON = "rbxassetid://14978048121"
        local DEFAULT_FOLDER_NAME = "TestWorldPreview"

        local toolbar = plugin:CreateToolbar("RNGaming")
        local spawnButton = toolbar:CreateButton(
            "SpawnTestModels",
            "Clone the generated test models into Workspace for previewing.",
            TOOLBAR_ICON,
            "Spawn Test Models"
        )
        local clearButton = toolbar:CreateButton(
            "ClearTestModels",
            "Remove the Workspace preview folder created by the test model plugin.",
            TOOLBAR_ICON,
            "Clear Test Preview"
        )

        spawnButton.ClickableWhenViewportHidden = true
        clearButton.ClickableWhenViewportHidden = true

        local function getConfig()
            local configModule = ReplicatedStorage:FindFirstChild("Config")
            if configModule and configModule:IsA("ModuleScript") then
                local ok, config = pcall(require, configModule)
                if ok and type(config) == "table" then
                    return config
                end
            end

            return {}
        end

        local function getPreviewFolderName()
            local config = getConfig()
            local groupName = config.GroupName or "RNGaming"
            return groupName .. "_" .. DEFAULT_FOLDER_NAME
        end

        local function getTestFolder()
            local testFolder = ServerStorage:FindFirstChild("TestWorldModels")
            if not testFolder then
                error("TestWorldModels was not found in ServerStorage. Connect Rojo and sync the project first.")
            end

            return testFolder
        end

        local function getBuildModule(testFolder)
            testFolder = testFolder or getTestFolder()

            local buildModule = testFolder:FindFirstChild("BuildTestFolder")
            if not buildModule or not buildModule:IsA("ModuleScript") then
                error("BuildTestFolder module is missing from ServerStorage/TestWorldModels.")
            end

            return buildModule
        end

        local function clearPreview()
            local previewFolder = Workspace:FindFirstChild(getPreviewFolderName())
            if previewFolder then
                previewFolder:Destroy()
                ChangeHistoryService:SetWaypoint("Clear Test World Preview")
            end
        end

        local function cloneChildren(source, target)
            for _, child in ipairs(source:GetChildren()) do
                child:Clone().Parent = target
            end
        end

        local function spawnSyncedModels(testFolder, previewFolder)
            local syncedFolder = testFolder:FindFirstChild("SyncedModels")
            if not syncedFolder then
                return false
            end

            local placedAny = false
            local worldModel = syncedFolder:FindFirstChild("SkyIslandHub") or syncedFolder:FindFirstChild("SkyIslandHubPreview")
            if worldModel then
                worldModel:Clone().Parent = previewFolder
                placedAny = true
            end

            local galleryFolder = Instance.new("Folder")
            galleryFolder.Name = "SyncedModelGallery"
            galleryFolder.Parent = previewFolder

            local nextX = -144
            for _, child in ipairs(syncedFolder:GetChildren()) do
                if child ~= worldModel and child.Name ~= "SkyIslandHubPreview" then
                    local clone = child:Clone()
                    clone.Parent = galleryFolder

                    if clone:IsA("Model") then
                        clone:PivotTo(CFrame.new(nextX, 42, 210))
                    elseif clone:IsA("BasePart") then
                        clone.CFrame = CFrame.new(nextX, 42, 210)
                    end

                    nextX = nextX + 72
                    placedAny = true
                end
            end

            if not placedAny then
                galleryFolder:Destroy()
            end

            return placedAny
        end

        local function spawnRuntimeModels(testFolder, previewFolder)
            local buildModule = getBuildModule(testFolder)
            local ok, builder = pcall(require, buildModule)
            if not ok then
                error(builder)
            end

            local generatedFolder = builder.build(testFolder)
            cloneChildren(generatedFolder, previewFolder)
        end

        local function spawnPreview()
            local testFolder = getTestFolder()
            clearPreview()

            local previewFolder = Instance.new("Folder")
            previewFolder.Name = getPreviewFolderName()
            previewFolder.Parent = Workspace

            local spawnedSynced = spawnSyncedModels(testFolder, previewFolder)
            if not spawnedSynced then
                spawnRuntimeModels(testFolder, previewFolder)
            end

            local config = getConfig()
            if config.GroupId then
                previewFolder:SetAttribute("GroupId", config.GroupId)
            end
            if config.GroupName then
                previewFolder:SetAttribute("GroupName", config.GroupName)
            end

            Selection:Set({previewFolder})
            ChangeHistoryService:SetWaypoint("Spawn Test World Preview")
        end

        spawnButton.Click:Connect(function()
            local ok, result = pcall(spawnPreview)
            if not ok then
                warn("[SpawnTestModels.plugin] " .. tostring(result))
            end
        end)

        clearButton.Click:Connect(function()
            local ok, result = pcall(clearPreview)
            if not ok then
                warn("[SpawnTestModels.plugin] " .. tostring(result))
            end
        end)
    """),
    "studio/SpawnTestModels.command.lua": textwrap.dedent("""
        local ServerStorage = game:GetService("ServerStorage")
        local Workspace = game:GetService("Workspace")

        local testFolder = ServerStorage:WaitForChild("TestWorldModels")
        local previewFolder = Workspace:FindFirstChild("CommandBarTestWorldPreview")

        if previewFolder then
            previewFolder:Destroy()
        end

        previewFolder = Instance.new("Folder")
        previewFolder.Name = "CommandBarTestWorldPreview"
        previewFolder.Parent = Workspace

        local syncedFolder = testFolder:FindFirstChild("SyncedModels")
        if syncedFolder and #syncedFolder:GetChildren() > 0 then
            local worldModel = syncedFolder:FindFirstChild("SkyIslandHub") or syncedFolder:FindFirstChild("SkyIslandHubPreview")
            if worldModel then
                worldModel:Clone().Parent = previewFolder
            end

            local galleryFolder = Instance.new("Folder")
            galleryFolder.Name = "SyncedModelGallery"
            galleryFolder.Parent = previewFolder

            local nextX = -144
            for _, child in ipairs(syncedFolder:GetChildren()) do
                if child ~= worldModel and child.Name ~= "SkyIslandHubPreview" then
                    local clone = child:Clone()
                    clone.Parent = galleryFolder

                    if clone:IsA("Model") then
                        clone:PivotTo(CFrame.new(nextX, 42, 210))
                    elseif clone:IsA("BasePart") then
                        clone.CFrame = CFrame.new(nextX, 42, 210)
                    end

                    nextX = nextX + 72
                end
            end
        else
            local buildModule = require(testFolder:WaitForChild("BuildTestFolder"))
            local generatedFolder = buildModule.build(testFolder)

            for _, child in ipairs(generatedFolder:GetChildren()) do
                child:Clone().Parent = previewFolder
            end
        end

        print("Spawned CommandBarTestWorldPreview in Workspace")
    """),
}


def rgb(red: int, green: int, blue: int) -> list[float]:
    return [round(component / 255, 6) for component in (red, green, blue)]


def instance_node(class_name: str, name: str | None = None, properties=None, children=None) -> dict:
    node = {"ClassName": class_name}

    if name is not None:
        node["Name"] = name
    if properties:
        node["Properties"] = properties
    if children:
        node["Children"] = children

    return node


def model_node(name: str, children: list[dict]) -> dict:
    return instance_node("Model", name=name, children=children)


def top_level_model(children: list[dict]) -> dict:
    return instance_node("Model", children=children)


def part_node(
    name: str,
    size: list[float],
    position: list[float],
    *,
    color: list[float] | None = None,
    material: str = "SmoothPlastic",
    shape: str | None = None,
    orientation: list[float] | None = None,
    anchored: bool = True,
    transparency: float | None = None,
    can_collide: bool | None = None,
    can_query: bool | None = None,
    can_touch: bool | None = None,
) -> dict:
    properties = {
        "Anchored": anchored,
        "Size": size,
        "Position": position,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
        "Material": material,
    }

    if color is not None:
        properties["Color"] = color
    if shape is not None:
        properties["Shape"] = shape
    if orientation is not None:
        properties["Orientation"] = orientation
    if transparency is not None:
        properties["Transparency"] = transparency
    if can_collide is not None:
        properties["CanCollide"] = can_collide
    if can_query is not None:
        properties["CanQuery"] = can_query
    if can_touch is not None:
        properties["CanTouch"] = can_touch

    return instance_node("Part", name=name, properties=properties)


def make_floating_pine_model() -> dict:
    return top_level_model(
        [
            part_node("IslandCore", [20, 14, 20], [0, -2, 0], color=rgb(97, 102, 112), material="Slate", shape="Ball"),
            part_node("GrassCap", [3, 18, 18], [0, 4, 0], color=rgb(112, 186, 92), material="Grass", shape="Cylinder", orientation=[0, 0, 90]),
            part_node("Trunk", [10, 3.5, 3.5], [0, 10, 0], color=rgb(117, 84, 57), material="Wood", shape="Cylinder", orientation=[0, 0, 90]),
            part_node("CanopyBase", [11, 11, 11], [0, 15, 0], color=rgb(78, 149, 73), material="Grass", shape="Ball"),
            part_node("CanopyLeft", [8, 8, 8], [-3.5, 14, 1.5], color=rgb(88, 161, 82), material="Grass", shape="Ball"),
            part_node("CanopyRight", [8, 8, 8], [3.5, 14, -1.5], color=rgb(88, 161, 82), material="Grass", shape="Ball"),
        ],
    )


def make_crystal_cluster_model() -> dict:
    return top_level_model(
        [
            part_node("RockBase", [4, 16, 16], [0, 0, 0], color=rgb(89, 94, 106), material="Slate", shape="Cylinder", orientation=[0, 0, 90]),
            part_node("Crystal1", [3, 12, 3], [0, 6, 0], color=rgb(86, 236, 255), material="Neon", orientation=[6, 0, 8]),
            part_node("Crystal2", [2.5, 8, 2.5], [-4, 4, 2], color=rgb(122, 255, 251), material="Neon", orientation=[-8, 18, -6]),
            part_node("Crystal3", [2, 7, 2], [3, 3.5, -3], color=rgb(132, 198, 255), material="Neon", orientation=[10, -22, 5]),
            part_node("Crystal4", [1.8, 5.5, 1.8], [5, 2.8, 1], color=rgb(168, 255, 255), material="Neon", orientation=[-12, 8, -10]),
        ],
    )


def make_stone_arch_model() -> dict:
    return top_level_model(
        [
            part_node("LeftPillar", [5, 22, 5], [-8, 11, 0], color=rgb(102, 107, 119), material="Slate"),
            part_node("RightPillar", [5, 22, 5], [8, 11, 0], color=rgb(102, 107, 119), material="Slate"),
            part_node("TopBeam", [24, 4, 6], [0, 22, 0], color=rgb(120, 127, 140), material="Slate"),
            part_node("RuneStone", [14, 2, 5], [0, 15, 0], color=rgb(123, 207, 255), material="Neon", can_collide=False),
        ],
    )


def make_market_stand_model() -> dict:
    return top_level_model(
        [
            part_node("Base", [18, 1, 14], [0, 0, 0], color=rgb(115, 85, 58), material="WoodPlanks"),
            part_node("Counter", [16, 4, 5], [0, 2.5, 4.5], color=rgb(136, 98, 65), material="WoodPlanks"),
            part_node("Post1", [1.5, 12, 1.5], [-6, 6, -4], color=rgb(104, 72, 48), material="Wood"),
            part_node("Post2", [1.5, 12, 1.5], [6, 6, -4], color=rgb(104, 72, 48), material="Wood"),
            part_node("Post3", [1.5, 12, 1.5], [-6, 6, 4], color=rgb(104, 72, 48), material="Wood"),
            part_node("Post4", [1.5, 12, 1.5], [6, 6, 4], color=rgb(104, 72, 48), material="Wood"),
            part_node("Roof", [20, 2, 16], [0, 13, 0], color=rgb(232, 182, 72), material="Fabric"),
        ],
    )


def make_cloud_pad_model() -> dict:
    return top_level_model(
        [
            part_node("Pad", [2, 18, 18], [0, 3, 0], color=rgb(255, 243, 161), material="Neon", shape="Cylinder", orientation=[0, 0, 90]),
            part_node("Cloud1", [8, 8, 8], [-4, 2, 0], color=rgb(244, 247, 255), shape="Ball", transparency=0.08),
            part_node("Cloud2", [8, 8, 8], [4, 2, 1], color=rgb(244, 247, 255), shape="Ball", transparency=0.08),
            part_node("Cloud3", [8, 8, 8], [0, 2.5, -3], color=rgb(244, 247, 255), shape="Ball", transparency=0.08),
            part_node("Cloud4", [8, 8, 8], [0, 2, 4], color=rgb(244, 247, 255), shape="Ball", transparency=0.08),
            part_node("Beacon", [3, 3, 3], [0, 8, 0], color=rgb(120, 223, 255), material="Neon", shape="Ball", can_collide=False),
        ],
    )


def make_preview_island(name: str, position: list[float], bridge_target_z: float, cap_color: list[float]) -> dict:
    x_pos, y_pos, z_pos = position
    bridge_length = abs(z_pos - bridge_target_z)
    bridge_midpoint = (z_pos + bridge_target_z) / 2

    return model_node(
        name,
        [
            part_node("IslandCore", [36, 22, 36], [x_pos, y_pos - 10, z_pos], color=rgb(93, 99, 110), material="Slate", shape="Ball"),
            part_node("GrassCap", [4, 36, 36], [x_pos, y_pos, z_pos], color=cap_color, material="Grass", shape="Cylinder", orientation=[0, 0, 90]),
            part_node("LandingPlate", [16, 2, 16], [x_pos, y_pos + 4, z_pos], color=rgb(203, 212, 221), material="Concrete"),
            part_node("Bridge", [14, 2, bridge_length], [x_pos, y_pos + 1, bridge_midpoint], color=rgb(141, 108, 78), material="WoodPlanks"),
            part_node("BridgeTrim", [10, 0.8, bridge_length], [x_pos, y_pos + 2.2, bridge_midpoint], color=rgb(190, 154, 117), material="WoodPlanks"),
        ],
    )


def make_sky_island_hub_preview_model() -> dict:
    children = [
        part_node("MiddlePath", [318, 8, 74], [0, 130, 0], color=rgb(116, 132, 146), material="Concrete"),
        part_node("MiddlePathTrim", [318, 1.5, 74], [0, 134.5, 0], color=rgb(80, 93, 105), material="Slate"),
        part_node("UpperSegwayLane", [258, 2, 12], [0, 136, 16], color=rgb(228, 216, 169), material="SmoothPlastic"),
        part_node("LowerSegwayLane", [258, 2, 12], [0, 132, -16], color=rgb(228, 216, 169), material="SmoothPlastic"),
        part_node("HubSpawn", [22, 2, 22], [0, 135.5, 0], color=rgb(120, 223, 255), material="Neon"),
        part_node("ShopZone", [72, 26, 72], [-192, 130, 0], color=rgb(224, 178, 92), material="WoodPlanks"),
        part_node("ShopSign", [20, 18, 6], [-192, 154, 0], color=rgb(255, 238, 171), material="Neon"),
        part_node("RNGZone", [82, 34, 88], [192, 134, 0], color=rgb(111, 135, 186), material="Slate"),
        part_node("RNGCore", [18, 18, 18], [192, 154, 0], color=rgb(123, 207, 255), material="Neon", shape="Ball"),
        part_node("CloudA", [28, 18, 28], [-220, 94, -96], color=rgb(244, 247, 255), shape="Ball", transparency=0.12),
        part_node("CloudB", [22, 14, 22], [-60, 82, 142], color=rgb(244, 247, 255), shape="Ball", transparency=0.16),
        part_node("CloudC", [26, 16, 26], [104, 88, -150], color=rgb(244, 247, 255), shape="Ball", transparency=0.14),
        part_node("CloudD", [34, 18, 34], [242, 92, 112], color=rgb(244, 247, 255), shape="Ball", transparency=0.16),
    ]

    island_specs = [
        ("TopLeftIsland", [-108, 146, -108], -37, rgb(113, 186, 93)),
        ("TopMiddleIsland", [0, 150, -118], -37, rgb(119, 195, 98)),
        ("TopRightIsland", [108, 146, -108], -37, rgb(113, 186, 93)),
        ("BottomLeftIsland", [-108, 118, 108], 37, rgb(111, 181, 91)),
        ("BottomMiddleIsland", [0, 114, 118], 37, rgb(119, 195, 98)),
        ("BottomRightIsland", [108, 118, 108], 37, rgb(111, 181, 91)),
    ]

    for name, position, bridge_target_z, cap_color in island_specs:
        children.append(make_preview_island(name, position, bridge_target_z, cap_color))

    return top_level_model(children)


COMMON_MODEL_FILES = {
    "test/SyncedModels/FloatingPine.model.json": make_floating_pine_model(),
    "test/SyncedModels/CrystalCluster.model.json": make_crystal_cluster_model(),
    "test/SyncedModels/StoneArch.model.json": make_stone_arch_model(),
    "test/SyncedModels/MarketStand.model.json": make_market_stand_model(),
    "test/SyncedModels/CloudPad.model.json": make_cloud_pad_model(),
    "test/SyncedModels/SkyIslandHub.model.json": make_sky_island_hub_preview_model(),
}

TEMPLATE_FILES = {
    "basic": {
        "server/BasicServer.lua": textwrap.dedent("""
            local BasicServer = {}

            function BasicServer:start()
                print("[BasicServer] Running generic server logic")
            end

            return BasicServer
        """)
    },
    "tycoon": {
        "server/Leaderstats.lua": textwrap.dedent("""
            local Players = game:GetService("Players")

            local function onPlayerAdded(player)
                local leaderstats = Instance.new("Folder")
                leaderstats.Name = "leaderstats"

                local money = Instance.new("IntValue")
                money.Name = "Money"
                money.Value = 0
                money.Parent = leaderstats

                leaderstats.Parent = player
            end

            Players.PlayerAdded:Connect(onPlayerAdded)

            return {}
        """),
        "server/WorldBuilder.lua": textwrap.dedent("""
            local Workspace = game:GetService("Workspace")

            local WorldBuilder = {}

            local WORLD_NAME = "SkyIslandHub"
            local WALK_TOP_Y = 130
            local PATH_HEIGHT = 8
            local BRIDGE_HEIGHT = 2
            local CYLINDER_ROTATION = CFrame.Angles(0, 0, math.rad(90))

            local COLORS = {
                Path = Color3.fromRGB(116, 132, 146),
                PathTrim = Color3.fromRGB(80, 93, 105),
                Rail = Color3.fromRGB(104, 79, 58),
                Grass = Color3.fromRGB(114, 186, 89),
                Stone = Color3.fromRGB(108, 112, 123),
                StoneDark = Color3.fromRGB(73, 77, 87),
                Cloud = Color3.fromRGB(244, 248, 255),
                Shop = Color3.fromRGB(255, 194, 76),
                RNG = Color3.fromRGB(109, 206, 255),
                Light = Color3.fromRGB(255, 244, 187),
                LaneTop = Color3.fromRGB(244, 190, 96),
                LaneBottom = Color3.fromRGB(106, 208, 255),
                Text = Color3.fromRGB(36, 40, 48),
            }

            local ISLAND_LAYOUT = {
                {name = "TopLeftIsland", position = Vector3.new(-220, WALK_TOP_Y, -148), radius = 46, accent = Color3.fromRGB(164, 229, 121)},
                {name = "TopCenterIsland", position = Vector3.new(0, WALK_TOP_Y, -164), radius = 52, accent = Color3.fromRGB(159, 225, 255)},
                {name = "TopRightIsland", position = Vector3.new(220, WALK_TOP_Y, -148), radius = 46, accent = Color3.fromRGB(173, 235, 139)},
                {name = "BottomLeftIsland", position = Vector3.new(-220, WALK_TOP_Y, 148), radius = 46, accent = Color3.fromRGB(255, 215, 123)},
                {name = "BottomCenterIsland", position = Vector3.new(0, WALK_TOP_Y, 164), radius = 52, accent = Color3.fromRGB(255, 207, 135)},
                {name = "BottomRightIsland", position = Vector3.new(220, WALK_TOP_Y, 148), radius = 46, accent = Color3.fromRGB(255, 221, 147)},
            }

            local function createInstance(className, parent, properties)
                local instance = Instance.new(className)

                for key, value in pairs(properties or {}) do
                    instance[key] = value
                end

                instance.Parent = parent
                return instance
            end

            local function createPart(parent, properties)
                local defaults = {
                    Anchored = true,
                    TopSurface = Enum.SurfaceType.Smooth,
                    BottomSurface = Enum.SurfaceType.Smooth,
                    Material = Enum.Material.SmoothPlastic,
                }

                for key, value in pairs(properties or {}) do
                    defaults[key] = value
                end

                return createInstance("Part", parent, defaults)
            end

            local function addSurfaceLabel(part, face, text, textColor)
                local surfaceGui = createInstance("SurfaceGui", part, {
                    Face = face,
                    AlwaysOnTop = true,
                    PixelsPerStud = 45,
                    SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
                })

                createInstance("TextLabel", surfaceGui, {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBlack,
                    Text = text,
                    TextColor3 = textColor,
                    TextScaled = true,
                    TextStrokeColor3 = Color3.fromRGB(248, 250, 255),
                    TextStrokeTransparency = 0.5,
                })
            end

            local function createSign(parent, name, cframe, size, text, accentColor)
                local sign = createPart(parent, {
                    Name = name,
                    Size = size,
                    CFrame = cframe,
                    Material = Enum.Material.WoodPlanks,
                    Color = accentColor,
                })

                addSurfaceLabel(sign, Enum.NormalId.Front, text, COLORS.Text)
                addSurfaceLabel(sign, Enum.NormalId.Back, text, COLORS.Text)
                return sign
            end

            local function createCloudCluster(parent, center, scale)
                local offsets = {
                    Vector3.new(-1.6, 0.0, 0.0),
                    Vector3.new(-0.6, 0.3, -0.7),
                    Vector3.new(0.5, 0.25, 0.4),
                    Vector3.new(1.4, 0.05, -0.25),
                    Vector3.new(0.0, 0.45, 0.8),
                }

                for index, offset in ipairs(offsets) do
                    local sizeMultiplier = 0.85 + (index * 0.1)

                    createPart(parent, {
                        Name = "Cloud" .. index,
                        Shape = Enum.PartType.Ball,
                        Size = Vector3.new(scale, scale, scale) * sizeMultiplier,
                        Position = center + Vector3.new(offset.X * scale, offset.Y * scale, offset.Z * scale),
                        Material = Enum.Material.SmoothPlastic,
                        Color = COLORS.Cloud,
                        Transparency = 0.18,
                        CanCollide = false,
                        CastShadow = false,
                    })
                end
            end

            local function createLightPost(parent, name, position)
                createPart(parent, {
                    Name = name .. "Post",
                    Size = Vector3.new(2, 6, 2),
                    Position = Vector3.new(position.X, WALK_TOP_Y + 3, position.Z),
                    Material = Enum.Material.WoodPlanks,
                    Color = COLORS.Rail,
                })

                createPart(parent, {
                    Name = name .. "Glow",
                    Shape = Enum.PartType.Ball,
                    Size = Vector3.new(1.6, 1.6, 1.6),
                    Position = Vector3.new(position.X, WALK_TOP_Y + 7, position.Z),
                    Material = Enum.Material.Neon,
                    Color = COLORS.Light,
                    CanCollide = false,
                })
            end

            local function createBridge(parent, name, startPosition, endPosition)
                local bridgeModel = createInstance("Model", parent, {Name = name})
                local deckCenterY = WALK_TOP_Y - (BRIDGE_HEIGHT / 2)
                local midpoint = Vector3.new(
                    (startPosition.X + endPosition.X) / 2,
                    deckCenterY,
                    (startPosition.Z + endPosition.Z) / 2
                )
                local lookTarget = Vector3.new(endPosition.X, deckCenterY, endPosition.Z)
                local bridgeCFrame = CFrame.lookAt(midpoint, lookTarget)
                local length = (Vector3.new(endPosition.X, 0, endPosition.Z) - Vector3.new(startPosition.X, 0, startPosition.Z)).Magnitude

                createPart(bridgeModel, {
                    Name = "Deck",
                    Size = Vector3.new(18, BRIDGE_HEIGHT, length),
                    CFrame = bridgeCFrame,
                    Material = Enum.Material.WoodPlanks,
                    Color = Color3.fromRGB(139, 109, 79),
                })

                createPart(bridgeModel, {
                    Name = "LeftRail",
                    Size = Vector3.new(2, 4, length),
                    CFrame = bridgeCFrame * CFrame.new(-8, 3, 0),
                    Material = Enum.Material.WoodPlanks,
                    Color = COLORS.Rail,
                })

                createPart(bridgeModel, {
                    Name = "RightRail",
                    Size = Vector3.new(2, 4, length),
                    CFrame = bridgeCFrame * CFrame.new(8, 3, 0),
                    Material = Enum.Material.WoodPlanks,
                    Color = COLORS.Rail,
                })

                createLightPost(bridgeModel, name .. "Start", startPosition)
                createLightPost(bridgeModel, name .. "End", endPosition)
            end

            local function createSegwayLane(parent, name, zPosition, color, velocity, labelText)
                local lane = createPart(parent, {
                    Name = name,
                    Size = Vector3.new(620, 1.2, 14),
                    Position = Vector3.new(0, WALK_TOP_Y + 0.6, zPosition),
                    Material = Enum.Material.Metal,
                    Color = color,
                    AssemblyLinearVelocity = velocity,
                    CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.35, 0.2),
                })

                addSurfaceLabel(lane, Enum.NormalId.Top, labelText, COLORS.Text)

                createPart(parent, {
                    Name = name .. "StartCap",
                    Size = Vector3.new(8, 3, 18),
                    Position = Vector3.new(-310, WALK_TOP_Y + 1.5, zPosition),
                    Material = Enum.Material.Neon,
                    Color = color,
                })

                createPart(parent, {
                    Name = name .. "EndCap",
                    Size = Vector3.new(8, 3, 18),
                    Position = Vector3.new(310, WALK_TOP_Y + 1.5, zPosition),
                    Material = Enum.Material.Neon,
                    Color = color,
                })
            end

            local function createTerminal(parent, name, center, labelText, accentColor)
                local terminal = createInstance("Model", parent, {Name = name})
                local signOffset = center.X < 0 and -68 or 68
                local signPosition = center + Vector3.new(signOffset, 28, 0)
                local signCFrame = CFrame.lookAt(signPosition, Vector3.new(0, signPosition.Y, 0))

                createPart(terminal, {
                    Name = "Pad",
                    Size = Vector3.new(104, 2, 74),
                    Position = Vector3.new(center.X, WALK_TOP_Y + 1, center.Z),
                    Material = Enum.Material.SmoothPlastic,
                    Color = accentColor,
                    Transparency = 0.08,
                })

                createPart(terminal, {
                    Name = "Booth",
                    Size = Vector3.new(34, 20, 30),
                    Position = Vector3.new(center.X, WALK_TOP_Y + 10, center.Z),
                    Material = Enum.Material.WoodPlanks,
                    Color = COLORS.Rail,
                })

                createPart(terminal, {
                    Name = "PortalFrame",
                    Size = Vector3.new(40, 24, 4),
                    Position = Vector3.new(center.X, WALK_TOP_Y + 14, center.Z - 18),
                    Material = Enum.Material.Neon,
                    Color = accentColor,
                    CanCollide = false,
                })

                createSign(terminal, name .. "Sign", signCFrame, Vector3.new(4, 56, 34), labelText, accentColor)
            end

            local function createSkyIsland(parent, islandInfo)
                local island = createInstance("Model", parent, {Name = islandInfo.name})
                local islandCenter = islandInfo.position
                local radius = islandInfo.radius
                local topCenter = Vector3.new(islandCenter.X, WALK_TOP_Y - 5, islandCenter.Z)
                local landingPadCenter = Vector3.new(islandCenter.X, WALK_TOP_Y - 0.5, islandCenter.Z)
                local detailOffsets = {
                    Vector3.new(-radius * 0.24, 2.5, -radius * 0.18),
                    Vector3.new(radius * 0.28, 2.5, radius * 0.12),
                    Vector3.new(radius * 0.08, 2.5, -radius * 0.3),
                }

                createPart(island, {
                    Name = "GrassTop",
                    Shape = Enum.PartType.Cylinder,
                    Size = Vector3.new(10, radius * 2, radius * 2),
                    CFrame = CFrame.new(topCenter) * CYLINDER_ROTATION,
                    Material = Enum.Material.Grass,
                    Color = COLORS.Grass,
                })

                createPart(island, {
                    Name = "StoneShelf",
                    Shape = Enum.PartType.Cylinder,
                    Size = Vector3.new(16, radius * 2.14, radius * 2.14),
                    CFrame = CFrame.new(islandCenter - Vector3.new(0, 8, 0)) * CYLINDER_ROTATION,
                    Material = Enum.Material.Slate,
                    Color = COLORS.Stone,
                })

                createPart(island, {
                    Name = "UndersideCore",
                    Shape = Enum.PartType.Ball,
                    Size = Vector3.new(radius * 1.08, radius * 1.08, radius * 1.08),
                    Position = islandCenter - Vector3.new(0, radius * 0.72, 0),
                    Material = Enum.Material.Slate,
                    Color = COLORS.StoneDark,
                })

                createPart(island, {
                    Name = "LandingPad",
                    Shape = Enum.PartType.Cylinder,
                    Size = Vector3.new(1, radius * 0.92, radius * 0.92),
                    CFrame = CFrame.new(landingPadCenter) * CYLINDER_ROTATION,
                    Material = Enum.Material.SmoothPlastic,
                    Color = islandInfo.accent,
                    Transparency = 0.08,
                })

                for index, offset in ipairs(detailOffsets) do
                    createPart(island, {
                        Name = "AccentStone" .. index,
                        Shape = Enum.PartType.Ball,
                        Size = Vector3.new(7, 7, 7),
                        Position = Vector3.new(islandCenter.X, WALK_TOP_Y + 2.5, islandCenter.Z) + offset,
                        Material = Enum.Material.Slate,
                        Color = COLORS.Stone,
                    })
                end

                createCloudCluster(island, islandCenter - Vector3.new(0, radius * 0.92, 0), radius * 0.24)
            end

            local function buildGeneralPath(parent)
                local pathModel = createInstance("Model", parent, {Name = "GeneralPath"})

                createPart(pathModel, {
                    Name = "Causeway",
                    Size = Vector3.new(760, PATH_HEIGHT, 92),
                    Position = Vector3.new(0, WALK_TOP_Y - (PATH_HEIGHT / 2), 0),
                    Material = Enum.Material.Slate,
                    Color = COLORS.Path,
                })

                local plaza = createPart(pathModel, {
                    Name = "CenterPlaza",
                    Shape = Enum.PartType.Cylinder,
                    Size = Vector3.new(10, 118, 118),
                    CFrame = CFrame.new(0, WALK_TOP_Y - 5, 0) * CYLINDER_ROTATION,
                    Material = Enum.Material.Slate,
                    Color = COLORS.PathTrim,
                })

                addSurfaceLabel(plaza, Enum.NormalId.Top, "GENERAL PATH", Color3.fromRGB(239, 244, 248))

                createPart(pathModel, {
                    Name = "NorthRail",
                    Size = Vector3.new(760, 4, 4),
                    Position = Vector3.new(0, WALK_TOP_Y + 2, -48),
                    Material = Enum.Material.WoodPlanks,
                    Color = COLORS.Rail,
                })

                createPart(pathModel, {
                    Name = "SouthRail",
                    Size = Vector3.new(760, 4, 4),
                    Position = Vector3.new(0, WALK_TOP_Y + 2, 48),
                    Material = Enum.Material.WoodPlanks,
                    Color = COLORS.Rail,
                })

                createPart(pathModel, {
                    Name = "CentralTrim",
                    Size = Vector3.new(760, 1, 8),
                    Position = Vector3.new(0, WALK_TOP_Y + 0.5, 0),
                    Material = Enum.Material.SmoothPlastic,
                    Color = COLORS.PathTrim,
                    CanCollide = false,
                })

                createInstance("SpawnLocation", pathModel, {
                    Name = "HubSpawn",
                    Size = Vector3.new(18, 1, 18),
                    Position = Vector3.new(0, WALK_TOP_Y + 0.5, 0),
                    Anchored = true,
                    Neutral = true,
                    Duration = 0,
                    Enabled = true,
                    Material = Enum.Material.Neon,
                    Color = COLORS.Light,
                })

                createSegwayLane(pathModel, "ShopToRNGLane", -18, COLORS.LaneTop, Vector3.new(22, 0, 0), "SHOP -> RNG")
                createSegwayLane(pathModel, "RNGToShopLane", 18, COLORS.LaneBottom, Vector3.new(-22, 0, 0), "RNG -> SHOP")

                createTerminal(pathModel, "ShopArea", Vector3.new(-332, WALK_TOP_Y, 0), "SHOP", COLORS.Shop)
                createTerminal(pathModel, "RNGArea", Vector3.new(332, WALK_TOP_Y, 0), "RNG", COLORS.RNG)
            end

            local function buildIslands(parent, bridgeParent)
                for _, islandInfo in ipairs(ISLAND_LAYOUT) do
                    createSkyIsland(parent, islandInfo)

                    local pathZ = islandInfo.position.Z < 0 and -52 or 52
                    local islandBridgeZ = islandInfo.position.Z < 0
                        and islandInfo.position.Z + (islandInfo.radius * 0.66)
                        or islandInfo.position.Z - (islandInfo.radius * 0.66)

                    createBridge(
                        bridgeParent,
                        islandInfo.name .. "Bridge",
                        Vector3.new(islandInfo.position.X, WALK_TOP_Y, pathZ),
                        Vector3.new(islandInfo.position.X, WALK_TOP_Y, islandBridgeZ)
                    )
                end
            end

            local function buildAtmosphere(parent)
                local cloudFields = {
                    {position = Vector3.new(-320, WALK_TOP_Y - 26, -220), scale = 18},
                    {position = Vector3.new(320, WALK_TOP_Y - 24, -220), scale = 20},
                    {position = Vector3.new(-320, WALK_TOP_Y - 24, 220), scale = 20},
                    {position = Vector3.new(320, WALK_TOP_Y - 26, 220), scale = 18},
                    {position = Vector3.new(0, WALK_TOP_Y - 34, -240), scale = 22},
                    {position = Vector3.new(0, WALK_TOP_Y - 34, 240), scale = 22},
                }

                for index, field in ipairs(cloudFields) do
                    local cloudGroup = createInstance("Model", parent, {Name = "CloudField" .. index})
                    createCloudCluster(cloudGroup, field.position, field.scale)
                end
            end

            function WorldBuilder:build()
                local existing = Workspace:FindFirstChild(WORLD_NAME)
                if existing then
                    existing:Destroy()
                end

                local world = createInstance("Model", Workspace, {Name = WORLD_NAME})
                local structures = createInstance("Folder", world, {Name = "Structures"})
                local islands = createInstance("Folder", world, {Name = "Islands"})
                local bridges = createInstance("Folder", world, {Name = "Bridges"})
                local atmosphere = createInstance("Folder", world, {Name = "Atmosphere"})

                buildGeneralPath(structures)
                buildIslands(islands, bridges)
                buildAtmosphere(atmosphere)

                print("[WorldBuilder] Generated sky island hub world.")
            end

            return WorldBuilder
        """),
        "server/TycoonManager.lua": textwrap.dedent("""
            local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

            local TycoonManager = {}

            function TycoonManager:start()
                print("[TycoonManager] Initializing tycoon template")
                WorldBuilder:build()
            end

            return TycoonManager
        """),
        "client/TycoonClient.lua": textwrap.dedent("""
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Config = require(ReplicatedStorage:WaitForChild("Config"))

            print("[TycoonClient] Starting client for " .. Config.GameName)
            print("[TycoonClient] Sky islands, bridge paths, shop dock, RNG dock, and segway lanes are ready")

            return {}
        """)
    },
    "obstacle_course": {
        "server/CheckpointManager.lua": textwrap.dedent("""
            local CheckpointManager = {}

            function CheckpointManager:initialize()
                print("[CheckpointManager] Ready to track checkpoints")
            end

            return CheckpointManager
        """),
        "client/ObbyClient.lua": textwrap.dedent("""
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Config = require(ReplicatedStorage:WaitForChild("Config"))

            print("[ObbyClient] Obstacle course client initialized for " .. Config.GameName)

            return {}
        """)
    },
    "waiting_in_line": {
        "server/QueueManager.lua": textwrap.dedent("""
            local Players = game:GetService("Players")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            local petTypes = {"TurboTurtle", "LuckyPup", "TrapCat", "FastFox"}
            local queue = {}
            local pets = {}

            local QueueManager = {}

            local function findEntry(player)
                for index, entry in ipairs(queue) do
                    if entry.player == player then
                        return index, entry
                    end
                end
            end

            local function syncPositions()
                for index, entry in ipairs(queue) do
                    entry.position = index
                    print("[QueueManager] " .. entry.player.Name .. " is now at position " .. index)
                end
            end

            function QueueManager:addPlayer(player)
                table.insert(queue, {player = player, position = #queue + 1, pet = nil})
                print("[QueueManager] Added " .. player.Name .. " to the line")
                syncPositions()
            end

            function QueueManager:removePlayer(player)
                local index = findEntry(player)
                if index then
                    table.remove(queue, index)
                    print("[QueueManager] Removed " .. player.Name .. " from the line")
                    syncPositions()
                end
            end

            function QueueManager:rollPet(player)
                local index, entry = findEntry(player)
                if not entry then
                    return
                end

                local petName = petTypes[math.random(1, #petTypes)]
                entry.pet = petName
                pets[player.UserId] = petName

                print("[QueueManager] " .. player.Name .. " rolled pet: " .. petName)

                if petName == "TurboTurtle" then
                    self:movePlayer(player, -2)
                elseif petName == "TrapCat" then
                    self:movePlayer(player, 3)
                elseif petName == "LuckyPup" then
                    print("[QueueManager] " .. player.Name .. " gets a small bonus")
                else
                    print("[QueueManager] " .. player.Name .. " keeps their place")
                end
            end

            function QueueManager:movePlayer(player, offset)
                local index, entry = findEntry(player)
                if not index then
                    return
                end

                local target = math.clamp(index + offset, 1, #queue)
                table.remove(queue, index)
                table.insert(queue, target, entry)
                print("[QueueManager] Moved " .. player.Name .. " to position " .. target)
                syncPositions()
            end

            Players.PlayerAdded:Connect(function(player)
                QueueManager:addPlayer(player)
            end)

            Players.PlayerRemoving:Connect(function(player)
                QueueManager:removePlayer(player)
            end)

            return QueueManager
        """),
        "client/WaitingLineClient.lua": textwrap.dedent("""
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Config = require(ReplicatedStorage:WaitForChild("Config"))

            print("[WaitingLineClient] Initialized for " .. Config.GameName)

            return {}
        """)
    },
    "turn_based_battle": {
        "server/BattleManager.lua": textwrap.dedent("""
            local Players = game:GetService("Players")

            local BattleManager = {}
            BattleManager.battles = {}

            local function createBattle(playerA, playerB)
                return {
                    players = {playerA, playerB},
                    health = {[playerA.UserId] = 100, [playerB.UserId] = 100},
                    turnIndex = 1,
                    state = "Waiting"
                }
            end

            function BattleManager:startBattle(playerA, playerB)
                local battle = createBattle(playerA, playerB)
                battle.state = "Active"
                self.battles[playerA.UserId] = battle
                self.battles[playerB.UserId] = battle
                print("[BattleManager] Battle started between " .. playerA.Name .. " and " .. playerB.Name)
                return battle
            end

            function BattleManager:processAction(player, action)
                local battle = self.battles[player.UserId]
                if not battle or battle.state ~= "Active" then
                    return
                end

                local opponent = battle.players[3 - battle.turnIndex]
                if player ~= battle.players[battle.turnIndex] then
                    print("[BattleManager] It's not " .. player.Name .. "'s turn")
                    return
                end

                local damage = 0
                if action == "Attack" then
                    damage = 15
                elseif action == "Defend" then
                    damage = 5
                else
                    damage = 10
                end

                battle.health[opponent.UserId] = battle.health[opponent.UserId] - damage
                print("[BattleManager] " .. player.Name .. " used " .. action .. " and dealt " .. damage)

                if battle.health[opponent.UserId] <= 0 then
                    battle.state = "Finished"
                    print("[BattleManager] " .. opponent.Name .. " was defeated")
                    return
                end

                battle.turnIndex = 3 - battle.turnIndex
                print("[BattleManager] Next turn: " .. battle.players[battle.turnIndex].Name)
            end

            return BattleManager
        """),
        "client/BattleClient.lua": textwrap.dedent("""
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Config = require(ReplicatedStorage:WaitForChild("Config"))

            print("[BattleClient] Initialized for " .. Config.GameName)

            return {}
        """)
    }
}

PROJECT_README = textwrap.dedent("""
    # {game_name}

    This Roblox project was generated automatically with the `{template}` template.

    ## What is included

    - Rojo project config: `default.project.json`
    - Shared config module: `shared/Config.lua`
    - Optional creator group metadata in `shared/Config.lua`
    - Server bootstrap: `server/MainServer.lua`
    - Client bootstrap: `client/MainClient.lua`
    - Test model folder: `test/`
    - Synced Studio model gallery: `test/SyncedModels/*.model.json`
    - Studio helper scripts: `studio/`
    - Install/use guide: `INSTALL_AND_USAGE.md`
    - Template-specific helper modules

    ## How to use

    1. Install Rojo: https://rojo.space
    2. Open a terminal in this folder.
    3. Run:
       ```powershell
       rojo serve --project default.project.json
       ```
    4. In Roblox Studio, connect to the Rojo server.
    5. Browse `ServerStorage/TestWorldModels/SyncedModels` for the static sample assets that sync immediately.
    6. Run the experience once if you also want the runtime-built `ServerStorage/TestWorldModels/GeneratedModels` folder.
    7. Use `studio/SpawnTestModels.plugin.lua` or `studio/SpawnTestModels.command.lua` to preview the synced gallery and sky-island hub in `Workspace`.

    ## Template

    {template_description}

    ## Notes

    - The generated code is a starting point; customize it in Roblox Studio.
    - The `test/` folder contains both synced `.model.json` assets and simple original runtime model builders.
    - The `studio/` folder contains local Studio helpers and is not synced into the live game by Rojo.
    - Avoid Blender imports unless you need custom meshes.
    - Use Roblox Toolbox assets and `StarterGui` for rapid iteration.
""")


PROJECT_INSTALL_AND_USAGE = textwrap.dedent("""
    # Install And Usage

    This guide explains how to install the tools for `{game_name}`, sync the project with Rojo, and place the generated world into Roblox Studio.

    ## Install

    1. Install Roblox Studio.
    2. Install Python 3.10 or newer if you plan to regenerate this project.
    3. Install the Rojo CLI.
    4. Install the Rojo Studio plugin.

    Example Rojo install options:

    ```powershell
    winget install Rojo.Rojo
    rojo plugin install
    ```

    ## Sync The Project

    1. Open a terminal in this folder.
    2. Start Rojo:
       ```powershell
       rojo serve --project default.project.json
       ```
    3. Open Roblox Studio.
    4. Use the Rojo plugin to connect to the local server.

    After syncing, this project appears in Studio as:

    - `ReplicatedStorage` from `shared/`
    - `ServerScriptService` from `server/`
    - `StarterPlayerScripts` from `client/`
    - `ServerStorage/TestWorldModels` from `test/`

    ## Use The Synced Models

    The easiest permanent workflow is to use the synced model library.

    1. In Studio, open `Explorer`.
    2. Expand `ServerStorage > TestWorldModels > SyncedModels`.
    3. Copy `SkyIslandHub`.
    4. Paste it into `Workspace`.
    5. Copy any extra models like `FloatingPine`, `CloudPad`, or `MarketStand` into `Workspace`.
    6. Move, rotate, and scale the `Workspace` copies as needed.

    `SkyIslandHub` is the static Studio model version of the world layout.

    ## Use The Runtime World

    This template also includes a runtime world generator for `{template}`.

    - Press `Play` in Studio.
    - The server builds `Workspace/SkyIslandHub` from `server/WorldBuilder.lua`.
    - This is useful for testing gameplay flow and generated placement.

    The runtime-built world is different from the synced model library:

    - `test/SyncedModels/SkyIslandHub.model.json` is the permanent draggable Studio model.
    - `server/WorldBuilder.lua` builds the live runtime version when the game starts.

    ## Studio Helpers

    This project includes Studio-side helpers:

    - `studio/SpawnTestModels.plugin.lua`
    - `studio/SpawnTestModels.command.lua`

    These clone the synced models into `Workspace` first and fall back to runtime-generated samples if needed.

    ## Creator Group

    Group metadata is stored in:

    - `shared/Config.lua`
    - `game_metadata.json`

    For this project:

    - `GroupId = {group_id_literal}`
    - `GroupName = {group_name_literal}`

    ## Troubleshooting

    If models do not appear in Studio:

    - make sure Rojo is connected
    - reconnect the Rojo plugin
    - confirm `default.project.json` is being served from this folder

    If `rojo` is not recognized in PowerShell:

    - close the terminal
    - open a new terminal window
    - run `rojo --version`
""")


def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def write_file(path: str, content: str) -> None:
    ensure_dir(Path(path).parent)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(content)


def write_json(path: str, data) -> None:
    ensure_dir(Path(path).parent)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=4)


def build_rojo_project(game_name: str, output_dir: str) -> None:
    project_file = output_dir / "default.project.json"
    project_config = {
        "name": game_name,
        "tree": {
            "$className": "DataModel",
            "ReplicatedStorage": {
                "$path": "shared"
            },
            "ServerScriptService": {
                "$path": "server"
            },
            "ServerStorage": {
                "$className": "ServerStorage",
                "TestWorldModels": {
                    "$className": "Folder",
                    "$path": "test"
                }
            },
            "StarterPlayer": {
                "$className": "StarterPlayer",
                "StarterPlayerScripts": {
                    "$path": "client"
                }
            }
        }
    }

    write_json(project_file, project_config)
    print(f"Created Rojo config: {project_file}")


def populate_project(output_dir: Path, metadata: dict) -> None:
    metadata = {
        **metadata,
        "group_id_literal": metadata.get("group_id_literal", "nil"),
        "group_name_literal": metadata.get("group_name_literal", "nil"),
    }

    for subdir in ["server", "client", "shared", "test", "studio"]:
        ensure_dir(output_dir / subdir)

    legacy_synced_preview = output_dir / "test" / "SyncedModels" / "SkyIslandHubPreview.model.json"
    if legacy_synced_preview.exists():
        legacy_synced_preview.unlink()

    for relative_path, body in BASE_FILES.items():
        path = output_dir / relative_path
        content = body.format(**metadata)
        write_file(path, content)
        print(f"Generated {relative_path}")

    for relative_path, body in COMMON_FILES.items():
        path = output_dir / relative_path
        write_file(path, body)
        print(f"Generated {relative_path}")

    for relative_path, model_data in COMMON_MODEL_FILES.items():
        path = output_dir / relative_path
        write_json(path, model_data)
        print(f"Generated {relative_path}")

    for relative_path, body in TEMPLATE_FILES.get(metadata["template"], {}).items():
        path = output_dir / relative_path
        write_file(path, body)
        print(f"Generated {relative_path}")

    readme_path = output_dir / "README_GENERATED.md"
    description = PROJECT_TEMPLATES[metadata["template"]]["description"]
    readme_content = PROJECT_README.format(
        game_name=metadata["game_name"],
        template=metadata["template"],
        template_description=description,
    )
    write_file(readme_path, readme_content)
    print(f"Generated README_GENERATED.md")

    install_guide_path = output_dir / "INSTALL_AND_USAGE.md"
    install_guide_content = PROJECT_INSTALL_AND_USAGE.format(
        game_name=metadata["game_name"],
        template=metadata["template"],
        group_id_literal=metadata["group_id_literal"],
        group_name_literal=metadata["group_name_literal"],
    )
    write_file(install_guide_path, install_guide_content)
    print(f"Generated INSTALL_AND_USAGE.md")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a Roblox project scaffold with Rojo support."
    )
    parser.add_argument("--game-name", required=True, help="Name of the Roblox game/project")
    parser.add_argument(
        "--template",
        choices=PROJECT_TEMPLATES.keys(),
        default="basic",
        help="Template type to generate",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output directory for the generated project",
    )
    parser.add_argument(
        "--author",
        default="AutoGenerated",
        help="Author name to include in shared config",
    )
    parser.add_argument(
        "--version",
        default="0.1",
        help="Initial version string for shared config",
    )
    parser.add_argument(
        "--group-id",
        type=int,
        default=None,
        help="Optional Roblox group/community ID for the generated project",
    )
    parser.add_argument(
        "--group-name",
        default="",
        help="Optional Roblox group/community name for the generated project",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing output directory if it exists",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_dir = Path(args.output).resolve()

    if output_dir.exists():
        if not args.force:
            raise SystemExit(
                f"Output directory '{output_dir}' already exists. Use --force to overwrite."
            )
    else:
        output_dir.mkdir(parents=True, exist_ok=True)

    metadata = {
        "game_name": args.game_name,
        "template": args.template,
        "author": args.author,
        "version": args.version,
        "group_id_literal": "nil" if args.group_id is None else str(args.group_id),
        "group_name_literal": "nil" if not args.group_name else json.dumps(args.group_name),
    }

    build_rojo_project(args.game_name, output_dir)

    game_meta = {
        "game_name": args.game_name,
        "template": args.template,
        "author": args.author,
        "version": args.version,
        "group_id": args.group_id,
        "group_name": args.group_name or None,
        "generated_at": str(output_dir),
    }
    write_json(output_dir / "game_metadata.json", game_meta)
    populate_project(output_dir, metadata)

    print("\nProject generated successfully.")
    print("Open Roblox Studio and use Rojo to sync the generated project.")


if __name__ == "__main__":
    main()
