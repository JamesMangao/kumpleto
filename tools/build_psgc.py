"""Build the offline place-name assets from the PSGC dump in `.psgc/`.

Output (small, lazily loaded):

    app/assets/psgc/index.json          regions, provinces per region, cities
                                        per shard, plus the data release line
    app/assets/psgc/bgy/<shard>.json.gz barangays grouped by city/municipality

A *shard* is a province code, or `R<region code>` for cities that do not belong
to a province (all of NCR, and the independent cities). Barangays are only
decompressed when the user opens that province, so the app never parses 42,000
rows at launch.

Source: Philippine Standard Geographic Code (PSGC), Philippine Statistics
Authority, CC BY 4.0. Downloaded dump kept in `.psgc/` (gitignored).
"""
import gzip
import io
import json
import os
import sys

SRC = ".psgc"
OUT = "app/assets/psgc"

SMALL_WORDS = {"de", "del", "dela", "ng", "sa", "at", "of", "the"}


def pretty(name):
    """PSGC names are upper-case; make them readable without changing words."""
    out = []
    for index, word in enumerate(name.lower().split()):
        # Keep leading punctuation such as "(Pob.)" intact.
        prefix = len(word) - len(word.lstrip("(.\"'"))
        core = word[prefix:]
        if not core:
            out.append(word)
        elif core in SMALL_WORDS and index > 0:
            out.append(word)
        else:
            out.append(word[:prefix] + core[:1].upper() + core[1:])
    return " ".join(out)


def load(name):
    with io.open(f"{SRC}/{name}.json", encoding="utf-8") as handle:
        return json.load(handle)


def main():
    regions = load("regions")
    provinces = load("provinces")
    cities = load("city-mun")
    barangays = load("barangays")

    if not regions or not cities or not barangays:
        print("missing source files in .psgc/", file=sys.stderr)
        return 1

    os.makedirs(f"{OUT}/bgy", exist_ok=True)

    region_rows = sorted(
        ({"c": row["reg_code"], "n": pretty(row["name"])} for row in regions),
        key=lambda row: row["c"],
    )

    provinces_by_region = {}
    shard_for_province = {}
    for row in provinces:
        code = (row.get("prov_code") or "").strip()
        region = (row.get("reg_code") or "").strip()
        if not code:
            continue
        provinces_by_region.setdefault(region, []).append(
            {"c": code, "n": pretty(row["name"])}
        )
        shard_for_province[code] = code

    cities_by_shard = {}
    shard_of_city = {}
    region_of_shard = {}
    for row in cities:
        city_code = (row.get("mun_code") or "").strip()
        province = (row.get("prov_code") or "").strip()
        region = (row.get("reg_code") or "").strip()
        if not city_code:
            continue
        shard = province if province else f"R{region}"
        shard_of_city[city_code] = shard
        region_of_shard.setdefault(shard, region)
        cities_by_shard.setdefault(shard, []).append(
            {"c": city_code, "n": pretty(row["name"])}
        )

    barangays_by_shard = {}
    for row in barangays:
        city_code = (row.get("mun_code") or "").strip()
        shard = shard_of_city.get(city_code)
        if shard is None:
            continue
        barangays_by_shard.setdefault(shard, {}).setdefault(city_code, []).append(
            {"c": row["brgy_code"], "n": pretty(row["name"])}
        )

    index = {
        "release": "PSGC (Philippine Statistics Authority) — data bundled offline",
        "attribution": "Place names from the PSA PSGC, used under CC BY 4.0.",
        "regions": region_rows,
        "provinces": {
            region: sorted(rows, key=lambda row: row["n"])
            for region, rows in provinces_by_region.items()
        },
        "cities": {
            shard: sorted(rows, key=lambda row: row["n"])
            for shard, rows in cities_by_shard.items()
        },
        # Nairobi-style flatter case: regions without provinces (NCR) need every
        # shard that belongs to the region so the picker can list their cities.
        "regionShards": {},
    }
    for shard, region in region_of_shard.items():
        index["regionShards"].setdefault(region, []).append(shard)
    for region, shards in index["regionShards"].items():
        index["regionShards"][region] = sorted(shards)
    with io.open(f"{OUT}/index.json", "w", encoding="utf-8", newline="\n") as handle:
        json.dump(index, handle, ensure_ascii=False, separators=(",", ":"))

    total = os.path.getsize(f"{OUT}/index.json")
    for shard, grouped in sorted(barangays_by_shard.items()):
        payload = json.dumps(
            {city: sorted(rows, key=lambda row: row["n"]) for city, rows in grouped.items()},
            ensure_ascii=False,
            separators=(",", ":"),
        ).encode("utf-8")
        path = f"{OUT}/bgy/{shard}.json.gz"
        with gzip.GzipFile(path, "wb", compresslevel=9, mtime=0) as handle:
            handle.write(payload)
        total += os.path.getsize(path)

    print(f"regions: {len(region_rows)}")
    print(f"provinces: {sum(len(v) for v in provinces_by_region.values())}")
    print(f"cities/municipalities: {len(shard_of_city)}")
    print(f"barangays: {len(barangays)}")
    print(f"shards: {len(barangays_by_shard)}")
    print(f"total asset size: {total / 1024:.0f} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
