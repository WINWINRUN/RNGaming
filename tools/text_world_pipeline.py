from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


NUMBER_WORDS = {
    "zero": 0,
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
    "eleven": 11,
    "twelve": 12,
    "thirteen": 13,
    "fourteen": 14,
    "fifteen": 15,
    "sixteen": 16,
    "seventeen": 17,
    "eighteen": 18,
    "nineteen": 19,
    "twenty": 20,
    "thirty": 30,
    "forty": 40,
    "fifty": 50,
}

TAG_CATALOG = {
    "theme": {
        "frozen-wilds": ["snow world", "ice world", "frozen forest", "snow forest", "snowy forest", "winter forest", "glacier"],
        "ancient-tech": ["ancient civilization", "robot ruins", "ancient robot", "ancient ruins", "sci-fi ruins", "mech ruins"],
        "sci-fi": ["sci-fi", "scifi", "space", "space station", "futuristic", "hangar", "starport"],
        "industrial": ["industrial", "factory", "refinery", "warehouse"],
        "cozy-town": ["cozy", "village", "town", "main street", "market"],
        "fantasy": ["fantasy", "castle", "magic", "medieval"],
        "post-apocalyptic": ["apocalypse", "ruined", "wasteland", "survival bunker"],
        "island-resort": ["island", "resort", "beach", "tropical", "coast"],
    },
    "art_style": {
        "blocky": ["blocky", "blocks", "grid", "voxel"],
        "pixel": ["pixel", "pixelated", "8-bit", "16-bit"],
        "stylized": ["stylized", "cartoony", "toy-like"],
        "clean-modular": ["modular", "kitbash", "snap grid", "prefab"],
    },
    "terrain": {
        "flat": ["flat", "plains", "plateau"],
        "cliffside": ["cliff", "cliffside", "ridge"],
        "mountains": ["mountain", "mountains", "mountain range", "mountain ranges", "summit", "peak", "pinnacle", "alpine"],
        "islands": ["island", "islands", "archipelago"],
        "canyon": ["canyon", "ravine", "gorge"],
        "forest": ["forest", "woods", "jungle"],
        "desert": ["desert", "dunes", "sand"],
        "snow": ["snow", "snowy", "frozen", "ice"],
    },
    "layout": {
        "main-road": ["main road", "main street", "spine road", "one road", "single road"],
        "hub": ["hub", "plaza", "center", "central plaza", "town square"],
        "branching": ["side street", "side streets", "alleys", "branches"],
        "loop": ["loop", "ring", "circuit"],
        "linear": ["linear", "line", "corridor"],
        "districts": ["district", "districts", "neighborhoods"],
    },
    "density": {
        "sparse": ["sparse", "open", "airy", "wide"],
        "medium": ["medium", "balanced"],
        "dense": ["dense", "tight", "cramped", "crowded"],
    },
    "detail": {
        "low": ["low detail", "simple", "minimal", "cheap"],
        "medium": ["medium detail", "moderate detail"],
        "high": ["high detail", "rich detail", "busy", "layered"],
    },
    "scale": {
        "small": ["small", "compact", "tiny"],
        "medium": ["medium"],
        "large": ["giant", "huge", "massive", "colossal", "vast"],
    },
    "flora_style": {
        "giant-conifer-forest": ["giant trees", "giant tree", "snowy forest", "snow forest", "pine forest", "conifer forest", "winter forest"],
        "mushroom-forest": ["mushroom forest", "giant mushroom", "mushroom grove", "fungal forest"],
        "overgrown": ["overgrown", "vines", "lush ruins"],
    },
    "gameplay_focus": {
        "exploration": ["explore", "exploration", "wander"],
        "queue": ["queue", "line", "waiting in line", "wait in line"],
        "combat": ["combat", "battle", "fight", "battleground"],
        "roleplay": ["roleplay", "rp"],
        "tycoon": ["tycoon", "economy", "upgrade path"],
        "obby": ["obby", "platformer"],
    },
    "mood": {
        "bright": ["bright", "sunny", "clean"],
        "eerie": ["eerie", "haunted", "creepy", "ominous"],
        "heroic": ["heroic", "epic"],
        "cozy": ["cozy", "warm", "friendly"],
        "hostile": ["hostile", "harsh", "dangerous"],
    },
}

