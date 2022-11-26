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

    HookEvent("player_activate", Player_Activated, EventHookMode_Post);
}

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
}


/*Action CS_OnCSWeaponDrop(int client, int weaponIndex, bool donated)
{
    return Plugin_Stop;
}*/

Action CS_OnGetWeaponPrice(int client, const char[] weapon, int& price)
{
    price = 0;
    return Plugin_Handled;
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
