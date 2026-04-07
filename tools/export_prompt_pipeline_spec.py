from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any

try:
    from text_gameplay_pipeline import build_result
except ImportError:  # pragma: no cover - fallback for module execution styles
    from tools.text_gameplay_pipeline import build_result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export a prompt-derived gameplay/world pipeline spec as a Lua module for a Roblox project."
    )
    parser.add_argument("--gameplay-prompt", required=True, help="Plain-language gameplay prompt.")
    parser.add_argument("--world-prompt", default="", help="Optional world prompt. Defaults to gameplay prompt.")
    parser.add_argument(
        "--output-lua",
        default="ToolboxLineGame/shared/PromptPipelineSpec.lua",
        help="Lua module path to write.",
    )
    parser.add_argument(
        "--output-assets-lua",
        default="ToolboxLineGame/shared/ModularWorldAssets.lua",
        help="Lua module path for the generated modular world asset plan.",
    )
    parser.add_argument(
        "--output-json",
        default="docs/prompt_pipeline_runtime.json",
        help="Optional JSON sidecar path for inspection.",
    )
    return parser.parse_args()


def slug_title(value: str) -> str:
    cleaned = "".join(ch if ch.isalnum() or ch in {" ", "-"} else " " for ch in value)
    return " ".join(cleaned.split()).title()


def derive_title(pipeline: dict[str, Any]) -> str:
    world_spec = pipeline["world_result"]["world_spec"]
    gameplay_spec = pipeline["gameplay_spec"]
    theme = slug_title(world_spec["theme"].replace("-", " "))
    core_loop = gameplay_spec["core_loop"]
    if core_loop == "queue-ladder":
        return f"{theme} Queue Terminal"
    if core_loop == "upgrade-tycoon":
        return f"{theme} Modular Tycoon"
    if core_loop == "combat-arena":
        return f"{theme} Arena Circuit"
    if core_loop == "social-roleplay":
        return f"{theme} Social Hub"
    if core_loop == "obby-checkpoints":
        return f"{theme} Checkpoint Run"
    return f"{theme} Prompt Experience"


def derive_goal_text(pipeline: dict[str, Any]) -> str:
    gameplay_spec = pipeline["gameplay_spec"]
    if gameplay_spec["core_loop"] == "queue-ladder":
        finale_role = gameplay_spec.get("finale_role", "host").replace("-", " ")
        return (
            f"Claim a spot, earn {gameplay_spec['currency_name']}, pay to move ahead, "
            f"and meet the {finale_role} at the front."
        )
    return "Move through the loop, scale your progression, and use the world anchors as milestones."


def derive_intro_text(pipeline: dict[str, Any]) -> str:
    gameplay_spec = pipeline["gameplay_spec"]
    world_spec = pipeline["world_result"]["world_spec"]
    return (
        f"{slug_title(world_spec['art_style'].replace('-', ' '))} {slug_title(world_spec['theme'].replace('-', ' '))} "
        f"layout with {gameplay_spec['player_capacity']} player capacity and {gameplay_spec['currency_name']} progression."
    )


def derive_layout_config(pipeline: dict[str, Any]) -> dict[str, Any]:
    integrated = pipeline["world_binding"]["integrated_world_spec"]
    gameplay = pipeline["gameplay_spec"]
    slot_count = int(gameplay["player_capacity"])
    slots_per_row = max(5, min(10, math.ceil(math.sqrt(slot_count * 2))))
    tile_spacing = max(10, round(integrated["grid_size"] * 0.5))
    row_spacing = tile_spacing + 2
    queue_rows = math.ceil(slot_count / slots_per_row)
    queue_start_z = max(56, queue_rows * row_spacing + 2)
    queue_side_margin = max(22, integrated["grid_size"])
    baseplate_width = ((slots_per_row - 1) * tile_spacing) + (queue_side_margin * 2) + 18
    baseplate_depth = (queue_rows * row_spacing) + 84
    front_row_z = queue_start_z - ((queue_rows - 1) * row_spacing)
    return {
        "slot_count": slot_count,
        "slots_per_row": slots_per_row,
        "tile_spacing": tile_spacing,
        "row_spacing": row_spacing,
        "queue_start_z": queue_start_z,
        "queue_front_z": front_row_z,
        "queue_side_margin": queue_side_margin,
        "module_grid_size": integrated["grid_size"],
        "baseplate_width": baseplate_width,
        "baseplate_depth": baseplate_depth,
        "route_style": "snake_rows",
    }


def derive_economy_config(pipeline: dict[str, Any]) -> dict[str, Any]:
    gameplay = pipeline["gameplay_spec"]
    slot_count = int(gameplay["player_capacity"])
    reward_base = max(4, round(slot_count / 12))
    reward_step = max(2, round(reward_base))
    advance_base_cost = reward_base * 8
    advance_cost_step = reward_step * 11
    finale_bonus = max(5000, advance_base_cost * slot_count * 3)
    return {
        "currency_name": gameplay["currency_name"],
        "reward_base": reward_base,
        "reward_step": reward_step,
        "advance_base_cost": advance_base_cost,
        "advance_cost_step": advance_cost_step,
        "finale_bonus": finale_bonus,
    }


def prepare_runtime_spec(pipeline: dict[str, Any]) -> dict[str, Any]:
    runtime_layout = derive_layout_config(pipeline)
    runtime_economy = derive_economy_config(pipeline)
    runtime_display = {
        "title": derive_title(pipeline),
        "goal_text": derive_goal_text(pipeline),
        "queue_intro_text": derive_intro_text(pipeline),
        "finale_prompt_text": f"Meet the {pipeline['gameplay_spec'].get('finale_role', 'host').replace('-', ' ')}",
    }
    runtime_spec = dict(pipeline)
    runtime_spec["runtime_layout"] = runtime_layout
    runtime_spec["runtime_economy"] = runtime_economy
    runtime_spec["runtime_display"] = runtime_display
    return runtime_spec


