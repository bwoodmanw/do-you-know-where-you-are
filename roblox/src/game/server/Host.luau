--[[
	Host - the party host. A tall pumpkin-headed figure built from parts
	(a proper 3D model from art/sheets/host-party.png can replace it later),
	and its brain: patrol, hear noises, see players, chase, catch.
]]

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local Host = {}
Host.__index = Host

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = a, b
	w.Parent = a
end

local function bodyPart(model, root, name, size, offset, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.Massless = true
	p.Anchored = false
	p.CFrame = root.CFrame * offset
	p.Parent = model
	weld(root, p)
	return p
end

-- about twice the height of a kid's avatar
local function buildModel(position)
	local model = Instance.new("Model")
	model.Name = "PartyHost"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.5, 2, 1.5)
	root.Transparency = 1
	root.CanCollide = false
	root.CFrame = CFrame.new(position + Vector3.new(0, 6, 0))
	root.Parent = model
	model.PrimaryPart = root

	local suit = Color3.fromRGB(58, 36, 72)
	local dark = Color3.fromRGB(28, 22, 30)
	bodyPart(model, root, "LegL", Vector3.new(0.8, 5, 0.8), CFrame.new(-0.6, -3.5, 0), dark, Enum.Material.Fabric)
	bodyPart(model, root, "LegR", Vector3.new(0.8, 5, 0.8), CFrame.new(0.6, -3.5, 0), dark, Enum.Material.Fabric)
	bodyPart(model, root, "Torso", Vector3.new(2.6, 3.8, 1.2), CFrame.new(0, 0.4, 0), suit, Enum.Material.Fabric)
	bodyPart(model, root, "CoatTail", Vector3.new(2.4, 2.2, 0.4), CFrame.new(0, -2.2, 0.55), suit, Enum.Material.Fabric)
	bodyPart(model, root, "Shirt", Vector3.new(0.9, 2.2, 0.1), CFrame.new(0, 1.0, -0.62), Color3.fromRGB(226, 213, 190))
	bodyPart(model, root, "BowTie", Vector3.new(1.0, 0.45, 0.2), CFrame.new(0, 2.05, -0.68), Color3.fromRGB(150, 40, 40))
	local armL = bodyPart(model, root, "ArmL", Vector3.new(0.6, 4.6, 0.6), CFrame.new(-1.75, 0.0, -0.3) * CFrame.Angles(math.rad(-20), 0, math.rad(-8)), suit, Enum.Material.Fabric)
	local armR = bodyPart(model, root, "ArmR", Vector3.new(0.6, 4.6, 0.6), CFrame.new(1.75, 0.0, -0.3) * CFrame.Angles(math.rad(-20), 0, math.rad(8)), suit, Enum.Material.Fabric)
	bodyPart(model, root, "GloveL", Vector3.new(0.9, 0.9, 0.9), CFrame.new(-1.95, -2.2, -1.1), Color3.fromRGB(236, 230, 214), nil, Enum.PartType.Ball)
	bodyPart(model, root, "GloveR", Vector3.new(0.9, 0.9, 0.9), CFrame.new(1.95, -2.2, -1.1), Color3.fromRGB(236, 230, 214), nil, Enum.PartType.Ball)
	local head = bodyPart(model, root, "Head", Vector3.new(3.4, 3.4, 3.4), CFrame.new(0, 4.1, 0), Color3.fromRGB(232, 112, 15), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	-- carved face that glows: two eyes and a grin
	local glow = Color3.fromRGB(255, 225, 77)
	local eyeL = bodyPart(model, root, "EyeL", Vector3.new(0.7, 0.6, 0.2), CFrame.new(-0.65, 4.55, -1.62), glow, Enum.Material.Neon)
	local eyeR = bodyPart(model, root, "EyeR", Vector3.new(0.7, 0.6, 0.2), CFrame.new(0.65, 4.55, -1.62), glow, Enum.Material.Neon)
	local mouth = bodyPart(model, root, "Mouth", Vector3.new(1.8, 0.35, 0.2), CFrame.new(0, 3.45, -1.6), glow, Enum.Material.Neon)
	for i = 1, 3 do
		bodyPart(model, root, "Drip", Vector3.new(0.25, 0.8, 0.25), CFrame.new(-0.9 + (i - 1) * 0.9, 2.6, -1.1), Color3.fromRGB(232, 112, 15), Enum.Material.SmoothPlastic)
	end
	bodyPart(model, root, "Stem", Vector3.new(0.35, 0.6, 0.35), CFrame.new(0, 5.9, 0), Color3.fromRGB(74, 122, 42))
	bodyPart(model, root, "PartyHat", Vector3.new(0.9, 1.6, 0.9), CFrame.new(0.9, 6.0, 0) * CFrame.Angles(0, 0, math.rad(-25)), Color3.fromRGB(123, 227, 107), Enum.Material.SmoothPlastic)
	local lamp = Instance.new("PointLight")
	lamp.Color = Color3.fromRGB(255, 150, 40)
	lamp.Range = 14
	lamp.Brightness = 2
	lamp.Parent = head

	local hum = Instance.new("Humanoid")
	hum.HipHeight = 5 -- bottom of the root part (y 5) to the floor
	hum.WalkSpeed = Config.HOST.patrol
	hum.AutoJumpEnabled = false
	hum.UseJumpPower = true
	hum.JumpPower = 0
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.Parent = model
	return model, hum, root, { eyeL, eyeR, mouth }, { armL, armR }
end

function Host.new(world, round)
	local self = setmetatable({}, Host)
	self.world = world
	self.round = round
	self.mode = "wait"
	self.wp = 1
	self.goal = nil
	self.lastSeen = 0
	self.pause = 0
	return self
end

function Host:spawn(diff)
	local H = self.world
	local sx, sy = table.unpack(H.map.spawn)
	local pos = require(script.Parent.House).at(sx, sy, 0)
	local info = Config.HOSTS[self.kind or "pumpkin"] or Config.HOSTS.pumpkin
	local custom = require(script.Parent.Characters).host(info.model)
	if custom then
		custom.Name = "PartyHost"
		self.model, self.hum, self.root, self.face, self.arms = custom, custom:FindFirstChildOfClass("Humanoid"), custom.HumanoidRootPart, {}, {}
		self.hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		self.hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		custom.Parent = workspace
		-- stand it on the floor by its real box (its pivot can be anywhere,
		-- and a host placed too high ends up walking on the roof)
		local cf, size = custom:GetBoundingBox()
		custom:PivotTo(custom:GetPivot() + (pos + Vector3.new(0, size.Y / 2 + 0.05, 0) - cf.Position))
		-- Roblox's own R15 walk and run, played as it moves
		local animator = self.hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", self.hum)
		local function track(id)
			local a = Instance.new("Animation")
			a.AnimationId = id
			return animator:LoadAnimation(a)
		end
		local walk, run = track("rbxassetid://507777826"), track("rbxassetid://507767714")
		self.hum.Running:Connect(function(speed)
			if speed > 11 then
				if walk.IsPlaying then walk:Stop() end
				if not run.IsPlaying then run:Play() end
			elseif speed > 0.5 then
				if run.IsPlaying then run:Stop() end
				if not walk.IsPlaying then walk:Play() end
			else
				walk:Stop()
				run:Stop()
			end
		end)
	else
		self.model, self.hum, self.root, self.face, self.arms = buildModel(pos)
		-- no model imported for this host yet: the built one in its colour
		if self.kind and self.kind ~= "pumpkin" then
			local isFace = {}
			for _, p in ipairs(self.face) do
				isFace[p] = true
			end
			for _, d in ipairs(self.model:GetDescendants()) do
				if d:IsA("BasePart") and not isFace[d] and d ~= self.root then
					d.Color = info.tint
				end
			end
		end
		self.model.Parent = workspace
	end
	self.root:SetNetworkOwner(nil)
	self.diff = diff -- a Config.DIFFICULTY entry
	self.frenzy = false
	self.mode = "patrol"
	self.skill = (Config.HOSTS[self.kind or "pumpkin"] or Config.HOSTS.pumpkin).skill
	self.nextSkill = os.clock() + 4
	self.path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 11, AgentCanJump = false, WaypointSpacing = 6 })
	return self.model
