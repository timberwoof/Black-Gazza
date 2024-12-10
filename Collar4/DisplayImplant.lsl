// Display.lsl
// Display script for Black Gazza Collar 4 Implant
// Timberwoof Lupindo
// June 2019
string version = "2023-04-15";

// This script handles all display elements of Black Gazza Collar 4.
// • alphanumeric display
// • blinky lights
// • battery display
// • floaty text

// This script requires some prims to have specific names:
// Titler
// BG_CollarV4_LightsMesh
// powerDisplay
// powerHoseNozzle
// leashPoint

integer OPTION_DEBUG = FALSE;

// **** general use colors
vector BLACK = <0,0,0>;
vector DARK_GRAY = <0.2, 0.2, 0.2>;
vector GRAY = <0.5, 0.5, 0.5>;
vector LIGHT_GRAY = <0.7, 0.7, 0.7>;
vector WHITE = <1.0, 1.0, 1.0>;
vector DARK_RED = <0.5, 0.0, 0.0>;
vector RED = <1.0, 0.0, 0.0>;
vector REDORANGE = <1.0, 0.25, 0.0>;
vector DARK_ORANGE = <0.5, 0.25, 0.0>;
vector ORANGE = <1.0, 0.5, 0.0>;
vector YELLOW = <1.0, 1.0, 0.0>;
vector DARK_GREEN = <0.0, 0.5, 0.0>;
vector GREEN = <0.0, 1.0, 0.0>;
vector DARK_BLUE = <0.0, 0.0, 0.5>;
vector BLUE = <0.0, 0.0, 1.0>;
vector DARK_MAGENTA = <0.5, 0.0, 0.5>;
vector MAGENTA = <1.0, 0.0, 1.0>;
vector DARK_CYAN = <0.0, 0.5, 0.5>;
vector CYAN = <0.0, 1.0, 1.0>;
vector PURPLE = <0.7, 0.1, 1.0>;

// **** links and faces
integer LinkFrame = 1;
integer FaceFrame = 0;
integer FacePadding = 1;

string smallLightID = "a27e5ac0-d949-0ca1-d9d4-042a85e9228a";
integer LinkBlinkyMood = 99; // set in setup
integer LinkBlinkyLock = 99; // set in setup
integer LinkBlinkyClass = 99; // set in setup
integer LinkBlinkyThreat = 99; // set in setup
integer FaceBlinkyMood = 0;
integer FaceBlinkyLock = 0;
integer FaceBlinkyClass = 0;
integer FaceBlinkyThreat = 0;

integer LinkClassIndicator = 99; 
integer FaceClassIndicator = 2; // gets class color
list LinksAlphanum = [];

integer linkTitler = 99;
float titlerActive = 1.0;
string buttonTitler = "Titler";

// BG_CollarV4_PowerDisplay_PNG
key batteryIconID = "ef369716-ead2-b691-8f5c-8253f79e690a";
integer batteryPercent;
float brightnessMultiplier = 1.0;
integer batteryIconLink = -1;
integer batteryIconFace = 0;
float batteryIconHScale = 0.2;
float batteryIconVScale = 0.75;
float batteryIconRotation = 90.0;
float batteryIconHoffset = -0.4;
vector batteryIconColor = <0.0, 0.5, 1.0>;
vector batteryLightColor = <1.0, 0.0, 0.0>;
float batteryLightGlow = 0.1;
integer pilotLightLink = 99;
integer pilotLightFace = 0;
string pilotLightID = "24a0a66a-5e83-c350-4d21-ad7b843b1c70";

string scrollText;
integer scrollPos;
integer scrollLimit;
string fontID = "fc55ee0b-62b5-667c-043d-46d822249ee0";

