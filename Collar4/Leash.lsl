// Leash.lsl
// Menu and control script for Black Gazza Collar 4
// Timberwoof Lupindo
// July 2019
// version: 2020-11-23

// Handles all leash menu, authroization, and leashing functionality

integer OPTION_DEBUG = FALSE;

integer rlvPresent = FALSE;
string prisonerLockLevel = "";
integer sitActive = FALSE;
integer sitPending = FALSE;

string prisonerNumber = "P-00000"; // to make the menus nice
integer menuChannel = 0;
integer menuListen = 0;
key leasherAvatar;
integer leashLength = 5;
key leashTarget;
string sensorState;
string action;
list leashPoints;
integer leashRingPrim;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Leash: "+message);
    }
}

string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
    }
    return result;
}
    
integer getJSONinteger(string jsonValue, string jsonKey, integer valueNow){
    integer result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = (integer)value;
    }
    return result;
}

list menuRadioButton(string title, string match)
// make radio button menu item out of a button and the state text
{
    string radiobutton;
    if (title == match)
    {
        radiobutton = "●";
    }
    else
    {
        radiobutton = "○";
    }
    return [radiobutton + " " + title];
}

list menuButtonActive(string title, integer onOff)
// make a menu button be the text or the Inactive symbol
{
    string button;
    if (onOff)
    {
        button = title;
    }
    else
    {
        button = "["+title+"]";//"⦻";
    }
    return [button];
}

setUpMenu(key avatarKey, string message, list buttons)
// wrapper to do all the calls that make a simple menu dialog.
{
    string completeMessage = prisonerNumber + " Collar: " + message;
    menuChannel = -(llFloor(llFrand(10000)+1000));
    llDialog(avatarKey, completeMessage, buttons, menuChannel);
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
}

leashMenuFilter(key avatarKey) {
    // action = "Leash" or "ForceSit"
    // If an inmate wants to leash you, ask your permission. 
    // If you or anybody esle wants to leash you, just present the leash menu. 
    sayDebug("leashMenuFilter leasherAvatar: "+(string)leasherAvatar);
    sayDebug("leashMenuFilter avatarKey: "+(string)avatarKey);
    sayDebug("leashMenuFilter llGetOwner: "+(string)llGetOwner());
    sayDebug("leashMenuFilter action: "+action);
    if (avatarKey != llGetOwner() && llSameGroup(avatarKey) && avatarKey != leasherAvatar) {
        // another inmate wants to mess with the leash
        sayDebug("leashMenuFilter ask");
        leasherAvatar = avatarKey; // remember who wanted to leash
        leashMenuAsk(leasherAvatar);
    } else if (leasherAvatar == llGetOwner() || avatarKey != llGetOwner()) {
        sayDebug("leashMenuFilter okay");
        leasherAvatar = avatarKey; // remember who wanted to leash
        if (action == "Leash") {
            leashMenu(avatarKey);
        } else {
            sitMenu(avatarKey, "leashMenuFilter okay");
        }
    } else {
        if (action == "Leash") {
            llInstantMessage(avatarKey, "You are not permitted to mess with the leash. "+llKey2Name(leasherAvatar)+" has the leash.");
            llSay (0, prisonerNumber + " tugs on the leash.");
        } else {
            llInstantMessage(avatarKey, "You are not permitted to stand.");
            llSay (0, prisonerNumber + " struggles.");
        }
    }

}

key leashMenuAsk(key avatarKey) {
    // action == "Leash" or "ForceSit"
    sayDebug("leashMenuAsk action: "+action);
    string informingLeasher;
    string askingWearer;
    if (action == "Leash") {
        informingLeasher = "Requesting permission to leash.";
        askingWearer = llGetDisplayName(avatarKey) + " wants to leash you.";
    } else {
        informingLeasher = "Requesting permission to force-sit.";
        askingWearer = llGetDisplayName(avatarKey) + " wants to force you to sit";
    }
    llInstantMessage(avatarKey,informingLeasher);
    list buttons = ["Okay", "No"];
    setUpMenu(llGetOwner(), askingWearer, buttons);
    return avatarKey;
}

leashMenu(key avatarKey)
// We passed all the tests. Present the leash menu. 
{
    sayDebug("leashMenu action:"+action+" sensorState:"+sensorState);
    string message = "Set "+prisonerNumber+"'s Leash.";
    list buttons = [];
    
    // you can't grab your own leash
    if (avatarKey != llGetOwner()) {
        buttons = buttons + ["Grab Leash"];
    }
    
    // you or anyone can leash and set length
    buttons = buttons + "Leash To";
    string leashIs = (string)leashLength + " m";
    buttons = buttons + menuRadioButton("1 m", leashIs);
    buttons = buttons + menuRadioButton("2 m", leashIs);
    buttons = buttons + menuRadioButton("5 m", leashIs);
    buttons = buttons + menuRadioButton("10 m", leashIs);
    buttons = buttons + menuRadioButton("20 m", leashIs);

    integer unleash = sensorState == "LeashObject" || sensorState == "LeashAgent";
    buttons = buttons + menuButtonActive("Unleash", unleash);
    
    setUpMenu(avatarKey, message, buttons);    
}

