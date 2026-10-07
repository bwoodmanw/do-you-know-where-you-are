--[[
	Rooms - makes every room look like what it is called, in every building.
	Each room is matched by words in its name (boiler, conveyor, ward, vault,
	bathroom...) to a look:
	  * a wall lining: its own walls (brick, steel, tiles, wallpaper, wood)
	  * set pieces: big recognisable things (a boiler with pipes, conveyor
	    belts that move, a vault door, an ambulance, a fireplace...)
	Everything here is decoration: never solid, never in a doorway, never on
	a hiding place, puzzle or start tile.

	Imported models: if ServerStorage -> Props has a model with a set piece's
	name (e.g. "Boiler"), that model is used instead of the built one, sized
	to fit. So a set piece can be upgraded later with no code change.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)

local T = Config.TILE
local H = Config.WALL_H
local HT = 24 -- tall rooms (as in House)

local Rooms = {}

local function cell(map, x, y)
	if y < 0 or y >= map.h or x < 0 or x >= map.w then
		return "#"
	end
	return string.sub(map.map[y + 1], x + 1, x + 1)
end

local function at(x, y)
	return Vector3.new(x * T + T / 2, 0, y * T + T / 2)
end

local function C(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- one decoration part: o.at is the offset from the piece's base (+Z towards
-- the wall behind it, +Y up), o.rot an extra turn
local function add(folder, base, o)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Name = o.name or "Deco"
	p.Size = o.size
	p.Color = o.color or C(200, 200, 200)
	p.Material = o.mat or Enum.Material.SmoothPlastic
	if o.shape then
		p.Shape = o.shape
	end
	p.Transparency = o.alpha or 0
	p.Reflectance = o.shine or 0
	p.CFrame = base * CFrame.new(o.at or Vector3.zero) * (o.rot or CFrame.new())
	p.Parent = folder
	return p
end

local function label(p, face, text, color)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.CanvasSize = Vector2.new(200, 120)
	sg.LightInfluence = 0.3
	sg.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color or C(30, 30, 30)
	t.Text = text
	t.Parent = sg
end

local function glow(p, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = color, range or 8, brightness or 0.8
	l.Parent = p
	return l
end

local UP = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder standing up
local METAL, NEON, GLASS, WOOD = Enum.Material.Metal, Enum.Material.Neon, Enum.Material.Glass, Enum.Material.Wood
local CANDY = { C(255, 77, 94), C(61, 139, 255), C(255, 210, 63), C(70, 209, 96), C(190, 110, 230), C(255, 150, 200) }

-- ---------------------------------------------------------------- set pieces
-- Each builds at base (a tile's floor centre, facing into the room).
-- size: what an imported model of that name is fitted into.
local PIECES = {}

PIECES.Boiler = { size = Vector3.new(6, 9, 6), build = function(f, b)
	add(f, b, { size = Vector3.new(7, 4.6, 4.6), at = Vector3.new(0, 3.5, 1), rot = UP, shape = Enum.PartType.Cylinder, color = C(120, 70, 50), mat = METAL })
	add(f, b, { size = Vector3.new(4.6, 4.6, 4.6), at = Vector3.new(0, 7, 1), shape = Enum.PartType.Ball, color = C(120, 70, 50), mat = METAL })
	add(f, b, { size = Vector3.new(1.8, 1.4, 0.2), at = Vector3.new(0, 1.6, -1.35), color = C(30, 20, 15) })
	glow(add(f, b, { size = Vector3.new(1.4, 1, 0.1), at = Vector3.new(0, 1.6, -1.45), color = C(255, 120, 30), mat = NEON }), C(255, 130, 40), 10, 1.2)
	add(f, b, { size = Vector3.new(0.7, H - 8, 0.7), at = Vector3.new(0, 8 + (H - 8) / 2, 1), color = C(140, 110, 80), mat = METAL })
	add(f, b, { size = Vector3.new(T, 0.6, 0.6), at = Vector3.new(0, H - 2, T / 2 - 0.6), color = C(140, 110, 80), mat = METAL })
	add(f, b, { size = Vector3.new(0.9, 0.9, 0.9), at = Vector3.new(1.6, 4.5, -0.9), shape = Enum.PartType.Ball, color = C(245, 245, 240) })
	add(f, b, { size = Vector3.new(0.2, 0.5, 0.05), at = Vector3.new(1.6, 4.6, -1.36), color = C(220, 40, 40) })
end }

PIECES.Generator = { size = Vector3.new(6, 5, 4), build = function(f, b)
	add(f, b, { size = Vector3.new(5.5, 3.6, 3.2), at = Vector3.new(0, 1.8, 1), color = C(200, 175, 60), mat = METAL })
	for i = -2, 2 do
		add(f, b, { size = Vector3.new(0.5, 0.3, 0.05), at = Vector3.new(i * 1.1, 0.5, -0.62), color = i % 2 == 0 and C(20, 20, 20) or C(250, 210, 40) })
	end
	add(f, b, { size = Vector3.new(0.6, 3, 0.6), at = Vector3.new(2, 5, 1.6), color = C(90, 90, 95), mat = METAL })
	glow(add(f, b, { size = Vector3.new(0.4, 0.4, 0.4), at = Vector3.new(-2, 3, -0.65), shape = Enum.PartType.Ball, color = C(80, 255, 120), mat = NEON }), C(80, 255, 120), 6, 1)
	label(add(f, b, { size = Vector3.new(2, 1, 0.05), at = Vector3.new(0, 2.6, -0.62), color = C(40, 40, 40) }), Enum.NormalId.Front, "\u{26A1} DANGER", C(250, 210, 40))
end }

PIECES.WaterTank = { size = Vector3.new(6, 9, 6), build = function(f, b)
	add(f, b, { size = Vector3.new(8, 5.5, 5.5), at = Vector3.new(0, 4, 0.8), rot = UP, shape = Enum.PartType.Cylinder, color = C(150, 160, 170), mat = METAL })
	add(f, b, { size = Vector3.new(0.6, 0.6, T), at = Vector3.new(2.4, 7, 0), color = C(110, 120, 130), mat = METAL })
end }

PIECES.Pipes = { size = Vector3.new(8, 3, 1), build = function(f, b)
	for i, y in ipairs({ H - 1.5, H - 2.6 }) do
		add(f, b, { size = Vector3.new(T, 0.55, 0.55), at = Vector3.new(0, y, T / 2 - 0.5 - i * 0.2), color = i == 1 and C(150, 110, 70) or C(120, 125, 130), mat = METAL })
	end
	add(f, b, { size = Vector3.new(0.55, H - 3, 0.55), at = Vector3.new(-2, (H - 3) / 2, T / 2 - 0.7), color = C(150, 110, 70), mat = METAL })
	add(f, b, { size = Vector3.new(1, 1, 0.3), at = Vector3.new(-2, 4, T / 2 - 1), color = C(200, 40, 40), shape = Enum.PartType.Cylinder, rot = CFrame.Angles(0, math.rad(90), 0) })
end }

-- a conveyor belt with sweets riding along it, and a candy machine at its end
PIECES.Conveyor = { size = Vector3.new(8, 4, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(T, 2.4, 2.8), at = Vector3.new(0, 1.2, 1.6), color = C(170, 175, 185), mat = METAL })
	add(f, b, { size = Vector3.new(T, 0.25, 2.4), at = Vector3.new(0, 2.5, 1.6), color = C(35, 35, 40), mat = Enum.Material.Rubber })
	for _, z in ipairs({ 0.25, 2.95 }) do
		for i = 0, 7 do
			add(f, b, { size = Vector3.new(1, 0.3, 0.12), at = Vector3.new(-3.5 + i, 2.5, z), color = i % 2 == 0 and C(250, 210, 40) or C(25, 25, 25) })
		end
	end
	local sweets = {}
	for i = 1, 4 do
		table.insert(sweets, add(f, b, { size = Vector3.new(0.9, 0.9, 0.9), at = Vector3.new(-3 + i * 1.8, 3.1, 1.6), shape = Enum.PartType.Ball, color = CANDY[i % #CANDY + 1] }))
	end
	local machine = add(f, b, { size = Vector3.new(2.4, 4.6, 3.2), at = Vector3.new(T / 2 - 1.2, 2.3, 1.6), color = C(255, 120, 170) })
	add(f, b, { size = Vector3.new(1.6, 2, 1.6), at = Vector3.new(T / 2 - 1.2, 5.4, 1.6), rot = UP, shape = Enum.PartType.Cylinder, color = C(250, 250, 250), mat = GLASS, alpha = 0.3 })
	glow(add(f, b, { size = Vector3.new(0.5, 0.5, 0.5), at = Vector3.new(T / 2 - 1.2, 4, 0), shape = Enum.PartType.Ball, color = C(80, 255, 120), mat = NEON }), C(80, 255, 120), 6, 0.8)
	local _ = machine
	task.spawn(function()
		local t = 0
		while f.Parent do
			t += 0.05
			for i, s in ipairs(sweets) do
				local x = ((i * 1.8 + t * 1.5) % 6.5) - 3.5
				s.CFrame = b * CFrame.new(x, 3.1, 1.6)
			end
			task.wait(0.05)
		end
	end)
end }

PIECES.CandyMachine = { size = Vector3.new(4, 7, 4), build = function(f, b)
	add(f, b, { size = Vector3.new(3.6, 5, 3), at = Vector3.new(0, 2.5, 1.5), color = C(110, 200, 255) })
	add(f, b, { size = Vector3.new(2.6, 2.6, 2.6), at = Vector3.new(0, 6.2, 1.5), shape = Enum.PartType.Ball, color = C(255, 255, 255), mat = GLASS, alpha = 0.35 })
	for i = 1, 5 do
		add(f, b, { size = Vector3.new(0.7, 0.7, 0.7), at = Vector3.new(math.cos(i) * 0.6, 5.8 + (i % 2) * 0.4, 1.5 + math.sin(i) * 0.6), shape = Enum.PartType.Ball, color = CANDY[i] })
	end
	add(f, b, { size = Vector3.new(1, 0.6, 1.2), at = Vector3.new(0, 1.2, -0.3), color = C(250, 210, 40) })
	glow(add(f, b, { size = Vector3.new(2.8, 0.3, 0.1), at = Vector3.new(0, 4.2, -0.02), color = C(255, 80, 160), mat = NEON }), C(255, 80, 160), 6, 0.8)
end }

PIECES.ChocolateRiver = { size = Vector3.new(8, 1, 8), build = function(f, b)
	add(f, b, { size = Vector3.new(T, 0.2, T * 0.7), at = Vector3.new(0, 0.12, 0), color = C(95, 55, 30), shine = 0.15 })
	add(f, b, { size = Vector3.new(3.4, H - 0.5, 0.4), at = Vector3.new(0, (H - 0.5) / 2, T / 2 - 0.4), color = C(110, 65, 35), shine = 0.2 })
	for i = -1, 1 do
		add(f, b, { size = Vector3.new(0.8, 0.25, 3.4), at = Vector3.new(i * 1.6, 0.4, 0), color = C(160, 110, 60), mat = WOOD })
	end
end }

PIECES.TaffyPuller = { size = Vector3.new(5, 7, 4), build = function(f, b)
	add(f, b, { size = Vector3.new(4, 3, 3), at = Vector3.new(0, 1.5, 1.4), color = C(190, 195, 205), mat = METAL })
	local arms = {}
	for _, x in ipairs({ -1, 1 }) do
		table.insert(arms, add(f, b, { size = Vector3.new(0.4, 3, 0.4), at = Vector3.new(x, 4.5, 1.4), color = C(150, 155, 165), mat = METAL }))
	end
	add(f, b, { size = Vector3.new(2.6, 0.9, 0.9), at = Vector3.new(0, 5.8, 1.4), color = C(255, 150, 200), shape = Enum.PartType.Ball })
end }

PIECES.GummyBear = { size = Vector3.new(4, 7, 4), build = function(f, b)
	local col = CANDY[math.random(1, #CANDY)]
	local function ball(s, at)
		add(f, b, { size = s, at = at, shape = Enum.PartType.Ball, color = col, mat = GLASS, alpha = 0.25 })
	end
	ball(Vector3.new(3, 3.6, 2.6), Vector3.new(0, 2.4, 1))
	ball(Vector3.new(2.4, 2.2, 2.2), Vector3.new(0, 5, 1))
	ball(Vector3.new(0.9, 0.9, 0.7), Vector3.new(-0.9, 6.1, 1))
	ball(Vector3.new(0.9, 0.9, 0.7), Vector3.new(0.9, 6.1, 1))
	ball(Vector3.new(1, 1.5, 1), Vector3.new(-1.6, 3, 0.8))
	ball(Vector3.new(1, 1.5, 1), Vector3.new(1.6, 3, 0.8))
	ball(Vector3.new(1.2, 1.2, 1.4), Vector3.new(-0.8, 0.6, 0.6))
	ball(Vector3.new(1.2, 1.2, 1.4), Vector3.new(0.8, 0.6, 0.6))
	add(f, b, { size = Vector3.new(3.4, 0.4, 3.4), at = Vector3.new(0, 0.2, 1), rot = UP, shape = Enum.PartType.Cylinder, color = C(250, 250, 250) })
end }

PIECES.Lollipop = { size = Vector3.new(4, 9, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(0.4, 6, 0.4), at = Vector3.new(0, 3, 1.5), color = C(250, 250, 250) })
	local disc = add(f, b, { size = Vector3.new(0.5, 4, 4), at = Vector3.new(0, 7.6, 1.5), rot = CFrame.Angles(0, math.rad(90), 0), shape = Enum.PartType.Cylinder, color = CANDY[math.random(1, #CANDY)] })
	label(disc, Enum.NormalId.Left, "\u{1F300}", C(255, 255, 255))
	label(disc, Enum.NormalId.Right, "\u{1F300}", C(255, 255, 255))
end }

PIECES.Sprinkles = { size = Vector3.new(6, 1, 6), build = function(f, b)
	for i = 1, 14 do
		add(f, b, { size = Vector3.new(1.4, 0.35, 0.35), at = Vector3.new(math.random(-28, 28) / 10, 0.2, math.random(-28, 28) / 10), rot = CFrame.Angles(0, math.rad(math.random(0, 179)), 0), color = CANDY[i % #CANDY + 1] })
	end
end }

PIECES.JellyCube = { size = Vector3.new(3, 3, 3), build = function(f, b)
	local cube = add(f, b, { size = Vector3.new(2.6, 2.6, 2.6), at = Vector3.new(0, 1.3, 1), color = CANDY[math.random(1, #CANDY)], mat = GLASS, alpha = 0.3 })
	TweenService:Create(cube, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = Vector3.new(2.9, 2.2, 2.9) }):Play()
end }

PIECES.GoldGumdrops = { size = Vector3.new(5, 3, 5), build = function(f, b)
	for i = 1, 9 do
		local p = add(f, b, { size = Vector3.new(1.3, 1.1, 1.3), at = Vector3.new(math.cos(i * 1.7) * (i % 3) * 0.8, 0.6 + (i > 6 and 1 or 0), 1 + math.sin(i * 1.7) * (i % 3) * 0.8), shape = Enum.PartType.Ball, color = C(255, 200, 60), mat = Enum.Material.Foil, shine = 0.2 })
		if i == 1 then
			glow(p, C(255, 210, 90), 10, 0.8)
		end
	end
end }

PIECES.VaultDoor = { size = Vector3.new(8, 9, 1), build = function(f, b)
	local d = add(f, b, { size = Vector3.new(0.8, 8.5, 8.5), at = Vector3.new(0, 5, T / 2 - 0.5), rot = CFrame.Angles(0, math.rad(90), 0), shape = Enum.PartType.Cylinder, color = C(200, 170, 80), mat = METAL, shine = 0.1 })
	local _ = d
	for k = 0, 5 do
		add(f, b, { size = Vector3.new(3.4, 0.35, 0.35), at = Vector3.new(0, 5, T / 2 - 1.1), rot = CFrame.Angles(0, 0, math.rad(k * 30)), color = C(120, 100, 50), mat = METAL })
	end
	add(f, b, { size = Vector3.new(1, 1, 1), at = Vector3.new(0, 5, T / 2 - 1.2), shape = Enum.PartType.Ball, color = C(120, 100, 50), mat = METAL })
end }

PIECES.Monitors = { size = Vector3.new(5, 6, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(5, 0.3, 2.2), at = Vector3.new(0, 3, 1.8), color = C(70, 75, 85), mat = METAL })
	add(f, b, { size = Vector3.new(4.6, 2.8, 2), at = Vector3.new(0, 1.5, 1.8), color = C(55, 60, 70), mat = METAL, alpha = 0.1 })
	for i = -1, 1 do
		local scr = add(f, b, { size = Vector3.new(1.4, 1, 0.1), at = Vector3.new(i * 1.55, 4, 2.4), color = C(40, 160, 255), mat = NEON })
		label(scr, Enum.NormalId.Front, ({ "\u{1F4F9}", "\u{1F47B}", "\u{1F4C8}" })[i + 2])
	end
end }

-- ---- hospital
PIECES.Ambulance = { size = Vector3.new(8, 7, 14), build = function(f, b)
	add(f, b, { size = Vector3.new(6, 5.5, 10), at = Vector3.new(0, 3.4, 0), color = C(245, 245, 245) })
	add(f, b, { size = Vector3.new(6, 3.6, 3.4), at = Vector3.new(0, 2.5, -6.6), color = C(245, 245, 245) })
	add(f, b, { size = Vector3.new(6.05, 0.7, 13.4), at = Vector3.new(0, 3.4, -1.7), color = C(220, 40, 40) })
	add(f, b, { size = Vector3.new(5, 1.4, 0.1), at = Vector3.new(0, 3.6, -8.3), color = C(150, 200, 230), mat = GLASS, alpha = 0.3 })
	for _, x in ipairs({ -2.6, 2.6 }) do
		for _, z in ipairs({ -6.5, 3 }) do
			add(f, b, { size = Vector3.new(0.6, 2, 2), at = Vector3.new(x * 1.1, 1, z), shape = Enum.PartType.Cylinder, color = C(30, 30, 30) })
		end
	end
	local red = add(f, b, { size = Vector3.new(1, 0.5, 0.6), at = Vector3.new(-1.2, 6.4, -4), color = C(255, 40, 40), mat = NEON })
	local blue = add(f, b, { size = Vector3.new(1, 0.5, 0.6), at = Vector3.new(1.2, 6.4, -4), color = C(40, 120, 255), mat = NEON })
	task.spawn(function()
		local on = false
		while red.Parent do
			on = not on
			red.Transparency, blue.Transparency = on and 0 or 0.8, on and 0.8 or 0
			task.wait(0.5)
		end
	end)
	label(add(f, b, { size = Vector3.new(0.05, 1.6, 4), at = Vector3.new(3.05, 4.3, 0), color = C(245, 245, 245) }), Enum.NormalId.Right, "AMBULANCE", C(220, 40, 40))
end }

PIECES.XRay = { size = Vector3.new(6, 8, 5), build = function(f, b)
	add(f, b, { size = Vector3.new(1, 7, 1), at = Vector3.new(-2.5, 3.5, 2), color = C(200, 205, 210), mat = METAL })
	add(f, b, { size = Vector3.new(5, 0.8, 1), at = Vector3.new(-0.5, 7, 2), color = C(200, 205, 210), mat = METAL })
	add(f, b, { size = Vector3.new(1.6, 1.6, 1.6), at = Vector3.new(1.5, 6, 1), color = C(230, 232, 235), mat = METAL })
	local box = add(f, b, { size = Vector3.new(3.4, 2.6, 0.2), at = Vector3.new(0, 5, T / 2 - 0.3), color = C(210, 235, 255), mat = NEON })
	label(box, Enum.NormalId.Front, "\u{1F9B4}\u{1F590}", C(40, 60, 90))
end }

PIECES.Curtain = { size = Vector3.new(6, 8, 1), build = function(f, b)
	add(f, b, { size = Vector3.new(6, 0.2, 0.2), at = Vector3.new(0, 8, 0), color = C(180, 185, 190), mat = METAL })
	for i = -2, 2 do
		add(f, b, { size = Vector3.new(1.3, 6.5, 0.12), at = Vector3.new(i * 1.15, 4.6, (i % 2) * 0.2), color = C(150, 200, 180), mat = Enum.Material.Fabric })
	end
end }

PIECES.IVStand = { size = Vector3.new(2, 7, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(0.15, 6.5, 0.15), at = Vector3.new(0, 3.25, 1), color = C(190, 195, 200), mat = METAL })
	add(f, b, { size = Vector3.new(1.6, 0.15, 1.6), at = Vector3.new(0, 0.1, 1), rot = UP, shape = Enum.PartType.Cylinder, color = C(190, 195, 200), mat = METAL })
	add(f, b, { size = Vector3.new(0.7, 1.1, 0.3), at = Vector3.new(0.3, 5.9, 1), color = C(200, 230, 255), mat = GLASS, alpha = 0.3 })
	local mon = add(f, b, { size = Vector3.new(1.4, 1, 0.2), at = Vector3.new(-0.6, 4.8, 1), color = C(30, 30, 35) })
	label(mon, Enum.NormalId.Front, "\u{1F49A}", C(80, 255, 120))
end }

PIECES.WaitingChairs = { size = Vector3.new(8, 4, 2), build = function(f, b)
	for i = -1.5, 1.5 do
		add(f, b, { size = Vector3.new(1.6, 0.3, 1.6), at = Vector3.new(i * 1.8, 1.8, 1.4), color = C(70, 110, 170) })
		add(f, b, { size = Vector3.new(1.6, 1.8, 0.25), at = Vector3.new(i * 1.8, 2.8, 2.15), color = C(70, 110, 170) })
	end
	add(f, b, { size = Vector3.new(7.4, 1.6, 0.3), at = Vector3.new(0, 0.9, 1.4), color = C(120, 125, 135), mat = METAL })
end }

PIECES.WashingMachines = { size = Vector3.new(8, 4, 3), build = function(f, b)
	for i = -1, 1 do
		add(f, b, { size = Vector3.new(2.4, 3, 2.4), at = Vector3.new(i * 2.5, 1.5, 1.7), color = C(245, 245, 248) })
		add(f, b, { size = Vector3.new(0.15, 1.5, 1.5), at = Vector3.new(i * 2.5, 1.6, 0.48), rot = CFrame.Angles(0, math.rad(90), 0), shape = Enum.PartType.Cylinder, color = C(160, 190, 220), mat = GLASS, alpha = 0.3 })
	end
end }

PIECES.Sofa = { size = Vector3.new(7, 4, 3), build = function(f, b)
	local col = ({ C(70, 130, 140), C(150, 60, 70), C(110, 90, 160) })[math.random(1, 3)]
	add(f, b, { size = Vector3.new(6, 1.2, 2.6), at = Vector3.new(0, 1, 1.6), color = col, mat = Enum.Material.Fabric })
	add(f, b, { size = Vector3.new(6, 2, 0.6), at = Vector3.new(0, 2.2, 2.7), color = col, mat = Enum.Material.Fabric })
	for _, x in ipairs({ -3, 3 }) do
		add(f, b, { size = Vector3.new(0.6, 1.8, 2.6), at = Vector3.new(x, 1.5, 1.6), color = col, mat = Enum.Material.Fabric })
	end
end }

PIECES.TV = { size = Vector3.new(4, 5, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(3, 2, 1.4), at = Vector3.new(0, 1, 2.6), color = C(90, 60, 40), mat = WOOD })
	local scr = add(f, b, { size = Vector3.new(3.6, 2.2, 0.3), at = Vector3.new(0, 3.2, 2.9), color = C(20, 20, 25) })
	local inner = add(f, b, { size = Vector3.new(3.2, 1.8, 0.05), at = Vector3.new(0, 3.2, 2.73), color = C(120, 160, 200), mat = NEON, alpha = 0.3 })
	glow(inner, C(140, 180, 255), 8, 0.6)
	local _ = scr
end }

PIECES.Beakers = { size = Vector3.new(4, 3, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(4.5, 0.3, 2.2), at = Vector3.new(0, 3.2, 1.8), color = C(240, 240, 240) })
	add(f, b, { size = Vector3.new(4.2, 3, 2), at = Vector3.new(0, 1.5, 1.8), color = C(200, 205, 210), mat = METAL })
	local cols = { C(80, 255, 120), C(80, 180, 255), C(255, 140, 60), C(220, 90, 255) }
	for i = 1, 4 do
		local liq = add(f, b, { size = Vector3.new(1.2, 0.7, 0.7), at = Vector3.new(-1.8 + i * 0.75, 4, 1.6 + (i % 2) * 0.5), rot = UP, shape = Enum.PartType.Cylinder, color = cols[i], mat = NEON, alpha = 0.2 })
		if i == 2 then
			glow(liq, cols[i], 8, 0.7)
		end
	end
	add(f, b, { size = Vector3.new(0.5, 1.4, 0.5), at = Vector3.new(1.6, 4.1, 2.3), color = C(40, 40, 45), mat = METAL })
end }

PIECES.RadioDesk = { size = Vector3.new(5, 6, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(4.5, 0.3, 2.2), at = Vector3.new(0, 3, 1.8), color = C(110, 80, 55), mat = WOOD })
	add(f, b, { size = Vector3.new(2.6, 1.5, 1.4), at = Vector3.new(0, 3.9, 2), color = C(60, 70, 60), mat = METAL })
	for i = -1, 1 do
		glow(add(f, b, { size = Vector3.new(0.3, 0.3, 0.1), at = Vector3.new(i * 0.6, 4.1, 1.28), shape = Enum.PartType.Ball, color = i == 0 and C(255, 60, 60) or C(80, 255, 120), mat = NEON }), C(80, 255, 120), 4, 0.5)
	end
	add(f, b, { size = Vector3.new(0.15, 5, 0.15), at = Vector3.new(1.6, 6.5, 2.5), color = C(180, 180, 185), mat = METAL })
end }

PIECES.LiftDoors = { size = Vector3.new(6, 9, 1), build = function(f, b)
	for _, x in ipairs({ -1.1, 1.1 }) do
		add(f, b, { size = Vector3.new(2.1, 7.5, 0.3), at = Vector3.new(x, 3.75, T / 2 - 0.25), color = C(180, 185, 192), mat = METAL, shine = 0.15 })
	end
	label(add(f, b, { size = Vector3.new(1.6, 0.8, 0.1), at = Vector3.new(0, 8.2, T / 2 - 0.3), color = C(20, 20, 20) }), Enum.NormalId.Front, "\u{25B2} 3", C(255, 140, 40))
end }

-- ---- party house
PIECES.Fireplace = { size = Vector3.new(6, 7, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(6, 6, 1.6), at = Vector3.new(0, 3, T / 2 - 0.8), color = C(130, 120, 115), mat = Enum.Material.Slate })
	add(f, b, { size = Vector3.new(3.2, 3, 0.2), at = Vector3.new(0, 1.6, T / 2 - 1.6), color = C(20, 15, 15) })
	local fire = add(f, b, { size = Vector3.new(2, 1, 0.6), at = Vector3.new(0, 0.7, T / 2 - 1.2), color = C(255, 120, 30), mat = NEON })
	local l = glow(fire, C(255, 140, 50), 14, 1.4)
	task.spawn(function()
		while fire.Parent do
			l.Brightness = 1 + math.random() * 0.8
			task.wait(0.15 + math.random() * 0.2)
		end
	end)
	add(f, b, { size = Vector3.new(6.6, 0.4, 1.9), at = Vector3.new(0, 6.2, T / 2 - 0.9), color = C(90, 60, 40), mat = WOOD })
end }

PIECES.Armchair = { size = Vector3.new(3, 4, 3), build = function(f, b)
	local col = ({ C(140, 40, 60), C(60, 90, 70), C(100, 70, 130) })[math.random(1, 3)]
	add(f, b, { size = Vector3.new(2.6, 1.2, 2.4), at = Vector3.new(0, 1, 1), color = col, mat = Enum.Material.Fabric })
	add(f, b, { size = Vector3.new(2.6, 2.6, 0.5), at = Vector3.new(0, 2.5, 2.1), color = col, mat = Enum.Material.Fabric })
	for _, x in ipairs({ -1.4, 1.4 }) do
		add(f, b, { size = Vector3.new(0.4, 1.8, 2.4), at = Vector3.new(x, 1.5, 1), color = col, mat = Enum.Material.Fabric })
	end
end }

PIECES.Stove = { size = Vector3.new(6, 6, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(3, 3.6, 2.6), at = Vector3.new(-1.6, 1.8, 2.3), color = C(60, 60, 65), mat = METAL })
	for _, x in ipairs({ -2.2, -1 }) do
		add(f, b, { size = Vector3.new(0.1, 0.9, 0.9), at = Vector3.new(x, 3.65, 2.3), rot = UP, shape = Enum.PartType.Cylinder, color = C(200, 60, 40), mat = NEON })
	end
	add(f, b, { size = Vector3.new(1.4, 1, 1.4), at = Vector3.new(-1.6, 4.2, 2.3), rot = UP, shape = Enum.PartType.Cylinder, color = C(150, 150, 155), mat = METAL })
	add(f, b, { size = Vector3.new(2.6, 6.5, 2.6), at = Vector3.new(1.8, 3.25, 2.3), color = C(235, 235, 230) })
	add(f, b, { size = Vector3.new(0.15, 1.6, 0.2), at = Vector3.new(0.7, 4.5, 0.95), color = C(150, 150, 155), mat = METAL })
end }

PIECES.Candelabra = { size = Vector3.new(2, 4, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(0.3, 3, 0.3), at = Vector3.new(0, 1.5, 0), color = C(200, 170, 80), mat = METAL })
	for i = -1, 1 do
		add(f, b, { size = Vector3.new(0.2, 0.8, 0.2), at = Vector3.new(i * 0.6, 3.3, 0), color = C(250, 245, 230) })
		glow(add(f, b, { size = Vector3.new(0.25, 0.35, 0.25), at = Vector3.new(i * 0.6, 3.85, 0), shape = Enum.PartType.Ball, color = C(255, 200, 80), mat = NEON }), C(255, 190, 90), 6, 0.6)
	end
end }

PIECES.Arcade = { size = Vector3.new(3, 7, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(2.6, 6.4, 2.4), at = Vector3.new(0, 3.2, 2.2), color = C(60, 40, 130) })
	local scr = add(f, b, { size = Vector3.new(2, 1.6, 0.1), at = Vector3.new(0, 4.6, 0.98), color = C(80, 220, 255), mat = NEON })
	label(scr, Enum.NormalId.Front, "\u{1F47E}", C(255, 255, 255))
	glow(scr, C(120, 220, 255), 8, 0.6)
	add(f, b, { size = Vector3.new(2.4, 0.6, 1), at = Vector3.new(0, 3.2, 0.8), color = C(30, 30, 35) })
end }

PIECES.Plants = { size = Vector3.new(3, 5, 3), build = function(f, b)
	for i = -1, 1, 2 do
		add(f, b, { size = Vector3.new(1.6, 1.8, 1.8), at = Vector3.new(i * 1.4, 0.8, 1.8), rot = UP, shape = Enum.PartType.Cylinder, color = C(180, 100, 60), mat = Enum.Material.Slate })
		add(f, b, { size = Vector3.new(2.6, 3, 2.6), at = Vector3.new(i * 1.4, 3, 1.8), shape = Enum.PartType.Ball, color = C(70, 150, 75), mat = Enum.Material.Grass })
	end
end }

PIECES.Sacks = { size = Vector3.new(5, 3, 3), build = function(f, b)
	for i = -1, 1 do
		local s = add(f, b, { size = Vector3.new(1.8, 2.2, 1.4), at = Vector3.new(i * 1.7, 1.1, 2), color = C(225, 205, 160), mat = Enum.Material.Fabric })
		if i == 0 then
			label(s, Enum.NormalId.Front, "SUGAR", C(120, 80, 40))
		end
	end
end }

PIECES.Bathroom = { size = Vector3.new(6, 6, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(1.6, 1.3, 2), at = Vector3.new(-1.8, 0.65, 2), color = C(245, 245, 248) })
	add(f, b, { size = Vector3.new(1.8, 1.8, 0.7), at = Vector3.new(-1.8, 1.9, 3), color = C(245, 245, 248) })
	add(f, b, { size = Vector3.new(2.2, 0.8, 1.6), at = Vector3.new(1.8, 3, 2.6), color = C(245, 245, 248) })
	add(f, b, { size = Vector3.new(0.6, 2.6, 0.6), at = Vector3.new(1.8, 1.3, 2.8), color = C(230, 230, 235) })
	add(f, b, { size = Vector3.new(2.4, 2.6, 0.1), at = Vector3.new(1.8, 5.4, T / 2 - 0.2), color = C(200, 225, 240), mat = GLASS, shine = 0.4 })
end }

PIECES.Wardrobe = { size = Vector3.new(4, 8, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(4, 7.5, 1.8), at = Vector3.new(0, 3.75, T / 2 - 1), color = C(110, 75, 50), mat = WOOD })
	add(f, b, { size = Vector3.new(0.08, 7, 0.1), at = Vector3.new(0, 3.75, T / 2 - 1.95), color = C(60, 40, 25) })
	for _, x in ipairs({ -0.3, 0.3 }) do
		add(f, b, { size = Vector3.new(0.2, 0.2, 0.2), at = Vector3.new(x, 3.8, T / 2 - 2), shape = Enum.PartType.Ball, color = C(200, 170, 80), mat = METAL })
	end
end }

PIECES.ToyBox = { size = Vector3.new(4, 4, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(3.4, 2, 2.2), at = Vector3.new(0, 1, 2), color = C(230, 80, 90) })
	add(f, b, { size = Vector3.new(1.2, 1.2, 1.2), at = Vector3.new(-0.8, 2.6, 2), shape = Enum.PartType.Ball, color = C(61, 139, 255) })
	add(f, b, { size = Vector3.new(1, 1, 1), at = Vector3.new(0.8, 2.5, 2), color = C(250, 210, 40) })
	-- a rocking horse
	add(f, b, { size = Vector3.new(2.6, 1.2, 0.8), at = Vector3.new(0, 2.2, -0.6), color = C(200, 150, 90), mat = WOOD })
	add(f, b, { size = Vector3.new(0.8, 1.4, 0.7), at = Vector3.new(1.3, 3.1, -0.6), color = C(200, 150, 90), mat = WOOD })
	add(f, b, { size = Vector3.new(3.2, 0.3, 0.4), at = Vector3.new(0, 0.3, -0.6), color = C(150, 90, 50), mat = WOOD })
end }

PIECES.Easels = { size = Vector3.new(6, 6, 2), build = function(f, b)
	for i = -1, 1, 2 do
		add(f, b, { size = Vector3.new(0.2, 5, 0.2), at = Vector3.new(i * 1.8, 2.5, 1.5), color = C(150, 100, 60), mat = WOOD })
		local c = add(f, b, { size = Vector3.new(2.6, 2.2, 0.15), at = Vector3.new(i * 1.8, 4, 1.3), color = C(240, 235, 220) })
		label(c, Enum.NormalId.Front, i < 0 and "\u{1F5BC}" or "\u{1F305}")
	end
end }

PIECES.Trunks = { size = Vector3.new(6, 3, 3), build = function(f, b)
	for i = -1, 1, 2 do
		add(f, b, { size = Vector3.new(2.8, 1.8, 1.8), at = Vector3.new(i * 1.6, 0.9, 2), color = C(100, 60, 35), mat = WOOD })
		add(f, b, { size = Vector3.new(2.85, 0.25, 1.85), at = Vector3.new(i * 1.6, 1.4, 2), color = C(200, 170, 80), mat = METAL })
	end
end }

PIECES.DustSheets = { size = Vector3.new(6, 5, 4), build = function(f, b)
	add(f, b, { size = Vector3.new(3, 3.6, 2.4), at = Vector3.new(-1.4, 1.8, 1.6), color = C(235, 232, 225), mat = Enum.Material.Fabric })
	add(f, b, { size = Vector3.new(2, 2.4, 2), at = Vector3.new(1.8, 1.2, 1.8), shape = Enum.PartType.Ball, color = C(235, 232, 225), mat = Enum.Material.Fabric })
end }

PIECES.Dolls = { size = Vector3.new(5, 3, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(4.6, 0.3, 1.4), at = Vector3.new(0, 2.6, 2.6), color = C(150, 100, 60), mat = WOOD })
	for i = -1, 1 do
		local col = CANDY[i + 3]
		add(f, b, { size = Vector3.new(0.7, 1, 0.5), at = Vector3.new(i * 1.4, 3.3, 2.6), color = col, mat = Enum.Material.Fabric })
		add(f, b, { size = Vector3.new(0.6, 0.6, 0.6), at = Vector3.new(i * 1.4, 4.1, 2.6), shape = Enum.PartType.Ball, color = C(250, 220, 200) })
	end
end }

PIECES.Crib = { size = Vector3.new(5, 4, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(4.4, 0.3, 2.6), at = Vector3.new(0, 1.6, 1.8), color = C(240, 240, 245) })
	for i = 0, 6 do
		add(f, b, { size = Vector3.new(0.15, 2.4, 0.15), at = Vector3.new(-2.1 + i * 0.7, 2.4, 0.5), color = C(240, 240, 245) })
	end
	add(f, b, { size = Vector3.new(1.2, 1.2, 1.2), at = Vector3.new(0, 2.3, 2), shape = Enum.PartType.Ball, color = C(160, 110, 70), mat = Enum.Material.Fabric })
end }

PIECES.Clocks = { size = Vector3.new(4, 8, 2), build = function(f, b)
	for i = -1, 1, 2 do
		add(f, b, { size = Vector3.new(1.8, 7.6, 1.3), at = Vector3.new(i * 1.4, 3.8, T / 2 - 0.9), color = C(95, 60, 35), mat = WOOD })
		local face = add(f, b, { size = Vector3.new(0.1, 1.4, 1.4), at = Vector3.new(i * 1.4, 6.3, T / 2 - 1.6), rot = CFrame.Angles(0, math.rad(90), 0), shape = Enum.PartType.Cylinder, color = C(245, 235, 210) })
		local hand = add(f, b, { size = Vector3.new(0.08, 0.6, 0.05), at = Vector3.new(i * 1.4, 6.5, T / 2 - 1.67), color = C(20, 20, 20) })
		local _ = face
		local pend = add(f, b, { size = Vector3.new(0.15, 1.8, 0.15), at = Vector3.new(i * 1.4, 3.6, T / 2 - 1.6), color = C(200, 170, 80), mat = METAL })
		local base = b * CFrame.new(i * 1.4, 4.5, T / 2 - 1.6)
		task.spawn(function()
			local t = math.random() * 6
			while pend.Parent do
				t += 0.1
				pend.CFrame = base * CFrame.Angles(0, 0, math.sin(t * 2) * 0.35) * CFrame.new(0, -0.9, 0)
				hand.CFrame = b * CFrame.new(i * 1.4, 6.3, T / 2 - 1.67) * CFrame.Angles(0, 0, -t * 0.2) * CFrame.new(0, 0.3, 0)
				task.wait(0.1)
			end
		end)
	end
end }

PIECES.Drums = { size = Vector3.new(5, 4, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(2, 2, 2), at = Vector3.new(-1, 1, 1.6), rot = CFrame.Angles(0, math.rad(90), 0), shape = Enum.PartType.Cylinder, color = C(200, 40, 50) })
	add(f, b, { size = Vector3.new(0.8, 1.4, 1.4), at = Vector3.new(0.8, 2.4, 1.2), rot = UP, shape = Enum.PartType.Cylinder, color = C(200, 40, 50) })
	add(f, b, { size = Vector3.new(0.1, 1.6, 1.6), at = Vector3.new(1.8, 3.6, 1.8), rot = UP, shape = Enum.PartType.Cylinder, color = C(220, 190, 80), mat = METAL })
	-- a guitar on the wall
	add(f, b, { size = Vector3.new(1.6, 2, 0.4), at = Vector3.new(-1.5, 5, T / 2 - 0.4), shape = Enum.PartType.Ball, color = C(190, 110, 40), mat = WOOD })
	add(f, b, { size = Vector3.new(0.3, 2.6, 0.2), at = Vector3.new(-1.5, 7, T / 2 - 0.4), color = C(90, 60, 40), mat = WOOD })
end }

PIECES.Globe = { size = Vector3.new(4, 5, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(0.3, 2.6, 0.3), at = Vector3.new(0, 1.3, 1), color = C(100, 70, 45), mat = WOOD })
	local g = add(f, b, { size = Vector3.new(1.8, 1.8, 1.8), at = Vector3.new(0, 3.3, 1), shape = Enum.PartType.Ball, color = C(70, 140, 200) })
	label(g, Enum.NormalId.Front, "\u{1F30D}", C(255, 255, 255))
	-- a reading lamp
	add(f, b, { size = Vector3.new(0.2, 5, 0.2), at = Vector3.new(2, 2.5, 2), color = C(40, 40, 40), mat = METAL })
	glow(add(f, b, { size = Vector3.new(1.2, 0.8, 1.2), at = Vector3.new(2, 5.2, 2), color = C(255, 220, 150), mat = NEON, alpha = 0.2 }), C(255, 210, 140), 10, 0.8)
end }

PIECES.CoatRack = { size = Vector3.new(3, 7, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(0.3, 6.4, 0.3), at = Vector3.new(0, 3.2, 2), color = C(90, 60, 40), mat = WOOD })
	for i = 1, 3 do
		add(f, b, { size = Vector3.new(1.1, 2.4, 0.5), at = Vector3.new(math.cos(i * 2) * 0.5, 4.8, 2 + math.sin(i * 2) * 0.5), color = CANDY[i], mat = Enum.Material.Fabric })
	end
	label(add(f, b, { size = Vector3.new(2.6, 3.2, 0.15), at = Vector3.new(-2.4, 5.5, T / 2 - 0.2), color = C(110, 80, 40), mat = WOOD }), Enum.NormalId.Front, "\u{1F9D3}")
end }

