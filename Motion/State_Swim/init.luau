local SwimState = {}

function SwimState.Create(): buffer
	return buffer.create(13)
end

function SwimState.Effect(Rig: Model, StateActive: boolean): ()
end

return table.freeze(SwimState)