// TWL's Transformation HUD 0.4
// Timberwoof Lupindo
// 2016-11-26
//
// Sense the area for nearby avatars. 
// Setermine whether thay are looking at the avatar wearing this HUD. 
// If one is, freeze the vatar. 
//
// Settigs in HUD Description 
// quiet, info, debug, trace: debug levels. off is default
// restrictoff: Movement will not be restricted. (By default movement will be restricted.)
// rlvoff: You will not be restricted with RLV. (By default you will be restricted.)
// transformoff: You will not be transformed. (By default you will be transformed.)
// seatedon: Seated avatars can transform you. (Bby default, seated avatars cannot freeze you.)
// werewolf: alone or unseen you turn into a werewolf
//
// Startup gives the wearer ten seconds to cancel. 
// The HUD can be turned off while not frozen.
// The HUD can NOT be turned off while frozen. 

list symbols;
list values;

string configurationNotecardName= "TWL's Transformation HUD configuration";

string OFF = "off";
string ON = "on";
integer ERROR = 0;
integer INFO = 1;
integer DEBUG = 2;
integer TRACE = 3;
list logLevelS = ["error","info","debug","trace"];
integer logLevel = 2; // debug

vector white = <1,1,1>; // not ready
vector red = <1,.25,.25>; // werewolf
vector orange = <1,.5,.25>; // transforming
vector yellow = <1,1,.25>; // ready
vector green = <.25,1,.25>; // flesh
vector blue = <.25,.25,1>; // stone

string triggerMode;
string transformInto;
string RLVFOLDER; // ~stgargoyle

integer line;
key notecardQueryId;

vector plinthLocal;
string plinthString;
string plinthSim;
vector plinthPos;
string plinthKey;
vector simGlobal;
key plinthQueryId;

string actualState;
integer triggerAnimationsSet = 0;
integer startState = 0; 
string who = "no one";
integer count = 0;
integer continuousLookingCount = 0;
integer continuousNotLookingCount = 0;
integer continuouslookthreshold = 0; 
integer continuouslooktimeout = 0;

integer rlvVersion = 0;
integer rlvVersionChannel;
integer rlvVersionListen;

string beetlejuicePhrase;
integer beetlejuiceListen;

// when description is "DEBUG", this sends messages to wearer for debugging
sayLog(integer level, string message) 
{
    if (level <= logLevel) {
        llOwnerSay(llList2String(logLevelS,level)+": "+message);
    }
}

string getSymbol(string symbol)
{
    string result = "";
    integer index = llListFindList(symbols,[symbol]);
    if (index > -1)
    {
        result = llList2String(values, index);
    }
    else
    {
        sayLog(ERROR,"getSymbol could not find symbol "+symbol);
    }
    sayLog(TRACE,"getSymbol("+symbol+") returns "+result);
    return result;
}

setSymbol(string symbol, string value)
// It's a pain in the ass to maintain symbol-list initialization with two long lists,
// so this adds them in sequence. 
{
    sayLog(TRACE,"setSymbol("+symbol+","+value+")");
    integer index = llListFindList(symbols, [symbol]);
    if (-1 == index)
    {
    symbols = symbols + [symbol];
        sayLog(TRACE,"setSymbol adding symbol "+symbol);
        index = llListFindList(symbols, [symbol]);
    }
    values = llListReplaceList(values, [value], index, index);
}

listSymbolValues(integer logLevel)
{
    integer index;
    for (index = 0; index < llGetListLength(symbols); index++)
    {
        sayLog(logLevel,llList2String(symbols,index)+": "+llList2String(values,index));
    }
}

