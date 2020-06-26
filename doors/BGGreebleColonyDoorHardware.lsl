// BG [COL] Bulkhead Door Script
// Replacement script for "~isil~ Secure Door" at Black Gazza
// Timberwoof Lupindo
// May 20, 2018 - May 29, 2018; December 7, 2019
// June 15, 2020
// 3.0 Separates Hardware and Logic Layers


// ========================================
// custom

// faces - custom for Isil
// A side has door on left
// B side has door on right

// prims - custom for Isil
integer PRIM_DOOR = 2;
integer FACE_DOOR_PANEL = 1;
integer FACE_DOOR_WINDOW1 = 2; // A side top
integer FACE_DOOR_WINDOW2 = 3; // A side top
integer FACE_DOOR_WINDOW3 = 4; // B side bottom
integer FACE_DOOR_WINDOW4 = 5; // B side bottom

integer PRIM_FRAME = 1;
integer FACE_FRAME0 = 0; // door, big window edge
integer FACE_FRAME1 = 1; // A side frame
integer FACE_FRAME2 = 2; // A side frame
integer FACE_FRAME3 = 3; // A side small window
integer FACE_FRAME4 = 4; // B side small window
integer FACE_FRAME7 = 7; // big window

// Physical Sizes
vector LEAF_SCALE = <0.22, 0.4, 0.8>;
float CLOSE_FACTOR = -0.35;
float OPEN_FACTOR = -0.14; // plus or minus
float ZOFFSET_FACTOR = 0.0;

vector PANEL_TEXTURE_SCALE = <1.0, 1.0, 0>;
vector PANEL_TEXTURE_OFFSET = <0.0, 0.0, 0>;
float PANEL_TEXTURE_ROTATION = 0.0;//-1.0*PI_BY_TWO;

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

float fwidth;
float fopen;
float fclose;
float fdelta;
float fZoffset;

// Door States
integer doorState; // 1 = door is open
integer OPEN = 1;
integer CLOSED = 0;
integer QUIETLY = 0;
integer NOISILY = 1;

// power states
integer gPowerState = 0;
integer POWER_OFF = 0;
integer POWER_ON = 1;
integer POWER_FAILING = 2;

// lockdown
integer gLockdownState = 0; // not locked down
integer LOCKDOWN_OFF = 0;
integer LOCKDOWN_IMMINENT = 1;
integer LOCKDOWN_ON = 2;
integer LOCKDOWN_TEMP = 3; // for normally-open door closed fair-game release

// options
integer OPTION_DEBUG = 0;
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

reportStatus()
{
    llWhisper(0,"Door Hardware Status:");
    llWhisper(0,"doorState: "+(string)doorState);
    llWhisper(0,"gLockdownState: "+(string)gLockdownState);
    llWhisper(0,"gPowerState: "+(string)gPowerState);
    llWhisper(0,"group: "+(string)OPTION_GROUP);
    llWhisper(0,"normally-open: "+(string)OPTION_NORMALLY_OPEN);
    llWhisper(0,"button: "+(string)OPTION_BUTTON);
    llWhisper(0,"bump: "+(string)OPTION_BUMP);
    llWhisper(0,"debug: "+(string)OPTION_DEBUG);
    llWhisper(0,"power: "+(string)OPTION_POWER);
}

// ========================================
// custom
open()
{
    sayDebug("open()");
    if ((CLOSED == doorState) & (gPowerState == POWER_ON))
    {
        setPanelColor(GREEN);
        setPanelTexture(texture_edgeStripes);
        llPlaySound(sound_slide, 1.0);
        float f;
        for (f = fclose; f < fopen; f = f + fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR,[PRIM_POS_LOCAL, <f, 0.0, 0.0>]);//f
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR,[PRIM_POS_LOCAL, <fopen, 0.0, 0.0>]);//f
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
        setPanelColor(REDORANGE);
        setPanelTexture(texture_edgeStripes);
        llPlaySound(sound_slide,1.0);
        float f;
        for (f = fopen; f >= fclose; f = f - fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR,[PRIM_POS_LOCAL, <f, 0.0, 0.0>]);//f
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR,[PRIM_POS_LOCAL, <fclose, 0.0, 0.0>]);//f
        doorState = CLOSED;
        sendJSONinteger("doorState", doorState, "");
    } 
    setColorsAndIcons();
}

setColorsAndIcons()
{
    sayDebug("setColorsAndIcons gPowerState:"+(string)gPowerState+" gLockdownState:"+(string)gLockdownState+" doorState:"+(string)doorState);
    if (gPowerState == POWER_OFF)
    {
        sayDebug("setColorsAndIcons gPowerState POWER_OFF");
        setPanelColor(BLACK);
        return;
    }

    if (gPowerState == POWER_FAILING)
    {
        sayDebug("setColorsAndIcons gPowerState POWER_FAILING");
        setPanelColor(BLUE);
        return;
    }

    if (gLockdownState == LOCKDOWN_IMMINENT)
    {
        sayDebug("setColorsAndIcons gLockdownState LOCKDOWN_IMMINENT");
        setPanelColor(REDORANGE);
        setPanelTexture(texture_edgeStripes);
        return;
    }

    if (gLockdownState == LOCKDOWN_ON)
    {
        sayDebug("setColorsAndIcons gLockdownState LOCKDOWN_ON");
        setPanelColor(RED);
        setPanelTexture(texture_padlock);
        return;
    }
    
    if (OPEN == doorState) 
    {
        sayDebug("setColorsAndIcons doorState OPEN");
        setPanelColor(WHITE);
        setPanelTexture(texture_edgeStripes);
    }
    else // (CLOSED == doorState)
    {
        if (OPTION_NORMALLY_OPEN) // temporarily closed
        {
            sayDebug("setColorsAndIcons CLOSED OPTION_NORMALLY_OPEN");
            setPanelColor(WHITE);
            setPanelTexture(texture_padlock);
        }
        else // (!OPTION_NORMALLY_OPEN)
        {
            sayDebug("setColorsAndIcons CLOSED !OPTION_NORMALLY_OPEN");
            if(OPTION_GROUP) 
            {
                setPanelColor(ORANGE);
            }
            else
            {
                setPanelColor(WHITE);
            }
            if(OPTION_BUTTON)
            {
                if (OPTION_BUMP)
                {
                    setPanelTexture(texture_bump_to_open);
                }
                else
                {
                    setPanelTexture(texture_press_to_open);
                }
            }
            else
            {
                if (OPTION_BUMP)
                {
                    setPanelTexture(texture_bump_to_open);
                }
                else
                {
                    setPanelTexture(texture_padlock);
                }
            }
        } 
    }
}

