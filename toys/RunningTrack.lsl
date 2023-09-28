// [TWL] Running Track
// Makes avatars run clockwise around on the track.

// running track prim position and dimensions
float gRadius;
vector gMyPos;
rotation gMyRot;
vector gAgentSitPos;
rotation gAgentSitRot;

// avatar position and stuff
float timerGrain = 0.1;
float speed = 1.0; // meter/second
key gAgent;

integer debug = TRUE;
sayDebug(string message) {
    if (debug) {
        llOwnerSay(message);
    }
}

stop_anims(key agent)
{
    list    l = llGetAnimationList(agent);
    integer    lsize = llGetListLength(l);
    integer i;
    for (i = 0; i < lsize; i++)
    {
        llStopAnimation(llList2Key(l, i));
    }
}


//Sets / Updates the sit target moving the gAgent on it if necessary.
UpdateSitTarget(vector pos, rotation rot)
{//Using this while the object is moving may give unpredictable results.
    llSitTarget(pos, rot);//Set the sit target
    key user = llAvatarOnSitTarget();
    if(user)//true if there is a user seated on the sittarget, if so update their position
    {
        vector size = llGetAgentSize(user);
        if(size)//This tests to make sure the user really exists.
        {
            //We need to make the position and rotation local to the current prim
            rotation localrot = ZERO_ROTATION;
            vector localpos = ZERO_VECTOR;
            if(llGetLinkNumber() > 1)//only need the local rot if it's not the root.
            {
                localrot = llGetLocalRot();
                localpos = llGetLocalPos();
            }
            integer linkNum = llGetNumberOfPrims();
            do
            {
                if(user == llGetLinkKey(linkNum))//just checking to make sure the index is valid.
                {
                    //<0.008906, -0.049831, 0.088967> are the coefficients for a parabolic curve that best fits real gAgents. It is not a perfect fit.
                    float fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
                   llSetLinkPrimitiveParamsFast(linkNum,
                        [PRIM_POS_LOCAL, (pos + <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust)) * localrot + localpos,
                         PRIM_ROT_LOCAL, rot * localrot]);
                    jump end;//cheaper but a tad slower then return
                }
            }while(--linkNum);
        }
        else
        {//It is rare that the sit target will bork but it does happen, this can help to fix it.
            llUnSit(user);
        }
    }
    @end;
}//Written by Strife Onizuka, size adjustment and improvements provided by Talarus Luan



default
{
    state_entry()
    {
        sayDebug("state_entry");
        gMyPos = llGetPos();
        gMyRot = llGetRot();
        vector scale = llGetScale();
        gRadius = (scale.y + scale.z) / 4.0 - 1.0;
        sayDebug("state_entry gMyPos:"+(string)gMyPos);
    }

    touch_start(integer total_number)
    {
        // you have to click first so it can get your position
        sayDebug("touch_start-----------------");
        key gAgent = llDetectedKey(0);
        vector avatarPos = llDetectedPos(0);
        
        // Wehn prim rotation os <0, 270, 0> the avatarRelPos is sane. 
        vector avatarRelPos = avatarPos - gMyPos; 
        sayDebug("avatarRelPos:"+(string)avatarRelPos);
        float avatarRadius = llVecDist(avatarPos, gMyPos);
        sayDebug("avatarRadius:"+(string)avatarRadius);
        float Theta = llAsin(avatarRelPos.y / avatarRadius);
        sayDebug("Theta:"+(string)Theta);
        if  (avatarRelPos.x > 0) {
            gAgentSitPos = gRadius * <0.0, llSin(Theta), -llCos(Theta)> + <1.0,0,0>;
        } else {
            gAgentSitPos = gRadius * <0.0, llSin(Theta), llCos(Theta)> + <1.0,0,0>;
        }
        sayDebug("gAgentSitPos:"+(string)gAgentSitPos);
        gAgentSitRot = llEuler2Rot(<0,0,Theta>) / gMyRot;
        sayDebug("gAgentSitRot:"+(string)gAgentSitRot);
        llSitTarget(gAgentSitPos, gAgentSitRot);
    }

    changed(integer change) 
    {

        if (change & CHANGED_LINK)
        {
            sayDebug("changed CHANGED_LINK");
            gAgent = llAvatarOnSitTarget();
            if (gAgent)            
            {
                llRequestPermissions(gAgent, PERMISSION_TRIGGER_ANIMATION);
            }
            else
            {
                gAgent = llGetPermissionsKey();
                if (llGetAgentSize(gAgent) != ZERO_VECTOR)
                {
                    llStopSound();
                    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                    {
                        llSetTimerEvent(0);
                        stop_anims(gAgent);
                        llResetScript(); // *** temporary
                    }
                }
            }
        }
        if (change & CHANGED_SCALE)
        {
            sayDebug("changed CHANGED_SCALE");
        }
    }    

    run_time_permissions(integer permissions)
    {
        if (permissions & PERMISSION_TRIGGER_ANIMATION)
        {
            sayDebug("run_time_permissions PERMISSION_TRIGGER_ANIMATION");
            gAgent = llGetPermissionsKey();
            if (llGetAgentSize(gAgent) != ZERO_VECTOR)
            {
                stop_anims(gAgent);
                llStartAnimation("run");
                llSetTimerEvent(timerGrain);
            }
        }
    }
    
    timer()
    {
        UpdateSitTarget(gAgentSitPos, gAgentSitRot);
    }
}
