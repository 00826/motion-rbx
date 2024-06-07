### DashState

|offset/total|type|alias|desc|
|-|-|-|-|
|0|u8|Enabled|can state be transitioned into|
|1|u8|Input|is input active|
|2|u16|Cooldown|state activation cooldown (milliseconds)|
|4|f32|Recent|state activation time|
|8|u16|Time|dash bodymover lifetime (milliseconds)|
|10|u16|Velocity|dash bodymover velocity|
|12|u16|P|dash bodymover P|
|-|-|-|-|
|14|-|-|buffer describing motion dash state|