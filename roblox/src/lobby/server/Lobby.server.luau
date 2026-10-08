--[[
	Lobby - where everyone arrives. A party of 1-6 forms here (friends only
	by default), its leader picks difficulty and Giggly/Spooky, and Start
	sends the whole party to its own private server of the Party House.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)

-- the Lobby code synced into the Party House by mistake: say so and stop
if game.PlaceId == Config.PLACE_IDS.game then
	warn("WRONG PLACE: this is the Lobby code, but this is the Party House place. In Rojo, connect the Party House to port 34872 (game.project.json).")
	return
end
local Places = require(ReplicatedStorage.Shared.Places)
local offerRejoin, queueReminder, Quests -- set further down
local Profile = require(ReplicatedStorage.Shared.Profile)
local Progress = require(ReplicatedStorage.Shared.Progress)

-- 3D characters for the Characters screen, from the models saved to Roblox
do
	local previews = Instance.new("Folder")
	previews.Name = "Previews"
	previews.Parent = ReplicatedStorage
	require(ReplicatedStorage.Shared.CharacterAssets).fill(previews, nil)
end
local MarketplaceService = game:GetService("MarketplaceService")

-- ---------- the lobby scene: the lane outside the Party House ----------
do
	local Lighting = game:GetService("Lighting")
	local function atLeast(c, r, g, b)
		return Color3.fromRGB(math.max(c.R * 255, r), math.max(c.G * 255, g), math.max(c.B * 255, b))
	end
	Lighting.Ambient = atLeast(Lighting.Ambient, 70, 62, 84)
	Lighting.OutdoorAmbient = atLeast(Lighting.OutdoorAmbient, 105, 96, 125)
end
local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = workspace
	return p
end

part({ Name = "Ground", Size = Vector3.new(200, 2, 200), Position = Vector3.new(0, -1, 0), Material = Enum.Material.Grass, Color = Color3.fromRGB(46, 82, 40) })
part({ Name = "Lane", Size = Vector3.new(16, 0.2, 140), Position = Vector3.new(0, 0.1, -20), Material = Enum.Material.Cobblestone, Color = Color3.fromRGB(90, 84, 80) })
-- the house at the end of the lane
part({ Name = "HouseFront", Size = Vector3.new(60, 34, 4), Position = Vector3.new(0, 17, -92), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(40, 28, 46) })
part({ Name = "Roof", Size = Vector3.new(66, 4, 30), CFrame = CFrame.new(0, 38, -100) * CFrame.Angles(math.rad(-25), 0, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(25, 20, 30) })
part({ Name = "Door", Size = Vector3.new(8, 14, 1), Position = Vector3.new(0, 7, -89.6), Material = Enum.Material.Wood, Color = Color3.fromRGB(122, 74, 30) })
for _, x in ipairs({ -20, -8, 8, 20 }) do
	for _, y in ipairs({ 12, 26 }) do
		if not (x == -8 and y == 12) and not (x == 8 and y == 12) then
			local w = part({ Name = "Window", Size = Vector3.new(6, 7, 0.5), Position = Vector3.new(x, y, -89.8), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 190, 90) })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 180, 90), 18, 1.5
			l.Parent = w
		end
	end
end
-- nobody walks round the house: an invisible wall across the end of the lawn
part({ Name = "HouseFence", Size = Vector3.new(200, 60, 2), Position = Vector3.new(0, 30, -88), Transparency = 1 })
-- ground under the house itself (the lawn stops at z -100; the house goes back further)
part({ Name = "HouseYard", Size = Vector3.new(160, 2, 80), Position = Vector3.new(0, -1, -138), Material = Enum.Material.Grass, Color = Color3.fromRGB(46, 82, 40) })
-- a realistic house model (ServerStorage/LobbyProps/House in THIS place) replaces
-- the built front. It is only scenery: imported with File > Import, no Avatar
-- Setup needed (a rig from Avatar Setup is removed here anyway).
local customHouse = false
local function placeHouse()
	local props = game:GetService("ServerStorage"):FindFirstChild("LobbyProps")
	local model = props and props:FindFirstChild("House")
	if not model then
		return
	end
	local m = model:Clone()
	if not m:IsA("Model") then
		local wrap = Instance.new("Model")
		m.Parent = wrap
		m = wrap
	end
	local parts = 0
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Humanoid") or d:IsA("Motor6D") or d:IsA("Bone") then
			d:Destroy()
		end
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			parts += 1
		end
	end
	if parts == 0 then
		return warn("Lobby house: LobbyProps/House has no parts to show")
	end
	-- face the lawn (Meshy models face the other way: turned by Config.LOBBY_HOUSE_TURN)
	m:PivotTo(CFrame.Angles(math.rad(Config.LOBBY_HOUSE_TILT or 0), 0, 0) * CFrame.Angles(0, math.rad(Config.LOBBY_HOUSE_TURN or 180), 0))
	local _, size = m:GetBoundingBox()
	if size.X > 0 then
		m:ScaleTo(m:GetScale() * 70 / size.X)
	end
	local cf2, size2 = m:GetBoundingBox()
	-- front on the fence line, standing on the ground, centred on the lane
	local fwd = Config.LOBBY_HOUSE_FORWARD or 0
	m:PivotTo(m:GetPivot() + (Vector3.new(0, size2.Y / 2 - (Config.LOBBY_HOUSE_SINK or 0), -90 + fwd - size2.Z / 2) - cf2.Position))
	local fence = workspace:FindFirstChild("HouseFence")
	if fence then
		fence.Position = Vector3.new(0, 30, -88 + fwd)
	end
	m.Name = "LobbyHouse"
	m.Parent = workspace
	for _, p2 in ipairs(workspace:GetChildren()) do
		if p2:IsA("BasePart") and (p2.Name == "HouseFront" or p2.Name == "Roof" or p2.Name == "Door" or p2.Name == "Watcher") then
			p2.Transparency, p2.CanCollide = 1, false
		end
	end
	-- the old built windows become invisible spots on the model's own windows
	customHouse = true
	local spots = Config.LOBBY_HOUSE_WINDOWS or {}
	-- precise spots: Parts named PeekSpot placed on the model's windows in Studio
	local exact = {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "PeekSpot" then
			d.Transparency, d.CanCollide = 1, false
			table.insert(exact, d.Position)
		end
	end
	local n = 0
	for _, w in ipairs(workspace:GetChildren()) do
		if w:IsA("BasePart") and w.Name == "Window" then
			n += 1
			local s = spots[n]
			w.Transparency, w.CanCollide = 1, false
			local l = w:FindFirstChildOfClass("PointLight")
			if l then
				l.Brightness = 0.6
			end
			if exact[n] then
				w.Position = exact[n] + Vector3.new(0, 0, 0.3)
			elseif s and #exact == 0 then
				-- on the house's own front at that spot (windows sit back from the porch)
				local x, y = s[1] * size2.X, s[2] * size2.Y - (Config.LOBBY_HOUSE_SINK or 0)
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Include
				params.FilterDescendantsInstances = { m }
				local hit = workspace:Raycast(Vector3.new(x, y, -40), Vector3.new(0, 0, -120), params)
				w.Position = hit and (hit.Position + Vector3.new(0, 0, 0.4)) or Vector3.new(x, y, -89.4 + fwd)
			else
				w.Name = "UnusedWindow"
			end
		end
	end
	print(string.format("Lobby house: placed LobbyProps/House, %d parts, %.0f x %.0f x %.0f studs", parts, size2.X, size2.Y, size2.Z))
end
-- window faces the owner set by clicking the windows (saved), else the
-- measured Config.LOBBY_HOUSE_WINDOWS. Stored relative to the house.
local LobbyStore = game:GetService("DataStoreService"):GetDataStore("EscapeCrewLobby")
local peekTest = {} -- windows to peek in straight away (the owner's Test)
local function applyPeekSpots(list)
	local m = workspace:FindFirstChild("LobbyHouse")
	if not m then
		return
	end
	local pivot = m:GetPivot()
	local spots = {}
	for _, w in ipairs(workspace:GetChildren()) do
		if w:IsA("BasePart") and (w.Name == "Window" or w.Name == "UnusedWindow") then
			table.insert(spots, w)
		end
	end
	for i, rel in ipairs(list) do
		local w = spots[i]
		if not w then
			w = part({ Name = "Window", Size = Vector3.new(6, 7, 0.5), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 190, 90) })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 180, 90), 18, 0.6
			l.Parent = w
			table.insert(spots, w)
		end
		w.Name, w.Transparency, w.CanCollide = "Window", 1, false
		w.Position = pivot:PointToWorldSpace(Vector3.new(rel[1], rel[2], rel[3]))
	end
	for i = #list + 1, #spots do
		spots[i].Name = "UnusedWindow"
	end
