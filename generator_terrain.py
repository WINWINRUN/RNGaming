import argparse
import json
import shutil
import textwrap
from pathlib import Path


PROJECT_TEMPLATES = {
    "terrain": {
        "description": "Terrain-first Roblox scaffold with procedural terrain, environment dressing, Studio helpers, and experience locks.",
        "features": [
            "procedural terrain generation",
            "environment dressing with primitive props",
            "edit-time generation helpers",
            "experience isolation",
            "preview and review tooling",
        ],
    },
    "experience": {
        "description": "Alias for the terrain-first Roblox scaffold.",
        "features": [
            "procedural terrain generation",
            "experience isolation",
        ],
    },
}

ARCHITECTURE_VERSION = "terrain-first-v1"

TERRAIN_PROFILE_MANIFEST = {
    "DefaultProfileName": "TemperateFrontier",
    "Profiles": {
        "TemperateFrontier": {
            "Name": "TemperateFrontier",
            "DisplayName": "Temperate Frontier",
            "Kind": "Heightmap",
            "WorldSize": 640,
            "CellSize": 8,
            "ManagedCenter": {"X": 0, "Y": 0, "Z": 0},
            "BaseY": -96,
            "ClearMinY": -160,
            "ClearMaxY": 260,
            "BaseHeight": 88,
            "HeightAmplitude": 74,
            "DetailAmplitude": 16,
            "RidgeAmplitude": 24,
            "TopsoilDepth": 8,
            "WaterLevel": 32,
            "SnowLine": 148,
            "Edge": {"InnerRadius": 228, "OuterRadius": 320, "Drop": 176},
            "Noise": {
                "ContinentalScale": 336,
                "ContinentalOctaves": 4,
                "DetailScale": 88,
                "DetailOctaves": 3,
                "RidgeScale": 176,
                "MoistureScale": 224,
                "Lacunarity": 2.0,
                "Persistence": 0.5,
            },
            "River": {"Enabled": True, "Scale": 156, "Width": 0.14, "Depth": 18},
            "Spawn": {
                "Height": 78,
                "InnerBlendRadius": 34,
                "FlattenRadius": 82,
            },
            "Props": {
                "ScatterStride": 20,
                "TreeDensity": 0.30,
                "BushDensity": 0.16,
                "RockDensity": 0.12,
                "LandmarkDensity": 0.02,
            },
            "Lighting": {
                "ClockTime": 14.2,
                "Brightness": 2.1,
                "ExposureCompensation": 0.04,
                "AmbientRGB": [93, 106, 124],
                "OutdoorAmbientRGB": [128, 151, 173],
                "AtmosphereColorRGB": [201, 227, 255],
                "AtmosphereDecayRGB": [107, 128, 156],
                "AtmosphereDensity": 0.32,
                "AtmosphereOffset": 0.08,
                "AtmosphereGlare": 0.1,
                "AtmosphereHaze": 1.6,
                "CloudCover": 0.34,
                "CloudDensity": 0.28,
                "CloudColorRGB": [255, 255, 255],
                "ColorCorrectionBrightness": 0.02,
                "ColorCorrectionContrast": 0.08,
                "ColorCorrectionSaturation": -0.02,
                "ColorCorrectionTintRGB": [255, 249, 245],
                "EnvironmentDiffuseScale": 0.45,
                "EnvironmentSpecularScale": 0.32,
            },
        },
        "DesertCanyon": {
            "Name": "DesertCanyon",
            "DisplayName": "Desert Canyon",
            "Kind": "Heightmap",
            "WorldSize": 704,
            "CellSize": 8,
            "ManagedCenter": {"X": 0, "Y": 0, "Z": 0},
            "BaseY": -110,
            "ClearMinY": -180,
            "ClearMaxY": 280,
            "BaseHeight": 102,
            "HeightAmplitude": 82,
            "DetailAmplitude": 22,
            "RidgeAmplitude": 34,
            "TopsoilDepth": 8,
            "WaterLevel": -72,
            "SnowLine": 999,
            "Edge": {"InnerRadius": 246, "OuterRadius": 350, "Drop": 188},
            "Noise": {
                "ContinentalScale": 292,
                "ContinentalOctaves": 4,
                "DetailScale": 78,
                "DetailOctaves": 3,
                "RidgeScale": 132,
                "MoistureScale": 260,
                "Lacunarity": 2.1,
                "Persistence": 0.47,
            },
            "River": {"Enabled": False, "Scale": 180, "Width": 0.1, "Depth": 10},
            "Spawn": {
                "Height": 90,
                "InnerBlendRadius": 38,
                "FlattenRadius": 92,
            },
            "Props": {
                "ScatterStride": 24,
                "TreeDensity": 0.02,
                "BushDensity": 0.03,
                "RockDensity": 0.2,
                "LandmarkDensity": 0.025,
            },
            "Lighting": {
                "ClockTime": 16.4,
                "Brightness": 2.2,
                "ExposureCompensation": 0.08,
                "AmbientRGB": [122, 112, 101],
                "OutdoorAmbientRGB": [168, 149, 118],
                "AtmosphereColorRGB": [255, 225, 185],
                "AtmosphereDecayRGB": [184, 132, 87],
                "AtmosphereDensity": 0.38,
                "AtmosphereOffset": 0.06,
                "AtmosphereGlare": 0.16,
                "AtmosphereHaze": 1.9,
                "CloudCover": 0.14,
                "CloudDensity": 0.16,
                "CloudColorRGB": [255, 236, 214],
                "ColorCorrectionBrightness": 0.01,
                "ColorCorrectionContrast": 0.14,
                "ColorCorrectionSaturation": -0.05,
                "ColorCorrectionTintRGB": [255, 240, 223],
                "EnvironmentDiffuseScale": 0.42,
                "EnvironmentSpecularScale": 0.36,
            },
        },
        "FrozenDesertMoon": {
            "Name": "FrozenDesertMoon",
            "DisplayName": "Frozen Desert Moon",
            "Kind": "Heightmap",
            "WorldSize": 736,
            "CellSize": 8,
            "ManagedCenter": {"X": 0, "Y": 0, "Z": 0},
            "BaseY": -124,
            "ClearMinY": -200,
            "ClearMaxY": 360,
            "BaseHeight": 108,
            "HeightAmplitude": 66,
            "DetailAmplitude": 24,
            "RidgeAmplitude": 22,
            "TopsoilDepth": 10,
            "WaterLevel": -140,
            "SnowLine": 999,
            "Edge": {"InnerRadius": 254, "OuterRadius": 368, "Drop": 174},
            "Noise": {
                "ContinentalScale": 304,
                "ContinentalOctaves": 4,
                "DetailScale": 92,
                "DetailOctaves": 3,
                "RidgeScale": 148,
                "MoistureScale": 236,
                "Lacunarity": 2.0,
                "Persistence": 0.48,
            },
            "River": {"Enabled": False, "Scale": 220, "Width": 0.08, "Depth": 8},
            "Spawn": {
                "Height": 112,
                "InnerBlendRadius": 40,
                "FlattenRadius": 96,
            },
            "Props": {
                "ScatterStride": 22,
                "TreeDensity": 0.0,
                "BushDensity": 0.1,
                "RockDensity": 0.22,
                "LandmarkDensity": 0.03,
            },
            "Moon": {
                "Enabled": True,
                "Radius": 58,
                "Distance": 460,
                "Height": 312,
                "CoreColorRGB": [232, 241, 255],
                "HaloColorRGB": [160, 196, 255],
            },
            "Stars": {
                "Count": 120,
                "Radius": 560,
                "MinY": 238,
                "MaxY": 420,
            },
            "Lighting": {
                "ClockTime": 1.8,
                "Brightness": 1.42,
                "ExposureCompensation": -0.08,
                "AmbientRGB": [32, 40, 62],
                "OutdoorAmbientRGB": [49, 62, 93],
                "AtmosphereColorRGB": [120, 144, 198],
                "AtmosphereDecayRGB": [24, 29, 49],
                "AtmosphereDensity": 0.1,
                "AtmosphereOffset": 0.02,
                "AtmosphereGlare": 0.02,
                "AtmosphereHaze": 0.54,
                "CloudCover": 0.05,
                "CloudDensity": 0.08,
                "CloudColorRGB": [214, 225, 255],
                "ColorCorrectionBrightness": -0.04,
                "ColorCorrectionContrast": 0.2,
                "ColorCorrectionSaturation": -0.09,
                "ColorCorrectionTintRGB": [214, 226, 255],
                "EnvironmentDiffuseScale": 0.24,
                "EnvironmentSpecularScale": 0.38,
            },
        },
        "SkyArchipelago": {
            "Name": "SkyArchipelago",
            "DisplayName": "Sky Archipelago",
            "Kind": "SkyIslands",
            "WorldSize": 720,
            "CellSize": 8,
            "ManagedCenter": {"X": 0, "Y": 0, "Z": 0},
            "BaseY": 20,
            "ClearMinY": -40,
            "ClearMaxY": 360,
            "BaseHeight": 174,
            "WaterLevel": -1000,
            "TopsoilDepth": 12,
            "IslandCount": 7,
            "RingRadius": 186,
            "RingJitter": 52,
            "IslandRadius": 56,
            "IslandRadiusJitter": 18,
            "IslandDepth": 82,
            "AltitudeJitter": 32,
            "TopThickness": 18,
            "TopBulge": 10,
            "Spawn": {
                "Height": 180,
                "InnerBlendRadius": 28,
                "FlattenRadius": 64,
            },
            "Props": {
                "ScatterStride": 18,
                "TreeDensity": 0.15,
                "BushDensity": 0.08,
                "RockDensity": 0.1,
                "LandmarkDensity": 0.025,
            },
            "Lighting": {
                "ClockTime": 11.4,
                "Brightness": 2.3,
                "ExposureCompensation": 0.06,
                "AmbientRGB": [104, 120, 139],
                "OutdoorAmbientRGB": [140, 170, 194],
                "AtmosphereColorRGB": [214, 238, 255],
                "AtmosphereDecayRGB": [138, 164, 193],
                "AtmosphereDensity": 0.24,
                "AtmosphereOffset": 0.12,
                "AtmosphereGlare": 0.08,
                "AtmosphereHaze": 1.2,
                "CloudCover": 0.58,
                "CloudDensity": 0.38,
                "CloudColorRGB": [255, 255, 255],
                "ColorCorrectionBrightness": 0.03,
                "ColorCorrectionContrast": 0.06,
                "ColorCorrectionSaturation": 0.01,
                "ColorCorrectionTintRGB": [247, 250, 255],
                "EnvironmentDiffuseScale": 0.48,
                "EnvironmentSpecularScale": 0.34,
            },
        },
        "SpaceWaterfallCliffs": {
            "Name": "SpaceWaterfallCliffs",
            "DisplayName": "Space Waterfall Cliffs",
            "Kind": "SkyIslands",
            "WorldSize": 760,
            "CellSize": 8,
            "ManagedCenter": {"X": 0, "Y": 0, "Z": 0},
            "BaseY": -120,
            "ClearMinY": -220,
            "ClearMaxY": 420,
            "BaseHeight": 224,
            "PrimaryIslandRadius": 118,
            "PrimaryIslandAltitude": 232,
            "WaterLevel": -1000,
            "TopsoilDepth": 12,
            "IslandCount": 6,
            "RingRadius": 254,
            "RingJitter": 34,
            "IslandRadius": 46,
            "IslandRadiusJitter": 12,
            "IslandDepth": 148,
            "AltitudeJitter": 20,
            "TopThickness": 26,
            "TopBulge": 16,
            "Spawn": {
                "Height": 236,
                "InnerBlendRadius": 30,
                "FlattenRadius": 72,
            },
            "Props": {
                "ScatterStride": 20,
                "TreeDensity": 0.0,
                "BushDensity": 0.0,
                "RockDensity": 0.2,
                "LandmarkDensity": 0.04,
            },
            "Waterfall": {
                "Enabled": True,
                "EdgeOffset": 78,
                "Height": 152,
                "Width": 22,
                "Thickness": 5,
                "MistRadius": 18,
            },
            "Stars": {
                "Count": 96,
                "Radius": 520,
                "MinY": 240,
                "MaxY": 420,
            },
            "Lighting": {
                "ClockTime": 2.4,
                "Brightness": 1.75,
                "ExposureCompensation": -0.05,
                "AmbientRGB": [36, 44, 70],
                "OutdoorAmbientRGB": [52, 67, 101],
                "AtmosphereColorRGB": [99, 131, 188],
                "AtmosphereDecayRGB": [21, 28, 53],
                "AtmosphereDensity": 0.08,
                "AtmosphereOffset": 0.02,
                "AtmosphereGlare": 0.01,
                "AtmosphereHaze": 0.45,
                "CloudCover": 0.02,
                "CloudDensity": 0.05,
                "CloudColorRGB": [215, 228, 255],
                "ColorCorrectionBrightness": -0.03,
                "ColorCorrectionContrast": 0.18,
                "ColorCorrectionSaturation": -0.08,
                "ColorCorrectionTintRGB": [212, 226, 255],
                "EnvironmentDiffuseScale": 0.22,
                "EnvironmentSpecularScale": 0.4,
            },
        },
    },
}

