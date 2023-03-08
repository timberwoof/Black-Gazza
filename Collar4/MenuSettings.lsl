// MenuSettings.lsl
// Menu script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019
string version = "2022-09-06";

integer OPTION_DEBUG = FALSE;

integer menuChannel = 0;
integer menuListen = 0;
string menuIdentifier;
key menuAgentKey;

// Punishments
integer allowZapLow = TRUE;
integer allowZapMed = TRUE;
integer allowZapHigh = TRUE;
integer allowVision = TRUE;

string mood;
string class = "white";
list classes = ["white", "pink", "red", "orange", "green", "blue", "black"];

string RLV = "RLV";
string lockLevel;
string lockLevelOff = "Off";
integer rlvPresent = FALSE;
integer renamerActive = FALSE;
integer DisplayTokActive = FALSE;

integer speechPenaltyBuzz = 0;
integer speechPenaltyZap = 0;

string crime = "Unknown";
string assetNumber = "P-00000";
string threat = "Moderate";
integer batteryActive = FALSE;
integer badWordsActive = FALSE;
integer titlerActive = TRUE;

string menuMain = "Main";
string moodDND = "DnD";
string moodOOC = "OOC";
string moodLockup = "Lockup";
string moodSubmissive = "Submissive";
string moodVersatile = "Versatile";
string moodDominant = "Dominant";
string moodNonsexual = "Nonsexual";
string moodStory = "Story";

string buttonBlank = " ";
string buttonSpeech = "Speech";
string buttonPenalties = "Penalties";
string buttonSettings = "Settings";
string buttonTitler = "Titler";
string buttonBattery = "Battery";
string buttonCharacter = "Character";
//string buttonHack = "Hack";

key guardGroupKey = "b3947eb2-4151-bd6d-8c63-da967677bc69";

// Utilities *******

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Menu: "+message);
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
    string completeMessage = assetNumber + " Collar: " + message;
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

// Settings Menus and Handlers ************************
// Sets Collar State: Mood, Threat, Lock, Zap levels 

