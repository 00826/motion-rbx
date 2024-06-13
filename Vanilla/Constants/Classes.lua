---### Classes.lua
---
---EmmyLua class container


---AnimationTrack properties table
---@class TrackProperties
---@field Name string? Name
---@field FadeTime number? FadeTime
---@field Weight number? Weight
---@field Speed number? Speed
---@field Priority Enum.AnimationPriority? AnimationPriority

---AnimController class
---@class AnimObject
---@field Rig Model
---@field RootPart BasePart
---@field Humanoid Humanoid
---@field Optimize boolean
---@field AnimationFolder Folder
---@field AnimationTable table<Enum.HumanoidRigType, table>
---@field BaseSpeed number
---@field CurrentAnim string
---@field CurrentAnimInstance Animation
---@field CurrentAnimTrack AnimationTrack
---@field CurrentAnimSpeed number
---@field ToolIdleTrack AnimationTrack
---@field TargetSound Sound
---@field LastFloorMaterial Enum.Material
---@field Connections RBXScriptConnection[]


---BarValue axes
---@alias BarAxes
---| 'X' # Vector3.X, or Bar.Value
---| 'Y' # Vector3.Y, or Bar.MaxValue
---| 'Z' # Vector3.Z, or Bar.Regen


---BodyGyro properties table
---@class BodyGyroProperties
---@field D number
---@field P number
---@field MaxTorque Vector3
---@field CFrame CFrame

---BodyVelocity properties table
---@class BodyVelocityProperties
---@field P number
---@field MaxForce Vector3
---@field Velocity Vector3

---BodyPosition properties table
---@class BodyPositionProperties
---@field D number
---@field P number
---@field MaxForce Vector3
---@field Position Vector3

---VectorForce properties table
---@class VectorForceProperties
---@field MaxForce Vector3


---Empty buffer class
---@class buffer


---Instance tree structure
---@class InstanceTree: table<string, any>
---@field ClassName string # Instance ClassName
---@field Parent Instance|nil # only needed for entry set of `Tree`
---@field Children InstanceTree[]|nil # InstanceTree recursion


---GuiButton mouse event table
---@class ConnectFunctions
---@field ClickDown fun(x: number, y: number) Button.MouseButton1Down
---@field ClickUp fun(x: number, y: number) Button.MouseButton1Up
---@field RClickDown fun(x: number, y: number) Button.MouseButton2Down
---@field RClickUp fun(x: number, y: number) Button.MouseButton2Up
---@field Enter fun(x: number, y: number) Button.MouseEnter/SelectionGained
---@field Leave fun(x: number, y: number) Button.MouseLeave/SelectionLost
---@field Move fun(x: number, y: number) Button.MouseMove

---ImageLabel Sprite properties table
---@class SpriteInfo
---@field Id string rbxassetid://
---@field Size Vector2 Vector2(width, height) of each square
---@field Padding number padding between sprite images
---@field Grid number dimensions of sprite

---SpriteSettings table
---@class SpriteSettings
---@field SpriteInfo SpriteInfo
---@field Position number (position of sprite, from left->right, top->bottom)


---Character components
---@class CharacterComponents
---@field Player Player LocalPlayer
---@field Character Model player character
---@field Humanoid Humanoid local humanoid
---@field RootPart Part local rootpart

---AccessoryPart
---@class AccessoryPart: BasePart
---@field Attachment Attachment
---@field Mesh SpecialMesh


---Grid arrange coordinates
---@class ArrangeResult
---@field X number
---@field Z number


---Status effect info
---@class StatusInfo
---@field Active boolean
---@field Until number?
---@field Stacks number?


---Time format result
---@class TimeFormatResult
---@field Timestamp string # unique string with respect to format
---@field Seed number # unique numeric seed with respect to format
---@field Until number # seconds until Timestamp and Seed will change


---ProfileService profile
---@class Profile


return nil