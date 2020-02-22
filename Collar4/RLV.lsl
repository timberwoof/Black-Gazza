// RLV.lsl
// RLV script for Black Gazza Collar 4
// Timberwoof Lupindo, June 2019
// version: 2020-02-22

// Sends locklevel status on link number 1400
// Receives menu commands on link number 1401
// Receives status requests on link number 1402
// Sends RLVstatus status on link number 1403

integer OPTION_DEBUG = 0;

string hudTitle = "BG Inmate Collar4 Alpha 0"; 

integer SafewordChannel = 0;
integer SafewordListen = 0;
integer Safeword = 0;
integer ZapChannel = -106969;

integer hudAttached = 0;    //0 = unattached; 1 = attached
integer HudFunctionState = 0;
// -3 = off with remote turn-on
// 0 = off
// 1 = on with off switch
// 2 = on with timer
// 3 = on with remote turn-off
string avatarKeyString;
string avatarName;
key primKey;
string primKeyString;

integer RLVpresent;
string RLVlevel;
integer RLVStatusChannel = 0;      // listen to itself for RLV responses; generated on the fly
integer RLVStatusListen = 0;

key soundCharging = "cfe72dda-9b3f-2c45-c4d6-fd6b39d282d1";
key soundShock = "4546cdc8-8682-6763-7d52-2c1e67e8257d";
key soundZapLoop = "27a18333-a425-30b1-1ab6-c9a3a3554903";
key soundLatch = "cd386eb2-037a-e774-04d1-fd8161ffc2ba";
key soundUnlatch="2f327bf4-a07f-2314-58bc-9443073a3065";
integer haveAnimatePermissions = 0;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("RLV:"+message);
    }
}

generateChannels() {
    sayDebug("generateChannels");
    if (RLVStatusChannel != 0) {
        sayDebug("remove RLVStatusChannel " + (string)RLVStatusChannel);
        llListenRemove(RLVStatusChannel);
    }
    RLVStatusChannel = (integer)llFrand(8999)+1000; // generate a sessin RLV status channel
    sayDebug("created new RLVStatusChannel " + (string)RLVStatusChannel);
    RLVStatusListen = llListen(RLVStatusChannel, "", llGetOwner(), "" );
        // listen on the newly generated rlv status channel
}

// =================================
// Communication with database
key httprequest;

registerWithDB() {
    sayDebug("registerWithDB");
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
    if (RLVpresent == 1) {
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
        "commandChannel=0";// + (string)CommandChannel;
    }
    
    list parameters = [HTTP_METHOD, "GET",
        HTTP_MIMETYPE,"text/plain;charset=utf-8"];
    string body = "";
    //sayDebug(url); 
    //httprequest = llHTTPRequest(url, parameters, body );
}

checkRLV() {
    sayDebug("checkRLV");
    if (llGetAttached() != 0) {
        llOwnerSay("Checking RLV version.");
        haveAnimatePermissions = 0;
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        generateChannels();
        string statusquery="version="+(string)RLVStatusChannel;
        sayDebug(statusquery);
        llOwnerSay("@"+statusquery);
        llSetTimerEvent(30); 
    }
        // "the timeout should be long enough, like 30 seconds to one minute 
        // in order to receive the automatic reply from the viewer." 
}

