// Station AI Devices and Registration

// altitudes list
// This list sets up the relationship between altitude and the first number of the location designator. 
// You can think of these as deck numbers, starting with 1 for Isolation. 
list altitudesList = [0, 1155, 1165, 1200, 1210, 1215, 1220, 1225, 1230, 1235, 1240, 
    1275, 1280,   1305, 1310,    1335, 1340, 1345, 
    1370, 1375, 1380,     1405, 1430, 1455, 1480];

vector coreLocation = <128,128,0>;
string gsSystemName = "Central Scrutinizer";

string initialTerminal = "13f13";


// all devices that want to register do so on this channel;
// when the Brain resets, it asks for registrations on this channel
integer gRegistrationChannel = 7659005;
integer gRegistrationListen;

// If the avatar sitting in Brain Seat talks on this channel, the brain tells them to shut up. 
integer gShutupChannel = 0;
integer gShutupListen;

// Avatar sitting in Brain Seat talks on this channel. 
integer gTalkChannel = 1;
integer gTalkListen;

// Avatar sitting in Brain Seat gives commands on this channel. 
integer gCommandChannel = 2;
integer gCommandListen;

// channel from the active terminal. 
integer gActiveTerminalChannel = 0;
integer gActiveTerminalListen = 0;

integer gACSChannel = 360;
integer giACSInterferenceAmount = 0;

// device list is a strided list
// it contains all registered devices
list deviceList = [];
integer deviceListOffsetType = 0;
integer deviceListOffsetChannel = 1;
integer deviceListOffsetLocation = 2;
integer deviceListOffsetDescription = 3;
integer deviceListOffsetCoordinates = 4;
integer deviceListOffsetRotation = 5;
integer deviceListStride = 6;

integer cycleDeviceNumber = 0;
string cycleDeviceFilter = "";

integer gReportLevel = 0; // memory monitor start/stop
integer ERROR = 0;
integer WARN = 1;
integer INFO = 2;
integer DEBUG = 3;
integer TRACE = 4;

// *******
// Utility functions

integer IsInteger(string var){
// http://wiki.secondlife.com/wiki/Integer
    integer i;
    for(i=0;i<llStringLength(var);++i){
        if(!~llListFindList(["1","2","3","4","5","6","7","8","9","0"],[llGetSubString(var,i,i)])){
            return FALSE;
        }
    }
    return TRUE;
}

twDebug(integer debugLevel, string message)
{
    llMessageLinked(LINK_THIS, 900+debugLevel, message, "");
}
setDebugLevel(string sDebugLevel)
{
    llMessageLinked(LINK_THIS, 998, sDebugLevel, "");
}
setReportLevel(string sReportLevel) 
{
            if(IsInteger(sReportLevel)) {
                gReportLevel = (integer)sReportLevel;
                if(gReportLevel > 0)
                {
                    twDebug(INFO,"beginning memory monitor");
                    llScriptProfiler(PROFILE_SCRIPT_MEMORY);
                }
                else{
                    twDebug(INFO,"ending memory monitor");
                    llScriptProfiler(PROFILE_NONE);
                    twDebug(INFO, "Memory:" +
                        " Used: " + (string)llGetUsedMemory() + 
                        " Free: " + (string)llGetFreeMemory() + 
                        " Max: " + (string)llGetSPMaxMemory() + 
                        " Limit: " +  (string)llGetMemoryLimit() + 
                        " " );
                }
            } else {
                twDebug(WARN,"unable to set report level to "+sReportLevel+": not an integer");
            }
}

// Lockdown
integer gLockDownChannel = -765489;
integer gLockDownHandle = 0;
string gLockDownState = "RELEASED"; // "LOCKED" or "RELEASED"

reportLockDown(){
    twDebug(INFO, "Lockdown Status:"+gLockDownState);
}

getSetLockdown(string action){
// "  lockdown { status | lock | release} - get or set lockdown status.\n"
    if(action == "status"){
        llRegionSay(gLockDownChannel,"INQUIRY");
    }
    else if(action == "lockdown"){
        twDebug(INFO, "sending lockdown command");
        llRegionSay(gLockDownChannel,"LOCKDOWN");
    }
    else if(action == "release"){
        twDebug(INFO, "sending release command");
        llRegionSay(gLockDownChannel,"RELEASE");
    }
    else {
        twDebug(INFO, "lockdown command has three options: status, lockdown, release");
        llRegionSay(gLockDownChannel,"INQUIRY");
    }
}

