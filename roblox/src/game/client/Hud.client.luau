--[[
	Hud - everything on a player's screen: skill picker, top bar (room,
	footsteps, door code, clue), action buttons (Run, Skill, Say, Come out),
	stamina and energy, messages, the keypad, jumpscares and running.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Sfx = require(game:GetService("ReplicatedStorage").Shared.Sfx)
local Gamepad = require(ReplicatedStorage.Shared.Gamepad)
local HttpService = game:GetService("HttpService")
local Progress = require(ReplicatedStorage.Shared.Progress)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundState = ReplicatedStorage:WaitForChild("RoundState")
-- this game's house, sent by the server (a floor plan with things placed at random)
local HouseMap = { w = 40, h = 30, map = {}, floors = {}, objects = {} }
local function readMap()
	local json = RoundState:GetAttribute("MapJson")
	if json then
		local ok, m = pcall(function()
			return HttpService:JSONDecode(json)
		end)
		if ok and type(m) == "table" then
			HouseMap = m
		end
	end
end
readMap()
local player = Players.LocalPlayer
local T = Config.TILE

local NIGHT = Color3.fromRGB(26, 16, 38)
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local PUMP = Color3.fromRGB(255, 138, 31)
local CREAM = Color3.fromRGB(255, 244, 224)

-- ---------- little builders ----------
local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
	f.BackgroundTransparency = 0.15
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
	b.BackgroundColor3 = Color3.fromRGB(75, 58, 102)
	b.AutoButtonColor = true
	for k, v in pairs(props) do
		b[k] = v
	end
	corner(b, 12)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
	pad.Parent = b
	b.Parent = parent
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- ---------- messages ----------
local toastFrame = frame(gui, { Size = UDim2.new(0.5, 0, 0, 56), Position = UDim2.new(0.25, 0, 0.2, 0), Visible = false })
corner(toastFrame, 14)
local toastStroke = Instance.new("UIStroke")
toastStroke.Color = PUMP
toastStroke.Thickness = 2
toastStroke.Parent = toastFrame
local toastText = label(toastFrame, { Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5) })
local toastToken = 0
local function toast(text, seconds)
	toastToken += 1
	local my = toastToken
	toastText.Text = text
	toastFrame.Visible = true
	task.delay(seconds or 3, function()
		if toastToken == my then
			toastFrame.Visible = false
		end
	end)
end

-- ---------- sounds only this player hears ----------
local SoundService = game:GetService("SoundService")
local function playLocal(name, volume)
	local id = Config.SOUNDS[name]
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundGroup = Sfx.group()
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume or 0.8
	s.Parent = SoundService
	s:Play()
	local max = Config.SOUND_MAX[name] or 4
	task.delay(max, function()
		s:Destroy()
	end)
end

-- ---------- jumpscare ----------
local scare = frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0, Visible = false, ZIndex = 50 })
local scareImg
if Config.IMAGES.scare then
	scareImg = Instance.new("ImageLabel")
	scareImg.Size = UDim2.fromScale(1, 1)
	scareImg.BackgroundTransparency = 1
	scareImg.Image = Config.IMAGES.scare
	scareImg.ScaleType = Enum.ScaleType.Crop
	scareImg.ZIndex = 51
	scareImg.Parent = scare
else
	label(scare, { Size = UDim2.fromScale(1, 0.7), Position = UDim2.fromScale(0, 0.15), Text = "\u{1F383}", ZIndex = 51 })
end
local redFlash = frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(200, 0, 20), BackgroundTransparency = 1, ZIndex = 49 })
-- the scare shows tonight's host's real 3D face, filling the screen
local scareView = Instance.new("ViewportFrame")
scareView.Size = UDim2.fromScale(1, 1)
scareView.BackgroundColor3 = Color3.new(0, 0, 0)
scareView.Ambient = Color3.fromRGB(150, 110, 90)
scareView.LightColor = Color3.fromRGB(255, 170, 90)
scareView.LightDirection = Vector3.new(0, -0.6, -1)
scareView.ZIndex = 52
scareView.Visible = false
scareView.Parent = scare
local scareCam = Instance.new("Camera")
scareCam.FieldOfView = 45
scareCam.Parent = scareView
scareView.CurrentCamera = scareCam
local scareFace -- head, direction and size, while a scare is on
local function jumpscare()
	scare.Visible = true
	scareFace = nil
	for _, c in ipairs(scareView:GetChildren()) do
		if c ~= scareCam then
			c:Destroy()
		end
	end
	local host = workspace:FindFirstChild("PartyHost")
	local ok, copy = pcall(function()
		return host and host:Clone()
	end)
	if ok and copy then
		for _, d in ipairs(copy:GetDescendants()) do
			if d:IsA("Script") or d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		copy.Parent = scareView
		local head = copy:FindFirstChild("Head") or copy.PrimaryPart
		local root = copy:FindFirstChild("HumanoidRootPart") or head
		if head then
			local look = root.CFrame.LookVector
			local dir = Vector3.new(look.X, 0, look.Z)
			dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, -1)
			scareFace = { head = head, dir = dir, r = math.max(head.Size.X, head.Size.Y, head.Size.Z) / 2 }
		end
	end
	scareView.Visible = scareFace ~= nil
	local cam = workspace.CurrentCamera
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local f = os.clock() - t0
		if scareFace then
			-- rush in on the face
			local d = scareFace.r * (2.6 - math.min(1, f * 2.5) * 1.3)
			local aim = scareFace.head.Position - Vector3.new(0, scareFace.r * 0.15, 0)
			scareCam.CFrame = CFrame.lookAt(aim + scareFace.dir * d + Vector3.new((math.random() - 0.5) * 0.15, 0, 0), aim)
		end
		if scareImg then
			scareImg.Size = UDim2.fromScale(1 + f * 0.4, 1 + f * 0.4)
			scareImg.Position = UDim2.fromScale(-f * 0.2, -f * 0.2)
		end
		cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, (math.random() - 0.5) * 0.05)
		if f > (scareFace and 1.2 or 0.7) then
			conn:Disconnect()
			scare.Visible = false
		end
	end)
end

-- When the server swaps the avatar for the real character, the camera can
-- stay on the old (removed) avatar: always follow the current character.
local function followMe(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum and player.Character == char then
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
	end
end
player.CharacterAdded:Connect(function(char)
	task.defer(followMe, char)
end)
if player.Character then
	task.defer(followMe, player.Character)
end

-- the camera rushes in on the host's face (works with any host model)
local scareBusyUntil = 0 -- the results wait for the close-up to finish
local function hostCloseUp(intense)
	local host = workspace:FindFirstChild("PartyHost")
	local head = host and (host:FindFirstChild("Head") or host.PrimaryPart)
	if not head then
		return
	end
	local cam = workspace.CurrentCamera
	local fov = cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable
	-- light the face so it shows in a dark room
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 150, 60)
	glow.Brightness = 3
	glow.Range = 14
	glow.Parent = head
	playLocal(intense and "roar" or "giggle", 1)
	redFlash.BackgroundTransparency = intense and 0.35 or 0.7
	TweenService:Create(redFlash, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
	local r = math.max(head.Size.X, head.Size.Y, head.Size.Z) / 2
	local t0 = os.clock()
	local dur = intense and 2.6 or 2
	scareBusyUntil = os.clock() + dur + (intense and 1.4 or 0.2)
	local rootPart = host:FindFirstChild("HumanoidRootPart") or head
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local f = (os.clock() - t0) / dur
		if f >= 1 or not head.Parent then
			conn:Disconnect()
			glow:Destroy()
			cam.FieldOfView = fov
			cam.CameraType = Enum.CameraType.Custom
			if intense then
				jumpscare()
			end
			return
		end
		-- rush in on the face, then hold it filling the screen, shaking
		local e = 1 - (1 - math.min(1, f * 1.6)) ^ 3
		local dist = r + 9.5 - e * 7.7
		cam.FieldOfView = fov - e * 25
		local s = (intense and 0.3 or 0.1) * e
		-- the face points the way the host walks (its root); a head part's own
		-- direction can be backwards on an imported model
		local look = rootPart.CFrame.LookVector
		local faceDir = Vector3.new(look.X, 0, look.Z)
		faceDir = faceDir.Magnitude > 0.1 and faceDir.Unit or Vector3.new(0, 0, -1)
		-- aim a little below the middle of the head part: an imported head part
		-- is taller than the face, so this keeps the whole face on screen
		local front = head.Position + faceDir * dist + Vector3.new(0, r * 0.05, 0)
		local shake = Vector3.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, (math.random() - 0.5) * s)
		cam.CFrame = CFrame.lookAt(front + shake, head.Position - Vector3.new(0, r * 0.2, 0))
	end)
end

-- ---------- top bar ----------
-- the top bar stops short of the sound and music buttons (top right)
local top = frame(gui, { Size = UDim2.new(0.7, -232, 0, 40), Position = UDim2.new(0.3, 0, 0, 8), BackgroundTransparency = 0.25 })
corner(top, 12)
local roomName -- placed with the bars below
local steps = {}
for i = 1, 5 do
	-- footprints are off: only the host's breathing gives it away
	steps[i] = label(top, { Position = UDim2.new(0.02 + (i - 1) * 0.065, 0, 0.2, 0), Size = UDim2.new(0.065, 0, 0.6, 0), Text = "\u{1F463}", TextTransparency = 0.8, Visible = false })
end
local timerLabel = label(top, { Size = UDim2.new(0.26, 0, 0.7, 0), Position = UDim2.fromScale(0.36, 0.15), Text = "\u{23F1} --:--" })
-- the room you're in, at the top left of the bar (the building and floor stay above the map)
local topRoom = label(top, { Size = UDim2.new(0.33, 0, 0.7, 0), Position = UDim2.fromScale(0.02, 0.15), Text = "", TextColor3 = PUMP })
-- the countdown: a flash at 1:00, bigger and shaking from 0:30, big red numbers from 0:10
local countdown = { scale = Instance.new("UIScale"), last = nil, flashUntil = 0 }
countdown.scale.Parent = timerLabel
countdown.big = label(gui, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(240, 180), Text = "", TextColor3 = Color3.fromRGB(255, 50, 60), TextStrokeTransparency = 0.1, Font = Enum.Font.GothamBlack, Visible = false, ZIndex = 30 })
countdown.bigScale = Instance.new("UIScale")
countdown.bigScale.Parent = countdown.big
local codeLabel = label(top, { Size = UDim2.new(0.36, 0, 0.7, 0), Position = UDim2.fromScale(0.62, 0.15), RichText = true, Text = "Code: ? ? ?" })
local clueBtn -- lives with the action buttons below
local function askClue()
	remotes.AskClue:FireServer()
end

local function hex(c)
	return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function paintCode()
	local parts = {}
	for i = 1, 3 do
		local k = RoundState:GetAttribute("Known" .. i)
		parts[i] = k and ('<font color="' .. hex(Config.COLOR3[k]) .. '">\u{25CF}</font>' .. (Config.COLOR_SHAPE[k] or "")) or "?"
	end
	codeLabel.Text = "Code: " .. table.concat(parts, " ")
	if clueBtn then
		local cost = RoundState:GetAttribute("ClueCost") or 10
		if player:GetAttribute("Skill") == "brainy" then
			cost = math.ceil(cost / 2)
		end
		local free = RoundState:GetAttribute("FreeClues") or 0
		local left = tostring(RoundState:GetAttribute("CluesLeft") or 0)
		clueBtn.Text = free > 0 and ("\u{1F4A1} Clue FREE (" .. left .. ")") or ("\u{1F4A1} Clue " .. cost .. "\u{2B50} (" .. left .. ")")
	end
end
RoundState.AttributeChanged:Connect(paintCode)
paintCode()

-- ---------- bars ----------
local bars = frame(gui, { Size = UDim2.fromOffset(250, 84), Position = TOUCH and UDim2.fromOffset(10, 60) or UDim2.new(0, 10, 1, -94), BackgroundTransparency = 0.3 })
roomName = label(bars, { Size = UDim2.new(1, -16, 0, 32), Position = UDim2.fromOffset(8, 54), Text = "The Party House", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PUMP })
do
-- the team's items, as icons above the active boosts: a key for each locked
-- door still shut, and the Confetti Cannons (they stay through a cage)
local itemRow = frame(gui, { Size = UDim2.fromOffset(290, 58), Position = TOUCH and UDim2.new(1, -300, 1, -472) or UDim2.new(1, -300, 1, -332), BackgroundTransparency = 1 })
local itemList = Instance.new("UIListLayout")
itemList.FillDirection = Enum.FillDirection.Horizontal
itemList.HorizontalAlignment = Enum.HorizontalAlignment.Right
itemList.SortOrder = Enum.SortOrder.LayoutOrder
itemList.Padding = UDim.new(0, 6)
itemList.Parent = itemRow
local function slot(icon, text, order)
	local f = frame(itemRow, { Size = UDim2.fromOffset(58, 58), BackgroundColor3 = NIGHT, BackgroundTransparency = 0.2, LayoutOrder = order })
	corner(f, 12)
	local ring = Instance.new("UIStroke")
	ring.Color, ring.Thickness = Color3.fromRGB(255, 210, 63), 2
	ring.Parent = f
	label(f, { Size = UDim2.new(1, 0, 0.62, 0), Position = UDim2.fromScale(0, 0.02), Text = icon })
	label(f, { Size = UDim2.new(1, -4, 0.34, 0), Position = UDim2.new(0, 2, 0.64, 0), Text = text, TextColor3 = Color3.fromRGB(255, 210, 63) })
end
local function doorName(id)
	for _, o in ipairs(HouseMap.objects or {}) do
		if o.id == id then
			return o.name
		end
	end
	return nil
