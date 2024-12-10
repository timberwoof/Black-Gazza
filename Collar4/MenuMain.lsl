// MenuMain.lsl
// Menu script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019
string version = "2024-12-08";

integer OPTION_DEBUG = FALSE;

integer menuChannel = 0;
integer menuListen = 0;
string menuIdentifier;
key menuAgentKey;

integer wearerChannel = 1;
integer wearerListen = 0;
string menuPhrase;

// Punishments
integer allowZapLow = TRUE;
integer allowZapMed = TRUE;
integer allowZapHigh = TRUE;
integer allowZapByObject = TRUE;
integer allowVision = TRUE;

string assetNumber = "P-00000";
string name;
string crime = "Unknown";
string threat = "Moderate";
string mood;
string class = "white";
list classes = ["white", "pink", "red", "orange", "green", "blue", "black"];
list classesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental"];

string RLV = "RLV";
string lockLevel;
string lockLevelOff = "Off";
integer rlvPresent = FALSE;
integer renamerActive = FALSE;
integer DisplayTokActive = FALSE;
string RelayLockState = "Off"; // what the relay told us

string batteryGraph = "";

string menuMain = "Main";
string moodDND = "DnD";
string moodOOC = "OOC";
string moodLockup = "Lockup";

string buttonBlank = " ";
string buttonInfo = "Info";
string buttonSettings = "Settings";
string buttonPunish = "Punish";
string buttonLeash = "Leash";
string buttonForceSit = "ForceSit";
string buttonSafeword = "Safeword";
string buttonRelease = "Release";
string buttonIncidents = "Incidents";
//string buttonHack = "Hack";

key guardGroupKey = "b3947eb2-4151-bd6d-8c63-da967677bc69";
key soundBlurp = "d5567c52-b78d-f78f-bcb1-605701b3af24";

// Utilities *******

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("MenuMain: "+message);
    }
}

sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
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

integer getLinkWithName(string linkName) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    for (; i < x; ++i)
        if (llGetLinkName(i) == linkName)
            return i; // Found it! Exit loop early with result
    return -1; // No prim with that name, return -1.
}

mainMenu(key avatarKey) {
    string message = menuMain + "\n";

    if (assetNumber == "P-00000") {
        sendJSON("Database", "getupdate", avatarKey);
    }

    if (menuAgentKey != "" & menuAgentKey != avatarKey) {
        llInstantMessage(avatarKey, "The collar menu is being accessed by someone else.");
        sayDebug("Told " + llKey2Name(avatarKey) + "that the collar menu is being accessed by someone else.");
        return;
    }

    // assume some things are not available
    integer doPunish = FALSE;
    integer doForceSit = FALSE;
    integer doLeash = FALSE;
    integer doSafeword = FALSE;
    integer doRelease = FALSE;
    integer doIncidents = TRUE; // **** Set to FALSE for production

    // Collar functions controlled by Mood: punish, force sit, leash, speech
    if (mood == moodDND | mood == moodLockup) {
        if (avatarKey == llGetOwner()) {
            doPunish = TRUE;
            doForceSit = TRUE;
            doLeash = TRUE;
        }
    } else if (mood == moodOOC) {
            // everyone can do everything (but you better ask)
            doPunish = TRUE;
            doForceSit = TRUE;
            doLeash = TRUE;
    } else { // mood == anything else
        if (avatarKey == llGetOwner()) {
            // wearer can't do anything
        } else if (agentIsGuard(avatarKey)) {
            // Guards can do anything
            doPunish = TRUE;
            doForceSit = TRUE;
            doLeash = TRUE;
        } else {
            // other prisoners can leash and force sit
            doForceSit = TRUE;
            doLeash = TRUE;
        }
    }

    // Collar functions overridden by lack of RLV
    if (!rlvPresent) {
        doForceSit = FALSE;
        doLeash = FALSE;
        message = message + "\nSome functions are available ony when RLV is present.";
    }

    // Collar functions controlled by locklevel: Safeword and Release
    if (agentIsGuard(avatarKey)) { // lockLevel == "Hardcore" && 
        doRelease = TRUE;
        doIncidents = TRUE;
    } else {
        message = message + "\nRelease command is available to a Guard when prisoner is in RLV Hardcore mode.";
    }

    if (avatarKey == llGetOwner() && lockLevel != "Hardcore" && lockLevel != lockLevelOff) {
        doSafeword = TRUE;
    } else {
        message = message + "\nSafeword is availavle to the Prisoner in RLV levels Medium and Heavy.";
    }

    list buttons = [];
    buttons = buttons + menuButtonActive(buttonSafeword, doSafeword);
    buttons = buttons + menuButtonActive(buttonRelease, doRelease);
    buttons = buttons + menuButtonActive(buttonIncidents, doIncidents);;
    buttons = buttons + menuButtonActive(buttonPunish, doPunish);
    buttons = buttons + menuButtonActive(buttonLeash, doLeash);
    buttons = buttons + menuButtonActive(buttonForceSit, doForceSit);
    buttons = buttons + buttonSettings;
    buttons = buttons + buttonInfo;

    setUpMenu(menuMain, avatarKey, message, buttons);
}

