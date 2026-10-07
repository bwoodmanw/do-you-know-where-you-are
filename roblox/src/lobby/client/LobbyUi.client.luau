--[[
	LobbyUi - the lobby screen: Play solo, Create party, parties you can join,
	and your party (players 1-6, friends only, difficulty, Giggly/Spooky,
	Invite friends, Start, Leave).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Config = require(ReplicatedStorage.Shared.Config)
local Progress = require(ReplicatedStorage.Shared.Progress)
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local remotes = ReplicatedStorage:WaitForChild("LobbyRemotes")
local player = Players.LocalPlayer

local NIGHT = Color3.fromRGB(26, 16, 38)
local PUMP = Color3.fromRGB(255, 138, 31)
local CREAM = Color3.fromRGB(255, 244, 224)
local PLUM = Color3.fromRGB(75, 58, 102)

local gui = Instance.new("ScreenGui")
gui.Name = "Lobby"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = o
end
local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = NIGHT
	f.BackgroundTransparency = 0.12
	for k, v in pairs(props) do
		f[k] = v
	end
	f.Parent = parent
	return f
end
local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = CREAM
	l.TextScaled = true
	for k, v in pairs(props) do
		l[k] = v
	end
	l.Parent = parent
	return l
end
local function button(parent, text, props, onClick)
	local b = Instance.new("TextButton")
	b.Font = Enum.Font.FredokaOne
	b.Text = text
	b.TextScaled = true
	b.TextColor3 = CREAM
	b.BackgroundColor3 = PLUM
	for k, v in pairs(props) do
		b[k] = v
	end
	corner(b, 12)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 5), UDim.new(0, 5)
	pad.Parent = b
	b.Parent = parent
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end
local function list(parent, padding)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, padding or 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.Parent = parent
	return l
end

-- ---------- messages ----------
local note = frame(gui, { Size = UDim2.new(0.5, 0, 0, 50), Position = UDim2.new(0.25, 0, 0, 70), Visible = false, ZIndex = 80 })
corner(note, 14)
local noteText = label(note, { Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5), ZIndex = 81 })
local noteToken = 0
local function notice(text)
	noteToken += 1
	local my = noteToken
	noteText.Text = text
	note.Visible = true
	task.delay(4, function()
		if noteToken == my then
			note.Visible = false
		end
	end)
end
remotes.Notice.OnClientEvent:Connect(notice)

-- Roblox's own invite, to everyone or to one friend (friends land in this Lobby)
local function robloxInvite(userId)
	local ok, can = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)
	if ok and can then
		pcall(function()
			local options = Instance.new("ExperienceInviteOptions")
			if userId then
				options.InviteUser = userId
			end
			SocialService:PromptGameInvite(player, options)
		end)
	else
		notice("Invites aren't available here (they work in the published game).")
	end
end

