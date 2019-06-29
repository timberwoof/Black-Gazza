// Timberwoof's Black Gazza Inmate HUD

// need to work out what different states it has and the transitions between locked and unlocked and stuff

key avatarKey; 
string avatarKeyString;
string avatarName;

key primKey;
string primKeyString;

integer RLVStatusChannel = 0;      // listen to itself for RLV responses; generated on the fly
integer RLVStatusListen = 0;
integer MenuChannel = 0;        // listen to itself for menu; generated on the fly
integer MenuListen = 0;
integer CommandChannel = 0;     //listen to commands from prison box & guard HUD; generated on the fly
integer CommandListen = 0;

string hudTitle = "BG Inmate HUD 0.5";
string tagDesc = "";

integer hudAttached = 0;    //0 = unattached; 1 = attached
integer rlvPresent = 0;     //0 = no RLV; 1 = RLV is present

integer HudFunctionState = 0;
// -3 = off with remote turn-on
// 0 = off
// 1 = on with off switch
// 2 = on with timer
// 3 = on with remote turn-off

integer SAFEWORD = 1; // ***
// Later on, add code that will change the value of this to 0 for hardcore users. 

sayDebug(string message) {
    if (tagDesc == "debug") {
        llOwnerSay("debug: "+message);
    }
}


// =================================
// colors
vector white = <1.0,1.0,1.0>;
vector green = <0.25,1.0,0.25>;
vector yellow = <1.0, 1.0, 0.0>;
vector red = <1.0, 0.0, 0.0>;

setStateTitleAndColor() {
    string suffix;
    vector color;
    if (hudAttached == 0) {
        suffix = "Unattatched";
        color  = white;
        
    } else if ((HudFunctionState < 1)){
        suffix = "Inactive";
        color  = green;
        
    } else if (rlvPresent == 0) {
        // this is a stupid state
        suffix = "Active";
        color  = yellow;
        
    } else {
        suffix = "Active RLV";
        color  = red;
    }

    llSetText(hudTitle+" \n"+suffix,color,1);
    llSetPrimitiveParams([PRIM_COLOR,ALL_SIDES,color,1.0]);
    //sayDebug(avatarName + "'s prison tag is now " + lock + ".");
}


// =================================
// HUD menu
//
list addSafewordToMenu() {
    if (SAFEWORD == 1) {
        return ["Safeword"];
    } else {
        return [];
    }
}

hudMenu() {
// "On","Off","On Timer","On Remote","Set Timer","Safeword","Register"

    list buttons;
    string message;
    if (HudFunctionState == 0) {   
        // off
        message = "OFF";
        buttons = ["On","On Timer","On Remote","Set Timer"];
    
    } else if (HudFunctionState == 1) { 
        // on with off switch
        message = "ON";
        buttons = ["Off","On Timer","On Remote","Set Timer"] + addSafewordToMenu();   
    
    } else if (HudFunctionState == 2) { 
        // on with timer
        message = "ON Timer";
        buttons = [] + addSafewordToMenu();   
    
    } else if (HudFunctionState == -3) { 
        // off with remote turn-on
        message = "OFF with Remote Activation";
        buttons = ["On","On Timer","Set Timer"];
    
    } else if (HudFunctionState == 3) { 
        // on with remote turn-off
        message = "Hud is ON with Remote Deactivation";
        buttons = [] + addSafewordToMenu();  
     
    } else {
        llOwnerSay("Error: illegal value for HudFunctionState: " + (string)HudFunctionState + " resetting.");
        llResetScript();
    }

    buttons = buttons + ["Register"];   // what's this for? 

    message = "Prisoner HUD v0.5 is " + message;
    MenuListen = llListen(MenuChannel, "", avatarKey, "" );
    // listen on the MenuChannel
    // to only the avatar wearing the hud
    llDialog(avatarKey, message, buttons, MenuChannel);
    llSetTimerEvent(30); 
}


// =================================
// Communication with database
key httprequest;

registerWithDB() {
    string timestamp = llGetTimestamp( ); // format 
    string timeStampDate = llGetSubString(timestamp,0,9);
    string timeStampTime = llGetSubString(timestamp,11,18);
    string timeStampAll = timeStampDate + " " + timeStampTime;
    string url;
    
    // what  to tell the database
    string hudActive = "0";
    if (HudFunctionState > 0) {
        hudActive = "1";
        }
    
    if (avatarKeyString == "00000000-0000-0000-0000-000000000000") {
        // tag is not attatched
        url = "http://web.infernosoft.com/blackgazza/unregisterInmate.php?"+
        "avatar=" + avatarKeyString + "&" + 
        "name=" + llEscapeURL(avatarName) + "&" + 
        "prim=" + primKeyString + "&" + 
        "timeSent=" + llEscapeURL(timeStampAll) + "&" +
        "commandChannel=0";
    } else {
        url = "http://web.infernosoft.com/blackgazza/registerInmate.php?"+
        "avatar=" + avatarKeyString + "&" + 
        "name=" + llEscapeURL(avatarName) + "&" + 
        "prim=" + primKeyString + "&" + 
        "locked=" + hudActive + "&" +
        "timeSent=" + llEscapeURL(timeStampAll) + "&" +
        "commandChannel=" + (string)CommandChannel;
    }
    
    list parameters = [HTTP_METHOD, "GET",
        HTTP_MIMETYPE,"text/plain;charset=utf-8"];
    string body = "";
    sayDebug(url); // *** debug
    httprequest = llHTTPRequest(url, parameters, body );
}


