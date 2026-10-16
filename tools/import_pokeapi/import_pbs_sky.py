#!/usr/bin/env python3
"""Importa PBS de La Base de Sky / Pokémon Essentials → data/pokemon/*.json

Por defecto baja los txt del repo de Sky.
También puedes apuntar a una carpeta local con --pbs.

Uso:
  python tools/import_pokeapi/import_pbs_sky.py --out data/pokemon
  python tools/import_pokeapi/import_pbs_sky.py --out data/pokemon --pbs "C:/ruta/PBS"
"""

from __future__ import annotations

import argparse
import json
import re
import urllib.request
from pathlib import Path

SKY_PBS = (
    "https://raw.githubusercontent.com/SkyFangames/La-Base-de-Sky/main/"
    "LA%20BASE%20DE%20SKY/PBS"
)

FILES = (
    "types.txt",
    "abilities.txt",
    "moves.txt",
    "items.txt",
    "pokemon.txt",
    "pokemon_forms.txt",
)

TYPE_KEY = {
    "NORMAL": "NORMAL",
    "FIGHTING": "FIGHTING",
    "FLYING": "FLYING",
    "POISON": "POISON",
    "GROUND": "GROUND",
    "ROCK": "ROCK",
    "BUG": "BUG",
    "GHOST": "GHOST",
    "STEEL": "STEEL",
    "FIRE": "FIRE",
    "WATER": "WATER",
    "GRASS": "GRASS",
    "ELECTRIC": "ELECTRIC",
    "PSYCHIC": "PSYCHIC",
    "ICE": "ICE",
    "DRAGON": "DRAGON",
    "DARK": "DARK",
    "FAIRY": "FAIRY",
    "STELLAR": "STELLAR",
    "MYSTERY": "MYSTERY",
}


