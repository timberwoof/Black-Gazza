// BG [NeurolaB Inc.] LUNA-2 DOOR
// Replacement script for Luna Doors: single or double, metal or glass at Black Gazza
// Timberwoof Lupindo
// January 1, 2014 - May 29, 2018
// 2.2 adds versatile timer; version number matches Greeble 
// 3.0 separates logic and presentation

// ========================================
// custom

// custom for Isil
// faces - custom for luna
integer FACE_OVERHEAD = 1; // rectangle at the top of the door
integer FACE_ACCESS_GRANTED = 2; // top square icon
integer FACE_KEYPAD = 0; // numeric keypad, middl esquare icon
integer FACE_PUSH_TO_OPEN = 4; // bottom square icon
integer FACE_OUTLINE = 3; // frame around bottom icon
integer FACE_FRAME = 5;

// prims - custom for luna
integer PRIM_PANEL_1 = 1;
integer PRIM_DOOR_1 = 5;
integer PRIM_DOOR_2 = 4;
integer PRIM_JET_1 = 2;
integer PRIM_JET_2 = 3;

// Physical Sizes
vector LEAF_SCALE = <0.94, 0.9, 0.015>;

// Extra for Nozzles
float nozzleXoffset = -0.4610;
float nozzleZoffset = 0.1601;
float nozzle2Yoffset = 0.2888;
float nozzle3Yoffset = -0.3050;

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

keypadBeep(vector hv)
{
    if (gPowerState != POWER_ON)
    {
        sayDebug("keypadBeep failed power check");
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

// Luna textures
string texture_luna_push_to_close = "f281d276-8410-7085-b7b1-f7d39ee16764";
string texture_luna_push_to_open = "19e1426e-8ebf-100a-c70d-a3b77c7117ee";
string texture_luna_access_granted = "6f635c48-e120-90db-d97c-2773992acda3";
string texture_luna_access_denied = "f58e636f-ea98-35a9-18c8-dc226b753fb5";

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
float fZoffset;

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
    if ( (CLOSED == doorState)  &  (gPowerState == POWER_ON)) 
    {
        setPanelColor(GREEN);
        setPanelTexture(texture_edgeStripes);
        particles(1); // luna door has steam puffs
        llPlaySound(sound_slide,1.0);
        float f;
        for (f = fclose; f < fopen; f = f + fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-f, 0.0, 0.0> ]);//
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <f, 0.0, 0.0>]);//f
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-fopen, 0.0, 0.0> ]);//
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <fopen, 0.0, 0.0>]);//f
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
        particles(1); // luna door has steam puffs
        llPlaySound(sound_slide,1.0);
        float f;
        for (f = fopen; f >= fclose; f = f - fdelta) 
        {
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-f, 0.0, 0.0>]);//-f
            llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <f, 0.0, 0.0>]);//f
        }
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-fclose, 0.0, 0.0> ]);//
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <fclose, 0.0, 0.0>]);//f
        doorState = CLOSED;
        sendJSONinteger("doorState", doorState, "");
    }
    setColorsAndIcons();
}

// luna door has things that puff steam
particles(integer on)
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
        llLinkParticleSystem(PRIM_JET_1, puff);
        llLinkParticleSystem(PRIM_JET_2, puff);
    }
    else
    {
        llLinkParticleSystem(PRIM_JET_1, []);
        llLinkParticleSystem(PRIM_JET_2, []);
    }
}

