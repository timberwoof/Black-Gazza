integer CHANNEL_EXTERNALS = -32876876;
integer LM_EXT_SHOCK = 60000;
integer LM_EXT_UNLOCK = 60001;
integer LM_EXT_LOCK = 60002;
integer LM_EXT_DRAG = 60003;
integer LM_EXT_TELEPORT = 60004;


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

integer listener;


integer overloaded = 0;

default
{
    state_entry()
    {
        listener = llListen(CHANNEL_EXTERNALS, "", "", "");
    }
    
    on_rez(integer param)
    {
        llResetScript();    
    }
    
    attach(key id)
    {
        if(id != NULL_KEY){
            llResetScript();
        }    
    }
    
    timer()
    {
        llSetTimerEvent(0.0); 
        overloaded = 0;   
    }
    
    listen(integer channel, string name, key id, string msg)
    {
        //If overloaded, ignore this command
        if(overloaded)
            return; 
        
        msg = Decrypt(msg, id);
        if(msg == "")
            return;
            
        

        list parse = llParseStringKeepNulls(msg, ["|"], []);
        string com = llList2String(parse, 0);
        key target = (key)llList2String(parse, 1);
        
        if(target != llGetOwner())
            return;
            
            
        //llOwnerSay("PASS");
        //Overload Prevention
        //This Makes sure consecutive commands are not sent to the avatar
        //Too quickly - SPAM.
        overloaded = 1;
        llSetTimerEvent(5.0);


        //Performs a shock with the designated intensity.
        if(com == "shock"){
            //llOwnerSay("SHOCK");
            integer s_force = (integer)llList2String(parse, 2);
            llMessageLinked(LINK_THIS, LM_EXT_SHOCK, (string)s_force, id);
        }else if(com == "unlock"){
            llMessageLinked(LINK_THIS, LM_EXT_UNLOCK, "", id);
        }else if(com == "lock"){
            llMessageLinked(LINK_THIS, LM_EXT_LOCK, "", id);
        }else if(com == "drag"){
            vector drag_loc = (vector)llList2String(parse, 2);
            llMessageLinked(LINK_THIS, LM_EXT_DRAG, (string)drag_loc, id);
        }else if(com == "teleport"){
            vector tp_loc = (vector)llList2String(parse, 2);
            llMessageLinked(LINK_THIS, LM_EXT_TELEPORT, (string)tp_loc, id);
        }
        
        else{return;}
        
        //If this line is executed, it means a command WAS run.  Send an OK signal
        //signalling the command was a success.
        llSay( CHANNEL_EXTERNALS, Encrypt("ok|" + msg) ); 
    }
    

    
}
