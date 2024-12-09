// database2.lsl
// interim connectivity for Collar 4 to the old database.
// This has the same commections to the rest of the collar as database.lsl but it connects to the current db.

// Database.lsl
// All interactions with the external database
// Timberwoof Lupindo
// version: 2024-12-01

// Startup sequence
// state_entry() calls sendDatabaseQuery()
// or attach() calls sendDatabaseQuery()
// sendDatabaseQuery calls llHTTPRequest()
// http_response() handles the request
// http_response() deletes request from request list and from isEditCrimesList

integer OPTION_DEBUG = FALSE;
list databaseQuery;
list isEditCrimeList;
string myQueryStatus;

string start_date;
string unassignedAsset = "P-00000";

string URL_BASE =  "http://sl.blackgazza.com/"; // "http://sl.blackgazza.com/";
string URL_READ = "read_inmate.cgi?key=";
string URL_ADD = "add_inmate.cgi?key=";
key crimeRequest;
integer gCharacterSlot = 0; // unselected

integer menuChannel;
integer menuListen;

integer crimeSetChannel = 0;
integer crimeSetListen;

//  Initialize the parameter lists for all 6 characters. 
// 1-based so 0 is unassigned
string UNRECORDED = "unrecorded";
string WHITE = "white";
string NONE = "None";
string OOC = "OOC";

list assetNumberList = ["P-00000","P-00000","P-00000","P-00000","P-00000","P-00000","P-00000"]; 
list crimeList = ["",UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED]; 
list nameList = ["",UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED]; 
list sentenceList = ["0","0","0","0","0","0","0"]; // it is not used in this collar but i decided to keep it
list zapLevelsList = ["","","","","","",""]; 
list zapByObjectList = ["","","","","","",""]; 
list classList = ["",WHITE,WHITE,WHITE,WHITE,WHITE,WHITE]; 
list threatList = ["",NONE,NONE,NONE,NONE,NONE,NONE]; 
list moodList = ["",OOC,OOC,OOC,OOC,OOC,OOC]; 

string tempcrime = "";

key guardGroupKey = "b3947eb2-4151-bd6d-8c63-da967677bc69";

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Database: "+message);
    }
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

list linksetDataReadList(string theKey) {
    string json = llLinksetDataRead(theKey);
    list result = llJson2List(json);
    sayDebug("linksetDataReadList("+theKey+") = "+json);
    return result;
}

linksetDataWriteList(string theKey, list theList) {
    string json = llList2Json(JSON_ARRAY, theList);
    integer result = llLinksetDataWrite(theKey, json);
    list resultStrings = ["ok", "too large", "empty key", "protected key", "key not found", "not updated"];
    string resultString = llList2String(resultStrings, result);
    integer available = llLinksetDataAvailable();
    sayDebug("linksetDataWriteList("+theKey+", "+json+") = "+resultString+"; "+(string)available+" free"); 
}

initializeLists() {
    // set up local copies of things from the asset data
    sayDebug("initializeLists from linksetData");
    assetNumberList = linksetDataReadList("assetNumberList");
    crimeList = linksetDataReadList("crimeList");
    nameList = linksetDataReadList("nameList");
    sentenceList = linksetDataReadList("sentenceList");
    classList = linksetDataReadList("classList");
    moodList = linksetDataReadList("moodList");
    threatList = linksetDataReadList("threatList");
    zapLevelsList = linksetDataReadList("zapLevelsList");
    zapByObjectList = linksetDataReadList("zapByObjectList");
}

string assetNumber() {
    return llList2String(assetNumberList, gCharacterSlot);
}

string crime() {
    return llList2String(crimeList, gCharacterSlot);
}

string name() {
    return llList2String(nameList, gCharacterSlot);
}

string class() {
    return llList2String(classList, gCharacterSlot);
}

string threat() {
    return llList2String(threatList, gCharacterSlot);
}

string mood() {
    return llList2String(moodList, gCharacterSlot);
}

string zapLevels() {
   return llList2String(zapLevelsList, gCharacterSlot);
}

string zapByObject() {
   return llList2String(zapByObjectList, gCharacterSlot);
}

