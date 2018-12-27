// UniversalLight Cylinder Box Tube 2.2
// Timberwoof Lupindo
// 2018-05-11

// object name should be set to "Deck" + number or name
// description should be set to include any of these keywords: 
// ceiling=color - makes bottom surface ligt up
// marker=color - makes outside surface red. Inconpatible with Interior. 
// source=color - makes it a light emitter. Use sparingly
// hollow=color - sets color of inside surface
// interior - makes outside surface light up. Incompatible with Marker. 
// lockdown - makes inner surface and slices turn red during lockdown
// slices - makes slices turn on and off (use only if they're visible)
// The =color option is optional. Default is usualy white.

// prim characteristics
integer FACE_TOP = 0;
list FACE_OUTER = [1];
integer FACE_BOTTOM = 2;
integer FACE_BEGIN = -1;
integer FACE_END = -1;
integer FACE_INNER = -1;
vector unsliced = <0,1,0>;
float gRadius = 10.0;

// options
integer OPTION_SOURCE = 0;
integer OPTION_CEILING = 0;
integer OPTION_LOCKDOWN = 0;
integer OPTION_SLICES = 0;
integer OPTION_MARKER = 0;
integer OPTION_INTERIOR = 0;
list CONFIGURATION = [];

// lighting state
integer gTimerState;
integer RELEASE_IMMINENT = 4;
integer REGISTERING = 5;
integer gLightState;
integer OFF = 0;
integer ON = 1;
integer HALF = 2;

// colors
vector black = <0.0, 0.0, 0.0>;
vector gray = <0.5, 0.5, 0.5>;
vector white = <1.0, 1.0, 1.0>;
vector red = <1.0, 0.0, 0.0>;
vector orange = <1.0, 0.5, 0.0>;
vector yellow = <1.0, 1.0, 0.0>;
vector green = <0.0, 1.0, 0.0>;
vector blue = <0.0, 0.0, 1.0>;
vector purple = <1.0, 0.0, 1.0>;
list colors;
list color_names;
vector marker_color;
vector source_color;
vector hollow_color;
vector ceiling_color;

// sounds
string sound_lightson = "dec4e122-f527-3004-8197-8821dc9da9ef";
string sound_lockdownMessage = "2d9b82b0-84be-d6b2-22af-15d30c92ad21";

// power failure
integer POWER_CHANNEL = -8654;
integer POWER_RESET_TIME = 60;
integer SENSE_SUN_INTERVAL = 300;
integer gPowerListen; 
vector gMyRealPos;
float gDistanceCLosestPanel = 10000;
key gClosestPanel = NULL_KEY;
string gClosestPanelName;
string mystate;

// lockdown
integer LOCKDOWN_CHANNEL = -765489;
integer gLockdownListen = 0;

// light controls
fullDark() 
    {
    // for power failure
    // turn everything really off
    integer i;
    for (i = 0; i < llGetListLength(FACE_OUTER); i++)
    {
        integer face = llList2Integer(FACE_OUTER,i);
        llSetPrimitiveParams([PRIM_COLOR,face,gray,1]);
    }
        
    llSetPrimitiveParams([PRIM_POINT_LIGHT,FALSE,black,0.0,0.0,0.0]);
    llSetPrimitiveParams([PRIM_GLOW,ALL_SIDES,FALSE]);
    llSetPrimitiveParams([PRIM_FULLBRIGHT,ALL_SIDES,FALSE]);
    if (FACE_INNER != -1) 
    {
        llSetPrimitiveParams([PRIM_COLOR,FACE_INNER,gray,1]);
    }
    if (OPTION_SLICES & (FACE_BEGIN != -1) & (FACE_END != -1)) 
    {
        llSetPrimitiveParams([PRIM_COLOR,FACE_BEGIN,gray,1]);
        llSetPrimitiveParams([PRIM_COLOR,FACE_END,gray,1]);
    }
    if (OPTION_CEILING) 
    {
        llSetPrimitiveParams([PRIM_COLOR,FACE_BOTTOM,gray,1]);
    }
    if (OPTION_INTERIOR)
    {
        llSetPrimitiveParams([PRIM_COLOR,llList2Integer(FACE_OUTER,0),gray,1]);
    }
}