setColorsAndIcons()
// Luna door has more panels that reflect state.
// Frame has all the panels so they are local calls.
{
    sayDebug("setColorsAndIcons gPowerState:"+(string)gPowerState+" gLockdownState:"+(string)gLockdownState+" doorState:"+(string)doorState);
    if (gPowerState == POWER_OFF)
    {
        sayDebug("setColorsAndIcons gPowerState POWER_OFF");
        llSetColor(BLACK, FACE_OVERHEAD);
        llSetColor(BLACK, FACE_ACCESS_GRANTED);
        llSetColor(BLACK, FACE_KEYPAD);
        setPanelColor(BLACK);
        llSetColor(BLACK, FACE_OUTLINE);
        return;
    }

    if (gPowerState == POWER_FAILING)
    {
        sayDebug("setColorsAndIcons gPowerState POWER_FAILING");
        llSetColor(DARK_BLUE, FACE_OVERHEAD);
        llSetColor(DARK_BLUE, FACE_ACCESS_GRANTED);
        llSetColor(DARK_BLUE, FACE_KEYPAD);
        setPanelColor(BLUE);
        llSetColor(DARK_BLUE, FACE_OUTLINE);
        return;
    }

    if (gLockdownState == LOCKDOWN_IMMINENT)
    {
        sayDebug("setColorsAndIcons gLockdownState LOCKDOWN_IMMINENT");
        llSetColor(REDORANGE, FACE_OVERHEAD);
        llSetColor(REDORANGE, FACE_ACCESS_GRANTED);
        llSetColor(REDORANGE, FACE_KEYPAD);
        setPanelColor(REDORANGE);
        llSetColor(REDORANGE, FACE_OUTLINE);
        llSetTexture(texture_edgeStripes,FACE_PUSH_TO_OPEN);
        llSetTexture(texture_luna_access_denied, FACE_ACCESS_GRANTED);
        return;
    }

    if (gLockdownState == LOCKDOWN_ON)
    {
        sayDebug("setColorsAndIcons gLockdownState LOCKDOWN_ON");
        llSetColor(RED, FACE_OVERHEAD);
        llSetColor(RED, FACE_ACCESS_GRANTED);
        llSetColor(RED, FACE_KEYPAD);
        setPanelColor(RED);
        llSetColor(RED, FACE_OUTLINE);
        llSetTexture(texture_padlock,FACE_PUSH_TO_OPEN);
        llSetTexture(texture_luna_access_denied, FACE_ACCESS_GRANTED);
        return;
    }

    // Luna door has a big light at the top
    //llSetColor(LABEL_COLOR, FACE_OVERHEAD);
    setPanelColor(WHITE);
    if (OPTION_GROUP)
    {
        sayDebug("setColorsAndIcons OPTION_GROUP");
        llSetColor(ORANGE, FACE_OVERHEAD);
        llSetColor(ORANGE, FACE_ACCESS_GRANTED);
        llSetColor(ORANGE, FACE_KEYPAD);
        llSetColor(ORANGE, FACE_OUTLINE);
    }
    else
    {
        sayDebug("setColorsAndIcons !OPTION_GROUP");
        llSetColor(CYAN, FACE_OVERHEAD);
        llSetColor(CYAN, FACE_ACCESS_GRANTED);
        llSetColor(CYAN, FACE_KEYPAD);
        llSetColor(CYAN, FACE_OUTLINE);
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
            //llSetColor(LABEL_COLOR, FACE_ACCESS_GRANTED);
            //llSetColor(LABEL_COLOR, FACE_KEYPAD);
            //llSetColor(LABEL_COLOR, FACE_OUTLINE);
            if(OPTION_BUTTON)
            {
                if (OPTION_BUMP)
                {
                    llSetTexture(texture_luna_push_to_open,FACE_ACCESS_GRANTED);
                    setPanelTexture(texture_bump_to_open);
                }
                else
                {
                    llSetTexture(texture_luna_push_to_open,FACE_ACCESS_GRANTED);
                    setPanelTexture(texture_press_to_open);
                }
            }
            else
            {
                if (OPTION_BUMP)
                {
                    llSetTexture(texture_luna_access_granted,FACE_ACCESS_GRANTED);
                    setPanelTexture(texture_bump_to_open);
                }
                else
                {
                    llSetTexture(texture_luna_access_denied,FACE_ACCESS_GRANTED);
                    setPanelTexture(texture_padlock);
                }
            }
        }
    }
}

setPanelColor(vector Color) 
{
    llSetColor(Color, FACE_PUSH_TO_OPEN);
}

setPanelTexture(string Texture) 
{
    llSetTexture(Texture, FACE_PUSH_TO_OPEN);
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
        gPowerState = POWER_OFF;
        
        // panel texture scale and offset
        llSetLinkColor(PRIM_PANEL_1, BLACK, FACE_ACCESS_GRANTED);
        llSetLinkColor(PRIM_PANEL_1, BLACK, FACE_ACCESS_GRANTED);

        setColorsAndIcons();

        // calculate the leaf movements
        // get the size of the door frame and calculate the sizes of the leaves
        vector myscale = llGetScale( );
        vector leafsize;
        
        // calculate the leaf movements - Luna
        if (llGetNumberOfPrims() == 5) 
        {
            // two sliding leaves
            leafsize = <myscale.y*LEAF_SCALE.y, myscale.x*LEAF_SCALE.x/2.0, myscale.x*LEAF_SCALE.z>; 
            // special case for double door
            fwidth = leafsize.y;
            fclose = fwidth / 2.0;
            fopen = fwidth + fclose;
            fdelta = .20;
        }
        else
        {
            // one sliding leaf
            leafsize = <myscale.y*LEAF_SCALE.y, myscale.x*LEAF_SCALE.x, myscale.x*LEAF_SCALE.z>; 
            // x and y are reversed in the leaves
            fwidth = leafsize.y;
            fclose = 0;
            fopen = -fwidth;
            fdelta = .05;
        }
        
        // set the initial leaf sizes and positions
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_1,[PRIM_POS_LOCAL, <-fopen, 0.0, 0.0>]);//
        llSetLinkPrimitiveParamsFast(PRIM_DOOR_2,[PRIM_POS_LOCAL, <fopen, 0.0, 0.0>]);//f

        // calculate and set the nozzle locations - luna only
        llSetLinkPrimitiveParamsFast(PRIM_JET_1,[PRIM_POS_LOCAL, 
        <myscale.x*nozzleXoffset, myscale.y*nozzle2Yoffset, myscale.z*nozzleZoffset>]);
        llSetLinkPrimitiveParamsFast(PRIM_JET_2,[PRIM_POS_LOCAL, 
        <myscale.x*nozzleXoffset, myscale.y*nozzle3Yoffset, myscale.z*nozzleZoffset>]);

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
        sayDebug("touch_start face "+(string)llDetectedTouchFace(0));
        if (llDetectedTouchFace(0) == FACE_PUSH_TO_OPEN)
        {
            setPanelColor(BLUE);
            llResetTime();
        }
    }
    
    touch_end(integer num_detected)
    {
        sayDebug("touch_end num_detected "+(string)num_detected);
        if (llDetectedTouchFace(0) == FACE_PUSH_TO_OPEN)
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
