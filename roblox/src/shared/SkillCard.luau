-- SkillCard: a character's skills as a list, one row per skill, each with a
-- colored tag that says how it works (4 Nov, Brent: one text size for every
-- character, and clear which skills are passive and which need a key):
--   ALWAYS ON (green)  - passive, nothing to press
--   HOLD E    (blue)   - hold the key at something in the house
--   PRESS R   (orange) - the skill button; it recharges
-- Used by the Lobby's Characters screen and the game's character picker.
-- The words come from Config.SKILL_INFO[id].parts.
local UserInputService = game:GetService("UserInputService")

local Config = require(script.Parent.Config)

local SkillCard = {}

SkillCard.KINDS = {
	passive = { color = Color3.fromRGB(46, 140, 72), icon = "\u{2728}" },
	hold = { color = Color3.fromRGB(48, 108, 196), icon = "\u{270B}" },
	press = { color = Color3.fromRGB(222, 112, 26), icon = "\u{1F518}" },
}

-- the tag's words: the key on a keyboard, the button on a phone or controller
function SkillCard.tag(part)
	local keys = UserInputService.KeyboardEnabled
	if part.kind == "passive" then
		return "ALWAYS ON"
	elseif part.kind == "hold" then
		return keys and ("HOLD " .. (part.key or "E")) or "HOLD"
	end
	return keys and ("PRESS " .. (part.key or "R")) or "SKILL BUTTON"
end

local function clear(list)
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- a scrolling list to fill: size, position, layer, text size, font
function SkillCard.list(parent, size, pos, z, textSize, font)
	local s = Instance.new("ScrollingFrame")
	s.Size = size
	s.Position = pos
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ZIndex = z
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	s.CanvasSize = UDim2.new(0, 0, 0, 0)
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = Color3.fromRGB(255, 138, 31)
	s:SetAttribute("TextSize", textSize)
	s:SetAttribute("Font", font.Name)
	local lay = Instance.new("UIListLayout")
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 6)
	lay.Parent = s
	s.Parent = parent
	return s
end

-- fill the list with one character's skills; extra[i] is added to part i
-- (the game names this floor's room for the invitation, paint and plant)
function SkillCard.fill(list, skillId, extra)
	clear(list)
	list.CanvasPosition = Vector2.zero
	local info = Config.SKILL_INFO[skillId]
	local parts = info and info.parts or {}
	local size = list:GetAttribute("TextSize") or 16
	local font = (Enum.Font :: any)[list:GetAttribute("Font") or "SourceSans"] or Enum.Font.SourceSans
	local z = list.ZIndex
	for i, part in ipairs(parts) do
		local kind = SkillCard.KINDS[part.kind] or SkillCard.KINDS.press
		local row = Instance.new("Frame")
		row.Name = "Skill" .. i
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -10, 0, 0)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.BackgroundColor3 = kind.color
		row.BackgroundTransparency = 0.82
		row.BorderSizePixel = 0
		row.ZIndex = z
		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 8)
		rc.Parent = row
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 4)
		pad.PaddingBottom = UDim.new(0, 5)
		pad.PaddingLeft = UDim.new(0, 6)
		pad.PaddingRight = UDim.new(0, 6)
		pad.Parent = row
		-- the tag: same width on every row, so the words line up
		local chip = Instance.new("TextLabel")
		chip.Name = "Tag"
		chip.Size = UDim2.fromOffset(108, size + 8)
		chip.BackgroundColor3 = kind.color
		chip.BorderSizePixel = 0
		chip.Font = Enum.Font.GothamBold
		chip.TextSize = math.max(11, size - 4)
		chip.TextColor3 = Color3.new(1, 1, 1)
		chip.Text = SkillCard.tag(part)
		chip.ZIndex = z + 1
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 6)
		cc.Parent = chip
		chip.Parent = row
		local words = Instance.new("TextLabel")
		words.Name = "Words"
		words.BackgroundTransparency = 1
		words.Position = UDim2.fromOffset(116, 2)
		words.Size = UDim2.new(1, -116, 0, 0)
		words.AutomaticSize = Enum.AutomaticSize.Y
		words.Font = font
		words.TextSize = size
		words.TextScaled = false
		words.TextWrapped = true
		words.RichText = true
		words.TextXAlignment = Enum.TextXAlignment.Left
		words.TextYAlignment = Enum.TextYAlignment.Top
		words.TextColor3 = Color3.fromRGB(255, 244, 222)
		local text = part.text .. ((extra and extra[i]) and (" " .. extra[i]) or "")
		words.Text = "<b>" .. part.name .. "</b> - " .. text
		words.ZIndex = z + 1
		words.Parent = row
		row.Parent = list
	end
end

return SkillCard
