
public Action CommandDeagleTest(int client, int args)
{
	ReplyToCommand(client, "[DEagle] Test3!");

    UpdateSkin(client, 0, 51);
	return Plugin_Handled;
}

void UpdateSkin(int client, int weaponClassIndex, int skinId)
{
	g_iSkins[client][weaponClassIndex] = skinId;
	char updateFields[256];
	char weaponName[32];
	RemoveWeaponPrefix(g_WeaponClasses[weaponClassIndex], weaponName, sizeof(weaponName));
	Format(updateFields, sizeof(updateFields), "%s = %d", weaponName, skinId);
	UpdatePlayerData(client, updateFields);

	RefreshWeapon(client, weaponClassIndex);
    GivePlayerItem(client, g_WeaponClasses[weaponClassIndex]);
}


