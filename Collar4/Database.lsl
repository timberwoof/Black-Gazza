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
https://api.blackgazza.com/asset/?identity=284ba63f-378b-4be6-84d9-10db6ae48b8d&c=show_key&role=inmate&asset=P-60361&key=crime
https://api.blackgazza.com/asset/?identity=284ba63f-378b-4be6-84d9-10db6ae48b8d&c=show_asset&role=inmate&asset=P-60361
https://api.blackgazza.com/asset/?identity=284ba63f-378b-4be6-84d9-10db6ae48b8d&c=show_keys&role=inmate&asset=P-60361
https://api.blackgazza.com/asset/?identity=284ba63f-378b-4be6-84d9-10db6ae48b8d&c=show_assets&role=inmate
https://api.blackgazza.com/asset/?identity=284ba63f-378b-4be6-84d9-10db6ae48b8d&c=show_roles
https://api.blackgazza.com/asset/?identity=284ba63f-378b-4be6-84d9-10db6ae48b8d

Collar is interested in the role=inmate things.
0. What roles does this UUID have? 
1. Does this UUID have an Inmate role set? 
2. If so, what assets (collar numbers) does this UUIS have? 
3. For each asset, show all the keys this asset has.
4. Fr each key, list the data. 
*/

integer OPTION_DEBUG = 1;
key databaseQuery;
integer myQueryStatus = 0;

string name;
string start_date;
string assetNumber;
string crime;
string class;
string shocks;
string rank;
string specialty;

list inmateAssetKeys;
list inmateAssetValues;


sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Database:"+message);
    }
}

// fire off a request to the crime database for this wearer. 
sendDatabaseQuery(integer queryStatus, string command) {
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
    string URL = "https://api.blackgazza.com/asset/?identity=" + UUID;
    if (command != "") {
        URL = URL + "&c=" + command; 
    }
    myQueryStatus = queryStatus;
    databaseQuery = llHTTPRequest(URL,[],"");
}

getPlayerRoles() {
    sendDatabaseQuery(1, "show_roles");
}

getPlayerInmateNumbers() {
    sendDatabaseQuery(2, "show_assets&role=inmate");
}

getPlayerInmateKeys(string assetNumber) {
    sendDatabaseQuery(3, "show_keys&role=inmate&asset="+assetNumber);
}

getPlayerInmateAssetKey(string assetNumber, string assetKey) {
    sendDatabaseQuery(4, "show_key&role=inmate&asset="+assetNumber+"&key="+assetKey);
}

addKeyValuePair(string theKey, string theValue) {
    inmateAssetKeys = inmateAssetKeys + [theKey];
    inmateAssetValues = inmateAssetValues + [theValue];
}

string getListThing(list theList, string theKey){
    return llList2String(theList, llListFindList(theList, [theKey])+1);
}

displayCentered(string message) {
    //sayDebug("displayCentered '"+message+"'");
    llMessageLinked(LINK_THIS, 2000, message, "");
}


