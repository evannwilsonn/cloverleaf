"""
Bring the collected captures and weather from the repo's `data` branch into data/.

The GitHub Actions collector appends a file to the `data` branch every 30 minutes. This copies
that branch's captures/ and weather/ folders here (without switching branches) so the load step
sees everything collected so far.

    python ingest/sync_data.py
"""
from __future__ import annotations

import subprocess
import tarfile
import io
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    subprocess.run(["git", "fetch", "--quiet", "origin", "data"], cwd=ROOT, check=True)
    tar = subprocess.run(["git", "archive", "origin/data", "captures", "weather"], cwd=ROOT,
                         check=True, capture_output=True).stdout
    with tarfile.open(fileobj=io.BytesIO(tar)) as t:
        t.extractall(ROOT / "data", filter="data")
    caps = list((ROOT / "data" / "captures").rglob("*.jsonl"))
    wx = list((ROOT / "data" / "weather").rglob("*.jsonl"))
    print(f"data/: {len(caps)} capture files, {len(wx)} weather files")


if __name__ == "__main__":
    main()
