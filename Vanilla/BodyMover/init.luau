--!strict

local RunService			= game:GetService("RunService")
local Players				= game:GetService("Players")

local IsServer				= RunService:IsServer()

---### BodyMover.luau
---
---applies a bodymovers with a clean server-client connection
local BodyMover = {
	Remote					= script:WaitForChild("MoverRemote");
	Cache					= {} :: {[string]: BodyMover}
}

for _, Mover: BodyMover in script:WaitForChild("Movers"):GetChildren() do
	BodyMover.Cache[Mover.ClassName] = Mover
end

---applies BodyMover of class string `MoverClass` to Model `M`'s `PrimaryPart` for number `Lifetime` seconds \
---optional table<string, any> `Properties`
---@param M Model target model
---@param MoverClass MoverClass
---@param Properties BodyGyroProperties | BodyVelocityProperties | BodyPositionProperties | VectorForceProperties
function BodyMover.Apply(M: Model, MoverClass: string, Lifetime: number?, Properties: {[string]: any}?): BodyMover?
	local RootPart = M.PrimaryPart
	if IsServer then
		local Player = Players:GetPlayerFromCharacter(M)
		if Player then
			BodyMover.Remote:FireClient(Player, M, MoverClass, Lifetime, Properties)
			return
		end
		local Owner = RootPart:GetNetworkOwner()
		if Owner then
			BodyMover.Remote:FireClient(Owner, M, MoverClass, Lifetime, Properties)
			return
		end
	end

	local NewMover = BodyMover.Cache[MoverClass]:Clone()

	if Properties then
		for P, V in Properties do
			NewMover[P] = V
		end
	end
	if Lifetime then
		task.delay(Lifetime, function()
			NewMover:Destroy()
		end)
	end

	NewMover.Parent = RootPart
	return NewMover
end

if not IsServer then
	BodyMover.Remote.OnClientEvent:Connect(BodyMover.Apply)
end

return BodyMover