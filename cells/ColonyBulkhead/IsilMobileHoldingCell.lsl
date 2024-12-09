// BG [COL] Bulkhead Door Script
// Replacement script for these doors at Black Gazza
// Timberwoof Lupindo
// May 20, 2018 - May 29, 2018
// 2.2 adds versatile timer; version number matches colony

// these parameters can be optionally set in the description:
// debug: whispers operational details
// lockdown: responds to station lockdown messages
// lockdown-delay[seconds]: waits seconds before closing when lockdown is called
//      lockdown checks samegroup; don't turn on lockdown option and group option
// power: responds to power failures
// group: makes it respond only to member of same group as door
// owner[ownername]: gives people listed the ability to open the door despite all settings
// zap: zaps nonmember who tries to operate door
// normally-open: door will open on reset, after power is restored, and lockdown is lifted
// otherwise door will close on reset and after power is restored. 
// frame:<r,g,b>: sets frame to this color
// label:<r,g,b>: sets panel color
// button: makes the "open" button work
// bump: makes the door open when someone bumps into it. 
// A normally-open door set to group, when closed by a member of the group,
// will stay closed for half an hour, implementing the fair-game rule. 
// typical setup: 
// bump button power lockdown-delay[120] label<.5,.5,1> frame<.5,.5,.5>

// custom for Isil
integer FACE_FRAME1 = 0;

integer PRIM_PANEL_1 = 2;
integer FACE_PANEL_1 = 1;

integer PRIM_DOOR_1 = 2;
integer FACE_DOOR_1 = 0;

vector PANEL_TEXTURE_SCALE = <1.0, 1.0, 0>;
vector PANEL_TEXTURE_OFFSET = <0.0, 0.0, 0>;
float PANEL_TEXTURE_ROTATION = 0.0;//-1.0*PI_BY_TWO;

integer PRIM_BOX = 2;

// colors
vector BLACK = <0,0,0>;
vector DARK_GRAY = <0.2, 0.2, 0.2>; // door
vector DARK_BLUE = <0.0, 0.0, 0.2>;
vector BLUE = <0.0, 0.0, 1.0>; // door
vector MAGENTA = <1.0, 0.0, 1.0>;
vector CYAN = <0.0, 1.0, 1.0>;
vector WHITE = <1.0, 1.0, 1.0>;
vector RED = <1.0, 0.0, 0.0>; // door
vector REDORANGE = <1.0, 0.25, 0.0>;
vector ORANGE = <1.0, 0.5, 0.0>; // door
vector YELLOW = <1.0, 1.0, 0.0>;
vector GREEN = <0.0, 1.0, 0.0>; // door

// my textures
string texture_auto_close = "d04fe5a2-d59e-d92d-3498-a0f4b1279356";
string texture_lockdown = "622233c6-10b8-0df0-720f-72d6627d5e04";
string texture_locked = "8e3485b0-3fb0-ef68-2fcb-b88b3ee929df";
string texture_press_to_open = "f80eb0af-0ecf-06bc-c708-64397285b40b";
string texture_bump_to_open = "55a465d3-32e6-9de4-54e7-a7168bcc74d2";

// ~Isil~ door textures
string texture_door_blue = "d5938215-7a13-17df-5451-b375b3ca0c22";
string texture_door_gray = "3acdf012-1c47-a306-d100-9ff36bbb7a35";
string texture_door_green = "67c6c7c7-e5e1-08ad-6a2a-ad9c11ba48ac";
string texture_door_orange = "65fa3524-e513-bee7-3349-ce5ed12f29d7";
string texture_door_red = "961d2fd3-dad4-28d3-db8b-3c279ea16c81";

// sounds
string sound_slide = "b3845015-d1d5-060b-6a63-de05d64d5444";
string sound_granted = "a4a9945e-8f73-58b8-8680-50cd460a3f46";
//string sound_denied = "d679e663-bba3-9caa-08f7-878f65966194";
//string sound_lockdown = "2d9b82b0-84be-d6b2-22af-15d30c92ad21";

// Physical Sizes
vector LEAF_SCALE = <0.0486, 0.3672, 0.7833>;  // x->y  y->x z_>z
float CLOSE_FACTOR = 0.0;
float OPEN_FACTOR = 0.40; // plus or minus
float ZOFFSET_FACTOR = -0.05;
float XOFFSET_FACTOR = -.44;

float fwidth;
float fopen;
float fclose;
float fdelta;
float fZoffset;
float fXoffset;
float gSensorRadius = 2.0;

integer ZAP_CHANNEL = -106969;
integer maintenanceChannel;
integer maintenanceListen;
integer prisonerChannel;
integer prisonerListen;

// Door States
integer doorState;
integer OPEN = 1;
integer CLOSED = 0;
string gdoorButton = "Open";

// power states
integer POWER_CHANNEL = -86548766;
integer gPowerListen; 
integer gPowerState = 0;
integer gPowerTimer = 0;
integer POWER_RESET_TIME = 60;
integer OFF = 0;
integer ON = 1;
integer DAMMIT = 1;
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
integer LOCKDOWN_DELAY = 0; // seconds
integer LOCKDOWN_OFF = 0;
integer LOCKDOWN_IMMINENT = 1;
integer LOCKDOWN_ON = 2;
integer LOCKDOWN_TEMP = 3; // for normally-open door closed fair-game release

