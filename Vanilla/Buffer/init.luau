--!strict

---save me nightrains... save me...
---@class buffer

---@alias bufferEntry
---| '"i8"' # [ -127, 127 ] signed 8-bit integer
---| '"u8"' # [ 0, 255 ] unsigned 8-bit integer
---| '"i16"' # [ -32,768, 32,767 ] signed 16-bit integer
---| '"u16"' # [ 0, 65,535 ] unsigned 16-bit integer
---| '"i32"' # [ -2,147,483,648, 2,147,483,647 ] signed 32-bit integer
---| '"u32"' # [ 0, 4,294,967,295 ] unsigned 32-bit integer
---| '"f32"' # [ ±3.40 * 10^38 ] 32-bit float
---| '"f64"' # [ ±1.80 * 10^308 ] 64-bit float
---| '"string"' # string
---| '"Vector3"' # Vector3
---| '"CFrame"' # CFrame
---| '"boolean"' # boolean

local Sizes = table.freeze{
	i8			= 1;
	u8			= 1;
	i16			= 2;
	u16			= 2;
	i32			= 4;
	u32			= 4;
	f32			= 4;
	f64			= 8;
	Vector3		= 12;	-- (x,y,z) * f32
	CFrame		= 18;	-- ((x,y,z) * f32) + ((rx,ry,rz) * u16)
	boolean		= 1;	-- `1 == true` `0 == false`
}

---### Buffer.luau
---
---buffer library with support for `Vector3`, `CFrame`, `boolean` types
local V_Buffer = {
	---Creates a buffer of the requested size with all bytes initialized to 0. \
	---Size limit is 1GB or 1,073,741,824 bytes.
	---@type fun(b: buffer, size: number): buffer
	create = buffer.create;

	---Copy `count` bytes from `source` starting at offset `sourceOffset` into the `target` at `targetOffset`. \
	---It is possible for `source` and `target` to be the same. Copying an overlapping region inside the same buffer acts as if the source region is copied into a temporary buffer and then that buffer is copied over to the target. \
	---If `sourceOffset` is nil or is omitted, it defaults to 0. \
	---If `count` is `nil` or is omitted, the whole `source` data starting from `sourceOffset` is copied.
	---@type fun(target: buffer, targetOffset: number, source: buffer, sourceOffset?: number, count?: number)
	copy = buffer.copy;

	---Sets the `count` bytes in the buffer starting at the specified `offset` to the `value`. \
	---If `count` is `nil` or is omitted, all bytes from the specified offset until the end of the buffer are set.
	---@type fun(b: buffer, offset: number, value: number, count?: number)
	fill = buffer.fill;

	---Reads signed 8-bit integer `[-127, 127]` from buffer \
	---`"char"` `1` byte size
	---@type fun(b: buffer, offset: number): number
	readi8 = buffer.readi8;
	---Writes signed 8-bit integer [-127, 127] to buffer
	---@type fun(b: buffer, offset: number, value: number)
	writei8 = buffer.writei8;

	---Reads unsigned 8-bit integer `[0, 255]` from buffer \
	---`"unsigned char"` `1` byte size
	---@type fun(b: buffer, offset: number): number
	readu8 = buffer.readu8;
	---Writes unsigned 8-bit integer `[0, 255]` to buffer
	---@type fun(b: buffer, offset: number, value: number)
	writeu8 = buffer.writeu8;

	---Reads signed 16-bit integer `[-32,768, 32,768]` from buffer \
	---`"short"` `2` byte size
	---@type fun(b: buffer, offset: number): number
	readi16 = buffer.readi16;
	---Writes signed 16-bit integer `[-32,768, 32,768]` to buffer
	---@type fun(b: buffer, offset: number, value: number)
	writei16 = buffer.writei16;

	---Reads unsigned 16-bit integer `[0, 65,535]` from buffer \
	---`"unsigned short"` `2` byte size
	---@type fun(b: buffer, offset: number): number
	readu16 = buffer.readu16;
	---Writes unsigned 16-bit integer `[0, 65,535]` to buffer
	---@type fun(b: buffer, offset: number, value: number)
	writeu16 = buffer.writeu16;

	---Reads signed 32-bit integer `[-2,147,483,648, 2,147,483,647]` from buffer \
	---`"long"` `4` byte size
	---@type fun(b: buffer, offset: number): number
	readi32 = buffer.readi32;
	---Writes signed 32-bit integer `[-2,147,483,648, 2,147,483,647]` to buffer
	---@type fun(b: buffer, offset: number, value: number)
	writei32 = buffer.writei32;

	---Reads unsigned 32-bit integer `[0, 4,294,967,295]` from buffer \
	---`"unsigned long"` `4` byte size
	---@type fun(b: buffer, offset: number): number
	readu32 = buffer.readu32;
	---Writes unsigned 32-bit integer `[0, 4,294,967,295]` to buffer
	---@type fun(b: buffer, offset: number, value: number)
	writeu32 = buffer.writeu32;

	---Reads 32-bit float `[±3.40 * 10^38]` from buffer \
	---`"float"` `4` byte size
	---@type fun(b: buffer, offset: number): number
	readf32 = buffer.readf32;
	---Writes 32-bit float `[±3.40 * 10^38]` to buffer
	---@type fun(b: buffer, offset: number, value: number)
	writef32 = buffer.writef32;

	---Reads 64-bit float `[±1.80 * 10^308]` from buffer \
	---`"double"` `8` byte size
	---@type fun(b: buffer, offset: number): number
	readf64 = buffer.readf64;
	---Writes 64-bit float `[±1.80 * 10^308]` to buffer
	---@type fun(b: buffer, offset: number, value: number)
	writef64 = buffer.writef64;

	---Reads string from buffer \
	---`#string` byte size
	---@type fun(b: buffer, offset: number, count: number): string
	readstring = buffer.readstring;
	---Writes string to buffer
	---@type fun(b: buffer, offset: number, value: number, count?: number)
	writestring = buffer.writestring;
}

