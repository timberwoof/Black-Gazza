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

// link message json keys of things we're interested in showing the wearer
list interestingMessages = ["AssetNumber", "Crime", "Class", "Threat", 
    "RLV", "LockLevel", "ZapLevels", "Mood", "ZAP", "BatteryPercent"];
// not interesting now but could be added: 
// "Name", "rlvPresent", "RelayLockState", 

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("subxmit: "+message);
    }
}

default
{
    link_message(integer sender_num, integer num, string json, key id) {
        // If the key is "interesting" then send it to the HUD. 
        string jsonkey = llList2String(llJson2List(json),0);
        if (llListFindList(interestingMessages, [jsonkey]) > 0) {
            sayDebug("link_message "+json);
            llWhisper(subliminalChannel, json);
        }    
    }
}
