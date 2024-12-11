// MenuRLV.lsl
// Menu script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019
string version = "2024-12-11";

integer OPTION_DEBUG = FALSE;

integer menuChannel = 0;
integer menuListen = 0;
string menuIdentifier;
key menuAgentKey;

string RLV = "RLV";
string buttonBlank = " ";
string lockLevel;
list lockLevels = ["Off", "Light", "Medium", "Heavy", "Hardcore"];
string lockLevelOff = "Off";
integer rlvPresent = FALSE;
integer renamerActive = FALSE;
integer relayCheckboxState = FALSE;
string RelayOFF = "Off";
string RelayASK = "Ask";
string RelayON = "On";

string assetNumber = "P-00000";

string menuMain = "Main";

string buttonInfo = "Info";
string buttonSettings = "Settings";
string buttonSpeech = "Speech";

key guardGroupKey = "b3947eb2-4151-bd6d-8c63-da967677bc69";
key blurp = "d5567c52-b78d-f78f-bcb1-605701b3af24";

// Utilities *******

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("MenuRLV: "+message);
    }
}

sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
}

sendJSONCheckbox(string jsonKey, string value, key avatarKey, integer ON) {
    if (ON) {
        sendJSON(jsonKey, value+"ON", avatarKey);
    } else {
        sendJSON(jsonKey, value+"OFF", avatarKey);
    }
}

sendJSONinteger(string jsonKey, integer value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, (string)value]), avatarKey);
}

string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
    }
    return result;
}

integer getJSONinteger(string jsonValue, string jsonKey, integer valueNow){
    integer result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = (integer)value;
    }
    return result;
}

/**
    since you can't directly check the agent's active group, this will get the group from the agent's attached items
*/
integer agentIsGuard(key agent)
{
    list attachList = llGetAttachedList(agent);
    integer item;
    while(item < llGetListLength(attachList))
    {
        if(llList2Key(llGetObjectDetails(llList2Key(attachList, item), [OBJECT_GROUP]), 0) == guardGroupKey) return TRUE;
        item++;
    }
    return FALSE;
}

setUpMenu(string identifier, key avatarKey, string message, list buttons)
// wrapper to do all the calls that make a simple menu dialog.
// - adds required buttons such as Close or Main
// - displays the menu command on the alphanumeric display
// - sets up the menu channel, listen, and timer event
// - calls llDialog
// parameters:
// identifier - sets menuIdentifier, the later context for the command
// avatarKey - uuid of who clicked
// message - text for top of blue menu dialog
// buttons - list of button texts
{
    sayDebug("setUpMenu "+identifier);

    if (identifier != menuMain) {
        buttons = buttons + [menuMain];
    }
    buttons = buttons + ["Close"];

    sendJSON("DisplayTemp", "menu access", avatarKey);
    menuIdentifier = identifier;
    menuAgentKey = avatarKey; // remember who clicked
    string completeMessage = assetNumber + " " + message;
    menuChannel = -(llFloor(llFrand(10000)+1000));
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
    llDialog(avatarKey, completeMessage, buttons, menuChannel);
}

string menuCheckbox(string title, integer onOff)
// make checkbox menu item out of a button title and boolean state
{
    string checkbox;
    if (onOff)
    {
        checkbox = "☒";
    }
    else
    {
        checkbox = "☐";
    }
    return checkbox + " " + title;
}

list menuRadioButton(string title, string match)
// make radio button menu item out of a button and the state text
{
    string radiobutton;
    if (title == match)
    {
        radiobutton = "●";
    }
    else
    {
        radiobutton = "○";
    }
    return [radiobutton + " " + title];
}

list menuButtonActive(string title, integer onOff)
// make a menu button be the text or the Inactive symbol
{
    string button;
    if (onOff)
    {
        button = title;
    }
    else
    {
        button = "["+title+"]";
    }
    return [button];
}

integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    for (; i < x; ++i)
        if (llGetLinkName(i) == name)
            return i; // Found it! Exit loop early with result
    return -1; // No prim with that name, return -1.
}

// Menus and Handlers ****************

