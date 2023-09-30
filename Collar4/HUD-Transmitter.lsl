// HUD-Transmitter.lsl
// Script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019
string version = "2023-09-29";

// This script intercepts JSON messages and retransmits them to the wearer's L-CON sumliminal HUD visor thing

integer OPTION_DEBUG = FALSE;


integer subliminalChannel = -36984125;
string sAssetNumber = "P-00000";
integer iAssetNumber = 0;

list interestingMessages = ["AssetNumber", "Name", "Crime", "Class", "Threat", 
    "rlvPresent", "RLV", "LockLevel", "RelayLockState", 
    "ZapLevels", "Mood", "ZAP"];

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("subxmit: "+message);
    }
}

string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
    }
    return result;
}

default
{
    state_entry()
    {
        sayDebug("state_entry done");
    }

    attach(key theAvatar) {
        sayDebug("attach done");
    }

    link_message( integer sender_num, integer num, string json, key id ){
        string jsonkey = llList2String(llJson2List(json),0);
        if (llListFindList(interestingMessages, [jsonkey]) > 0) {
            sayDebug("link_message "+json);
            llWhisper(subliminalChannel, json);
        }    
    }
}
