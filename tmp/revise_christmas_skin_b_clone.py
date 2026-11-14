import hashlib
import json
import os
import shutil
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
workflow_path = root / 'tools/workflows/christmas-skins-b-pictures.json'
workflow = json.loads(workflow_path.read_text(encoding='utf-8'))
asset = workflow['assets'][6]
assert asset['order'] == 7 and asset['status'] == 'completed'
assert workflow['assets'][7]['status'] == 'pending'
destination = Path(asset['saved_path'])
assert hashlib.sha256(destination.read_bytes()).hexdigest() == asset['sha256']
source = Path(r'C:\Users\bwood\.codex\generated_images\01a1ad49-0658-7483-b66e-214ca3c73292\exec-4d6c1d4c-c0b6-4185-90ca-01dc87905369.png')
data = source.read_bytes()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
asset.setdefault('discarded_attempts', []).append({
    'generated_source': asset['generated_source'],
    'sha256': asset['sha256'],
    'reason': 'Two button columns instead of one central vertical row.'
})
clarification = "Button placement clarification: exactly ONE straight vertical column of round gold buttons centered along the jacket's middle opening. No double-breasted layout and no two columns of buttons. Front image left half red, right half royal blue."
asset['prompt'] += '\n\n' + clarification
shutil.copyfile(source, destination)
asset.update(generated_source=str(source), sha256=hashlib.sha256(data).hexdigest(),
             dimensions=list(struct.unpack('>II', data[16:24])),
             validation='Inspected: Clone identity, gold-rimmed goggles, gold wrist gadget with dark screen, red picture-left and royal-blue picture-right jacket, one central column of gold buttons, compact gold shoulder pads, white belt, pocketless black trousers and black boots. Full-body A-pose with arm gaps, no text or logos. Soft form lighting remains visible.')
assert hashlib.sha256(destination.read_bytes()).hexdigest() == asset['sha256']
temporary = workflow_path.with_suffix('.tmp')
temporary.write_text(json.dumps(workflow, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
os.replace(temporary, workflow_path)
print('Saved corrected Clone front and updated provenance.')