// device registration
registerDevice(string deviceName, string deviceMessage){
    // registration message from device looks like this:
    // register,1932051327,description,<193.93410, 205.39699, 1327.13428>,<0.00000, 0.00000, 0.00000, 1.00000>
    // parse message into pieces
    twDebug(TRACE,"registerDevice "+deviceName+": "+deviceMessage);
    list deviceParameters = llCSV2List(deviceMessage);
    string sChannel = llList2String(deviceParameters,1);
    if((integer)sChannel == 0){
        twDebug(WARN,"registerDevice "+deviceName+" had channel 0. Not registering it.");
        return;
    }
    
    string deviceDescription = llList2String(deviceParameters,2);
    if (deviceDescription == "Cell") return;
    string locationDesignator = channelToLocation(sChannel);
    if (llSubStringIndex(deviceMessage,"Remote:R-") > -1){
         list parts = llParseString2List( deviceDescription, [":"], [] );
         locationDesignator = llList2String(parts,1);
         deviceDescription = "Remote " + llList2String(parts,2);
    }
    vector devicePosition =(vector)llList2String(deviceParameters,3);
    rotation deviceRotation =(rotation)llList2String(deviceParameters,4);

    // add the item to the list
    addOrupdateDevice(deviceName, (integer)sChannel, locationDesignator, deviceDescription, devicePosition, deviceRotation);
    llRegionSay((integer)sChannel,"designator," + locationDesignator);
    twDebug(INFO,"registered \"" + deviceName + "\" at " + locationDesignator + "; " + deviceDescription);
}

updateEyepoint(string deviceName, string deviceMessage){
    list deviceParameters = llCSV2List(deviceMessage);
    vector terminalPosition =(vector)llList2String(deviceParameters,3);
    rotation cameraRotation =(rotation)llList2String(deviceParameters,4);
    vector cameraPosition = <-1.0, 0, 1.5> * cameraRotation + terminalPosition;
    vector cameraFocus =  <1.0, 0, 0.8> * cameraRotation + terminalPosition;
    // This is ONLY for implant terminals. 
        
    if(havePermissions == 1) {
        llSetCameraParams([
        CAMERA_ACTIVE, 1, // 1 is active, 0 is inactive
        CAMERA_BEHINDNESS_ANGLE, 0.0, //(0 to 180) degrees
        CAMERA_BEHINDNESS_LAG, 0.0, //(0 to 3) seconds
        CAMERA_DISTANCE, 0.0, //(0.5 to 10) meters
        CAMERA_FOCUS, cameraFocus, // region relative position
        CAMERA_FOCUS_LAG, 0.0 , //(0 to 3) seconds
        CAMERA_FOCUS_LOCKED, TRUE, //(TRUE or FALSE)
        CAMERA_FOCUS_THRESHOLD, 0.0, //(0 to 4) meters
        //CAMERA_PITCH, 80.0, //(-45 to 80) degrees
        CAMERA_POSITION, cameraPosition, // region relative position
        CAMERA_POSITION_LAG, 0.0, //(0 to 3) seconds
        CAMERA_POSITION_LOCKED, TRUE, //(TRUE or FALSE)
        CAMERA_POSITION_THRESHOLD, 0.0, //(0 to 4) meters
        CAMERA_FOCUS_OFFSET, ZERO_VECTOR // <-10,-10,-10> to <10,10,10> meters
        ]);
    }
}


// add a device to the list
addOrupdateDevice(string newName, integer newChannel, string newLocationDesignator, string newDescription, vector newDevicePosition, rotation newDeviceRotation) {
    integer index;
    integer limit = llGetListLength(deviceList);

    // look for the device in the list
    for(index = 0; index < limit; index = index + deviceListStride) {
        string name = llList2String(deviceList, index + deviceListOffsetType);
        integer channel = llList2Integer(deviceList, index + deviceListOffsetChannel);
        string location = llList2String(deviceList, index + deviceListOffsetLocation);

        // if it's in the list, update the list and bail
        if((name == newName) &&(location == newLocationDesignator)) { 
           deviceList = llListReplaceList(deviceList, [newName, newChannel, newLocationDesignator, newDescription, newDevicePosition, newDeviceRotation], index, index+deviceListOffsetRotation);
           twDebug(DEBUG,"updated device:" + newName + " location:" + newLocationDesignator + " description:" + newDescription);
           return;
        }
    }
    
    // if it's not already in the list, add it
    deviceList =(deviceList=[]) + deviceList + [newName, newChannel, newLocationDesignator, newDescription, newDevicePosition, newDeviceRotation];
    twDebug(DEBUG,"added device:" + newName + " location:" + newLocationDesignator + " description:" + newDescription);
}

