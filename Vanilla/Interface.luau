--!strict

local Constants				= require(script.Parent.Constants)
local Tween					= require(script.Parent.Tween)

local function ToCartesian(n: number, col: number): (number, number)
	n -= 1
	return math.floor(n / col), (n % col)
end

---### Interface.luau
---
---contains quality-of-life functions for UI development
local Interface = {
	ButtonSounds			= {};
}

function Interface.BCurve(A: number, Points: {UDim2}): UDim2
	if #Points > 1 then
		local NewPoints = {}
		for i = 1, #Points - 1 do
			table.insert(NewPoints, Points[i]:Lerp(Points[i + 1], A))
		end
		return Interface.BCurve(A, NewPoints)
	end
	return Points[1]
end

---Interface.PlaySound()
---@param SoundId ButtonSound ButtonSound
function Interface.PlaySound(SoundId: string, MuteError: boolean?): ()
	local Sound = Interface.ButtonSounds[SoundId]
	if not Sound then
		if not MuteError then
			warn(`{SoundId} was not imported as a button sound`)
		end
		return
	end
	local S = Sound:Clone()
	S.Parent = script
	S:Destroy()
end

---Interface.ImportButtonSounds()
---@param Sounds Sound[] SoundList
function Interface.ImportButtonSounds(Sounds: {Sound}): ()
	for _, Sound in Sounds do
		Interface.ButtonSounds[Sound.Name] = Sound
	end
end

---scrolls text of TextLabel `TextLabel` \
---optional text string `Text` \
---optional scroll speed number `Speed`
---@param TextLabel TextLabel target textlabel
---@param Text string? optional text
---@param Speed number? optional scroll speed (default: 30)
function Interface.ScrollText(TextLabel: TextLabel, Text: string?, Speed: number?): ()
	TextLabel.MaxVisibleGraphemes = 0
	if Text then TextLabel.Text = Text end
	local n = utf8.len(TextLabel.ContentText) or 0
	Tween(TextLabel, {MaxVisibleGraphemes = n}, n / (Speed or 40), Enum.EasingStyle.Sine)
	return
end

---connects button events to GuiButton `Button` as defined by table<string, fun(x: number, y: number)> `ConnectFunctions` \
---automatically plays associated sounds imported by Interface.ImportButtonSounds()
---@param Button GuiButton target guibutton
---@param ConnectFunctions ConnectFunctions ConnectFunctions
---@return RBXScriptConnection[] Connections array of RbxScriptConnections
function Interface.ConnectButton(Button: GuiButton, ConnectFunctions: {[string]: any}, MuteSounds: boolean?): {RBXScriptConnection}
	local t = table.create(7)
	if ConnectFunctions.ClickDown then
		table.insert(t, Button.MouseButton1Down:Connect(ConnectFunctions.ClickDown))
	end
	if ConnectFunctions.ClickUp then
		table.insert(t, Button.MouseButton1Up:Connect(function(...)
			ConnectFunctions.ClickUp(...)
			if MuteSounds == true then return end
			Interface.PlaySound("Click", true)
		end))
	end
	if ConnectFunctions.RClickDown then
		table.insert(t, Button.MouseButton2Down:Connect(ConnectFunctions.RClickDown))
	end
	if ConnectFunctions.RClickUp then
		table.insert(t, Button.MouseButton2Up:Connect(function(...)
			ConnectFunctions.RClickUp(...)
			if MuteSounds == true then return end
			Interface.PlaySound("Click", true)
		end))
	end
	if ConnectFunctions.Enter then
		local function Enter(...)
			ConnectFunctions.Enter(...)
			if MuteSounds == true then return end
			Interface.PlaySound("Hover", true)
		end
		table.insert(t, Button.MouseEnter:Connect(Enter))
		table.insert(t, Button.SelectionGained:Connect(Enter))
	end
	if ConnectFunctions.Leave then
		table.insert(t, Button.MouseLeave:Connect(ConnectFunctions.Leave))
		table.insert(t, Button.SelectionLost:Connect(ConnectFunctions.Leave))
	end
	if ConnectFunctions.Move then
		table.insert(t, Button.MouseMoved:Connect(ConnectFunctions.Move))
	end
	return t
end

