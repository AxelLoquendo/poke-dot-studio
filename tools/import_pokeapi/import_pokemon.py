#!/usr/bin/env python3
"""Vuelca PokéAPI al JSON que lee PokemonDB.

No descarga sprites. El juego usa los gráficos de La Base de Sky.

Uso (desde la raíz del proyecto):
  python tools/import_pokeapi/import_pokemon.py --out data/pokemon
  python tools/import_pokeapi/import_pokemon.py --out data/pokemon --only-items
  python tools/import_pokeapi/import_pokemon.py --out data/pokemon --skip-items
  python tools/import_pokeapi/import_pokemon.py --out data/pokemon --limit 151

Requiere red. Cachea cada URL en .cache/ junto al script.
"""

from __future__ import annotations

import argparse
import json
import re
import time
import urllib.request
from pathlib import Path

API = "https://pokeapi.co/api/v2"
LANG = "es"
VERSION_GROUP = "scarlet-violet"

GROWTH = {
    "slow": "Slow",
    "medium": "Medium",
    "fast": "Fast",
    "medium-slow": "Parabolic",
    "slow-then-very-fast": "Erratic",
    "fast-then-very-slow": "Fluctuating",
}

EGG = {
    "monster": "Monster",
    "water1": "Water1",
    "water2": "Water2",
    "water3": "Water3",
    "bug": "Bug",
    "flying": "Flying",
    "ground": "Field",
    "fairy": "Fairy",
    "plant": "Grass",
    "humanshape": "HumanLike",
    "mineral": "Mineral",
    "indeterminate": "Amorphous",
    "ditto": "Ditto",
    "dragon": "Dragon",
    "no-eggs": "Undiscovered",
}

GENDER = {
    -1: "Genderless",
    0: "AlwaysMale",
    1: "FemaleOneEighth",
    2: "Female25Percent",
    4: "Female50Percent",
    6: "Female75Percent",
    7: "FemaleSevenEighths",
    8: "AlwaysFemale",
}

STAT_ORDER = (
    "hp",
    "attack",
    "defense",
    "speed",
    "special-attack",
    "special-defense",
)

COLOR = {
    "black": "Black",
    "blue": "Blue",
    "brown": "Brown",
    "gray": "Gray",
    "green": "Green",
    "pink": "Pink",
    "purple": "Purple",
    "red": "Red",
    "white": "White",
    "yellow": "Yellow",
}

SHAPE = {
    "ball": "Head",
    "squiggle": "Serpentine",
    "fish": "Finned",
    "arms": "HeadArms",
    "blob": "HeadBase",
    "upright": "BipedalTail",
    "legs": "HeadLegs",
    "quadruped": "Quadruped",
    "wings": "Winged",
    "tentacles": "Multipedal",
    "heads": "MultiWinged",
    "humanoid": "Bipedal",
    "bug-wings": "Insectoid",
    "armor": "HeadTorso",
}

ITEM_POCKET = {
    "standard-balls": "POKEBALLS",
    "special-balls": "POKEBALLS",
    "apricorn-balls": "POKEBALLS",
    "all-machines": "TMS",
    "medicine": "MEDICINE",
    "healing": "MEDICINE",
    "status-cures": "MEDICINE",
    "pp-recovery": "MEDICINE",
    "revival": "MEDICINE",
    "vitamins": "MEDICINE",
    "stat-boosts": "MEDICINE",
    "effort-drop": "MEDICINE",
}


def key_of(slug: str) -> str:
    return re.sub(r"[^A-Z0-9]", "", slug.upper())


def named(names: list, fallback: str, field: str = "name") -> str:
    for entry in names:
        if entry.get("language", {}).get("name") != LANG:
            continue
        value = entry.get(field)
        if value:
            return value
    for entry in names:
        value = entry.get(field)
        if value:
            return value
    return fallback.replace("-", " ").title()


def flavor(entries: list) -> str:
    best = ""
    for entry in entries:
        if entry.get("language", {}).get("name") != LANG:
            continue
        text = entry.get("flavor_text", "").replace("\n", " ").replace("\f", " ").strip()
        if len(text) > len(best):
            best = text
    return best