setPanelColor(vector Color) 
{
    llSetLinkColor(PRIM_DOOR, Color, FACE_DOOR_PANEL);
}

setPanelTexture(string Texture) 
{
    llSetLinkTexture(PRIM_DOOR, Texture, FACE_DOOR_PANEL);
}

integer isDoorButton(integer link, integer face)
{
    return (link == PRIM_DOOR && face == FACE_DOOR_PANEL);
}

integer isPanelButton(integer link, integer face)
{
    return (link == PRIM_FRAME && (face == FACE_FRAME3 || face == FACE_FRAME4));
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
        gPowerState = POWER_OFF;
        
        // panel texture scale and offset
        setPanelColor(WHITE);
        llSetLinkPrimitiveParams(PRIM_DOOR, [PRIM_TEXTURE, FACE_DOOR_PANEL, texture_padlock, <13.5, 13.5, 0>, <0.58, 0.9, 0>, -1.0*PI_BY_TWO]);
        llSetLinkPrimitiveParams(PRIM_DOOR, [PRIM_GLOW, FACE_DOOR_PANEL, 0.1]);

        // calculate the leaf movements
        // get the size of the door frame and calculate the sizes of the leaves
        vector frameSize = llGetScale( );
        vector leafsize = <frameSize.x * LEAF_SCALE.x, frameSize.y * LEAF_SCALE.y, frameSize.z * LEAF_SCALE.z>; 
        fwidth = frameSize.x;
        fclose = fwidth * CLOSE_FACTOR;
        fopen = fwidth * OPEN_FACTOR;
        fdelta = .10;
        fZoffset = frameSize.z * ZOFFSET_FACTOR;
        
        // set the initial leaf sizes and positions
        llSetLinkPrimitiveParamsFast(PRIM_DOOR,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR,[PRIM_POS_LOCAL, <-fclose, 0.0, fZoffset>]);

        gPowerState = POWER_ON;
        
        if (OPTION_NORMALLY_OPEN) {
            open();
            close();
            open();
        }
        else
        {
            close();
            open();
            close();
        }
        
        sendJSON("command", "getStatus", llDetectedKey(0));
        setColorsAndIcons();
        llPlaySound(sound_granted,1);
        sayDebug("initialized");
    }

    touch_start(integer total_number)
    {
        integer link = llDetectedLinkNumber(0);
        integer face = llDetectedTouchFace(0);
        sayDebug("touch_start link:"+(string)link+" face:"+(string)llDetectedTouchFace(0));

        if (isDoorButton(link, face) || isPanelButton(link, face))
        {
            setPanelColor(BLUE);
            llResetTime();
        }
    }
    
    touch_end(integer num_detected)
    {
        integer face = llDetectedTouchFace(0);
        integer link = llDetectedLinkNumber(0);
        sayDebug("touch_end link:"+(string)link+" face:"+(string)llDetectedTouchFace(0));
        
        if (llGetTime() >= 2.0 && isDoorButton(link, face))
        {
            sendJSON("command", "admin", llDetectedKey(0));
        }
        else 
        {
            if (OPTION_BUTTON && isDoorButton(link, face))
            {
                sendJSON("command", "button", llDetectedKey(0));
            }
            else if (isPanelButton(link, face))
            {
                sendJSON("command", "admin", llDetectedKey(0));
            }
        }
        setPanelColor(WHITE);
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
        sayDebug("link_message "+json);
        OPTION_DEBUG = getJSONinteger(json, "OPTION_DEBUG", OPTION_DEBUG);
        OPTION_GROUP = getJSONinteger(json, "OPTION_GROUP", OPTION_GROUP);
        OPTION_NORMALLY_OPEN = getJSONinteger(json, "OPTION_NORMALLY_OPEN", OPTION_NORMALLY_OPEN);
        OPTION_BUMP = getJSONinteger(json, "OPTION_BUMP", OPTION_BUMP);
        OPTION_BUTTON = getJSONinteger(json, "OPTION_BUTTON", OPTION_BUTTON);
        FRAME_COLOR = (vector)getJSONstring(json, "FRAME_COLOR", (string)FRAME_COLOR);
        gLockdownState = getJSONinteger(json, "lockdownState", gLockdownState);
        gPowerState = getJSONinteger(json, "powerState", gPowerState);

        string command = "";
        command = getJSONstring(json, "command", command);
        if (command == "reset") {
            llResetScript();
        } else if (command == "close") {
            close();
        } else if (command == "open") {
            open();
        } else if (command == "setColorsAndIcons") {
            setColorsAndIcons();
        } else if (command == "reportStatus") {
            reportStatus();
        }
    }
}
