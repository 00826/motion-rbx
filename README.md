# motion-rbx

| <img src="./thumbnail.png" width="484"> |**shmoovin<br><br>motion-rbx is a buffer learning project, using buffers and various integer types in a high volume for the sake of becoming more familiar with the Luau buffer type<br><br>motion-rbx uses a sandbox of to-be-open-sourced roblox-luau library `Vanilla` to read player inputs and safely load characters<br><br>motion-rbx also uses a sandbox of the `PlayerModule` to disable the default jump inputs and to modify the shiftlock behavior**<br><br>motion demo: https://www.roblox.com/games/17597123706/|
|-|:-|

## a preamble

motion-rbx was written with these end goals:
1. familiarize myself with Luau buffers
2. make a highly-controllable movement fork that runs off a single thread
3. make a movement fork that is compatible with pc, gamepad, and mobile platforms
4. have custom movement states (aux states) efficiently replicate to other clients
5. have certain movement inputs (jumping, crouching, dashing) be buffered for UX and accessibility
6. make a future-proofed movement system against R6 & R15 rigs
7. de-mystify the default swim state and flight implementations

motion-rbx is not fully-typed in Luau because i spent more time locked in a sisyphian battle against the type solver than actually making progress on what i set out to do ^ -- however when the new Luau solver is released i do hope to revisit this project

## demo video

[![demo video](https://img.youtube.com/vi/XcdxNsNFTTo/maxresdefault.jpg)](https://youtu.be/XcdxNsNFTTo)

## motion-rbx client [./Local/MotionClient.client.lua](./Local/MotionClient.client.lua)

```lua
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")

local Motion = require(Shared.Motion)

local Vanilla = require(Shared.Vanilla)
local Inputs = Vanilla.Inputs

local PlayerScripts = Player:WaitForChild("PlayerScripts")
local ControlScript = require(PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

-- ... define MObject state settings
local Speed = MObject.Speed
buffer.writeu16(Speed, 0, 18) -- base speed 18
buffer.writeu16(Speed, 2, 32) -- sprint speed 32

MObject:Init(Character,
	function()
		return Inputs.Read(1)
	end,
	function()
		return ControlScript:GetMoveVector()
	end
)
```

## motion states [./Motion/State_Base/stateBuffer.md](./Motion/State_Base/stateBuffer.md)
|base movement state|input|
|-|-|
|idle|(none)|
|walk|directional input|
|sprint|double-tap forward input|
|sprint-stopped|while sprinting: release forward input|

|auxiliary movement state|input|
|-|-|
|jump|grounded: jump input|
|jumpaux (ex. double-jump)|in-air: jump input|
|crouch|Keycode `C`|
|slide|while sprinting: crouch input|
|dash|Keycode `Q`|
|swim|enter defined `SwimVolume`|
|fly|in-air: Keycode `F`|

## buffer reference table

|alias|type|byte size (offset)|range|description|
|-|-|-|-|-|
|i8|char|1|[ -127, 127 ]|signed 8-bit integer|
|u8|unsigned char|1|[ 0, 255 ]|unsigned 8-bit integer|
|i16|short|2|[ -32,768, 32,767 ]|signed 16-bit integer|
|u16|unsigned short|2|[ 0, 65,535 ]|unsigned 16-bit integer|
|i32|long|4|[ -2,147,483,648, 2,147,483,647 ]|signed 32-bit integer|
|u32|unsigned long|4|[ 0, 4,294,967,295 ]|unsigned 32-bit integer|
|f32|float|4|± 3.40 * 10<sup>38</sup>|32-bit float|
|f64|double|8|± 1.80 * 10<sup>308</sup>|64-bit float|