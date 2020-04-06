// Display.lsl
// Display script for Black Gazza Stocks 4
// Timberwoof Lupindo
// June 2019
// version: 2020-03-14 JSON

// This script handles all display elements of Black Gazza Collar 4.
// • alphanumeric display
// • blinky lights
// • battery displaydi
// • floaty text

integer OPTION_DEBUG = 0;

vector BLACK = <0,0,0>;
vector DARK_GRAY = <0.2, 0.2, 0.2>;
vector GRAY = <0.5, 0.5, 0.5>;
vector LIGHT_GRAY = <0.7, 0.7, 0.7>;
vector DARK_BLUE = <0.0, 0.0, 0.2>;
vector BLUE = <0.0, 0.0, 1.0>;
vector BLUE2 = <0.32, 0.32, .84>;
vector LIGHT_BLUE = <0.1, 0.5, 1.0>;
vector MAGENTA = <1.0, 0.0, 1.0>;
vector MAGENTA2 = <1, .2, .66>;
vector CYAN = <0.0, 1.0, 1.0>;
vector CYAN2 = <0.0, 1.0, 1.0>;
vector WHITE = <1.0, 1.0, 1.0>;
vector RED = <1.0, 0.32, 0.32>;
vector RED2 = <.87, 0.12, 0.12>;
vector REDORANGE = <1.0, 0.25, 0.0>;
vector ORANGE = <1.0, 0.5, 0.0>;
vector ORANGE2 = <1, 0.66, 0.2>;
vector YELLOW = <1.0, 1.0, 0.0>;
vector GREEN = <0.0, 1.0, 0.0>;
vector GREEN2 = <0.32, 1, 0.32>;
vector PURPLE = <0.7, 0.1, 1.0>;

list lockLevels = ["Safeword", "Off", "Light", "Medium", "Heavy", "Hardcore"];
list lockColors = [GREEN, BLACK, GREEN, YELLOW, ORANGE, RED];
list threatLevels = ["None", "Moderate", "Dangerous", "Extreme"];
list threatColors = [GREEN, YELLOW, ORANGE, RED];
list classColors = [WHITE, MAGENTA, RED, ORANGE, GREEN, CYAN, WHITE];
list classFrameColors = [WHITE, MAGENTA2, RED2, ORANGE2, GREEN2, BLUE2, DARK_GRAY];

integer LinkFrame = 1;
integer FaceFrame = 0;
integer FacePadding = 1;

integer LinkPilotLight = 0;
integer LinkBlinky1 = 17;
integer LinkBlinky2 = 17;
integer LinkBlinky3 = 17;
integer LinkBlinky4 = 17;
integer FaceBlinky1 = ALL_SIDES;
integer FaceBlinky2 = ALL_SIDES;
integer FaceBlinky3 = ALL_SIDES;
integer FaceBlinky4 = ALL_SIDES;

integer LinkDisplayFrame = 26;
integer FaceDisplayFrame = 0;
integer FaceAlphanum = 1;
list LinksAlphanum = [];

integer linkTitler = 0;

// BG_CollarV4_PowerDisplay_PNG
string batteryLevel;
key batteryIconID = "ef369716-ead2-b691-8f5c-8253f79e690a";
integer batteryIconLink = 0;
integer batteryIconFace = 0;
float batteryIconHScale = 0.2;
float batteryIconVScale = 0.75;
float batteryIconRotation = 90.0;
float batteryIconHoffset = -0.4;
vector batteryIconColor = <0.0, 0.5, 1.0>;
vector batteryLightColor = <1.0, 0.0, 0.0>;
float batteryLightGlow = 0.1;

string scrollText;
integer scrollPos;
integer scrollLimit;
string fontID = "fc55ee0b-62b5-667c-043d-46d822249ee0";

string prisonerMood;
list moodNames;
list moodColors;
vector moodColor;

string prisonerClass;
string prisonerClassLong;
list classNames;
list classNamesLong;
vector prisonerClassColor;
vector frameClassColor;
string prisonerLockLevel;

string prisonerCrime;
string prisonerThreat;

integer responderChannel;
integer responderListen;

string assetNumber;
string zapLevelsJSON;

integer TIMER_BADWORDS = 0;
integer TIMER_SCROLL = 0;
integer TIMER_REDISPLAY = 0;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Display:"+message);
    }
}

integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    integer result = -1;
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) {
            result = i; // Found it! Exit loop early with result
        }
    sayDebug("getLinkWithName("+name+") returns "+(string)result);
    return result; // No prim with that name, return -1.
}

displayTitler() {
    integer moodIndex = llListFindList(moodNames, [prisonerMood]);
    moodColor = llList2Vector(moodColors, moodIndex);
    integer classIndex = llListFindList(classNames, [prisonerClass]);
    string description = "Class " + prisonerClass + ": " + llList2String(classNamesLong, classIndex);
    string title = assetNumber + "\n" + description + "\nCrime: " + prisonerCrime + "\nThreat: " + prisonerThreat + "\nMood: " + prisonerMood ;
    llSetLinkPrimitiveParamsFast(linkTitler, [PRIM_TEXT, title, moodColor, 1.0]);
}

displayText(string text){
// Display a string of 12 characters on the collar display. 
// If you supply less than 12 characters, the last ones don't get reset. 
// Anything after 12 characters gets truncated. 
    sayDebug("displaytext("+text+")");

    // The text map is in this jumbled order because the bitmap maps weirdly. 
    string textMap = 
        "ZabcdUVWXY" + // 4 U-Za-d
        "jklmnefghi" + // 5 e-n
        "tuvwxopqrs" + // 6 o-x
        ":;-#*yz .," + // 7 yz...
        "5678901234" + // 1 0-9
        "FGHIJABCDE" + // 2 A-J
        "PQRSTKLMNO" ; // 3 K-T
    integer i;
    integer j;
    string letter;
    for (i = 0; i < 12; i++){
        letter =  llGetSubString(text,i,i);     // get a letter out of the text
        j = llSubStringIndex(textMap,letter);   // find it in the bitmap
        integer ix = (j % 10);                  // find the x coordinates
        float x = ix * 0.1 + .05;

        integer iy = 7 - j / 10;                // find the y coordinates
        float y = iy * 0.1429;

        integer linkNumber = llList2Integer(LinksAlphanum, i); // shift the appropriate textmap
        llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_TEXTURE, 0, fontID, <0.1, 0.15, 0.0>, <x, y, 0.0>, 0.0]);
    }
}

setTextColor(vector prisonerClassColor){
    sayDebug("setTextColor "+(string)prisonerClassColor);
    integer i;
    for (i = 0; i < 12; i++){
        integer linkNumber = llList2Integer(LinksAlphanum, i); 
        llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_COLOR, 0, prisonerClassColor, 0.5]);
        llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_GLOW, 0, 0.3]);
    }
}

displayCentered(string text){
// display a string of less than 12 characters on the alphanumeric display, more or less centered
    sayDebug("displayCentered("+text+")");
    integer pad = (12 - llStringLength(text)) / 2; 
    displayText(llInsertString("            ", pad, text));
}

displayScroll(string text){
// display a string of more than 12 characters in a lovely scrolling manner. 
// needs some support from timer 
    sayDebug("displayScroll("+text+")");
    string displayText = "            "; // 12 spaces
    scrollText = llToUpper(text) + " " + llToUpper(text) + " " ;
    scrollPos = 0;
    scrollLimit = llStringLength(text);
    llSetTimerEvent(1);
}