sendRLVRestrictCommand(string level) {
    // level can be Off Light Medium Heavy Hardcore
    string theSound = soundLatch;
    if (RLVpresent == 1) {
        RLVlevel = level;
        sayDebug("sendRLVRestrictCommand("+RLVlevel+")");
        llOwnerSay("@clear");
        string rlvcommand = ""; 
        if (RLVlevel == "Off") {
            theSound = soundUnlatch;
        }else if (RLVlevel == "Light") {
            rlvcommand = "@tplm=n,tploc=n,showworldmap=y,showminimap=y,showloc=y,fly=n,detach=n";
            // tplure=y,edit=y,rez=y,chatshout=y,chatnormal=y,chatwhisper=y,shownames=y,sittp=y,fartouch=y
        } else if (RLVlevel == "Medium") {
            rlvcommand = "@tplm=n,tploc=n,showworldmap=n,showminimap=n,showloc=y,fly=n,detach=n,sittp=n,fartouch=n";
            // tplure=y,edit=y,rez=y,chatshout=y,chatnormal=y,chatwhisper=y,shownames=y,
        } else if (RLVlevel == "Heavy") {
            rlvcommand = "@tplm=n,tploc=n,tplure=n," +          
            "showworldmap=n,showminimap=n,showloc=n,setcam_avdistmax:2=n," +
            "fly=n,detach=n,edit=n,rez=n," +
            "chatshout=n,sittp=n,fartouch=n";
            // chatnormal=y,chatwhisper=y,
        } else if (RLVlevel == "Hardcore") {
            rlvcommand = "@tplm=n,tploc=n,tplure=n," +          
            "showworldmap=n,showminimap=n,showloc=n,setcam_avdistmax:2=n," + 
            "fly=n,detach=n,edit=n,rez=n," +
            "chatshout=n,chatnormal=n,sittp=n,fartouch=n";
            // chatwhisper=y,
        }
        sayDebug(rlvcommand);
        llPlaySound(theSound, 1);
        llOwnerSay(rlvcommand);
        llMessageLinked(LINK_THIS, 1400, RLVlevel, "");
        llMessageLinked(LINK_THIS, 2001, "", "");
        llOwnerSay("RLV lock level has been set to "+RLVlevel);
    } else {
        sayDebug("sendRLVRestrictCommand but no RLV present");
        llMessageLinked(LINK_THIS, 1403, "NoRLV", "");
        llMessageLinked(LINK_THIS, 2001, "", "");
    }
}

// ***************************
// Safeword
SendSafewordInstructions() {
    sayDebug("SendSafewordInstructions");
    if (SafewordChannel != 0) {
        sayDebug("remove SafewordChannel " + (string)SafewordChannel);
        llListenRemove(SafewordChannel);
    }
    SafewordChannel = (integer)llFrand(8999)+1000; 
    SafewordListen = llListen(SafewordChannel, "", llGetOwner(), "" );
    sayDebug("created new SafewordChannel " + (string)SafewordChannel);

    Safeword =(integer)llFrand(899999)+100000; // generate 6-digit number
            
    llOwnerSay("To unlock your BG Collar, type " + (string)Safeword + 
        " on channel " +  (string)SafewordChannel + " within 60 seconds.");
}

SafewordFailed() {
    llOwnerSay ("Wrong Safeword or time ran out.");
    llListenRemove(SafewordListen);
    SafewordChannel = 0;
    SafewordListen = 0;
    //lockTimerRestart();
}

SafewordSucceeded() {
    llShout(0, "Safeword Succeeded. Removing RLV restrictions.");
    llListenRemove(SafewordListen);
    SafewordChannel = 0;
    SafewordListen = 0;
    sendRLVRestrictCommand("Off");
}
 
// =====================
// Zap

// got menu command: play charge sound and ask for zap permission
startZap(string zapLevel, string who) {
    llWhisper(0, who+" zaps the inmate.");
    llPlaySound(soundCharging, 1.0);
    llSleep(1.5);
    llLoopSound(soundZapLoop, 1.0);
    if (haveAnimatePermissions) {
        stop_anims();
        llStartAnimation("Zap");
    }
    if (zapLevel == "Low") {
        llSleep(1);
    } else if (zapLevel == "Med") {
        llSleep(4);
    } else if (zapLevel == "Hig") {
        llSleep(12);
    }
    llStopSound();
    if (haveAnimatePermissions) {
        stop_anims();
        llStartAnimation("Stand");
    }
    llSleep(1); // Some people reported that the sound didn't stop looping.
    llStopSound();
}

stop_anims()
{
    list animationList = llGetAnimationList(llGetOwner());
    integer lsize = llGetListLength(animationList);
    integer i;
    for ( i = 0; i < lsize; i++ )
    {
        llStopAnimation(llList2Key(animationList, i));
    }
}


// =================================
// Lock Timer

