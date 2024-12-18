// MenuSettings.lsl
// Menu script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019
string version = "2024-12-11";

integer OPTION_DEBUG = FALSE;

integer menuChannel = 0;
integer menuListen = 0;
string menuIdentifier;
key menuAgentKey;

// Punishments
integer allowZapLow = TRUE;
integer allowZapMed = TRUE;
integer allowZapHigh = TRUE;
integer allowZapByObject = TRUE;
integer allowVision = TRUE;
string zapJsonList = ""; // for link data transfers

string mood;
string class = "white";
list classes = ["white", "pink", "red", "orange", "green", "blue", "black"];
list classesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental"];
integer canBeNone = 1;
integer canBeModerate = 1;
integer canBeDangerous = 1;
integer canBeExtreme = 1;

string RLV = "RLV";
string RLVlevel;
string RLVlevelOff = "Off";
integer rlvPresent = FALSE;
integer renamerActive = FALSE;
integer DisplayTokActive = FALSE;

integer speechPenaltyBuzz = 0;
integer speechPenaltyZap = 0;

string crime = "Unknown";
string assetNumber = "P-00000";
string threat = "Moderate";
//integer batteryActive = FALSE;
integer badWordsActive = FALSE;
//integer titlerActive = TRUE;

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
string buttonCharacter = "Character";
string buttonSetCrime = "Set Crime";
string buttonSetName = "Set Name";
string buttonBackup = "Backup";
//string buttonTitler = "Titler";
//string buttonBattery = "Battery";
//string buttonHack = "Hack";

key guardGroupKey = "b3947eb2-4151-bd6d-8c63-da967677bc69";
key blurp = "d5567c52-b78d-f78f-bcb1-605701b3af24";

// Utilities *******

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("MenuSettings: "+message);
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

string menuRadioButton(string title, string match)
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
    return radiobutton + " " + title;
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

