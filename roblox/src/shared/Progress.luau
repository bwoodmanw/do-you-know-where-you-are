--[[
	Progress - the rules of progression, shared by the Lobby and the game:
	maps and how they unlock, shop boosts, character levels, and the skill
	ladder (pick 1 of 2 upgrades at levels 2-10). Edit numbers here.
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
Progress.LEVEL_XP = { 0, 300, 800, 1600, 3000, 4800, 7000, 9600, 12600, 16000 } -- XP needed for levels 1..10

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
	The skill ladder. Each level from 2 to 10 offers two upgrades; the player
	picks one. Even levels (2, 4, 6, 8) are the same for everyone; odd levels
	(3, 5, 7, 9) and level 10 belong to the character's own skill. Bonuses
	are small and add up; Progress.CAPS stops them stacking too far. Ids at
	levels 2-5 are the ones saved before 10 levels: keep them.
	An upgrade is a set of mods the game understands:
	  staminaMult  runMult  energyStart  sightMult (how far the host sees you)
	  holdMult (pick/shove/read/light/ask/free hold times)  clues  revealOne
	  shield (start each game with a shield)  cooldownMult  sneakTime
	  glowRange  healAmount  healShield  echoRange  freeAll
]]
local GENERIC = {
	[2] = {
		{ id = "lungs", name = "Big Lungs", say = "10% more stamina", mods = { staminaMult = 1.1 } },
		{ id = "nimble", name = "Nimble Hands", say = "Hold things 8% faster", mods = { holdMult = 0.92 } },
	},
	[4] = {
		{ id = "quick", name = "Quick Feet", say = "Run 5% faster", mods = { runMult = 1.05 } },
		{ id = "quiet", name = "Quiet Steps", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
	},
	[6] = {
		{ id = "wind", name = "Deep Breath", say = "10% more stamina", mods = { staminaMult = 1.1 } },
		{ id = "steady", name = "Steady Hands", say = "Hold things 8% faster", mods = { holdMult = 0.92 } },
	},
	[8] = {
		{ id = "feet", name = "Fast Feet", say = "Run 5% faster", mods = { runMult = 1.05 } },
		{ id = "soft", name = "Soft Steps", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
	},
}
local SPECIAL = {
	tinker = {
		[3] = {
			{ id = "fingers", name = "Quick Fingers", say = "Pick locked doors 15% faster", mods = { holdMult = 0.85 } },
			{ id = "lucky", name = "Lucky Guess", say = "Your team starts knowing one colour of the code", mods = { revealOne = true } },
		},
		[5] = {
			{ id = "master", name = "Handy", say = "Everything you hold is 15% faster", mods = { holdMult = 0.85 } },
			{ id = "gadget", name = "Gadget Shield", say = "Start every game with a Party Shield", mods = { shield = true } },
		},
		[7] = {
			{ id = "toolbelt", name = "Tool Belt", say = "Everything you hold is 15% faster", mods = { holdMult = 0.85 } },
			{ id = "gizmo", name = "Clue Gizmo", say = "+1 clue for the team", mods = { clues = 1 } },
		},
		[9] = {
			{ id = "expert", name = "Expert Hands", say = "Everything you hold is 20% faster", mods = { holdMult = 0.8 } },
			{ id = "cloak", name = "Gadget Cloak", say = "The host sees you from 15% less far", mods = { sightMult = 0.85 } },
		},
		[10] = {
			{ id = "master10", name = "Master Hands", say = "Everything you hold (pick, shove, free) is twice as fast", mods = { holdMult = 0.5 } },
			{ id = "boots", name = "Rocket Boots", say = "Run 15% faster", mods = { runMult = 1.15 } },
		},
	},
	shadow = {
		[3] = {
			{ id = "long", name = "Long Sneak", say = "Sneak lasts 8 seconds", mods = { sneakTime = 8 } },
			{ id = "recharge", name = "Fast Recharge", say = "Sneak recharges 20% faster", mods = { cooldownMult = 0.8 } },
		},
		[5] = {
			{ id = "ghost", name = "Longer Sneak", say = "Sneak lasts 10 seconds", mods = { sneakTime = 10 } },
			{ id = "blur", name = "Swift", say = "Run 5% faster", mods = { runMult = 1.05 } },
		},
		[7] = {
			{ id = "shade", name = "Shade", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
			{ id = "rest", name = "Quick Rest", say = "Sneak recharges 20% faster", mods = { cooldownMult = 0.8 } },
		},
		[9] = {
			{ id = "phantom", name = "Phantom", say = "Sneak lasts 12 seconds", mods = { sneakTime = 12 } },
			{ id = "dash", name = "Dash", say = "Run 8% faster", mods = { runMult = 1.08 } },
		},
		[10] = {
			{ id = "ghost10", name = "Ghost", say = "Sneak lasts 14 seconds", mods = { sneakTime = 14 } },
			{ id = "blur10", name = "Blur", say = "Run 15% faster", mods = { runMult = 1.15 } },
		},
	},
	brainy = {
		[3] = {
			{ id = "hints", name = "Bonus Hint", say = "+1 clue for the team", mods = { clues = 1 } },
			{ id = "sense", name = "Code Sense", say = "Your team starts knowing one colour of the code", mods = { revealOne = true } },
		},
		[5] = {
			{ id = "genius", name = "Clever", say = "+1 clue for the team", mods = { clues = 1 } },
			{ id = "speedread", name = "Quick Reader", say = "Read and use things 20% faster", mods = { holdMult = 0.8 } },
		},
		[7] = {
			{ id = "notebook", name = "Notebook", say = "+1 clue for the team", mods = { clues = 1 } },
			{ id = "focus", name = "Focus", say = "Read and use things 15% faster", mods = { holdMult = 0.85 } },
		},
		[9] = {
			{ id = "bigbrain", name = "Big Brain", say = "+2 clues for the team", mods = { clues = 2 } },
			{ id = "scan", name = "Speed Scan", say = "Read and use things 20% faster", mods = { holdMult = 0.8 } },
		},
		[10] = {
			{ id = "genius10", name = "Genius", say = "+3 clues for the team", mods = { clues = 3 } },
			{ id = "speedread10", name = "Speed Reader", say = "Read and use things twice as fast", mods = { holdMult = 0.5 } },
		},
	},
	muscle = {
		[3] = {
			{ id = "heave", name = "Big Heave", say = "Shove 20% faster", mods = { holdMult = 0.8 } },
			{ id = "tough", name = "Tough", say = "Start every game with a Party Shield", mods = { shield = true } },
		},
		[5] = {
			{ id = "sprinter", name = "Sprinter", say = "Run 5% faster", mods = { runMult = 1.05 } },
			{ id = "stamina", name = "Strong Lungs", say = "15% more stamina", mods = { staminaMult = 1.15 } },
		},
		[7] = {
			{ id = "push", name = "Strong Push", say = "Shove 20% faster", mods = { holdMult = 0.8 } },
			{ id = "chest", name = "Big Chest", say = "15% more stamina", mods = { staminaMult = 1.15 } },
		},
		[9] = {
			{ id = "power", name = "Power Shove", say = "Shove 30% faster", mods = { holdMult = 0.7 } },
			{ id = "charge", name = "Charge", say = "Run 8% faster", mods = { runMult = 1.08 } },
		},
		[10] = {
			{ id = "titan", name = "Titan", say = "Shove twice as fast", mods = { holdMult = 0.5 } },
			{ id = "ironlungs", name = "Iron Lungs", say = "50% more stamina", mods = { staminaMult = 1.5 } },
		},
	},
	glow = {
		[3] = {
			{ id = "bright", name = "Brighter Bulb", say = "Your light reaches a bit further", mods = { glowRange = 28 } },
			{ id = "secrets", name = "Secret Seeker", say = "Your team starts knowing one colour of the code", mods = { revealOne = true } },
		},
		[5] = {
			{ id = "sun", name = "Bright Beam", say = "Your light reaches further", mods = { glowRange = 32 } },
			{ id = "dazzle", name = "Twinkle", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
		},
		[7] = {
			{ id = "lamp", name = "Big Lamp", say = "Your light reaches much further", mods = { glowRange = 38 } },
			{ id = "dim", name = "Dimmer", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
		},
		[9] = {
			{ id = "flood", name = "Floodlight", say = "Your light reaches very far", mods = { glowRange = 44 } },
			{ id = "flash", name = "Flash", say = "The host sees you from 15% less far", mods = { sightMult = 0.85 } },
		},
		[10] = {
			{ id = "sun10", name = "Little Sun", say = "Your light fills a whole room", mods = { glowRange = 50 } },
			{ id = "dazzle10", name = "Dazzle", say = "The host sees you from 30% less far", mods = { sightMult = 0.7 } },
		},
	},
	patch = {
		[3] = {
			{ id = "bigheal", name = "Shields for All", say = "Shield every friend nearby, not just one", mods = { healShield = true } },
			{ id = "quickheal", name = "Quick Shield", say = "Shield recharges 15% faster", mods = { cooldownMult = 0.85 } },
		},
		[5] = {
			{ id = "guardian", name = "Guardian", say = "Shield recharges 20% faster", mods = { cooldownMult = 0.8 } },
			{ id = "medic", name = "Helper", say = "Free friends from the cage 20% faster", mods = { holdMult = 0.8 } },
		},
		[7] = {
			{ id = "care", name = "Caring", say = "Shield recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "nurse", name = "Nurse", say = "Free friends from the cage 20% faster", mods = { holdMult = 0.8 } },
		},
		[9] = {
			{ id = "hero", name = "Hero", say = "Shield recharges 25% faster", mods = { cooldownMult = 0.75 } },
			{ id = "rescuer", name = "Rescuer", say = "Free friends from the cage 30% faster", mods = { holdMult = 0.7 } },
		},
		[10] = {
			{ id = "guardian10", name = "Guardian Angel", say = "Shield recharges twice as fast", mods = { cooldownMult = 0.5 } },
			{ id = "medic10", name = "Field Medic", say = "Free friends from the cage twice as fast", mods = { holdMult = 0.5 } },
		},
	},
	echo = {
		[3] = {
			{ id = "throw", name = "Strong Throw", say = "Throw a noise a bit further", mods = { echoRange = 85 } },
			{ id = "echoquick", name = "Quick Echo", say = "Noise recharges 15% faster", mods = { cooldownMult = 0.85 } },
		},
		[5] = {
			{ id = "radar", name = "Good Ears", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
			{ id = "echofast", name = "Echo Boost", say = "Noise recharges 20% faster", mods = { cooldownMult = 0.8 } },
		},
		[7] = {
			{ id = "far", name = "Far Throw", say = "Throw a noise further", mods = { echoRange = 95 } },
			{ id = "hush", name = "Hush", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
		},
		[9] = {
			{ id = "boomer", name = "Boomer", say = "Throw a noise much further", mods = { echoRange = 110 } },
			{ id = "rapid", name = "Rapid Echo", say = "Noise recharges 25% faster", mods = { cooldownMult = 0.75 } },
		},
		[10] = {
			{ id = "radar10", name = "Radar Ears", say = "The host sees you from 30% less far", mods = { sightMult = 0.7 } },
			{ id = "echofast10", name = "Echo Storm", say = "Noise recharges twice as fast", mods = { cooldownMult = 0.5 } },
		},
	},
	bramble = {
		[3] = {
			{ id = "whisper", name = "Plant Whisperer", say = "Ask the plant 20% faster", mods = { holdMult = 0.8 } },
			{ id = "roots", name = "Deep Roots", say = "10% more stamina", mods = { staminaMult = 1.1 } },
		},
		[5] = {
			{ id = "camo", name = "Leafy", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
			{ id = "bloom", name = "Bloom", say = "Your team starts knowing one colour of the code", mods = { revealOne = true } },
		},
		[7] = {
			{ id = "listen", name = "Good Listener", say = "Ask the plant 20% faster", mods = { holdMult = 0.8 } },
			{ id = "vines", name = "Vines", say = "15% more stamina", mods = { staminaMult = 1.15 } },
		},
		[9] = {
			{ id = "thicket", name = "Thicket", say = "The host sees you from 15% less far", mods = { sightMult = 0.85 } },
			{ id = "sprout", name = "Sprout", say = "+1 clue for the team", mods = { clues = 1 } },
		},
		[10] = {
			{ id = "camo10", name = "Leaf Camouflage", say = "The host sees you from 35% less far", mods = { sightMult = 0.65 } },
			{ id = "whisper10", name = "Plant Friend", say = "Ask the plant twice as fast", mods = { holdMult = 0.5 } },
		},
	},
}

-- how far the bonuses can stack, whatever is picked
Progress.CAPS = { staminaMult = 1.5, runMult = 1.2, holdMult = 0.5, sightMult = 0.65, cooldownMult = 0.5, clues = 5 }
Progress.MAX_LEVEL = #Progress.LEVEL_XP

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
	local c = Progress.CAPS
	m.staminaMult = math.min(m.staminaMult, c.staminaMult)
	m.runMult = math.min(m.runMult, c.runMult)
	m.holdMult = math.max(m.holdMult, c.holdMult)
	m.sightMult = math.max(m.sightMult, c.sightMult)
	m.cooldownMult = math.max(m.cooldownMult, c.cooldownMult)
	m.clues = math.min(m.clues, c.clues)
	return m
end

return Progress
