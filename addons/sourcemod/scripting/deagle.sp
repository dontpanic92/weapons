#include <clients>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name        = "Deagle",
	author      = "dontpanic",
	description = "All in one CS:GO weapon skin management",
	version     = "0.0.1",
	url         = "https://deagle.club"
};

Database db = null;
char     g_steamId[MAXPLAYERS + 1][128];
char     g_userToken[MAXPLAYERS + 1][32];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("deagle");

	CreateNative("FindTargetBySteam64Id", FindTargetBySteam64Id_Native);

	return APLRes_Success;
}

public void OnPluginStart()
{
	Database.Connect(SQLConnectCallback, "csgodb");

	HookEvent("player_spawned", Player_Activated, EventHookMode_Post);

	RegConsoleCmd("sm_wx", CommandShowWxQrCode);

	AddCommandListener(ChatListener, "say");
	AddCommandListener(ChatListener, "say2");
	AddCommandListener(ChatListener, "say_team");
}

Handle g_Cvar_bot_quota = INVALID_HANDLE;
int    g_bot_quota;
int    g_max_players;

public void OnConfigsExecuted()
{
	g_Cvar_bot_quota = FindConVar("bot_quota");
	g_bot_quota      = GetConVarInt(g_Cvar_bot_quota);
	g_max_players    = GetMaxClients();
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	if (!IsFakeClient(client))
		return;

	if (g_bot_quota < GetConVarInt(g_Cvar_bot_quota))
		SetConVarInt(g_Cvar_bot_quota, g_bot_quota);

	int i, count;
	for (i = 1; i <= g_max_players; i++)
		if (IsClientInGame(i) && GetClientTeam(i) > 1)
			count++;

	if (count <= g_bot_quota)
		return;

	char name[32];
	if (!GetClientName(client, name, 31))
		return;
	ServerCommand("bot_kick %s", name);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
	return Plugin_Handled;
}

/*
default (white): \x01
teamcolour (will be purple if message from server): \x03
red: \x07
lightred: \x0F
darkred: \x02
bluegrey: \x0A
blue: \x0B
darkblue: \x0C
purple: \x03
orchid: \x0E
yellow: \x09
gold: \x10
lightgreen: \x05
green: \x04
lime: \x06
grey: \x08
grey2: \x0D
 */
public Action Player_Activated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	char steamid[128];
	if (GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid)))
	{
		strcopy(g_steamId[client], 128, steamid);

		int  token1 = GetURandomInt();
		int  token2 = GetURandomInt();
		char token[32];
		FormatEx(token, sizeof(token), "%x%x", token1, token2);

		strcopy(g_userToken[client], 32, token);

		char query[255];
		FormatEx(query, sizeof(query), "INSERT INTO active_users (steamid, serverip, token) VALUES ('%s', 'unknown', '%s')", steamid, token);
		db.Query(T_InsertCallback, query);
	}
	else
	{
		LogError("Cannot get user auth id");
	}

	PrintToChatAll(" \x10[DEagle] \x0B欢迎来到 DEagle 社区服，\x04输入 \x10.wx \x04扫描二维码打开微信小程序， \x04快速检视 Buff/UU 在售饰品！");
	return Plugin_Handled;
}

public Action CommandShowWxQrCode(int client, int args)
{
	ShowQrCode(client, false);
	// CreateTimer(0.5, DismissQrCodeTimer, client);
	ShowQrCode(client, false);
	// CreateTimer(1.5, ShowWxQrCodeTimer, client);

	return Plugin_Handled;
}

public void ShowQrCode(int client, bool clear)
{
	char html[256];
	if (clear)
	{
		FormatEx(html, sizeof(html), "");
	}
	else {
		FormatEx(html, sizeof(html), "<img src='https://deagle.club/api/wx/qrcode?token=%s' width='500' height='500'>", g_userToken[client]);
	}

	PrintToServer("client: %d clear: %d", client, clear);

	Event newevent_message = CreateEvent("cs_win_panel_round");
	newevent_message.SetString("funfact_token", html);
	newevent_message.FireToClient(client);
	newevent_message.Cancel();
}

