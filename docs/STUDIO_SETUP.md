# Studio Setup

This repo now targets a terrain-first Roblox workflow.

## Install and sync

1. Install the Rojo CLI and the Rojo Studio plugin.
2. Generate or open a project folder such as `MyTycoonGame`.
3. Start Rojo from that folder:

```powershell
rojo serve default.project.json
```

4. Open Roblox Studio.
5. Open the Rojo plugin and connect to the local server.

## What syncs where

- `shared/` -> `ReplicatedStorage`
- `server/` -> `ServerScriptService`
- `client/` -> `StarterPlayer/StarterPlayerScripts`

The terrain generator writes into:

- `Workspace.Terrain`
- `Workspace/GeneratedEnvironment`
- `Workspace/GeneratedSpawn`

## Generate terrain in Studio

Default behavior is conservative:

- `AutoGenerateOnServerStart = false`
- generation only clears the configured managed region
- place locking can block generation in the wrong experience

To generate terrain in edit mode:

1. Open `View > Command Bar`.
2. Paste `studio/GenerateTerrain.command.lua`, or install `studio/GenerateTerrain.plugin.lua` as a local Studio plugin.
3. Run generation.

## Experience isolation

Use one project folder per experience or place workflow, then lock it with:

```powershell
python tools\lock_project_to_place.py --project ".\MyTycoonGame" --place-id 123456789
```

If you reuse the same local project folder across multiple places, Rojo will still sync that same source tree to each connected place. Isolation comes from separate folders plus place locks, not from Rojo alone.

## Review loop

```powershell
python tools\review_terrain_profiles.py --project ".\MyTycoonGame"
python tools\render_terrain_preview.py --project ".\MyTycoonGame"
```

If preview rendering says Pillow is missing, install it with `python -m pip install pillow`.
