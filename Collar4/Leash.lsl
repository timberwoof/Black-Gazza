integer OPTION_DEBUG = 1;
string prisonerNumber = "P-99999";
integer menuChannel = 0;
integer menuListen = 0;
key leashAvatar;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Menu:"+message);
    }
}

setUpMenu(key avatarKey, string message, list buttons)
// wrapper to do all the calls that make a simple menu dialog.
{
    string completeMessage = prisonerNumber + " Collar: " + message;
    menuChannel = -(llFloor(llFrand(10000)+1000));
    llDialog(avatarKey, completeMessage, buttons, menuChannel);
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
}

key leashMenuFilter(key avatarKey) {
    // If an inmate wants to leash you, ask your permission. 
    // If you or anybody esle wants to leash you, just present the leash menu. 
    if (avatarKey != llGetOwner() && llSameGroup(avatarKey)) {
        sayDebug("leashMenuFilter ask");
        leashMenuAsk(avatarKey);
    } else {
        sayDebug("leashMenuFilter do");
        leashMenu(avatarKey);
    }
    return avatarKey;
}

key leashMenuAsk(key avatarKey) {
    sayDebug("leashMenuAsk");
    string message = llGetDisplayName(avatarKey) + " wants to leash you.";
    list buttons = ["Leash Okay"];
    setUpMenu(llGetOwner(), message, buttons);
    return avatarKey;
}

leashMenu(key avatarKey)
// We passed all the tests. Present the leash menu. 
{
    sayDebug("leashMenu");
    string message = "Set "+prisonerNumber+"'s Leash.";
    list buttons = ["Grab leash", "Leash To", "Length", "Unleash"];
    setUpMenu(avatarKey, message, buttons);    
}

scanLeashPosts(key avatarKey) {
}

doLeash(key avatarKey, string message) {
    if (message == "Grab leash") {
        llMessageLinked(LINK_THIS, 2000, message, avatarKey);
    } else if (message == "Leash To") {
        scanLeashPosts(avatarKey);
    } else if (message == "Length") {
    }
}


default
{
    state_entry()
    {
        llSay(0, "Hello, Avatar!");
    }

    touch_start(integer total_number)
    {
        llSay(0, "Touched.");
    }
    
    listen( integer channel, string name, key avatarKey, string message ){
        llListenRemove(menuListen);
        menuListen = 0;
        llSetTimerEvent(0);
        sayDebug("listen:"+message);
    
        if (message == "Leash Okay"){
            sayDebug("listen: Leash");
            leashMenu(leashAvatar);
        }
        
        // Leash "Grab leash", "Leash To", "Length", "Unleash"
        else if (llSubStringIndex("leash", llToLower(message)) > -1){
            sayDebug("listen: Main:"+message);
            doLeash(avatarKey, message);
        }
        
    }


}
