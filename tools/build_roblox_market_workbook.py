from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import re
import statistics
import time
import uuid
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any

import requests
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill
from openpyxl.utils import get_column_letter


FANDOM_WIKITEXT_URL = "https://roblox.fandom.com/api.php"
FANDOM_RANKINGS_URL = "https://roblox.fandom.com/wiki/List_of_most-visited_Roblox_experiences_per_month"
ROBLOX_SEARCH_URL = "https://apis.roblox.com/search-api/omni-search"
ROBLOX_GAMES_URL = "https://games.roblox.com/v1/games"

REQUEST_HEADERS = {"User-Agent": "Mozilla/5.0"}

SEARCH_ALIASES = {
    "All Star Tower Defense X": "ASTD X",
    "Fish It!": "Fish It",
    "Plants Vs Brainrots": "Plants & Brainrots",
}

GAME_TYPE_OVERRIDES = {
    "99 Nights in the Forest": "Survival_Adventure",
    "Adopt Me!": "Roleplay_Social",
    "All Star Tower Defense X": "Strategy_TowerDefense",
    "Arise Crossover": "RPG_Progression",
    "Blox Fruits": "RPG_Progression",
    "Blue Lock: Rivals": "Sports_Competitive",
    "Brookhaven RP": "Roleplay_Social",
    "Dandy's World": "Survival_Horror",
    "Dead Rails": "Survival_Adventure",
    "Dress to Impress": "Fashion_Social",
    "Fisch": "Simulation_Fishing",
    "Fish It!": "Simulation_Fishing",
    "Forsaken": "Survival_Horror",
    "Grow a Garden": "Simulation_Tycoon",
    "Ink Game": "Party_Elimination",
    "Murder Mystery 2": "SocialDeduction_Survival",
    "Plants Vs Brainrots": "Simulation_Tycoon",
    "RIVALS": "Shooter_Competitive",
    "Shrimp Game": "Party_Elimination",
    "Squid Game X": "Party_Elimination",
    "Steal a Brainrot": "Simulation_Tycoon",
    "The Forge": "RPG_Crafting",
    "The Strongest Battlegrounds": "Fighting_Battlegrounds",
}