-- the invite list: players in this Lobby (straight into your party) and
-- friends online elsewhere (a Roblox invite to come here)
local inviteBox -- built on first use
local inParty = false
local function invite()
	if inviteBox then
		inviteBox:Destroy()
	end
	inviteBox = Instance.new("Frame")
	inviteBox.Size = UDim2.fromOffset(420, 460)
	inviteBox.AnchorPoint = Vector2.new(0.5, 0.5)
	inviteBox.Position = UDim2.fromScale(0.5, 0.5)
	inviteBox.BackgroundColor3 = Color3.fromRGB(26, 16, 38)
	inviteBox.ZIndex = 30
	inviteBox.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 16)
	c.Parent = inviteBox
	local function text(t, y, colour)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -40, 0, 26)
		l.Position = UDim2.fromOffset(20, y)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = colour or Color3.fromRGB(255, 244, 224)
		l.Text = t
		l.ZIndex = 31
		l.Parent = inviteBox
	end
	text("\u{2709} Invite friends", 14, Color3.fromRGB(255, 138, 31))
	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(36, 32)
	close.Position = UDim2.new(1, -50, 0, 12)
	close.BackgroundColor3 = Color3.fromRGB(150, 60, 70)
	close.Font = Enum.Font.GothamBlack
	close.TextScaled = true
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Text = "X"
	close.ZIndex = 31
	close.Parent = inviteBox
	local cc = Instance.new("UICorner")
	cc.Parent = close
	close.Activated:Connect(function()
		inviteBox:Destroy()
		inviteBox = nil
	end)
	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -40, 1, -120)
	list.Position = UDim2.fromOffset(20, 52)
	list.BackgroundTransparency = 1
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 6
	list.ZIndex = 31
	list.Parent = inviteBox
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local order = 0
	local function row(name, action, onClick, colour)
		order += 1
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, -8, 0, 40)
		r.BackgroundColor3 = Color3.fromRGB(75, 58, 102)
		r.LayoutOrder = order
		r.ZIndex = 32
		r.Parent = list
		local rc = Instance.new("UICorner")
		rc.Parent = r
		local n = Instance.new("TextLabel")
		n.Size = UDim2.new(1, -130, 1, -10)
		n.Position = UDim2.fromOffset(10, 5)
		n.BackgroundTransparency = 1
		n.Font = Enum.Font.FredokaOne
		n.TextScaled = true
		n.TextXAlignment = Enum.TextXAlignment.Left
		n.TextColor3 = Color3.fromRGB(255, 244, 224)
		n.Text = name
		n.ZIndex = 33
		n.Parent = r
		if action then
			local b = Instance.new("TextButton")
			b.Size = UDim2.fromOffset(110, 30)
			b.Position = UDim2.new(1, -116, 0, 5)
			b.BackgroundColor3 = colour or Color3.fromRGB(255, 138, 31)
			b.Font = Enum.Font.FredokaOne
			b.TextScaled = true
			b.TextColor3 = Color3.fromRGB(26, 16, 38)
			b.Text = action
			b.ZIndex = 33
			b.Parent = r
			local bc = Instance.new("UICorner")
			bc.Parent = b
			b.Activated:Connect(function()
				onClick()
				b.Text = "\u{2705} Sent"
				b.Active = false
			end)
		end
	end
	local function heading(t)
		order += 1
		local h = Instance.new("TextLabel")
		h.Size = UDim2.new(1, -8, 0, 24)
		h.BackgroundTransparency = 1
		h.Font = Enum.Font.FredokaOne
		h.TextScaled = true
		h.TextXAlignment = Enum.TextXAlignment.Left
		h.TextColor3 = Color3.fromRGB(185, 168, 207)
		h.Text = t
		h.LayoutOrder = order
		h.ZIndex = 32
		h.Parent = list
	end
	-- people already in this Lobby
	if inParty then
		heading("Here in the Lobby")
		local any = false
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				any = true
				row(p.DisplayName, "Invite", function()
					remotes.InviteToParty:FireServer(p.UserId)
				end)
			end
		end
		if not any then
			row("Nobody else here yet", nil)
		end
	end
	-- friends who are online somewhere else
	heading("Friends online")
	task.spawn(function()
		local ok, friends = pcall(function()
			return player:GetFriendsOnline(50)
		end)
		if not inviteBox then
			return
		end
		local here = {}
		for _, p in ipairs(Players:GetPlayers()) do
			here[p.UserId] = true
		end
		local shown = 0
		for _, f in ipairs(ok and friends or {}) do
			if not here[f.VisitorId] then
				shown += 1
				row(f.DisplayName or f.UserName, "Invite", function()
					robloxInvite(f.VisitorId)
				end, Color3.fromRGB(0, 170, 220))
			end
		end
		if shown == 0 then
			row(ok and "No friends online right now" or "Friends list not available here", nil)
		end
	end)
	-- or Roblox's own list
	local all = Instance.new("TextButton")
	all.Size = UDim2.new(1, -40, 0, 44)
	all.Position = UDim2.new(0, 20, 1, -58)
	all.BackgroundColor3 = Color3.fromRGB(75, 58, 102)
	all.Font = Enum.Font.FredokaOne
	all.TextScaled = true
	all.TextColor3 = Color3.fromRGB(255, 244, 224)
	all.Text = "Open Roblox's invite list"
	all.ZIndex = 31
	all.Parent = inviteBox
	local ac = Instance.new("UICorner")
	ac.Parent = all
	all.Activated:Connect(function()
		robloxInvite(nil)
	end)
end

-- someone in this Lobby invited you to their party
remotes.PartyInvite.OnClientEvent:Connect(function(info)
	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(380, 150)
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, 80)
	box.BackgroundColor3 = Color3.fromRGB(26, 16, 38)
	box.ZIndex = 40
	box.Parent = gui
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 16)
	bc.Parent = box
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -30, 0, 70)
	t.Position = UDim2.fromOffset(15, 10)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextWrapped = true
	t.TextColor3 = Color3.fromRGB(255, 244, 224)
	t.Text = "\u{2709} " .. tostring(info.from) .. " invited you to " .. tostring(info.leader) .. "'s party!"
	t.ZIndex = 41
	t.Parent = box
	local function btn(textValue, x, colour, onClick)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(160, 44)
		b.Position = UDim2.fromOffset(x, 92)
		b.BackgroundColor3 = colour
		b.Font = Enum.Font.FredokaOne
		b.TextScaled = true
		b.TextColor3 = Color3.fromRGB(26, 16, 38)
		b.Text = textValue
		b.ZIndex = 41
		b.Parent = box
		local c = Instance.new("UICorner")
		c.Parent = b
		b.Activated:Connect(function()
			onClick()
			box:Destroy()
		end)
	end
	btn("Join", 20, Color3.fromRGB(255, 138, 31), function()
		remotes.JoinParty:FireServer(info.id)
	end)
	btn("No thanks", 200, Color3.fromRGB(185, 168, 207), function() end)
	task.delay(30, function()
		if box.Parent then
			box:Destroy()
		end
	end)
end)

