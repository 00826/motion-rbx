--!strict

local RunService				= game:GetService("RunService")
local IsServer					= RunService:IsServer()

local Players					= game:GetService("Players")

local ApplyPosition				= require(script:WaitForChild("ApplyPosition"))
local ApplyVelocity				= require(script:WaitForChild("ApplyVelocity"))
local Raycast					= require(script:WaitForChild("Raycast"))

local ForceRotateRemote			= script:WaitForChild("ForceRotate")
local ReplicateRemote			= script:WaitForChild("Replicate")
local ReplicateClock			= 1 / 45

local Vector3_xzAxis			= Vector3.one - Vector3.yAxis

local States					= table.freeze{
	Base				= require(script.State_Base);
	Vectors				= require(script.State_Vectors);

	Speed				= require(script.State_Speed);
	Jump				= require(script.State_Jump);
	Rotate				= require(script.State_Rotate);

	JumpAux				= require(script.State_JumpAux);
	Crouch				= require(script.State_Crouch);
	Slide				= require(script.State_Slide);
	Dash				= require(script.State_Dash);
	Swim				= require(script.State_Swim);
	Fly					= require(script.State_Fly);
}

local AuxStates				= {
	[0]					= "None";
	[1]					= "JumpAux";
	[2]					= "Crouch";
	[3]					= "Slide";
	[4]					= "Dash";
	[5]					= "Swim";
	[6]					= "Fly";
}

local SwimVolumes			= table.create(4) :: { {CFrame | Vector3} } -- CFrame, Size = T[n][1], T[n][2]

local function lerp(x: number, y: number, a: number): number
	return (1 - a) * x + a * y;
end

local Motion = { __index = {} }

function Motion.Create()
	local MObject = setmetatable({
		Base			= States.Base.Create();
		Vectors			= States.Vectors.Create();

		Speed			= States.Speed.Create();
		Jump			= States.Jump.Create();
		Rotate			= States.Rotate.Create();

		JumpAux			= States.JumpAux.Create();
		Crouch			= States.Crouch.Create();
		Slide			= States.Slide.Create();
		Dash			= States.Dash.Create();
		Swim			= States.Swim.Create();
		Fly				= States.Fly.Create();

		Rig				= nil :: Model?;
		RootPart		= nil :: BasePart?;
		Humanoid		= nil :: Humanoid?;
		Camera			= nil :: Camera?;
		LastNonZero		= Vector3.zero :: Vector3?;

		Movers			= {} :: {[string]: BodyMover};

		Blacklist		= table.create(4);

		R				= nil :: ((Rig: Model, StateId: number, StateActive: boolean) -> ())?
	}, Motion)
	return MObject
end

function Motion.__index:Init(Rig: Model, GetMousePosition: () -> Vector3, GetMoveVector: () -> Vector3)
	local RootPart = Rig.PrimaryPart or Rig:WaitForChild("HumanoidRootPart")
	assert(RootPart:IsA("BasePart"))
	local Humanoid = Rig:FindFirstChildOfClass("Humanoid") or Rig:WaitForChild("Humanoid")
	assert(Humanoid:IsA("Humanoid"))

	self.Rig = Rig
	self.RootPart = RootPart
	self.Humanoid = Humanoid
	self.Camera = workspace.CurrentCamera
	self.Camera.FieldOfView = buffer.readu8(self.Speed, 27)

	table.insert(self.Blacklist, Rig)

	Humanoid.WalkSpeed = buffer.readu16(self.Speed, 0) * (buffer.readu16(self.Speed, 4) / 100)
	Humanoid.JumpPower = buffer.readu16(self.Jump, 0)
	Humanoid.UseJumpPower = true
	Humanoid.BreakJointsOnDeath = false

	Motion.Optimize(Humanoid)

	---@diagnostic disable-next-line: undefined-type
	local C = ForceRotateRemote.OnClientEvent:Connect(function(fBuffer: buffer)
		self:OnForceRotateRecv(fBuffer)
	end)

	Humanoid.Died:Once(function()
		RunService:UnbindFromRenderStep("MotionStep")
		self:ClearMovers()
		C:Disconnect()
	end)

	RunService:UnbindFromRenderStep("MotionStep")
	RunService:BindToRenderStep("MotionStep", Enum.RenderPriority.Character.Value + 1, function(dt: number)
		local CameraCFrame = self.Camera.CFrame
		local Vectors = self.Vectors
		do
			local Offset, V = 0, GetMoveVector()
			buffer.writef32(Vectors, Offset + 0, V.X); buffer.writef32(Vectors, Offset + 4, V.Y); buffer.writef32(Vectors, Offset + 8, V.Z)
		end
		do
			local Offset, V = 24, CameraCFrame.LookVector
			buffer.writef32(Vectors, Offset + 0, V.X); buffer.writef32(Vectors, Offset + 4, V.Y); buffer.writef32(Vectors, Offset + 8, V.Z)
		end
		do
			local Offset, V = 36, CameraCFrame.Position
			buffer.writef32(Vectors, Offset + 0, V.X); buffer.writef32(Vectors, Offset + 4, V.Y); buffer.writef32(Vectors, Offset + 8, V.Z)
		end
		do
			local Offset, V = 48, GetMousePosition()
			buffer.writef32(Vectors, Offset + 0, V.X); buffer.writef32(Vectors, Offset + 4, V.Y); buffer.writef32(Vectors, Offset + 8, V.Z)
		end
		do
			local Offset, V = 60, self:GetFloorNormal()
			buffer.writef32(Vectors, Offset + 0, V.X); buffer.writef32(Vectors, Offset + 4, V.Y); buffer.writef32(Vectors, Offset + 8, V.Z)
		end

		self:Update(dt)
	end)
