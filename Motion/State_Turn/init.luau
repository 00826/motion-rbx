local TurnState = {}

function TurnState.Create(): buffer
	return buffer.create(12)
end

return table.freeze(TurnState)