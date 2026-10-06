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
	easy = { name = "Easy", grace = 30, timer = 480, hunt = 10, sight = 26, catch = 4, clues = 5, bonus = 1 },
	normal = { name = "Normal", grace = 20, timer = 360, hunt = 12, sight = 32, catch = 4.5, clues = 3, bonus = 1.5 },
	hard = { name = "Hard", grace = 12, timer = 270, hunt = 14, sight = 40, catch = 5, clues = 2, bonus = 2 },
	nightmare = { name = "Nightmare", grace = 6, timer = 210, hunt = 16, sight = 48, catch = 5.5, clues = 1, bonus = 3 },
}

Config.CLUE_COST = 30
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
	{ id = "patch", name = "Patch", icon = "\u{1F497}", say = "Heals and rescues", color = Color3.fromRGB(255, 179, 199) },
	{ id = "echo", name = "Echo", icon = "\u{1F3A7}", say = "Throws a noise", color = Color3.fromRGB(255, 210, 63) },
	{ id = "bramble", name = "Bramble", icon = "\u{1F33F}", say = "Talks to plants", color = Color3.fromRGB(143, 209, 106) },
}

Config.COOLDOWN = { shadow = 20, patch = 30, echo = 25 }

-- what each skill does, and how you use it, for the character select screen
Config.SKILL_INFO = {
	tinker = { about = "Picks the lock on the big door, so the team can escape without the colour code.", how = "Walk up to the keypad and hold F." },
	shadow = { about = "Sneaks: for a few seconds the host can't see or grab Shadow. Shadow is also harder to spot than anyone.", how = "Press the Sneak button. It recharges." },
	brainy = { about = "Reads the twisty party invitation and cracks the whole door code. Clues cost Brainy half as much energy.", how = "Find the invitation in the Parlour and press E." },
	muscle = { about = "Shoves the heavy cabinet in the Game Room aside, opening a secret way out.", how = "Hold E at the cabinet." },
	glow = { about = "Carries a glowing light that brightens dark rooms, and lights up secret paint that shows the door code.", how = "Press E at the painted wall in the Library." },
	patch = { about = "Heals everyone nearby with energy and stamina, and frees every caged friend at once.", how = "Press the Heal button. Hold E at the cage." },
	echo = { about = "Hears the host coming from further away, and throws a noise that sends the host to look somewhere else.", how = "Press Noise, then tap where to throw it." },
	bramble = { about = "Talks to plants: the big plant in the Library whispers the door code to Bramble.", how = "Press E at the plant." },
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
Config.VOTE_SECONDS = 10
Config.MAX_PARTY = 6

-- Robux prices for boosts: the Developer Product id for each boost, created in
-- Creator Hub -> Escape Crew -> Monetization -> Developer Products. 0 = not on
-- sale for Robux (points only). Every boost can always be bought with points.
Config.ROBUX_PRODUCTS = {
	candy = 0,
	shield = 0,
	clue = 0,
	energy = 0,
	headstart = 0,
}

-- Boost pictures: the Image asset id of each uploaded boost icon
-- (art/roblox-store/boost-*-512.png). 0 = show the emoji instead.
Config.BOOST_IMAGES = {
	candy = 129315639528838,
	shield = 118951370092761,
	clue = 101410393070554,
	energy = 86003322408140,
	headstart = 129479504189534,
}

-- filled in after uploading: { title = "rbxassetid://...", scare = "rbxassetid://...", ... }
Config.IMAGES = {}
Config.SOUNDS = {}

return Config
