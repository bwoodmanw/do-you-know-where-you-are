--[[
	Characters - swaps a player's avatar for the real Escape Crew character
	when one has been imported into ServerStorage -> Characters (named Glow,
	Tinker, Host, ...). Until a model exists the player keeps their avatar,
	so characters can arrive one at a time.
]]

local ServerStorage = game:GetService("ServerStorage")

local Characters = {}

local KID_HEIGHT = 5.4 -- studs; the host is about twice that
local HOST_HEIGHT = 12 -- rooms are 14 tall

local function rigged(m)
	if m:FindFirstChildOfClass("Humanoid") then
		return m
	end
	for _, c in ipairs(m:GetChildren()) do
		if c:IsA("Model") and c:FindFirstChildOfClass("Humanoid") then
			return c
		end
	end
	return m
end

local function template(name)
	local folder = ServerStorage:FindFirstChild("Characters")
	if not folder then
		return nil
	end
	local want = string.lower(name)
	for _, c in ipairs(folder:GetChildren()) do
		if c:IsA("Model") and string.lower(c.Name) == want then
			return rigged(c)
		end
	end
	-- a near miss ("Muscle1", "muscle_rig", "Muscle "): use it, and say so
	for _, c in ipairs(folder:GetChildren()) do
		if c:IsA("Model") and string.find(string.lower(c.Name), want, 1, true) then
			warn("Using ServerStorage/Characters/" .. c.Name .. " for " .. name .. " - rename it exactly " .. name)
			return rigged(c)
		end
	end
	return nil
end

-- what is in the Characters folder, for messages when something is missing
local function contents()
	local folder = ServerStorage:FindFirstChild("Characters")
	local names = {}
	for _, c in ipairs(folder and folder:GetChildren() or {}) do
		table.insert(names, c.Name .. " (" .. c.ClassName .. ")")
	end
	return #names > 0 and table.concat(names, ", ") or "nothing"
end

-- free or imported models must not run their own code in our game
local function strip(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		end
	end
end

local function fitHeight(model, height)
	local size = model:GetExtentsSize()
	if size.Y > 0.1 then
		model:ScaleTo(model:GetScale() * height / size.Y)
	end
end

function Characters.has(name)
	return template(name) ~= nil
end

-- name is the character's display name, e.g. "Glow"
function Characters.apply(plr, name)
	local t = template(name)
	local old = plr.Character
	if not t then
		if name ~= "Host" then
			warn("No imported " .. name .. ": ServerStorage/Characters has " .. contents() .. ". Keeping the player's own avatar.")
		end
		return false
	end
	if not old then
		return false
	end
	if old:GetAttribute("EscapeCrewChar") == name then
		return true
	end
	local m = t:Clone()
	strip(m)
	local hum = m:FindFirstChildOfClass("Humanoid")
	local hrp = m:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then
		warn("Characters/" .. name .. " needs a Humanoid and a HumanoidRootPart - run Avatar Setup on it in Studio")
		return false
	end
	m.Name = plr.Name
	m.PrimaryPart = hrp
	m:SetAttribute("EscapeCrewChar", name)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
		end
	end
	fitHeight(m, KID_HEIGHT)
	-- keep Roblox's walk/run/jump animations from the avatar
	local animate = old:FindFirstChild("Animate")
	if animate then
		animate:Clone().Parent = m
	end
	local oldRoot = old:FindFirstChild("HumanoidRootPart")
	m:PivotTo(oldRoot and oldRoot.CFrame or CFrame.new(0, 5, 0))
	m.Parent = workspace
	plr.Character = m
	old:Destroy()
	return true
end

-- a fresh copy of the imported host, or nil to use the built-from-parts one
function Characters.host()
	local t = template("Host")
	if not t then
		local folder = ServerStorage:FindFirstChild("Characters")
		local names = {}
		for _, c in ipairs(folder and folder:GetChildren() or {}) do
			table.insert(names, c.Name .. " (" .. c.ClassName .. ")")
		end
		warn("No imported host: ServerStorage/Characters has " .. (#names > 0 and table.concat(names, ", ") or "nothing") .. " - name the host model Host. Using the built host.")
		return nil
	end
	local m = t:Clone()
	strip(m)
	if not m:FindFirstChildOfClass("Humanoid") or not m:FindFirstChild("HumanoidRootPart") then
		warn("Characters/Host needs a Humanoid and a HumanoidRootPart - run Avatar Setup on it in Studio")
		return nil
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
		end
	end
	fitHeight(m, HOST_HEIGHT)
	m.PrimaryPart = m.HumanoidRootPart
	return m
end

return Characters