GAME_SUMMARIES = {
    "99 Nights in the Forest": (
        "Co-op survival game about building a camp and enduring increasingly dangerous nights.",
        "Gather resources, fortify camp, and survive each night with your team.",
    ),
    "Adopt Me!": (
        "Social collection game built around pets, homes, trading, and light roleplay.",
        "Raise and trade pets, decorate homes, and socialize in a friendly sandbox.",
    ),
    "All Star Tower Defense X": (
        "Anime tower defense game focused on summoning units and clearing wave-based stages.",
        "Collect strong units, place them well, and survive enemy waves efficiently.",
    ),
    "Arise Crossover": (
        "Anime-flavored progression simulator where players grind enemies and scale their power.",
        "Farm enemies, unlock stronger powers, and push into harder zones.",
    ),
    "Blox Fruits": (
        "Large-scale anime action RPG with combat, exploration, bosses, and power progression.",
        "Level up, collect fruits, sail between zones, and beat stronger enemies.",
    ),
    "Blue Lock: Rivals": (
        "Competitive soccer game inspired by Blue Lock with character classes and flashy plays.",
        "Win high-pressure matches and outplay other teams with better positioning and timing.",
    ),
    "Brookhaven RP": (
        "Open roleplay town where players hang out, drive, own homes, and improvise stories.",
        "Create social scenarios, customize your life in town, and roleplay with friends.",
    ),
    "Dandy's World": (
        "Mascot-horror co-op survival game about completing machines while descending deeper into danger.",
        "Work together, finish objectives, and survive the threats in each layer.",
    ),
    "Dead Rails": (
        "Co-op zombie survival adventure built around trains, loot runs, and long forward pushes.",
        "Keep the run alive, gather supplies, and reach safety through hostile territory.",
    ),
    "Dress to Impress": (
        "Runway fashion competition where players style outfits to match themed prompts.",
        "Build the best look for the prompt and earn votes from the lobby.",
    ),
    "Fisch": (
        "Exploration-heavy fishing game with rare catches, progression, and collection goals.",
        "Catch better fish, unlock upgrades, and fill out increasingly rare collections.",
    ),
    "Fish It!": (
        "Fast-moving fishing progression game with trading, gear upgrades, and event content.",
        "Catch valuable fish, flip rewards into stronger gear, and expand your collection.",
    ),
    "Forsaken": (
        "Asymmetrical survival horror game where survivors complete objectives while a killer hunts them.",
        "Either out-survive the killer or eliminate everyone before time runs out.",
    ),
    "Grow a Garden": (
        "Idle-friendly farming tycoon where seeds, crop growth, and profit loops drive progression.",
        "Plant valuable crops, optimize your garden, and reinvest into faster growth.",
    ),
    "Ink Game": (
        "Squid Game-style elimination party game built around deadly challenge rounds.",
        "Stay alive through the minigames and be one of the last players standing.",
    ),
    "Murder Mystery 2": (
        "Round-based social survival game with Innocent, Sheriff, and Murderer roles.",
        "Read the room, survive the round, and use your role well.",
    ),
    "Plants Vs Brainrots": (
        "Garden tycoon parody where planted units generate money and fight for you.",
        "Plant stronger units, generate more income, and snowball your garden economy.",
    ),
    "RIVALS": (
        "Skill-first FPS duel game that scales from 1v1 fights to small-team matches.",
        "Win aim-heavy rounds, unlock better loadouts, and outshoot your opponents.",
    ),
    "Shrimp Game": (
        "Squid Game-inspired elimination game with a queue of familiar survival minigames.",
        "Survive each round, avoid instant losses, and outlast the lobby.",
    ),
    "Squid Game X": (
        "Large-scale elimination party game with multiple Squid Game-inspired modes and twists.",
        "Clear the round sequence and avoid getting eliminated before the finale.",
    ),
    "Steal a Brainrot": (
        "Chaotic tycoon built around buying units, stealing from rivals, and rebirthing for more power.",
        "Generate cash, steal value from other players, and loop into stronger upgrades.",
    ),
    "The Forge": (
        "Crafting-heavy RPG about mining ore, forging gear, and fighting with custom builds.",
        "Mine materials, forge stronger equipment, and tune your build for combat.",
    ),
    "The Strongest Battlegrounds": (
        "Arena fighter focused on flashy anime-style combos, duels, and character mastery.",
        "Win fights consistently by mastering movement, timing, and damage routes.",
    ),
}

TYPE_BASES = {
    "Roleplay_Social": {"session_minutes": 23.0, "retention_30d": 0.34, "payer_rate": 0.021, "arppu": 17.0},
    "Strategy_TowerDefense": {"session_minutes": 24.0, "retention_30d": 0.31, "payer_rate": 0.028, "arppu": 21.0},
    "RPG_Progression": {"session_minutes": 27.0, "retention_30d": 0.33, "payer_rate": 0.029, "arppu": 22.0},
    "Sports_Competitive": {"session_minutes": 20.0, "retention_30d": 0.25, "payer_rate": 0.016, "arppu": 15.0},
    "Survival_Horror": {"session_minutes": 19.0, "retention_30d": 0.24, "payer_rate": 0.016, "arppu": 14.0},
    "Survival_Adventure": {"session_minutes": 21.0, "retention_30d": 0.27, "payer_rate": 0.018, "arppu": 15.0},
    "Fashion_Social": {"session_minutes": 18.0, "retention_30d": 0.27, "payer_rate": 0.022, "arppu": 16.0},
    "Simulation_Fishing": {"session_minutes": 20.0, "retention_30d": 0.29, "payer_rate": 0.024, "arppu": 19.0},
    "Simulation_Tycoon": {"session_minutes": 19.0, "retention_30d": 0.28, "payer_rate": 0.033, "arppu": 23.0},
    "Party_Elimination": {"session_minutes": 16.0, "retention_30d": 0.22, "payer_rate": 0.013, "arppu": 12.0},
    "SocialDeduction_Survival": {"session_minutes": 18.0, "retention_30d": 0.24, "payer_rate": 0.015, "arppu": 13.0},
    "Shooter_Competitive": {"session_minutes": 22.0, "retention_30d": 0.28, "payer_rate": 0.019, "arppu": 15.0},
    "RPG_Crafting": {"session_minutes": 24.0, "retention_30d": 0.30, "payer_rate": 0.026, "arppu": 20.0},
    "Fighting_Battlegrounds": {"session_minutes": 21.0, "retention_30d": 0.27, "payer_rate": 0.018, "arppu": 15.0},
}

