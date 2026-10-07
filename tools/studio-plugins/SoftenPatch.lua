--[[
	Escape Crew - "Soften Patch" Studio plugin (local plugin).
	Copied to %LOCALAPPDATA%\Roblox\Plugins. In Studio: Plugins tab ->
	Escape Crew -> Soften Patch.

	Imported Meshy characters wear a SurfaceAppearance whose bumpy maps make
	faces look blotchy. A running game cannot read its colour picture, but a
	plugin can: this copies each SurfaceAppearance's colour picture into its
	MeshPart's TextureID and removes the SurfaceAppearance. Undo with Ctrl+Z.

	It works on the model selected in Explorer, or on
	ServerStorage -> Characters -> Patch when nothing is selected.
]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local toolbar = plugin:CreateToolbar("Escape Crew")
local button = toolbar:CreateButton("Soften Patch", "Smooth a character's face: colour picture only, no bumpy maps (selected model, or Characters/Patch)", "")
button.ClickableWhenViewportHidden = true

local function colourOf(sa)
	local ok, c = pcall(function()
		return sa.ColorMap
	end)
	if ok and typeof(c) == "string" and c ~= "" then
		return c
	end
	local ok2, uri = pcall(function()
		return sa.ColorMapContent.Uri
	end)
	if ok2 and typeof(uri) == "string" and uri ~= "" then
		return uri
	end
	return nil
end

button.Click:Connect(function()
	local target = Selection:Get()[1]
	if not (target and target:IsA("Model")) then
		local folder = game:GetService("ServerStorage"):FindFirstChild("Characters")
		target = folder and folder:FindFirstChild("Patch")
	end
	if not target then
		warn("Soften Patch: select a character model in Explorer, or put Patch in ServerStorage -> Characters")
		return
	end
	local recording = ChangeHistoryService:TryBeginRecording("Soften " .. target.Name)
	local done, missing = 0, 0
	for _, d in ipairs(target:GetDescendants()) do
		if d:IsA("SurfaceAppearance") and d.Parent and d.Parent:IsA("MeshPart") then
			local c = colourOf(d)
			if c then
				d.Parent.TextureID = c
				d.Parent = nil
				done += 1
			else
				missing += 1
			end
		end
	end
	if recording then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end
	print(string.format("Soften Patch: %s - softened %d parts%s", target:GetFullName(), done, missing > 0 and (", " .. missing .. " had no colour picture") or ""))
	if done == 0 and missing == 0 then
		print("Soften Patch: " .. target.Name .. " has no SurfaceAppearance left - it is already soft (or the blotches are in its picture)")
	end
end)
