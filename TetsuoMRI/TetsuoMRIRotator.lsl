// ===================================================================================
// When an avatar sits on the prim it is animated using the pose in the prim.
//

rotation eready;
rotation escan;

// Scan Constants
integer gyawduration = 15; // Z
integer ganglelimit = 60;

// Cycle globals
integer gCycle;
integer gIndex;
vector gPosition;
vector gDelta;
vector gTilt;

integer SETUP_SCAN = 1;
integer CYCLE_SCAN = 2;
integer FINISH_SCAN = 3;
integer SCAN_STEPS = 600; // can be any duration

vector framePos;
rotation frameRot;


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

setup_scan()
{
    gIndex = 0;
    gCycle = CYCLE_SCAN;
}

cycle_scan()
{
    gTilt.z = cyclicMovement(gIndex, gyawduration, ganglelimit);
        
    llSetRot(llEuler2Rot(gTilt*DEG_TO_RAD));
    gIndex++;
    if (gIndex >= SCAN_STEPS) gCycle = FINISH_SCAN;
}

finish_scan()
{
    llSetRot(eready);
    gCycle = 0;
}



// ===================================================================================
default
{
    state_entry() 
    {
        eready =llEuler2Rot(<0, 90, 0>*DEG_TO_RAD);
        llSetRot(eready);
        escan =llEuler2Rot(<0, 90, 0>*DEG_TO_RAD);
        llListen(1988,"","","");
        gTilt.x = 0.0;
        gTilt.y = 90.0;
    }


    listen(integer channel, string name, key id, string message)
    {
        list theList = llCSV2List(message);
        string command = llList2String(theList,0);
        if (name == "TetsuoMRIFrame" & command == "here")
        {
            llSetTimerEvent(0);
            llSetRot(eready);
        } 
        else if (name == "TetsuoMRIControl" & command == "Ready")
        {
            llSetTimerEvent(0);
            llSetRot(eready);
        }
        else if (name == "TetsuoMRIControl" & command == "Scan")
        {
            llSetTimerEvent(0);
            runCycle(SETUP_SCAN);
        }
        else if (name == "TetsuoMRIControl" & command == "Maint")
        {
            llSetTimerEvent(0);
            llSetRot(eready);
        }
        else if (name == "TetsuoMRIControl" & command == "Stow")
        {
            llSetTimerEvent(0);
            llSetRot(eready);
        }
        else if (name == "TetsuoMRIControl" & command == "Stop")
        {
            llSetTimerEvent(0);
        }
    }
    
    touch_start(integer num_detected)
    {
            llSetTimerEvent(0);
            runCycle(SETUP_SCAN);
    }
    
    timer()
    {
        if (gCycle == SETUP_SCAN) setup_scan(); 
        else if (gCycle == CYCLE_SCAN) cycle_scan(); 
        else if (gCycle == FINISH_SCAN) finish_scan(); 
    }
}