// print list of devices registered
// devicefilter lists devices of a specific type
// "" means all devices(no filter)
listDevices(string deviceFilter) {
    integer index;
    integer limit = llGetListLength(deviceList);
    string output = "";
    for(index = 0; index < limit; index = index + deviceListStride) {
        twDebug(DEBUG,"listDevices "+(string)index);
        string name = llList2String(deviceList, index + deviceListOffsetType);
        string location = llList2String(deviceList, index + deviceListOffsetLocation);
        string description = llList2String(deviceList, index + deviceListOffsetDescription);
        output = name + ": " + location + ", " + description;
        twDebug(INFO, output);
        // this is throttled to one per second by LSL, so this takes a while
    }
}

// set up a timer that causes the active terminal 
// to switch the active terminal from one terminal to the next every ten seconds. 
StartTerminalCycle(integer index, string filter) {
    if(gSitterKey != "") {
        cycleDeviceNumber = index;
        cycleDeviceFilter = llToLower(filter);
        twDebug(INFO,"starting terminal activation cycle at " +(string)cycleDeviceNumber);
        twDebug(INFO,"To stop, type /2 stop");
        llSetTimerEvent(10);
    } 
    else {
        llSetTimerEvent(0);
    }
}

StopTerminalCycle() {
    llSetTimerEvent(0);
    twDebug(INFO,"cycle stopped.");
}

integer cycleFilterFunction(string description, string filter, string name, string searchFor) {
    if(filter == ""){
        return llSubStringIndex(name, searchFor) == -1;
    }
    else{
        return(llSubStringIndex(description, filter) == -1) | (llSubStringIndex(name, searchFor) == -1);
    }
}

// gets called by timer every ten seconds
// to switch the active terminal from one terminal to the next
cycleDeviceWithFilter(string filter) {
    if(gSitterKey != "") {
        twDebug(DEBUG,"cycleDeviceWithFilter:'"+filter+"'");
        integer limit = llGetListLength(deviceList);
        integer index = cycleDeviceNumber * deviceListStride;
        string name = llToLower(llList2String(deviceList, index + deviceListOffsetType));
        string terminalDesignator = llList2String(deviceList, index + deviceListOffsetLocation);
        string description = llToLower(llList2String(deviceList, index + deviceListOffsetDescription));
        string searchFor = gsSystemName;
        
        // skip things that are not terminals
        // or don't match the filter
        while(cycleFilterFunction(description, filter, name, searchFor)){
            twDebug(TRACE,"cycleDeviceWithFilter "+description+","+filter+","+name+","+searchFor);
            cycleDeviceNumber = cycleDeviceNumber + 1;
            if(cycleDeviceNumber > limit) 
           {
                cycleDeviceNumber = 0;
            }
            index = cycleDeviceNumber * deviceListStride;
            name = llList2String(deviceList, index + deviceListOffsetType);
            terminalDesignator = llList2String(deviceList, index + deviceListOffsetLocation);
            description = description = llToLower(llList2String(deviceList, index + deviceListOffsetDescription));
        }   
    
        activate(terminalDesignator);

        // prepare the next device number in the sequence
        cycleDeviceNumber = cycleDeviceNumber + 1;
        if(cycleDeviceNumber > limit) {
            cycleDeviceNumber = 0;
        }   
    } 
    else {
        twDebug(DEBUG,"cycleDeviceWithFilter:'"+filter+"' canceled because gSitterKey is null");
        llSetTimerEvent(0);
    }
}

Search(list CommandList){
    twDebug(DEBUG,"Search "+(string)CommandList);
    string searchterm = llToLower(llList2String(CommandList,1));
    integer foundcount = 0;
    integer limit = llGetListLength(deviceList);
    integer index = 0; 
    while(index < limit) {
        twDebug(TRACE,"Search "+(string)index);
        string name = llList2String(deviceList, index + deviceListOffsetType);
        string location = llList2String(deviceList, index + deviceListOffsetLocation);
        string description = llList2String(deviceList, index + deviceListOffsetDescription);
        string allstring = llToLower(name + " " + location + " " + description);            
        if(llSubStringIndex(allstring, searchterm) > -1){
            twDebug(DEBUG,"found: " + allstring);
            foundcount = foundcount + 1;
        }
        index = index + deviceListStride;
    }
    twDebug(DEBUG,"Search complete. Found "+(string)foundcount+ " item(s).");
}

