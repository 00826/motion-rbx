local SpeedState = {}

---@diagnostic disable-next-line: undefined-type
function SpeedState.Create(): buffer
	return buffer.create(31)
end

---@diagnostic disable-next-line: undefined-type
function SpeedState.EvaluateSprint(sBuffer: buffer): boolean
	local Now = os.clock()
	local Cooldown = buffer.readu16(sBuffer, 10) * 0.001
	local Recent = buffer.readf32(sBuffer, 12)
	if (Recent + Cooldown) < Now then
		buffer.writef32(sBuffer, 12, Now)
		return true
	end
	return false
end

function SpeedState.SolveDecayScalar(Since: number, DecayTime: number): number
	return (1 - math.clamp((Since / DecayTime), 0, 1))
end

return table.freeze(SpeedState)