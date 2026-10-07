"""Count the locals at the top level of a Luau script (Studio stops at 200).

Usage: python tools/count_locals.py <file.luau>
Runs .tools/luau-ast.exe and counts the names declared directly in the
script's outermost block (locals inside do ... end blocks are not counted:
they are freed when the block ends).
"""
import json
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
src = sys.argv[1]
out = subprocess.run([str(root / ".tools" / "luau-ast.exe"), src], capture_output=True, text=True, encoding="utf-8")
ast = json.loads(out.stdout)
n = 0
for stat in ast["root"]["body"]:
    if stat["type"] == "AstStatLocal":
        n += len(stat["vars"])
    elif stat["type"] == "AstStatLocalFunction":
        n += 1
print(f"{src}: {n} top-level locals (limit 200)")
