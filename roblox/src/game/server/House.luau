--[[
	House - builds the Party House in 3D from HouseMap: floors, walls, a
	ceiling, furniture, the props you interact with, lights and the garden
	safe area. Returns a table of the interactive parts by object id.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local T = Config.TILE
local H = Config.WALL_H

local House = {}

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
		local l = light(root, Vector3.new(centre.X, H - 2, centre.Z), Color3.fromRGB(255, 196, 120), math.min(60, math.max(w, d) * 0.75), 1.2)
		table.insert(world.lights, l)
	end

	-- doorway floors, walls, furniture
	for y = 0, map.h - 1 do
		for x = 0, map.w - 1 do
			local c = cell(map, x, y)
			if c == "." and floorKind(map, x, y) == "door" then
				part(root, { Name = "Doorway", Size = Vector3.new(T, 1, T), Position = at(x, y, -0.5), Material = FLOOR.door[1], Color = FLOOR.door[2] })
			elseif c == "#" or c == "C" then
				part(root, {
					Name = "Wall",
					Size = Vector3.new(T, H, T),
					Position = at(x, y, H / 2),
					Material = Enum.Material.Plaster,
					Color = Color3.fromRGB(70, 46, 96),
				})
				if c == "C" then
					-- the host's dark doorway, with eyes
					part(root, { Name = "HostDoor", Size = Vector3.new(0.4, 9, 5), Position = at(x, y, 4.5) + Vector3.new(T / 2 + 0.1, 0, 0), Color = Color3.fromRGB(5, 3, 10), Material = Enum.Material.SmoothPlastic })
					for i = -1, 1, 2 do
						part(root, { Name = "Eye", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), Position = at(x, y, 6.5) + Vector3.new(T / 2 + 0.35, 0, i * 0.7), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 50, 50), CanCollide = false })
					end
				end
			elseif c == "D" or c == "H" then
				part(root, { Name = "DoorFloor", Size = Vector3.new(T, 1, T), Position = at(x, y, -0.5), Material = FLOOR.door[1], Color = FLOOR.door[2] })
				part(root, { Name = "Lintel", Size = Vector3.new(T, H - 10, T), Position = at(x, y, 10 + (H - 10) / 2), Material = Enum.Material.Plaster, Color = Color3.fromRGB(70, 46, 96) })
			elseif c == "T" then
				local f = furnitureAt(map, x, y)
				local kind = f and f.kind or "table"
				if kind == "table" then
					part(root, { Name = "Table", Size = Vector3.new(T, 0.6, T), Position = at(x, y, 3.4), Material = Enum.Material.Fabric, Color = Color3.fromRGB(242, 233, 247) })
					part(root, { Name = "TableSkirt", Size = Vector3.new(T - 0.2, 3, T - 0.2), Position = at(x, y, 1.6), Material = Enum.Material.Fabric, Color = Color3.fromRGB(255, 138, 31) })
				elseif kind == "counter" then
					part(root, { Name = "Counter", Size = Vector3.new(T, 4, T), Position = at(x, y, 2), Material = Enum.Material.Wood, Color = Color3.fromRGB(139, 106, 79) })
					part(root, { Name = "CounterTop", Size = Vector3.new(T, 0.4, T), Position = at(x, y, 4.2), Material = Enum.Material.Marble, Color = Color3.fromRGB(207, 200, 187) })
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
	local cake = part(root, { Name = "Cake", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 3.4, 3.4), CFrame = CFrame.new(at(14, 13, 0) + Vector3.new(T / 2, 4.9, T / 2)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(247, 198, 217), Material = Enum.Material.SmoothPlastic })
	part(root, { Name = "Candle", Size = Vector3.new(0.3, 1.2, 0.3), Position = cake.Position + Vector3.new(0, 1.8, 0), Color = Color3.new(1, 1, 1) })
	part(root, { Name = "Flame", Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4), Position = cake.Position + Vector3.new(0, 2.6, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 210, 63), CanCollide = false })

	-- ceiling, so the house feels like a house
	part(root, { Name = "Ceiling", Size = Vector3.new(map.w * T, 4, map.h * T), Position = Vector3.new(map.w * T / 2, H + 2.02, map.h * T / 2), CastShadow = false, Material = Enum.Material.Plaster, Color = Color3.fromRGB(30, 20, 40) })

	House.buildObjects(world)
	House.buildGarden(world)
	return world
end