-- ---------- main menu (left) ----------
local menu = frame(gui, { Size = UDim2.fromOffset(330, 500), Position = UDim2.new(0, 24, 0.5, -250) })
corner(menu, 18)
local menuStroke = Instance.new("UIStroke")
menuStroke.Color, menuStroke.Transparency = PUMP, 0.6
menuStroke.Parent = menu
local menuPad = Instance.new("UIPadding")
menuPad.PaddingTop, menuPad.PaddingBottom = UDim.new(0, 16), UDim.new(0, 16)
menuPad.Parent = menu
list(menu, 10)
label(menu, { Size = UDim2.new(0.9, 0, 0, 22), Text = "THE PARTY AT THE END OF THE LANE", TextColor3 = Color3.fromRGB(255, 217, 168), LayoutOrder = 1 })
label(menu, { Size = UDim2.new(0.9, 0, 0, 56), Text = "ESCAPE CREW", TextColor3 = PUMP, LayoutOrder = 2 })
button(menu, "\u{25B6} Play solo", { Size = UDim2.new(0.86, 0, 0, 52), BackgroundColor3 = PUMP, TextColor3 = NIGHT, LayoutOrder = 3 }, function()
	remotes.CreateParty:FireServer(true)
end)
button(menu, "\u{1F465} Create a party", { Size = UDim2.new(0.86, 0, 0, 52), LayoutOrder = 4 }, function()
	remotes.CreateParty:FireServer(false)
end)
button(menu, "\u{2709} Invite friends", { Size = UDim2.new(0.86, 0, 0, 46), LayoutOrder = 5 }, invite)
local shopBtn = button(menu, "\u{1F6D2} Shop", { Size = UDim2.new(0.86, 0, 0, 46), LayoutOrder = 6 })
local charsBtn = button(menu, "\u{1F9D1}\u{200D}\u{1F91D}\u{200D}\u{1F9D1} Characters", { Size = UDim2.new(0.86, 0, 0, 46), LayoutOrder = 7 })
local helpBtn = button(menu, "\u{2753} How to play", { Size = UDim2.new(0.86, 0, 0, 46), LayoutOrder = 8 })

-- ---------- parties you can join (right) ----------
local joinBox = frame(gui, { Size = UDim2.fromOffset(330, 400), Position = UDim2.new(1, -354, 0.5, -200) })
corner(joinBox, 18)
label(joinBox, { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 10), Text = "Friends' parties", TextColor3 = PUMP })
local joinList = frame(joinBox, { Size = UDim2.new(1, -20, 1, -64), Position = UDim2.fromOffset(10, 56), BackgroundTransparency = 1 })
list(joinList, 8)
local joinEmpty = label(joinList, { Size = UDim2.new(1, 0, 0, 60), Text = "No parties yet - create one and invite a friend!", TextColor3 = Color3.fromRGB(185, 168, 207) })

-- ---------- your party (middle) ----------
local partyBox = frame(gui, { Size = UDim2.fromOffset(440, 560), Position = UDim2.new(0.5, -220, 0.5, -280), Visible = false })
corner(partyBox, 18)
local partyTitle = label(partyBox, { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 10), Text = "Your party", TextColor3 = PUMP })
local slots = frame(partyBox, { Size = UDim2.new(1, -40, 0, 150), Position = UDim2.fromOffset(20, 56), BackgroundTransparency = 1 })
local slotGrid = Instance.new("UIGridLayout")
slotGrid.CellSize = UDim2.fromOffset(190, 42)
slotGrid.CellPadding = UDim2.fromOffset(10, 8)
slotGrid.Parent = slots
local slotLabels = {}
for i = 1, Config.MAX_PARTY do
	local s = frame(slots, { BackgroundColor3 = PLUM, BackgroundTransparency = 0.2 })
	corner(s, 10)
	slotLabels[i] = { frame = s, text = label(s, { Size = UDim2.new(1, -16, 0.8, 0), Position = UDim2.new(0, 8, 0.1, 0), Text = "" }) }
end

local current = nil
local amLeader = false
local function opt(key, value)
	remotes.SetOption:FireServer(key, value)