initializeSymbols()
{
    // default symbols so it will do something even when there's no notecard
    setSymbol("loglevel","debug");
    setSymbol("triggermode","night"); // seen, unseen, day, night
    setSymbol("transform",ON);
    setSymbol("transforminto","were"); // or stone
    setSymbol("restrict",OFF);
    setSymbol("rlv",ON);
    setSymbol("seated",OFF);
    setSymbol("plinth",OFF);
    setSymbol("plinthrotation","0");
    setSymbol("beetlejuice",OFF);
    setSymbol("pose","any");
    setSymbol("rlvfolder","stgargoyle");
    setSymbol("sensorradius","10.0");
    setSymbol("sensorrate","2.0");
    setSymbol("continuouslookthreshold","4");
    setSymbol("continuouslooktimeout","30");
    setSymbol("anglethreshold","0.12");
    setSymbol("sunangle","0.5");
}

initializePart1() 
{
    sayLog(INFO,"Initializing");

    // set up simple global variables    
    startState = 0;
    rlvVersion = 0;
    continuousLookingCount = 0;
    continuousNotLookingCount = 0;
    triggerAnimationsSet = 0;
    startState = 0;
    actualState = "flesh";
    notecardQueryId = NULL_KEY;
    plinthQueryId = NULL_KEY;

    // set up basic prim prooperties
    llSetColor(white,ALL_SIDES);
    llSetTimerEvent(0);
    
    // Ask for RLV version number.
    rlvVersionChannel = (integer)llFloor(llFrand(10000));
    rlvVersionListen = llListen(rlvVersionChannel,"","","");
    llOwnerSay("@versionnum="+(string)rlvVersionChannel);
    llSensorRemove();

    // Ask for animaiton and controls permisiosns.
    if(llGetAttached() != 0) 
    { 
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
        sayLog(DEBUG,"attached; asked for animation and control permissions");
    }
    
    initializeSymbols();

    sayLog(TRACE,"initializePart1 reading notecard '"+configurationNotecardName+"'");
    if(llGetInventoryType(configurationNotecardName) != INVENTORY_NOTECARD)
    {
        sayLog(ERROR, "Missing inventory notecard: "+configurationNotecardName);
        startState = 2; // skip state 1; finish init with default values
        llSetTimerEvent(1);
        sayLog(DEBUG,"initializePart1 done. Using default settings.");    
    }
    else
    {
        line = 0;
        notecardQueryId = llGetNotecardLine(configurationNotecardName, line);
        startState = 1; // wait for data
        sayLog(INFO,"Reading configuration notecard '"+configurationNotecardName+"'");
        // Dataserver event calls initializePart2.
    }
}

initializePart2(string data)
// Called by notecard dataserver event.
{
    sayLog(DEBUG,"initializePart2("+data+")");
    if ((EOF != data) & (data != ""))
    {
        if(llSubStringIndex(data, "#") != 0)
        {
            integer i = llSubStringIndex(data, "=");
            if(i != -1)
            {
                string name = llGetSubString(data, 0, i - 1);
                string value = llGetSubString(data, i + 1, -1);
                list temp = llParseString2List(name, [" "], []);
                name = llDumpList2String(temp, " ");
                name = llToLower(name);
                temp = llParseString2List(value, [" "], []);
                value = llDumpList2String(temp, " ");
                
                sayLog(TRACE,"initializePart2 setting "+name+" to "+value);
                setSymbol(name, value);
            }
            else
            {
                sayLog(ERROR,"initializePart2 could not read line " + (string)line);
            }
        }
        notecardQueryId = llGetNotecardLine(configurationNotecardName, ++line);
    }
    
    if (EOF == data)
    {
        sayLog(DEBUG,"initializePart2 finished reading the configuration.");
        if (0 == rlvVersion)
        {
            llSetTimerEvent(30); // no rlv version yet, so wait for it. 
            sayLog(DEBUG,"initializePart2 waiting for RLV version response.");
        }
        else
        {
            llSetTimerEvent(1); // we already got it, so no need to wait. 
        }
        startState = 2; // initializePart2 is done
        return;
    }
}
 
