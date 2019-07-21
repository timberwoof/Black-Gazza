// RoleWizard.lsl
// Black Gazza RPG Role Setter Upper Wizard
// Timberwoof Lupindo
// July 2019

// Takes the user through a series of questions to set up one character in the new database.
// Resulting data is sent as an upsert operation to the new database.
// JSON looks like {"name":"Flimbertwoof Utini","crime":"Stealing hubcaps off landspeeeders","class":"orange","threat":"Moderate"}

// reference: useful unicode characters
// https://unicode-search.net/unicode-namesearch.pl?term=CIRCLE

integer OPTION_DEBUG = 1;

integer menuChannel = 0;
integer menuListen = 0;

list PlayerRoleNames = ["inmate", "guard", "medic", "mechanic", "robot", "k9", "bureaucrat"];
list AssetPrefixes = ["P", "G", "M", "X", "R", "K", "B"];
list PlayerRoleKeys = ["inmate", "name_text", "crime_text", "class", "threat", "***inmate", 
                        "guard", "name_text", "rank", "***guard"];
list playerRoleKeyValues = [];

list PrisonerClasses = ["white", "pink", "red", "orange", "green", "blue", "black"];
list PrisonerClassesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental"];
list PrisonerThreatLevels = ["None", "Moderate", "Dangerous", "Extreme"];
list MedicalSpecialties = ["General", "Surgery", "Neurology", "Psychiatry", "Pharmacology"];
list RoleKeyValues = []; // set up during initilizaitons

string playerRole = "Unknown";
string prisonerCrime = "Unknown";
string assetNumber = "Unknown";
string threatLevel = "None";

string textBoxParameter = "";
key databaseQuery;

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
    menuChannel = -(llFloor(llFrand(10000)+1000));
    llDialog(avatarKey, message, buttons, menuChannel);
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
}

setUpTextBox(key avatarKey, string message) {
    menuChannel = -(llFloor(llFrand(10000)+1000));
    llTextBox(avatarKey, message, menuChannel);
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
    //sayDebug("upsertRoleKeyValue "+theKey+"="+theValue);
    // sets global PlayerRoleKeyValues
    integer where = -1;
    integer i;
    for (i = 0; i < llGetListLength(playerRoleKeyValues); i++) {
        string keyValue = llList2String(playerRoleKeyValues, i);
        integer theIndex = llSubStringIndex(keyValue, theKey);
        //sayDebug("upsertRoleKeyValue keyValue:"+keyValue+ " theIndex:"+(string)theIndex);
        if (theIndex == 0) {
            where = i;
            }
        }
        
    // generate the new key-value pair
    string newKeyValue = theKey + "=" + theValue;
    
    // is it in our list?
    if (where == -1) {
        // nope. Add it to the list.
        sayDebug("upsertRoleKeyValue adding "+newKeyValue);
        playerRoleKeyValues = playerRoleKeyValues + [newKeyValue];
    } else {
        // yup. Replace it.
        sayDebug("upsertRoleKeyValue updating "+newKeyValue);
        playerRoleKeyValues = llListReplaceList(playerRoleKeyValues, [newKeyValue], where, where);
    }
}

string getRoleKeyValue(string lookupKey) {
    sayDebug("getRoleKeyValue(\""+lookupKey+"\")");
    // gets something out of global PlayerRoleKeyValues
    string result = "";
    integer where = -1;
    integer i;
    for (i = 0; i < llGetListLength(playerRoleKeyValues); i++) {
        string onePair = llList2String(playerRoleKeyValues, i);
        list keyValue = llParseString2List(onePair, ["="], []);
        string thekey = llList2String(keyValue, 0);
        string thevalue = llList2String(keyValue, 1);
        //sayDebug("getRoleKeyValue retrieved onePair:"+onePair+ " keyValue:" + (string)keyValue + " thekey:" + thekey + " thevalue:" + thevalue);
        
        if (thekey == lookupKey){
            result = thevalue;        
        }
    }
    return result;
}

string CharacterInfoList() {
    sayDebug("CharacterInfoList");
    // Adds all the key-value pairs in PlayerRoleKeyValues to a string
    string message = "";
    integer i;
    for (i = 0; i < llGetListLength(playerRoleKeyValues); i++) {
        string onePair = llList2String(playerRoleKeyValues, i);
        list keyValue = llParseString2List(onePair, ["="], []);
        string thekey = llList2String(keyValue, 0);
        string thevalue = llList2String(keyValue, 1);
        //sayDebug("CharacterInfoList adding onePair:"+onePair+ " keyValue:" + (string)keyValue + " thekey:" + thekey + " thevalue:" + thevalue);
        message = message + thekey + ": " + thevalue + "\n";
    }
    return message;
}