end
local okHouse, houseErr = pcall(placeHouse)
if okHouse then
	task.spawn(function()
		local ok, saved = pcall(function()
			return LobbyStore:GetAsync("peekSpots")
		end)
		if ok and type(saved) == "table" and #saved > 0 then
			applyPeekSpots(saved)
			print("Lobby peek: using " .. #saved .. " window spots set by clicking (saved)")
		elseif not ok then
			warn("Lobby peek: could not read the saved window spots (in Studio: Game Settings -> Security -> Enable Studio Access to API Services) - using the measured spots")
		else
			print("Lobby peek: no saved window spots yet - using the measured spots (owner: 🪟 Windows button)")
		end
	end)
end
if not okHouse then
	warn("Lobby house: could not place it - " .. tostring(houseErr))
end
-- now and then the host peeks out of a window, or its shadow does
task.spawn(function()
	local head
	local faceDir = Vector3.new(0, 0, -1)
	local id = Config.CHARACTER_ASSETS and Config.CHARACTER_ASSETS.Host
	if id and id > 0 then
		local m = require(ReplicatedStorage.Shared.CharacterAssets).load("Host", id)
		local h = m and m:FindFirstChild("Head")
		local root = m and m:FindFirstChild("HumanoidRootPart")
		if h and h:IsA("BasePart") then
			-- which way the face looks, in the head's own terms: the way the body
			-- faces when it walks (its root), which we know is right
			if root then
				faceDir = h.CFrame:VectorToObjectSpace(root.CFrame.LookVector)
			end
			head = h:Clone()
			for _, c in ipairs(head:GetChildren()) do
				if not (c:IsA("SurfaceAppearance") or c:IsA("SpecialMesh") or c:IsA("Decal")) then
					c:Destroy()
				end
			end
			head.Anchored, head.CanCollide, head.CanQuery = true, false, false
		end
		if m then
			m:Destroy()
		end
	end
	print(head and ("Lobby peek: host head loaded (" .. head.ClassName .. ", " .. tostring(head.Size) .. ")") or "Lobby peek: no host head - peeks show a shadow instead")
	while true do
		local gap = Config.LOBBY_PEEK_GAP
		local waitFor, t0 = math.random(gap[1], gap[2]), os.clock()
		while os.clock() - t0 < waitFor and #peekTest == 0 do
			task.wait(0.25)
		end
		local windows = {}
		for _, w in ipairs(workspace:GetChildren()) do
			if w.Name == "Window" and w:IsA("BasePart") then
				table.insert(windows, w)
			end
		end
		local w = table.remove(peekTest, 1) or windows[math.random(1, math.max(1, #windows))]
		-- one peek going wrong must never stop the peeks for the rest of the server's life
		local okPeek, peekErr = pcall(function()
		if w then
			local old = w.Color
			w.Color = Color3.fromRGB(200, 60, 40)
			if head and (customHouse or math.random() < 0.6) then
				-- the host's face rises into the window, stares, and sinks away.
				-- The imported head's own front is its +Z, so it faces the lawn as it is.
				local h = head:Clone()
				h.Size = h.Size * (6 / math.max(h.Size.X, h.Size.Y))
				-- turn the head so its face points out at the lawn (+Z)
				local turn, best = 0, -2
				for i = 0, 71 do
					local a = i / 72 * math.pi * 2
					local z = CFrame.Angles(0, a, 0):VectorToWorldSpace(faceDir).Z
					if z > best then
						turn, best = a, z
					end
				end
				local shown = CFrame.new(w.Position + Vector3.new(0, 0, 1.2)) * CFrame.Angles(0, turn, 0)
				local hidden = shown - Vector3.new(0, 4, 0)
				if game:GetService("RunService"):IsStudio() then
					print(string.format("Lobby peek: window at %.0f, %.0f; face turned %d degrees", w.Position.X, w.Position.Y, math.deg(turn)))
				end
				h.CFrame = hidden
				h.Transparency = 1
				local glow = Instance.new("PointLight")
				glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(255, 150, 60), 10, 2.5
				glow.Parent = h
				h.Parent = workspace
				local TweenService = game:GetService("TweenService")
				TweenService:Create(h, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = shown, Transparency = 0 }):Play()
				task.wait(0.7 + Config.LOBBY_PEEK_SECONDS)
				TweenService:Create(h, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = hidden, Transparency = 1 }):Play()
				task.wait(0.75)
				h:Destroy()
			else
				-- a shadow standing behind the glass
				local shadow = Instance.new("Model")
				shadow.Name = "WindowShadow"
				part({ Name = "ShadowHead", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 0.2), Position = w.Position + Vector3.new(0, 1.6, 0.3), Color = Color3.new(0, 0, 0), Transparency = 0.15, CanCollide = false }).Parent = shadow
				part({ Name = "ShadowBody", Size = Vector3.new(4.2, 3.2, 0.2), Position = w.Position + Vector3.new(0, -1.8, 0.3), Color = Color3.new(0, 0, 0), Transparency = 0.15, CanCollide = false }).Parent = shadow
				shadow.Parent = workspace
				task.wait(Config.LOBBY_PEEK_SECONDS)
				shadow:Destroy()
			end
			w.Color = old
		end
		end)
		if not okPeek then
			warn("Lobby peek failed (trying again next time): " .. tostring(peekErr))
			task.wait(5)
		end
	end
end)
-- a silhouette at the top window
local watcher = part({ Name = "Watcher", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), Position = Vector3.new(20, 27, -89.4), Material = Enum.Material.Neon, Color = Color3.fromRGB(230, 110, 20) })
if customHouse then
	watcher.Transparency = 1