end
local mapBox = frame(partyBox, { Size = UDim2.new(1, -40, 0, 80), Position = UDim2.fromOffset(20, 210), BackgroundTransparency = 1 })
local mapGrid = Instance.new("UIGridLayout")
mapGrid.CellSize = UDim2.new(1 / #Progress.MAPS, -7, 0, 76)
mapGrid.CellPadding = UDim2.fromOffset(8, 0)
mapGrid.Parent = mapBox
local mapBtns = {}
for _, m in ipairs(Progress.MAPS) do
	mapBtns[m.id] = button(mapBox, "", {}, function()
		remotes.VoteMap:FireServer(m.id)
	end)
end
local optBox = frame(partyBox, { Size = UDim2.new(1, -40, 0, 170), Position = UDim2.fromOffset(20, 300), BackgroundTransparency = 1 })
label(optBox, { Size = UDim2.new(0.32, 0, 0, 30), Position = UDim2.fromOffset(0, 0), Text = "Players", TextXAlignment = Enum.TextXAlignment.Left })
button(optBox, "-", { Size = UDim2.fromOffset(40, 32), Position = UDim2.fromOffset(150, 0) }, function()
	if current then
		opt("max", current.max - 1)
	end
end)
local maxLabel = label(optBox, { Size = UDim2.fromOffset(60, 32), Position = UDim2.fromOffset(196, 0), Text = "6" })
button(optBox, "+", { Size = UDim2.fromOffset(40, 32), Position = UDim2.fromOffset(262, 0) }, function()
	if current then
		opt("max", current.max + 1)
	end
end)
local friendsBtn = button(optBox, "", { Size = UDim2.fromOffset(250, 34), Position = UDim2.fromOffset(150, 40) }, function()
	if current then
		opt("friendsOnly", not current.friendsOnly)
	end
end)
label(optBox, { Size = UDim2.new(0.32, 0, 0, 30), Position = UDim2.fromOffset(0, 42), Text = "Who can join", TextXAlignment = Enum.TextXAlignment.Left })
local diffBtns = {}
for i, key in ipairs(Config.DIFFICULTY_ORDER) do
	diffBtns[key] = button(optBox, Config.DIFFICULTY[key].name, { Size = UDim2.fromOffset(92, 34), Position = UDim2.fromOffset((i - 1) * 100, 84) }, function()
		opt("difficulty", key)
	end)
end
local gigBtn = button(optBox, "\u{1F604} Giggly", { Size = UDim2.fromOffset(190, 34), Position = UDim2.fromOffset(0, 126) }, function()
	opt("spook", "giggly")
end)
local spkBtn = button(optBox, "\u{1F47B} Spooky", { Size = UDim2.fromOffset(190, 34), Position = UDim2.fromOffset(200, 126) }, function()
	opt("spook", "spooky")
end)
local startBtn = button(partyBox, "\u{25B6} Start", { Size = UDim2.fromOffset(130, 48), Position = UDim2.new(0, 20, 1, -64), BackgroundColor3 = PUMP, TextColor3 = NIGHT }, function()
	remotes.StartParty:FireServer()
end)
button(partyBox, "\u{2709} Invite", { Size = UDim2.fromOffset(130, 48), Position = UDim2.new(0.5, -65, 1, -64) }, invite)
button(partyBox, "Leave", { Size = UDim2.fromOffset(130, 48), Position = UDim2.new(1, -150, 1, -64) }, function()
	remotes.LeaveParty:FireServer()
end)

local function paintParty(p)
	current = p
	inParty = p ~= nil
	partyBox.Visible = p ~= nil
	menu.Visible = p == nil
	joinBox.Visible = p == nil
	if not p then
		return
	end
	amLeader = p.leaderId == player.UserId
	partyTitle.Text = (amLeader and "Your party" or (p.leader .. "'s party")) .. "  (" .. #p.members .. "/" .. p.max .. ")"
	for i = 1, Config.MAX_PARTY do
		local m = p.members[i]
		local s = slotLabels[i]
		s.frame.Visible = i <= p.max
		s.text.Text = m and ((m.userId == p.leaderId and "\u{1F451} " or "") .. m.name) or "Waiting..."
		s.text.TextColor3 = m and CREAM or Color3.fromRGB(150, 135, 175)
	end
	maxLabel.Text = tostring(p.max)
	friendsBtn.Text = p.friendsOnly and "\u{1F512} Friends only" or "\u{1F310} Anyone in the lobby"
	for key, b in pairs(diffBtns) do
		b.BackgroundColor3 = key == p.difficulty and Color3.fromRGB(232, 80, 91) or PLUM
	end
	gigBtn.BackgroundColor3 = p.spook == "giggly" and PUMP or PLUM
	spkBtn.BackgroundColor3 = p.spook == "spooky" and PUMP or PLUM
	optBox.Active = amLeader
	startBtn.Visible = amLeader
	local tally = {}
	for _, mapId in pairs(p.votes or {}) do
		tally[mapId] = (tally[mapId] or 0) + 1
	end
	local myVote = p.votes and p.votes[tostring(player.UserId)]
	for _, m in ipairs(Progress.MAPS) do
		local b = mapBtns[m.id]
		local open = m.ready and p.unlocked and p.unlocked[m.id]
		local state = not m.ready and "Coming soon" or (open and ((tally[m.id] or 0) .. " vote" .. ((tally[m.id] or 0) == 1 and "" or "s")) or "\u{1F512} Locked")
		b.Text = m.icon .. " " .. m.name .. "\n" .. state
		b.BackgroundColor3 = myVote == m.id and PUMP or (open and PLUM or Color3.fromRGB(50, 44, 60))
		b.TextColor3 = myVote == m.id and NIGHT or CREAM
	end
end

remotes.PartyList.OnClientEvent:Connect(function(parties, myId)
	local mine = nil
	for _, child in ipairs(joinList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local shown = 0
	for _, p in ipairs(parties) do
		if p.id == myId then
			mine = p
		elseif #p.members < p.max then
			shown += 1
			button(joinList, p.leader .. "'s party  " .. #p.members .. "/" .. p.max .. "  \u{00B7} " .. Config.DIFFICULTY[p.difficulty].name, { Size = UDim2.new(1, 0, 0, 46) }, function()
				remotes.JoinParty:FireServer(p.id)
			end)
		end
	end
	joinEmpty.Visible = shown == 0
	paintParty(mine)
end)

-- ---------- my profile (points, bag, characters) ----------
local profile = { points = 0, inv = {}, loadout = {}, xp = {}, picks = {}, unlocked = {} }
local pointsLabel = label(gui, { Size = UDim2.fromOffset(240, 36), Position = UDim2.new(1, -260, 0, 64), Text = "\u{2B50} 0 points", TextXAlignment = Enum.TextXAlignment.Right })
local repaintShop, repaintChars

local function readProfile()
	local json = player:GetAttribute("ProfileJson")
	if json then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(json)
		end)
		if ok and type(data) == "table" then
			profile = data
		end
	end
	pointsLabel.Text = "\u{2B50} " .. tostring(profile.points or 0) .. " points"
	if repaintShop then
		repaintShop()
	end
	if repaintChars then
		repaintChars()
	end
end
player:GetAttributeChangedSignal("ProfileJson"):Connect(readProfile)

-- ---------- the shop ----------
local shop = frame(gui, { Size = UDim2.fromOffset(620, 610), Position = UDim2.new(0.5, -310, 0.5, -305), Visible = false, ZIndex = 10 })
corner(shop, 18)
local shopTitle = label(shop, { Size = UDim2.new(1, -40, 0, 40), Position = UDim2.fromOffset(20, 10), Text = "\u{1F6D2} Boost Shop", TextColor3 = PUMP, ZIndex = 11 })
label(shop, { Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 50), Text = "+ buys, - sells back. Tap Take on up to " .. Progress.MAX_BOOSTS .. " to bring into your next game.", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 11 })
local shopRows = {}
for i, id in ipairs(Progress.BOOST_ORDER) do
	local b = Progress.BOOSTS[id]
	local row = frame(shop, { Size = UDim2.new(1, -24, 0, 64), Position = UDim2.fromOffset(12, 78 + (i - 1) * 70), BackgroundColor3 = PLUM, BackgroundTransparency = 0.3, ZIndex = 11 })
	corner(row, 12)
	local img = Config.BOOST_IMAGES[id] or 0
	if img > 0 then
		local pic = Instance.new("ImageLabel")
		pic.BackgroundTransparency = 1
		pic.Image = "rbxassetid://" .. img
		pic.Size = UDim2.fromOffset(52, 52)
		pic.Position = UDim2.fromOffset(5, 6)
		pic.ZIndex = 12
		pic.Parent = row
	else
		label(row, { Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(8, 9), Text = b.icon, ZIndex = 12 })
	end
	label(row, { Size = UDim2.fromOffset(200, 26), Position = UDim2.fromOffset(60, 6), Text = b.name, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
	label(row, { Size = UDim2.fromOffset(220, 22), Position = UDim2.fromOffset(60, 34), Text = b.say, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(205, 190, 225), ZIndex = 12 })
	local owned = label(row, { Size = UDim2.fromOffset(84, 20), Position = UDim2.fromOffset(282, 4), Text = "You have 0", ZIndex = 12 })
	button(row, "+ " .. b.price .. " \u{2B50}", { Size = UDim2.fromOffset(84, 40), Position = UDim2.fromOffset(282, 30 - 18 + 14), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 12 }, function()
		remotes.BuyBoost:FireServer(id)
	end)
	local minus = button(row, "-", { Font = Enum.Font.GothamBlack, Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(370, 26), BackgroundColor3 = Color3.fromRGB(150, 60, 70), ZIndex = 12 }, function()
		remotes.SellBoost:FireServer(id)
	end)
	local productId = Config.ROBUX_PRODUCTS[id] or 0
	if productId > 0 then
		button(row, "R$", { Size = UDim2.fromOffset(46, 40), Position = UDim2.fromOffset(414, 26), BackgroundColor3 = Color3.fromRGB(0, 176, 111), ZIndex = 12 }, function()
			MarketplaceService:PromptProductPurchase(player, productId)
		end)
	end
	local take = button(row, "", { Size = UDim2.fromOffset(92, 40), Position = UDim2.fromOffset(496, 12), ZIndex = 12 }, function()
		local list, have = {}, false
		for _, x in ipairs(profile.loadout or {}) do
			if x == id and not have then
				have = true
			else
				table.insert(list, x)
			end
		end
		if not have then
			if #list >= Progress.MAX_BOOSTS then
				notice("You can take " .. Progress.MAX_BOOSTS .. " boosts. Tap a \u{2705} Taking one to put it back first.")
				return
			end
			table.insert(list, id)
		end
		-- show the change straight away; the server's copy follows
		profile.loadout = list
		repaintShop()
		remotes.SetLoadout:FireServer(list)
	end)
	shopRows[id] = { owned = owned, take = take, minus = minus }
end
-- what is packed for the next game
local packed = frame(shop, { Size = UDim2.new(1, -24, 0, 46), Position = UDim2.fromOffset(12, 502), BackgroundColor3 = Color3.fromRGB(47, 107, 58), BackgroundTransparency = 0.4, ZIndex = 11 })
corner(packed, 12)
local packedText = label(packed, { Size = UDim2.new(1, -20, 1, -12), Position = UDim2.fromOffset(10, 6), ZIndex = 12 })
button(shop, "Close", { Size = UDim2.fromOffset(160, 44), Position = UDim2.new(0.5, -80, 1, -54), ZIndex = 11 }, function()
	shop.Visible = false
end)
repaintShop = function()
	shopTitle.Text = "\u{1F6D2} Boost Shop  \u{00B7}  \u{2B50} " .. tostring(profile.points or 0) .. " points"
	for id, r in pairs(shopRows) do
		local n = (profile.inv and profile.inv[id]) or 0
		r.owned.Text = "You have " .. n
		local taking = table.find(profile.loadout or {}, id) ~= nil
		r.take.Text = taking and "\u{2705} Taking" or "Take"
		r.take.BackgroundColor3 = taking and Color3.fromRGB(47, 107, 58) or PLUM
		r.take.Visible = n > 0
		r.minus.Visible = n > 0
	end
	local names = {}
	for _, id in ipairs(profile.loadout or {}) do
		local b = Progress.BOOSTS[id]
		if b then
			table.insert(names, b.icon .. " " .. b.name)
		end
	end
	packedText.Text = #names > 0 and ("Next game: " .. table.concat(names, " + ") .. "  (tap \u{2705} to put back)") or "Next game: nothing packed yet"

end
shopBtn.Activated:Connect(function()
	shop.Visible = true
end)
remotes.OpenShop.OnClientEvent:Connect(function()
	shop.Visible = true
end)

-- ---------- characters and the skill ladder ----------
local chars = frame(gui, { Size = UDim2.fromOffset(900, 560), Position = UDim2.new(0.5, -450, 0.5, -280), Visible = false, ZIndex = 10 })
corner(chars, 18)
label(chars, { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 10), Text = "Characters & skill ladder", TextColor3 = PUMP, ZIndex = 11 })
-- left: the character in 3D (drag to turn) and what their skill does
local view = Instance.new("ViewportFrame")
view.Size = UDim2.fromOffset(230, 270)
view.Position = UDim2.fromOffset(14, 56)
view.BackgroundColor3 = Color3.fromRGB(40, 26, 58)
view.Ambient = Color3.fromRGB(170, 160, 190)
view.LightColor = Color3.fromRGB(255, 240, 220)
view.LightDirection = Vector3.new(-0.4, -1, -0.6)
view.ZIndex = 11
view.Parent = chars
corner(view, 14)
local viewWorld = Instance.new("WorldModel")
viewWorld.Parent = view
local viewCam = Instance.new("Camera")
viewCam.FieldOfView = 32
viewCam.Parent = view
view.CurrentCamera = viewCam
local noModel = label(view, { Size = UDim2.fromScale(1, 0.7), Position = UDim2.fromScale(0, 0.12), Text = "", ZIndex = 12 })
label(view, { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -24), Text = "drag to turn", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 12 })
local skillAbout = label(chars, { Size = UDim2.fromOffset(230, 120), Position = UDim2.fromOffset(14, 334), TextScaled = false, TextSize = 16, TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 11 })
-- right: picking a character, their level and the skill ladder
local right = frame(chars, { Size = UDim2.new(1, -256, 1, -60), Position = UDim2.fromOffset(250, 0), BackgroundTransparency = 1, ZIndex = 11 })
local charRow = frame(right, { Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 56), BackgroundTransparency = 1, ZIndex = 11 })
local charGrid = Instance.new("UIGridLayout")
charGrid.CellSize = UDim2.fromOffset(72, 46)
charGrid.CellPadding = UDim2.fromOffset(6, 0)
charGrid.Parent = charRow
local selected = Config.SKILLS[1].id
local charBtns = {}
for _, sk in ipairs(Config.SKILLS) do
	charBtns[sk.id] = button(charRow, sk.icon, { BackgroundColor3 = sk.color, ZIndex = 12 }, function()
		selected = sk.id
		repaintChars()
	end)