integer linkScrew1 = 99;
integer linkScrew2 = 99;
integer linkScrew3 = 99;
integer faceScrew = 0;
integer faceElectrode = 2;
vector sliceLoose = <0.25, 1, 0>;
vector sliceTight = <0, 0.72, 0>;
vector sliceRemoved = <0.25, 0.72, 0>;
integer screwSteps = 30;
string screwdriver = "6deca0b7-4bec-435e-74f4-80b463f933c4";
string philipsHead = "bf8e2fdd-2d90-6fca-42a2-21b41319983d";
string electrodeEnd = "57e278a5-b399-2cd7-8aef-61c06f02a365";
string roundhole = "30d8f00d-2066-08f3-66e2-bf367144a591";
integer screwState = 0;

// *** Collar State
// only lists that are needed in a lot of places are kept here.
// Other lists are dedined only where they are needed, in an effort to save space.
list moodNames = ["OOC", "Lockup", "Submissive", "Versatile", "Dominant", "Nonsexual", "Story", "DnD"];
list moodColors = [LIGHT_GRAY, WHITE, GREEN, YELLOW, ORANGE, CYAN, PURPLE, BLACK];

list threatLevels = ["None", "Moderate", "Dangerous", "Extreme"];
list threatColors = [GREEN, YELLOW, ORANGE, RED];

list classNames = ["white","pink","red","orange","green","blue","black"];
list classNamesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental","Unknown"];
list classColors = [WHITE, MAGENTA, RED, ORANGE, GREEN, BLUE, GRAY];
list classPaddingColors = [GRAY, DARK_MAGENTA, DARK_RED, DARK_ORANGE, DARK_GREEN, DARK_BLUE, DARK_GRAY];
        
string mood = "OOC";
vector moodColor;

string class;
string classLong;
vector classColor;
string lockLevel;
string crime;
string threat;

string assetNumber = "P-00000";
string unassignedAsset = "P-00000";

integer TIMER_BADWORDS = 0;
integer TIMER_SCROLL = 0;
integer TIMER_REDISPLAY = 0;

key avatar = NULL_KEY;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Display: "+message);
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
    
sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
}
    
integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    integer result = 99;
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) {
            result = i; // Found it! Exit loop early with result
        }
    sayDebug("getLinkWithName("+name+") returns "+(string)result);
    llSetLinkPrimitiveParamsFast(result, [PRIM_TEXT, "", BLACK, 0]);
    return result; // No prim with that name, return 99.
}

tone(string number) {
    string touchTone0 = "ccefe784-13b0-e59e-b0aa-c818197fdc03";
    string touchTone1 = "303afb6c-158f-aa6f-03fc-35bd42d8427d";
    string touchTone2 = "c4499d5e-85df-0e8e-0c6f-2c7e101517b5";
    string touchTone3 = "c3f88066-894e-7a3d-39b5-2619e8ae7e73";
    string touchTone4 = "10748aa2-753f-89ad-2802-984dc6e3d530";
    string touchTone5 = "2d9cf7a7-08e5-5687-6976-8d256b1dc84b";
    string touchTone6 = "97a896a8-0677-8281-f4e3-ba21c8f88b64";
    string touchTone7 = "01c5c969-daf1-6d7d-ade6-fd54dcb1aab5";
    string touchTone8 = "dafc5c77-8c81-02f1-6d36-9602d306dc0d";
    string touchTone9 = "d714bede-cfa3-7c33-3a7c-bcffd49534eb";
    list touchTones = [touchTone0, touchTone1, touchTone2, touchTone3, touchTone4,
        touchTone5, touchTone6, touchTone7, touchTone8, touchTone9];

    integer i;
    for (i = 0; i < llStringLength(number); i++) {
        integer digit = (integer)llGetSubString(number, i, i);
        llPlaySound(llList2String(touchTones, digit), 0.2);
        llSleep(.1);
    }
}

