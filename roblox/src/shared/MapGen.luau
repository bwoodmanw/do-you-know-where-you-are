--[[
	MapGen - makes this game's house: picks one of the floor plans in
	HouseMap and scatters the movable objects over that plan's checked slots.
	The same picking rules are played 500 times per plan by
	tools/make_housemap.py, which checks nothing ever gets cut off - keep the
	two in step.

	Every game: 3 clue balloons (two in rooms open from the start, one behind
	the first locked door), 3 trick balloons, the plant (start rooms), 2 real
	and 2 empty presents, 11 search spots (7 / 3 / 1 by zone; the keys go in
	these), 8 hiding places in different rooms (plus more until every two
	rooms joined by a doorway share one; each fits 1-3), and the invitation and painted
	wall behind the first locked door.
]]

local MapGen = {}

local HIDE_LOOKS = { "wardrobe", "sofa", "curtain", "box", "cloth" }
local SEARCH_LOOKS = { "drawer", "crate", "cakebox", "coat", "toybox", "vase", "laundry", "chest" }

local function copy(t)
	local c = {}
	for k, v in pairs(t) do
		c[k] = v
	end
	return c
end

function MapGen.make(plans, rng)
	rng = rng or Random.new()
	local plan = plans[rng:NextInteger(1, #plans)]
	local map = {
		id = plan.id,
		name = plan.name,
		w = plan.w,
		h = plan.h,
		map = plan.map,
		floors = plan.floors,
		furniture = plan.furniture,
		start = plan.start,
		spawn = plan.spawn,
		cake = plan.cake,
		patrol = plan.patrol,
		props = plan.props,
		exitStyle = plan.exitStyle,
		exitText = plan.exitText,
		theme = plan.theme,
		pads = plan.pads,
		loft = plan.loft,
		objects = {},
	}
	local zoneOf = {}
	for _, f in ipairs(plan.floors) do
		zoneOf[f.name] = f.zone
	end
	for _, o in ipairs(plan.fixed) do
		local c = copy(o)
		local y = o.kind == "door" and o.y + 1 or o.y
		c.zone = 1
		for _, f in ipairs(plan.floors) do
			if o.x >= f.x0 and o.x <= f.x1 and y >= f.y0 and y <= f.y1 then
				c.zone = f.zone
			end
		end
		table.insert(map.objects, c)
	end

	local taken, usedRooms = {}, {}
	local function ok(s)
		for dx = -1, 1 do
			for dy = -1, 1 do
				if taken[(s[1] + dx) .. "," .. (s[2] + dy)] then
					return false
				end
			end
		end
		return true
	end
	local function pick(zones, kind, limit)
		local cands = {}
		for _, s in ipairs(plan.floorSlots) do
			if zones[s[3]] and ok(s) and not (kind == "balloon" and (s[5] or 0) > 0) then
				table.insert(cands, s)
			end
		end
		if kind and limit then
			local fresh = {}
			for _, s in ipairs(cands) do
				if (usedRooms[kind .. "|" .. s[4]] or 0) < limit then
					table.insert(fresh, s)
				end
			end
			if #fresh > 0 then
				cands = fresh
			end
		end
		if #cands == 0 then
			return nil
		end
		local s = cands[rng:NextInteger(1, #cands)]
		taken[s[1] .. "," .. s[2]] = true
		if kind then
			usedRooms[kind .. "|" .. s[4]] = (usedRooms[kind .. "|" .. s[4]] or 0) + 1
		end
		return s
	end
	local function add(o, s)
		if s then
			o.x, o.y, o.zone = s[1], s[2], s[3]
			if s[5] and s[5] > 0 then
				o.h = s[5] -- up on the loft
			end
			table.insert(map.objects, o)
		end
	end
	local Z1, Z2, Z3, ZA = { [1] = true }, { [2] = true }, { [3] = true }, { [1] = true, [2] = true, [3] = true }

	-- the clue balloons: numbers 1-3 in a random order
	local order = { 1, 2, 3 }
	for i = 3, 2, -1 do
		local j = rng:NextInteger(1, i)
		order[i], order[j] = order[j], order[i]
	end
	add({ id = "b0", kind = "balloon", n = order[1] }, pick(Z1, "balloon", 1))
	add({ id = "b1", kind = "balloon", n = order[2] }, pick(Z1, "balloon", 1))
	add({ id = "b2", kind = "balloon", n = order[3] }, pick(Z2, "balloon", 1))
	add({ id = "plant", kind = "plant" }, pick(Z1))
	add({ id = "p0", kind = "present", boost = "candy" }, pick(Z1, "present", 1))
	add({ id = "p1", kind = "present", boost = "shield" }, pick(Z1, "present", 1))
	add({ id = "p2", kind = "present" }, pick({ [1] = true, [2] = true }, "present", 1))
	add({ id = "p3", kind = "present" }, pick({ [1] = true, [2] = true }, "present", 1))
	local n = 0
	for _, zc in ipairs({ { Z1, 7 }, { Z2, 3 }, { Z3, 1 } }) do
		for _ = 1, zc[2] do
			n += 1
			add({ id = "s" .. n, kind = "search", look = SEARCH_LOOKS[rng:NextInteger(1, #SEARCH_LOOKS)] }, pick(zc[1], "search", 1))
		end
	end
	for i = 1, 8 do
		local look = HIDE_LOOKS[rng:NextInteger(1, #HIDE_LOOKS)]
		add({ id = "h" .. i, kind = "hide", look = look, cap = look == "wardrobe" and 3 or rng:NextInteger(1, 2) }, pick(ZA, "hide", 1))
	end
	for i = 0, 2 do
		add({ id = "x" .. i, kind = "balloon", decoy = true, n = rng:NextInteger(1, 3) }, pick(ZA, "balloon", 1))
	end
	-- every two rooms joined by a doorway get at least one hiding place
	-- between them. Done after everything the generator checks, so it can
	-- only use slots nothing else needed.
	local function roomAt(x, y)
		for _, f in ipairs(plan.floors) do
			if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
				return f.name
			end
		end
		return nil
	end
	local links, seen = {}, {}
	local function link(a, b)
		if a and b and a ~= b then
			local k = a < b and (a .. "|" .. b) or (b .. "|" .. a)
			if not seen[k] then
				seen[k] = true
				table.insert(links, { a, b })
			end
		end
	end
	for y = 0, plan.h - 1 do
		local row = plan.map[y + 1]
		for x = 0, plan.w - 1 do
			if row and string.sub(row, x + 1, x + 1) ~= "#" then
				local here = roomAt(x, y)
				local near = {}
				for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
					local r = roomAt(x + d[1], y + d[2])
					if r then
						table.insert(near, r)
					end
				end
				if here then
					for _, r in ipairs(near) do
						link(here, r)
					end
				else
					-- a doorway between rooms
					for i = 1, #near do
						for j = i + 1, #near do
							link(near[i], near[j])
						end
					end
				end
			end
		end
	end
	local hidden, extra = {}, 0
	for _, o in ipairs(map.objects) do
		if o.kind == "hide" then
			hidden[roomAt(o.x, o.y) or ""] = true
		end
	end
	for _, l in ipairs(links) do
		if not hidden[l[1]] and not hidden[l[2]] then
			local cands = {}
			for _, s in ipairs(plan.floorSlots) do
				if (s[4] == l[1] or s[4] == l[2]) and ok(s) then
					table.insert(cands, s)
				end
			end
			if #cands > 0 then
				local s = cands[rng:NextInteger(1, #cands)]
				taken[s[1] .. "," .. s[2]] = true
				extra += 1
				local look = HIDE_LOOKS[rng:NextInteger(1, #HIDE_LOOKS)]
				add({ id = "hx" .. extra, kind = "hide", look = look, cap = look == "wardrobe" and 3 or rng:NextInteger(1, 2) }, s)
				hidden[s[4]] = true
			end
		end
	end
	-- posters on walls behind the first locked door, not side by side
	local wtaken = {}
	for _, kind in ipairs({ "invite", "uv" }) do
		local cands = {}
		for _, s in ipairs(plan.wallSlots) do
			if s[3] == 2 and not wtaken[(s[1] - 1) .. "," .. s[2]] and not wtaken[s[1] .. "," .. s[2]] and not wtaken[(s[1] + 1) .. "," .. s[2]] then
				table.insert(cands, s)
			end
		end
		if #cands > 0 then
			local s = cands[rng:NextInteger(1, #cands)]
			wtaken[s[1] .. "," .. s[2]] = true
			table.insert(map.objects, { id = kind, kind = kind, x = s[1], y = s[2], zone = s[3] })
		end
	end
	return map
end

-- the parts of a map the players' screens need (sent as JSON)
function MapGen.forClient(map)
	local objects = {}
	for _, o in ipairs(map.objects) do
		table.insert(objects, { id = o.id, kind = o.kind, x = o.x, y = o.y, n = o.n, zone = o.zone, name = o.name, blocked = o.blocked, bonus = o.bonus })
	end
	return { id = map.id, name = map.name, w = map.w, h = map.h, map = map.map, floors = map.floors, objects = objects, loft = map.loft }
end

return MapGen