HEADER_FILL = PatternFill(fill_type="solid", fgColor="1F4E78")
HEADER_FONT = Font(color="FFFFFF", bold=True)


@dataclass
class MonthlyChartEntry:
    month: str
    rank: int
    experience: str
    monthly_visits: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build an Excel workbook with monthly Roblox chart leaders and live official stats."
    )
    parser.add_argument(
        "--year",
        type=int,
        default=date.today().year - 1,
        help="Calendar year to compile. Defaults to the most recent full year.",
    )
    parser.add_argument(
        "--output",
        default="",
        help="Optional output workbook path. Defaults to docs/roblox_top_experiences_<year>.xlsx",
    )
    return parser.parse_args()


def canonicalize_title(title: str) -> str:
    title = title.lower()
    title = title.replace("&", " and ")
    title = re.sub(r"\[[^\]]*\]", " ", title)
    title = re.sub(r"[^a-z0-9]+", " ", title)
    return " ".join(title.split())


def parse_visit_label(raw_value: str, raw_unit: str) -> int:
    scale = 1_000_000_000 if raw_unit == "B" else 1_000_000
    return int(float(raw_value) * scale)


def fetch_rankings_wikitext() -> str:
    response = requests.get(
        FANDOM_WIKITEXT_URL,
        params={
            "action": "parse",
            "page": "List_of_most-visited_Roblox_experiences_per_month",
            "prop": "wikitext",
            "formatversion": "2",
            "format": "json",
        },
        headers=REQUEST_HEADERS,
        timeout=30,
    )
    response.raise_for_status()
    return response.json()["parse"]["wikitext"]


def parse_chart_year(wikitext: str, year: int) -> list[MonthlyChartEntry]:
    section_start = f"== {year} =="
    section_end = f"== {year + 1} =="
    if section_start not in wikitext:
        raise ValueError(f"Could not find rankings for {year}.")
    if section_end in wikitext:
        section = wikitext[wikitext.index(section_start) : wikitext.index(section_end)]
    else:
        section = wikitext[wikitext.index(section_start) :]

    current_month = ""
    rows: list[MonthlyChartEntry] = []
    month_rank = 0
    for line in section.splitlines():
        stripped = line.strip()
        heading_match = re.match(r"^===\s+(.+?)\s+===$", stripped)
        if heading_match:
            current_month = heading_match.group(1)
            month_rank = 0
            continue
        row_match = re.match(r"^#\s+([0-9.]+)([MB])\s+-\s+(.+)$", stripped)
        if row_match and current_month:
            month_rank += 1
            rows.append(
                MonthlyChartEntry(
                    month=current_month,
                    rank=month_rank,
                    experience=row_match.group(3),
                    monthly_visits=parse_visit_label(row_match.group(1), row_match.group(2)),
                )
            )
    if not rows:
        raise ValueError(f"No monthly chart entries were parsed for {year}.")
    return rows


