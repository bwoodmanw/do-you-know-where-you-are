--[[
	LobbyScene - the drop-off scene outside the Party House: the shop stall
	with a waving shopkeeper, the leaderboard wall, parked cars and benches
	you can sit in (Seats - sitting only, no driving). If a model with the
	same name is in ServerStorage -> LobbyProps (a Creator Store car, say),
	it is used instead of the built-from-parts one.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Scene = {}

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

-- a seat you can sit on by walking into it or pressing E; jump to get up
local function seat(parent, cf, size, color)
	local s = Instance.new("Seat")
	s.Anchored = true
	s.Size = size or Vector3.new(2, 0.4, 2)
	s.CFrame = cf
	s.Color = color or Color3.fromRGB(40, 30, 30)
	s.Material = Enum.Material.Fabric
	s.TopSurface, s.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	s.Parent = parent
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Sit"
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Parent = s
	prompt.Triggered:Connect(function(plr)
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if hum and not s.Occupant then
			s:Sit(hum)
		end
	end)
	return s
end

-- a model from ServerStorage/LobbyProps if Brent added one, scripts stripped,
-- vehicle seats turned into plain seats (sit, but never drive)
local function fromStorage(name, cf, fitSize)
	local folder = ServerStorage:FindFirstChild("LobbyProps")
	local src = folder and folder:FindFirstChild(name)
	if not src then
		return nil
	end
	local m = src:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		end
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("VehicleSeat") then
			seat(m, d.CFrame, d.Size, d.Color)
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local _, size = m:GetBoundingBox()
	local scale = math.min(fitSize.X / size.X, fitSize.Y / size.Y, fitSize.Z / size.Z)
	if scale > 0 then
		m:ScaleTo(m:GetScale() * scale)
	end
	m:PivotTo(cf)
	local bcf, bsize = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + Vector3.new(0, cf.Position.Y - (bcf.Position.Y - bsize.Y / 2), 0))
	m.Parent = workspace
	return m
end

-- ---------- parked cars (the parents' drop-off) ----------
local function car(position, yaw, color)
	local cf = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	if fromStorage("Car", cf, Vector3.new(8, 6, 15)) then
		return
	end
	local m = Instance.new("Model")
	m.Name = "Car"
	m.Parent = workspace
	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	part(m, { Name = "Body", Size = Vector3.new(7, 2.2, 14), CFrame = at(0, 1.9, 0), Color = color, Material = Enum.Material.SmoothPlastic })
	part(m, { Name = "Bonnet", Size = Vector3.new(6.8, 0.6, 3.6), CFrame = at(0, 3.1, -5), Color = color, Material = Enum.Material.SmoothPlastic })
	part(m, { Name = "Boot", Size = Vector3.new(6.8, 0.6, 2.6), CFrame = at(0, 3.1, 5.6), Color = color, Material = Enum.Material.SmoothPlastic })
	-- open-top cabin so kids can climb in: glass sides, no roof
	part(m, { Name = "Windscreen", Size = Vector3.new(6.4, 2, 0.2), CFrame = at(0, 4.1, -3.1) * CFrame.Angles(math.rad(-20), 0, 0), Color = Color3.fromRGB(150, 190, 220), Material = Enum.Material.Glass, Transparency = 0.5, CanCollide = false })
	for _, x in ipairs({ -3.3, 3.3 }) do
		part(m, { Name = "Door", Size = Vector3.new(0.3, 1.2, 6.4), CFrame = at(x, 3.6, 0.6), Color = color, Material = Enum.Material.SmoothPlastic })
	end
	for _, x in ipairs({ -3.2, 3.2 }) do
		for _, z in ipairs({ -4.3, 4.3 }) do
			part(m, { Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 2.6, 2.6), CFrame = at(x, 1.3, z) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(25, 25, 28), Material = Enum.Material.Rubber })
		end
	end
	for _, x in ipairs({ -2.4, 2.4 }) do
		part(m, { Name = "Headlight", Size = Vector3.new(1.2, 0.6, 0.2), CFrame = at(x, 2.3, -7.05), Color = Color3.fromRGB(255, 245, 210), Material = Enum.Material.Neon })
		part(m, { Name = "Taillight", Size = Vector3.new(1.2, 0.5, 0.2), CFrame = at(x, 2.3, 7.05), Color = Color3.fromRGB(220, 40, 40), Material = Enum.Material.Neon })
	end
	-- seats: front two, back bench
	seat(m, at(-1.5, 3.2, -1.2))
	seat(m, at(1.5, 3.2, -1.2))
	seat(m, at(0, 3.2, 2.6), Vector3.new(5, 0.4, 2))
	part(m, { Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 1.4, 1.4), CFrame = at(-1.5, 4.2, -2.4) * CFrame.Angles(math.rad(70), 0, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(30, 30, 30), CanCollide = false })
end

-- ---------- benches ----------
local function bench(position, yaw)
	local cf = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	if fromStorage("Bench", cf, Vector3.new(7, 4, 3)) then
		return
	end
	local m = Instance.new("Model")
	m.Name = "Bench"
	m.Parent = workspace
	local wood = Color3.fromRGB(120, 78, 44)
	part(m, { Name = "Back", Size = Vector3.new(6, 1.6, 0.3), CFrame = cf * CFrame.new(0, 3, 0.9), Color = wood, Material = Enum.Material.WoodPlanks })
	for _, x in ipairs({ -2.6, 2.6 }) do
		part(m, { Name = "Leg", Size = Vector3.new(0.3, 1.8, 2), CFrame = cf * CFrame.new(x, 0.9, 0.2), Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Metal })
	end
	seat(m, cf * CFrame.new(-1.4, 1.95, 0.2), Vector3.new(2.8, 0.3, 1.8), wood)
	seat(m, cf * CFrame.new(1.4, 1.95, 0.2), Vector3.new(2.8, 0.3, 1.8), wood)
end

-- ---------- the boost shop stall, facing the lane ----------
function Scene.stall(position)
	-- front faces +X (towards the lane)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(-90), 0)
	local m = Instance.new("Model")
	m.Name = "ShopStall"
	m.Parent = workspace
	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	local counter = part(m, { Name = "Counter", Size = Vector3.new(10, 3.6, 2.4), CFrame = at(0, 1.8, -1), Color = Color3.fromRGB(122, 74, 30), Material = Enum.Material.WoodPlanks })
	part(m, { Name = "CounterTop", Size = Vector3.new(10.4, 0.3, 2.8), CFrame = at(0, 3.75, -1), Color = Color3.fromRGB(90, 52, 24), Material = Enum.Material.Wood })
	part(m, { Name = "BackWall", Size = Vector3.new(10, 9, 0.5), CFrame = at(0, 4.5, 3.2), Color = Color3.fromRGB(60, 36, 80), Material = Enum.Material.WoodPlanks })
	for _, x in ipairs({ -4.8, 4.8 }) do
		part(m, { Name = "Post", Size = Vector3.new(0.5, 9, 0.5), CFrame = at(x, 4.5, -2), Color = Color3.fromRGB(90, 60, 30), Material = Enum.Material.Wood })
	end
	-- striped awning, sloping down to the front
	for i = 0, 9 do
		part(m, { Name = "Awning", Size = Vector3.new(1.1, 0.25, 6.4), CFrame = at(-4.95 + i * 1.1, 9.4, 0.4) * CFrame.Angles(math.rad(14), 0, 0), Color = i % 2 == 0 and Color3.fromRGB(255, 138, 31) or Color3.fromRGB(110, 60, 160), Material = Enum.Material.Fabric })
	end
	-- string lights along the front edge
	for i = 0, 8 do
		local bulb = part(m, { Name = "StringLight", Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), CFrame = at(-4.4 + i * 1.1, 8.3 - math.abs(i - 4) * 0.05, -2.6), Color = ({ Color3.fromRGB(255, 77, 94), Color3.fromRGB(255, 210, 63), Color3.fromRGB(123, 227, 107), Color3.fromRGB(61, 139, 255) })[i % 4 + 1], Material = Enum.Material.Neon, CanCollide = false })
		if i % 3 == 0 then
			local l = Instance.new("PointLight")
			l.Range, l.Brightness, l.Color = 10, 0.8, bulb.Color
			l.Parent = bulb
		end
	end
	-- candy jars on the counter
	for i, c in ipairs({ Color3.fromRGB(255, 77, 94), Color3.fromRGB(123, 227, 107), Color3.fromRGB(255, 210, 63) }) do
		local x = -3.5 + (i - 1) * 1.6
		part(m, { Name = "Jar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 1.1, 1.1), CFrame = at(x, 4.6, -1.2) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(200, 230, 255), Material = Enum.Material.Glass, Transparency = 0.6, CanCollide = false })
		for k = 0, 3 do
			part(m, { Name = "Candy", Shape = Enum.PartType.Ball, Size = Vector3.new(0.35, 0.35, 0.35), CFrame = at(x + (k % 2) * 0.3 - 0.15, 4.2 + math.floor(k / 2) * 0.3, -1.2 + (k % 2) * 0.2), Color = c, Material = Enum.Material.SmoothPlastic, CanCollide = false })
		end
	end
	-- the sign on top: a board with words on both faces
	local sign = part(m, { Name = "Sign", Size = Vector3.new(8, 2, 0.4), CFrame = at(0, 11.4, -1.4), Color = Color3.fromRGB(26, 16, 38), Material = Enum.Material.Wood })
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.LightInfluence = 0
		sg.CanvasSize = Vector2.new(400, 100)
		sg.Parent = sign
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(255, 210, 63)
		t.Text = "\u{1F6D2} BOOST SHOP"
		t.Parent = sg
	end
	-- the shopkeeper behind the counter, waving now and then
	task.spawn(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = Color3.fromRGB(240, 200, 160)
		desc.LeftArmColor, desc.RightArmColor = desc.HeadColor, desc.HeadColor
		desc.TorsoColor = Color3.fromRGB(110, 60, 160)
		desc.LeftLegColor, desc.RightLegColor = Color3.fromRGB(40, 30, 50), Color3.fromRGB(40, 30, 50)
		local ok, npc = pcall(function()
			return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
		if not ok or not npc then
			return
		end
		npc.Name = "Shopkeeper"
		local root = npc:FindFirstChild("HumanoidRootPart")
		root.Anchored = true
		npc:PivotTo(at(0, 3, 1.6))
		local hum = npc:FindFirstChildOfClass("Humanoid")
		hum.DisplayName = "Shopkeeper"
		hum.NameDisplayDistance = 40
		npc.Parent = m
		local head = npc:FindFirstChild("Head")
		if head then
			local hat = part(npc, { Name = "PartyHat", Size = Vector3.new(0.9, 1.3, 0.9), CFrame = head.CFrame * CFrame.new(0.2, 1, 0) * CFrame.Angles(0, 0, math.rad(-15)), Color = Color3.fromRGB(123, 227, 107), Material = Enum.Material.SmoothPlastic, CanCollide = false })
			hat.Anchored = false
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = head, hat
			w.Parent = hat
		end
		local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
		local wave = Instance.new("Animation")
		wave.AnimationId = "rbxassetid://507770239"
		local idle = Instance.new("Animation")
		idle.AnimationId = "rbxassetid://507766388"
		local idleTrack = animator:LoadAnimation(idle)
		idleTrack.Looped = true
		idleTrack:Play()
		local waveTrack = animator:LoadAnimation(wave)
		while npc.Parent do
			task.wait(6)
			waveTrack:Play()
		end
	end)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Boosts"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Parent = counter
	return prompt
end

-- ---------- the leaderboard wall ----------
-- returns the three board text labels, in order
function Scene.boards(titles)
	local wallX = 34
	part(workspace, { Name = "BoardWall", Size = Vector3.new(2, 20, 70), Position = Vector3.new(wallX + 1, 10, 0), Color = Color3.fromRGB(90, 60, 56), Material = Enum.Material.Brick })
	part(workspace, { Name = "WallCap", Size = Vector3.new(2.6, 0.6, 71), Position = Vector3.new(wallX + 1, 20.3, 0), Color = Color3.fromRGB(60, 45, 45), Material = Enum.Material.Slate })
	local bodies = {}
	for i, title in ipairs(titles) do
		local z = (i - (#titles + 1) / 2) * 17
		-- the board's front faces the lane (-X)
		local b = part(workspace, { Name = "Leaderboard", Size = Vector3.new(14, 16, 0.6), CFrame = CFrame.lookAt(Vector3.new(wallX - 0.4, 10, z), Vector3.new(wallX - 10, 10, z)), Color = Color3.fromRGB(40, 28, 46), Material = Enum.Material.Wood })
		local lamp = part(workspace, { Name = "BoardLamp", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), Position = Vector3.new(wallX - 2, 19, z), Color = Color3.fromRGB(255, 230, 170), Material = Enum.Material.Neon, CanCollide = false })
		local l = Instance.new("SpotLight")
		l.Face = Enum.NormalId.Bottom
		l.Angle, l.Range, l.Brightness = 70, 14, 2
		l.Color = Color3.fromRGB(255, 230, 170)
		l.Parent = lamp
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.CanvasSize = Vector2.new(420, 480)
		sg.LightInfluence = 0
		sg.Parent = b
		local head = Instance.new("TextLabel")
		head.Size = UDim2.new(1, 0, 0, 64)
		head.BackgroundColor3 = Color3.fromRGB(255, 138, 31)
		head.Font = Enum.Font.FredokaOne
		head.TextScaled = true
		head.TextColor3 = Color3.fromRGB(26, 16, 38)
		head.Text = title
		head.Parent = sg
		local body = Instance.new("TextLabel")
		body.Size = UDim2.new(1, -24, 1, -76)
		body.Position = UDim2.fromOffset(12, 72)
		body.BackgroundTransparency = 1
		body.Font = Enum.Font.FredokaOne
		body.TextSize = 28
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.TextColor3 = Color3.fromRGB(255, 244, 224)
		body.Text = "Loading..."
		body.Parent = sg
		table.insert(bodies, body)
	end
	return bodies
end

-- ---------- the drop-off: cars along the lane, benches by the lamps ----------
function Scene.dropOff()
	local colours = { Color3.fromRGB(180, 40, 50), Color3.fromRGB(40, 90, 170), Color3.fromRGB(230, 230, 225), Color3.fromRGB(60, 120, 70) }
	-- parked along both sides, nose towards the house
	car(Vector3.new(-17, 0, -22), 0, colours[1])
	car(Vector3.new(-17, 0, -42), 0, colours[2])
	car(Vector3.new(17, 0, -30), math.rad(180), colours[3])
	car(Vector3.new(17, 0, -50), math.rad(180), colours[4])
	-- benches facing the lane
	bench(Vector3.new(-20, 0, 22), math.rad(-90))
	bench(Vector3.new(20, 0, 22), math.rad(90))
	bench(Vector3.new(-20, 0, -4), math.rad(-90))
end

return Scene
