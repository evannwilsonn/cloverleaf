"""
Land everything collected so far in the warehouse, unchanged (schema raw_cloverleaf).

  raw_cloverleaf.captures              one JSON payload per camera per collector run
  raw_cloverleaf.weather_observations  one JSON payload per NWS observation pull row
  raw_cloverleaf.eval_predictions      detector counts on the hand-labelled evaluation frames

Every row keeps _source_file and _loaded_at. Types and de-duplication happen in dbt staging.

    python ingest/load_raw.py
"""
from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
DB = ROOT / "warehouse" / "cloverleaf.duckdb"


def land_jsonl(con, table: str, folder: Path, loaded_at: str) -> int:
    files = sorted(folder.rglob("*.jsonl"))
    if not files:
        raise SystemExit(f"No files in {folder.relative_to(ROOT)}. Run ingest/sync_data.py or the collector first.")
    paths = [f.as_posix() for f in files]
    con.execute(f"""
        create or replace table raw_cloverleaf.{table} as
        select json as payload,
               regexp_extract(filename, '(captures|weather)/.*$') as _source_file,
               cast('{loaded_at}' as timestamp) as _loaded_at
        from read_json_objects({paths}, format = 'newline_delimited', filename = true)""")
    n = con.execute(f"select count(*) from raw_cloverleaf.{table}").fetchone()[0]
    lines = sum(sum(1 for line in open(f, encoding="utf-8") if line.strip()) for f in files)
    if n != lines:
        raise SystemExit(f"{table}: loaded {n} rows but the files hold {lines} lines")
    return n


def main() -> None:
    DB.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(DB))
    con.execute("create schema if not exists raw_cloverleaf")
    loaded_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    n1 = land_jsonl(con, "captures", DATA / "captures", loaded_at)
    n2 = land_jsonl(con, "weather_observations", DATA / "weather", loaded_at)
    preds = ROOT / "eval" / "predictions.csv"
    con.execute(f"""create or replace table raw_cloverleaf.eval_predictions as
        select *, 'eval/predictions.csv' as _source_file, cast('{loaded_at}' as timestamp) as _loaded_at
        from read_csv('{preds.as_posix()}', header = true, all_varchar = true)""")
    n3 = con.execute("select count(*) from raw_cloverleaf.eval_predictions").fetchone()[0]
    print(f"Loaded into {DB.relative_to(ROOT)}")
    print(f"  raw_cloverleaf.captures              {n1:>8,} rows")
    print(f"  raw_cloverleaf.weather_observations  {n2:>8,} rows")
    print(f"  raw_cloverleaf.eval_predictions      {n3:>8,} rows")


if __name__ == "__main__":
    main()
