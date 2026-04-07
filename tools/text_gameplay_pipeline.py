from __future__ import annotations

import argparse
import json
import math
import re
from dataclasses import asdict
from pathlib import Path
from typing import Any

try:
    from text_world_pipeline import MatchRecord, build_result as build_world_result, extract_count, first_match
except ImportError:  # pragma: no cover - fallback for module execution styles
    from tools.text_world_pipeline import MatchRecord, build_result as build_world_result, extract_count, first_match


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


GAMEPLAY_TAG_CATALOG = {
    "core_loop": {
        "queue-ladder": ["waiting in line", "wait in line", "queue", "line game", "move up in line"],
        "upgrade-tycoon": ["tycoon", "upgrade path", "build up", "collect and upgrade"],
        "combat-arena": ["arena", "battleground", "fight", "combat", "duel"],
        "exploration-route": ["explore", "exploration", "discover", "journey"],
        "social-roleplay": ["roleplay", "hang out", "social", "live in"],
        "obby-checkpoints": ["obby", "checkpoint", "platformer", "finish line"],
    },
    "interaction_mode": {
        "solo": ["solo", "singleplayer", "alone"],
        "co-op": ["co-op", "coop", "team up", "together"],
        "competitive": ["competitive", "versus", "rivals", "against", "race"],
        "social-shared": ["social", "hang out", "public", "shared", "roleplay"],
    },
    "session_shape": {
        "short-rounds": ["rounds", "quick", "short rounds", "fast matches"],
        "mid-session": ["session", "run", "medium", "steady"],
        "persistent": ["persistent", "always on", "open world", "idle"],
    },
    "economy_model": {
        "tickets": ["tickets", "ticket"],
        "coins": ["coins", "coin"],
        "cash": ["cash", "money", "bucks", "dollars"],
        "credits": ["credits", "credit"],
        "resources": ["resources", "ore", "wood", "loot"],
        "none": ["no money", "no economy", "without currency"],
    },
    "reward_model": {
        "steady-income": ["earn over time", "income", "passive income", "steady"],
        "jackpot-finale": ["jackpot", "big payout", "at the end", "final reward", "meet at the end"],
        "drop-loot": ["loot", "drops", "drop rewards"],
        "cosmetic-expression": ["cosmetic", "dress up", "style", "decorate"],
        "rank-progression": ["rank up", "level up", "progression", "mastery"],
    },
    "failure_state": {
        "soft-reset": ["reset", "go back", "lose progress", "fall back"],
        "hard-elimination": ["elimination", "knockout", "deadly", "last one standing"],
        "checkpoint-reset": ["checkpoint reset", "respawn", "respawn at checkpoint"],
        "no-fail": ["no fail", "can't lose", "safe"],
    },
    "gating_style": {
        "cost-gate": ["costs more to move ahead", "requires more money", "pay to move", "pays more", "cost more", "buy ahead", "unlock with money"],
        "time-gate": ["wait", "timer", "cooldown", "every few seconds"],
        "skill-gate": ["harder", "skill", "precision", "beat the challenge"],
        "level-gate": ["level gate", "level requirement", "higher level"],
        "objective-gate": ["complete objective", "finish task", "clear wave"],
    },
    "player_motion": {
        "locked-slots": ["locked in place", "stuck in place", "one spot", "fixed position"],
        "free-roam": ["free roam", "walk around", "open movement"],
        "lane-based": ["lanes", "track", "corridor"],
        "arena-movement": ["arena", "dash", "fight around"],
        "checkpoint-forward": ["move forward", "advance", "push ahead"],
    },
    "occupancy_model": {
        "one-per-slot": ["one player per spot", "one person per spot", "50 people", "50 players", "one player per tile"],
        "claimed-zones": ["claim", "my plot", "own area"],
        "shared-space": ["shared", "public", "together", "same area"],
        "team-lanes": ["teams", "lanes", "left team", "right team"],
    },
    "advancement_rule": {
        "purchase-advance": ["pay to move ahead", "buy forward", "costs more to move ahead"],
        "auto-advance": ["move up in place", "automatically move", "advance every"],
        "objective-unlock": ["complete objective", "unlock next", "clear stage"],
        "win-advance": ["winner advances", "win to move up", "beat the other player"],
    },
    "pacing": {
        "chill": ["chill", "casual", "relaxed"],
        "steady": ["steady", "consistent", "medium pace"],
        "tense": ["tense", "high pressure", "stressful"],
        "burst": ["burst", "fast", "quick"],
    },
    "objective_style": {
        "reach-finale": ["reach the end", "at the end", "front of the line", "finish line"],
        "survive": ["survive", "last one standing", "stay alive"],
        "defeat-opponents": ["fight", "defeat", "kill", "beat players"],
        "collect-and-scale": ["collect", "gather", "farm", "upgrade"],
        "express-and-socialize": ["social", "roleplay", "show off", "dress up"],
    },
}

