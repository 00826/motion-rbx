--!strict

local Players				= game:GetService("Players")

local IsServer				= game:GetService("RunService"):IsServer()

local async					= require(script.Parent.async)

---### Network.luau
---
---`RemoteEvent` wrapper
---
---offers ease-of-use without the hassle of having to reference Remotes in every script
local Network = {
	Cache = {} :: {[string]: RemoteEvent};
	InvokeTimeout = 3;
}

script.ChildAdded:Connect(function(Remote: RemoteEvent)
	Network.Cache[Remote.Name] = Remote
end)
for _, Remote: RemoteEvent in script:GetChildren() do
	Network.Cache[Remote.Name] = Remote
end

---connects new RemoteEvent named by string `Remote` and binds .OnClientEvent/.OnServerEvent to function `Callback` \
---optional boolean `Yield` \
---optional boolean `Unreliable` to make the remote an UnreliableRemoteEvent
---@param Remote string remote name
---@param Callback? fun(...)
---@param Yield? boolean reference Remote with WaitForChild(Remote)
---@param Unreliable? boolean UnreliableRemoteEvent
---@return RBXScriptConnection RemoteEventConnection RemoteEventConnection
function Network:Connect(Remote: string, Callback: ((...any) -> ())?, Yield: boolean?, Unreliable: boolean?): RBXScriptConnection?
	local RemoteObject = Network.Cache[Remote]

	if IsServer then
		if not RemoteObject then
			local NewRemote = Instance.new(Unreliable and "UnreliableRemoteEvent" or "RemoteEvent")
			NewRemote.Name = Remote
			NewRemote.Parent = script

			RemoteObject = NewRemote
		end
		if Callback then
			return RemoteObject.OnServerEvent:Connect(Callback)
		end
	else
		if Yield and not RemoteObject then
			RemoteObject = script:WaitForChild(Remote)
			Network.Cache[Remote] = RemoteObject
		end
		if Callback then
			return RemoteObject.OnClientEvent:Connect(Callback)
		end
	end
	return
end

---fires RemoteEvent named string `Remote` connected by `Network:Connect(Remote)` \
---`RemoteEvent:FireServer()`
---@param Remote string remote name
---@vararg any
function Network:FireServer(Remote: string, ...: any)
	Network.Cache[Remote]:FireServer(...)
end

---fires RemoteEvent named string `Remote` connected by `Network:Connect(Remote)` to PlayerArg `PlayerArg` \
---can be a player, array of players, function that filters players, or no player \
---`RemoteEvent:FireAllClients()` but with more control over "AllClients"
---@param Remote string remote name
---@param PlayerArg any
---@vararg string args to send to clients
---
---@overload fun(Remote: string, PlayerArg: Player, ...)
---@overload fun(Remote: string, PlayerArg: Player[], ...)
---@overload fun(Remote: string, PlayerArg: fun(Player: Player):boolean, ...)
---@overload fun(Remote: string, PlayerArg: any|nil, ...)
function Network:FireClients(Remote: string, PlayerArg: any, ...)
	local RemoteObject: RemoteEvent = Network.Cache[Remote]

	local t = type(PlayerArg)
	if t == "userdata" then
		RemoteObject:FireClient(PlayerArg, ...)
	elseif t == "table" then
		if #PlayerArg == 0 then
			RemoteObject:FireAllClients(...)
		else
			for _, Player in PlayerArg do
				RemoteObject:FireClient(Player, ...)
			end
		end
	elseif t == "function" then
		for _, Player in Players:GetPlayers() do
			if not PlayerArg(Player) then continue end
			RemoteObject:FireClient(Player, ...)
		end
	elseif t == "nil" then
		RemoteObject:FireAllClients(...)
	end
end

--[[
	RemoteFunctions are slow and infinitely yield if an error is thrown
	RemoteEvent.OnClientEvent:Wait() doesnt have a timeout parameter and also infinitely yields if an error is thrown
]]

---fires RemoteEvent named string `Remote` connected by `Network:Connect(Remote)` and yields for a server response from that same RemoteEvent
---@param Remote string remote name
---@return ...
function Network:Invoke(Remote: string, ...: any?): ...any?
	local RemoteObject: RemoteEvent = Network.Cache[Remote]
	local Packet = nil

	local C = RemoteObject.OnClientEvent:Once(function(...) Packet = {...} end)
	RemoteObject:FireServer(...)

	async(function() return Packet ~= nil end):await(nil, nil, Network.InvokeTimeout)

	if C then C:Disconnect() end

	return Packet and unpack(Packet) or nil
end

return Network