// getCrimeSetter2
// Allow an inmate to set their getCrimes and Character Names in the database.
// Manages six sets of UUID, getCrime, Name
// Timberwoof Lupindo, March 2024


key Sound_Open = "482b14cb-ff89-178a-b3f3-ee0e9a403b24";
key Sound_Close = "375397f6-531c-aa00-275f-caeb66c56e71";
key userKey;

integer DEBUG = FALSE;
sayDebug(string message) {
    if (DEBUG) {
        llWhisper(0, message);
        llSetText(message, <1,1,1>,1);
    } else {
        llSetText("", <1,1,1>,1);
    }
}

// *************************'
// DATABASE 

string URL_BASE = "http://sl.blackgazza.com/";
string URL_READ = "read_inmate.cgi?key=";
string URL_ADD = "add_inmate.cgi?key=";
string GET = "GET";
string PUT = "PUT";

// These lists are 1-based, numbered 1-6
string queryType;
list databaseRequestList; // 1-based so 0 is unassigned
list assetNumberList; // 1-based so 0 is unassigned
list crimeList;  // 1-based so 0 is unassigned
list charNameList;  // 1-based so 0 is unassigned
list sentenceList; // it is not used in this collar but i decided to keep it
integer lists_populated;
integer currentIndex;

initLists() {
    userKey = NULL_KEY;
    currentIndex = 0;
    databaseRequestList = [NULL_KEY, "", "", "", "", "", ""];
    assetNumberList = ["P-00000","","","","","",""];
    crimeList = ["DUMMY","","","","","",""];
    charNameList = ["DUMMY","","","","","",""];
    sentenceList = ["-999","0","0","0","0","0","0"];
    lists_populated = FALSE;
}

string getAssetNumber(integer index) {
    return llList2String(assetNumberList, index);
}

string getCrime(integer index) {
    return llList2String(crimeList, index);
}

string getCharName(integer index) {
    return llList2String(charNameList, index);
}

