// Menu.lsl
// Menu script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019

// Handles all the menus for the collar. 
// State is kept here and transmitted to interested scripts by link message calls. 

// reference: useful unicode characters
// https://unicode-search.net/unicode-namesearch.pl?term=CIRCLE

string version = "2020-02-26";

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

integer OPTION_DEBUG = 0;

integer menuChannel = 0;
integer menuListen = 0;
string menuIdentifier;
key menuAgentKey;

integer allowZapLow = 1;
integer allowZapMed = 1;
integer allowZapHigh = 1;

list assetNumbers;
string ICOOCMood = "OOC";
string prisonerClass = "white";
list prisonerClasses = ["white", "pink", "red", "orange", "green", "blue", "black"];
list prisonerClassesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental"];
string theLocklevel = "Off";
list LockLevels = ["Off", "Light", "Medium", "Heavy", "Hardcore"];
integer rlvPresent = 0;

string prisonerCrime = "Unknown";
string assetNumber = "Unknown";
string threatLevel = "Moderate";
string batteryLevel = "Unknown";

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
        llWhisper(0,"Menu:"+message);
    }
}

integer invert(integer boolie)
{
    if (boolie == 1) 
        return 0;
    else
        return 1;
}

tempDisplay(string message) 
// send the message to the alphanumeric Display
{
    llMessageLinked(LINK_THIS, 2001, message, "");
}

setUpMenu(string identifier, key avatarKey, string message, list buttons)
// wrapper to do all the calls that make a simple menu dialog.
{
    sayDebug("setUpMenu "+identifier);
    
    if (identifier != "Main") {
        buttons = buttons + ["Main"];
    }
    
    tempDisplay("menu access");
    menuIdentifier = identifier;
    menuAgentKey = avatarKey;
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
        button = "⦻";
    }
    return [button];
}

// Menus and Handlers ****************

