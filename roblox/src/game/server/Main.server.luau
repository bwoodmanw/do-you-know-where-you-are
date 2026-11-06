--[[
	Main - the referee for one server (up to 6 players). Builds the house,
	runs a round, wires every prompt, checks every request from players,
	and decides win or lose. Players only ask; the server decides.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

-- the Party House code synced into the Lobby by mistake: say so and stop
if game.PlaceId == Config.PLACE_IDS.lobby then
	warn("WRONG PLACE: this is the Party House code, but this is the Escape Crew (Lobby) place. In Rojo, connect the Lobby to port 34873 (lobby.project.json). Not publishing this is fine - nothing was lost.")
	return
end
local Plans = require(ReplicatedStorage.Shared.HouseMap)
local MapGen = require(ReplicatedStorage.Shared.MapGen)
local HttpService = game:GetService("HttpService")
-- this game's house: a floor plan with everything placed at random, remade
-- at the start of every game
local HouseMap = MapGen.make(Plans.partyhouse[1])
local House = require(script.Parent.House)
local Host = require(script.Parent.Host)
local Effects = require(script.Parent.Effects)
local Plushies = require(ReplicatedStorage.Shared.Plushies)
local Shapes = require(ReplicatedStorage.Shared.Shapes) -- stretched balls need a sphere mesh
local Seasons = require(ReplicatedStorage.Shared.Seasons) -- the yearly events (Config.SEASONS)
local FeastMeter = require(ReplicatedStorage.Shared.FeastMeter) -- Thanksgiving's community goal
local Characters = require(script.Parent.Characters)
local Props = require(script.Parent.Props)

-- Players' screens can't see ServerStorage: copy the imported characters to
-- ReplicatedStorage.Previews (anchored, no scripts) for the select screen.
do
	local previews = Instance.new("Folder")
	previews.Name = "Previews"
	previews.Parent = ReplicatedStorage
	local src = game:GetService("ServerStorage"):FindFirstChild("Characters")
	if src then
		for _, c in ipairs(src:GetChildren()) do
			if c:IsA("Model") and string.sub(string.lower(c.Name), 1, 4) ~= "host" then
				local m = c:Clone()
				-- named as on the select screen whatever its capitals ("muscle" -> "Muscle")
				for _, sk in ipairs(Config.SKILLS) do
					if string.lower(sk.name) == string.lower(c.Name) then
						m.Name = sk.name
					end
				end
				for _, d in ipairs(m:GetDescendants()) do
					if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
						d:Destroy()
					elseif d:IsA("BasePart") then
						d.Anchored = true
					end
				end
				m.Parent = previews
			end
		end
	end
	-- characters saved to Roblox fill in any not imported here
	local ServerStorage = game:GetService("ServerStorage")
	local chars = ServerStorage:FindFirstChild("Characters")
	if not chars then
		chars = Instance.new("Folder")
		chars.Name = "Characters"
		chars.Parent = ServerStorage
	end
	require(ReplicatedStorage.Shared.CharacterAssets).fill(previews, chars)
end
local Places = require(ReplicatedStorage.Shared.Places)
local TeleportService = game:GetService("TeleportService")

local T = Config.TILE
local at = House.at

-- ---------- remotes and shared round state ----------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local function remote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local Notify = remote("Notify") -- server -> clients: (kind, text, data)
local OpenKeypad = remote("OpenKeypad") -- server -> one client
local Press = remote("Press") -- client -> server: colour
local PickSkill = remote("PickSkill") -- client -> server: skill id
local ReadyUp = remote("Ready") -- client -> server: pressed Play on the character screen
local UseSkill = remote("UseSkill") -- client -> server: optional position (Echo)
local RingBells = remote("RingBells") -- client -> server: Nutmeg's Jingle Bells (level 20), once a game
local GrowHedge = remote("GrowHedge") -- client -> server: Holly's Holly Hedge (level 20), once a game
local UseCopy = remote("UseCopy") -- client -> server: Clone's copied skill (slot 1 / 2, optional position)
local SingEncore = remote("SingEncore") -- client -> server: Harmony's Encore (level 20), once a game
local Jailbreak = remote("Jailbreak") -- client -> server: Patch's Jailbreak (level 20, 5 Nov), once a game
local ElfyPower = remote("ElfyPower") -- client -> server: Elfy's Toy Parade or Workshop Rush (level 20), once a game
local AskClue = remote("AskClue")
local Say = remote("Say") -- client -> server: phrase index
local Bubble = remote("Bubble") -- server -> clients: player, phrase index
local Unhide = remote("Unhide")
local SetSpook = remote("SetSpook")
local Boost = remote("Boost") -- server -> one client: "candy" | "stamina"
local SetDifficulty = remote("SetDifficulty")
local Results = remote("Results") -- server -> clients: the end-of-round summary
local Vote = remote("Vote") -- client -> server: "again" | "lobby"
local UseCandy = remote("UseCandy")
local UseBoost = remote("UseBoost") -- (boostId) tap a boost from the bag
local SetMusic = remote("SetMusic") -- (volume 0..1)
SetMusic.OnServerEvent:Connect(function(plr, v)
	require(ReplicatedStorage.Shared.Profile).setMusic(plr, v)
end)
local SetSfx = remote("SetSfx") -- (game-sound volume 0..1)
SetSfx.OnServerEvent:Connect(function(plr, v)
	require(ReplicatedStorage.Shared.Profile).setSfx(plr, v)
end)
remote("SetPhoto").OnServerEvent:Connect(function(plr, v) -- the escape photo setting
	require(ReplicatedStorage.Shared.Profile).setPhoto(plr, v)
end)
require(ReplicatedStorage.Shared.Sfx).group()

local RoundState = Instance.new("Configuration")
RoundState.Name = "RoundState"
RoundState.Parent = ReplicatedStorage
RoundState:SetAttribute("Spook", "spooky") -- 10 Oct: Spooky by default (Brent)
RoundState:SetAttribute("Difficulty", "normal")

-- the floor above this one in the same building (nil on a top floor)
local function nextFloor()
	local Progress = require(ReplicatedStorage.Shared.Progress)
	local mapId = RoundState:GetAttribute("Map") or "partyhouse"
	local i = Progress.mapIndex(mapId)
	local m = i and Progress.MAPS[i]
	if not m or m.floor < 1 then
		return nil -- the secret Basement: up the cellar steps and out, no floor above
	end
	for _, n in ipairs(Progress.MAPS) do
		if n.building == m.building and n.floor == m.floor + 1 and n.ready then
			return n
		end
	end
	return nil
end

-- realistic night lighting
local Lighting = game:GetService("Lighting")
local function effect(class, props)
	local e = Lighting:FindFirstChildOfClass(class) or Instance.new(class)
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = Lighting
	return e
end
-- a cleaner, more colorful look (Config.LOOK): less haze, richer colors, a
-- soft glow on lights; each building gets its own light and tint (applyLook)
local LOOK = Config.LOOK
effect("Atmosphere", { Density = LOOK.haze.Density, Color = Color3.fromRGB(120, 100, 150), Decay = Color3.fromRGB(40, 30, 60), Glare = 0, Haze = LOOK.haze.Haze })
effect("BloomEffect", LOOK.bloom)
local colorFx = effect("ColorCorrectionEffect", { Saturation = LOOK.saturation, Contrast = LOOK.contrast, Brightness = LOOK.brightness, TintColor = LOOK.themes.party.tint })
local function applyLook(theme, spooky)
	local t = LOOK.themes[theme or "party"] or LOOK.themes.party
	local k = spooky and LOOK.spooky or 1
	Lighting.Ambient = t.ambient:Lerp(Color3.new(0, 0, 0), 1 - k)
	Lighting.OutdoorAmbient = t.outdoor:Lerp(Color3.new(0, 0, 0), 1 - k)
	colorFx.TintColor = t.tint
end
applyLook("party", false)

-- ---------- saved progress (shared with the Lobby) ----------
local Profile = require(ReplicatedStorage.Shared.Profile)
local Unlocks = require(ReplicatedStorage.Shared.Unlocks) -- characters you buy or earn (Nutmeg)
local Progress = require(ReplicatedStorage.Shared.Progress)

local function setupPlayer(plr)
	Profile.load(plr)
	plr:SetAttribute("Energy", 100)
	-- the characters you unlock that are yours (the picker reads it)
	task.spawn(function()
		for _ = 1, 40 do
			if Profile.get(plr) or not plr.Parent then
				break
			end
			task.wait(0.25)
		end
		local owned = {}
		for id, yes in pairs(Unlocks.all(plr)) do
			if yes then
				table.insert(owned, id)
			end
		end
		plr:SetAttribute("Unlocked", table.concat(owned, ","))
	end)
end

-- Tap-to-use boosts brought from the Lobby wait in a bag for the whole visit
-- (Play again keeps them). Whatever is left goes back into the player's
-- saved boosts when they leave, so nothing bought is lost.
local bags = {} -- [userId] = { boostId, ... }
local function paintBag(plr)
	plr:SetAttribute("Bag", table.concat(bags[plr.UserId] or {}, ","))
end
local function returnBag(plr)
	local bag = bags[plr.UserId]
	local data = Profile.get(plr)
	if bag and data then
		for _, id in ipairs(bag) do
			data.inv[id] = (data.inv[id] or 0) + 1
		end
	end
	bags[plr.UserId] = nil
end

-- the party's average character level: each player's chosen character's
-- level (before choosing, their highest)
local function partyLevel()
	local sum, n = 0, 0
	for _, plr in ipairs(Players:GetPlayers()) do
		local pd = Profile.get(plr)
		if pd and pd.xp then
			local skill = plr:GetAttribute("Skill")
			local lvl = 1
			if skill and pd.xp[skill] then
				lvl = Progress.level(pd.xp[skill])
			else
				for _, xp in pairs(pd.xp) do
					lvl = math.max(lvl, Progress.level(xp))
				end
			end
			sum += lvl
			n += 1
		end
	end
	return n > 0 and sum / n or 1
end
-- a difficulty for this party (3 Nov, Brent: Hard / Nightmare too easy for
-- experienced crews): Config.DIFFICULTY plus Config.DIFFICULTY_LEVEL scaled
-- by the party's level - the full step at level 20, none at level 1
local function diffFor(key)
	local base = Config.DIFFICULTY[key] or Config.DIFFICULTY.normal
	local add = Config.DIFFICULTY_LEVEL and Config.DIFFICULTY_LEVEL[key]
	if not add then
		return base
	end
	local f = math.clamp((partyLevel() - 1) / 19, 0, 1)
	local d = table.clone(base)
	d.hunt = base.hunt + (add.hunt or 0) * f
	d.sight = base.sight + (add.sight or 0) * f
	d.timer = math.floor(base.timer + (add.timer or 0) * f + 0.5)
	if base.peek then
		d.peek = base.peek + (add.peek or 0) * f
	end
	return d
end

local function savePlayer(plr)
	returnBag(plr)
	Profile.release(plr)
end

local state = {}
local function addPoints(plr, n, exact)
	if n > 0 and not exact then
		n = math.max(1, math.floor(n * Config.POINT_SCALE + 0.5))
	end
	Profile.addPoints(plr, n)
	if state.earned then
		state.earned[plr.UserId] = (state.earned[plr.UserId] or 0) + n
		plr:SetAttribute("GameEarned", state.earned[plr.UserId])
	end
end

-- The upgrades the player's current character has picked on the skill
-- ladder, put on the player as attributes the game and their screen read.
local function applyMods(plr)
	local data = Profile.get(plr)
	local skill = plr:GetAttribute("Skill")
	local m = Progress.mods(skill, data and data.picks[skill], data and data.xp[skill] or 0)
	-- 17 Oct (Brent): on Nightmare the ladder's run / stamina / hold / cooldown
	-- bonuses count half (a level-20 kid escaped with minutes to spare)
	local dd = Config.DIFFICULTY[(state and state.diff) or RoundState:GetAttribute("Difficulty") or "normal"]
	if dd and dd.ladderHalf then
		for _, k in ipairs({ "staminaMult", "runMult", "holdMult", "cooldownMult" }) do
			m[k] = 1 + (m[k] - 1) * 0.5
		end
	end
	plr:SetAttribute("StaminaMult", m.staminaMult)
	plr:SetAttribute("RunMult", m.runMult)
	plr:SetAttribute("SightMult", m.sightMult)
	-- Patch frees caged friends (and holds everything) twice as fast
	plr:SetAttribute("HoldMult", m.holdMult * (skill == "patch" and 0.5 or 1))
	plr:SetAttribute("CooldownMult", m.cooldownMult)
	-- ladder steps (Progress.ADDS) are added to each base value
	plr:SetAttribute("SneakTime", 6 + (m.sneakTime or 0))
	plr:SetAttribute("GlowRange", 24 + (m.glowRange or 0))
	plr:SetAttribute("HealAmount", m.healAmount or 40)
	plr:SetAttribute("HealShield", m.healShield == true)
	plr:SetAttribute("EchoRange", 70 + (m.echoRange or 0))
	plr:SetAttribute("BarricadeHold", Config.BARRICADE.hold + (m.barricadeHold or 0))
	-- skills version 2: the level-10 / level-20 powers and the new buttons' numbers
	plr:SetAttribute("Power10", m.p10 or "")
	plr:SetAttribute("Power20", m.p20 or "")
	plr:SetAttribute("BurstMult", Config.ECHO_BURST.mult + (m.burstMult or 0))
	plr:SetAttribute("BurstTime", Config.ECHO_BURST.seconds + (m.burstTime or 0))
	plr:SetAttribute("FlareRange", Config.GLOW_FLARE.range + (m.flareRange or 0))
	plr:SetAttribute("FlareStamina", Config.GLOW_FLARE.stamina + (m.flareStamina or 0))
	plr:SetAttribute("FlareTime", Config.GLOW_FLARE.seconds + (m.flareTime or 0))
	plr:SetAttribute("VineTime", Config.VINES.seconds + (m.vineTime or 0))
	plr:SetAttribute("CloneTime", Config.CLONE.seconds + (m.cloneTime or 0))
	plr:SetAttribute("ThinkTime", Config.THINK_SECONDS + (m.thinkTime or 0))
	-- Nutmeg (3 Nov): how far Good Nose reaches, how long a dash lasts, how far it pulls a friend
	plr:SetAttribute("NoseRange", Config.NUTMEG.nose + (m.noseRange or 0))
	plr:SetAttribute("DashTime", Config.NUTMEG.dash + (m.dashTime or 0))
	plr:SetAttribute("PullRange", Config.NUTMEG.pull + (m.pullRange or 0))
	-- Cloud (4 Nov): her fog's size (fogSize = studs wider) and time, her Float Up hold
	plr:SetAttribute("FogRadius", Config.CLOUD.radius + (m.fogSize or 0) / 2)
	plr:SetAttribute("FogTime", Config.CLOUD.fog + (m.fogTime or 0))
	plr:SetAttribute("FloatMult", m.floatMult or 1)
	plr:SetAttribute("FogBankUsed", false)
	-- Holly (4 Nov): how long her peppermints stay, how wide (round), how long he slips
	plr:SetAttribute("PatchTime", Config.HOLLY.patch + (m.patchTime or 0))
	plr:SetAttribute("PatchRadius", (m.p20 == "candystorm" and Config.HOLLY.stormRadius or Config.HOLLY.radius) + (m.patchSize or 0))
	plr:SetAttribute("SlipTime", m.slipTime or 0)
	-- Clone (4 Nov): Look-alike's hesitation, Copycat's reach; no copies yet
	plr:SetAttribute("LookAlike", Config.CLONE_COPY.lookAlike + (m.lookAlike or 0))
	plr:SetAttribute("CopyReach", Config.CLONE_COPY.reach + (m.copyReach or 0))
	-- Harmony (4 Nov): how long and how far her Lullaby
	plr:SetAttribute("LullabyTime", Config.HARMONY.seconds + (m.lullabyTime or 0))
	plr:SetAttribute("LullabyRange", Config.HARMONY.range + (m.lullabyRange or 0))
	plr:SetAttribute("LullabyRun", Config.HARMONY.runTime + (m.lullabyRun or 0)) -- (5 Nov) the speed burst
	if skill ~= "clone" then
		plr:SetAttribute("Copy1", nil)
		plr:SetAttribute("Copy2", nil)
	end
	-- Muscle's Iron Lungs: stamina refills twice as fast
	plr:SetAttribute("RegenMult", m.p10 == "ironlungs" and Config.IRON_LUNGS_REGEN or 1)
	plr:SetAttribute("ToolkitReady", false)
	plr:SetAttribute("RunBonus", 1)
	return m
end

-- ---------- the round ----------
local round = {}
-- Tower Run: what carries from one floor to the next (set between floors)
local towerCarry = nil
local world, host
-- Claus Manor's top floor (5 Nov): a second host runs alongside the first;
-- steppingHost is whichever host is thinking right now (its catches and the
-- traps it steps in are its own)
local host2, steppingHost = nil, nil
-- a noise: every host hears it
local function alertHosts(pos)
	if host then
		host:alert(pos)
	end
	if host2 and host2.model then
		host2:alert(pos)
	end
end
-- (5 Nov) the hosts that are out, the one nearest a spot, and the nearest
-- within reach of it: a kid's skill works on whichever Claus it's used on
local function liveHosts()
	local out = {}
	for _, h in ipairs({ host, host2 }) do
		if h and h.model and h.root then
			table.insert(out, h)
		end
	end
	return out
end
local function nearestHost(pos)
	local best, bestD = host, math.huge
	for _, h in ipairs(liveHosts()) do
		local d = (h.root.Position - pos).Magnitude
		if d < bestD then
			best, bestD = h, d
		end
	end
	return best
end
local function hostNear(pos, reach)
	local h = nearestHost(pos)
	return h and h.root and (h.root.Position - pos).Magnitude < reach and h or nil
end
local hostTimer = nil

local function say(kind, text, data, toPlayer)
	if toPlayer then
		Notify:FireClient(toPlayer, kind, text, data)
	else
		Notify:FireAllClients(kind, text, data)
	end
end

-- daily quests: count something this player did; a finished quest pays at once
local Quests = require(ReplicatedStorage.Shared.Quests)
local function quest(plr, kind, n)
	local data = Profile.get(plr)
	if not data then
		return
	end
	for _, d in ipairs(Quests.bump(data, plr.UserId, kind, n)) do
		local b = d.boost and Progress.BOOSTS[d.boost]
		say("quest", "\u{1F4DC} " .. (d.weekly and "Weekly quest" or "Quest") .. " done: " .. d.text .. "! +" .. d.points .. " points" .. (b and (" and a " .. b.icon .. " " .. b.name) or ""),
			{ userId = plr.UserId, points = d.points }, plr)
	end
	Profile.publish(plr)
end

-- play with a friend: a Roblox friend in this game gives +10% points
local friendPair = {}
local function friends(a, b)
	local key = math.min(a.UserId, b.UserId) .. ":" .. math.max(a.UserId, b.UserId)
	if friendPair[key] == nil then
		local ok, yes = pcall(function()
			return a:IsFriendsWith(b.UserId)
		end)
		friendPair[key] = ok and yes == true
	end
	return friendPair[key]
end
local function paintFriends()
	local list = Players:GetPlayers()
	for _, p in ipairs(list) do
		local any = false
		for _, q in ipairs(list) do
			if q ~= p and friends(p, q) then
				any = true
			end
		end
		p:SetAttribute("FriendBonus", any or nil)
	end
end

-- the model a player's character uses: their chosen skin, if they own it
-- and its model is here, else the character itself
local MarketplaceService = game:GetService("MarketplaceService")
local passCache = {}
local function ownsSkin(plr, skin)
	if RunService:IsStudio() and Config.SKINS_FREE_IN_STUDIO then
		return true
	end
	if Config.SKINS_FREE_FOR_OWNER and game.CreatorType == Enum.CreatorType.User and plr.UserId == game.CreatorId then
		return true
	end
	-- a skin bought in a season's shop, or given by the owner (3 Nov: any
	-- skin, Game Pass ones too): yours for good; a Game Pass one is yours
	-- either way
	do
		local d = Profile.get(plr)
		if d ~= nil and d.skinsEarned ~= nil and d.skinsEarned[skin.id] == true then
			return true
		end
	end
	if not skin.pass or skin.pass <= 0 then
		return false
	end
	local key = plr.UserId .. ":" .. skin.pass
	if passCache[key] == nil then
		local ok, yes = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, skin.pass)
		end)
		if not ok then
			return false
		end
		passCache[key] = yes == true
	end
	return passCache[key]
end
local triedWarned = {} -- a broken test model is reported once
-- Studio (and the owner live): a remade test model for a character or a
-- skin (Config.STUDIO_TRY_MODEL, by model name), if it is imported and sound;
-- otherwise the model itself
local function tryModel(plr, name)
	local tester = RunService:IsStudio()
		or (Config.TRY_MODEL_FOR_OWNER and game.CreatorType == Enum.CreatorType.User and plr.UserId == game.CreatorId)
	local try = tester and Config.STUDIO_TRY_MODEL and Config.STUDIO_TRY_MODEL[name]
	if try and not Characters.has(try) and not triedWarned[try] then
		-- say so once, with what is there (a name typed a little differently?)
		triedWarned[try] = true
		print("[Characters] Test model " .. try .. " is not in ServerStorage/Characters yet, so the old " .. name
			.. " plays. Characters has: " .. Characters.list())
	end
	if try and Characters.has(try) then
		local problem = Characters.broken[try] and "it died as soon as it went on (see the [Characters] line above)" or Characters.problem(try)
		if not problem then
			return try
		end
		if not triedWarned[try] then
			triedWarned[try] = true
			warn("Test model " .. try .. " not used - " .. problem .. ". Playing the old " .. name .. ".")
		end
	end
	return name
end
local function modelFor(plr, s)
	local data = Profile.get(plr)
	local skinId = data and data.skins and data.skins[s.id]
	if RunService:IsStudio() and Config.STUDIO_NO_SKINS then
		skinId = nil -- Studio: the plain character (Config.STUDIO_NO_SKINS)
	end
	for _, skin in ipairs(Config.SKINS or {}) do
		if skin.id == skinId and skin.skill == s.id and Characters.has(skin.model) and ownsSkin(plr, skin) then
			return tryModel(plr, skin.model)
		end
	end
	return tryModel(plr, s.name)
end

local function hrpOf(plr)
	local c = plr.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function setSpeed(plr, walk)
	local c = plr.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = walk
		hum.JumpPower = walk > 0 and 50 or 0
	end
	plr:SetAttribute("Frozen", walk == 0)
end

local function setVisible(plr, visible)
	local c = plr.Character
	if not c then
		return
	end
	for _, d in ipairs(c:GetDescendants()) do
		if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") then
			d.Transparency = visible and 0 or 1
		end
	end
end

local function teleport(plr, pos)
	local hrp = hrpOf(plr)
	if hrp then
		hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	end
end

local function colourWord(c)
	return string.upper(c) .. " " .. (Config.COLOR_SHAPE[c] or "")
end

-- a name tag over each kid showing their character, until the real
-- character models replace the avatars
local function gear(plr)
	local c = plr.Character
	local head = c and c:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("SkillTag")
	if old then
		old:Destroy()
	end
	local skill
	for _, sk in ipairs(Config.SKILLS) do
		if sk.id == plr:GetAttribute("Skill") then
			skill = sk
		end
	end
	if not skill then
		return
	end
	local tag = Instance.new("BillboardGui")
	tag.Name = "SkillTag"
	tag.PlayerToHideFrom = plr -- everyone else sees it; you know who you are
	tag.Size = UDim2.fromOffset(120, 30)
	tag.StudsOffset = Vector3.new(0, 2.6, 0)
	tag.MaxDistance = 60
	tag.Parent = head
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundColor3 = skill.color
	l.BackgroundTransparency = 0.15
	l.TextColor3 = Color3.fromRGB(26, 16, 38)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = skill.icon .. " " .. skill.name
	l.Parent = tag
	local oldBulb = head:FindFirstChild("GlowBulb")
	if oldBulb then
		oldBulb:Destroy()
	end
	if skill.id == "glow" then
		local bulb = Instance.new("Part")
		bulb.Name = "GlowBulb"
		bulb.Shape = Enum.PartType.Ball
		bulb.Size = Vector3.new(0.45, 0.45, 0.45)
		bulb.Material = Enum.Material.Neon
		bulb.Color = Color3.fromRGB(255, 242, 122)
		bulb.CanCollide, bulb.Massless, bulb.CanQuery = false, true, false
		bulb.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.95, 0)
		bulb.Parent = head
		local stalk = Instance.new("Part")
		stalk.Name = "Stalk"
		stalk.Size = Vector3.new(0.08, head.Size.Y * 0.5, 0.08)
		stalk.Color = Color3.fromRGB(42, 77, 47)
		stalk.CanCollide, stalk.Massless, stalk.CanQuery = false, true, false
		stalk.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.7, 0)
		stalk.Parent = bulb
		for _, p in ipairs({ bulb, stalk }) do
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = head, p
			w.Parent = p
		end
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness, light.Shadows = Color3.fromRGB(255, 242, 160), plr:GetAttribute("GlowRange") or 24, 1.6, true
		light.Parent = bulb
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = l
end

local function playersInRound()
	local list = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and not plr:GetAttribute("Waiting") then
			table.insert(list, plr)
		end
	end
	return list
end

