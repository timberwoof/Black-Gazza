integer marco_channel_handle;
integer marco_channel = -1;

integer RESPONSE = 0;
integer SHOCK = 0;
integer VIOLATION = 0;
integer VERBOSE = 1;
integer ROAM = 0;
integer WARNINGS = 0;

string PRISONER_ID;
string PRISONER_NAME;
string CRIME;

initialize() {
    llListenRemove(marco_channel_handle);
    marco_channel_handle = llListen(marco_channel,"",NULL_KEY,"");
    llSetTimerEvent(20.0);
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
    
    listen(integer channel, string name, key id, string message) {
    if (message == "Marco!") {
            RESPONSE = 1;
            llShout(-2,PRISONER_ID+" "+PRISONER_NAME+" ("+CRIME+")");
        }
    }
    
    timer() {
        if ((RESPONSE == 0) && (ROAM == 0)) {
            if (VERBOSE == 1) {
                WARNINGS++;
                if (WARNINGS < 5) {
                    llSay(0,"Inmate "+llKey2Name(llGetOwner())+" has strayed from tracking station.");
                } else {
                    if (SHOCK == 0) {
                        llSay(0,"Inmate "+llKey2Name(llGetOwner())+" is being punished for being away from the prison!");
                        llMessageLinked(LINK_SET,-80857873,"PUNISH",NULL_KEY);
                        SHOCK = 1;
                    } else {
                        SHOCK = 0;
                    }
                }
            }
            llMessageLinked(LINK_SET,555,"VIOLATION                 ","0");
            VIOLATION = 1;        
        } 
        if (RESPONSE == 1) {
            RESPONSE = 0;
            WARNINGS = 0;
        }
    }
    link_message(integer sender_num, integer link_num, string link_string, key id) {
        if (link_num == -68658465) {
            list parameters = llCSV2List(link_string);
            PRISONER_ID = llList2String(parameters,0);
            PRISONER_NAME = llList2String(parameters,1);
            CRIME = llList2String(parameters,2);
        }
        if (link_num == -82796577) {
            if (link_string == "ON") {
                llWhisper(0,llKey2Name(llGetOwner())+"'s collar is prison tethered.");
                llSetTimerEvent(20);
            } else {
                llWhisper(0,llKey2Name(llGetOwner())+"'s collar is untethered.");
            }
        }
    }
}
