# RNGaming

RNGaming is now a terrain-first Roblox scaffold generator.

The repo builds isolated Rojo projects that focus on procedural terrain, environment dressing, safe edit-time generation, and preview tooling. You can generate the world foundation first and add your own game mode skeletons later.

## Quickstart

```powershell
python generate_game.py --game-name "MyTerrainExperience" --template terrain --output ".\MyTerrainExperience" --author "Mikey" --version "0.1" --force
```

Then sync it with Rojo:

```powershell
cd ".\MyTerrainExperience"
rojo serve default.project.json
```

## Included systems

- `server/terrain/` modules for deterministic terrain generation and primitive environment dressing
- `shared/TerrainProfiles.lua` for profile-driven world presets
- `shared/ExperienceGuard.lua` for place locking and experience isolation
- `studio/GenerateTerrain.command.lua` and `studio/GenerateTerrain.plugin.lua` for edit-time generation
- `tools/review_terrain_profiles.py` for sampled terrain checks
- `tools/render_terrain_preview.py` for visual previews generated from the same seeded noise stack

Included profiles:
- `TemperateFrontier`
- `DesertCanyon`
- `FrozenDesertMoon`
- `SkyArchipelago`
- `SpaceWaterfallCliffs`

## Create separate experiences

```powershell
python tools\create_experience.py --name "ForestLobby" --output-root ".\experiences" --author "Mikey" --version "0.1" --default-profile TemperateFrontier --force
```

Lock a generated experience to one or more place IDs:

```powershell
python tools\lock_project_to_place.py --project ".\experiences\ForestLobby" --place-id 123456789
```

## Review and preview

```powershell
python tools\review_terrain_profiles.py --project ".\MyTerrainExperience"
python tools\render_terrain_preview.py --project ".\MyTerrainExperience"
```

If preview rendering says Pillow is missing, install it with `python -m pip install pillow`.

## Studio MCP bridge

The Roblox Studio CLI bridge code used during development is now vendored in:
- [integrations/roblox-studio-mcp](C:/Users/Mikey/roblox%20tycoon/integrations/roblox-studio-mcp)

That folder includes the local bridge wrappers plus the upstream Rust MCP server and Studio plugin source used for Studio CLI access.

## Notes

- The scaffold does not inject a game mode by default.
- Terrain generation is bounded to a managed region so it does not blindly wipe an entire place.
- Isolation comes from one project folder per experience plus optional place locks.
