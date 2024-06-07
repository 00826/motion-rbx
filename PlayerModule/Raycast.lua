local WhitelistParams				= RaycastParams.new()
WhitelistParams.FilterType			= Enum.RaycastFilterType.Whitelist
WhitelistParams.IgnoreWater			= true

local BlacklistParams				= RaycastParams.new()
BlacklistParams.FilterType			= Enum.RaycastFilterType.Blacklist
BlacklistParams.IgnoreWater			= true

local Raycast = {}

function Raycast.RayWhitelist(Origin: Vector3, Direction: Vector3, Whitelist: {Instance}): (Instance?, Vector3?, Vector3?, Enum.Material?)
	WhitelistParams.FilterDescendantsInstances = Whitelist
	local Result = workspace:Raycast(Origin, Direction, WhitelistParams)
	if Result then
		return Result.Instance, Result.Position, Result.Normal, Result.Material
	end
end

function Raycast.RayBlacklist(Origin: Vector3, Direction: Vector3, Blacklist: {Instance}): (Instance?, Vector3?, Vector3?, Enum.Material?)
	BlacklistParams.FilterDescendantsInstances = Blacklist
	local Result = workspace:Raycast(Origin, Direction, BlacklistParams)
	if Result then
		return Result.Instance, Result.Position, Result.Normal, Result.Material
	end
end

return Raycast