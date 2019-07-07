// Menu.lsl
// Menu script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019

// Handles all the menus for the collar. 
// State is kept here and transmitted to interested scripts by link message calls. 

// reference: useful unicode characters
// https://unicode-search.net/unicode-namesearch.pl?term=CIRCLE

key sWelcomeGroup="49b2eab0-67e6-4d07-8df1-21d3e03069d0";
key sMainGroup="ce9356ec-47b1-5690-d759-04d8c8921476";
key sGuardGroup="b3947eb2-4151-bd6d-8c63-da967677bc69";
key sBlackGazzaRPStaff="900e67b1-5c64-7eb2-bdef-bc8c04582122";
key sOfficers="dd7ff140-9039-9116-4801-1f378af1a002";

integer OPTION_DEBUG = 0;

integer menuChannel = 0;
integer menuListen = 0;

integer allowZapLow = 1;
integer allowZapMed = 1;
integer allowZapHigh = 1;

string ICOOCMood = "OOC";
string prisonerClass = "White";
string theLocklevel = "Off";
list LockLevels = ["Off", "Light", "Medium", "Heavy", "Hardcore"];
integer rlvPresent = 0;

string prisonerCrime = "Unknown";
string prisonerNumber = "Unknown";
string threatLevel = "None";
string batteryLevel = "Unknown";

string approveCrime;
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

setUpMenu(key avatarKey, string message, list buttons)
// wrapper to do all the calls that make a simple menu dialog.
{
    string completeMessage = prisonerNumber + " Collar: " + message;
    menuChannel = -(llFloor(llFrand(10000)+1000));
    llDialog(avatarKey, completeMessage, buttons, menuChannel);
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
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

// Menus and Handlers ****************

mainMenu(key avatarKey) {
    // Sometimes this happens, so fix it. 
    // Respose won't come in time but it will be there for the next menu.
    if (prisonerNumber == "Unknown") {
         llMessageLinked(LINK_THIS, 2000, "Request", avatarKey);
    }
    
    string message = "Main";
    list buttons = ["Info", "Settings", "Leash"]; // *** , "Hack" // not yet implemented
    if (!llSameGroup(avatarKey) || (ICOOCMood == "OOC")) {
        // inmates don't get Zap commands
        buttons = buttons + ["Zap"];
    }
    if (avatarKey == llGetOwner() && theLocklevel != "Hardcore" && theLocklevel != "Off") {
        // if wearer is in hardcore mode, no safeword
        buttons = buttons + ["Safeword"];
    }
    if (theLocklevel == "Hardcore" && !llSameGroup(avatarKey)) {
        // if wearer is in hardcore mode, no safeword
        buttons = buttons + ["Release"];
    }
    setUpMenu(avatarKey, message, buttons);
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
    if (allowZapLow) buttons = buttons + ["Zap Low"];
    if (allowZapMed) buttons = buttons + ["Zap Med"];
    if (allowZapHigh) buttons = buttons + ["Zap High"];
    setUpMenu(avatarKey, message, buttons);
}

infoGive(key avatarKey){
    // Prepare text of collar settings for the information menu
    string ZapLevels = "";
    ZapLevels = menuCheckbox("Low", allowZapLow) + "  " +
    menuCheckbox("Medium", allowZapMed) +  "  " +
    menuCheckbox("High", allowZapHigh);

    string message = "Prisoner Information \n"+
    "Number: " + prisonerNumber + "\n" +
    "Crime: " + prisonerCrime + "\n" +
    "Class: " + prisonerClass + "\n" +
    "Threat: " + threatLevel + "\n" +
    "Zap Levels: " + ZapLevels + "\n"; 
    
    if (rlvPresent) {
        message = message + "RLV Restriction: " + theLocklevel + "\n";
    } else {
        message = message + "RLV is not detected.\n";
    }
    message = message + "Battery Level: " + batteryLevel + "% \n" +
    "Mood: " + ICOOCMood + "\n";
    
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
    setUpMenu(avatarKey, message, buttons);
}

hackMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "Hack";
        list buttons = ["hack", "Maintenance", "Fix"];
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        ;
    }
}