local function checkEnd()
	if state.status ~= "playing" then
		return
	end
	local list = playersInRound()
	if #list == 0 then
		return
	end
	local free, escaped = 0, 0
	for _, plr in ipairs(list) do
		if plr:GetAttribute("Escaped") then
			escaped += 1
		elseif not plr:GetAttribute("Caged") then
			free += 1
		end
	end
	if free > 0 then
		return
	end
	local diff = Config.DIFFICULTY[state.diff] or Config.DIFFICULTY.normal
	local now = workspace:GetServerTimeNow()
	local won = escaped > 0
	if won then
		state.status = "won"
		local winBonus = math.floor(20 * diff.bonus)
		local climbing = RoundState:GetAttribute("Tower") and nextFloor() ~= nil
		local timeBonus = (state.frenzy or climbing) and 0 or math.max(0, math.floor((state.endsAt - now) / 6))
		for _, plr in ipairs(list) do
			addPoints(plr, plr:GetAttribute("Escaped") and (winBonus + timeBonus) or math.floor(winBonus / 2))
		end
		state.timeBonus = timeBonus
		-- Tower Run: a floor cleared and one above: up the stairs together
		if climbing then
			RoundState:SetAttribute("Status", state.status)
			local mapNow = RoundState:GetAttribute("Map") or "partyhouse"
			local up = nextFloor()
			for _, plr in ipairs(list) do
				local pd = Profile.get(plr)
				if pd and plr:GetAttribute("Escaped") then
					quest(plr, "escape")
					pd.cleared = pd.cleared or {}
					pd.cleared[mapNow] = true
					for _, nextMap in ipairs(Progress.unlocksAfter(mapNow)) do
						pd.unlocked[nextMap.id] = true
					end
					Profile.publish(plr)
				end
			end
			towerCarry = { earned = state.earned, endsAt = state.endsAt, startedAt = state.towerStarted or state.startedAt,
				hostKind = host and host.kind, floor = (state.towerFloor or 1) + 1, everCaught = state.everCaught }
			say("escape", "\u{1F5FC} Floor cleared! Up to the " .. (string.match(up.name, ":%s*(.+)$") or up.name) .. " - keep going, the clock is still running!")
			task.delay(4, function()
				RoundState:SetAttribute("Map", up.id)
				round.start()
			end)
			return
		end
	else
		state.status = "lost"
	end
	RoundState:SetAttribute("Status", state.status)
	local rows = {}
	local mapId = RoundState:GetAttribute("Map") or "partyhouse"
	local seconds = math.floor(now - state.startedAt)
	local towerRun = RoundState:GetAttribute("Tower") == true
	if towerRun then
		seconds = math.floor(now - (state.towerStarted or state.startedAt))
		if won then
			for _, plr in ipairs(list) do
				local got = state.earned[plr.UserId] or 0
				if got > 0 then
					addPoints(plr, math.max(1, math.floor(got * Config.TOWER.bonus + 0.5)), true)
				end
			end
		end
	end
	-- playing with a friend: +10% of this game's points
	local friendBonus = {}
	for _, plr in ipairs(list) do
		local got = state.earned[plr.UserId] or 0
		if plr:GetAttribute("FriendBonus") and got > 0 then
			local extra = math.max(1, math.floor(got * (Config.FRIEND_BONUS or 0.1) + 0.5))
			addPoints(plr, extra, true)
			friendBonus[plr.UserId] = extra
		end
	end
	for _, plr in ipairs(list) do
		local earned = state.earned[plr.UserId] or 0
		local skill = plr:GetAttribute("Skill")
		local out = plr:GetAttribute("Escaped") == true and not plr:GetAttribute("Waiting")
		local row = { name = plr.DisplayName, points = earned, escaped = out, skill = skill, userId = plr.UserId, friendBonus = friendBonus[plr.UserId] }
		quest(plr, "play")
		if won and out then
			quest(plr, "escape")
			if state.diff == "hard" or state.diff == "nightmare" then
				quest(plr, "escapeHard")
				if state.diff == "nightmare" then
					quest(plr, "escapeNightmare")
				end
			end
		end
		local pd = Profile.get(plr)
		if pd then
			local before = Progress.level(pd.xp[skill] or 0)
			pd.xp[skill] = (pd.xp[skill] or 0) + earned
			local after = Progress.level(pd.xp[skill])
			if after > before then
				row.levelUp = after
			end
			pd.stats.games += 1
			if out then
				pd.stats.escapes += 1
				row.firstEscape = pd.stats.escapes == 1
				-- 4 Nov: a character earned by escaping (Cloud at 10, ...)
				for cid, cu in pairs(Config.CHARACTER_UNLOCK) do
					if cu.escapes == pd.stats.escapes and not (pd.charsEarned and pd.charsEarned[cid]) then
						local cname = string.upper(string.sub(cid, 1, 1)) .. string.sub(cid, 2)
						local unlockedNow = plr:GetAttribute("Unlocked") or ""
						if not table.find(string.split(unlockedNow, ","), cid) then
							plr:SetAttribute("Unlocked", unlockedNow == "" and cid or (unlockedNow .. "," .. cid))
						end
						task.delay(3, function()
							say("info", "\u{1F389} " .. cname .. " unlocked - " .. plr.DisplayName .. " escaped " .. cu.escapes .. " times! Pick " .. cname .. " in your next game.", nil, plr)
						end)
					end
				end
				local key = mapId .. "_" .. state.diff
				if not towerRun and (not pd.best[key] or seconds < pd.best[key]) then
					pd.best[key] = seconds
				end
			end
			if won and out then
				pd.cleared = pd.cleared or {}
				pd.cleared[mapId] = true
				local names = {}
				for _, nextMap in ipairs(Progress.unlocksAfter(mapId)) do
					if not pd.unlocked[nextMap.id] then
						pd.unlocked[nextMap.id] = true
						table.insert(names, nextMap.name)
					end
				end
				if #names > 0 then
					row.unlocked = table.concat(names, " + ")
				end
			end
			Profile.publish(plr)
			Profile.record(plr, mapId, state.diff, (out and not towerRun) and seconds or nil)
			task.spawn(Profile.save, plr)
		end
		table.insert(rows, row)
	end
	require(ReplicatedStorage.Shared.BalanceLog).record(mapId, state.diff, #list, escaped, seconds, won, partyLevel())
	-- badges (each only if made in Creator Hub: Config.BADGES)
	task.spawn(function()
		local BadgeService = game:GetService("BadgeService")
		local function award(plr, key)
			local id = Config.BADGES[key]
			if id and id > 0 then
				pcall(function()
					BadgeService:AwardBadge(plr.UserId, id)
				end)
			end
		end
		local mi = Progress.mapIndex(mapId)
		local m = mi and Progress.MAPS[mi]
		for _, plr in ipairs(list) do
			local pd = Profile.get(plr)
			local out = plr:GetAttribute("Escaped") == true and not plr:GetAttribute("Waiting")
			if out then
				award(plr, "firstEscape")
				if m and m.season then
					-- a season floor (the Harvest Barn): its badge comes from its hunt
				elseif m and m.secret then
					award(plr, "basement") -- the Secret Basement (not the building's top floor)
				elseif m and not nextFloor() then
					award(plr, m.building)
				end
				if towerRun and won then
					award(plr, "tower") -- the top of a Tower Run
				end
				if not (state.everCaught and state.everCaught[plr.UserId]) then
					award(plr, "untouched")
				end
				if state.diff == "nightmare" then
					award(plr, "nightmare")
				end
				if pd and pd.cleared then
					local all = true
					for _, mm in ipairs(Progress.MAPS) do
						if mm.ready and not mm.secret and Config.ALL_FLOORS_BUILDINGS[mm.building] and not pd.cleared[mm.id] then
							all = false
						end
					end
					if all then
						award(plr, "allFloors")
					end
				end
			end
			if pd and (pd.stats.rescues or 0) >= 10 then
				award(plr, "rescuer")
			end
		end
	end)
	Results:FireAllClients({
		won = won,
		difficulty = diff.name,
		seconds = math.floor(now - state.startedAt),
		timeBonus = state.timeBonus or 0,
		vote = true, -- the countdown: RoundState VoteEnds / VoteMode (round.startVote)
		nextFloor = (won and not towerRun) and (nextFloor() or {}).name or nil,
		floorName = (Progress.MAPS[Progress.mapIndex(mapId) or 0] or {}).name, -- 10 Oct: the title named the Party House everywhere
		tower = towerRun and (state.towerFloor or 1) or nil,
		players = rows,
	})
	round.startVote()
end

local function escape(plr, side)
	if plr:GetAttribute("Escaped") or plr:GetAttribute("Caged") then
		return
	end
	plr:SetAttribute("Escaped", true)
	plr:SetAttribute("Hidden", false)
	teleport(plr, side and world.gardenSpotSide or world.gardenSpot)
	Effects.burst((side and world.gardenSpotSide or world.gardenSpot) + Vector3.new(0, 2, 0), "escape")
	addPoints(plr, 15)
	say("escape", plr.DisplayName .. " made it out!")
	checkEnd()
end

local function openDoor(plr, how)
	if state.doorOpen or (state.roundup and how ~= "turkeys") or (state.presentHunt and how ~= "presents") then
		return
	end
	state.doorOpen = true
	RoundState:SetAttribute("DoorOpen", true)
	Effects.sound(world.objects.door.keypad.Position, "unlock", 1)
	local door = world.objects.door.door
	door.CanCollide = false
	TweenService:Create(door, TweenInfo.new(1.2), { Position = door.Position + Vector3.new(0, 9.5, 0) }):Play()
	world.objects.door.usePrompt.Enabled = false
	-- the Harvest Barn's sign over the doors
	if world.objects.door.exitSign then
		world.objects.door.exitSign.Text = "EXIT"
		world.objects.door.exitSign.TextColor3 = Color3.fromRGB(90, 240, 120)
	end
	addPoints(plr, 25)
	quest(plr, "door")
	say("open", how == "turkeys" and "Every turkey caught! The big barn doors swing open - everybody out!"
		or how == "pick" and ("Click! " .. plr.DisplayName .. " picked the lock! Everybody out!") or "The big door is open! Everybody out!")
end

local function revealAll(plr, by)
	-- 4 Nov: a 4-color code (Hard, Nightmare): the code skills learn 3 of the 4 -
	-- one still unknown stays hidden (a balloon, a clue or Tinker's pick)
	local n = #state.code
	local keep
	if n >= 4 then
		local unknown = {}
		for i = 1, n do
			if not state.known[i] then
				table.insert(unknown, i)
			end
		end
		if #unknown >= 2 then
			keep = unknown[math.random(1, #unknown)]
		end
	end
	for i = 1, n do
		if i ~= keep then
			state.known[i] = state.code[i]
			RoundState:SetAttribute("Known" .. i, state.code[i])
		end
	end
	addPoints(plr, 10)
	local words = {}
	for i = 1, n do
		table.insert(words, state.known[i] and colourWord(state.code[i]) or "?")
	end
	say("reveal", by .. " The code is " .. table.concat(words, ", ") .. "." .. (keep and (" Color " .. keep .. " is still a mystery - find it!") or ""), state.code)
end
-- the whole code known? (3 or 4 colors)
local function codeKnown()
	for i = 1, #(state.code or {}) do
		if not state.known[i] then
			return false
		end
	end
	return true
end

local function need(plr, skill, text)
	say("need", text, { skill = skill }, plr)
end

local function hideSpotCount(id)
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("Hidden") and p:GetAttribute("HideSpot") == id then
			n += 1
		end
	end
	return n
end

local function unhide(plr)
	if not plr:GetAttribute("Hidden") then
		return
	end
	local entry = world.objects[plr:GetAttribute("HideSpot")]
	plr:SetAttribute("Hidden", false)
	plr:SetAttribute("HideSpot", nil)
	local hrp = hrpOf(plr)
	if hrp then
		hrp.Anchored = false
	end
	setVisible(plr, true)
	if entry then
		House.peekHide(entry)
		teleport(plr, entry.outside)
		Effects.sound(entry.outside, "unhide")
	end
end

local function freeFromCage(plr)
	plr:SetAttribute("Caged", false)
	teleport(plr, world.objects.cage.outside)
	setSpeed(plr, Config.WALK)
end

local function anyCaged()
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("Caged") then
			return true
		end
	end
	return false
end

-- nearest walkable tile beside a spot, for stepping out of hiding
local function besideTile(x, y, h)
	local map = HouseMap.map
	for _, d in ipairs({ { 0, 1 }, { 1, 0 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 } }) do
		local nx, ny = x + d[1], y + d[2]
		local row = map[ny + 1]
		if row and string.sub(row, nx + 1, nx + 1) == "." then
			return at(nx, ny, h or 0)
		end
	end
	return at(x, y, 0)
end

local NOTHING = {
	{ "A flutter of bats! Nothing useful.", "bats" },
	{ "Just tissue paper. Nothing here.", "tissue" },
	{ "Confetti everywhere! Nothing else though.", "confetti" },
	{ "Nothing but old socks and tissue paper.", "tissue" },
	{ "Squeak! Bats! Try somewhere else.", "bats" },
}

-- a boost happens: from the bag (tapped) or found in a present / search spot
local function applyBoost(plr, id, seconds)
	if id == "candy" then
		Boost:FireClient(plr, "candy")
	elseif id == "energy" then
		Boost:FireClient(plr, "stamina")
	elseif id == "shield" then
		plr:SetAttribute("Shield", true)
		plr:SetAttribute("SelfShieldAt", nil) -- this one keeps until a grab
	elseif id == "freeze" then
		for _, host in ipairs(liveHosts()) do -- (5 Nov) both Clauses
			host:stun(10)
			RoundState:SetAttribute("FrozenUntil", workspace:GetServerTimeNow() + 10)
			local ice = Instance.new("Highlight")
			ice.FillColor = Color3.fromRGB(140, 220, 255)
			ice.OutlineColor = Color3.new(1, 1, 1)
			ice.FillTransparency = 0.35
			ice.Parent = host.model
			Effects.burst(host.root.Position, "reveal")
			task.delay(10, function()
				ice:Destroy()
			end)
		end
	elseif id == "clue" then
		state.cluesLeft += 1
		state.freeClues = (state.freeClues or 0) + 1
		RoundState:SetAttribute("CluesLeft", state.cluesLeft)
		RoundState:SetAttribute("FreeClues", state.freeClues)
	elseif id == "giftbox" then
		-- Christmas's Gift Box Hideout (3 Nov): hidden in a wrapped present
		-- right where you stand for Config.GIFTBOX.seconds - the host can't see
		-- or grab you; Jump or the Get Out button ends it early. GiftBoxUntil
		-- shows the countdown on your screen
		local hrp = hrpOf(plr)
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if not hrp then
			return
		end
		seconds = seconds or Config.GIFTBOX.seconds -- (5 Nov) Elfy's Wrapped Up: shorter
		local untilT = workspace:GetServerTimeNow() + seconds
		local ground = hrp.Position - Vector3.new(0, (hum and hum.HipHeight or 2) + hrp.Size.Y / 2, 0)
		local box = Instance.new("Model")
		box.Name = "GiftBoxHideout"
		local function piece(props)
			local p = Instance.new("Part")
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.Material = Enum.Material.SmoothPlastic
			for k, v in pairs(props) do
				p[k] = v
			end
			p.Parent = box
			return p
		end
		local RED, GOLD = Color3.fromRGB(210, 35, 45), Color3.fromRGB(255, 205, 70)
		local mid = ground + Vector3.new(0, 2, 0)
		piece({ Name = "Box", Size = Vector3.new(4, 4, 4), Position = mid, Color = RED })
		piece({ Name = "Ribbon", Size = Vector3.new(4.06, 4.06, 0.7), Position = mid, Color = GOLD })
		piece({ Name = "Ribbon", Size = Vector3.new(0.7, 4.06, 4.06), Position = mid, Color = GOLD })
		for _, sx in ipairs({ -1, 1 }) do
			piece({ Name = "Bow", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 0.9, 0.9), Position = ground + Vector3.new(sx * 0.6, 4.4, 0), Color = GOLD })
		end
		box.Parent = world.root
		plr:SetAttribute("Hidden", true)
		plr:SetAttribute("HideSpot", nil)
		plr:SetAttribute("GiftBoxUntil", untilT)
		hrp.Anchored = true
		setVisible(plr, false)
		Effects.burst(mid, "boost", "collect")
		Effects.sound(mid, "hide")
		local conn
		conn = plr:GetAttributeChangedSignal("Hidden"):Connect(function()
			if not plr:GetAttribute("Hidden") then
				conn:Disconnect()
				box:Destroy()
				plr:SetAttribute("GiftBoxUntil", nil)
			end
		end)
		task.delay(seconds, function()
			if plr.Parent and plr:GetAttribute("GiftBoxUntil") == untilT then
				unhide(plr)
			end
		end)
	elseif id == "thermos" then
		-- Christmas's Cocoa Thermos (3 Nov): you and every friend within
		-- Config.THERMOS.reach studs get all your stamina back
		local hrp = hrpOf(plr)
		for _, p in ipairs(Players:GetPlayers()) do
			local h = hrpOf(p)
			if hrp and h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and (h.Position - hrp.Position).Magnitude <= Config.THERMOS.reach then
				Boost:FireClient(p, "stamina")
				if p ~= plr then
					Effects.at(p, "boost", "energy")
					say("info", "\u{2615} " .. plr.DisplayName .. " shared a Cocoa Thermos - all your stamina back!", nil, p)
				end
			end
		end
	end
end

-- this floor's hidden item, found: it works at once (found items never go in
-- the bag - the bag goes back to your saved boosts when you leave)
local FOUND_TEXT = {
	candy = " found Candy Corn - run without getting puffed!",
	shield = " found a Party Shield - it saves you from one grab!",
	energy = " found a Second Wind - all their stamina back!",
	clue = " found an Extra Clue - the team gets a free clue!",
	freeze = " found a Frozen Pop - the host is frozen for 10 seconds!",
}
local function foundLoot(plr, item, pos)
	local b = Progress.BOOSTS[item]
	if not b then
		return
	end
	addPoints(plr, 5)
	Effects.burst(pos, "boost", "collect")
	if item == "candy" then
		Effects.at(plr, "boost", "eat")
	elseif item == "energy" then
		Effects.at(plr, "boost", "energy")
	end
	applyBoost(plr, item)
	say("boost", plr.DisplayName .. (FOUND_TEXT[item] or (" found " .. b.name .. "!")), { icon = b.icon, userId = plr.UserId, item = b.name })
end

-- a locked inner door opens (with its key, or Tinker picks it)
local function openLock(plr, id, how)
	-- a blocked passage has no lock: only Muscle or a Confetti Cannon clears it
	-- (the Skeleton Key marked it open and errored, so Shove and the cannon then
	-- refused it - Conveyor Hall, 10 Oct)
	if world.unlocked[id] or world.objects[id].def.blocked then
		return
	end
	world.unlocked[id] = true
	RoundState:SetAttribute("Lock_" .. id, true)
	local entry = world.objects[id]
	entry.part.CanCollide = false
	entry.unlockPrompt.Enabled = false
	entry.pickPrompt.Enabled = false
	Effects.sound(entry.lockPart.Position, "unlock", 1)
	TweenService:Create(entry.part, TweenInfo.new(1), { Position = entry.part.Position + Vector3.new(0, 13, 0) }):Play()
	entry.lockPart:Destroy()
	if entry.giftPrompt then
		entry.giftPrompt.Enabled = true
	end
	addPoints(plr, 15)
	say("open", (how == "pick" and ("Click! " .. plr.DisplayName .. " picked the lock on the ") or (plr.DisplayName .. " unlocked the ")) .. entry.def.name .. "!")
end

-- the blocked passage clears (Muscle shoved it, or the Confetti Cannon went off)
local function clearBlock(plr, id, how)
	if world.unlocked[id] then
		return
	end
	world.unlocked[id] = true
	RoundState:SetAttribute("Lock_" .. id, true)
	local entry = world.objects[id]
	entry.part.CanCollide = false
	entry.shovePrompt.Enabled = false
	entry.popperPrompt.Enabled = false
	if entry.giftPrompt then
		entry.giftPrompt.Enabled = true
	end
	for _, g in ipairs(entry.part:GetChildren()) do
		if g:IsA("SurfaceGui") then
			g:Destroy()
		end
	end
	for _, p in ipairs(entry.pile) do
		local to = how == "popper" and p.Position + Vector3.new(math.random(-5, 5), 8 + math.random(0, 6), math.random(-5, 5))
			or p.Position - Vector3.new(0, p.Size.Y + 1, 0)
		TweenService:Create(p, TweenInfo.new(how == "popper" and 0.7 or 1.2), { Position = to, Transparency = 1 }):Play()
		game:GetService("Debris"):AddItem(p, 1.5)
	end
	if how == "shove" then
		Effects.sound(entry.part.Position, "shove", 1)
		Effects.burst(entry.part.Position, "shove")
		House.addCrate(world, entry.def.x, entry.def.y)
		addPoints(plr, 25)
		say("open", "Muscle shoved the junk out of the " .. entry.def.name .. "!" .. (entry.def.bonus and " A bonus present inside!" or ""))
	else
		addPoints(plr, 15)
		say("open", "BOOM! The Confetti Cannon blasted open the " .. entry.def.name .. "... and the host heard it!" .. (entry.def.bonus and " A bonus present inside!" or ""))
	end
end

-- a store room's present: points and one surprise for whoever opens it
local function wireStoreRooms()
	for id, entry in pairs(world.objects) do
		if entry.giftPrompt then
			entry.giftPrompt.Triggered:Connect(function(plr)
				if state.status ~= "playing" or entry.giftOpened or not world.unlocked[id] then
					return
				end
				entry.giftOpened = true
				entry.giftPrompt.Enabled = false
				quest(plr, "present")
				local pos = entry.gift.Position
				for _, b in ipairs(entry.giftBits) do
					b:Destroy()
				end
				Effects.surprise(pos, "confetti")
				Effects.burst(pos, "boost")
				for _, p in ipairs(playersInRound()) do
					local n = math.random(20, 60)
					addPoints(p, n, true)
					say("boost", "\u{1F381} Bonus present: +" .. n .. " points for you!", { icon = "\u{1F381}", userId = p.UserId, item = "+" .. n .. " points" }, p)
				end
				local roll = math.random(1, 3)
				local extra = ""
				if roll == 1 then
					state.cluesLeft += 1
					state.freeClues = (state.freeClues or 0) + 1
					RoundState:SetAttribute("CluesLeft", state.cluesLeft)
					RoundState:SetAttribute("FreeClues", state.freeClues)
					extra = " And a free clue for the team!"
				elseif roll == 2 then
					plr:SetAttribute("Shield", true)
					plr:SetAttribute("SelfShieldAt", nil)
					extra = " And a Party Shield for " .. plr.DisplayName .. "!"
				end
				say("info", plr.DisplayName .. " opened a bonus present - points for everyone!" .. extra)
			end)
		end
	end
end

-- Muscle's Barricade: the nearest crate slides into its doorway. Kids walk
-- through it; the host has to smash through (stuck for BarricadeHold s).
local function barricade(plr, c)
	c.busy = true
	if c.prompt then
		c.prompt.Enabled = false
	end
	Effects.sound(c.part.Position, "shove", 1)
	TweenService:Create(c.part, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { CFrame = c.door }):Play()
	say("info", plr.DisplayName .. " shoved a crate into the doorway - the host can't get through!")
	local hold = plr:GetAttribute("BarricadeHold") or Config.BARRICADE.hold
	local myWorld = world
	task.spawn(function()
		local stopAt = os.clock() + Config.BARRICADE.stands
		while os.clock() < stopAt and world == myWorld and state.status == "playing" do
			local host = nearestHost(c.door.Position) -- (5 Nov) the Claus at the door
			if host and host.model and host.root and (host.root.Position - c.door.Position).Magnitude < 7 then
				host:stun(hold)
				say("info", "CRASH! The host is smashing through Muscle's barricade!")
				for _ = 1, math.max(1, math.floor(hold)) do
					Effects.sound(c.door.Position, "shove", 1.2)
					task.wait(1)
				end
				break
			end
			task.wait(0.1)
		end
		if world ~= myWorld or not c.part.Parent then
			return
		end
		TweenService:Create(c.part, TweenInfo.new(0.6), { CFrame = c.home }):Play()
		task.wait(0.6)
		c.busy = false
		if c.prompt then
			c.prompt.Enabled = true
		end
	end)
end

local function wirePrompts()
	local o = world.objects
	for id, entry in pairs(o) do
		local def = entry.def
		if def.kind == "balloon" then
			entry.prompt.Triggered:Connect(function(plr)
				if state.status ~= "playing" or entry.popped then
					return
				end
				entry.popped = true
				entry.prompt.Enabled = false
				if def.decoy then
					entry.part.Transparency = 1
					entry.label.Text = ""
					Effects.burst(entry.part.Position, "pop")
					say("pop", "POP! Just air - that balloon was a trick. And it was LOUD...", nil, plr)
					if host then
						alertHosts(entry.part.Position)
					end
					return
				end
				local col = state.code[def.n]
				state.known[def.n] = col
				RoundState:SetAttribute("Known" .. def.n, col)
				entry.part.Color = Config.COLOR3[col]
				entry.part.Material = Enum.Material.Neon
				entry.part.Size = Vector3.new(1.4, 1.4, 1.4)
				entry.part.Position = at(def.x, def.y, 0.8)
				entry.label.TextColor3 = Color3.new(1, 1, 1)
				entry.label.Text = def.n .. " " .. (Config.COLOR_SHAPE[col] or "")
				addPoints(plr, 5)
				quest(plr, "balloon")
				Effects.burst(entry.part.Position + Vector3.new(0, 4, 0), "pop")
				say("pop", "Balloon " .. def.n .. " was " .. colourWord(col) .. "! That was LOUD...", { n = def.n, color = col, icon = Config.ITEM_ICONS.balloon, userId = plr.UserId })
				if host then
					alertHosts(entry.part.Position)
				end
			end)
		elseif def.kind == "present" then
			entry.prompt.Triggered:Connect(function(plr)
				if entry.opened then
					return
				end
				entry.opened = true
				entry.prompt.Enabled = false
				House.openObject(entry)
				local item = world.lootIn and world.lootIn[id]
				if not item then
					Effects.sound(entry.part.Position, "hide")
					Effects.surprise(entry.part.Position, "tissue")
					return say("info", "Empty! Just tissue paper.", nil, plr)
				end
				foundLoot(plr, item, entry.part.Position)
			end)
		elseif def.kind == "invite" then
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Skill") ~= "brainy" then
					return need(plr, "brainy", "Twisty writing... Brainy could read this!")
				end
				entry.prompt.Enabled = false
				Effects.burst(entry.part.Position, "reveal")
				revealAll(plr, "Brainy cracked the invitation!")
				quest(plr, "skill")
			end)
		elseif def.kind == "uv" then
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Skill") ~= "glow" then
					return need(plr, "glow", "Something is painted here, but it is too dark. Glow could light it up!")
				end
				entry.prompt.Enabled = false
				entry.part.Color = Color3.fromRGB(120, 60, 200)
				entry.part.Material = Enum.Material.Neon
				entry.label.RichText = true
				revealAll(plr, "Glow lit up the secret paint!")
				local t = ""
				for i = 1, #state.code do
					if not state.known[i] then
						t ..= "? " -- (4 colors: the one the paint doesn't show)
						continue
					end
					local c = Config.COLOR3[state.code[i]]
					t ..= string.format('<font color="#%02x%02x%02x">&#9679;</font>%s ', math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5), Config.COLOR_SHAPE[state.code[i]] or "")
				end
				entry.label.Text = t
				Effects.burst(entry.part.Position, "light")
				quest(plr, "skill")
			end)
		elseif def.kind == "plant" then
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Skill") ~= "bramble" then
					for _, p in ipairs(Players:GetPlayers()) do
						if p:GetAttribute("Skill") == "bramble" and not p:GetAttribute("Escaped") then
							return need(plr, "bramble", "This plant knows the code, but it only talks to Bramble - bring " .. p.DisplayName .. " here!")
						end
					end
					return say("info", "This plant only talks to Bramble, and nobody in your crew is Bramble. Pop the balloons to find the code!", nil, plr)
				end
				entry.prompt.Enabled = false
				Effects.burst(entry.part.Position + Vector3.new(0, 3, 0), "plant")
				revealAll(plr, "The plant whispered the code to Bramble!")
				quest(plr, "skill")
			end)
		elseif def.kind == "door" then
			entry.usePrompt.Triggered:Connect(function(plr)
				if not state.doorOpen then
					OpenKeypad:FireClient(plr)
				end
			end)
			entry.padPrompt.Triggered:Connect(function(plr)
				if state.status ~= "playing" or state.doorOpen then
					return
				end
				if plr:GetAttribute("Skill") ~= "tinker" then
					return need(plr, "tinker", "Only Tinker can pick a keypad. Everyone else needs the color code!")
				end
				if state.padPicked then
					return say("info", "The keypad has already been picked this game.", nil, plr)
				end
				local unknown = {}
				for i = 1, #state.code do
					if not state.known[i] then
						table.insert(unknown, i)
					end
				end
				if #unknown == 0 then
					return say("info", "You already know the whole code!", nil, plr)
				end
				state.padPicked = true
				entry.padPrompt.Enabled = false
				local k = unknown[math.random(1, #unknown)]
				state.known[k] = state.code[k]
				RoundState:SetAttribute("Known" .. k, state.code[k])
				addPoints(plr, 15)
				quest(plr, "skill")
				plr:SetAttribute("ToolkitReady", false)
				Effects.burst(entry.keypad.Position, "pick")
				say("reveal", "Click! Tinker picked the keypad: color " .. k .. " is " .. colourWord(state.code[k]) .. "!")
				-- Master Tinker: a second colour too (never the last one)
				if plr:GetAttribute("Power20") == "mastertinker" then
					local more = {}
					for i = 1, #state.code do
						if not state.known[i] then
							table.insert(more, i)
						end
					end
					if #more > 1 then
						local k2 = more[math.random(1, #more)]
						state.known[k2] = state.code[k2]
						RoundState:SetAttribute("Known" .. k2, state.code[k2])
						say("reveal", "Master Tinker: color " .. k2 .. " is " .. colourWord(state.code[k2]) .. " too!")
					end
				end
			end)
			entry.exit.Touched:Connect(function(hit)
				local plr = Players:GetPlayerFromCharacter(hit.Parent)
				if plr and state.doorOpen and state.status == "playing" then
					escape(plr, false)
				end
			end)
		elseif def.kind == "cage" then
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Caged") then
					return
				end
				local freed = 0
				for _, p in ipairs(Players:GetPlayers()) do
					if p:GetAttribute("Caged") and (freed == 0 or plr:GetAttribute("Skill") == "patch") then
						freeFromCage(p)
						freed += 1
					end
				end
				if freed > 0 then
					Effects.burst(world.objects.cage.outside, "rescue")
					Effects.ring(world.objects.cage.outside - Vector3.new(0, 2.8, 0), Color3.fromRGB(255, 210, 63), 26, 0.9)
					addPoints(plr, 20 * freed)
					local pd = Profile.get(plr)
					if pd then
						pd.stats.rescues += freed
					end
					quest(plr, "rescue", freed)
					say("rescue", plr.DisplayName .. " freed " .. freed .. (freed == 1 and " friend" or " friends") .. " from the cage!")
				end
				entry.prompt.Enabled = anyCaged()
			end)
		elseif def.kind == "lock" and def.blocked then
			entry.shovePrompt.Triggered:Connect(function(plr)
				if state.status ~= "playing" or world.unlocked[id] then
					return
				end
				if plr:GetAttribute("Skill") ~= "muscle" then
					return need(plr, "muscle", "Too heavy to move! Muscle could shove it - or find a Confetti Cannon in a drawer or box.")
				end
				clearBlock(plr, id, "shove")
				quest(plr, "skill")
			end)
			entry.popperPrompt.Triggered:Connect(function(plr)
				if state.status ~= "playing" or world.unlocked[id] then
					return
				end
				if entry.fuse then
					return say("info", "The Confetti Cannon is already planted - stand back!", nil, plr)
				end
				if (world.poppers or 0) <= 0 then
					return need(plr, "muscle", "You need a Confetti Cannon - search drawers and boxes for one! Or bring Muscle to shove it.")
				end
				entry.fuse = true
				world.poppers -= 1
				RoundState:SetAttribute("Poppers", world.poppers)
				entry.popperPrompt.Enabled = false
				local myWorld = world
				local pos = entry.part.Position - Vector3.new(0, 5.6, 0)
				local popper = Instance.new("Part")
				popper.Name = "ConfettiCannon"
				popper.Shape = Enum.PartType.Cylinder
				popper.Size = Vector3.new(1.6, 0.9, 0.9)
				popper.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
				popper.Color = Color3.fromRGB(255, 77, 160)
				popper.Material = Enum.Material.Neon
				popper.Anchored, popper.CanCollide = true, false
				popper.Parent = workspace
				local count = Instance.new("BillboardGui")
				count.Size = UDim2.fromOffset(80, 60)
				count.StudsOffset = Vector3.new(0, 3, 0)
				count.AlwaysOnTop = true
				count.Parent = popper
				local num = Instance.new("TextLabel")
				num.Size = UDim2.fromScale(1, 1)
				num.BackgroundTransparency = 1
				num.Font = Enum.Font.FredokaOne
				num.TextScaled = true
				num.TextColor3 = Color3.fromRGB(255, 210, 63)
				num.TextStrokeTransparency = 0.3
				num.Parent = count
				say("info", plr.DisplayName .. " planted the Confetti Cannon - stand back!")
				task.spawn(function()
					for n = 3, 1, -1 do
						num.Text = "\u{1F389} " .. n
						Effects.sound(pos, "beep", 1)
						task.wait(1)
					end
					popper:Destroy()
					if world ~= myWorld or state.status ~= "playing" then
						return
					end
					Effects.sound(pos, "pop", 1.5)
					Effects.surprise(pos, "confetti")
					Effects.burst(pos, "shove")
					-- BOOM: the host comes to look
					if host and host.model then
						alertHosts(pos)
					end
					clearBlock(plr, id, "popper")
				end)
			end)
		elseif def.kind == "lock" then
			entry.unlockPrompt.Triggered:Connect(function(plr)
				if state.status ~= "playing" or world.unlocked[id] then
					return
				end
				if not world.keys[id] then
					return need(plr, "tinker", "Locked! The key is hidden in something you can search - drawers, boxes, coats... Or bring Tinker to pick it.")
				end
				openLock(plr, id, "key")
			end)
			entry.pickPrompt.Triggered:Connect(function(plr)
				if state.status ~= "playing" or world.unlocked[id] then
					return
				end
				-- (4 Nov: Clone with a copied Toolkit ready picks one lock too)
				if plr:GetAttribute("Skill") ~= "tinker" and not (plr:GetAttribute("Skill") == "clone" and plr:GetAttribute("ToolkitReady")) then
					return need(plr, "tinker", "Only Tinker can pick a lock. Everyone else needs the key!")
				end
				Effects.burst(entry.lockPart.Position, "pick")
				openLock(plr, id, "pick")
				plr:SetAttribute("ToolkitReady", false)
				quest(plr, "skill")
				-- Skeleton Key: the first lock Tinker picks each game opens every other one too
				state.oncePerGame = state.oncePerGame or {}
				if plr:GetAttribute("Power10") == "skeleton" and not state.oncePerGame["skel" .. plr.UserId] then
					state.oncePerGame["skel" .. plr.UserId] = true
					local n = 0
					for other, e in pairs(world.objects) do
						if e.def and e.def.kind == "lock" and not e.def.blocked and not world.unlocked[other] then
							openLock(plr, other, "pick")
							n += 1
						end
					end
					if n > 0 then
						say("info", "\u{1F5DD} " .. plr.DisplayName .. "'s Skeleton Key opened " .. n .. " more " .. (n == 1 and "door!" or "doors!"))
					end
				end
			end)
		elseif def.kind == "search" then
			entry.prompt.Triggered:Connect(function(plr)
				if state.status ~= "playing" or entry.searched then
					return
				end
				entry.searched = true
				entry.prompt.Enabled = false
				quest(plr, "search")
				Effects.sound(entry.part.Position, "hide")
				-- rummaging is noisy
				if host and math.random() < 0.5 then
					alertHosts(entry.part.Position)
				end
				local lock = world.keyIn[id]
				local isPopper = lock ~= nil and world.objects[lock].def.blocked
				House.openObject(entry, lock ~= nil and not isPopper)
				if isPopper then
					-- the team's Poppers: any one works on any blocked doorway
					world.poppers = (world.poppers or 0) + 1
					RoundState:SetAttribute("Poppers", world.poppers)
					Effects.burst(entry.part.Position, "boost", "collect")
					addPoints(plr, 10)
					quest(plr, "key")
					say("key", plr.DisplayName .. " found a Confetti Cannon! It blasts open any blocked doorway.", { icon = "\u{1F389}", userId = plr.UserId, item = "Confetti Cannon" })
				elseif lock then
					world.keys[lock] = true
					RoundState:SetAttribute("Key_" .. lock, true)
					Effects.burst(entry.part.Position, "boost", "collect")
					addPoints(plr, 10)
					quest(plr, "key")
					say("key", plr.DisplayName .. " found the key to the " .. world.objects[lock].def.name .. "!", { icon = "\u{1F511}", userId = plr.UserId, item = "Key" })
				elseif world.lootIn and world.lootIn[id] then
					foundLoot(plr, world.lootIn[id], entry.part.Position)
				else
					local what = NOTHING[math.random(1, #NOTHING)]
					Effects.surprise(entry.part.Position, what[2])
					say("info", what[1], nil, plr)
				end
			end)
		elseif def.kind == "vent" then
			-- crawl through to the other end; the host cannot follow
			entry.prompt.Triggered:Connect(function(plr)
				if state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") or plr:GetAttribute("Hidden") or plr:GetAttribute("Crawling") then
					return
				end
				local other
				for oid, e in pairs(world.objects) do
					if e.def.kind == "vent" and e.def.pair == def.pair and oid ~= id then
						other = e
					end
				end
				if not other then
					return
				end
				-- any number can crawl; each player waits 2.5 s after coming out
				state.ventCool = state.ventCool or {}
				local nowT = os.clock()
				if (state.ventCool[plr.UserId] or 0) > nowT then
					return say("info", "Catch your breath - you can crawl again in a moment.", nil, plr)
				end
				state.ventCool[plr.UserId] = nowT + 1.6 + Config.VENT_REUSE
				local crawlId = (plr:GetAttribute("CrawlId") or 0) + 1
				plr:SetAttribute("CrawlId", crawlId)
				plr:SetAttribute("Crawling", true)
				quest(plr, "vent")
				local h = hrpOf(plr)
				if h then
					h.Anchored = true
				end
				setVisible(plr, false)
				Effects.sound(entry.part.Position, "hide")
				say("info", "Crawling through the vent...", nil, plr)
				task.delay(1.6, function()
					if plr:GetAttribute("CrawlId") ~= crawlId or plr:GetAttribute("Caged") then
						return -- caught on the way: the cage has them now
					end
					teleport(plr, at(other.def.x, other.def.y, 0))
					local h2 = hrpOf(plr)
					if h2 then
						h2.Anchored = false
					end
					setVisible(plr, true)
					plr:SetAttribute("Crawling", false)
					Effects.sound(other.part.Position, "hide")
				end)
			end)
		elseif def.kind == "hide" then
			entry.outside = besideTile(def.x, def.y, def.h)
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Hidden") then
					return unhide(plr)
				end
				if plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
					return
				end
				if hideSpotCount(id) >= (def.cap or 2) then
					return say("info", "No room in there!", nil, plr)
				end
				plr:SetAttribute("Hidden", true)
				plr:SetAttribute("HideSpot", id)
				quest(plr, "hide")
				local hrp = hrpOf(plr)
				if hrp then
					hrp.CFrame = CFrame.new(entry.inside)
					hrp.Anchored = true
				end
				setVisible(plr, false)
				House.peekHide(entry)
				Effects.sound(entry.inside, "hide")
				say("hide", "You are hiding. Press Jump or the Hide button to come out.", nil, plr)
			end)
		end
	end
end

function round.hostSpotted(_, plr)
	say("spotted", "The host has seen " .. plr.DisplayName .. "! RUN or HIDE!", { userId = plr.UserId })
end
function round.hostLost()
	say("gone", "Where did everybody go...?")
end
function round.hostSniff()
	say("sniff", "Sniff sniff... I smell birthday cake.")
end
-- the room an object is in (wall pictures count as the room below them)
local function roomOf(id)
	local e = world and world.objects[id]
	if not e then
		return "house"
	end
	local d = e.def
	local y = (d.kind == "door" or d.kind == "invite" or d.kind == "uv") and d.y + 1 or d.y
	for _, f in ipairs(HouseMap.floors) do
		if d.x >= f.x0 and d.x <= f.x1 and y >= f.y0 and y <= f.y1 then
			return f.name
		end
	end
	return "house"
end
local function reachable(id)
	local z = world.objects[id] and world.objects[id].def.zone or 1
	return z == 1 or (z == 2 and world.unlocked.L1) or (z == 3 and world.unlocked.L1 and world.unlocked.L2)
end

-- Gummy Bear Man's puddles: at most a few, melting, never near a doorway,
-- locked door, exit, vent or another puddle, so there is always a clean way
local function cellAt(x, y)
	local row = HouseMap.map[y + 1]
	return row and string.sub(row, x + 1, x + 1) or "#"
end
local function nearDoorway(x, y)
	for dx = -2, 2 do
		for dy = -2, 2 do
			local cx, cy = x + dx, y + dy
			local c = cellAt(cx, cy)
			if c == "L" or c == "D" or c == "H" or c == "C" then
				return true
			end
			if c == "." and ((cellAt(cx - 1, cy) == "#" and cellAt(cx + 1, cy) == "#") or (cellAt(cx, cy - 1) == "#" and cellAt(cx, cy + 1) == "#")) then
				return true
			end
		end
	end
	for _, e in pairs(world.objects) do
		if e.def.kind == "vent" and math.abs(e.def.x - x) <= 2 and math.abs(e.def.y - y) <= 2 then
			return true
		end
	end
	return false
end
-- Crumbles' crumbs (Christmas, 4 Nov): a little patch of gingerbread crumbs
-- where he walks; a kid stepping on one crunches it and he comes to look
function round.hostCrumbs(_, pos, hostModel)
	if state.status ~= "playing" then
		return false
	end
	local s = Config.HOST_SKILLS.crumbs
	state.crumbs = state.crumbs or {}
	for i = #state.crumbs, 1, -1 do
		if not state.crumbs[i].Parent then
			table.remove(state.crumbs, i)
		end
	end
	if #state.crumbs >= s.max then
		return false
	end
	for _, g in ipairs(state.crumbs) do
		if (Vector3.new(g.Position.X, 0, g.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < s.clear * T then
			return false
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { hostModel }
	local hit = workspace:Raycast(pos, Vector3.new(0, -40, 0), params)
	local floorY = hit and hit.Position.Y or 0
	local g = Instance.new("Part")
	g.Name = "Crumbs"
	g.Shape = Enum.PartType.Cylinder
	g.Size = Vector3.new(0.2, 5, 5)
	g.CFrame = CFrame.new(pos.X, floorY + 0.1, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
	g.Color = Color3.fromRGB(176, 108, 58)
	g.Material = Enum.Material.Sand
	g.Transparency = 0.2
	g.Anchored, g.CanCollide, g.CanQuery = true, false, false
	g.Parent = world.root
	-- a few bigger crumbs and an icing chip on top
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2 + math.random()
		local b = Instance.new("Part")
		b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch, b.CastShadow = true, false, false, false, false
		b.Size = Vector3.new(0.6, 0.35, 0.5) * (0.7 + math.random() * 0.6)
		b.CFrame = CFrame.new(pos.X + math.cos(a) * 1.4, floorY + 0.25, pos.Z + math.sin(a) * 1.4) * CFrame.Angles(0, a, 0)
		b.Color = i == 1 and Color3.fromRGB(250, 250, 250) or Color3.fromRGB(150, 90, 45)
		b.Material = Enum.Material.SmoothPlastic
		b.Parent = g
	end
	table.insert(state.crumbs, g)
	g.Touched:Connect(function(hitPart)
		local plr = Players:GetPlayerFromCharacter(hitPart.Parent)
		if not plr or not g.Parent or state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped")
			or plr:GetAttribute("Crawling") or (plr:GetAttribute("SneakUntil") or 0) > workspace:GetServerTimeNow() then
			return
		end
		local at = g.Position
		g:Destroy()
		Effects.sound(at, "candy", 1)
		say("info", "CRUNCH! " .. plr.DisplayName .. " stepped on Crumbles' crumbs - he heard that!", { userId = plr.UserId })
		if host and host.model then
			alertHosts(at)
		end
	end)
	task.delay(s.last, function()
		if g.Parent then
			g:Destroy()
		end
	end)
	return true
end

function round.hostGummy(_, pos, hostModel)
	if state.status ~= "playing" then
		return false
	end
	local s = Config.HOST_SKILLS.gummy
	state.gummies = state.gummies or {}
	for i = #state.gummies, 1, -1 do
		if not state.gummies[i].Parent then
			table.remove(state.gummies, i)
		end
	end
	if #state.gummies >= s.max then
		return false
	end
	local x, y = math.floor(pos.X / T), math.floor(pos.Z / T)
	if nearDoorway(x, y) then
		return false
	end
	for _, g in ipairs(state.gummies) do
		if (Vector3.new(g.Position.X, 0, g.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < s.clear * T then
			return false
		end
	end
	-- the floor under him (the ground or the loft)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { hostModel }
	local hit = workspace:Raycast(pos, Vector3.new(0, -40, 0), params)
	local floorY = hit and hit.Position.Y or 0
	local g = Instance.new("Part")
	g.Name = "GummyPuddle"
	g.Shape = Enum.PartType.Cylinder
	g.Size = Vector3.new(0.3, 6, 6)
	g.CFrame = CFrame.new(pos.X, floorY + 0.15, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
	g.Color = Color3.fromRGB(230, 40, 80)
	g.Material = Enum.Material.Glass
	g.Transparency = 0.25
	g.Anchored, g.CanCollide, g.CanQuery = true, false, false
	g.Parent = world.root
	-- a sticky heap of gummy bears on the goo (they go when the puddle does)
	do
		local cols = { Color3.fromRGB(230, 40, 80), Color3.fromRGB(255, 160, 40), Color3.fromRGB(80, 200, 90), Color3.fromRGB(255, 220, 60), Color3.fromRGB(150, 80, 220) }
		local function bit(size, cf, col, alpha)
			local b = Instance.new("Part")
			b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch, b.CastShadow = true, false, false, false, false
			b.Shape = Enum.PartType.Ball
			b.Size = size
			Shapes.fix(b, Enum.PartType.Ball, size)
			b.CFrame = cf
			b.Color = col
			b.Material = Enum.Material.SmoothPlastic
			b.Reflectance = 0.12
			b.Transparency = alpha or 0.1
			b.Parent = g
		end
		local base = Vector3.new(pos.X, floorY, pos.Z)
		bit(Vector3.new(4.2, 1.4, 4.2), CFrame.new(base + Vector3.new(0, 0.35, 0)), Color3.fromRGB(230, 40, 80), 0.25)
		-- five little gummy bears sitting round the goo, facing out: body,
		-- paler belly and muzzle, head, round ears, dark eyes and nose
		local DARK = Color3.fromRGB(40, 25, 35)
		for i = 1, 5 do
			local a = i / 5 * math.pi * 2
			local p = base + Vector3.new(math.cos(a) * 1.2, 0.9, math.sin(a) * 1.2)
			local cf = CFrame.lookAt(p, p + Vector3.new(math.cos(a), 0, math.sin(a)))
			local col = cols[i % #cols + 1]
			local pale = col:Lerp(Color3.new(1, 1, 1), 0.45)
			bit(Vector3.new(0.9, 1.05, 0.8), cf, col)
			bit(Vector3.new(0.55, 0.6, 0.2), cf * CFrame.new(0, -0.05, -0.35), pale, 0)
			bit(Vector3.new(0.82, 0.74, 0.72), cf * CFrame.new(0, 0.78, 0), col)
			bit(Vector3.new(0.3, 0.3, 0.2), cf * CFrame.new(-0.28, 1.12, 0), col)
			bit(Vector3.new(0.3, 0.3, 0.2), cf * CFrame.new(0.28, 1.12, 0), col)
			bit(Vector3.new(0.36, 0.26, 0.16), cf * CFrame.new(0, 0.68, -0.33), pale, 0)
			bit(Vector3.new(0.13, 0.1, 0.1), cf * CFrame.new(0, 0.74, -0.42), DARK, 0)
			bit(Vector3.new(0.1, 0.12, 0.08), cf * CFrame.new(-0.16, 0.9, -0.33), DARK, 0)
			bit(Vector3.new(0.1, 0.12, 0.08), cf * CFrame.new(0.16, 0.9, -0.33), DARK, 0)
		end
	end
	table.insert(state.gummies, g)
	Effects.sound(g.Position, "bounce", 0.5)
	g.Touched:Connect(function(hitPart)
		local plr = Players:GetPlayerFromCharacter(hitPart.Parent)
		if not plr or not g.Parent or state.status ~= "playing" or plr:GetAttribute("Stuck") or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") or plr:GetAttribute("Crawling") then
			return
		end
		g:Destroy()
		plr:SetAttribute("Stuck", true)
		plr:SetAttribute("Frozen", true)
		setSpeed(plr, 0)
		say("stuck", plr.DisplayName .. " stepped in a gummy puddle - stuck!", { userId = plr.UserId })
		Effects.react(plr, "gummy", s.stick)
		task.delay(s.stick, function()
			plr:SetAttribute("Stuck", false)
			plr:SetAttribute("Frozen", false)
			if not plr:GetAttribute("Caged") and not plr:GetAttribute("Hidden") then
				setSpeed(plr, Config.WALK)
			end
		end)
	end)
	task.delay(s.melt, function()
		if g.Parent then
			TweenService:Create(g, TweenInfo.new(1.5), { Transparency = 1 }):Play()
			for _, d in ipairs(g:GetDescendants()) do
				if d:IsA("BasePart") then
					TweenService:Create(d, TweenInfo.new(1.5), { Transparency = 1 }):Play()
				end
			end
			task.delay(1.6, function()
				g:Destroy()
			end)
		end
	end)
	return true
end

-- the Robot's blackout: his room goes dark for a few seconds
function round.hostBlackout(_, pos)
	if state.status ~= "playing" then
		return
	end
	local x, y = math.floor(pos.X / T), math.floor(pos.Z / T)
	local name
	for _, f in ipairs(HouseMap.floors) do
		if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
			name = f.name
		end
	end
	local light = name and world.roomLights and world.roomLights[name]
	if not light then
		return
	end
	light.Enabled = false
	RoundState:SetAttribute("Blackout", name)
	local eyes
	local head = host and host.model and (host.model:FindFirstChild("Head") or host.root)
	if head then
		eyes = Instance.new("PointLight")
		eyes.Color, eyes.Range, eyes.Brightness = Color3.fromRGB(255, 40, 40), 10, 3
		eyes.Parent = head
	end
	say("dark", "The lights just went out in the " .. name .. "!")
	for _, kid in ipairs(Players:GetPlayers()) do
		local kh = kid.Character and kid.Character:FindFirstChild("HumanoidRootPart")
		if kh and not kid:GetAttribute("Caged") and not kid:GetAttribute("Escaped") then
			local kx, ky = math.floor(kh.Position.X / T), math.floor(kh.Position.Z / T)
			for _, f in ipairs(HouseMap.floors) do
				if f.name == name and kx >= f.x0 and kx <= f.x1 and ky >= f.y0 and ky <= f.y1 then
					Effects.react(kid, "dark", Config.HOST_SKILLS.blackout.seconds)
				end
			end
		end
	end
	task.delay(Config.HOST_SKILLS.blackout.seconds, function()
		light.Enabled = true
		if RoundState:GetAttribute("Blackout") == name then
			RoundState:SetAttribute("Blackout", "")
		end
		if eyes then
			eyes:Destroy()
		end
	end)
end

-- the Caretaker's Lock-up: a padlocked gate across a doorway near a kid he
-- can see, on the far side of them, for a few seconds. The host walks
-- through it (collision groups); Tinker picks it at once.
do
	local PhysicsService = game:GetService("PhysicsService")
	for _, g in ipairs({ "Host", "LockUp" }) do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(g)
		end)
	end
	PhysicsService:CollisionGroupSetCollidable("Host", "LockUp", false)

	-- a plain doorway: floor with wall either side, not by a locked door, the exit or the host's door
	local function plainDoorway(x, y)
		if cellAt(x, y) ~= "." then
			return nil
		end
		local across
		if cellAt(x - 1, y) == "#" and cellAt(x + 1, y) == "#" then
			across = "x" -- walls left and right: you walk through it along z
		elseif cellAt(x, y - 1) == "#" and cellAt(x, y + 1) == "#" then
			across = "z"
		else
			return nil
		end
		for dx = -2, 2 do
			for dy = -2, 2 do
				local c = cellAt(x + dx, y + dy)
				if c == "L" or c == "D" or c == "H" or c == "C" then
					return nil
				end
			end
		end
		return across
	end

	function round.hostLockup(_, target, hostPos)
		if state.status ~= "playing" or not world then
			return false
		end
		local s = Config.HOST_SKILLS.lockup
		local hrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return false
		end
		state.lockups = state.lockups or {}
		local kx, ky = math.floor(hrp.Position.X / T), math.floor(hrp.Position.Z / T)
		local kidFromHost = (Vector3.new(hrp.Position.X - hostPos.X, 0, hrp.Position.Z - hostPos.Z)).Magnitude
		local best, bestD, bestAcross
		for dx = -s.near, s.near do
			for dy = -s.near, s.near do
				local x, y = kx + dx, ky + dy
				local across = (dx ~= 0 or dy ~= 0) and not state.lockups[x .. "," .. y] and plainDoorway(x, y)
				if across then
					local c = House.at(x, y, 0)
					-- on the far side of the kid (ahead of them, away from the host)
					local fromHost = (Vector3.new(c.X - hostPos.X, 0, c.Z - hostPos.Z)).Magnitude
					local d = (Vector3.new(c.X - hrp.Position.X, 0, c.Z - hrp.Position.Z)).Magnitude
					local clear = true
					for _, p in ipairs(Players:GetPlayers()) do
						local h = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
						if h and (Vector3.new(h.Position.X - c.X, 0, h.Position.Z - c.Z)).Magnitude < T * 0.9 then
							clear = false -- never shut a gate on top of someone
						end
					end
					if clear and fromHost > kidFromHost and (not bestD or d < bestD) then
						best, bestD, bestAcross = Vector2.new(x, y), d, across
					end
				end
			end
		end
		if not best then
			return false
		end
		local key = best.X .. "," .. best.Y
		state.lockups[key] = true
		local base = House.at(best.X, best.Y, 0)
		local gate = Instance.new("Model")
		gate.Name = "LockUpGate"
		local function bit(size, offset, col, mat, shape)
			local b = Instance.new("Part")
			b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch, b.CastShadow = true, false, false, false, false
			b.Shape = shape or Enum.PartType.Block
			b.Size = bestAcross == "x" and size or Vector3.new(size.Z, size.Y, size.X)
			b.Position = base + (bestAcross == "x" and offset or Vector3.new(offset.Z, offset.Y, offset.X))
			b.Color = col
			b.Material = mat or Enum.Material.Metal
			b.Parent = gate
			return b
		end
		-- the wall kids bump into (the host's group passes through; pathfinding ignores it)
		local wall = bit(Vector3.new(T, Config.WALL_H, 0.6), Vector3.new(0, Config.WALL_H / 2, 0), Color3.new(), Enum.Material.SmoothPlastic)
		wall.Transparency, wall.CanCollide, wall.CollisionGroup, wall.Name = 1, true, "LockUp", "Bars"
		local mod = Instance.new("PathfindingModifier")
		mod.PassThrough = true
		mod.Parent = wall
		-- old iron bars, two chains in a cross and a big brass padlock
		local iron = Color3.fromRGB(60, 62, 66)
		for i = -2, 2 do
			bit(Vector3.new(0.35, 9, 0.35), Vector3.new(i * T / 5.5, 4.5, 0), iron)
		end
		bit(Vector3.new(T, 0.4, 0.4), Vector3.new(0, 8.6, 0), iron)
		bit(Vector3.new(T, 0.4, 0.4), Vector3.new(0, 1.2, 0), iron)
		for _, a in ipairs({ 35, -35 }) do
			local ch = bit(Vector3.new(T * 1.05, 0.3, 0.3), Vector3.new(0, 4.6, -0.4), Color3.fromRGB(150, 150, 155))
			ch.CFrame = CFrame.new(ch.Position) * (bestAcross == "x" and CFrame.Angles(0, 0, math.rad(a)) or CFrame.Angles(math.rad(a), 0, 0))
		end
		local lock = bit(Vector3.new(1.3, 1.3, 0.6), Vector3.new(0, 4.6, -0.75), Color3.fromRGB(205, 160, 60))
		lock.CanQuery = true
		bit(Vector3.new(0.9, 0.9, 0.2), Vector3.new(0, 5.6, -0.75), Color3.fromRGB(170, 170, 175))
		gate.Parent = world.root
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Pick the lock"
		pp.ObjectText = "Tinker"
		pp.HoldDuration = 0
		pp.MaxActivationDistance = 10
		pp.RequiresLineOfSight = false
		pp.KeyboardKeyCode = Enum.KeyCode.F
		pp.GamepadKeyCode = Enum.KeyCode.ButtonY
		pp:SetAttribute("Only", "tinker")
		pp.Parent = lock
		local mine = state.lockups
		local function open()
			mine[key] = nil
			if gate.Parent then
				gate:Destroy()
			end
		end
		pp.Triggered:Connect(function(plr)
			if state.status ~= "playing" or plr:GetAttribute("Skill") ~= "tinker" or not gate.Parent then
				return
			end
			Effects.burst(lock.Position, "pick")
			say("pick", plr.DisplayName .. " picked the Caretaker's padlock!")
			quest(plr, "skill")
			open()
		end)
		Effects.sound(lock.Position, "pick", 0.8)
		say("lockup", "Jangle jangle... the Caretaker padlocked a doorway!", { userId = target.UserId })
		Effects.react(target, "lockup")
		task.delay(s.seconds, open)
		return true
	end
end

-- the Clown Bear's jack-in-the-boxes: when a floor starts with him as the
-- host, a few boxes on random free checked spots (never the starting room,
-- by a doorway or on top of anything). Come near one (not sneaking or
-- hidden) and it springs with a honk: you glow for a moment and he comes to
-- look. It winds itself back up in the same place; Tinker winds one down
-- for good.
function round.placeJackBoxes()
	local s = Config.HOST_SKILLS.jackbox
	local myState, myWorld = state, world
	local map = HouseMap
	local startRoom
	for _, f in ipairs(map.floors) do
		local sx, sy = map.start[1][1], map.start[1][2]
		if sx >= f.x0 and sx <= f.x1 and sy >= f.y0 and sy <= f.y1 then
			startRoom = f.name
		end
	end
	local taken = {}
	local function near(x, y, r)
		for _, t in ipairs(taken) do
			if math.abs(t[1] - x) <= r and math.abs(t[2] - y) <= r then
				return true
			end
		end
		return false
	end
	for _, e in pairs(world.objects) do
		if e.def and e.def.x then
			table.insert(taken, { e.def.x, e.def.y })
		end
	end
	table.insert(taken, map.cake)
	table.insert(taken, map.spawn)
	for _, p in ipairs(map.pads or {}) do
		table.insert(taken, p)
	end
	local pool = {}
	for _, sl in ipairs(map.floorSlots or {}) do
		if sl[4] ~= startRoom and not nearDoorway(sl[1], sl[2]) and not near(sl[1], sl[2], 1) then
			table.insert(pool, sl)
		end
	end
	local want = s.count[state.diff] or 4
	local boxes = {}
	while #boxes < want and #pool > 0 do
		local sl = table.remove(pool, math.random(1, #pool))
		if not near(sl[1], sl[2], 1) then
			local spaced = true
			for _, b in ipairs(boxes) do
				if math.abs(b.x - sl[1]) + math.abs(b.y - sl[2]) < 5 then
					spaced = false
				end
			end
			if spaced then
				table.insert(boxes, { x = sl[1], y = sl[2] })
				table.insert(taken, { sl[1], sl[2] })
				state.extraTaken = state.extraTaken or {}
				table.insert(state.extraTaken, { sl[1], sl[2] })
			end
		end
	end
	local purple, orange = Color3.fromRGB(110, 60, 160), Color3.fromRGB(255, 140, 40)
	for _, b in ipairs(boxes) do
		local base = House.at(b.x, b.y, 0)
		local m = Instance.new("Model")
		m.Name = "JackInTheBox"
		local function bit(size, pos, col, mat, shape)
			local pt = Instance.new("Part")
			pt.Anchored, pt.CanCollide, pt.CanTouch, pt.CastShadow = true, false, false, false
			pt.Size, pt.Position, pt.Color = size, pos, col
			pt.Material = mat or Enum.Material.SmoothPlastic
			pt.Shape = shape or Enum.PartType.Block
			pt.Parent = m
			return pt
		end
		local box = bit(Vector3.new(2.6, 2.6, 2.6), base + Vector3.new(0, 1.3, 0), purple)
		for i = -1, 1, 2 do
			bit(Vector3.new(2.65, 0.5, 2.65), base + Vector3.new(0, 1.3 + i * 0.7, 0), orange)
		end
		bit(Vector3.new(0.3, 0.3, 1.2), base + Vector3.new(1.45, 1.4, 0), Color3.fromRGB(230, 190, 80), Enum.Material.Foil) -- the crank
		bit(Vector3.new(0.3, 0.9, 0.3), base + Vector3.new(1.45, 1.75, 0.5), Color3.fromRGB(230, 190, 80), Enum.Material.Foil)
		local lid = bit(Vector3.new(2.7, 0.3, 2.7), base + Vector3.new(0, 2.75, 0), orange)
		local spring = bit(Vector3.new(0.2, 0.6, 0.6), base + Vector3.new(0, 2.2, 0), Color3.fromRGB(200, 200, 210), Enum.Material.Metal, Enum.PartType.Cylinder)
		spring.CFrame = CFrame.new(spring.Position) * CFrame.Angles(0, 0, math.rad(90))
		local head = bit(Vector3.new(1.8, 1.8, 1.8), base + Vector3.new(0, 1.6, 0), Color3.fromRGB(250, 240, 230), nil, Enum.PartType.Ball)
		local nose = bit(Vector3.new(0.6, 0.6, 0.6), head.Position + Vector3.new(0, 0, -0.9), Color3.fromRGB(230, 40, 50), nil, Enum.PartType.Ball)
		local hat = bit(Vector3.new(1, 1.2, 1), head.Position + Vector3.new(0, 1.1, 0), Color3.fromRGB(255, 140, 40), nil, Enum.PartType.Ball)
		m.Parent = world.root
		b.model, b.armed = m, true
		local down = { head = head.Position, nose = nose.Position, hat = hat.Position, lid = lid.CFrame, spring = spring.CFrame }
		local function pose(open)
			local up = open and Vector3.new(0, 3, 0) or Vector3.zero
			local ti = TweenInfo.new(open and 0.25 or 1.2, open and Enum.EasingStyle.Back or Enum.EasingStyle.Sine)
			TweenService:Create(head, ti, { Position = down.head + up }):Play()
			TweenService:Create(nose, ti, { Position = down.nose + up }):Play()
			TweenService:Create(hat, ti, { Position = down.hat + up }):Play()
			TweenService:Create(spring, ti, { Size = open and Vector3.new(3.2, 0.6, 0.6) or Vector3.new(0.2, 0.6, 0.6), CFrame = down.spring + up / 2 }):Play()
			TweenService:Create(lid, ti, { CFrame = open and (down.lid * CFrame.new(-1.3, 0, 0) * CFrame.Angles(0, 0, math.rad(100)) * CFrame.new(1.3, 0, 0)) or down.lid }):Play()
		end
		b.pose = pose
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Wind it down"
		pp.ObjectText = "Jack-in-the-box"
		pp.HoldDuration = s.wind
		pp.MaxActivationDistance = 9
		pp.RequiresLineOfSight = false
		pp.KeyboardKeyCode = Enum.KeyCode.F
		pp.GamepadKeyCode = Enum.KeyCode.ButtonY
		pp:SetAttribute("Only", "tinker")
		pp.Parent = box
		pp.Triggered:Connect(function(plr)
			if state ~= myState or state.status ~= "playing" or plr:GetAttribute("Skill") ~= "tinker" or b.dead then
				return
			end
			b.dead, b.armed = true, false
			Effects.burst(box.Position, "pick")
			say("pick", plr.DisplayName .. " wound a jack-in-the-box down for good!")
			quest(plr, "skill")
			m:Destroy()
		end)
	end
	if #boxes == 0 then
		return
	end
	-- watch for anyone coming near an armed box
	task.spawn(function()
		while state == myState and world == myWorld and state.status == "playing" do
			task.wait(0.2)
			local now = workspace:GetServerTimeNow()
			for _, b in ipairs(boxes) do
				if b.armed and not b.dead and b.model.Parent then
					local c = House.at(b.x, b.y, 0)
					for _, plr in ipairs(Players:GetPlayers()) do
						local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
						if h and b.armed and (Vector3.new(h.Position.X - c.X, 0, h.Position.Z - c.Z)).Magnitude < s.near and math.abs(h.Position.Y - c.Y) < 8
							and not plr:GetAttribute("Hidden") and not plr:GetAttribute("Crawling") and not plr:GetAttribute("Caged") and not plr:GetAttribute("Escaped")
							and (plr:GetAttribute("SneakUntil") or 0) <= now then
							b.armed = false
							b.pose(true)
							Effects.burst(c + Vector3.new(0, 4, 0), "noise")
							say("jackbox", "BOING! A jack-in-the-box gave " .. plr.DisplayName .. " away!", { userId = plr.UserId })
							Effects.react(plr, "jack")
							local hl = Instance.new("Highlight")
							hl.FillColor, hl.OutlineColor, hl.FillTransparency = Color3.fromRGB(255, 80, 120), Color3.fromRGB(255, 220, 80), 0.6
							hl.Parent = plr.Character
							game:GetService("Debris"):AddItem(hl, s.show)
							if host and host.model then
								alertHosts(h.Position)
							end
							task.delay(s.rearm, function()
								if not b.dead and b.model.Parent and state == myState then
									b.pose(false)
									task.wait(1.3)
									b.armed = not b.dead
								end
							end)
						end
					end
				end
			end
		end
	end)
end

-- the Anglerfish Keeper's fake presents: exactly like a real one; open it
-- and it flashes, you glow and he comes to look. Brainy and Glow can pop a
-- fake safely (their own prompt). A few at once, each for a minute.
function round.hostFakeGift(_, pos, hostModel)
	if state.status ~= "playing" or not world then
		return false
	end
	local s = Config.HOST_SKILLS.fakegift
	state.fakes = state.fakes or {}
	for i = #state.fakes, 1, -1 do
		if not state.fakes[i].Parent then
			table.remove(state.fakes, i)
		end
	end
	if #state.fakes >= s.max then
		return false
	end
	local x, y = math.floor(pos.X / T), math.floor(pos.Z / T)
	if nearDoorway(x, y) then
		return false
	end
	for _, g in ipairs(state.fakes) do
		if (Vector3.new(g:GetPivot().Position.X - pos.X, 0, g:GetPivot().Position.Z - pos.Z)).Magnitude < s.clear * T then
			return false
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { hostModel }
	local hit = workspace:Raycast(pos, Vector3.new(0, -40, 0), params)
	local base = Vector3.new(pos.X, hit and hit.Position.Y or 0, pos.Z)
	local m = Instance.new("Model")
	m.Name = "FakePresent"
	local function bit(props)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanTouch, p.CastShadow = true, false, false, false
		for k, v in pairs(props) do
			p[k] = v
		end
		p.Parent = m
		return p
	end
	local blue = math.random() < 0.5
	local col = blue and Color3.fromRGB(61, 139, 255) or Color3.fromRGB(232, 80, 91)
	local box = bit({ Name = "Present", Size = Vector3.new(2.2, 2, 2.2), Position = base + Vector3.new(0, 1, 0), Color = col })
	bit({ Name = "Ribbon", Size = Vector3.new(2.3, 2.1, 0.4), Position = box.Position, Color = Color3.fromRGB(255, 210, 63) })
	bit({ Name = "PresentLid", Size = Vector3.new(2.5, 0.5, 2.5), Position = base + Vector3.new(0, 2.2, 0), Color = col })
	bit({ Name = "Bow", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), Position = base + Vector3.new(0, 2.6, 0), Color = Color3.fromRGB(255, 210, 63) })
	m.PrimaryPart = box
	m.Parent = world.root
	table.insert(state.fakes, m)
	local myState = state
	local function prompt(action, object, only)
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText, pp.ObjectText = action, object
		pp.HoldDuration = 0
		pp.MaxActivationDistance = 10
		pp.RequiresLineOfSight = false
		if only then
			pp:SetAttribute("Only", only)
			pp.KeyboardKeyCode = Enum.KeyCode.F
			pp.GamepadKeyCode = Enum.KeyCode.ButtonY
		end
		pp.Parent = box
		return pp
	end
	-- anyone: it looks just like a present
	prompt("Open", "Present").Triggered:Connect(function(plr)
		if state ~= myState or state.status ~= "playing" or not m.Parent then
			return
		end
		m:Destroy()
		local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		Effects.burst(box.Position + Vector3.new(0, 2, 0), "noise")
		say("fake", "It was a trick present! The Anglerfish Keeper knows where " .. plr.DisplayName .. " is!", { userId = plr.UserId })
		Effects.react(plr, "fake")
		if plr.Character then
			local hl = Instance.new("Highlight")
			hl.FillColor, hl.OutlineColor, hl.FillTransparency = Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 240, 170), 0.6
			hl.Parent = plr.Character
			game:GetService("Debris"):AddItem(hl, s.show)
		end
		if h and host and host.model then
			alertHosts(h.Position)
		end
	end)
	-- Brainy and Glow can tell a fake, and pop it safely
	for _, who in ipairs({ "brainy", "glow" }) do
		prompt("Pop it - it's a fake!", who == "brainy" and "Brainy can tell" or "Glow's light shows it", who).Triggered:Connect(function(plr)
			if state ~= myState or state.status ~= "playing" or not m.Parent or plr:GetAttribute("Skill") ~= who then
				return
			end
			m:Destroy()
			Effects.burst(box.Position, "pop")
			say("pick", plr.DisplayName .. " spotted a trick present and popped it!")
			quest(plr, "skill")
		end)
	end
	task.delay(s.last, function()
		if m.Parent then
			m:Destroy()
		end
	end)
	return true
end

-- the collectibles book: this floor's lost plushie sits on a free spot
-- away from the starting room (behind the locks too). Each player who has
-- not found it yet adds it to their Plushie Book by walking up to it.
function round.placePlushie()
	local mapId = RoundState:GetAttribute("Map") or "partyhouse"
	local def
	for _, p in ipairs(Config.PLUSHIES or {}) do
		if p.map == mapId then
			def = p
		end
	end
	if not def then
		return
	end
	local map = HouseMap
	local function roomAt(x, y)
		for _, f in ipairs(map.floors) do
			if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
				return f.name
			end
		end
		return nil
	end
	local startRoom = map.start and map.start[1] and roomAt(map.start[1][1], map.start[1][2])
	local taken = {}
	for _, o in pairs(world.objects) do
		if o.def and o.def.x then
			table.insert(taken, { o.def.x, o.def.y })
		end
	end
	for _, t in ipairs(state.extraTaken or {}) do
		table.insert(taken, t)
	end
	for _, p in ipairs(map.pads or {}) do
		table.insert(taken, p)
	end
	table.insert(taken, map.cake)
	local pool = {}
	for _, sl in ipairs(map.floorSlots or {}) do
		local ok = not nearDoorway(sl[1], sl[2]) and roomAt(sl[1], sl[2]) ~= startRoom
		for _, t in ipairs(taken) do
			if t and math.abs(t[1] - sl[1]) <= 1 and math.abs(t[2] - sl[2]) <= 1 then
				ok = false
			end
		end
		if ok then
			table.insert(pool, sl)
		end
	end
	if #pool == 0 then
		return
	end
	local sl = pool[math.random(1, #pool)]
	table.insert(state.extraTaken, { sl[1], sl[2] })
	local pos = House.at(sl[1], sl[2], 0)
	local m = Plushies.build(def, CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	-- big enough to see what animal it is (built 2.4 studs tall), feet on the floor
	m:ScaleTo(1.6)
	do
		local bcf, bsize = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + Vector3.new(pos.X - bcf.Position.X, pos.Y + bsize.Y / 2 - bcf.Position.Y, pos.Z - bcf.Position.Z))
	end
	m.Parent = world.root
	if RunService:IsStudio() then
		print("[Plushie] " .. def.name .. " is in the " .. tostring(roomAt(sl[1], sl[2])))
		task.delay(6, function()
			say("info", "(Studio test) " .. def.name .. " is in the " .. tostring(roomAt(sl[1], sl[2])) .. ".")
		end)
	end
	local myState, myWorld = state, world
	local told = {}
	task.spawn(function()
		while state == myState and world == myWorld and state.status == "playing" and m.Parent do
			task.wait(0.25)
			for _, plr in ipairs(Players:GetPlayers()) do
				local h = hrpOf(plr)
				if h and not told[plr] and not plr:GetAttribute("Caged") and not plr:GetAttribute("Escaped") and (h.Position - pos).Magnitude < 5 then
					told[plr] = true
					local data = Profile.get(plr)
					if data then
						data.plush = data.plush or {}
						if data.plush[mapId] then
							say("info", "\u{1F9F8} " .. def.name .. " is already in your Plushie Book.", nil, plr)
						else
							data.plush[mapId] = true
							local n = 0
							for _ in pairs(data.plush) do
								n += 1
							end
							addPoints(plr, Config.PLUSHIE_POINTS, true)
							Profile.publish(plr)
							Effects.burst(pos + Vector3.new(0, 2.5, 0), "rescue", "collect")
							Effects.sound(pos, "squeak", 0.9)
							-- 10 Oct (Brent): it hops, spins and ends up facing its finder
							task.spawn(function()
								local start = m:GetPivot()
								local toward = Vector3.new(h.Position.X, start.Y, h.Position.Z)
								local face = CFrame.lookAt(start.Position, start.Position - (toward - start.Position)) -- the plushie's front is -Z
								local _, yaw0 = start:ToEulerAnglesYXZ()
								local _, yaw1 = face:ToEulerAnglesYXZ()
								local turn = (yaw1 - yaw0) % (math.pi * 2) + math.pi * 2
								local t0 = os.clock()
								while m.Parent and os.clock() - t0 < 0.8 do
									local t = (os.clock() - t0) / 0.8
									m:PivotTo(CFrame.new(start.Position + Vector3.new(0, math.sin(t * math.pi) * 1.5, 0)) * CFrame.Angles(0, yaw0 + turn * t, 0))
									task.wait()
								end
								if m.Parent then
									m:PivotTo(CFrame.new(start.Position) * CFrame.Angles(0, yaw0 + turn, 0))
								end
							end)
							-- the finder gets a card with the plushie in 3D (on the
							-- side, so it hides nothing); everyone else a message
							for _, p in ipairs(Players:GetPlayers()) do
								if p == plr then
									say("plushie", "\u{1F9F8} You found " .. def.name .. "!", { userId = plr.UserId, map = mapId, n = n, total = #Config.PLUSHIES }, p)
								else
									say("info", "\u{1F9F8} " .. plr.DisplayName .. " found " .. def.name .. "! (" .. n .. " / " .. #Config.PLUSHIES .. " in their Plushie Book)", nil, p)
								end
							end
							if n >= #Config.PLUSHIES and (Config.BADGES.plushies or 0) > 0 then
								task.spawn(pcall, function()
									game:GetService("BadgeService"):AwardBadge(plr.UserId, Config.BADGES.plushies)
								end)
							end
						end
					end
				end
			end
		end
	end)
end

-- the season's hunt (Config.SEASONS - Halloween's candy corns, Thanksgiving's
-- golden feathers): a few on random free checked spots of every floor (behind
-- the locks too) while the season runs. Walk into one to pick it up: points,
-- and the count towards the season's badge.
-- Cloud's Float Up (4 Nov, Config.CLOUD): a few high shelves on each floor,
-- against a wall with a little cloud above, out of everyone's reach. Only Cloud
-- floats up to one (hold E): a free clue for the team, or points for everyone.
-- Extras only - never anything the team needs to escape
-- Harmony's Music Box (4 Nov): one behind the first locked door (a zone-2
-- room, like Brainy's invitation and Glow's paint - Brent: in the start room
-- it gave the whole code in the first seconds). Only Harmony hears it
-- (hold E): it plays the door code
function round.placeMusicBox()
	local myState, myWorld = state, world
	local s = HouseMap.start and HouseMap.start[1]
	if not s then
		return
	end
	local rooms, startRoom = {}, nil
	for _, f in ipairs(HouseMap.floors) do
		if s[1] >= f.x0 and s[1] <= f.x1 and s[2] >= f.y0 and s[2] <= f.y1 then
			startRoom = f
		end
		if f.zone == 2 then
			table.insert(rooms, f)
		end
	end
	if not startRoom and #rooms == 0 then
		return
	end
	local taken = {}
	for _, o in pairs(world.objects) do
		if o.def and o.def.x then
			table.insert(taken, { o.def.x, o.def.y })
		end
	end
	for _, t in ipairs(state.extraTaken or {}) do
		table.insert(taken, t)
	end
	for _, st in ipairs(HouseMap.start) do
		table.insert(taken, st)
	end
	local function poolIn(list)
		local pool = {}
		for _, sl in ipairs(HouseMap.floorSlots or {}) do
			local x, y = sl[1], sl[2]
			for _, room in ipairs(list) do
				if x >= room.x0 and x <= room.x1 and y >= room.y0 and y <= room.y1 and not nearDoorway(x, y) then
					local clear = true
					for _, t in ipairs(taken) do
						if math.abs(t[1] - x) <= 1 and math.abs(t[2] - y) <= 1 then
							clear = false
						end
					end
					if clear then
						table.insert(pool, { sl, room })
					end
				end
			end
		end
		return pool
	end
	local pool = poolIn(rooms)
	if #pool == 0 and startRoom then
		pool = poolIn({ startRoom }) -- (a floor with no room behind its first lock)
	end
	if #pool == 0 then
		return
	end
	local pick = pool[math.random(1, #pool)]
	local sl = pick[1]
	RoundState:SetAttribute("MusicBoxRoom", pick[2].name)
	table.insert(state.extraTaken, { sl[1], sl[2] })
	local at = House.at(sl[1], sl[2], 0)
	local mdl = Instance.new("Model")
	mdl.Name = "MusicBox"
	local function piece(props)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Material = Enum.Material.SmoothPlastic
		for k, v in pairs(props) do
			p[k] = v
		end
		p.Parent = mdl
		return p
	end
	local box = piece({ Name = "Box", Size = Vector3.new(2, 1.2, 1.4), Position = at + Vector3.new(0, 0.6, 0), Color = Color3.fromRGB(150, 90, 170), CanCollide = true })
	piece({ Name = "Lid", Size = Vector3.new(2, 0.2, 1.4), CFrame = CFrame.new(at + Vector3.new(0, 1.55, -0.55)) * CFrame.Angles(math.rad(-70), 0, 0), Color = Color3.fromRGB(120, 70, 140) })
	piece({ Name = "Dancer", Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.6, 0.4), Position = at + Vector3.new(0, 1.5, 0.1), Color = Color3.fromRGB(255, 220, 120), Material = Enum.Material.Neon })
	piece({ Name = "Key", Size = Vector3.new(0.15, 0.5, 0.5), Position = at + Vector3.new(1.1, 0.7, 0), Color = Color3.fromRGB(230, 190, 80), Material = Enum.Material.Metal })
	local note = Instance.new("BillboardGui")
	note.Size = UDim2.fromOffset(40, 40)
	note.StudsOffset = Vector3.new(0, 2.6, 0)
	note.Parent = box
	local nt = Instance.new("TextLabel")
	nt.Size = UDim2.fromScale(1, 1)
	nt.BackgroundTransparency = 1
	nt.TextScaled = true
	nt.Text = "\u{1F3B5}"
	nt.Parent = note
	mdl.Parent = world.root
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Listen"
	pp.ObjectText = "Music box - Harmony"
	pp.HoldDuration = Config.HARMONY.listen
	pp.MaxActivationDistance = 9
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Only", "harmony")
	pp.Parent = box
	pp.Triggered:Connect(function(plr)
		if state ~= myState or world ~= myWorld or state.status ~= "playing" or plr:GetAttribute("Skill") ~= "harmony" then
			return
		end
		pp.Enabled = false
		nt.Text = "\u{1F3B6}"
		quest(plr, "skill")
		revealAll(plr, "\u{1F3B5} The music box played the door code for Harmony!")
	end)
end

function round.placeCloudSpots()
	local C = Config.CLOUD
	local myState, myWorld = state, world
	local taken = {}
	for _, o in pairs(world.objects) do
		if o.def and o.def.x then
			table.insert(taken, { o.def.x, o.def.y })
		end
	end
	for _, t in ipairs(state.extraTaken or {}) do
		table.insert(taken, t)
	end
	local pool = {}
	for _, sl in ipairs(HouseMap.floorSlots or {}) do
		local x, y = sl[1], sl[2]
		local clear = not nearDoorway(x, y)
		for _, t in ipairs(taken) do
			if math.abs(t[1] - x) <= 1 and math.abs(t[2] - y) <= 1 then
				clear = false
			end
		end
		if clear then
			for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
				if cellAt(x + d[1], y + d[2]) == "#" then
					table.insert(pool, { x = x, y = y, d = d })
					break
				end
			end
		end
	end
	local spots = {}
	while #spots < C.spots and #pool > 0 do
		local s = table.remove(pool, math.random(1, #pool))
		local spaced = true
		for _, o in ipairs(spots) do
			if math.abs(o.x - s.x) + math.abs(o.y - s.y) < 8 then
				spaced = false
			end
		end
		if spaced then
			table.insert(spots, s)
			table.insert(state.extraTaken, { s.x, s.y })
		end
	end
	if RunService:IsStudio() then
		print("[Cloud] high shelves on this floor: " .. #spots) -- (4 Nov: Brent saw none)
	end
	for i, s in ipairs(spots) do
		local wall = Vector3.new(s.d[1], 0, s.d[2])
		local base = House.at(s.x, s.y, 0) + wall * (T / 2 - 1)
		local high = Config.WALL_H - 4
		local m = Instance.new("Model")
		m.Name = "CloudShelf"
		local function piece(props)
			local p = Instance.new("Part")
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.Material = Enum.Material.SmoothPlastic
			for k, v in pairs(props) do
				p[k] = v
			end
			p.Parent = m
			return p
		end
		local face = CFrame.lookAt(base, base - wall) -- facing out of the wall
		local shelf = piece({ Name = "Shelf", Size = Vector3.new(4, 0.4, 2), CFrame = face * CFrame.new(0, high, 0), Color = Color3.fromRGB(150, 110, 75), Material = Enum.Material.Wood })
		-- the cloud mark on the wall above
		for k, off in ipairs({ { -0.7, 0 }, { 0, 0.35 }, { 0.7, 0 } }) do
			piece({ Name = "CloudMark", Shape = Enum.PartType.Ball, Size = Vector3.new(1.1, 0.9, 0.3) * (k == 2 and 1.2 or 1), CFrame = face * CFrame.new(off[1], high + 1.9 + off[2], 0.9), Color = Color3.fromRGB(235, 245, 255), Material = Enum.Material.Neon })
		end
		-- on the shelf: a free clue (a lightbulb) or a present (points for everyone)
		local clue = i % 2 == 1
		if clue then
			piece({ Name = "ClueBulb", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.9, 0.8), CFrame = face * CFrame.new(0, high + 0.65, 0), Color = Color3.fromRGB(255, 220, 90), Material = Enum.Material.Neon })
		else
			piece({ Name = "ShelfPresent", Size = Vector3.new(1, 0.9, 1), CFrame = face * CFrame.new(0, high + 0.65, 0), Color = Color3.fromRGB(70, 140, 255) })
			piece({ Name = "ShelfRibbon", Size = Vector3.new(1.05, 0.95, 0.2), CFrame = face * CFrame.new(0, high + 0.65, 0), Color = Color3.fromRGB(255, 210, 63) })
		end
		m.Parent = world.root
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Float up"
		pp.ObjectText = clue and "High shelf - a clue" or "High shelf - a present"
		pp.HoldDuration = C.floatHold
		pp.MaxActivationDistance = high + 3
		pp.RequiresLineOfSight = false
		pp:SetAttribute("Only", "cloud")
		pp.Parent = shelf
		pp.Triggered:Connect(function(plr)
			if state ~= myState or world ~= myWorld or state.status ~= "playing" or plr:GetAttribute("Skill") ~= "cloud"
				or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") or not m.Parent then
				return
			end
			-- she floats up to the shelf and back down
			local h = hrpOf(plr)
			if h then
				local from = h.CFrame
				h.Anchored = true
				local up = TweenService:Create(h, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { CFrame = from + Vector3.new(0, high - 3, 0) })
				up:Play()
				up.Completed:Wait()
				local down = TweenService:Create(h, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { CFrame = from })
				down:Play()
				down.Completed:Wait()
				if not plr:GetAttribute("Hidden") then
					h.Anchored = false
				end
			end
			if not m.Parent then
				return
			end
			m:Destroy()
			quest(plr, "skill")
			if clue then
				state.cluesLeft += 1
				state.freeClues = (state.freeClues or 0) + 1
				RoundState:SetAttribute("CluesLeft", state.cluesLeft)
				RoundState:SetAttribute("FreeClues", state.freeClues)
				say("info", "\u{2601} " .. plr.DisplayName .. " floated up to a high shelf - a free clue for the team!")
			else
				for _, p in ipairs(Players:GetPlayers()) do
					if not p:GetAttribute("Escaped") then
						addPoints(p, C.spotPoints)
					end
				end
				say("info", "\u{2601} " .. plr.DisplayName .. " floated up to a high shelf - a present: +" .. C.spotPoints .. " points for everyone!")
			end
		end)
	end
end

function round.placeCandyCorn()
	local e = Seasons.active()
	if not e then
		return
	end
	local myState, myWorld = state, world
	local map = HouseMap
	local taken = {}
	for _, o in pairs(world.objects) do
		if o.def and o.def.x then
			table.insert(taken, { o.def.x, o.def.y })
		end
	end
	for _, t in ipairs(state.extraTaken or {}) do
		table.insert(taken, t)
	end
	table.insert(taken, map.cake)
	for _, p in ipairs(map.pads or {}) do
		table.insert(taken, p)
	end
	local function free(x, y)
		for _, t in ipairs(taken) do
			if math.abs(t[1] - x) <= 1 and math.abs(t[2] - y) <= 1 then
				return false
			end
		end
		return true
	end
	local pool = {}
	for _, sl in ipairs(map.floorSlots or {}) do
		if not nearDoorway(sl[1], sl[2]) and free(sl[1], sl[2]) then
			table.insert(pool, sl)
		end
	end
	local corns = {}
	while #corns < e.perFloor and #pool > 0 do
		local sl = table.remove(pool, math.random(1, #pool))
		local spaced = free(sl[1], sl[2])
		for _, c in ipairs(corns) do
			if math.abs(c.x - sl[1]) + math.abs(c.y - sl[2]) < 6 then
				spaced = false
			end
		end
		if spaced then
			table.insert(corns, { x = sl[1], y = sl[2] })
			table.insert(taken, { sl[1], sl[2] })
		end
	end
	for _, c in ipairs(corns) do
		local pos = House.at(c.x, c.y, 2.2)
		local m = Instance.new("Model")
		m.Name = e.item == "corn" and "CandyCorn" or e.item == "cane" and "CandyCane" or "Golden" .. string.upper(string.sub(e.item, 1, 1)) .. string.sub(e.item, 2)
		-- a candy corn: a rounded yellow base, an orange middle, a white tip,
		-- each band narrower than the one below; it bobs and glows
		local YEL, ORA, WHI = Color3.fromRGB(255, 205, 40), Color3.fromRGB(255, 130, 25), Color3.fromRGB(255, 250, 240)
		local bands = {
			{ Enum.PartType.Ball, Vector3.new(2.1, 1, 2.1), -0.75, YEL },
			{ Enum.PartType.Cylinder, Vector3.new(0.8, 2, 2), -0.4, YEL },
			{ Enum.PartType.Cylinder, Vector3.new(0.75, 1.55, 1.55), 0.35, ORA },
			{ Enum.PartType.Cylinder, Vector3.new(0.6, 1.05, 1.05), 1.0, WHI },
			{ Enum.PartType.Ball, Vector3.new(0.75, 0.75, 0.75), 1.35, WHI },
		}
		if e.item == "feather" then
			-- a golden feather (Thanksgiving): a tall flat gold vane with a pale
			-- middle stripe, on a short quill; it bobs and glows the same way
			local GOLD, PALE, QUILL = Color3.fromRGB(255, 196, 46), Color3.fromRGB(255, 236, 160), Color3.fromRGB(214, 150, 40)
			bands = {
				{ Enum.PartType.Ball, Vector3.new(0.45, 2.8, 1.4), 0.35, GOLD },
				{ Enum.PartType.Ball, Vector3.new(0.5, 2.4, 0.3), 0.4, PALE },
				{ Enum.PartType.Cylinder, Vector3.new(1.1, 0.2, 0.2), -1.35, QUILL },
			}
		elseif e.item == "cane" then
			-- a candy cane (Christmas, 3 Nov): a white stick with red stripes and
			-- a hook of balls curling over at the top (the 5th value: sideways)
			local WHITE, RED = Color3.fromRGB(255, 252, 248), Color3.fromRGB(220, 30, 45)
			bands = {
				{ Enum.PartType.Cylinder, Vector3.new(2.6, 0.5, 0.5), -0.2, WHITE },
				{ Enum.PartType.Cylinder, Vector3.new(0.25, 0.56, 0.56), -1.1, RED },
				{ Enum.PartType.Cylinder, Vector3.new(0.25, 0.56, 0.56), -0.45, RED },
				{ Enum.PartType.Cylinder, Vector3.new(0.25, 0.56, 0.56), 0.2, RED },
				{ Enum.PartType.Cylinder, Vector3.new(0.25, 0.56, 0.56), 0.8, RED },
				{ Enum.PartType.Ball, Vector3.new(0.52, 0.52, 0.52), 1.25, WHITE, 0 },
				{ Enum.PartType.Ball, Vector3.new(0.52, 0.52, 0.52), 1.55, RED, 0.15 },
				{ Enum.PartType.Ball, Vector3.new(0.52, 0.52, 0.52), 1.72, WHITE, 0.5 },
				{ Enum.PartType.Ball, Vector3.new(0.52, 0.52, 0.52), 1.55, RED, 0.85 },
				{ Enum.PartType.Ball, Vector3.new(0.52, 0.52, 0.52), 1.25, WHITE, 1.0 },
				{ Enum.PartType.Ball, Vector3.new(0.52, 0.52, 0.52), 0.92, RED, 1.05 },
			}
		end
		local parts = {}
		for _, bd in ipairs(bands) do
			local pt = Instance.new("Part")
			pt.Anchored, pt.CanCollide, pt.CanTouch, pt.CanQuery, pt.CastShadow = true, false, false, false, false
			pt.Shape = bd[1]
			pt.Size = bd[2]
			Shapes.fix(pt, bd[1], bd[2])
			pt.CFrame = CFrame.new(pos + Vector3.new(bd[5] or 0, bd[3], 0)) * (bd[1] == Enum.PartType.Cylinder and CFrame.Angles(0, 0, math.rad(90)) or CFrame.new())
			pt.Color = bd[4]
			pt.Material = Enum.Material.SmoothPlastic
			pt.Parent = m
			table.insert(parts, pt)
		end
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 160, 60), 8, 0.9
		l.Parent = parts[3]
		m.Parent = world.root
		for _, pt in ipairs(parts) do
			TweenService:Create(pt, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = pt.CFrame + Vector3.new(0, 0.6, 0) }):Play()
		end
		c.model, c.pos = m, pos
	end
	if #corns == 0 then
		return
	end
	task.spawn(function()
		while state == myState and world == myWorld and state.status == "playing" do
			task.wait(0.25)
			for _, c in ipairs(corns) do
				if c.model and c.model.Parent then
					for _, plr in ipairs(Players:GetPlayers()) do
						local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
						if c.model and h and not plr:GetAttribute("Caged") and not plr:GetAttribute("Escaped")
							and (h.Position - c.pos).Magnitude < e.near + 2 then
							c.model:Destroy()
							c.model = nil
							addPoints(plr, e.points, true)
							local data = Profile.get(plr)
							local n = 0
							if data then
								data.stats[e.item] = (data.stats[e.item] or 0) + 1
								n = data.stats[e.item]
								Profile.publish(plr)
							end
							-- share (Thanksgiving's feathers): it counts for everyone else in the party too
							if e.share then
								for _, other in ipairs(Players:GetPlayers()) do
									local od = other ~= plr and Profile.get(other)
									if od then
										od.stats[e.item] = (od.stats[e.item] or 0) + 1
										Profile.publish(other)
									end
								end
							end
							Effects.burst(c.pos, "boost", "collect")
							local One = string.upper(string.sub(e.one, 1, 1)) .. string.sub(e.one, 2)
							say("corn", One .. " found! " .. n .. " so far (+" .. e.points .. " points)", { userId = plr.UserId, found = n, item = e.item }, plr)
							if e.goal and e.badgeName and n == e.goal then
								say("info", e.icon .. " " .. plr.DisplayName .. " found " .. e.goal .. " " .. e.many .. " - " .. e.badgeName .. "!")
							end
							local have = data and Seasons.have(data.stats, e) or 0
							for _, skin in ipairs(Config.SKINS or {}) do
								local price = skin[e.item]
								if type(price) == "number" and have == price and not skin.hidden and not (data.skinsEarned and data.skinsEarned[skin.id]) then
									say("info", e.icon .. " " .. price .. " " .. e.many .. " to spend - get " .. skin.name .. " in the Lobby's " .. e.shopName .. "!", nil, plr)
								end
							end
							local badge = e.badge and Config.BADGES[e.badge] or 0
							if e.goal and n >= e.goal and badge > 0 then
								task.spawn(pcall, function()
									game:GetService("BadgeService"):AwardBadge(plr.UserId, badge)
								end)
							end
						end
					end
				end
			end
		end
	end)
end

-- the Turkey Roundup (Thanksgiving, on the Harvest Barn floor - Brent, 11 Oct):
-- the stall gates stand open, the keys and the code aren't needed; little
-- runaway turkeys hide round the barn and run from any kid who comes near
-- (a bit slower than running, so the crew corners them together); every one
-- caught counts toward the Turkey Wrangler badge (Config.ROUNDUP.goal) - for
-- the whole party with `share` - and once all are caught the big barn doors
-- swing open.
function round.placeTurkeys()
	state.roundup = nil
	RoundState:SetAttribute("Roundup", nil)
	local R = Config.ROUNDUP
	if not R or HouseMap.theme ~= "barn" then
		return
	end
	local myState, myWorld = state, world
	state.roundup = { caught = 0, total = 0 }
	-- the stall gates stand open from the start; no keypad on the big doors
	for id, entry in pairs(world.objects) do
		if entry.def and entry.def.kind == "lock" and not entry.def.bonus and not world.unlocked[id] then
			world.unlocked[id] = true
			RoundState:SetAttribute("Lock_" .. id, true)
			entry.part.CanCollide = false
			entry.part.Position += Vector3.new(0, 13, 0)
			for _, k in ipairs({ "unlockPrompt", "pickPrompt", "shovePrompt", "popperPrompt" }) do
				if entry[k] then
					entry[k].Enabled = false
				end
			end
			if entry.lockPart then
				entry.lockPart:Destroy()
			end
			for _, p in ipairs(entry.pile or {}) do
				p:Destroy()
			end
			if entry.giftPrompt then
				entry.giftPrompt.Enabled = true
			end
		end
	end
	local door = world.objects.door
	if door then
		for _, k in ipairs({ "usePrompt", "padPrompt" }) do
			if door[k] then
				door[k].Enabled = false
			end
		end
	end
	-- where they hide: free floor slots, spread round the barn
	local taken = {}
	for _, o in pairs(world.objects) do
		if o.def and o.def.x then
			table.insert(taken, { o.def.x, o.def.y })
		end
	end
	for _, t in ipairs(state.extraTaken or {}) do
		table.insert(taken, t)
	end
	local pool = {}
	for _, sl in ipairs(HouseMap.floorSlots or {}) do
		local ok = true
		for _, t in ipairs(taken) do
			if math.abs(t[1] - sl[1]) <= 1 and math.abs(t[2] - sl[2]) <= 1 then
				ok = false
			end
		end
		if ok then
			table.insert(pool, sl)
		end
	end
	local spots = {}
	while #spots < R.turkeys and #pool > 0 do
		local sl = table.remove(pool, math.random(1, #pool))
		local spaced = true
		for _, s in ipairs(spots) do
			if math.abs(s[1] - sl[1]) + math.abs(s[2] - sl[2]) < 5 then
				spaced = false
			end
		end
		if spaced then
			table.insert(spots, sl)
			table.insert(state.extraTaken, { sl[1], sl[2] })
		end
	end
	-- the turkey: the imported model (Characters/Turkey), else a built one
	local src = game:GetService("ServerStorage"):FindFirstChild("Characters")
	src = src and src:FindFirstChild("Turkey")
	if not src and (Config.TURKEY_ASSET or 0) > 0 then
		-- the turkey saved to Roblox (Config.TURKEY_ASSET)
		local ok, box = pcall(function()
			return game:GetService("InsertService"):LoadAsset(Config.TURKEY_ASSET)
		end)
		src = ok and box and box:FindFirstChildWhichIsA("Model", true) or nil
		if not src and ok and box then
			src = box -- the asset's own container holds the parts
		end
	end
	local function makeTurkey()
		local m
		if src then
			m = src:Clone()
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Humanoid") then
					d:Destroy()
				end
			end
		else
			m = Instance.new("Model")
			local function bit(shape, size, pos, color)
				local p = Instance.new("Part")
				p.Shape, p.Size, p.Color = shape, size, color
				Shapes.fix(p, shape, size)
				p.Material = Enum.Material.SmoothPlastic
				p.CFrame = CFrame.new(pos)
				p.Parent = m
				return p
			end
			local BROWN, CREAM, ORANGE = Color3.fromRGB(126, 72, 40), Color3.fromRGB(246, 222, 180), Color3.fromRGB(255, 140, 30)
			bit(Enum.PartType.Ball, Vector3.new(2.4, 2.2, 2.4), Vector3.new(0, 1.6, 0), BROWN)
			bit(Enum.PartType.Ball, Vector3.new(1.4, 1.4, 0.8), Vector3.new(0, 1.5, 0.95), CREAM)
			bit(Enum.PartType.Ball, Vector3.new(1.3, 1.3, 1.3), Vector3.new(0, 2.9, 0.6), BROWN)
			bit(Enum.PartType.Ball, Vector3.new(0.4, 0.3, 0.6), Vector3.new(0, 2.8, 1.3), ORANGE)
			for i = -2, 2 do
				local col = ({ Color3.fromRGB(214, 58, 40), ORANGE, Color3.fromRGB(255, 206, 60) })[i % 3 + 1]
				local f = bit(Enum.PartType.Ball, Vector3.new(0.8, 2.2, 0.4), Vector3.new(0, 2.4, -1.1), col)
				f.CFrame = CFrame.new(0, 1.8, -1.1) * CFrame.Angles(0, 0, math.rad(i * 25)) * CFrame.new(0, 0.9, 0)
			end
		end
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
			end
		end
		local _, size = m:GetBoundingBox()
		if size.Y > 0 then
			m:ScaleTo(m:GetScale() * R.height / size.Y)
		end
		return m
	end
	-- the imported toons face +Z (paint_toon), the built one too; PivotTo with
	-- lookAt faces -Z, so turn it round
	local TURN = CFrame.Angles(0, math.pi, 0)
	local turkeys = {}
	for _, sl in ipairs(spots) do
		local m = makeTurkey()
		m.Name = "RunawayTurkey"
		m.Parent = world.root
		local cf, size = m:GetBoundingBox()
		local lift = m:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
		local pos = House.at(sl[1], sl[2], 0)
		local t = { model = m, pos = pos, lift = lift, face = Vector3.new(0, 0, 1), busyUntil = 0 }
		m:PivotTo(CFrame.lookAt(pos + Vector3.new(0, lift, 0), pos + Vector3.new(0, lift, 0) + t.face) * TURN)
		table.insert(turkeys, t)
	end
	state.roundup.total = #turkeys
	RoundState:SetAttribute("Roundup", "0/" .. #turkeys)
	if #turkeys == 0 then
		return
	end
	-- how far a turkey can run that way before a wall or furniture
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local function runTo(from, dir, most)
		local skip = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		for _, hh in ipairs(liveHosts()) do
			table.insert(skip, hh.model)
		end
		params.FilterDescendantsInstances = skip
		local eye = from + Vector3.new(0, 1.5, 0)
		local hit = workspace:Raycast(eye, dir * most, params)
		local d = hit and math.max(0, (hit.Position - eye).Magnitude - 2.5) or most
		return from + dir * d, d
	end
	local function move(t, to, speed)
		local from = t.pos
		local dist = (to - from).Magnitude
		if dist < 0.5 then
			return
		end
		local seconds = dist / speed
		t.face = (to - from).Unit
		t.busyUntil = os.clock() + seconds
		t.moving = (t.moving or 0) + 1
		local mine = t.moving
		task.spawn(function()
			local start = os.clock()
			while t.model.Parent and t.moving == mine do
				local a = math.min(1, (os.clock() - start) / seconds)
				t.pos = from:Lerp(to, a)
				-- a little hop as it runs
				local hop = math.abs(math.sin(a * seconds * 9)) * 0.6
				local p = t.pos + Vector3.new(0, t.lift + hop, 0)
				t.model:PivotTo(CFrame.lookAt(p, p + t.face) * TURN)
				if a >= 1 then
					break
				end
				task.wait()
			end
		end)
	end
	local function catch(t, plr)
		t.moving = (t.moving or 0) + 1
		local at = t.pos
		t.model:Destroy()
		Effects.burst(at + Vector3.new(0, 1.5, 0), "boost", "collect")
		state.roundup.caught += 1
		local n, total = state.roundup.caught, state.roundup.total
		RoundState:SetAttribute("Roundup", n .. "/" .. total)
		addPoints(plr, R.points, true)
		-- the badge count: the catcher, or the whole party (share)
		local who = R.share and Players:GetPlayers() or { plr }
		local feastKey = FeastMeter.key()
		for _, p in ipairs(who) do
			local data = Profile.get(p)
			if data then
				data.stats.turkey = (data.stats.turkey or 0) + 1
				-- took part this season: shares the Feast Meter's rewards (Brent, 11 Oct)
				if feastKey then
					data.feastJoined = data.feastJoined or {}
					data.feastJoined[feastKey] = true
				end
				Profile.publish(p)
				local badge = Config.BADGES.turkey or 0
				if data.stats.turkey == R.goal then
					say("info", "\u{1F983} " .. p.DisplayName .. " has caught " .. R.goal .. " turkeys - Turkey Wrangler!")
				end
				if data.stats.turkey >= R.goal and badge > 0 then
					task.spawn(pcall, function()
						game:GetService("BadgeService"):AwardBadge(p.UserId, badge)
					end)
				end
			end
		end
		FeastMeter.add(1) -- the community goal: every turkey in every server
		say("corn", "Gobble! " .. plr.DisplayName .. " caught a runaway turkey! " .. n .. " of " .. total, { userId = plr.UserId, found = n, item = "turkey" })
		if n >= total then
			openDoor(plr, "turkeys")
		end
	end
	task.spawn(function()
		while state == myState and world == myWorld and state.status == "playing" do
			task.wait(0.1)
			local kids = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local h = hrpOf(p)
				if h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and not p:GetAttribute("Waiting") then
					table.insert(kids, { plr = p, pos = h.Position })
				end
			end
			for _, t in ipairs(turkeys) do
				if not t.model.Parent then
					continue
				end
				local near, nd = nil, math.huge
				for _, k in ipairs(kids) do
					local d = (Vector3.new(k.pos.X, 0, k.pos.Z) - Vector3.new(t.pos.X, 0, t.pos.Z)).Magnitude
					if d < nd then
						near, nd = k, d
					end
				end
				if near and nd <= R.catch then
					catch(t, near.plr)
				elseif near and nd < R.flee and os.clock() >= t.busyUntil - 0.15 then
					-- run: of a few ways away from the kid, the one that ends furthest from them
					local away = Vector3.new(t.pos.X - near.pos.X, 0, t.pos.Z - near.pos.Z)
					away = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
					local best, bestScore = nil, -math.huge
					for _, deg in ipairs({ 0, 35, -35, 70, -70, 110, -110 }) do
						local dir = (CFrame.Angles(0, math.rad(deg), 0) * CFrame.new(away)).Position
						local to, d = runTo(t.pos, dir, 10)
						if d >= 2 then
							local kid = Vector3.new(near.pos.X, 0, near.pos.Z)
							local score = (Vector3.new(to.X, 0, to.Z) - kid).Magnitude + d * 0.2
							if score > bestScore then
								best, bestScore = to, score
							end
						end
					end
					if best then
						move(t, best, R.speed)
					end
				elseif os.clock() >= t.busyUntil + 1.5 and math.random() < 0.03 then
					-- pecking about: a short stroll
					local a = math.random() * math.pi * 2
					local to, d = runTo(t.pos, Vector3.new(math.cos(a), 0, math.sin(a)), 5)
					if d >= 2 then
						move(t, to, 4)
					end
				end
			end
		end
	end)
end

-- hit by a thrown pumpkin: knocked flat for a moment
-- the Present Hunt (Claus Manor, Christmas - Brent 5 Nov, CLAUS_MANOR.md):
-- the locked doors stand open and the keypad is off; real presents and decoys
-- look the same round the floor. A real one counts (the big door swings open
-- once all are found) and adds to the opener's Elfy count; a decoy lets out
-- a Toy Elf who runs from kids jingling - every jingle tells the Clauses
-- where he is - until he is tagged or his time runs out.
function round.placePresents()
	state.presentHunt = nil
	RoundState:SetAttribute("Presents", nil)
	local P = Config.PRESENT_HUNT
	if not P or HouseMap.theme ~= "claus" then
		return
	end
	local myState, myWorld = state, world
	local mi = Progress.mapIndex(RoundState:GetAttribute("Map") or "")
	local fl = (mi and Progress.MAPS[mi].floor) or 1
	local nReal, nDecoy = P.real[fl] or P.real[1], P.decoys[fl] or P.decoys[1]
	-- the locked doors stand open from the start; no keypad on the big door
	for id, entry in pairs(world.objects) do
		if entry.def and entry.def.kind == "lock" and not entry.def.bonus and not world.unlocked[id] then
			world.unlocked[id] = true
			RoundState:SetAttribute("Lock_" .. id, true)
			entry.part.CanCollide = false
			entry.part.Position += Vector3.new(0, 13, 0)
			for _, k in ipairs({ "unlockPrompt", "pickPrompt", "shovePrompt", "popperPrompt" }) do
				if entry[k] then
					entry[k].Enabled = false
				end
			end
			if entry.lockPart then
				entry.lockPart:Destroy()
			end
			for _, p in ipairs(entry.pile or {}) do
				p:Destroy()
			end
			if entry.giftPrompt then
				entry.giftPrompt.Enabled = true
			end
		end
	end
	local door = world.objects.door
	if door then
		for _, k in ipairs({ "usePrompt", "padPrompt" }) do
			if door[k] then
				door[k].Enabled = false
			end
		end
	end
	-- where they sit: free floor slots, spread round the floor
	local taken = {}
	for _, o in pairs(world.objects) do
		if o.def and o.def.x then
			table.insert(taken, { o.def.x, o.def.y })
		end
	end
	for _, t in ipairs(state.extraTaken or {}) do
		table.insert(taken, t)
	end
	local pool = {}
	for _, sl in ipairs(HouseMap.floorSlots or {}) do
		local ok = true
		for _, t in ipairs(taken) do
			if math.abs(t[1] - sl[1]) <= 1 and math.abs(t[2] - sl[2]) <= 1 then
				ok = false
			end
		end
		if ok then
			table.insert(pool, sl)
		end
	end
	local spots = {}
	local gapNeeded = 4
	while #spots < nReal + nDecoy and #pool > 0 do
		local sl = table.remove(pool, math.random(1, #pool))
		local spaced = true
		for _, s in ipairs(spots) do
			if math.abs(s[1] - sl[1]) + math.abs(s[2] - sl[2]) < gapNeeded then
				spaced = false
			end
		end
		if spaced then
			table.insert(spots, sl)
			table.insert(state.extraTaken, { sl[1], sl[2] })
		end
	end
	nReal = math.min(nReal, #spots)
	state.presentHunt = { found = 0, total = nReal }
	RoundState:SetAttribute("Presents", "0/" .. nReal)
	if nReal == 0 then
		state.presentHunt = nil -- nowhere to put them: an ordinary door
		RoundState:SetAttribute("Presents", nil)
		return
	end
	-- which are real: the first nReal of a shuffled list
	for i = #spots, 2, -1 do
		local j = math.random(1, i)
		spots[i], spots[j] = spots[j], spots[i]
	end
	local WRAPS = { Color3.fromRGB(214, 40, 50), Color3.fromRGB(40, 150, 80), Color3.fromRGB(60, 110, 220), Color3.fromRGB(240, 196, 60), Color3.fromRGB(150, 70, 190) }
	local RIBBON = { Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 255, 255), Color3.fromRGB(240, 60, 70) }
	local folder = Instance.new("Folder")
	folder.Name = "HuntPresents"
	folder.Parent = world.root

	-- the Toy Elf: the imported toy (Characters/ToyElf, once saved), else a built one
	local chars = game:GetService("ServerStorage"):FindFirstChild("Characters")
	local src = chars and chars:FindFirstChild("ToyElf")
	local function makeElf()
		local m
		if src then
			m = src:Clone()
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Humanoid") then
					d:Destroy()
				end
			end
		else
			m = Instance.new("Model")
			local function bit(shape, size, pos, color)
				local p = Instance.new("Part")
				p.Shape, p.Size, p.Color = shape, size, color
				Shapes.fix(p, shape, size)
				p.Material = Enum.Material.SmoothPlastic
				p.CFrame = CFrame.new(pos)
				p.Parent = m
				return p
			end
			local RED, GREEN, SKIN = Color3.fromRGB(214, 40, 50), Color3.fromRGB(50, 160, 80), Color3.fromRGB(255, 214, 180)
			bit(Enum.PartType.Ball, Vector3.new(1.8, 1.9, 1.6), Vector3.new(0, 1.3, 0), GREEN)
			bit(Enum.PartType.Ball, Vector3.new(1.4, 1.4, 1.4), Vector3.new(0, 2.7, 0), SKIN)
			bit(Enum.PartType.Ball, Vector3.new(1.3, 1.1, 1.3), Vector3.new(0, 3.4, 0), RED)
			bit(Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, 4.0, 0), Color3.fromRGB(255, 255, 255))
			bit(Enum.PartType.Ball, Vector3.new(0.25, 0.25, 0.25), Vector3.new(-0.3, 2.8, 0.65), Color3.fromRGB(20, 20, 24))
			bit(Enum.PartType.Ball, Vector3.new(0.25, 0.25, 0.25), Vector3.new(0.3, 2.8, 0.65), Color3.fromRGB(20, 20, 24))
			bit(Enum.PartType.Block, Vector3.new(0.3, 1.0, 0.3), Vector3.new(0, 1.5, -0.95), Color3.fromRGB(240, 196, 60))
			bit(Enum.PartType.Block, Vector3.new(1.0, 0.3, 0.3), Vector3.new(0, 1.9, -1.1), Color3.fromRGB(240, 196, 60))
		end
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
			end
		end
		local _, size = m:GetBoundingBox()
		if size.Y > 0 then
			m:ScaleTo(m:GetScale() * P.elfHeight / size.Y)
		end
		return m
	end
	local TURN = CFrame.Angles(0, math.pi, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local function runTo(from, dir, most)
		local skip = { folder }
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		for _, h in ipairs({ host, host2 }) do
			if h and h.model then
				table.insert(skip, h.model)
			end
		end
		params.FilterDescendantsInstances = skip
		local eye = from + Vector3.new(0, 1.2, 0)
		local hit = workspace:Raycast(eye, dir * most, params)
		local d = hit and math.max(0, (hit.Position - eye).Magnitude - 2.5) or most
		return from + dir * d, d
	end
	local function releaseElf(at, opener)
		local m = makeElf()
		m.Name = "ToyElf"
		m.Parent = folder
		local cf, size = m:GetBoundingBox()
		local lift = m:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
		local e = { model = m, pos = at, face = Vector3.new(0, 0, 1), moving = 0 }
		m:PivotTo(CFrame.lookAt(at + Vector3.new(0, lift, 0), at + Vector3.new(0, lift, 1)) * TURN)
		say("info", "\u{1F514} A decoy! A Toy Elf jumped out and is jingling for the Clauses - tag him to stop him!", { userId = opener and opener.UserId })
		local endsAt = os.clock() + P.elfTime
		local nextJingle = 0
		local function gone(tagger)
			if not m.Parent then
				return
			end
			e.moving += 1
			local pos = e.pos
			m:Destroy()
			Effects.burst(pos + Vector3.new(0, 1.5, 0), "light")
			if tagger then
				addPoints(tagger, P.elfPoints, true)
				say("info", "\u{1F9DD} " .. tagger.DisplayName .. " tagged the Toy Elf - quiet again!", { userId = tagger.UserId })
			end
		end
		task.spawn(function()
			while m.Parent and state == myState and world == myWorld and state.status == "playing" do
				local now = os.clock()
				if now >= endsAt then
					gone(nil)
					break
				end
				-- the jingle: every host hears where he is
				if now >= nextJingle then
					nextJingle = now + P.jingle
					Effects.sound(e.pos, "bell", 0.8)
					Effects.burst(e.pos + Vector3.new(0, 2, 0), "noise", false)
					alertHosts(e.pos)
				end
				-- run from the nearest kid; tagged when one catches him
				local near, nd = nil, math.huge
				for _, p in ipairs(Players:GetPlayers()) do
					local h = hrpOf(p)
					if h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and not p:GetAttribute("Waiting") then
						local d = (Vector3.new(h.Position.X, 0, h.Position.Z) - Vector3.new(e.pos.X, 0, e.pos.Z)).Magnitude
						if d < nd then
							near, nd = p, d
						end
					end
				end
				if near and nd <= P.catch then
					gone(near)
					break
				end
				if near and nd < P.flee and (e.busyUntil or 0) <= now then
					local h = hrpOf(near)
					local away = Vector3.new(e.pos.X - h.Position.X, 0, e.pos.Z - h.Position.Z)
					away = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
					-- the most open way roughly away from the kid
					local bestTo, bestD = nil, -1
					for _, a in ipairs({ 0, 35, -35, 70, -70, 110, -110 }) do
						local dir = (CFrame.Angles(0, math.rad(a), 0) * away)
						local to, d = runTo(e.pos, dir, 12)
						if d > bestD then
							bestTo, bestD = to, d
						end
					end
					if bestTo and bestD > 1 then
						local from = e.pos
						local seconds = (bestTo - from).Magnitude / P.speed
						e.face = (bestTo - from).Unit
						e.busyUntil = now + seconds
						e.moving += 1
						local mine = e.moving
						task.spawn(function()
							local start = os.clock()
							while m.Parent and e.moving == mine do
								local a = math.min(1, (os.clock() - start) / seconds)
								e.pos = from:Lerp(bestTo, a)
								local hop = math.abs(math.sin(a * seconds * 10)) * 0.5
								local p = e.pos + Vector3.new(0, lift + hop, 0)
								m:PivotTo(CFrame.lookAt(p, p + e.face) * TURN)
								if a >= 1 then
									break
								end
								task.wait()
							end
						end)
					end
				end
				task.wait(0.1)
			end
			if m.Parent then
				m:Destroy()
			end
		end)
	end

	local function opened(plr, real, box)
		local hunt = state.presentHunt
		local at = box.Position
		box.Parent = nil
		for _, d in ipairs(folder:GetChildren()) do
			if d:GetAttribute("Box") == box.Name then
				d:Destroy()
			end
		end
		box:Destroy()
		if not real then
			Effects.burst(at, "pop")
			releaseElf(Vector3.new(at.X, at.Y - box.Size.Y / 2, at.Z), plr)
			return
		end
		hunt.found += 1
		local n, total = hunt.found, hunt.total
		RoundState:SetAttribute("Presents", n .. "/" .. total)
		Effects.burst(at + Vector3.new(0, 1, 0), "escape", "present")
		addPoints(plr, P.points, true)
		-- the opener's own count (no party share): Elfy at P.goal
		local data = Profile.get(plr)
		if data then
			data.stats.presents = (data.stats.presents or 0) + 1
			local goal = (Config.CHARACTER_UNLOCK.elfy and Config.CHARACTER_UNLOCK.elfy.presents) or P.goal
			local have = data.stats.presents
			data.charsEarned = data.charsEarned or {}
			if have >= goal and not data.charsEarned.elfy then
				data.charsEarned.elfy = true -- kept for good, even after Christmas
				say("info", "\u{1F9DD} " .. plr.DisplayName .. " opened " .. goal .. " presents and won ELFY, the limited-edition elf! Pick him in the Lobby.")
				Effects.at(plr, "pop")
			elseif have < goal and have % 10 == 0 then
				say("info", "\u{1F9DD} Elfy: " .. have .. " of " .. goal .. " presents opened.", nil, plr)
			end
			Profile.publish(plr)
		end
		say("info", "\u{1F381} " .. plr.DisplayName .. " found a present! " .. n .. " of " .. total, { userId = plr.UserId })
		if n >= total then
			say("info", "\u{1F381} Every present found - the door is open!")
			openDoor(plr, "presents")
		end
	end

	for i, sl in ipairs(spots) do
		local real = i <= nReal
		local base = House.at(sl[1], sl[2], 0)
		local s = 2.6
		local wrap = WRAPS[math.random(1, #WRAPS)]
		local ribbon = RIBBON[math.random(1, #RIBBON)]
		local box = Instance.new("Part")
		box.Name = "HuntPresent" .. i
		box.Size = Vector3.new(s * 1.2, s, s * 1.2)
		box.CFrame = CFrame.new(base + Vector3.new(0, s / 2, 0)) * CFrame.Angles(0, math.rad(math.random(0, 89)), 0)
		box.Color = wrap
		box.Material = Enum.Material.SmoothPlastic
		box.Anchored, box.CanCollide = true, true
		box.Parent = folder
		for _, sz in ipairs({ Vector3.new(s * 1.22, s + 0.04, 0.4), Vector3.new(0.4, s + 0.04, s * 1.22) }) do
			local r = Instance.new("Part")
			r.Name = "Ribbon"
			r.Size = sz
			r.CFrame = box.CFrame
			r.Color = ribbon
			r.Material = Enum.Material.SmoothPlastic
			r.Anchored, r.CanCollide, r.CanQuery = true, false, false
			r:SetAttribute("Box", box.Name)
			r.Parent = folder
		end
		local bow = Instance.new("Part")
		bow.Name = "Bow"
		bow.Shape = Enum.PartType.Ball
		bow.Size = Vector3.new(1.1, 0.7, 1.1)
		bow.CFrame = box.CFrame * CFrame.new(0, s / 2 + 0.3, 0)
		bow.Color = ribbon
		bow.Anchored, bow.CanCollide, bow.CanQuery = true, false, false
		bow:SetAttribute("Box", box.Name)
		bow.Parent = folder
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = "Present"
		prompt.HoldDuration = P.hold
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = box
		local done = false
		prompt.Triggered:Connect(function(plr)
			if done or state ~= myState or state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
				return
			end
			done = true
			opened(plr, real, box)
		end)
	end
end

function round.hostHit(_, plr)
	if plr:GetAttribute("Knocked") then
		return
	end
	plr:SetAttribute("Knocked", true)
	plr:SetAttribute("Frozen", true)
	setSpeed(plr, 0)
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = true
	end
	say("bonk", "BONK! " .. plr.DisplayName .. " was hit by a flying pumpkin!", { userId = plr.UserId })
	Effects.react(plr, "bonk", Config.HOST_SKILLS.throw.knock)
	task.delay(Config.HOST_SKILLS.throw.knock, function()
		if hum and hum.Parent then
			hum.PlatformStand = false
		end
		plr:SetAttribute("Knocked", false)
		plr:SetAttribute("Frozen", false)
		if not plr:GetAttribute("Caged") and not plr:GetAttribute("Hidden") then
			setSpeed(plr, Config.WALK)
		end
	end)
end

-- put a caged player in the cage, seen by everyone; they can shuffle round
-- inside it but not jump (the keeper puts anyone who slips out back in)
local function intoCage(plr)
	local h = hrpOf(plr)
	if h then
		h.Anchored = false
	end
	setVisible(plr, true)
	teleport(plr, world.objects.cage.inside)
	setSpeed(plr, Config.CAGE_WALK)
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.JumpPower = 0
	end
	world.objects.cage.prompt.Enabled = true
end

-- Mr Claus's Lump of Coal (5 Nov): slowed, not knocked down
function round.hostCoal(_, plr)
	local s = Config.HOST_SKILLS.coal
	plr:SetAttribute("CoalUntil", workspace:GetServerTimeNow() + s.slow)
	Effects.react(plr, "bonk", s.slow)
	say("bonk", "\u{1FAA8} " .. plr.DisplayName .. " got a lump of coal - slowed down!", { userId = plr.UserId })
end

-- Mrs Claus's Naughty List (5 Nov): for a few seconds every host is told
-- where the kid she saw is
function round.hostNaughty(_, plr)
	local s = Config.HOST_SKILLS.naughty
	local myState = state
	say("info", "\u{1F4DC} Mrs Claus put " .. plr.DisplayName .. " on the Naughty List - the Clauses know where you are! Keep moving!", { userId = plr.UserId })
	Effects.at(plr, "reveal")
	task.spawn(function()
		local ends = os.clock() + s.seconds
		while os.clock() < ends and state == myState and state.status == "playing" do
			local h = hrpOf(plr)
			if not h or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
				break
			end
			-- (5 Nov, Brent) hiding wipes you off the list: a closet or hiding
			-- spot, a present (gift box, Elfy's Wrapped Up), a vent, Cloud's fog
			-- or a sneak skill - the Clauses aren't told where you are
			if plr:GetAttribute("Hidden") or plr:GetAttribute("Crawling") or plr:GetAttribute("Fogged")
				or (plr:GetAttribute("SneakUntil") or 0) > workspace:GetServerTimeNow() then
				say("info", "\u{1F92B} " .. plr.DisplayName .. " hid - off the Naughty List!", { userId = plr.UserId })
				break
			end
			-- (a host chasing by sight keeps chasing; the others come to look,
			-- and she keeps after the kid once they are out of sight)
			alertHosts(h.Position)
			task.wait(s.every)
		end
	end)
end

function round.hostCaught(_, plr)
	local host = steppingHost or host -- (5 Nov) the Claus who caught them
	unhide(plr)
	-- caught in a vent or the laundry chute (only in a frenzy): out of it first
	if plr:GetAttribute("Crawling") then
		plr:SetAttribute("CrawlId", (plr:GetAttribute("CrawlId") or 0) + 1)
		plr:SetAttribute("Crawling", false)
	end
	if state.everCaught and not plr:GetAttribute("Shield") then
		state.everCaught[plr.UserId] = true
	end
	if plr:GetAttribute("Shield") then
		local extra = plr:GetAttribute("ExtraShields") or 0
		if extra > 0 then
			plr:SetAttribute("ExtraShields", extra - 1) -- still shielded once more
		else
			plr:SetAttribute("Shield", false)
		end
		host:stun(2.5)
		Effects.stars(host.model, 2.5)
		Effects.at(plr, "pop", "shieldHit")
		local sh = hrpOf(plr)
		if sh then
			Effects.ring(sh.Position - Vector3.new(0, 2.8, 0), Color3.fromRGB(120, 200, 255), 18, 0.6)
		end
		return say("shield", "POP! " .. plr.DisplayName .. "'s Party Shield saved them - run!")
	end
	Effects.at(plr, "caught")
	do
		local ch = hrpOf(plr)
		if ch then
			Effects.ring(ch.Position - Vector3.new(0, 2.8, 0), Color3.fromRGB(255, 60, 60), 22, 0.7)
		end
	end
	if host then
		host:stun(2.8) -- holds still for the close-up
	end
	plr:SetAttribute("Caged", true)
	intoCage(plr)
	say("caught", plr.DisplayName .. " was caught! Free them from the cage in the " .. roomOf("cage") .. "!",
		{ userId = plr.UserId, host = host and host.model and host.model.Name or nil })
	checkEnd()
end

-- the steps still to do, in order: a clue gives the first (Brainy's
-- Two-Step Clue lights up the second too; Mastermind gives the whole route)
local function clueSteps()
	local o = world.objects
	local list = {}
	local function add(id, text)
		table.insert(list, { id = id, text = text })
	end
	if anyCaged() then
		add("cage", "Free your friend! Stand by the cage in the " .. roomOf("cage") .. ".")
	end
	if state.doorOpen then
		add("door", "The big door is open - everybody out!")
		return list
	end
	local skills = {}
	for _, p in ipairs(playersInRound()) do
		if not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") then
			skills[p:GetAttribute("Skill")] = true
		end
	end
	local function lockHint(id)
		local name = o[id].def.name
		if o[id].def.blocked then
			if skills.muscle then
				return id, "Muscle can shove the junk blocking the " .. name .. "."
			end
			if (world.poppers or 0) > 0 then
				return id, "Plant a Confetti Cannon at the blocked " .. name .. " - it's loud, so be ready to run!"
			end
			for sid, lock in pairs(world.keyIn) do
				if lock == id and not o[sid].searched then
					return sid, "A Confetti Cannon is hidden in the " .. roomOf(sid) .. " - it can blast open the " .. name .. "."
				end
			end
			return id, "The " .. name .. " is blocked. Bring Muscle, or search drawers and boxes for a Confetti Cannon!"
		end
		if skills.tinker then
			return id, "Tinker can pick the lock on the " .. name .. "."
		end
		if world.keys[id] then
			return id, "You found the key - unlock the " .. name .. "!"
		end
		for sid, lock in pairs(world.keyIn) do
			if lock == id and not o[sid].searched then
				return sid, "The key to the " .. name .. " is hidden in the " .. roomOf(sid) .. "."
			end
		end
		return id, "The " .. name .. " is locked. Search drawers and boxes for the key!"
	end
	local known = codeKnown()
	if not known then
		if skills.brainy and o.invite.prompt.Enabled and reachable("invite") then
			add("invite", "Brainy can read the twisty invitation in the " .. roomOf("invite") .. ".")
		elseif skills.glow and o.uv.prompt.Enabled and reachable("uv") then
			add("uv", "Glow can light up the painted wall in the " .. roomOf("uv") .. ".")
		elseif skills.bramble and o.plant.prompt.Enabled and reachable("plant") then
			add("plant", "Bramble can ask the big plant in the " .. roomOf("plant") .. ".")
		else
			for _, id in ipairs({ "b0", "b1", "b2" }) do
				if o[id] and not o[id].popped and reachable(id) then
					add(id, "Pop balloon " .. o[id].def.n .. " in the " .. roomOf(id) .. " - it shows a color of the door code. Careful: some balloons are tricks!")
				end
			end
		end
	end
	if not world.unlocked.L1 then
		add(lockHint("L1"))
	end
	if not world.unlocked.L2 then
		add(lockHint("L2"))
	end
	add("door", known and ("You know the colors! Use the keypad by the big door in the " .. roomOf("door") .. ".") or ("Try the keypad by the big door in the " .. roomOf("door") .. "."))
	return list, skills, lockHint
end

-- Brainy's Mastermind: every step to the exit at once
local function routeText()
	local o = world.objects
	local steps, skills, lockHint = clueSteps()
	local _ = steps
	local parts = {}
	local known = codeKnown()
	if not known then
		if skills.brainy and o.invite.prompt.Enabled then
			table.insert(parts, "read the twisty invitation in the " .. roomOf("invite") .. " (Brainy)")
		elseif skills.glow and o.uv.prompt.Enabled then
			table.insert(parts, "light up the painted wall in the " .. roomOf("uv") .. " (Glow)")
		elseif skills.bramble and o.plant.prompt.Enabled then
			table.insert(parts, "ask the big plant in the " .. roomOf("plant") .. " (Bramble)")
		else
			local rooms, seen = {}, {}
			for _, id in ipairs({ "b0", "b1", "b2" }) do
				if o[id] and not o[id].popped and not seen[roomOf(id)] then
					seen[roomOf(id)] = true
					table.insert(rooms, roomOf(id))
				end
			end
			table.insert(parts, "pop the real balloons in the " .. table.concat(rooms, ", "))
		end
	end
	for _, l in ipairs({ "L1", "L2" }) do
		if not world.unlocked[l] then
			local _, t = lockHint(l)
			table.insert(parts, t)
		end
	end
	table.insert(parts, "type the code on the keypad in the " .. roomOf("door") .. " - then everybody out!")
	for i, t in ipairs(parts) do
		parts[i] = i .. ") " .. t
	end
	return table.concat(parts, "  ")
end

local function lightUp(id, colour)
	local entry = world.objects[id]
	local target = entry and (entry.keypad or entry.part or entry.exit)
	if target then
		local hl = Instance.new("Highlight")
		hl.FillColor, hl.OutlineColor, hl.FillTransparency = colour, colour, 0.6
		hl.Adornee = target
		hl.Parent = target
		task.delay(15, function()
			hl:Destroy()
		end)
	end
end

-- one clue for the team (prefix: "Free clue: " or "")
local function giveClue(prefix)
	if state.mastermind then
		-- Brainy's Mastermind: the team's first clue is free and is the whole route
		state.mastermind = false
		local steps = clueSteps()
		if steps[1] then
			lightUp(steps[1].id, Color3.fromRGB(123, 227, 107))
		end
		return say("clue", "\u{1F9E0} Mastermind route: " .. routeText())
	end
	local steps = clueSteps()
	local first = steps[1]
	if not first then
		return
	end
	lightUp(first.id, Color3.fromRGB(123, 227, 107))
	local text = prefix .. first.text
	if state.twoStep then
		for i = 2, #steps do
			if steps[i].id ~= first.id then
				lightUp(steps[i].id, Color3.fromRGB(255, 210, 63))
				text ..= "  Then: " .. steps[i].text
				break
			end
		end
	end
	say("clue", text)
end

-- ---------- skills version 2: buttons for everyone, the level-10/20 powers ----------
do
	-- the camera fades walls and furniture between it and you (never jumps
	-- inside a bookshelf or out into the next room)
	local StarterPlayer = game:GetService("StarterPlayer")
	StarterPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	local function camera(p)
		p.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	end
	Players.PlayerAdded:Connect(camera)
	for _, p in ipairs(Players:GetPlayers()) do
		camera(p)
	end

	-- the guard rails: a skill stun is short, and never twice in a row
	function round.skillStun(_, seconds, text, near)
		-- (5 Nov) the host in the trap, or the one nearest the skill
		local host = steppingHost or (near and nearestHost(near)) or host
		if not (host and host.model) or state.status ~= "playing" then
			return false
		end
		local now = os.clock()
		if (host.stunImmune or 0) > now then
			return false
		end
		local g = Config.SKILL_STUN
		seconds = math.min(seconds, g.max)
		if state.diff == "nightmare" then
			seconds = math.min(seconds, g.nightmare)
		end
		host:stun(seconds)
		host.stunImmune = now + seconds + g.gap
		Effects.stars(host.model, seconds)
		if host.root then
			Effects.burst(host.root.Position + Vector3.new(0, 3, 0), "light")
		end
		if text then
			say("info", text)
		end
		return true
	end

	-- how far you can go from a spot in a direction before a wall (on the floor)
	local function clearRun(from, dir, most)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		for _, hh in ipairs(liveHosts()) do
			table.insert(skip, hh.model)
		end
		params.FilterDescendantsInstances = skip
		local flat = Vector3.new(dir.X, 0, dir.Z)
		if flat.Magnitude < 0.01 then
			flat = Vector3.new(0, 0, 1)
		end
		flat = flat.Unit
		local hit = workspace:Raycast(from, flat * most, params)
		local d = hit and math.max(2, (hit.Position - from).Magnitude - 2) or most
		return from + flat * d
	end

	-- a decoy that runs off: the host goes after it (Shadow's clone, Tinker's mouse)
	local function decoy(model, from, to, seconds)
		model.Parent = world.root
		local t = Instance.new("NumberValue")
		local base = model:GetPivot()
		local turn = CFrame.lookAt(from, Vector3.new(to.X, from.Y, to.Z)).Rotation
		t.Changed:Connect(function(a)
			if model.Parent then
				model:PivotTo(CFrame.new(from:Lerp(to, a)) * turn * base.Rotation:Inverse() * base.Rotation)
			end
		end)
		TweenService:Create(t, TweenInfo.new(math.min(seconds, 3), Enum.EasingStyle.Linear), { Value = 1 }):Play()
		task.delay(seconds, function()
			t:Destroy()
			if model.Parent then
				model:Destroy()
			end
		end)
		for _, h in ipairs(liveHosts()) do -- (5 Nov) both Clauses
			h:lure(to, seconds)
		end
	end

	-- Shadow's clone: a dark copy of Shadow runs away from the host
	function round.shadowClone(plr, count)
		local char = plr.Character
		local hrp = hrpOf(plr)
		if not char or not hrp then
			return
		end
		local seconds = plr:GetAttribute("CloneTime") or Config.CLONE.seconds
		local near = nearestHost(hrp.Position) -- (5 Nov) away from the nearest Claus
		local away = near and near.root and (hrp.Position - near.root.Position) or hrp.CFrame.LookVector
		for i = 1, count do
			-- 17 Oct (Brent: one clone barely moved): the first runs away from the
			-- host, the second the opposite way, a third to the side; each turns a
			-- little at a time until it finds a run longer than 8 studs
			local base = i == 1 and 0 or i == 2 and 180 or 90
			local dir = CFrame.Angles(0, math.rad(base), 0):VectorToWorldSpace(away)
			do
				local flat0 = Vector3.new(away.X, 0, away.Z)
				flat0 = flat0.Magnitude > 0.01 and flat0.Unit or Vector3.new(0, 0, 1)
				for _, turn in ipairs({ 0, 30, -30, 60, -60, 90, -90 }) do
					local try = CFrame.Angles(0, math.rad(base + turn), 0):VectorToWorldSpace(flat0)
					if (clearRun(hrp.Position, try, Config.CLONE.run) - hrp.Position).Magnitude >= 8 then
						dir = try
						break
					end
				end
			end
			local was = char.Archivable
			char.Archivable = true
			local c = char:Clone()
			char.Archivable = was
			if c then
				for _, d in ipairs(c:GetDescendants()) do
					if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") or d:IsA("BillboardGui") then
						d:Destroy()
					elseif d:IsA("BasePart") then
						d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
					end
				end
				-- 17 Oct (Brent: a clone blocked Shadow's way): no Humanoid in a clone
				-- (it can make the body solid again); kids run straight through it
				local hum = c:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:Destroy()
				end
				local hl = Instance.new("Highlight")
				hl.FillColor, hl.OutlineColor, hl.FillTransparency = Color3.fromRGB(40, 20, 70), Color3.fromRGB(150, 100, 220), 0.15
				hl.Parent = c
				c.Name = "ShadowClone"
				-- 17 Oct (Brent: the clones floated): its lowest point on the floor
				-- under Shadow, whatever height his root part rides at
				-- the clone is placed by its pivot: the pivot's height above the clone's
				-- lowest point, put that far above the floor
				local pivotY = hrp.Position.Y
				do
					local fp = RaycastParams.new()
					fp.FilterType = Enum.RaycastFilterType.Exclude
					fp.FilterDescendantsInstances = { char, c }
					local floorHit = workspace:Raycast(hrp.Position, Vector3.new(0, -30, 0), fp)
					if floorHit then
						local ccf, csize = c:GetBoundingBox()
						pivotY = floorHit.Position.Y + (c:GetPivot().Position.Y - (ccf.Position.Y - csize.Y / 2))
					end
				end
				local from = Vector3.new(hrp.Position.X, pivotY, hrp.Position.Z)
				local runTo = clearRun(hrp.Position, dir, Config.CLONE.run)
				local to = Vector3.new(runTo.X, pivotY, runTo.Z)
				decoy(c, from, to, seconds)
			end
		end
		say("info", plr.DisplayName .. "'s shadow clone runs off - the host goes after it!")
	end

	-- Tinker's wind-up mouse
	local function windUpMouse(plr)
		local hrp = hrpOf(plr)
		if not hrp then
			return
		end
		local m = Instance.new("Model")
		m.Name = "WindUpMouse"
		local start = hrp.Position - Vector3.new(0, 2.4, 0)
		local to = clearRun(start, hrp.CFrame.LookVector, Config.MOUSE.run)
		local face = (to - start) * Vector3.new(1, 0, 1)
		local look = face.Magnitude > 0.1 and CFrame.lookAt(start, start + face) or CFrame.new(start)
		-- a clockwork mouse facing where it will run: ears, eyes, a pink nose,
		-- a tail and the winding key on its back
		local function bit(size, off, col, mat, shape)
			local p = Instance.new("Part")
			p.Shape = shape or Enum.PartType.Ball
			p.Size = size
			Shapes.fix(p, shape or Enum.PartType.Ball, size)
			p.Color = col
			p.Material = mat or Enum.Material.SmoothPlastic
			p.Anchored, p.CanCollide, p.CanQuery = true, false, false
			p.CFrame = look * CFrame.new(off)
			p.Parent = m
			return p
		end
		local GREY = Color3.fromRGB(160, 160, 170)
		local body = bit(Vector3.new(1.6, 1, 2), Vector3.zero, GREY, Enum.Material.Metal)
		for _, s in ipairs({ -1, 1 }) do
			bit(Vector3.new(0.7, 0.7, 0.12), Vector3.new(s * 0.45, 0.65, -0.55), GREY, Enum.Material.Metal)
			bit(Vector3.new(0.45, 0.45, 0.08), Vector3.new(s * 0.45, 0.65, -0.62), Color3.fromRGB(255, 170, 190))
			bit(Vector3.new(0.16, 0.16, 0.16), Vector3.new(s * 0.3, 0.25, -0.85), Color3.fromRGB(20, 20, 25))
		end
		bit(Vector3.new(0.22, 0.2, 0.2), Vector3.new(0, 0, -1.02), Color3.fromRGB(255, 130, 160))
		bit(Vector3.new(0.08, 0.08, 1.4), Vector3.new(0, 0.1, 1.6), Color3.fromRGB(255, 170, 190), nil, Enum.PartType.Block)
		bit(Vector3.new(0.2, 0.8, 0.8), Vector3.new(0, 0.7, 0.2), Color3.fromRGB(230, 190, 80), Enum.Material.Foil, Enum.PartType.Block)
		m.PrimaryPart = body
		Effects.sound(body.Position, "noise", 0.8)
		decoy(m, body.Position, to, Config.MOUSE.seconds)
		say("info", plr.DisplayName .. " let a wind-up mouse go - squeak squeak! The host chases it.")
	end

	-- a plain doorway near a spot (for Bramble's vines)
	-- 5 Nov (Brent: Holly Hedge missed wide doorways): a doorway is an open
	-- tile between rooms (outside every room's rectangle), 1 to 3 tiles wide;
	-- one entry per doorway - the tile nearest you (x, y), its middle (mx,
	-- my), how many tiles wide, and which way it runs (across)
	local function inRoom(x, y)
		for _, f in ipairs(HouseMap.floors) do
			if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
				return true
			end
		end
		return false
	end
	local function doorCell(x, y)
		return cellAt(x, y) == "." and not inRoom(x, y)
	end
	local function doorwaysNear(pos, reach)
		local px, py = math.floor(pos.X / T), math.floor(pos.Z / T)
		local byStart, found = {}, {}
		for dx = -reach, reach do
			for dy = -reach, reach do
				local x, y = px + dx, py + dy
				if doorCell(x, y) then
					local across
					if doorCell(x - 1, y) or doorCell(x + 1, y) then
						across = "x"
					elseif doorCell(x, y - 1) or doorCell(x, y + 1) then
						across = "z"
					elseif cellAt(x - 1, y) ~= "." and cellAt(x + 1, y) ~= "." then
						across = "x"
					elseif cellAt(x, y - 1) ~= "." and cellAt(x, y + 1) ~= "." then
						across = "z"
					end
					if across then
						local sx, sy = across == "x" and 1 or 0, across == "z" and 1 or 0
						local a, b = 0, 0
						while a < 3 and doorCell(x - (a + 1) * sx, y - (a + 1) * sy) do
							a += 1
						end
						while b < 3 and doorCell(x + (b + 1) * sx, y + (b + 1) * sy) do
							b += 1
						end
						local width = a + b + 1
						if width <= 3 then
							local x0, y0 = x - a * sx, y - a * sy
							local key = x0 .. "," .. y0
							local d = math.abs(dx) + math.abs(dy)
							local e = byStart[key]
							if not e then
								e = { x = x, y = y, across = across, d = d, width = width,
									mx = x0 + (width - 1) / 2 * sx, my = y0 + (width - 1) / 2 * sy }
								byStart[key] = e
								table.insert(found, e)
							elseif d < e.d then
								e.x, e.y, e.d = x, y, d
							end
						end
					end
				end
			end
		end
		table.sort(found, function(a, b)
			return a.d < b.d
		end)
		return found
	end

	-- Holly's Hedge (level 20, 4 Nov): once a game, a prickly holly hedge across
	-- the nearest doorway for Config.HOLLY.hedge seconds. Kids squeeze through;
	-- the host is held at it. Returns true if it grew
	function round.hollyHedge(plr)
		local hrp = hrpOf(plr)
		local spots = hrp and doorwaysNear(hrp.Position, Config.VINES.reach) or {}
		local spot = spots[1]
		-- 5 Nov (Brent): of the doorways tied for nearest, the one she faces
		if spot and hrp then
			local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
			local bestDot = -math.huge
			for _, s in ipairs(spots) do
				if s.d == spots[1].d then
					local to = House.at(s.mx, s.my, 0) - hrp.Position
					to = Vector3.new(to.X, 0, to.Z)
					local dot = (to.Magnitude > 0.1 and look.Magnitude > 0.1) and to.Unit:Dot(look.Unit) or 1
					if dot > bestDot then
						spot, bestDot = s, dot
					end
				end
			end
		end
		if not spot then
			say("info", "\u{1F33F} Stand in or next to a doorway to grow your Holly Hedge there.", nil, plr)
			return false
		end
		local c = House.at(spot.mx or spot.x, spot.my or spot.y, 0)
		local m = Instance.new("Model")
		m.Name = "HollyHedge"
		local across = spot.across == "x" and Vector3.new(1, 0, 0) or Vector3.new(0, 0, 1)
		local half = math.max(2, math.ceil(((spot.width or 1) * T - 2) / 2.8)) -- (5 Nov) the whole doorway
		local block = 6 + ((spot.width or 1) - 1) * T / 2
		for k = -half, half do
			for lvl = 0, 2 do
				local bush = Instance.new("Part")
				bush.Name = "Hedge"
				bush.Shape = Enum.PartType.Ball
				bush.Size = Vector3.new(2.4, 2.4, 2.4)
				bush.Position = c + across * k * 1.4 + Vector3.new(0, 1 + lvl * 1.8, 0)
				bush.Anchored, bush.CanCollide, bush.CanQuery, bush.CanTouch = true, false, false, false
				bush.Color = Color3.fromRGB(28, 100, 45)
				bush.Material = Enum.Material.LeafyGrass
				bush.Parent = m
				if (k + lvl) % 2 == 0 then
					local berry = Instance.new("Part")
					berry.Name = "HedgeBerry"
					berry.Shape = Enum.PartType.Ball
					berry.Size = Vector3.new(0.45, 0.45, 0.45)
					berry.Position = bush.Position + Vector3.new(0, 0.9, 0) + (across:Cross(Vector3.yAxis)) * 1
					berry.Anchored, berry.CanCollide, berry.CanQuery, berry.CanTouch = true, false, false, false
					berry.Color = Color3.fromRGB(215, 30, 40)
					berry.Material = Enum.Material.SmoothPlastic
					berry.Parent = m
				end
			end
		end
		m.Parent = world.root
		Effects.burst(c + Vector3.new(0, 2, 0), "plant")
		say("info", "\u{1F33F} " .. plr.DisplayName .. " grew a prickly Holly Hedge - the host can't get through!")
		local myWorld = world
		task.spawn(function()
			local stopAt = os.clock() + Config.HOLLY.hedge
			local told = false
			while os.clock() < stopAt and world == myWorld and state.status == "playing" do
				local host = nearestHost(c) -- (5 Nov) the Claus at the hedge
				if host and host.model and host.root and (Vector3.new(host.root.Position.X, 0, host.root.Position.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude < block then
					host:stun(0.4) -- held at the hedge
					if not told then
						told = true
						say("info", "Ouch! The host can't get past Holly's hedge!")
					end
				end
				task.wait(0.3)
			end
			if m.Parent then
				m:Destroy()
			end
		end)
		return true
	end

	local function growVines(plr, spot, seconds, snapper)
		local c = House.at(spot.x, spot.y, 0)
		local m = Instance.new("Model")
		m.Name = "BrambleVines"
		local floor = Instance.new("Part")
		floor.Name = "Vines"
		floor.Size = Vector3.new(T, 0.3, T)
		floor.Position = c + Vector3.new(0, 0.15, 0)
		floor.Color = Color3.fromRGB(60, 140, 60)
		floor.Material = Enum.Material.Grass
		floor.Anchored, floor.CanCollide, floor.CanQuery, floor.CanTouch = true, false, true, false
		if snapper then
			floor:SetAttribute("Snapper", true)
		end
		floor.Parent = m
		for i = 1, 7 do
			local v = Instance.new("Part")
			v.Size = Vector3.new(0.35, 2 + (i % 3), 0.35)
			local off = (i - 4) * (T / 8)
			v.Position = c + (spot.across == "x" and Vector3.new(off, v.Size.Y / 2, (i % 2) * 1.2 - 0.6) or Vector3.new((i % 2) * 1.2 - 0.6, v.Size.Y / 2, off))
			v.Orientation = Vector3.new((i % 2) * 20 - 10, i * 37, (i % 3) * 12 - 12)
			v.Color = i % 2 == 0 and Color3.fromRGB(70, 160, 70) or Color3.fromRGB(40, 110, 50)
			v.Material = Enum.Material.Grass
			v.Anchored, v.CanCollide, v.CanQuery, v.CanTouch = true, false, false, false
			v.Parent = m
			-- grows up out of the floor, one stem after another
			local fullCF, fullSize = v.CFrame, v.Size
			v.Size = Vector3.new(fullSize.X, 0.1, fullSize.Z)
			v.CFrame = fullCF - Vector3.new(0, fullSize.Y / 2, 0)
			game:GetService("TweenService"):Create(v, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, i * 0.05), { Size = fullSize, CFrame = fullCF }):Play()
			if snapper and i == 4 then
				-- the snapper: a red head with an open mouth and white teeth, two
				-- leaves under it; it pops open once its stem has grown
				local top = fullCF.Position + Vector3.new(0, fullSize.Y / 2 + 0.6, 0)
				local function snap(size, off, col, shape)
					local p = Instance.new("Part")
					p.Shape = shape or Enum.PartType.Ball
					p.Size = size
					Shapes.fix(p, shape or Enum.PartType.Ball, size)
					p.CFrame = CFrame.new(top) * CFrame.new(off)
					p.Color = col
					p.Anchored, p.CanCollide, p.CanQuery = true, false, false
					p.Transparency = 1
					p.Parent = m
					game:GetService("TweenService"):Create(p, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.5), { Transparency = 0 }):Play()
				end
				snap(Vector3.new(1.4, 1.2, 1.4), Vector3.new(0, 0.1, 0), Color3.fromRGB(220, 60, 80))
				snap(Vector3.new(1, 0.45, 0.6), Vector3.new(0, 0, -0.5), Color3.fromRGB(70, 15, 25))
				for k = -1, 1, 2 do
					snap(Vector3.new(0.14, 0.2, 0.1), Vector3.new(k * 0.25, 0.18, -0.72), Color3.new(1, 1, 1), Enum.PartType.Block)
					snap(Vector3.new(0.14, 0.2, 0.1), Vector3.new(k * 0.25, -0.18, -0.72), Color3.new(1, 1, 1), Enum.PartType.Block)
					snap(Vector3.new(1, 0.15, 0.5), Vector3.new(k * 0.6, -0.7, 0), Color3.fromRGB(70, 160, 70))
				end
			end
		end
		m.Parent = world.root
		Effects.burst(c + Vector3.new(0, 1, 0), "plant")
		local myWorld = world
		task.delay(seconds, function()
			if m.Parent and world == myWorld then
				-- the vines sink back into the floor
				for _, v in ipairs(m:GetChildren()) do
					if v:IsA("BasePart") then
						-- shrinking down to the floor, not to its middle
						game:GetService("TweenService"):Create(v, TweenInfo.new(0.4), { Size = Vector3.new(v.Size.X, 0.1, v.Size.Z), CFrame = v.CFrame - Vector3.new(0, v.Size.Y / 2, 0), Transparency = 1 }):Play()
					end
				end
				game:GetService("Debris"):AddItem(m, 0.45)
			end
		end)
	end

	-- a colour of the door code nobody knows yet (not on Nightmare)
	local function revealAColour()
		if state.diff == "nightmare" and not Config.CODE_COLOUR_ON_NIGHTMARE then
			return nil
		end
		local unknown = {}
		for k = 1, #state.code do
			if not state.known[k] then
				table.insert(unknown, k)
			end
		end
		if #unknown <= 1 then
			return nil -- never the last one
		end
		local k = unknown[math.random(1, #unknown)]
		state.known[k] = state.code[k]
		RoundState:SetAttribute("Known" .. k, state.code[k])
		return k
	end

	-- the new buttons (and the powers that ride on the old ones); returns
	-- false when nothing happened (no cooldown then)
	-- Elfy's wind-up toy soldier (5 Nov): marches `march` studs a second along
	-- `dir` (stopping at walls) for Config.ELFY.toy s (+band); every `every`
	-- s each host within earshot goes after it (as after Echo's noise)
	function round.windUpToy(plr, hrp, dir, band, stun)
		local E = Config.ELFY
		stun = stun or E.toyStun -- (5 Nov) a host reaching the toy is stunned
		local seconds = E.toy + (band and E.band or 0)
		local hear = band and E.bandHear or E.hear
		dir = Vector3.new(dir.X, 0, dir.Z)
		dir = dir.Magnitude > 0.05 and dir.Unit or Vector3.new(0, 0, 1)
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		local ground = hrp.Position - Vector3.new(0, (hum and hum.HipHeight or 2) + hrp.Size.Y / 2, 0)
		local m = Instance.new("Model")
		m.Name = "WindUpToy"
		local function bit(shape, size, offset, color)
			local p = Instance.new("Part")
			p.Shape, p.Size, p.Color = shape, size, color
			Shapes.fix(p, shape, size)
			p.Material = Enum.Material.SmoothPlastic
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p:SetAttribute("Offset", offset)
			p.Parent = m
			return p
		end
		bit(Enum.PartType.Block, Vector3.new(0.9, 1.1, 0.7), Vector3.new(0, 1.2, 0), Color3.fromRGB(200, 40, 50))
		bit(Enum.PartType.Ball, Vector3.new(0.8, 0.8, 0.8), Vector3.new(0, 2.15, 0), Color3.fromRGB(255, 214, 180))
		bit(Enum.PartType.Cylinder, Vector3.new(0.9, 0.7, 0.7), Vector3.new(0, 2.85, 0), Color3.fromRGB(30, 30, 40))
		bit(Enum.PartType.Block, Vector3.new(0.35, 0.65, 0.35), Vector3.new(-0.22, 0.33, 0), Color3.fromRGB(30, 60, 140))
		bit(Enum.PartType.Block, Vector3.new(0.35, 0.65, 0.35), Vector3.new(0.22, 0.33, 0), Color3.fromRGB(30, 60, 140))
		bit(Enum.PartType.Cylinder, Vector3.new(0.4, 0.8, 0.8), Vector3.new(0, 1.2, 0.5), Color3.fromRGB(240, 196, 60))
		bit(Enum.PartType.Block, Vector3.new(0.15, 0.7, 0.15), Vector3.new(0, 1.3, -0.5), Color3.fromRGB(240, 196, 60))
		m.Parent = world.root
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip = { m }
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		params.FilterDescendantsInstances = skip
		local myState = state
		local pos = ground
		local function place(t)
			local cf = CFrame.lookAt(pos, pos + dir)
			local bob = math.abs(math.sin(t * 12)) * 0.15
			for _, p in ipairs(m:GetChildren()) do
				local o = p:GetAttribute("Offset")
				if o then
					p.CFrame = cf * CFrame.new(o.X, o.Y + bob, -o.Z)
					if p.Shape == Enum.PartType.Cylinder then
						p.CFrame = p.CFrame * CFrame.Angles(0, 0, math.rad(90))
					end
				end
			end
		end
		place(0)
		Effects.burst(ground + Vector3.new(0, 1, 0), "noise")
		task.spawn(function()
			local start, last, nextCall = os.clock(), os.clock(), 0
			while m.Parent and state == myState and state.status == "playing" do
				local now = os.clock()
				local t = now - start
				if t >= seconds then
					break
				end
				local step = (now - last) * E.march
				last = now
				local hit = workspace:Raycast(pos + Vector3.new(0, 1, 0), dir * (step + 1.2), params)
				if hit then
					dir = Vector3.new(-dir.Z, 0, dir.X) -- a wall: turn and keep marching
				else
					pos += dir * step
				end
				place(t)
				if now >= nextCall then
					nextCall = now + E.every
					Effects.sound(pos, "bell", 0.6)
					for _, h in ipairs({ host, host2 }) do
						if h and h.model and h.root and (h.root.Position - pos).Magnitude <= hear then
							h:lure(pos, E.every + 0.5)
						end
					end
				end
				-- 5 Nov (Brent): a host that reaches the toy trips over it
				local tripped = false
				for _, h in ipairs({ host, host2 }) do
					if not tripped and h and h.model and h.root and Vector3.new(h.root.Position.X - pos.X, 0, h.root.Position.Z - pos.Z).Magnitude <= 3.5 then
						tripped = true
						h:stun(stun)
						Effects.sound(pos, "bonk", 0.8)
						say("info", "\u{1F941} The host tripped over " .. plr.DisplayName .. "'s wind-up toy!")
					end
				end
				if tripped then
					break
				end
				task.wait()
			end
			if m.Parent then
				Effects.burst(pos + Vector3.new(0, 1, 0), "light")
				m:Destroy()
			end
		end)
	end

	function round.skillV2(plr, skill, hrp, pos)
		local p10, p20 = plr:GetAttribute("Power10"), plr:GetAttribute("Power20")
		state.oncePerGame = state.oncePerGame or {}
		local once = state.oncePerGame
		if skill == "tinker" then
			plr:SetAttribute("ToolkitReady", true)
			Effects.icon(plr, "\u{1F527}", 1.6)
			Effects.at(plr, "pick")
			say("info", "\u{1F527} Toolkit ready: your next lock or keypad picks in an instant.", nil, plr)
			if p10 == "mouse" then
				windUpMouse(plr)
			end
			return true
		elseif skill == "brainy" then
			local steps = clueSteps()
			if not steps[1] then
				say("info", "\u{1F9E0} Nothing left to work out - get to the exit!", nil, plr)
				return false
			end
			lightUp(steps[1].id, Color3.fromRGB(120, 190, 255))
			Effects.icon(plr, "\u{1F4A1}", 2)
			Effects.at(plr, "reveal")
			local text = "\u{1F9E0} " .. plr.DisplayName .. " thinks: " .. steps[1].text
			if p20 == "bigbrain" then
				for i = 2, #steps do
					if steps[i].id ~= steps[1].id then
						lightUp(steps[i].id, Color3.fromRGB(255, 210, 63))
						text ..= "  Then: " .. steps[i].text
						break
					end
				end
			end
			say("clue", text)
			plr:SetAttribute("ThinkUntil", workspace:GetServerTimeNow() + (plr:GetAttribute("ThinkTime") or Config.THINK_SECONDS)) -- the lit-up step stays (15 s + ladder steps)
			if p20 == "photo" and not once["photo" .. plr.UserId] then
				once["photo" .. plr.UserId] = true
				local k = revealAColour()
				if k then
					say("reveal", "\u{1F4F8} Brainy remembers: color " .. k .. " of the code is " .. colourWord(state.code[k]) .. "!")
				end
			end
			return true
		elseif skill == "bramble" then
			local spots = doorwaysNear(hrp.Position, Config.VINES.reach)
			if #spots == 0 then
				say("info", "\u{1F33F} Stand in or next to a doorway to grow vines across it.", nil, plr)
				return false
			end
			local seconds = plr:GetAttribute("VineTime") or Config.VINES.seconds
			local many = p20 == "overgrowth" and 2 or 1
			for i = 1, math.min(many, #spots) do
				growVines(plr, spots[i], seconds, p10 == "snapper")
			end
			say("info", "\u{1F33F} " .. plr.DisplayName .. " grew vines across the doorway - the host will wade through slowly!")
			plr:SetAttribute("VinesUntil", workspace:GetServerTimeNow() + seconds)
			-- 5 Nov (Brent): Vine Swing (level 20) - a vine shoots to the next
			-- doorway ahead (a clear path, the nearest in front first) and
			-- swings her and the friends near her there, fast, at once
			if p20 == "forest" then
				local VS = Config.VINE_SWING
				local here = spots[1]
				local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.RespectCanCollide = true
				local skip = {}
				for _, p in ipairs(Players:GetPlayers()) do
					if p.Character then
						table.insert(skip, p.Character)
					end
				end
				params.FilterDescendantsInstances = skip
				local best, bestScore
				for _, d in ipairs(doorwaysNear(hrp.Position, VS.tiles)) do
					if d ~= here and (math.abs(d.mx - here.mx) + math.abs(d.my - here.my)) >= 2 then
						local to = House.at(d.mx, d.my, 0) + Vector3.new(0, hrp.Position.Y - House.at(0, 0, 0).Y, 0)
						local way = Vector3.new(to.X - hrp.Position.X, 0, to.Z - hrp.Position.Z)
						if way.Magnitude > 4 and not workspace:Raycast(hrp.Position, way, params) then
							local score = way.Magnitude - (look.Magnitude > 0.1 and way.Unit:Dot(look.Unit) > 0.3 and 1000 or 0)
							if not bestScore or score < bestScore then
								best, bestScore = to, score
							end
						end
					end
				end
				if best then
					local now3 = workspace:GetServerTimeNow()
					local names = {}
					for _, p in ipairs(Players:GetPlayers()) do
						local h = hrpOf(p)
						if h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and (p == plr or (h.Position - hrp.Position).Magnitude <= VS.near) then
							local trip = (Vector3.new(best.X - h.Position.X, 0, best.Z - h.Position.Z)).Magnitude / (Config.WALK * VS.speed) + 0.8
							p:SetAttribute("VineTo", best)
							p:SetAttribute("VineUntil", now3 + trip)
							p:SetAttribute("TeamBurstMult", VS.speed)
							p:SetAttribute("TeamBurstUntil", now3 + trip)
							Effects.aura(p, "speed", trip)
							if p ~= plr then
								table.insert(names, p.DisplayName)
							end
						end
					end
					-- the vine itself, for a moment
					local mid = (hrp.Position + best) / 2 + Vector3.new(0, 2, 0)
					local rope = Instance.new("Part")
					rope.Name = "SwingVine"
					rope.Anchored, rope.CanCollide, rope.CanQuery, rope.CanTouch = true, false, false, false
					rope.Size = Vector3.new(0.4, 0.4, (best - hrp.Position).Magnitude)
					rope.CFrame = CFrame.lookAt(mid, best + Vector3.new(0, 2, 0))
					rope.Color = Color3.fromRGB(60, 140, 60)
					rope.Material = Enum.Material.Grass
					rope.Parent = world.root
					game:GetService("Debris"):AddItem(rope, 2)
					say("info", "\u{1F33F} Vine Swing! " .. plr.DisplayName .. (#names > 0 and (" swung off with " .. table.concat(names, " and ")) or " swung off") .. " to the next doorway!")
				end
			end
			return true
		elseif skill == "nutmeg" then
			-- Sleigh Dash (3 Nov): double speed for DashTime seconds; the nearest
			-- friend within PullRange (two with Two Riders) is pulled along - their
			-- screens steer them beside Nutmeg (DashFollow), no aiming
			local nm = Config.NUTMEG
			local now = workspace:GetServerTimeNow()
			-- (5 Nov, Brent) Two Riders: a quarter second longer for the extra rider
			local seconds = (plr:GetAttribute("DashTime") or nm.dash) + (p20 == "riders" and 0.25 or 0)
			local untilT = now + seconds
			plr:SetAttribute("TeamBurstMult", nm.dashMult)
			plr:SetAttribute("TeamBurstUntil", untilT)
			plr:SetAttribute("DashUntil", untilT)
			Effects.aura(plr, "speed", seconds)
			Effects.sound(hrp.Position, "bell", 0.8)
			local riders = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local h = hrpOf(p)
				if p ~= plr and h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and not p:GetAttribute("Hidden") and not p:GetAttribute("Crawling") then
					local d = (h.Position - hrp.Position).Magnitude
					if d <= (plr:GetAttribute("PullRange") or nm.pull) then
						table.insert(riders, { p = p, d = d })
					end
				end
			end
			table.sort(riders, function(a, b)
				return a.d < b.d
			end)
			local names = {}
			for i = 1, math.min(#riders, p20 == "riders" and 2 or 1) do
				local p = riders[i].p
				p:SetAttribute("TeamBurstMult", nm.dashMult)
				p:SetAttribute("TeamBurstUntil", untilT)
				p:SetAttribute("DashFollow", plr.UserId)
				p:SetAttribute("DashUntil", untilT)
				p:SetAttribute("DashSide", i == 1 and 1 or -1)
				Effects.aura(p, "speed", seconds)
				table.insert(names, p.DisplayName)
			end
			say("info", "\u{1F6F7} " .. plr.DisplayName .. " dashed off" .. (#names > 0 and (" with " .. table.concat(names, " and ")) or "") .. "!")
			-- Jingle Dash (level 10): the bell freezes a host close by
			local host = nearestHost(hrp.Position) -- (5 Nov) the nearest Claus
			if p10 == "jingledash" and host and host.model and host.root and (host.root.Position - hrp.Position).Magnitude <= nm.jingleRange then
				host:stun(nm.jingleStun)
				say("info", "\u{1F514} Jingle! The host froze for " .. nm.jingleStun .. " s.")
			end
			-- Snow Sense (level 10): the room of the nearest key still hidden
			if p10 == "snowsense" then
				local best, bestD
				for sid, lock in pairs(world.keyIn or {}) do
					local e = world.objects[sid]
					if e and e.def and not e.searched and not world.unlocked[lock] and not world.keys[lock] then
						local d = (at(e.def.x, e.def.y, 0) - hrp.Position).Magnitude
						if not bestD or d < bestD then
							best, bestD = sid, d
						end
					end
				end
				say("info", best and ("\u{2744} Snow Sense: the nearest key is in the " .. roomOf(best) .. "!") or "\u{2744} Snow Sense: no keys left to find!", nil, plr)
			end
			return true
		elseif skill == "cloud" then
			-- Fog (4 Nov): a fog cloud where she stands (Storm Cloud: where she
			-- tapped, up to Config.CLOUD.throw studs away) for FogTime seconds
			local C = Config.CLOUD
			local storm = p20 == "storm"
			local center = hrp.Position
			if storm then
				if typeof(pos) ~= "Vector3" then
					say("info", "\u{26C8} Tap where to throw your storm cloud.", nil, plr)
					return false
				end
				local d = pos - hrp.Position
				center = d.Magnitude > C.throw and (hrp.Position + d.Unit * C.throw) or pos
				center = Vector3.new(center.X, hrp.Position.Y - 2.5, center.Z)
			else
				center = hrp.Position - Vector3.new(0, 2.5, 0)
			end
			local seconds = plr:GetAttribute("FogTime") or C.fog
			round.makeFog(plr, center, plr:GetAttribute("FogRadius") or C.radius, seconds, { follow = p10 == "rolling" and not storm, storm = storm, lining = p10 == "lining" })
			plr:SetAttribute("FogUntil", workspace:GetServerTimeNow() + seconds)
			if storm then
				-- friends near her when she throws it: stamina and a burst of speed
				local now = workspace:GetServerTimeNow()
				for _, p in ipairs(Players:GetPlayers()) do
					local h = hrpOf(p)
					if h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and (h.Position - hrp.Position).Magnitude <= C.stormNear then
						Boost:FireClient(p, "plus", C.stormStamina)
						p:SetAttribute("TeamBurstMult", C.stormSpeed)
						p:SetAttribute("TeamBurstUntil", now + C.stormSpeedTime)
						Effects.aura(p, "speed", C.stormSpeedTime)
					end
				end
				say("info", "\u{26C8} " .. plr.DisplayName .. " threw a storm cloud! Friends nearby: +" .. C.stormStamina .. "% stamina and a burst of speed!")
			else
				say("info", "\u{2601} " .. plr.DisplayName .. " breathed out a fog - anyone inside is hidden from the host!")
			end
			-- Fog Bank (level 20): a second fog before it recharges
			if p20 == "bank" then
				if not plr:GetAttribute("FogBankUsed") then
					plr:SetAttribute("FogBankUsed", true)
					say("info", "\u{2601} One more fog before it recharges!", nil, plr)
					return "free"
				end
				plr:SetAttribute("FogBankUsed", false)
			end
			return true
		elseif skill == "elfy" then
			-- Wind-up Toy (5 Nov): a toy soldier marches off straight ahead
			-- jingling; the hosts within earshot go after it
			round.windUpToy(plr, hrp, hrp.CFrame.LookVector, p10 == "band")
			if p10 == "wrapped" then
				applyBoost(plr, "giftbox", Config.ELFY.wrapped)
				say("info", "\u{1F381} " .. plr.DisplayName .. " set down a wind-up toy and hid inside a present!")
			else
				say("info", "\u{1F941} " .. plr.DisplayName .. " set down a wind-up toy - the host goes after the noise!")
			end
			return true
		elseif skill == "holly" then
			-- Peppermint Slide (4 Nov): peppermints scattered on the floor where she
			-- stands - the host slips on them once (Holly Trap: a ring of holly)
			local H = Config.HOLLY
			local r = plr:GetAttribute("PatchRadius") or H.radius
			local seconds = plr:GetAttribute("PatchTime") or H.patch
			local trap = p10 == "hollytrap"
			-- 5 Nov (Brent): Candy Storm also perks up friends nearby
			if p20 == "candystorm" then
				for _, p in ipairs(Players:GetPlayers()) do
					local h = hrpOf(p)
					if p ~= plr and h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and (h.Position - hrp.Position).Magnitude <= 16 then
						Boost:FireClient(p, "plus", 25)
					end
				end
			end
			local ground = hrp.Position - Vector3.new(0, 2.9, 0)
			local m = Instance.new("Model")
			m.Name = "HollyPeppermints"
			-- the patch the host's feet find (Host: "Peppermints")
			local pad = Instance.new("Part")
			pad.Name = "Peppermints"
			pad.Shape = Enum.PartType.Cylinder
			pad.Size = Vector3.new(0.1, r * 2, r * 2)
			pad.CFrame = CFrame.new(ground + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
			pad.Anchored, pad.CanCollide, pad.CanTouch, pad.CastShadow = true, false, false, false
			pad.CanQuery = true
			pad.Transparency = 0.6
			pad.Color = Color3.fromRGB(255, 225, 230)
			pad.Material = Enum.Material.SmoothPlastic
			pad:SetAttribute("Holly", trap or nil)
			pad:SetAttribute("Stun", (trap and H.trapStun or H.slipStun) + (plr:GetAttribute("SlipTime") or 0))
			pad.Parent = m
			local rng = Random.new()
			for _ = 1, math.floor(r * r * 1.2) do
				local a, d = rng:NextNumber(0, math.pi * 2), math.sqrt(rng:NextNumber()) * (r - 0.4)
				local at = ground + Vector3.new(math.cos(a) * d, 0.15, math.sin(a) * d)
				for k, col in ipairs({ Color3.fromRGB(250, 250, 250), Color3.fromRGB(215, 30, 45) }) do
					local candy = Instance.new("Part")
					candy.Name = "Peppermint"
					candy.Shape = Enum.PartType.Cylinder
					candy.Size = k == 1 and Vector3.new(0.18, 0.7, 0.7) or Vector3.new(0.2, 0.32, 0.32)
					candy.CFrame = CFrame.new(at + Vector3.new(0, (k - 1) * 0.02, 0)) * CFrame.Angles(0, 0, math.rad(90))
					candy.Anchored, candy.CanCollide, candy.CanQuery, candy.CanTouch, candy.CastShadow = true, false, false, false, false
					candy.Color = col
					candy.Material = Enum.Material.SmoothPlastic
					candy.Parent = m
				end
			end
			if trap then
				-- the ring of holly round the edge: leaves and red berries
				for k = 0, 15 do
					local a = k / 16 * math.pi * 2
					local leaf = Instance.new("Part")
					leaf.Name = k % 2 == 0 and "HollyLeaf" or "HollyBerry"
					leaf.Shape = k % 2 == 0 and Enum.PartType.Block or Enum.PartType.Ball
					leaf.Size = k % 2 == 0 and Vector3.new(0.9, 0.15, 0.5) or Vector3.new(0.35, 0.35, 0.35)
					leaf.CFrame = CFrame.new(ground + Vector3.new(math.cos(a) * r, 0.2, math.sin(a) * r)) * CFrame.Angles(0, -a, 0)
					leaf.Anchored, leaf.CanCollide, leaf.CanQuery, leaf.CanTouch = true, false, false, false
					leaf.Color = k % 2 == 0 and Color3.fromRGB(30, 110, 50) or Color3.fromRGB(210, 30, 40)
					leaf.Material = Enum.Material.SmoothPlastic
					leaf.Parent = m
				end
			end
			m.Parent = world.root
			game:GetService("Debris"):AddItem(m, seconds)
			Effects.burst(ground + Vector3.new(0, 1, 0), "boost", "collect")
			plr:SetAttribute("PeppermintUntil", workspace:GetServerTimeNow() + seconds)
			say("info", "\u{1F36C} " .. plr.DisplayName .. " scattered peppermints - lead the host over them!")
			return true
		elseif skill == "clone" then
			-- Copycat (4 Nov): the button skill of the nearest friend within
			-- CopyReach (the two nearest with Copy Two) becomes his own extra
			-- button; alone, one is picked at random. Full Copy: the friend's own numbers
			local reach = plr:GetAttribute("CopyReach") or Config.CLONE_COPY.reach
			local near = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local h = hrpOf(p)
				local s = p:GetAttribute("Skill")
				if p ~= plr and h and s and s ~= "clone" and Config.COOLDOWN[s] and not p:GetAttribute("Escaped") then
					local d = (h.Position - hrp.Position).Magnitude
					if d <= reach then
						table.insert(near, { p = p, s = s, d = d })
					end
				end
			end
			table.sort(near, function(a, b)
				return a.d < b.d
			end)
			local want = p20 == "copytwo" and 2 or 1
			local picks = {}
			for _, n in ipairs(near) do
				local dup = false
				for _, k in ipairs(picks) do
					dup = dup or k.s == n.s
				end
				if not dup and #picks < want then
					table.insert(picks, n)
				end
			end
			local wheel = #picks == 0
			if wheel then
				local pool = {}
				for _, sk in ipairs(Config.SKILLS) do
					if sk.id ~= "clone" and Config.COOLDOWN[sk.id] then
						table.insert(pool, sk.id)
					end
				end
				for _ = 1, want do
					if #pool > 0 then
						table.insert(picks, { s = table.remove(pool, math.random(1, #pool)) })
					end
				end
			end
			applyMods(plr) -- back to the basic numbers first
			local names = {}
			for slot = 1, 2 do
				local k = picks[slot]
				plr:SetAttribute("Copy" .. slot, k and k.s or nil)
				plr:SetAttribute("CopyCool" .. slot, 0)
				if k then
					local nm = k.s
					for _, sk in ipairs(Config.SKILLS) do
						if sk.id == k.s then
							nm = sk.name
						end
					end
					table.insert(names, nm .. (k.p and "" or ""))
					-- Full Copy: the friend's own numbers for that skill
					if p10 == "fullcopy" and k.p then
						for _, a in ipairs({ "SneakTime", "GlowRange", "FlareTime", "FlareRange", "FlareStamina", "EchoRange", "BurstMult", "BurstTime",
							"BarricadeHold", "VineTime", "ThinkTime", "HealAmount", "HealShield", "CloneTime", "DashTime", "PullRange", "NoseRange",
							"FogRadius", "FogTime", "PatchTime", "PatchRadius", "SlipTime" }) do
							if k.p:GetAttribute(a) ~= nil then
								plr:SetAttribute(a, k.p:GetAttribute(a))
							end
						end
					end
				end
			end
			Effects.at(plr, "reveal")
			say("info", (wheel and "\u{1F3B2} Picked at random: " or "\u{1F465} ") .. plr.DisplayName .. " copied " .. table.concat(names, " and ") .. "'s skill" .. (#names > 1 and "s" or "") .. "!")
			-- Quick Change (level 20): once a game, Copycat is ready again at once
			if p20 == "quickchange" and not once["quickchange" .. plr.UserId] then
				once["quickchange" .. plr.UserId] = true
				say("info", "\u{26A1} Quick Change: Copycat is ready again!", nil, plr)
				return "free"
			end
			return true
		elseif skill == "harmony" then
			-- Lullaby (4 Nov): the host near her walks at half speed for a while
			local Hm = Config.HARMONY
			if #liveHosts() == 0 then
				say("info", "\u{1F3B5} Save your Lullaby for when the host is out.", nil, plr)
				return false
			end
			-- 4 Nov (Brent: no clear reach): measured flat (not up and down), and
			-- a too-far host is told in studs. 5 Nov (Brent: failed with the host
			-- in the circle): measured to the edge of his body, not his middle,
			-- 2 studs of grace for him walking in as she presses, and every host
			-- in reach is slowed (Claus Manor has two)
			local reach = plr:GetAttribute("LullabyRange") or Hm.range
			local hum = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
			local feet = hrp.Position - Vector3.new(0, hrp.Size.Y / 2 + (hum and hum.HipHeight or 2), 0) -- (the floor under her)
			local caught, nearest = {}, math.huge
			for _, h in ipairs(liveHosts()) do
				local cf, size = h.model:GetBoundingBox()
				local body = math.min(math.max(size.X, size.Z) / 2, 5)
				local gap = Vector3.new(cf.Position.X - hrp.Position.X, 0, cf.Position.Z - hrp.Position.Z).Magnitude - body
				nearest = math.min(nearest, gap)
				if gap <= reach + 2 then
					table.insert(caught, h)
				end
			end
			if #caught == 0 then
				Effects.zone(feet, Color3.fromRGB(180, 140, 230), reach * 2, 2.5)
				say("info", "\u{1F3B5} The host is " .. math.max(1, math.floor(nearest - reach)) .. " studs outside your Lullaby (the purple circle). Sing when he's inside it.", nil, plr)
				return "miss" -- (5 Nov) a short wait, not the whole recharge
			end
			local seconds = plr:GetAttribute("LullabyTime") or Hm.seconds
			for _, h in ipairs(caught) do
				h.slowUntil = os.clock() + seconds
				h.slowMult = Hm.slow
				if p20 == "crescendo" then
					h:stun(Hm.crescendoStop) -- Crescendo: a full stop first (5 Nov: 2 s, was 1)
				end
				Effects.stars(h.model, seconds, Color3.fromRGB(190, 140, 255))
			end
			plr:SetAttribute("LullabyUntil", workspace:GetServerTimeNow() + seconds)
			-- 5 Nov (Brent): she and every friend inside the circle run faster
			-- for a moment (a stronger burst already running is kept)
			do
				local run = plr:GetAttribute("LullabyRun") or Hm.runTime
				local mult = p20 == "crescendo" and Hm.crescendoRun or Hm.run -- (5 Nov) Crescendo: 15%
				local now2 = workspace:GetServerTimeNow()
				for _, p in ipairs(Players:GetPlayers()) do
					local h = hrpOf(p)
					if h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped")
						and Vector3.new(h.Position.X - hrp.Position.X, 0, h.Position.Z - hrp.Position.Z).Magnitude <= reach then
						local busy = (p:GetAttribute("TeamBurstUntil") or 0) > now2 and (p:GetAttribute("TeamBurstMult") or 1) > mult
						if not busy then
							p:SetAttribute("TeamBurstMult", mult)
							p:SetAttribute("TeamBurstUntil", now2 + run)
							Effects.aura(p, "speed", run)
						end
					end
				end
			end
			-- 5 Nov (Brent: it has to feel instant): the whole reach lights up at
			-- once (no ring spreading out); purple notes circle the host for as
			-- long as he is slowed - the slow itself starts the moment she sings
			Effects.zone(feet, Color3.fromRGB(180, 140, 230), reach * 2, 1.2)
			-- Chorus (level 10): every friend's recharge 5 s nearer
			if p10 == "chorus" then
				local now2 = workspace:GetServerTimeNow()
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= plr and (p:GetAttribute("CoolUntil") or 0) > now2 then
						p:SetAttribute("CoolUntil", p:GetAttribute("CoolUntil") - Hm.chorus)
					end
				end
			end
			say("info", "\u{1F3B5} " .. plr.DisplayName .. " sang a Lullaby - the host is sleepy and slow for " .. seconds .. " s!" .. (p10 == "chorus" and " Everyone's skills are 5 s nearer!" or ""))
			return true
		end
		return nil -- not a new button
	end

	-- after the old buttons: the powers that ride on them
	function round.skillAfter(plr, skill, hrp, pos)
		local p10, p20 = plr:GetAttribute("Power10"), plr:GetAttribute("Power20")
		if skill == "shadow" and (p10 == "clone" or p20 == "doubleclone") then
			round.shadowClone(plr, p20 == "doubleclone" and 2 or 1)
		elseif skill == "patch" and p10 == "hug" then
			local n = 0
			for _, p in ipairs(Players:GetPlayers()) do
				local h = hrpOf(p)
				if p ~= plr and h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and (h.Position - hrp.Position).Magnitude < 20 then
					Boost:FireClient(p, "stamina")
					Effects.at(p, "heal")
					n += 1
				end
			end
			if n > 0 then
				say("info", "\u{1F917} Group Hug! " .. n .. (n == 1 and " friend" or " friends") .. " got all their stamina back.")
			end
		elseif skill == "glow" then
			do
				local f = Config.GLOW_FLARE
				local seconds = plr:GetAttribute("FlareTime") or f.seconds
				local range = plr:GetAttribute("FlareRange") or f.range
				local stam = plr:GetAttribute("FlareStamina") or f.stamina
				local got = {}
				local myState = state
				if plr:GetAttribute("Power20") == "beacon" then
					-- Beacon: the whole team, wherever they are, gets the big lift at once
					local bc = f.beacon
					for _, p in ipairs(Players:GetPlayers()) do
						if hrpOf(p) and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") then
							got[p] = true
							p:SetAttribute("TeamBurstMult", bc.speed)
							p:SetAttribute("TeamBurstUntil", workspace:GetServerTimeNow() + bc.speedTime)
							Boost:FireClient(p, "plus", bc.stamina)
							Effects.at(p, "light")
							if p ~= plr then
								say("info", "\u{2728} Glow's Beacon! +" .. bc.stamina .. "% stamina and 5% faster for " .. bc.speedTime .. " s.", nil, p)
							end
						end
					end
				end
				-- 5 Nov (Brent): Little Sun - the Flare fills the whole room she's in,
				-- and a host in that room is blinded 1 s
				local sun = plr:GetAttribute("Power20") == "sun"
				local function roomRect(pos)
					local tx, ty = math.floor(pos.X / T), math.floor(pos.Z / T)
					for _, fl in ipairs(HouseMap.floors) do
						if tx >= fl.x0 and tx <= fl.x1 and ty >= fl.y0 and ty <= fl.y1 then
							return fl
						end
					end
					return nil
				end
				if sun then
					local room = roomRect(hrp.Position)
					for _, h in ipairs(liveHosts()) do
						if room and roomRect(h.root.Position) == room then
							h:stun(1)
							say("info", "\u{2600} Little Sun! The host is blinded for a moment.")
						end
					end
				end
				task.spawn(function()
					local stopAt = os.clock() + seconds
					while os.clock() < stopAt and state == myState and state.status == "playing" do
						local gh = hrpOf(plr)
						if not gh then
							break
						end
						local myRoom = sun and roomRect(gh.Position) or nil
						for _, p in ipairs(Players:GetPlayers()) do
							local h = hrpOf(p)
							if h and not got[p] and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped")
								and ((h.Position - gh.Position).Magnitude <= range or (myRoom ~= nil and roomRect(h.Position) == myRoom)) then
								got[p] = true
								p:SetAttribute("TeamBurstMult", f.speed)
								p:SetAttribute("TeamBurstUntil", workspace:GetServerTimeNow() + f.speedTime)
								Boost:FireClient(p, "plus", stam)
								Effects.at(p, "light")
								if p ~= plr then
									say("info", "\u{2728} Glow's Flare! +" .. stam .. "% stamina and 5% faster for " .. f.speedTime .. " s.", nil, p)
								end
							end
						end
						task.wait(0.25)
					end
				end)
			end
			local light = plr.Character and plr.Character:FindFirstChild("Head") and plr.Character.Head:FindFirstChild("GlowBulb")
			light = light and light:FindFirstChildOfClass("PointLight")
			local range = light and light.Range or 40
			if p10 == "nightlight" then
				local lamp = Instance.new("Part")
				lamp.Name = "NightLight"
				lamp.Shape = Enum.PartType.Ball
				lamp.Size = Vector3.new(1.4, 1.4, 1.4)
				lamp.Material = Enum.Material.Neon
				lamp.Color = Color3.fromRGB(255, 242, 160)
				lamp.Anchored, lamp.CanCollide, lamp.CanQuery = true, false, false
				lamp.Position = hrp.Position + Vector3.new(0, 4, 0)
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 242, 160), Config.NIGHT_LIGHT.range, 1.5
				l.Parent = lamp
				lamp.Parent = world.root
				-- 5 Nov (Brent): anyone who comes within `near` studs of the lamp
				-- while it burns gets a stamina lift, once
				do
					local NL = Config.NIGHT_LIGHT
					local lampState, warmed = state, {}
					task.spawn(function()
						while lamp.Parent and state == lampState and state.status == "playing" do
							for _, p in ipairs(Players:GetPlayers()) do
								local h = hrpOf(p)
								if h and not warmed[p] and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and (h.Position - lamp.Position).Magnitude <= NL.near then
									warmed[p] = true
									Boost:FireClient(p, "plus", NL.stamina)
									Effects.at(p, "light")
									say("info", "\u{1F4A1} Glow's Night Light: +" .. NL.stamina .. "% stamina!", nil, p)
								end
							end
							task.wait(0.3)
						end
					end)
				end
				local tx, ty = math.floor(hrp.Position.X / T), math.floor(hrp.Position.Z / T)
				for _, f in ipairs(HouseMap.floors) do
					if tx >= f.x0 and tx <= f.x1 and ty >= f.y0 and ty <= f.y1 and world.dark[f.name] then
						world.setDark(f.name, false)
					end
				end
				game:GetService("Debris"):AddItem(lamp, Config.NIGHT_LIGHT.seconds)
			elseif p10 == "dazzle" and hostNear(hrp.Position, range) then
				round:skillStun(2, "\u{2728} Dazzled! The host stops to rub his eyes.", hrp.Position)
			end
			if p20 == "beacon" then
				local seconds = plr:GetAttribute("FlareTime") or Config.GLOW_FLARE.seconds
				for _, p in ipairs(Players:GetPlayers()) do
					if p.Character and not p:GetAttribute("Escaped") then
						local hl = Instance.new("Highlight")
						hl.Name = "Beacon"
						hl.FillTransparency, hl.FillColor, hl.OutlineColor = 0.7, Color3.fromRGB(255, 242, 160), Color3.fromRGB(255, 220, 90)
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.Parent = p.Character
						game:GetService("Debris"):AddItem(hl, seconds)
					end
				end
			end
		elseif skill == "echo" then
			-- the burst: Echo herself runs faster for a moment
			plr:SetAttribute("TeamBurstMult", plr:GetAttribute("BurstMult") or Config.ECHO_BURST.mult)
			plr:SetAttribute("TeamBurstUntil", workspace:GetServerTimeNow() + (plr:GetAttribute("BurstTime") or Config.ECHO_BURST.seconds))
			plr:SetAttribute("EchoBurstUntil", plr:GetAttribute("TeamBurstUntil"))
			if p10 == "echomap" then
				-- 4 Nov (Brent): the whole team sees the host (Echo already
				-- sees him near with Sharp Ears)
				say("hostmap", "\u{1F3A7} Echo Map: " .. plr.DisplayName .. " hears exactly where the host is - look!", { seconds = 5 })
			end
			if p20 == "soundwave" and typeof(pos) == "Vector3" and hostNear(pos, 12) then
				round:skillStun(1, "\u{1F4A5} Sound Wave! The host is stunned by the noise.", pos)
			end
		end
	end

	-- a shimmering bubble on anyone with a Party Shield; a golden streak
	-- behind anyone in a burst of speed
	task.spawn(function()
		while true do
			task.wait(0.25)
			local nowS = workspace:GetServerTimeNow()
			for _, p in ipairs(Players:GetPlayers()) do
				local playing = state.status == "playing" and not p:GetAttribute("Escaped") and not p:GetAttribute("Caged")
					and not p:GetAttribute("Hidden") and not p:GetAttribute("Crawling")
				Effects.shield(p, playing and p:GetAttribute("Shield") == true)
				local left = (p:GetAttribute("TeamBurstUntil") or 0) - nowS
				if playing and left > 0.2 then
					Effects.aura(p, "speed", left)
				end
			end
		end
	end)

	-- Patch's level-20 powers: Guardian (once a game) and Medic Run
	task.spawn(function()
		while true do
			task.wait(0.5)
			if state.status == "playing" and world then
				for _, patch in ipairs(Players:GetPlayers()) do
					local p20 = patch:GetAttribute("Skill") == "patch" and patch:GetAttribute("Power20")
					local ph = hrpOf(patch)
					if p20 == "medicrun" and ph then
						local near = false
						for _, p in ipairs(Players:GetPlayers()) do
							local h = hrpOf(p)
							if p ~= patch and h and not p:GetAttribute("Caged") and (h.Position - ph.Position).Magnitude < 14 then
								near = true
							end
						end
						patch:SetAttribute("RunBonus", near and 1.1 or 1)
					end
					-- (5 Nov) Guardian is now Jailbreak, a button (below)
				end
			end
		end
	end)
end

-- ---------- after a round: play again or go back to the lobby ----------
local votes = {}
local voting = false

-- ---------- rejoining after a dropped connection ----------
-- The Lobby sends this server's access code in the teleport data. A player
-- who drops out mid-game (not on purpose) is remembered here and in a
-- MemoryStore the Lobby reads: back in the Lobby they are offered "Rejoin".
-- While this server runs it says so every 30 s (EC_Live), so the Lobby never
-- sends anyone to a game that has closed.
local MemoryStoreService = game:GetService("MemoryStoreService")
local rejoinMap, liveMap
pcall(function()
	rejoinMap = MemoryStoreService:GetHashMap("EC_Rejoin")
	liveMap = MemoryStoreService:GetHashMap("EC_Live")
end)
local serverCode = nil -- this reserved server's access code (from the Lobby)
local expectedPlayers = {} -- [userId] = true: the party members the Lobby sent here (the first game waits for them)
local firstArrival = nil -- os.clock() when the first of them arrived
local leaving = {} -- [userId] = true: going to the Lobby on purpose
local dropped = {} -- [userId] = { skill, caged, escaped }: dropped out mid-game
local rejoining = {} -- [userId] = what they had, while they come back in
task.spawn(function()
	while true do
		if serverCode and liveMap then
			pcall(function()
				liveMap:SetAsync(game.JobId, true, 90)
			end)
		end
		task.wait(30)
	end
end)

local function toLobby(list)
	local lobbyId = Places.lobby()
	if not lobbyId or #list == 0 then
		return false
	end
	for _, p in ipairs(list) do
		leaving[p.UserId] = true
	end
	local ok = pcall(function()
		TeleportService:TeleportAsync(lobbyId, list)
	end)
	return ok
end

-- a player leaves the game for the Lobby at any time (their boosts go back
-- to their bag and their points are saved when they leave)
local LeaveToLobby = remote("LeaveToLobby")
LeaveToLobby.OnServerEvent:Connect(function(plr)
	if not toLobby({ plr }) then
		say("info", "Going back to the Lobby only works in the published game (not in a Studio test).", nil, plr)
	end
end)


-- 3 Nov (Brent): the results wait for a choice - nobody is moved on without
-- choosing. Once someone picks Play again / Next floor, the rest have
-- Config.END_WAIT.others seconds (then they go to the lobby); if nobody
-- chooses, everyone goes to the lobby after END_WAIT.idle. Everyone chosen:
-- the next game starts at once. RoundState VoteEnds / VoteMode feed the
-- results screen's countdown.
function round.startVote()
	votes = {}
	voting = true
	local w = Config.END_WAIT
	local began, firstChoice = os.clock(), nil
	RoundState:SetAttribute("VoteMode", "idle")
	RoundState:SetAttribute("VoteEnds", workspace:GetServerTimeNow() + w.idle)
	task.spawn(function()
		while voting do
			task.wait(0.5)
			local playing, undecided = 0, 0
			for _, plr in ipairs(Players:GetPlayers()) do
				local v = votes[plr.UserId]
				if v == "again" or v == "next" then
					playing += 1
				elseif v ~= "lobby" then
					undecided += 1
				end
			end
			if playing > 0 and not firstChoice then
				firstChoice = os.clock()
				RoundState:SetAttribute("VoteMode", "others")
				RoundState:SetAttribute("VoteEnds", workspace:GetServerTimeNow() + w.others)
			end
			if (playing > 0 and undecided == 0) or (firstChoice and os.clock() - firstChoice >= w.others)
				or (not firstChoice and os.clock() - began >= w.idle) or (playing == 0 and undecided == 0) then
				break
			end
		end
		if not voting then
			return
		end
		voting = false
		RoundState:SetAttribute("VoteMode", nil)
		local again, rest = {}, {}
		local up, same = 0, 0
		for _, plr in ipairs(Players:GetPlayers()) do
			if votes[plr.UserId] == "again" or votes[plr.UserId] == "next" then
				table.insert(again, plr)
				if votes[plr.UserId] == "next" then
					up += 1
				else
					same += 1
				end
			elseif votes[plr.UserId] ~= "lobby" then
				-- didn't choose in time: back to the lobby
				table.insert(rest, plr)
			end
		end
		if #again == 0 and #rest == 0 then
			return -- everyone chose the lobby and is on the way there
		end
		-- most of those staying chose the floor above: go up (a tie goes up)
		local nf = nextFloor()
		if RoundState:GetAttribute("Tower") then
			RoundState:SetAttribute("Map", RoundState:GetAttribute("TowerStart") or RoundState:GetAttribute("Map"))
			nf = nil
		end
		if nf and up > 0 and up >= same then
			RoundState:SetAttribute("Map", nf.id)
		end
		-- anyone who did not choose goes back to the lobby (if there is one)
		if #again > 0 or not toLobby(rest) then
			if #again > 0 then
				toLobby(rest)
			end
			round.start()
		end
	end)
end

Vote.OnServerEvent:Connect(function(plr, choice)
	if not voting or (choice ~= "again" and choice ~= "lobby" and choice ~= "next") then
		return
	end
	if choice == "next" and not nextFloor() then
		choice = "again"
	end
	votes[plr.UserId] = choice
	if choice == "lobby" then
		if not toLobby({ plr }) then
			say("info", "The lobby only works in the published game - you'll play again here.", nil, plr)
			votes[plr.UserId] = "again"
		end
	end
	say("vote", plr.DisplayName .. (choice == "again" and " wants to play again!" or choice == "next" and " wants to go up to the next floor!" or " went back to the lobby."))
end)

-- ---------- requests from players ----------
Press.OnServerEvent:Connect(function(plr, colour)
	if state.status ~= "playing" or state.doorOpen or typeof(colour) ~= "string" or not Config.COLOR3[colour] then
		return
	end
	local hrp = hrpOf(plr)
	if not hrp or (hrp.Position - world.objects.door.keypad.Position).Magnitude > 16 then
		return
	end
	state.entry[plr.UserId] = state.entry[plr.UserId] or {}
	local e = state.entry[plr.UserId]
	table.insert(e, colour)
	if #e < #state.code then
		return
	end
	state.entry[plr.UserId] = {}
	local right = true
	for i = 1, #state.code do
		right = right and e[i] == state.code[i]
	end
	if right then
		openDoor(plr, "code")
	else
		say("wrong", "Wrong code! And that was LOUD... something is coming.", nil, plr)
		Effects.sound(world.objects.door.keypad.Position, "wrong", 1)
		if host then
			alertHosts(world.objects.door.keypad.Position)
		end
	end
end)

local function pickFor(plr, s)
	plr:SetAttribute("Skill", s.id)
	applyMods(plr)
	if not Characters.apply(plr, modelFor(plr, s)) then
		local char = plr.Character
		if char and char:GetAttribute("EscapeCrewChar") then
			plr:LoadCharacter()
		else
			gear(plr)
		end
	end
end

PickSkill.OnServerEvent:Connect(function(plr, id)
	if typeof(id) ~= "string" then
		return
	end
	-- choose freely until the host comes out; after that, wait for the next game
	-- characters are locked once the game's clock starts (everyone has chosen)
	if state.status == "playing" and (RoundState:GetAttribute("HostOut") or (state.endsAt and state.endsAt ~= math.huge)) and plr:GetAttribute("Skill") then
		return say("info", "The game has started - you can change character before the next game.", nil, plr)
	end
	for _, s in ipairs(Config.SKILLS) do
		if s.id == id then
			-- a character you unlock (Nutmeg): only once it's yours
			if not Unlocks.owns(plr, id) then
				local u = Config.CHARACTER_UNLOCK[id]
				local e = u and Seasons.get(u.season)
				local pd = Profile.get(plr)
				local how = Unlocks.howText(id, pd and pd.stats)
				return say("info", "\u{1F512} " .. s.name .. " is locked - " .. (how and (how .. ", or ") or "") .. "get " .. s.name .. " in the Lobby's Shop" .. (e and (" (" .. u.price .. " " .. e.many .. " while it's open)") or "") .. ".", nil, plr)
			end
			plr:SetAttribute("Skill", id)
			applyMods(plr)
			-- Holly's Peppermint Pockets (level 10): a free Candy Corn, once a game
			if id == "holly" and plr:GetAttribute("Power10") == "pockets" and not plr:GetAttribute("PocketsGiven") then
				plr:SetAttribute("PocketsGiven", true)
				bags[plr.UserId] = bags[plr.UserId] or {}
				table.insert(bags[plr.UserId], "candy")
				paintBag(plr)
				say("info", "\u{1F36C} Peppermint Pockets: a free Candy Corn in your bag!", nil, plr)
			end
			if not Characters.apply(plr, modelFor(plr, s)) then
				local char = plr.Character
				if char and char:GetAttribute("EscapeCrewChar") then
					-- leaving a 3D character for one without a model yet:
					-- back to the player's own avatar (it respawns at the start)
					plr:LoadCharacter()
				else
					gear(plr)
				end
			end
			return
		end
	end
end)

-- Play on the character screen: this player is ready (the game starts when
-- everyone is, or when PICK_WAIT runs out)
ReadyUp.OnServerEvent:Connect(function(plr)
	if plr:GetAttribute("Skill") then
		plr:SetAttribute("Ready", true)
	end
end)

-- Cloud's fogs (4 Nov, Config.CLOUD). Each: where, how big, until when, who made
-- it, and its powers - follow (Rolling Fog), storm (Storm Cloud), lining
-- (Silver Lining). Five times a second every kid inside one is Fogged (the host
-- can't see or grab them, as at a hiding spot); a storm stops a host it covers
local fogs = {}
function round.makeFog(owner, center, r, seconds, opts)
	local storm = opts.storm
	local m = Instance.new("Model")
	m.Name = storm and "StormCloud" or "CloudFog"
	local puffs = {}
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(r * 1.3, r * 1.1, r * 1.3)
		p.Material = Enum.Material.SmoothPlastic
		p.Color = storm and Color3.fromRGB(110, 115, 135) or Color3.fromRGB(235, 240, 250)
		p.Transparency = 0.35
		p:SetAttribute("Off", Vector3.new(math.cos(a) * r * 0.45, 2.2 + (k % 2) * 0.8, math.sin(a) * r * 0.45))
		p.Parent = m
		table.insert(puffs, p)
	end
	local mist = Instance.new("ParticleEmitter")
	mist.Color = ColorSequence.new(storm and Color3.fromRGB(150, 155, 170) or Color3.fromRGB(245, 248, 255))
	mist.Size = NumberSequence.new(3, 5)
	mist.Transparency = NumberSequence.new(0.5, 1)
	mist.Lifetime = NumberRange.new(1.5, 2.5)
	mist.Rate = 25
	mist.Speed = NumberRange.new(1, 2)
	mist.SpreadAngle = Vector2.new(180, 180)
	mist.Parent = puffs[1]
	m.Parent = world.root
	local f = { owner = owner, pos = center, r = r, untilT = workspace:GetServerTimeNow() + seconds, model = m, puffs = puffs,
		follow = opts.follow, storm = storm, lining = opts.lining, world = world }
	local function place()
		for _, p in ipairs(f.puffs) do
			p.Position = f.pos + p:GetAttribute("Off")
		end
	end
	place()
	f.place = place
	table.insert(fogs, f)
	-- 4 Nov: everyone already inside is hidden at once (not at the next check)
	for _, p in ipairs(Players:GetPlayers()) do
		local h = hrpOf(p)
		if h and state.status == "playing" and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped")
			and (Vector3.new(h.Position.X, 0, h.Position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude <= r + (Config.CLOUD.edge or 0) then
			p:SetAttribute("Fogged", true)
		end
	end
	Effects.sound(center, "sneak", 0.8)
	return f
end
-- a lightning bolt flashing down through a storm cloud
local function lightning(at)
	local parts = {}
	local p = at + Vector3.new(0, 8, 0)
	for _ = 1, 4 do
		local q = p + Vector3.new(math.random(-15, 15) / 10, -2, math.random(-15, 15) / 10)
		local bolt = Instance.new("Part")
		bolt.Anchored, bolt.CanCollide, bolt.CanQuery, bolt.CanTouch = true, false, false, false
		bolt.Material = Enum.Material.Neon
		bolt.Color = Color3.fromRGB(255, 240, 120)
		bolt.Size = Vector3.new(0.25, 0.25, (q - p).Magnitude)
		bolt.CFrame = CFrame.lookAt((p + q) / 2, q)
		bolt.Parent = world.root
		table.insert(parts, bolt)
		p = q
	end
	Effects.sound(at, "bonk", 1)
	task.delay(0.35, function()
		for _, b in ipairs(parts) do
			b:Destroy()
		end
	end)
end
task.spawn(function()
	local fogOf = {} -- player -> the fog they were in a moment ago
	while true do
		task.wait(0.2)
		local now = workspace:GetServerTimeNow()
		for i = #fogs, 1, -1 do
			local f = fogs[i]
			if now >= f.untilT or f.world ~= world or not f.model.Parent then
				f.model:Destroy()
				table.remove(fogs, i)
			else
				local oh = f.follow and hrpOf(f.owner)
				if oh and not f.owner:GetAttribute("Caged") then
					f.pos = Vector3.new(oh.Position.X, f.pos.Y, oh.Position.Z) -- Rolling Fog
					f.place()
				end
				local host = nearestHost(f.pos) -- (5 Nov) the Claus under the cloud
				-- Storm Cloud: a host under it stops (once a fog), with lightning
				if f.storm and not f.stopped and host and host.model and host.root
					and (Vector3.new(host.root.Position.X, 0, host.root.Position.Z) - Vector3.new(f.pos.X, 0, f.pos.Z)).Magnitude <= f.r + 2 then
					f.stopped = true
					host:stun(Config.CLOUD.stormStop)
					lightning(host.root.Position)
					say("info", "\u{26A1} Lightning! " .. f.owner.DisplayName .. "'s storm cloud stopped the host for " .. Config.CLOUD.stormStop .. " s!")
				end
			end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			local h = hrpOf(p)
			local inside
			if h and state.status == "playing" and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") then
				for _, f in ipairs(fogs) do
					-- (+ edge: the cloud drawn reaches about a stud past its radius)
					if (Vector3.new(h.Position.X, 0, h.Position.Z) - Vector3.new(f.pos.X, 0, f.pos.Z)).Magnitude <= f.r + (Config.CLOUD.edge or 0) then
						inside = f
						break
					end
				end
			end
			local was = fogOf[p]
			if (inside ~= nil) ~= (p:GetAttribute("Fogged") == true) then
				p:SetAttribute("Fogged", inside ~= nil)
			end
			-- Silver Lining: a friend stepping out of her fog gets a little speed
			if was and not inside and was.lining and p ~= was.owner and now < was.untilT then
				p:SetAttribute("TeamBurstMult", Config.CLOUD.liningSpeed)
				p:SetAttribute("TeamBurstUntil", now + Config.CLOUD.liningTime)
				Effects.aura(p, "speed", Config.CLOUD.liningTime)
			end
			fogOf[p] = inside
		end
	end
end)

-- Harmony's In Tune (4 Nov): twice a second, every friend within
-- Config.HARMONY.tune studs of a Harmony is InTune - their screen refills their
-- stamina faster
task.spawn(function()
	while true do
		task.wait(0.5)
		local singers = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("Skill") == "harmony" and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and hrpOf(p) then
				table.insert(singers, p)
			end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			local h = hrpOf(p)
			local tuned = false
			if h and state.status == "playing" then
				for _, s in ipairs(singers) do
					if s ~= p and (hrpOf(s).Position - h.Position).Magnitude <= Config.HARMONY.tune then
						tuned = true
					end
				end
			end
			if (p:GetAttribute("InTune") == true) ~= tuned then
				p:SetAttribute("InTune", tuned)
			end
		end
	end
end)

-- Elfy's Workshop Helper (5 Nov, Brent): once a second, every friend within
-- Config.ELFY.helpNear studs of an Elfy gets `help` s taken off each skill
-- recharge still running (their own button and Clone's copies) - their skills
-- come back 15% faster while they stay near him. More than one Elfy: no stacking
task.spawn(function()
	while true do
		task.wait(1)
		if state.status == "playing" then
			local elves = {}
			for _, p in ipairs(Players:GetPlayers()) do
				if p:GetAttribute("Skill") == "elfy" and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and hrpOf(p) then
					table.insert(elves, p)
				end
			end
			if #elves > 0 then
				local E = Config.ELFY
				local now = workspace:GetServerTimeNow()
				for _, p in ipairs(Players:GetPlayers()) do
					local h = hrpOf(p)
					local near = false
					if h and not p:GetAttribute("Escaped") then
						for _, e in ipairs(elves) do
							local eh = hrpOf(e)
							if e ~= p and eh and (eh.Position - h.Position).Magnitude <= E.helpNear then
								near = true
							end
						end
					end
					if near then
						for _, k in ipairs({ "CoolUntil", "CopyCool1", "CopyCool2" }) do
							local u = p:GetAttribute(k) or 0
							if u > now then
								p:SetAttribute(k, math.max(now, u - E.help))
							end
						end
					end
				end
			end
		end
	end
end)

-- Nutmeg's Jingle Bells (level 20; 4 Nov, Brent: her choice when, not her first
-- dash): its own button, once a game - the host freezes for Config.NUTMEG.bells
-- seconds wherever he is. Not used up while the host isn't out yet
RingBells.OnServerEvent:Connect(function(plr)
	if plr:GetAttribute("Skill") ~= "nutmeg" or plr:GetAttribute("Power20") ~= "bells" or plr:GetAttribute("BellsUsed")
		or state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
		return
	end
	if not (host and host.model) then
		return say("info", "\u{1F514} The host isn't out yet - save your Jingle Bells for when he is.", nil, plr)
	end
	local seconds = Config.NUTMEG.bells
	plr:SetAttribute("BellsUsed", true)
	for _, h in ipairs(liveHosts()) do -- (5 Nov) both Clauses
		h:stun(seconds)
	end
	RoundState:SetAttribute("FrozenUntil", workspace:GetServerTimeNow() + seconds)
	local h = hrpOf(plr)
	if h then
		Effects.sound(h.Position, "bell", 1)
		Effects.at(plr, "reveal")
	end
	say("info", "\u{1F514}\u{1F514} " .. plr.DisplayName .. " rang the Jingle Bells! The host is frozen for " .. seconds .. " seconds!")
end)

-- Holly's Holly Hedge (level 20; 4 Nov): its own button, once a game, at the
-- nearest doorway (not used up when there's no doorway close by)
GrowHedge.OnServerEvent:Connect(function(plr)
	if plr:GetAttribute("Skill") ~= "holly" or plr:GetAttribute("Power20") ~= "hedge" or plr:GetAttribute("HedgeUsed")
		or state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
		return
	end
	if round.hollyHedge(plr) then
		plr:SetAttribute("HedgeUsed", true)
	end
end)

-- a skill used by its own button - or (4 Nov) one of Clone's copies of a
-- friend's (slot 1 / 2), which runs just like the friend's own, at its basic
-- strength (Full Copy: the friend's), with its own recharge CopyCool1 / 2
local function runSkill(plr, skill, pos, slot)
	local cd = Config.COOLDOWN[skill]
	if not cd or state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
		return
	end
	local coolKey = slot and ("CopyCool" .. slot) or "CoolUntil"
	local coolMult = slot and (plr:GetAttribute("Power10") == "quickcopy" and 0.85 or 1) or (plr:GetAttribute("CooldownMult") or 1)
	local now = workspace:GetServerTimeNow()
	if (plr:GetAttribute(coolKey) or 0) > now then
		return say("info", (slot and "That copied skill is" or "Your skill is") .. " recharging... " .. math.ceil(plr:GetAttribute(coolKey) - now) .. " seconds", nil, plr)
	end
	local hrp = hrpOf(plr)
	if not hrp then
		return
	end
	-- skills version 2: Tinker's Toolkit, Brainy's Think!, Bramble's Vines
	local v2 = round.skillV2(plr, skill, hrp, pos)
	if v2 ~= nil then
		if v2 == "free" then
			quest(plr, "skill") -- worked, and the button is ready again at once (Cloud's Fog Bank)
		elseif v2 == "miss" then
			plr:SetAttribute(coolKey, now + 3) -- (5 Nov) Harmony's Lullaby missed: try again in 3 s
		elseif v2 then
			-- Tinker's Rocket Boots: a rocket run after each Toolkit
			if skill == "tinker" and not slot and plr:GetAttribute("Power20") == "boots" then
				local rb = Config.ROCKET_BOOTS
				plr:SetAttribute("TeamBurstMult", rb.mult)
				plr:SetAttribute("TeamBurstUntil", now + rb.seconds)
				Effects.aura(plr, "speed", rb.seconds)
				say("info", "\u{1F680} Rocket Boots! Run!", nil, plr)
			end
			plr:SetAttribute(coolKey, now + cd * coolMult)
			quest(plr, "skill")
		end
		return
	end
	if skill == "shadow" then
		plr:SetAttribute("SneakUntil", now + (plr:GetAttribute("SneakTime") or 6))
		Effects.at(plr, "sneak")
		Effects.aura(plr, "sneak", plr:GetAttribute("SneakTime") or 6)
		say("sneak", plr.DisplayName .. " is sneaking - the host cannot see or grab them for " .. (plr:GetAttribute("SneakTime") or 6) .. " seconds!", { userId = plr.UserId })
	elseif skill == "patch" then
		-- a Party Shield for the nearest friend without one (every friend
		-- nearby without one with Shields for All); if no friend near needs one,
		-- Patch shields herself - for Config.SELF_SHIELD seconds (10 Oct, Brent:
		-- friends' shields last until a grab, hers runs out)
		local nearest, nd, given = nil, math.huge, 0
		for _, p in ipairs(Players:GetPlayers()) do
			local h = hrpOf(p)
			if p ~= plr and h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and not p:GetAttribute("Shield") then
				local d = (h.Position - hrp.Position).Magnitude
				if d < 18 then
					if plr:GetAttribute("HealShield") then
						p:SetAttribute("Shield", true)
						p:SetAttribute("SelfShieldAt", nil)
						given += 1
					elseif d < nd then
						nearest, nd = p, d
					end
				end
			end
		end
		if nearest then
			nearest:SetAttribute("Shield", true)
			nearest:SetAttribute("SelfShieldAt", nil)
			given += 1
		end
		if given == 0 then
			if plr:GetAttribute("Shield") and plr:GetAttribute("SelfShieldAt") == nil then
				-- already holds a lasting shield: it stays as it is
			else
				local mark = workspace:GetServerTimeNow()
				plr:SetAttribute("Shield", true)
				plr:SetAttribute("SelfShieldAt", mark)
				local secs = Config.SELF_SHIELD or 30
				plr:SetAttribute("SelfShieldUntil", mark + secs)
				task.delay(secs, function()
					if plr.Parent and plr:GetAttribute("SelfShieldAt") == mark and plr:GetAttribute("Shield") and (plr:GetAttribute("ExtraShields") or 0) == 0 then
						plr:SetAttribute("Shield", false)
						plr:SetAttribute("SelfShieldAt", nil)
						say("info", "\u{1F6E1} Your own Party Shield wore off.", nil, plr)
					end
				end)
			end
		end
		Effects.at(plr, "heal")
		Effects.ring(hrp.Position - Vector3.new(0, 2.8, 0), Color3.fromRGB(123, 227, 107), 36, 0.8)
		say("heal", given == 0 and ("Patch gave herself a Party Shield (" .. (Config.SELF_SHIELD or 30) .. " s)!") or ("Patch handed out " .. given .. (given == 1 and " Party Shield" or " Party Shields") .. " - one grab each!"), { userId = plr.UserId })
	elseif skill == "muscle" then
		local best, bd = nil, Config.BARRICADE.reach
		for _, c in ipairs(world.crates or {}) do
			local d = (c.part.Position - hrp.Position).Magnitude
			if not c.busy and d < bd then
				best, bd = c, d
			end
		end
		if not best then
			if plr:GetAttribute("Power10") == "pound" then
				-- Ground Pound: no crate here, so stamp the floor
				Effects.burst(hrp.Position, "shove")
				Effects.sound(hrp.Position, "shove", 1.2)
				local floorAt = hrp.Position - Vector3.new(0, 2.8, 0)
				Effects.ring(floorAt, Color3.fromRGB(200, 160, 110), Config.POUND.range * 2, 0.6)
				Effects.ring(floorAt, Color3.fromRGB(255, 230, 190), Config.POUND.range * 1.4, 0.5, 0.12)
				for _, p in ipairs(Players:GetPlayers()) do
					local h = hrpOf(p)
					if h and (h.Position - hrp.Position).Magnitude < 40 then
						Boost:FireClient(p, "shake", p == plr and 1 or 0.6)
					end
				end
				if hostNear(hrp.Position, Config.POUND.range) then
					round:skillStun(Config.POUND.stun, "\u{1F4A5} GROUND POUND! " .. plr.DisplayName .. " stunned the host!", hrp.Position)
				else
					say("info", "\u{1F4A5} Ground Pound! (The host was too far away to feel it.)", nil, plr)
				end
			else
				return say("info", "No \u{1F4AA} crate close by - Barricade works next to one beside a doorway.", nil, plr)
			end
		else
			barricade(plr, best)
			plr:SetAttribute("BarricadeUntil", now + Config.BARRICADE.stands)
		end
	elseif skill == "glow" then
		local head = plr.Character and plr.Character:FindFirstChild("Head")
		local bulb = head and head:FindFirstChild("GlowBulb")
		local light = bulb and bulb:FindFirstChildOfClass("PointLight")
		if not light and not slot then
			return
		end
		local f = Config.GLOW_FLARE
		local base = plr:GetAttribute("GlowRange") or 24
		local seconds = plr:GetAttribute("FlareTime") or f.seconds
		if light then -- (Clone's copied Flare has no bulb of its own: the burst of light only)
			light.Range = math.min(60, base * f.mult)
			light.Brightness = 3
		end
		plr:SetAttribute("FlareUntil", now + seconds)
		Effects.at(plr, "light")
		Effects.swell(hrp.Position, Color3.fromRGB(255, 242, 160), math.min(60, base * f.mult) * 1.2, 0.8)
		Effects.aura(plr, "flare", seconds)
		say("flare", plr.DisplayName .. "'s Flare lights up everything around!", { userId = plr.UserId })
		task.delay(seconds, function()
			if light and light.Parent then
				light.Range, light.Brightness = plr:GetAttribute("GlowRange") or 24, 1.6
			end
		end)
	elseif skill == "echo" then
		if typeof(pos) ~= "Vector3" or (pos - hrp.Position).Magnitude > (plr:GetAttribute("EchoRange") or 70) then
			return say("info", "Throw it somewhere closer!", nil, plr)
		end
		for _, h in ipairs(liveHosts()) do -- (5 Nov) both Clauses
			h:lure(pos, Config.ECHO_LURE)
		end
		Effects.burst(pos + Vector3.new(0, 1, 0), "noise")
		Effects.ring(pos, Color3.fromRGB(255, 210, 63), 24, 0.9, 0.25)
		Effects.ring(pos, Color3.fromRGB(190, 140, 255), 18, 0.9, 0.5)
		say("lure", "Echo threw a noise - the host has gone to look!", { pos = pos, userId = plr.UserId })
	end
	round.skillAfter(plr, skill, hrp, pos)
	-- two goes before the recharge: Echo's Double Throw, Muscle's Fortress,
	-- Patch's Guardian Angel (the first go doesn't start the recharge)
	local p10, p20 = plr:GetAttribute("Power10"), plr:GetAttribute("Power20")
	local twoGoes = not slot and ((skill == "echo" and p10 == "double") or (skill == "muscle" and p20 == "fortress")
		or (skill == "patch" and p10 == "twoshields"))
	if twoGoes and not plr:GetAttribute("SkillSecond") then
		plr:SetAttribute("SkillSecond", true)
		quest(plr, "skill")
		local again = { echo = "\u{1F3A7} One more noise to throw!", muscle = "\u{1F4AA} One more barricade to build!", patch = "\u{1F6E1} One more shield to give!" }
		return say("info", again[skill], nil, plr)
	end
	plr:SetAttribute("SkillSecond", false)
	-- Shadow's recharge starts when the sneak ends (never hidden all the time)
	local after = skill == "shadow" and (plr:GetAttribute("SneakTime") or 6) or 0
	plr:SetAttribute(coolKey, now + after + cd * coolMult)
	quest(plr, "skill")
end
-- Harmony's Encore (level 20; 4 Nov): its own button, once a game - a lullaby
-- the whole floor hears: the host walks at half speed for Config.HARMONY.encore s
-- Elfy's level-20 buttons (5 Nov), once a game: Toy Parade (three toys at
-- once) or Workshop Rush (every friend's skill button ready again at once)
ElfyPower.OnServerEvent:Connect(function(plr)
	local p20 = plr:GetAttribute("Power20")
	if plr:GetAttribute("Skill") ~= "elfy" or (p20 ~= "parade" and p20 ~= "rush") or plr:GetAttribute("ToyPowerUsed")
		or state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
		return
	end
	local hrp = hrpOf(plr)
	if not hrp then
		return
	end
	plr:SetAttribute("ToyPowerUsed", true)
	if p20 == "parade" then
		local look = hrp.CFrame.LookVector
		for _, a in ipairs({ 0, 120, -120 }) do
			round.windUpToy(plr, hrp, CFrame.Angles(0, math.rad(a), 0) * look, plr:GetAttribute("Power10") == "band", Config.ELFY.paradeStun)
		end
		say("info", "\u{1F941} Toy Parade! " .. plr.DisplayName .. " sent three toys marching off - the host can't follow them all!")
	else
		-- (5 Nov, Brent) every friend, anywhere in the house - and Elfy's own
		-- Wind-up Toy too: skill buttons (and Clone's copies) ready at once
		local now = workspace:GetServerTimeNow()
		for _, p in ipairs(Players:GetPlayers()) do
			if not p:GetAttribute("Escaped") then
				local was = false
				for _, k in ipairs({ "CoolUntil", "CopyCool1", "CopyCool2" }) do
					if (p:GetAttribute(k) or 0) > now then
						p:SetAttribute(k, now)
						was = true
					end
				end
				if was and hrpOf(p) then
					Effects.aura(p, "speed", 2)
				end
				if hrpOf(p) and not p:GetAttribute("Caged") then
					Boost:FireClient(p, "plus", Config.ELFY.rushStamina) -- (5 Nov) and stamina
				end
			end
		end
		say("info", "\u{1F6E0} Workshop Rush! " .. plr.DisplayName .. " fixed everyone's gadgets - every skill is ready to use again, and +" .. Config.ELFY.rushStamina .. "% stamina!")
	end
end)

-- Patch's Jailbreak (level 20; 5 Nov, Brent - was Guardian, which freed one
-- friend when she reached the cage): its own button, once a game - everyone
-- in the cage is freed, wherever Patch is. Not used up with nobody caged
Jailbreak.OnServerEvent:Connect(function(plr)
	if plr:GetAttribute("Skill") ~= "patch" or plr:GetAttribute("Power20") ~= "guardian" or plr:GetAttribute("JailbreakUsed")
		or state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
		return
	end
	-- 5 Nov (Brent): within JAILBREAK.reach studs of the cage; it takes `hold` s
	local J = Config.JAILBREAK
	local function cagePos()
		local cage = world and world.objects and world.objects.cage
		local cp = cage and (cage.part or cage.outside)
		return typeof(cp) == "Instance" and cp.Position or (typeof(cp) == "Vector3" and cp or nil)
	end
	local function near()
		local h, cp = hrpOf(plr), cagePos()
		return h and cp and (h.Position - cp).Magnitude <= J.reach
	end
	local anyone = false
	for _, p in ipairs(Players:GetPlayers()) do
		anyone = anyone or p:GetAttribute("Caged") == true
	end
	if not anyone then
		return say("info", "\u{1F513} Nobody is in the cage - save your Jailbreak for when a friend is caught.", nil, plr)
	end
	if not near() then
		return say("info", "\u{1F513} Get within " .. J.reach .. " studs of the cage to use Jailbreak.", nil, plr)
	end
	plr:SetAttribute("JailbreakUsed", true)
	say("info", "\u{1F513} " .. plr.DisplayName .. " is breaking the cage open...")
	local myState = state
	task.delay(J.hold, function()
		if state ~= myState or state.status ~= "playing" or plr:GetAttribute("Caged") or not near() then
			plr:SetAttribute("JailbreakUsed", false) -- interrupted: not used up
			return say("info", "\u{1F513} Jailbreak stopped - try again.", nil, plr)
		end
		local freed = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("Caged") then
				freeFromCage(p)
				Effects.at(p, "heal")
				table.insert(freed, p.DisplayName)
			end
		end
		say("info", "\u{1F513} Jailbreak! " .. plr.DisplayName .. " freed " .. (#freed > 0 and table.concat(freed, ", ") or "the cage") .. "!")
	end)
end)

SingEncore.OnServerEvent:Connect(function(plr)
	if plr:GetAttribute("Skill") ~= "harmony" or plr:GetAttribute("Power20") ~= "encore" or plr:GetAttribute("EncoreUsed")
		or state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
		return
	end
	if not (host and host.model) then
		return say("info", "\u{1F3B5} The host isn't out yet - save your Encore for when he is.", nil, plr)
	end
	plr:SetAttribute("EncoreUsed", true)
	for _, h in ipairs(liveHosts()) do -- (5 Nov) both Clauses
		h.slowUntil = os.clock() + Config.HARMONY.encore
		h.slowMult = Config.HARMONY.slow
		Effects.stars(h.model, Config.HARMONY.encore, Color3.fromRGB(190, 140, 255)) -- (4 Nov) notes while he's slow
	end
	-- 5 Nov (Brent): and every friend gets a stamina lift
	for _, p in ipairs(Players:GetPlayers()) do
		if hrpOf(p) and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") then
			Boost:FireClient(p, "plus", Config.HARMONY.encoreStamina)
		end
	end
	say("info", "\u{1F3B6} Encore! " .. plr.DisplayName .. "'s song fills the whole floor - the host is slow for " .. Config.HARMONY.encore .. " s, and everyone gets +" .. Config.HARMONY.encoreStamina .. "% stamina!")
end)

UseSkill.OnServerEvent:Connect(function(plr, pos)
	runSkill(plr, plr:GetAttribute("Skill"), pos)
end)
-- Clone's copied skill buttons (4 Nov): slot 1 or 2 (two with Copy Two)
UseCopy.OnServerEvent:Connect(function(plr, slot, pos)
	if plr:GetAttribute("Skill") ~= "clone" or (slot ~= 1 and slot ~= 2) then
		return
	end
	local copied = plr:GetAttribute("Copy" .. slot)
	if typeof(copied) == "string" and copied ~= "clone" and Config.COOLDOWN[copied] then
		runSkill(plr, copied, pos, slot)
	end
end)

AskClue.OnServerEvent:Connect(function(plr)
	if state.status ~= "playing" or state.cluesLeft <= 0 then
		return
	end
	-- a bonus clue (a present, the Extra Clue boost, a ladder upgrade) is free
	if (state.freeClues or 0) > 0 then
		state.freeClues -= 1
		RoundState:SetAttribute("FreeClues", state.freeClues)
		state.cluesLeft -= 1
		RoundState:SetAttribute("CluesLeft", state.cluesLeft)
		return giveClue("\u{1F381} Free clue: ")
	end
	-- a clue costs points earned in this game: 10, then 20, then 30 (Brainy half)
	local used = state.cluesUsed or 0
	local cost = Config.CLUE_COSTS[math.min(used + 1, #Config.CLUE_COSTS)]
	if plr:GetAttribute("Skill") == "brainy" then
		cost = math.ceil(cost / 2)
	end
	local have = (state.earned and state.earned[plr.UserId]) or 0
	if have < cost then
		return say("info", "A clue costs " .. cost .. " points from this game - you have " .. have .. ". Pop balloons, open presents and search to earn some!", nil, plr)
	end
	addPoints(plr, -cost)
	state.cluesUsed = used + 1
	RoundState:SetAttribute("ClueCost", Config.CLUE_COSTS[math.min(state.cluesUsed + 1, #Config.CLUE_COSTS)])
	state.cluesLeft -= 1
	RoundState:SetAttribute("CluesLeft", state.cluesLeft)
	giveClue("")
end)

local said = {}
Say.OnServerEvent:Connect(function(plr, idx)
	if typeof(idx) ~= "number" or idx % 1 ~= 0 or idx < 1 or idx > #Config.PHRASES then
		return
	end
	local now = os.clock()
	local list = said[plr.UserId] or {}
	local keep = {}
	for _, t in ipairs(list) do
		if now - t < 10 then
			table.insert(keep, t)
		end
	end
	if #keep >= 3 then
		return say("info", "Too many messages - wait a moment.", nil, plr)
	end
	table.insert(keep, now)
	said[plr.UserId] = keep
	-- some phrases also pin where you stand (the team sees it through walls)
	local h = Config.PING_PHRASES[Config.PHRASES[idx]] and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	Bubble:FireAllClients(plr, idx, h and not plr:GetAttribute("Escaped") and h.Position or nil)
end)

Unhide.OnServerEvent:Connect(unhide)

UseCandy.OnServerEvent:Connect(function(plr)
	local n = plr:GetAttribute("CandyCharges") or 0
	if n <= 0 or state.status ~= "playing" then
		return
	end
	plr:SetAttribute("CandyCharges", n - 1)
	Boost:FireClient(plr, "candy")
	Effects.at(plr, "boost", "eat")
	say("boost", plr.DisplayName .. " ate Candy Corn - running without getting puffed!", { icon = Config.ITEM_ICONS.candy, userId = plr.UserId, item = "Candy Corn" })
end)

UseBoost.OnServerEvent:Connect(function(plr, id)
	local bag = bags[plr.UserId]
	local i = bag and typeof(id) == "string" and table.find(bag, id)
	if not i or state.status ~= "playing" or plr:GetAttribute("Escaped") then
		return
	end
	-- the Gift Box Hideout needs you out in the open (not hiding, caged or in a vent)
	if id == "giftbox" and (plr:GetAttribute("Hidden") or plr:GetAttribute("Caged") or plr:GetAttribute("Crawling")) then
		return say("info", "\u{1F381} You can only hide in a gift box out in the open.", nil, plr)
	end
	local boost = Progress.BOOSTS[id]
	table.remove(bag, i)
	paintBag(plr)
	applyBoost(plr, id)
	Effects.at(plr, "boost", id == "candy" and "eat" or (id == "energy" or id == "thermos") and "energy" or nil)
	-- 3 Nov (Brent): the season's look of it while its shop is open (Apple Cider)
	local look = Seasons.look(id)
	local shown = look and look.name or boost.name
	-- 3 Nov (Brent): what it did, in the same line
	local did = ({ energy = " +100% stamina!", thermos = " +100% stamina for everyone nearby!", giftbox = " Hidden for " .. Config.GIFTBOX.seconds .. " s!",
		candy = " No tiring for 20 s!", freeze = " The host is frozen for 10 s!", clue = " +1 clue for the team!" })[id] or ""
	say("boost", plr.DisplayName .. " used " .. shown .. "!" .. did, { icon = look and look.icon or boost.icon, userId = plr.UserId, item = shown })
end)

-- the party leader leaving hands the lead to someone still here
Players.PlayerRemoving:Connect(function(plr)
	if RoundState:GetAttribute("Leader") == plr.UserId then
		local nextOne
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= plr then
				nextOne = nextOne or p
			end
		end
		RoundState:SetAttribute("Leader", nextOne and nextOne.UserId or nil)
	end
end)

local function isLeader(plr)
	local lead = RoundState:GetAttribute("Leader")
	return lead == nil or lead == plr.UserId
end

SetDifficulty.OnServerEvent:Connect(function(plr, key)
	if not isLeader(plr) then
		return say("info", "Only the party leader can change the difficulty.", nil, plr)
	end
	if typeof(key) == "string" and Config.DIFFICULTY[key] and not (host and host.model) then
		-- 5 Nov: set once the escape timer runs (the floor is made for it)
		if state.status == "playing" and state.endsAt and state.endsAt ~= math.huge then
			return say("info", "The difficulty is set once the game starts - pick it in the Lobby or before everyone has chosen.", nil, plr)
		end
		RoundState:SetAttribute("Difficulty", key)
		say("info", "Difficulty: " .. Config.DIFFICULTY[key].name)
	end
end)

-- 5 Nov (Brent: some Hard / Nightmare games had a 3-color code): the floor is
-- made for the difficulty when the round starts, but it can still change
-- while characters are chosen (the leader's picker, or a player arriving with
-- the Lobby's choice). Until the timer starts the round follows it: the code
-- gets its 4th color (an unpopped trick balloon becomes balloon 4) or loses
-- it, the clues change by the difference, and the timer and host use the new
-- difficulty when they start. After that it stays as it was.
RoundState:GetAttributeChangedSignal("Difficulty"):Connect(function()
	local key = RoundState:GetAttribute("Difficulty") or "normal"
	local new, old = Config.DIFFICULTY[key], Config.DIFFICULTY[state.diff or ""]
	if not new or not old or key == state.diff or state.status ~= "playing" or not world or not state.code then
		return
	end
	if (state.endsAt and state.endsAt ~= math.huge) or (host and host.model) or (state.towerFloor or 1) > 1 then
		RoundState:SetAttribute("Difficulty", state.diff) -- too late: back to this game's
		return
	end
	state.diff = key
	-- clues: the new difficulty's count, less any already used
	state.cluesLeft = math.max(0, state.cluesLeft + (new.clues or 0) - (old.clues or 0))
	RoundState:SetAttribute("CluesLeft", state.cluesLeft)
	-- the code's length
	local want, have = new.code or 3, #state.code
	if want ~= have then
		local balloons = {}
		for _, e in pairs(world.objects) do
			if e.def.kind == "balloon" then
				table.insert(balloons, e)
			end
		end
		local function relabel(e)
			if e.label and not e.popped then
				e.label.Text = tostring(e.def.n)
			end
			if e.prompt then
				e.prompt.ObjectText = "Balloon " .. e.def.n
			end
		end
		if want > have then
			for i = have + 1, want do
				state.code[i] = Config.COLORS[math.random(1, #Config.COLORS)]
				local tricks = {}
				for _, e in ipairs(balloons) do
					if e.def.decoy and not e.popped then
						table.insert(tricks, e)
					end
				end
				if #tricks > 0 then
					local e = tricks[math.random(1, #tricks)]
					e.def.decoy = nil
					e.def.n = i
					relabel(e)
				end
			end
		else
			for i = have, want + 1, -1 do
				state.code[i] = nil
				state.known[i] = nil
				RoundState:SetAttribute("Known" .. i, nil)
				for _, e in ipairs(balloons) do
					if not e.def.decoy and e.def.n == i then
						e.def.decoy = true
						e.def.n = math.random(1, want)
						relabel(e)
					end
				end
			end
		end
		RoundState:SetAttribute("CodeLen", want)
		RoundState:SetAttribute("MapJson", HttpService:JSONEncode(MapGen.forClient(HouseMap)))
	end
	if RunService:IsStudio() then
		print("[Difficulty] " .. new.name .. " before the timer: the code has " .. #state.code .. " colors, " .. state.cluesLeft .. " clues")
	end
end)

SetSpook.OnServerEvent:Connect(function(plr, level)
	if not isLeader(plr) then
		return say("info", "Only the party leader can choose Giggly or Spooky.", nil, plr)
	end
	if (level == "giggly" or level == "spooky") and not (host and host.model) then
		RoundState:SetAttribute("Spook", level)
		applyLook(HouseMap.theme, level == "spooky")
		say("info", "This game is " .. (level == "spooky" and "SPOOKY" or "Giggly") .. ".")
	end
end)

-- ---------- starting a round ----------
function round.start()
	if hostTimer then
		task.cancel(hostTimer)
		hostTimer = nil
	end
	if host then
		host:remove()
	end
	if host2 then
		host2:remove()
		host2 = nil
	end
	state.partnerKind = nil
	-- the floor this server plays (the Lobby's choice; Config.STUDIO_MAP in Studio)
	local mapIdx = Progress.mapIndex(RoundState:GetAttribute("Map") or "partyhouse")
	local mapInfo = mapIdx and Progress.MAPS[mapIdx]
	local floors = Plans[mapInfo and mapInfo.building or "partyhouse"] or Plans.partyhouse
	do
		local d = Config.DIFFICULTY[RoundState:GetAttribute("Difficulty") or "normal"] or Config.DIFFICULTY.normal
		HouseMap = MapGen.make(floors[mapInfo and mapInfo.floor or 1] or Plans.partyhouse[1], nil, { decoys = d.decoys, search = d.search, code = d.code or 3 })
	end
	-- one of the locked doors is a blocked passage instead: Muscle shoves the
	-- junk away, or anyone plants the Confetti Cannon hidden in a search spot
	local lockDefs = {}
	for _, o in ipairs(HouseMap.objects) do
		if o.kind == "lock" and not o.bonus then
			table.insert(lockDefs, o)
		end
	end
	if #lockDefs > 0 then
		lockDefs[math.random(1, #lockDefs)].blocked = true
	end
	RoundState:SetAttribute("MapJson", HttpService:JSONEncode(MapGen.forClient(HouseMap)))
	-- a floor with a floor above gets stairs and a door up, named for it
	do
		local nf = nextFloor()
		HouseMap.hasNext = nf ~= nil
		HouseMap.upText = nf and ("Up to the " .. (string.match(nf.name, ":%s*(.+)$") or nf.name)) or nil
	end
	world = House.build(HouseMap)
	world.onNoise = function(pos)
		if host and host.model then
			alertHosts(pos)
		end
	end
	Props.place(world)
	wirePrompts()
	wireStoreRooms()
	House.placeCrates(world, Config.BARRICADE.crates)
	-- every room dressed to look like what it is called (game/server/Rooms.luau)
	local okDress, dressErr = pcall(function()
		require(script.Parent.Rooms).dress(world)
	end)
	if not okDress then
		warn("Room dressing failed (the game goes on without it): " .. tostring(dressErr))
	end
	-- light switches: a dark room hides you (the host sees less far there)
	world.dark = {}
	local function paintDark()
		local names = {}
		for n in pairs(world.dark) do
			table.insert(names, n)
		end
		RoundState:SetAttribute("DarkRooms", table.concat(names, ","))
	end
	paintDark()
	world.setDark = function(room, dark)
		local light = world.roomLights and world.roomLights[room]
		if light then
			light.Enabled = not dark
		end
		world.dark[room] = dark or nil
		local sw = world.switches and world.switches[room]
		if sw then
			sw.ActionText = dark and "Lights on" or "Lights off"
		end
		paintDark()
	end
	-- the Aquarium's Deep Sea: the kelp forest, the anglerfish den and the
	-- coral cave start dark (Glow's light, or the light switch, helps)
	if HouseMap.theme == "aquarium" then
		for _, f in ipairs(HouseMap.floors) do
			local n = string.lower(f.name)
			if string.find(n, "kelp", 1, true) or string.find(n, "anglerfish den", 1, true) or string.find(n, "coral cave", 1, true) then
				world.setDark(f.name, true)
			end
		end
	end
	world.onSwitch = function(plr, room)
		if state.status ~= "playing" or not room then
			return
		end
		local nowDark = not world.dark[room]
		world.setDark(room, nowDark)
		Effects.sound(hrpOf(plr) and hrpOf(plr).Position or Vector3.zero, "beep", 0.7)
		say("info", nowDark and ("Lights off in the " .. room .. " - the host can't see as far in here.") or ("Lights on in the " .. room .. "."), nil, plr)
	end
	-- a TV, radio, drums or arcade machine switched on: the host comes to look
	world.onLure = function(plr, pos, label)
		if state.status ~= "playing" then
			return
		end
		if host and host.model then
			alertHosts(pos)
		end
		say("info", plr.DisplayName .. " switched on the " .. label .. " - the host is coming to look!")
	end
	-- the Jelly Vault's vault door: the wheel creaks (the host hears it), then
	-- the treasure inside is points for everyone and a free clue for the team
	world.onVaultTurn = function(plr, pos)
		if state.status ~= "playing" then
			return false
		end
		if host and host.model then
			alertHosts(pos)
		end
		say("info", "CREEEAK! " .. plr.DisplayName .. " turned the vault wheel - the vault is open! (The host heard that...)")
		return true
	end
	world.onVaultTreasure = function(plr, pos)
		if state.status ~= "playing" then
			return false
		end
		Effects.surprise(pos, "confetti")
		Effects.burst(pos, "boost")
		for _, p in ipairs(playersInRound()) do
			local n = math.random(Config.VAULT.points[1], Config.VAULT.points[2])
			addPoints(p, n, true)
			say("boost", "\u{1F4B0} Vault treasure: +" .. n .. " points for you!", { icon = "\u{1F4B0}", userId = p.UserId, item = "+" .. n .. " points" }, p)
		end
		state.cluesLeft += 1
		state.freeClues = (state.freeClues or 0) + 1
		RoundState:SetAttribute("CluesLeft", state.cluesLeft)
		RoundState:SetAttribute("FreeClues", state.freeClues)
		quest(plr, "present")
		say("info", plr.DisplayName .. " found the vault treasure - points for everyone and a free clue!")
		return true
	end
	-- the laundry chute: a one-way slide to a far room (the host can't follow)
	if world.chute then
		local chute = world.chute
		local used = {}
		chute.prompt.Triggered:Connect(function(plr)
			if state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") or plr:GetAttribute("Hidden") or plr:GetAttribute("Crawling") then
				return
			end
			if (used[plr.UserId] or 0) > os.clock() then
				return say("info", "The chute needs a moment - try again in a few seconds.", nil, plr)
			end
			used[plr.UserId] = os.clock() + Config.CHUTE.seconds + Config.CHUTE.reuse
			local crawlId = (plr:GetAttribute("CrawlId") or 0) + 1
			plr:SetAttribute("CrawlId", crawlId)
			plr:SetAttribute("Crawling", true)
			local h = hrpOf(plr)
			if h then
				h.Anchored = true
			end
			setVisible(plr, false)
			Effects.sound(chute.from, "throw", 1)
			say("info", chute.goText or "Wheee! Down the laundry chute...", nil, plr)
			task.delay(Config.CHUTE.seconds, function()
				if plr:GetAttribute("CrawlId") ~= crawlId or plr:GetAttribute("Caged") then
					return -- caught on the way: the cage has them now
				end
				teleport(plr, chute.to)
				local h2 = hrpOf(plr)
				if h2 then
					h2.Anchored = false
				end
				setVisible(plr, true)
				plr:SetAttribute("Crawling", false)
				Effects.sound(chute.to, "bounce", 1)
				Effects.burst(chute.to + Vector3.new(0, 2, 0), "pop", false)
				say("info", chute.landText or ("You landed in the laundry basket in the " .. chute.toRoom .. "!"), nil, plr)
			end)
		end)
	end
	local upDoor = world.root:FindFirstChild("NextFloorDoor")
	if upDoor then
		local told = {}
		upDoor.Touched:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if not plr then
				return
			end
			if voting and state.status == "won" and nextFloor() then
				if votes[plr.UserId] ~= "next" then
					votes[plr.UserId] = "next"
					say("vote", plr.DisplayName .. " stepped through - up to the next floor!")
				end
			elseif not told[plr.UserId] or os.clock() - told[plr.UserId] > 6 then
				told[plr.UserId] = os.clock()
				say("info", nextFloor() and "Wait here for your crew! When the game ends, step through to go up together." or "This is the top floor - you made it!", nil, plr)
			end
		end)
	end
	-- the Barricade prompt on a crate works like Muscle's button
	world.onCrate = function(plr, c)
		if state.status ~= "playing" or plr:GetAttribute("Skill") ~= "muscle" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") or c.busy then
			return
		end
		local now = workspace:GetServerTimeNow()
		if (plr:GetAttribute("CoolUntil") or 0) > now then
			return say("info", "Barricade is recharging... " .. math.ceil(plr:GetAttribute("CoolUntil") - now) .. " seconds", nil, plr)
		end
		barricade(plr, c)
		plr:SetAttribute("CoolUntil", now + Config.COOLDOWN.muscle * (plr:GetAttribute("CooldownMult") or 1))
		quest(plr, "skill")
	end
	-- each locked door hides its key (the blocked passage: a Confetti Cannon) in a
	-- random searchable thing on its near side
	world.unlocked, world.keys, world.keyIn = {}, {}, {}
	world.poppers = 0
	RoundState:SetAttribute("Poppers", 0)
	for _, lock in ipairs({ { "L1", 1 }, { "L2", 2 }, { "B1", 1 }, { "B2", 1 } }) do
		local choices = {}
		for oid, e in pairs(world.objects) do
			if e.def.kind == "search" and e.def.zone == lock[2] and not world.keyIn[oid] then
				table.insert(choices, oid)
			end
		end
		if #choices > 0 and world.objects[lock[1]] then
			world.keyIn[choices[math.random(1, #choices)]] = lock[1]
		end
		RoundState:SetAttribute("Lock_" .. lock[1], false)
		RoundState:SetAttribute("Key_" .. lock[1], false)
	end
	-- Nutmeg's Good Nose (3 Nov): twice a second, each Nutmeg's screen gets the
	-- drawers and boxes within her NoseRange that still hold a key or a
	-- Confetti Cannon (NoseSpots: "x,y,z;x,y,z") - it sparkles them through walls
	do
		local myWorld = world
		task.spawn(function()
			while world == myWorld do
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr:GetAttribute("Skill") == "nutmeg" then
						local h = hrpOf(plr)
						local found = {}
						if h and state.status == "playing" and not plr:GetAttribute("Caged") and not plr:GetAttribute("Escaped") then
							local reach = plr:GetAttribute("NoseRange") or Config.NUTMEG.nose
							for sid, lock in pairs(world.keyIn or {}) do
								local e = world.objects[sid]
								if e and e.def and not e.searched and not world.unlocked[lock] and not world.keys[lock] then
									local p = (e.part and e.part.Position) or at(e.def.x, e.def.y, 2)
									if (p - h.Position).Magnitude <= reach then
										table.insert(found, string.format("%.1f,%.1f,%.1f", p.X, p.Y, p.Z))
									end
								end
							end
						end
						local text = table.concat(found, ";")
						if plr:GetAttribute("NoseSpots") ~= text then
							plr:SetAttribute("NoseSpots", text)
						end
					elseif plr:GetAttribute("NoseSpots") then
						plr:SetAttribute("NoseSpots", nil)
					end
				end
				task.wait(0.5)
			end
		end)
	end
	-- this floor's items (Candy Corn, a Party Shield and one more) each hide in
	-- a random present or search spot of any look - never one holding a key
	world.lootIn = {}
	do
		local spots = {}
		for oid, e in pairs(world.objects) do
			if e.def and (e.def.kind == "present" or (e.def.kind == "search" and not world.keyIn[oid])) then
				table.insert(spots, oid)
			end
		end
		table.sort(spots) -- (pairs order is not random: shuffle from a sorted list)
		local items = table.clone(Config.LOOT.always)
		table.insert(items, Config.LOOT.extra[math.random(1, #Config.LOOT.extra)])
		for _, item in ipairs(items) do
			if #spots == 0 then
				break
			end
			world.lootIn[table.remove(spots, math.random(1, #spots))] = item
		end
	end
	local code = {}
	-- 4 Nov: 4 colors on Hard and Nightmare (Config.DIFFICULTY code), else 3
	local codeLen = (Config.DIFFICULTY[RoundState:GetAttribute("Difficulty") or "normal"] or {}).code or 3
	for i = 1, codeLen do
		code[i] = Config.COLORS[math.random(1, #Config.COLORS)]
	end
	RoundState:SetAttribute("CodeLen", codeLen)
	local diffKey = RoundState:GetAttribute("Difficulty") or "normal"
	local diff = Config.DIFFICULTY[diffKey]
	local now = workspace:GetServerTimeNow()
	state = { status = "playing", code = code, known = {}, entry = {}, doorOpen = false, everCaught = {}, cluesLeft = diff.clues,
		diff = diffKey, earned = {}, startedAt = now, endsAt = now + diff.timer, frenzy = false }
	-- Tower Run: the next floor of the climb keeps the points, the clock and the host
	local carry = towerCarry
	if not carry then
		-- a new game (not the next floor of a Tower Run): Nutmeg's Jingle Bells is back
		for _, p in ipairs(Players:GetPlayers()) do
			p:SetAttribute("BellsUsed", false)
			p:SetAttribute("HedgeUsed", false) -- Holly's Holly Hedge too
			p:SetAttribute("PocketsGiven", false) -- and Holly's Peppermint Pockets
			p:SetAttribute("EncoreUsed", false) -- and Harmony's Encore
			p:SetAttribute("ToyPowerUsed", false) -- and Elfy's Toy Parade / Workshop Rush
			p:SetAttribute("JailbreakUsed", false) -- and Patch's Jailbreak (5 Nov)
		end
	end
	towerCarry = nil
	if RoundState:GetAttribute("Tower") then
		state.towerFloor = carry and carry.floor or 1
		RoundState:SetAttribute("TowerFloor", state.towerFloor)
		if carry then
			state.earned = carry.earned
			state.everCaught = carry.everCaught or {}
		end
	end
	-- clear the last game's clock and host first, so screens see a fresh
	-- game (not one already under way) and open the character picker
	RoundState:SetAttribute("EndsAt", nil)
	RoundState:SetAttribute("HostOut", false)
	RoundState:SetAttribute("Status", "playing")
	RoundState:SetAttribute("ClueCost", Config.CLUE_COSTS[1])
	if carry then
		-- climbing on: the clock keeps running, so nobody picks a character again
		RoundState:SetAttribute("EndsAt", carry.endsAt)
	end
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("GameEarned", state.earned[p.UserId] or 0)
	end
	RoundState:SetAttribute("DoorOpen", false)
	RoundState:SetAttribute("CluesLeft", diff.clues)
	RoundState:SetAttribute("Frenzy", false)
	RoundState:SetAttribute("HostOut", false)
	for i = 1, 4 do
		RoundState:SetAttribute("Known" .. i, nil)
	end
	local spook = RoundState:GetAttribute("Spook")
	for _, l in ipairs(world.lights) do
		l.Brightness = spook == "spooky" and 0.45 or 1.2
	end
	applyLook(HouseMap.theme, spook == "spooky")
	local extraGrace = 0
	for i, plr in ipairs(Players:GetPlayers()) do
		plr:SetAttribute("Waiting", false)
		plr:SetAttribute("Escaped", false)
		plr:SetAttribute("Caged", false)
		plr:SetAttribute("Hidden", false)
		plr:SetAttribute("Shield", false)
		plr:SetAttribute("ExtraShields", 0)
		plr:SetAttribute("Energy", 100)
		local hrp = hrpOf(plr)
		if hrp then
			hrp.Anchored = false
		end
		setVisible(plr, true)
		setSpeed(plr, Config.WALK)
		-- boosts brought from the Lobby shop, used up in this game
		local pd = Profile.get(plr)
		local on = {}
		bags[plr.UserId] = bags[plr.UserId] or {}
		if pd and pd.loadout and #pd.loadout > 0 then
			for _, id in ipairs(pd.loadout) do
				if id == "shield" then
					if plr:GetAttribute("Shield") then
						-- a second Party Shield: saves you a second time
						plr:SetAttribute("ExtraShields", (plr:GetAttribute("ExtraShields") or 0) + 1)
					end
					plr:SetAttribute("Shield", true)
					plr:SetAttribute("SelfShieldAt", nil)
					plr:SetAttribute("ShieldBoost", true)
					table.insert(on, id)
				elseif id == "headstart" then
					extraGrace += 10 -- two Head Starts: 20 seconds
					table.insert(on, id)
				elseif Progress.BOOSTS[id] then
					table.insert(bags[plr.UserId], id)
				end
			end
			pd.loadout = {}
			Profile.publish(plr)
			task.spawn(Profile.save, plr)
		end
		plr:SetAttribute("BoostsOn", table.concat(on, ","))
		paintBag(plr)
		local s = HouseMap.start[((i - 1) % #HouseMap.start) + 1]
		teleport(plr, at(s[1], s[2], 0))
	end
	state.freeClues = 0
	RoundState:SetAttribute("FreeClues", 0)
	host = Host.new(world, round)
	-- tonight's host: half the time the building's own, otherwise another
	local mapI = Progress.mapIndex(RoundState:GetAttribute("Map") or "partyhouse")
	local own = Config.BUILDING_HOST[mapI and Progress.MAPS[mapI].building or "partyhouse"] or "pumpkin"
	local kind = own
	-- a season floor (the Harvest Barn) always has its own host (the Gobbler)
	if math.random() >= 0.5 and not (mapI and Progress.MAPS[mapI].season) then
		local others = {}
		for k, h in pairs(Config.HOSTS) do
			if k ~= own and not h.hidden then
				table.insert(others, k)
			end
		end
		kind = others[math.random(1, #others)]
	end
	if RunService:IsStudio() and Config.STUDIO_HOST and Config.HOSTS[Config.STUDIO_HOST] then
		kind = Config.STUDIO_HOST
	end
	if carry and carry.hostKind then
		kind = carry.hostKind -- the same host follows you up
	end
	-- (5 Nov) a building whose floors have their own hosts (Claus Manor): a
	-- list is two at once - the second runs alongside the first
	do
		local fh = mapI and Config.FLOOR_HOSTS and Config.FLOOR_HOSTS[Progress.MAPS[mapI].building]
		local e = fh and fh[Progress.MAPS[mapI].floor]
		if type(e) == "table" then
			kind = e[1]
			state.partnerKind = e[2]
		elseif type(e) == "string" then
			kind = e
		end
		if RunService:IsStudio() and Config.STUDIO_HOST and Config.HOSTS[Config.STUDIO_HOST] then
			kind = Config.STUDIO_HOST
		end
	end
	host.kind = kind
	RoundState:SetAttribute("HostKind", kind)
	state.extraTaken = {}
	if Config.HOSTS[kind] and Config.HOSTS[kind].skill == "jackbox" then
		round.placeJackBoxes()
	end
	round.placeCandyCorn()
	round.placeCloudSpots() -- Cloud's high shelves (4 Nov)
	round.placeMusicBox() -- Harmony's music box (4 Nov)
	round.placeTurkeys()
	round.placePresents() -- Claus Manor (5 Nov)
	round.placePlushie()
	RoundState:SetAttribute("Blackout", "")
	RoundState:SetAttribute("DarkRooms", "")
	RoundState:SetAttribute("KeyRooms", "")
	local grace = carry and Config.TOWER.grace or (diff.grace + extraGrace)
	-- nothing starts until everyone has chosen a character (or PICK_WAIT runs out)
	state.endsAt = math.huge
	if not carry then
		RoundState:SetAttribute("EndsAt", nil)
	end
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("Ready", carry and p:GetAttribute("Skill") and true or nil)
	end
	local deadline = workspace:GetServerTimeNow() + (carry and 0 or Config.PICK_WAIT)
	RoundState:SetAttribute("PickDeadline", deadline)
	hostTimer = task.spawn(function()
		firstArrival = firstArrival or os.clock()
		while state.status == "playing" do
			local waiting = 0
			for _, p in ipairs(Players:GetPlayers()) do
				if not (p:GetAttribute("Skill") and p:GetAttribute("Ready")) and not p:GetAttribute("Waiting") then
					waiting += 1
				end
			end
			-- party members still on their way here (the first game only, at most ARRIVE_WAIT)
			if not carry and os.clock() - firstArrival < Config.ARRIVE_WAIT then
				for uid in pairs(expectedPlayers) do
					if not Players:GetPlayerByUserId(uid) then
						waiting += 1
					end
				end
			end
			RoundState:SetAttribute("WaitingToPick", waiting)
			if waiting == 0 or workspace:GetServerTimeNow() >= deadline then
				break
			end
			task.wait(0.5)
		end
		if state.status ~= "playing" then
			return
		end
		-- still undecided after the wait: a random character each
		for _, p in ipairs(Players:GetPlayers()) do
			if not p:GetAttribute("Skill") then
				-- (only characters they may play)
				local mine = {}
				for _, sk in ipairs(Config.SKILLS) do
					if Unlocks.owns(p, sk.id) then
						table.insert(mine, sk)
					end
				end
				local s = mine[math.random(1, #mine)]
				pickFor(p, s)
				say("info", "Time's up for choosing - you're " .. s.name .. " this game!", nil, p)
			end
		end
		RoundState:SetAttribute("WaitingToPick", 0)
		RoundState:SetAttribute("PickDeadline", nil)
		table.clear(expectedPlayers)
		-- everyone has their character now: its ladder upgrades count from here
		-- (free clues - never paid for with points - a code colour, stamina, a Shield)
		local bonusClues, reveals = 0, 0
		local team = {} -- Brainy's upgrades work for the whole team
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("Skill") and not p:GetAttribute("Waiting") then
				local mods = applyMods(p)
				for _, k in ipairs({ "trickSight", "twoStep", "keyMap", "longRead", "mastermind" }) do
					if mods[k] then
						team[k] = true
					end
				end
				p:SetAttribute("Energy", 100 + (mods.energyStart or 0))
				p:SetAttribute("Shield", mods.shield == true or p:GetAttribute("ShieldBoost") == true)
				bonusClues += mods.clues or 0
				if mods.revealOne then
					reveals += 1
				end
			end
			p:SetAttribute("ShieldBoost", nil)
		end
		state.twoStep = team.twoStep == true
		if team.mastermind then
			-- the first clue is free and gives the whole route
			state.mastermind = true
			bonusClues += 1
		end
		if team.trickSight then
			-- Trick Spotter: the trick balloons look grey and droopy to everyone
			for _, e in pairs(world.objects) do
				if e.def.kind == "balloon" and e.def.decoy and not e.popped and e.part then
					e.part.Color = Color3.fromRGB(140, 140, 150)
					e.part.Transparency = 0.35
					e.part.Size = Vector3.new(2, 2.3, 2)
					e.part.Position -= Vector3.new(0, 1.4, 0)
					if e.label then
						e.label.TextTransparency = 0.6
					end
				end
			end
			say("info", "\u{1F9E0} Brainy spotted the trick balloons - they look gray and droopy. Pop the bright ones!")
		end
		if team.longRead and world.objects.invite and world.objects.invite.prompt then
			-- Long Read: the invitation can be read from twice as far
			world.objects.invite.prompt.MaxActivationDistance = 20
		end
		if team.keyMap then
			-- Key Finder: the rooms hiding a key (or a Confetti Cannon) show a key on the map
			local myWorld = world
			task.spawn(function()
				while world == myWorld and state.status == "playing" do
					local rooms, seen = {}, {}
					for sid, lock in pairs(world.keyIn) do
						local e = world.objects[sid]
						if e and not e.searched and not world.unlocked[lock] and not world.keys[lock] then
							local r = roomOf(sid)
							if not seen[r] then
								seen[r] = true
								table.insert(rooms, r)
							end
						end
					end
					RoundState:SetAttribute("KeyRooms", table.concat(rooms, ","))
					task.wait(2)
				end
			end)
		end
		if bonusClues > 0 then
			state.freeClues = (state.freeClues or 0) + bonusClues
			state.cluesLeft += bonusClues
			RoundState:SetAttribute("FreeClues", state.freeClues)
			RoundState:SetAttribute("CluesLeft", state.cluesLeft)
		end
		-- "one code colour" upgrades: one colour a game, however many players have
		-- one, and none on Nightmare (Config.CODE_COLOUR_ON_NIGHTMARE)
		if state.diff == "nightmare" and not Config.CODE_COLOUR_ON_NIGHTMARE then
			reveals = 0
		end
		for _ = 1, math.min(reveals, 1) do
			local unknown = {}
			for k = 1, #state.code do
				if not state.known[k] then
					table.insert(unknown, k)
				end
			end
			if #unknown > 1 then
				local k = unknown[math.random(1, #unknown)]
				state.known[k] = state.code[k]
				RoundState:SetAttribute("Known" .. k, state.code[k])
			end
		end
		if reveals > 0 or bonusClues > 0 then
			say("info", (reveals > 0 and "Your upgrades showed a color of the code! " or "") .. (bonusClues > 0 and ("+" .. bonusClues .. " free " .. (bonusClues == 1 and "clue" or "clues") .. " from your upgrades.") or ""))
		end
		-- the escape timer starts now (the characters are chosen: the party's
		-- level sets Hard / Nightmare's timer and host - diffFor)
		local t0 = workspace:GetServerTimeNow()
		local partyDiff = diffFor(state.diff)
		state.hostDiff = partyDiff
		state.startedAt = t0
		state.endsAt = t0 + partyDiff.timer
		if carry then
			-- climbing on: the same clock
			state.endsAt = carry.endsAt
			state.towerStarted = carry.startedAt
		elseif RoundState:GetAttribute("Tower") then
			-- a Tower Run: one clock for the whole climb
			state.endsAt = t0 + partyDiff.timer * Config.TOWER.timeMult
			state.towerStarted = t0
		end
		RoundState:SetAttribute("EndsAt", state.endsAt)
		say("start", (RoundState:GetAttribute("Tower") and ("\u{1F5FC} Tower Run, floor " .. (state.towerFloor or 1) .. ": ") or "") .. "Find the way out of " .. (HouseMap.name or "the Party House") .. ". Don't get caught!", { grace = grace })
		task.wait(grace)
		hostTimer = nil
		if state.status == "playing" then
			host:spawn(state.hostDiff or diffFor(state.diff))
			RoundState:SetAttribute("HostOut", true)
			local partner = state.partnerKind and Config.HOSTS[state.partnerKind]
			say("appear", "Ding dong! Who came to my party? (Tonight's host" .. (partner and "s: " or ": ") .. Config.HOSTS[host.kind or "pumpkin"].name
				.. (partner and (" and " .. partner.name) or "") .. ")")
			-- (5 Nov) the second Claus follows a few seconds later
			if partner then
				local myState = state
				task.delay(4, function()
					if state ~= myState or state.status ~= "playing" then
						return
					end
					host2 = Host.new(world, round)
					host2.kind = state.partnerKind
					host2:spawn(state.hostDiff or diffFor(state.diff))
					if host2.model then
						host2.model.Name = "PartyHost2" -- the client's close-ups follow the first
					end
				end)
			end
		end
	end)
end

-- Patch's aura: friends near her get half their stamina back, once every
-- 10 seconds each
local auraAt = {}
task.spawn(function()
	while true do
		task.wait(1)
		if state.status == "playing" then
			for _, patch in ipairs(Players:GetPlayers()) do
				local ph = hrpOf(patch)
				if ph and patch:GetAttribute("Skill") == "patch" and not patch:GetAttribute("Caged") and not patch:GetAttribute("Escaped") and not patch:GetAttribute("Hidden") then
					for _, p in ipairs(Players:GetPlayers()) do
						local h = hrpOf(p)
						if p ~= patch and h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") and (h.Position - ph.Position).Magnitude < 14 and (auraAt[p] or 0) < os.clock() then
							auraAt[p] = os.clock() + 10
							Boost:FireClient(p, "half")
							Effects.at(p, "heal")
							say("info", "Patch gave you a breather: +50% stamina", nil, p)
						end
					end
				end
			end
		end
	end
end)

-- the host thinks five times a second
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.2 then
		return
	end
	local step = acc
	acc = 0
	if state.status ~= "playing" or not world then
		return
	end
	if host and host.model then
		host:step(step)
	end
	if host2 and host2.model then
		steppingHost = host2
		local ok, err = pcall(host2.step, host2, step)
		steppingHost = nil
		if not ok then
			warn("[host2] " .. tostring(err))
		end
	end
	local _W, Hh = HouseMap.w * T, HouseMap.h * T
	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = hrpOf(plr)
		if hrp then
			local pos = hrp.Position
			if plr:GetAttribute("Caged") and not plr:GetAttribute("Escaped") and world.objects.cage
				and (pos - world.objects.cage.inside).Magnitude > 7 then
				intoCage(plr)
			elseif pos.Y < -20 then
				-- fell off the world: back to safety
				teleport(plr, plr:GetAttribute("Escaped") and world.gardenSpot or at(HouseMap.start[1][1], HouseMap.start[1][2], 0))
			elseif not plr:GetAttribute("Escaped") and not plr:GetAttribute("Caged") and not plr:GetAttribute("Waiting") then
				if state.doorOpen and pos.Z < -1 then
					escape(plr, false)
				end
			end
		end
	end
	if not state.frenzy and workspace:GetServerTimeNow() >= state.endsAt then
		state.frenzy = true
		RoundState:SetAttribute("Frenzy", true)
		for _, l in ipairs(world.lights) do
			l.Brightness = 0.15
			l.Color = Color3.fromRGB(255, 60, 40)
		end
		-- every other light in the building too: lamps, tanks, bulbs, windows
		for _, d in ipairs(world.root:GetDescendants()) do
			if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
				d.Color = Color3.fromRGB(255, 60, 40)
				d.Brightness = math.min(d.Brightness, 0.3)
			end
		end
		if host then
			host.frenzy = true
		end
		say("frenzy", "TIME'S UP! The lights go out... and the host knows where you are!")
	end
	local _ = Hh
end)

-- ---------- players coming and going ----------
local spawnPart = Instance.new("SpawnLocation")
spawnPart.Anchored = true
spawnPart.Size = Vector3.new(6, 1, 6)
spawnPart.Position = at(14, 19, -0.4)
spawnPart.Transparency = 1
spawnPart.CanCollide = false
spawnPart.Neutral = true
spawnPart.Duration = 0
spawnPart.Parent = workspace

local started = false
Players.PlayerAdded:Connect(function(plr)
	setupPlayer(plr)
	local data = plr:GetJoinData().TeleportData
	if type(data) == "table" and not (host and host.model) then
		if Config.DIFFICULTY[data.difficulty] then
			RoundState:SetAttribute("Difficulty", data.difficulty)
		end
		if data.spook == "giggly" or data.spook == "spooky" then
			RoundState:SetAttribute("Spook", data.spook)
		end
		if RunService:IsStudio() and not RoundState:GetAttribute("Map") then
			RoundState:SetAttribute("Map", Config.STUDIO_MAP)
		end
		if typeof(data.map) == "string" and Progress.mapIndex(data.map) then
			RoundState:SetAttribute("Map", data.map)
		end
		if typeof(data.leader) == "number" and not RoundState:GetAttribute("Leader") then
			RoundState:SetAttribute("Leader", data.leader)
		end
		if data.tower == true and not data.rejoin then
			RoundState:SetAttribute("Tower", true)
			RoundState:SetAttribute("TowerStart", RoundState:GetAttribute("Map"))
		end
	end
	if RunService:IsStudio() and not RoundState:GetAttribute("Map") then
		RoundState:SetAttribute("Map", Config.STUDIO_MAP)
		if Config.STUDIO_TOWER then
			-- a Tower Run from floor 1 of that building
			local i = Progress.mapIndex(Config.STUDIO_MAP)
			for _, m in ipairs(Progress.MAPS) do
				if i and m.building == Progress.MAPS[i].building and m.floor == 1 then
					RoundState:SetAttribute("Map", m.id)
				end
			end
			RoundState:SetAttribute("Tower", true)
			RoundState:SetAttribute("TowerStart", RoundState:GetAttribute("Map"))
		end
	end
	if type(data) == "table" and typeof(data.code) == "string" then
		serverCode = data.code
	end
	-- the party the Lobby sent: the first game waits for all of them
	if type(data) == "table" and type(data.party) == "table" and not data.rejoin then
		for _, uid in ipairs(data.party) do
			if typeof(uid) == "number" then
				expectedPlayers[uid] = true
			end
		end
	end
	-- back after a dropped connection: the same character, where they were
	leaving[plr.UserId] = nil
	local was = dropped[plr.UserId]
	dropped[plr.UserId] = nil
	if rejoinMap then
		task.spawn(pcall, function()
			rejoinMap:RemoveAsync("u" .. plr.UserId)
		end)
	end
	if was and state.status == "playing" then
		rejoining[plr.UserId] = was
		plr:SetAttribute("Skill", was.skill)
		applyMods(plr)
		plr:SetAttribute("Ready", true)
	end
	task.spawn(paintFriends) -- asks Roblox who is friends with whom (can take a moment)
	-- no party leader known (Studio, or they left): the first one here leads
	if not RoundState:GetAttribute("Leader") then
		RoundState:SetAttribute("Leader", plr.UserId)
	end
	plr.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		-- the real character, if this skill's model has been imported
		if not char:GetAttribute("EscapeCrewChar") then
			for _, s in ipairs(Config.SKILLS) do
				if s.id == plr:GetAttribute("Skill") and Characters.has(modelFor(plr, s)) then
					if Characters.apply(plr, modelFor(plr, s)) then
						return -- CharacterAdded fires again for the new model
					end
				end
			end
		end
		gear(plr)
		local hum = char:WaitForChild("Humanoid")
		hum.WalkSpeed = Config.WALK
		local back = rejoining[plr.UserId]
		if back then
			rejoining[plr.UserId] = nil
			plr:SetAttribute("Waiting", false)
			if back.escaped then
				plr:SetAttribute("Escaped", true)
				teleport(plr, world.gardenSpot)
			elseif back.caged then
				plr:SetAttribute("Caged", true)
				intoCage(plr)
			else
				teleport(plr, at(HouseMap.start[1][1], HouseMap.start[1][2], 0))
			end
			say("info", plr.DisplayName .. " is back in the game!")
		elseif plr:GetAttribute("Caged") then
			intoCage(plr)
		elseif plr:GetAttribute("Escaped") then
			teleport(plr, world.gardenSpot)
		elseif host and host.model then
			-- arrived while the host is out: wait in the garden for the next round
			plr:SetAttribute("Waiting", true)
			plr:SetAttribute("Escaped", true)
			teleport(plr, world.gardenSpot)
			say("info", "A game is already running - you'll join the next one from the garden.", nil, plr)
		else
			teleport(plr, at(HouseMap.start[1][1], HouseMap.start[1][2], 0))
		end
	end)
	if not started then
		started = true
		round.start()
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	-- dropped out mid-game (friends still playing): they can rejoin from the Lobby
	local underway = state.status == "playing" and (RoundState:GetAttribute("HostOut") or RoundState:GetAttribute("EndsAt") ~= nil)
	if not leaving[plr.UserId] and underway and serverCode and #Players:GetPlayers() > 1 and plr:GetAttribute("Skill") and not plr:GetAttribute("Waiting") then
		dropped[plr.UserId] = { skill = plr:GetAttribute("Skill"), caged = plr:GetAttribute("Caged") == true, escaped = plr:GetAttribute("Escaped") == true }
		if rejoinMap then
			local info = { code = serverCode, job = game.JobId, map = RoundState:GetAttribute("Map") or "partyhouse", t = os.time() }
			task.spawn(pcall, function()
				rejoinMap:SetAsync("u" .. plr.UserId, info, Config.REJOIN_SECONDS)
			end)
		end
	end
	leaving[plr.UserId] = nil
	savePlayer(plr)
	said[plr.UserId] = nil
	task.defer(paintFriends)
	task.defer(checkEnd)
	if #Players:GetPlayers() <= 1 then
		started = false
	end
end)

game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		savePlayer(plr)
	end
end)