FOCUS_GAMEPLAY_DEFAULTS = {
    "queue": {
        "core_loop": "queue-ladder",
        "interaction_mode": "social-shared",
        "session_shape": "mid-session",
        "economy_model": "tickets",
        "reward_model": "jackpot-finale",
        "failure_state": "soft-reset",
        "gating_style": "cost-gate",
        "player_motion": "locked-slots",
        "occupancy_model": "one-per-slot",
        "advancement_rule": "purchase-advance",
        "pacing": "steady",
        "objective_style": "reach-finale",
        "currency_name": "Tickets",
        "zone_roles": ["spawn_entry", "queue_slots", "income_nodes", "finale_pad", "exit_reset"],
        "required_modules": ["queue_slot", "checkpoint_gate", "income_marker", "reward_pad", "exit_lane"],
        "loop_beats": ["join", "claim slot", "earn currency", "pay to advance", "reach finale", "reset or replay"],
    },
    "tycoon": {
        "core_loop": "upgrade-tycoon",
        "interaction_mode": "social-shared",
        "session_shape": "persistent",
        "economy_model": "cash",
        "reward_model": "rank-progression",
        "failure_state": "no-fail",
        "gating_style": "cost-gate",
        "player_motion": "free-roam",
        "occupancy_model": "claimed-zones",
        "advancement_rule": "purchase-advance",
        "pacing": "steady",
        "objective_style": "collect-and-scale",
        "currency_name": "Cash",
        "zone_roles": ["spawn_entry", "claim_zone", "production_lane", "shop_node", "prestige_or_showcase"],
        "required_modules": ["claim_plot", "generator_pad", "upgrade_station", "shopfront", "showcase"],
        "loop_beats": ["claim", "produce", "collect", "upgrade", "expand", "prestige or flex"],
    },
    "combat": {
        "core_loop": "combat-arena",
        "interaction_mode": "competitive",
        "session_shape": "short-rounds",
        "economy_model": "credits",
        "reward_model": "rank-progression",
        "failure_state": "hard-elimination",
        "gating_style": "skill-gate",
        "player_motion": "arena-movement",
        "occupancy_model": "shared-space",
        "advancement_rule": "win-advance",
        "pacing": "tense",
        "objective_style": "defeat-opponents",
        "currency_name": "Credits",
        "zone_roles": ["spawn_lobby", "loadout_zone", "arena_core", "flank_lane", "reward_exit"],
        "required_modules": ["spawn_room", "loadout_pad", "arena", "cover_lane", "reward_room"],
        "loop_beats": ["load in", "gear up", "fight", "win or lose", "cash out", "requeue"],
    },
    "roleplay": {
        "core_loop": "social-roleplay",
        "interaction_mode": "social-shared",
        "session_shape": "persistent",
        "economy_model": "cash",
        "reward_model": "cosmetic-expression",
        "failure_state": "no-fail",
        "gating_style": "objective-gate",
        "player_motion": "free-roam",
        "occupancy_model": "shared-space",
        "advancement_rule": "objective-unlock",
        "pacing": "chill",
        "objective_style": "express-and-socialize",
        "currency_name": "Cash",
        "zone_roles": ["town_entry", "social_square", "home_strip", "shop_strip", "event_anchor"],
        "required_modules": ["entry_gate", "plaza", "home_block", "shopfront", "stage"],
        "loop_beats": ["arrive", "socialize", "customize", "visit locations", "show off", "return to hub"],
    },
    "obby": {
        "core_loop": "obby-checkpoints",
        "interaction_mode": "solo",
        "session_shape": "short-rounds",
        "economy_model": "none",
        "reward_model": "rank-progression",
        "failure_state": "checkpoint-reset",
        "gating_style": "skill-gate",
        "player_motion": "checkpoint-forward",
        "occupancy_model": "shared-space",
        "advancement_rule": "objective-unlock",
        "pacing": "burst",
        "objective_style": "reach-finale",
        "currency_name": "Medals",
        "zone_roles": ["start_pad", "obstacle_chain", "checkpoint_chain", "finale_pad", "reset_lane"],
        "required_modules": ["start_pad", "hazard_lane", "checkpoint", "finish_pad", "reset_pad"],
        "loop_beats": ["start", "clear obstacle", "reach checkpoint", "finish", "restart"],
    },
    "exploration": {
        "core_loop": "exploration-route",
        "interaction_mode": "solo",
        "session_shape": "mid-session",
        "economy_model": "resources",
        "reward_model": "drop-loot",
        "failure_state": "soft-reset",
        "gating_style": "objective-gate",
        "player_motion": "free-roam",
        "occupancy_model": "shared-space",
        "advancement_rule": "objective-unlock",
        "pacing": "chill",
        "objective_style": "collect-and-scale",
        "currency_name": "Supplies",
        "zone_roles": ["spawn_hub", "route_markers", "resource_nodes", "landmark_reward", "return_hub"],
        "required_modules": ["hub", "trail", "resource_node", "vista", "cache"],
        "loop_beats": ["set out", "discover", "collect", "return", "upgrade route knowledge"],
    },
}

