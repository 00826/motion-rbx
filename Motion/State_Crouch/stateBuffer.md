### CrouchState

|offset/total|type|alias|desc|
|-|-|-|-|
|0|u8|Enabled|can state be transitioned into|
|1|u8|Active|state active|
|2|u16|Cooldown|state activation cooldown (milliseconds)|
|4|f32|Recent|state activation time|
|-|-|-|-|
|8|-|-|buffer describing motion crouch state|