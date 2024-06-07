--!strict

local Cache = {}

local Connect = {__index = {}}
Connect.__len = function(self)
	return #self.Connections
end

---checks if there is an existing connection at index `i`
---@param i number
function Connect.__index:Peek(i: number): boolean
	return self.Connections[i] ~= nil
end

---disconnects connection at index `i` and replaces it with new connection `C` or nil
---@param C? RBXScriptConnection RBXScriptConnection
---@param i number connection index
function Connect.__index:AtIndex(i: number, C: RBXScriptConnection?)
	if self.Connections[i] then
		self.Connections[i]:Disconnect()
	end
	self.Connections[i] = C :: any
end

---merges or inserts RBXScriptConnection[] `C` into stored connections
---@param C RBXScriptConnection|RBXScriptConnection[] single connection or array of connections
function Connect.__index:Merge(C: RBXScriptConnection|{RBXScriptConnection})
	if typeof(C) == "table" then
		for _, Connection in C do
			table.insert(self.Connections, Connection)
		end
	elseif typeof(C) == "RBXScriptConnection" then
		table.insert(self.Connections, C)
	end
end

---disconnects all connections
function Connect.__index:Clear()
	for _, Connection in self.Connections do
		if Connection then
			Connection:Disconnect()
		end
	end
	table.clear(self.Connections)
end

---destroys Connect object
function Connect.__index:Destroy()
	local Name = self.Name
	self:Disconnect()
	table.clear(self)
	setmetatable(self, nil)
	Cache[Name] = nil
end

---### Connect.luau
---
---bulk RBXScriptConnection handler
---@param Name string connection group name
---@param Size? number connection group size (default 64)
return function(Name: string, Size: number?)
	if not Cache[Name] then
		Cache[Name] = setmetatable({ Name = Name; Connections = table.create(Size or 64); }, Connect)
	end
	return Cache[Name]
end