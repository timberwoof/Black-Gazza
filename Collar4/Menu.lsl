// Menu.lsl
// Menu script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019
// version: 2020-03-14 JSONN

// Handles all the menus for the collar. 
// State is kept here and transmitted to interested scripts by link message calls. 

// reference: useful unicode characters
// https://unicode-search.net/unicode-namesearch.pl?term=CIRCLE

string version = "2020-03-08 JSON";
integer OPTION_DEBUG = 0;

key sWelcomeGroup="49b2eab0-67e6-4d07-8df1-21d3e03069d0";
key sMainGroup="ce9356ec-47b1-5690-d759-04d8c8921476";
key sGuardGroup="b3947eb2-4151-bd6d-8c63-da967677bc69";
key sBlackGazzaRPStaff="900e67b1-5c64-7eb2-bdef-bc8c04582122";
key sOfficers="dd7ff140-9039-9116-4801-1f378af1a002";

string touchTone0 = "ccefe784-13b0-e59e-b0aa-c818197fdc03";
string touchTone1 = "303afb6c-158f-aa6f-03fc-35bd42d8427d";
string touchTone2 = "c4499d5e-85df-0e8e-0c6f-2c7e101517b5";
string touchTone3 = "c3f88066-894e-7a3d-39b5-2619e8ae7e73";
string touchTone4 = "10748aa2-753f-89ad-2802-984dc6e3d530";
string touchTone5 = "2d9cf7a7-08e5-5687-6976-8d256b1dc84b";
string touchTone6 = "97a896a8-0677-8281-f4e3-ba21c8f88b64";
string touchTone7 = "01c5c969-daf1-6d7d-ade6-fd54dcb1aab5";
string touchTone8 = "dafc5c77-8c81-02f1-6d36-9602d306dc0d";
string touchTone9 = "d714bede-cfa3-7c33-3a7c-bcffd49534eb";
list touchTones;

integer menuChannel = 0;
integer menuListen = 0;
string menuIdentifier;
key menuAgentKey;

integer wearerChannel = 1;
integer wearerListen = 0;
string menuPhrase;

integer allowZapLow = 1;
integer allowZapMed = 1;
integer allowZapHigh = 1;

list assetNumbers;
string prisonerMood = "OOC";
string prisonerClass = "white";
list prisonerClasses = ["white", "pink", "red", "orange", "green", "blue", "black"];
list prisonerClassesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental"];
string prisonerLockLevel = "Off";
list LockLevels = ["Off", "Light", "Medium", "Heavy", "Hardcore"];
integer rlvPresent = 0;
integer renamerActive = 0;
integer gagActive = 0;
integer DisplayTokActive = 0;

string prisonerCrime = "Unknown";
string assetNumber = "Unknown";
string prisonerThreat = "Moderate";
string batteryLevel = "Unknown";
integer badWordsActive = 0;

key approveAvatar;

integer LinkBlinky = 17;
integer FaceBlinky1 = 1;
integer FaceBlinky2 = 2;
integer FaceBlinky3 = 3;
integer FaceBlinky4 = 4;
integer batteryIconLink = 16;
integer batteryIconFace = 0;
integer batteryCoverLink = 1;
integer batteryCoverFace = 6;

// Utilities *******

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Menu:"+message);
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

