default
{
    state_entry()
    {
        string outMessage = "here,"+(string)llGetPos()+","+(string)llGetRot();
        llWhisper(1988, outMessage);
        llListen(1988,"","","");
        
    }

    touch_start(integer total_number)
    {
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (message == "where?")
        {
            string outMessage = "here,"+(string)llGetPos()+","+(string)llGetRot();
            llWhisper(1988, outMessage);
        }
    }
}
