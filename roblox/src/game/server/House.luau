--[[
	House - builds the Party House in 3D from HouseMap: floors, walls, a
	ceiling, furniture, the props you interact with, lights and the garden
	safe area. Returns a table of the interactive parts by object id.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)

local T = Config.TILE
local H = Config.WALL_H

local House = {}
-- the building's look (set by House.build from map.theme)
local wallColor = Color3.fromRGB(70, 46, 96)
local THEMES = {
	party = { wall = Color3.fromRGB(70, 46, 96), light = Color3.fromRGB(255, 196, 120), ceiling = Color3.fromRGB(30, 20, 40) },
	gummy = { wall = Color3.fromRGB(255, 150, 200), light = Color3.fromRGB(255, 200, 225), ceiling = Color3.fromRGB(255, 205, 225) },
	hospital = { wall = Color3.fromRGB(150, 172, 160), light = Color3.fromRGB(215, 235, 255), ceiling = Color3.fromRGB(70, 76, 80) },
	-- the Midnight School: old green walls, warm lamps, a cream ceiling
	school = { wall = Color3.fromRGB(86, 104, 84), light = Color3.fromRGB(255, 226, 175), ceiling = Color3.fromRGB(205, 198, 175) },
	-- the Creepy Carnival: dark red tent walls, warm bulbs, a striped tent roof
	carnival = { wall = Color3.fromRGB(122, 38, 56), light = Color3.fromRGB(255, 205, 140), ceiling = Color3.fromRGB(70, 30, 80) },
	-- the Sunken Aquarium: deep teal walls, cool blue-white light, a dark ceiling
	aquarium = { wall = Color3.fromRGB(28, 72, 96), light = Color3.fromRGB(165, 215, 255), ceiling = Color3.fromRGB(18, 38, 58) },
}
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
	mint = { Enum.Material.SmoothPlastic, Color3.fromRGB(160, 230, 200) },
	lilac = { Enum.Material.SmoothPlastic, Color3.fromRGB(205, 175, 240) },
	caramel = { Enum.Material.SmoothPlastic, Color3.fromRGB(210, 140, 70) },
	pinktiles = { Enum.Material.CeramicTiles, Color3.fromRGB(255, 190, 215) },
	whitetiles = { Enum.Material.CeramicTiles, Color3.fromRGB(222, 228, 226) },
	mintlino = { Enum.Material.SmoothPlastic, Color3.fromRGB(165, 200, 185) },
	greylino = { Enum.Material.SmoothPlastic, Color3.fromRGB(150, 156, 166) },
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

local function roomNameAt(map, x, y)
	for _, f in ipairs(map.floors) do
		if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
			return f.name
		end
	end
	return ""
end

-- what sits on a shelf, by room, in every building: food in a pantry,
-- kitchen or canteen, towels in a bathroom or linen room, toys in a nursery
-- or children's ward, files in records and offices, lockers in a locker
-- room, boxes in stores; otherwise the building's own (books, candy jars,
-- medicine)
local function shelfStyle(theme, name)
	local n = string.lower(name)
	local function has(...)
		for _, w in ipairs({ ... }) do
			if string.find(n, w, 1, true) then
				return true
			end
		end
		return false
	end
	if has("medicine", "pharmacy") then
		return "medicine"
	elseif has("pantry", "kitchen", "canteen", "taste", "cellar") then
		return "food"
	elseif has("bath", "linen", "laundry") then
		return "towels"
	elseif has("nursery", "play", "kids", "doll", "children") then
		return "toys"
	elseif has("records", "office", "study", "radio", "archive") then
		return "files"
	elseif has("locker") then
		return "lockers"
	elseif has("storage", "box", "trunk", "store", "supply", "packing", "wrapper") then
		return "boxes"
	end
	return theme == "gummy" and "candy" or theme == "hospital" and "medicine" or "books"
end

-- a shelf that matches its room (false: the building's own kind of shelf)
local function styledShelf(root, map, x, y)
	local style = shelfStyle(map.theme, roomNameAt(map, x, y))
	if style == "books" or style == "candy" or style == "medicine" then
		return false
	end
	local bodyCol = map.theme == "gummy" and Color3.fromRGB(255, 190, 215) or map.theme == "hospital" and Color3.fromRGB(232, 236, 238) or (style == "towels" and Color3.fromRGB(235, 232, 225) or Color3.fromRGB(150, 110, 70))
	if style == "lockers" then
		part(root, { Name = "Lockers", Size = Vector3.new(T, 10, T * 0.6), Position = at(x, y, 5), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 140, 170) })
		for d = -1, 1 do
			part(root, { Name = "LockerGap", Size = Vector3.new(0.1, 9.4, 0.1), Position = at(x, y, 5) + Vector3.new(d * 2.6 + 1.3, 0, T * 0.3 + 0.05), Color = Color3.fromRGB(40, 45, 55), CanCollide = false })
			part(root, { Name = "LockerVent", Size = Vector3.new(1.4, 0.8, 0.1), Position = at(x, y, 8.5) + Vector3.new(d * 2.6, 0, T * 0.3 + 0.05), Color = Color3.fromRGB(60, 70, 85), CanCollide = false })
		end
		return true
	end
	part(root, { Name = "Shelf", Size = Vector3.new(T, 10, T * 0.6), Position = at(x, y, 5), Material = (map.theme == "party" or map.theme == "school") and Enum.Material.Wood or Enum.Material.SmoothPlastic, Color = bodyCol })
	local front = T * 0.3 + 0.4
	for row = 0, 2 do
		for j = 0, 2 do
			local p = at(x, y, 1.4 + row * 3) + Vector3.new(-2.5 + j * 2.5, 0, front)
			local k = (x + j + row) % 3
			if style == "food" then
				if k == 0 then
					part(root, { Name = "Can", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 1.1, 1.1), CFrame = CFrame.new(p + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(200, 60, 50), Material = Enum.Material.Metal, CanCollide = false })
				elseif k == 1 then
					part(root, { Name = "Jar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.8, 1.3, 1.3), CFrame = CFrame.new(p + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 170, 60), Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false })
				else
					part(root, { Name = "CerealBox", Size = Vector3.new(1.6, 2.3, 0.7), Position = p + Vector3.new(0, 0.35, 0), Color = Color3.fromRGB(255, 210, 63), CanCollide = false })
				end
			elseif style == "towels" then
				for t = 0, 2 do
					part(root, { Name = "Towel", Size = Vector3.new(2, 0.5, 1.2), Position = p + Vector3.new(0, -0.4 + t * 0.55, 0), Color = ({ Color3.fromRGB(150, 200, 235), Color3.fromRGB(250, 250, 250), Color3.fromRGB(255, 190, 210) })[(t + j) % 3 + 1], Material = Enum.Material.Fabric, CanCollide = false })
				end
			elseif style == "toys" then
				if k == 0 then
					part(root, { Name = "ToyBall", Shape = Enum.PartType.Ball, Size = Vector3.new(1.5, 1.5, 1.5), Position = p, Color = Color3.fromRGB(61, 139, 255), CanCollide = false })
				elseif k == 1 then
					part(root, { Name = "ToyBlock", Size = Vector3.new(1.3, 1.3, 1.3), Position = p - Vector3.new(0, 0.1, 0), Color = Color3.fromRGB(232, 80, 91), CanCollide = false })
					part(root, { Name = "ToyBlock", Size = Vector3.new(1, 1, 1), Position = p + Vector3.new(0, 1.05, 0), Color = Color3.fromRGB(70, 209, 96), CanCollide = false })
				else
					part(root, { Name = "Teddy", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.5, 1.2), Position = p - Vector3.new(0, 0.2, 0), Color = Color3.fromRGB(160, 110, 70), Material = Enum.Material.Fabric, CanCollide = false })
					part(root, { Name = "TeddyHead", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1), Position = p + Vector3.new(0, 0.9, 0), Color = Color3.fromRGB(160, 110, 70), Material = Enum.Material.Fabric, CanCollide = false })
				end
			elseif style == "files" then
				for t = 0, 3 do
					part(root, { Name = "Folder", Size = Vector3.new(0.35, 1.9, 1.3), Position = p + Vector3.new(-0.6 + t * 0.4, 0.15, 0), Color = ({ Color3.fromRGB(230, 200, 140), Color3.fromRGB(150, 180, 220), Color3.fromRGB(230, 120, 110) })[(t + j) % 3 + 1], CanCollide = false })
				end
			else
				part(root, { Name = "Box", Size = Vector3.new(2, 1.8, 1.2), Position = p + Vector3.new(0, 0.1, 0), Color = Color3.fromRGB(180, 140, 95), Material = Enum.Material.Cardboard, CanCollide = false })
			end
		end
	end
	return true
end

local function furnitureAt(map, x, y)
	for _, f in ipairs(map.furniture) do
		if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
			return f
		end
	end
	return nil
end