end
local function paintItems()
	for _, c in ipairs(itemRow:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local n = RoundState:GetAttribute("Poppers") or 0
	if n > 0 then
		slot("\u{1F389}", "x" .. n, 1)
	end
	for i, id in ipairs({ "L1", "L2", "B1", "B2" }) do
		if RoundState:GetAttribute("Key_" .. id) and not RoundState:GetAttribute("Lock_" .. id) then
			local nm = doorName(id) or "Key"
			slot("\u{1F511}", string.match(nm, "^(%S+)") or nm, 1 + i)
		end
	end
end
RoundState.AttributeChanged:Connect(function(a)
	if a == "Poppers" or a == "MapJson" or string.sub(a, 1, 4) == "Key_" or string.sub(a, 1, 5) == "Lock_" then
		paintItems()
	end
end)
paintItems()
end
corner(bars, 10)
local function bar(y, color, name)
	label(bars, { Size = UDim2.fromOffset(78, 16), Position = UDim2.fromOffset(8, y - 2), Text = name, TextXAlignment = Enum.TextXAlignment.Left })
	local back = frame(bars, { Size = UDim2.new(1, -96, 0, 12), Position = UDim2.fromOffset(88, y), BackgroundColor3 = Color3.fromRGB(18, 10, 27), BackgroundTransparency = 0 })
	corner(back, 6)
	local fill = frame(back, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BackgroundTransparency = 0 })
	corner(fill, 6)
	return fill
end
local staminaBar = bar(10, Color3.fromRGB(123, 227, 107), "Stamina")
-- points earned in this game (clues are paid from these)
local gameEarned = label(bars, { Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 30), Text = "\u{2B50} 0 points this game", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 210, 63) })

-- ---------- action buttons ----------
local acts = frame(gui, { Size = UDim2.fromOffset(290, 150), Position = TOUCH and UDim2.new(1, -300, 1, -300) or UDim2.new(1, -300, 1, -160), BackgroundTransparency = 1 })
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(92, 44)
grid.CellPadding = UDim2.fromOffset(6, 6)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Right
grid.VerticalAlignment = Enum.VerticalAlignment.Bottom
grid.Parent = acts

local runToggle, shiftHeld = false, false
local runBtn = button(acts, "\u{1F3C3} Run", { LayoutOrder = 1 }, function()
	runToggle = not runToggle
end)
local skillBtn = button(acts, "\u{2B50} Skill", { LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(47, 107, 58) })
local sayBtn = button(acts, (not TOUCH and UserInputService.KeyboardEnabled) and "\u{1F4AC} Say (T)" or "\u{1F4AC} Say", { LayoutOrder = 3 })
local outBtn = button(acts, "\u{1F440} Come out", { LayoutOrder = 4, Visible = false }, function()
	remotes.Unhide:FireServer()
end)
local pickBtn = button(acts, "\u{1F504} Change", { LayoutOrder = 5 })
clueBtn = button(acts, "\u{1F4A1} Clue (3)", { LayoutOrder = 6 }, askClue)
local candyBtn = button(acts, "Candy Corn", { LayoutOrder = 8, Visible = false }, function()
	remotes.UseCandy:FireServer()
end)
local function paintCandy()
	local n = player:GetAttribute("CandyCharges") or 0
	candyBtn.Visible = n > 0
	candyBtn.Text = "Candy Corn (" .. n .. ")"
end
player:GetAttributeChangedSignal("CandyCharges"):Connect(paintCandy)
paintCandy()
-- controller: which button does what (tags show only with a controller)
do
	Gamepad.hint(runBtn, "L3")
	Gamepad.hint(skillBtn, "RB")
	Gamepad.hint(sayBtn, "Right")
	Gamepad.hint(clueBtn, "Up")
	Gamepad.hint(outBtn, "A")
	-- hold the left trigger to run (like Shift); click the left stick to keep running
	Gamepad.bind(Enum.KeyCode.ButtonL2, function()
		shiftHeld = true
	end)
	Gamepad.bindRelease(Enum.KeyCode.ButtonL2, function()
		shiftHeld = false
	end)
	Gamepad.bind(Enum.KeyCode.ButtonL3, function()
		runToggle = not runToggle
	end)
end

do
-- prompts one character uses (Pick the lock, Shove) show only to them, and
-- the everyone-else prompt beside it (Unlock, Confetti Cannon) hides for them:
-- never two on top of each other. Set on this screen only.
local function fitPrompt(p)
	local only, notFor = p:GetAttribute("Only"), p:GetAttribute("Not")
	if not only and not notFor then
		return
	end
	if p:GetAttribute("BaseDist") == nil then
		p:SetAttribute("BaseDist", p.MaxActivationDistance)
	end
	local s = player:GetAttribute("Skill")
	local show = (only == nil or s == only) and (notFor == nil or s ~= notFor)
	p.MaxActivationDistance = show and p:GetAttribute("BaseDist") or 0
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then
		task.defer(fitPrompt, d)
	end
end)
player:GetAttributeChangedSignal("Skill"):Connect(function()
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			fitPrompt(d)
		end
	end
end)
end

-- hold-to-use prompts (pick, shove, read, free...) go faster with ladder upgrades
local ProximityPromptService = game:GetService("ProximityPromptService")
local function fitHold(prompt)
	local base = prompt:GetAttribute("BaseHold")
	if base == nil then
		base = prompt.HoldDuration
		prompt:SetAttribute("BaseHold", base)
	end
	local only = prompt:GetAttribute("Only")
	-- Tinker's Toolkit: the next pick is instant; Muscle's Bulldozer: every shove is
	local instant = (only == "tinker" and player:GetAttribute("ToolkitReady") == true)
		or (only == "muscle" and player:GetAttribute("Power20") == "bulldozer")
		-- Bramble's Forest Friend: the big plant answers at once
		or (prompt.ObjectText == "Big plant - Bramble" and player:GetAttribute("Power20") == "forest")
	prompt.HoldDuration = instant and 0 or base * (player:GetAttribute("HoldMult") or 1)
end
ProximityPromptService.PromptShown:Connect(fitHold)
-- pressing Toolkit while already standing at the lock: change it straight away
player:GetAttributeChangedSignal("ToolkitReady"):Connect(function()
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d:GetAttribute("Only") == "tinker" then
			fitHold(d)
		end
	end
end)
-- mouse look (computers): the camera turns as the mouse moves, no button held
local mouseLook = false
local lookBtn = button(acts, "\u{1F5B1} Look (M)", { LayoutOrder = 7, Visible = not TOUCH and UserInputService.KeyboardEnabled }, function()
	mouseLook = not mouseLook
end)

do
	-- emotes (G / the right stick): wave, point, cheer, laugh, dances
	local emoteBtn = button(acts, (not TOUCH and UserInputService.KeyboardEnabled) and "\u{1F604} Emote (G)" or "\u{1F604} Emote", { LayoutOrder = 9 })
	require(ReplicatedStorage.Shared.Emotes).mount(gui, emoteBtn, UDim2.new(0.5, -218, 1, -400))
end
do
	-- a rumble (controller, and phones that allow it): caught, spotted, a
	-- pumpkin hit, a Ground Pound nearby, FRENZY
	local Haptics = require(ReplicatedStorage.Shared.Haptics)
	player:GetAttributeChangedSignal("Caged"):Connect(function()
		if player:GetAttribute("Caged") then
			Haptics.buzz(1, 0.6)
		end
	end)
	RoundState:GetAttributeChangedSignal("Frenzy"):Connect(function()
		if RoundState:GetAttribute("Frenzy") then
			Haptics.buzz(0.7, 0.9)
		end
	end)
	remotes.Boost.OnClientEvent:Connect(function(kind, amount)
		if kind == "shake" then
			Haptics.buzz(0.8 * (tonumber(amount) or 1), 0.35)
		end
	end)
	remotes.Notify.OnClientEvent:Connect(function(kind, _, data)
		local mine = type(data) == "table" and data.userId == player.UserId
		if mine and kind == "spotted" then
			Haptics.buzz(0.4, 0.25)
		elseif mine and kind == "bonk" then
			Haptics.buzz(0.9, 0.4)
		end
	end)
end

-- ---------- quick-chat phrases ----------
local sayPanel = frame(gui, { Size = UDim2.fromOffset(530, 250), Position = UDim2.new(0.5, -265, 1, -390), Visible = false })
corner(sayPanel, 14)
local sayGrid = Instance.new("UIGridLayout")
sayGrid.CellSize = UDim2.fromOffset(124, 52)
sayGrid.CellPadding = UDim2.fromOffset(6, 6)
sayGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
sayGrid.Parent = sayPanel
for i, p in ipairs(Config.PHRASES) do
	button(sayPanel, (Config.PING_PHRASES[p] and "\u{1F4CD} " or "") .. p, { BackgroundColor3 = CREAM, TextColor3 = NIGHT }, function()
		remotes.Say:FireServer(i)
		sayPanel.Visible = false
	end)
end
sayBtn.Activated:Connect(function()
	sayPanel.Visible = not sayPanel.Visible
end)
Gamepad.panel(sayPanel)
Gamepad.bind(Enum.KeyCode.DPadRight, function()
	sayPanel.Visible = not sayPanel.Visible
end)
do
	-- T opens the phrases on a keyboard
	UserInputService.InputBegan:Connect(function(input, used)
		if not used and input.KeyCode == Enum.KeyCode.T then
			sayPanel.Visible = not sayPanel.Visible
		end
	end)
	-- the game's own speech bubble (shows even for players whose chat is off),
	-- and a pin where they stood for the phrases that mark a place
	local bubbles = {}
	remotes.Bubble.OnClientEvent:Connect(function(who, idx, pos)
		local text = Config.PHRASES[idx]
		local head = who and who.Character and (who.Character:FindFirstChild("Head") or who.Character:FindFirstChild("HumanoidRootPart"))
		if not text then
			return
		end
		if head then
			if bubbles[who] then
				bubbles[who]:Destroy()
			end
			local bb = Instance.new("BillboardGui")
			bb.Name = "SayBubble"
			bb.Adornee = head
			bb.Size = UDim2.fromOffset(190, 46)
			bb.StudsOffset = Vector3.new(0, 3.2, 0)
			bb.MaxDistance = 90
			bb.Parent = gui
			local f = frame(bb, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = CREAM, BackgroundTransparency = 0.05 })
			corner(f, 14)
			label(f, { Size = UDim2.new(1, -12, 1, -8), Position = UDim2.fromOffset(6, 4), Text = text, TextColor3 = NIGHT })
			bubbles[who] = bb
			task.delay(4, function()
				if bubbles[who] == bb then
					bubbles[who] = nil
				end
				bb:Destroy()
			end)
		end
		if typeof(pos) == "Vector3" and who ~= player then
			local a = Instance.new("Attachment")
			a.WorldPosition = pos + Vector3.new(0, 4, 0)
			a.Parent = workspace.Terrain
			local pin = Instance.new("BillboardGui")
			pin.Name = "Ping"
			pin.Adornee = a
			pin.AlwaysOnTop = true
			pin.Size = UDim2.fromOffset(150, 56)
			pin.Parent = gui
			label(pin, { Size = UDim2.new(1, 0, 0.55, 0), Text = "\u{1F4CD}", TextColor3 = PUMP })
			label(pin, { Size = UDim2.new(1, 0, 0.45, 0), Position = UDim2.fromScale(0, 0.55), Text = who.DisplayName .. ": " .. text, TextStrokeTransparency = 0.3 })
			task.delay(Config.PING_SECONDS or 6, function()
				pin:Destroy()
				a:Destroy()
			end)
		end
	end)
end

-- ---------- character select: a 3D model you can turn, and its skill ----------
local picker = frame(gui, { Size = UDim2.fromOffset(860, 576), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 20 })
corner(picker, 16)
-- shrink the whole panel on small screens so nothing is cut off
local pickerScale = Instance.new("UIScale")
pickerScale.Parent = picker
local function fitPicker()
	local vs = workspace.CurrentCamera.ViewportSize
	pickerScale.Scale = math.min(1, (vs.Y - 40) / 576, (vs.X - 20) / 860)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPicker)
fitPicker()
label(picker, { Size = UDim2.new(1, -120, 0, 36), Position = UDim2.fromOffset(60, 12), Text = "Escape Crew - pick your character", TextColor3 = PUMP, ZIndex = 21 })
-- back out without changing anything
button(picker, "X", { Font = Enum.Font.GothamBlack, Size = UDim2.fromOffset(44, 40), Position = UDim2.new(1, -58, 0, 12), BackgroundColor3 = Color3.fromRGB(150, 60, 70), ZIndex = 22 }, function()
	-- closing it with a character chosen means "I'm ready"
	if player:GetAttribute("Skill") then
		remotes.Ready:FireServer()
	end
	picker.Visible = false
end)

local view = Instance.new("ViewportFrame")
view.Size = UDim2.fromOffset(400, 300)
view.Position = UDim2.fromOffset(20, 64)
view.BackgroundColor3 = Color3.fromRGB(40, 26, 58)
view.Ambient = Color3.fromRGB(170, 160, 190)
view.LightColor = Color3.fromRGB(255, 240, 220)
view.LightDirection = Vector3.new(-0.4, -1, -0.6)
view.ZIndex = 21
view.Parent = picker
corner(view, 14)
local viewWorld = Instance.new("WorldModel")
viewWorld.Parent = view
local viewCam = Instance.new("Camera")
viewCam.FieldOfView = 32
viewCam.Parent = view
view.CurrentCamera = viewCam
local noModel = label(view, { Size = UDim2.fromScale(1, 0.8), Position = UDim2.fromScale(0, 0.1), Text = "", ZIndex = 22 })
label(view, { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, -26), Text = "drag to turn", TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 22 })

