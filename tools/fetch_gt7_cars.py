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
CAR_LIST = "https://www.gran-turismo.com/us/gt7/carlist/"


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
    """Parse the data-only JS literal grammar; never execute downloaded code.

    Strings can contain newlines, quotes, escaped delimiters and backslashes.
    Unsupported expressions/interpolation fail closed instead of being evaluated.
    """
    pos = 0

    def whitespace():
        nonlocal pos
        while pos < len(node) and node[pos].isspace():
            pos += 1

    def string():
        nonlocal pos
        quote = node[pos]
        pos += 1
        result = []
        while pos < len(node):
            ch = node[pos]
            pos += 1
            if ch == quote:
                return ''.join(result)
            if ch == '$' and quote == '`' and node[pos:pos + 1] == '{':
                raise ValueError('Template interpolation is not data')
            if ch == chr(92):
                if pos >= len(node):
                    raise ValueError('Unterminated escape')
                ch = node[pos]
                pos += 1
                if ch in 'ux':
                    count = 4 if ch == 'u' else 2
                    result.append(chr(int(node[pos:pos + count], 16)))
                    pos += count
                    continue
                ch = {'n': chr(10), 'r': chr(13), 't': chr(9),
                      'b': chr(8), 'f': chr(12)}.get(ch, ch)
            result.append(ch)
        raise ValueError('Unterminated string')

    def value():
        nonlocal pos
        whitespace()
        if pos >= len(node):
            raise ValueError('Missing value')
        ch = node[pos]
        if ch in ('`', '"', "'"):
            return string()
        if ch in '{[':
            pos += 1
            obj = {} if ch == '{' else []
            close = '}' if ch == '{' else ']'
            whitespace()
            while node[pos:pos + 1] != close:
                if isinstance(obj, dict):
                    whitespace()
                    if node[pos] in ('`', '"', "'"):
                        key = string()
                    else:
                        match = re.match(r'[A-Za-z_$][A-Za-z0-9_$]*', node[pos:])
                        if not match:
                            raise ValueError('Invalid object key')
                        key = match[0]
                        pos += len(key)
                    whitespace()
                    if node[pos:pos + 1] != ':':
                        raise ValueError('Missing colon')
                    pos += 1
                    if key in obj:
                        raise ValueError('Duplicate key')
                    obj[key] = value()
                else:
                    obj.append(value())
                whitespace()
                if node[pos:pos + 1] == ',':
                    pos += 1
                    whitespace()
                elif node[pos:pos + 1] != close:
                    raise ValueError('Missing separator')
            pos += 1
            return obj
        match = re.match(r'(?:-?(?:0|[1-9][0-9]*)(?:[.][0-9]+)?(?:[eE][+-]?[0-9]+)?|true|false|null)(?=[,}\]\s]|$)', node[pos:])
        if not match:
            raise ValueError('Unsupported JavaScript expression')
        pos += len(match[0])
        return json.loads(match[0])

    result = value()
    whitespace()
    if pos != len(node):
        raise ValueError('Unexpected trailing code')
    return json.dumps(result, ensure_ascii=False)


def _object_literal(module: str) -> str:
    """The data module is `var e={...};export{e as Cars}` - take just the object."""
    body = module[module.index("{"):]
    for marker in (";export", "export{"):
        cut = body.find(marker)
        if cut != -1:
            body = body[:cut]
            break
    return body[: body.rindex("}") + 1]


def build_brand_central(bundle: str, output="assets/cars/brand_central.json"):
    def dataset(prefix):
        return json.loads(to_json(_object_literal(
            get(f"{BASE}/assets/{_chunk(bundle, prefix)}").decode("utf-8"))))

    editions = {}
    for lang, locale in (("en", "us"), ("ru", "ru")):
        cars = dataset(f"cars.{locale}")
        descriptions = dataset(f"descriptions.{locale}")
        for car_id, car in cars.items():
            if not re.fullmatch(r"car[0-9]+", car_id) or car.get("id") != car_id:
                raise ValueError("Invalid official car ID")
            car.update(descriptions.get(car_id, {}))
        editions[lang] = cars
    brands = dataset("tuners.us")
    countries = dataset("countries.us")
    shots = dataset("car-shots-index")
    modules = dict(re.findall(
        r"import\(`\./(car[0-9]+_[0-9]+_[0-9]+)-([A-Za-z0-9_\-]+)\.js`\)", bundle))
    gallery = {car: [f"{name[:-4]}-{modules[name[:-4]]}.js"
                    for name in sorted(names, key=lambda shot: ('_2_01' not in shot, shot)) if name[:-4] in modules]
               for car, names in shots.items() if car in editions['en']}
    for lang, cars in editions.items():
        for car in cars.values():
            if car['manufacturerId'] not in brands or car['countryId'] not in countries:
                raise ValueError('Unresolved catalogue join')
            if not car.get('desc') or not gallery.get(car['id']):
                raise ValueError('Missing official history or gallery')
    result = {"source": CAR_LIST, "editions": editions, "brands": brands,
              "countries": countries, "gallery": gallery}
    with open(output, 'w') as f:
        json.dump(result, f, ensure_ascii=False, separators=(',', ':'), sort_keys=True)
    print(f"Brand Central: {len(editions['en'])} cars, {len(brands)} brands -> {output}")


def main() -> None:
    page = get(CAR_LIST).decode("utf-8", "ignore")
    entry = re.search(r'(/common/dist/gt7/carlist/assets/index-[A-Za-z0-9_-]+\.js)', page)
    if not entry:
        raise RuntimeError("Official catalogue entrypoint changed")
    bundle = get("https://www.gran-turismo.com" + entry.group(1)).decode("utf-8", "ignore")

    if '--brand-central-only' in __import__('sys').argv:
        build_brand_central(bundle)
        return

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

    build_brand_central(bundle)

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
    m = re.search(rf"\./({re.escape(prefix)}-[A-Za-z0-9_\-]+\.js)", bundle)
    return m.group(1)



if __name__ == "__main__":
    main()
