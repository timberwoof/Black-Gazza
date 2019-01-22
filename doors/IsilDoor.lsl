// BG [Isil] Double Door Script
// Replacement script for these doors at Black Gazza
// Timberwoof Lupindo
// May 20, 2018 - May 29, 2018
// 2.2 adds versatile timer; version number matches Luna

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
// button: makes the "open" button work
// bump: makes the door open when someone bumps into it. 

// A normally-open door set to group, when closed by a member of the group,
// will stay closed for half an hour, implementing the fair-game rule. 

// custom for Isil
integer FACE_FRAME1 = 0;
integer FACE_FRAME2 = 1;

integer PRIM_PANEL_1 = 2;
integer PRIM_PANEL_2 = 2;
integer FACE_PANEL_1 = 1;
integer FACE_PANEL_2 = 2;

integer PRIM_DOOR_1 = 4;
integer PRIM_DOOR_2 = 3;

vector PANEL_TEXTURE_SCALE = <1.0, 1.0, 0>;
vector PANEL_TEXTURE_OFFSET = <0.0, 0.0, 0>;

// Physical Sizes
// frame: <0.38743, 5.11704, 5.08728>
// leaf: <0.10476,1.06177, 3.04108>
vector LEAF_SCALE = <0.2704, 0.2075, 0.5978>;
float CLOSE_FACTOR = 0.103;
float OPEN_FACTOR = .31;
float ZOFFSET_FACTOR = -.0786275; // isil leaves are lower than the door frame

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

// sounds
string sound_slide = "b3845015-d1d5-060b-6a63-de05d64d5444";
string sound_granted = "a4a9945e-8f73-58b8-8680-50cd460a3f46";
string sound_denied = "d679e663-bba3-9caa-08f7-878f65966194";
string sound_lockdown = "2d9b82b0-84be-d6b2-22af-15d30c92ad21";

float fwidth;
float fopen;
float fclose;
float fdelta;
float fZoffset;
float gSensorRadius = 2.0;

integer ZAP_CHANNEL = -106969;

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
vector OUTLINE_COLOR = <0,0,0>;
vector FRAME_COLOR = <0,0,0>;
string owners = "";
vector LABEL_COLOR = <1,1,1>;

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
        //LABEL_COLOR = (vector)label; // Isil door hasn't got a label!
        debug("label:"+label);
        OPTION_LABEL = 0; // Isil door hasn't got a label!
    }
    
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
        llSetLinkColor(PRIM_PANEL_1, GREEN, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, GREEN, FACE_PANEL_2);
        llSetLinkTexture(PRIM_PANEL_1, texture_lockdown, FACE_PANEL_1);
        llSetLinkTexture(PRIM_PANEL_2, texture_lockdown, FACE_PANEL_2);
    }
    else
    {
        llSetLinkColor(PRIM_PANEL_1, RED, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, RED, FACE_PANEL_2);
        llSetLinkTexture(PRIM_PANEL_1, texture_locked, FACE_PANEL_1);
        llSetLinkTexture(PRIM_PANEL_2, texture_locked, FACE_PANEL_2);
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
    if ( (CLOSED == doorState)  &  (((gPowerState == POWER_ON) & (gLockdownState == LOCKDOWN_OFF) & auth) | override) ) 
    {
        llPlaySound(sound_slide, 1.0);
        float f;
        for (f = fclose; f < fopen; f = f + fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <0.0, -f, fZoffset> ]);
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <0.0, f, fZoffset>]);
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <0.0, -fopen, fZoffset> ]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <0.0, fopen, fZoffset>]);
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
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <0.0, -f, fZoffset>]);
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <0.0, f, fZoffset>]);
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <0.0, -fclose, fZoffset>]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <0.0, fclose, fZoffset>]);
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
        llSetLinkTexture(PRIM_PANEL_1, texture_locked, FACE_PANEL_1);
        llSetLinkTexture(PRIM_PANEL_2, texture_locked, FACE_PANEL_2);
        return;
    }
    
    if (OPEN == doorState) 
    {
        debug("setColorsAndIcons doorState OPEN");
        llSetLinkColor(PRIM_PANEL_1, WHITE, FACE_PANEL_1);
        llSetLinkColor(PRIM_PANEL_2, WHITE, FACE_PANEL_2);
        llSetLinkTexture(PRIM_PANEL_1, texture_lockdown, FACE_PANEL_1);
        llSetLinkTexture(PRIM_PANEL_2, texture_lockdown, FACE_PANEL_2);
    }
    else // (CLOSED == doorState)
    {
        if (OPTION_NORMALLY_OPEN) // temporarily closed
        {
            debug("setColorsAndIcons CLOSED OPTION_NORMALLY_OPEN");
            llSetLinkColor(PRIM_PANEL_1, WHITE, FACE_PANEL_1);
            llSetLinkColor(PRIM_PANEL_2, WHITE, FACE_PANEL_2);
            llSetLinkTexture(PRIM_PANEL_1, texture_locked, FACE_PANEL_1);
            llSetLinkTexture(PRIM_PANEL_2, texture_locked, FACE_PANEL_2);
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
                    llSetLinkTexture(PRIM_PANEL_1, texture_locked, FACE_PANEL_1);
                    llSetLinkTexture(PRIM_PANEL_2, texture_locked, FACE_PANEL_2);
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
        fdelta = .10;
        fZoffset = frameSize.z * ZOFFSET_FACTOR;
        
        // set the initial leaf sizes and positions
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <0.0, -fclose, 0.0>]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <0.0,  fclose, 0.0>]);

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
        if (OPTION_BUTTON & (llDetectedTouchFace(0) == FACE_PANEL_1 | llDetectedTouchFace(0) == FACE_PANEL_2))
        {
            toggleDoor(checkAuthorization(llDetectedKey(0)), 0);
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
            gPowerTimer = setTimerEvent((integer)distance+2);
        }
        
        else if (channel == LOCKDOWN_CHANNEL) 
        {
            debug("listen "+message);
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
