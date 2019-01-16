integer MYNUMBER = 0;

initialize() {
    string mynumber = llGetObjectDesc( );
    llSetObjectName("Medical Isolation Cell "+mynumber);
    MYNUMBER = (integer) mynumber;
     }

list commandList = ["Rubber","Canvas","Steel","Glass","Stars","White","Paws","Opt2","Opt3","Opt5","Pink","Old"];
list textureList = ["E&D Fabric - Latex Rubber - FLR001 07","TRU PADDED CELL","grayheavy_1a","AF_glass_block.tga","stars01","White Tile","MichaelMillerBlackPawsYellow.jpg","CATERS_MASTER_OF_OPTICAL_ILLUSIONS_02","CATERS_MASTER_OF_OPTICAL_ILLUSIONS_03","CATERS_MASTER_OF_OPTICAL_ILLUSIONS_05a","Pinkwalls","PaddedWallYucky"];

list HollowNameslist = ["Small", "Medium", "Large"];
list HollowNumbersList = [.45, .70, .95];
float oldHollow;


default
{
    touch_start(integer arf) {
    } 
    
    
    state_entry()
    {
        initialize();
    }
    
    link_message(integer Sender, integer Number, string Command, key Key) {
        if (Number == MYNUMBER) {
            integer index = llListFindList(commandList, [Command]);
            if (index >= 0) {
                string texture = llList2String(textureList, index);
                llSetTexture(texture,0);
            }
        }
    }
}


