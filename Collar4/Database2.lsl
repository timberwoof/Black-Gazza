// database2.lsl
// interim connectivity for Collar 4 to the old database.
// This has the same commections to the rest of the collar as database.lsl but it connects to the current db.

// Database.lsl
// All interactions with the external database
// Timberwoof Lupindo
// version: 2024-12-11

// Startup sequence
// state_entry() calls sendDatabaseRead()
// or attach() calls sendDatabaseRead()
// sendDatabaseRead calls llHTTPRequest()
// http_response() handles the request
// http_response() deletes request from request list and from isEditCrimesList

integer OPTION_DEBUG = FALSE;
list databaseQuery;
string READorWrite;

string start_date;
string unassignedAsset = "P-00000";

string URL_BASE =  "http://sl.blackgazza.com/"; // "http://sl.blackgazza.com/";
string URL_READ = "read_inmate.cgi?key=";
string URL_ADD = "add_inmate.cgi?key=";
integer gCharacterSlot = 1; 

integer channelMenu;
integer listenMenu;
string menuID;

integer channelSetCrime = 0;
integer listenSetCrime;

integer channelSetName = 0;
integer listenSetName;

integer channelEnterIncident = 0;
integer listenEnterIncident;

//  Initialize the parameter lists for all 6 characters. 
// 1-based so 0 is unassigned
string UNRECORDED = "unrecorded";
string WHITE = "white";
string NONE = "None";
string OOC = "OOC";

// The indexes are 0 in these lists but +1 in the additional characters
list assetNumberList = ["P-00000","P-00000","P-00000","P-00000","P-00000","P-00000"]; 
list crimeList = [UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED]; 
list nameList = [UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED]; 
list sentenceList = ["0","0","0","0","0","0"]; // it is not used in this collar but i decided to keep it
list zapLevelsList = ["","","","","",""]; 
list zapByObjectList = ["","","","","",""]; 
list classList = [WHITE,WHITE,WHITE,WHITE,WHITE,WHITE]; 
list threatList = [NONE,NONE,NONE,NONE,NONE,NONE]; 
list moodList = [OOC,OOC,OOC,OOC,OOC,OOC]; 

list incidentNumbersList = ["","","","","",""]; // 7 json lists of incident incidentNumbers
list incidentReportsList = ["","","","","",""]; // 7 json lists of incidents

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
    list result = llList2List(llJson2List(json), 0, 5); // Never read more than 6 items.
    sayDebug("linksetDataReadList("+theKey+") = "+json);
    return result;
}

linksetDataWriteList(string theKey, list theList) {
    theList = llList2List(theList, 0, 5); // Never write more than 6 items.  
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
    incidentNumbersList = linksetDataReadList("incidentNumbersList");
    incidentReportsList = linksetDataReadList("incidentReportsList");
}

backupList(string prefix, string thekey, list theList, string suffix) {
    string jsonlist = llList2Json(JSON_ARRAY, theList);
    string jsonobject = llList2Json(JSON_OBJECT, [thekey, jsonlist]);
    string jsonblob = prefix + jsonobject + suffix;
    llInstantMessage(llGetOwner(),jsonblob);
}

backup(key id) {
    llInstantMessage(llGetOwner(), "Copy the following text and paste it into a notecard.");
    llInstantMessage(llGetOwner(), "Delete the timestamp, your asset number, and your name from each line."); 
    backupList("{\"BGLCON\":[", "assetNumberList", assetNumberList, ",");
    backupList("", "crimeList", crimeList, ",");
    backupList("", "nameList", nameList, ",");
    backupList("", "sentenceList", sentenceList, ",");
    backupList("", "classList", classList, ",");
    backupList("", "moodList", moodList, ",");
    backupList("", "threatList", threatList, ",");
    backupList("", "zapLevelsList", zapLevelsList, ",");
    backupList("", "zapByObjectList", zapByObjectList, ",");
    //backupList("", "incidentNumbersList", incidentNumbersList, ",");
    //backupList("", "incidentReportsList", incidentReportsList, "]}");
    llInstantMessage(llGetOwner(), "End of Backup Report"); 
}

string assetNumber(integer slot) {
    return llList2String(assetNumberList, slot-1);
}

string crime(integer slot) {
    return llList2String(crimeList, slot-1);
}

string name(integer slot) {
    return llList2String(nameList, slot-1);
}

