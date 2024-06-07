--!strict

local ContentProvider			= game:GetService("ContentProvider")

---### Misc.luau
---
---miscellaneous functions and wrappers
--[[

	Misc.Preload -- ContentProvider wrapper
	Misc.Color -- color functions

	-- ... and other miscellaneous functions
]]
local Misc = {}

---### Misc.Preload
---
---ContentProvider wrapper + recursive rbxassetid:// finder
Misc.Preload = {}

---recursively inserts all `rbxassetid://` values in deep table<string, any> `T` into array string[] `A`
---@param T table<string, any> target table
---@param A string[] target array
function Misc.Preload.Index(T: {[string]: any}, A: {string})
	local Duplicates = {}
	local function Idx(ThisTable)
		for _, Value in ThisTable do
			if type(Value) == "table" then
				Idx(Value)
				continue
			end
			if type(Value) ~= "string" then continue end
			if not Value:find("rbxassetid://") then continue end
			if Duplicates[Value] then continue end
			Duplicates[Value] = true
			table.insert(A, Value)
		end
	end
	Idx(T)
end

---ContentProvider:PreloadAsync()
---@param A string[] target array of rbxassetid:// strings
---@param F fun(ContentString: string, AssetFetchStatus: Enum.AssetFetchStatus)
---@return number Time `ContentProvider:PreloadAsync` time (in milliseconds)
function Misc.Preload.Async(A: {any}, F: ((ContentString: string, AssetFetchStatus: Enum.AssetFetchStatus) -> ())?): number
	local s = os.clock()
	ContentProvider:PreloadAsync(A, F)
	return (os.clock() - s) * 1000
end

---### Misc.Color
---
---Color functions
Misc.Color = {}

---adjusts saturation of Color3 `Color` by number `DeltaSaturation`
---@param Color Color3 Color3
---@param DeltaSaturation number DeltaSaturation
---@return Color3 Color Color3
function Misc.Color.DeltaS(Color: Color3, DeltaSaturation: number): Color3
	local H, S, V = Color:ToHSV()
	return Color3.fromHSV(H, math.clamp(S + (DeltaSaturation / 100), 0, 1), V)
end

---inverts Color3 `Color`
---@param Color Color3 Color3
---@return Color3 Color Color3
function Misc.Color.Invert(Color: Color3): Color3
	return Color3.new(1 - Color.R, 1 - Color.G, 1 - Color.B)
end

---returns sort value of Color3 `Color`
---@param Color Color3 Color3
---@return number SortValue LayoutOrder
function Misc.Color.SortValue(Color: Color3): number
	return (Color:ToHSV()) * 100
end

---converts Color3 `Color` to Vector3 `VertexColor`
---@param Color Color3 Color
---@return Vector3 VertexColor VertexColor
function Misc.Color.ToVertexColor(Color: Color3): Vector3
	return Vector3.new(Color.R, Color.G, Color.B) / 255
end

---converts Vector3 `VertexColor` to Color3 `Color`
---@param VertexColor Vector3 VertexColor
---@return Color3 Color Color
function Misc.Color.FromVertexColor(VertexColor: Vector3): Color3
	VertexColor *= 255
	return Color3.new(VertexColor.X, VertexColor.Y, VertexColor.Z)
end

---returns `Color3` from ColorSequence `Sequence` with respect to interpolant `A [0, 1]`
---@param Sequence ColorSequence ColorSequence
---@param A number interpolant
---@return Color3 Color Color3
function Misc.Color.GetColorAtValue(Sequence: ColorSequence, A: number): Color3
	local LastKeypoint = nil
	for _, Keypoint in ipairs(Sequence.Keypoints) do
		if A < Keypoint.Time then
			local T0 = LastKeypoint.Time

			return LastKeypoint.Value:Lerp(Keypoint.Value, (A - T0) / (Keypoint.Time - T0))
		end
		LastKeypoint = Keypoint
	end
	return LastKeypoint and LastKeypoint.Value or Color3.fromRGB(255, 255, 255)
end

return Misc