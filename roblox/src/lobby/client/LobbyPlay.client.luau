-- LobbyPlay (5 Nov, Brent): the player's side of the bounce course and the
-- seasonal rides (server: LobbyPlay.luau). The bounce happens here, where the
-- character's physics run; riding: the sitting pose, the sleigh and broom
-- floating down slowly, a Get off button.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("LobbyRemotes")

local Sfx = require(ReplicatedStorage.Shared.Sfx)
local function sound(id, parent, volume)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume or 0.6
	s.SoundGroup = Sfx.group() -- (the sound button's volume)
	s.Parent = parent
	s:Play()
	game:GetService("Debris"):AddItem(s, 3)
end

-- ---------- the bounce pads ----------
do
	local last = 0
	local function hook(pad)
		if not pad:IsA("BasePart") or pad.Name ~= "BouncePad" then
			return
		end
		pad.Touched:Connect(function(hit)
			local char = player.Character
			if not char or not hit:IsDescendantOf(char) or os.clock() - last < 0.4 then
				return
			end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then
				return
			end
			last = os.clock()
			local v = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, pad:GetAttribute("Bounce") or 82, v.Z)
			sound(Config.SOUNDS.bounce, pad, 0.6)
		end)
	end
	task.spawn(function()
		local folder = workspace:WaitForChild("LobbyPlay", 60)
		local course = folder and folder:WaitForChild("BounceCourse", 30)
		if not course then
			return
		end
		for _, d in ipairs(course:GetDescendants()) do
			hook(d)
		end
		course.DescendantAdded:Connect(hook)
	end)
end

-- ---------- riding ----------
do
	local RideOff = remotes:WaitForChild("RideOff", 30)
	local gui = Instance.new("ScreenGui")
	gui.Name = "RideGui"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local off = Instance.new("TextButton")
	off.Size = UDim2.fromOffset(150, 46)
	off.AnchorPoint = Vector2.new(0.5, 0)
	off.Position = UDim2.new(0.5, 0, 0, 120)
	off.BackgroundColor3 = Color3.fromRGB(232, 80, 91)
	off.TextColor3 = Color3.fromRGB(255, 244, 224)
	off.Font = Enum.Font.FredokaOne
	off.TextScaled = true
	off.Text = "Get off"
	off.Visible = false
	off.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = off
	off.Activated:Connect(function()
		if RideOff then
			RideOff:FireServer()
		end
	end)

	local track
	local function pose()
		if track then
			track:Stop(0.2)
			track = nil
		end
		local kind = player:GetAttribute("Riding")
		off.Visible = kind ~= nil
		if not kind then
			return
		end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		if animator then
			local a = Instance.new("Animation")
			a.AnimationId = "rbxassetid://2506281703" -- Roblox's R15 sit
			local ok, t = pcall(function()
				return animator:LoadAnimation(a)
			end)
			if ok and t then
				t.Priority = Enum.AnimationPriority.Action
				t.Looped = true
				t:Play(0.2)
				track = t
			end
		end
	end
	player:GetAttributeChangedSignal("Riding"):Connect(pose)
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		pose()
	end)
	pose()

	-- the sleigh and the broom float down slowly; a jingle as the sleigh jumps
	local wasFalling = false
	RunService.Heartbeat:Connect(function()
		local kind = player:GetAttribute("Riding")
		if kind ~= "sleigh" and kind ~= "broom" then
			return
		end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		local v = hrp.AssemblyLinearVelocity
		if v.Y < -12 then
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, -12, v.Z)
		end
		local up = v.Y > 20
		if up and not wasFalling and kind == "sleigh" then
			sound(Config.SOUNDS.bell, hrp, 0.35)
		end
		wasFalling = up
	end)
end