end
local charTitle = label(right, { Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 114), Text = "", ZIndex = 11 })
local xpBack = frame(right, { Size = UDim2.new(1, -40, 0, 14), Position = UDim2.fromOffset(20, 150), BackgroundColor3 = Color3.fromRGB(18, 10, 27), BackgroundTransparency = 0, ZIndex = 11 })
corner(xpBack, 7)
local xpFill = frame(xpBack, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(123, 227, 107), BackgroundTransparency = 0, ZIndex = 12 })
corner(xpFill, 7)
local ladder = {}
for level = 2, 5 do
	local y = 176 + (level - 2) * 68
	local tag = label(right, { Size = UDim2.fromOffset(70, 56), Position = UDim2.fromOffset(16, y), Text = "Lv " .. level, ZIndex = 11 })
	local a = button(right, "", { Size = UDim2.fromOffset(265, 56), Position = UDim2.fromOffset(92, y), ZIndex = 11 })
	local b = button(right, "", { Size = UDim2.fromOffset(265, 56), Position = UDim2.fromOffset(364, y), ZIndex = 11 })
	ladder[level] = { tag = tag, a = a, b = b }
	for _, side in ipairs({ "a", "b" }) do
		ladder[level][side].Activated:Connect(function()
			local options = Progress.choices(selected, level)
			local opt = options and options[side == "a" and 1 or 2]
			if opt then
				remotes.PickUpgrade:FireServer(selected, level, opt.id)
			end
		end)
	end
