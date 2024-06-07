### RotateState

|offset/total|type|alias|desc|
|-|-|-|-|
|0|u8|RotateModeAir|`0` = `Humanoid.AutoRotate = false`<br>`1` = `Humanoid.AutoRotate = true`<br>`2` = camera<br>`3` = mouse<br>`4` = RotateVector|
|1|u32|RotateModeAirPower|power of angular rotation|
|5|u8|RotateModeGround|`0` = `Humanoid.AutoRotate = false`<br>`1` = `Humanoid.AutoRotate = true`<br>`2` = camera<br>`3` = mouse<br>`4` = RotateVector|
|6|u32|RotateModeGroundPower|power of angular rotation|
|10|u8|RotateModeForce|`0` = `Humanoid.AutoRotate = false`<br>`1` = `Humanoid.AutoRotate = true`<br>`2` = camera<br>`3` = mouse<br>`4` = RotateVector|
|11|u32|RotateModeForcePower|power of angular rotation|
|15|u8|ForceRotatePriority|priority of forced rotate mode|
|16|f32|ForceRotateUntil|duration of forced rotate mode|
|[20, 24, 28]|f32|RotateVector|rotate mode 4 vector<br>if `RotateVector == Vector3.zero`, then RotateVector will fallback to `RootPart.CFrame.LookVector`|
|-|-|-|-|
|32|-|-|buffer describing rotate state|