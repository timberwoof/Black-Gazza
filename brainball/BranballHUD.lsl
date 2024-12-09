// ===================================
// Brainball Device and Registration

// all brainballs that want to resgiter do so on this channel;
// when the HUD resets, it asks for registrations on this channel
integer gRegistrationChannel = 272462255;
integer gRegistrationListen;

// If the avatar wearign the brainball hud talks on this channel, the brain tells them to shut up. 
integer gShutupChannel = 0;
integer gShutupListen;

// Avatar sitting in branball hud talks on this channel. 
integer gTalkChannel = 1;
integer gTalkListen;

// Avatar sitting in branball hud gives commands on this channel. 
integer gCommandChannel = 2;
integer gCommandListen;

// channel from the active terminal. 
integer gActiveTerminalListen = 0;

integer brainballChannel;
string brainballLocation;
string brainballDescription;
vector brainballCoordinates;
rotation brainballRotation;

integer gDebugLevel = 0;

// *******
// Utility functions

string twList2String(list inlist) {
    integer i;
    string result = "";
    integer listLength = llGetListLength(inlist);
    for (i = 0; i < listLength; i++) {
        result = result + llList2String(inlist,i);
        if (i < listLength-1) {
            result = result+ ",";
        }
    }
    return result;
}

setDebugLevel(string debugLevelS) {
    debug("setting debug level to "+debugLevelS);
    if (IsInteger(debugLevelS)) {
        gDebugLevel = (integer)debugLevelS;
        debug("set debug level to "+(string)gDebugLevel);
    } else {
        debug("unable to set debug level to "+debugLevelS+": not an integer");
    }     
}

debug(string message) {
    if (gDebugLevel > 0) {
        llWhisper(0,message);
    }
}

integer IsInteger(string var)
// http://wiki.secondlife.com/wiki/Integer
{
    integer i;
    for (i=0;i<llStringLength(var);++i)
    {
        if(!~llListFindList(["1","2","3","4","5","6","7","8","9","0"],[llGetSubString(var,i,i)]))
        {
            return FALSE;
        }
    }
    return TRUE;
}

// *******
// device registration
registerDevice(key deviceKey, string deviceName, string deviceMessage){
    // llWhisper(0,"registerDevice deviceName="+deviceName+ " deviceMessage=" +deviceMessage);
    // registration message looks like this:
    // register,1932051327,description,<193.93410, 205.39699, 1327.13428>,<0.00000, 0.00000, 0.00000, 1.00000>
    // parse message into pieces
    list deviceParameters = llCSV2List(deviceMessage);
    string command = llList2String(deviceParameters,0);
    string sChannel = llList2String(deviceParameters,1);
    string deviceDescripiton = llList2String(deviceParameters,2);
    vector devicePosition = (vector)llList2String(deviceParameters,3);
    rotation deviceRotation = (rotation)llList2String(deviceParameters,4);
}

updateEyepoint(key deviceKey, string deviceName, string deviceMessage){
    list deviceParameters = llCSV2List(deviceMessage);
    string command = llList2String(deviceParameters,0);
    string sChannel = llList2String(deviceParameters,1);
    string deviceDescripiton = llList2String(deviceParameters,2);
    vector brainballCoordinates = (vector)llList2String(deviceParameters,3);
    rotation brainballRotation = (rotation)llList2String(deviceParameters,4);

    //get the device location and position
    vector cameraPosition = <-0.01,0,0> * brainballRotation + brainballCoordinates;
    vector cameraFocus =  <1.0,0,0> * brainballRotation + brainballCoordinates;
        
    if (havePermissions == 1) {
        llSetCameraParams([
        CAMERA_ACTIVE, 1, // 1 is active, 0 is inactive
        CAMERA_BEHINDNESS_ANGLE, 0.0, // (0 to 180) degrees
        CAMERA_BEHINDNESS_LAG, 0.0, // (0 to 3) seconds
        CAMERA_DISTANCE, 0.0, // ( 0.5 to 10) meters
        CAMERA_FOCUS, cameraFocus, // region relative position
        CAMERA_FOCUS_LAG, 0.0 , // (0 to 3) seconds
        CAMERA_FOCUS_LOCKED, TRUE, // (TRUE or FALSE)
        CAMERA_FOCUS_THRESHOLD, 0.0, // (0 to 4) meters
        //CAMERA_PITCH, 80.0, // (-45 to 80) degrees
        CAMERA_POSITION, cameraPosition, // region relative position
        CAMERA_POSITION_LAG, 0.0, // (0 to 3) seconds
        CAMERA_POSITION_LOCKED, TRUE, // (TRUE or FALSE)
        CAMERA_POSITION_THRESHOLD, 0.0, // (0 to 4) meters
        CAMERA_FOCUS_OFFSET, ZERO_VECTOR // <-10,-10,-10> to <10,10,10> meters
        ]);
    }
}



// *******
// report status
reportStatus() {
    llInstantMessage(gSitterKey,"free memory: " + (string)llGetFreeMemory() + " bytes");
}



