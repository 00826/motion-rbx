--!strict

local Constants				= require(script.Parent.Constants)
local pi2					= Constants.mathpi2

---### Math.luau
---
---extension of lua math library
local V_Math = {}

---returns cooldown value of `n` with respect to deltaTime number `dt` \
---used to calculate cooldown "energy" normalized within range [0, 100]; "%n per second"
---@param n number number
---@param dt number deltaTime
---@return number Value number
function V_Math.CooldownRate(n: number, dt: number): number
	return dt * (100 / n)
end

---returns regen value of `n` with respect to deltaTime number `dt` \
---used to calculate regen rate; "n per second"
---@param n number number
---@param dt number deltaTime
---@return number Value number
function V_Math.RegenRate(n: number, dt: number): number
	return dt * n
end

---returns `x` ^ `y`; optimized for powers of 2
---@param x number base
---@param y number exponent
---@return number power x ^ y
function V_Math.Pow(x: number, y: number): number
	return y == 2 and x * x or x ^ y
end

---returns square root of x
---@param x number number
function V_Math.Sqrt(x: number): number
	return x ^ 0.5
end

---linearly interpolates number `v0` towards number `v1` with respect to alpha `a` within clamped range [0, 1]
---@param v0 number
---@param v1 number
---@param a number
---@return number
---
---@overload fun(Range: NumberRange, a: number): number
function V_Math.Lerp(v0: number, v1: number, a: number): number
	if typeof(v0) == "NumberRange" then
		return (1 - v1) * v0.Min + v1 * v0.Max
	end
	return (1 - a) * v0 + a * v1;
end

---returns the alpha number `a` value between number `v0` and number `v1` given number `n`
---@param n number base number
---@param v0 number min number
---@param v1 number max number
---@return number a Alpha
---
---@overload fun(Range: NumberRange, n: number): number
function V_Math.Alpha(v0: number, v1: number, n: number): number
	if typeof(v0) == "NumberRange" then
		return (v1 - v0.Min) / (v0.Max - v0.Min)
	end

	if n >= v1 then
		return 1
	elseif n <= v0 then
		return 0
	end

	return (n - v0) / (v1 - v0)
end

---maps number `n` from range `[min0, max0]` to range `[min1, max1]`
---@param n number number
---@param Min0 number number
---@param Max0 number number
---@param Min1 number number
---@param Max1 number number
---@return number Mapped number
function V_Math.Map(n: number, Min0: number, Max0: number, Min1: number, Max1: number): number
	return (n - Min0) * (Max1 - Min1) / (Max0 - Min0) + Min1;
end

---returns true if number `n` is in range `[Min, Max]` or range `NumberRange`
---@param n number base number
---@param Min number min number
---@param Max number max number
---@return boolean InRange is in range
---
---@overload fun(n: number, Range: NumberRange): boolean
function V_Math.InRange(n: number, Min: number, Max: number): boolean
	if typeof(Min) == "NumberRange" then
		Max = Min.Max
		Min = Min.Min
	end

	if n >= Min and n <= Max then
		return true
	end
	return false
end

---shifts number `n` by delta number `Delta` within range [0, `Limit`] \
---used for carousel displays
---```
---Solver.ShiftNumber(13, 1, 10) -> 4
---Solver.ShiftNumber(5, 2, 10) -> 7
---```
---@param n number base number
---@param Delta number delta
---@param Limit number limit
---@return number n shifted number
function V_Math.ShiftNumber(n: number, Delta: number, Limit: number): number
	return (n + Delta) % Limit
end

---returns value of input `x` scaled against limit `a` [0, inf] with slope scalar `k` [steep, flat] \
---`y=\frac{ax}{k+x}`
---@param x number input number
---@param a number limit number
---@param k number slope scalar
---@return number y result of limit function
function V_Math.Limit(x: number, a: number, k: number): number
	return (a * x) / (k + x)
end

---scales NumberSequence `Sequence` by scale number `Scale`
---@param Sequence NumberSequence NumberSequence
---@param Scale number scale
---@return NumberSequence ScaledSequence NumberSequence
function V_Math.ScaleNumberSequence(Sequence: NumberSequence, Scale: number): NumberSequence
	local NewSequence = {}
	for _,Keypoint in ipairs(Sequence.Keypoints) do
		local NewValue = Keypoint.Value * Scale
		table.insert(NewSequence,NumberSequenceKeypoint.new(Keypoint.Time,NewValue))
	end
	return NumberSequence.new(NewSequence)
end

---converts alpha number `a` [0, 1] into a NumberSequence `ScaledNumberSequence`
---@param a number alpha
---@return NumberSequence ScaledNumberSequence Scaled NumberSequence
function V_Math.AlphaToNumberSequence(a: number): NumberSequence
	if a <= 0.01 then
		return Constants.SeqZero
	elseif a == 1 then
		return Constants.SeqOne
	elseif a >= 0.99 then
		return Constants.SeqOne
	end
	a = math.clamp(a, 0, 1)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0);
		NumberSequenceKeypoint.new(a, 0);
		NumberSequenceKeypoint.new(math.clamp(a + 0.001, 0, 1), 1);
		NumberSequenceKeypoint.new(1, 1);
	})
end

---creates unit circle with vertices number `Vertices` around radius number `Radius`
---@param Vertices number circle vertices
---@param Radius number circle radius
---@return Vector3[] UnitCircle unit circle
function V_Math.UnitCircle(Vertices: number, Radius: number): {Vector3}
	if Vertices == 1 then
		return table.create(1, -Vector3.xAxis)
	elseif Vertices == 2 then
		return {-Vector3.xAxis, Vector3.xAxis}
	end
	local pRadians = pi2 / Vertices
	local List = table.create(Vertices)
	for i = 1, Vertices do
		local r = pRadians * i
		table.insert(List, Vector3.new(Radius * math.cos(r), 0, Radius * math.sin(r)))
	end
	return List
end

---Solver.UnitCircle but slightly modified for a niche case
--- param Vertices number circle vertices
--- param Radius number circle radius
--- return ArrangeResult[] Arranged ArrangeResult
--[[function V_Math.QuickArrange(Vertices: number, Radius: number): {{X: number, Z: number}}
	if Vertices == 1 then
		return table.create(1, {X = Radius * -1; Z = 0;})
	elseif Vertices == 2 then
		return {{X = Radius * -1; Z = 0;}, {X = Radius; Z = 0;}}
	end
	local Step = pi2 / Vertices
	local Tilt = math.pi / Vertices
	local Results = table.create(Vertices)
	for i = 1, Vertices do
		local a = (i * Step) - Tilt
		table.insert(Results, {X = Radius * math.cos(a); Z = Radius * math.sin(a);})
	end
	return Results
end]]

return table.freeze(V_Math)