end
-- choices are for keeps; a reset clears this character's whole ladder
button(right, "\u{1F504} Reset upgrades: " .. Config.RESET_POINTS .. " \u{2B50}", { Size = UDim2.fromOffset(265, 34), Position = UDim2.fromOffset(92, 448), BackgroundColor3 = Color3.fromRGB(150, 60, 70), ZIndex = 11 }, function()
	remotes.ResetLadder:FireServer(selected, "points")
end)
button(right, "\u{1F504} Reset upgrades: R$ 49", { Size = UDim2.fromOffset(265, 34), Position = UDim2.fromOffset(364, 448), BackgroundColor3 = Color3.fromRGB(0, 176, 111), ZIndex = 11, Visible = (Config.ROBUX_PRODUCTS.reset or 0) > 0 }, function()
	remotes.ResetLadder:FireServer(selected, "robux")
	MarketplaceService:PromptProductPurchase(player, Config.ROBUX_PRODUCTS.reset)
end)
button(chars, "Close", { Size = UDim2.fromOffset(160, 40), Position = UDim2.new(0.5, -80, 1, -46), ZIndex = 11 }, function()
	chars.Visible = false
end)
local shown, spin, dragging, lastX, shownFor = nil, 0, false, 0, nil
local function showModel(sk)
	if shownFor == sk.id and shown then
		return
	end
	if shown then
		shown:Destroy()
		shown = nil
	end
	spin = 0
	local previews = ReplicatedStorage:FindFirstChild("Previews")
	local src = previews and previews:FindFirstChild(sk.name)
	if src then
		shown = src:Clone()
		shown.Parent = viewWorld
		shownFor = sk.id
		noModel.Visible = false
	else
		shownFor = nil
		noModel.Visible = true
		noModel.Text = sk.icon .. "\n3D model coming soon"
	end
	local info = Config.SKILL_INFO[sk.id]
	skillAbout.Text = sk.say .. (info and (": " .. info.about) or "")