doMainMenu(key avatarKey, string message) {
    //sendJSON(RLV, "Status", avatarKey); // this asks for RLV status update all the damn time.
    if (message == buttonInfo){
        giveInfo(avatarKey);
    }
    else if (message == buttonSettings){
        sendJSON("Menu", buttonSettings, avatarKey);
    }
    //else if (message == buttonHack){
    //    hackMenu(avatarKey);
    //}
    else if (message == buttonPunish){
        punishMenu(avatarKey);
    }
    else if (message == buttonForceSit){
        sendJSON(buttonLeash, buttonForceSit, avatarKey);
    }
    else if (message == buttonLeash){
        sendJSON(buttonLeash, buttonLeash, avatarKey);
    }
    else if (message == buttonSafeword){
        sendJSON(RLV, buttonSafeword, avatarKey);
    }
    else if (message == buttonRelease){
        sendJSON(RLV, lockLevelOff, avatarKey);
    }
    else if (message == buttonIncidents) {
        sendJSON("Database", "incidents", avatarKey);
    } else {
        llPlaySound(soundBlurp, 1.0);
        llSleep(0.2);
    }
}

punishMenu(key avatarKey)
{
    // the zap menu never includes radio buttons in front of the Zap word
    string message = buttonPunish;
    list buttons = [];
    buttons = buttons + menuButtonActive("Zap Low", allowZapLow);
    buttons = buttons + menuButtonActive("Zap Med", allowZapMed);
    buttons = buttons + menuButtonActive("Zap High", allowZapHigh);
    //buttons = buttons + menuButtonActive("Vision" , allowVision);
    setUpMenu(buttonPunish, avatarKey, message, buttons);
}

string class2Description(string class) {
    return llList2String(classes, llListFindList(classes, [class])) + "=" +
        llList2String(classesLong, llListFindList(classes, [class]));
}