initializePart3()
// Called by timer set by dataserver eof in initializePart2 
{
    logLevel = llListFindList(logLevelS,[getSymbol("loglevel")]);
    sayLog(DEBUG,"initializePart3");
    listSymbolValues(TRACE);
    
    llListenRemove(rlvVersionListen);
    if (0 == rlvVersion)
    {
        sayLog(ERROR,"RLV not detected. Nothing interesting will happen to you.");
    }
    else
    {
        sayLog(DEBUG,"rlvVersion:"+(string)rlvVersion);
        llOwnerSay("@clear");
        if (getSymbol("rlv") == ON)
        {
            sayLog(INFO,"RLV is on. RLV will be used to restrict you.");
        }
        else
        {
            sayLog(INFO,"RLV is off. RLV will not be used to restrict you.");
        }

    }
    
    // simple often-used symbols become variables
    RLVFOLDER = "~"+getSymbol("rlvfolder");
    continuouslookthreshold = (integer)getSymbol("continuouslookthreshold");
    continuouslooktimeout = (integer)getSymbol("continuouslooktimeout");

    // triggermode can be seen, unseen, day, or night.
    string triggerphrase;
    triggerMode = getSymbol("triggermode");
    if ("seen" == triggerMode)
    {
        triggerphrase = "When someone looks at you, ";
    } 
    else if ("unseen" == triggerMode)
    {
        triggerphrase = "When no one is looking at you, ";
    }
    else if ("day" == triggerMode)
    {
        triggerphrase = "During the day, ";
    }
    else if ("night" == triggerMode)
    {
        triggerphrase = "At night, ";
    }
    else
    {
        triggerphrase = "*Error*";
        sayLog(ERROR,"triggerMode is badly defined: "+triggerMode+". It must be seen, unseen, day, or night.");
    }
    
    // transformation can be were or stone
    transformInto = getSymbol("transforminto");

    string not = " ";    
    if (0 == rlvVersion | getSymbol("transform") != ON)
    {
        not = " not ";
    }
    
    if (getSymbol("transform") == ON)
    {
        if ("were" == transformInto) 
        {
            sayLog(INFO,triggerphrase+"you will"+not+"transform into your 'were' form.");
            sayLog(DEBUG,"The HUD will"+not+"use avatars in #RLV/"+RLVFOLDER+"/flesh and #RLV/"+RLVFOLDER+"/were");
            llSetTexture("werewolf",ALL_SIDES);
        } 
        else if ("stone" == transformInto)
        {
            sayLog(INFO,triggerphrase+"you will"+not+"transform into stone.");
            sayLog(DEBUG,"The HUD will"+not+"use avatars in #RLV/"+RLVFOLDER+"/flesh and #RLV/"+RLVFOLDER+"/stone");
            if (("seen" == triggerMode) | ("unseen" == triggerMode))
            {
                llSetTexture("weeping angel",ALL_SIDES);
            }
            else
            {
                llSetTexture("gargoyle",ALL_SIDES);
            }
        }
        else
        {
            sayLog(ERROR,"transformInto is badly defined: "+transformInto+". It must be stone or were.");
        }
    }
    else 
    {
            sayLog(INFO,"transform is off. You will not be transformed.");
    }
    
    // If we need teleport services, deal with older RLV version
    // http://wiki.secondlife.com/wiki/LSL_Protocol/RestrainedLoveAPI#Version_Checking
    string plinthString = getSymbol("plinth"); // like "Black Gazza/216/28/40" 
    sayLog(DEBUG,"plinthString:'"+plinthString+"'");
    string beetlejuice = getSymbol("beetlejuice");
    sayLog(DEBUG,"beetlejuice:'"+beetlejuice+"'");
    if ((plinthString != OFF) & (beetlejuice != OFF))
    {
        list plinthList = llParseString2List(plinthString, ["/"], [""]);
        plinthSim = llList2String (plinthList, 0);
        plinthPos.x = llList2Float (plinthList, 1);
        plinthPos.y = llList2Float (plinthList, 2);
        plinthPos.z = llList2Float (plinthList, 3);
        plinthKey = llList2String (plinthList, 4);
        if ((0 >= plinthPos.x) | (0 >= plinthPos.y) | (0 >= plinthPos.z))
        {
            sayLog(ERROR,"Badly defined plinth: "+plinthString+". It ust be coded like coded like region/128/128/20. You will not be returned to your plinth.");
            llSetTimerEvent(1); // no wait, but needs event
            plinthSim = "";
        }
        if ((rlvVersion > 0) & (rlvVersion < 2092000))
        {
            sayLog(DEBUG,"RLV version "+(string)rlvVersion+" does not support easy goto coordinates.");
        }
        else
        {
            sayLog(DEBUG,"Requesting coordinates from sim.");
            plinthQueryId = llRequestSimulatorData (plinthSim, DATA_SIM_POS);
            // this will cause initializePart4
        }
    }

    if (NULL_KEY == plinthQueryId)
    {
        llSetTimerEvent(0);
        llSetColor(green,ALL_SIDES);
        startState = 3;
        sayLog(INFO,"Ready. Click the HUD to start.");
    }
    else 
    {
        llSetTimerEvent(30); // wait for data server for initializePart4
    }
    sayLog(TRACE,"initializePart3 done");
}


