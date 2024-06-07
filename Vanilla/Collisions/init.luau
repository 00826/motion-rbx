--!strict

local WhitelistParams				= RaycastParams.new()
WhitelistParams.FilterType			= Enum.RaycastFilterType.Include
WhitelistParams.IgnoreWater			= true

local BlacklistParams				= RaycastParams.new()
BlacklistParams.FilterType			= Enum.RaycastFilterType.Exclude
BlacklistParams.IgnoreWater			= true

local OverlapWhite					= OverlapParams.new()
OverlapWhite.FilterType				= Enum.RaycastFilterType.Include
OverlapWhite.RespectCanCollide		= false

local OverlapBlack					= OverlapParams.new()
OverlapBlack.FilterType				= Enum.RaycastFilterType.Exclude
OverlapBlack.RespectCanCollide		= false

local f								= function() end
local FancastResolution				= 10

local FastDistance					= require(script.Parent.Vector3).Distance

local DebugPart						= script:WaitForChild("DebugPart")

--local Vert1 = Vector3.new(1, 1, 1)
local Vert2 = Vector3.new(-1, 1, 1)
local Vert3 = Vector3.new(-1, -1, 1)
local Vert4 = Vector3.new(1, -1, 1)
--local Vert5 = Vector3.new(-1, -1, -1)
local Vert6 = Vector3.new(-1, 1, -1)
local Vert7 = Vector3.new(1, 1, -1)
local Vert8 = Vector3.new(1, -1, -1)

---### Collisions.luau
---
---avoids using OverlapParams.new() spam when raycasting/shapecasting \
---wraps GetPartBoundsInBox/GetPartBoundsInRadius/GetPartsInPart into a single function
local Collisions = { Groups = {} :: {[string]: {Instance}}; }

