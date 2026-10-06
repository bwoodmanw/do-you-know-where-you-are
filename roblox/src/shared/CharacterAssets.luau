--[[
	CharacterAssets (server only) - brings in the characters Brent has saved
	to Roblox (Config.CHARACTER_ASSETS: name -> model asset id), so the Lobby,
	which cannot see the Party House's ServerStorage, can show them in 3D too.

	fill(previews, characters):
	  previews   - a Folder of anchored, script-free copies for 3D viewers
	  characters - optional: ServerStorage.Characters, topped up with any
	               saved character not imported there (the game uses these)
	Characters already in a folder are left alone. Loads in the background.
]]

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local CharacterAssets = {}

local function strip(m)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		end
	end
end

-- the rigged model inside what LoadAsset returns
local function rigged(container)
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("Model") and c:FindFirstChildOfClass("Humanoid") then
			return c
		end
	end
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") then
			return d
		end
	end
	return nil
end

local function has(folder, name)
	if not folder then
		return false
	end
	for _, c in ipairs(folder:GetChildren()) do
		if string.lower(c.Name) == string.lower(name) then
			return true
		end
	end
	return false
end

function CharacterAssets.load(name, id)
	local ok, container = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	if not ok or not container then
		warn("Could not load character " .. name .. " (asset " .. tostring(id) .. "): " .. tostring(container) .. " - is it saved to Roblox by the game's owner?")
		return nil
	end
	local m = rigged(container)
	if not m then
		warn("Character " .. name .. " (asset " .. id .. ") has no Humanoid - run Avatar Setup before Save to Roblox")
		container:Destroy()
		return nil
	end
	m.Parent = nil
	container:Destroy()
	strip(m)
	m.Name = name
	return m
end

function CharacterAssets.fill(previews, characters)
	task.spawn(function()
		for name, id in pairs(Config.CHARACTER_ASSETS or {}) do
			local needPreview = string.sub(name, 1, 4) ~= "Host" and previews and not has(previews, name)
			local needChar = characters and not has(characters, name)
			if typeof(id) == "number" and id > 0 and (needPreview or needChar) then
				local m = CharacterAssets.load(name, id)
				if m then
					if needChar then
						m:Clone().Parent = characters
					end
					if needPreview then
						for _, d in ipairs(m:GetDescendants()) do
							if d:IsA("BasePart") then
								d.Anchored = true
							end
						end
						m.Parent = previews
					else
						m:Destroy()
					end
				end
			end
		end
	end)
end

return CharacterAssets
