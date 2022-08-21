// database2.lsl
// interim connectivity for Collar 4 to the old database. 
// This has the same commections to the rest of the collar as database.lsl but it connects to the current db. 

// Database.lsl
// All interactions with the external database
// Timberwoof Lupindo
// July 2019, February 2020
// version: 2020-11-23

integer OPTION_DEBUG = 0;
key databaseQuery;
string myQueryStatus;

string name;
string start_date;
list assetNumbers; // there's only one
string assetNumber;
string unassignedAsset = "P-00000";
string crime;
string class;


sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Database: "+message);
    }
}

// fire off a request to the crime database for this wearer. 
sendDatabaseQuery() {
    if (llGetAttached() != 0) {
        displayCentered("Accessing DB");
        string URL = "http://sl.blackgazza.com/read_inmate.cgi?key=" + (string)llGetOwner();
        sayDebug("sendDatabaseQuery:"+URL);
        databaseQuery = llHTTPRequest(URL,[],"");
    } else {
        sayDebug("sendDatabaseQuery unattached");
        string statusJsonList = llList2Json(JSON_OBJECT, [
            "assetNumber", assetNumber, 
            "crime", crime]);
        llMessageLinked(LINK_THIS, 0, statusJsonList, "");
    }
}

displayCentered(string message) {
    string json = llList2Json(JSON_OBJECT, ["Display",message]);
    llMessageLinked(LINK_THIS, 0, json, "");
}

sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
    }
    
default
{
    state_entry() // reset
    {
        sayDebug("state_entry");
        assetNumber = unassignedAsset;
        crime = "Unknown";
        sendDatabaseQuery();
        sayDebug("state_entry done");
    }
    
    attach(key avatar) 
    {
        sayDebug("attach");
        sendDatabaseQuery();
        sayDebug("attach done");
    }

    http_response(key request_id, integer status, list metadata, string message)
    // handle the response from the crime database
    {
        displayCentered("status "+(string)status);
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
            name = llList2String(returnedStuff, 0);
            string mysteriousNumber = llList2String(returnedStuff, 1);
            crime = llList2String(returnedStuff, 2);
            string avatarKey = llList2String(returnedStuff, 3);
            assetNumber = llList2String(returnedStuff, 4);
            
            sayDebug("name:"+name);
            sayDebug("number:"+mysteriousNumber);
            sayDebug("crime:"+crime);
            sayDebug("key:"+avatarKey);
            sayDebug("assetNumber:"+assetNumber);
        }
        else {
            displayCentered("error "+(string)status);
            assetNumber = "ERR-" + (string)status;
        }
        sendJSON("assetNumber", assetNumber, llGetOwner());
        sendJSON("crime", crime, llGetOwner());
    
    }
    
    link_message( integer sender_num, integer num, string json, key id ){ 
        sayDebug("link_message "+json);
        string request = llJsonGetValue(json, ["database"]);
        if (request != JSON_INVALID)
            sendDatabaseQuery();
        }
    }
