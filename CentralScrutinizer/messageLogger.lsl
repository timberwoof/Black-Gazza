integer gRegistrationChannel = 7658005;
integer LOG_CHANNEL = 0;
string logTitle = "Log";
string logText = "";

list missingList = [];

floatyLog(string newEntry)
{
    // chop off the title from the old log
    integer titleLength = llStringLength(logTitle);
    logText = llDeleteSubString(logText, 0, titleLength);
    
    // calculate room left in log
    integer logTextLength = llStringLength(logText);
    string timestamp = llGetTimestamp( );
    timestamp = llGetSubString(timestamp, 14,18);
    newEntry = "\n" + newEntry; //"\n" + timestamp + " " + newEntry;
    integer newEntryLength = llStringLength(newEntry);
    integer chop = titleLength + logTextLength + newEntryLength - 254;
    
    // chop off enough to make room for the new entry;
    if (chop > 0)
    {
        logText = llDeleteSubString(logText, 0, chop);
    }
    logText = logTitle + "\n" + logText + newEntry;
    llSetText(logText,<0,1,0>,1);
}

default
{
    state_entry()
    {
        // initialize missing list
        missingList = [];
    
        logTitle = "AI Message Log";//llGetObjectName();
        floatyLog("log starts");
        llListen(gRegistrationChannel, "", NULL_KEY, "");
    }


    listen(integer channel, string name, key id, string msg)
    {
        floatyLog(msg);
    }
}
