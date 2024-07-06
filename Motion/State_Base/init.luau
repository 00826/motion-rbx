local BaseState = {}

function BaseState.Create(): buffer
	return buffer.create(6)
end

return table.freeze(BaseState)