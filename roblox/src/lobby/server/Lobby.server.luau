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
-- a silhouette at the top window
part({ Name = "Watcher", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), Position = Vector3.new(20, 27, -89.4), Material = Enum.Material.Neon, Color = Color3.fromRGB(230, 110, 20) })
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
		unlocked = (Profile.get(party.leader) or { unlocked = { partyhouse = true } }).unlocked,
	}
end

-- the map the party plays: most votes among maps that are ready and the
-- leader has unlocked; a tie goes to the leader's vote
local function chosenMap(party)
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

local function broadcast()
	for _, plr in ipairs(Players:GetPlayers()) do
		local list = {}
		for _, party in pairs(parties) do
			if partyOf[plr] == party or not party.friendsOnly or isFriend(plr, party.leader) then
				table.insert(list, snapshot(party))
			end
		end
		PartyList:FireClient(plr, list, partyOf[plr] and partyOf[plr].id or nil)
	end
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
		options:SetTeleportData({ difficulty = party.difficulty, spook = party.spook, map = mapId })
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
		friendsOnly = true,
		difficulty = "normal",
		spook = "giggly",
		votes = {},
	}
	nextId += 1
	parties[party.id] = party
	partyOf[plr] = party
	broadcast()
	if solo then
		start(party)
	end
end)

JoinParty.OnServerEvent:Connect(function(plr, id)
	local party = parties[id]
	if not party or party.starting then
		return Notice:FireClient(plr, "That party has already gone.")
	end
	if #party.members >= party.max then
		return Notice:FireClient(plr, "That party is full.")
	end
	if party.friendsOnly and not isFriend(plr, party.leader) then
		return Notice:FireClient(plr, "That party is friends only.")
	end
	leave(plr)
	table.insert(party.members, plr)
	partyOf[plr] = party
	for _, m in ipairs(party.members) do
		Notice:FireClient(m, plr.DisplayName .. " joined the party!")
	end
	broadcast()
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
	end
	broadcast()
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
	if productId and productId > 0 then
		productToBoost[productId] = id
	end
end
MarketplaceService.ProcessReceipt = function(info)
	local plr = Players:GetPlayerByUserId(info.PlayerId)
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
PickUpgrade.OnServerEvent:Connect(function(plr, skill, level, upgradeId)
	local data = Profile.get(plr)
	if not data or typeof(skill) ~= "string" or typeof(level) ~= "number" or typeof(upgradeId) ~= "string" then
		return
	end
	local options = Progress.choices(skill, level)
	if not options or Progress.level(data.xp[skill] or 0) < level then
		return Notice:FireClient(plr, "Play more as this character to reach level " .. tostring(level) .. ".")
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
local boards = Scene.boards({ "\u{1F3C6} Most points earned", "\u{1F6AA} Most escapes", "\u{1F512} Most rescues", "\u{23F1} Fastest escapes this week" })
local boardPoints, boardEscapes, boardRescue, boardFast = boards[1], boards[2], boards[3], boards[4]
local function fill(body, rows, fmt)
	if #rows == 0 then
		body.Text = "No scores yet - be the first!"
		return
	end
	local lines = {}
	for i, r in ipairs(rows) do
		table.insert(lines, i .. ". " .. r.name .. "  " .. fmt(r.value, r))
	end
	body.Text = table.concat(lines, "\n")
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
		-- two lines a row: the time, then where it was set
		fill(boardFast, Profile.top(names.fastest, 6, true), function(v, r)
			local d = Config.DIFFICULTY[r.difficulty]
			return string.format("%d:%02d", math.floor(v / 60), v % 60) .. "\n     " .. mapName(r.map) .. (d and (" \u{00B7} " .. d.name) or "")
		end)
		fill(boardRescue, Profile.top(names.rescues, 10), function(v)
			return tostring(v)
		end)
		task.wait(60)
	end
end)

Players.PlayerAdded:Connect(function(plr)
	Profile.load(plr)
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