function House.buildObjects(world)
	local root, map = world.root, world.map
	for _, o in ipairs(map.objects) do
		local base = at(o.x, o.y, 0)
		local entry = { def = o }
		world.objects[o.id] = entry
		if o.kind == "door" then
			entry.door = part(root, { Name = "BigDoor", Size = Vector3.new(T, 10, 1), Position = base + Vector3.new(0, 5, T / 2 - 0.6), Material = Enum.Material.Wood, Color = Color3.fromRGB(122, 74, 30) })
			entry.keypad = part(root, { Name = "Keypad", Size = Vector3.new(1.6, 2, 0.3), Position = base + Vector3.new(2.6, 4.5, T / 2 + 0.05), Color = Color3.fromRGB(30, 30, 34) })
			for i, col in ipairs(Config.COLORS) do
				part(root, { Name = "Key", Size = Vector3.new(0.5, 0.5, 0.1), Position = entry.keypad.Position + Vector3.new(((i - 1) % 2) * 0.7 - 0.35, 0.4 - math.floor((i - 1) / 2) * 0.7, 0.18), Material = Enum.Material.Neon, Color = Config.COLOR3[col], CanCollide = false })
			end
			entry.usePrompt = prompt(entry.keypad, "Use keypad", "Big door")
			entry.pickPrompt = prompt(entry.keypad, "Pick the lock", "Tinker", 5)
			entry.pickPrompt.KeyboardKeyCode = Enum.KeyCode.F
			entry.exit = part(root, { Name = "ExitDoor", Size = Vector3.new(T, 10, 2), Position = base + Vector3.new(0, 5, -T / 2 + 1), Transparency = 1, CanCollide = false })
		elseif o.kind == "hole" then
			entry.panel = part(root, { Name = "HolePanel", Size = Vector3.new(T, 10, T), Position = base + Vector3.new(0, 5, 0), Material = Enum.Material.Plaster, Color = Color3.fromRGB(70, 46, 96) })
			entry.exit = part(root, { Name = "ExitHole", Size = Vector3.new(2, 10, T), Position = base + Vector3.new(T / 2 + 1, 5, 0), Transparency = 1, CanCollide = false })
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
			local blue = o.boost == "shield"
			entry.part = part(root, { Name = "Present", Size = Vector3.new(2.2, 2, 2.2), Position = base + Vector3.new(0, 1, 0), Color = blue and Color3.fromRGB(61, 139, 255) or Color3.fromRGB(232, 80, 91) })
			part(root, { Name = "Ribbon", Size = Vector3.new(2.3, 2.1, 0.4), Position = entry.part.Position, Color = Color3.fromRGB(255, 210, 63), CanCollide = false })
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
			entry.prompt = prompt(entry.part, "Hide", "")
			entry.prompt.HoldDuration = 0.2
		end
	end
end

function House.buildGarden(world)
	local root, map = world.root, world.map
	-- the safe area: the back garden beyond the big door (north) and round
	-- the side past the hole (east)
	local gx0, gx1 = 8, 22
	local garden = part(root, { Name = "Garden", Size = Vector3.new((gx1 - gx0) * T, 1, 6 * T), Position = Vector3.new((gx0 + gx1) / 2 * T, -0.5, -3 * T), Material = Enum.Material.Grass, Color = Color3.fromRGB(60, 110, 50) })
	part(root, { Name = "SidePath", Size = Vector3.new(4 * T, 1, map.h * T), Position = Vector3.new(map.w * T + 2 * T, -0.5, map.h * T / 2), Material = Enum.Material.Grass, Color = Color3.fromRGB(60, 110, 50) })
	for i = 0, 10 do
		local pos = Vector3.new(gx0 * T + i * (gx1 - gx0) * T / 10, 9, -5.5 * T)
		part(root, { Name = "FairyLight", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), Position = pos, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 220, 140), CanCollide = false })
	end
	light(root, garden.Position + Vector3.new(0, 10, 0), Color3.fromRGB(255, 220, 160), 60, 2)
	-- hedges you can see, and tall invisible walls so nobody walks or jumps off
	local function hedge(x0, z0, x1, z1)
		local size = Vector3.new(math.max(2, math.abs(x1 - x0)), 6, math.max(2, math.abs(z1 - z0)))
		local centre = Vector3.new((x0 + x1) / 2, 3, (z0 + z1) / 2)
		part(root, { Name = "Hedge", Size = size, Position = centre, Material = Enum.Material.LeafyGrass, Color = Color3.fromRGB(40, 80, 38) })
		part(root, { Name = "Boundary", Size = Vector3.new(size.X, 40, size.Z), Position = centre + Vector3.new(0, 20, 0), Transparency = 1 })
	end
	local gx0s, gx1s, gz = gx0 * T, gx1 * T, -6 * T
	hedge(gx0s, gz, gx0s, 0) -- west side of the garden
	hedge(gx1s, gz, gx1s, 0) -- east side
	hedge(gx0s, gz, gx1s, gz) -- far end
	local px0, px1 = map.w * T, map.w * T + 4 * T
	hedge(px1, 0, px1, map.h * T) -- outer side of the side path
	hedge(px0, 0, px1, 0) -- its two ends
	hedge(px0, map.h * T, px1, map.h * T)
	world.gardenSpot = garden.Position + Vector3.new(0, 4, 0)
	world.gardenSpotSide = Vector3.new(map.w * T + 2 * T, 4, map.h * T / 2)
end

return House
