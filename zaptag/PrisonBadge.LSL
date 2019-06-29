// Timberwoof's Black Gazza Inmate HUD

string hudTitle = "BG Inmate HUD 0.8"; 

key avatarKey; 
string avatarKeyString;
string avatarName;

key primKey;
string primKeyString;

integer hudAttached = 0;    //0 = unattached; 1 = attached
integer HudFunctionState = 0;
// -3 = off with remote turn-on
// 0 = off
// 1 = on with off switch
// 2 = on with timer
// 3 = on with remote turn-off

integer rlvPresent = 0;     //0 = no RLV; 1 = RLV is present
integer RLVStatusChannel = 0;      // listen to itself for RLV responses; generated on the fly
integer RLVStatusListen = 0;
integer MenuChannel = 0;        // listen to itself for menu; generated on the fly
integer MenuListen = 0;
integer CommandChannel = 0;     //listen to commands from prison box & guard HUD; generated on the fly
integer CommandListen = 0;
integer SafewordChannel = 0;
integer SafewordListen = 0;
integer muzzleChannel = 0;
integer muzzleHandle = 0;
integer Safeword = 0;
integer debugLevel = 0; // 0 = silent, 1 = blabby

integer SAFEWORD = 1; // ***
// Later on, add code that will change the value of this to 0 for hardcore users. 

sayDebug(string message) {
    if (debugLevel == 1) {
        llOwnerSay("debug: "+message);
    }
}

list addDebugToMenu() {
    // if we are blabby, offer to be silent
    if (debugLevel == 1) {
        return(["Bugger Off"]);
    } else {
        return(["Debug On"]);
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
        // this is a stupid state ... but possible nevertheless
        suffix = "Active";
        color  = yellow;
        
    } else {
        suffix = "Active RLV";
        color  = red;
    }

    if (HudFunctionState == 2) {
        suffix = suffix + " " + HUDTimerDisplay();
    }

    llSetText(hudTitle+" \n"+suffix,color,1);
    llSetPrimitiveParams([PRIM_COLOR,ALL_SIDES,color,1.0]);
    //sayDebug(avatarName + "'s prison tag is now " + lock + ".");
}


generateChannels() {
    if (MenuChannel != 0) {
        sayDebug("remove menuChannel " + (string)MenuChannel);
        llListenRemove(MenuChannel);
        }
    MenuChannel = -(integer)llFrand(8999)+1000; // generate a session menu channel
    sayDebug("created new menuChannel " + (string)MenuChannel);
    

    if (CommandChannel != 0) {
        sayDebug("remove CommandChannel " + (string)CommandChannel);
        llListenRemove(CommandChannel);
        }
    CommandChannel = -(integer)llFrand(8999)+1000;   // generate a session command channel
    sayDebug("created new CommandChannel " + (string)CommandChannel);
    CommandListen = llListen(CommandChannel, "", "", "" );
        // listen on the newly generated command channel 
        // to any prim or avtar
        // with any uuid
        // saying any message

    if (RLVStatusChannel != 0) {
        sayDebug("remove RLVStatusChannel " + (string)RLVStatusChannel);
        llListenRemove(RLVStatusChannel);
    }
    RLVStatusChannel = (integer)llFrand(8999)+1000; // generate a sessin RLV status channel
    sayDebug("created new RLVStatusChannel " + (string)RLVStatusChannel);
    RLVStatusListen = llListen(RLVStatusChannel, "", avatarKey, "" );
        // listen on the newly generated rlv status channel
        
    if (muzzleChannel != 0) {
        sayDebug("remove muzzleChannel " + (string)muzzleChannel);
        llListenRemove(muzzleChannel);
        }
    muzzleChannel = (integer)llFrand(8999)+1000; // generate a session menu channel
    sayDebug("created new muzzleChannel " + (string)muzzleChannel);
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
// "On","Off","On Timer","On Remote","Set Timer","Safeword","Register","Debug"

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

    //buttons = buttons + ["Register"];   // what's Register for? Removed it.
    
    buttons = buttons + addDebugToMenu();

    message = hudTitle + " is " + message;
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
    integer hudActive = 0;
    if (HudFunctionState > 0) {
        hudActive = 1;
        }
    if (rlvPresent == 1) {
        hudActive = hudActive * 10;
    }
    
    if (avatarKeyString == "00000000-0000-0000-0000-000000000000") {
        // tag is not attatched
        url = "http://web.infernosoft.com/blackgazza/registerUser.php?"+
        "avatar=" + avatarKeyString + "&" + 
        "name=&" + 
        "prim=" + primKeyString + "&" + 
        "role=0&" +
        "timeSent=" + llEscapeURL(timeStampAll) + "&" +
        "commandChannel=0";
    } else {
        url = "http://web.infernosoft.com/blackgazza/registerUser.php?"+
        "avatar=" + avatarKeyString + "&" + 
        "name=" + llEscapeURL(avatarName) + "&" + 
        "prim=" + primKeyString + "&" + 
        "role=" + (string)hudActive + "&" +
        "timeSent=" + llEscapeURL(timeStampAll) + "&" +
        "commandChannel=" + (string)CommandChannel;
    }
    
    list parameters = [HTTP_METHOD, "GET",
        HTTP_MIMETYPE,"text/plain;charset=utf-8"];
    string body = "";
    //sayDebug(url); // *** debug
    httprequest = llHTTPRequest(url, parameters, body );
}


