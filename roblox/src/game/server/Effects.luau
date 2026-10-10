--[[
	Effects - short visual bursts everyone sees: skills firing, items picked
	up, balloons popping, getting caught, rescues, escapes. Uses Roblox's
	built-in particle textures, so nothing needs uploading.
]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Sfx = require(game:GetService("ReplicatedStorage").Shared.Sfx)

local Effects = {}

-- the sound each burst makes
local KIND_SOUND = {
	pop = "pop", boost = "present", reveal = "reveal", light = "light", plant = "plant", shove = "shove",
	pick = "pick", rescue = "rescue", escape = "escape", caught = "cage", sneak = "sneak", heal = "heal", noise = "noise",
}

-- a sound everyone near the spot hears (louder the closer they are)
function Effects.sound(position, name, volume)
	local id = Config.SOUNDS[name]
	if not id or typeof(position) ~= "Vector3" then
		return
	end
	local holder = Instance.new("Part")
	holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.Position = position
	local s = Instance.new("Sound")
	s.SoundGroup = Sfx.group()
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume or 0.8
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 12
	s.RollOffMaxDistance = 90
	s.Parent = holder
	holder.Parent = workspace
	s:Play()
	local max = Config.SOUND_MAX[name] or 4
	task.delay(max, function()
		if s.Parent then
			s:Stop()
		end
	end)
	Debris:AddItem(holder, max + 0.5)
end

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

-- what each effect looks like: texture, colours, how many, speed, size, lifetime, light
local KINDS = {
	sneak = { SMOKE, { Color3.fromRGB(110, 70, 170), Color3.fromRGB(40, 20, 60) }, 40, 3, 3, 1.4, nil },
	heal = { SPARKLE, { Color3.fromRGB(123, 227, 107), Color3.fromRGB(255, 179, 199) }, 50, 6, 1.2, 1.6, Color3.fromRGB(123, 227, 107) },
	noise = { SPARKLE, { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 210, 63) }, 30, 10, 0.8, 0.8, nil },
	pick = { FIRE, { Color3.fromRGB(255, 210, 63), Color3.fromRGB(255, 120, 20) }, 30, 12, 0.5, 0.5, Color3.fromRGB(255, 200, 80) },
	reveal = { SPARKLE, { Color3.fromRGB(79, 179, 232), Color3.fromRGB(255, 255, 255) }, 50, 6, 1, 1.4, Color3.fromRGB(120, 190, 255) },
	light = { SPARKLE, { Color3.fromRGB(255, 242, 122), Color3.fromRGB(255, 255, 255) }, 70, 10, 1.4, 1.2, Color3.fromRGB(255, 242, 160) },
	shove = { SMOKE, { Color3.fromRGB(160, 130, 100), Color3.fromRGB(90, 70, 50) }, 40, 6, 3, 1.5, nil },
	plant = { SPARKLE, { Color3.fromRGB(95, 179, 90), Color3.fromRGB(255, 138, 192) }, 50, 5, 1.2, 1.8, Color3.fromRGB(120, 220, 120) },
	pop = { SPARKLE, { Color3.fromRGB(255, 77, 94), Color3.fromRGB(61, 139, 255), Color3.fromRGB(255, 210, 63), Color3.fromRGB(70, 209, 96) }, 80, 14, 0.7, 1.2, nil },
	boost = { SPARKLE, { Color3.fromRGB(255, 210, 63), Color3.fromRGB(255, 255, 255) }, 60, 7, 1, 1.4, Color3.fromRGB(255, 220, 120) },
	caught = { SMOKE, { Color3.fromRGB(200, 40, 40), Color3.fromRGB(60, 10, 10) }, 50, 5, 3, 1.2, Color3.fromRGB(255, 60, 40) },
	rescue = { SPARKLE, { Color3.fromRGB(255, 210, 63), Color3.fromRGB(123, 227, 107) }, 60, 8, 1.2, 1.4, Color3.fromRGB(255, 230, 140) },
	escape = { SPARKLE, { Color3.fromRGB(255, 77, 94), Color3.fromRGB(61, 139, 255), Color3.fromRGB(255, 210, 63), Color3.fromRGB(123, 227, 107) }, 120, 20, 1, 2, Color3.fromRGB(255, 240, 200) },
}

