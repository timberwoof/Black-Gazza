// Main Prim Link 1
integer FACE_DOORFRAME = 0; // surrounds door opening; yellow striped
integer FACE_FRAME1 = 1; // front frame
integer FACE_FRAME2 = 2; // back frame
integer FACE_PANEL1 = 3; // front weird octagon panel
integer FACE_PANEL2 = 4; // back weird octagon panel
integer FACE_DOORFRAME_BOTTOM = 5; // door opening bottom floor
integer FACE_DOORFRAME_TOP = 6; // door opening top surface
integer FACE_WINDOW = 7; // inside and outside
// Door Prim Link 2
integer FACE_DOOR_FRAME = 0;
integer FACE_DOOR_CENTER = 1; 
integer FACE_DOOR_WINDOW_TOP1 = 2;
integer FACE_DOOR_WINDOW_TOP2 = 3;
integer FACE_DOOR_WINDOW_BOTTOM1 = 4;
integer FACE_DOOR_WINDOW_BOTTOM2 = 5;
integer FACE_DOOR_PANEL1 = 3;
integer FACE_DOOR_PANEL2 = 3;
// prims
integer primDoor = 3;
integer CellBox = 2;

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
string TEXTURE_CELL_CLEAR = "4475e9cc-ef4f-7dd8-7f19-7d97abcc7a3c" ; 
string TEXTURE_CELL_SOLID = "bf2a3d3b-482c-20b9-8e48-7f0dba51ee21" ; 

//Options
integer OPTION_NORMALLY_OPEN = 0;
integer OPTION_BUTTON = 0;
integer OPTION_BUMP = 0;
integer OPTION_DEBUG = 0;
vector LABEL_COLOR = <1,1,1>;
vector FRAME_COLOR = <1,1,1>;

//Door
integer OPEN = 1;

//Power
integer POWER_OFF = 0;
integer POWER_ON = 1;
integer POWER_FAILING = 2;

//Lockdown
integer LOCKDOWN_OFF = 0;
integer LOCKDOWN_IMMINENT = 1;
integer LOCKDOWN_ON = 2;
integer LOCKDOWN_TEMP = 3; // for normally-open door closed fair-game release

debug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Appearance - "+message);
    }
}

