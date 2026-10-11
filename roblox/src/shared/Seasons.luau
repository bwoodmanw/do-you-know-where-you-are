-- Seasons: the events come back every year by themselves (SEASONAL_EVENTS.md
-- part 1, 11 Oct 2026). Each season in Config.SEASONS runs from midnight US
-- Eastern on its `from` date to midnight Eastern on its `to` date (a `to`
-- earlier in the year than `from` ends the next year), and its shop stays open
-- `shopDays` more days. The Eastern clock's daylight saving change is worked
-- out for every year - no fixed times to update.
--
-- Each season has its own currency, `item` (corn, feather...), saved in the
-- profile's stats: stats[item] = found in games (the badge and the community
-- meter count only these), stats[item .. "Gift"] = the owner's gifts,
-- stats[item .. "Bought"] = bought for Robux, stats[item .. "Spent"] = spent.
-- Kept between years: corns found in 2026 still spend in 2027.

local Config = require(script.Parent.Config)

local Seasons = {}

local DAY = 86400

-- the time the seasons go by: now, or in Studio the date in
-- Config.STUDIO_SEASON_DATE ({ year, month, day }, noon Eastern, ticking on
-- from when the game started) - to try a season before it starts
local studioStart = os.time()
function Seasons.clock()
	local d = Config.STUDIO_SEASON_DATE
	if d and game:GetService("RunService"):IsStudio() then
		return Seasons.easternMidnight(d[1], d[2], d[3]) + 12 * 3600 + (os.time() - studioStart)
	end
	return os.time()
end

-- days since 1 Jan 1970 for a calendar date (Howard Hinnant's method)
local function daysFromCivil(y, m, d)
	y = m <= 2 and y - 1 or y
	local era = y // 400
	local yoe = y - era * 400
	local mp = (m + 9) % 12
	local doy = (153 * mp + 2) // 5 + d - 1
	local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
	return era * 146097 + doe - 719468
end

-- the calendar date of a day number (the reverse)
local function civilFromDays(z)
	z += 719468
	local era = z // 146097
	local doe = z - era * 146097
	local yoe = (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365
	local y = yoe + era * 400
	local doy = doe - (365 * yoe + yoe // 4 - yoe // 100)
	local mp = (5 * doy + 2) // 153
	local d = doy - (153 * mp + 2) // 5 + 1
	local m = mp < 10 and mp + 3 or mp - 9
	return m <= 2 and y + 1 or y, m, d
end

-- the day of the month of the nth Sunday (1 Jan 1970 was a Thursday)
local function nthSunday(y, m, n)
	local wd = (daysFromCivil(y, m, 1) + 4) % 7 -- 0 = Sunday
	return 1 + (7 - wd) % 7 + (n - 1) * 7
end

-- the UTC time of midnight Eastern at the start of a date. Daylight time runs
-- from the 2nd Sunday of March to the 1st Sunday of November, changing at
-- 2:00 AM - so at midnight on either change day the old clock still holds.
function Seasons.easternMidnight(y, m, d)
	local day = daysFromCivil(y, m, d)
	local dstStart = daysFromCivil(y, 3, nthSunday(y, 3, 2))
	local dstEnd = daysFromCivil(y, 11, nthSunday(y, 11, 1))
	local dst = day > dstStart and day <= dstEnd
	return day * DAY + (dst and 4 or 5) * 3600
end

-- the Eastern calendar date (year, month, day) a UTC time falls on
function Seasons.easternDate(t)
	-- try the daylight-time date first; if its midnight is still ahead, it is
	-- standard time's date
	local y, m, d = civilFromDays((t - 4 * 3600) // DAY)
	if Seasons.easternMidnight(y, m, d) > t then
		y, m, d = civilFromDays((t - 4 * 3600) // DAY - 1)
	end
	return y, m, d
end

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

-- "Nov 8": the last Eastern day before a closing time (American English)
function Seasons.untilText(t)
	local _, m, d = Seasons.easternDate(t - 1)
	return MONTHS[m] .. " " .. d
end

-- a season's start and end (UTC) in the year it starts
function Seasons.window(s, year)
	local startT = Seasons.easternMidnight(year, s.from[1], s.from[2])
	local endYear = (s.to[1] < s.from[1] or (s.to[1] == s.from[1] and s.to[2] <= s.from[2])) and year + 1 or year
	local endT = Seasons.easternMidnight(endYear, s.to[1], s.to[2])
	return startT, endT, startT and endT + (s.shopDays or 0) * DAY
end

-- every season window that touches `now` (this year's and last year's, for a
-- season crossing New Year), with its times: { season, start, ends, shopUntil, year }
local function windows(now)
	local out = {}
	local y = Seasons.easternDate(now)
	for _, s in ipairs(Config.SEASONS or {}) do
		for _, year in ipairs({ y - 1, y }) do
			local a, b, c = Seasons.window(s, year)
			if now >= a and now < c then
				table.insert(out, { season = s, start = a, ends = b, shopUntil = c, year = year })
			end
		end
	end
	return out
end

-- the season running now (its hunt is on), or nil
function Seasons.active(now)
	now = now or Seasons.clock()
	for _, w in ipairs(windows(now)) do
		if now < w.ends then
			return w.season, w
		end
	end
	return nil
end

-- every season whose shop is open now (running, or ended less than
-- shopDays ago), the running one first
function Seasons.shops(now)
	now = now or Seasons.clock()
	local out = windows(now)
	table.sort(out, function(a, b)
		return a.start > b.start
	end)
	return out
end

-- a season by id
function Seasons.get(id)
	for _, s in ipairs(Config.SEASONS or {}) do
		if s.id == id then
			return s
		end
	end
	return nil
end

-- its window now, if its shop is open
function Seasons.openWindow(id, now)
	for _, w in ipairs(Seasons.shops(now)) do
		if w.season.id == id then
			return w
		end
	end
	return nil
end

-- what a player has to spend of a season's currency (stats: the profile's)
function Seasons.have(stats, s)
	stats = stats or {}
	local k = s.item
	return (stats[k] or 0) + (stats[k .. "Gift"] or 0) + (stats[k .. "Bought"] or 0) - (stats[k .. "Spent"] or 0)
end

-- a skin's price in a season's currency: (price, season), or nil for a skin
-- sold only as a Game Pass. The skin names its price by the currency
-- (`corn = 100`, `feather = 150`).
function Seasons.skinPrice(skin)
	for _, s in ipairs(Config.SEASONS or {}) do
		local p = skin[s.item]
		if type(p) == "number" then
			return p, s
		end
	end
	return nil
end

return Seasons