// =================================
// Animation Queue
string theAnimation;

oldTouch(){
    if (HudFunctionState > 0) {   // must be prison-locked *** comment out for debug
        if (avatarKey != llDetectedKey(0)) { // must be someone else *** comment out for debug
            startAnimations(1);
            }   // *** comment out for debug
        }   // *** comment out for debug
}


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
    //sayDebug("startAnimation " + (string)index);
    llSetTimerEvent(1.0);
    if (index < NumberOfAnimations) {
        AnimationPlaying = index;
        theAnimation = llList2String(AnimationList, AnimationPlaying*2);
        PlayNextAnimation = llGetUnixTime() + llList2Integer(AnimationList,AnimationPlaying*2+1);
        //sayDebug("animating '" + theAnimation + "' until " + (string)PlayNextAnimation);
        if (avatarKey != NULL_KEY) {
            llRequestPermissions( avatarKey, PERMISSION_TRIGGER_ANIMATION ); 
        }
        
        if (index == 1) {
            //llSetPrimitiveParams( [ PRIM_GLOW, ALL_SIDES, 1.0 ] ) ; 
            //StartParticles(); // doesn't work as hud
            llOwnerSay(llKey2Name(llDetectedKey(0)) + " punishes " + avatarName + " for disobedience.");
            llLoopSound("electricshock", 1.0);      
            llSetTimerEvent(1.0);
        } else if (index == 2) {
            //llSetPrimitiveParams( [ PRIM_GLOW, ALL_SIDES, 0.0 ] ) ; 
            //StopParticles(); // doesn't work as hud
            llStopSound();
            if (rlvPresent == 1) {
                llOwnerSay("@sendchat=n,recvchat=n");   // no chatting while fainted
            }
        } else if (index == 4) {
            if (rlvPresent == 1) {
                llOwnerSay("@sendchat=y,recvchat=y");   // allow chat again
            }
        }
    } else {
        //sayDebug("startAnimation sequence completed");
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
            //sayDebug("stopping an animation");
            llStopAnimation( llList2Key( animationList, i ) );
        }
    }
}


// =================================
// RLV

sendRLVRestrictCommand() {
    llOwnerSay("@chatshout=n,chatnormal=n,tplm=n,tploc=n,tplure=n,sittp=n,fartouch=n,showworldmap=n,showminimap=n,showloc=n,fly=n,detach=n,edit=n,rez=n,detach:BGVisitor=force,attach:BGInmate=force,showinv=n");
}

sendRLVUnrestrictCommand() {
    llOwnerSay("@clear,detach:BGInmate=force,attach:BGVisitor=force");
}



