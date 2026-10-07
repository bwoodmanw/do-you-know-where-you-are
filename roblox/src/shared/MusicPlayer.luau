--[[
	MusicPlayer (client) - background music from Config.MUSIC, shuffled, with a
	small music button that steps the volume 100% -> 50% -> 25% -> off, and
	beside it a game-sounds button that does the same for every other sound
	(pops, doors, bounces...). Both are saved with the player's profile (the
	MusicVolume and SfxVolume attributes), so they follow them between the
	Lobby and the game.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Config = require(ReplicatedStorage.Shared.Config)

local MusicPlayer = {}

local STEPS = { 1, 0.5, 0.25, 0 }
local BASE = 0.5 -- music sits under the sound effects

function MusicPlayer.start(listName, gui, position, setRemote, setSfxRemote)
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
	-- what is playing, under the button
	local nowPlaying = Instance.new("TextLabel")
	nowPlaying.Size = UDim2.fromOffset(240, 18)
	nowPlaying.Position = position + UDim2.fromOffset(-144, 38)
	nowPlaying.BackgroundTransparency = 1
	nowPlaying.Font = Enum.Font.FredokaOne
	nowPlaying.TextSize = 14
	nowPlaying.TextXAlignment = Enum.TextXAlignment.Right
	nowPlaying.TextColor3 = Color3.fromRGB(205, 190, 225)
	nowPlaying.TextStrokeTransparency = 0.5
	nowPlaying.Text = ""
	nowPlaying.ZIndex = 5
	nowPlaying.Parent = gui

	local sound = Instance.new("Sound")
	sound.Name = "Music"
	sound.Parent = SoundService

	local function paint()
		btn.Text = level == 0 and "\u{1F507} Off" or ("\u{1F3B5} " .. math.floor(level * 100 + 0.5) .. "%")
		sound.Volume = BASE * level
		nowPlaying.Visible = level > 0
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
		local song = order[index]
		local id = type(song) == "table" and song.id or song
		local name = type(song) == "table" and song.name or nil
		nowPlaying.Text = name and ("\u{266A} " .. name .. (Config.MUSIC_ARTIST and (" - " .. Config.MUSIC_ARTIST) or "")) or ""
		nowPlaying.Visible = level > 0
		sound.SoundId = "rbxassetid://" .. id
		sound.TimePosition = 0
		sound:Play()
	end
	sound.Ended:Connect(nextSong)
	-- keep the music going: when a song has finished (or never loaded in 20
	-- seconds) the next one starts, round and round
	task.spawn(function()
		while sound.Parent do
			task.wait(1)
			local age = os.clock() - startedAt
			if sound.IsLoaded and not sound.IsPlaying and age > 3 then
				nextSong()
			elseif not sound.IsLoaded and age > 20 then
				warn("Music: skipping " .. sound.SoundId .. " (did not load)")
				nextSong()
			end
		end
	end)

	-- game sounds: its own button, just left of the music one
	local Sfx = require(ReplicatedStorage.Shared.Sfx)
	local sfxLevel = player:GetAttribute("SfxVolume") or 1
	local sfxBtn = btn:Clone()
	sfxBtn.Name = "SoundsButton"
	sfxBtn.Position = position - UDim2.fromOffset(102, 0)
	sfxBtn.Visible = true
	sfxBtn.Parent = gui
	local function paintSfx()
		sfxBtn.Text = sfxLevel == 0 and "\u{1F507} Off" or ("\u{1F50A} " .. math.floor(sfxLevel * 100 + 0.5) .. "%")
		Sfx.setVolume(sfxLevel)
	end
	sfxBtn.Activated:Connect(function()
		local i = table.find(STEPS, sfxLevel) or 1
		sfxLevel = STEPS[i % #STEPS + 1]
		paintSfx()
		if setSfxRemote then
			setSfxRemote:FireServer(sfxLevel)
		end
	end)
	player:GetAttributeChangedSignal("SfxVolume"):Connect(function()
		sfxLevel = player:GetAttribute("SfxVolume") or sfxLevel
		paintSfx()
	end)
	task.spawn(function()
		Sfx.group()
		paintSfx()
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
