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

function Effects.burst(position, kind)
	local k = KINDS[kind]
	if not k or typeof(position) ~= "Vector3" then
		return
	end
	if KIND_SOUND[kind] then
		Effects.sound(position, KIND_SOUND[kind])
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
			local bat = Instance.new("Part")
			bat.Name = "Bat"
			bat.Size = Vector3.new(1.4, 0.15, 0.7)
			bat.Color = Color3.fromRGB(25, 15, 30)
			bat.Anchored, bat.CanCollide, bat.CanQuery, bat.CanTouch = true, false, false, false
			bat.CFrame = CFrame.new(position + Vector3.new(math.random() - 0.5, 1.5, math.random() - 0.5))
			bat.Parent = workspace
			local goal = position + Vector3.new(math.random(-10, 10), math.random(8, 13), math.random(-10, 10))
			TweenService:Create(bat, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { CFrame = CFrame.new(goal) * CFrame.Angles(math.random() * 2, math.random() * 6, math.random() * 2), Transparency = 1 }):Play()
			Debris:AddItem(bat, 1.8)
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
function Effects.at(player, kind)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		Effects.burst(hrp.Position, kind)
	end
end

return Effects
