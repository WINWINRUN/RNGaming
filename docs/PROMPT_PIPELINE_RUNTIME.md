# Prompt Pipeline Runtime Flow

This is the end-to-end bridge from prompt text to an actual Roblox project runtime.

## What now exists

- `tools/text_world_pipeline.py`
- `tools/text_gameplay_pipeline.py`
- `tools/export_prompt_pipeline_spec.py`
- `tools/create_prompt_experience.py`
- `ToolboxLineGame/shared/PromptPipelineSpec.lua`
- `ToolboxLineGame/shared/ModularWorldAssets.lua`
- `ToolboxLineGame/server/PromptPipelineBuilder.lua`

## Flow

1. Parse a world sentence into a modular `world_spec`.
2. Parse a gameplay sentence into a `gameplay_spec`.
3. Bind gameplay zones back onto the modular world anchors.
4. Export the combined runtime spec to Lua.
5. Export a dedicated modular world asset file to Lua.
6. Let the Roblox project read those files at runtime.
7. Build modular parts, slot positions, anchors, prompts, and signage from the exported plan.

## Export command

```powershell
python tools\export_prompt_pipeline_spec.py --world-prompt "blocky sci-fi queue terminal with one long main route, bright checkpoints, and a reward room at the front" --gameplay-prompt "50-player waiting in line game where each player is locked to one spot, earns more tickets near the front, pays more to move ahead, and meets the host at the end" --output-lua ToolboxLineGame\shared\PromptPipelineSpec.lua --output-assets-lua ToolboxLineGame\shared\ModularWorldAssets.lua --output-json docs\prompt_pipeline_runtime.json
```

## Runtime behavior

`ToolboxLineGame` now reads the generated spec and uses it to drive:

- slot count
- queue layout dimensions
- currency name
- reward and cost tuning
- sign text
- world anchors
- modular decor placement

For fully isolated new experiences, use [PROMPT_EXPERIENCE_WORKFLOW.md](C:/Users/Mikey/roblox%20tycoon/docs/PROMPT_EXPERIENCE_WORKFLOW.md).

For world-only isolated experience generation, use [PROMPT_WORLD_EXPERIENCE_WORKFLOW.md](C:/Users/Mikey/roblox%20tycoon/docs/PROMPT_WORLD_EXPERIENCE_WORKFLOW.md).

## Verification

The updated project should build with:

```powershell
cd ToolboxLineGame
rojo build default.project.json -o build\ToolboxLineGame.promptpipeline.rbxlx
```
