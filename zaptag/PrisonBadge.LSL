key avatarKey; 
string avatarKeyString;
string avatarName;

key primKey;
string primKeyString;

integer statuschannel = 16565;
integer statuslisten = 0;
integer commandchannel = -1654;
integer commandlisten = 0;

string tagTitle = "Zap Tag 0.4";

integer rlv = 0;        // default is there is no RLV
integer locked = 0;     // start up unlocked


// =================================
// colors
vector white = <1.0,1.0,1.0>;
vector green = <0.25,1.0,0.25>;
vector yellow = <1.0, 1.0, 0.0>;
vector red = <1.0, 0.0, 0.0>;

vector thecolor() {
    if (locked == 1) {
        if (rlv == 1) {
            return red;
        } else {
            return yellow;
        }
    } else {
        return green;
    }
}


// =================================
// particle system
StopParticles () {
    llParticleSystem(  [   ]  );
}

StartParticles () {
            llParticleSystem( [
            PSYS_PART_START_SCALE, <0.1,0.1,0.0>, 
            PSYS_PART_END_SCALE, <1.0,2.0,0.0>,    
            PSYS_PART_START_COLOR, thecolor(), 
            PSYS_PART_END_COLOR, yellow,    
            PSYS_PART_START_ALPHA, 0.2,     
            PSYS_PART_END_ALPHA, 0.0,            
            PSYS_SRC_BURST_PART_COUNT, 256,  
            PSYS_SRC_BURST_RATE, 0.1,  
            PSYS_PART_MAX_AGE, 1.0,   
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE, 
            PSYS_SRC_ACCEL, <0.0,0.0,-1.0>,       
            PSYS_SRC_BURST_SPEED_MIN, 0.3,   
            PSYS_SRC_BURST_SPEED_MAX, 2.3, 
            PSYS_PART_FLAGS, ( 
                PSYS_PART_EMISSIVE_MASK | 
                PSYS_PART_FOLLOW_VELOCITY_MASK | 
                PSYS_PART_INTERP_COLOR_MASK | 
                PSYS_PART_INTERP_SCALE_MASK )
        ] );
}

// =================================
// Communication with database
key httprequest;
string theAnimation;

registerWithDB(integer $locked) {
    // $locked == 0 means not locked
    // $locked == 1 means prisoner locked
    string timestamp = llGetTimestamp( ); // format 
    string timeStampDate = llGetSubString(timestamp,0,9);
    string timeStampTime = llGetSubString(timestamp,11,18);
    string timeStampAll = timeStampDate + " " + timeStampTime;
    string url;
    
    if (avatarKeyString == "00000000-0000-0000-0000-000000000000") {
        // tag is not attatched
        url = "http://web.infernosoft.com/blackgazza/unregisterInmate.php?"+
        "avatar=" + avatarKeyString + "&" + 
        "name=" + llEscapeURL(avatarName) + "&" + 
        "prim=" + primKeyString + "&" + 
        "timeSent=" + llEscapeURL(timeStampAll);
    } else {
        url = "http://web.infernosoft.com/blackgazza/registerInmate.php?"+
        "avatar=" + avatarKeyString + "&" + 
        "name=" + llEscapeURL(avatarName) + "&" + 
        "prim=" + primKeyString + "&" + 
        "locked=" + (string)locked + "&" +
        "timeSent=" + llEscapeURL(timeStampAll);
    }
    
    list parameters = [HTTP_METHOD, "GET",
        HTTP_MIMETYPE,"text/plain;charset=utf-8"];
    string body = "";
    //llOwnerSay(url); // *** debug
    httprequest = llHTTPRequest(url, parameters, body );
}


// =================================
// Animation Queue
list AnimationList = [
"bogus",0,
"shock",5,
"Fall/Faint",5,
"Stand From Faint",3,
"stand",1
];

integer NumberOfAnimations; // number of sounds in the list. n
integer AnimationPlaying = 0;   // the number of the sound that's playing. 0..n-1
integer PlayNextAnimation = 0;  // the Unix time when the next sound must be played

initAnimationQueue() {
    // initialize the sond playing system
    NumberOfAnimations =  llGetListLength(AnimationList) / 2;
}

startAnimations(integer index) {
    // sets the time wehn we need to kick off the next animation
    // start with call to starSound(0);
    //llOwnerSay("startAnimation " + (string)index);
    llSetTimerEvent(1.0);
    if (index < NumberOfAnimations) {
        AnimationPlaying = index;
        theAnimation = llList2String(AnimationList, AnimationPlaying*2);
        PlayNextAnimation = llGetUnixTime() + llList2Integer(AnimationList,AnimationPlaying*2+1);
        //llOwnerSay("animating '" + theAnimation + "' until " + (string)PlayNextAnimation);
        if (avatarKey != NULL_KEY) {
            llRequestPermissions( avatarKey, PERMISSION_TRIGGER_ANIMATION ); 
        }
        
        if (index == 1) {
            llSetPrimitiveParams( [ PRIM_GLOW, ALL_SIDES, 1.0 ] ) ; 
            StartParticles();
            llOwnerSay(llKey2Name(llDetectedKey(0)) + " punishes " + avatarName + " for disobedience.");
            llLoopSound("electricshock", 1.0);      
            llSetTimerEvent(1.0);
        } else if (index == 2) {
            llSetPrimitiveParams( [ PRIM_GLOW, ALL_SIDES, 0.0 ] ) ; 
            StopParticles(); 
            llStopSound();
            if (rlv == 1) {
                llOwnerSay("@sendchat=n,recvchat=n");   // no chatting while fainted
            }
        } else if (index == 4) {
            if (rlv == 1) {
                llOwnerSay("@sendchat=y,recvchat=y");   // allow chat again
            }
        }
    } else {
        //llOwnerSay("startAnimation sequence completed");
        AnimationPlaying = 0;
        PlayNextAnimation = 0;
        stop_anims(avatarKey);
        llSetTimerEvent(0);
    }
}