def score_candidate(target_title: str, candidate_title: str) -> float:
    target = canonicalize_title(target_title)
    candidate = canonicalize_title(candidate_title)
    target_tokens = set(target.split())
    candidate_tokens = set(candidate.split())
    if not target_tokens or not candidate_tokens:
        return 0.0
    overlap = len(target_tokens & candidate_tokens)
    score = overlap / len(target_tokens)
    if candidate == target:
        score += 2.0
    if candidate.startswith(target):
        score += 0.5
    if target.startswith(candidate):
        score += 0.25
    return score


def search_experience(title: str) -> dict[str, Any]:
    query = SEARCH_ALIASES.get(title, title)
    response = requests.get(
        ROBLOX_SEARCH_URL,
        params={"searchQuery": query, "sessionId": str(uuid.uuid4()), "pageType": "Game"},
        headers=REQUEST_HEADERS,
        timeout=20,
    )
    response.raise_for_status()
    payload = response.json()

    best_match: dict[str, Any] | None = None
    best_score = -1.0
    for result_group in payload.get("searchResults", []):
        if result_group.get("contentGroupType") != "Game":
            continue
        for candidate in result_group.get("contents", []):
            score = score_candidate(title, candidate.get("name", ""))
            if score > best_score:
                best_match = candidate
                best_score = score

    if not best_match:
        raise ValueError(f"Could not resolve a Roblox universe for {title}.")
    return best_match


def fetch_live_game_data(universe_ids: list[int]) -> dict[int, dict[str, Any]]:
    response = requests.get(
        ROBLOX_GAMES_URL,
        params={"universeIds": ",".join(str(universe_id) for universe_id in universe_ids)},
        headers=REQUEST_HEADERS,
        timeout=30,
    )
    response.raise_for_status()
    return {item["id"]: item for item in response.json()["data"]}


def human_number(value: int) -> str:
    if value >= 1_000_000_000:
        return f"{value / 1_000_000_000:.2f}B"
    if value >= 1_000_000:
        return f"{value / 1_000_000:.1f}M"
    if value >= 1_000:
        return f"{value / 1_000:.1f}K"
    return str(value)


def percentage(value: float) -> float:
    return round(value * 100, 2)


def seeded_random(name: str) -> random.Random:
    digest = hashlib.sha256(name.encode("utf-8")).hexdigest()
    return random.Random(int(digest[:12], 16))


def summarize_game(title: str, description: str) -> tuple[str, str]:
    if title in GAME_SUMMARIES:
        return GAME_SUMMARIES[title]

    cleaned = re.sub(r"\s+", " ", description.replace("\n", " ").replace("\r", " ")).strip()
    first_sentence = cleaned.split(". ")[0].strip()
    if not first_sentence.endswith("."):
        first_sentence += "."
    return first_sentence, "Play the core loop, scale up, and push for better progression."


def infer_game_type(title: str, genre_l1: str | None, genre_l2: str | None) -> str:
    if title in GAME_TYPE_OVERRIDES:
        return GAME_TYPE_OVERRIDES[title]

    normalized = canonicalize_title(f"{genre_l1 or ''} {genre_l2 or ''}")
    if "tower defense" in normalized:
        return "Strategy_TowerDefense"
    if "roleplay" in normalized or "life" in normalized or "dress up" in normalized:
        return "Roleplay_Social"
    if "fighting" in normalized or "battleground" in normalized:
        return "Fighting_Battlegrounds"
    if "shooter" in normalized:
        return "Shooter_Competitive"
    if "sports" in normalized:
        return "Sports_Competitive"
    if "simulation" in normalized or "tycoon" in normalized:
        return "Simulation_Tycoon"
    if "rpg" in normalized:
        return "RPG_Progression"
    if "survival" in normalized:
        return "Survival_Horror"
    if "party" in normalized or "minigame" in normalized:
        return "Party_Elimination"
    return "Mixed"


