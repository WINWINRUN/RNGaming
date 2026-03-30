# RNGaming

RNGaming is a lightweight Roblox project scaffold generator for developers building Roblox games with Roblox Studio and Rojo.

It creates Rojo-compatible starter projects so you can move quickly from a fresh idea to an editable Studio-ready codebase.

## Recent changes

- synced `.model.json` assets now appear immediately in Studio under `ServerStorage/TestWorldModels/SyncedModels`
- the PNG-inspired sky-island layout is available as a real draggable model named `SkyIslandHub`
- the runtime world generator in `server/WorldBuilder.lua` is still included for live play/testing
- Studio helper scripts now prefer the synced model library and fall back to runtime-generated samples
- generated projects now include `INSTALL_AND_USAGE.md` with Rojo setup and Studio placement steps

For a full walkthrough, see `docs/STUDIO_SETUP.md` and `CHANGELOG.md`.

## What this does

- creates a game folder structure for `server`, `client`, and `shared`
- adds a `test` folder with synced `.model.json` assets and simple original world-model builders
- adds a `studio` folder with plugin/command-bar helpers for quick previews
- generates `default.project.json` for Rojo syncing
- writes starter Lua modules for server bootstrap, client bootstrap, and shared config
- supports multiple built-in game genres
- includes a generated sky-island tycoon example with connected island pathing
- produces a generated `README_GENERATED.md` in each output project

## Requirements

- Python 3.10 or newer
- Rojo installed (recommended) for syncing generated code into Roblox Studio
- Roblox Studio for editing and testing the generated project

## Install

1. Install Python 3.10+ from python.org.
2. Install the Rojo CLI:

```powershell
winget install Rojo.Rojo
```

3. Install the Rojo Studio plugin:

```powershell
rojo plugin install
```

4. Open this workspace in your editor.

## Quickstart

Generate a project scaffold with the desired template:

```powershell
python generate_game.py --game-name "MyTycoon" --template tycoon --output "./MyTycoonGame" --author "Mikey" --version "0.1" --force
```

Optional creator group metadata:

```powershell
python generate_game.py --game-name "MyTycoon" --template tycoon --output "./MyTycoonGame" --author "Mikey" --version "0.1" --group-id 846021713 --group-name "RN_Gaming" --force
```

Open the new project folder in Roblox Studio via Rojo:

```powershell
cd MyTycoonGame
rojo serve --project default.project.json
```

Then connect Roblox Studio to the Rojo server.

For a step-by-step Studio walkthrough, see `docs/STUDIO_SETUP.md`.

## Available templates

- `basic`
  - generic starter game scaffold
  - use this for any custom genre prototype
- `tycoon`
  - tycoon-style sky island hub with `leaderstats`, connected islands, and shop/RNG lanes
  - good for economy, shop, RNG, and growth gameplay
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
6. browse or duplicate the synced sample assets from `ServerStorage/TestWorldModels/SyncedModels`
7. run the place if you also want runtime-generated samples in `ServerStorage/TestWorldModels/GeneratedModels`
8. use the Studio helper in `MyTycoonGame/studio/` to clone the synced gallery or runtime test set into `Workspace`

## Customize the generated project

- open `MyTycoonGame/server/MainServer.lua` and add server initialization
- open `MyTycoonGame/server/WorldBuilder.lua` to reshape the generated sky island world
- open `MyTycoonGame/test/ModelLibrary.lua` to add more simple Studio-ready models
- add more synced Studio assets under `MyTycoonGame/test/SyncedModels/*.model.json`
- use `MyTycoonGame/studio/SpawnTestModels.plugin.lua` for one-click Studio previews
- edit `MyTycoonGame/shared/Config.lua` to point the project at your Roblox group/community
- open `MyTycoonGame/client/MainClient.lua` and add client UI hooks
- add Roblox instances in Studio for UI, spawns, checkpoints, queue positions

## Testing

Run the built-in test script to verify the generator:

```powershell
python test_generate_game.py
```

## Notes

- This generator is a starting point, not a complete playable game.
- `ServerStorage/TestWorldModels/SyncedModels` appears immediately after Rojo sync.
- Run the place once after syncing to populate `ServerStorage/TestWorldModels/GeneratedModels`.
- The `studio/` helpers are local Studio utilities and are not part of the live game build.
- Use Roblox Studio for asset layout, part placement, UI design, and in-game testing.
- Reuse Roblox Toolbox assets rather than modeling in Blender unless you need unique meshes.
- If you want a new genre, generate from `basic` and add your own module logic.
