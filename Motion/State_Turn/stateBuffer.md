### TurnState

|offset/total|type|alias|desc|
|-|-|-|-|
|0|u8|Enabled|can state be transitioned into|
|1|u8|Mode|`0` = none<br>`1` = face camera<br>`2` = face mouse|
|2|u8|FloorAutoTurn|automatically turn when on floor|
|3|u32|FloorTurnSpeed|floor turn rate|
|7|u8|AirAutoTurn|automatically turn when in air|
|8|u32|AirTurnSpeed|air turn rate|
|-|-|-|-|
|12|-|-|buffer describing turn state|