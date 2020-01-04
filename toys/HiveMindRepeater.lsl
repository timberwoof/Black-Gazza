integer hiveTalkChannel = -77683945; // avatars talk & resend
integer hiveTalkListen = 0;
integer hiveHearChannel = -77683950; // avatars listen & tell avatars


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
