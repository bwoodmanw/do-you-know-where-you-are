"""Record targeted fixes and verify the ten saved images and their dependencies."""
import hashlib
import json
import os
import re
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / 'tools/workflows/christmas-skins-b-pictures.json'
workflow = json.loads(path.read_text(encoding='utf-8'))
clarifications = {
    8: "Rear-view construction clarification: the goggles remain on his FRONT forehead as shown in the attached front. From directly behind, show only the simple smooth gold goggle strap around the sides/back of his curly hair. NO lenses, NO round goggle eyepieces and NO face visible on the back of his head. Rear jacket blue on picture LEFT and red on picture RIGHT. Keep the gold wrist gadget on picture LEFT in this rear view.",
    10: "Rear-view construction clarification: her long straight black hair falls naturally down her back OVER the rear of the collar and scarf, ending at the same length as the front reference. The scarf encircles her neck underneath the hair; do not place a red scarf or a white front-style split collar on top of the middle of her hanging hair. Small scarf/collar edges may show at the sides of the neck under her hair. Show one continuous plain coat back, no front buttons or front pockets on the back. Preserve the exact beret tilt with sides reversed for a rear view, and put the gold clips on picture left.",
}
discarded = {
    8: ('exec-8c2d4ca2-a8ef-4b72-b099-8a3167d4e9bb.png', 'Goggle lenses incorrectly appeared on the back of his head.'),
    10: ('exec-cb91bcae-30f4-4a07-951c-a0e5b058f7dc.png', 'Scarf and split front-style collar incorrectly overlaid the hanging rear hair.'),
}
for order, clarification in clarifications.items():
    asset = workflow['assets'][order - 1]
    if not asset['prompt'].endswith(clarification):
        asset['prompt'] += '\n\n' + clarification
    filename, reason = discarded[order]
    source = Path(r'C:\Users\bwood\.codex\generated_images\01a1ad49-0658-7483-b66e-214ca3c73292') / filename
    record = {'generated_source': str(source), 'sha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'reason': reason}
    if record not in asset.setdefault('discarded_attempts', []):
        asset['discarded_attempts'].append(record)

request = Path(r'C:\Users\bwood\.codex\attachments\62ab38f8-8eff-4f2c-a92c-05cd480fe662\Pasted text.txt').read_text(encoding='utf-8')
standard = re.search(r'\[Picture Standard\] = "(.*?)"', request).group(1)
rows = re.findall(r'^\[(FRONT view.*?|BACK view.*?)\] \| \[(.*?)\] \| \[(.*?)\]$', request, re.M)
assert standard == workflow['picture_standard']
assert len(rows) == len(workflow['assets']) == 10
for order, (asset, row) in enumerate(zip(workflow['assets'], rows), 1):
    assert asset['order'] == order and asset['status'] == 'completed'
    assert (asset['picture'], asset['references'][0], asset['file_name']) == row
    assert standard + '\n\n' + asset['picture'] in asset['prompt']
    destination = root / workflow['output_root'] / asset['file_name']
    data = destination.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    assert list(struct.unpack('>II', data[16:24])) == asset['dimensions'] == [1024, 1536]
    assert hashlib.sha256(data).hexdigest() == asset['sha256']
    assert Path(asset['saved_path']) == destination
    reference = root / workflow['reference_root'] / asset['references'][0]
    assert reference.is_file()
    assert asset['attached_reference_paths'] == [str(reference)]
    if order % 2 == 0:
        front = workflow['assets'][order - 2]
        assert asset['depends_on'] == front['order']
        assert reference == Path(front['saved_path'])
        assert hashlib.sha256(reference.read_bytes()).hexdigest() == asset['reference_front_sha256'] == front['sha256']
workflow['status'] = 'completed'
workflow['completed'] = '2026-11-05'
workflow['verification'] = {
    'images': 10, 'front_back_dependencies': 5, 'dimensions': [1024, 1536],
    'request_rows_and_standard_match': True, 'file_hashes_verified': True,
    'notes': 'Soft 3D form lighting and slight background tonal variation remain visible; surfaces are smooth, without fabric grain or glitter. Clone buttons and rear goggle construction corrected; Harmony rear hair layering corrected.'
}
temporary = path.with_suffix('.tmp')
temporary.write_text(json.dumps(workflow, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
os.replace(temporary, path)
print('Verified all 10 PNGs (1024 x 1536), hashes, exact request rows/standard and all 5 saved-front dependencies.')
