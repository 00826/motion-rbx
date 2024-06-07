local AnimationInstance			= script:WaitForChild("Animation")

local AnimLibrary				= {} :: { [Enum.HumanoidRigType|"Custom"]: {[string]: {Id: string; Priority: Enum.AnimationPriority;}} }
local StepSounds				= {} :: { [Enum.Material|"Default"]: Sound }

local Vector3_xzAxis			= Vector3.one - Vector3.yAxis

local Animation = { __index = {} }

function Animation.new(Rig: Model)
	local Controller, Animator = Animation.Components(Rig)
	assert(Controller)
	return setmetatable({
		Rig					= Rig;
		RootPart			= Rig.PrimaryPart;
		Controller			= Controller;
		Animator			= Animator;
		AnimTable			= Controller:IsA("Humanoid") and AnimLibrary[Controller.RigType] or AnimLibrary.Custom;

		CurrentLoopAnim		= nil :: AnimationTrack?;
		CurrentToolAnim		= nil :: AnimationTrack?;

		ScalarBuffer		= buffer.create(12);
		--[[
		[0] uint8 BaseRecp # when LateralVelocity <= BaseSpeed, AnimationSpeed = LateralVelocity * (1 / BaseRecp)
		[1] uint8 SprintRecp # when LateralVelocity > BaseSpeed, AnimationSpeed = LateralVelocity * (1 / SprintRecp)
		[2] uint16 BaseSpeed # BaseSpeed
		[4] f32 AnimSpeedUpperLimit # Animation::SolveAnimSpeed upper limit
		[8] f32 StepsMuted # step sounds muted until
		]]
	}, Animation)
end

function Animation.__index:FastSolveMotionState(): number
	local ScalarBuffer = self.ScalarBuffer
	local LateralVelocity = (self.RootPart.AssemblyLinearVelocity * Vector3_xzAxis).Magnitude
	if LateralVelocity < 1 then
		return 0
	elseif LateralVelocity <= buffer.readu16(ScalarBuffer, 2) + 1 then
		return 1
	else
		return 2
	end
end

function Animation.__index:SolveAnimSpeed(): number
	local ScalarBuffer = self.ScalarBuffer
	local LateralVelocity = (self.RootPart.AssemblyLinearVelocity * Vector3_xzAxis).Magnitude
	if LateralVelocity <= buffer.readu16(ScalarBuffer, 2) + 1 then
		return math.clamp(LateralVelocity * (1 / buffer.readu8(ScalarBuffer, 0)), 0, buffer.readf32(self.ScalarBuffer, 4))
	else
		return math.clamp(LateralVelocity * (1 / buffer.readu8(ScalarBuffer, 1)), 0, buffer.readf32(self.ScalarBuffer, 4))
	end
end

---@diagnostic disable-next-line: undefined-type
function Animation.__index:WriteScalars(BaseSpeed: number?, BaseRecp: number?, SprintRecp: number?, AnimSpeedUpperLimit: number?): buffer
	local sBuffer = self.ScalarBuffer
	if BaseRecp then
		buffer.writeu8(sBuffer, 0, BaseRecp)
	end
	if SprintRecp then
		buffer.writeu8(sBuffer, 1, SprintRecp)
	end
	if BaseSpeed then
		buffer.writeu16(sBuffer, 2, BaseSpeed)
	end
	if AnimSpeedUpperLimit then
		buffer.writef32(sBuffer, 4, AnimSpeedUpperLimit)
	end
	return sBuffer
end

function Animation.__index:UpdateLoopSpeed(Speed: number?)
	if self.CurrentLoopAnim then
		self.CurrentLoopAnim:AdjustSpeed(Speed or self:SolveAnimSpeed())
	end
end

function Animation.__index:SetLoopAnim(Ref: string?): AnimationTrack?
	if self:Evaluate(self.CurrentLoopAnim, Ref) then
		self.CurrentLoopAnim = self:Replace(self.CurrentLoopAnim, Ref)
		if (self.CurrentLoopAnim) and (next(StepSounds) ~= nil) then
			self.CurrentLoopAnim.KeyframeReached:Connect(function()
				if buffer.readf32(self.ScalarBuffer, 8) > os.clock() then return end
				if not self.Controller then return end
				if not self.Controller:IsA("Humanoid") then return end

				local NewSound = (StepSounds[self.Controller.FloorMaterial] or StepSounds.Default):Clone()
				NewSound.Parent = self.RootPart
				NewSound.Ended:Once(function()
					NewSound:Destroy()
				end)
				NewSound:Play()
			end)
		end
	end
	return self.CurrentLoopAnim
end

function Animation.__index:SetToolAnim(Ref: string?): AnimationTrack?
	if self:Evaluate(self.CurrentToolAnim, Ref) then
		self.CurrentToolAnim = self:Replace(self.CurrentToolAnim, Ref)
	end
	return self.CurrentToolAnim
end

