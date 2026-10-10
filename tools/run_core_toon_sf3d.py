import json
import os
import shutil
import struct
import sys
import types
from collections import deque
from contextlib import nullcontext
from pathlib import Path

import numpy as np
import torch
import trimesh
from PIL import Image, ImageFilter

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

# The installed rembg import hangs in this runtime. SF3D imports rembg through
# sf3d.utils at module import time, but this runner prepares RGBA inputs itself,
# so a no-op shim keeps the SF3D package importable without using rembg.
sys.modules.setdefault(
    "rembg",
    types.SimpleNamespace(
        remove=lambda image, session=None, **kwargs: image,
        new_session=lambda *args, **kwargs: None,
    ),
)
sys.path.insert(0, str(SF3D))

from sf3d.system import SF3D as StableFast3D
from sf3d.utils import resize_foreground


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
                size = value.size
                if isinstance(size, int):
                    size = [size]
                else:
                    size = list(size)
                textures.append({"name": key, "size": size})
    return {
        "geometries": len(geoms),
        "vertices": sum(len(g.vertices) for g in geoms),
        "triangles": sum(len(g.faces) for g in geoms),
        "materials": materials,
        "texture_count": len(textures),
        "textures": textures,
    }


def prepared_image(source: Path, ratio: float = 0.85) -> Image.Image:
    image = Image.open(source).convert("RGB")
    arr = np.asarray(image).astype(np.int16)
    height, width, _ = arr.shape
    edge = np.concatenate(
        [arr[0, :, :], arr[-1, :, :], arr[:, 0, :], arr[:, -1, :]],
        axis=0,
    )
    bg = np.median(edge, axis=0)
    near_bg = np.linalg.norm(arr - bg, axis=2) < 26

    visited = np.zeros((height, width), dtype=bool)
    queue = deque()
    for x in range(width):
        queue.append((0, x))
        queue.append((height - 1, x))
    for y in range(height):
        queue.append((y, 0))
        queue.append((y, width - 1))

    while queue:
        y, x = queue.popleft()
        if y < 0 or y >= height or x < 0 or x >= width:
            continue
        if visited[y, x] or not near_bg[y, x]:
            continue
        visited[y, x] = True
        queue.append((y - 1, x))
        queue.append((y + 1, x))
        queue.append((y, x - 1))
        queue.append((y, x + 1))

    alpha = np.where(visited, 0, 255).astype(np.uint8)
    alpha_image = Image.fromarray(alpha, mode="L").filter(ImageFilter.MinFilter(3))
    rgba = image.convert("RGBA")
    rgba.putalpha(alpha_image)
    return resize_foreground(rgba, ratio)


def load_model():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Device used: {device}", flush=True)
    model = StableFast3D.from_pretrained(
        "stabilityai/stable-fast-3d",
        config_name="config.yaml",
        weight_name="model.safetensors",
    )
    model.to(device)
    model.eval()
    return model, device


def run_job(model, device: str, slug: str, filename: str, vertex_count: int) -> dict:
    source_front = MODEL_INPUT / slug / "front-toon.png"
    source_back = MODEL_INPUT / slug / "back-toon.png"
    if not source_front.exists():
        raise FileNotFoundError(source_front)
    if not source_back.exists():
        raise FileNotFoundError(source_back)

    out_dir = OUTPUT_ROOT / slug
    raw_glb = out_dir / "0" / "mesh.glb"
    final_glb = MODELS / filename

    if final_glb.exists():
        stats = inspect_glb(final_glb)
        return {
            "slug": slug,
            "front_reference": str(source_front),
            "back_reference": str(source_back),
            "raw_glb": str(raw_glb),
            "final_glb": str(final_glb),
            "target_vertex_count": vertex_count,
            "skipped_existing": True,
            **stats,
        }

    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    MODELS.mkdir(parents=True, exist_ok=True)

    image = prepared_image(source_front)
    input_copy = out_dir / "0" / "input.png"
    input_copy.parent.mkdir(parents=True, exist_ok=True)
    image.save(input_copy)

    with torch.no_grad():
        with torch.autocast(device_type=device, dtype=torch.bfloat16) if device == "cuda" else nullcontext():
            mesh, _ = model.run_image(
                [image],
                bake_resolution=2048,
                remesh="triangle",
                vertex_count=vertex_count,
            )
    if isinstance(mesh, list):
        mesh = mesh[0]
    mesh.export(raw_glb, include_normals=True)
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

    os.environ["HF_HUB_OFFLINE"] = "1"
    os.environ["TRANSFORMERS_OFFLINE"] = "1"
    model, device = load_model()

    results = []
    for index, job in enumerate(JOBS, start=1):
        print(f"=== {index}/{len(JOBS)} {job[0]} ===", flush=True)
        result = run_job(model, device, *job)
        results.append(result)
        print(json.dumps(result, indent=2), flush=True)

    summary = OUTPUT_ROOT / "summary.json"
    summary.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"SUMMARY {summary}", flush=True)


if __name__ == "__main__":
    main()