giveInfo(key avatarKey){
    // Prepare text of collar settings for the information menu
    string message = "Prisoner Information \n" +
    "\nNumber: " + assetNumber + " (" + name + ")\n";
    if (agentIsGuard(avatarKey) || avatarKey == llGetOwner()) {
        string ZapLevels = "";
        ZapLevels = menuCheckbox("Low", allowZapLow) + "  " +
        menuCheckbox("Medium", allowZapMed) +  "  " +
        menuCheckbox("High", allowZapHigh) + "  " +
        menuCheckbox("Objects", allowZapByObject);

        message = message +
        "Crime: " + crime + "\n" +
        "Class: "+class2Description(class)+"\n" +
        "Threat: " + threat + "\n" +
        "Shock: " + ZapLevels + "\n";
    } else {
        string restricted = "RESTRICTED INFO";
        message = message +
        "Crime: " + restricted + "\n" +
        "Class: "+restricted+"\n" +
        "Threat: " + restricted + "\n" +
        "Punishment: " + restricted + "\n";
    }
    message = message + "Battery Level: " + batteryGraph + "\n";
    message = message + "\nOOC Information:\n";
    message = message + "Version: " + version + "\n";
    message = message + "Mood: " + mood + "\n";
    message = message + "RLV Relay: " + RelayLockState + "\n";
    if (rlvPresent) {
        message = message + "RLV Active: " + lockLevel + "\n";
    } else {
        message = message + "RLV not detected.\n";
    }

    if (OPTION_DEBUG) {
        message = message + "Used Memory: " + (string)llGetUsedMemory() + ".\n";
    }

    // Prepare a list of documents to hand out
    list buttons = [];
    integer numNotecards = llGetInventoryNumber(INVENTORY_NOTECARD);
    if (numNotecards > 0) {
        message = message + "\nChoose a Notecard:";
        integer index;
        for (index = 0; index < numNotecards; index++) {
            integer inumber = index+1;
            string title = llGetSubString(llGetInventoryName(INVENTORY_NOTECARD,index), 0, 20);
            message += "\n" + (string)inumber + " - " + title;
            buttons += ["Doc "+(string)inumber];
        }
    }

    message = llGetSubString(message, 0, 511);
    setUpMenu(buttonInfo, avatarKey, message, buttons);
}

doSetPunishmentLevels(key avatarKey, string message)
{
    if (avatarKey == llGetOwner())
    {
        sayDebug("wearer sets allowable zap level: "+message);
        if (message == "") {
            allowZapLow = TRUE;
            allowZapMed = TRUE;
            allowZapHigh = TRUE;
            allowVision = TRUE;
        }
        else if (message == "Zap Low") {
            allowZapLow = !allowZapLow;
        } else if (message == "Zap Med") {
            allowZapMed = !allowZapMed;
        } else if (message == "Zap High") {
            allowZapHigh = !allowZapHigh;
        //} else if (message == "Vision") {
        //    allowVision = !allowVision;
        }
        if (!(allowZapLow || allowZapMed || allowZapHigh)) {
            allowZapHigh = TRUE;
        }
        string zapJsonList = llList2Json(JSON_ARRAY, [allowZapLow, allowZapMed, allowZapHigh]);
        sendJSON("ZapLevels", zapJsonList, avatarKey);
        //sendJSONinteger("AllowVision", allowVision, avatarKey);
    }
}