class Client:
    def __init__(self, cache: Path) -> None:
        self.cache = cache
        cache.mkdir(parents=True, exist_ok=True)

    def get(self, url: str) -> dict:
        name = re.sub(r"[^a-zA-Z0-9._-]", "_", url.replace(API + "/", ""))
        path = self.cache / (name + ".json")
        if path.exists():
            return json.loads(path.read_text(encoding="utf-8"))

        last_error: Exception | None = None
        for attempt in range(1, 6):
            try:
                request = urllib.request.Request(
                    url, headers={"User-Agent": "poke-dot-studio-import"}
                )
                with urllib.request.urlopen(request, timeout=120) as response:
                    raw = response.read()
                path.write_bytes(raw)
                time.sleep(0.08)
                return json.loads(raw.decode("utf-8"))
            except Exception as error:
                last_error = error
                wait = attempt * 2
                print(f"  retry {attempt}/5 {url} ({error})")
                time.sleep(wait)
        raise RuntimeError(f"falló tras 5 intentos: {url}") from last_error


def evolution_rules(chain: dict, species_key: str) -> list[dict]:
    rules: list[dict] = []

    def walk(node: dict) -> None:
        here = key_of(node["species"]["name"])
        for nxt in node.get("evolves_to", []):
            if here == species_key:
                rules.append(rule_for(nxt))
            walk(nxt)

    walk(chain)
    return rules


def rule_for(node: dict) -> dict:
    detail = (node.get("evolution_details") or [{}])[0]
    trigger = (detail.get("trigger") or {}).get("name", "")
    into = key_of(node["species"]["name"])
    item = detail.get("item") or detail.get("held_item")
    item_key = key_of(item["name"]) if item else ""
    level = detail.get("min_level")
    happiness = detail.get("min_happiness")
    time_of_day = detail.get("time_of_day") or ""
    known = detail.get("known_move")
    if trigger == "use-item":
        return {"into": into, "method": "Item", "parameter": item_key}
    if trigger == "trade":
        method = "TradeItem" if item_key else "Trade"
        return {"into": into, "method": method, "parameter": item_key}
    if trigger == "level-up":
        if happiness:
            method = "Happiness"
            if time_of_day == "day":
                method = "HappinessDay"
            elif time_of_day == "night":
                method = "HappinessNight"
            return {"into": into, "method": method, "parameter": ""}
        if known:
            return {
                "into": into,
                "method": "Move",
                "parameter": key_of(known["name"]),
            }
        if time_of_day == "day":
            return {
                "into": into,
                "method": "LevelDay",
                "parameter": str(level or ""),
            }
        if time_of_day == "night":
            return {
                "into": into,
                "method": "LevelNight",
                "parameter": str(level or ""),
            }
        return {"into": into, "method": "Level", "parameter": str(level or "")}
    return {"into": into, "method": "Custom", "parameter": trigger}


def moves_by_method(pokemon: dict, method: str) -> list:
    found: dict[str, int] = {}
    for row in pokemon.get("moves", []):
        move_key = key_of(row["move"]["name"])
        for detail in row.get("version_group_details", []):
            if detail.get("version_group", {}).get("name") != VERSION_GROUP:
                continue
            if detail.get("move_learn_method", {}).get("name") != method:
                continue
            level = int(detail.get("level_learned_at") or 0)
            if method == "level-up":
                if move_key not in found or level < found[move_key]:
                    found[move_key] = level
            else:
                found[move_key] = 0
    if method == "level-up":
        pairs = [{"level": lv, "move": m} for m, lv in found.items()]
        pairs.sort(key=lambda item: (item["level"], item["move"]))
        return pairs
    return sorted(found.keys())


def stats_of(pokemon: dict) -> tuple[list[int], list[int]]:
    by_name = {row["stat"]["name"]: row for row in pokemon["stats"]}
    base = [int(by_name[name]["base_stat"]) for name in STAT_ORDER]
    evs = [int(by_name[name]["effort"]) for name in STAT_ORDER]
    return base, evs


