### JumpAuxState

|offset/total|type|alias|desc|
|-|-|-|-|
|0|u8|Enabled|can state be transitioned into|
|1|u8|Active|state active|
|2|u16|Velocity|aux jump velocity|
|4|u16|Scalar|aux jump scalar (`50` = `x0.5`), (`100` = `x1`), (`200` = `x2`)|
|6|u16|Cooldown|state activation cooldown (milliseconds)|
|8|f32|Recent|state activation time|
|12|u8|Current|internal jump-aux counter|
|13|u8|Limit|internal jump-aux limit|
|-|-|-|-|
|14|-|-|buffer describing motion jump-aux state|