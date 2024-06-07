### JumpState

|offset/total|type|alias|desc|
|-|-|-|-|
|0|u16|Velocity|base jump velocity|
|2|u16|Scalar|base jump scalar (`50` = `x0.5`), (`100` = `x1`), (`200` = `x2`)|
|4|u16|Cooldown|state activation cooldown (milliseconds)|
|6|f32|Recent|state activation time|
|10|u8|LiftType|`0` = none<br>`1` = vertical|
|11|u16|LiftVelocity|lift velocity|
|-|-|-|-|
|13|-|-|buffer describing motion jump state|