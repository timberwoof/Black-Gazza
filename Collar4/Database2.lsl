// database2.lsl
// interim connectivity for Collar 4 to the old database. 
// This has the same commections to the rest of the collar as database.lsl but it connects to the current db. 

// Database.lsl
// All interactions with the external database
// Timberwoof Lupindo
// July 2019, February 2020
// version: 2020-03-22

integer OPTION_DEBUG = 0;
key databaseQuery;
string myQueryStatus;

string prisonerName;
string start_date;
list assetNumbers; // there's only one
string assetNumber;
string prisonerCrime;
string prisonerClass;


sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Database:"+message);
    }
}

// fire off a request to the crime database for this wearer. 
sendDatabaseQuery() {
    displayCentered("Accessing DB");
    string URL = "http://sl.blackgazza.com/read_inmate.cgi?key=" + (string)llGetOwner();
    sayDebug("sendDatabaseQuery:"+URL);
    databaseQuery = llHTTPRequest(URL,[],"");
}

displayCentered(string message) {
    string json = llList2Json(JSON_OBJECT, ["Display",message]);
    llMessageLinked(LINK_THIS, 0, json, "");
}

default
{
    state_entry() // reset
    {
        sayDebug("state_entry");
        assetNumber = "P-00000";
        prisonerCrime = "Unknown";
        string statusJsonList = llList2Json(JSON_OBJECT, [
            "assetNumber", assetNumber, 
            "prisonerCrime", prisonerCrime]);
        llMessageLinked(LINK_THIS, 0, statusJsonList, "");
        if (llGetAttached() != 0) {
            sendDatabaseQuery();
        }
    }
    
    attach(key avatar) 
    {
        sayDebug("attach");
        sendDatabaseQuery();
    }

    http_response(key request_id, integer status, list metadata, string message)
    // handle the response from the crime database
    {
        sayDebug("http_response message="+message);
        displayCentered("status "+(string)status);
        if (status == 200) {
            // decode the response
            // looks like 
            // Timberwoof Lupindo,0,Piracy; Illegal Transport of Biogenics,284ba63f-378b-4be6-84d9-10db6ae48b8d,P-60361
            list returnedStuff = llParseString2List(message, [","], []);
            prisonerName = llList2String(returnedStuff, 0);
            prisonerCrime = llList2String(returnedStuff, 2);
            assetNumber = llList2String(returnedStuff, 4);
            
            sayDebug("name:"+prisonerName);
            sayDebug("crime:"+prisonerCrime);
            sayDebug("assetNumber:"+assetNumber);
        }
        else {
            displayCentered("error "+(string)status);
            assetNumber = "ERR-" + (string)status;
        }
        string statusJsonList = llList2Json(JSON_OBJECT, [
            "assetNumber", assetNumber, 
            "prisonerCrime", prisonerCrime]);
        llMessageLinked(LINK_THIS, 0, statusJsonList, "");
    }
    
    link_message( integer sender_num, integer num, string json, key id ){ 
        sayDebug("link_message "+json);
        string request = llJsonGetValue(json, ["database"]);
        if (request != JSON_INVALID)
            sendDatabaseQuery();
        }
    }
