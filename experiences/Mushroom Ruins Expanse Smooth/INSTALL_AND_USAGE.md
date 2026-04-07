# Mushroom Ruins Expanse Smooth Install And Usage

This project is a prompt-world experience, not the older terrain scaffold.

## Pipeline

- world style: `smooth`
- renderer: topographic heightfield generation using Workspace.Terrain, erosion passes, and chunked voxel writes
- source prompt: `snow world filled with giant trees and 4 giant flat top ice pillars`

## Fresh generation behavior

- omit `--generation-seed` to force a new procedural terrain and asset pass on every regeneration
- smooth worlds use a built-in optimization flow with topographic control maps, erosion passes, chunked voxel writes, and bounded hero detail

## Open In Studio

1. Open this project folder in your editor.
2. Start Rojo from the project root:

```powershell
rojo serve --project default.project.json
```

3. Open the built place from `build/` or connect Studio with the Rojo plugin.

## Regenerate From Prompt

Regenerate the project from the repo root with:

```powershell
python tools\create_prompt_world_experience.py --name "Mushroom Ruins Expanse Smooth" --world-style smooth --world-prompt "snow world filled with giant trees and 4 giant flat top ice pillars" --force
```

## Runtime Notes

- `shared/Config.lua` keeps `AutoGenerateOnServerStart = false` by default so Studio does not rebuild unexpectedly.
- `server/PromptWorldService.lua` is the active world builder for this experience.
- `Workspace` attributes such as `PromptWorldTitle` and `PromptWorldRenderStyle` report the live generation result.
- If you place ready-made Creator Store assets into the live world, record them with:

```powershell
python tools\log_creator_store_asset_usage.py --experience-root "experiences\Mushroom Ruins Expanse Smooth"
```

- The asset log keeps only the latest 5 world workbooks and deletes older `.xlsx` files automatically.
