key avatarKey; 
string avatarKeyString;
string avatarName;

key primKey;
string primKeyString;

integer statuschannel = 16565;
integer statuslisten;
integer commandchannel = -1654;
integer commandlisten;

integer locked = 0;

string theAnimation;

integer agony = 0;
integer inagony = 0;
integer agonyduraton = 10;

integer faint = 0;
integer fainted = 0;
integer faintduration = 10;

key httprequest;

registerWithDB(integer $locked) {
    string timestamp = llGetTimestamp( ); // format 
    string timeStampDate = llGetSubString(timestamp,0,9);
    string timeStampTime = llGetSubString(timestamp,11,18);
    string timeStampAll = timeStampDate + " " + timeStampTime;
    string url;
    
    if (avatarKeyString == "00000000-0000-0000-0000-000000000000") {
        url = "http://web.infernosoft.com/blackgazza/unregisterInmate.php?"+
        "avatar=" + avatarKeyString + "&" + 
        "name=" + llEscapeURL(avatarName) + "&" + 
        "prim=" + primKeyString + "&" + 
        "timeSent=" + llEscapeURL(timeStampAll);
    } else {
        url = "http://web.infernosoft.com/blackgazza/registerInmate.php?"+
        "avatar=" + avatarKeyString + "&" + 
        "name=" + llEscapeURL(avatarName) + "&" + 
        "prim=" + primKeyString + "&" + 
        "locked=" + (string)locked + "&" +
        "timeSent=" + llEscapeURL(timeStampAll);
    }
    
    list parameters = [HTTP_METHOD, "GET",
        HTTP_MIMETYPE,"text/plain;charset=utf-8"];
    string body = "";
    //llOwnerSay(url); // *** debug
    httprequest = llHTTPRequest(url, parameters, body );
}





stop_anims( key agent )
{
    list    l = llGetAnimationList( agent );
    integer    lsize = llGetListLength( l );
    integer i;
    for ( i = 0; i < lsize; i++ )
    {
        //llOwnerSay("stopping an animation");
        llStopAnimation( llList2Key( l, i ) );
    }
}


default
{
    state_entry()
    {
        llPreloadSound("electricshock");
        llSetTimerEvent(1.0);
        commandlisten = llListen(commandchannel, "Timberwoof Prison Box", "", "" );
            }

     attach( key id )
     {
        avatarKey = id;
        avatarKeyString = (string)avatarKey;
        avatarName = llKey2Name(avatarKey);
        
        primKey = llGetKey( );
        primKeyString = (string)primKey;
        
        registerWithDB(0);
    }
 
    touch_start( integer num_detected )
    {
        integer now = llGetUnixTime( );
        //llOwnerSay("now: " + (string)now);
        if (locked > 0) {
            llWhisper(0,llKey2Name(llDetectedKey(0)) + " punishes " + avatarName + " for disobedience.");
            agony = now + agonyduraton;
        }    
        //llOwnerSay("agony: " + (string)agony);
        // agony is normally 0. Now it is set to some time from now. It is the time of the end of agony.
    }
    
    run_time_permissions(integer permissions)
    {
        //llOwnerSay("run_time_permissions" + (string)mytimer);
        if (permissions & PERMISSION_TRIGGER_ANIMATION) {
            llStartAnimation(theAnimation);
        }
    }

    
    timer()
    {
        float red = llFrand(1.0);
        float green = llFrand(0.5);
        
        if (green > red) {
            red = green;
        }
        if (locked > 0) {
            llSetText("BG Tag 0.2\n*Active*",<red,green,0>,1);
        } else {
            llSetText("BG Tag 0.2\nInactive",<0,1,0>,1);
        }
        
        integer now = llGetUnixTime( );

        if (agony > now) {
            //llOwnerSay("now: " + (string)now);
            // if agony end time has not been reached, see if agony animation has started.
            llPlaySound("electricshock", 1.0);      
            if (inagony == 0) {
                // if agony animaiton has not started, start it
                theAnimation = "shock";
                llRequestPermissions( avatarKey, PERMISSION_TRIGGER_ANIMATION );
                inagony = 1;
            } else {}}
        else {        
            if (inagony == 1) {
            // agony end time hs been reached; stop that animation and kick off a faint
            llStopAnimation(theAnimation);
            stop_anims( avatarKey );
            agony = 0;
            inagony = 0;
            agonyduraton = agonyduraton + 5;    // make it last long er next time

            fainted = now + faintduration;      // kick off a faint
            llWhisper(0,avatarName + " fainted form the pain");
            } else {} }
        
        
        if (fainted > now) {
            //llOwnerSay("now: " + (string)now);
            // if faint end time has not been reached, see if agony animation has started.      
            if (faint == 0) {
                // if faint animaiton has not started, start it
                llOwnerSay("@sendchat=n,recvchat=n");   // no chatting
                theAnimation = "Fall/Faint";
                llRequestPermissions( avatarKey, PERMISSION_TRIGGER_ANIMATION );
                faint = 1;
            } else {}}
        else {        
            if (faint == 1) {
            // faint end time hs been reached; stop that animation and kick off a faint
            llStopAnimation(theAnimation);
            stop_anims( avatarKey );
            theAnimation = "Stand";
            llRequestPermissions( avatarKey, PERMISSION_TRIGGER_ANIMATION );
            faint = 0;
            fainted = 0;
            faintduration = faintduration + 5;  // make it last long next time
            llOwnerSay("@sendchat=y,recvchat=y");   // allow chat again
            } else {} }
        }
    

    // listen to the prison box
    listen( integer channel, string name, key id, string message )
    {
        if (channel == commandchannel) {
            //llOwnerSay(message);
            integer space = llSubStringIndex(message," ");
            string keyString = llGetSubString(message,0,space-1);
            //llOwnerSay("keyString:'" + keyString + "'");
            
            string RLVmessage = llGetSubString(message,space+1,-1);
            //llOwnerSay("RLVmessage:'" + RLVmessage + "'");
            
            if (avatarKeyString == keyString) {
                llOwnerSay(RLVmessage);
                    if (llSubStringIndex(message,"@clear") > 0) {
                    locked = 0;
                } else {
                    locked = 1;
                }
            }
            registerWithDB(locked);

            //            avatarKeyString
            //llOwnerSay("received message from prison lock");
            //llListenRemove(commandlisten); // no wonder it doesn't get the command. 
            //statuslisten = llListen(statuschannel, "Zap Badge", "", "" );
            //llOwnerSay("@getstatus=" + (string)statuschannel);
        }
        // doesn't seem to work
        //if (channel == statuschannel) {
        //    llOwnerSay("received status message");
        //    llOwnerSay (message);
        //    llListenRemove(statuslisten);
        //}
    }
    
    http_response(key request_id, integer status, list metadata, string body)
    {
        if (request_id == httprequest)
        {
            //llOwnerSay("response...");
            //llOwnerSay(body); // *** debug
            //llOwnerSay("...response");
        }
    }


    state_exit()
    {
        // doesn't seem to work
        llOwnerSay("state_exit");
        llOwnerSay("@clear");
        //statuslisten = llListen(statuschannel, "Zap Badge", "", "" );
        //llOwnerSay("@getstatus=" + (string)statuschannel);
    }
}
