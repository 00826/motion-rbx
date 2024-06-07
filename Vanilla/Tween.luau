--!strict

local TweenService			= game:GetService("TweenService")

---### Tween.luau
---
---TweenService wrapper
---```
---Vanilla.Tween(Thing, {Transparency = 1}, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
---```
---@param Object Instance target to be tweened
---@param Properties table<string, any> tween properties
---@param Time number tween time
---@vararg Enum.EasingStyle, Enum.EasingDirection
return function(Object: Instance, Properties: {[string]: any}, Time: number, ...)
	TweenService:Create(Object, TweenInfo.new(Time, ...), Properties):Play()
end