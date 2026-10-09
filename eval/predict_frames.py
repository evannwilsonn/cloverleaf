"""
Run the collector's detector over the hand-labelled evaluation frames (eval/frames/*.jpg) with
exactly the collector's settings, and write eval/predictions.csv. dbt compares these counts to
seeds/eval_labels.csv in rpt_detection_accuracy and fails the build if daylight accuracy drops
below the gate.

Each label may set count_zone_top (0-1): in busy frames the far traffic cannot be counted by hand,
so both the person and the detector count only vehicles whose centre is below that fraction of the height.

Frame names are <camera_id>_<YYYYMMDDTHHMMSS>.jpg (UTC), as saved by capture.py --save-frames.

    python eval/predict_frames.py
"""
from __future__ import annotations

import csv
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "collector"))
import capture  # noqa: E402

import cv2  # noqa: E402
from ultralytics import YOLO  # noqa: E402


def main() -> None:
    cams = {c["camera_id"]: c for c in csv.DictReader(open(ROOT / "seeds" / "cameras.csv", encoding="utf-8"))}
    labels = {r["frame_file"]: r for r in csv.DictReader(open(ROOT / "seeds" / "eval_labels.csv", encoding="utf-8"))}
    model = YOLO(capture.MODEL)
    rows = []
    for f in sorted((ROOT / "eval" / "frames").glob("*.jpg")):
        cam_id, stamp = f.stem.rsplit("_", 1)
        when = datetime.strptime(stamp, "%Y%m%dT%H%M%S").replace(tzinfo=timezone.utc)
        cam = cams[cam_id]
        r = model.predict(cv2.imread(str(f)), classes=list(capture.VEHICLES), conf=capture.CONF,
                          imgsz=capture.WIDTH, verbose=False)[0]
        # Count only inside the frame's counting zone (the part a person could count reliably):
        # boxes whose centre is at or below count_zone_top x frame height. Blank = the whole frame.
        zone = (labels.get(f.name) or {}).get("count_zone_top") or "0"
        y_min = float(zone) * r.orig_shape[0]
        centre_y = r.boxes.xywh[:, 1].tolist()
        cls = [c for c, y in zip(r.boxes.cls.int().tolist(), centre_y) if y >= y_min]
        counts = {name: sum(1 for c in cls if c == k) for k, name in capture.VEHICLES.items()}
        rows.append({"frame_file": f.name, "camera_id": cam_id, "cars": counts["car"], "trucks": counts["truck"],
                     "buses": counts["bus"], "motorcycles": counts["motorcycle"],
                     "sun_elevation": capture.solar_elevation(float(cam["latitude"]), float(cam["longitude"]), when),
                     "model": capture.MODEL})
    with open(ROOT / "eval" / "predictions.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"{len(rows)} frames -> eval/predictions.csv")


if __name__ == "__main__":
    main()
