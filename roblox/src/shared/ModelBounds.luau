--[[
	ModelBounds - the box round the parts of a model you can see (no
	invisible parts: the HumanoidRootPart, a leftover import mesh, hit boxes).
	The 3D character views fit their camera to this, so every character
	fills the view the same (Echo's model had an invisible part that made
	her look small). Returns a CFrame (no turn) and a size, like GetBoundingBox.
]]

return function(model)
	local lo, hi
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.95 and d.Name ~= "HumanoidRootPart" then
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
		return model:GetBoundingBox()
	end
	return CFrame.new((lo + hi) / 2), hi - lo
end
