--[[
	PreviewPose (client) - the 3D character views (Lobby -> Characters, the
	game's character select) play the character's own idle from its
	animation pack (Config.ANIM: Shadow's ninja idle, Muscle's superhero
	idle...), so the preview stands the way it does in the game. The
	animation bends the model's skin properly (moving the arm parts by hand
	squashed them - 8 Oct).

	A character saved in a T-pose (arms straight out, like the remade Echo
	and Ghostly Shadow) plays it at 85%: the arms hang a little out from the
	body, which keeps the shoulders from bunching.

	Call it after the copy is in the view's WorldModel, with the character's
	skill id (and the model's name, for a skin with its own pack). If
	anything is missing (no Humanoid, the animation does not load) the model
	simply stays as it was saved.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IDLE = 507766666 -- Roblox's R15 idle (the Animate script's own)

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

-- the idle of this character's pack (a skin's own pack first), or Roblox's
local function idleFor(skillId, modelName)
	local ok, Config = pcall(require, ReplicatedStorage.Shared.Config)
	local A = ok and Config.ANIM
	if not A then
		return IDLE
	end
	local pack = A.packs[(modelName and A.model[modelName]) or A.skill[skillId or ""] or ""]
	return pack and pack.idle or IDLE
end

return function(model, skillId, modelName)
	local hum = model:FindFirstChildWhichIsA("Humanoid", true)
	if not hum then
		return
	end
	local tPose = armsOut(model)
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
	anim.AnimationId = "rbxassetid://" .. idleFor(skillId, modelName or model.Name)
	local track = animator:LoadAnimation(anim)
	track.Looped = true
	track:Play(0, tPose and 0.85 or 1)
end
