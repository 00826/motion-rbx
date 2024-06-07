### BaseState

|offset/total|type|alias|desc|
|-|-|-|-|
|0|u8|State|base movement state|
||||`0` = idle|
||||`1` = walk|
||||`2` = sprint|
||||`3` = sprint stopped|
|1|u8|AuxState|auxiliary movement state|
||||`0` = none|
||||`1` = jumpaux|
||||`2` = crouch|
||||`3` = slide|
||||`4` = dash|
||||`5` = swim|
||||`6` = fly|
|2|u8|SlowState|movement slow state|
||||`0` = none/normal|
||||`1` = slowed|
||||`2` = stopped|
|3|u8|SprintInput|sprint input<br>`1` = active<br>`0` = inactive|
|4|u8|DownInput|crouch input<br>`1` = active<br>`0` = inactive|
|5|u8|UpInput|jump input<br>`1` = active<br>`0` = inactive|
|-|-|-|-|
|6|-|-|buffer describing motion base state|