---sets Image property of ImageLabel or ImageButton `Image` with respect to SpriteInfo `SpriteInfo`
---sprite sheet must be square (2x2, 3x3, 4x4, etc)
---@param ImageObject ImageLabel|ImageButton target imageobject
---@param Settings SpriteSettings SpriteSettings
function Interface.ApplySprite(ImageObject: ImageLabel, Settings: {Position: number, SpriteInfo: {[string]: any}})
	local SpriteInfo = Settings.SpriteInfo
	ImageObject.Image = SpriteInfo.Id

	if SpriteInfo then
		local X, Y = ToCartesian(Settings.Position, SpriteInfo.Grid)
		local Padding = SpriteInfo.Padding or 0
		local Size = SpriteInfo.Size
		ImageObject.ImageRectSize = Size
		ImageObject.ImageRectOffset = Vector2.new((Y * Size.X) + (Y * Padding), (X * Size.Y) + (X * Padding))
	else
		ImageObject.ImageRectSize = Vector2.zero
		ImageObject.ImageRectOffset = Vector2.zero
	end
end

---synchronously iterates through all descendants of GuiObject `G` and hides any GuiObjects named string `Name`
---@param G GuiObject
function Interface.HideWithName(G: GuiObject, Name: string)
	task.spawn(function()
		for _, Thing in G:GetDescendants() do
			if Thing.Name ~= Name then continue end
			if not Thing:IsA("GuiObject") then continue end
			Thing.Visible = false
		end
	end)
end

---expands TextLabel T until the font fits
---@param T TextLabel TextLabel
---@param AutoTextBounds? boolean initially scale to text bounds
---@param OffsetY? number add size offset after scaling
function Interface.ScaleTextLabel(T: TextLabel, AutoTextBounds: boolean?, OffsetY: number?)
	if AutoTextBounds then
		local aY = T.AbsoluteSize.Y
		T.Size = UDim2.new(1, 0, 0, aY)
		T.TextSize = aY
	end
	T.TextWrapped = true
	if not T.TextFits then
		repeat
			T.Size += Constants.UDimOffsetY
		until T.TextFits
	end
	if OffsetY then
		T.Size += UDim2.fromOffset(0, OffsetY)
	end
end

---attaches GuiObject Thing to TextLabel T with respect to string Alignment
---@param T TextLabel TextLabel
---@param Thing GuiObject GuiObject
---@param Alignment Alignment GuiObject alignment
---@param Offset number padding between the T.Text and Thing
function Interface.AppendToTextLabel(T: TextLabel, Thing: GuiObject, Alignment: "Left" | "Right", Offset: number)
	local TextX = T.TextBounds.X
	local RealOffset = UDim2.fromOffset(0, 0)
	if Alignment == "Left" then
		Thing.AnchorPoint = Constants.Vector2Right
		RealOffset = UDim2.fromOffset(-Offset, 0)
	elseif Alignment == "Right" then
		Thing.AnchorPoint = Constants.Vector2Left
		RealOffset = UDim2.fromOffset(Offset, 0)
	end
	if T.TextXAlignment == Enum.TextXAlignment.Left then
		if Alignment == "Left" then
			Thing.Position = Constants.UDimLeft
		elseif Alignment == "Right" then
			Thing.Position = UDim2.new(0, TextX, 0.5, 0)
		end
	elseif T.TextXAlignment == Enum.TextXAlignment.Right then
		if Alignment == "Left" then
			Thing.Position = UDim2.new(1, -TextX, 0.5, 0)
		elseif Alignment == "Right" then
			Thing.Position = Constants.UDimRight
		end
	elseif T.TextXAlignment == Enum.TextXAlignment.Center then
		if Alignment == "Left" then
			Thing.Position = UDim2.new(0.5, -TextX * 0.5, 0.5, 0)
		elseif Alignment == "Right" then
			Thing.Position = UDim2.new(0.5, TextX * 0.5, 0.5, 0)
		end
	end
	Thing.Position += RealOffset
end

---returns position of GuiObject Subject @ screen position (x, y), clamped within GuiObject Container
---@param x number screen position x
---@param y number screen position y
---@param Subject GuiObject Subject
---@param Container GuiObject Container
---@return UDim2 ScreenPosition clamped position
function Interface.ClampPosition(x: number, y: number, Subject: GuiObject, Container: GuiObject): UDim2
	local pX, pY = (x - Container.AbsolutePosition.X), (y - Container.AbsolutePosition.Y - 36)

	local dY = math.abs(math.clamp(Container.AbsoluteSize.Y - (pY + Subject.AbsoluteSize.Y), -math.huge, 0))
	return UDim2.fromOffset(pX, pY - dY)
