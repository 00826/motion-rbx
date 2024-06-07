local Animate = require(script.Parent:WaitForChild("Animate"))

local AnimIdsByRigType = {
	[Enum.HumanoidRigType.R6] = "rbxassetid://9369552093";
	[Enum.HumanoidRigType.R15] = "rbxassetid://15293210459";
}

local JumpAuxState = {}

---@diagnostic disable-next-line: undefined-type
function JumpAuxState.Create(): buffer
	return buffer.create(14)
end

---@diagnostic disable-next-line: undefined-type
function JumpAuxState.Evaluate(jaBuffer: buffer): boolean
	if buffer.readu8(jaBuffer, 0) == 0 then return false end
	if buffer.readu8(jaBuffer, 12) >= buffer.readu8(jaBuffer, 13) then return false end

	local Now = os.clock()
	local Cooldown = buffer.readu16(jaBuffer, 6) * 0.001
	local Recent = buffer.readf32(jaBuffer, 8)
	if (Recent + Cooldown) < Now then
		buffer.writef32(jaBuffer, 8, Now)
		return true
	end
	return false
end

function JumpAuxState.Effect(Rig: Model, StateActive: boolean): ()
end

function JumpAuxState.Animate(Rig: Model, State: boolean): AnimationTrack?
	local Humanoid = Rig:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end
	local AnimId = AnimIdsByRigType[Humanoid.RigType]
	if not AnimId then warn(Humanoid.RigType) return end

	return Animate(Rig, AnimId, nil, "JumpAux")
end

return table.freeze(JumpAuxState)