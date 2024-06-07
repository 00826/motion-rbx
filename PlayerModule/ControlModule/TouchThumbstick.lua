--[[

	TouchThumbstick

--]]
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
--[[ Constants ]]--
local TOUCH_CONTROL_SHEET = "rbxasset://textures/ui/TouchControlsSheet.png"
--[[ The Module ]]--
local BaseCharacterController = require(script.Parent:WaitForChild("BaseCharacterController"))
local TouchThumbstick = setmetatable({}, BaseCharacterController)
TouchThumbstick.__index = TouchThumbstick
function TouchThumbstick.new()
	local self = setmetatable(BaseCharacterController.new(), TouchThumbstick)

	self.isFollowStick = false

	self.thumbstickFrame = nil
	self.moveTouchObject = nil
	self.onTouchMovedConn = nil
	self.onTouchEndedConn = nil
	self.screenPos = nil
	self.stickImage = nil
	self.thumbstickSize = nil -- Float

	return self
end
function TouchThumbstick:Enable(enable, uiParentFrame)
	if enable == nil then return false end			-- If nil, return false (invalid argument)
	enable = enable and true or false				-- Force anything non-nil to boolean before comparison
	if self.enabled == enable then return true end	-- If no state change, return true indicating already in requested state

	self.moveVector = Vector3.zero
	self.isJumping = false

	if enable then
		-- Enable
		if not self.thumbstickFrame then
			self:Create(uiParentFrame)
		end
		self.thumbstickFrame.Visible = true
	else
		-- Disable
		self.thumbstickFrame.Visible = false
		self:OnInputEnded()
	end
	self.enabled = enable
end
function TouchThumbstick:OnInputEnded()
	self.thumbstickFrame.Position = self.screenPos
	self.stickImage.Position = UDim2.new(0, self.thumbstickFrame.Size.X.Offset/2 - self.thumbstickSize/4, 0, self.thumbstickFrame.Size.Y.Offset/2 - self.thumbstickSize/4)

	self.moveVector = Vector3.zero
	self.isJumping = false
	self.thumbstickFrame.Position = self.screenPos
	self.moveTouchObject = nil