// options
integer OPTION_DEBUG = 0;
integer OPTION_INFO = 0;
integer OPTION_LOCKDOWN = 0;
integer OPTION_POWER = 0;
integer OPTION_GROUP = 0;
integer OPTION_OWNERS = 0;
integer OPTION_ZAP = 0;
integer OPTION_NORMALLY_OPEN = 0;
integer OPTION_BUTTON = 0;
integer OPTION_BUMP = 0;
vector LABEL_COLOR = <1,1,1>; // used by appearance but we have to save it
vector FRAME_COLOR = <1,1,1>;
string owners = "";

// timer
integer TIMER_INTERVAL = 2;
float buttonTimer;

info(string message) {
    if (OPTION_INFO + OPTION_DEBUG)
    {
        llWhisper(0,"Main - "+message);
    }
}

debug(string message) {
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Main - "+message);
    }
}


// evaluates optionstring for presence of option
// returns true if option is present
integer getBooleanParameter(string optionstring, string option) {
    integer result = 0;
    if (llSubStringIndex(optionstring,option) > -1) 
        result = 1;
    return result;
}

// looks for label in optionstring, parses for following vector, returns it
vector getVectorParameter(string optionstring, string label, vector defaultValue) {
    vector result = defaultValue;
    integer label_index = llSubStringIndex(optionstring,label); 
    if (label_index > -1)
    {
        string theRest = llGetSubString(optionstring,label_index,-1);
        integer lbracket = llSubStringIndex(theRest,"<");
        integer rbracket = llSubStringIndex(theRest,">");
        string vectorString = llGetSubString(theRest, lbracket, rbracket);
        result = (vector)vectorString;
    }
    return result;
}

// extract option string from description, 
// set all the relevant options and parameters
getParameters() {
    string optionstring = llGetObjectDesc();
    info("getParameters("+ optionstring +")");
    OPTION_DEBUG = getBooleanParameter(optionstring, "debug");
    OPTION_INFO = getBooleanParameter(optionstring, "info");
    OPTION_LOCKDOWN = getBooleanParameter(optionstring, "lockdown");
    OPTION_POWER = getBooleanParameter(optionstring, "power");
    OPTION_GROUP = getBooleanParameter(optionstring, "group");
    OPTION_ZAP = getBooleanParameter(optionstring, "zap");
    OPTION_NORMALLY_OPEN = getBooleanParameter(optionstring, "normally-open");
    OPTION_BUTTON = getBooleanParameter(optionstring, "button");
    OPTION_BUMP = getBooleanParameter(optionstring, "bump");
    LABEL_COLOR = getVectorParameter(optionstring, "label", LABEL_COLOR);
    FRAME_COLOR = getVectorParameter(optionstring, "frame", FRAME_COLOR);

    integer lockdown_delay_index = llSubStringIndex(optionstring,"lockdown-delay"); 
    if (lockdown_delay_index > -1)
    {
        string theRest = llGetSubString(optionstring,lockdown_delay_index,-1);
        integer lbracket = llSubStringIndex(theRest,"[");
        integer rbracket = llSubStringIndex(theRest,"]");
        string lockdown_delay = llGetSubString(theRest,lbracket+1,rbracket-1);
        LOCKDOWN_DELAY = (integer)lockdown_delay;
        debug("lockdown_delay("+lockdown_delay+")="+(string)LOCKDOWN_DELAY);
    }
    
    integer owner_index = llSubStringIndex(optionstring,"owner"); 
    if (owner_index > -1)
    {
        string theRest = llGetSubString(optionstring,owner_index,-1);
        integer lbracket = llSubStringIndex(theRest,"[");
        integer rbracket = llSubStringIndex(theRest,"]");
        owners = llGetSubString(theRest,lbracket+1,rbracket-1);
        debug("owners:["+ owners +"]");
        OPTION_OWNERS = 1;
    }
    debug("getParameters end");
}

integer setOptionLogical(string message, string choice, integer stateNow, integer stateNew) {
    integer result = stateNow;
    if (llSubStringIndex(message, choice) > -1)
    {
        result = stateNew;
    }
    return result;
}

string getOption(string choice, integer stateNow) {
    string result = "";
    if (stateNow)
    {
        result = choice + " ";
    }
    return result;
}

// if stateNow is True, return the choice, otherwise return empty string. 
string getOptionString(string choice, string stateNow) {
    string result = "";
    if (stateNow != "")
    {
        result = choice + stateNow + " ";
    }
    return result;
}

