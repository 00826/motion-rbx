local Animation = script:WaitForChild("Animation")

return function(Rig: Model, AnimationId: string, Priority: Enum.AnimationPriority?, Name: string?): AnimationTrack?
	local Humanoid = Rig:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end
	local Animator = Humanoid:FindFirstChildOfClass("Animator")
	if not Animator then return end

	Animation.AnimationId = AnimationId
	local AnimTrack = Animator:LoadAnimation(Animation)
	AnimTrack.Name = Name or "MotionTrack_" .. AnimationId
	AnimTrack.Priority = Priority or Enum.AnimationPriority.Action
	AnimTrack:Play()

	return AnimTrack
end