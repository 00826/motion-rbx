--!strict

---### Vanilla.luau
---
---a roblox-luau library with functions, wrappers and extensions that complement vanilla roblox
---
---[view Vanilla on github](https://github.com/00826/vanilla)
local Vanilla = table.freeze{
	---modules

	Constants			= require(script.Constants);

	Inputs				= require(script.Inputs);
	Rig					= require(script.Rig);

	---library extensions

	Instance			= require(script.Instance);

	---standalone functions

	async				= require(script.async);
	Tween				= require(script.Tween);
}

return Vanilla