ROOT_README = textwrap.dedent(
    """
    # RNGaming

    RNGaming is now a terrain-first Roblox scaffold generator.

    The repo builds isolated Rojo projects that focus on procedural terrain, environment dressing, safe edit-time generation, and preview tooling. The idea is that you can generate and review a world foundation first, then layer your game mode skeletons on top later.

    ## What the scaffold gives you

    - `server/terrain/` modules for deterministic terrain generation and environment dressing
    - `shared/TerrainProfiles.lua` for profile-driven world presets
    - `shared/ExperienceGuard.lua` for place locking and experience isolation
    - `studio/GenerateTerrain.command.lua` and `studio/GenerateTerrain.plugin.lua` for edit-time generation
    - `tools/review_terrain_profiles.py` for machine checks on terrain profile ranges
    - `tools/render_terrain_preview.py` for visual previews generated from the same seeded noise stack

    ## Quickstart

    ```powershell
    python generate_game.py --game-name "MyTerrainExperience" --template terrain --output ".\\MyTerrainExperience" --author "Mikey" --version "0.1" --force
    ```

    Then sync it with Rojo:

    ```powershell
    cd ".\\MyTerrainExperience"
    rojo serve default.project.json
    ```

    ## Terrain workflow

    1. Connect the generated project to Studio with Rojo.
    2. Use the command bar helper or plugin helper to generate terrain in the managed region.
    3. Review the preview images and profile warnings locally.
    4. Save and publish the place once you like the result.
    """
).strip() + "\n"

ROOT_STUDIO_SETUP = textwrap.dedent(
    """
    # Studio Setup

    This repo now targets a terrain-first Roblox workflow.

    ## Install and sync

    1. Install the Rojo CLI and the Rojo Studio plugin.
    2. Generate or open a project folder such as `MyTycoonGame`.
    3. Start Rojo from that folder:

    ```powershell
    rojo serve default.project.json
    ```

    4. Open Roblox Studio.
    5. Open the Rojo plugin and connect to the local server.

    ## What syncs where

    - `shared/` -> `ReplicatedStorage`
    - `server/` -> `ServerScriptService`
    - `client/` -> `StarterPlayer/StarterPlayerScripts`

    The terrain generator itself writes into `Workspace.Terrain`, `Workspace/GeneratedEnvironment`, and `Workspace/GeneratedSpawn`.
    """
).strip() + "\n"

CHANGELOG_TEXT = textwrap.dedent(
    """
    # Changelog

    ## 2026-03-30

    - Rebuilt the repo from a model-first scaffold into a terrain-first Roblox generator.
    - Added deterministic terrain profiles for `TemperateFrontier`, `DesertCanyon`, and `SkyArchipelago`.
    - Added Studio helpers for edit-time terrain generation and safe managed-region clearing.
    - Added terrain review and preview tooling driven by the same profile manifest.
    - Kept experience isolation through project-folder separation and `AllowedPlaceIds`.
    """
).strip() + "\n"

PROJECT_README = textwrap.dedent(
    """
    # __GAME_NAME__

    __GAME_NAME__ is a terrain-first Roblox experience scaffold generated by RNGaming.

    It focuses on terrain generation, environment dressing, and place isolation. Game mode skeletons are intentionally left out so you can add them later without fighting auto-generated gameplay code.

    ## Included terrain profiles

    - `TemperateFrontier`
    - `DesertCanyon`
    - `FrozenDesertMoon`
    - `SkyArchipelago`
    - `SpaceWaterfallCliffs`

    ## Core folders

    - `server/terrain/` contains terrain, environment, lighting, spawn, and diagnostics modules
    - `shared/` contains config, terrain profiles, and experience guard logic
    - `studio/` contains edit-time helpers for Studio command bar or plugin use
    - `art/reviews/terrain/` stores preview renders generated by the Python tooling
    """
).strip() + "\n"

PROJECT_INSTALL_AND_USAGE = textwrap.dedent(
    """
    # __GAME_NAME__ Install And Usage

    __GAME_NAME__ uses a terrain-first architecture:

    - terrain is generated by code rather than synced model assets
    - the generator writes into a managed region instead of clearing the entire place
    - environment props are built from primitive parts with no embedded scripts
    - terrain profile previews are generated locally with Python tooling

    ## Install

    1. Install Rojo and the Rojo Studio plugin.
    2. Open this project folder in your editor.
    3. Start Rojo from the project root:

    ```powershell
    rojo serve --project default.project.json
    ```

    4. Open Roblox Studio and connect with the Rojo plugin.

    ## Generate terrain in Studio

    Recommended edit-time flow:

    1. Open `View > Command Bar`.
    2. Paste `studio/GenerateTerrain.command.lua`.
    3. Press Enter.
    4. Review the generated world in Studio and save the place when you are happy with it.

    You can also install `studio/GenerateTerrain.plugin.lua` as a local Studio plugin and use its toolbar buttons for generate, regenerate, and clear.

    ## Runtime flow

    `server/MainServer.lua` loads `server/TerrainBootstrap.lua`.

    By default:

    - `AutoGenerateOnServerStart = false`
    - place locks are respected
    - generation only clears the managed region for the active profile

    If you want runtime generation, set `AutoGenerateOnServerStart = true` in `shared/Config.lua`.

    ## Experience separation

    - keep one generated project folder per Roblox experience or place workflow
    - use `tools/lock_project_to_place.py` to lock a project to one or more place IDs
    - `shared/Config.lua` contains `ExperienceLockEnabled` and `AllowedPlaceIds`

    ## Review the terrain before using it

    ```powershell
    python tools\\review_terrain_profiles.py --project ".\\__PROJECT_FOLDER_NAME__"
    python tools\\render_terrain_preview.py --project ".\\__PROJECT_FOLDER_NAME__"
    ```

    Preview images are written to `art/reviews/terrain/`.
    If preview rendering says Pillow is missing, install it with `python -m pip install pillow`.

    ## Working with profiles

    - change the default profile in `shared/Config.lua`
    - tune generation settings in `shared/TerrainProfiles.lua`
    - keep `terrain_profiles.json` in sync by regenerating the project from the repo root
    """
).strip() + "\n"

ART_REVIEW_README = textwrap.dedent(
    """
    # Terrain Review Outputs

    This folder is for generated terrain review images.
    """
).strip() + "\n"

TEXT_FILES: dict[str, str] = {}


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=4), encoding="utf-8")


def lua_value(value, indent: int = 0) -> str:
    indent_str = "    " * indent
    next_indent_str = "    " * (indent + 1)

    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "nil"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, list):
        if not value:
            return "{}"
        items = [f"{next_indent_str}{lua_value(item, indent + 1)}" for item in value]
        return "{\n" + ",\n".join(items) + f"\n{indent_str}" + "}"
    if isinstance(value, dict):
        if not value:
            return "{}"
        items = []
        for key, item in value.items():
            key_prefix = key if key.isidentifier() else f"[{json.dumps(key)}]"
            items.append(f"{next_indent_str}{key_prefix} = {lua_value(item, indent + 1)}")
        return "{\n" + ",\n".join(items) + f"\n{indent_str}" + "}"
    raise TypeError(f"Unsupported Lua value: {type(value)!r}")


