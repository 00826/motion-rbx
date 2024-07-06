# motion-rbx

| <img src="./thumbnail.png" width="484"> |**shmoovin<br><br>motion-rbx is a buffer learning project, using buffers and various integer types in a high volume for the sake of becoming more familiar with the Luau buffer type<br><br>motion-rbx uses open-source roblox-luau library `Konbini` to read player inputs and safely load characters<br><br>motion-rbx also uses a sandbox of the `PlayerModule` to disable the default jump inputs and to modify the shiftlock behavior**<br><br>motion demo: https://www.roblox.com/games/17597123706/|
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

## demo video [https://youtu.be/XcdxNsNFTTo](https://youtu.be/XcdxNsNFTTo)

[<img src="https://img.youtube.com/vi/XcdxNsNFTTo/maxresdefault.jpg" width="75%">](https://youtu.be/XcdxNsNFTTo)

## motion-rbx client [./Local/MotionClient.client.lua](./Local/MotionClient.client.lua)

```lua
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")

local Motion = require(Shared.Motion)

local Konbini = require(Shared.Konbini)
local Inputs = Konbini.Inputs

local Player = game:GetService("Players").LocalPlayer
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