local info = frame(picker, { Size = UDim2.fromOffset(400, 300), Position = UDim2.fromOffset(440, 64), BackgroundColor3 = Color3.fromRGB(43, 29, 64), ZIndex = 21 })
corner(info, 14)
local infoIcon = label(info, { Size = UDim2.fromOffset(70, 70), Position = UDim2.fromOffset(14, 12), Text = "", ZIndex = 22 })
local infoPortrait = Instance.new("ImageLabel")
infoPortrait.Size = UDim2.fromOffset(70, 70)
infoPortrait.Position = UDim2.fromOffset(14, 12)
infoPortrait.BackgroundTransparency = 1
infoPortrait.ScaleType = Enum.ScaleType.Crop
infoPortrait.ZIndex = 23
infoPortrait.Parent = info
corner(infoPortrait, 14)
local infoName = label(info, { Size = UDim2.fromOffset(270, 40), Position = UDim2.fromOffset(94, 14), Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22 })
local infoSay = label(info, { Size = UDim2.fromOffset(270, 26), Position = UDim2.fromOffset(94, 54), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PUMP, ZIndex = 22 })
local function para(y, h)
	return label(info, { Size = UDim2.new(1, -28, 0, h), Position = UDim2.fromOffset(14, y), TextScaled = false, TextSize = 18, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 22 })
end
local infoAbout = para(96, 78)
infoAbout.TextScaled = true
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 18
	fit.Parent = infoAbout
end
local infoHow = para(178, 46)
infoHow.TextColor3 = Color3.fromRGB(123, 227, 107)
local infoLevel = para(220, 48)
-- the boosts you are bringing into this game
local infoBag = para(272, 24)
infoBag.TextColor3 = Color3.fromRGB(255, 210, 63)
infoBag.TextScaled = true
local bagFit = Instance.new("UITextSizeConstraint")
bagFit.MaxTextSize = 18
bagFit.Parent = infoBag
infoLevel.TextColor3 = Color3.fromRGB(205, 190, 225)

local viewIndex = 1
local shown, spin, dragging, lastX = nil, 0, false, 0
local chooseBtn

local function profileData()
	local json = player:GetAttribute("ProfileJson")
	if not json then
		return nil
	end
	local ok, data = pcall(function()
		return game:GetService("HttpService"):JSONDecode(json)
	end)
	return ok and data or nil
end

local function showChar()
	local sk = Config.SKILLS[viewIndex]
	local bring = {}
	for _, attr in ipairs({ "Bag", "BoostsOn" }) do
		for bid in string.gmatch(player:GetAttribute(attr) or "", "[^,]+") do
			local b = Progress.BOOSTS[bid]
			if b then
				table.insert(bring, b.icon .. " " .. b.name)
			end
		end
	end
	infoBag.Text = #bring > 0 and ("\u{1F392} Bringing: " .. table.concat(bring, ", ")) or "\u{1F392} No boosts this game (get them in the Lobby shop)"

	if shown then
		shown:Destroy()
		shown = nil
	end
	local previews = ReplicatedStorage:FindFirstChild("Previews")
	local src = previews and previews:FindFirstChild(sk.name)
	do
		-- the skin this player wears for the character
		local pd = profileData()
		local worn = pd and pd.skins and pd.skins[sk.id]
		for _, skin in ipairs(Config.SKINS or {}) do
			if skin.id == worn and previews and previews:FindFirstChild(skin.model) then
				src = previews:FindFirstChild(skin.model)
			end
		end
	end
	spin = 0
	if src then
		shown = src:Clone()
		shown.Parent = viewWorld
		pcall(require(ReplicatedStorage.Shared.PreviewPose), shown, sk.id, src.Name) -- the character's own idle
		noModel.Visible = false
	else
		noModel.Visible = true
		noModel.Text = sk.icon .. "\n3D model coming soon"
	end
	view.BackgroundColor3 = sk.color:Lerp(Color3.fromRGB(26, 16, 38), 0.75)
	local si = Config.SKILL_INFO[sk.id] or {}
	local portrait = Config.PORTRAITS_GAME[sk.id] or Config.PORTRAITS[sk.id] or 0
	infoPortrait.Image = portrait > 0 and ("rbxassetid://" .. portrait) or ""
	infoPortrait.Visible = portrait > 0
	infoIcon.Text = portrait > 0 and "" or sk.icon
	infoName.Text = sk.name
	infoSay.Text = sk.say
	infoAbout.Text = si.about or ""
	-- this floor's real room for the invitation, the painted wall and the plant
	local how = si.how
	local function roomOf(id)
		for _, o in ipairs(HouseMap.objects or {}) do
			if o.id == id then
				local y = (o.kind == "invite" or o.kind == "uv") and o.y + 1 or o.y
				for _, f in ipairs(HouseMap.floors) do
					if o.x >= f.x0 and o.x <= f.x1 and y >= f.y0 and y <= f.y1 then
						return f.name
					end
				end
			end
		end
		return nil
	end
	local where = { brainy = { "invite", "Find the twisty invitation in the %s and press E. Press Think! (R) when you're stuck." }, glow = { "uv", "Press E at the painted wall in the %s. Press Flare (R) to light up far around you and give friends near you a lift." }, bramble = { "plant", "Find the big plant in the %s and press E. Stand in a doorway and press Vines (R)." } }
	local w = where[sk.id]
	local room = w and roomOf(w[1])
	if room then
		how = string.format(w[2], room)
	end
	infoHow.Text = how and ("\u{1F3AE} " .. how) or ""
	local data = profileData()
	local xp = data and data.xp and data.xp[sk.id] or 0
	local level = Progress.level(xp)
	local picks = data and data.picks and data.picks[sk.id]
	local n = 0
	if picks then
		for _ in pairs(picks) do
			n += 1
		end
	end
	infoLevel.Text = "\u{2B50} Level " .. level .. "  (" .. xp .. " XP)\n" .. (n > 0 and (n .. " upgrade" .. (n == 1 and "" or "s") .. " chosen") or "Level up by playing as " .. sk.name .. " - choose upgrades in the Lobby.")
	local mine = player:GetAttribute("Skill") == sk.id
	chooseBtn.Text = mine and ("\u{2705} You are " .. sk.name) or ("Choose " .. sk.name)
	chooseBtn.BackgroundColor3 = mine and Color3.fromRGB(47, 107, 58) or PUMP
end

button(picker, "\u{25C0}", { Size = UDim2.fromOffset(70, 48), Position = UDim2.fromOffset(20, 384), ZIndex = 22 }, function()
	viewIndex = (viewIndex - 2) % #Config.SKILLS + 1
	showChar()
end)
button(picker, "\u{25B6}", { Size = UDim2.fromOffset(70, 48), Position = UDim2.fromOffset(350, 384), ZIndex = 22 }, function()
	viewIndex = viewIndex % #Config.SKILLS + 1
	showChar()
end)
chooseBtn = button(picker, "Choose", { Size = UDim2.fromOffset(230, 48), Position = UDim2.fromOffset(105, 384), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 22 }, function()
	remotes.PickSkill:FireServer(Config.SKILLS[viewIndex].id)
end)
player:GetAttributeChangedSignal("Skill"):Connect(showChar)
player:GetAttributeChangedSignal("ProfileJson"):Connect(showChar)
-- controller: LB / RB step through the characters, the right stick turns
-- the model, B closes (= ready, like the X)
do
	Gamepad.panel(picker, chooseBtn, function()
		if player:GetAttribute("Skill") then
			remotes.Ready:FireServer()
		end
		picker.Visible = false
	end)
	local function stepChar(d)
		if picker.Visible then
			viewIndex = (viewIndex - 1 + d) % #Config.SKILLS + 1
			showChar()
		end
	end
	Gamepad.bind(Enum.KeyCode.ButtonL1, function()
		stepChar(-1)
	end, true)
	Gamepad.bind(Enum.KeyCode.ButtonR1, function()
		stepChar(1)
	end, true)
	local padTurn = 0
	UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			padTurn = math.abs(input.Position.X) > 0.2 and input.Position.X or 0
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		if padTurn ~= 0 and picker.Visible then
			spin += padTurn * dt * 3
		end
	end)
	Gamepad.hint(chooseBtn, "A")
end

-- drag the model round; it faces you to begin with
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
	if not shown or not picker.Visible then
		return
	end
	-- Roblox characters face -Z; turn it round to face the camera on +Z
	shown:PivotTo(CFrame.Angles(0, math.pi + spin, 0))
	local cf, size = require(ReplicatedStorage.Shared.ModelBounds)(shown) -- the parts you can see
	local dist = size.Y * 0.62 / math.tan(math.rad(viewCam.FieldOfView / 2))
	viewCam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, size.Y * 0.05, dist), cf.Position)
end)

local function openPicker()
	for i, sk in ipairs(Config.SKILLS) do
		if sk.id == player:GetAttribute("Skill") then
			viewIndex = i
		end
	end
	showChar()
end
-- a new game: choose (or keep) your character. Checked a moment later, once
-- every change the server made for the new game has arrived.
RoundState:GetAttributeChangedSignal("Status"):Connect(function()
	task.delay(0.3, function()
		if RoundState:GetAttribute("Status") == "playing" and not RoundState:GetAttribute("HostOut") and RoundState:GetAttribute("EndsAt") == nil then
			picker.Visible = true
		end
	end)
end)
picker:GetPropertyChangedSignal("Visible"):Connect(function()
	if picker.Visible then
		openPicker()
	end
end)
task.defer(openPicker)
label(picker, { Size = UDim2.fromOffset(150, 40), Position = UDim2.fromOffset(20, 450), Text = "Difficulty", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 21 })
label(picker, { Size = UDim2.fromOffset(150, 44), Position = UDim2.fromOffset(20, 506), Text = "Mood", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 21 })
local giggly = button(picker, "\u{1F604} Giggly", { Size = UDim2.fromOffset(160, 44), Position = UDim2.fromOffset(180, 506), ZIndex = 22 }, function()
	remotes.SetSpook:FireServer("giggly")
end)
local spooky = button(picker, "\u{1F47B} Spooky", { Size = UDim2.fromOffset(160, 44), Position = UDim2.fromOffset(356, 506), ZIndex = 22 }, function()
	remotes.SetSpook:FireServer("spooky")
end)
button(picker, "\u{25B6} Play", { Size = UDim2.fromOffset(240, 52), Position = UDim2.new(1, -260, 0, 502), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 22 }, function()
	if not player:GetAttribute("Skill") then
		remotes.PickSkill:FireServer(Config.SKILLS[viewIndex].id)
	end
	remotes.Ready:FireServer()
	picker.Visible = false
end)
do
local diffBtns = {}
for i, key in ipairs(Config.DIFFICULTY_ORDER) do
	diffBtns[key] = button(picker, Config.DIFFICULTY[key].name, { Size = UDim2.fromOffset(150, 40), Position = UDim2.fromOffset(180 + (i - 1) * 166, 450), ZIndex = 22 }, function()
		remotes.SetDifficulty:FireServer(key)
	end)
end
local function paintDifficulty()
	local d = RoundState:GetAttribute("Difficulty")
	for key, b in pairs(diffBtns) do
		b.BackgroundColor3 = key == d and Color3.fromRGB(232, 80, 91) or Color3.fromRGB(75, 58, 102)
	end
end
RoundState:GetAttributeChangedSignal("Difficulty"):Connect(paintDifficulty)
paintDifficulty()
do
-- only the party leader can change these; everyone else sees what was chosen
local leaderNote = label(picker, { Size = UDim2.fromOffset(300, 20), Position = UDim2.new(1, -320, 0, 480), Text = "The party leader picks these", TextColor3 = Color3.fromRGB(185, 168, 207), TextScaled = false, TextSize = 14, Visible = false, ZIndex = 22 })
local function paintLeader()
	local lead = RoundState:GetAttribute("Leader")
	local mine = lead == nil or lead == player.UserId
	for _, b in pairs(diffBtns) do
		b.Active, b.AutoButtonColor = mine, mine
	end
	giggly.Active, giggly.AutoButtonColor = mine, mine
	spooky.Active, spooky.AutoButtonColor = mine, mine
	leaderNote.Visible = not mine
end
RoundState:GetAttributeChangedSignal("Leader"):Connect(paintLeader)
paintLeader()
end
local function paintSpook()
	local s = RoundState:GetAttribute("Spook")
	giggly.BackgroundColor3 = s == "giggly" and PUMP or Color3.fromRGB(75, 58, 102)
	spooky.BackgroundColor3 = s == "spooky" and PUMP or Color3.fromRGB(75, 58, 102)
end
RoundState:GetAttributeChangedSignal("Spook"):Connect(paintSpook)
paintSpook()
-- characters are chosen before a game starts: no changing in the middle
local function midGame()
	return RoundState:GetAttribute("Status") == "playing" and (RoundState:GetAttribute("HostOut") == true or RoundState:GetAttribute("EndsAt") ~= nil)
end
local function paintPick()
	pickBtn.Visible = not midGame()
	if midGame() then
		picker.Visible = false
	end
end
RoundState:GetAttributeChangedSignal("Status"):Connect(paintPick)
RoundState:GetAttributeChangedSignal("HostOut"):Connect(paintPick)
RoundState:GetAttributeChangedSignal("EndsAt"):Connect(paintPick)
paintPick()
pickBtn.Activated:Connect(function()
	if midGame() then
		return toast("The game has started - you can change character before the next game.", 3)
	end
	picker.Visible = not picker.Visible
end)

-- ---------- keypad ----------
end
local keypad = frame(gui, { Size = UDim2.fromOffset(250, 300), Position = UDim2.new(1, -270, 0.5, -150), Visible = false, ZIndex = 30 })
corner(keypad, 16)
label(keypad, { Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 8), Text = "Door keypad", ZIndex = 31 })
local entered = label(keypad, { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 44), Text = "_ _ _", RichText = true, ZIndex = 31 })
local pressed = {}
for i, c in ipairs(Config.COLORS) do
	button(keypad, Config.COLOR_SHAPE[c] or "", {
		Size = UDim2.fromOffset(100, 80),
		Position = UDim2.fromOffset(18 + ((i - 1) % 2) * 112, 84 + math.floor((i - 1) / 2) * 90),
		BackgroundColor3 = Config.COLOR3[c],
		ZIndex = 31,
	}, function()
		table.insert(pressed, c)
		local shown = {}
		for j = 1, 3 do
			shown[j] = pressed[j] and (Config.COLOR_SHAPE[pressed[j]] or ('<font color="' .. hex(Config.COLOR3[pressed[j]]) .. '">\u{25CF}</font>')) or "_"
		end
		entered.Text = table.concat(shown, " ")
		playLocal("beep", 0.6)
		remotes.Press:FireServer(c)
		if #pressed >= 3 then
			pressed = {}
			task.delay(0.6, function()
				entered.Text = "_ _ _"
			end)
		end
	end)
