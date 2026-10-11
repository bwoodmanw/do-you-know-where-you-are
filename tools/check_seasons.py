"""check_seasons.py - tests roblox/src/shared/Seasons.luau with the real
Luau (.tools/luau.exe): the yearly dates in US Eastern time (daylight saving
both ways), which shop is open when, and the Config.SEASONS entries.
Builds a copy of Seasons.luau with Config.SEASONS pasted in (Config.luau
itself needs Roblox), runs the checks, prints OK or what failed.
  python tools/check_seasons.py
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SHARED = ROOT / "roblox" / "src" / "shared"
LUAU = ROOT / ".tools" / "luau.exe"

seasons = (SHARED / "Seasons.luau").read_text(encoding="utf-8")
config = (SHARED / "Config.luau").read_text(encoding="utf-8")
m = re.search(r"^Config\.SEASONS = \{.*?^\}", config, re.S | re.M)
assert m, "Config.SEASONS not found"
anchor = "local Config = require(script.Parent.Config)"
assert seasons.count(anchor) == 1
body = seasons.replace(anchor, "local Config = {}\n" + m.group(0))
body = body.replace("\nreturn Seasons", "\nlocal _S = Seasons")

TESTS = r'''
local S = _S
local fails = 0
local function eq(what, got, want)
	if got ~= want then
		fails += 1
		print("FAIL " .. what .. ": got " .. tostring(got) .. ", want " .. tostring(want))
	end
end
-- known UTC times (checked against the old fixed Config.EVENT numbers)
eq("Halloween 2026 ends (Nov 1 midnight EDT)", S.easternMidnight(2026, 11, 1), 1793505600)
eq("Candy Shop 2026 closes (Nov 8 midnight EST)", S.easternMidnight(2026, 11, 8), 1794114000)
-- daylight saving: Mar 8 2026 (2nd Sunday) midnight is still EST; Mar 9 EDT
eq("2026-03-08 00:00 EST", S.easternMidnight(2026, 3, 8), 1772946000)
eq("2026-03-09 00:00 EDT", S.easternMidnight(2026, 3, 9), 1773028800)
eq("2027-11-01 00:00 EDT (Nov 7 is the change)", S.easternMidnight(2027, 11, 1), 1825041600)
eq("2027-11-08 00:00 EST", S.easternMidnight(2027, 11, 8), 1825650000)
eq("2027-01-04 00:00 EST", S.easternMidnight(2027, 1, 4), 1799038800)
-- the date back from a time
local y, mo, d = S.easternDate(1793505600)
eq("date at Nov 1 midnight", y * 10000 + mo * 100 + d, 20261101)
y, mo, d = S.easternDate(1793505600 - 1)
eq("one second before", y * 10000 + mo * 100 + d, 20261031)
y, mo, d = S.easternDate(1794114000 + 3600 * 23)
eq("Nov 8, 11 PM EST", y * 10000 + mo * 100 + d, 20261108)
eq("until text", S.untilText(1794114000), "Nov 7")
-- which season / shops when
local function at(yy, mm, dd, hh)
	return S.easternMidnight(yy, mm, dd) + (hh or 0) * 3600
end
local function act(t)
	local s = S.active(t)
	return s and s.id or "none"
end
local function shops(t)
	local out = {}
	for _, w in ipairs(S.shops(t)) do
		table.insert(out, w.season.id)
	end
	return table.concat(out, ",")
end
eq("Sep 30 2026", act(at(2026, 9, 30, 12)), "none")
eq("Oct 1 2026", act(at(2026, 10, 1)), "halloween")
eq("Oct 31 11 PM", act(at(2026, 10, 31, 23)), "halloween")
eq("Nov 1 midnight", act(at(2026, 11, 1)), "thanksgiving")
eq("Nov 1 shops", shops(at(2026, 11, 1, 1)), "thanksgiving,halloween")
eq("Nov 8 shops", shops(at(2026, 11, 8, 1)), "thanksgiving")
eq("Nov 30 11 PM", act(at(2026, 11, 30, 23)), "thanksgiving")
eq("Dec 1", act(at(2026, 12, 1, 1)), "none")
eq("Dec 1 shops", shops(at(2026, 12, 1, 1)), "thanksgiving")
eq("Dec 8 shops", shops(at(2026, 12, 8, 1)), "")
eq("Oct 15 2027", act(at(2027, 10, 15)), "halloween")
eq("Nov 20 2031", act(at(2031, 11, 20)), "thanksgiving")
-- a season over New Year (as Christmas will be)
local xmas = { id = "x", item = "x", from = { 12, 1 }, to = { 1, 4 }, shopDays = 7 }
local a, b, c = S.window(xmas, 2026)
eq("Christmas starts", a, S.easternMidnight(2026, 12, 1))
eq("Christmas ends next year", b, S.easternMidnight(2027, 1, 4))
eq("Christmas shop", c, S.easternMidnight(2027, 1, 11))
-- spending money
eq("have", S.have({ feather = 10, featherGift = 5, featherBought = 50, featherSpent = 20 }, S.get("thanksgiving")), 45)
eq("skin price", select(1, S.skinPrice({ corn = 100 })), 100)
eq("skin price season", select(2, S.skinPrice({ feather = 150 })).id, "thanksgiving")
eq("pass skin", S.skinPrice({ pass = 1 }), nil)
-- every season is complete
for _, s in ipairs(Config.SEASONS) do
	for _, k in ipairs({ "id", "name", "shopName", "item", "one", "many", "from", "to", "perFloor", "points", "goal", "near", "badge", "shop" }) do
		eq(s.id .. "." .. k .. " set", s[k] ~= nil, true)
	end
end
print(fails == 0 and "OK: seasons" or (fails .. " failed"))
'''
with tempfile.TemporaryDirectory() as d:
    f = Path(d) / "seasons_test.luau"
    f.write_text(body + "\n" + TESTS, encoding="utf-8")
    r = subprocess.run([str(LUAU), str(f)], capture_output=True, text=True)
    print(r.stdout.strip() or r.stderr.strip())
    sys.exit(0 if "OK: seasons" in r.stdout else 1)
