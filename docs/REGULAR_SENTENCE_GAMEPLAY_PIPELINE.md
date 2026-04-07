# Regular Sentence Gameplay Pipeline

This is the gameplay companion to the modular world pipeline.

`tools/text_gameplay_pipeline.py` reads a normal gameplay sentence, extracts the playable structure, fills missing fields with defaults, and then binds that design back onto the modular world spec from `tools/text_world_pipeline.py`.

## What it produces

- `explicit_gameplay_config`
- `filled_gameplay_gaps`
- `gameplay_spec`
- `world_binding`
- `world_result`
- `gameplay_pipeline_steps`

## Why it fits the world pipeline

The gameplay script does not build a separate disconnected design.

Instead, it:

1. Builds or imports a modular `world_spec`.
2. Derives the gameplay loop from a regular sentence.
3. Expands the world module count if gameplay capacity needs more space.
4. Maps gameplay zones onto world anchors and module families.
5. Emits throughput and validation rules that can drive later generation.

## Example usage

```powershell
python tools\text_gameplay_pipeline.py --world-prompt "blocky sci-fi queue terminal with one long main route and bright checkpoints" --gameplay-prompt "50-player waiting in line game where each player is locked to one spot, earns more tickets near the front, pays more to move ahead, and meets the host at the end" --json-out docs\gameplay_prompt_example.json
```

## Integration model

The important bridge is `world_binding`.

That section tells us:

- which gameplay zones must exist
- which world anchors they should use
- which module families are required
- how many modular slots the world may need after gameplay is attached

## Intended follow-up

The next practical step would be to translate `zone_allocations` into actual Roblox prefab placement rules:

1. reserve anchors
2. assign snapped module budgets
3. place interaction nodes
4. wire costs, rewards, and fail states
5. run throughput validation

That runtime bridge now exists in [PROMPT_PIPELINE_RUNTIME.md](C:/Users/Mikey/roblox%20tycoon/docs/PROMPT_PIPELINE_RUNTIME.md).

For creating a brand-new isolated experience from prompts, use [PROMPT_EXPERIENCE_WORKFLOW.md](C:/Users/Mikey/roblox%20tycoon/docs/PROMPT_EXPERIENCE_WORKFLOW.md).
