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

-- ---------- the swing (6 Nov, Brent) ----------
-- It swings here, on every player's screen in time (the server's clock),
-- and carries you while you stand on it
do
	local seat, ropes, last
	RunService.Stepped:Connect(function()
		if not seat or not seat.Parent then
			seat, last = nil, nil
			local f = workspace:FindFirstChild("LobbyPlay")
			local c = f and f:FindFirstChild("BounceCourse")
			local m = c and c:FindFirstChild("SkySwing")
			seat = m and m:FindFirstChild("SwingSeat")
			if not seat then
				return
			end
			ropes = {}
			for _, r in ipairs(m:GetChildren()) do
				if r.Name == "SwingRope" then
					table.insert(ropes, r)
				end
			end
		end
		local P, R = seat:GetAttribute("Pivot"), seat:GetAttribute("Radius")
		if typeof(P) ~= "Vector3" or not R then
			return
		end
		local t = workspace:GetServerTimeNow()
		local a = math.rad(seat:GetAttribute("Swing") or 40) * math.sin(t * 2 * math.pi / (seat:GetAttribute("Period") or 5))
		local center = P + Vector3.new(0, -R * math.cos(a), R * math.sin(a))
		local old = last or center
		last = center
		seat.CFrame = CFrame.new(center)
		for _, r in ipairs(ropes) do
			local dx = r:GetAttribute("Side") or 0
			local top = P + Vector3.new(dx, 0, 0)
			local bottom = center + Vector3.new(dx, 0.4, 0)
			r.Size = Vector3.new(0.25, 0.25, (bottom - top).Magnitude)
			r.CFrame = CFrame.lookAt((top + bottom) / 2, bottom)
		end
		-- standing on it: you move with it
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.FloorMaterial ~= Enum.Material.Air then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { seat }
			if workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), params) then
				hrp.CFrame += center - old
			end
		end
	end)
end

