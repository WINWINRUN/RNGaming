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
        "description": "Tycoon-style game with money, leaderstats, and purchase stubs.",
        "features": ["leaderstats", "currency system", "buy button helper"]
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

        local Config = require(ReplicatedStorage:WaitForChild("Config"))

        local function onPlayerAdded(player)
            print("[Server] Player joined:", player.Name)
        end

        Players.PlayerAdded:Connect(onPlayerAdded)

        local function setupGame()
            print("[Server] Starting {game_name} ({template})")

            if Config.Template == "tycoon" then
                print("[Server] Preparing tycoon systems")
            elseif Config.Template == "obstacle_course" then
                print("[Server] Preparing obstacle course systems")
            elseif Config.Template == "waiting_in_line" then
                print("[Server] Preparing waiting-in-line systems")
            elseif Config.Template == "turn_based_battle" then
                print("[Server] Preparing turn-based battle systems")
            else
                print("[Server] Basic game started")
            end
        end

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
        }}

        return Config
    """)
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
        "server/TycoonManager.lua": textwrap.dedent("""
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Config = require(ReplicatedStorage:WaitForChild("Config"))

            local TycoonManager = {}

            function TycoonManager:start()
                print("[TycoonManager] Initializing tycoon template")
            end

            return TycoonManager
        """),
        "client/TycoonClient.lua": textwrap.dedent("""
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Config = require(ReplicatedStorage:WaitForChild("Config"))

            print("[TycoonClient] Starting client for " .. Config.GameName)

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
    - Server bootstrap: `server/MainServer.lua`
    - Client bootstrap: `client/MainClient.lua`
    - Template-specific helper modules

    ## How to use

    1. Install Rojo: https://rojo.space
    2. Open a terminal in this folder.
    3. Run:
       ```powershell
       rojo serve --project default.project.json
       ```
    4. In Roblox Studio, connect to the Rojo server.

    ## Template

    {template_description}

    ## Notes

    - The generated code is a starting point; customize it in Roblox Studio.
    - Avoid Blender imports unless you need custom meshes.
    - Use Roblox Toolbox assets and `StarterGui` for rapid iteration.
""")


def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def write_file(path: str, content: str) -> None:
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(content)


def write_json(path: str, data) -> None:
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
    for subdir in ["server", "client", "shared"]:
        ensure_dir(output_dir / subdir)

    for relative_path, body in BASE_FILES.items():
        path = output_dir / relative_path
        content = body.format(**metadata)
        write_file(path, content)
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
    }

    build_rojo_project(args.game_name, output_dir)

    game_meta = {
        "game_name": args.game_name,
        "template": args.template,
        "author": args.author,
        "version": args.version,
        "generated_at": str(output_dir),
    }
    write_json(output_dir / "game_metadata.json", game_meta)
    populate_project(output_dir, metadata)

    print("\nProject generated successfully.")
    print("Open Roblox Studio and use Rojo to sync the generated project.")


if __name__ == "__main__":
    main()
