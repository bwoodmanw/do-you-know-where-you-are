--[[
	LobbyUi - the lobby screen: Play solo, Create party, parties you can join,
	and your party (players 1-6, friends only, difficulty, Giggly/Spooky,
	Invite friends, Start, Leave).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Config = require(ReplicatedStorage.Shared.Config)
local Sfx = require(game:GetService("ReplicatedStorage").Shared.Sfx)
local Progress = require(ReplicatedStorage.Shared.Progress)
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local remotes = ReplicatedStorage:WaitForChild("LobbyRemotes")
local Gamepad = require(ReplicatedStorage.Shared.Gamepad)
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
-- the clean look (art/ui-mockups/menus-v2.png): Roblox's Builder Sans for
-- words, the rounded game font only for orange titles, and text that stays a
-- normal size instead of growing to fill its box
local BODY_FONT = Enum.Font.GothamBold
pcall(function()
	BODY_FONT = Enum.Font.BuilderSansBold
end)
local function capText(o, max)
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = max
	c.Parent = o
end
local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = BODY_FONT
	l.TextColor3 = CREAM
	l.TextScaled = true
	for k, v in pairs(props) do
		l[k] = v
	end
	local title = l.TextColor3 == PUMP
	if title and props.Font == nil then
		l.Font = Enum.Font.FredokaOne
	end
	capText(l, title and Config.UI_TEXT.title or Config.UI_TEXT.body)
	l.Parent = parent
	return l
end
local function button(parent, text, props, onClick)
	local b = Instance.new("TextButton")
	b.Font = BODY_FONT
	b.Text = text
	b.TextScaled = true
	b.TextColor3 = CREAM
	b.BackgroundColor3 = PLUM
	for k, v in pairs(props) do
		b[k] = v
	end
	-- no light buttons: plum (or the color given) with a thin cream edge
	if b.BackgroundColor3 == CREAM then
		b.BackgroundColor3, b.TextColor3 = PLUM, CREAM
	end
	capText(b, Config.UI_TEXT.body)
	local edge = Instance.new("UIStroke")
	edge.Color, edge.Thickness, edge.ApplyStrokeMode, edge.Transparency = CREAM, 2, Enum.ApplyStrokeMode.Border, 0.35
	edge.Parent = b
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
			-- who invited them: both get a Party Shield when a new friend arrives
			options.LaunchData = "inv:" .. player.UserId
			options.PromptMessage = 'Come and escape with me! New players who join from my invite get a Party Shield - and so do I.'
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
	local thisBox = inviteBox
	Gamepad.panel(thisBox, nil, function()
		thisBox:Destroy()
		if inviteBox == thisBox then
			inviteBox = nil
		end
	end)
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
	Gamepad.panel(box, nil, function()
		box:Destroy()
	end)
	task.delay(30, function()
		if box.Parent then
			box:Destroy()
		end
	end)
end)

-- ---------- main menu: big picture tiles, one word each ----------
-- (the look Brent picked 9 Oct: art/ui-mockups/lobby-v2.png). The left has
-- the play tiles, the right a bar of smaller ones. A tile shows its picture
-- from Config.UI_ICONS once uploaded, its emoji until then.
local menu = frame(gui, { Size = UDim2.fromOffset(310, 590), Position = UDim2.fromOffset(20, 136), BackgroundTransparency = 1 })
local rightBar = frame(gui, { Size = UDim2.fromOffset(104, 520), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 196), BackgroundTransparency = 1 })
do
	-- small screens: the tiles shrink to fit
	local fitL, fitR = Instance.new("UIScale"), Instance.new("UIScale")
	fitL.Parent, fitR.Parent = menu, rightBar
	local function refit()
		local cam = workspace.CurrentCamera
		local vy = cam and cam.ViewportSize.Y or 900
		fitL.Scale = math.clamp((vy - 70 - 16) / (590 + 66), 0.4, 1) -- the points chip sits above the tiles
		fitR.Scale = math.clamp((vy - 196 - 60) / 520, 0.45, 1)
	end
	refit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end
end
-- a tile: a picture (or emoji) and one word, a cream border, a red dot for news
local function tileBtn(parent, key, emoji, word, props, onClick)
	local b = Instance.new("TextButton")
	b.Text = ""
	b.BackgroundColor3 = PLUM
	b.TextColor3 = CREAM
	for k, v in pairs(props) do
		b[k] = v
	end
	corner(b, 18)
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness, stroke.ApplyStrokeMode = CREAM, 3, Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	local wide = b.Size.X.Offset > b.Size.Y.Offset * 1.6
	local iconSize = wide and UDim2.new(0.28, 0, 0.8, 0) or UDim2.new(0.7, 0, 0.56, 0)
	local iconAt = wide and UDim2.new(0.04, 0, 0.1, 0) or UDim2.new(0.15, 0, 0.06, 0)
	local id = Config.UI_ICONS and Config.UI_ICONS[key] or 0
	if id > 0 then
		local pic = Instance.new("ImageLabel")
		pic.BackgroundTransparency = 1
		pic.Image = "rbxassetid://" .. id
		pic.ScaleType = Enum.ScaleType.Fit
		pic.Size, pic.Position = iconSize, iconAt
		pic.Parent = b
	else
		label(b, { Name = "Emoji", Size = iconSize, Position = iconAt, Text = emoji })
	end
	label(b, { Name = "Word", Size = wide and UDim2.new(0.62, 0, 0.7, 0) or UDim2.new(0.92, 0, 0.26, 0), Position = wide and UDim2.new(0.34, 0, 0.15, 0) or UDim2.new(0.04, 0, 0.68, 0),
		Text = word, TextColor3 = b.TextColor3, TextXAlignment = wide and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center })
	local dot = frame(b, { Name = "Badge", Size = UDim2.fromOffset(34, 34), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -8, 0, 8), BackgroundColor3 = Color3.fromRGB(232, 60, 70), BackgroundTransparency = 0, Visible = false, ZIndex = 3 })
	corner(dot, 17)
	label(dot, { Name = "Count", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Text = "!", ZIndex = 4 })
	b.Parent = parent
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end
-- the red dot on a tile: a number or "!", or nil to hide it
local function setBadge(b, text)
	local dot = b and b:FindFirstChild("Badge")
	if dot then
		dot.Visible = text ~= nil and text ~= ""
		dot.Count.Text = text or ""
	end