end

---creates a clone of GuiObject Template named by string Name; automatically parented to Template.Parent \
---optional LayoutOrder
---@param Template GuiObject Template GuiObject
---@param Name string name of cloned Template
---@param LayoutOrder? number optional GuiObject.LayoutOrder
---@return GuiObject Clone clone of Template
function Interface.QuickClone(Template: GuiObject, Name: string, LayoutOrder: number?): GuiObject
	local T = Template:Clone()
	T.Name = Name or "UnnamedClone"
	T.Parent = Template.Parent
	T.LayoutOrder = LayoutOrder or 0
	T.Visible = true
	return T
end

---iterates through members of {GuiObject} | GuiObject Container, then hides members whose names match vararg string
---if no strings are provided, then all members will be hidden by default
---@param Container GuiObject[]|GuiObject Container
---@vararg ...? string Names to compare
function Interface.ToggleContents(Container: any, ...: string)
	local Names = {...}
	local AutoHide = #Names == 0
	for _, Thing: GuiObject in typeof(Container) == "Instance" and Container:GetChildren() or Container do
		local s = pcall(function() local _ = Thing.Visible end)
		if not s then continue end
		if AutoHide then
			Thing.Visible = false
		else
			Thing.Visible = table.find(Names, Thing.Name) ~= nil
		end
	end
end

---Adjusts UIGridLayout GridLayout's CellSize until its AbsoluteCellCount == number Columns
---@param GridLayout UIGridLayout target UIGridLayout
---@param Columns number target # of columns
function Interface.AdjustGridLayout(GridLayout: UIGridLayout, Columns: number)
	if GridLayout:GetAttribute("Adjustment") == Columns then return end
	GridLayout:SetAttribute("Adjustment", Columns)
	GridLayout.CellSize = Constants.UDimOne
	local Placeholders = {}
	if GridLayout.AbsoluteCellCount.X * GridLayout.AbsoluteCellCount.Y < Columns then
		for i = 1, Columns do
			local nt = Instance.new("Frame")
			nt.Name = "__placeholder_" .. i
			nt.Visible = true
			nt.Parent = GridLayout.Parent
			table.insert(Placeholders, nt)
		end
	end
	repeat
		GridLayout.CellSize -= Constants.UDimOffsetX
	until GridLayout.AbsoluteCellCount.X == Columns

	if #Placeholders == 0 then return end
	for _, f in Placeholders do
		f:Destroy()
	end
end

---automatically scales the CanvasSize of ScrollingFrame ScrollingFrame to fit its contents with respect to its UIGridLayout or UIListLayout
---@param ScrollingFrame ScrollingFrame
---@return RBXScriptConnection Connection LayoutObject:GetPropertyChangedSignal("AbsoluteContentSize")
function Interface.AutoScrollScale(ScrollingFrame: ScrollingFrame): RBXScriptConnection?
	local LayoutObject = ScrollingFrame:FindFirstChildOfClass("UIGridLayout") or ScrollingFrame:FindFirstChildOfClass("UIListLayout")
	if not LayoutObject then return end
	local PaddingObject = ScrollingFrame:FindFirstChildOfClass("UIPadding")
	local Height = LayoutObject.AbsoluteContentSize.Y
	local Compound = 0
	if PaddingObject then
		Compound += PaddingObject.PaddingTop.Offset
		Compound += PaddingObject.PaddingBottom.Offset
	end
	ScrollingFrame.CanvasSize = UDim2.fromOffset(0, math.ceil(Height + Compound))

	return LayoutObject:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ScrollingFrame.CanvasSize = UDim2.fromOffset(0, math.ceil(LayoutObject.AbsoluteContentSize.Y + Compound))
	end)
end

