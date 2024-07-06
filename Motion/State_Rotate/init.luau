local TurnState = {}

function TurnState.Create(): buffer
	return buffer.create(32)
end

return table.freeze(TurnState)