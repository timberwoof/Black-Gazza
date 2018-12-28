
integer rlv_channel;
integer rlv_channel_handle;

integer command_channel;
integer command_channel_handle;

list KNOWN_AVATARS;
list KNOWN_AVATARS_RLV;

//list DEFAULT_RLV = ["UNSIT","SHOW INV","TP","IN IM","OUT IM","MAPS","ADMIN","WEAR","FLY","ID"];
list DEFAULT_RLV = ["TP","MAPS","ADMIN","FLY"];
list WINDOW_RLV = ["TP","MAPS","HEARING","WHISPERING","ADMIN","FLY","ID"]
list CURRENT_RLV;
list ALL_RLV;
list RLV_TX;
list RLV_MESSAGES;
integer THROW_MENU = 0;

integer RLV_NUMBER_OF_COMMANDS = 0;


key ME;

key VICTIM;

initialize() {
    ME = llGetKey();
    //llSensorRepeat("",NULL_KEY,AGENT,10,PI,5);
    rlv_channel = -1812221819;
    llListenRemove(rlv_channel_handle);
    rlv_channel_handle = llListen(rlv_channel,"",NULL_KEY,"");
    
    llListenRemove(command_channel_handle);
    command_channel = -1 * (integer)llFrand(10000000) + 100000;
    llListen(command_channel,"",NULL_KEY,"");
    
    CURRENT_RLV = [];
    ALL_RLV = ["UNSIT",
               "SHOW INV",
               "TP",
               "HEARING",
               "SPEAKING",
               "WHISPERING",
               "IN IM",
               "OUT IM",
               "MAPS",
               "ADMIN",
               "WEAR",
               "FLY",
               "ID"];
    RLV_TX = ["@unsit=",
              "@showinv=",
              "@tplm=,@tploc=,@tplure=,@sittp=",
              "@recvchat=",
              "@chatshout=,@chatnormal=,@chatwhisper=,@sendchat=",
              "@chatshout=,@chatnormal=",
              "@recvim=",
              "@sendim=",
              "@showloc=,@showminimap=,@showworldmap=",
              "@edit=,@rez=,@fartouch=",
              "@detach=,@addoutfit=,@remoutfit=,@detach=",
              "@fly=",
              "@shownames="];
}  

init(key i_victim) {
    llSay(0,"Running init on: "+llKey2Name(i_victim)); 
    VICTIM = i_victim;
    integer count;
    string default_rlv_string;
    RLV_NUMBER_OF_COMMANDS = 0;
    
    for (count = 0; count < llGetListLength(DEFAULT_RLV); count++) {
        integer rule_count;
        integer t_count = llListFindList(ALL_RLV,[llList2String(DEFAULT_RLV,count)]);
        //llSay(0,"Implementing: "+llList2String(DEFAULT_RLV,count)); // ***
        list sub_commands = llCSV2List(llList2String(RLV_TX,t_count));
        for (rule_count = 0; rule_count < llGetListLength(sub_commands); rule_count++) {
            default_rlv_string += llList2String(sub_commands,rule_count)+"n|";
            RLV_NUMBER_OF_COMMANDS++;
        }
    }
    llSay(rlv_channel,"INIT,"+(string)VICTIM+","+default_rlv_string);
    llSetTimerEvent(5);
    CURRENT_RLV = DEFAULT_RLV;
}

release(key r_victim) {
    llSay(rlv_channel,"RELEASE,"+(string)r_victim+",!release");
    CURRENT_RLV = [];
    llMessageLinked(LINK_SET,rlv_channel,"RLV OFF",NULL_KEY);
    VICTIM = NULL_KEY;
}

menu(key commander) {
    list rlv_menu = [];
    integer rlv_elements;
    
    list RLV_STRING;
    if (VICTIM) {
        RLV_STRING = CURRENT_RLV;
    } else {
        RLV_STRING = DEFAULT_RLV;
    }
    
    for (rlv_elements = 0; rlv_elements < llGetListLength(ALL_RLV); rlv_elements++) {
        if (llListFindList(RLV_STRING,[llList2String(ALL_RLV,rlv_elements)]) == -1) {
            string t_str = "-" + llList2String(ALL_RLV,rlv_elements);
            rlv_menu += [t_str];
        } else {
            string t_str = "+" + llList2String(ALL_RLV,rlv_elements);
            rlv_menu += [t_str];
        }
    }
    
    if (VICTIM) {
        llDialog(commander, "Choose a RLV Feature To Change:",rlv_menu,command_channel);
    } else {
        llDialog(commander, "Choose a Default RLV Feature To Change:",rlv_menu,command_channel);
    }
}

disable_rlv(string command, key commander) {
    
    list RLV_STRING;
    if (VICTIM) {
        RLV_STRING = CURRENT_RLV;
    } else {
        RLV_STRING = DEFAULT_RLV;
        //llOwnerSay("disable -- DEFAULT");
    }
    
    integer current_rlv_position = llListFindList(RLV_STRING,[command]);
    if (current_rlv_position != -1) {
        integer rlv_element = llListFindList(ALL_RLV,[command]);
        list rlv_commands = llCSV2List(llList2String(RLV_TX,rlv_element));
        integer rlv_atom;
        string serial_rlv;
        for (rlv_atom = 0; rlv_atom < llGetListLength(rlv_commands); rlv_atom++) {
            serial_rlv += llList2String(rlv_commands,rlv_atom)+"y|";
        }
        
        if (VICTIM) {
            llSay(rlv_channel,"COMMAND,"+(string)VICTIM+","+serial_rlv);
            CURRENT_RLV = llDeleteSubList(CURRENT_RLV,current_rlv_position,current_rlv_position);
        } else {
            DEFAULT_RLV = llDeleteSubList(DEFAULT_RLV,current_rlv_position,current_rlv_position);
            //llOwnerSay("DEFAULT");
        }   
    }
    if (THROW_MENU == 1) {
        THROW_MENU = 0;
        menu(commander); 
    }         
}

