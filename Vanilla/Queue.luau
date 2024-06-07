--!strict

---### Queue.luau
---
---fifo-style table implementation
local Queue = {__index = {}}
Queue.__len = function(self)
	return #self.Items
end
Queue.__iter = function(self)
	return pairs(self.Items)
end

---removes and returns the first (oldest) element in the queue
---@return any element popped element
function Queue.__index:pop(): any?
	return table.remove(self.Items, 1)
end

---returns the first (oldest) element in the queue
---@return any element front element
function Queue.__index:front(): any
	return self.Items[1]
end

---returns the last (newest) element in the queue
---@return any element back element
function Queue.__index:back(): any
	return self.Items[#self.Items]
end

---adds a value to the back of the queue
---@param val any value
function Queue.__index:push(val: any): ()
	table.insert(self.Items, val)
end

---pushes a value to the queue, if any only if it isn't an element of the queue already \
---returns whether or not the value was successfully pushed
---@param val any value
function Queue.__index:ifAndOnlyIf(val: any): boolean
	if not table.find(self.Items, val) then
		table.insert(self.Items, val)
		return true
	end
	return false
end

---destroys queue
function Queue.__index:Destroy(): ()
	table.clear(self.Items)
	table.clear(self)
	setmetatable(self, nil)
end

return function(n: number)
	return setmetatable({ Items = table.create(n or 64); }, Queue)
end