def synthesize_user_metrics(title: str, game_type: str, chart_rows: list[MonthlyChartEntry], live_data: dict[str, Any]) -> dict[str, float]:
    base = TYPE_BASES.get(game_type, {"session_minutes": 20.0, "retention_30d": 0.26, "payer_rate": 0.02, "arppu": 16.0})
    rng = seeded_random(title)

    visits = max(1, int(live_data["visits"]))
    favorites = int(live_data["favoritedCount"])
    playing = int(live_data["playing"])
    upvotes = int(live_data["totalUpVotes"])
    downvotes = int(live_data["totalDownVotes"])
    favorite_rate = favorites / visits
    approval_rate = upvotes / max(1, upvotes + downvotes)
    popularity_factor = min(1.0, math.log10(max(playing, 10)) / 6.0)

    peak_monthly_visits = max(entry.monthly_visits for entry in chart_rows)
    average_monthly_visits = statistics.mean(entry.monthly_visits for entry in chart_rows)
    history_proxy = max(average_monthly_visits / 4.0, peak_monthly_visits / 8.0)
    live_proxy = max(playing * 70, visits * 0.05)
    monthly_active_proxy_cap = max(playing * 2800, visits * 0.45)
    monthly_active_proxy = min(max(history_proxy, live_proxy), monthly_active_proxy_cap)
    history_confidence = min(1.0, math.sqrt(visits / max(average_monthly_visits, 1.0)))

    synthetic_session = min(
        48.0,
        max(
            10.0,
            base["session_minutes"] + (popularity_factor * 6.0) + (favorite_rate * 160.0) + rng.uniform(-1.5, 1.5),
        ),
    )
    synthetic_retention = min(
        0.62,
        max(
            0.14,
            base["retention_30d"] + (favorite_rate * 0.9) + ((approval_rate - 0.75) * 0.15) + rng.uniform(-0.015, 0.015),
        ),
    )
    synthetic_payer_rate = min(
        0.08,
        max(
            0.008,
            base["payer_rate"] + (favorite_rate * 0.35) + ((approval_rate - 0.75) * 0.03) + rng.uniform(-0.002, 0.002),
        ),
    )
    synthetic_arppu = min(
        38.0,
        max(
            8.0,
            base["arppu"] + (popularity_factor * 5.0) + (favorite_rate * 40.0) + rng.uniform(-1.5, 1.5),
        ),
    )

    monetization_index = monthly_active_proxy * synthetic_payer_rate * synthetic_arppu * synthetic_retention * history_confidence
    stickiness_index = (synthetic_session / 30.0) * synthetic_retention * (0.5 + approval_rate)

    return {
        "favorite_rate": favorite_rate,
        "approval_rate": approval_rate,
        "peak_monthly_visits": float(peak_monthly_visits),
        "average_monthly_visits": float(average_monthly_visits),
        "monthly_active_proxy": float(monthly_active_proxy),
        "history_confidence": round(history_confidence, 4),
        "synthetic_avg_session_minutes": round(synthetic_session, 2),
        "synthetic_30d_return_rate": round(synthetic_retention, 4),
        "synthetic_payer_rate": round(synthetic_payer_rate, 4),
        "synthetic_arppu_usd": round(synthetic_arppu, 2),
        "monetization_index": round(monetization_index, 2),
        "stickiness_index": round(stickiness_index, 4),
    }


