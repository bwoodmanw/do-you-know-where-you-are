--!nocheck
-- Mirrors.client.luau (5 Nov, Brent): real-looking mirrors in the Funhouse's
-- Hall of Mirrors. Roblox has no mirrors (Reflectance only shows the sky),
-- so each player's own game paints one: on the mirror walls near the camera
-- a picture (a ViewportFrame on the wall) of the room flipped behind the
-- glass, with every kid and the host moving in it.
--
-- How it lines up: the picture's camera sits where the real camera is and
-- looks straight into the wall, so the wall's picture is a plain scaled
-- slice of what that camera sees. The room is copied once per wall (flipped
-- across it); the characters are moved every frame.
--
-- Cost: only the nearest few walls the camera faces draw (2 on phones,
-- 15 times a second there), and nothing runs outside a Hall of Mirrors.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


local phone = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local MAX_ACTIVE = phone and 2 or 3
local STEP = phone and 1 / 15 or 1 / 40
local PPS = phone and 14 or 22 -- picture pixels per stud
local RANGE = 40 -- how far a wall draws from the camera
local ROOM_REACH = 46 -- how far from a wall its copy of the room reaches
local MAX_ROOM_PARTS = 700

-- the flip across a wall (centre c, facing n), kept a proper turn by
-- turning the part over on its own X (blocks, balls and bodies look alike)
local function flipVec(v, n)
	return v - 2 * v:Dot(n) * n
end
local function flipCF(cf, c, n)
	local p = cf.Position
	return CFrame.fromMatrix(p - 2 * (p - c):Dot(n) * n, -flipVec(cf.XVector, n), flipVec(cf.YVector, n), flipVec(cf.ZVector, n))
end

local KEEP = { Decal = true, Texture = true, SurfaceGui = true, SpecialMesh = true, SurfaceAppearance = true, Bone = true, Attachment = true, WrapLayer = true }
local function tidy(clone)
	for _, d in ipairs(clone:GetDescendants()) do
		if d.Parent and not d:IsA("BasePart") and (not d:IsA("GuiBase") or d:IsA("BillboardGui")) and not d:IsA("Model") and not d:IsA("Folder") and not KEEP[d.ClassName] and not d:IsA("DataModelMesh") then
			pcall(function()
				d:Destroy()
			end)
		end
	end
end

local panes = {} -- every mirror wall face of the current floor
local signature = ""

local function clearPanes()
	for _, p in ipairs(panes) do
		if p.part then
			p.part:Destroy()
		end
	end
	panes = {}
end

-- find the mirror walls and join side-by-side faces into one pane each
local function scan()
	-- the floor being played (House.build makes one model, PartyHouse; its
	-- walls are its own children)
	local home = workspace:FindFirstChild("PartyHouse")
	local walls = {}
	for _, d in ipairs(home and home:GetChildren() or {}) do
		if d:IsA("BasePart") and d.Name == "MirrorWall" then
			table.insert(walls, d)
		end
	end
	local sig = #walls > 0 and (tostring(home) .. #walls .. ":" .. tostring(walls[1].Position)) or ""
	if sig == signature then
		return
	end
	signature = sig
	clearPanes()
	if #walls == 0 then
		return
	end
	local house = walls[1]
	while house.Parent and house.Parent ~= workspace do
		house = house.Parent
	end
	local T = walls[1].Size.X
	-- every wall cell (plain or mirror), to tell which faces open into a room
	local solid = {}
	local function key(p)
		return math.floor(p.X / T + 0.5) .. "," .. math.floor(p.Z / T + 0.5)
	end
	for _, d in ipairs(house:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == "Wall" or d.Name == "MirrorWall") and math.abs(d.Size.X - T) < 0.1 then
			solid[key(d.Position)] = true
		end
	end
	-- faces grouped by side and the line they sit on
	local runs = {}
	for _, w in ipairs(walls) do
		for _, n in ipairs({ Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis }) do
			if not solid[key(w.Position + n * T)] then
				local along = n.X ~= 0 and w.Position.Z or w.Position.X
				local line = n.X ~= 0 and w.Position.X or w.Position.Z
				local k = tostring(n) .. "|" .. math.floor(line + 0.5) .. "|" .. math.floor(w.Size.Y + 0.5)
				runs[k] = runs[k] or { n = n, wall = w, cells = {} }
				table.insert(runs[k].cells, along)
			end
		end
	end
	for _, r in pairs(runs) do
		table.sort(r.cells)
		local i = 1
		while i <= #r.cells do
			local j = i
			while j < #r.cells and math.abs(r.cells[j + 1] - r.cells[j] - T) < 0.5 do
				j += 1
			end
			local a, b = r.cells[i], r.cells[j]
			local mid = (a + b) / 2
			local w = r.wall
			local hgt = w.Size.Y
			local base = w.Position + r.n * (T / 2 + 0.06)
			local c = r.n.X ~= 0 and Vector3.new(base.X, w.Position.Y, mid) or Vector3.new(mid, w.Position.Y, base.Z)
			table.insert(panes, { c = c, n = r.n, width = (b - a) + T, height = hgt, house = house })
			i = j + 1
		end
	end