// stick a call to this in the timer event
handleAnimationQueue() {
    if ((PlayNextAnimation > 0) && 
        (PlayNextAnimation <= llGetUnixTime( )) && 
        (AnimationPlaying < NumberOfAnimations)){
            startAnimations(++AnimationPlaying);
        }
} 

// llOwnerSay(avatarName + " fainted from the pain");
// agonyduraton = agonyduraton + 5; 
// faintduration = faintduration + 5;  // make it last long next time
 
stop_anims( key agent )
{
    if (agent != NULL_KEY) {
        list animationList = llGetAnimationList( agent );
        integer    lsize = llGetListLength( animationList );
        integer i;
        for ( i = 0; i < lsize; i++ )
        {
            //llOwnerSay("stopping an animation");
            llStopAnimation( llList2Key( animationList, i ) );
        }
    }
}


// =================================
// Events
default
{
    state_entry()
    {
        //llOwnerSay("state_entry");
        StopParticles();
        initAnimationQueue();
        llPreloadSound("electricshock");
        primKey = llGetKey( );
        primKeyString = (string)primKey;
        //llOwnerSay("state_entry done");
    }

     attach( key id )
     {
        //llOwnerSay("attach");
        llSetPrimitiveParams([PRIM_COLOR,ALL_SIDES,green,1.0]); // make it green
        llSetText(tagTitle+"\nInactive",green,1);

        rlv = 0;
        locked = 0;
        
        avatarKey = id;
        avatarKeyString = (string)avatarKey;
        avatarName = llKey2Name(avatarKey);

        commandlisten = llListen(commandchannel, "Timberwoof Prison Box", "", "" );
        statuslisten = llListen(statuschannel, "", "", "" );
        string statusquery="version="+(string)statuschannel;
        //llOwnerSay(statusquery);
        llOwnerSay("@"+statusquery);
        llSetTimerEvent(60); // "the timeout should be long enough, like 30 seconds to one minute in order to receive the automatic reply from the viewer." 

        registerWithDB(0);  // doesn't tell RLV status
        llOwnerSay("Black Gazza Zap Tag 0.4 (development version). To activate or deactivate, click a Prison Box.");
        //llOwnerSay("attach done");
    }
 
    touch_start( integer num_detected )
    {
        if (locked > 0) {   // must be prison-locked *** comment out for debug
            if (avatarKey != llDetectedKey(0)) { // must be someone else *** comment out for debug
                startAnimations(1);
            }   // *** comment out for debug
        }   // *** comment out for debug
    }
    
    run_time_permissions(integer permissions)
    {
        //llOwnerSay("run_time_permissions " + (string)theAnimation);
        if (permissions & PERMISSION_TRIGGER_ANIMATION) {
            stop_anims(avatarKey);
            llStartAnimation(theAnimation);
        }
    }

    timer()
    {
        if (statuslisten != 0) {
            // we were asking local RLV status; this is the timeout
            llOwnerSay("Your SL viewer is not RLV-Enabled. You're missing out on all the fun!");
            rlv = 0;
            llListenRemove(statuslisten);
            statuslisten = 0;
        } else {
            // can only have come from an animation event
            handleAnimationQueue();
        }            
    }
    
    // listen to the prison box
    listen( integer channel, string name, key id, string message )
    {
        if (channel == commandchannel) {
            //llOwnerSay("command:" + message);
            integer space = llSubStringIndex(message," ");
            string keyString = llGetSubString(message,0,space-1);
            //llOwnerSay("keyString:'" + keyString + "'");
            
            string RLVmessage = llGetSubString(message,space+1,-1);
            //llOwnerSay("RLVmessage:'" + RLVmessage + "'");
            
            if (avatarKeyString == keyString) {
                string lock;
                llOwnerSay(RLVmessage); // *** This is where the message gets sent to viewer. Don't comment this out. 
                if (llSubStringIndex(message,"@clear") > 0) {
                    locked = 0;
                    lock = "Inactive";
                } else {
                    locked = 1;
                    if (rlv == 1) {
                        lock = "Active+RLV";
                    } else {
                        lock = "Active";
                    }
                }
                llSetPrimitiveParams([PRIM_COLOR,ALL_SIDES,thecolor(),1.0]);
                llSetText(tagTitle+"\n"+lock,thecolor(),1.0);
                llWhisper(0,avatarName + "'s prison tag is now " + lock + ".");
            }
            registerWithDB(locked);
        }
        if (channel == statuschannel) {
            //llOwnerSay("RLV status:" + message);
            rlv = 1;
            llListenRemove(statuslisten);
            statuslisten = 0;
        }
    }
    
    http_response(key request_id, integer status, list metadata, string body)
    {
        // just drop it in the bitbucket.
        //if (request_id == httprequest)
        //{
        //}
    }


    //state_exit()
    //{
        // doesn't seem to work
        //llOwnerSay("state_exit");
        //llOwnerSay("@clear");
        //statuslisten = llListen(statuschannel, "Zap Badge", "", "" );
        //llOwnerSay("@getstatus=" + (string)statuschannel);
    //}
}