// gather up all the options into an option string and save it to the description
saveOptions() {
    string options = "";
    options = options + getOption("lockdown", OPTION_LOCKDOWN);
    options = options + getOption("group", OPTION_GROUP);
    options = options + getOption("zap", OPTION_ZAP);
    options = options + getOption("normally-open", OPTION_NORMALLY_OPEN);
    options = options + getOption("button", OPTION_BUTTON);
    options = options + getOption("bump", OPTION_BUMP);
    options = options + getOption("debug", OPTION_DEBUG);
    options = options + getOption("info", OPTION_INFO);
    options = options + getOption("power", OPTION_POWER);
    options = options + getOptionString("label",  "["+(string)LABEL_COLOR+"]");
    options = options + getOptionString("frame", "["+(string)FRAME_COLOR+"]" );
    
    if (OPTION_OWNERS)
    {
         options = options + "owner[" + owners + "]";
    }
    info("saveOptions: \""+options+"\"");
    llSetObjectDesc(options);
    llMessageLinked(LINK_THIS, 2030, "",""); // make other scripts reread options
    //llResetScript();
}
 
// communicate the door state through a JSON string to the Appearance script. 
setColorsAndIcons() {
    info("setColorsAndIcons"); 
    string Dictionary = llList2Json( JSON_OBJECT, [] ); 
    Dictionary = llJsonSetValue (Dictionary, ["powerState",  "Value"], (string)gPowerState);
    Dictionary = llJsonSetValue (Dictionary, ["lockdownState",  "Value"], (string)gLockdownState);
    Dictionary = llJsonSetValue (Dictionary, ["doorState",  "Value"], (string)doorState);
    Dictionary = llJsonSetValue (Dictionary, ["doorTimerRunning",  "Value"], (string)gDoorTimerRunning);
    Dictionary = llJsonSetValue (Dictionary, ["doorClockRunning",  "Value"], (string)gDoorClockRunning);
    llMessageLinked(LINK_THIS, 2000, Dictionary,"");
}

// communicate the window state to the Appearance script. 
integer gcellAlphaState;
setCellAlpha(integer transparency) {
    info("setCellAlpha send");
    gcellAlphaState = transparency;
    llMessageLinked(LINK_THIS, 2020+transparency, "",""); // handoff to Apppearance
}

// power *********************************************
powerListen(integer channel, key id, string message) {
    if ((channel == POWER_CHANNEL) & (gPowerState != POWER_FAILING) & (gPowerState != POWER_OFF)) 
    {
        debug("powerListen");
        list xyz = llParseString2List( message, [","], ["<",">"]);
        vector distantloc;
        distantloc.x = llList2Float(xyz,1);
        distantloc.y = llList2Float(xyz,2);
        distantloc.z = llList2Float(xyz,3);
        vector here = llGetPos();
        float distance = llVecDist(here, distantloc)/10.0;
        gPowerState = POWER_FAILING;
        gPowerTimer = setTimerEvent((integer)distance);
    }
}
 
PowerTimer(){
    if (gPowerTimer > 0)
    {
        gPowerTimer = gPowerTimer - TIMER_INTERVAL;
        debug("timer gPowerState:"+(string)gPowerState + " gPowerTimer:"+(string)gPowerTimer);
    }
    if (gPowerTimer <= 0)
    {
        // power timer has run out. 
        
        // POWER_FAILING means we just had a power failure. 
        // Power On -> Off because failure imminent timer
        if (gPowerState == POWER_FAILING) 
        {
            debug("timer POWER_FAILING");
            gPowerState = POWER_OFF;
            gPowerTimer = setTimerEvent(POWER_RESET_TIME);
            close();
            setColorsAndIcons();
        }
        
        // POWER_OFF means the power failure is over, so reset. 
        // Power Off -> On because restore timer
        else if (gPowerState == POWER_OFF) 
        {
            debug("timer POWER_OFF");
            llPlaySound(sound_granted,1.0);
            gPowerState = POWER_ON;
            gPowerTimer = 0;
            setColorsAndIcons();
            open(OPTION_NORMALLY_OPEN, 0);
        }
    }
}


// Lockdown *********************************************
lockdownListen(integer channel, key id, string message) {
    if (channel == LOCKDOWN_CHANNEL) 
    {
        info("lockdownListen "+message);
        if (message == "LOCKDOWN") 
        {
            if (LOCKDOWN_DELAY <= 0)
            {
                info("listen LOCKDOWN_DELAY <= 0 -> gLockdownState = LOCKDOWN_ON");
                //llPlaySound(sound_lockdown,1);
                gLockdownState = LOCKDOWN_ON;
                gLockdownTimer = setTimerEvent(LOCKDOWN_RESET_TIME);
                close(); // don't put a sensor here. It's lockdown. Get out of the way!
            }
            else
            {
                info("listen LOCKDOWN_DELAY > 0 -> gLockdownState = LOCKDOWN_IMMINENT");
                gLockdownState = LOCKDOWN_IMMINENT;
                gLockdownTimer = setTimerEvent(LOCKDOWN_DELAY);   
                setColorsAndIcons();
            }
        }
        if (message == "RELEASE") 
        {
            // Lockdown On -> Off because message
            info("listen RELEASE -> gLockdownState = LOCKDOWN_OFF");
            gLockdownState = LOCKDOWN_OFF;
            gLockdownTimer = setTimerEvent(LOCKDOWN_OFF); 
            string optionstring = llGetObjectDesc();
            open(OPTION_NORMALLY_OPEN, 0);
        }
    }
}