end
button(keypad, "Close", { Size = UDim2.fromOffset(214, 34), Position = UDim2.fromOffset(18, 262), ZIndex = 31 }, function()
	keypad.Visible = false
end)
remotes.OpenKeypad.OnClientEvent:Connect(function()
	pressed = {}
	entered.Text = "_ _ _"
	keypad.Visible = true
end)
Gamepad.panel(keypad)

-- ---------- skills that are buttons: Shadow, Patch, Echo ----------
local aiming = false
local SKILL_TEXT = { shadow = "\u{1F319} Sneak", patch = "\u{1F6E1} Shield", echo = "\u{1F3A7} Noise", muscle = "\u{1F4AA} Barricade", glow = "\u{2728} Flare",
	tinker = "\u{1F527} Toolkit", brainy = "\u{1F9E0} Think!", bramble = "\u{1F33F} Vines" }
local KEYS = not TOUCH and UserInputService.KeyboardEnabled -- show the R key on the button
do
local function paintSkill()
	local s = player:GetAttribute("Skill")
	local icon = "\u{2B50}"
	for _, sk in ipairs(Config.SKILLS) do
		if sk.id == s then
			icon = sk.icon
		end
	end
	skillBtn.Text = (SKILL_TEXT[s] or (icon .. " Skill")) .. (KEYS and " (R)" or "")
end
player:GetAttributeChangedSignal("Skill"):Connect(paintSkill)
paintSkill()
local function useSkill()
	local s = player:GetAttribute("Skill")
	if s == "echo" and Gamepad.on() then
		-- a controller throws the noise at the middle of the screen
		local spot = Gamepad.aimPoint({ player.Character }, 300)
		if spot then
			remotes.UseSkill:FireServer(spot)
		else
			toast("\u{1F3A7} Point the camera at a floor or wall to throw a noise there.", 3)
		end
	elseif s == "echo" then
		aiming = true
		toast("\u{1F3A7} Tap or click a spot to throw a noise there.", 3)
	elseif SKILL_TEXT[s] then
		remotes.UseSkill:FireServer()
	else
		local function roomOfObj(id)
			for _, o in ipairs(HouseMap.objects) do
				if o.id == id then
					local y = (o.kind == "invite" or o.kind == "uv") and o.y + 1 or o.y
					for _, f in ipairs(HouseMap.floors) do
						if o.x >= f.x0 and o.x <= f.x1 and y >= f.y0 and y <= f.y1 then
							return f.name
						end
					end
				end
			end
			return "house"
		end
		local tips = { tinker = "Hold F at a locked door to pick it - no key needed. Once a game, hold F at the big door's keypad to learn a color.", brainy = "Find the twisty invitation in the " .. roomOfObj("invite") .. " and press E to read it.",
			muscle = "Find the doorway heaped with junk and hold E to shove it clear.", glow = "Find the painted wall in the " .. roomOfObj("uv") .. " and press E to light it up.",
			bramble = "Find the big plant in the " .. roomOfObj("plant") .. " and press E to ask it." }
		local tip = tips[s] or "Walk up to things and press E."
		if Gamepad.on() then
			tip = string.gsub(string.gsub(string.gsub(tip, "hold F", "hold Y"), "press E", "press X"), "hold E", "hold X")
		end
		toast(tip, 4)
	end
end
skillBtn.Activated:Connect(useSkill)
-- R uses the skill from the keyboard
UserInputService.InputBegan:Connect(function(input, used)
	if not used and input.KeyCode == Enum.KeyCode.R then
		useSkill()
	end
end)
-- controller: RB uses the skill (not while choosing a character or caged)
Gamepad.bind(Enum.KeyCode.ButtonR1, function()
	if not picker.Visible and not player:GetAttribute("Caged") and not player:GetAttribute("Escaped") then
		useSkill()
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		shiftHeld = true
	end
	if input.KeyCode == Enum.KeyCode.M and not processed and not TOUCH then
		mouseLook = not mouseLook
	end
	if not aiming or processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		aiming = false
		local ray = workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
		if hit then
			remotes.UseSkill:FireServer(hit.Position)
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		shiftHeld = false
	end
end)
UserInputService.JumpRequest:Connect(function()
	if player:GetAttribute("Hidden") then
		remotes.Unhide:FireServer()
	end
end)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space and player:GetAttribute("Hidden") then
		remotes.Unhide:FireServer()
	end
end)

-- ---------- boosts brought from the Lobby ----------
-- Tap boosts (Candy, Energy Drink, Extra Clue) sit in the bag until used;
-- keys 1 and 2 on a keyboard. Shield and Head Start work by themselves and
-- show as ON badges (the shield greys out once it has saved you).
local boostBar = frame(gui, { Size = UDim2.fromOffset(290, 56), Position = TOUCH and UDim2.new(1, -300, 1, -362) or UDim2.new(1, -300, 1, -222), BackgroundTransparency = 1 })
local boostList = Instance.new("UIListLayout")
boostList.FillDirection = Enum.FillDirection.Horizontal
boostList.HorizontalAlignment = Enum.HorizontalAlignment.Right
boostList.VerticalAlignment = Enum.VerticalAlignment.Center
boostList.Padding = UDim.new(0, 6)
boostList.SortOrder = Enum.SortOrder.LayoutOrder
boostList.Parent = boostBar
local function split(s)
	local out = {}
	for id in string.gmatch(s or "", "[^,]+") do
		table.insert(out, id)
	end
	return out
end
local function boostSlot(id, order, tag, onClick)
	local b = Progress.BOOSTS[id]
	local img = Config.BOOST_IMAGES[id] or 0
	local slot
	if img > 0 then
		slot = Instance.new("ImageButton")
		slot.Image = "rbxassetid://" .. img
		slot.BackgroundColor3 = NIGHT
		slot.BackgroundTransparency = 0.3
		slot.Size = UDim2.fromOffset(52, 52)
		slot.LayoutOrder = order
		corner(slot, 26)
		slot.Parent = boostBar
		if onClick then
			slot.Activated:Connect(onClick)
		end
	else
		slot = button(boostBar, b.icon, { Size = UDim2.fromOffset(52, 52), LayoutOrder = order }, onClick)
	end
	label(slot, { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -12), Text = tag, TextStrokeTransparency = 0.2 })
	return slot
end
local function paintBoosts()
	for _, c in ipairs(boostBar:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, id in ipairs(split(player:GetAttribute("Bag"))) do
		local slot = boostSlot(id, i, i <= 2 and not TOUCH and ("Tap \u{00B7} " .. i) or "Tap", function()
			remotes.UseBoost:FireServer(id)
		end)
		if i == 1 then
			Gamepad.hint(slot, "LB")
		end
	end
	for i, id in ipairs(split(player:GetAttribute("BoostsOn"))) do
		local used = id == "shield" and not player:GetAttribute("Shield")
		local s = boostSlot(id, 10 + i, used and "Used" or "ON")
		if s:IsA("ImageButton") then
			s.ImageTransparency = used and 0.6 or 0
		else
			s.TextTransparency = used and 0.6 or 0
		end
		s.AutoButtonColor = false
	end
end
player:GetAttributeChangedSignal("Bag"):Connect(paintBoosts)
player:GetAttributeChangedSignal("BoostsOn"):Connect(paintBoosts)
player:GetAttributeChangedSignal("Shield"):Connect(paintBoosts)
paintBoosts()
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	local n = input.KeyCode == Enum.KeyCode.One and 1 or input.KeyCode == Enum.KeyCode.Two and 2 or nil
	local id = n and split(player:GetAttribute("Bag"))[n]
	if id then
		remotes.UseBoost:FireServer(id)
	end
end)
-- controller: LB uses the first boost in the bag (not while choosing a
-- character, caged or watching the team)
Gamepad.bind(Enum.KeyCode.ButtonL1, function()
	local id = split(player:GetAttribute("Bag"))[1]
	if id and not picker.Visible and not player:GetAttribute("Caged") and not player:GetAttribute("Escaped") then
		remotes.UseBoost:FireServer(id)
	end
end)

-- ---------- map of the rooms you have found ----------
-- A small map in the corner, north up, the exit door at the top. Rooms appear
-- as you walk into them; you are the arrow, teammates are dots (red = caged).
-- N or the Map button opens and closes it.
local MAP_W = TOUCH and 240 or 300
local PX = MAP_W / HouseMap.w
local MAP_H = math.floor(PX * HouseMap.h + 0.5)
-- computers: the map in the bottom-left corner with the bars above it;
-- touch screens: the bars at the top left with the map under them
local BARS_H = TOUCH and 92 or 124 -- computers: a line of level bonuses at the bottom
local mapAt = TOUCH and UDim2.fromOffset(10, 60 + BARS_H + 6) or UDim2.new(0, 10, 1, -(MAP_H + 32) - 10)
bars.Size = UDim2.fromOffset(MAP_W + 8, BARS_H)
do
	-- what this character's levels give, all the time: "Your levels: run +10%,
	-- stamina +20%..." (computers: its own line; phones: it takes turns with
	-- the building name, 5 s each)
	local levels = label(bars, { Size = UDim2.new(1, -16, 0, TOUCH and 32 or 30), Position = UDim2.fromOffset(8, TOUCH and 54 or 88), Text = "", TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Color3.fromRGB(150, 220, 255), Visible = not TOUCH })
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 14
	cap.Parent = levels
	local function pct(x)
		return math.floor(x * 100 + 0.5)
	end
	local function paint()
		local parts = {}
		local run = (player:GetAttribute("RunMult") or 1) - 1
		if run > 0.001 then
			table.insert(parts, "\u{1F3C3} run +" .. pct(run) .. "%")
		end
		local stam = (player:GetAttribute("StaminaMult") or 1) - 1
		if stam > 0.001 then
			table.insert(parts, "\u{1F49A} stamina +" .. pct(stam) .. "%")
		end
		-- Patch's own "twice as fast" is her character, not a level
		local hold = (player:GetAttribute("HoldMult") or 1) / (player:GetAttribute("Skill") == "patch" and 0.5 or 1)
		if hold < 0.999 then
			table.insert(parts, "\u{270B} hands " .. pct(1 / hold - 1) .. "% faster")
		end
		local sight = 1 - (player:GetAttribute("SightMult") or 1)
		if sight > 0.001 then
			table.insert(parts, "\u{1F441} host sees you " .. pct(sight) .. "% less")
		end
		local cool = 1 - (player:GetAttribute("CooldownMult") or 1)
		if cool > 0.001 then
			table.insert(parts, "\u{1F504} recharge " .. pct(cool) .. "% faster")
		end
		levels.Text = #parts > 0 and ("\u{2B06} Your levels: " .. table.concat(parts, "  ")) or "\u{2B06} No level bonuses yet - play to level up!"
	end
	for _, a in ipairs({ "RunMult", "StaminaMult", "HoldMult", "SightMult", "CooldownMult", "Skill" }) do
		player:GetAttributeChangedSignal(a):Connect(paint)
	end
	paint()
	if TOUCH then
		task.spawn(function()
			while levels.Parent do
				task.wait(5)
				levels.Visible = not levels.Visible
				roomName.Visible = not levels.Visible
			end
		end)
	end
end
local mapBox = frame(gui, { Size = UDim2.fromOffset(MAP_W + 8, MAP_H + 32), Position = mapAt, BackgroundTransparency = 0.25 })
corner(mapBox, 10)
local mapArea = frame(mapBox, { Size = UDim2.fromOffset(MAP_W, MAP_H), Position = UDim2.fromOffset(4, 28), BackgroundColor3 = Color3.fromRGB(10, 6, 16), BackgroundTransparency = 0, ClipsDescendants = true })
local mapTitle = label(mapBox, { Size = UDim2.new(1, -44, 0, 20), Position = UDim2.fromOffset(8, 4), Text = "\u{1F5FA} Map" .. (TOUCH and "" or " (N)"), TextXAlignment = Enum.TextXAlignment.Left })
local mapOpenBtn = button(gui, "\u{1F5FA} Map" .. (TOUCH and "" or " (N)"), { Size = UDim2.fromOffset(110, 36), Position = mapAt, Visible = false })
local function showMap(open)
	mapBox.Visible = open
	mapOpenBtn.Visible = not open
	if not TOUCH then
		-- the bars sit on top of the map, or on top of the Map button when it is closed
		mapOpenBtn.Position = UDim2.new(0, 10, 1, -46)
		bars.Position = open and UDim2.new(0, 10, 1, -(MAP_H + 32) - 10 - BARS_H - 6) or UDim2.new(0, 10, 1, -46 - BARS_H - 6)
	end
end
showMap(mapBox.Visible)
button(mapBox, "X", { Font = Enum.Font.GothamBlack, Size = UDim2.fromOffset(28, 22), Position = UDim2.new(1, -32, 0, 3), BackgroundColor3 = Color3.fromRGB(150, 60, 70) }, function()
	showMap(false)
end)
mapOpenBtn.Activated:Connect(function()
	showMap(true)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.N and not processed then
		showMap(not mapBox.Visible)
	end
end)
Gamepad.bind(Enum.KeyCode.DPadLeft, function()
	showMap(not mapBox.Visible)
end)
Gamepad.hint(mapOpenBtn, "Left")

