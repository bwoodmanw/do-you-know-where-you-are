--[[
	Escape Crew - "Soften Patch" Studio plugin (local plugin).
	Copied to %LOCALAPPDATA%\Roblox\Plugins. In Studio, with the game
	STOPPED (not playing): Plugins tab -> Escape Crew -> Soften Patch.
	A small window shows what it did.

	Imported Meshy characters wear a SurfaceAppearance whose bumpy maps make
	faces look blotchy. A running game cannot read its colour picture, but a
	plugin can: this copies each SurfaceAppearance's colour picture into its
	MeshPart's TextureID and removes the SurfaceAppearance. Undo with Ctrl+Z.

	It works on the model selected in Explorer, or on
	ServerStorage -> Characters -> Patch when nothing is selected.
]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")

local toolbar = plugin:CreateToolbar("Escape Crew")
local button = toolbar:CreateButton("Soften Patch", "Smooth a character's face: colour picture only, no bumpy maps (selected model, or Characters/Patch)", "")
button.ClickableWhenViewportHidden = true

-- a small window that shows the result (no need to find the Output panel)
local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 380, 150, 300, 120)
local widget = plugin:CreateDockWidgetPluginGui("EscapeCrewSoftenPatch", info)
widget.Title = "Soften Patch"
local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundColor3 = Color3.fromRGB(30, 22, 40)
text.TextColor3 = Color3.fromRGB(255, 244, 224)
text.Font = Enum.Font.GothamBold
text.TextSize = 16
text.TextWrapped = true
text.Parent = widget

local function show(msg)
	text.Text = msg
	widget.Enabled = true
	print("Soften Patch: " .. msg)
end

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
	if RunService:IsRunning() then
		show("The game is playing. Press Stop (the red square at the top) first, then click Soften Patch again.\n\n(Changes made while playing are thrown away when you stop.)")
		return
	end
	local target = Selection:Get()[1]
	if not (target and target:IsA("Model")) then
		local folder = game:GetService("ServerStorage"):FindFirstChild("Characters")
		target = folder and folder:FindFirstChild("Patch")
	end
	if not target then
		show("No Patch found. Open the Party House place (it has ServerStorage > Characters > Patch), or click a character model in Explorer first.")
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
	if done == 0 and missing == 0 then
		show(target.Name .. " is already soft (no SurfaceAppearance left). If the face is still blotchy, the blotches are in its picture.")
	else
		show(string.format("Done! Softened %d parts on %s.%s\n\nPress Play to look at the face. Ctrl+Z undoes it.\nThen right-click %s > Save to Roblox so the Lobby matches.", done, target.Name, missing > 0 and (" (" .. missing .. " had no colour picture.)") or "", target.Name))
	end
end)
