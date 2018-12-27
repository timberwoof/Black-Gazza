integer CELL_SENSOR_INTERVAL = 2;
float gSensorRadius;
integer OPTION_DEBUG = 0;

debug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Sensor - "+message);
    }
}

getParameters()
{
    string optionstring = llGetObjectDesc();
    debug("getParameters("+ optionstring +")");
    OPTION_DEBUG = 0;
    if (llSubStringIndex(optionstring,"debug") > -1) OPTION_DEBUG = 1;
}

default
{
    state_entry()
    {
        getParameters();
        vector myscale = llGetScale();
        gSensorRadius = (myscale.x + myscale.y) / 3.0;
    }
    
    link_message(integer sender_num, integer msgInteger, string msgString, key msgKey) {
        if (msgInteger == 3000) {
            debug("llSensorRemove");
            llSensorRemove();
        } else if (msgInteger == 3001) {
            debug("llSensorRepeat");
            llSensorRepeat("","",AGENT,gSensorRadius,PI,CELL_SENSOR_INTERVAL); 
        } else if (msgInteger == 2030) {
            getParameters();
        }
    }
    
    sensor(integer num_detected)
    {
        debug("sensor");
        llMessageLinked(LINK_ROOT, num_detected, "sensor", llDetectedKey(0));
        integer i;
        for (i = 0; i<num_detected; i++)
        {
            llMessageLinked(LINK_ROOT, num_detected, "sensor_list", llDetectedKey(i));
        }
        llMessageLinked(LINK_ROOT, num_detected, "sensor_done", llDetectedKey(0));
    }
    
    no_sensor()
    {
        debug("no_sensor");
        llMessageLinked(LINK_ROOT, 0, "no_sensor", "");
    }
}
