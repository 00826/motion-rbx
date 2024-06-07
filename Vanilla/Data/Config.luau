return {
	DataStoreName			= "PlayerData";
	SaveKey					= "_1a";

	--- keys that are read from Player.Data when synced
	SyncKeys				= table.freeze{
		"Inventory";
		"Equipped";
		"Progress";
		"CrewProfile";
		"QuestProfile";
		"Passives";
		"Race";
		"Fruit";
		"Spawn";
		"Style";
	};
}