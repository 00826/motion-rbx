local BaseState = {}

---@diagnostic disable-next-line: undefined-type
function BaseState.Create(): buffer
	return buffer.create(6)
end

return table.freeze(BaseState)