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
local Sfx = require(ReplicatedStorage.Shared.Sfx)
local current = { world = nil, room = nil } -- the world and room being dressed

-- a prompt that makes a noise (TV, radio, drums, arcade): the host comes to look
local function noisy(p, label, soundId, seconds)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Switch on"
	pp.ObjectText = label .. " (noisy!)"
	pp.HoldDuration = 0.3
	pp.MaxActivationDistance = 9
	pp.RequiresLineOfSight = false
	pp.Parent = p
	local world = current.world
	pp.Triggered:Connect(function(plr)
		pp.Enabled = false
		if soundId and soundId > 0 then
			local s = Instance.new("Sound")
			s.SoundId = "rbxassetid://" .. soundId
			s.Volume = 1.2
			s.Looped = true
			s.RollOffMaxDistance = 90
			s.SoundGroup = Sfx.group()
			s.Parent = p
			s:Play()
			task.delay(seconds or 6, function()
				s:Destroy()
			end)
		end
		if world and world.onLure then
			world.onLure(plr, p.Position, label)
		end
		task.delay(40, function()
			pp.Enabled = true
		end)
	end)
end

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
	-- the pipe comes out of the wall and down into the top of the tank
	add(f, b, { size = Vector3.new(0.6, 0.6, 3.4), at = Vector3.new(0, 8.4, 2.3), color = C(110, 120, 130), mat = METAL })
	add(f, b, { size = Vector3.new(0.6, 0.7, 0.6), at = Vector3.new(0, 8.1, 0.8), color = C(110, 120, 130), mat = METAL })
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
	-- a pool at the foot of the waterfall: wading through it is slow
	local pool = add(f, b, { name = "ChocolateRiver", size = Vector3.new(T, 0.2, T * 0.7), at = Vector3.new(0, 0.12, 0), color = C(95, 55, 30), shine = 0.15 })
	pool.CanQuery = true
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

-- a little plush animal (the Plushie Book's builder, without its sparkle),
-- `height` studs tall, its feet at `cf` (facing -Z like the pieces)
local function plush(f, cf, height, color, animal)
	local ok, m = pcall(function()
		return require(game:GetService("ReplicatedStorage").Shared.Plushies).build({ animal = animal or "bear", color = color }, cf, true, true)
	end)
	if not ok or not m then
		return
	end
	local _, size = m:GetBoundingBox()
	if size.Y > 0.1 then
		m:ScaleTo(height / size.Y)
	end
	local bcf, bsize = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + (cf.Position + Vector3.new(0, bsize.Y / 2, 0) - bcf.Position))
	m.Parent = f
end

PIECES.GummyBear = { size = Vector3.new(4, 7, 4), build = function(f, b)
	-- a big gummy bear on a stand, facing the room: shiny candy body, a paler
	-- belly and muzzle, round ears, dark eyes and nose (it read as a pile of
	-- see-through balls before)
	local col = CANDY[math.random(1, #CANDY)]
	local pale = col:Lerp(C(255, 255, 255), 0.45)
	local DARK = C(40, 25, 35)
	local function ball(s, at, c, rot)
		return add(f, b, { size = s, at = at, rot = rot, shape = Enum.PartType.Ball, color = c or col, alpha = c and 0 or 0.12, shine = 0.12 })
	end
	add(f, b, { size = Vector3.new(0.4, 3.6, 3.6), at = Vector3.new(0, 0.2, 1), rot = UP, shape = Enum.PartType.Cylinder, color = C(250, 250, 250) })
	ball(Vector3.new(1.4, 1.5, 1.6), Vector3.new(-0.8, 1.1, 0.8)) -- feet
	ball(Vector3.new(1.4, 1.5, 1.6), Vector3.new(0.8, 1.1, 0.8))
	ball(Vector3.new(2.8, 3.2, 2.4), Vector3.new(0, 2.7, 1)) -- body
	ball(Vector3.new(1.8, 2, 0.6), Vector3.new(0, 2.6, -0.05), pale) -- belly
	ball(Vector3.new(1, 1.8, 1), Vector3.new(-1.5, 3.2, 0.8), nil, CFrame.Angles(0, 0, math.rad(-25))) -- arms
	ball(Vector3.new(1, 1.8, 1), Vector3.new(1.5, 3.2, 0.8), nil, CFrame.Angles(0, 0, math.rad(25)))
	ball(Vector3.new(2.6, 2.3, 2.2), Vector3.new(0, 5.2, 1)) -- head
	ball(Vector3.new(1, 1, 0.6), Vector3.new(-0.95, 6.3, 1)) -- ears
	ball(Vector3.new(1, 1, 0.6), Vector3.new(0.95, 6.3, 1))
	ball(Vector3.new(1.1, 0.8, 0.6), Vector3.new(0, 4.85, -0.05), pale) -- muzzle
	ball(Vector3.new(0.45, 0.32, 0.3), Vector3.new(0, 5.05, -0.32), DARK) -- nose
	ball(Vector3.new(0.35, 0.42, 0.22), Vector3.new(-0.5, 5.6, 0), DARK) -- eyes
	ball(Vector3.new(0.35, 0.42, 0.22), Vector3.new(0.5, 5.6, 0), DARK)
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
		add(f, b, { size = Vector3.new(1.55, 1.15, 0.35), at = Vector3.new(i * 1.55, 4, 2.62), color = C(35, 35, 40) }) -- its case
		add(f, b, { size = Vector3.new(0.25, 0.4, 0.25), at = Vector3.new(i * 1.55, 3.35, 2.6), color = C(35, 35, 40) }) -- its stand
		label(scr, Enum.NormalId.Front, ({ "\u{1F4F9}", "\u{1F47B}", "\u{1F4C8}" })[i + 2])
	end
end }

PIECES.FilingCabinets = { size = Vector3.new(7, 6, 2), build = function(f, b)
	for i = -1, 1 do
		local col = ({ C(255, 170, 200), C(170, 220, 255), C(200, 240, 170) })[i + 2]
		add(f, b, { size = Vector3.new(2.2, 5.4, 1.8), at = Vector3.new(i * 2.3, 2.7, T / 2 - 1), color = col })
		for d = 0, 3 do
			add(f, b, { size = Vector3.new(1.9, 1.1, 0.08), at = Vector3.new(i * 2.3, 0.8 + d * 1.3, T / 2 - 1.94), color = C(250, 250, 250), alpha = 0.3 })
			add(f, b, { size = Vector3.new(0.6, 0.15, 0.1), at = Vector3.new(i * 2.3, 1.1 + d * 1.3, T / 2 - 2), color = C(200, 170, 80), mat = METAL })
		end
	end
	label(add(f, b, { size = Vector3.new(4, 1, 0.1), at = Vector3.new(0, 6.3, T / 2 - 0.2), color = C(255, 210, 63) }), Enum.NormalId.Front, "ARCHIVE", C(90, 40, 60))
end }

PIECES.PaperStacks = { size = Vector3.new(4, 3, 3), build = function(f, b)
	for i = -1, 1 do
		for k = 0, 3 - (i % 2) do
			add(f, b, { size = Vector3.new(1.4, 0.35, 1), at = Vector3.new(i * 1.5, 0.2 + k * 0.38, 1.2 + (k % 2) * 0.1), rot = CFrame.Angles(0, math.rad(k * 9), 0), color = k % 2 == 0 and C(250, 248, 240) or C(255, 230, 150) })
		end
	end
end }

-- honey dripping down a wall (the archive is sticky)
PIECES.HoneyDrips = { size = Vector3.new(8, 10, 1), build = function(f, b)
	for i = -3, 3 do
		local len = 1.5 + (i % 3) * 1.2
		add(f, b, { size = Vector3.new(0.7, len, 0.25), at = Vector3.new(i * 1.1, H - 0.5 - len / 2, T / 2 - 0.2), color = C(240, 160, 30), mat = GLASS, alpha = 0.15 })
		add(f, b, { size = Vector3.new(0.8, 0.8, 0.4), at = Vector3.new(i * 1.1, H - 0.5 - len, T / 2 - 0.25), shape = Enum.PartType.Ball, color = C(240, 160, 30), mat = GLASS, alpha = 0.15 })
	end
	add(f, b, { size = Vector3.new(2.6, 0.12, 2), at = Vector3.new(0.5, 0.07, 1.2), color = C(240, 160, 30), mat = GLASS, alpha = 0.2 })
end }

PIECES.LightSwitch = { size = Vector3.new(1, 2, 1), build = function(f, b)
	local plate = add(f, b, { size = Vector3.new(0.8, 1.2, 0.12), at = Vector3.new(0, 4.6, T / 2 - 0.08), color = C(240, 236, 225) })
	add(f, b, { size = Vector3.new(0.25, 0.45, 0.12), at = Vector3.new(0, 4.6, T / 2 - 0.16), color = C(255, 210, 63), mat = NEON })
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Lights off"
	pp.ObjectText = "Light switch"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 8
	pp.RequiresLineOfSight = false
	pp.Parent = plate
	local world, room = current.world, current.room
	pp.Triggered:Connect(function(plr)
		if world and world.onSwitch then
			world.onSwitch(plr, room)
		end
	end)
	if world then
		world.switches = world.switches or {}
		world.switches[room] = pp
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
	-- a curtain on a stand: a pole at each end, with feet
	for _, x in ipairs({ -3, 3 }) do
		add(f, b, { size = Vector3.new(0.15, 8, 0.15), at = Vector3.new(x, 4, 0), color = C(180, 185, 190), mat = METAL })
		add(f, b, { size = Vector3.new(0.2, 0.15, 1.4), at = Vector3.new(x, 0.08, 0), color = C(180, 185, 190), mat = METAL })
	end
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
	noisy(scr, "TV", Config.AMBIENT.buzz, 6)
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
	for _, x in ipairs({ -2, 2 }) do
		for _, z in ipairs({ 0.9, 2.7 }) do
			add(f, b, { size = Vector3.new(0.25, 2.85, 0.25), at = Vector3.new(x, 1.43, z), color = C(110, 80, 55), mat = WOOD })
		end
	end
	add(f, b, { size = Vector3.new(2.6, 1.5, 1.4), at = Vector3.new(0, 3.9, 2), color = C(60, 70, 60), mat = METAL })
	for i = -1, 1 do
		glow(add(f, b, { size = Vector3.new(0.3, 0.3, 0.1), at = Vector3.new(i * 0.6, 4.1, 1.28), shape = Enum.PartType.Ball, color = i == 0 and C(255, 60, 60) or C(80, 255, 120), mat = NEON }), C(80, 255, 120), 4, 0.5)
	end
	local mast = add(f, b, { size = Vector3.new(0.15, 5, 0.15), at = Vector3.new(1.6, 6.5, 2.5), color = C(180, 180, 185), mat = METAL })
	local _ = mast
	noisy(f:FindFirstChildWhichIsA("BasePart") or mast, "Radio", Config.AMBIENT.buzz, 6)
end }

PIECES.LiftDoors = { size = Vector3.new(6, 9, 1), build = function(f, b)
	for _, x in ipairs({ -1.1, 1.1 }) do
		add(f, b, { size = Vector3.new(2.1, 7.5, 0.3), at = Vector3.new(x, 3.75, T / 2 - 0.25), color = C(180, 185, 192), mat = METAL, shine = 0.15 })
	end
	label(add(f, b, { size = Vector3.new(1.6, 0.8, 0.1), at = Vector3.new(0, 8.2, T / 2 - 0.3), color = C(20, 20, 20) }), Enum.NormalId.Front, "\u{25B2} 3", C(255, 140, 40))
end }

-- ---- the Sunken Aquarium
PIECES.FishTank = { size = Vector3.new(7, 7, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(7, 6, 1.6), at = Vector3.new(0, 4, T / 2 - 0.85), color = C(60, 150, 210), mat = GLASS, alpha = 0.45 })
	add(f, b, { size = Vector3.new(7.3, 0.4, 1.8), at = Vector3.new(0, 0.9, T / 2 - 0.85), color = C(40, 40, 45), mat = METAL })
	add(f, b, { size = Vector3.new(7.3, 0.4, 1.8), at = Vector3.new(0, 7.1, T / 2 - 0.85), color = C(40, 40, 45), mat = METAL })
	add(f, b, { size = Vector3.new(6.8, 0.5, 1.4), at = Vector3.new(0, 1.35, T / 2 - 0.85), color = C(230, 205, 150), mat = Enum.Material.Sand })
	local cols = { C(255, 140, 40), C(255, 220, 60), C(255, 90, 140), C(120, 230, 160) }
	local Fish = require(script.Parent.Fish)
	for i = 1, 4 do
		-- real little fish swimming along the tank, turning at each end
		local y = 2.6 + (i % 3) * 1.2
		local a = (b * CFrame.new(-2.6, y, T / 2 - 0.85)).Position
		local z = (b * CFrame.new(2.6, y + 0.3, T / 2 - 0.85)).Position
		local start = a:Lerp(z, i / 5)
		local body = Fish.make(f, CFrame.new(start), cols[i], 0.9)
		Fish.swim(body, i % 2 == 0 and a or z, i % 2 == 0 and z or a, 2.4 + i * 0.5)
	end
	glow(add(f, b, { size = Vector3.new(0.3, 0.3, 0.3), at = Vector3.new(0, 6.6, T / 2 - 0.85), color = C(170, 220, 255), mat = NEON }), C(140, 200, 255), 10, 0.8)
end }

PIECES.JellyTank = { size = Vector3.new(4, 8, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(3.6, 7, 1.6), at = Vector3.new(0, 4, T / 2 - 0.85), color = C(30, 40, 90), mat = GLASS, alpha = 0.35 })
	for i = 1, 3 do
		-- a round bell with four trailing tentacles,
		-- welded to it so they drift together (inside the tank)
		local col = ({ C(255, 140, 220), C(160, 140, 255), C(120, 230, 255) })[i]
		local jelly = add(f, b, { size = Vector3.new(1.1, 0.8, 1.1), at = Vector3.new((i - 2) * 1, 2.2 + i * 1.2, T / 2 - 0.85), shape = Enum.PartType.Ball, color = col, mat = NEON, alpha = 0.3 })
		local function hang(size, off, shape)
			local p = add(f, b, { size = size, at = Vector3.new((i - 2) * 1, 2.2 + i * 1.2, T / 2 - 0.85) + off, shape = shape, color = col, mat = NEON, alpha = 0.35 })
			p.Anchored, p.Massless = false, true
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = jelly, p
			w.Parent = p
		end
		for k = 0, 3 do
			local a = k * math.pi / 2 + 0.4
			hang(Vector3.new(0.08, 1, 0.08), Vector3.new(math.cos(a) * 0.3, -0.75, math.sin(a) * 0.3))
		end
		TweenService:Create(jelly, TweenInfo.new(2.6 + i * 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = jelly.CFrame * CFrame.new(0, 0.9, 0) }):Play()
		glow(jelly, C(200, 150, 255), 6, 0.5)
	end
end }

