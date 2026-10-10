import json
import os
import shutil
import struct
import subprocess
from pathlib import Path

import trimesh

PROJECT = Path(r"C:\Users\bwood\OneDrive\Documents\Kids Games\Do You Know Where You Are")
OLD_ROOT = Path(r"C:\Users\bwood\Documents\Codex\2026-10-05\referenced-chatgpt-conversation-this-is-an")
SF3D = OLD_ROOT / "work" / "stable-fast-3d"
PYTHON = OLD_ROOT / "work" / "sf3d-venv" / "Scripts" / "python.exe"

MODEL_INPUT = PROJECT / "art" / "model-input"
OUTPUT_ROOT = PROJECT / "art" / "sf3d-core-toon"
MODELS = PROJECT / "art" / "models"

JOBS = [
    ("brainy", "brainy-toon.glb", 5000),
    ("shadow", "shadow-toon.glb", 5000),
    ("muscle", "muscle-toon.glb", 5000),
    ("glow", "glow-toon.glb", 5000),
    ("patch", "patch-toon.glb", 5000),
    ("echo", "echo-toon.glb", 5000),
    ("bramble", "bramble-toon.glb", 5000),
]


def _align4(data: bytes, pad: bytes) -> bytes:
    return data + pad * ((4 - (len(data) % 4)) % 4)


def make_unlit_glb(src: Path, dst: Path) -> None:
    data = src.read_bytes()
    if data[:4] != b"glTF":
        raise ValueError(f"{src} is not a GLB")

    version, total_len = struct.unpack_from("<II", data, 4)
    if version != 2:
        raise ValueError(f"{src} is GLB version {version}, expected 2")
    if total_len != len(data):
        raise ValueError(f"{src} has invalid GLB length")

    pos = 12
    chunks = []
    while pos < len(data):
        chunk_len, chunk_type = struct.unpack_from("<II", data, pos)
        pos += 8
        chunk = data[pos : pos + chunk_len]
        pos += chunk_len
        chunks.append((chunk_type, chunk))

    if not chunks or chunks[0][0] != 0x4E4F534A:
        raise ValueError(f"{src} has no JSON chunk")

    gltf = json.loads(chunks[0][1].rstrip(b" \t\r\n\0").decode("utf-8"))
    extensions_used = set(gltf.get("extensionsUsed", []))
    extensions_used.add("KHR_materials_unlit")
    gltf["extensionsUsed"] = sorted(extensions_used)

    for material in gltf.get("materials", []):
        material.pop("normalTexture", None)
        material.pop("occlusionTexture", None)
        material.pop("emissiveTexture", None)
        material["emissiveFactor"] = [0, 0, 0]
        pbr = material.setdefault("pbrMetallicRoughness", {})
        pbr["metallicFactor"] = 0
        pbr["roughnessFactor"] = 1
        material.setdefault("extensions", {})["KHR_materials_unlit"] = {}

    json_chunk = _align4(
        json.dumps(gltf, separators=(",", ":")).encode("utf-8"),
        b" ",
    )

    out_chunks = [(0x4E4F534A, json_chunk)]
    out_chunks.extend(chunks[1:])
    out_len = 12 + sum(8 + len(chunk) for _, chunk in out_chunks)

    out = bytearray()
    out += b"glTF"
    out += struct.pack("<II", 2, out_len)
    for chunk_type, chunk in out_chunks:
        out += struct.pack("<II", len(chunk), chunk_type)
        out += chunk

    dst.write_bytes(out)


def inspect_glb(path: Path) -> dict:
    scene = trimesh.load(path, force="scene")
    geoms = list(scene.geometry.values())
    textures = []
    materials = []
    for geom in geoms:
        material = getattr(getattr(geom, "visual", None), "material", None)
        if material is None:
            continue
        materials.append(type(material).__name__)
        for key, value in getattr(material, "_data", {}).items():
            if hasattr(value, "size"):
                textures.append({"name": key, "size": list(value.size)})
    return {
        "geometries": len(geoms),
        "vertices": sum(len(g.vertices) for g in geoms),
        "triangles": sum(len(g.faces) for g in geoms),
        "materials": materials,
        "texture_count": len(textures),
        "textures": textures,
    }


def run_job(slug: str, filename: str, vertex_count: int) -> dict:
    source_front = MODEL_INPUT / slug / "front-toon.png"
    source_back = MODEL_INPUT / slug / "back-toon.png"
    if not source_front.exists():
        raise FileNotFoundError(source_front)
    if not source_back.exists():
        raise FileNotFoundError(source_back)

    out_dir = OUTPUT_ROOT / slug
    raw_glb = out_dir / "0" / "mesh.glb"
    final_glb = MODELS / filename

    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    MODELS.mkdir(parents=True, exist_ok=True)

    env = os.environ.copy()
    env["HF_HUB_OFFLINE"] = "1"
    env["TRANSFORMERS_OFFLINE"] = "1"

    cmd = [
        str(PYTHON),
        "run.py",
        str(source_front),
        "--output-dir",
        str(out_dir),
        "--texture-resolution",
        "2048",
        "--remesh_option",
        "triangle",
        "--target_vertex_count",
        str(vertex_count),
        "--batch_size",
        "1",
    ]
    subprocess.run(cmd, cwd=SF3D, env=env, check=True)
    if not raw_glb.exists():
        raise FileNotFoundError(raw_glb)

    make_unlit_glb(raw_glb, final_glb)
    stats = inspect_glb(final_glb)
    return {
        "slug": slug,
        "front_reference": str(source_front),
        "back_reference": str(source_back),
        "raw_glb": str(raw_glb),
        "final_glb": str(final_glb),
        "target_vertex_count": vertex_count,
        **stats,
    }


def main() -> None:
    if not SF3D.exists():
        raise FileNotFoundError(SF3D)
    if not PYTHON.exists():
        raise FileNotFoundError(PYTHON)

    results = []
    for index, job in enumerate(JOBS, start=1):
        print(f"=== {index}/{len(JOBS)} {job[0]} ===", flush=True)
        result = run_job(*job)
        results.append(result)
        print(json.dumps(result, indent=2), flush=True)

    summary = OUTPUT_ROOT / "summary.json"
    summary.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"SUMMARY {summary}", flush=True)


if __name__ == "__main__":
    main()
