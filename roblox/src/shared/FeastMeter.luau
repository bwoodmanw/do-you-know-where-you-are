--[[
	FeastMeter - the community goal (Thanksgiving, Brent 11 Oct): every
	runaway turkey caught in every server adds up, for this season and year
	(DataStore "FeastMeter", key e.g. "thanksgiving2026"). Servers only.

	The game adds (FeastMeter.add): caught turkeys are kept and written in one
	go about once a minute (DataStore limits), and once more when the server
	closes. The Lobby reads (FeastMeter.get), cached for a minute.
	Stages and rewards: Config.FEAST. In Studio without API access it counts
	in this server only (no error).
]]

local Config = require(script.Parent.Config)
local Seasons = require(script.Parent.Seasons)

local FeastMeter = {}

local STORE_NAME = "FeastMeter"
local store
local function getStore()
	if store == nil then
		local ok, s = pcall(function()
			return game:GetService("DataStoreService"):GetDataStore(STORE_NAME)
		end)
		store = ok and s or false
	end
	return store or nil
end

-- the key for the running season (or nil out of season / a season without a meter)
function FeastMeter.key()
	local s, w = Seasons.active()
	if not s or not (Config.FEAST and Config.FEAST[s.id]) then
		return nil
	end
	return s.id .. tostring(w.year), s.id
end

-- ---------- the game: add caught turkeys ----------
local pending, local_total = 0, 0
local flushing = false
local function flush()
	if flushing or pending <= 0 then
		return
	end
	local key = FeastMeter.key()
	local ds = getStore()
	if not key or not ds then
		pending = 0
		return
	end
	flushing = true
	local n = pending
	pending = 0
	local ok, err = pcall(function()
		ds:UpdateAsync(key, function(old)
			return (tonumber(old) or 0) + n
		end)
	end)
	if not ok then
		pending += n -- try again next time
		warn("[FeastMeter] could not save " .. n .. " turkeys: " .. tostring(err))
	end
	flushing = false
end

local started = false
function FeastMeter.add(n)
	pending += n
	local_total += n
	if not started then
		started = true
		task.spawn(function()
			while true do
				task.wait(60)
				flush()
			end
		end)
		game:BindToClose(flush)
	end
end

-- ---------- the Lobby: read the total ----------
local cache, cacheAt, cacheKey = 0, -math.huge, nil
function FeastMeter.get()
	local key = FeastMeter.key()
	if not key then
		return 0, nil
	end
	if key == cacheKey and os.clock() - cacheAt < 60 then
		return cache, key
	end
	local ds = getStore()
	local ok, v = false, nil
	if ds then
		ok, v = pcall(function()
			return ds:GetAsync(key)
		end)
	end
	cache = ok and (tonumber(v) or 0) or math.max(cache, local_total)
	cacheAt, cacheKey = os.clock(), key
	return cache, key
end

-- the stages reached at `total` (Config.FEAST[seasonId].stages, in order)
function FeastMeter.reached(seasonId, total)
	local out = {}
	for i, st in ipairs((Config.FEAST and Config.FEAST[seasonId] or {}).stages or {}) do
		if total >= st.at then
			table.insert(out, i)
		end
	end
	return out
end

return FeastMeter
