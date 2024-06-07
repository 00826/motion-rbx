--[[
	LegacyCamera - Implements legacy controller types: Attach, Fixed, Watch
--]]

-- Local private variables and constants
--local UNIT_X = Vector3.xAxis
--local UNIT_Y = Vector3.yAxis
--local UNIT_Z = Vector3.zAxis
--local X1_Y0_Z1 = Vector3.new(1, 0, 1)	--Note: not a unit vector, used for projecting onto XZ plane

--local VR_PITCH_FRACTION = 0.25
--local tweenAcceleration = math.rad(220)		--Radians/Second^2
--local tweenSpeed = math.rad(0)				--Radians/Second
--local tweenMaxSpeed = math.rad(250)			--Radians/Second
--local TIME_BEFORE_AUTO_ROTATE = 2.0 		--Seconds, used when auto-aligning camera with vehicles
--local PORTRAIT_OFFSET = Vector3.new(0,-3,0)

local Util = require(script.Parent:WaitForChild("CameraUtils"))

--[[ Services ]]--
local PlayersService = game:GetService("Players")
--local VRService = game:GetService("VRService")

--[[ The Module ]]--
local BaseCamera = require(script.Parent:WaitForChild("BaseCamera"))
local LegacyCamera = setmetatable({}, BaseCamera)
LegacyCamera.__index = LegacyCamera

function LegacyCamera.new()
	local self = setmetatable(BaseCamera.new(), LegacyCamera)

	self.cameraType = Enum.CameraType.Fixed
	self.lastUpdate = tick()
	self.lastDistanceToSubject = nil

	return self
end

function LegacyCamera:GetModuleName()
	return "LegacyCamera"
end

function LegacyCamera:Test()
	print("LegacyCamera:Test()")
end

--[[ Functions overridden from BaseCamera ]]--
function LegacyCamera:SetCameraToSubjectDistance(desiredSubjectDistance)
	return BaseCamera.SetCameraToSubjectDistance(self,desiredSubjectDistance)
end

function LegacyCamera:Update(dt)

	-- Cannot update until cameraType has been set
	if not self.cameraType then return end

	local now = tick()
	local timeDelta = (now - self.lastUpdate)
	local camera = 	workspace.CurrentCamera
	local newCameraCFrame = camera.CFrame
	local newCameraFocus = camera.Focus
	local player = PlayersService.LocalPlayer
	local humanoid = self:GetHumanoid()
	local cameraSubject = camera and camera.CameraSubject
	local isInVehicle = cameraSubject and cameraSubject:IsA("VehicleSeat")
	local isOnASkateboard = cameraSubject and cameraSubject:IsA("SkateboardPlatform")
	local isClimbing = humanoid and humanoid:GetState() == Enum.HumanoidStateType.Climbing

	if self.lastUpdate == nil or timeDelta > 1 then
		self.lastDistanceToSubject = nil
	end
	local subjectPosition = self:GetSubjectPosition()

	if self.cameraType == Enum.CameraType.Fixed then
		if self.lastUpdate then
			-- Cap out the delta to 0.1 so we don't get some crazy things when we re-resume from
			local delta = math.min(0.1, now - self.lastUpdate)
			local gamepadRotation = self:UpdateGamepad()
			self.rotateInput = self.rotateInput + (gamepadRotation * delta)
		end

		if subjectPosition and player and camera then
			local distanceToSubject = self:GetCameraToSubjectDistance()
			local newLookVector = self:CalculateNewLookVector()
			self.rotateInput = Vector2.zero

			newCameraFocus = camera.Focus -- Fixed camera does not change focus
			newCameraCFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + (distanceToSubject * newLookVector))
		end
	elseif self.cameraType == Enum.CameraType.Attach then
		if subjectPosition and camera then
			local distanceToSubject = self:GetCameraToSubjectDistance()
			local humanoid = self:GetHumanoid()
			if self.lastUpdate and humanoid and humanoid.RootPart then

				-- Cap out the delta to 0.1 so we don't get some crazy things when we re-resume from
				local delta = math.min(0.1, now - self.lastUpdate)
				local gamepadRotation = self:UpdateGamepad()
				self.rotateInput = self.rotateInput + (gamepadRotation * delta)

				local forwardVector = humanoid.RootPart.CFrame.LookVector

				local y = Util.GetAngleBetweenXZVectors(forwardVector, self:GetCameraLookVector())
				if Util.IsFinite(y) then
					-- Preserve vertical rotation from user input
					self.rotateInput = Vector2.new(y, self.rotateInput.Y)
				end
			end

			local newLookVector = self:CalculateNewLookVector()
			self.rotateInput = Vector2.zero

			newCameraFocus = CFrame.new(subjectPosition)
			newCameraCFrame = CFrame.new(subjectPosition - (distanceToSubject * newLookVector), subjectPosition)
		end
	elseif self.cameraType == Enum.CameraType.Watch then
		if subjectPosition and player and camera then
			local cameraLook = nil

			local humanoid = self:GetHumanoid()
			if humanoid and humanoid.RootPart then
				local diffVector = subjectPosition - camera.CFrame.Position
				cameraLook = diffVector.Unit

				if self.lastDistanceToSubject and self.lastDistanceToSubject == self:GetCameraToSubjectDistance() then
					-- Don't clobber the zoom if they zoomed the camera
					local newDistanceToSubject = diffVector.Magnitude
					self:SetCameraToSubjectDistance(newDistanceToSubject)
				end
			end

			local distanceToSubject = self:GetCameraToSubjectDistance()
			local newLookVector = self:CalculateNewLookVector(cameraLook)
			self.rotateInput = Vector2.zero

			newCameraFocus = CFrame.new(subjectPosition)
			newCameraCFrame = CFrame.new(subjectPosition - (distanceToSubject * newLookVector), subjectPosition)

			self.lastDistanceToSubject = distanceToSubject
		end
	else
		-- Unsupported type, return current values unchanged
		return camera.CFrame, camera.Focus
	end

	self.lastUpdate = now
	return newCameraCFrame, newCameraFocus
end

return LegacyCamera
