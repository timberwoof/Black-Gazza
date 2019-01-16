integer giZapChannel = -106969;
integer giUpdatePin = 7658042;
integer giRegistrationChannel = 7659005;
string gsSystemName = "Central Scrutinizer";
integer giRegistrationListen;
string gsMyCommandChannel;  
integer giMyCommandChannel;
integer giMyCommandListen;
string gsMyDescription;
string gsMyLocationDesignator = "";
string gsWardenName = "";
string gStausText = "";
integer giMyOpenListen = 0;
key gkWarden;

integer giActiveState = 0;
integer isACTIVE = 2;
integer isPRESENT = 1;
integer isINACTIVE = 0;

string logTitle = "Terminal Log";
string logText = "";

key beepSound = "a4a9945e-8f73-58b8-8680-50cd460a3f46";

string commandList = "on off reset maint stow ready load scan unload stop";

floatyLog(string newEntry)
{
    // chop off the title from the old log
    integer titleLength = llStringLength(logTitle);
    logText = llDeleteSubString(logText, 0, titleLength);
    
    // calculate room left in log
    integer logTextLength = llStringLength(logText);
    string timestamp = llGetTimestamp( );
    timestamp = llGetSubString(timestamp, 14,18);
    newEntry = "\n" + newEntry; //"\n" + timestamp + " " + newEntry;
    integer newEntryLength = llStringLength(newEntry);
    integer chop = titleLength + logTextLength + newEntryLength - 254;
    
    // chop off enough to make room for the new entry;
    if (chop > 0)
    {
        logText = llDeleteSubString(logText, 0, chop);
    }
    logText = logTitle + "\n" + logText + newEntry;
    logText="";
    llSetText(logText,<0,1,0>,1);//logText
}

// register this terminal with the mainframe.
// send it a bunch of information about where it is. 
register(string message) {
    integer colon = llSubStringIndex(message, ",");
    string filter =  llToLower(llGetSubString(message, colon+1, -1));
    string registrationMessage = gsMyCommandChannel + "," + gsMyDescription + "," + (string)llGetPos() + "," + (string)llGetRot();
    if (llSubStringIndex( llToLower(registrationMessage), filter) > -1) {
        floatyLog("register:"+registrationMessage);
        llRegionSay(giRegistrationChannel, "register," + registrationMessage);
    }
}

// convert a poisition vector into a string that encodes the integer meters part; 
// these get used as channel numbers.
// So don't put two terminals or devices within a meter of each other.  
string coordinatesToChannel(vector position) {
    integer iPosX = llFloor(position.x) + 1000;
    integer iPosY = llFloor(position.y) + 1000;
    integer iPosZ = llFloor(position.z) + 10000;
    
    string sPosX = (string)iPosX;
    string sPosY = (string)iPosY;
    string sPosZ = (string)iPosZ;
    return llGetSubString(sPosX,1,-1) + llGetSubString(sPosY,1,-1) + llGetSubString(sPosZ,1,-1);
}

default
{
    state_entry()
    {
        // most of this is just verifying that descriptions got set correctly. 
        floatyLog("Log Begins");
        llSetRemoteScriptAccessPin(giUpdatePin);
        gsMyDescription = llGetObjectDesc();
        llSleep(10);
        giRegistrationListen = llListen(giRegistrationChannel, gsSystemName, "", "");
        gsMyCommandChannel = coordinatesToChannel(llGetPos());
        giMyCommandChannel = (integer)gsMyCommandChannel;
        //register(); // don't register until asked
        giMyCommandListen = llListen(giMyCommandChannel, gsSystemName, "", "");
    }

    listen(integer channel, string name, key id, string message) {
        // if we receive an order form the maindrame to reregister
        if (channel == giRegistrationChannel) {
            //llWhisper(0,"registration message");
            //llWhisper(0,"channel:" + (string)channel + " message:" + message);
            floatyLog("register:"+message);
            list messageList = llCSV2List(message);
            string command = llList2String(messageList,0);
            if (command == "REGISTER") {
                register(message);
            }
            
        // if we receive a specialized order from the mainframe
        } else if (channel == giMyCommandChannel) {
            //llWhisper(0,"command message");
            //llWhisper(0,"channel:" + (string)channel + " message:" + message);
            floatyLog("command:"+message);
            list messageList = llCSV2List(message);
            string command = llList2String(messageList,0);
            if (command == "designator") {
                gsMyLocationDesignator = llList2String(messageList,1);
                //llSetObjectName(gsSystemName + " Terminal " + gsMyLocationDesignator);
                llSetObjectDesc(gsSystemName + " " + gsMyLocationDesignator);
            } else if (command == "loopback") {
                llInstantMessage(gkWarden,llGetSubString(message,8,-1));
            } else if (llSubStringIndex(commandList, command) > -1) {
                llMessageLinked(LINK_THIS, 0, llToLower(command), "");
            } else {
                llInstantMessage(gkWarden,"Did not understand command "+command);
                llInstantMessage(gkWarden,"Available commands are "+commandList);
            }
        } 
    }
    link_message(integer channel, integer num, string message, key id)
    {
        if (num == 1) llInstantMessage(gkWarden,"State: "+message);
    }
}