end

function Motion.__index:Update(dt: number)
	local Now = os.clock()

	local BaseState = self.Base
	local MoveState = buffer.readu8(BaseState, 0)
	local AuxState = buffer.readu8(BaseState, 1)
	local SlowState = buffer.readu8(BaseState, 2)
	local SprintInput = buffer.readu8(BaseState, 3) == 1
	local DownInput = buffer.readu8(BaseState, 4) == 1
	local UpInput = buffer.readu8(BaseState, 5) == 1

	local Vectors = self.Vectors
	local MoveVector = Vector3.new(buffer.readf32(Vectors, 0), buffer.readf32(Vectors, 4), buffer.readf32(Vectors, 8))
	local UpVector = Vector3.new(buffer.readf32(Vectors, 12), buffer.readf32(Vectors, 16), buffer.readf32(Vectors, 20))
	local CamVector = Vector3.new(buffer.readf32(Vectors, 24), buffer.readf32(Vectors, 28), buffer.readf32(Vectors, 32))
	local CamPosition = Vector3.new(buffer.readf32(Vectors, 36), buffer.readf32(Vectors, 40), buffer.readf32(Vectors, 44))
	local MousePosition = Vector3.new(buffer.readf32(Vectors, 48), buffer.readf32(Vectors, 52), buffer.readf32(Vectors, 56))
	local FloorVector = Vector3.new(buffer.readf32(Vectors, 60), buffer.readf32(Vectors, 64), buffer.readf32(Vectors, 68))
	local PreJumpCamVector = Vector3.new(buffer.readf32(Vectors, 72), buffer.readf32(Vectors, 76), buffer.readf32(Vectors, 80))

	local SpeedState = self.Speed
	local BaseSpeed = buffer.readu16(SpeedState, 0)
	local SprintSpeed = buffer.readu16(SpeedState, 2)
	local BaseScalar = buffer.readu16(SpeedState, 4)
	local AirScalar = buffer.readu16(SpeedState, 6)
	local SlowScalar = buffer.readu16(SpeedState, 8)
	local SprintCooldown = buffer.readu16(SpeedState, 10)
	local SprintEnd = buffer.readf32(SpeedState, 12)
	local DecayTime = buffer.readu16(SpeedState, 16)
	local DecayStart = buffer.readf32(SpeedState, 18)
	local DecayDot = buffer.readi16(SpeedState, 22)
	local AirControlMode = buffer.readu8(SpeedState, 26)
	local BaseFOV = buffer.readu8(SpeedState, 27)
	local SprintFOV = buffer.readu8(SpeedState, 28)
	local SlowFOV = buffer.readu8(SpeedState, 29)

	local JumpState = self.Jump
	local RotateState = self.Rotate
	local JumpAuxState = self.JumpAux
	local CrouchState = self.Crouch
	local SlideState = self.Slide
	local DashState = self.Dash
	local FlyState = self.Fly
	local SwimState = self.Swim

	local Camera = self.Camera :: Camera
	local RootPart = self.RootPart :: BasePart
	local RootCFrame = RootPart.CFrame
	local Humanoid = self.Humanoid :: Humanoid
	local IsInAir = Humanoid.FloorMaterial == Enum.Material.Air
	local IsInputStopped = MoveVector.Magnitude == 0
	local TargetWalkSpeed = BaseSpeed
	local TargetScalar = 100

	if (not IsInAir)
	and (not IsInputStopped)
	then
		self.LastNonZero = Camera.CFrame:VectorToWorldSpace(MoveVector)
	end

	if Humanoid.Sit == true then
		if UpInput then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		else
			Humanoid:Move(MoveVector)
		end
		return
	end

	if SlowState == 0 then
		TargetScalar = BaseScalar
	elseif SlowState == 1 then
		TargetScalar = SlowScalar
		self:AdjustCameraFOV(SlowFOV, dt)
	elseif SlowState == 2 then
		self:AdjustCameraFOV(SlowFOV, dt)
		buffer.writeu8(BaseState, 0, 0)
		Humanoid.WalkSpeed = TargetWalkSpeed
		Humanoid:Move(Vector3.zero)
		return
	end

	if MoveState == 3 then
		self:AdjustCameraFOV(BaseFOV, dt)
	elseif MoveState == 2 then
		self:AdjustCameraFOV(SprintFOV, dt)
	elseif MoveState == 1 then
		self:AdjustCameraFOV(BaseFOV, dt)
	else
		self:AdjustCameraFOV(BaseFOV, dt)
	end

	do -- buffered dash input
		if (MoveState ~= 3)
		and (SlowState == 0)
		and (buffer.readu8(DashState, 1) == 1)
		and (buffer.readu8(CrouchState, 1) ~= 1)
		and (buffer.readu8(FlyState, 1) ~= 1)
		then
			if self:EvaluateAuxState(4, true) then
				local V = Humanoid.MoveDirection
				if V.Magnitude == 0 then
					V = RootCFrame.LookVector
				end

				RootPart.AssemblyLinearVelocity *= Vector3_xzAxis
				self:SetMover("Slide", nil)
				self:SetMover("Dash", ApplyVelocity(
					self.Rig,
					V * buffer.readu16(DashState, 10),
					buffer.readu16(DashState, 8) * 0.001,
					Vector3.new(30000, 1250, 30000),
					buffer.readu16(DashState, 12)
				) :: any)

				self:Replicate(4, true)
				self:SendState(4, true)
				buffer.writeu8(BaseState, 0, 2)
				return
			end
			if States.Dash.IsActive(DashState) then
				buffer.writeu8(BaseState, 0, 2)
				buffer.writef32(CrouchState, 4, Now + 0.5)
				Humanoid.WalkSpeed = TargetWalkSpeed
				Humanoid:Move(MoveVector, true)
				return
			end
		end
	end

	do -- buffered jump & lift input
		if (buffer.readu8(SlideState, 1) ~= 1)
		and (buffer.readu8(FlyState, 1) ~= 1)
		and (buffer.readu8(SwimState, 1) ~= 1)
		then
			if (not IsInAir)
			and (SlowState == 0)
			and (MoveState ~= 3)
			then
				if States.Jump.Evaluate(JumpState, UpInput) then
					Humanoid.JumpPower = buffer.readu16(JumpState, 0) * (buffer.readu16(JumpState, 2) / 100)
					Humanoid.Jump = true

					States.Vectors.Write(Vectors, 72, CamVector)
				end
			end

			local LiftType = buffer.readu8(JumpState, 10)
			if (IsInAir)
			and (UpInput)
			and (SlowState == 0)
			and (LiftType ~= 0) then
				local Direction = Vector3.zero
				local Velocity = buffer.readu16(JumpState, 11) * dt
				if LiftType == 1 then
					Direction = Vector3.yAxis
				end
				RootPart:ApplyImpulse(Direction * Velocity)
			end
		end
	end

	do -- slide
		if (buffer.readu8(SlideState, 1) == 1) then
			local SlideActive, A = States.Slide.IsActive(SlideState)
			local SlideMover = self:GetMover("Slide")
			if (SlideActive) and (SlideMover) then
				SlideMover.P = (8000 * (1 - A))
				buffer.writeu8(BaseState, 0, 0)
				Humanoid.WalkSpeed = TargetWalkSpeed
				Humanoid:Move(Vector3.zero)
				return
			else
				buffer.writeu8(SlideState, 1, 0)
			end
		end
	end

	do -- buffered crouch,slide input
		if (not IsInAir)
		and (DownInput)
		and (MoveState == 2)
		and (buffer.readu8(DashState, 1) ~= 1)
		and (buffer.readu8(FlyState, 1) ~= 1)
		and (buffer.readu8(SwimState, 1) ~= 1)
		and (not States.Dash.IsActive(DashState))
		and (self:EvaluateAuxState(3, true))
		then
			self:SetMover("Dash", nil)
			self:SetMover("Slide", ApplyVelocity(
				self.Rig,
				-RootCFrame.RightVector:Cross(self:GetFloorNormal()) * buffer.readu16(SlideState, 10),
				buffer.readu16(SlideState, 8) * 0.001,
				Vector3.new(30000, 1000, 30000),
				buffer.readu16(SlideState, 12)
			) :: any)

			self:Replicate(3, true)
			self:SendState(3, true)
			buffer.writeu8(BaseState, 0, 0)
			buffer.writef32(CrouchState, 4, Now + 0.5)
			return
		end

		if (MoveState ~= 3)
		and (buffer.readu8(SwimState, 1) ~= 1)
		and (not States.Dash.IsActive(DashState))
		and (not States.Slide.IsActive(SlideState))
		and (States.Crouch.Evaluate(CrouchState, DownInput))
		then
			local IsCrouching = buffer.readu8(CrouchState, 1) == 1
			self:Replicate(2, IsCrouching)
			self:SendState(2, IsCrouching)
		end
	end

	do -- swim
		if (buffer.readu8(SwimState, 0) == 1) then
			local RigInVolume, CamInVolume, Depth = self:IsInSwimVolume()
			buffer.writeu8(SwimState, 12, CamInVolume == true and 1 or 0)
			if RigInVolume then
				if (buffer.readu8(CrouchState, 1) == 1) then
					buffer.writeu8(CrouchState, 1, 0)
					self:Replicate(2, false)
					self:SendState(2, false)
				end
				if self:GetMover("Fly") then
					buffer.writeu8(FlyState, 1, 0)
					self:SetMover("Fly", nil)
					self:Replicate(6, false)
					self:SendState(6, false)
				end
				if not self:GetMover("Swim") then
					buffer.writeu8(JumpAuxState, 12, 0)
					buffer.writeu8(SwimState, 1, 1)
					self:SetMover("Swim", ApplyPosition( self.Rig, RootCFrame.Position ) :: any)
					self:Replicate(5, true)
					self:SendState(5, true)
				end
				buffer.writeu16(SwimState, 8, Depth)
				local SwimMover = self:GetMover("Swim")
				if (MoveVector ~= Vector3.zero) or (UpVector ~= Vector3.zero) then
					local SwimSpeed = TargetWalkSpeed
					if MoveState == 2 then
						SwimSpeed = SprintSpeed
					end
					SwimSpeed *= (BaseScalar / 100) * (buffer.readu16(SwimState, 10) / 100)

					local SwimVelocity = (Camera.CFrame:VectorToWorldSpace(MoveVector) + UpVector).Unit
					if (math.round(Depth + 0.2) == 0) and (SwimVelocity:Dot(Vector3.yAxis) > -0.55) then
						SwimSpeed = 0
					end
					SwimMover.Position = RootCFrame.Position + (Vector3.yAxis * SwimVelocity * SwimSpeed)
				else
					SwimMover.Position = RootCFrame.Position
				end
			else
				if self:GetMover("Swim") then
					buffer.writeu8(SwimState, 1, 0)
					self:SetMover("Swim", nil)
					self:Replicate(5, false)
					self:SendState(5, false)
				end
			end
		else
			if self:GetMover("Swim") then
				buffer.writeu8(SwimState, 1, 0)
				self:SetMover("Swim", nil)
				self:Replicate(5, false)
				self:SendState(5, false)
			end
		end
	end

	do -- fly
		if (buffer.readu8(FlyState, 1) == 1)
		and (buffer.readu8(SwimState, 1) ~= 1)
		then
			if not IsInAir then
				if self:GetMover("Fly") then
					buffer.writeu8(FlyState, 1, 0)
					self:SetMover("Fly", nil)
					self:Replicate(6, false)
					self:SendState(6, false)
				end
			else
				self:SetMover("Dash", nil)
				self:SetMover("Slide", nil)
				if not self:GetMover("Fly") then
					self:SetMover("Fly", ApplyVelocity(
						self.Rig,
						Vector3.zero,
						nil,
						Vector3.one * buffer.readu32(FlyState, 10),
						buffer.readu32(FlyState, 14)
					) :: any)
					self:Replicate(6, true)
					self:SendState(6, true)
				end
				local FlyMover = self:GetMover("Fly")
				if (MoveVector ~= Vector3.zero) or (UpVector ~= Vector3.zero) then
					local FlySpeed = TargetWalkSpeed
					if MoveState == 2 then
						FlySpeed = SprintSpeed
					end
					FlySpeed *= (TargetScalar / 100) * (buffer.readu16(FlyState, 8) / 100)

					local FlyVelocity = Camera.CFrame:VectorToWorldSpace(MoveVector) + UpVector
					FlyMover.Velocity = FlyVelocity.Unit * FlySpeed
				else
					FlyMover.Velocity = Vector3.zero
				end
			end
		else
			if self:GetMover("Fly") then
				buffer.writeu8(FlyState, 1, 0)
				self:SetMover("Fly", nil)
				self:Replicate(6, false)
				self:SendState(6, false)
			end
		end
	end

	do -- rotate
		local RotateMode = 0
		local RotatePower = 0

		local ForcePriorityUntil = buffer.readf32(RotateState, 16)
		if (ForcePriorityUntil > Now) or (ForcePriorityUntil == -1) then
			RotateMode = buffer.readu8(RotateState, 10)
			RotatePower = buffer.readu32(RotateState, 11)
		else
			if IsInAir then
				RotateMode = buffer.readu8(RotateState, 0)
				RotatePower = buffer.readu32(RotateState, 1)
			else
				RotateMode = buffer.readu8(RotateState, 5)
				RotatePower = buffer.readu32(RotateState, 6)
			end
		end

		Humanoid.AutoRotate = RotateMode == 1

		if RotateMode == 2 then -- camera
			local rY = RootCFrame.RightVector:Dot((CamVector * Vector3_xzAxis).Unit)
			RootPart:ApplyAngularImpulse(Vector3.yAxis * -rY * RotatePower * dt)
		elseif RotateMode == 3 then -- mouse
			local rY = RootCFrame.RightVector:Dot(((MousePosition - RootPart.Position).Unit * Vector3_xzAxis).Unit)
			RootPart:ApplyAngularImpulse(Vector3.yAxis * -rY * RotatePower * dt)
		elseif RotateMode == 4 then -- rotatevector
			local RotateVector = Vector3.new(buffer.readf32(RotateState, 20), buffer.readf32(RotateState, 24), buffer.readf32(RotateState, 28))
			if RotateVector == Vector3.zero then
				RotateVector = RootCFrame.LookVector
			end
			local rY = RootCFrame.RightVector:Dot((RotateVector.Unit * Vector3_xzAxis).Unit)
			RootPart:ApplyAngularImpulse(Vector3.yAxis * -rY * RotatePower * dt)
		elseif RotateMode == 5 then
			local rY = RootCFrame.RightVector:Dot((PreJumpCamVector.Unit * Vector3_xzAxis).Unit)
			RootPart:ApplyAngularImpulse(Vector3.yAxis * -rY * RotatePower * dt)
		end
	end

	local IsCrouching = buffer.readu8(CrouchState, 1) == 1
	if IsCrouching then
		TargetScalar = SlowScalar
	end

	-- humanoid movement
	if MoveVector.Magnitude == 0 then
		if MoveState == 0 then
			-- input 0, idle
			-- lounge or smthing
			Humanoid.WalkSpeed = TargetWalkSpeed
			MoveVector = Vector3.zero
		elseif MoveState == 1 then
			-- input 0, walking
			-- transition to idle
			buffer.writeu8(BaseState, 0, 0)
			Humanoid.WalkSpeed = TargetWalkSpeed
			MoveVector = Vector3.zero
		elseif MoveState == 2 then
			-- input 0, sprinting
			-- define stop vector and transition to sprint decay
			Humanoid.WalkSpeed = TargetWalkSpeed
			if SlowState == 1 then
				buffer.writeu8(BaseState, 0, 0)
			else
				if IsInAir then
					buffer.writeu8(BaseState, 0, 0)
					MoveVector = self:SolveStopVector(IsInAir)
				else
					buffer.writeu8(BaseState, 0, 3)
					buffer.writef32(SpeedState, 12, Now + (SprintCooldown * 0.001))
					buffer.writef32(SpeedState, 18, Now)
				end
			end
		elseif MoveState == 3 then
			-- input 0, sprint stopped
			-- decay movement to 0
			local Since = Now - DecayStart
			DecayTime /= 1000
			if Since >= DecayTime then
				buffer.writeu8(BaseState, 0, 0)
				TargetWalkSpeed = BaseSpeed
			else
				TargetWalkSpeed = SprintSpeed * States.Speed.SolveDecayScalar(Since, DecayTime)
			end

			MoveVector = self:SolveStopVector(IsInAir)
		end

		if (IsInAir)
		and (buffer.readu8(FlyState, 1) ~= 1)
		then
			if AirControlMode == 0 then
				Humanoid:Move(MoveVector)
			elseif AirControlMode == 1 then
				Humanoid:Move(MoveVector)
			elseif AirControlMode == 2 then
				if (RootPart.AssemblyLinearVelocity * Vector3_xzAxis).Magnitude < 2 then
					Humanoid:Move(Vector3.zero)
				else
					Humanoid:Move(self.LastNonZero)
				end
			end
		else
			Humanoid:Move(MoveVector)
		end
	else
		if MoveState == 3 then
			-- input 1, sprint stopped
			-- decay movement to 0
			local Since = Now - DecayStart
			DecayTime /= 1000
			if Since >= DecayTime then
				buffer.writeu8(BaseState, 0, 0)
				TargetWalkSpeed = BaseSpeed
			else
				TargetWalkSpeed = math.clamp(SprintSpeed * States.Speed.SolveDecayScalar(Since, DecayTime), BaseSpeed, math.huge)
			end

			MoveVector = self:SolveStopVector(IsInAir)
			Humanoid:Move(MoveVector)
		else
			TargetWalkSpeed = MoveState == 2 and SprintSpeed or BaseSpeed
			if IsCrouching then
				TargetWalkSpeed = BaseSpeed
			end

			if MoveState == 0 then
				-- input 1, idle
				-- transition to walk state
				buffer.writeu8(BaseState, 0, 1)
			elseif MoveState == 1 then
				-- input 1, walking
				-- if sprint input then transition to sprint state
				if (SprintInput) and (SlowState == 0) then
					if States.Speed.EvaluateSprint(SpeedState) then
						buffer.writeu8(BaseState, 0, 2)
					end
					buffer.writeu8(BaseState, 3, 0)
				end
			elseif MoveState == 2 then
				-- input 1, sprinting
				-- if conditions are met, transition to walk state
				if (SlowState == 1) or (MoveVector:Dot(Vector3.zAxis) >= DecayDot * 0.001) or (IsCrouching) then
					buffer.writeu8(BaseState, 0, 1)
				end
			end

			if (IsInAir)
			and (buffer.readu8(FlyState, 1) ~= 1)
			then
				if AirControlMode == 0 then
					Humanoid:Move(Vector3.zero)
				elseif AirControlMode == 1 then
					Humanoid:Move(MoveVector, true)
				elseif AirControlMode == 2 then
					if (RootPart.AssemblyLinearVelocity * Vector3_xzAxis).Magnitude < 2 then
						Humanoid:Move(Vector3.zero)
					else
						Humanoid:Move(self.LastNonZero)
					end
				end
			else
				Humanoid:Move(MoveVector, true)
			end
		end
	end

	local FinalSpeed = TargetWalkSpeed * (TargetScalar / 100)
	if IsInAir then
		FinalSpeed *= (AirScalar / 100)
	end

	Humanoid.WalkSpeed = FinalSpeed