// =================================
// Events
default
{
    state_entry()
    {
        //sayDebug("state_entry");
        hudAttached = 0;
        rlvPresent = 0;
        HudFunctionState = 0;
        
        hudTitle = llGetObjectName();
        tagDesc = llGetObjectDesc();

        initAnimationQueue();
        llPreloadSound("electricshock");
        //sayDebug("state_entry done");
        llSetPrimitiveParams([PRIM_COLOR,ALL_SIDES,white,1.0]); // make it white
        setStateTitleAndColor();
    }

     attach( key id )
     {
        sayDebug("attach"); // *** debug

        hudAttached = 1;
        rlvPresent = 0;
        HudFunctionState = 0;
        
        primKey = llGetKey( );
        primKeyString = (string)primKey;

        avatarKey = id;
        avatarKeyString = (string)avatarKey;
        avatarName = llKey2Name(avatarKey);

        llSetPrimitiveParams([PRIM_COLOR,ALL_SIDES,green,1.0]); // make it green
        setStateTitleAndColor();
        
        MenuChannel = (integer)llFrand(8999)+1000; // generate a session menu channel

        CommandChannel = (integer)llFrand(8999)+1000;   // generate a session command channel
        sayDebug("commandChannel=" + (string)CommandChannel);
        CommandListen = llListen(CommandChannel, "", "", "" );
            // listen on the newly generated command channel 
            // to any prim or avtar
            // with any uuid
            // saying any message
        
        RLVStatusChannel = (integer)llFrand(8999)+1000; // generate a sessin RLV status channel
        RLVStatusListen = llListen(RLVStatusChannel, "", "", "" );
            // listen on the newly generated rlv status channel
        string statusquery="version="+(string)RLVStatusChannel;
        sayDebug(statusquery); // *** debug
        llOwnerSay("@"+statusquery);
        llSetTimerEvent(60); 
        // "the timeout should be long enough, like 30 seconds to one minute 
        // in order to receive the automatic reply from the viewer." 

        registerWithDB();    // inmate, offline  
        llOwnerSay("Black Gazza" + hudTitle + 
            " (development version). To activate or deactivate, click a Prison Box.");
        sayDebug("attach done"); // *** debug
    }
 
    touch_start( integer num_detected )
    {
        hudMenu();
    }
    
    run_time_permissions(integer permissions)
    {
        //sayDebug("run_time_permissions " + (string)theAnimation);
        if (permissions & PERMISSION_TRIGGER_ANIMATION) {
            stop_anims(avatarKey);
            llStartAnimation(theAnimation);
        }
    }

    timer()
    {
        if (RLVStatusListen != 0) {
            // we were asking local RLV status; this is the timeout
            llOwnerSay("Your SL viewer is not RLV-Enabled. You're missing out on all the fun!");
            rlvPresent = 0;
            llListenRemove(RLVStatusListen);
            RLVStatusListen = 0;
        } else if (MenuListen !=0) {
            // we were waiting for a memnu; this is the timeoit
            llListenRemove(MenuListen);
            MenuListen = 0;
        } else {
            // can only have come from an animation event
            handleAnimationQueue();
        }            
    }
    
    // listen to objects on the command channel, 
    // rlv status messages on the status channel, 
    // and menu commands on the menuc hannel
    listen( integer channel, string name, key id, string message )
    {
        if (channel == CommandChannel) {
            sayDebug("command:" + message);   // *** debug
            integer atrlv = llSubStringIndex(message,"@");
            
            if (atrlv >= 0) {
                integer space = llSubStringIndex(message," ");
                string keyString = llGetSubString(message,0,space-1);
                //sayDebug("keyString:'" + keyString + "'");   // *** debug
            
                string RLVmessage = llGetSubString(message,space+1,-1);
                //sayDebug("RLVmessage:'" + RLVmessage + "'");   // *** debug
            
                if ((atrlv > -1) && (avatarKeyString == keyString)) {
                    if (llSubStringIndex(message,"clear") > 0) {
                        // remote deactivation always allowed.
                        // *** This is where the message gets sent to viewer. 
                        llOwnerSay(RLVmessage); // *** Don't comment this out. *** debug
                        HudFunctionState = 0;
                    } else {
                        // if remote activation is allowed, then turn it on
                        if (HudFunctionState == -3) {
                            // *** This is where the message gets sent to viewer. 
                            llOwnerSay(RLVmessage); // *** Don't comment this out. *** debug
                            HudFunctionState = 1;
                        } else {
                            sayDebug("ignored remote activation message:");
                        }
                    }
                    setStateTitleAndColor();
                }
                registerWithDB();
            } // if (atrlv >= 0)

            integer atbg = llSubStringIndex(message,"#") +1;
            if (atbg > 0) {
                string command = llGetSubString(message,atbg,-1);
                sayDebug("command=" + command);
                if (command = "zap") {
                    startAnimations(1);
                }
            } // if (atbg >= 0)
            // never remove the commandChannel listen                       
        }
        
        if (channel == RLVStatusChannel) {
            sayDebug("RLV status:" + message);   // *** debug
            rlvPresent = 1;
            llListenRemove(RLVStatusListen);
            RLVStatusListen = 0;
        }
        
        if (channel == MenuChannel) {
            if (message == "Off") {
                sendRLVUnrestrictCommand();
                HudFunctionState = 0;
                registerWithDB(); // prisoner, off

            } else if (message == "On") {
                sendRLVRestrictCommand();
                HudFunctionState = 1;
                registerWithDB(); // prisoner, on
                
            } else if (message == "On Timer") {
                HudFunctionState = 2;
                
            } else if (message == "On Remote") {
                HudFunctionState = -3;
                
            } else if (message == "Set Timer") {
                // setTimer();
                
            } else if (message == "Safeword") {
                // safeword();
                HudFunctionState = 0;
                
            } else if (message == "Register") {
                registerWithDB();    // what's this for? 
            }
            setStateTitleAndColor();
            llListenRemove(MenuListen);
            MenuListen = 0;
        }
    }


    
    http_response(key request_id, integer status, list metadata, string body)
    {
        // just drop it in the bitbucket.
        if (request_id == httprequest)
        {
            sayDebug("http response:");
            sayDebug(body);
            sayDebug("---end");
        }
    }


    //state_exit()
    //{
        // doesn't seem to work
        //sayDebug("state_exit");
        //llOwnerSay("@clear");
        //RLVStatusListen = llListen(RLVStatusChannel, "Zap Badge", "", "" );
        //llOwnerSay("@getstatus=" + (string)RLVStatusChannel);
    //}
}
