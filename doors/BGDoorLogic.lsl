// BG Door Logic
// Replacement script for doors at Black Gazza
// Timberwoof Lupindo
// May 20, 2018 - May 29, 2018
// 3.0 Separates Hardware and Logic Layers

// these parameters can be optionally set in the description:
// debug: whispers operational details
// lockdown: responds to station lockdown messages
// delay: waits s120 econds before closing when lockdown is called
// power: responds to power failures
// group: makes it respond only to member of same group as door
// admin: makes admin show up only for members of same group
// owner[ownername]: gives people listed the ability to open the door despite all settings
// zap: zaps nonmember who tries to operate door
// normally-open: door will open on reset, after power is restored, and lockdown is lifted
// otherwise door will close on reset and after power is restored. 
// frame:<r,g,b>: sets frame to this color
// button: makes the "open" button work
// bump: makes the door open when someone bumps into it. 

// A normally-open door set to group, when closed by a member of the group,
// will stay closed for half an hour, implementing the fair-game rule. 

string version = "3.1 2020-08-10";
float gSensorRadius;

integer ZAP_CHANNEL = -106969;

integer menuChannel;
integer menuListen;
integer gMenuTimer = 0;

// Door States
integer doorState; // 1 = door is open
integer OPEN = TRUE;
integer CLOSED = FALSE;
integer QUIETLY = FALSE;
integer NOISILY = TRUE;

// power states
integer POWER_CHANNEL = -86548766;
integer gPowerListen; 
integer gPowerState = 0;
integer gPowerTimer = 0;
integer POWER_RESET_TIME = 60;
integer OFF = FALSE;
integer ON = TRUE;
integer OVERRIDE = 1;
integer MAYBE = 0;
integer POWER_OFF = 0;
integer POWER_ON = 1;
integer POWER_FAILING = 2;

// lockdown
integer LOCKDOWN_CHANNEL = -765489;
integer gLockdownListen = 0;
integer gLockdownState = 0; // not locked down
integer gLockdownTimer = 0;
integer LOCKDOWN_RESET_TIME = 1800; // 30 minutes
integer LOCKDOWN_DELAY = 120; // seconds
integer LOCKDOWN_OFF = 0;
integer LOCKDOWN_IMMINENT = 1;
integer LOCKDOWN_ON = 2;
integer LOCKDOWN_TEMP = 3; // for normally-open door closed fair-game release
string sound_lockdown = "2d9b82b0-84be-d6b2-22af-15d30c92ad21";

// options
integer OPTION_DEBUG = FALSE;
integer OPTION_LOCKDOWN = FALSE;
integer OPTION_DELAY = FALSE;
integer OPTION_POWER = FALSE;
integer OPTION_GROUP = FALSE;
integer OPTION_ADMIN = FALSE;
integer OPTION_OWNERS = FALSE;
integer OPTION_ZAP = FALSE;
integer OPTION_NORMALLY_OPEN = FALSE;
integer OPTION_LABEL = FALSE;
integer OPTION_BUTTON = FALSE;
integer OPTION_BUMP = FALSE;
integer OPTION_DIRECTION = 1; // if 1, sets security based on entry or exit
string OPTION_COLOR_FRAME = JSON_INVALID;
string OPTION_COLOR_PANELS = JSON_INVALID;
string OPTION_COLOR_CLEATS = JSON_INVALID;
string owners = "";

integer responderChannel;
integer responderListen;
integer responderTimer;
string direction;
string avatarJSON;

// timer
integer TIMER_INTERVAL = 2;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"LOGIC "+message);
    }
}

string getVectorOption(string optionstring, string optionName) {
    string result = JSON_INVALID;
    integer option_index = llSubStringIndex(optionstring, optionName); 
    if (option_index > -1)
    {
        string theRest = llGetSubString(optionstring,option_index,-1);
        integer lbracket = llSubStringIndex(theRest,"<");
        integer rbracket = llSubStringIndex(theRest,">");
        result = llGetSubString(theRest,lbracket,rbracket);
    }
    return result;
}