end

function Host:remove()
	if self.model then
		self.model:Destroy()
	end
	self.model = nil
	self.mode = "wait"
end

local function setFace(self, hunting)
	local c = hunting and Color3.fromRGB(255, 59, 48) or Color3.fromRGB(255, 225, 77)
	for _, p in ipairs(self.face) do
		p.Color = c
	end
end

-- a noise somewhere: go and look
function Host:alert(pos)
	if not self.model or self.mode == "hunt" then
		return
	end
	self.mode = "search"
	self.goal = pos
end

-- Echo's noise: it goes to look and ignores everyone it can see for a few
-- seconds (it still grabs anyone it bumps into)
function Host:lure(pos, seconds)
	if not self.model then
		return
	end
	self.mode = "search"
	self.goal = pos
	self.target = nil
	self.lureUntil = os.clock() + seconds
end

function Host:canSee(char)
	local head = self.model and self.model:FindFirstChild("Head")
	local target = char and char:FindFirstChild("HumanoidRootPart")
	if not head or not target then
		return false
	end
	local plr = Players:GetPlayerFromCharacter(char)
	if not plr or plr:GetAttribute("Hidden") or plr:GetAttribute("Crawling") or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
		return false
	end
	if (plr:GetAttribute("SneakUntil") or 0) > workspace:GetServerTimeNow() then
		return false
	end
	local dist = (target.Position - head.Position).Magnitude
	local range = self.diff.sight
	if plr:GetAttribute("Skill") == "shadow" then
		range = Config.HOST.shadowSight
	end
	range *= plr:GetAttribute("SightMult") or 1
	if dist > range then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.model, char }
	local hit = workspace:Raycast(head.Position, target.Position - head.Position, params)
	return hit == nil
