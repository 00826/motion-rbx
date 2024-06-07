--!strict

local Constants				= require(script.Parent.Constants)

local V3_yzAxis				= Constants.V3_yzAxis
local V3_xzAxis				= Constants.V3_xzAxis
local V3_xyAxis				= Constants.V3_xyAxis
local V3_CoefficientB		= Constants.V3_CoefficientB

local pi2					= Constants.mathpi2
local Gravity				= Constants.Gravity

local DefaultR				= Constants.Random

---### Vector3.luau
---
---extension of lua Vector3 library
local V_Vector3 = {}

---returns the height difference between Vector3 `V0` and Vector3 `V1`
---@param V0 Vector3
---@param V1 Vector3
---@return number
function V_Vector3.Height(V0: Vector3, V1: Vector3): number
	return V1.Y - V0.Y
end

---normalizes Vector3 `V` along axis `Axis`
---@param V Vector3 target vector
---@param Axis Axis target axis
---@return Vector3 Normalized Vector3
function V_Vector3.Normalize(V: Vector3, Axis: "X" | "Y" | "Z"): Vector3
	return (V * (
		Axis == "X" and V3_yzAxis or
			Axis == "Y" and V3_xzAxis or
			Axis == "Z" and V3_xyAxis or
			Vector3.one
		)).Unit
end

---creates Vector3 `AxisVector` from number `A` and target axis `Axis`
---@param A number
---@param Axis Axis
---@return Vector3 AxisVector
function V_Vector3.FromAxis(A: number, Axis: "X" | "Y" | "Z"): Vector3
	return Vector3.new(
		Axis == "X" and A or 0,
		Axis == "Y" and A or 0,
		Axis == "Z" and A or 0
	)
end

---returns a `Vector3` created from constant number `n` \
---equivalent to `Vector3.one * n`
---@param n number constant
---@return Vector3 Vector3 Vector3
function V_Vector3.FromConstant(n: number): Vector3
	return Vector3.one * n
end

---packs Vector3 or Vector3int16 `V` into vector array `VectorArray`
---@param V Vector3 | Vector3int16 target vector
---@return number[] VectorArray [x, y, z]
function V_Vector3.Pack(V: Vector3 | Vector3int16): {number}
	return {V.X, V.Y, V.Z}
end

---unpacks vector array `VA`[x, y, z] into Vector3 or Vector3int16 `V`
---@param VectorArray number[] vector table
---@param Int16? boolean turn into int16?
---@return Vector3 | Vector3int16 V vector3 or vector3int16
function V_Vector3.Unpack(VectorArray: {number}, Int16: boolean?): Vector3 | Vector3int16
	if Int16 then
		return Vector3int16.new(unpack(VectorArray))
	end
	return Vector3.new(unpack(VectorArray))
end

---returns X, Y, Z of Vector3 `V`
---@param V Vector3 target vector
---@return number X
---@return number Y
---@return number Z
function V_Vector3.GetComponents(V: Vector3): (number, number, number)
	return V.X, V.Y, V.Z
end

---returns the highest component value of Vector3 `V`
---@param V Vector3 Vector3
---@return number Max max value
function V_Vector3.Max(V: Vector3): number
	return math.max(V.X, V.Y, V.Z)
end

---returns the lowest component value of Vector3 `V`
---@param V Vector3 Vector3
---@return number Min min value
function V_Vector3.Min(V: Vector3): number
	return math.min(V.X, V.Y, V.Z)
end

---returns a Vector3 with the highest components between Vector3 `V0` and Vector3 `V1`
---@param V0 Vector3
---@param V1 Vector3
---@return Vector3 CeilVector Vector3
function V_Vector3.Ceil(V0: Vector3, V1: Vector3): Vector3
	return Vector3.new(
		math.max(V0.X, V1.X),
		math.max(V0.Y, V1.Y),
		math.max(V0.Z, V1.Z)
	)
end

---returns a Vector3 with the lowest components between Vector3 `V0` and Vector3 `V1`
---@param V0 Vector3
---@param V1 Vector3
---@return Vector3 FloorVector Vector3
function V_Vector3.Floor(V0: Vector3, V1: Vector3): Vector3
	return Vector3.new(
		math.min(V0.X, V1.X),
		math.min(V0.Y, V1.Y),
		math.min(V0.Z, V1.Z)
	)
end

---returns Vector3 `V0` clamped within Vector3 `Min` and Vector3 `Max`
---@param V0 Vector3 target vector
---@param Min Vector3 min vector
---@param Max Vector3 max vector
---@return Vector3 Vector3 Vector3
function V_Vector3.Clamp(V0: Vector3, Min: Vector3, Max: Vector3): Vector3
	return Vector3.new(
		math.clamp(V0.X, math.min(Min.X, Max.X), math.max(Min.X, Max.X)),
		math.clamp(V0.Y, math.min(Min.Y, Max.Y), math.max(Min.Y, Max.Y)),
		math.clamp(V0.Z, math.min(Min.Z, Max.Z), math.max(Min.Z, Max.Z))
	)
end

