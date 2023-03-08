// keypad.lsl
// script for inflicting a keypd on the user nd giving back a number
// Lormyr Daviau, back when they used oscilloscopes to debug fire
// version 2023-03-08
integer KEYPAD_CHANNEL;
integer KEYPAD_CHANNEL_HANDLE;
string MESSAGE;
list keypad = ["C","0","E","1","2","3","4","5","6","7","8","9"];
string ENTRY_STYLE = "";

string string2stringtime(string timemessage) {
    string formatted_message;
    if (llStringLength(timemessage) > 6) {
        formatted_message += llGetSubString(timemessage,0,-7)+"d";
    }
    if (llStringLength(timemessage) > 4) {
        formatted_message += llGetSubString(timemessage,-6,-5)+"h";
    }
    if (llStringLength(timemessage) > 2) {
        formatted_message += llGetSubString(timemessage,-4,-3)+"m";
    }
    if (llStringLength(timemessage) > 0) {
        formatted_message += llGetSubString(timemessage,-2,-1)+"s";
    }
    if (llStringLength(timemessage) == 0) {
        formatted_message = "(no time)";
    }
    return formatted_message;
}

string stringtime2integertime(string timemessage) {
    //Stuff
    integer formatted_message = 0;
    if (llStringLength(timemessage) > 6) {
        formatted_message += (integer)llGetSubString(timemessage,0,-7)*86400;
    }
    if (llStringLength(timemessage) > 4) {
        formatted_message += (integer)llGetSubString(timemessage,-6,-5)*3600;
    }
    if (llStringLength(timemessage) > 2) {
        formatted_message += (integer)llGetSubString(timemessage,-4,-3)*60;
    }
    if (llStringLength(timemessage) > 0) {
        formatted_message += (integer)llGetSubString(timemessage,-2,-1);
    }
    return (string)formatted_message;
}


default
{
    state_entry()
    {
    }

    on_rez(integer rez_state)
    {
    }

    touch_start(integer total_number)
    {
        //llSay(0,llDetectedKey(0));
        //llDialog(llDetectedKey(0),"Please enter in the combination.",keypad,CHANNEL);
    }
    
    link_message(integer sender_num, integer signal, string message, key incoming_id) {
        if (signal == 3000) {
            MESSAGE = "";
            llSetTimerEvent(30);
            KEYPAD_CHANNEL = (integer)(llFrand(1000000) + 1000) * -1;
            KEYPAD_CHANNEL_HANDLE = llListen(KEYPAD_CHANNEL,"",NULL_KEY,"");
            if (message == "TIMER MODE") {
                ENTRY_STYLE = "TIMER MODE";
                llDialog(incoming_id,"Please enter the time requested:\n\nEntered: "+string2stringtime(MESSAGE),keypad,KEYPAD_CHANNEL);
            } else {
                llDialog(incoming_id,"Please enter in the combination.\n\nEntered: "+MESSAGE,keypad,KEYPAD_CHANNEL);
            }
        }
    }

    listen(integer heard_channel, string name, key id, string message) {
        //llSay(0,"You pressed "+message);
        if (heard_channel == KEYPAD_CHANNEL) {
            if (message == "E") {
                if (ENTRY_STYLE == "TIMER MODE") {
                    llMessageLinked(LINK_THIS,3002,stringtime2integertime(MESSAGE),id);
                } else {
                    llMessageLinked(LINK_THIS,3001,MESSAGE,id);
                }
            } else if (message == "C") {
                MESSAGE = "";
                if (ENTRY_STYLE == "TIMER MODE") {
                    llDialog(id,"Please enter in the time requested:\n\nEntered: "+string2stringtime(MESSAGE),keypad,KEYPAD_CHANNEL);
                } else {
                    llDialog(id,"Please enter in the combination.\n\nEntered: "+MESSAGE,keypad,KEYPAD_CHANNEL);
                }
            } else {
                MESSAGE += message;
                if (ENTRY_STYLE == "TIMER MODE") {
                    llDialog(id,"Please enter in the time requested:\n\nEntered: "+string2stringtime(MESSAGE),keypad,KEYPAD_CHANNEL);
                } else {
                    llDialog(id,"Please enter in the combination.\n\nEntered: "+MESSAGE,keypad,KEYPAD_CHANNEL);
                }
            }
        }
    }
    
    timer() {
        llListenRemove(KEYPAD_CHANNEL_HANDLE);
        }
}
