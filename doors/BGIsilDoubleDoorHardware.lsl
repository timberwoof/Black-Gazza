// BG [Isil] Double Door Script
// Replacement script for these doors at Black Gazza
// Timberwoof Lupindo
// May 20, 2018 - May 29, 2018
// 2.2 adds versatile timer; version number matches Luna
// 3.0 separates logic and presentation

// ========================================
// custom

// faces - custom for Isil
integer FACE_PANEL_1 = 1;
integer FACE_PANEL_2 = 2;
integer FACE_FRAME1 = 0;
integer FACE_FRAME2 = 1;

// prims - custom for Isil
integer primDoor1 = 4;
integer primDoor2 = 3;
integer primPanel = 2;

// Physical Sizes - custom grebe
float leafXscale = 0.5; // thickness of leaf compared to main prim
float leafYscale = 0.5; // width of leav compared to main prim
float leafZscale = 1.0; // height of leav compared to main prim

float fZoffset = -0.4014; // isil leaves are lower than the door frame
float gSensorRadius = 2.0;

// ========================================
// Common

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

// Door States
integer doorState; // 1 = door is open
integer OPEN = 1;
integer CLOSED = 0;
integer QUIETLY = 0;
integer NOISILY = 1;

// power states
integer gPowerState = 0;
integer POWER_ON = 0;
integer POWER_OFF = 1;
integer POWER_FAILING = 2;

// lockdown
integer gLockdownState = 0; // not locked down
integer LOCKDOWN_OFF = 0;
integer LOCKDOWN_IMMINENT = 1;
integer LOCKDOWN_ON = 2;
integer LOCKDOWN_TEMP = 3; // for normally-open door closed fair-game release

// options
integer OPTION_DEBUG = 1;
vector OUTLINE_COLOR = <0,0,0>;
vector FRAME_COLOR = <1,1,1>;
integer OPTION_NORMALLY_OPEN;
integer OPTION_GROUP;
integer OPTION_BUTTON;
integer OPTION_BUMP; // need to know which icon to present
integer OPTION_POWER; // need to know power state

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"DOOR "+message);
    }
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

// ========================================
// custom
open()
{
    sayDebug("open()");
    if ( (CLOSED == doorState)  &  (gPowerState == POWER_ON)) 
    {
        llPlaySound(sound_slide,1.0);
        float f;
        for (f = fclose; f < fopen; f = f + fdelta) 
        {
            llSetLinkPrimitiveParamsFast(primDoor1,[PRIM_POS_LOCAL, <0.0, -f, fZoffset> ]);
            llSetLinkPrimitiveParamsFast(primDoor2,[PRIM_POS_LOCAL, <0.0, f, fZoffset>]);
        }
        llSetLinkPrimitiveParamsFast(primDoor1,[PRIM_POS_LOCAL, <0.0, -fopen, fZoffset> ]);
        llSetLinkPrimitiveParamsFast(primDoor2,[PRIM_POS_LOCAL, <0.0, fopen, fZoffset>]);
        doorState = OPEN;
        sendJSONinteger("doorState", doorState, "");
    }
    setColorsAndIcons();
}

close()
{
    sayDebug("close");
    if (OPEN == doorState) 
    {
        llPlaySound(sound_slide,1.0);
        float f;
        for (f = fopen; f >= fclose; f = f - fdelta) 
        {
            llSetLinkPrimitiveParamsFast(primDoor1,[PRIM_POS_LOCAL, <0.0, -f, fZoffset>]);//-f
            llSetLinkPrimitiveParamsFast(primDoor2,[PRIM_POS_LOCAL, <0.0, f, fZoffset>]);//f
        }
        llSetLinkPrimitiveParamsFast(primDoor1,[PRIM_POS_LOCAL, <0.0, -fclose, fZoffset> ]);//
        llSetLinkPrimitiveParamsFast(primDoor2,[PRIM_POS_LOCAL, <0.0, fclose, fZoffset>]);//f
        doorState = CLOSED;
        sendJSONinteger("doorState", doorState, "");
    }
    setColorsAndIcons();
}

