# Regular Sentence World Pipeline

This pipeline is meant for fast world ideation from normal language instead of a rigid schema.

For the gameplay companion that binds loops and progression back onto the world spec, see [REGULAR_SENTENCE_GAMEPLAY_PIPELINE.md](C:/Users/Mikey/roblox%20tycoon/docs/REGULAR_SENTENCE_GAMEPLAY_PIPELINE.md).

## What it does

`tools/text_world_pipeline.py` takes a sentence like:

```text
blocky sci-fi outpost with one main road, cramped side alleys, a big landing pad, and low detail
```

and turns it into:

- explicit config extracted from the sentence
- filled defaults for everything the sentence did not specify
- a final modular `world_spec`
- a short build pipeline for chunk assembly

## Why this version is useful

It keeps the prompt loose and human, but still gives us structured output we can feed into later tooling.

The script is designed around three layers:

1. Parse what the sentence clearly says.
2. Fill the missing fields from theme, style, and gameplay defaults.
3. Emit a modular build recipe instead of raw noise-based generation.

## Example usage

```powershell
python tools\text_world_pipeline.py --prompt "blocky sci-fi outpost with one main road, cramped side alleys, a big landing pad, and low detail" --json-out docs\world_prompt_example.json
```

## Output shape

The JSON output contains:

- `explicit_config`
- `filled_gaps`
- `world_spec`
- `modular_plan`
- `pipeline_steps`

## Intended follow-up

This is intentionally left as a planning pipeline for now.

The next integration step would be:

1. Map `module_families` to actual Roblox prefabs or Creator Store module kits.
2. Convert `world_spec` into a snapped grid layout.
3. Run a placement pass, a validation pass, and then a dressing pass.

The prompt-to-runtime bridge for this repo is documented in [PROMPT_PIPELINE_RUNTIME.md](C:/Users/Mikey/roblox%20tycoon/docs/PROMPT_PIPELINE_RUNTIME.md).

For generating a separate new experience instead of reusing an existing Studio place, use [PROMPT_EXPERIENCE_WORKFLOW.md](C:/Users/Mikey/roblox%20tycoon/docs/PROMPT_EXPERIENCE_WORKFLOW.md).
