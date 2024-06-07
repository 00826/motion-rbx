--!strict

local Constants				= require(script.Parent.Constants)

local DefaultR				= Constants.Random

---### Table.luau
---
---extension of lua table library
local V_Table = {}

---recursive `table.copy(T)`
---@param T table<any, any> target table
function V_Table.Copy(T: {[any]: any}): {[any]: any}
	local C = {}

	for k, v in T do
		if type(v) == "table" then
			C[k] = V_Table.Copy(v)
		else
			C[k] = v
		end
	end

	return C
end

---returns average or weighted average of array any[] `A` \
---optional weights array number[] `B` \
---supports `A` as a single-type array populated with types that support the `+`, `*`, `/` operators
---@param A any[] target array
---@param Weights? number[] optional weights of corresponding values of A
---@return any Average type(A)
function V_Table.Average<T>(A: {T}, Weights: {number}?): T
	local n = #A
	local C = table.remove(A, 1)
	for i, V in ipairs(A) do
		C += V * (Weights and Weights[i] or 1)
	end
	return C / n
end

---returns a frozen, space-allocated, shallow-copied version of array `A` \
---faster read speed, minimal space allocation
function V_Table.ReadOnly<T>(A: {T}): {T}
	local t = table.create(#A)
	for _, v in ipairs(A) do
		table.insert(t, v)
	end
	return t
end

---picks number `n` values from table `T` \
---optional Random object `R`
---```
---local DropTable = {
---	Common = 60;
---	Rare = 35;
---	Legendary = 5;
---}
---V_Table.Pick(DropTable, 2) -- {"Common", "Common"} (probably)
---
---local DropList = {"pineapple", "mango", "coconut", "a fish", "poke"}
---V_Table.Pick(DropList) -- {"a fish"} (maybe)
---```
---@param T any[] array or DropTable table<string, number>
---@param n? number amount to pick (default: 1)
---@param R? Random Random (default: `Constants.Random`)
----
---@overload fun(T: table<string, number>, n?: number, R?: Random): string[]
function V_Table.Pick(T: {any}, n: number|any, R: Random|any): {string?}
	if not R then R = Constants.Random end
	if not n then n = 1 end

	local Things = table.create(n)
	local V = next(T)
	local Type = type(V)

	if Type == "nil" then
		return Things
	elseif Type == "string" then
		--- drop chance dictionary
		for _ = 1, n do
			local Roll, Passed = 100 * (R:NextNumber()), 0
			for Key, Value in T do
				Passed += Value
				if Roll > Passed then continue end
				table.insert(Things, Key)
				break
			end
		end
	else
		--- pick from list
		local Length = #T
		local Integers = {}
		for _ = 1, math.clamp(n, 1, Length) do
			local ThisIdx
			repeat
				ThisIdx = R:NextInteger(1, Length)
			until not Integers[ThisIdx]
			Integers[ThisIdx] = true

			table.insert(Things, T[ThisIdx])
		end
	end
	return Things
end

---returns string `Key` from table<any, any> `T` using any value `V`
---```
---V_Table.FindKeyFromValue({x = 5, y = 10}, 5) --> "x"
---```
---@param T table<any, any>
---@param V any V
---@return any Key key found
function V_Table.FindKeyfromValue(T: {[any]: any}, V: any): any?
	for Key, Value in T do
		if V ~= Value then continue end
		return Key
	end
	return
end

---returns a shuffled copy of any[] array `A`
---@param A any[]
---@return any[] Shuffled shuffled copy of `A`
function V_Table.Shuffle(A: {any}, R: Random|any): {any}
	return (R or DefaultR):Shuffle(table.clone(A))
end

---merges all values in table `B` into table `A`
---@param A any[]|table<any, any> base array
---@param B any[]|table<any, any> not base array
function V_Table.Merge(A: {any}, B: {any})
	if table.maxn(A) == 0 and table.maxn(B) == 0 then
		for k, v in B do
			A[k] = v
		end
	else
		for _, v in B do
			table.insert(A, v)
		end
	end
end

---patches all key-values in table `B` against target table `A`, using table `B` as a truth state \
---removes all key-values in table `A` that are not present in table `B` \
---overwrites key-value if `A[key]` has a type mismatch against `B[key]`
---@param A table<any, any> base table
---@param B table<any, any> not base table
function V_Table.Patch(A: {[any]: any}, B: {[any]: any})
	for k in A do
		if not B[k] then
			A[k] = nil
		end
	end
	for k, v in B do
		if type(A[k]) ~= type(v) then
			A[k] = v
		end
	end
end

---returns length of table<any, any> `T`
---@param T table<any, any> target table
---@return number Length table length
function V_Table.len(T: {}): number
	if type(next(T) :: any) ~= "number" then
		local n = 0
		for _ in T :: {any} do n += 1 end
		return n
	end
	return #T
end

---backwards-iterates through array any[] `A` and calls iterator function `f(i: number, v: any):ReverseIterAction|nil` on each value \
---useful in contexts where a value may be removed mid-iteration
---@param A any[] target array
---@param f fun(i: number, v: any):ReverseIterAction|nil
function V_Table.ipairsR(A: {any}, f: (i: number, v: any) -> number?)
	for i = #A, 1, -1 do
		local Result = f(i, A[i])
		if Result == 0 then
			table.remove(A, i)
		elseif Result == 1 then
			continue
		elseif Result == 2 then
			break
		end
	end
end

---removes & returns last element of array any[] `A`
---@param A any[] target array
---@return any ... any
function V_Table.Pop(A: {any}): any
	return table.remove(A)
end

---removes all occurrences of element `E` in array any[] `A`
---@param A any[] target array
---@param E any target element
function V_Table.PopE(A: {any}, E: any)
	if table.remove(A, table.find(A, E) or 0) == E then
		V_Table.PopE(A, E)
	else
		return
	end
end

---pops entire array any[] `A` and calls function `f` on each popped element
---@param A any[] target array
---@param f fun(...)
function V_Table.PopF(A: {}, f: (...any) -> (), ...: any)
	local x = table.remove(A)
	if x then
		task.defer(f, x, ...)
		V_Table.PopF(A, f, ...)
	else
		return
	end
end

---inserts any `v` into array any[] `A`, if and only if `v` is not already a member of `A`
---@param A any[] target array
---@param v any value
function V_Table.InsertSingle(A: {any}, v: any): ()
	if not table.find(A, v) then
		table.insert(A, v)
	end
end

---limits length of array any[] `A` to number `n`, removing all elements whose indices are > `n`
---@param A any[] target array
---@param n number
function V_Table.Limit(A: {any}, n: number)
	if #A > n then
		table.remove(A)
		V_Table.Limit(A, n)
	else
		return
	end
end

---returns elements of array `A` as a page with size `Size` and offset `Offset`
---```
---t = {} -- [1, ..., 25]
---Page(t, 10, 1) -- [1, ..., 10]
---Page(t, 10, 2) -- [11, ..., 20]
---Page(t, 10, 3) -- [21, ..., 25]
---Page(t, 10, 4) -- []
---```
---@param A any[] target array
---@param Size number page size as # of elements
---@param Offset number offset (starts at 1)
---@return any[] ArrayPage ArrayPage
function V_Table.Page(A: {any}, Size: number, Offset: number): {any}
	local Max = #A
	local x = 1 + math.clamp((Offset - 1) * Size, 0, Max)
	local y = math.clamp(Offset * Size, 0, Max)
	return table.move(A, x, y, 1, table.create(Max))
end

return table.freeze(V_Table)