local roomTiles, found, viewParts, lockConns = {}, {}, {}, {}
local loftView -- the loft, drawn over its room; bright when you are up there
local function mapRect(x0, y0, x1, y1, color, z)
	local f = frame(mapArea, { Position = UDim2.fromOffset(x0 * PX, y0 * PX), Size = UDim2.fromOffset((x1 - x0 + 1) * PX, (y1 - y0 + 1) * PX), BackgroundColor3 = color, BackgroundTransparency = 0, Visible = false, ZIndex = z or 2 })
	table.insert(viewParts, f)
	return f
end
local ROOM_COLOR = Color3.fromRGB(92, 70, 128)
local function floorOf(x, y)
	for _, f in ipairs(HouseMap.floors) do
		if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
			return f.name
		end
	end
	return nil
end
-- draw this game's house (hidden until each room is found)
local function buildView()
	for _, p in ipairs(viewParts) do
		p:Destroy()
	end
	for _, c in ipairs(lockConns) do
		c:Disconnect()
	end
	viewParts, lockConns, roomTiles, found = {}, {}, {}, {}
	loftView = nil
	for _, f in ipairs(HouseMap.floors) do
		local r = mapRect(f.x0, f.y0, f.x1, f.y1, ROOM_COLOR)
		-- the room's name fills its tile (wrapped, up to 18 px) so it can be read
		local nm = label(r, { Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromOffset(2, 2), Text = f.name, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Color3.fromRGB(240, 228, 250), TextStrokeTransparency = 0.4, ZIndex = 3 })
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = 18
		cap.Parent = nm
		-- Brainy's Key Finder: a key in rooms that hide one
		label(r, { Name = "KeyMark", Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Text = "\u{1F511}", ZIndex = 4, Visible = string.find("," .. (RoundState:GetAttribute("KeyRooms") or "") .. ",", "," .. f.name .. ",", 1, true) ~= nil })
		roomTiles[f.name] = { r }
	end
	-- doorways: walkable tiles between rooms, shown once a room beside them is found
	for y, row in ipairs(HouseMap.map) do
		for x = 1, #row do
			local tx, ty = x - 1, y - 1
			local ch = string.sub(row, x, x)
			if (ch == "." or ch == "L") and not floorOf(tx, ty) then
				local d = mapRect(tx, ty, tx, ty, ROOM_COLOR)
				-- locked doors show gold (the blocked passage red) until they open
				for _, o in ipairs(HouseMap.objects) do
					if o.kind == "lock" and o.x == tx and o.y == ty then
						local icon = label(d, { Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Text = o.blocked and "\u{1F6A7}" or "\u{1F512}", TextStrokeTransparency = 0.3, ZIndex = 6 })
						local function paint()
							local open = RoundState:GetAttribute("Lock_" .. o.id)
							d.BackgroundColor3 = open and ROOM_COLOR or (o.blocked and Color3.fromRGB(232, 80, 91) or Color3.fromRGB(255, 210, 63))
							icon.Visible = not open
						end
						table.insert(lockConns, RoundState:GetAttributeChangedSignal("Lock_" .. o.id):Connect(paint))
						paint()
					end
				end
				for _, n in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
					local name = floorOf(tx + n[1], ty + n[2])
					if name then
						table.insert(roomTiles[name], d)
					end
				end
			end
		end
	end
	if HouseMap.loft then
		local L = HouseMap.loft
		loftView = mapRect(L.x0, L.y0, L.x1, L.y1, Color3.fromRGB(190, 150, 90), 3)
		loftView.BackgroundTransparency = 0.8
		local name = floorOf(L.x0, L.y0)
		if name then
			table.insert(roomTiles[name], loftView)
		end
		-- "Loft" goes at the foot of its stairs, below the room names (over
		-- the loft itself it sat on top of the next room's name)
		if L.stairX and L.stairY1 then
			local right = L.stairX > (L.x0 + L.x1) / 2
			local tag = mapRect(L.stairX, L.stairY1, L.stairX, L.stairY1, Color3.new(0, 0, 0), 5)
			tag.BackgroundTransparency = 1
			local loftName = label(tag, { Size = UDim2.fromOffset(6 * PX, 12), AnchorPoint = Vector2.new(right and 1 or 0, 1), Position = UDim2.fromScale(right and 1 or 0, 1), Text = "\u{2B06} Loft", TextXAlignment = right and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 240, 200), TextStrokeTransparency = 0.3, ZIndex = 5 })
			local loftCap = Instance.new("UITextSizeConstraint")
			loftCap.MaxTextSize = 12
			loftCap.Parent = loftName
			local stairRoom = floorOf(L.stairX, L.stairY1)
			if stairRoom then
				table.insert(roomTiles[stairRoom], tag)
			end
		end
	end
	-- the way out, once you have seen the room it is in
	for _, o in ipairs(HouseMap.objects) do
		if o.kind == "door" then
			local name = floorOf(o.x, o.y + 1)
			local door = mapRect(o.x - 0.5, o.y, o.x + 0.5, o.y, PUMP, 4)
			label(door, { Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Text = "\u{1F6AA}", TextStrokeTransparency = 0.3, ZIndex = 6 })
			if name then
				table.insert(roomTiles[name], door)
			end
		elseif o.kind == "cage" then
			-- the cage, where a caught friend waits to be freed
			local name = floorOf(o.x, o.y)
			local cage = mapRect(o.x, o.y, o.x, o.y, Color3.fromRGB(150, 60, 70), 4)
			cage.BackgroundTransparency = 0.3
			label(cage, { Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Text = "\u{26D3}", TextStrokeTransparency = 0.3, ZIndex = 6 })
			if name then
				table.insert(roomTiles[name], cage)
			end
		end
	end
end
buildView()
RoundState:GetAttributeChangedSignal("KeyRooms"):Connect(function()
	local list = "," .. (RoundState:GetAttribute("KeyRooms") or "") .. ","
	for name, tiles in pairs(roomTiles) do
		local mark = tiles[1] and tiles[1]:FindFirstChild("KeyMark")
		if mark then
			mark.Visible = string.find(list, "," .. name .. ",", 1, true) ~= nil
		end
	end
end)
-- a new game brings a new house
RoundState:GetAttributeChangedSignal("MapJson"):Connect(function()
	readMap()
	buildView()
end)
local function discover(name)
	if name and not found[name] then
		found[name] = true
		for _, r in ipairs(roomTiles[name] or {}) do
			r.Visible = true
		end
	end
end
local me = label(mapArea, { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Text = "\u{1F53A}", TextColor3 = Color3.fromRGB(255, 255, 255), TextStrokeTransparency = 0, ZIndex = 6 })
local dots = {}
local SKILL_COLOR = {}
for _, sk in ipairs(Config.SKILLS) do
	SKILL_COLOR[sk.id] = sk.color
end
local function onMap(pos)
	return UDim2.fromOffset(pos.X / T * PX, pos.Z / T * PX)
end
RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		discover(floorOf(math.floor(hrp.Position.X / T), math.floor(hrp.Position.Z / T)))
		me.Position = onMap(hrp.Position)
		-- up on the loft or down on the floor: the map follows you
		local up = HouseMap.loft and hrp.Position.Y > HouseMap.loft.h + 1
		mapTitle.Text = "\u{1F5FA} Map \u{00B7} " .. (up and "Loft" or "Ground") .. (TOUCH and "" or " (N)")
		if loftView then
			loftView.BackgroundTransparency = up and 0.15 or 0.8
		end
		local lv = hrp.CFrame.LookVector
		me.Rotation = math.deg(math.atan2(lv.X, -lv.Z))
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local dot = dots[p]
			if not dot then
				-- a round marker in the character's colour, with their initial
				dot = frame(mapArea, { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 0, ZIndex = 5 })
				corner(dot, 7)
				local ring = Instance.new("UIStroke")
				ring.Color = Color3.new(0, 0, 0)
				ring.Thickness = 1.5
				ring.Parent = dot
				label(dot, { Name = "Initial", Size = UDim2.fromScale(1, 1), Text = string.upper(string.sub(p.DisplayName, 1, 1)), TextColor3 = Color3.new(0, 0, 0), ZIndex = 6 })
				dots[p] = dot
			end
			local h = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			dot.Visible = h ~= nil and not p:GetAttribute("Escaped")
			if h then
				dot.Position = onMap(h.Position)
				dot.BackgroundColor3 = p:GetAttribute("Caged") and Color3.fromRGB(255, 77, 94) or SKILL_COLOR[p:GetAttribute("Skill")] or CREAM
				local initial = dot:FindFirstChild("Initial")
				if initial then
					initial.Text = p:GetAttribute("Caged") and "\u{1F512}" or string.upper(string.sub(p.DisplayName, 1, 1))
				end
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(p)
	if dots[p] then
		dots[p]:Destroy()
		dots[p] = nil
	end
end)

-- ---------- bounce pads (Gummy Bounce House): boing! ----------
local lastBounce = 0
local function watchPad(pad)
	pad.Touched:Connect(function(hit)
		local char = player.Character
		if not char or not hit:IsDescendantOf(char) or os.clock() - lastBounce < 0.5 or player:GetAttribute("Frozen") then
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		lastBounce = os.clock()
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(v.X, 70, v.Z)
		local s = Instance.new("Sound")
		s.SoundGroup = Sfx.group()
		s.SoundId = "rbxassetid://" .. Config.SOUNDS.bounce
		s.Parent = pad
		s:Play()
		game:GetService("Debris"):AddItem(s, 2)
	end)
end
for _, d in ipairs(workspace:GetDescendants()) do
	if d.Name == "BouncePad" and d:IsA("BasePart") then
		watchPad(d)
	end
end
workspace.DescendantAdded:Connect(function(d)
	if d.Name == "BouncePad" and d:IsA("BasePart") then
		watchPad(d)
	end
end)

-- ---------- music ----------
require(ReplicatedStorage.Shared.MusicPlayer).start("game", gui, UDim2.new(1, -110, 0, 10), remotes:WaitForChild("SetMusic"), remotes:WaitForChild("SetSfx"), UDim2.new(1, -250, 0, 134))

-- ---------- who is playing, and their points this game ----------
local SKILL_ICON = {}
for _, sk in ipairs(Config.SKILLS) do
	SKILL_ICON[sk.id] = sk.icon
