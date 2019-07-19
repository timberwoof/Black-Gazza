// Database.lsl
// All interactions with the external database
// Timberwoof Lupindo
// July 2019

// Link-Messages in the 2000 range

integer OPTION_DEBUG = 1;
key crimeRequest;

string name;
string start_date;
string registrationNumber;
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
sendDatabaseQuery() {
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
    crimeRequest= llHTTPRequest(URL,[],"");
}

string getListThing(list theList, string theKey){
    return llList2String(theList, llListFindList(theList, [theKey])+1);
}

displayCentered(string message) {
    llMessageLinked(LINK_THIS, 2000, message, "");
}


default
{
    state_entry()
    {
        sayDebug("state_entry");
    }

    touch_start(integer total_number)
    {
        llSay(0, "Touched.");
    }
    http_response(key request_id, integer status, list metadata, string message)
    // handle the response from the crime database
    {
        displayCentered("status "+(string)status);        
        if (status == 200) {
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
            
            // find the canonical name: first finr the _name_ key
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
                
                string registrationNumber = llList2String(list3,0);
                //sayDebug("registrationNumber="+registrationNumber);
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
                    sayDebug("inmate "+name+" "+registrationNumber+" Class:"+class+" Crime:"+crime+" "+shocks+" shocks "+start_date);
                } else if (item == "guard") {
                    rank = getListThing(list4, "rank");
                    sayDebug("guard "+rank+" "+name+" "+registrationNumber+" "+start_date);
                } else if (item == "medic") {
                    specialty = getListThing(list4, "specialty");
                    sayDebug("medic "+name+" "+specialty+" "+registrationNumber+" "+start_date);
                } else if (item == "mechanic") {
                    sayDebug("mechanic "+name+" "+registrationNumber+" "+start_date);
                } else if (item == "robot") {
                    sayDebug("robot "+name+" "+registrationNumber+" "+start_date);
                }
                
            }
                

            
            string number = "P-00000";
            displayCentered(number);
        }
    }
    
    link_message( integer sender_num, integer num, string message, key id ){ 
        sayDebug("link_message "+(string)num+" "+message);
        // Someone wants database update
        if (num == 2002) {
            sayDebug("link_message "+(string)num+" "+message);
            sendDatabaseQuery();
        }
    }
}
