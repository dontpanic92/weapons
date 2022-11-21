#include <clients>
#include <deagle>

public Action CommandDeagleTest(int client, int args)
{
	ReplyToCommand(client, "[DEagle] Test3!");

	int target;
	if (client > 0)
	{
		char auth[256];
		GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
		ReplyToCommand(client, "[DEagle] ClientId %s", auth);
		target = client;
	}
	else
	{
		char steamid[128];
		GetCmdArg(1, steamid, sizeof(steamid));
		target = FindTargetBySteam64Id(steamid);
		if (target == -1)
		{
			LogError("Unable to find user %s", steamid);
			return Plugin_Handled;
		}
	}

	UpdateSkin(target, 0, 51);
	return Plugin_Handled;
}

public Action CommandDeagleSetWeapon(int client, int args)
{
	PrintToServer("[DEagle] CommandDeagleSetWeapon");

	if (client > 0)
	{
		ReplyToCommand("[DEagle] warning: cannot be called from client.");
		return Plugin_Handled;
	}
	else
	{
		char steamid[128];
		GetCmdArg(1, steamid, sizeof(steamid));

		int target = FindTargetBySteam64Id(steamid);
		if (target == -1)
		{
			LogError("Unable to find user %s", steamid);
			return Plugin_Handled;
		}

		char weaponName[64];
		GetCmdArg(2, weaponName, sizeof(weaponName));
		int weaponIndex = FindWeaponIndex(weaponName);
		if (weaponIndex == -1)
		{
			LogError("Unable to find weapon %s", weaponName);
			return Plugin_Handled;
		}

		char skinIdStr[64];
		GetCmdArg(3, skinIdStr, sizeof(skinIdStr));
		int skinId = StringToInt(skinIdStr);

        char seedIdStr[64];
		GetCmdArg(4, seedIdStr, sizeof(seedIdStr));
		int seedId = StringToInt(seedIdStr);
        
        char weaponFloatStr[64];
		GetCmdArg(5, weaponFloatStr, sizeof(weaponFloatStr));
		float weaponFloat = StringToFloat(weaponFloatStr);

		UpdateSkin(target, weaponIndex, skinId, seedId, weaponFloat);
		return Plugin_Handled;
	}
}

int FindWeaponIndex(char[] weaponName)
{
	for (int i = 0; i < sizeof(g_WeaponClasses); i++)
	{
		if (strcmp(weaponName, g_WeaponClasses[i]) == 0)
		{
			return i;
		}
	}

	return -1;
}

void UpdateSkin(int client, int weaponClassIndex, int skinId, int seedId, float weaponFloat)
{
	g_iSkins[client][weaponClassIndex]      = skinId;
	g_iWeaponSeed[client][weaponClassIndex] = seedId;

	if (weaponFloat < 0)
	{
		weaponFloat = 0;
	}
	else if (weaponFloat > 1)
	{
		weaponFloat = 1;
	}

	g_fFloatValue[client][weaponClassIndex] = weaponFloat;

	char updateFields[256];
	char weaponName[32];
	RemoveWeaponPrefix(g_WeaponClasses[weaponClassIndex], weaponName, sizeof(weaponName));
	Format(updateFields, sizeof(updateFields), "%s = %d", weaponName, skinId);
	Format(updateFields, sizeof(updateFields), "%s_seed = %d", weaponName, seedId);
	Format(updateFields, sizeof(updateFields), "%s_float = %.2f", weaponName, weaponFloat);
	UpdatePlayerData(client, updateFields);

	RefreshWeapon(client, weaponClassIndex);

	int entity = GetPlayerWeaponSlot(client, 0);
	if (entity != -1)
	{
		AcceptEntityInput(entity, "Kill");
	}

	GivePlayerItem(client, g_WeaponClasses[weaponClassIndex]);
}