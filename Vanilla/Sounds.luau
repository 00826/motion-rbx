--!strict

---### Sounds.luau
---
---`Sound` player/loader
local Sounds = {}

---clones Sound `Sound` parented to Instance `Parent`, with optional operator function `f` to be used on sound Clone
---@param Sound Sound target sound
---@param Parent Instance? target parent
---@param f? fun(Sound: Sound)
---@return Sound Sound cloned Sound
function Sounds.PlayOnce(Sound: Sound, Parent: Instance?, f: ((SoundClone: Sound) -> ())?): Sound
	local NewSound = Sound:Clone() :: Sound
	NewSound.Parent = Parent or Sound.Parent
	if f then f(NewSound) end

	NewSound:Play()
	NewSound.Ended:Once(function()
		NewSound:Destroy()
	end)
	NewSound.Stopped:Once(function()
		NewSound:Destroy()
	end)

	return NewSound
end

---clones Sound `Sound` parented to Instance `Parent` \
---optional operator function `f` to be used on sound Clone \
---uses PlayOnRemove
---@param Sound Sound target sound
---@param Parent Instance? target parent
---@param f? fun(Sound: Sound)
function Sounds.PlayRemove(Sound: Sound, Parent: Instance?, f: ((SoundClone: Sound) -> ())?)
	local NewSound = Sound:Clone() :: Sound
	NewSound.Parent = Parent or Sound.Parent
	if f then f(NewSound) end

	NewSound.PlayOnRemove = true
	NewSound:Destroy()
end

return Sounds