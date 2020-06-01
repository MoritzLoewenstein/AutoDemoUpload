#include <sourcemod>
#include <SteamWorks>

ArrayList g_aMsgs = null;
ArrayList g_aWebhook = null;

Handle g_hTimer = null;

bool g_bSending;
bool g_bSlowdown;

public Plugin myinfo = {
	name = "Discord API",
	author = "MoeJoe111",
	description = "This plugin lets you send messages to discord",
	version = "0.5",
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("Discord_SendMessage", Native_SendMessage);
	RegPluginLibrary("discord");
	return APLRes_Success;
}

public void OnPluginStart() {
	//empty
}

public void OnMapStart() {
	RestartMessageTimer(false);
}

public void OnMapEnd() {
	g_hTimer = null;
}

public int Native_SendMessage(Handle plugin, int numParams) {
	char sUrl[512]
	GetNativeString(1, sUrl, sizeof(sUrl));

	char sMessage[4096];
	GetNativeString(2, sMessage, sizeof(sMessage));
	
	// If the message dosn't start with a '{' it's not for a JSON formated message, lets fix that!
	if(StrContains(sMessage, "{") != 0)
		Format(sMessage, sizeof(sMessage), "{\"content\":\"%s\"}", sMessage);
	
	if (g_aMsgs == null) {
		g_aWebhook = new ArrayList(64);
		g_aMsgs = new ArrayList(4096);
	}
	
	g_aWebhook.PushString(sUrl);
	g_aMsgs.PushString(sMessage);
}

public Action Timer_SendNextMessage(Handle timer, any data) {
	SendNextMsg();
	return Plugin_Continue;
}

public void SendNextMsg() {
	// We are still waiting for a reply from our last msg
	if(g_bSending)
		return;
	
	// Nothing to send
	if(g_aMsgs == null || g_aMsgs.Length < 1)
		return;
	
	char sUrl[512]
	g_aWebhook.GetString(0, sUrl, sizeof(sUrl));

	char sMessage[4096];
	g_aMsgs.GetString(0, sMessage, sizeof(sMessage));
	
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, sUrl);
	if(!hRequest || !SteamWorks_SetHTTPCallbacks(hRequest, view_as<SteamWorksHTTPRequestCompleted>(OnRequestComplete)) 
				|| !SteamWorks_SetHTTPRequestRawPostBody(hRequest, "application/json", sMessage, strlen(sMessage))
				|| !SteamWorks_SendHTTPRequest(hRequest)) {
		delete hRequest;
		LogError("SendNextMsg: Failed To Send Message");
		return;
	}
	
	// Don't Send new messages aslong we wait for a reply from this one
	g_bSending = true;
}

public int OnRequestComplete(Handle hRequest, bool bFailed, bool bRequestSuccessful, EHTTPStatusCode eStatusCode) {
	// This should not happen!
	if(bFailed || !bRequestSuccessful) {
		LogError("[OnRequestComplete] Request failed");
	}
	// Seems like the API is busy or too many message send recently
	else if(eStatusCode == k_EHTTPStatusCode429TooManyRequests || eStatusCode == k_EHTTPStatusCode500InternalServerError) {
		if(!g_bSlowdown) RestartMessageTimer(true);
	}
	// Wrong msg format, API doesn't like it
	else if(eStatusCode == k_EHTTPStatusCode400BadRequest) {
		char sMessage[4096];
		g_aMsgs.GetString(0, sMessage, sizeof(sMessage));
		
		LogError("[OnRequestComplete] Bad Request! Error Code: [400]. Check your message, the API doesn't like it! Message: \"%s\"", sMessage); 
		
		// Remove it, the API will never accept it like this.
		g_aWebhook.Erase(0);
		g_aMsgs.Erase(0);
	}
	else if(eStatusCode == k_EHTTPStatusCode200OK || eStatusCode == k_EHTTPStatusCode204NoContent) {
		if(g_bSlowdown) RestartMessageTimer(false);
		g_aWebhook.Erase(0);
		g_aMsgs.Erase(0);
	}
	// Unknown error
	else {
		LogError("[OnRequestComplete] Error Code: [%d]", eStatusCode);
		g_aWebhook.Erase(0);
		g_aMsgs.Erase(0);
	}
	
	delete hRequest;
	g_bSending = false;
}

public void RestartMessageTimer(bool slowdown) {
	g_bSlowdown = slowdown;

	if(g_hTimer != null) delete g_hTimer;
	g_hTimer = CreateTimer(g_bSlowdown ? 1.0 : 0.1, Timer_SendNextMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}