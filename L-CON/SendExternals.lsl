integer CHANNEL_EXTERNALS = -32876876;
integer LM_SEND_EXTERNAL = -888377;
integer LM_RECV_EXTERNAL = -888378;


integer listener;
string static_hash = "38h48740flk";

string Encrypt(string message)
{ return llMD5String((string)llGetKey() + message + (string)CHANNEL_EXTERNALS + static_hash, FALSE) + message; }
string Decrypt(string message, key sender){
    string md5 = llGetSubString(message, 0, 31);
    string theStr = llGetSubString(message, 32, -1);
    string c_md5 = llMD5String((string)sender + theStr + (string)CHANNEL_EXTERNALS + static_hash, FALSE);
   // llOwnerSay(theStr);
    if(md5 == c_md5){
        return theStr;
    }else{
        return "";
    }    
}

string expected;
key target;

default
{
    timer()
    {
        llSetTimerEvent(0.0);
        expected = "";
        llMessageLinked(LINK_THIS, LM_RECV_EXTERNAL, (string)FALSE, target);
        target = NULL_KEY;
    }
    
    
    link_message(integer link, integer num, string msg, key id)
    {
        if(expected != "")
            return;
        
        if(num == LM_SEND_EXTERNAL){
            list parse = llParseStringKeepNulls(msg,[","],[]);
            
            //Compile the new string
            string str = llList2String(parse, 0) + "|";
            str += (string)id + "|";
            str += llDumpList2String(llList2List(parse, 1, -1),"|");
            
            //Compile Expected Strings
            expected = "ok|" + str;
            llSetTimerEvent(10.0);
            
            //llOwnerSay(str);
            listener = llListen(CHANNEL_EXTERNALS, "", "", expected);
            //llSay(0, Encrypt(str));
            llRegionSay(CHANNEL_EXTERNALS, Encrypt(str));
        }
    }
    
    listen(integer channel, string name, key id, string msg)
    {
        expected = "";
        llSetTimerEvent(0.0);
        llMessageLinked(LINK_THIS, LM_RECV_EXTERNAL, (string)TRUE, target);  
        target = NULL_KEY;  
    }
}
