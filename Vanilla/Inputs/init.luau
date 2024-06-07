--!strict

local RunService			= game:GetService("RunService")
local IsServer				= RunService:IsServer()

local Players				= game:GetService("Players")

local UIS					= game:GetService("UserInputService")
local GuiService			= game:GetService("GuiService")
local GamepadService		= game:GetService("GamepadService")

local Bind					= require(script.Parent.Bind)
local Collisions			= require(script.Parent.Collisions)
local Constants				= require(script.Parent.Constants)

local ConversionTable		= Constants.PlatformConversions

local LocalPlayer: Player|any
local PlayerGui: PlayerGui|any

local Camera				= workspace.CurrentCamera

local InputTable			= {
	Vector3.zero;				-- mouse position
	Vector3.zAxis;				-- camera direction
	Vector3.yAxis;				-- mouse surface normal
	Vector3.zero;				-- character floor normal
}
local InputMaxSize			= #InputTable * 12

local Inset					= GuiService:GetGuiInset()
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
	Inset = GuiService:GetGuiInset()
end)

---### Inputs.luau
---
---`UserInputService` wrapper \
---compatible with mobile, gamepad, k&m
---uses buffers to nicely replicate client inputs
local Inputs = {
	Connections					= {} :: {[string]: {[() -> ()]: any}};
	TouchEnabled				= UIS.TouchEnabled;
	---@type InputPlatformId
	Platform					= 0;
	MobileScreenCenter			= nil :: () -> (Vector2)?;
	AssistMousePosition			= nil :: () -> (Vector2)?;
	GamepadCursorEnabled		= false;

	InputTimes					= {} :: {[Enum.KeyCode]: number};
	DoubleTapTime				= 0.2;
	ChordTime					= 0.1;
	LongPressTime				= 0.3;

	RefreshRate					= 1/50;
	Blacklist					= table.create(8);
	Remote						= script:WaitForChild("InputRemote");

	BufferCache					= {};
}

---reads Vector3 `V` from Client `C`'s input buffer offset `i`
---@param i InputBufferOffset buffer offset
---@param C Player|Model|nil Player, Player-Character, or LocalPlayer if called locally
---@return Vector3 V vector input
function Inputs.Read(i: number, C: (Player|Model)?): Vector3
	local Buffer = Inputs.BufferCache[Players:GetPlayerFromCharacter(C) or C or LocalPlayer]
	if Buffer then
		local Offset = (i - 1) * 12
		return Vector3.new(
			buffer.readf32(Buffer, Offset + 0),
			buffer.readf32(Buffer, Offset + 4),
			buffer.readf32(Buffer, Offset + 8)
		)
	end
	return InputTable[i]
end

---writes Vector3 `V` to Player `P`'s input buffer offset `i`
---@param i InputBufferOffset buffer offset
---@param V Vector3
function Inputs.Write(i: number, P: Player?, V: Vector3): boolean
	local Buffer = Inputs.BufferCache[P or LocalPlayer]
	if Buffer then
		local Offset = (i - 1) * 12
		buffer.writef32(Buffer, Offset + 0, V.X)
		buffer.writef32(Buffer, Offset + 4, V.Y)
		buffer.writef32(Buffer, Offset + 8, V.Z)
		return true
	end
	return false
end

local function UpdateMouse(InputObject: InputObject)
	local ScreenPosition = Vector2.zero
	if Inputs.Platform == 2 then
		local InputPosition = InputObject.Position
		if Inputs.MobileScreenCenter then
			InputPosition = Inputs.MobileScreenCenter() or InputPosition
		end
		ScreenPosition = Vector2.new(InputPosition.X, InputPosition.Y)
	else
		ScreenPosition = UIS:GetMouseLocation() - Inset --GuiService:GetGuiInset()
	end
	if Inputs.AssistMousePosition then
		ScreenPosition = Inputs.AssistMousePosition() or ScreenPosition
	end

	local UnitRay = Camera:ScreenPointToRay(ScreenPosition.X, ScreenPosition.Y)
	local Result = Collisions.RayBlacklist(UnitRay.Origin, UnitRay.Direction * 10000, Inputs.Blacklist)

	Inputs.Write(1, LocalPlayer, Result and Result.Position or (UnitRay.Origin + (UnitRay.Direction * 10000)))
	Inputs.Write(2, LocalPlayer, Camera.CFrame.LookVector)
	Inputs.Write(3, LocalPlayer, Result and Result.Normal or Vector3.yAxis)
