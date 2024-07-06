local Animate = require(script.Parent:WaitForChild("Animate"))

local AnimIdsByRigType = {
	[Enum.HumanoidRigType.R6] = "rbxassetid://16788485937";
	[Enum.HumanoidRigType.R15] = "rbxassetid://16822595313";
}

local SlideState = {}

function SlideState.Create(): buffer
	return buffer.create(14)
end

function SlideState.Evaluate(sBuffer: buffer): boolean
	if buffer.readu8(sBuffer, 0) == 0 then return false end

	local Now = os.clock()
	local Cooldown = buffer.readu16(sBuffer, 2) * 0.001
	local Recent = buffer.readf32(sBuffer, 4)
	if (Recent + Cooldown) < Now then
		buffer.writeu8(sBuffer, 1, 1)
		buffer.writef32(sBuffer, 4, Now)
		return true
	end
	return false
end

function SlideState.IsActive(sBuffer: buffer): (boolean, number)
	local Now = os.clock()
	local Recent = buffer.readf32(sBuffer, 4)
	local Time = buffer.readu16(sBuffer, 8) * 0.001
	return (Recent + Time) > Now, (Now - Recent) / Time
end

function SlideState.Effect(Rig: Model, StateActive: boolean): ()
end

function SlideState.Animate(Rig: Model, State: boolean): AnimationTrack?
	local Humanoid = Rig:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end
	local AnimId = AnimIdsByRigType[Humanoid.RigType]
	if not AnimId then warn(Humanoid.RigType); return end

	return Animate(Rig, AnimId, Enum.AnimationPriority.Action, "Slide")
end

return table.freeze(SlideState)