setUpMenu(string identifier, key avatarKey, string message, list buttons)
// wrapper to do all the calls that make a simple menu dialog.
{
    sayDebug("setUpMenu "+identifier);
    
    if (identifier != "Main") {
        buttons = buttons + ["Main"];
    }
    
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

// Menus and Handlers ****************

mainMenu(key avatarKey) {
    string message = "Main";

    if (assetNumber == "Unknown") {
        sendJSON("database", "getupdate", avatarKey);
    }
    
    if (menuAgentKey != "" & menuAgentKey != avatarKey) {
        llInstantMessage(avatarKey, "The collar menu is being accessed by someone else.");
        sayDebug("Told " + llKey2Name(avatarKey) + "that the collar menu is being accessed by someone else.");
        return;
        }
    
    // assume some things are not available
    integer doZap = 0;
    integer doSafeword = 0;
    integer doRelease = 0;
    
    // enable things based on state
    if (!llSameGroup(avatarKey) && (prisonerMood != "OOC") && (prisonerMood != "DnD")) {
        doZap = 1;
    }
    
    if (avatarKey == llGetOwner() && prisonerLockLevel != "Hardcore" && prisonerLockLevel != "Off") {
        doSafeword = 1;
    } else {
        message = message + "\nSafeword is only availavle to the Prisoner in RLV levels Medium and Heavy.";
    }
    
    if (prisonerLockLevel != "Off" && !llSameGroup(avatarKey)) {
        doRelease = 1;
    } else {
        message = message + "\nRelease is only availavle to a Guard while prisoner is in RLV Hardcore mode.";
    }
    
    list buttons = ["Info", "Settings", "Hack"];
    buttons = buttons + menuButtonActive("Zap", doZap);
    buttons = buttons + ["Leash", "Speech"];
    buttons = buttons + menuButtonActive("Safeword", doSafeword);
    buttons = buttons + menuButtonActive("Release", doRelease);
    setUpMenu("Main", avatarKey, message, buttons);
}

doMainMenu(key avatarKey, string message) {
        if (message == "Info"){
            infoGive(avatarKey);
        }
        else if (message == "Settings"){
            settingsMenu(avatarKey);
        }
        else if (message == "Hack"){
            hackMenu(avatarKey);
        }
        else if (message == "Zap"){
            zapMenu(avatarKey);
        }
        else if (message == "Leash"){
            sendJSON("Leash", "Leash", avatarKey);
        }
        else if (message == "Speech"){
            speechMenu(avatarKey);
        }
        else if (message == "Safeword"){
            sendJSON("RLV", "Safeword", avatarKey);
        }
        else if (message == "Release"){
            sendJSON("RLV", "Off", avatarKey);
        }
    }

// Action Menus and Handlers **************************
// Top-level menu items for immediate use in roleplay:
// Zap, Leash, Info, Hack, Safeword, Settings

zapMenu(key avatarKey)
{
    // the zap menu never includes radio buttons in front of the Zap word
    string message = "Zap";
    list buttons = [];
    buttons = buttons + menuButtonActive("Zap Low", allowZapLow);
    buttons = buttons + menuButtonActive("Zap Med", allowZapMed);
    buttons = buttons + menuButtonActive("Zap High", allowZapHigh);
    setUpMenu("Zap", avatarKey, message, buttons);
}

string class2Description(string class) {
    return llList2String(prisonerClasses, llListFindList(prisonerClasses, [class])) + ": " +
        llList2String(prisonerClassesLong, llListFindList(prisonerClasses, [class]));
}

string batteryGraph(string batteryLevel) {
    integer iBattery = (integer)batteryLevel / 10;
    integer i;
    string graph = "";
    for (i=0; i<iBattery; i++) {
        graph = graph + "◼";
    }
    for (; i<10; i++) {
        graph = graph + "◻";
    }
    return graph;
}

infoGive(key avatarKey){
    // Prepare text of collar settings for the information menu
    string message = "\n------------------\nPrisoner Information \n" +
    "Number: " + assetNumber + "\n";
    if (!llSameGroup(avatarKey) || avatarKey == llGetOwner()) {
        string ZapLevels = "";
        ZapLevels = menuCheckbox("Low", allowZapLow) + "  " +
        menuCheckbox("Medium", allowZapMed) +  "  " +
        menuCheckbox("High", allowZapHigh);
        message = message + 
        "Crime: " + prisonerCrime + "\n" +
        "Class: "+class2Description(prisonerClass)+"\n" +
        "Threat: " + prisonerThreat + "\n" +
        "Zap Levels: " + ZapLevels + "\n"; 
    } else {
        string restricted = "RESTRICTED INFO";
        message = message + 
        "Crime: " + restricted + "\n" +
        "Class: "+restricted+"\n" +
        "Threat: " + restricted + "\n" +
        "Zap Levels: " + restricted + "\n"; 
    }
    message = message + "Battery Level: " + batteryGraph(batteryLevel)+"\n";
    message = message + "------------------\nOOC Information:\n";
    message = message + "Version: " + version + "\n";
    message = message + "Mood: " + prisonerMood + "\n";
    if (rlvPresent) {
        message = message + "RLV Active: " + prisonerLockLevel + "\n";
    } else {
        message = message + "RLV not detected.\n";
    }
    
    // Prepare a list of documents to hand out 
    list buttons = []; 
    integer numNotecards = llGetInventoryNumber(INVENTORY_NOTECARD);
    if (numNotecards > 0) {
        message = message + "------------------\nChoose a Notecard:";
        integer index;
        for (index = 0; index < numNotecards; index++) {
            integer inumber = index+1;
            message += "\n" + (string)inumber + " - " + llGetInventoryName(INVENTORY_NOTECARD,index);
            buttons += ["Doc "+(string)inumber];
        }
    }
    setUpMenu("Info", avatarKey, message, buttons);
}

hackMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "Hack";
        list buttons = ["hack", "Maintenance", "Fix"];
        setUpMenu("Hack", avatarKey, message, buttons);
    }
    else
    {
        ;
    }
}

