// ===================================================================================
// When an avatar sits on the prim it is animated using the pose in the prim.
//

vector pload1 = <8.75, 0, -0.3>; // at the far end
vector eload1 = <0, 0, 0>;

vector pload2 = <2.25, 0, -0.3>;  // ready to get pcked up
vector eload2 = <0, 0, 0>;

vector pready =<0, 0, -.3>;  // ready to start MRI
vector eready =<0, 0,  0>;

vector pscan =<0, 0, -.3>;
vector escan =<0, 0, 0>;

vector pmaint = <-3.7, 0, -.5>;//<-3, 0, -.5>;
vector emaint = <0, 0, 0>;

vector pstow = <0, 0, -.3>; // <-3.7, 0, -.5>
vector estow = <0, 0, 0>;

// Scan Constants
integer gxduration = 40; // tenths ofseconds
integer gyduration = 60; // 
integer gzduration = 100; // 
integer grollduration = 20; // X
integer gpitchduration = 40; // Y
integer gyawduration = 80; // Z
float gdistancelimit = 0.25; // meters
float ganglelimit = 10.0; // degrees

// Cycle globals
integer gCycle;
integer gIndex;
vector gPosition;
vector gDelta;
vector gTilt;

// Cycle global constants
integer SETUP_UNLOAD1 = 1;
integer CYCLE_UNLOAD1 = 2;
integer SETUP_UNLOAD2 = 3;
integer CYCLE_UNLOAD2 = 4;
integer FINISH_UNLOAD = 5;

integer SETUP_LOAD1 = 6;
integer CYCLE_LOAD1 = 7;
integer SETUP_LOAD2 = 8;
integer CYCLE_LOAD2 = 9;
integer FINISH_LOAD = 10;

integer SETUP_SCAN = 11;
integer CYCLE_SCAN = 12;
integer FINISH_SCAN = 13;

integer UNLOAD1_STEPS = 10;
integer UNLOAD2_STEPS = 20;
integer LOAD1_STEPS = 20;
integer LOAD2_STEPS = 10;
integer SCAN_STEPS = 600; // can be any duration

vector framePos;
rotation frameRot;

setPosRot(vector desiredPosition, vector desiredEuler)
{
    rotation desiredRotation = llEuler2Rot(desiredEuler*DEG_TO_RAD);
    vector desiredWorldPos = framePos + (desiredPosition)*frameRot;
    rotation desiredWorldRot = frameRot / desiredRotation;
    llSay(19880,"move,"+(string)desiredWorldPos+","+(string)desiredWorldRot);
    llSetRegionPos(desiredWorldPos);
    llSetRot(desiredWorldRot);
}


setPosRot2(vector desiredPosition1, vector desiredEuler1, vector desiredPosition2, vector desiredEuler2)
{
    rotation desiredRotation1 = llEuler2Rot(desiredEuler1*DEG_TO_RAD);
    vector desiredWorldPos1 = framePos + (desiredPosition1)*frameRot;
    rotation desiredWorldRot1 = frameRot / desiredRotation1;
    llSetRegionPos(desiredWorldPos1);
    llSetRot(desiredWorldRot1);
    
    rotation desiredRotation2 = llEuler2Rot(desiredEuler2*DEG_TO_RAD);
    vector desiredWorldPos2 = framePos + (desiredPosition2)*frameRot;
    rotation desiredWorldRot2 = frameRot / desiredRotation2;
    llSay(19880,"move,"+(string)desiredWorldPos2+","+(string)desiredWorldRot2);
}


test()
{
}

float cyclicMovement(integer cycle, integer duration, float limit)
{
    integer mod = cycle % duration;
    float tx = (float)mod / (float)duration * TWO_PI;
    return llSin(tx) * limit;
}

runCycle(integer cycle)
// set cycle, whcih indicates what loop we're doing
// set the index to 0
// set the steps limit
// start the timer
{
    gCycle = cycle;
    gIndex = 0;
    llSetTimerEvent(.1);
}

finishCycle(integer cycle)
{
    gCycle = 0;
    llSetTimerEvent(0);
}



setup_unload1()
// move from Ready position to Load Position: pready, pload2, pload1
{
    // move from Ready position to pickup point.
    // bed move goes along
    gPosition = pready;
    setPosRot(gPosition, eready);
    gDelta = (pload2 - pready) / UNLOAD1_STEPS;
    gCycle = CYCLE_UNLOAD1;
}

cycle_unload1()
{
    gPosition = gPosition + gDelta;
    setPosRot(gPosition, eready);
    gIndex++;
    if (gIndex >= UNLOAD1_STEPS) gCycle = SETUP_UNLOAD2;
}

setup_unload2()
{    
    // move from pickup point along the track to the load point.
    // bed mover stays where it is, at pload2
    gPosition = pload2;
    setPosRot(gPosition, eload2);
    gIndex = 0;
    gDelta = (pload1 - pload2) / UNLOAD2_STEPS;
    gCycle = CYCLE_UNLOAD2;
}

cycle_unload2()
{
    gPosition = gPosition + gDelta;
    setPosRot2(gPosition, eload1, pload2, eload2);
    gIndex++;
    if (gIndex >= UNLOAD2_STEPS) gCycle = FINISH_UNLOAD;
}

finish_unload()
{
    setPosRot2(pload1, eload1, pload2, eload2);
    gCycle = 0;
}



setup_load1()
// move from Ready position to Load Position: pready, pload2, pload1
{
    // move from Ready position to pickup point.
    // bed move goes along
    gPosition = pload1;
    setPosRot2(gPosition, eload2, pload2, eload2);
    gDelta = (pload2 - pload1) / LOAD1_STEPS;
    gCycle = CYCLE_LOAD1;
}

