local WhitelistParams				= RaycastParams.new()
WhitelistParams.FilterType			= Enum.RaycastFilterType.Include
WhitelistParams.IgnoreWater			= true

local BlacklistParams				= RaycastParams.new()
BlacklistParams.FilterType			= Enum.RaycastFilterType.Exclude
BlacklistParams.IgnoreWater			= true

local Raycast = {}

---casts a whitelist raycast at Vector3 `Origin` towards Vector3 `Direction` with Instance[] whitelist `Whitelist`
---@param Origin Vector3 Origin of Raycast
---@param Direction Vector3 Direction of Raycast
---@param Whitelist Instance[] array of Instances to Raycast against
---@return RaycastResult Result RaycastResult
function Raycast.RayWhitelist(Origin: Vector3, Direction: Vector3, Whitelist: {Instance}): RaycastResult
	WhitelistParams.FilterDescendantsInstances = Whitelist
	return workspace:Raycast(Origin, Direction, WhitelistParams)
end

---casts a whitelist raycast at Vector3 `Origin` towards Vector3 `Direction` with Instance[] blacklist `Blacklist`
---@param Origin Vector3 Origin of Raycast
---@param Direction Vector3 Direction of Raycast
---@param Blacklist Instance[] array of Instances to not Raycast against
---@return RaycastResult Result RaycastResult
function Raycast.RayBlacklist(Origin: Vector3, Direction: Vector3, Blacklist: {Instance}): RaycastResult
	BlacklistParams.FilterDescendantsInstances = Blacklist
	return workspace:Raycast(Origin, Direction, BlacklistParams)
end

return Raycast