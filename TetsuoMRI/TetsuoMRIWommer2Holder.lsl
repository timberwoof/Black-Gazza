vector phome = < 2.0, 0.0, 0.0>;
vector ehome = <0,  0  , 0>;

vector pready= < 2.0, 0.0, 0.0>;
vector eready =<0,  0  , 0>;

vector framePos;
rotation frameRot;

vector hinge = <5, 0, 0>;

setPosRot(vector desiredPosition, vector desiredEuler)
{
    rotation desiredRotation = llEuler2Rot(desiredEuler*DEG_TO_RAD);
    vector desiredWorldPos = framePos + desiredPosition*frameRot;
    rotation desiredWorldRot = frameRot / desiredRotation;
    llSetRegionPos(desiredWorldPos);
    llSetRot(desiredWorldRot);
}

followWommer(vector bedpos, rotation bedrot)
{
    llSetRegionPos(bedpos);
    vector relativeHinge = hinge * frameRot; // hinge position relative to frame
    vector worldHinge = framePos + relativeHinge; // hinge in world coordinates
    // Point the prim's positive y axis (<0.0, 1.0, 0.0>) towards a position on the sim
    llRotLookAt( llRotBetween( <1.0,0.0,0.0>, llVecNorm(worldHinge - bedpos)),1.0, 0.4 );
}


// ===================================================================================
default
{
    state_entry() 
    {
        llListen(1988,"","",""); // control
        llListen(19882,"","",""); // wommer2
        llWhisper(1988,"where?");
    }

    listen(integer channel, string name, key id, string message)
    {
        list theList = llCSV2List(message);
        string command = llList2String(theList,0);
        if (name == "TetsuoMRIFrame" & command == "here")
        {
            string stringPos = llList2String(theList,1);
            framePos = (vector)stringPos;
            string stringRot = llList2String(theList,2);
            frameRot = (rotation)stringRot;
            //setPosRot(phome,ehome);
        } 
        else if (name == "TetsuoMRIWommer2" & command == "move")
        {
            followWommer((vector)llList2String(theList,1), (rotation)llList2String(theList,2));
        }
    }
}
