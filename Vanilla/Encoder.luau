--!strict

local HttpService			= game:GetService("HttpService")

local Prefix, Suffix		= "%f[A-Za-z]", "%f[^A-Za-z]:(%d+)"

---### Encoder.luau
---
---encodes/decodes/solves shallow table<string, number> tables as strings to be stored as attributes \
---example case for player stats:
---```
---Encoder.Encode({str = 2, dex = 10, int = 7}) --> "str:2/dex:10/int:7"
---Encoder.Decode("str:2/dex:10/int:7") --> {str = 2, dex = 10, int = 7}
---Encoder.Sum("str:2/dex:10/int:7", "str:4/dex:1/int:8/crit:5") --> {str = 6, dex = 11, int = 15, crit = 5}
---```
local Encoder = {}

---returns a string `StatString` from provided table `StatTable`
---@param StatTable table<string, number> StatTable
---@return string StatString StatString
function Encoder.Encode(StatTable: {[string]: number}): string
	if not StatTable then return "" end
	if next(StatTable) == nil then return "" end

	local StatString = ""
	for Key, Value in StatTable do
		StatString ..= Key ..":".. Value .. "/"
	end

	return StatString:sub(1, -2)
end

---returns a table `StatTable` from provided string `StatString`
---@param StatString string StatString
---@return table<string, number> StatTable StatTable
function Encoder.Decode(StatString: string): {[string]: number}
	if not StatString then return {} end
	if StatString == "" then return {} end

	local Data = {} :: {[string]: number|any}
	for _, KV in StatString:split("/") do
		local Split = KV:split(":")
		Data[Split[1]] = tonumber(Split[2])
	end

	return Data
end

---reads number Value of single string key `Key` in StatString `StatString`
---@param StatString string
---@param Key string
---@return number|nil Value value
function Encoder.Read(StatString: string, Key: string): number
	return tonumber(StatString:match(Prefix .. Key .. Suffix) or 0) or 0
end

---returns the sum of vararg strings StatStrings or table<string, number> StatTables as a table `StatTable`
---@vararg string | table<string, number> StatStrings or table<string, number>
---@return table<string, number> Result sum of varargs
function Encoder.Sum(...: string | {[string]: number}): {[string]: number}
	local Sum = {} -- table.create() omitted in favor of speed
	for _, StatTable in {...} do
		if type(StatTable) == "string" then
			StatTable = Encoder.Decode(StatTable)
		end
		if type(StatTable) ~= "table" then continue end
		for Key, Value in StatTable do
			Sum[Key] = (Sum[Key] or 0) + Value
		end
	end

	return Sum
end

---Encoder.SumStringVarargs()
function Encoder.SumStringVarargs(...: string): {[string]: number}
	local Sum = {}
	for _, StatString in {...} do
		for Key, Value in Encoder.Decode(StatString) do
			Sum[Key] = (Sum[Key] or 0) + Value
		end
	end
	return Sum
end

---Encoder.SumTableVarargs()
function Encoder.SumTableVarargs(...: {[string]: number}): {[string]: number}
	local Sum = {}
	for _, StatTable in {...} do
		for Key, Value in StatTable do
			Sum[Key] = (Sum[Key] or 0) + Value
		end
	end
	return Sum
end

---Encoder.SumTable()
function Encoder.SumTable(T: {[string]: {[string]: number}}): {[string]: number}
	local Sum = {}
	for _, StatTable in T do
		for Key, Value in StatTable do
			Sum[Key] = (Sum[Key] or 0) + Value
		end
	end
	return Sum
end

---generates GUID \
---optional length `len` (default: 8)
---@return string GUID GUID
function Encoder.GUID(len: number?): string
	return HttpService:GenerateGUID(false):gsub("-", ""):sub(1, (len or 8))
end

return Encoder