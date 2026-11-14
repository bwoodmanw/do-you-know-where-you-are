import hashlib,json,pathlib,shutil,struct,sys
root=pathlib.Path(__file__).resolve().parents[1]
p=root/'tools/workflows/christmas-skins-muscle-shadow-revisions.json'
w=json.loads(p.read_text());a=w['assets'][int(sys.argv[1])-1]
dest=root/w['output_root']/a['file_name'].replace('\\','/')
assert not dest.exists(),dest
if 'depends_on' in a:assert w['assets'][a['depends_on']-1]['status']=='completed'
source=pathlib.Path(sys.argv[2])
assert source.read_bytes()[:8]==b'\x89PNG\r\n\x1a\n',source
dest.parent.mkdir(parents=True,exist_ok=True)
shutil.copy2(source,dest)
b=dest.read_bytes();assert b[:8]==b'\x89PNG\r\n\x1a\n'
refs=[root/w['reference_root']/r.replace('\\','/') for r in a['references']]
a.update(status='completed',generated_source=str(source),saved_path=str(dest),dimensions=list(struct.unpack('>II',b[16:24])),sha256=hashlib.sha256(b).hexdigest(),validation=sys.argv[3],attached_reference_paths=list(map(str,refs)),reference_sha256=[hashlib.sha256(r.read_bytes()).hexdigest() for r in refs])
p.write_text(json.dumps(w,indent=2)+'\n');print(dest)
