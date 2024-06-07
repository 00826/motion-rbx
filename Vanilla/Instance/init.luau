--!strict

local ObjectValue			= script:WaitForChild("ObjectValue")
local Weld					= script:WaitForChild("Weld")

type InstanceTree = {
	ClassName: string;
	Children: {InstanceTree};
	Parent: Instance?; --.Parent only needed for entry set
	--... any properties
}

---### Instance.luau
---
---extension of roblox Instance library
local V_Instance = {}

---recursive Instance.new() using instance tree
---@param T InstanceTree Instance Tree
---@return Instance Instance Instance
function V_Instance.new(T: any): Instance
	local NewInstance = Instance.new(T.ClassName)

	for Property, Value in T do
		if Property == "ClassName" then continue end
		if Property == "Parent" then continue end
		if Property == "Children" then continue end

		---yes, these checks make the function slower, but property write errors on yet-to-be-parented instances are silent and yield indefinitely so its preferred to have something that works versus something thats fast
		if not V_Instance.IsPropertyOf(NewInstance, Property) then
			warn(`{debug.traceback()}{Property} is not a property of {T.ClassName} "{T.Name or T.ClassName}"`)
			continue
		end
		if (NewInstance[Property] ~= nil) and (typeof(Value) ~= typeof(NewInstance[Property])) then
			warn(`{debug.traceback()}Attempt to write {typeof(Value)} to {T.ClassName} "{T.Name or T.ClassName}" property {Property} ({typeof(NewInstance[Property])})`)
			continue
		end

		NewInstance[Property] = Value
	end

	if T.Children then
		for _, v in T.Children do
			v.Parent = NewInstance
			V_Instance.new(v)
		end
	end

	NewInstance.Parent = T.Parent

	return NewInstance
end

---interprets path `"a/b/c"` string `Path` beginning at root Instance `R` \
---safely-chains FFC/WFC calls with respect to boolean `Async` \
---`R["a"]` until the path arrives at `R["c"]`
---@param R Instance Root instance
---@param Path string path to target instance
---@param Async? boolean use `Instance:WaitForChild()` if `Instance:FindFirstChild()` returns nil
---@return Instance? PathResult PathResult
function V_Instance.Path(R: Instance, Path: string, Async: boolean?): Instance?
	for _, Ref in ipairs(Path:split("/")) do
		local New = Async and R:WaitForChild(Ref) or R:FindFirstChild(Ref)

		if not New then
			warn(`Ref "{Ref}" is not a member of {R.ClassName} "{R}"`)
			return nil
		end
		R = New
	end
	return R
end

---returns true if string `Property` is a property of Instance `I`
---@param I Instance target instance
---@param Property string desired property to check
---@return boolean IsProperty IsProperty
function V_Instance.IsPropertyOf(I: any, Property: string): boolean
	return pcall(function() return I[Property] end)
end

---welds "loose" BasePart `Loose` to "root" BasePart `Root` \
---optional CFrame offset `C0`
---@param Root BasePart loose part
---@param Loose BasePart base part
---@param C0? CFrame Weld.C0
---@return WeldConstraint WeldConstraint WeldConstraint
function V_Instance.Weld(Root: BasePart, Loose: BasePart, C0: CFrame?): WeldConstraint
	local NewWeld = Weld:Clone()
	Loose.CFrame = Root.CFrame * (C0 or CFrame.identity)
	NewWeld.Part0 = Loose
	NewWeld.Part1 = Root
	NewWeld.Parent = Loose
	return NewWeld
end

---recursively creates a proxy instance tree of Instance `I` \
---optional levels of recursion number `R`
---@param I Instance target instance
---@param R number? levels of recursion
---@return ObjectValue Proxy ObjectValue
function V_Instance.Proxy(I: Instance, R: number?): ObjectValue
	local OV = ObjectValue:Clone()
	OV.Name = I.Name
	OV.Value = I

	if R and R > 0 then
		for _, Thing in I:GetChildren() do
			V_Instance.Proxy(Thing, R - 1).Parent = OV
		end
	end
	return OV
end

---iterative `Property` setter
---@param I Instance target
---@param Properties table<string, any> properties
function V_Instance.SetProperties(I: any, Properties: {[string]: any})
	for k, v in Properties do
		if k == "Parent" then continue end
		I[k] = v
	end
	if Properties.Parent then
		I.Parent = Properties.Parent
	end
end

---iterative `Attribute` setter
---@param I Instance target
---@param Attributes table<string, any> attributes
function V_Instance.SetAttributes(I: Instance, Attributes: {[string]: any})
	for k, v in Attributes do
		I:SetAttribute(k, v)
	end
end

---yields until Child whose ClassName matches string `ClassName` is added to Instance `I`
---@param I Instance target
---@param ClassName string desired ClassName
---@param Timeout number? optional timeout (default: 10)
---@return Instance? Thing Thing
function V_Instance.WaitForChildOfClass(I: Instance, ClassName: string, Timeout: number?): Instance?
	local Thing, T = I:FindFirstChildOfClass(ClassName), Timeout or 10
	if not Thing then
		repeat
			T -= task.wait()
			Thing = I:FindFirstChildOfClass(ClassName)
		until (Thing ~= nil) or (T < 0)
	end
	return Thing
end

---gets all children of Instance `I` whose Name matches vararg string `Names` as Instance[] `Children`
---@param I Instance target instance
---@vararg string Names Names
---@return Instance[] Children ChildrenWithName
function V_Instance.GetChildrenWithName(I: Instance, ...: string): {Instance}
	local C, N = {}, {...}
	for _, ThisThing in I:GetChildren() do
		if not table.find(N, ThisThing.Name) then continue end
		table.insert(C, ThisThing)
	end
	return C