end

local function MoveSinkCheck(InputObject: InputObject): boolean
	if not PlayerGui then return false end
	if Inputs.Platform == 2 then
		local P = InputObject.Position
		local A: {GuiObject} = PlayerGui:GetGuiObjectsAtPosition(P.X, P.Y)
		if #A == 0 then
			return true
		else
			for _, GuiObject in A do
				if GuiObject.Name ~= "DynamicThumbstickFrame" then continue end
				return false
			end
		end
	end
	return true
end

if IsServer then
	---@diagnostic disable-next-line: undefined-type
	Inputs.Remote.OnServerEvent:Connect(function(Player: Player, InputBuffer: buffer)
		---@diagnostic disable-next-line: invalid-class-name
		if type(InputBuffer) ~= "buffer" then return end
		local CachedBuffer = Inputs.BufferCache[Player]
		if not CachedBuffer then
			Inputs.BufferCache[Player] = buffer.create(InputMaxSize)
			CachedBuffer = Inputs.BufferCache[Player]
		end

		buffer.copy(CachedBuffer, 0, InputBuffer, 0, InputMaxSize)
	end)
	Players.PlayerAdded:Connect(function(Player: Player)
		Inputs.BufferCache[Player] = buffer.create(InputMaxSize)
	end)
	Players.PlayerRemoving:Connect(function(Player: Player)
		Inputs.BufferCache[Player] = nil
	end)
else
	LocalPlayer = Players.LocalPlayer
	PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	Inputs.BufferCache[LocalPlayer] = buffer.create(InputMaxSize)
	if UIS.KeyboardEnabled then
		Inputs.Platform = 1
	elseif UIS.MouseEnabled then
		Inputs.Platform = 1
	elseif UIS.TouchEnabled then
		Inputs.Platform = 2
	elseif GuiService:IsTenFootInterface() then
		Inputs.Platform = 3
	elseif UIS.GamepadEnabled then
		Inputs.Platform = 3
	else
		Inputs.Platform = ConversionTable[UIS:GetLastInputType()] or Inputs.Platform
	end

	UIS.InputBegan:Connect(function(InputObject: InputObject, ...)
		if not MoveSinkCheck(InputObject) then return end
		Bind("_VInputs_Began"):Fire(InputObject, ...)

		local Now, KeyCode = os.clock(), InputObject.KeyCode
		local KeyCodeTimeTable = Inputs.InputTimes

		do -- doubletap inputs
			local Then = KeyCodeTimeTable[KeyCode] or 0
			KeyCodeTimeTable[KeyCode] = Now
			if Now - Then < Inputs.DoubleTapTime then
				Bind("_VInputs_DoubleTap"):Fire(KeyCode)
			end
		end

		UpdateMouse(InputObject)
	end)
	UIS.InputEnded:Connect(function(...)
		Bind("_VInputs_Ended"):Fire(...)
		UpdateMouse(...)
	end)
	UIS.InputChanged:Connect(function(...)
		Bind("_VInputs_Changed"):Fire(...)
		UpdateMouse(...)
	end)
	UIS.TouchStarted:Connect(function(...)
		if not MoveSinkCheck(...) then return end
		Bind("_VInputs_Began"):Fire(...)
	end)
	UIS.TouchEnded:Connect(function(...)
		Bind("_VInputs_Ended"):Fire(...)
	end)
	UIS.TouchMoved:Connect(function(...)
		Bind("_VInputs_Changed"):Fire(...)
	end)
	UIS.LastInputTypeChanged:Connect(function(InputType: Enum.UserInputType)
		Inputs.TouchEnabled = UIS.TouchEnabled
		local CurrentPlatform = Inputs.Platform
		local ThisPlatform = ConversionTable[InputType] or Inputs.Platform
		Inputs.Platform = ThisPlatform
		if CurrentPlatform ~= ThisPlatform then
			Bind("_VInputs_PlatformChanged"):Fire(Inputs.Platform)
		end
		Bind("_VInputs_LastInputTypeChanged"):Fire(InputType)
	end)

	GamepadService:GetPropertyChangedSignal("GamepadCursorEnabled"):Connect(function()
		Inputs.GamepadCursorEnabled = GamepadService.GamepadCursorEnabled
		Bind("_VInputs_GamepadCursorStateChanged"):Fire(GamepadService.GamepadCursorEnabled)
	end)

	LocalPlayer.CharacterAdded:Connect(function(Character: Model)
		local Humanoid = Character:WaitForChild("Humanoid")
		Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
			Inputs.Write(4, LocalPlayer, Humanoid.FloorMaterial ~= Enum.Material.Air and Vector3.yAxis or Vector3.zero)
		end)
	end)

	local Elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		Elapsed += dt
		if Elapsed < Inputs.RefreshRate then return end
		Elapsed -= Inputs.RefreshRate
		Inputs.Remote:FireServer(Inputs.BufferCache[LocalPlayer])
	end)
