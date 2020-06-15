// BG [Greeble] Bulkhead Door Script
// Replacement script for these doors at Black Gazza
// Timberwoof Lupindo
// May 20, 2018 - May 29, 2018
// 2.3.3 separates group access for operation and admin

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

// custom for Greeble
integer FACE_FRAME0 = 0;
integer FACE_FRAME1 = 1;
integer FACE_FRAME2 = 2;

integer PRIM_PANEL_1 = 3;
integer PRIM_PANEL_2 = 2;
integer FACE_PANEL_1 = 5;
integer FACE_PANEL_2 = 5;

integer PRIM_FRAME = 1;
integer PRIM_DOOR_1 = 3;
integer PRIM_DOOR_2 = 2;

vector PANEL_TEXTURE_SCALE = <30.0, 23.0, 0>;
vector PANEL_TEXTURE_OFFSET = <0.34, 0.23, 0>;

// Physical Sizes
vector LEAF_SCALE = <0.5, 0.5, 1.0>;
float CLOSE_FACTOR = 0.2;
float OPEN_FACTOR = 0.6;
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
string texture_edgeStripes = "622233c6-10b8-0df0-720f-72d6627d5e04";
string texture_padlock = "8e3485b0-3fb0-ef68-2fcb-b88b3ee929df";
string texture_press_to_open = "f80eb0af-0ecf-06bc-c708-64397285b40b";
string texture_bump_to_open = "55a465d3-32e6-9de4-54e7-a7168bcc74d2";

// sounds
string sound_slide = "b3845015-d1d5-060b-6a63-de05d64d5444";
string sound_granted = "a4a9945e-8f73-58b8-8680-50cd460a3f46";
string sound_denied = "d679e663-bba3-9caa-08f7-878f65966194";
string sound_lockdown = "2d9b82b0-84be-d6b2-22af-15d30c92ad21";
string sound_warning = "fb0a28c3-4e7a-7554-0403-d8c3f56d1ccc";
string sound_door = "ccab0df8-8819-9840-9327-ae2791a9d2e2";
string sound_slam = "fc85aee3-2358-55aa-ba3d-d2d40f58e2bc";
string sound_latch = "e96de4ba-b21c-03e4-03f9-31b5da9b6f99";

float fwidth;
float fopen;
float fclose;
float fdelta;
float fZoffset;
float gSensorRadius = 2.0;

integer ZAP_CHANNEL = -106969;

integer menuChannel;
integer menuListen;
integer gMenuTimer = 0;

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
integer LOCKDOWN_DELAY = 120; // seconds
integer LOCKDOWN_OFF = 0;
integer LOCKDOWN_IMMINENT = 1;
integer LOCKDOWN_ON = 2;
integer LOCKDOWN_TEMP = 3; // for normally-open door closed fair-game release

