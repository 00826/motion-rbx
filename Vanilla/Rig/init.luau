--!strict

local Players				= game:GetService("Players")
local RunService			= game:GetService("RunService")
local IsServer				= RunService:IsServer()

local AccessoryPart			= script:WaitForChild("AccessoryPart")
local Ball					= script:WaitForChild("BallSocketConstraint")
local Motor					= script:WaitForChild("Motor6D")
local Weld					= script:WaitForChild("Weld")

local RagdollLimbs			= {
	[Enum.HumanoidRigType.R6]		= {
		--[["Head";
		"Left Arm";
		"Left Foot";
		"Right Arm";
		"Right Foot";
		"Torso";]]
	};
	[Enum.HumanoidRigType.R15]		= {
		"Head";
		"LeftHand";
		"RightHand";
		"LeftFoot";
		"RightFoot";
	};
}

local RagdollMotors			= {
	[Enum.HumanoidRigType.R6]		= {
		"Neck";
		"Right Shoulder";
		"Left Shoulder";
		"Right Hip";
		"Left Hip";
	};
	[Enum.HumanoidRigType.R15]		= {
		"Neck";
		"RightShoulder";
		"LeftShoulder";
		"RightHip";
		"LeftHip";
	};
}

---### Rig.luau
---
---handler for motor6d-based rigs \
---some functions work with any rig
local Rig = {}

---returns table containing all components of Client `Player`
---@param Client? Player target player, if called locally defaults to localplayer
function Rig.Components(Client: Player?)
	if not IsServer and not Client then
		Client = Players.LocalPlayer
	end
	if not Client then return {} end

	local Character = Client.Character or Client.CharacterAdded:Wait()
	return {
		Player = Client;
		Character = Character;
		RootPart = Character.PrimaryPart or Character:WaitForChild("HumanoidRootPart");
		Humanoid = Character:WaitForChild("Humanoid");
	}
end

---memory-safe Player:LoadCharacter() on Player `Player` \
---optional function `F` that returns a `HumanoidDescription`
---@param Player Player Player
---@param HumanoidDescription HumanoidDescription HumanoidDescription
function Rig.LoadCharacter(Player: Player, HumanoidDescription: HumanoidDescription?)
	if Player.Character then
		Player.Character:Destroy()
		Player.Character = nil
	end
	if IsServer then
		if HumanoidDescription then
			Player:LoadCharacterWithHumanoidDescription(HumanoidDescription)
		else
			Player:LoadCharacter()
		end
	end
end

---updates Player `Player`'s character description; automatically parents it to `Player`
---@param Player Player target player
---@return HumanoidDescription HumanoidDescription HumanoidDescription
function Rig.UpdateHumanoidDescription(Player: Player): HumanoidDescription?
	local UserId = Player.UserId
	if UserId < 1 then return nil end -- Players in test mode throw errors as their UserId's are negative

	local Current = Player:FindFirstChildOfClass("HumanoidDescription")
	if Current then
		Current:Destroy()
	end

	local New = Players:GetHumanoidDescriptionFromUserId(UserId)
	New.Parent = Player
	return New
end

---@class MeshProperties
---@field MeshId string
---@field TextureId string
---@field Offset Vector3
---@field Scale Vector3
---@field VertexColor Vector3

--[[ CFrame.new(0, 0, 0) * CFrame.fromOrientation(math.rad(0), math.rad(0), math.rad(0)) ]]

---creates new BasePart `AccessoryPart`
---@param Name string name of new AccessoryPart
---@param C0 CFrame `AccessoryPart.Attachment.CFrame`
---@param MeshProperties MeshProperties MeshProperties
function Rig.CreateAccessoryPart(Name: string, C0: CFrame, MeshProperties: {}): BasePart
	local NewPart = AccessoryPart:Clone()
	NewPart.Name = Name

	local Attachment = AccessoryPart:FindFirstChildOfClass("Attachment")
	if Attachment then
		Attachment.CFrame = C0
	end

	local SpecialMesh = AccessoryPart:FindFirstChildOfClass("SpecialMesh")
	if SpecialMesh then
		for Property, Value in MeshProperties do
			SpecialMesh[Property] = Value
		end
	end

	return NewPart
end

