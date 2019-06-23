key TARGET;
integer IN_USE = 0;
string PUNISH_MODE = "";

integer command_channel;
integer command_channel_handle;

initialize() {
    llListenRemove(command_channel_handle);
    command_channel = -1 * (integer)llFrand(1000000) + 1000000;
    command_channel_handle = llListen(command_channel,"","","");
    TARGET = llGetOwner();
    llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);
    llStopSound();
}

punish() {
    
}

default
{
    link_message(integer sender_num, integer send_num, string send_str, key id) {
        if (send_num == -80857873) {
            if (send_str == "PUNISH" || send_str == "1") {
                PUNISH_MODE = "Punish";
                //llSay(0,llKey2Name(llGetOwner())+" is shocked by "+S_ENACTOR+" as punishment.") ;
                llLoopSound("electricshock",.5);
                llStartAnimation("Zap");
                llSetTimerEvent(10);
            }
            if (send_str == "ZAP" || send_str == "0") {
                PUNISH_MODE = "Zap";
                //lSay(0,llKey2Name(llGetOwner())+" is given a slight jolt by "+S_ENACTOR+".");
                llPlaySound("electricshock",.5);
                llStartAnimation("Zap");
                llSetTimerEvent(1);
            }
            if (send_str == "STUN" || send_str == "2") {
                PUNISH_MODE = "Stun";
                //llSay(0,llKey2Name(llGetOwner())+" is shocked by "+S_ENACTOR+" as punishment.");
                llLoopSound("electricshock",.5);
                llStartAnimation("Zap");
                llSetTimerEvent(10);
            }
            
            if (PUNISH_MODE == "") {
                llDialog(id,"Please Select Punishment",["Zap","Punish","Stun"],command_channel);
            } else {
                llInstantMessage(id,"Punishment Module Already Running");
            }
        }
    }
    
    state_entry() {
        initialize();
    }
    
    on_rez(integer rez_parameter) {
        initialize();
    }
    
    listen(integer incoming_channel, string incoming_name, key id, string incoming_message) {
        
        if (incoming_channel == command_channel) {
            key ENACTOR = id;
            string S_ENACTOR = llKey2Name(id);
            if (incoming_message == "Zap") {
                // Zap
                PUNISH_MODE = "Zap";
                llSay(0,llKey2Name(llGetOwner())+" is given a slight jolt by "+S_ENACTOR+".");
                llPlaySound("electricshock",.5);
                llStartAnimation("Zap");
                llSetTimerEvent(1);
                
            } else if (incoming_message == "Punish") {
                // Punish
                PUNISH_MODE = "Punish";
                llSay(0,llKey2Name(llGetOwner())+" is shocked by "+S_ENACTOR+" as punishment.") ;
                llLoopSound("electricshock",.5);
                llStartAnimation("Zap");
                llSetTimerEvent(10);
            } else if (incoming_message == "Stun") {
                // Stun
                PUNISH_MODE = "Stun";
                llSay(0,llKey2Name(llGetOwner())+" is shocked by "+S_ENACTOR+" as punishment.");
                llLoopSound("electricshock",.5);
                llStartAnimation("Zap");
                llSetTimerEvent(10);
            }
        }
    }
    
    timer() {
        if (PUNISH_MODE == "Zap") {
            llStopAnimation("Zap");
            llSetTimerEvent(0);
            PUNISH_MODE = "";
        } else if (PUNISH_MODE == "Punish") {
            llStopAnimation("Zap");
            llStopSound();
            PUNISH_MODE = "";
        } else if (PUNISH_MODE == "Stun") {
            llSay(0,"The Shock Renders "+llKey2Name(llGetOwner())+" unconscious.");
            llStopAnimation("Zap");
            llStopSound();
            llStartAnimation("Sleep");
            PUNISH_MODE = "Sleep";
            llSetTimerEvent(300);
        } else if (PUNISH_MODE == "Sleep") {
            llSay(0,llKey2Name(llGetOwner())+" starts to recover from the shock.");
            llStopAnimation("Sleep");
            llStartAnimation("ZapRecover");
            llSetTimerEvent(10);
            PUNISH_MODE = "Recover";
        } else if (PUNISH_MODE == "Recover") {
            llStopAnimation("ZapRecover");
            llSetTimerEvent(0);
            llSay(0,llKey2Name(llGetKey())+" recovers from the shock fully.");
            PUNISH_MODE = "";
        }
    }
    
}
