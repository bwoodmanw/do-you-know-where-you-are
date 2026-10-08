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
		stats = { games = 0, escapes = 0, rescues = 0, earned = 0, corn = 0 }, -- earned: every point ever won, spent or not; corn: candy corns found (Halloween)
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
	-- daily rewards were not counted as earned before 8 Oct: what you hold
	-- was earned at some point, so "earned" is never less than it
	p.stats.earned = math.max(p.stats.earned or 0, p.points or 0)
	return p
end

--[[
	Save safety. A player's save is "held" by the server they are in: the
	save carries _lock = { job = that server, t = when }. A server only loads
	a save nobody else holds (it waits up to LOCK_WAIT seconds for the place
	they came from to let go), and only writes a save it still holds. Leaving
	writes the save and lets go in one step. So the trip Lobby -> game ->
	Lobby can never load old data or write over newer data.
]]
local LOCK_WAIT = 20 -- seconds to wait for the last server to let go
local LOCK_STALE = 300 -- a hold older than this belongs to a server that died
local JOB = game.JobId

local function heldByOther(v)
	return type(v) == "table" and type(v._lock) == "table" and v._lock.job ~= JOB and os.time() - (v._lock.t or 0) < LOCK_STALE
end

function Profile.load(plr)
	local key = "u" .. plr.UserId
	local data
	if store then
		local started = os.clock()
		while plr.Parent and not data do
			local force = os.clock() - started > LOCK_WAIT
			local got
			local ok = pcall(function()
				store:UpdateAsync(key, function(old)
					got = nil -- Roblox may run this more than once: only the last run counts
					if heldByOther(old) and not force then
						return nil -- another server still has it: wait
					end
					local d = type(old) == "table" and old or { _new = true }
					d._lock = { job = JOB, t = os.time() }
					got = d
					return d
				end)
			end)
			if ok and got then
				data = got
			elseif not ok then
				task.wait(2)
			else
				task.wait(1.5)
			end
			if not ok and os.clock() - started > LOCK_WAIT + 10 then
				break -- the save service is down: play on with a fresh profile, saved later
			end
		end
	end
	if not data or data._new then
		-- a first visit: a fresh profile (still holding the lock if we took one)
		local lock = data and data._lock
		data = fresh()
		data._lock = lock
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
	plr:SetAttribute("MusicVolume", (data.settings and data.settings.music) or 0.5)
	plr:SetAttribute("SfxVolume", (data.settings and data.settings.sfx) or 1)
	cache[plr.UserId] = data
	Profile.publish(plr)
	return data
end

function Profile.get(plr)
	return cache[plr.UserId]
end

-- write the save (and keep holding it, unless letting go); false if it could
-- not be written, or another server holds it now
local function write(userId, letGo)
	local data = cache[userId]
	if not data or not store then
		return false
	end
	local wrote = false
	local ok = pcall(function()
		store:UpdateAsync("u" .. userId, function(old)
			wrote = false -- Roblox may run this more than once: only the last run counts
			if heldByOther(old) then
				return nil -- someone else has it now: never write over newer data
			end
			data._lock = (not letGo) and { job = JOB, t = os.time() } or nil
			wrote = true
			return data
		end)
	end)
	return ok and wrote
end

function Profile.save(plr)
	return write(plr.UserId, false)
end

function Profile.release(plr)
	write(plr.UserId, true)
	cache[plr.UserId] = nil
end

-- every minute: save everyone here (keeps the hold fresh; a crash loses a minute at most)
if game:GetService("RunService"):IsServer() then
	task.spawn(function()
		while true do
			task.wait(60)
			for userId in pairs(cache) do
				task.spawn(write, userId, false)
			end
		end
	end)
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

-- a player's music volume (0, 0.25, 0.5 or 1)
function Profile.setMusic(plr, v)
	local data = cache[plr.UserId]
	if not data or typeof(v) ~= "number" or v < 0 or v > 1 then
		return
	end
	data.settings = data.settings or {}
	data.settings.music = v
	plr:SetAttribute("MusicVolume", v)
end

-- a player's game-sound volume (0, 0.25, 0.5 or 1)
function Profile.setSfx(plr, v)
	local data = cache[plr.UserId]
	if not data or typeof(v) ~= "number" or v < 0 or v > 1 then
		return
	end
	data.settings = data.settings or {}
	data.settings.sfx = v
	plr:SetAttribute("SfxVolume", v)
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
		floors = "EC_TopFloors", -- how many different floors escaped
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
		local fl = board(names.floors)
		if fl then
			local n = 0
			for _ in pairs(data.cleared or {}) do
				n += 1
			end
			pcall(function()
				fl:SetAsync(key, n)
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
			table.insert(rows, { name = nameOf(tonumber(uid)), userId = tonumber(uid), value = negate and -entry.value or entry.value, map = map, difficulty = diff })
		end
	end
	return rows
end

return Profile