string class(integer slot) {
    return llList2String(classList, slot-1);
}

string threat(integer slot) {
    return llList2String(threatList, slot-1);
}

string mood(integer slot) {
    return llList2String(moodList, slot-1);
}

string zapLevels(integer slot) {
   return llList2String(zapLevelsList, slot-1);
}

string zapByObject(integer slot) {
   return llList2String(zapByObjectList, slot-1);
}

list incidentNumbers(integer slot) {
    return llJson2List(llList2String(incidentNumbersList, slot-1));
}

list incidentReports(integer slot) {
    return llJson2List(llList2String(incidentReportsList, slot-1));
}

list setLocalList(integer slot, string listName, list thelist, string value) {
    // replaces one value in the local list, then updates the linksetData
    sayDebug("setLocalList("+(string)slot+", "+listName+", "+value+")");
    list newList = llListReplaceList(thelist, [value], slot-1, slot-1);
    linksetDataWriteList(listName, newList);
    return newList;
}

// convert agent key to database key
string getDatabaseKey(integer slot) {
// If the slot number is 2 or greater, it sticks the character key into the agent UUID.
// Otherwise it leaves the UUID alone. 
    string agentKey = (string)llGetOwner();
    if (slot > 1) {
        agentKey = llGetSubString(agentKey, 0, 22) + (string)slot + llGetSubString(agentKey, 24, -1);
    }
    return agentKey;
}

// fire off a request to the crime database for this wearer.
// Parameter iSlot determines which character to get.
sendDatabaseRead(integer iSlot) {
    if (llGetAttached()) {
        sayDebug("sendDatabaseRead");
        DisplayTemp("Reading DB");
        READorWrite = "READ";
        string URL = URL_BASE + URL_READ + getDatabaseKey(iSlot);
        sayDebug("sendDatabaseRead URL:"+URL);
        databaseQuery += [llHTTPRequest(URL,[],"")]; // append reqest_id for use it later in responder event
    } else {
        sayDebug("sendDatabaseRead unattached");
        sendJSON("AssetNumber", assetNumber(iSlot), llGetOwner());
        sendJSON("Crime", crime(iSlot), llGetOwner());
        sendJSON("Name", name(iSlot), llGetOwner());
    }
}

