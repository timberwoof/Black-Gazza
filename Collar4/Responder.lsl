// Responder.lsl
// Script for Black Gazza Collar 4
// Timberwoof Lupindo, February 2020
// version: 2020-04-11

integer responderChannel;
integer responderListen;
string lockLevel;

integer OPTION_DEBUG = 1;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Responder:"+message);
    }
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

integer uuidToInteger(key uuid)
// primitive hash of uuid parts
{
    // UUID looks like 284ba63f-378b-4be6-84d9-10db6ae48b8d
    string hexdigits = "abcdef";
    list uuidparts = llParseString2List(uuid,["-"],[]);
    // last one is too big; split it into 2 6-digit numbers
    string last = llList2String(uuidparts,4);
    string last1 = llGetSubString(last,0,5);
    string last2 = llGetSubString(last,6,12);
    list lasts = [last1, last2];
    uuidparts = llListReplaceList(uuidparts, lasts, 4, 4);
    
    integer sum = 0;
    integer i = 0;
    // take each uuid part
    for (i=0; i < llGetListLength(uuidparts); i++) {
        string uuidPart = llList2String(uuidparts,i);
        integer j;
        // look at each digit
        for (j=0; j < llStringLength(uuidPart); j++) {
            string c = llGetSubString(uuidPart, j, j);
            string k = (string)llSubStringIndex(hexdigits, c);
            // if it's in abcdef
            if ((integer)k > -1) {
                // substitute in the digit 123456
                uuidPart = llDeleteSubString(uuidPart, j, j);
                uuidPart = llInsertString(uuidPart, j, k);
            }
        }
        sum = sum - (integer)uuidPart;
    }
    return sum;
}

string Role = "Inmate";
string assetNumber;
string prisonerMood;
string prisonerClass;
string prisonerCrime;
string prisonerThreat;
string prisonerLockLevel;
string prisonerZapLevels;
integer batteryCharge;

list symbols = ["Role", "assetNumber", "Mood", "Class", "Crime", "Threat", "LockLevel", "BatteryCharge", "ZapLevels"];
list values;


default
{
    state_entry()
    {
        responderChannel = uuidToInteger(llGetOwner());
        responderListen = llListen(responderChannel,"", "", "");
    }
    
    link_message( integer sender_num, integer num, string json, key id )
    {
    // We listen in on link status messages and pick the ones we're interested in
        sayDebug("link_message json "+json);
        assetNumber = getJSONstring(json, "assetNumber", assetNumber);
        prisonerCrime = getJSONstring(json, "prisonerCrime", prisonerCrime);
        prisonerClass = getJSONstring(json, "prisonerClass", prisonerClass);
        prisonerThreat = getJSONstring(json, "prisonerThreat", prisonerThreat);
        prisonerMood = getJSONstring(json, "prisonerMood", prisonerMood);
        prisonerLockLevel = getJSONstring(json, "prisonerLockLevel", prisonerLockLevel);
        batteryCharge = getJSONinteger(json, "batteryCharge", batteryCharge);
        prisonerZapLevels = getJSONstring(json, "ZapLevels", prisonerZapLevels);
        values = [Role, assetNumber, prisonerMood, prisonerClass, prisonerCrime, prisonerThreat, prisonerLockLevel, batteryCharge, prisonerZapLevels];
    } 

    listen(integer channel, string name, key id, string json)
    {
        // {"request":["Mood","Class","LockLevel"]}
        sayDebug("Responder listen("+name+","+json+")");  
        string value = getJSONstring(json, "request", "");  // ["Mood","Class","LockLevel"]
        sayDebug("listen value: "+value);
        list requests = llJson2List(value);
        integer i;
        list responses;
        for (i = 0; i < llGetListLength(requests); i++) {
            string symbolkey = llList2String(requests, i);
            integer index = llListFindList(symbols, [symbolkey]);
            string value = "Error";
            if (index >= 0) {
                value = llList2String(values, index);
            }
            sayDebug(symbolkey+" -> "+value);
            string onejson = llList2Json(JSON_OBJECT, [symbolkey, value]); // {"Mood":"OOC"}
            responses = responses + [onejson];
        }        
        string jsonlist = llList2Json(JSON_ARRAY, responses); // [{"Mood":"OOC"},{"Class":"blue"},{"LockLevel":"Off"}]
        sayDebug("jsonlist:"+jsonlist);
        string jsonresponse = llList2Json(JSON_OBJECT, ["response", jsonlist]); // {"response":[{"Mood":"OOC"},{"Class":"blue"},{"LockLevel":"Off"}]}
        sayDebug("jsonresponse:"+jsonresponse);
        llWhisper(responderChannel, jsonresponse);
    }
}
