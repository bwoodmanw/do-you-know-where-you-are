--[[
	Places - finds the Lobby and the Party House in this experience by name
	(Asset Manager -> Places), so no place ids need copying into the code.
	Server only. Returns nil for a place that does not exist yet, and always
	nil inside a Studio test (teleports only work in the published game).
]]

local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local Config = require(script.Parent.Config)

local Places = {}
local cache = nil

local function load()
	if cache then
		return cache
	end
	cache = {}
	local ok, pages = pcall(function()
		return AssetService:GetGamePlacesAsync()
	end)
	if not ok then
		return cache
	end
	while true do
		for _, place in ipairs(pages:GetCurrentPage()) do
			cache[place.Name] = place.PlaceId
		end
		if pages.IsFinished then
			break
		end
		local more = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not more then
			break
		end
	end
	return cache
end

function Places.lobby()
	if RunService:IsStudio() then
		return nil
	end
	return load()[Config.LOBBY_PLACE]
end

function Places.game()
	if RunService:IsStudio() then
		return nil
	end
	return load()[Config.GAME_PLACE]
end

return Places
