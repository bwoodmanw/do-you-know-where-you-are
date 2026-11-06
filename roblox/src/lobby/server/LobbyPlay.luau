--[[
	LobbyPlay (5 Nov, Brent) - the Lobby's bounce course and seasonal rides.

	Bounce course: six bounce pads on posts climbing to the Sky Perch, a
	platform high over the lawn with a star on it - touch the star once a day
	for points. The pads (and posts) dress for the season: gumdrops on
	candy-cane posts at Christmas, pumpkins at Halloween, hay at Thanksgiving.
	The bounce itself happens on each player's screen (LobbyPlay.client).

	Rides: a stand with the season's ride - a turkey at Thanksgiving, Santa's
	sleigh at Christmas, a broomstick at Halloween. E rides it: the ride is
	welded under you, you sit, run faster and jump higher (the sleigh and the
	broom float down slowly). Get off with the button, by jumping off at the
	stand, or by leaving the Lobby. One ride each.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Seasons = require(ReplicatedStorage.Shared.Seasons)
local Shapes = require(ReplicatedStorage.Shared.Shapes)
local Profile = require(ReplicatedStorage.Shared.Profile)
local ModelBounds = require(ReplicatedStorage.Shared.ModelBounds)

local Play = {}

-- where it all stands: the west lawn, clear of the other toys
Play.PADS = {
	-- x, z, the pad's top height, and how hard it throws you up (studs a second)
	{ -60, 30, 1, 82 },
	{ -70, 22, 9, 82 },
	{ -79, 12, 17, 82 },
	{ -73, 1, 25, 82 },
	{ -63, -6, 33, 82 },
	{ -72, -14, 41, 70 },
}
Play.PERCH = Vector3.new(-82, 49, -20) -- the Sky Perch's floor (top middle)
Play.STAND = Vector3.new(-58, 0, 52) -- the ride stand (clear of the Christmas snow pile at -55, 45)
Play.PERCH_POINTS = 10
Play.RIDE_SPEED = 1.6 -- (the client multiplies its walk and run by this)

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	Shapes.fix(p, props.Shape, props.Size)
	p.Parent = parent
	return p
end

local CYL = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder standing up

-- the season's look for the course
local LOOKS = {
	christmas = { pads = { Color3.fromRGB(230, 40, 60), Color3.fromRGB(60, 190, 90), Color3.fromRGB(250, 210, 60), Color3.fromRGB(150, 80, 220) },
		post = Color3.fromRGB(245, 245, 245), stripe = Color3.fromRGB(220, 30, 45), padMat = Enum.Material.SmoothPlastic, postMat = Enum.Material.SmoothPlastic, dome = true },
	thanksgiving = { pads = { Color3.fromRGB(225, 130, 40), Color3.fromRGB(190, 80, 40), Color3.fromRGB(230, 180, 60) },
		post = Color3.fromRGB(215, 180, 90), postMat = Enum.Material.Fabric, padMat = Enum.Material.Fabric },
	halloween = { pads = { Color3.fromRGB(240, 120, 20), Color3.fromRGB(120, 60, 170) },
		post = Color3.fromRGB(40, 34, 46), postMat = Enum.Material.Wood, padMat = Enum.Material.SmoothPlastic },
	none = { pads = { Color3.fromRGB(61, 139, 255), Color3.fromRGB(255, 77, 94), Color3.fromRGB(70, 209, 96) },
		post = Color3.fromRGB(70, 70, 82), postMat = Enum.Material.Metal, padMat = Enum.Material.Fabric },
}

-- ---------- the bounce course ----------
local function buildCourse(folder, season)
	local look = LOOKS[season or "none"] or LOOKS.none
	for i, d in ipairs(Play.PADS) do
		local x, z, top, power = d[1], d[2], d[3], d[4]
		local col = look.pads[(i - 1) % #look.pads + 1]
		if top > 1.2 then
			-- the post up to the pad
			local h = top - 0.6
			part(folder, { Name = "PadPost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 2.4, 2.4), CFrame = CFrame.new(x, h / 2, z) * CYL, Color = look.post, Material = look.postMat })
			if look.stripe then
				-- candy-cane stripes up the post
				for y = 2, h - 1, 3 do
					part(folder, { Name = "PadStripe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.9, 2.5, 2.5), CFrame = CFrame.new(x, y, z) * CYL, Color = look.stripe, Material = look.postMat, CanCollide = false })
				end
			end
			-- a rim to stand on round the pad
			part(folder, { Name = "PadRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 9, 9), CFrame = CFrame.new(x, top - 0.6, z) * CYL, Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal })
		else
			part(folder, { Name = "PadRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 9, 9), CFrame = CFrame.new(x, 0.5, z) * CYL, Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal })
		end
		local pad = part(folder, { Name = "BouncePad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 7.6, 7.6), CFrame = CFrame.new(x, top, z) * CYL, Color = col, Material = look.padMat })
		pad:SetAttribute("Bounce", power)
		if look.dome then
			-- gumdrops: a sugary dome on the rim's edge (not on the pad - you land on that)
			for k = 0, 3 do
				local a = k * math.pi / 2 + i
				part(folder, { Name = "Gumdrop", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.2, 1.4), Position = Vector3.new(x + math.cos(a) * 4.2, top + 0.2, z + math.sin(a) * 4.2), Color = look.pads[(i + k) % #look.pads + 1], Material = Enum.Material.SmoothPlastic, CanCollide = false })
			end
		elseif season == "halloween" then
			part(folder, { Name = "PadPumpkin", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.5, 1.8), Position = Vector3.new(x + 4.3, top + 0.3, z), Color = Color3.fromRGB(240, 120, 20), Material = Enum.Material.SmoothPlastic, CanCollide = false })
		elseif season == "thanksgiving" then
			part(folder, { Name = "PadCorn", Size = Vector3.new(0.6, 1.6, 0.6), Position = Vector3.new(x + 4.3, top + 0.6, z), Color = Color3.fromRGB(240, 200, 60), Material = Enum.Material.SmoothPlastic, CanCollide = false })
		end
		-- the first pad's sign
		if i == 1 then
			local sign = part(folder, { Name = "CourseSign", Size = Vector3.new(7, 2.2, 0.4), CFrame = CFrame.lookAt(Vector3.new(x + 6, 3.2, z + 5), Vector3.new(x + 6, 3.2, z + 15)), Color = Color3.fromRGB(40, 22, 62), Material = Enum.Material.SmoothPlastic })
			part(folder, { Name = "SignPost", Size = Vector3.new(0.4, 2.2, 0.4), Position = Vector3.new(x + 6, 1.1, z + 5), Color = Color3.fromRGB(70, 50, 40), Material = Enum.Material.Wood })
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Back
			gui.CanvasSize = Vector2.new(420, 132)
			gui.Parent = sign
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.TextScaled = true
			t.Font = Enum.Font.FredokaOne
			t.TextColor3 = Color3.fromRGB(255, 180, 70)
			t.Text = "\u{2B50} Bounce up to the Sky Perch!"
			t.Parent = gui
		end
	end
	-- the Sky Perch: a railed platform with a star
	local P = Play.PERCH
	part(folder, { Name = "PerchFloor", Size = Vector3.new(12, 1, 12), Position = P - Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(90, 60, 110), Material = Enum.Material.WoodPlanks })
	part(folder, { Name = "PerchPost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(P.Y - 1, 2.6, 2.6), CFrame = CFrame.new(P.X, (P.Y - 1) / 2, P.Z) * CYL, Color = look.post, Material = look.postMat })
	for _, s in ipairs({ { 0, 6, 12, 0.4 }, { 0, -6, 12, 0.4 }, { 6, 0, 0.4, 12 } }) do
		part(folder, { Name = "PerchRail", Size = Vector3.new(s[3], 2.4, s[4]), Position = P + Vector3.new(s[1], 1.2, s[2]), Color = Color3.fromRGB(60, 40, 70), Material = Enum.Material.Wood, Transparency = 0.2 })
	end
	local star = part(folder, { Name = "PerchStar", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Position = P + Vector3.new(0, 2.2, 0), Color = Color3.fromRGB(255, 220, 80), Material = Enum.Material.Neon, CanCollide = false })
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 220, 120), 18, 1.5
	l.Parent = star
	return star
end

-- ---------- the rides ----------
-- each built from parts, its seat's top at height `seat` (of a 1-stud-tall
-- ride; scaled to the rider) and its front toward -Z
local function rideModel(kind)
	local m = Instance.new("Model")
	local function bit(props)
		props.CanCollide, props.CanQuery, props.CanTouch, props.CastShadow = false, false, false, false
		props.Anchored = false
		props.Massless = true
		return part(m, props)
	end
	local RED, GOLD, BROWN = Color3.fromRGB(196, 36, 44), Color3.fromRGB(235, 190, 70), Color3.fromRGB(120, 70, 35)
	local body, seat
	if kind == "sleigh" then
		-- Santa's sleigh: about 3 tall, 6 long; you sit in the middle
		body = bit({ Name = "RideBody", Size = Vector3.new(3.4, 1.6, 5), CFrame = CFrame.new(0, 1.9, 0), Color = RED, Material = Enum.Material.SmoothPlastic })
		bit({ Name = "SleighBack", Size = Vector3.new(3.4, 1.8, 0.6), CFrame = CFrame.new(0, 3.3, 2.2), Color = RED, Material = Enum.Material.SmoothPlastic })
		bit({ Name = "SleighFront", Size = Vector3.new(3.4, 1, 0.5), CFrame = CFrame.new(0, 3, -2.3) * CFrame.Angles(math.rad(-25), 0, 0), Color = RED, Material = Enum.Material.SmoothPlastic })
		bit({ Name = "SleighTrim", Size = Vector3.new(3.5, 0.25, 5.1), CFrame = CFrame.new(0, 2.75, 0), Color = GOLD, Material = Enum.Material.SmoothPlastic })
		for _, sx in ipairs({ -1.4, 1.4 }) do
			bit({ Name = "Runner", Size = Vector3.new(0.25, 0.25, 6.2), CFrame = CFrame.new(sx, 0.15, -0.3), Color = GOLD, Material = Enum.Material.Metal })
			bit({ Name = "RunnerCurl", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 1.1, 0.5), CFrame = CFrame.new(sx, 0.6, -3.4), Color = GOLD, Material = Enum.Material.Metal })
			bit({ Name = "RunnerLeg", Size = Vector3.new(0.25, 1.1, 0.25), CFrame = CFrame.new(sx, 0.7, 1.4), Color = GOLD, Material = Enum.Material.Metal })
			bit({ Name = "RunnerLeg", Size = Vector3.new(0.25, 1.1, 0.25), CFrame = CFrame.new(sx, 0.7, -1.4), Color = GOLD, Material = Enum.Material.Metal })
		end
		bit({ Name = "PresentSack", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2.2, 1.6), CFrame = CFrame.new(0, 3.4, 1.6), Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.Fabric })
		local bell = bit({ Name = "SleighBell", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), CFrame = CFrame.new(1.8, 2.6, -2), Color = GOLD, Material = Enum.Material.Metal })
		bell.Name = "SleighBell"
		seat = 2.7
	elseif kind == "turkey" then
		-- a big friendly turkey: you sit on its back
		body = bit({ Name = "RideBody", Shape = Enum.PartType.Ball, Size = Vector3.new(3.2, 2.8, 4), CFrame = CFrame.new(0, 2.2, 0), Color = BROWN, Material = Enum.Material.SmoothPlastic })
		bit({ Name = "TurkeyNeck", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 2.2, 1), CFrame = CFrame.new(0, 3.4, -1.9), Color = BROWN, Material = Enum.Material.SmoothPlastic })
		bit({ Name = "TurkeyHead", Shape = Enum.PartType.Ball, Size = Vector3.new(1.1, 1.1, 1.2), CFrame = CFrame.new(0, 4.5, -2.2), Color = Color3.fromRGB(150, 100, 70), Material = Enum.Material.SmoothPlastic })
		bit({ Name = "TurkeyBeak", Size = Vector3.new(0.3, 0.3, 0.6), CFrame = CFrame.new(0, 4.45, -2.85), Color = Color3.fromRGB(240, 180, 40), Material = Enum.Material.SmoothPlastic })
		bit({ Name = "TurkeyWattle", Shape = Enum.PartType.Ball, Size = Vector3.new(0.35, 0.8, 0.35), CFrame = CFrame.new(0, 4, -2.7), Color = Color3.fromRGB(200, 30, 40), Material = Enum.Material.SmoothPlastic })
		for _, ex in ipairs({ -0.3, 0.3 }) do
			bit({ Name = "TurkeyEye", Shape = Enum.PartType.Ball, Size = Vector3.new(0.22, 0.22, 0.22), CFrame = CFrame.new(ex, 4.7, -2.75), Color = Color3.fromRGB(20, 20, 24), Material = Enum.Material.SmoothPlastic })
		end
		-- the tail fan
		local FAN = { Color3.fromRGB(150, 70, 30), Color3.fromRGB(220, 140, 40), Color3.fromRGB(190, 50, 40), Color3.fromRGB(230, 190, 70) }
		for k = -3, 3 do
			bit({ Name = "TailFeather", Size = Vector3.new(0.9, 3.2, 0.2), CFrame = CFrame.new(0, 3.2, 2.1) * CFrame.Angles(0, 0, math.rad(k * 22)) * CFrame.new(0, 1.2, 0), Color = FAN[(k + 3) % #FAN + 1], Material = Enum.Material.SmoothPlastic })
		end
		for _, lx in ipairs({ -0.8, 0.8 }) do
			bit({ Name = "TurkeyLeg", Size = Vector3.new(0.3, 1.2, 0.3), CFrame = CFrame.new(lx, 0.6, 0), Color = Color3.fromRGB(240, 180, 40), Material = Enum.Material.SmoothPlastic })
		end
		seat = 3.4
	else
		-- a broomstick: you sit astride the handle
		body = bit({ Name = "RideBody", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 0.35, 0.35), CFrame = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(110, 70, 40), Material = Enum.Material.Wood })
		bit({ Name = "Bristles", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 2.4), CFrame = CFrame.new(0, 1.5, 3.4), Color = Color3.fromRGB(200, 160, 80), Material = Enum.Material.Fabric })
		bit({ Name = "BroomBand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 0.5, 0.5), CFrame = CFrame.new(0, 1.55, 2.4) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(120, 60, 170), Material = Enum.Material.SmoothPlastic })
		seat = 1.8
	end
	m.PrimaryPart = body
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d ~= body then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = body, d
			w.Parent = d
		end
	end
	return m, seat
end

local RIDES = {
	thanksgiving = { kind = "turkey", name = "the Turkey", verb = "Ride the turkey" },
	christmas = { kind = "sleigh", name = "Santa's Sleigh", verb = "Ride the sleigh" },
	halloween = { kind = "broom", name = "the Broomstick", verb = "Ride the broom" },
}

function Play.start(remote, notice)
	local folder = Instance.new("Folder")
	folder.Name = "LobbyPlay"
	folder.Parent = workspace
	local course = Instance.new("Folder")
	course.Name = "BounceCourse"
	course.Parent = folder
	local RideOff = remote("RideOff") -- client -> server: get off

	-- ---------- the course, dressed for the season (checked every minute) ----------
	local shownSeason = false
	local star
	local function dress()
		local s = Seasons.decor()
		if s == shownSeason then
			return
		end
		shownSeason = s
		course:ClearAllChildren()
		star = buildCourse(course, s)
		local touchedAt = {}
		star.Touched:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if not plr or os.clock() - (touchedAt[plr] or 0) < 3 then
				return
			end
			touchedAt[plr] = os.clock()
			local data = Profile.get(plr)
			if not data then
				return
			end
			local today = math.floor(os.time() / 86400)
			if data.perchDay == today then
				notice(plr, "\u{2B50} You reached the Sky Perch! Come back tomorrow for more points.")
				return
			end
			data.perchDay = today
			data.points += Play.PERCH_POINTS
			data.stats.earned = (data.stats.earned or 0) + Play.PERCH_POINTS
			Profile.publish(plr)
			notice(plr, "\u{2B50} You reached the Sky Perch! +" .. Play.PERCH_POINTS .. " points (once a day)")
		end)
	end

	-- ---------- the ride stand ----------
	local stand = Instance.new("Model")
	stand.Name = "RideStand"
	stand.Parent = folder
	local A = Play.STAND
	part(stand, { Name = "StandBase", Size = Vector3.new(9, 0.6, 9), Position = A + Vector3.new(0, 0.3, 0), Color = Color3.fromRGB(90, 60, 110), Material = Enum.Material.WoodPlanks })
	local signPart = part(stand, { Name = "StandSign", Size = Vector3.new(6, 1.8, 0.4), Position = A + Vector3.new(0, 6.2, 4.6), Color = Color3.fromRGB(40, 22, 62), Material = Enum.Material.SmoothPlastic })
	for _, sx in ipairs({ -2.6, 2.6 }) do
		part(stand, { Name = "StandPost", Size = Vector3.new(0.5, 6, 0.5), Position = A + Vector3.new(sx, 3.3, 4.6), Color = Color3.fromRGB(70, 50, 40), Material = Enum.Material.Wood })
	end
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.CanvasSize = Vector2.new(360, 108)
	signGui.Parent = signPart
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.TextScaled = true
	signText.Font = Enum.Font.FredokaOne
	signText.TextColor3 = Color3.fromRGB(255, 180, 70)
	signText.Parent = signGui
	local shown -- the ride on show at the stand
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ride"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	local anchor = part(stand, { Name = "RideSpot", Size = Vector3.new(1, 1, 1), Position = A + Vector3.new(0, 2, 0), Transparency = 1, CanCollide = false, CanQuery = false })
	prompt.Parent = anchor
	local function showRide()
		local s = Seasons.decor()
		local r = s and RIDES[s]
		if shown then
			shown:Destroy()
			shown = nil
		end
		stand.Parent = r and folder or nil
		if not r then
			return
		end
		signText.Text = "\u{1F6F7} " .. r.name .. " - press to ride!"
		if r.kind == "turkey" then
			signText.Text = "\u{1F983} " .. r.name .. " - hop on!"
		elseif r.kind == "broom" then
			signText.Text = "\u{1F9F9} " .. r.name .. " - hop on!"
		end
		prompt.ObjectText = r.name
		prompt.ActionText = r.verb
		local m = rideModel(r.kind)
		m.Name = "RideOnShow"
		m:ScaleTo(1.25)
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		m:PivotTo(CFrame.new(A + Vector3.new(0, 0.6 + (m:GetPivot().Position.Y - (select(1, m:GetBoundingBox()).Position.Y - select(2, m:GetBoundingBox()).Y / 2)), 0)) * CFrame.Angles(0, math.rad(180), 0))
		m.Parent = stand
		shown = m
	end

	-- ---------- riding ----------
	local riding = {} -- [player] = { model, hum, hip }
	local function getOff(plr)
		local r = riding[plr]
		if not r then
			return
		end
		riding[plr] = nil
		if r.model then
			r.model:Destroy()
		end
		if r.hum and r.hum.Parent then
			r.hum.HipHeight = r.hip
			r.hum.JumpPower = r.jump
		end
		plr:SetAttribute("Riding", nil)
	end
	local function getOn(plr)
		local s = Seasons.decor()
		local r = s and RIDES[s]
		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not r or not hum or not hrp or hum.Health <= 0 then
			return
		end
		if riding[plr] then
			return getOff(plr)
		end
		local m, seat = rideModel(r.kind)
		-- the ride sized to the rider: a sleigh about as long as they are tall
		local _, csize = ModelBounds(char)
		local tall = math.max(3, csize.Y)
		local scale = tall / (r.kind == "turkey" and 5 or r.kind == "sleigh" and 4.4 or 4)
		m:ScaleTo(scale)
		seat *= scale
		m.Name = "Ride"
		-- the rider sits on the seat: the hips go up by the seat's height
		-- (sitting lowers them by about a leg's length, which the hip height
		-- keeps for the legs - so the seat height is the lift)
		local hip = hum.HipHeight
		local lift = seat * 0.75
		hum.HipHeight = hip + lift
		-- the ride under the rider: its bottom on the floor, facing their way
		local floorY = hrp.Position.Y - hrp.Size.Y / 2 - hip
		local bcf, bsize = m:GetBoundingBox()
		local pivotUp = m:GetPivot().Position.Y - (bcf.Position.Y - bsize.Y / 2)
		local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
		look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
		local base = CFrame.lookAt(Vector3.new(hrp.Position.X, floorY + pivotUp + lift, hrp.Position.Z), Vector3.new(hrp.Position.X, floorY + pivotUp + lift, hrp.Position.Z) + look)
		m:PivotTo(base)
		-- welded to the rider's root where they will sit (they rise by `lift`)
		local weld = Instance.new("Weld")
		weld.Part0 = hrp
		weld.Part1 = m.PrimaryPart
		weld.C0 = (hrp.CFrame + Vector3.new(0, lift, 0)):ToObjectSpace(m.PrimaryPart.CFrame)
		weld.Parent = m.PrimaryPart
		m.Parent = char
		riding[plr] = { model = m, hum = hum, hip = hip, jump = hum.JumpPower }
		hum.UseJumpPower = true
		hum.JumpPower = math.max(hum.JumpPower, 50) * 1.35
		plr:SetAttribute("Riding", r.kind)
		notice(plr, "\u{2B50} You're riding " .. r.name .. "! Run, jump - and try the bounce pads. Tap Get off to hop down.")
	end
	prompt.Triggered:Connect(getOn)
	RideOff.OnServerEvent:Connect(getOff)
	Players.PlayerRemoving:Connect(function(plr)
		riding[plr] = nil
	end)
	Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function()
			riding[plr] = nil
			plr:SetAttribute("Riding", nil)
		end)
	end)
	for _, plr in ipairs(Players:GetPlayers()) do
		plr.CharacterAdded:Connect(function()
			riding[plr] = nil
			plr:SetAttribute("Riding", nil)
		end)
	end

	-- the season: built now, looked at again every minute
	task.spawn(function()
		while true do
			dress()
			local want = Seasons.decor() or false
			if want ~= (Play.shownRide or false) then
				Play.shownRide = want
				showRide()
				-- out of season: everyone gets off
				for plr in pairs(riding) do
					getOff(plr)
				end
			end
			task.wait(60)
		end
	end)
	Play.getOff = getOff
end

return Play