getOptions()
{
    string optionstring = llGetObjectDesc();
    sayDebug("getOptions("+ optionstring +")");
    if (llSubStringIndex(optionstring,"debug") > -1) OPTION_DEBUG = 1;
    sendJSONinteger("OPTION_DEBUG",OPTION_DEBUG, "");
    if (llSubStringIndex(optionstring,"lockdown") > -1) OPTION_LOCKDOWN = 1;
    if (llSubStringIndex(optionstring,"power") > -1) OPTION_POWER = 1;
    if (llSubStringIndex(optionstring,"group") > -1) OPTION_GROUP = 1;

    if (llSubStringIndex(optionstring,"admin") > -1) OPTION_ADMIN = 1;
    if (llSubStringIndex(optionstring,"zap") > -1) OPTION_ZAP = 1;
    if (llSubStringIndex(optionstring,"normally-open") > -1) OPTION_NORMALLY_OPEN = 1;
    if (llSubStringIndex(optionstring,"button") > -1) OPTION_BUTTON = 1;
    if (llSubStringIndex(optionstring,"bump") > -1) OPTION_BUMP = 1;
    if (llSubStringIndex(optionstring,"direction") > -1) OPTION_DIRECTION = 1;
    if (llSubStringIndex(optionstring,"delay") > -1) OPTION_DELAY = 1;
    
    OPTION_COLOR_FRAME = getVectorOption(optionstring, "frame");
    OPTION_COLOR_PANELS = getVectorOption(optionstring, "panels");
    OPTION_COLOR_CLEATS = getVectorOption(optionstring, "cleats");
            
    integer owner_index = llSubStringIndex(optionstring,"owner"); 
    if (owner_index > -1)
    {
        string theRest = llGetSubString(optionstring,owner_index,-1);
        integer lbracket = llSubStringIndex(theRest,"[");
        integer rbracket = llSubStringIndex(theRest,"]");
        owners = llGetSubString(theRest,lbracket+1,rbracket-1);
        sayDebug("owners:["+ owners +"]");
        OPTION_OWNERS = 1;
    }
    sayDebug("getOptions end");
}

sendOptions()
{
    sayDebug("sendOptions()");
    sendJSONinteger("OPTION_DEBUG",OPTION_DEBUG, "");
    sendJSONinteger("OPTION_GROUP",OPTION_GROUP, "");
    sendJSONinteger("OPTION_NORMALLY_OPEN",OPTION_NORMALLY_OPEN, "");
    sendJSONinteger("OPTION_BUTTON", OPTION_BUTTON, "");
    sendJSONinteger("OPTION_BUMP",OPTION_BUMP, "");
    if (OPTION_COLOR_FRAME != JSON_INVALID) sendJSON("OPTION_COLOR_FRAME", (string)OPTION_COLOR_FRAME, "");
    if (OPTION_COLOR_PANELS != JSON_INVALID) sendJSON("OPTION_COLOR_PANELS", (string)OPTION_COLOR_PANELS, "");
    if (OPTION_COLOR_CLEATS != JSON_INVALID) sendJSON("OPTION_COLOR_CLEATS", (string)OPTION_COLOR_CLEATS, "");
    // can't setColorsAndIcons here because the door hasn't got them yet. 
}

saveOptions()
{
    sayDebug("saveOptions()");
    string options = "";
    options = options + getOption("lockdown", OPTION_LOCKDOWN);
    options = options + getOption("delay", OPTION_DELAY);
    options = options + getOption("group", OPTION_GROUP);
    options = options + getOption("admin", OPTION_ADMIN);
    options = options + getOption("zap", OPTION_ZAP);
    options = options + getOption("normally-open", OPTION_NORMALLY_OPEN);
    options = options + getOption("button", OPTION_BUTTON);
    options = options + getOption("bump", OPTION_BUMP);
    options = options + getOption("direction", OPTION_DIRECTION);
    options = options + getOption("debug", OPTION_DEBUG);
    options = options + getOption("power", OPTION_POWER);

    // since we have no code to set these colors, we must assume that whatever's in the description is correct. 
    // if someone edited the description and then did a reset, we want to keep what's in the description. 
    string optionstring = llGetObjectDesc();
    OPTION_COLOR_FRAME = getVectorOption(optionstring, "frame");
    OPTION_COLOR_PANELS = getVectorOption(optionstring, "panels");
    OPTION_COLOR_CLEATS = getVectorOption(optionstring, "cleats");
    if (OPTION_COLOR_FRAME != JSON_INVALID) options = options + "frame"+ OPTION_COLOR_FRAME;
    if (OPTION_COLOR_PANELS != JSON_INVALID) options = options + "panels"+ OPTION_COLOR_PANELS;
    if (OPTION_COLOR_CLEATS != JSON_INVALID) options = options + "cleats"+ OPTION_COLOR_CLEATS;
    
    if (OPTION_OWNERS)
    {
         options = options + "owner[" + owners + "]";
    }
    sayDebug("saveOptions: \""+options+"\"");
    llSetObjectDesc(options);
}

