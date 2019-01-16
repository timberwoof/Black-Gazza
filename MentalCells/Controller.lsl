// Medical ISolation Cell Controller
// Provide one menu to control six doors


integer CLOSED = 0;
integer OPEN = 1;

// doorStates 0..5 OPEN or CLOSED
list doorStates = [CLOSED,CLOSED,CLOSED,CLOSED,CLOSED,CLOSED];

integer gCommandChannelHandle;
integer gCommandChannel;
integer gCell;
string gMenuMode;

// code to make something fail of an electrical panel neary goes splodey
integer boomChannel = -8654876675;
integer resetTime = 60; 
integer enabled = 1;
integer controlPanelFace = 2;


showCommandMenu (key agent) {
    gMenuMode = "Command";
    list menuList = [];
    integer i;
    string actionString;
    for (i=1; i<=5; i++) {
        if (llList2Integer(doorStates,i) == CLOSED) {
            actionString = "Open";
        } else {
            actionString = "Close";
        }
        string buttonString = actionString + " " + (string)i;
        menuList = menuList + [buttonString];
    }
    menuList = menuList + ["Close All"];
    menuList = menuList + ["Open All"];
    menuList = menuList + ["Customize"];
    menuList = menuList + ["Info"];
    if (gCommandChannelHandle != 0) {
        llListenRemove(gCommandChannelHandle);
        }
    gCommandChannel = -1 * ((integer)llFrand(1000000)+1000000);
    gCommandChannelHandle = llListen(gCommandChannel,"",NULL_KEY,"");
    llDialog(agent,"Select A Command Function",menuList,gCommandChannel);
    llSetTimerEvent(30);
}

ListenCommand(integer channel, string name, key agent, string message) {
    list items = llParseString2List(message,[" "],[]);
    string command = llList2String(items,0);
    if (command == "Customize") 
    {
        pickCell(agent);
    }
    else if (command == "Info") 
    {
        llGiveInventory(agent, "BG Mental Ward Cells");
    }
    else 
    {
        string doors = llList2String(items,1);
        if (doors == "All") {
            integer i;
            for (i = 1; i <= 5; i++) 
            {
                integer desiredState;
                if (command == "Close") 
                {
                    desiredState = OPEN;
                } 
                else if (command == "Open") 
                {
                    desiredState = CLOSED;
                }
                
                if (llList2Integer(doorStates,i) == desiredState) {
                    llMessageLinked(LINK_ALL_CHILDREN, i, command, "");
                    string soundname = "touchtone" + (string)i;
                    llPlaySound(soundname,1);
                    llSleep(2);
                }
            }
        } 
        else 
        {
            integer door = llList2Integer(items,1);
            llMessageLinked(LINK_ALL_CHILDREN, door, command, "");
            string soundname = "touchtone" + (string)(door);
            llPlaySound(soundname,1);
        }
    }
}

pickCell (key agent) {
    gMenuMode = "PickCell";
    list menuList = [];
    integer i;
    string actionString;
    for (i=1; i<=5; i++) {
        menuList = menuList + [(string)i];
    }
    if (gCommandChannelHandle != 0) {
        llListenRemove(gCommandChannelHandle);
        }
    gCommandChannel = -1 * ((integer)llFrand(1000000)+1000000);
    gCommandChannelHandle = llListen(gCommandChannel,"",NULL_KEY,"");
    llDialog(agent,"Select A Cell to Customize",menuList,gCommandChannel);
    llSetTimerEvent(30);
}

ListePickCell (integer channel, string name, key agent, string message) {
    gCell = (integer)message;
    customize(agent);
}

