integer g_iOnline;
key Sound_Open = "482b14cb-ff89-178a-b3f3-ee0e9a403b24";
key Sound_Close = "375397f6-531c-aa00-275f-caeb66c56e71";
float fVolum = 0.5;
string URL = "http://sl.blackgazza.com/";
string URL_READ = "read_inmate.cgi?key=";
string URL_ADD = "add_inmate.cgi?key=";
key crimeRequest;
integer iFailed;

integer chan;
integer listener;
integer skip_expired;

integer DEBUG = 0;

key user_key;
key give_key;

string sPromt;
list assetNumbersList; // position 0 is a dummy so it'a 1-based
list crimesList; // position 0 is a dummy so it'a 1-based

integer iMakeInmate;
integer iSetInmate;

key INMATE_KEY;
string INMATE_RESULT;

key crimesRequest;
vector red = <1.0, 0.0, 0.0>;
integer run;

debug(string message) {
    if (DEBUG) {
        llWhisper(0, message);
    }
} 

string COLLAR_GIVER = "e4833429-22d9-a1cc-2e08-90f6562e8830";
string COLLAR_GIVER_OFFLINE = "80e7148b-9a18-fe07-2476-fdbcebab5fce";
integer FACE = 3;
float TIMER = 900; 
key statusRequest;
integer iMenu;
key kKey;

string AgentKeyWithRole(string agentKey, integer slot) {
// if the slot number is 2 or greater, 
// sticks the character key into the agent UUID
    string result = agentKey;
    if (slot > 1) {
        string after = llGetSubString(agentKey, 0, 22);
        string before = llGetSubString(agentKey, 24, -1);
        result = after + (string)slot + before;
    }
    debug("AgentKeyWithRole("+(string)agentKey+", "+(string)slot+") returns "+result);
    return result;
}

Database_Read(integer g_iSlotLoad) {
    string final_url = URL + URL_READ + AgentKeyWithRole(user_key, g_iSlotLoad) + "";
    debug("Database_Read " + (string)g_iSlotLoad + " " + final_url);
    crimeRequest = llHTTPRequest(final_url, [], "");    
} 

crimes_generate(integer iValue) {
    // you little fucker. You could be the end of a loop. 
    if(iValue <= 6) {
        string final_url = URL + URL_READ + AgentKeyWithRole(INMATE_KEY, iValue) + "";
        debug("crimes_generate " + (string)iValue + " " + final_url);
        crimesRequest = llHTTPRequest(final_url, [], "");
    } else{
        // you little fucker! You're sending yourself messages. 
        debug("crimes_generate links message");
        llMessageLinked(LINK_SET, 5, INMATE_RESULT, INMATE_KEY);
    }
} 

Database_Save(integer iSlot, string sMsg) {
    // you little fucker. You could be the end of a loop. 
    if(iSlot <= 6) {
        debug("Database_Save (" + (string)iSlot + ", " + sMsg + ")");
        sMsg = llEscapeURL(llDumpList2String(llParseStringKeepNulls((sMsg = "")  +  sMsg, [";"], []), ","));
        string name = llEscapeURL(llKey2Name(user_key));
        string final_url = URL + URL_ADD + AgentKeyWithRole(user_key, iSlot) + "&name=" + name + "&crime=" + sMsg + "&sentence=0";
        debug("Database_Save " + (string)iSlot + " " + final_url);
        llHTTPRequest(final_url, [], "");
    }
    Clean();
} 

UserComand(key sID, string msg) {
    debug("UserComand:" + msg);
    if(msg == "main") {
        iFailed = 0;
        iSetInmate = 0;
        iMakeInmate = 0;
        give_key = NULL_KEY;
        llDialog(sID, sPromt, llList2List(assetNumbersList,1,6), chan);
    } else if(msg == "crimesetter") {
        llOwnerSay("crimesetter");
        if(iSetInmate > 0) {
            string message = "Crime setter:\n";
            
            integer i;
            for (i = 1; i <= 6; i = i + 1) {
                if(iSetInmate == i) {
                message += "Inmate selected:" + llList2String(assetNumbersList,iSetInmate);
                message += "\nCrime:" +  llList2String(crimesList,iSetInmate);
                }
            }            
            message += "\nPlease enter new crime:";
            llTextBox(sID, message , chan);
        } else if(iMakeInmate > 0) {
            Database_Save(iMakeInmate, "none");
            llSleep(2.0);
            iSetInmate = iMakeInmate;
            iMakeInmate = 0;
            Database_Read(iSetInmate);
        } 
    } else {
        for (iSetInmate = 1; iSetInmate <= 6; iSetInmate = iSetInmate + 1) {
            if (msg == llList2String(assetNumbersList, iSetInmate)) {
                Clean();
                debug("iSetInmate="+(string)iSetInmate);
                Generate(sID, "crimesetter");
                // this means that Generate uses iSetInmate as a hidden variable 
                // I hate you an awful lot
            }
        }
        for (iMakeInmate = 1; iMakeInmate <= 6; iMakeInmate = iMakeInmate + 1) {
            if (msg == (string)iMakeInmate) {
                Clean();
                debug("iMakeInmate="+(string)iMakeInmate);
                Generate(sID, "crimesetter");
                // this means that Generate uses iMakeInmate as a hidden variable 
                // I hate you an awful lot
            }
        }
    }
} 