enable_rlv(string command, key commander) {
    
    list RLV_STRING;
    if (VICTIM) {
        RLV_STRING = CURRENT_RLV;
    } else {
        RLV_STRING = DEFAULT_RLV;
        //llOwnerSay("enable -- DEFAULT");
    }
    
    integer current_rlv_position = llListFindList(RLV_STRING,[command]);
    if (current_rlv_position == -1) {
        integer rlv_element = llListFindList(ALL_RLV,[command]);
        list rlv_commands = llCSV2List(llList2String(RLV_TX,rlv_element));
        integer rlv_atom;
        string serial_rlv;
        for (rlv_atom = 0; rlv_atom < llGetListLength(rlv_commands); rlv_atom++) {
            serial_rlv += llList2String(rlv_commands,rlv_atom)+"n|";
        }
        if (VICTIM) {
            llSay(rlv_channel,"COMMAND,"+(string)VICTIM+","+serial_rlv);
            CURRENT_RLV += [command];
        } else {
            DEFAULT_RLV += [command];
            //llOwnerSay("DEFAULT");
        }
    }
    if (THROW_MENU == 1) {
        THROW_MENU = 0;
        menu(commander);
    }      
}


default
{
    state_entry()
    {
        initialize();
    }
    
    on_rez(integer rez_state) {
        initialize();
    }

    touch_start(integer total_number)
    {
        //llSay(0, "Touched.");
    }
    
    timer() {
        if (RLV_NUMBER_OF_COMMANDS != 0) {
            llSay(0,"No RLV on Target. Doing the best I can.");
            llMessageLinked(LINK_SET,rlv_channel,"RLV KO",NULL_KEY);
            llSetTimerEvent(0);
        }
    }
    
    listen(integer incoming_channel, string incoming_name, key incoming_key, string incoming_message) {
        if (incoming_channel == rlv_channel) {
            //llOwnerSay("I heard something on the RLV channel: "+incoming_message);
            
            if (incoming_message == "ping,"+(string)llGetKey()+",ping,ping") {
                llShout(rlv_channel,"ping,"+(string)VICTIM+",pong!");
            }
            
            list rlv_data = llCSV2List(incoming_message);
            if ((key)llList2String(rlv_data,1) == ME) {
                if (llList2String(rlv_data,0) == "INIT") {
                    RLV_NUMBER_OF_COMMANDS--;
                    if (RLV_NUMBER_OF_COMMANDS == 0) {
                        llSay(0,"Target Has Been RLV Locked.");
                        llMessageLinked(LINK_SET,rlv_channel,"RLV OK",NULL_KEY);
                        llSetTimerEvent(0);
                    }
                } else if (llList2String(rlv_data,0) == "RELEASE") {
                    llSay(0,"Target Has Been RLV Released.");  
                    
                }
            }
        } else if (incoming_channel == command_channel) {
            //llSay(0,incoming_message);
            THROW_MENU = 1; 
            llMessageLinked(LINK_THIS,rlv_channel,incoming_message,incoming_key);
            
        }
    }
    link_message(integer sender_num, integer i_message, string s_message, key k_key) {
        if (i_message == rlv_channel) {
            if (s_message == "INIT") {
                init(k_key);
            } else if (s_message == "RELEASE") {
                release(VICTIM);
            } else if (s_message == "MENU") {
                menu(k_key);
            } else if (s_message == "NAKED") {
                
                llWhisper(0,(string)llListFindList(CURRENT_RLV,["WEAR"]));
                if (llListFindList(CURRENT_RLV,["WEAR"]) > -1) {
                    llSay(0,"Running Flair.");
                    llShout(rlv_channel,"UNWEAR,"+(string)VICTIM+",@remoutfit=y");
                    llSleep(2);
                    llWhisper(0,"1");
                    llShout(rlv_channel,"NAKED,"+(string)VICTIM+",@remoutfit=force");
                    llSleep(2);
                    llWhisper(0,"2");
                    llShout(rlv_channel,"WEAR,"+(string)VICTIM+",@remoutfit=n");
                } else {
                    llShout(rlv_channel,"NAKED,"+(string)VICTIM+",@remoutfit=force");
                }
            } else {
                string root_command = llGetSubString(s_message,1,-1);
                string function_command = llGetSubString(s_message,0,0);

                if (llListFindList(ALL_RLV,[root_command]) != -1) {
                    // Do The RLV Function.
                    if (function_command == "+") {
                        //llWhisper(0,"Enabling "+root_command);  // ***
                        disable_rlv(root_command, k_key);
                    } else if (function_command == "-") {
                        //llWhisper(0,"Disabling "+root_command); // ***
                        enable_rlv(root_command,k_key);
                    }
                }
            }
        }
    }
}