reportStatus()
{
    llWhisper(0,"Door Logic Status:");
    llWhisper(0,"software version:"+version);
    llWhisper(0,"lockdown: "+(string)OPTION_LOCKDOWN);
    llWhisper(0,"delay: "+(string)OPTION_DELAY);
    llWhisper(0,"group: "+(string)OPTION_GROUP);
    llWhisper(0,"admin: "+(string)OPTION_ADMIN);
    llWhisper(0,"zap: "+(string)OPTION_ZAP);
    llWhisper(0,"normally-open: "+(string)OPTION_NORMALLY_OPEN);
    llWhisper(0,"button: "+(string)OPTION_BUTTON);
    llWhisper(0,"bump: "+(string)OPTION_BUMP);
    llWhisper(0,"debug: "+(string)OPTION_DEBUG);
    llWhisper(0,"power: "+(string)OPTION_POWER);
}

sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
}
    
sendJSONCheckbox(string jsonKey, string value, key avatarKey, integer ON) {
    if (ON) {
        sendJSON(jsonKey, value+"ON", avatarKey);
    } else {
        sendJSON(jsonKey, value+"OFF", avatarKey);
    }
}
    
sendJSONinteger(string jsonKey, integer value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, (string)value]), avatarKey);
}
    
string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
    }
    sayDebug("getJSONstring("+jsonValue+", "+jsonKey+", "+valueNow+")  returns  "+result);
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

string menuCheckbox(string title, integer onOff)
{
    string checkbox;
    if (onOff)
    {
        checkbox = "☒";
    }
    else
    {
        checkbox = "☐";
    }
    return checkbox + " " + title;
}

maintenanceMenu(key whoClicked)
{
    list menu = [];
    menu = menu + [menuCheckbox("Open", OPTION_NORMALLY_OPEN)];
    menu = menu + [menuCheckbox("Button", OPTION_BUTTON)];
    menu = menu + [menuCheckbox("Bump", OPTION_BUMP)];
    
    menu = menu + [menuCheckbox("Power", OPTION_POWER)];
    menu = menu + [menuCheckbox("Lockdown", OPTION_LOCKDOWN)];
    menu = menu + [menuCheckbox("Delay", OPTION_DELAY)];

    menu = menu + [menuCheckbox("Group", OPTION_GROUP)];
    menu = menu + [menuCheckbox("Zap", OPTION_ZAP)];
    menu = menu + [menuCheckbox("Admin", OPTION_ADMIN)];

    menu = menu + [menuCheckbox("Debug", OPTION_DEBUG)];
    menu = menu + ["Status"];
    menu = menu + ["Reset"];
    menuChannel = (integer)llFloor(llFrand(1000+1000));
    menuListen = llListen(menuChannel, "", whoClicked, "");
    llDialog(whoClicked, "Door Logic ("+version+") Maintenance", menu, menuChannel);
    gMenuTimer = setTimerEvent(30);
}

integer setOptionLogical(string message, string choice, integer stateNow, integer stateNew)
{
    integer result = stateNow;
    if (llSubStringIndex(message, choice) > -1)
    {
        result = stateNew;
    }
    return result;
}

string getOption(string choice, integer stateNow)
{
    string result = "";
    if (stateNow)
    {
        result = choice + " ";
    }
    return result;
}

string getOptionString(string choice, string stateNow)
{
    string result = "";
    if (stateNow != "")
    {
        result = choice + stateNow + " ";
    }
    return result;
}

integer checkAdmin(key whoclicked)
{
    sayDebug("checkAdmin");
    integer authorized = 1;
    if (OPTION_ADMIN && !llSameGroup(whoclicked))
    {
        sayDebug("checkAdmin turning off");
        authorized = 0;
    }
    return authorized;
}