customize (key agent) {
    gMenuMode = "Customize";
    list menuList = [];
    menuList = menuList + ["Rubber"];
    menuList = menuList + ["Canvas"];
    menuList = menuList + ["Pink"];
    menuList = menuList + ["Paws"];
    menuList = menuList + ["Old"];
    menuList = menuList + ["Small"];
    menuList = menuList + ["Medium"];
    menuList = menuList + ["Large"];
    if (gCommandChannelHandle != 0) {
        llListenRemove(gCommandChannelHandle);
        }
    gCommandChannel = -1 * ((integer)llFrand(1000000)+1000000);
    gCommandChannelHandle = llListen(gCommandChannel,"",NULL_KEY,"");
    llDialog(agent,"Customize Cell " + (string)gCell,menuList,gCommandChannel);
    llSetTimerEvent(30);
}

ListenCustomize (integer channel, string name, key agent, string command) {
    llMessageLinked(LINK_ALL_CHILDREN, gCell, command, "");
}



default
{
    state_entry()
    {
        llListen(boomChannel,"","","");
        gCommandChannelHandle = 0;
        enabled = 1;
        llSetColor(<0.25,0.25,0.25>,controlPanelFace);
        llSleep(2);
        llSetColor(<1,1,1>,controlPanelFace);
    }

    touch_start(integer total_number)
    {
        if (enabled == 1) {
            key toucher = llDetectedKey(0);
            if (llVecDist(llGetPos(),llDetectedPos(0)) > 3)
            {
                llWhisper (0,"((You are too far away from the controller.))");
            }
            else if (llSameGroup(toucher)) 
            {
                showCommandMenu(toucher);
            } 
            else 
            {
                llSay(0,"Unauthorized access detected. Retrieving records.");
                llSleep(2);
                llSay(0,"Inmate detected. Sending punishment code.");
                llSleep(2);
                llSay(-106969,(string)toucher);
            }
        }
    }
    
    listen (integer channel, string name, key agent, string message) {
        if (channel == boomChannel) {
            list xyz = llParseString2List( message, [","], ["<",">"]);
            vector distantloc;
            distantloc.x = llList2Float(xyz,1);
            distantloc.y = llList2Float(xyz,2);
            distantloc.z = llList2Float(xyz,3);
            vector here = llGetPos();
            float distance = llVecDist( here, distantloc );
            if (distance < 20) {
                llSetTimerEvent(resetTime);
                enabled = 0;
                llSetColor(<0.25,0.25,0.25>,controlPanelFace);
                // put your disable code in here
            }
        } else {
            if (gMenuMode == "Command") 
            {
                ListenCommand(channel, name, agent, message);
            } 
            else if (gMenuMode == "PickCell") 
            {
               ListePickCell(channel, name, agent, message);
            } 
            else if (gMenuMode == "Customize") 
            {
                ListenCustomize(channel, name, agent, message);
            } 
        } 
    }
        
     
    link_message(integer Sender, integer Number, string State, key Key) {
        llPlaySound("beepbeepbeepbeep",1);
        string soundname = "touchtone" + (string)Number;
        llPlaySound(soundname,1);
        integer newstate;
        if (State == "OPEN") 
        {
            newstate = OPEN;
        } 
        else if (State == "CLOSED") 
        {
            newstate = CLOSED;
        }
        else if (State == "occupied") 
        {
            llWhisper(0,"Cell "+(string)Number+" is now occupied. Closing in 5 seconds.");
            llSleep(5);
            llMessageLinked(LINK_ALL_CHILDREN, Number, "Close", "");
        }
        else if (State == "empty") 
        {
            llWhisper(0,"Cell "+(string)Number+" is empty. Opening.");
            llMessageLinked(LINK_ALL_CHILDREN, Number, "Open", "");
        }
        else 
        {
        }
        doorStates = llListReplaceList(doorStates,[newstate],Number,Number);
    }
    
    timer() {
        if (gCommandChannelHandle != 0) {
            llListenRemove(gCommandChannelHandle);
            gCommandChannelHandle = 0;
            }
        llSetTimerEvent(0);
        enabled = 1;
                llSetColor(<1,1,1>,controlPanelFace);
        }
}