speechMenu(key avatarKey)
{
    integer itsMe = avatarKey == llGetOwner();
    integer locked = prisonerLockLevel != "Off";
    
    string message = "";
    list buttons = [];
    
    // assume we can do nothing
    integer doRenamer = 0;
    integer doGag = 0;
    integer doBadWords = 0;
    integer doWordList = 0;
    integer doDisplayTok = 0;
    
    // work out what menu items are available
    if (locked) {
        if (itsMe) {
            doRenamer = 1;
            doBadWords = renamerActive;
            doDisplayTok = renamerActive;
        }
        doGag = renamerActive;
    } else {
        message = message + "\nRenamer, Gag, BadWords, and Display only work when the collar is locked.";
    }
    if (itsMe) {
        if (prisonerMood == "OOC") {
            doWordList = 1;
        } else {
            message = message + "\nYou can only change your word list while OOC.";
        }
    } else {
        if (llSameGroup(avatarKey)) {
            message = message + "\nOnly Guards can change the word list";
        } else {
            doWordList = 1;
        }
    }
    
    buttons = buttons + menuButtonActive(menuCheckbox("Renamer", renamerActive), doRenamer);
    buttons = buttons + menuButtonActive(menuCheckbox("Gag", gagActive), doGag);
    buttons = buttons + menuButtonActive(menuCheckbox("BadWords", badWordsActive), doBadWords);
    buttons = buttons + menuButtonActive(menuCheckbox("DisplayTok", DisplayTokActive), doDisplayTok);
    buttons = buttons + menuButtonActive("WordList", doWordList);
    
    setUpMenu("Speech", avatarKey, message, buttons);
}

