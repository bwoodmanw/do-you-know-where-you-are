--[[
	Main - the referee for one server (up to 6 players). Builds the house,
	runs a round, wires every prompt, checks every request from players,
	and decides win or lose. Players only ask; the server decides.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage.Shared.Config)
local HouseMap = require(ReplicatedStorage.Shared.HouseMap)
local House = require(script.Parent.House)
local Host = require(script.Parent.Host)

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

local RoundState = Instance.new("Configuration")
RoundState.Name = "RoundState"
RoundState.Parent = ReplicatedStorage
RoundState:SetAttribute("Spook", "giggly")

-- ---------- saving points ----------
local store
pcall(function()
	store = DataStoreService:GetDataStore("DYKWYA_Points_v1")
end)

local function setupPlayer(plr)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = plr
	local pts = Instance.new("IntValue")
	pts.Name = "Points"
	pts.Parent = stats
	if store then
		local ok, v = pcall(function()
			return store:GetAsync("p" .. plr.UserId)
		end)
		if ok and type(v) == "number" then
			pts.Value = v
		end
	end
	plr:SetAttribute("Skill", "tinker")
	plr:SetAttribute("Energy", 100)
end

local function savePlayer(plr)
	local stats = plr:FindFirstChild("leaderstats")
	if store and stats then
		pcall(function()
			store:SetAsync("p" .. plr.UserId, stats.Points.Value)
		end)
	end
end

local function addPoints(plr, n)
	local stats = plr:FindFirstChild("leaderstats")
	if stats then
		stats.Points.Value += n
	end
end

-- ---------- the round ----------
local round = {}
local world, host
local state = {}
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

-- skill gear: a few parts welded to the avatar's head
local function gear(plr)
	local c = plr.Character
	local head = c and c:FindFirstChild("Head")
	if not head then
		return
	end
	local old = c:FindFirstChild("SkillGear")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "SkillGear"
	folder.Parent = c
	local s = head.Size.Y
	local function g(name, size, offset, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		if shape then
			p.Shape = shape
		end
		p.Size = size * s
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.CanCollide, p.Massless, p.Anchored, p.CanQuery = false, true, false, false
		p.CFrame = head.CFrame * CFrame.new(offset * s)
		p.Parent = folder
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = head, p
		w.Parent = p
		return p
	end
	local skill = plr:GetAttribute("Skill")
	if skill == "tinker" then
		for i = -1, 1, 2 do
			g("Goggle", Vector3.new(0.38, 0.38, 0.2), Vector3.new(i * 0.24, 0.42, -0.5), Color3.fromRGB(181, 140, 60), Enum.Material.Metal, Enum.PartType.Cylinder)
		end
		g("Strap", Vector3.new(1.05, 0.12, 1.05), Vector3.new(0, 0.42, 0), Color3.fromRGB(90, 60, 30))
	elseif skill == "shadow" then
		g("Mask", Vector3.new(1.08, 0.3, 1.08), Vector3.new(0, 0.05, 0), Color3.fromRGB(30, 24, 40), Enum.Material.Fabric)
	elseif skill == "brainy" then
		g("Beanie", Vector3.new(1.05, 0.5, 1.05), Vector3.new(0, 0.55, 0), Color3.fromRGB(232, 66, 63), Enum.Material.Fabric)
		g("Propeller", Vector3.new(1.0, 0.06, 0.18), Vector3.new(0, 0.95, 0), Color3.fromRGB(61, 139, 255))
	elseif skill == "muscle" then
		g("Sweatband", Vector3.new(1.08, 0.2, 1.08), Vector3.new(0, 0.32, 0), Color3.fromRGB(255, 210, 63), Enum.Material.Fabric)
	elseif skill == "glow" then
		g("Antenna", Vector3.new(0.06, 0.7, 0.06), Vector3.new(0, 0.85, 0), Color3.fromRGB(42, 77, 47))
		local bulb = g("Bulb", Vector3.new(0.3, 0.3, 0.3), Vector3.new(0, 1.25, 0), Color3.fromRGB(255, 242, 122), Enum.Material.Neon, Enum.PartType.Ball)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 242, 160), 22, 1.5
		l.Parent = bulb
	elseif skill == "patch" then
		g("Plaster", Vector3.new(0.4, 0.14, 0.05), Vector3.new(0.2, 0.35, -0.52), Color3.fromRGB(242, 208, 160))
	elseif skill == "echo" then
		g("Band", Vector3.new(1.1, 0.12, 0.2), Vector3.new(0, 0.6, 0), Color3.fromRGB(43, 33, 64))
		for i = -1, 1, 2 do
			g("Cup", Vector3.new(0.2, 0.42, 0.42), Vector3.new(i * 0.56, 0.05, 0), Color3.fromRGB(43, 33, 64))
		end
	elseif skill == "bramble" then
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			g("Leaf", Vector3.new(0.22, 0.36, 0.22), Vector3.new(math.cos(a) * 0.45, 0.62, math.sin(a) * 0.45), i % 2 == 0 and Color3.fromRGB(58, 125, 68) or Color3.fromRGB(95, 179, 90), Enum.Material.Grass, Enum.PartType.Ball)
		end
	end
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
	if escaped > 0 then
		state.status = "won"
		RoundState:SetAttribute("Status", "won")
		for _, plr in ipairs(list) do
			addPoints(plr, 20)
		end
		say("win", "You escaped the Party House! Everyone made it to the garden.")
		task.delay(10, round.start)
	else
		state.status = "lost"
		RoundState:SetAttribute("Status", "lost")
		say("lose", "Everyone is in the cage! The party starts again...")
		task.delay(7, round.start)
	end
end

local function escape(plr, side)
	if plr:GetAttribute("Escaped") or plr:GetAttribute("Caged") then
		return
	end
	plr:SetAttribute("Escaped", true)
	plr:SetAttribute("Hidden", false)
	teleport(plr, side and world.gardenSpotSide or world.gardenSpot)
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
	local door = world.objects.door.door
	door.CanCollide = false
	TweenService:Create(door, TweenInfo.new(1.2), { Position = door.Position + Vector3.new(0, 9.5, 0) }):Play()
	world.objects.door.usePrompt.Enabled = false
	world.objects.door.pickPrompt.Enabled = false
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
local function besideTile(x, y)
	local map = HouseMap.map
	for _, d in ipairs({ { 0, 1 }, { 1, 0 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 } }) do
		local nx, ny = x + d[1], y + d[2]
		local row = map[ny + 1]
		if row and string.sub(row, nx + 1, nx + 1) == "." then
			return at(nx, ny, 0)
		end
	end
	return at(x, y, 0)
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
				local col = state.code[def.n]
				state.known[def.n] = col
				RoundState:SetAttribute("Known" .. def.n, col)
				entry.part.Color = Config.COLOR3[col]
				entry.part.Material = Enum.Material.Neon
				entry.part.Size = Vector3.new(1.4, 1.4, 1.4)
				entry.part.Position = at(def.x, def.y, 0.8)
				entry.label.TextColor3 = Color3.new(1, 1, 1)
				addPoints(plr, 5)
				say("pop", "Balloon " .. def.n .. " was " .. colourWord(col) .. "! That was LOUD...", { n = def.n, color = col })
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
				entry.part.Transparency = 0.6
				addPoints(plr, 5)
				if def.boost == "shield" then
					plr:SetAttribute("Shield", true)
					say("boost", plr.DisplayName .. " found a Party Shield - it saves you from one grab!")
				else
					Boost:FireClient(plr, "candy")
					say("boost", plr.DisplayName .. " found Candy Corn - run without getting puffed!")
				end
			end)
		elseif def.kind == "invite" then
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Skill") ~= "brainy" then
					return need(plr, "brainy", "Twisty writing... Brainy could read this!")
				end
				entry.prompt.Enabled = false
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
				revealAll(plr, "Glow lit up the secret paint!")
			end)
		elseif def.kind == "plant" then
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Skill") ~= "bramble" then
					return need(plr, "bramble", "This plant looks like it knows something... Bramble could ask it!")
				end
				entry.prompt.Enabled = false
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
			entry.pickPrompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Skill") ~= "tinker" then
					return need(plr, "tinker", "Only Tinker can pick this lock. Try the colour code instead!")
				end
				openDoor(plr, "pick")
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
					addPoints(plr, 20 * freed)
					say("rescue", plr.DisplayName .. " freed " .. freed .. (freed == 1 and " friend" or " friends") .. " from the cage!")
				end
				entry.prompt.Enabled = anyCaged()
			end)
		elseif def.kind == "hide" then
			entry.outside = besideTile(def.x, def.y)
			entry.prompt.Triggered:Connect(function(plr)
				if plr:GetAttribute("Hidden") then
					return unhide(plr)
				end
				if plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
					return
				end
				if hideSpotCount(id) >= 2 then
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
function round.hostCaught(_, plr)
	if plr:GetAttribute("Shield") then
		plr:SetAttribute("Shield", false)
		host:stun(2.5)
		return say("shield", "POP! " .. plr.DisplayName .. "'s Party Shield saved them - run!")
	end
	plr:SetAttribute("Caged", true)
	teleport(plr, world.objects.cage.inside)
	setSpeed(plr, 0)
	world.objects.cage.prompt.Enabled = true
	say("caught", plr.DisplayName .. " was caught! Free them from the cage in the Front Hall!", { userId = plr.UserId })
	checkEnd()
end

local function hintFor()
	local o = world.objects
	if anyCaged() then
		return "cage", "Free your friend! Stand by the cage in the Front Hall."
	end
	if state.doorOpen then
		return "door", "The big door is open - everybody out!"
	end
	if state.holeOpen then
		return "hole", "The secret hole in the Game Room is open - squeeze through!"
	end
	if state.known[1] and state.known[2] and state.known[3] then
		return "door", "You know the colours! Use the keypad by the big door in the Corridor."
	end
	local skills = {}
	for _, p in ipairs(playersInRound()) do
		if not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") then
			skills[p:GetAttribute("Skill")] = true
		end
	end
	if skills.tinker then
		return "door", "Tinker can pick the lock on the big door in the Corridor."
	end
	if skills.muscle then
		return "cab", "That cabinet in the Game Room hides something. Muscle can shove it!"
	end
	if skills.brainy and o.invite.prompt.Enabled then
		return "invite", "Brainy can read the twisty invitation in the Parlour."
	end
	if skills.glow and o.uv.prompt.Enabled then
		return "uv", "Glow can light up the painted wall in the Library."
	end
	if skills.bramble and o.plant.prompt.Enabled then
		return "plant", "Bramble can ask the big plant in the Library."
	end
	for _, id in ipairs({ "b0", "b1", "b2" }) do
		if not o[id].popped then
			return id, "Pop the numbered balloons - each one shows a colour of the door code."
		end
	end
	return "door", "Try the keypad by the big door."
end

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
		if host then
			host:alert(world.objects.door.keypad.Position)
		end
	end
end)

