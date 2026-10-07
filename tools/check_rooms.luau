--[[
	check_rooms.luau - plays the Rooms.luau placement rules (vault door,
	laundry chute, windows) on every floor plan with MapGen's random fills,
	outside Roblox. Run: .tools/luau.exe tools/check_rooms.luau
	The rules here are copied from game/server/Rooms.luau: keep them in step.
]]

-- a stand-in for Roblox's Random
Random = {}
function Random.new(seed)
	local state = (seed or os.time()) % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	local r = {}
	local function nextRaw()
		state = (state * 48271) % 2147483647
		return state / 2147483647
	end
	function r:NextInteger(a, b)
		return a + math.floor(nextRaw() * (b - a + 1))
	end
	function r:NextNumber(a, b)
		a, b = a or 0, b or 1
		return a + nextRaw() * (b - a)
	end
	return r
end

local Plans = require("../roblox/src/shared/HouseMap")
local MapGen = require("../roblox/src/shared/MapGen")

local function cell(map, x, y)
	if y < 0 or y >= map.h or x < 0 or x >= map.w then
		return "#"
	end
	return string.sub(map.map[y + 1], x + 1, x + 1)
end
local DIRS = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }
local function onEdge(map, x, y)
	return x == 0 or y == 0 or x == map.w - 1 or y == map.h - 1
end

-- Rooms.dress's busy tiles (objects, starts, doorways and what is next to them)
local function busyOf(map)
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
	return busy
end

local function openTiles(map)
	local seen, queue = {}, {}
	for _, s in ipairs(map.start) do
		seen[s[1] .. "," .. s[2]] = true
		table.insert(queue, { s[1], s[2] })
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

local function vaultSpot(map, f, busy)
	for y = f.y0, f.y1 do
		for x = f.x0, f.x1 do
			if cell(map, x, y) == "." and not busy[x .. "," .. y] then
				for _, d in ipairs(DIRS) do
					local wx, wy = x + d[1], y + d[2]
					local ax, ay = d[2] ~= 0 and 1 or 0, d[1] ~= 0 and 1 or 0
					if onEdge(map, wx, wy) and cell(map, wx, wy) == "#" and cell(map, wx - ax, wy - ay) == "#" and cell(map, wx + ax, wy + ay) == "#" then
						return { x, y }
					end
				end
			end
		end
	end
	return nil
end

local function chuteSpots(map, busy, open)
	local from
	for _, f in ipairs(map.floors) do
		local n = string.lower(f.name)
		if not from and (string.find(n, "laundry", 1, true) or string.find(n, "linen", 1, true)) then
			from = f
		end
	end
	if not from then
		return nil
	end
	local function spot(f, needWall)
		for y = f.y0, f.y1 do
			for x = f.x0, f.x1 do
				if cell(map, x, y) == "." and open[x .. "," .. y] and not busy[x .. "," .. y] then
					local wall = false
					for _, d in ipairs(DIRS) do
						if cell(map, x + d[1], y + d[2]) == "#" then
							wall = true
						end
					end
					if wall or not needWall then
						return { x, y }
					end
				end
			end
		end
		return nil
	end
	local a = spot(from, true)
	if not a then
		return from.name .. ": NO HATCH SPOT"
	end
	local to, toDist
	local fx, fy = (from.x0 + from.x1) / 2, (from.y0 + from.y1) / 2
	for _, f in ipairs(map.floors) do
		if f ~= from and spot(f, false) then
			local dist = math.abs((f.x0 + f.x1) / 2 - fx) + math.abs((f.y0 + f.y1) / 2 - fy)
			if not to or dist > toDist then
				to, toDist = f, dist
			end
		end
	end
	return from.name .. " -> " .. (to and to.name or "NOWHERE")
end

local function windowCount(map, busy)
	local objAt = {}
	for _, o in ipairs(map.objects) do
		objAt[o.x .. "," .. o.y] = true
	end
	local total, rooms = 0, 0
	for _, f in ipairs(map.floors) do
		local made, last = 0, nil
		for y = f.y0, f.y1 do
			for x = f.x0, f.x1 do
				local corner = (x == f.x0 or x == f.x1) and (y == f.y0 or y == f.y1)
				if made < 2 and not corner and cell(map, x, y) == "." and not busy[x .. "," .. y] and not objAt[x .. "," .. y] then
					for _, d in ipairs(DIRS) do
						local wx, wy = x + d[1], y + d[2]
						local ax, ay = d[2] ~= 0 and 1 or 0, d[1] ~= 0 and 1 or 0
						local far = not last or math.abs(x - last[1]) + math.abs(y - last[2]) >= 3
						if made < 2 and far and onEdge(map, wx, wy) and cell(map, wx, wy) == "#" and cell(map, wx - ax, wy - ay) == "#" and cell(map, wx + ax, wy + ay) == "#" and not objAt[wx .. "," .. wy] then
							made += 1
							last = { x, y }
						end
					end
				end
			end
		end
		total += made
		if made > 0 then
			rooms += 1
		end
	end
	return total, rooms
end

local RUNS = 200
for building, floors in pairs(Plans) do
	for floorNo, plans in pairs(floors) do
		for _, plan in ipairs(plans) do
			local vaultMiss, chute, wMin, wMax, rMin = 0, nil, math.huge, 0, math.huge
			local hasVault = false
			for run = 1, RUNS do
				local map = MapGen.make({ plan }, Random.new(run * 31 + #plan.id))
				local busy = busyOf(map)
				for _, f in ipairs(map.floors) do
					if string.find(string.lower(f.name), "vault door hall", 1, true) then
						hasVault = true
						if not vaultSpot(map, f, busy) then
							vaultMiss += 1
						end
					end
				end
				chute = chuteSpots(map, busy, openTiles(map)) or chute
				local w, r = windowCount(map, busy)
				wMin, wMax, rMin = math.min(wMin, w), math.max(wMax, w), math.min(rMin, r)
			end
			print(string.format("%-10s %d %-8s windows %d-%d (rooms with one: at least %d)%s%s", building, floorNo, plan.id, wMin, wMax, rMin,
				hasVault and ("  vault missed " .. vaultMiss .. "/" .. RUNS) or "", chute and ("  chute " .. chute) or ""))
		end
	end
end