---Reads Vector3 from buffer
---@diagnostic disable-next-line: undefined-type
function V_Buffer.readVector3(b: buffer, offset: number): Vector3
	return Vector3.new(
		buffer.readf32(b, offset),
		buffer.readf32(b, offset + 4),
		buffer.readf32(b, offset + 8)
	)
end

---Writes Vector3 to buffer
---@diagnostic disable-next-line: undefined-type
function V_Buffer.writeVector3(b: buffer, offset: number, value: Vector3): ()
	buffer.writef32(b, offset, value.X)
	buffer.writef32(b, offset + 4, value.Y)
	buffer.writef32(b, offset + 8, value.Z)
end

---Reads CFrame from buffer
---@diagnostic disable-next-line: undefined-type
function V_Buffer.readCFrame(b: buffer, offset: number): CFrame
	return CFrame.new(
		buffer.readf32(b, offset),
		buffer.readf32(b, offset + 4),
		buffer.readf32(b, offset + 8)
	) * CFrame.fromOrientation(
		buffer.readi16(b, offset + 12) / 100,
		buffer.readi16(b, offset + 14) / 100,
		buffer.readi16(b, offset + 16) / 100
	)
end

---Writes CFrame to buffer
---@diagnostic disable-next-line: undefined-type
function V_Buffer.writeCFrame(b: buffer, offset: number, value: CFrame): ()
	buffer.writef32(b, offset, value.X)
	buffer.writef32(b, offset + 4, value.Y)
	buffer.writef32(b, offset + 8, value.Z)

	local rx, ry, rz = value:ToOrientation()
	buffer.writei16(b, offset + 12, rx * 100)
	buffer.writei16(b, offset + 14, ry * 100)
	buffer.writei16(b, offset + 16, rz * 100)
end

---Reads boolean from buffer
---@diagnostic disable-next-line: undefined-type
function V_Buffer.readboolean(b: buffer, offset: number): boolean
	return buffer.readu8(b, offset) == 1
end

---Writes boolean to buffer
---@diagnostic disable-next-line: undefined-type
function V_Buffer.writeboolean(b: buffer, offset: number, value: boolean?): ()
	buffer.writeu8(b, offset, value and 1 or 0)
end

---Creates a buffer based on byte size of datatype aliases
---@diagnostic disable-next-line: undefined-type
function V_Buffer.createFromTypes(datatypes: {string|number}): buffer
	local Size = 0
	for _, T in datatypes do
		if type(T) == "number" then
			Size += T
		elseif type(T) == "string" then
			Size += Sizes[T] or 0
		end
	end
	return buffer.create(Size)
end

return table.freeze(V_Buffer)