// Settings Menus and Handlers ************************
// Sets Collar State: Mood, Crime, Class, Threat, Lock, Zap levels 

settingsMenu(key avatarKey) {
    // What this menu can present depends on a number of things: 
    // who you are - self or guard
    // IC/OOC mood - OOC, DnD or other
    // RLV lock level - Off, Light, Medium, Heavy, Lardcore
    
    // 1. Assume nothing is allowed
    integer setMood = 0;
    integer setCrime = 0;
    integer setClass = 0;
    integer setThreat = 0;
    integer setLock = 0;
    integer setZaps = 0;
    
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
            setCrime = 1;
            setClass = 1;
            setThreat = 1;
            setZaps = 1;
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
            setCrime = 1;
            setClass = 1;
        }
    }
    
    // Lock level changes some privileges
    if ((theLocklevel == "Hardcore" || theLocklevel == "Heavy")) {
        if (avatarKey == llGetOwner()) {
            sayDebug("settingsMenu: heavy-owner");
            setZaps = 0;
        } else {
            sayDebug("settingsMenu: heavy-guard");
            setZaps = 1;
        }
    }
    
    string message = "Settings";
    list buttons = [];
    if (setMood) buttons = buttons + "Mood";
    if (setCrime) buttons = buttons + "Crime";
    if (setClass) buttons = buttons + "Class";
    if (setThreat) buttons = buttons + "Threat";
    if (setLock) buttons = buttons + "Lock";
    if (setZaps) buttons = buttons + "SetZap";
    setUpMenu(avatarKey, message, buttons);
}
    
doSettingsMenu(key avatarKey, string message) {
        if (message == "Mood"){
            moodMenu(avatarKey);
        }
        else if (message == "Crime"){
            crimeDialog(avatarKey);
        }
        else if (message == "Class"){
            classMenu(avatarKey);
        }
        else if (message == "Lock"){
            lockMenu(avatarKey);
        }
        else if (message == "Threat"){
            threatMenu(avatarKey);
        }
        else if (message == "SetZap"){
            ZapLevelMenu(avatarKey);
        }
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
    setUpMenu(avatarKey, message, buttons);
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
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        ; // no one else gets a thing
    }
}

crimeDialog(key avatarKey) {
    string completeMessage = "Set " + prisonerNumber + "'s Crime";
    menuChannel = -(llFloor(llFrand(10000)+1000));
    llTextBox(avatarKey, completeMessage, menuChannel);
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
}

askToApproveCrime(key avatarKey, string message) {
    sayDebug("askToApproveCrime("+message+")");
    approveCrime = message;
    approveAvatar = avatarKey;
    message = llKey2Name(avatarKey) + " wants to set your crime to \"" + message + "\"";
    setUpMenu(llGetOwner(), message, ["Approve", "Disapprove"]);
}

approveTheCrime() {
    // approveCrime
    if (approveAvatar != llGetOwner()) {
        llInstantMessage(approveAvatar, "Your request to set a new crime has been approved.");
    }
    llOwnerSay("Submitting request to database. New crime will read \""+approveCrime+"\"");
    string URL = "http://sl.blackgazza.com/add_inmate.cgi?key=";
    llHTTPRequest(URL+(string)llGetOwner()+"&name="+llKey2Name(llGetOwner())+"&crime="+approveCrime+"&sentence=0",[],"");
    llSleep(10);
    llOwnerSay("Requesting update from database. In a moment, verify the update with Collar > Info.");
    llMessageLinked(LINK_THIS, 2002, "", "");
}

disapproveTheCrime() {
    llInstantMessage(approveAvatar, "Your request to set a new crime has been disapproved.");
}

