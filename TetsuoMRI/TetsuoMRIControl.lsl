integer CONTROLCHANNEL = 1988;

integer KEYBOARD = 1;
integer BUTTONS = 0;
integer SCREEN = 3;

list OFF_MENU;
string OFF_MESSAGE = "Power is Off. Select a Function:";

list ON_MENU;
string ON_MESSAGE = "Power is ON. Select a Function:";

list STOW_MENU;
string STOW_MESSAGE = "Power is On; system is Stowed.";

list UNLOAD_MENU;
string UNLOAD_MESSAGE = "Power is On; system is Unloaded. load your patient.";

list LOAD_MENU;
string LOAD_MESSAGE = "Power is On; patient is Loaded.";

list READY_MENU;
string READY_MESSAGE = "Power is On; system is Ready for scan.";

list SCAN_MENU;
string SCAN_MESSAGE = "Power is On;  Scan is in progress.";

list MAINT_MENU;
string MAINT_MESSAGE = "Power is Off; Maintenance Mode.";

string SYSTEMSTATE;
string ON = "On";
string OFF = "Off";
string RESET = "Reset";
string MAINT = "Maint";
string STOW = "Stow";
string READY = "Ready";
string LOAD = "Load";
string SCAN = "Scan";
string UNLOAD = "Unload";
string STOP = "Stop";
string BLANK = "-";
string DOCS = "Manual";

vector LCARS = <-0.333, 0.333, 0>; 
vector LCARS_OFF = <-0.333, 0.333, 0>;
vector LCARS_MAINT = < 0.000, 0.333, 0>;
vector LCARS_RESET = < 0.333, 0.333, 0>;

vector LCARS_UNLOAD = <-0.333, 0.000, 0>;
vector LCARS_LOAD = < 0.000, 0.000, 0>;
vector LCARS_ON = < 0.333, 0.000, 0>;

vector LCARS_SCAN = <-0.333, -0.333, 0>;
vector LCARS_STOP = < 0.000, -0.333, 0>;
vector LCARS_READY = < 0.333, -0.333, 0>;

list BUTTON_VECTORS = [<.12,.60,0>, <.12,.44,0>, <.12,.28,0>, <.12,.12,0>, <.35,.75,0>, <.57,.75,0>, <.78,.75,0>];
list BUTTON_NAMES = ["Power","Load","Ready","Scan","Maint","Reset","Stop"];

string find_button(vector Touch)
{
    integer buttons = llGetListLength(BUTTON_VECTORS);
    integer i;
    for (i = 0; i < buttons; i++)
    {
        vector possible = llList2Vector(BUTTON_VECTORS, i);
        if (llVecDist(possible, Touch) < 0.10) return llList2String(BUTTON_NAMES, i);
    }
    return "";
}


key avatar;
integer avatarListen;
integer avatarChannel;

string sound_hum = "46157083-3135-fb2a-2beb-0f2c67893907";
string sound_beeps = "a4a9945e-8f73-58b8-8680-50cd460a3f46";
string jet_start = "1e6e6eec-737b-0bf7-25a1-9e6e4e2f7580";
string jet_loop = "a6fede89-6bc5-76cc-bd3a-01ef326ea239";
string jet_looop_fade = "41bcdb2a-d789-13f9-cb7f-0c5d05d8b5dd";
string warn = "fb0a28c3-4e7a-7554-0403-d8c3f56d1ccc";

string twToCapitalied(string anycase)
{
    return llToUpper(llGetSubString(anycase,0,0)) + llToLower(llGetSubString(anycase,1,-1));
}

power(integer ON)
{
    if (ON)
    {
        llSetColor(<1,1,1>,BUTTONS);
        llPlaySound(sound_beeps, 1.0);
        llLoopSound(sound_hum,1.0);
    }
    else
    {
        llStopSound();
        llSetColor(<.1,.1,.1>,BUTTONS);
    }
}

startActiveSound()
{
    llStopSound();
    llPlaySound(sound_beeps,1.0);
    //llSleep(1);
    //llPlaySound(jet_start,0.2);
    //llSleep(5);
    //llLoopSound(jet_loop,0.2);
}