def make_rojo_project(game_name: str) -> dict:
    return {
        "name": game_name,
        "tree": {
            "$className": "DataModel",
            "ReplicatedStorage": {"$className": "ReplicatedStorage", "$path": "shared"},
            "ServerScriptService": {"$className": "ServerScriptService", "$path": "server"},
            "StarterPlayer": {
                "$className": "StarterPlayer",
                "StarterPlayerScripts": {
                    "$className": "StarterPlayerScripts",
                    "$path": "client",
                },
            },
        },
    }


def build_rojo_project(game_name: str, output_dir: Path) -> None:
    write_json(output_dir / "default.project.json", make_rojo_project(game_name))


def render_config_lua(metadata: dict) -> str:
    template = textwrap.dedent(
        """
        return {
            GameName = __GAME_NAME__,
            ExperienceName = __EXPERIENCE_NAME__,
            Architecture = __ARCHITECTURE__,
            Author = __AUTHOR__,
            Version = __VERSION__,
            GroupId = __GROUP_ID__,
            GroupName = __GROUP_NAME__,
            ExperienceLockEnabled = __EXPERIENCE_LOCK_ENABLED__,
            AllowedPlaceIds = __ALLOWED_PLACE_IDS__,
            AutoGenerateOnServerStart = false,
            DefaultTerrainProfile = __DEFAULT_PROFILE__,
            DefaultSeed = __DEFAULT_SEED__,
            ClearManagedRegionBeforeGenerate = true,
            GeneratedEnvironmentFolderName = "GeneratedEnvironment",
        }
        """
    ).strip()
    return (
        template.replace("__GAME_NAME__", json.dumps(metadata["game_name"]))
        .replace("__EXPERIENCE_NAME__", json.dumps(metadata["experience_name"]))
        .replace("__ARCHITECTURE__", json.dumps(ARCHITECTURE_VERSION))
        .replace("__AUTHOR__", json.dumps(metadata["author"]))
        .replace("__VERSION__", json.dumps(metadata["version"]))
        .replace("__GROUP_ID__", "nil" if metadata["group_id"] is None else str(metadata["group_id"]))
        .replace("__GROUP_NAME__", "nil" if not metadata["group_name"] else json.dumps(metadata["group_name"]))
        .replace("__EXPERIENCE_LOCK_ENABLED__", "true" if metadata["allowed_place_ids"] else "false")
        .replace("__ALLOWED_PLACE_IDS__", lua_value(metadata["allowed_place_ids"]))
        .replace("__DEFAULT_PROFILE__", json.dumps(metadata["default_profile"]))
        .replace("__DEFAULT_SEED__", str(metadata["default_seed"]))
        + "\n"
    )


def render_experience_guard_lua() -> str:
    return (
        textwrap.dedent(
            """
            local ExperienceGuard = {}

            function ExperienceGuard.canRunHere(config)
                if not config.ExperienceLockEnabled then
                    return true
                end

                for _, placeId in ipairs(config.AllowedPlaceIds) do
                    if game.PlaceId == placeId then
                        return true
                    end
                end

                return false
            end

            return ExperienceGuard
            """
        ).strip()
        + "\n"
    )


def render_terrain_profiles_lua() -> str:
    profiles_lua = lua_value(TERRAIN_PROFILE_MANIFEST)
    return (
        textwrap.dedent(
            """
            local TerrainProfiles = __PROFILES__

            local function deepCopy(value)
                if type(value) ~= "table" then
                    return value
                end

                local copy = {}
                for key, item in pairs(value) do
                    copy[key] = deepCopy(item)
                end
                return copy
            end

            function TerrainProfiles.getProfile(profileName)
                local resolvedName = profileName or TerrainProfiles.DefaultProfileName
                local profile = TerrainProfiles.Profiles[resolvedName]
                assert(profile, string.format("Unknown terrain profile '%s'", tostring(resolvedName)))
                return deepCopy(profile)
            end

            return TerrainProfiles
            """
        ).strip().replace("__PROFILES__", profiles_lua)
        + "\n"
    )


def reset_output_dir(output_dir: Path) -> None:
    if output_dir.exists():
        for child in output_dir.iterdir():
            if child.is_dir():
                shutil.rmtree(child)
            else:
                child.unlink()
    else:
        output_dir.mkdir(parents=True, exist_ok=True)


