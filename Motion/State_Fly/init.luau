local FlyState = {}

---@diagnostic disable-next-line: undefined-type
function FlyState.Create(): buffer
	return buffer.create(18)
end

function FlyState.Effect(Rig: Model, StateActive: boolean): ()
end

return table.freeze(FlyState)