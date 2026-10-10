"""make_toon_models.py - the toon characters' 3D models (TOON_WORKFLOW.md,
workflow 2), with Stable Fast 3D on this PC.

Made like the batch that worked on 7-8 Oct: each front picture is copied to a
work folder with no spaces and outside OneDrive, Stable Fast 3D runs there
with relative paths, and only the finished mesh.glb is copied back to
art/models/<name>-toon.glb. (Pointing it straight at the OneDrive game folder,
whose path has spaces, left Brainy's output empty on 10 Oct.)

Stable Fast 3D makes a model from ONE picture: the front. The back picture is
only checked (it must exist) and its colors are left to Claude's render check.

Run with the Stable Fast 3D Python (it has torch and trimesh):
  <sf3d-venv>\\Scripts\\python.exe tools\\make_toon_models.py            (all)
  <sf3d-venv>\\Scripts\\python.exe tools\\make_toon_models.py tinker     (one)
  <sf3d-venv>\\Scripts\\python.exe tools\\make_toon_models.py brainy shadow
"""
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
TOOL_ROOT = Path(r"C:\Users\bwood\Documents\Codex\2026-10-05\referenced-chatgpt-conversation-this-is-an")
SF3D = TOOL_ROOT / "work" / "stable-fast-3d"
PYTHON = TOOL_ROOT / "work" / "sf3d-venv" / "Scripts" / "python.exe"
WORK = TOOL_ROOT / "work" / "toon"  # no spaces, not in OneDrive

MODEL_INPUT = PROJECT / "art" / "model-input"
MODELS = PROJECT / "art" / "models"

# picture folder -> the .glb it makes (Studio name: see TOON_WORKFLOW.md)
JOBS = {
    "tinker": "tinker-toon.glb",
    "brainy": "brainy-toon.glb",
    "shadow": "shadow-toon.glb",
    "muscle": "muscle-toon.glb",
    "glow": "glow-toon.glb",
    "patch": "patch-toon.glb",
    "echo": "echo-toon.glb",
    "bramble": "bramble-toon.glb",
    "halloween-nurse-patch": "halloween-nurse-patch-toon.glb",
    # the skins (10 Oct)
    "tinker-pumpkin": "tinker-pumpkin-toon.glb",
    "ghostly-shadow": "ghostly-shadow-toon.glb",
    "candy-glow": "candy-glow-toon.glb",
    "space-cadet-brainy": "space-cadet-brainy-toon.glb",
    "snow-day-muscle": "snow-day-muscle-toon.glb",
    "starlight-echo": "starlight-echo-toon.glb",
    "autumn-leaf-bramble": "autumn-leaf-bramble-toon.glb",
    "muscle-mummy": "muscle-mummy-toon.glb",
    # the hosts (10 Oct)
    "host": "host-toon.glb",
    "host-gummy": "host-gummy-toon.glb",
    "host-hospital": "host-hospital-toon.glb",
    "host-caretaker": "host-caretaker-toon.glb",
    "host-clownbear": "host-clownbear-toon.glb",
    "host-anglerfish": "host-anglerfish-toon.glb",
}
TEXTURE = 1024  # one 1024 x 1024 picture: plenty for flat cartoon colors
VERTICES = 4000  # about 8,000 triangles


def triangles(path):
    try:
        import trimesh

        scene = trimesh.load(path, force="scene")
        return sum(len(g.faces) for g in scene.geometry.values())
    except Exception as e:  # trimesh missing or the file odd: not fatal
        return f"? ({e})"


def make(slug):
    front = MODEL_INPUT / slug / "front-toon.png"
    back = MODEL_INPUT / slug / "back-toon.png"
    for pic in (front, back):
        if not pic.exists():
            raise FileNotFoundError(pic)
    job = WORK / slug
    if job.exists():
        shutil.rmtree(job)
    (job / "out").mkdir(parents=True)
    shutil.copy2(front, job / "front.png")

    env = os.environ.copy()
    env["HF_HUB_OFFLINE"] = "1"  # the model weights are already downloaded
    env["TRANSFORMERS_OFFLINE"] = "1"
    cmd = [
        str(PYTHON), "run.py",
        os.path.relpath(job / "front.png", SF3D),
        "--output-dir", os.path.relpath(job / "out", SF3D),
        "--texture-resolution", str(TEXTURE),
        "--remesh_option", "triangle",
        "--target_vertex_count", str(VERTICES),
        "--batch_size", "1",
    ]
    started = time.time()
    # it needs all of the RTX 4050's 6 GB (peak 6.2 GB on 10 Oct): a crash
    # (exit code 3221225477) usually means something else was using the card -
    # one more try, then give up with advice
    for attempt in (1, 2):
        proc = subprocess.run(cmd, cwd=SF3D, env=env, text=True)
        if proc.returncode == 0:
            break
        print(f"Stable Fast 3D crashed for {slug} (exit code {proc.returncode}), try {attempt} of 2", flush=True)
        time.sleep(5)
    if proc.returncode != 0:
        raise RuntimeError(f"Stable Fast 3D failed for {slug} (exit code {proc.returncode}). "
                           "Close Roblox Studio, games and browsers (they share the graphics card) and run it again.")
    mesh = job / "out" / "0" / "mesh.glb"
    if not mesh.exists():
        raise FileNotFoundError(mesh)
    MODELS.mkdir(parents=True, exist_ok=True)
    final = MODELS / JOBS[slug]
    shutil.copy2(mesh, final)
    # then its colors straight from the front and back pictures (paint_toon.py):
    # the back is no longer guessed, the washed-out colors come back
    raw = final.with_name(final.stem + "-raw.glb")
    if raw.exists():
        raw.unlink()  # a fresh model: paint from it, not from an older one
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import paint_toon

    paint_toon.paint(slug)
    return {"slug": slug, "glb": str(final), "triangles": triangles(final),
            "seconds": round(time.time() - started)}


def main():
    for need in (SF3D, PYTHON):
        if not need.exists():
            sys.exit(f"Missing: {need}")
    slugs = sys.argv[1:] or list(JOBS)
    unknown = [s for s in slugs if s not in JOBS]
    if unknown:
        sys.exit(f"Unknown: {unknown}. Choose from: {', '.join(JOBS)}")
    results, failed = [], []
    for i, slug in enumerate(slugs, 1):
        print(f"=== {i}/{len(slugs)} {slug} ===", flush=True)
        try:
            r = make(slug)
            results.append(r)
            print(json.dumps(r), flush=True)
        except Exception as e:  # one bad picture does not stop the rest
            failed.append(slug)
            print(f"FAILED {slug}: {e}", flush=True)
    print(f"DONE: {len(results)} made, {len(failed)} failed {failed}", flush=True)
    (WORK / "summary.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