PIECES.WaterPool = { size = Vector3.new(8, 1, 8), build = function(f, b)
	-- a shallow pool: wading through it is slow (and for the host too)
	local pool = add(f, b, { name = "WadeWater", size = Vector3.new(T, 0.2, T * 0.7), at = Vector3.new(0, 0.12, 0), color = C(60, 150, 210), mat = GLASS, alpha = 0.2, shine = 0.1 })
	pool.CanQuery = true
	for i = -1, 1, 2 do
		add(f, b, { size = Vector3.new(T, 0.5, 0.4), at = Vector3.new(0, 0.25, i * (T * 0.35 + 0.2)), color = C(95, 100, 110), mat = Enum.Material.Slate })
	end
	require(script.Parent.Fish).make(f, b * CFrame.new(1.4, 0.35, 0.4) * CFrame.Angles(0, 0.8, 0), C(255, 140, 40), 0.9)
end }

PIECES.Porthole = { size = Vector3.new(4, 4, 1), build = function(f, b)
	add(f, b, { size = Vector3.new(0.4, 3.6, 3.6), at = Vector3.new(0, 6, T / 2 - 0.2), rot = CFrame.Angles(0, math.rad(90), 0), shape = Enum.PartType.Cylinder, color = C(200, 160, 70), mat = METAL, shine = 0.2 })
	local glass = add(f, b, { size = Vector3.new(0.2, 2.8, 2.8), at = Vector3.new(0, 6, T / 2 - 0.45), rot = CFrame.Angles(0, math.rad(90), 0), shape = Enum.PartType.Cylinder, color = C(30, 90, 150), mat = GLASS, alpha = 0.2 })
	glow(glass, C(80, 160, 230), 8, 0.6)
	label(add(f, b, { size = Vector3.new(2.6, 2.6, 0.05), at = Vector3.new(0, 6, T / 2 - 0.58), color = C(30, 90, 150), alpha = 1 }), Enum.NormalId.Front, "\u{1F420}", C(255, 255, 255))
end }

PIECES.DivingGear = { size = Vector3.new(4, 7, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(0.4, 5, 0.4), at = Vector3.new(0, 2.5, T / 2 - 1), color = C(90, 70, 50), mat = WOOD })
	add(f, b, { size = Vector3.new(2.6, 2.6, 2.6), at = Vector3.new(0, 5.6, T / 2 - 1), shape = Enum.PartType.Ball, color = C(200, 150, 60), mat = METAL, shine = 0.25 })
	add(f, b, { size = Vector3.new(0.2, 1.2, 1.2), at = Vector3.new(0, 5.6, T / 2 - 2.3), rot = CFrame.Angles(0, math.rad(90), 0), shape = Enum.PartType.Cylinder, color = C(150, 200, 230), mat = GLASS })
	add(f, b, { size = Vector3.new(1.6, 3, 1), at = Vector3.new(1.8, 1.5, T / 2 - 0.8), color = C(240, 240, 235) }) -- an air tank
end }

PIECES.Penguins = { size = Vector3.new(6, 3, 3), build = function(f, b)
	for i = -1, 1 do
		-- a penguin: black body and head, white belly and face, eyes, an orange
		-- beak and feet, flippers - all welded to the body so it waddles as one
		local px = i * 1.9
		local body = add(f, b, { size = Vector3.new(1.4, 2, 1.2), at = Vector3.new(px, 1.05, 1), shape = Enum.PartType.Ball, color = C(30, 30, 35) })
		local function on(size, at, col, shape, rot)
			local p = add(f, b, { size = size, at = at, shape = shape or Enum.PartType.Ball, color = col, rot = rot })
			p.Anchored, p.Massless = false, true
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = body, p
			w.Parent = p
		end
		on(Vector3.new(1.05, 1.5, 0.3), Vector3.new(px, 0.95, 0.45), C(245, 245, 240))
		on(Vector3.new(1, 0.95, 0.95), Vector3.new(px, 2.3, 1), C(30, 30, 35))
		on(Vector3.new(0.7, 0.55, 0.25), Vector3.new(px, 2.25, 0.62), C(245, 245, 240))
		on(Vector3.new(0.13, 0.13, 0.1), Vector3.new(px - 0.17, 2.4, 0.5), C(20, 20, 25))
		on(Vector3.new(0.13, 0.13, 0.1), Vector3.new(px + 0.17, 2.4, 0.5), C(20, 20, 25))
		on(Vector3.new(0.24, 0.16, 0.42), Vector3.new(px, 2.18, 0.38), C(255, 170, 40), Enum.PartType.Block)
		on(Vector3.new(0.2, 1.1, 0.55), Vector3.new(px - 0.75, 1.2, 1), C(25, 25, 30), nil, CFrame.Angles(0, 0, math.rad(-15)))
		on(Vector3.new(0.2, 1.1, 0.55), Vector3.new(px + 0.75, 1.2, 1), C(25, 25, 30), nil, CFrame.Angles(0, 0, math.rad(15)))
		on(Vector3.new(0.4, 0.15, 0.55), Vector3.new(px - 0.3, 0.08, 0.75), C(255, 170, 40))
		on(Vector3.new(0.4, 0.15, 0.55), Vector3.new(px + 0.3, 0.08, 0.75), C(255, 170, 40))
		TweenService:Create(body, TweenInfo.new(0.9 + (i + 1) * 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = body.CFrame * CFrame.Angles(0, 0, math.rad(8)) }):Play()
	end
end }

-- ---- the Creepy Carnival
PIECES.TicketWindow = { size = Vector3.new(6, 9, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(6, 7, 2.4), at = Vector3.new(0, 3.5, T / 2 - 1.3), color = C(200, 40, 60) })
	add(f, b, { size = Vector3.new(3.4, 2.4, 0.1), at = Vector3.new(0, 4.6, T / 2 - 2.55), color = C(255, 230, 160), mat = GLASS, alpha = 0.5 })
	add(f, b, { size = Vector3.new(6.6, 0.4, 3), at = Vector3.new(0, 7.2, T / 2 - 1.3), color = C(230, 190, 80), mat = Enum.Material.Foil })
	label(add(f, b, { size = Vector3.new(5, 1.4, 0.1), at = Vector3.new(0, 8.2, T / 2 - 2.6), color = C(40, 20, 50) }), Enum.NormalId.Front, "\u{1F39F} TICKETS", C(255, 210, 63))
	glow(add(f, b, { size = Vector3.new(0.4, 0.4, 0.4), at = Vector3.new(0, 6.6, T / 2 - 2.6), color = C(255, 220, 140), mat = NEON }), C(255, 210, 140), 8, 0.7)
end }

PIECES.PrizeWall = { size = Vector3.new(7, 8, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(7, 7.5, 0.4), at = Vector3.new(0, 3.75, T / 2 - 0.2), color = C(120, 40, 60), mat = Enum.Material.Fabric })
	for row = 0, 2 do
		add(f, b, { size = Vector3.new(6.6, 0.3, 1.4), at = Vector3.new(0, 1.2 + row * 2.3, T / 2 - 0.9), color = C(150, 100, 60), mat = WOOD })
		for i = -2, 2 do
			-- a plush prize: a little bear, bunny, cat or dog in candy colors
			local col = CANDY[(i + row * 2) % #CANDY + 1]
			plush(f, b * CFrame.new(i * 1.25, 1.35 + row * 2.3, T / 2 - 0.9), 1.5, col, ({ "bear", "bunny", "cat", "dog" })[(i + row) % 4 + 1])
		end
	end
	label(add(f, b, { size = Vector3.new(5, 1, 0.1), at = Vector3.new(0, 7.9, T / 2 - 0.45), color = C(40, 20, 50) }), Enum.NormalId.Front, "\u{2B50} PRIZES \u{2B50}", C(255, 210, 63))
end }

PIECES.CrystalBall = { size = Vector3.new(4, 5, 4), build = function(f, b)
	add(f, b, { size = Vector3.new(3.4, 3, 3.4), at = Vector3.new(0, 1.5, 0.6), shape = Enum.PartType.Cylinder, rot = UP, color = C(80, 40, 110), mat = Enum.Material.Fabric })
	local ball = add(f, b, { size = Vector3.new(1.8, 1.8, 1.8), at = Vector3.new(0, 3.9, 0.6), shape = Enum.PartType.Ball, color = C(190, 150, 255), mat = GLASS, alpha = 0.25 })
	glow(ball, C(180, 120, 255), 12, 1.2)
	TweenService:Create(ball, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Color = C(120, 220, 255) }):Play()
	label(add(f, b, { size = Vector3.new(4, 2.4, 0.1), at = Vector3.new(0, 6.5, T / 2 - 0.1), color = C(40, 20, 60) }), Enum.NormalId.Front, "\u{1F52E} Your future: RUN!", C(220, 190, 255))
end }

PIECES.FunMirror = { size = Vector3.new(4, 9, 1), build = function(f, b)
	add(f, b, { size = Vector3.new(4, 8.6, 0.3), at = Vector3.new(0, 4.6, T / 2 - 0.2), color = C(230, 190, 80), mat = Enum.Material.Foil })
	-- a wavy mirror: three panes leaning different ways
	for i = -1, 1 do
		add(f, b, { size = Vector3.new(3.3, 2.5, 0.1), at = Vector3.new(0, 4.6 + i * 2.6, T / 2 - 0.42), rot = CFrame.Angles(math.rad(i * 9), math.rad(-i * 7), 0), color = C(205, 225, 240), mat = GLASS, shine = 0.6 })
	end
end }

PIECES.CostumeRack = { size = Vector3.new(6, 7, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(6, 0.25, 0.25), at = Vector3.new(0, 6.2, T / 2 - 1), color = C(150, 150, 160), mat = METAL })
	for _, x in ipairs({ -2.9, 2.9 }) do
		add(f, b, { size = Vector3.new(0.25, 6.2, 0.25), at = Vector3.new(x, 3.1, T / 2 - 1), color = C(150, 150, 160), mat = METAL })
	end
	local cols = { C(220, 40, 60), C(255, 200, 40), C(80, 170, 230), C(150, 80, 200), C(70, 190, 110) }
	for i = 1, 5 do
		local x = -2.4 + (i - 1) * 1.2
		add(f, b, { size = Vector3.new(1, 3.6, 0.6), at = Vector3.new(x, 4.2, T / 2 - 1), color = cols[i], mat = Enum.Material.Fabric })
		add(f, b, { size = Vector3.new(1.1, 0.35, 0.7), at = Vector3.new(x, 5.7, T / 2 - 1), color = C(250, 240, 225), mat = Enum.Material.Fabric }) -- a frilly collar
	end
end }