vector getVectorParameter(string optionstring, string label, vector defaultValue)
{
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

getParameters()
{
    string optionstring = llGetObjectDesc();
    debug("getParameters("+ optionstring +")");
    OPTION_DEBUG = 0;
    OPTION_NORMALLY_OPEN = 0;
    OPTION_BUTTON = 0;
    OPTION_BUMP = 0;
    
    if (llSubStringIndex(optionstring,"debug") > -1) OPTION_DEBUG = 1;
    if (llSubStringIndex(optionstring,"normally-open") > -1) OPTION_NORMALLY_OPEN = 1;
    if (llSubStringIndex(optionstring,"button") > -1) OPTION_BUTTON = 1;
    if (llSubStringIndex(optionstring,"bump") > -1) OPTION_BUMP = 1;

    LABEL_COLOR = getVectorParameter(optionstring, "label", LABEL_COLOR);
    llSetColor(LABEL_COLOR, FACE_PANEL1);
    llSetColor(LABEL_COLOR, FACE_PANEL2);
    llSetLinkColor(primDoor, LABEL_COLOR, FACE_DOORFRAME);
    
    FRAME_COLOR = getVectorParameter(optionstring, "frame", FRAME_COLOR);
    llSetColor(FRAME_COLOR, FACE_FRAME1);
    llSetColor(FRAME_COLOR, FACE_FRAME2);
    
    debug("getParameters end");
}

// Colors ****************
setColorsAndIcons(integer gPowerState, integer gLockdownState, integer doorState, integer gDoorTimerRunning, integer gDoorClockRunning, string reservationState )
// COL door has only one panel to show state.
// Each door leaf has its own panel 
// so there are always two linked color or texture calls.
{
    debug("setColorsAndIcons gPowerState:"+(string)gPowerState+" gLockdownState:"+(string)gLockdownState+" doorState:"+(string)doorState);

    if (gPowerState == POWER_OFF)
    {
        debug("setColorsAndIcons gPowerState POWER_OFF");
        llSetLinkColor(primDoor, BLACK, FACE_DOOR_CENTER);
        return;
    }

    if (gPowerState == POWER_FAILING)
    {
        debug("setColorsAndIcons gPowerState POWER_FAILING");
        llSetLinkColor(primDoor, BLUE, FACE_DOOR_CENTER);
        return;
    }

    if (gLockdownState == LOCKDOWN_IMMINENT)
    {
        debug("setColorsAndIcons gLockdownState LOCKDOWN_IMMINENT");
        llSetLinkColor(primDoor, YELLOW, FACE_DOOR_CENTER);
        return;
    }

    if (gLockdownState == LOCKDOWN_ON | gDoorTimerRunning | gDoorClockRunning)
    {
        debug("setColorsAndIcons gLockdownState LOCKDOWN_ON");
        llSetLinkColor(primDoor, WHITE, FACE_DOOR_CENTER);
        llSetLinkTexture(primDoor, texture_locked, FACE_DOOR_CENTER);
        return;
    }

    vector doorFrameCOlor = WHITE;    
    if (reservationState == "FREE") doorFrameCOlor = WHITE;
    else if (reservationState == "READY") doorFrameCOlor = YELLOW;
    else if (reservationState == "HERE") doorFrameCOlor = GREEN;
    else if (reservationState == "GONE") doorFrameCOlor = RED;
    else if (reservationState == "GUEST") doorFrameCOlor = BLUE;
    llSetColor(doorFrameCOlor, FACE_DOORFRAME);
    
    if (OPEN == doorState) 
    {
        debug("setColorsAndIcons doorState OPEN");
        llSetLinkColor(primDoor, WHITE, FACE_DOOR_CENTER);
        llSetLinkTexture(primDoor, texture_lockdown, FACE_DOOR_CENTER);
    }
    else // (CLOSED == doorState)
    {
        llSetLinkColor(primDoor, WHITE, FACE_DOOR_CENTER);

        if (OPTION_NORMALLY_OPEN) // temporarily closed
        {
            debug("setColorsAndIcons CLOSED OPTION_NORMALLY_OPEN");
            llSetLinkColor(primDoor, WHITE, FACE_DOOR_CENTER);
            llSetLinkTexture(primDoor, texture_locked, FACE_DOOR_CENTER);
        }
        else // (!OPTION_NORMALLY_OPEN)
        {
            debug("setColorsAndIcons CLOSED !OPTION_NORMALLY_OPEN");
            if(OPTION_BUTTON)
            {
                if (OPTION_BUMP)
                {
                    llSetLinkTexture(primDoor, texture_bump_to_open, FACE_DOOR_CENTER);
                }
                else
                {
                    llSetLinkTexture(primDoor, texture_press_to_open, FACE_DOOR_CENTER);
                }
            }
            else
            {
                if (OPTION_BUMP)
                {
                    llSetLinkTexture(primDoor, texture_bump_to_open, FACE_DOOR_CENTER);
                }
                else
                {
                    llSetLinkTexture(primDoor, texture_locked, FACE_DOOR_CENTER);
                }
            }
        } 
    }
}

// opacity ********************************
// Cell opacity has two obvious states, opaque and transparent; cell does not need to annnouce this state.
// For this to work, the cell inventory must contain the textures. 
// This needs different sets of prims assigned to different faces.

default
{
    state_entry()
    {
        getParameters();
        debug("state_entry");
        // COL panel texture needs special texture scale and offset
        llSetLinkColor(primDoor, WHITE, FACE_DOOR_CENTER);
        llSetLinkPrimitiveParams(primDoor, [PRIM_TEXTURE, FACE_DOOR_CENTER, texture_locked, <13.5, 13.5, 0>, <0.58, 0.9, 0>, -1.0*PI_BY_TWO]);
        llSetLinkPrimitiveParams(primDoor, [PRIM_GLOW, FACE_DOOR_CENTER, 0.05]);
        llSetLinkPrimitiveParams(primDoor, [PRIM_TEXTURE, FACE_DOOR_WINDOW_TOP1, TEXTURE_CELL_CLEAR, <3, 4, 0>, <0, 0, 0>, 0]);
        llSetLinkPrimitiveParams(primDoor, [PRIM_TEXTURE, FACE_DOOR_WINDOW_TOP2, TEXTURE_CELL_CLEAR, <3, 4, 0>, <0, 0, 0>, 0]);
        llSetLinkPrimitiveParams(primDoor, [PRIM_TEXTURE, FACE_DOOR_WINDOW_BOTTOM1, TEXTURE_CELL_CLEAR, <3, 4, 0>, <0, 0, 0>, 0]);
        llSetLinkPrimitiveParams(primDoor, [PRIM_TEXTURE, FACE_DOOR_WINDOW_BOTTOM2, TEXTURE_CELL_CLEAR, <3, 4, 0>, <0, 0, 0>, 0]);
        llSetLinkPrimitiveParams(primDoor, [PRIM_TEXTURE, FACE_WINDOW, TEXTURE_CELL_CLEAR, <12, 8, 0>, <0, 0, 0>, 0]);
        
        //setColorsAndIcons();
    }
    
    link_message(integer sender_num, integer msgInteger, string msgString, key msgKey)
    {
        if (msgInteger == 2000) // setColorsandIcons
        {
            integer powerState = (integer)llJsonGetValue(msgString, ["powerState", "Value"]);
            integer lockdownState = (integer)llJsonGetValue(msgString, ["lockdownState", "Value"]);
            integer doorState = (integer)llJsonGetValue(msgString, ["doorState", "Value"]);
            integer doorTimerRunning = (integer)llJsonGetValue(msgString, ["doorTimerRunning", "Value"]);
            integer doorClockRunning = (integer)llJsonGetValue(msgString, ["doorClockRunning", "Value"]);
            string reservedState = (string)llJsonGetValue(msgString, ["reservationState", "Value"]);
            setColorsAndIcons(powerState, lockdownState, doorState, doorTimerRunning, doorClockRunning, reservedState);
        } 
        else if (msgInteger == 2010) // checkAuthorization failed
        {
            // not authotized
            llSetLinkColor(primDoor, REDORANGE, FACE_DOOR_CENTER);
            llSetLinkTexture(primDoor, texture_locked, FACE_DOOR_CENTER);
        }
        else if (msgInteger == 2011) // checkAuthorization succeeded
        {   
            // authorized
            llSetLinkColor(primDoor, GREEN, FACE_DOOR_CENTER);
            llSetLinkTexture(primDoor, texture_lockdown, FACE_DOOR_CENTER);
        }
        else if (msgInteger == 2020) // windows opaque
        {
            llSetTexture(TEXTURE_CELL_SOLID, FACE_WINDOW);
            llSetLinkTexture(primDoor, TEXTURE_CELL_SOLID, FACE_DOOR_WINDOW_TOP1);
            llSetLinkTexture(primDoor, TEXTURE_CELL_SOLID, FACE_DOOR_WINDOW_BOTTOM1);
            llSetLinkTexture(primDoor, TEXTURE_CELL_SOLID, FACE_DOOR_WINDOW_TOP2);
            llSetLinkTexture(primDoor, TEXTURE_CELL_SOLID, FACE_DOOR_WINDOW_BOTTOM2);
        }
        else if (msgInteger == 2021) // windows transparent
        {
            llSetTexture(TEXTURE_CELL_CLEAR, FACE_WINDOW);
            llSetLinkTexture(primDoor, TEXTURE_CELL_CLEAR, FACE_DOOR_WINDOW_TOP1);
            llSetLinkTexture(primDoor, TEXTURE_CELL_CLEAR, FACE_DOOR_WINDOW_BOTTOM1);
            llSetLinkTexture(primDoor, TEXTURE_CELL_CLEAR, FACE_DOOR_WINDOW_TOP2);
            llSetLinkTexture(primDoor, TEXTURE_CELL_CLEAR, FACE_DOOR_WINDOW_BOTTOM2);
        }
        else if (msgInteger == 2030) // read options
        {
            getParameters();
        }
    }
}