// fire off a request to the crime database for this wearer.
// Parameter iSlot determines which character to get.
sendDatabaseWrite(integer iSlot) {
    if (llGetAttached()) {
        sayDebug("sendDatabaseWrite");
        DisplayTemp("Writing DB");
        READorWrite = "WRITE";
        string URL = URL_BASE; // http://sl.blackgazza.com/
        URL += URL_ADD; // add_inmate.cgi?key=
        URL += getDatabaseKey(iSlot);
        URL += "&sentence=" + llList2String(sentenceList, iSlot);
        URL += "&name=" + llEscapeURL(name(iSlot));  
        URL += "&crime=" + llEscapeURL(crime(iSlot)); 

        sayDebug("sendDatabaseWrite URL:"+URL);
        databaseQuery += [llHTTPRequest(URL,[],"")]; // append reqest_id for use it later in responder event
    } else {
        sayDebug("sendDatabaseWrite unattached");
        sendJSON("AssetNumber", assetNumber(iSlot), llGetOwner());
        sendJSON("Crime", crime(iSlot), llGetOwner());
        sendJSON("Name", name(iSlot), llGetOwner());
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

DisplayCentered(string message) {
    string json = llList2Json(JSON_OBJECT, ["Display", message]);
    llMessageLinked(LINK_THIS, 0, json, "");
}

DisplayScroll(string message) {
    string json = llList2Json(JSON_OBJECT, ["DisplayScroll", message]);
    llMessageLinked(LINK_THIS, 0, json, "");
}

DisplayTemp(string message) {
    string json = llList2Json(JSON_OBJECT, ["DisplayTemp", message]);
    llMessageLinked(LINK_THIS, 0, json, "");
}

setUpMenu(string id, key avatarKey, string message, list buttons)
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
    menuID = id;

    //buttons = buttons + ["Main"];
    buttons = buttons + ["Close"];

    DisplayTemp("menu access");
    string completeMessage = assetNumber(gCharacterSlot) + " Collar: " + message;
    channelMenu = -(llFloor(llFrand(10000)+1000));
    listenMenu = llListen(channelMenu, "", avatarKey, "");
    llSetTimerEvent(30);
    llDialog(avatarKey, completeMessage, buttons, channelMenu);
}

characterMenu() {
    sayDebug("characterMenu()");
    list buttons = [];
    integer i = 1;
    for (i=1; i<=6; i = i + 1) {
        if (assetNumber(i) != "") {
            buttons = buttons + [assetNumber(i)];
        }
    }
    setUpMenu("Character", llGetOwner(), "Choose your Asset Number", buttons);
}

setCharacterCrime(key avatarKey)
{
    sayDebug("setCharacterCrime()");
    string message = assetNumber(gCharacterSlot) + "\nCurrent Crime: " + crime(gCharacterSlot) + "\nPlease set new Crime: ";
    channelSetCrime = -(llFloor(llFrand(1000)+1000));
    listenSetCrime = llListen(channelSetCrime, "", avatarKey, "");
    llSetTimerEvent(30);
    llTextBox(avatarKey, message, channelSetCrime);
}

setCharacterName(key avatarKey)
{
    sayDebug("setCharacterName()");
    string message = assetNumber(gCharacterSlot) + "\nCurrent Name: " + name(gCharacterSlot) + "\nPlease set new Name: ";
    channelSetName = -(llFloor(llFrand(1000)+1000));
    listenSetName = llListen(channelSetName, "", avatarKey, "");
    llSetTimerEvent(30);
    llTextBox(avatarKey, message, channelSetName);
}

incidentReportsMenu(key avatarKey) {
    // Present list of incident reports and "Enter"
    sayDebug("incidentReportsMenu()");
    list incNumList = incidentNumbers(gCharacterSlot);
    list buttons = [];
    integer i;
    for (i = 0; i < llGetListLength(incNumList); i = i + 1) {
        string IncidentNumberButton = "increp-" + (string)llList2Integer(incNumList, i);
        buttons = buttons + [IncidentNumberButton];
    }
    buttons = buttons + ["Enter"];
    setUpMenu("Incident", avatarKey, "Read or Enter Incident Report", buttons);
    // next call is retrieveIncidentReport
    // or enterIncidentReportDialog and recordIncidentReport
}

retrieveIncidentReport(key avatarKey, string text) {
    // send an incident report to the guard
    sayDebug("retrieveIncidentReport("+text+")");
    // text is in the form incid-6
    string incidentNumber = llStringTrim(llGetSubString(text, 7, 10),STRING_TRIM);
    integer index = llListFindList(incidentNumbers(gCharacterSlot), [(integer)incidentNumber]);
    string incidentReport = llList2String(incidentReports(gCharacterSlot), index);
    llInstantMessage(avatarKey, text+": "+incidentReport);
}

enterIncidentReportDialog(key avatarKey) {
    // Present dialog to enter one incident report
    sayDebug("enterIncidentReportDialog()");
    string message = "Enter Incident Report for asset " + assetNumber(gCharacterSlot) + "(" + name(gCharacterSlot) + ")";
    channelEnterIncident = -(llFloor(llFrand(1000)+1000));
    listenEnterIncident = llListen(channelEnterIncident, "", avatarKey, "");
    llSetTimerEvent(30);
    llTextBox(avatarKey, message, channelEnterIncident);
    // next call is recordIncidentReport
}

recordIncidentReport(key avatarKey, string text) {
    // Handle incoming incident report
    sayDebug("recordIncidentReport("+text+")");
    list incNumList = llList2List(incidentNumbers(gCharacterSlot), 0, 5);
    list incReportList = llList2List(incidentReports(gCharacterSlot), 0, 5);

    // get the next number for an incident
    integer i = 0;
    integer max = 0;
    for (i = 0; i < llGetListLength(incNumList); i = i + 1) {
        integer aNumber = llList2Integer(incNumList, i);
        if (aNumber > max) {
            max = aNumber;
        }
    }
    integer newNumber = max + 1;
    
    // add the incident number to the list of incident numbers
    incNumList = [newNumber] + incNumList;
    incNumList =  llList2List(incNumList, 0, 5);
    incidentNumbersList = linksetDataReadList("incidentNumbersList");
    incidentNumbersList = setLocalList(gCharacterSlot, "incidentNumbersList", incidentNumbersList, llList2Json(JSON_ARRAY, incNumList));

    // add the incident text to the list of incidentReports\
    string reportText = llGetDate() + " by " + llKey2Name(avatarKey) +": " + text;
    incReportList =  llList2List([reportText] + incReportList, 0, 5);
    incidentReportsList = linksetDataReadList("incidentReportsList");
    incidentReportsList = setLocalList(gCharacterSlot, "incidentReportsList", incidentReportsList, llList2Json(JSON_ARRAY, incReportList));
                
    llInstantMessage(avatarKey, "The incident "+(string)newNumber+": \""+reportText+"\" has been recorded.");
}

default
{
    state_entry() // reset
    {
        sayDebug("state_entry");
        initializeLists();
        sendDatabaseRead(gCharacterSlot);
        sayDebug("state_entry done");
    }

    attach(key avatar)
    {
        sayDebug("attach");
        initializeLists();
        sendDatabaseRead(gCharacterSlot);        
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
            DisplayTemp("DBERR UNREQ");
            return; // skip response if this script did not require it
        }

        // If response status code not ok (not 200)
        // then remove item with request_id from list and exit without changing any data. 
        if (status != 200)
        {
            DisplayTemp("DBSTAT"+(string)status);

            // removes unnecessary request_id from memory to save
            databaseQuery = llDeleteSubList(databaseQuery, listRequestIndex, listRequestIndex);

            characterMenu();
            return;
        }

        // Response from web server was OK and it was for something we wanted. 
        // 
        // then process response the way crimesetter does
        if (READorWrite == "WRITE")
        {
            sayDebug("http_response was for a write. Exiting.");
            databaseQuery = llDeleteSubList(databaseQuery, listRequestIndex, listRequestIndex);
            return;
        }

        // READorWrite == "READ"
        sayDebug("http_response was for a read.");
        // clear request_id from memory
        databaseQuery = llDeleteSubList(databaseQuery, listRequestIndex, listRequestIndex);

        // default values to be filled in fromt he request
        string assetNumber = "P-00000";
        string theCrime = "Unregistered";
        string theName = llGetOwner();

        // decode the response which looks like
        // Timberwoof Lupindo,0,Piracy;Illegal Transport of Biogenics,284ba63f-378b-4be6-84d9-10db6ae48b8d,P-60361
        
        // Handle any empty slots
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
        string theSentence = llList2String(returnedStuff, 1);
        theCrime = llList2String(returnedStuff, 2);
        string avatarKey = llList2String(returnedStuff, 3);
        string theAssetNumber = llList2String(returnedStuff, 4);

        // Report the data we got
        sayDebug("name:"+theName);
        sayDebug("number:"+theSentence);
        sayDebug("crime:"+theCrime);
        sayDebug("key:"+avatarKey);
        sayDebug("assetNumber:"+theAssetNumber);

        // update our local lists of things and store them in the linkset
        assetNumberList = setLocalList(gCharacterSlot, "assetNumberList", assetNumberList, theAssetNumber);
        crimeList = setLocalList(gCharacterSlot, "crimeList", crimeList, theCrime);
        sentenceList = setLocalList(gCharacterSlot, "sentenceList", sentenceList, theSentence);
        //nameList = setLocalList(gCharacterSlot, "nameList", nameList, theName); *** No. The name in the database is wrong.

        // fire off the next data request
        if (gCharacterSlot < 6) {
            gCharacterSlot = gCharacterSlot + 1;
            sendDatabaseRead(gCharacterSlot);
        } else {
            gCharacterSlot = 1; // this was in error

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
        if (request == "getupdate") sendDatabaseRead(gCharacterSlot);
        if (request == "setcharacter") sendDatabaseRead(1);
        if (request == "setcrime") setCharacterCrime(id);
        if (request == "setname") setCharacterName(id);
        if (request == "incidents") incidentReportsMenu(id);
        if (request == "Backup") backup(id);

        string value = llJsonGetValue(json, ["Class"]);
        if (value != JSON_INVALID) {
            sayDebug("link_message Class:"+value);
            classList = setLocalList(gCharacterSlot, "classList", classList, value);
        }

        value = llJsonGetValue(json, ["Threat"]);
        if (value != JSON_INVALID) {
            sayDebug("link_message Threat:"+value);
            threatList = setLocalList(gCharacterSlot, "threatList", threatList, value);
        }

        value = llJsonGetValue(json, ["Mood"]);
        if (value != JSON_INVALID) {
            sayDebug("link_message Mood:"+value);
            moodList = setLocalList(gCharacterSlot, "moodList", moodList, value);
        }
        
        value = llJsonGetValue(json, ["ZapLevels"]);
        if (value != JSON_INVALID) {
            sayDebug("link_message ZapLevels:"+value);
            zapLevelsList = setLocalList(gCharacterSlot, "zapLevelsList", zapLevelsList, value);
        }

        value = llJsonGetValue(json, ["RLV"]);
        if (value != JSON_INVALID) {
            sayDebug("link_message RLV:"+value);
            zapByObjectList = setLocalList(gCharacterSlot, "zapByObjectList", zapByObjectList, value);
        }
        
    }

    listen(integer channel, string name, key id, string text) {
        text = llStringTrim(text, STRING_TRIM);
        sayDebug("listen("+text+")");
        llSetTimerEvent(0);
        if (channel == channelMenu) {
            llListenRemove(listenMenu);
            channelMenu = 0;
            if (menuID == "Character") {
                // character selection menu
                sayDebug("listen(channel, "+menuID+", "+text+")");
                gCharacterSlot = llListFindList(assetNumberList, [text]) + 1;
                if (gCharacterSlot < 1) {
                    // this is an error. Fix it benignly..
                    gCharacterSlot = 1;
                }
                sendJSON("AssetNumber", assetNumber(gCharacterSlot), llGetOwner());
                sendJSON("Crime", crime(gCharacterSlot), llGetOwner());
                sendJSON("Name", name(gCharacterSlot), llGetOwner());
                sendJSON("Class", class(gCharacterSlot), llGetOwner());
                sendJSON("Threat", threat(gCharacterSlot), llGetOwner());
                sendJSON("Mood", mood(gCharacterSlot), llGetOwner());
                sendJSON("ZapLevels", zapLevels(gCharacterSlot), llGetOwner());
                sendJSON("zapByObject", zapByObject(gCharacterSlot), llGetOwner());
            } 
            else if (menuID == "Incident") {
                // retrieve an incident report
                sayDebug("listen(channelMenu, Incident, "+text+")");
                if (text == "Enter") {
                    enterIncidentReportDialog(id);
                } else if (text == "Close") {
                    // nothing
                } else {
                    retrieveIncidentReport(id, text);
                }
            }
        }
        else if (channel == channelSetName) {
            sayDebug("listen(channelSetName, "+text+")");
            llListenRemove(listenSetName);
            channelSetName = 0;
            if (text != "") {
                nameList = setLocalList(gCharacterSlot, "nameList", nameList, text);
                sendDatabaseWrite(gCharacterSlot);
                sendJSON("Name", name(gCharacterSlot), llGetOwner());
            } else {
                llInstantMessage(id, "The submitted name was blank. The name was not updated.");
            }

        }
        else if (channel == channelSetCrime) {
            sayDebug("listen(channelSetCrime, "+text+")");
            llListenRemove(listenSetCrime);
            channelSetCrime = 0;
            llSetTimerEvent(0);
            if (text != "") {
                crimeList = setLocalList(gCharacterSlot, "crimeList", crimeList, text);
                sendDatabaseWrite(gCharacterSlot);
                sendJSON("Crime", crime(gCharacterSlot), llGetOwner());
                llOwnerSay(name+" set your crime to "+text);
            } else {
                llInstantMessage(id, "The submitted crime was blank. The crime was not updated.");
            }
        }
        else if (channel == channelEnterIncident) {
            sayDebug("listen(channelEnterIncident, "+text+")");
            llListenRemove(listenEnterIncident);
            channelEnterIncident = 0;
            if (text != "") {
                recordIncidentReport(id, text);
            } else {
                llInstantMessage(id, "The submitted incident report was blank. The report was not recorded.");
            }
        }
    }

    timer() {
        if (listenMenu != 0) {
            llListenRemove(listenMenu);
            channelMenu = 0;
        }
        if (listenSetCrime != 0) {
            llListenRemove(listenSetCrime);
            channelSetCrime = 0;
        }
        if (listenSetName != 0) {
            llListenRemove(listenSetName);
            channelSetName = 0;
        }
        if (listenEnterIncident != 0) {
            llListenRemove(listenEnterIncident);
            channelEnterIncident = 0;
        }
        llSetTimerEvent(0);
    }
}