initializePart4(string data)
// Called by sim info dataserver event llRequestSimulatorData;
{
    sayLog(DEBUG,"dataserver: received plinth global coordinates:"+data);
    sayLog(DEBUG,"original plinth coordinates: "+getSymbol("plinth")); // Debug purposes

    // Parse the dataserver response (it is a vector cast to a string)
    list tokens = llParseString2List (data, ["<", ",", ">"], []);
 
    // The coordinates given by the dataserver are the ones of the
    // South-West corner of this sim
    simGlobal.x = llList2Float (tokens, 0);
    simGlobal.y = llList2Float (tokens, 1);
    simGlobal.z = llList2Float (tokens, 2);
    sayLog(DEBUG, "sim global coordinates: "+(string)simGlobal); // Debug purposes

    // beetlejuice spell can only be done if this is called. 
    string beetlejuice = getSymbol("beetlejuice");
    if (beetlejuice != OFF)
    {   
        beetlejuicePhrase = ":: " + beetlejuice+" "+beetlejuice+" "+beetlejuice + " ::";
        beetlejuiceListen = llListen(0,"",NULL_KEY, beetlejuicePhrase);
        sayLog(INFO,"When anyone says "+beetlejuicePhrase+", you will go to them.");
    }

    llSetTimerEvent(0);
    llSetColor(yellow,ALL_SIDES);
    startState = 3;
    sayLog(INFO,"Ready. Click the HUD to start.");
    sayLog(TRACE,"initializePart4 done");
}

forceTeleportTo(string sim, vector position)
// Uses RLV force teleport to move you. 
// The exact thing to do depends on the RLV version 
// and some setup already done elsewhere. 
{
    sayLog(DEBUG,"Teleporting to "+sim+(string)position);
    string summonString;
    if ((rlvVersion > 0) & (rlvVersion < 2092000))
    {
        vector summonto = position + simGlobal;
        summonString = (string)((integer)summonto.x)
        +"/"+(string)((integer)summonto.y)
        +"/"+(string)((integer)summonto.z);
    }
    else
    {
        summonString = llGetRegionName()
        +"/"+(string)((integer)position.x)
        +"/"+(string)((integer)position.y)
        +"/"+(string)((integer)position.z);
    }
    sayLog(DEBUG,"You are being teleported to "+summonString);
    llOwnerSay("@tpto:"+summonString+"=force");
    
    string plinthrotationstring = getSymbol("plinthrotation");
    if ("" != plinthrotationstring)
    {
        sayLog(DEBUG,"Setting rotation to "+plinthrotationstring);
        float newrot = (float)plinthrotationstring*DEG_TO_RAD;
        llOwnerSay("@setrot:"+(string)newrot+"=force");
    }
    
    if ("" != plinthKey)
    {
        sayLog(DEBUG,"Force-sitting on "+plinthKey);
        llOwnerSay("@sit:"+plinthKey+"=force");
    }
}