TEXT_FILES.update(
    {
        "server/MainServer.lua": textwrap.dedent(
            """
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local ServerScriptService = game:GetService("ServerScriptService")

            local Config = require(ReplicatedStorage:WaitForChild("Config"))
            local ExperienceGuard = require(ReplicatedStorage:WaitForChild("ExperienceGuard"))
            local TerrainBootstrap = require(ServerScriptService:WaitForChild("TerrainBootstrap"))

            if not ExperienceGuard.canRunHere(Config) then
                warn("[RNGaming] Terrain generation skipped because this place is not allowed by Config.lua")
                return
            end

            local ok, result = pcall(function()
                return TerrainBootstrap.start()
            end)

            if not ok then
                warn("[RNGaming] Terrain bootstrap failed:", result)
                return
            end

            if result then
                print(string.format("[RNGaming] Terrain ready with profile %s and seed %s", result.ProfileName, tostring(result.Seed)))
            else
                print("[RNGaming] Terrain scaffold loaded. AutoGenerateOnServerStart is disabled.")
            end
            """
        ).strip()
        + "\n",
        "server/TerrainBootstrap.lua": textwrap.dedent(
            """
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local ServerScriptService = game:GetService("ServerScriptService")

            local Config = require(ReplicatedStorage:WaitForChild("Config"))
            local ExperienceGuard = require(ReplicatedStorage:WaitForChild("ExperienceGuard"))
            local TerrainProfiles = require(ReplicatedStorage:WaitForChild("TerrainProfiles"))

            local terrainFolder = ServerScriptService:WaitForChild("terrain")
            local TerrainGenerator = require(terrainFolder:WaitForChild("TerrainGenerator"))
            local EnvironmentGenerator = require(terrainFolder:WaitForChild("EnvironmentGenerator"))
            local LightingController = require(terrainFolder:WaitForChild("LightingController"))
            local SpawnPlanner = require(terrainFolder:WaitForChild("SpawnPlanner"))
            local TerrainDiagnostics = require(terrainFolder:WaitForChild("TerrainDiagnostics"))

            local TerrainBootstrap = {}

            local function resolveProfile(profileName)
                local profile = TerrainProfiles.getProfile(profileName or Config.DefaultTerrainProfile)
                profile.Name = profile.Name or profileName or Config.DefaultTerrainProfile
                return profile
            end

            local function resolveSeed(seed)
                if seed == nil then
                    return Config.DefaultSeed
                end

                return seed
            end

            local function assertGenerationAllowed(modeLabel)
                if ExperienceGuard.canRunHere(Config) then
                    return
                end

                error(string.format(
                    "[RNGaming] %s terrain generation is blocked because this project is locked to a different place. Update AllowedPlaceIds in Config.lua or lock the project to the correct PlaceId.",
                    tostring(modeLabel)
                ))
            end

            function TerrainBootstrap.generate(profileName, seed, options)
                local profile = resolveProfile(profileName)
                local resolvedSeed = resolveSeed(seed)
                local generationOptions = options or {}
                local modeLabel = generationOptions.Mode or "Unknown"

                assertGenerationAllowed(modeLabel)

                local terrainSummary = TerrainGenerator.generate(profile, resolvedSeed, Config, generationOptions)
                local environmentSummary = EnvironmentGenerator.generate(profile, resolvedSeed, Config, generationOptions)
                LightingController.apply(profile)
                local spawn = SpawnPlanner.place(profile)
                local summary = {
                    ProfileName = profile.Name,
                    Seed = resolvedSeed,
                    ColumnCount = terrainSummary.ColumnCount or 0,
                    IslandCount = terrainSummary.IslandCount or 0,
                    MinimumHeight = terrainSummary.MinimumHeight,
                    MaximumHeight = terrainSummary.MaximumHeight,
                    WaterCoverage = terrainSummary.WaterCoverage or 0,
                    PropCount = environmentSummary.PropCount or 0,
                    SpawnHeight = spawn and spawn.Position.Y or nil,
                }

                TerrainDiagnostics.publish(summary)
                return summary
            end

            function TerrainBootstrap.clearManagedRegion(profileName)
                assertGenerationAllowed("Studio")
                local profile = resolveProfile(profileName)
                TerrainGenerator.clearManagedRegion(profile, Config)
                TerrainDiagnostics.clear()
            end

            function TerrainBootstrap.start()
                if not Config.AutoGenerateOnServerStart then
                    return nil
                end

                return TerrainBootstrap.generate(Config.DefaultTerrainProfile, Config.DefaultSeed, {
                    Mode = "ServerStart",
                })
            end

            function TerrainBootstrap.generateInStudio(profileName, seed)
                return TerrainBootstrap.generate(profileName, seed, {
                    Mode = "Studio",
                })
            end

            return TerrainBootstrap
            """
        ).strip()
        + "\n",
        "server/terrain/Noise.lua": textwrap.dedent(
            """
            local bit32 = bit32

            local Noise = {}

            function Noise.clamp(value, minValue, maxValue)
                if value < minValue then
                    return minValue
                end

                if value > maxValue then
                    return maxValue
                end

                return value
            end

            function Noise.lerp(a, b, t)
                return a + (b - a) * t
            end

            function Noise.smoothstep(edge0, edge1, value)
                if edge0 == edge1 then
                    return value >= edge1 and 1 or 0
                end

                local alpha = Noise.clamp((value - edge0) / (edge1 - edge0), 0, 1)
                return alpha * alpha * (3 - 2 * alpha)
            end

            function Noise.hash2D(xi, zi, seed)
                local value = bit32.band(xi * 374761393 + zi * 668265263 + seed * 1442695041, 0xFFFFFFFF)
                value = bit32.bxor(value, bit32.rshift(value, 13))
                value = bit32.band(value * 1274126177, 0xFFFFFFFF)
                value = bit32.bxor(value, bit32.rshift(value, 16))
                return (value % 100000) / 50000 - 1
            end

            function Noise.hash01(xi, zi, seed)
                return (Noise.hash2D(xi, zi, seed) + 1) * 0.5
            end

            function Noise.value2D(x, z, scale, seed)
                local fx = x / scale
                local fz = z / scale

                local x0 = math.floor(fx)
                local z0 = math.floor(fz)
                local tx = fx - x0
                local tz = fz - z0
                local x1 = x0 + 1
                local z1 = z0 + 1
                local sx = tx * tx * (3 - 2 * tx)
                local sz = tz * tz * (3 - 2 * tz)

                local v00 = Noise.hash2D(x0, z0, seed)
                local v10 = Noise.hash2D(x1, z0, seed)
                local v01 = Noise.hash2D(x0, z1, seed)
                local v11 = Noise.hash2D(x1, z1, seed)

                local row0 = Noise.lerp(v00, v10, sx)
                local row1 = Noise.lerp(v01, v11, sx)

                return Noise.lerp(row0, row1, sz)
            end

            function Noise.fractal2D(x, z, scale, octaves, lacunarity, persistence, seed)
                local total = 0
                local amplitude = 1
                local amplitudeSum = 0
                local currentScale = scale

                for octave = 0, octaves - 1 do
                    total = total + Noise.value2D(x, z, currentScale, seed + octave * 131) * amplitude
                    amplitudeSum = amplitudeSum + amplitude
                    amplitude = amplitude * persistence
                    currentScale = currentScale / lacunarity
                end

                if amplitudeSum == 0 then
                    return 0
                end

                return total / amplitudeSum
            end

            function Noise.ridge2D(x, z, scale, octaves, lacunarity, persistence, seed)
                local value = math.abs(Noise.fractal2D(x, z, scale, octaves, lacunarity, persistence, seed))
                return 1 - value
            end

            return Noise
            """
        ).strip()
        + "\n",
        "server/terrain/BiomeLibrary.lua": textwrap.dedent(
            """
            local BiomeLibrary = {}

            local BIOMES = {
                TemperateFrontier = {
                    Shore = {Name = "Shore", SurfaceMaterial = Enum.Material.Sand, BodyMaterial = Enum.Material.Ground, PropStyle = "Shore"},
                    Meadow = {Name = "Meadow", SurfaceMaterial = Enum.Material.Grass, BodyMaterial = Enum.Material.Ground, PropStyle = "Meadow"},
                    Forest = {Name = "Forest", SurfaceMaterial = Enum.Material.LeafyGrass, BodyMaterial = Enum.Material.Ground, PropStyle = "Forest"},
                    Cliff = {Name = "Cliff", SurfaceMaterial = Enum.Material.Rock, BodyMaterial = Enum.Material.Slate, PropStyle = "Cliff"},
                    Alpine = {Name = "Alpine", SurfaceMaterial = Enum.Material.Snow, BodyMaterial = Enum.Material.Rock, PropStyle = "Alpine"},
                },
                DesertCanyon = {
                    Shore = {Name = "Shore", SurfaceMaterial = Enum.Material.Sand, BodyMaterial = Enum.Material.Sandstone, PropStyle = "Desert"},
                    Dunes = {Name = "Dunes", SurfaceMaterial = Enum.Material.Sand, BodyMaterial = Enum.Material.Sandstone, PropStyle = "Desert"},
                    Mesa = {Name = "Mesa", SurfaceMaterial = Enum.Material.CrackedLava, BodyMaterial = Enum.Material.Sandstone, PropStyle = "Mesa"},
                    Cliff = {Name = "Cliff", SurfaceMaterial = Enum.Material.Rock, BodyMaterial = Enum.Material.Slate, PropStyle = "Cliff"},
                },
                FrozenDesertMoon = {
                    Shore = {Name = "Shore", SurfaceMaterial = Enum.Material.Glacier, BodyMaterial = Enum.Material.Sandstone, PropStyle = "FrozenDesert"},
                    Dunes = {Name = "Dunes", SurfaceMaterial = Enum.Material.Glacier, BodyMaterial = Enum.Material.Sandstone, PropStyle = "FrozenDesert"},
                    Mesa = {Name = "Mesa", SurfaceMaterial = Enum.Material.Snow, BodyMaterial = Enum.Material.Sandstone, PropStyle = "FrozenDesert"},
                    Cliff = {Name = "Cliff", SurfaceMaterial = Enum.Material.Rock, BodyMaterial = Enum.Material.Slate, PropStyle = "Cliff"},
                },
                SkyArchipelago = {
                    Meadow = {Name = "Meadow", SurfaceMaterial = Enum.Material.Grass, BodyMaterial = Enum.Material.Ground, PropStyle = "SkyMeadow"},
                    Grove = {Name = "Grove", SurfaceMaterial = Enum.Material.LeafyGrass, BodyMaterial = Enum.Material.Ground, PropStyle = "SkyGrove"},
                    Cliff = {Name = "Cliff", SurfaceMaterial = Enum.Material.Rock, BodyMaterial = Enum.Material.Slate, PropStyle = "Cliff"},
                    Summit = {Name = "Summit", SurfaceMaterial = Enum.Material.Snow, BodyMaterial = Enum.Material.Rock, PropStyle = "Alpine"},
                },
            }

            function BiomeLibrary.resolveBiome(profile, column)
                local profileBiomes = BIOMES[profile.Name]
                if not profileBiomes then
                    return {Name = "Default", SurfaceMaterial = Enum.Material.Grass, BodyMaterial = Enum.Material.Ground, PropStyle = "Meadow"}
                end

                if profile.Kind == "SkyIslands" then
                    if column.slope >= 1.15 then
                        return profileBiomes.Cliff
                    end
                    if column.height >= profile.Spawn.Height + 26 then
                        return profileBiomes.Summit
                    end
                    if column.moisture >= 0.58 then
                        return profileBiomes.Grove
                    end
                    return profileBiomes.Meadow
                end

                if column.height <= profile.WaterLevel + 6 then
                    return profileBiomes.Shore
                end
                if column.slope >= 1.1 then
                    return profileBiomes.Cliff
                end
                if profile.Name == "DesertCanyon" or profile.Name == "FrozenDesertMoon" then
                    if column.height >= profile.Spawn.Height + 34 then
                        return profileBiomes.Mesa
                    end
                    return profileBiomes.Dunes
                end
                if column.height >= profile.SnowLine then
                    return profileBiomes.Alpine
                end
                if column.moisture >= 0.58 then
                    return profileBiomes.Forest
                end
                return profileBiomes.Meadow
            end

            return BiomeLibrary
            """
        ).strip()
        + "\n",
    }
)

