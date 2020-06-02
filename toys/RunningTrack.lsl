list gAgentSlots; // list of avatars where
list gAvatars; // set of avatars we know are seated

integer maxAgents = 8;
key newAgent;


place_agent(integer link, key agent)
{
    llOwnerSay("place_agent");
    newAgent = agent; 
    
    vector pos;
    vector box = llGetAgentSize(agent);
    pos = <box.z * 0.67, 0.0, 0.0>;
    
    // find an empty slot
    integer slot = 0;
    integer theslot = 0;
    for(slot = 0; slot < maxAgents; slot++)
    {
        llOwnerSay("place_agent slot:"+(string)slot);
        if (NULL_KEY == llList2Key(gAgentSlots, slot))
        {
            llOwnerSay("place_agent llListReplaceList:"+(string)slot);
            gAgentSlots = llListReplaceList(gAgentSlots, [agent], slot, slot);
            theslot = slot+1;
            slot = maxAgents;
        }
    }
    
    llOwnerSay("theslot:"+(string)theslot);
    float angle = PI_BY_TWO / theslot;
    pos += <0.0, 0.0, 19.0> * llEuler2Rot(<angle, 0.0, 0.0>);
    rotation rot = llEuler2Rot(<-PI_BY_TWO, 0.0, angle + PI_BY_TWO>); //angle
    
    llRequestPermissions(agent, PERMISSION_TRIGGER_ANIMATION);
    llSetLinkPrimitiveParams(link, [PRIM_POSITION, pos]);
    llSetLinkPrimitiveParams(link, [PRIM_ROTATION, rot]);
    llOwnerSay("place_agent done");
}



remove_agent(key agent)
{
    llOwnerSay("remove_agent");
    integer slot = llListFindList(gAgentSlots, [agent]);
    if(slot < 0) return;
    gAgentSlots = llListReplaceList(gAgentSlots, [NULL_KEY], slot, slot);
    llOwnerSay("remove_agent done");
}


stop_anims( key agent )
{
    list    l = llGetAnimationList( agent );
    integer    lsize = llGetListLength( l );
    integer i;
    for ( i = 0; i < lsize; i++ )
    {
        llStopAnimation( llList2Key( l, i ) );
    }
}

default
{
    state_entry()
    {
        llOwnerSay("state_entry");
        // set up the agentSlots list
        integer slot;
        for (slot = 0; slot < maxAgents; slot++)
        {
            gAgentSlots += [NULL_KEY];
        }
        llListen(-999,"Running Track","","");
        llTargetOmega(<1.0,0.0,0.0>,0.25,0.5);
        llSetTimerEvent(1);
        llOwnerSay("state_entry done");
    }

    listen(integer channel, string name, key id, string message)
    {
        if ("run" == message)
        {
            llTargetOmega(<1,0,0>,1.5,4.5);
        }
        if ("stop" == message)
        {
            llTargetOmega(<0,0,0>,0,0);
        }
    }
    
    run_time_permissions(integer permissions)
    {
        if (permissions & PERMISSION_TRIGGER_ANIMATION)
        {
            key agent = llGetPermissionsKey();
            if ( llGetAgentSize( agent ) != ZERO_VECTOR )
            { // agent is still in the sim.
                // START RUNNING
                stop_anims( agent );
                llStartAnimation("Run");
            }
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_LINK)
        {
            llOwnerSay("changed CHANGED_LINK");        
            list new_avatars;
            integer i;
            integer n = llGetNumberOfPrims();
            
            for(i = 1; i < n; ++i)
            {
                key agent = llGetLinkKey(i + 1);
                if(llListFindList(gAvatars, [agent]) == -1) 
                {
                    place_agent(i + 1, agent);
                    
                }
                new_avatars += [agent];
            }
            
            n = llGetListLength(gAvatars);
            for(i = 0; i < n; ++i)
            {
                key agent = llList2Key(gAvatars, i);
                if(llListFindList(new_avatars, [agent]) == -1)
                {
                    remove_agent(agent);
                }
            }
            
            gAvatars = new_avatars;
        }
        llOwnerSay("changed done");
    }
    
    timer()
    {
       llMoveToTarget(<128.0, 128.0,1225.34753>, 1.0);
    }

}