// turn on or off restrictions 
// this can be called as often as sensor wants to 
// but it won't reset the same state
doTransform(string desiredState)
{
    sayLog(TRACE,"transform "+desiredState);
    
    if (getSymbol("transform") != ON)
    {
        sayLog(DEBUG,"transform is not on.");
    }
    
    else if (desiredState != actualState)
    {
        sayLog(INFO,"You are transforming into "+desiredState);
        llSetColor(orange,ALL_SIDES);
        
        if ("flesh" == desiredState) // WORKS
        {
            llOwnerSay("@clear");

            if (getSymbol("transform") == ON)
            {
                sayLog(DEBUG,"attaching "+RLVFOLDER+"/flesh");
                llOwnerSay("@detach=n"); // lock the HUD so it doesn't get removed
                llOwnerSay("@remoutfit=force,remattach=force");
                llSleep(3);
                llOwnerSay("@attach:"+RLVFOLDER+"/flesh=force");
                llOwnerSay("@clear");
            }
            
            if (1== triggerAnimationsSet)
            {
                stopAllAnimations();
            }
            
            // Give movement control back to the avatar; ask for permissions again for the next time. 
            llReleaseControls();
            llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);

            continuousLookingCount = 0;
            llSetColor(yellow,ALL_SIDES);
        }
        
        else if ("stone" == desiredState)
        {
            // RLV restrictions
            if (getSymbol("restrict") == ON)
            {
                sayLog(DEBUG,"setting movement restrictions");
                llTakeControls(
                    CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT |
                    CONTROL_UP | CONTROL_DOWN | CONTROL_LBUTTON | CONTROL_ML_LBUTTON , TRUE, FALSE);
            }   

            // animations
            if (1 == triggerAnimationsSet)
            {
                string poseString = getSymbol("pose");
                if ("none" != poseString)
                {
                    if ("any" == poseString)
                    {
                        poseString = getRandomAnimation();
                    }
                    sayLog(DEBUG,"setting animation "+poseString);
                    llStartAnimation(poseString);
                }
            }
            
            // force teleport
            if ("" != plinthSim)
            {
                forceTeleportTo(plinthSim, plinthPos);
            }
            
            // attach statue skin and parts for statue
            if (getSymbol("transform") == ON)
            {
                sayLog(DEBUG,"attaching "+RLVFOLDER+"/stone");
                llOwnerSay("@detach=n"); // lock the HUD so it doesn't get removed
                llOwnerSay("@remoutfit=force,remattach=force");
                llSleep(3);
                llOwnerSay("@attach:"+RLVFOLDER+"/stone=force");
            }
            
            // rlv restrictions
            if (getSymbol("rlv") == ON)
            {
                sayLog(DEBUG,"setting RLV restrictions");
                llOwnerSay("@chatshout=n,chatnormal=n,fly=n,tploc=n,tplure_sec=n,emote=add,sendchat=n");
                llOwnerSay("@remattach=n,addattach=n,remoutfit=n,addoutfit=n,tploc=n");
                llOwnerSay("@rez=n,showinv=n,fartouch=n,touchall=n,touchattach=n,touchworld=n");
            }
            else
            {
                llOwnerSay("@clear"); // unlock lock the HUD
            }
            
            llSetColor(blue,ALL_SIDES);
        } 
        
        else if ("were" == desiredState)
        {
            // force teleport
            if ("" != plinthSim)
            {
                forceTeleportTo(plinthSim, plinthPos);
            }
            
            // attach skin and attachments for wereweolf
            if (getSymbol("transform") == ON)
            {
                sayLog(DEBUG,"attaching "+RLVFOLDER+"/were");
                llOwnerSay("@detach=n"); // lock the HUD so it doesn't get removed
                llOwnerSay("@remoutfit=force,remattach=force");
                llSleep(3);
                llOwnerSay("@attach:"+RLVFOLDER+"/were=force");
            }
            
            // rlv restrictions
            if (getSymbol("rlv") == ON)
            {
                sayLog(DEBUG,"setting RLV restrictions");
                llOwnerSay("@chatshout=n,chatnormal=n,fly=n,tploc=n,tplure_sec=n,shownames=n,emote=add,sendchat=n");
                llOwnerSay("@remattach=n,addattach=n,remoutfit=n,addoutfit=n,tploc=n");
                llOwnerSay("@rez=n,showinv=n,fartouch=n,touchall=n,touchattach=n,touchworld=n");
                llOwnerSay("@camunlock=n,camzoommax:1=n,camzoommin:1=n,setcam_fovmin:0.65=n,setcam_fovmax:0.75=n,setcam_fov:0.7=force"); // works
                llOwnerSay("@camdistmax:1=n,camdistmin:1=n"); // works
                llOwnerSay("@camdrawmin:5=n,camdrawmax:20=n,camdrawalphamin:0.1=n,camdrawalphamax:0.9=n,@camdrawcolor:0;0;0=n");
            }
            llSetColor(red,ALL_SIDES);
        }
        else
        {
            sayLog(ERROR,"ill-defined desiredState in transform:"+desiredState);
        }
    }
    actualState = desiredState;
}