end
local playersBtn = button(gui, "\u{1F465} Players", { Size = UDim2.fromOffset(96, 36), Position = UDim2.new(1, -110, 0, 52), ZIndex = 5 })
local playersBox = frame(gui, { Size = UDim2.fromOffset(260, 60), Position = UDim2.new(0.77, -268, 0, 52), Visible = false, ZIndex = 6 })
corner(playersBox, 12)
label(playersBox, { Size = UDim2.new(1, -50, 0, 22), Position = UDim2.fromOffset(10, 7), Text = "\u{1F465} In this game", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PUMP, ZIndex = 7 })
button(playersBox, "X", { Font = Enum.Font.GothamBlack, Size = UDim2.fromOffset(28, 24), Position = UDim2.new(1, -34, 0, 6), BackgroundColor3 = Color3.fromRGB(150, 60, 70), ZIndex = 7 }, function()
	playersBox.Visible = false
end)
local playerRows = {}
local function paintPlayers()
	for _, r in ipairs(playerRows) do
		r:Destroy()
	end
	playerRows = {}
	local list = Players:GetPlayers()
	table.sort(list, function(a, b)
		return (a:GetAttribute("GameEarned") or 0) > (b:GetAttribute("GameEarned") or 0)
	end)
	for i, p in ipairs(list) do
		local state = p:GetAttribute("Escaped") and "\u{2705}" or p:GetAttribute("Caged") and "\u{1F512}" or p:GetAttribute("Hidden") and "\u{1F648}" or "\u{1F3C3}"
		local row = label(playersBox, {
			Size = UDim2.new(1, -20, 0, 26),
			Position = UDim2.fromOffset(10, 36 + (i - 1) * 28),
			Text = (SKILL_ICON[p:GetAttribute("Skill")] or "") .. " " .. p.DisplayName .. "  " .. state .. "  " .. tostring(p:GetAttribute("GameEarned") or 0) .. " \u{2B50}",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = p == player and Color3.fromRGB(120, 200, 255) or CREAM,
			ZIndex = 7,
		})
		table.insert(playerRows, row)
	end
	playersBox.Size = UDim2.fromOffset(260, 44 + #list * 28)
end
local function togglePlayers()
	playersBox.Visible = not playersBox.Visible
	if playersBox.Visible then
		paintPlayers()
	end
end
playersBtn.Activated:Connect(togglePlayers)
Gamepad.bind(Enum.KeyCode.DPadDown, togglePlayers)
Gamepad.hint(playersBtn, "Down")
task.spawn(function()
	while true do
		task.wait(0.5)
		if playersBox.Visible then
			paintPlayers()
		end
	end
end)

-- ---------- leave for the Lobby (asks first) ----------
local leaveBtn = button(gui, "\u{1F6AA} Lobby", { Size = UDim2.fromOffset(96, 36), Position = UDim2.new(1, -110, 0, 94), ZIndex = 5 })
local leaveBox = frame(gui, { Size = UDim2.fromOffset(360, 140), Position = UDim2.new(0.5, -180, 0.4, -70), Visible = false, ZIndex = 45 })
corner(leaveBox, 16)
label(leaveBox, { Size = UDim2.new(1, -30, 0, 60), Position = UDim2.fromOffset(15, 10), Text = "Leave this game and go back to the Lobby?", TextWrapped = true, ZIndex = 46 })
button(leaveBox, "Go to Lobby", { Size = UDim2.fromOffset(150, 44), Position = UDim2.fromOffset(20, 82), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 46 }, function()
	leaveBox.Visible = false
	remotes.LeaveToLobby:FireServer()
	toast("Off to the Lobby...", 3)
end)
button(leaveBox, "Stay", { Size = UDim2.fromOffset(150, 44), Position = UDim2.new(1, -170, 0, 82), ZIndex = 46 }, function()
	leaveBox.Visible = false
end)
leaveBtn.Activated:Connect(function()
	leaveBox.Visible = true
end)
Gamepad.panel(leaveBox)

-- ---------- waiting for everyone to choose a character ----------
local pickBanner = label(gui, { Size = UDim2.fromOffset(560, 40), Position = UDim2.new(0.5, -280, 0, 56), BackgroundTransparency = 0.2, BackgroundColor3 = NIGHT, TextColor3 = PUMP, Visible = false, ZIndex = 8 })
corner(pickBanner, 10)
local readyBtn = button(gui, "\u{25B6} I'm ready!", { Size = UDim2.fromOffset(170, 38), Position = UDim2.new(0.5, -85, 0, 100), BackgroundColor3 = PUMP, TextColor3 = NIGHT, Visible = false, ZIndex = 8 }, function()
	if player:GetAttribute("Skill") then
		remotes.Ready:FireServer()
	else
		picker.Visible = true
	end
end)
-- controller Up: "I'm ready" while waiting, otherwise a clue
Gamepad.hint(readyBtn, "Up")
Gamepad.bind(Enum.KeyCode.DPadUp, function()
	if readyBtn.Visible then
		if player:GetAttribute("Skill") then
			remotes.Ready:FireServer()
		else
			picker.Visible = true
		end
	elseif RoundState:GetAttribute("HostOut") or RoundState:GetAttribute("EndsAt") then
		askClue()
	end
end)
task.spawn(function()
	while true do
		task.wait(0.5)
		local waiting = RoundState:GetAttribute("WaitingToPick") or 0
		local deadline = RoundState:GetAttribute("PickDeadline")
		local show = RoundState:GetAttribute("Status") == "playing" and not RoundState:GetAttribute("HostOut") and deadline ~= nil and waiting > 0
		pickBanner.Visible = show
		readyBtn.Visible = show and not player:GetAttribute("Ready") and not picker.Visible
		readyBtn.Text = player:GetAttribute("Skill") and "\u{25B6} I'm ready!" or "Choose a character"
		if show then
			local left = math.max(0, math.floor(deadline - workspace:GetServerTimeNow()))
			local mine = not player:GetAttribute("Ready")
			pickBanner.Text = (mine and "Choose your character and press \u{25B6} Play! " or "Waiting for friends to choose... ")
				.. waiting .. " still choosing \u{00B7} starts anyway in " .. string.format("%d:%02d", math.floor(left / 60), left % 60)
		end
	end
end)

-- ---------- boosts working right now: icon and how long is left ----------
end
local activeRow = frame(gui, { Size = UDim2.fromOffset(290, 46), Position = TOUCH and UDim2.new(1, -300, 1, -412) or UDim2.new(1, -300, 1, -272), BackgroundTransparency = 1 })
local activeList = Instance.new("UIListLayout")
activeList.FillDirection = Enum.FillDirection.Horizontal
activeList.HorizontalAlignment = Enum.HorizontalAlignment.Right
activeList.Padding = UDim.new(0, 6)
activeList.Parent = activeRow
local function activeSlot(boostId, fallback)
	local f = frame(activeRow, { Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 0.3, Visible = false })
	corner(f, 22)
	local ring = Instance.new("UIStroke")
	ring.Color = Color3.fromRGB(123, 227, 107)
	ring.Thickness = 2
	ring.Parent = f
	local imgId = Config.BOOST_IMAGES[boostId] or 0
	if imgId > 0 then
		local pic = Instance.new("ImageLabel")
		pic.Size = UDim2.fromScale(1, 1)
		pic.BackgroundTransparency = 1
		pic.Image = "rbxassetid://" .. imgId
		pic.Parent = f
	else
		label(f, { Size = UDim2.fromScale(1, 1), Text = fallback })
	end
	local t = label(f, { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -12), Text = "", TextStrokeTransparency = 0.2, ZIndex = 3 })
	return f, t
end
local shieldSlot, shieldText = activeSlot("shield", "\u{1F6E1}")
local candySlot, candyText = activeSlot("candy", "\u{1F36C}")
local freezeSlot, freezeText = activeSlot("freeze", "\u{1F9CA}")
local speedSlot, speedText = activeSlot("speed", "\u{26A1}") -- a burst of speed (it always runs out)
do
	-- the speed slot says how much faster ("+5%") above its seconds
	local pct = label(speedSlot, { Name = "Pct", Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, -2), Text = "", TextColor3 = Color3.fromRGB(255, 230, 120), TextStrokeTransparency = 0.2, ZIndex = 3 })
	-- a line floats up over the boost row whenever a skill or boost gives you
	-- something: "+6% stamina", "+5% speed for 3 s"
	local floatAt = TOUCH and UDim2.new(1, -310, 1, -452) or UDim2.new(1, -310, 1, -312)
	local floating = 0
	local function float(text, color)
		floating += 1
		local n = floating
		local l = label(gui, { Size = UDim2.fromOffset(300, 30), Position = floatAt - UDim2.fromOffset(0, ((n - 1) % 3) * 30), Text = text, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = color, TextStrokeTransparency = 0.1, ZIndex = 20 })
		TweenService:Create(l, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = l.Position - UDim2.fromOffset(0, 40), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.delay(2.3, function()
			l:Destroy()
			if floating == n then
				floating = 0
			end
		end)
	end
	local GREEN, GOLD = Color3.fromRGB(123, 227, 107), Color3.fromRGB(255, 230, 120)
	remotes.Boost.OnClientEvent:Connect(function(kind, amount)
		if kind == "plus" and tonumber(amount) then
			float("\u{1F49A} +" .. math.floor(tonumber(amount) + 0.5) .. "% stamina", GREEN)
		elseif kind == "half" then
			float("\u{1F49A} +50% stamina", GREEN)
		elseif kind == "stamina" then
			float("\u{1F49A} Full stamina!", GREEN)
		elseif kind == "candy" then
			float("\u{1F36C} No tiring for 20 s", GREEN)
		elseif kind == "shake" then
			-- a quick shake of the camera (Muscle's Ground Pound nearby)
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			local strength = tonumber(amount) or 1
			if hum then
				task.spawn(function()
					for i = 1, 8 do
						local s = strength * (1 - i / 9) * 0.6
						hum.CameraOffset = Vector3.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, 0)
						task.wait(0.03)
					end
					hum.CameraOffset = Vector3.zero
				end)
			end
		end
	end)
	player:GetAttributeChangedSignal("TeamBurstUntil"):Connect(function()
		local left = (player:GetAttribute("TeamBurstUntil") or 0) - workspace:GetServerTimeNow()
		local mult = player:GetAttribute("TeamBurstMult") or 1
		if left > 0.5 and mult > 1 then
			float("\u{26A1} +" .. math.floor((mult - 1) * 100 + 0.5) .. "% speed for " .. math.floor(left + 0.5) .. " s", GOLD)
		end
	end)
	RunService.Heartbeat:Connect(function()
		local mult = player:GetAttribute("TeamBurstMult") or 1
		pct.Text = speedSlot.Visible and mult > 1 and ("+" .. math.floor((mult - 1) * 100 + 0.5) .. "%") or ""
	end)
end

-- ---------- running and stamina ----------
local stamina, tired, candyUntil = 100, false, 0
remotes.Boost.OnClientEvent:Connect(function(kind, amount)
	if kind == "candy" then
		candyUntil = os.clock() + 20
	elseif kind == "stamina" then
		stamina, tired = 100, false
	elseif kind == "half" then
		stamina = math.min(100, stamina + 50)
	elseif kind == "plus" then
		stamina = math.min(100, stamina + (tonumber(amount) or 0))
		if stamina >= 25 then
			tired = false
		end
	end
end)

-- the heartbeat speeds up and gets louder as the host comes closer
do
local dangerLevel = 0
task.spawn(function()
	while true do
		if Config.HEARTBEAT and dangerLevel >= 2 and not player:GetAttribute("Escaped") and not player:GetAttribute("Caged") then
			local vol = 0.2 + dangerLevel * 0.15
			playLocal("heart", vol)
			task.wait(0.22)
			playLocal("heart", vol * 0.7)
			task.wait(math.max(0.2, 1.2 - dangerLevel * 0.2))
		else
			task.wait(0.3)
		end
	end
end)
-- the host breathes: a looping sound on its head, louder the closer you are
local breathFor

-- the Robot's blackout: only the room it happened in goes dark
local LightingService = game:GetService("Lighting")
local normalLight = { Ambient = LightingService.Ambient, OutdoorAmbient = LightingService.OutdoorAmbient, Brightness = LightingService.Brightness }
local darkLight = { Ambient = Color3.new(0, 0, 0), OutdoorAmbient = Color3.new(0, 0, 0), Brightness = 0 }
local inBlackout = false
local wadeParams = RaycastParams.new()
wadeParams.FilterType = Enum.RaycastFilterType.Exclude
local wadeTold = false

local function roomAt(pos)
	local x, y = math.floor(pos.X / T), math.floor(pos.Z / T)
	for _, f in ipairs(HouseMap.floors) do
		if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
			return f.name
		end
	end
	return nil
end

RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then
		return
	end
	local frozen = player:GetAttribute("Frozen") or player:GetAttribute("Hidden") or player:GetAttribute("Caged")
	outBtn.Visible = player:GetAttribute("Hidden") == true
	if not frozen then
		local moving = hum.MoveDirection.Magnitude > 0.1
		local wantRun = runToggle or shiftHeld
		local candy = os.clock() < candyUntil
		-- Echo's burst after a noise, Patch's Medic Run
		local bonus = player:GetAttribute("RunBonus") or 1
		if (player:GetAttribute("TeamBurstUntil") or 0) > workspace:GetServerTimeNow() then
			bonus *= player:GetAttribute("TeamBurstMult") or 1
		end
		if wantRun and moving and not tired then
			hum.WalkSpeed = Config.RUN * (player:GetAttribute("RunMult") or 1) * bonus
			if not candy then
				stamina = math.max(0, stamina - Config.STAMINA_DRAIN * dt / (player:GetAttribute("StaminaMult") or 1))
				if stamina <= 0 then
					tired = true
					toast("Puffed out! Walk for a bit.", 2)
				end
			end
		else
			hum.WalkSpeed = Config.WALK * bonus
			stamina = math.min(100, stamina + Config.STAMINA_REGEN * dt)
			if tired and stamina >= 25 then
				tired = false
			end
		end
		-- wading through the chocolate river is slow (the bridge is not)
		wadeParams.FilterDescendantsInstances = { char }
		local below = workspace:Raycast(hrp.Position, Vector3.new(0, -8, 0), wadeParams)
		if below and (below.Instance.Name == "ChocolateRiver" or below.Instance.Name == "WadeWater") then
			hum.WalkSpeed *= Config.WADE.kid
			if not wadeTold then
				wadeTold = true
				toast(below.Instance.Name == "WadeWater" and "\u{1F4A7} Wading through water - slow going!" or "\u{1F36B} Wading through chocolate - slow going! Use the bridge.", 3)
			end
		end
	end
	runBtn.BackgroundColor3 = (runToggle or shiftHeld) and PUMP or Color3.fromRGB(75, 58, 102)
	-- the active boosts row
	shieldSlot.Visible = player:GetAttribute("Shield") == true
	shieldText.Text = "ON"
	local candyLeft = candyUntil - os.clock()
	candySlot.Visible = candyLeft > 0
	candyText.Text = candyLeft > 0 and (math.ceil(candyLeft) .. "s") or ""
	local frozenLeft = (RoundState:GetAttribute("FrozenUntil") or 0) - workspace:GetServerTimeNow()
	freezeSlot.Visible = frozenLeft > 0
	freezeText.Text = frozenLeft > 0 and (math.ceil(frozenLeft) .. "s") or ""
	local burstLeft = (player:GetAttribute("TeamBurstUntil") or 0) - workspace:GetServerTimeNow()
	speedSlot.Visible = burstLeft > 0
	speedText.Text = burstLeft > 0 and (math.ceil(burstLeft) .. "s") or ""
	staminaBar.Size = UDim2.fromScale(stamina / 100, 1)
	staminaBar.BackgroundColor3 = tired and Color3.fromRGB(255, 77, 94) or Color3.fromRGB(123, 227, 107)
	gameEarned.Text = "\u{2B50} " .. tostring(player:GetAttribute("GameEarned") or 0) .. " points this game" .. (player:GetAttribute("FriendBonus") and "  \u{1F46B} +10%" or "")

	-- skill countdown: active time, then recharge time
	local serverNow = workspace:GetServerTimeNow()
	local skill = player:GetAttribute("Skill")
	if SKILL_TEXT[skill] then
		-- while a skill is working: its own countdown; then the recharge countdown
		local ACTIVE = { shadow = { "SneakUntil", "\u{1F319} Sneaking" }, glow = { "FlareUntil", "\u{2728} Flare" }, bramble = { "VinesUntil", "\u{1F33F} Vines" },
			echo = { "EchoBurstUntil", "\u{1F3A7} Burst" }, muscle = { "BarricadeUntil", "\u{1F4AA} Barricade" }, brainy = { "ThinkUntil", "\u{1F9E0} Thinking" } }
		local a = ACTIVE[skill]
		local active = a and ((player:GetAttribute(a[1]) or 0) - serverNow) or 0
		local cool = (player:GetAttribute("CoolUntil") or 0) - serverNow
		if skill == "tinker" and player:GetAttribute("ToolkitReady") then
			skillBtn.Text = "\u{1F527} Toolkit ready!" .. (KEYS and " (R)" or "")
			skillBtn.BackgroundColor3 = PUMP
		elseif active > 0 then
			skillBtn.Text = a[2] .. " " .. math.ceil(active) .. "s" .. (KEYS and " (R)" or "")
			skillBtn.BackgroundColor3 = PUMP
		elseif cool > 0 then
			skillBtn.Text = SKILL_TEXT[skill] .. " " .. math.ceil(cool) .. "s" .. (KEYS and " (R)" or "")
			skillBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		else
			skillBtn.Text = SKILL_TEXT[skill] .. (KEYS and " (R)" or "")
			skillBtn.BackgroundColor3 = Color3.fromRGB(47, 107, 58)
		end
	end

	-- escape timer
	local ends = RoundState:GetAttribute("EndsAt")
	local scale, rot, bigOn = 1, 0, false
	if RoundState:GetAttribute("Frenzy") then
		timerLabel.Text = "\u{1F525} FRENZY"
		timerLabel.TextColor3 = Color3.fromRGB(255, 77, 94)
		countdown.last = nil
	elseif ends and RoundState:GetAttribute("Status") == "playing" then
		local exact = math.max(0, ends - serverNow)
		local left = math.floor(exact)
		timerLabel.Text = string.format("\u{23F1} %d:%02d", math.floor(left / 60), left % 60)
		timerLabel.TextColor3 = left < 60 and Color3.fromRGB(255, 77, 94) or CREAM
		local t = os.clock()
		if countdown.last and countdown.last > 60 and left <= 60 then
			countdown.flashUntil = t + 2.5 -- one minute left: flash
		end
		countdown.last = left
		if t < countdown.flashUntil then
			scale = 1.35 + 0.15 * math.sin(t * 12)
			timerLabel.TextColor3 = (math.floor(t * 6) % 2 == 0) and Color3.fromRGB(255, 210, 63) or Color3.fromRGB(255, 77, 94)
		elseif left <= 30 and left > 0 then
			-- the last half minute: bigger, and shaking
			scale = left <= 10 and 1.25 or 1.15
			rot = math.sin(t * 35) * (left <= 10 and 5 or 3)
		end
		if left <= 10 and exact > 0 then
			-- the last ten seconds: a big red number in the middle, pulsing each second
			bigOn = true
			countdown.big.Text = tostring(math.min(10, math.ceil(exact)))
			countdown.bigScale.Scale = 1 + 0.45 * (exact % 1)
		end
	end
	countdown.scale.Scale = scale
	timerLabel.Rotation = rot
	countdown.big.Visible = bigOn

	-- where am I, and how close is the host?
	local r = roomAt(hrp.Position)
	local dark = RoundState:GetAttribute("Blackout")
	local nowDark = (dark ~= nil and dark ~= "" and r == dark)
		or (r ~= nil and string.find("," .. (RoundState:GetAttribute("DarkRooms") or "") .. ",", "," .. r .. ",", 1, true) ~= nil)
	if nowDark ~= inBlackout then
		inBlackout = nowDark
		TweenService:Create(LightingService, TweenInfo.new(0.4), nowDark and darkLight or normalLight):Play()
	end
	local where = HouseMap.name or "The Party House"
	if RoundState:GetAttribute("Tower") then
		where = "\u{1F5FC} " .. (RoundState:GetAttribute("TowerFloor") or 1) .. "/3 \u{00B7} " .. where
	end
	roomName.Text = where
	topRoom.Text = r and ("\u{1F4CD} " .. r) or ""
	local host = workspace:FindFirstChild("PartyHost")
	if host ~= breathFor then
		breathFor = host
		local head = host and (host:FindFirstChild("Head") or host.PrimaryPart)
		if head and Config.SOUNDS.breath then
			local s = Instance.new("Sound")
			s.SoundGroup = Sfx.group()
			s.Name = "Breathing"
			s.SoundId = "rbxassetid://" .. Config.SOUNDS.breath
			s.Looped = true
			s.Volume = 1.4
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			s.RollOffMinDistance = 6
			s.RollOffMaxDistance = 60
			s.Parent = head
			s:Play()
		end
	end
	local level = 0
	if host and host.PrimaryPart then
		local d = (host.PrimaryPart.Position - hrp.Position).Magnitude / T
		if player:GetAttribute("Skill") == "echo" then
			d -= 3
		end
		level = d <= 2 and 5 or d <= 3 and 4 or d <= 5 and 3 or d <= 7 and 2 or d <= 11 and 1 or 0
	end
	for i = 1, 5 do
		steps[i].TextTransparency = i <= level and 0 or 0.8
	end
	dangerLevel = level
end)

