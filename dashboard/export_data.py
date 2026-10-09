"""
Export the reporting marts to dashboard/data.json, plus a current still from each camera.

Reads the local DuckDB warehouse by default, or Snowflake with --target snowflake (key-pair
sign-in via SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER and SNOWFLAKE_PRIVATE_KEY_PATH).

    python dashboard/export_data.py
    python dashboard/export_data.py --target snowflake
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import urllib.request
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[1]
TABLES = {
    "kpis": "select * from reporting.rpt_kpi_daily order by local_date, kpi_id",
    "corridors": "select * from reporting.rpt_corridor_daily order by local_date, corridor",
    "hourly": "select * from reporting.rpt_hourly_profile order by corridor, day_type, local_hour",
    "cameras": "select * from reporting.rpt_camera_status order by corridor, camera_name",
    "quality": "select * from reporting.rpt_data_quality order by local_date, priority",
    "weather": "select * from reporting.rpt_weather_impact order by daylight_captures desc",
    "accuracy": "select * from reporting.rpt_detection_accuracy order by light desc",
    "timeline": "select * from reporting.rpt_network_timeline order by run_started_at_local",
    "captures": """select run_id, camera_id, captured_at_local, is_daylight, is_valid, exclusion_reason,
                           vehicles_per_min, moving_vehicles, moving_heavy, is_congested, speed_ratio, clip_seconds
                    from core.fct_captures
                    where captured_at >= (select max(captured_at) from core.fct_captures) - interval '48 hours'
                    order by captured_at_local, camera_id""",
    "kpi_catalog": "select * from reference.kpi_catalog",
    "qc_rules": "select * from reference.qc_rules order by priority",
}


def clean(v):
    if isinstance(v, (datetime, date)):
        return v.isoformat()
    if isinstance(v, Decimal):
        return float(v)
    if isinstance(v, float):
        return round(v, 4)
    return v


def query(target: str):
    if target == "snowflake":
        import snowflake.connector
        con = snowflake.connector.connect(
            account=os.environ["SNOWFLAKE_ACCOUNT"], user=os.environ["SNOWFLAKE_USER"],
            private_key_file=os.environ["SNOWFLAKE_PRIVATE_KEY_PATH"], role=os.environ.get("SNOWFLAKE_ROLE", "SYSADMIN"),
            warehouse=os.environ.get("SNOWFLAKE_WAREHOUSE", "PORTFOLIO_WH"), database="CLOVERLEAF")

        def run(sql):
            cur = con.cursor()
            cur.execute(sql)
            return [c[0].lower() for c in cur.description], cur.fetchall()
    else:
        import duckdb
        con = duckdb.connect(str(ROOT / "warehouse" / "cloverleaf.duckdb"), read_only=True)

        def run(sql):
            cur = con.execute(sql)
            return [c[0] for c in cur.description], cur.fetchall()
    return run


def still(url: str) -> str | None:
    """A small current still from the camera, inlined so the dashboard needs no live requests."""
    try:
        import cv2
        import numpy as np
        req = urllib.request.Request(url, headers={"User-Agent": "cloverleaf dashboard export"})
        raw = urllib.request.urlopen(req, timeout=15).read()
        img = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
        h, w = img.shape[:2]
        img = cv2.resize(img, (360, round(h * 360 / w)))
        ok, buf = cv2.imencode(".jpg", img, [cv2.IMWRITE_JPEG_QUALITY, 70])
        return "data:image/jpeg;base64," + base64.b64encode(buf.tobytes()).decode() if ok else None
    except Exception:  # noqa: BLE001
        return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", choices=["duckdb", "snowflake"], default="duckdb")
    ap.add_argument("--no-stills", action="store_true")
    args = ap.parse_args()
    run = query(args.target)
    out = {"generated": datetime.now(ZoneInfo("America/Los_Angeles")).replace(tzinfo=None).isoformat(timespec="seconds"),
           "source": args.target}
    for key, sql in TABLES.items():
        cols, rows = run(sql)
        out[key] = [{c: clean(v) for c, v in zip(cols, r)} for r in rows]
    # thresholds the page quotes, read from dbt's vars so the page never hardcodes them
    import yaml
    v = yaml.safe_load((ROOT / "dbt_project.yml").read_text(encoding="utf-8")).get("vars", {})
    out["meta"] = {k: v.get(k) for k in ("runs_per_day", "min_daylight_count_ratio", "max_daylight_mean_abs_pct_error")}
    if not args.no_stills:
        for cam in out["cameras"]:
            cam["still"] = still(cam["still_url"])
    path = ROOT / "dashboard" / "data.json"
    path.write_text(json.dumps(out, separators=(",", ":")), encoding="utf-8")
    t = out["timeline"]
    print(f"Wrote {path.relative_to(ROOT)} ({path.stat().st_size // 1024} KB, {len(t)} runs, "
          f"{len(out['cameras'])} cameras) from {args.target}")


if __name__ == "__main__":
    main()