displayBattery(integer percent)
// based on the percentage, display the correct icon and color
{   
    sayDebug("displayBattery("+(string)percent+")");
    // The battery icon has 5 states. Horizontal Offsets can be
    // -0.4 full charge 100% - 88%
    // -0.2 3/4 charge   87% - 75% - 62%
    //  0.0 1/2 charge   61% - 50% - 38%
    //  0.2 1/4 charge   37% - 25% - 12%
    //  0.4 0/4 charge   12% - 0%
    //  Between 5% and 1% it shows red.
    //  At 0% it turns black. 
    
    if (percent > 87) batteryIconHoffset = -0.4; // full
    else if (percent > 61) batteryIconHoffset = -0.2; // 3/4
    else if (percent > 37) batteryIconHoffset =  0.0; // 1/2
    else if (percent > 12) batteryIconHoffset =  0.2; // 1/4
    else batteryIconHoffset =  0.4; // empty
    
    if (percent > 12) {
        batteryIconColor = <0.0, 0.5, 1.0>; // blue-cyan full, 3/4, 1/2, 1/4
        batteryLightColor = <0.0, 1.0, 0.0>;
        batteryLightGlow = 0.1;
    }
    else if (percent > 8) {
        batteryIconColor = <1.0, 0.5, 0>; // orange empty
        batteryLightColor = <1.0, 0.5, 0>;
        batteryLightGlow = 0.2;
    }
    else if (percent > 4) {
        batteryIconColor = <1.0, 0.0, 0.0>; // red empty
        batteryLightColor = <1.0, 0.0, 0.0>;
        batteryLightGlow = 0.4;
    }
    else {
        batteryIconColor = <0.0, 0.0, 0.0>; // black empty
        batteryLightColor = <0.0, 0.0, 0.0>;
        batteryLightGlow = 0.0;
    }
    llSetLinkColor(LinkPilotLight, batteryLightColor, ALL_SIDES);
    llSetLinkPrimitiveParamsFast(LinkPilotLight, [PRIM_GLOW, ALL_SIDES, batteryLightGlow]);
    llSetLinkPrimitiveParamsFast(LinkPilotLight, [PRIM_GLOW, ALL_SIDES, 0.3]);
    llSetLinkPrimitiveParamsFast(batteryIconLink,[PRIM_TEXTURE, batteryIconFace, batteryIconID, <0.2, 0.75, 0.0>, <batteryIconHoffset, 0.0, 0.0>, 1.5708]);
    llSetLinkPrimitiveParamsFast(batteryIconLink,[PRIM_COLOR, batteryIconFace, batteryIconColor, 1.0]);
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

// get a value from color stored in the blinky and send it to the link
//*** string blinkyFaceColorToMeaning(integer face, list colors, list names, string jsonTag){
    //*** list colorList = llGetLinkPrimitiveParams(LinkBlinky, [PRIM_COLOR, face]);
    //*** vector prisonerThreatColor = llList2Vector(colorList,0);
    //*** integer index = llListFindList(colors, [prisonerThreatColor]);
    //*** string stateName = llList2String(names, index); 
    //*** llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonTag, stateName]), "");
    //*** return stateName;
//*** }

default
{
    state_entry()
    {
        sayDebug("state_entry");
        
        // set up lists and shit
        moodNames = ["OOC","Submissive","Versatile","Dominant","Nonsexual","Story", "DnD"];
        moodColors = [LIGHT_GRAY, GREEN, YELLOW, ORANGE, CYAN, PURPLE, GRAY];
        prisonerMood = "OOC";
        
        classNames = ["white","pink","red","orange","green","blue","black"];
        classNamesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental","Unknown"];
        classColors = [WHITE, MAGENTA, RED, ORANGE, GREEN, CYAN, WHITE];
        prisonerClass = "white";
        prisonerClassColor = WHITE;
        setTextColor(CYAN);
        
        // LinksAlphanum
        integer i;
        for (i = 0; i < 12; i++) {
            string linkname = "D"+(string)i;
            integer link = getLinkWithName(linkname);
            sayDebug("init linking "+linkname+" to "+(string)link);
            LinksAlphanum = LinksAlphanum + [link];
            }        
        linkTitler = getLinkWithName("Titler");
        LinkPilotLight = getLinkWithName("PilotLight");
        LinkBlinky1 = getLinkWithName("blinky1");
        LinkBlinky2 = getLinkWithName("blinky2");
        LinkBlinky3 = getLinkWithName("blinky3");
        LinkBlinky4 = getLinkWithName("blinky4");
        LinkDisplayFrame = getLinkWithName("DisplayFrame");
        batteryIconLink = getLinkWithName("powerDisplay");
        //linkTitler = getLinkWithName("powerHoseNozzle");
        //linkTitler = getLinkWithName("leashPoint");
        
        llSetLinkAlpha(linkTitler, 0, ALL_SIDES);

        // Initialize the world
        batteryLevel = "Unknown"; 
        prisonerMood = "Unknown";//blinkyFaceColorToMeaning(FaceDisplayFrame, moodColors, moodNames, "prisonerMood");
        prisonerClass = "Unknown";//blinkyFaceColorToMeaning(FaceBlinky3, classColors, classNames, "prisonerClass");
        prisonerThreat = "Unknown";//blinkyFaceColorToMeaning(FaceBlinky4, threatColors, threatLevels, "prisonerThreat");
        prisonerCrime = "Unknown";
        displayTitler();
                
        // set up the responder
        responderChannel = uuidToInteger(llGetOwner());
        responderListen = llListen(responderChannel,"", "", "");
        
        if (llGetAttached() > 0) {
            llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
            }
    }
    
    attach(key avatar) {
        llRequestPermissions(avatar, PERMISSION_TRIGGER_ANIMATION);
        }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStartAnimation("binder4a");
            llSetTimerEvent(5);
        }
    }

    link_message( integer sender_num, integer num, string json, key id ){ 
        sayDebug("link_message "+json);

        // IC/OOC Mood sets frame color 
        string value = llJsonGetValue(json, ["prisonerMood"]);
        if (value != JSON_INVALID) {
            prisonerMood = value;
            integer moodi = llListFindList(moodNames, [prisonerMood]);
            vector moodColor = llList2Vector(moodColors, moodi);
            llSetLinkPrimitiveParamsFast(LinkDisplayFrame,[PRIM_COLOR, FaceDisplayFrame, moodColor, 1.0]);
            llSetLinkPrimitiveParamsFast(LinkDisplayFrame, [PRIM_GLOW, FaceDisplayFrame, 0.3]);
            displayTitler();
        }

        // Prisoner Class sets text color and blinky 3
        value = llJsonGetValue(json, ["prisonerClass"]);
        if (value != JSON_INVALID) {
            prisonerClass = value;
            sayDebug("link_message "+(string)num+" "+prisonerClass+"->prisonerClass");
            integer classi = llListFindList(classNames, [prisonerClass]);
            prisonerClassColor = llList2Vector(classColors, classi);
            frameClassColor = llList2Vector(classFrameColors, classi);
            prisonerClassLong = llList2String(classNamesLong, classi);
            setTextColor(prisonerClassColor);
            
            // set the blinky color
            llSetLinkPrimitiveParamsFast(LinkBlinky3,[PRIM_COLOR, FaceBlinky3, prisonerClassColor, 1.0]);
            
            // set the collar frame color
            llSetLinkPrimitiveParamsFast(LinkFrame,[PRIM_COLOR, FaceFrame, frameClassColor, 1.0]);
            displayTitler();
        }
        
        // Zap Level sets blinky 1
        value = llJsonGetValue(json, ["zapLevels"]);
        if (value != JSON_INVALID) {
            zapLevelsJSON = value;
            list zapLevels = llJson2List(zapLevelsJSON);
            sayDebug("link_message "+(string)num+" "+(string)zapLevels+"->message");
            sayDebug("zapLevels list:"+(string)zapLevels);
            vector lightcolor = BLACK;
            // color tells the highest allowed zap level
            if (llList2Integer(zapLevels,0)) lightcolor = YELLOW;
            if (llList2Integer(zapLevels,1)) lightcolor = ORANGE;
            if (llList2Integer(zapLevels,2)) lightcolor = RED;
            llSetLinkPrimitiveParamsFast(LinkBlinky1,[PRIM_COLOR, FaceBlinky1, lightcolor, 1.0]);            
        }
        
        // Lock level sets blinky 2
        value = llJsonGetValue(json, ["prisonerLockLevel"]);
        if (value != JSON_INVALID) {
            prisonerLockLevel = value;
            integer locki = llListFindList(lockLevels, [prisonerLockLevel]);
            vector lockcolor = llList2Vector(lockColors, locki);
            sayDebug("lock level message:"+prisonerLockLevel+" locki:"+(string)locki+" lockColors:"+(string)lockcolor);
            llSetLinkPrimitiveParamsFast(LinkBlinky2,[PRIM_COLOR, FaceBlinky2, lockcolor, 1.0]);
        }
        
        // Threat level sets blinky 4
        value = llJsonGetValue(json, ["prisonerThreat"]);
        if (value != JSON_INVALID) {
            prisonerThreat = value;
            integer threati = llListFindList(threatLevels, [prisonerThreat]);
            vector threatcolor = llList2Vector(threatColors, threati);
            sayDebug("threat level json:"+json+" threati:"+(string)threati+" threatcolor:"+(string)threatcolor);
            llSetLinkPrimitiveParamsFast(LinkBlinky4,[PRIM_COLOR, FaceBlinky4, threatcolor, 1.0]);
            displayTitler();
        }
        
        // Battery Level Report
        value = llJsonGetValue(json, ["batteryLevel"]);
        if (value != JSON_INVALID) {
            batteryLevel = value;
            sayDebug("batteryLevel "+batteryLevel);
            displayBattery((integer)batteryLevel);
        }
        
        // Prisoner Crime
        value = llJsonGetValue(json, ["prisonerCrime"]);
        if (value != JSON_INVALID) {
            prisonerCrime = value;
            displayTitler();
        }

        // set and display asset number
        value = llJsonGetValue(json, ["assetNumber"]);
        if (value != JSON_INVALID) {
            assetNumber = value;
            sayDebug("set and display assetNumber \""+assetNumber+"\"");
            string ownerName = llGetDisplayName(llGetOwner());
            list namesList = llParseString2List(ownerName, [" "], [""]);
            string firstName = llList2String(namesList, 0);
            llSetObjectName(assetNumber+" ("+firstName+")");
            displayCentered(assetNumber);
            displayTitler();
        }
        
        // display a message
        value = llJsonGetValue(json, ["Display"]);
        if (value != JSON_INVALID) {
            sayDebug("Display "+value);
            displayCentered(value);
        }
        
        // temporarily display a message
        value = llJsonGetValue(json, ["DisplayTemp"]);
        if (value != JSON_INVALID) {
            sayDebug("DisplayTemp "+value);
            displayCentered(value);
            TIMER_REDISPLAY = 1;
            llSetTimerEvent(3);
        }
        
        // blink battery light for bad words
        value = llJsonGetValue(json, ["badWordCount"]);
        if (value != JSON_INVALID) {
            sayDebug("badWordCount "+value);
            TIMER_BADWORDS = (integer)value;
            llSetTimerEvent(1);
            }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (message == "Request Status") {
            string statusJsonList = llList2Json(JSON_OBJECT, [
                "assetNumber", assetNumber, 
                "prisonerCrime", prisonerCrime, 
                "prisonerClass", prisonerClass, 
                "prisonerThreat", prisonerThreat,
                "prisonerMood", prisonerMood, 
                "batteryLevel", batteryLevel, 
                "prisonerLockLevel", prisonerLockLevel, 
                "zapLevels", zapLevelsJSON]);
            sayDebug("listen("+name+","+message+") responds with " + statusJsonList);
            llSay(responderChannel, statusJsonList);
        }
    }

    timer() {
        sayDebug("timer()");
            if (TIMER_REDISPLAY > 0) {
                if (assetNumber == "") {
                    displayCentered("P-00000");
                } else {
                    sayDebug("set and display assetNumber \""+assetNumber+"\"");
                    displayCentered(assetNumber);
                }
                llSetTimerEvent(0);  
                TIMER_REDISPLAY = 0;
            }
            
            // Blink the battery light off and red for every bad word spokem.
            // Timer shoud be on one-second interval
            if (TIMER_BADWORDS > 0) {
                sayDebug("timer TIMER_BADWORDS:"+(string)TIMER_BADWORDS);
                llSetLinkColor(LinkPilotLight, RED, 0);
                llSetLinkPrimitiveParamsFast(LinkDisplayFrame,[PRIM_COLOR, FaceDisplayFrame, RED, 1.0]);
                TIMER_BADWORDS = - TIMER_BADWORDS;
            } else if (TIMER_BADWORDS < 0) {
                sayDebug("timer TIMER_BADWORDS:"+(string)TIMER_BADWORDS);
                displayBattery((integer)batteryLevel);
                llSetLinkPrimitiveParamsFast(LinkDisplayFrame,[PRIM_COLOR, FaceDisplayFrame, BLACK, 1.0]);
                TIMER_BADWORDS = -TIMER_BADWORDS - 1;
                if (TIMER_BADWORDS == 0) {
                    llSetLinkPrimitiveParamsFast(LinkDisplayFrame,[PRIM_COLOR, FaceDisplayFrame, moodColor, 1.0]);
                    llSetTimerEvent(5);  
                }
            }
            
            else {
                llStartAnimation("binder4a");
                }
        }
    }