-- ---------- a big icon that pops up: items picked up, skills used ----------
end
local popFrame = frame(gui, { Size = UDim2.fromOffset(170, 170), Position = UDim2.new(0.5, -85, 0.55, -85), BackgroundTransparency = 1, Visible = false, ZIndex = 35 })
local popIcon = label(popFrame, { Size = UDim2.fromScale(1, 0.75), Text = "", ZIndex = 36 })
local popText = label(popFrame, { Size = UDim2.new(1.6, 0, 0.25, 0), Position = UDim2.fromScale(-0.3, 0.75), Text = "", ZIndex = 36 })
local popPic = Instance.new("ImageLabel")
popPic.BackgroundTransparency = 1
popPic.Size = UDim2.fromScale(0.75, 0.75)
popPic.Position = UDim2.fromScale(0.125, 0)
popPic.ZIndex = 36
popPic.Visible = false
popPic.Parent = popFrame
local popToken = 0
-- icon: an emoji, or an image asset id (a picture instead)
local function popUp(icon, text)
	popToken += 1
	local my = popToken
	local isPic = typeof(icon) == "number"
	popPic.Visible = isPic
	popPic.Image = isPic and ("rbxassetid://" .. icon) or ""
	popIcon.Text, popText.Text = isPic and "" or icon, text or ""
	popFrame.Size = UDim2.fromOffset(60, 60)
	popFrame.Position = UDim2.new(0.5, -30, 0.55, -30)
	popFrame.Visible = true
	TweenService:Create(popFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(170, 170), Position = UDim2.new(0.5, -85, 0.55, -85) }):Play()
	task.delay(1.6, function()
		if popToken == my then
			popFrame.Visible = false
		end
	end)
end
local function skillIcon(id)
	for _, sk in ipairs(Config.SKILLS) do
		if sk.id == id then
			return sk.icon
		end
	end
	return "\u{2B50}"
end

-- ---------- spectating: when caught (or out), watch the team ----------
local spec = frame(gui, { Size = UDim2.fromOffset(380, 46), Position = UDim2.new(0.5, -190, 1, -160), Visible = false, ZIndex = 25 })
corner(spec, 12)
local specName = label(spec, { Size = UDim2.new(0.5, 0, 0.8, 0), Position = UDim2.fromScale(0.2, 0.1), Text = "", ZIndex = 26 })
local specIndex = 0
-- who you can watch: teammates still in the house, then the host himself
local function teammates()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChildOfClass("Humanoid") and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped") then
			table.insert(list, { name = p.DisplayName, hum = p.Character:FindFirstChildOfClass("Humanoid") })
		end
	end
	local host = workspace:FindFirstChild("PartyHost")
	local hostHum = host and host:FindFirstChildOfClass("Humanoid")
	if hostHum then
		table.insert(list, { name = "The host", hum = hostHum })
	end
	return list
end
local function watch(step)
	local list = teammates()
	local cam = workspace.CurrentCamera
	local mine = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if #list == 0 or step == 0 then
		specIndex = 0
		if mine then
			cam.CameraSubject = mine
		end
		specName.Text = #list == 0 and "Nobody else to watch" or "Your view"
		return
	end
	specIndex = ((specIndex - 1 + step) % #list) + 1
	local who = list[specIndex]
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = who.hum
	specName.Text = "\u{1F440} " .. who.name
end
button(spec, "\u{25C0}", { Size = UDim2.new(0.16, 0, 0.8, 0), Position = UDim2.fromScale(0.02, 0.1), ZIndex = 26 }, function()
	watch(-1)
end)
button(spec, "\u{25B6}", { Size = UDim2.new(0.16, 0, 0.8, 0), Position = UDim2.fromScale(0.7, 0.1), ZIndex = 26 }, function()
	watch(1)
end)
button(spec, "Me", { Size = UDim2.new(0.12, 0, 0.8, 0), Position = UDim2.fromScale(0.87, 0.1), ZIndex = 26 }, function()
	watch(0)
end)
local function paintSpectate()
	local out = player:GetAttribute("Caged") or player:GetAttribute("Escaped")
	spec.Visible = out == true and RoundState:GetAttribute("Status") == "playing"
	if not spec.Visible and specIndex ~= 0 then
		watch(0)
	elseif spec.Visible and specName.Text == "" then
		specName.Text = "Watch your team"
	end
end
player:GetAttributeChangedSignal("Caged"):Connect(paintSpectate)
player:GetAttributeChangedSignal("Escaped"):Connect(paintSpectate)
do
	-- the escape photo: the moment you get out, you cheer in the garden (with
	-- any friends already there), the camera turns to face you, the game's
	-- buttons hide and Roblox takes a picture; a card then offers to save it
	-- to your Roblox captures or share it
	local okCS, CaptureService = pcall(game.GetService, game, "CaptureService")
	local Emotes = require(ReplicatedStorage.Shared.Emotes)
	local card = frame(gui, { Size = UDim2.fromOffset(300, 250), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -170), Visible = false, ZIndex = 40 })
	corner(card, 14)
	label(card, { Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 6), Text = "\u{1F4F8} Escape photo!", TextColor3 = PUMP, ZIndex = 41 })
	local pic = Instance.new("ImageLabel")
	pic.Size = UDim2.fromOffset(280, 158)
	pic.Position = UDim2.fromOffset(10, 36)
	pic.BackgroundTransparency = 1
	pic.ScaleType = Enum.ScaleType.Fit
	pic.ZIndex = 41
	pic.Parent = card
	local shot -- the picture's content id
	local function close()
		card.Visible = false
	end
	button(card, "\u{1F4BE} Save", { Size = UDim2.fromOffset(88, 40), Position = UDim2.fromOffset(10, 202), BackgroundColor3 = Color3.fromRGB(47, 107, 58), ZIndex = 41 }, function()
		if shot then
			pcall(function()
				CaptureService:PromptSaveCapturesToGallery({ shot }, function() end)
			end)
		end
		close()
	end)
	button(card, "\u{1F4E4} Share", { Size = UDim2.fromOffset(88, 40), Position = UDim2.fromOffset(106, 202), BackgroundColor3 = Color3.fromRGB(61, 110, 200), ZIndex = 41 }, function()
		if shot then
			pcall(function()
				CaptureService:PromptShareCapture(shot, "", function() end, function() end)
			end)
		end
		close()
	end)
	button(card, "\u{2716} No thanks", { Size = UDim2.fromOffset(88, 40), Position = UDim2.fromOffset(202, 202), ZIndex = 41 }, close)
	Gamepad.panel(card)
	local busy = false
	local function takePhoto()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if busy or not okCS or not CaptureService or not hrp then
			return
		end
		busy = true
		task.wait(1.2) -- land in the garden first
		Emotes.play("cheer")
		task.wait(0.6)
		local cam = workspace.CurrentCamera
		local look = hrp.Position + Vector3.new(0, 1.2, 0)
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(look + hrp.CFrame.LookVector * 11 + Vector3.new(0, 2.5, 0), look)
		local wasOn = gui.Enabled
		gui.Enabled = false
		task.wait(0.15)
		local done = false
		pcall(function()
			CaptureService:CaptureScreenshot(function(id)
				shot = id
				done = true
			end)
		end)
		local t0 = os.clock()
		while not done and os.clock() - t0 < 3 do
			task.wait(0.05)
		end
		gui.Enabled = wasOn
		cam.CameraType = Enum.CameraType.Custom
		busy = false
		if shot then
			pic.Image = shot
			card.Visible = true
			task.delay(25, function()
				card.Visible = false
			end)
		end
	end
	player:GetAttributeChangedSignal("Escaped"):Connect(function()
		if player:GetAttribute("Escaped") then
			shot = nil
			task.spawn(takePhoto)
		end
	end)
end
player.CharacterAdded:Connect(function()
	task.defer(paintSpectate)
end)
-- keyboard: left / right arrows (or Q / E) switch who you watch
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not spec.Visible then
		return
	end
	if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Q then
		watch(-1)
	elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.E then
		watch(1)
	end
end)
RoundState:GetAttributeChangedSignal("Status"):Connect(paintSpectate)
-- controller: LB / RB switch who you watch
Gamepad.bind(Enum.KeyCode.ButtonL1, function()
	if spec.Visible then
		watch(-1)
	end
end)
Gamepad.bind(Enum.KeyCode.ButtonR1, function()
	if spec.Visible then
		watch(1)
	end
end)

-- ---------- end of round: results ----------
local results = frame(gui, { Size = UDim2.fromOffset(460, 440), Position = UDim2.new(0.5, -230, 0.5, -220), Visible = false, ZIndex = 40 })
corner(results, 18)
do
local resTitle = label(results, { Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 12), TextColor3 = PUMP, ZIndex = 41 })
local resInfo = label(results, { Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 60), ZIndex = 41 })
local resList = label(results, { Size = UDim2.new(1, -40, 0, 190), Position = UDim2.fromOffset(20, 96), TextScaled = false, TextSize = 22, TextYAlignment = Enum.TextYAlignment.Top, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41 })
local resNext = label(results, { Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 1, -96), TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 41 })
local againBtn, lobbyBtn, upBtn
local function chose(choice)
	remotes.Vote:FireServer(choice)
	againBtn.Visible, lobbyBtn.Visible, upBtn.Visible = false, false, false
	resNext.Text = choice == "lobby" and "Going back to the lobby..." or "Waiting for the others..."
end
againBtn = button(results, "\u{1F501} Play again", { Size = UDim2.fromOffset(200, 50), Position = UDim2.new(0.5, -210, 1, -64), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 41 }, function()
	chose("again")
end)
lobbyBtn = button(results, "\u{1F3E0} Back to lobby", { Size = UDim2.fromOffset(200, 50), Position = UDim2.new(0.5, 10, 1, -64), ZIndex = 41 }, function()
	chose("lobby")
end)
upBtn = button(results, "\u{2B06} Next floor", { Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 20, 1, -150), BackgroundColor3 = Color3.fromRGB(70, 209, 96), TextColor3 = NIGHT, Visible = false, ZIndex = 41 }, function()
	chose("next")
