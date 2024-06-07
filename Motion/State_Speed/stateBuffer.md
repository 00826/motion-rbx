### SpeedState

|offset/total|type|alias|desc|
|-|-|-|-|
|0|u16|BaseSpeed|base speed|
|2|u16|SprintSpeed|sprint speed|
|4|u16|BaseScalar|speed scalar (`50` = `x0.5`), (`100` = `x1`), (`200` = `x2`)|
|6|u16|AirScalar|air speed scalar (`50` = `x0.5`), (`100` = `x1`), (`200` = `x2`)|
|8|u16|SlowScalar|slow scalar (`50` = `x0.5`), (`100` = `x1`), (`200` = `x2`)|
|10|u16|SprintCooldown|sprint activation cooldown (milliseconds)|
|12|f32|SprintEnd|sprint input end|
|16|u16|DecayTime|sprint-stop decay time (milliseconds)|
|18|f32|DecayStart|sprint-stop decay start|
|22|i16|DecayDot|`[-1000, 1000]` movevector dot product that activates sprint-stop decay if `MoveVector:Dot(Vector3.zAxis)` is *greater than or equal to* `DecayDot / 1000`<br>if `DecayDot == 0`, then decay will start when MoveVector is purely lateral<br>if `DecayDot > 1000`, then this step is skipped|
|24|u8|DecayGroundControl|move towards camera when in sprint decay state [0, 100]|
|25|u8|AirControl|move towards camera when airborne and controlmode is `2` [0, 100]|
|26|u8|AirControlMode|`0` = none (no control)<br>`1` = follow movevector<br>`2` = follow stopvector|
|27|u8|BaseFieldOfView|base field of view|
|28|u8|SprintFieldOfView|sprint field of view|
|29|u8|SlowFieldOfView|slow field of view|
|30|u8|FOV_C|lerp coefficient * dt|
|-|-|-|-|
|31|-|-|buffer describing motion speed state|