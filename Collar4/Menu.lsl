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
string RLVLevel = "Off";
integer rlvPresent = 0;

string prisonerCrime = "Unknown";
string prisonerNumber = "Unknown";
string threatLevel = "None";
string batteryLevel = "Unknown";

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

list menuCheckbox(string title, integer onOff)
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
    return [checkbox + " " + title];
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
    string message = "Main";
    list buttons = ["Info", "Settings", "Leash", "Hack"];
    if (!llSameGroup(avatarKey)) {
        // inmates don't get Zap commands
        buttons = buttons + ["Zap"];
    }
    if (RLVLevel != "Hardcore" && RLVLevel != "Off") {
        // if wearer is in hardcore mode, no safeword
        buttons = buttons + ["Safeword"];
    }
    if (RLVLevel == "Hardcore" && !llSameGroup(avatarKey)) {
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
            leashMenu(avatarKey);
        }
        else if (message == "Info"){
            infoGive(avatarKey);
        }
        else if (message == "Hack"){
            hackMenu(avatarKey);
        }
        else if (message == "Safeword"){
            llMessageLinked(LINK_THIS, 1400, "Safeword", "");
        }
        else if (message == "Settings"){
            settingsMenu(avatarKey);
        }
        else if (message == "Release"){
            RLVLevel = "Off";
            llMessageLinked(LINK_THIS, 1400, "Off", "");
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

leashMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        ; // can't leash yourself. Well, you can, but you can't unleash yourself. 
    }
    else
    {
        ;
    }
}

infoGive(key avatarKey){
    string ZapLevels = "";
    if (allowZapLow) ZapLevels = ZapLevels + "Low ";
    if (allowZapMed) ZapLevels = ZapLevels + "Medium ";
    if (allowZapHigh) ZapLevels = ZapLevels + "High ";

    string message = "Prisoner Information \n"+
    "Number: " + prisonerNumber + "\n" +
    "Crime: " + prisonerCrime + "\n" +
    "Class: " + prisonerClass + "\n" +
    "Threat: " + threatLevel + "\n" +
    "Zap Levels: " + ZapLevels + "\n"; 
    
    if (rlvPresent) {
        message = message + "Restriction: " + RLVLevel + "\n";
    } else {
        message = message + "RLV is not detected.\n";
    }
    message = message + "Battery Level: " + batteryLevel + "% \n" +
    "Mood: " + ICOOCMood + "\n";
    
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
    if (avatarKey == llGetOwner())
    {
        string message = "Settings";
        list buttons = ["Mood"];
        if (RLVLevel != "Hardcore" && RLVLevel != "Heavy") {
            buttons = buttons + ["Crime", "Class", "Threat", "SetZap", "Lock"];
        }
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        ;
    }
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
        } else if (message == "Zap Hi") {
            allowZapHigh = invert(allowZapHigh);
        }
        if (allowZapLow + allowZapMed + allowZapHigh == 0) {
            allowZapHigh = 1;
        }
        string zapJsonList = llList2Json(JSON_ARRAY, [allowZapLow, allowZapMed, allowZapHigh]);
        llMessageLinked(LINK_THIS, 1301, zapJsonList, "");
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
    llWhisper(0,prisonerCrime);
    llMessageLinked(LINK_THIS, 1800, prisonerCrime, ""); // communicate the crime
}

classMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
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
    else
    {
        ; // guards can set Unclassified/Orange/Blue/Pink/Green/Black
    }
}

lockMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "Lock";
        list buttons = [];
        buttons = buttons + menuRadioButton("Off", RLVLevel);
        
        if (rlvPresent == 1) {
            buttons = buttons + menuRadioButton("Light", RLVLevel);
            buttons = buttons + menuRadioButton("Medium", RLVLevel);
            buttons = buttons + menuRadioButton("Heavy", RLVLevel);
            buttons = buttons + menuRadioButton("Hardcore", RLVLevel);
        } else  if (rlvPresent == 0) {
            message = "Lock is not available because RLV is disabled.";
        }
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        ;
    }
}

threatMenu(key avatarKey) {
    if (avatarKey == llGetOwner())
    {
        string message = "Threat";
        list buttons = [];
        buttons = buttons + menuRadioButton("None", threatLevel);
        buttons = buttons + menuRadioButton("Moderate", threatLevel);
        buttons = buttons + menuRadioButton("Dangerous", threatLevel);
        buttons = buttons + menuRadioButton("Extreme", threatLevel);
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        ;
    }
}

// Event Handlers ***************************

