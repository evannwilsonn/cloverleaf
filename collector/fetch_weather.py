"""
Pull recent hourly-ish observations from the National Weather Service for every station in
seeds/weather_stations.csv. The NWS API only keeps about a week, so this runs alongside the
camera collector and each pull is kept; staging de-duplicates on station + timestamp.

    python collector/fetch_weather.py              # last 6 hours
    python collector/fetch_weather.py --hours 168  # backfill the week the API still has
"""
from __future__ import annotations

import argparse
import csv
import json
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UA = {"User-Agent": "cloverleaf traffic pipeline (github.com/evannwilsonn/cloverleaf)", "Accept": "application/geo+json"}
KEEP = ("timestamp", "textDescription", "temperature", "dewpoint", "windSpeed", "windGust", "visibility",
        "precipitationLastHour", "precipitationLast3Hours", "relativeHumidity", "presentWeather", "cloudLayers")


def fetch(station: str, since: datetime) -> list[dict]:
    url = f"https://api.weather.gov/stations/{station}/observations?start={since.strftime('%Y-%m-%dT%H:%M:%SZ')}"
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
        feats = json.load(r)["features"]
    return [{"station_id": station, **{k: f["properties"].get(k) for k in KEEP}} for f in feats]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--hours", type=int, default=6)
    ap.add_argument("--out", default=str(ROOT / "data" / "weather"))
    args = ap.parse_args()
    now = datetime.now(timezone.utc).replace(microsecond=0)
    since = now - timedelta(hours=args.hours)
    rows, failed = [], []
    for s in csv.DictReader(open(ROOT / "seeds" / "weather_stations.csv", encoding="utf-8")):
        try:
            rows += fetch(s["station_id"], since)
        except Exception as exc:  # noqa: BLE001  one station down shouldn't stop the rest
            failed.append(f"{s['station_id']}: {exc}")
    out = Path(args.out) / now.strftime("%Y-%m-%d")
    out.mkdir(parents=True, exist_ok=True)
    path = out / f"{now.strftime('%H%M%S')}.jsonl"
    with open(path, "w", encoding="utf-8") as fh:
        for r in rows:
            fh.write(json.dumps({**r, "fetched_at": now.isoformat()}) + "\n")
    print(f"{len(rows)} observations -> {path.relative_to(ROOT)}" + (f"; failed: {failed}" if failed else ""))


if __name__ == "__main__":
    main()
