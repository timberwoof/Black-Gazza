// Collar Control Script 1-11-09
integer main_channel; 
//integer crime_channel;
integer ping_channel;
integer command_channel;

integer COM_CHANNEL = -282367354;
integer random_main_channel;
string C_ID;
key C_OWNER;
string C_OWNER_STR;

integer CHANNEL=-1;
integer LOCK_TIME;
integer DISPLAY_INFO = 0;
integer DEATH = 0;
integer ROAM = 0; 
integer CLOTHES = 1;
integer SHOCK = 0;

string LOCK_STATE = "UNLOCKED";

vector BASE_COLOR = <0.0,0.0,1.0>;
vector PUNISH_COLOR = <1.0,0.0,0.0>; 
vector DEATH_COLOR = <0.0,1.0,0.0>;

integer RELAY_CHANNEL = -1812221819;
integer PUNISH_CHANNEL = -80857873;
integer DATA_CHANNEL = 0;
integer DATA_CHANNEL_HANDLE = 0;
integer DATA_TIMEOUT = 0;

integer LM_OPTIONDATA = 10002;
integer LM_MENULOADED = 10003;
integer LM_READSTRINGDATA = 10006;

integer LM_EXT_SHOCK = 60000;
integer LM_EXT_UNLOCK = 60001;
integer LM_EXT_LOCK = 60002;
integer LM_EXT_DRAG = 60003;
integer LM_EXT_TELEPORT = 60004;
integer LM_TELEPORT_SIGNAL = -90000;


list COLLAR_MENU;
string CRIME;
string URL = "http://shye.org/bg/";

integer LOCK_ON_INIT = 1;
integer SENTENCE_TIME = 0;

key IN_HTTP;
key OUT_HTTP;

integer activated = 0;

integer ACCESS_OWNER = 0;
integer ACCESS_OTHER = 1;
integer ACCESS_GUARD = 2;

violation() {
     llMessageLinked(LINK_SET,555,"VIOLATION                 ","0");          
}

lock(key id)
{
    rlv_on();
    
    if(id != NULL_KEY){
        llSay(0,llKey2Name(id)+" has locked "+llKey2Name(llGetOwner())+"'s collar.");    
    }else{
        llSay(0,llKey2Name(llGetOwner())+"'s collar locks tightly.");
    }
    
    LOCK_STATE = "LOCKED";    
}

unlock()
{
    llSay(0,llKey2Name(llGetOwner())+"'s collar clicks as the lock opens.");
    release_collar();
}

toucher(key requestor, integer access)
{
        list MOD_COLLAR_MENU = COLLAR_MENU;

        //If they are a Guard...
        if(access >= ACCESS_GUARD){
            MOD_COLLAR_MENU += ["RLV"];
            
            MOD_COLLAR_MENU += ["Crime"];
            
            if (ROAM == 0) {
                MOD_COLLAR_MENU += ["Roam"];
            } else {
                MOD_COLLAR_MENU += ["No Roam"];
            }
            
            if (LOCK_STATE == "LOCKED") {
                MOD_COLLAR_MENU += ["Unlock"];
            }
            
            MOD_COLLAR_MENU += ["Punish"];
        }
        
        //If they are another inmate...
        if(access >= ACCESS_OTHER){
            MOD_COLLAR_MENU += ["Leash"];
        }
        
        //If they are themselves, or a Guard (No public)
        if(access == ACCESS_OWNER || access == ACCESS_GUARD){
            MOD_COLLAR_MENU += ["Resync","Punish","Leash"]; // Change This to Just Resync
            
            if (LOCK_STATE == "UNLOCKED") {
                MOD_COLLAR_MENU += ["Lock"];
            } else {
                MOD_COLLAR_MENU += ["Safeword"];
            }
            
            if (DISPLAY_INFO == 0) { 
                MOD_COLLAR_MENU += ["IC"];
            } else {
                MOD_COLLAR_MENU += ["OOC"];
            }
        }
        llDialog(requestor, "Black Gazza Collar Control",MOD_COLLAR_MENU, random_main_channel);
}

