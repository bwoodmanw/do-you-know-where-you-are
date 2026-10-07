--[[
	Quests - three daily quests per player (Config.QUESTS), shared by the
	Lobby and the game (server only). Each day (UTC) a player gets the same
	three quests in every server (picked from their user id and the day).
	The game counts things as they happen (Quests.bump); a quest that reaches
	its goal pays its points at once.

	Saved in the profile as data.quests = { day = N, list = { { id, n, done } } }
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local Quests = {}

local function today()
	return math.floor(os.time() / 86400)
end
Quests.today = today

local function def(id)
	for _, q in ipairs(Config.QUESTS) do
		if q.id == id then
			return q
		end
	end
	return nil
end
Quests.def = def

-- today's three quests (made fresh on a new day)
function Quests.ensure(data, userId)
	local day = today()
	if type(data.quests) == "table" and data.quests.day == day and type(data.quests.list) == "table" then
		return data.quests
	end
	local rng = Random.new(day * 7919 + (userId % 1000003))
	local pool = {}
	for i = 1, #Config.QUESTS do
		pool[i] = i
	end
	local list = {}
	for _ = 1, math.min(3, #pool) do
		local q = Config.QUESTS[table.remove(pool, rng:NextInteger(1, #pool))]
		table.insert(list, { id = q.id, n = 0, done = false })
	end
	data.quests = { day = day, list = list }
	return data.quests
end

-- count n of something; returns the quests finished just now
function Quests.bump(data, userId, kind, n)
	if not data then
		return {}
	end
	local qs = Quests.ensure(data, userId)
	local finished = {}
	for _, q in ipairs(qs.list) do
		local d = def(q.id)
		if d and d.kind == kind and not q.done then
			q.n = math.min(d.goal, q.n + (n or 1))
			if q.n >= d.goal then
				q.done = true
				data.points = (data.points or 0) + d.points
				if data.stats then
					data.stats.earned = (data.stats.earned or 0) + d.points
				end
				table.insert(finished, d)
			end
		end
	end
	return finished
end

-- seconds until tomorrow's quests
function Quests.secondsLeft()
	return (today() + 1) * 86400 - os.time()
end

return Quests