end
local quick = tileBtn(menu, "quick", "\u{26A1}", "Quick Play", { Size = UDim2.fromOffset(310, 100), BackgroundColor3 = Color3.fromRGB(70, 209, 96), TextColor3 = NIGHT }, function()
	remotes.QuickPlay:FireServer()
end)
tileBtn(menu, "solo", "\u{25B6}", "Solo", { Size = UDim2.fromOffset(148, 146), Position = UDim2.fromOffset(0, 112) }, function()
	remotes.CreateParty:FireServer(true)
end)
tileBtn(menu, "party", "\u{1F388}", "Party", { Size = UDim2.fromOffset(148, 146), Position = UDim2.fromOffset(162, 112) }, function()
	remotes.CreateParty:FireServer(false)
end)
local charsBtn = tileBtn(menu, "characters", "\u{1F9D2}", "Characters", { Size = UDim2.fromOffset(148, 146), Position = UDim2.fromOffset(0, 268) })
local shopBtn = tileBtn(menu, "shop", "\u{1F6D2}", "Shop", { Size = UDim2.fromOffset(148, 146), Position = UDim2.fromOffset(162, 268) })
local questsBtn = tileBtn(menu, "quests", "\u{1F4DC}", "Quests", { Size = UDim2.fromOffset(148, 146), Position = UDim2.fromOffset(0, 424) })
-- (Plushies is the sixth tile, made with the Plushie Book below)
tileBtn(rightBar, "invite", "\u{2709}", "Invite", { Size = UDim2.fromOffset(104, 96), Position = UDim2.fromOffset(0, 0) }, invite)
local joinBox -- the friends' parties list (made below); the Join tile opens it
local joinOpen = false
local joinBtn = tileBtn(rightBar, "join", "\u{1F389}", "Join", { Size = UDim2.fromOffset(104, 96), Position = UDim2.fromOffset(0, 104) }, function()
	joinOpen = not joinOpen
	if joinBox then
		joinBox.Visible = joinOpen and menu.Visible
	end
end)
local helpBtn = tileBtn(rightBar, "help", "\u{2753}", "Help", { Size = UDim2.fromOffset(104, 96), Position = UDim2.fromOffset(0, 416) })
-- controller: Up jumps into the menu (or your party's buttons)
do
	Gamepad.hint(quick, "Up")
	Gamepad.bind(Enum.KeyCode.DPadUp, function()
		if menu.Visible then
			Gamepad.select(quick)
		end
	end)
end

-- ---------- the balance table (the experience's owner only) ----------
task.spawn(function()
	local tries = 0
	while player:GetAttribute("IsOwner") == nil and tries < 40 do
		tries += 1
		task.wait(0.25)
	end
	if not player:GetAttribute("IsOwner") then
		return
	end
	local panel = frame(gui, { Size = UDim2.fromOffset(640, 440), Position = UDim2.new(0.5, -320, 0.5, -220), Visible = false, ZIndex = 30 })
	corner(panel, 16)
	label(panel, { Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 8), Text = "\u{1F4CA} Host balance - real games so far", TextColor3 = PUMP, ZIndex = 31 })
	label(panel, { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 42), Text = "Aim: about 70% of games won on Easy, 50% Normal, 35% Hard, 20% Nightmare", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 31 })
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -20, 1, -120)
	scroll.Position = UDim2.fromOffset(10, 68)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 8
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.ZIndex = 31
	scroll.Parent = panel
	local rowsList = Instance.new("UIListLayout")
	rowsList.Padding = UDim.new(0, 4)
	rowsList.SortOrder = Enum.SortOrder.LayoutOrder
	rowsList.Parent = scroll
	local function fill()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextLabel") then
				c:Destroy()
			end
		end
		local ok, data = pcall(function()
			return remotes.GetBalance:InvokeServer()
		end)
		data = ok and data or {}
		local n = 0
		for mi, m in ipairs(Progress.MAPS) do
			for di, d in ipairs(Config.DIFFICULTY_ORDER) do
				local r = data[m.id .. "|" .. d]
				if r and r.games > 0 then
					n += 1
					local avg = r.won > 0 and math.floor(r.secs / r.won) or 0
					label(scroll, { Size = UDim2.new(1, -12, 0, 24), LayoutOrder = mi * 10 + di, TextScaled = false, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 32,
						Text = string.format("%s \u{00B7} %s: %d games, won %d (%d%%), kids out %d of %d, a win takes %d:%02d", m.name, Config.DIFFICULTY[d].name, r.games, r.won, math.floor(r.won / r.games * 100 + 0.5), r.escaped, r.kids, math.floor(avg / 60), avg % 60) })
				end
			end
		end
		if n == 0 then
			label(scroll, { Size = UDim2.new(1, -12, 0, 48), TextScaled = false, TextSize = 16, TextWrapped = true, ZIndex = 32, Text = "No games logged yet. Every finished game in the live Party House adds a line here (Studio games too, if Studio API access is on)." })
		end
	end
	button(panel, "\u{1F504} Refresh", { Size = UDim2.fromOffset(160, 40), Position = UDim2.new(0.5, -170, 1, -48), ZIndex = 31 }, fill)
	button(panel, "Close", { Size = UDim2.fromOffset(160, 40), Position = UDim2.new(0.5, 10, 1, -48), ZIndex = 31 }, function()
		panel.Visible = false
	end)
	button(gui, "\u{1F4CA} Balance", { Size = UDim2.fromOffset(130, 36), Position = UDim2.new(0, 372, 1, -52), ZIndex = 5 }, function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			fill()
		end
	end)
	-- window faces: click the middle of each window on the house
	local setup = frame(gui, { Size = UDim2.fromOffset(640, 100), Position = UDim2.new(0.5, -320, 0, 56), Visible = false, ZIndex = 30 })
	corner(setup, 14)
	label(setup, { Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 4), TextWrapped = true, ZIndex = 31,
		Text = "\u{1FA9F} Click the middle of each window on the house (up to 8). Then Save. Test makes the host peek in each." })
	local editingMode = false
	local function bar(text, x, action)
		button(setup, text, { Size = UDim2.fromOffset(140, 38), Position = UDim2.new(0, x, 1, -46), ZIndex = 31 }, function()
			if action == "done" then
				editingMode = false
				setup.Visible = false
			else
				remotes.PeekSetup:FireServer(action)
			end
		end)
	end
	bar("\u{1F4BE} Save", 16, "save")
	bar("\u{1F440} Test", 172, "test")
	bar("\u{1F5D1} Clear", 328, "clear")
	bar("Done", 484, "done")
	local _windowsBtn = button(gui, "\u{1FA9F} Windows", { Size = UDim2.fromOffset(130, 36), Position = UDim2.new(0, 512, 1, -52), ZIndex = 5, Visible = Config.WINDOW_SETUP == true }, function()
		editingMode = not editingMode
		setup.Visible = editingMode
		if editingMode then
			remotes.PeekSetup:FireServer("start")
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not editingMode or processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local house = workspace:FindFirstChild("LobbyHouse")
			if not house then
				return
			end
			local ray = workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { house }
			local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
			if hit then
				remotes.PeekSetup:FireServer("add", hit.Position)
			end
		end
	end)
end)

-- ---------- running in the Lobby: no stamina here ----------
do
	local WALK, RUN = 16, 28
	local running = false
	local function apply()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = running and RUN or WALK
		end
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
			running = true
			apply()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			running = false
			apply()
		end
	end)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		apply()
	end)
	Gamepad.bind(Enum.KeyCode.ButtonL2, function()
		running = true
		apply()
	end)
	Gamepad.bindRelease(Enum.KeyCode.ButtonL2, function()
		running = false
		apply()
	end)
	if UserInputService.TouchEnabled then
		local runBtn
		runBtn = button(gui, "\u{1F3C3} Run", { Size = UDim2.fromOffset(110, 50), Position = UDim2.new(1, -130, 1, -200), ZIndex = 5 }, function()
			running = not running
			runBtn.BackgroundColor3 = running and PUMP or PLUM
			apply()
		end)
	end
end

-- ---------- parties you can join (right) ----------
-- below the points, sound and music buttons (top right)
joinBox = frame(gui, { Size = UDim2.fromOffset(330, 400), Position = UDim2.new(1, -470, 0, 196), Visible = false })
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
-- the map: one button here; the map screen opens for the whole party together
local mapBtn = button(partyBox, "", { Size = UDim2.new(1, -40, 0, 80), Position = UDim2.fromOffset(20, 210), BackgroundColor3 = Color3.fromRGB(47, 107, 58) }, function()
	if not current then
		return
	end
	if amLeader then
		opt("mapScreen", true)
	else
		notice("Your party leader opens the map screen - then everyone votes together.")
	end
end)

local function img(id)
	return (id and id > 0) and ("rbxassetid://" .. id) or ""
end
local mapScreen = frame(gui, { Size = UDim2.fromOffset(940, 600), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Visible = false, ZIndex = 40 })
corner(mapScreen, 18)
local msScale = Instance.new("UIScale")
msScale.Parent = mapScreen
local function fitMapScreen()
	local vs = workspace.CurrentCamera.ViewportSize
	msScale.Scale = math.min(1, (vs.Y - 30) / 600, (vs.X - 20) / 940)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitMapScreen)
fitMapScreen()
label(mapScreen, { Size = UDim2.new(1, -40, 0, 40), Position = UDim2.fromOffset(20, 12), Text = "\u{1F5FA} Choose where to play", TextColor3 = PUMP, ZIndex = 41 })
label(mapScreen, { Size = UDim2.new(1, -40, 0, 24), Position = UDim2.fromOffset(20, 56), Text = "1. The leader picks a building     2. Everyone votes for a floor (ties go to the leader)", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 41 })
local buildingCards, floorCards = {}, {}
local function card(parent, x, y, w, h, onClick)
	local b = Instance.new("ImageButton")
	b.Size = UDim2.fromOffset(w, h)
	b.Position = UDim2.fromOffset(x, y)
	b.BackgroundColor3 = PLUM
	b.ScaleType = Enum.ScaleType.Crop
	b.ZIndex = 42
	b.Parent = parent
	corner(b, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 0
	stroke.Color = PUMP
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	local name = label(b, { Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 1, -66), BackgroundTransparency = 0.25, BackgroundColor3 = NIGHT, ZIndex = 43, Text = "" })
	corner(name, 8)
	local sub = label(b, { Size = UDim2.new(1, -16, 0, 26), Position = UDim2.new(0, 8, 1, -32), BackgroundTransparency = 0.25, BackgroundColor3 = NIGHT, ZIndex = 43, Text = "", TextColor3 = Color3.fromRGB(255, 210, 63) })
	corner(sub, 8)
	b.Activated:Connect(onClick)
	return { button = b, name = name, sub = sub, stroke = stroke }
end
-- the building cards share one row (900 wide): 3 at 290, more get narrower
local nb = #Progress.BUILDINGS
local bgap = nb <= 3 and 15 or 10
local bw = nb <= 3 and 290 or math.floor((900 - (nb - 1) * bgap) / nb)
for i, bld in ipairs(Progress.BUILDINGS) do
	buildingCards[bld.id] = card(mapScreen, 20 + (i - 1) * (bw + bgap), 92, bw, 190, function()
		if amLeader then
			opt("building", bld.id)
		else
			notice("The leader picks the building - you vote for the floor.")
		end
	end)
end
for i = 1, 4 do
	floorCards[i] = card(mapScreen, 20 + (i - 1) * 305, 300, 290, 220, function()
		local id = floorCards[i].mapId
		if id then
			remotes.VoteMap:FireServer(id)
		end
	end)
