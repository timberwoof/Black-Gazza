// HiveMindRepeater.lsl
// companion to PodVisionTalk.lsl
// Timberwoof Lupindo
// forces eyepoint of people who sit in an MD Pod to match their avatar
// enables speech between pod prisoners

// HiveTalk constants and variables
integer hiveTalkChannel = 77683945; // avatars talk & resend; this scriopt listens  on this channel
integer hiveHearChannel = 77683950; // this script talks; pod scripts listen & tell avatars on this channel
integer hiveTalkListen = 0;

default
{
    state_entry()
    {
        llRegionSay(hiveHearChannel, "Hive Mind Repeater state_entry");
        hiveTalkListen =  llListen(hiveTalkChannel, "","", "");
        llSetTimerEvent(30);
        llSetText("Initilaized", <1,1,1>,1);
    }

    touch_start(integer total_number)
    {
        llRegionSay(hiveHearChannel, "has been touched.");
    }
    
    listen(integer channel, string name, key id, string message) {
        llRegionSay(hiveHearChannel, message);
        llSetText(message, <1,1,1>,1);
    }
    
    timer() {
        llRegionSay(hiveHearChannel, "test message");
    }
}
