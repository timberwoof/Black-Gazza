// Menu.lsl
// Menu script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019
string version = "2021-02-27";

// Handles all the menus for the collar. 
// State is kept here and transmitted to interested scripts by link message calls. 

// reference: useful unicode characters
// https://unicode-search.net/unicode-namesearch.pl?term=CIRCLE

integer OPTION_DEBUG = 0;

//key sWelcomeGroup="49b2eab0-67e6-4d07-8df1-21d3e03069d0";
//key sMainGroup="ce9356ec-47b1-5690-d759-04d8c8921476";
//key sGuardGroup="b3947eb2-4151-bd6d-8c63-da967677bc69";
//key sBlackGazzaRPStaff="900e67b1-5c64-7eb2-bdef-bc8c04582122";
//key sOfficers="dd7ff140-9039-9116-4801-1f378af1a002";

integer menuChannel = 0;
integer menuListen = 0;
string menuIdentifier;
key menuAgentKey;

integer wearerChannel = 1;
integer wearerListen = 0;
string menuPhrase;

// Punishments
integer allowZapLow = 1;
integer allowZapMed = 1;
integer allowZapHigh = 1;
integer allowVision = 1;

list assetNumbers;
string prisonerMood;
string prisonerClass = "white";
list prisonerClasses = ["white", "pink", "red", "orange", "green", "blue", "black"];
list prisonerClassesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental"];
string prisonerLockLevel;
list LockLevels = ["Off", "Light", "Medium", "Heavy", "Hardcore"];
string lockLevelOff = "Off";
integer rlvPresent = 0;
integer renamerActive = 0;
integer DisplayTokActive = 0;
string RelayLockState = "Relay Off";
string RelayOFF = "Relay Off";
string RelayASK = "Relay Ask";
string RelayON = "Relay On";

integer speechPenaltyDisplay = 0;
integer speechPenaltyGarbleWord = 0;
integer speechPenaltyGarbleTime = 0;
integer speechPenaltyBuzz = 0;
integer speechPenaltyZap = 0;

string prisonerCrime = "Unknown";
string assetNumber = "P-00000";
string prisonerThreat = "Moderate";
integer batteryCharge = 100;
string batteryGraph = "";
integer badWordsActive = 0;
integer titlerActive = TRUE;

key approveAvatar;

integer LinkBlinky = 17;
integer FaceBlinky1 = 1;
integer FaceBlinky2 = 2;
integer FaceBlinky3 = 3;
integer FaceBlinky4 = 4;
integer batteryIconFace = 0;
integer batteryCoverLink = 1;
integer batteryCoverFace = 6;

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
string buttonInfo = "Info";
string buttonSettings = "Settings";
//string buttonHack = "Hack";
string buttonPunish = "Punish";
string buttonLeash = "Leash";
string buttonSpeech = "Speech";
string buttonPenalties = "Penalties";
string buttonForceSit = "ForceSit";
string buttonSafeword = "Safeword";
string buttonRelease = "Release";
string buttonTitler = "Titler";

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
        button = "["+title+"]";//"⦻";
    }
    return [button];
}