sitMenu(key avatarKey, string calledBy)
// We passed all the tests. Present the Sit menu.
{
    sayDebug("sitMenu calledBy:"+calledBy+" action:"+action+" sensorState:"+sensorState);
    string message = "Force "+prisonerNumber+" to sit.";
    list buttons = [];
    buttons = buttons + menuButtonActive("Sit On", rlvPresent & !sitActive);
    buttons = buttons + menuButtonActive("Unsit", sitActive);
    setUpMenu(avatarKey, message, buttons);        
}

leashParticlesOn(string whocalled, key target) {
    sayDebug("leashParticlesOn("+whocalled+", "+llKey2Name(target)+")");
    string texturename = "1d15cba4-91dd-568c-b2b4-d25331bebe73"; 
    float age = 5; 
    float gravity = 0.2; 

    llLinkParticleSystem(leashRingPrim, [
        PSYS_PART_START_SCALE,(vector) <0.075,0.075,0>,
        PSYS_PART_END_SCALE,(vector) <0.075,0.075,0>,
        PSYS_PART_START_COLOR,(vector) <1,1,1>,
        PSYS_PART_END_COLOR,(vector) <1,1,1>,
        PSYS_PART_START_ALPHA,(float) 1.0,
        PSYS_PART_END_ALPHA,(float) 1.0,
        PSYS_SRC_TEXTURE,(string) texturename,
        PSYS_SRC_BURST_PART_COUNT,(integer) 4,
        PSYS_SRC_BURST_RATE,(float) .025,
        PSYS_PART_MAX_AGE,(float) age,
        PSYS_SRC_MAX_AGE,(float) 0.0,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
        PSYS_SRC_BURST_RADIUS,(float) 0.5,
        PSYS_SRC_INNERANGLE,(float) 0.0,
        PSYS_SRC_OUTERANGLE,(float) 0.0,
        PSYS_SRC_OMEGA,(vector) <0,0,0>,
        PSYS_SRC_ACCEL,(vector) <0,0,-gravity>,
        PSYS_SRC_BURST_SPEED_MIN,(float) 0.05,
        PSYS_SRC_BURST_SPEED_MAX,(float) 0.05,
        PSYS_SRC_TARGET_KEY,(key) target,
        PSYS_PART_FLAGS,
        PSYS_PART_RIBBON_MASK |
        PSYS_PART_FOLLOW_SRC_MASK |
        PSYS_PART_TARGET_POS_MASK | 0
    ] );
}

leashParticlesOff() {
    sayDebug("leashParticlesOff");
    llLinkParticleSystem(leashRingPrim, []);
}

integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) 
            return i; // Found it! Exit loop early with result
    return -1; // No prim with that name, return -1.
}

sendRLVSitCommand(key what) {
    string rlvcommand;
    rlvcommand = "@sit:"+(string)what+"=force,unsit=n";
    sayDebug("sendRLVRestrictCommand rlvcommand:"+rlvcommand);
    llOwnerSay(rlvcommand);
    sitActive = TRUE;
}

sendRLVReleaseCommand() {
    string rlvcommand = "@unsit=y,unsit=force";
    sayDebug("sendRLVReleaseCommand rlvcommand:"+rlvcommand);
    llOwnerSay(rlvcommand);
    sitActive = FALSE;
}