LANDMARK_KEYWORDS = {
    "landing_pad": ["landing pad", "pad", "hangar"],
    "watchtower": ["watchtower", "tower"],
    "market": ["market", "bazaar", "stall"],
    "station": ["station", "terminal"],
    "gate": ["gate", "checkpoint"],
    "arena": ["arena"],
    "docks": ["docks", "pier", "harbor"],
    "mushroom_grove": ["mushroom forest", "mushroom grove", "giant mushroom"],
    "robot_ruin": ["robot ruins", "mech ruins", "robot giant ruins", "ancient robot"],
    "fallen_colossus": ["giant ruins", "colossus", "giant robot"],
    "ancient_gate": ["ancient civilization", "ancient ruins", "ancient gate"],
    "summit_crown": ["pinnacle", "summit", "mountain peak"],
    "valley_pass": ["valley", "valleys", "mountain pass"],
    "lake_basin": ["lake", "lake near the bottom", "lake basin"],
    "ice_pillar": ["ice pillar", "ice pillars", "ice spire", "ice spires", "flat top ice pillar", "flat-top ice pillar"],
    "giant_tree_grove": ["giant trees", "giant tree", "snow forest", "snowy forest", "pine forest"],
}

THEME_DEFAULTS = {
    "frozen-wilds": {
        "terrain": "snow",
        "mood": "heroic",
        "color_story": ["snow white", "ice blue", "frost gray"],
        "boundary_style": "glacier walls and frozen ridgelines",
        "spawn_anchor": "snowfield arrival",
        "objective_anchor": "ice crown",
        "module_family_bias": ["snowfield", "ice_pillar", "glacier_bridge", "ridge_path", "lookout", "frozen_grove"],
    },
    "ancient-tech": {
        "terrain": "forest",
        "mood": "eerie",
        "color_story": ["stone", "steel", "deep blue"],
        "boundary_style": "collapsed titan ring and relic walls",
        "spawn_anchor": "ruined approach gate",
        "objective_anchor": "ancient machine core",
        "module_family_bias": ["path", "ruin_wall", "fallen_colossus", "relic_gate", "plaza", "bridge"],
    },
    "sci-fi": {
        "terrain": "flat",
        "mood": "bright",
        "color_story": ["steel", "off-white", "safety orange"],
        "boundary_style": "service walls and canyon berms",
        "spawn_anchor": "airlock checkpoint",
        "objective_anchor": "main landing pad",
        "module_family_bias": ["road", "service_alley", "hangar", "utility_room", "tower", "pad"],
    },
    "industrial": {
        "terrain": "flat",
        "mood": "hostile",
        "color_story": ["charcoal", "rust", "hazard yellow"],
        "boundary_style": "fence line and pipe corridor",
        "spawn_anchor": "loading bay",
        "objective_anchor": "refinery core",
        "module_family_bias": ["road", "pipeway", "warehouse", "tank_yard", "office", "tower"],
    },
    "cozy-town": {
        "terrain": "flat",
        "mood": "cozy",
        "color_story": ["cream", "brick", "forest green"],
        "boundary_style": "tree line and low walls",
        "spawn_anchor": "town gate",
        "objective_anchor": "central plaza",
        "module_family_bias": ["street", "plaza", "shopfront", "home", "garden", "fence"],
    },
    "fantasy": {
        "terrain": "cliffside",
        "mood": "heroic",
        "color_story": ["stone", "gold", "deep blue"],
        "boundary_style": "castle wall and ravine edge",
        "spawn_anchor": "outer gate",
        "objective_anchor": "great hall",
        "module_family_bias": ["road", "courtyard", "tower", "market", "gatehouse", "bridge"],
    },
    "post-apocalyptic": {
        "terrain": "desert",
        "mood": "hostile",
        "color_story": ["dust tan", "oxide red", "smoke gray"],
        "boundary_style": "wreck line and scrap wall",
        "spawn_anchor": "salvage shelter",
        "objective_anchor": "signal tower",
        "module_family_bias": ["road", "scrap_yard", "shelter", "checkpoint", "market", "tower"],
    },
    "island-resort": {
        "terrain": "islands",
        "mood": "bright",
        "color_story": ["sand", "sea blue", "palm green"],
        "boundary_style": "shoreline and boardwalk fencing",
        "spawn_anchor": "pier gate",
        "objective_anchor": "beach plaza",
        "module_family_bias": ["boardwalk", "plaza", "bungalow", "market", "dock", "garden"],
    },
}

