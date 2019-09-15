string gsMyOwner;
key gkMyOwner;
key gkbrainballSlaveHUD;
string gStausText;
integer giMyCommandChannel = -765765;
integer giMyCommandListen;
integer giMyOpenListen = 0;
integer giActiveState;
integer hologramprim = 1;

integer DEBUG_LEVEL = 3;
integer OFF = 0;
integer ON = 1;
integer INFO = 1;
integer DEBUG = 2;
integer TRACE = 3;

list DEBUG_LEVELS = ["off","info","debug","trace"];

integer isACTIVE = 2;
integer isINACTIVE = 0;

// when description is "debug", this sends messages to wearer for debugging
sayDebug(integer level, string message) 
{
    if (level <= DEBUG_LEVEL) {
        llOwnerSay(llList2String(DEBUG_LEVELS,level)+": "+message);
    }
}


// register this brainball with the owner's SlaveHUD.
// send it information about where it is. 
register() {
    rotation myRotation = llGetRot() * llEuler2Rot(<0,-90,0>*DEG_TO_RAD);
    string registrationMessage  = "register," + (string)giMyCommandChannel + "," + gsMyOwner + "," + (string)llGetPos() + "," + (string)myRotation;
    sayDebug(INFO,"register "+registrationMessage);
    llRegionSay(giMyCommandChannel,registrationMessage);
}


startHologram(vector color)
{
    //llParticleSystem([]);
    //llLinkParticleSystem(0,[]);
    //llLinkParticleSystem(1,[]);
            llLinkParticleSystem(hologramprim,[
                PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK + PSYS_PART_INTERP_COLOR_MASK, 
                PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
                PSYS_PART_START_COLOR, color,
                PSYS_PART_END_COLOR, color,
                PSYS_PART_START_ALPHA, 1.0,
                PSYS_PART_END_ALPHA, 1.0,
                PSYS_PART_START_SCALE, <0.1,.2,0>,
                PSYS_PART_END_SCALE, <0.1,0.2,0>,
                PSYS_SRC_MAX_AGE, 10.0,
                PSYS_SRC_BURST_RATE, 1.0,
                PSYS_SRC_BURST_PART_COUNT, 10, 
                PSYS_PART_MAX_AGE, 60,
                PSYS_SRC_TEXTURE, "brainball hologram concept"
            ]);
}

        
endHologram()
{ 
    llLinkParticleSystem(2,[]);
}        


// the mainframe is setting the camera position to this terminal. 
// Make the terminal look alive and identify who's on the mainframe. 
activate(integer newstate, string newName, key newKey) {
    sayDebug(INFO,"activate");
    integer lensprim = 1;
    integer lensside = ALL_SIDES;
    giActiveState = newstate;
    
    string statusText = "Brainball status update.   Entity:"+ gsMyOwner;
    vector textColor = <1,0,0>;
    
    if (newstate == isACTIVE) {
        llPlaySound("beepbeepbeepbeep",1.0);
        llSetLinkPrimitiveParams(lensprim,[PRIM_FULLBRIGHT,lensside,TRUE]);
        llSetLinkPrimitiveParams(lensprim,[PRIM_GLOW,lensside,0.3]);
        statusText = statusText + "   Status:Active   Operator:" + newName;
        textColor = <1.0, 0.75, 0>;
        giMyOpenListen = llListen(0,"","","");
        startHologram(<0,1,0>);
    } else if (newstate == isINACTIVE) {
        llPlaySound("beepbeepbeepbeep",1.0);
        llSetLinkPrimitiveParams(lensprim,[PRIM_FULLBRIGHT,lensside,FALSE]);
        llSetLinkPrimitiveParams(lensprim,[PRIM_GLOW,lensside,0.0]);
        statusText = statusText + "   Status:Vacant";
        textColor = <0.75, 0.75, 0.75>;
        llListenRemove(giMyOpenListen);
        giMyOpenListen = 0;
        startHologram(<1,0,0>);
     }
    if (gStausText != statusText)
    {
        sayDebug(INFO,statusText);
        gStausText = statusText;
    }
   
}