display_info() {
    if (DISPLAY_INFO == 1) {
       llSetText("BLACK GAZZA INMATE "+llKey2Name(llGetOwner())+"\n\nID: "+C_ID+"\nCRIME: "+CRIME+"\n \n \n \n \n \n",<1.0,1.0,1.0>,1.0);
    } else {
       llSetText("",<1.0,1.0,1.0>,1.0);
    }
}
    
g_state_entry() {
        activated = 1;
        
        llSay(0,"Collar Reinitializing.");
        llSetText("",<1.0,1.0,1.0>,1.0);
        C_OWNER = llGetOwner();
        C_OWNER_STR = llKey2Name(C_OWNER);
        string S_C_OWNER = (string)C_OWNER;
        
        random_main_channel = (llFloor(llFrand(100000.0)) + 1000) * -1;
        main_channel = llListen(random_main_channel,"","","");
        ping_channel = llListen(CHANNEL,"","","");
        command_channel = llListen(COM_CHANNEL, "", "", "");
        
        llSetTimerEvent(20.0);

        COLLAR_MENU = [];
        
        string final_url = URL+"read_inmate.cgi?key="+S_C_OWNER;
        
        if (LOCK_ON_INIT == 1) {
            lock(NULL_KEY);
        }
        llSay(0,llKey2Name(llGetOwner())+"'s collar is being resynced.");
        S_C_OWNER = (string)llGetOwner();
        llHTTPRequest(final_url,[],"");
        display_info();
}

rlv_on() {
    LOCK_STATE="LOCKED";
    llMessageLinked(LINK_THIS,RELAY_CHANNEL,"INIT",llGetOwner());
    llMessageLinked(LINK_THIS,RELAY_CHANNEL,"STICKY",llGetOwner());
}

release_collar() {
    llMessageLinked(LINK_THIS,RELAY_CHANNEL,"UNSTICK",llGetOwner());
    llMessageLinked(LINK_THIS,RELAY_CHANNEL,"RELEASE",llGetOwner());
}