end
function TouchThumbstick:Create(parentFrame)

	if self.thumbstickFrame then
		self.thumbstickFrame:Destroy()
		self.thumbstickFrame = nil
		if self.onTouchMovedConn then
			self.onTouchMovedConn:Disconnect()
			self.onTouchMovedConn = nil
		end
		if self.onTouchEndedConn then
			self.onTouchEndedConn:Disconnect()
			self.onTouchEndedConn = nil
		end
	end

	local minAxis = math.min(parentFrame.AbsoluteSize.X, parentFrame.AbsoluteSize.Y)
	local isSmallScreen = minAxis <= 500
	self.thumbstickSize = isSmallScreen and 70 or 120
	self.screenPos = isSmallScreen and UDim2.new(0, (self.thumbstickSize/2) - 10, 1, -self.thumbstickSize - 20) or
		UDim2.new(0, self.thumbstickSize/2, 1, -self.thumbstickSize * 1.75)

	self.thumbstickFrame = Instance.new("Frame")
	self.thumbstickFrame.Name = "ThumbstickFrame"
	self.thumbstickFrame.Active = true
	self.thumbstickFrame.Visible = false
	self.thumbstickFrame.Size = UDim2.new(0, self.thumbstickSize, 0, self.thumbstickSize)
	self.thumbstickFrame.Position = self.screenPos
	self.thumbstickFrame.BackgroundTransparency = 1

	local outerImage = Instance.new("ImageLabel")
	outerImage.Name = "OuterImage"
	outerImage.Image = TOUCH_CONTROL_SHEET
	outerImage.ImageRectOffset = Vector2.new()
	outerImage.ImageRectSize = Vector2.new(220, 220)
	outerImage.BackgroundTransparency = 1
	outerImage.Size = UDim2.new(0, self.thumbstickSize, 0, self.thumbstickSize)
	outerImage.Position = UDim2.new(0, 0, 0, 0)
	outerImage.Parent = self.thumbstickFrame

	self.stickImage = Instance.new("ImageLabel")
	self.stickImage.Name = "StickImage"
	self.stickImage.Image = TOUCH_CONTROL_SHEET
	self.stickImage.ImageRectOffset = Vector2.new(220, 0)
	self.stickImage.ImageRectSize = Vector2.new(111, 111)
	self.stickImage.BackgroundTransparency = 1
	self.stickImage.Size = UDim2.new(0, self.thumbstickSize/2, 0, self.thumbstickSize/2)
	self.stickImage.Position = UDim2.new(0, self.thumbstickSize/2 - self.thumbstickSize/4, 0, self.thumbstickSize/2 - self.thumbstickSize/4)
	self.stickImage.ZIndex = 2
	self.stickImage.Parent = self.thumbstickFrame

	local centerPosition = nil
	local deadZone = 0.05

	local function DoMove(direction)

		local currentMoveVector = direction / (self.thumbstickSize/2)

		-- Scaled Radial Dead Zone
		local inputAxisMagnitude = currentMoveVector.Magnitude
		if inputAxisMagnitude < deadZone then
			currentMoveVector = Vector3.zero
		else
			currentMoveVector = currentMoveVector.Unit * ((inputAxisMagnitude - deadZone) / (1 - deadZone))
			-- NOTE: Making currentMoveVector a unit vector will cause the player to instantly go max speed
			-- must check for zero length vector is using unit
			currentMoveVector = Vector3.new(currentMoveVector.X, 0, currentMoveVector.Y)
		end

		self.moveVector = currentMoveVector
	end

	local function MoveStick(pos)
		local relativePosition = Vector2.new(pos.X - centerPosition.X, pos.Y - centerPosition.Y)
		local length = relativePosition.Magnitude
		local maxLength = self.thumbstickFrame.AbsoluteSize.X/2
		if self.isFollowStick and length > maxLength then
			local offset = relativePosition.Unit * maxLength
			self.thumbstickFrame.Position = UDim2.new(
				0, pos.X - self.thumbstickFrame.AbsoluteSize.X/2 - offset.X,
				0, pos.Y - self.thumbstickFrame.AbsoluteSize.Y/2 - offset.Y)
		else
			length = math.min(length, maxLength)
			relativePosition = relativePosition.Unit * length
		end
		self.stickImage.Position = UDim2.new(0, relativePosition.X + self.stickImage.AbsoluteSize.X/2, 0, relativePosition.Y + self.stickImage.AbsoluteSize.Y/2)
	end

	-- input connections
	self.thumbstickFrame.InputBegan:Connect(function(inputObject)
		--A touch that starts elsewhere on the screen will be sent to a frame's InputBegan event
		--if it moves over the frame. So we check that this is actually a new touch (inputObject.UserInputState ~= Enum.UserInputState.Begin)
		if self.moveTouchObject or inputObject.UserInputType ~= Enum.UserInputType.Touch
			or inputObject.UserInputState ~= Enum.UserInputState.Begin then
			return
		end

		self.moveTouchObject = inputObject
		self.thumbstickFrame.Position = UDim2.new(0, inputObject.Position.X - self.thumbstickFrame.Size.X.Offset/2, 0, inputObject.Position.Y - self.thumbstickFrame.Size.Y.Offset/2)
		centerPosition = Vector2.new(self.thumbstickFrame.AbsolutePosition.X + self.thumbstickFrame.AbsoluteSize.X/2,
			self.thumbstickFrame.AbsolutePosition.Y + self.thumbstickFrame.AbsoluteSize.Y/2)
		local direction = Vector2.new(inputObject.Position.X - centerPosition.X, inputObject.Position.Y - centerPosition.Y)
	end)

	self.onTouchMovedConn = UserInputService.TouchMoved:Connect(function(inputObject, isProcessed)
		if inputObject == self.moveTouchObject then
			centerPosition = Vector2.new(self.thumbstickFrame.AbsolutePosition.X + self.thumbstickFrame.AbsoluteSize.X/2,
				self.thumbstickFrame.AbsolutePosition.Y + self.thumbstickFrame.AbsoluteSize.Y/2)
			local direction = Vector2.new(inputObject.Position.X - centerPosition.X, inputObject.Position.Y - centerPosition.Y)
			DoMove(direction)
			MoveStick(inputObject.Position)
		end
	end)

	self.onTouchEndedConn = UserInputService.TouchEnded:Connect(function(inputObject, isProcessed)
		if inputObject == self.moveTouchObject then
			self:OnInputEnded()
		end
	end)

	GuiService.MenuOpened:Connect(function()
		if self.moveTouchObject then
			self:OnInputEnded()
		end
	end)

	self.thumbstickFrame.Parent = parentFrame
end
return TouchThumbstick