end
-- models load in the background: show one as soon as it arrives
task.spawn(function()
	local previews = ReplicatedStorage:WaitForChild("Previews", 30)
	if previews then
		previews.ChildAdded:Connect(function()
			if chars.Visible and repaintChars then
				shownFor = nil
				repaintChars()
			end
		end)
	end
end)
view.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, lastX = true, input.Position.X
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		spin += (input.Position.X - lastX) * 0.012
		lastX = input.Position.X
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
RunService.RenderStepped:Connect(function()
	if not shown or not chars.Visible then
		return
	end
	-- characters face -Z; turn it round to face the camera on +Z
	shown:PivotTo(CFrame.Angles(0, math.pi + spin, 0))
	local cf, size = shown:GetBoundingBox()
	local dist = size.Y * 0.62 / math.tan(math.rad(viewCam.FieldOfView / 2))
	viewCam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, size.Y * 0.05, dist), cf.Position)
end)

repaintChars = function()
	local sk
	for _, x in ipairs(Config.SKILLS) do
		if x.id == selected then
			sk = x
		end
		local stroke = charBtns[x.id]:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", charBtns[x.id])
		stroke.Thickness = x.id == selected and 3 or 0
		stroke.Color = Color3.new(1, 1, 1)
	end
	showModel(sk)
	local xp = (profile.xp and profile.xp[selected]) or 0
	local lvl = Progress.level(xp)
	local nextNeed = Progress.LEVEL_XP[lvl + 1]
	charTitle.Text = sk.icon .. " " .. sk.name .. "  \u{00B7}  Level " .. lvl .. "  \u{00B7}  " .. xp .. " XP" .. (nextNeed and (" (next at " .. nextNeed .. ")") or " (max!)")
	local prev = Progress.LEVEL_XP[lvl]
	xpFill.Size = UDim2.fromScale(nextNeed and math.clamp((xp - prev) / (nextNeed - prev), 0, 1) or 1, 1)
	local picks = (profile.picks and profile.picks[selected]) or {}
	for level = 2, 5 do
		local options = Progress.choices(selected, level)
		local row = ladder[level]
		local reached = lvl >= level
		for i, side in ipairs({ "a", "b" }) do
			local opt = options[i]
			local chosen = picks[tostring(level)] == opt.id
			local other = picks[tostring(level)] ~= nil and not chosen -- the one not taken: locked out
			row[side].Text = (chosen and "\u{2705} " or other and "\u{1F512} " or "") .. opt.name .. "\n" .. opt.say
			row[side].BackgroundColor3 = chosen and Color3.fromRGB(47, 107, 58) or ((reached and not other) and PLUM or Color3.fromRGB(45, 40, 55))
			row[side].TextTransparency = (reached and not other) and 0 or 0.5
		end
		row.tag.Text = reached and ("Lv " .. level) or ("\u{1F512} " .. level)
	end
end
charsBtn.Activated:Connect(function()
	chars.Visible = true
	repaintChars()
end)
readProfile()

