--[[
	Hud - everything on a player's screen: skill picker, top bar (room,
	footsteps, door code, clue), action buttons (Run, Skill, Say, Come out),
	stamina and energy, messages, the keypad, jumpscares and running.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
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
			local aim = scareFace.head.Position + Vector3.new(0, scareFace.r * 0.3, 0)
			scareCam.CFrame = CFrame.lookAt(aim + scareFace.dir * d + Vector3.new((math.random() - 0.5) * 0.15, scareFace.r * 0.1, 0), aim)
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
		-- aim a little above the middle of the head: the whole face, not the chest
		local front = head.Position + faceDir * dist + Vector3.new(0, r * 0.45, 0)
		local shake = Vector3.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, (math.random() - 0.5) * s)
		cam.CFrame = CFrame.lookAt(front + shake, head.Position + Vector3.new(0, r * 0.3, 0))
	end)
end

-- ---------- top bar ----------
local top = frame(gui, { Size = UDim2.new(0.36, 0, 0, 40), Position = UDim2.new(0.4, 0, 0, 8), BackgroundTransparency = 0.25 })
corner(top, 12)
local roomName -- placed with the bars below
local steps = {}
for i = 1, 5 do
	-- footprints are off: only the host's breathing gives it away
	steps[i] = label(top, { Position = UDim2.new(0.02 + (i - 1) * 0.065, 0, 0.2, 0), Size = UDim2.new(0.065, 0, 0.6, 0), Text = "\u{1F463}", TextTransparency = 0.8, Visible = false })
end
local timerLabel = label(top, { Size = UDim2.new(0.26, 0, 0.7, 0), Position = UDim2.fromScale(0.36, 0.15), Text = "\u{23F1} --:--" })
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
		parts[i] = k and ('<font color="' .. hex(Config.COLOR3[k]) .. '">\u{25CF}</font>') or "?"
	end
	codeLabel.Text = "Code: " .. table.concat(parts, " ")
	if clueBtn then
		local cost = RoundState:GetAttribute("ClueCost") or 10
		if player:GetAttribute("Skill") == "brainy" then
			cost = math.ceil(cost / 2)
		end
		clueBtn.Text = "\u{1F4A1} Clue " .. cost .. "\u{2B50} (" .. tostring(RoundState:GetAttribute("CluesLeft") or 0) .. ")"
	end
end
RoundState.AttributeChanged:Connect(paintCode)
paintCode()

-- ---------- bars ----------
local bars = frame(gui, { Size = UDim2.fromOffset(250, 84), Position = TOUCH and UDim2.fromOffset(10, 60) or UDim2.new(0, 10, 1, -94), BackgroundTransparency = 0.3 })
roomName = label(bars, { Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 58), Text = "The Party House", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PUMP })
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
local sayBtn = button(acts, "\u{1F4AC} Say", { LayoutOrder = 3 })
local outBtn = button(acts, "\u{1F440} Come out", { LayoutOrder = 4, Visible = false }, function()
	remotes.Unhide:FireServer()
end)
local pickBtn = button(acts, "\u{1F504} Change", { LayoutOrder = 5 })
clueBtn = button(acts, "\u{1F4A1} Clue (3)", { LayoutOrder = 6 }, askClue)
local candyBtn = button(acts, "\u{1F36C} Candy", { LayoutOrder = 8, Visible = false }, function()
	remotes.UseCandy:FireServer()
end)
local function paintCandy()
	local n = player:GetAttribute("CandyCharges") or 0
	candyBtn.Visible = n > 0
	candyBtn.Text = "\u{1F36C} Candy (" .. n .. ")"
end
player:GetAttributeChangedSignal("CandyCharges"):Connect(paintCandy)
paintCandy()

-- hold-to-use prompts (pick, shove, read, free...) go faster with ladder upgrades
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptShown:Connect(function(prompt)
	local base = prompt:GetAttribute("BaseHold")
	if base == nil then
		base = prompt.HoldDuration
		prompt:SetAttribute("BaseHold", base)
	end
	prompt.HoldDuration = base * (player:GetAttribute("HoldMult") or 1)
end)
-- mouse look (computers): the camera turns as the mouse moves, no button held
local mouseLook = false
local lookBtn = button(acts, "\u{1F5B1} Look (M)", { LayoutOrder = 7, Visible = not TOUCH }, function()
	mouseLook = not mouseLook
end)