---automatically scales the Size of `Frame` Backdrop to UILayout `LayoutObject`
---@param LayoutObject UIGridLayout|UIListLayout target LayoutObject
---@param Backdrop Frame target Backdrop
---@param Axis ContentAxis Axis
---@return RBXScriptConnection Connection LayoutObject:GetPropertyChangedSignal("AbsoluteContentSize")
function Interface.MatchContentScale(LayoutObject: any, Backdrop: Frame, Axis: "X" | "Y"): RBXScriptConnection?
	local PaddingObject = LayoutObject.Parent:FindFirstChildOfClass("UIPadding")
	local Compound = 0
	if PaddingObject then
		if Axis == "X" then
			Compound += PaddingObject.PaddingLeft.Offset
			Compound += PaddingObject.PaddingRight.Offset
		elseif Axis == "Y" then
			Compound += PaddingObject.PaddingTop.Offset
			Compound += PaddingObject.PaddingBottom.Offset
		end
	end

	local function UpdateSize()
		local Stretch = LayoutObject.AbsoluteContentSize[Axis]
		local Real = Stretch > 1 and math.ceil(Stretch + Compound) or 0
		if Axis == "X" then
			Backdrop.Size = UDim2.new(0, Real, 1, 0)
		elseif Axis == "Y" then
			Backdrop.Size = UDim2.new(1, 0, 0, Real)
		end
	end

	UpdateSize()
	return LayoutObject:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSize)
end

---sets UDim `Pad` to Top/Left/Right/BottomPadding value of UIPadding `UIPadding`
---@param UIPadding UIPadding
---@param Pad UDim2
function Interface.Pad(UIPadding: UIPadding, Pad: UDim): ()
	UIPadding.PaddingTop = Pad
	UIPadding.PaddingLeft = Pad
	UIPadding.PaddingRight = Pad
	UIPadding.PaddingBottom = Pad
end

---creates a unit circle with number `V` vertices, radius number `Radius`, and optional initial angle offset `Initial`
---@param V number # number of vertices
---@param R number radius of the circle
---@param Theta number initial angle offset
---@return UDim2[] U UDim2 coordinates
function Interface.UnitCircle(V: number, R: number, Theta: number): {UDim2}
	local Results = table.create(V)

	local Start = math.rad(Theta or 0)
	local Step = Constants.mathpi2 / V

	for i = 1, V do
		i -= 1
		local a = (i * Step) + Start
		local U = UDim2.fromScale(R * math.cos(a), R * math.sin(a)) + Constants.UDimHalf
		table.insert(Results, U)
	end

	return Results
end

---formats number `n` with: \
---optional abbreviation limit number `Abbreviate` \
---optional comma limit number `Comma` \
---optional decimal places number `Decimals`
---```
---Interface.FormatNumber(152813) --> "152.8K"
---Interface.FormatNumber(9525) --> "9,525"
---```
---@param n number target number
---@param Abbreviate number abbreviate limit
---@param Comma number comma limit
---@param Decimals number decimal places if abbreviated
---@return string FormattedNumber formatted number
function Interface.FormatNumber(n: number, Abbreviate: number?, Comma: number?, Decimals: number?): string
	if n >= (Abbreviate or 10000) then
		return Interface.AbbreviateNumber(n, Decimals or 1)
	elseif n >= (Comma or 1000) then
		return Interface.CommaNumber(n)
	end
	return tostring(n)
end

---formats number `n` with commas
---@param n number target number
---@return string CommaNumber comma number
function Interface.CommaNumber(n: number): string
	if math.abs(n) < 1000 then return tostring(n) end
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
end

---abbreviates number `n` with decimal places number DecimalPlaces
---@param n number target number
---@param DecimalPlaces number decimal places
---@return string AbbNumber abbreviated number
function Interface.AbbreviateNumber(n: number, DecimalPlaces: number): string
	local exp = math.floor(math.log(math.max(1, math.abs(n)), 1000))
	local suffix = Constants.Suffixes[1 + exp] or ("e+" .. exp)
	local norm = math.floor(n * ((10 ^ DecimalPlaces) / (1000 ^ exp))) / (10 ^ DecimalPlaces)

	return ("%." .. DecimalPlaces .. "f%s"):format(norm, suffix)
end

---reconciles table<string, Frame> `FrameCache` against table<string, any> `KeyTable`, using `KeyTable` as a truth state
---@param FrameCache table<string, Frame>
---@param KeyTable table<string, any>
function Interface.ReconcileFrames(FrameCache: {[string]: Frame}, KeyTable: {}): ()
	for k, Frame in FrameCache do
		if KeyTable[k] then continue end
		Frame:Destroy()
		FrameCache[k] = nil
	end
	return
end

return Interface