end
-- the gate with balloons, and lamps along the lane
part({ Name = "GatePostL", Size = Vector3.new(2, 8, 2), Position = Vector3.new(-9, 4, -60), Material = Enum.Material.Brick, Color = Color3.fromRGB(70, 50, 50) })
part({ Name = "GatePostR", Size = Vector3.new(2, 8, 2), Position = Vector3.new(9, 4, -60), Material = Enum.Material.Brick, Color = Color3.fromRGB(70, 50, 50) })
for i, c in ipairs({ Color3.fromRGB(255, 77, 94), Color3.fromRGB(61, 139, 255), Color3.fromRGB(255, 210, 63) }) do
	part({ Name = "Balloon", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Position = Vector3.new(-9 + (i - 2) * 1.6, 11 + i * 0.5, -60), Material = Enum.Material.SmoothPlastic, Color = c, CanCollide = false })
end
for z = 30, -50, -20 do
	for _, x in ipairs({ -11, 11 }) do
		part({ Name = "LampPost", Size = Vector3.new(0.6, 10, 0.6), Position = Vector3.new(x, 5, z), Material = Enum.Material.Metal, Color = Color3.fromRGB(30, 30, 34) })
		local bulb = part({ Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), Position = Vector3.new(x, 10.4, z), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 220, 150), CanCollide = false })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 210, 150), 22, 1.2
		l.Parent = bulb
	end
end
-- edges you cannot walk off
for _, w in ipairs({ { Vector3.new(200, 40, 2), Vector3.new(0, 20, 100) }, { Vector3.new(200, 40, 2), Vector3.new(0, 20, -100) }, { Vector3.new(2, 40, 200), Vector3.new(100, 20, 0) }, { Vector3.new(2, 40, 200), Vector3.new(-100, 20, 0) } }) do
	part({ Name = "Boundary", Size = w[1], Position = w[2], Transparency = 1 })
end
local spawnPad = Instance.new("SpawnLocation")
spawnPad.Anchored, spawnPad.Neutral, spawnPad.Duration = true, true, 0
spawnPad.Size = Vector3.new(10, 1, 10)
spawnPad.Position = Vector3.new(0, 0.1, 30)
spawnPad.Transparency = 1
spawnPad.CanCollide = false
spawnPad.Parent = workspace

-- ---------- parties ----------
local remotes = Instance.new("Folder")
remotes.Name = "LobbyRemotes"
remotes.Parent = ReplicatedStorage
local function remote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local CreateParty = remote("CreateParty") -- (solo: boolean)
local JoinParty = remote("JoinParty") -- (partyId)
local LeaveParty = remote("LeaveParty")
local SetOption = remote("SetOption") -- (key, value) leader only
local StartParty = remote("StartParty") -- leader only
local PartyList = remote("PartyList") -- server -> client: what this player can see
local Notice = remote("Notice") -- server -> client: a message
local BuyBoost = remote("BuyBoost") -- (boostId) with points
local SellBoost = remote("SellBoost") -- (boostId) back for its points
local ResetLadder = remote("ResetLadder") -- (skill, "points" | "robux")
local SetMusic = remote("SetMusic") -- (volume 0..1)
-- the balance table, for the experience's owner only
local GetBalance = Instance.new("RemoteFunction")
GetBalance.Name = "GetBalance"
GetBalance.Parent = remotes
local function isOwner(plr)
	if game:GetService("RunService"):IsStudio() then
		return true
	end
	return game.CreatorType == Enum.CreatorType.User and plr.UserId == game.CreatorId
end
GetBalance.OnServerInvoke = function(plr)
	if not isOwner(plr) then
		return nil
	end
	return require(ReplicatedStorage.Shared.BalanceLog).read() or {}
end
Players.PlayerAdded:Connect(function(plr)
	plr:SetAttribute("IsOwner", isOwner(plr))
end)
-- the owner sets the window faces by clicking the windows: start, add (a
-- point on the house), save, clear, test
local PeekSetup = remote("PeekSetup")
local editing, markers = nil, {}
local function clearMarkers()
	for _, mk in ipairs(markers) do
		mk:Destroy()
	end
	markers = {}
