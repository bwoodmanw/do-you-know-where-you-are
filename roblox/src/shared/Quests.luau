--[[
	Quests - daily and weekly quests (Config.QUESTS, Config.WEEKLY_QUESTS),
	shared by the Lobby and the game (server only). Every day (UTC) a player
	gets 3 daily quests, every week (from Monday, UTC) 3 weekly ones, the same
	in every server (picked from their user id and the day / week). The game
	counts things as they happen (Quests.bump); a quest that reaches its goal
	pays at once: points, and for a weekly quest a boost in the bag too.

	Saved in the profile as
	  data.quests = { day = N, list = { { id, n, done } } }
	  data.weekly = { week = N, list = { { id, n, done } } }
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local Quests = {}

local function today()
	return math.floor(os.time() / 86400)
end
Quests.today = today
-- weeks start on Monday (1 Jan 1970 was a Thursday)
local function thisWeek()
	return math.floor((os.time() + 3 * 86400) / (7 * 86400))
end
Quests.thisWeek = thisWeek

local function defIn(pool, id)
	for _, q in ipairs(pool) do
		if q.id == id then
			return q
		end
	end
	return nil
end
function Quests.def(id)
	return defIn(Config.QUESTS, id) or defIn(Config.WEEKLY_QUESTS or {}, id)
end

-- a fresh set of 3 from a pool, or the saved one with any quest no longer on
-- the list swapped for one the player does not have
local function ensureSet(saved, key, period, pool, seed)
	if type(saved) == "table" and saved[key] == period and type(saved.list) == "table" then
		for i, q in ipairs(saved.list) do
			if not defIn(pool, q.id) then
				local have = {}
				for _, o in ipairs(saved.list) do
					have[o.id] = true
				end
				for _, d in ipairs(pool) do
					if not have[d.id] then
						saved.list[i] = { id = d.id, n = 0, done = false }
						break
					end
				end
			end
		end
		return saved
	end
	local rng = Random.new(seed)
	local order = {}
	for i = 1, #pool do
		order[i] = i
	end
	local list = {}
	for _ = 1, math.min(3, #order) do
		local q = pool[table.remove(order, rng:NextInteger(1, #order))]
		table.insert(list, { id = q.id, n = 0, done = false })
	end
	return { [key] = period, list = list }
end

-- today's and this week's quests (made fresh when the day / week turns)
function Quests.ensure(data, userId)
	local day, week = today(), thisWeek()
	data.quests = ensureSet(data.quests, "day", day, Config.QUESTS, day * 7919 + (userId % 1000003))
	data.weekly = ensureSet(data.weekly, "week", week, Config.WEEKLY_QUESTS or {}, week * 104729 + (userId % 999983))
	return data.quests
end

-- count n of something; returns the quests finished just now
-- (each with weekly = true for a weekly one)
function Quests.bump(data, userId, kind, n)
	if not data then
		return {}
	end
	Quests.ensure(data, userId)
	local finished = {}
	for _, set in ipairs({ { data.quests, Config.QUESTS, false }, { data.weekly, Config.WEEKLY_QUESTS or {}, true } }) do
		for _, q in ipairs(set[1].list) do
			local d = defIn(set[2], q.id)
			if d and d.kind == kind and not q.done then
				q.n = math.min(d.goal, q.n + (n or 1))
				if q.n >= d.goal then
					q.done = true
					data.points = (data.points or 0) + d.points
					if data.stats then
						data.stats.earned = (data.stats.earned or 0) + d.points
					end
					if d.boost then
						data.inv = data.inv or {}
						data.inv[d.boost] = (data.inv[d.boost] or 0) + 1
					end
					table.insert(finished, { text = d.text, points = d.points, boost = d.boost, weekly = set[3] })
				end
			end
		end
	end
	return finished
end

-- seconds until tomorrow's quests / next week's
function Quests.secondsLeft()
	return (today() + 1) * 86400 - os.time()
end
function Quests.weekSecondsLeft()
	return (thisWeek() + 1) * 7 * 86400 - 3 * 86400 - os.time()
end

return Quests
