// BG Droid/Borg HUD
// Worn by Robots, Droids, Androids, Cyborgs, and other controlled units;
// interfaces to the Black Gazza AI. 
// The wearer becomes a terminal selectable by the AI. 
// The wearer can still move and speak under his own volition. 
// The AI sees and hears from the wearer's position; 
// the AI speaks from the wearer. 

// Instructions: Wearer must change the HUD's description to his robot designation, 
// for example "Lup-4636". This is the designation the AI operator must use to 
// activate the robot as a terminal, so be kind and keep it short. 

integer giRegistrationChannel = 7659005; // Do not change this. 
integer giRegistrationListen;
string gsMyCommandChannel;
integer giMyCommandChannel;
integer giMyCommandListen;
string gsMyDesignator = "";
string gsWardenName = "Central Scrutinizer";
integer giMyOpenListen = 0;
key gkWarden;

key gkWearer;

string inmateToZap = "";

integer giActiveState = 0;
integer isACTIVE = 2;
integer isPRESENT = 1;
integer isINACTIVE = 0;

vector gLastPos = <0,0,0>;

initialize(key id)
{
    gkWearer = id;
    if (id == "") 
    {
        gkWearer = llGetOwner();
    }
    gsMyDesignator = "R-" + stringToTouchTone(llKey2Name(gkWearer),4);
    
    llSetObjectName(gsMyDesignator);
    activate(isINACTIVE,"state_entry","");
    giRegistrationListen = llListen(giRegistrationChannel, gsWardenName, "", "");
    gsMyCommandChannel = stringToTouchTone(gsMyDesignator,9);
    giMyCommandChannel = (integer)gsMyCommandChannel;
    giMyCommandListen = llListen(giMyCommandChannel, gsWardenName, "", "");
    register();
    activate(giActiveState,"initialized",gkWarden);
}

// Register this terminal with the mainframe.
// Send it a bunch of information about where it is. 
register() {
    string registrationMessage  = "register," + gsMyCommandChannel + "," + 
        "Remote:" + gsMyDesignator +":" + llKey2Name(gkWearer) + "," + (string)llGetPos() + "," + (string)llGetRot();
    llRegionSay(giRegistrationChannel,registrationMessage);
    // registrationMessage looks like
    // register,58704636,R-84623:Timberwoof Lupindo,<199.44099, 195.92999, 1231.37427>,<0.00000, 0.00000, 0.33792, 0.94118>
}

updateLocation() {
    if (llVecDist(gLastPos, llGetPos()) > 1.0)
    {
        gLastPos = llGetPos();
        string locationMessage  = "update," + gsMyCommandChannel + "," + 
            "Remote:" + gsMyDesignator + "," + (string)gLastPos + "," + (string)llGetRot();
        llRegionSay(giRegistrationChannel,locationMessage);
    }
}

string char2touchToneInt(string inputCharacter)
// Convert one character to its touch-tone equivalent.
// Unknown characters are converted to 0. 
{
    list buttons = ["0","1","2abcABC","3defDEF","4ghiGHI","5jklJKL","6mnoMNO","7pqrsPQRS","8tuvTUV","9wxyzWXYZ"];
    integer i;
    for (i=0; i<=9; i++)
    {
        if (llSubStringIndex(llList2String(buttons,i),inputCharacter) >= 0)
            return (string)i;
    }
    return "0";
}

// Convert a string (usually the robot name) to digits. The result is unique enough.
// Lup-4636 should become 58704636
string stringToTouchTone(string designator, integer digits)
{
    string outdigits = "";
    integer i;
    integer len = llStringLength(llGetSubString(designator,0,digits));
    for (i=0; i<len; i++)
    {
        outdigits = outdigits + char2touchToneInt(llGetSubString(designator,i,i));
    }
    return outdigits;
}