end

function Motion.__index:EvaluateAuxState(StateId: number, DesiredState: boolean?): boolean
	local AuxStateName = AuxStates[StateId]
	local StateModule = States[AuxStateName]
	if StateModule and StateModule.Evaluate then
		return StateModule.Evaluate(self[AuxStateName], DesiredState)
	end
	return false
end

function Motion.__index:SolveStopVector(IsInAir: boolean?): Vector3
	local RootPart = self.RootPart
	local LookVector = RootPart.CFrame.LookVector
	local LateralCamera = ((self.Camera :: Camera).CFrame.LookVector * Vector3_xzAxis).Unit
	local LateralVelocity = ((RootPart :: BasePart).AssemblyLinearVelocity * Vector3_xzAxis).Unit
	if IsInAir then
		return LookVector:Lerp(LateralCamera.Unit, buffer.readu8(self.Speed, 25) / 100).Unit
	else
		return LateralVelocity:Lerp(LateralCamera.Unit, buffer.readu8(self.Speed, 24) / 100).Unit
	end
end

function Motion.__index:GetFloorNormal(): Vector3
	local RootPart = self.RootPart
	local Result = Raycast.RayBlacklist(RootPart.Position, Vector3.yAxis * -((3 * self.Rig:GetScale()) + 0.1), self.Blacklist)
	return Result and Result.Normal or Vector3.zero
