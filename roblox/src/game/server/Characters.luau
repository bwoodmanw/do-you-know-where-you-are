--[[
	Characters - swaps a player's avatar for the real Escape Crew character
	when one has been imported into ServerStorage -> Characters (named Glow,
	Tinker, Host, ...). Until a model exists the player keeps their avatar,
	so characters can arrive one at a time.
]]

local ServerStorage = game:GetService("ServerStorage")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

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

-- Meshy faces looked blotchy and their shadows flickered under the rooms'
-- shadow-casting lights: characters cast no shadows (so they cannot darken
-- their own faces), and with FLAT_CHARACTER_SKIN their skin uses only its
-- colour picture, without the bumpy normal map. Both are tried safely.
local function soften(model)
	local skipped = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CastShadow = false
		elseif d:IsA("SurfaceAppearance") and Config.FLAT_CHARACTER_SKIN then
			local part = d.Parent
			if part and part:IsA("MeshPart") then
				local ok = pcall(function()
					local tex = d.ColorMap
					if tex and tex ~= "" then
						part.TextureID = tex
					else
						error("no color map")
					end
				end)
				if ok then
					d:Destroy()
				else
					-- a running game usually cannot read ColorMap: soften it in Studio instead
					skipped += 1
				end
			end
		end
	end
	if skipped > 0 then
		warn("Face softening skipped for " .. (model:GetAttribute("EscapeCrewChar") or model.Name) .. " (" .. skipped .. " parts) - run the Command Bar fix in Studio (TEST_PLAN.md)")
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

-- what is wrong with an imported model that would kill the player (no head,
-- parts not joined to the root, so they fall out of the world), or nil if
-- it is fine. The original imported copy (one mesh, before Avatar Setup)
-- fails here.
function Characters.problem(name)
	local t = template(name)
	if not t then
		return "not in ServerStorage/Characters"
	end
	local hum = t:FindFirstChildOfClass("Humanoid")
	local hrp = t:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then
		return "no Humanoid / HumanoidRootPart (is it the copy Avatar Setup made?)"
	end
	if hum.Health <= 0 then
		return "its Humanoid's Health is 0"
	end
	if not t:FindFirstChild("Head") then
		return "no part named Head"
	end
	-- every part must hang off the root through joints
	local links, parts = {}, {}
	local function link(a, b)
		if a and b then
			links[a] = links[a] or {}
			links[b] = links[b] or {}
			table.insert(links[a], b)
			table.insert(links[b], a)
		end
	end
	for _, d in ipairs(t:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		elseif d:IsA("JointInstance") then
			link(d.Part0, d.Part1)
		elseif d:IsA("WeldConstraint") then
			link(d.Part0, d.Part1)
		end
	end
	local reached, todo = { [hrp] = true }, { hrp }
	while #todo > 0 do
		local p = table.remove(todo)
		for _, q in ipairs(links[p] or {}) do
			if not reached[q] then
				reached[q] = true
				table.insert(todo, q)
			end
		end
	end
	local loose = {}
	for _, p in ipairs(parts) do
		if not reached[p] then
			table.insert(loose, p.Name)
		end
	end
	if #loose > 0 then
		return #loose .. " of " .. #parts .. " parts are not joined to the body (" .. table.concat(loose, ", ", 1, math.min(#loose, 6)) .. ")"
	end
	return nil
end

-- the animation pack for a character's model ("Glow", or a skin's model name)
local function packFor(name)
	local A = Config.ANIM
	if not A then
		return nil
	end
	if A.model[name] then
		return A.packs[A.model[name]]
	end
	for _, s in ipairs(Config.SKILLS) do
		if s.name == name then
			return A.packs[A.skill[s.id] or ""]
		end
	end
	for _, skin in ipairs(Config.SKINS or {}) do
		if skin.model == name then
			return A.packs[A.skill[skin.skill] or ""]
		end
	end
	return nil
end

-- put a pack's animations into a copy of Roblox's R15 Animate script
local function setPack(animate, pack, plain, plainRun)
	if not pack then
		return
	end
	local function set(folder, child, id)
		local f = animate:FindFirstChild(folder)
		local a = f and f:FindFirstChild(child)
		if a and a:IsA("Animation") and id then
			a.AnimationId = "rbxassetid://" .. id
		end
	end
	set("idle", "Animation1", plain and plain.idle or pack.idle)
	set("idle", "Animation2", plain and plain.idle2 or pack.idle2)
	set("walk", "WalkAnim", pack.walk)
	set("run", "RunAnim", plainRun or pack.run)
	set("jump", "JumpAnim", pack.jump)
	set("fall", "FallAnim", pack.fall)
	set("climb", "ClimbAnim", pack.climb)
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
	-- the head is joined (Characters.problem checked), but if its joint is not
	-- called Neck the Humanoid would think it lost its head and die
	local neck = false
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("JointInstance") and d.Name == "Neck" then
			neck = true
		end
	end
	if not neck then
		hum.RequiresNeck = false
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
	-- feet exactly on the floor: the hip height from the model itself, and
	-- only the root collides (limbs scraping the floor made a character shake
	-- as it ran)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d ~= hrp then
			d.CanCollide = false
		end
	end
	local bcf, bsize = m:GetBoundingBox()
	local hip = (hrp.Position.Y - hrp.Size.Y / 2) - (bcf.Position.Y - bsize.Y / 2)
	if hip > 0.1 then
		hum.HipHeight = hip
	end
	soften(m)
	-- Roblox's walk/run/jump script from the avatar, with this character's
	-- own animation pack (Config.ANIM)
	local animate = old:FindFirstChild("Animate")
	if animate then
		animate = animate:Clone()
		local A = require(game:GetService("ReplicatedStorage").Shared.Config).ANIM
		-- the skill this model belongs to (a skin's too), for the plain run
		local skillId
		for _, s in ipairs(Config.SKILLS) do
			if s.name == name then
				skillId = s.id
			end
		end
		for _, skin in ipairs(Config.SKINS or {}) do
			if skin.model == name then
				skillId = skin.skill
			end
		end
		setPack(animate, packFor(name), A and A.plainIdle[name] and A.plain or nil, A and skillId and A.plainRun[skillId] and A.run or nil)
		animate.Parent = m
	end
	-- an Animator made here on the server lets everyone else see this
	-- character's walk and run (without it they glide)
	if not hum:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = hum
	end
	local oldRoot = old:FindFirstChild("HumanoidRootPart")
	m:PivotTo(oldRoot and oldRoot.CFrame or CFrame.new(0, 5, 0))
	m.Parent = workspace
	plr.Character = m
	old:Destroy()
	return true
end

-- a fresh copy of the imported host, or nil to use the built-from-parts one
function Characters.host(name)
	name = name or "Host"
	local t = template(name)
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