SendMessageToOneDevice(string message) 
{
    llRegionSay(brainballChannel,message);
}



// ============
// Sit
integer havePermissions = 0;
string gSitterName;
key gSitterKey;

// Stop all animations
stop_anims( key agent )
{
    list    l = llGetAnimationList( agent );
    integer    lsize = llGetListLength( l );
    integer i;
    for ( i = 0; i < lsize; i++ )
    {
        llStopAnimation( llList2Key( l, i ) );
    }
}

// *******
// initialize
initialize() {
    llWhisper(0,"initializing");
    setDebugLevel("1");
    llScriptProfiler(PROFILE_SCRIPT_MEMORY);
    rotation primRotation = llGetRot();
    rotation avrotation = llEuler2Rot(<0, 0, 180> * DEG_TO_RAD);
  
    llSetSitText("Warden");
    llSitTarget( < 0.2, 0.0, -1.0> ,  avrotation);
    
    // listen for device registrations
    gRegistrationListen  = llListen(gRegistrationChannel,"","","");

    // ask all devices to send registration information
    llRegionSay(gRegistrationChannel,"REGISTER");
    llWhisper(0,"Initialization complete; awaiting registration messages.");
}

// *******
// Activaate, Deactivate
// set the sitter's camera to the parameters sent in the list
activate() {
        llInstantMessage( gSitterKey,"activating brainball");
    
        //get the device location and position
        vector cameraPosition = <-0.01,0,0> * brainballRotation + brainballCoordinates;
        vector cameraFocus =  <1.0,0,0> * brainballRotation + brainballCoordinates;
        
        if (havePermissions == 1) {
            llSetCameraParams([
            CAMERA_ACTIVE, 1, // 1 is active, 0 is inactive
            CAMERA_BEHINDNESS_ANGLE, 0.0, // (0 to 180) degrees
            CAMERA_BEHINDNESS_LAG, 0.0, // (0 to 3) seconds
            CAMERA_DISTANCE, 0.0, // ( 0.5 to 10) meters
            CAMERA_FOCUS, cameraFocus, // region relative position
            CAMERA_FOCUS_LAG, 0.0 , // (0 to 3) seconds
            CAMERA_FOCUS_LOCKED, TRUE, // (TRUE or FALSE)
            CAMERA_FOCUS_THRESHOLD, 0.0, // (0 to 4) meters
            //CAMERA_PITCH, 80.0, // (-45 to 80) degrees
            CAMERA_POSITION, cameraPosition, // region relative position
            CAMERA_POSITION_LAG, 0.0, // (0 to 3) seconds
            CAMERA_POSITION_LOCKED, TRUE, // (TRUE or FALSE)
            CAMERA_POSITION_THRESHOLD, 0.0, // (0 to 4) meters
            CAMERA_FOCUS_OFFSET, ZERO_VECTOR // <-10,-10,-10> to <10,10,10> meters
            ]);
        } else {
            llInstantMessage( gSitterKey,"error: did not have permission to set your camera.");
        }
        // tell every terminal that someone is present
        llRegionSay(gRegistrationChannel,"present," + gSitterName + "," + (string)gSitterKey);
        llSleep(0.5);// delay so that the active terminal doesn't get its data wiped out
        // send it the activate command. 
        string message = "activate," + gSitterName + "," + (string)gSitterKey;
        SendMessageToOneDevice(message);
}

deactivate () {
    string message = "deactivate," + gSitterName + "," + (string)gSitterKey;
    SendMessageToOneDevice(message);
}

absent () {
    llRegionSay(gRegistrationChannel,"deactivate," + gSitterName + "," + (string)gSitterKey);
}

// *******
// help
help() {
    llInstantMessage( gSitterKey, 
    "Welcome, " + gSitterName + ". You are now Black Gazza's Warden, an AI.\n" +
    "Issue commands by typing /" + (string)gCommandChannel + " and then the command.\n" +
    "The Core Computer knows these commands:\n" +
    "  activate <device> - sends  your eyepoint to that terminal.\n" +
    "  boom - sends the boom command to every device.\n" +
    "  close <device> - sends close command to a device.\n" +
    "  cycle - activates all terminals in sequence. You scan the station.\n" +
    "  cycle <type> - activates all terminals in sequence that have \"type\" in the name. You scan the station.\n" +
    "  debug - set debug level. 0 = off; 1 = chatty.\n" + 
    "  help - lists commands known by the Core Computer.\n" +
    "  lockdown { status | lockdown | release} - get or set lockdown status.\n" +
    "  list - lists devices you can command. (Slow!)\n" +
    "  open <device> - sends open command to a device.\n" +
    "  reregister - clears device list and asks every device to send registration information.\n" +
    "  scan - activates all terminals in sequence. You scan the station.\n" +
    "  scan <type> - activates all terminals in sequence that have \"type\" in the name. You scan the station.\n" +
    "  status - shows this script's memory usage. \n" +
    "  stop - stops terminal activation cycle. \n" +
    "  zap <name> - zaps the inmate. \n" +
    "<device> is a device designator, for example 9c6 for the terminal in the Warden room.\n" +
    "Talk by typing /" + (string)gTalkChannel + " ahead of your speech.\n" +
    "");
}



