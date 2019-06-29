// Menu.lsl
// Menu script for Black Gazza Collar 4
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
string prisonerClass = "White";
string playLevel = "Casual";
string lockLevel = "";

string prisonerCrime = "Unknown";
string prisonerNumber = "Unknown";


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
    string completeMessage = prisonerNumber + " Collar: " + message;
    menuChannel = -(llFloor(llFrand(10000)+1000));
    llDialog(avatarKey, completeMessage, buttons, menuChannel);
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
        string message = "Set your Play Level";
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

zapMenu(key avatarKey)
{
    string message = "Set Permissible Zap";
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
        llMessageLinked(LINK_THIS, 1101, zapJsonList, "");
    }
    else
    {
        llMessageLinked(LINK_THIS, 1102, action, "");
    }

}

moodMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "Set your Mood";
        list buttons = [];
        buttons = buttons + menuRadioButton("OOC", ICOOCMood);
        buttons = buttons + menuRadioButton("Submissive", ICOOCMood);
        buttons = buttons + menuRadioButton("Versatile", ICOOCMood);
        buttons = buttons + menuRadioButton("Dominant", ICOOCMood);
        buttons = buttons + menuRadioButton("Nonsexual", ICOOCMood);
        buttons = buttons + menuRadioButton("Story", ICOOCMood);
        buttons = buttons + menuRadioButton("DnD", ICOOCMood);
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

crimeDialog(key avatarKey) {
    llWhisper(0,prisonerCrime);
}

classMenu(key avatarKey)
{
    if (avatarKey == llGetOwner())
    {
        string message = "Set Prisoner Class";
        list buttons = [];
        buttons = buttons + menuRadioButton("White", prisonerClass);
        buttons = buttons + menuRadioButton("Pink", prisonerClass);
        buttons = buttons + menuRadioButton("Red", prisonerClass);
        buttons = buttons + menuRadioButton("Orange", prisonerClass);
        buttons = buttons + menuRadioButton("Green", prisonerClass);
        buttons = buttons + menuRadioButton("Blue", prisonerClass);
        buttons = buttons + menuRadioButton("Black", prisonerClass);
        setUpMenu(avatarKey, message, buttons);
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
        string message = "Lock";
        list buttons = [];
        buttons = buttons + menuRadioButton("Off", lockLevel);
        buttons = buttons + menuRadioButton("Normal", lockLevel);
        buttons = buttons + menuRadioButton("Hardcore", lockLevel);
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
        string message = "Hack";
        list buttons = ["hack", "Maintenance", "Fix"];
        setUpMenu(avatarKey, message, buttons);
    }
    else
    {
        ;
    }
}

mainMenu(key avatarKey, string message) {
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
       
        string message = "Main Menu";
        list buttons = ["Play Level", "Zap", "Mood", "Leash", "Crime", "Class", "Info", "Lock", "Hack"];
        setUpMenu(avatarKey, message, buttons);
    }
    
    listen( integer channel, string name, key avatarKey, string message ){
        llListenRemove(menuListen);
        menuListen = 0;
        string messageNoButtons = llStringTrim(llGetSubString(message,2,11), STRING_TRIM);
        debug("listen:"+message+" messageNoButtons:"+messageNoButtons);
        
        //Main
        if (llSubStringIndex("Play Level Zap Mood Leash Crime Class Info Lock Hack", message) > -1){
            llWhisper(0,"listen: Main:"+message);
             mainMenu(avatarKey, message);
        }
        
        // Mood
        else if (llSubStringIndex("OOC Submissive Versatile Dominant Nonsexual Story DnD",  messageNoButtons) > -1){
            llWhisper(0,"listen: Mood:"+messageNoButtons);
            ICOOCMood = messageNoButtons;
            llMessageLinked(LINK_THIS, 1100, ICOOCMood, "");
        }
        
        //Class
        else if (llSubStringIndex("White Pink Red Orange Green Blue Black", messageNoButtons) > -1){
            llWhisper(0,"listen: Class:"+messageNoButtons);
            prisonerClass = messageNoButtons;
            llMessageLinked(LINK_THIS, 1200, prisonerClass, "");
        }
        
        // Zap
        else if (llGetSubString(message,2,4) == "Zap"){
            llWhisper(0,"listen: Zap:"+message);
            doZap(avatarKey, message);
        }
        
        // Play Level
        else if (llSubStringIndex("Casual Normal Hard Core", messageNoButtons) > -1){
            llWhisper(0,"listen: playLevel:"+messageNoButtons);
            playLevel = messageNoButtons;
            llMessageLinked(LINK_THIS, 1300, playLevel, "");
        }

        // Lock Level
        else if (llSubStringIndex("Off Normal Hard Core", messageNoButtons) > -1){
            llWhisper(0,"listen: lockLevel:"+messageNoButtons);
            lockLevel = messageNoButtons;
            llMessageLinked(LINK_THIS, 1400, lockLevel, "");
        }

                
        if (llGetOwner() == avatarKey)
         ; 
    }
    
    link_message( integer sender_num, integer num, string message, key id ){ 
        llWhisper(0,"Menu link_message "+(string)num+" "+message);
        if (num == 2000) {
            list returned = llParseString2List(message, [","], []);
            prisonerCrime = llList2String(returned, 2);
            prisonerNumber = llList2String(returned, 4);
        }
    }

    
    timer() 
    {
        llListenRemove(menuListen);
        menuListen = 0;    
    }
}
