--!nonstrict

local RunService				= game:GetService("RunService")

local Shared					= game:GetService("ReplicatedStorage"):WaitForChild("Shared")

local Motion					= require(Shared.Motion)

local Konbini					= require(Shared.Konbini)
local Animation					= Konbini.Animation
local Inputs					= Konbini.Inputs

local Player					= game:GetService("Players").LocalPlayer
local Character					= Player.Character or Player.CharacterAdded:Wait()
local Humanoid					= Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid")

local PlayerScripts				= Player:WaitForChild("PlayerScripts")
local PlayerModule				= require(PlayerScripts:WaitForChild("PlayerModule"))
local ControlScript				= require(PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

do
	local SwimVolumes = workspace:WaitForChild("World"):WaitForChild("SwimVolumes")
	local CompiledDescs = table.create(4)
	for _, BasePart in SwimVolumes:GetChildren() do
		if not BasePart:IsA("BasePart") then continue end
		local VolumeDesc = table.create(2)
		VolumeDesc[1] = BasePart.CFrame
		VolumeDesc[2] = BasePart.Size
		table.insert(CompiledDescs, VolumeDesc)
	end
	Motion.DefineSwimVolumes(CompiledDescs)

	local StepSounds = script.Parent:WaitForChild("StepSounds")
	Animation.definestepsounds{
		[Enum.Material.Grass]		= StepSounds.StepGrass;
		[Enum.Material.Sand]		= StepSounds.StepSand;
		[Enum.Material.Wood]		= StepSounds.StepWood;
		[Enum.Material.WoodPlanks]	= StepSounds.StepWood;
		[Enum.Material.Snow]		= StepSounds.StepSnow;
		[Enum.Material.Ice]			= StepSounds.StepSnow;
	
		["Default"]					= StepSounds.StepDefault;
	}

	Animation.defineanimlibrary({
		[Enum.HumanoidRigType.R6]		= {
			Walk				= {Id = "rbxassetid://5939744476";		Priority = Enum.AnimationPriority.Core;};
			Sprint				= {Id = "rbxassetid://5939696701";		Priority = Enum.AnimationPriority.Core;};
			Idle				= {Id = "rbxassetid://5939950114";		Priority = Enum.AnimationPriority.Movement;};
			Freefall			= {Id = "rbxassetid://5942469156";		Priority = Enum.AnimationPriority.Movement;};
			Swim				= {Id = "rbxassetid://16822497838";		Priority = Enum.AnimationPriority.Core;};
			SwimIdle			= {Id = "rbxassetid://16822499422";		Priority = Enum.AnimationPriority.Movement;};
			Fly					= {Id = "rbxassetid://16844408044";		Priority = Enum.AnimationPriority.Core;};
			FlyIdle				= {Id = "rbxassetid://16844658341";		Priority = Enum.AnimationPriority.Movement;};
	
			Dash				= {Id = "rbxassetid://12860993465";		Priority = Enum.AnimationPriority.Action;};
			Jump				= {Id = "rbxassetid://5942441753";		Priority = Enum.AnimationPriority.Action;};
			DoubleJump			= {Id = "rbxassetid://5942879508";		Priority = Enum.AnimationPriority.Action;};
			SprintStop			= {Id = "rbxassetid://12859964757";		Priority = Enum.AnimationPriority.Action;};
			Slide				= {Id = "rbxassetid://16788485937";		Priority = Enum.AnimationPriority.Action;};
		};
	})
end

local AObject = Animation.Controller(Character)
AObject:WriteScalars(18, 10, 16, 2.5)

local MObject = Motion.empty()

local BaseState = MObject.Base
local Vectors = MObject.Vectors

local Speed = MObject.Speed
buffer.writeu16(Speed, 0, 18) -- base speed
buffer.writeu16(Speed, 2, 32) -- sprint speed
buffer.writeu16(Speed, 4, 100) -- speed scalar
buffer.writeu16(Speed, 6, 100) -- air speed scalar
buffer.writeu16(Speed, 8, 50) -- slow scalar
buffer.writeu16(Speed, 10, 500) -- sprint activation cooldown
buffer.writeu16(Speed, 16, 350) -- sprint-stop decay time
buffer.writei16(Speed, 22, 1001) -- sprint-stop decay dot
buffer.writeu8(Speed, 24, 1) -- decay ground control
buffer.writeu8(Speed, 25, 0) -- air control
buffer.writeu8(Speed, 26, 1) -- air control mode
buffer.writeu8(Speed, 27, 80) -- base fov
buffer.writeu8(Speed, 28, 90) -- max fov
buffer.writeu8(Speed, 29, 70) -- slow fov
buffer.writeu8(Speed, 30, 8) -- lerp coefficient * dt

local Jump = MObject.Jump
buffer.writeu16(Jump, 0, 50) -- jump velocity
buffer.writeu16(Jump, 2, 100) -- jump scalar
buffer.writeu16(Jump, 4, 0) -- jump cooldown
buffer.writeu8(Jump, 10, 1) -- jump lift type
buffer.writeu16(Jump, 11, 800) -- jump lift velocity

local JumpAux = MObject.JumpAux
buffer.writeu8(JumpAux, 0, 1) -- aux jump enabled
buffer.writeu16(JumpAux, 2, 70) -- aux jump velocity
buffer.writeu16(JumpAux, 4, 100) -- aux jump scalar
buffer.writeu16(JumpAux, 6, 0) -- aux jump cooldown
buffer.writeu8(JumpAux, 13, 1) -- aux jump limit

local Crouch = MObject.Crouch
buffer.writeu8(Crouch, 0, 1) -- crouch enabled
buffer.writeu16(Crouch, 2, 100) -- crouch cooldown

local Slide = MObject.Slide
buffer.writeu8(Slide, 0, 1) -- slide enabled
buffer.writeu16(Slide, 2, 1250) -- slide cooldown
buffer.writeu16(Slide, 8, 400) -- slide lifetime
buffer.writeu16(Slide, 10, 70) -- slide velocity
buffer.writeu16(Slide, 12, 8000) -- slide P

local Dash = MObject.Dash
buffer.writeu8(Dash, 0, 1) -- dash enabled
buffer.writeu16(Dash, 2, 1500) -- dash cooldown
buffer.writeu16(Dash, 8, 150) -- dash lifetime
buffer.writeu16(Dash, 10, 100) -- dash velocity
buffer.writeu16(Dash, 12, 12000) -- dash P

local Rotate = MObject.Rotate
buffer.writeu8(Rotate, 0, 1) -- rotate mode air
buffer.writeu32(Rotate, 1, 5000) -- rotate mode air power
buffer.writeu8(Rotate, 5, 1) -- rotate mode ground
buffer.writeu32(Rotate, 6, 60000) -- rotate mode ground power

local Fly = MObject.Fly
buffer.writeu8(Fly, 0, 1) -- fly enabled
buffer.writeu16(Fly, 2, 0) -- fly cooldown
buffer.writeu16(Fly, 8, 200) -- fly scalar
buffer.writeu32(Fly, 10, 50000) -- fly maxforce
buffer.writeu32(Fly, 14, 250000) -- fly P

local Swim = MObject.Swim
buffer.writeu8(Swim, 0, 1) -- swim enabled
buffer.writeu16(Swim, 2, 0) -- swim cooldown
buffer.writeu16(Swim, 10, 20) -- swim scalar

MObject:init(Character,
	function()
		return Inputs.read(1)
	end,
	function()
		return ControlScript:GetMoveVector()
	end
)

assert(MObject.RootPart)

local function Replicate(Rig: Model, StateId: number, StateActive: boolean)
	local IsLocal = Rig == Character
	--print(Rig.Name, IsLocal, StateId, StateActive)

	if StateId == 1 then -- jump aux
		Motion.Effect(Rig, IsLocal, "JumpAux", StateActive)
	elseif StateId == 2 then -- crouch
		Motion.Effect(Rig, IsLocal, "Crouch", StateActive)
	elseif StateId == 3 then -- slide
		local AnimTrack = Motion.Effect(Rig, IsLocal, "Slide", StateActive)
		if AnimTrack then
			AnimTrack:AdjustSpeed(1 / (buffer.readu16(Slide, 8) * 0.001))
		end
	elseif StateId == 4 then -- dash
		Motion.Effect(Rig, IsLocal, "Dash", StateActive)
	elseif StateId == 5 then -- swim
		Motion.Effect(Rig, IsLocal, "Swim", StateActive)
	elseif StateId == 6 then -- fly
		Motion.Effect(Rig, IsLocal, "Fly", StateActive)
	end
end

local function JumpAuxReal(Extra: number?)
	buffer.writeu8(JumpAux, 12, buffer.readu8(JumpAux, 12) + 1)

	MObject.RootPart.AssemblyLinearVelocity *= Vector3.new(1, 0, 1)
	MObject.RootPart.AssemblyLinearVelocity += Vector3.yAxis * (buffer.readu16(JumpAux, 2) + (Extra or 0))

	MObject:Replicate(1, true)
	MObject:SendState(1, true)
end

local function JumpAuxBehavior()
	if (Humanoid.Sit)
	or (buffer.readu8(Crouch, 1) == 1)
	or (buffer.readu8(JumpAux, 1) == 1)
	or (buffer.readu8(Fly, 1) == 1)
	then return end

	if buffer.readu16(Swim, 1) == 1 then
		if buffer.readu16(Swim, 8) == 0 then
			JumpAuxReal(30)
		end
		return
	end
	if Humanoid.FloorMaterial ~= Enum.Material.Air then return end
	if not MObject:EvaluateAuxState(1, true) then return end

	JumpAuxReal()
end

local function ResetJumpAux()
	buffer.writeu8(JumpAux, 12, 0)
end

local function OnInputBegan(InputObject: InputObject, SunkInput: boolean)
	local UserInputType = InputObject.UserInputType
	local KeyCode = InputObject.KeyCode

	if PlayerModule:IsMouseLocked() then
		if UserInputType == Enum.UserInputType.MouseButton2 then
			--buffer.writeu8(Rotate, 0, 2)
			buffer.writeu8(Rotate, 5, 2)
		elseif KeyCode == Enum.KeyCode.ButtonR2 then
			--buffer.writeu8(Rotate, 0, 2)
			buffer.writeu8(Rotate, 5, 2)
		end
	end

	if KeyCode == Enum.KeyCode.Space then
		if SunkInput then return end
		buffer.writeu8(BaseState, 5, 1)
		buffer.writef32(Vectors, 16, 1)
		JumpAuxBehavior()
	elseif KeyCode == Enum.KeyCode.ButtonA then
		buffer.writef32(Vectors, 16, 1)
		JumpAuxBehavior()
	elseif KeyCode == Enum.KeyCode.C then
		if SunkInput then return end
		buffer.writeu8(BaseState, 4, 1)
		buffer.writef32(Vectors, 16, -1)
	elseif KeyCode == Enum.KeyCode.Q then
		if SunkInput then return end
		buffer.writeu8(Dash, 1, 1)
	elseif KeyCode == Enum.KeyCode.ButtonL3 then
		if SunkInput then return end
		buffer.writeu8(Dash, 1, 1)
	elseif KeyCode == Enum.KeyCode.F then
		if SunkInput then return end
		if Humanoid.FloorMaterial ~= Enum.Material.Air then return end
		if buffer.readu8(Swim, 1) == 1 then return end
		buffer.writeu8(Fly, 1, buffer.readu8(Fly, 1) == 0 and 1 or 0)
	end
end

local function OnInputEnded(InputObject: InputObject, SunkInput: boolean)
	local UserInputType = InputObject.UserInputType
	local KeyCode = InputObject.KeyCode

	if UserInputType == Enum.UserInputType.MouseButton2 then
		--buffer.writeu8(Rotate, 0, 1)
		buffer.writeu8(Rotate, 5, 1)
	elseif KeyCode == Enum.KeyCode.ButtonR2 then
		--buffer.writeu8(Rotate, 0, 1)
		buffer.writeu8(Rotate, 5, 1)
	end

	local UpVectorY = buffer.readf32(Vectors, 16)
	if KeyCode == Enum.KeyCode.Space then
		if SunkInput then return end
		buffer.writeu8(BaseState, 5, 0)
		if UpVectorY ~= 1 then return end
		buffer.writef32(Vectors, 16, 0)
	elseif KeyCode == Enum.KeyCode.ButtonA then
		if UpVectorY ~= 1 then return end
		buffer.writef32(Vectors, 16, 0)
	elseif KeyCode == Enum.KeyCode.C then
		if SunkInput then return end
		buffer.writeu8(BaseState, 4, 0)
		if UpVectorY ~= -1 then return end
		buffer.writef32(Vectors, 16, 0)
	elseif KeyCode == Enum.KeyCode.Q then
		if SunkInput then return end
		buffer.writeu8(Dash, 1, 0)
	elseif KeyCode == Enum.KeyCode.ButtonL3 then
		if SunkInput then return end
		buffer.writeu8(Dash, 1, 0)
	end
end

local function OnDoubleTap(KeyCode: Enum.KeyCode)
	if KeyCode == Enum.KeyCode.W then
		if buffer.readu8(BaseState, 0) == 3 then return end
		buffer.writeu8(BaseState, 3, 1)
	end
end

Humanoid.StateChanged:Connect(function(_, NewState: Enum.HumanoidStateType)
	if NewState == Enum.HumanoidStateType.Landed then
		ResetJumpAux()
	elseif NewState == Enum.HumanoidStateType.Jumping then
		Animation.playfromref(Character, "Jump")
	end
end)

MObject:BindToReplicate(Replicate)

Inputs.began(OnInputBegan)
Inputs.ended(OnInputEnded)
Inputs.doubletap(OnDoubleTap)

local PreviousState = 0

local function SolveIdleAnimation()
	local MoveState = buffer.readu8(BaseState, 0)
	local Swimming = buffer.readu8(Swim, 1) == 1
	local Flying = buffer.readu8(Fly, 1) == 1

	if PreviousState ~= MoveState then
		PreviousState = MoveState
		if (MoveState == 3)
		and (not Flying)
		and (not Swimming)
		then
			Animation.playfromref(Character, "SprintStop")
		end
	end

	if (Character:GetAttribute("Ragdoll"))
	or (Character:GetAttribute("Dead"))
	or (Humanoid.Sit)
	then
		AObject:SetLoopAnim(nil)
		AObject:UpdateLoopSpeed(1)
		return
	end

	if (not Flying)
	and (not Swimming)
	and (Humanoid.FloorMaterial == Enum.Material.Air)
	then
		AObject:SetLoopAnim("Freefall")
		AObject:UpdateLoopSpeed(1)
		return
	end

	if MoveState == 0 then
		if Swimming then
			AObject:SetLoopAnim("SwimIdle")
		elseif Flying then
			AObject:SetLoopAnim("FlyIdle")
		else
			AObject:SetLoopAnim("Idle")
		end
		AObject:UpdateLoopSpeed(1)
	elseif MoveState == 1 then
		if Swimming then
			AObject:SetLoopAnim("Swim")
		elseif Flying then
			AObject:SetLoopAnim("Fly")
		else
			AObject:SetLoopAnim("Walk")
		end
		AObject:UpdateLoopSpeed((Swimming or Flying) and 1 or nil)
	elseif MoveState == 2 then
		if Swimming then
			AObject:SetLoopAnim("Swim")
		elseif Flying then
			AObject:SetLoopAnim("Fly")
		else
			AObject:SetLoopAnim("Sprint")
		end
		AObject:UpdateLoopSpeed((Swimming or Flying) and 1 or nil)
	elseif MoveState == 3 then
		AObject:SetLoopAnim("Idle")
		AObject:UpdateLoopSpeed()
	end
end

local function MotionFrame(dt: number)
	SolveIdleAnimation()

	if Inputs.PlatformId == 2 then
		if ControlScript:GetMoveVector().Magnitude > 0.98 then
			if buffer.readu8(BaseState, 0) == 3 then return end
			buffer.writeu8(BaseState, 3, 1)
		end
	end
end

RunService.Heartbeat:Connect(MotionFrame)