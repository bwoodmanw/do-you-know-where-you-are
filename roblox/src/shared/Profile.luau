--[[
	Profile - each player's saved progress, shared by the Lobby and the game
	(server only). Points, character XP and upgrade picks, owned boosts,
	the boosts chosen for the next game, unlocked maps, stats, best times.
	Also the global leaderboards.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Profile = {}

local STORE = "EscapeCrew_Profile_v1"
local OLD_POINTS = "DYKWYA_Points_v1"
local store, oldStore
pcall(function()
	store = DataStoreService:GetDataStore(STORE)
	oldStore = DataStoreService:GetDataStore(OLD_POINTS)
end)

local cache = {} -- [userId] = profile table

local function fresh()
	return {
		v = 1,
		points = 0,
		xp = {},
		picks = {}, -- picks[skill][level as string] = upgrade id
		inv = {}, -- owned boosts: inv[boostId] = count
		loadout = {}, -- boosts chosen for the next game (taken from inv)
		unlocked = { partyhouse = true },
		stats = { games = 0, escapes = 0, rescues = 0, earned = 0 }, -- earned: every point ever won, spent or not
		best = {}, -- best["partyhouse_normal"] = seconds
	}
end

local function fill(p)
	local base = fresh()
	for k, v in pairs(base) do
		if p[k] == nil then
			p[k] = v
		end
	end
	if p.stats and p.stats.earned == nil then
		p.stats.earned = math.max(0, p.points or 0) -- older profiles: start from what they hold
	end
	for k, v in pairs(base.stats) do
		if p.stats[k] == nil then
			p.stats[k] = v
		end
	end
	return p
end

function Profile.load(plr)
	local key = "u" .. plr.UserId
	local data
	if store then
		local ok, v = pcall(function()
			return store:GetAsync(key)
		end)
		if ok and type(v) == "table" then
			data = v
		end
	end
	if not data then
		data = fresh()
		-- bring over points from the first version of the game
		if oldStore then
			local ok, v = pcall(function()
				return oldStore:GetAsync("p" .. plr.UserId)
			end)
			if ok and type(v) == "number" then
				data.points = v
			end
		end
	end
	data = fill(data)
	cache[plr.UserId] = data
	Profile.publish(plr)
	return data
end

function Profile.get(plr)
	return cache[plr.UserId]
end

function Profile.save(plr)
	local data = cache[plr.UserId]
	if not data or not store then
		return false
	end
	local ok = pcall(function()
		store:SetAsync("u" .. plr.UserId, data)
	end)
	return ok
end

function Profile.release(plr)
	Profile.save(plr)
	cache[plr.UserId] = nil
end

-- copy what screens need onto the player (attributes replicate to clients)
function Profile.publish(plr)
	local data = cache[plr.UserId]
	if not data then
		return
	end
	plr:SetAttribute("ProfileJson", game:GetService("HttpService"):JSONEncode(data))
	local stats = plr:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = plr
		local pts = Instance.new("IntValue")
		pts.Name = "Points"
		pts.Parent = stats
	end
	stats.Points.Value = data.points
end

function Profile.addPoints(plr, n)
	local data = cache[plr.UserId]
	if data then
		data.points = math.max(0, data.points + n)
		if n > 0 then
			data.stats.earned = (data.stats.earned or 0) + n
		end
		Profile.publish(plr)
	end
end

-- ---------- leaderboards ----------
local function board(name)
	local ok, s = pcall(function()
		return DataStoreService:GetOrderedDataStore(name)
	end)
	return ok and s or nil
end

-- the week number, so "fastest" boards start fresh each week
function Profile.week()
	return math.floor(os.time() / (7 * 86400))
end

-- points = every point ever earned (spending does not lower it); fastest is
-- one weekly board for all maps, keyed "userId|map|difficulty" so each row
-- knows where it was set
function Profile.boardNames()
	return {
		points = "EC_TopEarned",
		escapes = "EC_TopEscapes",
		rescues = "EC_TopRescues",
		fastest = "EC_FastAll_w" .. Profile.week(),
	}
end

-- higher is better for points/rescues; for times we store a negative so the
-- fastest sorts first
function Profile.record(plr, mapId, difficulty, escapedSeconds)
	local data = cache[plr.UserId]
	if not data then
		return
	end
	local names = Profile.boardNames()
	local key = tostring(plr.UserId)
	task.spawn(function()
		local p = board(names.points)
		if p then
			pcall(function()
				p:SetAsync(key, math.floor(data.stats.earned or data.points))
			end)
		end
		local e = board(names.escapes)
		if e then
			pcall(function()
				e:SetAsync(key, data.stats.escapes)
			end)
		end
		local r = board(names.rescues)
		if r then
			pcall(function()
				r:SetAsync(key, data.stats.rescues)
			end)
		end
		if escapedSeconds then
			local f = board(names.fastest)
			if f then
				pcall(function()
					f:UpdateAsync(key .. "|" .. mapId .. "|" .. difficulty, function(old)
						local v = -math.floor(escapedSeconds)
						if old == nil or v > old then
							return v
						end
						return nil
					end)
				end)
			end
		end
	end)
end

local nameCache = {}
local function nameOf(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, n = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = ok and n or ("Player " .. userId)
	return nameCache[userId]
end

-- top N rows: { { name, value, map, difficulty } } (map/difficulty on the fastest board)
function Profile.top(boardName, n, negate)
	local b = board(boardName)
	if not b then
		return {}
	end
	local rows = {}
	local ok, pages = pcall(function()
		return b:GetSortedAsync(false, n)
	end)
	if ok and pages then
		for _, entry in ipairs(pages:GetCurrentPage()) do
			local uid, map, diff = string.match(entry.key, "^(%d+)|?([^|]*)|?([^|]*)$")
			table.insert(rows, { name = nameOf(tonumber(uid)), value = negate and -entry.value or entry.value, map = map, difficulty = diff })
		end
	end
	return rows
end

return Profile