list blankRow(list buttons){
// fill out the row with blank buttons
    list blanks = [];
    integer numblanks = (3 - llGetListLength(buttons) % 3) % 3;
    integer i;
    for (i = 0; i < numblanks; i++) {
        blanks = blanks + buttonBlank;
    }
    return blanks;
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

mainMenu(key avatarKey) {
    string message = menuMain + "\n";

    if (assetNumber == "P-00000") {
        sendJSON("database", "getupdate", avatarKey);
    }
    
    if (menuAgentKey != "" & menuAgentKey != avatarKey) {
        llInstantMessage(avatarKey, "The collar menu is being accessed by someone else.");
        sayDebug("Told " + llKey2Name(avatarKey) + "that the collar menu is being accessed by someone else.");
        return;
        }
    
    // assume some things are not available
    integer doPunish = 0;
    integer doForceSit = 0;
    integer doLeash = 0;
    integer doSpeech = 0;
    integer doSafeword = 0;
    integer doRelease = 0;
    
    // Collar functions controlled by Mood: punish, force sit, leash, speech
    if (prisonerMood == moodDND | prisonerMood == moodLockup) {
        if (avatarKey == llGetOwner()) {
            doPunish = 1;
            doForceSit = 1;
            doLeash = 1;
            doSpeech = 1;
        }
    } else if (prisonerMood == moodOOC) {
            // everyone can do everything (but you better ask)
            doPunish = 1;
            doForceSit = 1;
            doLeash = 1;
            doSpeech = 1;
    } else { // prisonerMood == anything else
        if (avatarKey == llGetOwner()) {
            // wearer can't do anything
        } else if (llSameGroup(avatarKey)) {
            // other prisoners can leash and force sit
            doForceSit = 1;
            doLeash = 1;
        } else {
            // Guards can do anything
            doPunish = 1;
            doForceSit = 1;
            doLeash = 1;
            doSpeech = 1;
        }
    }
    
    // Collar functions overridden by lack of RLV
    if (!rlvPresent) {
        doForceSit = 0;
        doLeash = 0;
        doSpeech = 0;
        message = message + "\nSome functions are available ony when RLV is present.";
    }
    
    // Collar functions controlled by locklevel: Safeword and Release
    if (prisonerLockLevel == "Hardcore" && !llSameGroup(avatarKey)) {
        doRelease = 1;
    } else {
        message = message + "\nRelease command is available to a Guard when prisoner is in RLV Hardcore mode.";
    }
    
    if (avatarKey == llGetOwner() && prisonerLockLevel != "Hardcore" && prisonerLockLevel != lockLevelOff) {
        doSafeword = 1;
    } else {
        message = message + "\nSafeword is availavle to the Prisoner in RLV levels Medium and Heavy.";
    }
    
    list buttons = [];
    buttons = buttons + menuButtonActive(buttonSafeword, doSafeword);
    buttons = buttons + menuButtonActive(buttonRelease, doRelease);
    buttons = buttons + buttonBlank;    
    buttons = buttons + menuButtonActive(buttonPunish, doPunish);
    buttons = buttons + menuButtonActive(buttonLeash, doLeash);
    buttons = buttons + menuButtonActive(buttonForceSit, doForceSit);
    buttons = buttons + buttonSettings; 
    buttons = buttons + buttonInfo;
    
    setUpMenu(menuMain, avatarKey, message, buttons);
}

doMainMenu(key avatarKey, string message) {
        sendJSON("RLV", "Status", avatarKey);
        if (message == buttonInfo){
            infoGive(avatarKey);
        }
        else if (message == buttonSettings){
            settingsMenu(avatarKey);
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
        else if (message == buttonSpeech){
            speechMenu(avatarKey);
        }
        else if (message == buttonSafeword){
            sendJSON("RLV", buttonSafeword, avatarKey);
        }
        else if (message == buttonRelease){
            sendJSON("RLV", lockLevelOff, avatarKey);
        }
    }

// Action Menus and Handlers **************************
// Top-level menu items for immediate use in roleplay:
// Zap, Leash, Info, Hack, Safeword, Settings

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
    return llList2String(prisonerClasses, llListFindList(prisonerClasses, [class])) + ": " +
        llList2String(prisonerClassesLong, llListFindList(prisonerClasses, [class]));
}

infoGive(key avatarKey){
    // Prepare text of collar settings for the information menu
    string message = "Prisoner Information \n" +
    "\nNumber: " + assetNumber + "\n";
    if (!llSameGroup(avatarKey) || avatarKey == llGetOwner()) {
        string ZapLevels = "";
        ZapLevels = menuCheckbox("Low", allowZapLow) + "  " +
        menuCheckbox("Medium", allowZapMed) +  "  " +
        menuCheckbox("High", allowZapHigh);
        // allowVision
        message = message + 
        "Crime: " + prisonerCrime + "\n" +
        "Class: "+class2Description(prisonerClass)+"\n" +
        "Threat: " + prisonerThreat + "\n" +
        "Punishment: shock " + ZapLevels + "\n"; 
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
    message = message + "Mood: " + prisonerMood + "\n";
    if (rlvPresent) {
        message = message + "RLV Active: " + prisonerLockLevel + "\n";
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

    buttons = buttons + blankRow(buttons);    
    
    message = llGetSubString(message, 0, 511);
    setUpMenu(buttonInfo, avatarKey, message, buttons);
}

//hackMenu(key avatarKey)
//{
//    string message = "Hack";
//    list buttons = ["Maintenance", "Fix", "hack"];
//    setUpMenu("Hack", avatarKey, message, buttons);
//}
//
//doHackMenu(key avatarKey, string message, string messageButtonsTrimmed) {
//    if (messageButtonsTrimmed == "Maintenance") {
//    } else if (messageButtonsTrimmed == "Fix") {
//    } else if (messageButtonsTrimmed == "hack") {
//    }
//}

speechMenu(key avatarKey)
{
    integer itsMe = avatarKey == llGetOwner();
    integer locked = prisonerLockLevel != lockLevelOff;
    
    string message = buttonSpeech + "\n";
    list buttons = [];
    
    // assume we can do nothing
    integer doRenamer = 0;
    //integer doGag = 1;
    integer doBadWords = 0;
    integer doWordList = 0;
    integer doDisplayTok = 0;
    integer doPenalties = 0;
    
    // work out what menu items are available
    if (rlvPresent) {
        if (itsMe) {
            doRenamer = 1;
            doWordList = 1;
            doPenalties = 1;
            if (renamerActive) {
                doBadWords = 1;
                doDisplayTok = 1;
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
        if (prisonerMood == moodOOC) {
            doWordList = 1;
        } else {
            message = message + "\nYou can only change your word list while OOC.";
        }
    } else {
        if (llSameGroup(avatarKey)) {
            message = message + "\nOnly Guards can change the word list";
        } else {
            doWordList = 1;
            if ((prisonerLockLevel == "Hardcore" || prisonerLockLevel == "Heavy")) {
                doBadWords = 1;
                doDisplayTok = 1;
                doPenalties = 1;
            } else {
                message = message + "\nGuards can set speech options only in Heavy or Hardcore mode.";
            }
        }
    }
    
    if (prisonerLockLevel == "Heavy" | prisonerLockLevel == "Hardcore") {
        doRenamer = 0;
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
    } else if (message == "Lock") {
        lockMenu(avatarKey);
    } else {
        speechMenu(avatarKey);
    }
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




// Settings Menus and Handlers ************************
// Sets Collar State: Mood, Threat, Lock, Zap levels 

settingsMenu(key avatarKey) {
    // What this menu can present depends on a number of things: 
    // who you are - self or guard
    // IC/OOC mood - OOC, DnD or other
    // RLV lock level - Off, Light, Medium, Heavy, Lardcore
    
    string message = buttonSettings;

    // 1. Assume nothing is allowed
    integer setClass = 0;
    integer setMood = 0;
    integer setThreat = 0;
    integer setLock = 0;
    integer setPunishments = 0;
    //integer setTimer = 0;
    //integer setAsset = 0;
    integer setBadWords = 0;
    integer setSpeech = 0;
    integer setTitle = 0;
    
    // Add some things depending on who you are. 
    // What wearer can change
    if (avatarKey == llGetOwner()) {
        // some things you can always cange
        sayDebug("settingsMenu: wearer");
        setMood = 1;
        setLock = 1;
        setSpeech = 1;
        //setTimer = 1;
        setTitle = 1;
        
        // Some things you can only change OOC
        if ((prisonerMood == moodOOC) || (prisonerMood == moodDND)) {
            sayDebug("settingsMenu: ooc");
            // IC or DnD you change everything
            setClass = 1;
            setThreat = 1;
            setPunishments = 1;
            //setAsset = 1;
            setBadWords = 1;
        }
        else {
            message = message + "\nSome settings are not available while you are IC.";
        }
    }
    // What a guard can change
    else { // (avatarKey != llGetOwner())
        // guard can always set some things
        sayDebug("settingsMenu: guard");
        setThreat = 1;
        setSpeech = 1;
        
        // some things guard can change only OOC
        if (prisonerMood == moodOOC) {
            sayDebug("settingsMenu: ooc");
            // OOC, guards can change some things
            // DnD means Do Not Disturb
            setClass = 1;
        }
        else {
            message = message + "\nSome settings are not available while you are OOC.";
        }
    }
    
    // Lock level changes some privileges
    if ((prisonerLockLevel == "Hardcore" || prisonerLockLevel == "Heavy")) {
        if (avatarKey == llGetOwner()) {
            sayDebug("settingsMenu: heavy-owner");
            setPunishments = 0;
            setThreat = 0;
            //setTimer = 0;
            setSpeech = 0;
            message = message + "\nSome settings are not available while your lock level is Heavy or Hardcore.";
        } else {
            if (!llSameGroup(avatarKey))
            {
                sayDebug("settingsMenu: heavy-guard");
                setPunishments = 1;
                setThreat = 1;
                //setTimer = 1;
            }
        }
    }

    if ((prisonerLockLevel == "Hardcore") && (avatarKey == llGetOwner())) {
        setLock = 0;
    }
        
    list buttons = [];
    //buttons = buttons + menuButtonActive("Asset", setAsset);
    buttons = buttons + menuButtonActive("Class", setClass);
    buttons = buttons + menuButtonActive("Threat", setThreat);
    buttons = buttons + menuButtonActive("Lock", setLock);
    //buttons = buttons + menuButtonActive("Timer", setTimer);
    buttons = buttons + menuButtonActive("Punishment", setPunishments);
    buttons = buttons + menuButtonActive("Mood", setMood);
    buttons = buttons + menuButtonActive(buttonSpeech, setSpeech);
    buttons = buttons + menuButtonActive(menuCheckbox(buttonTitler, titlerActive), setTitle);
    
    setUpMenu(buttonSettings, avatarKey, message, buttons);
}
    
doSettingsMenu(key avatarKey, string message, string messageButtonsTrimmed) {
    sayDebug("doSettingsMenu("+message+")");
        if (message == "Mood"){
            moodMenu(avatarKey);
        }
        else if (message == "Lock"){
            if (rlvPresent) {
                lockMenu(avatarKey);
            } else {
                // get RLV to check RLV again 
                llOwnerSay("RLV was off nor not detected. Attempting to register with RLV.");
                sendJSON("RLV", "Register", avatarKey);
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
        else if (messageButtonsTrimmed = buttonTitler) {
            titlerActive = !titlerActive;
            sendJSONCheckbox(buttonTitler, "", avatarKey, titlerActive);
            settingsMenu(avatarKey);
        }
            
}

//assetMenu(key avatarKey)
//{
//    string message = "Choose which Asset Number your collar will show.";
//    setUpMenu("Asset", avatarKey, message, assetNumbers);
//}

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
            allowZapLow = 1;
            allowZapMed = 1;
            allowZapHigh = 1;
            allowVision = 1;
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
        if (allowZapLow + allowZapMed + allowZapHigh == 0) {
            allowZapHigh = 1;
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
    integer length = llGetListLength(prisonerClasses);
    for (index = 0; index < length; index++) {
        string class = llList2String(prisonerClasses, index);
        buttons = buttons + menuRadioButton(class, prisonerClass);
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
        buttons = buttons + menuRadioButton(moodDND, prisonerMood);
        buttons = buttons + menuRadioButton(moodOOC, prisonerMood);
        buttons = buttons + menuRadioButton(moodLockup, prisonerMood);
        buttons = buttons + menuRadioButton(moodSubmissive, prisonerMood);
        buttons = buttons + menuRadioButton(moodVersatile, prisonerMood);
        buttons = buttons + menuRadioButton(moodDominant, prisonerMood);
        buttons = buttons + menuRadioButton(moodNonsexual, prisonerMood);
        buttons = buttons + menuRadioButton(moodStory, prisonerMood);
        buttons = buttons + [buttonBlank, buttonSettings];
        setUpMenu("Mood", avatarKey, message, buttons);
    }
    else
    {
        ; // no one else gets a thing
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
            "• Hardcore has no safeword. To be released, you must ask a Guard.";
            
        // LockLevels: 0=Off 1=Light 2=Medium 3=Heavy 4=Hardcore
        // convert our locklevel to an integer
        sayDebug("lockMenu prisonerLockLevel:"+prisonerLockLevel);
        integer iLockLevel = llListFindList(LockLevels, [prisonerLockLevel]);
        sayDebug("lockMenu iLocklevel:"+(string)iLockLevel);
        // make a list of wjether each lock level is available from that lock level
        // prisonerLockLevel: 0=off, 1=light, 2=medium, 3=heavy, 4=hardcore
        list lockListOff = [0, 1, 1, 1, 0];
        list lockListLight = [1, 0, 1, 1, 0];
        list lockListMedium = [1, 1, 0, 1, 0];
        list lockListHeavy = [0, 0, 0, 0, 1];
        list lockListHardcore = [0, 0, 0, 0, 0];
        list lockLists = lockListOff + lockListLight + lockListMedium + lockListHeavy + lockListHardcore; // strided list
        list lockListMenu = llList2List(lockLists, iLockLevel*5, (iLockLevel+1)*5); // list of lock levels to add to menu
        sayDebug("lockMenu lockListMenu:"+(string)lockListMenu); 
                
        //make the button list
        list buttons = [];
        string allTheButtons = "";
        integer levelIndex;
        for (levelIndex = 0; levelIndex < 5; levelIndex++) {
            integer buttonActive =  llList2Integer(lockListMenu, levelIndex);
            string buttonText = llList2String(LockLevels, levelIndex);
            string radioButton = llList2String(menuRadioButton(buttonText, prisonerLockLevel), 0);
            buttons = buttons + menuButtonActive(radioButton, buttonActive);
            if (buttonActive) {
                allTheButtons = allTheButtons + buttonText;
            }
        }
        buttons = buttons + blankRow(buttons);    

        // Relay Buttons
        buttons = buttons + menuRadioButton(RelayOFF, RelayLockState);
        buttons = buttons + menuRadioButton(RelayASK, RelayLockState);
        buttons = buttons + menuRadioButton(RelayON, RelayLockState);

        // Settings button. 
        buttons = buttons + [buttonSettings];
        
        setUpMenu("Lock", avatarKey, message, buttons);
    }
}

doLockMenu(key avatarKey, string message, string messageButtonsTrimmed) {
            if (message == "○ Hardcore") {
                confirmHardcore(avatarKey);
            } else if (message == "⨷ Hardcore") {
                sayDebug("listen set prisonerLockLevel:\""+prisonerLockLevel+"\"");
                sendJSON("RLV", "Hardcore", avatarKey);
            } else if (llSubStringIndex(message, RelayOFF) >= 0) {
                llMessageLinked(LINK_THIS, 0, "relay-reset", avatarKey);
                RelayLockState = RelayOFF;
            } else if (llSubStringIndex(message, RelayASK) >= 0) {
                llMessageLinked(LINK_THIS, 1, "relay-ask", avatarKey);
                RelayLockState = RelayASK;
            } else if (llSubStringIndex(message, RelayON) >= 0) {
                llMessageLinked(LINK_THIS, 0, "relay-ask", avatarKey);
                RelayLockState = RelayON;
            } else {
                sayDebug("listen set prisonerLockLevel:\""+prisonerLockLevel+"\"");
                sendJSON("RLV", messageButtonsTrimmed, avatarKey);
                if (messageButtonsTrimmed == "Heavy" && !renamerActive) {
                    sayDebug("listen prisonerLockLevel Heavy, so turn on renamer");
                    renamerActive = 1;
                    sendJSONCheckbox(buttonSpeech, "Renamer", avatarKey, renamerActive);
                    }
                settingsMenu(avatarKey);
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
        setUpMenu("Lock", avatarKey, message, buttons);
    }
}

threatMenu(key avatarKey) {
    string message = "Threat";
    list buttons = [];
    buttons = buttons + menuRadioButton("None", prisonerThreat);
    buttons = buttons + menuRadioButton("Moderate", prisonerThreat);
    buttons = buttons + menuRadioButton("Dangerous", prisonerThreat);
    buttons = buttons + menuRadioButton("Extreme", prisonerThreat);
    buttons = buttons + [buttonBlank, buttonBlank, buttonSettings];
    setUpMenu("Threat", avatarKey, message, buttons);
}

attachStartup() {
    sayDebug("attachStartup");
    // set up chanel 1 menu command
    string canonicalName = llToLower(llKey2Name(llGetOwner()));
    list canoncialList = llParseString2List(llToLower(canonicalName), [" "], []);
    string initials = llGetSubString(llList2String(canoncialList,0),0,0) + llGetSubString(llList2String(canoncialList,1),0,0);
    menuPhrase = initials + "menu";
    llOwnerSay("Access the collar menu by typing /1"+menuPhrase);
    wearerListen = llListen(wearerChannel, "", "", menuPhrase);
}

// Event Handlers ***************************

default
{
    state_entry() // reset
    {
        sayDebug("state_entry");
        menuAgentKey = "";
        prisonerMood = moodOOC;
        prisonerLockLevel = lockLevelOff; 
        renamerActive = 0;       
        LinkBlinky = getLinkWithName("BG_CollarV4_LightsMesh");

        // Initialize Unworn
        if (llGetAttached() == 0) {
            sendJSON("assetNumber", "P-00000", "");
            sendJSON("prisonerClass", "white", "");
            sendJSON("prisonerCrime", "unknown", "");
            sendJSON("prisonerThreat", "None", "");
            sendJSON("prisonerMood", moodOOC, "");            
            doSetPunishmentLevels(llGetOwner(),""); // initialize
        } else {
            attachStartup();
        }
        sayDebug("state_entry done");
    }
    
    attach(key avatar) {
        sayDebug("attach");
        attachStartup();
        sayDebug("attach done");
    }

    touch_start(integer total_number)
    {
        key whoClicked  = llDetectedKey(0);
        integer touchedLink = llDetectedLinkNumber(0);
        integer touchedFace = llDetectedTouchFace(0);
        vector touchedUV = llDetectedTouchUV(0);
        sayDebug("Link "+(string)touchedLink+", Face "+(string)touchedFace+", UV "+(string)touchedUV);
        
        if (touchedLink == LinkBlinky) {
            if (touchedFace == FaceBlinky1) {// Prepare text of collar settings for the information menu
                string ZapLevels = "";
                ZapLevels = menuCheckbox("Low", allowZapLow) + "  " +
                menuCheckbox("Medium", allowZapMed) +  "  " +
                menuCheckbox("High", allowZapHigh);
                llInstantMessage(whoClicked, assetNumber+" Zap: "+ZapLevels);
                }
            else if (touchedFace == FaceBlinky2) {llInstantMessage(whoClicked, assetNumber+" Lock Level: "+prisonerLockLevel);}
            else if (touchedFace == FaceBlinky3) {llInstantMessage(whoClicked, assetNumber+" Class: "+class2Description(prisonerClass));}
            else if (touchedFace == FaceBlinky4) {llInstantMessage(whoClicked, assetNumber+" Threat: "+prisonerThreat);}
            else if (touchedFace == batteryIconFace) llInstantMessage(whoClicked, assetNumber+" Battery level: "+(string)batteryCharge+"%");
        } else if (touchedLink == batteryCoverLink) {
            if (touchedFace == batteryCoverFace) llInstantMessage(whoClicked, assetNumber+" Battery level: "+(string)batteryCharge+"%");
            mainMenu(whoClicked);
        } else {
            mainMenu(whoClicked);
        }
    }
    
    listen(integer channel, string name, key avatarKey, string message){
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
        
        string messageButtonsTrimmed = llStringTrim(llGetSubString(message,2,11), STRING_TRIM);
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

        // Asset
        //else if (menuIdentifier == "Asset") {
        //    sayDebug("listen: Asset:"+message);
        //    if (message != "OK") {
        //        assetNumber = message;
        //        // The wearer chose this asset number so transmit it and display it
        //        sendJSON("assetNumber", assetNumber, avatarKey);
        //        settingsMenu(avatarKey);
        //    }
        //}
        
        // Class
        else if (menuIdentifier == "Class") {
            sayDebug("listen: Class:"+messageButtonsTrimmed);
            prisonerClass = messageButtonsTrimmed;
            sendJSON("prisonerClass", prisonerClass, avatarKey);
            settingsMenu(avatarKey);
        }
        
        // Mood
        else if (menuIdentifier == "Mood") {
            sayDebug("listen: Mood:"+messageButtonsTrimmed);
            prisonerMood = messageButtonsTrimmed;
            sendJSON("prisonerMood", prisonerMood, avatarKey);
            settingsMenu(avatarKey);
        }
        
        // Hack
        //else if (menuIdentifier == buttonHack) {
        //    sayDebug("listen: Hack:"+messageButtonsTrimmed);
        //    doHackMenu(avatarKey, message, messageButtonsTrimmed);
        //}
        
        // Zap the inmate
        else if (menuIdentifier == buttonPunish) {
            sayDebug("listen: Zap:"+message);
            sendJSON("RLV", message, avatarKey);
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

        // Lock Level
        else if (menuIdentifier == "Lock") {
            sayDebug("listen Lock: message:"+message);
            doLockMenu(avatarKey, message, messageButtonsTrimmed);
        }

        // Threat Level
        else if (menuIdentifier == "Threat") {
            sayDebug("listen: prisonerThreat:"+messageButtonsTrimmed);
            prisonerThreat = messageButtonsTrimmed;
            sendJSON("prisonerThreat", prisonerThreat, avatarKey);
            settingsMenu(avatarKey);
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
        }
    }
    
    link_message(integer sender_num, integer num, string json, key avatarKey){ 
    // We listen in on link status messages and pick the ones we're interested in
        sayDebug("link_message json "+json);
        assetNumber = getJSONstring(json, "assetNumber", assetNumber);
        prisonerCrime = getJSONstring(json, "prisonerCrime", prisonerCrime);
        prisonerClass = getJSONstring(json, "prisonerClass", prisonerClass);
        prisonerThreat = getJSONstring(json, "prisonerThreat", prisonerThreat);
        prisonerMood = getJSONstring(json, "prisonerMood", prisonerMood);
        prisonerLockLevel = getJSONstring(json, "prisonerLockLevel", prisonerLockLevel);
        renamerActive = getJSONinteger(json, "renamerActive", renamerActive);
        badWordsActive = getJSONinteger(json, "badWordsActive", badWordsActive);
        DisplayTokActive = getJSONinteger(json, "DisplayTokActive", DisplayTokActive);
        batteryCharge = getJSONinteger(json, "batteryCharge", batteryCharge);
        batteryGraph = getJSONstring(json, "batteryGraph", batteryGraph);
        rlvPresent = getJSONinteger(json, "rlvPresent", rlvPresent);
        if (rlvPresent == 0) {
            renamerActive = 0;
            badWordsActive = 0;
            DisplayTokActive = 0;
        }
    }
    
    timer() 
    {
        // reset the menu setup
        llListenRemove(menuListen);
        menuListen = 0;   
        menuAgentKey = "";
    }
}
