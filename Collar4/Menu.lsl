// Menu.lsl
// Menu scuopt for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019

// reference: useful unicode characters
// https://unicode-search.net/unicode-namesearch.pl?term=CIRCLE

key sWelcomeGroup="49b2eab0-67e6-4d07-8df1-21d3e03069d0";
key sMainGroup="ce9356ec-47b1-5690-d759-04d8c8921476";
key sGuardGroup="b3947eb2-4151-bd6d-8c63-da967677bc69";
key sBlackGazzaRPStaff="900e67b1-5c64-7eb2-bdef-bc8c04582122";
key sOfficers="dd7ff140-9039-9116-4801-1f378af1a002";

integer OPTION_DEBUG = 1;

integer menuChannel = 0;
integer menuListen = 0;

integer allowZapLow = 1;
integer allowZapMed = 1;
integer allowZapHigh = 1;

string ICOOCMood = "OOC";
string playLevel = "Casual";

debug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,message);
    }
}

integer invert(integer boolie)
{
    if (boolie == 1) 
        return 0;
    else
        return 1;
}

setUpMenu(key avatarKey, string message, list buttons)
{
    menuChannel = -(llFloor(llFrand(10000)+1000));
    llDialog(avatarKey, message, buttons, menuChannel);
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
}

list menuCheckbox(string title, integer onOff)
// make checkbox item out of a button title and boolean state
{
    string checkbox;
    if (onOff)
    {
        checkbox = "☒";
    }
    else
    {
        checkbox = "☐";
    }
    return [checkbox + " " + title];
}

list menuRadioButton(string title, string match)
// make radio button item out of a button and the state text
{
    string radiobutton;
    if (title == match)
    {
        radiobutton = "●";
    }
    else
    {
        radiobutton = "○";
    }
    return [radiobutton + " " + title];
}

playLevelMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "L-CON Collar - Set Your Play Level";
        list buttons = [];
        buttons = buttons + menuRadioButton("Casual", playLevel);
        buttons = buttons + menuRadioButton("Normal", playLevel);
        buttons = buttons + menuRadioButton("Hard Core", playLevel);
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        llInstantMessage(avatarKey,playLevel);
    }
}

setPlayLevel(string message)
{
    playLevel = llStringTrim(llGetSubString(message,2,10), STRING_TRIM);
    llMessageLinked(LINK_THIS, 2001, playLevel, "");
}

zapMenu(key avatarKey)
{
    string message = "L-CON Collar - Set Permissible Zap";
    list buttons = [];
    buttons = buttons + menuCheckbox("Zap Low", allowZapLow);
    buttons = buttons + menuCheckbox("Zap Med", allowZapMed);
    buttons = buttons + menuCheckbox("Zap Hi", allowZapHigh);
    setUpMenu(avatarKey, message, buttons);
}

doZap(key avatarKey, string message)
{
    string checkbox = llGetSubString(message,0,0);
    string action = llGetSubString(message,6,10);
    if (avatarKey == llGetOwner()) 
    {
        debug("wearer sets allowable zap level: "+action);
        if (action == "Low") {
            allowZapLow = invert(allowZapLow);
        } else if (action == "Med") {
            allowZapMed = invert(allowZapMed);
        } else if (action == "Hi") {
            allowZapHigh = invert(allowZapHigh);
        }
        string zapJsonList = llList2Json(JSON_ARRAY, [allowZapLow, allowZapMed, allowZapHigh]);
        llMessageLinked(LINK_THIS, 1001, zapJsonList, "");
    }
    else
    {
        llMessageLinked(LINK_THIS, 1002, action, "");
    }

}

moodMenu(key avatarKey)
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

leashMenu(key avatarKey)
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

crimeDialog(key avatarKey)
{;}

classMenu(key avatarKey)
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

infoGive(key avatarKey)
{;}

lockMenu(key avatarKey)
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

hackMenu(key avatarKey)
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
        debug("listen:"+message);
        llListenRemove(menuListen);
        menuListen = 0;
        if (message == "Play Level"){
            playLevelMenu(avatarKey);
        }
        else if (message == "Zap"){
            zapMenu(avatarKey);
        }
        else if (message == "Mood"){
            moodMenu(avatarKey);
        }
        else if (message == "Leash"){
            leashMenu(avatarKey);
        }
        else if (message == "Crime"){
            crimeDialog(avatarKey);
        }
        else if (message == "Class"){
            classMenu(avatarKey);
        }
        else if (message == "Info"){
            infoGive(avatarKey);
        }
        else if (message == "Lock"){
            lockMenu(avatarKey);
        }
        else if (message == "Hack"){
            hackMenu(avatarKey);
        }
        
        else if (llGetSubString(message,2,4) == "Zap"){
            doZap(avatarKey, message);
        }
        
        else if (llSubStringIndex("Casual Normal Hard Core", llStringTrim(llGetSubString(message,2,10), STRING_TRIM)) > -1){
            setPlayLevel(message);
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
