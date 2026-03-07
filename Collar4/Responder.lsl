// Responder.lsl
// Script for Black Gazza Collar 4
// Timberwoof Lupindo, February 2020
// version: 2023-04-15

integer responderChannel;
integer responderListen;

integer OPTION_DEBUG = FALSE;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Responder: "+message);
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

string role = "inmate";
string assetNumber;
string mood;
string class;
string crime;
string threat;
string lockLevel;
string zaplevels;
integer batteryPercent;
string battery;

// Symbols according to Responder Protocol.
list symbols = ["role", "assetNumber", "mood", "class", "crime", "threat", "lockLevel", "Battery", "batteryPercent", "ZapLevels"];
list values;


default
{
    state_entry()
    {
        responderChannel = uuidToInteger(llGetOwner());
        responderListen = llListen(responderChannel,"", "", "");
    }

    link_message(integer sender_num, integer num, string json, key id)
    {
    // We listen in on link status messages and pick the ones we're interested in
        sayDebug("link_message json "+json);
        assetNumber = getJSONstring(json, "AssetNumber", assetNumber);
        crime = getJSONstring(json, "Crime", crime);
        class = getJSONstring(json, "Class", class);
        threat = getJSONstring(json, "Threat", threat);
        mood = getJSONstring(json, "Mood", mood);
        lockLevel = getJSONstring(json, "LockLevel", lockLevel);
        battery = getJSONstring(json, "Battery", battery);
        batteryPercent = getJSONinteger(json, "BatteryPercent", batteryPercent);
        zaplevels = getJSONstring(json, "ZapLevels", zaplevels);
        values = [role, assetNumber, mood, class, crime, threat, lockLevel, batteryPercent, zaplevels];
    }

    listen(integer channel, string name, key id, string json)
    {
        sayDebug("listen channel:"+(string)channel+" name:"+name+" json:"+json);
        string value = getJSONstring(json, "request", "");
        // {"request":["Mood","Class","LockLevel"]}
        if ((battery == "OFF") || ((batteryPercent > 4) && (value != ""))) {
            sayDebug("listen request value: "+value);
            list requests = llJson2List(value);
            integer i;
            list responses = ["key", llGetOwner()];
            for (i = 0; i < llGetListLength(requests); i++) {
                string symbolkey = llList2String(requests, i);
                integer index = llListFindList(symbols, [symbolkey]);
                string value = "Error";
                if (index >= 0) {
                    value = llList2String(values, index);
                }
                sayDebug(symbolkey+" -> "+value);
                responses = responses + [symbolkey, value];
            }
            string jsonlist = llList2Json(JSON_OBJECT, responses); // [{"Mood":"OOC"},{"Class":"blue"},{"LockLevel":"Off"}]
            sayDebug("jsonlist:"+jsonlist);
            string jsonresponse = llList2Json(JSON_OBJECT, ["response", jsonlist]); // {"response":[{"Mood":"OOC"},{"Class":"blue"},{"LockLevel":"Off"}]}
            sayDebug("jsonresponse:"+jsonresponse);
            llWhisper(responderChannel, jsonresponse);
        } else {
            sayDebug("batteryPercent < 4 or value = ''");
        }

        if (name == "L-CON Battery Charger") {
            sayDebug("listen "+name+" "+json);
            llMessageLinked(LINK_THIS, 0, json, llGetOwner());
        }
    }
}
