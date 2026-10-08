--[[
	RestPose (client) - a character saved in a T-pose (arms straight out,
	like the remade Echo and Ghostly Shadow) stands with its arms down in the
	3D character views. Each arm (upper arm, lower arm, hand) turns together
	round its shoulder, as an animation would move it, until it hangs a
	little out from the body. Arms already down (or in an A-pose) are left alone. Only for the
	anchored copies in the views; the game itself animates the real models.
]]

local OUT = math.rad(12) -- how far from straight down the arms rest

return function(model)
	local root = model:FindFirstChild("HumanoidRootPart", true)
	local frame = root and root.CFrame or model:GetPivot()
	local axis = frame.LookVector -- the arms swing round the way the character faces
	local down = -frame.UpVector
	for _, side in ipairs({ "Left", "Right" }) do
		local upper = model:FindFirstChild(side .. "UpperArm", true)
		local lower = model:FindFirstChild(side .. "LowerArm", true)
		local hand = model:FindFirstChild(side .. "Hand", true)
		if upper and upper:IsA("BasePart") and hand and hand:IsA("BasePart") then
			-- the shoulder: where the shoulder joint holds the arm, else the arm's top
			local pivot
			local joint = upper:FindFirstChild(side .. "Shoulder")
			if joint and joint:IsA("Motor6D") and joint.Part0 then
				pivot = (joint.Part0.CFrame * joint.C0).Position
			else
				pivot = (upper.CFrame * CFrame.new(0, upper.Size.Y / 2, 0)).Position
			end
			local d = hand.Position - pivot
			local dp = d - axis * d:Dot(axis)
			if dp.Magnitude > 0.1 then
				dp = dp.Unit
				if math.acos(math.clamp(dp:Dot(down), -1, 1)) > math.rad(65) then
					-- the target: straight down, turned a little out towards this arm's side
					local outward = dp - down * dp:Dot(down)
					outward = outward.Magnitude > 0.01 and outward.Unit or Vector3.zero
					local target = (down * math.cos(OUT) + outward * math.sin(OUT)).Unit
					local angle = math.atan2(dp:Cross(target):Dot(axis), dp:Dot(target))
					local p = CFrame.new(pivot)
					local turn = p * CFrame.fromAxisAngle(axis, angle) * p:Inverse()
					for _, part in ipairs({ upper, lower, hand }) do
						if part and part:IsA("BasePart") then
							part.CFrame = turn * part.CFrame
						end
					end
				end
			end
		end
	end
end