classMenu(key avatarKey)
{
    string message = "Set Prisoner Class";
    list buttons = [];
    buttons = buttons + menuRadioButton("White", prisonerClass);
    buttons = buttons + menuRadioButton("Pink", prisonerClass);
    buttons = buttons + menuRadioButton("Red", prisonerClass);
    buttons = buttons + menuRadioButton("Orange", prisonerClass);
    buttons = buttons + menuRadioButton("Green", prisonerClass);
    buttons = buttons + menuRadioButton("Blue", prisonerClass);
    buttons = buttons + menuRadioButton("Black", prisonerClass);
    setUpMenu(avatarKey, message, buttons);
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
        sayDebug("lockMenu LockLevels:"+(string)LockLevels);
        integer iLockLevel = llListFindList(LockLevels, [theLocklevel]);
        sayDebug("lockMenu iLocklevel:"+(string)iLockLevel);
        // make a list of what lock levels are available from each lock level
        list lockListOff = [0, 1, 2, 3];
        list lockListLight = [0, 1, 2, 3];
        list lockListMedium = [0, 1, 2, 3];
        list lockListHeavy = [3, 4, -1, -1];
        list lockListHardcore = [-1, -1, -1, -1];
        list lockLists = lockListOff + lockListLight + lockListMedium + lockListHeavy + lockListHardcore; // strided list
        list lockListMenu = llList2List(lockLists, iLockLevel*4, (iLockLevel+1)*4 ); // list of lock levels to add to menu
        sayDebug("lockMenu lockListMenu:"+(string)lockListMenu); 
               
        //make the button list
        list buttons = [];
        integer listsIndex;
        for (listsIndex = 0; listsIndex < 4; listsIndex++) {
            integer lockindex =  llList2Integer(lockListMenu, listsIndex);
            if (lockindex != -1) {
                buttons = buttons + [llList2String(LockLevels, lockindex)];
            }
        }
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        ;
    }
}

threatMenu(key avatarKey) {
    string message = "Threat";
    list buttons = [];
    buttons = buttons + menuRadioButton("None", threatLevel);
    buttons = buttons + menuRadioButton("Moderate", threatLevel);
    buttons = buttons + menuRadioButton("Dangerous", threatLevel);
    buttons = buttons + menuRadioButton("Extreme", threatLevel);
    setUpMenu(avatarKey, message, buttons);
}

// Event Handlers ***************************

