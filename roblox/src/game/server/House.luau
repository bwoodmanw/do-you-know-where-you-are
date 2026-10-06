--[[
	House - builds the Party House in 3D from HouseMap: floors, walls, a
	ceiling, furniture, the props you interact with, lights and the garden
	safe area. Returns a table of the interactive parts by object id.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage.Shared.Config)

local T = Config.TILE
local H = Config.WALL_H

local House = {}
local HT = 24 -- ceiling height of tall rooms (the Gallery with its loft)

-- inside, or in the wall ring round, a tall room
local function tallAt(map, x, y, ring)
	for _, f in ipairs(map.floors) do
		if f.tall and x >= f.x0 - (ring and 1 or 0) and x <= f.x1 + (ring and 1 or 0) and y >= f.y0 - (ring and 1 or 0) and y <= f.y1 + (ring and 1 or 0) then
			return true
		end
	end
	return false
end

local FLOOR = {
	carpet = { Enum.Material.Carpet, Color3.fromRGB(122, 39, 65) },
	boards = { Enum.Material.WoodPlanks, Color3.fromRGB(77, 53, 38) },
	green = { Enum.Material.Carpet, Color3.fromRGB(47, 90, 62) },
	tiles = { Enum.Material.CeramicTiles, Color3.fromRGB(214, 207, 191) },
	wood = { Enum.Material.WoodPlanks, Color3.fromRGB(150, 98, 52) },
	purple = { Enum.Material.Carpet, Color3.fromRGB(75, 53, 112) },
	door = { Enum.Material.WoodPlanks, Color3.fromRGB(62, 44, 34) },
}

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

-- centre of tile (x, y) at height h
function House.at(x, y, h)
	return Vector3.new(x * T + T / 2, h or 0, y * T + T / 2)
end
local at = House.at

local function cell(map, x, y)
	if y < 0 or y >= map.h or x < 0 or x >= map.w then
		return "#"
	end
	return string.sub(map.map[y + 1], x + 1, x + 1)
end

-- the way an object against a wall faces: away from the wall, into the room
local function facing(map, x, y)
	for _, d in ipairs({ { 0, -1 }, { 0, 1 }, { 1, 0 }, { -1, 0 } }) do
		local behind = cell(map, x + d[1], y + d[2])
		if (behind == "#" or behind == "T") and cell(map, x - d[1], y - d[2]) == "." then
			return Vector3.new(-d[1], 0, -d[2])
		end
	end
	return Vector3.new(0, 0, 1)
end

local function prompt(p, action, object, hold)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object or ""
	pp.HoldDuration = hold or 0
	pp.MaxActivationDistance = 10
	pp.RequiresLineOfSight = false
	pp.Parent = p
	return pp
end

local function light(parent, pos, color, range, brightness)
	local holder = part(parent, { Size = Vector3.new(1, 1, 1), Position = pos, Transparency = 1, CanCollide = false, CanQuery = false })
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = true
	l.Parent = holder
	return l
end

local function floorKind(map, x, y)
	for _, f in ipairs(map.floors) do
		if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
			return f.kind
		end
	end
	return "door"
end

local function furnitureAt(map, x, y)
	for _, f in ipairs(map.furniture) do
		if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
			return f
		end
	end
	return nil
end

function House.build(map)
	local old = workspace:FindFirstChild("PartyHouse")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "PartyHouse"
	root.Parent = workspace
	local world = { root = root, objects = {}, lights = {}, map = map }

	-- floors: one slab per room, checker tiles in the kitchen
	for _, f in ipairs(map.floors) do
		local w, d = (f.x1 - f.x0 + 1) * T, (f.y1 - f.y0 + 1) * T
		local centre = Vector3.new((f.x0 + f.x1 + 1) / 2 * T, -0.5, (f.y0 + f.y1 + 1) / 2 * T)
		local mat = FLOOR[f.kind]
		if f.kind == "tiles" then
			for y = f.y0, f.y1 do
				for x = f.x0, f.x1 do
					for qy = 0, 1 do
						for qx = 0, 1 do
							local dark = (x * 2 + qx + y * 2 + qy) % 2 == 0
							part(root, {
								Name = "Tile",
								Size = Vector3.new(T / 2, 1, T / 2),
								Position = Vector3.new(x * T + qx * T / 2 + T / 4, -0.5, y * T + qy * T / 2 + T / 4),
								Material = Enum.Material.CeramicTiles,
								Color = dark and Color3.fromRGB(40, 40, 46) or Color3.fromRGB(226, 220, 205),
							})
						end
					end
				end
			end
		else
			part(root, { Name = "Floor " .. f.name, Size = Vector3.new(w, 1, d), Position = centre, Material = mat[1], Color = mat[2] })
		end
		-- a warm light per room, dimmed for Spooky games later
		local l = light(root, Vector3.new(centre.X, (f.tall and HT or H) - 2, centre.Z), Color3.fromRGB(255, 196, 120), math.min(60, math.max(w, d) * 0.75), 1.2)
		table.insert(world.lights, l)
	end

	-- doorway floors, walls, furniture
	for y = 0, map.h - 1 do
		for x = 0, map.w - 1 do
			local c = cell(map, x, y)
			if c == "." and floorKind(map, x, y) == "door" then
				part(root, { Name = "Doorway", Size = Vector3.new(T, 1, T), Position = at(x, y, -0.5), Material = FLOOR.door[1], Color = FLOOR.door[2] })
				if tallAt(map, x, y, true) then
					-- close the gap above a doorway into a tall room
					part(root, { Name = "TallLintel", Size = Vector3.new(T, HT - H, T), Position = at(x, y, H + (HT - H) / 2), Material = Enum.Material.Plaster, Color = Color3.fromRGB(70, 46, 96) })
				end
			elseif c == "#" or c == "C" then
				part(root, {
					Name = "Wall",
					Size = Vector3.new(T, tallAt(map, x, y, true) and HT or H, T),
					Position = at(x, y, (tallAt(map, x, y, true) and HT or H) / 2),
					Material = Enum.Material.Plaster,
					Color = Color3.fromRGB(70, 46, 96),
				})
				if c == "C" then
					local side = cell(map, x + 1, y) == "." and 1 or -1
					-- the host's dark doorway, with eyes
					part(root, { Name = "HostDoor", Size = Vector3.new(0.4, 9, 5), Position = at(x, y, 4.5) + Vector3.new((T / 2 + 0.1) * side, 0, 0), Color = Color3.fromRGB(5, 3, 10), Material = Enum.Material.SmoothPlastic })
					for i = -1, 1, 2 do
						part(root, { Name = "Eye", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), Position = at(x, y, 6.5) + Vector3.new((T / 2 + 0.35) * side, 0, i * 0.7), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 50, 50), CanCollide = false })
					end
				end
			elseif c == "D" or c == "H" or c == "L" then
				-- locked doors are tall enough for the host once open
				local top = c == "L" and 13 or 10
				part(root, { Name = "DoorFloor", Size = Vector3.new(T, 1, T), Position = at(x, y, -0.5), Material = FLOOR.door[1], Color = FLOOR.door[2] })
				part(root, { Name = "Lintel", Size = Vector3.new(T, H - top, T), Position = at(x, y, top + (H - top) / 2), Material = Enum.Material.Plaster, Color = Color3.fromRGB(70, 46, 96) })
			elseif c == "T" then
				local f = furnitureAt(map, x, y)
				local kind = f and f.kind or "table"
				if kind == "table" then
					part(root, { Name = "Table", Size = Vector3.new(T, 0.6, T), Position = at(x, y, 3.4), Material = Enum.Material.Fabric, Color = Color3.fromRGB(242, 233, 247) })
					part(root, { Name = "TableSkirt", Size = Vector3.new(T - 0.2, 3, T - 0.2), Position = at(x, y, 1.6), Material = Enum.Material.Fabric, Color = Color3.fromRGB(255, 138, 31) })
				elseif kind == "counter" then
					part(root, { Name = "Counter", Size = Vector3.new(T, 4, T), Position = at(x, y, 2), Material = Enum.Material.Wood, Color = Color3.fromRGB(139, 106, 79) })
					part(root, { Name = "CounterTop", Size = Vector3.new(T, 0.4, T), Position = at(x, y, 4.2), Material = Enum.Material.Marble, Color = Color3.fromRGB(207, 200, 187) })
				elseif kind == "bed" then
					part(root, { Name = "Bed", Size = Vector3.new(T, 2.4, T), Position = at(x, y, 1.2), Material = Enum.Material.Fabric, Color = Color3.fromRGB(200, 190, 230) })
					part(root, { Name = "Pillow", Size = Vector3.new(T * 0.7, 0.8, 2), Position = at(x, y, 2.8), Material = Enum.Material.Fabric, Color = Color3.fromRGB(245, 240, 250), CanCollide = false })
				elseif kind == "desk" then
					part(root, { Name = "Desk", Size = Vector3.new(T, 0.5, T * 0.7), Position = at(x, y, 3.6), Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 80, 50) })
					part(root, { Name = "DeskBody", Size = Vector3.new(T * 0.9, 3.4, T * 0.6), Position = at(x, y, 1.7), Material = Enum.Material.Wood, Color = Color3.fromRGB(100, 66, 40) })
				elseif kind == "bath" then
					part(root, { Name = "Bath", Size = Vector3.new(T, 3, T), Position = at(x, y, 1.5), Material = Enum.Material.Marble, Color = Color3.fromRGB(235, 235, 240) })
				elseif kind == "planter" then
					part(root, { Name = "Planter", Size = Vector3.new(T, 3, T * 0.7), Position = at(x, y, 1.5), Material = Enum.Material.Brick, Color = Color3.fromRGB(150, 80, 60) })
					for i = -1, 1 do
						part(root, { Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(3.2, 3.2, 3.2), Position = at(x, y, 4) + Vector3.new(i * 2.4, 0, 0), Material = Enum.Material.Grass, Color = (x + i) % 2 == 0 and Color3.fromRGB(58, 125, 68) or Color3.fromRGB(95, 179, 90), CanCollide = false })
					end
				elseif kind == "piano" then
					part(root, { Name = "Piano", Size = Vector3.new(T, 5, T * 0.7), Position = at(x, y, 2.5), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(20, 18, 24) })
					part(root, { Name = "Keys", Size = Vector3.new(T, 0.3, 1.4), Position = at(x, y, 4.2) + Vector3.new(0, 0, T * 0.35 + 0.7), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 240, 235) })
				else
					part(root, { Name = "Shelf", Size = Vector3.new(T, 10, T * 0.6), Position = at(x, y, 5), Material = Enum.Material.Wood, Color = Color3.fromRGB(92, 58, 34) })
					local cols = { Color3.fromRGB(232, 80, 91), Color3.fromRGB(61, 139, 255), Color3.fromRGB(255, 210, 63), Color3.fromRGB(70, 209, 96), Color3.fromRGB(138, 107, 209) }
					for row = 0, 2 do
						for b = 0, 5 do
							part(root, {
								Name = "Book",
								Size = Vector3.new(0.9, 2.2, 0.4),
								Position = at(x, y, 1.6 + row * 3) + Vector3.new(-3 + b * 1.2, 0, T * 0.3 + 0.2),
								Color = cols[((x + b + row) % 5) + 1],
								CanCollide = false,
							})
						end
					end
				end
			end
		end
	end

	-- the party cake on the hall table
	local cake = part(root, { Name = "Cake", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 3.4, 3.4), CFrame = CFrame.new(at(map.cake[1], map.cake[2], 0) + Vector3.new(T / 2, 4.9, T / 2)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(247, 198, 217), Material = Enum.Material.SmoothPlastic })
	part(root, { Name = "Candle", Size = Vector3.new(0.3, 1.2, 0.3), Position = cake.Position + Vector3.new(0, 1.8, 0), Color = Color3.new(1, 1, 1) })
	part(root, { Name = "Flame", Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4), Position = cake.Position + Vector3.new(0, 2.6, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 210, 63), CanCollide = false })

	-- ceiling, so the house feels like a house
	local function ceiling(x0, y0, x1, y1, height)
		if x1 < x0 or y1 < y0 then
			return
		end
		part(root, { Name = "Ceiling", Size = Vector3.new((x1 - x0 + 1) * T, 4, (y1 - y0 + 1) * T), Position = Vector3.new((x0 + x1 + 1) / 2 * T, height + 2.02, (y0 + y1 + 1) / 2 * T), CastShadow = false, Material = Enum.Material.Plaster, Color = Color3.fromRGB(30, 20, 40) })
	end
	local tall
	for _, f in ipairs(map.floors) do
		if f.tall then
			tall = f
		end
	end
	if tall then
		-- a high ceiling over the tall room, the normal one everywhere else
		ceiling(0, 0, map.w - 1, tall.y0 - 1, H)
		ceiling(0, tall.y1 + 1, map.w - 1, map.h - 1, H)
		ceiling(0, tall.y0, tall.x0 - 1, tall.y1, H)
		ceiling(tall.x1 + 1, tall.y0, map.w - 1, tall.y1, H)
		ceiling(tall.x0, tall.y0, tall.x1, tall.y1, HT)
	else
		ceiling(0, 0, map.w - 1, map.h - 1, H)
	end
	House.buildLoft(world)

	House.buildObjects(world)
	House.buildGarden(world)
	House.decorate(world)
	return world