TEXT_FILES.update(
    {
        "server/terrain/TerrainGenerator.lua": textwrap.dedent(
            """
            local Workspace = game:GetService("Workspace")
            local Terrain = Workspace.Terrain

            local Noise = require(script.Parent.Noise)
            local BiomeLibrary = require(script.Parent.BiomeLibrary)

            local TerrainGenerator = {}

            local function getManagedCenter(profile)
                local center = profile.ManagedCenter
                return Vector3.new(center.X, center.Y, center.Z)
            end

            local function getManagedClearCenter(profile)
                local center = getManagedCenter(profile)
                local y = profile.ClearMinY + (profile.ClearMaxY - profile.ClearMinY) * 0.5
                return Vector3.new(center.X, y, center.Z)
            end

            local function createColumnSummary()
                return {
                    ColumnCount = 0,
                    WaterColumns = 0,
                    MinimumHeight = math.huge,
                    MaximumHeight = -math.huge,
                }
            end

            local function updateColumnSummary(summary, height, waterLevel)
                summary.ColumnCount = summary.ColumnCount + 1
                summary.MinimumHeight = math.min(summary.MinimumHeight, height)
                summary.MaximumHeight = math.max(summary.MaximumHeight, height)
                if height < waterLevel then
                    summary.WaterColumns = summary.WaterColumns + 1
                end
            end

            local function clearGeneratedFolder(folderName)
                local existing = Workspace:FindFirstChild(folderName)
                if existing then
                    existing:Destroy()
                end
            end

            function TerrainGenerator.clearManagedRegion(profile, config)
                local clearCenter = getManagedClearCenter(profile)
                local size = Vector3.new(profile.WorldSize, profile.ClearMaxY - profile.ClearMinY, profile.WorldSize)

                Terrain:FillBlock(CFrame.new(clearCenter), size, Enum.Material.Air)
                clearGeneratedFolder(config.GeneratedEnvironmentFolderName)

                local spawn = Workspace:FindFirstChild("GeneratedSpawn")
                if spawn then
                    spawn:Destroy()
                end
            end

            local function buildHeightmapColumns(profile, seed)
                local cellSize = profile.CellSize
                local cellCount = math.floor(profile.WorldSize / cellSize)
                local halfSize = profile.WorldSize * 0.5
                local center = getManagedCenter(profile)
                local columns = {}
                local summary = createColumnSummary()

                for ix = 1, cellCount do
                    columns[ix] = {}
                    local worldX = center.X - halfSize + (ix - 0.5) * cellSize

                    for iz = 1, cellCount do
                        local worldZ = center.Z - halfSize + (iz - 0.5) * cellSize
                        local dx = worldX - center.X
                        local dz = worldZ - center.Z
                        local distance = math.sqrt(dx * dx + dz * dz)

                        local continental = Noise.fractal2D(
                            worldX,
                            worldZ,
                            profile.Noise.ContinentalScale,
                            profile.Noise.ContinentalOctaves,
                            profile.Noise.Lacunarity,
                            profile.Noise.Persistence,
                            seed + 11
                        )
                        local detail = Noise.fractal2D(
                            worldX,
                            worldZ,
                            profile.Noise.DetailScale,
                            profile.Noise.DetailOctaves,
                            profile.Noise.Lacunarity,
                            profile.Noise.Persistence,
                            seed + 173
                        )
                        local ridge = Noise.ridge2D(
                            worldX,
                            worldZ,
                            profile.Noise.RidgeScale,
                            3,
                            profile.Noise.Lacunarity,
                            profile.Noise.Persistence,
                            seed + 307
                        )
                        local moisture = (Noise.fractal2D(
                            worldX,
                            worldZ,
                            profile.Noise.MoistureScale,
                            3,
                            profile.Noise.Lacunarity,
                            profile.Noise.Persistence,
                            seed + 419
                        ) + 1) * 0.5

                        local height = profile.BaseHeight
                            + continental * profile.HeightAmplitude
                            + detail * profile.DetailAmplitude
                            + ridge * profile.RidgeAmplitude

                        if profile.River.Enabled then
                            local riverNoise = math.abs(Noise.fractal2D(
                                worldX,
                                worldZ,
                                profile.River.Scale,
                                2,
                                2,
                                0.5,
                                seed + 557
                            ))
                            if riverNoise < profile.River.Width then
                                local riverAlpha = 1 - riverNoise / profile.River.Width
                                height = height - riverAlpha * profile.River.Depth
                            end
                        end

                        local edgeAlpha = Noise.smoothstep(profile.Edge.InnerRadius, profile.Edge.OuterRadius, distance)
                        height = height - edgeAlpha * profile.Edge.Drop

                        local spawnAlpha = Noise.smoothstep(
                            profile.Spawn.InnerBlendRadius,
                            profile.Spawn.FlattenRadius,
                            distance
                        )
                        if distance < profile.Spawn.FlattenRadius then
                            height = Noise.lerp(profile.Spawn.Height, height, spawnAlpha)
                        end

                        height = math.max(height, profile.BaseY + cellSize)

                        columns[ix][iz] = {
                            x = worldX,
                            z = worldZ,
                            height = height,
                            moisture = moisture,
                            slope = 0,
                            biome = nil,
                        }
                        updateColumnSummary(summary, height, profile.WaterLevel)
                    end

                    if ix % 12 == 0 then
                        task.wait()
                    end
                end

                for ix = 1, cellCount do
                    for iz = 1, cellCount do
                        local left = columns[math.max(ix - 1, 1)][iz].height
                        local right = columns[math.min(ix + 1, cellCount)][iz].height
                        local up = columns[ix][math.max(iz - 1, 1)].height
                        local down = columns[ix][math.min(iz + 1, cellCount)].height
                        local slope = math.max(math.abs(left - right), math.abs(up - down)) / cellSize
                        local column = columns[ix][iz]
                        column.slope = slope
                        column.biome = BiomeLibrary.resolveBiome(profile, column)
                    end
                end

                if summary.ColumnCount > 0 then
                    summary.WaterCoverage = summary.WaterColumns / summary.ColumnCount
                else
                    summary.WaterCoverage = 0
                end

                return columns, summary
            end

            local function fillColumn(profile, column)
                local cellSize = profile.CellSize
                local baseY = profile.BaseY
                local bodyTop = math.max(baseY + cellSize, column.height - profile.TopsoilDepth)
                local bodyHeight = bodyTop - baseY
                local topHeight = math.max(cellSize, column.height - bodyTop)
                local biome = column.biome

                if bodyHeight > 0 then
                    Terrain:FillBlock(
                        CFrame.new(column.x, baseY + bodyHeight * 0.5, column.z),
                        Vector3.new(cellSize, bodyHeight, cellSize),
                        biome.BodyMaterial
                    )
                end

                Terrain:FillBlock(
                    CFrame.new(column.x, bodyTop + topHeight * 0.5, column.z),
                    Vector3.new(cellSize, topHeight, cellSize),
                    biome.SurfaceMaterial
                )

                if column.height < profile.WaterLevel then
                    local waterHeight = profile.WaterLevel - column.height
                    Terrain:FillBlock(
                        CFrame.new(column.x, column.height + waterHeight * 0.5, column.z),
                        Vector3.new(cellSize, waterHeight, cellSize),
                        Enum.Material.Water
                    )
                end
            end

            local function applyHeightmapColumns(profile, columns)
                for ix, columnRow in ipairs(columns) do
                    for _, column in ipairs(columnRow) do
                        fillColumn(profile, column)
                    end

                    if ix % 12 == 0 then
                        task.wait()
                    end
                end
            end

            local function buildIslandDescriptors(profile, seed)
                local center = getManagedCenter(profile)
                local descriptors = {}
                local totalIslands = profile.IslandCount

                table.insert(descriptors, {
                    Position = Vector3.new(center.X, profile.PrimaryIslandAltitude or profile.Spawn.Height, center.Z),
                    Radius = profile.PrimaryIslandRadius or (profile.IslandRadius + 10),
                    Altitude = profile.PrimaryIslandAltitude or profile.Spawn.Height,
                })

                for index = 1, totalIslands - 1 do
                    local angleNoise = Noise.hash01(index, totalIslands, seed + 61)
                    local angle = ((index - 1) / math.max(totalIslands - 1, 1)) * math.pi * 2 + angleNoise * 0.45
                    local radialOffset = (Noise.hash01(index, totalIslands, seed + 73) - 0.5) * profile.RingJitter
                    local altitudeOffset = (Noise.hash01(index, totalIslands, seed + 89) - 0.5) * profile.AltitudeJitter
                    local radiusOffset = (Noise.hash01(index, totalIslands, seed + 101) - 0.5) * profile.IslandRadiusJitter

                    local radialDistance = profile.RingRadius + radialOffset
                    local altitude = profile.BaseHeight + altitudeOffset
                    local radius = profile.IslandRadius + radiusOffset

                    table.insert(descriptors, {
                        Position = Vector3.new(
                            center.X + math.cos(angle) * radialDistance,
                            altitude,
                            center.Z + math.sin(angle) * radialDistance
                        ),
                        Radius = radius,
                        Altitude = altitude,
                    })
                end

                return descriptors
            end

            local function applySkyIslands(profile, seed)
                local descriptors = buildIslandDescriptors(profile, seed)
                local minimumHeight = math.huge
                local maximumHeight = -math.huge

                for _, descriptor in ipairs(descriptors) do
                    local position = descriptor.Position
                    local radius = descriptor.Radius

                    Terrain:FillBall(position, radius, Enum.Material.Ground)
                    Terrain:FillBlock(
                        CFrame.new(position.X, position.Y + profile.TopThickness * 0.25, position.Z),
                        Vector3.new(radius * 1.8, profile.TopThickness, radius * 1.8),
                        Enum.Material.Grass
                    )

                    for layer = 1, 5 do
                        local alpha = layer / 5
                        local undersideRadius = radius * (1 - alpha * 0.45)
                        local y = position.Y - alpha * profile.IslandDepth
                        Terrain:FillBall(Vector3.new(position.X, y, position.Z), undersideRadius, Enum.Material.Rock)
                    end

                    minimumHeight = math.min(minimumHeight, position.Y - profile.IslandDepth)
                    maximumHeight = math.max(maximumHeight, position.Y + profile.TopThickness)
                end

                return {
                    ColumnCount = 0,
                    IslandCount = #descriptors,
                    MinimumHeight = minimumHeight,
                    MaximumHeight = maximumHeight,
                    WaterCoverage = 0,
                }
            end

            function TerrainGenerator.generate(profile, seed, config, options)
                local generationOptions = options or {}
                local shouldClear = generationOptions.ClearManagedRegion
                if shouldClear == nil then
                    shouldClear = config.ClearManagedRegionBeforeGenerate
                end

                if shouldClear then
                    TerrainGenerator.clearManagedRegion(profile, config)
                end

                if profile.Kind == "SkyIslands" then
                    return applySkyIslands(profile, seed)
                end

                local columns, summary = buildHeightmapColumns(profile, seed)
                applyHeightmapColumns(profile, columns)
                return summary
            end

            return TerrainGenerator
            """
        ).strip()
        + "\n",
    }
)