CURRENCY_KEYWORDS = [
    ("Tickets", ["tickets", "ticket"]),
    ("Cash", ["cash", "money", "bucks"]),
    ("Coins", ["coins", "coin"]),
    ("Credits", ["credits", "credit"]),
    ("Points", ["points", "score"]),
    ("Tokens", ["tokens", "token"]),
]

FINALE_ROLE_KEYWORDS = {
    "host": ["host", "character", "npc", "judge"],
    "boss": ["boss", "villain"],
    "shopkeeper": ["shopkeeper", "merchant"],
    "friend": ["friend", "ally"],
}


def extract_currency_name(prompt: str, default_name: str) -> str:
    prompt_lower = prompt.lower()
    for currency_name, keywords in CURRENCY_KEYWORDS:
        if any(keyword in prompt_lower for keyword in keywords):
            return currency_name
    return default_name


def extract_finale_role(prompt: str) -> MatchRecord | None:
    prompt_lower = prompt.lower()
    for role, keywords in FINALE_ROLE_KEYWORDS.items():
        for keyword in keywords:
            if keyword in prompt_lower:
                return MatchRecord(value=role, evidence=keyword)
    return None


def parse_numeric_token(raw_value: str) -> int | None:
    value = raw_value.strip().lower()
    if value.isdigit():
        return int(value)
    return NUMBER_WORDS.get(value)


def extract_special_count(prompt: str, noun_pattern: str) -> MatchRecord | None:
    number_pattern = "|".join(NUMBER_WORDS)
    patterns = [
        rf"\b(\d+|{number_pattern})[-\s]+{noun_pattern}\b",
        rf"\b{noun_pattern}[-\s]+(\d+|{number_pattern})\b",
    ]
    for pattern in patterns:
        match = re.search(pattern, prompt, flags=re.IGNORECASE)
        if match:
            value = parse_numeric_token(match.group(1))
            if value is not None:
                return MatchRecord(value=value, evidence=match.group(0))
    return None


def resolve_focus_defaults(world_result: dict[str, Any]) -> dict[str, Any]:
    focus = world_result["world_spec"]["gameplay_focus"]
    return FOCUS_GAMEPLAY_DEFAULTS.get(focus, FOCUS_GAMEPLAY_DEFAULTS["exploration"])