default
{
    state_entry()
    {
        sayDebug("state_entry");
        //sendDatabaseQuery(0, "");
        getPlayerRoles();
    }

    http_response(key request_id, integer status, list metadata, string message)
    // handle the response from the crime database
    {
        //sayDebug("http_response message="+message);
        displayCentered("status "+(string)status);
        if (status == 200) {
            if (myQueryStatus == 0) {
                // The whole kitten kaboodle
                
            // body looks like 
            // {"roles": 
            //  {"inmate": 
            //    {"P-40631": 
            //      {"name": "Marmour Bovinecow", "start_date": "2019-07-17 03:00:00", "crime": "Identity Theft", "class": "orange", "shocks": "22"}}, 
            //   "guard": {"G-90673": {"name": "Timberwoof Lupindo", "start_date": "2009-08-10 01:39:05", "rank": "Captain"}, 
            //             "G-3631": {"name": "LUP-8462", "start_date": "2015-02-01 11:16:15"}}, 
            //   "medic": {"M-15981": {"name": "Melkor Schmerzlos", "start_date": "2019-07-17 17:49:15", "specialty": "Neurology"}, 
            //             "M-9991": {"name": "LUP-8462", "start_date": "2015-02-01 11:16:15"}}, 
            //   "mechanic": {"X-1241": {"name": "LUP-8462", "start_date": "2015-02-01 11:16:15"}}}, 
            // "_name_": "Timberwoof Lupindo", 
            // "_start_date_": "2009-08-10 01:39:05"}
            //
            // keys: 
            // roles - inmate mechanic medic guard
            //  inmate - name, start_date, crime, class, shocks
            //  guard - name, star_date
            //  medic - name, start_date, specialty
            //  mechanic - name, start_date
            // _name_
            // _start_date_
            
            //sayDebug("http_response got message from server: " + message);
            
            list list1 = llJson2List(message);
            
            // debug the first-level list
            integer i;
            //sayDebug("------------------------------");
            //sayDebug("http_response first-level list");
            for (i=0; i < llGetListLength(list1); i++){
                string item = llList2String(list1,i);
                //sayDebug("list1 item "+(string)i+":"+item);
            }
            
            // find the canonical name: first find the _name_ key
            integer nameIndex = llListFindList(list1, ["_name_"]);
            if (nameIndex < 0) {
                sayDebug("Error: did not find key _name_ in returned JSON");
                displayCentered("Key Error");
                return;
                }
            string nameInDB = llList2String(list1, nameIndex+1);
            string ownerName = llKey2Name(llGetOwner());
            if (nameInDB != ownerName) {
                sayDebug("Error: returned name "+nameInDB+" did not match owner name "+ownerName);
                displayCentered("Name Error");
                return;
                }
            
            // find the roles. 
            integer rolesIndex = llListFindList(list1, ["roles"]);
            list list2 = llJson2List(llList2String(list1, rolesIndex+1));
            //sayDebug("------------------------------");
            //sayDebug("http_response second-level list");
            for (i=0; i < llGetListLength(list2); i=i+2){
                string item = llList2String(list2,i);
                list list3 = llJson2List(llList2String(list2,i+1));
                //sayDebug("raw list3:"+(string)list3);
                
                string assetNumber = llList2String(list3,0);
                //sayDebug("assetNumber="+assetNumber);
                list list4 =llJson2List(llList2String(list3,1));
                
                integer j;
                for (j = 0; j < llGetListLength(list4); j=j+2){
                    string theKey = llList2String(list4,j);
                    string theValue = llList2String(list4,j+1);
                    //sayDebug("Key:"+theKey+"="+theValue);
                }
                
                name = getListThing(list4, "name");
                start_date = getListThing(list4, "start_date");
                
                if (item == "inmate") {
                    crime = getListThing(list4, "crime");
                    class = getListThing(list4, "class");
                    shocks = getListThing(list4, "shocks");
                    sayDebug("inmate "+name+" "+assetNumber+" Class:"+class+" Crime:"+crime+" "+shocks+" shocks "+start_date);
                } else if (item == "guard") {
                    rank = getListThing(list4, "rank");
                    sayDebug("guard "+rank+" "+name+" "+assetNumber+" "+start_date);
                } else if (item == "medic") {
                    specialty = getListThing(list4, "specialty");
                    sayDebug("medic "+name+" "+specialty+" "+assetNumber+" "+start_date);
                } else if (item == "mechanic") {
                    sayDebug("mechanic "+name+" "+assetNumber+" "+start_date);
                } else if (item == "robot") {
                    sayDebug("robot "+name+" "+assetNumber+" "+start_date);
                }
                
            } // end myQueryStatus = 0
            
            //getPlayerRoles();
            }
               
            else if (myQueryStatus == 1) {
                //sayDebug("decode roles");
                list list1 = llJson2List(message);
                string what = llList2String(list1,0);
                //sayDebug("what:"+what);
                if (what != "roles") {
                    sayDebug("response was "+what+", not assets");
                } else {
                    string theString = llList2String(list1,1);
                    list theList = llJson2List(llList2String(list1,1));
                    if (llListFindList(theList, ["inmate"]) < 0) {
                        sayDebug("roles did not contain inmate");
                    } else {
                        addKeyValuePair("role", "inmate");
                        getPlayerInmateNumbers();
                    }
               }
            }

            else if (myQueryStatus == 2) {
                //sayDebug("decode asset numbers");
                list list1 = llJson2List(message);
                string what = llList2String(list1,0);
                if (what != "assets") {
                    sayDebug("response was "+what+", not assets");
                } else {
                    string theString = llList2String(list1,1);
                    list theList = llJson2List(llList2String(list1,1));
                    assetNumber = llList2String(theList,0);
                    sayDebug("assetNumber:"+assetNumber);
                    addKeyValuePair("assetNumber", assetNumber);
                    getPlayerInmateKeys(assetNumber);
                }
            }
            
            else if (myQueryStatus == 3) {
                //sayDebug("get list of asset keys");
                list list1 = llJson2List(message);
                string what = llList2String(list1,0);
                if (what != "keys") {
                    sayDebug("response was "+what+", not keys");
                } else {
                    string theString = llList2String(list1,1);
                    list theList = llJson2List(llList2String(list1,1));
                    integer i;
                    for (i = 0; i < llGetListLength(theList); i++){
                        //sayDebug("key:"+llList2String(theList, i));
                        getPlayerInmateAssetKey(assetNumber,llList2String(theList, i));
                    }
                }
            }
            
            else if (myQueryStatus == 4) {
                //sayDebug("get one asset key");
                list list1 = llJson2List(message);
                string theKey = llList2String(list1,0);
                string theValue = llList2String(list1,1);
                sayDebug("key-value: "+theKey+"="+theValue);
                addKeyValuePair(theKey, theValue);
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
            sendDatabaseQuery(0, "");
        }
    }
}