default
{
    on_rez ( integer param )
    {
        initialize();
    }

    state_entry() 
    {
        initialize();
    }

    run_time_permissions(integer permissions)
    {
        if (permissions & (PERMISSION_TRIGGER_ANIMATION | PERMISSION_CONTROL_CAMERA))
        {
            gSitterKey = llGetPermissionsKey();
            gSitterName = llKey2Name(gSitterKey);
            stop_anims( gSitterKey );
            llStartAnimation( "fetal" ); 
            havePermissions = 1;
            
            // set up listens
            gShutupListen = llListen(gShutupChannel, gSitterName, gSitterKey, "");
            gTalkListen = llListen(gTalkChannel, gSitterName, gSitterKey, "");
            gCommandListen = llListen(gCommandChannel, gSitterName, gSitterKey, ""); 

            // activate the terminal in Control Room
            llRegionSay(gRegistrationChannel,"present," + gSitterName + "," + (string)gSitterKey);
            llInstantMessage(gSitterKey,"Please use /" + (string)gTalkChannel +
            " to talk and /" + (string)gCommandChannel + " for commands.");
        } else {
            llWhisper(0,"FAILED to initialize");
            llResetScript();
        }
    }

    changed(integer change) 
    {
        if (change & CHANGED_LINK) {
            // Someone sat or stood up ...
            gSitterKey = llAvatarOnSitTarget();
            if (gSitterKey) {
                // Sat down
                llRequestPermissions( gSitterKey, PERMISSION_TRIGGER_ANIMATION | PERMISSION_CONTROL_CAMERA);
            } else {
                // Stood up ( or maybe crashed! )
                havePermissions = 0;
                gSitterKey = llGetPermissionsKey();
                if ( llGetAgentSize( gSitterKey ) != ZERO_VECTOR ) {
                    // agent is still in the sim.
                    if ( llGetPermissions() & (PERMISSION_TRIGGER_ANIMATION | PERMISSION_CONTROL_CAMERA)) {
                        // Only stop anis if permission was granted previously.
                        stop_anims( gSitterKey );
                    }
                }
                llWhisper(0,"processing stand up");
                gSitterKey = "";
                gSitterName = "nobody";
                llRegionSay(gRegistrationChannel,"absent,nobody,");
                llListenRemove(gTalkListen);
                llListenRemove(gCommandListen);
                llResetScript();
            }
        }
    }    
    
    // command processor
    listen( integer channel, string name, key id, string message ) {
        debug ("received message from " + name + ": " + message);
        
        // handle device registrations
        if (gRegistrationChannel == channel) {
            list parameters = llParseString2List( message, [","], []);
            string command = llToLower(llList2String(parameters,0));

            if (command == "register") {
                registerDevice(id, name, message);
                
            } else if (command == "update") {
                updateEyepoint(id, name, message);

            } else if (command == "page") {
                string designation = llList2String(parameters,1);
                integer channel = (integer)llList2String(parameters,2);
                string pagername  = llList2String(parameters,3);
                if (gSitterKey != "" ) {
                    llInstantMessage(gSitterKey,name+ ": Page from " + pagername + " at terminal " + designation + ".\n"+
                    "   type\n" +
                    "/" + (string)gCommandChannel + " activate " + designation + "\n"+
                    "   to activate that terminal.");
                } else {
                    integer space = llSubStringIndex(pagername, " ");
                    pagername = llGetSubString(pagername, 0, space-1); // just the first name
                    llRegionSay(channel,"say,    I'm sorry, " + pagername + ". I'm afraid I can't do that.");
                }
            }
        }
            
        if (gShutupChannel == channel) {
            if (gSitterKey != "" ) {
                llInstantMessage(gSitterKey,"Please use /" + (string)gTalkChannel +
                " to talk and /" + (string)gCommandChannel + " for commands.");
            }
        }
        
        if (gTalkChannel == channel) {
            // *** kludge to fix a bug in terminals. 
            // when you fix the terminals, you have to fix this, too. 
            // llWhisper(0,"say," +message);
            llRegionSay(brainballChannel,"say," +"1234"+message); 
            if (gSitterKey != "" )  {
                 llInstantMessage(gSitterKey,"\""+message+"\"");
            }
        }
        
        // handle commands from the sitter            
        if (gCommandChannel == channel) {
            llInstantMessage(gSitterKey,"processing command \""+message+"\"");
            list parameters = llParseString2List( message, [" "], []);
            string command = llToLower(llList2String(parameters,0));
            string parameter = llToLower(llList2String(parameters,1));
                
            if (command == "activate") {
                activate();
                                
            } else if (command == "debug") {
                setDebugLevel(parameter);
                
            } else if (command == "help") {
                help();
                
            } else if (command == "status") {
                reportStatus();

            }
        } 
    }

}
