// Copyright (c)2009 Thomas Shikami
// 
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
// 
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

integer COMMS_CHANNEL = 1888512232;
//integer SCRIPT_PIN = 79504640; *** update

integer gTeleportState;
integer gUsePerms;
integer gArrivalPerms;
list gKnownTeleporters;
list gKnownDestinations;
integer gDialogChannel;
integer gDialogListener;
integer gCircuit;
key gAgent;

pingTeleporters()
{
    //llWhisper (0,"pingTeleporters");
    integer i;
    integer n = llGetListLength(gKnownTeleporters);
    list existing = [];
    
    gKnownTeleporters = llListSort(gKnownTeleporters, 1, TRUE);
    gKnownDestinations = [];
    
    for(i = 0; i < n; ++i)
    {
        key teleporter = llList2Key(gKnownTeleporters, i);
        list details = llGetObjectDetails(teleporter, [OBJECT_DESC]);
        
        if(llGetListLength(details) == 1)
        {
            existing += [teleporter];
            gKnownDestinations += [llList2String(details, 0)];
        }
    }
    
    gKnownTeleporters = existing;
    
    list parts = llParseStringKeepNulls(llGetObjectDesc(), [":"], []);
    gCircuit = llList2Integer(parts, 3);
    //llWhisper (0,"pingTeleporters done");
}

addTeleporters(list keys)
{
    //llWhisper (0,"addTeleporters");
    integer i;
    integer n = llGetListLength(keys);
    
    for(i = 0; i < n; ++i)
    {
        key id = (key)llList2String(keys, i);
        
        if(llListFindList(gKnownTeleporters, [id]) == -1)
        {
            gKnownTeleporters += [id];
        }
    }
    //llWhisper (0,"addTeleporters done");
}

particles(integer show?)
{
    if(show?)
    {
        vector size = llGetScale();
        
        llParticleSystem([
            PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_COLOR_MASK,
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_SRC_ANGLE_BEGIN, PI_BY_TWO,
            PSYS_SRC_ANGLE_END, PI_BY_TWO,
            PSYS_PART_START_COLOR, <0.0, 1.0, 0.0>,
            PSYS_PART_END_COLOR, <1.0, 0.0, 0.0>,
            PSYS_PART_START_ALPHA, 0.75,
            PSYS_PART_END_ALPHA, 0.75,
            PSYS_PART_START_SCALE, <0.5, 2.0, 0.0>,
            PSYS_PART_END_SCALE, <0.5, 2.0, 0.0>,
            PSYS_PART_MAX_AGE, ( (size.x + size.y) * 0.25),
            PSYS_SRC_ACCEL, <0.0, 0.0, 1.0>,
            PSYS_SRC_BURST_RATE, 0.1,
            PSYS_SRC_BURST_PART_COUNT, 8,
            PSYS_SRC_BURST_RADIUS, 1.66,
            PSYS_SRC_BURST_SPEED_MIN, 0.1,
            PSYS_SRC_BURST_SPEED_MAX, 0.1]);     
    }
    else
    {
        llParticleSystem([]);
    }
}

integer getUsePerms()
{
    list data = llParseStringKeepNulls(llGetObjectDesc(), [":"], []);
    if(llGetListLength(data) == 4)
    {
        return llList2Integer(data, 1);
    }
    return 0;
}

showDialog(key agent)
{
    //llWhisper (0,"showDialog");
    pingTeleporters(); // *** this makes them laggy
    integer i;
    integer n = llGetListLength(gKnownDestinations);
    list buttons;
    
    for(i = 0; i < n; ++i)
    {
        key id = llList2Key(gKnownTeleporters, i);
        string dest = llList2String(gKnownDestinations, i);
        
        if(id != llGetKey())
        {
            list data = llParseStringKeepNulls(dest, [":"], []);
            if(llGetListLength(data) == 4)
            {
                integer allowed = TRUE;
                integer arrival_perms = llList2Integer(data, 2);
                integer circuit = llList2Integer(data, 3);
                
                if(circuit == gCircuit)
                {
                    if(arrival_perms & 1) {
                        if(!llSameGroup(agent)) allowed = FALSE;
                    }
                    buttons += [llList2String(data, 0)];
                }
            }
        }
    }
    
    if(llGetListLength(buttons) == 0)
    {
        llSay(0, "Sorry, no teleporter destinations known yet");
        return;
    }
    
    llListenControl(gDialogListener, TRUE);
    llDialog(agent, "Please select your destination", buttons, gDialogChannel);
}

chooseDestination(string choosen_dest)
{
    pingTeleporters();
    integer i;
    integer n = llGetListLength(gKnownDestinations);
    
    for(i = 0; i < n; ++i)
    {
        key id = llList2Key(gKnownTeleporters, i);
        string dest = llList2String(gKnownDestinations, i);
        
        if(id != llGetKey())
        {
            list data = llParseStringKeepNulls(dest, [":"], []);
            if(llGetListLength(data) == 4)
            {
                if(choosen_dest == llList2String(data, 0))
                {
                    teleportTo(id);
                    return;
                }
            }
        }
    }
}

vector gSourcePos;
vector gDestinationPos;

