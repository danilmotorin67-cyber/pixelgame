#!/usr/bin/env python3
from __future__ import annotations
import json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
REQUIRED = [
    "items", "crops", "trees", "fish", "shellfish", "animals",
    "recipes_craft", "recipes_cook", "stations", "tools", "weapons", "amulets", "clothes",
    "enemies", "bosses", "loot_tables", "deep_biomes", "grotto", "sea_map", "ships",
    "npcs", "gifts", "quests", "bodies", "registry", "ghosts", "the_twenty", "evidence",
    "weather", "tides", "festivals", "bundles", "neptune",
    "skills", "knowledge_tree", "achievements", "collections",
    "bottles", "pages", "tales", "shops", "buildings", "balance",
]


def load(name: str):
    p = DATA / f"{name}.json"
    if not p.exists():
        return None, f"missing {p}"
    try:
        return json.loads(p.read_text(encoding="utf-8")), None
    except json.JSONDecodeError as e:
        return None, f"json {p}: {e}"


def rows(obj):
    if isinstance(obj, list):
        return obj
    if isinstance(obj, dict):
        for k in ("items", "nodes", "list"):
            if k in obj and isinstance(obj[k], list):
                return obj[k]
    return []


def main() -> int:
    errs = []
    tables = {}
    for name in REQUIRED:
        obj, err = load(name)
        if err:
            errs.append(err)
            continue
        tables[name] = obj
        ids = []
        for row in rows(obj):
            if isinstance(row, dict) and "id" in row:
                ids.append(row["id"])
        if ids and len(ids) != len(set(ids)):
            errs.append(f"dup id in {name}")
    npc_ids = {r["id"] for r in rows(tables.get("npcs", [])) if isinstance(r, dict) and "id" in r}
    if "npc_fortuna" not in npc_ids:
        errs.append("npc_fortuna missing")
    if "npc_hedda" not in npc_ids:
        errs.append("npc_hedda missing")
    item_ids = {r["id"] for r in rows(tables.get("items", [])) if isinstance(r, dict) and "id" in r}
    for need in ("seed_turnip", "tool_hoe", "fish_cod"):
        if need not in item_ids:
            errs.append(f"item {need} missing")
    if errs:
        print("FAIL")
        for e in errs:
            print(" -", e)
        return 1
    print("OK tables", len(tables), "npcs", len(npc_ids), "items", len(item_ids))
    return 0


if __name__ == "__main__":
    sys.exit(main())