local function sequence(colours)
	local keys = {}
	for i, c in ipairs(colours) do
		table.insert(keys, ColorSequenceKeypoint.new(#colours == 1 and 0 or (i - 1) / (#colours - 1), c))
	end
	if #keys == 1 then
		table.insert(keys, ColorSequenceKeypoint.new(1, colours[1]))
	end
	return ColorSequence.new(keys)
end

-- sound: optional - another sound's name instead of the kind's own, or
-- false for none (the sparkle of "boost" with the "collect" ding, say)
function Effects.burst(position, kind, sound)
	local k = KINDS[kind]
	if not k or typeof(position) ~= "Vector3" then
		return
	end
	if sound == nil then
		sound = KIND_SOUND[kind]
	end
	if sound then
		Effects.sound(position, sound)
	end
	local holder = Instance.new("Part")
	holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.Position = position
	holder.Parent = workspace
	local att = Instance.new("Attachment")
	att.Parent = holder
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = k[1]
	pe.Color = sequence(k[2])
	pe.Speed = NumberRange.new(k[4] * 0.5, k[4])
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, k[5]), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(k[6] * 0.6, k[6])
	pe.LightEmission = 0.8
	pe.Rate = 0
	pe.Parent = att
	pe:Emit(k[3])
	if k[7] then
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = k[7], 16, 3
		l.Parent = holder
		TweenService:Create(l, TweenInfo.new(1.2), { Brightness = 0 }):Play()
	end
	if kind == "noise" then
		-- a ring that spreads out across the floor
		local ring = Instance.new("Part")
		ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(255, 255, 255)
		ring.Size = Vector3.new(0.2, 2, 2)
		ring.CFrame = CFrame.new(position.X, 0.3, position.Z) * CFrame.Angles(0, 0, math.rad(90))
		ring.Transparency = 0.2
		ring.Parent = workspace
		TweenService:Create(ring, TweenInfo.new(0.9), { Size = Vector3.new(0.2, 30, 30), Transparency = 1 }):Play()
		Debris:AddItem(ring, 1)
	end
	Debris:AddItem(holder, k[6] + 0.5)
end

-- what comes out of something empty: bats flutter away, tissue paper floats
-- down, or a pop of confetti
function Effects.surprise(position, kind)
	if kind == "bats" then
		Effects.sound(position, "sneak", 0.6)
		for _ = 1, 6 do
			-- a little bat: a round body and two wings swept up, flying off as one
			local from = CFrame.new(position + Vector3.new(math.random() - 0.5, 1.5, math.random() - 0.5)) * CFrame.Angles(0, math.random() * 6, 0)
			local goal = CFrame.new(position + Vector3.new(math.random(-10, 10), math.random(8, 13), math.random(-10, 10))) * CFrame.Angles(math.random() - 0.5, math.random() * 6, math.random() - 0.5)
			for k, piece in ipairs({
				{ Vector3.new(0.45, 0.45, 0.55), CFrame.new(), Enum.PartType.Ball },
				{ Vector3.new(0.9, 0.06, 0.6), CFrame.new(-0.6, 0.12, 0) * CFrame.Angles(0, 0, math.rad(25)), Enum.PartType.Block },
				{ Vector3.new(0.9, 0.06, 0.6), CFrame.new(0.6, 0.12, 0) * CFrame.Angles(0, 0, math.rad(-25)), Enum.PartType.Block },
			}) do
				local p = Instance.new("Part")
				p.Name = k == 1 and "Bat" or "BatWing"
				p.Shape = piece[3]
				p.Size = piece[1]
				require(game:GetService("ReplicatedStorage").Shared.Shapes).fix(p, piece[3], piece[1])
				p.Color = Color3.fromRGB(25, 15, 30)
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
				p.CFrame = from * piece[2]
				p.Parent = workspace
				TweenService:Create(p, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { CFrame = goal * piece[2], Transparency = 1 }):Play()
				Debris:AddItem(p, 1.8)
			end
		end
	elseif kind == "tissue" then
		Effects.sound(position, "hide", 0.5)
		for _ = 1, 8 do
			local sheet = Instance.new("Part")
			sheet.Name = "Tissue"
			sheet.Size = Vector3.new(1.3, 0.05, 1.3)
			sheet.Color = ({ Color3.fromRGB(255, 200, 220), Color3.fromRGB(200, 230, 255), Color3.fromRGB(255, 245, 200) })[math.random(1, 3)]
			sheet.Anchored, sheet.CanCollide, sheet.CanQuery, sheet.CanTouch = true, false, false, false
			sheet.CFrame = CFrame.new(position + Vector3.new(math.random() * 2 - 1, 3 + math.random() * 2, math.random() * 2 - 1))
			sheet.Parent = workspace
			local land = Vector3.new(position.X + math.random(-4, 4), position.Y - 1, position.Z + math.random(-4, 4))
			TweenService:Create(sheet, TweenInfo.new(2.2, Enum.EasingStyle.Sine), { CFrame = CFrame.new(land) * CFrame.Angles(0, math.random() * 6, 0) }):Play()
			task.delay(3, function()
				if sheet.Parent then
					TweenService:Create(sheet, TweenInfo.new(1), { Transparency = 1 }):Play()
				end
			end)
			Debris:AddItem(sheet, 4.2)
		end
	else
		Effects.burst(position, "pop")
	end
end

-- the burst at a player, a little above the floor
function Effects.at(player, kind, sound)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		Effects.burst(hrp.Position, kind, sound)
	end
end

-- ---------- lasting effects (skills version 2 polish) ----------

local Shapes = require(game:GetService("ReplicatedStorage").Shared.Shapes) -- stretched balls (eggs, fish bodies) need a sphere mesh
local function fxPart(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	for k, v in pairs(props) do
		p[k] = v
	end
	Shapes.fix(p, props.Shape, props.Size)
	p.Parent = props.Parent or workspace
	return p
end

local function hrpOf(player)
	return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- a flat ring that spreads across the floor from a spot (y = the floor)
function Effects.ring(position, color, size, seconds, delay)
	if typeof(position) ~= "Vector3" then
		return
	end
	task.delay(delay or 0, function()
		local ring = fxPart({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Color = color, Transparency = 0.15,
			Size = Vector3.new(0.15, 2, 2), CFrame = CFrame.new(position + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
		TweenService:Create(ring, TweenInfo.new(seconds or 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.15, size, size), Transparency = 1 }):Play()
		Debris:AddItem(ring, (seconds or 0.8) + 0.1)
	end)
end

-- a soft ball of light that swells out and fades (Glow's Flare)
function Effects.swell(position, color, size, seconds)
	if typeof(position) ~= "Vector3" then
		return
	end
	local ball = fxPart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = color, Transparency = 0.55,
		Size = Vector3.new(2, 2, 2), Position = position })
	TweenService:Create(ball, TweenInfo.new(seconds or 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(size, size, size), Transparency = 1 }):Play()
	Debris:AddItem(ball, (seconds or 0.7) + 0.1)
end

-- particles that follow a player for a while: Shadow's smoke while he
-- sneaks, Glow's sparkles while her Flare lasts, a streak while running fast
local AURAS = {
	sneak = { SMOKE, { Color3.fromRGB(120, 80, 190), Color3.fromRGB(30, 15, 50) }, 14, 1.5, 2.4, 1.3, 0.45 },
	flare = { SPARKLE, { Color3.fromRGB(255, 242, 122), Color3.fromRGB(255, 255, 255) }, 22, 4, 0.8, 1, 0.1 },
}
function Effects.aura(player, kind, seconds)
	local hrp = hrpOf(player)
	if not hrp or not seconds or seconds <= 0 then
		return
	end
	local name = "Aura_" .. kind
	local untilT = os.clock() + seconds
	local att = hrp:FindFirstChild(name)
	if att then
		if (att:GetAttribute("Until") or 0) >= untilT then
			return
		end
	elseif kind == "speed" then
		-- a golden streak behind a runner (Echo's burst, Glow's lift, Beacon)
		att = Instance.new("Attachment")
		att.Name = name
		att.Position = Vector3.new(0, 0.9, 0)
		local low = Instance.new("Attachment")
		low.Name = "Low"
		low.Position = Vector3.new(0, -1.8, 0)
		low.Parent = att
		local tr = Instance.new("Trail")
		tr.Attachment0, tr.Attachment1 = att, low
		tr.Lifetime = 0.35
		tr.LightEmission = 0.8
		tr.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 150, 40))
		tr.Transparency = NumberSequence.new(0.35, 1)
		tr.Parent = att
		att.Parent = hrp
	else
		local k = AURAS[kind]
		if not k then
			return
		end
		att = Instance.new("Attachment")
		att.Name = name
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = k[1]
		pe.Color = sequence(k[2])
		pe.Rate = k[3]
		pe.Speed = NumberRange.new(k[4] * 0.4, k[4])
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, k[5]), NumberSequenceKeypoint.new(1, k[5] * 0.3) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, k[7]), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(k[6] * 0.6, k[6])
		pe.LightEmission = 0.6
		pe.Parent = att
		att.Parent = hrp
	end
	att:SetAttribute("Until", untilT)
	task.delay(seconds + 0.05, function()
		if att.Parent and os.clock() >= (att:GetAttribute("Until") or 0) then
			local pe = att:FindFirstChildOfClass("ParticleEmitter")
			if pe then
				pe.Enabled = false -- let the last puffs fade
				Debris:AddItem(att, 1.5)
			else
				att:Destroy()
			end
		end
	end)