end

function Motion.__index:AdjustCameraFOV(TargetFOV: number, dt: number)
	self.Camera.FieldOfView = lerp(self.Camera.FieldOfView, TargetFOV, buffer.readu8(self.Speed, 30) * dt)
end

function Motion.__index:GetMover(Key: string): BodyMover?
	return self.Movers[Key]
end

function Motion.__index:SetMover(Key: string, Mover: BodyMover?): ()
	if self.Movers[Key] then
		self.Movers[Key]:Destroy()
	end
	self.Movers[Key] = (Mover :: any)
end

function Motion.__index:ClearMovers(): ()
	for Key in self.Movers do
		self.Movers[Key]:Destroy()
		self.Movers[Key] = nil
	end
end

---rootinvolume,caminvolume,rootdepth
function Motion.__index:IsInSwimVolume(): (boolean, boolean, number)
	local P0 = self.RootPart.Position
	local P1 = self.Camera.CFrame.Position
	local RootInVolume = false
	local CamInVolume = false
	local Depth = 0
	for _, VolumeDesc in SwimVolumes do
		local C0, Size = VolumeDesc[1] :: CFrame, VolumeDesc[2] :: Vector3
		Size *= 0.5
		local sX, sY, sZ = Size.X, Size.Y, Size.Z

		if not RootInVolume then
			local RootObjSpace = C0:PointToObjectSpace(P0)
			RootInVolume =
				(math.abs(RootObjSpace.X) <= sX) and
				(math.abs(RootObjSpace.Y) <= sY) and
				(math.abs(RootObjSpace.Z) <= sZ)
			if RootInVolume then
				Depth = Size.Y - RootObjSpace.Y
			end
		end
		if not CamInVolume then
			local CamObjSpace = C0:PointToObjectSpace(P1)
			CamInVolume =
				(math.abs(CamObjSpace.X) <= sX) and
				(math.abs(CamObjSpace.Y) <= sY) and
				(math.abs(CamObjSpace.Z) <= sZ)
		end
	end
	return RootInVolume, CamInVolume, Depth