function Animation.__index:Replace(AnimTrack: AnimationTrack?, Ref: string?): AnimationTrack?
	if AnimTrack then
		AnimTrack:Stop(0.1)
		AnimTrack = nil
	end
	if Ref then
		AnimTrack = self:LoadFromRef(Ref)
		AnimTrack:Play()
		AnimTrack:AdjustSpeed(self:SolveAnimSpeed())
	end
	return AnimTrack
end

---returns true if AnimTrack can be replaced by Ref
function Animation.__index:Evaluate(AnimTrack: AnimationTrack?, Ref: string?): boolean
	if (AnimTrack == nil) and (Ref == nil) then return false end
	if (AnimTrack == nil) then return true end
	return AnimTrack.Name ~= Ref
end

function Animation.__index:LoadFromRef(Ref: string): AnimationTrack
	local AnimData = self.AnimTable[Ref]
	AnimationInstance.AnimationId = AnimData.Id
	local Track = self.Animator:LoadAnimation(AnimationInstance)
	Track.Name = Ref
	Track.Priority = AnimData.Priority
	return Track
end

function Animation.__index:MuteStepSounds(Time: number): ()
	buffer.writef32(self.ScalarBuffer, 8, os.clock() + Time)
end

function Animation.__index:Destroy(): ()
	if self.CurrentLoopAnim then
		self.CurrentLoopAnim:Stop(0.1)
	end
	if self.CurrentToolAnim then
		self.CurrentToolAnim:Stop(0.1)
	end
	table.clear(self)
	setmetatable(self, nil)
end

function Animation.Components(Rig: Model): ((Humanoid|AnimationController)?, Animator?)
	local Container = Rig:FindFirstChildOfClass("Humanoid") or Rig:FindFirstChildOfClass("AnimationController")
	local Animator = nil
	if Container then
		Animator = Container:FindFirstChildOfClass("Animator")
	end
	return Container, Animator
end

function Animation.FindAnimator(Rig: Model): Animator?
	local Container = Rig:FindFirstChildOfClass("Humanoid") or Rig:FindFirstChildOfClass("AnimationController")
	if Container then
		return Container:FindFirstChildOfClass("Animator")
	end
end

function Animation.AddAnimator(Rig: Model): Animator?
	local Container = Rig:FindFirstChildOfClass("Humanoid") or Rig:FindFirstChildOfClass("AnimationController")
	if Container then
		local PreExisting = nil
		repeat
			PreExisting = Container:FindFirstChildOfClass("Animator")
			if PreExisting then
				PreExisting:Destroy()
			end
		until PreExisting == nil

		PreExisting = Instance.new("Animator") -- using a prefab animator that was made post-runtime has weird behavior
		PreExisting.Parent = Container
		return PreExisting
	end
end

function Animation.StopAll(A: Animator): ()
	for _, AnimTrack in A:GetPlayingAnimationTracks() do
		AnimTrack:Stop(0.1)
	end
end

function Animation.PlayFromAssetId(Rig: Model, Id: string, Priority: Enum.AnimationPriority?): AnimationTrack?
	local Controller, Animator = Animation.Components(Rig)
	if Controller and Animator then
		local AnimTable = nil
		if Controller:IsA("Humanoid") then
			AnimTable = AnimLibrary[Controller.RigType]
		elseif Controller:IsA("AnimationController") then
			AnimTable = AnimLibrary.Custom
		end
		if AnimTable then
			AnimationInstance.AnimationId = Id
			local AnimationTrack = Animator:LoadAnimation(AnimationInstance)
			AnimationTrack.Name = Id
			AnimationTrack.Priority = Priority or Enum.AnimationPriority.Action
			AnimationTrack:Play()
			return AnimationTrack
		else
			warn(Rig.Name, Controller)
		end
	end
end

function Animation.PlayFromRef(Rig: Model, Ref: string): AnimationTrack?
	local Controller, Animator = Animation.Components(Rig)
	if Controller and Animator then
		local AnimTable = nil
		if Controller:IsA("Humanoid") then
			AnimTable = AnimLibrary[Controller.RigType]
		elseif Controller:IsA("AnimationController") then
			AnimTable = AnimLibrary.Custom
		end
		if AnimTable and AnimTable[Ref] then
			local AnimData = AnimTable[Ref]
			AnimationInstance.AnimationId = AnimData.Id
			local AnimationTrack = Animator:LoadAnimation(AnimationInstance)
			AnimationTrack.Name = Ref
			AnimationTrack.Priority = AnimData.Priority
			AnimationTrack:Play()
			return AnimationTrack
		else
			warn(Rig.Name, Ref, Controller)
		end
	end
end

function Animation.DefineAnimLibrary(T: { [Enum.HumanoidRigType|"Custom"]: { [string]: { Id: string; Priority: Enum.AnimationPriority; } } }): ()
	for RigType, AnimTable in T do
		AnimLibrary[RigType] = AnimTable
	end
end

function Animation.DefineStepSounds(T: { [Enum.Material|"Default"]: Sound }): ()
	for Material, Sound in T do
		StepSounds[Material] = Sound
	end
end

return Animation