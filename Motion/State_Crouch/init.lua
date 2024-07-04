local RigMotorOrientations = table.freeze{
	[Enum.HumanoidRigType.R6] = {
		[true] = table.freeze{
			NeckC1 = CFrame.fromOrientation(math.rad(-45), math.rad(-180), 0);
			RootC1 = CFrame.fromOrientation(math.rad(-45), 0, math.rad(180));
			LeftHipC1 = CFrame.fromOrientation(0, math.rad(-90), math.rad(45));
			RightHipC1 = CFrame.fromOrientation(0, math.rad(90), math.rad(-45));
		};
		[false] = table.freeze{
			NeckC1 = CFrame.fromOrientation(math.rad(-90), math.rad(-180), 0);
			RootC1 = CFrame.fromOrientation(math.rad(-90), math.rad(180), 0);
			LeftHipC1 = CFrame.fromOrientation(0, math.rad(-90), 0);
			RightHipC1 = CFrame.fromOrientation(0, math.rad(90), 0);
		};
	};
	[Enum.HumanoidRigType.R15] = {
		[true] = table.freeze{
			NeckC1 = CFrame.fromOrientation(math.rad(-45), 0, 0);
			RootC1 = CFrame.fromOrientation(math.rad(45), 0, 0);
			LeftHipC1 = CFrame.fromOrientation(math.rad(-45), 0, 0);
			RightHipC1 = CFrame.fromOrientation(math.rad(-45), 0, 0);
		};
		[false] = table.freeze{
			NeckC1 = CFrame.identity; --CFrame.fromOrientation(0, 0, 0);
			RootC1 = CFrame.identity; --CFrame.fromOrientation(0, 0, 0);
			LeftHipC1 = CFrame.identity; --CFrame.fromOrientation(0, 0, 0);
			RightHipC1 = CFrame.identity; --CFrame.fromOrientation(0, 0, 0);
		};
	};
}

local function ApplyOrientation(Motor: Motor6D?, Orientation: CFrame): boolean
	if Motor then
		Motor.C1 = CFrame.new(Motor.C1.Position) * Orientation
		return true
	end
	return false
end

local CrouchState = {}

---@diagnostic disable-next-line: undefined-type
function CrouchState.Create(): buffer
	return buffer.create(8)
end

---@diagnostic disable-next-line: undefined-type
function CrouchState.Evaluate(cBuffer: buffer, DesiredState: boolean): boolean
	if buffer.readu8(cBuffer, 0) == 0 then return false end

	local Active = buffer.readu8(cBuffer, 1) == 1
	if DesiredState == Active then return false end

	local Now = os.clock()

	if DesiredState == false then
		buffer.writeu8(cBuffer, 1, 0)
		buffer.writef32(cBuffer, 4, Now)
		return true
	else
		local Cooldown = buffer.readu16(cBuffer, 2) * 0.001
		local Recent = buffer.readf32(cBuffer, 4)
		if (Recent + Cooldown) < Now then
			buffer.writeu8(cBuffer, 1, 1)
			buffer.writef32(cBuffer, 4, Now)
			return true
		end
	end

	return false
end

function CrouchState.Effect(Rig: Model, StateActive: boolean): ()
	local Humanoid = Rig:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end

	local OrientationTable = RigMotorOrientations[Humanoid.RigType]
	if not OrientationTable then warn(Humanoid.RigType); return end
	local StateRotations = OrientationTable[StateActive]

	if Humanoid.RigType == Enum.HumanoidRigType.R6 then
		local Torso = Rig:FindFirstChild("Torso")
		if Torso then
			ApplyOrientation(Torso:FindFirstChild("Neck"), StateRotations.NeckC1)
			ApplyOrientation(Torso:FindFirstChild("Left Hip"), StateRotations.LeftHipC1)
			ApplyOrientation(Torso:FindFirstChild("Right Hip"), StateRotations.RightHipC1)
		end

		local RootPart = Rig:FindFirstChild("HumanoidRootPart")
		if RootPart then
			ApplyOrientation(RootPart:FindFirstChild("RootJoint"), StateRotations.RootC1)
		end

		if StateActive == true then
			Humanoid.HipHeight = -0.28 * Rig:GetScale()
		else
			Humanoid.HipHeight = 0
		end
	elseif Humanoid.RigType == Enum.HumanoidRigType.R15 then
		local Head = Rig:FindFirstChild("Head")
		if Head then
			ApplyOrientation(Head:FindFirstChild("Neck"), StateRotations.NeckC1)
		end

		local LeftUpperLeg = Rig:FindFirstChild("LeftUpperLeg")
		if LeftUpperLeg then
			ApplyOrientation(LeftUpperLeg:FindFirstChild("LeftHip"), StateRotations.LeftHipC1)
		end
		local RightUpperLeg = Rig:FindFirstChild("RightUpperLeg")
		if RightUpperLeg then
			ApplyOrientation(RightUpperLeg:FindFirstChild("RightHip"), StateRotations.RightHipC1)
		end

		local LowerTorso = Rig:FindFirstChild("LowerTorso")
		if LowerTorso then
			ApplyOrientation(LowerTorso:FindFirstChild("Root"), StateRotations.RootC1)
		end
	end
end

return table.freeze(CrouchState)