setRelayState(integer on) {
    sayDebug("setRelayState("+(string)on+")");
    key avatarKey = llGetOwner();
    if (on) {
        integer level = llListFindList(lockLevels, [lockLevel]);
        if (level < 3) {
            sendJSON("DisplayTemp", "Relay ASK", avatarKey);
            sayDebug("setRelayState: "+(string)level+" "+RelayASK);
            sendJSON("RelayCommand", RelayASK, avatarKey);
        } else {
            // Heavy or hardcore
            sendJSON("DisplayTemp", "Relay ON", avatarKey);
            relayCheckboxState = TRUE;
            sayDebug("setRelayState: "+(string)level+" "+RelayON);
            sendJSON("RelayCommand", RelayON, avatarKey);
        }
    }  else {
        sendJSON("DisplayTemp", "Relay OFF", avatarKey);
        sayDebug("setRelayState: "+RelayOFF);
        sendJSON("RelayCommand", RelayOFF, avatarKey);
    }
}

lockMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "Set your Lock Level\n\n" +
            "Each level applies heavier RLV restrictions.\n"+
            "• Off has no RLV restrictions.\n" +
            "• Light and Medium can be switched Off any time.\n" +
            "• Heavy requires you to acitvely Safeword out.\n" +
            "• Hardcore has no safeword. To be released, you must ask a Guard.";

        // lockLevels: 0=Off 1=Light 2=Medium 3=Heavy 4=Hardcore
        // convert our locklevel to an integer
        sayDebug("lockMenu lockLevel:"+lockLevel);
        integer iLockLevel = llListFindList(lockLevels, [lockLevel]);
        sayDebug("lockMenu iLocklevel:"+(string)iLockLevel);
        // make a list of wjether each lock level is available from that lock level
        // lockLevel: 0=off, 1=light, 2=medium, 3=heavy, 4=hardcore
        list lockListOff = [FALSE, TRUE, TRUE, TRUE, FALSE];
        list lockListLight = [TRUE, FALSE, TRUE, TRUE, FALSE];
        list lockListMedium = [TRUE, TRUE, FALSE, TRUE, FALSE];
        list lockListHeavy = [FALSE, FALSE, FALSE, FALSE, TRUE];
        list lockListHardcore = [FALSE, FALSE, FALSE, FALSE, FALSE];
        list lockLists = lockListOff + lockListLight + lockListMedium + lockListHeavy + lockListHardcore; // strided list
        list lockListMenu = llList2List(lockLists, iLockLevel*5, (iLockLevel+1)*5); // list of lock levels to add to menu
        sayDebug("lockMenu lockListMenu:"+(string)lockListMenu);

        //make the button list
        list buttons = [];
        integer levelIndex;
        for (levelIndex = 0; levelIndex < 5; levelIndex++) {
            integer buttonActive =  llList2Integer(lockListMenu, levelIndex);
            string buttonText = llList2String(lockLevels, levelIndex);
            string radioButton = llList2String(menuRadioButton(buttonText, lockLevel), 0);
            buttons = buttons + menuButtonActive(radioButton, buttonActive);
            // It may seem stupid to have ([•] something) but in this case choosing it again is stupider.
        }
        buttons = buttons + buttonBlank;

        // Relay button
        buttons = buttons + menuButtonActive(menuCheckbox("Relay", relayCheckboxState), iLockLevel < 3);
        buttons = buttons + buttonBlank + buttonBlank;

        // Settings button
        buttons = buttons + [buttonSettings];

        setUpMenu(RLV, avatarKey, message, buttons);
    }
}
doLockMenu(key avatarKey, string message, string messageButtonsTrimmed) {
    sayDebug("doLockMenu("+message+","+messageButtonsTrimmed+")");
    // Ask to Confirm Hardcore.
    if (message == "○ Hardcore") {
        confirmHardcore(avatarKey);

    // Hardcore is Confirmed. Set Hardcore.
    } else if (message == "⨷ Hardcore") {
        sayDebug("listen set lockLevel:\""+lockLevel+"\"");
        sendJSON(RLV, "Hardcore", avatarKey);
        relayCheckboxState = TRUE;
        setRelayState(relayCheckboxState);

    // Relay
    } else if (message == menuCheckbox("Relay", relayCheckboxState)) {
        // RelayState() now returns what the state is now,
        // which the wearer wants to change to the opposite.
        if (relayCheckboxState) {
            relayCheckboxState = FALSE;
        } else {
            relayCheckboxState = TRUE;
        }
        sayDebug("listen set relayCheckboxState:"+(string)relayCheckboxState);
        setRelayState(relayCheckboxState);

    // Locklevels
    } else if (llListFindList(lockLevels, [messageButtonsTrimmed]) > -1) {
        sayDebug("listen set lockLevel:\""+lockLevel+"\"");
        sendJSON(RLV, messageButtonsTrimmed, avatarKey);
        if (messageButtonsTrimmed == "Heavy") {
            sayDebug("listen lockLevel Heavy, so turn on renamer");
            renamerActive = TRUE;
            sendJSONCheckbox(buttonSpeech, "Renamer", avatarKey, renamerActive);
            relayCheckboxState = TRUE;
            }
        setRelayState(relayCheckboxState);
        // settingsMenu(avatarKey);
        // need to send json to call settings menu
        llSleep(0.5);
        sendJSON("Menu", buttonSettings, avatarKey);

    // Ignore
    } else if ((message != menuMain) & (message != buttonSettings)) {
        sayDebug("doLockMenu ignoring "+message);
        llPlaySound(blurp, 1.0);
        llSleep(0.5);
    }
}