end

function House.buildObjects(world)
	local root, map = world.root, world.map
	for _, o in ipairs(map.objects) do
		local base = at(o.x, o.y, o.h or 0)
		local entry = { def = o }
		world.objects[o.id] = entry
		if o.kind == "door" then
			entry.door = part(root, { Name = "BigDoor", Size = Vector3.new(T, 10, 1), Position = base + Vector3.new(0, 5, T / 2 - 0.6), Material = Enum.Material.Wood, Color = Color3.fromRGB(122, 74, 30) })
			entry.keypad = part(root, { Name = "Keypad", Size = Vector3.new(1.6, 2, 0.3), Position = base + Vector3.new(2.6, 4.5, T / 2 + 0.05), Color = Color3.fromRGB(30, 30, 34) })
			for i, col in ipairs(Config.COLORS) do
				part(root, { Name = "Key", Size = Vector3.new(0.5, 0.5, 0.1), Position = entry.keypad.Position + Vector3.new(((i - 1) % 2) * 0.7 - 0.35, 0.4 - math.floor((i - 1) / 2) * 0.7, 0.18), Material = Enum.Material.Neon, Color = Config.COLOR3[col], CanCollide = false })
			end
			entry.usePrompt = prompt(entry.keypad, "Use keypad", "Big door")
			entry.exit = part(root, { Name = "ExitDoor", Size = Vector3.new(T, 10, 2), Position = base + Vector3.new(0, 5, -T / 2 + 1), Transparency = 1, CanCollide = false })
		elseif o.kind == "hole" then
			entry.panel = part(root, { Name = "HolePanel", Size = Vector3.new(T, 10, T), Position = base + Vector3.new(0, 5, 0), Material = Enum.Material.Plaster, Color = Color3.fromRGB(70, 46, 96) })
			entry.exit = part(root, { Name = "ExitHole", Size = Vector3.new(2, 10, T), Position = base + Vector3.new((T / 2 + 1) * (o.x == 0 and -1 or 1), 5, 0), Transparency = 1, CanCollide = false })
		elseif o.kind == "cabinet" then
			entry.part = part(root, { Name = "Cabinet", Size = Vector3.new(T * 0.8, 9, T * 0.9), Position = base + Vector3.new(0, 4.5, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(107, 66, 38) })
			entry.prompt = prompt(entry.part, "Shove", "Heavy cabinet - Muscle", 2.5)
		elseif o.kind == "cage" then
			local cage = Instance.new("Model")
			cage.Name = "Cage"
			cage.Parent = root
			part(cage, { Name = "CageFloor", Size = Vector3.new(T, 0.4, T), Position = base + Vector3.new(0, 0.2, 0), Color = Color3.fromRGB(43, 43, 51), Material = Enum.Material.Metal })
			part(cage, { Name = "CageRoof", Size = Vector3.new(T, 0.4, T), Position = base + Vector3.new(0, 8, 0), Color = Color3.fromRGB(43, 43, 51), Material = Enum.Material.Metal })
			for i = 0, 6 do
				local t = -T / 2 + i * T / 6
				for _, off in ipairs({ Vector3.new(t, 4, -T / 2), Vector3.new(t, 4, T / 2), Vector3.new(-T / 2, 4, t), Vector3.new(T / 2, 4, t) }) do
					part(cage, { Name = "Bar", Size = Vector3.new(0.25, 8, 0.25), Position = base + off, Material = Enum.Material.Metal, Color = Color3.fromRGB(154, 154, 168) })
				end
			end
			entry.inside = base + Vector3.new(0, 3, 0)
			entry.outside = at(o.x + 1, o.y, 3)
			entry.part = cage.CageRoof
			local lockPart = part(cage, { Name = "Padlock", Size = Vector3.new(1, 1, 0.4), Position = base + Vector3.new(T / 2 + 0.3, 4, 0), Color = Color3.fromRGB(255, 210, 63), Material = Enum.Material.Metal })
			entry.prompt = prompt(lockPart, "Free your friend", "Cage", 2)
			entry.prompt.Enabled = false
		elseif o.kind == "balloon" then
			local b = part(root, { Name = "Balloon", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), Position = base + Vector3.new(0, 6, 0), Color = Color3.fromRGB(239, 233, 245), Material = Enum.Material.SmoothPlastic, CanCollide = false })
			part(root, { Name = "String", Size = Vector3.new(0.08, 4.7, 0.08), Position = base + Vector3.new(0, 2.35, 0), Color = Color3.fromRGB(220, 220, 220), CanCollide = false })
			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromOffset(50, 50)
			gui.StudsOffset = Vector3.new(0, 0, 0)
			gui.AlwaysOnTop = false
			gui.Parent = b
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text = tostring(o.n)
			label.TextScaled = true
			label.Font = Enum.Font.FredokaOne
			label.TextColor3 = Color3.fromRGB(58, 42, 79)
			label.Parent = gui
			entry.part, entry.label = b, label
			entry.prompt = prompt(b, "Pop", "Balloon " .. o.n)
		elseif o.kind == "present" then
			local blue = o.boost == "shield" or o.id == "p3"
			entry.part = part(root, { Name = "Present", Size = Vector3.new(2.2, 2, 2.2), Position = base + Vector3.new(0, 1, 0), Color = blue and Color3.fromRGB(61, 139, 255) or Color3.fromRGB(232, 80, 91) })
			part(root, { Name = "Ribbon", Size = Vector3.new(2.3, 2.1, 0.4), Position = entry.part.Position, Color = Color3.fromRGB(255, 210, 63), CanCollide = false })
			entry.lid = part(root, { Name = "PresentLid", Size = Vector3.new(2.5, 0.5, 2.5), Position = base + Vector3.new(0, 2.2, 0), Color = entry.part.Color, CanCollide = false })
			part(root, { Name = "Bow", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), Position = base + Vector3.new(0, 2.6, 0), Color = Color3.fromRGB(255, 210, 63), CanCollide = false }).Parent = entry.lid
			entry.style = "present"
			entry.prompt = prompt(entry.part, "Open", "Present")
		elseif o.kind == "invite" or o.kind == "uv" then
			local poster = part(root, { Name = o.kind == "invite" and "Invitation" or "GlowWall", Size = Vector3.new(4, 4, 0.2), Position = base + Vector3.new(0, 6, T / 2 + 0.15), Color = o.kind == "invite" and Color3.fromRGB(247, 231, 196) or Color3.fromRGB(60, 40, 85), CanCollide = false })
			local sg = Instance.new("SurfaceGui")
			sg.Face = Enum.NormalId.Back
			sg.Parent = poster
			local txt = Instance.new("TextLabel")
			txt.Size = UDim2.fromScale(1, 1)
			txt.BackgroundTransparency = 1
			txt.TextScaled = true
			txt.Font = o.kind == "invite" and Enum.Font.Fondamento or Enum.Font.Creepster
			txt.TextColor3 = o.kind == "invite" and Color3.fromRGB(138, 63, 209) or Color3.fromRGB(110, 90, 140)
			txt.Text = o.kind == "invite" and "You're invited!\n~~~~~~~~\n~~~~~~" or "~ ~ ~"
			txt.Parent = sg
			entry.part, entry.label = poster, txt
			if o.kind == "invite" then
				entry.prompt = prompt(poster, "Read", "Twisty invitation - Brainy", 1.5)
			else
				entry.prompt = prompt(poster, "Light up", "Painted wall - Glow", 1.5)
			end
		elseif o.kind == "plant" then
			local pot = part(root, { Name = "Pot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 2.4, 2.4), CFrame = CFrame.new(base + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(181, 101, 58), Material = Enum.Material.Slate })
			for i = 1, 7 do
				local a = i / 7 * math.pi * 2
				part(root, { Name = "Leaf", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 2.6, 1.6), Position = base + Vector3.new(math.cos(a) * 1.1, 3.2 + (i % 2) * 0.8, math.sin(a) * 1.1), Color = i % 2 == 0 and Color3.fromRGB(58, 125, 68) or Color3.fromRGB(95, 179, 90), Material = Enum.Material.Grass, CanCollide = false })
			end
			entry.part = pot
			entry.prompt = prompt(pot, "Ask the plant", "Big plant - Bramble", 1.5)
		elseif o.kind == "lock" then
			-- walls left and right: the door spans X, otherwise Z
			local alongX = cell(map, o.x - 1, o.y) ~= "."
			entry.part = part(root, { Name = "LockedDoor", Size = alongX and Vector3.new(T, 13, 1) or Vector3.new(1, 13, T), Position = base + Vector3.new(0, 6.5, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(96, 52, 30) })
			entry.lockPart = part(root, { Name = "Lock", Size = alongX and Vector3.new(1, 1.2, 1.6) or Vector3.new(1.6, 1.2, 1), Position = base + Vector3.new(0, 4.5, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(255, 210, 63) })
			for _, face in ipairs(alongX and { Enum.NormalId.Front, Enum.NormalId.Back } or { Enum.NormalId.Left, Enum.NormalId.Right }) do
				local sg = Instance.new("SurfaceGui")
				sg.Face = face
				sg.CanvasSize = Vector2.new(400, 650)
				sg.Parent = entry.part
				local txt = Instance.new("TextLabel")
				txt.Size = UDim2.new(1, -40, 0.22, 0)
				txt.Position = UDim2.new(0, 20, 0.08, 0)
				txt.BackgroundTransparency = 1
				txt.TextScaled = true
				txt.Font = Enum.Font.FredokaOne
				txt.TextColor3 = Color3.fromRGB(255, 210, 63)
				txt.Text = "\u{1F512} " .. (o.name or "Locked door")
				txt.Parent = sg
			end
			entry.unlockPrompt = prompt(entry.lockPart, "Unlock", o.name or "Locked door", 0.5)
			entry.pickPrompt = prompt(entry.lockPart, "Pick the lock", "Tinker", 4)
			entry.pickPrompt.KeyboardKeyCode = Enum.KeyCode.F
		elseif o.kind == "vent" then
			-- a grate low on the wall towards the other end
			local dir = Vector3.new(0, 0, 0)
			for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
				if cell(map, o.x + d[1], o.y + d[2]) == "#" and cell(map, o.x + 2 * d[1], o.y + 2 * d[2]) == "." then
					for _, p in ipairs(map.objects) do
						if p.kind == "vent" and p.pair == o.pair and p.x == o.x + 2 * d[1] and p.y == o.y + 2 * d[2] then
							dir = Vector3.new(d[1], 0, d[2])
						end
					end
				end
			end
			local alongX = dir.X ~= 0
			local spot = base + dir * (T / 2 - 0.15) + Vector3.new(0, 1.6, 0)
			part(root, { Name = "VentHole", Size = alongX and Vector3.new(0.2, 3, 3.8) or Vector3.new(3.8, 3, 0.2), Position = spot, Color = Color3.fromRGB(8, 6, 10), CanCollide = false })
			entry.part = part(root, { Name = "Vent", Size = alongX and Vector3.new(0.3, 3.2, 4) or Vector3.new(4, 3.2, 0.3), Position = spot - dir * 0.2, Color = Color3.fromRGB(150, 150, 160), Material = Enum.Material.DiamondPlate, Transparency = 0.3, CanCollide = false })
			entry.prompt = prompt(entry.part, "Crawl", "Vent", 0.5)
		elseif o.kind == "search" then
			-- size, colour, material, name, how it opens
			local looks = {
				drawer = { Vector3.new(5, 4, 3), Color3.fromRGB(120, 80, 50), Enum.Material.Wood, "Chest of drawers", "drawer" },
				crate = { Vector3.new(4, 4, 4), Color3.fromRGB(170, 130, 80), Enum.Material.WoodPlanks, "Old crate", "lid" },
				cakebox = { Vector3.new(3.5, 3, 3.5), Color3.fromRGB(255, 190, 210), Enum.Material.Cardboard, "Cake box", "lid" },
				coat = { Vector3.new(3, 8, 3), Color3.fromRGB(60, 80, 60), Enum.Material.Fabric, "Coats", "coat" },
				toybox = { Vector3.new(5, 3, 3.5), Color3.fromRGB(200, 60, 60), Enum.Material.SmoothPlastic, "Toy box", "lid" },
				vase = { Vector3.new(2.6, 4.5, 2.6), Color3.fromRGB(60, 130, 140), Enum.Material.SmoothPlastic, "Big vase", "tip" },
				laundry = { Vector3.new(3.5, 3.5, 3.5), Color3.fromRGB(190, 160, 110), Enum.Material.Fabric, "Laundry basket", "lid" },
				chest = { Vector3.new(5, 3.5, 3.5), Color3.fromRGB(110, 70, 40), Enum.Material.Wood, "Old chest", "lid" },
			}
			local look = looks[o.look] or looks.crate
			local size, col, mat = look[1], look[2], look[3]
			local front = facing(map, o.x, o.y)
			local cf = CFrame.lookAt(base, base + front) -- -Z (LookVector) is the front
			entry.style, entry.front, entry.cf, entry.depth = look[5], front, cf, size.Z
			if look[5] == "lid" then
				entry.part = part(root, { Name = "Search " .. o.id, Size = size - Vector3.new(0, 0.5, 0), CFrame = cf * CFrame.new(0, (size.Y - 0.5) / 2, 0), Color = col, Material = mat })
				entry.lid = part(root, { Name = "Lid", Size = Vector3.new(size.X + 0.2, 0.5, size.Z + 0.2), CFrame = cf * CFrame.new(0, size.Y - 0.25, 0), Color = col:Lerp(Color3.new(0, 0, 0), 0.2), Material = mat })
				entry.hinge = cf * CFrame.new(0, size.Y, (size.Z + 0.2) / 2) -- the back top edge
			elseif look[5] == "drawer" then
				entry.part = part(root, { Name = "Search " .. o.id, Size = size, CFrame = cf * CFrame.new(0, size.Y / 2, 0), Color = col, Material = mat })
				entry.drawer = part(root, { Name = "Drawer", Size = Vector3.new(size.X - 0.6, size.Y * 0.35, size.Z - 0.4), CFrame = cf * CFrame.new(0, size.Y * 0.72, -0.25), Color = col:Lerp(Color3.new(1, 1, 1), 0.15), Material = mat, CanCollide = false })
				part(root, { Name = "Knob", Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4), CFrame = cf * CFrame.new(0, size.Y * 0.72, -size.Z / 2 - 0.25), Color = Color3.fromRGB(230, 200, 120), CanCollide = false }).Parent = entry.drawer
				part(root, { Name = "Drawer", Size = Vector3.new(size.X - 0.6, size.Y * 0.35, 0.2), CFrame = cf * CFrame.new(0, size.Y * 0.3, -size.Z / 2 - 0.05), Color = col:Lerp(Color3.new(1, 1, 1), 0.15), Material = mat, CanCollide = false })
			elseif look[5] == "coat" then
				entry.part = part(root, { Name = "Search " .. o.id, Size = Vector3.new(0.5, 8, 0.5), CFrame = cf * CFrame.new(0, 4, 0.6), Color = Color3.fromRGB(80, 55, 35), Material = Enum.Material.Wood })
				entry.coats = {}
				for i, c in ipairs({ Color3.fromRGB(60, 80, 60), Color3.fromRGB(120, 40, 50) }) do
					table.insert(entry.coats, part(root, { Name = "Coat", Size = Vector3.new(1.7, 4, 0.9), CFrame = cf * CFrame.new(i == 1 and -0.9 or 0.9, 5, 0), Color = c, Material = Enum.Material.Fabric, CanCollide = false }))
				end
			else -- vase: tips over
				entry.part = part(root, { Name = "Search " .. o.id, Size = size, CFrame = cf * CFrame.new(0, size.Y / 2, 0), Color = col, Material = mat })
				local neck = part(root, { Name = "VaseNeck", Size = Vector3.new(1.4, 1, 1.4), CFrame = cf * CFrame.new(0, size.Y + 0.5, 0), Color = col, Material = mat, CanCollide = false })
				entry.tipParts = { entry.part, neck }
			end
			entry.prompt = prompt(entry.part, "Search", look[4], 2)
		elseif o.kind == "hide" then
			local size, col, mat, y = Vector3.new(T * 0.8, 10, T * 0.6), Color3.fromRGB(78, 47, 26), Enum.Material.Wood, 5
			if o.look == "curtain" then
				size, col, mat = Vector3.new(T * 0.9, 12, 1.2), Color3.fromRGB(122, 31, 61), Enum.Material.Fabric
				y = 6
			elseif o.look == "sofa" then
				size, col, mat, y = Vector3.new(T * 0.9, 3.5, T * 0.6), Color3.fromRGB(91, 59, 138), Enum.Material.Fabric, 1.75
			elseif o.look == "cloth" then
				size, col, mat, y = Vector3.new(T, 3, 1.5), Color3.fromRGB(242, 233, 247), Enum.Material.Fabric, 1.5
			elseif o.look == "box" then
				size, col, mat, y = Vector3.new(5, 5, 5), Color3.fromRGB(201, 154, 91), Enum.Material.Cardboard, 2.5
			end
			entry.part = part(root, { Name = "Hide " .. o.id, Size = size, Position = base + Vector3.new(0, y, 0), Color = col, Material = mat })
			entry.inside = base + Vector3.new(0, 3, 0)
			entry.prompt = prompt(entry.part, "Hide", "Fits " .. (o.cap or 2))
			entry.prompt.HoldDuration = 0.2
		end
	end
end

function House.buildGarden(world)
	local root, map = world.root, world.map
	-- the safe area: the back garden beyond the big door (north) and round
	-- the side past the hole (east)
	local doorX = 15
	for _, o in ipairs(map.objects) do
		if o.kind == "door" then
			doorX = o.x
		end
	end
	local gx0, gx1 = doorX - 7, doorX + 8
	-- upper floors: the way out is a stairwell landing (wood, walls, stairs up) instead of the garden
	local stairs = map.exitStyle == "stairs"
	local groundMat, groundCol = Enum.Material.Grass, Color3.fromRGB(60, 110, 50)
	if stairs then
		groundMat, groundCol = Enum.Material.WoodPlanks, Color3.fromRGB(110, 75, 48)
	end
	local garden = part(root, { Name = "Garden", Size = Vector3.new((gx1 - gx0) * T, 1, 6 * T), Position = Vector3.new((gx0 + gx1) / 2 * T, -0.5, -3 * T), Material = groundMat, Color = groundCol })
	if stairs then
		for i = 1, 8 do
			part(root, { Name = "StairUp", Size = Vector3.new(16, i * 1.5, 3), Position = Vector3.new(doorX * T + T / 2, i * 0.75, -16 - i * 3), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(95, 62, 40), CanCollide = false })
		end
		local sign = part(root, { Name = "UpSign", Size = Vector3.new(10, 3, 0.3), Position = Vector3.new(doorX * T + T / 2, 14, -5.9 * T), Color = Color3.fromRGB(40, 28, 46), CanCollide = false })
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Back
		sg.Parent = sign
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.FredokaOne
		t.TextColor3 = Color3.fromRGB(255, 210, 63)
		t.Text = "\u{2B06} Up to the next floor"
		t.Parent = sg
	end
	-- the side path runs along whichever side has the hole
	local holeWest = false
	for _, o in ipairs(map.objects) do
		if o.kind == "hole" and o.x == 0 then
			holeWest = true
		end
	end
	local sideX = holeWest and -2 * T or map.w * T + 2 * T
	part(root, { Name = "SidePath", Size = Vector3.new(4 * T, 1, map.h * T), Position = Vector3.new(sideX, -0.5, map.h * T / 2), Material = Enum.Material.Grass, Color = Color3.fromRGB(60, 110, 50) })
	for i = 0, 10 do
		local pos = Vector3.new(gx0 * T + i * (gx1 - gx0) * T / 10, 9, -5.5 * T)
		part(root, { Name = "FairyLight", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), Position = pos, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 220, 140), CanCollide = false })
	end
	light(root, garden.Position + Vector3.new(0, 10, 0), Color3.fromRGB(255, 220, 160), 60, 2)
	-- hedges you can see, and tall invisible walls so nobody walks or jumps off
	local function hedge(x0, z0, x1, z1)
		local size = Vector3.new(math.max(2, math.abs(x1 - x0)), 6, math.max(2, math.abs(z1 - z0)))
		local centre = Vector3.new((x0 + x1) / 2, 3, (z0 + z1) / 2)
		part(root, { Name = "Hedge", Size = stairs and Vector3.new(size.X, 16, size.Z) or size, Position = stairs and centre + Vector3.new(0, 5, 0) or centre,
			Material = stairs and Enum.Material.Plaster or Enum.Material.LeafyGrass, Color = stairs and Color3.fromRGB(70, 46, 96) or Color3.fromRGB(40, 80, 38) })
		part(root, { Name = "Boundary", Size = Vector3.new(size.X, 40, size.Z), Position = centre + Vector3.new(0, 20, 0), Transparency = 1 })
	end
	local gx0s, gx1s, gz = gx0 * T, gx1 * T, -6 * T
	hedge(gx0s, gz, gx0s, 0) -- west side of the garden
	hedge(gx1s, gz, gx1s, 0) -- east side
	hedge(gx0s, gz, gx1s, gz) -- far end
	local px0, px1 = sideX - 2 * T, sideX + 2 * T
	hedge(holeWest and px0 or px1, 0, holeWest and px0 or px1, map.h * T) -- outer side of the side path
	hedge(px0, 0, px1, 0) -- its two ends
	hedge(px0, map.h * T, px1, map.h * T)
	world.gardenSpot = garden.Position + Vector3.new(0, 4, 0)
	world.gardenSpotSide = Vector3.new(sideX, 4, map.h * T / 2)
