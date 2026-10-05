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
	{ id = "tinker", name = "Tinker", say = "Picks locks", color = Color3.fromRGB(242, 140, 40) },
	{ id = "shadow", name = "Shadow", say = "Sneaks unseen", color = Color3.fromRGB(138, 107, 209) },
	{ id = "brainy", name = "Brainy", say = "Cracks codes", color = Color3.fromRGB(79, 179, 232) },
	{ id = "muscle", name = "Muscle", say = "Shoves heavy things", color = Color3.fromRGB(232, 80, 91) },
	{ id = "glow", name = "Glow", say = "Lights up secrets", color = Color3.fromRGB(184, 224, 90) },
	{ id = "patch", name = "Patch", say = "Heals and rescues", color = Color3.fromRGB(255, 179, 199) },
	{ id = "echo", name = "Echo", say = "Throws a noise", color = Color3.fromRGB(255, 210, 63) },
	{ id = "bramble", name = "Bramble", say = "Talks to plants", color = Color3.fromRGB(143, 209, 106) },
}

Config.COOLDOWN = { shadow = 20, patch = 30, echo = 25 }

Config.PHRASES = {
	"Over here!", "I found something!", "Hide!", "Run!", "Use your skill!", "Help me!",
	"Nice one!", "The door is open!", "Pop the balloons!", "It is coming!", "Ha ha ha!", "I want cake!",
}

-- filled in after uploading: { title = "rbxassetid://...", scare = "rbxassetid://...", ... }
Config.IMAGES = {}
Config.SOUNDS = {}

return Config