Generate(key sID, string sStr) {
    user_key = sID;
    llListenRemove(listener);
    chan = 100  +  (integer)llFrand(20000);
    listener = llListen(chan, "", "", "");
    skip_expired = 1;
    llSetTimerEvent(60.0);
    UserComand(user_key, sStr);
} 



Clean() {
    llListenRemove(listener);
    skip_expired = 1;
    user_key = NULL_KEY;
    llSetTimerEvent(5.0);
} 

integer Authentification(key sID) {
    if(llSameGroup(sID)) {
        return 1;
    } 
    list AttachedUUIDs = llGetAttachedList(sID);
    string groupkey = (string)llGetObjectDetails((key)llList2String(AttachedUUIDs, 0) , [OBJECT_GROUP]);
    if(groupkey == "ce9356ec-47b1-5690-d759-04d8c8921476"||groupkey == "b3947eb2-4151-bd6d-8c63-da967677bc69"||groupkey == "900e67b1-5c64-7eb2-bdef-bc8c04582122") {
        return 1;
    } 
    if(groupkey == "49b2eab0-67e6-4d07-8df1-21d3e03069d0") {
        return -1;
    } 
    return 0;
} 

default
{
    state_entry()
    {
        string options = llGetObjectDesc();
        if (llSubStringIndex(options,"debug") > -1) {
            DEBUG = TRUE;
            debug("state_entry");
        }
        
        Clean();
        give_key = NULL_KEY;
    
    } 
    
    timer()
    {
        if(user_key == NULL_KEY) {
            llSetTimerEvent(TIMER);
            iMenu = 0;
            kKey = NULL_KEY;
        //    string funal_url = URL + URL_READ + "937996d5-654e-4aee-92ef-7375970f1249" + "";
        //    debug("timer: " + funal_url);
        //    statusRequest = llHTTPRequest(funal_url, [], "");
        } else
             Clean();
        //} 
       
    } 
    
    http_response(key request_id, integer status, list metadata, string body) {
        debug("http_response [" + (string)status + "] (" + (string)metadata + ")" + body);
        if (request_id == crimeRequest) {
            debug("http_response crimeRequest "+body);
            list inmate_data = llCSV2List(body); 
            string inmate_number = llList2String(inmate_data, 4);
         
            if(inmate_number != "") {
                if(iSetInmate > 0) {
                    debug("http_response links message");
                    llMessageLinked(LINK_SET, 4, "numbers", user_key);    
                } 
            } else{
                
            } 
        } 
        if (request_id == crimesRequest) {
            debug("http_response crimesRequest "+body);
            
            list inmate_data = llCSV2List(body); 
            string inmate_number = llList2String(inmate_data, 4);
            string inmate_channel = llGetSubString(inmate_number, 2, -1);
            string inmate_sentence = llList2String(inmate_data, 1);
            string inmate_crime = llList2String(inmate_data, 2);
           
           if(inmate_number != "")
           { 
                if(inmate_crime == ""||llStringLength(inmate_crime) < 2) {
                    inmate_crime = "<No crimes.>";
                } 
                INMATE_RESULT += inmate_number + "@" + inmate_crime + "@";
             
                run ++;
                crimes_generate(run);
           } else if(run == 1) {
               INMATE_RESULT = "<No records.>";
                debug("http_response links message");
               llMessageLinked(LINK_SET, 5, INMATE_RESULT, INMATE_KEY);
            } else{
                 run ++;
                crimes_generate(run);
            } 
        } 
        if (request_id == statusRequest) {
            debug("http_response statusRequest "+body);
            list inmate_data = llCSV2List(body); 
            string inmate_number = llList2String(inmate_data, 4);
         
            if(inmate_number != "") { 
                debug("http_response links message");
                llMessageLinked(LINK_SET, 3, "1", "");
                if(iMenu) {
                    debug("http_response links message");
                    llMessageLinked(LINK_SET, 2, "1", kKey);
                } 
                //llSetTexture(COLLAR_GIVER, FACE);
            } else{            
                if(iMenu) {
                    debug("http_response links message");
                    llMessageLinked(LINK_SET, 2, "0", kKey);
                } 
                debug("http_response links message");
                llMessageLinked(LINK_SET, 3, "0", "");
                //llSetTexture(COLLAR_GIVER_OFFLINE, FACE);
            } 
            iMenu = 0;
            kKey = NULL_KEY;
        } 
    } 
    
    touch_start(integer num_detected)
    {
        key kKey = llDetectedKey(0);
        if(user_key == NULL_KEY) // nirmal circumstance. user_key is the current user
        {
            integer i = Authentification(kKey);
            if(i == 1) {
                iFailed = 0;
                debug("touch_start links message 'check'");
                llMessageLinked(LINK_SET, 1, "check", kKey);
            } else if(i == -1) {
                llPlaySound(Sound_Close, fVolum);
                llInstantMessage(kKey, "An active BG group is required. Having the Welcome Group is not an official BG member group tag.");
            } else{
                llPlaySound(Sound_Close, fVolum);
                llInstantMessage(kKey, "Sorry, an active BG group is required.");
            } 
            
        } else if(user_key != kKey) { 
            llInstantMessage(kKey, "Sorry, the menu is being used by someone. >.<");
        } else if(user_key == kKey) {
            integer i = Authentification(kKey);
            if(i == 1) {
                llPlaySound(Sound_Open, fVolum);
                Generate(kKey, "main");
            } else if(i == -1) {
                llPlaySound(Sound_Close, fVolum);
                llInstantMessage(kKey, "An active BG group is required. Having the Welcoem Group is not an official BG member group tag.");
            } else{
                llPlaySound(Sound_Close, fVolum);
                llInstantMessage(kKey, "Sorry, an active BG group is required.");
            } 
        } 
    } 
    
    listen(integer channel, string name, key sID, string msg)
    {
        if(sID == user_key) {
            if(iMakeInmate == 0 && iSetInmate == 0) {
                llOwnerSay(msg);
                UserComand(sID, msg);
            } else
            if(iSetInmate > 0) {
                Database_Save(iSetInmate, msg);
                iSetInmate = 0;
                Clean();
                llSleep(2.0);
                debug("listen links message");
                llMessageLinked(LINK_SET, 4, "numbers", sID);    
            } 
        } 
    } 
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        debug("link_message iNum:"+(string)iNum+" sStr:"+sStr);
        // why the FUCK are you sending yourself link messages?
        if(iNum == 2) {
            g_iOnline = (integer)sStr;
            if(g_iOnline) {
                debug("link_message links message");
                llMessageLinked(LINK_SET, 4, "numbers", kID);
            } 
        } else if(iNum == 3) {
            g_iOnline = (integer)sStr;
        } else if(iNum == 5) {
            if((key)kID) {
                assetNumbersList = ["0", "1", "2", "3", "4", "5", "6"];
                crimesList = ["", "", "", "", "", "", ""];
                sPromt = "INMATES:\n";
                if(sStr == "<No records.>") {  
                    sPromt += "None, maybe not registered.";
                } else{
                    list lParams = llParseString2List(sStr, ["@"], []);
                    string sNumber;
                    string sCrime;
                    
                    integer i;
                    for (i = 1; i <= 6; i = i + 1) {
                        sNumber = llList2String(lParams, (i-1)*2);
                        sCrime = llList2String(lParams, (i-1)*2+1);
                        if(~llSubStringIndex(sNumber, "P-6")) {
                            assetNumbersList = llListReplaceList(assetNumbersList, [sNumber], i, i);
                            crimesList = llListReplaceList(crimesList, [sCrime], 1, 1);
                        } 
                        sPromt += sNumber + " > " + sCrime + "\n";
                    }
                } 
                sPromt = llGetSubString(sPromt, 0, 500);
                if(llGetListLength(assetNumbersList) <= 0) {
                    assetNumbersList = ["-", "-", "-"];
                } 
                Generate(kID, "main");
            } 
        } else if(iNum == 4 && sStr == "numbers") {
            if((key)kID) {
                if(kID != NULL_KEY) {
                  INMATE_RESULT = "";
                  run = 1;
                  INMATE_KEY = kID;
                  INMATE_RESULT = "";
                  string final_url = URL + URL_READ + (string)INMATE_KEY + "";
                  debug("link_message URL: " + final_url);
                  crimesRequest = llHTTPRequest(final_url, [], "");
                } else{
                    debug("link_message links message");
                    llMessageLinked(LINK_SET, 5, "<ERROR>", kID);
                } 
            } else{
                debug("link_message links message");
                llMessageLinked(LINK_SET, 5, "<ERROR>", kID);
            } 
        } else if(iNum == 1 && sStr == "check") {
            debug("database presence check");
            llSetTimerEvent(TIMER);
            iMenu = 1;
            kKey = kID;
            string final_url = URL + URL_READ + "937996d5-654e-4aee-92ef-7375970f1249" + "";
            debug("link_message URL: " + final_url);
            statusRequest = llHTTPRequest(final_url, [], "");
        } 
    } 
    
    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) {
            llResetScript();
        } 
        if (iChange & CHANGED_INVENTORY)         
        {
           
        } 
        if (iChange & CHANGED_ALLOWED_DROP) 
        {
           
        } 
    } 
    
} 

