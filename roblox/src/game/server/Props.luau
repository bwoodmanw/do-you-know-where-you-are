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
	-- Parlour (x 1-9, y 1-8)
	{ name = "Fireplace", x = 1, y = 3, w = 1, d = 2, h = 9, face = "e" },
	{ name = "Armchair", x = 2, y = 5, w = 1, d = 1, h = 5, face = "e" },
	{ name = "GrandfatherClock", x = 9, y = 3, w = 1, d = 1, h = 11, face = "w" },
	{ name = "Rug", x = 4, y = 3, w = 3, d = 3, h = 0.4, face = "s" },
	{ name = "SideTable", x = 2, y = 1, w = 1, d = 1, h = 4, face = "s" },
	{ name = "Chandelier", x = 5, y = 4, w = 2, d = 2, h = 5, face = "s", hang = true },
	-- Corridor (x 11-18, y 1-8)
	{ name = "Bench", x = 11, y = 3, w = 1, d = 2, h = 4, face = "e" },
	{ name = "Bench", x = 18, y = 6, w = 1, d = 2, h = 4, face = "w" },
	{ name = "PottedPlant", x = 11, y = 7, w = 1, d = 1, h = 7, face = "e" },
	{ name = "Rug", x = 14, y = 2, w = 3, d = 5, h = 0.4, face = "s" },
	-- Library (x 20-28, y 1-8; shelves on rows 3 and 6)
	{ name = "Desk", x = 21, y = 8, w = 2, d = 1, h = 4.5, face = "n" },
	{ name = "DeskChair", x = 21, y = 7, w = 1, d = 1, h = 5, face = "s" },
	{ name = "Globe", x = 28, y = 4, w = 1, d = 1, h = 5, face = "w" },
	{ name = "FloorLamp", x = 20, y = 1, w = 1, d = 1, h = 9, face = "s" },
	-- Kitchen (x 1-9, y 10-20; counter on row 11)
	{ name = "Fridge", x = 1, y = 16, w = 1, d = 1, h = 10, face = "e" },
	{ name = "Stove", x = 1, y = 18, w = 1, d = 1, h = 5, face = "e" },
	{ name = "KitchenTable", x = 5, y = 15, w = 2, d = 2, h = 4, face = "s" },
	{ name = "DiningChair", x = 4, y = 16, w = 1, d = 1, h = 5, face = "e" },
	{ name = "DiningChair", x = 7, y = 16, w = 1, d = 1, h = 5, face = "w" },
	-- Front Hall (x 11-18, y 10-20; party table on 13-16 x 13-14)
	{ name = "DiningChair", x = 12, y = 13, w = 1, d = 1, h = 5, face = "e" },
	{ name = "DiningChair", x = 12, y = 14, w = 1, d = 1, h = 5, face = "e" },
	{ name = "DiningChair", x = 17, y = 13, w = 1, d = 1, h = 5, face = "w" },
	{ name = "DiningChair", x = 17, y = 14, w = 1, d = 1, h = 5, face = "w" },
	{ name = "Chandelier", x = 14, y = 13, w = 2, d = 2, h = 5, face = "s", hang = true },
	{ name = "CoatRack", x = 18, y = 20, w = 1, d = 1, h = 8, face = "w" },
	{ name = "Pumpkin", x = 11, y = 20, w = 1, d = 1, h = 2.5, face = "e" },
	-- Game Room (x 20-28, y 10-20)
	{ name = "ArcadeMachine", x = 28, y = 10, w = 1, d = 1, h = 8, face = "w" },
	{ name = "BallPit", x = 21, y = 18, w = 2, d = 2, h = 3, face = "n" },
	{ name = "PoolTable", x = 22, y = 13, w = 2, d = 1, h = 4, face = "s" },
	{ name = "BeanBag", x = 26, y = 15, w = 1, d = 1, h = 3, face = "w" },
	{ name = "DiscoBall", x = 24, y = 15, w = 1, d = 1, h = 3, face = "s", hang = true },
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
