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

		char query[255];
		FormatEx(query, sizeof(query), "INSERT INTO active_users (steamid, serverip) VALUES ('%s', 'unknown')", steamid);
		db.Query(T_InsertCallback, query);
	}
	else
	{
		LogError("Cannot get user auth id");
	}

	PrintToChatAll(" \x04[DEagle] \x0B欢迎来到 DEagle 社区服，访问 \x06https://dealge.club \x04一键检视 Buff/UU 在售饰品");
	return Plugin_Handled;
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

	g_SecondsToChangeMap = 120;
	int nextMap          = GetURandomInt() % 7;

	strcopy(g_NextMap, sizeof(g_NextMap), g_MapPool[nextMap]);
	g_ChangeMapTimer = CreateTimer(float(g_ChangeMapTimerInterval), MapChangeTimer, 0, TIMER_REPEAT);
}

Action MapChangeTimer(Handle timer)
{
	if (g_SecondsToChangeMap < 0)
	{
		PrintToChatAll(" \x04[DEagle] \x0B正在更换地图： \x04%s", g_NextMap);
		ServerCommand("sm_map %s", g_NextMap);
		return Plugin_Stop;
	}

	if (g_SecondsToChangeMap >= 60 && g_SecondsToChangeMap % 60 == 0) {
		PrintToChatAll(" \x04[DEagle] \x0B%d分钟后将更换地图。下一张地图为： \x04%s", g_SecondsToChangeMap / 60, g_NextMap);
	} else if (g_SecondsToChangeMap < 60) {
		PrintToChatAll(" \x04[DEagle] \x0B即将更换地图。下一张地图为： \x04%s", g_NextMap);
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
