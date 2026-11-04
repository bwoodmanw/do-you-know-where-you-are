--[[
	Unlocks - characters you buy or earn first (Config.CHARACTER_UNLOCK; 3 Nov,
	Nutmeg the Christmas reindeer): earned with a season's item in its shop
	(the profile's charsEarned), or a Game Pass. Every other character is
	free, as before. Used by the Lobby and the Party House servers.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Config = require(script.Parent.Config)
local Profile = require(script.Parent.Profile)

local Unlocks = {}
local passCache = {}

-- does this character need unlocking at all?
function Unlocks.locked(id)
	return Config.CHARACTER_UNLOCK[id] ~= nil
end

-- the player may play this character
function Unlocks.owns(plr, id)
	local u = Config.CHARACTER_UNLOCK[id]
	if not u then
		return true
	end
	-- as with skins: free in Studio tests and for the game's owner
	if RunService:IsStudio() and Config.SKINS_FREE_IN_STUDIO then
		return true
	end
	if Config.SKINS_FREE_FOR_OWNER and game.CreatorType == Enum.CreatorType.User and plr.UserId == game.CreatorId then
		return true
	end
	local d = Profile.get(plr)
	if d and d.charsEarned and d.charsEarned[id] then
		return true
	end
	-- 4 Nov: earned by escaping (Cloud, Clone, Harmony, Holly)
	if u.escapes and d and d.stats and (d.stats.escapes or 0) >= u.escapes then
		return true
	end
	if (u.pass or 0) <= 0 then
		return false
	end
	local key = plr.UserId .. ":" .. u.pass
	if passCache[key] == nil then
		local ok, yes = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, u.pass)
		end)
		if not ok then
			return false
		end
		passCache[key] = yes == true
	end
	return passCache[key]
end

-- a pass just bought (PromptGamePassPurchaseFinished): owned from now on
function Unlocks.passBought(plr, passId)
	passCache[plr.UserId .. ":" .. passId] = true
end

-- how a locked character is earned, in words ("escape 10 times - 6 so far")
function Unlocks.howText(id, stats)
	local u = Config.CHARACTER_UNLOCK[id]
	if not u or not u.escapes then
		return nil
	end
	local have = math.min((stats and stats.escapes) or 0, u.escapes)
	return "escape " .. u.escapes .. " times (" .. have .. " so far)"
end

-- every unlockable character's id -> owned, for the player's screens
function Unlocks.all(plr)
	local out = {}
	for id in pairs(Config.CHARACTER_UNLOCK) do
		out[id] = Unlocks.owns(plr, id)
	end
	return out
end

return Unlocks
