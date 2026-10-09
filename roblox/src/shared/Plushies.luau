--[[
	Plushies - the collectibles book's lost plushies (Config.PLUSHIES): one
	small soft toy sits somewhere on every floor, built from fabric parts.
	Each animal has its own ears, face and extras. The model faces -Z; the
	caller turns it.
]]

local Plushies = {}

local FABRIC = Enum.Material.Fabric
local BLACK = Color3.fromRGB(30, 22, 28)
local WHITE = Color3.fromRGB(250, 248, 242)
local ORANGE = Color3.fromRGB(255, 150, 40)

local function add(m, base, size, at, color, shape, rot, mat)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Shape = shape or Enum.PartType.Ball
	p.Size = size
	p.Color = color
	p.Material = mat or FABRIC
	p.CFrame = base * CFrame.new(at) * (rot or CFrame.new())
	p.Parent = m
	return p
end

-- a plushie for Config.PLUSHIES entry `def`, sitting on the floor at `base`
-- (a CFrame on the floor, facing -Z)
function Plushies.build(def, base, noGlow, quiet)
	local m = Instance.new("Model")
	m.Name = "Plushie"
	local col = def.color
	local pale = col:Lerp(WHITE, 0.55)
	local a = def.animal
	local V = Vector3.new
	if a == "octopus" then
		-- a big round head and six curly legs
		add(m, base, V(1.7, 1.6, 1.6), V(0, 1.25, 0), col)
		for i = 1, 6 do
			local ang = i / 6 * math.pi * 2
			add(m, base, V(0.35, 0.35, 0.9), V(math.cos(ang) * 0.75, 0.25, math.sin(ang) * 0.75), col, nil, CFrame.Angles(0, -ang + math.pi / 2, 0))
		end
		add(m, base, V(0.3, 0.36, 0.15), V(-0.32, 1.4, -0.75), BLACK)
		add(m, base, V(0.3, 0.36, 0.15), V(0.32, 1.4, -0.75), BLACK)
		add(m, base, V(0.35, 0.18, 0.12), V(0, 1.05, -0.78), pale)
	else
		-- sitting body, belly patch, stubby legs and arms, round head
		add(m, base, V(1.4, 1.5, 1.3), V(0, 0.75, 0), col)
		if a ~= "duck" then
			add(m, base, V(0.95, 1.05, 0.3), V(0, 0.7, -0.55), a == "penguin" and WHITE or pale)
		end
		add(m, base, V(0.55, 0.45, 0.7), V(-0.4, 0.22, -0.45), col) -- legs
		add(m, base, V(0.55, 0.45, 0.7), V(0.4, 0.22, -0.45), col)
		add(m, base, V(0.4, 0.75, 0.4), V(-0.75, 0.9, -0.1), col, nil, CFrame.Angles(0, 0, math.rad(-20))) -- arms
		add(m, base, V(0.4, 0.75, 0.4), V(0.75, 0.9, -0.1), col, nil, CFrame.Angles(0, 0, math.rad(20)))
		add(m, base, V(1.3, 1.2, 1.2), V(0, 1.95, 0), col) -- head
		-- eyes (the owl's and the frog's are big, white with dark middles)
		if a == "owl" or a == "frog" then
			local y = a == "frog" and 2.5 or 2.05
			for _, x in ipairs({ -0.3, 0.3 }) do
				add(m, base, V(0.45, 0.45, 0.3), V(x, y, -0.45), WHITE)
				add(m, base, V(0.2, 0.22, 0.12), V(x, y, -0.62), BLACK)
			end
		else
			add(m, base, V(0.18, 0.22, 0.1), V(-0.25, 2.05, -0.57), BLACK)
			add(m, base, V(0.18, 0.22, 0.1), V(0.25, 2.05, -0.57), BLACK)
		end
		-- muzzles and beaks
		if a == "duck" or a == "penguin" or a == "owl" then
			add(m, base, V(a == "duck" and 0.6 or 0.3, 0.2, 0.4), V(0, a == "owl" and 1.8 or 1.82, -0.62), ORANGE)
		elseif a == "pig" then
			add(m, base, V(0.2, 0.42, 0.42), V(0, 1.85, -0.6), pale:Lerp(Color3.fromRGB(255, 150, 170), 0.5), Enum.PartType.Cylinder, CFrame.Angles(0, math.rad(90), 0))
			add(m, base, V(0.07, 0.07, 0.06), V(-0.08, 1.87, -0.71), BLACK)
			add(m, base, V(0.07, 0.07, 0.06), V(0.08, 1.87, -0.71), BLACK)
		elseif a ~= "frog" then
			add(m, base, V(0.55, 0.38, 0.3), V(0, 1.8, -0.52), pale)
			add(m, base, V(0.16, 0.12, 0.1), V(0, 1.88, -0.68), a == "bunny" and Color3.fromRGB(255, 140, 170) or BLACK)
		end
		-- ears
		if a == "bear" then
			add(m, base, V(0.45, 0.45, 0.25), V(-0.45, 2.48, 0), col)
			add(m, base, V(0.45, 0.45, 0.25), V(0.45, 2.48, 0), col)
		elseif a == "bunny" then
			add(m, base, V(0.3, 1, 0.2), V(-0.25, 2.85, 0), col, nil, CFrame.Angles(0, 0, math.rad(8)))
			add(m, base, V(0.3, 1, 0.2), V(0.25, 2.85, 0), col, nil, CFrame.Angles(0, 0, math.rad(-8)))
			add(m, base, V(0.15, 0.7, 0.1), V(-0.25, 2.85, -0.08), Color3.fromRGB(255, 180, 200), nil, CFrame.Angles(0, 0, math.rad(8)))
			add(m, base, V(0.15, 0.7, 0.1), V(0.25, 2.85, -0.08), Color3.fromRGB(255, 180, 200), nil, CFrame.Angles(0, 0, math.rad(-8)))
		elseif a == "mouse" then
			add(m, base, V(0.75, 0.75, 0.15), V(-0.55, 2.5, 0), col)
			add(m, base, V(0.75, 0.75, 0.15), V(0.55, 2.5, 0), col)
			add(m, base, V(0.5, 0.5, 0.1), V(-0.55, 2.5, -0.08), Color3.fromRGB(255, 180, 200))
			add(m, base, V(0.5, 0.5, 0.1), V(0.55, 2.5, -0.08), Color3.fromRGB(255, 180, 200))
		elseif a == "cat" or a == "owl" then
			-- pointed ears (the owl's are feather tufts)
			for _, x in ipairs({ -0.38, 0.38 }) do
				add(m, base, V(0.38, 0.38, 0.15), V(x, 2.5, 0), a == "owl" and col:Lerp(BLACK, 0.3) or col, Enum.PartType.Block, CFrame.Angles(0, 0, math.rad(45)))
			end
		elseif a == "pig" then
			add(m, base, V(0.35, 0.35, 0.15), V(-0.45, 2.45, 0), col, Enum.PartType.Block, CFrame.Angles(0, 0, math.rad(45)))
			add(m, base, V(0.35, 0.35, 0.15), V(0.45, 2.45, 0), col, Enum.PartType.Block, CFrame.Angles(0, 0, math.rad(45)))
		elseif a == "dog" then
			-- floppy ears hanging down the sides
			add(m, base, V(0.3, 0.75, 0.4), V(-0.68, 1.95, 0), col:Lerp(BLACK, 0.25), nil, CFrame.Angles(0, 0, math.rad(-12)))
			add(m, base, V(0.3, 0.75, 0.4), V(0.68, 1.95, 0), col:Lerp(BLACK, 0.25), nil, CFrame.Angles(0, 0, math.rad(12)))
		end
		if a == "penguin" or a == "duck" then
			add(m, base, V(0.5, 0.15, 0.6), V(-0.35, 0.07, -0.5), ORANGE) -- feet
			add(m, base, V(0.5, 0.15, 0.6), V(0.35, 0.07, -0.5), ORANGE)
		end
	end
	if quiet then
		return m -- a decoration teddy: no sparkle, no glow
	end
	-- a faint sparkle so a sharp eye can spot it
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, 1.2, 0)
	att.Parent = m:FindFirstChildWhichIsA("BasePart")
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 240, 180))
	pe.Rate = 8
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Speed = NumberRange.new(0.5, 1.2)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new(0.35, 0)
	pe.LightEmission = 0.7
	pe.Parent = att
	if not noGlow then
		local glow = Instance.new("PointLight")
		glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(255, 230, 170), 7, 0.8
		glow.Parent = att
	end
	return m
end

return Plushies
