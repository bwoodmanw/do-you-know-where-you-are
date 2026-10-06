--[[
	MusicPlayer (client) - background music from Config.MUSIC, shuffled, with a
	small music button that steps the volume 100% -> 50% -> 25% -> off. The
	choice is saved with the player's profile (the server keeps it in the
	MusicVolume attribute), so it follows them between the Lobby and the game.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Config = require(ReplicatedStorage.Shared.Config)

local MusicPlayer = {}

local STEPS = { 1, 0.5, 0.25, 0 }
local BASE = 0.5 -- music sits under the sound effects

function MusicPlayer.start(listName, gui, position, setRemote)
	local ids = (Config.MUSIC and Config.MUSIC[listName]) or {}
	local player = Players.LocalPlayer
	local level = player:GetAttribute("MusicVolume") or 0.5

	local btn = Instance.new("TextButton")
	btn.Name = "MusicButton"
	btn.Size = UDim2.fromOffset(96, 36)
	btn.Position = position
	btn.BackgroundColor3 = Color3.fromRGB(26, 16, 38)
	btn.BackgroundTransparency = 0.2
	btn.TextColor3 = Color3.fromRGB(255, 244, 224)
	btn.Font = Enum.Font.FredokaOne
	btn.TextScaled = true
	btn.ZIndex = 5
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn
	btn.Visible = #ids > 0
	btn.Parent = gui

	local sound = Instance.new("Sound")
	sound.Name = "Music"
	sound.Parent = SoundService

	local function paint()
		btn.Text = level == 0 and "\u{1F507} Off" or ("\u{1F3B5} " .. math.floor(level * 100 + 0.5) .. "%")
		sound.Volume = BASE * level
	end

	-- a shuffled playlist that goes round and round (a fresh shuffle every
	-- visit: Random.new() is seeded differently each time)
	local rng = Random.new()
	local order = table.clone(ids)
	for i = #order, 2, -1 do
		local j = rng:NextInteger(1, i)
		order[i], order[j] = order[j], order[i]
	end
	local index = 0
	local startedAt = os.clock()
	local function nextSong()
		if #order == 0 then
			return
		end
		index = index % #order + 1
		startedAt = os.clock()
		sound.SoundId = "rbxassetid://" .. order[index]
		sound.TimePosition = 0
		sound:Play()
	end
	sound.Ended:Connect(nextSong)
	-- a song that still has not loaded after 20 seconds (not allowed in this
	-- game, or not approved yet): skip it. Long songs can take a while to load.
	task.spawn(function()
		while sound.Parent do
			task.wait(2)
			if #order > 1 and not sound.IsLoaded and os.clock() - startedAt > 20 then
				warn("Music: skipping " .. sound.SoundId .. " (did not load)")
				nextSong()
			end
		end
	end)

	btn.Activated:Connect(function()
		local i = table.find(STEPS, level) or 1
		level = STEPS[i % #STEPS + 1]
		paint()
		if setRemote then
			setRemote:FireServer(level)
		end
	end)
	player:GetAttributeChangedSignal("MusicVolume"):Connect(function()
		level = player:GetAttribute("MusicVolume") or level
		paint()
	end)
	paint()
	nextSong()
	return sound
end

return MusicPlayer