def fetch_text(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": "poke-dot-studio-pbs"})
    with urllib.request.urlopen(req, timeout=120) as response:
        raw = response.read()
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    return raw.decode("utf-8", errors="replace")


def read_pbs(source: Path | None, name: str) -> str:
    if source is not None:
        path = source / name
        text = path.read_text(encoding="utf-8-sig")
        return text
    print(f"download {name}")
    return fetch_text(f"{SKY_PBS}/{name}")


def parse_blocks(text: str) -> list[tuple[str, dict[str, str]]]:
    """[(section_id, {Key: value}), ...]  section_id = BULBASAUR o VENUSAUR,1"""
    blocks: list[tuple[str, dict[str, str]]] = []
    current_id: str | None = None
    current: dict[str, str] = {}
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            if current_id is not None:
                blocks.append((current_id, current))
            current_id = line[1:-1].strip()
            current = {}
            continue
        if current_id is None or "=" not in line:
            continue
        key, value = line.split("=", 1)
        current[key.strip()] = value.strip()
    if current_id is not None:
        blocks.append((current_id, current))
    return blocks


def split_list(value: str) -> list[str]:
    if not value:
        return []
    return [part.strip() for part in value.split(",") if part.strip()]


def type_list(value: str) -> list[str]:
    return [TYPE_KEY.get(t.upper(), t.upper()) for t in split_list(value)]


def int_list(value: str, size: int, fill: int = 0) -> list[int]:
    out = [fill] * size
    parts = split_list(value)
    for i, part in enumerate(parts[:size]):
        out[i] = int(part)
    return out


def parse_evs(value: str) -> list[int]:
    """EVs = SPEED,1,SPECIAL_ATTACK,2 → orden HP Atk Def Spe SpA SpDef"""
    order = {
        "HP": 0,
        "ATTACK": 1,
        "DEFENSE": 2,
        "SPEED": 3,
        "SPECIAL_ATTACK": 4,
        "SPECIAL_DEFENSE": 5,
        "SPATK": 4,
        "SPDEF": 5,
    }
    out = [0, 0, 0, 0, 0, 0]
    parts = split_list(value)
    i = 0
    while i + 1 < len(parts):
        name = parts[i].upper()
        amount = int(parts[i + 1])
        if name in order:
            out[order[name]] = amount
        i += 2
    return out


def parse_moves(value: str) -> list[dict]:
    """1,TACKLE,3,GROWL → [{level, move}]"""
    parts = split_list(value)
    out: list[dict] = []
    i = 0
    while i + 1 < len(parts):
        out.append({"level": int(parts[i]), "move": parts[i + 1].upper()})
        i += 2
    return out


def parse_evolutions(value: str) -> list[dict]:
    """IVYSAUR,Level,16,MEGA,Item,STONE → triples"""
    parts = split_list(value)
    out: list[dict] = []
    i = 0
    while i + 2 < len(parts):
        out.append(
            {
                "into": parts[i].upper(),
                "method": parts[i + 1],
                "parameter": parts[i + 2],
            }
        )
        i += 3
    # a veces falta parámetro
    if i + 1 < len(parts):
        out.append(
            {
                "into": parts[i].upper(),
                "method": parts[i + 1],
                "parameter": parts[i + 2] if i + 2 < len(parts) else "",
            }
        )
    return out


def species_from_fields(key: str, fields: dict[str, str], form: int = 0) -> dict:
    row: dict = {
        "key": key.upper(),
        "form": form,
        "form_name": fields.get("FormName", ""),
        "name": fields.get("Name", key.title()),
        "types": type_list(fields.get("Types", "")),
        "base_stats": int_list(fields.get("BaseStats", ""), 6, 1),
        "evs": parse_evs(fields.get("EVs", "")),
        "gender_ratio": fields.get("GenderRatio", "Female50Percent"),
        "growth_rate": fields.get("GrowthRate", "Medium"),
        "base_exp": int(fields.get("BaseExp", "0") or 0),
        "catch_rate": int(fields.get("CatchRate", "45") or 45),
        "happiness": int(fields.get("Happiness", "70") or 70),
        "abilities": [a.upper() for a in split_list(fields.get("Abilities", ""))],
        "hidden_abilities": [
            a.upper() for a in split_list(fields.get("HiddenAbilities", ""))
        ],
        "moves": parse_moves(fields.get("Moves", "")),
        "tutor_moves": [m.upper() for m in split_list(fields.get("TutorMoves", ""))],
        "egg_moves": [m.upper() for m in split_list(fields.get("EggMoves", ""))],
        "egg_groups": split_list(fields.get("EggGroups", "")),
        "hatch_steps": int(fields.get("HatchSteps", "5120") or 5120),
        "height_m": float(fields.get("Height", "0.1") or 0.1),
        "weight_kg": float(fields.get("Weight", "0.1") or 0.1),
        "color": fields.get("Color", "Green"),
        "shape": fields.get("Shape", "Quadruped"),
        "habitat": fields.get("Habitat", ""),
        "category": fields.get("Category", ""),
        "pokedex": fields.get("Pokedex", ""),
        "generation": int(fields.get("Generation", "1") or 1),
        "evolutions": parse_evolutions(fields.get("Evolutions", "")),
        "flags": split_list(fields.get("Flags", "")),
        "wild_item_common": fields.get("WildItemCommon", "").upper(),
        "wild_item_uncommon": fields.get("WildItemUncommon", "").upper(),
        "wild_item_rare": fields.get("WildItemRare", "").upper(),
        "incense": fields.get("Incense", "").upper(),
        "offspring": fields.get("Offspring", "").upper(),
        "mega_stone": fields.get("MegaStone", "").upper(),
        "mega_move": fields.get("MegaMove", "").upper(),
        "mega_message": fields.get("MegaMessage", ""),
        "unmega_form": int(fields.get("UnmegaForm", "0") or 0),
        "pokedex_form": int(fields.get("PokedexForm", "0") or 0),
    }
    return row


def load_types(text: str) -> list[dict]:
    rows = []
    for index, (section, fields) in enumerate(parse_blocks(text)):
        rows.append(
            {
                "key": section.upper(),
                "name": fields.get("Name", section.title()),
                "icon_position": int(fields.get("IconPosition", str(index)) or index),
                "weaknesses": type_list(fields.get("Weaknesses", "")),
                "resistances": type_list(fields.get("Resistances", "")),
                "immunities": type_list(fields.get("Immunities", "")),
            }
        )
    return rows


def load_abilities(text: str) -> list[dict]:
    rows = []
    for section, fields in parse_blocks(text):
        rows.append(
            {
                "key": section.upper(),
                "name": fields.get("Name", section.title()),
                "description": fields.get("Description", ""),
            }
        )
    return rows


def load_moves(text: str) -> list[dict]:
    rows = []
    for section, fields in parse_blocks(text):
        rows.append(
            {
                "key": section.upper(),
                "name": fields.get("Name", section.title()),
                "type": type_list(fields.get("Type", "NORMAL"))[0]
                if fields.get("Type")
                else "NORMAL",
                "category": fields.get("Category", "Physical"),
                "power": int(fields.get("Power", "0") or 0),
                "accuracy": int(fields.get("Accuracy", "100") or 0),
                "total_pp": int(fields.get("TotalPP", "5") or 5),
                "target": fields.get("Target", "NearOther"),
                "function_code": fields.get("FunctionCode", "None"),
                "flags": split_list(fields.get("Flags", "")),
                "effect_chance": int(fields.get("EffectChance", "0") or 0),
                "priority": int(fields.get("Priority", "0") or 0),
                "description": fields.get("Description", ""),
            }
        )
    return rows


def load_items(text: str) -> list[dict]:
    rows = []
    for section, fields in parse_blocks(text):
        rows.append(
            {
                "key": section.upper(),
                "name": fields.get("Name", section.title()),
                "pocket": fields.get("Pocket", "Items").upper().replace(" ", ""),
                "price": int(fields.get("Price", "0") or 0),
                "description": fields.get("Description", ""),
                "flags": split_list(fields.get("Flags", "")),
            }
        )
    return rows


def load_species(text: str) -> list[dict]:
    rows = []
    for section, fields in parse_blocks(text):
        rows.append(species_from_fields(section, fields, 0))
    return rows


def load_forms(text: str) -> list[dict]:
    rows = []
    for section, fields in parse_blocks(text):
        # [VENUSAUR,1]
        if "," in section:
            key, form_s = section.split(",", 1)
            form = int(form_s.strip())
        else:
            key, form = section, 1
        row = species_from_fields(key.strip(), fields, form)
        rows.append(row)
    return rows


def dump(out: Path, name: str, rows: list) -> None:
    (out / name).write_text(
        json.dumps(rows, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(name, len(rows))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    parser.add_argument(
        "--pbs",
        default="",
        help="Carpeta local con los .txt PBS. Si se omite, descarga de Sky",
    )
    args = parser.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    source = Path(args.pbs) if args.pbs else None

    types = load_types(read_pbs(source, "types.txt"))
    abilities = load_abilities(read_pbs(source, "abilities.txt"))
    moves = load_moves(read_pbs(source, "moves.txt"))
    items = load_items(read_pbs(source, "items.txt"))
    species = load_species(read_pbs(source, "pokemon.txt"))
    forms = load_forms(read_pbs(source, "pokemon_forms.txt"))

    dump(out, "types.json", types)
    dump(out, "abilities.json", abilities)
    dump(out, "moves.json", moves)
    dump(out, "items.json", items)
    dump(out, "species.json", species)
    dump(out, "forms.json", forms)


if __name__ == "__main__":
    main()