default
{
    state_entry()
    {
        sayDebug(INFO,"state_entry");

    // set options from desctiption
    string optionstring = llGetObjectDesc();
    sayDebug(INFO,"Description: '"+optionstring+"'");
    
    // set the debug level
    DEBUG_LEVEL = OFF;
    if (llSubStringIndex(optionstring,"quiet") > -1) 
    {
        DEBUG_LEVEL = OFF;
        sayDebug(OFF,"debug level set to OFF");
    } 
    else if (llSubStringIndex(optionstring,"info") > -1) 
    {
        DEBUG_LEVEL = INFO;
        sayDebug(INFO,"debug level set to INFO");
    } 
    else if (llSubStringIndex(optionstring,"debug") > -1) 
    {
        DEBUG_LEVEL = DEBUG;
        sayDebug(DEBUG,"debug level set to DEBUG");
    }
    else if (llSubStringIndex(optionstring,"trace") > -1) 
    {
        DEBUG_LEVEL = TRACE;
        sayDebug(TRACE,"debug level set to TRACE");
    }

        
                
        gkMyOwner = llGetOwner();
        gsMyOwner = llKey2Name(gkMyOwner);
        
        integer link;
        for (link = 0; link <= llGetNumberOfPrims(); link++)
        {
            list result = llGetLinkPrimitiveParams(link,[PRIM_NAME]);
            string primname = llList2String(result,0);
            if (primname == "Hologram")
            {
                hologramprim = link;
            }
         }
        
        
        activate(isACTIVE,"state_entry","");
        llSleep(10);
        //giRegistrationListen = llListen(giRegistrationChannel, "BlackGazzaWarden", "", "");
        //giMyCommandChannel = giRegistrationChannel + (integer)llFloor(llFrand(-1000));
        register();
        giMyCommandListen = llListen(giMyCommandChannel, "BlackGazzaWarden", "", "");
        activate(giActiveState,"initialized",gkbrainballSlaveHUD);
    }

    touch_start(integer num_detected)
    {
        sayDebug(INFO,"touch_start");
        startHologram(<0.25,0,0>);
        llSay(0,"Waking the Entity. Please stand by.");
        register();
        string pageMessage  = "page," + gsMyOwner + "," + (string)giMyCommandChannel + "," + llKey2Name(llDetectedKey(0));
        sayDebug(INFO,"page "+pageMessage);
        llRegionSay(giMyCommandChannel,pageMessage);
    }
    
    listen(integer channel, string name, key id, string message) {
        sayDebug (DEBUG, "listen " + name + ": " + message);
        // if we receive an order form the maindrame to reregister
        if (channel == giMyCommandChannel) {
            startHologram(<1,.5,0>);
            llInstantMessage(gsMyOwner,"registration message");
            llInstantMessage(gsMyOwner,"channel:" + (string)channel + " message:" + message);
            list messageList = llCSV2List(message);
            string command = llList2String(messageList,0);
            if (command == "REGISTER") {
                register();
            } else if (command == "absent") {
                activate(isINACTIVE, llList2String(messageList,1), (key)llList2String(messageList,2));
            } else if (command == "deactivate") {
                activate(isINACTIVE, llList2String(messageList,1), (key)llList2String(messageList,2));
            }
            
        // if we receive a specialized order from the mainframe
        } else if (channel == giMyCommandChannel) {
            startHologram(<1,1,0>);
            llInstantMessage(gsMyOwner,"command message");
            llInstantMessage(gsMyOwner,"channel:" + (string)channel + " message:" + message);
            list messageList = llCSV2List(message);
            string command = llList2String(messageList,0);
            if (command == "activate") {
                activate(isACTIVE, llList2String(messageList,1), (key)llList2String(messageList,2));
            } else if (command == "designator") {
                gsMyOwner = llList2String(messageList,1);
                llSetObjectName("WardenTerminal " + gsMyOwner);
                activate(giActiveState,gsMyOwner,gkbrainballSlaveHUD);
            } else if (command == "say") {
                // chop off the beginning part of the message; only say the relevant part. 
                llSay(0,llGetSubString(message,8,-1));
            } else if (command == "loopback") {
                llInstantMessage(gkbrainballSlaveHUD,llGetSubString(message,8,-1));
            }

        // anything that comes in over the open listen gets sent to the sitting avatar. 
        } else if ( (0 != giMyOpenListen) && (channel = giMyOpenListen) && ( "" != gkbrainballSlaveHUD) ) {
            startHologram(<.25,.25,0>);
            llInstantMessage(gsMyOwner,name+ ": " +message);
        }
    }
    
}