default
{
    state_entry()
    {
        string theLocklevel = "Off";
        llMessageLinked(LINK_THIS, 1402, "", ""); // ask for RLV update
        llMessageLinked(LINK_THIS, 2002, "", ""); // ask for database update
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
                llInstantMessage(avatarKey, prisonerNumber+" Zap: "+ZapLevels);
                }
            else if (touchedFace == FaceBlinky2) {llInstantMessage(avatarKey, prisonerNumber+" Lock Level: "+theLocklevel);}
            else if (touchedFace == FaceBlinky3) {llInstantMessage(avatarKey, prisonerNumber+" Class: "+prisonerClass);}
            else if (touchedFace == FaceBlinky4) {llInstantMessage(avatarKey, prisonerNumber+" Threat: "+threatLevel);}
            else if (touchedFace == batteryIconFace) llInstantMessage(avatarKey, prisonerNumber+" Battery level: "+batteryLevel+"%");
        } else if (touchedLink == batteryCoverLink) {
            if (touchedFace == batteryCoverFace) llInstantMessage(avatarKey, prisonerNumber+" Battery level: "+batteryLevel+"%");
            mainMenu(avatarKey);
        } else {
            mainMenu(avatarKey);
        }
    }
    
    listen( integer channel, string name, key avatarKey, string message ){
        llListenRemove(menuListen);
        menuListen = 0;
        llSetTimerEvent(0);
        string messageButtonsTrimmed = llStringTrim(llGetSubString(message,2,11), STRING_TRIM);
        sayDebug("listen message:"+message+" messageButtonsTrimmed:"+messageButtonsTrimmed);
        
        //Main
        if (llSubStringIndex("Zap Hack Leash Info Safeword Settings Release", message) > -1){
            sayDebug("listen: Main:"+message);
            doMainMenu(avatarKey, message);
        }
        
        //Settings
        else if (llSubStringIndex("Play Level Class Threat Crime Lock Mood SetZap", message) > -1){
            sayDebug("listen: Settings:"+message);
            doSettingsMenu(avatarKey, message);
        }

        // Mood
        else if (llSubStringIndex("OOC Submissive Versatile Dominant Nonsexual Story DnD",  messageButtonsTrimmed) > -1){
            sayDebug("listen: Mood:"+messageButtonsTrimmed);
            ICOOCMood = messageButtonsTrimmed;
            llMessageLinked(LINK_THIS, 1100, ICOOCMood, avatarKey);
        }
        
        //Class
        else if (llSubStringIndex("White Pink Red Orange Green Blue Black", messageButtonsTrimmed) > -1){
            sayDebug("listen: Class:"+messageButtonsTrimmed);
            prisonerClass = messageButtonsTrimmed;
            llMessageLinked(LINK_THIS, 1200, prisonerClass, avatarKey);
        }
        
        // Zap the inmate
        else if (llSubStringIndex("Zap Low Zap Med Zap High", message) > -1){
            sayDebug("listen: Zap:"+message);
            llMessageLinked(LINK_THIS, 1301, message, avatarKey);
        }

        // Set Zap Level
        else if (llSubStringIndex("Zap Low Zap Med Zap High", messageButtonsTrimmed) > -1){
            sayDebug("listen: Set Zap:"+message);
            doSetZapLevels(avatarKey, messageButtonsTrimmed);
        }

        // Lock Level
        else if (llSubStringIndex("Off Light Medium Heavy Hardcore", message) > -1){
            sayDebug("listen: theLocklevel:"+message);
            theLocklevel = message;
            sayDebug("listen set theLocklevel:"+theLocklevel);
            llMessageLinked(LINK_THIS, 1401, theLocklevel, avatarKey);
        }

        // Threat Level
        else if (llSubStringIndex("None Moderate Dangerous Extreme", messageButtonsTrimmed) > -1){
            sayDebug("listen: threatLevel:"+messageButtonsTrimmed);
            threatLevel = messageButtonsTrimmed;
            llMessageLinked(LINK_THIS, 1500, threatLevel, avatarKey);
        }
        
        // Document
        else if (llGetSubString(message,0,3) == "Doc "){
            integer inumber = (integer)llGetSubString(message,4,4) - 1;
            sayDebug("listen: message:"+message+ " inumber:"+(string)inumber);
            if (inumber > -1) {
                llOwnerSay("Offering '"+llGetInventoryName(INVENTORY_NOTECARD,inumber)+"' to "+llGetDisplayName(avatarKey)+".");
                llGiveInventory(avatarKey, llGetInventoryName(INVENTORY_NOTECARD,inumber) );    
            }        
        }
        
        // Crime
        else if (message == "Approve") {
            approveTheCrime();
        }
        else if (message == "Disapprove") {
            disapproveTheCrime();
        }
        else {
            sayDebug("listen: Crime:"+message);
            askToApproveCrime(avatarKey, message);
        } 
    }
    
    link_message( integer sender_num, integer num, string message, key id ){ 
    // We listen in on link status messages and pick the ones we're interested in
        sayDebug("Menu link_message "+(string)num+" "+message);
        if (num == 2000) {
            // database status message
            list returned = llParseString2List(message, [","], []);
            prisonerCrime = llList2String(returned, 2);
            prisonerNumber = llList2String(returned, 4);
        } else if (num == 1700) {
            batteryLevel = message;
        } else if (num == 1400) {
            // RLV/Lock status
            if (message == "NoRLV") {
                rlvPresent = 0;
                theLocklevel = "Off";
            } else if (message == "YesRLV") {
                rlvPresent = 1;
            } else {
                theLocklevel = message;
            }
            sayDebug("link_message set theLocklevel:"+theLocklevel);
        }
    }
    
    timer() 
    {
        llListenRemove(menuListen);
        menuListen = 0;    
    }
}
