--!nocheck

local Shared					= game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Konbini					= require(Shared.Konbini)

for _, Module: ModuleScript in ipairs{
	script:WaitForChild("AncestrySetter");
	script:WaitForChild("MotionServer");
} do
	Konbini.async(function() return require(Module) end):try(
		function()
			print(`Loaded Module: {Module.Name}`)
		end, function(traceback)
			warn(traceback)
		end
	)
end