end
Gamepad.panel(mapScreen, function()
	return floorCards[1] and floorCards[1].button or nil
end, function() end)
local msDone = button(mapScreen, "\u{2705} Done", { Size = UDim2.fromOffset(200, 48), Position = UDim2.new(1, -220, 1, -62), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 42 }, function()
	opt("mapScreen", false)
end)
local msWait = label(mapScreen, { Size = UDim2.new(1, -500, 0, 40), Position = UDim2.new(0, 20, 1, -58), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 41 })
-- Tower Run: every floor of the building in one game (the leader switches it on)
local towerBtn = button(mapScreen, "", { Size = UDim2.fromOffset(220, 48), Position = UDim2.new(1, -460, 1, -62), BackgroundColor3 = PLUM, ZIndex = 42 }, function()
	if current and amLeader then
		opt("tower", not current.tower)
	elseif current then
		notice("The leader can switch Tower Run on: all the floors in one game.")
	end
end)
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
label(partyBox, { Size = UDim2.new(1, -40, 0, 20), Position = UDim2.fromOffset(20, 472), Text = "\u{1F46B} Play with a Roblox friend: +10% points!", TextColor3 = Color3.fromRGB(123, 227, 107) })
Gamepad.hint(startBtn, "Up")
Gamepad.bind(Enum.KeyCode.DPadUp, function()
	if partyBox.Visible and not mapScreen.Visible then
		Gamepad.select(startBtn.Visible and startBtn or mapBtn)
	end
end)
button(partyBox, "Leave", { Size = UDim2.fromOffset(130, 48), Position = UDim2.new(1, -150, 1, -64) }, function()
	remotes.LeaveParty:FireServer()
end)

