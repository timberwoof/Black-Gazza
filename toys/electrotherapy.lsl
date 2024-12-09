key Acupuncture1 = "e4b2b32c-c987-5f0e-cbda-c45d267f1c65";
key Acupuncture2 = "e4455f4e-15f5-70b4-1c75-47574640d78b";
key Acupuncture3 = "d7f64b91-2aeb-96ab-e571-c915340ae096";
key Naparapathy = "daea4d27-c0e2-c17e-3c3f-f37cc08a967b";
key Cupping = "53b420c1-ddc7-3b68-717b-4679b3c8da52";
list ModeSounds;
key theSound; 

integer FaceControlsFront = 1;
integer FaceControlsTop = 0;

list TimerVectors = [ <0.84249, 0.78694, 0.00000>, <0.75774, 0.82169, 0.00000>, 
    <0.71866, 0.88701, 0.00000>, <0.74183, 0.94960, 0.00000>, <0.81964, 0.97634, 0.00000>, 
    <0.90676, 0.94767, 0.00000>, <0.94723, 0.88459, 0.00000>, <0.91935, 0.82192, 0.00000> ];
    
list PowerLevelVectors = [ <0.11775, 0.82215, 0.00000> , <0.08701, 0.86253, 0.00000>, 
    <0.08277, 0.90234, 0.00000>, <0.10191, 0.94108, 0.00000>, <0.13837, 0.97032, 0.00000>,
    <0.19510, 0.97744, 0.00000>, <0.24647, 0.96736, 0.00000>, <0.28977, 0.94165, 0.00000>,
    <0.30958, 0.90179, 0.00000>, <0.31184, 0.85995, 0.00000>, <0.28926, 0.82166, 0.00000> ];
    
list ModeVectors = [ <0.28118, 0.55178, 0.00000>, <0.38970, 0.55113, 0.00000>, 
    <0.50035, 0.55175, 0.00000>, <0.61733, 0.55306, 0.00000>, <0.73015, 0.55056, 0.00000> ];
    
float thePowerlevel = 0.0;
    
vector onArea = <0.48076, 0.80675, 0.00000>;
vector offArea = <0.58163, 0.80570, 0.00000>;
    
    
// findXYinList
// locationVectors - list of llDetectedTouchUV target vectors 
// touch - the vector returned by llDetectedTouchUV
// delta - how far away the click can be
//
// returns -1 for no find, 0 through whatever for find
integer findXYinList(list locationVectors, vector theTouch, float delta)
{
    integer listLength = llGetListLength(locationVectors);
    integer i;
    integer result = -1;
    for (i = 0; i < listLength; i= i + 1)
    {
        vector candidate = llList2Vector(locationVectors, i);
        float vecDist = llVecDist(candidate, theTouch);
        //llWhisper(0,"vecDist:"+(string)vecDist);
        if (vecDist < delta)
        {
            result = i;
            return result;
        }
    }
    return result;
}

// findTouchNearVector
// target - llDetectedTouchUV target vector
// theTouch  - the vector returned by llDetectedTouchUV
// delta - how far away the click can be
// returns false for no find, true for find
integer findTouchNearVector(vector candidate, vector theTouch, float delta)
{
    float vecDist = llVecDist(candidate, theTouch);
    //llWhisper(0,"vecDist:"+(string)vecDist);
    return (vecDist < delta);
}
    
default
{
    state_entry()
    {
        llStopSound();
        ModeSounds = [ Acupuncture1, Acupuncture2, Acupuncture3, Naparapathy, Cupping ];
        theSound = Acupuncture1;
    }

    touch_start(integer total_number)
    {
        integer iTouch =  llDetectedTouchFace(0);
        vector vTouch = llDetectedTouchUV(0);
        //llWhisper(0, "iTouch:"+(string)iTouch+", vTouch:"+(string)vTouch);
        
        if (iTouch == FaceControlsFront)
        {
            integer whichMode = findXYinList(ModeVectors, vTouch, 0.04);
            if (whichMode > -1)
            {
                theSound = llList2Key(ModeSounds, whichMode);
                //llWhisper(0,"looping at power "+(string)thePowerlevel);
                llLoopSound(theSound,thePowerlevel);
            }
        }
        
        if (iTouch == FaceControlsTop)
        {
            if (findTouchNearVector(onArea, vTouch, .05))
            {
                llLoopSound(theSound,thePowerlevel);
                return;
            }
            if (findTouchNearVector(offArea, vTouch, .05))
            {
                llStopSound();
                llSetTimerEvent(0);
                return;
            }
            integer whichTimer = findXYinList(TimerVectors, vTouch, .04);
            if (whichTimer > -1)
            {
                //llWhisper(0,"Timer:"+(string)whichTimer);
                if (whichTimer > 0)
                {
                    llSetTimerEvent(10*whichTimer);
                    //llWhisper(0,"looping at power "+(string)thePowerlevel);
                    llLoopSound(theSound,thePowerlevel);
                }
                else
                {
                    llStopSound();
                }
                return;
            }
            integer whichPower = findXYinList(PowerLevelVectors, vTouch, .02);
            if (whichPower > -1)
            {
                //llWhisper(0,"Power:"+(string)whichPower);
                thePowerlevel = whichPower / 10.0;
                //llWhisper(0,"looping at power "+(string)thePowerlevel);
                llStopSound();
                llLoopSound(theSound,thePowerlevel);
                return;
            }
        }
    }
    
    timer()
    {
        llStopSound();
    }
}