list setLocalList(string listName, list thelist, string value) {
    // replaces one value in the local list, then updates the linksetData
    sayDebug("setLocalList("+listName+", "+value+")");
    list newList = llListReplaceList(thelist, [value], gCharacterSlot, gCharacterSlot);
    linksetDataWriteList(listName, newList);
    return newList;
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
sendDatabaseQuery(integer iSlot, string crime) {
    if (llGetAttached()) {
        displayCentered("Accessing DB");
        string URL = URL_BASE; // http://sl.blackgazza.com/
        if ((crime != "") && (assetNumber() != "") && (assetNumber() != "P-00000")) {
            URL += URL_ADD; // add_inmate.cgi?key=
            isEditCrimeList += [TRUE];
            URL += AgentKeyWithRole((string)llGetOwner(),iSlot);
            URL += "&sentence=" + llList2String(sentenceList, gCharacterSlot);
            URL += "&name=" + name();
            URL += "&crime=" + crime;
            tempcrime = crime;
        } else {
            URL += URL_READ; // read_inmate.cgi?key=
            isEditCrimeList += [FALSE];
            URL += AgentKeyWithRole((string)llGetOwner(),iSlot);
        }

        sayDebug("sendDatabaseQuery URL:"+URL);
        databaseQuery += [llHTTPRequest(URL,[],"")]; // append reqest_id for use it later in responder event
        gCharacterSlot = iSlot;
    } else {
        sayDebug("sendDatabaseQuery unattached");
        sendJSON("AssetNumber", assetNumber(), llGetOwner());
        sendJSON("Crime", crime(), llGetOwner());
        sendJSON("Name", name(), llGetOwner());
    }
}

integer agentIsGuard(key agent)
{
    list attachList = llGetAttachedList(agent);
    integer item;
    while(item < llGetListLength(attachList))
    {
        if (llList2Key(llGetObjectDetails(llList2Key(attachList, item), [OBJECT_GROUP]), 0) == guardGroupKey) return TRUE;
        item++;
    }
    return FALSE;
}

displayCentered(string message) {
    string json = llList2Json(JSON_OBJECT, ["Display",message]);
    llMessageLinked(LINK_THIS, 0, json, "");
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
    buttons = buttons + ["Close"];

    sendJSON("DisplayTemp", "menu access", avatarKey);
    string completeMessage = assetNumber() + " Collar: " + message;
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

setCharacterCrime(key avatarKey)
{
    if (avatarKey == llGetOwner() || !agentIsGuard(avatarKey)) return;
    string message = assetNumber() + "\nCurrent Crime: " + crime() + "\nPlease set new Crime: ";
    crimeSetChannel = -(llFloor(llFrand(1000)+1000));
    crimeSetListen = llListen(crimeSetChannel, "", avatarKey, "");
    llSetTimerEvent(30);
    llTextBox(avatarKey, message, crimeSetChannel);
}

default
{
    state_entry() // reset
    {
        sayDebug("state_entry");
        initializeLists();
        if (gCharacterSlot == 0) {
            sendDatabaseQuery(1, "");
        } else {
            sendJSON("AssetNumber", assetNumber(), llGetOwner());
        }
        sayDebug("state_entry done");
    }

    attach(key avatar)
    {
        sayDebug("attach");
        initializeLists();
        if (gCharacterSlot == 0) {
            sendDatabaseQuery(1, "");
        } else {
            sendJSON("AssetNumber", assetNumber(), llGetOwner());
        }
        sayDebug("attach done");
    }

    http_response(key request_id, integer status, list metadata, string message)
    // handle the response from the crime database
    {
        sayDebug("http_response status:"+(string)status);
        
        // In all the requests we sent, find which one this is the data for. 
        integer listRequestIndex = llListFindList(databaseQuery, [request_id]);

        // IF this response is for something we didn't ask for, quit safely. 
        if (listRequestIndex == -1) 
        {
            displayCentered("DBERR UREQ");
            return; // skip response if this script did not require it
        }

        // If response status code not ok (not 200)
        // then remove item with request_id from list and exit without changing any data. 
        if (status != 200)
        {
            displayCentered("DBERR STAT"+(string)status);

            // removes unnecessary request_id from memory to save
            databaseQuery = llDeleteSubList(databaseQuery, listRequestIndex, listRequestIndex);

            // also removes unnecessary crime record from memory to save
            isEditCrimeList = llDeleteSubList(isEditCrimeList, listRequestIndex, listRequestIndex);
            
            characterMenu();
            return;
        }

        // Response from web server was OK and it was for something we waanted. 
        // 
        // then process response the way crimesetter does
        if (llList2Integer(isEditCrimeList, listRequestIndex))
        {
            crimeList = setLocalList("crimeList", crimeList, tempcrime);
            sendJSON("Crime", crime(), llGetOwner());

            // removes unnecessary request_id from memory
            databaseQuery = llDeleteSubList(databaseQuery, listRequestIndex, listRequestIndex);
            isEditCrimeList = llDeleteSubList(isEditCrimeList, listRequestIndex, listRequestIndex);
            return;
        }

        // removes unnecessary request_id from memory
        databaseQuery = llDeleteSubList(databaseQuery, listRequestIndex, listRequestIndex);
        isEditCrimeList = llDeleteSubList(isEditCrimeList, listRequestIndex, listRequestIndex);

        //displayCentered("DB Status "+(string)status);
        string assetNumber = "P-00000";
        string theCrime = "Unregistered";
        string theName = llGetOwner();

        // decode the response which looks like
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

        // extract the pieces from this data returned from the database
        list returnedStuff = llParseString2List(message, [","], []);
        theName = llList2String(returnedStuff, 0);
        string sentence = llList2String(returnedStuff, 1);
        theCrime = llList2String(returnedStuff, 2);
        string avatarKey = llList2String(returnedStuff, 3);
        string theAssetNumber = llList2String(returnedStuff, 4);

        // Report the data we got
        sayDebug("name:"+theName);
        sayDebug("number:"+sentence);
        sayDebug("crime:"+theCrime);
        sayDebug("key:"+avatarKey);
        sayDebug("assetNumber:"+theAssetNumber);

        // update our local lists of things and store them in the linkset
        assetNumberList = setLocalList("assetNumberList", assetNumberList, theAssetNumber);
        crimeList = setLocalList("crimeList", crimeList, theCrime);
        nameList = setLocalList("nameList", nameList, theName);
        sentenceList = setLocalList("sentenceList", sentenceList, sentence);

        // fire off the next data request
        if (gCharacterSlot < 6) {
            gCharacterSlot = gCharacterSlot + 1;
            sendDatabaseQuery(gCharacterSlot, "");
        } else {
            gCharacterSlot = 0; // unselected

            sayDebug("httpresponse assetNumberList: "+(string)assetNumberList);
            sayDebug("httpresponse crimeList: "+(string)crimeList);
            sayDebug("httpresponse nameList: "+(string)nameList);

            characterMenu();
        }
    }

    link_message(integer sender_num, integer num, string json, key id){
        //sayDebug("link_message "+json);
        string request = getJSONstring(json, "Database", "");
        if (request != "") sayDebug("link_message("+json+")");
        if (request == "getupdate") sendDatabaseQuery(gCharacterSlot, "");
        if (request == "setcharacter") sendDatabaseQuery(1,"");
        if (request == "setcrimes") setCharacterCrime(id);

        string value = llJsonGetValue(json, ["Class"]);
        if (value != JSON_INVALID) {
            sayDebug("link_message Class:"+value);
            classList = setLocalList("classList", classList, value);
        }

        value = llJsonGetValue(json, ["Threat"]);
        if (value != JSON_INVALID) {
            sayDebug("link_message Threat:"+value);
            threatList = setLocalList("threatList", threatList, value);
        }

        value = llJsonGetValue(json, ["Mood"]);
        if (value != JSON_INVALID) {
            sayDebug("link_message Mood:"+value);
            moodList = setLocalList("moodList", moodList, value);
        }
        
        value = llJsonGetValue(json, ["ZapLevels"]);
        if (value != JSON_INVALID) {
            sayDebug("link_message ZapLevels:"+value);
            zapLevelsList = setLocalList("zapLevelsList", zapLevelsList, value);
        }

        value = llJsonGetValue(json, ["RLV"]);
        if (value != JSON_INVALID) {
            sayDebug("link_message RLV:"+value);
            moodList = setLocalList("zapByObjectList", zapByObjectList, value);
        }
        
    }

    listen(integer channel, string name, key id, string text) {
        if (channel == menuChannel) {
            // character selection menu
            sayDebug("listen(menuchannel, "+text+")");
            gCharacterSlot = llListFindList(assetNumberList, [text]); // selected
            sendJSON("AssetNumber", assetNumber(), llGetOwner());
            sendJSON("Crime", crime(), llGetOwner());
            sendJSON("Name", name(), llGetOwner());
            sendJSON("Class", class(), llGetOwner());
            sendJSON("Threat", threat(), llGetOwner());
            sendJSON("Mood", mood(), llGetOwner());
            sendJSON("ZapLevels", zapLevels(), llGetOwner());
            sendJSON("zapByObject", zapByObject(), llGetOwner());
            llListenRemove(menuListen);
            menuChannel = 0;
            llSetTimerEvent(0);
        }
        else if (channel == crimeSetChannel)
        {
            sayDebug("listen(crimeSetChannel, "+text+")");
            llListenRemove(crimeSetListen);
            crimeSetChannel = 0;
            llSetTimerEvent(0);
            if ( (assetNumber() != "") && (assetNumber() != "P-00000") && (id != llGetOwner()) && (agentIsGuard(id)))
                sendDatabaseQuery(gCharacterSlot, text);
        }
    }

    timer() {
        if (menuListen != 0) {
            llListenRemove(menuListen);
            menuChannel = 0;
        }
        if (crimeSetListen != 0)
        {
            llListenRemove(crimeSetListen);
            crimeSetChannel = 0;
        }
        llSetTimerEvent(0);
    }
}
