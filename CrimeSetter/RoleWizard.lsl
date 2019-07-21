// RoleWizard.lsl
// Black Gazza RPG Role Setter Upper Wizard
// Timberwoof Lupindo
// July 2019

// Takes the user through a series of questions to set up one character in the new database.
// Resulting data is sent as an upsert operation to the new database.

// reference: useful unicode characters
// https://unicode-search.net/unicode-namesearch.pl?term=CIRCLE

integer OPTION_DEBUG = 1;

integer menuChannel = 0;
integer menuListen = 0;

list PlayerRoleNames = ["inmate", "guard", "medic", "mechanic", "robot", "k9", "bureaucrat"];
list AssetPrefixes = ["P", "G", "M", "X", "R", "K", "B"];
list PlayerRoleKeys = ["inmate", "name_text", "crime_text", "class", "threat", "inmate***", 
                        "guard", "name_text", "rank", "guard***"];
list PlayerRoleKeyValues = [];

list prisonerClasses = ["white", "pink", "red", "orange", "green", "blue", "black"];
list prisonerClassesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental"];
list prisonerThreatLevels = ["None", "Moderate", "Dangerous", "Extreme"];
list medicalSpecialties = ["General", "Surgery", "Neurology", "Psychiatry", "Pharmacology"];

string playerRole = "Unknown";
string prisonerCrime = "Unknown";
string assetNumber = "Unknown";
string threatLevel = "None";

key approveAvatar;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,message);
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
    string completeMessage = assetNumber + " Collar: " + message;
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

mainMenu(key avatarKey) {
    sayDebug("mainMenu");
    string message = "Welcome to the Black Gazza RPG Role Setter Upper Wizard. " +
    "Set up a Black Gazza character for your Second Life account. " + 
    "First, choose your Character Class:";
    setUpMenu(avatarKey, message, PlayerRoleNames);
}

upsertRoleKeyValue(string theKey, string theValue) {
    sayDebug("upsertRoleKeyValue "+theKey+"="+theValue);
    // sets global PlayerRoleKeyValues
    integer where = -1;
    integer i;
    for (i = 0; i < llGetListLength(PlayerRoleKeyValues); i++) {
        string keyValue = llList2String(PlayerRoleKeyValues, i);
        integer theIndex = llSubStringIndex(keyValue, theKey);
        sayDebug("upsertRoleKeyValue keyValue:"+keyValue+ " theIndex:"+(string)theIndex);
        if (theIndex == 0) {
            where = i;
            }
        }
        
    // generate the new key-value pair
    string newKeyValue = theKey + "=" + theValue;
    
    // is it in our list?
    if (where == -1) {
        // nope. Add it to the list.
        PlayerRoleKeyValues = PlayerRoleKeyValues + [newKeyValue];
    } else {
        // yup. Replace it.
        PlayerRoleKeyValues = llListReplaceList(PlayerRoleKeyValues, [newKeyValue], where, where);
    }
}

string CharacterInfoList() {
    // Adds all the key-value pairs in PlayerRoleKeyValues to a string
    string message = "";
    integer i;
    for (i = 0; i < llGetListLength(PlayerRoleKeyValues); i++) {
        string onePair = llList2String(PlayerRoleKeyValues, i);
        list keyValue = llParseString2List(onePair, ["="], []);
        string thekey = llList2String(keyValue, 0);
        string thevalue = llList2String(keyValue, 1);
        //sayDebug("CharacterInfoList adding onePair:"+onePair+ " keyValue:" + (string)keyValue + " thekey:" + thekey + " thevalue:" + thevalue);
        message = message + thekey + ": " + thevalue + "\n";
    }
    return message;
}

keyMenu(key avatarKey, string playerRole) {
    // Gather up the additional keys for the playerRole
    // Some of these are free-form text
    // Some of these are picklists
    integer indexStart = llListFindList(PlayerRoleKeys, [playerRole]);
    integer indexEnd = llListFindList(PlayerRoleKeys, [playerRole+"***"]);
    string message = "Continue setting up your Black Gazza character. \n" +
    "Your setup so far: \n" + 
    CharacterInfoList() +
    "Next, choose additional parameters:";
    list buttons = llList2List(PlayerRoleKeys, indexStart+1, indexEnd-1);
    buttons = buttons + ["Finish"];
    setUpMenu(avatarKey, message, buttons);
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
    }

    touch_start(integer total_number)
    {
        sayDebug("touch_start");
        key avatarKey  = llDetectedKey(0); 
        upsertRoleKeyValue("name_text", llKey2Name(avatarKey));
        mainMenu(avatarKey);

    }
    
    listen( integer channel, string name, key avatarKey, string message ){
        llListenRemove(menuListen);
        menuListen = 0;
        llSetTimerEvent(0);
        string messageButtonsTrimmed = llStringTrim(llGetSubString(message,2,11), STRING_TRIM);
        sayDebug("listen message:"+message+" messageButtonsTrimmed:"+messageButtonsTrimmed);
        
        if (llListFindList(PlayerRoleNames, [message]) > -1){
            playerRole = message;
            keyMenu(avatarKey, playerRole);
            }
    }

    timer() 
    {
        llListenRemove(menuListen);
        menuListen = 0;    
    }
}