// =================================
// Animation Queue
string theAnimation;
integer AnimationQueueStatus = 0;

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
        AnimationQueueStatus = 1; 
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
        AnimationQueueStatus = 0; 
        HUDTimerRestart();
    }
}

// stick a call to this in the timer event
handleAnimationQueue() {
    if (PlayNextAnimation > 0) { 
        HUDTimerIncrement(HUDTimerInterval + 1); // makes timer backup while animation is playing 
            // HUDTimerInterval backs off what was added in accelerated timer
            // 1 adds in the second for the accelerated timer
            // the result is that while getting zapped time timer adds time. 
        if ((PlayNextAnimation <= llGetUnixTime( )) && (AnimationPlaying < NumberOfAnimations)){
                startAnimations(++AnimationPlaying);
        }
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
    if (rlvPresent == 1) {
        muzzleHandle = llListen(muzzleChannel,"",avatarKey,""); // *** should be avatarkey
        string rlvcommand = "@tplm=n,tploc=n,tplure=n," +          
            "showworldmap=n,showminimap=n,showloc=n," + 
            "fly=n,detach=n,edit=n,rez=n,redirchat:" + (string)muzzleChannel + "=add," +
            "detach:BGVisitor=force,attach:BGInmate=force";
        sayDebug(rlvcommand);
        llOwnerSay(rlvcommand);
    } else {
        sayDebug("sendRLVRestrictCommand but no RLV present");
    }
}

// chatshout=n,chatnormal=y,chatwhisper=n,shownames=n,sittp=n,fartouch=n,

sendRLVUnrestrictCommand() {
    if (rlvPresent == 1) {
        llOwnerSay("@clear,detach:BGInmate=force,attach:BGVisitor=force");
        llListenRemove(muzzleHandle); 
    }
}


// =================================
// Timer

// This timer controls how long the HUD stays active
// This works like a kitchen timer: "30 minutes from now"
// It has non-obvious states that need to be announced and displayed
integer HUDTimerInterval = 5; // 5 seconds ;for all timers
integer HUDTimeremaining = 1800; // seconds remaining on timer: half an hour by default
integer HUDTimerunning = 0; // 0 = stopped; 1 = running
integer HUDTimeStart = 1800; // seconds it was set to so we can set it again 
    // *** set to 20 for debug, 1800 for production

string HUDTimerDisplay() {
    // parameter: HUDTimeremaining global
    // returns: a string in the form of "1 Days 3 Hours 5 Minutes 7 Seconds"
    // or "(no timer)" if seconds is less than zero
    
    if (HUDTimeremaining <= 0) {
        return "";// "Timer not set."
    } else {

    // Calculate
    //llWhisper(0,"time_display received "+(string)seconds+" seconds."); // *** debug
    string display_time = ""; // "Unlocks in ";
    integer days = HUDTimeremaining/86400;
    integer hours;
    integer minutes;
    integer seconds;
    
    if (days > 0) {
        display_time += (string)days+" Days ";   
    }
    
    integer carry_over_hours = HUDTimeremaining - (86400 * days);
    hours = carry_over_hours / 3600;
    //if (hours > 0) {
        display_time += (string)hours+":"; // " Hours ";
    //}
    
    integer carry_over_minutes = carry_over_hours - (hours * 3600);
    
    minutes = carry_over_minutes / 60;
    //if (minutes > 0) {
        display_time += (string)minutes+":"; // " Minutes ";
    //}
    
    seconds = carry_over_minutes - (minutes * 60);
    
    //if (seconds > 0) {
        display_time += (string)seconds; //+" Seconds";
    //}
    
    //if (HUDTimerunning == 1) {
    //    display_time += " …";
    //} else {
    //    display_time += " .";
    //}    
    
    return display_time; 
    }
}

HUDTimerReset() {
    // reset the timer to the value previously set for it. init and finish countdown. 
    HUDTimeremaining = HUDTimeStart; 
    HUDTimerunning = 0; // timer is stopped
    //llWhisper(0,thisCell+" Timelock Has Been Cleared.");
}

HUDTimerSet(integer set_time) {
    // set the timer to the desired time, remember that time
    HUDTimeremaining = set_time; // set it to that 
    HUDTimeStart = set_time; // remember what it was set to
    // HUDTimerunning = 0; // timer is stopped *** fix bug 58. 
    //llWhisper(0,thisCell+" Timelock Has Been Set.");
}

HUDTimerRun() {
    // make the timer run. Init and finish countdown. 
    HUDTimerunning = 1; // timer is running
    llSetTimerEvent(5.0);
    //llWhisper(0,thisCell+" Timer has started.");
}

HUDTimerRestart() {
    if (HUDTimerunning == 1) {
        llSetTimerEvent(5.0);
    } else {
        llSetTimerEvent(0.0);
    }
}

HUDTimerStop() {
    // stop the timer. Nobody calls this ... yet. 
    // *** perhaps use this while prisoner is being schoked
    HUDTimerunning = 0; // timer is stopped
    //llWhisper(0,thisCell+" Timer has stopped.");
}


HUDTimerIncrement(integer interval) {
    HUDTimeremaining += interval;
    // *** use this to increase the time every time someone gets shocked for touching the box
    // perhaps ... HUDTimerIncrement(HUDTimeremaining / 10);
}

HUDTimer() {
    //llWhisper(0, "HUDTimerunning=" + (string)HUDTimerunning + " HUDTimeremaining=" + (string)HUDTimeremaining);
    if (HUDTimerunning == 1 && HUDTimeremaining <= HUDTimerInterval) {
        // time has run out...
        //llWhisper(0,thisCell+" has finished timelock. Opening.");
        sendRLVUnrestrictCommand();
        HudFunctionState = 0;
        registerWithDB(); // prisoner, off
        HUDTimerReset();
        setStateTitleAndColor();
    }   

    if (HUDTimerunning == 1) {
        // timer's on, door's closed, someone's in here
        HUDTimeremaining -= HUDTimerInterval;
        setStateTitleAndColor();
    }
}

// ***************************
// Safeword
SendSafewordInstructions() {
    if (SafewordChannel != 0) {
        sayDebug("remove SafewordChannel " + (string)SafewordChannel);
        llListenRemove(SafewordChannel);
    }
    SafewordChannel = (integer)llFrand(8999)+1000; 
    SafewordListen = llListen(SafewordChannel, "", avatarKey, "" );
    sayDebug("created new SafewordChannel " + (string)SafewordChannel);

    Safeword =(integer)llFrand(899999)+100000; // generate 6-digit number
            
    llOwnerSay("To deactivate the Prisoner HUD, say " + (string)Safeword + 
        " on channel " +  (string)SafewordChannel + " within 60 seconds.");
}

SafewordFailed() {
    llOwnerSay ("Wrong Safeword or time ran out.");
    llListenRemove(SafewordListen);
    SafewordChannel = 0;
    SafewordListen = 0;
    HUDTimerRestart();
}

SafewordSucceeded() {
    llListenRemove(SafewordListen);
    SafewordChannel = 0;
    SafewordListen = 0;
    sendRLVUnrestrictCommand();
    HudFunctionState = 0;
    setStateTitleAndColor();
    registerWithDB(); // prisoner, off
}


// =================================
// Events
default
{
    state_entry()
    {
        // this stuff does need to get done on rez so that it behaves correctly if rezzed not as an attachment
        sayDebug("state_entry");
        hudAttached = 0;
        rlvPresent = 0;
        HudFunctionState = 0;
        SafewordListen = 0;
        
        initAnimationQueue();
        llPreloadSound("electricshock");
        llSetPrimitiveParams([PRIM_COLOR,ALL_SIDES,white,1.0]); // make it white
        setStateTitleAndColor();

        sayDebug("state_entry done");
    }

     attach( key id )
     {
        if (id) {
            sayDebug("attach"); // *** debug

            hudAttached = 1;
            rlvPresent = 0;
            HudFunctionState = 0;
        
            primKey = llGetKey( );
            primKeyString = (string)primKey;
            sayDebug("primKey:" + (string)primKey); // *** debug

            avatarKey = id;
            avatarKeyString = (string)avatarKey;
            avatarName = llKey2Name(avatarKey);
            sayDebug("avatarKey:" + (string)avatarKey); // *** debug

            llSetPrimitiveParams([PRIM_COLOR,ALL_SIDES,green,1.0]); // make it green
            setStateTitleAndColor();
        
            generateChannels();
        
            string statusquery="version="+(string)RLVStatusChannel;
            sayDebug(statusquery); // *** debug
            llOwnerSay("@"+statusquery);
            llSetTimerEvent(60); 
            // "the timeout should be long enough, like 30 seconds to one minute 
            // in order to receive the automatic reply from the viewer." 

            registerWithDB();    // inmate, offline  
            llOwnerSay("Black Gazza" + hudTitle + " (development version). Click the HUD for a menu.");
            sayDebug("attach done"); // *** debug
        } else {
            sayDebug("attach but no ID"); // *** debug
            hudAttached = 0;
            HudFunctionState = 0;
            sendRLVUnrestrictCommand();
            registerWithDB();    // inmate, offline  
            sayDebug("attach but no ID done"); // *** debug
        }
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
        if (SafewordListen != 0) {
            // we are listening for a safeword, so all else loses priority
            // but this means the Safeword was allowed to time out. 
            SafewordFailed();
        } else if (RLVStatusListen != 0) {
            // we were asking local RLV status; this is the timeout
            llOwnerSay("Your SL viewer is not RLV-Enabled. You're missing out on all the fun!");
            rlvPresent = 0;
            llListenRemove(RLVStatusListen);
            RLVStatusListen = 0;
            HUDTimerRestart();
        } else if (MenuListen !=0) {
            // we were waiting for a memnu; this is the timeoit
            llListenRemove(MenuListen);
            MenuListen = 0;
            HUDTimerRestart();
        } else {
            // can only have come from an animation event
            handleAnimationQueue();
        } 
                   
        HUDTimer();
    }
    
    // listen to objects on the command channel, 
    // rlv status messages on the status channel, 
    // and menu commands on the menuc hannel
    listen( integer channel, string name, key id, string message )
    {
        sayDebug("listen channel:" + (string)channel + " key:" + (string) id + " message:"+ message);
        
        if (channel == muzzleChannel) {
            //sayDebug("muzzleChannel message:"+message);
            llSay(0,message);
        } 

        if (channel == SafewordChannel) {
            sayDebug("safeword:" + message);   // *** debug
            if (message == (string)Safeword) {
                SafewordSucceeded();
            } else {
                SafewordFailed();
            }
        }
        
        if (channel == CommandChannel) {
            sayDebug("command:" + message);   // *** debug
            integer atrlv = llSubStringIndex(message,"@");
            
            if ((atrlv >= 0) && (rlvPresent == 1)) {
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
                } else {}
                registerWithDB();
            } // if (atrlv >= 0)

            integer atbg = llSubStringIndex(message,"#") +1;
            if (atbg > 0) {
                string command = llGetSubString(message,atbg,-1);
                sayDebug("command=" + command);
                if (command = "zap") {
                    startAnimations(1);
                } else {}
            }  else {} // if (atbg >= 0)
            // never remove the commandChannel listen                       
        }
        
        if (channel == RLVStatusChannel) {
            sayDebug("RLV status:" + message);   // *** debug
            rlvPresent = 1;
            llListenRemove(RLVStatusListen);
            RLVStatusListen = 0;
        } 
        
        if (channel == MenuChannel) {
            sayDebug("menu:" + message);   // *** debug
            if (message == "Off") {
                sendRLVUnrestrictCommand();
                HudFunctionState = 0;
                registerWithDB(); // prisoner, off

            } else if (message == "On") {
                //generateChannels();  // This seems to hose things
                sendRLVRestrictCommand();
                HudFunctionState = 1;
                registerWithDB(); // prisoner, on
                
            } else if (message == "On Timer") {
                sendRLVRestrictCommand();
                HudFunctionState = 2;
                registerWithDB(); // prisoner, on
                HUDTimerRun();
                
            } else if (message == "On Remote") {
                HudFunctionState = -3;
                
            } else if (message == "Set Timer") {
                llMessageLinked(LINK_THIS, 1000, "TIMER MODE",id);
                
            } else if (message == "Safeword") {
                SendSafewordInstructions();
                
            } else if (message == "Register") {
                registerWithDB();    // what's this for? 
            } else if (message == "Bugger Off") {
                sayDebug("message:" + message + "- turning debug off");
                debugLevel = 0;
                sayDebug("debug is off");   // this message shoudl not happen
            } else if (message == "Debug On") {
                debugLevel = 1;
                sayDebug("message:" + message + "-  turning debug on");
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
            //sayDebug("http response:");
            //sayDebug(body);
            //sayDebug("---end");
        }
    }


    link_message(integer sender_num, integer sender_integer, string sender_string, key sender_key) {
        if (sender_integer == 1002) {
            if (sender_string == "") {
                HUDTimerReset();
            } else {
                HUDTimerSet((integer)sender_string);
            }
        }
    }
}
