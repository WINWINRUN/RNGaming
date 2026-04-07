from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path

try:
    from export_prompt_pipeline_spec import write_prompt_runtime_files
except ImportError:  # pragma: no cover - fallback for module execution styles
    from tools.export_prompt_pipeline_spec import write_prompt_runtime_files


ARCHITECTURE_VERSION = "prompt-modular-experience-v1"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a fresh isolated Roblox experience from world/gameplay prompts."
    )
    parser.add_argument("--name", required=True, help="Experience folder and display name.")
    parser.add_argument("--gameplay-prompt", required=True, help="Plain-language gameplay prompt.")
    parser.add_argument("--world-prompt", default="", help="Optional world prompt. Defaults to gameplay prompt.")
    parser.add_argument("--output-root", default="experiences", help="Parent folder for generated experiences.")
    parser.add_argument("--base-project", default="ToolboxLineGame", help="Source project architecture to copy.")
    parser.add_argument("--force", action="store_true", help="Overwrite the target folder if it already exists.")
    parser.add_argument("--skip-build", action="store_true", help="Skip `rojo build` for the generated project.")
    return parser.parse_args()


def safe_folder_name(value: str) -> str:
    cleaned = "".join(ch if ch.isalnum() or ch in {" ", "-", "_"} else " " for ch in value)
    slug = "-".join(cleaned.split())
    return slug or "PromptExperience"


def reset_output_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def copy_project_template(base_project: Path, target_project: Path) -> None:
    shutil.copytree(
        base_project,
        target_project,
        dirs_exist_ok=False,
        ignore=shutil.ignore_patterns("build", "*.rbxlx", "__pycache__", "*.pyc"),
    )


def update_project_name(project_root: Path, name: str) -> None:
    default_project_path = project_root / "default.project.json"
    payload = json.loads(default_project_path.read_text(encoding="utf-8"))
    payload["name"] = name
    default_project_path.write_text(json.dumps(payload, indent=4) + "\n", encoding="utf-8")


def write_experience_metadata(
    *,
    project_root: Path,
    display_name: str,
    gameplay_prompt: str,
    world_prompt: str,
    build_output: Path | None,
) -> None:
    metadata = {
        "name": display_name,
        "architecture": ARCHITECTURE_VERSION,
        "base_project": "ToolboxLineGame",
        "gameplay_prompt": gameplay_prompt,
        "world_prompt": world_prompt or gameplay_prompt,
        "build_output": str(build_output) if build_output else None,
    }
    (project_root / "prompt_experience.json").write_text(
        json.dumps(metadata, indent=2, ensure_ascii=True) + "\n",
        encoding="utf-8",
    )


def build_project(project_root: Path, output_name: str) -> Path:
    build_dir = project_root / "build"
    build_dir.mkdir(parents=True, exist_ok=True)
    build_output = build_dir / f"{output_name}.rbxlx"
    subprocess.run(
        ["rojo", "build", "default.project.json", "-o", str(build_output)],
        cwd=project_root,
        check=True,
    )
    return build_output


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parent.parent
    base_project = (repo_root / args.base_project).resolve()
    if not base_project.exists():
        raise SystemExit(f"Base project not found: {base_project}")

    folder_name = safe_folder_name(args.name)
    output_root = (repo_root / args.output_root).resolve()
    target_project = output_root / folder_name

    if target_project.exists():
        if not args.force:
            raise SystemExit(f"Target project already exists: {target_project}. Use --force to overwrite.")
        shutil.rmtree(target_project)

    output_root.mkdir(parents=True, exist_ok=True)
    copy_project_template(base_project, target_project)
    update_project_name(target_project, args.name)

    write_prompt_runtime_files(
        gameplay_prompt=args.gameplay_prompt,
        world_prompt=args.world_prompt or None,
        output_lua=target_project / "shared" / "PromptPipelineSpec.lua",
        output_assets_lua=target_project / "shared" / "ModularWorldAssets.lua",
        output_json=target_project / "docs" / "prompt_pipeline_runtime.json",
    )

    build_output = None
    if not args.skip_build:
        build_output = build_project(target_project, folder_name)

    write_experience_metadata(
        project_root=target_project,
        display_name=args.name,
        gameplay_prompt=args.gameplay_prompt,
        world_prompt=args.world_prompt,
        build_output=build_output,
    )

    print(
        json.dumps(
            {
                "project_root": str(target_project),
                "build_output": str(build_output) if build_output else None,
                "prompt_spec": str(target_project / "shared" / "PromptPipelineSpec.lua"),
                "modular_world_assets": str(target_project / "shared" / "ModularWorldAssets.lua"),
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
