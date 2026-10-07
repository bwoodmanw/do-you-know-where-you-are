--[[
	Sfx - every game sound (pops, doors, bounces, the host's breathing...)
	plays through one SoundGroup, SoundService/GameSounds, so each player
	can turn game sounds up or down on their own screen, apart from the
	music. The server makes the group; a player's volume is set only on
	their own screen (a client-side change is not copied to anyone else).
]]

local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Sfx = {}

function Sfx.group()
	local g = SoundService:FindFirstChild("GameSounds")
	if not g and RunService:IsClient() then
		g = SoundService:WaitForChild("GameSounds", 5)
	end
	if not g then
		g = Instance.new("SoundGroup")
		g.Name = "GameSounds"
		g.Volume = 1
		g.Parent = SoundService
	end
	return g
end

-- this player's game-sound volume (0..1), on every GameSounds group
function Sfx.setVolume(v)
	for _, g in ipairs(SoundService:GetChildren()) do
		if g:IsA("SoundGroup") and g.Name == "GameSounds" then
			g.Volume = v
		end
	end
end

return Sfx
