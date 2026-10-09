--[[ check_ladder_waste.luau - finds ladder picks that end up doing nothing.
	For each character it makes many random level-20 builds; in each build it
	takes every pick away in turn and compares the mods. If nothing changes,
	that pick was wasted in that build (a later pick replaced it, or a cap
	swallowed it). Prints every pick that is ever wasted, and how often,
	split by which level-10 and level-20 power was chosen.
	Run: .tools/luau.exe tools/check_ladder_waste.luau ]]
local Progress = require("../roblox/src/shared/Progress")
local skills = { "tinker", "shadow", "brainy", "muscle", "glow", "patch", "echo", "bramble" }
local N = 3000
local XP = Progress.LEVEL_XP[Progress.MAX_LEVEL]

local function same(a, b)
	for k, v in pairs(a) do
		if b[k] ~= v then
			return false
		end
	end
	for k, v in pairs(b) do
		if a[k] ~= v then
			return false
		end
	end
	return true
end

local total = 0
for _, sk in ipairs(skills) do
	-- wasted[id] = { builds, dead, by10 = {id = {n, dead}}, by20 = {...} }
	local stats, order = {}, {}
	for _ = 1, N do
		local picks = {}
		for lv = 2, Progress.MAX_LEVEL do
			local c = Progress.choices(sk, lv)
			picks[tostring(lv)] = c[math.random(1, 2)].id
		end
		local full = Progress.mods(sk, picks, XP)
		for lv = 2, Progress.MAX_LEVEL do
			local key = tostring(lv)
			local id = picks[key]
			picks[key] = nil
			local dead = same(full, Progress.mods(sk, picks, XP))
			picks[key] = id
			local sid = lv .. ":" .. id
			local s = stats[sid]
			if not s then
				s = { lv = lv, id = id, n = 0, dead = 0, by10 = {}, by20 = {} }
				stats[sid] = s
				table.insert(order, sid)
			end
			s.n += 1
			if dead then
				s.dead += 1
			end
			for _, pair in ipairs({ { s.by10, picks["10"] }, { s.by20, picks["20"] } }) do
				local t = pair[1][pair[2]] or { n = 0, dead = 0 }
				pair[1][pair[2]] = t
				t.n += 1
				if dead then
					t.dead += 1
				end
			end
		end
	end
	table.sort(order, function(a, b)
		local x, y = stats[a], stats[b]
		if x.lv ~= y.lv then
			return x.lv < y.lv
		end
		return x.id < y.id
	end)
	print("== " .. sk)
	for _, sid in ipairs(order) do
		local s = stats[sid]
		if s.dead > 0 then
			total += 1
			local parts = {}
			for _, grp in ipairs({ { "L10", s.by10 }, { "L20", s.by20 } }) do
				for pid, t in pairs(grp[2]) do
					if t.dead > 0 then
						table.insert(parts, string.format("%s %s %d%%", grp[1], pid, math.floor(100 * t.dead / t.n + 0.5)))
					end
				end
			end
			table.sort(parts)
			print(string.format("  L%-2d %-14s wasted in %3d%% of builds  (%s)", s.lv, s.id,
				math.floor(100 * s.dead / s.n + 0.5), table.concat(parts, ", ")))
		end
	end
end
print(total == 0 and "OK: no pick is ever wasted" or (total .. " picks can be wasted"))
