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
	-- the secret Basement: under the house (floor 0), unlocked by escaping the Attic
	{ id = "partyhouse_b", building = "partyhouse", floor = 0, name = "Party House: Secret Basement", icon = "\u{1F56F}", ready = true, secret = true, unlockAfter = "partyhouse_3" },
	{ id = "gummy", building = "gummy", floor = 1, name = "Gummy: Bounce Hall", icon = "\u{1F36C}", ready = true },
	{ id = "gummy_2", building = "gummy", floor = 2, name = "Gummy: Candy Factory", icon = "\u{1F36D}", ready = true },
	{ id = "gummy_3", building = "gummy", floor = 3, name = "Gummy: Jelly Vault", icon = "\u{1F36F}", ready = true },
	{ id = "hospital", building = "hospital", floor = 1, name = "Hospital: Ground Floor", icon = "\u{1F3E5}", ready = true },
	{ id = "hospital_2", building = "hospital", floor = 2, name = "Hospital: Wards", icon = "\u{1F6CF}", ready = true },
	{ id = "hospital_3", building = "hospital", floor = 3, name = "Hospital: Labs", icon = "\u{1F9EA}", ready = true },
	-- building 4 (8 Oct): unlocked by escaping the Hospital's Wards
	{ id = "school", building = "school", floor = 1, name = "School: Ground Floor", icon = "\u{1F3EB}", ready = true },
	{ id = "school_2", building = "school", floor = 2, name = "School: Classrooms", icon = "\u{1F4DA}", ready = true },
	{ id = "school_3", building = "school", floor = 3, name = "School: Clock Tower", icon = "\u{1F570}", ready = true },
	-- building 5 (8 Oct): unlocked by escaping the School's Classrooms
	{ id = "carnival", building = "carnival", floor = 1, name = "Carnival: The Midway", icon = "\u{1F3A0}", ready = true },
	{ id = "carnival_2", building = "carnival", floor = 2, name = "Carnival: The Big Top", icon = "\u{1F3AA}", ready = true },
	{ id = "carnival_3", building = "carnival", floor = 3, name = "Carnival: The Funhouse", icon = "\u{1F921}", ready = true },
	-- building 6 (8 Oct): unlocked by escaping the Carnival's Big Top
	{ id = "aquarium", building = "aquarium", floor = 1, name = "Aquarium: Main Hall", icon = "\u{1F41F}", ready = true },
	{ id = "aquarium_2", building = "aquarium", floor = 2, name = "Aquarium: Deep Sea", icon = "\u{1F419}", ready = true },
	{ id = "aquarium_3", building = "aquarium", floor = 3, name = "Aquarium: Rooftop Pools", icon = "\u{1F42C}", ready = true },
}

