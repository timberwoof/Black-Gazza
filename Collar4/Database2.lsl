// database2.lsl
// interim connectivity for Collar 4 to the old database. 
// This has the same commections to the rest of the collar as database.lsl but it connects to the current db. 

// Database.lsl
// All interactions with the external database
// Timberwoof Lupindo
// July 2019, February 2020
// version: 2020-03-08

// Link-Messages in the 2000 range

integer OPTION_DEBUG = 0;
key databaseQuery;
string myQueryStatus;

string name;
string start_date;
list assetNumbers; // there's only one
string assetNumber;
string crime;
string class;
string shocks;
string rank;
string specialty;

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
    //sayDebug("displayCentered '"+message+"'");
    llMessageLinked(LINK_THIS, 2001, message, "");
}

sendAssetNumbers() {
    // Send the active asset numbers to Menu
    string message = llList2Json(JSON_ARRAY, assetNumbers);
    sayDebug("sendAssetNumbers:"+message);
    llMessageLinked(LINK_THIS, 1011, message, "");
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
        llSleep(2); // wait for other scripts to awaken. 
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
            string name = llList2String(returnedStuff, 0);
            crime = llList2String(returnedStuff, 2);
            assetNumber = llList2String(returnedStuff, 4);
            
            sayDebug("name:"+name);
            sayDebug("crime:"+crime);
            sayDebug("assetNumber:"+assetNumber);
            
            llMessageLinked(LINK_THIS, 1800, crime, "");
        }
        else {
            displayCentered("error "+(string)status);
            llMessageLinked(LINK_THIS, 1800, crime, "Unknown");
            assetNumber = "ERR-" + (string)status;
        }
        assetNumbers = [assetNumber];
        sendAssetNumbers();
    }
    
    link_message( integer sender_num, integer num, string message, key id ){ 
        sayDebug("link_message "+(string)num+" "+message);
        // Someone wants database update
        if (num == 2002) {
            sayDebug("link_message "+(string)num+" "+message);
            sendDatabaseQuery();
        } else if (num == 1013) {
            sayDebug("link_message "+(string)num+" "+message);
            //displayCentered("Function unsupported");
        }
    }
}
