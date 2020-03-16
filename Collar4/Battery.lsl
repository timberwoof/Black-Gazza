// Battery.lsl
// Battery script for Black Gazza Collar 4
// Timberwoof Lupindo, June 2019
// version: 2020-03-15

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

sendJSONinteger(string jsonKey, integer value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, (string)value]), avatarKey);
    }
    
string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
        }
    return result;
    }
        
float updateValue(string json, string jsonKey, float now, float replace) {
    string value = llJsonGetValue(json, [jsonKey]);
    if (value != JSON_INVALID) {
        return replace;
    } else {
        return now;
    }
}



dischargeBattery(float seconds)
{
    batteryCharge = batteryCharge - seconds;
    if (batteryCharge <= 0) {
        batteryCharge = basicCharge; // user choice battery "off" state
        sayDebug("dischargeBattery: recharged battery");
    }
    sayDebug("dischargeBattery:"+(string)seconds+" seconds leaves "+(string)batteryCharge+" charge.");
    integer displayLevel = (integer)llFloor(batteryCharge/basicCharge*100);
    sendJSONinteger("batteryLevel", displayLevel, "");
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
        currentDischargeRate = 1.0;
        timerInterval = 300.0;
        llSetTimerEvent(timerInterval);
        sayDebug("initialized");
    }

    link_message( integer sender_num, integer num, string json, key id ){
        sayDebug("link_message "+json);
        float chargeUsed = 0;
        
        chargeUsed = updateValue(json, "prisonerMood", chargeUsed, 600);
        chargeUsed = updateValue(json, "zapLevels", chargeUsed, 600);
        chargeUsed = updateValue(json, "prisonerThreat", chargeUsed, 600);
        chargeUsed = updateValue(json, "prisonerClass", chargeUsed, 1200);
        chargeUsed = updateValue(json, "prisonerCrime", chargeUsed, 1200);
        chargeUsed = updateValue(json, "prisonerLockLevel", chargeUsed, 1200);
        string value = getJSONstring(json, "zapPrisoner", "");
        if (value != JSON_INVALID) {
            // message is like "Zap Low" 
            string variation = llGetSubString(value, 4,6);
            if (variation == "Low") {
                chargeUsed = 60 * 60; // 1 hour for light zap
            } else if (variation == "Med") {
                chargeUsed = 2 * 60 * 60; // 2 hours for medium zap
            } else if (variation == "Hig") {
                chargeUsed = 4 * 60 * 60; // 4 hours for heavy zap
            }
        }
        currentDischargeRate = llList2Float(dischargeRates, llListFindList(rlvStates, [theRLVstate]));
        if (chargeUsed) dischargeBattery(chargeUsed);
    }

    timer() {
        dischargeBattery(timerInterval * currentDischargeRate);
    }
}
