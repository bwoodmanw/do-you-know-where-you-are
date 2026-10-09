--[[
	Fish - little fish for the Aquarium's tanks and the Shark Tunnel: a round
	body, a fanned tail, a fin on top, two eyes (clownfish get white
	stripes). They swim from one end to the other, turn round, and swim
	back. Before 10 Oct the fish were two loose blocks (the tail did not
	even move with the body).
]]

local TweenService = game:GetService("TweenService")

local Fish = {}

local function piece(model, body, size, offset, color, shape, rot)
	local p = Instance.new("Part")
	p.Shape = shape or Enum.PartType.Ball
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless = false, false, false, false, true
	p.Anchored = false
	p.CFrame = body.CFrame * CFrame.new(offset) * (rot or CFrame.new())
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = body, p
	w.Parent = p
	p.Parent = model
	return p
end

-- a fish facing -Z at `cf`; returns its body (anchored: move it to move the fish)
function Fish.make(parent, cf, color, scale)
	local s = scale or 1
	local m = Instance.new("Model")
	m.Name = "Fish"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(0.5, 0.75, 1.3) * s
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide, body.CanQuery, body.CanTouch, body.CastShadow = false, false, false, false
	body.CFrame = cf
	body.Parent = m
	m.PrimaryPart = body
	local V = Vector3.new
	-- the tail: a fan at the back, two lobes
	piece(m, body, V(0.08, 0.55, 0.5) * s, V(0, 0.18, 0.8) * s, color, nil, CFrame.Angles(math.rad(-30), 0, 0))
	piece(m, body, V(0.08, 0.55, 0.5) * s, V(0, -0.18, 0.8) * s, color, nil, CFrame.Angles(math.rad(30), 0, 0))
	-- a fin on top and two small side fins
	piece(m, body, V(0.06, 0.3, 0.55) * s, V(0, 0.38, 0.05) * s, color:Lerp(Color3.new(0, 0, 0), 0.15))
	piece(m, body, V(0.05, 0.2, 0.35) * s, V(0.27, -0.12, -0.1) * s, color, nil, CFrame.Angles(0, 0, math.rad(-35)))
	piece(m, body, V(0.05, 0.2, 0.35) * s, V(-0.27, -0.12, -0.1) * s, color, nil, CFrame.Angles(0, 0, math.rad(35)))
	-- eyes: white with a dark middle
	for _, x in ipairs({ -0.2, 0.2 }) do
		piece(m, body, V(0.16, 0.16, 0.16) * s, V(x, 0.1, -0.42) * s, Color3.new(1, 1, 1))
		piece(m, body, V(0.09, 0.09, 0.09) * s, V(x * 1.25, 0.1, -0.46) * s, Color3.fromRGB(20, 20, 30))
	end
	-- an orange fish is a clownfish: white stripes
	if color.R > 0.9 and color.G > 0.45 and color.G < 0.65 then
		piece(m, body, V(0.53, 0.78, 0.14) * s, V(0, 0, -0.2) * s, Color3.new(1, 1, 1))
		piece(m, body, V(0.45, 0.62, 0.12) * s, V(0, 0, 0.35) * s, Color3.new(1, 1, 1))
	end
	m.Parent = parent
	return body
end

-- swim between two points for ever: there, turn round, back (it stops when
-- the fish is removed)
function Fish.swim(body, a, b, seconds)
	task.spawn(function()
		local from, to = a, b
		while body.Parent and body.Parent.Parent do
			body.CFrame = CFrame.lookAt(from, to)
			local tw = TweenService:Create(body, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = CFrame.lookAt(to, to + (to - from)) })
			tw:Play()
			tw.Completed:Wait()
			task.wait(0.3)
			from, to = to, from
		end
	end)
end

return Fish
