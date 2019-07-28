// Database.lsl
// All interactions with the external database
// Timberwoof Lupindo
// July 2019

// Link-Messages in the 2000 range

/*
Kyroraz Ansar, [Jul 18, 2019 at 1:06:46 PM (7/18/19, 1:23:14 PM)]:
...Commands:
    show_roles:  Shows all the roles within a UUID identity (SL Avatar)
    show_assets:  Shows all the assets (e.g. P-60361, X-19281 etc) within a role owned by a UUID identity.
    show_asset:  Shows all the information about an asset (P-60361 for example) 
    show_key:  Shows one piece of information about an asset.  Example:  crime within P-60361, this just returns the crime.
    show_keys:  Displays the keys linked to an asset e.g. P-60361

Other parameters:

    role = Defines a specific role to drill into
    asset = Defines a specific asset to drill into
    key = Defines a specific key within  an asset to drill into

Example URLs:
https://api.blackgazza.com/identity/284ba63f-378b-4be6-84d9-10db6ae48b8d
https://api.blackgazza.com/identity/284ba63f-378b-4be6-84d9-10db6ae48b8d/roles
https://api.blackgazza.com/identity/284ba63f-378b-4be6-84d9-10db6ae48b8d/roles/inmate
https://api.blackgazza.com/identity/284ba63f-378b-4be6-84d9-10db6ae48b8d/roles/inmate/P-60361

Collar is interested in the role=inmate things.
0. What roles does this UUID have? 
1. Does this UUID have an Inmate role set? 
2. If so, what assets (collar numbers) does this UUIS have? 
3. For each asset, show all the keys this asset has.
4. Fr each key, list the data. 
*/

integer OPTION_DEBUG = 1;
key databaseQuery;
string myQueryStatus;

string name;
string start_date;
list assetNumbers;
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
    // Old DB
    //string URL = "http://sl.blackgazza.com/read_inmate.cgi?key=" + (string)llGetOwner();
    // New DB
    string UUID = (string)llGetOwner();
    // test uuids
    // 00000000-0000-0000-0000-000000000010 Loot Boplace
    // 00000000-0000-0000-0000-000000000011 Marmour Bovinecow
    // 00000000-0000-0000-0000-000000000012 LUP-8462
    // 00000000-0000-0000-0000-000000000013 Melkor Schmerzlos
    //UUID = "00000000-0000-0000-0000-000000000013";
    string URL = "https://api.blackgazza.com/identity/" + UUID;
    if (command != "") {
        URL = URL + command; 
    }
    myQueryStatus = queryStatus;
    sayDebug("sendDatabaseQuery:"+URL);
    databaseQuery = llHTTPRequest(URL,[],"");
}

getPlayerRoles() {
    sayDebug("getPlayerRoles");
    sendDatabaseQuery("GetRoles", "/roles");
}

getPlayerInmateNumbers() {
    sayDebug("getPlayerInmateNumbers");
    sendDatabaseQuery("GetAssets", "/roles/inmate");
}

getPlayerInmateKeys(string assetNumber) {
    sayDebug("getPlayerInmateKeys("+assetNumber+")");
    sendDatabaseQuery("GetAssetKeys", "/roles/inmate/"+assetNumber);
}

getPlayerInmateAssetKey(string assetNumber, string assetKey) {
    sayDebug("getPlayerInmateAssetKey("+assetNumber+","+assetKey+")");
    sendDatabaseQuery("GetOneKey", "/roles/inmate/"+assetNumber+"/"+assetKey);
}

string getListThing(list theList, string theKey){
    return llList2String(theList, llListFindList(theList, [theKey])+1);
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
        sayDebug("state_entry with asset number=\""+assetNumber+"\"");
        getPlayerRoles();
    }

    http_response(key request_id, integer status, list metadata, string message)
    // handle the response from the crime database
    {
        sayDebug("http_response message="+message);
        displayCentered("status "+(string)status);
        if (status == 200) {
              
            if (myQueryStatus == "GetRoles") {
                sayDebug("decode roles");
                list theList = llJson2List(message);
                if (llListFindList(theList, ["inmate"]) < 0) {
                    sayDebug("roles did not contain inmate");
                } else {
                    getPlayerInmateNumbers();
               }
            }

            else if (myQueryStatus == "GetAssets") {
                sayDebug("decode asset numbers");
                list theList = llJson2List(message);
                assetNumbers = [];
                integer i;
                for (i = 0; i < llGetListLength(theList); i = i + 2) {
                    string theAssetNumber = llList2String(theList,i); // index tells which asset number to grab
                    sayDebug("theAssetNumber:"+theAssetNumber);
                    assetNumbers = assetNumbers + [theAssetNumber];
                    // now player must choose which asset
                    sendAssetNumbers();
                }
            }
            
            else if (myQueryStatus == "GetAssetKeys") {
                sayDebug("get list of asset keys");
                list theList = llJson2List(message);
                crime="";
                llMessageLinked(LINK_THIS, 1800, crime, "");
                class = "";
                llMessageLinked(LINK_THIS, 1200, class, "");
                    
                // decode the incoming list of keys
                integer i;
                for (i = 0; i < llGetListLength(theList); i=i+2){
                    string theKey = llList2String(theList,i);
                    string theValue = llList2String(theList,i+1);
                    sayDebug("key-value: "+theKey+"="+theValue);
                    if (theKey == "crime") {
                        crime = theValue;
                        sayDebug("sending crime \""+crime+"\"");
                        llMessageLinked(LINK_THIS, 1800, crime, "");
                    } else if (theKey == "class") {
                        class = theValue;
                        sayDebug("sending class "+class);
                        llMessageLinked(LINK_THIS, 1200, class, "");
                    }
                }
            }
            
            else if (myQueryStatus == "GetOneKey") {
                sayDebug("get one asset key");
                list list1 = llJson2List(message);
                string theKey = llList2String(list1,0);
                string theValue = llList2String(list1,1);
                sayDebug("key-value: "+theKey+"="+theValue);
            }

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
