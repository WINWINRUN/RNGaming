# Mushroom Ruins Expanse Smooth

Mushroom Ruins Expanse Smooth is a prompt-world experience generated with the `smooth` world pipeline.

## World style

- `smooth`: topographic heightfield generation using Workspace.Terrain, erosion passes, and chunked voxel writes

## Generation policy

- each regeneration uses a fresh procedural seed unless you explicitly pin `--generation-seed`
- smooth worlds synthesize new terrain macro-shapes and new asset families instead of reusing fixed prefab landmarks
- large smooth worlds use bounded hero-detail budgets and yielded generation steps to keep the runtime lighter

## Generated files

- `shared/WorldPromptSpec.lua` stores the parsed prompt result.
- `shared/ModularWorldAssets.lua` stores the planning data and render-style metadata.
- `server/PromptWorldService.lua` builds the world at edit time or runtime.
- `prompt_world_experience.json` records the generated experience metadata.
- `docs/world_prompt_runtime.json` keeps the JSON sidecar for inspection.
- `docs/creator_store_asset_logs/*.xlsx` stores rolling Creator Store asset logs for this world.