end

function Motion.__index:BindToReplicate(f: (Rig: Model, StateId: number, StateActive: boolean) -> ())
	self.R = f
	---@diagnostic disable-next-line: undefined-type
	ReplicateRemote.OnClientEvent:Connect(function(Payload: { any })
		for _, T in Payload do
			local Rig: Model = T[1]
			local CompressedStateBuffer: buffer = T[2]
			if Rig == self.Rig :: Model then continue end

			for i = 1, buffer.len(CompressedStateBuffer) do
				local StateId, StateActive = Motion.StateDecompress(buffer.readu8(CompressedStateBuffer, i - 1))
				task.defer(self.R, Rig, StateId, StateActive)
			end
		end
	end)
end

function Motion.__index:SendState(StateId: number, StateActive: boolean): ()
	ReplicateRemote:FireServer(Motion.StateCompress(StateId, StateActive))
end

function Motion.__index:Replicate(StateId: number, StateActive: boolean): ()
	if self.R then
		task.defer(self.R :: any, self.Rig, StateId, StateActive)
	else
		warn("replicate function not bound to Motion::BindToReplicate")
	end
end

	---@diagnostic disable-next-line: undefined-type
function Motion.__index:OnForceRotateRecv(fBuffer: buffer): ()
	local RotateState = self.Rotate
	local Now = os.clock()

	local Priority = buffer.readu8(fBuffer, 5)
	local Overrides = (Priority >= buffer.readu8(RotateState, 15)) or (buffer.readf32(RotateState, 16) < Now)
	if not Overrides then return end

	buffer.writeu8(RotateState, 10, buffer.readu8(fBuffer, 0))
	buffer.writeu32(RotateState, 11, buffer.readu32(fBuffer, 1))
	buffer.writeu8(RotateState, 15, Priority)
	buffer.writef32(RotateState, 16, buffer.readu16(fBuffer, 6) * 0.001)
	buffer.copy(RotateState, 20, fBuffer, 8, 12)
