### VectorState

|offset/total|type|alias|desc|
|-|-|-|-|
|	[0, 4, 8]|f32|MoveVector|movement vector|
|[12, 16, 20]|f32|UpVector|up/down input vector|
|[24, 28, 32]|f32|CamVector|camera lookvector|
|[36, 40, 44]|f32|CamPosition|camera position|
|[48, 52, 56]|f32|MousePosition|mouse position|
|[60, 64, 68]|f32|FloorVector|floor normal|
|-|-|-|-|
|72|-|-|buffer describing vectors read upon by the motion system|