--!strict

local Time					= require(script.Parent.Time)

local Prefix				= "___VStatus_"
local Type					= "Vector2"
local PrefixLength			= #Prefix + 1

---### Status.luau
---
---Status effects are stored as a Vector2 attribute: SetAttribute(StatusId, Vector2(Expiry, Stacks)) \
---if Expiry == -1 then state is indefinite
local Status = {}

---applies status id string `StatusId` to Instance `Thing` with: \
---optional valueTime number `vT` (default: 0) \
---optional valueStacks number `vS` (default: 0) \
---optional deltaTime number `dT` (default: 0) \
---optional deltaStacks number `dS` (default: 0)
---@param Thing Instance
---@param StatusId string
---@param vT? number value of Time
---@param vS? number value of Stacks
---@param dT? number delta Time
---@param dS? number delta Stacks
function Status.Add(Thing: Instance, StatusId: string, vT: number?, vS: number?, dT: number?, dS: number?)
	local Now = Time()
	local _, Until, Stacks = Status.Read(Thing, StatusId)
	if vT == -1 then
		Until = -1
	else
		Until = (vT or 0) + (dT or 0) + math.max(Now, Until)
	end
	Stacks = (vS or 0) + (dS or 0)
	Thing:SetAttribute(Prefix .. StatusId, Vector2.new(Until, Stacks))
end

---removes status id string `StatusId` from Instance `Thing` applied by `Status.Add(Thing, StatusId)`
---@param Thing Instance target instance
---@param StatusId string StatusId
function Status.Remove(Thing: Instance, StatusId: string)
	Thing:SetAttribute(Prefix .. StatusId, nil)
end

---reads from status id string `StatusId` applied by `Status.Add` to Instance `Thing`; returns boolean `Active`, number `Until`, and number `Stacks` \
---if state is expired (`Active == false`), then `Until` and `Stacks` will be `0`
---@param Thing Instance target instance
---@param StatusId string StatusId
---@return boolean Active status active
---@return number Until time when state expires
---@return number Stacks stack count
function Status.Read(Thing: Instance, StatusId: string): (boolean, number, number)
	return Status._ReadRaw(Thing:GetAttribute(Prefix .. StatusId))
end

type StatusInfo = {
	Active: boolean;
	Until: number?;
	Stacks: number?;
}

---reads all status effects applied by `Status.Add` to Instance `Thing` as table<string, StatusInfo> `States`
---@param Thing Instance target instance
---@return table<string, StatusInfo> States
function Status.ReadAll(Thing: Instance): {[string]: StatusInfo}
	local States = {} :: {}

	Status._Iterate(Thing, function(StatusId: string, StatusVector: Vector2?)
		local A, U, S = Status._ReadRaw(StatusVector)
		if A == true then
			States[StatusId] = {Active = A; Until = U; Stacks = S}
		end
	end)

	return States
end

---removes all status effects applies by `Status.Add` to Instance `Thing`
---@param Thing Instance target instance
function Status.Cleanup(Thing: Instance)
	Status._Iterate(Thing, function(StatusId: string, StatusVector: Vector2?)
		local A = Status._ReadRaw(StatusVector)
		if not A then
			Status.Remove(Thing, StatusId)
		end
	end)
end

---formats status effects given time number `Time` and stacks number `Stacks` as string `"x(Stacks) 0:00"` \
---overload: status vector Vector2 `StatusVector`
---```
---Status.Format(10, 8) -> "x8  0:10"
---Status.Format(Vector2.new(64, 6)) -> "x6  1:04"
---Status.Format(Vector2.new(150, 0)) -> "2:30"
---Status.Format(Vector2.new(-1, 5)) -> "x5"
---```
---@param T number seconds
---@param Stacks number stack count
---@return string Formatted formatted string
---
---@overload fun(StatusVector: Vector2, Stacks: number): string
---@overload fun(Time: number, Stacks: number): string
function Status.Format(T: any, Stacks: number): string
	if typeof(T) == "Vector2" then
		Stacks = T.Y
		T = T.X
	end
	if T ~= -1 then
		T = Status.Delta(T :: number)
	end
	return (Stacks == 0 and "" or (Status._FormatStacks(Stacks) .. "	")) .. (T == -1 and "" or Status._FormatTime(T :: number))
end

function Status.Delta(Until: number): number
	return Until - Time()
end

---reads directly from status vector `V`; returns boolean `Active`, number `Until`, and number `Stacks` \
---if state is expired (`Active == false`), then `Until` and `Stacks` will be `0`
---@param V Vector2 status vector
---@return boolean Active status active
---@return number Until time when state expires
---@return number Stacks stack count
function Status._ReadRaw(V: Vector2?): (boolean, number, number)
	if not V then return false, 0, 0 end
	local Until, Stacks = V.X, V.Y
	if Until == -1 then
		-- indefinite
	elseif Until < Time() then
		return false, 0, 0
	end
	return true, Until, Stacks
end

---iterates over Instance `Thing`'s Attributes that were set by `Status.Add` with operator function `f`
---@param Thing Instance target instance
---@param f fun(Attribute: string, Value: Vector2)
function Status._Iterate(Thing: Instance, f: (StatusId: string, StatusVector: Vector2?) -> ())
	for Attribute, StatusVector: Vector2? in Thing:GetAttributes() do
		if #Attribute < PrefixLength then continue end -- skips if attribute character count is lower than minimum number `PrefixLength`
		if not Attribute:find(Prefix) then continue end -- skips if attribute does not contain string `Prefix`
		if typeof(StatusVector) ~= Type then continue end -- skips if value assigned to attribute does not match type `Type` (Vector2)
		f(Attribute:sub(PrefixLength, #Attribute), StatusVector) -- trims string `Prefix` from actual attribute and passes it into operator function `f`
	end
end

---formats seconds number `n` into M:SS form as string `s`
---@param n number number
---@return string s `n` represented in M:SS form
function Status._FormatTime(n: number): string
	return os.date("!%X", n):sub(4, 8):gsub("^0", "")
end

---formats stacks number `n` into string form as string `Formatted` \
---@param n number number
---@return string s `"x" .. n`
function Status._FormatStacks(n: number): string
	if n == 0 then
		return ""
	end
	return "x" .. n
end

return Status