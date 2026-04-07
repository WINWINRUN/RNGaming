import json
import subprocess
import sys
import tempfile
from pathlib import Path

from generator_terrain import build_rojo_project, populate_project


def test_generate_terrain_scaffold():
    with tempfile.TemporaryDirectory() as temp_dir:
        output_dir = Path(temp_dir) / "TerrainExperience"
        output_dir.mkdir(parents=True, exist_ok=True)
        metadata = {
            "game_name": "TerrainExperience",
            "experience_name": "TerrainPlace",
            "template": "terrain",
            "author": "Tester",
            "version": "0.1",
            "group_id": 846021713,
            "group_name": "RN_Gaming",
            "allowed_place_ids": [123456789],
            "default_profile": "TemperateFrontier",
            "default_seed": 2048,
            "architecture": "terrain-first-v1",
        }

        build_rojo_project(metadata["game_name"], output_dir)
        populate_project(output_dir, metadata)

        assert (output_dir / "default.project.json").exists()
        assert (output_dir / "server" / "MainServer.server.lua").exists()
        assert (output_dir / "server" / "TerrainBootstrap.lua").exists()
        assert (output_dir / "server" / "terrain" / "TerrainGenerator.lua").exists()
        assert (output_dir / "server" / "terrain" / "EnvironmentGenerator.lua").exists()
        assert (output_dir / "server" / "terrain" / "LightingController.lua").exists()
        assert (output_dir / "shared" / "Config.lua").exists()
        assert (output_dir / "shared" / "ExperienceGuard.lua").exists()
        assert (output_dir / "shared" / "TerrainProfiles.lua").exists()
        assert (output_dir / "studio" / "GenerateTerrain.command.lua").exists()
        assert (output_dir / "studio" / "GenerateTerrain.plugin.lua").exists()
        assert (output_dir / "terrain_profiles.json").exists()
        assert (output_dir / "INSTALL_AND_USAGE.md").exists()
        assert (output_dir / "client" / "MainClient.client.lua").exists()

        project_config = json.loads((output_dir / "default.project.json").read_text(encoding="utf-8"))
        assert project_config["tree"]["ServerScriptService"]["$path"] == "server"
        assert project_config["tree"]["ReplicatedStorage"]["$path"] == "shared"

        config_lua = (output_dir / "shared" / "Config.lua").read_text(encoding="utf-8")
        assert 'ExperienceName = "TerrainPlace"' in config_lua
        assert 'DefaultTerrainProfile = "TemperateFrontier"' in config_lua
        assert "DefaultSeed = 2048" in config_lua
        assert "ExperienceLockEnabled = true" in config_lua
        assert "AllowedPlaceIds = {" in config_lua

        profiles_manifest = json.loads((output_dir / "terrain_profiles.json").read_text(encoding="utf-8"))
        assert profiles_manifest["DefaultProfileName"] == "TemperateFrontier"
        assert "TemperateFrontier" in profiles_manifest["Profiles"]
        assert "DesertCanyon" in profiles_manifest["Profiles"]
        assert "FrozenDesertMoon" in profiles_manifest["Profiles"]
        assert "SkyArchipelago" in profiles_manifest["Profiles"]
        assert "SpaceWaterfallCliffs" in profiles_manifest["Profiles"]

        terrain_generator = (output_dir / "server" / "terrain" / "TerrainGenerator.lua").read_text(encoding="utf-8")
        assert "FillBlock" in terrain_generator
        assert "FillBall" in terrain_generator
        assert "clearManagedRegion" in terrain_generator

        terrain_bootstrap = (output_dir / "server" / "TerrainBootstrap.lua").read_text(encoding="utf-8")
        assert "ExperienceGuard" in terrain_bootstrap
        assert "assertGenerationAllowed" in terrain_bootstrap

        environment_generator = (output_dir / "server" / "terrain" / "EnvironmentGenerator.lua").read_text(encoding="utf-8")
        assert "Raycast" in environment_generator
        assert "createTree" in environment_generator

        command_helper = (output_dir / "studio" / "GenerateTerrain.command.lua").read_text(encoding="utf-8")
        assert "pcall" in command_helper
        assert "warn(result)" in command_helper


def test_generate_game_cli_and_tools():
    with tempfile.TemporaryDirectory() as temp_dir:
        repo_root = Path(__file__).resolve().parent
        output_dir = Path(temp_dir) / "SeparatedExperience"

        subprocess.run(
            [
                sys.executable,
                str(repo_root / "generate_game.py"),
                "--game-name",
                "SeparatedExperience",
                "--experience-name",
                "SeparatedPlace",
                "--template",
                "terrain",
                "--output",
                str(output_dir),
                "--author",
                "Tester",
                "--version",
                "0.2",
                "--default-profile",
                "SkyArchipelago",
                "--default-seed",
                "4096",
                "--force",
            ],
            check=True,
            cwd=repo_root,
        )

        metadata = json.loads((output_dir / "game_metadata.json").read_text(encoding="utf-8"))
        assert metadata["architecture"] == "terrain-first-v1"
        assert metadata["default_profile"] == "SkyArchipelago"
        assert metadata["default_seed"] == 4096
        assert metadata["experience_lock_enabled"] is False

        subprocess.run(
            [
                sys.executable,
                str(repo_root / "tools" / "lock_project_to_place.py"),
                "--project",
                str(output_dir),
                "--place-id",
                "111",
                "--place-id",
                "222",
            ],
            check=True,
            cwd=repo_root,
        )

        config_lua = (output_dir / "shared" / "Config.lua").read_text(encoding="utf-8")
        assert "ExperienceLockEnabled = true" in config_lua
        assert "AllowedPlaceIds = {111, 222}" in config_lua

        metadata = json.loads((output_dir / "game_metadata.json").read_text(encoding="utf-8"))
        assert metadata["experience_lock_enabled"] is True
        assert metadata["allowed_place_ids"] == [111, 222]

        subprocess.run(
            [
                sys.executable,
                str(repo_root / "tools" / "review_terrain_profiles.py"),
                "--project",
                str(output_dir),
                "--resolution",
                "48",
            ],
            check=True,
            cwd=repo_root,
        )

        subprocess.run(
            [
                sys.executable,
                str(repo_root / "tools" / "render_terrain_preview.py"),
                "--project",
                str(output_dir),
                "--resolution",
                "64",
                "--profile",
                "TemperateFrontier",
            ],
            check=True,
            cwd=repo_root,
        )

        assert (output_dir / "art" / "reviews" / "terrain" / "TemperateFrontier.png").exists()
        assert (output_dir / "art" / "reviews" / "terrain" / "TemperateFrontier.json").exists()


if __name__ == "__main__":
    test_generate_terrain_scaffold()
    test_generate_game_cli_and_tools()
    print("test_generate_game.py passed")