endActiveSound()
{
    llStopSound();
    //llPlaySound(jet_looop_fade,0.2);
    //llSleep(6);
    //llLoopSound(sound_hum,1.0);
}

processMessage(string Message, string name, key id)
{
    // message from Central Scrutinizer could be upper- or lower-case
    // so we convert to lowercase for all comparisons. 
    // But the system state machine wants the canonical mix-case state names
    // so that is maintained in Message. 
        string oldSystemState = SYSTEMSTATE;
        string Message = twToCapitalied(Message);
        if (Message == ON)
        {
            power(1);
            llSay(CONTROLCHANNEL,ON);
            llSay(CONTROLCHANNEL,STOW);
            LCARS = LCARS_ON;
        } 
        else if (Message == OFF)
        {
            power(0);
            llSay(CONTROLCHANNEL,OFF);
            LCARS = LCARS_OFF;
        }
        else if (Message == RESET)
        {
            llOffsetTexture(LCARS_RESET.x, LCARS_RESET.y, SCREEN);
            llSay(CONTROLCHANNEL,"where?");
            power(1);
            LCARS = LCARS_ON;
        }
        else if (Message == STOP)
        {
            llOffsetTexture(LCARS_STOP.x, LCARS_STOP.y, SCREEN);
            endActiveSound();
            Message = READY;
            llSay(CONTROLCHANNEL,READY);
            LCARS = LCARS_READY;
        }
        else if (Message == READY)// && (name == "TetsuoMRIBed")) // why?
        {
            llSay(CONTROLCHANNEL,READY);
            LCARS = LCARS_READY;
        }
        else if (Message == MAINT)
        {
            llSay(CONTROLCHANNEL,MAINT);
            LCARS = LCARS_MAINT;
        }
        else if (Message == LOAD)
        {
            llSay(CONTROLCHANNEL,LOAD);
            LCARS = LCARS_LOAD;
        }
        else if (Message == SCAN)
        {
            startActiveSound();
            llSay(CONTROLCHANNEL,SCAN);
            LCARS = LCARS_SCAN;
        }
        else if (Message == UNLOAD)
        {
            llSay(CONTROLCHANNEL,UNLOAD);
            LCARS = LCARS_UNLOAD;
        }
        else if (Message == DOCS)
        {
            Message = oldSystemState;
            llGiveInventory(id, llGetInventoryName(INVENTORY_NOTECARD,0));
        }
        if (Message != "Reset")
        {
            SYSTEMSTATE = Message;
        }
        if (name == "CS")
        {
            llMessageLinked(LINK_THIS, 1, SYSTEMSTATE, "");
        }
        llOffsetTexture(LCARS.x, LCARS.y, SCREEN);
}

