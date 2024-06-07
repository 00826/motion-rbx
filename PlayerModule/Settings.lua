return {
	-- shiftlock settings
	ShiftlockOffset			= Vector3.new(0, 1.75, 0); -- Vector3.new(1.75, 0, 0)
	ShiftlockRotationType	= Enum.RotationType.MovementRelative;
	ShiftlockMobile			= true;
	ShiftlockCursor			= "rbxasset://textures/MouseLockedCursor.png"; -- rbxasset://textures/MouseLockedCursor.png

	-- jump input toggle
	JumpEnabled				= false;

	-- zoom distance steps when gamepad L3 is pressed
	GamepadZoomSteps		= { 0, 16, 32 };
	GamepadDeadzone			= 0.1; -- default 0.1;
	GamepadCurve			= 1; -- default 0.35; [0, 1]; [curve, linear]

	-- list of instance names that wont go transparent when camera is in 1st person mode
	FirstPersonBlacklist	= {};

	-- list of instances that the camera can go through
	CameraBlacklist			= {
	};
}