LockdownTimer() {
    if (gLockdownTimer > 0)
    {
        gLockdownTimer = gLockdownTimer - TIMER_INTERVAL;
        //debug("timer gLockdownState:" + (string)gLockdownState + " gLockdownTimer:"+(string)gLockdownTimer);
    }
    if (gLockdownTimer <= 0) 
    {
        // lockdown timer has run out
            
        // LOCKDOWN_IMMINENT means lockdown was called
        // Lockdown Off -> On because lockdown imminent timer
        if (gLockdownState == LOCKDOWN_IMMINENT)
        {
            debug("timer LOCKDOWN_IMMINENT");
            gLockdownState = LOCKDOWN_ON;
            gLockdownTimer = setTimerEvent(LOCKDOWN_RESET_TIME);   // fair-game half-hour automatic release
            close(); // don't put a sensor here. It's lockdown. Get out of the way!
        }
        
        // Lockdown On -> Off because fair-game rules
        else if (gLockdownState == LOCKDOWN_ON | gLockdownState == LOCKDOWN_TEMP)
        {
            debug("timer LOCKDOWN_ON or LOCKDOWN_TEMP");
            gLockdownState = OFF;
            gLockdownTimer = 0;
            string optionstring = llGetObjectDesc();
            open(OPTION_NORMALLY_OPEN, 0);
        }
    }
}


// status ******************************
ReportStatus() {
    llOwnerSay("door timer running: " + (string)gDoorTimerRunning);
    llOwnerSay("door timer remaining: " + (string)gDoorTimeRemaining);
    llOwnerSay("door timer start: " + (string)gDoorTimeStart);
    llOwnerSay("door clock running: " + (string)gDoorClockRunning);
    llOwnerSay("door clock end: " + (string)gDoorClockEnd);
    llOwnerSay("door clock passed: " + (string)gDoorClockPassed);
    llOwnerSay("door: " + (string)doorState);
}


// Command Menu ***************************
integer commandChannel;
integer commandListen;
integer commandChannelExpires;
integer maintenanceChannelExpires;
integer prisonerChannelExpires;
string WINDOW_BUTTON = "Window";

