// BG [NeurolaB Inc.] LUNA-2 DOOR
// Replacement script for Luna Doors: single or double, metal or glass at Black Gazza
// Timberwoof Lupindo
// January 1, 2014 - May 29, 2018
// 2.2 adds versatile timer; version number matches Greeble 

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
// label<r,g,b>: sets overhead label to this color
// button: makes the "open" button work
// bump: makes the door open when someone bumps into it. 

// A normally-open door set to group, when closed by a member of the group,
// will stay closed for half an hour, implementing the fair-game rule. 

// custom for luna
integer FACE_FRAME1 = 5;

integer PRIM_PANEL_1 = 1;
integer PRIM_PANEL_2 = 1;
integer FACE_PANEL_1 = 4;
integer FACE_PANEL_2 = 2;

integer PRIM_DOOR_1 = 5;
integer PRIM_DOOR_2 = 4;

// additional texture faces
integer FACE_KEYPAD = 0;
integer FACE_OVERHEAD = 1;
integer FACE_TEXT = 2;
integer FACE_OUTLINE = 3;
integer FACE_SLOT = 6;

integer primJet1 = 2;
integer primJet2 = 3;

vector PANEL_TEXTURE_SCALE = <1.0, 1.0, 0>;
vector PANEL_TEXTURE_OFFSET = <0.0, 0.0, 0>;

// Physical Sizes
vector LEAF_SCALE = <0.94, 0.9, 0.015>;
float CLOSE_FACTOR = 0.0;
float OPEN_FACTOR = -0.6;
float ZOFFSET_FACTOR = 0.0;

// colors
vector BLACK = <0,0,0>;
vector DARK_GRAY = <0.2, 0.2, 0.2>;
vector DARK_BLUE = <0.0, 0.0, 0.2>;
vector BLUE = <0.0, 0.0, 1.0>;
vector MAGENTA = <1.0, 0.0, 1.0>;
vector CYAN = <0.0, 1.0, 1.0>;
vector WHITE = <1.0, 1.0, 1.0>;
vector RED = <1.0, 0.0, 0.0>;
vector REDORANGE = <1.0, 0.25, 0.0>;
vector ORANGE = <1.0, 0.5, 0.0>;
vector YELLOW = <1.0, 1.0, 0.0>;
vector GREEN = <0.0, 1.0, 0.0>;

// my textures
string texture_auto_close = "d04fe5a2-d59e-d92d-3498-a0f4b1279356";
string texture_lockdown = "622233c6-10b8-0df0-720f-72d6627d5e04";
string texture_locked = "8e3485b0-3fb0-ef68-2fcb-b88b3ee929df";
string texture_press_to_open = "f80eb0af-0ecf-06bc-c708-64397285b40b";
string texture_bump_to_open = "55a465d3-32e6-9de4-54e7-a7168bcc74d2";

// Luna textures
string texture_luna_push_to_close = "f281d276-8410-7085-b7b1-f7d39ee16764";
string texture_luna_push_to_open = "19e1426e-8ebf-100a-c70d-a3b77c7117ee";//gets used
string texture_luna_access_granted = "6f635c48-e120-90db-d97c-2773992acda3";//gets used
string texture_luna_access_denied = "f58e636f-ea98-35a9-18c8-dc226b753fb5";//gets used

// sounds
string sound_slide = "b3845015-d1d5-060b-6a63-de05d64d5444";
string sound_granted = "a4a9945e-8f73-58b8-8680-50cd460a3f46";
string sound_denied = "d679e663-bba3-9caa-08f7-878f65966194";
string sound_lockdown = "2d9b82b0-84be-d6b2-22af-15d30c92ad21";