def prepare_modular_world_assets(runtime_spec: dict[str, Any]) -> dict[str, Any]:
    world_spec = runtime_spec["world_result"]["world_spec"]
    world_binding = runtime_spec["world_binding"]

    return {
        "Version": "prompt-modular-assets-v1",
        "Prompts": {
            "GameplayPrompt": runtime_spec["gameplay_prompt"],
            "WorldPrompt": runtime_spec["world_prompt"],
        },
        "Display": {
            "Title": runtime_spec["runtime_display"]["title"],
            "GoalText": runtime_spec["runtime_display"]["goal_text"],
            "QueueIntroText": runtime_spec["runtime_display"]["queue_intro_text"],
            "FinalePromptText": runtime_spec["runtime_display"]["finale_prompt_text"],
            "FinaleRole": runtime_spec["gameplay_spec"].get("finale_role", "host"),
        },
        "Layout": runtime_spec["runtime_layout"],
        "Economy": runtime_spec["runtime_economy"],
        "World": {
            "Theme": world_spec["theme"],
            "ArtStyle": world_spec["art_style"],
            "Terrain": world_spec["terrain"],
            "LayoutStyle": world_spec["layout"],
            "IntegratedWorldSpec": world_binding["integrated_world_spec"],
            "ZoneAllocations": world_binding["zone_allocations"],
            "RequiredModuleFamilies": world_binding["required_module_families"],
            "ThroughputRules": world_binding["throughput_rules"],
            "BindingNotes": world_binding["binding_notes"],
        },
        "AssetStyles": {
            "ZoneColors": {
                "spawn_entry": [255, 210, 96],
                "queue_slots": [88, 112, 162],
                "income_nodes": [116, 220, 176],
                "finale_pad": [126, 208, 255],
                "exit_reset": [162, 241, 180],
            },
            "BaseplateColorRGB": [45, 50, 62],
            "QueueLaneColorRGB": [42, 47, 60],
            "QueueRowPlateColorRGB": [53, 58, 72],
            "SideRailColorRGB": [70, 76, 92],
            "BackdropColorRGB": [60, 66, 84],
            "StructureMetalColorRGB": [56, 62, 76],
            "AccentMetalColorRGB": [77, 85, 104],
            "IncomeMarkerBaseColorRGB": [36, 40, 50],
            "CheckpointGateColorRGB": [239, 183, 64],
            "QueueSlotGradientStartRGB": [68, 92, 124],
            "QueueSlotGradientEndRGB": [208, 168, 70],
        },
    }


def lua_key(key: str) -> str:
    if key.isidentifier():
        return key
    return f'["{key}"]'


def to_lua(value: Any, indent: int = 0) -> str:
    pad = " " * indent
    child_pad = " " * (indent + 4)
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "nil"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        return f'"{escaped}"'
    if isinstance(value, list):
        if not value:
            return "{}"
        items = ",\n".join(f"{child_pad}{to_lua(item, indent + 4)}" for item in value)
        return "{\n" + items + "\n" + pad + "}"
    if isinstance(value, dict):
        if not value:
            return "{}"
        entries = []
        for key, item in value.items():
            entries.append(f"{child_pad}{lua_key(str(key))} = {to_lua(item, indent + 4)}")
        return "{\n" + ",\n".join(entries) + "\n" + pad + "}"
    raise TypeError(f"Unsupported value for Lua serialization: {type(value)!r}")


def write_prompt_runtime_files(
    *,
    gameplay_prompt: str,
    world_prompt: str | None,
    output_lua: Path,
    output_assets_lua: Path,
    output_json: Path | None,
) -> dict[str, Any]:
    pipeline = build_result(gameplay_prompt, world_prompt or None)
    runtime_spec = prepare_runtime_spec(pipeline)
    modular_world_assets = prepare_modular_world_assets(runtime_spec)

    output_lua.parent.mkdir(parents=True, exist_ok=True)
    output_lua.write_text("return " + to_lua(runtime_spec, 0) + "\n", encoding="utf-8")

    output_assets_lua.parent.mkdir(parents=True, exist_ok=True)
    output_assets_lua.write_text("return " + to_lua(modular_world_assets, 0) + "\n", encoding="utf-8")

    if output_json:
        output_json.parent.mkdir(parents=True, exist_ok=True)
        output_json.write_text(json.dumps(runtime_spec, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")

    return {
        "runtime_spec": runtime_spec,
        "modular_world_assets": modular_world_assets,
    }


def main() -> int:
    args = parse_args()
    output_lua = Path(args.output_lua)
    output_assets_lua = Path(args.output_assets_lua)
    output_json = Path(args.output_json) if args.output_json else None
    written = write_prompt_runtime_files(
        gameplay_prompt=args.gameplay_prompt,
        world_prompt=args.world_prompt or None,
        output_lua=output_lua,
        output_assets_lua=output_assets_lua,
        output_json=output_json,
    )
    runtime_spec = written["runtime_spec"]

    print(
        json.dumps(
            {
                "output_lua": str(output_lua),
                "output_assets_lua": str(output_assets_lua),
                "output_json": args.output_json,
                "title": runtime_spec["runtime_display"]["title"],
                "slot_count": runtime_spec["runtime_layout"]["slot_count"],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