---attaches AccessoryPart `AccessoryPart` to Rig `Character` \
---enables client-authoritative accessory control, as it should be :P
---@param Character Model target character
---@param APart AccessoryPart AccessoryPart
---@param AttachmentRef string AttachmentRef
---@param Parent? Instance APart.Parent (default: Character)
---@return boolean AttachSuccess AttachSuccess
function Rig.AttachAccessoryPart(Character: Model, APart: BasePart, AttachmentRef: string, Parent: Instance?): boolean
	local A0 = Character:FindFirstChild(AttachmentRef, true) :: Attachment
	if not A0 then return false end
	if not A0:IsA("Attachment") then return false end
	local A1 = APart:FindFirstChildOfClass("Attachment") :: Attachment?
	if not A1 then return false end
	APart.CFrame = A0.WorldCFrame * A1.CFrame:Inverse()

	local W = Weld:Clone()
	W.Part0 = APart
	W.Part1 = A0.Parent
	W.Parent = APart

	APart.Parent = Parent or Character
	return true
end

---disables Enum.HumanoidStateType[] array `States` for Humanoid `Humanoid`
---@param Humanoid Humanoid Humanoid
---@param States Enum.HumanoidStateType[] Humanoid states to disable
function Rig.DisableHumanoidStates(Humanoid: Humanoid, States: {Enum.HumanoidStateType})
	for _, State: Enum.HumanoidStateType in States do
		Humanoid:SetStateEnabled(State, false)
	end
end

---connects ragdoll event to rig Model `Character` \
---should be connected on both client & server because of weird network ownership interactions
---@param Character Model target character
function Rig.ConnectRagdollEvent(Character: Model)
	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	if not Humanoid then warn(`Humanoid not found in {Character}`) return end
	Character:GetAttributeChangedSignal("Ragdoll"):Connect(function()
		if Character:GetAttribute("Ragdoll") == true then
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
			Rig.ToggleRagdollCollisions(Character, Humanoid.RigType, true)
			if not IsServer then return end
			Rig.Ragdoll(Character, true)
		else
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			Rig.ToggleRagdollCollisions(Character, Humanoid.RigType, false)
			if not IsServer then return end
			Rig.Ragdoll(Character, false)
		end
	end)
end

---ragdolls rig Model `Character` with ragdoll state boolean `State` (default: false) \
---compatible with any rig constructed with Motor6D
---@param Character Model target character
---@param State? boolean ragdoll state (default: `false`)
function Rig.Ragdoll(Character: Model, State: boolean?)
	if not IsServer then
		warn("call .Ragdoll on server")
		return
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end

	local TargetMotors = RagdollMotors[Humanoid.RigType]

	if State == true then
		Humanoid.Sit = true
		Humanoid.RequiresNeck = false
		for _, Motor6D: Motor6D|any in Character:GetDescendants() do
			if not Motor6D:IsA("Motor6D") then continue end
			if not table.find(TargetMotors, Motor6D.Name) then continue end
			Motor6D.Part1:SetAttribute("MotorRef", Motor6D.Name)
			local Socket: BallSocketConstraint = Ball:Clone()
			local A0, A1 = Instance.new("Attachment"), Instance.new("Attachment")
			A0.Parent = Motor6D.Part0
			A1.Parent = Motor6D.Part1
			Socket.Attachment0 = A0
			Socket.Attachment1 = A1
			A0.CFrame = Motor6D.C0
			A1.CFrame = Motor6D.C1
			Socket.Parent = Motor6D.Parent
			Motor6D:Destroy()
		end
	else
		for _, BallSocket: any in Character:GetDescendants() do
			if not BallSocket:IsA("BallSocketConstraint") then continue end
			BallSocket.UpperAngle = 0
			BallSocket.TwistUpperAngle = 0
			BallSocket.TwistLowerAngle = 0
			local Motor6D = Motor:Clone()
			Motor6D.Part0 = BallSocket.Attachment0.Parent
			Motor6D.Part1 = BallSocket.Attachment1.Parent
			Motor6D.C0 = BallSocket.Attachment0.CFrame
			Motor6D.C1 = BallSocket.Attachment1.CFrame
			Motor6D.Name = Motor6D.Part1:GetAttribute("MotorRef")
			Motor6D.Parent = BallSocket.Parent
			BallSocket.Attachment0:Destroy()
			BallSocket.Attachment1:Destroy()
			BallSocket:Destroy()
		end
		Humanoid.Sit = false
		Humanoid.RequiresNeck = true
	end
	Rig.ToggleRagdollCollisions(Character, Humanoid.RigType, State or false)
end

function Rig.ToggleRagdollCollisions(Character: Model, RigType: Enum.HumanoidRigType, State: boolean)
	for _, Limb in RagdollLimbs[RigType] do
		local P = Character:FindFirstChild(Limb :: string)
		if not P then continue end
		if not P:IsA("BasePart") then continue end
		P.CanCollide = State or false
	end
end

return Rig