end

---creates rotateforcemode packet
---@param Mode number rotate mode `0` = autorotate false `1` = autorotate true `2` = camera `3` = mouse
---@param Power number angular rotation power
---@param Priority number priority
---@param TimeMs number rotate mode force time (milliseconds)
---@param Direction Vector3 optional force direction
---@return buffer forceBuffer buffer
---@diagnostic disable-next-line: undefined-type
function Motion.RotateModeForcePacket(Mode: number, Power: number, Priority: number, TimeMs: number, Direction: Vector3?): buffer
	local b = buffer.create(20)
	buffer.writeu8(b, 0, Mode)
	buffer.writeu32(b, 1, Power)
	buffer.writeu8(b, 5, Priority)
	buffer.writeu16(b, 6, TimeMs)
	if Direction then
		buffer.writef32(b, 8, Direction.X)
		buffer.writef32(b, 12, Direction.Y)
		buffer.writef32(b, 16, Direction.Z)
	end
	return b
end

---@diagnostic disable-next-line: undefined-type
function Motion.SendForcePacket(Player: Player, fBuffer: buffer): ()
	ForceRotateRemote:FireClient(Player, fBuffer)
end

function Motion.Effect(Rig: Model, IsLocal: boolean, StateName: string, StateActive: boolean): AnimationTrack?
	local StateModule = States[StateName]
	if StateModule then
		if StateModule.Effect then
			StateModule.Effect(Rig, StateActive)
		end
		if IsLocal and StateModule.Animate then
			return StateModule.Animate(Rig, StateActive)
		end
	end
	return
