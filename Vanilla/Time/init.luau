--!strict

local RunService			= game:GetService("RunService")
local IsServer				= RunService:IsServer()

local TimeRemote			= script:WaitForChild("TimeRemote")

local TimeBuffer			= buffer.create(4)
buffer.writef32(TimeBuffer, 0, 0)

if IsServer then
	local Elapsed, Rate = 0, 1 / 60
	local function UpdateTime(t, dt)
		buffer.writef32(TimeBuffer, 0, t)

		Elapsed += dt
		if Elapsed < Rate then return end
		Elapsed -= Rate

		TimeRemote:FireAllClients(TimeBuffer)
	end
	UpdateTime(0, Rate)
	RunService.Stepped:Connect(UpdateTime)
else
	---@diagnostic disable-next-line: undefined-type
	TimeRemote.OnClientEvent:Connect(function(tBuffer: buffer)
		buffer.copy(TimeBuffer, 0, tBuffer, 0, 4)
	end)
end

local function subf(x: string): string
	return #x == 1 and "0" .. x or x
end

---### Time.luau
---
---server-authoritative global time
local Time = {__index = {}}

---returns vanilla time `Time`
---@return number TimeResult time result
Time.__call = function(): number
	return buffer.readf32(TimeBuffer, 0)
end

---returns furthest-ahead time between number `n` and vanilla time
---@param n? number Time
---@return number Furthest furthest-ahead time
function Time.__index.Furthest(n: number?): number
	return math.max(n or 0, buffer.readf32(TimeBuffer, 0))
end

---runs function `f` in second intervals of number `n`
---@param n number Time
---@param f fun()
function Time.__index.Framerule(n: number, f: () -> ()): RBXScriptConnection
	local T = 0
	local function Frame(dt)
		T += dt
		if T < n then return end
		T -= n
		f()
	end
	f()
	return RunService.Heartbeat:Connect(Frame)
end

---formats seconds `S` into respective notation `Notation`
---@param S number seconds
---@param Notation string default: `os.date("!%X", S)`
---| '"DD:HH:MM:SS"' # `100000` --> `"01:03:46:40"`
---| '"HH:MM:SS"' # `86401` --> `"24:00:01"`
---| '"MM:SS"' # `7201` --> `"120:01"`
---| '"M:SS"' # `599` --> `"9:59"`
function Time.__index.Notation(S: number, Notation: string?): string
	--[[
		os.date("!%X", S) is the fastest for all inputs below 86400, because any input at or above 86400 breaks the formatting
		:format:gsub(x, subf) is the second fastest for all inputs, never has a formatting break, but is ~10% slower than os.date("!%X", S)
		combining both through comparing S >= 86400 gives a faster average across all possible inputs
	]]
	if Notation == "DD:HH:MM:SS" then
		if S >= 86400 then
			local D = math.floor(S / 86400)
			S -= D * 86400
			local H = math.floor(S / 3600)
			S -= H * 3600
			local M = math.floor(S / 60)
			S -= M * 60
			return ("%d:%d:%d:%d"):format(D, H, M, S):gsub("%d+", subf)
		else
			return "00:" .. os.date("!%X", S)
		end
	elseif Notation == "HH:MM:SS" then
		if S >= 86400 then
			local H = math.floor(S / 3600)
			S -= H * 3600
			local M = math.floor(S / 60)
			S -= M * 60
			return ("%d:%d:%d"):format(H, M, S):gsub("%d+", subf)
		else
			return os.date("!%X", S)
		end
	elseif Notation == "MM:SS" then
		if S >= 3600 then
			local M = math.floor(S / 60)
			S -= M * 60
			return ("%d:%d"):format(M, S):gsub("%d+", subf)
		else
			return os.date("!%X", S):sub(4, 8)
		end
	elseif Notation == "M:SS" then
		return os.date("!%X", S):sub(4, 8):gsub("^0", "")
	end
	return os.date("!%X", S)
end