integer SendMessageToOneDevice(string designator, string message) {
    twDebug(DEBUG,"SendMessageToOneDevice(\""+designator+"\", \""+message+"\")");
    list theDevice = findDeviceByDesignator(designator);
    integer channel = llList2Integer(theDevice,deviceListOffsetChannel);
    if(channel != 0) {
        twDebug(TRACE,"sending message \""+message+"\" to channel "+(string)channel);
        llRegionSay(channel,message);
    }
    else
    {
        twDebug(ERROR, "SendMessageToOneDevice channel was "+(string)channel);
    }
    return channel;
}

list findDeviceByDesignator(string designator) {
    designator = llToLower(designator);
    twDebug(DEBUG,"findDeviceByDesignator ("+designator+")");
    integer index;
    integer limit = llGetListLength(deviceList);
    list result = [];
    for(index = 0; index < limit; index = index + deviceListStride) {
        string location = llToLower(llList2String(deviceList, index + deviceListOffsetLocation));
        if(location == designator) {
            result = llList2List(deviceList, index, index+deviceListStride-1);
        }
    }
    twDebug(DEBUG,"findDeviceByDesignator returns "+(string)result);
    return result;
}

// convert altitude in meters to an arbitrary level designation 
integer altitudeToLevel(float altitude) {
    integer index = 0;
    while(llList2Integer(altitudesList,index) < altitude) {
        index = index + 1;
    }
    index = index -1;
    return index;
}

// convert angle around station axis to a 1-12(hours) segment number
integer XYtoSegment(float X, float Y) {
    float deltax = X - coreLocation.x;
    float deltay = Y - coreLocation.y;
    integer result = llFloor((PI/2 - llAtan2(deltay, deltax)) * 9 / PI) ;
    if(result < 1) {
        result = result + 18;
    }
    return result;
}

// convert distance from station axis to 4-meter rings. 
string XYtoRing(float X, float Y) {
    float deltax = X - coreLocation.x;
    float deltay = Y - coreLocation.y;
    integer distance = llFloor(llSqrt(deltax * deltax + deltay * deltay)/4);
    return llGetSubString("abcdefghijklm",distance,distance);
}

// convert device X,Y,Z location to an easier alphanumeric designation. 
string channelToLocation(string message) {
    string locX = llGetSubString(message,0,2);
    string locY = llGetSubString(message,3,5);
    string locZ = llGetSubString(message,6,-1);
    vector location = <(float)locX,(float)locY,(float)locZ >;
    
    string result =(string)altitudeToLevel(location.z) + XYtoRing(location.x, location.y) +(string)XYtoSegment(location.x, location.y);
    twDebug(DEBUG,"channelToLocation returns "+result);
    return result;
}

// ============
// Sit
integer havePermissions = 0;
string gSitterName;
key gSitterKey;
string gsPreviousTerminalDesignator = "";

// Stop all animations
stop_anims(key agent){
    list l = llGetAnimationList(agent);
    integer lsize = llGetListLength(l);
    integer i;
    for(i = 0; i < lsize; i++){
        llStopAnimation(llList2Key(l, i));
    }
}



initialize() {
    setDebugLevel("DEBUG");
    twDebug(INFO,"initializing");
    giACSInterferenceAmount = 0;
    llMessageLinked(LINK_THIS, 999, "avatar","");
    setReportLevel("0");
    rotation primRotation = llGetRot();
    rotation avrotation = llEuler2Rot(<0, 0, 0> * DEG_TO_RAD);
  
    llSetSitText(gsSystemName);
    llSitTarget(<0.0, 0.0, 0.1> ,  avrotation);
    gSitterKey = "";
    llMessageLinked(LINK_THIS, 999, "avatar",gSitterKey);

    llListenRemove(gLockDownHandle);
    gLockDownHandle = llListen(gLockDownChannel,"",NULL_KEY,"");
    llRegionSay(gLockDownChannel,"INQUIRY");
    
    gRegistrationListen  = llListen(gRegistrationChannel,"","","");
    llRegionSay(gRegistrationChannel,"REGISTER,default");
    
    twDebug(INFO,"Initialization complete; awaiting registration messages.");
}