settingsMenu(key avatarKey) {
    // What this menu can present depends on a number of things: 
    // who you are - self or guard
    // IC/OOC mood - OOC, DnD or other
    // RLV lock level - Off, Light, Medium, Heavy, Lardcore
    
    string message = buttonSettings;

    // 1. Assume nothing is allowed
    integer setClass = FALSE;
    integer setMood = FALSE;
    integer setThreat = FALSE;
    integer setLock = FALSE;
    integer setPunishments = FALSE;
    //integer setTimer = FALSE;
    //integer setAsset = FALSE;
    integer setBadWords = FALSE;
    integer setSpeech = FALSE;
    integer setTitle = FALSE;
    integer setBattery = FALSE;
    integer setCharacter = FALSE;
    integer setCrimes = FALSE;
    
    // Add some things depending on who you are. 
    // What wearer can change
    if (avatarKey == llGetOwner()) {
        // some things you can always cange
        sayDebug("settingsMenu: wearer");
        setMood = TRUE;
        setLock = TRUE;
        setSpeech = TRUE;
        //setTimer = TRUE;
        setTitle = TRUE;
        setBattery = TRUE;
        
        // Some things you can only change OOC
        if ((mood == moodOOC) || (mood == moodDND)) {
            sayDebug("settingsMenu: ooc");
            // IC or DnD you change everything
            setClass = TRUE;
            setThreat = TRUE;
            setPunishments = TRUE;
            //setAsset = TRUE;
            setBadWords = TRUE;
            setCharacter = TRUE;
        }
        else {
            message = message + "\nSome settings are not available while you are IC.";
        }
    }
    // What a guard can change
    else if(agentIsGuard(avatarKey))
    { // (avatarKey != llGetOwner())
        // guard can always set some things
        sayDebug("settingsMenu: guard");
        setThreat = TRUE;
        setSpeech = TRUE;
        setCrimes = TRUE;
        
        // some things guard can change only OOC
        if (mood == moodOOC) {
            sayDebug("settingsMenu: ooc");
            // OOC, guards can change some things
            // DnD means Do Not Disturb
            setClass = TRUE;
            setCrimes = FALSE;
        }
        else {
            message = message + "\nSome settings are not available while you are OOC.";
        }
    }
    
    // Lock level changes some privileges
    if ((lockLevel == "Hardcore" || lockLevel == "Heavy")) {
        if (avatarKey == llGetOwner()) {
            sayDebug("settingsMenu: heavy-owner");
            setPunishments = FALSE;
            setThreat = FALSE;
            //setTimer = FALSE;
            setSpeech = FALSE;
            setBattery = FALSE;
            message = message + "\nSome settings are not available while your lock level is Heavy or Hardcore.";
        } 
        else if(agentIsGuard(avatarKey))
        {
            
            sayDebug("settingsMenu: heavy-guard");
            setPunishments = TRUE;
            setThreat = TRUE;
            //setTimer = TRUE;
        }
    }

    if ((lockLevel == "Hardcore") && (avatarKey == llGetOwner())) {
        setLock = FALSE;
    }
        
    list buttons = [];
    //buttons = buttons + menuButtonActive("Asset", setAsset);
    buttons = buttons + menuButtonActive("Class", setClass);
    buttons = buttons + menuButtonActive("Threat", setThreat);
    buttons = buttons + menuButtonActive(RLV, setLock);
    //buttons = buttons + menuButtonActive("Timer", setTimer);
    buttons = buttons + menuButtonActive("Punishment", setPunishments);
    buttons = buttons + menuButtonActive("Mood", setMood);
    buttons = buttons + menuButtonActive(buttonSpeech, setSpeech);
    buttons = buttons + menuButtonActive(menuCheckbox(buttonTitler, titlerActive), setTitle);
    buttons = buttons + menuButtonActive(menuCheckbox(buttonBattery, batteryActive), setBattery);
    buttons = buttons + menuButtonActive(buttonCharacter, setCharacter);
    
    setUpMenu(buttonSettings, avatarKey, message, buttons);
}
doSettingsMenu(key avatarKey, string message, string messageButtonsTrimmed) {
    sayDebug("doSettingsMenu("+message+")");

    if (message == "Mood"){
        moodMenu(avatarKey);
    }
    else if (message == RLV){
        if (rlvPresent) {
            sendJSON("menu", RLV, avatarKey);
        } else {
            // get RLV to check RLV again 
            llOwnerSay("RLV was off nor not detected. Attempting to register with RLV.");
            sendJSON(RLV, "Register", avatarKey);
        }
    }
    else if (message == "Class"){
        classMenu(avatarKey);
    }
    else if (message == "Threat"){
        threatMenu(avatarKey);
    }
    else if (message == "Punishment"){
        PunishmentLevelMenu(avatarKey);
    }
    //else if (message == "Asset"){
    //    assetMenu(avatarKey);
    //}
    //else if (message == "Timer"){
    //    llMessageLinked(LINK_THIS, 3000, "TIMER MODE", avatarKey);
    //}
    else if (message == buttonSpeech){
        speechMenu(avatarKey);
    }
    else if (messageButtonsTrimmed == buttonTitler) {
        titlerActive = !titlerActive;
        sendJSONCheckbox(buttonTitler, "", avatarKey, titlerActive);
        settingsMenu(avatarKey);
    }
    else if (messageButtonsTrimmed == buttonBattery) {
        batteryActive = !batteryActive;
        sendJSONCheckbox(buttonBattery, "", avatarKey, batteryActive);
        settingsMenu(avatarKey);
    }
    else if (message == buttonCharacter){
        characterMenu(avatarKey);
    }
            
}

PunishmentLevelMenu(key avatarKey)
{
    // the zap Level Menu always includes checkboxes in front of the Zap word. 
    // This is not a maximum zap radio button, it is checkboxes. 
    // An inmate could be set to most severe zap setting only. 
    string message = "Set Permissible Zap Levels";
    list buttons = [];
    buttons = buttons + menuCheckbox("Zap Low", allowZapLow);
    buttons = buttons + menuCheckbox("Zap Med", allowZapMed);
    buttons = buttons + menuCheckbox("Zap High", allowZapHigh);
    //buttons = buttons + menuCheckbox("Vision", allowVision);
    buttons = buttons + buttonSettings;
    setUpMenu("Punishments", avatarKey, message, buttons);
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
        if (!(allowZapLow & allowZapMed & allowZapHigh)) {
            allowZapHigh = TRUE;
        }
        string zapJsonList = llList2Json(JSON_ARRAY, [allowZapLow, allowZapMed, allowZapHigh]);
        sendJSON("ZapLevels", zapJsonList, avatarKey);
        sendJSONinteger("allowVision", allowVision, avatarKey);
    }
}

classMenu(key avatarKey)
{
    sayDebug("classMenu");
    string message = "Set your Prisoner Class";
    list buttons = [];
    integer index = 0;
    integer length = llGetListLength(classes);
    for (index = 0; index < length; index++) {
        string thisClass = llList2String(classes, index);
        buttons = buttons + menuRadioButton(thisClass, class);
    }
    buttons = buttons + [buttonBlank, buttonBlank, buttonSettings];
    setUpMenu("Class", avatarKey, message, buttons);
}

moodMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "Set your Mood";
        list buttons = [];
        buttons = buttons + menuRadioButton(moodDND, mood);
        buttons = buttons + menuRadioButton(moodOOC, mood);
        buttons = buttons + menuRadioButton(moodLockup, mood);
        buttons = buttons + menuRadioButton(moodSubmissive, mood);
        buttons = buttons + menuRadioButton(moodVersatile, mood);
        buttons = buttons + menuRadioButton(moodDominant, mood);
        buttons = buttons + menuRadioButton(moodNonsexual, mood);
        buttons = buttons + menuRadioButton(moodStory, mood);
        buttons = buttons + [buttonBlank, buttonSettings];
        setUpMenu("Mood", avatarKey, message, buttons);
    }
    else
    {
        ; // no one else gets a thing
    }
}

threatMenu(key avatarKey) {
    string message = "Threat";
    list buttons = [];
    buttons = buttons + menuRadioButton("None", threat);
    buttons = buttons + menuRadioButton("Moderate", threat);
    buttons = buttons + menuRadioButton("Dangerous", threat);
    buttons = buttons + menuRadioButton("Extreme", threat);
    buttons = buttons + [buttonBlank, buttonBlank, buttonSettings];
    setUpMenu("Threat", avatarKey, message, buttons);
}

speechMenu(key avatarKey)
{
    integer itsMe = avatarKey == llGetOwner();
    integer locked = lockLevel != lockLevelOff;
    
    string message = buttonSpeech + "\n";
    list buttons = [];
    
    // assume we can do nothing
    integer doRenamer = FALSE;
    //integer doGag = TRUE;
    integer doBadWords = FALSE;
    integer doWordList = FALSE;
    integer doDisplayTok = FALSE;
    integer doPenalties = FALSE;
    
    // work out what menu items are available
    if (rlvPresent) {
        if (itsMe) {
            doRenamer = TRUE;
            doWordList = TRUE;
            doPenalties = TRUE;
            if (renamerActive) {
                doBadWords = TRUE;
                doDisplayTok = TRUE;
            } else {
                message = message + "\BadWords and Displaytok (Display-Talk) work only when Renamer is active.";
            }
        } else {
            message = message + "\Only the prisoner may access some functions.";
        }
    } else {
        message = message + "\nRenamer, BadWords, and Displaytok (Display-Talk) work only when RLV is active.";
    }
    if (itsMe) {
        if (mood == moodOOC) {
            doWordList = TRUE;
        } else {
            message = message + "\nYou can only change your word list while OOC.";
        }
    } else {
        if(agentIsGuard(avatarKey))
        {
            doWordList = TRUE;
            if ((lockLevel == "Hardcore" || lockLevel == "Heavy")) {
                doBadWords = TRUE;
                doDisplayTok = TRUE;
                doPenalties = TRUE;
            } else {
                message = message + "\nGuards can set speech options only in Heavy or Hardcore mode.";
            }
        }
        else
        {
            message = message + "\nOnly Guards can change the word list";
        }

    }
    
    if (lockLevel == "Heavy" | lockLevel == "Hardcore") {
        doRenamer = FALSE;
    }
    
    buttons = buttons + menuButtonActive(menuCheckbox("Renamer", renamerActive), doRenamer);
    buttons = buttons + menuButtonActive(menuCheckbox("BadWords", badWordsActive), doBadWords);
    buttons = buttons + menuButtonActive(menuCheckbox("DisplayTok", DisplayTokActive), doDisplayTok);
    buttons = buttons + menuButtonActive("WordList", doWordList);
    buttons = buttons + menuButtonActive("Penalties", doPenalties);
    buttons = buttons + [buttonBlank, buttonSettings];
    
    setUpMenu(buttonSpeech, avatarKey, message, buttons);
}
doSpeechMenu(key avatarKey, string message, string messageButtonsTrimmed) 
{
    if (messageButtonsTrimmed == "Renamer") {
        renamerActive = !renamerActive;
        sendJSONCheckbox(buttonSpeech, "Renamer", avatarKey, renamerActive);
        speechMenu(avatarKey);
    } else if (message == "WordList") {
        sendJSON(buttonSpeech,"WordList", avatarKey);
    } else if (messageButtonsTrimmed == "BadWords") {
        badWordsActive = !badWordsActive;
        sendJSONCheckbox(buttonSpeech, "BadWords", avatarKey, badWordsActive);
        speechMenu(avatarKey);
    } else if (messageButtonsTrimmed == "DisplayTok") {
        DisplayTokActive = !DisplayTokActive;
        sendJSONCheckbox(buttonSpeech, "DisplayTok", avatarKey, DisplayTokActive);
        speechMenu(avatarKey);
    } else if (message == "Penalties") {
        PenaltyMenu(avatarKey);
    } else {
        speechMenu(avatarKey);
    }
}

characterMenu(key avatarKey) {
    // tell database to give the character menu and choose the character stuff. 
    sendJSON("database", "setcharacter", avatarKey);
}

