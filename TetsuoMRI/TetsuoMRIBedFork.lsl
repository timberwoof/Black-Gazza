vector home = < 0.0, 0.0, 0.0>;
vector ready= < 0.0, 0.0,-1.0>;
vector ehome = <-14, 0 ,0>; // <14, 0  ,0>
vector eready= <0, 0 ,0>;

vector gFramePos;
rotation gFrameRot;
vector gWorldHinge;

vector gRelativeHinge = <-5, 0, 0.0>;//<-5, 0, -0.36>; // meters
// Relative position of hinge to frame origin

setPosRot(vector desiredPosition, vector desiredEuler)
{
    rotation desiredRotation = llEuler2Rot(desiredEuler*DEG_TO_RAD);
    vector desiredWorldPos = gFramePos + desiredPosition*gFrameRot;
    rotation desiredWorldRot = gFrameRot / desiredRotation;
    llSetRegionPos(desiredWorldPos);
    llSetRot(desiredWorldRot);
}

followBed(vector bedpos, rotation bedrot)
{
    // An attempt to keep the bed arm's center in one pivot point. 
    // but some lack of precision tilts it in a weird way. 
    //llWhisper(0,"followBed("+(string)bedpos+","+(string)bedrot+")");
    //llSetRegionPos(bedpos);
    // Point the prim's positive y axis toward a position on the sim
    //llWhisper(0,"followBed gWorldHinge:"+(string)gWorldHinge+",  bedpos:"+(string)bedpos);    
    //vector vecnorm = llVecNorm(gWorldHinge - bedpos);
    //rotation rotbetween = llRotBetween( <-1.0, 0.0, 0.0>, vecnorm); // must have same magnitude
    //llWhisper(0,"followBed vecnorm:"+(string)vecnorm+",  rotbetween:"+(string)rotbetween);    
    //llRotLookAt( rotbetween, 1.0, 0.4 );
    
    // Simple algorithm with no "corrections"
    llSetRegionPos(bedpos);
    vector relativeHinge = gWorldHinge * gFrameRot; // hinge position relative to frame
    vector worldHinge = gFramePos + relativeHinge; // hinge in world coordinates
    llRotLookAt( llRotBetween( <-1.0,0.0,0.0>, llVecNorm(gWorldHinge - bedpos)), 1.0, 0.4 );
}


// ===================================================================================
default
{
    state_entry() 
    {
        llListen(1988,"","",""); // control
        llListen(19880,"","",""); // bed
        llWhisper(1988,"where?");
   }

    listen(integer channel, string name, key id, string message)
    {
        //llWhisper(0,message);
        list theList = llCSV2List(message);
        string command = llList2String(theList,0);
        if (name == "TetsuoMRIFrame" & command == "here")
        {
            string stringPos = llList2String(theList,1);
            string stringRot = llList2String(theList,2);

            gFramePos = (vector)stringPos;
            gFrameRot = (rotation)stringRot;
            gWorldHinge = gFramePos + gRelativeHinge * gFrameRot; // hinge in world coordinates
        } 
        else if (name == "TetsuoMRIBed" & command == "move")
        {
            followBed((vector)llList2String(theList,1), (rotation)llList2String(theList,2));
        }
    }
}