// set the sitter's camera to the parameters sent in the list
activate(string terminalDesignator) {
    twDebug(DEBUG,"activate ("+terminalDesignator+")");
    // get the new active device
    list theDevice = findDeviceByDesignator(terminalDesignator);
    
    if(theDevice != []) {
        string deviceDescription = llList2String(theDevice,deviceListOffsetDescription);
        twDebug(INFO,"activating " + terminalDesignator + ": " + deviceDescription);
    
        //get the device location and position
        vector terminalPosition = llList2Vector(theDevice, deviceListOffsetCoordinates);
        rotation cameraRotation = llList2Rot(theDevice, deviceListOffsetRotation);
        vector cameraPosition = <-0.01,0,0> * cameraRotation + terminalPosition;
        vector cameraFocus =  <1.0,0,0> * cameraRotation + terminalPosition;
        
        twDebug(DEBUG,"llSetCameraParams cameraFocus:" + (string)cameraFocus + " cameraPosition:" + (string)cameraPosition);
        
        if(havePermissions == 1) {
            llSetCameraParams([
            CAMERA_ACTIVE, 1, // 1 is active, 0 is inactive
            CAMERA_BEHINDNESS_ANGLE, 0.0, //(0 to 180) degrees
            CAMERA_BEHINDNESS_LAG, 0.0, //(0 to 3) seconds
            CAMERA_DISTANCE, 0.0, //(0.5 to 10) meters
            CAMERA_FOCUS, cameraFocus, // region relative position
            CAMERA_FOCUS_LAG, 0.0 , //(0 to 3) seconds
            CAMERA_FOCUS_LOCKED, TRUE, //(TRUE or FALSE)
            CAMERA_FOCUS_THRESHOLD, 0.0, //(0 to 4) meters
            //CAMERA_PITCH, 80.0, //(-45 to 80) degrees
            CAMERA_POSITION, cameraPosition, // region relative position
            CAMERA_POSITION_LAG, 0.0, //(0 to 3) seconds
            CAMERA_POSITION_LOCKED, TRUE, //(TRUE or FALSE)
            CAMERA_POSITION_THRESHOLD, 0.0, //(0 to 4) meters
            CAMERA_FOCUS_OFFSET, ZERO_VECTOR // <-10,-10,-10> to <10,10,10> meters
            ]);
        } else {
            twDebug(WARN,"error: did not have permission to set your camera.");
        }
        // tell every terminal that someone is present
        llMessageLinked(LINK_THIS, 999, "avatar",gSitterKey);
        llRegionSay(gRegistrationChannel,"present," + gSitterName + "," +(string)gSitterKey);
        llSleep(0.5);// delay so that the active terminal doesn't get its data wiped out
        // send it the activate command. 
        gActiveTerminalChannel = llList2Integer(theDevice,deviceListOffsetChannel);
        string message = "activate," + gSitterName + "," +(string)gSitterKey;
        SendMessageToOneDevice(terminalDesignator, message);
        gsPreviousTerminalDesignator = terminalDesignator;
    } else {
        twDebug(WARN,"Could not find " + terminalDesignator);
    }
}

deactivate(string terminalDesignator) {
    twDebug(DEBUG,"deactivate "+terminalDesignator);
    string message = "deactivate," + gSitterName + "," +(string)gSitterKey;
    SendMessageToOneDevice(terminalDesignator,message);
}

absent() {
    llRegionSay(gRegistrationChannel,"deactivate," + gSitterName + "," +(string)gSitterKey);
}

