local BodyVelocity = script:FindFirstChildOfClass("BodyVelocity") or script:WaitForChild("BodyVelocity")

return function(Rig: Model, Direction: Vector3, Time: number?, MaxForce: Vector3?, P: number?): BodyVelocity
	local RootPart = Rig.PrimaryPart
	local BV = BodyVelocity:Clone()
	BV.Velocity = Direction
	BV.MaxForce = MaxForce or BV.MaxForce
	BV.P = P or BV.P
	BV.Parent = RootPart
	if Time then
		task.delay(Time, function() BV:Destroy() end)
	end
	return BV
end