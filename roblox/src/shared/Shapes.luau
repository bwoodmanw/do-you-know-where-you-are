--[[
	Shapes - Roblox keeps a Ball part a perfect sphere: give it a stretched
	size and it squashes back to a round ball (10 Oct: the shark's long body
	came out a small ball and its tail and fins floated free; plushies looked
	like blobs). Shapes.fix turns a stretched ball into a block with a sphere
	mesh, which stretches to any size - an egg, a fish body, a muzzle.

	Call it after setting a part's properties, with the shape and size you
	meant: Shapes.fix(part, Enum.PartType.Ball, Vector3.new(1.8, 1.7, 6)).
	Round balls are left alone.
]]

local Shapes = {}

function Shapes.fix(p, shape, size)
	if shape ~= Enum.PartType.Ball or typeof(size) ~= "Vector3" then
		return p
	end
	if math.abs(size.X - size.Y) < 0.01 and math.abs(size.Y - size.Z) < 0.01 then
		return p -- a round ball: fine as it is
	end
	p.Shape = Enum.PartType.Block
	p.Size = size
	local mesh = p:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

return Shapes