setColorsAndIcons()
// Isil door has only one panel to show state.
// Each door leaf has its own panel 
// so there are always two linked color or texture calls.
{
    sayDebug("setColorsAndIcons gPowerState:"+(string)gPowerState+" gLockdownState:"+(string)gLockdownState+" doorState:"+(string)doorState);
    if (gPowerState == POWER_OFF)
    {
        sayDebug("setColorsAndIcons gPowerState POWER_OFF");
        llSetLinkColor(primPanel, BLACK, FACE_PANEL_1);
        llSetLinkColor(primPanel, BLACK, FACE_PANEL_2);
        return;
    }

    if (gPowerState == POWER_FAILING)
    {
        sayDebug("setColorsAndIcons gPowerState POWER_FAILING");
        llSetLinkColor(primPanel, BLUE, FACE_PANEL_1);
        llSetLinkColor(primPanel, BLUE, FACE_PANEL_2);
        return;
    }

    if (gLockdownState == LOCKDOWN_IMMINENT)
    {
        sayDebug("setColorsAndIcons gLockdownState LOCKDOWN_IMMINENT");
        llSetLinkColor(primPanel, REDORANGE, FACE_PANEL_1);
        llSetLinkColor(primPanel, REDORANGE, FACE_PANEL_2);
        return;
    }

    if (gLockdownState == LOCKDOWN_ON)
    {
        sayDebug("setColorsAndIcons gLockdownState LOCKDOWN_ON");
        llSetLinkColor(primPanel, RED, FACE_PANEL_1);
        llSetLinkColor(primPanel, RED, FACE_PANEL_2);
        llSetLinkTexture(primPanel, texture_padlock, FACE_PANEL_1);
        llSetLinkTexture(primPanel, texture_padlock, FACE_PANEL_2);
        return;
    }
    
    if (OPEN == doorState) 
    {
        sayDebug("setColorsAndIcons doorState OPEN");
        llSetLinkColor(primPanel, WHITE, FACE_PANEL_1);
        llSetLinkColor(primPanel, WHITE, FACE_PANEL_2);
        llSetLinkTexture(primPanel, texture_edgeStripes, FACE_PANEL_1);
        llSetLinkTexture(primPanel, texture_edgeStripes, FACE_PANEL_2);
    }
    else // (CLOSED == doorState)
    {
        if (OPTION_NORMALLY_OPEN) // temporarily closed
        {
            sayDebug("setColorsAndIcons CLOSED OPTION_NORMALLY_OPEN");
            llSetLinkColor(primPanel, WHITE, FACE_PANEL_1);
            llSetLinkColor(primPanel, WHITE, FACE_PANEL_2);
            llSetLinkTexture(primPanel, texture_padlock, FACE_PANEL_1);
            llSetLinkTexture(primPanel, texture_padlock, FACE_PANEL_2);
        }
        else // (!OPTION_NORMALLY_OPEN)
        {
            sayDebug("setColorsAndIcons CLOSED !OPTION_NORMALLY_OPEN");
            //llSetLinkColor(primPanel, LABEL_COLOR, FACE_PANEL_1);
            //llSetLinkColor(primPanel, LABEL_COLOR, FACE_PANEL_2);
            if(OPTION_BUTTON)
            {
                if (OPTION_BUMP)
                {
                    llSetLinkTexture(primPanel, texture_bump_to_open, FACE_PANEL_1);
                    llSetLinkTexture(primPanel, texture_bump_to_open, FACE_PANEL_2);
                }
                else
                {
                    llSetLinkTexture(primPanel, texture_press_to_open, FACE_PANEL_1);
                    llSetLinkTexture(primPanel, texture_press_to_open, FACE_PANEL_2);
                }
            }
            else
            {
                if (OPTION_BUMP)
                {
                    llSetLinkTexture(primPanel, texture_bump_to_open, FACE_PANEL_1);
                    llSetLinkTexture(primPanel, texture_bump_to_open, FACE_PANEL_2);
                }
                else
                {
                    llSetLinkTexture(primPanel, texture_padlock, FACE_PANEL_1);
                    llSetLinkTexture(primPanel, texture_padlock, FACE_PANEL_2);
                }
            }
        } 
    }
}


setPanelColor(vector Color) {}


