--!strict

---### Constants.luau
---
---contains constants used by Vanilla
return table.freeze{
	Random					= Random.new();
	f						= function() end;
	mathpi2					= math.pi * 2;

	FancastResolution		= 10;

	SeqZero					= NumberSequence.new(0);
	SeqOne					= NumberSequence.new(1);

	V3_yzAxis				= Vector3.new(0, 1, 1);			-- `Vector3.new(0, 1, 1)`
	V3_xzAxis				= Vector3.new(1, 0, 1);			-- `Vector3.new(1, 0, 1)`
	V3_xyAxis				= Vector3.new(1, 1, 0);			-- `Vector3.new(1, 1, 0)`
	V3_CoefficientB			= Vector3.new(0, 0.5, 0);		-- Vector3 ballistic coefficient `(0.5*g*t*t)`

	Gravity					= 196;

	RX90					= CFrame.Angles(math.rad(90), 0, 0);
	RY90					= CFrame.Angles(0, math.rad(90), 0);
	RZ90					= CFrame.Angles(0, 0, math.rad(90));

	RXn90					= CFrame.Angles(-math.rad(90), 0, 0);
	RYn90					= CFrame.Angles(0, -math.rad(90), 0);
	RZn90					= CFrame.Angles(0, 0, -math.rad(90));

	RX180					= CFrame.Angles(math.pi, 0, 0);
	RY180					= CFrame.Angles(0, math.pi, 0);
	RZ180					= CFrame.Angles(0, 0, math.pi);

	UDimOne					= UDim2.fromScale(1, 1);		-- `UDim2.fromScale(1, 1)`
	UDimZero				= UDim2.fromScale(0, 0);		-- `UDim2.fromScale(0, 0)`
	UDimX					= UDim2.fromScale(1, 0);		-- `UDim2.fromScale(1, 0)`
	UDimY					= UDim2.fromScale(0, 1);		-- `UDim2.fromScale(0, 1)`

	UDimHalf				= UDim2.fromScale(0.5, 0.5);	-- `UDim2.fromScale(0.5, 0.5)`
	UDimTop					= UDim2.fromScale(0.5, 0);		-- `🡱` -- `UDim2.fromScale(0.5, 0)`
	UDimBottom				= UDim2.fromScale(0.5, 1);		-- `🡳` -- `UDim2.fromScale(0.5, 1)`
	UDimLeft				= UDim2.fromScale(0, 0.5);		-- `🡰` -- `UDim2.fromScale(0, 0.5)`
	UDimRight				= UDim2.fromScale(1, 0.5);		-- `🡲` -- `UDim2.fromScale(1, 0.5)`
	UDimTopLeft				= UDim2.fromScale(0, 0);		-- `🡴` -- `UDim2.fromScale(0, 0)`
	UDimTopRight			= UDim2.fromScale(1, 0);		-- `🡵` -- `UDim2.fromScale(1, 0)`
	UDimBottomLeft			= UDim2.fromScale(0, 1);		-- `🡷` -- `UDim2.fromScale(0, 1)`
	UDimBottomRight			= UDim2.fromScale(1, 1);		-- `🡶` -- `UDim2.fromScale(1, 1)`

	UDimOffsetX				= UDim2.fromOffset(1, 0);		-- UDim2.fromOffset(1, 0)
	UDimOffsetY				= UDim2.fromOffset(0, 1);		-- UDim2.fromOffset(0, 1)

	Vector2Half				= Vector2.new(0.5, 0.5);		-- `Vector2.new(0.5, 0.5)`
	Vector2Top				= Vector2.new(0.5, 0);			-- `🡱` -- `Vector2.new(0.5, 0)`
	Vector2Bottom			= Vector2.new(0.5, 1);			-- `🡳` -- `Vector2.new(0.5, 1)`
	Vector2Left				= Vector2.new(0, 0.5);			-- `🡰` -- `Vector2.new(0, 0.5)`
	Vector2Right			= Vector2.new(1, 0.5);			-- `🡲` -- `Vector2.new(1, 0.5)`
	Vector2TopLeft			= Vector2.new(0, 0);			-- `🡴` -- `Vector2.new(0, 0)`
	Vector2TopRight			= Vector2.new(1, 0);			-- `🡵` -- `Vector2.new(1, 0)`
	Vector2BottomLeft		= Vector2.new(0, 1);			-- `🡷` -- `Vector2.new(0, 1)`
	Vector2BottomRight		= Vector2.new(1, 1);			-- `🡶` -- `Vector2.new(1, 1)`

	Color3White				= Color3.fromRGB(255, 255, 255);
	Color3Gray				= Color3.fromRGB(128, 128, 128);
	Color3Black				= Color3.fromRGB();

	Suffixes				= table.freeze{""; "K"; "M"; "B"; "T"; "Qd"};

	PlatformConversions		= table.freeze{
		[Enum.UserInputType.Keyboard]		= 1;
		[Enum.UserInputType.MouseButton1]	= 1;
		[Enum.UserInputType.MouseButton2]	= 1;
		[Enum.UserInputType.MouseButton3]	= 1;
		[Enum.UserInputType.MouseMovement]	= 1;
		[Enum.UserInputType.MouseWheel]		= 1;
		[Enum.UserInputType.TextInput]		= 1;

		[Enum.UserInputType.Touch]			= 2;

		[Enum.UserInputType.Gamepad1]		= 3;
		[Enum.UserInputType.Gamepad2]		= 3;
		[Enum.UserInputType.Gamepad3]		= 3;
		[Enum.UserInputType.Gamepad4]		= 3;
		[Enum.UserInputType.Gamepad5]		= 3;
		[Enum.UserInputType.Gamepad6]		= 3;
		[Enum.UserInputType.Gamepad7]		= 3;
		[Enum.UserInputType.Gamepad8]		= 3;
	};
}