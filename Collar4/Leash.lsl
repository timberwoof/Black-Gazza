// Leash.lsl
// Menu and control script for Black Gazza Collar 4
// Timberwoof Lupindo
// July 2019

// Handles all leash menu, authroization, and leashing functionality

integer OPTION_DEBUG = 1;
string prisonerNumber = "P-99999";
integer menuChannel = 0;
integer menuListen = 0;
key leasherAvatar;
integer rlvPresent;
string RLVLevel;
integer leashLength = 5;
key leashTarget;
string sensorState = "Leash";
list leashPoints;

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
    if (avatarKey != llGetOwner() && llSameGroup(avatarKey)) {
        sayDebug("leashMenuFilter ask");
        leashMenuAsk(avatarKey);
    } else {
        sayDebug("leashMenuFilter do");
        leashMenu(avatarKey);
    }
    leasherAvatar = avatarKey;
}

key leashMenuAsk(key avatarKey) {
    sayDebug("leashMenuAsk");
    string message = llGetDisplayName(avatarKey) + " wants to leash you.";
    list buttons = ["Leash Okay"];
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
    buttons = buttons + ["Leash To", "Length 2m", "Length 5m", "Length 10m", "Length 20m", "Unleash"];
    setUpMenu(avatarKey, message, buttons);    
}

leashToMenu(key avatarKey, list objects) {
}

scanLeashPosts(key avatarKey) {
}

doLeash(key avatarKey, string message) {
    if (message == "Grab leash") {
        llMessageLinked(LINK_THIS, 2000, message, avatarKey);
    } else if (message == "Leash To") {
        scanLeashPosts(avatarKey);
    } else if (message == "Length") {
    }
}

leashParticlesOn(key target) {
    sayDebug("leashParticlesOn");
    string texturename = "1d15cba4-91dd-568c-b2b4-d25331bebe73"; 
    string nullstr = ""; 
    key nullkey = NULL_KEY; 
    key posekey = nullkey; 
    float age = 3; 
    float gravity = 1.0; 
    key currenttarget = nullkey; 
    string ourtarget = nullstr; 
    integer line; 
    key loadkey; 

    llParticleSystem( [
   PSYS_PART_START_SCALE,(vector) <0.075,0.075,0>,
   PSYS_PART_END_SCALE,(vector) <1,1,0>,
   PSYS_PART_START_COLOR,(vector) <1,1,1>,
   PSYS_PART_END_COLOR,(vector) <1,1,1>,
   PSYS_PART_START_ALPHA,(float) 1.0,
   PSYS_PART_END_ALPHA,(float) 1.0,
   PSYS_SRC_TEXTURE,(string) texturename,
   PSYS_SRC_BURST_PART_COUNT,(integer) 1,
   PSYS_SRC_BURST_RATE,(float) 0.0,
   PSYS_PART_MAX_AGE,(float) age,
   PSYS_SRC_MAX_AGE,(float) 0.0,
   PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
   PSYS_SRC_BURST_RADIUS,(float) 0.5,
   PSYS_SRC_INNERANGLE,(float) 0.0,
   PSYS_SRC_OUTERANGLE,(float) 0.0,
   PSYS_SRC_OMEGA,(vector) <0,0,0>,
   PSYS_SRC_ACCEL,(vector) <0,0,-gravity>,
   PSYS_SRC_BURST_SPEED_MIN,(float) 1000.0,
   PSYS_SRC_BURST_SPEED_MAX,(float) 1000.0,
   PSYS_SRC_TARGET_KEY,(key) target,
   PSYS_PART_FLAGS,
    PSYS_PART_FOLLOW_VELOCITY_MASK |
    PSYS_PART_FOLLOW_SRC_MASK |
    PSYS_PART_TARGET_POS_MASK | 0
   ] );
}

leashParticlesOff() {
    sayDebug("leashParticlesOff");
    llParticleSystem([]);
}

default
{
    state_entry()
    {
        llParticleSystem([]);
        leashLength = 5;
    }

    link_message( integer sender_num, integer num, string message, key id ){ 
        sayDebug("link_message("+(string)num+","+message+")");
        if (num == 2000 && message == "Leash"){
            leashMenuFilter(id);
        } else if (num == 1401) {
            if (message == "NoRLV") {
                rlvPresent = 0;
                RLVLevel = "Off";
            } else if (message == "YesRLV") {
                rlvPresent = 1;
            } else {
                RLVLevel = message;
            }
        } else if (num == 2000) {
            list returned = llParseString2List(message, [","], []);
            prisonerNumber = llList2String(returned, 4);
        }
    }
    
    
    listen( integer channel, string name, key avatarKey, string message ){
        sayDebug("listen("+message+")");
        llListenRemove(menuListen);
        menuListen = 0;
        llSetTimerEvent(0);
        sayDebug("listen:"+message);
        if (message == "Leash Okay"){
            sayDebug("listen: Leash");
            leashMenu(leasherAvatar);
        } else if (message == "Grab Leash") {
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
            key leashTarget = llList2Key(leashPoints,pointi);
            leashParticlesOn(leashTarget);
            llSensorRepeat("", leashTarget, ( ACTIVE | PASSIVE | SCRIPTED ), 25, PI, 1);
        } else if (message == "Unleash") {
            llSensorRemove();
            leashParticlesOff();
        }
        
        // Leash "Grab Leash", "Leash To", "Length 2 m", "Length 5 m", "Length 10m", "Length 20m", "Unleash"
        else if (llSubStringIndex("leash", llToLower(message)) > -1){
            sayDebug("listen: Main:"+message);
            doLeash(avatarKey, message);
        }
        
    }

   sensor(integer detected)
   {
        float dist; 
        key owner; 
        string targetN;
        
        if (sensorState == "Leash") {
            dist = llVecDist(llGetPos(), llDetectedPos(0));
            if(dist >= (leashLength + 1))
            {
                llMoveToTarget(llDetectedPos(0), 0.75);
            }
            if(dist <= leashLength)
            {
                llStopMoveToTarget();
            }
        } else if (sensorState == "Findpost") {
            sayDebug("sensor("+(string)detected+")");
            string message = "Select a leash Point:\n";
            list buttons = [];
            integer pointi;
            for(pointi = 0; pointi < detected; pointi++)
            {
                llOwnerSay(llDetectedName(pointi));
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
}
