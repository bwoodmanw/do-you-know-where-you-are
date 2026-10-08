--[[
	Props - dresses the Party House with real furniture. Brent drops models
	(free Creator Store models or Meshy pieces) into ServerStorage -> Props,
	named as in FURNITURE.md; each one listed below is copied into its room,
	sized to fit its spot, stood on the floor (or hung from the ceiling),
	made solid, and stripped of any scripts. A missing model is skipped.
	Spots keep clear of doorways, hiding places, puzzles and the start.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local T = Config.TILE
local H = Config.WALL_H

local Props = {}

-- The furniture spots come with each floor plan (HouseMap props, made by
-- tools/make_housemap.py): x, y tile; w, d tiles of floor it may use; h max
-- height in studs; face: which way its front points (n, s, e, w); hang: from
-- the ceiling.

local FACE = { s = 0, w = math.rad(90), n = math.rad(180), e = math.rad(-90) }

local function strip(model)
	for _, d in ipairs(model:GetDescendants()) do
		-- (sounds too: a prop's own audio may not be allowed in this game; rooms have their own)
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Sound") then
			d:Destroy()
		end
	end
end

function Props.place(world)
	local folder = ServerStorage:FindFirstChild("Props")
	if not folder then
		return 0
	end
	local placed = 0
	for _, spot in ipairs(world.map.props or {}) do
		local src = folder:FindFirstChild(spot.name)
		if src then
			local m = src:IsA("Model") and src:Clone() or nil
			if not m then
				-- a single part or mesh: wrap it in a model
				m = Instance.new("Model")
				src:Clone().Parent = m
			end
			strip(m)
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = spot.h > 1 and not spot.hang
				end
			end
			-- face the room, then shrink or grow to fit the spot
			m:PivotTo(CFrame.Angles(0, FACE[spot.face] or 0, 0))
			local cf, size = m:GetBoundingBox()
			local turned = spot.face == "e" or spot.face == "w"
			local wx, dz = (turned and spot.d or spot.w) * T * 0.9, (turned and spot.w or spot.d) * T * 0.9
			local scale = math.min(wx / size.X, dz / size.Z, spot.h / size.Y)
			if scale > 0 and scale ~= 1 then
				m:ScaleTo(m:GetScale() * scale)
			end
			cf, size = m:GetBoundingBox()
			local centre = Vector3.new((spot.x + spot.w / 2) * T, 0, (spot.y + spot.d / 2) * T)
			local y = spot.hang and (H - size.Y / 2) or size.Y / 2
			m:PivotTo(m:GetPivot() + (Vector3.new(centre.X, y, centre.Z) - cf.Position))
			m.Name = spot.name
			m.Parent = world.root
			placed += 1
		end
	end
	return placed
end

return Props
