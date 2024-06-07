--!strict

---### ToBoolean.luau
---
---represents any non-userdata data type as boolean `bool`
---@param v? any any
---@return boolean bool boolean
return function(v: any): boolean
	if not v then return false end
	local t = type(v)
	return (t == "boolean" and v) or (t == "number" and v > 0) or (t == "string" and v ~= "") or (t == "vector" and v.Magnitude > 0) or (t == "table" and next(v) ~= nil) or (t == "function" and (v :: () -> ())()) or false
end