local function paintParty(p)
	current = p
	inParty = p ~= nil
	partyBox.Visible = p ~= nil
	menu.Visible = p == nil
	rightBar.Visible = p == nil
	joinBox.Visible = p == nil and joinOpen
	if not p then
		return
	end
	amLeader = p.leaderId == player.UserId
	partyTitle.Text = p.max == 1 and "Solo game - choose a floor, then Start" or ((amLeader and "Your party" or (p.leader .. "'s party")) .. "  (" .. #p.members .. "/" .. p.max .. ")")
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
	-- the chosen map on the party panel
	local ci = Progress.mapIndex(p.chosen or "partyhouse")
	mapBtn.Text = (amLeader and "\u{1F5FA} Tap to choose a map" or "\u{1F5FA} The leader chooses a map") .. (p.tower and "  \u{00B7} \u{1F5FC} Tower Run" or "")
	local _ = ci
	-- the map screen, the same for everyone in the party
	mapScreen.Visible = p.mapScreen == true
	msDone.Visible = amLeader
	towerBtn.Text = p.tower and "\u{1F5FC} Tower Run: ON" or "\u{1F5FC} Tower Run: off"
	towerBtn.BackgroundColor3 = p.tower and Color3.fromRGB(70, 140, 220) or PLUM
	msWait.Text = amLeader and "Tap Done when everyone has voted." or ("Waiting for " .. p.leader .. " to tap Done...")
	for _, bld in ipairs(Progress.BUILDINGS) do
		local c = buildingCards[bld.id]
		local total, open = 0, 0
		for _, m in ipairs(Progress.MAPS) do
			if m.building == bld.id then
				total += 1
				if m.ready and p.unlocked and p.unlocked[m.id] then
					open += 1
				end
			end
		end
		c.button.Image = img(Config.MAP_IMAGES["building-" .. bld.id])
		c.name.Text = bld.name
		c.sub.Text = open .. " of " .. total .. " floors open"
		c.stroke.Thickness = p.building == bld.id and 5 or 0
	end
	local floors = {}
	for _, m in ipairs(Progress.MAPS) do
		if m.building == (p.building or "partyhouse") then
			table.insert(floors, m)
		end
	end
	-- three floors fill the row; four (with the Basement) share it
	local wide = #floors >= 4 and 214 or 290
	for i = 1, 4 do
		local c, m = floorCards[i], floors[i]
		c.button.Size = UDim2.fromOffset(wide, 220)
		c.button.Position = UDim2.fromOffset(20 + (i - 1) * (wide + 10 + (wide == 290 and 5 or 0)), 300)
		c.button.Visible = m ~= nil
		c.mapId = nil
		if m then
			local open = m.ready and p.unlocked and p.unlocked[m.id]
			local voters = {}
			for uid, vote in pairs(p.votes or {}) do
				if vote == m.id then
					for _, mem in ipairs(p.members) do
						if tostring(mem.userId) == uid then
							table.insert(voters, mem.name)
						end
					end
				end
			end
			c.mapId = open and m.id or nil
			c.button.Image = img(Config.MAP_IMAGES[m.id] or Config.MAP_IMAGES["building-" .. m.building])
			c.button.ImageTransparency = open and 0 or 0.6
			c.name.Text = m.name
			c.sub.Text = not m.ready and "Coming soon" or (not open and "\u{1F512} Locked")
				or (#voters .. (#voters == 1 and " vote" or " votes") .. (#voters > 0 and (": " .. table.concat(voters, ", ")) or ""))
			c.stroke.Thickness = myVote == m.id and 5 or (p.chosen == m.id and 3 or 0)
			c.stroke.Color = myVote == m.id and PUMP or Color3.fromRGB(123, 227, 107)
		end
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
	setBadge(joinBtn, shown > 0 and tostring(shown) or nil) -- how many parties you could join
	paintParty(mine)
end)

-- ---------- my profile (points, bag, characters) ----------
local profile = { points = 0, inv = {}, loadout = {}, xp = {}, picks = {}, unlocked = {} }
-- points: a chip on top of the tile column (it shrinks with the tiles on small screens)
local pointsLabel = label(menu, { Size = UDim2.fromOffset(200, 50), Position = UDim2.fromOffset(0, -62), Text = "\u{2B50} 0", BackgroundColor3 = NIGHT, BackgroundTransparency = 0.1 })
do
	corner(pointsLabel, 25)
	local ring = Instance.new("UIStroke")
	ring.Color, ring.Thickness, ring.ApplyStrokeMode = CREAM, 3, Enum.ApplyStrokeMode.Border
	ring.Parent = pointsLabel
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
	pad.Parent = pointsLabel
end
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
	pointsLabel.Text = "\u{2B50} " .. tostring(profile.points or 0)
	if repaintShop then
		repaintShop()
	end
	if repaintChars then
		repaintChars()
	end
end
player:GetAttributeChangedSignal("ProfileJson"):Connect(readProfile)
do
	-- every pop-up panel: dark glass with a cream border, and only one open at
	-- a time (opening one closes the others). A pop-up is a panel on the
	-- screen that starts hidden and sits above the rest (ZIndex 10+), or the
	-- emote picker.
	local popups = {}
	local function isPopup(f)
		if not f:IsA("Frame") or f.BackgroundTransparency > 0.9 then
			return false
		end
		if f.Name == "Emotes" then
			return true
		end
		return f.ZIndex >= 10 and f.Size.X.Offset >= 300 and f.Size.Y.Offset >= 200
	end
	-- text inside a pop-up built by hand (not with label / button): the same
	-- clean look - capped size, Builder Sans unless an orange title, no light buttons
	local function clean(o)
		if not (o:IsA("TextLabel") or o:IsA("TextButton")) or o:FindFirstChildOfClass("UITextSizeConstraint") then
			return
		end
		local title = o.TextColor3 == PUMP
		if o.Font == Enum.Font.FredokaOne and not title then
			o.Font = BODY_FONT
		end
		if o:IsA("TextButton") and o.BackgroundColor3 == CREAM then
			o.BackgroundColor3, o.TextColor3 = PLUM, CREAM
		end
		capText(o, title and Config.UI_TEXT.title or Config.UI_TEXT.body)
	end
	local function adopt(f)
		if popups[f] or not isPopup(f) then
			return
		end
		popups[f] = true
		for _, d in ipairs(f:GetDescendants()) do
			clean(d)
		end
		f.DescendantAdded:Connect(function(d)
			task.defer(clean, d)
		end)
		if not f:FindFirstChildOfClass("UIStroke") then
			local edge = Instance.new("UIStroke")
			edge.Color, edge.Thickness, edge.ApplyStrokeMode = CREAM, 3, Enum.ApplyStrokeMode.Border
			edge.Parent = f
		end
		if not f:FindFirstChildOfClass("UICorner") then
			corner(f, 20)
		end
		local function closeOthers()
			if f.Visible then
				for other in pairs(popups) do
					if other ~= f and other.Parent and other.Visible then
						other.Visible = false
					end
				end
			end
		end
		f:GetPropertyChangedSignal("Visible"):Connect(closeOthers)
		closeOthers() -- a pop-up made already open (the invite list)
	end
	task.defer(function()
		for _, c in ipairs(gui:GetChildren()) do
			adopt(c)
		end
		gui.ChildAdded:Connect(function(c)
			task.defer(adopt, c)
		end)
	end)
end
do
	-- emotes in the Lobby too (G / the right stick), under the points
	local emoteBtn = tileBtn(rightBar, "emote", "\u{1F604}", "Emote", { Size = UDim2.fromOffset(104, 96), Position = UDim2.fromOffset(0, 208) })
	require(ReplicatedStorage.Shared.Emotes).mount(gui, emoteBtn, UDim2.new(1, -580, 0, 300))
	-- the escape photo setting (the only way back on once it is Off)
	local MODES = { every = "Every escape", daily = "Daily", off = "Off" }
	local NEXT = { every = "daily", daily = "off", off = "every" }
	local photoBtn = tileBtn(rightBar, "photo", "\u{1F4F8}", "Photo", { Size = UDim2.fromOffset(104, 96), Position = UDim2.fromOffset(0, 312) }, function()
		remotes:WaitForChild("SetPhoto"):FireServer(NEXT[player:GetAttribute("PhotoMode") or "daily"])
	end)
	local function paintPhoto()
		photoBtn.Word.Text = "Photo: " .. (MODES[player:GetAttribute("PhotoMode") or "daily"] or "Daily")
	end
	player:GetAttributeChangedSignal("PhotoMode"):Connect(paintPhoto)
	paintPhoto()
end
do
	-- the Plushie Book: a page for every floor's lost plushie - found ones
	-- show their animal and name, missing ones say which floor hides them
	local book = frame(gui, { Size = UDim2.fromOffset(820, 540), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Visible = false, ZIndex = 20 })
	corner(book, 18)
	local fit = Instance.new("UIScale")
	fit.Parent = book
	local function refit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		fit.Scale = math.min(1, (vp.X - 20) / 820, (vp.Y - 20) / 540)
	end
	refit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end
	local title = label(book, { Size = UDim2.new(1, -40, 0, 40), Position = UDim2.fromOffset(20, 12), Text = "\u{1F9F8} Plushie Book", TextColor3 = PUMP, ZIndex = 21 })
	local sub = label(book, { Size = UDim2.new(1, -40, 0, 22), Position = UDim2.fromOffset(20, 54), Text = "", ZIndex = 21 })
	local grid = Instance.new("ScrollingFrame")
	grid.Size = UDim2.new(1, -40, 1, -150)
	grid.Position = UDim2.fromOffset(20, 84)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 8
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.CanvasSize = UDim2.new()
	grid.ZIndex = 21
	grid.Parent = book
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(150, 120)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	local floorName = {}
	for _, m in ipairs(Progress.MAPS) do
		floorName[m.id] = m.name
	end
	local spinning = {} -- [viewport] = plushie model, turned slowly while the book is open
	RunService.RenderStepped:Connect(function()
		if book.Visible then
			local a = os.clock() * 0.8
			for _, m in pairs(spinning) do
				if m.Parent then
					m:PivotTo(CFrame.Angles(0, math.pi + math.sin(a) * 0.9, 0))
				end
			end
		end
	end)
	local function paint()
		for _, c in ipairs(grid:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		table.clear(spinning)
		local found = 0
		local have = profile.plush or {}
		for i, p in ipairs(Config.PLUSHIES) do
			local got = have[p.map] == true
			if got then
				found += 1
			end
			local card = frame(grid, { LayoutOrder = i, BackgroundColor3 = got and Color3.fromRGB(70, 50, 100) or Color3.fromRGB(40, 30, 55), ZIndex = 22 })
			corner(card, 12)
			-- the plushie itself, turning slowly (a dark shape until found)
			local vf = Instance.new("ViewportFrame")
			vf.Size = UDim2.new(1, 0, 0, 56)
			vf.Position = UDim2.fromOffset(0, 2)
			vf.BackgroundTransparency = 1
			vf.Ambient = Color3.fromRGB(170, 160, 180)
			vf.LightDirection = Vector3.new(-0.4, -1, -0.6)
			vf.ImageColor3 = got and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
			vf.ZIndex = 23
			vf.Parent = card
			local vcam = Instance.new("Camera")
			vcam.FieldOfView = 30
			vcam.Parent = vf
			vf.CurrentCamera = vcam
			local okP, plush = pcall(function()
				return require(ReplicatedStorage.Shared.Plushies).build(p, CFrame.new(), true)
			end)
			if okP and plush then
				plush.Parent = vf
				spinning[vf] = plush
				vcam.CFrame = CFrame.lookAt(Vector3.new(0, 1.6, -9.5), Vector3.new(0, 1.35, 0))
			end
			if not got then
				label(card, { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0.5, -15, 0, 14), Text = "\u{2753}", ZIndex = 24 })
			end
			label(card, { Size = UDim2.new(1, -10, 0, 34), Position = UDim2.fromOffset(5, 58), Text = got and p.name or "Lost somewhere in", TextWrapped = true, TextColor3 = got and CREAM or Color3.fromRGB(180, 170, 195), ZIndex = 23 })
			label(card, { Size = UDim2.new(1, -10, 0, 20), Position = UDim2.fromOffset(5, 94), Text = floorName[p.map] or p.map, TextColor3 = got and Color3.fromRGB(255, 210, 63) or Color3.fromRGB(150, 140, 170), ZIndex = 23 })
		end
		sub.Text = found .. " of " .. #Config.PLUSHIES .. " found" .. (found == #Config.PLUSHIES and " - you found them all!" or " - one is hidden on every floor. Look closely for a little sparkle!")
	end
	local _ = title
	button(book, "Close", { Size = UDim2.fromOffset(160, 44), Position = UDim2.new(0.5, -80, 1, -56), ZIndex = 22 }, function()
		book.Visible = false
	end)
	local bookBtn = tileBtn(menu, "plushies", "\u{1F9F8}", "Plushies", { Size = UDim2.fromOffset(148, 146), Position = UDim2.fromOffset(162, 424) })
	bookBtn.Activated:Connect(function()
		paint()
		book.Visible = not book.Visible
	end)
	player:GetAttributeChangedSignal("ProfileJson"):Connect(function()
		if book.Visible then
			task.defer(paint)
		end
	end)
end
do
	-- the Halloween Candy Corn Hunt: a banner at the bottom that opens the
	-- Candy Shop (laid out like the Boost Shop: boosts and the event skin for
	-- candy corns). The candy-corn picture is the Candy Corn boost's own.
	local e = Config.EVENT
	if e and os.time() < (e.shopUntil or e.ends) then
		local CORN = Config.BOOST_IMAGES and Config.BOOST_IMAGES.candy or 0
		local function cornPic(parent, size, pos, z)
			if CORN > 0 then
				local pic = Instance.new("ImageLabel")
				pic.BackgroundTransparency = 1
				pic.Image = "rbxassetid://" .. CORN
				pic.Size = UDim2.fromOffset(size, size)
				pic.Position = pos
				pic.ZIndex = z
				pic.Parent = parent
				return pic
			end
			return nil
		end
		local bannerHolder = Instance.new("Frame")
		bannerHolder.BackgroundTransparency = 1
		bannerHolder.AnchorPoint = Vector2.new(0.5, 1)
		bannerHolder.Position = UDim2.new(0.5, 0, 1, -8)
		bannerHolder.Size = UDim2.fromOffset(540, 38)
		bannerHolder.ZIndex = 5
		bannerHolder.Parent = gui
		cornPic(bannerHolder, 38, UDim2.fromOffset(0, 0), 6)
		local banner = button(bannerHolder, "", { Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -42, 1, 0), BackgroundColor3 = Color3.fromRGB(40, 22, 62), TextColor3 = Color3.fromRGB(255, 180, 70), ZIndex = 5 })
		local cshop = frame(gui, { Size = UDim2.fromOffset(620, 620), Position = UDim2.new(0.5, -310, 0.5, -310), Visible = false, ZIndex = 10 })
		corner(cshop, 18)
		cornPic(cshop, 46, UDim2.fromOffset(16, 6), 11)
		local title = label(cshop, { Size = UDim2.new(1, -90, 0, 40), Position = UDim2.fromOffset(70, 10), TextColor3 = PUMP, ZIndex = 11 })
		label(cshop, { Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 52), Text = "Spend candy corns from the games. The Candy Corn Collector badge counts every corn you find.", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 11 })
		local rows, skinRows = {}, {}
		local function row(i, picId, iconText, name, say)
			local r = frame(cshop, { Size = UDim2.new(1, -24, 0, 64), Position = UDim2.fromOffset(12, 80 + (i - 1) * 70), BackgroundColor3 = PLUM, BackgroundTransparency = 0.3, ZIndex = 11 })
			corner(r, 12)
			if (picId or 0) > 0 then
				local pic = Instance.new("ImageLabel")
				pic.BackgroundTransparency = 1
				pic.Image = "rbxassetid://" .. picId
				pic.Size = UDim2.fromOffset(52, 52)
				pic.Position = UDim2.fromOffset(5, 6)
				pic.ZIndex = 12
				pic.Parent = r
			else
				label(r, { Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(8, 9), Text = iconText, ZIndex = 12 })
			end
			label(r, { Size = UDim2.fromOffset(250, 26), Position = UDim2.fromOffset(64, 6), Text = name, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
			label(r, { Size = UDim2.fromOffset(300, 22), Position = UDim2.fromOffset(64, 34), Text = say, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(205, 190, 225), ZIndex = 12 })
			local owned = label(r, { Size = UDim2.fromOffset(100, 20), Position = UDim2.fromOffset(372, 22), Text = "", ZIndex = 12 })
			return r, owned
		end
		local function buyButton(r, price, onClick)
			local b = button(r, "Buy " .. price, { Size = UDim2.fromOffset(84, 40), Position = UDim2.fromOffset(476, 12), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 12 }, onClick)
			local pic = cornPic(r, 30, UDim2.fromOffset(562, 17), 12)
			if pic then
				b:GetPropertyChangedSignal("Visible"):Connect(function()
					pic.Visible = b.Visible
				end)
			end
			return b
		end
		local i = 0
		for _, id in ipairs(Progress.BOOST_ORDER) do
			local price = e.shop and e.shop[id]
			local boost = Progress.BOOSTS[id]
			if price and boost then
				i += 1
				local r, owned = row(i, Config.BOOST_IMAGES and Config.BOOST_IMAGES[id], boost.icon, boost.name, boost.say)
				buyButton(r, price, function()
					remotes:WaitForChild("CornShop"):FireServer(id)
				end)
				rows[id] = owned
			end
		end
		for _, skin in ipairs(Config.SKINS or {}) do
			if skin.corn and not skin.hidden then
				i += 1
				local r, owned = row(i, skin.icon, "\u{2728}", skin.name .. " skin", "A Halloween look for " .. string.upper(string.sub(skin.skill, 1, 1)) .. string.sub(skin.skill, 2) .. " - yours for good")
				local b = buyButton(r, skin.corn, function()
					remotes:WaitForChild("CornShop"):FireServer("skin:" .. skin.id)
				end)
				skinRows[skin] = { owned = owned, buy = b }
			end
		end
		button(cshop, "Close", { Size = UDim2.fromOffset(160, 44), Position = UDim2.new(0.5, -80, 1, -54), ZIndex = 11 }, function()
			cshop.Visible = false
		end)
		banner.Activated:Connect(function()
			cshop.Visible = not cshop.Visible
		end)
		local function paint()
			local ok, data = pcall(function()
				return HttpService:JSONDecode(player:GetAttribute("ProfileJson") or "{}")
			end)
			data = ok and data or {}
			local st = data.stats or {}
			local n = st.corn or 0
			local have = n + (st.cornGift or 0) - (st.cornSpent or 0)
			local earned = data.skinsEarned or {}
			local inv = data.inv or {}
			for id, owned in pairs(rows) do
				owned.Text = "You have " .. (inv[id] or 0)
			end
			local skinGoal
			for skin, r in pairs(skinRows) do
				local mine = earned[skin.id] == true
				r.owned.Text = mine and "\u{2705} Yours!" or ""
				r.buy.Visible = not mine
				if not mine then
					skinGoal = skin
				end
			end
			title.Text = "Candy Shop  \u{00B7}  " .. have .. " candy corns to spend"
			if os.time() >= e.ends then
				banner.Text = "Candy Shop: " .. have .. " candy corns to spend (until 8 Nov)"
			elseif skinGoal then
				banner.Text = "Candy corns: " .. have .. " to spend  \u{00B7}  " .. skinGoal.name .. " " .. skinGoal.corn .. "  \u{00B7}  Shop"
			else
				banner.Text = "Candy corns: " .. n .. " found, " .. have .. " to spend  \u{00B7}  Shop"
			end
		end
		paint()
		player:GetAttributeChangedSignal("ProfileJson"):Connect(paint)
	end

	-- the owner's gift panel: candy corns or points for anyone in this Lobby
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId and e then
		local giftBtn = button(gui, "\u{1F381} Gift", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 652, 1, -14), Size = UDim2.fromOffset(96, 38), BackgroundColor3 = Color3.fromRGB(47, 107, 58), ZIndex = 5 })
		local panel = frame(gui, { Size = UDim2.fromOffset(560, 420), Position = UDim2.new(0.5, -280, 0.5, -210), Visible = false, ZIndex = 10 })
		corner(panel, 18)
		label(panel, { Size = UDim2.new(1, -20, 0, 36), Position = UDim2.fromOffset(10, 8), Text = "\u{1F381} Gifts (only you see this)", TextColor3 = PUMP, ZIndex = 11 })
		label(panel, { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 44), Text = "For players in this Lobby server. Corns go to spend (not the badge).", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 11 })
		local giftList = Instance.new("ScrollingFrame")
		giftList.BackgroundTransparency = 1
		giftList.Position = UDim2.fromOffset(10, 70)
		giftList.Size = UDim2.new(1, -20, 1, -130)
		giftList.AutomaticCanvasSize = Enum.AutomaticSize.Y
		giftList.CanvasSize = UDim2.new()
		giftList.ScrollBarThickness = 6
		giftList.ZIndex = 11
		giftList.Parent = panel
		local ll = Instance.new("UIListLayout")
		ll.Padding = UDim.new(0, 6)
		ll.Parent = giftList
		local function fill()
			for _, c in ipairs(giftList:GetChildren()) do
				if c:IsA("GuiObject") then
					c:Destroy()
				end
			end
			for _, p in ipairs(Players:GetPlayers()) do
				local r = frame(giftList, { Size = UDim2.new(1, -8, 0, 44), BackgroundColor3 = PLUM, BackgroundTransparency = 0.3, ZIndex = 12 })
				corner(r, 10)
				label(r, { Size = UDim2.fromOffset(150, 36), Position = UDim2.fromOffset(8, 4), Text = p.DisplayName, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13 })
				local x = 166
				for _, a in ipairs(e.giftCorn or {}) do
					button(r, "+" .. a .. " corns", { Size = UDim2.fromOffset(88, 34), Position = UDim2.fromOffset(x, 5), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 13 }, function()
						remotes:WaitForChild("OwnerGift"):FireServer(p.UserId, "corn", a)
					end)
					x += 92
				end
				for _, a in ipairs(e.giftPoints or {}) do
					button(r, "+" .. a .. " pts", { Size = UDim2.fromOffset(88, 34), Position = UDim2.fromOffset(x, 5), BackgroundColor3 = Color3.fromRGB(0, 140, 100), ZIndex = 13 }, function()
						remotes:WaitForChild("OwnerGift"):FireServer(p.UserId, "points", a)
					end)
					x += 92
				end
			end
		end
		button(panel, "Close", { Size = UDim2.fromOffset(160, 44), Position = UDim2.new(0.5, -80, 1, -54), ZIndex = 11 }, function()
			panel.Visible = false
		end)
		giftBtn.Activated:Connect(function()
			panel.Visible = not panel.Visible
			if panel.Visible then
				fill()
			end
		end)
	end