toneAlpha(string message) {
    message = llToLower(message);
    string characters = "0123456789abcdefghijklmnopqrstuvwxyz";
    string digits     = "012345678922233344455566677778889999";
    string digitized = "";
    integer i;
    for (i = 0; i < llStringLength(message); i++) {
        integer index = llSubStringIndex(characters, llGetSubString(message, i, i));
        if (index > -1) {
            digitized = digitized + llGetSubString(digits, index, index);
        }
    }
    sayDebug("toneAlpha("+message+") returns "+digitized);
    tone(digitized);
}

displayTitler() {
    sayDebug("displayTitler");
    integer moodIndex = llListFindList(moodNames, [mood]);
    moodColor = llList2Vector(moodColors, moodIndex);
    integer classIndex = llListFindList(classNames, [class]);
    string description = "Class " + class + ": " + llList2String(classNamesLong, classIndex);
    string title = assetNumber + "\n" + description + "\nCrime: " + crime + "\nThreat: " + threat + "\nMood: " + mood ;
    if (mood == "DND") {
        llSetLinkPrimitiveParamsFast(linkTitler, [PRIM_TEXT, "Please Do Not Distrub", WHITE, 1.0]);
    } else {
        llSetLinkPrimitiveParamsFast(linkTitler, [PRIM_TEXT, title, moodColor, titlerActive]);
    }
}

displayText(string text){
// Display a string of 12 characters on the collar display.
// If you supply less than 12 characters, the last ones don't get reset.
// Anything after 12 characters gets truncated.
    sayDebug("displaytext(\""+text+"\")");

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

setTextColor(vector textColor){
    sayDebug("setTextColor "+(string)textColor);
    integer i;
    for (i = 0; i < 12; i++){
        integer linkNumber = llList2Integer(LinksAlphanum, i);
        llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_COLOR, 0, textColor*brightnessMultiplier, 0.9]);
        llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_GLOW, 0, 0.1]);
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
        brightnessMultiplier = 1.0;
    }
    else if (percent > 8) {
        batteryIconColor = <1.0, 0.5, 0>; // orange empty
        batteryLightColor = <1.0, 0.5, 0>;
        batteryLightGlow = 0.2;
        brightnessMultiplier = 0.75;
    }
    else if (percent > 4) {
        batteryIconColor = <1.0, 0.0, 0.0>; // red empty
        batteryLightColor = <1.0, 0.0, 0.0>;
        batteryLightGlow = 0.4;
        brightnessMultiplier = 0.50;
    }
    else {
        batteryIconColor = <0.0, 0.0, 0.0>; // black empty
        batteryLightColor = <0.0, 0.0, 0.0>;
        batteryLightGlow = 0.0;
        brightnessMultiplier = 0.0;
    }
    sayDebug("displayBattery("+(string)percent+") brightnessMultiplier:" + (string)brightnessMultiplier);
    
    // Pilot light
    llSetLinkPrimitiveParamsFast(batteryIconLink, [PRIM_TEXTURE, batteryIconFace, pilotLightID, <0.4, 0.4, 0.0>, <0.0, 0.0, 0.0>, 0]);
    llSetLinkPrimitiveParamsFast(pilotLightLink, [PRIM_GLOW, batteryIconFace, batteryLightGlow]);
    llSetLinkPrimitiveParamsFast(pilotLightLink, [PRIM_COLOR, pilotLightFace, batteryLightColor*brightnessMultiplier, 1.0]);
    llSetLinkPrimitiveParamsFast(pilotLightLink, [PRIM_COLOR, pilotLightFace, batteryLightColor*brightnessMultiplier, 1.0]);
    
    // Battery Icon
    llSetLinkPrimitiveParamsFast(batteryIconLink, [PRIM_GLOW, batteryIconFace, batteryLightGlow]);
    llSetLinkPrimitiveParamsFast(batteryIconLink, [PRIM_TEXTURE, batteryIconFace, batteryIconID, <0.25, 1.0, 0.0>, <batteryIconHoffset, 0.0, 0.0>, 0]);
    llSetLinkPrimitiveParamsFast(batteryIconLink, [PRIM_COLOR, batteryIconFace, batteryIconColor*brightnessMultiplier, 1.0]);
    
    // Other indictaors dim with low levels
    llSetLinkPrimitiveParamsFast(LinkClassIndicator, [PRIM_GLOW, FaceClassIndicator, 0.2]);
    llSetLinkPrimitiveParamsFast(LinkBlinkyMood,[PRIM_COLOR, FaceBlinkyMood, moodColor*brightnessMultiplier, 1.0]);
    setTextColor(moodColor*brightnessMultiplier);
    setclass(class);
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
string blinkyColorToMeaning(integer LinkBlinky, list colors, list names, string jsonTag){
    list colorList = llGetLinkPrimitiveParams(LinkBlinky, [PRIM_COLOR, 0]);
    vector theColor = llList2Vector(colorList,0);
    integer index = llListFindList(colors, [theColor]);
    string stateName = llList2String(names, index);
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonTag, stateName]), "");
    return stateName;
}

