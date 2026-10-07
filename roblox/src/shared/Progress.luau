--[[
	Progress - the rules of progression, shared by the Lobby and the game:
	maps and how they unlock, shop boosts, character levels, and the skill
	ladder (pick 1 of 2 upgrades at levels 2-5). Edit numbers here.
]]

local Progress = {}

-- Buildings are stacks of floors; one game is one floor. Escaping a floor
-- (any difficulty) unlocks the next floor up, and escaping floor 2 also
-- unlocks the next building's first floor.
Progress.MAPS = {
	{ id = "partyhouse", building = "partyhouse", floor = 1, name = "Party House: Ground", icon = "\u{1F383}", ready = true },
	{ id = "partyhouse_2", building = "partyhouse", floor = 2, name = "Party House: Bedrooms", icon = "\u{1F6CF}", ready = true },
	{ id = "partyhouse_3", building = "partyhouse", floor = 3, name = "Party House: Attic", icon = "\u{1F578}", ready = true },
	{ id = "gummy", building = "gummy", floor = 1, name = "Gummy: Bounce Hall", icon = "\u{1F36C}", ready = true },
	{ id = "gummy_2", building = "gummy", floor = 2, name = "Gummy: Candy Factory", icon = "\u{1F36D}", ready = false },
	{ id = "gummy_3", building = "gummy", floor = 3, name = "Gummy: Jelly Vault", icon = "\u{1F36F}", ready = false },
	{ id = "hospital", building = "hospital", floor = 1, name = "Abandoned Hospital", icon = "\u{1F3E5}", ready = false },
}

Progress.BUILDINGS = {
	{ id = "partyhouse", name = "The Party House" },
	{ id = "gummy", name = "Gummy Bounce House" },
	{ id = "hospital", name = "Abandoned Hospital" },
}

-- what escaping this floor unlocks
function Progress.unlocksAfter(id)
	local out = {}
	local i = Progress.mapIndex(id)
	local m = i and Progress.MAPS[i]
	if not m then
		return out
	end
	for _, n in ipairs(Progress.MAPS) do
		if n.building == m.building and n.floor == m.floor + 1 then
			table.insert(out, n)
		end
	end
	if m.floor == 2 then
		local seen = false
		for _, n in ipairs(Progress.MAPS) do
			if n.building == m.building then
				seen = true
			elseif seen and n.floor == 1 then
				table.insert(out, n)
				break
			end
		end
	end
	return out
end

function Progress.mapIndex(id)
	for i, m in ipairs(Progress.MAPS) do
		if m.id == id then
			return i
		end
	end
	return nil
end

-- Boosts: bought in the Lobby shop, up to MAX_BOOSTS taken into a game.
-- robux = the price shown if a Developer Product exists for it (Config.ROBUX_PRODUCTS).
Progress.MAX_BOOSTS = 2
Progress.BOOST_ORDER = { "candy", "shield", "clue", "energy", "headstart", "freeze" }
Progress.BOOSTS = {
	candy = { name = "Candy Corn", icon = "\u{1F36C}", say = "Tap in the game: run without tiring for 20 s", tap = true, price = 60 },
	shield = { name = "Party Shield", icon = "\u{1F6E1}", say = "Automatic: saves you from one grab", price = 120 },
	clue = { name = "Extra Clue", icon = "\u{1F4A1}", say = "Tap in the game: +1 clue for the team", tap = true, price = 80 },
	energy = { name = "Second Wind", icon = "\u{1F4A8}", say = "Tap in the game: all your stamina back", tap = true, price = 50 },
	freeze = { name = "Frozen Pop", icon = "\u{1F9CA}", say = "Tap in the game: freezes the host for 10 s", tap = true, price = 150 },
	headstart = { name = "Head Start", icon = "\u{23F1}", say = "Automatic: the host waits 10 s longer", price = 100 },
}

-- Character levels: XP comes from points earned while playing that character.
Progress.LEVEL_XP = { 0, 300, 800, 1600, 3000 } -- XP needed for levels 1..5

function Progress.level(xp)
	local lvl = 1
	for i, need in ipairs(Progress.LEVEL_XP) do
		if (xp or 0) >= need then
			lvl = i
		end
	end
	return lvl
end