// luna has a numeric keypad
string sound_beep0 = "ccefe784-13b0-e59e-b0aa-c818197fdc03";
string sound_beep1 = "303afb6c-158f-aa6f-03fc-35bd42d8427d";
string sound_beep2 = "c4499d5e-85df-0e8e-0c6f-2c7e101517b5";
string sound_beep3 = "c3f88066-894e-7a3d-39b5-2619e8ae7e73";
string sound_beep4 = "10748aa2-753f-89ad-2802-984dc6e3d530";
string sound_beep5 = "2d9cf7a7-08e5-5687-6976-8d256b1dc84b";
string sound_beep6 = "97a896a8-0677-8281-f4e3-ba21c8f88b64";
string sound_beep7 = "01c5c969-daf1-6d7d-ade6-fd54dcb1aab5";
string sound_beep8 = "dafc5c77-8c81-02f1-6d36-9602d306dc0d";
string sound_beep9 = "d714bede-cfa3-7c33-3a7c-bcffd49534eb";

// luna has steam nozzles
float nozzleXoffset = -0.4610;
float nozzleZoffset = 0.1601;
float nozzle2Yoffset = 0.2888;
float nozzle3Yoffset = -0.3050;

float fwidth;
float fopen;
float fclose;
float fdelta;
float fZoffset;
float gSensorRadius = 2.0;

integer ZAP_CHANNEL = -106969;

integer menuChannel;
integer menuListen;

// Door States
integer doorState; // 1 = door is open
integer OPEN = 1;
integer CLOSED = 0;
integer QUIETLY = 0;
integer NOISILY = 1;

// power states
integer POWER_CHANNEL = -86548766;
integer gPowerListen; 
integer gPowerState = 0;
integer gPowerTimer = 0;
integer POWER_RESET_TIME = 60;
integer OFF = 0;
integer ON = 1;
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
integer LOCKDOWN_DELAY = 0; // seconds
integer LOCKDOWN_OFF = 0;
integer LOCKDOWN_IMMINENT = 1;
integer LOCKDOWN_ON = 2;
integer LOCKDOWN_TEMP = 3; // for normally-open door closed fair-game release

// options
integer OPTION_DEBUG = 0;
integer OPTION_LOCKDOWN = 0;
integer OPTION_POWER = 0;
integer OPTION_GROUP = 0;
integer OPTION_OWNERS = 0;
integer OPTION_ZAP = 0;
integer OPTION_NORMALLY_OPEN = 0;
integer OPTION_LABEL = 0;
integer OPTION_BUTTON = 0;
integer OPTION_BUMP = 0;
vector LABEL_COLOR = <1,1,1>;
vector OUTLINE_COLOR = <0,0,0>;
vector FRAME_COLOR = <0,0,0>;
string owners = "";

// timer
integer TIMER_INTERVAL = 2;

debug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,message);
    }
}

