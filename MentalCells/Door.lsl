//Timberwoof Lupindo's Automatic Door

// Global Constants that you can edit
integer gLoopsteps = 8; // number of steps for animation; chosen to match length of sound
float gDoorClosedCut = 0.0;
float gDoorOpenCut = 0.80;
float gSoundVolume = 0.5;

// don't touch these globals
list gDoorClosedCutState;
list gDoorOpenCutState;
float gDoorDelta; // (gDoorOpenCut - gDoorClosedCut) / gLoopsteps;
string gDoorSound = "B5door";
string gDoorState;
string gDoorClosed = "CLOSED";
string gDoorOpened = "OPEN";
integer gPopulation; // number of avatars within 2 m - relates to the state of the door
string DoorState = gDoorClosed; 

list commandList = ["Rubber","Canvas","Steel","Glass","Stars","White","Paws","Opt2","Opt3","Opt5","Pink","Old"];
list textureList = ["E&D Fabric - Latex Rubber - FLR001 07","TRU PADDED CELL","grayheavy_1a","AF_glass_block.tga","stars01","White Tile","MichaelMillerBlackPawsYellow.jpg","CATERS_MASTER_OF_OPTICAL_ILLUSIONS_02","CATERS_MASTER_OF_OPTICAL_ILLUSIONS_03","CATERS_MASTER_OF_OPTICAL_ILLUSIONS_05a","Pinkwalls","PaddedWallYucky"];

integer MYNUMBER = 0;

initialize() 
{
    string mynumber = llGetObjectDesc( );
    llSetObjectName("Medical Isolation Door "+mynumber);
    MYNUMBER = (integer) mynumber;
    
    gDoorClosedCutState = [PRIM_TYPE, PRIM_TYPE_BOX, PRIM_HOLE_CIRCLE, <0.0, 1.0, 0.0>, gDoorClosedCut, 
    <0.0, 0.0, 0.0>, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>];
    
    gDoorOpenCutState = [PRIM_TYPE, PRIM_TYPE_BOX, PRIM_HOLE_CIRCLE, <0.0, 1.0, 0.0>, gDoorOpenCut, 
    <0.0, 0.0, 0.0>, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>];
    
    llSetPrimitiveParams(gDoorClosedCutState);  
    gDoorState =  gDoorClosed; 
    gDoorDelta = (gDoorOpenCut - gDoorClosedCut) / gLoopsteps;
}

open_door() 
{
    if (gDoorState != "OPEN") 
    {
        float DoorCutState; 
        llPlaySound(gDoorSound,gSoundVolume);
        for (DoorCutState = gDoorClosedCut; DoorCutState <= gDoorOpenCut; DoorCutState += gDoorDelta) 
        {
            llSetPrimitiveParams([PRIM_TYPE, PRIM_TYPE_BOX, PRIM_HOLE_CIRCLE, <0.0, 1.0, 0.0>, DoorCutState, 
                <0.0, 0.0, 0.0>, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>]);
        }
        llSetPrimitiveParams(gDoorOpenCutState);   // open just to make sure
        llSetTexture("st_wallg_2", 5 ); 
        gDoorState = "OPEN";
    }
    llMessageLinked(LINK_ROOT, MYNUMBER, gDoorState, "");
}

close_door() 
{
    if (gDoorState != "CLOSED") 
    {
        llPlaySound(gDoorSound,gSoundVolume);
        float DoorCutState; 
        for (DoorCutState = gDoorOpenCut; DoorCutState >= gDoorClosedCut; DoorCutState -= gDoorDelta) 
        {
            llSetPrimitiveParams([PRIM_TYPE, PRIM_TYPE_BOX, PRIM_HOLE_CIRCLE, <0.0, 1.0, 0.0>, DoorCutState, 
                <0.0, 0.0, 0.0>, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>]);
        }
        llSetPrimitiveParams(gDoorClosedCutState);    // closed just to make sure
        gDoorState = "CLOSED";
    }    
    llMessageLinked(LINK_ROOT, MYNUMBER, gDoorState, "");
}



default
{
    state_entry()
    {
        initialize();
    }
    
    touch_start(integer num_detected)
    {
    }
    
    link_message(integer Sender, integer Number, string Command, key Key) 
    {
        if (Number == MYNUMBER) 
        {
            if (Command == "Open") 
            {
                open_door();
            } 
            else if (Command == "Close") 
            {
                close_door();
            } 
            else 
            {
                integer index = llListFindList(commandList, [Command]);
                if (index >= 0) 
                {
                    string texture = llList2String(textureList, index);
                    llSetTexture(texture,0);
                }
            }
        }
    }
}