ART_STYLE_DEFAULTS = {
    "blocky": {"grid_size": 24, "height_step": 12},
    "pixel": {"grid_size": 16, "height_step": 8},
    "stylized": {"grid_size": 20, "height_step": 10},
    "clean-modular": {"grid_size": 24, "height_step": 12},
}

GAMEPLAY_DEFAULTS = {
    "exploration": {"navigation_pattern": "discover side paths and return to landmarks"},
    "queue": {"navigation_pattern": "one-directional advance with clear checkpoints"},
    "combat": {"navigation_pattern": "arena loops with flank routes and reset lanes"},
    "roleplay": {"navigation_pattern": "free roam with obvious social anchors"},
    "tycoon": {"navigation_pattern": "claim space, upgrade stations, re-route through unlocks"},
    "obby": {"navigation_pattern": "forward path with readable hazard cadence"},
}


@dataclass
class MatchRecord:
    value: Any
    evidence: str


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip().lower().replace("-", " "))


def first_match(prompt: str, options: dict[str, list[str]]) -> MatchRecord | None:
    prompt_norm = normalize_text(prompt)
    best: MatchRecord | None = None
    for value, keywords in options.items():
        for keyword in sorted(keywords, key=len, reverse=True):
            keyword_pattern = r"(?<!\w)" + re.escape(keyword).replace(r"\ ", r"\s+") + r"(?!\w)"
            if re.search(keyword_pattern, prompt_norm):
                if value == "flat" and re.search(r"\bflat\s+tops?\b", prompt_norm):
                    continue
                candidate = MatchRecord(value=value, evidence=keyword)
                if best is None or len(keyword) > len(best.evidence):
                    best = candidate
    return best


def parse_numeric_value(raw_value: str) -> int | None:
    raw_value = raw_value.strip().lower()
    if raw_value.isdigit():
        return int(raw_value)
    return NUMBER_WORDS.get(raw_value)


def extract_count(prompt: str, noun_pattern: str) -> MatchRecord | None:
    patterns = [
        rf"\b(\d+|{'|'.join(NUMBER_WORDS)})(?:\s+|-)+{noun_pattern}\b",
        rf"\b{noun_pattern}(?:\s+|-)+(\d+|{'|'.join(NUMBER_WORDS)})\b",
    ]
    for pattern in patterns:
        match = re.search(pattern, prompt, flags=re.IGNORECASE)
        if match:
            raw = match.group(1)
            value = parse_numeric_value(raw)
            if value is not None:
                return MatchRecord(value=value, evidence=match.group(0))
    return None


def extract_landmarks(prompt: str) -> list[MatchRecord]:
    prompt_norm = normalize_text(prompt)
    matches: list[MatchRecord] = []
    for landmark, keywords in LANDMARK_KEYWORDS.items():
        for keyword in keywords:
            if keyword in prompt_norm:
                matches.append(MatchRecord(value=landmark, evidence=keyword))
                break
    return matches


