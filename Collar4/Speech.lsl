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
            } else {
                sayDebug("link_message renamer off");
            }
        }
    
        if (num == 1403) {
            // RLV Presence
            if (message == "NoRLV") {
                rlvPresent = 0;
                renamerActive = 0;
            } else if (message == "YesRLV") {
                rlvPresent = 1;
            }    
        sayDebug("link_message set rlvPresent:"+(string)rlvPresent);
        }
    }
}
