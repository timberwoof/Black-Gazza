// database2.lsl
// interim connectivity for Collar 4 to the old database.
// This has the same commections to the rest of the collar as database.lsl but it connects to the current db.

// Database.lsl
// All interactions with the external database
// Timberwoof Lupindo
// version: 2024-12-01

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
integer gCharacterSlot = 1; // unselected

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

list assetNumberList = ["P-00000","P-00000","P-00000","P-00000","P-00000","P-00000","P-00000"]; 
list crimeList = ["",UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED]; 
list nameList = ["",UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED,UNRECORDED]; 
list sentenceList = ["0","0","0","0","0","0","0"]; // it is not used in this collar but i decided to keep it
list zapLevelsList = ["","","","","","",""]; 
list zapByObjectList = ["","","","","","",""]; 
list classList = ["",WHITE,WHITE,WHITE,WHITE,WHITE,WHITE]; 
list threatList = ["",NONE,NONE,NONE,NONE,NONE,NONE]; 
list moodList = ["",OOC,OOC,OOC,OOC,OOC,OOC]; 

list incidentDatesList = ["","","","","","",""]; // 7 json bobs of incident dates
list incidentsList = ["","","","","","",""]; // 7 json blobs of incidents

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
    incidentDatesList = linksetDataReadList("incidentDatesList");
    incidentsList = linksetDataReadList("incidentsList");
}

string assetNumber(integer slot) {
    return llList2String(assetNumberList, slot);
}

string crime(integer slot) {
    return llList2String(crimeList, slot);
}

string name(integer slot) {
    return llList2String(nameList, slot);
}

string class(integer slot) {
    return llList2String(classList, slot);
}

string threat(integer slot) {
    return llList2String(threatList, slot);
}

string mood(integer slot) {
    return llList2String(moodList, slot);
}

string zapLevels(integer slot) {
   return llList2String(zapLevelsList, slot);
}

string zapByObject(integer slot) {
   return llList2String(zapByObjectList, slot);
}

list incidentDates(integer slot) {
    return llJson2List(llList2String(incidentDatesList, slot));
}

list incidents(integer slot) {
    return llJson2List(llList2String(incidentsList, slot));
}

