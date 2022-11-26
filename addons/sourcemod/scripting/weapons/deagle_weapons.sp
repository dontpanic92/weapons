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

	UpdateSkin(target, 0, 51, 0, 0.0);
	return Plugin_Handled;
}

public Action CommandDeagleSetWeapon(int client, int args)
{
	PrintToServer("[DEagle] CommandDeagleSetWeapon");

	if (client > 0)
	{
		ReplyToCommand(client, "[DEagle] warning: cannot be called from client.");
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
		UpdateMenu(target);
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

int InfoMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch (action)
	{
		case MenuAction_Select:
		{
		}
		case MenuAction_Cancel:
		{
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

void UpdateMenu(int client)
{
	Menu menu = new Menu(InfoMenuHandler);
	menu.SetTitle("正在检视：");
	menu.AddItem("a2", "模板编号：");
	menu.AddItem("a3", "皮肤磨损：");
	menu.ExitBackButton = true;

	menu.Display(client, MENU_TIME_FOREVER);
}

void UpdateSkin(int client, int weaponClassIndex, int skinId, int seedId, float weaponFloat)
{
	g_iSkins[client][weaponClassIndex]      = skinId;
	g_iWeaponSeed[client][weaponClassIndex] = seedId;

	if (weaponFloat < 0.0)
	{
		weaponFloat = 0.0;
	}
	else if (weaponFloat > 1.0)
	{
		weaponFloat = 1.0;
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

	if (IsKnifeClass(g_WeaponClasses[weaponClassIndex]))
	{
		SetClientKnife(client, g_WeaponClasses[weaponClassIndex]);
	}
	else
	{
		int slot   = g_WeaponSlot[weaponClassIndex];
		int entity = GetPlayerWeaponSlot(client, slot);
		if (entity != -1)
		{
			AcceptEntityInput(entity, "Kill");
		}

		GivePlayerItem(client, g_WeaponClasses[weaponClassIndex]);
	}
}
