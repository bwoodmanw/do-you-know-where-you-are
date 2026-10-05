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
local HouseMap = require(ReplicatedStorage.Shared.HouseMap)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundState = ReplicatedStorage:WaitForChild("RoundState")
local player = Players.LocalPlayer
local T = Config.TILE

local NIGHT = Color3.fromRGB(26, 16, 38)
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
local toastFrame = frame(gui, { Size = UDim2.new(0.6, 0, 0, 56), Position = UDim2.new(0.2, 0, 0, 64), Visible = false })
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
local function jumpscare()
	scare.Visible = true
	local cam = workspace.CurrentCamera
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local f = os.clock() - t0
		if scareImg then
			scareImg.Size = UDim2.fromScale(1 + f * 0.4, 1 + f * 0.4)
			scareImg.Position = UDim2.fromScale(-f * 0.2, -f * 0.2)
		end
		cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, (math.random() - 0.5) * 0.05)
		if f > 0.7 then
			conn:Disconnect()
			scare.Visible = false
		end
	end)
end

-- ---------- top bar ----------
local top = frame(gui, { Size = UDim2.new(1, -20, 0, 48), Position = UDim2.fromOffset(10, 8), BackgroundTransparency = 0.25 })
corner(top, 12)
local roomName = label(top, { Size = UDim2.new(0.3, 0, 0.7, 0), Position = UDim2.fromScale(0.02, 0.15), Text = "The Party House", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = PUMP })
local steps = {}
for i = 1, 5 do
	steps[i] = label(top, { Size = UDim2.new(0.04, 0, 0.8, 0), Position = UDim2.new(0.33 + i * 0.04, 0, 0.1, 0), Text = "\u{1F463}", TextTransparency = 0.8 })
end
local codeLabel = label(top, { Size = UDim2.new(0.2, 0, 0.7, 0), Position = UDim2.fromScale(0.6, 0.15), RichText = true, Text = "Code: ? ? ?" })
local clueBtn = button(top, "\u{1F4A1} Clue (3)", { Size = UDim2.new(0.16, 0, 0.8, 0), Position = UDim2.fromScale(0.82, 0.1) }, function()
	remotes.AskClue:FireServer()
end)

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
	clueBtn.Text = "\u{1F4A1} Clue (" .. tostring(RoundState:GetAttribute("CluesLeft") or 0) .. ")"
end
RoundState.AttributeChanged:Connect(paintCode)
paintCode()

-- ---------- bars ----------
local bars = frame(gui, { Size = UDim2.fromOffset(220, 46), Position = UDim2.new(0, 10, 1, -56), BackgroundTransparency = 0.3 })
corner(bars, 10)
local function bar(y, color)
	local back = frame(bars, { Size = UDim2.new(1, -16, 0, 12), Position = UDim2.fromOffset(8, y), BackgroundColor3 = Color3.fromRGB(18, 10, 27), BackgroundTransparency = 0 })
	corner(back, 6)
	local fill = frame(back, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BackgroundTransparency = 0 })
	corner(fill, 6)
	return fill
end
local staminaBar = bar(8, Color3.fromRGB(123, 227, 107))
local energyBar = bar(26, Color3.fromRGB(255, 210, 63))

-- ---------- action buttons ----------
local acts = frame(gui, { Size = UDim2.fromOffset(330, 120), Position = UDim2.new(1, -340, 1, -130), BackgroundTransparency = 1 })
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(104, 54)
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
local pickBtn = button(acts, "\u{1F504} Skill", { LayoutOrder = 5 })

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

-- ---------- skill picker ----------
local picker = frame(gui, { Size = UDim2.fromOffset(620, 380), Position = UDim2.new(0.5, -310, 0.5, -190), ZIndex = 20 })
corner(picker, 16)
label(picker, { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 8), Text = "Pick your skill", TextColor3 = PUMP, ZIndex = 21 })
local cardBox = frame(picker, { Size = UDim2.new(1, -20, 0, 240), Position = UDim2.fromOffset(10, 54), BackgroundTransparency = 1, ZIndex = 21 })
local cardGrid = Instance.new("UIGridLayout")
cardGrid.CellSize = UDim2.fromOffset(142, 112)
cardGrid.CellPadding = UDim2.fromOffset(8, 8)
cardGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
cardGrid.Parent = cardBox
local cards = {}
for _, s in ipairs(Config.SKILLS) do
	local b = button(cardBox, s.name .. "\n" .. s.say, { BackgroundColor3 = s.color, TextColor3 = NIGHT, ZIndex = 22 }, function()
		remotes.PickSkill:FireServer(s.id)
	end)
	cards[s.id] = b
