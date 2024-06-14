local Players					= game:GetService("Players")

local Shared					= game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Vanilla					= require(Shared.Vanilla)
local Rig						= Vanilla.Rig

local function RefreshHumanoidDescription(Player)
	local Description = Rig.UpdateHumanoidDescription(Player)
	if Description then
		Vanilla.Instance.SetProperties(Description, {
			Head = "0";
			LeftArm = "0";
			LeftLeg = "0";
			RightArm = "0";
			RightLeg = "0";
			Torso = "0";
		})
	end
	return Description
end

local function ListenToHealth(Character: Model)
	local P = Players:GetPlayerFromCharacter(Character)
	local C; C = Character:GetAttributeChangedSignal("Health"):Connect(function()
		local V = Character:GetAttribute("Health")
		if V and V.X > 0 then return end

		C:Disconnect()
		Character:SetAttribute("Dead", true)
		Character:SetAttribute("Ragdoll", true)
		Character:SetAttribute("Health", Vector3.zero)

		task.delay(Players.RespawnTime, function()
			Rig.LoadCharacter(P, P:FindFirstChildOfClass("HumanoidDescription"))
		end)
	end)
end

local function ListenToHumanoid(Humanoid: Humanoid)
	local Character = Humanoid.Parent
	local C; C = Humanoid.HealthChanged:Connect(function(Health: number)
		if Character:GetAttribute("Health") == Vector3.zero then return end
		if Character:GetAttribute("Dead") == true then return end
		if Health <= 0 then
			C:Disconnect()
			Character:SetAttribute("Dead", true)
			Character:SetAttribute("Ragdoll", true)
			Character:SetAttribute("Health", Vector3.zero)
		end
	end)
end

local function PlayerAdded(Player: Player)
	if Player:GetAttribute("Connected") then return end
	Player:SetAttribute("Connected", true)

	Player.CharacterAdded:Connect(function(Character: Model)
		ListenToHealth(Character)

		local RootPart = Character.PrimaryPart or Character:WaitForChild("HumanoidRootPart")
		local Humanoid = Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid") :: Humanoid

		ListenToHumanoid(Humanoid)

		Vanilla.async(function() return Character:IsDescendantOf(workspace) end):await(function()
			Character.Parent = workspace.World.Living
			Character.PrimaryPart = RootPart
		end)

		local Desc = RefreshHumanoidDescription(Player)
		if Desc then
			Vanilla.async(function() return Humanoid:IsDescendantOf(workspace) end):await(function()
				Humanoid.BreakJointsOnDeath = false
				Humanoid:ApplyDescription(Desc)
				Character:SetAttribute("__AppliedDescription", true)

				Rig.ConnectRagdollEvent(Character)
			end)
		end
	end)
	local Desc = RefreshHumanoidDescription(Player)
	Rig.LoadCharacter(Player, Desc)
end

for _, Player in Players:GetPlayers() do
	PlayerAdded(Player)
end
Players.PlayerAdded:Connect(PlayerAdded)

return true