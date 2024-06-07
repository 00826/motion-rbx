local BodyPosition = script:FindFirstChildOfClass("BodyPosition") or script:WaitForChild("BodyPosition")

return function(Rig: Model, Position: Vector3?, Time: number?, MaxForce: Vector3?, P: number?): BodyPosition
	local RootPart = Rig.PrimaryPart
	local BP = BodyPosition:Clone()
	BP.Position = Position or Vector3.zero
	BP.MaxForce = MaxForce or BP.MaxForce
	BP.P = P or BP.P
	BP.Parent = RootPart
	if Time then
		task.delay(Time, function() BP:Destroy() end)
	end
	return BP
end