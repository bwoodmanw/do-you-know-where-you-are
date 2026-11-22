--[[
	Speedrun - the Weekly Speedrun Challenge (22 Nov, Brent: bring in older
	players). Every week one floor is the challenge floor. Escape it on Hard
	or Nightmare within the par time and you get bonus points (once a week)
	and the Speedrunner badge (Config.BADGES.speedrun).
	The week is Profile.week() - the same week as the "Fastest escapes this
	week" board, so both change together (Wednesday 7 PM Eastern / Thursday
	00:00 UTC).
]]

local Config = require(script.Parent.Config)
local Progress = require(script.Parent.Progress)

local Speedrun = {}

-- the floors that take turns: every year-round floor, not the Secret Basement
-- or a season floor (those are not open to everyone all year)
function Speedrun.floors()
	local out = {}
	for _, m in ipairs(Progress.MAPS) do
		if m.ready and not m.secret and not m.season then
			table.insert(out, m)
		end
	end
	return out
end

function Speedrun.week()
	return math.floor(os.time() / (7 * 86400))
end

-- this week's challenge: { map = <Progress.MAPS entry>, week = n, par = { hard = s, nightmare = s } }
-- The order is shuffled by a fixed step so one building's floors don't come
-- three weeks running
function Speedrun.current(week)
	week = week or Speedrun.week()
	local floors = Speedrun.floors()
	if #floors == 0 then
		return nil
	end
	-- a step sharing no factor with the number of floors, so every floor gets a turn
	local function gcd(a, b)
		while b ~= 0 do
			a, b = b, a % b
		end
		return a
	end
	local step = 7
	while gcd(step, #floors) ~= 1 do
		step += 1
	end
	local i = (week * step) % #floors + 1
	return { map = floors[i], week = week, par = Config.SPEEDRUN.par }
end

-- seconds as 3:05
function Speedrun.clock(s)
	s = math.max(0, math.floor(s or 0))
	return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

-- did this escape beat the challenge? (mapId, difficulty id, seconds)
function Speedrun.beats(mapId, diff, seconds)
	local c = Speedrun.current()
	local par = c and c.par[diff]
	return c ~= nil and c.map.id == mapId and par ~= nil and seconds <= par, c
end

return Speedrun
