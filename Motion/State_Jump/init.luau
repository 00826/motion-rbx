local JumpState = {}

function JumpState.Create(): buffer
	return buffer.create(13)
end

function JumpState.Evaluate(jBuffer: buffer, DesiredState: boolean): boolean
	if DesiredState == true then
		local Now = os.clock()
		local Cooldown = buffer.readu16(jBuffer, 4) * 0.001
		local Recent = buffer.readf32(jBuffer, 6)
		if (Recent + Cooldown) < Now then
			buffer.writef32(jBuffer, 6, Now)
			return true
		end
	end
	return false
end

return table.freeze(JumpState)