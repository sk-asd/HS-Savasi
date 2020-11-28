#include <sourcemod>
#include <warden>
#include <sdktools>
#include <cstrike>
#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0
int silah = -1, sure = 0;
ConVar Test = null;
Handle g_timer;
bool oyun;
public Plugin myinfo =  { name = "HS SAVAŞI", author = "phiso", description = "Jailbreak modunda hs savaşı yapmanıza yarar.", version = "1.3", url = "phiso#3331" };
public void OnMapStart()
{
	char mapismi[512];
	GetCurrentMap(mapismi, sizeof(mapismi));
	if (StrContains(mapismi, "jb_", false) != 0 && StrContains(mapismi, "jail_", false) != 0 && StrContains(mapismi, "ba_jail", false) != 0)
	{
		SetFailState("[HS SAVAŞI] Bu eklenti sadece jailbreak modunda calismaktadir.");
	}
}	
public void OnPluginStart()
{
	RegConsoleCmd("sm_hsmenu", HSMenu);
	RegConsoleCmd("sm_hsbitir", HSDur);
	HookEvent("round_end", ra);
	HookEvent("round_start", ra);
	HookEvent("player_death", oldumq);
	Test = CreateConVar("sm_hsmenu_flag", "f", "Komutçu harici kullanabilecek kişilerin yetki harfi");
	AutoExecConfig(true, "HS-Savas", "phiso");
}
public Action HSMenu(int client, int args)
{
	char Flag[16];
	Test.GetString(Flag, sizeof(Flag));
	if (warden_iswarden(client) || CheckAdminFlag(client, Flag))
	{
		Menu menu = new Menu(Men_u);
		menu.SetTitle("[SM] HS Menü - Hangi Silahla Kapışılsın?");
		menu.AddItem("ak47", "★ AK-47");
		menu.AddItem("m4a1", "★ M4A1-S\n---------------");
		menu.AddItem("deagle", "★ DEAGLE");
		menu.AddItem("usps", "★ USP-S\n");
		menu.AddItem("kapatmq", "★ Kapat");
		menu.ExitBackButton = false;
		menu.ExitButton = false;
		menu.Display(client, 20);
	}
	else
	{
		ReplyToCommand(client, "[SM] \x04Bu komuta \x02erişiminiz \x04yok!");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public int Men_u(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char item[10];
		menu.GetItem(param2, item, sizeof(item));
		if (strcmp(item, "ak47") == 0)
		{
			saniye(param1);
			silah = 1;
		}
		else if (strcmp(item, "m4a1") == 0)
		{
			saniye(param1);
			silah = 2;
		}
		else if (strcmp(item, "deagle") == 0)
		{
			saniye(param1);
			silah = 3;
		}
		else if (strcmp(item, "usps") == 0)
		{
			saniye(param1);
			silah = 4;
		}
		else if (strcmp(item, "kapatmq") == 0)
		{
			PrintToChat(param1, "[SM] \x04Menüyü senin için kapattım.");
			delete menu;
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
public void saniye(int client)
{
	Menu menu = new Menu(Me_nu);
	menu.SetTitle("[SM] HS Menü - Kaç saniye sonra başlasın?");
	menu.AddItem("60", "60 Saniye Sonra");
	menu.AddItem("50", "50 Saniye Sonra");
	menu.AddItem("40", "40 Saniye Sonra");
	menu.AddItem("30", "30 Saniye Sonra");
	menu.AddItem("20", "20 Saniye Sonra");
	menu.AddItem("10", "10 Saniye Sonra");
	menu.ExitBackButton = true;
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}
public int Me_nu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char item[20];
		menu.GetItem(param2, item, sizeof(item));
		if (strcmp(item, "60") == 0)
		{
			sure = 60;
		}
		else if (strcmp(item, "50") == 0)
		{
			sure = 50;
		}
		else if (strcmp(item, "40") == 0)
		{
			sure = 40;
		}
		else if (strcmp(item, "30") == 0)
		{
			sure = 30;
		}
		else if (strcmp(item, "20") == 0)
		{
			sure = 20;
		}
		else if (strcmp(item, "10") == 0)
		{
			sure = 10;
		}
		if (g_timer != null)
		{
			delete g_timer;
			g_timer = null;
		}
		g_timer = CreateTimer(1.0, saytimer, _, TIMER_REPEAT);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				Silah_Sil(i);
				if (silah == 1)
					GivePlayerItem(i, "weapon_ak47");
				else if (silah == 2)
					GivePlayerItem(i, "weapon_m4a1_silencer");
				else if (silah == 3)
					GivePlayerItem(i, "weapon_deagle");
				else if (silah == 4)
					GivePlayerItem(i, "weapon_usp_silencer");
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			HSMenu(param1, 1);
		}
	}
}
public Action saytimer(Handle Timer, any data)
{
	if (sure > 0)
	{
		YerdekiSilahlariSil();
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				PrintHintText(i, "<font color='#00FF00'>%d Saniye</font> sonra hs savaşı başlayacak", sure);
			}
		}
		sure--;
		return Plugin_Continue;
	}
	if (sure <= 0)
	{
		SetCvar("mp_teammates_are_enemies", 1);
		SetCvar("mp_friendlyfire", 1);
		SetCvar("mp_respawn_on_death_t", 0);
		SetCvar("mp_damage_headshot_only", 1);
		PrintToChatAll("[SM] \x01HS Savaşı \x04başladı!");
		oyun = true;
		if (g_timer != null)g_timer = null;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				Silah_Sil(i);
				if (silah == 1)
					GivePlayerItem(i, "weapon_ak47");
				else if (silah == 2)
					GivePlayerItem(i, "weapon_m4a1_silencer");
				else if (silah == 3)
					GivePlayerItem(i, "weapon_deagle");
				else if (silah == 4)
					GivePlayerItem(i, "weapon_usp_silencer");
			}
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
public Action oldumq(Event event, const char[] name, bool dontBroadcast)
{
	if (oyun)
	{
		int yasayanoc = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
				yasayanoc++;
		}
		if (yasayanoc == 1)
		{
			SetCvar("mp_teammates_are_enemies", 0);
			SetCvar("mp_friendlyfire", 0);
			SetCvar("mp_damage_headshot_only", 0);
			PrintToChatAll("[SM] \x01HS savaşı sona erdi!");
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
					SetEntityHealth(i, 100);
			}
		}
	}
}
public Action HSDur(int client, int args)
{
	if (oyun)
	{
		oyun = false;
		g_timer = null;
		delete g_timer;
		SetCvar("mp_teammates_are_enemies", 0);
		SetCvar("mp_friendlyfire", 0);
		PrintToChatAll("[SM] \x01HS savaşı iptal edildi!");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
				SetEntityHealth(i, 100);
		}
	}
}
public Action ra(Event event, const char[] name, bool dontBroadcast)
{
	if (oyun)
	{
		oyun = false;
		delete g_timer;
		SetCvar("mp_teammates_are_enemies", 0);
		SetCvar("mp_friendlyfire", 0);
		PrintToChatAll("[SM] \x01HS savaşı iptal edildi!");
	}
}
stock void SetCvar(char[] cvarName, int value) { ConVar IntCvar = FindConVar(cvarName); if (IntCvar == null)return; int flags = IntCvar.Flags; flags &= ~FCVAR_NOTIFY; IntCvar.Flags = flags; IntCvar.IntValue = value; flags |= FCVAR_NOTIFY; IntCvar.Flags = flags; } stock bool IsValidClient(int client) { if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client)) || IsClientSourceTV(client) || IsClientReplay(client)) { return false; } return true; } stock void YerdekiSilahlariSil() { int g_WeaponParent = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity"); int maxent = GetMaxEntities(); char weapon[64]; for (int i = MaxClients; i < maxent; i++) { if (IsValidEdict(i) && IsValidEntity(i)) { GetEdictClassname(i, weapon, sizeof(weapon)); if ((StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1) && GetEntDataEnt2(i, g_WeaponParent) == -1)RemoveEdict(i); } } } stock void Silah_Sil(int client) { for (int j = 0; j < 12; j++) { int weapon = GetPlayerWeaponSlot(client, j); if (weapon != -1) { RemovePlayerItem(client, weapon); RemoveEdict(weapon); } } } stock bool CheckAdminFlag(int client, const char[] flags) { int iCount = 0; char sflagNeed[22][8], sflagFormat[64]; bool bEntitled = false; Format(sflagFormat, sizeof(sflagFormat), flags); ReplaceString(sflagFormat, sizeof(sflagFormat), " ", ""); iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[])); for (int i = 0; i < iCount; i++) { if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT)) { bEntitled = true; break; } } return bEntitled; } 
