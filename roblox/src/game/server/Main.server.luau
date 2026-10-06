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
local HouseMap = MapGen.make(Plans[1])
local House = require(script.Parent.House)
local Host = require(script.Parent.Host)
local Effects = require(script.Parent.Effects)
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
local UseSkill = remote("UseSkill") -- client -> server: optional position (Echo)
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

local RoundState = Instance.new("Configuration")
RoundState.Name = "RoundState"
RoundState.Parent = ReplicatedStorage
RoundState:SetAttribute("Spook", "giggly")
RoundState:SetAttribute("Difficulty", "normal")

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
effect("Atmosphere", { Density = 0.35, Color = Color3.fromRGB(120, 100, 150), Decay = Color3.fromRGB(40, 30, 60), Glare = 0, Haze = 1.5 })
effect("BloomEffect", { Intensity = 0.6, Size = 30, Threshold = 1.4 })
effect("ColorCorrectionEffect", { Saturation = -0.05, Contrast = 0.12, TintColor = Color3.fromRGB(255, 240, 230) })

-- ---------- saved progress (shared with the Lobby) ----------
local Profile = require(ReplicatedStorage.Shared.Profile)
local Progress = require(ReplicatedStorage.Shared.Progress)

local function setupPlayer(plr)
	Profile.load(plr)
	plr:SetAttribute("Skill", "tinker")
	plr:SetAttribute("Energy", 100)
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

local function savePlayer(plr)
	returnBag(plr)
	Profile.release(plr)
end

local state = {}
local function addPoints(plr, n)
	if n > 0 then
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
	plr:SetAttribute("StaminaMult", m.staminaMult)
	plr:SetAttribute("RunMult", m.runMult)
	plr:SetAttribute("SightMult", m.sightMult)
	-- Patch frees caged friends (and holds everything) twice as fast
	plr:SetAttribute("HoldMult", m.holdMult * (skill == "patch" and 0.5 or 1))
	plr:SetAttribute("CooldownMult", m.cooldownMult)
	plr:SetAttribute("SneakTime", m.sneakTime or 6)
	plr:SetAttribute("GlowRange", m.glowRange or 24)
	plr:SetAttribute("HealAmount", m.healAmount or 40)
	plr:SetAttribute("HealShield", m.healShield == true)
	plr:SetAttribute("EchoRange", m.echoRange or 70)
	return m
end

-- ---------- the round ----------
local round = {}
local world, host
local hostTimer = nil

