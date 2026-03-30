# Studio Setup

This guide covers installing the tooling, syncing the repo with Rojo, and placing the generated world into Roblox Studio.

## Install

1. Install Roblox Studio.
2. Install Python 3.10 or newer.
3. Install the Rojo CLI:

```powershell
winget install Rojo.Rojo
```

4. Install the Rojo Studio plugin:

```powershell
rojo plugin install
```

5. Open a fresh PowerShell window and verify:

```powershell
rojo --version
```

## Start Rojo

From the generated project folder:

```powershell
cd "C:\Users\Mikey\roblox tycoon\MyTycoonGame"
rojo serve --project default.project.json
```

Then open Roblox Studio, open the `Plugins` tab, launch Rojo, and connect to the local server.

## What syncs where

- `shared/` -> `ReplicatedStorage`
- `server/` -> `ServerScriptService`
- `client/` -> `StarterPlayerScripts`
- `test/` -> `ServerStorage/TestWorldModels`

## Use the synced models

After Rojo connects, open `Explorer` and go to:

`ServerStorage > TestWorldModels > SyncedModels`

Use this as your local model library.

To place the PNG-inspired world into the experience:

1. Right-click `SkyIslandHub`.
2. Choose `Copy`.
3. Right-click `Workspace`.
4. Choose `Paste Into`.

Do the same for smaller models like `FloatingPine`, `CloudPad`, or `MarketStand`.

Edit the copies in `Workspace`, not the source library in `ServerStorage`.

## Static world vs runtime world

There are two versions of the sky-island layout:

- `SkyIslandHub` in `ServerStorage/TestWorldModels/SyncedModels`
  - This is the permanent draggable Studio model.
- `server/WorldBuilder.lua`
  - This builds the world at runtime when you press Play.

If you want the structure saved into the place file, use the synced `SkyIslandHub` model in `Workspace`.

## Studio helper scripts

The repo includes:

- `MyTycoonGame/studio/SpawnTestModels.plugin.lua`
- `MyTycoonGame/studio/SpawnTestModels.command.lua`

These place the synced world and asset gallery into `Workspace` automatically.

## Troubleshooting

If the Rojo plugin does not appear:

- close all Studio windows
- reopen Studio
- check the `Plugins` tab again

If `rojo` is not recognized:

- close the terminal
- open a new terminal
- run `rojo --version`

If models are missing:

- confirm you started Rojo from the project folder
- reconnect the Rojo plugin
- expand `ServerStorage > TestWorldModels > SyncedModels`