default
{
    state_entry()
    {
        sayDebug("state_entry");
        gPowerState = POWER_OFF;
        
        // Isil panel texture needs special texture scale and offset
        llSetLinkColor(primPanel, WHITE, FACE_PANEL_1);
        llSetLinkColor(primPanel, WHITE, FACE_PANEL_2);
        llSetLinkPrimitiveParams(primPanel, [PRIM_TEXTURE, FACE_PANEL_1, texture_padlock, <1.0, 1.0, 0>, <0.0, 0.0, 0>, 0.0]);
        llSetLinkPrimitiveParams(primPanel, [PRIM_TEXTURE, FACE_PANEL_2, texture_padlock, <1.0, 1.0, 0>, <0.0, 0.0, 0>, 0.0]);
        llSetLinkPrimitiveParams(primPanel, [PRIM_GLOW, FACE_PANEL_1, 0.1]);
        llSetLinkPrimitiveParams(primPanel, [PRIM_GLOW, FACE_PANEL_2, 0.1]);
        
        setColorsAndIcons();
        
        // get  the size of the door frame and calculate the sizes of the leaves
        vector myscale = llGetScale( );
        vector leafsize;
        
        // calculate the leaf movements - Isil
        // two sliding leaves
        leafsize = <myscale.x*leafXscale, myscale.y*leafYscale, myscale.z*leafZscale>; 
        // special case for double door
        fwidth = myscale.y;
        fclose = .5312;//fwidth * something;
        fopen = 1.5906;//fwidth * something;
        fdelta = .10;
        fZoffset = -0.4014;//fheight * something;
        
        // set the initial leaf sizes
        //llSetLinkPrimitiveParamsFast(primDoor2,[PRIM_SIZE,leafsize]);
        //llSetLinkPrimitiveParamsFast(primDoor1,[PRIM_SIZE,leafsize]);
        // set the initial leaf positions
        llSetLinkPrimitiveParamsFast(primDoor1,[PRIM_POS_LOCAL, <0.0, -fclose, 0.0>]);
        llSetLinkPrimitiveParamsFast(primDoor2,[PRIM_POS_LOCAL, <0.0,  fclose, 0.0>]);

        gPowerState = POWER_ON;
        
        if (OPTION_NORMALLY_OPEN) {
            open();
        }
        else
        {
            close();
        }
        
        setColorsAndIcons();
        llPlaySound(sound_granted,1);
        sayDebug("initialized");
    }

    touch_start(integer total_number)
    {
        sayDebug("touch_start face "+(string)llDetectedTouchFace(0));
        setPanelColor(BLUE);
        llResetTime();
    }
    
    touch_end(integer num_detected)
    {
        sayDebug("touch_end num_detected "+(string)num_detected);
        if (llDetectedTouchFace(0) == FACE_PANEL_1 | llDetectedTouchFace(0) == FACE_PANEL_2)
        {
            if (llGetTime() >= 2.0)
            {
                sendJSON("command", "admin", llDetectedKey(0));
            }
            else if (OPTION_BUTTON)
            {
                sendJSON("command", "button", llDetectedKey(0));
            }
            else {
                setPanelColor(WHITE);
            }
        }
    }
    
    collision_start(integer total_number)
    {
        sayDebug("collision_start");
        if (OPTION_BUMP) 
        {
             sendJSON("command", "bump", llDetectedKey(0));
        }
    }
    
    link_message(integer sender_num, integer num, string json, key avatarKey){ 
        // We listen in on link status messages and pick the ones we're interested in
        sayDebug("link_message json "+json);
        
        OPTION_DEBUG = getJSONinteger(json, "OPTION_DEBUG", OPTION_DEBUG);
        OPTION_GROUP = getJSONinteger(json, "OPTION_GROUP", OPTION_GROUP);
        OPTION_NORMALLY_OPEN = getJSONinteger(json, "OPTION_NORMALLY_OPEN", OPTION_NORMALLY_OPEN);
        OPTION_BUMP = getJSONinteger(json, "OPTION_BUMP", OPTION_BUMP);
        OPTION_BUTTON = getJSONinteger(json, "OPTION_BUTTON", OPTION_BUTTON);
        FRAME_COLOR = (vector)getJSONstring(json, "FRAME_COLOR", (string)FRAME_COLOR);
        
        string command = "";
        command = getJSONstring(json, "command", command);
        if (command == "close") {
            close();
        } else if (command == "open") {
            open();
        } else if (command == "setColorsAndIcons") {
            setColorsAndIcons();
        }
        
    }
    
}