PIECES.Runner = { size = Vector3.new(4, 1, 8), build = function(f, b)
	add(f, b, { size = Vector3.new(3, 0.08, T * 2.6), at = Vector3.new(0, 0.07, 0), color = C(130, 30, 45), mat = Enum.Material.Fabric })
end }

PIECES.Crates = { size = Vector3.new(5, 6, 4), build = function(f, b)
	for k = 0, 2 do
		add(f, b, { size = Vector3.new(2.6 - k * 0.4, 2, 2.6 - k * 0.4), at = Vector3.new(-1.2, 1 + k * 2, 2), rot = CFrame.Angles(0, math.rad(k * 17), 0), color = C(170, 125, 80), mat = Enum.Material.Cardboard })
	end
	add(f, b, { size = Vector3.new(3, 0.5, 3), at = Vector3.new(1.8, 0.25, 2), color = C(150, 110, 70), mat = WOOD })
	add(f, b, { size = Vector3.new(2.4, 2.2, 2.4), at = Vector3.new(1.8, 1.6, 2), color = C(185, 140, 90), mat = Enum.Material.Cardboard })
end }

PIECES.Lockers = { size = Vector3.new(6, 8, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(6, 7.6, 1.8), at = Vector3.new(0, 3.8, T / 2 - 1), color = C(120, 140, 170), mat = METAL })
	for d = -1, 1 do
		add(f, b, { size = Vector3.new(0.1, 7.2, 0.1), at = Vector3.new(d * 2 + 1, 3.8, T / 2 - 1.95), color = C(40, 45, 55) })
		add(f, b, { size = Vector3.new(1.2, 0.6, 0.05), at = Vector3.new(d * 2, 6.6, T / 2 - 1.95), color = C(60, 70, 85) })
	end
	add(f, b, { size = Vector3.new(5, 0.4, 1.2), at = Vector3.new(0, 1.6, 0.5), color = C(150, 110, 70), mat = WOOD })
