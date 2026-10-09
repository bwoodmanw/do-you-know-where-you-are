--[[
	Haptics (client) - a short rumble on a controller (and on phones and
	tablets that Roblox lets vibrate): caught, a Ground Pound nearby, the
	host spotting you, a pumpkin hit, FRENZY. Anything not supported is
	skipped quietly.
]]

local HapticService = game:GetService("HapticService")

local Haptics = {}

local TYPES = { Enum.UserInputType.Gamepad1, Enum.UserInputType.Touch }
local MOTORS = { Enum.VibrationMotor.Large, Enum.VibrationMotor.Small }
local token = 0

local function set(strength)
	for _, t in ipairs(TYPES) do
		pcall(function()
			if HapticService:IsVibrationSupported(t) then
				for _, m in ipairs(MOTORS) do
					if HapticService:IsMotorSupported(t, m) then
						HapticService:SetMotor(t, m, strength)
					end
				end
			end
		end)
	end
end

-- strength 0..1 for `seconds`
function Haptics.buzz(strength, seconds)
	token += 1
	local mine = token
	set(math.clamp(strength or 0.5, 0, 1))
	task.delay(seconds or 0.3, function()
		if token == mine then
			set(0)
		end
	end)
end

return Haptics
