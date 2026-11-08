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