end }

PIECES.Counter = { size = Vector3.new(6, 5, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(6, 3.6, 2.2), at = Vector3.new(0, 1.8, 2.2), color = C(165, 200, 185) })
	add(f, b, { size = Vector3.new(6.2, 0.3, 2.4), at = Vector3.new(0, 3.75, 2.2), color = C(240, 242, 242) })
	local scr = add(f, b, { size = Vector3.new(1.6, 1.1, 0.15), at = Vector3.new(1.4, 4.6, 2.6), color = C(40, 160, 255), mat = NEON })
	local _ = scr
	add(f, b, { size = Vector3.new(0.5, 0.4, 0.5), at = Vector3.new(-1.6, 4.1, 2), shape = Enum.PartType.Ball, color = C(230, 190, 60), mat = METAL })
end }

PIECES.Trays = { size = Vector3.new(5, 4, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(5, 3.4, 2.2), at = Vector3.new(0, 1.7, 2.2), color = C(200, 205, 210), mat = METAL })
	for i = -1, 1 do
		add(f, b, { size = Vector3.new(1.4, 0.15, 1), at = Vector3.new(i * 1.6, 3.5, 2), color = C(240, 120, 60) })
		add(f, b, { size = Vector3.new(0.6, 0.6, 0.6), at = Vector3.new(i * 1.6, 3.85, 2), shape = Enum.PartType.Ball, color = CANDY[i + 3] })
	end