---creates or adds vararg Instances to Group string `GroupId` to be used by the raycast wrapper \
---not to be mistaken for BasePart.CollisionGroup
---@param GroupId string Name of collision Group
---@vararg Instance Instances that are part of collision group
function Collisions.AddGroup(GroupId: string, ...: Instance)
	local GroupTable, A = Collisions.Groups[GroupId], {...}

	if not GroupTable then
		Collisions.Groups[GroupId] = table.create(#A + 1) -- #A + 1 so there is always space for a friend :)! (table.insert(Collisions.CopyGroup(), Thing))
		GroupTable = Collisions.Groups[GroupId]
	end

	for _, Thing in A do
		if table.find(GroupTable, Thing) then continue end
		table.insert(GroupTable, Thing)
	end
end

---returns Instance[] array `Members` that belong to Group string `GroupId` \
---not to be mistaken for BasePart.CollisionGroup
---@param GroupId string Name of collision Group
---@return Instance[] Members array of Instances that belong to GroupId
function Collisions.GetGroup(GroupId: string): {Instance}
	return Collisions.Groups[GroupId] or table.create(0)
end

---returns a copy of Instance[] array `Members` that belong to Group string `GroupId` \
---for one-time calls in cases where a player-character needs to be inserted into the group, but the base group itself shouldnt be modified \
---not to be mistaken for BasePart.CollisionGroup \
---optional Instance `Thing` that gets inserted into the copied array
---@param GroupId string Name of collision Group
---@return Instance[] Members array of Instances that belong to GroupId
function Collisions.CopyGroup(GroupId: string, Thing: Instance?): {Instance}
	local T = Collisions.Groups[GroupId]
	if T then
		local C = table.clone(T)
		table.insert(C, Thing)
		return C
	end
	return table.create(1, Thing)
end

---sets string `CollisionGroup` property of valid descendants of Model `M`
---@param M Model Target Model
---@param CollisionGroup string CollisionGroup property
function Collisions.SetModelCollisionGroup(M: Model, CollisionGroup: string)
	for _, Part in M:GetDescendants() do
		if Part:IsA("Part") then
			Part.CollisionGroup = CollisionGroup
		elseif Part:IsA("MeshPart") then
			Part.CollisionGroup = CollisionGroup
		end
	end
end

---returns Vector3 `NearestPoint` towards Vector3 `WorldPoint` given the CFrame `C0` and Vector3 `Size` of an abstract object
---@param C0 CFrame abstract object CFrame
---@param Size Vector3 abstract object Size
---@param WorldPoint Vector3 WorldPoint
function Collisions.NearestPoint(C0: CFrame, Size: Vector3, WorldPoint: Vector3)
	local ObjectSpace = C0:PointToObjectSpace(WorldPoint)
	Size *= 0.5
	local X, Y, Z = Size.X, Size.Y, Size.Z
	return C0 * Vector3.new(
		math.clamp(ObjectSpace.X, -X, X),
		math.clamp(ObjectSpace.Y, -Y, Y),
		math.clamp(ObjectSpace.Z, -Z, Z)
	)
end

---simulates raycast against Model[] array `M` with theoretical furthest possible actual raycast with number `Distance` at origin Vector3 `P0`
---@param P0 Vector3 Origin of raycast
---@param Distance number Distance of raycast
---@param M Model[] array of Models to search through
function Collisions.QuickCast(P0: Vector3, Distance: number, M: {Model}): {Model}
	if #M == 0 then return table.create(1) end
	local L = table.create(#M)
	for _, Model in M do
		local C0, Size = Model:GetBoundingBox()
		if FastDistance(P0, C0.Position) > ((math.max(Size.X, Size.Y, Size.Z) * 0.5) + Distance) then continue end
		table.insert(L, Model)
	end

	return L
end

---calls BasePart `Part`:GetTouchingParts() and runs an iterator function `Iter` over its return value
---@param Part BasePart BasePart
---@return BasePart[] TouchingParts array of touching parts
function Collisions.QuickCollide(Part: BasePart): {BasePart}
	local C = Part.Touched:Connect(f)
	local T = Part:GetTouchingParts()
	C:Disconnect()
	return T
end

---all-in-one `workspace:GetPartBoundsInBox()`, `workspace:GetPartBoundsInRadius()`
---@param Shape CastShape # shape hitbox enum
---@param Type CastListType # collision array is a whitelist or blacklist
---@param Search Instance[] # collision array
---@param Pivot CFrame|Vector3 # pivot of hitbox
---@param Debug? boolean # spawn a visual part at pivot of hitbox
---@return BasePart[] CastResults # CastResults
---
---@overload fun(Shape: '"Box"', Type: CastListType, Search: Instance[], Pivot: CFrame, Size: Vector3, Debug?: boolean):BasePart[]
---@overload fun(Shape: '"Ball"', Type: CastListType, Search: Instance[], Pivot: Vector3, Size: number, Debug?: boolean):BasePart[]
function Collisions.Cast(Shape: string, Type: string, Search: {Instance}, Pivot: CFrame|Vector3, Size: Vector3|number, Debug: boolean?): {BasePart}
	local Overlap = ((Type == "WList" and OverlapWhite) or (Type == "BList" and OverlapBlack)) :: OverlapParams
	Overlap.FilterDescendantsInstances = Search

	if Shape == "Box" then
		if Debug then
			task.defer(Collisions._DebugPart, Pivot, Size, Enum.PartType.Block)
		end
		return workspace:GetPartBoundsInBox(Pivot, Size, Overlap)
	elseif Shape == "Ball" then
		if Debug then
			task.defer(Collisions._DebugPart, CFrame.new(Pivot), Vector3.one * 2 * Size, Enum.PartType.Ball)
		end
		return workspace:GetPartBoundsInRadius(Pivot, Size, Overlap)
	else
		warn(`invalid shape {Shape}`)
	end

	return table.create(0)
end

---casts a whitelist raycast at Vector3 `Origin` towards Vector3 `Direction` with Instance[] whitelist `Whitelist`
---@param Origin Vector3 Origin of Raycast
---@param Direction Vector3 Direction of Raycast
---@param Whitelist Instance[] array of Instances to Raycast against
---@param Debug? boolean # spawn a visual part at pivot of hitbox
---@return RaycastResult Result RaycastResult
function Collisions.RayWhitelist(Origin: Vector3, Direction: Vector3, Whitelist: {Instance}, Debug: boolean?): RaycastResult
	WhitelistParams.FilterDescendantsInstances = Whitelist
	if Debug then
		local Distance = Direction.Magnitude
		task.defer(Collisions._DebugPart, CFrame.lookAt(Origin, Origin + Direction) * CFrame.new(0, 0, -Distance * 0.5), Vector3.new(0.5, 0.5, Distance), Enum.PartType.Block)
	end
	return workspace:Raycast(Origin, Direction, WhitelistParams)
end

---casts a whitelist raycast at Vector3 `Origin` towards Vector3 `Direction` with Instance[] blacklist `Blacklist`
---@param Origin Vector3 Origin of Raycast
---@param Direction Vector3 Direction of Raycast
---@param Blacklist Instance[] array of Instances to not Raycast against
---@param Debug? boolean # spawn a visual part at pivot of hitbox
---@return RaycastResult Result RaycastResult
function Collisions.RayBlacklist(Origin: Vector3, Direction: Vector3, Blacklist: {Instance}, Debug: boolean?): RaycastResult
	BlacklistParams.FilterDescendantsInstances = Blacklist
	if Debug then
		local Distance = Direction.Magnitude
		task.defer(Collisions._DebugPart, CFrame.lookAt(Origin, Origin + Direction) * CFrame.new(0, 0, -Distance * 0.5), Vector3.new(0.5, 0.5, Distance), Enum.PartType.Block)
	end
	return workspace:Raycast(Origin, Direction, BlacklistParams)
end

---casts a fancast at Vector3 `Origin` towards Vector3 `Direction` with Instance[] array `Search` to be filtered as a Whitelist or Blacklist with boolean `IsBlacklist` (default: false)
---@param Origin Vector3 Origin of Fancast
---@param Direction Vector3 Direction of Fancast
---@param Angle number Angle of Fancast
---@param Search Instance[] array of Instance to [not?] Fancast against
---@param IsBlacklist boolean? use Collisions.RayBlacklist() instead of Collisions.RayWhitelist()
---@return RaycastResult[] Results RaycastResults
function Collisions.RayFancast(Origin: Vector3, Direction: Vector3, Angle: number, Search: {Instance}, IsBlacklist: boolean?): {RaycastResult}
	local Step = (math.rad(Angle * 0.5)) / FancastResolution
	local Distance = Direction.Magnitude
	local C0 = CFrame.lookAt(Origin, Origin + Direction.Unit)

	local Parts, Results = table.create(FancastResolution), table.create(FancastResolution * 2)

	local function Fan(n: number)
		local Look0 = (C0 * CFrame.Angles(0, n * Step, 0)).LookVector

		local RaycastResult: RaycastResult = IsBlacklist and Collisions.RayBlacklist(Origin, Look0 * Distance, Search) or Collisions.RayWhitelist(Origin, Look0 * Distance, Search)

		if RaycastResult then
			if table.find(Parts, RaycastResult.Instance) then return end
			table.insert(Parts, RaycastResult.Instance)
			table.insert(Results, RaycastResult)
		end
	end

	for i = 0, FancastResolution, 1 do
		Fan(i)
		if i == 0 then continue end -- skip doing 0th raycast twice
		Fan(-i)
	end

	return Results
end

---returns vertices Vector3[] of Model or Part `PV`
---@param PV Model | Part target model or part
---@return Vector3[] Vertices Vertices
function Collisions.GetVertices(PV: Model | Part): {Vector3}
	local C0, S0
	if PV:IsA("Model") then
		C0 = PV:GetPivot()
		S0 = PV:GetExtentsSize() * 0.5
	else
		C0 = PV.CFrame
		S0 = PV.Size * 0.5
	end
	return {
		(C0 * (S0 --[[* Vert1]]));
		(C0 * (S0 * Vert2));
		(C0 * (S0 * Vert3));
		(C0 * (S0 * Vert4));
		(C0 * (-S0 --[[* Vert5]]));
		(C0 * (S0 * Vert6));
		(C0 * (S0 * Vert7));
		(C0 * (S0 * Vert8));
	}
end

---creates a debug part for 0.1 seconds
---@param C CFrame Part CFrame
---@param S Vector3 Part Size
---@param Shape? Enum.PartType Part Shape
---@param CancelDestroy? boolean Skip automatic :Destroy()
function Collisions._DebugPart(C: CFrame, S: Vector3, Shape: Enum.PartType?, CancelDestroy: boolean?)
	local P = DebugPart:Clone() :: Part
	P.CFrame = C
	P.Size = S
	P.Shape = Shape or Enum.PartType.Block
	P.Parent = workspace
	if CancelDestroy then return end
	task.delay(0.1, function()
		P:Destroy()
	end)
end

return Collisions