-- ---------- the string of lights and the ice bridge (6 Nov, Brent) ----------
-- The lights swing here in time with everyone's (the server's clock). Jump at
-- the glowing handle to grab it; you hang on as it swings; jump again to let
-- go - you fly off the way it was swinging. On the ice bridge you keep
-- sliding the way you were going and the ice nudges you sideways
do
	local UserInputService = game:GetService("UserInputService")
	local handle, parts, lastH
	local grabbed, letGoAt, swingVel = false, 0, Vector3.zero
	local hint = Instance.new("TextLabel")
	do
		local g = Instance.new("ScreenGui")
		g.Name = "SwingHint"
		g.ResetOnSpawn = false
		g.Parent = player:WaitForChild("PlayerGui")
		hint.Size = UDim2.fromOffset(300, 40)
		hint.AnchorPoint = Vector2.new(0.5, 0)
		hint.Position = UDim2.new(0.5, 0, 0, 172)
		hint.BackgroundColor3 = Color3.fromRGB(40, 22, 62)
		hint.BackgroundTransparency = 0.2
		hint.TextColor3 = Color3.fromRGB(255, 230, 120)
		hint.Font = Enum.Font.FredokaOne
		hint.TextScaled = true
		hint.Text = "\u{1F384} Jump to let go!"
		hint.Visible = false
		hint.Parent = g
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 10)
		c.Parent = hint
	end
	local function letGo(jump)
		if not grabbed then
			return
		end
		grabbed = false
		letGoAt = os.clock()
		hint.Visible = false
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		if hrp then
			hrp.AssemblyLinearVelocity = swingVel + Vector3.new(0, jump and 28 or 0, 0)
		end
	end
	UserInputService.JumpRequest:Connect(function()
		if grabbed and os.clock() - letGoAt > 0.3 then
			letGo(true)
		end
	end)
	player.CharacterAdded:Connect(function()
		grabbed = false
		hint.Visible = false
	end)
	local slide, slideOn = Vector3.zero, false
	RunService.Stepped:Connect(function(_, dt)
		if not handle or not handle.Parent then
			handle, lastH = nil, nil
			local f = workspace:FindFirstChild("LobbyPlay")
			local c = f and f:FindFirstChild("BounceCourse")
			local m = c and c:FindFirstChild("LightSwing")
			handle = m and m:FindFirstChild("LightGrab")
			parts = {}
			if m then
				for _, d in ipairs(m:GetChildren()) do
					if d.Name == "LightBulb" or d.Name == "LightStrand" then
						table.insert(parts, d)
					end
				end
			end
		end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if handle then
			local P, R = handle:GetAttribute("Pivot"), handle:GetAttribute("Radius")
			if typeof(P) == "Vector3" and R then
				local t = workspace:GetServerTimeNow()
				local a = math.rad(handle:GetAttribute("Swing") or 40) * math.sin(t * 2 * math.pi / (handle:GetAttribute("Period") or 5))
				local dir = Vector3.new(0, -math.cos(a), math.sin(a))
				local H = P + dir * R
				if lastH and dt > 0 then
					swingVel = (H - lastH) / dt
				end
				lastH = H
				handle.CFrame = CFrame.new(H)
				for _, d in ipairs(parts) do
					if d.Name == "LightStrand" then
						d.Size = Vector3.new(0.2, 0.2, R)
						d.CFrame = CFrame.lookAt(P + dir * (R / 2), H)
					else
						d.CFrame = CFrame.lookAt(P + dir * (R * (d:GetAttribute("Along") or 0.5)), H)
					end
				end
				if hum and hrp and hum.Health > 0 then
					local hang = H - Vector3.new(0, 2.6, 0)
					if grabbed then
						hrp.CFrame = CFrame.lookAt(hang, hang + Vector3.new(0, 0, 1))
						hrp.AssemblyLinearVelocity = swingVel
					elseif os.clock() - letGoAt > 0.8 and hum.FloorMaterial == Enum.Material.Air and (hrp.Position - hang).Magnitude < 4 then
						grabbed = true
						hum.PlatformStand = true
						-- (6 Nov: the season's words and sound, from the handle)
						local say = handle:GetAttribute("Hint")
						hint.Text = typeof(say) == "string" and say or "\u{1F384} Jump to let go!"
						hint.Visible = true
						sound(Config.SOUNDS[handle:GetAttribute("Sound") or "bell"] or Config.SOUNDS.bell, handle, 0.4)
					end
				end
			end
		end
		-- the ice bridge
		if hum and hrp and not grabbed then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { char }
			local hit = hum.FloorMaterial ~= Enum.Material.Air and workspace:Raycast(hrp.Position, Vector3.new(0, -8, 0), params)
			local v = hrp.AssemblyLinearVelocity
			if hit and hit.Instance.Name == "IceBridge" then
				if not slideOn then
					slide = Vector3.new(v.X, 0, v.Z)
					slideOn = true
				end
				local across = hit.Instance.CFrame.RightVector
				local k = math.clamp((dt or 1 / 60) * 60, 0.2, 3)
				slide = slide * (1 - 0.015 * k) + hum.MoveDirection * hum.WalkSpeed * 0.015 * k
					+ across * math.sin(workspace:GetServerTimeNow() * 1.7) * 0.04 * k
				hrp.AssemblyLinearVelocity = Vector3.new(slide.X, v.Y, slide.Z)
			else
				slideOn = false
			end
		end
	end)
end

-- ---------- the Sky Perch's star: fireworks, then gone till tomorrow (6 Nov) ----------
task.spawn(function()
	local TweenService = game:GetService("TweenService")
	local Debris = game:GetService("Debris")
	local COLORS = { Color3.fromRGB(255, 80, 90), Color3.fromRGB(90, 220, 120), Color3.fromRGB(255, 215, 70), Color3.fromRGB(90, 160, 255), Color3.fromRGB(220, 120, 255), Color3.fromRGB(255, 255, 255) }
	local function starPart()
		local f = workspace:FindFirstChild("LobbyPlay")
		local c = f and f:FindFirstChild("BounceCourse")
		return c and c:FindFirstChild("PerchStar")
	end
	local function paint()
		local s = starPart()
		if not s then
			return
		end
		local done = player:GetAttribute("PerchDone") == true
		s.Transparency = done and 1 or 0
		for _, d in ipairs(s:GetChildren()) do
			if d:IsA("Light") then
				d.Enabled = not done
			end
		end
	end
	local function burst(at)
		local from = at + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
		local to = at + Vector3.new(math.random(-10, 10), math.random(12, 20), math.random(-10, 10))
		local col = COLORS[math.random(#COLORS)]
		local rocket = Instance.new("Part")
		rocket.Shape = Enum.PartType.Ball
		rocket.Size = Vector3.new(0.6, 0.6, 0.6)
		rocket.Material = Enum.Material.Neon
		rocket.Color = col
		rocket.Anchored, rocket.CanCollide, rocket.CanQuery, rocket.CanTouch = true, false, false, false
		rocket.Position = from
		rocket.Parent = workspace
		Debris:AddItem(rocket, 4)
		local tw = TweenService:Create(rocket, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = to })
		tw:Play()
		tw.Completed:Wait()
		rocket.Transparency = 1
		local e = Instance.new("ParticleEmitter")
		e.Rate = 0
		e.Color = ColorSequence.new(col, Color3.new(1, 1, 1))
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
		e.Speed = NumberRange.new(16, 26)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Drag = 2.5
		e.Acceleration = Vector3.new(0, -8, 0)
		e.Lifetime = NumberRange.new(1, 1.6)
		e.Parent = rocket
		e:Emit(90)
		local glow = Instance.new("PointLight")
		glow.Color, glow.Range, glow.Brightness = col, 30, 3
		glow.Parent = rocket
		sound(Config.SOUNDS.pop, rocket, 0.7)
		task.delay(0.5, function()
			glow.Enabled = false
		end)
	end
	local PerchWin = remotes:WaitForChild("PerchWin", 60)
	if PerchWin then
		PerchWin.OnClientEvent:Connect(function(at)
			if typeof(at) ~= "Vector3" then
				return
			end
			local s = starPart()
			if s then
				sound(Config.SOUNDS.escape, s, 0.6)
			end
			for i = 1, 8 do
				task.delay((i - 1) * 0.3, burst, at)
			end
			task.delay(0.3, paint)
		end)
	end
	player:GetAttributeChangedSignal("PerchDone"):Connect(paint)
	local folder = workspace:WaitForChild("LobbyPlay", 60)
	local course = folder and folder:WaitForChild("BounceCourse", 30)
	if course then
		course.ChildAdded:Connect(function(c)
			if c.Name == "PerchStar" then
				task.defer(paint)
			end
		end)
	end
	paint()
end)

-- ---------- riding ----------
do
	local RideOff = remotes:WaitForChild("RideOff", 30)
	local gui = Instance.new("ScreenGui")
	gui.Name = "RideGui"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	-- 7 Nov (Brent: the big button over the middle blocked the view): E on a
	-- keyboard (unless another prompt is showing - its E wins), Y on a
	-- controller; phones get a small button at the right edge
	local UIS = game:GetService("UserInputService")
	local PPS = game:GetService("ProximityPromptService")
	local promptsShown = 0
	PPS.PromptShown:Connect(function()
		promptsShown += 1
	end)
	PPS.PromptHidden:Connect(function()
		promptsShown = math.max(0, promptsShown - 1)
	end)
	UIS.InputBegan:Connect(function(input, used)
		if used or not player:GetAttribute("Riding") or not RideOff then
			return
		end
		if (input.KeyCode == Enum.KeyCode.E and promptsShown == 0) or input.KeyCode == Enum.KeyCode.ButtonY then
			RideOff:FireServer()
		end
	end)
	local phone = UIS.TouchEnabled and not UIS.KeyboardEnabled
	local off = Instance.new("TextButton")
	off.Size = UDim2.fromOffset(104, 36)
	off.AnchorPoint = Vector2.new(1, 0.5)
	off.Position = UDim2.new(1, -12, 0.4, 0)
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
		off.Visible = kind ~= nil and phone
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