setclass(string class) {
    sayDebug("setclass("+class+")");

    integer classi = llListFindList(classNames, [class]);
    classColor = llList2Vector(classColors, classi);
    classLong = llList2String(classNamesLong, classi);

    // set the blinky color
    llSetLinkPrimitiveParamsFast(LinkBlinkyClass,[PRIM_COLOR, FaceBlinkyClass, classColor*brightnessMultiplier, 1.0]);

    // set the big square on the wearer's right
    llSetLinkPrimitiveParamsFast(LinkClassIndicator, [PRIM_COLOR, FaceClassIndicator, classColor*brightnessMultiplier, 1.0]);
    llSetLinkPrimitiveParamsFast(LinkClassIndicator, [PRIM_GLOW, FaceClassIndicator, 0.2]);

    displayTitler();
}

// try to recover some settings based on colors of faces
attachStartup(key theAvatar) {
    sayDebug("attachStartup");
    avatar = theAvatar;
    mood = blinkyColorToMeaning(FaceBlinkyMood, moodColors, moodNames, "Mood");
    class = blinkyColorToMeaning(FaceBlinkyClass, classColors, classNames, "Class");
    threat = blinkyColorToMeaning(FaceBlinkyThreat, threatColors, threatLevels, "Threat");
}

tightenScrew(integer link){
    integer i;
    vector slideDelta = (sliceLoose - sliceTight) / screwSteps;
    vector slice = sliceLoose;
    llPlaySound(screwdriver, 1.0);
    llSetLinkTextureAnim(link, ANIM_ON | SMOOTH | LOOP | ROTATE, faceScrew, 1, 1, 0.0, TWO_PI, -8.0); 
    for (i = 0; i < screwSteps; i = i + 1) {
        slice = slice - slideDelta;
        llSetLinkPrimitiveParamsFast(link, [PRIM_SLICE, slice]);
        llSleep(0.1);
        }
    llSetLinkTextureAnim(link, !ANIM_ON, faceScrew, 1, 1, 0.0, 60.0, 1.0);
    llStopSound();
}

loosenScrew(integer link){
    integer i;
    vector slideDelta = (sliceLoose - sliceTight) / screwSteps;
    vector slice = sliceTight;
    llPlaySound(screwdriver, 1.0);
    llSetLinkTextureAnim(link, ANIM_ON | SMOOTH | LOOP | ROTATE, faceScrew, 1, 1, 0.0, TWO_PI, 8.0);
    for (i = 0; i < screwSteps; i = i + 1) {
        slice = slice + slideDelta;
        llSetLinkPrimitiveParamsFast(link, [PRIM_SLICE, slice]);
        llSleep(0.1);
        }
    llSetLinkTextureAnim(link, !ANIM_ON, faceScrew, 1, 1, 0.0, 60.0, 1.0);
    llStopSound();
}

