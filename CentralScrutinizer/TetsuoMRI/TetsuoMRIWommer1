// Positions are
// load, ready, scan, maint, stow

vector pload = <-3, 0, 0>;
vector eload = <0, 0, 0>;

vector pready =<-1.5, 0, 0>;
vector eready =<0,  0, 0>;

vector pscan =<-1, 0, 0>;
vector escan =<0,  0, 0>;

vector pmaint = <-1.25, 0, 0>;
vector emaint = <25, 0, 0>;

vector pstow = <-3, 0, 0>;
vector estow = <0, 0, 0>;

vector framePos;
rotation frameRot;

// Scan Constants
integer gxduration = 80; // tenths ofseconds
integer gyduration = 90; // 
integer gzduration = 60; // 
integer grollduration = 10; // X
integer gpitchduration = 20; // Y
integer gyawduration = 30; // Z
    
float gdistancelimit = 0.5; // meters
float ganglelimit = 10.0; // degrees

// Cycle globals
integer gCycle;
integer gIndex;
vector gPosition;
vector gDelta;
vector gTilt;

// Cycle global constants
integer SETUP_SCAN = 11;
integer CYCLE_SCAN = 12;
integer FINISH_SCAN = 13;
integer SCAN_STEPS = 600; // can be any duration


string sound_wom = "1e89e974-d9be-f3cd-618e-c4d96f91d7f6";

setPosRot(vector desiredPosition, vector desiredEuler)
{
    rotation desiredRotation = llEuler2Rot(desiredEuler*DEG_TO_RAD);
    vector desiredWorldPos = framePos + desiredPosition*frameRot;
    rotation desiredWorldRot = frameRot / desiredRotation;
    llWhisper(19881,"move,"+(string)desiredWorldPos+","+(string)desiredWorldRot);
    llSetRegionPos(desiredWorldPos);
    llSetRot(desiredWorldRot);
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



test()
{
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
    //gTilt.y = cyclicMovement(cycle, gpitchduration, ganglelimit);
    //gTilt.Z = cyclicMovement(cycle, gyawduration, ganglelimit);
        
    setPosRot(gDelta+pscan,gTilt);
    gIndex++;
    if (gIndex >= SCAN_STEPS) gCycle = FINISH_SCAN;
}

finish_scan()
{
    setPosRot(pready,eready);
    llStopSound();
    gCycle = 0;
}


scan()
{
    integer cycleduration = 600; // tenths of seconds
    integer cycle = 0;
    
    
    llLoopSound(sound_wom,1.0);

        for (cycle = 0; cycle < cycleduration; cycle ++)
    {
        llSleep(0.1);
    }
}



// ===================================================================================
default
{
    state_entry() 
    {
        llStopSound();
        llSay(1988, "where?");
        llListen(1988,"","","");
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
            setPosRot(pstow,estow);
        } 
        else if (name == "TetsuoMRIControl" & command == "Test")
        {
            llSetTimerEvent(0);
            test();
        }
        else if (name == "TetsuoMRIControl" & command == "Load")
        {
            llSetTimerEvent(0);
            //setPosRot(pload,eload);
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
        else if (name == "TetsuoMRIControl" & command == "Stop")
        {
            llSetTimerEvent(0);
        }
    }

    timer()
    {
        if (gCycle == SETUP_SCAN) setup_scan(); 
        else if (gCycle == CYCLE_SCAN) cycle_scan(); 
        else if (gCycle == FINISH_SCAN) finish_scan(); 
    }
}
