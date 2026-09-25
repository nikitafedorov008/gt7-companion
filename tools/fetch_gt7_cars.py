#!/usr/bin/env python3
"""Build the local GT7 car catalogue from the official car-list site.

The official car list (gran-turismo.com/gt7/carlist) ships its data as hashed
ES modules. This script downloads the three pieces we need and writes two small
JSON assets, so the app never scrapes at runtime:

  assets/cars/cars.json        id -> name, maker, class, power, weight
  assets/cars/car_images.json  id -> first official photo path

Re-run it when Polyphony rebuilds the site (asset hashes change):
    python3 tools/fetch_gt7_cars.py
"""

import json
import os
import re
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor

BASE = "https://www.gran-turismo.com/common/dist/gt7/carlist"
ENTRY = f"{BASE}/assets/index-BxejHdeX.js"


def get(url: str, attempts: int = 4) -> bytes:
    """Fetches with backoff: the site throttles a burst of requests."""
    last = None
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(url, timeout=30) as r:
                return r.read()
        except Exception as error:  # noqa: BLE001 - retry, then report
            last = error
            time.sleep(0.4 * (attempt + 1))
    raise last


def to_json(node: str) -> str:
    """The datasets are JS object literals.

    Keys are unquoted and strings are backtick templates, and some names carry
    literal double quotes inside ("LEXUS LF-LC GT "Vision Gran Turismo""), so
    quote the keys first and then convert each template to an escaped string.
    """
    node = re.sub(r"([{,])\s*([A-Za-z_][A-Za-z0-9_]*)\s*:", r'\1"\2":', node)

    def escape(match: "re.Match[str]") -> str:
        inner = match.group(1).replace("\\", "\\\\").replace('"', '\\"')
        return '"' + inner + '"'

    return re.sub(r"`([^`]*)`", escape, node)



def _object_literal(module: str) -> str:
    """The data module is `var e={...};export{e as Cars}` - take just the object."""
    body = module[module.index("{"):]
    for marker in (";export", "export{"):
        cut = body.find(marker)
        if cut != -1:
            body = body[:cut]
            break
    return body[: body.rindex("}") + 1]


def main() -> None:
    bundle = get(ENTRY).decode("utf-8", "ignore")

    # 1. car records: var e={car102:{...},...}
    cars_chunk = re.search(r"cars\.us-([A-Za-z0-9_\-]+)\.js", bundle)
    cars_js = get(f"{BASE}/assets/cars.us-{cars_chunk.group(1)}.js").decode("utf-8", "ignore")
    records = json.loads(to_json(_object_literal(cars_js)))

    cars = {}
    for car_id, c in records.items():
        cars[car_id] = {
            "name": c.get("nameLong") or c.get("nameShort") or "",
            "short": c.get("nameShort") or "",
            "maker": c.get("manufacturerId", ""),
            "class": c.get("carClass", ""),
            "power": c.get("power", ""),
            "weight": c.get("weight", ""),
            # The official catalogue also carries the performance point the
            # game shows (as the string "PP 454.66"), the drivetrain layout and
            # the induction type - all per car, all in the chosen locale.
            "pp": (c.get("performancePoint") or "").replace("PP", "").strip(),
            "drive": c.get("driveTrain", ""),
            "aspiration": c.get("aspirationShort", ""),
        }

    # 2. photos: the index names the shots, the per-shot chunk carries the
    #    hashed asset path.
    shots_js = get(f"{BASE}/assets/{_chunk(bundle, 'car-shots-index')}").decode("utf-8", "ignore")
    shots = json.loads(to_json(_object_literal(shots_js)))

    chunk_names = dict(
        re.findall(r"import\(`\./(car[0-9]+_[0-9]+_[0-9]+)-([A-Za-z0-9_\-]+)\.js`\)", bundle)
    )

    def photo(car_id: str):
        names = shots.get(car_id) or []
        if not names:
            return None
        first = names[0].replace(".jpg", "")
        fingerprint = chunk_names.get(first)
        if not fingerprint:
            return None
        try:
            js = get(f"{BASE}/assets/{first}-{fingerprint}.js").decode("utf-8", "ignore")
            m = re.search(r"`(/common/[^`]+)`", js)
            return m.group(1) if m else None
        except Exception:
            return None

    ids = [i for i in shots if i in cars]

    # Never lose what an earlier run already resolved: the site throttles, and
    # a re-run that happens to fail must not shrink the asset. Successful
    # lookups overwrite, everything else is kept as it was.
    images_path = "assets/cars/car_images.json"
    known: dict[str, str] = {}
    if os.path.exists(images_path):
        with open(images_path) as f:
            known = json.load(f)

    with ThreadPoolExecutor(max_workers=4) as pool:
        fetched = dict(zip(ids, pool.map(photo, ids)))

    images = {**known, **{k: v for k, v in fetched.items() if v}}

    cars_path = "assets/cars/cars.json"
    with open(cars_path, "w") as f:
        json.dump(cars, f, ensure_ascii=False, separators=(",", ":"), sort_keys=True)
    with open(images_path, "w") as f:
        json.dump({k: v for k, v in images.items() if v}, f, separators=(",", ":"), sort_keys=True)

    missing = [i for i in ids if i not in images]
    print(f"{len(cars)} cars -> {cars_path}")
    print(f"{len(images)} photos -> {images_path} ({len(missing)} still unresolved)")
    if missing:
        print("re-run to pick up the rest; resolved entries are never dropped")


def _chunk(bundle: str, prefix: str) -> str:
    m = re.search(rf"\./({prefix}-[A-Za-z0-9_\-]+\.js)", bundle)
    return m.group(1)



if __name__ == "__main__":
    main()
