--[[ check_ladder.luau - every character has two choices at levels 2..MAX_LEVEL,
	ids are unique per character, and the mods of a full ladder come out sane.
	Run: .tools/luau.exe tools/check_ladder.luau ]]
local Progress = require("../roblox/src/shared/Progress")
local skills = { "tinker", "shadow", "brainy", "muscle", "glow", "patch", "echo", "bramble" }
local bad = 0
print("levels: " .. Progress.MAX_LEVEL .. ", XP for 20: " .. Progress.LEVEL_XP[20])
for _, sk in ipairs(skills) do
	local seen, picks = {}, {}
	for lv = 2, Progress.MAX_LEVEL do
		local c = Progress.choices(sk, lv)
		if not c or #c ~= 2 then
			print("MISSING " .. sk .. " level " .. lv)
			bad += 1
		else
			for _, o in ipairs(c) do
				local key = o.id
				if seen[key] and lv % 2 == 1 then
					print("DUPLICATE id " .. sk .. " " .. key)
					bad += 1
				end
				seen[key] = true
			end
			picks[tostring(lv)] = c[1].id
		end
	end
	local m = Progress.mods(sk, picks, Progress.LEVEL_XP[20])
	print(string.format("%-8s first-choice ladder: run %.2f stamina %.2f hold %.2f sight %.2f cooldown %.2f clues %d p10=%s p20=%s",
		sk, m.runMult, m.staminaMult, m.holdMult, m.sightMult, m.cooldownMult, m.clues, tostring(m.p10), tostring(m.p20)))
end
print(bad == 0 and "LADDER OK" or ("PROBLEMS: " .. bad))