end }

-- ---------------------------------------------------------------- room looks
-- walls: { material, colour, height (nil: full) }; pieces: set pieces to place
local WALLS = {
	brick = { Enum.Material.Brick, C(125, 70, 55) },
	steel = { Enum.Material.DiamondPlate, C(130, 135, 145) },
	tiles = { Enum.Material.CeramicTiles, C(225, 228, 230) },
	wood = { Enum.Material.WoodPlanks, C(110, 72, 45), 4.5 },
	choc = { Enum.Material.SmoothPlastic, C(110, 65, 35) },
	gold = { Enum.Material.Foil, C(205, 170, 80) },
	mint = { Enum.Material.SmoothPlastic, C(170, 225, 200) },
	lilac = { Enum.Material.SmoothPlastic, C(205, 180, 240) },
	green = { Enum.Material.Plaster, C(55, 90, 65) },
	red = { Enum.Material.Plaster, C(120, 40, 50) },
	blue = { Enum.Material.Plaster, C(80, 110, 160) },
	pastel = { Enum.Material.Plaster, C(240, 205, 215) },
	teal = { Enum.Material.Plaster, C(60, 120, 125) },
	purple = { Enum.Material.Plaster, C(85, 60, 120) },
	grey = { Enum.Material.Plaster, C(150, 155, 160) },
}