TEXT_FILES.update(
    {
        "server/terrain/EnvironmentGenerator.lua": textwrap.dedent(
            """
            local Workspace = game:GetService("Workspace")
            local Noise = require(script.Parent.Noise)

            local EnvironmentGenerator = {}

            local function getManagedCenter(profile)
                local center = profile.ManagedCenter
                return Vector3.new(center.X, center.Y, center.Z)
            end

            local function getOrCreateRootFolder(folderName)
                local existing = Workspace:FindFirstChild(folderName)
                if existing then
                    existing:Destroy()
                end

                local root = Instance.new("Folder")
                root.Name = folderName
                root.Parent = Workspace
                return root
            end

            local function ensureCategory(parent, name)
                local folder = Instance.new("Folder")
                folder.Name = name
                folder.Parent = parent
                return folder
            end

            local function createPart(parent, name, size, cframe, color, material, transparency, canCollide)
                local part = Instance.new("Part")
                part.Name = name
                part.Anchored = true
                part.CanCollide = canCollide ~= false
                part.TopSurface = Enum.SurfaceType.Smooth
                part.BottomSurface = Enum.SurfaceType.Smooth
                part.Size = size
                part.CFrame = cframe
                part.Color = color
                part.Material = material
                part.Transparency = transparency or 0
                part.Parent = parent
                return part
            end

            local function createTree(parent, position, scale, seedValue)
                local tree = Instance.new("Model")
                tree.Name = "GeneratedTree"
                tree.Parent = parent

                local trunkColor = Color3.fromRGB(89 + seedValue % 18, 65, 42)
                local canopyColor = Color3.fromRGB(75, 127 + seedValue % 20, 70)

                createPart(tree, "Trunk", Vector3.new(1.4 * scale, 8 * scale, 1.4 * scale), CFrame.new(position + Vector3.new(0, 4 * scale, 0)), trunkColor, Enum.Material.Wood, 0)
                createPart(tree, "CanopyLower", Vector3.new(5.5 * scale, 4.5 * scale, 5.5 * scale), CFrame.new(position + Vector3.new(0, 8.5 * scale, 0)), canopyColor, Enum.Material.Grass, 0).Shape = Enum.PartType.Ball
                createPart(tree, "CanopyUpper", Vector3.new(4.2 * scale, 3.6 * scale, 4.2 * scale), CFrame.new(position + Vector3.new(0, 11.2 * scale, 0)), canopyColor:Lerp(Color3.new(1, 1, 1), 0.06), Enum.Material.Grass, 0).Shape = Enum.PartType.Ball
                tree:PivotTo(CFrame.new(position))
                return tree
            end

            local function createBush(parent, position, scale, seedValue)
                local bush = Instance.new("Model")
                bush.Name = "GeneratedBush"
                bush.Parent = parent
                local baseColor = Color3.fromRGB(69, 118 + seedValue % 24, 64)
                createPart(bush, "BushCore", Vector3.new(4.2 * scale, 2.4 * scale, 4.2 * scale), CFrame.new(position + Vector3.new(0, 1.2 * scale, 0)), baseColor, Enum.Material.Grass, 0).Shape = Enum.PartType.Ball
                createPart(bush, "BushAccent", Vector3.new(2.6 * scale, 2.0 * scale, 2.6 * scale), CFrame.new(position + Vector3.new(1.1 * scale, 1.7 * scale, 0)), baseColor:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.Grass, 0).Shape = Enum.PartType.Ball
                bush:PivotTo(CFrame.new(position))
                return bush
            end

            local function createRockCluster(parent, position, scale, seedValue)
                local rock = Instance.new("Model")
                rock.Name = "GeneratedRockCluster"
                rock.Parent = parent
                local baseColor = Color3.fromRGB(109 + seedValue % 20, 107 + seedValue % 14, 108 + seedValue % 10)
                createPart(rock, "RockA", Vector3.new(3.4 * scale, 2.6 * scale, 3.8 * scale), CFrame.new(position + Vector3.new(-0.8 * scale, 1.3 * scale, 0.6 * scale)) * CFrame.Angles(0.12, 0.25, -0.1), baseColor, Enum.Material.Slate, 0)
                createPart(rock, "RockB", Vector3.new(2.8 * scale, 2.0 * scale, 2.8 * scale), CFrame.new(position + Vector3.new(1.0 * scale, 1.0 * scale, -0.6 * scale)) * CFrame.Angles(-0.08, -0.3, 0.14), baseColor:Lerp(Color3.new(1, 1, 1), 0.06), Enum.Material.Rock, 0)
                rock:PivotTo(CFrame.new(position))
                return rock
            end

            local function createCactus(parent, position, scale, seedValue)
                local cactus = Instance.new("Model")
                cactus.Name = "GeneratedCactus"
                cactus.Parent = parent
                local color = Color3.fromRGB(84, 133 + seedValue % 25, 78)
                createPart(cactus, "Body", Vector3.new(1.8 * scale, 7.2 * scale, 1.8 * scale), CFrame.new(position + Vector3.new(0, 3.6 * scale, 0)), color, Enum.Material.SmoothPlastic, 0)
                createPart(cactus, "ArmLeft", Vector3.new(1.1 * scale, 3.0 * scale, 1.1 * scale), CFrame.new(position + Vector3.new(-1.2 * scale, 3.2 * scale, 0)) * CFrame.Angles(0, 0, math.rad(30)), color, Enum.Material.SmoothPlastic, 0)
                createPart(cactus, "ArmRight", Vector3.new(1.1 * scale, 2.4 * scale, 1.1 * scale), CFrame.new(position + Vector3.new(1.0 * scale, 4.3 * scale, 0)) * CFrame.Angles(0, 0, math.rad(-35)), color, Enum.Material.SmoothPlastic, 0)
                cactus:PivotTo(CFrame.new(position))
                return cactus
            end

            local function createIceShard(parent, position, scale, seedValue)
                local shard = Instance.new("Model")
                shard.Name = "GeneratedIceShard"
                shard.Parent = parent

                local coolAlpha = (seedValue % 100) / 100
                local baseColor = Color3.fromRGB(169, 212, 255):Lerp(Color3.fromRGB(238, 246, 255), coolAlpha)

                createPart(shard, "ShardA", Vector3.new(1.6 * scale, 8.4 * scale, 1.8 * scale), CFrame.new(position + Vector3.new(0, 4.2 * scale, 0)) * CFrame.Angles(math.rad(-7), math.rad(16), math.rad(11)), baseColor, Enum.Material.Glass, 0.12, true)
                createPart(shard, "ShardB", Vector3.new(1.2 * scale, 5.8 * scale, 1.4 * scale), CFrame.new(position + Vector3.new(-1.0 * scale, 2.9 * scale, 0.3 * scale)) * CFrame.Angles(math.rad(9), math.rad(-12), math.rad(-8)), baseColor:Lerp(Color3.new(1, 1, 1), 0.1), Enum.Material.Neon, 0.2, false)
                createPart(shard, "ShardC", Vector3.new(1.0 * scale, 4.6 * scale, 1.2 * scale), CFrame.new(position + Vector3.new(0.9 * scale, 2.3 * scale, -0.4 * scale)) * CFrame.Angles(math.rad(-5), math.rad(18), math.rad(6)), baseColor, Enum.Material.Glass, 0.18, false)
                shard:PivotTo(CFrame.new(position))
                return shard
            end

            local function createLandmark(parent, position, scale, profileName)
                local landmark = Instance.new("Model")
                landmark.Name = "GeneratedLandmark"
                landmark.Parent = parent
                local baseColor = profileName == "DesertCanyon" and Color3.fromRGB(173, 129, 84) or Color3.fromRGB(126, 129, 137)
                if profileName == "FrozenDesertMoon" then
                    baseColor = Color3.fromRGB(146, 157, 188)
                end
                createPart(landmark, "Base", Vector3.new(8 * scale, 2 * scale, 8 * scale), CFrame.new(position + Vector3.new(0, scale, 0)), baseColor, Enum.Material.Rock, 0)
                createPart(landmark, "PillarA", Vector3.new(1.8 * scale, 7.5 * scale, 1.8 * scale), CFrame.new(position + Vector3.new(-2.1 * scale, 5 * scale, 0)), baseColor:Lerp(Color3.new(1, 1, 1), 0.04), Enum.Material.Slate, 0)
                createPart(landmark, "PillarB", Vector3.new(1.8 * scale, 6.2 * scale, 1.8 * scale), CFrame.new(position + Vector3.new(2.1 * scale, 4.4 * scale, 0)), baseColor:Lerp(Color3.new(1, 1, 1), 0.1), Enum.Material.Slate, 0)
                createPart(landmark, "Beam", Vector3.new(6.8 * scale, 1.3 * scale, 1.5 * scale), CFrame.new(position + Vector3.new(0, 8.1 * scale, 0)), baseColor, Enum.Material.Slate, 0)
                landmark:PivotTo(CFrame.new(position))
                return landmark
            end

            local function createMoonBackdrop(parent, profile)
                local feature = Instance.new("Model")
                feature.Name = "MoonBackdrop"
                feature.Parent = parent

                local center = getManagedCenter(profile)
                local moon = profile.Moon
                local moonPosition = Vector3.new(
                    center.X - moon.Distance,
                    moon.Height,
                    center.Z - moon.Distance * 0.35
                )

                createPart(feature, "MoonHalo", Vector3.new(moon.Radius * 2.9, moon.Radius * 2.9, moon.Radius * 2.9), CFrame.new(moonPosition), Color3.fromRGB(moon.HaloColorRGB[1], moon.HaloColorRGB[2], moon.HaloColorRGB[3]), Enum.Material.Neon, 0.74, false).Shape = Enum.PartType.Ball
                createPart(feature, "MoonCore", Vector3.new(moon.Radius * 2, moon.Radius * 2, moon.Radius * 2), CFrame.new(moonPosition), Color3.fromRGB(moon.CoreColorRGB[1], moon.CoreColorRGB[2], moon.CoreColorRGB[3]), Enum.Material.SmoothPlastic, 0.04, false).Shape = Enum.PartType.Ball
                createPart(feature, "MoonShadow", Vector3.new(moon.Radius * 1.7, moon.Radius * 1.7, moon.Radius * 1.7), CFrame.new(moonPosition + Vector3.new(8, -5, 6)), Color3.fromRGB(181, 198, 231), Enum.Material.SmoothPlastic, 0.16, false).Shape = Enum.PartType.Ball
                feature:PivotTo(CFrame.new(center))
                return feature
            end

            local function createSpaceWaterfall(parent, profile)
                local feature = Instance.new("Model")
                feature.Name = "SpaceWaterfallCliff"
                feature.Parent = parent

                local center = getManagedCenter(profile)
                local waterfall = profile.Waterfall
                local topPosition = Vector3.new(center.X + waterfall.EdgeOffset, profile.Spawn.Height + 6, center.Z)
                local basePosition = topPosition - Vector3.new(0, waterfall.Height, 0)

                createPart(
                    feature,
                    "WaterLip",
                    Vector3.new(waterfall.Width + 8, 3, waterfall.Thickness + 4),
                    CFrame.new(topPosition + Vector3.new(-8, 1, 0)),
                    Color3.fromRGB(95, 108, 130),
                    Enum.Material.Slate,
                    0,
                    true
                )
                createPart(
                    feature,
                    "WaterSheetOuter",
                    Vector3.new(waterfall.Width, waterfall.Height, waterfall.Thickness),
                    CFrame.new(topPosition + Vector3.new(0, -waterfall.Height * 0.5, 0)),
                    Color3.fromRGB(143, 213, 255),
                    Enum.Material.Glass,
                    0.28,
                    false
                )
                createPart(
                    feature,
                    "WaterSheetCore",
                    Vector3.new(waterfall.Width - 6, waterfall.Height, math.max(waterfall.Thickness - 2, 2)),
                    CFrame.new(topPosition + Vector3.new(0, -waterfall.Height * 0.5, 0.6)),
                    Color3.fromRGB(185, 237, 255),
                    Enum.Material.Neon,
                    0.38,
                    false
                )
                createPart(
                    feature,
                    "MistRing",
                    Vector3.new(waterfall.MistRadius * 2, 2.5, waterfall.MistRadius * 2),
                    CFrame.new(basePosition + Vector3.new(0, 4, 0)),
                    Color3.fromRGB(208, 236, 255),
                    Enum.Material.Neon,
                    0.55,
                    false
                ).Shape = Enum.PartType.Cylinder
                createPart(
                    feature,
                    "ImpactGlow",
                    Vector3.new(waterfall.MistRadius * 1.2, 3, waterfall.MistRadius * 1.2),
                    CFrame.new(basePosition + Vector3.new(0, 7, 0)),
                    Color3.fromRGB(131, 199, 255),
                    Enum.Material.Neon,
                    0.4,
                    false
                ).Shape = Enum.PartType.Ball
                createPart(
                    feature,
                    "CliffSpur",
                    Vector3.new(18, 48, 26),
                    CFrame.new(topPosition + Vector3.new(-14, -18, 0)) * CFrame.Angles(0.08, 0.14, -0.06),
                    Color3.fromRGB(79, 83, 104),
                    Enum.Material.Slate,
                    0,
                    true
                )

                feature:PivotTo(CFrame.new(center))
                return feature
            end

            local function createSpaceStars(parent, profile, seed)
                local starsFolder = Instance.new("Folder")
                starsFolder.Name = "StarField"
                starsFolder.Parent = parent

                local center = getManagedCenter(profile)
                local stars = profile.Stars

                for index = 1, stars.Count do
                    local angle = Noise.hash01(index, stars.Count, seed + 990) * math.pi * 2
                    local radius = stars.Radius * (0.45 + Noise.hash01(index, stars.Count, seed + 1007) * 0.55)
                    local height = stars.MinY + (stars.MaxY - stars.MinY) * Noise.hash01(index, stars.Count, seed + 1021)
                    local x = center.X + math.cos(angle) * radius
                    local z = center.Z + math.sin(angle) * radius
                    local size = 1.2 + Noise.hash01(index, stars.Count, seed + 1039) * 3.2
                    local coolAlpha = Noise.hash01(index, stars.Count, seed + 1057)
                    local color = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(153, 214, 255), coolAlpha)
                    createPart(
                        starsFolder,
                        "Star" .. tostring(index),
                        Vector3.new(size, size, size),
                        CFrame.new(x, height, z),
                        color,
                        Enum.Material.Neon,
                        0.18,
                        false
                    ).Shape = Enum.PartType.Ball
                end

                return starsFolder
            end

            local function buildRaycastParams(environmentRoot)
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = { environmentRoot }
                params.IgnoreWater = false
                return params
            end

            local function shouldSkipSpawn(profile, position)
                local center = getManagedCenter(profile)
                local offset = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
                return offset.Magnitude < (profile.Spawn.FlattenRadius + 18)
            end

            local function spawnProp(profile, categories, position, material, randomness)
                local seedValue = math.floor(randomness * 1000)
                if material == Enum.Material.Water then
                    return nil
                end

                if profile.Name == "DesertCanyon" then
                    if randomness < profile.Props.TreeDensity then
                        return createCactus(categories.Trees, position, 1.0 + randomness, seedValue)
                    end
                    if randomness < profile.Props.TreeDensity + profile.Props.RockDensity then
                        return createRockCluster(categories.Rocks, position, 1.1 + randomness * 0.6, seedValue)
                    end
                    if randomness > 1 - profile.Props.LandmarkDensity then
                        return createLandmark(categories.Landmarks, position, 1.0 + randomness, profile.Name)
                    end
                    return nil
                end

                if profile.Name == "FrozenDesertMoon" then
                    if randomness < profile.Props.BushDensity then
                        return createIceShard(categories.Bushes, position, 1.0 + randomness * 0.55, seedValue)
                    end
                    if randomness < profile.Props.BushDensity + profile.Props.RockDensity then
                        return createRockCluster(categories.Rocks, position, 1.05 + randomness * 0.5, seedValue)
                    end
                    if randomness > 1 - profile.Props.LandmarkDensity then
                        return createLandmark(categories.Landmarks, position, 0.95 + randomness * 0.6, profile.Name)
                    end
                    return nil
                end

                if material == Enum.Material.Rock or material == Enum.Material.Slate then
                    if randomness < profile.Props.RockDensity then
                        return createRockCluster(categories.Rocks, position, 0.9 + randomness * 0.8, seedValue)
                    end
                    if randomness > 1 - profile.Props.LandmarkDensity then
                        return createLandmark(categories.Landmarks, position, 0.9 + randomness * 0.7, profile.Name)
                    end
                    return nil
                end

                if material == Enum.Material.Snow then
                    if randomness < profile.Props.TreeDensity * 0.5 then
                        return createTree(categories.Trees, position, 0.92 + randomness * 0.4, seedValue)
                    end
                    if randomness < profile.Props.TreeDensity * 0.5 + profile.Props.RockDensity then
                        return createRockCluster(categories.Rocks, position, 1.0 + randomness * 0.5, seedValue)
                    end
                    return nil
                end

                if randomness < profile.Props.TreeDensity then
                    return createTree(categories.Trees, position, 0.95 + randomness * 0.55, seedValue)
                end
                if randomness < profile.Props.TreeDensity + profile.Props.BushDensity then
                    return createBush(categories.Bushes, position, 0.95 + randomness * 0.5, seedValue)
                end
                if randomness < profile.Props.TreeDensity + profile.Props.BushDensity + profile.Props.RockDensity then
                    return createRockCluster(categories.Rocks, position, 0.9 + randomness * 0.5, seedValue)
                end
                if randomness > 1 - profile.Props.LandmarkDensity then
                    return createLandmark(categories.Landmarks, position, 0.9 + randomness * 0.6, profile.Name)
                end
                return nil
            end

            function EnvironmentGenerator.generate(profile, seed, config, options)
                local environmentRoot = getOrCreateRootFolder(config.GeneratedEnvironmentFolderName)
                local categories = {
                    Trees = ensureCategory(environmentRoot, "Trees"),
                    Bushes = ensureCategory(environmentRoot, "Bushes"),
                    Rocks = ensureCategory(environmentRoot, "Rocks"),
                    Landmarks = ensureCategory(environmentRoot, "Landmarks"),
                    Effects = ensureCategory(environmentRoot, "Effects"),
                }
                local raycastParams = buildRaycastParams(environmentRoot)
                local center = getManagedCenter(profile)
                local stride = profile.Props.ScatterStride
                local halfSize = profile.WorldSize * 0.5
                local propCount = 0

                if profile.Name == "SpaceWaterfallCliffs" then
                    createSpaceStars(categories.Effects, profile, seed)
                    createSpaceWaterfall(categories.Effects, profile)
                    propCount = propCount + 2
                end
                if profile.Name == "FrozenDesertMoon" then
                    createSpaceStars(categories.Effects, profile, seed)
                    createMoonBackdrop(categories.Effects, profile)
                    propCount = propCount + 2
                end

                for x = center.X - halfSize, center.X + halfSize, stride do
                    for z = center.Z - halfSize, center.Z + halfSize, stride do
                        local randomness = Noise.hash01(math.floor(x / stride), math.floor(z / stride), seed + 887)
                        if randomness > 0.78 then
                            local origin = Vector3.new(x, profile.ClearMaxY - 4, z)
                            local direction = Vector3.new(0, -(profile.ClearMaxY - profile.ClearMinY + 180), 0)
                            local result = Workspace:Raycast(origin, direction, raycastParams)
                            if result and not shouldSkipSpawn(profile, result.Position) and result.Normal.Y >= 0.65 then
                                local placed = spawnProp(profile, categories, result.Position, result.Material, randomness)
                                if placed then
                                    propCount = propCount + 1
                                end
                            end
                        end
                    end
                    task.wait()
                end

                return {PropCount = propCount}
            end

            return EnvironmentGenerator
            """
        ).strip()
        + "\n",
        "server/terrain/LightingController.lua": textwrap.dedent(
            """
            local Lighting = game:GetService("Lighting")
            local Workspace = game:GetService("Workspace")

            local LightingController = {}

            local function ensureChild(parent, className, name)
                local child = parent:FindFirstChild(name)
                if child and child.ClassName == className then
                    return child
                end
                if child then
                    child:Destroy()
                end
                child = Instance.new(className)
                child.Name = name
                child.Parent = parent
                return child
            end

            local function colorFromRGB(rgb)
                return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
            end

            function LightingController.apply(profile)
                local settings = profile.Lighting
                Lighting.Technology = Enum.Technology.Future
                Lighting.ClockTime = settings.ClockTime
                Lighting.Brightness = settings.Brightness
                Lighting.ExposureCompensation = settings.ExposureCompensation
                Lighting.Ambient = colorFromRGB(settings.AmbientRGB)
                Lighting.OutdoorAmbient = colorFromRGB(settings.OutdoorAmbientRGB)
                Lighting.EnvironmentDiffuseScale = settings.EnvironmentDiffuseScale
                Lighting.EnvironmentSpecularScale = settings.EnvironmentSpecularScale
                Lighting.GlobalShadows = true

                local atmosphere = ensureChild(Lighting, "Atmosphere", "GeneratedAtmosphere")
                atmosphere.Color = colorFromRGB(settings.AtmosphereColorRGB)
                atmosphere.Decay = colorFromRGB(settings.AtmosphereDecayRGB)
                atmosphere.Density = settings.AtmosphereDensity
                atmosphere.Offset = settings.AtmosphereOffset
                atmosphere.Glare = settings.AtmosphereGlare
                atmosphere.Haze = settings.AtmosphereHaze

                local colorCorrection = ensureChild(Lighting, "ColorCorrectionEffect", "GeneratedColorCorrection")
                colorCorrection.Brightness = settings.ColorCorrectionBrightness
                colorCorrection.Contrast = settings.ColorCorrectionContrast
                colorCorrection.Saturation = settings.ColorCorrectionSaturation
                colorCorrection.TintColor = colorFromRGB(settings.ColorCorrectionTintRGB)

                local terrain = Workspace.Terrain
                local clouds = terrain:FindFirstChild("GeneratedClouds")
                if clouds and not clouds:IsA("Clouds") then
                    clouds:Destroy()
                    clouds = nil
                end
                if not clouds then
                    clouds = Instance.new("Clouds")
                    clouds.Name = "GeneratedClouds"
                    clouds.Parent = terrain
                end
                clouds.Cover = settings.CloudCover
                clouds.Density = settings.CloudDensity
                clouds.Color = colorFromRGB(settings.CloudColorRGB)
            end

            return LightingController
            """
        ).strip()
        + "\n",
        "server/terrain/SpawnPlanner.lua": textwrap.dedent(
            """
            local Workspace = game:GetService("Workspace")

            local SpawnPlanner = {}

            local function getManagedCenter(profile)
                local center = profile.ManagedCenter
                return Vector3.new(center.X, center.Y, center.Z)
            end

            function SpawnPlanner.place(profile)
                local existing = Workspace:FindFirstChild("GeneratedSpawn")
                if existing then
                    existing:Destroy()
                end

                local center = getManagedCenter(profile)
                local spawn = Instance.new("SpawnLocation")
                spawn.Name = "GeneratedSpawn"
                spawn.Anchored = true
                spawn.Neutral = true
                spawn.CanCollide = true
                spawn.Color = Color3.fromRGB(104, 226, 255)
                spawn.Material = Enum.Material.Neon
                spawn.Transparency = 0.3
                spawn.Size = Vector3.new(10, 1, 10)
                spawn.CFrame = CFrame.new(center.X, profile.Spawn.Height + 3, center.Z)
                spawn.Parent = Workspace
                return spawn
            end

            return SpawnPlanner
            """
        ).strip()
        + "\n",
        "server/terrain/TerrainDiagnostics.lua": textwrap.dedent(
            """
            local Workspace = game:GetService("Workspace")

            local TerrainDiagnostics = {}

            local function getOrCreateFolder()
                local folder = Workspace:FindFirstChild("GeneratedTerrainInfo")
                if folder then
                    folder:Destroy()
                end
                folder = Instance.new("Folder")
                folder.Name = "GeneratedTerrainInfo"
                folder.Parent = Workspace
                return folder
            end

            local function addValue(parent, className, name, value)
                local instance = Instance.new(className)
                instance.Name = name
                instance.Value = value
                instance.Parent = parent
                return instance
            end

            function TerrainDiagnostics.publish(summary)
                Workspace:SetAttribute("RNGamingTerrainProfile", summary.ProfileName)
                Workspace:SetAttribute("RNGamingTerrainSeed", summary.Seed)
                Workspace:SetAttribute("RNGamingTerrainPropCount", summary.PropCount or 0)

                local folder = getOrCreateFolder()
                addValue(folder, "StringValue", "ProfileName", summary.ProfileName)
                addValue(folder, "IntValue", "Seed", summary.Seed)
                addValue(folder, "IntValue", "ColumnCount", summary.ColumnCount or 0)
                addValue(folder, "IntValue", "IslandCount", summary.IslandCount or 0)
                addValue(folder, "IntValue", "PropCount", summary.PropCount or 0)
                addValue(folder, "NumberValue", "MinimumHeight", summary.MinimumHeight or 0)
                addValue(folder, "NumberValue", "MaximumHeight", summary.MaximumHeight or 0)
                addValue(folder, "NumberValue", "WaterCoverage", summary.WaterCoverage or 0)
                addValue(folder, "NumberValue", "SpawnHeight", summary.SpawnHeight or 0)
            end

            function TerrainDiagnostics.clear()
                Workspace:SetAttribute("RNGamingTerrainProfile", nil)
                Workspace:SetAttribute("RNGamingTerrainSeed", nil)
                Workspace:SetAttribute("RNGamingTerrainPropCount", nil)
                local folder = Workspace:FindFirstChild("GeneratedTerrainInfo")
                if folder then
                    folder:Destroy()
                end
            end

            return TerrainDiagnostics
            """
        ).strip()
        + "\n",
        "client/MainClient.lua": textwrap.dedent(
            """
            local Workspace = game:GetService("Workspace")

            local function reportTerrain()
                local profile = Workspace:GetAttribute("RNGamingTerrainProfile")
                local seed = Workspace:GetAttribute("RNGamingTerrainSeed")
                if profile and seed then
                    print(string.format("[RNGaming] Active terrain profile: %s (seed %s)", profile, tostring(seed)))
                end
            end

            Workspace:GetAttributeChangedSignal("RNGamingTerrainProfile"):Connect(reportTerrain)
            reportTerrain()
            """
        ).strip()
        + "\n",
        "studio/GenerateTerrain.command.lua": textwrap.dedent(
            """
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local ServerScriptService = game:GetService("ServerScriptService")

            local Config = require(ReplicatedStorage:WaitForChild("Config"))
            local TerrainBootstrap = require(ServerScriptService:WaitForChild("TerrainBootstrap"))

            local ok, result = pcall(function()
                local profileName = Config.DefaultTerrainProfile
                local seed = Config.DefaultSeed
                return TerrainBootstrap.generateInStudio(profileName, seed)
            end)

            if ok then
                print(string.format(
                    "[RNGaming] Generated terrain profile %s with seed %s. Props: %s",
                    result.ProfileName,
                    tostring(result.Seed),
                    tostring(result.PropCount)
                ))
            else
                warn(result)
            end
            """
        ).strip()
        + "\n",
        "studio/GenerateTerrain.plugin.lua": textwrap.dedent(
            """
            local toolbar = plugin:CreateToolbar("RNGaming Terrain")
            local generateButton = toolbar:CreateButton("Generate Terrain", "Generate the configured terrain profile inside the managed region.", "")
            local randomizeButton = toolbar:CreateButton("Generate New Seed", "Generate the configured terrain profile with a new seed.", "")
            local clearButton = toolbar:CreateButton("Clear Region", "Clear the managed terrain region and generated environment.", "")

            local function withBootstrap(callback)
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local ServerScriptService = game:GetService("ServerScriptService")
                local Config = require(ReplicatedStorage:WaitForChild("Config"))
                local TerrainBootstrap = require(ServerScriptService:WaitForChild("TerrainBootstrap"))
                callback(TerrainBootstrap, Config)
            end

            generateButton.Click:Connect(function()
                local ok, result = pcall(function()
                    withBootstrap(function(TerrainBootstrap, Config)
                        local summary = TerrainBootstrap.generateInStudio(Config.DefaultTerrainProfile, Config.DefaultSeed)
                        print(string.format("[RNGaming] Generated %s with seed %s", summary.ProfileName, tostring(summary.Seed)))
                    end)
                end)
                if not ok then
                    warn("[RNGaming] Generate Terrain failed:", result)
                end
            end)

            randomizeButton.Click:Connect(function()
                local ok, result = pcall(function()
                    withBootstrap(function(TerrainBootstrap, Config)
                        local seed = math.floor(os.time() % 1000000)
                        local summary = TerrainBootstrap.generateInStudio(Config.DefaultTerrainProfile, seed)
                        print(string.format("[RNGaming] Generated %s with new seed %s", summary.ProfileName, tostring(summary.Seed)))
                    end)
                end)
                if not ok then
                    warn("[RNGaming] Generate New Seed failed:", result)
                end
            end)

            clearButton.Click:Connect(function()
                local ok, result = pcall(function()
                    withBootstrap(function(TerrainBootstrap, Config)
                        TerrainBootstrap.clearManagedRegion(Config.DefaultTerrainProfile)
                        print("[RNGaming] Cleared the managed terrain region.")
                    end)
                end)
                if not ok then
                    warn("[RNGaming] Clear Region failed:", result)
                end
            end)
            """
        ).strip()
        + "\n",
    }
)