def fill_missing(explicit: dict[str, MatchRecord], prompt: str) -> dict[str, Any]:
    theme = explicit.get("theme", MatchRecord("cozy-town", "default cozy-town")).value
    art_style = explicit.get("art_style", MatchRecord("blocky", "default blocky")).value
    gameplay_focus = explicit.get("gameplay_focus", MatchRecord("exploration", "default exploration")).value
    layout = explicit.get("layout", MatchRecord("hub", "default hub")).value
    density = explicit.get("density", MatchRecord("medium", "default medium")).value
    detail = explicit.get("detail", MatchRecord("medium", "default medium")).value
    flora_style = explicit.get("flora_style", MatchRecord("", "default no flora style")).value

    theme_defaults = THEME_DEFAULTS[theme]
    art_defaults = ART_STYLE_DEFAULTS[art_style]
    gameplay_defaults = GAMEPLAY_DEFAULTS[gameplay_focus]

    terrain = explicit.get("terrain", MatchRecord(theme_defaults["terrain"], f"default from {theme} theme")).value
    mood = explicit.get("mood", MatchRecord(theme_defaults["mood"], f"default from {theme} theme")).value
    scale = explicit.get("scale", MatchRecord("medium", "default medium scale")).value
    boundary_style = theme_defaults["boundary_style"]
    spawn_anchor = theme_defaults["spawn_anchor"]
    objective_anchor = theme_defaults["objective_anchor"]
    default_module_count = 64 if scale == "large" else 36
    module_count = explicit.get("module_count", MatchRecord(default_module_count, f"default {default_module_count} snapped modules")).value

    default_district_count = 4 if scale == "large" else 3
    districts = explicit.get("district_count", MatchRecord(default_district_count, f"default {default_district_count} districts")).value
    main_routes = explicit.get("main_route_count", MatchRecord(1, "default one spine route")).value
    side_routes = explicit.get("side_route_count", MatchRecord(2 if layout in {"main-road", "branching"} else 1, "default side route count")).value
    landmark_count = explicit.get("landmark_count", MatchRecord(max(2, districts), "default landmarks tied to districts")).value

    module_families = theme_defaults["module_family_bias"][:]
    if layout in {"hub", "districts"} and "plaza" not in module_families:
        module_families.append("plaza")
    if gameplay_focus == "queue" and "checkpoint" not in module_families:
        module_families.append("checkpoint")
    if detail == "low":
        prop_budget = "light prop pass"
    elif detail == "high":
        prop_budget = "heavy prop pass"
    else:
        prop_budget = "medium prop pass"

    if density == "dense":
        open_space_ratio = 0.2
    elif density == "sparse":
        open_space_ratio = 0.45
    else:
        open_space_ratio = 0.32

    if flora_style == "mushroom-forest":
        if terrain != "mountains":
            terrain = "forest"
        if "mushroom_grove" not in module_families:
            module_families.append("mushroom_grove")
        if "fungal_clearing" not in module_families:
            module_families.append("fungal_clearing")
        if "eerie" == mood or theme == "ancient-tech":
            mood = "eerie"

    if flora_style == "giant-conifer-forest":
        if terrain != "snow":
            terrain = "snow"
        if "giant_tree_grove" not in module_families:
            module_families.append("giant_tree_grove")
        if "frozen_grove" not in module_families:
            module_families.append("frozen_grove")

    if theme == "ancient-tech":
        if "robot_ruin" not in module_families:
            module_families.append("robot_ruin")
        if "ancient_gate" not in module_families:
            module_families.append("ancient_gate")
        if scale == "large":
            landmark_count = max(landmark_count, 4)

    mountain_range_count = explicit.get("mountain_range_count", MatchRecord(3, "default three mountain ranges")).value
    valley_count = explicit.get("valley_count", MatchRecord(2, "default two valleys")).value
    ice_pillar_count = explicit.get("ice_pillar_count", MatchRecord(0, "default no ice pillars")).value
    water_feature = explicit.get("water_feature", MatchRecord("", "default dry world")).value
    section_mode = "single-zone"
    world_structure = "landmark-hub"

    prompt_norm = normalize_text(prompt)
    flat_top_pillars = bool(re.search(r"\bflat\s+tops?\b", prompt_norm))
    creator_store_foliage = flora_style == "giant-conifer-forest" or "giant trees" in prompt_norm or "giant tree" in prompt_norm
    if "lake" in prompt_norm and not water_feature:
        water_feature = "lake"

    if terrain == "mountains":
        world_structure = "triple-range-verticality" if mountain_range_count >= 3 else "mountain-spine"
        section_mode = "contiguous-sections"
        layout = "districts" if layout == "hub" else layout
        density = "sparse" if density == "medium" else density
        spawn_anchor = "summit arrival"
        objective_anchor = "ancient machine crown"
        boundary_style = "triple mountain walls, cliff shelves, and relic terraces"
        if "mountain_range" not in module_families:
            module_families.append("mountain_range")
        if "summit_plateau" not in module_families:
            module_families.append("summit_plateau")
        if "valley_floor" not in module_families:
            module_families.append("valley_floor")
        if "ridge_bridge" not in module_families:
            module_families.append("ridge_bridge")
        if water_feature == "lake" and "lake_basin" not in module_families:
            module_families.append("lake_basin")
        if scale == "large":
            module_count = max(module_count, 108)
            districts = max(districts, 6)
            landmark_count = max(landmark_count, 6)
            open_space_ratio = max(open_space_ratio, 0.42)

    if terrain == "snow":
        mood = "heroic" if mood == "cozy" else mood
        boundary_style = "glacier walls, frozen basins, and icy ridgelines"
        spawn_anchor = "snowfield arrival"
        objective_anchor = "ice crown"
        world_structure = "ice-pillar-crown"
        section_mode = "contiguous-sections"
        layout = "districts" if layout == "hub" else layout
        density = "sparse" if density == "medium" else density
        open_space_ratio = max(open_space_ratio, 0.4)
        mountain_range_count = max(mountain_range_count, 4 if ("peak" in prompt_norm or "pillar" in prompt_norm) else 3)
        ice_pillar_count = max(ice_pillar_count, 4 if ("peak" in prompt_norm or "pillar" in prompt_norm) else 0)
        if "ice_pillar" not in module_families:
            module_families.append("ice_pillar")
        if "glacier_bridge" not in module_families:
            module_families.append("glacier_bridge")
        if "snowfield" not in module_families:
            module_families.append("snowfield")
        if "frozen_grove" not in module_families:
            module_families.append("frozen_grove")
        if scale == "large":
            module_count = max(module_count, 96)
            landmark_count = max(landmark_count, 5)

    return {
        "theme": theme,
        "art_style": art_style,
        "terrain": terrain,
        "flora_style": flora_style,
        "layout": layout,
        "density": density,
        "detail": detail,
        "scale": scale,
        "mood": mood,
        "gameplay_focus": gameplay_focus,
        "district_count": districts,
        "module_count": module_count,
        "main_route_count": main_routes,
        "side_route_count": side_routes,
        "landmark_count": landmark_count,
        "grid_size": art_defaults["grid_size"],
        "height_step": art_defaults["height_step"],
        "color_story": theme_defaults["color_story"],
        "boundary_style": boundary_style,
        "spawn_anchor": spawn_anchor,
        "objective_anchor": objective_anchor,
        "module_families": module_families,
        "navigation_pattern": gameplay_defaults["navigation_pattern"],
        "prop_budget": prop_budget,
        "open_space_ratio": open_space_ratio,
        "world_structure": world_structure,
        "mountain_range_count": mountain_range_count,
        "valley_count": valley_count,
        "ice_pillar_count": ice_pillar_count,
        "flat_top_pillars": flat_top_pillars,
        "creator_store_foliage": creator_store_foliage,
        "water_feature": water_feature,
        "section_mode": section_mode,
        "validation_rules": [
            "Every path connector must terminate in a compatible connector.",
            "Every landmark must be reachable from spawn in under three route changes.",
            "No module should float or overlap after snap placement.",
            "Primary route must keep landmark sightlines at regular intervals.",
            "Gameplay-critical anchors must stay readable even in low-detail mode.",
            "Major elevation changes need readable approaches, terraces, or overlooks.",
        ],
        "source_prompt": prompt,
    }


