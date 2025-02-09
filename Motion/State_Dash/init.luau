local Animate = require(script.Parent:WaitForChild("Animate"))

local AnimIdsByRigType = {
	[Enum.HumanoidRigType.R6] = "rbxassetid://12860993465";
	[Enum.HumanoidRigType.R15] = "rbxassetid://15293196922";
}

local DashState = {}

function DashState.Create(): buffer
	return buffer.create(14)
end

function DashState.Evaluate(dBuffer: buffer): boolean
	if buffer.readu8(dBuffer, 0) == 0 then return false end

	local Now = os.clock()
	local Cooldown = buffer.readu16(dBuffer, 2) * 0.001
	local Recent = buffer.readf32(dBuffer, 4)
	if (Recent + Cooldown) < Now then
		buffer.writef32(dBuffer, 4, Now)
		return true
	end
	return false
end

function DashState.IsActive(dBuffer: buffer): boolean
	local Now = os.clock()
	local Recent = buffer.readf32(dBuffer, 4)
	local Time = buffer.readu16(dBuffer, 8) * 0.001
	return (Recent + Time) > Now
end

function DashState.Effect(Rig: Model, StateActive: boolean): ()
end

function DashState.Animate(Rig: Model, State: boolean): AnimationTrack?
	local Humanoid = Rig:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end
	local AnimId = AnimIdsByRigType[Humanoid.RigType]
	if not AnimId then warn(Humanoid.RigType); return end

	return Animate(Rig, AnimId, Enum.AnimationPriority.Action2, "Dash")
end

return table.freeze(DashState)