PickSkill.OnServerEvent:Connect(function(plr, id)
	if typeof(id) ~= "string" then
		return
	end
	for _, s in ipairs(Config.SKILLS) do
		if s.id == id then
			plr:SetAttribute("Skill", id)
			gear(plr)
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
	local now = os.clock()
	if (plr:GetAttribute("CoolUntil") or 0) > now then
		return say("info", "Your skill is recharging... " .. math.ceil(plr:GetAttribute("CoolUntil") - now) .. " seconds", nil, plr)
	end
	local hrp = hrpOf(plr)
	if not hrp then
		return
	end
	if skill == "shadow" then
		plr:SetAttribute("SneakUntil", now + 6)
		say("sneak", plr.DisplayName .. " is sneaking - the host cannot see or grab them for 6 seconds!")
	elseif skill == "patch" then
		for _, p in ipairs(Players:GetPlayers()) do
			local h = hrpOf(p)
			if h and not p:GetAttribute("Caged") and (h.Position - hrp.Position).Magnitude < 18 then
				p:SetAttribute("Energy", math.min(100, (p:GetAttribute("Energy") or 0) + 40))
				Boost:FireClient(p, "stamina")
			end
		end
		say("heal", "Patch patched up everyone nearby - energy and stamina back!")
	elseif skill == "echo" then
		if typeof(pos) ~= "Vector3" or (pos - hrp.Position).Magnitude > 70 then
			return say("info", "Throw it somewhere closer!", nil, plr)
		end
		if host and host.model then
			host.mode = "search"
			host.goal = pos
		end
		say("lure", "Echo threw a noise - the host has gone to look!", { pos = pos })
	end
	plr:SetAttribute("CoolUntil", now + cd)
end)