end

-- dizzy stars circling a head (the host stunned by a skill)
function Effects.stars(model, seconds)
	local head = model and (model:FindFirstChild("Head") or model.PrimaryPart)
	if not head or not head:IsA("BasePart") then
		return
	end
	local root = model.PrimaryPart or head
	local stars = {}
	for i = 1, 3 do
		local s = fxPart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 225, 90), Size = Vector3.new(0.7, 0.7, 0.7) })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 225, 90), 5, 1
		l.Parent = s
		stars[i] = s
	end
	local t0 = os.clock()
	local conn
	conn = game:GetService("RunService").Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > seconds or not root.Parent then
			conn:Disconnect()
			for _, s in ipairs(stars) do
				s:Destroy()
			end
			return
		end
		local cf, size = model:GetBoundingBox()
		local c = cf.Position + Vector3.new(0, size.Y / 2 + 0.6, 0)
		for i, s in ipairs(stars) do
			local a = t * 6 + i * (math.pi * 2 / 3)
			s.Position = c + Vector3.new(math.cos(a) * 1.6, math.sin(t * 8 + i) * 0.2, math.sin(a) * 1.6)
		end
	end)
	Effects.sound(head.Position, "dizzy", 0.7)
end

-- a picture that pops up over a player's head for a moment (💡 Think!, 🔧 Toolkit)
function Effects.icon(player, text, seconds)
	local char = player.Character
	local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
	if not head then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "SkillIcon"
	gui.Size = UDim2.fromScale(0.5, 0.5)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = head
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Text = text
	l.Parent = gui
	TweenService:Create(gui, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromScale(3, 3) }):Play()
	task.delay(seconds or 1.8, function()
		if gui.Parent then
			TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			TweenService:Create(gui, TweenInfo.new(0.4), { StudsOffset = Vector3.new(0, 4.5, 0) }):Play()
		end
	end)
	Debris:AddItem(gui, (seconds or 1.8) + 0.5)
end

-- a shimmering bubble round a player who has a Party Shield
function Effects.shield(player, on)
	local hrp = hrpOf(player)
	if not hrp then
		return
	end
	local bubble = hrp:FindFirstChild("ShieldBubble")
	if on and not bubble then
		bubble = Instance.new("Part")
		bubble.Name = "ShieldBubble"
		bubble.Shape = Enum.PartType.Ball
		bubble.Size = Vector3.new(7, 7, 7)
		bubble.Material = Enum.Material.ForceField
		bubble.Color = Color3.fromRGB(120, 200, 255)
		bubble.Transparency = 0.2
		bubble.CanCollide, bubble.CanQuery, bubble.CanTouch, bubble.CastShadow, bubble.Massless = false, false, false, false, true
		bubble.CFrame = hrp.CFrame
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = bubble, hrp
		w.Parent = bubble
		bubble.Parent = hrp
	elseif not on and bubble then
		bubble:Destroy()
	end
end

return Effects