end)
-- controller: Play again is chosen to begin with (or Next floor after a win)
Gamepad.panel(results, function()
	return upBtn.Visible and upBtn or againBtn.Visible and againBtn or nil
end, function() end)
local function confetti()
	local colours = { Color3.fromRGB(255, 77, 94), Color3.fromRGB(61, 139, 255), Color3.fromRGB(255, 210, 63), Color3.fromRGB(70, 209, 96), PUMP }
	for i = 1, 70 do
		local c = frame(gui, { Size = UDim2.fromOffset(10, 6), Position = UDim2.new(math.random(), 0, -0.05, 0), BackgroundColor3 = colours[i % #colours + 1], BackgroundTransparency = 0, Rotation = math.random(0, 180), ZIndex = 45 })
		local fall = TweenService:Create(c, TweenInfo.new(2 + math.random() * 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(c.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1.05, 0), Rotation = c.Rotation + 360 })
		fall:Play()
		fall.Completed:Connect(function()
			c:Destroy()
		end)
	end
end
remotes.Results.OnClientEvent:Connect(function(r)
	-- your very first escape: ask once to add Escape Crew to your favourites
	for _, row in ipairs(r.players or {}) do
		if row.userId == player.UserId and row.firstEscape then
			task.delay(4, function()
				pcall(function()
					game:GetService("AvatarEditorService"):PromptSetFavorite(Config.PLACE_IDS.lobby, Enum.AvatarItemType.Asset, true)
				end)
			end)
		end
	end
	resTitle.Text = r.won and "\u{1F389} You escaped the Party House!" or "\u{1F512} Everyone was caught..."
	if r.tower then
		resTitle.Text = r.won and "\u{1F5FC} Tower Run: you reached the top! (+25%)" or ("\u{1F5FC} Tower Run: caught on floor " .. r.tower)
	end
	resInfo.Text = r.difficulty .. "  \u{00B7}  " .. string.format("%d:%02d", math.floor(r.seconds / 60), r.seconds % 60) .. (r.timeBonus > 0 and ("  \u{00B7}  time bonus +" .. r.timeBonus) or "")
	local lines = {}
	for _, row in ipairs(r.players) do
		local extra = ""
		if row.levelUp then
			extra ..= "  \u{2B06} Level " .. row.levelUp .. "!"
		end
		if row.unlocked then
			extra ..= "  \u{1F513} " .. row.unlocked
		end
		if row.friendBonus and row.friendBonus > 0 then
			extra ..= "  \u{1F46B} +" .. row.friendBonus .. " friend bonus"
		end
		table.insert(lines, (row.escaped and "\u{2705} " or "\u{1F512} ") .. row.name .. "  +" .. row.points .. " points" .. extra)
	end
	resList.Text = table.concat(lines, "\n")
	local waitFor = scareBusyUntil - os.clock()
	if waitFor > 0 then
		task.wait(waitFor)
	end
	results.Visible = true
	againBtn.Visible, lobbyBtn.Visible = r.vote == true, r.vote == true
	upBtn.Visible = r.vote == true and r.nextFloor ~= nil
	upBtn.Text = "\u{2B06} Next floor: " .. tostring(r.nextFloor or "")
	spec.Visible = false
	if r.won then
		confetti()
	end
	local left = r.nextIn
	task.spawn(function()
		while left > 0 and results.Visible do
			if againBtn.Visible then
				resNext.Text = "Choose in " .. left .. "... (no choice = back to the lobby)"
			end
			task.wait(1)
			left -= 1
		end
		results.Visible = false
	end)
end)

-- ---------- messages from the server ----------
remotes.Notify.OnClientEvent:Connect(function(kind, text, data)
	local spooky = RoundState:GetAttribute("Spook") == "spooky"
	if kind == "appear" and spooky then
		jumpscare()
	elseif kind == "caught" and data and data.userId == player.UserId then
		hostCloseUp(spooky)
	elseif kind == "spotted" and data and data.userId == player.UserId then
		local cam = workspace.CurrentCamera
		for i = 1, 6 do
			task.delay(i * 0.04, function()
				cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, (math.random() - 0.5) * 0.06)
			end)
		end
	elseif kind == "frenzy" then
		local big = label(gui, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromOffset(620, 170), Text = "\u{1F525} TIME'S UP! \u{1F525}\nThe host knows where you are - get out!", TextColor3 = Color3.fromRGB(255, 60, 60), TextStrokeTransparency = 0.1, Font = Enum.Font.GothamBlack, ZIndex = 31 })
		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - t0
			if t > 4.5 or not big.Parent then
				conn:Disconnect()
				big:Destroy()
				return
			end
			big.Rotation = math.sin(t * 30) * 3
			big.TextTransparency = t > 3.8 and (t - 3.8) / 0.7 or 0
		end)
	elseif kind == "hostmap" then
		-- Echo Map: the host shows through walls for a few seconds
		local h = workspace:FindFirstChild("PartyHost")
		if h then
			local hl = Instance.new("Highlight")
			hl.FillColor, hl.OutlineColor, hl.FillTransparency = Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 220, 220), 0.5
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = h
			game:GetService("Debris"):AddItem(hl, data and data.seconds or 5)
		end
	elseif kind == "corn" and data and data.userId == player.UserId then
		local pic = Config.BOOST_IMAGES and Config.BOOST_IMAGES.candy or 0
		popUp(pic > 0 and pic or "\u{1F383}", tostring(data.found or "") .. " candy corns")
	elseif kind == "quest" and data and data.userId == player.UserId then
		popUp("\u{1F4DC}", "Quest done! +" .. tostring(data.points or 0))
	elseif (kind == "boost" or kind == "pop") and data and data.userId == player.UserId then
		local pic
		for id, b in pairs(Progress.BOOSTS) do
			if b.name == data.item then
				pic = Config.BOOST_IMAGES and Config.BOOST_IMAGES[id]
			end
		end
		popUp((pic and pic > 0) and pic or (data.icon or "\u{2B50}"), data.item or "")
	elseif (kind == "sneak" or kind == "heal" or kind == "lure") and data and data.userId == player.UserId then
		popUp(skillIcon(player:GetAttribute("Skill")), kind == "sneak" and "Sneaking!" or kind == "heal" and "Shields up!" or "Noise!")
	elseif kind == "start" then
		keypad.Visible = false
		stamina, tired = 100, false
	end
	toast(text, (kind == "clue" or kind == "reveal") and 6 or 3.5)
end)

-- ---------- the coach: tips for a new player's first games ----------
do
	local STEPS = {
		"\u{1F388} Find the clue balloons and pop them: walk up and press E. Careful - some are tricks!",
		"A real balloon shows a color. Three colors = the code for the big exit door.",
		"\u{1F512} A locked door? Search drawers, boxes and coats for its key. Tinker can pick locks.",
		"\u{1F47B} The host is out! Hold Shift to run, and press E at a \u{1F648} hiding place to hide.",
		"Caught? Friends free you from the cage. Stuck? Press \u{1F4A1} Clue for a hint (it costs points).",
		"\u{1F6AA} You know the code! Go to the big door and type the colors on the keypad.",
	}
	local box = frame(gui, { Size = UDim2.fromOffset(330, 116), Position = UDim2.new(0, 10, 0.3, 0), BackgroundColor3 = NIGHT, BackgroundTransparency = 0.15, Visible = false, ZIndex = 9 })
	corner(box, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = PUMP, 2
	stroke.Parent = box
	local head = label(box, { Size = UDim2.new(1, -60, 0, 24), Position = UDim2.fromOffset(12, 6), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PUMP, ZIndex = 10 })
	local body = label(box, { Size = UDim2.new(1, -24, 0, 50), Position = UDim2.fromOffset(12, 30), TextScaled = false, TextSize = 16, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 10 })
	local step, on = 0, false
	local function show(i)
		if not on or i <= step or i > #STEPS then
			return
		end
		step = i
		head.Text = "\u{1F393} Tip " .. i .. " of " .. #STEPS
		body.Text = STEPS[i]
		box.Visible = true
	end
	local nextBtn = button(box, "Next \u{25B6}", { Size = UDim2.fromOffset(110, 28), Position = UDim2.new(1, -122, 1, -34), ZIndex = 10 }, function()
		if step >= #STEPS then
			box.Visible = false
		else
			show(step + 1)
		end
	end)
	button(box, "X", { Font = Enum.Font.GothamBlack, Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, -38, 0, 6), BackgroundColor3 = Color3.fromRGB(150, 60, 70), ZIndex = 10 }, function()
		on = false
		box.Visible = false
	end)
	RunService.Heartbeat:Connect(function()
		nextBtn.Text = step >= #STEPS and "Got it!" or "Next \u{25B6}"
	end)
	remotes.Notify.OnClientEvent:Connect(function(kind)
		if kind == "start" then
			local data = profileData()
			local games = data and data.stats and data.stats.games or 0
			on = games < (Config.COACH_GAMES or 2)
			step = 0
			show(1)
		elseif kind == "pop" then
			show(2)
		elseif kind == "key" or kind == "need" then
			show(3)
		elseif kind == "appear" then
			show(4)
		elseif kind == "caught" then
			show(5)
		end
	end)
	for i = 1, 3 do
		RoundState:GetAttributeChangedSignal("Known" .. i):Connect(function()
			if RoundState:GetAttribute("Known1") and RoundState:GetAttribute("Known2") and RoundState:GetAttribute("Known3") then
				show(6)
			end
		end)
	end
end

-- ---------- the clue log: every clue this game, to read again ----------
do
	local log = {}
	local open = button(acts, "\u{1F4DC} Clues", { LayoutOrder = 9, Visible = false })
	local panel = frame(gui, { Size = UDim2.fromOffset(440, 300), Position = UDim2.new(0.5, -220, 0, 150), Visible = false, ZIndex = 30 })
	corner(panel, 14)
	label(panel, { Size = UDim2.new(1, -60, 0, 30), Position = UDim2.fromOffset(14, 8), Text = "\u{1F4DC} Clues this game", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PUMP, ZIndex = 31 })
	button(panel, "X", { Font = Enum.Font.GothamBlack, Size = UDim2.fromOffset(36, 30), Position = UDim2.new(1, -46, 0, 8), BackgroundColor3 = Color3.fromRGB(150, 60, 70), ZIndex = 31 }, function()
		panel.Visible = false
	end)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -24, 1, -52)
	scroll.Position = UDim2.fromOffset(12, 44)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 8
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.ZIndex = 31
	scroll.Parent = panel
	local body = label(scroll, { Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextScaled = false, TextSize = 17, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 32 })
	local function paint()
		local lines = {}
		for i, t in ipairs(log) do
			-- a Mastermind route: one step a line
			t = string.gsub(t, "  (%d%))", "\n   %1")
			lines[i] = (i == 1 and "\u{27A4} " or "\u{2022} ") .. t
		end
		body.Text = table.concat(lines, "\n\n")
		open.Text = "\u{1F4DC} Clues (" .. #log .. ")"
	end
	open.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
	Gamepad.panel(panel)
	remotes.Notify.OnClientEvent:Connect(function(kind, text)
		if kind == "start" then
			log = {}
			open.Visible, panel.Visible = false, false
		elseif kind == "clue" and typeof(text) == "string" then
			table.insert(log, 1, text)
			open.Visible = true
			paint()
			if string.find(text, "Mastermind route", 1, true) then
				panel.Visible = true -- the whole route: too long to remember from a message
			end
		end
	end)
end

-- ---------- mouse look: lock the mouse to the centre unless a menu is open ----------
end
local locked = false
RunService.RenderStepped:Connect(function()
	local menus = picker.Visible or keypad.Visible or sayPanel.Visible or results.Visible or spec.Visible or aiming
	local want = mouseLook and not menus and not TOUCH
	if want then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		locked = true
	elseif locked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		locked = false
	end
	lookBtn.Text = mouseLook and "\u{1F5B1} Look: on (M)" or "\u{1F5B1} Look (M)"
	lookBtn.BackgroundColor3 = mouseLook and PUMP or Color3.fromRGB(75, 58, 102)
end)

-- ---------- the camera: never inside or behind a wall ----------
-- Invisicam fades furniture between the camera and you (shelves, tables);
-- walls, ceilings and door frames instead stop the camera in front of them,
-- so backing up to a wall never shows the next room or the black outside.
do
	local RS = game:GetService("RunService")
	local STOP = { Wall = true, MirrorWall = true, TunnelGlass = true, Ceiling = true, Lintel = true, TallLintel = true, HostDoor = true }
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	RS:BindToRenderStep("EscapeCrewCameraWalls", Enum.RenderPriority.Camera.Value + 1, function()
		local cam = workspace.CurrentCamera
		local char = player.Character
		local head = char and char:FindFirstChild("Head")
		if not cam or not head or cam.CameraType ~= Enum.CameraType.Custom then
			return
		end
		local from = head.Position
		local to = cam.CFrame.Position
		local dir = to - from
		local dist = dir.Magnitude
		if dist < 1 then
			return
		end
		local unit = dir.Unit
		params.FilterDescendantsInstances = { char }
		local origin = from
		for _ = 1, 8 do
			local hit = workspace:Raycast(origin, to - origin, params)
			if not hit then
				return
			end
			if STOP[hit.Instance.Name] then
				local stopAt = hit.Position - unit * 0.6
				if (stopAt - from).Magnitude < 0.6 then
					stopAt = from - unit * 0.1
				end
				cam.CFrame = CFrame.new(stopAt) * cam.CFrame.Rotation
				return
			end
			origin = hit.Position + unit * 0.05 -- furniture: look past it (Invisicam fades it)
		end
	end)
end