AskClue.OnServerEvent:Connect(function(plr)
	if state.status ~= "playing" or state.cluesLeft <= 0 then
		return
	end
	local cost = plr:GetAttribute("Skill") == "brainy" and Config.CLUE_COST / 2 or Config.CLUE_COST
	local energy = plr:GetAttribute("Energy") or 0
	if energy < cost then
		return say("info", "Not enough energy for a clue.", nil, plr)
	end
	plr:SetAttribute("Energy", energy - cost)
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
	world = House.build(HouseMap)
	wirePrompts()
	local code = {}
	for i = 1, 3 do
		code[i] = Config.COLORS[math.random(1, #Config.COLORS)]
	end
	state = { status = "playing", code = code, known = {}, entry = {}, doorOpen = false, holeOpen = false, cluesLeft = Config.CLUES }
	RoundState:SetAttribute("Status", "playing")
	RoundState:SetAttribute("DoorOpen", false)
	RoundState:SetAttribute("CluesLeft", Config.CLUES)
	RoundState:SetAttribute("HostOut", false)
	for i = 1, 3 do
		RoundState:SetAttribute("Known" .. i, nil)
	end
	local spook = RoundState:GetAttribute("Spook")
	for _, l in ipairs(world.lights) do
		l.Brightness = spook == "spooky" and 0.45 or 1.2
	end
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
		local s = HouseMap.start[((i - 1) % #HouseMap.start) + 1]
		teleport(plr, at(s[1], s[2], 0))
	end
	host = Host.new(world, round)
	local grace = spook == "spooky" and Config.GRACE_SPOOKY or Config.GRACE
	say("start", "Find the way out of the Party House. Don't get caught!", { grace = grace })
	hostTimer = task.delay(grace, function()
		hostTimer = nil
		if state.status == "playing" then
			host:spawn(spook)
			RoundState:SetAttribute("HostOut", true)
			say("appear", "Ding dong! Who came to my party?")
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
	if host and host.model and state.status == "playing" then
		host:step(step)
	end
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
	plr.CharacterAdded:Connect(function(char)
		task.wait(0.2)
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