PenaltyMenu(key avatarKey) {
    string message = "Set the penalties for speaking bad words:";
    list buttons = [];
    buttons = buttons + menuCheckbox("Buzz", speechPenaltyBuzz);
    buttons = buttons + menuCheckbox("Zap", speechPenaltyZap);
    buttons = buttons + [buttonBlank, buttonSpeech];
    setUpMenu(buttonPenalties, avatarKey, message, buttons);
}

doPenaltyMenu(key avatarKey, string message, string messageButtonsTrimmed) {
    if (messageButtonsTrimmed == "Buzz") {
        speechPenaltyBuzz = !speechPenaltyBuzz;
        sendJSONCheckbox(buttonPenalties, "Buzz", avatarKey, speechPenaltyBuzz);
        PenaltyMenu(avatarKey);
    } else if (messageButtonsTrimmed == "Zap") {
        speechPenaltyZap = !speechPenaltyZap;
        sendJSONCheckbox(buttonPenalties, "Zap", avatarKey, speechPenaltyZap);
        PenaltyMenu(avatarKey);
    } else if (messageButtonsTrimmed == buttonSpeech) {
        speechMenu(avatarKey);
    }
}

default
{
    state_entry() // reset
    {
        sayDebug("state_entry");
        menuAgentKey = "";
        mood = moodOOC;
        lockLevel = lockLevelOff; 
        renamerActive = FALSE;  
    }

    listen( integer channel, string name, key avatarKey, string message )
    {
        sayDebug("listen name:"+name+" message:"+message);

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

        if(message == menuMain)
        {
            sendJSON("menu", menuMain, avatarKey);
        }
        else if(message == buttonSettings)
        {
            settingsMenu(avatarKey);
        }
        //Settings
        else if (menuIdentifier == buttonSettings){
            sayDebug("listen: Settings:"+message);
            doSettingsMenu(avatarKey, message, messageButtonsTrimmed);
        }
        //Speech
        else if (menuIdentifier == buttonSpeech){
            sayDebug("listen: Speech:"+message);
            doSpeechMenu(avatarKey, message, messageButtonsTrimmed);
        }
        //Speech Penalties
        else if (menuIdentifier == "Penalties"){
            sayDebug("listen: Speech Penalties:"+message);
            doPenaltyMenu(avatarKey, message, messageButtonsTrimmed);
        }
        // Class
        else if (menuIdentifier == "Class") {
            sayDebug("listen: Class:"+messageButtonsTrimmed);
            class = messageButtonsTrimmed;
            sendJSON("class", class, avatarKey);
            settingsMenu(avatarKey);
        }
        // Mood
        else if (menuIdentifier == "Mood") {
            sayDebug("listen: Mood:"+messageButtonsTrimmed);
            mood = messageButtonsTrimmed;
            sendJSON("mood", mood, avatarKey);
            settingsMenu(avatarKey);
        }
        // Set Zap Level
        else if (menuIdentifier == "Punishments") {
            sayDebug("listen: Set Zap:"+message);
            if (message == buttonSettings) {
                settingsMenu(avatarKey);
            } else {
                doSetPunishmentLevels(avatarKey, messageButtonsTrimmed);
                PunishmentLevelMenu(avatarKey);
            }
        }
        // Threat Level
        else if (menuIdentifier == "Threat") {
            sayDebug("listen: threat:"+messageButtonsTrimmed);
            threat = messageButtonsTrimmed;
            sendJSON("threat", threat, avatarKey);
            settingsMenu(avatarKey);
        }
        else {
            sayDebug("ERROR: did not process menuIdentifier "+menuIdentifier);
        }
    }

    link_message(integer sender_num, integer num, string json, key avatarKey){ 
        // We listen in on link status messages and pick the ones we're interested in
        //sayDebug("link_message json "+json);
        assetNumber = getJSONstring(json, "assetNumber", assetNumber);
        crime = getJSONstring(json, "crime", crime);
        class = getJSONstring(json, "class", class);
        threat = getJSONstring(json, "threat", threat);
        mood = getJSONstring(json, "mood", mood);
        lockLevel = getJSONstring(json, "lockLevel", lockLevel);
        renamerActive = getJSONinteger(json, "renamerActive", renamerActive);
        badWordsActive = getJSONinteger(json, "badWordsActive", badWordsActive);
        DisplayTokActive = getJSONinteger(json, "DisplayTokActive", DisplayTokActive);
        rlvPresent = getJSONinteger(json, "rlvPresent", rlvPresent);
        if (!rlvPresent) {
            renamerActive = FALSE;
            badWordsActive = FALSE;
            DisplayTokActive = FALSE;
        }
        if ((lockLevel == "Hardcore" || lockLevel == "Heavy")) {
            batteryActive = TRUE;
        }

        if(getJSONstring(json, "menu", "") == buttonSettings)
        {
            menuIdentifier = buttonSettings;
            settingsMenu(avatarKey);
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