end

---UserInputService.InputBegan
---@param f fun(InputObject: InputObject, SunkInput: boolean)
---@return fun() Disconnect disconnect function
function Inputs.Began(f: (InputObject: InputObject, SunkInput: boolean) -> ()): () -> ()
	return Bind("_VInputs_Began"):Connect(f)
end

---UserInputService.InputEnded
---@param f fun(InputObject: InputObject, SunkInput: boolean)
---@return fun() Disconnect disconnect function
function Inputs.Ended(f: (InputObject: InputObject, SunkInput: boolean) -> ()): () -> ()
	return Bind("_VInputs_Ended"):Connect(f)
end

---UserInputService.DoubleTap \
---fires when a key is double-tapped
---@param f fun(KeyCode: Enum.KeyCode)
---@return fun() Disconnect disconnect function
function Inputs.DoubleTap(f: (KeyCode: Enum.KeyCode) -> ()): () -> ()
	return Bind("_VInputs_DoubleTap"):Connect(f)
end

---UserInputService.InputChanged
---@param f fun(InputObject: InputObject, SunkInput: boolean)
---@return fun() Disconnect disconnect function
function Inputs.Changed(f: (InputObject: InputObject, SunkInput: boolean) -> ()): () -> ()
	return Bind("_VInputs_Changed"):Connect(f)
end

---UserInputService.InputChanged
---@param f fun(LastInputType: Enum.UserInputType)
---@return fun() Disconnect disconnect function
function Inputs.LastInputTypeChanged(f: (LastInputType: Enum.UserInputType) -> ()): () -> ()
	return Bind("_VInputs_LastInputTypeChanged"):Connect(f)
end

---Inputs.PlatformChanged \
---narrower-scope UserInputService.InputChanged
---@param f fun(PlatformId: InputPlatformId)
---@return fun() Disconnect disconnect function
function Inputs.PlatformChanged(f: (PlatformId: number) -> ()): () -> ()
	return Bind("_VInputs_PlatformChanged"):Connect(f)
end

---Inputs.GamepadCursorStateChanged \
---fires when a gamepad cursor is enabled/disabled
---@param f fun(GamepadCursorEnabled: boolean)
---@return fun() Disconnect disconnect function
function Inputs.GamepadCursorStateChanged(f: (GamepadCursorEnabled: boolean) -> ()): () -> ()
	return Bind("_VInputs_GamepadCursorStateChanged"):Connect(f)
end

function Inputs.SetMouseIconEnabled(Enabled: boolean): ()
	UIS.MouseIconEnabled = Enabled
end

return Inputs