-- ---------- quick-chat phrases ----------
local sayPanel = frame(gui, { Size = UDim2.fromOffset(420, 250), Position = UDim2.new(0.5, -210, 1, -390), Visible = false })
corner(sayPanel, 14)
local sayGrid = Instance.new("UIGridLayout")
sayGrid.CellSize = UDim2.fromOffset(132, 54)
sayGrid.CellPadding = UDim2.fromOffset(6, 6)
sayGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
sayGrid.Parent = sayPanel
for i, p in ipairs(Config.PHRASES) do
	button(sayPanel, p, { BackgroundColor3 = CREAM, TextColor3 = NIGHT }, function()
		remotes.Say:FireServer(i)
		sayPanel.Visible = false
	end)
end
sayBtn.Activated:Connect(function()
	sayPanel.Visible = not sayPanel.Visible
end)
remotes.Bubble.OnClientEvent:Connect(function(who, idx)
	local text = Config.PHRASES[idx]
	if who and who.Character and text then
		pcall(function()
			TextChatService:DisplayBubble(who.Character, text)
		end)
	end
end)

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
local infoName = label(info, { Size = UDim2.fromOffset(270, 40), Position = UDim2.fromOffset(94, 14), Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22 })
local infoSay = label(info, { Size = UDim2.fromOffset(270, 26), Position = UDim2.fromOffset(94, 54), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PUMP, ZIndex = 22 })
local function para(y, h)
	return label(info, { Size = UDim2.new(1, -28, 0, h), Position = UDim2.fromOffset(14, y), TextScaled = false, TextSize = 18, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 22 })
end
local infoAbout = para(96, 78)
local infoHow = para(178, 46)
infoHow.TextColor3 = Color3.fromRGB(123, 227, 107)
local infoLevel = para(220, 48)
-- the boosts you are bringing into this game
local infoBag = para(272, 24)
infoBag.TextColor3 = Color3.fromRGB(255, 210, 63)
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
	infoBag.Text = #bring > 0 and ("\u{1F392} Bringing: " .. table.concat(bring, ", ")) or "\u{1F392} No boosts this game (buy them in the Lobby shop)"

	if shown then
		shown:Destroy()
		shown = nil
	end
	local previews = ReplicatedStorage:FindFirstChild("Previews")
	local src = previews and previews:FindFirstChild(sk.name)
	spin = 0
	if src then
		shown = src:Clone()
		shown.Parent = viewWorld
		noModel.Visible = false
	else
		noModel.Visible = true
		noModel.Text = sk.icon .. "\n3D model coming soon"
	end
	view.BackgroundColor3 = sk.color:Lerp(Color3.fromRGB(26, 16, 38), 0.75)
	local si = Config.SKILL_INFO[sk.id] or {}
	infoIcon.Text = sk.icon
	infoName.Text = sk.name
	infoSay.Text = sk.say
	infoAbout.Text = si.about or ""
	infoHow.Text = si.how and ("\u{1F3AE} " .. si.how) or ""
	local data = profileData()
	local xp = data and data.xp and data.xp[sk.id] or 0
	local level = 1
	for i, need in ipairs({ 0, 100, 250, 450, 700 }) do
		if xp >= need then
			level = i
		end
	end
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
	local cf, size = shown:GetBoundingBox()
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
-- a new game: choose (or keep) your character
RoundState:GetAttributeChangedSignal("Status"):Connect(function()
	if RoundState:GetAttribute("Status") == "playing" and not RoundState:GetAttribute("HostOut") then
		picker.Visible = true
	end
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
	picker.Visible = false
end)
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
local function paintSpook()
	local s = RoundState:GetAttribute("Spook")
	giggly.BackgroundColor3 = s == "giggly" and PUMP or Color3.fromRGB(75, 58, 102)
	spooky.BackgroundColor3 = s == "spooky" and PUMP or Color3.fromRGB(75, 58, 102)