// This timer controls how long the lock stays active
// This works like a kitchen timer: "30 minutes from now"
// It has non-obvious states that need to be announced and displayed
integer lockTimerInterval = 5; // 5 seconds ;for all timers
integer lockTimeremaining = 1800; // seconds remaining on timer: half an hour by default
integer lockTimerunning = 0; // 0 = stopped; 1 = running
integer HUDTimeStart = 20; // seconds it was set to so we can set it again 
    // *** set to 20 for debug, 1800 for production

string lockTimerDisplay() {
    // parameter: lockTimeremaining global
    // returns: a string in the form of "1 Days 3 Hours 5 Minutes 7 Seconds"
    // or "(no timer)" if seconds is less than zero
    
    if (lockTimeremaining <= 0) {
        return "";// "Timer not set."
    } else {

    // Calculate
    sayDebug("lockTimerDisplay received "+(string)lockTimeremaining+" seconds."); 
    string display_time = ""; // "Unlocks in ";
    integer days = lockTimeremaining/86400;
    integer hours;
    integer minutes;
    integer seconds;
    
    if (days > 0) {
        display_time += (string)days+" Days ";   
    }
    
    integer carry_over_hours = lockTimeremaining - (86400 * days);
    hours = carry_over_hours / 3600;
    display_time += (string)hours+":"; // " Hours ";
    
    integer carry_over_minutes = carry_over_hours - (hours * 3600);
    minutes = carry_over_minutes / 60;
    display_time += (string)minutes+":"; // " Minutes ";
    
    seconds = carry_over_minutes - (minutes * 60);
    
    display_time += (string)seconds; //+" Seconds";    
    return display_time; 
    }
}

lockTimerReset() {
    // reset the timer to the value previously set for it. init and finish countdown. 
    lockTimeremaining = HUDTimeStart; 
    lockTimerunning = 0; // timer is stopped
    llOwnerSay("Timelock Has Been Cleared.");
}

lockTimerSet(integer set_time) {
    // set the timer to the desired time, remember that time
    lockTimeremaining = set_time; // set it to that 
    HUDTimeStart = set_time; // remember what it was set to
    llOwnerSay("Timelock has been set to "+lockTimerDisplay());
}

lockTimerRun() {
    // make the timer run. Init and finish countdown. 
    lockTimerunning = 1; // timer is running
    llSetTimerEvent(5.0);
    llOwnerSay("Timer has started.");
}

lockTimerRestart() {
    if (lockTimerunning == 1) {
        llSetTimerEvent(5.0);
    } else {
        llSetTimerEvent(0.0);
    }
}

lockTimerStop() {
    // stop the timer. Nobody calls this ... yet. 
    // *** perhaps use this while prisoner is being schoked
    lockTimerunning = 0; // timer is stopped
    llOwnerSay("Timer has stopped.");
}


lockTimerIncrement(integer interval) {
    lockTimeremaining += interval;
    // *** use this to increase the time every time someone gets shocked for touching the box
    // perhaps ... lockTimerIncrement(lockTimeremaining / 10);
}

lockTimer() {
    //llWhisper(0, "lockTimerunning=" + (string)lockTimerunning + " lockTimeremaining=" + (string)lockTimeremaining);
    if (lockTimerunning == 1 && lockTimeremaining <= lockTimerInterval) {
        // time has run out...
        llOwnerSay("Timelock has ended. Releasing.");
        sendRLVRestrictCommand("Off");
        HudFunctionState = 0;
        registerWithDB(); // prisoner, off
        lockTimerReset();
    }   

    if (lockTimerunning == 1) {
        // timer's on, door's closed, someone's in here
        lockTimeremaining -= lockTimerInterval;
    }
}


