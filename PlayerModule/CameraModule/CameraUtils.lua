--[[
	CameraUtils - Math utility functions shared by multiple camera scripts
--]]

local ForkSettings = require(script.Parent.Parent.Settings)

local CameraUtils = {}

local FFlagUserCameraToggle do
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserCameraToggle")
	end)
	FFlagUserCameraToggle = success and result
end

-- map a value from one range to another
function CameraUtils.map(x, inMin, inMax, outMin, outMax)
	return (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
end

-- Note, arguments do not match the new math.clamp
-- Eventually we will replace these calls with math.clamp, but right now
-- this is safer as math.clamp is not tolerant of min>max
function CameraUtils.Clamp(low, high, val)
	return math.min(math.max(val, low), high)
end

-- From TransparencyController
function CameraUtils.Round(num, places)
	local decimalPivot = 10^places
	return math.floor(num * decimalPivot + 0.5) / decimalPivot
end

function CameraUtils.IsFinite(val)
	return val == val and val ~= math.huge and val ~= -math.huge
end

function CameraUtils.IsFiniteVector3(vec3)
	return CameraUtils.IsFinite(vec3.X) and CameraUtils.IsFinite(vec3.Y) and CameraUtils.IsFinite(vec3.Z)
end

-- Legacy implementation renamed

function CameraUtils.GetAngleBetweenXZVectors(v1, v2)
	return math.atan2(v2.X * v1.Z - v2.Z * v1.X, v2.X * v1.X + v2.Z * v1.Z)
end

function CameraUtils.RotateVectorByAngleAndRound(camLook, rotateAngle, roundAmount)
	if camLook.Magnitude > 0 then
		camLook = camLook.Unit
		local currAngle = math.atan2(camLook.Z, camLook.X)
		local newAngle = math.round((math.atan2(camLook.Z, camLook.X) + rotateAngle) / roundAmount) * roundAmount
		return newAngle - currAngle
	end
	return 0
end

-- K is a tunable parameter that changes the shape of the S-curve
-- the larger K is the more straight/linear the curve gets

local lowerK = 0.8

local function SCurveTranform(t)
	t = CameraUtils.Clamp(-1, 1, t)
	if t >= 0 then
		local k = ForkSettings.GamepadCurve
		return (k * t) / (k - t + 1)
	end
	return -((lowerK * -t) / (lowerK + t + 1))
end

local function toSCurveSpace(t)
	local DEADZONE = ForkSettings.GamepadDeadzone
	return (1 + DEADZONE) * (2*math.abs(t) - 1) - DEADZONE
end

local function fromSCurveSpace(t)
	return t/2 + 0.5
end

function CameraUtils.GamepadLinearToCurve(thumbstickPosition)
	local function onAxis(axisValue)
		local sign = 1
		if axisValue < 0 then
			sign = -1
		end
		local point = fromSCurveSpace(SCurveTranform(toSCurveSpace(math.abs(axisValue))))
		point = point * sign
		return CameraUtils.Clamp(-1, 1, point)
	end
	return Vector2.new(onAxis(thumbstickPosition.X), onAxis(thumbstickPosition.Y))
end

-- This function converts 4 different, redundant enumeration types to one standard so the values can be compared
function CameraUtils.ConvertCameraModeEnumToStandard(enumValue)
	if enumValue == Enum.TouchCameraMovementMode.Default then
		return Enum.ComputerCameraMovementMode.Follow
	end

	if enumValue == Enum.ComputerCameraMovementMode.Default then
		return Enum.ComputerCameraMovementMode.Classic
	end

	if enumValue == Enum.TouchCameraMovementMode.Classic or
		enumValue == Enum.DevTouchCameraMovementMode.Classic or
		enumValue == Enum.DevComputerCameraMovementMode.Classic or
		enumValue == Enum.ComputerCameraMovementMode.Classic then
		return Enum.ComputerCameraMovementMode.Classic
	end

	if enumValue == Enum.TouchCameraMovementMode.Follow or
		enumValue == Enum.DevTouchCameraMovementMode.Follow or
		enumValue == Enum.DevComputerCameraMovementMode.Follow or
		enumValue == Enum.ComputerCameraMovementMode.Follow then
		return Enum.ComputerCameraMovementMode.Follow
	end

	if enumValue == Enum.TouchCameraMovementMode.Orbital or
		enumValue == Enum.DevTouchCameraMovementMode.Orbital or
		enumValue == Enum.DevComputerCameraMovementMode.Orbital or
		enumValue == Enum.ComputerCameraMovementMode.Orbital then
		return Enum.ComputerCameraMovementMode.Orbital
	end

	if FFlagUserCameraToggle then
		if enumValue == Enum.ComputerCameraMovementMode.CameraToggle or
			enumValue == Enum.DevComputerCameraMovementMode.CameraToggle then
			return Enum.ComputerCameraMovementMode.CameraToggle
		end
	end

	-- Note: Only the Dev versions of the Enums have UserChoice as an option
	if enumValue == Enum.DevTouchCameraMovementMode.UserChoice or
		enumValue == Enum.DevComputerCameraMovementMode.UserChoice then
		return Enum.DevComputerCameraMovementMode.UserChoice
	end

	-- For any unmapped options return Classic camera
	return Enum.ComputerCameraMovementMode.Classic
end

return CameraUtils