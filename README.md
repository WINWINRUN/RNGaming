# RNGaming

RNGaming is a lightweight Roblox project scaffold generator for developers building Roblox games with Roblox Studio and Rojo.

It creates Rojo-compatible starter projects so you can move quickly from a fresh idea to an editable Studio-ready codebase.

## What this does

- creates a game folder structure for `server`, `client`, and `shared`
- generates `default.project.json` for Rojo syncing
- writes starter Lua modules for server bootstrap, client bootstrap, and shared config
- supports multiple built-in game genres
- produces a generated `README_GENERATED.md` in each output project

## Requirements

- Python 3.10 or newer
- Rojo installed (recommended) for syncing generated code into Roblox Studio
- Roblox Studio for editing and testing the generated project

## Install

1. Install Python 3.10+ from python.org.
2. Install Rojo:

```powershell
npm install -g rojo
```

3. Open this workspace in your editor.

## Quickstart

Generate a project scaffold with the desired template:

```powershell
python generate_game.py --game-name "MyTycoon" --template tycoon --output "./MyTycoonGame" --author "Mikey" --version "0.1" --force
```

Open the new project folder in Roblox Studio via Rojo:

```powershell
cd MyTycoonGame
rojo serve --project default.project.json
```

Then connect Roblox Studio to the Rojo server.

## Available templates

- `basic`
  - generic starter game scaffold
  - use this for any custom genre prototype
- `tycoon`
  - tycoon-style game with `leaderstats` and currency stubs
  - good for economy, shop, and growth gameplay
- `obstacle_course`
  - obstacle course starter with checkpoint framework
  - good for obby and parkour games
- `waiting_in_line`
  - queue-based game with RNG pet rolls
  - includes line advancement/back effects
  - great for waiting-line or service-style gameplay
- `turn_based_battle`
  - turn-based combat start with action processing
  - useful for battle arena or RPG-style fights

## Example commands

Generate a waiting-in-line game:

```powershell
python generate_game.py --game-name "LineRush" --template waiting_in_line --output "./LineRush" --author "Mikey" --version "0.1" --force
```

Generate a turn-based battle game:

```powershell
python generate_game.py --game-name "BattleGrid" --template turn_based_battle --output "./BattleGrid" --author "Mikey" --version "0.1" --force
```

## Included example

This repository currently includes a generated sample project in `MyTycoonGame/` so Roblox developers can inspect the expected output structure right away.

## How to use this with Codex

Use Codex for script generation, not place assembly.

1. generate a scaffold using this tool
2. open the folder in Roblox Studio via Rojo
3. ask Codex to write Lua modules for a specific mechanic
   - `QueueManager.lua` for waiting line logic
   - `BattleManager.lua` for turn-based combat
   - `leaderstats` setup, remote events, UI actions
4. paste Codex-generated Luau into the files under `server/` or `client/`
5. test and iterate in Studio

## Customize the generated project

- open `MyTycoonGame/server/MainServer.lua` and add server initialization
- open `MyTycoonGame/client/MainClient.lua` and add client UI hooks
- edit `MyTycoonGame/shared/Config.lua` for game metadata
- add Roblox instances in Studio for UI, spawns, checkpoints, queue positions

## Testing

Run the built-in test script to verify the generator:

```powershell
python test_generate_game.py
```

## Notes

- This generator is a starting point, not a complete playable game.
- Use Roblox Studio for asset layout, part placement, UI design, and in-game testing.
- Reuse Roblox Toolbox assets rather than modeling in Blender unless you need unique meshes.
- If you want a new genre, generate from `basic` and add your own module logic.