removeScrew(integer link){
    llSetLinkPrimitiveParamsFast(link, [PRIM_SLICE, sliceRemoved]);
    llSetLinkPrimitiveParamsFast(link, [PRIM_TEXTURE, faceScrew, roundhole, <1, 1, 0.0>, <0.0, 0.0, 0.0>, 0]);
    llSetLinkPrimitiveParamsFast(link, [PRIM_TEXTURE, faceElectrode, roundhole, <1, 1, 0.0>, <0.0, 0.0, 0.0>, 0]);
}

insertScrew(integer link){
    llSetLinkPrimitiveParamsFast(link, [PRIM_SLICE, sliceLoose]);
    llSetLinkPrimitiveParamsFast(link, [PRIM_TEXTURE, faceScrew, philipsHead, <1, 1, 0.0>, <0.0, 0.0, 0.0>, 0]);
    llSetLinkPrimitiveParamsFast(link, [PRIM_TEXTURE, faceElectrode, electrodeEnd, <1, 1, 0.0>, <0.0, 0.0, 0.0>, 0]);
}
insertScrews() {
    insertScrew(linkScrew2);
    insertScrew(linkScrew1);
    insertScrew(linkScrew3);
}

tightenScrews() {
    tightenScrew(linkScrew2);
    tightenScrew(linkScrew1);
    tightenScrew(linkScrew3);
}

loosenScrews() {
    loosenScrew(linkScrew1);
    loosenScrew(linkScrew3);
    loosenScrew(linkScrew2);
}

removeScrews() {
    removeScrew(linkScrew1);
    removeScrew(linkScrew2);
    removeScrew(linkScrew3);
}

screwDownSequence() {
    displayCentered("bolting");
    if (screwState == 0) {
        insertScrews();
        llSleep(1);
        tightenScrews();
        screwState = 1;
    }
    displayCentered("ready");
}

screwRemovalSequence() {
    displayCentered("unbolting");
    if (screwState == 1) {
        loosenScrews();
        llSleep(1);
        removeScrews();
        screwState = 0;
    }
    displayCentered("ready");
} 

initializeScrews() {
    screwDownSequence();
    llSleep(1);
    screwRemovalSequence();
}