// convert a "boolean" to a checked or not checked checkbox
string menuCheckbox(string title, integer onOff) {
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

// if a menu timer has expired, kill its listen and return zero
integer menuTimer(float channelExpires, integer menuListen) {
    integer result = menuListen;
    if (llGetUnixTime() > channelExpires) {
        llListenRemove(menuListen);
        result = 0;
        debug("menuTimer");
    }
    return result;
}

commandMenu(key whoClicked) {
    string header = "Cell Operation: ";
    if (gDoorClockRunning) 
    {
        header = header + displayDoorClock();
    } 
    else 
    {
        header = header + displayDoorTimer();
    }
    
    list menu = [];
    menu += [];
    menu += [gdoorButton];
    menu += [menuCheckbox(WINDOW_BUTTON, gcellAlphaState)]; // 
    menu += ["Set Timer…"];
    menu += [gDoorClockButton];
    menu += [gTrapButton];
    
    if (llSameGroup(whoClicked))
    {
        menu += ["Status"];
        menu += ["Maintenance"];
    }

    commandChannel = -1 * (integer)llFloor(llFrand(1000+1000));
    commandListen = llListen(commandChannel, "", whoClicked, "");
    commandChannelExpires = llGetUnixTime( ) + 60; 
    debug("commandMenu "+(string)commandChannel);
    llDialog(whoClicked, header, menu, commandChannel);
    llSetTimerEvent(TIMER_INTERVAL);
}

// process string generated by the main Command Menu and chosen by the user
commandMenuListen(integer incoming_channel, key incoming_key, string incoming_message) {
    if (incoming_channel == commandChannel) 
    {
        info("commandMenuListen: "+incoming_message); 
        if (incoming_message == "Open") {
            open(checkAuthorization(incoming_key),1);
        } else if (incoming_message == "Close") {
            close();
        } else if (incoming_message == gTrapButton) {
            if (gTrapState == TRAP_SAFE)
            {
                setCellTrap(TRAP_SET);
                llInstantMessage(incoming_key, "Trap has been set.");
            }
            else
            {
                setCellTrap(TRAP_SAFE);
                llInstantMessage(incoming_key, "Trap has been cleared.");
            }
        } else if (incoming_message == menuCheckbox(WINDOW_BUTTON,ON)) {
            setCellAlpha(OFF); 
        } else if (incoming_message == menuCheckbox(WINDOW_BUTTON,OFF)) {
            setCellAlpha(ON); 
        } else if (incoming_message == "Set Timer…") {
            llMessageLinked(LINK_THIS, 1000, "TIMER MODE",incoming_key);
        } else if (incoming_message == CLOCK_SET_BUTTON) {
            llMessageLinked(LINK_THIS, 1000, "CLOCK MODE",incoming_key);
        } else if (incoming_message == CLOCK_UNSET_BUTTON) {  
            resetDoorClock();
        } else if (incoming_message == "Status") {
            ReportStatus();
        } else if (incoming_message == "Maintenance") {
            maintenanceMenu(incoming_key);
        }
        llListenRemove(commandListen);
        commandListen = 0;
        commandChannel = 0;
        commandChannelExpires = llGetUnixTime();
    }
}

maintenanceMenu(key whoClicked) {
    list menu = [];
    menu = menu + [menuCheckbox("Lockdown", OPTION_LOCKDOWN)];
    menu = menu + [menuCheckbox("Group", OPTION_GROUP)];
    menu = menu + [menuCheckbox("Zap", OPTION_ZAP)];
    menu = menu + [menuCheckbox("Open", OPTION_NORMALLY_OPEN)];
    menu = menu + [menuCheckbox("Button", OPTION_BUTTON)];
    menu = menu + [menuCheckbox("Bump", OPTION_BUMP)];
    menu = menu + [menuCheckbox("Debug", OPTION_DEBUG)];
    menu = menu + [menuCheckbox("Info", OPTION_INFO)];
    menu += ["Status"];
    maintenanceChannel = -1 * (integer)llFloor(llFrand(1000+1000));
    maintenanceListen = llListen(maintenanceChannel, "", whoClicked, "");
    maintenanceChannelExpires = llGetUnixTime( ) + 60; 
    debug("maintenanceMenu "+(string)commandChannel);
    llDialog(whoClicked, "Maintenance", menu, maintenanceChannel);
    llSetTimerEvent(TIMER_INTERVAL);
}

maintenanceMenuListen(integer incoming_channel, key incoming_key, string message) {
    if (incoming_channel == maintenanceChannel) 
    {
        debug("maintenanceMenuListen: "+message); 
        integer stateNew = llGetSubString(message,0,0) == "☐";
        OPTION_LOCKDOWN = setOptionLogical(message, "Lockdown", OPTION_LOCKDOWN, stateNew);
        OPTION_GROUP = setOptionLogical(message, "Group", OPTION_GROUP, stateNew);
        OPTION_ZAP = setOptionLogical(message, "Zap", OPTION_ZAP, stateNew);
        OPTION_NORMALLY_OPEN = setOptionLogical(message, "Open", OPTION_NORMALLY_OPEN, stateNew);
        OPTION_BUTTON = setOptionLogical(message, "Button", OPTION_BUTTON, stateNew);
        OPTION_BUMP = setOptionLogical(message, "Bump", OPTION_BUMP, stateNew);
        OPTION_DEBUG = setOptionLogical(message, "Debug", OPTION_DEBUG, stateNew);
        OPTION_INFO = setOptionLogical(message, "Info", OPTION_DEBUG, stateNew);
        OPTION_POWER = setOptionLogical(message, "Power", OPTION_POWER, stateNew);
            
        saveOptions();
        open(OPTION_NORMALLY_OPEN, 0);
        
        llListenRemove(maintenanceListen);
        maintenanceListen = 0;
        maintenanceChannel = 0;
        maintenanceChannelExpires = llGetUnixTime();
    }
}


// cell door timer  ********************************
// This timer controls how long the door stays shut
// This works like a kitchen timer: "30 minutes from now"
// It has non-obvious states that need to be announced and displayed
integer gDoorTimeRemaining = 0; // seconds remaining on timer
integer gDoorTimerRunning = 0; // 0 = stopped; 1 = running
integer gDoorTimeStart = 1800; // seconds it was set to so we can set it again 
integer gPopulationNum = 0; // number of Prisoners
string gNamesInCell = ""; // a list of names of peope in the cell
key gKeyInCell;
list gPopulationList; // UUIDs of gPrisoners

string secondsToDaysHoursMinutesSeconds(integer secondsRemaining) {

    string display_time = "";

    integer days = secondsRemaining/86400;
    if (days > 0) {
        display_time += (string)days+"d ";   
    }

    integer carry_over_seconds = secondsRemaining - (86400 * days);
    integer hours = carry_over_seconds / 3600;
    if (hours < 10) {
        display_time += "0";
    }
    display_time += (string)hours + ":";

    carry_over_seconds = carry_over_seconds - (hours * 3600);
    integer minutes = carry_over_seconds / 60;
    if (minutes < 10) {
        display_time += "0";
    }
    display_time += (string)minutes+":";

    integer seconds = carry_over_seconds - (minutes * 60);
    if (seconds < 10) {
        display_time += "0";
    }
    display_time += (string)seconds;
    return display_time; 
}

string displayDoorTimer() {
    // parameter: gDoorTimeRemaining global
    // returns: a string in the form of "1 Days 3 Hours 5 Minutes 7 Seconds"
    // or "(no timer)" if seconds is less than zero
    if (gDoorTimeRemaining <= 0) {
        return "Timer not set. ";
    } else {
        return "Opens in " + secondsToDaysHoursMinutesSeconds(gDoorTimeRemaining) + ". ";
    }
}

resetDoorTimer() {
    // reset the timer to the value previously set for it. init and finish countdown. 
    info("resetDoorTimer");
    gDoorTimeRemaining = gDoorTimeStart; 
    gDoorTimerRunning = 0; // timer is stopped
    startSensor();
}

setDoorTimer(integer set_time) {
    // set the timer to the desired time, remember that time
    info("setDoorTimer("+(string)set_time+")");
    gDoorTimeRemaining = set_time; // set it to that 
    gDoorTimeStart = set_time; // remember what it was set to
    gDoorTimerRunning = 1;
    startSensor();
    llSetTimerEvent(TIMER_INTERVAL);
}

startDoorTimer() {
    // make the timer run. Init and finish countdown. 
    info("startDoorTimer");
    gDoorTimerRunning = 1; // timer is running
    llSetTimerEvent(TIMER_INTERVAL);
}

stopDoorTimer() {
    // stop the timer.
    // *** perhaps use this while prisoner is being schoked
    info("stopDoorTimer");
    gDoorTimerRunning = 0; // timer is stopped
}

updateDoorTimer() {
    if (gDoorTimeRemaining <= 0) {
        debug("updateDoorTimer gDoorTimerRunning=" + (string)gDoorTimerRunning + " gDoorTimeRemaining=" + (string)gDoorTimeRemaining);
        // time has run out...
        open(OPTION_NORMALLY_OPEN, 0);
        resetDoorTimer();
        stopSensor();
    }   

    if (doorState == CLOSED && gPopulationNum != 0) {
        debug("updateDoorTimer gDoorTimerRunning=" + (string)gDoorTimerRunning + " gDoorTimeRemaining=" + (string)gDoorTimeRemaining);
        // timer's on, door's closed, someone's in here
        //decDoorTimer(); // optimization
        gDoorTimeRemaining -= TIMER_INTERVAL;
    }
}

// cell door clock  ********************************
// This clock controls when the door opens
// This works like an alarm clock: "Open the door at 7:36 pm"
// It has non-obvious states that need to be announced and displayed. 
// It uses the server's seconds-since-midnight counter. 
// If time has not yet occurred today, it will open today. 
// If the time set has already occurred today, it will open tomorrow. 
integer gDoorClockRunning = 0; // 0 = stopped; 1 = running
integer gDoorClockEnd = 1; // midnight:00:01
integer gDoorClockPassed = 1; // 1 = the time has already occurred today; open tomorrow
// This configuration is pretty much always true. It is likely that it's after midnight, 
// so we have to wait until that time tomorrow

string CLOCK_UNSET_BUTTON = "Unset Clock";
string CLOCK_SET_BUTTON = "Set Clock…";
string gDoorClockButton = CLOCK_SET_BUTTON;

// converts clock state to a phrase displayable in the menu. 
string displayDoorClock() {
    // implied parameter: gDoorClockEnd global
    // returns: a string in the form of "19:30:00"
    // or "(not set)" if not set
    string display_time = " Opens at ";
    
    if (!gDoorClockRunning) {
        return "Clock not set. ";
    } else {
        return "Opens at " + secondsToDaysHoursMinutesSeconds(gDoorClockEnd) + ". ";
    }
}

setDoorClock(integer set_time) {
    info("setDoorClock");
    // set the timer to the desired time, remember that time
    integer now = (integer) llGetWallclock();    // what time is it now? 
    if (set_time < now) {
        gDoorClockPassed = 1;    // end happens tomorow
    } else {
        gDoorClockPassed = 0;     // end happens today
    }
    gDoorClockEnd = set_time; // remember what it was set to
    gDoorClockRunning = 1; 
    llSetTimerEvent(TIMER_INTERVAL);
    gDoorClockButton = CLOCK_UNSET_BUTTON;
}

resetDoorClock() {
    info("resetDoorClock");
    gDoorClockRunning = 0; // turn off the clock
    gDoorClockButton = CLOCK_SET_BUTTON;
    llSetTimerEvent(TIMER_INTERVAL);
}

updateDoorClock() {
    // call this every clock cycle
    integer now = (integer) llGetWallclock();    // what time is it now? 

    // first account for rolling over midnight
    if (gDoorClockPassed && now <= gDoorClockEnd) {
        debug("updateDoorClock gDoorClockPassed");
        gDoorClockPassed = 0;
        }

    if (gDoorClockPassed == 0 && gDoorClockEnd <= now) {
        debug("updateDoorClock !gDoorClockPassed");
        open(OPTION_NORMALLY_OPEN, 0);
        resetDoorClock();
    }
}


// Door **********************************
// Door has obvious state, open and closed, and does not need to announce its state
open(integer auth, integer override)
{
    debug("open("+(string)auth+", "+(string)override+")");
    if ( (CLOSED == doorState)  &  (((gPowerState == POWER_ON) & (gLockdownState == LOCKDOWN_OFF) & auth) | override) ) 
    {
        llPlaySound(sound_slide, 1.0);
        float f;
        for (f = fclose; f < fopen; f = f + fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <fXoffset, f, fZoffset>]);
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <fXoffset, fopen, fZoffset>]);
        doorState = OPEN;
    }

    // if normally closed or we're in lockdown,
    // start a sensor that will close the door when it's clear. 
    if (!OPTION_NORMALLY_OPEN | gLockdownState == LOCKDOWN_ON) 
    {
        debug("open setting sensor radius "+(string)gSensorRadius);
        llSensorRepeat("", "", AGENT, gSensorRadius, PI_BY_TWO, 1.0);
    } 
    if (gLockdownState == LOCKDOWN_TEMP)
    {
        debug("open gLockdownState LOCKDOWN_TEMP -> gLockdownState = LOCKDOWN_OFF");
        gLockdownState = LOCKDOWN_OFF;
        gLockdownTimer = setTimerEvent(LOCKDOWN_OFF); 
    }
    setColorsAndIcons();
}