end
PeekSetup.OnServerEvent:Connect(function(plr, action, pos)
	local m = workspace:FindFirstChild("LobbyHouse")
	if not isOwner(plr) or not m then
		return
	end
	if action == "start" then
		editing = {}
		clearMarkers()
	elseif action == "add" and editing and typeof(pos) == "Vector3" then
		local cf, size = m:GetBoundingBox()
		local inBox = cf:PointToObjectSpace(pos)
		if math.abs(inBox.X) > size.X / 2 + 2 or math.abs(inBox.Y) > size.Y / 2 + 2 or math.abs(inBox.Z) > size.Z / 2 + 4 then
			return Notice:FireClient(plr, "Click on the house itself - the middle of a window.")
		end
		local rel = m:GetPivot():PointToObjectSpace(pos)
		table.insert(editing, { rel.X, rel.Y, rel.Z })
		table.insert(markers, part({ Name = "PeekMarker", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), Position = pos, Material = Enum.Material.Neon, Color = Color3.fromRGB(80, 255, 120), CanCollide = false }))
		applyPeekSpots(editing)
		Notice:FireClient(plr, "Window " .. #editing .. " set. Click the next one, or Save.")
	elseif action == "save" and editing and #editing > 0 then
		local list = editing
		local ok = pcall(function()
			LobbyStore:SetAsync("peekSpots", list)
		end)
		clearMarkers()
		editing = nil
		Notice:FireClient(plr, ok and ("Saved " .. #list .. " windows - the host will peek in those.") or "Could not save (in Studio: turn on API access). The spots work until the server closes.")
	elseif action == "clear" then
		pcall(function()
			LobbyStore:RemoveAsync("peekSpots")
		end)
		editing = {}
		clearMarkers()
		Notice:FireClient(plr, "Cleared. Click the windows again, then Save.")
	elseif action == "test" then
		for _, w in ipairs(workspace:GetChildren()) do
			if w:IsA("BasePart") and w.Name == "Window" then
				table.insert(peekTest, w)
			end
		end
		Notice:FireClient(plr, "Watch the house: the host peeks in each window in turn.")
	end
end)
for _, plr in ipairs(Players:GetPlayers()) do
	plr:SetAttribute("IsOwner", isOwner(plr))
end
local InviteToParty = remote("InviteToParty") -- (userId) a player in this Lobby
local PartyInvite = remote("PartyInvite") -- server -> client: { id, leader }
SetMusic.OnServerEvent:Connect(function(plr, v)
	Profile.setMusic(plr, v)
end)
local SetSfx = remote("SetSfx") -- (game-sound volume 0..1)
SetSfx.OnServerEvent:Connect(function(plr, v)
	Profile.setSfx(plr, v)
end)
require(ReplicatedStorage.Shared.Sfx).group()
local SetLoadout = remote("SetLoadout") -- ({boostId, ...}) up to Progress.MAX_BOOSTS
local PickUpgrade = remote("PickUpgrade") -- (skill, level, upgradeId)
local VoteMap = remote("VoteMap") -- (mapId)
local OpenShop = remote("OpenShop") -- server -> client: the shop stall was used

local parties = {}
local partyOf = {}
local nextId = 1
local friendCache = {}

local function isFriend(a, b)
	if a == b then
		return true
	end
	local key = math.min(a.UserId, b.UserId) .. ":" .. math.max(a.UserId, b.UserId)
	if friendCache[key] == nil then
		local ok, yes = pcall(function()
			return a:IsFriendsWith(b.UserId)
		end)
		friendCache[key] = ok and yes or false
	end
	return friendCache[key]
end

local chosenMap
local function snapshot(party)
	local members = {}
	for _, m in ipairs(party.members) do
		table.insert(members, { name = m.DisplayName, userId = m.UserId })
	end
	return {
		id = party.id,
		leader = party.leader.DisplayName,
		leaderId = party.leader.UserId,
		members = members,
		max = party.max,
		friendsOnly = party.friendsOnly,
		difficulty = party.difficulty,
		spook = party.spook,
		votes = party.votes,
		mapScreen = party.mapScreen == true,
		building = party.building or "partyhouse",
		chosen = chosenMap(party),
		unlocked = (Profile.get(party.leader) or { unlocked = { partyhouse = true } }).unlocked,
	}
end

-- the map the party plays: most votes among maps that are ready and the
-- leader has unlocked; a tie goes to the leader's vote
function chosenMap(party)
	local unlocked = (Profile.get(party.leader) or { unlocked = { partyhouse = true } }).unlocked
	local tally, best, bestN = {}, "partyhouse", 0
	for userId, mapId in pairs(party.votes) do
		local i = Progress.mapIndex(mapId)
		if i and Progress.MAPS[i].ready and unlocked[mapId] then
			tally[mapId] = (tally[mapId] or 0) + 1
		end
	end
	local leaderVote = party.votes[tostring(party.leader.UserId)]
	for mapId, n in pairs(tally) do
		if n > bestN or (n == bestN and mapId == leaderVote) then
			best, bestN = mapId, n
		end
	end
	return best
end

-- ---------- party circles: each party gets a glowing circle on the lawn with
-- its players standing round it and a sign: "2 / 6 - waiting for players" ----------
local PAD_SPOTS = { Vector3.new(24, 0, 46), Vector3.new(-26, 0, 46), Vector3.new(24, 0, 64), Vector3.new(-26, 0, 64), Vector3.new(24, 0, 82), Vector3.new(-26, 0, 82) }
local padsFolder = Instance.new("Folder")
padsFolder.Name = "PartyCircles"
padsFolder.Parent = workspace
local joinPartyFn -- set below (the JoinParty handler)
local padOf = {} -- [pad index] = party
local function padFor(party)
	for i, p in pairs(padOf) do
		if p == party then
			return i
		end
	end
	for i = 1, #PAD_SPOTS do
		if not padOf[i] then
			padOf[i] = party
			return i
		end
	end
	return nil
end
local function standOnPad(party, plr)
	if party.max <= 1 then
		return -- solo games have no circle
	end
	local i = padFor(party)
	local char = plr.Character
	if not i or not char then
		return
	end
	local k = table.find(party.members, plr) or 1
	local a = (k - 1) / 6 * math.pi * 2
	local centre = PAD_SPOTS[i]
	local spot = centre + Vector3.new(math.cos(a) * 4.5, 3, math.sin(a) * 4.5)
	char:PivotTo(CFrame.lookAt(spot, Vector3.new(centre.X, spot.Y, centre.Z)))
end
local function paintPads()
	for i, party in pairs(padOf) do
		if not parties[party.id] then
			padOf[i] = nil
		end
	end
	for _, party in pairs(parties) do
		if party.max > 1 then
			padFor(party)
		end
	end
	padsFolder:ClearAllChildren()
	for i, party in pairs(padOf) do
		local c = PAD_SPOTS[i]
		local full = #party.members >= party.max
		local colour = party.starting and Color3.fromRGB(123, 227, 107) or full and Color3.fromRGB(255, 210, 63) or Color3.fromRGB(255, 138, 31)
		local disc = Instance.new("Part")
		disc.Name = "PartyCircle"
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = Vector3.new(0.3, 12, 12)
		disc.CFrame = CFrame.new(c + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		disc.Material = Enum.Material.Neon
		disc.Color = colour
		disc.Transparency = 0.45
		disc.Anchored, disc.CanCollide = true, false
		disc.Parent = padsFolder
		local sign = Instance.new("BillboardGui")
		sign.Size = UDim2.fromOffset(330, 80)
		sign.StudsOffset = Vector3.new(0, 8, 0)
		sign.AlwaysOnTop = false
		sign.MaxDistance = 120
		sign.Parent = disc
		-- the leader's avatar headshot beside the words
		local face = Instance.new("ImageLabel")
		face.Size = UDim2.fromOffset(80, 80)
		face.BackgroundColor3 = Color3.fromRGB(75, 58, 102)
		face.Image = "rbxthumb://type=AvatarHeadShot&id=" .. party.leader.UserId .. "&w=150&h=150"
		face.Parent = sign
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(0.5, 0)
		fc.Parent = face
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -86, 1, 0)
		t.Position = UDim2.fromOffset(86, 0)
		t.BackgroundTransparency = 0.3
		t.BackgroundColor3 = Color3.fromRGB(26, 16, 38)
		t.TextColor3 = Color3.fromRGB(255, 244, 224)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		local left = math.max(0, math.floor(Config.PARTY_HOLD - (os.clock() - (party.created or os.clock()))))
		local status = party.starting and "Starting!" or (full and "Full - ready to start" or "Waiting for players") .. string.format(" (closes in %d:%02d)", math.floor(left / 60), left % 60)
		t.Text = party.leader.DisplayName .. "'s party\n" .. #party.members .. " / " .. party.max .. "  \u{00B7}  " .. status .. (party.friendsOnly and "\n(friends only)" or "")
		t.Parent = sign
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = t
		if not full and not party.starting then
			-- walk onto the circle to join (the same rules as the Join button)
			local tried = {}
			disc.CanTouch = true
			disc.Touched:Connect(function(hit)
				local plr = Players:GetPlayerFromCharacter(hit.Parent)
				if plr and partyOf[plr] ~= party and joinPartyFn and (tried[plr] or 0) < os.clock() then
					tried[plr] = os.clock() + 3
					joinPartyFn(plr, party.id)
				end
			end)
			local pp = Instance.new("ProximityPrompt")
			pp.ActionText = "Join party"
			pp.ObjectText = party.leader.DisplayName .. "'s party"
			pp.RequiresLineOfSight = false
			pp.MaxActivationDistance = 10
			pp.Parent = disc
			pp.Triggered:Connect(function(plr)
				if joinPartyFn and partyOf[plr] ~= party then
					joinPartyFn(plr, party.id)
				end
			end)
		end
	end
end

local broadcast
-- parties wait at most PARTY_HOLD seconds to start, then close
task.spawn(function()
	while true do
		task.wait(5)
		local changed = false
		for id, party in pairs(parties) do
			if not party.starting and party.max > 1 and os.clock() - (party.created or os.clock()) > Config.PARTY_HOLD then
				for _, m in ipairs(party.members) do
					partyOf[m] = nil
					Notice:FireClient(m, "Your party closed after " .. math.floor(Config.PARTY_HOLD / 60) .. " minutes without starting. Make a new one when you're ready!")
				end
				parties[id] = nil
				changed = true
			end
		end
		if changed and broadcast then
			broadcast()
		elseif next(parties) then
			paintPads() -- the countdown on the signs
		end
	end
end)

function broadcast()
	for _, plr in ipairs(Players:GetPlayers()) do
		local list = {}
		for _, party in pairs(parties) do
			if partyOf[plr] == party or not party.friendsOnly or isFriend(plr, party.leader) then
				table.insert(list, snapshot(party))
			end
		end
		PartyList:FireClient(plr, list, partyOf[plr] and partyOf[plr].id or nil)
	end
	paintPads()
end

local function leave(plr)
	local party = partyOf[plr]
	if not party then
		return
	end
	partyOf[plr] = nil
	local i = table.find(party.members, plr)
	if i then
		table.remove(party.members, i)
	end
	if #party.members == 0 then
		parties[party.id] = nil
	elseif party.leader == plr then
		party.leader = party.members[1]
		Notice:FireClient(party.leader, "You are now the party leader.")
	end
end

local function start(party)
	if party.starting then
		return
	end
	local placeId = Places.game()
	if not placeId then
		for _, m in ipairs(party.members) do
			Notice:FireClient(m, "Starting a party only works in the published game. In Studio, open the Party House place and press Play to test it.")
		end
		return
	end
	party.starting = true
	local mapId = chosenMap(party)
	local mapName = Progress.MAPS[Progress.mapIndex(mapId)].name
	for _, m in ipairs(party.members) do
		Notice:FireClient(m, "Off to " .. mapName .. "...")
		-- the boosts each player chose leave their bag now and wait for them in the game
		local data = Profile.get(m)
		if data then
			local kept = {}
			for _, id in ipairs(data.loadout or {}) do
				if (data.inv[id] or 0) > 0 then
					data.inv[id] -= 1
					table.insert(kept, id)
				end
			end
			data.loadout = kept
			Profile.save(m)
			Profile.publish(m)
		end
	end
	local ok, err = pcall(function()
		local code = TeleportService:ReserveServer(placeId)
		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = code
		options:SetTeleportData({ difficulty = party.difficulty, spook = party.spook, map = mapId, leader = party.leader.UserId, code = code })
		TeleportService:TeleportAsync(placeId, party.members, options)
	end)
	if not ok then
		party.starting = false
		for _, m in ipairs(party.members) do
			Notice:FireClient(m, "Couldn't start the game: " .. tostring(err))
		end
	end
end

CreateParty.OnServerEvent:Connect(function(plr, solo)
	leave(plr)
	local party = {
		id = nextId,
		leader = plr,
		members = { plr },
		max = solo and 1 or Config.MAX_PARTY,
		created = os.clock(),
		friendsOnly = true,
		difficulty = "normal",
		spook = "giggly",
		votes = {},
	}
	nextId += 1
	parties[party.id] = party
	partyOf[plr] = party
	broadcast()
	standOnPad(party, plr)
end)

local function joinParty(plr, id)
	local party = parties[id]
	if not party or party.starting then
		return Notice:FireClient(plr, "That party has already gone.")
	end
	if #party.members >= party.max then
		return Notice:FireClient(plr, "That party is full.")
	end
	if party.friendsOnly and not isFriend(plr, party.leader) and not (party.invited and party.invited[plr.UserId]) then
		return Notice:FireClient(plr, "That party is friends only.")
	end
	leave(plr)
	table.insert(party.members, plr)
	partyOf[plr] = party
	for _, m in ipairs(party.members) do
		Notice:FireClient(m, plr.DisplayName .. " joined the party!")
	end
	broadcast()
	standOnPad(party, plr)
end
joinPartyFn = joinParty
JoinParty.OnServerEvent:Connect(joinParty)

-- invite someone in this Lobby: a pop-up on their screen; accepting lets them
-- into a friends-only party too
InviteToParty.OnServerEvent:Connect(function(plr, userId)
	local party = partyOf[plr]
	local target = typeof(userId) == "number" and Players:GetPlayerByUserId(userId)
	if not party or not target or target == plr or partyOf[target] == party then
		return
	end
	party.invited = party.invited or {}
	party.invited[target.UserId] = true
	PartyInvite:FireClient(target, { id = party.id, leader = party.leader.DisplayName, from = plr.DisplayName })
	Notice:FireClient(plr, "Invite sent to " .. target.DisplayName .. "!")
end)

LeaveParty.OnServerEvent:Connect(function(plr)
	leave(plr)
	broadcast()
end)

SetOption.OnServerEvent:Connect(function(plr, key, value)
	local party = partyOf[plr]
	if not party or party.leader ~= plr or party.starting then
		return
	end
	if key == "max" and typeof(value) == "number" and value % 1 == 0 then
		party.max = math.clamp(value, math.max(1, #party.members), Config.MAX_PARTY)
	elseif key == "friendsOnly" and typeof(value) == "boolean" then
		party.friendsOnly = value
	elseif key == "difficulty" and Config.DIFFICULTY[value] then
		party.difficulty = value
	elseif key == "spook" and (value == "giggly" or value == "spooky") then
		party.spook = value
	elseif key == "mapScreen" and typeof(value) == "boolean" then
		-- the leader opens the map screen for the whole party (and closes it)
		party.mapScreen = value
	elseif key == "building" and typeof(value) == "string" then
		for _, b in ipairs(Progress.BUILDINGS) do
			if b.id == value then
				party.building = value
			end
		end
	end
	broadcast()
end)

-- Quick Play: join an open party with room, or straight into a solo game
-- on the next floor this player has not escaped yet
local QuickPlay = remote("QuickPlay")
QuickPlay.OnServerEvent:Connect(function(plr)
	local mine = partyOf[plr]
	if mine and mine.starting then
		return
	end
	for id, party in pairs(parties) do
		if party ~= mine and not party.starting and not party.friendsOnly and #party.members < party.max then
			return joinParty(plr, id)
		end
	end
	local data = Profile.get(plr)
	local pick = "partyhouse"
	if data then
		for _, m in ipairs(Progress.MAPS) do
			if m.ready and data.unlocked and data.unlocked[m.id] and not (data.cleared and data.cleared[m.id]) then
				pick = m.id
				break
			end
		end
	end
	leave(plr)
	local party = {
		id = nextId,
		leader = plr,
		members = { plr },
		max = 1,
		created = os.clock(),
		friendsOnly = true,
		difficulty = "normal",
		spook = "giggly",
		votes = { [tostring(plr.UserId)] = pick },
	}
	nextId += 1
	parties[party.id] = party
	partyOf[plr] = party
	broadcast()
	local i = Progress.mapIndex(pick)
	Notice:FireClient(plr, "\u{26A1} Quick Play: " .. (i and Progress.MAPS[i].name or pick) .. "!")
	start(party)
end)

StartParty.OnServerEvent:Connect(function(plr)
	local party = partyOf[plr]
	if party and party.leader == plr then
		start(party)
	end
end)

VoteMap.OnServerEvent:Connect(function(plr, mapId)
	local party = partyOf[plr]
	local i = typeof(mapId) == "string" and Progress.mapIndex(mapId)
	if not party or not i or party.starting then
		return
	end
	if not Progress.MAPS[i].ready then
		return Notice:FireClient(plr, Progress.MAPS[i].name .. " is coming soon!")
	end
	local unlocked = (Profile.get(party.leader) or { unlocked = {} }).unlocked
	if not unlocked[mapId] then
		return Notice:FireClient(plr, "Your leader hasn't unlocked " .. Progress.MAPS[i].name .. " yet - escape the map before it first.")
	end
	party.votes[tostring(plr.UserId)] = mapId
	broadcast()
end)

-- ---------- the shop ----------
BuyBoost.OnServerEvent:Connect(function(plr, id)
	local boost = typeof(id) == "string" and Progress.BOOSTS[id]
	local data = Profile.get(plr)
	if not boost or not data then
		return
	end
	if data.points < boost.price then
		return Notice:FireClient(plr, "You need " .. boost.price .. " points for " .. boost.name .. ".")
	end
	data.points -= boost.price
	data.paid = data.paid or table.clone(data.inv) -- older profiles: all bought with points
	data.paid[id] = (data.paid[id] or 0) + 1
	data.inv[id] = (data.inv[id] or 0) + 1
	Profile.publish(plr)
	Profile.save(plr)
	Notice:FireClient(plr, boost.icon .. " You bought " .. boost.name .. "!")
end)

-- the - button: a boost bought with points goes back for its full price
SellBoost.OnServerEvent:Connect(function(plr, id)
	local boost = typeof(id) == "string" and Progress.BOOSTS[id]
	local data = Profile.get(plr)
	if not boost or not data then
		return
	end
	data.paid = data.paid or table.clone(data.inv)
	local taking = 0
	for _, x in ipairs(data.loadout or {}) do
		if x == id then
			taking += 1
		end
	end
	if (data.inv[id] or 0) - taking <= 0 then
		return Notice:FireClient(plr, "Tap \u{2705} Taking first to put " .. boost.name .. " back.")
	end
	if (data.paid[id] or 0) <= 0 then
		return Notice:FireClient(plr, "That " .. boost.name .. " was bought with Robux, so it can't be sold for points.")
	end
	data.inv[id] -= 1
	data.paid[id] -= 1
	data.points += boost.price
	Profile.publish(plr)
	Profile.save(plr)
	Notice:FireClient(plr, "Sold back " .. boost.name .. ": +" .. boost.price .. " points.")
end)

SetLoadout.OnServerEvent:Connect(function(plr, list)
	local data = Profile.get(plr)
	if not data or typeof(list) ~= "table" then
		return
	end
	local kept, count = {}, {}
	for _, id in ipairs(list) do
		if typeof(id) == "string" and Progress.BOOSTS[id] and #kept < Progress.MAX_BOOSTS then
			count[id] = (count[id] or 0) + 1
			if count[id] <= (data.inv[id] or 0) then
				table.insert(kept, id)
			end
		end
	end
	data.loadout = kept
	Profile.publish(plr)
end)

-- Robux: each Developer Product grants one boost
local productToBoost = {}
for id, productId in pairs(Config.ROBUX_PRODUCTS) do
	if productId and productId > 0 and Progress.BOOSTS[id] then
		productToBoost[productId] = id
	end
end
local function resetLadder(data, skill)
	data.picks[skill] = {}
end
MarketplaceService.ProcessReceipt = function(info)
	local plr = Players:GetPlayerByUserId(info.PlayerId)
	-- the skill-ladder reset, for the character chosen before buying
	if (Config.ROBUX_PRODUCTS.reset or 0) > 0 and info.ProductId == Config.ROBUX_PRODUCTS.reset then
		local d = plr and Profile.get(plr)
		if not d then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		d.receipts = d.receipts or {}
		if not d.receipts[info.PurchaseId] and d.pendingReset then
			d.receipts[info.PurchaseId] = true
			resetLadder(d, d.pendingReset)
		end
		if not Profile.save(plr) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		Profile.publish(plr)
		Notice:FireClient(plr, "Upgrades reset - choose again!")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local id = productToBoost[info.ProductId]
	local data = plr and Profile.get(plr)
	if not id or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.receipts = data.receipts or {}
	if not data.receipts[info.PurchaseId] then
		data.receipts[info.PurchaseId] = true
		data.inv[id] = (data.inv[id] or 0) + 1
	end
	if not Profile.save(plr) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Profile.publish(plr)
	Notice:FireClient(plr, Progress.BOOSTS[id].icon .. " " .. Progress.BOOSTS[id].name .. " added to your bag!")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ---------- the skill ladder ----------
-- reset one character's upgrades: with points now, or Robux (the product
-- prompt opens on the player's screen; ProcessReceipt finishes it)
ResetLadder.OnServerEvent:Connect(function(plr, skill, how)
	local data = Profile.get(plr)
	if not data or typeof(skill) ~= "string" or not Progress.choices(skill, 3) then
		return
	end
	if not data.picks[skill] or next(data.picks[skill]) == nil then
		return Notice:FireClient(plr, "Nothing to reset yet.")
	end
	if how == "robux" then
		data.pendingReset = skill
		return
	end
	if data.points < Config.RESET_POINTS then
		return Notice:FireClient(plr, "A reset costs " .. Config.RESET_POINTS .. " points.")
	end
	data.points -= Config.RESET_POINTS
	resetLadder(data, skill)
	Profile.publish(plr)
	Profile.save(plr)
	Notice:FireClient(plr, "Upgrades reset - choose again!")
end)
PickUpgrade.OnServerEvent:Connect(function(plr, skill, level, upgradeId)
	local data = Profile.get(plr)
	if not data or typeof(skill) ~= "string" or typeof(level) ~= "number" or typeof(upgradeId) ~= "string" then
		return
	end
	local options = Progress.choices(skill, level)
	if not options or Progress.level(data.xp[skill] or 0) < level then
		return Notice:FireClient(plr, "Play more as this character to reach level " .. tostring(level) .. ".")
	end
	-- a choice is for keeps: changing needs a reset of the whole ladder
	local chosen = data.picks[skill] and data.picks[skill][tostring(level)]
	local stillOffered = false
	for _, opt in ipairs(options) do
		if opt.id == chosen then
			stillOffered = true
		end
	end
	if chosen and stillOffered then
		return Notice:FireClient(plr, chosen == upgradeId and "Already chosen!" or ("Locked in! Reset this character's upgrades for " .. Config.RESET_POINTS .. " points (or Robux) to choose again."))
	end
	for _, opt in ipairs(options) do
		if opt.id == upgradeId then
			data.picks[skill] = data.picks[skill] or {}
			data.picks[skill][tostring(level)] = upgradeId
			Profile.publish(plr)
			Profile.save(plr)
			return Notice:FireClient(plr, "Upgrade chosen: " .. opt.name)
		end
	end
end)

-- ---------- the scene: shop stall, leaderboard wall, cars and benches ----------
local Scene = require(script.Parent.LobbyScene)
local stallPrompt = Scene.stall(Vector3.new(-30, 0, 10))
stallPrompt.Triggered:Connect(function(plr)
	OpenShop:FireClient(plr)
end)
Scene.dropOff()
Scene.fun()
Scene.perimeter()
Scene.halloween()
local boards = Scene.boards({ "\u{1F3C6} Most points earned", "\u{1F6AA} Most escapes", "\u{1F3E2} Most floors escaped", "\u{1F512} Most rescues", "\u{23F1} Fastest escapes this week" })
local boardPoints, boardEscapes, boardFloors, boardRescue, boardFast = boards[1], boards[2], boards[3], boards[4], boards[5]
-- each row: the player's avatar in a circle, then rank, name and score
local function fill(body, rows, fmt, rowH)
	rowH = rowH or 38
	for _, c in ipairs(body:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	if #rows == 0 then
		body.Text = "No scores yet - be the first!"
		return
	end
	body.Text = ""
	for i, r in ipairs(rows) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, rowH - 4)
		row.Position = UDim2.fromOffset(0, (i - 1) * rowH)
		row.BackgroundTransparency = 1
		row.Parent = body
		local face = Instance.new("ImageLabel")
		face.Size = UDim2.fromOffset(34, 34)
		face.BackgroundColor3 = Color3.fromRGB(75, 58, 102)
		face.Image = r.userId and ("rbxthumb://type=AvatarHeadShot&id=" .. r.userId .. "&w=48&h=48") or ""
		face.Parent = row
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(0.5, 0)
		fc.Parent = face
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -42, 1, 0)
		t.Position = UDim2.fromOffset(42, 0)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextColor3 = Color3.fromRGB(255, 244, 224)
		t.Text = i .. ". " .. r.name .. "  " .. fmt(r.value, r)
		t.Parent = row
	end
end
local function mapName(id)
	local i = Progress.mapIndex(id)
	return i and Progress.MAPS[i].name or "?"
end
task.spawn(function()
	while true do
		local names = Profile.boardNames()
		fill(boardPoints, Profile.top(names.points, 10), function(v)
			return tostring(v)
		end)
		fill(boardEscapes, Profile.top(names.escapes, 10), function(v)
			return tostring(v)
		end)
		fill(boardFloors, Profile.top(names.floors, 10), function(v)
			return tostring(v)
		end)
		-- two lines a row: the time, then where it was set
		fill(boardFast, Profile.top(names.fastest, 6, true), function(v, r)
			local d = Config.DIFFICULTY[r.difficulty]
			return string.format("%d:%02d", math.floor(v / 60), v % 60) .. "\n" .. mapName(r.map) .. (d and (" \u{00B7} " .. d.name) or "")
		end, 62)
		fill(boardRescue, Profile.top(names.rescues, 10), function(v)
			return tostring(v)
		end)
		task.wait(60)
	end
end)

-- ---------- daily quests (shared/Quests.luau; the game counts them) ----------
Quests = require(ReplicatedStorage.Shared.Quests)

-- ---------- rejoining a game after a dropped connection ----------
-- The game server writes EC_Rejoin["u<userId>"] when a player drops out
-- mid-game, and keeps EC_Live[<its job id>] fresh while it runs.
local MemoryStoreService = game:GetService("MemoryStoreService")
local rejoinMap, liveMap
pcall(function()
	rejoinMap = MemoryStoreService:GetHashMap("EC_Rejoin")
	liveMap = MemoryStoreService:GetHashMap("EC_Live")
end)
local RejoinOffer = remote("RejoinOffer") -- server -> client: { map = name }
local Rejoin = remote("Rejoin") -- client -> server: true (rejoin) | false (no thanks)
local function rejoinInfo(plr)
	if not rejoinMap or not liveMap then
		return nil
	end
	local ok, info = pcall(function()
		return rejoinMap:GetAsync("u" .. plr.UserId)
	end)
	if not ok or type(info) ~= "table" or typeof(info.code) ~= "string" then
		return nil
	end
	if os.time() - (info.t or 0) > Config.REJOIN_SECONDS then
		return nil
	end
	local okLive, alive = pcall(function()
		return liveMap:GetAsync(info.job)
	end)
	if not okLive or not alive then
		return nil
	end
	return info
end
function offerRejoin(plr)
	local info = rejoinInfo(plr)
	if info and plr.Parent then
		local i = Progress.mapIndex(info.map or "")
		RejoinOffer:FireClient(plr, { map = i and Progress.MAPS[i].name or "your game" })
	end
end
Rejoin.OnServerEvent:Connect(function(plr, yes)
	local info = rejoinInfo(plr)
	if not info then
		return Notice:FireClient(plr, "That game has finished - start a new one!")
	end
	if yes ~= true then
		pcall(function()
			rejoinMap:RemoveAsync("u" .. plr.UserId)
		end)
		return
	end
	local placeId = Places.game()
	if not placeId then
		return Notice:FireClient(plr, "Rejoining only works in the published game.")
	end
	leave(plr)
	broadcast()
	Notice:FireClient(plr, "Back to your game...")
	local ok, err = pcall(function()
		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = info.code
		options:SetTeleportData({ rejoin = true, map = info.map, code = info.code })
		TeleportService:TeleportAsync(placeId, { plr }, options)
	end)
	if not ok then
		Notice:FireClient(plr, "Couldn't get back into that game: " .. tostring(err))
	end
end)

-- ---------- "your daily reward is ready" (Roblox experience notifications) ----------
-- Claiming the daily reward puts a reminder in a queue (EC_Remind, sorted by
-- when it is due). Any Lobby server sends the reminders that are due, through
-- Open Cloud with the API key kept in the experience's Secrets. Only players
-- 13 and over who said yes to notifications get them (Roblox's rule), at most
-- one a day.
local remindQueue
pcall(function()
	remindQueue = MemoryStoreService:GetSortedMap("EC_Remind")
end)
function queueReminder(plr)
	if not remindQueue or (Config.NOTIFY.messageId or "") == "" then
		return
	end
	local due = os.time() + math.floor((Config.NOTIFY.hours or 22) * 3600)
	task.spawn(pcall, function()
		remindQueue:SetAsync(tostring(plr.UserId), due, 3 * 86400, due)
	end)
end
local function sendReminder(userId)
	local HttpService = game:GetService("HttpService")
	local ok, err = pcall(function()
		local key = HttpService:GetSecret(Config.NOTIFY.secret)
		local body = HttpService:JSONEncode({
			source = { universe = "universes/" .. game.GameId },
			payload = { message_id = Config.NOTIFY.messageId, type = "MOMENT" },
		})
		local res = HttpService:RequestAsync({
			Url = "https://apis.roblox.com/cloud/v2/users/" .. userId .. "/notifications",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = key },
			Body = body,
		})
		if not res.Success then
			error(res.StatusCode .. " " .. tostring(res.Body))
		end
	end)
	if not ok then
		warn("Daily reminder to " .. userId .. " not sent: " .. tostring(err))
	end
end
task.spawn(function()
	if game:GetService("RunService"):IsStudio() then
		return -- secrets only work in live servers
	end
	while true do
		task.wait(120 + math.random(0, 60))
		if remindQueue and (Config.NOTIFY.messageId or "") ~= "" then
			local ok, due = pcall(function()
				return remindQueue:GetRangeAsync(Enum.SortDirection.Ascending, 20, nil, { sortKey = os.time() })
			end)
			for _, entry in ipairs(ok and due or {}) do
				-- take it off the queue first (another Lobby may be looking too)
				local took = false
				pcall(function()
					remindQueue:UpdateAsync(entry.key, function(old)
						took = old ~= nil
						return nil
					end, 1)
				end)
				pcall(function()
					remindQueue:RemoveAsync(entry.key)
				end)
				if took and not Players:GetPlayerByUserId(tonumber(entry.key) or 0) then
					sendReminder(entry.key)
				end
			end
		end
	end
end)

-- ---------- character skins (Game Passes; shown in Characters) ----------
local EquipSkin = remote("EquipSkin") -- (skill, skinId or "") wear a skin, or the plain character
local OwnedSkins = Instance.new("RemoteFunction")
OwnedSkins.Name = "OwnedSkins"
OwnedSkins.Parent = remotes
local skinOwned = {} -- ["userId:passId"] = true
local function ownsSkin(plr, skin)
	if game:GetService("RunService"):IsStudio() and Config.SKINS_FREE_IN_STUDIO then
		return true
	end
	if not skin.pass or skin.pass <= 0 then
		return false
	end
	local key = plr.UserId .. ":" .. skin.pass
	if skinOwned[key] == nil then
		local ok, yes = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, skin.pass)
		end)
		if not ok then
			return false
		end
		skinOwned[key] = yes == true
	end
	return skinOwned[key]
end
OwnedSkins.OnServerInvoke = function(plr)
	local out = {}
	for _, skin in ipairs(Config.SKINS or {}) do
		out[skin.id] = ownsSkin(plr, skin)
	end
	return out
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, bought)
	if bought then
		skinOwned[plr.UserId .. ":" .. passId] = true
		for _, skin in ipairs(Config.SKINS or {}) do
			if skin.pass == passId then
				local data = Profile.get(plr)
				if data then
					data.skins = data.skins or {}
					data.skins[skin.skill] = skin.id
					Profile.publish(plr)
					Profile.save(plr)
				end
				Notice:FireClient(plr, "\u{2728} " .. skin.name .. " is yours - wear it in your next game!")
			end
		end
	end