end

-- the loft: a raised gallery along one side of a tall room, a railing, and a
-- ramp down (a ramp, so the host can follow you up)
function House.buildLoft(world)
	local L = world.map.loft
	if not L then
		return
	end
	local root = world.root
	local x0, z0, x1, z1 = L.x0 * T, L.y0 * T, (L.x1 + 1) * T, (L.y1 + 1) * T
	part(root, { Name = "Loft", Size = Vector3.new(x1 - x0, 1, z1 - z0), Position = Vector3.new((x0 + x1) / 2, L.h - 0.5, (z0 + z1) / 2), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(110, 72, 44) })
	for x = L.x0, L.x1 do
		if x ~= L.stairX then
			part(root, { Name = "Rail", Size = Vector3.new(T, 3, 0.4), Position = at(x, L.y1, L.h + 1.5) + Vector3.new(0, 0, T / 2 - 0.2), Material = Enum.Material.Wood, Color = Color3.fromRGB(70, 45, 30) })
		end
	end
	-- the ramp rises northwards (-Z) from the floor to the loft's edge
	local run = (L.stairY1 - L.stairY0 + 1) * T
	local ramp = Instance.new("WedgePart")
	ramp.Name = "LoftRamp"
	ramp.Anchored = true
	ramp.Size = Vector3.new(T - 1, L.h, run)
	-- a WedgePart is tallest at its back (+Z); turned round, tallest towards the loft
	ramp.CFrame = CFrame.new(L.stairX * T + T / 2, L.h / 2, L.stairY0 * T + run / 2) * CFrame.Angles(0, math.pi, 0)
	ramp.Material = Enum.Material.WoodPlanks
	ramp.Color = Color3.fromRGB(110, 72, 44)
	ramp.Parent = root
