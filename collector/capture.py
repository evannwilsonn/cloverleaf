"""
Record a short clip from every camera in seeds/cameras.csv and turn it into traffic measurements.

For each camera:
  1. open the Caltrans HLS stream and read CLIP_SECONDS of video, keeping SAMPLE_FPS frames a second
  2. run YOLOv8 with ByteTrack over those frames (cars, motorcycles, buses, trucks)
  3. summarise: vehicles in view per frame, vehicles that moved through the view (tracks), how fast
     tracks crossed the frame, plus image-quality signals the pipeline uses to accept or exclude
     the capture (brightness, sharpness, frozen feed)

One JSON line per camera is written to data/captures/<date>/<run_id>.jsonl. Nothing is judged here:
offline feeds, dark frames and frozen video are recorded as measured, and the dbt rules decide.

    python collector/capture.py                    # every camera
    python collector/capture.py --only tv516 tvd01 # a few
    python collector/capture.py --save-frames eval/frames   # also keep one frame per camera
"""
from __future__ import annotations

import argparse
import csv
import json
import math
import os
import platform
import subprocess
import time
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

os.environ.setdefault("OPENCV_FFMPEG_CAPTURE_OPTIONS", "rw_timeout;15000000")
import cv2  # noqa: E402
import numpy as np  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
CLIP_SECONDS = 12
SAMPLE_FPS = 3
WIDTH = 960                       # frames are resized to this width before detection
MODEL = os.environ.get("CLOVERLEAF_MODEL", "yolov8s.pt")
CONF = 0.25
VEHICLES = {2: "car", 3: "motorcycle", 5: "bus", 7: "truck"}
MIN_TRACK_FRAMES = 3              # a track must be seen this many times to count
MIN_TRACK_TRAVEL = 0.04           # ...and travel this share of the frame diagonal


def read_clip(cam: dict) -> dict:
    """Read the clip. Returns frames plus stream facts; never raises."""
    t0 = time.time()
    out = {"frames": [], "status": "ok", "error": None, "stream_fps": None, "width": None, "height": None}
    cap = cv2.VideoCapture(cam["stream_url"], cv2.CAP_FFMPEG)
    try:
        if not cap.isOpened():
            out.update(status="offline", error="stream did not open")
            return out
        fps = cap.get(cv2.CAP_PROP_FPS) or 0
        fps = fps if 1 <= fps <= 60 else 15
        out.update(stream_fps=round(fps, 2), width=int(cap.get(3)), height=int(cap.get(4)))
        step = max(1, round(fps / SAMPLE_FPS))
        total = int(fps * CLIP_SECONDS)
        for i in range(total):
            ok = cap.grab()
            if not ok:
                break
            if i % step == 0:
                ok, f = cap.retrieve()
                if ok:
                    h, w = f.shape[:2]
                    out["frames"].append(cv2.resize(f, (WIDTH, round(h * WIDTH / w))))
            if time.time() - t0 > CLIP_SECONDS * 4:   # a stalled stream shouldn't hold the run
                out["error"] = "stream stalled"
                break
        if not out["frames"]:
            out.update(status="error", error=out["error"] or "no frames decoded")
    except Exception as exc:  # noqa: BLE001
        out.update(status="error", error=str(exc)[:300])
    finally:
        cap.release()
        out["read_seconds"] = round(time.time() - t0, 2)
    return out