def populate_project(output_dir: Path, metadata: dict) -> None:
    write_text(output_dir / "README_GENERATED.md", PROJECT_README.replace("__GAME_NAME__", metadata["game_name"]))
    write_text(
        output_dir / "INSTALL_AND_USAGE.md",
        PROJECT_INSTALL_AND_USAGE.replace("__GAME_NAME__", metadata["game_name"]).replace("__PROJECT_FOLDER_NAME__", output_dir.name),
    )
    write_text(output_dir / "shared" / "Config.lua", render_config_lua(metadata))
    write_text(output_dir / "shared" / "ExperienceGuard.lua", render_experience_guard_lua())
    write_text(output_dir / "shared" / "TerrainProfiles.lua", render_terrain_profiles_lua())
    write_json(output_dir / "terrain_profiles.json", TERRAIN_PROFILE_MANIFEST)
    write_text(output_dir / "art" / "reviews" / "terrain" / "README.md", ART_REVIEW_README)

    for relative_path, content in TEXT_FILES.items():
        write_text(output_dir / relative_path, content)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a terrain-first Roblox experience scaffold.")
    parser.add_argument("--game-name", required=True, help="Generated project name.")
    parser.add_argument("--experience-name", default=None, help="Optional Roblox experience or place workflow name. Defaults to the game name.")
    parser.add_argument("--template", choices=sorted(PROJECT_TEMPLATES.keys()), default="terrain", help="Template to generate. 'experience' is an alias for the terrain scaffold.")
    parser.add_argument("--output", required=True, help="Output directory for the generated project.")
    parser.add_argument("--author", default="Unknown", help="Project author.")
    parser.add_argument("--version", default="0.1", help="Project version.")
    parser.add_argument("--group-id", type=int, default=None, help="Optional Roblox group/community ID.")
    parser.add_argument("--group-name", default="", help="Optional Roblox group/community name.")
    parser.add_argument("--allowed-place-id", action="append", type=int, default=[], help="Optional PlaceId to lock the generated project to. Repeat for multiple places.")
    parser.add_argument("--default-profile", choices=sorted(TERRAIN_PROFILE_MANIFEST["Profiles"].keys()), default=TERRAIN_PROFILE_MANIFEST["DefaultProfileName"], help="Default terrain profile used by Config.lua.")
    parser.add_argument("--default-seed", type=int, default=1337, help="Default terrain seed used by Config.lua.")
    parser.add_argument("--force", action="store_true", help="Overwrite the output directory if it already exists.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_dir = Path(args.output).resolve()

    if output_dir.exists() and not args.force:
        raise SystemExit(f"Output directory '{output_dir}' already exists. Use --force to overwrite.")

    reset_output_dir(output_dir)

    metadata = {
        "game_name": args.game_name,
        "experience_name": args.experience_name or args.game_name,
        "template": "terrain",
        "author": args.author,
        "version": args.version,
        "group_id": args.group_id,
        "group_name": args.group_name or None,
        "allowed_place_ids": args.allowed_place_id or [],
        "default_profile": args.default_profile,
        "default_seed": args.default_seed,
        "architecture": ARCHITECTURE_VERSION,
    }

    build_rojo_project(args.game_name, output_dir)
    populate_project(output_dir, metadata)
    write_json(
        output_dir / "game_metadata.json",
        {
            "game_name": metadata["game_name"],
            "experience_name": metadata["experience_name"],
            "template": metadata["template"],
            "author": metadata["author"],
            "version": metadata["version"],
            "group_id": metadata["group_id"],
            "group_name": metadata["group_name"],
            "experience_lock_enabled": bool(metadata["allowed_place_ids"]),
            "allowed_place_ids": metadata["allowed_place_ids"],
            "default_profile": metadata["default_profile"],
            "default_seed": metadata["default_seed"],
            "architecture": metadata["architecture"],
        },
    )

    print("\\nProject generated successfully.")
    print("Open Roblox Studio and use Rojo to sync the generated project.")


if __name__ == "__main__":
    main()
