import argparse
import json
import re
from pathlib import Path


def build_place_ids_literal(place_ids: list[int]) -> str:
    return "{" + ", ".join(str(place_id) for place_id in place_ids) + "}" if place_ids else "{}"


def update_config_lua(config_path: Path, enabled: bool, place_ids: list[int]) -> None:
    text = config_path.read_text(encoding="utf-8")
    place_ids_literal = build_place_ids_literal(place_ids)
    enabled_literal = "true" if enabled else "false"

    if "ExperienceLockEnabled" in text:
        text = re.sub(
            r"ExperienceLockEnabled = (true|false),",
            f"ExperienceLockEnabled = {enabled_literal},",
            text,
        )
        text = re.sub(
            r"AllowedPlaceIds = \{[^\n]*\},",
            f"AllowedPlaceIds = {place_ids_literal},",
            text,
        )
    else:
        insertion = (
            f"    ExperienceLockEnabled = {enabled_literal},\n"
            f"    AllowedPlaceIds = {place_ids_literal},\n"
        )
        text = re.sub(r"(    GroupName = .*,\n)", r"\1" + insertion, text)

    config_path.write_text(text, encoding="utf-8")


def update_game_metadata(metadata_path: Path, enabled: bool, place_ids: list[int]) -> None:
    metadata = {}
    if metadata_path.exists():
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))

    metadata["experience_lock_enabled"] = enabled
    metadata["allowed_place_ids"] = place_ids
    metadata_path.write_text(json.dumps(metadata, indent=4), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Lock a generated Roblox project to one or more PlaceIds."
    )
    parser.add_argument(
        "--project",
        required=True,
        help="Path to the generated Roblox project folder, for example ./MyTycoonGame",
    )
    parser.add_argument(
        "--place-id",
        action="append",
        type=int,
        default=[],
        help="Allowed Roblox PlaceId. Repeat this flag to allow multiple places.",
    )
    parser.add_argument(
        "--disable",
        action="store_true",
        help="Disable the place lock and clear AllowedPlaceIds.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    project_path = Path(args.project).resolve()
    config_path = project_path / "shared" / "Config.lua"
    metadata_path = project_path / "game_metadata.json"

    if not config_path.exists():
        raise SystemExit(f"Could not find Config.lua at {config_path}")

    if args.disable:
        enabled = False
        place_ids: list[int] = []
    else:
        place_ids = args.place_id
        if not place_ids:
            raise SystemExit("Provide at least one --place-id, or use --disable.")
        enabled = True

    update_config_lua(config_path, enabled, place_ids)
    update_game_metadata(metadata_path, enabled, place_ids)

    status = "enabled" if enabled else "disabled"
    print(f"Experience lock {status} for {project_path.name}")
    print(f"AllowedPlaceIds = {build_place_ids_literal(place_ids)}")


if __name__ == "__main__":
    main()
