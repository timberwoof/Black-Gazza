key avatarKey; 
string avatarKeyString;
string avatarName;

key primKey;
string primKeyString;

integer statuschannel = 16565;
integer statuslisten;
integer commandchannel = -1654;
integer commandlisten;

string tagTitle = "Zap Tag 0.3";

integer locked = 0;

// =================================
// particle system
StopParticles () {
    llParticleSystem(  [   ]  );
}

StartParticles () {
            llParticleSystem( [
            PSYS_PART_START_SCALE, <0.1,0.1,0.0>, 
            PSYS_PART_END_SCALE, <1.0,2.0,0.0>,     // requires INTERP_SCALE
            PSYS_PART_START_COLOR, <1.0,0.0,0.0>,
            PSYS_PART_END_COLOR, <1.0,1.0,0.0>,     // requires INTERP_COLOR
            PSYS_PART_START_ALPHA, 0.2,     
            PSYS_PART_END_ALPHA, 0.0,               // requires INTERP_COLOR
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
    string timestamp = llGetTimestamp( ); // format 
    string timeStampDate = llGetSubString(timestamp,0,9);
    string timeStampTime = llGetSubString(timestamp,11,18);
    string timeStampAll = timeStampDate + " " + timeStampTime;
    string url;
    
    if (avatarKeyString == "00000000-0000-0000-0000-000000000000") {
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
        llRequestPermissions( avatarKey, PERMISSION_TRIGGER_ANIMATION ); 
        
        if (index == 1) {
            StartParticles();
            llOwnerSay(llKey2Name(llDetectedKey(0)) + " punishes " + avatarName + " for disobedience.");
            llPlaySound("electricshock", 1.0);      
            llSetTimerEvent(1.0);
        } else if (index == 2) {
            StopParticles();
            llOwnerSay("@sendchat=n,recvchat=n");   // no chatting while fainted
        } else if (index == 4) {
            llOwnerSay("@sendchat=y,recvchat=y");   // allow chat again
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
    
    if (AnimationPlaying == 1) {
        llPlaySound("electricshock", 1.0);      
        }
} 

// llOwnerSay(avatarName + " fainted from the pain");
// agonyduraton = agonyduraton + 5; 
// faintduration = faintduration + 5;  // make it last long next time
 
stop_anims( key agent )
{
    list    l = llGetAnimationList( agent );
    integer    lsize = llGetListLength( l );
    integer i;
    for ( i = 0; i < lsize; i++ )
    {
        //llOwnerSay("stopping an animation");
        llStopAnimation( llList2Key( l, i ) );
    }
}


default
{
    state_entry()
    {
        llSetText(tagTitle+"\nInactive",<0,1,0>,1);
        StopParticles();
        initAnimationQueue();
        llPreloadSound("electricshock");
        commandlisten = llListen(commandchannel, "Timberwoof Prison Box", "", "" );
            }

     attach( key id )
     {
        avatarKey = id;
        avatarKeyString = (string)avatarKey;
        avatarName = llKey2Name(avatarKey);
        
        primKey = llGetKey( );
        primKeyString = (string)primKey;
        
        registerWithDB(0);
    }
 
    touch_start( integer num_detected )
    {
        integer now = llGetUnixTime( );
        //llOwnerSay("now: " + (string)now);
        if ((locked > 0) && (avatarKey != llDetectedKey(0))) {
            startAnimations(1);
        }    
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
        handleAnimationQueue();
    }
    
    // listen to the prison box
    listen( integer channel, string name, key id, string message )
    {
        if (channel == commandchannel) {
            //llOwnerSay(message);
            integer space = llSubStringIndex(message," ");
            string keyString = llGetSubString(message,0,space-1);
            //llOwnerSay("keyString:'" + keyString + "'");
            
            string RLVmessage = llGetSubString(message,space+1,-1);
            //llOwnerSay("RLVmessage:'" + RLVmessage + "'");
            
            if (avatarKeyString == keyString) {
                llOwnerSay(RLVmessage);
                if (llSubStringIndex(message,"@clear") > 0) {
                    locked = 0;
                    llSetText(tagTitle+"\nInactive",<0,1,0>,1);
                } else {
                    locked = 1;
                    llSetText(tagTitle+"\n*Active*",<1,1,0>,1);
                }
            }
            registerWithDB(locked);

        }
    }
    
    //http_response(key request_id, integer status, list metadata, string body)
    //{
    //    if (request_id == httprequest)
    //    {
    //    }
    //}


    //state_exit()
    //{
        // doesn't seem to work
        //llOwnerSay("state_exit");
        //llOwnerSay("@clear");
        //statuslisten = llListen(statuschannel, "Zap Badge", "", "" );
        //llOwnerSay("@getstatus=" + (string)statuschannel);
    //}
}
