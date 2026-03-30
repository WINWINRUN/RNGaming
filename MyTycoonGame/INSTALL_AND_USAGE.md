
# Install And Usage

This guide explains how to install the tools for `MyTycoon`, sync the project with Rojo, and place the generated world into Roblox Studio.

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

This template also includes a runtime world generator for `tycoon`.

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

- `GroupId = 846021713`
- `GroupName = "RN_Gaming"`

## Troubleshooting

If models do not appear in Studio:

- make sure Rojo is connected
- reconnect the Rojo plugin
- confirm `default.project.json` is being served from this folder

If `rojo` is not recognized in PowerShell:

- close the terminal
- open a new terminal window
- run `rojo --version`
