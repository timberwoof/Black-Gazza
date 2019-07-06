// Leash.lsl
// Menu and control script for Black Gazza Collar 4
// Timberwoof Lupindo
// July 2019

// Handles all leash menu, authroization, and leashing functionality

integer OPTION_DEBUG = 0;
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
        llWhisper(0,"Leash:"+message);
    }
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
    if (avatarKey != llGetOwner() && llSameGroup(avatarKey)) {
        // another inmate wants to mess with the leash
        sayDebug("leashMenuFilter ask");
        leashMenuAsk(avatarKey);
    } else if (leasherAvatar == llGetOwner() || avatarKey != llGetOwner()) {
        sayDebug("leashMenuFilter okay");
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
    sayDebug("leashMenu");
    string message = "Set "+prisonerNumber+"'s Leash.";
    list buttons = [];
    if (avatarKey != llGetOwner()) {
        buttons = buttons + ["Grab Leash"];
    }
    buttons = buttons + ["Leash To", "Length 1m", "Length 2m", "Length 5m", "Length 10m", "Length 20m", "Unleash"];
    setUpMenu(avatarKey, message, buttons);    
}

leashParticlesOn(key target) {
    sayDebug("leashParticlesOn");
    string texturename = "1d15cba4-91dd-568c-b2b4-d25331bebe73"; 
    string nullstr = ""; 
    key nullkey = NULL_KEY; 
    key posekey = nullkey; 
    float age = 5; 
    float gravity = 1.0; 
    key currenttarget = nullkey; 
    string ourtarget = nullstr; 
    integer line; 
    key loadkey; 

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

default
{
    state_entry()
    {
        leashParticlesOff();
        leashLength = 5;
    }

    link_message( integer sender_num, integer num, string message, key id ){ 
        if (num == 1901 && message == "Leash"){
            // leash command
            sayDebug("link_message("+(string)num+","+message+")");;
            leashMenuFilter(id);
        } else if (num == 2000) {
            // database status
            sayDebug("link_message("+(string)num+","+message+")");
            list returned = llParseString2List(message, [","], []);
            prisonerNumber = llList2String(returned, 4);
        }
    }
    
    
    listen( integer channel, string name, key avatarKey, string message ){
        sayDebug("listen("+message+")");
        llListenRemove(menuListen);
        menuListen = 0;
        llSetTimerEvent(0);
        leasherAvatar = avatarKey;
        sayDebug("listen:"+message);
        if (message == "Okay"){
            leashMenu(leasherAvatar);
        } else if (message == "No"){
            llInstantMessage(leasherAvatar,"Permission to leash was not granted.");
        } else if (message == "Grab Leash") {
            leasherAvatar = avatarKey;
            leashTarget = avatarKey;
            sensorState = "Leash";
            leashParticlesOn(leashTarget);
            llSensorRepeat("", leashTarget, AGENT, 96, PI, 1);
        } else if (message == "Leash To") {
            sensorState = "Findpost";
            leashPoints = [];
            llSensor("", NULL_KEY, ( ACTIVE | PASSIVE | SCRIPTED ), 5, PI);
        } else if (llGetSubString(message,0,5) == "Length") {
            leashLength = (integer)llGetSubString(message,7,8);
        } else if (llGetSubString(message,0,4) == "Point") {
            sensorState = "Leash";
            integer pointi = (integer)llGetSubString(message,6,7);
            leasherAvatar = avatarKey;
            key leashTarget = llList2Key(leashPoints,pointi);
            leashParticlesOn(leashTarget);
            llSensorRepeat("", leashTarget, ( ACTIVE | PASSIVE | SCRIPTED ), 25, PI, 1);
        } else if (message == "Unleash") {
            llSensorRemove();
            leashParticlesOff();
            leasherAvatar = llGetOwner();
        } else {
            llOwnerSay("Error: Unhandled listem: "+name+" :"+message);
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
    }

    timer() 
    {
        llListenRemove(menuListen);
        menuListen = 0;    
    }
}