integer uuidToInteger(key uuid)
// primitive hash of uuid parts
// It is used to generate a channel number from an avatar UUID.
{
    // UUID looks like 284ba63f-378b-4be6-84d9-10db6ae48b8d
    string hexdigits = "abcdef";
    list uuidparts = llParseString2List(uuid,["-"],[]);
    // last one is too big; split it into 2 6-digit numbers
    string last = llList2String(uuidparts,4);
    string last1 = llGetSubString(last,0,5);
    string last2 = llGetSubString(last,6,12);
    list lasts = [last1, last2];
    uuidparts = llListReplaceList(uuidparts, lasts, 4, 4);
    
    integer sum = 0;
    integer i = 0;
    // take each uuid part
    for (i=0; i < llGetListLength(uuidparts); i++) {
        string uuidPart = llList2String(uuidparts,i);
        integer j;
        // look at each digit
        for (j=0; j < llStringLength(uuidPart); j++) {
            string c = llGetSubString(uuidPart, j, j);
            string k = (string)llSubStringIndex(hexdigits, c);
            // if it's in abcdef
            if ((integer)k > -1) {
                // substitute in the digit 123456
                uuidPart = llDeleteSubString(uuidPart, j, j);
                uuidPart = llInsertString(uuidPart, j, k);
            }
        }
        sum = sum - (integer)uuidPart;
    }
    return sum;
}

pokeResponder(key whoclicked) {
    // send a message on the responderChannel for the avatar
    // the message looks like
    // {"request":["mood","class","lockLevel"]}
    responderChannel = uuidToInteger(whoclicked);
    responderListen = llListen(responderChannel, "", "", "");
    responderTimer = setTimerEvent(TIMER_INTERVAL);
    
    // first make a json list
    string jsonArray = (llList2Json(JSON_ARRAY, ["role", "mood","class","lockLevel"]));
    string jsonRequest = llList2Json(JSON_OBJECT, ["request", jsonArray]);
    sayDebug("pokeResponder jsonRequest:"+(string)responderChannel + " " + jsonRequest);
    llSay(responderChannel, jsonRequest);
    // Message from avatar comes back in default listen where channel == responderChannel
}

integer checkAuthorization1(string calledby, key whoclicked)
// all the decisions about whether to do anything
// in response to bump or press button
{
    sayDebug("checkAuthorization1 called by "+calledby);
    // assume no authorization
    integer authorized = 1;
    
    // group prohibits
    if (OPTION_GROUP & (!llSameGroup(whoclicked)))
    {
        sayDebug("checkAuthorization1 failed group check");
        authorized = 0;
    }

    // power off prohibits, but don't zap
    if ((OPTION_POWER) & (gPowerState == POWER_OFF))
    {
        sayDebug("checkAuthorization1 failed power check");
        authorized = 0;
        return authorized;
    }
    
    // lockdown checks group
    if ((gLockdownState == LOCKDOWN_ON | gLockdownState == LOCKDOWN_TEMP) && (!llSameGroup(whoclicked)))
    {
        sayDebug("checkAuthorization1 gLockdownState:"+(string)gLockdownState+" failed lockdown group check");
        authorized = 0;
    }

    // owner match overrides
    sayDebug("owners:"+owners+" whoclicked:"+llKey2Name(whoclicked));
    if (OPTION_OWNERS & (llSubStringIndex(owners, llKey2Name(whoclicked))) >= 0)
    {
        sayDebug ("checkAuthorization1 passed OWNERS check");
        authorized = 1;
    }
    
    if (OPTION_DIRECTION)
    {
        vector doorPos = llGetPos();
        rotation doorRot = llGetRot();
        vector avatarPos = llList2Vector(llGetObjectDetails(whoclicked, [OBJECT_POS]), 0);
        vector end = llVecNorm(avatarPos - doorPos); // vector from dor to avatar, normalized
        vector start = <0,1,0>; // a point out from door, normalized
        rotation rotBetween = llRotBetween(start, end) / doorRot;
        vector eulerBetween = llRot2Euler(rotBetween) * RAD_TO_DEG;
        if  (eulerBetween.z < 0) {
             direction = "Exit";
        } else {
             direction = "Enter";
        }   
        sayDebug("checkAuthorization1 "+direction);
    }

    if (authorized)
    {
        sayDebug("checkAuthorization1 passed checks");
    }
    else
    {
        if (OPTION_ZAP) 
        {
            sayDebug("checkAuthorization1 failed checks; zapping");
            llSay(ZAP_CHANNEL,(string)whoclicked);
        } 
        else 
        {
            sayDebug("checkAuthorization1 failed checks");
        }
    }
    sendJSONinteger("authorized", authorized, "");

    sayDebug("checkAuthorization1 returns "+(string)authorized);
    return authorized;
}