// options
integer OPTION_DEBUG = 0;
integer OPTION_LOCKDOWN = 0;
integer OPTION_DELAY = 0;
integer OPTION_POWER = 0;
integer OPTION_GROUP = 0;
integer OPTION_ADMIN = 0;
integer OPTION_OWNERS = 0;
integer OPTION_ZAP = 0;
integer OPTION_NORMALLY_OPEN = 0;
integer OPTION_LABEL = 0;
integer OPTION_BUTTON = 0;
integer OPTION_BUMP = 0;
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
    if (llSubStringIndex(optionstring,"admin") > -1) OPTION_ADMIN = 1;
    if (llSubStringIndex(optionstring,"zap") > -1) OPTION_ZAP = 1;
    if (llSubStringIndex(optionstring,"normally-open") > -1) OPTION_NORMALLY_OPEN = 1;
    if (llSubStringIndex(optionstring,"button") > -1) OPTION_BUTTON = 1;
    if (llSubStringIndex(optionstring,"bump") > -1) OPTION_BUMP = 1;
    if (llSubStringIndex(optionstring,"delay") > -1) OPTION_DELAY = 1;
        
    integer outline_index = llSubStringIndex(optionstring,"outline"); 
    if (outline_index > -1)
    {
        string theRest = llGetSubString(optionstring,outline_index,-1);
        integer lbracket = llSubStringIndex(theRest,"<");
        integer rbracket = llSubStringIndex(theRest,">");
        string outline = llGetSubString(theRest,lbracket,rbracket);
        OUTLINE_COLOR = (vector)outline;
        debug("outline:"+outline);
    }
    
    integer frame_index = llSubStringIndex(optionstring,"frame"); 
    if (frame_index > -1)
    {
        string theRest = llGetSubString(optionstring,frame_index,-1);
        integer lbracket = llSubStringIndex(theRest,"<");
        integer rbracket = llSubStringIndex(theRest,">");
        string frame = llGetSubString(theRest,lbracket,rbracket);
        FRAME_COLOR = (vector)frame;
        debug("frame:"+frame);
        llSetColor(FRAME_COLOR, FACE_FRAME1);
        llSetColor(FRAME_COLOR, FACE_FRAME2);
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
    list menu = [];
    menu = menu + [menuItem("Lockdown", OPTION_LOCKDOWN)];
    menu = menu + [menuItem("Group", OPTION_GROUP)];
    menu = menu + [menuItem("Admin", OPTION_ADMIN)];
    menu = menu + [menuItem("Zap", OPTION_ZAP)];
    menu = menu + [menuItem("Open", OPTION_NORMALLY_OPEN)];
    menu = menu + [menuItem("Button", OPTION_BUTTON)];
    menu = menu + [menuItem("Bump", OPTION_BUMP)];
    menu = menu + [menuItem("Debug", OPTION_DEBUG)];
    menu = menu + [menuItem("Delay", OPTION_DELAY)];
    menu = menu + ["Reset"];
    menuChannel = (integer)llFloor(llFrand(1000+1000));
    llListenRemove(menuListen);
    menuListen = llListen(menuChannel, "", whoClicked, "");
    llDialog(whoClicked, "Maintenance", menu, menuChannel);
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

saveOptions()
{
    string options = "";
    options = options + getOption("lockdown", OPTION_LOCKDOWN);
    options = options + getOption("delay", OPTION_DELAY);
    options = options + getOption("group", OPTION_GROUP);
    options = options + getOption("admin", OPTION_ADMIN);
    options = options + getOption("zap", OPTION_ZAP);
    options = options + getOption("normally-open", OPTION_NORMALLY_OPEN);
    options = options + getOption("button", OPTION_BUTTON);
    options = options + getOption("bump", OPTION_BUMP);
    options = options + getOption("debug", OPTION_DEBUG);
    options = options + getOption("power", OPTION_POWER);
    options = options + getOptionString("frame",(string)FRAME_COLOR);
    if (OPTION_OWNERS)
    {
         options = options + "owner[" + owners + "]";
    }
    debug("saveOptions: \""+options+"\"");
    llSetObjectDesc(options);
 }
 
integer checkAdmin(key whoclicked)
{
    integer authorized = 0;
    if ((OPTION_ADMIN) && (llSameGroup(whoclicked)))
    {
        authorized = 1;
    } else {
        authorized = checkAuthorization("checkAdmin", whoclicked);
    }
    return authorized;
}

integer checkAuthorization(string calledby, key whoclicked)
// all the decisions about whether to do anything
// in response to bump or press button
{
    debug("checkAuthorization called by "+calledby);
    // assume authorization
    integer authorized = 1;
    
    // group prohibits
    if (OPTION_GROUP & (!llSameGroup(whoclicked)))
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
    if ((gLockdownState == LOCKDOWN_ON | gLockdownState == LOCKDOWN_TEMP) & (!llSameGroup(llDetectedKey(0))))
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
    else
    {
        debug ("checkAuthorization failed OWNERS check");
    }
    
    if (authorized)
    {
        debug("checkAuthorization passed checks");
        llSetLinkColor(PRIM_PANEL_1, GREEN, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, GREEN, FACE_PANEL_2);
        llSetLinkTexture(PRIM_PANEL_1, texture_edgeStripes, FACE_PANEL_1);
        llSetLinkTexture(PRIM_PANEL_2, texture_edgeStripes, FACE_PANEL_2);
    }
    else
    {
        debug("checkAuthorization failed checks");
        llSetLinkColor(PRIM_PANEL_1, RED, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, RED, FACE_PANEL_2);
        llSetLinkTexture(PRIM_PANEL_1, texture_padlock, FACE_PANEL_1);
        llSetLinkTexture(PRIM_PANEL_2, texture_padlock, FACE_PANEL_2);
        if (OPTION_ZAP) 
        {
            llSay(-106969,(string)whoclicked);
        }
    }

    debug("checkAuthorization returns "+(string)authorized);
    return authorized;
}

open(integer auth, integer override)
{
    debug("open("+(string)auth+", "+(string)override+")");
    if ( (CLOSED == doorState)  &  (((gPowerState == POWER_ON) & auth) | override) ) 
    {
        llSetLinkPrimitiveParamsFast(PRIM_FRAME, [PRIM_FULLBRIGHT, FACE_FRAME0, TRUE ]);
        llSetLinkColor(PRIM_PANEL_1, GREEN, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, GREEN, FACE_PANEL_2);
        llSetLinkTexture(PRIM_PANEL_1, texture_edgeStripes, FACE_PANEL_1);
        llSetLinkTexture(PRIM_PANEL_2, texture_edgeStripes, FACE_PANEL_2);

        llPlaySound(sound_door, 1.0);
        float f;
        for (f = fclose; f < fopen; f = f + fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <0.0, -f, fZoffset> ]);
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <0.0, f, fZoffset>]);
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <0.0, -fopen, fZoffset> ]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <0.0, fopen, fZoffset>]);
        llPlaySound(sound_latch, 1.0);
        llSetLinkPrimitiveParamsFast(PRIM_FRAME, [PRIM_FULLBRIGHT, FACE_FRAME0, FALSE]);
        doorState = OPEN;
    }

    // if normally closed or we're in lockdown,
    // start a sensor that will close the door when it's clear. 
    if (!OPTION_NORMALLY_OPEN | gLockdownState == LOCKDOWN_ON) 
    {
        debug("open setting sensor radius "+(string)gSensorRadius);
        llSensorRepeat("", "", AGENT, gSensorRadius, PI_BY_TWO, 1.0);
    } 
    
    // if normally open and lockdown-temp and auth
    if (OPTION_NORMALLY_OPEN & gLockdownState == LOCKDOWN_TEMP & auth == 1)
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
        llSetLinkPrimitiveParamsFast(PRIM_FRAME, [ PRIM_FULLBRIGHT, FACE_FRAME0, TRUE ]);
        llSetLinkColor(PRIM_PANEL_1, REDORANGE, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, REDORANGE, FACE_PANEL_2);
        llSetLinkTexture(PRIM_PANEL_1, texture_edgeStripes, FACE_PANEL_1);
        llSetLinkTexture(PRIM_PANEL_2, texture_edgeStripes, FACE_PANEL_2);

        llPlaySound(sound_door, 1.0);
        float f;
        for (f = fopen; f >= fclose; f = f - fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <0.0, -f, fZoffset>]);
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <0.0, f, fZoffset>]);
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <0.0, -fclose, fZoffset>]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <0.0, fclose, fZoffset>]);
        llPlaySound(sound_latch, 1.0);
        llSetLinkPrimitiveParamsFast(PRIM_FRAME, [ PRIM_FULLBRIGHT, FACE_FRAME0, FALSE ]);
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

