-- Photo mode (5 Nov, Brent: store thumbnails from real game shots). In Studio
-- only, P hides every on-screen button, bar and name tag (and Roblox's own
-- menus) for a clean screenshot; P again brings them back. Players never get it.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local hidden = false
local was = {}

local function setHidden(on)
	hidden = on
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not on)
	end)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if gui then
		for _, g in ipairs(gui:GetChildren()) do
			if g:IsA("LayerCollector") then
				if on then
					was[g] = g.Enabled
					g.Enabled = false
				elseif was[g] ~= nil then
					g.Enabled = was[g]
				end
			end
		end
	end
	-- name tags and other floating labels over heads; (7 Nov) the names
	-- Roblox puts over every character (Player1...) too
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BillboardGui") then
			if on then
				was[d] = d.Enabled
				d.Enabled = false
			elseif was[d] ~= nil then
				d.Enabled = was[d]
			end
		elseif d:IsA("Humanoid") then
			if on then
				was[d] = d.DisplayDistanceType
				d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			elseif was[d] ~= nil then
				d.DisplayDistanceType = was[d]
			end
		end
	end
	-- (7 Nov) the E prompts, the mouse pointer and Roblox's top-left buttons
	pcall(function()
		game:GetService("ProximityPromptService").Enabled = not on
	end)
	UserInputService.MouseIconEnabled = not on
	pcall(function()
		StarterGui:SetCore("TopbarEnabled", not on)
	end)
	if not on then
		was = {}
	end
	print(on and "[Photo mode] on - everything on screen hidden; press P again to bring it back" or "[Photo mode] off")
end

UserInputService.InputBegan:Connect(function(input, used)
	if not used and input.KeyCode == Enum.KeyCode.P then
		setHidden(not hidden)
	end
end)

-- (7 Nov, Brent: something invisible kept him out of a corner) Studio only:
-- K names every solid thing just in front of you (knee, waist and head
-- height) in the Output panel and outlines it in red for 10 s
UserInputService.InputBegan:Connect(function(input, used)
	if used or input.KeyCode ~= Enum.KeyCode.K then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	look = look.Magnitude > 0.05 and look.Unit or Vector3.new(0, 0, -1)
	local found = 0
	for _, up in ipairs({ -1.8, 0, 2 }) do
		local hit = workspace:Raycast(hrp.Position + Vector3.new(0, up, 0), look * 6, params)
		if hit then
			found += 1
			local p = hit.Instance
			print(string.format("[Blocked by] %s | size %s | at %s | see-through %.2f | solid %s | group %s",
				p:GetFullName(), tostring(p.Size), tostring(p.Position), p.Transparency, tostring(p.CanCollide), p.CollisionGroup))
			local box = Instance.new("SelectionBox")
			box.Adornee = p
			box.Color3 = Color3.fromRGB(255, 40, 40)
			box.LineThickness = 0.15
			box.Parent = workspace.CurrentCamera
			game:GetService("Debris"):AddItem(box, 10)
		end
	end
	if found == 0 then
		print("[Blocked by] nothing solid within 6 studs in front of you")
	end
end)