local function say(kind, text, data, toPlayer)
	if toPlayer then
		Notify:FireClient(toPlayer, kind, text, data)
	else
		Notify:FireAllClients(kind, text, data)
	end
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
	return string.upper(c)
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
		local timeBonus = state.frenzy and 0 or math.max(0, math.floor((state.endsAt - now) / 6))
		for _, plr in ipairs(list) do
			addPoints(plr, plr:GetAttribute("Escaped") and (winBonus + timeBonus) or math.floor(winBonus / 2))
		end
		state.timeBonus = timeBonus
	else
		state.status = "lost"
	end
	RoundState:SetAttribute("Status", state.status)
	local rows = {}
	local mapId = RoundState:GetAttribute("Map") or "partyhouse"
	local seconds = math.floor(now - state.startedAt)
	for _, plr in ipairs(list) do
		local earned = state.earned[plr.UserId] or 0
		local skill = plr:GetAttribute("Skill")
		local out = plr:GetAttribute("Escaped") == true and not plr:GetAttribute("Waiting")
		local row = { name = plr.DisplayName, points = earned, escaped = out, skill = skill }
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
				local key = mapId .. "_" .. state.diff
				if not pd.best[key] or seconds < pd.best[key] then
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
			Profile.record(plr, mapId, state.diff, out and seconds or nil)
			task.spawn(Profile.save, plr)
		end
		table.insert(rows, row)
	end
	Results:FireAllClients({
		won = won,
		difficulty = diff.name,
		seconds = math.floor(now - state.startedAt),
		timeBonus = state.timeBonus or 0,
		nextIn = Config.VOTE_SECONDS,
		vote = true,
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
	if state.doorOpen then
		return
	end
	state.doorOpen = true
	RoundState:SetAttribute("DoorOpen", true)
	Effects.sound(world.objects.door.keypad.Position, "unlock", 1)
	local door = world.objects.door.door
	door.CanCollide = false
	TweenService:Create(door, TweenInfo.new(1.2), { Position = door.Position + Vector3.new(0, 9.5, 0) }):Play()
	world.objects.door.usePrompt.Enabled = false
	addPoints(plr, 25)
	say("open", how == "pick" and ("Click! " .. plr.DisplayName .. " picked the lock! Everybody out!") or "The big door is open! Everybody out!")
end

local function revealAll(plr, by)
	for i = 1, 3 do
		state.known[i] = state.code[i]
		RoundState:SetAttribute("Known" .. i, state.code[i])
	end
	addPoints(plr, 10)
	say("reveal", by .. " The code is " .. colourWord(state.code[1]) .. ", " .. colourWord(state.code[2]) .. ", " .. colourWord(state.code[3]) .. ".", state.code)
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
	"Nothing but old socks.",
	"Just crumbs and a sticky sweet. No key.",
	"A spider! But no key.",
	"Dusty party hats. No key here.",
	"Empty... the key must be somewhere else.",
}

-- a locked inner door opens (with its key, or Tinker picks it)
local function openLock(plr, id, how)
	if world.unlocked[id] then
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
	addPoints(plr, 15)
	say("open", (how == "pick" and ("Click! " .. plr.DisplayName .. " picked the lock on the ") or (plr.DisplayName .. " unlocked the ")) .. entry.def.name .. "!")
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
						host:alert(entry.part.Position)
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
				addPoints(plr, 5)
				Effects.burst(entry.part.Position + Vector3.new(0, 4, 0), "pop")
				say("pop", "Balloon " .. def.n .. " was " .. colourWord(col) .. "! That was LOUD...", { n = def.n, color = col, icon = Config.ITEM_ICONS.balloon, userId = plr.UserId })
				if host then
					host:alert(entry.part.Position)
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
				if not def.boost then
					Effects.sound(entry.part.Position, "hide")
					return say("info", "Empty! Just tissue paper.", nil, plr)
				end
				addPoints(plr, 5)
				if def.boost == "shield" then
					plr:SetAttribute("Shield", true)
					Effects.burst(entry.part.Position, "boost")
					say("boost", plr.DisplayName .. " found a Party Shield - it saves you from one grab!", { icon = Config.ITEM_ICONS.shield, userId = plr.UserId, item = "Party Shield" })
				else
					Boost:FireClient(plr, "candy")
					Effects.burst(entry.part.Position, "boost")
					say("boost", plr.DisplayName .. " found Candy Corn - run without getting puffed!", { icon = Config.ITEM_ICONS.candy, userId = plr.UserId, item = "Candy Corn" })
				end
			end)
		elseif def.kind == "invite" then
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Skill") ~= "brainy" then
					return need(plr, "brainy", "Twisty writing... Brainy could read this!")
				end
				entry.prompt.Enabled = false
				Effects.burst(entry.part.Position, "reveal")
				revealAll(plr, "Brainy cracked the invitation!")
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
				local t = ""
				for i = 1, 3 do
					local c = Config.COLOR3[state.code[i]]
					t ..= string.format('<font color="#%02x%02x%02x">&#9679;</font> ', math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
				end
				entry.label.Text = t
				Effects.burst(entry.part.Position, "light")
				revealAll(plr, "Glow lit up the secret paint!")
			end)
		elseif def.kind == "plant" then
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Skill") ~= "bramble" then
					return need(plr, "bramble", "This plant looks like it knows something... Bramble could ask it!")
				end
				entry.prompt.Enabled = false
				Effects.burst(entry.part.Position + Vector3.new(0, 3, 0), "plant")
				revealAll(plr, "The plant whispered the code to Bramble!")
			end)
		elseif def.kind == "cabinet" then
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Skill") ~= "muscle" then
					return need(plr, "muscle", "Too heavy! Muscle could shove it.")
				end
				if state.holeOpen then
					return
				end
				state.holeOpen = true
				entry.prompt.Enabled = false
				TweenService:Create(entry.part, TweenInfo.new(1), { Position = entry.part.Position + Vector3.new(0, 0, T) }):Play()
				Effects.burst(entry.part.Position, "shove")
				o.hole.panel:Destroy()
				addPoints(plr, 25)
				say("open", "Muscle shoved the cabinet - a secret hole! Squeeze through!")
			end)
		elseif def.kind == "door" then
			entry.usePrompt.Triggered:Connect(function(plr)
				if not state.doorOpen then
					OpenKeypad:FireClient(plr)
				end
			end)
			entry.exit.Touched:Connect(function(hit)
				local plr = Players:GetPlayerFromCharacter(hit.Parent)
				if plr and state.doorOpen and state.status == "playing" then
					escape(plr, false)
				end
			end)
		elseif def.kind == "hole" then
			entry.exit.Touched:Connect(function(hit)
				local plr = Players:GetPlayerFromCharacter(hit.Parent)
				if plr and state.holeOpen and state.status == "playing" then
					escape(plr, true)
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
					addPoints(plr, 20 * freed)
					local pd = Profile.get(plr)
					if pd then
						pd.stats.rescues += freed
					end
					say("rescue", plr.DisplayName .. " freed " .. freed .. (freed == 1 and " friend" or " friends") .. " from the cage!")
				end
				entry.prompt.Enabled = anyCaged()
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
				if plr:GetAttribute("Skill") ~= "tinker" then
					return need(plr, "tinker", "Only Tinker can pick a lock. Everyone else needs the key!")
				end
				Effects.burst(entry.lockPart.Position, "pick")
				openLock(plr, id, "pick")
			end)
		elseif def.kind == "search" then
			entry.prompt.Triggered:Connect(function(plr)
				if state.status ~= "playing" or entry.searched then
					return
				end
				entry.searched = true
				entry.prompt.Enabled = false
				Effects.sound(entry.part.Position, "hide")
				-- rummaging is noisy
				if host and math.random() < 0.5 then
					host:alert(entry.part.Position)
				end
				local lock = world.keyIn[id]
				House.openObject(entry, lock ~= nil)
				if lock then
					world.keys[lock] = true
					RoundState:SetAttribute("Key_" .. lock, true)
					Effects.burst(entry.part.Position, "boost")
					addPoints(plr, 10)
					say("key", plr.DisplayName .. " found the key to the " .. world.objects[lock].def.name .. "!", { icon = "\u{1F511}", userId = plr.UserId, item = "Key" })
				else
					say("info", NOTHING[math.random(1, #NOTHING)], nil, plr)
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
				state.ventCool = state.ventCool or {}
				local nowT = os.clock()
				if (state.ventCool[def.pair] or 0) > nowT then
					return say("info", "Someone just crawled through - wait a moment.", nil, plr)
				end
				state.ventCool[def.pair] = nowT + 10
				plr:SetAttribute("Crawling", true)
				local h = hrpOf(plr)
				if h then
					h.Anchored = true
				end
				setVisible(plr, false)
				Effects.sound(entry.part.Position, "hide")
				say("info", "Crawling through the vent...", nil, plr)
				task.delay(1.6, function()
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
				local hrp = hrpOf(plr)
				if hrp then
					hrp.CFrame = CFrame.new(entry.inside)
					hrp.Anchored = true
				end
				setVisible(plr, false)
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
	table.insert(state.gummies, g)
	Effects.sound(g.Position, "pop", 0.5)
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

-- hit by a thrown pumpkin: knocked flat for a moment
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

function round.hostCaught(_, plr)
	unhide(plr)
	if plr:GetAttribute("Shield") then
		plr:SetAttribute("Shield", false)
		host:stun(2.5)
		return say("shield", "POP! " .. plr.DisplayName .. "'s Party Shield saved them - run!")
	end
	Effects.at(plr, "caught")
	if host then
		host:stun(2.8) -- holds still for the close-up
	end
	plr:SetAttribute("Caged", true)
	teleport(plr, world.objects.cage.inside)
	setSpeed(plr, 0)
	world.objects.cage.prompt.Enabled = true
	say("caught", plr.DisplayName .. " was caught! Free them from the cage in the " .. roomOf("cage") .. "!", { userId = plr.UserId })
	checkEnd()
end

local function hintFor()
	local o = world.objects
	if anyCaged() then
		return "cage", "Free your friend! Stand by the cage in the " .. roomOf("cage") .. "."
	end
	if state.doorOpen then
		return "door", "The big door is open - everybody out!"
	end
	if state.holeOpen then
		return "hole", "The secret hole in the " .. roomOf("cab") .. " is open - squeeze through!"
	end
	local skills = {}
	for _, p in ipairs(playersInRound()) do
		if not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") then
			skills[p:GetAttribute("Skill")] = true
		end
	end
	local function lockHint(id)
		local name = o[id].def.name
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
	local known = state.known[1] and state.known[2] and state.known[3]
	if known then
		if not world.unlocked.L1 then
			return lockHint("L1")
		end
		if not world.unlocked.L2 then
			return lockHint("L2")
		end
		return "door", "You know the colours! Use the keypad by the big door in the " .. roomOf("door") .. "."
	end
	if skills.brainy and o.invite.prompt.Enabled and reachable("invite") then
		return "invite", "Brainy can read the twisty invitation in the " .. roomOf("invite") .. "."
	end
	if skills.glow and o.uv.prompt.Enabled and reachable("uv") then
		return "uv", "Glow can light up the painted wall in the " .. roomOf("uv") .. "."
	end
	if skills.bramble and o.plant.prompt.Enabled and reachable("plant") then
		return "plant", "Bramble can ask the big plant in the " .. roomOf("plant") .. "."
	end
	for _, id in ipairs({ "b0", "b1", "b2" }) do
		if o[id] and not o[id].popped and reachable(id) then
			return id, "Pop balloon " .. o[id].def.n .. " in the " .. roomOf(id) .. " - it shows a colour of the door code. Careful: some balloons are tricks!"
		end
	end
	if not world.unlocked.L1 then
		return lockHint("L1")
	end
	if not world.unlocked.L2 then
		return lockHint("L2")
	end
	if skills.muscle then
		return "cab", "That cabinet in the " .. roomOf("cab") .. " hides something. Muscle can shove it!"
	end
	return "door", "Try the keypad by the big door in the " .. roomOf("door") .. "."
end

-- ---------- after a round: play again or go back to the lobby ----------
local votes = {}
local voting = false

local function toLobby(list)
	local lobbyId = Places.lobby()
	if not lobbyId or #list == 0 then
		return false
	end
	local ok = pcall(function()
		TeleportService:TeleportAsync(lobbyId, list)
	end)
	return ok
end

function round.startVote()
	votes = {}
	voting = true
	task.delay(Config.VOTE_SECONDS, function()
		voting = false
		local again, rest = {}, {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if votes[plr.UserId] == "again" then
				table.insert(again, plr)
			elseif votes[plr.UserId] ~= "lobby" then
				table.insert(rest, plr)
			end
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
	if not voting or (choice ~= "again" and choice ~= "lobby") then
		return
	end
	votes[plr.UserId] = choice
	if choice == "lobby" then
		if not toLobby({ plr }) then
			say("info", "The lobby only works in the published game - you'll play again here.", nil, plr)
			votes[plr.UserId] = "again"
		end
	end
	say("vote", plr.DisplayName .. (choice == "again" and " wants to play again!" or " went back to the lobby."))
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
	if #e < 3 then
		return
	end
	state.entry[plr.UserId] = {}
	if e[1] == state.code[1] and e[2] == state.code[2] and e[3] == state.code[3] then
		openDoor(plr, "code")
	else
		say("wrong", "Wrong code! And that was LOUD... something is coming.", nil, plr)
		Effects.sound(world.objects.door.keypad.Position, "wrong", 1)
		if host then
			host:alert(world.objects.door.keypad.Position)
		end
	end
end)

PickSkill.OnServerEvent:Connect(function(plr, id)
	if typeof(id) ~= "string" then
		return
	end
	-- choose freely until the host comes out; after that, wait for the next game
	if state.status == "playing" and RoundState:GetAttribute("HostOut") then
		return say("info", "The host is out! You can change character before the next game.", nil, plr)
	end
	for _, s in ipairs(Config.SKILLS) do
		if s.id == id then
			plr:SetAttribute("Skill", id)
			applyMods(plr)
			if not Characters.apply(plr, s.name) then
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

UseSkill.OnServerEvent:Connect(function(plr, pos)
	local skill = plr:GetAttribute("Skill")
	local cd = Config.COOLDOWN[skill]
	if not cd or state.status ~= "playing" or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
		return
	end
	local now = workspace:GetServerTimeNow()
	if (plr:GetAttribute("CoolUntil") or 0) > now then
		return say("info", "Your skill is recharging... " .. math.ceil(plr:GetAttribute("CoolUntil") - now) .. " seconds", nil, plr)
	end
	local hrp = hrpOf(plr)
	if not hrp then
		return
	end
	if skill == "shadow" then
		plr:SetAttribute("SneakUntil", now + (plr:GetAttribute("SneakTime") or 6))
		Effects.at(plr, "sneak")
		say("sneak", plr.DisplayName .. " is sneaking - the host cannot see or grab them for 6 seconds!", { userId = plr.UserId })
	elseif skill == "patch" then
		-- a Party Shield for the nearest friend (all nearby with Shields for
		-- All), everyone's breath back; alone, Patch shields herself
		local nearest, nd, given = nil, math.huge, 0
		for _, p in ipairs(Players:GetPlayers()) do
			local h = hrpOf(p)
			if p ~= plr and h and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") then
				local d = (h.Position - hrp.Position).Magnitude
				if d < 18 then
					Boost:FireClient(p, "stamina")
					if plr:GetAttribute("HealShield") then
						p:SetAttribute("Shield", true)
						given += 1
					elseif d < nd then
						nearest, nd = p, d
					end
				end
			end
		end
		if nearest then
			nearest:SetAttribute("Shield", true)
			given += 1
		end
		if given == 0 then
			plr:SetAttribute("Shield", true)
		end
		Boost:FireClient(plr, "stamina")
		Effects.at(plr, "heal")
		say("heal", given == 0 and "Patch gave herself a Party Shield!" or ("Patch handed out " .. given .. (given == 1 and " Party Shield" or " Party Shields") .. " - one grab each!"), { userId = plr.UserId })
	elseif skill == "echo" then
		if typeof(pos) ~= "Vector3" or (pos - hrp.Position).Magnitude > (plr:GetAttribute("EchoRange") or 70) then
			return say("info", "Throw it somewhere closer!", nil, plr)
		end
		if host and host.model then
			host.mode = "search"
			host.goal = pos
		end
		Effects.burst(pos + Vector3.new(0, 1, 0), "noise")
		say("lure", "Echo threw a noise - the host has gone to look!", { pos = pos, userId = plr.UserId })
	end
	plr:SetAttribute("CoolUntil", now + cd * (plr:GetAttribute("CooldownMult") or 1))
end)

AskClue.OnServerEvent:Connect(function(plr)
	if state.status ~= "playing" or state.cluesLeft <= 0 then
		return
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
	local id, text = hintFor()
	local entry = world.objects[id]
	local target = entry and (entry.keypad or entry.part or entry.exit)
	if target then
		local hl = Instance.new("Highlight")
		hl.FillColor = Color3.fromRGB(123, 227, 107)
		hl.OutlineColor = Color3.fromRGB(123, 227, 107)
		hl.FillTransparency = 0.6
		hl.Adornee = target
		hl.Parent = target
		task.delay(15, function()
			hl:Destroy()
		end)
	end
	say("clue", text)
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
	Bubble:FireAllClients(plr, idx)
end)

Unhide.OnServerEvent:Connect(unhide)

UseCandy.OnServerEvent:Connect(function(plr)
	local n = plr:GetAttribute("CandyCharges") or 0
	if n <= 0 or state.status ~= "playing" then
		return
	end
	plr:SetAttribute("CandyCharges", n - 1)
	Boost:FireClient(plr, "candy")
	Effects.at(plr, "boost")
	say("boost", plr.DisplayName .. " ate Candy Corn - running without getting puffed!", { icon = Config.ITEM_ICONS.candy, userId = plr.UserId, item = "Candy Corn" })
end)

UseBoost.OnServerEvent:Connect(function(plr, id)
	local bag = bags[plr.UserId]
	local i = bag and typeof(id) == "string" and table.find(bag, id)
	if not i or state.status ~= "playing" or plr:GetAttribute("Escaped") then
		return
	end
	local boost = Progress.BOOSTS[id]
	table.remove(bag, i)
	paintBag(plr)
	if id == "candy" then
		Boost:FireClient(plr, "candy")
	elseif id == "energy" then
		Boost:FireClient(plr, "stamina")
	elseif id == "freeze" then
		if host and host.model then
			host:stun(10)
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
		RoundState:SetAttribute("CluesLeft", state.cluesLeft)
	end
	Effects.at(plr, "boost")
	local spot = hrpOf(plr)
	if spot and (id == "candy" or id == "energy") then
		Effects.sound(spot.Position, id)
	end
	say("boost", plr.DisplayName .. " used " .. boost.name .. "!", { icon = boost.icon, userId = plr.UserId, item = boost.name })
end)

SetDifficulty.OnServerEvent:Connect(function(_, key)
	if typeof(key) == "string" and Config.DIFFICULTY[key] and not (host and host.model) then
		RoundState:SetAttribute("Difficulty", key)
		say("info", "Difficulty: " .. Config.DIFFICULTY[key].name)
	end
end)

SetSpook.OnServerEvent:Connect(function(_, level)
	if (level == "giggly" or level == "spooky") and not (host and host.model) then
		RoundState:SetAttribute("Spook", level)
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
	-- the floor this server plays (the Lobby's choice; Config.STUDIO_MAP in Studio)
	local mapIdx = Progress.mapIndex(RoundState:GetAttribute("Map") or "partyhouse")
	local floorNo = mapIdx and Progress.MAPS[mapIdx].floor or 1
	HouseMap = MapGen.make(Plans[floorNo] or Plans[1])
	RoundState:SetAttribute("MapJson", HttpService:JSONEncode(MapGen.forClient(HouseMap)))
	world = House.build(HouseMap)
	Props.place(world)
	wirePrompts()
	-- each locked door hides its key in a random searchable thing on its near side
	world.unlocked, world.keys, world.keyIn = {}, {}, {}
	for _, lock in ipairs({ { "L1", 1 }, { "L2", 2 } }) do
		local choices = {}
		for oid, e in pairs(world.objects) do
			if e.def.kind == "search" and e.def.zone == lock[2] then
				table.insert(choices, oid)
			end
		end
		if #choices > 0 and world.objects[lock[1]] then
			world.keyIn[choices[math.random(1, #choices)]] = lock[1]
		end
		RoundState:SetAttribute("Lock_" .. lock[1], false)
		RoundState:SetAttribute("Key_" .. lock[1], false)
	end
	local code = {}
	for i = 1, 3 do
		code[i] = Config.COLORS[math.random(1, #Config.COLORS)]
	end
	local diffKey = RoundState:GetAttribute("Difficulty") or "normal"
	local diff = Config.DIFFICULTY[diffKey]
	local now = workspace:GetServerTimeNow()
	state = { status = "playing", code = code, known = {}, entry = {}, doorOpen = false, holeOpen = false, cluesLeft = diff.clues,
		diff = diffKey, earned = {}, startedAt = now, endsAt = now + diff.timer, frenzy = false }
	RoundState:SetAttribute("Status", "playing")
	RoundState:SetAttribute("ClueCost", Config.CLUE_COSTS[1])
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("GameEarned", 0)
	end
	RoundState:SetAttribute("DoorOpen", false)
	RoundState:SetAttribute("CluesLeft", diff.clues)
	RoundState:SetAttribute("EndsAt", state.endsAt)
	RoundState:SetAttribute("Frenzy", false)
	RoundState:SetAttribute("HostOut", false)
	for i = 1, 3 do
		RoundState:SetAttribute("Known" .. i, nil)
	end
	local spook = RoundState:GetAttribute("Spook")
	for _, l in ipairs(world.lights) do
		l.Brightness = spook == "spooky" and 0.45 or 1.2
	end
	local extraClues, extraGrace, reveal = 0, 0, false
	for i, plr in ipairs(Players:GetPlayers()) do
		plr:SetAttribute("Waiting", false)
		plr:SetAttribute("Escaped", false)
		plr:SetAttribute("Caged", false)
		plr:SetAttribute("Hidden", false)
		plr:SetAttribute("Shield", false)
		plr:SetAttribute("Energy", 100)
		local hrp = hrpOf(plr)
		if hrp then
			hrp.Anchored = false
		end
		setVisible(plr, true)
		setSpeed(plr, Config.WALK)
		local mods = applyMods(plr)
		plr:SetAttribute("Energy", 100 + mods.energyStart)
		plr:SetAttribute("Shield", mods.shield == true)
		extraClues += mods.clues
		reveal = reveal or mods.revealOne == true
		-- boosts brought from the Lobby shop, used up in this game
		local pd = Profile.get(plr)
		local on = {}
		bags[plr.UserId] = bags[plr.UserId] or {}
		if pd and pd.loadout and #pd.loadout > 0 then
			for _, id in ipairs(pd.loadout) do
				if id == "shield" then
					plr:SetAttribute("Shield", true)
					table.insert(on, id)
				elseif id == "headstart" then
					extraGrace = 10
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
	if extraClues > 0 then
		state.cluesLeft += extraClues
		RoundState:SetAttribute("CluesLeft", state.cluesLeft)
	end
	if reveal then
		local k = math.random(1, 3)
		state.known[k] = state.code[k]
		RoundState:SetAttribute("Known" .. k, state.code[k])
	end
	host = Host.new(world, round)
	-- tonight's host: half the time the building's own, otherwise another
	local mapI = Progress.mapIndex(RoundState:GetAttribute("Map") or "partyhouse")
	local own = Config.BUILDING_HOST[mapI and Progress.MAPS[mapI].building or "partyhouse"] or "pumpkin"
	local kind = own
	if math.random() >= 0.5 then
		local others = {}
		for k in pairs(Config.HOSTS) do
			if k ~= own then
				table.insert(others, k)
			end
		end
		kind = others[math.random(1, #others)]
	end
	host.kind = kind
	RoundState:SetAttribute("HostKind", kind)
	RoundState:SetAttribute("Blackout", "")
	local grace = diff.grace + extraGrace
	say("start", "Find the way out of the Party House. Don't get caught!", { grace = grace })
	hostTimer = task.delay(grace, function()
		hostTimer = nil
		if state.status == "playing" then
			host:spawn(Config.DIFFICULTY[state.diff])
			RoundState:SetAttribute("HostOut", true)
			say("appear", "Ding dong! Who came to my party? (Tonight's host: " .. Config.HOSTS[host.kind or "pumpkin"].name .. ")")
		end
	end)
end

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
	local W, Hh = HouseMap.w * T, HouseMap.h * T
	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = hrpOf(plr)
		if hrp then
			local pos = hrp.Position
			if pos.Y < -20 then
				-- fell off the world: back to safety
				teleport(plr, plr:GetAttribute("Escaped") and world.gardenSpot or at(HouseMap.start[1][1], HouseMap.start[1][2], 0))
			elseif not plr:GetAttribute("Escaped") and not plr:GetAttribute("Caged") and not plr:GetAttribute("Waiting") then
				if state.doorOpen and pos.Z < -1 then
					escape(plr, false)
				elseif state.holeOpen and pos.X > W + 1 then
					escape(plr, true)
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
	end
	plr.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		-- the real character, if this skill's model has been imported
		if not char:GetAttribute("EscapeCrewChar") then
			for _, s in ipairs(Config.SKILLS) do
				if s.id == plr:GetAttribute("Skill") and Characters.has(s.name) then
					if Characters.apply(plr, s.name) then
						return -- CharacterAdded fires again for the new model
					end
				end
			end
		end
		gear(plr)
		local hum = char:WaitForChild("Humanoid")
		hum.WalkSpeed = Config.WALK
		if plr:GetAttribute("Caged") then
			teleport(plr, world.objects.cage.inside)
			setSpeed(plr, 0)
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
	savePlayer(plr)
	said[plr.UserId] = nil
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
