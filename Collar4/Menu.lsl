key sWelcomeGroup="49b2eab0-67e6-4d07-8df1-21d3e03069d0";
key sMainGroup="ce9356ec-47b1-5690-d759-04d8c8921476";
key sGuardGroup="b3947eb2-4151-bd6d-8c63-da967677bc69";
key sBlackGazzaRPStaff="900e67b1-5c64-7eb2-bdef-bc8c04582122";
key sOfficers="dd7ff140-9039-9116-4801-1f378af1a002";

integer menuChannel = 0;
integer menuListen = 0;

setUpMenu(key avatarKey, string message, list buttons)
{
    menuChannel = -(llFloor(llFrand(10000)+1000));
    llDialog(avatarKey, message, buttons, menuChannel);
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
}

playLevel(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "L-CON Collar - Set Play Level";
        list buttons = ["OOC", "Casual", "Normal", "Hard Core"];
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        
    }
}

zap(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "L-CON Collar - Set Maximum Zap";
        list buttons = ["Low", "Medium", "High"]; // needs checkboxes to reflect current state
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        string message = "L-CON Collar - Zap";
        list buttons = ["Low", "Medium", "High"]; // fix this so it only shows available levels
        setUpMenu(avatarKey, message, buttons);
    }
}

mood(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "L-CON Collar - Set Play Level";
        list buttons = ["OOC", "Submissive", "Versatile", "Dominant", "Nonsexual", "Story-Driven"];
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        ; // no one else gets a thing
    }
}

leash(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        ; // can't leash yourself. Well, you can, but you can't unleash yourself. 
    }
    else
    {
        ;
    }
}

crime(key avatarKey)
{;}

class(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        ;
    }
    else
    {
        ; // guards can set Unclassified/Orange/Blue/Pink/Green/Black
    }
}

info(key avatarKey)
{;}

lock(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "L-CON Collar - Lock";
        list buttons = ["Casual", "Normal", "Hardcore"];
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        ;
    }
}

hack(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "L-CON Collar - Attempt to Hack";
        list buttons = ["hack", "Maintenance", "Fix"];
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        ;
    }
}

default
{
    state_entry()
    {
    }

    touch_start(integer total_number)
    {
        key avatarKey  = llDetectedKey(0);
        integer isGroup = llDetectedGroup(0);
       
        string message = "L-CON Collar Control Main Menu";
        list buttons = ["Play Level", "Zap", "Mood", "Leash", "Crime", "Class", "Info", "Lock", "Hack"];
        setUpMenu(avatarKey, message, buttons);
    }
    
    listen( integer channel, string name, key avatarKey, string message ){
        llListenRemove(menuListen);
        menuListen = 0;
        if (message == "Play Level"){
            playLevel(avatarKey);
        }
        else if (message == "Zap"){
            zap(avatarKey);
        }
        else if (message == "Mood"){
            mood(avatarKey);
        }
        else if (message == "Leash"){
            leash(avatarKey);
        }
        else if (message == "Crime"){
            crime(avatarKey);
        }
        else if (message == "Class"){
            class(avatarKey);
        }
        else if (message == "Info"){
            info(avatarKey);
        }
        else if (message == "Lock"){
            lock(avatarKey);
        }
        else if (message == "Hack"){
            hack(avatarKey);
        }
                
        if (llGetOwner() == avatarKey)
         ; 
    }
    
    timer() 
    {
        llListenRemove(menuListen);
        menuListen = 0;    
    }
}
