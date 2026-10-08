--[[
	PreviewPose (client) - a character saved in a T-pose (arms straight out,
	like the remade Echo and Ghostly Shadow) plays Roblox's standard idle
	animation in the 3D character views, so its arms come down the same way
	they do in the game. The animation bends the model's skin properly
	(moving the arm parts by hand squashed them - 8 Oct). Characters already
	standing with their arms down are left exactly as they are.

	Call it after the copy is in the view's WorldModel. If anything is
	missing (no Humanoid, the animation does not load) the model simply stays
	in its T-pose.
]]

local IDLE = "rbxassetid://507766666" -- Roblox's R15 idle (the Animate script's own)

local function armsOut(model)
	local root = model:FindFirstChild("HumanoidRootPart", true)
	local frame = root and root.CFrame or model:GetPivot()
	local axis, down = frame.LookVector, -frame.UpVector
	for _, side in ipairs({ "Left", "Right" }) do
		local upper = model:FindFirstChild(side .. "UpperArm", true)
		local hand = model:FindFirstChild(side .. "Hand", true)
		if upper and hand and upper:IsA("BasePart") and hand:IsA("BasePart") then
			local top = (upper.CFrame * CFrame.new(0, upper.Size.Y / 2, 0)).Position
			local d = hand.Position - top
			d -= axis * d:Dot(axis)
			if d.Magnitude > 0.1 and math.acos(math.clamp(d.Unit:Dot(down), -1, 1)) > math.rad(65) then
				return true
			end
		end
	end
	return false
end

return function(model)
	if not armsOut(model) then
		return
	end
	local hum = model:FindFirstChildWhichIsA("Humanoid", true)
	if not hum then
		return
	end
	-- the body hangs from its root, as it does in the game, so the joints can move
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = d.Name == "HumanoidRootPart"
		end
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = IDLE
	local track = animator:LoadAnimation(anim)
	track.Looped = true
	track:Play(0)
end
