//Battery.lsl
// Battery script for Black Gazza Collar 4
// Timberwoof Lupindo, June 2019

// Receives events from other sytsems and discgarhes the battery accordingly. 
// Receives recharge message from the charger and charges the battery accordingly. 
// Sends battery state commands to Display. 

integer OPTION_DEBUG = 0;

float basicCharge; // battery capacity in seconds
float batteryCharge; // seconds left
list rlvStates; // names of rlv states
list dischargeRates;  // battery seconds per second
float currentDischargeRate; 
string theRLVstate;
float timerInterval;


sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Battery:"+message);
    }
}

float calculateDischargeRate(){
    // given the current RLV state, calculate the battery discharge rate
    integer index = llListFindList(rlvStates, [theRLVstate]);
    return llList2Float(dischargeRates, index);
}

dischargeBattery(float seconds)
{
    batteryCharge = batteryCharge - seconds;
    if (batteryCharge <= 0) {
        batteryCharge = basicCharge; // user choice battery "off" state
        sayDebug("dischargeBattery: recharged battery");
    }
    sayDebug("dischargeBattery:"+(string)seconds+" seconds leaves "+(string)batteryCharge+" charge.");
    sendBatteryStatus();
}

sendBatteryStatus(){
    integer displayLevel = (integer)llFloor(batteryCharge/basicCharge*100);
    llMessageLinked(LINK_THIS, 1701, (string)displayLevel, "");
}

default
{
    state_entry()
    {
        rlvStates = ["Off", "Light", "Medium", "Heavy", "Hardcore"];
        
        basicCharge = 24 * 60 * 60; // 24 hours worth of seconds
        // discharge rates contains fraction of basic charge that gets used every second
        dischargeRates = [0.0]; // Off
        dischargeRates = dischargeRates + [1.0]; // Light = 24 hours
        dischargeRates = dischargeRates + [2.0]; // Medium 2x rate = 12 hours
        dischargeRates = dischargeRates + [3.0]; // Heavy 3x rate = 8 hours
        dischargeRates = dischargeRates + [4.0]; // Hardcore 4x rate = 6 hours
        theRLVstate = "Off";
        batteryCharge = basicCharge;
        currentDischargeRate = calculateDischargeRate();
        timerInterval = 300.0;
        llSetTimerEvent(timerInterval);
        sayDebug("initialized");
    }

    link_message( integer sender_num, integer num, string message, key id ){ 
        if (num != 1701) {
            sayDebug("link_message "+(string)num+" "+message);
            float chargeUsed = 0;
            if (num == 1100 || num == 1301 || num == 1500) { // set icooc, zap level, threat level
                chargeUsed = 10 * 60; // 10 minutes for a small adjustment
            } else if (num == 1200 || num == 1800) { // set prisoner class, crime
                chargeUsed = 20 * 60; // 20 minutes for database access
            } else if (num == 1400) { // set lock level
                // Based on new RLV setting, change discharge rate
                theRLVstate = message; 
                chargeUsed = 20 * 60; // 20 minutes for database access
                currentDischargeRate = calculateDischargeRate();
                dischargeBattery(timerInterval * currentDischargeRate);// *** why?
            } else if (num == 1302) {
                // message is like "Zap Low" 
                string variation = llGetSubString(message, 4,6);
                if (variation == "Low") {
                    chargeUsed = 60 * 60; // 1 hour for light zap
                } else if (variation == "Med") {
                    chargeUsed = 2 * 60 * 60; // 2 hours for medium zap
                } else if (variation == "Hig") {
                    chargeUsed = 4 * 60 * 60; // 4 hours for heavy zap
                }
            }
            dischargeBattery(chargeUsed);
        }
    }

    timer() {
        dischargeBattery(timerInterval * currentDischargeRate);
        sendBatteryStatus();
    }
}