-- ---------- daily reward ----------
local function showDaily()
	local json = player:GetAttribute("DailyShow")
	if not json then
		return
	end
	local ok, info = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(info) ~= "table" then
		return
	end
	local box = frame(gui, { Size = UDim2.fromOffset(640, 330), Position = UDim2.new(0.5, -320, 0.5, -165), ZIndex = 20 })
	corner(box, 18)
	label(box, { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 10), Text = "\u{1F381} Daily reward \u{00B7} " .. info.streak .. (info.streak == 1 and " day" or " days") .. " in a row!", TextColor3 = PUMP, ZIndex = 21 })
	for i, r in ipairs(Config.DAILY) do
		local today = i == info.day
		local done = i < info.day
		local cell = frame(box, { Size = UDim2.fromOffset(80, 110), Position = UDim2.fromOffset(18 + (i - 1) * 87, 62),
			BackgroundColor3 = today and PUMP or (done and Color3.fromRGB(47, 107, 58) or PLUM), BackgroundTransparency = today and 0 or 0.3, ZIndex = 21 })
		corner(cell, 12)
		label(cell, { Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 6), Text = "Day " .. i, TextColor3 = today and NIGHT or CREAM, ZIndex = 22 })
		local b = r.boost and Progress.BOOSTS[r.boost]
		label(cell, { Size = UDim2.new(1, -8, 0, 40), Position = UDim2.fromOffset(4, 32), Text = (done and "\u{2705}\n" or "") .. r.points .. " \u{2B50}" .. (b and ("\n+" .. b.icon) or ""), TextColor3 = today and NIGHT or CREAM, ZIndex = 22 })
	end
	local b = info.boost and Progress.BOOSTS[info.boost]
	label(box, { Size = UDim2.new(1, -40, 0, 30), Position = UDim2.fromOffset(20, 182),
		Text = "+" .. info.points .. " \u{2B50}" .. (b and (" and a " .. b.icon .. " " .. b.name) or "") .. (info.premium and "  (Premium: double points!)" or ""), ZIndex = 21 })
	label(box, { Size = UDim2.new(1, -40, 0, 22), Position = UDim2.fromOffset(20, 214), Text = "Come back tomorrow for day " .. (info.day % #Config.DAILY + 1) .. ". Miss a day and it starts again at day 1.", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 21 })
	if not info.premium then
		button(box, "\u{2B50} Roblox Premium: double daily points", { Size = UDim2.fromOffset(330, 38), Position = UDim2.fromOffset(20, 276), BackgroundColor3 = Color3.fromRGB(0, 120, 200), ZIndex = 21 }, function()
			MarketplaceService:PromptPremiumPurchase(player)
		end)
	end
	button(box, "Yay!", { Size = UDim2.fromOffset(150, 38), Position = UDim2.new(1, -170, 0, 276), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 21 }, function()
		box:Destroy()
	end)
end
if player:GetAttribute("DailyShow") then
	showDaily()
else
	local conn
	conn = player:GetAttributeChangedSignal("DailyShow"):Connect(function()
		conn:Disconnect()
		showDaily()
	end)
end

-- ---------- music ----------
require(ReplicatedStorage.Shared.MusicPlayer).start("lobby", gui, UDim2.new(1, -116, 0, 104), remotes:WaitForChild("SetMusic"))

-- ---------- the trampoline: bounce high (here, where the character's physics run) ----------
task.spawn(function()
	local fun = workspace:WaitForChild("LobbyFun", 30)
	local tramp = fun and fun:WaitForChild("Trampoline", 10)
	if not tramp then
		return
	end
	local last = 0
	tramp.Touched:Connect(function(hit)
		local char = player.Character
		if not char or not hit:IsDescendantOf(char) or os.clock() - last < 0.5 then
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		last = os.clock()
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(v.X, 85, v.Z)
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://" .. Config.SOUNDS.bounce
		s.Parent = tramp
		s:Play()
		game:GetService("Debris"):AddItem(s, 2)
	end)
end)

-- ---------- how to play ----------
local help = frame(gui, { Size = UDim2.fromOffset(520, 420), Position = UDim2.new(0.5, -260, 0.5, -210), Visible = false, ZIndex = 10 })
corner(help, 18)
label(help, { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 10), Text = "How to play", TextColor3 = PUMP, ZIndex = 11 })
label(help, {
	Size = UDim2.new(1, -40, 1, -120),
	Position = UDim2.fromOffset(20, 56),
	TextScaled = false,
	TextSize = 19,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 11,
	Text = "\u{1F3E0} You were dropped at a party. It was a trick. Find the way out of the Party House before the host catches you - and before the timer runs out.\n\n"
		.. "\u{1F388} Pop the numbered balloons (E) to learn the door code, or use your character's skill.\n"
		.. "\u{1F648} Hide in wardrobes, curtains and boxes (E). Jump to come out.\n"
		.. "\u{1F3C3} Run with Shift or the Run button - it uses stamina.\n"
		.. "\u{1F4A1} Clues show the next step but cost points you earned in that game.\n"
		.. "\u{1F512} Caught? A teammate frees you from the cage - or watch your team.\n"
		.. "\u{1F333} Everyone out to the garden = you win!",
})
button(help, "Got it", { Size = UDim2.fromOffset(160, 46), Position = UDim2.new(0.5, -80, 1, -60), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 11 }, function()
	help.Visible = false
end)
helpBtn.Activated:Connect(function()
	help.Visible = true
end)