mainMenu(key avatarKey) {
    string message = "Main";

    if (assetNumber == "Unknown") {
        llMessageLinked(LINK_THIS, 2002, "", avatarKey);
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
    
    // enambe things based on state
    if (!llSameGroup(avatarKey) || (ICOOCMood == "OOC")) {
        doZap = 1;
    }
    
    if (avatarKey == llGetOwner() && theLocklevel != "Hardcore" && theLocklevel != "Off") {
        doSafeword = 1;
    } else {
        message = message + "\nSafeword is only availavle to the Prisoner in RLV levels Medium and Heavy.";
    }
    
    if (theLocklevel != "Off" && !llSameGroup(avatarKey)) {
        doRelease = 1;
    } else {
        message = message + "\nRelease is only availavle to a Guard while prisoner is in RLV Hardcore mode.";
    }
    
    list buttons = ["Info", "Settings", "Leash", "Hack"];
    buttons = buttons + menuButtonActive("Zap", doZap);
    buttons = buttons + menuButtonActive("Safeword", doSafeword);
    buttons = buttons + menuButtonActive("Release", doRelease);
    setUpMenu("Main", avatarKey, message, buttons);
}

doMainMenu(key avatarKey, string message) {
        if (message == "Zap"){
            zapMenu(avatarKey);
        }
        else if (message == "Leash"){
            llMessageLinked(LINK_THIS, 1901, "Leash", avatarKey);
        }
        else if (message == "Info"){
            infoGive(avatarKey);
        }
        else if (message == "Hack"){
            hackMenu(avatarKey);
        }
        else if (message == "Safeword"){
            llMessageLinked(LINK_THIS, 1401, "Safeword", avatarKey);
        }
        else if (message == "Settings"){
            settingsMenu(avatarKey);
        }
        else if (message == "Release"){
            theLocklevel = "Off";
            llMessageLinked(LINK_THIS, 1401, "Off", avatarKey);
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
        "Threat: " + threatLevel + "\n" +
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
    message = message + "Mood: " + ICOOCMood + "\n";
    if (rlvPresent) {
        message = message + "RLV Active: " + theLocklevel + "\n";
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
    
    // Add some things depending on who you are. 
    // What wearer can change
    if (avatarKey == llGetOwner()) {
        // some things you can always cange
        sayDebug("settingsMenu: wearer");
        setMood = 1;
        setLock = 1;
        
        // Some things you can only change OOC
        if ((ICOOCMood == "OOC") || (ICOOCMood == "DnD")) {
            sayDebug("settingsMenu: ooc");
            // IC or DnD you change everything
            setClass = 1;
            setThreat = 1;
            setZaps = 1;
            setTimer = 1;
            setAsset = 1;
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
        if (ICOOCMood == "OOC") {
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
    if ((theLocklevel == "Hardcore" || theLocklevel == "Heavy")) {
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
    
    setUpMenu("Settings", avatarKey, message, buttons);
}
    
doSettingsMenu(key avatarKey, string message) {
        if (message == "Mood"){
            moodMenu(avatarKey);
        }
        else if (message == "Lock"){
            if (rlvPresent == 1) {
                lockMenu(avatarKey);
            } else {
                // get RLV to check RLV again 
                llOwnerSay("RLV was off nor not detected. Attempting to register with RLV.");
                llMessageLinked(LINK_THIS, 1410, "Register RLV", avatarKey);
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
            allowZapLow = invert(allowZapLow);
        } else if (message == "Zap Med") {
            allowZapMed = invert(allowZapMed);
        } else if (message == "Zap High") {
            allowZapHigh = invert(allowZapHigh);
        }
        if (allowZapLow + allowZapMed + allowZapHigh == 0) {
            allowZapHigh = 1;
        }
        // Send the zap status message
        string zapJsonList = llList2Json(JSON_ARRAY, [allowZapLow, allowZapMed, allowZapHigh]);
        llMessageLinked(LINK_THIS, 1300, zapJsonList, avatarKey);
    }
}

classMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "Set your Prisoner Class";
        setUpMenu("Class", avatarKey, message, prisonerClasses);
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
        buttons = buttons + menuRadioButton("OOC", ICOOCMood);
        buttons = buttons + menuRadioButton("Submissive", ICOOCMood);
        buttons = buttons + menuRadioButton("Versatile", ICOOCMood);
        buttons = buttons + menuRadioButton("Dominant", ICOOCMood);
        buttons = buttons + menuRadioButton("Nonsexual", ICOOCMood);
        buttons = buttons + menuRadioButton("Story", ICOOCMood);
        buttons = buttons + menuRadioButton("DnD", ICOOCMood);
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
            "• Each level applies heavier RLV restrictions.\n" +
            "• Off has no RLV restrictions.\n" +
            "• Light and Medium can be switched to Off any time.\n" +
            "• Heavy equires you to actvely Safeword out.\n" +
            "• Hardcore has the Heavy restrictions but no safeword option. To be released from this level, you must ask a Guard.";
        // LockLevels: 0=Off 1=Light 2=Medium 3=Heavy 4=Hardcore
        // convert our locklevel to an integer
        sayDebug("lockMenu theLocklevel:"+theLocklevel);
        integer iLockLevel = llListFindList(LockLevels, [theLocklevel]);
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
        integer listsIndex;
        for (listsIndex = 0; listsIndex < 4; listsIndex++) {
            integer lockindex =  llList2Integer(lockListMenu, listsIndex);
            if (lockindex != -1) {
                string lockButton = llList2String(LockLevels, lockindex);
                buttons = buttons + menuRadioButton(lockButton, theLocklevel); 
            }
        }
        setUpMenu("Lock", avatarKey, message, buttons);
    }
}

threatMenu(key avatarKey) {
    string message = "Threat";
    list buttons = [];
    buttons = buttons + menuRadioButton("None", threatLevel);
    buttons = buttons + menuRadioButton("Moderate", threatLevel);
    buttons = buttons + menuRadioButton("Dangerous", threatLevel);
    buttons = buttons + menuRadioButton("Extreme", threatLevel);
    setUpMenu("Threat", avatarKey, message, buttons);
}

tone(integer number) {
    string numbers = (string)number;
    integer i;
    for (i = 0; i < llStringLength(numbers); i++) {
        integer digit = (integer)llGetSubString(numbers, i, i);
        llPlaySound(llList2String(touchTones, digit), 1);
    }
}

// Event Handlers ***************************

default
{
    state_entry()
    {
        sayDebug("state_entry");
        menuAgentKey = "";
        theLocklevel = "Off";        
        touchTones = [touchTone0, touchTone1, touchTone2, touchTone3, touchTone4, 
            touchTone5, touchTone6, touchTone7, touchTone8, touchTone9];
        llMessageLinked(LINK_THIS, 1402, "", ""); // ask for RLV update
        llMessageLinked(LINK_THIS, 2002, "", ""); // ask for database update
        doSetZapLevels(llGetOwner(),""); // initialize
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
            else if (touchedFace == FaceBlinky2) {llInstantMessage(avatarKey, assetNumber+" Lock Level: "+theLocklevel);}
            else if (touchedFace == FaceBlinky3) {llInstantMessage(avatarKey, assetNumber+" Class: "+prisonerClass + ": "+class2Description(prisonerClass));}
            else if (touchedFace == FaceBlinky4) {llInstantMessage(avatarKey, assetNumber+" Threat: "+threatLevel);}
            else if (touchedFace == batteryIconFace) llInstantMessage(avatarKey, assetNumber+" Battery level: "+batteryLevel+"%");
        } else if (touchedLink == batteryCoverLink) {
            if (touchedFace == batteryCoverFace) llInstantMessage(avatarKey, assetNumber+" Battery level: "+batteryLevel+"%");
            mainMenu(avatarKey);
        } else {
            mainMenu(avatarKey);
        }
    }
    
    listen(integer channel, string name, key avatarKey, string message){
        string messageButtonsTrimmed = llStringTrim(llGetSubString(message,2,11), STRING_TRIM);
        sayDebug("listen message:"+message+" messageButtonsTrimmed:"+messageButtonsTrimmed);
        sayDebug("listen menuIdentifier: "+menuIdentifier);
        tone(channel);
        if (llGetSubString(message,1,1) == " ") {
            tempDisplay(messageButtonsTrimmed);
        } else {
            tempDisplay(message);
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
        else if (menuIdentifier == "Main") {
            sayDebug("listen: Main:"+message);
            doMainMenu(avatarKey, message);
        }
        
        //Settings
        else if (menuIdentifier == "Settings") {
            sayDebug("listen: Settings:"+message);
            doSettingsMenu(avatarKey, message);
        }

        // Asset
        else if (menuIdentifier == "Asset") {
            sayDebug("listen: Asset:"+message);
            if (message != "OK") {
                assetNumber = message;
                // The wearer chose this asset number so transmit it and display it
                llMessageLinked(LINK_THIS, 1013, assetNumber, avatarKey);
                llMessageLinked(LINK_THIS, 2000, assetNumber, avatarKey);
                settingsMenu(avatarKey);
            }
        }
        
        // Class
        else if (menuIdentifier == "Class") {
            sayDebug("listen: Class:"+message);
            prisonerClass = message;
            llMessageLinked(LINK_THIS, 1200, prisonerClass, avatarKey);
            settingsMenu(avatarKey);
        }
        
        // Mood
        else if (menuIdentifier == "Mood") {
            sayDebug("listen: Mood:"+messageButtonsTrimmed);
            ICOOCMood = messageButtonsTrimmed;
            llMessageLinked(LINK_THIS, 1100, ICOOCMood, avatarKey);
            settingsMenu(avatarKey);
        }
        
        // Zap the inmate
        else if (menuIdentifier == "Zap") {
            sayDebug("listen: Zap:"+message);
            llMessageLinked(LINK_THIS, 1301, message, avatarKey);
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
            sayDebug("listen: theLocklevel:"+messageButtonsTrimmed);
            if (messageButtonsTrimmed != "") {
                theLocklevel = messageButtonsTrimmed;
                sayDebug("listen set theLocklevel:\""+theLocklevel+"\"");
                llMessageLinked(LINK_THIS, 1401, theLocklevel, avatarKey);
                settingsMenu(avatarKey);
            }
        }

        // Threat Level
        else if (menuIdentifier == "Threat") {
            sayDebug("listen: threatLevel:"+messageButtonsTrimmed);
            threatLevel = messageButtonsTrimmed;
            llMessageLinked(LINK_THIS, 1500, threatLevel, avatarKey);
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
    
    link_message(integer sender_num, integer num, string message, key avatarKey){ 
    // We listen in on link status messages and pick the ones we're interested in
        sayDebug("Menu link_message "+(string)num+" "+message);
        if (num == 1011) {
            assetNumbers = llJson2List(message);
            assetNumber = llList2String(assetNumbers, 0);
            llMessageLinked(LINK_THIS, 1013, assetNumber, avatarKey);
            llMessageLinked(LINK_THIS, 2000, assetNumber, avatarKey);
        } else if (num == 1200) {
            prisonerClass = message;
        } else if (num == 1400) {
            // RLV level: Off, Light, Medium, heavy, Hardcore
            if (rlvPresent == 1) {
                theLocklevel = message;
            } else {
                theLocklevel = "Off";
            }
            sayDebug("link_message set theLocklevel:"+theLocklevel);
        } else if (num == 1403) {
            // RLV Presence
            if (message == "NoRLV") {
                rlvPresent = 0;
                theLocklevel = "Off";
            } else if (message == "YesRLV") {
                rlvPresent = 1;
            }
            sayDebug("link_message set rlvPresent:"+(string)rlvPresent);
        } else if (num == 1700) {
            batteryLevel = message;
        } else if (num == 1800) {
            prisonerCrime = message;
        } else if (num == 2000) {
            assetNumber = message;
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
