// Cell Control Box

// Important Setup Instructions
// Cells come in pairs; they can be in any of four cell blocks A B C D and have numbers 1..8
// The left cell is always odd-numbered and the right cell is always even-numbered. 
// The left cell prim must be named its name (A1, B5, D7 ...)
// The right cell prim must be named its name (A2, B6, D8 ...)
// The Controller box prim must be named the same as the LEFT cell (A1, B5, D7 ...)
// These names are used to determine how the Controller box and cells talk to each other
// and to set the position of the single texture that has all the cell names and appears on the Controller box.
// The names also show up in the "Other Cell" selection menu. 

string gControl = "None";
key gControlKey = NULL_KEY;
string gDisplayLeft = "";
string gDisplayRight = "";
integer gDisplayDirty = FALSE;
string gLeftCell = "";
string gRightCell = "";
integer gLeftCellLinkNum;
integer gRightCellLinkNum;

list gInmatesLeft = [];
list gInmatesRight = [];

integer gCommandChannel; 
integer gCommandChannelHandle;

initialize() { 
    llListenRemove(gCommandChannelHandle);
    gCommandChannel = -1 * ((integer)llFrand(1000000) + 1000000);
    gCommandChannelHandle = llListen(gCommandChannel, "", NULL_KEY, "");
    llSetTimerEvent(5);
    // Set the names of the two cells. 
    // The name of the object that is this lockbox must be set to {A|B|C|D} {1,3,5,7,9}
    // (the name of the left cell). 
    // This moves the texture so that the correct letters show up in front. 
    string this_cell_pair = llGetObjectName();
    string cell_block_char = llGetSubString(this_cell_pair, 0, 0); 
    integer cell_number = (integer)llGetSubString(this_cell_pair, 1, 1); 
    integer cell_block_char_index = llSubStringIndex("ABCD", cell_block_char) + 1;
    
    gLeftCell = cell_block_char + (string)cell_number + "…";
    gRightCell = cell_block_char + (string)(cell_number + 1) + "…";
    
    float texture_offset_u = cell_number * .1 - .5;
    float texture_offset_v = cell_block_char_index * -.25 + .625; 
    llOffsetTexture(texture_offset_u, texture_offset_v, -1); 
    llScaleTexture(.2, .25, -1);
} 

default
{
    state_entry()
    {
        initialize();
    }
    
    on_rez(integer state_entered) {
        initialize();
    }

    touch_start(integer total_number)
    {
        key accessor = llDetectedKey(0);
        //llWhisper(0, (string)llDetectedTouchFace(0));
        //llWhisper(0, (string)llDetectedTouchST(0));
        
        if(llDetectedTouchFace(0) == 4)
        {
            vector st = llDetectedTouchST(0);
            if(st.x > 0.5)
            {
                gControl = gRightCell;
            }
            else
            {
                gControl = gLeftCell;
            }
            gControlKey = accessor;
        }
        
        if(accessor != gControlKey)
        {
            gControl = "None";
        }
        
        if (llListFindList(gInmatesLeft + gInmatesRight, [(string)accessor]) == -1) {
            if (gControl == "None") {
                llDialog(accessor, "Choose A Cell To Control:", [gLeftCell,gRightCell], gCommandChannel);
            } else {
                llMessageLinked(LINK_ALL_OTHERS, 5000, gControl, accessor);
            }
        } else {
            //llSay(0, llKey2Name(accessor) + " is given a soft shock as they attempt to manipulate their cell.");
            llWhisper(-106969,(string)accessor);

        }
    }
    
    listen(integer incoming_channel, string incoming_name, key incoming_key, string incoming_message) {
        if (incoming_channel == gCommandChannel) {
            if (incoming_message == gLeftCell || incoming_message == gRightCell) {
                gControl = incoming_message;
                gControlKey = incoming_key;
                llMessageLinked(LINK_ALL_OTHERS, 5000, incoming_message, incoming_key);
            }
        }
    }
    
    link_message(integer sender_num, integer message_num, string received_message, key link_user) {
        if (message_num == 5003) {
            if (received_message == "Release") {
                gControl = "None";
                gControlKey = NULL_KEY;
            }
            if (received_message == "Other") {
                string cell;
                
                if(gLeftCellLinkNum == sender_num)
                {
                    cell = gRightCell;
                }
                else
                {
                    cell = gLeftCell;
                }
                gControl = cell;
                llMessageLinked(LINK_ALL_OTHERS, 5000, cell, link_user);
            }
        } else if (message_num == 5001) {
            gLeftCellLinkNum = sender_num;
            if(gDisplayLeft != received_message) {
                gDisplayLeft = received_message;
                gDisplayDirty = TRUE;
            }
        } else if (message_num == 5002) {
            gRightCellLinkNum = sender_num;
            if(gDisplayRight != received_message) {
                gDisplayRight = received_message;
                gDisplayDirty = TRUE;
            }
        } else if (message_num == 5004) {
            if(gLeftCellLinkNum == sender_num)
            {
                gInmatesLeft = llCSV2List(received_message);
            }
            if(gRightCellLinkNum == sender_num)
            {
                gInmatesRight = llCSV2List(received_message);
            }
        }
    }
    
    timer() {
        if(gDisplayDirty)
        {
            llSetText(gDisplayLeft + "\n \n" + gDisplayRight, <1.0,1.0,1.0>, 1.0);
            gDisplayDirty = FALSE;
        }
    }    
}
