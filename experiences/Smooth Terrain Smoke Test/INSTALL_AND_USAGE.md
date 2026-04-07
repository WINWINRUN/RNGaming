# Smooth Terrain Smoke Test Install And Usage

This project is a prompt-world experience, not the older terrain scaffold.

## Pipeline

- world style: `smooth`
- renderer: terrain-first generation using Workspace.Terrain, height sampling, and water-filled landforms
- source prompt: `rolling alpine valley with a crater lake, ancient stone ruins, and smooth cliffs you can walk across`

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
python tools\create_prompt_world_experience.py --name "Smooth Terrain Smoke Test" --world-style smooth --world-prompt "rolling alpine valley with a crater lake, ancient stone ruins, and smooth cliffs you can walk across" --force
```

## Runtime Notes

- `shared/Config.lua` keeps `AutoGenerateOnServerStart = false` by default so Studio does not rebuild unexpectedly.
- `server/PromptWorldService.lua` is the active world builder for this experience.
- `Workspace` attributes such as `PromptWorldTitle` and `PromptWorldRenderStyle` report the live generation result.