integer checkAuthorization2 (string avatarJSON) {
    sayDebug("checkAuthorization2 ("+avatarJSON+")"); 
    // [{"role":"Inmate"},{"mood":"OOC"},{"class":"blue"},{"lockLevel":"Off"}]
    integer authorized = 0;
    if (avatarJSON != JSON_INVALID) {
        string role = "unknown";
        string mood = "unknown";
        string class = "unknown";
        string lockLevel = "unknown";

        list keyValuePairs = llJson2List(avatarJSON);
        //sayDebug("checkAuthorization2 keyValuePairs:"+(string)keyValuePairs); 
        integer i;
        list responses;
        for (i = 0; i < llGetListLength(keyValuePairs); i = i + 2) {
            string thekey = llList2String(keyValuePairs, i);
            string value = llList2String(keyValuePairs, i+1);
            //sayDebug("checkAuthorization2 thekey:"+thekey+"  value:"+value);
            if (thekey ==  "role") {role = value;}
            if (thekey ==  "mood") {mood = value;}
            if (thekey ==  "class") {class = value;}
            if (thekey ==  "lockLevel") {lockLevel = value;}
        }        
        sayDebug("checkAuthorization2 role:"+role+" mood:"+mood+" class:"+class+" Lock:"+lockLevel);
        if (role == "inmate") {
            if (direction == "Exit") {
                if (mood == "OOC") {
                    authorized = 1;
                } else {
                    llWhisper(0, "Inmate! Exit is forbidden. ((Switch your mood to OOC.))");
                }
            } else {
                if (mood != "OOC") {
                    authorized = 1;
                } else {
                    llWhisper(0, "Inmate! Entry is forbidden. ((Switch your mood to IC.))");
                }
            }
        }     
        
    } else {
        sayDebug("checkAuthorization2 got bad json");
    }
    sayDebug("checkAuthorization2 returns "+(string)authorized);
    return authorized;
}

// sends open command to hardware
// starts sensor
// handles temporary lockdown
// hardware calls setColorsAndIcons
open()
{
    sayDebug("open()");
    sendJSON("command", "open", "");

    // if normally closed or we're in lockdown,
    // start a sensor that will close the door when it's clear. 
    if (!OPTION_NORMALLY_OPEN | gLockdownState == LOCKDOWN_ON | gLockdownState == LOCKDOWN_IMMINENT) 
    {
        sayDebug("open setting sensor radius "+(string)gSensorRadius);
        llSensorRepeat("", "", AGENT, gSensorRadius, PI, 1.0);
    } 
    
    // if we were in temporary door-lock, then open the door and reset locdown state
    // This needs to be done no matter what called open().
    if (gLockdownState == LOCKDOWN_TEMP)
    {
        sayDebug("open gLockdownState LOCKDOWN_TEMP -> gLockdownState = LOCKDOWN_OFF");
        gLockdownState = LOCKDOWN_OFF;
        gLockdownTimer = setTimerEvent(LOCKDOWN_OFF); 
        sendJSONinteger("lockdownState", gLockdownState, "");
    }
}

// sends close command to hardware
// handles temporary lockdown
// hardware calls setColorsAndIcons
close() 
{
    sayDebug("close");
    sendJSON("command", "close", "");
    
    // if normally open and we're in lockdown,
    // start the fair-game automatic release timer
    if (OPTION_NORMALLY_OPEN & gLockdownState != LOCKDOWN_ON & gPowerState != POWER_OFF)
    {
        sayDebug("close setting fair-game release");
        gLockdownState = LOCKDOWN_TEMP;
        gLockdownTimer = setTimerEvent(LOCKDOWN_RESET_TIME);
        sendJSONinteger("lockdownState", gLockdownState, "");
    }
}

