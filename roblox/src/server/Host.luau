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

function Host:spawn(spook)
	local H = self.world
	local sx, sy = table.unpack(H.map.spawn)
	local pos = require(script.Parent.House).at(sx, sy, 0)
	self.model, self.hum, self.root, self.face, self.arms = buildModel(pos)
	self.model.Parent = workspace
	self.root:SetNetworkOwner(nil)
	self.spook = spook
	self.mode = "patrol"
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

function Host:canSee(char)
	local head = self.model and self.model:FindFirstChild("Head")
	local target = char and char:FindFirstChild("HumanoidRootPart")
	if not head or not target then
		return false
	end
	local plr = Players:GetPlayerFromCharacter(char)
	if not plr or plr:GetAttribute("Hidden") or plr:GetAttribute("Caged") or plr:GetAttribute("Escaped") then
		return false
	end
	if (plr:GetAttribute("SneakUntil") or 0) > os.clock() then
		return false
	end
	local dist = (target.Position - head.Position).Magnitude
	local range = Config.HOST.sight[self.spook] or 32
	if plr:GetAttribute("Skill") == "shadow" then
		range = Config.HOST.shadowSight
	end
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
	if self.pause > 0 then
		self.pause -= dt
		self.hum:MoveTo(self.root.Position)
		return
	end
	-- who can it see? the nearest wins
	local best, bestD = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		if char and self:canSee(char) then
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
	elseif self.mode == "hunt" and now - self.lastSeen > Config.HOST.lostAfter then
		self.mode = "search"
		self.round:hostLost()
	end
	setFace(self, self.mode == "hunt")
	self.hum.WalkSpeed = self.mode == "hunt" and Config.HOST.hunt[self.spook] or (self.mode == "search" and Config.HOST.search or Config.HOST.patrol)

	-- catch anyone close enough who is not hidden
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and not plr:GetAttribute("Hidden") and not plr:GetAttribute("Caged") and not plr:GetAttribute("Escaped")
			and (plr:GetAttribute("SneakUntil") or 0) <= now then
			local flat = Vector3.new(hrp.Position.X - self.root.Position.X, 0, hrp.Position.Z - self.root.Position.Z)
			if flat.Magnitude < Config.HOST.catch then
				self.pause = 2.5
				self.mode = "patrol"
				self.round:hostCaught(plr)
				return
			end
		end
	end

	-- where to walk
	local goal
	if self.mode == "patrol" then
		local wp = self.world.map.patrol[self.wp]
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

function Host:stun(seconds)
	self.pause = seconds
	self.mode = "patrol"
end

return Host