default
{
    state_entry()
    {
        string RLVLevel = "Off";
    }

    touch_start(integer total_number)
    {
        key avatarKey  = llDetectedKey(0);
        integer touchedLink = llDetectedLinkNumber(0);
        integer touchedFace = llDetectedTouchFace(0);
        vector touchedUV = llDetectedTouchUV(0);
        sayDebug("Link "+(string)touchedLink+", Face "+(string)touchedFace+", UV "+(string)touchedUV);
        
        if (touchedLink == LinkBlinky) {
            if (touchedFace == FaceBlinky1) {llInstantMessage(avatarKey, prisonerNumber+" Mood: "+ICOOCMood);}
            else if (touchedFace == FaceBlinky2) {llInstantMessage(avatarKey, prisonerNumber+" Class: "+prisonerClass);}
            else if (touchedFace == FaceBlinky3) {llInstantMessage(avatarKey, prisonerNumber+" Threat: "+threatLevel);}
            else if (touchedFace == FaceBlinky4) {llInstantMessage(avatarKey, prisonerNumber+" Zap:");}
            else if (touchedFace == batteryIconFace) llInstantMessage(avatarKey, prisonerNumber+" Battery level: "+batteryLevel+"%");
        } else if (touchedLink == batteryCoverLink) {
            if (touchedFace == batteryCoverFace) llInstantMessage(avatarKey, prisonerNumber+" Battery level: "+batteryLevel+"%");
            else mainMenu(avatarKey);
        } else
            mainMenu(avatarKey);
    }
    
    listen( integer channel, string name, key avatarKey, string message ){
        llListenRemove(menuListen);
        menuListen = 0;
        llSetTimerEvent(0);
        string messageNoButtons = llStringTrim(llGetSubString(message,2,11), STRING_TRIM);
        sayDebug("listen:"+message+" messageNoButtons:"+messageNoButtons);
        
        //Main
        if (llSubStringIndex("Zap Hack Leash Info Safeword Settings Release", message) > -1){
            sayDebug("listen: Main:"+message);
             doMainMenu(avatarKey, message);
        }
        
        // Do Zap
        else if (llGetSubString(message,0,2) == "Zap"){
            sayDebug("listen: Zap:"+message);
            llMessageLinked(LINK_THIS, 1302, message, "");
        }
        
        //Settings
        else if (llSubStringIndex("Play Level Class Threat Crime Lock Mood SetZap", message) > -1){
            sayDebug("listen: Settings:"+message);
            doSettingsMenu(avatarKey, message);
        }

        // Mood
        else if (llSubStringIndex("OOC Submissive Versatile Dominant Nonsexual Story DnD",  messageNoButtons) > -1){
            sayDebug("listen: Mood:"+messageNoButtons);
            ICOOCMood = messageNoButtons;
            llMessageLinked(LINK_THIS, 1100, ICOOCMood, "");
        }
        
        //Class
        else if (llSubStringIndex("White Pink Red Orange Green Blue Black", messageNoButtons) > -1){
            sayDebug("listen: Class:"+messageNoButtons);
            prisonerClass = messageNoButtons;
            llMessageLinked(LINK_THIS, 1200, prisonerClass, "");
        }
        
        // Set Zap Level
        else if (llSubStringIndex("Zap Low Zap Med Zap High", messageNoButtons) > -1){
            sayDebug("listen: Set Zap:"+message);
            doSetZapLevels(avatarKey, messageNoButtons);
        }

        // Lock Level
        else if (llSubStringIndex("Off Light Medium Heavy Hardcore", messageNoButtons) > -1){
            sayDebug("listen: RLVLevel:"+messageNoButtons);
            RLVLevel = messageNoButtons;
            llMessageLinked(LINK_THIS, 1400, RLVLevel, "");
        }

        // Threat Level
        else if (llSubStringIndex("None Moderate Dangerous Extreme", messageNoButtons) > -1){
            sayDebug("listen: threatLevel:"+messageNoButtons);
            threatLevel = messageNoButtons;
            llMessageLinked(LINK_THIS, 1500, threatLevel, "");
        }
        
        // Document
        else if ((llGetSubString(message,0,2) == "Doc") > -1){
            sayDebug("listen: message:"+message);
            integer inumber = (integer)llGetSubString(message,4,4) - 1;
            llInstantMessage(llGetOwner(),"Offering '"+llGetInventoryName(INVENTORY_NOTECARD,inumber)+"' to "+llGetDisplayName(avatarKey)+".");
            llGiveInventory(avatarKey, llGetInventoryName(INVENTORY_NOTECARD,inumber) );            
        }

        else {
            sayDebug("Error: Unhandled Dialog Message: "+message);
        } 
    }
    
    link_message( integer sender_num, integer num, string message, key id ){ 
    // We listen in on all ink messages and pick the ones we're interested in
        sayDebug("Menu link_message "+(string)num+" "+message);
        if (num == 2000) {
            list returned = llParseString2List(message, [","], []);
            prisonerCrime = llList2String(returned, 2);
            prisonerNumber = llList2String(returned, 4);
        } else if (num == 1700) {
            batteryLevel = message;
        } else if (num == 1401) {
            if (message == "NoRLV") {
                rlvPresent = 0;
                RLVLevel = "Off";
            } else if (message == "YesRLV") {
                rlvPresent = 1;
            } else {
                RLVLevel = message;
            }
        }
    }
    
    timer() 
    {
        llListenRemove(menuListen);
        menuListen = 0;    
    }
}
