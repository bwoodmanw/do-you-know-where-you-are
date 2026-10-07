--[[
	Config - numbers and names shared by the server and every player.
	Asset ids (pictures, sounds) are filled in once Brent uploads them to
	Roblox; until then the game uses Roblox materials and no custom sounds.
]]

local Config = {}

Config.TILE = 8 -- studs per map tile
Config.WALL_H = 14 -- room height
Config.GRACE = 20 -- seconds before the host comes out (Giggly)
Config.GRACE_SPOOKY = 12

Config.WALK = 12
Config.RUN = 20
Config.STAMINA_DRAIN = 22 -- per second while running
Config.STAMINA_REGEN = 15 -- per second otherwise

Config.HOST = {
	patrol = 8,
	search = 10,
	hunt = { giggly = 12, spooky = 14 },
	sight = { giggly = 32, spooky = 40 },
	shadowSight = 14, -- how close it must be to see Shadow
	catch = 4.5,
	lostAfter = 4, -- seconds out of sight before it gives up
}

-- Difficulty: chosen before the host comes out. timer = seconds to escape
-- before the lights go out and the host goes into a frenzy. bonus multiplies
-- the escape reward.
Config.DIFFICULTY_ORDER = { "easy", "normal", "hard", "nightmare" }
Config.DIFFICULTY = {
	easy = { name = "Easy", grace = 30, timer = 600, hunt = 13, sight = 26, catch = 4, clues = 5, bonus = 1 },
	normal = { name = "Normal", grace = 20, timer = 480, hunt = 14, sight = 32, catch = 4.5, clues = 3, bonus = 1.5 },
	hard = { name = "Hard", grace = 12, timer = 360, hunt = 15.5, sight = 40, catch = 5, clues = 2, bonus = 2 },
	nightmare = { name = "Nightmare", grace = 6, timer = 300, hunt = 17, sight = 48, catch = 5.5, clues = 1, bonus = 3 },
}

-- clues cost points earned in this game: the team's 1st, 2nd, 3rd+ clue
-- (Brainy pays half). Points from a game are scaled by POINT_SCALE.
Config.CLUE_COSTS = { 10, 20, 30 }
Config.POINT_SCALE = 0.67
-- reset one character's skill ladder (the Robux price is set on the
-- Developer Product: 49)
Config.RESET_POINTS = 500
-- the heartbeat that speeds up near the host (off: only the breathing tells)
Config.HEARTBEAT = false
-- host skills; cooldowns by difficulty
Config.HOST_SKILLS = {
	-- Pumpkin: a pumpkin thrown in a slow arc; a hit knocks you down
	throw = { min = 8, range = 45, flight = 1.2, radius = 4, knock = 2,
		cooldown = { easy = 20, normal = 15, hard = 12, nightmare = 9 } },
	-- Gummy Bear Man: sticky puddles (stuck for a moment); never many, never by doors
	gummy = { max = 4, melt = 40, stick = 3, clear = 2,
		cooldown = { easy = 14, normal = 10, hard = 8, nightmare = 6 } },
	-- Robot: the room he is in goes dark (light still spills in from next door)
	blackout = { seconds = 8, cooldown = { easy = 40, normal = 30, hard = 25, nightmare = 20 } },
}
-- the hosts: the model in ServerStorage/Characters and the skill. Each game
-- picks one: half the time the building's own, otherwise one of the others.
Config.HOSTS = {
	pumpkin = { model = "Host", name = "the Pumpkin Host", skill = "throw", tint = Color3.fromRGB(240, 120, 20) },
	gummy = { model = "HostGummy", name = "Gummy Bear Man", skill = "gummy", tint = Color3.fromRGB(230, 40, 80) },
	robot = { model = "HostRobot", name = "the Robot", skill = "blackout", tint = Color3.fromRGB(150, 160, 170) },
}
Config.BUILDING_HOST = { partyhouse = "pumpkin", gummy = "gummy", hospital = "robot" }
Config.CLUES = 3

Config.COLORS = { "red", "blue", "yellow", "green" }
Config.COLOR3 = {
	red = Color3.fromRGB(255, 77, 94),
	blue = Color3.fromRGB(61, 139, 255),
	yellow = Color3.fromRGB(255, 210, 63),
	green = Color3.fromRGB(70, 209, 96),
}

Config.SKILLS = {
	{ id = "tinker", name = "Tinker", icon = "\u{1F527}", say = "Picks locks", color = Color3.fromRGB(242, 140, 40) },
	{ id = "shadow", name = "Shadow", icon = "\u{1F319}", say = "Sneaks unseen", color = Color3.fromRGB(138, 107, 209) },
	{ id = "brainy", name = "Brainy", icon = "\u{1F9E0}", say = "Cracks codes", color = Color3.fromRGB(79, 179, 232) },
	{ id = "muscle", name = "Muscle", icon = "\u{1F4AA}", say = "Shoves heavy things", color = Color3.fromRGB(232, 80, 91) },
	{ id = "glow", name = "Glow", icon = "\u{1F4A1}", say = "Lights up secrets", color = Color3.fromRGB(184, 224, 90) },
	{ id = "patch", name = "Patch", icon = "\u{1F497}", say = "Shields and rescues", color = Color3.fromRGB(255, 179, 199) },
	{ id = "echo", name = "Echo", icon = "\u{1F3A7}", say = "Throws a noise", color = Color3.fromRGB(255, 210, 63) },
	{ id = "bramble", name = "Bramble", icon = "\u{1F33F}", say = "Talks to plants", color = Color3.fromRGB(143, 209, 106) },
}