doSpeechMenu(key avatarKey, string message, string messageButtonsTrimmed) 
{
    if (messageButtonsTrimmed == "Renamer") {
        renamerActive = !renamerActive;
        if (renamerActive) {
            sendJSON("Speech", "RenamerON", avatarKey);
        } else {
            sendJSON("Speech", "RenamerOFF", avatarKey);
        }
        sayDebug("doSpeechMenu renamerActive:"+(string)renamerActive);
        speechMenu(avatarKey);
    } else if (message == "WordList") {
        sendJSON("Speech","WordList", avatarKey);
    } else if (messageButtonsTrimmed == "BadWords") {
        badWordsActive = !badWordsActive;
        if (badWordsActive) {
            sendJSON("Speech", "BadWordsON", avatarKey);
        } else {
            sendJSON("Speech", "BadWordsOFF", avatarKey);
        }
        sayDebug("doSpeechMenu badWordsActive:"+(string)badWordsActive);
        speechMenu(avatarKey);
    } else if (messageButtonsTrimmed == "Gag") {
        gagActive = !gagActive;
        if (gagActive) {
            sendJSON("Speech", "GagON", avatarKey);
        } else {
            sendJSON("Speech", "GagOFF", avatarKey);
        }
        sayDebug("doSpeechMenu gagActive:"+(string)gagActive);
        speechMenu(avatarKey);
    } else if (messageButtonsTrimmed == "DisplayTok") {
        DisplayTokActive = !DisplayTokActive;
        if (DisplayTokActive) {
            sendJSON("Speech", "DisplayTokON", avatarKey);
        } else {
            sendJSON("Speech", "DisplayTokOFF", avatarKey);
        }
        sayDebug("doSpeechMenu DisplayTokActive:"+(string)DisplayTokActive);
        speechMenu(avatarKey);
    } else {
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
    
    string message = "Settings";

    // 1. Assume nothing is allowed
    integer setClass = 0;
    integer setMood = 0;
    integer setThreat = 0;
    integer setLock = 0;
    integer setZaps = 0;
    integer setTimer = 0;
    integer setAsset = 0;
    integer setBadWords = 0;
    
    // Add some things depending on who you are. 
    // What wearer can change
    if (avatarKey == llGetOwner()) {
        // some things you can always cange
        sayDebug("settingsMenu: wearer");
        setMood = 1;
        setLock = 1;
        
        // Some things you can only change OOC
        if ((prisonerMood == "OOC") || (prisonerMood == "DnD")) {
            sayDebug("settingsMenu: ooc");
            // IC or DnD you change everything
            setClass = 1;
            setThreat = 1;
            setZaps = 1;
            setTimer = 1;
            setAsset = 1;
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
        
        // some things guard can change only OOC
        if (prisonerMood == "OOC") {
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
            setZaps = 0;
            setTimer = 0;
            message = message + "\nSome settings are not available while your lock level is Heavy or Hardcore.";
        } else {
            sayDebug("settingsMenu: heavy-guard");
            setZaps = 1;
            setTimer = 1;
            message = message + "\nSome settings are not available to you while you are a guard.";
        }
    }
    
    list buttons = [];
    buttons = buttons + menuButtonActive("Asset", setAsset);
    buttons = buttons + menuButtonActive("Class", setClass);
    buttons = buttons + menuButtonActive("Threat", setThreat);
    buttons = buttons + menuButtonActive("Lock", setLock);
    buttons = buttons + menuButtonActive("Timer", setTimer);
    buttons = buttons + menuButtonActive("SetZap", setZaps);
    buttons = buttons + menuButtonActive("Mood", setMood);
    buttons = buttons + "Speech";
    
    setUpMenu("Settings", avatarKey, message, buttons);
}
    
doSettingsMenu(key avatarKey, string message, string messageButtonsTrimmed) {
        if (message == "Mood"){
            moodMenu(avatarKey);
        }
        else if (message == "Lock"){
            if (rlvPresent == 1) {
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
        else if (message == "SetZap"){
            ZapLevelMenu(avatarKey);
        }
        else if (message == "Asset"){
            assetMenu(avatarKey);
        }
        else if (message == "Timer"){
            llMessageLinked(LINK_THIS, 3000, "TIMER MODE", avatarKey);
        }
        else if (message == "Speech"){
            speechMenu(avatarKey);
        }
            
}

assetMenu(key avatarKey)
{
    string message = "Choose which Asset Number your collar will show.";
    setUpMenu("Asset", avatarKey, message, assetNumbers);
}

ZapLevelMenu(key avatarKey)
{
    // the zap Level Menu always includes checkboxes in front of the Zap word. 
    // This is not a maximum zap radio button, it is checkboxes. 
    // An inmate could be set to most severe zap setting only. 
    string message = "Set Permissible Zap Levels";
    list buttons = [];
    buttons = buttons + menuCheckbox("Zap Low", allowZapLow);
    buttons = buttons + menuCheckbox("Zap Med", allowZapMed);
    buttons = buttons + menuCheckbox("Zap High", allowZapHigh);
    buttons = buttons + "Settings";
    setUpMenu("ZapLevel", avatarKey, message, buttons);
}

doSetZapLevels(key avatarKey, string message)
{
    if (avatarKey == llGetOwner()) 
    {
        sayDebug("wearer sets allowable zap level: "+message);
        if (message == "Zap Low") {
            allowZapLow = !allowZapLow;
        } else if (message == "Zap Med") {
            allowZapMed = !allowZapMed;
        } else if (message == "Zap High") {
            allowZapHigh = !allowZapHigh;
        }
        if (allowZapLow + allowZapMed + allowZapHigh == 0) {
            allowZapHigh = 1;
        }
        string zapJsonList = llList2Json(JSON_ARRAY, [allowZapLow, allowZapMed, allowZapHigh]);
        sendJSON("zapLevels", zapJsonList, avatarKey);
    }
}

classMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "Set your Prisoner Class";
        list buttons = [];
        integer index = 0;
        integer length = llGetListLength(prisonerClasses);
        for (index = 0; index < length; index++) {
            string class = llList2String(prisonerClasses, index);
            buttons = buttons + menuRadioButton(class, prisonerClass);
        }
        buttons = buttons + "Settings";
        setUpMenu("Class", avatarKey, message, buttons);
    }
    else
    {
        ; // no one else gets a thing
    }
}

moodMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "Set your Mood";
        list buttons = [];
        buttons = buttons + menuRadioButton("OOC", prisonerMood);
        buttons = buttons + menuRadioButton("Submissive", prisonerMood);
        buttons = buttons + menuRadioButton("Versatile", prisonerMood);
        buttons = buttons + menuRadioButton("Dominant", prisonerMood);
        buttons = buttons + menuRadioButton("Nonsexual", prisonerMood);
        buttons = buttons + menuRadioButton("Story", prisonerMood);
        buttons = buttons + menuRadioButton("DnD", prisonerMood);
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
        string message = "Set your Lock Level\n" +
            "• Each level applies heavier RLV restrictions.\n";
            
        // LockLevels: 0=Off 1=Light 2=Medium 3=Heavy 4=Hardcore
        // convert our locklevel to an integer
        sayDebug("lockMenu prisonerLockLevel:"+prisonerLockLevel);
        integer iLockLevel = llListFindList(LockLevels, [prisonerLockLevel]);
        sayDebug("lockMenu iLocklevel:"+(string)iLockLevel);
        // make a list of what lock levels are available from each lock level
        list lockListOff = [0, 1, 2, 3];
        list lockListLight = [0, 1, 2, 3];
        list lockListMedium = [0, 1, 2, 3];
        list lockListHeavy = [3, 4, -1, -1];
        list lockListHardcore = [-1, -1, -1, -1];
        list lockLists = lockListOff + lockListLight + lockListMedium + lockListHeavy + lockListHardcore; // strided list
        list lockListMenu = llList2List(lockLists, iLockLevel*4, (iLockLevel+1)*4); // list of lock levels to add to menu
        sayDebug("lockMenu lockListMenu:"+(string)lockListMenu); 
        
        //make the button list
        list buttons = [];
        string allTheButtons = "";
        integer listsIndex;
        for (listsIndex = 0; listsIndex < 4; listsIndex++) {
            integer lockindex =  llList2Integer(lockListMenu, listsIndex);
            if (lockindex != -1) {
                string lockButton = llList2String(LockLevels, lockindex);
                buttons = buttons + menuRadioButton(lockButton, prisonerLockLevel); 
                allTheButtons = allTheButtons + lockButton;
            }
        }
        
        // based on what buttons are available, build the message.
        if (llSubStringIndex(allTheButtons, "Off") >= 0) {
            message = message + "• Off has no RLV restrictions.\n";
            }
        if (llSubStringIndex(allTheButtons, "Light") >= 0) {
            message = message +  "• Light and Medium can be switched to Off any time.\n";
            }
        if (llSubStringIndex(allTheButtons, "Heavy") >= 0) {
            message = message +  "• Heavy equires you to actvely Safeword out.\n";
        }
        if (llSubStringIndex(allTheButtons, "Hardcore") >= 0) {
            message = message + "• Hardcore has the Heavy restrictions.\n"+
                "Hardcore has no safeword.\n";
                "To be released from Hardcore, you must ask a Guard.\n";
        }
        
        setUpMenu("Lock", avatarKey, message, buttons);
    }
}

