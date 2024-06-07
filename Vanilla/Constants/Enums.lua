---### Enums.lua
---
---EmmyLua Enum container


---BodyMover types, new BodyMovers are unusable dont @ me thx
---@alias MoverClass
---| '"BodyVelocity"' # BodyVelocity
---| '"BodyGyro"' # BodyGyro
---| '"BodyPosition"' # BodyPosition
---| '"VectorForce"' # VectorForce


---cast hitbox shape
---@alias CastShape
---| '"Box"' # Cube
---| '"Ball"' # Sphere

---cast hitbox collision type
---@alias CastListType
---| '"WList"' # Whitelist
---| '"BList"' # Blacklist


---Input buffer offsets
---@alias InputBufferOffset
---| '1' # mouse position
---| '2' # camera direction
---| '3' # mouse surface normal
---| '4' # character floor normal

---Input platform id
---@alias InputPlatformId
---| '0' # unknown
---| '1' # keyboard & mouse
---| '2' # mobile
---| '3' # gamepad


---GuiObject content scale direction
---@alias ContentAxis
---| '"X"' # scale along X-axis
---| '"Y"' # scale along Y-axis

---Text ImageLabel alignment
---@alias Alignment
---| '"Left"' # GuiObject will be appended to the left side of the text
---| '"Right"' # GuiObject will be appended to the right side of the text

---Interface button sounds
---@alias ButtonSound
---| '"Click"' # click
---| '"Hover"' # hover
---| '"Ping"' # ping


---Network Player enums
---@alias PlayerArg
---| 'nil' # RemoteEvent:FireAllClients(...)
---| 'Player' # RemoteEvent:FireClient(...)
---| 'Player[]' # RemoteEvent:FireClients(...)
---| 'function (Player): boolean' # RemoteEvent:FireAllClientsThatMatchCase(...)


---Collision hitbox shapes
---@alias Shape
---| '"Box"' # GetPartBoundsInBox
---| '"Sphere"' # GetPartBoundsInRadius
---| 'Part' # GetPartsInPart


---Reverse iterator return values
---@alias ReverseIterAction
---| '0' # table.remove(A, i)
---| '1' # continue
---| '2' # break


---Time.Format() format strings
---@alias TimeFormatString
---| '"Hour"' # hour
---| '"Biphase"' # biphase (AM, PM)
---| '"Day"' # day
---| '"Week"' # week (1-52)
---| '"Season"' # season (S, S, F, W)
---| '"Biseason"' # biseason (SS, FW)
---| '"Year"' # year


---Vector3 axis components
---@alias Axis
---| '"X"' # X-component
---| '"Y"' # Y-component
---| '"Z"' # Z-component


---CFrame-Vector3 data types
---@alias CV 'Vector3' | 'Vector3int16' | 'PVInstance' | 'CFrame'


---PolicyService policy aliases
---@alias PolicyAlias
---| '"Ads"' # can be shown ads
---| '"Lootboxes"' # can buy lootboxes
---| '"Trading"' # can trade items
---| '"Subscriptions"' # can purchase in game subscriptions
---| '"China"' # is subject to china policies


return nil