local TurnState = {}

---@diagnostic disable-next-line: undefined-type
function TurnState.Create(): buffer
	return buffer.create(32)
end

return table.freeze(TurnState)