def fill_gameplay_defaults(explicit: dict[str, MatchRecord], world_result: dict[str, Any], gameplay_prompt: str) -> dict[str, Any]:
    world_spec = world_result["world_spec"]
    defaults = resolve_focus_defaults(world_result)

    gameplay_spec = {
        "core_loop": explicit.get("core_loop", MatchRecord(defaults["core_loop"], "default from world gameplay focus")).value,
        "interaction_mode": explicit.get("interaction_mode", MatchRecord(defaults["interaction_mode"], "default from world gameplay focus")).value,
        "session_shape": explicit.get("session_shape", MatchRecord(defaults["session_shape"], "default from world gameplay focus")).value,
        "economy_model": explicit.get("economy_model", MatchRecord(defaults["economy_model"], "default from world gameplay focus")).value,
        "reward_model": explicit.get("reward_model", MatchRecord(defaults["reward_model"], "default from world gameplay focus")).value,
        "failure_state": explicit.get("failure_state", MatchRecord(defaults["failure_state"], "default from world gameplay focus")).value,
        "gating_style": explicit.get("gating_style", MatchRecord(defaults["gating_style"], "default from world gameplay focus")).value,
        "player_motion": explicit.get("player_motion", MatchRecord(defaults["player_motion"], "default from world gameplay focus")).value,
        "occupancy_model": explicit.get("occupancy_model", MatchRecord(defaults["occupancy_model"], "default from world gameplay focus")).value,
        "advancement_rule": explicit.get("advancement_rule", MatchRecord(defaults["advancement_rule"], "default from world gameplay focus")).value,
        "pacing": explicit.get("pacing", MatchRecord(defaults["pacing"], "default from world gameplay focus")).value,
        "objective_style": explicit.get("objective_style", MatchRecord(defaults["objective_style"], "default from world gameplay focus")).value,
        "player_capacity": explicit.get("player_capacity", MatchRecord(12, "default twelve players")).value,
        "checkpoint_count": explicit.get("checkpoint_count", MatchRecord(max(3, world_spec["landmark_count"]), "default tied to landmarks")).value,
        "stage_count": explicit.get("stage_count", MatchRecord(max(3, world_spec["district_count"]), "default tied to districts")).value,
        "upgrade_count": explicit.get("upgrade_count", MatchRecord(5, "default five upgrades")).value,
        "round_count": explicit.get("round_count", MatchRecord(3, "default three rounds")).value,
        "currency_name": extract_currency_name(gameplay_prompt, defaults["currency_name"]),
        "zone_roles": defaults["zone_roles"][:],
        "required_modules": defaults["required_modules"][:],
        "loop_beats": defaults["loop_beats"][:],
        "source_prompt": gameplay_prompt,
    }

    if gameplay_spec["core_loop"] == "queue-ladder":
        gameplay_spec["checkpoint_count"] = max(gameplay_spec["checkpoint_count"], gameplay_spec["player_capacity"])
        gameplay_spec["stage_count"] = max(3, math.ceil(gameplay_spec["checkpoint_count"] / max(1, world_spec["main_route_count"] + world_spec["side_route_count"])))
        gameplay_spec["upgrade_count"] = max(gameplay_spec["upgrade_count"], 3)
    elif gameplay_spec["core_loop"] == "obby-checkpoints":
        gameplay_spec["checkpoint_count"] = max(gameplay_spec["checkpoint_count"], 8)
    elif gameplay_spec["core_loop"] == "upgrade-tycoon":
        gameplay_spec["upgrade_count"] = max(gameplay_spec["upgrade_count"], 8)

    return gameplay_spec


def reconcile_gameplay_prompt_signals(gameplay_spec: dict[str, Any], gameplay_prompt: str) -> None:
    prompt_lower = gameplay_prompt.lower()
    if any(token in prompt_lower for token in ["pay", "pays more", "cost", "costs more", "requires more money", "buy ahead"]):
        gameplay_spec["gating_style"] = "cost-gate"
        gameplay_spec["advancement_rule"] = "purchase-advance"
    if gameplay_spec["core_loop"] == "queue-ladder" and gameplay_spec["player_capacity"] > gameplay_spec["checkpoint_count"]:
        gameplay_spec["checkpoint_count"] = gameplay_spec["player_capacity"]


