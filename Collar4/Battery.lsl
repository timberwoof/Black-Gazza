// Battery.lsl
// Battery script for Black Gazza Collar 4
// Timberwoof Lupindo, June 2019
// version: 2021-03-07

// Receives events from other sytsems and discgarhes the battery accordingly. 
// Receives recharge message from the charger and charges the battery accordingly. 
// Sends battery state commands to Display. 

integer OPTION_DEBUG = FALSE;

integer basicCharge; // battery capacity in seconds
integer batteryCharge; // seconds left
integer batteryPercent;
list rlvStates; // names of rlv states
list dischargeRates;  // battery seconds per second
integer dischargeRate; 
string theRLVstate;
integer timerInterval;

string mood = "OOC";
string lockLevel = "Off";
list LockLevels = ["Off", "Light", "Medium", "Heavy", "Hardcore"];
integer renamerActive = FALSE;
integer badWordsActive = FALSE;
integer gagActive = FALSE;
integer DisplayTokActive = FALSE;
string batteryActive = "OFF";

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Battery: "+message);
    }
}

sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
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

integer updateValue(string json, string jsonKey, integer now, integer replace) {
    string value = llJsonGetValue(json, [jsonKey]);
    if (value != JSON_INVALID) {
        return replace;
    } else {
        return now;
    }
}

dischargeBattery(string why, integer seconds)
{
    batteryCharge = batteryCharge - seconds;
    
    // limit battery charge to basic charge
    if (batteryCharge > basicCharge) {
        batteryCharge = basicCharge; 
    }
    
    // limit battery discharge to 0;
    // automatically rehcarge if battery is off
    if (batteryCharge <= 0) {
        if (batteryActive == "ON") {
            batteryCharge = 0;
        } else {
            batteryCharge = basicCharge;           
        }
    }
    
    // broadcast the new battery level 0-100%
    integer newbatteryPercent = (integer)llFloor(batteryCharge * 100.0 / basicCharge);
    if (newbatteryPercent != batteryPercent) {
        sayDebug("dischargeBattery newbatteryPercent:" + (string)newbatteryPercent);
        batteryPercent = newbatteryPercent;
        sendJSONinteger("batteryCharge", batteryCharge, "");
        sendJSONinteger("batteryPercent", batteryPercent, "");
        sendJSON("batteryGraph", batteryGraph(batteryPercent), "");
    }
    sayDebug("dischargeBattery(" + why + "," + (string)seconds + ") resulted in batteryCharge:" + (string)batteryCharge);
}

string batteryGraph(integer batteryCharge) {
    // batteryCharge 0-100
    integer iBattery = batteryCharge / 10;
    integer i;
    string graph = "";
    for (i=0; i<iBattery; i++) {
        graph = graph + "◼";
    }
    for (; i<10; i++) {
        graph = graph + "◻";
    }
    return graph;
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
        basicCharge = 24 * 60 * 60; // 24 hours worth of seconds
        // discharge rates contains fraction of basic charge that gets used every second
        dischargeRates = [0]; // Off
        dischargeRates = dischargeRates + [1]; // Light = 24 hours
        dischargeRates = dischargeRates + [2]; // Medium 2x rate = 12 hours
        dischargeRates = dischargeRates + [3]; // Heavy 3x rate = 8 hours
        dischargeRates = dischargeRates + [4]; // Hardcore 4x rate = 6 hours
        theRLVstate = "Off";
        batteryCharge = basicCharge;
        dischargeRate = 1;
        timerInterval = 300;
        llSetTimerEvent(timerInterval);
        sayDebug("state_entry basicCharge:" + (string)basicCharge + " batteryCharge:" + (string)batteryCharge);
        sayDebug("state_entry done");
    }

    link_message(integer sender_num, integer num, string json, key id){
        sayDebug("link_message (" + json + ")");
        
        // Message from Responder for charging
        string value = llJsonGetValue(json, ["CHARGE"]); // range 0.0 to 1.0
        if (value != JSON_INVALID) {
            sayDebug("json:"+json+"  batteryCharge now:" + (string)batteryCharge);
            dischargeBattery("charging", llFloor((float)value * basicCharge * -1.0));
            sayDebug("link_message new batteryCharge:" + (string)batteryCharge + "; returning");
            return;
        }
        
        // message from Menu to update Battery setting
        value = llJsonGetValue(json, ["Battery"]);
        if (value != JSON_INVALID) {
            batteryActive = llToUpper(value);
            sayDebug("link_message new batteryActive:" + batteryActive + "; returning");
            return;
        }
                
        // One-time discharges for events. 
        // When something gets set, discharge the battery a little.
        integer chargeUsed = FALSE;
        chargeUsed = updateValue(json, "mood", chargeUsed, 600);
        chargeUsed = updateValue(json, "zapLevels", chargeUsed, 600);
        chargeUsed = updateValue(json, "threat", chargeUsed, 600);
        chargeUsed = updateValue(json, "class", chargeUsed, 1200);
        chargeUsed = updateValue(json, "crime", chargeUsed, 1200);
        chargeUsed = updateValue(json, "lockLevel", chargeUsed, 1200);
        chargeUsed = updateValue(json, "Speech", chargeUsed, 600);
        chargeUsed = updateValue(json, "Info", chargeUsed, 600);
        chargeUsed = updateValue(json, "DisplayTemp", chargeUsed, 600);
        if (chargeUsed) {
            dischargeBattery("menu", chargeUsed);
            return;
        }

        chargeUsed = getJSONinteger(json, "Discharge", FALSE);
        if (chargeUsed) {
            dischargeBattery("discharge", chargeUsed);
            return;
        }

        // receive some basic settings that change the rate of battery use
        mood = getJSONstring(json, "mood", mood);
        lockLevel = getJSONstring(json, "lockLevel", lockLevel);
        string speechCommand = getJSONstring(json, "Speech", "");
        if (speechCommand == "RenamerOFF") renamerActive = FALSE;
        if (speechCommand == "RenamerON")  renamerActive = TRUE;
        if (speechCommand == "BadWordsOFF") badWordsActive = FALSE;
        if (speechCommand == "BadWordsON") badWordsActive = TRUE;
        if (speechCommand == "GagOFF") gagActive = FALSE;
        if (speechCommand == "GagON") gagActive = TRUE;
        if (speechCommand == "DisplayTokOFF") DisplayTokActive = FALSE;
        if (speechCommand == "DisplayTokON") DisplayTokActive = TRUE;
        if (lockLevel == "Off") {
            renamerActive = FALSE;
            badWordsActive = FALSE;
            gagActive = FALSE; 
            DisplayTokActive = FALSE;
        }
        
        // Current discharge rate depending on things that are on.
        integer newDischargeRate = 0;
        // theRLVstate results in numbers 0,1,2,3,4
        newDischargeRate = newDischargeRate + llList2Integer(dischargeRates, llListFindList(LockLevels, [lockLevel]));
        newDischargeRate = newDischargeRate + renamerActive;
        newDischargeRate = newDischargeRate + badWordsActive;
        newDischargeRate = newDischargeRate + gagActive;
        newDischargeRate = newDischargeRate + DisplayTokActive;
        
        // if we adjusted the discharge rate, then update it and do a battery discharge
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
