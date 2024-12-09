// Responder.lsl
// Script for Black Gazza Collar 4
// Timberwoof Lupindo, February 2020
// version: 2020-02-22

integer responderChannel;
integer responderListen;
string lockLevel;

integer OPTION_DEBUG = 0;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Responder:"+message);
    }
}

integer uuidToInteger(key uuid)
// primitive hash of uuid parts
{
    // UUID looks like 284ba63f-378b-4be6-84d9-10db6ae48b8d
    string hexdigits = "abcdef";
    list uuidparts = llParseString2List(uuid,["-"],[]);
    // last one is too big; split it into 2 6-digit numbers
    string last = llList2String(uuidparts,4);
    string last1 = llGetSubString(last,0,5);
    string last2 = llGetSubString(last,6,12);
    list lasts = [last1, last2];
    uuidparts = llListReplaceList(uuidparts, lasts, 4, 4);
    
    integer sum = 0;
    integer i = 0;
    // take each uuid part
    for (i=0; i < llGetListLength(uuidparts); i++) {
        string uuidPart = llList2String(uuidparts,i);
        integer j;
        // look at each digit
        for (j=0; j < llStringLength(uuidPart); j++) {
            string c = llGetSubString(uuidPart, j, j);
            string k = (string)llSubStringIndex(hexdigits, c);
            // if it's in abcdef
            if ((integer)k > -1) {
                // substitute in the digit 123456
                uuidPart = llDeleteSubString(uuidPart, j, j);
                uuidPart = llInsertString(uuidPart, j, k);
            }
        }
        sum = sum - (integer)uuidPart;
    }
    return sum;
}

default
{
    state_entry()
    {
        responderChannel = uuidToInteger(llGetOwner());
        responderListen = llListen(responderChannel,"", "", "");
    }
    
    link_message( integer sender_num, integer num, string message, key id )
    {
        if (num == 1400) {
            lockLevel = message;
        }
    } 

    listen(integer channel, string name, key id, string message)
    {
        sayDebug("Responder listen("+name+","+message+")");
        list lockLevels = ["Safeword", "Off", "Light", "Medium", "Heavy", "Hardcore"];
        integer locki = llListFindList(lockLevels, [lockLevel]);
        if (message == "Request Authorization") {
            if (0 < locki && locki <= 2) {
                llSay(responderChannel,"Yes");
            } else if (locki == 3) {
                llSay(responderChannel,"No");
            } else if (locki >= 4) {
                llSay(responderChannel,"Zap");
            }
        }
    }
}
