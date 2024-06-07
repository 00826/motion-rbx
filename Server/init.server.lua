local Shared					= game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Vanilla					= require(Shared.Vanilla)

for _, Module in ipairs{
	script:WaitForChild("AncestrySetter");
	script:WaitForChild("MotionServer");
} do
	Vanilla.async(function() return require(Module) end):try(
		function()
			print(`Loaded Module: {Module.Name}`)
		end, function(traceback)
			warn(traceback)
		end
	)
end