end)
EquipSkin.OnServerEvent:Connect(function(plr, skill, skinId)
	local data = Profile.get(plr)
	if not data or typeof(skill) ~= "string" or typeof(skinId) ~= "string" then
		return
	end
	data.skins = data.skins or {}
	if skinId == "" then
		data.skins[skill] = nil
		Profile.publish(plr)
		return
	end
	for _, skin in ipairs(Config.SKINS or {}) do
		if skin.id == skinId and skin.skill == skill then
			if not ownsSkin(plr, skin) then
				return Notice:FireClient(plr, "Get " .. skin.name .. " first!")
			end
			data.skins[skill] = skin.id
			Profile.publish(plr)
			Profile.save(plr)
			return Notice:FireClient(plr, "\u{2728} Wearing " .. skin.name .. " next game!")
		end
	end
end)

-- daily login reward: claimed on arrival once a day; an unbroken run of days
-- climbs the 7-day ladder, a missed day starts it again at day 1
local function dailyReward(plr, data)
	if not data then
		return
	end
	local today = math.floor(os.time() / 86400)
	data.daily = data.daily or { last = 0, streak = 0 }
	if data.daily.last == today then
		return
	end
	data.daily.streak = (data.daily.last == today - 1) and (data.daily.streak + 1) or 1
	data.daily.last = today
	local day = (data.daily.streak - 1) % #Config.DAILY + 1
	local r = Config.DAILY[day]
	local premium = plr.MembershipType == Enum.MembershipType.Premium
	local pts = r.points * (premium and Config.PREMIUM_DAILY_MULT or 1)
	data.points += pts
	if r.boost then
		data.inv[r.boost] = (data.inv[r.boost] or 0) + 1
	end
	Profile.publish(plr)
	Profile.save(plr)
	queueReminder(plr)
	plr:SetAttribute("DailyShow", game:GetService("HttpService"):JSONEncode({ streak = data.daily.streak, day = day, points = pts, boost = r.boost, premium = premium }))
end

Players.PlayerAdded:Connect(function(plr)
	local data = Profile.load(plr)
	dailyReward(plr, data)
	if data then
		Quests.ensure(data, plr.UserId)
		Profile.publish(plr)
	end
	task.spawn(offerRejoin, plr)
	task.wait(1)
	broadcast()
end)
Players.PlayerRemoving:Connect(function(plr)
	leave(plr)
	Profile.release(plr)
	broadcast()
end)
game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		Profile.save(plr)
	end
end)
