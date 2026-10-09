--[[
	ModelBounds - the box round the parts of a model you can see (no
	invisible parts: the HumanoidRootPart, a leftover import mesh, hit boxes).
	The 3D character views fit their camera to this, so every character
	fills the view the same (Echo's model had an invisible part that made
	her look small). Returns a CFrame (no turn) and a size, like GetBoundingBox.
]]

-- the 15 body parts of a Roblox (R15) character: with bodyOnly, hats,
-- hoods and other extras are left out (Ghostly Shadow's made him look small)
local BODY = {}
for _, n in ipairs({ "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }) do
	BODY[n] = true
end

local function bounds(model, bodyOnly)
	local lo, hi
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.95 and d.Name ~= "HumanoidRootPart" and (not bodyOnly or BODY[d.Name]) then
			local half = d.Size / 2
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local p = d.CFrame:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
						lo = lo and lo:Min(p) or p
						hi = hi and hi:Max(p) or p
					end
				end
			end
		end
	end
	if not lo then
		return nil
	end
	return CFrame.new((lo + hi) / 2), hi - lo
end

return function(model, bodyOnly)
	local cf, size = bounds(model, bodyOnly)
	if not cf and bodyOnly then
		cf, size = bounds(model, false)
	end
	if not cf then
		return model:GetBoundingBox()
	end
	return cf, size
end
