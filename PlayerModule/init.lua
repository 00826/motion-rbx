--[[
	PlayerModule - This module requires and instantiates the camera and control modules,
	and provides getters for developers to access methods on these singletons without
	having to modify Roblox-supplied scripts.

	2018 PlayerScripts Update - AllYourBlox

	Forked PlayerModule before roblox babyproofed the shiftlock & camera API (i think around january 2019/20-ish?)
	This fork was made to:
		correct deprecated code
		optimize currently existing code
		make certain settings more easily accessible

	... "all while avoiding a full recarpeting of the floor" ~sun tzu

	2024 PlayerModule Fork - overflowed
--]]

local PlayerModule = {}
PlayerModule.__index = PlayerModule

function PlayerModule.new()
	local self = setmetatable({}, PlayerModule)
	self.cameras = require(script:WaitForChild("CameraModule"))
	self.controls = require(script:WaitForChild("ControlModule"))
	self.Raycast = require(script:WaitForChild("Raycast"))
	self.Settings = require(script:WaitForChild("Settings"))
	return self
end

function PlayerModule:IsMouseLocked(): boolean
	local Cameras = self:GetCameras()
	if not Cameras then return false end

	local MouseLockController = Cameras.activeMouseLockController
	if not MouseLockController then return false end

	return MouseLockController.isMouseLocked
end

function PlayerModule:ShiftlockToggled(f: (State: boolean) -> ())
	local Cameras = self:GetCameras()
	local MouseLockController = Cameras.activeMouseLockController

	MouseLockController:GetBindableToggleEvent():Connect(function()
		f(MouseLockController.isMouseLocked)
	end)
end

function PlayerModule:SetShiftlock(State: boolean): boolean?
	local Cameras = self:GetCameras()
	if not Cameras then return false end

	local CameraController = Cameras.activeCameraController
	local MouseLockController = Cameras.activeMouseLockController

	if not CameraController then return false end
	if not MouseLockController then return false end

	if MouseLockController.isMouseLocked == State then return false end

	if State == true then
		MouseLockController:OnMouseLockToggled()
		CameraController:SetIsMouseLocked(true)
	else
		if MouseLockController:GetIsMouseLocked() then
			MouseLockController:OnMouseLockToggled()
			CameraController:SetIsMouseLocked(false)
			return true
		end
	end
	return false
end

function PlayerModule:GetCameras()
	return self.cameras
end

function PlayerModule:GetControls()
	return self.controls
end

function PlayerModule:GetRaycast()
	return self.Raycast
end

function PlayerModule:GetSettings()
	return self.Settings
end

function PlayerModule:GetClickToMoveController()
	return self.controls:GetClickToMoveController()
end

return PlayerModule.new()