def build_world_binding(gameplay_spec: dict[str, Any], world_result: dict[str, Any]) -> dict[str, Any]:
    world_spec = world_result["world_spec"]
    modular_plan = world_result["modular_plan"]
    required_module_families = sorted(set(world_spec["module_families"]) | set(gameplay_spec["required_modules"]))

    base_module_count = world_spec["module_count"]
    if gameplay_spec["core_loop"] == "queue-ladder":
        required_module_count = max(base_module_count, gameplay_spec["checkpoint_count"] + 8)
    elif gameplay_spec["core_loop"] == "obby-checkpoints":
        required_module_count = max(base_module_count, gameplay_spec["checkpoint_count"] + 6)
    else:
        required_module_count = max(base_module_count, world_spec["district_count"] * 8)

    if gameplay_spec["core_loop"] == "queue-ladder":
        zone_ratios = {
            "spawn_entry": 0.08,
            "queue_slots": 0.55,
            "income_nodes": 0.12,
            "finale_pad": 0.15,
            "exit_reset": 0.10,
        }
    elif gameplay_spec["core_loop"] == "upgrade-tycoon":
        zone_ratios = {
            "spawn_entry": 0.10,
            "claim_zone": 0.18,
            "production_lane": 0.34,
            "shop_node": 0.18,
            "prestige_or_showcase": 0.20,
        }
    elif gameplay_spec["core_loop"] == "combat-arena":
        zone_ratios = {
            "spawn_lobby": 0.12,
            "loadout_zone": 0.12,
            "arena_core": 0.46,
            "flank_lane": 0.18,
            "reward_exit": 0.12,
        }
    elif gameplay_spec["core_loop"] == "social-roleplay":
        zone_ratios = {
            "town_entry": 0.10,
            "social_square": 0.24,
            "home_strip": 0.28,
            "shop_strip": 0.18,
            "event_anchor": 0.20,
        }
    elif gameplay_spec["core_loop"] == "obby-checkpoints":
        zone_ratios = {
            "start_pad": 0.10,
            "obstacle_chain": 0.45,
            "checkpoint_chain": 0.20,
            "finale_pad": 0.15,
            "reset_lane": 0.10,
        }
    else:
        zone_ratios = {
            "spawn_hub": 0.16,
            "route_markers": 0.28,
            "resource_nodes": 0.22,
            "landmark_reward": 0.18,
            "return_hub": 0.16,
        }

    zone_allocations = []
    anchors = modular_plan["anchor_order"]
    for index, zone_role in enumerate(gameplay_spec["zone_roles"]):
        module_budget = max(1, round(required_module_count * zone_ratios.get(zone_role, 0.1)))
        anchor = anchors[min(index, len(anchors) - 1)]
        zone_allocations.append(
            {
                "zone_role": zone_role,
                "anchor": anchor,
                "module_budget": module_budget,
                "preferred_world_modules": required_module_families[max(0, index - 1) : min(len(required_module_families), index + 3)],
            }
        )

    integrated_world_spec = dict(world_spec)
    integrated_world_spec["module_count"] = required_module_count
    integrated_world_spec["module_families"] = required_module_families
    integrated_world_spec["required_zone_roles"] = gameplay_spec["zone_roles"]
    integrated_world_spec["gameplay_binding"] = {
        "currency_name": gameplay_spec["currency_name"],
        "loop_beats": gameplay_spec["loop_beats"],
        "zone_allocations": zone_allocations,
    }

    throughput_rules = [
        f"Support up to {gameplay_spec['player_capacity']} concurrent players in the authored loop.",
        f"Route gameplay through {gameplay_spec['checkpoint_count']} checkpoint or position node(s).",
        "Keep spawn, first action, and first reward within a single readable route chain.",
        "Do not place economy, fail, or finale interactions behind ambiguous navigation choices.",
    ]
    if gameplay_spec["occupancy_model"] == "one-per-slot":
        throughput_rules.append("Every progression slot must advertise exclusive occupancy and a clear upgrade target.")
    if gameplay_spec["player_motion"] == "locked-slots":
        throughput_rules.append("Lock player movement only after the slot or checkpoint is visibly claimed.")

    return {
        "required_module_families": required_module_families,
        "integrated_world_spec": integrated_world_spec,
        "zone_allocations": zone_allocations,
        "throughput_rules": throughput_rules,
        "binding_notes": [
            f"Bind the primary loop to the world anchor chain: {' -> '.join(modular_plan['anchor_order'])}.",
            f"Use {world_spec['layout']} routing to stage the {gameplay_spec['core_loop']} loop without breaking landmark readability.",
            f"Extend the world from {world_spec['module_count']} to {required_module_count} modules if the gameplay capacity demands it.",
        ],
    }


