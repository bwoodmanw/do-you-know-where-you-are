--[[ check_ladder_repeats.luau - finds wasted ladder choices for each character:
	an on/off perk offered at two levels, or a "biggest value wins" perk whose
	option is no bigger than one already offered at an earlier level.
	Run: .tools/luau.exe tools/check_ladder_repeats.luau ]]
local Progress = require("../roblox/src/shared/Progress")
local skills = { "tinker", "shadow", "brainy", "muscle", "glow", "patch", "echo", "bramble" }
local FLAGS = { shield = true, revealOne = true, trickSight = true, twoStep = true, keyMap = true, longRead = true, healShield = true, mastermind = true, freeAll = true }
local MAXES = { glowRange = true, healAmount = true, echoRange = true, sneakTime = true, barricadeHold = true, burstMult = true, burstTime = true, flareTime = true, vineTime = true, cloneTime = true, flareRange = true, flareStamina = true }
local total = 0
for _, sk in ipairs(skills) do
	local flagAt, best = {}, {}
	for lv = 2, Progress.MAX_LEVEL do
		for _, o in ipairs(Progress.choices(sk, lv) or {}) do
			local maxKeys, better, other = 0, false, false
			for k, v in pairs(o.mods) do
				if FLAGS[k] then
					if flagAt[k] then
						print(string.format("%-8s L%-2d %-16s repeats %s from L%d", sk, lv, o.id, k, flagAt[k]))
						total += 1
					else
						flagAt[k] = lv
					end
				elseif MAXES[k] then
					maxKeys += 1
					if not best[k] or v > best[k].v then
						better = true
					end
				else
					other = true
				end
			end
			if maxKeys > 0 and not better and not other then
				print(string.format("%-8s L%-2d %-16s no number beats an earlier level", sk, lv, o.id))
				total += 1
			end
			for k, v in pairs(o.mods) do
				if MAXES[k] and (not best[k] or v > best[k].v) then
					best[k] = { v = v, lv = lv }
				end
			end
		end
	end
end
print(total == 0 and "NO REPEATS" or (total .. " wasted choices"))
