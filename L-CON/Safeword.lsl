integer PASSWORD;
integer CHANNEL;

integer CHANNEL_HANDLER;
integer RLV_CHANNEL = -1812221819;

initialize() {
    
    PASSWORD = (integer)llFrand(899999) + 100000;
    CHANNEL = (integer)llFrand(8999) + 1000;
    llListenRemove(CHANNEL_HANDLER);
}

default
{
    
    link_message(integer link_num, integer sent_num, string sent_str, key id) {
        if (sent_num == -83657069) {
            llInstantMessage(llGetOwner(),"Safeword: You have 60 seconds to type "+(string)PASSWORD+" on channel "+(string)CHANNEL+".");
            CHANNEL_HANDLER = llListen(CHANNEL,"",llGetOwner(),"");
            llSetTimerEvent(60);
        }
    }
    
    listen(integer l_channel, string name, key id, string message) {
        if (l_channel == CHANNEL) {
            if ((integer)message == PASSWORD) {
                //llShout(0,llKey2Name(llGetOwner())+" has safeworded from their inmate collar.");
                llMessageLinked(LINK_SET,RLV_CHANNEL,"RELEASE",id);
                llOwnerSay("@detach=y");
                llSetTimerEvent(0);
            }
        }
    }
    
    timer() {
        llInstantMessage(llGetOwner(),"Time has expired on your safeword password.");
        llSetTimerEvent(0);
        initialize();
    }
    
    state_entry() {
        initialize();
    }
    
    on_rez(integer rez_state) {
        initialize();
    }
            
}
