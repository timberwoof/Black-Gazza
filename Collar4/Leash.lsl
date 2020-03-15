// Leash.lsl
// Menu and control script for Black Gazza Collar 4
// Timberwoof Lupindo
// July 2019
// version: 2020-03-14 JSON

// Handles all leash menu, authroization, and leashing functionality

integer OPTION_DEBUG = 1;

string prisonerNumber = "P-99999"; // to make the menus nice
integer menuChannel = 0;
integer menuListen = 0;
key leasherAvatar;
integer leashLength = 5;
key leashTarget;
string sensorState = "Leash";
list leashPoints;
integer leashRingPrim = 3;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Leash:"+message);
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
    // If an inmate wants to leash you, ask your permission. 
    // If you or anybody esle wants to leash you, just present the leash menu. 
    sayDebug("leashMenuFilter leasherAvatar:"+(string)leasherAvatar);
    sayDebug("leashMenuFilter avatarKey:"+(string)avatarKey);
    sayDebug("leashMenuFilter llGetOwner:"+(string)llGetOwner());
    if (avatarKey != llGetOwner() && llSameGroup(avatarKey) && avatarKey != leasherAvatar) {
        // another inmate wants to mess with the leash
        sayDebug("leashMenuFilter ask");
        leasherAvatar = avatarKey; // remember who wanted to leash
        leashMenuAsk(leasherAvatar);
    } else if (leasherAvatar == llGetOwner() || avatarKey != llGetOwner()) {
        sayDebug("leashMenuFilter okay");
        leasherAvatar = avatarKey; // remember who wanted to leash
        leashMenu(avatarKey);
    } else {
        llInstantMessage(avatarKey, "You are not permitted to mess with the leash.");
        llSay (0, prisonerNumber + " tugs on the leash.");
    }

}

key leashMenuAsk(key avatarKey) {
    sayDebug("leashMenuAsk");
    llInstantMessage(avatarKey,"Requesting permission to leash.");
    string message = llGetDisplayName(avatarKey) + " wants to leash you.";
    list buttons = ["Okay", "No"];
    setUpMenu(llGetOwner(), message, buttons);
    return avatarKey;
}

leashMenu(key avatarKey)
// We passed all the tests. Present the leash menu. 
{
    sayDebug("leashMenu sensorState:"+sensorState);
    string message = "Set "+prisonerNumber+"'s Leash.";
    list buttons = [];
    
    // you can't grab your own leash
    if (avatarKey != llGetOwner()) {
        buttons = buttons + ["Grab Leash"];
    }
    
    // you or anyone can leash and set length
    buttons = buttons + ["Leash To", "1 m", "2 m", "5 m", "10 m", "20 m"];

    // if not leashed, then you can't unleash    
    if (sensorState == "Leash") {
        buttons = buttons + ["Unleash"];
    }
    
    setUpMenu(avatarKey, message, buttons);    
}

leashParticlesOn(key target) {
    sayDebug("leashParticlesOn");
    string texturename = "1d15cba4-91dd-568c-b2b4-d25331bebe73"; 
    float age = 5; 
    float gravity = 0.2; 

    llLinkParticleSystem( leashRingPrim, [
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

default
{
    state_entry()
    {
        leashParticlesOff();
        leashRingPrim = getLinkWithName("leashPoint");
        leasherAvatar = llGetOwner();
        llMessageLinked(LINK_THIS, 2002, "Request", "");
        sensorState = "";
    }

    link_message( integer sender_num, integer num, string json, key id ){ 
    
        string value = llJsonGetValue(json, ["Leash"]);
        if (value != JSON_INVALID) {
            // leash command
            sayDebug("link_message("+(string)num+","+json+")");;
            leashMenuFilter(id);
        }

        value = llJsonGetValue(json, ["assetNumber"]);
        if (value != JSON_INVALID) {
            // database status
            sayDebug("link_message("+(string)num+","+json+")");
            prisonerNumber = value;
        }
    }
    
    
    listen( integer channel, string name, key avatarKey, string message ){
        sayDebug("listen("+message+")");
        llListenRemove(menuListen);
        menuListen = 0;
        llSetTimerEvent(0);
        if (message == "Okay"){
            leashMenu(leasherAvatar);
        } else if (message == "No"){
            llInstantMessage(leasherAvatar,"Permission to leash was not granted.");
        } else if (message == "Grab Leash") {
            sayDebug("grab leash");
            leashTarget = avatarKey;
            leashParticlesOn(leashTarget);
            llSensorRepeat("", leashTarget, AGENT, 96, PI, 1);
            sensorState = "Leash";
            leashMenu(leasherAvatar);
        } else if (message == "Leash To") {
            sayDebug("find leash points");
            leashPoints = [];
            llSensor("", NULL_KEY, ( ACTIVE | PASSIVE | SCRIPTED ), 5, PI);
            sensorState = "Findpost";
        } else if (llSubStringIndex(message, "m") > -1) {
            sayDebug("set leash length");
            // message was like "5 m" or "10 m"
            leashLength = (integer)llGetSubString(message,0,1);
            leashMenu(leasherAvatar);
        } else if (llGetSubString(message,0,4) == "Point") {
            sayDebug("leash to point");
            integer pointi = (integer)llGetSubString(message,6,7);
            key leashTarget = llList2Key(leashPoints,pointi);
            leashParticlesOn(leashTarget);
            llSensorRepeat("", leashTarget, ( ACTIVE | PASSIVE | SCRIPTED ), 25, PI, 1);
            sensorState = "Leash";
            leashMenu(leasherAvatar);
        } else if (message == "Unleash") {
            llSensorRemove();
            leashParticlesOff();
            leasherAvatar = llGetOwner();
            leashTarget = "";
            sensorState = "";
        } else {
            llOwnerSay("Leash Error: Unhandled listen message: "+name+": "+message);
        }
    }

    sensor(integer detected)
    {
        float distance; 
        
        if (sensorState == "Leash") {
            // distance to avatar holding the leash or the object leashed to.
            distance = llVecDist(llGetPos(), llDetectedPos(0));
            if (distance >= leashLength) {
                llMoveToTarget(llDetectedPos(0), 1.0);
            } else {
                llStopMoveToTarget();
            }
        } else if (sensorState == "Findpost") {
            // we got a list of nearby objects we might be able to leash to.
            // Male a dialog box out of th elist. 
            sayDebug("sensor("+(string)detected+")");
            string message = "Select a leash Point:\n";
            list buttons = [];
            integer pointi;
            if (detected > 12) detected = 12;
            for(pointi = 0; pointi < detected; pointi++) {
                sayDebug(llDetectedName(pointi));
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
