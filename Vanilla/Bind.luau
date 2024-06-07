---!strict

local Cache = {}

local Bind = {__index = {}}

---connects function `f`
---@vararg any
---@param f fun(...)
---@return fun() Disconnect disconnect function
function Bind.__index:Connect(f: (...any) -> ()): () -> ()
	table.insert(self.funcs, f)
	return function() self:Disconnect(f) end
end

---passes vararg `...` to all connected functions
---@vararg any
function Bind.__index:Fire(...: any): ()
	for i = #self.funcs, 1, -1 do
		local f = self.funcs[i]
		if getfenv(f).script.Parent == nil then
			table.remove(self.funcs, i)
			continue
		end
		task.defer(f, ...)
	end
	self:Resume(...)
end

---recursively resumes all yielded threads and passes vararg `...` into `task.defer(coroutine, ...)`
---@vararg any
function Bind.__index:Resume(...: any): ()
	local co = table.remove(self.yields)
	if co then
		task.defer(co, ...)
		self:Resume(...)
	else
		return
	end
end

---yields thread until `Fire()` is called
---@vararg any
---@return ...
function Bind.__index:Wait(): ...any
	table.insert(self.yields, coroutine.running())
	return coroutine.yield()
end

---disconnects function
---@vararg any
---@param f fun(...)
function Bind.__index:Disconnect(f: (...any) -> ()): ()
	table.remove(self.funcs, table.find(self.funcs, f) or 0)
end

---disconnects all connected functions
function Bind.__index:DisconnectAll(): ()
	table.clear(self.funcs)
	self:Resume()
end

---destroys bind, clears all connected functions, and resumes all yielded threads
function Bind.__index:Destroy(): ()
	local Name = self.Name
	self:DisconnectAll()
	table.clear(self)
	setmetatable(self, nil)
	Cache[Name] = nil
end

---### Bind.luau
---
---binds multiple functions to a single group
---@param Name string bind name
---@param Size? number bind bucket size (default: 8)
return function(Name: string, Size: number?)
	if not Cache[Name] then
		Cache[Name] = setmetatable({ Name = Name; funcs = table.create(Size or 8); yields = table.create(Size or 8); }, Bind)
	end
	return Cache[Name]
end