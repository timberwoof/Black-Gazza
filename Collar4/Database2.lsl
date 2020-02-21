// database2.lsl
// interim connectivity for Collar 4 to the old database. 
// This has the same commections to the rest of the collar as database.lsl but it connects to the current db. 

// Database.lsl
// All interactions with the external database
// Timberwoof Lupindo
// July 2019, February 2020

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
        llWhisper(0,"Database:"+message);
    }
}

// fire off a request to the crime database for this wearer. 
sendDatabaseQuery(string queryStatus, string command) {
    sayDebug("sendDatabaseQuery(\""+command+"\")");
    displayCentered("Accessing DB");
    string URL = "http://sl.blackgazza.com/read_inmate.cgi?key=" + (string)llGetOwner();
    myQueryStatus = queryStatus;
    sayDebug("sendDatabaseQuery:"+URL);
    databaseQuery = llHTTPRequest(URL,[],"");
}

displayCentered(string message) {
    //sayDebug("displayCentered '"+message+"'");
    llMessageLinked(LINK_THIS, 2001, message, "");
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
        getPlayerRoles();
    }

    http_response(key request_id, integer status, list metadata, string message)
    // handle the response from the crime database
    {
        sayDebug("http_response message="+message);
        displayCentered("status "+(string)status);
        if (status == 200) {
          // decode the response
              
        }
        else {
            displayCentered("error "+(string)status);
        }
    }
    
    link_message( integer sender_num, integer num, string message, key id ){ 
        //sayDebug("link_message "+(string)num+" "+message);
        // Someone wants database update
        if (num == 2002) {
            sayDebug("link_message "+(string)num+" "+message);
            getPlayerRoles();
        } else if (num == 1013) {
            sayDebug("link_message "+(string)num+" "+message);
            getPlayerInmateKeys(message);
        }
    }
}
