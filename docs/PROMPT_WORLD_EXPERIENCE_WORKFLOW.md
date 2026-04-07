# Prompt World Experience Workflow

Use this workflow when the request is mainly about generating a new world concept, not reusing an existing gameplay template.

## Main command

```powershell
python tools\create_prompt_world_experience.py --name "Mushroom Ruins Expanse" --world-prompt "giant mushroom forest surrounded by sci-fi robot giant ruins from ancient civilization"
```

## Choose a world style

The world-only generator now supports two separate pipelines:

- `blocky`: modular part-built terrain made from snapped columns and landmark parts
- `smooth`: `Workspace.Terrain` generation from a topographic control map, erosion passes, and chunked voxel writes

Example smooth-world command:

```powershell
python tools\create_prompt_world_experience.py --name "Alpine Basin" --world-style smooth --world-prompt "rolling alpine valley with a crater lake, ancient stone ruins, and smooth cliffs you can walk across"
```

If you want a completely fresh result every time, omit `--generation-seed`. The tool will stamp a new seed and a new procedural asset signature on each regeneration.

## What it does

1. Creates a fresh terrain-first experience scaffold in `experiences/`.
2. Writes `shared/WorldPromptSpec.lua`.
3. Writes `shared/ModularWorldAssets.lua`.
4. Writes `docs/world_prompt_runtime.json`.
5. Copies the correct runtime for the selected `--world-style`.
6. Rewrites the generated project docs so they match the prompt-world architecture.
7. Applies the style-specific generation policy:
   smooth uses topographic control maps, erosion passes, chunked voxel generation, hero-detail budgets, and fresh procedural landmark families.
8. Builds a separate `.rbxlx` for that experience.
9. Lets you capture Creator Store asset usage into a rolling Excel log once live Studio assets have been placed.

## Why this matters

This keeps new world-generation requests isolated from the current active gameplay project in Studio, and it lets us preserve the older block/cube world engine without forcing every new world onto that same renderer.

## Creator Store asset logs

If a world uses ready-made Creator Store assets in Studio, capture them into an Excel workbook with:

```powershell
python tools\log_creator_store_asset_usage.py --experience-root "experiences\Your World Name"
```

Each workbook records:

- world log id
- asset identification number
- asset id and asset version id
- marketplace name
- search query
- creator name
- Roblox library URL
- placement count
- unique asset count and total placed instance count

The log folder is `docs/creator_store_asset_logs/`, and the retention policy keeps only the latest 5 world workbooks. Once a 6th world log is written, the oldest `.xlsx` file is deleted automatically.

For a direct comparison of `blocky` versus `smooth`, use [WORLD_PIPELINE_STYLES.md](/c:/Users/Mikey/roblox%20tycoon/docs/WORLD_PIPELINE_STYLES.md).
