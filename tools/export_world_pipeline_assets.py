from __future__ import annotations

import argparse
import json
import secrets
from pathlib import Path
from typing import Any

try:
    from export_prompt_pipeline_spec import to_lua
except ImportError:  # pragma: no cover - fallback for module execution styles
    from tools.export_prompt_pipeline_spec import to_lua

try:
    from text_world_pipeline import build_result
except ImportError:  # pragma: no cover - fallback for module execution styles
    from tools.text_world_pipeline import build_result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export a world-only prompt pipeline spec and modular world assets as Lua modules."
    )
    parser.add_argument("--world-prompt", required=True, help="Plain-language world prompt.")
    parser.add_argument(
        "--world-style",
        choices=("blocky", "smooth"),
        default="blocky",
        help="Target world-generation runtime style.",
    )
    parser.add_argument(
        "--generation-seed",
        type=int,
        default=None,
        help="Optional unique generation seed. A fresh seed is created automatically when omitted.",
    )
    parser.add_argument(
        "--output-lua",
        default="shared/WorldPromptSpec.lua",
        help="Lua module path for the raw world prompt spec.",
    )
    parser.add_argument(
        "--output-assets-lua",
        default="shared/ModularWorldAssets.lua",
        help="Lua module path for the generated modular world asset file.",
    )
    parser.add_argument(
        "--output-json",
        default="docs/world_prompt_runtime.json",
        help="Optional JSON sidecar path.",
    )
    return parser.parse_args()


def slug_title(value: str) -> str:
    cleaned = "".join(ch if ch.isalnum() or ch in {" ", "-"} else " " for ch in value)
    return " ".join(cleaned.split()).title()


def derive_title(world_result: dict[str, Any]) -> str:
    prompt = world_result["prompt"].lower()
    if "mountain" in prompt and "mushroom" in prompt and ("ruin" in prompt or "civilization" in prompt):
        return "Mushroom Crown Range"
    if "mushroom" in prompt and ("ruin" in prompt or "civilization" in prompt):
        return "Mushroom Ruins Expanse"

    theme = slug_title(world_result["world_spec"]["theme"].replace("-", " "))
    landmarks = world_result["world_spec"].get("landmarks", [])
    if landmarks:
        anchor = slug_title(str(landmarks[0]).replace("_", " "))
        return f"{theme} {anchor}"
    return f"{theme} Frontier"


def derive_asset_signature(world_result: dict[str, Any], generation_seed: int) -> str:
    prompt = world_result["prompt"]
    accumulator = generation_seed % 2147483647
    for character in prompt:
        accumulator = ((accumulator * 131) + ord(character)) % 2147483647
    return f"{accumulator:08X}"


def derive_goal_text(world_result: dict[str, Any]) -> str:
    world_spec = world_result["world_spec"]
    if world_spec.get("terrain") == "mountains" and world_spec.get("water_feature") == "lake":
        return (
            "Explore the summit mushroom ruins, descend through the twin valleys, "
            "and reach the lower lake basin across the mountain ranges."
        )
    landmarks = ", ".join(str(landmark).replace("_", " ") for landmark in world_spec.get("landmarks", []))
    if landmarks:
        return f"Explore the world spine, move through the landmarks, and use {landmarks} as major anchors."
    return "Explore the modular world and follow the anchor chain from spawn to objective."


def derive_intro_text(world_result: dict[str, Any], pipeline_style: str) -> str:
    world_spec = world_result["world_spec"]
    theme = slug_title(world_spec["theme"].replace("-", " "))
    terrain = slug_title(world_spec["terrain"].replace("-", " "))
    module_count = world_spec["module_count"]

    if pipeline_style == "smooth":
        return (
            f"Smooth terrain runtime for a {theme} world with {terrain.lower()} landforms "
            f"and {module_count} modular planning slots."
        )

    return (
        f"{slug_title(world_spec['art_style'].replace('-', ' '))} "
        f"{theme} layout with {module_count} modular slots."
    )