-- first match wins: words in the room's name -> its look (a 4th entry: only
-- in that building)
local LOOKS = {
	{ { "stairwell", "stairs" }, "grey", { "LiftDoors" }, "hospital" },
	{ { "children's ward" }, "pastel", { "ToyBox", "IVStand", "Curtain" } },
	{ { "vault entrance" }, "steel", { "Monitors", "GoldGumdrops" } },
	{ { "archive" }, "lilac", { "Monitors", "JellyCube" } },
	{ { "ball pit" }, "lilac", { "GummyBear", "Lollipop" } },
	{ { "slide" }, "pastel", { "Lollipop", "Sprinkles" } },
	{ { "bounce room" }, "mint", { "JellyCube", "Lollipop" } },
	{ { "boiler" }, "brick", { "Boiler", "Pipes" } },
	{ { "generator" }, "brick", { "Generator", "Pipes" } },
	{ { "water tank" }, "brick", { "WaterTank", "Pipes" } },
	{ { "conveyor" }, "steel", { "Conveyor", "Conveyor", "CandyMachine" } },
	{ { "factory floor" }, "steel", { "CandyMachine", "Conveyor", "Pipes" } },
	{ { "chocolate" }, "choc", { "ChocolateRiver" } },
	{ { "wrapper" }, "steel", { "Conveyor", "Crates" } },
	{ { "packing", "loading", "dock" }, "brick", { "Crates", "Crates" } },
	{ { "taste lab" }, "lilac", { "Beakers", "CandyMachine" } },
	{ { "sugar" }, "pastel", { "Sacks", "Sacks" } },
	{ { "locker" }, "blue", { "Lockers" } },
	{ { "taffy" }, "pastel", { "TaffyPuller" } },
	{ { "sprinkle" }, "pastel", { "Sprinkles", "Lollipop" } },
	{ { "bear gallery" }, "lilac", { "GummyBear", "GummyBear" } },
	{ { "gummy lobby", "lollipop" }, nil, { "Lollipop", "Lollipop", "GummyBear" } },
	{ { "candy kitchen" }, "tiles", { "Stove", "CandyMachine" } },
	{ { "jelly corridor", "wobble", "jelly pool" }, "mint", { "JellyCube", "JellyCube" } },
	{ { "jelly bank" }, "gold", { "GoldGumdrops", "Counter" } },
	{ { "gold gumdrop" }, "gold", { "GoldGumdrops", "GoldGumdrops" } },
	{ { "vault" }, "steel", { "VaultDoor", "GoldGumdrops" } },
	{ { "gumball" }, "pastel", { "CandyMachine", "CandyMachine" } },
	{ { "sticky" }, "mint", { "Crates", "JellyCube" } },
	{ { "security" }, "steel", { "Monitors" } },
	-- hospital
	{ { "ambulance" }, "brick", { "Ambulance" } },
	{ { "x-ray" }, "steel", { "XRay", "IVStand" } },
	{ { "ward" }, "mint", { "Curtain", "IVStand", "Curtain" } },
	{ { "waiting" }, nil, { "WaitingChairs", "WaitingChairs", "TV" } },
	{ { "laundry" }, "tiles", { "WashingMachines" } },
	{ { "canteen" }, "tiles", { "Trays", "Trays" } },
	{ { "reception", "nurses' station" }, nil, { "Counter", "WaitingChairs", "Plants" } },
	{ { "day room", "quiet room", "staff room" }, nil, { "Sofa", "TV", "Plants" } },
	{ { "science lab", "lab store" }, "steel", { "Beakers", "Beakers" } },
	{ { "plant lab" }, "green", { "Plants", "Plants", "Beakers" } },
	{ { "radio" }, "steel", { "RadioDesk", "Monitors" } },
	{ { "lift" }, "steel", { "LiftDoors", "WaitingChairs" } },
	{ { "pharmacy", "medicine" }, "tiles", { "Counter" } },
	{ { "records", "nurses' office" }, "grey", { "Monitors" } },
	{ { "supply" }, "grey", { "Crates", "Crates" } },
	{ { "main corridor", "lab entrance" }, nil, { "WaitingChairs", "IVStand" } },
	-- party house
	{ { "parlour" }, "red", { "Fireplace", "Armchair", "Armchair" } },
	{ { "library" }, "green", { "Globe", "Armchair", "Fireplace" } },
	{ { "study" }, "green", { "Globe" } },
	{ { "music" }, "purple", { "Drums" } },
	{ { "kitchen" }, "tiles", { "Stove" } },
	{ { "dining" }, "red", { "Candelabra", "Candelabra" } },
	{ { "game room" }, "teal", { "Arcade", "Arcade" } },
	{ { "conservatory" }, "green", { "Plants", "Plants" } },
	{ { "pantry" }, "wood", { "Sacks" } },
	{ { "bath" }, "tiles", { "Bathroom" } },
	{ { "clock" }, "wood", { "Clocks" } },
	{ { "trunk" }, "wood", { "Trunks", "Trunks" } },
	{ { "dusty", "box room" }, "wood", { "DustSheets", "Crates" } },
	{ { "doll" }, "pastel", { "Dolls", "ToyBox" } },
	{ { "nursery", "playroom", "kids", "children" }, "pastel", { "ToyBox", "Wardrobe" } },
	{ { "bedroom", "guest" }, "blue", { "Wardrobe", "Armchair" } },
	{ { "gallery" }, "wood", { "Easels" } },
	{ { "linen" }, "tiles", { "WashingMachines" } },
	{ { "stairwell", "stairs", "landing" }, "wood", { "CoatRack" } },
	{ { "hall", "corridor" }, "wood", { "CoatRack", "Runner" } },
}

