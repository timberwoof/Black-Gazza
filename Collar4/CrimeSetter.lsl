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



key user_key;
key give_key;

string sPromt;
list lButtons;

string sButton_1;
string sButton_2;
string sButton_3;
string sButton_4;
string sButton_5;
string sButton_6;

string sCrime_1;
string sCrime_2;
string sCrime_3;
string sCrime_4;
string sCrime_5;
string sCrime_6;

integer iMakeInmate;
integer iSetInmate;


key INMATE_KEY;
string INMATE_RESULT;


key crimesRequest;
vector red = <1.0, 0.0, 0.0>;
integer run;


debug(string message) {
    //llWhisper(0, message);
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
        llDialog(sID, sPromt, lButtons, chan);
    } else if(msg == llToLower(sButton_1)) {
        Clean();
        iSetInmate = 1;
        llOwnerSay("iSetInmate = " + (string)iSetInmate);
        Generate(sID, "crimesetter");
    } else if(msg == llToLower(sButton_2)) {
        Clean();
        iSetInmate = 2;
        llOwnerSay("iSetInmate = " + (string)iSetInmate);
        Generate(sID, "crimesetter");
    } else if(msg == llToLower(sButton_3)) {
           Clean();
        iSetInmate = 3;
        llOwnerSay("iSetInmate = " + (string)iSetInmate);
        Generate(sID, "crimesetter");
    } else if(msg == llToLower(sButton_4)) {
        Clean();
        iSetInmate = 4;
        llOwnerSay("iSetInmate = " + (string)iSetInmate);
        Generate(sID, "crimesetter");
    } else if(msg == llToLower(sButton_5)) {
        Clean();
        iSetInmate = 5;
        llOwnerSay("iSetInmate = " + (string)iSetInmate);
        Generate(sID, "crimesetter");
    } else if(msg == llToLower(sButton_6)) {
        Clean();
        iSetInmate = 6;
        llOwnerSay("iSetInmate = " + (string)iSetInmate);
        Generate(sID, "crimesetter");
    } else if(msg == "1") {
        Clean();
        iMakeInmate = 1;
        Generate(sID, "crimesetter");
    } else if(msg == "2") {
        Clean();
        iMakeInmate = 2;
        Generate(sID, "crimesetter");
    } else if(msg == "3") {
           Clean();
        iMakeInmate = 3;
        Generate(sID, "crimesetter");
    } else if(msg == "4") {
        Clean();
        iMakeInmate = 4;
        Generate(sID, "crimesetter");
    } else if(msg == "5") {
        Clean();
        iMakeInmate = 5;
        Generate(sID, "crimesetter");
    } else if(msg == "6") {
        Clean();
        iMakeInmate = 6;
        Generate(sID, "crimesetter");
    } else if(msg == "crimesetter") {
        llOwnerSay("crimesetter");
        if(iSetInmate > 0) {
            string message = "Crime setter:\n";
            if(iSetInmate == 1) {
                message += "Inmate selected:" + sButton_1;
                message += "\nCrime:" + sCrime_1;
            } else
            if(iSetInmate == 2) {
                message += "Inmate selected:" + sButton_2;
                message += "\nCrime:" + sCrime_2;
            } else
            if(iSetInmate == 3) {
                message += "Inmate selected:" + sButton_3;
                message += "\nCrime:" + sCrime_3;
            } else
            if(iSetInmate == 4) {
                message += "Inmate selected:" + sButton_4;
                message += "\nCrime:" + sCrime_4;
            } else
            if(iSetInmate == 5) {
                message += "Inmate selected:" + sButton_5;
                message += "\nCrime:" + sCrime_5;
            } else
            if(iSetInmate == 6) {
                message += "Inmate selected:" + sButton_6;
                message += "\nCrime:" + sCrime_6;
            } 
            message += "\nPlease enter new crime:";
            llTextBox(sID, message , chan);
        } else
        if(iMakeInmate > 0) {
            Database_Save(iMakeInmate, "none");
            llSleep(2.0);
            iSetInmate = iMakeInmate;
            iMakeInmate = 0;
            Database_Read(iSetInmate);
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
    
        Clean();
        give_key = NULL_KEY;
    
    } 
    on_rez(integer iParam) {
        
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
                llMessageLinked(LINK_SET, 3, "1", "");
                if(iMenu) {
                    llMessageLinked(LINK_SET, 2, "1", kKey);
                } 
                //llSetTexture(COLLAR_GIVER, FACE);
            } else{            
                if(iMenu) {
                    llMessageLinked(LINK_SET, 2, "0", kKey);
                } 
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
        if(user_key == NULL_KEY)
        {
            
            integer i = Authentification(kKey);
            if(i == 1) {
                iFailed = 0;
                llMessageLinked(LINK_SET, 1, "check", kKey);
            } else if(i == -1) {
                llPlaySound(Sound_Close, fVolum);
                llInstantMessage(kKey, "An active BG group is required. Having the Welcoem Group is not an official BG member group tag.");
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
                UserComand(sID, llToLower(msg));
            } else
            if(iSetInmate > 0) {
                Database_Save(iSetInmate, msg);
                iSetInmate = 0;
                Clean();
                llSleep(2.0);
                llMessageLinked(LINK_SET, 4, "numbers", sID);    
            } 
        } 
    } 
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == 2) {
            g_iOnline = (integer)sStr;
            if(g_iOnline) {
                llMessageLinked(LINK_SET, 4, "numbers", kID);
            } 
        } else
        if(iNum == 3) {
            g_iOnline = (integer)sStr;
        } else
        if(iNum == 5) {
            if((key)kID) {
                sButton_1 = "1";
                sButton_2 = "2";
                sButton_3 = "3";
                sButton_4 = "4";
                sButton_5 = "5";
                sButton_6 = "6";
                sCrime_1 = "";
                sCrime_2 = "";
                sCrime_3 = "";
                sCrime_4 = "";
                sCrime_5 = "";
                sCrime_6 = "";
                sPromt = "INMATES:\n";
                if(sStr == "<No records.>") {  
                    sPromt += "None, maybe not registered.";

                } else{
                    list lParams = llParseString2List(sStr, ["@"], []);
                    string sNumber;
                    
                    sNumber = "";
                    sNumber = llList2String(lParams, 0);
                    if(~llSubStringIndex(sNumber, "P-6")) {
                        sButton_1 = sNumber;
                        sCrime_1 = llList2String(lParams, 1);
                    } 
                    sNumber = "";
                    sNumber = llList2String(lParams, 2);
                    if(~llSubStringIndex(sNumber, "P-6")) {
                        sButton_2 = sNumber;
                        sCrime_2 = llList2String(lParams, 3);
                    } 
                    sNumber = "";
                    sNumber = llList2String(lParams, 4);
                    if(~llSubStringIndex(sNumber, "P-6")) {
                        sButton_3 = sNumber;
                        sCrime_3 = llList2String(lParams, 5);
                    } 
                    sNumber = "";
                    sNumber = llList2String(lParams, 6);
                    if(~llSubStringIndex(sNumber, "P-6")) {
                        sButton_4 = sNumber;
                        sCrime_4 = llList2String(lParams, 7);
                    } 
                    sNumber = "";
                    sNumber = llList2String(lParams, 8);
                    if(~llSubStringIndex(sNumber, "P-6")) {
                        sButton_5 = sNumber;
                        sCrime_5 = llList2String(lParams, 9);
                    } 
                    sNumber = "";
                    sNumber = llList2String(lParams, 10);
                    if(~llSubStringIndex(sNumber, "P-6")) {
                        sButton_6 = sNumber;
                        sCrime_6 = llList2String(lParams, 11);
                    } 
                    sPromt += sButton_1 + " > " + sCrime_1 + "\n";
                    sPromt += sButton_2 + " > " + sCrime_2 + "\n";
                    sPromt += sButton_3 + " > " + sCrime_3 + "\n";
                    sPromt += sButton_4 + " > " + sCrime_4 + "\n";
                    sPromt += sButton_5 + " > " + sCrime_5 + "\n";
                    sPromt += sButton_6 + " > " + sCrime_6 + "\n";
                } 
                sPromt = llGetSubString(sPromt, 0, 500);
                lButtons = [];
                lButtons += sButton_1;
                lButtons += sButton_2;
                lButtons += sButton_3;
                lButtons += sButton_4;
                lButtons += sButton_5;
                lButtons += sButton_6;
                if(llGetListLength(lButtons) <= 0) {
                    lButtons = ["-", "-", "-"];
                } 
                Generate(kID, "main");
            } 
        } 
        
        if(iNum == 4 && sStr == "numbers") {
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
                    llMessageLinked(LINK_SET, 5, "<ERROR>", kID);
                } 
            } else{
                llMessageLinked(LINK_SET, 5, "<ERROR>", kID);
            } 
        } 
        
        if(iNum == 1 && sStr == "check") {
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