keyMenu(key avatarKey, string playerRole) {
    sayDebug("keyMenu");
    // Gather up the additional keys for the playerRole
    string message = "Continue setting up your Black Gazza character. \n" +
    "Your setup so far: \n" + 
    CharacterInfoList() +
    "Next, choose additional parameters:";
    integer indexStart = llListFindList(PlayerRoleKeys, [playerRole]);
    integer indexEnd = llListFindList(PlayerRoleKeys, ["***"+playerRole]);
    list buttons = llList2List(PlayerRoleKeys, indexStart+1, indexEnd-1);
    buttons = buttons + ["Finish"];
    setUpMenu(avatarKey, message, buttons);
}

roleKeyDialog(key avatarKey, string parameterKey) {
    sayDebug("roleKeyDialog");
        // let player enter text or select from chocies
    // Some of these are free-form text; the keys end in "_text"
    // Some of these are picklists
    string message = "Continue setting up your Black Gazza character. \n";
    
    if (llSubStringIndex(parameterKey, "_text") > -1) {
        // get some freeform text
        textBoxParameter = llGetSubString(parameterKey, 0, -6);
        message = message + "Enter your " + textBoxParameter;
        setUpTextBox(avatarKey, message);
    } else {
        // pick from a picklist
        message = message + "Select a value for your " + parameterKey;
        
        // Gather up the additional keys for the playerRole
        integer indexStart = llListFindList(RoleKeyValues, [parameterKey]);
        integer indexEnd = llListFindList(RoleKeyValues, ["***"+parameterKey]);
        list buttons = llList2List(RoleKeyValues, indexStart+1, indexEnd-1);
        buttons = buttons + ["Finish"];
        setUpMenu(avatarKey, message, buttons);
    }
}

setRoleKeyValue(string theValue) {
    sayDebug("setRoleKeyValue("+theValue+")");
    // player has selected a key value; 
    // find out what it was a list of and upsert it in the player key-value pairs. 
    integer startIndex = llListFindList(RoleKeyValues,[theValue]);
    integer i;
    for (i = startIndex; i < llGetListLength(RoleKeyValues); i++) {
        string listItem = llList2String(RoleKeyValues, i);
        if (llSubStringIndex(listItem, "***") > -1) {
            string theKey = llGetSubString(listItem, 3, -1);
            upsertRoleKeyValue(theKey, theValue);
            i = 999; // break
        }
    }
}

setTextParameter(string message) {
    // sanitize message
    upsertRoleKeyValue(textBoxParameter, message);
    }    

string generateUpsertJson() {
    list values = [];
    integer i;
    for (i = 0; i < llGetListLength(playerRoleKeyValues); i++) {
        string onePair = llList2String(playerRoleKeyValues, i);
        list keyValue = llParseString2List(onePair, ["="], []);
        string thekey = llList2String(keyValue, 0);
        string thevalue = llList2String(keyValue, 1);
        values = values + [thekey, thevalue];
    }
    return llList2Json(JSON_OBJECT, values);
}

registerNewCharacter(key avatarKey) {
    upsertRoleKeyValue("identity",(string)avatarKey);
    string json = generateUpsertJson();
    sayDebug("registerNewCharacter:"+json);
    string URL = "https://api.blackgazza.com/asset/?identity=" + (string)avatarKey;
    databaseQuery = llHTTPRequest(URL,[HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/json"], json);
}
    
default
{
    state_entry()
    {
        sayDebug("state_entry");
        textBoxParameter = "";
        RoleKeyValues = ["class"] + PrisonerClasses + ["***class"] +
            ["threat"] + PrisonerThreatLevels + ["***threat"]; 

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
        sayDebug("listen message:"+message);
        
        if (llListFindList(PlayerRoleNames, [message]) > -1){
            playerRole = message;
            keyMenu(avatarKey, playerRole);
        }
            
        else if (llListFindList(PlayerRoleKeys, [message]) > -1){
            roleKeyDialog(avatarKey, message);
        }
        
        else if (llListFindList(RoleKeyValues, [message]) > -1) {
            setRoleKeyValue(message);
            keyMenu(avatarKey, playerRole);
        }
        
        else if (message == "Finish") {
            registerNewCharacter(avatarKey);
        }
        
        else {
            setTextParameter(message);
            keyMenu(avatarKey, playerRole);
        }
    }

    timer() 
    {
        llListenRemove(menuListen);
        menuListen = 0;    
    }
    
    http_response(key request_id, integer status, list metadata, string message)
    // handle the response from the crime database
    {
        sayDebug("http_response status:"+(string)status);
        sayDebug(message);
    }

}