local function lookFor(name, theme)
	local n = string.lower(name)
	for _, l in ipairs(LOOKS) do
		for _, w in ipairs(l[1]) do
			if string.find(n, w, 1, true) and (l[4] == nil or l[4] == theme) then
				return l[2], l[3]
			end
		end
	end
	return nil, {}
end

-- the room's own walls: thin panels on every wall face round the room
local function lineWalls(folder, map, f, look)
	local w = WALLS[look]
	if not w then
		return
	end
	local top = f.tall and HT or H
	local h = w[3] or (top - 0.05)
	local function panel(cf, len)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Size = Vector3.new(len, h, 0.2)
		p.CFrame = cf
		p.Material, p.Color = w[1], w[2]
		p.Name = "WallLining"
		p.Parent = folder
		if w[3] then
			-- a wooden rail on top of half-height panelling
			local rail = p:Clone()
			rail.Size = Vector3.new(len, 0.3, 0.45)
			rail.CFrame = cf * CFrame.new(0, h / 2 + 0.15, 0.1)
			rail.Parent = folder
		end
	end
	-- runs of wall along each side
	local sides = {
		{ f.x0, f.x1, function(i) return i, f.y0 - 1 end, function(a, b) return Vector3.new((a + b + 1) / 2 * T, h / 2, f.y0 * T + 0.11), 0 end },
		{ f.x0, f.x1, function(i) return i, f.y1 + 1 end, function(a, b) return Vector3.new((a + b + 1) / 2 * T, h / 2, (f.y1 + 1) * T - 0.11), 0 end },
		{ f.y0, f.y1, function(i) return f.x0 - 1, i end, function(a, b) return Vector3.new(f.x0 * T + 0.11, h / 2, (a + b + 1) / 2 * T), 90 end },
		{ f.y0, f.y1, function(i) return f.x1 + 1, i end, function(a, b) return Vector3.new((f.x1 + 1) * T - 0.11, h / 2, (a + b + 1) / 2 * T), 90 end },
	}
	for _, s in ipairs(sides) do
		local runStart
		for i = s[1], s[2] + 1 do
			local wall = false
			if i <= s[2] then
				local cx, cy = s[3](i)
				wall = cell(map, cx, cy) == "#"
			end
			if wall and not runStart then
				runStart = i
			elseif not wall and runStart then
				local pos, turn = s[4](runStart, i - 1)
				panel(CFrame.new(pos) * CFrame.Angles(0, math.rad(turn), 0), (i - runStart) * T - 0.3)
				runStart = nil
			end
		end
	end
