--!strict

local RunService			= game:GetService("RunService")
local IsServer				= RunService:IsServer()

local Prefix				= "___STREAM_"
local InString				= Prefix .. "InDestination"
local OutString				= Prefix .. "OutDestination"
local PivotString			= Prefix .. "Pivot"

local ObjectValue			= script:WaitForChild("ObjectValue")

---### Stream.luau
---
---granular, customizable, client-authoritative streaming/rendering module
local Stream = {
	StreamInCallback		= nil :: ((Thing: Instance) -> ())?;
	StreamOutCallback		= nil :: ((Thing: Instance) -> ())?;
}

---registers stream destination Instance `Destination` under string `DestinationId`
---@param DestinationId string DestinationId
---@param Destination Instance Destination Instance
---@return string DestinationId DestinationId
function Stream.RegisterDestination(DestinationId: string, Destination: Instance): string?
	if IsServer then
		local OValue = script:FindFirstChild(DestinationId) :: any
		if not OValue then
			OValue = ObjectValue:Clone()
			OValue.Parent = script
			OValue.Name = DestinationId
		end
		OValue.Value = Destination
		return DestinationId
	else
		warn("RegisterDestination() can only be called on server")
	end
	return nil
end

---returns Instance `Destination` by string `DestinationId` as registered with `Stream.RegisterDestination()`
---@param DestinationId string DestinationId
---@return Instance Destination Destination Instance
function Stream.GetDestination(DestinationId: string): Instance
	assert(script[DestinationId], "destination not registered " .. (DestinationId or "nil"))
	return script[DestinationId].Value
end

---sets StreamInDestination for Instance `Thing` to string `DestinationId`
---@param Thing Instance
---@param DestinationId string
function Stream.SetStreamInDestination(Thing: Instance, DestinationId: string)
	Thing:SetAttribute(InString, DestinationId)
end

---returns Instance `Thing`'s assigned StreamInDestination string `DestinationId`
---@param Thing Instance target instance
---@return string DestinationId DestinationId
function Stream.GetStreamInDestination(Thing: Instance): string
	return Thing:GetAttribute(InString)
end

---sets StreamOutDestination for Instance `Thing` to string `DestinationId`
---@param Thing Instance
---@param DestinationId string
function Stream.SetStreamOutDestination(Thing: Instance, DestinationId: string)
	Thing:SetAttribute(OutString, DestinationId)
end

---returns Instance `Thing`'s assigned StreamOutDestination string `DestinationId`
---@param Thing Instance target instance
---@return string DestinationId DestinationId
function Stream.GetStreamOutDestination(Thing: Instance): string
	return Thing:GetAttribute(OutString)
end

---parents Instance `Thing` to its assigned StreamInDestination
---@param Thing Instance target instance
function Stream.StreamIn(Thing: Instance)
	local DestId = Stream.GetStreamInDestination(Thing)
	Thing.Parent = Stream.GetDestination(DestId)
	if Thing:IsA("PVInstance") then
		Thing:PivotTo(Stream.GetPivot(Thing))
	end

	if Stream.StreamInCallback and getfenv(Stream.StreamInCallback).script.Parent ~= nil then
		task.defer(Stream.StreamInCallback, Thing)
	end
end

---parents Instance `Thing` to its assigned StreamOutDestination
---@param Thing Instance target instance
function Stream.StreamOut(Thing: Instance)
	local DestId = Stream.GetStreamOutDestination(Thing)
	Thing.Parent = Stream.GetDestination(DestId)

	if Stream.StreamOutCallback and getfenv(Stream.StreamOutCallback).script.Parent ~= nil then
		task.defer(Stream.StreamOutCallback, Thing)
	end
end

---returns `true` if Instance `Thing` is parented to its StreamInDestination
---@param Thing Instance target instance
---@return boolean IsStreamedIn IsStreamedIn
function Stream.IsStreamedIn(Thing: Instance): boolean
	local DestId = Stream.GetStreamInDestination(Thing)
	return Thing:IsDescendantOf(Stream.GetDestination(DestId))
end

---updates a pivot CFrame attribute for PVInstance `Thing` for internal use by Stream.luau
---@param Thing PVInstance PVInstance
function Stream.UpdatePivot(Thing: PVInstance)
	if not Thing:IsA("PVInstance") then
		warn("Attempt to call UpdatePivot() on a non-PVInstance instance")
		return
	end
	if IsServer then
		Thing:SetAttribute(PivotString, Thing:GetPivot())
	else
		Thing:PivotTo(Thing:GetAttribute(PivotString) or Thing:GetPivot())
	end
end

---returns CFrame `Pivot` set by `Stream.UpdatePivot(Thing)` (default: Thing:GetPivot()) \
---this is used (in conjunction with `Stream.UpdatePivot`) as a workaround for CFrame values not replicating in ReplicatedStorage \
---basically, whenever a model is parented into ReplicatedStorage, its pivot property is paused at where it was prior to being parented to ReplicatedStorage \
---a video made on [effectively loading/offloading characters](https://www.youtube.com/watch?v=qzTxWdbJrKs) \
---...uses an UpdatePivot() function called at a set interval so that when an instance is streamed in, it'll be closer to its actual cframe and not at the cframe when it was streamed out
---@param Thing PVInstance
---@return CFrame Pivot CFrame
function Stream.GetPivot(Thing: PVInstance): CFrame
	return Thing:GetAttribute(PivotString) or Thing:GetPivot()
end

---creates folder
---@param Name string folder name
---@param Parent Instance folder parent
function Stream.CreateFolder(Name: string, Parent: Instance): Folder
	local F = Instance.new("Folder")
	F.Name = Name
	F.Parent = Parent
	return F
end

return Stream