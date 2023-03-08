// database2.lsl
// interim connectivity for Collar 4 to the old database.
// This has the same commections to the rest of the collar as database.lsl but it connects to the current db.

// Database.lsl
// All interactions with the external database
// Timberwoof Lupindo
// July 2019, February 2020
// version: 2023-03-08

integer OPTION_DEBUG = FALSE;
key databaseQuery;
string myQueryStatus;

string start_date;
string unassignedAsset = "P-00000";
string class;

string URL_BASE = "http://sl.blackgazza.com/";
string URL_READ = "read_inmate.cgi?key=";
string URL_ADD = "add_inmate.cgi?key=";
key crimeRequest;
integer characterSlot = 1;

integer menuChannel;
integer menuListen;

list assetNumberList = ["P-00000","","","","","",""]; // 1-based so 0 is unassigned
list crimeList = ["","","","","","",""];  // 1-based so 0 is unassigned
list nameList = ["","","","","","",""];  // 1-based so 0 is unassigned

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Database: "+message);
    }
}

string assetNumber(integer iSlot) {
    return llList2String(assetNumberList, iSlot);
}

string crime(integer iSlot) {
    return llList2String(crimeList, iSlot);
}

string name(integer iSlot) {
    return llList2String(nameList, iSlot);
}

// convert agent key to database key
string AgentKeyWithRole(string agentKey, integer slot) {
// if the slot number is 2 or greater,
// sticks the character key into the agent UUID
    string result = agentKey;
    if (slot > 1) {
        string after = llGetSubString(agentKey, 0, 22);
        string before = llGetSubString(agentKey, 24, -1);
        result = after + (string)slot + before;
    }
    return result;
}

// fire off a request to the crime database for this wearer.
// Reads global iSlot to determine which character to get.
sendDatabaseQuery(integer iSlot) {
    if (llGetAttached() != 0) {
        displayCentered("Accessing DB");
        string URL = "http://sl.blackgazza.com/read_inmate.cgi?key=" + AgentKeyWithRole((string)llGetOwner(),iSlot);
        sayDebug("sendDatabaseQuery:"+URL);
        databaseQuery = llHTTPRequest(URL,[],"");
        characterSlot = iSlot;
    } else {
        sayDebug("sendDatabaseQuery unattached");
        sendJSON("assetNumber", assetNumber(characterSlot), llGetOwner());
        sendJSON("crime", crime(characterSlot), llGetOwner());
        sendJSON("name", name(characterSlot), llGetOwner());
    }
}

setCharacter() {
    sayDebug("setCharacter");
    sendDatabaseQuery(1);
}

displayCentered(string message) {
    string json = llList2Json(JSON_OBJECT, ["Display",message]);
    llMessageLinked(LINK_THIS, 0, json, "");
}

sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
    }
    
string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
    }
    return result;
}

setUpMenu(key avatarKey, string message, list buttons)
// wrapper to do all the calls that make a simple menu dialog.
// - adds required buttons such as Close or Main
// - displays the menu command on the alphanumeric display
// - sets up the menu channel, listen, and timer event
// - calls llDialog
// parameters:
// avatarKey - uuid of who clicked
// message - text for top of blue menu dialog
// buttons - list of button texts
{
    sayDebug("setUpMenu");
    
    buttons = buttons + ["Main"];
    buttons = buttons + ["Main"];
    buttons = buttons + ["Close"];
    
    sendJSON("DisplayTemp", "menu access", avatarKey);
    string completeMessage = assetNumber(characterSlot) + " Collar: " + message;
    menuChannel = -(llFloor(llFrand(10000)+1000));
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
    llDialog(avatarKey, completeMessage, buttons, menuChannel);
}

characterMenu() {
    sayDebug("characterMenu()");
    list buttons = [];
    integer i = 0;
    for (i=1; i<7; i = i + 1) {
        string assetNumber = llList2String(assetNumberList, i);
        if (assetNumber != "") {
            buttons = buttons + [assetNumber];
        }
    }
    setUpMenu(llGetOwner(), "Choose your Asset Number", buttons);
}
    
default
{
    state_entry() // reset
    {
        sayDebug("state_entry");
        sendDatabaseQuery(1);
        sayDebug("state_entry done");
    }
    
    attach(key avatar)
    {
        sayDebug("attach");
        sendDatabaseQuery(1);
        sayDebug("attach done");
    }

    http_response(key request_id, integer status, list metadata, string message)
    // handle the response from the crime database
    {
        displayCentered("status "+(string)status);
        string assetNumber = "P-00000";
        string theCrime = "Unregistered";
        string theName = llGetOwner();
        if (status == 200) {
            // decode the response
            // looks like
            // Timberwoof Lupindo,0,Piracy; Illegal Transport of Biogenics,284ba63f-378b-4be6-84d9-10db6ae48b8d,P-60361
            integer whereTwoCommas = llSubStringIndex(message, ",,");
            if (whereTwoCommas > 1) {
                message = llInsertString( message, whereTwoCommas, ",Unrecorded," );
            }
            whereTwoCommas = llSubStringIndex(message, ",,");
            if (whereTwoCommas > 1) {
                message = llInsertString( message, whereTwoCommas, ",Unrecorded," );
            }
            sayDebug("http_response message="+message);
            
            list returnedStuff = llParseString2List(message, [","], []);
            string theName = llList2String(returnedStuff, 0);
            string mysteriousNumber = llList2String(returnedStuff, 1);
            string theCrime = llList2String(returnedStuff, 2);
            string avatarKey = llList2String(returnedStuff, 3);
            string theAssetNumber = llList2String(returnedStuff, 4);
            
            sayDebug("name:"+theName);
            sayDebug("number:"+mysteriousNumber);
            sayDebug("crime:"+theCrime);
            sayDebug("key:"+avatarKey);
            sayDebug("assetNumber:"+theAssetNumber);
            
            assetNumberList = llListReplaceList(assetNumberList, [theAssetNumber], characterSlot, characterSlot);
            crimeList = llListReplaceList(crimeList, [theCrime], characterSlot, characterSlot);
            nameList = llListReplaceList(nameList, [theName], characterSlot, characterSlot);
            
            if (characterSlot < 6) {
                characterSlot = characterSlot + 1;
                sendDatabaseQuery(characterSlot);
            } else {
                characterSlot = 1;
                
                sayDebug("htpresponse assetNumberList: "+(string)assetNumberList);
                sayDebug("htpresponse crimeList: "+(string)crimeList);
                sayDebug("htpresponse nameList: "+(string)nameList);
                
                characterMenu();
            }
        } else {
            displayCentered("error "+(string)status);
            assetNumber = "ERR-" + (string)status;
        }
    }
    
    link_message(integer sender_num, integer num, string json, key id){
        string request = getJSONstring(json, "database", "");
        if (request == "getupdate") sendDatabaseQuery(characterSlot);
        if (request == "setcharacter") setCharacter();
    }
    
    listen(integer channel, string name, key id, string text) {
        if (channel == menuChannel) {
            characterSlot = llListFindList(assetNumberList, [text]);
            sendJSON("assetNumber", assetNumber(characterSlot), llGetOwner());
            sendJSON("crime", crime(characterSlot), llGetOwner());
            sendJSON("name", name(characterSlot), llGetOwner());
            llListenRemove(menuListen);
            menuChannel = 0;
        }
    }
    
    timer() {
        if (menuListen != 0) {
            llListenRemove(menuListen);
            menuChannel = 0;
        }
    }
}