def build_pipeline_steps(world_spec: dict[str, Any]) -> list[str]:
    steps = [
        "Parse the plain sentence into world tags, counts, and landmarks.",
        f"Choose the {world_spec['theme']} module kit in {world_spec['art_style']} style on a {world_spec['grid_size']}-stud grid.",
        f"Generate a {world_spec['layout']} layout with {world_spec['main_route_count']} main route(s) and {world_spec['side_route_count']} supporting branch(es).",
        f"Reserve {world_spec['landmark_count']} landmark slots and place spawn at {world_spec['spawn_anchor']}.",
        f"Snap districts and module families into place with {world_spec['density']} density and {world_spec['open_space_ratio']:.0%} open space.",
        f"Run a {world_spec['prop_budget']} using the palette {', '.join(world_spec['color_story'])}.",
        "Validate routing, landmark readability, connector compatibility, and boundary closure.",
    ]
    if world_spec["terrain"] == "mountains":
        steps.insert(
            3,
            f"Shape {world_spec['mountain_range_count']} mountain range(s), {world_spec['valley_count']} valley corridor(s), and the {world_spec['water_feature'] or 'primary basin'} before landmark dressing.",
        )
        if world_spec["section_mode"] != "single-zone":
            steps.insert(
                5,
                f"Organize the world into {world_spec['section_mode']} for summit, valleys, and lower basin traversal.",
            )
    if world_spec["terrain"] == "snow":
        steps.insert(
            3,
            f"Build {world_spec['ice_pillar_count'] or 4} giant ice pillar(s) with {'flat tops' if world_spec['flat_top_pillars'] else 'sculpted crowns'} into the original snow terrain field.",
        )
        if world_spec.get("creator_store_foliage"):
            steps.insert(
                6 if len(steps) > 6 else len(steps),
                "Populate tree and foliage zones with ready-made Creator Store assets after the original terrain pass.",
            )
    return steps