end
RoundState:GetAttributeChangedSignal("Spook"):Connect(paintSpook)
paintSpook()
-- characters are chosen before a game starts: no changing in the middle
local function midGame()
	return RoundState:GetAttribute("Status") == "playing" and RoundState:GetAttribute("HostOut") == true
end
local function paintPick()
	pickBtn.Visible = not midGame()
	if midGame() then
		picker.Visible = false
	end
end
RoundState:GetAttributeChangedSignal("Status"):Connect(paintPick)
RoundState:GetAttributeChangedSignal("HostOut"):Connect(paintPick)
paintPick()
pickBtn.Activated:Connect(function()
	if midGame() then
		return toast("The host is out! You can change character before the next game.", 3)
	end
	picker.Visible = not picker.Visible
end)

-- ---------- keypad ----------
local keypad = frame(gui, { Size = UDim2.fromOffset(250, 300), Position = UDim2.new(1, -270, 0.5, -150), Visible = false, ZIndex = 30 })
corner(keypad, 16)
label(keypad, { Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 8), Text = "Door keypad", ZIndex = 31 })
local entered = label(keypad, { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 44), Text = "_ _ _", RichText = true, ZIndex = 31 })
local pressed = {}
for i, c in ipairs(Config.COLORS) do
	button(keypad, "", {
		Size = UDim2.fromOffset(100, 80),
		Position = UDim2.fromOffset(18 + ((i - 1) % 2) * 112, 84 + math.floor((i - 1) / 2) * 90),
		BackgroundColor3 = Config.COLOR3[c],
		ZIndex = 31,
	}, function()
		table.insert(pressed, c)
		local shown = {}
		for j = 1, 3 do
			shown[j] = pressed[j] and ('<font color="' .. hex(Config.COLOR3[pressed[j]]) .. '">\u{25CF}</font>') or "_"
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

-- ---------- skills that are buttons: Shadow, Patch, Echo ----------
local aiming = false
local SKILL_TEXT = { shadow = "\u{1F319} Sneak", patch = "\u{1F6E1} Shield", echo = "\u{1F3A7} Noise" }
local function paintSkill()
	local s = player:GetAttribute("Skill")
	local icon = "\u{2B50}"
	for _, sk in ipairs(Config.SKILLS) do
		if sk.id == s then
			icon = sk.icon
		end
	end
	skillBtn.Text = SKILL_TEXT[s] or (icon .. " Skill")
end
player:GetAttributeChangedSignal("Skill"):Connect(paintSkill)
paintSkill()
skillBtn.Activated:Connect(function()
	local s = player:GetAttribute("Skill")
	if s == "echo" then
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
		local tips = { tinker = "Walk up to a locked door and hold F to pick it - no key needed.", brainy = "Find the twisty invitation in the " .. roomOfObj("invite") .. " and press E to read it.",
			muscle = "Find the heavy cabinet in the " .. roomOfObj("cab") .. " and hold E to shove it.", glow = "Find the painted wall in the " .. roomOfObj("uv") .. " and press E to light it up.",
			bramble = "Find the big plant in the " .. roomOfObj("plant") .. " and press E to ask it." }
		toast(tips[s] or "Walk up to things and press E.", 4)
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
		boostSlot(id, i, i <= 2 and not TOUCH and ("Tap \u{00B7} " .. i) or "Tap", function()
			remotes.UseBoost:FireServer(id)
		end)
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

-- ---------- map of the rooms you have found ----------
-- A small map in the corner, north up, the exit door at the top. Rooms appear
-- as you walk into them; you are the arrow, teammates are dots (red = caged).
-- N or the Map button opens and closes it.
local MAP_W = 196
local PX = MAP_W / HouseMap.w
local MAP_H = math.floor(PX * HouseMap.h + 0.5)
local mapAt = TOUCH and UDim2.fromOffset(10, 152) or UDim2.new(0, 10, 1, -94 - MAP_H - 40)
local mapBox = frame(gui, { Size = UDim2.fromOffset(MAP_W + 8, MAP_H + 32), Position = mapAt, BackgroundTransparency = 0.25 })
corner(mapBox, 10)
local mapArea = frame(mapBox, { Size = UDim2.fromOffset(MAP_W, MAP_H), Position = UDim2.fromOffset(4, 28), BackgroundColor3 = Color3.fromRGB(10, 6, 16), BackgroundTransparency = 0, ClipsDescendants = true })
local mapTitle = label(mapBox, { Size = UDim2.new(1, -44, 0, 20), Position = UDim2.fromOffset(8, 4), Text = "\u{1F5FA} Map" .. (TOUCH and "" or " (N)"), TextXAlignment = Enum.TextXAlignment.Left })
local mapOpenBtn = button(gui, "\u{1F5FA} Map" .. (TOUCH and "" or " (N)"), { Size = UDim2.fromOffset(110, 36), Position = mapAt, Visible = false })
local function showMap(open)
	mapBox.Visible = open
	mapOpenBtn.Visible = not open
end
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
		label(r, { Size = UDim2.new(1, -4, 0, 12), Position = UDim2.fromOffset(2, 2), Text = f.name, TextColor3 = Color3.fromRGB(230, 215, 245), ZIndex = 3 })
		roomTiles[f.name] = { r }
	end
	-- doorways: walkable tiles between rooms, shown once a room beside them is found
	for y, row in ipairs(HouseMap.map) do
		for x = 1, #row do
			local tx, ty = x - 1, y - 1
			local ch = string.sub(row, x, x)
			if (ch == "." or ch == "L") and not floorOf(tx, ty) then
				local d = mapRect(tx, ty, tx, ty, ROOM_COLOR)
				-- locked doors show gold until they open
				for _, o in ipairs(HouseMap.objects) do
					if o.kind == "lock" and o.x == tx and o.y == ty then
						local function paint()
							d.BackgroundColor3 = RoundState:GetAttribute("Lock_" .. o.id) and ROOM_COLOR or Color3.fromRGB(255, 210, 63)
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
		label(loftView, { Size = UDim2.new(1, -4, 1, 0), Position = UDim2.fromOffset(2, 0), Text = "Loft", TextColor3 = Color3.fromRGB(255, 240, 200), ZIndex = 4 })
		local name = floorOf(L.x0, L.y0)
		if name then
			table.insert(roomTiles[name], loftView)
		end
	end
	-- the way out, once you have seen the room it is in
	for _, o in ipairs(HouseMap.objects) do
		if o.kind == "door" then
			local name = floorOf(o.x, o.y + 1)
			local door = mapRect(o.x - 0.5, o.y, o.x + 0.5, o.y, PUMP, 4)
			if name then
				table.insert(roomTiles[name], door)
			end
		end
	end
end
buildView()
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
require(ReplicatedStorage.Shared.MusicPlayer).start("game", gui, UDim2.new(0.77, 0, 0, 10), remotes:WaitForChild("SetMusic"))

-- ---------- who is playing, and their points this game ----------
local SKILL_ICON = {}
for _, sk in ipairs(Config.SKILLS) do
	SKILL_ICON[sk.id] = sk.icon
end
local playersBtn = button(gui, "\u{1F465} Players", { Size = UDim2.fromOffset(96, 36), Position = UDim2.new(0.77, 0, 0, 52), ZIndex = 5 })
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
playersBtn.Activated:Connect(function()
	playersBox.Visible = not playersBox.Visible
	if playersBox.Visible then
		paintPlayers()
	end
end)
task.spawn(function()
	while true do
		task.wait(0.5)
		if playersBox.Visible then
			paintPlayers()
		end
	end
end)

-- ---------- leave for the Lobby (asks first) ----------
local leaveBtn = button(gui, "\u{1F6AA} Lobby", { Size = UDim2.fromOffset(96, 36), Position = UDim2.new(0.77, 0, 0, 94), ZIndex = 5 })
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

-- ---------- waiting for everyone to choose a character ----------
local pickBanner = label(gui, { Size = UDim2.fromOffset(560, 40), Position = UDim2.new(0.5, -280, 0, 56), BackgroundTransparency = 0.2, BackgroundColor3 = NIGHT, TextColor3 = PUMP, Visible = false, ZIndex = 8 })
corner(pickBanner, 10)
task.spawn(function()
	while true do
		task.wait(0.5)
		local waiting = RoundState:GetAttribute("WaitingToPick") or 0
		local deadline = RoundState:GetAttribute("PickDeadline")
		local show = RoundState:GetAttribute("Status") == "playing" and not RoundState:GetAttribute("HostOut") and deadline ~= nil and waiting > 0
		pickBanner.Visible = show
		if show then
			local left = math.max(0, math.floor(deadline - workspace:GetServerTimeNow()))
			local mine = player:GetAttribute("Skill") == nil
			pickBanner.Text = (mine and "Choose your character! " or "Waiting for friends to choose... ")
				.. waiting .. " still choosing \u{00B7} starts anyway in " .. string.format("%d:%02d", math.floor(left / 60), left % 60)
		end
	end
end)

-- ---------- running and stamina ----------
local stamina, tired, candyUntil = 100, false, 0
remotes.Boost.OnClientEvent:Connect(function(kind)
	if kind == "candy" then
		candyUntil = os.clock() + 20
	elseif kind == "stamina" then
		stamina, tired = 100, false
	end
end)

-- the heartbeat speeds up and gets louder as the host comes closer
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
		if wantRun and moving and not tired then
			hum.WalkSpeed = Config.RUN * (player:GetAttribute("RunMult") or 1)
			if not candy then
				stamina = math.max(0, stamina - Config.STAMINA_DRAIN * dt / (player:GetAttribute("StaminaMult") or 1))
				if stamina <= 0 then
					tired = true
					toast("Puffed out! Walk for a bit.", 2)
				end
			end
		else
			hum.WalkSpeed = Config.WALK
			stamina = math.min(100, stamina + Config.STAMINA_REGEN * dt)
			if tired and stamina >= 25 then
				tired = false
			end
		end
	end
	runBtn.BackgroundColor3 = (runToggle or shiftHeld) and PUMP or Color3.fromRGB(75, 58, 102)
	staminaBar.Size = UDim2.fromScale(stamina / 100, 1)
	staminaBar.BackgroundColor3 = tired and Color3.fromRGB(255, 77, 94) or Color3.fromRGB(123, 227, 107)
	gameEarned.Text = "\u{2B50} " .. tostring(player:GetAttribute("GameEarned") or 0) .. " points this game"

	-- skill countdown: active time, then recharge time
	local serverNow = workspace:GetServerTimeNow()
	local skill = player:GetAttribute("Skill")
	if SKILL_TEXT[skill] then
		local active = (player:GetAttribute("SneakUntil") or 0) - serverNow
		local cool = (player:GetAttribute("CoolUntil") or 0) - serverNow
		if skill == "shadow" and active > 0 then
			skillBtn.Text = "\u{1F319} Sneaking " .. math.ceil(active) .. "s"
			skillBtn.BackgroundColor3 = PUMP
		elseif cool > 0 then
			skillBtn.Text = SKILL_TEXT[skill] .. " " .. math.ceil(cool) .. "s"
			skillBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		else
			skillBtn.Text = SKILL_TEXT[skill]
			skillBtn.BackgroundColor3 = Color3.fromRGB(47, 107, 58)
		end
	end

	-- escape timer
	local ends = RoundState:GetAttribute("EndsAt")
	if RoundState:GetAttribute("Frenzy") then
		timerLabel.Text = "\u{1F525} FRENZY"
		timerLabel.TextColor3 = Color3.fromRGB(255, 77, 94)
	elseif ends and RoundState:GetAttribute("Status") == "playing" then
		local left = math.max(0, math.floor(ends - serverNow))
		timerLabel.Text = string.format("\u{23F1} %d:%02d", math.floor(left / 60), left % 60)
		timerLabel.TextColor3 = left < 60 and Color3.fromRGB(255, 77, 94) or CREAM
	end

	-- where am I, and how close is the host?
	local r = roomAt(hrp.Position)
	local dark = RoundState:GetAttribute("Blackout")
	local nowDark = dark ~= nil and dark ~= "" and r == dark
	if nowDark ~= inBlackout then
		inBlackout = nowDark
		TweenService:Create(LightingService, TweenInfo.new(0.4), nowDark and darkLight or normalLight):Play()
	end
	local where = HouseMap.name or "The Party House"
	roomName.Text = r and (where .. " \u{00B7} " .. r) or where
	local host = workspace:FindFirstChild("PartyHost")
	if host ~= breathFor then
		breathFor = host
		local head = host and (host:FindFirstChild("Head") or host.PrimaryPart)
		if head and Config.SOUNDS.breath then
			local s = Instance.new("Sound")
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
local popFrame = frame(gui, { Size = UDim2.fromOffset(170, 170), Position = UDim2.new(0.5, -85, 0.55, -85), BackgroundTransparency = 1, Visible = false, ZIndex = 35 })
local popIcon = label(popFrame, { Size = UDim2.fromScale(1, 0.75), Text = "", ZIndex = 36 })
local popText = label(popFrame, { Size = UDim2.new(1.6, 0, 0.25, 0), Position = UDim2.fromScale(-0.3, 0.75), Text = "", ZIndex = 36 })
local popToken = 0
local function popUp(icon, text)
	popToken += 1
	local my = popToken
	popIcon.Text, popText.Text = icon, text or ""
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

-- ---------- end of round: results ----------
local results = frame(gui, { Size = UDim2.fromOffset(460, 360), Position = UDim2.new(0.5, -230, 0.5, -180), Visible = false, ZIndex = 40 })
corner(results, 18)
local resTitle = label(results, { Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 12), TextColor3 = PUMP, ZIndex = 41 })
local resInfo = label(results, { Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 60), ZIndex = 41 })
local resList = label(results, { Size = UDim2.new(1, -40, 0, 190), Position = UDim2.fromOffset(20, 96), TextScaled = false, TextSize = 22, TextYAlignment = Enum.TextYAlignment.Top, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41 })
local resNext = label(results, { Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 1, -96), TextColor3 = Color3.fromRGB(185, 168, 207), ZIndex = 41 })
local againBtn, lobbyBtn
local function chose(choice)
	remotes.Vote:FireServer(choice)
	againBtn.Visible, lobbyBtn.Visible = false, false
	resNext.Text = choice == "again" and "Waiting for the others..." or "Going back to the lobby..."