close() 
{
    debug("close");
    if (OPEN == doorState) 
    {
        llPlaySound(sound_slide,1.0);
        float f;
        for (f = fopen; f >= fclose; f = f - fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <fXoffset, f, fZoffset>]);
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <fXoffset, fclose, fZoffset>]);
        doorState = CLOSED;
    } 
    
    // if normally open and we're in lockdown,
    // start the fair-game automatic release timer
    if (OPTION_NORMALLY_OPEN & gLockdownState != LOCKDOWN_ON & gPowerState != POWER_OFF)
    {
        debug("close setting fair-game release");
        gLockdownState = LOCKDOWN_TEMP;
        gLockdownTimer = setTimerEvent(LOCKDOWN_RESET_TIME);
    }
    setColorsAndIcons();
}

toggleDoor(integer auth, integer override) {
    info("toggleDoor("+(string)auth+", "+(string)override+")");
    if (doorState == CLOSED)
    {
        debug("toggleDoor CLOSED");
        open(auth, override);
    }
    else 
    {
        debug("toggleDoor OPEN");
        close();
    }
    debug("toggleDoor ends");
}


// trap  ********************************
// when "trap" is set, the cell closes when someone walks into it. 
// Makes cells self-service: you can walk in and have it close the door behind you. 
// cell trap has two states, safe and ready, and should annoucne state changes, but doesn't need to appear in display
integer gTrapState;
integer TRAP_SET = 1;
integer TRAP_SAFE = 0;
string gTrapButton;