getParameters()
{
    string optionstring = llGetObjectDesc();
    debug("getParameters("+ optionstring +")");
    if (llSubStringIndex(optionstring,"debug") > -1) OPTION_DEBUG = 1;
    if (llSubStringIndex(optionstring,"lockdown") > -1) OPTION_LOCKDOWN = 1;
    if (llSubStringIndex(optionstring,"power") > -1) OPTION_POWER = 1;
    if (llSubStringIndex(optionstring,"group") > -1) OPTION_GROUP = 1;
    if (llSubStringIndex(optionstring,"zap") > -1) OPTION_ZAP = 1;
    if (llSubStringIndex(optionstring,"normally-open") > -1) OPTION_NORMALLY_OPEN = 1;
    if (llSubStringIndex(optionstring,"button") > -1) OPTION_BUTTON = 1;
    if (llSubStringIndex(optionstring,"bump") > -1) OPTION_BUMP = 1;
   
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
    
    integer label_index = llSubStringIndex(optionstring,"label"); 
    if (label_index > -1)
    {
        string theRest = llGetSubString(optionstring,label_index,-1);
        integer lbracket = llSubStringIndex(theRest,"<");
        integer rbracket = llSubStringIndex(theRest,">");
        string label = llGetSubString(theRest,lbracket,rbracket);
        LABEL_COLOR = (vector)label;
        debug("label"+label);
        OPTION_LABEL = 1;
        llSetColor(LABEL_COLOR,FACE_OVERHEAD);
        llSetPrimitiveParams([PRIM_GLOW, FACE_OVERHEAD, 0.0]);
    }
    llSetPrimitiveParams([PRIM_TEXTURE, FACE_OVERHEAD, TEXTURE_BLANK, <1.0, 1.0, 0>, <0.0, 0.0, 0>, 0.0]);
    
    integer outline_index = llSubStringIndex(optionstring,"outline"); 
    if (outline_index > -1)
    {
        string theRest = llGetSubString(optionstring,outline_index,-1);
        integer lbracket = llSubStringIndex(theRest,"<");
        integer rbracket = llSubStringIndex(theRest,">");
        string outline = llGetSubString(theRest,lbracket,rbracket);
        OUTLINE_COLOR = (vector)outline;
        debug("outline"+outline);
    }
    
    integer frame_index = llSubStringIndex(optionstring,"frame"); 
    if (frame_index > -1)
    {
        string theRest = llGetSubString(optionstring,frame_index,-1);
        integer lbracket = llSubStringIndex(theRest,"<");
        integer rbracket = llSubStringIndex(theRest,">");
        string frame = llGetSubString(theRest,lbracket,rbracket);
        FRAME_COLOR = (vector)frame;
        debug("frame"+frame);
        llSetColor(FRAME_COLOR, FACE_FRAME1);
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

// Luna door has a numeric keypad
keypadBeep(vector hv)
{
    if (gPowerState != POWER_ON)
    {
        debug("keypadBeep failed power check");
        return;
    }
    list sounds = [sound_beep0, 
        sound_beep1, sound_beep2, sound_beep3, 
        sound_beep4, sound_beep5, sound_beep6, 
        sound_beep7, sound_beep8, sound_beep9, 
        sound_beep0, sound_beep0, sound_beep0 ];
        
    integer ones = llFloor(hv.x * 3) + 1;
    integer threes = 9 - llFloor(hv.y * 4) * 3; 
    llPlaySound(llList2String(sounds,ones + threes),1);
}

string menuItem(string title, integer onOff)
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
    if (llSameGroup(whoClicked))
    {
        list menu = [];
        menu = menu + [menuItem("Lockdown", OPTION_LOCKDOWN)];
        menu = menu + [menuItem("Group", OPTION_GROUP)];
        menu = menu + [menuItem("Zap", OPTION_ZAP)];
        menu = menu + [menuItem("Open", OPTION_NORMALLY_OPEN)];
        menu = menu + [menuItem("Button", OPTION_BUTTON)];
        menu = menu + [menuItem("Bump", OPTION_BUMP)];
        menu = menu + [menuItem("Debug", OPTION_DEBUG)];
        menuChannel = (integer)llFloor(llFrand(1000+1000));
        menuListen = llListen(menuChannel, "", whoClicked, "");
        llDialog(whoClicked, "Maintenance", menu, menuChannel);
    }
     else if (OPTION_ZAP) 
    {
        debug("maintenanceMenu authorization failed; zapping");
        llSay(-106969,(string)whoClicked);
    }
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

saveOptions()
{
    string options = "";
    options = options + getOption("lockdown", OPTION_LOCKDOWN);
    options = options + getOption("group", OPTION_GROUP);
    options = options + getOption("zap", OPTION_ZAP);
    options = options + getOption("normally-open", OPTION_NORMALLY_OPEN);
    options = options + getOption("button", OPTION_BUTTON);
    options = options + getOption("bump", OPTION_BUMP);
    options = options + getOption("debug", OPTION_DEBUG);
    options = options + getOption("power", OPTION_POWER);
    options = options + getOptionString("label",(string)LABEL_COLOR);
    //options = options + getOptionString("outline",(string)OUTLINE_COLOR);
    //options = options + getOptionString("frame",(string)FRAME_COLOR);
    if (OPTION_OWNERS)
    {
         options = options + "owner[" + owners + "]";
    }
    debug("saveOptions: \""+options+"\"");
    llSetObjectDesc(options);
    llResetScript();
 }

integer checkAuthorization(key whoclicked)
// all the decisions about whether to do anything
// in response to bump or press button
{
    // assume authorization
    integer authorized = 1;
    
    // group prohibits
    if (OPTION_GROUP & (!llSameGroup(llDetectedKey(0))))
    {
        debug("checkAuthorization failed group check");
        authorized = 0;
    }

    // power off prohibits
    if ((OPTION_POWER) & (gPowerState == POWER_OFF))
    {
        debug("checkAuthorization failed power check");
        authorized = 0;
        return authorized;
    }
    
    // lockdown checks group
    if ((OPTION_LOCKDOWN) & (gLockdownState == LOCKDOWN_ON) & (!llSameGroup(llDetectedKey(0))))
    {
        debug("checkAuthorization failed lockdown group check");
        authorized = 0;
    }

    // owner match overrides
    debug("owners:"+owners+" whoclicked:"+llKey2Name(whoclicked));
    if (OPTION_OWNERS & (llSubStringIndex(owners, llKey2Name(whoclicked))) >= 0)
    {
        debug ("checkAuthorization passed OWNERS check");
        authorized = 1;
    }
    
    if (authorized)
    {
        debug("checkAuthorization authorization passed; setting colors and textures");
        llSetColor(GREEN, FACE_PANEL_1);
        llSetColor(GREEN, FACE_KEYPAD);
        llSetColor(GREEN, FACE_PANEL_2);
    }
    else
    {
        debug("checkAuthorization authorization failed; setting colors and textures");
        llSetTexture(texture_locked, FACE_PANEL_1);
        llSetTexture(texture_locked, FACE_PANEL_2);
        llSetColor(RED, FACE_PANEL_1);
        llSetColor(RED, FACE_KEYPAD);
        llSetColor(RED, FACE_PANEL_2);
        if (OPTION_ZAP) 
        {
            debug("checkAuthorization authorization failed; zapping");
            llSay(-106969,(string)whoclicked);
        }
    }

    debug("checkAuthorization returns "+(string)authorized);
    return authorized;
}

open(integer auth, integer override)
{
    debug("open("+(string)auth+", "+(string)override+")");
    if ( (CLOSED == doorState)  &  (((gPowerState == POWER_ON) & (gLockdownState == LOCKDOWN_OFF) & auth) | override) )
    {
        steamJet(1); // luna door has steam puffs
        llPlaySound(sound_slide, 1.0);
        float f;
        for (f = fclose; f < fopen; f = f + fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-f, 0.0, fZoffset> ]);
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <f, 0.0, fZoffset> ]);
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-fopen, 0.0, fZoffset> ]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <fopen, 0.0, fZoffset> ]);
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
        steamJet(1); // luna door has steam puffs
        llPlaySound(sound_slide,1.0);
        float f;
        for (f = fopen; f >= fclose; f = f - fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-f, 0.0, fZoffset>]);
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <f, 0.0, fZoffset>]);
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-fclose, 0.0, fZoffset>]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <fclose, 0.0, fZoffset>]);
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