help() {
    twDebug(INFO, 
    "Welcome, " + gSitterName + ". You are now the "+gsSystemName+", an AI.\n" +
    "Issue commands by typing /" +(string)gCommandChannel + " and then the command.\n" +
    "The Core Computer knows these commands:\n" +
    "  activate <device> - sends  your eyepoint to that terminal.\n" +
    "  cycle - activates all terminals in sequence. You scan the station.\n" +
    "  cycle {filter} - sequentially activates registered terminals in sequence that have \"filter\" in the name. You scan the station.\n" +
    "  debug - set debug level: 0-4 = ERROR, WARN, INFO, DEBUG, TRACE.\n" + 
    "  help - lists commands known by the Core Computer.\n" +
    "  lockdown { status | lockdown | release} - get or set lockdown status.\n" +
    "  list - lists terminals you can command.(Slow!)\n" +
    "  report - set memory report level. 1 = start monitoring; 0 = stop monitoring and report\n" + 
    "  register <filter> - clears device list and asks every device matching <filter> to send registration information.\n" +
    "  scan {filter} - sequentially activates registered terminals in sequence that have \"filter\" in the name. You scan the station.\n" +
    "  status - shows this script's memory usage. You must set debug to 1 for this to work.\n" +
    "  stop - stops terminal activation cycle. \n" +
    "  zap <name> - zaps the inmate. \n" +
    "<device> is a device designator, for example "+initialTerminal+" for the terminal in the "+gsSystemName+" room.\n" +
    "Talk by typing /" +(string)gTalkChannel + " ahead of your speech.\n" +
    "");
}