end

function Host:moveTo(goal)
	local ok = pcall(function()
		self.path:ComputeAsync(self.root.Position, goal)
	end)
	if ok and self.path.Status == Enum.PathStatus.Success then
		local wps = self.path:GetWaypoints()
		-- step a little way along the path; the brain re-plans often
		local nextWp = wps[3] or wps[2] or wps[1]
		if nextWp then
			self.hum:MoveTo(nextWp.Position)
		end
	else
		self.hum:MoveTo(goal)
	end
end

-- called about five times a second by the round
function Host:step(dt)
	if not self.model or not self.model.Parent then
		return
	end
	-- never stuck on the roof or under the floor: back to its door
	local rootY = self.root.Position.Y
	if rootY > Config.WALL_H or rootY < -10 then
		local sx, sy = table.unpack(self.world.map.spawn)
		local p = require(script.Parent.House).at(sx, sy, 0)
		local cf, size = self.model:GetBoundingBox()
		self.model:PivotTo(self.model:GetPivot() + (p + Vector3.new(0, size.Y / 2 + 0.05, 0) - cf.Position))
		self.mode = "patrol"
	end
	if self.pause > 0 then
		self.pause -= dt
		self.hum:MoveTo(self.root.Position)
		return
	end
	-- who can it see? the nearest wins
	local best, bestD = nil, math.huge
	local lured = os.clock() < (self.lureUntil or 0)
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		if char and not lured and self:canSee(char) then
			local d = (char.HumanoidRootPart.Position - self.root.Position).Magnitude
			if d < bestD then
				best, bestD = plr, d
			end
		end
	end
	local now = os.clock()
	if best then
		if self.mode ~= "hunt" then
			self.round:hostSpotted(best)
		end
		self.mode = "hunt"
		self.target = best
		self.goal = best.Character.HumanoidRootPart.Position
		self.lastSeen = now
		-- throw a pumpkin at someone in sight, not too close, not too far
		local s = Config.HOST_SKILLS.throw
		if self.skill == "throw" and now >= (self.nextSkill or 0) and bestD >= s.min and bestD <= s.range then
			self.nextSkill = now + (s.cooldown[string.lower(self.diff.name)] or 15)
			self:throwAt(best)
		end
	elseif self.mode == "hunt" and now - self.lastSeen > Config.HOST.lostAfter then
		self.mode = "search"
		self.round:hostLost()
	end
	setFace(self, self.mode == "hunt")
	if self.frenzy and not best then
		-- time is up: it always knows where the nearest kid is
		local near, nd = nil, math.huge
		for _, plr in ipairs(Players:GetPlayers()) do
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp and not plr:GetAttribute("Caged") and not plr:GetAttribute("Escaped") then
				local d = (hrp.Position - self.root.Position).Magnitude
				if d < nd then near, nd = hrp, d end
			end
		end
		if near then
			self.mode = "hunt"
			self.goal = near.Position
			self.lastSeen = now
		end
	end
	self.hum.WalkSpeed = self.mode == "hunt" and (self.diff.hunt + (self.frenzy and 2 or 0)) or (self.mode == "search" and Config.HOST.search or Config.HOST.patrol)

	-- catch anyone close enough who is not hidden
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hidden = plr:GetAttribute("Hidden") or plr:GetAttribute("Crawling")
		if hrp and (not hidden or self.frenzy) and not plr:GetAttribute("Caged") and not plr:GetAttribute("Escaped")
			and (plr:GetAttribute("SneakUntil") or 0) <= workspace:GetServerTimeNow() then
			local flat = Vector3.new(hrp.Position.X - self.root.Position.X, 0, hrp.Position.Z - self.root.Position.Z)
			-- in a frenzy it searches hiding places it walks right up to
			-- it reaches up: standing on a table or furniture is no escape
			local reach = (hidden and 3.5 or self.diff.catch) + (hrp.Position.Y > 4.5 and 4 or 0)
			if flat.Magnitude < reach then
				self.pause = 2.5
				self.mode = "patrol"
				self.round:hostCaught(plr)
				return
			end
		end
	end

	-- the Robot: the moment a kid is in the same room as him, lights out
	if self.skill == "blackout" and now >= (self.nextSkill or 0) then
		local function roomOf(pos)
			local x, y = math.floor(pos.X / Config.TILE), math.floor(pos.Z / Config.TILE)
			for _, f in ipairs(self.world.map.floors) do
				if x >= f.x0 and x <= f.x1 and y >= f.y0 and y <= f.y1 then
					return f.name
				end
			end
			return nil
		end
		local mine = roomOf(self.root.Position)
		if mine then
			for _, plr in ipairs(Players:GetPlayers()) do
				local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if h and not plr:GetAttribute("Hidden") and not plr:GetAttribute("Caged") and not plr:GetAttribute("Escaped") and roomOf(h.Position) == mine then
					self.nextSkill = now + (Config.HOST_SKILLS.blackout.cooldown[string.lower(self.diff.name)] or 30)
					self.round:hostBlackout(self.root.Position)
					break
				end
			end
		end
	end

	-- Gummy Bear Man leaves sticky puddles as he goes (the round decides where they may go)
	if self.skill == "gummy" and now >= (self.nextSkill or 0) then
		if self.round:hostGummy(self.root.Position, self.model) then
			self.nextSkill = now + (Config.HOST_SKILLS.gummy.cooldown[string.lower(self.diff.name)] or 10)
		else
			self.nextSkill = now + 1
		end
	end

	-- where to walk
	local goal
	if self.mode == "patrol" then
		-- skip patrol points behind doors that are still locked
		local list = self.world.map.patrol
		for _ = 1, #list do
			local w = list[self.wp]
			if not w.lock or (self.world.unlocked and self.world.unlocked[w.lock]) then
				break
			end
			self.wp = self.wp % #list + 1
		end
		local wp = list[self.wp]
		local p = require(script.Parent.House).at(wp[1], wp[2], 0)
		if (Vector3.new(p.X, 0, p.Z) - Vector3.new(self.root.Position.X, 0, self.root.Position.Z)).Magnitude < 4 then
			self.wp = self.wp % #self.world.map.patrol + 1
		end
		goal = p
	else
		goal = self.goal
		if goal and (Vector3.new(goal.X, 0, goal.Z) - Vector3.new(self.root.Position.X, 0, self.root.Position.Z)).Magnitude < 4 and self.mode == "search" then
			self.mode = "patrol"
			self.pause = 2
			self.round:hostSniff()
			return
		end
	end
	if goal then
		self:moveTo(goal)
	end