cycle_load1()
{
    gPosition = gPosition + gDelta;
    setPosRot2(gPosition, eload1, pload2, eload2);
    gIndex++;
    if (gIndex >= LOAD1_STEPS) gCycle = SETUP_LOAD2;
}

setup_load2()
{    
    // move from pickup point along the track to the load point.
    // bed mover stays where it is, at pload2
    gPosition = pload2;
    setPosRot(gPosition, eready);
    gIndex = 0;
    gDelta = (pready - pload2) / LOAD2_STEPS;
    gCycle = CYCLE_LOAD2;
}

cycle_load2()
{
    gPosition = gPosition + gDelta;
    setPosRot(gPosition, eready);
    gIndex++;
    if (gIndex >= LOAD2_STEPS) gCycle = FINISH_LOAD;
}

finish_load()
{
    setPosRot(pready,eready);
    gCycle = 0;
}



setup_scan()
{
    gIndex = 0;
    gCycle = CYCLE_SCAN;
}

cycle_scan()
{
    gDelta.x = cyclicMovement(gIndex, gxduration, gdistancelimit);
    gDelta.y = cyclicMovement(gIndex, gyduration, gdistancelimit);
    gDelta.z = cyclicMovement(gIndex, gzduration, gdistancelimit);
        
    gTilt.x = cyclicMovement(gIndex, grollduration, ganglelimit);
    gTilt.y = cyclicMovement(gIndex, gpitchduration, ganglelimit);
    gTilt.z = cyclicMovement(gIndex, gyawduration, ganglelimit);
        
    setPosRot(gDelta+pscan,gTilt);
    gIndex++;
    if (gIndex >= SCAN_STEPS) gCycle = FINISH_SCAN;
}

finish_scan()
{
    setPosRot(pready,eready);
    gCycle = 0;
    llSay(1988,"Ready");
}




// ====================================================================================================
// Stop all animations
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

// ===================================================================================
default
{
    state_entry() 
    {
        llListen(1988,"","","");
        llSay(1988, "where?");
        llSetSitText( "Be Scanned" );
        llSitTarget( < -0.2, 0.0, -0.1 > , llEuler2Rot(<0, -90, 0>*DEG_TO_RAD) );
        llSetCameraEyeOffset(<-1.62, 0.0, 0.62>); // where the camera is
        llSetCameraAtOffset(<0.0, 0.0, 0.5>); // where it's looking
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
                llSetTimerEvent(1);
            }
        }
        else
        {
            //llResetScript();
        }
    }

    changed(integer change) 
    {

        if (change & CHANGED_LINK)
        {    // Someone sat or stood up ...
            // get who sat
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
                    //llResetScript();
                }
            }
        }
    }    

    listen(integer channel, string name, key id, string message)
    {
        list theList = llCSV2List(message);
        string command = llList2String(theList,0);
        if (name == "TetsuoMRIFrame" & command == "here")
        {
            llSetTimerEvent(0);
            string stringPos = llList2String(theList,1);
            framePos = (vector)stringPos;
            string stringRot = llList2String(theList,2);
            frameRot = (rotation)stringRot;
            setPosRot(pmaint,emaint);
        } 
        else if (name == "TetsuoMRIControl" & command == "Test")
        {
            llSetTimerEvent(0);
        }
        else if (name == "TetsuoMRIControl" & command == "Load")
        {
            llSetTimerEvent(0);
            runCycle(SETUP_LOAD1);
        }
        else if (name == "TetsuoMRIControl" & command == "Unload")
        {
            llSetTimerEvent(0);
            runCycle(SETUP_UNLOAD1);
        }
        else if (name == "TetsuoMRIControl" & command == "Ready")
        {
            llSetTimerEvent(0);
            setPosRot(pready,eready);
        }
        else if (name == "TetsuoMRIControl" & command == "Scan")
        {
            llSetTimerEvent(0);
            runCycle(SETUP_SCAN);
        }
        else if (name == "TetsuoMRIControl" & command == "Maint")
        {
            llSetTimerEvent(0);
            setPosRot(pmaint,emaint);
        }
        else if (name == "TetsuoMRIControl" & command == "Stow")
        {
            llSetTimerEvent(0);
            setPosRot(pstow,estow);
        }
        else if (name == "TetsuoMRIControl" & command == "Off")
        {
            llSetTimerEvent(0);
            setPosRot(pmaint,emaint);
        }
        else if (name == "TetsuoMRIControl" & command == "Stop")
        {
            llSetTimerEvent(0);
        }
    }
    
    timer()
    {
        if (gCycle == SETUP_UNLOAD1) setup_unload1(); 
        else if (gCycle == CYCLE_UNLOAD1) cycle_unload1(); 
        else if (gCycle == SETUP_UNLOAD2) setup_unload2(); 
        else if (gCycle == CYCLE_UNLOAD2) cycle_unload2(); 
        else if (gCycle == FINISH_UNLOAD) finish_unload(); 
        
        else if (gCycle == SETUP_LOAD1) setup_load1(); 
        else if (gCycle == CYCLE_LOAD1) cycle_load1(); 
        else if (gCycle == SETUP_LOAD2) setup_load2(); 
        else if (gCycle == CYCLE_LOAD2) cycle_load2(); 
        else if (gCycle == FINISH_LOAD) finish_load(); 

        else if (gCycle == SETUP_SCAN) setup_scan(); 
        else if (gCycle == CYCLE_SCAN) cycle_scan(); 
        else if (gCycle == FINISH_SCAN) finish_scan(); 
    }
}