end

function Motion.DefineSwimVolumes(VolumeDescriptions: { {CFrame|Vector3} })
	table.clear(SwimVolumes)
	table.move(VolumeDescriptions, 1, #VolumeDescriptions, 1, SwimVolumes)
end

function Motion.Optimize(Humanoid: Humanoid): ()
	for _, State: Enum.HumanoidStateType in {
		Enum.HumanoidStateType.Climbing;
		Enum.HumanoidStateType.PlatformStanding;
		Enum.HumanoidStateType.Flying;
		Enum.HumanoidStateType.FallingDown;
		Enum.HumanoidStateType.Swimming;
	} do
		Humanoid:SetStateEnabled(State, false)
	end
end

function Motion.StateCompress(StateId: number, StateActive: boolean): number
	return (StateId * 10) + (StateActive and 1 or 0)
end

function Motion.StateDecompress(CompressedState: number): (number, boolean)
	local StateId, StateActive = math.modf(CompressedState / 10)
	return StateId, math.round(StateActive * 10) == 1
end

if IsServer then
	local Cache = {} :: {[Player]: {[number]: number}}
	local MaxPlayers = Players.MaxPlayers
	local StateRange = 0

	for _ in States do
		StateRange += 1
	end
	StateRange -= 5 -- (base, vectors, speed, jump, turn)

	ReplicateRemote.OnServerEvent:Connect(function(Player: Player, CompressedState: number)
		local Character = Player.Character
		if not Character then return end
		if type(CompressedState) ~= "number" then return end
		if CompressedState > 255 then return end
		if CompressedState < 0 then return end

		local StateId, StateActive = Motion.StateDecompress(CompressedState)
		if StateId > StateRange then return end
		if StateId <= 0 then return end

		if not Cache[Player] then
			Cache[Player] = table.create(StateRange)
		end
		Cache[Player][StateId] = StateActive and 1 or 0
	end)

	local Elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		Elapsed += dt
		if Elapsed < ReplicateClock then return end
		Elapsed -= ReplicateClock

		-- Size starts with 1 byte overhead
		-- Payload: [ [Character, StateBuffer] ]
		local Size, Payload = 1, table.create(MaxPlayers)

		for Player, DecompressedStates in Cache do
			-- filter left players, nil characters, empty state tables
			if not Player:IsDescendantOf(Players) then
				Cache[Player] = nil
				continue
			end
			if not Player.Character then
				Cache[Player] = nil
				continue
			end
			if next(DecompressedStates) == nil then
				Cache[Player] = nil
				continue
			end

			-- count payload size
			-- break out of loop if payload is past 900 byte limit
			local len = 0
			for _ in DecompressedStates do
				len += 1
			end

			Size += 4 + len -- instance + len
			if Size >= 900 then break end

			-- pack numbers into a buffer to send
			local b, offset = buffer.create(len), 0
			for StateId, StateActive in DecompressedStates do
				buffer.writeu8(b, offset, Motion.StateCompress(StateId, StateActive == 1))
				offset += 1
			end

			-- T: [Character, StateBuffer]
			local T = table.create(2) :: {any}
			table.insert(T, Player.Character)
			table.insert(T, b)
			table.insert(Payload, T)

			-- flush from cache 🚽🌊
			Cache[Player] = nil
		end

		if #Payload > 0 then
			ReplicateRemote:FireAllClients(Payload)
		end
	end)
end

return Motion