def build_gameplay_pipeline_steps(gameplay_spec: dict[str, Any], world_binding: dict[str, Any]) -> list[str]:
    return [
        "Parse the sentence into gameplay loop, progression, economy, and occupancy signals.",
        "Pull the modular world spec and inherit its anchors, layout, and module families.",
        f"Choose the {gameplay_spec['core_loop']} loop with {gameplay_spec['interaction_mode']} interaction and {gameplay_spec['session_shape']} session shape.",
        f"Allocate {len(world_binding['zone_allocations'])} gameplay zones across {world_binding['integrated_world_spec']['module_count']} modular world slots.",
        f"Bind rewards to {gameplay_spec['currency_name']} using the {gameplay_spec['reward_model']} reward curve and {gameplay_spec['gating_style']} gating.",
        f"Route players with {gameplay_spec['player_motion']} motion and {gameplay_spec['occupancy_model']} occupancy rules.",
        "Validate throughput, first-time readability, recovery after failure, and finale clarity.",
    ]


def build_result(gameplay_prompt: str, world_prompt: str | None = None) -> dict[str, Any]:
    effective_world_prompt = world_prompt or gameplay_prompt
    world_result = build_world_result(effective_world_prompt)

    explicit_matches: dict[str, MatchRecord] = {}
    for field_name, catalog in GAMEPLAY_TAG_CATALOG.items():
        match = first_match(gameplay_prompt, catalog)
        if match:
            explicit_matches[field_name] = match

    for field_name, noun_pattern in {
        "player_capacity": r"(?:players?|people)",
        "checkpoint_count": r"(?:checkpoints?|positions?|tiles?|slots?)",
        "stage_count": r"(?:stages?|zones?|acts?|areas?)",
        "upgrade_count": r"(?:upgrades?|tiers?)",
        "round_count": r"(?:rounds?|waves?)",
    }.items():
        if field_name == "player_capacity":
            match = extract_special_count(gameplay_prompt, noun_pattern)
        else:
            match = extract_count(gameplay_prompt, noun_pattern)
        if match:
            explicit_matches[field_name] = match

    finale_role = extract_finale_role(gameplay_prompt)
    if finale_role:
        explicit_matches["finale_role"] = finale_role

    gameplay_spec = fill_gameplay_defaults(explicit_matches, world_result, gameplay_prompt)
    reconcile_gameplay_prompt_signals(gameplay_spec, gameplay_prompt)
    if "finale_role" in explicit_matches:
        gameplay_spec["finale_role"] = explicit_matches["finale_role"].value
    else:
        gameplay_spec["finale_role"] = "host"

    filled_gaps = {}
    for key, value in gameplay_spec.items():
        if key in explicit_matches or key == "source_prompt":
            continue
        filled_gaps[key] = value

    world_binding = build_world_binding(gameplay_spec, world_result)

    return {
        "gameplay_prompt": gameplay_prompt,
        "world_prompt": effective_world_prompt,
        "explicit_gameplay_config": {key: asdict(value) for key, value in explicit_matches.items()},
        "filled_gameplay_gaps": filled_gaps,
        "gameplay_spec": gameplay_spec,
        "world_binding": world_binding,
        "world_result": world_result,
        "gameplay_pipeline_steps": build_gameplay_pipeline_steps(gameplay_spec, world_binding),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract gameplay structure from a regular sentence and bind it onto the modular world pipeline."
    )
    parser.add_argument("--gameplay-prompt", required=True, help="Plain-language gameplay prompt.")
    parser.add_argument("--world-prompt", default="", help="Optional world prompt. Defaults to the gameplay prompt.")
    parser.add_argument("--json-out", default="", help="Optional JSON output file.")
    parser.add_argument("--indent", type=int, default=2, help="JSON indentation.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    result = build_result(args.gameplay_prompt, args.world_prompt or None)
    payload = json.dumps(result, indent=args.indent, ensure_ascii=True)
    if args.json_out:
        output_path = Path(args.json_out)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(payload + "\n", encoding="utf-8")
    print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