end
local function paintCards()
	local mine = player:GetAttribute("Skill")
	for id, b in pairs(cards) do
		b.BorderSizePixel = 0
		local stroke = b:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", b)
		stroke.Thickness = id == mine and 4 or 0
		stroke.Color = Color3.new(1, 1, 1)
	end
end
player:GetAttributeChangedSignal("Skill"):Connect(paintCards)
paintCards()
local giggly = button(picker, "\u{1F604} Giggly", { Size = UDim2.fromOffset(140, 44), Position = UDim2.new(0.5, -290, 1, -56), ZIndex = 22 }, function()
	remotes.SetSpook:FireServer("giggly")
end)
local spooky = button(picker, "\u{1F47B} Spooky", { Size = UDim2.fromOffset(140, 44), Position = UDim2.new(0.5, -142, 1, -56), ZIndex = 22 }, function()
	remotes.SetSpook:FireServer("spooky")
end)
button(picker, "\u{25B6} Play", { Size = UDim2.fromOffset(150, 44), Position = UDim2.new(0.5, 140, 1, -56), BackgroundColor3 = PUMP, TextColor3 = NIGHT, ZIndex = 22 }, function()
	picker.Visible = false
end)
local function paintSpook()
	local s = RoundState:GetAttribute("Spook")
	giggly.BackgroundColor3 = s == "giggly" and PUMP or Color3.fromRGB(75, 58, 102)
	spooky.BackgroundColor3 = s == "spooky" and PUMP or Color3.fromRGB(75, 58, 102)
end
RoundState:GetAttributeChangedSignal("Spook"):Connect(paintSpook)
paintSpook()
pickBtn.Activated:Connect(function()
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
local SKILL_TEXT = { shadow = "\u{1F319} Sneak", patch = "\u{1F497} Heal", echo = "\u{1F3A7} Throw noise" }
local function paintSkill()
	local s = player:GetAttribute("Skill")
	skillBtn.Text = SKILL_TEXT[s] or "\u{2B50} Skill: walk up + E"
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
		local tips = { tinker = "Walk up to the big door's keypad and hold F to pick the lock.", brainy = "Find the twisty invitation in the Parlour and press E to read it.",
			muscle = "Find the heavy cabinet in the Game Room and hold E to shove it.", glow = "Find the painted wall in the Library and press E to light it up.",
			bramble = "Find the big plant in the Library and press E to ask it." }
		toast(tips[s] or "Walk up to things and press E.", 4)
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		shiftHeld = true
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

-- ---------- running and stamina ----------
local stamina, tired, candyUntil = 100, false, 0
remotes.Boost.OnClientEvent:Connect(function(kind)
	if kind == "candy" then
		candyUntil = os.clock() + 20
	elseif kind == "stamina" then
		stamina, tired = 100, false
	end
end)

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
			hum.WalkSpeed = Config.RUN
			if not candy then
				stamina = math.max(0, stamina - Config.STAMINA_DRAIN * dt)
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
	energyBar.Size = UDim2.fromScale((player:GetAttribute("Energy") or 0) / 100, 1)

	-- where am I, and how close is the host?
	local r = roomAt(hrp.Position)
	roomName.Text = r and ("The Party House \u{00B7} " .. r) or "The Party House"
	local host = workspace:FindFirstChild("PartyHost")
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
end)

-- ---------- messages from the server ----------
remotes.Notify.OnClientEvent:Connect(function(kind, text, data)
	local spooky = RoundState:GetAttribute("Spook") == "spooky"
	if kind == "appear" and spooky then
		jumpscare()
	elseif kind == "caught" and spooky and data and data.userId == player.UserId then
		jumpscare()
	elseif kind == "spotted" and data and data.userId == player.UserId then
		local cam = workspace.CurrentCamera
		for i = 1, 6 do
			task.delay(i * 0.04, function()
				cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, (math.random() - 0.5) * 0.06)
			end)
		end
	elseif kind == "start" then
		picker.Visible = true
		keypad.Visible = false
		stamina, tired = 100, false
	end
	toast(text, (kind == "clue" or kind == "reveal") and 6 or 3.5)
end)