setCellTrap(integer newState) {
    gTrapState = newState;
    gTrapButton = menuCheckbox("Trap",gTrapState);
    if (gTrapState == TRAP_SET) {
        startSensor();
    }
}


// Sensor ***************************************
// Only run the sensor when we need it.
// The sensor runs in the attached box prim and sends link messages back. 
startSensor() {
    llMessageLinked(PRIM_BOX, 3001, "sensor_start", NULL_KEY);
}

stopSensor() {
    if (gTrapState == TRAP_SAFE && gDoorTimeRemaining <= 0) {
        llMessageLinked(PRIM_BOX, 3000, "sensor_stop", NULL_KEY);
    }
}
    


// all the decisions about whether to do anything
// in response to bump or press button
integer checkAuthorization(key whoclicked) {
    // assume authorization
    integer authorized = 1;
    
    // group prohibits
    if (OPTION_GROUP & (!llSameGroup(llDetectedKey(0))))
    {
        info("checkAuthorization failed group check");
        authorized = 0;
    }

    // power off prohibits
    if ((OPTION_POWER) & (gPowerState == POWER_OFF))
    {
        info("checkAuthorization failed power check");
        authorized = 0;
        return authorized;
    }
    
    // timers running prohibit
    if (gDoorTimerRunning | gDoorClockRunning)
        {
        info("checkAuthorization failed timer check");
        authorized = 0;
        return authorized;
    }

    // lockdown checks group
    if ((OPTION_LOCKDOWN) & (gLockdownState == LOCKDOWN_ON) & (!llSameGroup(llDetectedKey(0))))
    {
        info("checkAuthorization failed lockdown group check");
        authorized = 0;
    }

    // owner match overrides
    if (OPTION_OWNERS & (llSubStringIndex(owners, llKey2Name(whoclicked))) >0)
    {
        info ("checkAuthorization passed OWNERS check");
        authorized = 1;
    }
    
    llMessageLinked(LINK_THIS, 2010+authorized, "",""); // handoff to Apppearance

    info("checkAuthorization returns "+(string)authorized);
    return authorized;
}

integer setTimerEvent(integer duration) {
    info("setTimerEvent("+(string)duration+")");
    if (duration > 0)
    {
        llSetTimerEvent(TIMER_INTERVAL);
        // Somebody else may be using the timer, so don't turn it off.
    }
    return duration;
}

