integer CONTROLCHANNEL = 1988;



default
{
    state_entry()
    {
        llSetTextureAnim(0, ALL_SIDES,0,0,1, 1, 0);
        llListen(CONTROLCHANNEL,"","","");
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (message == "On")
        {
            llSetTextureAnim(ANIM_ON | SMOOTH | LOOP, 5,0,0,0, 1, .5);
        }
        else if (message == "Off")
        {
            llSetTextureAnim(0, ALL_SIDES,0,0,1, 1, 0);
        }
    }
}
