// RLV.lsl
// RLV script for Black Gazza Collar 4
// Timberwoof Lupindo, June 2019
// version: 2020-04-10

// Sends locklevel status on link number 1400
// Receives menu commands on link number 1401
// Receives status requests on link number 1402
// Sends RLVstatus status on link number 1403

integer OPTION_DEBUG = 0;

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
string assetNumber = "P-00000";

integer RLVpresent;
string prisonerLockLevel;
integer RLVStatusChannel = 0;      // listen to itself for RLV responses; generated on the fly
integer RLVStatusListen = 0;

integer visionTimeout = 0;

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

string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
        }
    return result;
    }

sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
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

checkRLV(string why) {
    sayDebug("checkRLV("+why+")");
    if (llGetAttached() != 0) {
        llOwnerSay("Checking RLV version ("+why+").");
        haveAnimatePermissions = 0;
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        generateChannels();
        string statusquery="version="+(string)RLVStatusChannel;
        sayDebug("checkRLV statusquery:"+statusquery);
        llOwnerSay("@"+statusquery);
        // "the timeout should be long enough, like 30 seconds to one minute 
        // in order to receive the automatic reply from the viewer." 
        llSetTimerEvent(30); 
        // The response comes in event listen on channel RLVStatusChannel.
    }
}

