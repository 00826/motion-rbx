--!strict

---### Vanilla.luau
---
---a roblox-luau library with functions, wrappers and extensions that complement vanilla roblox
---
---[view Vanilla on github](https://github.com/00826/vanilla)
local Vanilla = table.freeze{
	---modules

	Constants			= require(script.Constants);

	Data				= require(script.Data);

	Network				= require(script.Network);

	Animation			= require(script.Animation);
	BarValue			= require(script.BarValue);
	BodyMover			= require(script.BodyMover);
	Collisions			= require(script.Collisions);
	Cross				= require(script.Cross);
	Encoder				= require(script.Encoder);
	Inputs				= require(script.Inputs);
	Interface			= require(script.Interface);
	Misc				= require(script.Misc);
	Rig					= require(script.Rig);
	Sounds				= require(script.Sounds);
	Status				= require(script.Status);
	Stream				= require(script.Stream);

	---library extensions

	Buffer				= require(script.Buffer);
	CFrame				= require(script.CFrame);
	Instance			= require(script.Instance);
	Math				= require(script.Math);
	Table				= require(script.Table);
	Vector3				= require(script.Vector3);

	---standalone functions

	async				= require(script.async);
	Bind				= require(script.Bind);
	Cache				= require(script.Cache);
	Connect				= require(script.Connect);
	Debounce			= require(script.Debounce);
	Queue				= require(script.Queue);
	Time				= require(script.Time);
	ToBoolean			= require(script.ToBoolean);
	Tween				= require(script.Tween);
}

return Vanilla