setLights(integer on) 
    {
    if (OPTION_MARKER)
    {
        integer i;
        for (i = 0; i < llGetListLength(FACE_OUTER); i++)
        {
            integer face = llList2Integer(FACE_OUTER,i);
            llSetPrimitiveParams([PRIM_COLOR,face,marker_color,1]);
            llSetPrimitiveParams([PRIM_FULLBRIGHT,face,on]);
            llSetPrimitiveParams([PRIM_GLOW,face,0.1]);
        }
    }
    
    if (gTimerState == RELEASE_IMMINENT) 
    {
        lockDown();
        return;
    }

    if (on) 
    {
        llPlaySound(sound_lightson,1);
    }

    // inside face lights
    if (FACE_INNER != -1) 
    {
        llSetPrimitiveParams([PRIM_COLOR,FACE_INNER,hollow_color,1]);
        llSetPrimitiveParams([PRIM_FULLBRIGHT,FACE_INNER,on]);
        llSetPrimitiveParams([PRIM_GLOW,FACE_INNER,on * 0.1]);
    }
    
    if (OPTION_INTERIOR)
    {
        llSetPrimitiveParams([PRIM_COLOR,llList2Integer(FACE_OUTER,0),white,1]);
        llSetPrimitiveParams([PRIM_FULLBRIGHT,llList2Integer(FACE_OUTER,0),on]);
        llSetPrimitiveParams([PRIM_GLOW,llList2Integer(FACE_OUTER,0),on * 0.1]);
    }
    
    // TODO: finish making OPTION_INTERIOR make the outside of the cylinder act like an inside light. 
    
    
    // slices face lights
    if (OPTION_SLICES & (FACE_BEGIN != -1) & (FACE_END != -1)) 
    {
        llSetPrimitiveParams([PRIM_COLOR,FACE_BEGIN,white,1]);
        llSetPrimitiveParams([PRIM_FULLBRIGHT,FACE_BEGIN,on]);
        llSetPrimitiveParams([PRIM_GLOW,FACE_BEGIN,on * 0.1]);
        llSetPrimitiveParams([PRIM_COLOR,FACE_END,white,1]);
        llSetPrimitiveParams([PRIM_FULLBRIGHT,FACE_END,on]);
        llSetPrimitiveParams([PRIM_GLOW,FACE_END,on * 0.1]);
    }
    
    // ceiling lights
    if (OPTION_CEILING) 
    {
        llSetPrimitiveParams([PRIM_COLOR,FACE_BOTTOM,ceiling_color,1]);
        llSetPrimitiveParams([PRIM_FULLBRIGHT,FACE_BOTTOM,on]);
        llSetPrimitiveParams([PRIM_GLOW,FACE_BOTTOM,on * 0.05]);
    }
    
    // light source
    if (OPTION_SOURCE) 
    {
        llSetPrimitiveParams([PRIM_POINT_LIGHT,on,source_color,1,gRadius,0.75]);   
    }
    
    gLightState = on;    
}

lockDown() 
{
    llPlaySound(sound_lockdownMessage,1);
    // inside face lights
    if (FACE_INNER != -1) {
        llSetPrimitiveParams([PRIM_COLOR,FACE_INNER,red,1]);
        llSetPrimitiveParams([PRIM_FULLBRIGHT,FACE_INNER,TRUE]);
        llSetPrimitiveParams([PRIM_GLOW,FACE_INNER,0.1]);
    }
    
    // slices face lights
    if (OPTION_SLICES & (FACE_BEGIN != -1) & (FACE_END != -1)) {
        llSetPrimitiveParams([PRIM_COLOR,FACE_BEGIN,red,1]);
        llSetPrimitiveParams([PRIM_FULLBRIGHT,FACE_BEGIN,TRUE]);
        llSetPrimitiveParams([PRIM_GLOW,FACE_BEGIN,0.1]);
        llSetPrimitiveParams([PRIM_COLOR,FACE_END,red,1]);
        llSetPrimitiveParams([PRIM_FULLBRIGHT,FACE_END,TRUE]);
        llSetPrimitiveParams([PRIM_GLOW,FACE_END,0.1]);
    }
    
    // light source turns red
    if (OPTION_SOURCE) {
        llSetPrimitiveParams([PRIM_POINT_LIGHT,TRUE,red,1.0,gRadius,0.75]);   
    }
    
}


report_status(key whom)
{
    string status = "Configuration: "+(string)CONFIGURATION;
    status = status + "  Position: "+(string)gMyRealPos;
    status = status + "  Closest Panel: "+gClosestPanelName;
    status = status + "  State: "+mystate+ " " + (string)gLightState;

    llInstantMessage(whom, status);
}

vector colorNameToValue(string colorname, vector default_color)
{
    vector result = default_color;
    integer index = llListFindList(color_names, [colorname]);
    if (index > 0)
    {
        result = llList2Vector(colors,index);
    }
    return result;
}

vector getOptionColor(string optionstring, string option, vector default_color)
{
    optionstring = optionstring + " ";
    integer iOption = llSubStringIndex(optionstring, option);
    integer iEquals = iOption + llStringLength(option);
    string sEquals = llGetSubString(optionstring, iEquals, iEquals);
    if (sEquals == "=")
    {
        string sRest = llGetSubString(optionstring, iEquals,-1);
        integer iSpace = llSubStringIndex(sRest, " ")-1;
        string color = llGetSubString(sRest, 1, iSpace);
        return colorNameToValue(color, default_color);
    }
    else
    {
        return default_color;
    }
}



