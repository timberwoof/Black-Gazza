// Speech.lsl
// Speech script for Black Gazza Collar 4
// Timberwoof Lupindo
// March 2020
// version 2020-03-01

// Handles all speech-related functions for the collar
// Renamer - Gag - Bad Words 

integer OPTION_DEBUG = 1;
integer rlvPresent = 0;
integer renamerActive = 0;
integer renameChannel = 0;
integer renameListen = 0;
string assetNumber;

list badWords;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Speech:"+message);
    }
}

default
{
    state_entry()
    {
    }

    link_message(integer sender_num, integer num, string message, key avatarKey){ 
        if (num == 2101) {
            renamerActive = (integer)message;
            if (renamerActive) {
                sayDebug("link_message renamer on");
                renameChannel = (llFloor(llFrand(10000)+1000));
                renameListen = llListen(renameChannel, "", llGetOwner(), "");
                string rlvcommand = "@redirchat:"+(string)renameChannel+"=add";
                sayDebug("link_message renamer rlvcommand:"+rlvcommand);
                llOwnerSay(rlvcommand);
            } else {
                sayDebug("link_message renamer off");
                string rlvcommand = "@redirchat:"+(string)renameChannel+"=rem";
                sayDebug("link_message renamer rlvcommand:"+rlvcommand);
                llOwnerSay(rlvcommand);
                llListenRemove(renameChannel);
                renameChannel = 0;
                renameListen = 0;
            }
        }
        
        if (num == 2110) {
            llOwnerSay("");
        }

        if (num == 1400) {
            // RLV Presence
            if (message == "Off") {
                rlvPresent = 0;
                renamerActive = 0;
            } else {
                rlvPresent = 1;
            }    
            sayDebug("link_message set rlvPresent:"+(string)rlvPresent);
        }
        
        if (num == 2000) {
            assetNumber = message;
            sayDebug("link_message set "+message);
        }
    }
    
    listen(integer channel, string name, key avatarKey, string message){
        llSay(0,message);
        }
}