confirmHardcore(key avatarKey) {
    sayDebug("confirmHardcore");
    if (avatarKey == llGetOwner()) {
        string message = "Set your Lock Level to Hardcore?\n"+
        "• Hardcore has the Heavy restrictions\n"+
        "• Hardcore has no safeword.\n"+
        "• To be released from Hardcore, you must ask a Guard.\n\n"+
        "Confirm that you want te Hardcore lock.";
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
    setUpMenu("Threat", avatarKey, message, buttons);
}

tone(integer number) {
    string numbers = (string)number;
    integer i;
    for (i = 0; i < llStringLength(numbers); i++) {
        integer digit = (integer)llGetSubString(numbers, i, i);
        llPlaySound(llList2String(touchTones, digit), 0.2);
    }
}

// Event Handlers ***************************

default
{
    state_entry()
    {
        sayDebug("state_entry");
        menuAgentKey = "";
        prisonerLockLevel = "Off"; 
        renamerActive = 0;       
        touchTones = [touchTone0, touchTone1, touchTone2, touchTone3, touchTone4, 
            touchTone5, touchTone6, touchTone7, touchTone8, touchTone9];
        
        // Initialize Unworn
        if (llGetAttached() == 0) {
            llSetObjectName("Black Gazza LOC-4 "+version);
            sendJSON("assetNumber", "P-00000", "");            
            sendJSON("prisonerClass", "white", "");
            sendJSON("prisonerCrime", "unknown", "");
            sendJSON("prisonerThreat", "None", "");
            sendJSON("prisonerMood", "OOC", "");            
        }

        doSetZapLevels(llGetOwner(),""); // initialize

        string canonicalName = llToLower(llKey2Name(llGetOwner()));
        list canoncialList = llParseString2List(llToLower(canonicalName), [" "], []);
        string initials = llGetSubString(llList2String(canoncialList,0),0,0) + llGetSubString(llList2String(canoncialList,1),0,0);
        menuPhrase = initials + "menu";
        llOwnerSay("Access the collar menu by typing /1"+menuPhrase);
        wearerListen = llListen(wearerChannel, "", "", menuPhrase);
    }

    touch_start(integer total_number)
    {
        key avatarKey  = llDetectedKey(0);
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
                llInstantMessage(avatarKey, assetNumber+" Zap: "+ZapLevels);
                }
            else if (touchedFace == FaceBlinky2) {llInstantMessage(avatarKey, assetNumber+" Lock Level: "+prisonerLockLevel);}
            else if (touchedFace == FaceBlinky3) {llInstantMessage(avatarKey, assetNumber+" Class: "+prisonerClass + ": "+class2Description(prisonerClass));}
            else if (touchedFace == FaceBlinky4) {llInstantMessage(avatarKey, assetNumber+" Threat: "+prisonerThreat);}
            else if (touchedFace == batteryIconFace) llInstantMessage(avatarKey, assetNumber+" Battery level: "+batteryLevel+"%");
        } else if (touchedLink == batteryCoverLink) {
            if (touchedFace == batteryCoverFace) llInstantMessage(avatarKey, assetNumber+" Battery level: "+batteryLevel+"%");
            mainMenu(avatarKey);
        } else {
            mainMenu(avatarKey);
        }
    }
    
    listen(integer channel, string name, key avatarKey, string message){
        if (channel == wearerChannel & message == menuPhrase) {
            mainMenu(avatarKey);
            return;
        }
        
        string messageButtonsTrimmed = llStringTrim(llGetSubString(message,2,11), STRING_TRIM);
        sayDebug("listen message:"+message+" messageButtonsTrimmed:"+messageButtonsTrimmed);
        sayDebug("listen menuIdentifier: "+menuIdentifier);
        tone(channel);
        if (llGetSubString(message,1,1) == " ") {
            sendJSON("DisplayTemp", messageButtonsTrimmed, avatarKey);
        } else {
            sendJSON("DisplayTemp", message, avatarKey);
        }    

        // reset the menu setup
        llListenRemove(menuListen);
        menuListen = 0;
        menuAgentKey = "";
        llSetTimerEvent(0);
        
        // Main button
        if (message == "Main") {
            mainMenu(avatarKey);
        }
        
        //Main Menu
        else if ((menuIdentifier == "Main") || (message == "Settings")) {
            sayDebug("listen: Main:"+message);
            doMainMenu(avatarKey, message);
        }
        
        //Settings
        else if (menuIdentifier == "Settings"){
            sayDebug("listen: Settings:"+message);
            doSettingsMenu(avatarKey, message, messageButtonsTrimmed);
        }

        //Speech
        else if (menuIdentifier == "Speech"){
            sayDebug("listen: Speech:"+message);
            doSpeechMenu(avatarKey, message, messageButtonsTrimmed);
        }

        // Asset
        else if (menuIdentifier == "Asset") {
            sayDebug("listen: Asset:"+message);
            if (message != "OK") {
                assetNumber = message;
                // The wearer chose this asset number so transmit it and display it
                sendJSON("assetNumber", assetNumber, avatarKey);
                settingsMenu(avatarKey);
            }
        }
        
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
        
        // Zap the inmate
        else if (menuIdentifier == "Zap") {
            sayDebug("listen: Zap:"+message);
            sendJSON("RLV", "zapPrisoner", avatarKey);
        }

        // Set Zap Level
        else if (menuIdentifier == "ZapLevel") {
            sayDebug("listen: Set Zap:"+message);
            if (message == "Settings") {
                settingsMenu(avatarKey);
            } else {
                doSetZapLevels(avatarKey, messageButtonsTrimmed);
                ZapLevelMenu(avatarKey);
            }
        }

        // Lock Level
        else if (menuIdentifier == "Lock") {
            sayDebug("listen Lock: message:"+message);
            if (message == "○ Hardcore") {
                confirmHardcore(avatarKey);
            } else if (message == "⨷ Hardcore") {
                sayDebug("listen set prisonerLockLevel:\""+prisonerLockLevel+"\"");
                sendJSON("RLV", "Hardcore", avatarKey);
            } else {
                sayDebug("listen set prisonerLockLevel:\""+prisonerLockLevel+"\"");
                sendJSON("RLV", messageButtonsTrimmed, avatarKey);
                if (prisonerLockLevel == "Off") {
                    renamerActive = 0;
                }
                settingsMenu(avatarKey);
            }
        }

        // Threat Level
        else if (menuIdentifier == "Threat") {
            sayDebug("listen: prisonerThreat:"+messageButtonsTrimmed);
            prisonerThreat = messageButtonsTrimmed;
            sendJSON("prisonerThreat", prisonerThreat, avatarKey);
            settingsMenu(avatarKey);
        }
        
        // Document
        else if (menuIdentifier == "Info") {
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
        rlvPresent = getJSONinteger(json, "rlvPresent", rlvPresent);
        prisonerLockLevel = getJSONstring(json, "prisonerLockLevel", prisonerLockLevel);
        renamerActive = getJSONinteger(json, "renamerActive", renamerActive);
        batteryLevel = getJSONstring(json, "batteryLevel", batteryLevel);
    }
    
    timer() 
    {
        // reset the menu setup
        llListenRemove(menuListen);
        menuListen = 0;   
        menuAgentKey = "";
    }
}