def image_signals(frames: list[np.ndarray]) -> dict:
    grays = [cv2.cvtColor(f, cv2.COLOR_BGR2GRAY) for f in frames]
    mid = grays[len(grays) // 2]
    diffs = [float(np.mean(cv2.absdiff(a, b))) for a, b in zip(grays, grays[1:])]
    return {
        "brightness": round(float(np.mean([g.mean() for g in grays])), 2),
        "contrast": round(float(mid.std()), 2),
        "sharpness": round(float(cv2.Laplacian(mid, cv2.CV_64F).var()), 2),
        # mean pixel change between consecutive sampled frames; ~0 means the feed is frozen
        "motion": round(float(np.mean(diffs)) if diffs else 0.0, 3),
    }


def analyse(frames: list[np.ndarray], fps: float) -> dict:
    from ultralytics import YOLO
    model = YOLO(MODEL)                     # a fresh model per camera keeps tracker state separate
    h, w = frames[0].shape[:2]
    diag = math.hypot(w, h)
    per_frame = {name: [] for name in VEHICLES.values()}
    tracks: dict[int, dict] = {}
    for i, f in enumerate(frames):
        r = model.track(f, persist=True, tracker="bytetrack.yaml", classes=list(VEHICLES), conf=CONF,
                        imgsz=WIDTH, verbose=False)[0]
        cls = r.boxes.cls.int().tolist() if r.boxes is not None else []
        for k, name in VEHICLES.items():
            per_frame[name].append(sum(1 for c in cls if c == k))
        if r.boxes is not None and r.boxes.id is not None:
            for tid, c, box in zip(r.boxes.id.int().tolist(), cls, r.boxes.xywh.tolist()):
                t = tracks.setdefault(tid, {"cls": [], "pts": [], "frames": []})
                t["cls"].append(c)
                t["pts"].append(box[:2])
                t["frames"].append(i)
    moving = {name: 0 for name in VEHICLES.values()}
    speeds = []
    for t in tracks.values():
        if len(t["frames"]) < MIN_TRACK_FRAMES:
            continue
        (x0, y0), (x1, y1) = t["pts"][0], t["pts"][-1]
        travel = math.hypot(x1 - x0, y1 - y0) / diag
        if travel < MIN_TRACK_TRAVEL:
            continue
        name = VEHICLES[max(set(t["cls"]), key=t["cls"].count)]
        moving[name] += 1
        secs = (t["frames"][-1] - t["frames"][0]) / SAMPLE_FPS
        if secs > 0:
            speeds.append(travel / secs)
    n = len(frames)
    return {
        "frames_analyzed": n,
        "clip_seconds": round(n / SAMPLE_FPS, 2),
        "in_view_mean": {k: round(sum(v) / n, 3) for k, v in per_frame.items()},
        "in_view_max": {k: max(v) for k, v in per_frame.items()},
        "tracks_total": len(tracks),
        "moving_vehicles": moving,
        # median share of the frame diagonal a moving vehicle covers per second (a relative speed index)
        "speed_index": round(float(np.median(speeds)), 4) if speeds else None,
    }


def solar_elevation(lat: float, lon: float, when: datetime) -> float:
    """Approximate sun elevation in degrees (NOAA formula, good to ~1 degree)."""
    doy = when.timetuple().tm_yday
    hour = when.hour + when.minute / 60 + when.second / 3600
    g = 2 * math.pi / 365 * (doy - 1 + (hour - 12) / 24)
    decl = (0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g) - 0.006758 * math.cos(2 * g)
            + 0.000907 * math.sin(2 * g) - 0.002697 * math.cos(3 * g) + 0.00148 * math.sin(3 * g))
    eqt = 229.18 * (0.000075 + 0.001868 * math.cos(g) - 0.032077 * math.sin(g)
                    - 0.014615 * math.cos(2 * g) - 0.040849 * math.sin(2 * g))
    tst = hour * 60 + eqt + 4 * lon
    ha = math.radians(tst / 4 - 180)
    la = math.radians(lat)
    cos_z = math.sin(la) * math.sin(decl) + math.cos(la) * math.cos(decl) * math.cos(ha)
    return round(90 - math.degrees(math.acos(max(-1, min(1, cos_z)))), 2)


def git_commit() -> str | None:
    try:
        return subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, capture_output=True,
                              text=True, timeout=5).stdout.strip() or None
    except Exception:  # noqa: BLE001
        return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*")
    ap.add_argument("--save-frames", help="directory to keep the middle frame of each clip (for labelling)")
    ap.add_argument("--out", default=str(ROOT / "data" / "captures"))
    args = ap.parse_args()

    cams = list(csv.DictReader(open(ROOT / "seeds" / "cameras.csv", encoding="utf-8")))
    if args.only:
        cams = [c for c in cams if c["camera_id"] in args.only]
    run_id = uuid.uuid4().hex[:12]
    started = datetime.now(timezone.utc).replace(microsecond=0)
    t0 = time.time()

    # streams are read in parallel (network-bound); detection runs one camera at a time (CPU-bound)
    with ThreadPoolExecutor(max_workers=10) as ex:
        clips = list(ex.map(read_clip, cams))

    day = started.strftime("%Y-%m-%d")
    out_dir = Path(args.out) / day
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / f"{started.strftime('%H%M%S')}_{run_id}.jsonl"
    base = {"run_id": run_id, "run_started_at": started.isoformat(), "runner": os.environ.get("GITHUB_ACTIONS") and "github-actions" or platform.node(),
            "code_version": git_commit(), "model": MODEL, "clip_target_seconds": CLIP_SECONDS, "sample_fps": SAMPLE_FPS}
    ok = 0
    with open(out_file, "w", encoding="utf-8") as fh:
        for cam, clip in zip(cams, clips):
            captured = datetime.now(timezone.utc).replace(microsecond=0)
            rec = {**base, "camera_id": cam["camera_id"], "captured_at": captured.isoformat(),
                   "sun_elevation": solar_elevation(float(cam["latitude"]), float(cam["longitude"]), captured),
                   "status": clip["status"], "error": clip["error"], "stream_fps": clip["stream_fps"],
                   "source_width": clip["width"], "source_height": clip["height"], "read_seconds": clip.get("read_seconds")}
            if clip["frames"]:
                try:
                    rec.update(image_signals(clip["frames"]))
                    rec.update(analyse(clip["frames"], clip["stream_fps"] or 15))
                    ok += 1
                    if args.save_frames:
                        d = Path(args.save_frames)
                        d.mkdir(parents=True, exist_ok=True)
                        cv2.imwrite(str(d / f"{cam['camera_id']}_{started.strftime('%Y%m%dT%H%M%S')}.jpg"),
                                    clip["frames"][len(clip["frames"]) // 2], [cv2.IMWRITE_JPEG_QUALITY, 88])
                except Exception as exc:  # noqa: BLE001
                    rec.update(status="error", error=f"analysis failed: {exc}"[:300])
            fh.write(json.dumps(rec) + "\n")
            print(f"{cam['camera_id']:<6} {rec['status']:<8} moving={sum(rec.get('moving_vehicles', {}).values()):>3} "
                  f"in_view={sum(rec.get('in_view_mean', {}).values()):>5.1f} bright={rec.get('brightness')} sun={rec['sun_elevation']}")
    print(f"run {run_id}: {ok}/{len(cams)} cameras analysed in {time.time() - t0:.0f}s -> {out_file.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
