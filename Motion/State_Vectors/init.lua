local VectorState = {}

---@diagnostic disable-next-line: undefined-type
function VectorState.Create(): buffer
	return buffer.create(84)
end

---@diagnostic disable-next-line: undefined-type
function VectorState.Write(b: buffer, offset: number, V: Vector3)
	buffer.writef32(b, offset, V.X)
	buffer.writef32(b, offset + 4, V.Y)
	buffer.writef32(b, offset + 8, V.Z)
end

---@diagnostic disable-next-line: undefined-type
function VectorState.Read(b: buffer, offset: number): Vector3
	return Vector3.new(
		buffer.readf32(b, offset),
		buffer.readf32(b, offset + 4),
		buffer.readf32(b, offset + 8)
	)
end

return table.freeze(VectorState)