--!strict

local DSS					= game:GetService("DataStoreService")
local RunService			= game:GetService("RunService")

local IsServer				= RunService:IsServer()

local Bind					= require(script.Parent.Bind)
local BindPrefix			= "_VData"

local DataRemote			= script:WaitForChild("DataRemote");

---### Data.luau
---
---Data handler
local Data = {
	Config					= require(script.Config);
	SaveTemplate			= require(script.SaveTemplate);

	SyncCache				= {} :: typeof(require(script.SaveTemplate));
	ProfileCache			= {} :: {[Player]: any};

	LoadHook				= nil :: ((Player: Player) -> {Data: typeof(require(script.SaveTemplate))}?)?;
	ReleaseHook				= nil :: ((Player: Player) -> boolean)?;
}

if not IsServer then
	DataRemote.OnClientEvent:Connect(function(Packet: {[string]: any})
		for Key, Value in Packet do
			Data.SyncCache[Key] = Value
			Bind(BindPrefix .. Key):Fire(Value)
		end
	end)
end

---returns saved Data for Player `Player`
---@param Player? Player Player
---@returns table SavedData saved data
function Data:Get(Player: Player?): typeof(require(script.SaveTemplate))?
	if IsServer then
		return self.ProfileCache[Player].Data
	else
		return Data.SyncCache
	end
end

---reads key from Player `Player`'s saved Data
---@param Key string target key
---@param Player? Player Player
---@return any Value any
function Data:ReadKey(Key: string, Player: Player?): any
	if IsServer then
		return self.ProfileCache[Player].Data[Key]
	else
		return Data.SyncCache[Key]
	end
end

---syncs saved Data for Player `Player`
---@param Player Player Player
---@param Keys string[]|nil array of keys to compile (empty = sync all)
---@vararg string data keys
function Data.Sync(Player: Player, Keys: {string?}?)
	if IsServer then
		local SaveData = Data.ProfileCache[Player].Data
		local Packet = {}

		if not Keys or #Keys <= 0 then
			for _, Key in Data.Config.SyncKeys do
				Packet[Key] = SaveData[Key]
			end
		else
			for _, Key in Keys do
				Packet[Key] = SaveData[Key]
			end
		end

		DataRemote:FireClient(Player, Packet)
	else
		warn("Data.Sync() can only be called on server")
	end
end

---wipes data for UserId's in the form of string IdString \
---formatted as either:
---```
---"24103210 12345 67890"
---or
---"24103210, 12345, 67890"
---```
---@param IdString string string of UserId's separated with anything that is not a number
function Data.Wipe(IdString: string)
	local DataStore = DSS:GetDataStore(Data.Config.DataStoreName)
	if RunService:IsStudio() and RunService:IsEdit() and DataStore then
		local _, n = IdString:gsub("%d+", function(LazyId)
			LazyId ..= Data.Config.SaveKey
			DataStore:RemoveAsync(LazyId)
			print(("Wiped data key %s"):format(LazyId))
			return LazyId
		end)
		print(("%d entries wiped"):format(n))
	else
		error("Data.Wipe() can only be called in a studio-edit environment")
	end
end

---binds function `f` to listen to changes in table<string, any> for key string `Key`
---```
-----works like:
---Data.SyncCache:GetValueChangedSignal(Key):Connect(f)
---```
---@param Key string
---@param f fun(Value: any)
---@return function Disconnect disconnect function
function Data.ListenTo(Key: string, f: (Value: any) -> ())
	if IsServer then
		error("Data.ListenTo() can only be called on client")
	else
		Bind(BindPrefix .. Key):Connect(f)
	end
end

---reads budget for request type
function Data.ReadBudget(RequestType: Enum.DataStoreRequestType): number
	return DSS:GetRequestBudgetForRequestType(RequestType)
end

return Data