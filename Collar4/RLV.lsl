// RLV.lsl
// RLV script for Black Gazza Collar 4
// Timberwoof Lupindo, June 2019
// version: 2021-03-07

// controls Relay
// manages Zap
// manages ACS interference
// manages OAD/Lovense vibrator toys
// Sends OAD Lovense commands to channel -20200610

integer OPTION_DEBUG = 0;

integer SafewordChannel = 0;
integer SafewordListen = 0;
integer Safeword = 0;

integer ZapChannel = -106969;
float ZapTimeCharge = 1.5;
float ZapTimeLow = 2;
float ZapTimeMed = 4;
float ZapTimeHigh = 8;

integer batteryCharge = 0;

integer ACSInterferenceChannel = 360;

integer OADSendChannel = -20200610;
string OAD_VIBE = "VIBE";
string OAD_ALL = "ALL";

integer HudFunctionState = 0;
// -3 = off with remote turn-on
// 0 = off
// 1 = on with off switch
// 2 = on with timer
// 3 = on with remote turn-off
string avatarKeyString;
string avatarName;
string assetNumber = "P-00000";

integer rlvPresent;
string lockLevel;
integer RLVStatusChannel = 0;      // listen to itself for RLV responses; generated on the fly
integer RLVStatusListen = 0;

integer visionTimeout = 0;
integer zapTimeout = 0;

key soundCharging = "5a10d96a-b51f-5f34-5cc9-affa87308e3e";
key soundShock = "4546cdc8-8682-6763-7d52-2c1e67e8257d";
key soundZapLoop = "27a18333-a425-30b1-1ab6-c9a3a3554903";
key soundLatch = "cd386eb2-037a-e774-04d1-fd8161ffc2ba";
key soundUnlatch="2f327bf4-a07f-2314-58bc-9443073a3065";
integer haveAnimatePermissions = 0;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("RLV: "+message);
    }
}

integer getJSONinteger(string jsonValue, string jsonKey, integer valueNow){
    integer result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = (integer)value;
        }
    return result;
    }

string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
        }
    return result;
    }

sendJSONinteger(string jsonKey, integer value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, (string)value]), avatarKey);
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
    RLVStatusChannel = (integer)llFrand(8999)+1000; // generate a session RLV status channel
    sayDebug("created new RLVStatusChannel " + (string)RLVStatusChannel);
    RLVStatusListen = llListen(RLVStatusChannel, "", llGetOwner(), "");
    // listen on the newly generated rlv status channel
}

// =================================
// Communication with database
key httprequest;


