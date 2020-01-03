
// llRegionSayTo(targetUUID, -1812221819, (string)targetUUID+",@getinvworn:Folder=2225");
// The relay message must be "ping,<object_uuid>,ping,ping" 
// and the object message must be "ping,<user_uuid>,!pong". 

integer RLVRelayPresent = 0;
integer RLVRelayChannel = -1812221819;
integer RLVStatusListen = 0;
integer haveAnimatePermissions = 0;
integer OPTION_DEBUG = 1;
key avatar;

integer hiveTalkChannel = 77683945; // avatars talk & resend
integer hiveHearChannel = 77683950; // avatars listen & tell avatars
integer hiveHearListen = 0;

list rlvCommands = [];

// adds "command:parameter=n" to the rlvCommands list. 
// use: rlvCommands = addRLVCommand("command","parameter")
addRLVCommand(string command, string parameter) {
    string completeCommand = command; 
    if (parameter != "") {
        completeCommand = completeCommand + ":" + parameter;
    }
    completeCommand = completeCommand + "=add";
    rlvCommands = rlvCommands + [completeCommand];
}

string makeRLVCommand(string tag, key avatar) {
    string result = tag + "," + (string)avatar + ",";
    string bar = "";
    integer i;
    for (i = 0; i < llGetListLength(rlvCommands); i++) {
        result = result + bar + "@" + llList2String(rlvCommands,i);
        bar = "|";
    }
    return result;
}

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("forceEyepoint: "+message);
    }
}

checkRLVRelay() {
    sayDebug("checkRLVRelay");
    // message  ::= <cmd_name>,<user_uuid>,<list_of_commands>
    string statusquery="checkRelay,"+(string)avatar+",!version";
    sayDebug("checkRLVRelay sending: "+statusquery);
    llRegionSayTo(avatar, RLVRelayChannel, statusquery);
    llSetTimerEvent(30); 
}

sendRLVRestrictCommand(string level) {
    sayDebug("sendRLVRestrictCommand("+level+")");
    if (RLVRelayPresent == 1) {
        if (level == "On") {
            //addRLVCommand("camdistmax","0.5"); // gets set
            //addRLVCommand("camdistmin","1"); // gets set
            //addRLVCommand("camunlock",""); // gets set
            //addRLVCommand("camzoommax","0.1"); // gets set
            addRLVCommand("redirchat",(string)hiveTalkChannel);
            //addRLVCommand("camdrawmin","1");
            //addRLVCommand("camdrawmax","10");
            //addRLVCommand("camdrawalphamin","0.1");
            //addRLVCommand("camdrawalphamax","0.9");
            //addRLVCommand("camdrawcolor","20;50;20");
            // this is lame. This is totally fucking lame. It rotates with every press of esc. 
            //addRLVCommand("setcam_eyeoffset","0/0/0.87");
            //addRLVCommand("setcam_focusoffset","0/-5/0.87");
            
            string rlvcommand = makeRLVCommand("rlvCommands", avatar); 
            
            sayDebug("sendRLVRestrictCommand sending: "+rlvcommand);
            llRegionSayTo(avatar, RLVRelayChannel, rlvcommand);
            llRegionSay(hiveTalkChannel, "Someone has joined.");
        }
        if (level == "Off") {
            string  rlvcommand = "rlvCommands,"+(string)avatar+",!release";
            sayDebug("sendRLVRestrictCommand sending: "+rlvcommand);
            llRegionSayTo(avatar, RLVRelayChannel, rlvcommand);
        }
        if (level == "Pong") {
            string  rlvcommand = "ping,"+(string)avatar+",!pong";
            sayDebug("sendRLVRestrictCommand sending: "+rlvcommand);
            llRegionSayTo(avatar, RLVRelayChannel, rlvcommand);
        }
        
    }
}

default
{
    state_entry()
    {
        RLVRelayPresent = 0;
        //llSetCameraEyeOffset(<0.0, 0.0, 0.87>); // where the camera is
        //llSetCameraAtOffset(<0.0, -5.0, 0.87>); // where it's looking
        llSetCameraEyeOffset(<0.0, 0.0, 0.0>); // where the camera is
        llSetCameraAtOffset(<0.0, 0.0, 0.0>); // where it's looking
    }

    // when someone sits on this
    changed(integer change) 
    {
        if (change & CHANGED_LINK) 
        {
            key sittingAvatar = llAvatarOnSitTarget();
            sayDebug("changed CHANGED_LINK");
            if (sittingAvatar != NULL_KEY) {
                avatar = sittingAvatar;
                sayDebug("The number of links has changed.");
                RLVRelayPresent = 0;
                RLVStatusListen = llListen(RLVRelayChannel, "", "", "");
                hiveHearListen = llListen(hiveHearChannel, "", "", "");
                checkRLVRelay();
            } else {
                sendRLVRestrictCommand("Off");
                avatar = NULL_KEY;
            }
        }    
    }

    listen( integer channel, string name, key id, string message )
    {
        sayDebug("listen channel:" + (string)channel + " key:" + (string) id + " message:"+ message);
        
        // checkRelay,d6841dc4-e1cf-3270-2988-3ea6a80172b9,!version,1100; 
        
        if (channel == RLVRelayChannel) {
            list response = llParseString2List(message, [","], []);
            string cmdName = llList2String(response,0);
            key returnedKey = llList2Key(response,1);
            string returnedCommand = llList2String(response,2);
            string returnedCommand2 = llList2String(response,3);
            if ((cmdName == "checkRelay") && (returnedCommand == "!version")) {
                sayDebug("got RLV relay response");
                RLVRelayPresent = 1;
                sendRLVRestrictCommand("On");
            }
            if ((cmdName == "ping") && (returnedCommand == "ping") && (returnedCommand2 == "ping")) {
                sayDebug("got RLV ping");
                RLVRelayPresent = 1;
                sendRLVRestrictCommand("Pong");
            }
        }
        
        if ((channel == hiveHearChannel) && (avatar != NULL_KEY)) {
            llInstantMessage(avatar, message);
        }
    }
    
    timer()
    {
        if (RLVStatusListen != 0) {
            // we were asking local RLV status; this is the timeout
            llListenRemove(RLVStatusListen);
            RLVRelayPresent = 0;
            RLVStatusListen = 0;
        } 
    }
}
