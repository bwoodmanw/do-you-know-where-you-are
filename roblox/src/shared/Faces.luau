--[[
	Faces - a crisp face laid on a toon's head. Stable Fast 3D gives a toon's
	face only ~50 x 50 texture pixels (blurry eyes, Echo 10 Oct); the face is
	cut from the approved picture instead (tools/make_face.py) and laid on the
	head as a Texture that follows the head's shape.

	Config.FACES[modelName] = { id = <image id>, top = .., left = .., size = .. }
	  top   the face's middle, below the top of the model, in model heights
	  left  across, in model heights (0 = the middle of the head)
	  size  the face picture's square, in model heights

	Faces.add(model, modelName)   after the model is sized (game, game card,
	                              Lobby preview). Does nothing without an entry.
]]

local Config = require(script.Parent.Config)

local Faces = {}

local function say(text)
	if game:GetService("RunService"):IsStudio() then
		print("[Faces] " .. text)
	end
end

function Faces.add(model, name)
	local f = Config.FACES and Config.FACES[name]
	if not f or (f.id or 0) <= 0 then
		return -- this model has no crisp face (yet)
	end
	local head = model:FindFirstChild("Head")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not head or not head:IsA("BasePart") then
		return say(name .. ": no part named Head (" .. (head and head.ClassName or "none") .. ")")
	end
	if not root then
		return say(name .. ": no HumanoidRootPart")
	end
	if head:FindFirstChild("ToonFace") then
		return
	end
	local box, size = model:GetBoundingBox()
	local up = root.CFrame.UpVector
	local forward = root.CFrame.LookVector
	local right = root.CFrame.RightVector
	local h = size.Y
	-- the face's middle, in the world: down from the top of the model
	local topCenter = box.Position + up * (size.Y / 2)
	local headMid = topCenter + right * (head.Position - topCenter):Dot(right)
	local center = headMid - up * (f.top * h) + right * ((f.left or 0) * h)
	-- the side of the head that faces forward
	local best, bestDot = nil, -2
	for _, normal in ipairs(Enum.NormalId:GetEnumItems()) do
		local n = head.CFrame:VectorToWorldSpace(Vector3.FromNormalId(normal))
		local d = n:Dot(forward)
		if d > bestDot then
			best, bestDot = normal, d
		end
	end
	-- across and down that side, as seen by someone facing the character
	local p = head.CFrame:PointToObjectSpace(center)
	local nLocal = Vector3.FromNormalId(best)
	local upLocal = head.CFrame:VectorToObjectSpace(up)
	local acrossLocal = (-nLocal):Cross(upLocal).Unit -- the viewer's right
	local half = head.Size / 2
	local halfAcross = math.abs(acrossLocal.X) * half.X + math.abs(acrossLocal.Y) * half.Y + math.abs(acrossLocal.Z) * half.Z
	local halfUp = math.abs(upLocal.X) * half.X + math.abs(upLocal.Y) * half.Y + math.abs(upLocal.Z) * half.Z
	local u = p:Dot(acrossLocal) + halfAcross -- from the side's left edge
	local v = halfUp - p:Dot(upLocal) -- from its top edge
	local tile = f.size * h
	local t = Instance.new("Texture")
	t.Name = "ToonFace"
	t.Texture = "rbxassetid://" .. f.id
	t.Face = best
	t.StudsPerTileU, t.StudsPerTileV = tile, tile
	-- the tile's top-left corner, so the face's middle lands on (u, v); the
	-- picture is transparent round the face, so the repeats show nothing
	t.OffsetStudsU = (Config.FACE_FLIP_U and -1 or 1) * (u - tile / 2)
	t.OffsetStudsV = (Config.FACE_FLIP_V and -1 or 1) * (v - tile / 2)
	t.Parent = head
	if game:GetService("RunService"):IsStudio() then
		-- for checking the placement while the faces are new (Output)
		print(string.format("[Faces] %s: face on the head's %s side, middle at %.2f across / %.2f down (head %.2f x %.2f studs), picture square %.2f studs, offsets %.2f / %.2f; head is a %s%s",
			name, best.Name, u, v, halfAcross * 2, halfUp * 2, tile, t.OffsetStudsU, t.OffsetStudsV, head.ClassName,
			head:FindFirstChildOfClass("SurfaceAppearance") and " with a SurfaceAppearance" or ""))
	end
end

-- Faces.add with any error said in Output (the callers used to hide it)
function Faces.try(model, name)
	local ok, err = pcall(Faces.add, model, name)
	if not ok then
		warn("[Faces] " .. tostring(name) .. " failed: " .. tostring(err))
	end
end

return Faces
