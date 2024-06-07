### SwimState

|offset/total|type|alias|desc|
|-|-|-|-|
|0|u8|Enabled|can state be transitioned into|
|1|u8|Active|state active|
|2|u16|Cooldown|state activation cooldown (milliseconds)|
|4|f32|Recent|state activation time|
|8|u16|Depth|depth in swim volume|
|10|u16|Scalar|swim speed scalar against base speed (`50` = `x0.5`), (`100` = `x1`), (`200` = `x2`)|
|12|u8|CamInSwimVolume|is camera in swim volume|
|-|-|-|-|
|13|-|-|buffer describing motion slide state|