---returns position along bezier curve defined by Vector3[] `Points` at interpolant number `A` within range [0, 1]
---@param A number interpolant
---@vararg ... Vector3 bezier points
---@return Vector3 Position Position
function V_Vector3.BCurve(A: number, Points: {Vector3}): Vector3
	if #Points > 1 then
		local NewPoints = table.create(#Points)
		for i = 1, #Points - 1 do
			table.insert(NewPoints, Points[i]:Lerp(Points[i + 1], A))
		end
		return V_Vector3.BCurve(A, NewPoints)
	end
	return Points[1]
end

---returns random cframe within volume defined by Vector3 `Size` and position-orientation CFrame `C0` \
---optional Random object `R`
---@param Size Vector3
---@param C0 CFrame
---@param R? Random
---@return CFrame RandomCFrame RandomCFrame
function V_Vector3.RandomVolume(C0: CFrame, Size: Vector3, R: Random?): CFrame
	if not R then R = Constants.Random end
	local SHalf = Size * 0.5
	local X, Y, Z = SHalf.X, SHalf.Y, SHalf.Z
	return R and C0 * CFrame.new(
		R:NextNumber(-X, X),
		R:NextNumber(-Y, Y),
		R:NextNumber(-Z, Z)
	) or C0
end

---returns random unit vector Vector3 `UV` \
---optional Random object `R` \
---@param R? Random seed
---@return Vector3 UV unit vector
function V_Vector3.RandomDirection(R: Random|any): Vector3
	return (R or DefaultR):NextUnitVector()
end

---returns random unit vector Vector3 `UV` from unit vector Vector3 `Normal` within degree angle number `Theta` \
---optional Random object `R` \
---uses trig to produce the unit vector for better distribution
---@param Normal Vector3 initial direction
---@param Theta number angle of cone
---@param R? Random seed
---@return Vector3 UV unit vector
function V_Vector3.RandomCone(Normal: Vector3, Theta: number, R: Random|any): Vector3
	if not R then R = Constants.Random end
	return (CFrame.new(Vector3.zero, Normal) * CFrame.Angles(0, 0, R:NextNumber(0, pi2)) * CFrame.Angles(math.acos(R:NextNumber(math.cos(math.rad(Theta)), 1)), 0, 0)).LookVector
end

---returns random Vector3 `V` within min Vector3 `Min` and max Vector3 `Max` \
---optional Random object `R`
---@param Min Vector3 min range
---@param Max Vector3 max range
---@param R? Random seed
---@return Vector3 V vector
function V_Vector3.RandomRange(Min: Vector3, Max: Vector3, R: Random|any): Vector3
	if not R then R = Constants.Random end
	return Vector3.new(
		R:NextNumber(Min.X, Max.X),
		R:NextNumber(Min.Y, Max.Y),
		R:NextNumber(Min.Z, Max.Z)
	)
end

---cframe-vector type CV: anything that can be represented using X,Y,Z
type CV = Vector3 | Vector3int16  | PVInstance | CFrame

---returns CV `CV` as a `Vector3`
---@param CV CV target CV
---@return Vector3 Vector3 Vector3
---
---@overload fun(CV: Vector3):Vector3
---@overload fun(CV: Vector3int16):Vector3
---@overload fun(CV: CFrame):Vector3
---@overload fun(CV: PVInstance):Vector3
function V_Vector3.ToVector(CV: any): Vector3
	local TypeOf = typeof(CV)
	if TypeOf == "Vector3" then
		return CV
	elseif TypeOf == "Vector3int16" then
		return Vector3.new(CV.X, CV.Y, CV.Z)
	elseif TypeOf == "CFrame" then
		return CV.Position
	elseif CV:IsA("PVInstance") then
		return CV:GetPivot().Position
	end
	return Vector3.zero
end

---returns `(V1 - V0).Magnitude` but fast
---@param V0 Vector3 Vector3
---@param V1 Vector3 Vector3
---@return Vector3 Distance Distance
function V_Vector3.Distance(V0: Vector3, V1: Vector3): number
	V1 -= V0
	local x, y, z = V1.X, V1.Y, V1.Z
	return ((x * x) + (y * y) + (z * z)) ^ 0.5
end

---returns distance between non-vector3 data types
---@param CV0 CV
---@param CV1 CV
---@return Vector3 Distance CVDistance
function V_Vector3.CVDistance(CV0: any, CV1: any): Vector3
	return V_Vector3.Distance(V_Vector3.ToVector(CV0), V_Vector3.ToVector(CV1))
end

---returns `(V1 - V0).Unit`
---@param V0 Vector3|CV Vector3
---@param V1 Vector3|CV Vector3
---@return Vector3 Distance Distance
function V_Vector3.Direction(V0: Vector3 | any, V1: Vector3 | any): Vector3
	if type(V0) ~= "vector" then
		V0 = V_Vector3.ToVector(V0)
	end
	if type(V1) ~= "vector" then
		V1 = V_Vector3.ToVector(V1)
	end
	return (V1 :: Vector3 - V0 :: Vector3).Unit
end

---returns the midpoint of vararg `CV`'s
---@vararg CV
---@return Vector3 Midpoint midpoint
function V_Vector3.Midpoint(...: CV): Vector3
	local Vectors = {...}
	local Count = #Vectors

	if Count == 1 then
		return V_Vector3.ToVector(Vectors[1])
	else
		local T = Vector3.zero
		for _, V in Vectors do
			T += V_Vector3.ToVector(V)
		end
		return T / Count
	end
end

---returns true if Vector3 `P0` and Vector3 `P1` are coplanar along unit vector `Normal`
---@param P0 Vector3 position
---@param P1 Vector3 position
---@param Normal Vector3 unit vector
---@return boolean IsCoplanar is coplanar
function V_Vector3.IsCoplanar(P0: Vector3, P1: Vector3, Normal: Vector3): boolean
	return math.round((P0 - P1):Dot(Normal)) == 0
end

---returns a reflection of unit vector Vector3 `Direction` along unit vector `Normal`
---@param Direction Vector3 directional unit vector
---@param Normal Vector3 unit vector / surface normal
---@return Vector3 UV unit vector
function V_Vector3.Reflect(Direction: Vector3, Normal: Vector3): Vector3
	return 2 * Direction:Dot(Normal) * Normal - Direction
end

---stretches Vector3 `RealPosition` towards Vector3 `DesiredPosition`, constrained around number radius `Radius` \
---used to compensate for client-server latency for better responsiveness
---@param RealPosition Vector3 server-auth position
---@param DesiredPosition Vector3 client-auth position
---@param Radius number max radius to stretch by
---@return Vector3 Position stretched position
function V_Vector3.Stretch(RealPosition: Vector3, DesiredPosition: Vector3, Radius: number): Vector3
	if V_Vector3.Distance(RealPosition, DesiredPosition) <= Radius then
		return DesiredPosition
	end
	return RealPosition + (V_Vector3.Direction(RealPosition, DesiredPosition) * Radius)
end

---returns radians `X`, `Y`, `Z` in put into terms of rotation vector Vector3 `RotVector`
---@param dX number rotation X, in radians
---@param dY number rotation Y, in radians
---@param dZ number rotation Z, in radians
---@return Vector3 RotVector rotation vector
function V_Vector3.ToRotationVector(dX: number, dY: number, dZ: number): Vector3
	return Vector3.new(dX, dY, dZ) * math.rad(1)
end

---returns rotation vector Vector3 `V` as its `CFrame.Angles` equivalent
---@param V Vector3 rotation vector
---@return CFrame CFrame CFrame
function V_Vector3.FromRotationVector(V: Vector3): CFrame
	return CFrame.Angles(V.X, V.Y, V.Z)
end

---rpm solver
---@param RotationVector Vector3 RotationVector
---@param Time number Time
---@return CFrame RotCFrame rotated cframe
function V_Vector3.GetRotateAtTime(RotationVector: Vector3, Time: number): CFrame
	RotationVector *= Time
	return CFrame.Angles(RotationVector.X, RotationVector.Y, RotationVector.Z)
end

---beam projectile solver \
---returns Vector3 `Size` and Vector3 `Offset` of a beam along axis Z with respect to number `Velocity` and elapsed time number `Time`
---@param Size Vector3 initial size of beam as Vector3(diameter, diameter, ?) (z-axis is ignored)
---@param Velocity number velocity
---@param Time number time elapsed
---@return Vector3 Size Size of beam as Vector3(diameter, diameter, length)
---@return Vector3 Offset Offset of beam as Vector3(0, 0, length / 2)
function V_Vector3.GetTransformAtTime(Size: Vector3, Velocity: number, Time: number): (Vector3, Vector3)
	local Distance = Velocity * Time
	return Vector3.new(Size.X, Size.Y, Distance), Vector3.new(0, 0, Distance * -0.5)
end

---ballistic projectile solver; basically simple projectile motion equation put into terms of 3d space \
---optional constant `G` which describes the gravity acting on the projectile (default: Constants.Gravity) \
---when `G == 0`, the return value behaves like a linear projectile
---returns offset Vector3 `Offset` given initial unit vector Vector3 `Direction` with respect to number `Velocity` and elapsed time number `Time`
---@param Direction Vector3 initial direction
---@param Velocity number initial velocity
---@param Time number time elapsed
---@param G Vector3 projectile gravity
---@return Vector3 Offset Offset
function V_Vector3.GetOffsetAtTime(Direction: Vector3, Velocity: number, Time: number, G: number?): Vector3
	return (Direction * (Velocity * Time)) - (V3_CoefficientB * (G or Gravity) * (Time * Time))
end

function V_Vector3.GetBCurveAtTime(V0: Vector3, ControlPoint: Vector3, V1: Vector3, Distance: number, Velocity: number, Time: number): (Vector3, number)
	local A = (Time * Velocity) / Distance
	local P0 = V0:Lerp(ControlPoint, A)
	local P1 = ControlPoint:Lerp(V1, A)
	return P0:Lerp(P1, A), A
end

return table.freeze(V_Vector3)