default
{
    
    state_entry()
    {
        if(llGetStartParameter() == 1)
            return;
            
        g_state_entry();
    }
    
    http_response(key request_id, integer status, list metadata, string body) {
        if(!activated) {return;}
        if (request_id !=  IN_HTTP) {
            list inmate_data = llCSV2List(body); 
            string inmate_number = llList2String(inmate_data,4);
            C_ID = inmate_number;
            CRIME = llList2String(inmate_data,2);
            llMessageLinked(LINK_SET,555,"  "+C_ID+"                 ","0");
            //llSetColor(BASE_COLOR,ALL_SIDES);
            display_info();
            llMessageLinked(LINK_SET,-68658465,C_ID+","+llKey2Name(llGetOwner())+","+CRIME,NULL_KEY);
        }
    }      
    
    link_message(integer link, integer num, string msg, key id)
    {
        //if(link == LINK_THIS){
        if(num == -1000){
            llResetScript();
        }else if(num == LM_EXT_SHOCK){
            //llOwnerSay("Arf");
            llMessageLinked(LINK_SET,-80857873,msg,id);
        }else if(num == LM_EXT_UNLOCK){
            llSay(0,llKey2Name(llGetOwner())+"'s collar clicks as the lock opens.");
            release_collar(); 
        }else if(num == LM_EXT_LOCK){
            lock(NULL_KEY);
        }else if(num == LM_EXT_UNLOCK){
            unlock();
        }else if(num == LM_EXT_DRAG){
            llOwnerSay("Drag");
            llMoveToTarget((vector)msg, 0.1);
            llSleep(0.1);
            llStopMoveToTarget();
        }else if(num == LM_EXT_TELEPORT){
            vector d = (vector)msg;
            string test = llGetRegionName() + "/" + (string)d.x + "/" + (string)d.y + "/" + (string)d.z;
            llMessageLinked(LINK_THIS, LM_TELEPORT_SIGNAL, test, NULL_KEY);
        } else if (num == RELAY_CHANNEL) {
            if (msg == "RELEASE") {
                LOCK_STATE = "UNLOCKED";;
            }
        }
        //}
    }
    
    touch_start(integer count)
    {
        key id = llDetectedKey(0);
        if(id == llGetOwner()){
            toucher(id, ACCESS_OWNER);
        }else{
            toucher(id, ACCESS_OTHER);
        }
    }
          
    on_rez(integer start){
        C_OWNER = llGetOwner();
        C_OWNER_STR = llKey2Name(C_OWNER);
        g_state_entry();
    }
    
    timer() {
        if(!activated) {return;}
        if (DATA_TIMEOUT > 0) {
            DATA_TIMEOUT -= 1;
            if (DATA_TIMEOUT == 0) {
                llListenRemove(DATA_CHANNEL_HANDLE);
            }
        }
    }

    listen(integer channel, string name, key id, string message) {
         if(!activated) {return;}
        integer collartitle_search = llSubStringIndex(message,"@collartitle");
        if(channel == COM_CHANNEL){
            list parser = llParseStringKeepNulls(message, ["~"], []);
            key sender;
            string command;
            if((key)llList2String(parser, 0) != llGetOwner() )
                return;
                
            sender = (key)llList2String(parser, 1);
            command = llList2String(parser, 2);
            
            if(command == "MENU"){
                toucher(sender,ACCESS_GUARD);
            }
            return;   
        } 
        
        
        if (channel == DATA_CHANNEL) {
            CRIME = message; 
            llSay(0,llKey2Name(llGetOwner())+"'s Crime has been set to: "+message);
            llListenRemove(DATA_CHANNEL_HANDLE);
            DATA_TIMEOUT = 0;
            string url_crime = llEscapeURL(CRIME);
            IN_HTTP = llHTTPRequest(URL+"add_inmate.cgi?key="+(string)llGetOwner()+"&crime="+url_crime+"&sentence=0",[],"");
            string S_C_OWNER = (string)llGetOwner();
            string final_url = URL+"read_inmate.cgi?key="+S_C_OWNER+"";
            llHTTPRequest(final_url,[],"");
            llSay(0,llKey2Name(llGetOwner())+"'s collar is being resynced.");
            display_info();
        }
        if (collartitle_search != -1) {
            //foo
            collartitle_search += 13;
            llMessageLinked(LINK_SET,555,llGetSubString(llToUpper(message),collartitle_search,-4),"0");
            
        }
  
        if (channel == random_main_channel) {
            
        if (message=="Show Number") {
                llMessageLinked(LINK_SET,555,"  "+C_ID+"                 ","0");
        } else if (message=="Crime") {
            DATA_CHANNEL = (integer)llFrand(8999)+1000;
            DATA_TIMEOUT = 10;
            llSay(0,"Please say on channel "+(string)DATA_CHANNEL+" the crime committed by "+llKey2Name(llGetOwner()));
            DATA_CHANNEL_HANDLE = llListen(DATA_CHANNEL,"",id,"");
        } else if (message=="Lock") {
            lock(id);
        } else if (message=="IC") {
            DISPLAY_INFO = 1;
            llSay(0,llKey2Name(llGetOwner())+" has now gone In Character.");
            display_info();
        } else if (message=="OOC") {
            DISPLAY_INFO = 0;
            display_info();
            llSay(0,llKey2Name(llGetOwner())+" has now gone Out Of Character.");
        } else if (message=="Resync") {
            llSay(0,llKey2Name(llGetOwner())+"'s collar is being resynced.");
            string S_C_OWNER = (string)llGetOwner();
            string final_url = URL+"read_inmate.cgi?key="+S_C_OWNER+"";
            llHTTPRequest(final_url,[],"");             
        } else if (message=="RLV") {
            llMessageLinked(LINK_THIS,0,"RLV",id);
        } else if (message=="Leash") {
            llMessageLinked(LINK_SET,3002,"Leash",id);
        } else if (message=="Punish") {
            llMessageLinked(LINK_SET,-80857873,"",id);
        } else if (message=="Safeword") {
            llMessageLinked(LINK_SET,-83657069,"",id);
        } else if (message=="Roam") {
            llMessageLinked(LINK_SET,-82796577,"OFF",NULL_KEY);
        } else if (message=="No Roam") {
            llMessageLinked(LINK_SET,-82796577,"ON",NULL_KEY);
        }
        }
    }
}