setColorsAndIcons()
{
    debug("setColorsAndIcons gPowerState:"+(string)gPowerState+" gLockdownState:"+(string)gLockdownState+" doorState:"+(string)doorState);
    if (gPowerState == POWER_OFF)
    {
        debug("setColorsAndIcons gPowerState POWER_OFF");
        llSetLinkColor(PRIM_PANEL_1, BLACK, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, BLACK, FACE_PANEL_2);
        return;
    }

    if (gPowerState == POWER_FAILING)
    {
        debug("setColorsAndIcons gPowerState POWER_FAILING");
        llSetLinkColor(PRIM_PANEL_1, BLUE, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, BLUE, FACE_PANEL_2);
        return;
    }

    if (gLockdownState == LOCKDOWN_IMMINENT)
    {
        debug("setColorsAndIcons gLockdownState LOCKDOWN_IMMINENT");
        llSetLinkColor(PRIM_PANEL_1, REDORANGE, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, REDORANGE, FACE_PANEL_2);
        return;
    }

    if (gLockdownState == LOCKDOWN_ON)
    {
        debug("setColorsAndIcons gLockdownState LOCKDOWN_ON");
        llSetLinkColor(PRIM_PANEL_1, RED, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, RED, FACE_PANEL_2);
        llSetLinkTexture(PRIM_PANEL_1, texture_padlock, FACE_PANEL_1);
        llSetLinkTexture(PRIM_PANEL_2, texture_padlock, FACE_PANEL_2);
        return;
    }
    
    if (OPEN == doorState) 
    {
        debug("setColorsAndIcons doorState OPEN");
        llSetLinkColor(PRIM_PANEL_1, WHITE, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, WHITE, FACE_PANEL_2);
        llSetLinkTexture(PRIM_PANEL_1, texture_edgeStripes, FACE_PANEL_1);
        llSetLinkTexture(PRIM_PANEL_2, texture_edgeStripes, FACE_PANEL_2);
    }
    else // (CLOSED == doorState)
    {
        if (OPTION_NORMALLY_OPEN) // temporarily closed
        {
            debug("setColorsAndIcons CLOSED OPTION_NORMALLY_OPEN");
            llSetLinkColor(PRIM_PANEL_1, WHITE, FACE_PANEL_1);
            llSetLinkColor(PRIM_PANEL_2, WHITE, FACE_PANEL_2);
            llSetLinkTexture(PRIM_PANEL_1, texture_padlock, FACE_PANEL_1);
            llSetLinkTexture(PRIM_PANEL_2, texture_padlock, FACE_PANEL_2);
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
                    llSetLinkTexture(PRIM_PANEL_1, texture_bump_to_open, FACE_PANEL_1);
                    llSetLinkTexture(PRIM_PANEL_2, texture_bump_to_open, FACE_PANEL_2);
                }
                else
                {
                    llSetLinkTexture(PRIM_PANEL_1, texture_press_to_open, FACE_PANEL_1);
                    llSetLinkTexture(PRIM_PANEL_2, texture_press_to_open, FACE_PANEL_2);
                }
            }
            else
            {
                if (OPTION_BUMP)
                {
                    llSetLinkTexture(PRIM_PANEL_1, texture_bump_to_open, FACE_PANEL_1);
                    llSetLinkTexture(PRIM_PANEL_2, texture_bump_to_open, FACE_PANEL_2);
                }
                else
                {
                    llSetLinkTexture(PRIM_PANEL_1, texture_padlock, FACE_PANEL_1);
                    llSetLinkTexture(PRIM_PANEL_2, texture_padlock, FACE_PANEL_2);
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
        llSetLinkColor(PRIM_PANEL_1, BLACK, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, BLACK, FACE_PANEL_2);
        llSetLinkPrimitiveParams(PRIM_PANEL_1, [PRIM_TEXTURE, FACE_PANEL_1, texture_padlock, PANEL_TEXTURE_SCALE, PANEL_TEXTURE_OFFSET, 0.0]);
        llSetLinkPrimitiveParams(PRIM_PANEL_2, [PRIM_TEXTURE, FACE_PANEL_2, texture_padlock, PANEL_TEXTURE_SCALE, PANEL_TEXTURE_OFFSET, 0.0]);
        llSetLinkPrimitiveParams(PRIM_PANEL_1, [PRIM_GLOW, FACE_PANEL_1, 0.1]);
        llSetLinkPrimitiveParams(PRIM_PANEL_2, [PRIM_GLOW, FACE_PANEL_2, 0.1]);
        
        setColorsAndIcons();
        
        // calculate the leaf movements
        // get  the size of the door frame and calculate the sizes of the leaves
        vector frameSize = llGetScale( );
        vector leafsize = <frameSize.x * LEAF_SCALE.x, frameSize.y * LEAF_SCALE.y, frameSize.z * LEAF_SCALE.z>; 
        fwidth = frameSize.y;
        fclose = fwidth * CLOSE_FACTOR;
        fopen = fwidth * OPEN_FACTOR;
        fZoffset = frameSize.z * ZOFFSET_FACTOR;
        fdelta = llFabs(fopen - fclose) * 0.003;
        debug("fdelta:"+(string)fdelta);
        
        // set the initial leaf sizes and positions
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <0.0, -fclose, 0.0>]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <0.0,  fclose, 0.0>]);

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
        
        if (OPTION_NORMALLY_OPEN) {
            open(1,1);
        }
        else
        {
            close();
        }
        
        setColorsAndIcons();
        llPlaySound(sound_granted,1);
        debug("initialized");
    }


    touch_start(integer total_number)
    {
        debug("touch_start face "+(string)llDetectedTouchFace(0));
        llSetLinkColor(PRIM_PANEL_1, BLUE, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, BLUE, FACE_PANEL_2);
        llResetTime();
    }
    
    touch_end(integer num_detected)
    {
        debug("touch_end num_detected "+(string)num_detected);
        if (llDetectedTouchFace(0) == FACE_PANEL_1 | llDetectedTouchFace(0) == FACE_PANEL_2)
        {
            key whoclicked = llDetectedKey(0);
            if (llGetTime() >= 2.0)
            {
                if (checkAdmin(whoclicked)) {
                    maintenanceMenu(whoclicked);
                }
            }
            else if (OPTION_BUTTON)
            {
                toggleDoor(checkAuthorization("touch_end", whoclicked), 0);
            }
            else {
                llSetLinkColor(PRIM_PANEL_1, WHITE, FACE_PANEL_1);
                llSetLinkColor(PRIM_PANEL_2, WHITE, FACE_PANEL_2);
            }
        }
    }
    
    collision_start(integer total_number)
    {
        debug("collision_start");
        if (OPTION_BUMP) 
        {
            open(checkAuthorization("collision_start", llDetectedKey(0)), 0);
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
            debug("listen "+message);
            if (message == "LOCKDOWN") 
            {
                if (OPTION_DELAY == 0)
                {
                    debug("listen OPTION_DELAY == 0 -> gLockdownState = LOCKDOWN_ON");
                    llPlaySound(sound_lockdown,1);
                    gLockdownState = LOCKDOWN_ON;
                    gLockdownTimer = setTimerEvent(LOCKDOWN_RESET_TIME);
                    close(); // don't put a sensor here. It's lockdown. Get out of the way!
                }
                else
                {
                    debug("listen LOCKDOWN_DELAY != 0 -> gLockdownState = LOCKDOWN_IMMINENT");
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
            
            gMenuTimer = 0;
            llListenRemove(menuListen);
            menuChannel = 0;
            
            integer stateNew = llGetSubString(message,0,0) == "☐";
            OPTION_LOCKDOWN = setOptionLogical(message, "Lockdown", OPTION_LOCKDOWN, stateNew);
            OPTION_DELAY = setOptionLogical(message, "Delay", OPTION_DELAY, stateNew);
            OPTION_GROUP = setOptionLogical(message, "Group", OPTION_GROUP, stateNew);
            OPTION_ADMIN = setOptionLogical(message, "Admin", OPTION_ADMIN, stateNew);
            OPTION_ZAP = setOptionLogical(message, "Zap", OPTION_ZAP, stateNew);
            OPTION_NORMALLY_OPEN = setOptionLogical(message, "Open", OPTION_NORMALLY_OPEN, stateNew);
            OPTION_BUTTON = setOptionLogical(message, "Button", OPTION_BUTTON, stateNew);
            OPTION_BUMP = setOptionLogical(message, "Bump", OPTION_BUMP, stateNew);
            OPTION_DEBUG = setOptionLogical(message, "Debug", OPTION_DEBUG, stateNew);
            
            saveOptions();
            
            if (message == "Reset")
            {
                llResetScript();
            }
            
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
        
        if (gMenuTimer > 0)
        {
            gMenuTimer = gMenuTimer - TIMER_INTERVAL;
            debug("timer gMenuTimer "+(string)gMenuTimer);
            if (gMenuTimer <= 0)
            {
                llListenRemove(menuListen);
                menuListen = 0;
            }
        }
                    
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
        
        if ( (gPowerTimer <= 0 & gLockdownTimer <= 0 & gMenuTimer <= 0) )
        {
            debug("timer"+
                " gPowerTimer:"+(string)gPowerTimer+
                " gLockdownTimer:"+(string)gLockdownTimer+
                " gMenuTimer:"+(string)gMenuTimer
                );
            llSetTimerEvent(0);
            setColorsAndIcons();
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