---returns UTC TimeFormatResult with respect to string `Format` or minute interval number \
---formatting `TimeFormatResult.Until` into HH:MM:SS notation is expensive and should be done separately
---@param Format TimeFormatString|number TimeFormatString or second number
---@return TimeFormatResult TimeFormatResult TimeFormatResult
function Time.__index.Format(Format: string|number): {}
	--[[
		~30% faster than 2 os.date("!*t) calls
		unpack(table.create(2, os.date("!*t"))) is cool and is also a one-liner but creates 2 references that point to the same memory address
	]]
	local T0 = os.date("!*t")
	local T1 = table.clone(T0)

	---@type TimeFormatResult
	local Result = {
		Timestamp = "";
		Seed = 0;
		Until = 0;
	}
	if type(Format) == "number" then
		---`Format: 5`
		---`February 14, 2024, 06:44` --> `"2024_45_6_8"`
		---`Format: 10`
		---`February 14, 2024, 06:44` --> `"2024_45_6_4"`
		---`Format: 15`
		---`February 14, 2024, 06:44` --> `"2024_45_6_2"`
		T1.min = Format * math.ceil((T1.min + 1) / Format)
		T1.sec = 0

		local Year, YDay, Hour, QtrHour = T0.year, T0.yday, T0.hour, math.ceil((T0.min + 1) / Format) - 1
		Result.Timestamp = ("%d_%d_%d_%d"):format(Year, YDay, Hour, QtrHour)
		Result.Seed = tonumber(Year .. YDay .. Hour .. QtrHour) :: number
	else
		if Format == "Hour" then
			---`February 14, 2024, 06:44` --> `"2024_45_6"`
			T1.hour = math.floor(T1.hour + 1)
			T1.min = 0
			T1.sec = 0

			local Year, YDay, Hour = T0.year, T0.yday, T0.hour
			Result.Timestamp = ("%d_%d_%d"):format(Year, YDay, Hour)
			Result.Seed = tonumber(Year .. YDay .. Hour) :: number
		elseif Format == "Biphase" then
			---`February 14, 2024, 06:44` --> `"2024_45_AM"`
			---`February 14, 2024, 16:44` --> `"2024_45_PM"`
			T1.hour = 12 * math.ceil((T1.hour + 1) / 12)
			T1.min = 0
			T1.sec = 0

			local Year, YDay, Phase = T0.year, T0.yday, os.date("!%p")
			Result.Timestamp = ("%d_%d_%s"):format(Year, YDay, Phase)
			Result.Seed = tonumber(Year .. YDay .. Phase:byte()) :: number
		elseif Format == "Day" then
			---`February 14, 2024` --> `"2024_45"`
			T1.day += 1
			T1.hour = 0
			T1.min = 0
			T1.sec = 0

			local Year, YDay = T0.year, T0.yday
			Result.Timestamp = ("%d_%d"):format(Year, YDay)
			Result.Seed = tonumber(Year .. YDay) :: number
		elseif Format == "Week" then
			---`February 14, 2024` --> `"2024_7_06"` (06th week of 2024)
			T1.day += 8 - T0.wday
			T1.hour = 0
			T1.min = 0
			T1.sec = 0

			local Year, Week, YWeek = T0.year, T0.wday, os.date("!%U")
			Result.Timestamp = ("%d_%d_%s"):format(Year, Week, YWeek)
			Result.Seed = tonumber(Year .. Week .. YWeek) :: number
		elseif Format == "Season" then
			---`February 14, 2024` --> `"2024_1"`
			---Mar-May: `1` (spring)
			---Jun-Aug: `2` (summer)
			---Sep-Nov: `3` (fall)
			---Dec-Feb: `4` (winter)
			T1.month += 1 + ((11 - math.ceil((T1.month - 3) % 12)) % 3)
			T1.day = 1
			T1.hour = 0
			T1.min = 0
			T1.sec = 0

			local Year, Month = T0.year, math.ceil((1 + ((T0.month - 3) % 12)) / 3)
			Result.Timestamp = ("%d_%d"):format(Year, Month)
			Result.Seed = tonumber(Year .. Month) :: number
		elseif Format == "Biseason" then
			---`February 14, 2024` --> `"2024_1"`
			---Jan-Jun: `1` (SS)
			---Jul-Dec: `2` (FW)
			T1.month = math.ceil(T1.month / 6)
			T1.day = 1
			T1.hour = 0
			T1.min = 0
			T1.sec = 0

			local Year, Month = T0.year, math.ceil(T0.month / 6)
			Result.Timestamp = ("%d_%d"):format(Year, Month)
			Result.Seed = tonumber(Year .. Month) :: number
		elseif Format == "Year" then
			---`February 14, 2024` --> `"2024"`
			T1.year += 1
			T1.month = 1
			T1.day = 1
			T1.hour = 0
			T1.min = 0
			T1.sec = 0

			Result.Timestamp = tostring(T0.year)
			Result.Seed = tonumber(T0.year) :: number
		end
	end

	Result.Until = os.time(T1) - os.time(T0)

	return Result
end

return setmetatable({}, Time)