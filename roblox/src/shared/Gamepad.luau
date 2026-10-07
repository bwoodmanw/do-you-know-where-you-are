--[[
	Gamepad (client) - controller / Xbox support shared by the game and the
	Lobby screens.

	* Gamepad.on(): true while the player is using a controller (the last
	  input came from one); Gamepad.changed fires when that flips.
	* Gamepad.hint(button, text): a small tag on a button ("RB", "LB"...)
	  shown only while a controller is in use.
	* Gamepad.panel(frame, firstButton): when the panel opens with a
	  controller, its first button is selected (the left stick moves between
	  buttons, A presses, B closes the panel through the close function).
	* Gamepad.bind(keyCode, fn): a controller button that does something,
	  unless a menu has the selection (then the stick and A belong to it).
]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Gamepad = {}

local changedEvent = Instance.new("BindableEvent")
Gamepad.changed = changedEvent.Event

local function isPad(t)
	return t == Enum.UserInputType.Gamepad1 or t == Enum.UserInputType.Gamepad2 or t == Enum.UserInputType.Gamepad3 or t == Enum.UserInputType.Gamepad4
end

local using = isPad(UserInputService:GetLastInputType()) or (UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled)
function Gamepad.on()
	return using
end
UserInputService.LastInputTypeChanged:Connect(function(t)
	local now
	if isPad(t) then
		now = true
	elseif t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
		now = false
	end
	if now ~= nil and now ~= using then
		using = now
		changedEvent:Fire(using)
	end
end)

-- a tag in the corner of a button, only while a controller is in use
local hints = {}
function Gamepad.hint(button, text)
	local tag = Instance.new("TextLabel")
	tag.Name = "PadHint"
	tag.AnchorPoint = Vector2.new(1, 0)
	tag.Size = UDim2.fromOffset(30, 18)
	tag.Position = UDim2.new(1, 4, 0, -6)
	tag.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	tag.BackgroundTransparency = 0.1
	tag.TextColor3 = Color3.new(1, 1, 1)
	tag.Font = Enum.Font.GothamBlack
	tag.TextScaled = true
	tag.Text = text
	tag.ZIndex = (button.ZIndex or 1) + 2
	tag.Visible = using
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = tag
	tag.Parent = button
	table.insert(hints, tag)
	return tag
end
Gamepad.changed:Connect(function(on)
	for i = #hints, 1, -1 do
		local t = hints[i]
		if t.Parent then
			t.Visible = on
		else
			table.remove(hints, i)
		end
	end
end)

-- panels that are open, newest last; B closes the newest
local panels = {}
local function firstSelectable(frame)
	for _, d in ipairs(frame:GetDescendants()) do
		if d:IsA("GuiButton") and d.Visible and d.Selectable then
			return d
		end
	end
	return nil
end
function Gamepad.select(obj)
	if obj and using then
		pcall(function()
			GuiService.SelectedObject = obj
		end)
	end
end
-- frame: the panel; first: the button to select (or a function giving it);
-- close: what B does (default: hide the panel)
function Gamepad.panel(frame, first, close)
	local entry = { frame = frame, close = close or function()
		frame.Visible = false
	end }
	local function pick()
		local b = typeof(first) == "function" and first() or first
		return b or firstSelectable(frame)
	end
	local function opened()
		local i = table.find(panels, entry)
		if frame.Visible and frame.Parent then
			if not i then
				table.insert(panels, entry)
			end
			task.defer(function()
				Gamepad.select(pick())
			end)
		else
			if i then
				table.remove(panels, i)
			end
			local sel = GuiService.SelectedObject
			if sel and sel:IsDescendantOf(frame) then
				GuiService.SelectedObject = nil
				-- back to the panel underneath, if any
				local under = panels[#panels]
				if under then
					Gamepad.select(firstSelectable(under.frame))
				end
			end
		end
	end
	frame:GetPropertyChangedSignal("Visible"):Connect(opened)
	frame.AncestryChanged:Connect(opened)
	if frame.Visible then
		opened()
	end
	return entry
end
-- with a controller: when a panel's selection moves out of the screen,
-- choose its first button again
Gamepad.changed:Connect(function(on)
	if on and panels[#panels] and not GuiService.SelectedObject then
		Gamepad.select(firstSelectable(panels[#panels].frame))
	end
end)

-- a menu has the controller right now (a button is selected)
function Gamepad.menuActive()
	return GuiService.SelectedObject ~= nil
end

local binds = {}
function Gamepad.bind(keyCode, fn, evenInMenus)
	binds[keyCode] = binds[keyCode] or {}
	table.insert(binds[keyCode], { fn = fn, always = evenInMenus })
end
UserInputService.InputBegan:Connect(function(input, processed)
	if not isPad(input.UserInputType) then
		return
	end
	-- B: close the newest open panel
	if input.KeyCode == Enum.KeyCode.ButtonB then
		local top = panels[#panels]
		if top and top.frame.Visible then
			top.close()
			return
		end
	end
	local list = binds[input.KeyCode]
	if not list then
		return
	end
	local menu = GuiService.SelectedObject ~= nil
	for _, b in ipairs(list) do
		if b.always or (not menu and not processed) then
			task.spawn(b.fn, input)
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if not isPad(input.UserInputType) then
		return
	end
	local list = binds["end:" .. input.KeyCode.Name]
	for _, b in ipairs(list or {}) do
		task.spawn(b.fn, input)
	end
end)
-- fn runs when the button is let go
function Gamepad.bindRelease(keyCode, fn)
	local k = "end:" .. keyCode.Name
	binds[k] = binds[k] or {}
	table.insert(binds[k], { fn = fn })
end

-- the point in the middle of the screen (for aiming with a controller)
function Gamepad.aimPoint(exclude, maxDist)
	local cam = workspace.CurrentCamera
	local vs = cam.ViewportSize
	local ray = cam:ViewportPointToRay(vs.X / 2, vs.Y / 2)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude or {}
	local hit = workspace:Raycast(ray.Origin, ray.Direction * (maxDist or 300), params)
	return hit and hit.Position or nil
end

return Gamepad