end
againBtn = button(results, "\u{1F501} Play again", { Size = UDim2.fromOffset(200, 50), Position = UDim2.new(0.5, -210, 1, -64), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 41 }, function()
	chose("again")
end)
lobbyBtn = button(results, "\u{1F3E0} Back to lobby", { Size = UDim2.fromOffset(200, 50), Position = UDim2.new(0.5, 10, 1, -64), ZIndex = 41 }, function()
	chose("lobby")
end)
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
	resTitle.Text = r.won and "\u{1F389} You escaped the Party House!" or "\u{1F512} Everyone was caught..."
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
		table.insert(lines, (row.escaped and "\u{2705} " or "\u{1F512} ") .. row.name .. "  +" .. row.points .. " points" .. extra)
	end
	resList.Text = table.concat(lines, "\n")
	results.Visible = true
	againBtn.Visible, lobbyBtn.Visible = r.vote == true, r.vote == true
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
	elseif (kind == "boost" or kind == "pop") and data and data.userId == player.UserId then
		popUp(data.icon or "\u{2B50}", data.item or "")
	elseif (kind == "sneak" or kind == "heal" or kind == "lure") and data and data.userId == player.UserId then
		popUp(skillIcon(player:GetAttribute("Skill")), kind == "sneak" and "Sneaking!" or kind == "heal" and "Shields up!" or "Noise!")
	elseif kind == "start" then
		keypad.Visible = false
		stamina, tired = 100, false
	end
	toast(text, (kind == "clue" or kind == "reveal") and 6 or 3.5)
end)

-- ---------- mouse look: lock the mouse to the centre unless a menu is open ----------
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
