integer MYNUMBER = 0;

list commandList = ["Rubber","Canvas","Steel","Glass","Stars","White","Paws","Opt2","Opt3","Opt5","Pink","Old"];
list textureList = ["E&D Fabric - Latex Rubber - FLR001 07","TRU PADDED CELL","grayheavy_1a","AF_glass_block.tga","stars01","White Tile","MichaelMillerBlackPawsYellow.jpg","CATERS_MASTER_OF_OPTICAL_ILLUSIONS_02","CATERS_MASTER_OF_OPTICAL_ILLUSIONS_03","CATERS_MASTER_OF_OPTICAL_ILLUSIONS_05a","Pinkwalls","PaddedWallYucky"];

list HollowNameslist = ["Small", "Medium", "Large"];
list HollowNumbersList = [.45, .70, .95];
float oldHollow;

integer numberOccupants;

adjust_hollow(float newHollow) {
    integer steps = 5;
    float deltaHollow = (newHollow - oldHollow) / steps;
    float hollow = oldHollow;
    integer i;
    //llPlaySound(gDoorSound,gSoundVolume);
    for (i = 0; i < steps; i++) {
        llSetPrimitiveParams([PRIM_TYPE, PRIM_TYPE_SPHERE, PRIM_HOLE_CIRCLE, 
            <0.0, 1.0, 0.0>, hollow, <0.0, 0.0, 0.0>, <0.196, 1.0, 0.0>]);
        hollow = hollow + deltaHollow;
        }
    llSetPrimitiveParams([PRIM_TYPE, PRIM_TYPE_SPHERE, PRIM_HOLE_CIRCLE, 
            <0.0, 1.0, 0.0>, newHollow, <0.0, 0.0, 0.0>, <0.196, 1.0, 0.0>]); 
    oldHollow = newHollow; 
    }

default
{
    state_entry()
    {
        string mynumber = llGetObjectDesc( );
        llSetObjectName("Medical Isolation Cell "+mynumber);
        MYNUMBER = (integer) mynumber;
        adjust_hollow(.95);
        llSetTexture("TRU PADDED CELL",1);
        llSensorRepeat("","",AGENT,3.5,PI,5);
        numberOccupants = 0;
    }
    
    touch_start(integer num_detected)
    {
    }
   
    sensor(integer num_detected)
    {
        if (numberOccupants != num_detected)
        {
            llMessageLinked(LINK_ROOT, MYNUMBER, "occupied", "");
            numberOccupants = num_detected;
        }
    }
    
    no_sensor()
    {
        if (numberOccupants != 0)
        {
            llMessageLinked(LINK_ROOT, MYNUMBER, "empty", "");
            numberOccupants = 0;
        }
    }
    
    link_message(integer Sender, integer Number, string Command, key Key) {
        if (Number == MYNUMBER) {
            integer index = llListFindList(commandList, [Command]);
            if (index >= 0) {
                string texture = llList2String(textureList, index);
                llSetTexture(texture,1);
            } else {
                integer index = llListFindList(HollowNameslist, [Command]);
                if (index >= 0) {
                    float newHollow = llList2Float(HollowNumbersList, index);
                    adjust_hollow(newHollow);
                }
            }
        }
    }
}