end

local function makeGui(p)
	local part = Instance.new("Part")
	part.Name = "MirrorPane"
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Transparency = 1
	part.Size = Vector3.new(p.width, p.height, 0.05)
	part.CFrame = CFrame.lookAt(p.c, p.c + p.n) -- its Front faces into the room
	part.Parent = workspace.CurrentCamera
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PPS
	gui.LightInfluence = 1 -- 5 Nov (Brent): lit like the room - it glowed white in the dark
	gui.Adornee = part
	gui.Enabled = false
	gui.Parent = part
	local clip = Instance.new("Frame")
	clip.Size = UDim2.fromScale(1, 1)
	clip.BackgroundColor3 = Color3.fromRGB(70, 82, 98) -- dark glass where nothing is reflected
	clip.BorderSizePixel = 0
	clip.ClipsDescendants = true
	clip.Parent = gui
	local vf = Instance.new("ViewportFrame")
	vf.AnchorPoint = Vector2.new(0.5, 0.5)
	vf.BackgroundTransparency = 1
	vf.Ambient = Color3.fromRGB(120, 118, 132) -- (5 Nov: dimmer, like the room)
	vf.LightColor = Color3.fromRGB(175, 170, 165)
	vf.LightDirection = Vector3.new(-0.4, -1, -0.3)
	vf.ImageColor3 = Color3.fromRGB(228, 238, 248) -- a cool glassy tint
	vf.Parent = clip
	local cam = Instance.new("Camera")
	cam.Parent = vf
	vf.CurrentCamera = cam
	local world = Instance.new("WorldModel") -- the moving characters
	world.Parent = vf
	p.part, p.gui, p.clip, p.vf, p.cam, p.world = part, gui, clip, vf, cam, world
	p.chars = {}
	-- the room, flipped behind the glass (copied once)
	local count = 0
	for _, d in ipairs(p.house:GetDescendants()) do
		if count >= MAX_ROOM_PARTS then
			break
		end
		if d:IsA("BasePart") and d.Transparency < 0.95 and d.Name ~= "MirrorPane" then
			local off = d.Position - p.c
			local front = off:Dot(p.n)
			if front > -0.5 and off.Magnitude < ROOM_REACH then
				local ok, copy = pcall(function()
					return d:Clone()
				end)
				if ok and copy then
					copy:ClearAllChildren()
					for _, k in ipairs(d:GetChildren()) do
						if k:IsA("Decal") or k:IsA("SurfaceGui") or k:IsA("DataModelMesh") or k:IsA("SurfaceAppearance") then
							local kc = k:Clone()
							if kc then
								kc.Parent = copy
							end
						end
					end
					copy.Anchored = true
					copy.CFrame = flipCF(d.CFrame, p.c, p.n)
					if d.Name == "MirrorWall" then
						copy.Color = Color3.fromRGB(190, 210, 225) -- other mirrors: silvery glass
					end
					copy.Parent = vf
					count += 1
				end
			end
		end
	end
end

-- the characters a pane shows: every kid and the host near it
local function people()
	local out = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(out, plr.Character)
		end
	end
	for _, nm in ipairs({ "PartyHost", "PartyHost2" }) do
		local h = workspace:FindFirstChild(nm)
		if h and h:IsA("Model") then
			table.insert(out, h)
		end
	end
	return out
end

local function copyChar(src)
	local was = src.Archivable
	src.Archivable = true
	local ok, clone = pcall(function()
		return src:Clone()
	end)
	src.Archivable = was
	if not ok or not clone then
		return nil
	end
	local a, b = src:GetDescendants(), clone:GetDescendants()
	local parts, bones = {}, {}
	if #a == #b then
		for i = 1, #a do
			if a[i]:IsA("BasePart") and b[i]:IsA("BasePart") then
				table.insert(parts, { a[i], b[i] })
			elseif a[i]:IsA("Bone") and b[i]:IsA("Bone") then
				table.insert(bones, { a[i], b[i] })
			end
		end
	end
	tidy(clone)
	for _, pr in ipairs(parts) do
		pr[2].Anchored = true
		pr[2].CanCollide, pr[2].CanTouch, pr[2].CanQuery = false, false, false
	end
	return { clone = clone, parts = parts, bones = bones }