end

-- the Pumpkin's throw: a slow arc you can see coming and dodge
function Host:throwAt(plr)
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	local head = self.model and (self.model:FindFirstChild("Head") or self.root)
	if not hrp or not head then
		return
	end
	local Effects = require(script.Parent.Effects)
	local s = Config.HOST_SKILLS.throw
	local from = head.Position + Vector3.new(0, 1, 0)
	local to = Vector3.new(hrp.Position.X, 1, hrp.Position.Z)
	local ball = Instance.new("Part")
	ball.Name = "ThrownPumpkin"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(3.4, 3, 3.4)
	ball.Color = Color3.fromRGB(240, 120, 20)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored, ball.CanCollide, ball.CanQuery, ball.CanTouch = true, false, false, false
	ball.Position = from
	ball.Parent = workspace
	-- easy to see coming: it glows, leaves a trail, and he winds up first
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(255, 140, 40), 14, 3
	glow.Parent = ball
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, 0.8, 0), Vector3.new(0, -0.8, 0)
	a0.Parent, a1.Parent = ball, ball
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 160, 40))
	trail.Lifetime = 0.35
	trail.LightEmission = 0.7
	trail.Parent = ball
	self.pause = math.max(self.pause or 0, 0.4)
	Effects.burst(from, "pick")
	if game:GetService("RunService"):IsStudio() then
		print("[host] throwing a pumpkin at " .. plr.Name)
	end
	Effects.sound(from, "throw")
	local peak = math.max(6, (to - from).Magnitude * 0.25)
	local t0 = os.clock()
	local conn
	conn = game:GetService("RunService").Heartbeat:Connect(function()
		local f = math.min(1, (os.clock() - t0) / s.flight)
		ball.CFrame = CFrame.new(from:Lerp(to, f) + Vector3.new(0, math.sin(f * math.pi) * peak, 0)) * CFrame.Angles(f * 8, 0, 0)
		if f < 1 then
			return
		end
		conn:Disconnect()
		ball:Destroy()
		Effects.burst(to, "shove")
		Effects.sound(to, "bonk", 1)
		for _, p in ipairs(Players:GetPlayers()) do
			local h = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if h and not p:GetAttribute("Hidden") and not p:GetAttribute("Crawling") and not p:GetAttribute("Caged") and not p:GetAttribute("Escaped")
				and (Vector3.new(h.Position.X, 0, h.Position.Z) - Vector3.new(to.X, 0, to.Z)).Magnitude < s.radius then
				self.round:hostHit(p)
			end
		end
	end)
end

function Host:stun(seconds)
	self.pause = seconds
	self.mode = "patrol"
end

return Host
