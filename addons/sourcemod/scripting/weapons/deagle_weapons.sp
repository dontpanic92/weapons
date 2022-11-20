#include <clients>

public Action CommandDeagleTest(int client, int args)
{
	ReplyToCommand(client, "[DEagle] Test3!");

    char auth[256];
    GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
	ReplyToCommand(client, "[DEagle] ClientId %s", auth);

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

	int entity = GetPlayerWeaponSlot(client, 0);
	if (entity != -1) {
		AcceptEntityInput(entity, "Kill");
    }

	GivePlayerItem(client, g_WeaponClasses[weaponClassIndex]);
}
