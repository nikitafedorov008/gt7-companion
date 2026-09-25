#!/usr/bin/env python3
"""Builds assets/tracks/tracks.json from the community GT7 course database.

Source: ddm999/gt7info, which publishes the CSVs the community maintains at
https://ddm999.github.io/gt7info/data/db/. The file the site offers is the same
one at https://raw.githubusercontent.com/ddm999/gt7info/web-new/_data/db/.

Why this exists: GT7's UDP packet carries **no track id** (the community asked
for years; Polyphony never added one). What it does carry is the car's position,
so the app can measure the lap distance, the elevation span and the number of
corners of a lap it has driven, and match that signature against this table.

Run from the repository root:  python3 tools/fetch_gt7_tracks.py
"""

import csv
import io
import json
import urllib.request

SOURCES = [
    "https://ddm999.github.io/gt7info/data/db/course.csv",
    "https://raw.githubusercontent.com/ddm999/gt7info/web-new/_data/db/course.csv",
]
OUT = "assets/tracks/tracks.json"


def fetch() -> str:
    last = None
    for url in SOURCES:
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                if response.status == 200:
                    print(f"fetched {url}")
                    return response.read().decode("utf-8", "ignore")
        except Exception as error:  # noqa: BLE001 - report and try the next host
            last = error
    raise SystemExit(f"could not download the course database: {last}")


def main() -> None:
    rows = list(csv.DictReader(io.StringIO(fetch())))

    tracks = {}
    for row in rows:
        try:
            track_id = int(row["ID"])
            length = int(row["Length"])
        except (KeyError, TypeError, ValueError):
            continue
        if length <= 0:
            continue

        def number(key: str, cast=float):
            try:
                return cast(row[key])
            except (KeyError, TypeError, ValueError):
                return None

        tracks[str(track_id)] = {
            "name": row["Name"].strip(),
            "length": length,
            "corners": number("NumCorners", int),
            "elevation": number("ElevationDiff"),
            "straight": number("LongestStraight", int),
            "oval": number("IsOval", int) == 1,
            "reverse": number("IsReverse", int) == 1,
            "country": number("Country", int),
            "category": (row.get("Category") or "").strip(),
        }

    with open(OUT, "w") as handle:
        json.dump(tracks, handle, separators=(",", ":"), sort_keys=True)

    ovals = sum(1 for t in tracks.values() if t["oval"])
    print(f"{len(tracks)} tracks ({ovals} ovals) -> {OUT}")


if __name__ == "__main__":
    main()