PIECES.Juggling = { size = Vector3.new(4, 5, 3), build = function(f, b)
	add(f, b, { size = Vector3.new(3.6, 2.4, 2), at = Vector3.new(0, 1.2, T / 2 - 1.2), color = C(60, 90, 180), mat = WOOD })
	for i = -1, 1 do
		add(f, b, { size = Vector3.new(0.35, 1.6, 0.35), at = Vector3.new(i * 0.9, 3.2, T / 2 - 1.5), color = C(250, 245, 235) })
		add(f, b, { size = Vector3.new(0.5, 0.5, 0.5), at = Vector3.new(i * 0.9, 3.9, T / 2 - 1.5), shape = Enum.PartType.Ball, color = CANDY[i + 2] })
	end
	for i = 1, 3 do
		add(f, b, { size = Vector3.new(0.7, 0.7, 0.7), at = Vector3.new(-1.2 + i * 0.6, 2.75, T / 2 - 0.6), shape = Enum.PartType.Ball, color = CANDY[i + 3] })
	end
end }

PIECES.Weights = { size = Vector3.new(6, 3, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(5.6, 0.3, 0.3), at = Vector3.new(0, 1.3, T / 2 - 1.2), rot = CFrame.Angles(0, 0, 0), color = C(150, 150, 160), mat = METAL })
	for _, x in ipairs({ -2.4, 2.4 }) do
		add(f, b, { size = Vector3.new(0.8, 2.6, 2.6), at = Vector3.new(x, 1.3, T / 2 - 1.2), shape = Enum.PartType.Cylinder, color = C(30, 30, 35) })
	end
	label(add(f, b, { size = Vector3.new(3, 1.2, 0.1), at = Vector3.new(0, 5.5, T / 2 - 0.1), color = C(40, 20, 50) }), Enum.NormalId.Front, "1 TON!", C(255, 210, 63))
end }

PIECES.BumperCars = { size = Vector3.new(7, 3, 4), build = function(f, b)
	for i, x in ipairs({ -1.8, 1.8 }) do
		add(f, b, { size = Vector3.new(1.4, 3.2, 3.2), at = Vector3.new(x, 0.8, 0), shape = Enum.PartType.Cylinder, rot = UP, color = C(30, 30, 35) })
		add(f, b, { size = Vector3.new(1.2, 2.8, 2.8), at = Vector3.new(x, 1.8, 0), shape = Enum.PartType.Cylinder, rot = UP, color = i == 1 and C(220, 40, 60) or C(80, 170, 230) })
		local col = i == 1 and C(220, 40, 60) or C(80, 170, 230)
		add(f, b, { size = Vector3.new(1.8, 1.3, 0.35), at = Vector3.new(x, 2.8, 0.95), color = col })
		add(f, b, { size = Vector3.new(1.4, 0.3, 1), at = Vector3.new(x, 2.35, 0.4), color = C(40, 40, 45) })
		add(f, b, { size = Vector3.new(0.15, 0.9, 0.9), at = Vector3.new(x, 2.8, -0.6), rot = CFrame.Angles(0, math.rad(90), math.rad(60)), shape = Enum.PartType.Cylinder, color = C(30, 30, 30) })
		add(f, b, { size = Vector3.new(2.6, 0.6, 0.5), at = Vector3.new(x, 0.9, -1.55), color = C(30, 30, 35) })
		add(f, b, { size = Vector3.new(0.15, 6, 0.15), at = Vector3.new(x, 5, 1.35), color = C(150, 150, 160), mat = METAL })
		glow(add(f, b, { size = Vector3.new(0.3, 0.3, 0.3), at = Vector3.new(x, 8, 1.35), shape = Enum.PartType.Ball, color = C(255, 230, 120), mat = NEON }), C(255, 220, 120), 4, 0.6)
	end
end }

PIECES.Tilted = { size = Vector3.new(6, 9, 1), build = function(f, b)
	-- crooked pictures and a shelf that slopes: everything here is a bit wonky
	for i, x in ipairs({ -1.8, 1.8 }) do
		local frame = add(f, b, { size = Vector3.new(2.4, 2, 0.2), at = Vector3.new(x, 7, T / 2 - 0.15), rot = CFrame.Angles(0, 0, math.rad(i == 1 and 18 or -24)), color = C(150, 100, 60), mat = WOOD })
		label(frame, Enum.NormalId.Front, i == 1 and "\u{1F921}" or "\u{1F3AA}", C(255, 255, 255))
	end
	add(f, b, { size = Vector3.new(5, 0.3, 1.2), at = Vector3.new(0, 4, T / 2 - 0.6), rot = CFrame.Angles(0, 0, math.rad(-12)), color = C(150, 100, 60), mat = WOOD })
	add(f, b, { size = Vector3.new(0.8, 0.8, 0.8), at = Vector3.new(1.6, 4.1, T / 2 - 0.6), shape = Enum.PartType.Ball, color = C(255, 210, 63) })
end }

