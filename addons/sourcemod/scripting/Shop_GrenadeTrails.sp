#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

int g_iSpriteIndex;
int g_iClientColor[MAXPLAYERS+1][4];
int g_iClientSpriteIndex[MAXPLAYERS+1] = { -1, ... };

Handle g_hKv = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "[Shop] Grenade Trails",
	description = "Add trails to grenades",
	author = "R1KO",
	version = "1.2",
	url = ""
};

public void OnPluginStart()
{
	if (Shop_IsStarted())
	{
		Shop_Started();
	}
}

public void OnMapStart()
{
	if (g_hKv)
	{
		CloseHandle(g_hKv);
	}

	char sBuffer[256];

	g_hKv = CreateKeyValues("Grenade_Trails");
	Shop_GetCfgFile(sBuffer, sizeof(sBuffer), "grenade_trails.txt");
	if (!(FileToKeyValues(g_hKv, sBuffer)))
	{
		SetFailState("Couldn't parse file %s", sBuffer);
	}

	KvGetString(g_hKv, "material", sBuffer, sizeof(sBuffer), "materials/sprites/laserbeam.vmt");

	g_iSpriteIndex = PrecacheModel(sBuffer, true);

	KvRewind(g_hKv);

	if (KvGotoFirstSubKey(g_hKv, true))
	{
		int index;
		do {
			KvGetString(g_hKv, "material", sBuffer, sizeof(sBuffer));
			if (sBuffer[0] && (index = PrecacheModel(sBuffer, true)) > 0)
			{
				KvSetNum(g_hKv, "sprite_indx", index);
			}
		} while (KvGotoNextKey(g_hKv, true));
	}
	KvRewind(g_hKv);
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void Shop_Started()
{
	if (!g_hKv)
	{
		OnMapStart();
	}

	KvRewind(g_hKv);

	char sName[64];
	char sDescription[64];

	KvGetString(g_hKv, "name", sName, sizeof(sName), "Grenade Trails");
	KvGetString(g_hKv, "description", sDescription, sizeof(sDescription));

	CategoryId category_id = Shop_RegisterCategory("grenade_trails", sName, sDescription);

	KvRewind(g_hKv);

	if (KvGotoFirstSubKey(g_hKv, true))
	{
		do {
			if (KvGetSectionName(g_hKv, sName, sizeof(sName)) && Shop_StartItem(category_id, sName))
			{
				KvGetString(g_hKv, "name", sDescription, sizeof(sDescription), sName);
				Shop_SetInfo(sDescription, "", KvGetNum(g_hKv, "price", 1000), KvGetNum(g_hKv, "sellprice", -1), Item_Togglable, KvGetNum(g_hKv, "duration", 604800));
				Shop_SetCustomInfo("level", KvGetNum(g_hKv, "level", 0));
				Shop_SetCallbacks(_, OnEquipItem);
				Shop_EndItem();
			}
		} while (KvGotoNextKey(g_hKv, true));
	}
	KvRewind(g_hKv);
}

public ShopAction OnEquipItem(int iClient, CategoryId category_id, char[] category, ItemId item_id, char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		g_iClientSpriteIndex[iClient] = -1;
		return Shop_UseOff;
	}

	Shop_ToggleClientCategoryOff(iClient, category_id);

	KvRewind(g_hKv);

	if (KvJumpToKey(g_hKv, item, false))
	{
		KvGetColor(g_hKv, "color", g_iClientColor[iClient][0], g_iClientColor[iClient][1], g_iClientColor[iClient][2], g_iClientColor[iClient][3]);

		int index = KvGetNum(g_hKv, "sprite_indx", 0);
		if (index)
		{
			g_iClientSpriteIndex[iClient] = index;
		}
		else
		{
			g_iClientSpriteIndex[iClient] = g_iSpriteIndex;
		}
		return Shop_UseOn;
	}
	PrintToChat(iClient, "Failed to use \"%s\"!.", item);
	return Shop_Raw;
}

public void OnClientPostAdminCheck(int iClient)
{
	g_iClientSpriteIndex[iClient] = -1;
}

public void OnClientDisconnect(int iClient)
{
	g_iClientSpriteIndex[iClient] = -1;
}

public void OnEntityCreated(int iEntity, const char[] classname)
{
	if (StrContains(classname, "_projectile", false) != -1)
	{
		CreateTimer(0.0, Timer_Trail, EntIndexToEntRef(iEntity), 0);
	}
}

public Action Timer_Trail(Handle hTimer, any ref)
{
	int iEntity = EntRefToEntIndex(ref);
	if (iEntity != -1)
	{
		int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", 0);

		if (0 < iClient && iClient <= MaxClients && g_iClientSpriteIndex[iClient] != -1)
		{
			TE_SetupBeamFollow(iEntity, g_iClientSpriteIndex[iClient], 0, 3.0, 5.0, 3.0, 6, g_iClientColor[iClient]);
			TE_SendToAll(0.0);
		}
	}
	return Plugin_Stop;
}