Progress.BUILDINGS = {
	{ id = "partyhouse", name = "The Party House" },
	{ id = "gummy", name = "Gummy Bounce House" },
	{ id = "hospital", name = "Abandoned Hospital" },
	{ id = "school", name = "Midnight School" },
	{ id = "carnival", name = "Creepy Carnival" },
	{ id = "aquarium", name = "Sunken Aquarium" },
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
		if (n.building == m.building and n.floor == m.floor + 1 and m.floor >= 1) or n.unlockAfter == id then
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
Progress.LEVEL_XP = { 0, 300, 800, 1600, 3000, 4800, 7000, 9600, 12600, 16000, -- XP needed for levels 1..10
	20000, 24500, 29500, 35000, 41000, 47500, 54500, 62000, 70000, 78500 } -- 11..20 (8 Oct: skills version 2)

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
	  glowRange  healAmount  healShield  echoRange  freeAll  barricadeHold
	Skills version 2 (8 Oct, SKILLS_V2.md): levels 11-20; every character has a
	button; levels 10 and 20 offer a big power (p10 / p20: read by the game).
	  burstMult burstTime (Echo's burst)  flareTime (Glow)  vineTime (Bramble)
	  cloneTime (Shadow's clone)  thinkTime (Brainy's Think! arrow)
	Since 9 Oct the timed / distance values (Progress.ADDS) are steps added to
	the game's base value, never "the biggest wins".
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
	-- levels 12-18: smaller steps (the caps stop them stacking too far)
	[12] = {
		{ id = "lungs12", name = "Second Lungs", say = "5% more stamina", mods = { staminaMult = 1.05 } },
		{ id = "hands12", name = "Light Fingers", say = "Hold things 4% faster", mods = { holdMult = 0.96 } },
	},
	[14] = {
		{ id = "feet14", name = "Spring Step", say = "Run 3% faster", mods = { runMult = 1.03 } },
		{ id = "quiet14", name = "Tiptoe", say = "The host sees you from 5% less far", mods = { sightMult = 0.95 } },
	},
	[16] = {
		{ id = "lungs16", name = "Long Breath", say = "5% more stamina", mods = { staminaMult = 1.05 } },
		{ id = "hands16", name = "Deft Hands", say = "Hold things 4% faster", mods = { holdMult = 0.96 } },
	},
	[18] = {
		{ id = "feet18", name = "Fleet Feet", say = "Run 3% faster", mods = { runMult = 1.03 } },
		{ id = "quiet18", name = "Hush Steps", say = "The host sees you from 5% less far", mods = { sightMult = 0.95 } },
	},
}
local SPECIAL = {
	tinker = {
		[3] = {
			{ id = "fingers", name = "Quick Fingers", say = "Pick locked doors 15% faster", mods = { holdMult = 0.85 } },
			{ id = "lucky", name = "Lucky Guess", say = "Your team starts knowing one color of the code (one a game, not on Nightmare)", mods = { revealOne = true } },
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
			{ id = "mouse10", name = "Wind-up Mouse", say = "Toolkit also lets a squeaky toy mouse run off - the host chases it for 5 s", mods = { p10 = "mouse" } },
			{ id = "skeleton10", name = "Skeleton Key", say = "The first lock you pick each game opens every locked door on the floor", mods = { p10 = "skeleton" } },
		},
		[11] = {
			{ id = "tk11", name = "Quick Toolkit", say = "Toolkit recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "fingers11", name = "Nimble Fingers", say = "Hold things 10% faster", mods = { holdMult = 0.9 } },
		},
		[13] = {
			{ id = "spare13", name = "Spare Clue", say = "+1 free clue for the team", mods = { clues = 1 } },
			{ id = "belt13", name = "Light Tool Belt", say = "10% more stamina", mods = { staminaMult = 1.1 } },
		},
		[15] = {
			{ id = "tk15", name = "Oiled Toolkit", say = "Toolkit recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "steady15", name = "Steady Hands", say = "Hold things 10% faster", mods = { holdMult = 0.9 } },
		},
		[17] = {
			{ id = "hands17", name = "Steady Fingers", say = "Hold things 10% faster", mods = { holdMult = 0.9 } },
			{ id = "quiet17", name = "Soft Soles", say = "The host sees you from 8% less far", mods = { sightMult = 0.92 } },
		},
		[19] = {
			{ id = "tk19", name = "Turbo Toolkit", say = "Toolkit recharges 20% faster", mods = { cooldownMult = 0.8 } },
			{ id = "dash19", name = "Quick Dash", say = "Run 5% faster", mods = { runMult = 1.05 } },
		},
		[20] = {
			{ id = "mastertinker20", name = "Master Tinker", say = "Picking the big door's keypad shows the team two colors", mods = { p20 = "mastertinker" } },
			{ id = "boots20", name = "Rocket Boots", say = "Each Toolkit also gives you a rocket run: 20% faster for 5 s", mods = { p20 = "boots" } },
		},
	},
	shadow = {
		[3] = {
			{ id = "long", name = "Long Sneak", say = "Sneak lasts 2 s longer", mods = { sneakTime = 2 } },
			{ id = "recharge", name = "Fast Recharge", say = "Sneak recharges 20% faster", mods = { cooldownMult = 0.8 } },
		},
		[5] = {
			{ id = "ghost", name = "Longer Sneak", say = "Sneak lasts 2 s longer", mods = { sneakTime = 2 } },
			{ id = "blur", name = "Swift", say = "Run 5% faster", mods = { runMult = 1.05 } },
		},
		[7] = {
			{ id = "shade", name = "Shade", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
			{ id = "rest", name = "Quick Rest", say = "Sneak recharges 20% faster", mods = { cooldownMult = 0.8 } },
		},
		[9] = {
			{ id = "phantom", name = "Phantom", say = "Sneak lasts 2 s longer", mods = { sneakTime = 2 } },
			{ id = "dash", name = "Dash", say = "Run 8% faster", mods = { runMult = 1.08 } },
		},
		[10] = {
			{ id = "clone10", name = "Shadow Clone", say = "Sneak also sends a dark copy of you running off - the host chases it for 4 s", mods = { p10 = "clone" } },
			{ id = "ghost10", name = "Ghost", say = "Sneak lasts 4 s longer", mods = { sneakTime = 4 } },
		},
		[11] = {
			{ id = "clone11", name = "Lasting Shadow", say = "Your clone fools the host 1 s longer", mods = { cloneTime = 1 } },
			{ id = "silent11", name = "Silent", say = "The host sees you from 8% less far", mods = { sightMult = 0.92 } },
		},
		[13] = {
			{ id = "rest13", name = "Quick Rest", say = "Sneak recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "dash13", name = "Dart", say = "Run 5% faster", mods = { runMult = 1.05 } },
		},
		[15] = {
			{ id = "clone15", name = "Deep Shadow", say = "Your clone fools the host 1 s longer", mods = { cloneTime = 1 } },
			{ id = "sneak15", name = "Long Shade", say = "Sneak lasts 2 s longer", mods = { sneakTime = 2 } },
		},
		[17] = {
			{ id = "rest17", name = "Swift Rest", say = "Sneak recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "shade17", name = "Shade", say = "The host sees you from 8% less far", mods = { sightMult = 0.92 } },
		},
		[19] = {
			{ id = "clone19", name = "Living Shadow", say = "Your clone fools the host 1 s longer", mods = { cloneTime = 1 } },
			{ id = "sneak19", name = "Vanish", say = "Sneak lasts 2 s longer", mods = { sneakTime = 2 } },
		},
		[20] = {
			{ id = "nightwalker20", name = "Night Walker", say = "In a dark room the host never sees you", mods = { p20 = "nightwalker" } },
			{ id = "doubleclone20", name = "Double Clone", say = "Sneak sends two clones, running different ways", mods = { p20 = "doubleclone" } },
		},
	},
	-- (8 Oct: each level teaches Brainy something new; a pick that is no longer
	-- offered stops counting and that level can be chosen again - BRAINY_LADDER.md)
	brainy = {
		[3] = {
			{ id = "hints", name = "Bonus Hint", say = "+1 free clue for the team", mods = { clues = 1 } },
			{ id = "trick", name = "Trick Spotter", say = "Trick balloons look gray and droopy to your whole team", mods = { trickSight = true } },
		},
		[5] = {
			{ id = "speedread", name = "Quick Reader", say = "Read and use things 20% faster", mods = { holdMult = 0.8 } },
			{ id = "twostep", name = "Two-Step Clue", say = "Clues also light up the step after next", mods = { twoStep = true } },
		},
		[7] = {
			{ id = "notebook", name = "Notebook", say = "+1 free clue for the team", mods = { clues = 1 } },
			{ id = "keyfinder", name = "Key Finder", say = "Rooms hiding a key show a key on your team's map", mods = { keyMap = true } },
		},
		[9] = {
			{ id = "scan", name = "Speed Scan", say = "Read and use things 20% faster", mods = { holdMult = 0.8 } },
			{ id = "longread", name = "Long Read", say = "Read the invitation from twice as far away", mods = { longRead = true } },
		},
		[10] = {
			{ id = "genius10", name = "Genius", say = "+3 free clues for the team", mods = { clues = 3 } },
			{ id = "mastermind", name = "Mastermind", say = "Your team's first clue is free and shows every step to the exit", mods = { mastermind = true } },
		},
		[11] = {
			{ id = "think11", name = "Quick Thinker", say = "Think! recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "hint11", name = "Long Think", say = "The Think! arrow stays 5 s longer", mods = { thinkTime = 5 } },
		},
		[13] = {
			{ id = "read13", name = "Fast Reader", say = "Read and use things 15% faster", mods = { holdMult = 0.85 } },
			{ id = "watch13", name = "Watchful", say = "The host sees you from 8% less far", mods = { sightMult = 0.92 } },
		},
		[15] = {
			{ id = "think15", name = "Bright Idea", say = "Think! recharges 20% faster", mods = { cooldownMult = 0.8 } },
			{ id = "lungs15", name = "Deep Thinker", say = "10% more stamina", mods = { staminaMult = 1.1 } },
		},
		[17] = {
			{ id = "hint17", name = "Deep Think", say = "The Think! arrow stays 5 s longer", mods = { thinkTime = 5 } },
			{ id = "dash17", name = "Quick Steps", say = "Run 5% faster", mods = { runMult = 1.05 } },
		},
		[19] = {
			{ id = "think19", name = "Brainwave", say = "Think! recharges 25% faster", mods = { cooldownMult = 0.75 } },
			{ id = "quiet19", name = "Library Voice", say = "The host sees you from 8% less far", mods = { sightMult = 0.92 } },
		},
		[20] = {
			{ id = "photo20", name = "Photographic Memory", say = "Your first Think! each game also shows one color of the door code (not on Nightmare)", mods = { p20 = "photo" } },
			{ id = "bigbrain20", name = "Big Brain", say = "Think! shows the next two steps", mods = { p20 = "bigbrain" } },
		},
	},
	muscle = {
		[3] = {
			{ id = "heave", name = "Big Heave", say = "Shove, free friends and search 20% faster", mods = { holdMult = 0.8 } },
			{ id = "tough", name = "Tough", say = "Start every game with a Party Shield", mods = { shield = true } },
		},
		[5] = {
			{ id = "sprinter", name = "Sprinter", say = "Run 5% faster", mods = { runMult = 1.05 } },
			{ id = "stamina", name = "Strong Lungs", say = "15% more stamina", mods = { staminaMult = 1.15 } },
		},
		[7] = {
			{ id = "push", name = "Strong Push", say = "Shove, free friends and search 20% faster", mods = { holdMult = 0.8 } },
			{ id = "sturdy", name = "Sturdy Barricade", say = "The host is stuck at your barricade 2 s longer", mods = { barricadeHold = 2 } },
		},
		[9] = {
			{ id = "power", name = "Power Shove", say = "Shove, free friends and search 30% faster", mods = { holdMult = 0.7 } },
			{ id = "builder", name = "Quick Builder", say = "Barricade recharges 25% faster", mods = { cooldownMult = 0.75 } },
		},
		[10] = {
			{ id = "pound10", name = "Ground Pound", say = "With no crate near, your button stamps the floor: the host within 10 studs is stunned 2 s", mods = { p10 = "pound" } },
			{ id = "ironlungs", name = "Iron Lungs", say = "Your stamina refills twice as fast", mods = { p10 = "ironlungs" } },
		},
		[11] = {
			{ id = "heave11", name = "Heave Ho", say = "Shove, free friends and search 15% faster", mods = { holdMult = 0.85 } },
			{ id = "build11", name = "Builder", say = "Your button recharges 15% faster", mods = { cooldownMult = 0.85 } },
		},
		[13] = {
			{ id = "hold13", name = "Solid Barricade", say = "The host is stuck at your barricade 1 s longer", mods = { barricadeHold = 1 } },
			{ id = "lungs13", name = "Big Chest", say = "10% more stamina", mods = { staminaMult = 1.1 } },
		},
		[15] = {
			{ id = "build15", name = "Quick Builder", say = "Your button recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "stride15", name = "Long Stride", say = "Run 5% faster", mods = { runMult = 1.05 } },
		},
		[17] = {
			{ id = "hold17", name = "Rock Barricade", say = "The host is stuck at your barricade 1 s longer", mods = { barricadeHold = 1 } },
			{ id = "sprint17", name = "Sprinter", say = "Run 5% faster", mods = { runMult = 1.05 } },
		},
		[19] = {
			{ id = "titan19", name = "Mighty", say = "The host is stuck at your barricade 1 s longer", mods = { barricadeHold = 1 } },
			{ id = "build19", name = "Master Builder", say = "Your button recharges 20% faster", mods = { cooldownMult = 0.8 } },
		},
		[20] = {
			{ id = "bulldozer20", name = "Bulldozer", say = "Shove junk out of doorways instantly - no holding", mods = { p20 = "bulldozer" } },
			{ id = "fortress20", name = "Fortress", say = "Build two barricades before your button recharges", mods = { p20 = "fortress" } },
		},
	},
	glow = {
		[3] = {
			{ id = "bright", name = "Brighter Bulb", say = "Your light reaches 4 studs further", mods = { glowRange = 4 } },
			{ id = "secrets", name = "Secret Seeker", say = "Your team starts knowing one color of the code (one a game, not on Nightmare)", mods = { revealOne = true } },
		},
		[5] = {
			{ id = "sun", name = "Bright Beam", say = "Your light reaches 4 studs further", mods = { glowRange = 4 } },
			{ id = "dazzle", name = "Twinkle", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
		},
		[7] = {
			{ id = "lamp", name = "Big Lamp", say = "Your light reaches 4 studs further", mods = { glowRange = 4 } },
			{ id = "dim", name = "Dimmer", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
		},
		[9] = {
			{ id = "flood", name = "Floodlight", say = "Your light reaches 4 studs further", mods = { glowRange = 4 } },
			{ id = "flash", name = "Flash", say = "The host sees you from 15% less far", mods = { sightMult = 0.85 } },
		},
		[10] = {
			{ id = "nightlight10", name = "Night Light", say = "Flare also leaves a lamp: the room stays lit for 60 s", mods = { p10 = "nightlight" } },
			{ id = "dazzle10", name = "Dazzle", say = "Flare makes the host stop and blink for 2 s if he is in your light", mods = { p10 = "dazzle" } },
		},
		[11] = {
			{ id = "flare11", name = "Long Flare", say = "Flare lasts 2 s longer and reaches friends 4 studs further", mods = { flareTime = 2, flareRange = 4 } },
			{ id = "bulb11", name = "Searchlight", say = "Your light reaches 4 studs further", mods = { glowRange = 4 } },
		},
		[13] = {
			{ id = "quick13", name = "Quick Spark", say = "Flare recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "dim13", name = "Soft Glow", say = "The host sees you from 8% less far", mods = { sightMult = 0.92 } },
		},
		[15] = {
			{ id = "flare15", name = "Longer Flare", say = "Flare lasts 2 s longer, reaches 4 studs further, +2% stamina", mods = { flareTime = 2, flareRange = 4, flareStamina = 2 } },
			{ id = "worm15", name = "Glow Worm", say = "The host sees you from 8% less far", mods = { sightMult = 0.92 } },
		},
		[17] = {
			{ id = "quick17", name = "Bright Spark", say = "Flare recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "bulb17", name = "Warm Glow", say = "Flare gives friends 4% more stamina back", mods = { flareStamina = 4 } },
		},
		[19] = {
			{ id = "flare19", name = "Blazing Flare", say = "Flare lasts 2 s longer and reaches friends 4 studs further", mods = { flareTime = 2, flareRange = 4 } },
			{ id = "dim19", name = "Twilight", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
		},
		[20] = {
			{ id = "sun20", name = "Little Sun", say = "Your light reaches 12 studs further - a whole room", mods = { glowRange = 12 } },
			{ id = "beacon20", name = "Beacon", say = "Flare reaches the whole team, anywhere: 25% stamina and 5% faster for 5 s, and shows everyone through walls", mods = { p20 = "beacon" } },
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
			{ id = "hug10", name = "Group Hug", say = "Shield also gives every friend within 20 studs all their stamina back", mods = { p10 = "hug" } },
			{ id = "guardian10", name = "Guardian Angel", say = "Shield twice before your button recharges", mods = { p10 = "twoshields" } },
		},
		[11] = {
			{ id = "care11", name = "Kind Heart", say = "Shield recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "nurse11", name = "Gentle Hands", say = "Free friends from the cage 15% faster", mods = { holdMult = 0.85 } },
		},
		[13] = {
			{ id = "lungs13", name = "Fresh Air", say = "10% more stamina", mods = { staminaMult = 1.1 } },
			{ id = "shield13", name = "Own Shield", say = "Start every game with a Party Shield", mods = { shield = true } },
		},
		[15] = {
			{ id = "care15", name = "Big Heart", say = "Shield recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "nurse15", name = "Quick Bandage", say = "Free friends from the cage 15% faster", mods = { holdMult = 0.85 } },
		},
		[17] = {
			{ id = "quiet17", name = "Quiet Shoes", say = "The host sees you from 8% less far", mods = { sightMult = 0.92 } },
			{ id = "dash17", name = "On Call", say = "Run 5% faster", mods = { runMult = 1.05 } },
		},
		[19] = {
			{ id = "care19", name = "Golden Heart", say = "Shield recharges 20% faster", mods = { cooldownMult = 0.8 } },
			{ id = "hint19", name = "First Aid Kit", say = "+1 free clue for the team", mods = { clues = 1 } },
		},
		[20] = {
			{ id = "guardian20", name = "Guardian", say = "Once a game, a caged friend is freed the moment you come near the cage", mods = { p20 = "guardian" } },
			{ id = "medicrun20", name = "Medic Run", say = "Run 10% faster while a friend is near you", mods = { p20 = "medicrun" } },
		},
	},
	echo = {
		[3] = {
			{ id = "throw", name = "Strong Throw", say = "Throw a noise 15 studs further", mods = { echoRange = 15 } },
			{ id = "echoquick", name = "Quick Echo", say = "Noise recharges 15% faster", mods = { cooldownMult = 0.85 } },
		},
		[5] = {
			{ id = "radar", name = "Good Ears", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
			{ id = "echofast", name = "Echo Boost", say = "Noise recharges 20% faster", mods = { cooldownMult = 0.8 } },
		},
		[7] = {
			{ id = "far", name = "Far Throw", say = "Throw a noise 10 studs further", mods = { echoRange = 10 } },
			{ id = "hush", name = "Hush", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
		},
		[9] = {
			{ id = "boomer", name = "Boomer", say = "Throw a noise 15 studs further", mods = { echoRange = 15 } },
			{ id = "rapid", name = "Rapid Echo", say = "Noise recharges 25% faster", mods = { cooldownMult = 0.75 } },
		},
		[10] = {
			{ id = "double10", name = "Double Throw", say = "Throw two noises before Noise recharges", mods = { p10 = "double" } },
			{ id = "echomap10", name = "Echo Map", say = "After a noise you see the host through walls for 5 s", mods = { p10 = "echomap" } },
		},
		[11] = {
			{ id = "burst11", name = "Bigger Burst", say = "Your burst: 3% faster and 1 s longer", mods = { burstMult = 0.03, burstTime = 1 } },
			{ id = "throw11", name = "Long Arm", say = "Throw a noise 10 studs further", mods = { echoRange = 10 } },
		},
		[13] = {
			{ id = "quick13", name = "Quick Echo", say = "Noise recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "ears13", name = "Sharp Ears", say = "The host sees you from 8% less far", mods = { sightMult = 0.92 } },
		},
		[15] = {
			{ id = "burst15", name = "Strong Burst", say = "Your burst: 2% faster and 1 s longer", mods = { burstMult = 0.02, burstTime = 1 } },
			{ id = "throw15", name = "Far Shout", say = "Throw a noise 10 studs further", mods = { echoRange = 10 } },
		},
		[17] = {
			{ id = "quick17", name = "Fast Echo", say = "Noise recharges 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "lungs17", name = "Singer's Lungs", say = "10% more stamina", mods = { staminaMult = 1.1 } },
		},
		[19] = {
			{ id = "burst19", name = "Rush", say = "Your burst: 2% faster", mods = { burstMult = 0.02 } },
			{ id = "quick19", name = "Rapid Echo", say = "Noise recharges 20% faster", mods = { cooldownMult = 0.8 } },
		},
		[20] = {
			{ id = "soundwave20", name = "Sound Wave", say = "A noise landing near the host stuns him 1 s", mods = { p20 = "soundwave" } },
			{ id = "superburst20", name = "Super Burst", say = "Your burst: 5% faster and 2 s longer", mods = { burstMult = 0.05, burstTime = 2 } },
		},
	},
	bramble = {
		[3] = {
			{ id = "whisper", name = "Plant Whisperer", say = "Ask the plant 20% faster", mods = { holdMult = 0.8 } },
			{ id = "roots", name = "Deep Roots", say = "10% more stamina", mods = { staminaMult = 1.1 } },
		},
		[5] = {
			{ id = "camo", name = "Leafy", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
			{ id = "bloom", name = "Bloom", say = "Your team starts knowing one color of the code (one a game, not on Nightmare)", mods = { revealOne = true } },
		},
		[7] = {
			{ id = "listen", name = "Good Listener", say = "Ask the plant 20% faster", mods = { holdMult = 0.8 } },
			{ id = "vines", name = "Ivy", say = "15% more stamina", mods = { staminaMult = 1.15 } },
		},
		[9] = {
			{ id = "thicket", name = "Thicket", say = "The host sees you from 15% less far", mods = { sightMult = 0.85 } },
			{ id = "sprout", name = "Sprout", say = "+1 clue for the team", mods = { clues = 1 } },
		},
		[10] = {
			{ id = "snapper10", name = "Snapper Plant", say = "Your vines snap shut on the host the first time he steps in: held 2 s", mods = { p10 = "snapper" } },
			{ id = "leaves10", name = "Hide in the Leaves", say = "Standing still, you blend in: the host only sees you up close", mods = { p10 = "leaves" } },
		},
		[11] = {
			{ id = "vine11", name = "Thick Vines", say = "Vines last 2 s longer", mods = { vineTime = 2 } },
			{ id = "leafy11", name = "Leafy Coat", say = "The host sees you from 8% less far", mods = { sightMult = 0.92 } },
		},
		[13] = {
			{ id = "quick13", name = "Fast Growth", say = "Vines recharge 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "roots13", name = "Strong Roots", say = "10% more stamina", mods = { staminaMult = 1.1 } },
		},
		[15] = {
			{ id = "vine15", name = "Bramble Wall", say = "Vines last 2 s longer", mods = { vineTime = 2 } },
			{ id = "breath15", name = "Deep Breath", say = "10% more stamina", mods = { staminaMult = 1.1 } },
		},
		[17] = {
			{ id = "quick17", name = "Spring Growth", say = "Vines recharge 15% faster", mods = { cooldownMult = 0.85 } },
			{ id = "sprout17", name = "Sprout", say = "+1 free clue for the team", mods = { clues = 1 } },
		},
		[19] = {
			{ id = "vine19", name = "Jungle", say = "Vines last 2 s longer", mods = { vineTime = 2 } },
			{ id = "thicket19", name = "Thicket", say = "The host sees you from 10% less far", mods = { sightMult = 0.9 } },
		},
		[20] = {
			{ id = "forest20", name = "Forest Friend", say = "The big plant answers you instantly, and +1 free clue for the team", mods = { p20 = "forest", clues = 1 } },
			{ id = "overgrowth20", name = "Overgrowth", say = "Vines grow across two doorways at once", mods = { p20 = "overgrowth" } },
		},
	},
}

-- steps that add up (9 Oct, LADDER_FIX.md): each pick adds its number to the
-- game's base value (Main.server applyMods), so no later pick wipes out an
-- earlier one. Taking every step gives the old best number (or a little more).
Progress.ADDS = { sneakTime = true, cloneTime = true, glowRange = true, echoRange = true, barricadeHold = true,
	burstMult = true, burstTime = true, flareTime = true, flareRange = true, flareStamina = true, vineTime = true, thinkTime = true }

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
						elseif Progress.ADDS[k] then
							m[k] = (m[k] or 0) + v
						elseif k == "healAmount" then
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