confirmHardcore(key avatarKey) {
    sayDebug("confirmHardcore");
    if (avatarKey == llGetOwner()) {
        string message = "Set your Lock Level to Hardcore?\n"+
        "• Hardcore has the Heavy restrictions\n"+
        "• Hardcore has no safeword.\n"+
        "• To be released from Hardcore, you must ask a Guard.\n\n"+
        "Confirm that you want the Hardcore lock.";
        list buttons = ["⨷ Hardcore"];
        setUpMenu(RLV, avatarKey, message, buttons);
    }
}

default
{

    listen( integer channel, string name, key avatarKey, string message )
    {
        string messageButtonsTrimmed = message;
        list striplist = ["☒ ","☐ ","● ","○ "];
        integer i;
        for (i=0; i < llGetListLength(striplist); i = i + 1) {
            string thing = llList2String(striplist, i);
            integer whereThing = llSubStringIndex(messageButtonsTrimmed, thing);
            if (whereThing > -1) {
                integer thingLength = llStringLength(thing)-1;
                messageButtonsTrimmed = llDeleteSubString(messageButtonsTrimmed, whereThing, whereThing + thingLength);
            }
        }
        sayDebug("listen messageButtonsTrimmed:"+messageButtonsTrimmed+" menuIdentifier: "+menuIdentifier);

        // display the menu item
        if (llGetSubString(message,1,1) == " ") {
            sendJSON("DisplayTemp", messageButtonsTrimmed, avatarKey);
        } else {
            sendJSON("DisplayTemp", message, avatarKey);
        }

        // reset the menu setup
        llListenRemove(menuListen);
        menuListen = 0;
        menuChannel = 0;
        menuAgentKey = "";
        llSetTimerEvent(0);

        if (message == "Close") {
            return;
        }
        else if(message == menuMain)
        {
            sendJSON("Menu", menuMain, avatarKey);
        }
        else if(message == buttonSettings)
        {
            sendJSON("Menu", buttonSettings, avatarKey);
        }

        if (menuIdentifier == RLV) {
            sayDebug("listen Lock: message:"+message);
            doLockMenu(avatarKey, message, messageButtonsTrimmed);
        }
    }

    link_message(integer sender_num, integer num, string json, key avatarKey){
        // We listen in on link status messages and pick the ones we're interested in
        //sayDebug("link_message json "+json);
        assetNumber = getJSONstring(json, "AssetNumber", assetNumber);
        lockLevel = getJSONstring(json, "LockLevel", lockLevel);
        renamerActive = getJSONinteger(json, "renamerActive", renamerActive);
        rlvPresent = getJSONinteger(json, "rlvPresent", rlvPresent);
        if (!rlvPresent) {
            renamerActive = FALSE;
        }

        if(getJSONstring(json, "Menu", "") == RLV)
        {
            menuIdentifier = RLV;
            lockMenu(avatarKey);
        }
    }

    timer()
    {
        llSetTimerEvent(0);
        // reset the menu setup
        llListenRemove(menuListen);
        menuListen = 0;
        menuAgentKey = "";
    }
}
