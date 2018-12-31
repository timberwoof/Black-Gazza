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

string gInmateToZap = "";

integer giActiveState = 0;
integer isACTIVE = 2;
integer isPRESENT = 1;
integer isINACTIVE = 0;

string logTitle = "Terminal Log";
string logText = "";

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

// the mainframe is setting the camera position to this terminal. 
// Make the terminal look alive and identify who's on the mainframe. 
activate(integer newstate, string newName, key newKey) {
    integer lensprim = 1;
    integer lensside = 2;
    gsWardenName = newName;
    giActiveState = newstate;
    gkWarden = newKey;
    
    string statusText = "Terminal status update.   Designator:" + gsMyLocationDesignator + "   Description:"+ gsMyDescription;
    vector textColor = <1,0,0>;
    
    if (newstate == isACTIVE) {
        llPlaySound("beepbeepbeepbeep",1.0);
        llSetLinkPrimitiveParams(lensprim,[PRIM_FULLBRIGHT,lensside,TRUE]);
        llSetLinkPrimitiveParams(lensprim,[PRIM_GLOW,lensside,0.3]);
        statusText = statusText + "   Status:Active   Operator:" + newName;
        textColor = <1.0, 0.75, 0>;
        giMyOpenListen = llListen(0,"","","");
        floatyLog("ACTIVE "+newName);

    } else if (newstate == isPRESENT) {
        llSetLinkPrimitiveParams(lensprim,[PRIM_FULLBRIGHT,lensside,TRUE]);
        llSetLinkPrimitiveParams(lensprim,[PRIM_GLOW,lensside,0.0]);
        statusText = statusText + "   Status:Present   Operator:" + newName;
        textColor = <0.75, 0.5, 0>;
        llListenRemove(giMyOpenListen);
        giMyOpenListen = 0;
        floatyLog("PRESENT "+newName);
    } else if (newstate == isINACTIVE) {
        llPlaySound("beepbeepbeepbeep",1.0);
        llSetLinkPrimitiveParams(lensprim,[PRIM_FULLBRIGHT,lensside,FALSE]);
        llSetLinkPrimitiveParams(lensprim,[PRIM_GLOW,lensside,0.0]);
        statusText = statusText + "   Status:Vacant";
        textColor = <0.75, 0.75, 0.75>;
        llListenRemove(giMyOpenListen);
        giMyOpenListen = 0;
        floatyLog("INACTIVE "+newName);
    }
    if (gStausText != statusText)
    {
        //llWhisper(0,statusText);
        gStausText = statusText;
    }
}

zap (list commandList) {
    string recipient = llList2String(commandList,1);
    string firstthree = llToUpper(llGetSubString(recipient,0,2));
    if (firstthree == "P-6") {
        llInstantMessage(gkWarden,"I think " + recipient + " is a collar number. I can't zap those yet.");
    } else {
        gInmateToZap = recipient;
        llSensor("","",AGENT,20,PI);
    }
}

default
{
    state_entry()
    {
        // most of this is just verifying that descriptions got set correctly. 
        floatyLog("Log Begins");
        llSetRemoteScriptAccessPin(giUpdatePin);
        gsMyDescription = llGetObjectDesc();
        activate(isACTIVE,"state_entry","");
        llSleep(10);
        giRegistrationListen = llListen(giRegistrationChannel, gsSystemName, "", "");
        gsMyCommandChannel = coordinatesToChannel(llGetPos());
        giMyCommandChannel = (integer)gsMyCommandChannel;
        //register(); // don't register until asked
        giMyCommandListen = llListen(giMyCommandChannel, gsSystemName, "", "");
        activate(giActiveState,"iniitlaized",gkWarden);
    }

    touch_start(integer num_detected)
    {
        //llSay(0,(string)llDetectedLinkNumber(0));
        llSay(0,"Paging the "+gsSystemName+". Please stand by.");
        string pageMessage  = "page," + gsMyLocationDesignator + "," + (string)gsMyCommandChannel + "," + llKey2Name(llDetectedKey(0));
        floatyLog("page:"+pageMessage);
        llRegionSay(giRegistrationChannel,pageMessage);
        llInstantMessage(llDetectedKey(0),gStausText);
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
            } else  if (command == "present") {
                activate(isPRESENT, llList2String(messageList,1), (key)llList2String(messageList,2));
            } else if (command == "absent") {
                activate(isINACTIVE, llList2String(messageList,1), (key)llList2String(messageList,2));
            } else if (command == "deactivate") {
                activate(isINACTIVE, llList2String(messageList,1), (key)llList2String(messageList,2));
            }
            
        // if we receive a specialized order from the mainframe
        } else if (channel == giMyCommandChannel) {
            //llWhisper(0,"command message");
            //llWhisper(0,"channel:" + (string)channel + " message:" + message);
            floatyLog("command:"+message);
            list messageList = llCSV2List(message);
            string command = llList2String(messageList,0);
            if (command == "activate") {
                activate(isACTIVE, llList2String(messageList,1), (key)llList2String(messageList,2));
            } else if (command == "designator") {
                gsMyLocationDesignator = llList2String(messageList,1);
                llSetObjectName(gsSystemName + " Terminal " + gsMyLocationDesignator);
                activate(giActiveState,gsWardenName,gkWarden);
            } else if (command == "say") {
                // chop off the beginning part of the message; only say the relevant part. 
                llSay(0,llGetSubString(message,8,-1));
            } else if (command == "loopback") {
                llInstantMessage(gkWarden,llGetSubString(message,8,-1));
            } else if (command == "zap") {
                zap(messageList);
            }

        // anything that comes in over the open listen gets sent to the sitting avatar. 
        } else if ( (0 != giMyOpenListen) && (channel = giMyOpenListen) && ( "" != gkWarden) ) {
            llInstantMessage(gkWarden,name+ ": " +message);
        }
    }
    
    sensor( integer detected) {
        integer stringLen = llStringLength(gInmateToZap);
        while(detected--) {
            string fullname = llDetectedName(detected);
            string nameFragment = llGetSubString(fullname,0,stringLen-1);
            if ( (llToUpper(gInmateToZap) == llToUpper(nameFragment)) || (gInmateToZap == "EVERYONE") ) {
                llSay(giZapChannel,(string)llDetectedKey(detected));
            }
        }
    }
}