toggleDoor(integer auth, integer override)
{
    debug("toggleDoor("+(string)auth+", "+(string)override+")");
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

// luna door has things that puff steam
steamJet(integer on)
{
    list puff = [
        PSYS_PART_FLAGS, 275,
        PSYS_SRC_PATTERN, 8, 
        PSYS_PART_START_ALPHA, 1.0,
        PSYS_PART_END_ALPHA, 0.0,
        PSYS_PART_START_COLOR, DARK_GRAY,
        PSYS_PART_END_COLOR, WHITE,
        PSYS_PART_START_SCALE, <0.05, 0.05, 0.0>,
        PSYS_PART_END_SCALE, <0.2, 0.2, 0.0>,
        PSYS_PART_MAX_AGE, 0.5,
        PSYS_SRC_MAX_AGE, 2.0, 
        PSYS_SRC_ACCEL, <0.0, 0.0, 0.0>,
        PSYS_SRC_ANGLE_BEGIN, 0.0,
        PSYS_SRC_ANGLE_END, 0.0,
        PSYS_SRC_BURST_PART_COUNT, 50,
        PSYS_SRC_BURST_RATE, 0.16,
        PSYS_SRC_BURST_RADIUS, 0.0,
        PSYS_SRC_BURST_SPEED_MIN, 0.5,
        PSYS_SRC_BURST_SPEED_MAX, 1.5,
        PSYS_SRC_OMEGA, <0.0, 0.0, 0.0>,
        PSYS_SRC_TARGET_KEY,(key)"",
        PSYS_SRC_TEXTURE, ""];

    if (on)
    {
        llLinkParticleSystem(primJet1, puff);
        llLinkParticleSystem(primJet2, puff);
    }
    else
    {
        llLinkParticleSystem(primJet1, []);
        llLinkParticleSystem(primJet2, []);
    }
}

setColorsAndIcons()
// Luna door has more panels that reflect state.
// Frame has all the panels so they are local calls.
{
    debug("setColorsAndIcons gPowerState:"+(string)gPowerState+" gLockdownState:"+(string)gLockdownState+" doorState:"+(string)doorState);
    if (gPowerState == POWER_OFF)
    {
        debug("setColorsAndIcons gPowerState POWER_OFF");
        llSetColor(BLACK, FACE_PANEL_1);
        llSetColor(BLACK, FACE_PANEL_2);
        llSetColor(BLACK, FACE_OVERHEAD);
        llSetColor(BLACK, FACE_KEYPAD);
        llSetColor(BLACK, FACE_OUTLINE);
        return;
    }

    if (gPowerState == POWER_FAILING)
    {
        debug("setColorsAndIcons gPowerState POWER_FAILING");
        llSetColor(BLUE, FACE_PANEL_1);
        llSetColor(BLUE, FACE_PANEL_2);
        llSetColor(BLUE, FACE_OVERHEAD);
        llSetColor(BLUE, FACE_KEYPAD);
        llSetColor(BLUE, FACE_OUTLINE);
        return;
    }

    if (gLockdownState == LOCKDOWN_IMMINENT)
    {
        debug("setColorsAndIcons gLockdownState LOCKDOWN_IMMINENT");
        llSetColor(REDORANGE, FACE_PANEL_1);
        llSetColor(REDORANGE, FACE_PANEL_2);
        llSetColor(REDORANGE, FACE_OVERHEAD);
        llSetColor(REDORANGE, FACE_KEYPAD);
        llSetColor(REDORANGE, FACE_OUTLINE);
        return;
    }

    if (gLockdownState == LOCKDOWN_ON)
    {
        debug("setColorsAndIcons gLockdownState LOCKDOWN_ON");
        llSetColor(RED, FACE_PANEL_1);
        llSetColor(RED, FACE_PANEL_2);
        llSetTexture(texture_locked, FACE_PANEL_1);
        llSetTexture(texture_luna_access_denied, FACE_PANEL_2);
        llSetColor(RED, FACE_OVERHEAD);
        llSetColor(RED, FACE_KEYPAD);
        llSetColor(RED, FACE_OUTLINE);
        llSetColor(RED, FACE_TEXT);
        llSetColor(WHITE, FACE_PANEL_1);
        return;
    }

    // Luna door has a big light at the top
    llSetColor(LABEL_COLOR, FACE_OVERHEAD);
    llSetColor(WHITE, FACE_PANEL_1);
    if (OPTION_GROUP)
    {
        debug("setColorsAndIcons OPTION_GROUP");
        llSetColor(ORANGE, FACE_TEXT);
        llSetColor(ORANGE, FACE_KEYPAD);
        llSetColor(ORANGE, FACE_OUTLINE);
    }
    else
    {
        debug("setColorsAndIcons !OPTION_GROUP");
        llSetColor(CYAN, FACE_TEXT);
        llSetColor(CYAN, FACE_KEYPAD);
        llSetColor(CYAN, FACE_OUTLINE);
    }
    
    if (OPEN == doorState) 
    {
        debug("setColorsAndIcons OPEN");
        llSetTexture(texture_luna_access_granted,FACE_TEXT);
        llSetTexture(texture_lockdown, FACE_PANEL_1);
    }
    else // (CLOSED == doorState)
    {
        if (OPTION_NORMALLY_OPEN) // temporarily closed
        {
            debug("setColorsAndIcons CLOSED OPTION_NORMALLY_OPEN");
            llSetColor(WHITE, FACE_PANEL_1);
            llSetColor(WHITE, FACE_PANEL_2);
            llSetTexture(texture_locked, FACE_PANEL_1);
            llSetTexture(texture_locked, FACE_PANEL_2);
        }
        else // (!OPTION_NORMALLY_OPEN)
        {
            debug("setColorsAndIcons CLOSED !OPTION_NORMALLY_OPEN");
            if(OPTION_GROUP) 
            {
                llSetLinkColor(PRIM_PANEL_1, ORANGE, FACE_PANEL_1);
                llSetLinkColor(PRIM_PANEL_2, ORANGE, FACE_PANEL_2);
            }
            else
            {
                llSetLinkColor(PRIM_PANEL_1, WHITE, FACE_PANEL_1);
                llSetLinkColor(PRIM_PANEL_2, WHITE, FACE_PANEL_2);
            }
            if(OPTION_BUTTON)
            {
                if (OPTION_BUMP)
                {
                    llSetTexture(texture_bump_to_open, FACE_PANEL_1);
                    llSetTexture(texture_luna_push_to_open, FACE_TEXT);
                }
                else
                {
                    llSetTexture(texture_press_to_open, FACE_PANEL_1);
                    llSetTexture(texture_luna_push_to_open, FACE_TEXT);
                }
            }
            else
            {
                if (OPTION_BUMP)
                {
                    llSetTexture(texture_bump_to_open, FACE_PANEL_1);
                    llSetTexture(texture_luna_access_granted, FACE_TEXT);
                }
                else
                {
                    llSetTexture(texture_locked, FACE_PANEL_1);
                    llSetTexture(texture_luna_access_denied, FACE_TEXT);
                }
            }
        }
    }
}

integer setTimerEvent(integer duration) 
{
    debug("setTimerEvent("+(string)duration+")");
    if (duration > 0)
    {
        llSetTimerEvent(TIMER_INTERVAL);
        // Somebody else may be using the timer, so don't turn it off.
    }
    return duration;
}

default
{
    state_entry()
    {
        getParameters();
        debug("state_entry");
        gPowerState = POWER_OFF;
        
        // panel texture scale and offset
        llSetLinkColor(PRIM_PANEL_1, WHITE, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, WHITE, FACE_PANEL_2);
        llSetLinkPrimitiveParams(PRIM_PANEL_1, [PRIM_TEXTURE, FACE_PANEL_1, texture_locked, PANEL_TEXTURE_SCALE, PANEL_TEXTURE_OFFSET, 0.0]);
        llSetLinkPrimitiveParams(PRIM_PANEL_2, [PRIM_TEXTURE, FACE_PANEL_2, texture_locked, PANEL_TEXTURE_SCALE, PANEL_TEXTURE_OFFSET, 0.0]);
        llSetLinkPrimitiveParams(PRIM_PANEL_1, [PRIM_GLOW, FACE_PANEL_1, 0.0]);
        llSetLinkPrimitiveParams(PRIM_PANEL_2, [PRIM_GLOW, FACE_PANEL_2, 0.0]);
        
        setColorsAndIcons();
        
        // calculate the leaf movements
        // get  the size of the door frame and calculate the sizes of the leaves
        vector frameSize = llGetScale( );
        vector leafsize = <frameSize.y * LEAF_SCALE.y, frameSize.x * LEAF_SCALE.x, frameSize.z * LEAF_SCALE.z>;
        fwidth = frameSize.y;
        fclose = fwidth * CLOSE_FACTOR;
        fopen = fwidth * OPEN_FACTOR;
        fdelta = .10;
        fZoffset = frameSize.z * ZOFFSET_FACTOR;

        // If it has two doors
        if (llGetNumberOfPrims() == 5) 
        {
            // two sliding leaves
            leafsize = <frameSize.y * LEAF_SCALE.y, frameSize.x * LEAF_SCALE.x / 2.0, frameSize.x * LEAF_SCALE.z>; 
            fwidth = frameSize.y;
            fclose = fwidth / 2.0;
            fopen = fwidth * OPEN_FACTOR / 2.0;
            fdelta = .20;
        }
        
        // set the initial leaf sizes and positions
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-fopen, 0.0, 0.0>]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <fopen, 0.0, 0.0>]);

        // calculate and set the nozzle locations - luna only
        llSetLinkPrimitiveParamsFast(primJet1,[PRIM_POS_LOCAL, 
        <frameSize.x*nozzleXoffset, frameSize.y*nozzle2Yoffset, frameSize.z*nozzleZoffset>]);
        llSetLinkPrimitiveParamsFast(primJet2,[PRIM_POS_LOCAL, 
        <frameSize.x*nozzleXoffset, frameSize.y*nozzle3Yoffset, frameSize.z*nozzleZoffset>]);

        // test the doors
        if (OPTION_NORMALLY_OPEN)
        {
            doorState = OPEN;
            close();
            open(1, OVERRIDE);
        }
        else
        {
            doorState = CLOSED;
            open(1, OVERRIDE);
            close();
        }
        
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
        
        gSensorRadius = (frameSize.x + frameSize.y) / 3.0;
        setColorsAndIcons();
        llPlaySound(sound_granted,1);
        debug("initialized");
    }


    touch_start(integer total_number)
    {
        debug("touch_start face "+(string)llDetectedTouchFace(0));
        // special handling for the numeric keypad on Luna doors
        if (llDetectedTouchFace(0) == FACE_KEYPAD)
        {
            keypadBeep(llDetectedTouchST(0));
        } else if (OPTION_BUTTON & (llDetectedTouchFace(0) == FACE_PANEL_1 | llDetectedTouchFace(0) == FACE_PANEL_2))
        {
            toggleDoor(checkAuthorization(llDetectedKey(0)), 0);
        } else if (llDetectedTouchFace(0) == FACE_SLOT)
        {
            maintenanceMenu(llDetectedKey(0));
        }
    }
    
    collision_start(integer total_number)
    {
        debug("collision_start");
        if (OPTION_BUMP) 
        {
            open(checkAuthorization(llDetectedKey(0)), 0);
        }
    }


    listen(integer channel, string name, key id, string message) {
        debug("listen channel:"+(string)channel+" name:'"+name+"' message: '"+message+"'");
        debug("listen gPowerState:"+(string)gPowerState+" gLockdownState:"+(string)gLockdownState);
        if ((channel == POWER_CHANNEL) & (gPowerState != POWER_FAILING) & (gPowerState != POWER_OFF)) 
        {
            debug("listen gPowerState = POWER_FAILING");
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
        
        else if (channel == LOCKDOWN_CHANNEL) 
        {
            debug("listen lockdown "+message);
            if (message == "LOCKDOWN") 
            {
                if (LOCKDOWN_DELAY <= 0)
                {
                    debug("listen LOCKDOWN_DELAY <= 0 -> gLockdownState = LOCKDOWN_ON");
                    llPlaySound(sound_lockdown,1);
                    gLockdownState = LOCKDOWN_ON;
                    gLockdownTimer = setTimerEvent(LOCKDOWN_RESET_TIME);
                    close(); // don't put a sensor here. It's lockdown. Get out of the way!
                }
                else
                {
                    debug("listen LOCKDOWN_DELAY > 0 -> gLockdownState = LOCKDOWN_IMMINENT");
                    gLockdownState = LOCKDOWN_IMMINENT;
                    gLockdownTimer = setTimerEvent(LOCKDOWN_DELAY);   
                    setColorsAndIcons();
                }
            }
            if (message == "RELEASE") 
            {
                // Lockdown On -> Off because message
                debug("listen RELEASE -> gLockdownState = LOCKDOWN_OFF");
                gLockdownState = LOCKDOWN_OFF;
                gLockdownTimer = setTimerEvent(LOCKDOWN_OFF); 
                string optionstring = llGetObjectDesc();
                if (OPTION_NORMALLY_OPEN)
                {
                    open(1, 0);
                }
                else
                {
                    setColorsAndIcons();
                }
            }
        }
         
        else if (channel == menuChannel)
        {
            debug("listen menu "+message);
            integer stateNew = llGetSubString(message,0,0) == "☐";
            OPTION_LOCKDOWN = setOptionLogical(message, "Lockdown", OPTION_LOCKDOWN, stateNew);
            OPTION_GROUP = setOptionLogical(message, "Group", OPTION_GROUP, stateNew);
            OPTION_ZAP = setOptionLogical(message, "Zap", OPTION_ZAP, stateNew);
            OPTION_NORMALLY_OPEN = setOptionLogical(message, "Open", OPTION_NORMALLY_OPEN, stateNew);
            OPTION_BUTTON = setOptionLogical(message, "Button", OPTION_BUTTON, stateNew);
            OPTION_BUMP = setOptionLogical(message, "Bump", OPTION_BUMP, stateNew);
            OPTION_DEBUG = setOptionLogical(message, "Debug", OPTION_DEBUG, stateNew);
            
            saveOptions();
            
            if (OPTION_NORMALLY_OPEN && !doorState)
            {
                open(1, 0);
            } 
            else if (!OPTION_NORMALLY_OPEN && doorState)
            {
                close();
            } 
            else
            {
                setColorsAndIcons();
            }
        }
    }
        
    timer() {
                    
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
            }
        
            // POWER_OFF means the power failure is over, so reset. 
            // Power Off -> On because restore timer
            else if (gPowerState == POWER_OFF) 
            {
                debug("timer POWER_OFF");
                llPlaySound(sound_granted,1.0);
                gPowerState = POWER_ON;
                gPowerTimer = 0;
                if (OPTION_NORMALLY_OPEN)
                {
                    open(1, 0);
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
            debug("timer gLockdownState:" + (string)gLockdownState + " gLockdownTimer:"+(string)gLockdownTimer);
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
                if (OPTION_NORMALLY_OPEN)
                {
                    open(1, 0);
                }
                else
                {
                    setColorsAndIcons();
                }
            }
        }
        
        if ( (gPowerTimer <= 0 & gLockdownTimer <= 0) | (gPowerState == POWER_ON & gLockdownState == LOCKDOWN_OFF) )
        {
            llSetTimerEvent(0);
        }
   }
    
    no_sensor()
    {
        debug("no_sensor");
        if (!OPTION_NORMALLY_OPEN | (OPTION_LOCKDOWN & (gLockdownState == LOCKDOWN_ON)))
        {
            close();
        }
        llSensorRemove();
    }
}
