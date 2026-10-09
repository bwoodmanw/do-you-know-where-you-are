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
		desc.TorsoColor = Color3.fromRGB(46, 120, 80) -- store-green shirt
		desc.Head = 12939347925 -- Know-It-All Grin (Roblox)
		desc.FaceAccessory = "62690529" -- Thick Rimmed Glasses 3.0 (Roblox)
		desc.HatAccessory = "96678344" -- LOL Day Cap (Roblox)
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
		local gap = math.min(17, 68 / #titles)
		local z = (i - (#titles + 1) / 2) * gap
		-- the board's front faces the lane (-X)
		local b = part(workspace, { Name = "Leaderboard", Size = Vector3.new(gap - 1.5, 16, 0.6), CFrame = CFrame.lookAt(Vector3.new(wallX - 0.4, 10, z), Vector3.new(wallX - 10, 10, z)), Color = Color3.fromRGB(40, 28, 46), Material = Enum.Material.Wood })
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
	-- left of the lane: two cars lined up, noses towards the house
	car(Vector3.new(-17, 0, -24), 0, colours[1])
	car(Vector3.new(-17, 0, -44), 0, colours[2])
	-- right of the lane: the drive-in, three cars facing the leaderboards,
	-- the outer two angled in towards the middle board
	car(Vector3.new(19, 0, -26), -math.pi / 2 - math.rad(12), colours[3])
	car(Vector3.new(19, 0, -7), -math.pi / 2, colours[4])
	-- benches facing the lane
	bench(Vector3.new(-20, 0, 22), math.rad(-90))
	bench(Vector3.new(20, 0, 22), math.rad(90))
	bench(Vector3.new(-20, 0, -4), math.rad(-90))
	car(Vector3.new(19, 0, 15), -math.pi / 2 + math.rad(12), Color3.fromRGB(230, 170, 40))
end

-- ---------- round the edge: an iron fence, trees and pumpkins ----------
function Scene.perimeter()
	local folder = Instance.new("Folder")
	folder.Name = "LobbyEdge"
	folder.Parent = workspace
	local iron = Color3.fromRGB(28, 26, 32)
	local E = 96 -- the fence line (the invisible edge walls are at 100)
	local function fence(a, b)
		local len = (b - a).Magnitude
		local mid = (a + b) / 2
		local cf = CFrame.lookAt(mid, b)
		for _, h in ipairs({ 2, 6 }) do
			part(folder, { Name = "FenceRail", Size = Vector3.new(0.3, 0.3, len), CFrame = cf + Vector3.new(0, h, 0), Color = iron, Material = Enum.Material.Metal })
		end
		local n = math.floor(len / 3)
		for i = 0, n do
			local p = a:Lerp(b, i / n)
			part(folder, { Name = "FencePost", Size = Vector3.new(0.3, 7, 0.3), Position = p + Vector3.new(0, 3.5, 0), Color = iron, Material = Enum.Material.Metal })
			if i % 8 == 0 then
				part(folder, { Name = "FenceSpike", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), Position = p + Vector3.new(0, 7.2, 0), Color = Color3.fromRGB(200, 160, 60), Material = Enum.Material.Metal })
			end
		end
	end
	fence(Vector3.new(-E, 0, -86), Vector3.new(-E, 0, E))
	fence(Vector3.new(E, 0, -86), Vector3.new(E, 0, E))
	fence(Vector3.new(-E, 0, E), Vector3.new(E, 0, E))
	-- trees just inside the fence: bare spooky ones and dark leafy ones
	local rng = Random.new(31)
	local function tree(pos, bare)
		local trunkCol = Color3.fromRGB(58, 40, 30)
		local h = bare and rng:NextNumber(12, 16) or rng:NextNumber(10, 14)
		part(folder, { Name = "TreeTrunk", Size = Vector3.new(1.4, h, 1.4), Position = pos + Vector3.new(0, h / 2, 0), Color = trunkCol, Material = Enum.Material.Wood })
		if bare then
			for k = 1, 4 do
				local a = k / 4 * math.pi * 2 + rng:NextNumber(0, 1)
				local base = pos + Vector3.new(0, h * rng:NextNumber(0.55, 0.9), 0)
				local tip = base + Vector3.new(math.cos(a) * 4, rng:NextNumber(2, 4), math.sin(a) * 4)
				part(folder, { Name = "Branch", Size = Vector3.new(0.5, 0.5, (tip - base).Magnitude), CFrame = CFrame.lookAt((base + tip) / 2, tip), Color = trunkCol, Material = Enum.Material.Wood, CanCollide = false })
			end
		else
			for k = 1, 3 do
				part(folder, { Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(8, 8, 8) * rng:NextNumber(0.8, 1.15), Position = pos + Vector3.new(rng:NextNumber(-1.5, 1.5), h + rng:NextNumber(-1, 2), rng:NextNumber(-1.5, 1.5)), Color = Color3.fromRGB(32, 58, 34), Material = Enum.Material.LeafyGrass, CanCollide = false })
			end
		end
	end
	local spots = {}
	for z = -80, 88, 14 do
		table.insert(spots, Vector3.new(-E + 6, 0, z))
		table.insert(spots, Vector3.new(E - 6, 0, z))
	end
	for x = -84, 84, 14 do
		table.insert(spots, Vector3.new(x, 0, E - 6))
	end
	for i, p in ipairs(spots) do
		tree(p + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-3, 3)), i % 3 == 0)
	end
	-- jack-o'-lanterns along the fence, glowing
	for i = 1, #spots, 3 do
		local p = spots[i] + Vector3.new(spots[i].X < 0 and 3 or spots[i].X > 0 and -3 or 0, 0, spots[i].Z > E - 10 and -3 or 7)
		local pumpkin = part(folder, { Name = "JackOLantern", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.2, 2.6), Position = p + Vector3.new(0, 1.1, 0), Color = Color3.fromRGB(240, 120, 20), Material = Enum.Material.SmoothPlastic })
		local glow = Instance.new("PointLight")
		glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(255, 140, 40), 12, 1.2
		glow.Parent = pumpkin
	end