def species_row(
    client: Client, dex: int, chains: dict[str, dict]
) -> tuple[dict, list[dict]]:
    pokemon = client.get(f"{API}/pokemon/{dex}")
    species = client.get(pokemon["species"]["url"])
    chain_url = species["evolution_chain"]["url"]
    if chain_url not in chains:
        chains[chain_url] = client.get(chain_url)["chain"]
    key = key_of(species["name"])
    base_stats, evs = stats_of(pokemon)
    types = [
        key_of(slot["type"]["name"])
        for slot in sorted(pokemon["types"], key=lambda s: s["slot"])
    ]
    abilities: list[str] = []
    hidden: list[str] = []
    for slot in sorted(pokemon["abilities"], key=lambda s: s["slot"]):
        ability_key = key_of(slot["ability"]["name"])
        if slot.get("is_hidden"):
            hidden.append(ability_key)
        else:
            abilities.append(ability_key)

    row = {
        "key": key,
        "name": named(species["names"], species["name"]),
        "types": types,
        "base_stats": base_stats,
        "evs": evs,
        "gender_ratio": GENDER.get(species.get("gender_rate", 4), "Female50Percent"),
        "growth_rate": GROWTH.get(species["growth_rate"]["name"], "Medium"),
        "base_exp": int(pokemon.get("base_experience") or 0),
        "catch_rate": int(species.get("capture_rate") or 0),
        "happiness": int(species.get("base_happiness") or 70),
        "abilities": abilities,
        "hidden_abilities": hidden,
        "moves": moves_by_method(pokemon, "level-up"),
        "tutor_moves": moves_by_method(pokemon, "tutor"),
        "egg_moves": moves_by_method(pokemon, "egg"),
        "egg_groups": [
            EGG.get(group["name"], "Undiscovered")
            for group in species.get("egg_groups", [])
        ],
        "hatch_steps": int(species.get("hatch_counter") or 20) * 256,
        "height_m": pokemon["height"] / 10.0,
        "weight_kg": pokemon["weight"] / 10.0,
        "color": COLOR.get(species.get("color", {}).get("name", ""), "Green"),
        "shape": SHAPE.get(species.get("shape", {}).get("name", ""), "Quadruped"),
        "habitat": (species.get("habitat") or {}).get("name", "") or "",
        "category": named(species.get("genera", []), "", "genus"),
        "pokedex": flavor(species.get("flavor_text_entries", [])),
        "generation": int(re.sub(r"\D", "", species["generation"]["name"]) or 1),
        "evolutions": evolution_rules(chains[chain_url], key),
        "flags": [],
        "wild_item_common": "",
        "wild_item_uncommon": "",
        "wild_item_rare": "",
        "incense": "",
        "offspring": "",
    }

    forms: list[dict] = []
    form_index = 0
    for variety in species.get("varieties", []):
        if variety.get("is_default"):
            continue
        form_index += 1
        form_pokemon = client.get(variety["pokemon"]["url"])
        form_stats, form_evs = stats_of(form_pokemon)
        form_types = [
            key_of(slot["type"]["name"])
            for slot in sorted(form_pokemon["types"], key=lambda s: s["slot"])
        ]
        form_abilities: list[str] = []
        form_hidden: list[str] = []
        for slot in sorted(form_pokemon["abilities"], key=lambda s: s["slot"]):
            ability_key = key_of(slot["ability"]["name"])
            if slot.get("is_hidden"):
                form_hidden.append(ability_key)
            else:
                form_abilities.append(ability_key)
        slug = variety["pokemon"]["name"]
        forms.append(
            {
                "key": key,
                "form": form_index,
                "form_name": slug.replace("-", " ").title(),
                "types": form_types,
                "base_stats": form_stats,
                "evs": form_evs,
                "abilities": form_abilities,
                "hidden_abilities": form_hidden,
                "height_m": form_pokemon["height"] / 10.0,
                "weight_kg": form_pokemon["weight"] / 10.0,
                "moves": moves_by_method(form_pokemon, "level-up"),
                "tutor_moves": moves_by_method(form_pokemon, "tutor"),
                "egg_moves": moves_by_method(form_pokemon, "egg"),
                "mega_stone": "",
                "mega_move": "",
            }
        )
    return row, forms


def collect_refs(
    species_rows: list[dict], form_rows: list[dict]
) -> tuple[set[str], set[str]]:
    moves: set[str] = set()
    abilities: set[str] = set()
    for row in species_rows + form_rows:
        for ability in row.get("abilities", []) + row.get("hidden_abilities", []):
            abilities.add(ability)
        for entry in row.get("moves", []):
            moves.add(entry["move"])
        for key in row.get("tutor_moves", []) + row.get("egg_moves", []):
            moves.add(key)
    return moves, abilities


def load_items(client: Client) -> list[dict]:
    rows: list[dict] = []
    entries = client.get(f"{API}/item?limit=100000")["results"]
    total = len(entries)
    for index, entry in enumerate(entries, start=1):
        if index % 50 == 0 or index == total:
            print(f"  item {index}/{total}")
        item = client.get(entry["url"])
        cat = (item.get("category") or {}).get("name", "")
        pocket = ITEM_POCKET.get(cat, "ITEMS")
        if "berry" in cat:
            pocket = "BERRIES"
        rows.append(
            {
                "key": key_of(entry["name"]),
                "name": named(item.get("names", []), entry["name"]),
                "pocket": pocket,
                "price": int(item.get("cost") or 0),
                "description": flavor(item.get("flavor_text_entries", [])),
                "flags": [],
            }
        )
    return rows