string getRandomAnimation()
{
    integer numberOfPoses = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer which = (integer)llFloor(llFrand(numberOfPoses));
    string result = llGetInventoryName(INVENTORY_ANIMATION,which);
    sayLog(TRACE,"getRandomAnimation returns "+result);
    return result;
}

stopAllAnimations()
{
    sayLog(DEBUG,"stopAllAnimations");
    list l = llGetAnimationList(llGetOwner());
    integer lsize = llGetListLength(l);
    integer i;
    for (i = 0; i < lsize; i++)
    {
        llStopAnimation( llList2Key(l, i));
    }
}

default
{
    state_entry()
    {
        sayLog(TRACE,"state_entry");
        initializePart1();
        sayLog(TRACE,"sate_entry done");
    }

    on_rez (integer start_param) 
    {
        sayLog(TRACE,"on_rez");
        initializePart1();
        sayLog(TRACE,"on_rez done");
    }
    
    run_time_permissions(integer perm)
    {
        if((perm & PERMISSION_TRIGGER_ANIMATION) && (perm & PERMISSION_TAKE_CONTROLS))
        {
            sayLog(DEBUG,"run_time_permissions: animation and control permissions granted");
            stopAllAnimations();
            triggerAnimationsSet = 1;
        }
    }
    
    dataserver(key request_id, string data)
    {
        if(request_id == notecardQueryId)
        {
            initializePart2(data);
        }
        
        // This only happens with a low RLV version number
        if (request_id == plinthQueryId) 
        {
            initializePart4(data);
        }
    }

    timer()
    {
        sayLog(DEBUG, "timer startState:"+(string)startState);
                
        if (2 == startState) // end of read-notecard
        {
            initializePart3();
        }
        
        else if (5 == startState) // end of cancel interval
        {
            sayLog(INFO,"Starting.");
            doTransform("flesh");
            if (("unseen" == triggerMode) | ("seen" == triggerMode))
            {
                llSensorRepeat("", NULL_KEY, AGENT, (float)getSymbol("sensorradius"), PI, (float)getSymbol("sensorrate"));
                llSetTimerEvent(0);
                startState = 6; // sensor seen/unseen mode
                sayLog(DEBUG,"timer in state "+(string)startState+": sensor mode");
            }
            else if (("day" == triggerMode) | ("night" == triggerMode))
            {
                llSetTimerEvent(10); // startup time. 
                startState = 7; // timer daytime mode
                sayLog(DEBUG,"timer in state "+(string)startState+": daytime mode");
            }
            else 
            {
                sayLog(ERROR,"badly specified triggerMode:"+triggerMode);
            }
            llOwnerSay("@detach=n"); // lock the HUD so it doesn't get removed
            
            if (getSymbol("transform") == ON)
            {
                llOwnerSay("@remoutfit=force,remattach=force");
                llSleep(3);
                llOwnerSay("@attach:"+RLVFOLDER+"/flesh=force"); // force the flesh state. 
                llOwnerSay("@clear");
            }
            
            if (getSymbol("rlv") != ON)
            {
                llOwnerSay("detach=y"); // lock the HUD so it doesn't get removed
            }
            sayLog(DEBUG,"active");
        }
        
        else if (7 == startState)
        {
            // triggerMode is day or night
            vector sun = llGetSunDirection();
            sayLog(DEBUG,"sun angle is "+(string)sun.z);
            float sunHours = 0;
            if ("day" == triggerMode)
            {
                if (sun.z <= (float)getSymbol("sunangle")) // Sun is below the angle
                {  
                    sayLog(DEBUG,"timer in state "+(string)startState+": day mode senses nighttime. You are flesh.");
                    doTransform("flesh");
                } 
                else if (sun.z > (float)getSymbol("sunangle")) // Sun is above the angle
                { 
                    sayLog(DEBUG,"timer in state "+(string)startState+": day mode senses daytime. You are "+transformInto);
                    doTransform(transformInto);
                }
            }
            else if ("night" == triggerMode)
            {
                if (-sun.z <= (float)getSymbol("sunangle")) // Sun is below the angle
                {  
                    sayLog(DEBUG,"timer in state "+(string)startState+": night mode senses nighttime. You are "+transformInto);
                    doTransform(transformInto);
                } 
                else if (-sun.z > (float)getSymbol("sunangle")) // Sun is above the angle
                { 
                    sayLog(DEBUG,"timer in state "+(string)startState+": night mode senses daytime. You are flesh.");
                    doTransform("flesh");
                }
            }
            else
            {
                sayLog(ERROR,"badly specified triggerMode:"+triggerMode);
            }
            llSetTimerEvent(300); // 5 minutes
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (rlvVersionChannel == channel)
        {
            // @version: RestrainedLife viewer v2.8.0 (RLVa 1.4.10)
            // @versionnew: RestrainedLove viewer v2.8.0 (RLVa 1.4.10)
            // @versionnum: 2080000
            // easy tpto is impemented in 2.9.20 = 2092000
            rlvVersion = (integer)message;
            sayLog(DEBUG,"RLV version:"+(string)message); 
            llListenRemove(rlvVersionListen);
        }
    }

    touch_start(integer total_number)
    {
        sayLog(DEBUG,"touch_Start startState:"+(string)startState);
        // User clicks it to start the HUD.
        if (3 == startState)
        {
            llSetColor(orange,ALL_SIDES);
            sayLog(INFO,"You have ten seconds to cancel the Transformation HUD.");
            llSetTimerEvent(10);
            startState = 5; // cancel interval
        }
        
        // If it is clicked within ten seconds, startup is canceled. 
        else if (5 == startState) // cancel interval
        {
            doTransform("flesh");
            sayLog(INFO,"TWL's Transformation HUD Startup Canceled.");
            initializePart1(); // resets known variables. 
        }
        
        else if (6 == startState) // sensor; seen or unseen
        {
            if ("flesh" == actualState)
            {
                llOwnerSay("@clear");
                llSensorRemove();
                sayLog(INFO,"TWL's Transformation HUD Canceled.");
                initializePart1(); // resets known variables.
            }
            else
            {
                sayLog(INFO,who+" is looking at you.");
                llSensorRepeat("", NULL_KEY, AGENT, (float)getSymbol("sensorradius"), PI, (float)getSymbol("sensorrate"));
            }
        } 
        
        else if (7 == startState) // timer; day or night
        {
            if ("flesh" == actualState)
            {
                llOwnerSay("@clear");
                llSensorRemove();
                sayLog(INFO,"TWL's Transformation HUD Canceled.");
                initializePart1(); // resets known variables.
            }
            else
            {
                    sayLog(INFO,"You are transformed. You cannot cancel the HUD.");
                    vector sun = llGetSunDirection();
                    sayLog(DEBUG,"sun angle is "+(string)sun.z);
            }
        }
    }
    
    sensor(integer num_detected) 
    {
        // Assuming that triggermode=unseen
        sayLog(TRACE,(string)count+" sensor("+(string)num_detected+")");
        count++;
        vector myLocation = llGetPos();
        
        integer someoneIsLooking = 0;
        integer avatarNumber;
        who = "no one";
        for (avatarNumber = 0; avatarNumber < num_detected; avatarNumber++) 
        {
            //sayLog(llDetectedName(avatarNumber));
            key detectedAvatar = llDetectedKey(avatarNumber);
            key detectedAvatarRoot = llList2Key(llGetObjectDetails(detectedAvatar, [OBJECT_ROOT]),0);
            string avatarName = llDetectedName(avatarNumber);
            if ((detectedAvatar == detectedAvatarRoot) || (getSymbol("seated") == ON))
            {
                vector avatarLocation = llDetectedPos(avatarNumber);
                rotation avatarRotation = llDetectedRot(avatarNumber);
                vector xPosOffset = <5.0, 0, 0>;
                vector avatarLookingAt = xPosOffset * avatarRotation; // fictional point relative to the avatar the avatar is looking at
                vector avatarSeesMe = myLocation - avatarLocation;  // point relative to avatar where I am
                avatarSeesMe.z = 0.0;
                rotation rotBetween = llRotBetween(avatarLookingAt,avatarSeesMe);
                float angleBetween = llAngleBetween(<0,0,0,0>, rotBetween);
                sayLog(DEBUG,avatarName+": "+(string)angleBetween);
                if (angleBetween < (float)getSymbol("anglethreshold"))
                {
                    someoneIsLooking = someoneIsLooking + 1;
                    if (someoneIsLooking = 1)
                    {
                        who = avatarName;
                    }
                    else
                    {
                        who = who + ", " + avatarName;
                    }
                    sayLog(TRACE,who+" is looking at you.");
                }
            }
            else
            {
                sayLog(TRACE,avatarName + " is seated.");
            }
        }  
        
        if (someoneIsLooking)
            {
            sayLog(TRACE,who+" is looking at you.");
            continuousNotLookingCount = 0;
            continuousLookingCount = continuousLookingCount + 1;
            if (continuousLookingCount > continuouslookthreshold & continuousLookingCount < continuouslooktimeout)
            {
                sayLog(TRACE,who+" has been looking at you for a while.");
                if ("seen" == triggerMode)
                {
                    doTransform(transformInto);
                }
                else if ("unseen" == triggerMode)
                {
                    doTransform("flesh");
                }
                else
                {
                    sayLog(ERROR,"ill-defined trigger mode: "+triggerMode);
                }
            }
            if (continuousLookingCount > continuouslooktimeout)
            {
                sayLog(INFO,"Someone has been looking at you for a long time.");
                if ("seen" == triggerMode)
                {
                    doTransform("flesh");
                }
                sayLog(INFO,"Run!");
            }

        }
        
        else if (someoneIsLooking == 0)
        {
            sayLog(TRACE,"No one is looking at you.");
            continuousLookingCount = 0;
            continuousNotLookingCount = continuousNotLookingCount + 1;
            if (continuousNotLookingCount > continuouslookthreshold)
            {
                sayLog(TRACE,"No one has looked at you for a while.");
                if ("seen" == triggerMode)
                {
                    doTransform("flesh");
                }
                else if ("unseen" == triggerMode)
                {
                    doTransform(transformInto);
                }
                else
                {
                    sayLog(ERROR,"ill-defined trigger mode: "+triggerMode);
                }
            }
        } 
    }
    
    no_sensor()
    {
        who = "no one";
        continuousLookingCount = 0;
        continuousNotLookingCount = continuousNotLookingCount + 1;
        
        if (continuousNotLookingCount > continuouslookthreshold)
        {
            sayLog(TRACE,"No one has seen you for a while.");
            if ("unseen" == triggerMode)
            {
                doTransform(transformInto);
            }
            else if ("seen" == triggerMode)
            {
                doTransform("flesh");
            }
            else
            {
                sayLog(ERROR,"ill-defined trigger mode: "+triggerMode);
            }
        }
    }
}