end

-- ---------- Halloween dressing for the Lobby ----------
function Scene.halloween()
	local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
	if not Config.HALLOWEEN then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "LobbyHalloween"
	folder.Parent = workspace
	-- orange and purple lights strung across the lane between the lamp posts
	for z = 30, -50, -20 do
		local a, b = Vector3.new(-11, 9.6, z), Vector3.new(11, 9.6, z)
		for k = 0, 14 do
			local p = a:Lerp(b, k / 14) - Vector3.new(0, math.sin(k / 14 * math.pi) * 1.6, 0)
			part(folder, { Name = "LaneLight", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), Position = p, Color = k % 2 == 0 and Color3.fromRGB(255, 138, 31) or Color3.fromRGB(150, 80, 220), Material = Enum.Material.Neon, CanCollide = false })
		end
	end
	-- hay bales with pumpkins by the gate
	for _, x in ipairs({ -15, 15 }) do
		part(folder, { Name = "HayBale", Size = Vector3.new(5, 2.6, 3), Position = Vector3.new(x, 1.3, -62), Color = Color3.fromRGB(215, 180, 90), Material = Enum.Material.Fabric })
		for i = -1, 1 do
			local pk = part(folder, { Name = "Pumpkin", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.4, 1.6), Position = Vector3.new(x + i * 1.6, 3.3, -62), Color = Color3.fromRGB(240, 120, 20), Material = Enum.Material.SmoothPlastic })
			if i == 0 then
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 140, 40), 10, 1
				l.Parent = pk
			end
		end
	end
	-- friendly tombstones on the lawn edges
	local words = { "BOO!", "R.I.P. Socks", "Here lies Sir Pumpkin", "BOO!", "Gone to the party", "Trick or Treat" }
	for i, p in ipairs({ Vector3.new(-40, 0, 30), Vector3.new(-48, 0, 12), Vector3.new(44, 0, -40), Vector3.new(-44, 0, -60), Vector3.new(62, 0, 40), Vector3.new(-60, 0, 70) }) do
		local stone = part(folder, { Name = "Tombstone", Size = Vector3.new(3, 4, 0.8), CFrame = CFrame.new(p + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad((i * 37) % 30 - 15), math.rad((i * 13) % 10 - 5)), Color = Color3.fromRGB(120, 120, 130), Material = Enum.Material.Slate })
		part(folder, { Name = "TombTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 3, 3), CFrame = stone.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(120, 120, 130), Material = Enum.Material.Slate })
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local sg = Instance.new("SurfaceGui")
			sg.Face = face
			sg.CanvasSize = Vector2.new(150, 200)
			sg.Parent = stone
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 0.6)
			t.Position = UDim2.fromScale(0, 0.15)
			t.BackgroundTransparency = 1
			t.TextScaled = true
			t.Font = Enum.Font.FredokaOne
			t.TextColor3 = Color3.fromRGB(60, 60, 70)
			t.Text = words[i]
			t.Parent = sg
		end
	end
	-- a ghost drifting slowly over the lawn
	local ghost = part(folder, { Name = "LawnGhost", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3.6, 3), Position = Vector3.new(0, 9, 50), Color = Color3.fromRGB(245, 245, 255), Transparency = 0.3, CanCollide = false })
	local gb = Instance.new("BillboardGui")
	gb.Size = UDim2.new(3, 0, 3, 0)
	gb.Parent = ghost
	local gt = Instance.new("TextLabel")
	gt.Size = UDim2.fromScale(1, 1)
	gt.BackgroundTransparency = 1
	gt.TextScaled = true
	gt.Text = "\u{1F47B}"
	gt.Parent = gb
	task.spawn(function()
		local t = 0
		while ghost.Parent do
			t += 0.05
			ghost.Position = Vector3.new(math.sin(t * 0.3) * 30, 9 + math.sin(t * 1.4) * 1.2, 50 + math.cos(t * 0.3) * 20)
			task.wait(0.05)
		end
	end)
	-- a thin purple haze
	local Lighting = game:GetService("Lighting")
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atm = Instance.new("Atmosphere")
		atm.Density = 0.32
		atm.Offset = 0.1
		atm.Color = Color3.fromRGB(110, 80, 150)
		atm.Decay = Color3.fromRGB(60, 40, 90)
		atm.Glare, atm.Haze = 0, 1.2
		atm.Parent = Lighting
	end