default
{
    state_entry() // reset
    {
        sayDebug("state_entry");
        leashRingPrim = getLinkWithName("leashPoint");
        leasherAvatar = llGetOwner();
        leashParticlesOff();
        sensorState = "";
        sayDebug("state_entry done");
    }
    
    attach(key avatar) {
        sayDebug("attach("+llKey2Name(leashTarget)+")");
        if (leashTarget != NULL_KEY) {
            if (sensorState == "LeashAgent") {
                llSensorRepeat("", leashTarget, AGENT, 96, PI, 1);
                leashParticlesOn("attach LeashAgent", leashTarget);
            } else if (sensorState == "LeashObject") {
                llSensorRepeat("", leashTarget, ( ACTIVE | PASSIVE | SCRIPTED ), 25, PI, 1);
                leashParticlesOn("attach leashTarget", leashTarget);
            } else if (sitActive) {
                // We may not be ready for RLV yet. 
                sitPending = TRUE; 
            }
        }
        sayDebug("attach done");
    }

    link_message( integer sender_num, integer num, string json, key id ){ 
    
        string value = llJsonGetValue(json, ["Leash"]);
        if (value != JSON_INVALID) {
            // leash command
            action = value;
            sayDebug("link_message("+json+") action:"+action);
            leashMenuFilter(id);
        }

        value = llJsonGetValue(json, ["assetNumber"]);
        if (value != JSON_INVALID) {
            // database status
            sayDebug("link_message("+(string)num+","+json+")");
            prisonerNumber = value;
        }
        
        prisonerLockLevel = getJSONstring(json, "prisonerLockLevel", prisonerLockLevel);
        string RLVCommand = getJSONstring(json, "prisonerLockLevel", "");
        if (RLVCommand == "Off") {
            sendRLVReleaseCommand();
        }
        rlvPresent = getJSONinteger(json, "rlvPresent", rlvPresent);
        if (rlvPresent & sitPending) {
            sendRLVSitCommand(leashTarget);
            sitPending = TRUE;
        }
    }
    
    
    listen( integer channel, string name, key avatarKey, string message ){
        sayDebug("listen("+message+")  action:"+action);
        llListenRemove(menuListen);
        menuListen = 0;
        llSetTimerEvent(0);
        if (message == "Okay"){
            if (action == "Leash") {
                leashMenu(leasherAvatar);
            } else {
                sitMenu(leasherAvatar, "Listen Okay");
            }            
        } else if (message == "No"){
            if (action == "Leash") {
                llInstantMessage(leasherAvatar,"Permission to leash was not granted.");
            } else {
                llInstantMessage(leasherAvatar,"Permission to force sit was not granted.");
            }
        } else if (message == "Grab Leash") {
            // sensor must keep track of the agent who grabbed the leash
            sayDebug("grab leash");
            leashTarget = avatarKey;
            leashParticlesOn("listen Grab Leash", leashTarget);
            llSensorRepeat("", leashTarget, AGENT, 96, PI, 1);
            sensorState = "LeashAgent";
            leashMenu(leasherAvatar);
        } else if ((message == "Leash To") | (message == "Sit On")){
            // sensor must find possible leash points
            sayDebug("find leash points");
            leashPoints = [];
            llSensor("", NULL_KEY, ( ACTIVE | PASSIVE | SCRIPTED ), 5, PI);
            sensorState = "Findpost";
        } else if (llSubStringIndex(message, "m") > -1) {
            // message was leash length like "○ 5 m" or "○ 10 m"
            sayDebug("set leash length");
            leashLength = (integer)llGetSubString(message,2,3);
            leashMenu(leasherAvatar);
        } else if (llGetSubString(message,0,4) == "Point") {
            // message was a specific leash point number
            sayDebug("Point  action:"+action);
            integer pointi = (integer)llGetSubString(message,6,7);
            leashTarget = llList2Key(leashPoints,pointi);
            if (action == "Leash") {
                leashParticlesOn("listen Point", leashTarget);
                llSensorRepeat("", leashTarget, ( ACTIVE | PASSIVE | SCRIPTED ), 25, PI, 1);
                sensorState = "LeashObject";
                leashMenu(leasherAvatar);
            } else {
                llSensorRemove();
                sensorState = "";
                sendRLVSitCommand(leashTarget);
                sitMenu(leasherAvatar, "leash to Point");
            }            
        } else if (message == "Unleash") {
            llSensorRemove();
            leashParticlesOff();
            leasherAvatar = llGetOwner();
            leashTarget = "";
            sensorState = "";
        } else if (message == "Unsit") {
            sendRLVReleaseCommand();
            leasherAvatar = llGetOwner();
            sensorState = "";
        } else {
            llOwnerSay("Leash Error: Unhandled listen message: "+name+": "+message);
        }
    }

    sensor(integer detected)
    {
        float distance; 
        
        if (sensorState == "LeashAgent" || sensorState == "LeashObject") {
            // distance to avatar holding the leash or the object leashed to.
            distance = llVecDist(llGetPos(), llDetectedPos(0));
            if (distance >= leashLength) {
                llMoveToTarget(llDetectedPos(0), 1.0);
            } else {
                llStopMoveToTarget();
            }
        } else if (sensorState == "Findpost") {
            // we got a list of nearby objects we might be able to leash to or sit on.
            // Male a dialog box out of the list. 
            sayDebug("sensor("+(string)detected+")  action: "+action);
            string message;
            if (action == "Leash") {
                message = "Select a leash Point:\n";
            } else {
                message = "Select a seat:\n";
            }
            list buttons = [];
            integer pointi;
            if (detected > 12) detected = 12;
            for(pointi = 0; pointi < detected; pointi++) {
                sayDebug("sensor Findpost "+(string)pointi+": "+llDetectedName(pointi));
                message = message + (string)pointi + " " + llDetectedName(pointi) + "\n"; 
                leashPoints = leashPoints + [llDetectedKey(pointi)];
                buttons = buttons + ["Point "+(string)pointi];
            }
            setUpMenu(leasherAvatar, message, buttons);
        } 
    }
    
    no_sensor()
    {
        leashParticlesOff();
        llStopMoveToTarget();
        sensorState = "";
    }

    timer() 
    {
        llListenRemove(menuListen);
        menuListen = 0;    
    }
}