def collect_dataset(year: int) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    chart_rows = parse_chart_year(fetch_rankings_wikitext(), year)
    titles = sorted({entry.experience for entry in chart_rows})

    search_results: dict[str, dict[str, Any]] = {}
    for title in titles:
        search_results[title] = search_experience(title)
        time.sleep(0.25)

    live_lookup = fetch_live_game_data([item["universeId"] for item in search_results.values()])

    grouped_chart_rows: dict[str, list[MonthlyChartEntry]] = {}
    for row in chart_rows:
        grouped_chart_rows.setdefault(row.experience, []).append(row)

    summary_rows: list[dict[str, Any]] = []
    for title in titles:
        search_row = search_results[title]
        live_row = live_lookup[search_row["universeId"]]
        chart_history = grouped_chart_rows[title]
        game_type = infer_game_type(title, live_row.get("genre_l1"), live_row.get("genre_l2"))
        quick_description, goal = summarize_game(title, live_row.get("description", ""))
        model = synthesize_user_metrics(title, game_type, chart_history, live_row | {
            "totalUpVotes": search_row["totalUpVotes"],
            "totalDownVotes": search_row["totalDownVotes"],
        })

        summary_rows.append(
            {
                "experience": title,
                "official_title": live_row["name"],
                "game_type": game_type,
                "creator": live_row["creator"]["name"],
                "genre_l1": live_row.get("genre_l1") or live_row.get("genre") or "",
                "genre_l2": live_row.get("genre_l2") or "",
                "months_on_chart": len(chart_history),
                "best_rank": min(entry.rank for entry in chart_history),
                "average_rank": round(statistics.mean(entry.rank for entry in chart_history), 2),
                "peak_monthly_visits": int(model["peak_monthly_visits"]),
                "average_monthly_visits": round(model["average_monthly_visits"]),
                "current_ccu": int(live_row["playing"]),
                "current_total_visits": int(live_row["visits"]),
                "current_favorites": int(live_row["favoritedCount"]),
                "current_upvotes": int(search_row["totalUpVotes"]),
                "current_downvotes": int(search_row["totalDownVotes"]),
                "approval_rate": model["approval_rate"],
                "favorite_rate": model["favorite_rate"],
                "history_confidence": model["history_confidence"],
                "synthetic_avg_session_minutes": model["synthetic_avg_session_minutes"],
                "synthetic_30d_return_rate": model["synthetic_30d_return_rate"],
                "synthetic_payer_rate": model["synthetic_payer_rate"],
                "synthetic_arppu_usd": model["synthetic_arppu_usd"],
                "stickiness_index": model["stickiness_index"],
                "monetization_index": model["monetization_index"],
                "quick_description": quick_description,
                "core_goal": goal,
                "roblox_url": f"https://www.roblox.com/games/{live_row['rootPlaceId']}",
                "rankings_source_url": FANDOM_RANKINGS_URL,
            }
        )

    summary_rows.sort(key=lambda row: row["monetization_index"], reverse=True)
    for index, row in enumerate(summary_rows, start=1):
        row["revenue_rank"] = index

    summary_lookup = {row["experience"]: row for row in summary_rows}

    monthly_rows: list[dict[str, Any]] = []
    for row in chart_rows:
        summary = summary_lookup[row.experience]
        monthly_rows.append(
            {
                "month": row.month,
                "rank": row.rank,
                "experience": row.experience,
                "game_type": summary["game_type"],
                "monthly_visits": row.monthly_visits,
                "monthly_visits_label": human_number(row.monthly_visits),
                "current_ccu": summary["current_ccu"],
                "current_total_visits": summary["current_total_visits"],
                "current_favorites": summary["current_favorites"],
                "approval_rate": summary["approval_rate"],
                "revenue_rank": summary["revenue_rank"],
                "monetization_index": summary["monetization_index"],
                "quick_description": summary["quick_description"],
                "core_goal": summary["core_goal"],
                "roblox_url": summary["roblox_url"],
                "rankings_source_url": summary["rankings_source_url"],
            }
        )

    return summary_rows, monthly_rows


