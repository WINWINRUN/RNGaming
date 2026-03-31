import argparse
import sys
from pathlib import Path

from terrain_math import load_project_manifest, summarize_profile


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Review terrain profile ranges and sampled terrain statistics for a generated Roblox project."
    )
    parser.add_argument("--project", required=True, help="Path to the generated project folder.")
    parser.add_argument("--resolution", type=int, default=96, help="Sampling resolution per profile.")
    parser.add_argument("--strict", action="store_true", help="Exit with a non-zero code if warnings are found.")
    return parser.parse_args()


def review_profile(profile: dict, summary: dict) -> list[str]:
    warnings: list[str] = []
    if profile["WorldSize"] % profile["CellSize"] != 0:
        warnings.append("world size should be divisible by cell size")
    if not 4 <= profile["CellSize"] <= 32:
        warnings.append("cell size should stay between 4 and 32 studs")
    if profile["Spawn"]["FlattenRadius"] >= profile["WorldSize"] * 0.25:
        warnings.append("spawn flatten radius is very large relative to the world size")
    if profile["Props"]["TreeDensity"] + profile["Props"]["BushDensity"] + profile["Props"]["RockDensity"] > 0.8:
        warnings.append("combined prop density is high and may clutter the environment")
    if summary["height_span"] < 24:
        warnings.append("height span is very low and may look too flat")
    if summary["spawn_height_stddev"] > 4.5:
        warnings.append("spawn area is not very flat")

    if profile["Kind"] == "Heightmap":
        if profile["Name"] in {"DesertCanyon", "FrozenDesertMoon"}:
            if summary["water_coverage"] > 0.2:
                warnings.append("water coverage is too high for the desert profile")
        else:
            if summary["water_coverage"] < 0.03:
                warnings.append("water coverage is low; the scene may feel dry")
            if summary["water_coverage"] > 0.6:
                warnings.append("water coverage is high; the scene may feel flooded")
    else:
        if profile["IslandCount"] < 4:
            warnings.append("sky island count is low")
        if profile["IslandCount"] > 12:
            warnings.append("sky island count is high and may feel cluttered")

    return warnings


def main() -> int:
    args = parse_args()
    project_path = Path(args.project).resolve()
    manifest = load_project_manifest(project_path)
    default_seed = 1337
    metadata_path = project_path / "game_metadata.json"
    if metadata_path.exists():
        import json

        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        default_seed = metadata.get("default_seed", default_seed)

    any_warnings = False
    for profile_name, profile in manifest["Profiles"].items():
        summary = summarize_profile(profile, default_seed, args.resolution)
        warnings = review_profile(profile, summary)
        warning_suffix = f" | warnings: {len(warnings)}" if warnings else " | warnings: 0"
        print(
            f"{profile_name}: span={summary['height_span']:.1f}, water={summary['water_coverage']:.2%}, "
            f"steep={summary['steep_coverage']:.2%}, spawn_stddev={summary['spawn_height_stddev']:.2f}{warning_suffix}"
        )
        for warning in warnings:
            any_warnings = True
            print(f"  - {warning}")

    if any_warnings and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