sendRLVRestrictCommand(string level, key id) {
    // level can be Off Light Medium Heavy Hardcore
    string theSound = soundLatch;
    if (RLVpresent == 1) {
        prisonerLockLevel = level;
        sayDebug("sendRLVRestrictCommand("+prisonerLockLevel+")");
        llOwnerSay("@clear");
        string rlvcommand = ""; 
        if (prisonerLockLevel == "Off") {
            theSound = soundUnlatch;
            llInstantMessage(id, assetNumber + " has been unlocked."); 
        }else if (prisonerLockLevel == "Light") {
            rlvcommand = "@tplm=n,tploc=n,fly=n,detach=n";
            // tplure=y,edit=y,rez=y,chatshout=y,chatnormal=y,chatwhisper=y,shownames=y,sittp=y,fartouch=y
        } else if (prisonerLockLevel == "Medium") {
            rlvcommand = "@tplm=n,tploc=n,showworldmap=n,showminimap=n,showloc=y,fly=n,detach=n,sittp=n,fartouch=n";
            // tplure=y,edit=y,rez=y,chatshout=y,chatnormal=y,chatwhisper=y,shownames=y,
        } else if (prisonerLockLevel == "Heavy") {
            rlvcommand = "@tplm=n,tploc=n,tplure=n," +          
            "showworldmap=n,showminimap=n,showloc=n,setcam_avdistmax:2=n," +
            "fly=n,detach=n,edit=n,rez=n," +
            "chatshout=n,sittp=n,fartouch=n";
            // chatnormal=y,chatwhisper=y,
        } else if (prisonerLockLevel == "Hardcore") {
            rlvcommand = "@tplm=n,tploc=n,tplure=n," +          
            "showworldmap=n,showminimap=n,showloc=n,setcam_avdistmax:2=n," + 
            "fly=n,detach=n,edit=n,rez=n," +
            "chatshout=n,chatnormal=n,sittp=n,fartouch=n";
            // chatwhisper=y,
            llOwnerSay("You have been locked into Hardcore mode. There is no safeword. For release, you must ask a Guard to release you.");
        }
        llPlaySound(theSound, 1);
        if (rlvcommand != "") {
            sayDebug("sendRLVRestrictCommand: "+rlvcommand);
            llOwnerSay(rlvcommand);
        }
        sendJSON("rlvPresent", "1", "");
        sendJSON("prisonerLockLevel", prisonerLockLevel, "");
        sendJSON("Speech", "resetRenamer", "");
        llOwnerSay("RLV lock level has been set to "+prisonerLockLevel);
    } else {
        sayDebug("sendRLVRestrictCommand but no RLV present");
        sendJSON("rlvPresent", "0", "");
        sendJSON("prisonerLockLevel", "Off", "");
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

SafewordSucceeded(key id) {
    llShout(0, "Safeword Succeeded. Removing RLV restrictions.");
    llListenRemove(SafewordListen);
    SafewordChannel = 0;
    SafewordListen = 0;
    sendRLVRestrictCommand("Off", id);
}
 
// =====================
// Zap

// got menu command: play charge sound and ask for zap permission
startZap(string zapLevel, key who) {
    if (llSubStringIndex("LowMedHig", zapLevel) >= 0) {
        
        // announce in chat what's happening
        string name;
        string description = llList2String(llGetObjectDetails(who, [OBJECT_DESC]),0);
        if (description == "") {
            // if it's an avatar, get its first name
            string zapName = llGetDisplayName(who);
            list namesList = llParseString2List(zapName, [" "], [""]);
            name = llList2String(namesList, 0);
        } else {
            // if it's an object, get its name
            name = llList2String(llGetObjectDetails(who, [OBJECT_NAME]),0);
        }       
        llWhisper(0, name+" zaps the inmate.");
        
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
            llSleep(2);
        } else if (zapLevel == "Hig") {
            llSleep(4);
        }
        llStopSound();
        
        if (haveAnimatePermissions) {
            stop_anims();
            llStartAnimation("Stand");
        }
    }
    llSleep(1);
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


restrictVision(integer enabled) {
    if (RLVpresent == 1) {
        string rlvcommand;
        string message;
        if (enabled) {
            rlvcommand = "@shownames_sec=n,showhovertextall=n,"+
            // setenv_daytime:0.0=force,
            "setenv_hazedensity:1.9=force,setenv_densitymultiplier:0.5=force,setenv_distancemultiplier:1.8=force,setenv_hazehorizon:0.2=force,"+
            "getenv_hazedensity=42,getenv_densitymultiplier=42,getenv_distancemultiplier=42,getenv_hazehorizon=42";
            
                //"setenv_scenegamma:0.1=force"; // 0-10; 10 is bright this one's good
                //"camdrawmin:5=n,camdrawmax:10=n,camdrawalphamin:1.0=n,camdrawalphamax:0.0=n";
            message = "You are being punished for a transgression. Your collar has injected you with a drug that will restrict your vision for some time.";
            visionTimeout = 1;
            llSetTimerEvent(15);
        } else {
            rlvcommand = "@shownames_sec=y,showhovertextall=y,setenv_daytime:-1.0=force";//+
                //"setenv_hazedensity:0.0=force"; // 0-1
                //"setenv_scenegamma:1.0=force";
                //"camdrawmin:5=y,”camdrawmax:10=y,camdrawalphamin:1.0=y,camdrawalphamax:0.0=y";
            message = "The vision restriction drug has worn off.";
            visionTimeout = 0;
        }
        sayDebug("sendRLVRestrictCommand: "+rlvcommand);
        llOwnerSay(rlvcommand);
        llOwnerSay(message);
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
        sendRLVRestrictCommand("Off", llGetOwner());
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
    state_entry() // reset
    {
        sayDebug("state_entry");
        llStopSound();
        RLVpresent = 0;
        prisonerLockLevel = "Off";
        HudFunctionState = 0;
        SafewordListen = 0;
        llPreloadSound(soundCharging);
        llPreloadSound(soundZapLoop);
        if (llGetAttached() != 0) {
            checkRLV("state_entry");
            llListen(ZapChannel, "", "", "");
        }
        
        llListen(42, "", "", "");
        
        sayDebug("state_entry done");
    }

     attach(key id)
     {
        if (id) {
            sayDebug("attach");
            hudAttached = 1;
            HudFunctionState = 0;
            checkRLV("attach");
            llListen(ZapChannel, "", "", "");
            registerWithDB();    // inmate, offline  
            sayDebug("attach done");
        } else {
            sayDebug("detach");
            hudAttached = 0;
            HudFunctionState = 0;
            sendRLVRestrictCommand("Off", llGetOwner());
            registerWithDB();    // inmate, offline  
            sayDebug("detach done");
        }
    }

    run_time_permissions(integer permissions)
    {
        sayDebug("run_time_permissions");
        if (permissions & PERMISSION_TRIGGER_ANIMATION) {
            haveAnimatePermissions = 1;
        }
    }
    
    link_message(integer sender_num, integer num, string json, key id ){ 
    // We listen in on link messages and pick the ones we're interested in:
    // RLV Register
    // RLV zapPrisoner
    // RLV <lockLevel>

        assetNumber = getJSONstring(json, "assetNumber", assetNumber);

        string RLVCommand = getJSONstring(json, "RLV", "");
        if (RLVCommand != "") {
            sayDebug("link_message "+RLVCommand);
            
            if (llSubStringIndex("Off Light Medium Heavy Hardcore", RLVCommand) > -1) {
                sendRLVRestrictCommand(RLVCommand, id);
            } else if (RLVCommand == "Safeword") {
                SendSafewordInstructions();
            }
            
            if (llSubStringIndex(RLVCommand, "Zap") > -1) {
                startZap(llGetSubString(RLVCommand, 4,6), id);
            }
            
            if (RLVCommand == "Vision") {
                restrictVision(1);
            }
            
            if (llSubStringIndex(RLVCommand, "Register") > -1) {
                checkRLV("link request");
            }
            

        // timer sent set or reset
        } else if (num == 3002) {
            if (json == "") {
                lockTimerReset();
            } else {
                lockTimerSet((integer)json);
            }
        }
   }


    // listen to objects on the command channel, 
    // rlv status messages on the status channel, 
    // and menu commands on the menuc hannel
    listen( integer channel, string name, key id, string message )
    {
        sayDebug("listen channel:" + (string)channel + " key:" + (string) id + " message:"+ message);
        
        // safeword system
        if (channel == SafewordChannel && id == llGetOwner()) {
            sayDebug("safeword:" + message);   
            if (message == (string)Safeword) {
                SafewordSucceeded(id);
            } else {
                SafewordFailed();
            }
        }
        
        // Response from RLV system in the viewer.
        // We just restarted or logged back in. 
        if (channel == RLVStatusChannel) {
            sayDebug("status:" + message);   
            RLVpresent = 1;
            llListenRemove(RLVStatusListen);
            sendJSON("rlvPresent", "1", "");
            sendRLVRestrictCommand(prisonerLockLevel, id);
            RLVStatusListen = 0;
            lockTimerRestart(); // why?
            llOwnerSay(message+"; RLV is present.");
        }
        
        // request on zapchannel
        if (channel == ZapChannel) {
            sayDebug("listen ZapChannel");   
            if (message == (string)llGetOwner()) {
                startZap("Low", id);
            }
        }
        
        if (channel==42){
            llOwnerSay(message);
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
            sendJSON("rlvPresent", "0", "");
            sendJSON("prisonerLockLevel", "Off", "");
        } else if (visionTimeout > 0) {
            restrictVision(0);
        }
        lockTimer();
    }

}
