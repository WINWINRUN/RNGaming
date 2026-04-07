# World Pipeline Styles

The repo now keeps two world-generation paths side by side instead of forcing every prompt onto the same renderer.

## `blocky`

Use `blocky` when you want:

- snapped modular terrain
- visible cube or column construction
- kitbashed landmark parts
- fast iteration for stylized or low-poly worlds

Implementation notes:

- renderer: part-built runtime
- terrain model: `part-columns`
- main template: `tools/templates/prompt_world_runtime/`
- create command: `python tools\create_prompt_world_experience.py --world-style blocky ...`

## `smooth`

Use `smooth` when you want:

- more natural landforms
- `Workspace.Terrain` instead of cube stacks
- a topographic terrain field instead of bead-like blob smoothing
- erosion-shaped slopes, basins, and valleys
- a terrain-first world base that can be dressed later
- fresh procedural landmark families instead of reusing one fixed mushroom or ruin kit

Implementation notes:

- renderer: terrain-first runtime
- terrain model: `terrain-heightmap`
- terrain core: coarse topography map -> erosion passes -> interpolated heightfield -> chunked voxel writes
- main template: `tools/templates/prompt_world_runtime_smooth/`
- create command: `python tools\create_prompt_world_experience.py --world-style smooth ...`
- optimization flow: chunked voxel terrain writes, bounded hero-detail counts, and reduced expensive point-light usage
- originality mode: fresh terrain macro-shapes plus new mushroom/ruin asset DNA on each regeneration unless you pin a seed
- Creator Store asset tracking: if live Studio foliage or props are inserted, log them to `docs/creator_store_asset_logs/*.xlsx` with a rolling 5-world retention window

## Shared planning layer

Both styles still share the prompt extraction stage:

- `tools/text_world_pipeline.py` turns a normal sentence into `world_spec`
- `tools/export_world_pipeline_assets.py` writes `WorldPromptSpec.lua` and `ModularWorldAssets.lua`
- `shared/ModularWorldAssets.lua` now records `Pipeline.Style` and `Pipeline.TerrainModel`

That means the planning layer is shared, while the final renderer is style-specific.

## Current boundary

- `blocky` world generation is the established modular/cube engine.
- `smooth` world generation is the new terrain-first world-only pipeline.
- the gameplay-generation pipeline still sits on the modular/blocky path for now.
