integer LinkFrame = 1;
integer FaceFrame = 0;
integer FacePadding = 1;

integer LinkBlinky = 17;
integer FaceBlinky1 = 1;
integer FaceBlinky2 = 2;
integer FaceBlinky3 = 3;
integer FaceBlinky4 = 4;

integer FaceAlphanum = 1;
list LinkAlphanums = [14, 13, 12, 11, 10, 9, 8, 7, 6, 5]; // better done mathematically

integer FaceAlphanumFrame = 5;
integer LinkAlphanumFrame = 17;

vector BLACK = <0,0,0>;
vector DARK_GRAY = <0.2, 0.2, 0.2>;
vector DARK_BLUE = <0.0, 0.0, 0.2>;
vector BLUE = <0.0, 0.0, 1.0>;
vector MAGENTA = <1.0, 0.0, 1.0>;
vector CYAN = <0.0, 1.0, 1.0>;
vector WHITE = <1.0, 1.0, 1.0>;
vector RED = <1.0, 0.0, 0.0>;
vector REDORANGE = <1.0, 0.25, 0.0>;
vector ORANGE = <1.0, 0.5, 0.0>;
vector YELLOW = <1.0, 1.0, 0.0>;
vector GREEN = <0.0, 1.0, 0.0>;

list colors = [];

integer LinkBatteryDisplay = 17;
integer FaceBatterySisplay = 0;
key GraphicBattery = "ef369716-ead2-b691-8f5c-8253f79e690a";


default
{
    state_entry()
    {
        llSay(0, "Hello, Avatar!");
        colors = [RED, ORANGE, YELLOW, GREEN, BLUE, BLACK];
        llSetTimerEvent(1);
        llSetLinkTextureAnim(LinkBatteryDisplay, 0,FaceBatterySisplay,5, 1, 0.0, 6.0, 6 );
 
        //llSetTextureAnim( ANIM_ON | LOOP, 0, 5, 1, 0.0, 6.0, 6 );
        // sizex = 5
        // sizey = 1
    }

    touch_start(integer total_number)
    {
        integer touchedLink = llDetectedLinkNumber(0);
        integer touchedFace = llDetectedTouchFace(0);
        vector touchedUV = llDetectedTouchUV(0);
        llSay(0, "Link "+(string)touchedLink+", Face "+(string)touchedFace+" UV "+(string)touchedUV);
    }
    
    timer()
    {
        integer face = llFloor(llFrand(4)) + 1;
        integer color =  llFloor(llFrand(6)) + 1;
        llSetLinkColor(LinkBlinky, llList2Vector(colors, color), face);
        
        color =  llFloor(llFrand(6)) + 1;
        llSetLinkColor(LinkAlphanumFrame, llList2Vector(colors, color), FaceAlphanumFrame);
    }
}