def build_result(prompt: str) -> dict[str, Any]:
    explicit_matches: dict[str, MatchRecord] = {}
    for field_name, field_catalog in TAG_CATALOG.items():
        match = first_match(prompt, field_catalog)
        if match:
            explicit_matches[field_name] = match

    for field_name, noun_pattern in {
        "main_route_count": r"(?:main\s+roads?|spine\s+roads?|main\s+streets?)",
        "side_route_count": r"(?:side\s+streets?|alleys|branches)",
        "district_count": r"(?:districts?|neighborhoods?|zones?)",
        "landmark_count": r"(?:landmarks?|anchors?)",
        "module_count": r"(?:tiles?|plots?|modules?)",
        "mountain_range_count": r"(?:mountain\s+ranges?|ranges?)",
        "valley_count": r"(?:valleys?)",
        "ice_pillar_count": r"(?:ice\s+pillars?|pillars?|peaks?)",
    }.items():
        match = extract_count(prompt, noun_pattern)
        if match:
            explicit_matches[field_name] = match

    landmark_matches = extract_landmarks(prompt)
    if landmark_matches:
        explicit_matches["landmarks"] = MatchRecord(
            value=[match.value for match in landmark_matches],
            evidence=", ".join(match.evidence for match in landmark_matches),
        )

    if "lake" in normalize_text(prompt):
        explicit_matches["water_feature"] = MatchRecord(value="lake", evidence="lake")

    world_spec = fill_missing(explicit_matches, prompt)
    if "landmarks" in explicit_matches:
        world_spec["landmarks"] = explicit_matches["landmarks"].value
    else:
        world_spec["landmarks"] = [world_spec["objective_anchor"].replace(" ", "_")]

    filled_gaps: dict[str, Any] = {}
    for key, value in world_spec.items():
        if key in explicit_matches or key in {"source_prompt", "validation_rules"}:
            continue
        filled_gaps[key] = value

    modular_plan = {
        "anchor_order": [
            world_spec["spawn_anchor"],
            *[landmark.replace("_", " ") for landmark in world_spec["landmarks"]],
            world_spec["objective_anchor"],
        ],
        "module_families": world_spec["module_families"],
        "placement_rules": [
            "Buildings should face the primary route or a plaza edge.",
            "Dead ends require a visual payoff module such as a tower, prop cluster, or gate.",
            "Back-of-house modules should not block landmark sightlines.",
            "Boundary modules should close silhouettes before prop dressing begins.",
        ],
    }

    return {
        "prompt": prompt,
        "explicit_config": {key: asdict(value) for key, value in explicit_matches.items()},
        "filled_gaps": filled_gaps,
        "world_spec": world_spec,
        "modular_plan": modular_plan,
        "pipeline_steps": build_pipeline_steps(world_spec),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract modular world configuration from a regular sentence and fill the missing fields."
    )
    parser.add_argument("--prompt", required=True, help="Plain-language world prompt.")
    parser.add_argument("--json-out", default="", help="Optional JSON output file.")
    parser.add_argument("--indent", type=int, default=2, help="JSON indentation.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    result = build_result(args.prompt)
    payload = json.dumps(result, indent=args.indent, ensure_ascii=True)
    if args.json_out:
        output_path = Path(args.json_out)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(payload + "\n", encoding="utf-8")
    print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