-- the Gummy Bounce House's furniture: candy-jar shelves, sweet conveyors,
-- chocolate vats, gumball machines, marshmallow beds, frosted tables
local CANDY = { Color3.fromRGB(255, 77, 94), Color3.fromRGB(61, 139, 255), Color3.fromRGB(255, 210, 63), Color3.fromRGB(70, 209, 96), Color3.fromRGB(190, 110, 230), Color3.fromRGB(255, 150, 200) }
local function candyFurniture(root, kind, x, y, room, map)
	if kind == "counter" and string.find(string.lower(room or ""), "chocolate", 1, true) then
		-- a channel of flowing chocolate at floor level with caramel banks:
		-- kids can wade through it, slowly (and so can the host); the wooden
		-- bridge across the middle of each run is not slow
		for _, side in ipairs({ -1, 1 }) do
			part(root, { Name = "RiverBank", Size = Vector3.new(T, 0.5, 0.7), Position = at(x, y, 0.25) + Vector3.new(0, 0, side * (T / 2 - 0.35)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(200, 140, 70), CanCollide = false })
		end
		local river = part(root, { Name = "ChocolateRiver", Size = Vector3.new(T, 0.5, T - 1.4), Position = at(x, y, 0.2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(95, 55, 30), Reflectance = 0.15, CanCollide = false })
		local mod = Instance.new("PathfindingModifier")
		mod.Label = "Chocolate"
		mod.Parent = river
		if (x + y) % 2 == 0 then
			local mallow = part(root, { Name = "Marshmallow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.1, 1.3, 1.3), CFrame = CFrame.new(at(x, y, 0.7) - Vector3.new(T * 0.35, 0, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 245, 250), CanCollide = false, CanQuery = false })
			TweenService:Create(mallow, TweenInfo.new(3 + (x % 3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = CFrame.new(at(x, y, 0.7) + Vector3.new(T * 0.35, 0, 0)) * CFrame.Angles(0, math.rad(40), math.rad(90)) }):Play()
		end
		-- the middle tile of a run of river: a little wooden footbridge across it
		local function isRiver(cx, cy)
			if cell(map, cx, cy) ~= "T" then
				return false
			end
			local f = furnitureAt(map, cx, cy)
			return f ~= nil and f.kind == "counter"
		end
		local x0, x1 = x, x
		while isRiver(x0 - 1, y) do
			x0 -= 1
		end
		while isRiver(x1 + 1, y) do
			x1 += 1
		end
		if x == math.floor((x0 + x1) / 2) then
			local wood = Color3.fromRGB(150, 100, 60)
			part(root, { Name = "ChocolateBridge", Size = Vector3.new(3.6, 0.3, T + 0.4), Position = at(x, y, 0.75), Material = Enum.Material.WoodPlanks, Color = wood })
			for _, side in ipairs({ -1, 1 }) do
				-- a gentle ramp at each end, and a rail along each side
				local ramp = Instance.new("WedgePart")
				ramp.Anchored, ramp.CanQuery = true, true
				ramp.Name = "ChocolateBridge"
				ramp.Size = Vector3.new(3.6, 0.9, 1.8)
				ramp.Material, ramp.Color = Enum.Material.WoodPlanks, wood
				ramp.CFrame = CFrame.new(at(x, y, 0.45) + Vector3.new(0, 0, side * (T / 2 + 1.1))) * CFrame.Angles(0, side < 0 and 0 or math.pi, 0)
				ramp.Parent = root
				part(root, { Name = "BridgeRail", Size = Vector3.new(0.25, 1.4, T), Position = at(x, y, 1.6) + Vector3.new(side * 1.7, 0, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 80, 45), CanCollide = false, CanQuery = false })
			end
		end
		return
	end
	if kind == "shelf" then
		part(root, { Name = "CandyShelf", Size = Vector3.new(T, 10, T * 0.6), Position = at(x, y, 5), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 190, 215) })
		for row = 0, 2 do
			for j = 0, 2 do
				local p = at(x, y, 2 + row * 3) + Vector3.new(-2.6 + j * 2.6, 0, T * 0.3 + 0.5)
				part(root, { Name = "CandyJar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2, 1.9, 1.9), CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Glass, Color = Color3.fromRGB(220, 240, 255), Transparency = 0.5, CanCollide = false })
				part(root, { Name = "Candy", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), Position = p - Vector3.new(0, 0.3, 0), Color = CANDY[(x + j + row) % #CANDY + 1], Material = Enum.Material.SmoothPlastic, CanCollide = false })
			end
		end
	elseif kind == "counter" then
		part(root, { Name = "Conveyor", Size = Vector3.new(T, 3.4, T), Position = at(x, y, 1.7), Material = Enum.Material.Metal, Color = Color3.fromRGB(190, 195, 205) })
		local belt = part(root, { Name = "Belt", Size = Vector3.new(T, 0.3, T * 0.8), Position = at(x, y, 3.55), Material = Enum.Material.Rubber, Color = Color3.fromRGB(40, 40, 46) })
		-- in the factory rooms the belts really move: stand on one and ride
		local r = string.lower(room or "")
		if string.find(r, "conveyor", 1, true) or string.find(r, "factory", 1, true) or string.find(r, "wrapper", 1, true) then
			belt.AssemblyLinearVelocity = Vector3.new(y % 2 == 0 and 9 or -9, 0, 0)
		end
		for j = -1, 1 do
			part(root, { Name = "Sweet", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), Position = at(x, y, 4.3) + Vector3.new(j * 2.5, 0, ((x + j) % 2) - 0.5), Color = CANDY[(x + j + 2) % #CANDY + 1], Material = Enum.Material.SmoothPlastic, CanCollide = false })
		end
	elseif kind == "bath" then
		part(root, { Name = "ChocolateVat", Size = Vector3.new(T, 3.4, T), Position = at(x, y, 1.7), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 205, 215) })
		part(root, { Name = "Chocolate", Size = Vector3.new(T - 1, 0.2, T - 1), Position = at(x, y, 3.35), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(95, 55, 30) })
	elseif kind == "desk" then
		part(root, { Name = "GumballStand", Size = Vector3.new(T * 0.6, 3, T * 0.6), Position = at(x, y, 1.5), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(230, 50, 60) })
		part(root, { Name = "GumballGlobe", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), Position = at(x, y, 5), Material = Enum.Material.Glass, Color = Color3.fromRGB(230, 245, 255), Transparency = 0.5, CanCollide = false })
		for j = 1, 6 do
			part(root, { Name = "Gumball", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), Position = at(x, y, 4.4) + Vector3.new(math.cos(j) * 0.9, (j % 3) * 0.5, math.sin(j * 1.3) * 0.9), Color = CANDY[j % #CANDY + 1], Material = Enum.Material.SmoothPlastic, CanCollide = false })
		end
	elseif kind == "bed" then
		part(root, { Name = "MarshmallowBed", Size = Vector3.new(T, 2.4, T), Position = at(x, y, 1.2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(252, 248, 252) })
		part(root, { Name = "Pillow", Size = Vector3.new(T * 0.7, 0.8, 2), Position = at(x, y, 2.8), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 180, 210), CanCollide = false })
	else
		part(root, { Name = "Table", Size = Vector3.new(T, 0.6, T), Position = at(x, y, 3.4), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 232, 242) })
		part(root, { Name = "TableSkirt", Size = Vector3.new(T - 0.2, 3, T - 0.2), Position = at(x, y, 1.6), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(150, 210, 255) })
	end
end

-- the school's tables and desks: wooden tops on metal legs, little desks
-- with a chair each (everything else is the Party House's own furniture)
local function schoolFurniture(root, kind, x, y)
	local wood, steel = Color3.fromRGB(176, 128, 78), Color3.fromRGB(120, 125, 132)
	if kind == "desk" then
		for _, dx in ipairs({ -1.9, 1.9 }) do
			part(root, { Name = "SchoolDesk", Size = Vector3.new(3.2, 0.3, 2.4), Position = at(x, y, 2.9) + Vector3.new(dx, 0, -0.6), Material = Enum.Material.Wood, Color = wood })
			part(root, { Name = "DeskFrame", Size = Vector3.new(3, 2.7, 0.2), Position = at(x, y, 1.4) + Vector3.new(dx, 0, -1.6), Material = Enum.Material.Metal, Color = steel })
			part(root, { Name = "SchoolChair", Size = Vector3.new(1.8, 0.25, 1.6), Position = at(x, y, 1.7) + Vector3.new(dx, 0, 1.5), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(70, 110, 170), CanCollide = false })
			part(root, { Name = "ChairBack", Size = Vector3.new(1.8, 1.6, 0.2), Position = at(x, y, 2.6) + Vector3.new(dx, 0, 2.3), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(70, 110, 170), CanCollide = false })
		end
		-- a solid block where the desks stand, so nobody walks through them
		part(root, { Name = "DeskBlock", Size = Vector3.new(T, 2.9, T * 0.55), Position = at(x, y, 1.45) + Vector3.new(0, 0, -0.6), Transparency = 1 })
		return true
	elseif kind == "table" then
		part(root, { Name = "Table", Size = Vector3.new(T, 0.5, T), Position = at(x, y, 3.3), Material = Enum.Material.Wood, Color = wood })
		for _, o in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
			part(root, { Name = "TableLeg", Size = Vector3.new(0.4, 3.05, 0.4), Position = at(x, y, 1.53) + Vector3.new(o[1] * (T / 2 - 0.5), 0, o[2] * (T / 2 - 0.5)), Material = Enum.Material.Metal, Color = steel })
		end
		part(root, { Name = "TableBlock", Size = Vector3.new(T - 0.6, 3, T - 0.6), Position = at(x, y, 1.5), Transparency = 1 })
		return true
	end
	return false
end

-- the Carnival's furniture: striped stalls, popcorn carts, a duck pond, a
-- clown car, circus seats, a band stage; the carousel and the spinning floor
-- turn slowly and carry you round if you hop on (built once, from their corner)
local CARNIVAL_STRIPES = { Color3.fromRGB(220, 40, 60), Color3.fromRGB(250, 240, 225) }
local function spin(parts, centre, speed, platform)
	-- every part keeps its place relative to the centre while the whole thing turns
	local offsets = {}
	for _, pt in ipairs(parts) do
		offsets[pt] = CFrame.new(centre):ToObjectSpace(pt.CFrame)
	end
	if platform then
		platform.AssemblyAngularVelocity = Vector3.new(0, speed, 0) -- carries anyone standing on it
	end
	local angle = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not platform or not platform.Parent then
			conn:Disconnect()
			return
		end
		angle += dt * speed
		local base = CFrame.new(centre) * CFrame.Angles(0, angle, 0)
		for pt, off in pairs(offsets) do
			pt.CFrame = base * off
		end
	end)
end
local function carnivalFurniture(root, kind, x, y, map)
	local f = furnitureAt(map, x, y)
	if kind == "carousel" or kind == "spinner" then
		if not f or x ~= f.x0 or y ~= f.y0 then
			return true -- built once, from the corner tile
		end
		local centre = at(f.x0 + 1, f.y0 + 1, 0)
		local r = (f.x1 - f.x0 + 1) * T / 2 - 0.4
		local moving = {}
		local function bit(props, moves)
			local b = part(root, props)
			if moves ~= false then
				table.insert(moving, b)
			end
			return b
		end
		local up = CFrame.Angles(0, 0, math.rad(90))
		if kind == "carousel" then
			local platform = bit({ Name = "CarouselFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, r * 2, r * 2), CFrame = CFrame.new(centre + Vector3.new(0, 0.3, 0)) * up, Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 60, 70) })
			bit({ Name = "CarouselPole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(11, 2.2, 2.2), CFrame = CFrame.new(centre + Vector3.new(0, 6, 0)) * up, Material = Enum.Material.Foil, Color = Color3.fromRGB(230, 190, 80) })
			bit({ Name = "CarouselRoof", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, r * 2 + 1, r * 2 + 1), CFrame = CFrame.new(centre + Vector3.new(0, 11.6, 0)) * up, Material = Enum.Material.Fabric, Color = Color3.fromRGB(220, 40, 60), CanCollide = false })
			bit({ Name = "CarouselTop", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 3, 5), CFrame = CFrame.new(centre + Vector3.new(0, 12.6, 0)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(250, 240, 225), CanCollide = false })
			-- six painted horses (and a pumpkin coach) on golden poles, bobbing gently
			local cols = { Color3.fromRGB(250, 245, 235), Color3.fromRGB(120, 80, 170), Color3.fromRGB(255, 150, 60), Color3.fromRGB(90, 170, 220), Color3.fromRGB(240, 120, 170), Color3.fromRGB(120, 200, 120) }
			for i = 1, 6 do
				local a = i / 6 * math.pi * 2
				local p0 = centre + Vector3.new(math.cos(a) * r * 0.68, 0, math.sin(a) * r * 0.68)
				local face = CFrame.lookAt(p0, p0 + Vector3.new(-math.sin(a), 0, math.cos(a)))
				local function h(size, off, col, mat)
					return bit({ Name = "Horse", Size = size, CFrame = face * CFrame.new(off), Color = col, Material = mat or Enum.Material.SmoothPlastic, CanCollide = false })
				end
				bit({ Name = "HorsePole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(11, 0.35, 0.35), CFrame = CFrame.new(p0 + Vector3.new(0, 6, 0)) * up, Material = Enum.Material.Foil, Color = Color3.fromRGB(230, 190, 80), CanCollide = false })
				h(Vector3.new(1.3, 1.5, 3.2), Vector3.new(0, 3.6, 0), cols[i])
				h(Vector3.new(0.9, 1.7, 1), Vector3.new(0, 4.7, -1.5), cols[i])
				h(Vector3.new(0.8, 0.8, 1.4), Vector3.new(0, 5.4, -2.1), cols[i])
				h(Vector3.new(0.3, 1.2, 0.8), Vector3.new(0, 5.6, -1.2), Color3.fromRGB(230, 190, 80), Enum.Material.Foil) -- mane
				h(Vector3.new(1.4, 0.3, 1.2), Vector3.new(0, 4.45, 0.2), Color3.fromRGB(200, 40, 60)) -- saddle
				for _, lx in ipairs({ -0.45, 0.45 }) do
					for _, lz in ipairs({ -1.2, 1.2 }) do
						h(Vector3.new(0.3, 1.8, 0.3), Vector3.new(lx, 2.2, lz), cols[i])
					end
				end
			end
			-- bulbs round the roof
			for i = 1, 12 do
				local a = i / 12 * math.pi * 2
				local bulb = bit({ Name = "Bulb", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), CFrame = CFrame.new(centre + Vector3.new(math.cos(a) * (r + 0.4), 11.1, math.sin(a) * (r + 0.4))), Material = Enum.Material.Neon, Color = i % 2 == 0 and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(190, 110, 230), CanCollide = false })
				if i % 4 == 0 then
					local l = Instance.new("PointLight")
					l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 200, 120), 14, 0.6
					l.Parent = bulb
				end
			end
			spin(moving, centre, 0.35, platform)
		else
			-- the Spinning Room's floor: a big turning disc with a swirl on it
			local platform = bit({ Name = "SpinnerFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, r * 2, r * 2), CFrame = CFrame.new(centre + Vector3.new(0, 0.2, 0)) * up, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(110, 60, 160) })
			for i = 1, 8 do
				local a = i / 8 * math.pi * 2
				bit({ Name = "Swirl", Size = Vector3.new(r * 0.9, 0.05, 1.2), CFrame = CFrame.new(centre + Vector3.new(math.cos(a) * r * 0.45, 0.43, math.sin(a) * r * 0.45)) * CFrame.Angles(0, -a + 0.6, 0), Material = Enum.Material.Neon, Color = i % 2 == 0 and Color3.fromRGB(255, 210, 63) or Color3.fromRGB(250, 245, 235), CanCollide = false })
			end
			bit({ Name = "SpinnerHub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 3, 3), CFrame = CFrame.new(centre + Vector3.new(0, 0.45, 0)) * up, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 80, 120), CanCollide = false })
			spin(moving, centre, 0.9, platform)
		end
		return true
	end
	if kind == "stall" then
		-- a game stall: a striped counter under a striped awning, prizes behind
		part(root, { Name = "StallCounter", Size = Vector3.new(T, 3.6, T * 0.5), Position = at(x, y, 1.8), Material = Enum.Material.SmoothPlastic, Color = CARNIVAL_STRIPES[x % 2 + 1] })
		part(root, { Name = "StallTop", Size = Vector3.new(T, 0.3, T * 0.6), Position = at(x, y, 3.75), Material = Enum.Material.Wood, Color = Color3.fromRGB(150, 100, 60) })
		part(root, { Name = "Awning", Size = Vector3.new(T, 0.3, T * 0.7), CFrame = CFrame.new(at(x, y, 8.5)) * CFrame.Angles(math.rad(-15), 0, 0), Material = Enum.Material.Fabric, Color = CARNIVAL_STRIPES[(x + 1) % 2 + 1], CanCollide = false })
		for i = -1, 1 do
			part(root, { Name = "Bottle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 0.6, 0.6), CFrame = CFrame.new(at(x, y, 4.5) + Vector3.new(i * 1.8, 0, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Glass, Color = Color3.fromRGB(90, 170, 120), Transparency = 0.2, CanCollide = false })
		end
		return true
	elseif kind == "counter" then
		-- a popcorn / toffee-apple cart: a red cart with a glass box of treats
		part(root, { Name = "Cart", Size = Vector3.new(T, 3.4, T * 0.8), Position = at(x, y, 1.7), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(200, 40, 50) })
		part(root, { Name = "CartTrim", Size = Vector3.new(T + 0.1, 0.4, T * 0.8 + 0.1), Position = at(x, y, 3.2), Material = Enum.Material.Foil, Color = Color3.fromRGB(230, 190, 80) })
		part(root, { Name = "TreatBox", Size = Vector3.new(T * 0.8, 2.6, T * 0.6), Position = at(x, y, 4.7), Material = Enum.Material.Glass, Color = Color3.fromRGB(220, 235, 240), Transparency = 0.6 })
		for i = 1, 6 do
			part(root, { Name = "Popcorn", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), Position = at(x, y, 3.9) + Vector3.new(math.cos(i * 2.1) * 1.8, (i % 3) * 0.35, math.sin(i * 1.3) * 1.1), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 236, 170), CanCollide = false })
		end
		return true
	elseif kind == "table" then
		part(root, { Name = "Table", Size = Vector3.new(T, 0.5, T), Position = at(x, y, 3.3), Material = Enum.Material.Wood, Color = Color3.fromRGB(150, 100, 60) })
		part(root, { Name = "TableSkirt", Size = Vector3.new(T - 0.2, 3, T - 0.2), Position = at(x, y, 1.6), Material = Enum.Material.Fabric, Color = CARNIVAL_STRIPES[(x + y) % 2 + 1] })
		return true
	elseif kind == "pond" then
		-- the duck pond: a round rim of water with little yellow ducks bobbing
		part(root, { Name = "PondRim", Size = Vector3.new(T, 2.4, T), Position = at(x, y, 1.2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(60, 110, 200) })
		local water = part(root, { Name = "PondWater", Size = Vector3.new(T - 1, 0.2, T - 1), Position = at(x, y, 2.45), Material = Enum.Material.Glass, Color = Color3.fromRGB(90, 190, 230), Transparency = 0.2, CanCollide = false })
		local _ = water
		local duck = part(root, { Name = "Duck", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.2, 1.4), Position = at(x, y, 3) + Vector3.new((x % 3 - 1) * 1.5, 0, (y % 2) * 1.5 - 0.7), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 215, 50), CanCollide = false })
		part(root, { Name = "DuckHead", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), Position = duck.Position + Vector3.new(0, 0.7, 0.4), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 215, 50), CanCollide = false })
		TweenService:Create(duck, TweenInfo.new(1.4 + (x % 3) * 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = duck.Position + Vector3.new(0, 0.25, 0) }):Play()
		return true
	elseif kind == "car" then
		-- the clown car: tiny, bright, with huge wheels
		if not f or x ~= f.x0 or y ~= f.y0 then
			part(root, { Name = "CarBlock", Size = Vector3.new(T, 4, T), Position = at(x, y, 2), Transparency = 1 })
			return true
		end
		local c = (at(f.x0, f.y0, 0) + at(f.x1, f.y1, 0)) / 2
		part(root, { Name = "ClownCar", Size = Vector3.new(T * 2 - 2, 3, T * 1.3), Position = c + Vector3.new(0, 2.6, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 200, 40), CanCollide = false })
		part(root, { Name = "ClownCarTop", Size = Vector3.new(T - 1, 2.4, T * 1.1), Position = c + Vector3.new(-1, 5.2, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(80, 170, 230), CanCollide = false })
		for _, wx in ipairs({ -1, 1 }) do
			for _, wz in ipairs({ -1, 1 }) do
				part(root, { Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 2.6, 2.6), CFrame = CFrame.new(c + Vector3.new(wx * (T - 2.5), 1.3, wz * (T * 0.65))) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(230, 50, 60), CanCollide = false })
			end
		end
		part(root, { Name = "Horn", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1), Position = c + Vector3.new(T - 1.5, 4.4, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(230, 50, 60), CanCollide = false })
		part(root, { Name = "CarBlock", Size = Vector3.new(T, 4, T), Position = at(x, y, 2), Transparency = 1 })
		return true
	elseif kind == "seats" then
		-- circus seats: three rising benches in red and blue
		for i = 0, 2 do
			part(root, { Name = "Bench", Size = Vector3.new(T, 1.2 + i * 1.2, T / 3), Position = at(x, y, (1.2 + i * 1.2) / 2) + Vector3.new(0, 0, (i - 1) * T / 3), Material = Enum.Material.Wood, Color = (i + x) % 2 == 0 and Color3.fromRGB(200, 40, 60) or Color3.fromRGB(60, 90, 180) })
		end
		return true
	elseif kind == "stage" then
		part(root, { Name = "BandStage", Size = Vector3.new(T, 2, T), Position = at(x, y, 1), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 90, 55) })
		part(root, { Name = "StageEdge", Size = Vector3.new(T, 0.4, T), Position = at(x, y, 2.2), Material = Enum.Material.Fabric, Color = CARNIVAL_STRIPES[(x + y) % 2 + 1] })
		if (x + y) % 3 == 0 then
			part(root, { Name = "BigDrum", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 3.4, 3.4), CFrame = CFrame.new(at(x, y, 4.1)) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(250, 240, 225), CanCollide = false })
		end
		return true
	end
	return false
end

-- the Aquarium's furniture: fish tanks, a great round tank with a shark
-- circling, a touch pool, kelp, a little submarine, a whale's bones, coral, a
-- whirlpool you can stand on (it turns), rock pools
local FISH = { Color3.fromRGB(255, 140, 40), Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 170, 255), Color3.fromRGB(255, 90, 140), Color3.fromRGB(120, 230, 160) }
local WATER = Color3.fromRGB(60, 150, 210)
local function fishIn(root, centre, spread, n, seed)
	for i = 1, n do
		local col = FISH[(seed + i) % #FISH + 1]
		local p0 = centre + Vector3.new(math.cos(i * 2.3 + seed) * spread.X, math.sin(i * 1.7) * spread.Y, math.sin(i * 2.3 + seed) * spread.Z)
		local fish = part(root, { Name = "Fish", Size = Vector3.new(0.9, 0.5, 0.25), Position = p0, Color = col, Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false, CastShadow = false })
		part(root, { Name = "FishTail", Size = Vector3.new(0.3, 0.4, 0.1), Position = p0 - Vector3.new(0.55, 0, 0), Color = col, Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = false, CastShadow = false }).Parent = fish
		TweenService:Create(fish, TweenInfo.new(2.4 + (i % 3) * 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = p0 + Vector3.new(spread.X * 0.8, 0.2, 0) }):Play()
	end
end
local function aquariumFurniture(root, kind, x, y, map)
	local f = furnitureAt(map, x, y)
	local room = string.lower(roomNameAt(map, x, y))
	if kind == "tank" or kind == "counter" then
		-- a fish tank on a cabinet: blue water, sand, weed and fish
		part(root, { Name = "TankCabinet", Size = Vector3.new(T, 2.6, T * 0.7), Position = at(x, y, 1.3), Material = Enum.Material.Wood, Color = Color3.fromRGB(60, 50, 45) })
		part(root, { Name = "Tank", Size = Vector3.new(T - 0.2, 4.4, T * 0.7 - 0.2), Position = at(x, y, 4.85), Material = Enum.Material.Glass, Color = WATER, Transparency = 0.55 })
		part(root, { Name = "TankSand", Size = Vector3.new(T - 0.4, 0.4, T * 0.7 - 0.4), Position = at(x, y, 2.85), Material = Enum.Material.Sand, Color = Color3.fromRGB(230, 205, 150), CanCollide = false })
		part(root, { Name = "TankLight", Size = Vector3.new(T - 0.2, 0.3, T * 0.7 - 0.2), Position = at(x, y, 7.2), Material = Enum.Material.Neon, Color = Color3.fromRGB(170, 220, 255), CanCollide = false })
		part(root, { Name = "Weed", Size = Vector3.new(0.3, 2.4, 0.3), Position = at(x, y, 4.2) + Vector3.new((x % 3 - 1) * 2, 0, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(60, 160, 80), CanCollide = false })
		fishIn(root, at(x, y, 4.9), Vector3.new(1.6, 0.8, 0.8), 3, x + y)
		return true
	elseif kind == "table" then
		part(root, { Name = "Table", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, T - 1, T - 1), CFrame = CFrame.new(at(x, y, 3.2)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 240, 235) })
		part(root, { Name = "TableLeg", Size = Vector3.new(0.6, 3, 0.6), Position = at(x, y, 1.5), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 125, 132) })
		part(root, { Name = "TableBlock", Size = Vector3.new(T - 1.2, 3, T - 1.2), Position = at(x, y, 1.5), Transparency = 1 })
		return true
	elseif kind == "shelf" and string.find(room, "kelp", 1, true) then
		-- tall waving kelp
		for i = -1, 1 do
			local k = part(root, { Name = "Kelp", Size = Vector3.new(0.6, 9 + (x + i) % 3, 0.3), Position = at(x, y, 4.8) + Vector3.new(i * 2.2, 0, (i % 2) * 1.2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(60, 140 + i * 15, 70), CanCollide = false })
			TweenService:Create(k, TweenInfo.new(2 + (x % 3) * 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Orientation = Vector3.new(0, 0, 8) }):Play()
		end
		part(root, { Name = "KelpRock", Size = Vector3.new(T, 1.6, T * 0.6), Position = at(x, y, 0.8), Material = Enum.Material.Slate, Color = Color3.fromRGB(70, 75, 85) })
		part(root, { Name = "KelpBlock", Size = Vector3.new(T, 8, T * 0.6), Position = at(x, y, 4), Transparency = 1 })
		return true
	elseif kind == "pond" or kind == "rockpool" then
		-- a touch pool / rock pool: a low rocky rim, water, starfish
		part(root, { Name = "PoolRim", Size = Vector3.new(T, 2.2, T), Position = at(x, y, 1.1), Material = Enum.Material.Slate, Color = Color3.fromRGB(95, 100, 110) })
		part(root, { Name = "PoolWater", Size = Vector3.new(T - 1, 0.2, T - 1), Position = at(x, y, 2.25), Material = Enum.Material.Glass, Color = WATER, Transparency = 0.25, CanCollide = false })
		part(root, { Name = "Starfish", Size = Vector3.new(1.4, 0.2, 1.4), CFrame = CFrame.new(at(x, y, 2.4) + Vector3.new((x % 3 - 1) * 1.5, 0, (y % 2) * 1.4 - 0.7)) * CFrame.Angles(0, math.rad(45), 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 120, 70), CanCollide = false })
		return true
	elseif kind == "bigtank" or kind == "whirlpool" then
		if not f or x ~= f.x0 or y ~= f.y0 then
			return true -- built once, from the corner tile
		end
		local centre = at(f.x0 + 1, f.y0 + 1, 0)
		local r = (f.x1 - f.x0 + 1) * T / 2 - 0.4
		local up = CFrame.Angles(0, 0, math.rad(90))
		if kind == "bigtank" then
			-- the great round tank: a glass drum of water, a sandy floor, a shark circling
			part(root, { Name = "BigTankBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, r * 2 + 0.6, r * 2 + 0.6), CFrame = CFrame.new(centre + Vector3.new(0, 0.6, 0)) * up, Material = Enum.Material.Slate, Color = Color3.fromRGB(60, 70, 80) })
			part(root, { Name = "BigTank", Shape = Enum.PartType.Cylinder, Size = Vector3.new(H - 1.4, r * 2, r * 2), CFrame = CFrame.new(centre + Vector3.new(0, 1.2 + (H - 1.4) / 2, 0)) * up, Material = Enum.Material.Glass, Color = WATER, Transparency = 0.6 })
			local swim = {}
			local function bit(props)
				local b = part(root, props)
				b.CanCollide, b.CanQuery, b.CastShadow = false, false, false
				table.insert(swim, b)
				return b
			end
			local sp = centre + Vector3.new(r * 0.6, 6.5, 0)
			local body = bit({ Name = "Shark", Size = Vector3.new(1.6, 1.4, 5), Position = sp, Color = Color3.fromRGB(120, 135, 150), Material = Enum.Material.SmoothPlastic })
			bit({ Name = "SharkFin", Size = Vector3.new(0.3, 1.4, 1.2), Position = sp + Vector3.new(0, 1.2, 0.3), Color = Color3.fromRGB(110, 125, 140), Material = Enum.Material.SmoothPlastic })
			bit({ Name = "SharkTail", Size = Vector3.new(0.3, 1.8, 1), Position = sp + Vector3.new(0, 0.2, 2.9), Color = Color3.fromRGB(110, 125, 140), Material = Enum.Material.SmoothPlastic })
			bit({ Name = "SharkBelly", Size = Vector3.new(1.4, 0.5, 4.4), Position = sp + Vector3.new(0, -0.6, -0.2), Color = Color3.fromRGB(235, 235, 230), Material = Enum.Material.SmoothPlastic })
			for i = -1, 1, 2 do
				bit({ Name = "SharkEye", Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Position = sp + Vector3.new(i * 0.75, 0.3, -2), Color = Color3.fromRGB(20, 20, 25), Material = Enum.Material.SmoothPlastic })
			end
			spin(swim, centre, 0.4, body)
			fishIn(root, centre + Vector3.new(0, 4, 0), Vector3.new(r * 0.5, 2, r * 0.5), 6, x)
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = Color3.fromRGB(120, 200, 255), 24, 1
			l.Parent = body
		else
			-- the Pump Room's whirlpool: a swirling disc of water that turns you round
			local moving = {}
			local function bit(props)
				local b = part(root, props)
				table.insert(moving, b)
				return b
			end
			local platform = bit({ Name = "Whirlpool", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, r * 2, r * 2), CFrame = CFrame.new(centre + Vector3.new(0, 0.2, 0)) * up, Material = Enum.Material.Glass, Color = WATER, Transparency = 0.15 })
			for i = 1, 8 do
				local a = i / 8 * math.pi * 2
				bit({ Name = "Swirl", Size = Vector3.new(r * 0.9, 0.05, 1), CFrame = CFrame.new(centre + Vector3.new(math.cos(a) * r * 0.45, 0.43, math.sin(a) * r * 0.45)) * CFrame.Angles(0, -a + 0.6, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(200, 240, 255), CanCollide = false })
			end
			spin(moving, centre, 0.9, platform)
		end
		return true
	elseif kind == "sub" then
		-- a little yellow submarine with a porthole
		if not f or x ~= f.x0 or y ~= f.y0 then
			part(root, { Name = "SubBlock", Size = Vector3.new(T, 5, T), Position = at(x, y, 2.5), Transparency = 1 })
			return true
		end
		local c = (at(f.x0, f.y0, 0) + at(f.x1, f.y1, 0)) / 2
		part(root, { Name = "Submarine", Shape = Enum.PartType.Cylinder, Size = Vector3.new(T * 2 - 1, 4.6, 4.6), CFrame = CFrame.new(c + Vector3.new(0, 2.6, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 205, 40), CanCollide = false })
		part(root, { Name = "SubTower", Size = Vector3.new(3, 2.4, 2.4), Position = c + Vector3.new(0, 5.4, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 205, 40), CanCollide = false })
		part(root, { Name = "Porthole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.8, 1.8), CFrame = CFrame.new(c + Vector3.new(-2, 2.8, -2.3)) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Glass, Color = Color3.fromRGB(150, 210, 240), CanCollide = false })
		part(root, { Name = "SubBlock", Size = Vector3.new(T, 5, T), Position = at(x, y, 2.5), Transparency = 1 })
		return true
	elseif kind == "bones" then
		-- a whale's skeleton laid out on a plinth: a backbone and arching ribs
		part(root, { Name = "Plinth", Size = Vector3.new(T, 1.2, T), Position = at(x, y, 0.6), Material = Enum.Material.Slate, Color = Color3.fromRGB(70, 75, 85) })
		part(root, { Name = "Backbone", Size = Vector3.new(T, 1.2, 1.2), Position = at(x, y, 1.8), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(235, 228, 210) })
		for i = -1, 1, 2 do
			part(root, { Name = "Rib", Size = Vector3.new(0.5, 4, 0.5), CFrame = CFrame.new(at(x, y, 3.2) + Vector3.new(0, 0, i * 1.4)) * CFrame.Angles(math.rad(i * 30), 0, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(235, 228, 210), CanCollide = false })
		end
		return true
	elseif kind == "coral" then
		part(root, { Name = "Reef", Size = Vector3.new(T, 1.6, T), Position = at(x, y, 0.8), Material = Enum.Material.Slate, Color = Color3.fromRGB(80, 70, 90) })
		local cols = { Color3.fromRGB(255, 110, 140), Color3.fromRGB(255, 170, 60), Color3.fromRGB(170, 110, 255), Color3.fromRGB(90, 220, 200) }
		for i = 1, 4 do
			part(root, { Name = "Coral", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 2.4, 1.8), Position = at(x, y, 2.6) + Vector3.new(math.cos(i * 1.7) * 2, (i % 2) * 0.6, math.sin(i * 1.7) * 2), Material = Enum.Material.Neon, Color = cols[(x + i) % 4 + 1], CanCollide = false })
		end
		return true
	end
	return false
end

-- the hospital's furniture: medicine cabinets, a reception counter, steel
-- tables and desks, beds with rails
local function hospitalFurniture(root, kind, x, y)
	if kind == "shelf" then
		part(root, { Name = "MedicineCabinet", Size = Vector3.new(T, 10, T * 0.6), Position = at(x, y, 5), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(232, 236, 238) })
		local boxes = { Color3.fromRGB(250, 250, 250), Color3.fromRGB(170, 205, 235), Color3.fromRGB(175, 220, 190), Color3.fromRGB(240, 200, 120) }
		for row = 0, 2 do
			for b = 0, 4 do
				part(root, { Name = "MedicineBox", Size = Vector3.new(1.1, 1.3, 0.8), Position = at(x, y, 1.4 + row * 3) + Vector3.new(-2.8 + b * 1.4, 0, T * 0.3 + 0.3), Color = boxes[((x + b + row) % #boxes) + 1], CanCollide = false })
			end
		end
	elseif kind == "counter" then
		part(root, { Name = "ReceptionCounter", Size = Vector3.new(T, 4, T), Position = at(x, y, 2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(165, 200, 185) })
		part(root, { Name = "CounterTop", Size = Vector3.new(T, 0.4, T), Position = at(x, y, 4.2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 242, 242) })
	elseif kind == "bed" then
		part(root, { Name = "BedFrame", Size = Vector3.new(T, 1.4, T), Position = at(x, y, 0.7), Material = Enum.Material.Metal, Color = Color3.fromRGB(185, 190, 196) })
		part(root, { Name = "Mattress", Size = Vector3.new(T - 0.6, 1, T - 0.6), Position = at(x, y, 1.9), Material = Enum.Material.Fabric, Color = Color3.fromRGB(245, 247, 250) })
		part(root, { Name = "Pillow", Size = Vector3.new(T * 0.6, 0.6, 1.6), Position = at(x, y, 2.7), Material = Enum.Material.Fabric, Color = Color3.fromRGB(255, 255, 255), CanCollide = false })
		part(root, { Name = "BedRail", Size = Vector3.new(T, 1, 0.2), Position = at(x, y, 3) + Vector3.new(0, 0, T / 2 - 0.2), Material = Enum.Material.Metal, Color = Color3.fromRGB(185, 190, 196), CanCollide = false })
	elseif kind == "desk" then
		part(root, { Name = "Desk", Size = Vector3.new(T, 0.4, T * 0.7), Position = at(x, y, 3.6), Material = Enum.Material.Metal, Color = Color3.fromRGB(175, 180, 186) })
		part(root, { Name = "DeskBody", Size = Vector3.new(T * 0.9, 3.4, T * 0.6), Position = at(x, y, 1.7), Material = Enum.Material.Metal, Color = Color3.fromRGB(140, 146, 152) })
	elseif kind == "bath" then
		part(root, { Name = "Tub", Size = Vector3.new(T, 3, T), Position = at(x, y, 1.5), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 242, 245) })
	else
		part(root, { Name = "SteelTable", Size = Vector3.new(T, 0.6, T), Position = at(x, y, 3.4), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 205, 210) })
		for _, o in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
			part(root, { Name = "TableLeg", Size = Vector3.new(0.4, 3.1, 0.4), Position = at(x, y, 1.55) + Vector3.new(o[1] * (T / 2 - 0.5), 0, o[2] * (T / 2 - 0.5)), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 155, 160) })
		end
	end
end

function House.build(map)
	local theme = THEMES[map.theme or "party"] or THEMES.party
	wallColor = theme.wall
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
		if f.kind == "tiles" or f.kind == "pinktiles" then
			local pink = f.kind == "pinktiles"
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
								Color = pink and (dark and Color3.fromRGB(255, 150, 190) or Color3.fromRGB(255, 240, 245)) or (dark and Color3.fromRGB(40, 40, 46) or Color3.fromRGB(226, 220, 205)),
							})
						end
					end
				end
			end
		else
			part(root, { Name = "Floor " .. f.name, Size = Vector3.new(w, 1, d), Position = centre, Material = mat[1], Color = mat[2] })
		end
		-- a warm light per room, dimmed for Spooky games later
		local l = light(root, Vector3.new(centre.X, (f.tall and HT or H) - 2, centre.Z), theme.light, math.min(60, math.max(w, d) * 0.75), 1.2)
		table.insert(world.lights, l)
		world.roomLights = world.roomLights or {}
		world.roomLights[f.name] = l
	end

	-- doorway floors, walls, furniture
	for y = 0, map.h - 1 do
		for x = 0, map.w - 1 do
			local c = cell(map, x, y)
			if c == "." and floorKind(map, x, y) == "door" then
				part(root, { Name = "Doorway", Size = Vector3.new(T, 1, T), Position = at(x, y, -0.5), Material = FLOOR.door[1], Color = FLOOR.door[2] })
				if tallAt(map, x, y, true) then
					-- close the gap above a doorway into a tall room
					part(root, { Name = "TallLintel", Size = Vector3.new(T, HT - H, T), Position = at(x, y, H + (HT - H) / 2), Material = Enum.Material.Plaster, Color = wallColor })
				end
			elseif c == "#" or c == "C" then
				local mirror = map.theme == "carnival" and string.find(roomNameAt(map, x, y), "Mirror", 1, true) ~= nil
				-- the Aquarium's Shark Tunnel: walls of water behind glass
				local tunnel = map.theme == "aquarium" and string.find(roomNameAt(map, x, y), "Tunnel", 1, true) ~= nil
				part(root, {
					Name = mirror and "MirrorWall" or tunnel and "TunnelGlass" or "Wall",
					Size = Vector3.new(T, tallAt(map, x, y, true) and HT or H, T),
					Position = at(x, y, (tallAt(map, x, y, true) and HT or H) / 2),
					Material = (mirror or tunnel) and Enum.Material.Glass or Enum.Material.Plaster,
					Color = mirror and Color3.fromRGB(200, 222, 238) or tunnel and Color3.fromRGB(50, 130, 190) or wallColor,
					Reflectance = mirror and 0.55 or tunnel and 0.1 or 0,
					Transparency = tunnel and 0.35 or 0,
				})
				if tunnel then
					fishIn(root, at(x, y, 7), Vector3.new(2.5, 3, 2.5), 2, x * 7 + y)
				end
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
				part(root, { Name = "Lintel", Size = Vector3.new(T, H - top, T), Position = at(x, y, top + (H - top) / 2), Material = Enum.Material.Plaster, Color = wallColor })
			elseif c == "T" then
				local f = furnitureAt(map, x, y)
				local kind = f and f.kind or "table"
				if kind == "shelf" and styledShelf(root, map, x, y) then
					-- a shelf that matches its room
				elseif map.theme == "gummy" and kind ~= "pit" and kind ~= "planter" then
					candyFurniture(root, kind, x, y, roomNameAt(map, x, y), map)
				elseif map.theme == "hospital" and kind ~= "planter" and kind ~= "pit" then
					hospitalFurniture(root, kind, x, y)
				elseif map.theme == "school" and schoolFurniture(root, kind, x, y) then
					-- a school table or desk
				elseif map.theme == "carnival" and carnivalFurniture(root, kind, x, y, map) then
					-- a carnival stall, cart, pond, ride or seats
				elseif map.theme == "aquarium" and aquariumFurniture(root, kind, x, y, map) then
					-- a fish tank, pool, kelp, submarine, bones, coral or the great tank
				elseif kind == "table" then
					part(root, { Name = "Table", Size = Vector3.new(T, 0.6, T), Position = at(x, y, 3.4), Material = Enum.Material.Fabric, Color = Color3.fromRGB(242, 233, 247) })
					part(root, { Name = "TableSkirt", Size = Vector3.new(T - 0.2, 3, T - 0.2), Position = at(x, y, 1.6), Material = Enum.Material.Fabric, Color = Color3.fromRGB(255, 138, 31) })
				elseif kind == "counter" then
					part(root, { Name = "Counter", Size = Vector3.new(T, 4, T), Position = at(x, y, 2), Material = Enum.Material.Wood, Color = Color3.fromRGB(139, 106, 79) })
					part(root, { Name = "CounterTop", Size = Vector3.new(T, 0.4, T), Position = at(x, y, 4.2), Material = Enum.Material.Marble, Color = Color3.fromRGB(207, 200, 187) })
				elseif kind == "pit" and string.find(string.lower(roomNameAt(map, x, y)), "jelly", 1, true) then
					-- a pool of wobbly jelly; every other tile bounces you up
					part(root, { Name = "JellyRim", Size = Vector3.new(T, 1.2, T), Position = at(x, y, 0.6), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 190, 220) })
					local jcol = ({ Color3.fromRGB(80, 220, 120), Color3.fromRGB(255, 80, 140), Color3.fromRGB(90, 160, 255), Color3.fromRGB(255, 200, 60) })[(x + y) % 4 + 1]
					local jelly = part(root, { Name = (x + y) % 2 == 0 and "BouncePad" or "Jelly", Size = Vector3.new(T - 0.4, 1, T - 0.4), Position = at(x, y, 1.6), Material = Enum.Material.Glass, Color = jcol, Transparency = 0.3 })
					TweenService:Create(jelly, TweenInfo.new(0.8 + (x % 3) * 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = Vector3.new(T - 0.2, 1.3, T - 0.2) }):Play()
				elseif kind == "pit" then
					-- the gumdrop ball pit: a low padded rim full of colourful balls
					part(root, { Name = "Pit", Size = Vector3.new(T, 1.6, T), Position = at(x, y, 0.8), Material = Enum.Material.Fabric, Color = Color3.fromRGB(255, 120, 170) })
					local cols = { Color3.fromRGB(255, 77, 94), Color3.fromRGB(61, 139, 255), Color3.fromRGB(255, 210, 63), Color3.fromRGB(70, 209, 96), Color3.fromRGB(190, 110, 230) }
					for i = 1, 6 do
						part(root, { Name = "Gumdrop", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), Position = at(x, y, 2) + Vector3.new(math.cos(i) * 2.2, (i % 2) * 0.4, math.sin(i * 1.7) * 2.2), Color = cols[(x + y + i) % 5 + 1], Material = Enum.Material.Glass, CanCollide = false })
					end
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
		part(root, { Name = "Ceiling", Size = Vector3.new((x1 - x0 + 1) * T, 4, (y1 - y0 + 1) * T), Position = Vector3.new((x0 + x1 + 1) / 2 * T, height + 2.02, (y0 + y1 + 1) / 2 * T), CastShadow = false, Material = Enum.Material.Plaster, Color = theme.ceiling })
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
	-- bounce pads: boing (the bounce itself happens on each player's screen)
	for _, pad in ipairs(map.pads or {}) do
		part(root, { Name = "BouncePad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 6, 6), CFrame = CFrame.new(at(pad[1], pad[2], 0.2)) * CFrame.Angles(0, 0, math.rad(90)), Color = map.theme == "aquarium" and Color3.fromRGB(120, 210, 255) or Color3.fromRGB(255, 90, 170), Material = Enum.Material.Neon })
	end
	House.buildGarden(world)
	House.decorate(world)
	return world
end

-- a store room's bonus present (opens once its door is open)
local function storeRoomGift(root, entry, o)
	if not (o.bonus and o.ix and o.iy) then
		return
	end
	local pos = at(o.ix, o.iy, 0) + Vector3.new(0, 1.3, 0)
	local box = part(root, { Name = "BonusPresent", Size = Vector3.new(2.6, 2.6, 2.6), Position = pos, Color = Color3.fromRGB(255, 210, 63), Material = Enum.Material.SmoothPlastic })
	local r1 = part(root, { Name = "Ribbon", Size = Vector3.new(2.7, 2.7, 0.5), Position = pos, Color = Color3.fromRGB(232, 80, 91), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	local r2 = part(root, { Name = "Ribbon", Size = Vector3.new(0.5, 2.7, 2.7), Position = pos, Color = Color3.fromRGB(232, 80, 91), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	local bow = part(root, { Name = "Bow", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1), Position = pos + Vector3.new(0, 1.6, 0), Color = Color3.fromRGB(232, 80, 91), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	entry.gift = box
	entry.giftBits = { box, r1, r2, bow }
	entry.giftPrompt = prompt(box, "Open", "Bonus present", 0.5)
	entry.giftPrompt.Enabled = false
end

--[[
	Muscle's barricade crates: a heavy crate standing beside a doorway, marked
	with a big arm, that Muscle's Barricade button slides into the doorway.
	Kids walk through it; the host has to smash through. Returns the crate
	(or nil when there is no free tile beside that doorway).
]]
function House.addCrate(world, x, y)
	local map = world.map
	world.crates = world.crates or {}
	world.crateAt = world.crateAt or {}
	if world.crateAt[x .. "," .. y] then
		return nil
	end
	local busy = {}
	for _, o in ipairs(map.objects) do
		busy[o.x .. "," .. o.y] = true
	end
	for _, s in ipairs(map.start) do
		busy[s[1] .. "," .. s[2]] = true
	end
	for _, c in ipairs(world.crates) do
		busy[c.hx .. "," .. c.hy] = true
	end
	-- walls left and right: people go through north-south
	local ns = cell(map, x - 1, y) == "#" and cell(map, x + 1, y) == "#"
	for _, side in ipairs({ 1, -1 }) do
		for _, along in ipairs({ -1, 1 }) do
			local hx, hy = x + along, y + side
			if not ns then
				hx, hy = x + side, y + along
			end
			if cell(map, hx, hy) == "." and not busy[hx .. "," .. hy] then
				local size = ns and Vector3.new(T * 0.9, 6, 2.6) or Vector3.new(2.6, 6, T * 0.9)
				local home = CFrame.new(at(hx, hy, 0) + Vector3.new(0, 3, 0))
				local door = CFrame.new(at(x, y, 0) + Vector3.new(0, 3, 0))
				local crate = part(world.root, { Name = "BarricadeCrate", Size = size, CFrame = home, Color = Color3.fromRGB(150, 98, 52), Material = Enum.Material.WoodPlanks, CanCollide = false })
				-- painted on every side: a strong arm and arrows, "push me"
				for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }) do
					local sg = Instance.new("SurfaceGui")
					sg.Face = face
					sg.CanvasSize = Vector2.new(200, 160)
					sg.LightInfluence = 0.3
					sg.Parent = crate
					local t = Instance.new("TextLabel")
					t.Size = UDim2.fromScale(1, 1)
					t.BackgroundTransparency = 1
					t.TextScaled = true
					t.Font = Enum.Font.FredokaOne
					t.TextColor3 = Color3.fromRGB(255, 210, 63)
					t.TextStrokeTransparency = 0.3
					t.Text = "\u{2B05}\u{1F4AA}\u{27A1}"
					t.Parent = sg
				end
				local mark = Instance.new("BillboardGui")
				mark.Size = UDim2.fromOffset(110, 56)
				mark.StudsOffset = Vector3.new(0, 5, 0)
				mark.MaxDistance = 35
				mark.Parent = crate
				local icon = Instance.new("TextLabel")
				icon.Size = UDim2.fromScale(1, 0.7)
				icon.BackgroundTransparency = 1
				icon.TextScaled = true
				icon.Text = "\u{1F4AA}"
				icon.Parent = mark
				local word = Instance.new("TextLabel")
				word.Size = UDim2.fromScale(1, 0.3)
				word.Position = UDim2.fromScale(0, 0.7)
				word.BackgroundTransparency = 1
				word.TextScaled = true
				word.Font = Enum.Font.FredokaOne
				word.TextColor3 = Color3.fromRGB(255, 120, 120)
				word.TextStrokeTransparency = 0.4
				word.Text = "Barricade crate - Muscle"
				word.Parent = mark
				local c = { part = crate, home = home, door = door, hx = hx, hy = hy, x = x, y = y, busy = false }
				-- Muscle's prompt (only Muscle sees it)
				c.prompt = prompt(crate, "Move Barricade", "Muscle's crate", 0)
				c.prompt:SetAttribute("Only", "muscle")
				c.prompt.Triggered:Connect(function(plr)
					if world.onCrate then
						world.onCrate(plr, c)
					end
				end)
				table.insert(world.crates, c)
				world.crateAt[x .. "," .. y] = c
				return c
			end
		end
	end
	return nil
end

-- up to n crates beside the house's inner doorways
function House.placeCrates(world, n)
	local map = world.map
	local doors = {}
	for y = 1, map.h - 2 do
		for x = 1, map.w - 2 do
			if cell(map, x, y) == "." and ((cell(map, x - 1, y) == "#" and cell(map, x + 1, y) == "#") or (cell(map, x, y - 1) == "#" and cell(map, x, y + 1) == "#")) then
				table.insert(doors, { x, y })
			end
		end
	end
	for i = #doors, 2, -1 do
		local j = math.random(1, i)
		doors[i], doors[j] = doors[j], doors[i]
	end
	local made = 0
	for _, d in ipairs(doors) do
		if made >= n then
			break
		end
		if House.addCrate(world, d[1], d[2]) then
			made += 1
		end
	end
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
			-- Tinker can pick the keypad once a game to learn one colour
			entry.padPrompt = prompt(entry.keypad, "Pick the keypad", "Tinker: learn one color", 6)
			entry.padPrompt.KeyboardKeyCode = Enum.KeyCode.F
			entry.padPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY -- X is every other prompt
			entry.padPrompt:SetAttribute("Only", "tinker")
			entry.padPrompt.UIOffset = Vector2.new(0, 96) -- below "Use keypad", not on top of it
			entry.exit = part(root, { Name = "ExitDoor", Size = Vector3.new(T, 10, 2), Position = base + Vector3.new(0, 5, -T / 2 + 1), Transparency = 1, CanCollide = false })
		elseif o.kind == "hole" then
			-- the old secret hole (Muscle's, before the blocked passage): plain wall now
			entry.panel = part(root, { Name = "HolePanel", Size = Vector3.new(T, 10, T), Position = base + Vector3.new(0, 5, 0), Material = Enum.Material.Plaster, Color = wallColor })
		elseif o.kind == "cabinet" then
			entry.part = part(root, { Name = "Cabinet", Size = Vector3.new(T * 0.8, 9, T * 0.9), Position = base + Vector3.new(0, 4.5, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(107, 66, 38) })
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
			entry.prompt = prompt(lockPart, "Free your friend", "Cage", 3.5) -- Patch holds half as long
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
			local pot = part(root, { Name = "Pot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 3.6, 3.6), CFrame = CFrame.new(base + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(181, 101, 58), Material = Enum.Material.Slate })
			for i = 1, 9 do
				local a = i / 9 * math.pi * 2
				part(root, { Name = "Leaf", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 4.2, 2.4), Position = base + Vector3.new(math.cos(a) * 1.6, 4.8 + (i % 3) * 1.1, math.sin(a) * 1.6), Color = i % 2 == 0 and Color3.fromRGB(58, 160, 78) or Color3.fromRGB(120, 210, 110), Material = Enum.Material.Grass, CanCollide = false })
			end
			-- a big flower on top so it reads as "the plant", a soft glow and sparkles
			part(root, { Name = "BloomMiddle", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1), Position = base + Vector3.new(0, 8.6, 0), Color = Color3.fromRGB(255, 210, 63), Material = Enum.Material.SmoothPlastic, CanCollide = false })
			for k = 1, 5 do
				local pa = k / 5 * math.pi * 2
				part(root, { Name = "Petal", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 0.4, 1.2), Position = base + Vector3.new(math.cos(pa) * 0.9, 8.5, math.sin(pa) * 0.9), Color = Color3.fromRGB(255, 120, 190), Material = Enum.Material.SmoothPlastic, CanCollide = false })
			end
			local glow = Instance.new("PointLight")
			glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(150, 255, 150), 14, 1.5
			glow.Parent = pot
			local att = Instance.new("Attachment")
			att.Position = Vector3.new(0, 0, 0)
			att.Parent = pot
			local sparkle = Instance.new("ParticleEmitter")
			sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparkle.Color = ColorSequence.new(Color3.fromRGB(170, 255, 170))
			sparkle.Rate = 4
			sparkle.Lifetime = NumberRange.new(1, 2)
			sparkle.Speed = NumberRange.new(1, 3)
			sparkle.SpreadAngle = Vector2.new(180, 180)
			sparkle.Size = NumberSequence.new(0.5, 0)
			sparkle.Parent = att
			local marker = Instance.new("BillboardGui")
			marker.Size = UDim2.fromOffset(44, 44)
			marker.StudsOffset = Vector3.new(0, 9, 0)
			marker.MaxDistance = 70
			marker.Parent = pot
			local icon = Instance.new("TextLabel")
			icon.Size = UDim2.fromScale(1, 1)
			icon.BackgroundTransparency = 1
			icon.TextScaled = true
			icon.Text = "\u{1F33F}"
			icon.Parent = marker
			entry.part = pot
			entry.prompt = prompt(pot, "Ask the plant", "Big plant - Bramble", 1.5)
		elseif o.kind == "lock" and o.blocked then
			-- a doorway heaped with party junk: Muscle shoves it, or a Confetti Cannon
			local alongX = cell(map, o.x - 1, o.y) ~= "."
			entry.part = part(root, { Name = "BlockedPassage", Size = alongX and Vector3.new(T, 13, 1.4) or Vector3.new(1.4, 13, T), Position = base + Vector3.new(0, 6.5, 0), Transparency = 1 })
			entry.pile = {}
			-- { size (across the doorway, up, through), offset (across, up, through), colour, material, tilt }
			local JUNK = {
				{ Vector3.new(T * 0.95, 3, 2.4), Vector3.new(0, 1.5, 0), Color3.fromRGB(107, 66, 38), Enum.Material.Wood, 0 },
				{ Vector3.new(3, 3, 2.6), Vector3.new(-T * 0.27, 4.5, 0.2), Color3.fromRGB(181, 139, 87), Enum.Material.WoodPlanks, 10 },
				{ Vector3.new(2.6, 2.6, 2.4), Vector3.new(T * 0.24, 4.3, -0.2), Color3.fromRGB(255, 77, 94), Enum.Material.SmoothPlastic, -8 },
				{ Vector3.new(3.6, 2.2, 2.2), Vector3.new(0.3, 7, 0), Color3.fromRGB(123, 227, 107), Enum.Material.SmoothPlastic, 18 },
				{ Vector3.new(0.8, 7, 0.8), Vector3.new(-T * 0.38, 8.5, 0.3), Color3.fromRGB(60, 40, 30), Enum.Material.Wood, 30 },
				{ Vector3.new(2.4, 2, 2.2), Vector3.new(T * 0.3, 7.4, 0), Color3.fromRGB(110, 60, 160), Enum.Material.Fabric, -15 },
				{ Vector3.new(2, 1.6, 2), Vector3.new(-0.8, 9.6, 0.1), Color3.fromRGB(255, 210, 63), Enum.Material.SmoothPlastic, 25 },
			}
			for _, j in ipairs(JUNK) do
				local size = alongX and j[1] or Vector3.new(j[1].Z, j[1].Y, j[1].X)
				local off = alongX and j[2] or Vector3.new(j[2].Z, j[2].Y, j[2].X)
				local tilt = alongX and CFrame.Angles(0, 0, math.rad(j[5])) or CFrame.Angles(math.rad(j[5]), 0, 0)
				table.insert(entry.pile, part(root, { Name = "Junk", Size = size, CFrame = CFrame.new(base + off) * tilt, Color = j[3], Material = j[4], CanCollide = false }))
			end
			for _, face in ipairs(alongX and { Enum.NormalId.Front, Enum.NormalId.Back } or { Enum.NormalId.Left, Enum.NormalId.Right }) do
				local sg = Instance.new("SurfaceGui")
				sg.Face = face
				sg.CanvasSize = Vector2.new(400, 650)
				sg.LightInfluence = 0
				sg.Parent = entry.part
				local txt = Instance.new("TextLabel")
				txt.Size = UDim2.new(1, -40, 0.16, 0)
				txt.Position = UDim2.new(0, 20, 0.04, 0)
				txt.BackgroundTransparency = 1
				txt.TextScaled = true
				txt.Font = Enum.Font.FredokaOne
				txt.TextColor3 = Color3.fromRGB(255, 120, 120)
				txt.TextStrokeTransparency = 0.4
				txt.Text = o.bonus and "\u{1F6A7} Junk Closet" or "\u{1F6A7} Blocked!"
				txt.Parent = sg
			end
			entry.shovePrompt = prompt(entry.part, "Shove", (o.bonus and "Junk Closet" or "Blocked passage") .. " - Muscle", 3)
			entry.popperPrompt = prompt(entry.part, "Plant Confetti Cannon", o.bonus and "Junk Closet" or "Blocked passage", 1)
			entry.popperPrompt.KeyboardKeyCode = Enum.KeyCode.F
			entry.popperPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY -- X is every other prompt
			-- Muscle sees Shove; everyone else sees the Confetti Cannon
			entry.shovePrompt:SetAttribute("Only", "muscle")
			entry.popperPrompt:SetAttribute("Not", "muscle")
			storeRoomGift(root, entry, o)
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
			entry.pickPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY -- X is every other prompt
			-- Tinker sees Pick; everyone else sees Unlock
			entry.pickPrompt:SetAttribute("Only", "tinker")
			entry.unlockPrompt:SetAttribute("Not", "tinker")
			storeRoomGift(root, entry, o)
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
			-- hiding places are marked so they stand out from things to search
			local mark = Instance.new("BillboardGui")
			mark.Size = UDim2.fromOffset(40, 40)
			mark.StudsOffset = Vector3.new(0, entry.part.Size.Y / 2 + 1.6, 0)
			mark.MaxDistance = 40
			mark.Parent = entry.part
			local mt = Instance.new("TextLabel")
			mt.Size = UDim2.fromScale(1, 1)
			mt.BackgroundTransparency = 1
			mt.TextScaled = true
			mt.Text = "\u{1F648}"
			mt.Parent = mark
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
	local clouds = map.exitStyle == "clouds"
	local groundMat, groundCol = Enum.Material.Grass, Color3.fromRGB(60, 110, 50)
	if stairs then
		groundMat, groundCol = Enum.Material.WoodPlanks, Color3.fromRGB(110, 75, 48)
	elseif clouds then
		groundMat, groundCol = Enum.Material.SmoothPlastic, Color3.fromRGB(255, 215, 232)
	end
	local garden = part(root, { Name = "Garden", Size = Vector3.new((gx1 - gx0) * T, 1, 6 * T), Position = Vector3.new((gx0 + gx1) / 2 * T, -0.5, -3 * T), Material = groundMat, Color = groundCol })
	if stairs or map.hasNext then
		-- solid steps you can climb, a landing at the top and a glowing doorway
		-- (indoors on upper floors; out in the garden or the clouds on a
		-- ground floor that has a floor above)
		local stepMat, stepCol = Enum.Material.WoodPlanks, Color3.fromRGB(95, 62, 40)
		if map.theme == "gummy" then
			stepMat, stepCol = Enum.Material.SmoothPlastic, Color3.fromRGB(255, 160, 200)
		elseif map.theme == "hospital" then
			stepMat, stepCol = Enum.Material.Concrete, Color3.fromRGB(150, 155, 160)
		elseif map.theme == "school" then
			stepMat, stepCol = Enum.Material.Wood, Color3.fromRGB(140, 100, 60)
		elseif map.theme == "carnival" then
			stepMat, stepCol = Enum.Material.SmoothPlastic, Color3.fromRGB(200, 40, 60)
		elseif map.theme == "aquarium" then
			stepMat, stepCol = Enum.Material.SmoothPlastic, Color3.fromRGB(40, 120, 140)
		end
		for i = 1, 8 do
			part(root, { Name = "StairUp", Size = Vector3.new(16, i * 1.5, 3), Position = Vector3.new(doorX * T + T / 2, i * 0.75, -16 - i * 3), Material = stepMat, Color = stepCol })
		end
		part(root, { Name = "Landing", Size = Vector3.new(16, 12, 7), Position = Vector3.new(doorX * T + T / 2, 6, -43.5), Material = stepMat, Color = stepCol })
		if not stairs then
			-- outdoors: a door frame standing on the landing
			part(root, { Name = "UpDoorFrame", Size = Vector3.new(9, 12, 1), Position = Vector3.new(doorX * T + T / 2, 18, -47.2), Material = stepMat, Color = stepCol })
		end
		-- a little in front of the landing's back wall (touching it, the two flickered)
		part(root, { Name = "NextFloorDoor", Size = Vector3.new(7, 10, 0.4), Position = Vector3.new(doorX * T + T / 2, 17, -46.6), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 190, 90), Transparency = 0.2, CanCollide = false })
		local doorLight = Instance.new("PointLight")
		doorLight.Color, doorLight.Range, doorLight.Brightness = Color3.fromRGB(255, 200, 120), 18, 2
		doorLight.Parent = root:FindFirstChild("NextFloorDoor")
		local sign = part(root, { Name = "UpSign", Size = Vector3.new(15, 4.4, 0.3), Position = Vector3.new(doorX * T + T / 2, 25, -46.4), Color = Color3.fromRGB(255, 138, 31), CanCollide = false })
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Back
		sg.LightInfluence = 0
		sg.CanvasSize = Vector2.new(600, 176)
		sg.Parent = sign
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -20, 0.66, 0)
		t.Position = UDim2.fromOffset(10, 4)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.FredokaOne
		t.TextColor3 = Color3.fromRGB(26, 16, 38)
		t.Text = "\u{2B06} " .. (map.upText or ((map.exitText and map.exitText ~= "") and map.exitText) or "Up to the next floor")
		t.Parent = sg
		local t2 = t:Clone()
		t2.Size = UDim2.new(1, -20, 0.3, 0)
		t2.Position = UDim2.new(0, 10, 0.68, 0)
		t2.Text = "Step through when the game ends"
		t2.Parent = sg
	end
	-- the side path runs along whichever side has the hole
	local holeWest = false
	for _, o in ipairs(map.objects) do
		if o.kind == "hole" and o.x == 0 then
			holeWest = true
		end
	end
	local sideX = holeWest and -2 * T or map.w * T + 2 * T
	part(root, { Name = "SidePath", Size = Vector3.new(4 * T, 1, map.h * T), Position = Vector3.new(sideX, -0.5, map.h * T / 2), Material = groundMat, Color = groundCol })
	for i = 0, 10 do
		local pos = Vector3.new(gx0 * T + i * (gx1 - gx0) * T / 10, 9, -5.5 * T)
		part(root, { Name = "FairyLight", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), Position = pos, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 220, 140), CanCollide = false })
	end
	light(root, garden.Position + Vector3.new(0, 10, 0), Color3.fromRGB(255, 220, 160), 60, 2)
	-- hedges you can see, and tall invisible walls so nobody walks or jumps off
	local function hedge(x0, z0, x1, z1)
		local size = Vector3.new(math.max(2, math.abs(x1 - x0)), 6, math.max(2, math.abs(z1 - z0)))
		local centre = Vector3.new((x0 + x1) / 2, 3, (z0 + z1) / 2)
		part(root, { Name = "Hedge", Size = stairs and Vector3.new(size.X, 26, size.Z) or size, Position = stairs and centre + Vector3.new(0, 10, 0) or centre,
			Material = stairs and Enum.Material.Plaster or clouds and Enum.Material.SmoothPlastic or Enum.Material.LeafyGrass,
			Color = stairs and wallColor or clouds and Color3.fromRGB(255, 240, 248) or Color3.fromRGB(40, 80, 38) })
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
	-- escaped players arrive beside the stairs, not inside them
	world.gardenSpot = garden.Position + Vector3.new(stairs and -3 * T or 0, 4, 0)
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
local HOSPITAL_PICTURES = { "\u{1FA7A}", "\u{1F48A}", "\u{1FA79}", "\u{1F9F8}", "\u{1F3E5}", "\u{1F47B}", "\u{1F987}", "\u{1F383}" }
local HALLOWEEN_DECOR = { Color3.fromRGB(255, 138, 31), Color3.fromRGB(110, 60, 160), Color3.fromRGB(30, 24, 34), Color3.fromRGB(150, 220, 60) }
local CANDY_PICTURES = { "\u{1F36C}", "\u{1F36D}", "\u{1F9C1}", "\u{1F369}", "\u{1F36B}", "\u{1F370}", "\u{1F366}", "\u{1F388}" }
local PICTURES = { "\u{1F383}", "\u{1F47B}", "\u{1F987}", "\u{1F578}", "\u{1F382}", "\u{1F388}", "\u{1F315}", "\u{1F36D}" }
local AQUARIUM_PICTURES = { "\u{1F41F}", "\u{1F420}", "\u{1F419}", "\u{1F988}", "\u{1F422}", "\u{1F42C}", "\u{1F980}", "\u{1F433}" }
local CARNIVAL_PICTURES = { "\u{1F3AA}", "\u{1F3A0}", "\u{1F3A1}", "\u{1F388}", "\u{1F37F}", "\u{1F39F}", "\u{1F939}", "\u{1F383}" }
local SCHOOL_PICTURES = { "\u{1F34E}", "\u{270F}", "\u{1F4DA}", "\u{1F514}", "\u{1F392}", "\u{1F4D0}", "\u{1F989}", "\u{1F383}" }

function House.decorate(world)
	local root, map = world.root, world.map
	local candy = map.theme == "gummy"
	local hosp = map.theme == "hospital"
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
		if hosp then
			local strip = deco({ Name = "StripLight", Size = Vector3.new(6, 0.3, 1), Position = Vector3.new((x0 + x1) / 2, H - 0.2, (z0 + z1) / 2), Color = Color3.fromRGB(225, 240, 255), Material = Enum.Material.Neon })
			task.spawn(function()
				local rng = Random.new()
				while strip.Parent do
					task.wait(rng:NextNumber(1.5, 6))
					for _ = 1, rng:NextInteger(1, 3) do
						strip.Transparency = 0.85
						task.wait(rng:NextNumber(0.05, 0.15))
						strip.Transparency = 0
						task.wait(rng:NextNumber(0.05, 0.2))
					end
				end
			end)
		end
		-- two swags of party flags across the ceiling (not in the hospital)
		for s = 0, hosp and -1 or 1 do
			local top = (f.tall and HT or H) - 1.2
			local a = Vector3.new(x0 + 1, top, s == 0 and z0 + 1 or z1 - 1)
			local b = Vector3.new(x1 - 1, top, s == 0 and z1 - 1 or z0 + 1)
			local n = math.max(2, math.floor((b - a).Magnitude / 2.6))
			local side = (b - a).Unit:Cross(Vector3.yAxis)
			for i = 0, n do
				local t = i / n
				local p = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * 2.5, 0)
				local flags = (Config.HALLOWEEN and not candy) and HALLOWEEN_DECOR or DECOR
				deco({ Name = "Flag", Size = Vector3.new(1.3, 1.5, 0.08), CFrame = CFrame.lookAt(p, p + side), Color = flags[(i + r) % #flags + 1], Material = Enum.Material.Fabric })
			end
		end
		-- Halloween: two paper bats hanging from the ceiling, slowly turning
		if Config.HALLOWEEN then
			local brng = Random.new(r * 7)
			for _ = 1, 2 do
				local bx = brng:NextNumber(x0 + 3, math.max(x0 + 3.1, x1 - 3))
				local bz = brng:NextNumber(z0 + 3, math.max(z0 + 3.1, z1 - 3))
				local top = (f.tall and HT or H)
				local by = top - brng:NextNumber(2.5, 4)
				deco({ Name = "BatString", Size = Vector3.new(0.05, top - by, 0.05), Position = Vector3.new(bx, (top + by) / 2, bz), Color = Color3.fromRGB(200, 200, 200) })
				local body = deco({ Name = "PaperBat", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.8, 0.7), Position = Vector3.new(bx, by, bz), Color = Color3.fromRGB(25, 20, 30), Material = Enum.Material.SmoothPlastic })
				local wings = {}
				for _, sx in ipairs({ -1, 1 }) do
					table.insert(wings, deco({ Name = "BatWing", Size = Vector3.new(1.4, 0.6, 0.06), CFrame = CFrame.new(bx + sx * 0.9, by + 0.1, bz) * CFrame.Angles(0, 0, math.rad(sx * 18)), Color = Color3.fromRGB(25, 20, 30), Material = Enum.Material.SmoothPlastic }))
				end
				local centre = CFrame.new(bx, by, bz)
				local rel = { centre:ToObjectSpace(wings[1].CFrame), centre:ToObjectSpace(wings[2].CFrame) }
				task.spawn(function()
					local a, speed = brng:NextNumber(0, 6), brng:NextNumber(0.3, 0.6)
					while body.Parent do
						a += speed * 0.1
						local turn = centre * CFrame.Angles(0, a, 0)
						body.CFrame = turn
						wings[1].CFrame = turn * rel[1]
						wings[2].CFrame = turn * rel[2]
						task.wait(0.1)
					end
				end)
			end
		end
		if Config.HALLOWEEN then
			local hrng = Random.new(r * 31 + 7)
			local top = (f.tall and HT or H)
			-- a little spider that slowly goes up and down on its thread
			do
				local sx = hrng:NextNumber(x0 + 4, math.max(x0 + 4.1, x1 - 4))
				local sz = hrng:NextNumber(z0 + 4, math.max(z0 + 4.1, z1 - 4))
				local thread = deco({ Name = "SpiderThread", Size = Vector3.new(0.04, 2, 0.04), Position = Vector3.new(sx, top - 1, sz), Color = Color3.fromRGB(230, 230, 230) })
				local body = deco({ Name = "Spider", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.7, 0.9), Position = Vector3.new(sx, top - 2, sz), Color = Color3.fromRGB(20, 18, 22), Material = Enum.Material.SmoothPlastic })
				local legs = {}
				for k = 1, 8 do
					local side = k <= 4 and -1 or 1
					local along = ((k - 1) % 4 - 1.5) * 0.22
					table.insert(legs, { deco({ Name = "SpiderLeg", Size = Vector3.new(0.7, 0.06, 0.06), Color = Color3.fromRGB(20, 18, 22) }), Vector3.new(side * 0.55, -0.05, along), side })
				end
				local eyes = {}
				for _, ex in ipairs({ -0.15, 0.15 }) do
					table.insert(eyes, { deco({ Name = "SpiderEye", Shape = Enum.PartType.Ball, Size = Vector3.new(0.15, 0.15, 0.15), Color = Color3.fromRGB(255, 80, 60), Material = Enum.Material.Neon }), Vector3.new(ex, 0.1, -0.42) })
				end
				task.spawn(function()
					local t = hrng:NextNumber(0, 6)
					while body.Parent do
						t += 0.1
						local drop = 2 + (math.sin(t * 0.6) + 1) * 2.2
						local c = CFrame.new(sx, top - drop, sz)
						body.CFrame = c
						thread.Size = Vector3.new(0.04, drop, 0.04)
						thread.CFrame = CFrame.new(sx, top - drop / 2, sz)
						for _, l in ipairs(legs) do
							l[1].CFrame = c * CFrame.new(l[2]) * CFrame.Angles(0, 0, math.rad(l[3] * -25 + math.sin(t * 3) * 8))
						end
						for _, e in ipairs(eyes) do
							e[1].CFrame = c * CFrame.new(e[2])
						end
						task.wait(0.1)
					end
				end)
			end
			-- a string of orange and purple lights along the top of one wall
			do
				local n = math.max(4, math.floor((x1 - x0) / 2.5))
				for k = 0, n do
					local px = x0 + 1 + (x1 - x0 - 2) * k / n
					deco({ Name = "HalloweenLight", Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), Position = Vector3.new(px, top - 0.9 - math.sin(k / n * math.pi) * 0.6, z0 + 0.5), Color = k % 2 == 0 and Color3.fromRGB(255, 138, 31) or Color3.fromRGB(150, 80, 220), Material = Enum.Material.Neon })
				end
			end
			-- every third room: a friendly little ghost floating in a corner
			if r % 3 == 0 then
				local spot
				for _, c in ipairs({ { f.x1, f.y1 }, { f.x0, f.y1 }, { f.x1, f.y0 }, { f.x0, f.y0 } }) do
					if not spot and free(c[1], c[2]) then
						spot = c
					end
				end
				if spot then
					busy[spot[1] .. "," .. spot[2]] = true
					local base = at(spot[1], spot[2], 0) + Vector3.new(0, 5, 0)
					local ghost = deco({ Name = "Ghost", Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.6, 2.2), Position = base, Color = Color3.fromRGB(245, 245, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.25 })
					local face = Instance.new("BillboardGui")
					face.Size = UDim2.new(2, 0, 2, 0)
					face.Parent = ghost
					local t = Instance.new("TextLabel")
					t.Size = UDim2.fromScale(1, 1)
					t.BackgroundTransparency = 1
					t.TextScaled = true
					t.Text = "\u{1F47B}"
					t.Parent = face
					local glow = Instance.new("PointLight")
					glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(190, 210, 255), 8, 0.6
					glow.Parent = ghost
					task.spawn(function()
						local tt = hrng:NextNumber(0, 6)
						while ghost.Parent do
							tt += 0.1
							ghost.Position = base + Vector3.new(math.sin(tt * 0.5) * 0.6, math.sin(tt * 1.3) * 0.5, math.cos(tt * 0.5) * 0.6)
							task.wait(0.1)
						end
					end)
				end
			end
		end
		-- pictures on the north wall, facing into the room
		local hung = 0
		for _, x in ipairs({ f.x0 + 2, f.x1 - 2, math.floor((f.x0 + f.x1) / 2) }) do
			if hung < 2 and cell(map, x, f.y0 - 1) == "#" and not busy[x .. "," .. (f.y0 - 1)] and cell(map, x, f.y0) ~= "#" then
				hung += 1
				world.wallUsed = world.wallUsed or {}
				world.wallUsed[x .. "," .. (f.y0 - 1)] = true -- no window over a picture
				local pic = deco({ Name = "Picture", Size = Vector3.new(3.4, 2.8, 0.2), Position = at(x, f.y0 - 1, 7.5) + Vector3.new(0, 0, T / 2 + 0.15), Color = Color3.fromRGB(110, 80, 40), Material = Enum.Material.Wood })
				local inner = deco({ Name = "Painting", Size = Vector3.new(2.8, 2.2, 0.05), Position = pic.Position + Vector3.new(0, 0, 0.12), Color = Color3.fromRGB(40, 30, 55) })
				local pics = candy and CANDY_PICTURES or hosp and HOSPITAL_PICTURES or map.theme == "school" and SCHOOL_PICTURES or map.theme == "carnival" and CARNIVAL_PICTURES or map.theme == "aquarium" and AQUARIUM_PICTURES or PICTURES
				emoji(inner, Enum.NormalId.Back, pics[(x + r) % #pics + 1])
			end
		end
		-- cobwebs in two top corners
		for _, c in ipairs(candy and {} or { { x0, z0, 45 }, { x1, z1, 45 } }) do
			local web = deco({ Name = "Cobweb", Size = Vector3.new(4.5, 4.5, 0.05), CFrame = CFrame.new(c[1] + (c[1] == x0 and 1.4 or -1.4), H - 1.8, c[2] + (c[2] == z0 and 1.4 or -1.4)) * CFrame.Angles(0, math.rad(c[3]), 0), Transparency = 1 })
			emoji(web, Enum.NormalId.Front, "\u{1F578}")
			emoji(web, Enum.NormalId.Back, "\u{1F578}")
		end
		-- party clutter away from the walls (not solid); some of it does things
		local inner = {}
		for y = f.y0 + 2, f.y1 - 2 do
			for x = f.x0 + 2, f.x1 - 2 do
				if free(x, y) then
					table.insert(inner, { x, y })
				end
			end
		end
		local rng = Random.new()
		for _ = 1, math.min(2, #inner) do
			local c = table.remove(inner, rng:NextInteger(1, #inner))
			for dx = -1, 1 do
				for dy = -1, 1 do
					busy[(c[1] + dx) .. "," .. (c[2] + dy)] = true
				end
			end
			local base = at(c[1], c[2], 0)
			local kind = rng:NextInteger(1, 4)
			if hosp and (kind == 1 or kind == 4) then
				-- a wheelchair: give it a spin (it creaks)
				local seat = deco({ Name = "WheelchairSeat", Size = Vector3.new(2, 0.4, 2), Position = base + Vector3.new(0, 1.8, 0), Color = Color3.fromRGB(60, 90, 140), Material = Enum.Material.Fabric })
				local back = deco({ Name = "WheelchairBack", Size = Vector3.new(2, 2, 0.3), Position = base + Vector3.new(0, 2.9, 0.9), Color = Color3.fromRGB(60, 90, 140), Material = Enum.Material.Fabric })
				local wheels = {}
				for _, sx in ipairs({ -1.15, 1.15 }) do
					table.insert(wheels, deco({ Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2.6, 2.6), CFrame = CFrame.new(base + Vector3.new(sx, 1.3, 0.2)), Color = Color3.fromRGB(180, 185, 190), Material = Enum.Material.Metal }))
				end
				local bits = { seat, back, wheels[1], wheels[2] }
				local centre = base + Vector3.new(0, 1.8, 0)
				local pp = prompt(seat, "Spin", "Wheelchair", 0.3)
				pp.Triggered:Connect(function()
					pp.Enabled = false
					require(script.Parent.Effects).sound(seat.Position, "unhide", 0.7)
					local start = {}
					for i, b in ipairs(bits) do
						start[i] = CFrame.new(centre):ToObjectSpace(b.CFrame)
					end
					for step = 1, 24 do
						local turn = CFrame.new(centre) * CFrame.Angles(0, step / 24 * math.pi * 2, 0)
						for i, b in ipairs(bits) do
							b.CFrame = turn * start[i]
						end
						task.wait(0.03)
					end
					pp.Enabled = true
				end)
			elseif kind == 1 then
				-- a birthday cake: blow out the candles
				deco({ Name = "CakeTable", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 4, 4), CFrame = CFrame.new(base + Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 235, 245), Material = Enum.Material.Fabric })
				deco({ Name = "CakeTableLeg", Size = Vector3.new(0.5, 2.6, 0.5), Position = base + Vector3.new(0, 1.3, 0), Color = Color3.fromRGB(90, 60, 40) })
				local cake = deco({ Name = "PartyCake", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 2.2, 2.2), CFrame = CFrame.new(base + Vector3.new(0, 3.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 190, 215) })
				local flames = {}
				for i = 1, 3 do
					local a = i / 3 * math.pi * 2
					deco({ Name = "Candle", Size = Vector3.new(0.15, 0.7, 0.15), Position = base + Vector3.new(math.cos(a) * 0.6, 4.75, math.sin(a) * 0.6), Color = DECOR[i] })
					table.insert(flames, deco({ Name = "Flame", Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Position = base + Vector3.new(math.cos(a) * 0.6, 5.25, math.sin(a) * 0.6), Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.Neon }))
				end
				local glow = Instance.new("PointLight")
				glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(255, 190, 90), 8, 1
				glow.Parent = cake
				local pp = prompt(cake, "Blow out the candles", "Birthday cake", 0.5)
				pp.Triggered:Connect(function()
					pp.Enabled = false
					for _, fl in ipairs(flames) do
						fl.Transparency = 1
					end
					glow.Enabled = false
					require(script.Parent.Effects).sound(cake.Position, "sneak", 0.6)
					task.delay(40, function()
						for _, fl in ipairs(flames) do
							fl.Transparency = 0
						end
						glow.Enabled = true
						pp.Enabled = true
					end)
				end)
			elseif kind == 2 then
				-- a jack-in-the-box: wind the crank... POP! (loud: the host hears it)
				local box = deco({ Name = "JackBox", Size = Vector3.new(2.2, 2.2, 2.2), Position = base + Vector3.new(0, 1.1, 0), Color = DECOR[(r % #DECOR) + 1], Material = Enum.Material.SmoothPlastic })
				deco({ Name = "JackStripe", Size = Vector3.new(2.25, 0.4, 2.25), Position = base + Vector3.new(0, 1.5, 0), Color = Color3.fromRGB(255, 210, 63), Material = Enum.Material.SmoothPlastic })
				deco({ Name = "Crank", Size = Vector3.new(0.9, 0.25, 0.25), Position = base + Vector3.new(1.55, 1.2, 0), Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal })
				deco({ Name = "CrankKnob", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), Position = base + Vector3.new(2, 1.2, 0), Color = Color3.fromRGB(232, 80, 91) })
				local lidRest = CFrame.new(base + Vector3.new(0, 2.33, 0))
				local lid = deco({ Name = "JackLid", Size = Vector3.new(2.3, 0.25, 2.3), CFrame = lidRest, Color = Color3.fromRGB(255, 210, 63), Material = Enum.Material.SmoothPlastic })
				-- Jack: a spring, a frilly collar, a grinning head with a jester hat
				local hidden = base + Vector3.new(0, 1.2, 0)
				local jack = {
					{ deco({ Name = "JackSpring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 0.6, 0.6), CFrame = CFrame.new(hidden) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(190, 190, 200), Material = Enum.Material.Metal, Transparency = 1 }), Vector3.new(0, 3, 0), true },
					{ deco({ Name = "JackCollar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 1.9, 1.9), CFrame = CFrame.new(hidden) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(250, 250, 250), Material = Enum.Material.Fabric, Transparency = 1 }), Vector3.new(0, 3.9, 0), true },
					{ deco({ Name = "JackHead", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), Position = hidden, Color = Color3.fromRGB(255, 226, 200), Material = Enum.Material.SmoothPlastic, Transparency = 1 }), Vector3.new(0, 4.8, 0) },
					{ deco({ Name = "JackNose", Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), Position = hidden, Color = Color3.fromRGB(232, 40, 50), Material = Enum.Material.SmoothPlastic, Transparency = 1 }), Vector3.new(0, 4.75, 0) },
					{ deco({ Name = "JackHatL", Size = Vector3.new(0.9, 1.1, 0.9), Position = hidden, Color = Color3.fromRGB(110, 60, 160), Material = Enum.Material.Fabric, Transparency = 1 }), Vector3.new(-0.5, 5.8, 0) },
					{ deco({ Name = "JackHatR", Size = Vector3.new(0.9, 1.1, 0.9), Position = hidden, Color = Color3.fromRGB(255, 138, 31), Material = Enum.Material.Fabric, Transparency = 1 }), Vector3.new(0.5, 5.8, 0) },
					{ deco({ Name = "JackBellL", Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4), Position = hidden, Color = Color3.fromRGB(255, 210, 63), Material = Enum.Material.Metal, Transparency = 1 }), Vector3.new(-0.9, 6.4, 0) },
					{ deco({ Name = "JackBellR", Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4), Position = hidden, Color = Color3.fromRGB(255, 210, 63), Material = Enum.Material.Metal, Transparency = 1 }), Vector3.new(0.9, 6.4, 0) },
				}
				-- his face always turns to whoever looks at him
				local face = Instance.new("BillboardGui")
				face.Size = UDim2.new(1.5, 0, 1.5, 0)
				face.Enabled = false
				face.Parent = jack[3][1]
				local grin = Instance.new("TextLabel")
				grin.Size = UDim2.fromScale(1, 1)
				grin.BackgroundTransparency = 1
				grin.TextScaled = true
				grin.Text = "\u{1F61C}"
				grin.Parent = face
				local pp = prompt(box, "Wind the crank", "Jack-in-the-box", 1)
				pp.Triggered:Connect(function()
					pp.Enabled = false
					local fx = require(script.Parent.Effects)
					task.wait(0.8)
					TweenService:Create(lid, TweenInfo.new(0.15), { CFrame = lidRest * CFrame.new(0, 0.9, -1.1) * CFrame.Angles(math.rad(-100), 0, 0) }):Play()
					for _, j in ipairs(jack) do
						j[1].Transparency = 0
						local goal = base + j[2]
						local cf = j[3] and CFrame.new(goal) * CFrame.Angles(0, 0, math.rad(90)) or CFrame.new(goal)
						TweenService:Create(j[1], TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = cf }):Play()
					end
					face.Enabled = true
					fx.sound(box.Position, "giggle", 1)
					fx.burst(box.Position + Vector3.new(0, 4, 0), "pop")
					if world.onNoise then
						world.onNoise(box.Position)
					end
					task.delay(8, function()
						for _, j in ipairs(jack) do
							j[1].Transparency = 1
							j[1].CFrame = j[3] and CFrame.new(hidden) * CFrame.Angles(0, 0, math.rad(90)) or CFrame.new(hidden)
						end
						face.Enabled = false
						lid.CFrame = lidRest
						pp.Enabled = true
					end)
				end)
			elseif kind == 3 then
				-- a pile of presents to shake: tissue paper flies out
				local boxes = {}
				for i = 0, 2 do
					table.insert(boxes, deco({ Name = "GiftPile", Size = Vector3.new(1.8 - i * 0.4, 1.2, 1.8 - i * 0.4), Position = base + Vector3.new(0, 0.6 + i * 1.2, 0), Color = DECOR[(i + r) % #DECOR + 1] }))
				end
				local pp = prompt(boxes[2], "Shake", "Pile of presents", 0.5)
				pp.Triggered:Connect(function()
					pp.Enabled = false
					require(script.Parent.Effects).surprise(boxes[3].Position, "tissue")
					task.delay(20, function()
						pp.Enabled = true
					end)
				end)
			else
				-- a chair with a bunch of balloons tied to it
				deco({ Name = "PartyChair", Size = Vector3.new(1.6, 2.4, 1.6), Position = base + Vector3.new(0, 1.2, 0), Color = Color3.fromRGB(120, 80, 160) })
				for i = 0, 2 do
					deco({ Name = "ChairBalloon", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.9, 1.6), Position = base + Vector3.new(math.cos(i * 2.1) * 0.8, 6 + i * 0.5, math.sin(i * 2.1) * 0.8), Color = DECOR[(i + r + 2) % #DECOR + 1] })
				end
			end
		end
		-- a rug in the middle (not in the kitchen: it has its tiles; not in the
		-- hospital; not in a pantry, bathroom or laundry)
		local lname = string.lower(f.name)
		local plain = string.find(lname, "pantry") or string.find(lname, "bath") or string.find(lname, "laundry") or string.find(lname, "corridor") or string.find(lname, "hall")
			or string.find(lname, "landing") or string.find(lname, "stair") or string.find(lname, "lobby") or string.find(lname, "entrance") or string.find(lname, "boiler") or string.find(lname, "tank")
		if f.kind ~= "tiles" and not hosp and not plain then
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
					-- a glowing pumpkin, or in the Gummy Bounce House a giant gumdrop
					local pk = deco({ Name = candy and "Gumdrop" or "Pumpkin", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2, 2.4), Position = base + Vector3.new(0, 1, 0),
						Color = candy and Color3.fromRGB(120, 220, 140) or Color3.fromRGB(240, 120, 20), Material = candy and Enum.Material.Glass or Enum.Material.SmoothPlastic })
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
