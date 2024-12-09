// Domain Role Chooser
// Give person clicking this the ability to set their domain role. 

integer domainChannel = 4040;
integer domainListen = 0;
integer avatarDialogListen = 0;
integer avatarDialogChannel = 0;
key avatarKey;
string avatarName;

integer queryState = 0;
integer AUTHENTICATE = 1;
integer ASKROLE = 2;
integer SETROLE = 3;

queryDomain(integer newqueryState, string query) {
    domainListen = llListen(domainChannel,  "BlackGazza", "700acad0-381d-441c-f00a-82ef0be267e6", "");
    llSetTimerEvent(30);
    llRegionSay (4040, query);
    queryState = newqueryState;
}

default
{
    state_entry()
    {
        llSay(0, "Initializing");
        queryState = 0;
    }

    touch_start(integer total_number)
    {
        avatarKey = llDetectedKey(0);
        avatarName = llDetectedName(0);
        
        llWhisper (0,"Inquiring status of "+(string)avatarKey);
        queryDomain(AUTHENTICATE, "query "+(string)avatarKey);
    }
    
    listen( integer channel, string name, key id, string message ){
        llOwnerSay("listen "+(string)channel+" "+name+" "+(string)id+" "+message);
        
        if (channel == domainChannel) {
            if (queryState == AUTHENTICATE) {
                list responses = llParseString2List(message,[" "], []);
                string status = llList2String(responses,0);
                string inquireKey = llList2String(responses,1);
                if ((inquireKey == avatarKey) && (status != "none")) {
                    // authenticated: ask what role they want
                    queryState = ASKROLE;
                    list buttons = ["OOC", "Dynatic", "PodPrisoner", "BGCyborg", "BGRobot", "BGInmate"];
                    string message = "Select your Role in the Nanite Systems Domain 'BlackGazza':";
                    avatarDialogChannel = llFloor(llFrand(10000)) + 10000;
                    avatarDialogListen = llListen(avatarDialogChannel, "", "", "");
                    llSetTimerEvent(30);
                    llDialog(avatarKey, message, buttons, avatarDialogChannel);     
                }
            }
            
            if (queryState == SETROLE) {
                llWhisper(0,"SETROLE");
            }
        }
        
        if (channel == avatarDialogChannel) {
            if (queryState == ASKROLE) {
                llWhisper (0,"Setting role of "+avatarName+" to "+message);
                // role <role>
                // member <id>
                string command = 
                    "role "+message+"\n"+
                    "member "+(string)avatarKey;
                llWhisper(0,command);
                queryDomain(SETROLE, command);
            }
        }
    }
    
    timer() {
        if (avatarDialogChannel != 0) {
            llListenRemove(avatarDialogListen);
            avatarDialogChannel = 0;
        }
        
        if (domainListen != 0) {
            llListenRemove(domainListen);
            domainListen = 0;
        }
    }

}