def derive_asset_styles(world_result: dict[str, Any]) -> dict[str, Any]:
    color_story = world_result["world_spec"].get("color_story", ["steel", "off-white", "safety orange"])
    base_map = {
        "steel": [92, 104, 124],
        "off-white": [225, 229, 232],
        "safety orange": [234, 145, 52],
        "charcoal": [60, 64, 72],
        "rust": [146, 84, 52],
        "hazard yellow": [245, 204, 58],
        "cream": [234, 225, 202],
        "brick": [148, 76, 67],
        "forest green": [74, 116, 68],
        "stone": [120, 121, 128],
        "gold": [219, 180, 69],
        "deep blue": [58, 82, 142],
        "dust tan": [182, 153, 110],
        "oxide red": [149, 88, 72],
        "smoke gray": [100, 104, 114],
        "sand": [226, 208, 146],
        "sea blue": [73, 133, 177],
        "palm green": [70, 126, 86],
        "snow white": [235, 242, 248],
        "ice blue": [146, 196, 228],
        "frost gray": [167, 180, 192],
    }

    mapped = [base_map.get(name, [180, 180, 190]) for name in color_story]
    while len(mapped) < 3:
        mapped.append([180, 180, 190])

    return {
        "PaletteRGB": mapped[:3],
        "BaseplateColorRGB": mapped[0],
        "PrimaryAccentColorRGB": mapped[1],
        "SecondaryAccentColorRGB": mapped[2],
        "BoundaryStyle": world_result["world_spec"]["boundary_style"],
    }


def prepare_world_assets(world_result: dict[str, Any], generation_seed: int, pipeline_style: str) -> dict[str, Any]:
    world_spec = world_result["world_spec"]
    modular_plan = world_result["modular_plan"]
    terrain_model = "part-columns" if pipeline_style == "blocky" else "terrain-heightmap"
    optimization_mode = "snap-modules and bounded landmark parts" if pipeline_style == "blocky" else "topographic heightfield, erosion passes, chunked voxel writes, and hero-asset budgets"
    originality_mode = "fresh procedural layout and asset dna per generation"
    return {
        "Version": "world-prompt-assets-v1",
        "Prompts": {"WorldPrompt": world_result["prompt"]},
        "Generation": {
            "Seed": generation_seed,
            "AssetSignature": derive_asset_signature(world_result, generation_seed),
            "ReusePolicy": "fresh-only unless a seed is explicitly pinned",
        },
        "Pipeline": {
            "Style": pipeline_style,
            "PlanningArtStyle": world_spec.get("art_style", "blocky"),
            "TerrainModel": terrain_model,
            "UsesWorkspaceTerrain": pipeline_style == "smooth",
            "OptimizationMode": optimization_mode,
            "OriginalityMode": originality_mode,
        },
        "Display": {
            "Title": derive_title(world_result),
            "GoalText": derive_goal_text(world_result),
            "IntroText": derive_intro_text(world_result, pipeline_style),
        },
        "World": {
            "WorldSpec": world_spec,
            "ModularPlan": modular_plan,
            "PipelineSteps": world_result["pipeline_steps"],
            "FilledGaps": world_result["filled_gaps"],
        },
        "AssetStyles": derive_asset_styles(world_result),
    }


def write_world_pipeline_files(
    *,
    world_prompt: str,
    output_lua: Path,
    output_assets_lua: Path,
    output_json: Path | None,
    generation_seed: int | None = None,
    pipeline_style: str = "blocky",
) -> dict[str, Any]:
    resolved_generation_seed = generation_seed or (secrets.randbelow(2_000_000_000) + 1)
    world_result = build_result(world_prompt)
    modular_world_assets = prepare_world_assets(world_result, resolved_generation_seed, pipeline_style)

    output_lua.parent.mkdir(parents=True, exist_ok=True)
    output_lua.write_text("return " + to_lua(world_result, 0) + "\n", encoding="utf-8")

    output_assets_lua.parent.mkdir(parents=True, exist_ok=True)
    output_assets_lua.write_text("return " + to_lua(modular_world_assets, 0) + "\n", encoding="utf-8")

    if output_json:
        output_json.parent.mkdir(parents=True, exist_ok=True)
        output_json.write_text(
            json.dumps(
                {
                    "generation_seed": resolved_generation_seed,
                    "pipeline_style": pipeline_style,
                    "world_result": world_result,
                },
                indent=2,
                ensure_ascii=True,
            )
            + "\n",
            encoding="utf-8",
        )

    return {
        "world_result": world_result,
        "modular_world_assets": modular_world_assets,
        "generation_seed": resolved_generation_seed,
    }


def main() -> int:
    args = parse_args()
    output_lua = Path(args.output_lua)
    output_assets_lua = Path(args.output_assets_lua)
    output_json = Path(args.output_json) if args.output_json else None

    written = write_world_pipeline_files(
        world_prompt=args.world_prompt,
        output_lua=output_lua,
        output_assets_lua=output_assets_lua,
        output_json=output_json,
        generation_seed=args.generation_seed,
        pipeline_style=args.world_style,
    )

    print(
        json.dumps(
            {
                "output_lua": str(output_lua),
                "output_assets_lua": str(output_assets_lua),
                "output_json": args.output_json,
                "title": written["modular_world_assets"]["Display"]["Title"],
                "world_style": args.world_style,
                "generation_seed": written["generation_seed"],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