end

local function drawPane(p, eye)
	local n = p.n
	local up = Vector3.yAxis
	local right = (-n):Cross(up) -- the viewer's right on the glass
	local d = (eye - p.c):Dot(n)
	local foot = eye - d * n
	local ox, oy = (foot - p.c):Dot(right), (foot - p.c):Dot(up)
	local hx, hy = math.abs(ox) + p.width / 2 + 0.5, math.abs(oy) + p.height / 2 + 0.5
	d = math.max(d, 0.3)
	local fov = math.deg(2 * math.atan(hy / d))
	if fov > 110 then
		-- too close to see it all: draw what fits, the edges stay silver
		local hy2 = d * math.tan(math.rad(55))
		hx, hy = hx * hy2 / hy, hy2
		fov = 110
	end
	p.cam.FieldOfView = math.max(fov, 1)
	p.cam.CFrame = CFrame.lookAt(eye, eye - n, up)
	p.vf.Size = UDim2.fromOffset(2 * hx * PPS, 2 * hy * PPS)
	p.vf.Position = UDim2.fromOffset((p.width / 2 + ox) * PPS, (p.height / 2 - oy) * PPS)
	-- the characters near this wall
	local seen = {}
	for _, src in ipairs(people()) do
		local root = src:FindFirstChild("HumanoidRootPart") or src.PrimaryPart or src:FindFirstChildWhichIsA("BasePart", true)
		if root then
			local off = root.Position - p.c
			if off:Dot(n) > -1 and off.Magnitude < ROOM_REACH then
				seen[src] = true
				local entry = p.chars[src]
				if not entry then
					entry = copyChar(src)
					if entry then
						entry.clone.Parent = p.world
						p.chars[src] = entry
					end
				end
				if entry then
					for _, pr in ipairs(entry.parts) do
						local s, t = pr[1], pr[2]
						if s.Parent then
							t.CFrame = flipCF(s.CFrame, p.c, n)
							t.Transparency = s.Transparency
						end
					end
					for _, br in ipairs(entry.bones) do
						if br[1].Parent then
							br[2].Transform = br[1].Transform
						end
					end
				end
			end
		end
	end
	for src, entry in pairs(p.chars) do
		if not seen[src] or not src.Parent then
			entry.clone:Destroy()
			p.chars[src] = nil
		end
	end
end

local function sleepPane(p)
	if p.gui then
		p.gui.Enabled = false
		for src, entry in pairs(p.chars) do
			entry.clone:Destroy()
			p.chars[src] = nil
		end
	end
end

local lastScan, lastPick, lastDraw = 0, 0, 0
local active = {}
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	if now - lastScan > 2 then
		lastScan = now
		local ok, err = pcall(scan)
		if not ok then
			warn("Mirrors: " .. tostring(err))
		end
	end
	if #panes == 0 then
		return
	end
	local cam = workspace.CurrentCamera
	local eye = cam.CFrame.Position
	local look = cam.CFrame.LookVector
	if now - lastPick > 0.4 then
		lastPick = now
		-- the nearest walls the camera is in front of and looking toward
		local pick = {}
		for _, p in ipairs(panes) do
			local off = eye - p.c
			local d = off:Dot(p.n)
			local dist = off.Magnitude
			if d > 0.2 and dist < RANGE + p.width / 2 and (look:Dot(-off.Unit) > 0.1 or dist < 10) then
				table.insert(pick, { p = p, dist = dist })
			end
		end
		table.sort(pick, function(a, b)
			return a.dist < b.dist
		end)
		local want = {}
		for i = 1, math.min(#pick, MAX_ACTIVE) do
			want[pick[i].p] = true
		end
		for p in pairs(active) do
			if not want[p] then
				sleepPane(p)
				active[p] = nil
			end
		end
		for p in pairs(want) do
			if not active[p] then
				if not p.part then
					local ok, err = pcall(makeGui, p)
					if not ok then
						warn("Mirrors: " .. tostring(err))
					end
				end
				if p.gui then
					p.gui.Enabled = true
					active[p] = true
				end
			end
		end
		-- panes of a floor that was taken down
		for p in pairs(active) do
			if not table.find(panes, p) then
				active[p] = nil
			end
		end
	end
	if now - lastDraw < STEP then
		return
	end
	lastDraw = now
	for p in pairs(active) do
		local ok, err = pcall(drawPane, p, eye)
		if not ok then
			warn("Mirrors: " .. tostring(err))
			sleepPane(p)
			active[p] = nil
		end
	end
end)
