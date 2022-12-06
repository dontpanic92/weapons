#include <clients>
#include <deagle>

public Action CommandDeagleGloveTest(int client, int args)
{
	ReplyToCommand(client, "[DEagle] Test4!");
	UpdateGlove(client, 5030, 10073, 0, 0.0);
	return Plugin_Handled;
}

public Action CommandDeagleSetGlove(int client, int args)
{
	PrintToServer("[DEagle] CommandDeagleSetGlove");

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

		if (args >= 6)
		{
			char weaponDisplayName[128];
			GetCmdArg(6, weaponDisplayName, sizeof(weaponDisplayName));
			UpdateMenu(target, weaponDisplayName, seedId, weaponFloat);
		}
		return Plugin_Handled;
	}
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

void UpdateMenu(int client, char[] weaponName, int seedId, float weaponFloat)
{
	Menu menu = new Menu(InfoMenuHandler);
	menu.SetTitle("DEagle 社区服");

	char buffer[128];
	Format(buffer, sizeof(buffer), "正在检视：%s", weaponName);
	menu.AddItem("a1", buffer, ITEMDRAW_DISABLED);

	Format(buffer, sizeof(buffer), "模板编号：%d", seedId);
	menu.AddItem("a2", buffer, ITEMDRAW_DISABLED);

	Format(buffer, sizeof(buffer), "皮肤磨损：%f", weaponFloat);
	menu.AddItem("a3", buffer, ITEMDRAW_DISABLED);

	menu.Display(client, MENU_TIME_FOREVER);
}

void UpdateGlove(int client, int groupId, int gloveId, int seedId, float weaponFloat)
{
	int team = GetClientTeam(client);

	g_iGroup[client][team]  = groupId;
	g_iGloves[client][team] = gloveId;
	char updateFields[128];
	char teamName[4];
	if (team == CS_TEAM_T)
	{
		teamName = "t";
	}
	else if (team == CS_TEAM_CT)
	{
		teamName = "ct";
	}
	Format(updateFields, sizeof(updateFields), "%s_group = %d, %s_glove = %d", teamName, groupId, teamName, gloveId);
	UpdatePlayerData(client, updateFields);

	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (activeWeapon != -1)
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
	}
	GivePlayerGloves(client);

	if (activeWeapon != -1)
	{
		DataPack dpack;
		CreateDataTimer(0.1, ResetGlovesTimer, dpack);
		dpack.WriteCell(client);
		dpack.WriteCell(activeWeapon);
	}
}