PIECES.RollingBarrel = { size = Vector3.new(7, 7, 4), build = function(f, b)
	-- a giant striped barrel on its side (the ride's spare), slowly rolling in place
	local barrel = add(f, b, { size = Vector3.new(6.4, 6, 6), at = Vector3.new(0, 3.1, T / 2 - 3.2), shape = Enum.PartType.Cylinder, color = C(200, 40, 60), mat = WOOD })
	local turning = { barrel }
	for i = -1, 1 do
		table.insert(turning, add(f, b, { size = Vector3.new(0.6, 6.15, 6.15), at = Vector3.new(i * 2.2, 3.1, T / 2 - 3.2), shape = Enum.PartType.Cylinder, color = C(250, 240, 225), mat = WOOD }))
	end
	-- dark planks along it, so you can see it roll
	for k = 0, 5 do
		local a = k * math.pi / 3
		table.insert(turning, add(f, b, { size = Vector3.new(6.45, 0.25, 0.5), at = Vector3.new(0, 3.1 + math.cos(a) * 2.95, T / 2 - 3.2 + math.sin(a) * 2.95), rot = CFrame.Angles(a, 0, 0), color = C(120, 25, 40), mat = WOOD }))
	end
	local centre = barrel.CFrame
	local offsets = {}
	for _, p in ipairs(turning) do
		offsets[p] = centre:ToObjectSpace(p.CFrame)
	end
	task.spawn(function()
		local angle = 0
		while barrel.Parent do
			angle += 0.05 * 0.7
			for p, off in pairs(offsets) do
				p.CFrame = centre * CFrame.Angles(angle, 0, 0) * off
			end
			task.wait(0.05)
		end
	end)
	label(add(f, b, { size = Vector3.new(4, 1.2, 0.1), at = Vector3.new(0, 8, T / 2 - 0.1), color = C(40, 20, 50) }), Enum.NormalId.Front, "ROLL UP! ROLL UP!", C(255, 210, 63))
end }

PIECES.JokeShelf = { size = Vector3.new(6, 8, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(6, 7.5, 1.6), at = Vector3.new(0, 3.75, T / 2 - 0.8), color = C(255, 200, 40), mat = WOOD })
	for row = 0, 2 do
		for i = -2, 2 do
			if (i + row) % 2 == 0 then
				add(f, b, { size = Vector3.new(0.8, 0.8, 0.8), at = Vector3.new(i * 1.1, 1.5 + row * 2.3, T / 2 - 1.75), shape = Enum.PartType.Ball, color = C(230, 40, 50) }) -- clown noses
			else
				add(f, b, { size = Vector3.new(0.9, 0.9, 0.7), at = Vector3.new(i * 1.1, 1.5 + row * 2.3, T / 2 - 1.75), color = CANDY[(i + row + 5) % #CANDY + 1] }) -- joke boxes
			end
		end
	end
	label(add(f, b, { size = Vector3.new(4, 1, 0.1), at = Vector3.new(0, 8, T / 2 - 0.1), color = C(40, 20, 50) }), Enum.NormalId.Front, "HA HA HA!", C(255, 80, 120))
end }

-- ---- the Midnight School
PIECES.Blackboard = { size = Vector3.new(8, 6, 1), build = function(f, b)
	local board = add(f, b, { size = Vector3.new(7, 3.6, 0.2), at = Vector3.new(0, 5.6, T / 2 - 0.15), color = C(40, 70, 52) })
	add(f, b, { size = Vector3.new(7.4, 4, 0.15), at = Vector3.new(0, 5.6, T / 2 - 0.08), color = C(120, 85, 50), mat = WOOD })
	add(f, b, { size = Vector3.new(7, 0.25, 0.5), at = Vector3.new(0, 3.7, T / 2 - 0.4), color = C(120, 85, 50), mat = WOOD })
	add(f, b, { size = Vector3.new(0.5, 0.15, 0.15), at = Vector3.new(-2, 3.9, T / 2 - 0.4), color = C(250, 250, 245) })
	local lines = { "A  B  C", "2 + 2 = ?", "\u{1F383} BOO!", "Homework:\nESCAPE", "7 x 3 = 21" }
	label(board, Enum.NormalId.Front, lines[math.random(1, #lines)], C(235, 240, 230))
end }

PIECES.SchoolDesks = { size = Vector3.new(8, 4, 6), build = function(f, b)
	for _, dx in ipairs({ -2, 2 }) do
		for _, dz in ipairs({ -1.6, 1.6 }) do
			add(f, b, { size = Vector3.new(2.4, 0.25, 1.6), at = Vector3.new(dx, 2.5, dz), color = C(176, 128, 78), mat = WOOD })
			add(f, b, { size = Vector3.new(2.2, 2.4, 0.15), at = Vector3.new(dx, 1.2, dz - 0.7), color = C(120, 125, 132), mat = METAL })
			add(f, b, { size = Vector3.new(1.4, 0.2, 1.2), at = Vector3.new(dx, 1.5, dz + 1.1), color = C(70, 110, 170) })
			add(f, b, { size = Vector3.new(1.4, 1.2, 0.15), at = Vector3.new(dx, 2.2, dz + 1.65), color = C(70, 110, 170) })
			for _, lx in ipairs({ -0.6, 0.6 }) do
				for _, lz in ipairs({ 0.6, 1.6 }) do
					add(f, b, { size = Vector3.new(0.12, 1.4, 0.12), at = Vector3.new(dx + lx, 0.7, dz + lz), color = C(120, 125, 132), mat = METAL })
				end
			end
		end
	end
	add(f, b, { size = Vector3.new(0.8, 1.1, 0.2), at = Vector3.new(-2, 2.75, -1.6), color = C(250, 245, 230) }) -- a test paper
end }

PIECES.Trophies = { size = Vector3.new(5, 7, 2), build = function(f, b)
	add(f, b, { size = Vector3.new(5, 6.5, 1.6), at = Vector3.new(0, 3.25, T / 2 - 0.9), color = C(120, 85, 50), mat = WOOD })
	add(f, b, { size = Vector3.new(4.6, 6, 0.1), at = Vector3.new(0, 3.3, T / 2 - 1.72), color = C(200, 225, 240), mat = GLASS, alpha = 0.6 })
	for row = 0, 2 do
		for i = -1, 1 do
			local cup = add(f, b, { size = Vector3.new(0.6, 0.9, 0.6), at = Vector3.new(i * 1.3, 1.4 + row * 1.9, T / 2 - 1.1), shape = Enum.PartType.Cylinder, rot = UP, color = row == 0 and C(205, 127, 50) or row == 1 and C(200, 200, 210) or C(255, 205, 60), mat = Enum.Material.Foil, shine = 0.3 })
			local _ = cup
		end
	end
	glow(add(f, b, { size = Vector3.new(0.3, 0.3, 0.3), at = Vector3.new(0, 6.3, T / 2 - 1), color = C(255, 240, 200), mat = NEON }), C(255, 230, 170), 6, 0.6)
end }

PIECES.Telescope = { size = Vector3.new(4, 6, 4), build = function(f, b)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		add(f, b, { size = Vector3.new(0.2, 3.4, 0.2), at = Vector3.new(math.cos(a) * 0.8, 1.6, 1 + math.sin(a) * 0.8), rot = CFrame.Angles(math.sin(a) * 0.25, 0, -math.cos(a) * 0.25), color = C(90, 70, 50), mat = WOOD })
	end
	add(f, b, { size = Vector3.new(4.2, 0.7, 0.7), at = Vector3.new(0, 4, 1), rot = CFrame.Angles(0, math.rad(90), math.rad(35)), shape = Enum.PartType.Cylinder, color = C(200, 160, 70), mat = METAL, shine = 0.2 })
	local map = add(f, b, { size = Vector3.new(4, 3, 0.1), at = Vector3.new(0, 6, T / 2 - 0.1), color = C(20, 25, 60) })
	label(map, Enum.NormalId.Front, "\u{2B50} \u{1F319} \u{2728}", C(255, 240, 180))
end }

PIECES.BigBell = { size = Vector3.new(5, 8, 5), build = function(f, b)
	add(f, b, { size = Vector3.new(0.5, 7, 0.5), at = Vector3.new(-2.2, 3.5, 1), color = C(90, 70, 50), mat = WOOD })
	add(f, b, { size = Vector3.new(0.5, 7, 0.5), at = Vector3.new(2.2, 3.5, 1), color = C(90, 70, 50), mat = WOOD })
	add(f, b, { size = Vector3.new(5, 0.5, 0.5), at = Vector3.new(0, 7, 1), color = C(90, 70, 50), mat = WOOD })
	local bell = add(f, b, { size = Vector3.new(3, 3.2, 3), at = Vector3.new(0, 5, 1), shape = Enum.PartType.Ball, color = C(205, 160, 60), mat = METAL, shine = 0.25 })
	add(f, b, { size = Vector3.new(0.6, 0.5, 0.6), at = Vector3.new(0, 6.6, 1), color = C(90, 70, 50), mat = WOOD }) -- what it hangs from
	add(f, b, { size = Vector3.new(3.6, 0.4, 3.6), at = Vector3.new(0, 3.6, 1), rot = UP, shape = Enum.PartType.Cylinder, color = C(205, 160, 60), mat = METAL })
	noisy(bell, "Big bell", Config.SOUNDS.bell, 3)
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
	add(f, b, { size = Vector3.new(1.5, 0.15, 0.15), at = Vector3.new(0, 2.92, 0), color = C(200, 170, 80), mat = METAL }) -- the arms
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
	noisy(scr, "Arcade machine", Config.SOUNDS.beep, 4)
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
	-- a rocking horse: curved rockers, four legs, body, saddle, neck, head,
	-- ears, eye, mane and tail
	local HORSE, DARKW, MANE = C(200, 150, 90), C(150, 90, 50), C(90, 55, 35)
	for _, z in ipairs({ -0.95, -0.25 }) do
		add(f, b, { size = Vector3.new(1.6, 0.2, 0.15), at = Vector3.new(0, 0.12, z), color = DARKW, mat = WOOD })
		add(f, b, { size = Vector3.new(1, 0.2, 0.15), at = Vector3.new(-1.2, 0.27, z), rot = CFrame.Angles(0, 0, math.rad(-20)), color = DARKW, mat = WOOD })
		add(f, b, { size = Vector3.new(1, 0.2, 0.15), at = Vector3.new(1.2, 0.27, z), rot = CFrame.Angles(0, 0, math.rad(20)), color = DARKW, mat = WOOD })
		for _, x in ipairs({ -0.8, 0.8 }) do
			add(f, b, { size = Vector3.new(0.22, 1.2, 0.22), at = Vector3.new(x, 0.8, z), color = HORSE, mat = WOOD })
		end
	end
	add(f, b, { size = Vector3.new(2.2, 0.9, 0.75), at = Vector3.new(0, 1.75, -0.6), color = HORSE, mat = WOOD })
	add(f, b, { size = Vector3.new(0.7, 0.12, 0.8), at = Vector3.new(-0.1, 2.25, -0.6), color = C(200, 40, 50) })
	add(f, b, { size = Vector3.new(0.55, 1.2, 0.5), at = Vector3.new(1.05, 2.5, -0.6), rot = CFrame.Angles(0, 0, math.rad(-25)), color = HORSE, mat = WOOD })
	add(f, b, { size = Vector3.new(1, 0.55, 0.5), at = Vector3.new(1.5, 3.05, -0.6), color = HORSE, mat = WOOD })
	for _, z in ipairs({ -0.75, -0.45 }) do
		add(f, b, { size = Vector3.new(0.14, 0.32, 0.12), at = Vector3.new(1.25, 3.42, z), color = HORSE, mat = WOOD })
	end
	add(f, b, { size = Vector3.new(0.1, 0.1, 0.52), at = Vector3.new(1.65, 3.15, -0.6), color = C(20, 20, 20) })
	add(f, b, { size = Vector3.new(0.14, 1.1, 0.2), at = Vector3.new(0.82, 2.7, -0.6), rot = CFrame.Angles(0, 0, math.rad(-25)), color = MANE })
	add(f, b, { size = Vector3.new(0.18, 0.8, 0.18), at = Vector3.new(-1.25, 1.65, -0.6), rot = CFrame.Angles(0, 0, math.rad(30)), color = MANE })
end }

PIECES.Easels = { size = Vector3.new(6, 6, 2), build = function(f, b)
	for i = -1, 1, 2 do
		add(f, b, { size = Vector3.new(0.2, 5, 0.2), at = Vector3.new(i * 1.8, 2.5, 1.5), color = C(150, 100, 60), mat = WOOD })
		-- two front legs and the ledge the picture stands on
		for _, s in ipairs({ -1, 1 }) do
			add(f, b, { size = Vector3.new(0.15, 4.4, 0.15), at = Vector3.new(i * 1.8 + s * 0.75, 2.2, 1.05), rot = CFrame.Angles(math.rad(-6), 0, math.rad(s * 10)), color = C(150, 100, 60), mat = WOOD })
		end
		add(f, b, { size = Vector3.new(2.7, 0.15, 0.45), at = Vector3.new(i * 1.8, 2.85, 1.2), color = C(150, 100, 60), mat = WOOD })
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
	add(f, b, { size = Vector3.new(4.6, 0.3, 1.4), at = Vector3.new(0, 2.6, 3.3), color = C(150, 100, 60), mat = WOOD })
	for i = -1, 1 do
		local col = CANDY[i + 3]
		add(f, b, { size = Vector3.new(0.7, 1, 0.5), at = Vector3.new(i * 1.4, 3.3, 3.3), color = col, mat = Enum.Material.Fabric })
		add(f, b, { size = Vector3.new(0.6, 0.6, 0.6), at = Vector3.new(i * 1.4, 4.1, 3.3), shape = Enum.PartType.Ball, color = C(250, 220, 200) })
	end
end }

PIECES.Crib = { size = Vector3.new(5, 4, 3), build = function(f, b)
	-- a cot on four posts: a mattress, bars front and back, rails along the top
	local WHITE = C(240, 240, 245)
	add(f, b, { size = Vector3.new(4.4, 0.3, 2.6), at = Vector3.new(0, 1.6, 1.8), color = WHITE })
	for _, z in ipairs({ 0.5, 3.1 }) do
		for i = 0, 6 do
			add(f, b, { size = Vector3.new(0.15, 2.4, 0.15), at = Vector3.new(-2.1 + i * 0.7, 2.4, z), color = WHITE })
		end
		add(f, b, { size = Vector3.new(4.6, 0.2, 0.2), at = Vector3.new(0, 3.6, z), color = WHITE })
		for _, x in ipairs({ -2.25, 2.25 }) do
			add(f, b, { size = Vector3.new(0.3, 3.8, 0.3), at = Vector3.new(x, 1.9, z), color = WHITE })
		end
	end
	plush(f, b * CFrame.new(0, 1.75, 2), 1.4, C(160, 110, 70), "bear")
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
	add(f, b, { size = Vector3.new(0.12, 2, 0.12), at = Vector3.new(0.8, 1, 1.2), color = C(150, 150, 160), mat = METAL }) -- the tom's stand
	add(f, b, { size = Vector3.new(0.1, 1.6, 1.6), at = Vector3.new(1.8, 3.6, 1.8), rot = UP, shape = Enum.PartType.Cylinder, color = C(220, 190, 80), mat = METAL })
	add(f, b, { size = Vector3.new(0.1, 3.55, 0.1), at = Vector3.new(1.8, 1.78, 1.8), color = C(150, 150, 160), mat = METAL }) -- the cymbal's stand
	-- a guitar on the wall
	add(f, b, { size = Vector3.new(1.6, 2, 0.4), at = Vector3.new(-1.5, 5, T / 2 - 0.4), shape = Enum.PartType.Ball, color = C(190, 110, 40), mat = WOOD })
	local neck = add(f, b, { size = Vector3.new(0.3, 2.6, 0.2), at = Vector3.new(-1.5, 7, T / 2 - 0.4), color = C(90, 60, 40), mat = WOOD })
	local _ = neck
	noisy(f:FindFirstChildWhichIsA("BasePart") or neck, "Drums", Config.SOUNDS.pop, 2)
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
	honey = { Enum.Material.SmoothPlastic, C(225, 165, 70) },
	tent = { Enum.Material.Fabric, C(160, 40, 60) },
	aqua = { Enum.Material.SmoothPlastic, C(40, 120, 140) },
	deep = { Enum.Material.SmoothPlastic, C(20, 40, 72) },
	ice = { Enum.Material.Ice, C(205, 230, 245) },
}

-- the floor that goes with each kind of wall (nil: keep the building's floor)
local FLOORS = {
	brick = { Enum.Material.Concrete, C(115, 115, 120) },
	steel = { Enum.Material.DiamondPlate, C(140, 145, 150) },
	tiles = { Enum.Material.CeramicTiles, C(232, 232, 230) },
	wood = { Enum.Material.WoodPlanks, C(125, 85, 52) },
	choc = { Enum.Material.SmoothPlastic, C(200, 140, 70) },
	gold = { Enum.Material.SmoothPlastic, C(225, 195, 100) },
	green = { Enum.Material.Carpet, C(50, 90, 60) },
	red = { Enum.Material.Carpet, C(120, 35, 45) },
	blue = { Enum.Material.Carpet, C(70, 90, 140) },
	teal = { Enum.Material.Carpet, C(40, 100, 105) },
	purple = { Enum.Material.Carpet, C(80, 55, 110) },
	grey = { Enum.Material.SmoothPlastic, C(165, 170, 175) },
	honey = { Enum.Material.SmoothPlastic, C(205, 150, 70) },
}

-- first match wins: words in the room's name -> its look (a 4th entry: only
-- in that building)
local LOOKS = {
	-- the Sunken Aquarium (only in the aquarium)
	{ { "entrance hall", "front doors", "great tank", "shark tunnel" }, "aqua", { "FishTank", "FishTank", "Porthole" }, "aquarium" },
	{ { "seahorse", "jellyfish", "kelp", "anglerfish den", "coral cave" }, "deep", { "JellyTank", "JellyTank", "Porthole" }, "aquarium" },
	{ { "keeper's office" }, "wood", { "FilingCabinets", "DivingGear", "Monitors" }, "aquarium" },
	{ { "gift shop" }, "aqua", { "ToyBox", "Plants" }, "aquarium" },
	{ { "cafe", "snack kiosk" }, "tiles", { "Trays", "Plants" }, "aquarium" },
	{ { "touch pools", "otter pool", "rock pool", "sea lion" }, "aqua", { "WaterPool", "WaterPool", "Plants" }, "aquarium" },
	{ { "submarine bay", "diving locker", "deep sea elevator" }, "steel", { "DivingGear", "Porthole", "Crates" }, "aquarium" },
	{ { "research lab" }, "tiles", { "Beakers", "Monitors", "FishTank" }, "aquarium" },
	{ { "whale skeleton" }, "deep", { "Porthole", "FishTank" }, "aquarium" },
	{ { "bubble vents", "pipe room", "pump" }, "steel", { "Pipes", "WaterTank" }, "aquarium" },
	{ { "penguin" }, "ice", { "Penguins", "Penguins" }, "aquarium" },
	{ { "feed store" }, "wood", { "Sacks", "Crates", "Sacks" }, "aquarium" },
	{ { "lighthouse", "water slide", "splash slide" }, "aqua", { "Porthole", "Plants" }, "aquarium" },
	-- the Creepy Carnival (only in the carnival)
	{ { "ticket booth", "main gate" }, "tent", { "TicketWindow", "Plants", "Crates" }, "carnival" },
	{ { "fortune teller" }, "purple", { "CrystalBall", "Candelabra", "Curtain" }, "carnival" },
	{ { "prize tent", "ring-toss", "duck pond" }, "tent", { "PrizeWall", "PrizeWall", "ToyBox" }, "carnival" },
	{ { "popcorn", "candy apple" }, "honey", { "Crates", "Sacks", "Trays" }, "carnival" },
	{ { "carousel" }, "purple", { "Plants", "Drums" }, "carnival" },
	{ { "hall of mirrors", "clown mirror", "laughing gallery" }, "grey", { "FunMirror", "FunMirror", "FunMirror" }, "carnival" },
	{ { "ringmaster" }, "red", { "FilingCabinets", "CoatRack", "Trunks" }, "carnival" },
	{ { "juggler", "the ring" }, "tent", { "Juggling", "Juggling", "Drums" }, "carnival" },
	{ { "costume wagon", "backstage" }, "pastel", { "CostumeRack", "CostumeRack", "Wardrobe" }, "carnival" },
	{ { "band stand" }, "red", { "Drums", "Drums" }, "carnival" },
	{ { "strongman" }, "brick", { "Weights", "Weights", "Crates" }, "carnival" },
	{ { "clown car", "cannon deck", "trapeze" }, "grey", { "Crates", "Trunks" }, "carnival" },
	{ { "tilted" }, "pastel", { "Tilted", "Tilted" }, "carnival" },
	{ { "bumper car" }, "grey", { "BumperCars", "BumperCars" }, "carnival" },
	{ { "rolling-barrel" }, "tent", { "RollingBarrel", "Crates" }, "carnival" },
	{ { "joke shop" }, "red", { "JokeShelf", "JokeShelf" }, "carnival" },
	{ { "ball pit", "slide tower" }, "pastel", { "ToyBox", "ToyBox" }, "carnival" },
	{ { "spinning room", "big wheel", "funhouse stairs" }, "purple", { "Plants" }, "carnival" },
	-- the Midnight School (only in the school)
	{ { "classroom", "detention" }, "teal", { "Blackboard", "SchoolDesks", "SchoolDesks" }, "school" },
	{ { "exam hall" }, "wood", { "SchoolDesks", "SchoolDesks", "Clocks" }, "school" },
	{ { "assembly hall" }, "wood", { "Trophies", "WaitingChairs", "WaitingChairs" }, "school" },
	{ { "hallway", "top corridor" }, "green", { "Lockers", "Lockers", "Trophies" }, "school" },
	{ { "front lobby", "trophy room" }, "wood", { "Trophies", "Trophies", "Plants" }, "school" },
	{ { "principal's office" }, "red", { "FilingCabinets", "Globe", "Blackboard" }, "school" },
	{ { "lost and found" }, "grey", { "CoatRack", "Crates", "PaperStacks" }, "school" },
	{ { "cafeteria" }, "tiles", { "Trays", "Trays", "Plants" }, "school" },
	{ { "computer room" }, "grey", { "Monitors", "Monitors", "SchoolDesks" }, "school" },
	{ { "art room" }, "pastel", { "Easels", "Easels", "ToyBox" }, "school" },
	{ { "restroom" }, "tiles", { "Bathroom", "Bathroom" }, "school" },
	{ { "caretaker" }, "brick", { "Crates", "Pipes", "CoatRack" }, "school" },
	{ { "bell room" }, "brick", { "BigBell", "Pipes" }, "school" },
	{ { "observatory" }, "purple", { "Telescope", "Globe" }, "school" },
	{ { "storage loft" }, "wood", { "DustSheets", "Crates", "Trunks" }, "school" },
	{ { "stairwell", "stairs" }, "grey", { "LiftDoors", "Plants" }, "hospital" },
	{ { "children's ward" }, "pastel", { "ToyBox", "IVStand", "Curtain", "ToyBox" } },
	{ { "vault entrance" }, "steel", { "Monitors", "GoldGumdrops", "VaultDoor" } },
	{ { "archive" }, "honey", { "FilingCabinets", "FilingCabinets", "HoneyDrips", "PaperStacks" } },
	{ { "ball pit" }, "lilac", { "GummyBear", "Lollipop", "JellyCube" } },
	{ { "slide" }, "pastel", { "Lollipop", "Sprinkles", "GummyBear" } },
	{ { "bounce room" }, "mint", { "JellyCube", "Lollipop", "Sprinkles" } },
	{ { "boiler" }, "brick", { "Boiler", "Pipes", "Generator" } },
	{ { "generator" }, "brick", { "Generator", "Pipes", "Crates" } },
	{ { "water tank" }, "brick", { "WaterTank", "Pipes", "Crates" } },
	{ { "conveyor" }, "steel", { "Conveyor", "Conveyor", "CandyMachine", "Pipes" } },
	{ { "factory floor" }, "steel", { "CandyMachine", "Conveyor", "Pipes", "CandyMachine" } },
	{ { "chocolate" }, "choc", { "ChocolateRiver", "Sacks" } },
	{ { "wrapper" }, "steel", { "Conveyor", "Crates", "CandyMachine" } },
	{ { "packing", "loading", "dock" }, "brick", { "Crates", "Crates", "Conveyor" } },
	{ { "taste lab" }, "lilac", { "Beakers", "CandyMachine", "Beakers" } },
	{ { "sugar" }, "pastel", { "Sacks", "Sacks", "Crates" } },
	{ { "locker" }, "blue", { "Lockers", "Lockers" } },
	{ { "taffy" }, "pastel", { "TaffyPuller", "TaffyPuller", "Sacks" } },
	{ { "sprinkle" }, "pastel", { "Sprinkles", "Sprinkles", "Lollipop" } },
	{ { "bear gallery" }, "lilac", { "GummyBear", "GummyBear", "GummyBear" } },
	{ { "gummy lobby", "lollipop" }, nil, { "Lollipop", "Lollipop", "GummyBear" } },
	{ { "candy kitchen" }, "tiles", { "Stove", "CandyMachine", "Trays" } },
	{ { "jelly pool" }, "mint", { "JellyCube", "JellyCube", "JellyCube", "JellyCube" } },
	{ { "jelly corridor", "wobble" }, "mint", { "JellyCube", "JellyCube", "JellyCube" } },
	{ { "jelly bank" }, "gold", { "GoldGumdrops", "Counter", "VaultDoor" } },
	{ { "gold gumdrop" }, "gold", { "GoldGumdrops", "GoldGumdrops", "GoldGumdrops" } },
	-- the Vault Door Hall's own vault door opens (Rooms.vault), so no extra one
	{ { "vault door hall" }, "steel", { "GoldGumdrops", "Monitors", "GoldGumdrops" } },
	{ { "vault" }, "steel", { "VaultDoor", "GoldGumdrops", "Monitors" } },
	{ { "gumball" }, "pastel", { "CandyMachine", "CandyMachine", "CandyMachine" } },
	{ { "sticky" }, "honey", { "Crates", "HoneyDrips", "Sacks" } },
	{ { "security" }, "steel", { "Monitors", "Monitors" } },
	-- hospital
	{ { "ambulance" }, "brick", { "Ambulance", "IVStand", "Crates" } },
	{ { "x-ray" }, "steel", { "XRay", "IVStand", "Monitors" } },
	{ { "ward" }, "mint", { "Curtain", "IVStand", "Curtain", "Monitors" } },
	{ { "waiting" }, nil, { "WaitingChairs", "WaitingChairs", "TV", "Plants" } },
	{ { "laundry" }, "tiles", { "WashingMachines", "WashingMachines" } },
	{ { "canteen", "cafeteria" }, "tiles", { "Trays", "Trays", "Plants" } },
	{ { "reception", "nurses' station" }, nil, { "Counter", "WaitingChairs", "Plants" } },
	{ { "day room", "quiet room", "staff room", "lounge" }, nil, { "Sofa", "TV", "Plants" } },
	{ { "science lab" }, "steel", { "Beakers", "Beakers", "Monitors" } },
	{ { "lab store", "lab storage" }, "steel", { "Crates", "Beakers", "PaperStacks" } },
	{ { "plant lab" }, "green", { "Plants", "Plants", "Beakers" } },
	{ { "radio" }, "steel", { "RadioDesk", "Monitors" } },
	{ { "lift", "elevator" }, "steel", { "LiftDoors", "WaitingChairs" } },
	{ { "pharmacy", "medicine" }, "tiles", { "Counter", "Beakers" } },
	{ { "records", "nurses' office" }, "grey", { "FilingCabinets", "FilingCabinets", "Monitors" } },
	{ { "supply" }, "grey", { "Crates", "Crates", "PaperStacks" } },
	{ { "main corridor", "lab entrance" }, nil, { "WaitingChairs", "IVStand", "Plants" } },
	-- party house
	-- the secret Basement
	{ { "wine cellar" }, "brick", { "Trunks", "Crates", "Sacks" } },
	{ { "pumpkin cellar" }, "brick", { "Sacks", "Crates", "Sacks" } },
	{ { "coal" }, "brick", { "Crates", "Sacks", "Pipes" } },
	{ { "workshop" }, "wood", { "Crates", "PaperStacks", "Trunks" } },
	{ { "cellar entrance" }, "brick", { "Crates", "CoatRack" } },
	{ { "old storage" }, "wood", { "DustSheets", "Crates", "Trunks" } },
	{ { "cellar stairs" }, "brick", { "Pipes", "Crates" } },
	{ { "parlour", "parlor" }, "red", { "Fireplace", "Armchair", "Armchair" } },
	{ { "library" }, "green", { "Globe", "Armchair", "Fireplace" } },
	{ { "study" }, "green", { "Globe", "Armchair", "PaperStacks" } },
	{ { "music" }, "purple", { "Drums", "Armchair" } },
	{ { "kitchen" }, "tiles", { "Stove", "Trays" } },
	{ { "dining" }, "red", { "Candelabra", "Candelabra", "Armchair" } },
	{ { "game room" }, "teal", { "Arcade", "Arcade", "Sofa" } },
	{ { "conservatory" }, "green", { "Plants", "Plants", "Plants" } },
	{ { "pantry" }, "wood", { "Sacks", "Crates", "Sacks" } },
	{ { "bath" }, "tiles", { "Bathroom", "Plants" } },
	{ { "clock" }, "wood", { "Clocks", "Clocks" } },
	{ { "trunk" }, "wood", { "Trunks", "Trunks", "DustSheets" } },
	{ { "dusty", "box room", "storage room" }, "wood", { "DustSheets", "Crates", "DustSheets" } },
	{ { "doll" }, "pastel", { "Dolls", "ToyBox", "Dolls" } },
	{ { "nursery", "playroom", "kids", "children" }, "pastel", { "ToyBox", "Wardrobe", "ToyBox" } },
	{ { "bedroom", "guest" }, "blue", { "Wardrobe", "Armchair", "Globe" } },
	{ { "gallery" }, "wood", { "Easels", "Easels", "Armchair" } },
	{ { "linen" }, "tiles", { "WashingMachines", "PaperStacks" } },
	{ { "stairwell", "stairs", "landing" }, "wood", { "CoatRack", "Plants" } },
	{ { "hall", "corridor" }, "wood", { "CoatRack", "Runner", "Plants" } },
}

local SOUNDS_BY_NAME = {
	{ { "boiler", "generator", "water tank" }, "hum" },
	{ { "conveyor", "factory", "wrapper", "packing", "taffy" }, "factory" },
	{ { "parlour", "parlor", "library" }, "fire" },
	{ { "clock" }, "tick" },
	{ { "trunk", "dusty", "box room", "storage room", "doll", "rooftop", "attic" }, "wind" },
	{ { "ward", "x-ray", "nurses", "records", "pharmacy", "medicine" }, "beep" },
	{ { "corridor", "waiting", "reception", "lift", "elevator", "lab", "canteen", "cafeteria" }, "buzz", "hospital" },
	{ { "chocolate", "jelly" }, "bubble" },
	{ { "bath", "laundry", "linen", "sticky", "archive", "cellar" }, "drip" },
}
-- effects: steam, dust, bubbles, sparkles, mist
local EFFECTS_BY_NAME = {
	{ { "boiler", "generator", "laundry" }, "steam" },
	{ { "trunk", "dusty", "box room", "clock", "doll", "storage", "coal", "workshop", "lost and found", "caretaker" }, "dust" },
	{ { "chocolate" }, "bubbles" },
	{ { "vault", "gold", "jelly bank" }, "sparkles" },
	{ { "jelly pool", "wobble" }, "mist" },
}
-- a room light's colour (and red warning lights in machine rooms)
local LIGHT_BY_LOOK = {
	brick = C(255, 120, 80), steel = C(200, 225, 255), tiles = C(230, 240, 255),
	wood = C(255, 200, 140), choc = C(255, 180, 120), gold = C(255, 215, 120),
	mint = C(170, 255, 210), lilac = C(220, 180, 255), pastel = C(255, 190, 220),
	green = C(255, 210, 150), red = C(255, 180, 130), blue = C(200, 210, 255),
	teal = C(160, 240, 255), purple = C(210, 160, 255), grey = C(220, 235, 255), honey = C(255, 200, 110),
}

local function firstMatch(list, name, theme)
	local n = string.lower(name)
	for _, l in ipairs(list) do
		for _, w in ipairs(l[1]) do
			if string.find(n, w, 1, true) and (l[3] == nil or l[3] == theme) then
				return l[2]
			end
		end
	end
	return nil
end

local function effect(folder, f, kind)
	local holder = Instance.new("Part")
	holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
	holder.Transparency = 1
	holder.Name = "RoomEffect"
	local w, d = (f.x1 - f.x0 + 1) * T, (f.y1 - f.y0 + 1) * T
	holder.Size = Vector3.new(w * 0.8, kind == "mist" and 1 or 6, d * 0.8)
	holder.Position = Vector3.new((f.x0 + f.x1 + 1) / 2 * T, kind == "mist" and 1 or (kind == "steam" and 7 or 5), (f.y0 + f.y1 + 1) / 2 * T)
	holder.Parent = folder
	local e = Instance.new("ParticleEmitter")
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.LightInfluence = 0.6
	if kind == "steam" then
		e.Rate, e.Lifetime, e.Speed = 4, NumberRange.new(2, 4), NumberRange.new(1, 2)
		e.Size = NumberSequence.new(1.5, 4)
		e.Transparency = NumberSequence.new(0.6, 1)
		e.Color = ColorSequence.new(Color3.fromRGB(235, 235, 235))
	elseif kind == "dust" then
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Rate, e.Lifetime, e.Speed = 6, NumberRange.new(5, 8), NumberRange.new(0.1, 0.4)
		e.Size = NumberSequence.new(0.15)
		e.Transparency = NumberSequence.new(0.4, 1)
		e.Color = ColorSequence.new(Color3.fromRGB(220, 210, 190))
	elseif kind == "bubbles" then
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Rate, e.Lifetime, e.Speed = 5, NumberRange.new(1, 2), NumberRange.new(1, 2)
		e.Size = NumberSequence.new(0.4, 0)
		e.Color = ColorSequence.new(Color3.fromRGB(140, 85, 45))
	elseif kind == "sparkles" then
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Rate, e.Lifetime, e.Speed = 6, NumberRange.new(1, 2), NumberRange.new(0.2, 0.6)
		e.Size = NumberSequence.new(0.5, 0)
		e.LightEmission = 1
		e.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120))
	else -- mist
		e.Rate, e.Lifetime, e.Speed = 3, NumberRange.new(4, 6), NumberRange.new(0.2, 0.5)
		e.Size = NumberSequence.new(3, 6)
		e.Transparency = NumberSequence.new(0.75, 1)
		e.Color = ColorSequence.new(Color3.fromRGB(200, 255, 230))
	end
	e.Parent = holder
end

local function ambience(folder, f, id)
	if not id or id <= 0 then
		return
	end
	local holder = Instance.new("Part")
	holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.Name = "RoomSound"
	holder.Position = Vector3.new((f.x0 + f.x1 + 1) / 2 * T, 6, (f.y0 + f.y1 + 1) / 2 * T)
	holder.Parent = folder
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Looped = true
	s.Volume = 0.3
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 6
	s.RollOffMaxDistance = math.max(f.x1 - f.x0, f.y1 - f.y0) * T * 0.75 + 10
	s.SoundGroup = Sfx.group()
	s.Parent = holder
	s:Play()
end

-- a sign above every doorway, on both sides, naming the room it leads to
local function doorSigns(folder, map)
	local function roomAt(x, y)
		for _, f in ipairs(map.floors) do
			if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
				return f
			end
		end
		return nil
	end
	for y = 1, map.h - 2 do
		for x = 1, map.w - 2 do
			local c = cell(map, x, y)
			if c == "." or c == "L" then
				local ns = cell(map, x - 1, y) == "#" and cell(map, x + 1, y) == "#"
				local ew = cell(map, x, y - 1) == "#" and cell(map, x, y + 1) == "#"
				if ns or ew then
					local a = ns and roomAt(x, y - 1) or roomAt(x - 1, y)
					local b2 = ns and roomAt(x, y + 1) or roomAt(x + 1, y)
					local here = roomAt(x, y)
					if a and b2 and a.name ~= b2.name and not here then
						local top = (a.tall and b2.tall) and HT or H
						local y0 = c == "L" and 13.4 or 10.6
						if y0 + 1.4 <= top then
							for side = -1, 1, 2 do
								local beyond = side < 0 and b2 or a
								local pos = ns and Vector3.new(x * T + T / 2, y0 + 0.7, (side < 0 and y * T or (y + 1) * T) + side * 0.07)
									or Vector3.new((side < 0 and x * T or (x + 1) * T) + side * 0.07, y0 + 0.7, y * T + T / 2)
								local board = Instance.new("Part")
								board.Anchored, board.CanCollide, board.CanQuery, board.CanTouch = true, false, false, false
								board.Name = "DoorSign"
								board.Size = ns and Vector3.new(T * 0.85, 1.3, 0.1) or Vector3.new(0.1, 1.3, T * 0.85)
								board.Position = pos
								board.Color = C(40, 28, 46)
								board.Parent = folder
								local sg = Instance.new("SurfaceGui")
								sg.Face = ns and (side < 0 and Enum.NormalId.Front or Enum.NormalId.Back) or (side < 0 and Enum.NormalId.Left or Enum.NormalId.Right)
								sg.CanvasSize = Vector2.new(400, 60)
								sg.LightInfluence = 0
								sg.Parent = board
								local t = Instance.new("TextLabel")
								t.Size = UDim2.fromScale(1, 1)
								t.BackgroundTransparency = 1
								t.TextScaled = true
								t.Font = Enum.Font.FredokaOne
								t.TextColor3 = C(255, 210, 63)
								t.Text = beyond.name
								t.Parent = sg
							end
						end
					end
				end
			end
		end
	end
end

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
local function lineWalls(folder, map, f, look, openings)
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
				wall = cell(map, cx, cy) == "#" and not (openings and openings[cx .. "," .. cy])
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
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Sound") then
			d:Destroy() -- (a prop's own sound may not be allowed in this game)
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

-- ---------------------------------------------------------------- the house's edges
local function onEdge(map, x, y)
	return x == 0 or y == 0 or x == map.w - 1 or y == map.h - 1
end
local DIRS = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }

-- tiles anyone can reach from the start without opening a door (no store rooms)
local function openTiles(map)
	local seen, queue = {}, {}
	for _, s in ipairs(map.start) do
		local k = s[1] .. "," .. s[2]
		if not seen[k] then
			seen[k] = true
			table.insert(queue, { s[1], s[2] })
		end
	end
	local i = 1
	while i <= #queue do
		local x, y = queue[i][1], queue[i][2]
		i += 1
		for _, d in ipairs(DIRS) do
			local nx, ny = x + d[1], y + d[2]
			local k = nx .. "," .. ny
			if not seen[k] and cell(map, nx, ny) == "." then
				seen[k] = true
				table.insert(queue, { nx, ny })
			end
		end
	end
	return seen
end

-- the wall part built for tile (wx, wy), if it is a plain wall
local function wallPart(world, wx, wy)
	local p = Vector3.new(wx * T + T / 2, 0, wy * T + T / 2)
	for _, c in ipairs(world.root:GetChildren()) do
		if c:IsA("BasePart") and c.Name == "Wall" and math.abs(c.Position.X - p.X) < 0.1 and math.abs(c.Position.Z - p.Z) < 0.1 then
			return c
		end
	end
	return nil
end

-- ---------------------------------------------------------------- the vault door
-- In the Jelly Vault's Vault Door Hall a giant round vault door sits in the
-- outer wall. Hold E on its wheel: it spins, the door swings open, and a
-- little vault behind it holds a treasure chest (points for everyone and a
-- free clue - world.onVaultTreasure in Main).
local function buildVault(folder, world, map, f, busy, openings)
	-- a tile against the house's outer wall, the wall either side of it solid
	local best, bestD, bestDir
	local cx, cy = (f.x0 + f.x1) / 2, (f.y0 + f.y1) / 2
	for y = f.y0, f.y1 do
		for x = f.x0, f.x1 do
			if cell(map, x, y) == "." and not busy[x .. "," .. y] then
				for _, d in ipairs(DIRS) do
					local wx, wy = x + d[1], y + d[2]
					local ax, ay = d[2] ~= 0 and 1 or 0, d[1] ~= 0 and 1 or 0 -- along the wall
					if onEdge(map, wx, wy) and cell(map, wx, wy) == "#" and cell(map, wx - ax, wy - ay) == "#" and cell(map, wx + ax, wy + ay) == "#"
						and not (world.wallUsed and world.wallUsed[wx .. "," .. wy]) and wallPart(world, wx, wy) then
						local dist = math.abs(x - cx) + math.abs(y - cy)
						if not best or dist < bestD then
							best, bestD, bestDir = { x, y }, dist, d
						end
					end
				end
			end
		end
	end
	if not best then
		return false
	end
	local x, y, d = best[1], best[2], bestDir
	local wx, wy = x + d[1], y + d[2]
	busy[x .. "," .. y] = true
	openings[wx .. "," .. wy] = true
	world.wallUsed = world.wallUsed or {}
	world.wallUsed[wx .. "," .. wy] = true
	local dirV = Vector3.new(d[1], 0, d[2]) -- from the room into the wall
	local centre = Vector3.new(wx * T + T / 2, 0, wy * T + T / 2)
	-- the wall becomes a thin back wall, a lintel over a 10-stud opening and a floor
	local wall = wallPart(world, wx, wy)
	local h = wall.Size.Y
	local across = d[1] ~= 0 -- the wall runs along Z
	local function slab(size, pos)
		local p = wall:Clone()
		p.Size = across and Vector3.new(size.Z, size.Y, size.X) or size
		p.Position = pos
		p.Name = "VaultWall"
		p.Parent = world.root
		return p
	end
	slab(Vector3.new(T, h, 1), centre + dirV * (T / 2 - 0.5) + Vector3.new(0, h / 2, 0))
	slab(Vector3.new(T, h - 10, T - 1), centre - dirV * 0.5 + Vector3.new(0, 10 + (h - 10) / 2, 0))
	local floor = slab(Vector3.new(T, 1, T - 1), centre - dirV * 0.5 + Vector3.new(0, -0.5, 0))
	floor.Material, floor.Color = Enum.Material.DiamondPlate, C(150, 150, 160)
	wall:Destroy()
	-- the vault: steel walls inside, the treasure, a warm gold light
	local face = centre - dirV * (T / 2) -- where the wall meets the room
	local base = CFrame.lookAt(face, face - dirV) -- looking into the room
	local inside = CFrame.lookAt(centre - dirV * 0.5, centre - dirV * 0.5 - dirV)
	for _, sx in ipairs({ -1, 1 }) do
		add(folder, inside, { size = Vector3.new(0.2, 10, T - 1), at = Vector3.new(sx * (T / 2 - 0.15), 5, 0), color = C(130, 135, 145), mat = Enum.Material.DiamondPlate })
	end
	add(folder, inside, { size = Vector3.new(T, 10, 0.2), at = Vector3.new(0, 5, T / 2 - 0.65), color = C(130, 135, 145), mat = Enum.Material.DiamondPlate })
	local chestBase = inside * CFrame.new(0, 0, 1)
	local chest = add(folder, chestBase, { name = "TreasureChest", size = Vector3.new(3.2, 2, 2), at = Vector3.new(0, 1, 0), color = C(130, 80, 40), mat = WOOD })
	local lid = add(folder, chestBase, { size = Vector3.new(3.3, 0.6, 2.1), at = Vector3.new(0, 2.3, 0), color = C(200, 160, 60), mat = METAL })
	local gold = {}
	for i = 1, 14 do
		table.insert(gold, add(folder, chestBase, { size = Vector3.new(0.9, 0.9, 0.9), at = Vector3.new(math.cos(i * 1.3) * (0.6 + (i % 3) * 0.5), 0.45 + (i > 9 and 0.8 or 0), -1.8 + math.sin(i * 1.3) * 0.6), shape = Enum.PartType.Ball, color = C(255, 200, 60), mat = Enum.Material.Foil, shine = 0.2 }))
	end
	glow(chest, C(255, 210, 90), 14, 1.2)
	-- the door: a big round steel door with a wheel, hinged on its left
	local doorParts, wheelParts = {}, {}
	local discCF = CFrame.new(0, 5, -0.45) * CFrame.Angles(0, math.rad(90), 0)
	table.insert(doorParts, add(folder, base, { name = "VaultDoorDisc", size = Vector3.new(0.9, 9.4, 9.4), at = discCF.Position, rot = discCF.Rotation, shape = Enum.PartType.Cylinder, color = C(200, 170, 80), mat = METAL, shine = 0.1 }))
	doorParts[1].CanCollide = true
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		table.insert(doorParts, add(folder, base, { size = Vector3.new(0.5, 0.5, 0.3), at = Vector3.new(math.cos(a) * 3.9, 5 + math.sin(a) * 3.9, -0.95), color = C(120, 100, 50), mat = METAL, shape = Enum.PartType.Ball }))
	end
	for k = 0, 5 do
		table.insert(wheelParts, add(folder, base, { size = Vector3.new(3.6, 0.35, 0.35), at = Vector3.new(0, 5, -1.35), rot = CFrame.Angles(0, 0, math.rad(k * 30)), color = C(90, 80, 70), mat = METAL }))
	end
	local hub = add(folder, base, { name = "VaultWheel", size = Vector3.new(1.1, 1.1, 1.1), at = Vector3.new(0, 5, -1.4), shape = Enum.PartType.Ball, color = C(90, 80, 70), mat = METAL })
	hub.CanQuery = true
	table.insert(wheelParts, hub)
	local sign = add(folder, base, { size = Vector3.new(4, 1, 0.1), at = Vector3.new(0, 10.6, -0.1), color = C(40, 28, 46) })
	label(sign, Enum.NormalId.Front, "\u{1F512} VAULT", C(255, 210, 63))
	for _, p in ipairs(wheelParts) do
		table.insert(doorParts, p)
	end
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Turn the wheel"
	pp.ObjectText = "Vault door"
	pp.HoldDuration = Config.VAULT.hold
	pp.MaxActivationDistance = 9
	pp.RequiresLineOfSight = false
	pp.Parent = hub
	local axisCF = base * CFrame.new(0, 5, -1.35) -- the wheel turns about the door's middle
	local hinge = base * CFrame.new(-4.7, 0, -0.45)
	pp.Triggered:Connect(function(plr)
		if not (world.onVaultTurn and world.onVaultTurn(plr, hub.Position)) then
			return
		end
		pp.Enabled = false
		local relWheel, relDoor = {}, {}
		for i, p in ipairs(wheelParts) do
			relWheel[i] = axisCF:ToObjectSpace(p.CFrame)
		end
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://" .. Config.SOUNDS.unhide
		s.Volume = 1.5
		s.PlaybackSpeed = 0.6
		s.SoundGroup = Sfx.group()
		s.Parent = hub
		s:Play()
		game:GetService("Debris"):AddItem(s, 3)
		for step = 1, 30 do
			for i, p in ipairs(wheelParts) do
				p.CFrame = axisCF * CFrame.Angles(0, 0, step / 30 * math.pi * 2) * relWheel[i]
			end
			task.wait(0.04)
		end
		for i, p in ipairs(doorParts) do
			relDoor[i] = hinge:ToObjectSpace(p.CFrame)
			p.CanCollide = false
		end
		for step = 1, 30 do
			local a = math.rad(100) * (1 - (1 - step / 30) ^ 2)
			for i, p in ipairs(doorParts) do
				p.CFrame = hinge * CFrame.Angles(0, a, 0) * relDoor[i]
			end
			task.wait(0.04)
		end
		-- the treasure
		local grab = Instance.new("ProximityPrompt")
		grab.ActionText = "Grab the treasure"
		grab.ObjectText = "Vault treasure"
		grab.HoldDuration = 0.5
		grab.MaxActivationDistance = 9
		grab.RequiresLineOfSight = false
		grab.Parent = chest
		grab.Triggered:Connect(function(p2)
			if not (world.onVaultTreasure and world.onVaultTreasure(p2, chest.Position)) then
				return
			end
			grab:Destroy()
			for _, g in ipairs(gold) do
				TweenService:Create(g, TweenInfo.new(0.6), { Transparency = 1, Position = g.Position + Vector3.new(0, 3, 0) }):Play()
			end
			TweenService:Create(lid, TweenInfo.new(0.4), { CFrame = lid.CFrame * CFrame.new(0, 0.6, 0.9) * CFrame.Angles(math.rad(-80), 0, 0) }):Play()
		end)
	end)
	return true
end

-- ---------------------------------------------------------------- the laundry chute
-- A one-way slide from the Laundry / Linen Room down into a laundry basket
-- in the room furthest away on the same side of the locked doors (Main moves
-- the player; the host can't follow).
local function buildChute(folder, world, map, busy, open)
	local from, kind
	for _, f in ipairs(map.floors) do
		local n = string.lower(f.name)
		if not from and (string.find(n, "laundry", 1, true) or string.find(n, "linen", 1, true)) then
			from, kind = f, "laundry"
		elseif not from and string.find(n, "cannon", 1, true) then
			from, kind = f, "cannon"
		elseif not from and (string.find(n, "slide tower", 1, true) or string.find(n, "splash slide", 1, true)) then
			from, kind = f, "slide"
		elseif not from and string.find(n, "pipe room", 1, true) then
			from, kind = f, "pipe"
		end
	end
	if not from then
		return
	end
	-- a free tile against a wall (h), or anywhere free
	local function spot(f, needWall)
		local cx, cy = (f.x0 + f.x1) / 2, (f.y0 + f.y1) / 2
		local best, bestD, bestDir
		for y = f.y0, f.y1 do
			for x = f.x0, f.x1 do
				if cell(map, x, y) == "." and open[x .. "," .. y] and not busy[x .. "," .. y] then
					local dir
					for _, d in ipairs(DIRS) do
						if not dir and cell(map, x + d[1], y + d[2]) == "#" then
							dir = d
						end
					end
					if dir or not needWall then
						local dist = math.abs(x - cx) + math.abs(y - cy)
						if not best or dist < bestD then
							best, bestD, bestDir = { x, y }, dist, dir
						end
					end
				end
			end
		end
		return best, bestDir
	end
	local a, aDir = spot(from, true)
	if not a then
		return
	end
	-- the landing: the room furthest away that anyone can walk to
	local to, toDist
	local fx, fy = (from.x0 + from.x1) / 2, (from.y0 + from.y1) / 2
	for _, f in ipairs(map.floors) do
		if f ~= from then
			local b = spot(f, false)
			if b then
				local dist = math.abs((f.x0 + f.x1) / 2 - fx) + math.abs((f.y0 + f.y1) / 2 - fy)
				if not to or dist > toDist then
					to, toDist = f, dist
				end
			end
		end
	end
	if not to then
		return
	end
	local b = spot(to, true) or spot(to, false)
	busy[a[1] .. "," .. a[2]] = true
	busy[b[1] .. "," .. b[2]] = true
	-- the hatch in the wall: a steel door with a chute sign
	local centre = at(a[1], a[2])
	local wallDir = Vector3.new(aDir[1], 0, aDir[2])
	local base = CFrame.lookAt(centre, centre - wallDir)
	local hatch
	if kind == "cannon" then
		-- the human cannon: a big striped barrel pointing up at the tent roof
		add(folder, base, { size = Vector3.new(3, 2, 4), at = Vector3.new(0, 1, T / 2 - 2.4), color = C(120, 80, 50), mat = WOOD })
		for _, wx in ipairs({ -1.7, 1.7 }) do
			add(folder, base, { size = Vector3.new(0.5, 3, 3), at = Vector3.new(wx, 1.5, T / 2 - 2.4), shape = Enum.PartType.Cylinder, color = C(200, 40, 60) })
		end
		hatch = add(folder, base, { name = "ChuteHatch", size = Vector3.new(6, 2.4, 2.4), at = Vector3.new(0, 4, T / 2 - 2.6), rot = CFrame.Angles(0, math.rad(90), math.rad(55)), shape = Enum.PartType.Cylinder, color = C(60, 70, 160), mat = METAL, shine = 0.1 })
		for i = -1, 1 do
			add(folder, base, { size = Vector3.new(0.4, 2.6, 2.6), at = Vector3.new(0, 4 + i * 1.4 * math.sin(math.rad(55)), T / 2 - 2.6 - i * 1.4 * math.cos(math.rad(55))), rot = CFrame.Angles(0, math.rad(90), math.rad(55)), shape = Enum.PartType.Cylinder, color = C(255, 210, 63), mat = Enum.Material.Foil })
		end
		label(add(folder, base, { size = Vector3.new(4.4, 0.9, 0.1), at = Vector3.new(0, 7.6, T / 2 - 0.1), color = C(40, 28, 46) }), Enum.NormalId.Front, "\u{1F4A5} HUMAN CANNON", C(255, 210, 63))
	else
		add(folder, base, { size = Vector3.new(3.6, 3.6, 0.3), at = Vector3.new(0, 3.2, T / 2 - 0.15), color = kind == "slide" and C(255, 200, 40) or C(110, 115, 125), mat = kind == "slide" and Enum.Material.SmoothPlastic or METAL })
		hatch = add(folder, base, { name = "ChuteHatch", size = Vector3.new(3, 3, 0.2), at = Vector3.new(0, 3.2, T / 2 - 0.35), color = kind == "slide" and C(80, 170, 230) or C(160, 165, 175), mat = kind == "slide" and Enum.Material.SmoothPlastic or METAL, shine = 0.1 })
		add(folder, base, { size = Vector3.new(1.2, 0.3, 0.3), at = Vector3.new(0, 2.2, T / 2 - 0.5), color = C(60, 60, 65), mat = METAL })
		label(add(folder, base, { size = Vector3.new(3.6, 0.9, 0.1), at = Vector3.new(0, 5.6, T / 2 - 0.1), color = C(40, 28, 46) }), Enum.NormalId.Front, kind == "slide" and "TWISTY SLIDE \u{2193}" or kind == "pipe" and "WATER PIPE \u{2193}" or "LAUNDRY CHUTE \u{2193}", C(255, 210, 63))
	end
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = kind == "cannon" and "Climb in!" or "Slide down"
	pp.ObjectText = (kind == "cannon" and "Human cannon" or kind == "slide" and "Twisty slide" or kind == "pipe" and "Water pipe" or "Laundry chute") .. " (to the " .. to.name .. ")"
	pp.HoldDuration = 0.4
	pp.MaxActivationDistance = 8
	pp.RequiresLineOfSight = false
	pp.Parent = hatch
	-- the landing: a big basket of towels (a safety net for the cannon, a heap of balls for the slide)
	local land = at(b[1], b[2])
	local basket = CFrame.new(land)
	if kind == "cannon" then
		add(folder, basket, { size = Vector3.new(0.6, 5.4, 5.4), at = Vector3.new(0, 1.4, 0), rot = UP, shape = Enum.PartType.Cylinder, color = C(200, 40, 60) })
		add(folder, basket, { size = Vector3.new(0.2, 4.8, 4.8), at = Vector3.new(0, 1.6, 0), rot = UP, shape = Enum.PartType.Cylinder, color = C(250, 240, 225), mat = Enum.Material.Fabric })
		for k = 0, 3 do
			local ang = k * math.pi / 2 + math.pi / 4
			add(folder, basket, { size = Vector3.new(0.3, 1.3, 0.3), at = Vector3.new(math.cos(ang) * 2.3, 0.6, math.sin(ang) * 2.3), color = C(150, 150, 160), mat = METAL })
		end
	else
		add(folder, basket, { size = Vector3.new(1.4, 4.2, 4.2), at = Vector3.new(0, 0.7, 0), rot = UP, shape = Enum.PartType.Cylinder, color = kind == "slide" and C(80, 170, 230) or C(190, 160, 110), mat = kind == "slide" and Enum.Material.SmoothPlastic or Enum.Material.Fabric })
		for i = 1, 4 do
			add(folder, basket, { size = kind == "slide" and Vector3.new(1, 1, 1) or Vector3.new(1.6, 0.5, 1.2), shape = kind == "slide" and Enum.PartType.Ball or nil, at = Vector3.new(math.cos(i * 1.6) * 0.9, 1.5 + (i % 2) * 0.2, math.sin(i * 1.6) * 0.9), rot = CFrame.Angles(0, i, 0), color = ({ C(150, 200, 235), C(250, 250, 250), C(255, 190, 210), C(200, 240, 170) })[i], mat = kind == "slide" and Enum.Material.SmoothPlastic or Enum.Material.Fabric })
		end
	end
	local goText = kind == "cannon" and "3... 2... 1... BOOM! You fly out of the cannon..." or kind == "slide" and "Wheee! Down the twisty slide..." or kind == "pipe" and "Whoosh! Down the water pipe..." or "Wheee! Down the laundry chute..."
	local landText = kind == "cannon" and "You bounced into the safety net in the " .. to.name .. "!" or kind == "slide" and "You shot out into a heap of balls in the " .. to.name .. "!" or kind == "pipe" and "SPLASH! You shot out into a pool in the " .. to.name .. "!" or "You landed in the laundry basket in the " .. to.name .. "!"
	world.chute = { prompt = pp, from = hatch.Position, to = land, toRoom = to.name, kind = kind, goText = goText, landText = landText }
end

-- ---------------------------------------------------------------- windows
-- Windows on the house's outer walls looking out on a moonlit night (a
-- painted view, so nothing outside needs building): stars, the moon, hills
-- and trees (candy clouds at the Gummy Bounce House, town lights at the
-- hospital). One soft beam of moonlight per room.
local NO_WINDOWS = { "vault", "bank", "security", "boiler", "generator", "water tank", "lift", "elevator lobby", "x-ray", "store", "lab storage", "coal room", "sugar room", "cupboard", "closet", "archive", "locker" }
local function paintView(sg, theme, seed)
	local rng = Random.new(seed)
	local sky = Instance.new("Frame")
	sky.Size = UDim2.fromScale(1, 1)
	sky.BorderSizePixel = 0
	sky.BackgroundColor3 = Color3.new(1, 1, 1)
	sky.Parent = sg
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = theme == "gummy" and ColorSequence.new(C(70, 40, 110), C(230, 130, 190)) or ColorSequence.new(C(8, 12, 40), C(60, 50, 110))
	grad.Parent = sky
	local function blob(x, y, w, h, col, alpha, round)
		local b = Instance.new("Frame")
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.fromScale(x, y)
		b.Size = UDim2.fromScale(w, h)
		b.BackgroundColor3 = col
		b.BackgroundTransparency = alpha or 0
		b.BorderSizePixel = 0
		b.Parent = sky
		if round then
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(round, 0)
			c.Parent = b
		end
		return b
	end
	for _ = 1, 18 do
		local s = rng:NextNumber(0.008, 0.018)
		blob(rng:NextNumber(0.03, 0.97), rng:NextNumber(0.03, 0.55), s, s, C(255, 255, 240), rng:NextNumber(0, 0.5), 0.5)
	end
	local mx, my = rng:NextNumber(0.25, 0.75), rng:NextNumber(0.18, 0.3)
	blob(mx, my, 0.34, 0.34, C(255, 250, 220), 0.85, 0.5)
	blob(mx, my, 0.2, 0.2, C(255, 248, 215), 0, 0.5)
	blob(mx + 0.04, my - 0.03, 0.05, 0.05, C(230, 225, 195), 0, 0.5)
	if Config.HALLOWEEN then
		local bat = Instance.new("TextLabel")
		bat.BackgroundTransparency = 1
		bat.AnchorPoint = Vector2.new(0.5, 0.5)
		bat.Position = UDim2.fromScale(mx + 0.18, my + 0.12)
		bat.Size = UDim2.fromScale(0.12, 0.12)
		bat.TextScaled = true
		bat.Text = "\u{1F987}"
		bat.Parent = sky
	end
	if theme == "gummy" then
		for i = 1, 3 do
			local cx, cy = rng:NextNumber(0.15, 0.85), rng:NextNumber(0.5, 0.7)
			for k = -1, 1 do
				blob(cx + k * 0.08, cy - (k == 0 and 0.03 or 0), 0.16, 0.12, i % 2 == 0 and C(255, 200, 230) or C(250, 240, 255), 0.1, 0.5)
			end
		end
		blob(0.5, 0.95, 1.2, 0.25, C(120, 70, 140), 0, 0.5)
	else
		-- hills and the garden's trees, black against the sky
		blob(0.25, 1.0, 0.9, 0.42, C(12, 14, 26), 0, 0.5)
		blob(0.8, 1.02, 0.9, 0.36, C(18, 20, 34), 0, 0.5)
		for _ = 1, 3 do
			local tx = rng:NextNumber(0.08, 0.92)
			blob(tx, 0.82, 0.03, 0.2, C(8, 8, 16), 0)
			blob(tx, 0.68, 0.14, 0.18, C(8, 8, 16), 0, 0.5)
		end
		if theme == "hospital" then
			for _ = 1, 10 do
				blob(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.8, 0.92), 0.012, 0.012, C(255, 220, 120), 0, 0.5)
			end
		end
	end
end

-- ---------------------------------------------------------------- posters
-- The building's two posters (Config.POSTERS), framed, high on inside walls
-- (the outside walls have the windows): only where the floor in front of the
-- wall is free (no furniture against it), never beside the invitation or the
-- painted wall, one per room, up to perFloor a floor.
local function buildPosters(folder, map, busy)
	local P = Config.POSTERS
	local ids = P and P[map.theme or "party"]
	if not ids or (ids[1] or 0) <= 0 then
		return
	end
	local wallObj = {}
	for _, o in ipairs(map.objects or {}) do
		if o.kind == "invite" or o.kind == "uv" then
			for dx = -1, 1 do
				wallObj[(o.x + dx) .. "," .. o.y] = true
			end
		end
	end
	local rooms = table.clone(map.floors)
	for i = #rooms, 2, -1 do
		local j = math.random(1, i)
		rooms[i], rooms[j] = rooms[j], rooms[i]
	end
	local hung = 0
	for _, f in ipairs(rooms) do
		if hung >= (P.perFloor or 4) then
			break
		end
		local spots = {}
		for y = f.y0, f.y1 do
			for x = f.x0, f.x1 do
				local wx, wy = x, y - 1 -- the wall north of this floor tile
				if cell(map, x, y) == "." and not busy[x .. "," .. y] and cell(map, wx, wy) == "#" and not onEdge(map, wx, wy)
					and not wallObj[wx .. "," .. wy] then
					table.insert(spots, { x, y })
				end
			end
		end
		if #spots > 0 then
			local s = spots[math.random(1, #spots)]
			busy[s[1] .. "," .. s[2] .. ",poster"] = true
			hung += 1
			local id = ids[(hung - 1) % #ids + 1]
			if (id or 0) <= 0 then
				id = ids[1]
			end
			-- on the wall's south face, facing into the room (+Z)
			local wall = at(s[1], s[2] - 1)
			local cf = CFrame.new(wall + Vector3.new(0, 8.4, T / 2 + 0.12))
			local frameP = add(folder, cf, { name = "PosterFrame", size = Vector3.new(3.7, 5.3, 0.16), color = C(60, 38, 28), mat = WOOD })
			local _ = frameP
			local poster = add(folder, cf * CFrame.new(0, 0, 0.1), { name = "Poster", size = Vector3.new(3.3, 4.9, 0.05), color = C(20, 15, 20) })
			local d = Instance.new("Decal")
			d.Face = Enum.NormalId.Back
			d.Texture = "rbxassetid://" .. id
			d.Parent = poster
		end
	end
end

local function buildWindows(folder, world, map, busy, pieceAt)
	if string.find(string.lower(map.name or ""), "basement", 1, true) then
		return -- under the ground: no windows
	end
	local objAt = {}
	for _, o in ipairs(map.objects) do
		objAt[o.x .. "," .. o.y] = true
	end
	local theme = map.theme or "party"
	for r, f in ipairs(map.floors) do
		local n = string.lower(f.name)
		local skip = false
		for _, w in ipairs(NO_WINDOWS) do
			if string.find(n, w, 1, true) then
				skip = true
			end
		end
		local made, lit, last = 0, false, nil
		if not skip then
			for y = f.y0, f.y1 do
				for x = f.x0, f.x1 do
					local corner = (x == f.x0 or x == f.x1) and (y == f.y0 or y == f.y1)
					if made < (Config.WINDOWS.perRoom or 2) and not corner and cell(map, x, y) == "." and not busy[x .. "," .. y] and not pieceAt[x .. "," .. y] and not objAt[x .. "," .. y] then
						for _, d in ipairs(DIRS) do
							local wx, wy = x + d[1], y + d[2]
							local ax, ay = d[2] ~= 0 and 1 or 0, d[1] ~= 0 and 1 or 0
							local key = wx .. "," .. wy
							local farEnough = not last or math.abs(x - last[1]) + math.abs(y - last[2]) >= 3
							if made < (Config.WINDOWS.perRoom or 2) and farEnough and onEdge(map, wx, wy) and cell(map, wx, wy) == "#"
								and cell(map, wx - ax, wy - ay) == "#" and cell(map, wx + ax, wy + ay) == "#"
								and not (world.wallUsed and world.wallUsed[key]) and not objAt[key] then
								made += 1
								last = { x, y }
								world.wallUsed = world.wallUsed or {}
								world.wallUsed[key] = true
								local face = at(x, y) + Vector3.new(d[1], 0, d[2]) * (T / 2)
								local base = CFrame.lookAt(face, face - Vector3.new(d[1], 0, d[2]))
								local wood = theme == "hospital" and C(235, 238, 240) or theme == "gummy" and C(255, 170, 210) or C(95, 62, 40)
								local view = add(folder, base, { name = "WindowView", size = Vector3.new(4.4, 4.4, 0.1), at = Vector3.new(0, 8, -0.28), color = C(10, 10, 30) })
								local sg = Instance.new("SurfaceGui")
								sg.Face = Enum.NormalId.Front
								sg.CanvasSize = Vector2.new(240, 240)
								sg.LightInfluence = 0
								sg.Brightness = 1.2
								sg.Parent = view
								paintView(sg, theme, r * 97 + x * 13 + y)
								add(folder, base, { size = Vector3.new(4.4, 4.4, 0.05), at = Vector3.new(0, 8, -0.38), color = C(200, 220, 255), mat = Enum.Material.Glass, alpha = 0.8, shine = 0.15 })
								for _, bar in ipairs({
									{ Vector3.new(5.2, 0.4, 0.3), Vector3.new(0, 10.4, -0.4) }, { Vector3.new(5.2, 0.4, 0.3), Vector3.new(0, 5.6, -0.4) },
									{ Vector3.new(0.4, 5.2, 0.3), Vector3.new(-2.4, 8, -0.4) }, { Vector3.new(0.4, 5.2, 0.3), Vector3.new(2.4, 8, -0.4) },
									{ Vector3.new(0.2, 4.4, 0.2), Vector3.new(0, 8, -0.42) }, { Vector3.new(4.4, 0.2, 0.2), Vector3.new(0, 8, -0.42) },
								}) do
									add(folder, base, { size = bar[1], at = bar[2], color = wood, mat = (theme == "party" or theme == "school") and WOOD or Enum.Material.SmoothPlastic })
								end
								add(folder, base, { size = Vector3.new(5.6, 0.3, 0.9), at = Vector3.new(0, 5.35, -0.5), color = wood, mat = (theme == "party" or theme == "school") and WOOD or Enum.Material.SmoothPlastic })
								if not lit then
									lit = true
									local beam = Instance.new("SpotLight")
									beam.Face = Enum.NormalId.Front
									beam.Color = theme == "gummy" and C(255, 200, 235) or C(170, 190, 255)
									beam.Brightness = 1.2
									beam.Range = 20
									beam.Angle = 70
									beam.Parent = view
								end
							end
						end
					end
				end
			end
		end
	end
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

	current.world = world
	world.chute = nil
	local openings = {} -- wall tiles opened up (the vault)
	doorSigns(folder, map)
	for _, f in ipairs(map.floors) do
		current.room = f.name
		local look, listed = lookFor(f.name, map.theme or "party")
		local pieces = table.clone(listed) -- this game's own copy (the switch is added below)
		local theme = map.theme or "party"
		ambience(folder, f, Config.AMBIENT[firstMatch(SOUNDS_BY_NAME, f.name, theme) or ""])
		local fx = firstMatch(EFFECTS_BY_NAME, f.name, theme)
		if fx then
			effect(folder, f, fx)
		end
		-- the room's own light colour; machine rooms get a slow red warning glow
		local roomLight = world.roomLights and world.roomLights[f.name]
		if roomLight and look and LIGHT_BY_LOOK[look] then
			roomLight.Color = LIGHT_BY_LOOK[look]
		end
		if look == "brick" and (string.find(string.lower(f.name), "boiler") or string.find(string.lower(f.name), "generator")) then
			local lamp = Instance.new("Part")
			lamp.Anchored, lamp.CanCollide, lamp.CanQuery, lamp.CanTouch = true, false, false, false
			lamp.Shape = Enum.PartType.Ball
			lamp.Size = Vector3.new(1, 1, 1)
			lamp.Material, lamp.Color = Enum.Material.Neon, C(255, 40, 30)
			lamp.Position = Vector3.new((f.x0 + f.x1 + 1) / 2 * T, H - 1, (f.y0 + f.y1 + 1) / 2 * T)
			lamp.Parent = folder
			local l = glow(lamp, C(255, 40, 30), 26, 0)
			TweenService:Create(l, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Brightness = 1.5 }):Play()
		end
		-- every room has a light switch (Party House and Hospital: a dark room hides you)
		if theme ~= "gummy" then
			table.insert(pieces, "LightSwitch")
		end
		-- the Jelly Vault's vault door, in the outer wall
		if string.find(string.lower(f.name), "vault door hall", 1, true) then
			local okV, errV = pcall(buildVault, folder, world, map, f, busy, openings)
			if not okV then
				warn("Room dressing: the vault door failed - " .. tostring(errV))
			end
		end
		if look then
			lineWalls(folder, map, f, look, openings)
			local fl = FLOORS[look]
			if fl and f.kind ~= "tiles" and f.kind ~= "pinktiles" and f.kind ~= "whitetiles" then
				local p = Instance.new("Part")
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
				p.Name = "RoomFloor"
				p.Size = Vector3.new((f.x1 - f.x0 + 1) * T, 0.06, (f.y1 - f.y0 + 1) * T)
				p.Position = Vector3.new((f.x0 + f.x1 + 1) / 2 * T, 0.03, (f.y0 + f.y1 + 1) / 2 * T)
				p.Material, p.Color = fl[1], fl[2]
				p.Parent = folder
			end
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
	-- the laundry chute, then windows on the outer walls
	local okC, errC = pcall(buildChute, folder, world, map, busy, openTiles(map))
	if not okC then
		warn("Room dressing: the laundry chute failed - " .. tostring(errC))
	end
	local okW, errW = pcall(buildWindows, folder, world, map, busy, {})
	if not okW then
		warn("Room dressing: windows failed - " .. tostring(errW))
	end
	local okP, errP = pcall(buildPosters, folder, map, busy)
	if not okP then
		warn("Room dressing: posters failed - " .. tostring(errP))
	end
	return folder
end

return Rooms
