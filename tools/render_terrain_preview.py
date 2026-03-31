import argparse
import json
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:
    raise SystemExit("Pillow is required for terrain previews. Install it with: python -m pip install pillow") from exc

from terrain_math import load_project_manifest, summarize_profile


SURFACE_COLORS = {
    "water": (69, 128, 194),
    "shore": (215, 196, 142),
    "meadow": (92, 156, 88),
    "forest": (57, 118, 58),
    "cliff": (104, 108, 114),
    "alpine": (235, 238, 244),
    "dunes": (223, 189, 132),
    "mesa": (182, 118, 74),
    "grove": (82, 142, 92),
    "summit": (235, 240, 247),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render top-down preview images for the terrain profiles in a generated Roblox project."
    )
    parser.add_argument("--project", required=True, help="Path to the generated project folder.")
    parser.add_argument("--resolution", type=int, default=192, help="Preview resolution per side.")
    parser.add_argument("--profile", default="all", help="Single profile name to render, or 'all'.")
    return parser.parse_args()


def tint(color: tuple[int, int, int], factor: float) -> tuple[int, int, int]:
    return tuple(max(0, min(255, int(channel * factor))) for channel in color)


def render_profile(output_dir: Path, profile_name: str, summary: dict) -> None:
    sampled = summary["sampled"]
    heights = sampled["heights"]
    slopes = sampled["slopes"]
    surfaces = sampled["surfaces"]
    min_height = summary["minimum_height"]
    height_span = max(summary["height_span"], 1.0)
    size = len(heights)
    image = Image.new("RGB", (size, size))

    for y in range(size):
        for x in range(size):
            surface = surfaces[y][x]
            base = SURFACE_COLORS.get(surface, (120, 120, 120))
            height_factor = 0.75 + 0.35 * ((heights[y][x] - min_height) / height_span)
            slope_factor = max(0.65, 1.05 - min(slopes[y][x], 1.4) * 0.22)
            image.putpixel((x, y), tint(base, height_factor * slope_factor))

    image_path = output_dir / f"{profile_name}.png"
    image.save(image_path)

    stats_path = output_dir / f"{profile_name}.json"
    stats_path.write_text(
        json.dumps(
            {
                key: value
                for key, value in summary.items()
                if key != "sampled"
            },
            indent=4,
        ),
        encoding="utf-8",
    )


def main() -> int:
    args = parse_args()
    project_path = Path(args.project).resolve()
    manifest = load_project_manifest(project_path)
    metadata_path = project_path / "game_metadata.json"
    default_seed = 1337
    if metadata_path.exists():
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        default_seed = metadata.get("default_seed", default_seed)

    output_dir = project_path / "art" / "reviews" / "terrain"
    output_dir.mkdir(parents=True, exist_ok=True)

    profiles = manifest["Profiles"]
    selected = profiles.keys() if args.profile == "all" else [args.profile]
    for profile_name in selected:
        if profile_name not in profiles:
            raise SystemExit(f"Unknown profile '{profile_name}'")
        summary = summarize_profile(profiles[profile_name], default_seed, args.resolution)
        render_profile(output_dir, profile_name, summary)
        print(f"Rendered preview for {profile_name} to {output_dir}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
