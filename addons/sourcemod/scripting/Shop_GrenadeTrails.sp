#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

int g_iSpriteIndex;
int g_iClientColor[MAXPLAYERS+1][4];
int g_iClientSpriteIndex[MAXPLAYERS+1] = { -1, ... };

KeyValues g_hKv = null;

public Plugin myinfo =
{
	name = "[Shop] Grenade Trails",
	description = "Add trails to grenades",
	author = "R1KO",
	version = "1.3",
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
		delete g_hKv;
	}

	char sBuffer[256];

	g_hKv = new KeyValues("Grenade_Trails");
	Shop_GetCfgFile(sBuffer, sizeof(sBuffer), "grenade_trails.txt");
	if (!(g_hKv.ImportFromFile(sBuffer)))
	{
		SetFailState("Couldn't parse file %s", sBuffer);
	}

	g_hKv.GetString("material", sBuffer, sizeof(sBuffer), "materials/sprites/laserbeam.vmt");

	g_iSpriteIndex = PrecacheModel(sBuffer, true);

	g_hKv.Rewind();

	if (g_hKv.GotoFirstSubKey(true))
	{
		int index;
		do {
			g_hKv.GetString("material", sBuffer, sizeof(sBuffer));
			if (sBuffer[0] && (index = PrecacheModel(sBuffer, true)) > 0)
			{
				g_hKv.SetNum("sprite_indx", index);
			}
		} while (g_hKv.GotoNextKey(true));
	}
	g_hKv.Rewind();
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

	g_hKv.Rewind();

	char sName[64];
	char sDescription[64];

	g_hKv.GetString("name", sName, sizeof(sName), "Grenade Trails");
	g_hKv.GetString("description", sDescription, sizeof(sDescription));

	CategoryId category_id = Shop_RegisterCategory("grenade_trails", sName, sDescription);

	g_hKv.Rewind();

	if (g_hKv.GotoFirstSubKey(true))
	{
		do {
			if (g_hKv.GetSectionName(sName, sizeof(sName)) && Shop_StartItem(category_id, sName))
			{
				g_hKv.GetString("name", sDescription, sizeof(sDescription), sName);
				Shop_SetInfo(sDescription, "", g_hKv.GetNum("price", 1000), g_hKv.GetNum("sellprice", -1), Item_Togglable, g_hKv.GetNum("duration", 604800));
				Shop_SetCustomInfo("level", g_hKv.GetNum("level", 0));
				Shop_SetCallbacks(_, OnEquipItem);
				Shop_EndItem();
			}
		} while (g_hKv.GotoNextKey(true));
	}
	g_hKv.Rewind();
}

public ShopAction OnEquipItem(int iClient, CategoryId category_id, char[] category, ItemId item_id, char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		g_iClientSpriteIndex[iClient] = -1;
		return Shop_UseOff;
	}

	Shop_ToggleClientCategoryOff(iClient, category_id);

	g_hKv.Rewind();

	if (g_hKv.JumpToKey(item, false))
	{
		g_hKv.GetColor("color", g_iClientColor[iClient][0], g_iClientColor[iClient][1], g_iClientColor[iClient][2], g_iClientColor[iClient][3]);

		int index = g_hKv.GetNum("sprite_indx", 0);
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
