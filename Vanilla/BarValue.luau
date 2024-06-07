--!strict

local Constants				= require(script.Parent.Constants)
local VMath					= require(script.Parent.Math)

local V3_yzAxis				= Constants.V3_yzAxis

---### BarValue.luau
---
---stores bar values (like health bars) as Vector3's to be stored as attributes \
---makes it easier to read and adjust bar values and regen rates \
---`Vector3(Value, MaxValue, RegenRate)`
local BarValue = {}

---adds BarValue Vector3 attribute `BarAttribute` to Model `Character` as `Vector3(MaxValue, MaxValue, Rate)`
---@param Character Model target character
---@param BarAttribute string BarValue name
---@param MaxValue? number MaxValue (default: 100)
---@param Rate? number Rate (default: 1)
function BarValue.Add(Character: Model, BarAttribute: string, MaxValue: number?, Rate: number?)
	MaxValue = MaxValue or 100
	Character:SetAttribute(BarAttribute, Vector3.new(MaxValue, MaxValue, Rate or 1))
end

---removes BarValue Vector3 attribute `BarAttribute` from Model `Character` as added by `BarValue.Add(Character, BarAttribute)`
---@param Character Model target character
---@param BarAttribute string BarValue name
function BarValue.Remove(Character: Model, BarAttribute: string)
	Character:SetAttribute(BarAttribute, nil)
end

---adds number `Delta` to Value of BarValue Vector3 attribute `BarAttribute` where `Value + Delta` is clamped within range `[0, MaxValue]`
---@param Character Model target character
---@param BarAttribute string BarValue name
---@param Delta number DeltaValue
---@return boolean success
---@return number NewValue NewValue (Vector.X)
function BarValue.Delta(Character: Model, BarAttribute: string, Delta: number): (boolean, number?)
	local V = Character:GetAttribute(BarAttribute)
	if not V then return false end
	local Max = V.Y
	local New = Vector3.new(math.clamp(V.X + Delta, 0, Max), Max, V.Z)
	Character:SetAttribute(BarAttribute, New)
	return true, New.X
end

---@param Character Model target character
---@param BarAttribute string BarValue name
---@param Axes table<BarAxes, number> Axes
function BarValue.WriteToAxes(Character: Model, BarAttribute: string, Axes: {[any]: number})
	local V = Character:GetAttribute(BarAttribute)
	Character:SetAttribute(BarAttribute, Vector3.new(
		Axes.X or V.X,
		Axes.Y or V.Y,
		Axes.Z or V.Z
	))
end

---sets BarValue Vector3 attribute `BarAttribute` from Model `Character`
---@param Character Model target character
---@param BarAttribute string BarValue name
function BarValue.Min(Character: Model, BarAttribute: string): boolean
	local V = Character:GetAttribute(BarAttribute)
	if not V then return false end
	Character:SetAttribute(BarAttribute, V * V3_yzAxis)
	return true
end

---sets BarValue Vector3 attribute `BarAttribute` from Model `Character`
---@param Character Model target character
---@param BarAttribute string BarValue name
function BarValue.Max(Character: Model, BarAttribute: string): boolean
	local V = Character:GetAttribute(BarAttribute)
	if not V then return false end
	Character:SetAttribute(BarAttribute, Vector3.new(V.Y, V.Y, V.Z))
	return true
end

---returns `BarValue.X / BarValue.Y` from Model `Character` as added by `BarValue.Add(Character, BarAttribute)`
---@param Character Model target character
---@param BarAttribute string BarValue name
---@return number Alpha X/Y
function BarValue.Alpha(Character: Model, BarAttribute: string): number
	local V = Character:GetAttribute(BarAttribute)
	if not V then return 0 end
	return V.X / V.Y
end

---returns x, y, z components of BarValue Vector3 attribute `BarAttribute` as `Value`, `MaxValue`, `RegenRate`
---@param Character Model
---@param BarAttribute string BarValue name
---@return number Value Bar.Value
---@return number MaxValue Bar.MaxValue
---@return number RegenRate Bar.RegenRate
function BarValue.Read(Character: Model, BarAttribute: string): (number, number, number)
	local V = Character:GetAttribute(BarAttribute)
	if not V then return 0, 0, 0 end
	return V.X, V.Y, V.Z
end

---returns true if Model `Character`'s BarValue Vector3 attribute `BarAttribute`'s X-component (Value) is equal-to or below `0`
---@param Character Model target character
---@param BarAttribute string BarValue name
---@return boolean IsZero IsZero
function BarValue.IsMin(Character: Model, BarAttribute: string): boolean
	local V = Character:GetAttribute(BarAttribute)
	if not V then return false end
	if type(V) ~= "vector" then return false end
	return V.X <= 0
end

---returns true if Model `Character`'s BarValue Vector3 attribute `BarAttribute`'s X-component (Value) is equal-to or above its Y-component (MaxValue)
---@param Character Model target character
---@param BarAttribute string BarValue name
---@return boolean IsMax IsMax
function BarValue.IsMax(Character: Model, BarAttribute: string): boolean
	local V = Character:GetAttribute(BarAttribute)
	if not V then return false end
	if type(V) ~= "vector" then return false end
	return V.X >= V.Y
end

---returns true if Model `Character`'s BarValue Vector3 attribute `BarAttribute`'s X-component (Value) is equal-to or above passed `Value`
---@param Character Model
---@param BarAttribute string
---@param Value number
function BarValue.IsOver(Character: Model, BarAttribute: string, Value: number): boolean
	local V = Character:GetAttribute(BarAttribute)
	if not V then return false end
	if type(V) ~= "vector" then return false end
	return V.X >= Value
end

---regenerates BarValue Vector3 attribute `BarAttribute`'s X-component (Value) within range `[0, Y-component (MaxValue)]` with respect to its Z-component (RegenRate) and deltaTime number `dt`
---@param Character Model target character
---@param BarAttribute string BarValue name
---@param dt number deltaTime
function BarValue.Regen(Character: Model, BarAttribute: string, dt: number)
	local AVector: Vector3? = Character:GetAttribute(BarAttribute)
	if not AVector then return end
	local Value, MaxValue, RegenRate = AVector.X, AVector.Y, AVector.Z
	if RegenRate == 0 then return end
	if Value >= MaxValue then return end
	Character:SetAttribute(BarAttribute, Vector3.new(math.clamp(Value + VMath.RegenRate(RegenRate, dt), 0, MaxValue), MaxValue, RegenRate))
end

return BarValue