// Event Handlers ***************************
default
{
    state_entry()
    {
        sayDebug("MainMenu: state_entry");
        menuAgentKey = "";
        mood = moodOOC;
        lockLevel = lockLevelOff;
        renamerActive = FALSE;

        // Initialize Unworn
        if (llGetAttached() == 0) {
            sendJSON("AssetNumber", assetNumber, "");
            sendJSON("Class", "white", "");
            sendJSON("Crime", "unknown", "");
            sendJSON("Threat", "None", "");
            sendJSON("Mood", moodOOC, "");
            doSetPunishmentLevels(llGetOwner(),""); // initialize
        }

        sayDebug("MainMenu: state_entry");
    }

    attach(key avatar) {
        if(llGetAttached() == 0) return;
        sayDebug("attach");
        string canonicalName = llToLower(llKey2Name(llGetOwner()));
        list canoncialList = llParseString2List(llToLower(canonicalName), [" "], []);
        string initials = llGetSubString(llList2String(canoncialList,0),0,0) + llGetSubString(llList2String(canoncialList,1),0,0);
        menuPhrase = initials + "Menu";
        llOwnerSay("Access the collar menu by typing /1"+menuPhrase);
        wearerListen = llListen(wearerChannel, "", "", menuPhrase);
        sayDebug("attach done");
    }

    touch_start(integer total_number)
    {
        key whoClicked  = llDetectedKey(0);
        integer touchedLink = llDetectedLinkNumber(0);
        integer touchedFace = llDetectedTouchFace(0);
        vector touchedUV = llDetectedTouchUV(0);
        sayDebug("Link "+(string)touchedLink+", Face "+(string)touchedFace+", UV "+(string)touchedUV);
        mainMenu(whoClicked);
    }

    listen( integer channel, string name, key avatarKey, string message )
    {
        sayDebug("listen name:"+name+" message:"+message);

        // listen for the /1flmenu command
        if (channel == wearerChannel & message == menuPhrase) {
            sayDebug("listen menuAgentKey:'"+(string)menuAgentKey+"'");
            if (menuAgentKey != avatarKey) {
                mainMenu(avatarKey);
                menuAgentKey = "";
            } else {
                llInstantMessage(avatarKey, "The collar menu is being accessed by someone else.");
            }
            return;
        }

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

        // Main button
        if (message == menuMain) {
            mainMenu(avatarKey);
        }
        //Main Menu
        else if ((menuIdentifier == menuMain) || (message == buttonSettings)) {
            sayDebug("listen: Main:"+message);
            doMainMenu(avatarKey, message);
        }
        // Zap the inmate
        else if (menuIdentifier == buttonPunish) {
            sayDebug("listen: Zap:"+message);
            sendJSON(RLV, message, avatarKey);
        }
        // Document
        else if (menuIdentifier == buttonInfo) {
            integer inumber = (integer)llGetSubString(message,4,4) - 1;
            sayDebug("listen: message:"+message+ " inumber:"+(string)inumber);
            if (inumber > -1) {
                llOwnerSay("Offering '"+llGetInventoryName(INVENTORY_NOTECARD,inumber)+"' to "+llGetDisplayName(avatarKey)+".");
                llGiveInventory(avatarKey, llGetInventoryName(INVENTORY_NOTECARD,inumber));
            }
        }
        else {
            sayDebug("ERROR: did not process menuIdentifier "+menuIdentifier);
            llPlaySound(soundBlurp, 0.2);
            llSleep(1);
        }
    }

    link_message(integer sender_num, integer num, string json, key avatarKey){
        // We listen in on link status messages and pick the ones we're interested in
        //sayDebug("link_message json "+json);
        assetNumber = getJSONstring(json, "AssetNumber", assetNumber);
        name = getJSONstring(json, "Name", name);
        crime = getJSONstring(json, "Crime", crime);
        class = getJSONstring(json, "Class", class);
        threat = getJSONstring(json, "Threat", threat);
        mood = getJSONstring(json, "Mood", mood);
        lockLevel = getJSONstring(json, "LockLevel", lockLevel);
        RelayLockState = getJSONstring(json, "RelayLockState", RelayLockState);
        renamerActive = getJSONinteger(json, "renamerActive", renamerActive);
        DisplayTokActive = getJSONinteger(json, "DisplayTokActive", DisplayTokActive);
        batteryGraph = getJSONstring(json, "BatteryGraph", batteryGraph);
        rlvPresent = getJSONinteger(json, "rlvPresent", rlvPresent);
        if (!rlvPresent) {
            renamerActive = FALSE;
            DisplayTokActive = FALSE;
        }
        if(getJSONstring(json, "Menu", "") == menuMain)
        {
            menuIdentifier = menuMain;
            mainMenu(avatarKey);
        }
        // zap levels and objects
        // string zapJsonList = llList2Json(JSON_ARRAY, [allowZapLow, allowZapMed, allowZapHigh]);
        string zapJsonList = llJsonGetValue(json, ["ZapLevels"]);
        if (zapJsonList != JSON_INVALID) {
            sayDebug("link_message ZapLevels "+zapJsonList);
            list zapList = llJson2List(zapJsonList);
            sayDebug("link_message zapList "+(string)zapList);
            allowZapLow = llList2Integer(zapList,0);
            allowZapMed = llList2Integer(zapList,1);
            allowZapHigh = llList2Integer(zapList,2);
        }
        allowZapByObject = getJSONinteger(json, "allowZapByObject", allowZapByObject);
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