default
{
    state_entry()
    {
        // Get  the prim's basic characteristics: 
        // has it got a hollow and a slice? 
        // Then set the list of faces that we're interested in lighting. 
        list params = llGetPrimitiveParams([PRIM_TYPE]);
        vector cut = llList2Vector(params, 2);
        float hollow = llList2Float(params, 3);
        vector holesize = <0,0,0>;
        integer primType = llList2Integer(params,0);
        
        colors = [black, gray, white, red, orange, yellow, green, blue, purple];
        color_names = ["black", "gray", "white", "red", "orange", "yellow", "green", "blue", "purple"];
        marker_color = red;
        source_color = white;
        hollow_color = white;
        ceiling_color = white;
        
        if (primType == PRIM_TYPE_CYLINDER) 
        {
            CONFIGURATION = CONFIGURATION + ["Cylinder"];
            if (hollow == 0.0) {
                if (cut == unsliced) 
                {
                    FACE_TOP = 0;
                    FACE_OUTER = [1];
                    FACE_BOTTOM = 2;
                    FACE_BEGIN = -1;
                    FACE_END = -1;
                    FACE_INNER = -1;
                } else {
                    CONFIGURATION = CONFIGURATION + ["Sliced"];
                    FACE_TOP = 0;
                    FACE_OUTER = [1];
                    FACE_BOTTOM = 2;
                    FACE_BEGIN = 3;
                    FACE_END = 4;
                    FACE_INNER = -1;
                }
            } 
            else 
            {
                CONFIGURATION = CONFIGURATION + ["Hollow"];
                if (cut == unsliced) 
                {
                    FACE_TOP = 0;
                    FACE_OUTER = [1];
                    FACE_INNER = 2;
                    FACE_BOTTOM = 3;
                    FACE_BEGIN = -1;
                    FACE_END = -1;
                } else {
                    CONFIGURATION = CONFIGURATION + ["Sliced"];
                    FACE_TOP = 0;
                    FACE_OUTER = [1];
                    FACE_INNER = 2;
                    FACE_BOTTOM = 3;
                    FACE_BEGIN = 4;
                    FACE_END = 5;
                }
            }
        } 
        else if (primType == PRIM_TYPE_BOX) 
        {
            CONFIGURATION = CONFIGURATION + ["Box"];
            if (hollow == 0.0) 
            {
                FACE_TOP = 0;
                FACE_OUTER = [1,2,3,4];
                FACE_INNER = -1;
                FACE_BOTTOM = 5;
                FACE_BEGIN = -1;
                FACE_END = -1;
            } else {
                CONFIGURATION = CONFIGURATION + ["Hollow"];
                FACE_TOP = 0;
                FACE_OUTER = [1,2,3,4];
                FACE_INNER = 5;
                FACE_BOTTOM = 6;
                FACE_BEGIN = -1;
                FACE_END = -1;
            } 
        } 
        else if (primType == PRIM_TYPE_TUBE) 
        {    
            CONFIGURATION = CONFIGURATION + ["Tube"];
            if (cut == unsliced) 
            {
                FACE_TOP = 1;
                FACE_OUTER = [0]; 
                FACE_INNER = 2;
                FACE_BOTTOM = 3;
                FACE_BEGIN = -1;
                FACE_END = -1;
            } 
            else // sliced
            {
                CONFIGURATION = CONFIGURATION + ["Sliced"];
                FACE_TOP = 4;
                FACE_OUTER = [1]; 
                FACE_INNER = 3;
                FACE_BOTTOM = 2;
                FACE_BEGIN = 0;
                FACE_END = 5;
            } 
            holesize = llList2Vector(params,  5);
        }
         
        
        // Set up light options:
        // source, ceiling, lockdown, switch, slices, marker, interior
        string optionstring = llGetObjectDesc();
        if (llSubStringIndex(optionstring,"source") > -1) 
        {
            OPTION_SOURCE = 1;
            CONFIGURATION = CONFIGURATION + ["source"];
            source_color = getOptionColor(optionstring, "source", source_color);
        }
        
        if (llSubStringIndex(optionstring,"ceiling") > -1) 
        {
            OPTION_CEILING = 1;
            CONFIGURATION = CONFIGURATION + "ceiling";
            ceiling_color = getOptionColor(optionstring, "ceiling", ceiling_color);
        }
        
        if (llSubStringIndex(optionstring,"lockdown") > -1) 
        {
            OPTION_LOCKDOWN = 1;
            CONFIGURATION = CONFIGURATION + "lockdown ";
        }
        
        if (llSubStringIndex(optionstring,"slices") > -1) 
        {
            OPTION_SLICES = 1;
            CONFIGURATION = CONFIGURATION + "slices ";
        }
        
        if (llSubStringIndex(optionstring,"marker") > -1) 
        {
            OPTION_MARKER = 1;
            CONFIGURATION = CONFIGURATION + "marker";
            marker_color = getOptionColor(optionstring, "marker", marker_color);
        }
        
        if (llSubStringIndex(optionstring,"interior") > -1) 
        {
            OPTION_INTERIOR = 1;
            CONFIGURATION = CONFIGURATION + "interior ";
        }
        
        if (llSubStringIndex(optionstring,"hollow") > -1) 
        {
            hollow_color = getOptionColor(optionstring, "hollow", hollow_color);
        }
        
        vector scale = llGetScale();
        
        // calculate "center" based on slice and hollow
        float gRadius = 0;
        float radius = 0;
        float theta = 0;
        rotation centerRot = ZERO_ROTATION;
        vector myOffset;
        gMyRealPos = llGetPos();
        if (cut == unsliced)
        {
            theta = 0;
        }
        else
            {
                // use vector cut to determine angle
                // ignore uneven x and y size
                theta = (cut.x + cut.y) * PI;
            if (primType == PRIM_TYPE_CYLINDER)
            {
                centerRot = llEuler2Rot(<0.0, 0.0, theta>);
                gRadius = (scale.x + scale.y) / 4.0;
                radius = gRadius * (hollow + 1.0) / 2.0;
                myOffset = <radius, 0.0, 0.0> * centerRot;
            }
            if (primType == PRIM_TYPE_BOX)
            {
                centerRot = llEuler2Rot(<0.0, 0.0, theta-PI*0.75>);
                gRadius = (scale.x + scale.y) / 4.0;
                radius = gRadius * (hollow + 1.0) / 2.0;
                myOffset = <radius, 0.0, 0.0> * centerRot;
            }
            if (primType == PRIM_TYPE_TUBE) 
            {
                llSay(0,"holesize:"+(string)holesize);
                centerRot = llEuler2Rot(<theta-PI*0.5, 0.0, 0.0>);
                gRadius = (scale.y + scale.z) / 4.0;
                radius = gRadius * (1.0 - holesize.y); 
                myOffset = <0.0, 0.0, radius> * centerRot;
            }
        
            gMyRealPos = llGetPos() + (myOffset * llGetRot());
        }
                
        // set up power failure listen
        gClosestPanel = NULL_KEY;
        gPowerListen = llListen(POWER_CHANNEL,"","","");
        gTimerState = REGISTERING;
        llRegionSay(POWER_CHANNEL,"request");
        llSetTimerEvent(10);
        
        // set up lockdown listen
        if (OPTION_LOCKDOWN) 
        {
            gLockdownListen = llListen(LOCKDOWN_CHANNEL,"","","");
        }
        
        // initial power-up
        fullDark();
        setLights(ON); 
    }
    
    listen(integer channel, string name, key id, string message) 
    {
        if (channel == POWER_CHANNEL)
        {
            list parts = llCSV2List(message);
            string command = llList2String(parts,0);
            if (command == "response")
            {
                list results = llGetObjectDetails(id,[OBJECT_POS]);
                vector where = llList2Vector(results,0);
                float distance = llVecDist(gMyRealPos, where);
        
                if (distance <= gDistanceCLosestPanel)
                {
                    gDistanceCLosestPanel = distance;
                    gClosestPanel = id;
                    gClosestPanelName = name;
                }
            }
                
            else if (gClosestPanel == id)
            {
                if ((command == "stable") & (command != mystate))
                {
                    setLights(ON);
                }
                if (command == "unstable")
                {
                    setLights(OFF);
                    llSleep(10);
                    setLights(ON);
                    llSleep(10);
                    setLights(OFF);
                    llSleep(10);
                    setLights(ON);
                }
                if (command == "failing")
                {
                    setLights(OFF);
                }
                if (command == "failed")
                {
                    fullDark();
                }
                mystate = command;
            }
        }
        if (channel == LOCKDOWN_CHANNEL) 
        {
            if (message == "RELEASE") 
            {
                gTimerState = ON;
                setLights(ON);
            }
            else if (message == "LOCKDOWN") 
            {
                gTimerState = RELEASE_IMMINENT;
                lockDown();
            }
        }
    } // listen
    
    touch_start(integer num_detected)
    {
        if (llSameGroup(llDetectedKey(0)))
        {
            report_status(llDetectedKey(0));
        }
    }
    
    timer() 
    {
        llListenRemove(gPowerListen);
        gPowerListen = llListen(POWER_CHANNEL,"",gClosestPanel,"");
        llSetTimerEvent(0);
    }
}