default {
    state_entry() {
        getParameters();
        info("state_entry");
        gPowerState = POWER_OFF;
        
        // panel texture scale and offset
        llSetLinkColor(PRIM_PANEL_1, WHITE, FACE_PANEL_1);
        llSetLinkPrimitiveParams(PRIM_PANEL_1, [PRIM_TEXTURE, FACE_PANEL_1, texture_locked, PANEL_TEXTURE_SCALE, PANEL_TEXTURE_OFFSET, PANEL_TEXTURE_ROTATION]);
        llSetLinkPrimitiveParams(PRIM_PANEL_1, [PRIM_GLOW, FACE_PANEL_1, 0.1]);

        setColorsAndIcons();
        
        // calculate the leaf movements
        // get  the size of the door frame and calculate the sizes of the leaves
        vector frameSize = llGetScale( );
        // // x->y  y->x z_>z
        vector leafsize = <frameSize.y * LEAF_SCALE.y, frameSize.x * LEAF_SCALE.x, frameSize.z * LEAF_SCALE.z>; 
        fwidth = frameSize.x;
        fclose = fwidth * CLOSE_FACTOR;
        fopen = fwidth * OPEN_FACTOR;
        fdelta = .10;
        fZoffset = frameSize.z * ZOFFSET_FACTOR;
        fXoffset = frameSize.x * XOFFSET_FACTOR;
        
        // set the initial leaf sizes and positions
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-fclose, 0.0, fZoffset>]);

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
        
        setCellTrap(TRAP_SAFE);
        resetDoorTimer();
        gKeyInCell = NULL_KEY;
        setCellAlpha(ON);
        setColorsAndIcons();
        
        llPlaySound(sound_granted,1);
        info("initialized");
    }


    touch_start(integer total_number) {
        debug("touch_start face "+(string)llDetectedLinkNumber(0)+":"+(string)llDetectedTouchFace(0));
        // if it's the door panel, maybe open the door
        if ((llDetectedLinkNumber(0) == PRIM_DOOR_1) && (llDetectedTouchFace(0) == FACE_DOOR_1))
        {
            toggleDoor(checkAuthorization(llDetectedKey(0)), 0);
        }
        // if it's the control panel, maybe give the menu
        else if((llDetectedLinkNumber(0) == PRIM_PANEL_1) &&  (llDetectedTouchFace(0) == FACE_PANEL_1))
        {
            // guard group, give the menu
            if (llSameGroup(llDetectedKey(0)))
            {
                commandMenu(llDetectedKey(0));
            } 
            // if no one is in cell or timer and clocks are not running. 
            else if ((gKeyInCell == NULL_KEY) || (!gDoorTimerRunning && !gDoorClockRunning))
            {
                commandMenu(llDetectedKey(0));
            } 
            else 
            {
                string message = "Cell will unlock in an undetermined number of minutes.";
                if (gDoorTimerRunning) message = "Cell will unlock in "+(string)(gDoorTimeRemaining/60)+ " minutes.";
                if (gDoorClockRunning) message = "Cell will unlock "+(string)(gDoorClockEnd/60)+ " minutes after midnight.";
                llInstantMessage(llDetectedKey(0), message);
            }
        }
    }
        
    collision_start(integer total_number) {
        debug("collision_start");
        if (OPTION_BUMP) 
        {
            open(checkAuthorization(llDetectedKey(0)), 0);
        }
    }

    link_message(integer sender_num, integer msgInteger, string msgString, key msgKey) {
        debug("link_message:"+msgString+(string)msgInteger);
        if (msgString == "sensor") {
            // one or more avatars are here
            gPopulationNum = msgInteger;
            gNamesInCell = "";
            gPopulationList = []; // clear UUID list
        }
        else if (msgString == "sensor_list") 
        {
            // sensor will send us one message for each person here
            gPopulationList += [msgKey];  // uuid
        }
        else if (msgString == "sensor_done")
        {
            gKeyInCell = msgKey; // first person in list
            if (gTrapState == TRAP_SET && doorState == OPEN) 
            {
                close();
            }
        }
        else if (msgInteger == 1002) {
            // set timer time
            if (msgString == "") {
                resetDoorTimer();
            } else {
                setDoorTimer((integer)msgString);
            }
            displayDoorTimer();
        }
        else if (msgInteger == 1003) {
            // set clock time
            if (msgString == "") {
                resetDoorClock();
            } else {
                setDoorClock((integer)msgString);
            }
            displayDoorClock();
        }
    }

    listen(integer channel, string name, key id, string message) {
        debug("listen channel:"+(string)channel+" name:'"+name+"' message: '"+message+"'");
        debug("listen gPowerState:"+(string)gPowerState+" gLockdownState:"+(string)gLockdownState);
        commandMenuListen(channel, id, message);
        maintenanceMenuListen(channel, id, message);
        powerListen(channel, id, message);
        lockdownListen(channel, id, message);
    }
    
    timer() {
        //debug("timer");
        integer timerisNeeded = FALSE;
        
        // cheaper to make IFs here than make unneeded function calls
        if (gDoorTimerRunning) {
            updateDoorTimer();
            timerisNeeded = TRUE;
        }
        if (gDoorClockRunning) {
            updateDoorClock(); 
            timerisNeeded = TRUE;
        }
        if (commandListen != 0) {
            commandListen = menuTimer(commandChannelExpires, commandListen);
            timerisNeeded = TRUE;
        }
        if (prisonerListen != 0) {
            prisonerListen = menuTimer(prisonerChannelExpires, prisonerListen);
            timerisNeeded = TRUE;
        }
        if (maintenanceListen != 0) {
            maintenanceListen = menuTimer(maintenanceChannelExpires, maintenanceListen);
            timerisNeeded = TRUE;
        }
        if (gPowerTimer != 0) {
            PowerTimer();
            timerisNeeded = TRUE;
        }
        if (gLockdownTimer != 0) {
            LockdownTimer();
            timerisNeeded = TRUE;
        }        
        // if we don't need a timer, turn it off
        if (!timerisNeeded) {
            info("timer off");
            llSetTimerEvent(0);
            setColorsAndIcons();
        }
    }   
}
