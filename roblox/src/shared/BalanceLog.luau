--[[
	BalanceLog - one line of totals per floor and difficulty, saved in the
	EscapeCrewBalance DataStore, so the host can be tuned from real games.
	The Party House adds every finished game; the Lobby shows the table to the
	experience's owner only (the 📊 Balance button).
	A row: games, won (someone escaped), kids, escaped (kids who got out),
	secs (total seconds of the games that were won).
]]

local DataStoreService = game:GetService("DataStoreService")

local BalanceLog = {}
local KEY = "v1"

local function store()
	return DataStoreService:GetDataStore("EscapeCrewBalance")
end

-- level: the party's average character level (3 Nov) - each row keeps the
-- sum, `lvl`, so the panel shows the average level of its games
function BalanceLog.record(mapId, diff, kids, escaped, seconds, won, level)
	-- 3 Nov: Studio test games no longer count (59 "Aquarium: Main Hall"
	-- Normal games, every one lost, were Studio Plays - Config.STUDIO_MAP)
	if game:GetService("RunService"):IsStudio() then
		return
	end
	task.spawn(function()
		local ok, err = pcall(function()
			store():UpdateAsync(KEY, function(old)
				old = old or {}
				local k = mapId .. "|" .. diff
				local r = old[k] or { games = 0, won = 0, kids = 0, escaped = 0, secs = 0 }
				r.games += 1
				if level then
					r.lvl = (r.lvl or 0) + level
					r.lvlGames = (r.lvlGames or 0) + 1
				end
				r.kids += kids
				r.escaped += escaped
				if won then
					r.won += 1
					r.secs += seconds
				end
				old[k] = r
				return old
			end)
		end)
		if not ok then
			warn("Balance log: could not save (" .. tostring(err) .. ")")
		end
	end)
end

function BalanceLog.read()
	local ok, v = pcall(function()
		return store():GetAsync(KEY)
	end)
	return ok and v or nil
end

return BalanceLog
