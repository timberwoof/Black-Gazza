integer OPTION_DEBUG = 0;

float topV = 4.0;
float bottomV = -2.0;

integer topFloor = 5;
integer bottomFloor = 0;

vector primSize;

integer menuChannel = 0;
integer menuListen = 0;

integer WAITING_FOR_MENU_CLICK = 0;
integer WAITING_FOR_FLOOR = 1;
integer WAITING_FOR_SIT_CLICK = 2;
integer STATE = 0;

integer desiredFloor = 0;

// textures for face 2
key open = "cc198c21-1485-f6e2-8d99-2c01011533c1";
key closed = "dfa1cff2-1005-f841-898b-146f13d2d5aa";

debug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay(message);
    }
}


default
{
    state_entry()
    {
        llSetTexture(closed, 2);
        primSize = llGetScale();
        llSetClickAction(CLICK_ACTION_TOUCH);
        STATE = WAITING_FOR_MENU_CLICK;
    }

    touch_start(integer total_number)
    {
        if (STATE == WAITING_FOR_MENU_CLICK) {
        key avatar = llDetectedKey(0);
        
        integer touchedLink = llDetectedLinkNumber(0);
        integer touchedFace = llDetectedTouchFace(0);
        llOwnerSay((string)touchedFace);
        vector touchedUV = llDetectedTouchUV(0);
        integer touchedFloor = llFloor((topFloor - bottomFloor + 1) * (touchedUV.y - bottomV) / (topV - bottomV));
        
        list buttons = [];
        integer i;
        for (i = bottomFloor; i <= topFloor; i++) {
            if (i != touchedFloor) {
                buttons = buttons + [(string)i];
            }
        }
        
        string message = "Select the Floor, then click again.";
        menuChannel = llFloor(-llFrand(10000)-10000);
        menuListen = llListen(menuChannel, "", avatar, "");
        llDialog(avatar, message, buttons, menuChannel);
        llSetTimerEvent(30);
        STATE = WAITING_FOR_FLOOR;
        }
    }
    
    listen(integer channel, string name, key id, string message) {
        // must be in STATE == WAITING_FOR_FLOOR
        llSetTexture(open, 2);
        desiredFloor = (integer)message;
        llSetClickAction(CLICK_ACTION_SIT);
        float xOffset = primSize.x / 2.0 + 1;
        float yOffset = 1.5;
        float zOffset = primSize.z / (topFloor - bottomFloor + 1) * (desiredFloor + 0.3) - primSize.z / 2.0;
        vector offset = <xOffset,yOffset,zOffset>;
        llSitTarget(offset, <0,0,0,0>);
        STATE = WAITING_FOR_SIT_CLICK;
    }
    
    timer() {
        if (STATE == WAITING_FOR_FLOOR) {
            llSetTexture(closed, 2);
            llListenRemove(menuListen);
            STATE = WAITING_FOR_MENU_CLICK;
        }
        if (STATE == WAITING_FOR_SIT_CLICK) {
            llSetTexture(closed, 2);
            llSetClickAction(CLICK_ACTION_TOUCH);
            STATE = WAITING_FOR_MENU_CLICK;
        }
        llSetTimerEvent(0);
    }
    
    changed(integer change) {
        if ((STATE == WAITING_FOR_SIT_CLICK) && (change & CHANGED_LINK)) {
            key user = llAvatarOnSitTarget();
            if(user) {
                llSetTexture(closed, 2);
                llUnSit(user); 
                llSetClickAction(CLICK_ACTION_TOUCH);
                STATE = WAITING_FOR_MENU_CLICK;
            }
        }
        
    }
}
