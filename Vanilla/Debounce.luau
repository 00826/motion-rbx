--!strict

local Time					= require(script.Parent.Time)

local Prefix				= "_Debounce_"

---### Debounce.luau
---
---returns true if debounce passed, returns false if not passed
---@param Thing Instance
---@param DebounceName string
---@param DebounceTime string
return function(Thing: Instance, DebounceName: string, DebounceTime: number): boolean
	local Now, Until = Time(), Thing:GetAttribute(Prefix .. DebounceName) or 0
	if Until > Now then return false end
	Thing:SetAttribute(Prefix .. DebounceName, Now + DebounceTime)
	return true
end