string class2Description(string class) {
    return llList2String(classes, llListFindList(classes, [class])) + "=" +
        llList2String(classesLong, llListFindList(classes, [class]));
}
settingsMenu(key avatarKey) {
    // What this menu can present depends on a number of things:
    // who you are - self or guard
    // IC/OOC mood - OOC, DnD or other
    // RLV lock level - Off, Light, Medium, Heavy, Lardcore

    string ZapLevels = menuCheckbox("Low", allowZapLow) + "  " +
    menuCheckbox("Medium", allowZapMed) +  "  " +
    menuCheckbox("High", allowZapHigh) + "  " +
    menuCheckbox("Objects", allowZapByObject);

    string message = buttonSettings + "\n" +
        "Crime: " + crime + "\n" +
        "Shock: " + ZapLevels + "\n" +
        "Mood: " + mood + "\n" + 
        "Class: "+class2Description(class)+"\n" +
        "Threat: " + threat;

    // 1. Assume nothing is allowed
    integer xsetRLVLevel = FALSE;
    integer setPunishments = FALSE;
    integer setBadWords = FALSE;
    integer setSpeech = FALSE;
    integer setCharacter = FALSE;
    integer setName = FALSE;
    integer setCrime = FALSE;
    integer setClass = FALSE;
    integer setThreat = FALSE;
    integer doBackup = FALSE;
    integer setMood = FALSE;

    // Add some things depending on who you are.
    // What wearer can change
    if (avatarKey == llGetOwner()) {
        sayDebug("settingsMenu Owner " + RLVlevel);
        if (RLVlevel == "Hardcore") {
            xsetRLVLevel = FALSE;
            message = message + "\nSome settings are not available while your lock level is Hardcore.";
        } else if (RLVlevel == "Heavy") {
            xsetRLVLevel = TRUE;
            message = message + "\nSome settings are not available while your lock level is Heavy.";
        } else {
            // otherwise the wearer can cange some things
            sayDebug("settingsMenu: normal-owner");
            xsetRLVLevel = TRUE;
            setPunishments = TRUE;
            setBadWords = TRUE;
            setSpeech = TRUE;
            setCharacter = TRUE;
            setName = TRUE;
            setCrime = TRUE;
            setClass = TRUE;
            setThreat = TRUE;
            setMood = TRUE;
            doBackup = TRUE;
        }
    }
    
    // What a guard can change
    else if(agentIsGuard(avatarKey) & avatarKey != llGetOwner())
    {
        sayDebug("settingsMenu Guard " + RLVlevel);
        setCrime = TRUE;
        setClass = TRUE;
        setThreat = TRUE;
        setPunishments = TRUE;
        if (RLVlevel == "Hardcore") {
            // Hardcore means guard can reset your RLVlevel. 
            xsetRLVLevel = TRUE;
        }
        if ((RLVlevel == "Hardcore" || RLVlevel == "Heavy")) {
            // hardcore and heavy mean things
            sayDebug("settingsMenu: heavy-owner");
            setSpeech = TRUE;
            setBadWords = TRUE;
        }
    }

    list buttons = [];
    buttons = buttons + menuButtonActive("Class", setClass);
    buttons = buttons + menuButtonActive("Threat", setThreat);
    buttons = buttons + menuButtonActive(RLV, xsetRLVLevel);
    buttons = buttons + menuButtonActive("Punishment", setPunishments);
    buttons = buttons + menuButtonActive("Mood", setMood);
    buttons = buttons + menuButtonActive(buttonSpeech, setSpeech);
    buttons = buttons + menuButtonActive(buttonSetName, setName);
    buttons = buttons + menuButtonActive(buttonSetCrime, setCrime);
    buttons = buttons + menuButtonActive(buttonBackup,doBackup);
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
            sendJSON("Menu", RLV, avatarKey);
        } else {
            // get RLV to check RLV again
            llOwnerSay("RLV was off nor not detected. Attempting to register with RLV.");
            sendJSON(RLV, "Register", avatarKey);
        }
    }
    else if (message == buttonBackup){
        sendJSON("Database", buttonBackup, avatarKey);
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
    else if (message == buttonSpeech){
        speechMenu(avatarKey);
    }
    else if (message == buttonCharacter){
        characterMenu(avatarKey);
    }
    else if (message == buttonSetName){
        characterSetNameTextBox(avatarKey);
    }
    else if(message == buttonSetCrime) {
        characterSetCrimeTextBox(avatarKey);
    }
    //else if (message == "Asset"){
    //    assetMenu(avatarKey);
    //}
    //else if (message == "Timer"){
    //    llMessageLinked(LINK_THIS, 3000, "TIMER MODE", avatarKey);
    //}
    //else if (messageButtonsTrimmed == buttonTitler) {
    //    titlerActive = !titlerActive;
    //    sendJSONCheckbox(buttonTitler, "", avatarKey, titlerActive);
    //    settingsMenu(avatarKey);
    //}
    //else if (messageButtonsTrimmed == buttonBattery) {
    //    batteryActive = !batteryActive;
    //    sendJSONCheckbox(buttonBattery, "", avatarKey, batteryActive);
    //    settingsMenu(avatarKey);
    //}
    else {
        sayDebug("doSettingsMenu ignoring "+message);
        llPlaySound(blurp, 1.0);
        llSleep(0.5);
    }

}

PunishmentLevelMenu(key avatarKey)
{
    // the zap Level Menu always includes checkboxes in front of the Zap word.
    // This is not a maximum zap radio button, it is checkboxes.
    // An inmate could be set to most severe zap setting only.
    string message = "Set Permissible Zap Levels";
    sayDebug("PunishmentLevelMenu zapJsonList before: "+(string)[allowZapLow, allowZapMed, allowZapHigh]);
    list buttons = [];
    buttons = buttons + menuCheckbox("Zap Low", allowZapLow);
    buttons = buttons + menuCheckbox("Zap Med", allowZapMed);
    buttons = buttons + menuCheckbox("Zap High", allowZapHigh);
    buttons = buttons + menuCheckbox("Objects", allowZapByObject);
    buttons = buttons + buttonBlank;
    buttons = buttons + buttonBlank;
    buttons = buttons + buttonSettings;
    //buttons = buttons + menuCheckbox("Vision", allowVision);
    setUpMenu("Punishments", avatarKey, message, buttons);
}