default{
    on_rez(integer param){
        initialize();
    }

    state_entry() {
        initialize();
    }

    changed(integer change) {
        if(change & CHANGED_LINK) {
            // Someone sat or stood up ...
            gSitterKey = llAvatarOnSitTarget();
            llMessageLinked(LINK_THIS, 999, "avatar",gSitterKey);
            if(gSitterKey) {
                // Sat down
                llRequestPermissions(gSitterKey, PERMISSION_TRIGGER_ANIMATION | PERMISSION_CONTROL_CAMERA);
            } else {
                // Stood up(or maybe crashed!)
                havePermissions = 0;
                gSitterKey = llGetPermissionsKey();
                llMessageLinked(LINK_THIS, 999, "avatar",gSitterKey);
                llMessageLinked(LINK_THIS, 1010, "no", "");
                if(llGetAgentSize(gSitterKey) != ZERO_VECTOR) {
                    // agent is still in the sim.
                    if(llGetPermissions() &(PERMISSION_TRIGGER_ANIMATION | PERMISSION_CONTROL_CAMERA)) {
                        // Only stop anis if permission was granted previously.
                        stop_anims(gSitterKey);
                    }
                }
                twDebug(INFO,"processing stand up");
                gSitterName = "nobody";
                llRegionSay(gRegistrationChannel,"absent,nobody,");
                llListenRemove(gTalkListen);
                llListenRemove(gCommandListen);
                StopTerminalCycle();
                absent();
                llResetScript();
            }
        }
    }    
    
    run_time_permissions(integer permissions){
        if(permissions &(PERMISSION_TRIGGER_ANIMATION | PERMISSION_CONTROL_CAMERA)){
            gSitterKey = llGetPermissionsKey();
            llMessageLinked(LINK_THIS, 999, "avatar",gSitterKey);
            llMessageLinked(LINK_THIS, 1011, "yes", "");
            gSitterName = llKey2Name(gSitterKey);
            stop_anims(gSitterKey);
            llStartAnimation("stasis"); 
            havePermissions = 1;
            
            // set up listens
            gShutupListen = llListen(gShutupChannel, gSitterName, gSitterKey, "");
            gTalkListen = llListen(gTalkChannel, gSitterName, gSitterKey, "");
            gCommandListen = llListen(gCommandChannel, gSitterName, gSitterKey, ""); 

            // activate the terminal in Control Room
            activate(initialTerminal);
            llRegionSay(gRegistrationChannel,"present," + gSitterName + "," +(string)gSitterKey);
            twDebug(WARN,"Please use /" +(string)gTalkChannel +
            " to talk and /" +(string)gCommandChannel + " for commands.");
        } else {
            twDebug(ERROR,"FAILED to initialize");
            llResetScript();
        }
    }

    link_message(integer Sender, integer Number, string message, key Key)
    {
        if (Number == gACSChannel)
        {
            integer newInterferenceLevel = (integer)message;
            if (newInterferenceLevel != giACSInterferenceAmount)
            {
                giACSInterferenceAmount = newInterferenceLevel;
                if (giACSInterferenceAmount = 0)
                {
                    activate(initialTerminal);            
                }            
            }
        }
    }

    
    // command processor
    listen(integer channel, string name, key id, string message) 
    {
        twDebug(TRACE,"listen ("+(string)channel +","+ name + ",\"" + message+"\")");
        
        // handle device registrations
        if(gRegistrationChannel == channel) 
        {
            list parameters = llParseString2List(message, [","], []);
            string command = llToLower(llList2String(parameters,0));

            if(command == "register") 
            {
                registerDevice(name, message);    
            } 
            else if(command == "update") 
            {
                if (llSubStringIndex(llToLower(message), gsPreviousTerminalDesignator) > -1)
                    updateEyepoint(name, message);
            } 
            else if(command == "page") 
            {
                string designation = llList2String(parameters,1);
                integer pagerChannel = (integer)llList2String(parameters,2);
                string pagername = llList2String(parameters,3);
                if(gSitterKey != "") 
                {
                    twDebug(INFO,name+ ": Page from " + pagername + " at terminal " + designation + ".\n"+
                    "   type\n" +
                    "/" +(string)gCommandChannel + " activate " + designation + "\n"+
                    "   to activate that terminal.");
                } 
                else if(pagerChannel != 0) 
                {
                    integer space = llSubStringIndex(pagername, " ");
                    pagername = llGetSubString(pagername, 0, space-1); // just the first name
                    llRegionSay(pagerChannel,"say,    I'm sorry, " + pagername + ". I'm afraid I can't do that.");
                }
            }
        }
            
        if(gShutupChannel == channel) 
        {
            twDebug(WARN,"Please use /" +(string)gTalkChannel +
            " to talk and /" +(string)gCommandChannel + " for commands.");
        }
        
        if((gTalkChannel == channel) &&(gActiveTerminalChannel != 0))
        {
            llMessageLinked(LINK_THIS, gTalkChannel, (string)gActiveTerminalChannel+":"+message, "");
        }
        
        // handle commands from the sitter
        if(gCommandChannel == channel) 
        {
            if(gSitterKey == "") 
            {
                return;
            }
            list parameters = llParseString2List(message, [" "], []);
            string command = llToLower(llList2String(parameters,0));
            string parameter = llToLower(llList2String(parameters,1));
            twDebug(INFO,"processing command \""+command+"\" \""+parameter+"\"");
                
            if(command == "activate") 
            {
                deactivate(gsPreviousTerminalDesignator);
                activate(parameter);
            } 
            else if((command == "cycle") |(command == "scan")) 
            {
                StartTerminalCycle(0, parameter);
                
            } 
            else if(command == "debug") 
            {
                setDebugLevel(llToUpper(parameter));
                
            } 
            else if(command == "report") 
            {
                setReportLevel(parameter);
                
            } 
            else if(command == "list") 
            {
                listDevices(parameter);
                
            } 
            else if(command == "lockdown") 
            {
                getSetLockdown(parameter);
                
            } 
            else if(command == "help") 
            {
                help();
            } 
            else if(command == "stop") 
            {
                 StopTerminalCycle();    
            } 
            else if(command == "search") 
            {
                 Search(parameters);    
            } 
            else if(command == "reregister" || command == "register") 
            {
                deviceList = [];
                if (parameter == ""){
                    parameter = "default";
                    }
                llRegionSay(gRegistrationChannel,"REGISTER,"+parameter);    
            } 
            else 
            {
                // see if the command is a designator
                list device = findDeviceByDesignator(command);
                if(device != []) 
                {
                    // we found something, so we have a device.
                    // if command is empty, activate the terminal
                    if (parameter == "")
                    {
                        twDebug(DEBUG,"command handler activating "+command);
                        deactivate(gsPreviousTerminalDesignator);
                        activate(command);
                    }
                    else 
                    {
                        // Send the commands unaltered to the terminal. 
                        twDebug(DEBUG,"command handler sending message \""+parameter+ "\" to terminal " + command);
                        //string message = llList2String(parameters,0) + "," + llList2String(parameters,2);
                        SendMessageToOneDevice(command, parameter);
                    }
                }
                
                // may be a command to the current terminal
                else
                {
                    SendMessageToOneDevice(gsPreviousTerminalDesignator, message);
                }
            } 
        }
        
        // handle lockdown manager message
        if(gLockDownChannel == channel) 
        {
            twDebug(DEBUG,"incoming lockdown status message: "+ message);
            if((message == "RELEASED") ||(message == "release")) 
            {
                gLockDownState = "RELEASED";
            }
            else if((message == "LOCKED") ||(message == "lockdown")) 
            {
                gLockDownState = "LOCKED";
            }
            reportLockDown();
        }
        
        twDebug(TRACE,"listen (" +(string)channel +","+ name + ",\"" + message+"\") done");
    }

    timer() {
            cycleDeviceWithFilter(cycleDeviceFilter);        
    }    
}
