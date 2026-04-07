# Smooth Terrain Smoke Test

Smooth Terrain Smoke Test is a prompt-world experience generated with the `smooth` world pipeline.

## World style

- `smooth`: terrain-first generation using Workspace.Terrain, height sampling, and water-filled landforms

## Generated files

- `shared/WorldPromptSpec.lua` stores the parsed prompt result.
- `shared/ModularWorldAssets.lua` stores the planning data and render-style metadata.
- `server/PromptWorldService.lua` builds the world at edit time or runtime.
- `prompt_world_experience.json` records the generated experience metadata.
- `docs/world_prompt_runtime.json` keeps the JSON sidecar for inspection.