doSetPunishmentLevels(key avatarKey, string message)
{
    if ((avatarKey == llGetOwner()) | agentIsGuard(avatarKey))
    {
        sayDebug("set allowable zap level: "+message);
        sayDebug("doSetPunishmentLevels zapJsonList before: "+(string)[allowZapLow, allowZapMed, allowZapHigh]);
        if (message == "") {
            allowZapLow = TRUE;
            allowZapMed = TRUE;
            allowZapHigh = TRUE;
            allowZapByObject = TRUE;
        }
        else if (message == "Zap Low") {
            allowZapLow = !allowZapLow;
        } else if (message == "Zap Med") {
            allowZapMed = !allowZapMed;
        } else if (message == "Zap High") {
            allowZapHigh = !allowZapHigh;
        } else if (message == "Objects") {
            allowZapByObject = !allowZapByObject;
        }
        // If the wearer turns them all off, then high gets set.
        if (!(allowZapLow || allowZapMed || allowZapHigh)){
            allowZapHigh = TRUE;
        }
        zapJsonList = llList2Json(JSON_ARRAY, [allowZapLow, allowZapMed, allowZapHigh]);
        sayDebug("doSetPunishmentLevels zapJsonList after: "+(string)[allowZapLow, allowZapMed, allowZapHigh]);
        sendJSON("ZapLevels", zapJsonList, avatarKey);
        string ZapLevels = menuCheckbox("Low", allowZapLow) + "  " +
        menuCheckbox("Medium", allowZapMed) +  "  " +
        menuCheckbox("High", allowZapHigh) + "  " +
        menuCheckbox("Objects", allowZapByObject);
        llOwnerSay(llKey2Name(avatarKey)+" set your punishment levels to "+ZapLevels);
        sendJSONCheckbox("RLV", "ZapByObject", avatarKey, allowZapByObject);
    }
}

