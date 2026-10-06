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

-- x, y: tile; w, d: tiles of floor it may use; h: max height in studs;
-- face: which way its front points (n, s, e, w); hang: from the ceiling
local SPOTS = {
	{ name = "Fireplace", x = 9, y = 2, w = 1, d = 2, h = 9, face = "w" },
	{ name = "Armchair", x = 7, y = 2, w = 1, d = 1, h = 5, face = "w" },
	{ name = "Rug", x = 6, y = 6, w = 2, d = 2, h = 0.4, face = "s" },
	{ name = "Chandelier", x = 4, y = 2, w = 2, d = 2, h = 5, face = "s", hang = true },
	{ name = "GrandfatherClock", x = 1, y = 3, w = 1, d = 1, h = 11, face = "e" },
	{ name = "Desk", x = 12, y = 1, w = 2, d = 1, h = 4.5, face = "s" },
	{ name = "DeskChair", x = 12, y = 2, w = 1, d = 1, h = 5, face = "n" },
	{ name = "Globe", x = 19, y = 2, w = 1, d = 1, h = 5, face = "w" },
	{ name = "FloorLamp", x = 11, y = 1, w = 1, d = 1, h = 9, face = "s" },
	{ name = "Rug", x = 13, y = 4, w = 4, d = 2, h = 0.4, face = "s" },
	{ name = "Bench", x = 21, y = 1, w = 2, d = 1, h = 4, face = "s" },
	{ name = "Bench", x = 28, y = 8, w = 2, d = 1, h = 4, face = "n" },
	{ name = "PottedPlant", x = 29, y = 1, w = 1, d = 1, h = 7, face = "w" },
	{ name = "PottedPlant", x = 21, y = 8, w = 1, d = 1, h = 7, face = "e" },
	{ name = "Rug", x = 24, y = 2, w = 3, d = 5, h = 0.4, face = "s" },
	{ name = "FloorLamp", x = 31, y = 1, w = 1, d = 1, h = 9, face = "s" },
	{ name = "BeanBag", x = 34, y = 6, w = 1, d = 1, h = 3, face = "n" },
	{ name = "DiscoBall", x = 34, y = 4, w = 1, d = 1, h = 3, face = "s", hang = true },
	{ name = "Armchair", x = 37, y = 4, w = 1, d = 1, h = 5, face = "w" },
	{ name = "Fridge", x = 1, y = 16, w = 1, d = 1, h = 10, face = "e" },
	{ name = "Stove", x = 1, y = 18, w = 1, d = 1, h = 5, face = "e" },
	{ name = "KitchenTable", x = 7, y = 13, w = 2, d = 1, h = 4, face = "s" },
	{ name = "DiningChair", x = 8, y = 16, w = 1, d = 1, h = 5, face = "w" },
	{ name = "DiningChair", x = 12, y = 12, w = 1, d = 1, h = 5, face = "s" },
	{ name = "DiningChair", x = 14, y = 12, w = 1, d = 1, h = 5, face = "s" },
	{ name = "DiningChair", x = 16, y = 12, w = 1, d = 1, h = 5, face = "s" },
	{ name = "DiningChair", x = 13, y = 15, w = 1, d = 1, h = 5, face = "n" },
	{ name = "DiningChair", x = 17, y = 15, w = 1, d = 1, h = 5, face = "n" },
	{ name = "Chandelier", x = 14, y = 13, w = 2, d = 2, h = 5, face = "s", hang = true },
	{ name = "SideTable", x = 19, y = 10, w = 1, d = 1, h = 4, face = "w" },
	{ name = "ArcadeMachine", x = 29, y = 10, w = 1, d = 1, h = 8, face = "w" },
	{ name = "PoolTable", x = 26, y = 15, w = 2, d = 1, h = 4, face = "s" },
	{ name = "BallPit", x = 27, y = 11, w = 2, d = 2, h = 3, face = "w" },
	{ name = "BeanBag", x = 21, y = 18, w = 1, d = 1, h = 3, face = "e" },
	{ name = "DiscoBall", x = 24, y = 14, w = 1, d = 1, h = 3, face = "s", hang = true },
	{ name = "PottedPlant", x = 31, y = 10, w = 1, d = 1, h = 7, face = "e" },
	{ name = "PottedPlant", x = 38, y = 14, w = 1, d = 1, h = 7, face = "w" },
	{ name = "Bench", x = 33, y = 17, w = 2, d = 1, h = 4, face = "n" },
	{ name = "Pumpkin", x = 1, y = 23, w = 1, d = 1, h = 2.5, face = "e" },
	{ name = "CoatRack", x = 28, y = 28, w = 1, d = 1, h = 8, face = "n" },
	{ name = "Pumpkin", x = 11, y = 28, w = 1, d = 1, h = 2.5, face = "e" },
	{ name = "DiningChair", x = 13, y = 23, w = 1, d = 1, h = 5, face = "e" },
	{ name = "DiningChair", x = 18, y = 24, w = 1, d = 1, h = 5, face = "w" },
	{ name = "Chandelier", x = 15, y = 23, w = 2, d = 2, h = 5, face = "s", hang = true },
	{ name = "Rug", x = 22, y = 21, w = 4, d = 3, h = 0.4, face = "s" },
}

local FACE = { s = 0, w = math.rad(90), n = math.rad(180), e = math.rad(-90) }

local function strip(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
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
	for _, spot in ipairs(SPOTS) do
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
