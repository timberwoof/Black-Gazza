// CrimeSetter2
// Allow an inmate to set their Crimes and Character Names in the database.
// Manages six sets of UUID, Crime, Name
// Timberwoof Lupindo, March 2024


key Sound_Open = "482b14cb-ff89-178a-b3f3-ee0e9a403b24";
key Sound_Close = "375397f6-531c-aa00-275f-caeb66c56e71";
key userKey;

integer DEBUG = TRUE;
sayDebug(string message) {
    if (DEBUG) {
        llWhisper(0, message);
        llSetText(message, <1,1,1>,1);
    }
}

// *************************'
// DATABASE 

string URL_BASE = "http://sl.blackgazza.com/";
string URL_READ = "read_inmate.cgi?key=";
string URL_ADD = "add_inmate.cgi?key=";
key crimeRequest;

// These lists are 1-based, numbered 1-6
string myQueryStatus;
list databaseRequests = ["", "", "", "", "", "", ""]; // 1-based so 0 is unassigned
list assetNumberList = ["P-00000","","","","","",""]; // 1-based so 0 is unassigned
list crimeList = ["","","","","","",""];  // 1-based so 0 is unassigned
list nameList = ["","","","","","",""];  // 1-based so 0 is unassigned
list sentenceList = ["0","0","0","0","0","0","0"]; // it is not used in this collar but i decided to keep it
string tempCrimes = "";

string assetNumber(integer index) {
    return llList2String(assetNumberList, index);
}

string crime(integer index) {
    return llList2String(crimeList, index);
}

string name(integer index) {
    return llList2String(nameList, index);
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
// Parameter iSlot determines which character to get.
sendReadDatabaseQuery(key avatarKey, integer index) {
    sayDebug("sendReadDatabaseQuery "+(string)index);
    string URL = URL_BASE + URL_READ + AgentKeyWithRole((string)llGetOwner(),index);
    sayDebug("sendReadDatabaseQuery URL:"+URL);
    key databaseQuery = llHTTPRequest(URL,[],""); // append reqest_id for use it later in responder event
    databaseRequests = llListReplaceList(databaseRequests, [databaseQuery], index, index);
}

gatherInmateRecords(key avatarKey) {
    sayDebug("gatherInmateRecords");
    integer index;
    for (index = 1; index <=6; index = index + 1) {
        sendReadDatabaseQuery(avatarKey, index);
    }
    
}



// *************************'
// MENU 

string menuIdentifier;
string menuMain = "Main";
string readDB = "Read DB";
key menuAgentKey;
integer menuChannel;
integer menuListen;
integer crimeSetChannel = 0;
integer crimeSetListen;

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

    sayDebug("menu access");
    menuIdentifier = identifier;
    menuAgentKey = avatarKey; // remember who clicked
    menuChannel = -(llFloor(llFrand(10000)+1000));
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
    llDialog(avatarKey, message, buttons, menuChannel);
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


main_menu(key avatarKey) {
    string message = "Crime Setter";
    list buttons = [];
    buttons = buttons + [readDB];
    setUpMenu(menuMain, avatarKey, message, buttons);

}

doMainMenu(key avatarKey, string message) {
    sayDebug("doMainMenu "+message);
    
    if (message == readDB) {
        gatherInmateRecords(avatarKey);
    }
}

characterMenu(key avatarKey) {
    sayDebug("characterMenu()");
    list buttons = [];
    integer i = 0;
    for (i=1; i<7; i = i + 1) {
        string assetNumber = llList2String(assetNumberList, i);
        if (assetNumber != "") {
            buttons = buttons + [assetNumber];
        }
    }
    setUpMenu(llGetOwner(), avatarKey, "Choose your Asset Number", buttons);
}

setCharacterCrimes(key avatarKey, integer index)
{
    string message = assetNumber(index) + "\nCharacter Name: " + name(index)  + "\nCurrent Crimes: " + crime(index) + "\nPlease set new Crimes: ";
    crimeSetChannel = -(llFloor(llFrand(1000)+1000));
    crimeSetListen = llListen(crimeSetChannel, "", avatarKey, "");
    llSetTimerEvent(30);
    llTextBox(avatarKey, message, crimeSetChannel);
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
        userKey = NULL_KEY;
    }

    touch_start(integer total_number)
    {
        key detectedKey = llDetectedKey(0);
        if (userKey == NULL_KEY) {
            userKey = detectedKey;
            main_menu(userKey);
        } else {
            if (userKey == detectedKey) {
                main_menu(userKey);
            } else {
                llSay(0, "This unit is in use by someoe else.");
            }
        }
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

        // display the menu item
        if (llGetSubString(message,1,1) == " ") {
            sayDebug(messageButtonsTrimmed);
        } else {
            sayDebug(message);
        }

        // reset the menu setup
        llListenRemove(menuListen);
        menuListen = 0;
        menuChannel = 0;
        menuAgentKey = "";
        llSetTimerEvent(0);

        // Main button
        if (message == menuMain) {
            main_menu(avatarKey);
        }
        
        if (message == readDB) {
            gatherInmateRecords(avatarKey);
        }

        if (message == "Close") {
            return;
        }

    }

    http_response(key request_id, integer status, list metadata, string message)
    // handle a response from the crime database
    {
        // find out which of the pending requests this is
        integer index = llListFindList(databaseRequests, [request_id]);
        if (index == -1) return; // skip response if this script did not require it

        // if response status code not equal 200(OK)
        // then remove item with request_id from list and exit
        if (status != 200)
        {
            sayDebug("DB Error "+(string)status);
            databaseRequests = llListReplaceList(databaseRequests, [0], index, index);
            crimeList = llListReplaceList(crimeList, ["uninitialized"], index, index);
            nameList = llListReplaceList(nameList, ["uninitialized"], index, index);
            assetNumberList = llListReplaceList(assetNumberList, ["P-00000"], index, index);
            return;
        }

        // decode the response which looks like
        // Timberwoof Lupindo,0,Piracy; Illegal Transport of Biogenics,284ba63f-378b-4be6-84d9-10db6ae48b8d,P-60361

        // Fix missing data in the response
        integer whereTwoCommas = llSubStringIndex(message, ",,");
        if (whereTwoCommas > 1) {
            message = llInsertString( message, whereTwoCommas, ",Unrecorded," );
        }
        whereTwoCommas = llSubStringIndex(message, ",,");
        if (whereTwoCommas > 1) {
            message = llInsertString( message, whereTwoCommas, ",Unrecorded," );
        }
        sayDebug("http_response message="+message);

        // extract the individual pieces
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

        assetNumberList = llListReplaceList(assetNumberList, [theAssetNumber], index, index);
        crimeList = llListReplaceList(crimeList, [theCrime], index, index);
        nameList = llListReplaceList(nameList, [theName], index, index);
        sentenceList = llListReplaceList(sentenceList, [mysteriousNumber], index, index);
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