end

-- something searched or opened shows it: lids lift, drawers slide out, coats
-- swing aside, vases tip over, present lids pop off. withKey: a gold key
-- floats up out of it.
function House.openObject(entry, withKey)
	local info = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	if entry.style == "lid" and entry.lid then
		local target = entry.hinge * CFrame.Angles(math.rad(110), 0, 0) * entry.hinge:Inverse() * entry.lid.CFrame
		TweenService:Create(entry.lid, info, { CFrame = target }):Play()
	elseif entry.style == "drawer" and entry.drawer then
		local knob = entry.drawer:FindFirstChild("Knob")
		TweenService:Create(entry.drawer, info, { CFrame = entry.drawer.CFrame + entry.front * 2.4 }):Play()
		if knob then
			TweenService:Create(knob, info, { CFrame = knob.CFrame + entry.front * 2.4 }):Play()
		end
	elseif entry.style == "coat" and entry.coats then
		for i, c in ipairs(entry.coats) do
			local hang = c.CFrame * CFrame.new(0, c.Size.Y / 2, 0)
			TweenService:Create(c, info, { CFrame = hang * CFrame.Angles(0, 0, math.rad(i == 1 and 60 or -60)) * hang:Inverse() * c.CFrame }):Play()
		end
	elseif entry.style == "tip" and entry.tipParts then
		local pivot = entry.cf * CFrame.new(0, 0, -entry.depth / 2)
		for _, p in ipairs(entry.tipParts) do
			p.CanCollide = false
			TweenService:Create(p, TweenInfo.new(0.8, Enum.EasingStyle.Bounce), { CFrame = pivot * CFrame.Angles(math.rad(-80), 0, 0) * pivot:Inverse() * p.CFrame }):Play()
		end
	elseif entry.style == "present" and entry.lid then
		local lid = entry.lid
		local bow = lid:FindFirstChild("Bow")
		TweenService:Create(lid, info, { CFrame = lid.CFrame * CFrame.new(1.2, 2.2, 0) * CFrame.Angles(0, 0, math.rad(-35)) }):Play()
		if bow then
			TweenService:Create(bow, info, { CFrame = bow.CFrame * CFrame.new(1.2, 2.2, 0) }):Play()
		end
		task.delay(1.4, function()
			for _, p in ipairs({ lid, bow }) do
				if p and p.Parent then
					TweenService:Create(p, TweenInfo.new(0.8), { Transparency = 1 }):Play()
				end
			end
		end)
	end
	if withKey and entry.part then
		local top = entry.part.Position + Vector3.new(0, entry.part.Size.Y / 2 + 1.5, 0)
		local holder = Instance.new("Model")
		holder.Name = "FoundKey"
		holder.Parent = workspace
		local bar = part(holder, { Name = "KeyBar", Size = Vector3.new(0.4, 0.4, 2.2), CFrame = CFrame.new(top), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 210, 63), CanCollide = false })
		local bow = part(holder, { Name = "KeyBow", Shape = Enum.PartType.Ball, Size = Vector3.new(1.1, 1.1, 1.1), CFrame = CFrame.new(top + Vector3.new(0, 0, 1.3)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 210, 63), CanCollide = false })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 220, 120), 10, 2
		l.Parent = bow
		for _, p in ipairs({ bar, bow }) do
			TweenService:Create(p, TweenInfo.new(2, Enum.EasingStyle.Sine), { CFrame = p.CFrame + Vector3.new(0, 3, 0), Transparency = 0.3 }):Play()
		end
		Debris:AddItem(holder, 2.6)
	end
