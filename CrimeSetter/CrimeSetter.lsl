settingsMenu
    integer setCrime = 0;
    integer setClass = 0;




classMenu(key avatarKey)
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



crimeDialog(key avatarKey) {
    string completeMessage = "Set " + prisonerNumber + "'s Crime";
    menuChannel = -(llFloor(llFrand(10000)+1000));
    llTextBox(avatarKey, completeMessage, menuChannel);
    menuListen = llListen(menuChannel, "", avatarKey, "");
    llSetTimerEvent(30);
}

askToApproveCrime(key avatarKey, string message) {
    sayDebug("askToApproveCrime("+message+")");
    approveCrime = message;
    approveAvatar = avatarKey;
    message = llKey2Name(avatarKey) + " wants to set your crime to \"" + message + "\"";
    setUpMenu(llGetOwner(), message, ["Approve", "Disapprove"]);
}

approveTheCrime() {
    // approveCrime
    if (approveAvatar != llGetOwner()) {
        llInstantMessage(approveAvatar, "Your request to set a new crime has been approved.");
    }
    llOwnerSay("Submitting request to database. New crime will read \""+approveCrime+"\"");
    string URL = "http://sl.blackgazza.com/add_inmate.cgi?key=";
    llHTTPRequest(URL+(string)llGetOwner()+"&name="+llKey2Name(llGetOwner())+"&crime="+approveCrime+"&sentence=0",[],"");
    llSleep(10);
    llOwnerSay("Requesting update from database. In a moment, verify the update with Collar > Info.");
    llMessageLinked(LINK_THIS, 2002, "", "");
}

disapproveTheCrime() {
    llInstantMessage(approveAvatar, "Your request to set a new crime has been disapproved.");
}

        //Class
        else if (llSubStringIndex("White Pink Red Orange Green Blue Black", messageButtonsTrimmed) > -1){
            sayDebug("listen: Class:"+messageButtonsTrimmed);
            prisonerClass = messageButtonsTrimmed;
            llMessageLinked(LINK_THIS, 1200, prisonerClass, avatarKey);
        }
        


        else if (message == "Crime"){
            crimeDialog(avatarKey);
        }
        else if (message == "Class"){
            classMenu(avatarKey);
        }

        // Crime
        else if (message == "Approve") {
            approveTheCrime();
        }
        else if (message == "Disapprove") {
            disapproveTheCrime();
        }
        else {
            sayDebug("listen: Crime:"+message);
            askToApproveCrime(avatarKey, message);
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
}