Action ShowWxQrCodeTimer(Handle timer, int client)
{
	ShowQrCode(client, false);
	ShowQrCode(client, false);

	Menu menu = new Menu(ShowWxQrCodeHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("DEagle 社区服");
	menu.AddItem("a1", "微信扫码打开小程序，即可快速换肤！支持解析 BUFF/UU 移动端分享链接", ITEMDRAW_DISABLED);

	menu.Display(client, MENU_TIME_FOREVER);
}

Action DismissQrCodeTimer(Handle timer, int client)
{
	ShowQrCode(client, true);
}

int ShowWxQrCodeHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch (action)
	{
		case MenuAction_Select:
		{
		}
		case MenuAction_Cancel:
		{
			ShowQrCode(client, true);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public Action ChatListener(int client, const char[] command, int args)
{
	char msg[128];
	GetCmdArgString(msg, sizeof(msg));
	StripQuotes(msg);

	if (StrEqual(msg, ".wx"))
	{
		CommandShowWxQrCode(client, 0);
	}

	return Plugin_Continue;
}

/*Action CS_OnCSWeaponDrop(int client, int weaponIndex, bool donated)
{
    return Plugin_Stop;
}*/
public Action CS_OnGetWeaponPrice(int client, const char[] weapon, int& price)
{
	price = 0;
	return Plugin_Handled;
}

char g_MapPool[][] = {
	"de_dust2",
	"cs_italy",
	"de_nuke",
	"de_mirage",
	"cs_office",
	"de_train",
	"de_inferno",
};

Handle g_ChangeMapTimer;
int    g_SecondsToChangeMap;
char   g_NextMap[32];
int    g_ChangeMapTimerInterval = 15;

public void OnMapStart()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "func_bomb_target")) != -1)
	{
		AcceptEntityInput(entity, "Disable");    // or "Kill"
	}

	g_SecondsToChangeMap = 55 * 60;
	int nextMap          = GetURandomInt() % 7;

	strcopy(g_NextMap, sizeof(g_NextMap), g_MapPool[nextMap]);
	g_ChangeMapTimer = CreateTimer(float(g_ChangeMapTimerInterval), MapChangeTimer, 0, TIMER_REPEAT);
}

Action MapChangeTimer(Handle timer)
{
	if (g_SecondsToChangeMap <= 0)
	{
		PrintToChatAll(" \x10[DEagle] \x0B正在更换地图： \x04%s", g_NextMap);
		ServerCommand("sm_map %s", g_NextMap);
		return Plugin_Stop;
	}

	if (g_SecondsToChangeMap >= 60 && g_SecondsToChangeMap <= 10 * 60 && g_SecondsToChangeMap % 60 == 0)
	{
		PrintToChatAll(" \x10[DEagle] \x0B%d分钟后将更换地图。下一张地图为： \x04%s", g_SecondsToChangeMap / 60, g_NextMap);
	}
	else if (g_SecondsToChangeMap <= 30) {
		PrintToChatAll(" \x10[DEagle] \x0B即将更换地图。下一张地图为： \x04%s", g_NextMap);
	}

	if (g_SecondsToChangeMap % 60 == 0)
	{
		PrintToChatAll(" \x10[DEagle] \x0B欢迎来到 DEagle 社区服，\x04输入 \x10.wx \x04扫描二维码打开微信小程序， \x04快速检视 Buff/UU 在售饰品！");
	}

	g_SecondsToChangeMap = g_SecondsToChangeMap - g_ChangeMapTimerInterval;
	return Plugin_Continue;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	/*char steamid[128];
	if (GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid)))
	{
	    strcopy(g_steamId[client], 128, steamid);

	    char query[255];
	    FormatEx(query, sizeof(query), "INSERT INTO active_users (steamid, serverip) VALUES ('%s', 'unknown')", steamid);
	    db.Query(T_InsertCallback, query);
	}
	else
	{
	    LogError("Cannot get user auth id");
	}*/
}

public void T_InsertCallback(Database database, DBResultSet results, const char[] error, any pack)
{
	if (results == null)
	{
		LogError("Insert Query failed!");
	}
}

public void OnClientDisconnect(int client)
{
	char query[255];
	FormatEx(query, sizeof(query), "DELETE FROM active_users WHERE steamid = '%s'", g_steamId[client]);
	db.Query(T_DeleteCallback, query);
}

public void T_DeleteCallback(Database database, DBResultSet results, const char[] error, any pack)
{
	if (results == null)
	{
		LogError("Delete active user failed!");
	}
}

public void SQLConnectCallback(Database database, const char[] error, any data)
{
	if (database == null)
	{
		LogError("Database failure: %s", error);
	}
	else
	{
		db = database;
	}
}

public int FindTargetBySteam64Id_Native(Handle plugin, int numparams)
{
	char steamid[128];
	GetNativeString(1, steamid, 128);
	for (int i = 1; i < MAXPLAYERS + 1; i++)
	{
		if (strcmp(steamid, g_steamId[i]) == 0)
		{
			return i;
		}
	}

	return -1;
}
