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
char g_steamId[MAXPLAYERS+1][128];

public void OnPluginStart()
{
	Database.Connect(SQLConnectCallback, "csgodb");
}

public void OnClientAuthorized(int client, const char[] auth)
{
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