classMenu(key avatarKey)
{
    fixThreatAndClass();
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

fixThreatAndClass() {
    // Threat and Class are related.
    // Each class has threat levels that its members can be.
    // White : None Moderate
    // Pink: None Moderate
    // Red: None Moderate
    // Green: None Moderate Dangerous
    // Orange: None Moderate Dangerous
    // Blue: Moderate Dangerous Extreme
    // Black: Dangerous Extreme

    // First we set up integers that say whether each threat level is allowed for the class.
    canBeNone = class != "blue" & class != "black";
    canBeModerate = class != "black";
    canBeDangerous = class != "white" & class != "pink";
    canBeExtreme = class == "blue" | class == "black";

    // Then we check the threat.
    // Can't be none or Moderate becomes Dangerous.
    // Can't be Dangerous or Extreme becomes Moderate.
    if (threat == "None" & !canBeNone) {
        threat = "Dangerous";
    }
    if (threat == "Moderate" & !canBeModerate) {
        threat = "Dangerous";
    }
    if (threat == "Dangerous" & !canBeDangerous) {
        threat = "Moderate";
    }
    if (threat == "Extreme" & !canBeExtreme) {
        threat = "Moderate";
    }
}

threatMenu(key avatarKey) {
    fixThreatAndClass();
    string message = "Threat";
    list buttons = [];
    // Each button is made active or inactive based on the class.
    if (canBeNone == 1) {
        buttons = buttons + menuRadioButton("None", threat);
    }
    if (canBeModerate == 1) {
        buttons = buttons + menuRadioButton("Moderate", threat);
    }
    if (canBeDangerous == 1) {
        buttons = buttons + menuRadioButton("Dangerous", threat);
    }
    if (canBeExtreme == 1) {
        buttons = buttons + menuRadioButton("Extreme", threat);
    }

    integer blanks = 3 - llGetListLength(buttons) % 3;
    if (blanks != 3) {
        integer i;
        for (i = 0; i < blanks; i = i + 1) {
            buttons = buttons + buttonBlank;
        }
    }
    buttons = buttons + buttonSettings;
    setUpMenu("Threat", avatarKey, message, buttons);
}

speechMenu(key avatarKey)
{
    integer itsMe = avatarKey == llGetOwner();
    integer locked = RLVlevel != RLVlevelOff;

    string message = buttonSpeech + "\n";
    list buttons = [];

    // assume we can do nothing
    integer doRenamer = FALSE;
    integer doBadWords = FALSE;
    integer doWordList = FALSE;
    integer doDisplayTok = FALSE;
    integer doPenalties = FALSE;
    //integer doGag = TRUE;

    // work out what menu items are available
    if (rlvPresent) {
        doWordList = TRUE;
        doPenalties = TRUE;
        if (itsMe) {
            doRenamer = TRUE;
        } else {
            message = message + "\Only the prisoner can turn on the renamer.";
        }
        if (itsMe | agentIsGuard(avatarKey)) {
            if (renamerActive) {
                doBadWords = TRUE;
                doDisplayTok = TRUE;
            } else {
                message = message + "\nBadWords and Display-Talk work only when Renamer is active.";
            }
        } else {
            message = message + "\nOnly a guard or the prisoner can turn on Bad Words or Displaytok.";
        }
    } else {
        message = message + "\nRenamer, BadWords, and Display-Talk work only when RLV is active.";
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
            if ((RLVlevel == "Hardcore" || RLVlevel == "Heavy")) {
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

    if (RLVlevel == "Heavy" | RLVlevel == "Hardcore") {
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
    sendJSON("Database", "setcharacter", avatarKey);
}

characterSetCrimeTextBox(key avatarKey) {
    // tell database to give the character set Crime TextBox
    sendJSON("Database","setcrime",avatarKey); 
}

characterSetNameTextBox(key avatarKey) {
    // tell database to give the character set Crime TextBox
    sendJSON("Database","setname",avatarKey); 
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
        RLVlevel = RLVlevelOff;
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
            sendJSON("Menu", menuMain, avatarKey);
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
            sendJSON("Class", class, avatarKey);
            llOwnerSay(name+" updated your class to "+class);
            settingsMenu(avatarKey);
        }
        // Mood
        else if (menuIdentifier == "Mood") {
            sayDebug("listen: Mood:"+messageButtonsTrimmed);
            mood = messageButtonsTrimmed;
            sendJSON("Mood", mood, avatarKey);
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
            sendJSON("Threat", threat, avatarKey);
            llOwnerSay(name+" updated your threat level to to "+threat);
            settingsMenu(avatarKey);
        }
        else {
            sayDebug("ERROR: did not process menuIdentifier "+menuIdentifier);
        }
    }

    link_message(integer sender_num, integer num, string json, key avatarKey){
        // We listen in on link status messages and pick the ones we're interested in
        //sayDebug("link_message json "+json);
        assetNumber = getJSONstring(json, "AssetNumber", assetNumber);
        crime = getJSONstring(json, "Crime", crime);
        class = getJSONstring(json, "Class", class);
        threat = getJSONstring(json, "Threat", threat);
        mood = getJSONstring(json, "Mood", mood);
        RLVlevel = getJSONstring(json, "LockLevel", RLVlevel);
        renamerActive = getJSONinteger(json, "renamerActive", renamerActive);
        badWordsActive = getJSONinteger(json, "badWordsActive", badWordsActive);
        DisplayTokActive = getJSONinteger(json, "DisplayTokActive", DisplayTokActive);
        rlvPresent = getJSONinteger(json, "rlvPresent", rlvPresent);
        if (!rlvPresent) {
            renamerActive = FALSE;
            badWordsActive = FALSE;
            DisplayTokActive = FALSE;
        }

        if(getJSONstring(json, "Menu", "") == buttonSettings)
        {
            menuIdentifier = buttonSettings;
            settingsMenu(avatarKey);
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
