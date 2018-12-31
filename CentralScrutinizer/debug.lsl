integer debugChannel = 999;
integer gLogChannel = 7659010;
key gAvatar;

integer ERROR = 0;
integer WARN = 1;
integer INFO = 2;
integer DEBUG = 3;
integer TRACE = 4;
integer messageLevelThreshold = 2;
list logLevelNames=["ERROR","WARN","INFO","DEBUG","TRACE"];

integer IsInteger(string var){
// http://wiki.secondlife.com/wiki/Integer
    integer i;
    for(i=0;i<llStringLength(var);++i){
        if(!~llListFindList(["1","2","3","4","5","6","7","8","9","0"],[llGetSubString(var,i,i)])){
            return FALSE;
        }
    }
    return TRUE;
}

// message comes in on 900+debugLevel
twDebug(integer messageLevel, string message) 
{
    message = llList2String(logLevelNames, messageLevel) + ": " + message; // append debug level name
    if (gAvatar != "" && messageLevel <= messageLevelThreshold) {
        if (messageLevelThreshold < TRACE) {
            llInstantMessage(gAvatar, message);
        }
        else
        {
            llInstantMessage(gAvatar, "debug.twDebug:"+message);
        }
    }
    llRegionSay(gLogChannel,message);
}

default
{
    link_message(integer Sender, integer Number, string message, key Key)
    {
        // set avatar to send messages to
        if (Number == 999)
        {
            gAvatar = Key;
        }
        
        // set debug level
        if (Number == 998)
        {
            if(IsInteger(message)) {
                integer newThreshold = (integer)message;
                if (newThreshold != messageLevelThreshold) {
                    messageLevelThreshold = newThreshold;
                    twDebug(INFO,"set message level to "+(string)messageLevelThreshold);
                }
            } else {
                twDebug(WARN,"unable to set message level to "+message+": not an integer");
            }
        }
                
        // post debug message
        else if ((Number >= 900) && (Number < 910))
        {
            integer debugLevel = Number - 900;
            twDebug(debugLevel, message);
        }
    }
}