end

---gets all children of Instance `I` whose ClassName matches string `ClassName` as Instance[] `Children`
---@param I Instance target instance
---@param ClassName string ClassName
---@return Instance[] Children ChildrenOfClass
function V_Instance.GetChildrenOfClass(I: Instance, ClassName: string): {Instance}
	local A = {}
	for _, T in I:GetChildren() do
		if not T:IsA(ClassName) then continue end
		table.insert(A, T)
	end
	return A
end

---gets child of Instance `I` whose conditions match function `Match`
---@param I Instance target instance
---@return Instance Children GetChildrenWithCase
function V_Instance.FindFirstChildWithCase(I: Instance, Match: (Thing: Instance) -> boolean): Instance?
	for _, Thing: Instance in I:GetChildren() do
		if Thing.Name:sub(1, 1) == "_" then continue end
		if Match(Thing) then return Thing end
	end
	return
end

---recursively searches for the highest ancestor `Ancestor` of Instance `I` whose ClassName property matches string `ClassName`
---```
-----Fish: Model
-----┣━ Scales: Part
-----┣━ Eyes: Part
-----┗┳ Fins: Model
----- ┣━ RightFin: Part
----- ┗━ LeftFin: Part
-----┗━ Animator: Animator
---V_Instance.FindHighestAncestorOfClass(RightFin, "Model") --> Fish
---```
---@param I Instance target instance
---@param ClassName string desired ClassName
---@return Instance? Ancestor HighestAncestor
function V_Instance.FindHighestAncestorOfClass(I: Instance, ClassName: string): Instance?
	local Ancestor = I:FindFirstAncestorOfClass(ClassName)
	if Ancestor then
		local ThisAncestor = V_Instance.FindHighestAncestorOfClass(Ancestor, ClassName)
		if not ThisAncestor then
			return Ancestor
		else
			Ancestor = ThisAncestor
		end
	end
	return Ancestor
end

---finds desired parents of Instance[] or RaycastResult[] array `Things` that match string `ClassName` \
---to be used in conjunction with Collisions.luau, otherwise serves a very niche use
---@param Things Instance[] | RaycastResult[] array of Instances or RaycastResults
---@param ClassName string Desired ClassName of Parent
---@param Ignore? Instance Parent Instance to ignore
---@return Instance[] Parents array of parents found
function V_Instance.GetDesiredParents(Things: {Instance | RaycastResult}, ClassName: string, Ignore: Instance?): {Instance}
	if #Things == 0 then return table.create(0) end
	local Found = table.create(#Things)
	for _, Thing in Things do
		local Parent = nil
		if typeof(Thing) == "RaycastResult" then
			Parent = Thing.Instance.Parent
		else
			Parent = Thing.Parent
		end

		if not Parent:IsA(ClassName) then continue end
		if table.find(Found, Parent) then continue end
		if Parent == Ignore then continue end

		table.insert(Found, Parent)
	end
	return Found
end

---Instance:IsDescendantOf() but it accepts varargs
---@param I Instance
---@return boolean IsDescendantOf IsDescandantOf
function V_Instance.IsDescendantOf(I: Instance, ...: Instance): boolean
	for _, Thing in {...} do
		if I:IsDescendantOf(Thing) then
			return true
		end
	end
	return false
end

---ClearAllChildrenWithNames()
---@param I Instance Instance to be cleaned
---@param Name string Name to clear
function V_Instance.ClearChildrenWithName(I: Instance, Name: string)
	local ThingWithClassName = I:FindFirstChild(Name)
	if ThingWithClassName then
		ThingWithClassName:Destroy()
		V_Instance.ClearChildrenWithName(I, Name)
	else
		return
	end
end

--ClearAllChildrenWithoutNames()
---@param I Instance Instance to be cleaned
---@vararg string string Names to skip
function V_Instance.ClearWithoutName(I: Instance, ...: string)
	local Names = {...}
	for _, Thing: Instance in I:GetChildren() do
		if Thing.Name:sub(1, 1) == "_" then continue end
		if table.find(Names, Thing.Name) then continue end
		Thing:Destroy()
	end
end

---ClearAllChildrenWithClassNames()
---@param I Instance Instance to be cleaned
---@param ClassName string ClassName to clear
function V_Instance.ClearChildrenWithClassName(I: Instance, ClassName: string)
	local ThingWithClassName = I:FindFirstChildOfClass(ClassName)
	if ThingWithClassName then
		ThingWithClassName:Destroy()
		V_Instance.ClearChildrenWithClassName(I, ClassName)
	else
		return
	end
end

---ClearAllChildrenWithoutClassName()
---@param I Instance Instance to be cleaned
---@param ClassName string ClassName to skip
function V_Instance.ClearChildrenWithoutClassName(I: Instance, ClassName: string)
	for _, Thing: Instance in I:GetChildren() do
		if Thing.Name:sub(1, 1) == "_" then continue end
		if Thing.ClassName == ClassName then continue end
		Thing:Destroy()
	end
end

---ClearAllChildrenWithDeleteCase()
---@param I Instance Instance to be cleaned
---@param ShouldDelete fun(I:Instance):boolean
function V_Instance.ClearChildrenWithCase(I: Instance, ShouldDelete: (Thing: Instance) -> boolean)
	for _, Thing: Instance in I:GetChildren() do
		if Thing.Name:sub(1, 1) == "_" then continue end
		if ShouldDelete(Thing) == false then continue end
		Thing:Destroy()
	end
end

return V_Instance