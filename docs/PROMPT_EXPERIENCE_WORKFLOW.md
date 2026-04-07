# Prompt Experience Workflow

New prompt-driven games should now be created as separate project folders, not injected into the same Studio experience.

## Main command

```powershell
python tools\create_prompt_experience.py --name "Sci Fi Queue Terminal" --world-prompt "blocky sci-fi queue terminal with one long main route, bright checkpoints, and a reward room at the front" --gameplay-prompt "50-player waiting in line game where each player is locked to one spot, earns more tickets near the front, pays more to move ahead, and meets the host at the end"
```

## What it does

1. Copies the prompt-game architecture into a fresh folder under `experiences/`.
2. Writes `shared/PromptPipelineSpec.lua`.
3. Writes `shared/ModularWorldAssets.lua`.
4. Writes `docs/prompt_pipeline_runtime.json` inside that new experience.
5. Builds a separate `.rbxlx` for that experience.

## Important result

This means a new gameplay request or new game request should create a new world in a new generated experience folder, instead of reusing `ToolboxLineGame` in Studio.

## Current scope

This gameplay pipeline still targets the modular/blocky world architecture.

- Use it when the world and gameplay should be generated together from snapped modular assets.
- Use the smooth terrain pipeline only for world-only experiences right now.

For world-only requests, use [PROMPT_WORLD_EXPERIENCE_WORKFLOW.md](C:/Users/Mikey/roblox%20tycoon/docs/PROMPT_WORLD_EXPERIENCE_WORKFLOW.md).