// =================================
// RLV communication
checkRLV(string why) {
    sayDebug("checkRLV("+why+")");
    if (llGetAttached() != 0) {
        llOwnerSay("Checking RLV version.");
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
    if (rlvPresent == 1) {
        lockLevel = level;
        sayDebug("sendRLVRestrictCommand(\""+lockLevel+"\")");
        llOwnerSay("@clear"); // this kills the speech settings
        string rlvcommand = ""; 
        if (lockLevel == "Off") {
            theSound = soundUnlatch;
        }else if (lockLevel == "Light") {
            rlvcommand = "@tplm=n,tploc=n,fly=n,detach=n";
            // tplure=y,edit=y,rez=y,chatshout=y,chatnormal=y,chatwhisper=y,shownames=y,sittp=y,fartouch=y
        } else if (lockLevel == "Medium") {
            rlvcommand = "@tplm=n,tploc=n,showworldmap=n,showminimap=n,showloc=y,fly=n,detach=n,sittp=n,fartouch=n";
            // tplure=y,edit=y,rez=y,chatshout=y,chatnormal=y,chatwhisper=y,shownames=y,
        } else if (lockLevel == "Heavy") {
            rlvcommand = "@tplm=n,tploc=n,tplure=n," +          
            "showworldmap=n,showminimap=n,showloc=n,setcam_avdistmax:2=n," +
            "fly=n,detach=n,edit=n,rez=n," +
            "chatshout=n,sittp=n,fartouch=n";
            // chatnormal=y,chatwhisper=y,
            llOwnerSay("You have been locked into Heavy mode. To Safeword, you must use the collar's Safeword function.");
        } else if (lockLevel == "Hardcore") {
            rlvcommand = "@tplm=n,tploc=n,tplure=n," +          
            "showworldmap=n,showminimap=n,showloc=n,setcam_avdistmax:2=n," + 
            "fly=n,detach=n,edit=n,rez=n," +
            "chatshout=n,chatnormal=n,sittp=n,fartouch=n";
            // chatwhisper=y,
            llOwnerSay("You have been locked into Hardcore mode. There is no safeword. For release, you must ask a Guard to release you.");
        }
        sayDebug("sendRLVRestrictCommand llPlaySound("+theSound+", 1.0);");
        llPlaySound(theSound, 1.0);
        if (rlvcommand != "") {
            sayDebug("sendRLVRestrictCommand: llOwnerSay(\""+rlvcommand+"\")");
            llOwnerSay(rlvcommand);
        }
        sendJSON("rlvPresent", "1", "");
        sendJSON("lockLevel", lockLevel, "");
        llOwnerSay("RLV lock level has been set to "+lockLevel+".");
    } else {
        sayDebug("sendRLVRestrictCommand was called but no RLV present");
        sendJSON("rlvPresent", "0", "");
        sendJSON("lockLevel", "Off", "");
    }
}

// ***************************
// ACS Interference
processACSInterference(string name, string message) {
        // interferenceCodes = "PMSNCY";
        // interferenceNames = ["Power","Motor","Speaker","Sensory","Cognitive","Memory"];

        list commands = llCSV2List(message);
        string acs = llList2String(commands,0);
        string interfere = llList2String(commands,1);
        
        if ((acs == "ACS") & (interfere == "interfere"))
        {
            // parse the ACS interference command
            //string type = llList2String(commands,2); //  type:"+type+
            integer time = llList2Integer(commands,3);
            integer strength = llList2Integer(commands,4);
            sayDebug("processACSInterference time:"+(string)time+" strength:"+(string)strength);

            // Scale ACS strentgh to OAD strength.
            // ACS interference strength ranges 0-9
            // OAS buzz strength ranges 0-20
            // 20 / 9 = 2.222, so 0:0 1:3 2:5 3:7 4:9 5:12 6:14 7:16 8:18 9:20
            strength = llCeil(strength * 2.222); 
            sayDebug("strength:"+(string)strength);
            
            // Limit buzz time to 10 seconds.
            // Adjust strength appropriately.
            if (time > 10) {
                strength = llCeil(strength * time / 10.0);
                sayDebug("strength recalculated by time to:"+(string)strength);
                time = 10;
                }
                
            // limit strength to max
            if (strength > 20) {
                strength = 20;
                sayDebug("strength capped:"+(string)strength);
                }
                
            // buzz the wearer
            sendOADCommand(OAD_VIBE, strength, OAD_ALL, time);
            llSleep(time);
            sendOADCommand(OAD_VIBE, 0, OAD_ALL, 0);
        } else {
            llSay(0,name+" transmitted on ACS Interference Channel.");
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

string firstname(key who) {
    string zapName = llGetDisplayName(who);
    list namesList = llParseString2List(zapName, [" "], [""]);
    return llList2String(namesList, 0);
}
 
// =====================
// Zap
integer zapTimerInterval = 5; // 5 seconds ;for all timers
integer zapTimeremaining ; // seconds remaining on timer: half an hour by default
integer zapTimerunning = 0; // 0 = stopped; 1 = running

list zapLevelNames = ["Low", "Med", "Hig"];
list zapTimes = [2.0, 4.0, 8.0]; // how many seconds zap lasts
list zapDischarges = [3600, 7200, 14400]; // how much battery time zap requires/discharges
list zapTimeouts = [120, 240, 960]; // timeout before you can zap again

// got menu command: play charge sound and ask for zap permission
startZap(string zapLevel, key who) {
    sayDebug("startZap("+zapLevel+")");
    integer zapindex = llListFindList(zapLevelNames, [zapLevel]);
    if ( (zapindex >= 0) & (zapTimerunning == 0))
    {
        // announce in chat what's happening
        string name;
        string objectDescription = llList2String(llGetObjectDetails(who, [OBJECT_DESC]),0);
        if (objectDescription != "") {
            // if it's an object, get its name
            name = llList2String(llGetObjectDetails(who, [OBJECT_NAME]),0);
        } else if (who != llGetOwner()) {
            // if it's an avatar, get its first name
            name = firstname(who);
        } else {
            name = assetNumber + "'s collar";
        }
        
        // calculate time of zap
        integer zapDischarge = llList2Integer(zapDischarges, zapindex);
        float zapTime = llList2Float(zapTimes, zapindex);
        if (batteryCharge < zapDischarge) {
            zapTime = zapTime * batteryCharge / zapDischarge;
        }

        if (zapTime > 0.1) {
            llWhisper(0, name + " zaps the inmate.");
        
            sayDebug("startZap charging up");
            OADStartBuzz();
            llPlaySound(soundCharging, 1.0);
            llSleep(1.5);
            
            sayDebug("startZap zapping("+zapLevel+")");
            OADBuzz(zapLevel);
            llLoopSound(soundZapLoop, 1.0);
            if (haveAnimatePermissions) {
                llStartAnimation("Zap");
            }
        
            llSleep(zapTime);
            sendJSONinteger("Discharge", zapDischarge, "");
            zapTimeremaining = llList2Integer(zapTimeouts, zapindex);
        
            sayDebug("startZap llStopSound();");
            llStopSound();
            if (haveAnimatePermissions) {
                llStopAnimation("Zap");
            }
        } else {
            sayDebug("Not enough charge for a zap.");
        }
    
    }
    llSleep(1);
    llStopSound();
    zapTimerunning = 0;
    llSetTimerEvent(zapTimerInterval);
}

restrictZap(integer zapLockout) {
    zapTimeout = 1;
    // needs to set up time when this timer runs out
    // it must coexist with the lock timer
}

sendOADCommand(string command, integer level, string toy, integer time){
    //AVIKEY~VIBE~(LEVEL)~(TOY)~(TIME)
    // command: VIBE, VIBE1, VIBE2
    // level: 0-20
    // toy: ALL, EDGE, HUSH, NORA, etc
    // time: seconds
    string command = (string)llGetOwner() + "~VIBE~" + (string)level + "~ALL~" + (string)time;
    sayDebug("sendOADCommand:"+command);
    llSay(OADSendChannel,command);
}

OADStartBuzz() {
    sayDebug("OADStartBuzz");
    sendOADCommand(OAD_VIBE, 5, OAD_ALL, (integer)ZapTimeCharge);
    }

OADBuzz(string level){
    sayDebug("OADBuzz:"+level);
    list zaplevels = ["Low","Med","Hig"];
    list buzzLevels = [10, 15, 20];
    list buzzTimes = [ZapTimeLow, ZapTimeMed, ZapTimeHigh];
    integer index = llListFindList(zaplevels,[level]);
    integer buzzLevel = llList2Integer(buzzLevels, index);
    integer buzzTime = llList2Integer(buzzTimes, index);
    sendOADCommand(OAD_VIBE, buzzLevel, OAD_ALL, buzzTime);
}

restrictVision(integer enabled) {
    sayDebug("restrictVision");
    if (rlvPresent == 1) {
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
            llSetTimerEvent(60);
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

default
{
    state_entry() // reset
    {
        sayDebug("state_entry attachPoint:"+(string)llGetAttached());
        llStopSound();
        rlvPresent = 0;
        lockLevel = "Off";
        HudFunctionState = 0;
        SafewordListen = 0;
        llPreloadSound(soundCharging);
        llPreloadSound(soundZapLoop);
        if (llGetAttached() != 0){
            checkRLV("state_entry");
            llListen(ZapChannel, "", "", "");
            llListen(ACSInterferenceChannel, "", "", "");
        }
        sayDebug("state_entry done");
    }

     attach(key id)
     {
        if (id) {
            sayDebug("attach(id) attachPoint:"+(string)llGetAttached());
            HudFunctionState = 0;
            checkRLV("state_entry");
            llListen(ZapChannel, "", "", "");
            sayDebug("attach done");
        } else {
            sayDebug("attach(NULL_KEY) or detach");
            HudFunctionState = 0;
            sendRLVRestrictCommand("Off", llGetOwner());
            sayDebug("attach or detach done");
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
        
        batteryCharge = getJSONinteger(json, "batteryCharge", batteryCharge); // Seconds

        string RLVCommand = getJSONstring(json, "RLV", "");
        if (RLVCommand != "") {
            sayDebug("link_message (\""+RLVCommand+"\")");
            
            if (llSubStringIndex("Off Light Medium Heavy Hardcore", RLVCommand) > -1) {
                sendRLVRestrictCommand(RLVCommand, id);
            } else if (RLVCommand == "Safeword") {
                SendSafewordInstructions();
            }
            
            if (llSubStringIndex(RLVCommand, "Zap") > -1) {
                startZap(llGetSubString(RLVCommand, 4,6), id);
            }
            
            if (llSubStringIndex(RLVCommand, "Buzz") > -1) {
                OADBuzz("Med");
            }
            
            //if (RLVCommand == "Vision") {
            //    restrictVision(1);
            //}
            
            if (llSubStringIndex(RLVCommand, "Register") > -1) {
                checkRLV("link request");
            }
            
            if (llSubStringIndex(RLVCommand, "Status") > -1) {
                sendJSON("rlvPresent", "1", "");
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
        sayDebug("listen: channel=" + (string)channel + " key=" + (string) id + " message='"+ message + "'");
        
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
            rlvPresent = 1;
            llListenRemove(RLVStatusListen);
            RLVStatusListen = 0;
            sendJSON("rlvPresent", "1", "");
            sendRLVRestrictCommand(lockLevel, id);
            lockTimerRestart(); // why?
            llOwnerSay(message+"; RLV is present.");
        }
        
        // request on zapchannel
        if (channel == ZapChannel) {
            if (message == (string)llGetOwner()) {
                sayDebug("listen ZapChannel legacy command");   
                startZap("Low", id);
            } else {
                sayDebug("listen ZapChannel JSON command");
                list zapCommands = llJson2List(message);
                key zapKey = llList2Key(zapCommands,0);
                string command = llList2String(zapCommands,1);
                string intensity = llList2String(zapCommands,2);
                if (command == "Zap") {
                    startZap(intensity, id);
                    }
                string buzz = getJSONstring(message, "buzz", "");
                if (command == "Buzz") {
                    OADBuzz(intensity);
                    }
                } 
            }
        
        // request on ACSInterferenceChannel
        if (channel == ACSInterferenceChannel) {
            sayDebug("listen ACSInterferenceChannel"); 
            processACSInterference(name, message);
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
            rlvPresent = 0;
            //llListenRemove(RLVStatusListen); *** debug
            //RLVStatusListen = 0; *** debug
            lockTimerRestart();
            sendJSON("rlvPresent", "0", "");
            sendJSON("lockLevel", "Off", "");
        //} else if (visionTimeout > 0) {
        //    restrictVision(0);
        }
        if (zapTimerunning == 1 && zapTimeremaining <= zapTimerInterval) {
            zapTimerunning = 0;
        }
        if (lockTimerunning == 1) {
            lockTimeremaining -= lockTimerInterval;
            if (lockTimeremaining <= lockTimerInterval) {
                // time has run out...
                llOwnerSay("Timelock has ended. Releasing.");
                sendRLVRestrictCommand("Off", llGetOwner());
                HudFunctionState = 0;
                lockTimerReset();
            }
        }   
        if ( (lockTimerunning == 0) && (zapTimerunning == 0) ) {
            llSetTimerEvent(0);
        }
    }

}
