--!strict

local MemoryStoreService	= game:GetService("MemoryStoreService")
local Players				= game:GetService("Players")

---### Cross.luau
---
---MemoryStoreService wrapper \
---Cross-server, semi persistent communication using MSS
local Cross = {
	Units					= 0;
	UnitsPerPlayerPerMinute	= 100;
	Times					= {
		Minute					= 60;
		Hour					= 3600;
		HalfDay					= 43200;
		Day						= 86400;
	};
	MemoryStoreCache		= {} :: {[string]: MemoryStoreSortedMap};
}

---checks if the MemoryStoreService budget can satisfy unit requests number `u`
---@param u number number of unit requests
---@return boolean BudgetCheck can satisfy requests
function Cross.BudgetCheck(u: number): boolean
	return (Cross.Units + u) <= (#Players:GetPlayers() * Cross.UnitsPerPlayerPerMinute)
end

---adds units to MemoryStoreService budget
---@param u number number of units to add
function Cross.BudgetAdd(u: number): ()
	Cross.Units += u
	task.delay(60, function() Cross.Units -= u end)
end

---creates and caches MemoryStoreSortedMap `MemoryStoreSortedMap` with string `StoreName`
---@param StoreName string MemoryStoreSortedMap name
---@return MemoryStoreSortedMap MemoryStoreSortedMap MemoryStoreSortedMap
function Cross.MemCreate(StoreName: string): MemoryStoreSortedMap
	if not Cross.MemoryStoreCache[StoreName] then
		Cross.MemoryStoreCache[StoreName] = MemoryStoreService:GetSortedMap(StoreName)
	end
	return Cross.MemoryStoreCache[StoreName]
end

---returns `MemoryStoreSortedMap:GetAsync(Key)` from a cached MemoryStoreSortedMap
---@param StoreName string MemoryStoreSortedMap name
---@param Key string key to retrieve
---@return boolean Success operation success
---@return any|string MemGet MemGet value or error message
function Cross.MemGet(StoreName: string, Key: string): (boolean, any|string)
	if not Cross.BudgetCheck(1) then return false, "Budget for this operation (1) exceeded" end
	Cross.BudgetAdd(1)
	return pcall(function()
		Cross.MemoryStoreCache[StoreName]:GetAsync(Key)
	end)
end

---returns `MemoryStoreSortedMap:GetRangeAsync(Key)` from a cached MemoryStoreSortedMap
---@param StoreName string MemoryStoreSortedMap name
---@param Direction Enum.SortDirection sort direction
---@param Range number # of items to retrieve, api cap is 200
---@param LowerBound? any optional criteria to sort the return value
---@param UpperBound? any optional criteria to sort the return value
---@return boolean Success operation success
---@return any[]|string MemGetRange MemGetRange values or error message
function Cross.MemGetRange(StoreName: string, Direction: Enum.SortDirection, Range: number, LowerBound: any?, UpperBound: any?): (boolean, {any}|string)
	if not Cross.BudgetCheck(Range) then return false, `Budget for this operation ({Range}) exceeded` end
	Cross.BudgetAdd(Range)
	return pcall(function()
		return Cross.MemoryStoreCache[StoreName]:GetRangeAsync(Direction, Range, LowerBound, UpperBound)
	end)
end

---returns `MemoryStoreSortedMap:SetAsync(Key)` from a cached MemoryStoreSortedMap
---@param StoreName string MemoryStoreSortedMap name
---@param Key string key to retrieve
---@param Value? any value to assign to Key
---@param Expiry? number expiry time of key in seconds
---@return boolean Success operation success
---@return boolean|string MemSet MemSet success or error message
function Cross.MemSet(StoreName: string, Key: string, Value: any?, Expiry: number?): (boolean, boolean|string)
	if not Cross.BudgetCheck(1) then return false, "Budget for this operation (1) exceeded" end
	Cross.BudgetAdd(1)
	return pcall(function()
		return Cross.MemoryStoreCache[StoreName]:SetAsync(Key, Value, Expiry or Cross.Times.Hour)
	end)
end

return Cross