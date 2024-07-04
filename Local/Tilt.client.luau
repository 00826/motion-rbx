--!strict

local RunService				= game:GetService("RunService")
local TS						= game:GetService("TweenService")

local Player					= game:GetService("Players").LocalPlayer
local Character					= Player.Character or Player.CharacterAdded:Wait()
local RootPart					= Character.PrimaryPart or Character:WaitForChild("HumanoidRootPart")
local Humanoid					= Character:WaitForChild("Humanoid")
local RigType					= Humanoid.RigType

local NeckMotor					= nil :: Motor6D?
local TorsoMotor				= nil :: Motor6D?

local NeckRotation				= CFrame.identity
local TorsoRotation				= CFrame.identity

local Dampening					= 5
local NeckDampening				= 4
local TweenTime					= 0.2
local Vector3_xzAxis			= Vector3.one - Vector3.yAxis

local Velocity					= nil
local Direction					= nil
local TorsoAngle				= nil
local NeckAngle					= nil

if RigType == Enum.HumanoidRigType.R6 then
	local Torso = Character:WaitForChild("Torso")

	NeckMotor = Torso:WaitForChild("Neck")
	TorsoMotor = RootPart:WaitForChild("RootJoint")
elseif RigType == Enum.HumanoidRigType.R15 then
	local Torso = Character:WaitForChild("LowerTorso")
	local Head = Character:WaitForChild("Head")

	NeckMotor = Head:WaitForChild("Neck")
	TorsoMotor = Torso:WaitForChild("Root")
else
	warn(RigType)
	return
end

assert(NeckMotor)
assert(TorsoMotor)

NeckRotation = CFrame.new(0, 0, 0, select(4, NeckMotor.C0:GetComponents()))
TorsoRotation = CFrame.new(0, 0, 0, select(4, TorsoMotor.C0:GetComponents()))

local function Tween(Object: Instance, Properties: {[string]: any}, Time: number, ...)
	TS:Create(Object, TweenInfo.new(Time, ...), Properties):Play()
end

local function Tilt()
	Velocity = RootPart.AssemblyLinearVelocity * Vector3_xzAxis
	if Velocity.Magnitude > 2 then
		Direction = Velocity.Unit
		local DotProduct = RootPart.CFrame.RightVector:Dot(Direction)
		TorsoAngle = DotProduct / Dampening
		NeckAngle = DotProduct / NeckDampening
	else
		TorsoAngle = 0
		NeckAngle = 0
	end

	---tween .Transform property when the property is actually writable
	if RigType == Enum.HumanoidRigType.R6 then
		Tween(TorsoMotor, {C0 = CFrame.new(TorsoMotor.C0.Position) * NeckRotation * CFrame.Angles(0, -TorsoAngle, 0)}, TweenTime, Enum.EasingStyle.Sine)
		Tween(NeckMotor, {C0 = CFrame.new(NeckMotor.C0.Position) * TorsoRotation * CFrame.Angles(0, NeckAngle, 0)}, TweenTime, Enum.EasingStyle.Sine)
	elseif RigType == Enum.HumanoidRigType.R15 then
		Tween(TorsoMotor, {C0 = CFrame.new(TorsoMotor.C0.Position) * NeckRotation * CFrame.Angles(0, 0, -TorsoAngle)}, TweenTime, Enum.EasingStyle.Sine)
		Tween(NeckMotor, {C0 = CFrame.new(NeckMotor.C0.Position) * TorsoRotation * CFrame.Angles(0, NeckAngle, 0)}, TweenTime, Enum.EasingStyle.Sine)
	end
end

RunService.Heartbeat:Connect(Tilt)