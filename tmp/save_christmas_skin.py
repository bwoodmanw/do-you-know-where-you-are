import hashlib
import json
import pathlib
import shutil
import struct
import sys

root = pathlib.Path(__file__).resolve().parents[1]
workflow_path = root / 'tools/workflows/christmas-skins-a-pictures.json'
workflow = json.loads(workflow_path.read_text(encoding='utf-8'))
asset = workflow['assets'][int(sys.argv[1]) - 1]
source = pathlib.Path(sys.argv[2])
destination = root / workflow['output_root'] / asset['file_name'].replace('\\', '/')
assert not destination.exists(), destination
if 'depends_on' in asset:
    assert workflow['assets'][asset['depends_on'] - 1]['status'] == 'completed'
shutil.copy2(source, destination)
data = destination.read_bytes()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
asset.update(status='completed', generated_source=str(source), saved_path=str(destination),
             dimensions=list(struct.unpack('>II', data[16:24])),
             sha256=hashlib.sha256(data).hexdigest(), validation=sys.argv[3])
workflow_path.write_text(json.dumps(workflow, indent=2) + '\n', encoding='utf-8')
print(str(destination))
