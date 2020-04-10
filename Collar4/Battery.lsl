// Battery.lsl
// Battery script for Black Gazza Collar 4
// Timberwoof Lupindo, June 2019
// version: 2020-04-10

// Receives events from other sytsems and discgarhes the battery accordingly. 
// Receives recharge message from the charger and charges the battery accordingly. 
// Sends battery state commands to Display. 

integer OPTION_DEBUG = 0;

float basicCharge; // battery capacity in seconds
float batteryCharge; // seconds left
integer displayLevel;
list rlvStates; // names of rlv states
list dischargeRates;  // battery seconds per second
float dischargeRate; 
string theRLVstate;
float timerInterval;

string prisonerMood = "OOC";
string prisonerLockLevel = "Off";
list LockLevels = ["Off", "Light", "Medium", "Heavy", "Hardcore"];
integer renamerActive = 0;
integer badWordsActive = 0;
integer gagActive = 0;
integer DisplayTokActive = 0;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Battery:"+message);
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
        
integer getJSONinteger(string jsonValue, string jsonKey, integer valueNow){
    integer result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = (integer)value;
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



dischargeBattery(string why, float seconds)
{
    batteryCharge = batteryCharge - seconds;
    if (batteryCharge <= 0) {
        batteryCharge = basicCharge; // user choice battery "off" state
        sayDebug("dischargeBattery("+why+","+(string)seconds+"): recharged battery");
    }
    sayDebug("dischargeBattery("+why+","+(string)seconds+") leaves "+(string)batteryCharge+" charge.");
    integer newDisplayLevel = (integer)llFloor(batteryCharge/basicCharge*100);
    if (newDisplayLevel != displayLevel) {
        displayLevel = newDisplayLevel;
        sendJSONinteger("batteryCharge", displayLevel, "");
    }
}

default
{
    state_entry()
    {
        basicCharge = 24 * 60 * 60; // 24 hours worth of seconds
        // discharge rates contains fraction of basic charge that gets used every second
        dischargeRates = [0.0]; // Off
        dischargeRates = dischargeRates + [1.0]; // Light = 24 hours
        dischargeRates = dischargeRates + [2.0]; // Medium 2x rate = 12 hours
        dischargeRates = dischargeRates + [3.0]; // Heavy 3x rate = 8 hours
        dischargeRates = dischargeRates + [4.0]; // Hardcore 4x rate = 6 hours
        theRLVstate = "Off";
        batteryCharge = basicCharge;
        dischargeRate = 1.0;
        timerInterval = 300.0;
        llSetTimerEvent(timerInterval);
        sayDebug("initialized");
    }

    link_message( integer sender_num, integer num, string json, key id ){
        string value = llJsonGetValue(json, ["batteryCharge"]);
        if (value != JSON_INVALID) {
            return;
        }
        sayDebug("link_message "+json);
        float chargeUsed = 0;
        
        // One-time discharges for events. 
        // When something gets set, discharge the battery a little.
        chargeUsed = updateValue(json, "prisonerMood", chargeUsed, 600);
        chargeUsed = updateValue(json, "zapLevels", chargeUsed, 600);
        chargeUsed = updateValue(json, "prisonerThreat", chargeUsed, 600);
        chargeUsed = updateValue(json, "prisonerClass", chargeUsed, 1200);
        chargeUsed = updateValue(json, "prisonerCrime", chargeUsed, 1200);
        chargeUsed = updateValue(json, "prisonerLockLevel", chargeUsed, 1200);
        chargeUsed = updateValue(json, "Speech", chargeUsed, 600);
        chargeUsed = updateValue(json, "Info", chargeUsed, 600);
        chargeUsed = updateValue(json, "DisplayTemp", chargeUsed, 600);
        
        value = getJSONstring(json, "zapPrisoner", "");
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
        if (chargeUsed) dischargeBattery("chargeUsed", chargeUsed);

        // receive some basic settings
        prisonerMood = getJSONstring(json, "prisonerMood", prisonerMood);
        prisonerLockLevel = getJSONstring(json, "prisonerLockLevel", prisonerLockLevel);
        string speechCommand = getJSONstring(json, "Speech", "");
        if (speechCommand == "RenamerOFF") renamerActive = 0;
        if (speechCommand == "RenamerON")  renamerActive = 1;
        if (speechCommand == "BadWordsOFF") badWordsActive = 0;
        if (speechCommand == "BadWordsON") badWordsActive = 1;
        if (speechCommand == "GagOFF") gagActive = 0;
        if (speechCommand == "GagON") gagActive = 1;
        if (speechCommand == "DisplayTokOFF") DisplayTokActive = 0;
        if (speechCommand == "DisplayTokON") DisplayTokActive = 1;

        if (prisonerLockLevel == "Off") {
            renamerActive = 0;
            badWordsActive = 0;
            gagActive = 0; 
            DisplayTokActive = 0;
        }
        
        // Current discharge rate depending on things that are on.
        integer newDischargeRate = 0;
        // theRLVstate results in numbers 0,1,2,3,4
        newDischargeRate = newDischargeRate + llList2Integer(dischargeRates, llListFindList(LockLevels, [prisonerLockLevel]));
        newDischargeRate = newDischargeRate + renamerActive;
        newDischargeRate = newDischargeRate + badWordsActive;
        newDischargeRate = newDischargeRate + gagActive;
        newDischargeRate = newDischargeRate + DisplayTokActive;
        
        if (newDischargeRate != dischargeRate) {
            sayDebug("link_message dischargeRate:"+(string)dischargeRate);
            dischargeRate = newDischargeRate;
            if (dischargeRate) dischargeBattery("dischargeRate", dischargeRate);
        }
        

    }

    timer() {
        dischargeBattery("timer", timerInterval * dischargeRate);
    }
}