default
{
    state_entry()
    {
        // LOAD,UNLOAD,READY,SCAN,STOP,MAINT,STOW,OFF
        OFF_MENU = [ON, RESET, BLANK, MAINT, BLANK, BLANK, BLANK, BLANK, BLANK, DOCS];
        ON_MENU = [BLANK, BLANK, OFF, MAINT, BLANK, READY, BLANK, BLANK, UNLOAD, DOCS];
        STOW_MENU = [ON, BLANK, OFF, BLANK, BLANK, READY, BLANK, BLANK, UNLOAD, DOCS];
        UNLOAD_MENU = [BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, LOAD, BLANK, BLANK, DOCS];
        LOAD_MENU = [BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, UNLOAD, DOCS];
        READY_MENU = [ON, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, SCAN, BLANK, DOCS];
        MAINT_MENU = [ON, BLANK, OFF, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK, DOCS];
        SCAN_MENU = [STOP];
        SYSTEMSTATE = OFF;
        llSay(CONTROLCHANNEL,"where?");
        llListen(CONTROLCHANNEL,"TetsuoMRIBed","","Ready");
        llSay(CONTROLCHANNEL,OFF);
        llScaleTexture(0.3333, 0.3333, SCREEN);
        llOffsetTexture(LCARS.x, LCARS.y, SCREEN);
        power(0);
    }

    touch_start(integer total_number)
    {
        integer face = llDetectedTouchFace(0);
        
        if ((face == KEYBOARD) || (face == BUTTONS))
        {
            avatar = llDetectedKey(0);
            avatarChannel = llFloor(llFrand(10000)+1000);
            llListenRemove(avatarListen);
            avatarListen = llListen(avatarChannel,"",avatar,"");
            if (SYSTEMSTATE == OFF)
            {
                llDialog(avatar, OFF_MESSAGE, OFF_MENU, avatarChannel);
            }
            else if (SYSTEMSTATE == ON)
            {
                llDialog(avatar, ON_MESSAGE, ON_MENU, avatarChannel);
            }
            else if (SYSTEMSTATE == STOW)
            {
                llDialog(avatar, STOW_MESSAGE, STOW_MENU, avatarChannel);
            }
            else if (SYSTEMSTATE == UNLOAD)
            {
                llDialog(avatar, UNLOAD_MESSAGE, UNLOAD_MENU, avatarChannel);
            }
            else if (SYSTEMSTATE == LOAD)
            {
                llDialog(avatar, LOAD_MESSAGE, LOAD_MENU, avatarChannel);
            }
            else if (SYSTEMSTATE == READY)
            {
            llDialog(avatar, READY_MESSAGE, READY_MENU, avatarChannel);
            }
            else if (SYSTEMSTATE == SCAN)
            {
            llDialog(avatar, SCAN_MESSAGE, SCAN_MENU, avatarChannel);
            }
            else if (SYSTEMSTATE == MAINT)
            {
            llDialog(avatar, MAINT_MESSAGE, MAINT_MENU, avatarChannel);
            }
            llSetTimerEvent(30);
        }
        else if (face == SCREEN)
        {
            string todo = find_button(llDetectedTouchST(0));
            string Message = ""; // default is not to do anything. 
            //llWhisper(0,"todo:"+todo);
            //llWhisper(0,"SYSTEMSTATE:"+SYSTEMSTATE);
            if (todo == "Power"){
                if ((SYSTEMSTATE == ON) || (SYSTEMSTATE == MAINT))
                    Message = OFF;
                else if (SYSTEMSTATE == OFF)
                    Message = ON;
            } 
            else if (todo == "Load"){
                if ((SYSTEMSTATE == ON) || (SYSTEMSTATE == LOAD))
                    Message = UNLOAD;
                else if (SYSTEMSTATE == UNLOAD)
                    Message = LOAD;
            }
            else if (todo == READY && (SYSTEMSTATE == ON) || (SYSTEMSTATE == LOAD)) Message = READY;
            else if (todo == READY && SYSTEMSTATE == READY) Message = ON;
            else if (todo == SCAN && SYSTEMSTATE == READY) Message = SCAN;
            else if (todo == MAINT && (SYSTEMSTATE == ON || SYSTEMSTATE == OFF)) Message = MAINT;
            else if (todo == MAINT && SYSTEMSTATE == MAINT) Message = ON;
            else if (todo == RESET && SYSTEMSTATE == OFF) Message = RESET;
            else if (todo == STOP && SYSTEMSTATE == SCAN) Message = STOP;
            if (Message != "")
            {
                llPlaySound(sound_beeps, 1.0);
                processMessage(Message, "", "");
                //llWhisper(0,"State: "+Message);
            }
            else
            {   
                if (SYSTEMSTATE != OFF) llPlaySound(warn,.25);
            }
        }
    }
    
    // receive messages from the Central Scrutinizer Interface
    link_message(integer channel, integer num, string message, key id)
    {
        if (num == 0) processMessage(message, "CS", id);
    }
    
    // receive messages from the menu
    listen(integer channel, string name, key id, string message)
    {
        llListenRemove(avatarListen);
        processMessage(message, "", id);
    }
    
    timer()
    {
        llListenRemove(avatarListen);
    }
}