end

-- a model from ServerStorage/Props with this name, fitted to size, or nil
local function imported(name, base, size, folder)
	local props = ServerStorage:FindFirstChild("Props")
	local src = props and props:FindFirstChild(name)
	if not src then
		return false
	end
	local m = src:IsA("Model") and src:Clone() or nil
	if not m then
		m = Instance.new("Model")
		src:Clone().Parent = m
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored, d.CanCollide = true, false
		end
	end
	m:PivotTo(base.Rotation)
	local _, s = m:GetBoundingBox()
	local scale = math.min(size.X / s.X, size.Y / s.Y, size.Z / s.Z)
	if scale > 0 then
		m:ScaleTo(m:GetScale() * scale)
	end
	local cf, s2 = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + (base.Position + Vector3.new(0, s2.Y / 2, 0) - cf.Position))
	m.Parent = folder
	return true
end

-- dress every room
function Rooms.dress(world)
	local map = world.map
	local folder = Instance.new("Folder")
	folder.Name = "RoomDressing"
	folder.Parent = world.root
	-- tiles nothing may go on: objects (and round puzzles, doors, store
	-- rooms), starts, furniture, doorways and the tiles beside them
	local busy = {}
	local function mark(x, y, r)
		for dx = -r, r do
			for dy = -r, r do
				busy[(x + dx) .. "," .. (y + dy)] = true
			end
		end
	end
	for _, o in ipairs(map.objects) do
		mark(o.x, o.y, (o.kind == "hide" or o.kind == "search" or o.kind == "balloon" or o.kind == "present" or o.kind == "vent") and 0 or 1)
		if o.ix then
			mark(o.ix, o.iy, 1)
		end
	end
	for _, s in ipairs(map.start) do
		mark(s[1], s[2], 0)
	end
	for y = 0, map.h - 1 do
		for x = 0, map.w - 1 do
			local c = cell(map, x, y)
			if c ~= "." and c ~= "#" then
				mark(x, y, 1)
			elseif c == "." and ((cell(map, x - 1, y) == "#" and cell(map, x + 1, y) == "#") or (cell(map, x, y - 1) == "#" and cell(map, x, y + 1) == "#")) then
				mark(x, y, 1)
			end
		end
	end
	for _, c in ipairs(world.crates or {}) do
		mark(c.hx, c.hy, 0)
	end
	if map.loft then
		local L = map.loft
		for y = L.stairY0 - 1, L.stairY1 + 1 do
			for x = L.stairX - 1, L.stairX + 1 do
				busy[x .. "," .. y] = true
			end
		end
	end

	for _, f in ipairs(map.floors) do
		local look, pieces = lookFor(f.name, map.theme or "party")
		if look then
			lineWalls(folder, map, f, look)
		end
		-- a free tile for each piece: against a wall if possible, else any free one
		for _, name in ipairs(pieces) do
			local piece = PIECES[name]
			if piece then
				local best, bestDir
				for pass = 1, 2 do
					for y = f.y0, f.y1 do
						for x = f.x0, f.x1 do
							if not best and cell(map, x, y) == "." and not busy[x .. "," .. y] then
								local dir
								for _, d in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
									if not dir and cell(map, x + d[1], y + d[2]) == "#" then
										dir = d
									end
								end
								if dir or pass == 2 then
									best, bestDir = { x, y }, dir or { 0, -1 }
								end
							end
						end
					end
					if best then
						break
					end
				end
				if best then
					busy[best[1] .. "," .. best[2]] = true
					local centre = at(best[1], best[2])
					-- face away from the wall behind it (+Z towards the wall)
					local wallDir = Vector3.new(bestDir[1], 0, bestDir[2])
					local base = CFrame.lookAt(centre, centre - wallDir)
					local sub = Instance.new("Model")
					sub.Name = name
					sub.Parent = folder
					if not imported(name, base, piece.size, sub) then
						local ok, err = pcall(piece.build, sub, base)
						if not ok then
							warn("Room dressing: " .. name .. " in " .. f.name .. " failed - " .. tostring(err))
						end
					end
				end
			end
		end
	end
	return folder
end

return Rooms