default
{
    state_entry()
    {
        llSetObjectName("BG L-CON Implant V4 "+version);
        sayDebug("state_entry");
        
        // LinksAlphanum
        integer i;
        for (i = 0; i < 12; i++) {
            string linkname = "D"+(string)i;
            integer link = getLinkWithName(linkname);
            sayDebug("init linking "+linkname+" to "+(string)link);
            LinksAlphanum = LinksAlphanum + [link];
        }
        linkTitler = getLinkWithName("Titler");
        LinkBlinkyMood = getLinkWithName("LinkBlinky1");
        LinkBlinkyLock = getLinkWithName("LinkBlinky2");
        LinkBlinkyClass = getLinkWithName("LinkBlinky3");
        LinkBlinkyThreat = getLinkWithName("LinkBlinky4");
        LinkClassIndicator = getLinkWithName("BigClassLight");
        pilotLightLink = getLinkWithName("PilotLight");
        //linkTitler = getLinkWithName("powerHoseNozzle");
        //linkTitler = getLinkWithName("leashPoint");
        
        linkScrew1 = getLinkWithName("screw1");
        linkScrew2 = getLinkWithName("screw2");
        linkScrew3 = getLinkWithName("screw3");
        
        llSetLinkAlpha(linkTitler, 0, ALL_SIDES);

        batteryIconLink = getLinkWithName("powerDisplay");
        llSetLinkTextureAnim(batteryIconLink, 0, batteryIconFace, 1, 1, 0.0, 0.0, 0.0);
        displayBattery(75);

        // Initialize the world
        batteryPercent = 0;
        crime = "";
        if (llGetAttached() != 0) {
            attachStartup(llGetOwner());
        } else {
            assetNumber = unassignedAsset;
            mood = "OOC";
            class = "white";
            classColor = WHITE;
            threat = "none";
            setclass(class);

            llSetLinkPrimitiveParamsFast(LinkBlinkyMood, [PRIM_TEXTURE, FaceBlinkyMood, smallLightID, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0]);
            llSetLinkPrimitiveParamsFast(LinkBlinkyLock, [PRIM_TEXTURE, FaceBlinkyLock, smallLightID, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0]);
            llSetLinkPrimitiveParamsFast(LinkBlinkyClass, [PRIM_TEXTURE, FaceBlinkyClass, smallLightID, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0]);
            llSetLinkPrimitiveParamsFast(LinkBlinkyThreat, [PRIM_TEXTURE, FaceBlinkyThreat, smallLightID, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0]);
            llSetLinkPrimitiveParamsFast(LinkClassIndicator, [PRIM_TEXTURE, FaceClassIndicator, smallLightID, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0]);

            llSetLinkPrimitiveParamsFast(LinkBlinkyMood,[PRIM_COLOR, FaceBlinkyMood, BLACK, 1.0]);
            llSetLinkPrimitiveParamsFast(LinkBlinkyLock,[PRIM_COLOR, FaceBlinkyLock, BLACK, 1.0]);
            llSetLinkPrimitiveParamsFast(LinkBlinkyClass,[PRIM_COLOR, FaceBlinkyClass, BLACK, 1.0]);
            llSetLinkPrimitiveParamsFast(LinkBlinkyThreat,[PRIM_COLOR, FaceBlinkyThreat, BLACK, 1.0]);
            llSetLinkPrimitiveParamsFast(LinkClassIndicator,[PRIM_COLOR, FaceClassIndicator, LIGHT_GRAY, 1.0]);
            
            displayTitler();
            
            initializeScrews();
        }
        sayDebug("state_entry done");
    }

    attach(key theAvatar) {
        sayDebug("attach("+(string)theAvatar+") assetNumber:'"+assetNumber+"'");
        attachStartup(theAvatar);
        sayDebug("attach done");
    }

    link_message( integer sender_num, integer num, string json, key id ){
        sayDebug("link_message "+json);

        // IC/OOC Mood sets frame color, text color, and Blinky1
        string value = llJsonGetValue(json, ["Mood"]);
        if (value != JSON_INVALID) {
            mood = value;
            integer moodi = llListFindList(moodNames, [mood]);
            vector moodColor = llList2Vector(moodColors, moodi);
            llSetLinkPrimitiveParamsFast(LinkBlinkyMood,[PRIM_COLOR, FaceBlinkyMood, moodColor, 1.0]);
            setTextColor(moodColor);
            displayTitler();
        }

        // Prisoner Class sets text color and blinky 3
        value = llJsonGetValue(json, ["Class"]);
        if (value != JSON_INVALID) {
            class = value;
            setclass(class);
            sayDebug("link_message "+(string)num+" "+class+"->class");
        }

        // Lock level sets blinky 2 and inserts or removes screws
        value = llJsonGetValue(json, ["LockLevel"]);
        if (value != JSON_INVALID) {
            list lockLevels = ["Safeword", "Off", "Light", "Medium", "Heavy", "Hardcore"];
            list lockColors = [GREEN, BLACK, GREEN, YELLOW, ORANGE, RED];

            lockLevel = value;
            integer locki = llListFindList(lockLevels, [lockLevel]);
            vector lockcolor = llList2Vector(lockColors, locki);
            sayDebug("lock level message:"+lockLevel+" locki:"+(string)locki+" lockColors:"+(string)lockcolor);
            llSetLinkPrimitiveParamsFast(LinkBlinkyLock,[PRIM_COLOR, FaceBlinkyLock, lockcolor, 1.0]);

            if (lockLevel == "Off") {
                screwRemovalSequence();
            } else {
                screwDownSequence();
            }
        }

        // Threat level sets blinky 4
        value = llJsonGetValue(json, ["Threat"]);
        if (value != JSON_INVALID) {
            threat = value;
            integer threati = llListFindList(threatLevels, [threat]);
            vector threatcolor = llList2Vector(threatColors, threati);
            sayDebug("threat level json:"+json+" threati:"+(string)threati+" threatcolor:"+(string)threatcolor);
            llSetLinkPrimitiveParamsFast(LinkBlinkyThreat,[PRIM_COLOR, FaceBlinkyThreat, threatcolor, 1.0]);
            displayTitler();
        }

        // Battery Level Report
        value = llJsonGetValue(json, ["BatteryPercent"]);
        if (value != JSON_INVALID) {
            batteryPercent = (integer)value;
            displayBattery(batteryPercent);
        }
        
        // Prisoner Crime
        value = llJsonGetValue(json, ["Crime"]);
        if (value != JSON_INVALID) {
            crime = value;
            displayTitler();
        }

        // Prisoner Asset Number
        value = llJsonGetValue(json, ["AssetNumber"]);
        if (value != JSON_INVALID) {
            assetNumber = value;
            string firstName = "Unassigned";
            sayDebug("set and display assetNumber \""+assetNumber+"\"");
            if (assetNumber != "P-00000") {
                string ownerName = llGetDisplayName(llGetOwner());
                list namesList = llParseString2List(ownerName, [" "], [""]);
                firstName = llList2String(namesList, 0);
                string newCollarName = assetNumber+" ("+firstName+")";
                if (llGetObjectName() != newCollarName && llGetAttached() != 0) {
                    llOwnerSay("This collar will now rename itself to \""+newCollarName+"\"");
                    llSetObjectName(newCollarName);
                }
            }
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
            toneAlpha(llGetSubString(value,0,3));
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

        //set titler visible
        value = llJsonGetValue(json, [buttonTitler]);
        if (value != JSON_INVALID) {
            sayDebug(buttonTitler+value);
            titlerActive = 0.0;
            if (value == "ON") {
                titlerActive = 1.0;
            }
            displayTitler();
        }
    }
    
   timer() {
        sayDebug("timer()");
        if (TIMER_REDISPLAY > 0) {
            if (assetNumber == unassignedAsset) {
                sendJSON("Database", "getupdate", llGetOwner());
            }
            sayDebug("set and display assetNumber \""+assetNumber+"\"");
            displayCentered(assetNumber);
            llSetTimerEvent(0);
            TIMER_REDISPLAY = 0;
        }
        
        // Blink the battery light off and red for every bad word spokem.
        // Timer shoud be on one-second interval
        if (TIMER_BADWORDS > 0) {
            sayDebug("timer TIMER_BADWORDS:"+(string)TIMER_BADWORDS);
            //llSetLinkColor(LinkBlinky, RED*brightnessMultiplier, 0);
            //llSetLinkPrimitiveParamsFast(LinkClassIndicator,[PRIM_COLOR, FaceClassIndicator, RED, 1.0]);
            TIMER_BADWORDS = - TIMER_BADWORDS;
        } else if (TIMER_BADWORDS < 0) {
            sayDebug("timer TIMER_BADWORDS:"+(string)TIMER_BADWORDS);
            displayBattery(batteryPercent); // reset the red light
            //llSetLinkPrimitiveParamsFast(LinkClassIndicator,[PRIM_COLOR, FaceClassIndicator, BLACK, 1.0]);
            TIMER_BADWORDS = -TIMER_BADWORDS - 1;
            if (TIMER_BADWORDS == 0) {
                //llSetLinkPrimitiveParamsFast(LinkClassIndicator,[PRIM_COLOR, FaceClassIndicator, moodColor, 1.0]);
                llSetTimerEvent(0);
            }
        }
    }
}