string getSentence(integer index) {
    return llList2String(sentenceList, index);
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

// fire off a request to the getCrime database for this wearer.
// Parameter iSlot determines which character to get.
sendReadDatabaseQuery(key avatarKey, integer index) {
    //sayDebug("sendReadDatabaseQuery "+(string)index);
    string URL = URL_BASE + URL_READ + AgentKeyWithRole(avatarKey, index);
    //sayDebug("sendReadDatabaseQuery URL:"+URL);
    queryType = GET;
    key databaseQuery = llHTTPRequest(URL,[],""); // append reqest_id for use it later in responder event
    sayDebug("sendReadDatabaseQuery sent query " + (string)databaseQuery);
    databaseRequestList = llListReplaceList(databaseRequestList, [databaseQuery], index, index);
}

// what the collar give does:
// llHTTPRequest(URL+"add_inmate.cgi?key="+(string)id+"&name="+name+"&number=P-foobar",[],"");
// what the crime setter does: 
// sMsg = llEscapeURL(llDumpList2String(llParseStringKeepNulls((sMsg = "")  +  sMsg, [";"], []), ","));
// string name = llEscapeURL(llKey2Name(user_key));
// string final_url = URL + URL_ADD + AgentKeyWithRole(user_key, iSlot) + "&name=" + name + "&crime=" + sMsg + "&sentence=0";
// debug("Database_Save " + (string)iSlot + " " + final_url);
// llHTTPRequest(final_url, [], "");

// fire off a request to the getCrime database for this wearer.
// Parameter iSlot determines which character to get.
sendWriteDatabaseQuery(key avatarKey, integer index, string charName, string crime, string sentence) {
    sayDebug("sendWriteDatabaseQuery ("+(string)index+", '"+charName+"', '"+crime+"')");
    string URL = URL_BASE + URL_ADD + AgentKeyWithRole(avatarKey, index) + 
    "&name=" + llEscapeURL(charName) + 
    "&crime=" + llEscapeURL(crime) + 
    "&sentence=" + (string)sentence;
    sayDebug("sendWriteDatabaseQuery URL:"+URL);
    queryType = PUT;
    key databaseQuery = llHTTPRequest(URL, [], "");
    sayDebug("sendWriteDatabaseQuery sent query " + (string)databaseQuery);
    databaseRequestList = llListReplaceList(databaseRequestList, [databaseQuery], index, index);
}

setCharName(key avatarKey, integer index, string newCharName) {
    sayDebug("setName ("+(string)index+", "+newCharName+")");
    sendWriteDatabaseQuery(avatarKey, index, newCharName, getCrime(index), getSentence(index));
}

setCrime(key avatarKey, integer index, string newCrime) { 
    sayDebug("setCrime ("+(string)index+", "+newCrime+")");
    sendWriteDatabaseQuery(avatarKey, index, getCharName(index), newCrime, getSentence(index));
}

setSentence(key avatarKey, integer index, string newSentence) { 
    sayDebug("setSentence ("+(string)index+", "+(string)newSentence+")");
    sendWriteDatabaseQuery(avatarKey, index, getCharName(index), getCrime(index), newSentence);
}

handleHttpResponse(integer index, string message) {
        sayDebug("handleHttpResponse message="+message);
        // decode the response which looks like
        // Timberwoof Lupindo,0,Piracy; Illegal Transport of Biogenics,284ba63f-378b-4be6-84d9-10db6ae48b8d,P-60361

        // Fix missing data in the response
        integer whereTwoCommas = llSubStringIndex(message, ",,");
        if (whereTwoCommas > 1) {
            message = llInsertString(message, whereTwoCommas, ",Unrecorded," );
        }
        whereTwoCommas = llSubStringIndex(message, ",,");
        if (whereTwoCommas > 1) {
            message = llInsertString(message, whereTwoCommas, ",Unrecorded," );
        }

        // extract the individual pieces
        list returnedStuff = llParseString2List(message, [","], []);
        string theName = llList2String(returnedStuff, 0);
        string mysteriousNumber = llList2String(returnedStuff, 1);
        string theCrime = llList2String(returnedStuff, 2);
        string theAvatarKey = llList2String(returnedStuff, 3);
        string theAssetNumber = llList2String(returnedStuff, 4);

        //sayDebug("name:"+theName);
        //sayDebug("number:"+mysteriousNumber);
        //sayDebug("crime:"+theCrime);
        //sayDebug("key:"+theAvatarKey);
        //sayDebug("assetNumber:"+theAssetNumber);
        llWhisper(0, "DB returns "+theAssetNumber+" "+theName+" - "+theCrime+": "+mysteriousNumber);
        
        if (theAvatarKey == AgentKeyWithRole(userKey, index)) {
            assetNumberList = llListReplaceList(assetNumberList, [theAssetNumber], index, index);
            crimeList = llListReplaceList(crimeList, [theCrime], index, index);
            charNameList = llListReplaceList(charNameList, [theName], index, index);
            sentenceList = llListReplaceList(sentenceList, [mysteriousNumber], index, index);
            lists_populated = TRUE;
        } else {
            sayDebug("Error: returned agent key did not match userKey");
        }
}

gatherInmateRecords(key avatarKey) {
    sayDebug("gatherInmateRecords");
    integer index;
    for (index = 1; index <=6; index = index + 1) {
        sendReadDatabaseQuery(avatarKey, index);
    }
}

listInmateRecords(key avatarKey, integer currentIndex) {
    llWhisper(0, "Collar Database Records for "+llGetUsername(avatarKey)+" = "+llGetDisplayName(avatarKey));
    integer index;
    for (index = 1; index <= 6; index = index + 1) {
        string tag = "  ";
        if (index == currentIndex) {
            tag = "* ";
        }
        llWhisper(0, tag + getAssetNumber(index) + ": " + getCrime(index));
    }
}

// *************************'
// MENU 

string menuIdentifier;
string MENU_MAIN = "Main";
string READ_DB = "Read DB";
string SELECT_CHAR = "Select";
string SET_NAME = "Set Name";
string SET_CRIME = "Set Crime";
string SET_SENTENCE = "Set Years";
string LIST = "List";
string characterChoice = "characterChoice";
key menuAgentKey;
integer menuChannel;
integer menuListen;
integer getSetTextChannel = 0;
integer getSetTextListen;

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

    if (identifier != MENU_MAIN) {
        buttons = buttons + [MENU_MAIN];
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
    string message = "getCrime Setter\n";
   
    if (currentIndex == 0) {
        message = message + "No character is selected.\n";
    } else {
        message = message + "Selected Caracter:\n";
        message = message + "Asset Number: " + getAssetNumber(currentIndex) + "\n";
        message = message + "Name: " + getCharName(currentIndex) + "\n";
        message = message + "Crime: " + getCrime(currentIndex);
    } 
    
    list buttons = [];
    buttons = buttons + [READ_DB];
    buttons = buttons + menuButtonActive(SELECT_CHAR, lists_populated);
    buttons = buttons + menuButtonActive(LIST, lists_populated);
    buttons = buttons + menuButtonActive(SET_CRIME, (currentIndex != 0));
    //buttons = buttons + [SET_SENTENCE];
    setUpMenu(MENU_MAIN, avatarKey, message, buttons);

}

string headerForGetTextDialog(key avatarKey, integer index) {
    return getAssetNumber(index) + "\n"+
    "Character Name: " + getCharName(index)  + "\n"+
    "Current Crime: " + getCrime(index) + "\n"+
    "Current Sentence: " + getSentence(index) + "\n";
}

getCrimeFromPlayer(key avatarKey, integer index)
{
    menuIdentifier = SET_CRIME;
    string message = headerForGetTextDialog(avatarKey, index);
    message = message + "Please set new Crime: ";
    getSetTextChannel = -(llFloor(llFrand(1000)+1000));
    getSetTextListen = llListen(getSetTextChannel, "", avatarKey, "");
    llSetTimerEvent(30);
    llTextBox(avatarKey, message, getSetTextChannel);
}

getNameFromPlayer(key avatarKey, integer index)
{
    menuIdentifier = SET_NAME;
    string message = headerForGetTextDialog(avatarKey, index);
    message = message +"Please set new Name: ";
    getSetTextChannel = -(llFloor(llFrand(1000)+1000));
    getSetTextListen = llListen(getSetTextChannel, "", avatarKey, "");
    llSetTimerEvent(30);
    llTextBox(avatarKey, message, getSetTextChannel);
}

getSentenceFromPlayer(key avatarKey, integer index)
{
    menuIdentifier = SET_SENTENCE;
    string message = headerForGetTextDialog(avatarKey, index);
    message = message + "Please set new Sentence: ";
    getSetTextChannel = -(llFloor(llFrand(1000)+1000));
    getSetTextListen = llListen(getSetTextChannel, "", avatarKey, "");
    llSetTimerEvent(30);
    llTextBox(avatarKey, message, getSetTextChannel);
}

doMainMenu(key avatarKey, string message) {
    sayDebug("doMainMenu "+message);
    
        // Main button
        if (message == MENU_MAIN) {
            main_menu(avatarKey);
        } else if (message == READ_DB) {
            // query database for the character records
            gatherInmateRecords(avatarKey);
        } else if (message == SELECT_CHAR) {
            // present player with menu of asset numbers and names
            characterMenu(avatarKey);
        } else if (message == SET_NAME) {
            getNameFromPlayer(avatarKey, currentIndex);
        } else if (message == SET_CRIME) {
            getCrimeFromPlayer(avatarKey, currentIndex);
        } else if (message == SET_SENTENCE) {
            getSentenceFromPlayer(avatarKey, currentIndex);
        } else if (message == LIST) {
            listInmateRecords (avatarKey, currentIndex);
        } else if (message == "Close") {
            initLists();
        } else if (menuIdentifier == SELECT_CHAR) {
            // set the specific character we will work with 
            currentIndex = (integer)message;
            main_menu(avatarKey);
        } else if (menuIdentifier == SET_NAME) {
            setCharName(avatarKey, currentIndex, message);
        } else if (menuIdentifier == SET_CRIME) {
            setCrime(avatarKey, currentIndex, message);
        } else if (menuIdentifier == SET_SENTENCE) {
            setSentence(avatarKey, currentIndex, message);
        } else {
            sayDebug("listen ERROR: did not handle message '"+message+"'  menuIdentifier '"+menuIdentifier+"'");
        }
}

characterMenu(key avatarKey) {
    // lets the player choose from asset numbers and names
    sayDebug("characterMenu()");
    string message = "Select the Character to work with:\n";
    list buttons = [];
    integer index;
    for (index=1; index<7; index = index + 1) {
        buttons = buttons + [(string)index];
        message = message + (string)index+ " " + getAssetNumber(index) + " " + getCrime(index) + "\n";
    }
    setUpMenu(SELECT_CHAR, avatarKey, message, buttons);
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
        userKey = NULL_KEY;
        initLists();
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
    
    listen(integer channel, string avatarName, key avatarKey, string message )
    {
        sayDebug("listen(avatarName='"+avatarName+"' message='"+message+"')");

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

        doMainMenu(avatarKey, message);
    }

    http_response(key request_id, integer status, list metadata, string message)
    // handle a response from the getCrime database
    {
        // validate the response
        // find out which of the pending requests this is
        integer index = llListFindList(databaseRequestList, [request_id]);
        if (index == -1) {
            sayDebug("handleHttpResponse did not find request_id "+(string)request_id);
            sayDebug("status:"+(string)status);
            sayDebug("metadata:"+(string)metadata);
            sayDebug("message:"+(string)message);
            return; // skip response if this script did not require it
        } else {
            sayDebug("found request "+(string)request_id+" in index "+(string)index);
            sayDebug("request belongs to "+getAssetNumber(index));
        }

        if (status != 200)
        {
            sayDebug("handleHttpResponse got error response for request id "+(string)request_id);
            sayDebug("status:"+(string)status);
            sayDebug("metadata:"+(string)metadata);
            sayDebug("message:"+(string)message);

            databaseRequestList = llListReplaceList(databaseRequestList, [0], index, index);
            return;
        }

        // Then send it to the database
        if (queryType == GET) {
            handleHttpResponse(index, message);
        }
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