--[[
	The skill ladder. Each level from 2 to 5 offers two upgrades; the player
	picks one. An upgrade is a set of mods the game understands:
	  staminaMult  runMult  energyStart  sightMult (how far the host sees you)
	  holdMult (pick/shove/read/light/ask/free hold times)  clues  revealOne
	  shield (start each game with a shield)  cooldownMult  sneakTime
	  glowRange  healAmount  healShield  echoRange  freeAll
]]
local GENERIC = {
	[2] = {
		{ id = "lungs", name = "Big Lungs", say = "20% more stamina", mods = { staminaMult = 1.2 } },
		{ id = "nimble", name = "Nimble Hands", say = "Hold things 15% faster", mods = { holdMult = 0.85 } },
	},
	[4] = {
		{ id = "quick", name = "Quick Feet", say = "Run 10% faster", mods = { runMult = 1.1 } },
		{ id = "quiet", name = "Quiet Steps", say = "The host sees you from 20% less far", mods = { sightMult = 0.8 } },
	},
}
local SPECIAL = {
	tinker = {
		[3] = {
			{ id = "fingers", name = "Quick Fingers", say = "Pick locked doors 40% faster", mods = { holdMult = 0.6 } },
			{ id = "lucky", name = "Lucky Guess", say = "Your team starts knowing one colour of the code", mods = { revealOne = true } },
		},
		[5] = {
			{ id = "master", name = "Master Hands", say = "Everything you hold (pick, shove, free) is twice as fast", mods = { holdMult = 0.5 } },
			{ id = "gadget", name = "Gadget Shield", say = "Start every game with a Party Shield", mods = { shield = true } },
		},
	},
	shadow = {
		[3] = {
			{ id = "long", name = "Long Sneak", say = "Sneak lasts 10 seconds", mods = { sneakTime = 10 } },
			{ id = "recharge", name = "Fast Recharge", say = "Sneak recharges 40% faster", mods = { cooldownMult = 0.6 } },
		},
		[5] = {
			{ id = "ghost", name = "Ghost", say = "Sneak lasts 14 seconds", mods = { sneakTime = 14 } },
			{ id = "blur", name = "Blur", say = "Run 15% faster", mods = { runMult = 1.15 } },
		},
	},
	brainy = {
		[3] = {
			{ id = "hints", name = "Bonus Hints", say = "+2 clues for the team", mods = { clues = 2 } },
			{ id = "sense", name = "Code Sense", say = "Your team starts knowing one colour of the code", mods = { revealOne = true } },
		},
		[5] = {
			{ id = "genius", name = "Genius", say = "+3 clues for the team", mods = { clues = 3 } },
			{ id = "speedread", name = "Speed Reader", say = "Read and use things twice as fast", mods = { holdMult = 0.5 } },
		},
	},
	muscle = {
		[3] = {
			{ id = "heave", name = "Big Heave", say = "Shove 50% faster", mods = { holdMult = 0.5 } },
			{ id = "tough", name = "Tough", say = "Start every game with a Party Shield", mods = { shield = true } },
		},
		[5] = {
			{ id = "sprinter", name = "Sprinter", say = "Run 15% faster", mods = { runMult = 1.15 } },
			{ id = "stamina", name = "Iron Lungs", say = "50% more stamina", mods = { staminaMult = 1.5 } },
		},
	},
	glow = {
		[3] = {
			{ id = "bright", name = "Brighter Bulb", say = "Your light reaches much further", mods = { glowRange = 36 } },
			{ id = "secrets", name = "Secret Seeker", say = "Your team starts knowing one colour of the code", mods = { revealOne = true } },
		},
		[5] = {
			{ id = "sun", name = "Little Sun", say = "Your light fills a whole room", mods = { glowRange = 50 } },
			{ id = "dazzle", name = "Dazzle", say = "The host sees you from 30% less far", mods = { sightMult = 0.7 } },
		},
	},
	patch = {
		[3] = {
			{ id = "bigheal", name = "Shields for All", say = "Shield every friend nearby, not just one", mods = { healShield = true } },
			{ id = "quickheal", name = "Quick Shield", say = "Shield recharges 40% faster", mods = { cooldownMult = 0.6 } },
		},
		[5] = {
			{ id = "guardian", name = "Guardian", say = "Shield recharges twice as fast", mods = { cooldownMult = 0.5 } },
			{ id = "medic", name = "Field Medic", say = "Free friends from the cage twice as fast", mods = { holdMult = 0.5 } },
		},
	},
	echo = {
		[3] = {
			{ id = "throw", name = "Strong Throw", say = "Throw a noise much further", mods = { echoRange = 110 } },
			{ id = "echoquick", name = "Quick Echo", say = "Noise recharges 40% faster", mods = { cooldownMult = 0.6 } },
		},
		[5] = {
			{ id = "radar", name = "Radar Ears", say = "The host sees you from 30% less far", mods = { sightMult = 0.7 } },
			{ id = "echofast", name = "Echo Storm", say = "Noise recharges twice as fast", mods = { cooldownMult = 0.5 } },
		},
	},
	bramble = {
		[3] = {
			{ id = "whisper", name = "Plant Whisperer", say = "Ask the plant twice as fast", mods = { holdMult = 0.5 } },
			{ id = "roots", name = "Deep Roots", say = "20% more stamina", mods = { staminaMult = 1.2 } },
		},
		[5] = {
			{ id = "camo", name = "Leaf Camouflage", say = "The host sees you from 35% less far", mods = { sightMult = 0.65 } },
			{ id = "bloom", name = "Bloom", say = "Your team starts knowing one colour of the code", mods = { revealOne = true } },
		},
	},
}

-- the two choices for a character at a level (nil for level 1)
function Progress.choices(skill, level)
	if GENERIC[level] then
		return GENERIC[level]
	end
	local s = SPECIAL[skill]
	return s and s[level] or nil
end

-- the combined mods for a character from the upgrades picked so far
function Progress.mods(skill, picks, xp)
	local m = { staminaMult = 1, runMult = 1, sightMult = 1, holdMult = 1, cooldownMult = 1, energyStart = 0, clues = 0 }
	local lvl = Progress.level(xp)
	for level = 2, lvl do
		local choice = picks and picks[tostring(level)]
		local options = Progress.choices(skill, level)
		if options and choice then
			for _, opt in ipairs(options) do
				if opt.id == choice then
					for k, v in pairs(opt.mods) do
						if k == "staminaMult" or k == "runMult" or k == "sightMult" or k == "holdMult" or k == "cooldownMult" then
							m[k] *= v
						elseif k == "energyStart" or k == "clues" then
							m[k] += v
						elseif k == "glowRange" or k == "healAmount" or k == "echoRange" or k == "sneakTime" then
							m[k] = math.max(m[k] or 0, v)
						else
							m[k] = v
						end
					end
				end
			end
		end
	end
	return m
end

return Progress