def dump(out: Path, name: str, rows: list) -> None:
    (out / name).write_text(
        json.dumps(rows, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(name, len(rows))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True, help="Carpeta data/pokemon del proyecto")
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Solo los N primeros de la dex. 0 = todos",
    )
    parser.add_argument(
        "--cache",
        default="",
        help="Carpeta de cache. Por defecto .cache junto al script",
    )
    parser.add_argument(
        "--skip-items",
        action="store_true",
        help="No importar items",
    )
    parser.add_argument(
        "--only-items",
        action="store_true",
        help="Solo regenera items.json (usa cache)",
    )
    args = parser.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    cache = (
        Path(args.cache)
        if args.cache
        else Path(__file__).resolve().parent / ".cache"
    )
    client = Client(cache)

    if args.only_items:
        print("items…")
        dump(out, "items.json", load_items(client))
        return

    index = client.get(f"{API}/pokemon-species?limit=100000")
    total = (
        len(index["results"])
        if args.limit <= 0
        else min(args.limit, len(index["results"]))
    )
    chains: dict[str, dict] = {}
    species_rows: list[dict] = []
    form_rows: list[dict] = []
    for dex in range(1, total + 1):
        print(f"species {dex}/{total}")
        row, forms = species_row(client, dex, chains)
        species_rows.append(row)
        form_rows.extend(forms)

    move_keys, ability_keys = collect_refs(species_rows, form_rows)

    move_rows: list[dict] = []
    for slug_url in client.get(f"{API}/move?limit=100000")["results"]:
        move_key = key_of(slug_url["name"])
        if move_key not in move_keys:
            continue
        move = client.get(slug_url["url"])
        move_rows.append(
            {
                "key": move_key,
                "name": named(move["names"], move["name"]),
                "type": key_of(move["type"]["name"]),
                "category": {
                    "physical": "Physical",
                    "special": "Special",
                    "status": "Status",
                }.get(move["damage_class"]["name"], "Status"),
                "power": int(move["power"] or 0),
                "accuracy": int(move["accuracy"] or 0),
                "total_pp": int(move["pp"] or 5),
                "target": "NearOther",
                "function_code": "None",
                "flags": [],
                "effect_chance": int(move["effect_chance"] or 0),
                "priority": int(move["priority"] or 0),
                "description": flavor(move.get("flavor_text_entries", [])),
            }
        )

    ability_rows: list[dict] = []
    for slug_url in client.get(f"{API}/ability?limit=10000")["results"]:
        ability_key = key_of(slug_url["name"])
        if ability_key not in ability_keys:
            continue
        ability = client.get(slug_url["url"])
        ability_rows.append(
            {
                "key": ability_key,
                "name": named(ability["names"], ability["name"]),
                "description": flavor(ability.get("flavor_text_entries", [])),
            }
        )

    type_rows: list[dict] = []
    for index_type, slug_url in enumerate(
        client.get(f"{API}/type?limit=100")["results"]
    ):
        if slug_url["name"] in ("unknown", "shadow"):
            continue
        type_data = client.get(slug_url["url"])
        rel = type_data["damage_relations"]
        type_rows.append(
            {
                "key": key_of(slug_url["name"]),
                "name": named(type_data["names"], slug_url["name"]),
                "icon_position": index_type,
                "weaknesses": [
                    key_of(item["name"]) for item in rel["double_damage_from"]
                ],
                "resistances": [
                    key_of(item["name"]) for item in rel["half_damage_from"]
                ],
                "immunities": [
                    key_of(item["name"]) for item in rel["no_damage_from"]
                ],
            }
        )

    dump(out, "species.json", species_rows)
    dump(out, "forms.json", form_rows)
    dump(out, "moves.json", move_rows)
    dump(out, "abilities.json", ability_rows)
    dump(out, "types.json", type_rows)

    if args.skip_items:
        if not (out / "items.json").exists():
            dump(out, "items.json", [])
        print("items.json skipped")
    else:
        print("items…")
        dump(out, "items.json", load_items(client))


if __name__ == "__main__":
    main()