end

-- ---------- decorations: streamers, pictures, cobwebs, pumpkins, balloon
-- bunches, rugs. None of it is solid or blocks the host's eyes. ----------
local DECOR = { Color3.fromRGB(255, 77, 94), Color3.fromRGB(61, 139, 255), Color3.fromRGB(255, 210, 63), Color3.fromRGB(70, 209, 96), Color3.fromRGB(138, 107, 209), Color3.fromRGB(255, 138, 31) }
local PICTURES = { "\u{1F383}", "\u{1F47B}", "\u{1F987}", "\u{1F578}", "\u{1F382}", "\u{1F388}", "\u{1F315}", "\u{1F36D}" }

function House.decorate(world)
	local root, map = world.root, world.map
	local busy = {}
	for _, o in ipairs(map.objects) do
		busy[o.x .. "," .. o.y] = true
	end
	for _, s in ipairs(map.start) do
		busy[s[1] .. "," .. s[2]] = true
	end
	local function gap(x, y)
		local c = cell(map, x, y)
		return (c == "." or c == "L") and ((cell(map, x - 1, y) == "#" and cell(map, x + 1, y) == "#") or (cell(map, x, y - 1) == "#" and cell(map, x, y + 1) == "#"))
	end
	local function free(x, y)
		if cell(map, x, y) ~= "." or busy[x .. "," .. y] then
			return false
		end
		for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			if gap(x + d[1], y + d[2]) then
				return false
			end
		end
		return true
	end
	local function deco(props, class)
		local p = Instance.new(class or "Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		for k, v in pairs(props) do
			p[k] = v
		end
		p.Parent = root
		return p
	end
	local function emoji(p, face, text)
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.CanvasSize = Vector2.new(200, 200)
		sg.LightInfluence = 0.6
		sg.Parent = p
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Text = text
		t.TextTransparency = 0.15
		t.Parent = sg
	end
	for r, f in ipairs(map.floors) do
		local x0, z0, x1, z1 = f.x0 * T, f.y0 * T, (f.x1 + 1) * T, (f.y1 + 1) * T
		-- two swags of party flags across the ceiling
		for s = 0, 1 do
			local top = (f.tall and HT or H) - 1.2
			local a = Vector3.new(x0 + 1, top, s == 0 and z0 + 1 or z1 - 1)
			local b = Vector3.new(x1 - 1, top, s == 0 and z1 - 1 or z0 + 1)
			local n = math.max(2, math.floor((b - a).Magnitude / 2.6))
			local side = (b - a).Unit:Cross(Vector3.yAxis)
			for i = 0, n do
				local t = i / n
				local p = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * 2.5, 0)
				deco({ Name = "Flag", Size = Vector3.new(1.3, 1.5, 0.08), CFrame = CFrame.lookAt(p, p + side), Color = DECOR[(i + r) % #DECOR + 1], Material = Enum.Material.Fabric })
			end
		end
		-- pictures on the north wall, facing into the room
		local hung = 0
		for _, x in ipairs({ f.x0 + 2, f.x1 - 2, math.floor((f.x0 + f.x1) / 2) }) do
			if hung < 2 and cell(map, x, f.y0 - 1) == "#" and not busy[x .. "," .. (f.y0 - 1)] and cell(map, x, f.y0) ~= "#" then
				hung += 1
				local pic = deco({ Name = "Picture", Size = Vector3.new(3.4, 2.8, 0.2), Position = at(x, f.y0 - 1, 7.5) + Vector3.new(0, 0, T / 2 + 0.15), Color = Color3.fromRGB(110, 80, 40), Material = Enum.Material.Wood })
				local inner = deco({ Name = "Painting", Size = Vector3.new(2.8, 2.2, 0.05), Position = pic.Position + Vector3.new(0, 0, 0.12), Color = Color3.fromRGB(40, 30, 55) })
				emoji(inner, Enum.NormalId.Back, PICTURES[(x + r) % #PICTURES + 1])
			end
		end
		-- cobwebs in two top corners
		for _, c in ipairs({ { x0, z0, 45 }, { x1, z1, 45 } }) do
			local web = deco({ Name = "Cobweb", Size = Vector3.new(4.5, 4.5, 0.05), CFrame = CFrame.new(c[1] + (c[1] == x0 and 1.4 or -1.4), H - 1.8, c[2] + (c[2] == z0 and 1.4 or -1.4)) * CFrame.Angles(0, math.rad(c[3]), 0), Transparency = 1 })
			emoji(web, Enum.NormalId.Front, "\u{1F578}")
			emoji(web, Enum.NormalId.Back, "\u{1F578}")
		end
		-- a rug in the middle (not in the kitchen: it has its tiles)
		if f.kind ~= "tiles" then
			local w, d = (f.x1 - f.x0 + 1) * T * 0.4, (f.y1 - f.y0 + 1) * T * 0.4
			deco({ Name = "Rug", Size = Vector3.new(w, 0.1, d), Position = Vector3.new((x0 + x1) / 2, 0.06, (z0 + z1) / 2), Color = DECOR[r % #DECOR + 1], Material = Enum.Material.Fabric, Transparency = 0.15 })
		end
		-- a glowing pumpkin and a balloon bunch in free corners
		local corners = { { f.x0, f.y1 }, { f.x1, f.y0 }, { f.x1, f.y1 }, { f.x0, f.y0 } }
		local placed = 0
		for _, c in ipairs(corners) do
			if placed < 2 and free(c[1], c[2]) then
				placed += 1
				busy[c[1] .. "," .. c[2]] = true
				local base = at(c[1], c[2], 0)
				if placed == 1 then
					local pk = deco({ Name = "Pumpkin", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2, 2.4), Position = base + Vector3.new(0, 1, 0), Color = Color3.fromRGB(240, 120, 20), Material = Enum.Material.SmoothPlastic })
					deco({ Name = "Stem", Size = Vector3.new(0.3, 0.6, 0.3), Position = base + Vector3.new(0, 2.2, 0), Color = Color3.fromRGB(70, 110, 40) })
					local l = Instance.new("PointLight")
					l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 140, 40), 9, 1
					l.Parent = pk
				else
					for i = 0, 2 do
						local off = Vector3.new(math.cos(i * 2.1) * 0.9, 7 + i * 0.6, math.sin(i * 2.1) * 0.9)
						deco({ Name = "PartyBalloon", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 2.1, 1.8), Position = base + off, Color = DECOR[(i + r + c[1]) % #DECOR + 1], Material = Enum.Material.SmoothPlastic })
						deco({ Name = "String", Size = Vector3.new(0.06, off.Y - 1, 0.06), Position = base + Vector3.new(off.X / 2, (off.Y - 1) / 2, off.Z / 2), Color = Color3.fromRGB(220, 220, 220) })
					end
				end
			end
		end
	end
end

return House
