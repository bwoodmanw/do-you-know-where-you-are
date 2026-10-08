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
-- Developer Product in Creator Hub; the Lobby button reads it from there)
Config.RESET_POINTS = 800
-- seconds before the same player can crawl through a vent again
Config.VENT_REUSE = 2.5
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
	-- the Caretaker: padlocks a doorway near a kid he can see, on the far side
	-- of them (never a locked door, the exit or the host's door); Tinker picks it
	lockup = { seconds = 6, near = 3, cooldown = { easy = 30, normal = 22, hard = 18, nightmare = 14 } },
	-- the Clown Bear: jack-in-the-boxes on random checked spots when the floor
	-- starts; one springs when a kid comes near (not sneaking or hidden) and
	-- tells him where they are; it winds back up in the same place; Tinker
	-- winds one down for good (hold)
	jackbox = { count = { easy = 3, normal = 4, hard = 5, nightmare = 6 }, near = 6, rearm = 30, wind = 2, show = 3 },
	-- the Anglerfish Keeper: while he patrols he leaves fake presents (at most
	-- max, each lasts `last` s); open one and it tells him where you are.
	-- Brainy and Glow can pop a fake safely.
	fakegift = { max = 3, last = 60, show = 3, clear = 4, cooldown = { easy = 35, normal = 25, hard = 20, nightmare = 15 } },
}
-- the hosts: the model in ServerStorage/Characters and the skill. Each game
-- picks one: half the time the building's own, otherwise one of the others.
Config.HOSTS = {
	pumpkin = { model = "Host", name = "the Pumpkin Host", skill = "throw", tint = Color3.fromRGB(240, 120, 20) },
	gummy = { model = "HostGummy", name = "Gummy Bear Man", skill = "gummy", tint = Color3.fromRGB(230, 40, 80) },
	robot = { model = "HostRobot", name = "the Robot", skill = "blackout", tint = Color3.fromRGB(150, 160, 170) },
	caretaker = { model = "HostCaretaker", name = "the Caretaker", skill = "lockup", tint = Color3.fromRGB(120, 160, 120) },
	clownbear = { model = "HostClownBear", name = "the Clown Bear", skill = "jackbox", tint = Color3.fromRGB(240, 150, 170) },
	-- the Aquarium's host (hidden = true would keep a host out of the random
	-- picks); lure = a glowing lure on a stalk above his head (Meshy lost the
	-- model's own)
	anglerfish = { model = "HostAnglerfish", name = "the Anglerfish Keeper", skill = "fakegift", tint = Color3.fromRGB(60, 110, 130), lure = true },
}
Config.BUILDING_HOST = { partyhouse = "pumpkin", gummy = "gummy", hospital = "robot", school = "caretaker", carnival = "clownbear", aquarium = "anglerfish" }
-- the "escaped all floors" badge counts these buildings' floors (its badge says 9 floors)
Config.ALL_FLOORS_BUILDINGS = { partyhouse = true, gummy = true, hospital = true }
Config.CLUES = 3

Config.COLORS = { "red", "blue", "yellow", "green" }
Config.COLOR3 = {
	red = Color3.fromRGB(255, 77, 94),
	blue = Color3.fromRGB(61, 139, 255),
	yellow = Color3.fromRGB(255, 210, 63),
	green = Color3.fromRGB(70, 209, 96),
}
-- a picture for each colour, so colour-blind players can read the code too
Config.COLOR_SHAPE = { red = "\u{2764}\u{FE0F}", blue = "\u{1F4A7}", yellow = "\u{2B50}", green = "\u{1F340}" }

