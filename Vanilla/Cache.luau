--!strict

local Cache					= {}

local C = {__index = {}}
C.__len = function(self)
	return #self.Items
end
C.__iter = function(self)
	return pairs(self.Items)
end

---returns index or nil of `Thing` in cached items, if any
---@param Thing any target thing
---@return number? ItemIdx item index
function C.__index:FindItem(Thing: any): number?
	return table.find(self.Items, Thing)
end

---adds `Thing` to cached items
---@param Thing any target thing
function C.__index:AddItem(Thing: any): ()
	if self.Filter then
		if not self.Filter(Thing) then return end
	end

	if not table.find(self.Items, Thing) then
		table.insert(self.Items, Thing)

		for _, f in self.AddedListeners do
			if getfenv(f).script.Parent == nil then
				table.remove(self.AddedListeners, table.find(self.AddedListeners, f) or 0)
				continue
			end
			task.defer(f, Thing)
		end
	end
end

---fires function `f` when an item is added to cached items
---@param f fun(Thing: Instance)
---@return function Disconnect disconnect function
function C.__index:ItemAdded(f: (Thing: any) -> ()): () -> ()
	table.insert(self.AddedListeners, f)
	return function ()
		table.remove(self.AddedListeners, table.find(self.AddedListeners, f) or 0)
	end
end

---removes `Thing` from cached items
---@param Thing any target thing
function C.__index:RemoveItem(Thing: any): any
	local Removed = table.remove(self.Items, table.find(self.Items, Thing) or 0)

	if Removed ~= nil then
		for _, f in self.RemovedListeners do
			if getfenv(f).script.Parent == nil then
				table.remove(self.RemovedListeners, table.find(self.RemovedListeners, f) or 0)
				continue
			end
			task.defer(f, Removed)
		end
	end

	return Removed
end

---fires function `f` when an item is removed from cached items
---@param f fun(Thing: Instance)
---@return function Disconnect disconnect function
function C.__index:ItemRemoved(f: (Thing: any) -> ()): () -> ()
	table.insert(self.RemovedListeners, f)
	return function ()
		table.remove(self.RemovedListeners, table.find(self.RemovedListeners, f) or 0)
	end
end

---connects .ChildAdded and .ChildRemoved events of Instance `Thing`
---@param Thing Instance
function C.__index:Connect(Thing: Instance): ()
	if self.Connections[Thing] then
		for _, Connection in self.Connections[Thing] do
			Connection:Disconnect()
		end
		table.clear(self.Connections[Thing])
	else
		self.Connections[Thing] = table.create(2)
	end

	local ConnectTable = self.Connections[Thing]
	table.insert(ConnectTable, Thing.ChildAdded:Connect(function(ThisThing: Instance)
		self:AddItem(ThisThing)
	end))
	table.insert(ConnectTable, Thing.ChildRemoved:Connect(function(ThisThing: Instance)
		self:RemoveItem(ThisThing)
	end))
	for _, ThisThing in Thing:GetChildren() do
		self:AddItem(ThisThing)
	end
end

---disconnects connections set by Instance `Thing`
---@param Thing Instance target instance
function C.__index:Disconnect(Thing: Instance): ()
	if self.Connections[Thing] then
		for _, Connection in self.Connections[Thing] do
			Connection:Disconnect()
		end
		table.clear(self.Connections[Thing])
		self.Connections[Thing] = nil
	end
end

---disconnects all instance connections
function C.__index:DisconnectAll(): ()
	for Thing in self.Connections do
		self:Disconnect(Thing)
	end
end

---destroys cache object
function C.__index:Destroy(): ()
	local Name = self.Name
	self:DisconnectAll()
	table.clear(self.Items)
	table.clear(self.AddedListeners)
	table.clear(self.RemovedListeners)
	table.clear(self)
	setmetatable(self, nil)
	Cache[Name] = nil
end

---### Cache.luau
---
---shallow instance cacher
---@param Name string cache name
---@param Size number? cache size
return function(Name: string, Size: number?)
	if not Cache[Name] then
		Cache[Name] = setmetatable({
			Name = Name;
			Items = table.create(Size or 64);
			Filter = nil :: ((Instance) -> boolean)?;
			Connections = {};
			AddedListeners = table.create(8);
			RemovedListeners = table.create(8);
		}, C)
	end
	return Cache[Name]
end