Config.COOLDOWN = { shadow = 20, patch = 45, echo = 25 }

-- what each skill does, and how you use it, for the character select screen
Config.SKILL_INFO = {
	tinker = { about = "Picks the locked doors inside the house, so the team never needs to hunt for their keys. (The big exit door still needs the colour code.)", how = "Walk up to a locked door and hold F." },
	shadow = { about = "Sneaks: for a few seconds the host can't see or grab Shadow. Shadow is also harder to spot than anyone.", how = "Press the Sneak button. It recharges." },
	brainy = { about = "Reads the twisty party invitation and cracks the whole door code. Clues cost Brainy half as many points.", how = "Find the invitation in the Parlour and press E." },
	muscle = { about = "Shoves the heavy cabinet in the Music Room aside, opening a secret way out.", how = "Hold E at the cabinet." },
	glow = { about = "Carries a glowing light that brightens dark rooms, and lights up secret paint that shows the door code.", how = "Press E at the painted wall in the Library." },
	patch = { about = "Gives a nearby friend a Party Shield (one grab) and everyone nearby their breath back. Frees every caged friend at once, twice as fast.", how = "Press the Shield button. Hold E at the cage." },
	echo = { about = "Hears the host coming from further away, and throws a noise that sends the host to look somewhere else.", how = "Press Noise, then tap where to throw it." },
	bramble = { about = "Talks to plants: the big plant in the Conservatory whispers the door code to Bramble.", how = "Press E at the plant." },
}

Config.PHRASES = {
	"Over here!", "I found something!", "Hide!", "Run!", "Use your skill!", "Help me!",
	"Nice one!", "The door is open!", "Pop the balloons!", "It is coming!", "Ha ha ha!", "I want cake!",
}

-- icons for things you pick up
Config.ITEM_ICONS = { candy = "\u{1F36C}", shield = "\u{1F6E1}", balloon = "\u{1F388}" }

-- the two places in the experience: players arrive in the Lobby; a party is
-- sent to its own private server of the Party House. Found by name at run
-- time, so no ids need copying.
Config.LOBBY_PLACE = "Lobby"
Config.GAME_PLACE = "Party House"
-- the two places' ids (Creator Hub), so each script can tell it is in the right one
Config.PLACE_IDS = { lobby = 115501124890066, game = 110069561824739 }
Config.VOTE_SECONDS = 10
-- the host waits until everyone has chosen a character, or this many seconds
Config.PICK_WAIT = 120
-- a party in the Lobby closes if it has not started after this many seconds
Config.PARTY_HOLD = 180
-- which floor a Studio Play test builds (there is no Lobby teleport in Studio)
Config.STUDIO_MAP = "gummy" -- partyhouse, partyhouse_2, partyhouse_3, gummy
-- the Lobby's house model turns this many degrees to face the lawn (try 0 if it shows its back)
Config.LOBBY_HOUSE_TURN = 180
-- testing in Studio: force a host ("pumpkin", "gummy", "robot"); nil = random
Config.STUDIO_HOST = nil
-- characters' skin without the bumpy normal map (smoother faces); false to keep it
Config.FLAT_CHARACTER_SKIN = true
Config.MAX_PARTY = 6

-- Robux prices for boosts: the Developer Product id for each boost, created in
-- Creator Hub -> Escape Crew -> Monetization -> Developer Products. 0 = not on
-- sale for Robux (points only). Every boost can always be bought with points.
Config.ROBUX_PRODUCTS = {
	candy = 3716922790, -- 25 Robux
	shield = 3716924173, -- 60
	clue = 3716923841, -- 40
	energy = 3716924026, -- Second Wind, 25
	headstart = 3716924113, -- 50
	freeze = 3716936312, -- Frozen Pop, 50
	reset = 3716924568, -- resets one character's skill ladder, 49
}

-- Characters saved to Roblox (Studio: right-click the character in
-- ServerStorage/Characters -> Save to Roblox), name -> model asset id. The
-- Lobby shows these in 3D; the Party House uses them for any character not
-- imported there. 0 = not saved yet.
Config.CHARACTER_ASSETS = {
	Glow = 74307875851069,
	Patch = 120375206872909,
	Muscle = 116831403539618,
	Tinker = 115806881502179,
	Shadow = 85123632229176,
	Brainy = 96432127418740,
	Echo = 121427930738516,
	Bramble = 83770262810721,
	Host = 135742994182895,
	HostGummy = 106903651525041,
	HostRobot = 95188395596101,
}

