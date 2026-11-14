"""Save one inspected generation and update its workflow provenance."""
import argparse
import hashlib
import json
import shutil
import struct
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("order", type=int)
parser.add_argument("source", type=Path)
parser.add_argument("validation")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
workflow_path = root / "tools/workflows/christmas-skins-b-pictures.json"
workflow = json.loads(workflow_path.read_text(encoding="utf-8"))
asset = workflow["assets"][args.order - 1]
assert asset["order"] == args.order and asset["status"] == "pending"
assert all(a["status"] == "completed" for a in workflow["assets"][:args.order - 1])
references = [root / workflow["reference_root"] / r for r in asset["references"]]
assert all(p.is_file() for p in references)
destination = root / workflow["output_root"] / asset["file_name"]
assert not destination.exists(), destination
data = args.source.read_bytes()
assert data[:8] == b"\x89PNG\r\n\x1a\n"
dimensions = list(struct.unpack(">II", data[16:24]))
destination.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(args.source, destination)
digest = hashlib.sha256(data).hexdigest()
assert hashlib.sha256(destination.read_bytes()).hexdigest() == digest
asset.update(status="completed", generated_source=str(args.source),
             saved_path=str(destination), dimensions=dimensions, sha256=digest,
             attached_reference_paths=[str(p) for p in references],
             validation=args.validation)
if "depends_on" in asset:
    front = workflow["assets"][asset["depends_on"] - 1]
    reference_digest = hashlib.sha256(references[0].read_bytes()).hexdigest()
    assert references[0] == Path(front["saved_path"])
    assert reference_digest == front["sha256"]
    asset["reference_front_sha256"] = reference_digest
workflow_path.write_text(json.dumps(workflow, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(json.dumps({"order": args.order, "saved_path": str(destination), "dimensions": dimensions}))
