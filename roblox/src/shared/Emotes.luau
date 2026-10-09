--[[
	Emotes (client) - the emote wheel: wave, point, cheer, laugh and three
	dances, using Roblox's own free R15 emote animations (ids checked on
	Roblox's API, 9 Oct). Played on your own character, so everyone sees
	them. Walking or jumping stops a dance.

	Emotes.mount(gui, button, panelPosition) builds the panel, opens it
	from `button`, G on a keyboard and the right stick click on a controller.
	Emotes.play(id) plays one (the escape photo uses it).
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Gamepad = require(script.Parent.Gamepad)

local Emotes = {}

Emotes.LIST = {
	{ id = "wave", icon = "\u{1F44B}", name = "Wave", anim = 507770239 },
	{ id = "point", icon = "\u{1F449}", name = "Point", anim = 507770453 },
	{ id = "cheer", icon = "\u{1F389}", name = "Cheer", anim = 507770677 },
	{ id = "laugh", icon = "\u{1F602}", name = "Laugh", anim = 507770818 },
	{ id = "dance1", icon = "\u{1F57A}", name = "Dance 1", anim = 507771019, loop = true },
	{ id = "dance2", icon = "\u{1F483}", name = "Dance 2", anim = 507776043, loop = true },
	{ id = "dance3", icon = "\u{1F3B6}", name = "Dance 3", anim = 507777268, loop = true },
}

local player = Players.LocalPlayer
local current -- the track playing now
local tracks = {} -- [character] = { [id] = track }

function Emotes.stop()
	if current then
		current:Stop(0.2)
		current = nil
	end
end

function Emotes.play(id)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	local def
	for _, e in ipairs(Emotes.LIST) do
		if e.id == id then
			def = e
		end
	end
	if not def then
		return
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	tracks[char] = tracks[char] or {}
	local t = tracks[char][id]
	if not t then
		local a = Instance.new("Animation")
		a.AnimationId = "rbxassetid://" .. def.anim
		local ok, loaded = pcall(function()
			return animator:LoadAnimation(a)
		end)
		if not ok then
			return
		end
		t = loaded
		t.Priority = Enum.AnimationPriority.Action
		t.Looped = def.loop == true
		tracks[char][id] = t
	end
	Emotes.stop()
	current = t
	t:Play(0.2)
	-- walking or jumping stops it
	local started = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if current ~= t or not t.IsPlaying then
			conn:Disconnect()
			return
		end
		if os.clock() - started > 0.3 and (hum.MoveDirection.Magnitude > 0.1 or hum.Jump) then
			Emotes.stop()
			conn:Disconnect()
		end
	end)
end

-- the panel of emote buttons, opened by `button` (and G / the right stick)
function Emotes.mount(gui, button, position)
	local panel = Instance.new("Frame")
	panel.Name = "Emotes"
	panel.Size = UDim2.fromOffset(4 * 100 + 5 * 6, 2 * 70 + 3 * 6)
	panel.Position = position
	panel.BackgroundColor3 = Color3.fromRGB(22, 13, 34)
	panel.BackgroundTransparency = 0.08
	panel.Visible = false
	panel.ZIndex = 30
	panel.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 18)
	c.Parent = panel
	local edge = Instance.new("UIStroke")
	edge.Color, edge.Thickness, edge.ApplyStrokeMode = Color3.fromRGB(255, 244, 224), 3, Enum.ApplyStrokeMode.Border
	edge.Parent = panel
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(100, 70)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = panel
	-- a tile per emote: its picture (Config.UI_ICONS "emote-<id>", or the
	-- emoji until uploaded) and one word, plum with a cream edge
	local okC, Config = pcall(require, script.Parent.Config)
	local icons = okC and Config.UI_ICONS or {}
	local font = Enum.Font.GothamBold
	pcall(function()
		font = Enum.Font.BuilderSansBold
	end)
	local function choice(i, key, emoji, word, onClick)
		local b = Instance.new("TextButton")
		b.LayoutOrder = i
		b.Text = ""
		b.BackgroundColor3 = Color3.fromRGB(75, 58, 102)
		b.ZIndex = 31
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 12)
		bc.Parent = b
		local be = Instance.new("UIStroke")
		be.Color, be.Thickness, be.ApplyStrokeMode, be.Transparency = Color3.fromRGB(255, 244, 224), 2, Enum.ApplyStrokeMode.Border, 0.35
		be.Parent = b
		local id = icons[key] or 0
		if id > 0 then
			local pic = Instance.new("ImageLabel")
			pic.BackgroundTransparency = 1
			pic.Image = "rbxassetid://" .. id
			pic.ScaleType = Enum.ScaleType.Fit
			pic.Size, pic.Position = UDim2.fromScale(0.6, 0.6), UDim2.fromScale(0.2, 0.04)
			pic.ZIndex = 32
			pic.Parent = b
		else
			local em = Instance.new("TextLabel")
			em.BackgroundTransparency, em.TextScaled, em.Text, em.ZIndex = 1, true, emoji, 32
			em.Size, em.Position = UDim2.fromScale(0.6, 0.56), UDim2.fromScale(0.2, 0.06)
			em.Parent = b
		end
		local w = Instance.new("TextLabel")
		w.BackgroundTransparency, w.TextScaled, w.Text, w.Font, w.ZIndex = 1, true, word, font, 32
		w.TextColor3 = Color3.fromRGB(255, 244, 224)
		w.Size, w.Position = UDim2.fromScale(0.9, 0.26), UDim2.fromScale(0.05, 0.68)
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = 18
		cap.Parent = w
		w.Parent = b
		b.Parent = panel
		b.Activated:Connect(onClick)
		return b
	end
	for i, e in ipairs(Emotes.LIST) do
		choice(i, "emote-" .. e.id, e.icon, e.name, function()
			Emotes.play(e.id)
			panel.Visible = false
		end)
	end
	choice(#Emotes.LIST + 1, "emote-stop", "\u{270B}", "Stop", function()
		Emotes.stop()
		panel.Visible = false
	end)
	local function toggle()
		panel.Visible = not panel.Visible
	end
	if button then
		button.Activated:Connect(toggle)
		Gamepad.hint(button, "R3")
	end
	UserInputService.InputBegan:Connect(function(input, used)
		if not used and input.KeyCode == Enum.KeyCode.G then
			toggle()
		end
	end)
	Gamepad.bind(Enum.KeyCode.ButtonR3, toggle)
	Gamepad.panel(panel)
	return panel
end

return Emotes
