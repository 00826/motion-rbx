--!strict

---### CFrame.luau
---
---extension of lua Vector3 library
local V_CFrame = {}

---applies axis `Axis` of CFrame `CopyFrom` to CFrame or Vector3 `Base` \
---if no axis is passed, then all rotational components will be applied
---@param Base CFrame | Vector3 base value
---@param CopyFrom CFrame rotation to be copied from
---@param Axis? Axis target axis
---@return CFrame CFrame CFrame
function V_CFrame.ApplyAxis(Base: CFrame | Vector3, CopyFrom: CFrame, Axis: ("X" | "Y" | "Z")?): CFrame
	if not Axis then
		return CFrame.new(Base.X, Base.Y, Base.Z, select(4, CopyFrom:GetComponents()))
	else
		local X, Y, Z = CopyFrom:ToOrientation()
		local C0 = CFrame.new(Base.X, Base.Y, Base.Z)
		if Axis == "X" then
			return C0 * CFrame.Angles(X, 0, 0)
		elseif Axis == "Y" then
			return C0 * CFrame.Angles(0, Y, 0)
		elseif Axis == "Z" then
			return C0 * CFrame.Angles(0, 0, Z)
		end
	end
	return CFrame.identity
end

---returns a blank `CFrame` rotated by unit vector Vector3 `UV`
---@param UV Vector3 unit vector
---@return CFrame UVCFrame CFrame
function V_CFrame.FromUnitVector(UV: Vector3): CFrame
	return CFrame.new(Vector3.zero, Vector3.zero + UV)
end

---returns a `CFrame` at position Vector3 `V` rotated by unit vector Vector3 `UV`
---@param V Vector3 position
---@param UV Vector3 unit vector
---@return CFrame CFrame CFrame
function V_CFrame.LookIn(V: Vector3, UV: Vector3): CFrame
	return CFrame.lookAt(V, V + UV)
end

---returns boolean `IsPointInVolume` if Vector3 `Point` is within volume bounds defined by CFrame `VolumeCFrame` and Size `VolumeSize`
---@param Point Vector3 target point
---@param VolumeCFrame CFrame volume cframe
---@param VolumeSize Vector3 volume size
---@return boolean IsPointInVolume IsPointInVolume
function V_CFrame.IsPointInVolume(Point: Vector3, VolumeCFrame: CFrame, VolumeSize: Vector3): boolean
	local ObjectSpace = VolumeCFrame:PointToObjectSpace(Point)
	VolumeSize *= 0.5
	return
		(math.abs(ObjectSpace.X) <= VolumeSize.X) and
		(math.abs(ObjectSpace.Y) <= VolumeSize.Y) and
		(math.abs(ObjectSpace.Z) <= VolumeSize.Z)
end

return table.freeze(V_CFrame)