default
{
    state_entry()
    {
        sayDebug("state_entry");
        llStopSound();
        RLVpresent = 0;
        RLVlevel = "Off";
        HudFunctionState = 0;
        SafewordListen = 0;
        checkRLV();
        llPreloadSound(soundCharging);
        llPreloadSound(soundZapLoop);
        if (llGetAttached() != 0) {
            checkRLV();
        }
        llListen(ZapChannel, "", "", "");
        sayDebug("state_entry done");
    }

     attach(key id)
     {
        if (id) {
            sayDebug("attach");
            hudAttached = 1;
            RLVpresent = 0;
            HudFunctionState = 0;
            checkRLV();
            registerWithDB();    // inmate, offline  
            sendRLVRestrictCommand(RLVlevel);
            sayDebug("attach done");
        } else {
            sayDebug("attach but no ID");
            hudAttached = 0;
            HudFunctionState = 0;
            sendRLVRestrictCommand("Off");
            sendRLVRestrictCommand("NoRLV");
            registerWithDB();    // inmate, offline  
            sayDebug("attach but no ID done");
        }
    }

    run_time_permissions(integer permissions)
    {
        sayDebug("run_time_permissions");
        if (permissions & PERMISSION_TRIGGER_ANIMATION) {
            haveAnimatePermissions = 1;
        }
    }
    
    link_message( integer sender_num, integer num, string message, key id ){ 
    // We listen in on link messages and pick the ones we're interested in
        if (num == 1401) {
            if (llSubStringIndex("Off Light Medium Heavy Hardcore", message) > -1) {
                sayDebug("link_message "+(string)num+" "+message);
                sendRLVRestrictCommand(message);
            } else if (message == "Safeword") {
                SendSafewordInstructions();
            }
        } else if (num == 1402) { // status request
            sayDebug("link_message sending RLVlevel:"+RLVlevel);
            if (RLVpresent) {
                llMessageLinked(LINK_THIS, 1403, "YesRLV", "");
            } else {
                llMessageLinked(LINK_THIS, 1403, "NoRLV", "");
            }
            llMessageLinked(LINK_THIS, 1400, RLVlevel, "");
        } else if (num == 1301) {
            // command message is like "Zap Low" 
            startZap(llGetSubString(message, 4,6), llKey2Name(id));
        } else if (num == 3002) {
            if (message == "") {
                lockTimerReset();
            } else {
                lockTimerSet((integer)message);
            }
        }
   }


    // listen to objects on the command channel, 
    // rlv status messages on the status channel, 
    // and menu commands on the menuc hannel
    listen( integer channel, string name, key id, string message )
    {
        sayDebug("listen channel:" + (string)channel + " key:" + (string) id + " message:"+ message);
        
        if (channel == SafewordChannel && id == llGetOwner()) {
            sayDebug("safeword:" + message);   
            if (message == (string)Safeword) {
                SafewordSucceeded();
            } else {
                SafewordFailed();
            }
        }
        
        if (channel == RLVStatusChannel) {
            sayDebug("status:" + message);   
            RLVpresent = 1;
            llListenRemove(RLVStatusListen);
            llMessageLinked(LINK_THIS, 1403, "YesRLV", "");
            llMessageLinked(LINK_THIS, 1400, RLVlevel, "");
            RLVStatusListen = 0;
            lockTimerRestart(); // why?
            llOwnerSay(message+"; RLV is present.");
        }
        
        if (channel == ZapChannel) {
            sayDebug("listen ZapChannel");   
            if (message == (string)llGetOwner()) {
                startZap("Low", name);
            }
        }
    }


    timer()
    {
        if (SafewordListen != 0) {
            sayDebug("timer SafewordListen");   
            // we are listening for a safeword, so all else loses priority
            // but this means the Safeword was allowed to time out. 
            SafewordFailed();
        } else if (RLVStatusListen != 0) {
            sayDebug("timer RLVStatusListen");   
            // we were asking local RLV status; this is the timeout
            llOwnerSay("Your SL viewer is not RLV-Enabled. You're missing out on all the fun!");
            RLVpresent = 0;
            llListenRemove(RLVStatusListen);
            RLVStatusListen = 0;
            lockTimerRestart();
            llMessageLinked(LINK_THIS, 1403, "NoRLV", "");
            llMessageLinked(LINK_THIS, 1400, "Off", "");
        } 
        lockTimer();
    }

}