-- Boost pictures: the Image asset id of each uploaded boost icon
-- (art/roblox-store/boost-*-512.png). 0 = show the emoji instead.
Config.BOOST_IMAGES = {
	candy = 122983417837830,
	shield = 121621852449445,
	clue = 123355295075279,
	energy = 101843924821215, -- Second Wind
	headstart = 109500734027827,
	freeze = 77471024527802,
	reset = 137033892267668,
}

-- filled in after uploading: { title = "rbxassetid://...", scare = "rbxassetid://...", ... }
Config.IMAGES = {}
-- daily login rewards: day 1-7 of an unbroken streak (then round again);
-- miss a day and it starts again at day 1. Roblox Premium members get
-- PREMIUM_DAILY_MULT times the points.
Config.DAILY = {
	{ points = 20 },
	{ points = 30 },
	{ points = 40, boost = "candy" },
	{ points = 50 },
	{ points = 60, boost = "energy" },
	{ points = 80 },
	{ points = 120, boost = "freeze" },
}
Config.PREMIUM_DAILY_MULT = 2
-- background music: audio asset ids (Creator Store or your own uploads).
-- Each list is shuffled; players set the volume with the music button.
Config.MUSIC = {
	lobby = {
		{ id = 76200647114315, name = "Go up - yeah!" },
		{ id = 110219102405339, name = "Turn me up right" },
		{ id = 104532983177380, name = "Run it like a crown" },
		{ id = 81622815713100, name = "Sweet but violent" },
		{ id = 114943415877728, name = "Shadow self" },
	},
	game = {
		{ id = 103218912557232, name = "Transmission" },
		{ id = 118449494725489, name = "Dead Frequency" },
		{ id = 123797473965749, name = "Sweet but violent" },
		{ id = 91340190574155, name = "Null Reckoning" },
		{ id = 127026458726333, name = "Override" },
		{ id = 129518539620106, name = "Teeth in" },
		{ id = 136562208725905, name = "I am the monster (Remastered)" },
		{ id = 124336285623807, name = "Hollow Veil" },
		{ id = 118983463747469, name = "Unknown Caller" },
	},
}
-- shown under the music button with the song's name
Config.MUSIC_ARTIST = "When Bears and Lions Attack"
-- where the Lobby house model's windows are, as fractions of its width (from
-- the middle) and height, for the host's peeks
Config.LOBBY_HOUSE_WINDOWS = { { -0.23, 0.72 }, { 0.02, 0.69 }, { 0.24, 0.73 }, { -0.3, 0.33 }, { 0.23, 0.33 } }
-- seconds between the host's peeks, and how long the face stays
Config.LOBBY_PEEK_GAP = { 18, 40 }
Config.LOBBY_PEEK_SECONDS = 2.5
-- Sounds: Roblox's licensed sound library (ProSoundEffects, free to use).
-- Swap any id for another from Studio's Toolbox -> Audio.
Config.SOUNDS = {
	pop = 9113263649, -- Balloon Pop 3
	hide = 9113837941, -- Cloth Rustle 5
	unhide = 9120839599, -- Wood Door Creak Squeak 11
	pick = 9117185722, -- Padlock Open Lock Pick
	unlock = 9116324156, -- Lock Unlock Door 10
	shove = 9114154737, -- Door Slides 7
	light = 9116395089, -- Magic Glows chiming hits 4
	reveal = 9116418035, -- Magic Tone Falling Shimmer 3
	plant = 9114518077, -- Foliage Movement 1
	present = 9126073001, -- Synth Sparkle bell ding
	candy = 9113959343, -- Crack Egg Crunchy 11
	energy = 9114172109, -- Drinking gulping 6 (Second Wind)
	bounce = 9113380196, -- Beach Ball 11
	bell = 9113421646, -- Bell Rings 1
	bonk = 9113484620, -- Body Hit 4
	throw = 9126229255, -- Whoosh by fast
	beep = 9119717523, -- Switch click
	wrong = 9113085764, -- Alarm Buzzer 5
	cage = 9114885296, -- Jail Cell Door 7
	rescue = 9114885622, -- Jail Cell Door 13
	escape = 9112766176, -- Crowd Cheer And Applause 1
	roar = 9113980480, -- Giant monster roar growl 2
	giggle = 9114571545, -- Ghost giggle 9
	sneak = 9126229255, -- Whoosh by fast
	heal = 9116395085, -- Magic chiming hits 5
	noise = 9120675895, -- Whistle calling 4
	breath = 9113983944, -- Deep monster breathing 1 (loops on the host)
	heart = 9119882039, -- Synth Whomps 38 (a heartbeat thump)
}
-- the longest a sound plays, in seconds (some library sounds are long)
Config.SOUND_MAX = { hide = 1.6, unhide = 1.5, escape = 5, cage = 2.5, rescue = 2, shove = 1.6, wrong = 1.2 }

return Config