toggleDoor()
{
    sayDebug("toggleDoor()");
    if (doorState == CLOSED)
    {
        sayDebug("toggleDoor CLOSED -> open");
        open();
    }
    else 
    {
        sayDebug("toggleDoor OPEN -> close");
        close();
    }
    sayDebug("toggleDoor ends");
}

integer setTimerEvent(integer duration) 
{
    sayDebug("setTimerEvent("+(string)duration+")");
    if (duration > 0)
    {
        llSetTimerEvent(TIMER_INTERVAL);
        // Somebody else may be using the timer, so don't turn it off.
    }
    return duration;
}

setColorsAndIcons()
{
    sayDebug("setColorsAndIcons()");
    sendJSON("command", "setColorsAndIcons", "");
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
        getOptions();
        sayDebug("state_entry got options");
        
       // set up power failure listen
        gPowerState = POWER_ON;
        if (OPTION_POWER) 
        {
            gPowerListen = llListen(POWER_CHANNEL,"","","");
        }
        
        // set up lockdown listen
        if (OPTION_LOCKDOWN) 
        {
            gLockdownListen = llListen(LOCKDOWN_CHANNEL,"","","");
            gLockdownState = LOCKDOWN_OFF;
        }
        
        vector frameSize = llGetScale( );
        gSensorRadius = (frameSize.x + frameSize.y + frameSize.z) / 4.0;
        
        sendOptions();
        llSleep(1);

        if (OPTION_NORMALLY_OPEN) {
            doorState = CLOSED;
            open();
        }
        else
        {
            doorState = OPEN;
            close();
        }
        
        sayDebug("state_entry end");
    }

    listen(integer channel, string name, key id, string message) {
        //sayDebug("listen channel:"+(string)channel+" name:'"+name+"' message: '"+message+"'");
        if ((channel == POWER_CHANNEL) & (gPowerState != POWER_FAILING) & (gPowerState != POWER_OFF)) 
        {
            sayDebug("listen POWER_CHANNEL gPowerState:"+(string)gPowerState);
            list xyz = llParseString2List( message, [","], ["<",">"]);
            vector distantloc;
            distantloc.x = llList2Float(xyz,1);
            distantloc.y = llList2Float(xyz,2);
            distantloc.z = llList2Float(xyz,3);
            vector here = llGetPos();
            float distance = llVecDist(here, distantloc)/10.0 + TIMER_INTERVAL;
            gPowerTimer = setTimerEvent((integer)distance);
            gPowerState = POWER_FAILING;
            sendJSONinteger("powerState", gPowerState, "");
            setColorsAndIcons();
        }
        
        else if (channel == responderChannel)
        {
            sayDebug("listen responderChannel message:"+message);
            // like {"response":[{"role":"Inmate"},{"mood":"unknown"},{"class":"unknown"},{"lockLevel":"unknown"}]}
            avatarJSON = llJsonGetValue(message, ["response"]);
            if (checkAuthorization2(avatarJSON)) {
                toggleDoor();
            }
            llListenRemove(responderChannel);
        }
        
        else if (channel == LOCKDOWN_CHANNEL) 
        {
            sayDebug("listen LOCKDOWN_CHANNEL gLockdownState:"+(string)gLockdownState);
            sayDebug("listen LOCKDOWN_CHANNEL message:"+message);
            if (message == "LOCKDOWN") 
            {
                if (OPTION_DELAY == 0)
                {
                    sayDebug("listen OPTION_DELAY == 0 -> gLockdownState = LOCKDOWN_ON");
                    llPlaySound(sound_lockdown,1);
                    gLockdownState = LOCKDOWN_ON;
                    gLockdownTimer = setTimerEvent(LOCKDOWN_RESET_TIME);
                    close(); // don't put a sensor here. It's lockdown. Get out of the way!
                }
                else
                {
                    sayDebug("listen LOCKDOWN_DELAY != 0 -> gLockdownState = LOCKDOWN_IMMINENT");
                    gLockdownState = LOCKDOWN_IMMINENT;
                    gLockdownTimer = setTimerEvent(LOCKDOWN_DELAY);   
                }
            }
            if (message == "RELEASE") 
            {
                // Lockdown On -> Off because message
                sayDebug("listen RELEASE -> gLockdownState = LOCKDOWN_OFF");
                gLockdownState = LOCKDOWN_OFF;
                gLockdownTimer = setTimerEvent(LOCKDOWN_OFF); 
                if (OPTION_NORMALLY_OPEN)
                {
                    open();
                }
            }
            sendJSONinteger("lockdownState", gLockdownState, "");
            setColorsAndIcons();
        }
         
        else if (channel == menuChannel)
        {
            sayDebug("listen menu "+message);
            
            llListenRemove(menuListen);
            menuListen = 0;
            menuChannel = 0;
            gMenuTimer = 0;
            
            // update any statuses from the menu
            integer stateNew = llGetSubString(message,0,0) == "☐";
            OPTION_POWER = setOptionLogical(message, "Power", OPTION_POWER, stateNew);
            OPTION_LOCKDOWN = setOptionLogical(message, "Lockdown", OPTION_LOCKDOWN, stateNew);
            OPTION_DELAY = setOptionLogical(message, "Delay", OPTION_DELAY, stateNew);
            OPTION_GROUP = setOptionLogical(message, "Group", OPTION_GROUP, stateNew);
            OPTION_ADMIN = setOptionLogical(message, "Admin", OPTION_ADMIN, stateNew);
            OPTION_ZAP = setOptionLogical(message, "Zap", OPTION_ZAP, stateNew);
            OPTION_NORMALLY_OPEN = setOptionLogical(message, "Open", OPTION_NORMALLY_OPEN, stateNew);
            OPTION_BUTTON = setOptionLogical(message, "Button", OPTION_BUTTON, stateNew);
            OPTION_BUMP = setOptionLogical(message, "Bump", OPTION_BUMP, stateNew);
            OPTION_DIRECTION = setOptionLogical(message, "Direction", OPTION_DIRECTION, stateNew);
            OPTION_DEBUG = setOptionLogical(message, "Debug", OPTION_DEBUG, stateNew);
            
            saveOptions(); // must save options now in case of reset
            
            if (message == "Reset")
            {
                sendJSON("command", "reset", "");
                llResetScript();
            }
            else if (message == "Status")
            {
                reportStatus();
                sendJSON("command", "reportStatus", "");
            }
            else 
            {
                sendOptions();
                llSleep(0.1); // give the hardware a moment to chew on this
            }
            
            if (OPTION_NORMALLY_OPEN && !doorState)
            {
                open(); // does setColorsAndIcons();
            } 
            else if (!OPTION_NORMALLY_OPEN && doorState)
            {
                close(); // does setColorsAndIcons();
            } 
            else
            {
                setColorsAndIcons();
            }
        }
    }
    
    link_message(integer sender_num, integer num, string json, key whoClicked){ 
        // We listen in on link status messages and pick the ones we're interested in
        doorState = getJSONinteger(json, "doorState", doorState);
        
        string command = "";
        command = getJSONstring(json, "command", command);
        if (command == "") {
            return;
        }
        sayDebug("link_message command:"+command);
        if (command == "button") {
            if (gMenuTimer > 0) {
                llListenRemove(menuListen);
                menuListen = 0;
                gMenuTimer = 0;
            }            
            if (checkAuthorization1("button", whoClicked)) {
                toggleDoor();
            } else {
                setColorsAndIcons();
                pokeResponder(whoClicked);
            }
        } else if (command == "bump") {
            if (!OPTION_NORMALLY_OPEN) {
                if (checkAuthorization1("bump", whoClicked)) {
                    toggleDoor();
                } else {
                    pokeResponder(whoClicked);
                    setColorsAndIcons();
                }
            }
        } else if (command == "admin") {
            if (checkAdmin(whoClicked)) {
                maintenanceMenu(whoClicked);
            } else {
                if (OPTION_ZAP) {
                    sayDebug("link_message failed checks; zapping");
                    llSay(ZAP_CHANNEL,(string)whoClicked);
                }
                setColorsAndIcons();
            }
        } else if (command == "getStatus") {
            sendOptions();
        } else {
            sayDebug("link_message ignored command:"+command);
        }
    }
    
    timer() {
        
        if (gMenuTimer > 0)
        {
            gMenuTimer = gMenuTimer - TIMER_INTERVAL;
            sayDebug("timer gMenuTimer "+(string)gMenuTimer);
            if (gMenuTimer <= 0)
            {
                llListenRemove(menuListen);
                menuListen = 0;
            }
        }
                    
        if (responderTimer > 0)
        {
            responderTimer = responderTimer - TIMER_INTERVAL;
            sayDebug("timer responderTimer "+(string)responderTimer);
            if (responderTimer <= 0)
            {
                llListenRemove(responderListen);
                responderListen = 0;
            }
        }
                    
        if (gPowerTimer > 0)
        {
            gPowerTimer = gPowerTimer - TIMER_INTERVAL;
            sayDebug("timer gPowerState:"+(string)gPowerState + " gPowerTimer:"+(string)gPowerTimer);
        }
        if (gPowerTimer <= 0)
        {
            // power timer has run out. 
            
            // POWER_FAILING means we just had a power failure. 
            // Power On -> Off because failure imminent timer
            if (gPowerState == POWER_FAILING) 
            {
                sayDebug("timer POWER_FAILING");
                gPowerState = POWER_OFF;
                sendJSONinteger("powerState", gPowerState, "");
                gPowerTimer = setTimerEvent(POWER_RESET_TIME);
                close();
            }
        
            // POWER_OFF means the power failure is over, so reset. 
            // Power Off -> On because restore timer
            else if (gPowerState == POWER_OFF) 
            {
                sayDebug("timer POWER_OFF");
                //llPlaySound(sound_granted,1.0); ***
                gPowerState = POWER_ON;
                sendJSONinteger("powerState", gPowerState, "");
                gPowerTimer = 0;
                if (OPTION_NORMALLY_OPEN)
                {
                    open(); // does setColorsAndIcons();
                }
                else
                {
                    setColorsAndIcons();
                }
            }
        }
        
        if (gLockdownTimer > 0)
        {
            gLockdownTimer = gLockdownTimer - TIMER_INTERVAL;
            sayDebug("timer gLockdownState:" + (string)gLockdownState + " gLockdownTimer:"+(string)gLockdownTimer);
        }
        if (gLockdownTimer <= 0) 
        {
            // lockdown timer has run out
            
            // LOCKDOWN_IMMINENT means lockdown was called
            // Lockdown Off -> On because lockdown imminent timer
            if (gLockdownState == LOCKDOWN_IMMINENT)
            {
                sayDebug("timer LOCKDOWN_IMMINENT");
                gLockdownState = LOCKDOWN_ON;
                sendJSONinteger("lockdownState", gLockdownState, "");
                gLockdownTimer = setTimerEvent(LOCKDOWN_RESET_TIME);   // fair-game half-hour automatic release
                close(); // don't put a sensor here. It's lockdown. Get out of the way!
            }
        
            // Lockdown On -> Off because fair-game rules
            else if (gLockdownState == LOCKDOWN_ON | gLockdownState == LOCKDOWN_TEMP)
            {
                sayDebug("timer LOCKDOWN_ON or LOCKDOWN_TEMP");
                gLockdownState = OFF;
                sendJSONinteger("lockdownState", gLockdownState, "");
                gLockdownTimer = 0;
                string optionstring = llGetObjectDesc();
                if (OPTION_NORMALLY_OPEN)
                {
                    open(); // does setColorsAndIcons();
                }
                else
                {
                    setColorsAndIcons();
                }
            }
        }
        
        if ( (gPowerTimer <= 0 & gLockdownTimer <= 0 & gMenuTimer <= 0) )
        {
            sayDebug("timer"+
                " gPowerTimer:"+(string)gPowerTimer+
                " gLockdownTimer:"+(string)gLockdownTimer+
                " gMenuTimer:"+(string)gMenuTimer
                );
            llSetTimerEvent(0);
            sendJSONinteger("powerState", gPowerState, ""); // dammit
            sendJSONinteger("lockdownState", gLockdownState, ""); // dammit
            setColorsAndIcons();
        }

   }
    
    no_sensor()
    {
        sayDebug("no_sensor");
        if (!OPTION_NORMALLY_OPEN | (OPTION_LOCKDOWN & (gLockdownState == LOCKDOWN_ON)))
        {
            close();
        }
        llSensorRemove();
    }
}