end

-- ---------- things to play with while waiting ----------
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Sfx = require(game:GetService("ReplicatedStorage").Shared.Sfx)
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local function sound(at, name, volume)
	local id = Config.SOUNDS[name]
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundGroup = Sfx.group()
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume or 0.8
	s.RollOffMaxDistance = 80
	s.Parent = at
	s:Play()
	Debris:AddItem(s, 4)
end

local function promptOn(p, action, object)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 10
	pp.Parent = p
	return pp
end

function Scene.fun()
	local folder = Instance.new("Folder")
	folder.Name = "LobbyFun"
	folder.Parent = workspace

	-- trampoline (the bounce itself happens on each player's screen: LobbyUi)
	part(folder, { Name = "TrampolineRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 10, 10), CFrame = CFrame.new(-14, 0.5, 40) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal })
	part(folder, { Name = "Trampoline", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 8.6, 8.6), CFrame = CFrame.new(-14, 1.1, 40) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(61, 139, 255), Material = Enum.Material.Fabric })

	-- a ball to kick about; it comes back if it rolls away
	local home = Vector3.new(12, 3, 44)
	local ball = part(folder, { Name = "KickBall", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), Position = home, Color = Color3.fromRGB(255, 77, 94), Material = Enum.Material.SmoothPlastic, Anchored = false })
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.4, 0.8)
	local lastBoing = 0
	ball.Touched:Connect(function(hit)
		if hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid") and os.clock() - lastBoing > 0.4 then
			lastBoing = os.clock()
			sound(ball, "bounce", 0.7)
		end
	end)
	task.spawn(function()
		while ball.Parent do
			task.wait(2)
			local p = ball.Position
			if p.Y < -20 or math.abs(p.X) > 90 or math.abs(p.Z) > 90 then
				ball.AssemblyLinearVelocity = Vector3.zero
				ball.Position = home
			end
		end
	end)

	-- a soccer ball to kick about too
	local soccerHome = Vector3.new(6, 3, 66)
	local soccer = part(folder, { Name = "SoccerBall", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), Position = soccerHome, Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.SmoothPlastic, Anchored = false })
	soccer.CustomPhysicalProperties = PhysicalProperties.new(0.25, 0.4, 0.7)
	for _, dir in ipairs({ Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, -1, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }) do
		local spot = part(folder, { Name = "Patch", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), Position = soccerHome + dir * 1.05, Color = Color3.fromRGB(20, 20, 24), Anchored = false, CanCollide = false, Massless = true })
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = soccer, spot
		w.Parent = spot
	end
	local lastKick = 0
	soccer.Touched:Connect(function(hit)
		if hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid") and os.clock() - lastKick > 0.4 then
			lastKick = os.clock()
			sound(soccer, "bounce", 0.6)
		end
	end)
	task.spawn(function()
		while soccer.Parent do
			task.wait(2)
			local p = soccer.Position
			if p.Y < -20 or math.abs(p.X) > 90 or math.abs(p.Z) > 95 then
				soccer.AssemblyLinearVelocity = Vector3.zero
				soccer.Position = soccerHome
			end
		end
	end)

	-- a swing set with two swings: sit and it swings
	local sx, sz = 40, 50
	local wood = Color3.fromRGB(110, 70, 40)
	for _, z in ipairs({ sz - 6, sz + 6 }) do
		for _, dx in ipairs({ -2.5, 2.5 }) do
			part(folder, { Name = "SwingLeg", Size = Vector3.new(0.6, 11, 0.6), CFrame = CFrame.new(sx + dx / 2, 5.3, z) * CFrame.Angles(0, 0, math.rad(dx > 0 and -12 or 12)), Color = wood, Material = Enum.Material.Wood })
		end
	end
	part(folder, { Name = "SwingBar", Size = Vector3.new(0.6, 0.6, 13), Position = Vector3.new(sx, 10.6, sz), Color = wood, Material = Enum.Material.Wood })
	for _, z in ipairs({ sz - 2.5, sz + 2.5 }) do
		local pivot = CFrame.new(sx, 10.4, z)
		local ropeL = part(folder, { Name = "SwingRope", Size = Vector3.new(0.12, 7.4, 0.12), Color = Color3.fromRGB(200, 190, 170), CanCollide = false })
		local ropeR = part(folder, { Name = "SwingRope", Size = Vector3.new(0.12, 7.4, 0.12), Color = Color3.fromRGB(200, 190, 170), CanCollide = false })
		local swing = Instance.new("Seat")
		swing.Name = "Swing"
		swing.Anchored = true
		swing.Size = Vector3.new(1.8, 0.3, 2.2)
		swing.Color = Color3.fromRGB(200, 60, 60)
		swing.Material = Enum.Material.SmoothPlastic
		swing.TopSurface, swing.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		swing.Parent = folder
		local pp = promptOn(swing, "Sit", "Swing")
		pp.Triggered:Connect(function(plr)
			local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
			if hum and not swing.Occupant then
				swing:Sit(hum)
			end
		end)
		local angle, t = 0, 0
		local function place(a)
			local swingCF = pivot * CFrame.Angles(0, 0, a)
			-- turned a quarter: you face the way the swing goes, not along the bar
			swing.CFrame = swingCF * CFrame.new(0, -7.6, 0) * CFrame.Angles(0, math.rad(90), 0)
			ropeL.CFrame = swingCF * CFrame.new(0, -3.7, -0.9)
			ropeR.CFrame = swingCF * CFrame.new(0, -3.7, 0.9)
		end
		place(0)
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			if swing.Occupant then
				t += dt
				angle = math.sin(t * 2.2) * 0.5
			elseif math.abs(angle) > 0.001 then
				angle *= 0.96
				t = 0
			else
				return
			end
			place(angle)
		end)
	end

	-- lamps over the play lawn (the lane's lamps stop at the spawn)
	local function lamp(x, z, range)
		part(folder, { Name = "LampPost", Size = Vector3.new(0.6, 10, 0.6), Position = Vector3.new(x, 5, z), Material = Enum.Material.Metal, Color = Color3.fromRGB(30, 30, 34) })
		local bulb = part(folder, { Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), Position = Vector3.new(x, 10.4, z), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 220, 150), CanCollide = false })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 210, 150), range or 24, 1.4
		l.Parent = bulb
	end
	for _, z in ipairs({ 48, 68, 88 }) do
		lamp(-11, z)
		lamp(11, z)
	end
	lamp(34, 50, 26) -- by the swings
	lamp(-36, 56) -- by the left party circles

	-- a giant pumpkin that giggles and glows when you poke it
	local pumpkin = part(folder, { Name = "GiantPumpkin", Shape = Enum.PartType.Ball, Size = Vector3.new(6, 5, 6), Position = Vector3.new(16, 2.5, 54), Color = Color3.fromRGB(240, 120, 20), Material = Enum.Material.SmoothPlastic })
	part(folder, { Name = "Stem", Size = Vector3.new(0.6, 1.2, 0.6), Position = Vector3.new(16, 5.4, 54), Color = Color3.fromRGB(70, 110, 40) })
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(255, 140, 40), 14, 0
	glow.Parent = pumpkin
	local poke = promptOn(pumpkin, "Poke", "Giant pumpkin")
	local busy = false
	poke.Triggered:Connect(function()
		if busy then
			return
		end
		busy = true
		sound(pumpkin, "giggle", 1)
		TweenService:Create(glow, TweenInfo.new(0.3), { Brightness = 4 }):Play()
		TweenService:Create(pumpkin, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true), { Size = Vector3.new(6.8, 5.8, 6.8) }):Play()
		task.wait(1.6)
		TweenService:Create(glow, TweenInfo.new(0.8), { Brightness = 0 }):Play()
		task.wait(1)
		busy = false
	end)

	-- a bell on a post: ring it
	part(folder, { Name = "BellPost", Size = Vector3.new(0.6, 9, 0.6), Position = Vector3.new(-12, 4.5, 54), Color = Color3.fromRGB(70, 50, 40), Material = Enum.Material.Wood })
	part(folder, { Name = "BellArm", Size = Vector3.new(2.6, 0.4, 0.4), Position = Vector3.new(-11, 8.8, 54), Color = Color3.fromRGB(70, 50, 40), Material = Enum.Material.Wood })
	local bell = part(folder, { Name = "Bell", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), Position = Vector3.new(-10, 7.6, 54), Color = Color3.fromRGB(230, 190, 70), Material = Enum.Material.Metal })
	local ring = promptOn(bell, "Ring", "Bell")
	local hang = CFrame.new(-10, 8.6, 54)
	local rest = bell.CFrame
	ring.Triggered:Connect(function()
		sound(bell, "bell", 0.9)
		for _, a in ipairs({ 30, -25, 15, 0 }) do
			local tw = TweenService:Create(bell, TweenInfo.new(0.18), { CFrame = hang * CFrame.Angles(0, 0, math.rad(a)) * hang:Inverse() * rest })
			tw:Play()
			tw.Completed:Wait()
		end
	end)
end

return Scene
