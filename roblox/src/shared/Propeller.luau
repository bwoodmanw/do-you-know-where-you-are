--[[
	Propeller - Brainy's spinning beanie propeller, built from parts and welded
	on top of a character's head (Stable Fast 3D lost the thin one from the toon
	model, 10 Oct). Which models get one: Config.PROPELLER.

	Propeller.add(model)   on a character (server) or a Lobby preview (client)
	Propeller.spinAll(t)   each frame on every screen: turns every propeller
	                       (a local turn, so it costs no network traffic)
]]

local CollectionService = game:GetService("CollectionService")

local Propeller = {}
local TAG = "PropellerSpin"
local SPEED = 14 -- turns the blades this many radians a second
local BLUE = Color3.fromRGB(45, 140, 255)
local STEEL = Color3.fromRGB(150, 155, 165)

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, false, true, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = a, b
	w.Parent = b
end

function Propeller.add(model, lift)
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") or model:FindFirstChild("Propeller") then
		return
	end
	local s = math.max(head.Size.X, head.Size.Z) -- everything in head widths
	local holder = Instance.new("Model")
	holder.Name = "Propeller"
	holder.Parent = model
	local top = head.CFrame * CFrame.new(0, head.Size.Y / 2 + (lift or 0) * s, 0)
	-- a short steel stem (a Cylinder's height is its X: stood up with a turn)
	local stem = part(holder, { Name = "Stem", Shape = Enum.PartType.Cylinder, Color = STEEL,
		Size = Vector3.new(0.2 * s, 0.07 * s, 0.07 * s), CFrame = top * CFrame.new(0, 0.08 * s, 0) * CFrame.Angles(0, 0, math.rad(90)) })
	weld(head, stem)
	local hub = part(holder, { Name = "Hub", Shape = Enum.PartType.Ball, Color = STEEL,
		Size = Vector3.new(0.12, 0.12, 0.12) * s, CFrame = top * CFrame.new(0, 0.2 * s, 0) })
	weld(head, hub)
	-- two blue blades, pitched opposite ways like a real propeller; the first
	-- turns on a Weld (spinAll), the second rides on it
	local bladeSize = Vector3.new(0.5 * s, 0.035 * s, 0.17 * s)
	local blade = part(holder, { Name = "Blade", Color = BLUE, Size = bladeSize, CFrame = hub.CFrame * CFrame.new(0.3 * s, 0, 0) * CFrame.Angles(math.rad(12), 0, 0) })
	local spin = Instance.new("Weld")
	spin.Name = "Spin"
	spin.Part0, spin.Part1 = hub, blade
	spin.C0 = CFrame.new()
	spin.C1 = blade.CFrame:ToObjectSpace(hub.CFrame)
	spin:SetAttribute("Base", spin.C0)
	spin.Parent = blade
	local other = part(holder, { Name = "Blade2", Color = BLUE, Size = bladeSize, CFrame = hub.CFrame * CFrame.new(-0.3 * s, 0, 0) * CFrame.Angles(math.rad(-12), 0, 0) })
	weld(blade, other)
	CollectionService:AddTag(spin, TAG)
	return holder
end

function Propeller.spinAll(t)
	local turn = CFrame.Angles(0, (t * SPEED) % (math.pi * 2), 0)
	for _, w in ipairs(CollectionService:GetTagged(TAG)) do
		if w.Parent and w:IsA("Weld") then
			local base = w:GetAttribute("Base")
			w.C0 = (typeof(base) == "CFrame" and base or CFrame.new()) * turn
		end
	end
end

return Propeller
