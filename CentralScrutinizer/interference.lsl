integer gACSChannel = 360;
integer gACSListen = 0;
integer gTalkChannel = 1;
list gACSInterferenceAmounts = [0,0,0,0,0,0];
list gACSInterferenceTypes = ["P","M","S","N","C","Y"];

// implement the ACS Interference Protocol as a receiver
//list gACSInterferenceAmounts = [0,0,0,0,0,0]
//string gACSInterferenceTypes = "PMSNCY";

integer ERROR = 0;
integer WARN = 1;
integer INFO = 2;
integer DEBUG = 3;
integer TRACE = 4;
integer gDebugLevel = 2;
list debugLevels=["ERROR ","WARN  ","INFO  ","DEBUG ","TRACE "];
integer gWasDebugLevel = 2;

integer havePermissions = 0;

// interference reports via logging handler
twDebug(integer debugLevel, string message)
{
    llMessageLinked(LINK_THIS, 900+debugLevel, message, ""); // (string)debugLevel+":"+
}

// interference works by setting debug level
setDebugLevel(string sDebugLevel) 
{
    llMessageLinked(LINK_THIS, 998, sDebugLevel, "");
}

setACSInterferenceAmount(string stype, integer amount)
// stype must be a single letter of PMSNCY
{
    integer itype = llListFindList(gACSInterferenceTypes,[stype]);
    gACSInterferenceAmounts = llListReplaceList(gACSInterferenceAmounts, [amount], itype, itype);
}

integer getACSInterferenceAmount(string stype)
{
    if (stype == "")
    {
        integer i;
        integer sum = 0;
        for(i = 0; i < 6; i++)
        {
            sum = sum + llList2Integer(gACSInterferenceAmounts,i);
        }
        return sum;
    }
    else
    {
        integer itype = llListFindList(gACSInterferenceTypes,[stype]);
        return llList2Integer(gACSInterferenceAmounts, itype);
    }
}

setACSInterferenceAmounts(string types, integer duration, integer strength) 
{
    twDebug(DEBUG, "setACSInterferenceAmounts: "+types+","+(string)duration+","+(string)strength);
    // P = Power interference (shuts unit down - cannot be compensated for) 
    // M = Motor interference (freezes unit) - not applicable
    // S = Speaker interference (silences unit) - prevents speaking on channel 1
    // N = Sensory interference (partially blinds unit, hides names) - requires RLV
    // C = Cognitive interference (makes it hard for unit to think; extra hard to compensate for)
    // Y = Memory interference (limits unit's memory; also hard to compensate for)
    integer l = llStringLength(types);
    if (l == 0)
    {
        types = "PMSNCY";
        l = 6;
        strength = 0;
    }
    integer i;
    for (i = 0; i < l; i++)
    {
        string type = llGetSubString(types, i, i);
        setACSInterferenceAmount(type, strength);
    }
    
    // power or sensory interference
    if ((getACSInterferenceAmount("N") > 0) | (getACSInterferenceAmount("P") > 0))
    {
        if(havePermissions == 1) 
        {
            vector cameraFocus = llGetPos();
            vector cameraPosition = llGetPos() - <.25,0,0>;
            llSetCameraParams([
                CAMERA_ACTIVE, 1, // 1 is active, 0 is inactive
                CAMERA_BEHINDNESS_ANGLE, 0.0, //(0 to 180) degrees
                CAMERA_BEHINDNESS_LAG, 0.0, //(0 to 3) seconds
                CAMERA_DISTANCE, 0.0, //(0.5 to 10) meters
                CAMERA_FOCUS, cameraFocus, // region relative position
                CAMERA_FOCUS_LAG, 0.0 , //(0 to 3) seconds
                CAMERA_FOCUS_LOCKED, TRUE, //(TRUE or FALSE)
                CAMERA_FOCUS_THRESHOLD, 0.0, //(0 to 4) meters
                //CAMERA_PITCH,0, //(-45 to 80) degrees
                CAMERA_POSITION, cameraPosition, // region relative position
                CAMERA_POSITION_LAG, 0.0, //(0 to 3) seconds
                CAMERA_POSITION_LOCKED, TRUE, //(TRUE or FALSE)
                CAMERA_POSITION_THRESHOLD, 0.0, //(0 to 4) meters
                CAMERA_FOCUS_OFFSET, ZERO_VECTOR // <-10,-10,-10> to <10,10,10> meters
            ]);
        }
    }
    
    if (getACSInterferenceAmount("P") > 0)
    {
        twDebug(INFO, "Power systems are being interfered with.");
    }
    
    if (getACSInterferenceAmount("S") > 0)
    {
        twDebug(INFO,"Speaker systems are being interfered with.");
    }
    
    if (getACSInterferenceAmount("C") > 0)
    {
        twDebug(INFO,"Cognitive systems are being interfered with.");
    }
    
    if (getACSInterferenceAmount("Y") > 0)
    {
        twDebug(INFO,"Memory systems are being interfered with.");
    }
    
    if (getACSInterferenceAmount("N") > 0)
    {
        twDebug(INFO,"Sensory systems are being interfered with.");
        gWasDebugLevel = gDebugLevel;
        setDebugLevel((string)ERROR); // only the most severe messages get through
    }
    else
    {
        setDebugLevel((string)gWasDebugLevel);
    }
    
    llMessageLinked(LINK_THIS, gACSChannel, (string)getACSInterferenceAmount(""), "");
    llSetTimerEvent(duration);
}


default
{
    state_entry()
    {
        //gACSListen = llListen(gACSChannel,"","","");
        havePermissions = 0;
    }

    link_message(integer Sender, integer Number, string message, key Key)
    {
        // filter a merssage to a terminal
        if(gTalkChannel == Number)
        {
            // ACS interference Speaker and Power
            // Power is all or nothing
            // Speaker should garble worse with higher integers. 
            integer colon = llSubStringIndex(message,":");
            integer gActiveTerminalChannel = (integer)llGetSubString(message,0,colon-1);
            string theMessage = llGetSubString(message,colon+1,-1);
            if(gActiveTerminalChannel != 0) {
                if ((getACSInterferenceAmount("S") > -1) | (getACSInterferenceAmount("P") > -1))
                {
                    llRegionSay(gActiveTerminalChannel,"say," +"1234"+theMessage); 
                    twDebug(INFO,"\""+theMessage+"\"");
                }
                else
                {
                    twDebug(DEBUG,"Could not send message because of ACS interference");
                }
            }
        }
        else if(gTalkChannel == 1010){
            havePermissions = 0;
        }
        else if(gTalkChannel == 1011){
            havePermissions = 1;
        }

    }
    
    listen(integer channel, string name, key id, string message) 
    {
        if (gACSChannel == channel) 
        {
            twDebug(DEBUG,"incoming interference message: "+message);
            list ACSCommands = llParseString2List(message, [","], []);
            string ACS = llList2String(ACSCommands,0);
            string command = llList2String(ACSCommands,1);
            string type = llList2String(ACSCommands,2);
            integer duration = llList2Integer(ACSCommands,3);
            integer strength = llList2Integer(ACSCommands,4);
            if ((ACS == "ACS") & (command == "interfere"))
            {
                setACSInterferenceAmounts(type, duration, strength);
            }
            else
            {
                twDebug(DEBUG,"unknown message in ACS interference channel:"+message);
            }
        }
    }

    timer() {
        if (getACSInterferenceAmount("") != 0)
        {
            setACSInterferenceAmounts("PMSNCY",0,0);
        }        
    }    
}