// The mainframe is setting the camera position to this terminal. 
activate(integer newstate, string newName, key newKey) {
    gsWardenName = newName;
    giActiveState = newstate;
    gkWarden = newKey;
    // Code about changing appearance is commented out as this is a HUD. 
    // If this ever becomes an object worn externally by the robot, this may change. 
    //integer lensprim = 1;
    //integer lensside = 2;
    
    string announceText = gsWardenName+" Mobile Terminal state: ";
    string floatText = gsWardenName+"Mobile Terminal\n" + gsMyDesignator;
    vector textColor = <1,0,0>;
    
    if (newstate == isACTIVE) {
        llPlaySound("beepbeepbeepbeep",1.0);
        llSetTexture("Hal",ALL_SIDES);
        llSetColor(<1,1,1>,ALL_SIDES);
        announceText = announceText + "ACTIVE (" + newName + ")";
        floatText = floatText + " - Active\n(" + newName + ")";
        textColor = <1.0, 0.75, 0>;
        giMyOpenListen = llListen(0,"","","");
        gLastPos = <0,0,0>;
        llSetTimerEvent(1);
    } else if (newstate == isPRESENT) {
        llSetTexture("Hal",ALL_SIDES);
        llSetColor(<.5,.5,.5>,ALL_SIDES);
        announceText = announceText + "PRESENT (" + newName + ")";
        floatText = floatText + " - Inactive\n(" + newName + ")";
        textColor = <0.75, 0.5, 0>;
        llListenRemove(giMyOpenListen);
        giMyOpenListen = 0;
        llSetTimerEvent(0);
    } else if (newstate == isINACTIVE) {
        llPlaySound("beepbeepbeepbeep",1.0);
        llSetTexture("Hal9000Grayscale",ALL_SIDES);
        llSetColor(<.5,.5,.5>,ALL_SIDES);
        announceText = announceText + "INACTIVE (" + newName + ")";
        floatText = floatText + " - Inactive\n(" + newName + ")";
        textColor = <0.75, 0.75, 0.75>;
        llListenRemove(giMyOpenListen);
        giMyOpenListen = 0;
        llSetTimerEvent(0);
    }
    floatText = "";
    llSetText(floatText, textColor, 1);
    //llSay (0,announceText);
}

zap (list commandList) {
    string recipient = llList2String(commandList,1);
    string firstthree = llToUpper(llGetSubString(recipient,0,2));
    if (firstthree == "P-6") {
        llInstantMessage(gkWarden,"I think " + recipient + " is a collar number. I can't zap those yet.");
    } else {
        inmateToZap = recipient;
        llSensor("","",AGENT,20,PI);
    }
}

default
{
    state_entry()
    {
        initialize(gkWearer);
    }
    
    attach(key id)
    {
        initialize(id);
    }

    touch_start(integer num_detected)
    {
        llSay(0,"Paging the "+gsWardenName+". Please stand by.");
        string pageMessage  = "page," + gsMyDesignator + "," + (string)gsMyCommandChannel + "," + llKey2Name(llDetectedKey(0));
        llRegionSay(giRegistrationChannel,pageMessage);
    }
    
    listen(integer channel, string name, key id, string message) {
        // if we receive an order form the mainframe to reregister
        if (channel == giRegistrationChannel) {
            llSetTimerEvent(0);
            list messageList = llCSV2List(message);
            string command = llList2String(messageList,0);
            if (command == "REGISTER") {
                register();
            } else  if (command == "present") {
                activate(isPRESENT, llList2String(messageList,1), (key)llList2String(messageList,2));
            } else if (command == "absent") {
                activate(isINACTIVE, llList2String(messageList,1), (key)llList2String(messageList,2));
            } else if (command == "deactivate") {
                activate(isINACTIVE, llList2String(messageList,1), (key)llList2String(messageList,2));
            }
            
        // if we receive a specialized order from the mainframe
        } else if (channel == giMyCommandChannel) {
            list messageList = llCSV2List(message);
            string command = llList2String(messageList,0);
            if (command == "activate") {
                activate(isACTIVE, llList2String(messageList,1), (key)llList2String(messageList,2));
            } else if (command == "designator") {
                gsMyDesignator = llList2String(messageList,1);
                activate(giActiveState,gsWardenName,gkWarden);
            } else if (command == "say") {
                // chop off the beginning part of the message; only say the relevant part. 
                llSay(0,llGetSubString(message,8,-1));
            } else if (command == "loopback") {
                llInstantMessage(gkWarden,llGetSubString(message,8,-1));
            } else if (command == "zap") {
                zap(messageList);
            }

        // anything that comes in over the open listen gets sent to the sitting avatar. 
        } else if ( (0 != giMyOpenListen) && (channel = giMyOpenListen) && ( "" != gkWarden) ) {
            llInstantMessage(gkWarden,name+ ": " +message);
        }
    }
    
    timer()
    {
        updateLocation();
    }
}