teleportTo(key id)
{
    if(gTeleportState != 0) return;
    llPlaySound("17836",1);
    gSourcePos = llGetPos();
    list data = llGetObjectDetails(id, [OBJECT_POS]);
    if(llGetListLength(data) != 1) return;
    
    gDestinationPos = llList2Vector(data, 0);

    llWhisper(COMMS_CHANNEL, "teleporting");
    llRegionSay(COMMS_CHANNEL, ">" + (string)id);
    gTeleportState = 1;
    llSetTimerEvent(2.0);
}

warpPos( vector destpos )
{   //R&D by Keknehv Psaltery, 05/25/2006
    //with a little pokeing by Strife, and a bit more
    //some more munging by Talarus Luan
    //Final cleanup by Keknehv Psaltery
    // Compute the number of jumps necessary
    integer jumps = (integer)(llVecDist(destpos, llGetPos()) / 10.0) + 1;
    // Try and avoid stack/heap collisions
    if (jumps > 250 )
        jumps = 250;    //  2.5km should be plenty
    list rules = [ PRIM_POSITION, destpos ];  //The start for the rules list
    integer count = 1;
    while ( ( count = count << 1 ) < jumps)
        rules = (rules=[]) + rules + rules;   //should tighten memory use.
    llSetPrimitiveParams( rules + llList2List( rules, (count - jumps) << 1, count) );
}

announceTeleporters()
{
    list out = gKnownTeleporters;
    
    while(llGetListLength(out) > 0)
    {
        llRegionSay(COMMS_CHANNEL, "X" + llDumpList2String(llList2List(out, 0, 26), "X"));
        out = llDeleteSubList(out, 0, 26);
    }
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
    on_rez(integer param)
    {
        llResetScript();
    }
    
    state_entry()
    {
        llSetObjectName("Dynatic Pod Teleporter");
        llSetSitText("Teleport");
        llSitTarget(<0, 0, -.25>, llEuler2Rot(<0,0,-90>*DEG_TO_RAD));
        gKnownTeleporters = [llGetKey()];
        llListen(COMMS_CHANNEL, "", NULL_KEY, "");
        gDialogChannel = llFloor(llFrand(1314938752)) + 18911488;
        gDialogListener = llListen(gDialogChannel, "", NULL_KEY, "");
        llListenControl(gDialogListener, FALSE);
        llRegionSay(COMMS_CHANNEL, "announce");
        llWhisper(COMMS_CHANNEL, "base");
    }
    
    changed(integer change)
    {
            key agent = llAvatarOnSitTarget();
            if (agent)            
            {    // Sat down
                llRequestPermissions( agent, PERMISSION_TRIGGER_ANIMATION );
            }
            else
            {    // Stood up ( or maybe crashed! )
                // Get agent to whom permissions were granted
                agent = llGetPermissionsKey();
                if ( llGetAgentSize( agent ) != ZERO_VECTOR )
                { // agent is still in the sim.
                    
                    if ( llGetPermissions() & PERMISSION_TRIGGER_ANIMATION )
                    {    // Only stop anis if permission was granted previously.
                        stop_anims( agent );
                    }
                }
            }
    }
    
    run_time_permissions(integer permissions)
    {
        if (permissions & PERMISSION_TRIGGER_ANIMATION)
        {
            key agent = llGetPermissionsKey();
            if ( llGetAgentSize( agent ) != ZERO_VECTOR )
            { // agent is still in the sim.
                // Sit the agent
                stop_anims( agent );
                llStartAnimation( llGetInventoryName( INVENTORY_ANIMATION, 0) );
                showDialog(agent);
            }
        }
        else
        {
            llResetScript();
        }
    }

    listen(integer channel, string name, key id, string msg)
    {
        // handle user's dialog box response
        if(channel == gDialogChannel)
        {
            chooseDestination(msg);
            return;
        }

        //llWhisper (0,"listen other");
        // when the owner uses the teleporter, it announces itself to the others
        if(llGetOwnerKey(id) != llGetOwner()) {
            return;
        }
    
        if(llGetSubString(msg, 0, 0) == "X")
        {
            addTeleporters(llParseString2List(msg, ["X"], []));
        }
        if(msg == "announce")
        {
            pingTeleporters();
            key first = llList2Key(gKnownTeleporters, 0);
            
            if(llGetKey() == first)
            {
                announceTeleporters();
            }
            if(id == first && llGetKey() == llList2Key(gKnownTeleporters, 1))
            {
                announceTeleporters();
            }
            addTeleporters([id]);
        }
    }
    
    timer()
    {
        //llWhisper (0,"timer");
        if(gTeleportState == 1)
        {
            gTeleportState = 2;
            llSetTimerEvent(1.0);
        }
        
        if(gTeleportState == 2)
        {
            warpPos(gDestinationPos);
            gTeleportState = 3;
            llSleep(1.0);
            llUnSit(gAgent);
            llSetTimerEvent(1.0);
        }
        else if(gTeleportState == 3)
        {
            warpPos(gSourcePos);
            llSetTimerEvent(0.0);
            gTeleportState = 0;
        }
    }
}