def write_sheet(ws, headers: list[str], rows: list[dict[str, Any]], hyperlink_columns: set[str] | None = None) -> None:
    hyperlink_columns = hyperlink_columns or set()
    ws.append(headers)
    for header_cell in ws[1]:
        header_cell.fill = HEADER_FILL
        header_cell.font = HEADER_FONT

    for row_data in rows:
        values = [row_data.get(header, "") for header in headers]
        ws.append(values)
        row_index = ws.max_row
        for col_index, header in enumerate(headers, start=1):
            if header in hyperlink_columns and row_data.get(header):
                cell = ws.cell(row=row_index, column=col_index)
                cell.hyperlink = row_data[header]
                cell.style = "Hyperlink"

    ws.freeze_panes = "A2"
    ws.auto_filter.ref = ws.dimensions

    for column_index, header in enumerate(headers, start=1):
        max_length = len(header)
        for cell in ws[get_column_letter(column_index)]:
            value = "" if cell.value is None else str(cell.value)
            max_length = max(max_length, min(70, len(value)))
        ws.column_dimensions[get_column_letter(column_index)].width = min(max_length + 2, 72)


def workbook_rows(summary_rows: list[dict[str, Any]], monthly_rows: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    revenue_rows: list[dict[str, Any]] = []
    for row in summary_rows:
        revenue_rows.append(
            {
                "Revenue Rank": row["revenue_rank"],
                "Experience": row["experience"],
                "Game Type": row["game_type"],
                "Official Genre L1": row["genre_l1"],
                "Official Genre L2": row["genre_l2"],
                "Creator": row["creator"],
                "Months On 2025 Chart": row["months_on_chart"],
                "Best 2025 Rank": row["best_rank"],
                "Average 2025 Rank": row["average_rank"],
                "Peak 2025 Monthly Visits": row["peak_monthly_visits"],
                "Average 2025 Monthly Visits": row["average_monthly_visits"],
                "Current CCU": row["current_ccu"],
                "Current Total Visits": row["current_total_visits"],
                "Current Favorites": row["current_favorites"],
                "Current Upvotes": row["current_upvotes"],
                "Current Downvotes": row["current_downvotes"],
                "Approval Rate %": percentage(row["approval_rate"]),
                "Favorite Rate %": percentage(row["favorite_rate"]),
                "History Confidence %": percentage(row["history_confidence"]),
                "Synthetic Avg Session Minutes": row["synthetic_avg_session_minutes"],
                "Synthetic 30d Return %": percentage(row["synthetic_30d_return_rate"]),
                "Synthetic Payer %": percentage(row["synthetic_payer_rate"]),
                "Synthetic ARPPU USD": row["synthetic_arppu_usd"],
                "Stickiness Index": row["stickiness_index"],
                "Revenue Potential Index": row["monetization_index"],
                "Quick Description": row["quick_description"],
                "Core Goal": row["core_goal"],
                "Roblox URL": row["roblox_url"],
                "Rankings Source URL": row["rankings_source_url"],
            }
        )

    monthly_sheet_rows: list[dict[str, Any]] = []
    for row in monthly_rows:
        monthly_sheet_rows.append(
            {
                "Month": row["month"],
                "Chart Rank": row["rank"],
                "Revenue Rank": row["revenue_rank"],
                "Experience": row["experience"],
                "Game Type": row["game_type"],
                "2025 Monthly Visits": row["monthly_visits"],
                "2025 Monthly Visits Label": row["monthly_visits_label"],
                "Current CCU": row["current_ccu"],
                "Current Total Visits": row["current_total_visits"],
                "Current Favorites": row["current_favorites"],
                "Approval Rate %": percentage(row["approval_rate"]),
                "Revenue Potential Index": row["monetization_index"],
                "Quick Description": row["quick_description"],
                "Core Goal": row["core_goal"],
                "Roblox URL": row["roblox_url"],
                "Rankings Source URL": row["rankings_source_url"],
            }
        )

    return revenue_rows, monthly_sheet_rows


def add_methodology_sheet(workbook: Workbook, year: int) -> None:
    ws = workbook.create_sheet("Methodology")
    rows = [
        ("Workbook Year", year),
        ("Monthly Chart Source", FANDOM_RANKINGS_URL),
        ("Monthly Chart Note", "Historical monthly rankings come from the Roblox Wiki page, which credits Rolimons and notes the figures may not be perfectly exact."),
        ("Live Stats Source", ROBLOX_GAMES_URL),
        ("Experience Search Source", ROBLOX_SEARCH_URL),
        ("Official Columns", "Current CCU, total visits, favorites, upvotes, downvotes, genre, creator, and official descriptions come from live Roblox APIs."),
        ("Synthetic Columns", "Synthetic Avg Session Minutes, Synthetic 30d Return %, Synthetic Payer %, Synthetic ARPPU USD, Stickiness Index, History Confidence %, and Revenue Potential Index are modeled estimates for planning only."),
        ("Revenue Ordering", "Rows are sorted by Revenue Potential Index, a heuristic that mixes current scale, modeled monetization behavior, and a confidence penalty when live totals look too small for the historical chart numbers."),
    ]
    ws.append(["Field", "Value"])
    for header_cell in ws[1]:
        header_cell.fill = HEADER_FILL
        header_cell.font = HEADER_FONT
    for field, value in rows:
        ws.append([field, value])
    ws.freeze_panes = "A2"
    ws.auto_filter.ref = ws.dimensions
    ws.column_dimensions["A"].width = 24
    ws.column_dimensions["B"].width = 120
    for row in range(2, ws.max_row + 1):
        if ws.cell(row=row, column=2).value and str(ws.cell(row=row, column=2).value).startswith("http"):
            ws.cell(row=row, column=2).hyperlink = ws.cell(row=row, column=2).value
            ws.cell(row=row, column=2).style = "Hyperlink"


def build_workbook(summary_rows: list[dict[str, Any]], monthly_rows: list[dict[str, Any]], year: int, output_path: Path) -> None:
    revenue_rows, monthly_sheet_rows = workbook_rows(summary_rows, monthly_rows)
    workbook = Workbook()
    workbook.remove(workbook.active)

    revenue_sheet = workbook.create_sheet("Revenue_Ranking")
    write_sheet(
        revenue_sheet,
        list(revenue_rows[0].keys()),
        revenue_rows,
        hyperlink_columns={"Roblox URL", "Rankings Source URL"},
    )

    monthly_sheet = workbook.create_sheet(f"Top10_{year}")
    write_sheet(
        monthly_sheet,
        list(monthly_sheet_rows[0].keys()),
        monthly_sheet_rows,
        hyperlink_columns={"Roblox URL", "Rankings Source URL"},
    )

    by_type_sheet = workbook.create_sheet("By_Game_Type")
    by_type_rows = sorted(revenue_rows, key=lambda row: (row["Game Type"], row["Revenue Rank"]))
    write_sheet(
        by_type_sheet,
        list(revenue_rows[0].keys()),
        by_type_rows,
        hyperlink_columns={"Roblox URL", "Rankings Source URL"},
    )

    for game_type in sorted({row["Game Type"] for row in revenue_rows}):
        sheet_name = game_type[:31]
        type_rows = [row for row in revenue_rows if row["Game Type"] == game_type]
        type_sheet = workbook.create_sheet(sheet_name)
        write_sheet(
            type_sheet,
            list(revenue_rows[0].keys()),
            type_rows,
            hyperlink_columns={"Roblox URL", "Rankings Source URL"},
        )

    add_methodology_sheet(workbook, year)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    workbook.save(output_path)


def main() -> int:
    args = parse_args()
    output_path = Path(args.output) if args.output else Path("docs") / f"roblox_top_experiences_{args.year}.xlsx"
    summary_rows, monthly_rows = collect_dataset(args.year)
    build_workbook(summary_rows, monthly_rows, args.year, output_path)
    print(json.dumps({"output": str(output_path), "experiences": len(summary_rows), "monthly_rows": len(monthly_rows)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