-- badges: create each in Creator Hub (Escape Crew -> Badges), then put its id
-- here; 0 = not made yet (skipped)
Config.BADGES = {
	firstEscape = 4113829508606477, -- Escaped! (first escape)
	partyhouse = 52874019824656, -- escaped the Party House's top floor (Attic)
	gummy = 4415169378717199, -- escaped the Gummy Bounce House's top floor (Jelly Vault)
	hospital = 3323093080758728, -- escaped the Hospital's top floor (Labs)
	school = 1104557368847767, -- Top of the Class: escaped the Midnight School's top floor (Clock Tower)
	allFloors = 1673377768038318, -- escaped all 9 floors
	carnival = 0, -- Star of the Show: escaped the Carnival's top floor (Funhouse)
	aquarium = 0, -- Making a Splash: escaped the Aquarium's top floor (Rooftop Pools)
	basement = 0, -- Down in the Dark: escaped the Party House's Secret Basement
	corn = 0, -- Candy Corn Collector: found Config.EVENT.goal candy corns (Halloween)
	tower = 2702531171107423, -- Tower Climber: reached the top in a Tower Run
	rescuer = 4200883843590712, -- Hero of the Crew: freed 10 friends from the cage
	untouched = 1991556459225776, -- Untouchable: escaped without being caught
	nightmare = 1282994468042939, -- Nightmare Escaper: escaped on Nightmare
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

Config.COOLDOWN = { shadow = 20, patch = 45, echo = 25, muscle = 25 }
-- Echo's noise: seconds the host goes to it and ignores the kids it can see
Config.ECHO_LURE = 5
-- room sounds, quiet and looped (Roblox's licensed Pro Sound Effects library)
Config.AMBIENT = {
	hum = 9112812234, -- Landing Craft Interior, Constant Hum (boilers, generators)
	factory = 9112796599, -- Industrial Ambience, Foundry (conveyors, factory)
	fire = 9112780462, -- Fireplace, Crackly, Constant (parlour, library)
	wind = 9118747853, -- Interior Wind, Semi Arctic Howl (attic)
	beep = 9113084761, -- Alarm Beep, Console, Constant (wards, x-ray)
	tick = 9114071134, -- Dial Switch, Sharp Ticking (clock room)
	drip = 9120607471, -- Water Trickle, Dripping (bathrooms, laundry, the sticky archive)
	bubble = 9112752575, -- Bubbles Dribble, Small Bloops (chocolate river, jelly)
	buzz = 9112823813, -- Light Bulb Buzz (hospital corridors, TVs)
}
-- Halloween dressing in every room (orange / purple bunting, paper bats)
Config.HALLOWEEN = true
-- the coach for new players: tips during their first games
Config.COACH_GAMES = 2
-- Muscle's Barricade: crates beside doorways (crates per floor), how close he
-- must be (studs), how long it stands, how long the host is stuck smashing it
Config.BARRICADE = { crates = 6, reach = 16, stands = 10, hold = 4 }

-- what each skill does, and how you use it, for the character select screen
Config.SKILL_INFO = {
	tinker = { about = "Picks the locked doors inside the house, so the team never needs to hunt for their keys - the Store Room too. Once a game Tinker can pick the big door's keypad to learn one colour of the code.", how = "Hold F at a locked door, or at the big door's keypad." },
	shadow = { about = "Sneaks: for a few seconds the host can't see or grab Shadow. Shadow is also harder to spot than anyone.", how = "Press the Sneak button. It recharges." },
	brainy = { about = "Reads the twisty party invitation and cracks the whole door code. Clues cost Brainy half as many points.", how = "Find the invitation in the Parlour and press E." },
	muscle = { about = "Shoves away junk heaped in blocked doorways (and the Junk Cupboard's bonus present), quietly. Barricade: slides a \u{1F4AA} crate into a doorway - friends squeeze through, the host has to smash it.", how = "Hold E at blocked doorways. Press Barricade next to a \u{1F4AA} crate." },
	glow = { about = "Carries a glowing light that brightens dark rooms, and lights up secret paint that shows the door code.", how = "Press E at the painted wall in the Library." },
	patch = { about = "Friends near Patch get half their stamina back (once every 10 seconds each). Her Shield button gives a friend a Party Shield. She frees every caged friend at once, faster than anyone.", how = "Stay close to friends. Press the Shield button. Hold E at the cage." },
	echo = { about = "Hears the host coming from further away, and throws a noise that sends the host to look somewhere else.", how = "Press Noise, then tap where to throw it." },
	bramble = { about = "Talks to plants: the big plant in the Conservatory whispers the door code to Bramble.", how = "Press E at the plant." },
}

Config.PHRASES = {
	"Over here!", "I found something!", "Key found!", "Help me!",
	"Need Tinker!", "Need Brainy!", "Hide!", "Run!",
	"It is coming!", "The door is open!", "Use your skill!", "Pop the balloons!",
	"Nice one!", "Thank you!", "Ha ha ha!", "I want cake!",
}
-- these also drop a pin where you stand, seen by the whole team through
-- walls for PING_SECONDS
Config.PING_PHRASES = { ["Over here!"] = true, ["I found something!"] = true, ["Key found!"] = true, ["Help me!"] = true, ["Need Tinker!"] = true, ["Need Brainy!"] = true }
Config.PING_SECONDS = 6

-- the Halloween Candy Corn Hunt: candy corns on every floor until `ends`
-- (os.time: 1 Nov 2026, midnight US Eastern). Each is `points` for whoever
-- picks it up; `goal` in all earns the badge (BADGES.corn).
Config.EVENT = { name = "Candy Corn Hunt", ends = 1793505600, perFloor = 6, points = 3, goal = 50, near = 4 }

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
Config.STUDIO_MAP = "aquarium" -- partyhouse(_2, _3, _b = the secret Basement), gummy(_2, _3), hospital(_2, _3), school(_2, _3), carnival(_2, _3), aquarium(_2, _3)
-- the Lobby's house model turns this many degrees to face the lawn (try 0 if it shows its back)
Config.LOBBY_HOUSE_TURN = 180
-- testing in Studio: force a host ("pumpkin", "gummy", "robot", "caretaker", "clownbear", "anglerfish"); nil = random
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
	reset = 3716924568, -- resets one character's skill ladder (price in Creator Hub)
}

-- Characters saved to Roblox (Studio: right-click the character in
-- ServerStorage/Characters -> Save to Roblox), name -> model asset id. The
-- Lobby shows these in 3D; the Party House uses them for any character not
-- imported there. 0 = not saved yet.
Config.CHARACTER_ASSETS = {
	Glow = 74307875851069,
	Patch = 120375206872909,
	Muscle = 95343724720766, -- 7 Oct: clean shoes (was 116831403539618)
	Tinker = 115806881502179,
	Shadow = 85123632229176,
	Brainy = 96432127418740,
	Echo = 102616480883822, -- 7 Oct: remade face (was 121427930738516)
	Bramble = 83770262810721,
	Host = 135742994182895,
	HostGummy = 106903651525041,
	HostRobot = 95188395596101,
	HostCaretaker = 97512217825851, -- 8 Oct
	HostClownBear = 139812870283621, -- 8 Oct
	HostAnglerfish = 100510711229549, -- 8 Oct
	-- skins (Config.SKINS: the model names)
	TinkerPumpkin = 107525785066601,
	ShadowGhost = 126072588049013,
	BrambleAutumn = 90429061895312,
	PatchHalloween = 80329522710291,
	EchoStar = 78905373095211, -- 8 Oct: remade face (was 78330257038104)
	BrainySpace = 110376512028941,
	GlowCandy = 99155956475141,
	MuscleSnow = 109339323825822,
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
-- map screen pictures (Lobby): buildings and floors
Config.MAP_IMAGES = {
	["building-partyhouse"] = 90366125862515,
	["building-gummy"] = 117537443847515,
	["building-hospital"] = 92023239477557,
	partyhouse = 72796482527577, -- Ground
	partyhouse_2 = 74153444335342, -- Bedrooms
	partyhouse_3 = 96483386228074, -- Attic
	gummy = 106384940484821, -- Bounce Hall
	gummy_2 = 85279894455333, -- Candy Factory
	gummy_3 = 113575969259861, -- Jelly Vault
	hospital = 92023239477557,
	hospital_2 = 93751751639136, -- Wards
	hospital_3 = 70614819830022, -- Labs
	["building-school"] = 108429364285668,
	school = 86527371561332, -- Ground Floor
	school_2 = 83786060551446, -- Classrooms
	school_3 = 111098812594935, -- Clock Tower
	["building-carnival"] = 116987880187331,
	carnival = 139473943447483, -- The Midway
	carnival_2 = 128885533879458, -- The Big Top
	carnival_3 = 102152843956658, -- The Funhouse
	["building-aquarium"] = 112735362765924,
	aquarium = 91974787928356, -- Main Hall
	aquarium_2 = 75069384210834, -- Deep Sea
	aquarium_3 = 111966719661004, -- Rooftop Pools
	partyhouse_b = 103210033418692, -- the Secret Basement (remade 8 Oct: no bottles)
}
-- character portraits (face with a skill badge) by skill id
Config.PORTRAITS = {
	tinker = 91349731911904,
	shadow = 102479346958097,
	patch = 81417443811968,
	muscle = 124426472579046,
	glow = 74862458851440,
	echo = 78989824967295,
	bramble = 127007527181153,
	brainy = 123589958200522,
}
-- the same portraits uploaded for the Party House place
Config.PORTRAITS_GAME = {
	tinker = 81932514363214,
	shadow = 105545933114977,
	patch = 86747214933789,
	muscle = 110255384055800,
	glow = 100607581544171,
	echo = 73829813302256,
	bramble = 79169071934599,
	brainy = 96437377458580,
}
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
-- (x across from the middle, y up from the ground) as parts of the house's
-- width and height. Re-measured 7 Oct: faces showed about a third too high
-- (the model's box is taller than the house you see), so y is scaled down.
-- Each face is put on the house's own front, found by a ray.
Config.LOBBY_HOUSE_WINDOWS = { { -0.2, 0.53 }, { 0.07, 0.51 }, { 0.3, 0.52 }, { -0.28, 0.27 }, { 0.29, 0.27 } }
-- studs the Lobby house comes forward towards the lawn
Config.LOBBY_HOUSE_FORWARD = 6
-- the owner's 🪟 Windows button in the Lobby (set the window faces by
-- clicking); off once they are saved - turn on to set them again
Config.WINDOW_SETUP = false
-- studs the Lobby house sits down into the ground, and degrees its front tips
-- down (the model's front stood lifted, 7 Oct)
Config.LOBBY_HOUSE_SINK = 1
Config.LOBBY_HOUSE_TILT = 5
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

-- play with a friend: +10% of the points from a game when a Roblox friend
-- plays it with you
Config.FRIEND_BONUS = 0.1
-- ladder upgrades that show one colour of the code at the start: one colour a
-- game however many players have one; on Nightmare too only if this is true
Config.CODE_COLOUR_ON_NIGHTMARE = false
-- Tower Run: one game climbs every floor of a building. timeMult: the climb's
-- one timer is this many times a floor's; bonus: extra points (a share of
-- everything earned) for reaching the top; grace: seconds before the host
-- comes out on the floors after the first
Config.TOWER = { timeMult = 2.5, bonus = 0.25, grace = 8 }
-- Studio Play as a Tower Run (from floor 1 of STUDIO_MAP's building)
Config.STUDIO_TOWER = false
-- the chocolate river: wading slows kids (and the host); the bridge does not
Config.WADE = { kid = 0.5, host = 0.6 }
-- the laundry chute: a one-way slide from the Laundry / Linen Room to a far
-- room on the same side of the locked doors (seconds in the chute)
Config.CHUTE = { seconds = 1.2, reuse = 6 }
-- the Jelly Vault's vault door: hold E on the wheel, then a treasure inside
-- gives everyone points and the team a free clue
Config.VAULT = { hold = 4, points = { 25, 50 } }
-- windows with a moonlit view on the outer walls (at most this many a room)
Config.WINDOWS = { perRoom = 2 }
-- a player who drops out of a game can rejoin it from the Lobby for this long
Config.REJOIN_SECONDS = 600
-- daily quests: 3 a day from this list, points paid when done.
-- kind = what the game counts; goal = how many; points = the reward
Config.QUESTS = {
	{ id = "escape2", kind = "escape", goal = 2, points = 60, text = "Escape 2 floors" },
	{ id = "escapeHard", kind = "escapeHard", goal = 1, points = 80, text = "Escape on Hard or Nightmare" },
	{ id = "rescue", kind = "rescue", goal = 1, points = 50, text = "Free a friend from the cage" },
	{ id = "keys3", kind = "key", goal = 3, points = 40, text = "Find 3 keys or Confetti Cannons" },
	{ id = "balloons5", kind = "balloon", goal = 5, points = 40, text = "Pop 5 real clue balloons" },
	{ id = "search10", kind = "search", goal = 10, points = 30, text = "Search 10 drawers, boxes or coats" },
	{ id = "games3", kind = "play", goal = 3, points = 40, text = "Play 3 games" },
	{ id = "skill5", kind = "skill", goal = 5, points = 40, text = "Use your character's skill 5 times" },
	{ id = "hide3", kind = "hide", goal = 3, points = 30, text = "Hide 3 times" },
	{ id = "vents3", kind = "vent", goal = 3, points = 30, text = "Crawl through 3 vents" },
	{ id = "door", kind = "door", goal = 1, points = 40, text = "Open the big exit door" },
	{ id = "present", kind = "present", goal = 1, points = 40, text = "Open a bonus present" },
}
-- weekly quests: 3 a week (from Monday), bigger goals, more points and a
-- boost (into the player's bag) for each one finished
Config.WEEKLY_QUESTS = {
	{ id = "w_escape8", kind = "escape", goal = 8, points = 250, boost = "freeze", text = "Escape 8 floors" },
	{ id = "w_nightmare5", kind = "escapeNightmare", goal = 5, points = 400, boost = "freeze", text = "Escape on Nightmare 5 times" },
	{ id = "w_rescue7", kind = "rescue", goal = 7, points = 260, boost = "shield", text = "Free 7 friends from the cage" },
	{ id = "w_keys12", kind = "key", goal = 12, points = 180, boost = "clue", text = "Find 12 keys or Confetti Cannons" },
	{ id = "w_balloons20", kind = "balloon", goal = 20, points = 180, boost = "candy", text = "Pop 20 real clue balloons" },
	{ id = "w_games15", kind = "play", goal = 15, points = 200, boost = "energy", text = "Play 15 games" },
	{ id = "w_skill30", kind = "skill", goal = 30, points = 180, boost = "candy", text = "Use your character's skill 30 times" },
	{ id = "w_door9", kind = "door", goal = 9, points = 250, boost = "headstart", text = "Open the big exit door 9 times" },
	{ id = "w_present7", kind = "present", goal = 7, points = 280, boost = "clue", text = "Open 7 bonus presents" },
	{ id = "w_vents15", kind = "vent", goal = 15, points = 150, boost = "energy", text = "Crawl through 15 vents" },
}
-- "Your daily reward is ready" (Roblox experience notifications; players 13+
-- who said yes). messageId: the notification string's asset id from Creator
-- Hub -> Engagement -> Notifications (0 = off). secret: the name of the
-- Creator Hub secret that holds the Open Cloud API key. hours: how long
-- after a daily reward is claimed the reminder is sent.
Config.NOTIFY = { messageId = "148e62f6-efd3-e349-bd48-3614612744c7", secret = "notifications", hours = 22 }
-- character skins for Robux (each one a Game Pass; 0 = not on sale yet, so
-- not shown). model = the model's name in Party House
-- ServerStorage/Characters (or in CHARACTER_ASSETS once saved to Roblox).
Config.SKINS = {
	{ id = "tinker_pumpkin", skill = "tinker", name = "Pumpkin Patch Tinker", model = "TinkerPumpkin", pass = 2019380267 },
	{ id = "shadow_ghost", skill = "shadow", name = "Ghostly Shadow", model = "ShadowGhost", pass = 2019074273 },
	{ id = "glow_candy", skill = "glow", name = "Candy Glow", model = "GlowCandy", pass = 2019554271 },
	{ id = "patch_halloween", skill = "patch", name = "Halloween Nurse Patch", model = "PatchHalloween", pass = 2019356268 },
	{ id = "brainy_space", skill = "brainy", name = "Space Cadet Brainy", model = "BrainySpace", pass = 2019890265 },
	{ id = "muscle_snow", skill = "muscle", name = "Snow Day Muscle", model = "MuscleSnow", pass = 2018270268 },
	{ id = "echo_star", skill = "echo", name = "Starlight Echo", model = "EchoStar", pass = 2017922280 },
	{ id = "bramble_autumn", skill = "bramble", name = "Autumn Leaf Bramble", model = "BrambleAutumn", pass = 2018084266 },
}
-- the owner can try every skin in Studio without buying it
Config.SKINS_FREE_IN_STUDIO = true
-- the experience's owner can wear every skin in the live game too (owning a
-- game does not count as owning its Game Passes)
Config.SKINS_FREE_FOR_OWNER = true

return Config