end

-- Roblox's own Robux icon (instead of "R$"), in a space kept at a button's right edge
local function robuxIcon(b, size)
	local pad = b:FindFirstChildOfClass("UIPadding")
	if pad then
		pad.PaddingRight = UDim.new(0, size + 10)
	end
	local pic = Instance.new("ImageLabel")
	pic.BackgroundTransparency = 1
	pic.Image = "rbxasset://textures/ui/common/robux.png"
	pic.Size = UDim2.fromOffset(size, size)
	pic.Position = UDim2.new(1, 4, 0.5, -size / 2)
	pic.ZIndex = b.ZIndex + 1
	pic.Parent = b
	return pic
end

-- ---------- the shop ----------
local shop = frame(gui, { Size = UDim2.fromOffset(620, 610), Position = UDim2.new(0.5, -310, 0.5, -305), Visible = false, ZIndex = 10 })
corner(shop, 18)
local shopTitle = label(shop, { Size = UDim2.new(1, -40, 0, 40), Position = UDim2.fromOffset(20, 10), Text = "\u{1F6D2} Boost Shop", TextColor3 = PUMP, ZIndex = 11 })
label(shop, { Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 50), Text = "+ buys, - sells back. Equip up to " .. Progress.MAX_BOOSTS .. " (two of the same is fine) for your next game.", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 11 })
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
	label(row, { Size = UDim2.fromOffset(205, 26), Position = UDim2.fromOffset(60, 6), Text = b.name, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
	label(row, { Size = UDim2.fromOffset(205, 22), Position = UDim2.fromOffset(60, 34), Text = b.say, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(205, 190, 225), ZIndex = 12 })
	-- everything on the right sits inside the row: have, price, + (buy), - (sell), Robux, Equip
	local owned = label(row, { Size = UDim2.fromOffset(56, 40), Position = UDim2.fromOffset(268, 12), Text = "", ZIndex = 12 })
	label(row, { Size = UDim2.fromOffset(60, 40), Position = UDim2.fromOffset(326, 12), Text = b.price .. " \u{2B50}", TextColor3 = Color3.fromRGB(255, 210, 63), ZIndex = 12 })
	button(row, "+", { Font = Enum.Font.GothamBlack, Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(388, 12), BackgroundColor3 = Color3.fromRGB(47, 140, 70), ZIndex = 12 }, function()
		remotes.BuyBoost:FireServer(id)
	end)
	local minus = button(row, "-", { Font = Enum.Font.GothamBlack, Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(430, 12), BackgroundColor3 = Color3.fromRGB(150, 60, 70), ZIndex = 12 }, function()
		remotes.SellBoost:FireServer(id)
	end)
	local productId = Config.ROBUX_PRODUCTS[id] or 0
	if productId > 0 then
		local rb = button(row, "", { Size = UDim2.fromOffset(44, 40), Position = UDim2.fromOffset(472, 12), BackgroundColor3 = Color3.fromRGB(0, 176, 111), ZIndex = 12 }, function()
			MarketplaceService:PromptProductPurchase(player, productId)
		end)
		local pic = robuxIcon(rb, 26)
		pic.Position = UDim2.new(0.5, -13, 0.5, -13) -- the icon alone, in the middle
		rb:FindFirstChildOfClass("UIPadding").PaddingRight = UDim.new(0, 8)
	end
	-- Equip: each tap packs one more (up to what you have and the limit); then empties
	local take = button(row, "", { Size = UDim2.fromOffset(72, 40), Position = UDim2.fromOffset(518, 12), ZIndex = 12 }, function()
		local list, mine = {}, 0
		for _, x in ipairs(profile.loadout or {}) do
			if x == id then
				mine += 1
			end
			table.insert(list, x)
		end
		local have = (profile.inv and profile.inv[id]) or 0
		if mine < have and #list < Progress.MAX_BOOSTS then
			table.insert(list, id)
		elseif mine > 0 then
			local kept = {}
			for _, x in ipairs(list) do
				if x ~= id then
					table.insert(kept, x)
				end
			end
			list = kept
		else
			notice("You can take " .. Progress.MAX_BOOSTS .. " boosts. Tap Equip on one to put it back first.")
			return
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
		r.owned.Text = "Have\n" .. n
		local mine = 0
		for _, x in ipairs(profile.loadout or {}) do
			if x == id then
				mine += 1
			end
		end
		r.take.Text = mine == 0 and "Equip" or mine == 1 and "\u{2705} Equipped" or ("\u{2705} x" .. mine)
		r.take.BackgroundColor3 = mine > 0 and Color3.fromRGB(47, 107, 58) or PLUM
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
	packedText.Text = #names > 0 and ("Next game: " .. table.concat(names, " + ") .. "  (tap Equipped to put back)") or "Next game: nothing equipped yet"

end
shopBtn.Activated:Connect(function()
	shop.Visible = true
end)
Gamepad.panel(shop)
remotes.OpenShop.OnClientEvent:Connect(function()
	shop.Visible = true
end)

-- ---------- characters and the skill ladder ----------
local chars = frame(gui, { Size = UDim2.fromOffset(900, 560), Position = UDim2.new(0.5, -450, 0.5, -280), Visible = false, ZIndex = 10 })
corner(chars, 18)
label(chars, { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 10), Text = "Characters & skill ladder", TextColor3 = PUMP, ZIndex = 11 })
-- left: the character in 3D (drag to turn) and what their skill does
local charName = label(chars, { Size = UDim2.fromOffset(230, 30), Position = UDim2.fromOffset(14, 54), Text = "", TextColor3 = PUMP, ZIndex = 11 })
local view = Instance.new("ViewportFrame")
view.Size = UDim2.fromOffset(230, 268)
view.Position = UDim2.fromOffset(14, 88)
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
local skillAbout = label(chars, { Size = UDim2.fromOffset(230, 100), Position = UDim2.fromOffset(14, 404), TextScaled = true, TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 11 })
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 16
	fit.Parent = skillAbout
end
-- right: picking a character, their level and the skill ladder
local right = frame(chars, { Size = UDim2.new(1, -256, 1, -60), Position = UDim2.fromOffset(250, 0), BackgroundTransparency = 1, ZIndex = 11 })
local charRow = frame(right, { Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 56), BackgroundTransparency = 1, ZIndex = 11 })
local charGrid = Instance.new("UIGridLayout")
charGrid.CellSize = UDim2.fromOffset(72, 64)
charGrid.CellPadding = UDim2.fromOffset(6, 0)
charGrid.Parent = charRow
local selected = Config.SKILLS[1].id
-- the owner's test buttons: jump the shown character to a level (only you see them)
if (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId) or game:GetService("RunService"):IsStudio() then
	local testRow = frame(chars, { Size = UDim2.fromOffset(240, 34), Position = UDim2.fromOffset(10, 514), BackgroundTransparency = 1, ZIndex = 11 })
	label(testRow, { Size = UDim2.fromOffset(54, 30), Position = UDim2.fromOffset(0, 2), Text = "\u{1F9EA} Lv", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 12 })
	for i, lv in ipairs({ 1, 5, 10, 15, 20 }) do
		button(testRow, tostring(lv), { Size = UDim2.fromOffset(34, 30), Position = UDim2.fromOffset(56 + (i - 1) * 37, 2), BackgroundColor3 = Color3.fromRGB(110, 70, 30), ZIndex = 12 }, function()
			notice("\u{1F9EA} Setting " .. selected .. " to level " .. lv .. "...")
			remotes:WaitForChild("OwnerSetLevel"):FireServer(selected, lv)
		end)
	end
end
local charBtns = {}
for _, sk in ipairs(Config.SKILLS) do
	charBtns[sk.id] = button(charRow, (Config.PORTRAITS[sk.id] or 0) > 0 and "" or sk.icon, { BackgroundColor3 = sk.color, ZIndex = 12 }, function()
		selected = sk.id
		repaintChars()
	end)
	if (Config.PORTRAITS[sk.id] or 0) > 0 then
		local face = Instance.new("ImageLabel")
		face.Size = UDim2.new(1, -4, 1, -4)
		face.Position = UDim2.fromOffset(2, 2)
		face.BackgroundTransparency = 1
		face.ScaleType = Enum.ScaleType.Crop
		face.Image = "rbxassetid://" .. Config.PORTRAITS[sk.id]
		face.ZIndex = 13
		face.Parent = charBtns[sk.id]
		corner(face, 10)
	end
end
local charTitle = label(right, { Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 128), Text = "", ZIndex = 11 })
local xpBack = frame(right, { Size = UDim2.new(1, -40, 0, 14), Position = UDim2.fromOffset(20, 164), BackgroundColor3 = Color3.fromRGB(18, 10, 27), BackgroundTransparency = 0, ZIndex = 11 })
corner(xpBack, 7)
local xpFill = frame(xpBack, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(123, 227, 107), BackgroundTransparency = 0, ZIndex = 12 })
corner(xpFill, 7)
local ladder = {}
local ladderScroll = Instance.new("ScrollingFrame")
ladderScroll.Size = UDim2.fromOffset(640, 204)
ladderScroll.Position = UDim2.fromOffset(0, 186)
ladderScroll.BackgroundTransparency = 1
ladderScroll.BorderSizePixel = 0
ladderScroll.ScrollBarThickness = 8
ladderScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 138, 31)
ladderScroll.CanvasSize = UDim2.fromOffset(0, (Progress.MAX_LEVEL - 1) * 68)
ladderScroll.ZIndex = 11
ladderScroll.Parent = right
for level = 2, Progress.MAX_LEVEL do
	local y = (level - 2) * 68
	local tag = label(ladderScroll, { Size = UDim2.fromOffset(70, 56), Position = UDim2.fromOffset(16, y), Text = "Lv " .. level, ZIndex = 12 })
	local a = button(ladderScroll, "", { Size = UDim2.fromOffset(265, 56), Position = UDim2.fromOffset(92, y), ZIndex = 12 })
	local b = button(ladderScroll, "", { Size = UDim2.fromOffset(265, 56), Position = UDim2.fromOffset(364, y), ZIndex = 12 })
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
-- arrows to step through the characters
local function stepChar(d)
	local i = 1
	for k, sk in ipairs(Config.SKILLS) do
		if sk.id == selected then
			i = k
		end
	end
	selected = Config.SKILLS[(i - 1 + d) % #Config.SKILLS + 1].id
	repaintChars()
end
button(chars, "\u{25C0}", { Size = UDim2.fromOffset(56, 36), Position = UDim2.fromOffset(14, 362), ZIndex = 12 }, function()
	stepChar(-1)
end)
button(chars, "\u{25B6}", { Size = UDim2.fromOffset(56, 36), Position = UDim2.fromOffset(188, 362), ZIndex = 12 }, function()
	stepChar(1)
end)
-- choices are for keeps; a reset clears this character's whole ladder
button(right, "\u{1F504} Reset upgrades: " .. Config.RESET_POINTS .. " \u{2B50}", { Size = UDim2.fromOffset(265, 34), Position = UDim2.fromOffset(92, 448), BackgroundColor3 = Color3.fromRGB(150, 60, 70), ZIndex = 11 }, function()
	remotes.ResetLadder:FireServer(selected, "points")
end)
-- skins: the plain character, then each skin for it (Game Passes)
local skinRow = frame(right, { Size = UDim2.new(1, -20, 0, 46), Position = UDim2.fromOffset(10, 396), BackgroundTransparency = 1, ZIndex = 11 })
local skinOwned = {}
local function paintSkins()
	for _, c in ipairs(skinRow:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local mine = {}
	for _, skin in ipairs(Config.SKINS or {}) do
		if skin.skill == selected and not skin.hidden and ((skin.pass or 0) > 0 or skin.corn or skinOwned[skin.id]) then
			table.insert(mine, skin)
		end
	end
	skinRow.Visible = #mine > 0
	if #mine == 0 then
		return
	end
	local wearing = profile.skins and profile.skins[selected]
	label(skinRow, { Size = UDim2.fromOffset(80, 40), Text = "\u{2728} Skins", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
	local x = 86
	local function chip(text, on, onClick)
		local b = button(skinRow, text, { Size = UDim2.fromOffset(170, 40), Position = UDim2.fromOffset(x, 0), BackgroundColor3 = on and Color3.fromRGB(47, 107, 58) or PLUM, ZIndex = 12 }, onClick)
		x += 176
		return b
	end
	chip((not wearing and "\u{2705} " or "") .. "Plain", not wearing, function()
		remotes.EquipSkin:FireServer(selected, "")
	end)
	for _, skin in ipairs(mine) do
		local owned = skinOwned[skin.id] or (skin.corn and profile.skinsEarned and profile.skinsEarned[skin.id])
		local found = profile.stats and ((profile.stats.corn or 0) + (profile.stats.cornGift or 0) - (profile.stats.cornSpent or 0)) or 0
		local tag = owned and "" or skin.corn and (" (" .. skin.corn .. " corns)") or ""
		local c = chip((wearing == skin.id and "\u{2705} " or "") .. skin.name .. tag, wearing == skin.id, function()
			if owned then
				remotes.EquipSkin:FireServer(selected, skin.id)
			elseif skin.corn then
				notice("\u{1F383} " .. skin.name .. " costs " .. skin.corn .. " candy corns in the Candy Shop (the banner at the bottom). You have " .. found .. ".")
			else
				MarketplaceService:PromptGamePassPurchase(player, skin.pass)
			end
		end)
		if not owned and not skin.corn then
			robuxIcon(c, 22) -- for sale for Robux
		end
	end
end
local function refreshOwned()
	local ok, got = pcall(function()
		return remotes:WaitForChild("OwnedSkins"):InvokeServer()
	end)
	if ok and type(got) == "table" then
		skinOwned = got
	end
	paintSkins()
end
-- a skin bought with candy corns shows as yours at once
player:GetAttributeChangedSignal("ProfileJson"):Connect(function()
	task.defer(paintSkins)
end)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, _, bought)
	if bought then
		task.delay(1, refreshOwned)
	end
end)
local resetRobux = button(right, "\u{1F504} Reset upgrades: Robux", { Size = UDim2.fromOffset(265, 34), Position = UDim2.fromOffset(364, 448), BackgroundColor3 = Color3.fromRGB(0, 176, 111), ZIndex = 11, Visible = (Config.ROBUX_PRODUCTS.reset or 0) > 0 }, function()
	remotes.ResetLadder:FireServer(selected, "robux")
	MarketplaceService:PromptProductPurchase(player, Config.ROBUX_PRODUCTS.reset)
end)
task.spawn(function()
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(Config.ROBUX_PRODUCTS.reset, Enum.InfoType.Product)
	end)
	if ok and info and info.PriceInRobux then
		resetRobux.Text = "\u{1F504} Reset upgrades: " .. info.PriceInRobux
		robuxIcon(resetRobux, 22)
	end
end)
button(chars, "Close", { Size = UDim2.fromOffset(160, 40), Position = UDim2.new(0.5, -80, 1, -46), ZIndex = 11 }, function()
	chars.Visible = false
end)
local shown, spin, dragging, lastX, shownFor = nil, 0, false, 0, nil
local function showModel(sk)
	-- the skin this player wears for the character, once its model is saved to Roblox
	local previews = ReplicatedStorage:FindFirstChild("Previews")
	local modelName = sk.name
	local worn = profile.skins and profile.skins[sk.id]
	for _, skin in ipairs(Config.SKINS or {}) do
		if skin.id == worn and previews and previews:FindFirstChild(skin.model) then
			modelName = skin.model
		end
	end
	if shownFor == modelName and shown then
		return
	end
	if shown then
		shown:Destroy()
		shown = nil
	end
	spin = 0
	local src = previews and previews:FindFirstChild(modelName)
	if src then
		shown = src:Clone()
		shown.Parent = viewWorld
		shown:PivotTo(CFrame.Angles(0, math.pi, 0))
		do
			-- shoulders to feet (a hood or a big head is left out, so a skin is
			-- the same size as its plain character), as a whole height
			local _, standing = require(ReplicatedStorage.Shared.ModelBounds)(shown, "nohead")
			shown:SetAttribute("FitH", standing.Y / 0.72 / ((Config.PREVIEW_SCALE or {})[shown.Name] or 1))
		end
		pcall(require(ReplicatedStorage.Shared.PreviewPose), shown, sk.id, modelName) -- the character's own idle
		shownFor = modelName
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
	local cf, size = require(ReplicatedStorage.Shared.ModelBounds)(shown) -- the parts you can see
	-- the distance from its standing height (measured once), so every
	-- character and skin is the same size on screen whatever its pose
	local h = shown:GetAttribute("FitH") or size.Y
	local dist = h * 0.54 / math.tan(math.rad(viewCam.FieldOfView / 2))
	viewCam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, h * 0.05, dist), cf.Position)
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
	charName.Text = sk.icon .. " " .. sk.name
	charTitle.Text = "Level " .. lvl .. "  \u{00B7}  " .. xp .. " XP" .. (nextNeed and (" (next at " .. nextNeed .. ")") or " (max!)")
	local prev = Progress.LEVEL_XP[lvl]
	xpFill.Size = UDim2.fromScale(nextNeed and math.clamp((xp - prev) / (nextNeed - prev), 0, 1) or 1, 1)
	local picks = (profile.picks and profile.picks[selected]) or {}
	for level = 2, Progress.MAX_LEVEL do
		local options = Progress.choices(selected, level)
		local row = ladder[level]
		local reached = lvl >= level
		for i, side in ipairs({ "a", "b" }) do
			local opt = options[i]
			local chosen = picks[tostring(level)] == opt.id
			-- the one not taken is locked out (a pick no longer offered counts as none)
			local pickedHere = picks[tostring(level)] ~= nil and (picks[tostring(level)] == options[1].id or picks[tostring(level)] == options[2].id)
			local other = pickedHere and not chosen
			row[side].Text = (chosen and "\u{2705} " or other and "\u{1F512} " or "") .. opt.name .. "\n" .. opt.say
			row[side].BackgroundColor3 = chosen and Color3.fromRGB(47, 107, 58) or ((reached and not other) and PLUM or Color3.fromRGB(45, 40, 55))
			row[side].TextTransparency = (reached and not other) and 0 or 0.5
		end
		row.tag.Text = reached and ("Lv " .. level) or ("\u{1F512} " .. level)
	end
	paintSkins()
