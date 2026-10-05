--[[
	LobbyUi - the lobby screen: Play solo, Create party, parties you can join,
	and your party (players 1-6, friends only, difficulty, Giggly/Spooky,
	Invite friends, Start, Leave).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Config = require(ReplicatedStorage.Shared.Config)
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
local note = frame(gui, { Size = UDim2.new(0.5, 0, 0, 50), Position = UDim2.new(0.25, 0, 0, 70), Visible = false })
corner(note, 14)
local noteText = label(note, { Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5) })
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

local function invite()
	local ok, can = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)
	if ok and can then
		pcall(function()
			SocialService:PromptGameInvite(player)
		end)
	else
		notice("Invites aren't available here (they work in the published game).")
	end
end

-- ---------- main menu (left) ----------
local menu = frame(gui, { Size = UDim2.fromOffset(330, 400), Position = UDim2.new(0, 24, 0.5, -200) })
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
local helpBtn = button(menu, "\u{2753} How to play", { Size = UDim2.new(0.86, 0, 0, 46), LayoutOrder = 6 })

-- ---------- parties you can join (right) ----------
local joinBox = frame(gui, { Size = UDim2.fromOffset(330, 400), Position = UDim2.new(1, -354, 0.5, -200) })
corner(joinBox, 18)
label(joinBox, { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 10), Text = "Friends' parties", TextColor3 = PUMP })
local joinList = frame(joinBox, { Size = UDim2.new(1, -20, 1, -64), Position = UDim2.fromOffset(10, 56), BackgroundTransparency = 1 })
list(joinList, 8)
local joinEmpty = label(joinList, { Size = UDim2.new(1, 0, 0, 60), Text = "No parties yet - create one and invite a friend!", TextColor3 = Color3.fromRGB(185, 168, 207) })

-- ---------- your party (middle) ----------
local partyBox = frame(gui, { Size = UDim2.fromOffset(440, 470), Position = UDim2.new(0.5, -220, 0.5, -235), Visible = false })
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
local optBox = frame(partyBox, { Size = UDim2.new(1, -40, 0, 170), Position = UDim2.fromOffset(20, 214), BackgroundTransparency = 1 })
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
		.. "\u{1F4A1} Clues show the next step but cost energy.\n"
		.. "\u{1F512} Caught? A teammate frees you from the cage - or watch your team.\n"
		.. "\u{1F333} Everyone out to the garden = you win!",
})
button(help, "Got it", { Size = UDim2.fromOffset(160, 46), Position = UDim2.new(0.5, -80, 1, -60), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 11 }, function()
	help.Visible = false
end)
helpBtn.Activated:Connect(function()
	help.Visible = true
end)
