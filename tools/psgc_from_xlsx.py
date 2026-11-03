"""Convert a PSA PSGC publication workbook into the `.psgc/` JSON dump.

`tools/build_psgc.py` reads four small JSON files from `.psgc/`:

    regions.json    reg_code, name
    provinces.json  prov_code, reg_code, name
    city-mun.json   mun_code, prov_code, reg_code, name
    barangays.json  brgy_code, mun_code, prov_code, reg_code, name

This script produces them from the official Excel workbook, so the offline
place list can be refreshed whenever the PSA publishes a new quarter.

Usage:

    python -m pip install openpyxl          # only dependency
    python tools/psgc_from_xlsx.py PSGC-3Q-2026-Publication-Datafile.xlsx
    python tools/build_psgc.py

The 10-digit PSGC in the workbook is `RR PPP MM BBB` (region, province,
city/municipality, barangay). Parent codes are derived from that structure:
the region is the first two digits, the province the first five, and the
city/municipality the first seven. Cities that belong to no province (NCR,
independent cities) get an empty `prov_code`, exactly as the build script
expects for its `R<region>` shards.

Source: Philippine Standard Geographic Code (PSGC), Philippine Statistics
Authority, CC BY 4.0.
"""
import io
import json
import os
import sys

SRC = ".psgc"
SHEET = "PSGC"
# Columns in the PSGC sheet (0-based, after the empty first column).
COL_CODE, COL_NAME, COL_LEVEL = 1, 2, 4

CITY_LEVELS = {"City", "Mun", "SubMun"}
# Barangays that hang off a city with no province still need their region.
UNPROVINCED = {"0990100000"}  # City of Isabela (Not a Province)


def read_rows(path):
    try:
        import openpyxl
    except ImportError:
        print(
            "openpyxl is required: python -m pip install openpyxl",
            file=sys.stderr,
        )
        raise SystemExit(1)

    workbook = openpyxl.load_workbook(path, read_only=True, data_only=True)
    sheet = workbook[SHEET] if SHEET in workbook.sheetnames else workbook.worksheets[-1]
    for index, row in enumerate(sheet.iter_rows(values_only=True)):
        if index == 0:
            continue
        code = str(row[COL_CODE] or "").strip()
        name = str(row[COL_NAME] or "").strip()
        level = str(row[COL_LEVEL] or "").strip()
        if len(code) != 10 or not name:
            continue
        yield code, name, level


def main(argv):
    if len(argv) != 2:
        print(__doc__.strip().splitlines()[0], file=sys.stderr)
        print("usage: psgc_from_xlsx.py <workbook.xlsx>", file=sys.stderr)
        return 2
    source = argv[1]
    if not os.path.exists(source):
        print(f"no such file: {source}", file=sys.stderr)
        return 1

    rows = list(read_rows(source))

    # "Special Geographic Area" is a grouping of BARMM municipalities with no
    # province row of its own; treat it as one so they stay reachable.
    province_codes = {
        code[:5]
        for code, name, level in rows
        if level == "Prov" or (level == "" and "Special Geographic Area" in name)
    }

    regions, provinces, cities, barangays = [], [], [], []
    for code, name, level in rows:
        region = code[:2]
        province = code[:5] if code[:5] in province_codes else ""

        if level == "Reg":
            regions.append({"psgc_code": code, "name": name, "reg_code": region})
        elif level == "Prov" or (level == "" and "Special Geographic Area" in name):
            provinces.append(
                {
                    "psgc_code": code,
                    "name": name,
                    "reg_code": region,
                    "prov_code": province,
                }
            )
        elif level in CITY_LEVELS or code in UNPROVINCED:
            cities.append(
                {
                    "psgc_code": code,
                    # Sub-municipalities (Manila's districts) stay in the dump so
                    # barangays keep a parent, but the picker skips them.
                    "level": level,
                    "name": name,
                    "reg_code": region,
                    "prov_code": province,
                    "mun_code": code[:7],
                }
            )
        elif level == "Bgy":
            # The full 10-digit code is kept: it is what the hall and the
            # PSA publish, and the app shows it next to the selected barangay.
            barangays.append(
                {
                    "psgc_code": code,
                    "brgy_code": code,
                    "name": name,
                    "mun_code": code[:7],
                    "prov_code": province,
                    "reg_code": region,
                }
            )

    # A barangay's province is its city's province; the workbook omits the
    # parent for cities that left a province when NIR was created.
    city = {row["mun_code"]: row for row in cities}
    for row in barangays:
        parent = city.get(row["mun_code"])
        if parent is not None:
            row["prov_code"] = parent["prov_code"]
            row["reg_code"] = parent["reg_code"]

    for index, row in enumerate(regions, 1):
        row["id"] = index
    for index, row in enumerate(provinces, 1):
        row["id"] = index
    for index, row in enumerate(cities, 1):
        row["id"] = index
    for index, row in enumerate(barangays, 1):
        row["id"] = index

    os.makedirs(SRC, exist_ok=True)
    for name, data in (
        ("regions", regions),
        ("provinces", provinces),
        ("city-mun", cities),
        ("barangays", barangays),
    ):
        with io.open(f"{SRC}/{name}.json", "w", encoding="utf-8", newline="\n") as handle:
            json.dump(data, handle, ensure_ascii=False)
        print(f"{name}: {len(data)}")

    orphan = sum(1 for row in barangays if row["mun_code"] not in city)
    if orphan:
        print(f"warning: {orphan} barangays have no city/municipality row", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