end
charsBtn.Activated:Connect(function()
	chars.Visible = true
	repaintChars()
	task.spawn(refreshOwned)
end)
Gamepad.panel(chars)
-- controller: LB / RB step through the characters, the right stick turns the model
do
	Gamepad.bind(Enum.KeyCode.ButtonL1, function()
		if chars.Visible then
			stepChar(-1)
		end
	end, true)
	Gamepad.bind(Enum.KeyCode.ButtonR1, function()
		if chars.Visible then
			stepChar(1)
		end
	end, true)
	local padTurn = 0
	UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			padTurn = math.abs(input.Position.X) > 0.2 and input.Position.X or 0
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		if padTurn ~= 0 and chars.Visible then
			spin += padTurn * dt * 3
		end
	end)
end
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
		local bpic = b and Config.BOOST_IMAGES and Config.BOOST_IMAGES[r.boost] or 0
		label(cell, { Size = UDim2.new(1, -8, 0, 40), Position = UDim2.fromOffset(4, 32), Text = (done and "\u{2705}\n" or "") .. r.points .. " \u{2B50}" .. ((b and bpic == 0) and ("\n+" .. b.icon) or ""), TextColor3 = today and NIGHT or CREAM, ZIndex = 22 })
		if b and bpic > 0 then
			label(cell, { Size = UDim2.fromOffset(20, 26), Position = UDim2.fromOffset(12, 76), Text = "+", TextColor3 = today and NIGHT or CREAM, ZIndex = 22 })
			local pic = Instance.new("ImageLabel")
			pic.BackgroundTransparency = 1
			pic.Image = "rbxassetid://" .. bpic
			pic.Size = UDim2.fromOffset(30, 30)
			pic.Position = UDim2.fromOffset(32, 74)
			pic.ZIndex = 22
			pic.Parent = cell
		end
	end
	local b = info.boost and Progress.BOOSTS[info.boost]
	label(box, { Size = UDim2.new(1, -40, 0, 30), Position = UDim2.fromOffset(20, 182),
		Text = "+" .. info.points .. " \u{2B50}" .. (b and (" and a " .. b.name .. " boost") or "") .. (info.premium and "  (Premium: double points!)" or ""), ZIndex = 21 })
	label(box, { Size = UDim2.new(1, -40, 0, 22), Position = UDim2.fromOffset(20, 214), Text = "Come back tomorrow for day " .. (info.day % #Config.DAILY + 1) .. ". Miss a day and it starts again at day 1.", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 21 })
	if not info.premium then
		button(box, "\u{2B50} Roblox Premium: double daily points", { Size = UDim2.fromOffset(330, 38), Position = UDim2.fromOffset(20, 276), BackgroundColor3 = Color3.fromRGB(0, 120, 200), ZIndex = 21 }, function()
			MarketplaceService:PromptPremiumPurchase(player)
		end)
	end
	local function done()
		box:Destroy()
		-- would you like a reminder when tomorrow's reward is ready? (Roblox
		-- only asks players 13+ who have not said no in the last 30 days)
		if (Config.NOTIFY.messageId or "") ~= "" then
			task.spawn(function()
				local ens = game:GetService("ExperienceNotificationService")
				local ok, can = pcall(function()
					return ens:CanPromptOptInAsync()
				end)
				if ok and can then
					pcall(function()
						ens:PromptOptIn()
					end)
				end
			end)
		end
	end
	local yay = button(box, "Yay!", { Size = UDim2.fromOffset(150, 38), Position = UDim2.new(1, -170, 0, 276), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 21 }, done)
	Gamepad.panel(box, yay, done)
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
require(ReplicatedStorage.Shared.MusicPlayer).start("lobby", gui, UDim2.new(1, -116, 0, 104), remotes:WaitForChild("SetMusic"), remotes:WaitForChild("SetSfx"))

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
		s.SoundGroup = Sfx.group()
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
do
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -30, 1, -120)
	scroll.Position = UDim2.fromOffset(18, 56)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 8
	scroll.ScrollBarImageColor3 = PUMP
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.ZIndex = 11
	scroll.Parent = help
	local t = label(scroll, {
		Size = UDim2.new(1, -14, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextScaled = false,
		TextSize = 17,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 12,
		Text = "\u{1F3E0} You were dropped at a party. It was a trick! Escape the floor before the host catches you - and before the timer runs out.\n\n"
			.. "\u{1F465} The party leader picks the floor, difficulty and Giggly or Spooky. Everyone picks a character and presses \u{25B6} Play when ready.\n\n"
			.. "\u{1F388} Pop balloons (E) to learn the 3-color door code - some are tricks. Brainy, Glow and Bramble learn it a faster way. Tinker can pick the big door's keypad (F) for one color.\n\n"
			.. "\u{1F511} Locked doors: find the key in a drawer, box or coat - or Tinker picks the lock (F).\n"
			.. "\u{1F6A7} Blocked doorways: Muscle shoves the junk (E), or anyone plants a \u{1F389} Confetti Cannon (F). Cannons belong to the whole team - but the BOOM brings the host!\n"
			.. "\u{1F381} The Store Room and the Junk Closet hide a bonus present - 20 to 60 points for everyone in the game!\n\n"
			.. "\u{1F3C3} Run with Shift or the Run button (it uses stamina).\n"
			.. "\u{1F648} Hide where you see a \u{1F648} - each fits 1 to 3. Press Space to come out.\n"
			.. "\u{1F573} Crawl through vents to the next room - the host can't follow.\n\n"
			.. "\u{1F4AA} Muscle's Barricade: slide a \u{1F4AA} crate into a doorway. Friends walk through, the host has to smash it.\n"
			.. "\u{1F3A7} Echo throws a noise - the host goes to look. \u{1F319} Shadow sneaks unseen. \u{1F6E1} Patch gives Party Shields and helps friends run.\n\n"
			.. "\u{1F512} Caught? A friend frees you from the cage (hold E) - or watch your team.\n"
			.. "\u{1F4A1} Clues show the next step but cost points earned that game.\n"
			.. "\u{1F392} Boosts from the shop: tap them in the game.\n\n"
			.. "\u{2B50} Play a character to level them up to 10 - choose upgrades in Characters.\n"
			.. "\u{1F6AA} Escape a floor to unlock the next one - 6 buildings, 18 floors (and a secret one...)!\n\n"
			.. "\u{1F4DC} Daily quests: three a day, points as soon as you finish one.\n"
			.. "\u{1F46B} Play with a Roblox friend for +10% points.\n"
			.. "\u{1F36B} Chocolate is slow to wade through - use the bridge. \u{1F9FA} Slide down the laundry chute. \u{1F512} Turn the vault wheel in the Jelly Vault for treasure!\n\n"
			.. "\u{1F3AE} Controller: A jump (and come out of hiding), X use, Y pick / plant, LT run, RB skill, LB boost, D-pad: Up clue, Left map, Right chat, Down players. The View button moves round the buttons.",
	})
	local _ = t
end
button(help, "Got it", { Size = UDim2.fromOffset(160, 46), Position = UDim2.new(0.5, -80, 1, -60), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 11 }, function()
	help.Visible = false
end)
helpBtn.Activated:Connect(function()
	help.Visible = true
end)
Gamepad.panel(help)

-- ---------- daily quests ----------
do
	local Quests = Config.QUESTS
	local panel = frame(gui, { Size = UDim2.fromOffset(520, 640), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Visible = false, ZIndex = 10 })
	corner(panel, 18)
	do
		local fit = Instance.new("UIScale")
		fit.Parent = panel
		local function size()
			fit.Scale = math.min(1, (workspace.CurrentCamera.ViewportSize.Y - 20) / 640)
		end
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(size)
		size()
	end
	label(panel, { Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 8), Text = "\u{1F4DC} Daily quests", TextColor3 = PUMP, ZIndex = 11 }) -- the menu button says Quests
	local resets = label(panel, { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 44), Text = "", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 11 })
	label(panel, { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 296), Text = "\u{1F3C6} Weekly quests", TextColor3 = Color3.fromRGB(255, 210, 63), ZIndex = 11 })
	local weekResets = label(panel, { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 328), Text = "", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 11 })
	local rows = {}
	for i = 1, 6 do
		local y = i <= 3 and (72 + (i - 1) * 74) or (354 + (i - 4) * 74)
		local r = frame(panel, { Size = UDim2.new(1, -40, 0, 66), Position = UDim2.fromOffset(20, y), BackgroundColor3 = PLUM, BackgroundTransparency = 0.3, ZIndex = 11 })
		corner(r, 12)
		local text = label(r, { Size = UDim2.new(1, -130, 0, 30), Position = UDim2.fromOffset(12, 6), Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
		local reward = label(r, { Size = UDim2.fromOffset(110, 30), Position = UDim2.new(1, -120, 0, 6), Text = "", TextColor3 = Color3.fromRGB(255, 210, 63), ZIndex = 12 })
		local back = frame(r, { Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(12, 44), BackgroundColor3 = Color3.fromRGB(18, 10, 27), BackgroundTransparency = 0, ZIndex = 12 })
		corner(back, 7)
		local fill = frame(back, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(123, 227, 107), BackgroundTransparency = 0, ZIndex = 13 })
		corner(fill, 7)
		rows[i] = { text = text, reward = reward, fill = fill }
	end
	local closeQ = button(panel, "Close", { Size = UDim2.fromOffset(160, 44), Position = UDim2.new(0.5, -80, 1, -56), ZIndex = 11 }, function()
		panel.Visible = false
	end)
	local function defOf(id)
		for _, pool in ipairs({ Quests, Config.WEEKLY_QUESTS or {} }) do
			for _, q in ipairs(pool) do
				if q.id == id then
					return q
				end
			end
		end
		return nil
	end
	local function paint()
		local qs = profile.quests
		local today = math.floor(os.time() / 86400)
		local week = math.floor((os.time() + 3 * 86400) / (7 * 86400))
		local list = (qs and qs.day == today and qs.list) or {}
		local wk = profile.weekly
		local wlist = (wk and wk.week == week and wk.list) or {}
		local doneCount, total = 0, 0
		for i = 1, 6 do
			local q = i <= 3 and list[i] or wlist[i - 3]
			local d = q and defOf(q.id)
			local r = rows[i]
			if d then
				local b = d.boost and Progress.BOOSTS[d.boost]
				r.text.Text = (q.done and "\u{2705} " or "") .. d.text .. "  (" .. q.n .. "/" .. d.goal .. ")"
				r.reward.Text = "+" .. d.points .. " \u{2B50}" .. (b and (" + " .. b.name) or "")
				r.fill.Size = UDim2.fromScale(math.clamp(q.n / d.goal, 0, 1), 1)
				total += 1
				if q.done then
					doneCount += 1
				end
			else
				r.text.Text = "New quests arrive when you join"
				r.reward.Text = ""
				r.fill.Size = UDim2.fromScale(0, 1)
			end
		end
		local left = (today + 1) * 86400 - os.time()
		resets.Text = "Rewards are paid the moment you finish - no claiming. New in " .. math.floor(left / 3600) .. "h " .. math.floor(left % 3600 / 60) .. "m"
		local wleft = (week + 1) * 7 * 86400 - 3 * 86400 - os.time()
		weekResets.Text = "Bigger goals, more points and a boost each. New on Monday (in " .. math.floor(wleft / 86400) .. "d " .. math.floor(wleft % 86400 / 3600) .. "h)"
		-- daily and weekly together: how many are done of how many there are
		setBadge(questsBtn, total > doneCount and tostring(total - doneCount) or nil) -- quests still to do
	end
	player:GetAttributeChangedSignal("ProfileJson"):Connect(function()
		task.defer(paint)
	end)
	paint()
	questsBtn.Activated:Connect(function()
		panel.Visible = not panel.Visible
		paint()
	end)
	Gamepad.panel(panel, closeQ)
end

-- ---------- back into a game after a dropped connection ----------
remotes:WaitForChild("RejoinOffer").OnClientEvent:Connect(function(info)
	local box = frame(gui, { Size = UDim2.fromOffset(420, 170), Position = UDim2.new(0.5, -210, 0.3, -85), ZIndex = 60 })
	corner(box, 16)
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = PUMP, 2
	stroke.Parent = box
	label(box, { Size = UDim2.new(1, -30, 0, 70), Position = UDim2.fromOffset(15, 12), TextWrapped = true, ZIndex = 61,
		Text = "\u{1F50C} You dropped out of " .. tostring(info.map) .. " - your crew is still playing! Go back in?" })
	local yes = button(box, "\u{25B6} Rejoin", { Size = UDim2.fromOffset(180, 50), Position = UDim2.fromOffset(20, 100), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 61 }, function()
		remotes.Rejoin:FireServer(true)
		box:Destroy()
	end)
	button(box, "No thanks", { Size = UDim2.fromOffset(180, 50), Position = UDim2.new(1, -200, 0, 100), ZIndex = 61 }, function()
		remotes.Rejoin:FireServer(false)
		box:Destroy()
	end)
	Gamepad.panel(box, yes, function()
		box:Destroy()
	end)
end)