list setLocalList(integer slot, string listName, list thelist, string value) {
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
integer sendDatabaseRead(integer iSlot) {
    if (llGetAttached()) {
        sayDebug("sendDatabaseRead");
        displayCentered("Reading DB");
        READorWrite = "READ";
        string URL = URL_BASE + URL_READ + AgentKeyWithRole((string)llGetOwner(),iSlot);
        sayDebug("sendDatabaseRead URL:"+URL);
        databaseQuery += [llHTTPRequest(URL,[],"")]; // append reqest_id for use it later in responder event
    } else {
        sayDebug("sendDatabaseRead unattached");
        sendJSON("AssetNumber", assetNumber(iSlot), llGetOwner());
        sendJSON("Crime", crime(iSlot), llGetOwner());
        sendJSON("Name", name(iSlot), llGetOwner());
    }
    return iSlot;
}

// fire off a request to the crime database for this wearer.
// Parameter iSlot determines which character to get.
integer sendDatabaseWrite(integer iSlot) {
    if (llGetAttached()) {
        sayDebug("sendDatabaseWrite");
        displayCentered("Writing DB");
        READorWrite = "WRITE";
        string URL = URL_BASE; // http://sl.blackgazza.com/
        URL += URL_ADD; // add_inmate.cgi?key=
        URL += AgentKeyWithRole((string)llGetOwner(),iSlot);
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
    return iSlot;
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

    buttons = buttons + ["Main"];
    buttons = buttons + ["Close"];

    sendJSON("DisplayTemp", "menu access", avatarKey);
    string completeMessage = assetNumber(gCharacterSlot) + " Collar: " + message;
    channelMenu = -(llFloor(llFrand(10000)+1000));
    listenMenu = llListen(channelMenu, "", avatarKey, "");
    llSetTimerEvent(30);
    llDialog(avatarKey, completeMessage, buttons, channelMenu);
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
    setUpMenu("Character", llGetOwner(), "Choose your Asset Number", buttons);
}

incidentsMenu(key avatarKey) {
    sayDebug("incidentsMenu()");    
    list buttons = ["Enter"] + llList2List(incidentDates(gCharacterSlot), 0, 5);
    setUpMenu("Incident", llGetOwner(), "Read or Enter Incident Report", buttons);
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

enterIncidenteReport(key avatarKey) {
    sayDebug("enterIncidenteReport()");
    string message = "Enter Incident Report for asset " + assetNumber(gCharacterSlot) + "(" + name(gCharacterSlot) + ")";
    channelEnterIncident = -(llFloor(llFrand(1000)+1000));
    listenEnterIncident = llListen(channelEnterIncident, "", avatarKey, "");
    llSetTimerEvent(30);
    sayDebug("enterIncidenteReport() textbox("+message+","+(string)channelEnterIncident+")");
    llTextBox(avatarKey, message, channelEnterIncident);
}

default
{
    state_entry() // reset
    {
        sayDebug("state_entry");
        initializeLists();
        if (gCharacterSlot == 0) {
            gCharacterSlot = sendDatabaseRead(1);
        } else {
            sendJSON("AssetNumber", assetNumber(gCharacterSlot), llGetOwner());
        }
        
        sayDebug("state_entry done");
    }

    attach(key avatar)
    {
        sayDebug("attach");
        initializeLists();
        if (gCharacterSlot == 0) {
            gCharacterSlot = sendDatabaseRead(1);
        } else {
            sendJSON("AssetNumber", assetNumber(gCharacterSlot), llGetOwner());
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

            characterMenu();
            return;
        }

        displayCentered("DB Status "+(string)status);

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
            gCharacterSlot = 1; // unselected

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
        if (request == "getupdate") gCharacterSlot = sendDatabaseRead(gCharacterSlot);
        if (request == "setcharacter") sendDatabaseRead(1);
        if (request == "setcrime") setCharacterCrime(id);
        if (request == "setname") setCharacterName(id);
        if (request == "incidents") incidentsMenu(id);

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
            moodList = setLocalList(gCharacterSlot, "zapByObjectList", zapByObjectList, value);
        }
        
    }

    listen(integer channel, string name, key id, string text) {
        sayDebug("listen("+text+")");
        if (channel == channelMenu) {
            if (menuID == "Character") {
                // character selection menu
                sayDebug("listen(channelMenu, menuID, "+text+")");
                gCharacterSlot = llListFindList(assetNumberList, [text]); // selected
                sendJSON("AssetNumber", assetNumber(gCharacterSlot), llGetOwner());
                sendJSON("Crime", crime(gCharacterSlot), llGetOwner());
                sendJSON("Name", name(gCharacterSlot), llGetOwner());
                sendJSON("Class", class(gCharacterSlot), llGetOwner());
                sendJSON("Threat", threat(gCharacterSlot), llGetOwner());
                sendJSON("Mood", mood(gCharacterSlot), llGetOwner());
                sendJSON("ZapLevels", zapLevels(gCharacterSlot), llGetOwner());
                sendJSON("zapByObject", zapByObject(gCharacterSlot), llGetOwner());
                llListenRemove(listenMenu);
                channelMenu = 0;
                llSetTimerEvent(0);
            }
            if (menuID = "Incident") {
                sayDebug("listen(channelMenu, Incident, "+text+")");
                if (text == "Enter") {
                    enterIncidenteReport(id);
                } else {
                    list dates = incidentDates(gCharacterSlot);
                    list incidents = incidents(gCharacterSlot);
                    integer index = llListFindList(dates, [text]);
                    string incident = llList2String(incidents, index);
                    sayDebug("Incident "+text+": "+incident);
                    llInstantMessage(id, "Incident " + text + ": " + incident);
                }
            }
        }
        else if (channel == channelSetName)
        {
            sayDebug("listen(channelSetName, "+text+")");
            llListenRemove(listenSetName);
            channelSetName = 0;
            llSetTimerEvent(0);
            nameList = setLocalList(gCharacterSlot, "nameList", nameList, text);
            gCharacterSlot = sendDatabaseWrite(gCharacterSlot);
            sendJSON("Name", name(gCharacterSlot), llGetOwner());
        }
        else if (channel == channelSetCrime)
        {
            sayDebug("listen(channelSetCrime, "+text+")");
            llListenRemove(listenSetCrime);
            channelSetCrime = 0;
            llSetTimerEvent(0);
            crimeList = setLocalList(gCharacterSlot, "crimeList", crimeList, text);
            gCharacterSlot = sendDatabaseWrite(gCharacterSlot);
            sendJSON("Crime", crime(gCharacterSlot), llGetOwner());
        }
        else if (channel == channelEnterIncident)
        {
            sayDebug("listen(channelEnterIncident, "+text+")");
            llListenRemove(listenEnterIncident);
            channelEnterIncident = 0;
            llSetTimerEvent(0);
            list dates = llList2List(incidentDates(gCharacterSlot), 0, 5);
            list incidents = llList2List(incidents(gCharacterSlot), 0, 5);
            sayDebug("dates:"+(string)dates);
            sayDebug("incidents:"+(string)incidents);
            integer count = llGetListLength(dates);
            if (count > 6) {
                // don't let the list grow too big: delete the last one
                sayDebug("deleting last incident report");
                dates == llDeleteSubList(dates, count-1, count-1);
                incidents == llDeleteSubList(incidents, count-1, count-1);
            }
            
            // Male a timestamp for this incident report
            list timestamp =llParseString2List(llGetTimestamp(),["-",":","."],["T"]);
            // YYYY-MM-DDThh:mm:ss.ff..fZ
            string MM = llList2String(timestamp, 1);
            string DD = llList2String(timestamp, 2);
            string hh = llList2String(timestamp, 4);
            string mm = llList2String(timestamp, 5);
            string ss = llList2String(timestamp, 6);
            string theDate = MM+DD+hh+mm+ss;
            
            dates = [theDate] + dates;
            incidents = [text] + incidents;
            setLocalList(gCharacterSlot, "incidentDatesList", incidentDatesList, llList2Json(JSON_ARRAY, dates));
            setLocalList(gCharacterSlot, "incidentsList", incidentsList, llList2Json(JSON_ARRAY, incidents));
            incidentDatesList = linksetDataReadList("incidentDatesList");
            incidentsList = linksetDataReadList("incidentsList");
            sayDebug("The incident "+theDate+": "+text+" has been recorded.");
            llInstantMessage(id, "The incident "+theDate+": \""+text+"\" has been recorded.");
        }
    }

    timer() {
        if (listenMenu != 0) {
            llListenRemove(listenMenu);
            channelMenu = 0;
        }
        if (listenSetCrime != 0)
        {
            llListenRemove(listenSetCrime);
            channelSetCrime = 0;
        }
        llSetTimerEvent(0);
    }
}
