// Display.lsl
// Display script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019
string version = "2020-04-05";

// This script handles all display elements of Black Gazza Collar 4.
// • alphanumeric display
// • blinky lights
// • battery displaydi
// • floaty text

integer OPTION_DEBUG = 0 ;

vector BLACK = <0,0,0>;
vector DARK_GRAY = <0.2, 0.2, 0.2>;
vector GRAY = <0.5, 0.5, 0.5>;
vector LIGHT_GRAY = <0.7, 0.7, 0.7>;
vector DARK_BLUE = <0.0, 0.0, 0.2>;
vector BLUE = <0.0, 0.0, 1.0>;
vector LIGHT_BLUE = <0.1, 0.5, 1.0>;
vector MAGENTA = <1.0, 0.0, 1.0>;
vector CYAN = <0.0, 1.0, 1.0>;
vector WHITE = <1.0, 1.0, 1.0>;
vector RED = <1.0, 0.0, 0.0>;
vector REDORANGE = <1.0, 0.25, 0.0>;
vector ORANGE = <1.0, 0.5, 0.0>;
vector YELLOW = <1.0, 1.0, 0.0>;
vector GREEN = <0.0, 1.0, 0.0>;
vector PURPLE = <0.7, 0.1, 1.0>;

list lockLevels = ["Safeword", "Off", "Light", "Medium", "Heavy", "Hardcore"];
list lockColors = [GREEN, BLACK, GREEN, YELLOW, ORANGE, RED];
list threatLevels = ["None", "Moderate", "Dangerous", "Extreme"];
list threatColors = [GREEN, YELLOW, ORANGE, RED];
        
// Diffuse = Textures
key BG_CollarV4_DiffuseBLK = "875eca8e-0dd3-1384-9dec-56dc680d0628";
key BG_CollarV4_DiffuseBLU = "512f7f51-69b3-1623-fe79-128f2fc72927";
key BG_CollarV4_DiffuseCLN = "6cf8859d-e117-6470-b8d2-4a2bc3e69f5e"; // White
key BG_CollarV4_DiffuseGRN = "fa3369fa-bff9-9df9-3824-45fe2ea25711";
key BG_CollarV4_DiffuseORNG = "05b8b472-25ee-4d48-9306-b322e1329c82";
key BG_CollarV4_DiffusePRPL = "85b92d52-bc50-6232-ca40-1fc5d4f5e5f3";
key BG_CollarV4_DiffuseRED = "6c5e4c59-5a20-abb0-cd10-36a7a314b0d4";
// alpha blending shoudl be None

// Specular = Shininess
key BG_CollarV4_SpecularBLK = "c8514866-6d1b-1a14-08c9-6f5f6cf19852";
key BG_CollarV4_SpecularBLU = "57a81cdf-dd18-e56b-d954-1beb95231680";
key BG_CollarV4_SpecularCLN = "c8fd2092-eae7-a73c-2603-528c7303d895"; // White
key BG_CollarV4_SpecularGRN = "45ace4a9-808d-9a80-3024-ffb882968ffd";
key BG_CollarV4_SpecularORNG = "cc716d0a-0e3b-72b4-4933-6888ce9631a6";
key BG_CollarV4_SpecularPRPL = "c5ab17c6-a9aa-3b4c-6a51-873a72b3d376";
key BG_CollarV4_SpecularRED = "706aee2e-f690-b1f7-8a1d-80a15ce2e835";

// Bump = Normals
key BG_CollarV4_NormalCln = "43bff6ec-96c3-7159-c73e-c50c6bb3944e"; // Clean
key BG_CollarV4_NormalCol = "4cc3a580-be55-1511-7c0b-4bf1094b1dbf"; // Colors

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
list touchTones;

integer LinkFrame = 1;
integer FaceFrame = 0;
integer FacePadding = 1;

integer LinkBlinky = 17;
integer FaceBlinkyZap = 1;
integer FaceBlinkyLock = 2;
integer FaceBlinkyClass = 3;
integer FaceBlinkyThreat = 4;

integer LinkAlphanumFrame = 17;
integer FaceAlphanumFrame = 5;
integer FaceAlphanum = 1;
list LinksAlphanum = [];

integer linkTitler = 0;

// BG_CollarV4_PowerDisplay_PNG
string batteryCharge;
key batteryIconID = "ef369716-ead2-b691-8f5c-8253f79e690a";
integer batteryIconLink = 16;
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
list classColors;
list classTextures;
list classSpeculars;
list classBumpmaps;
vector prisonerClassColor;
string prisonerLockLevel;

string prisonerCrime;
string prisonerThreat;

integer responderChannel;
integer responderListen;

string assetNumber = "P-00000";
string zapLevelsJSON;

integer TIMER_BADWORDS = 0;
integer TIMER_SCROLL = 0;
integer TIMER_REDISPLAY = 0;

key avatar = NULL_KEY;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Display:"+message);
    }
}

sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
    }
    
string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
        }
    return result;
    }
    
integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) 
            return i; // Found it! Exit loop early with result
    return -1; // No prim with that name, return -1.
}

tone(string number) {
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
    llSetLinkColor(LinkBlinky, batteryLightColor, 0);
    llSetLinkPrimitiveParamsFast(LinkBlinky, [PRIM_GLOW, ALL_SIDES, batteryLightGlow]);
    llSetLinkPrimitiveParamsFast(LinkBlinky, [PRIM_GLOW, FaceAlphanumFrame, 0.3]);
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
string blinkyFaceColorToMeaning(integer face, list colors, list names, string jsonTag){
    list colorList = llGetLinkPrimitiveParams(LinkBlinky, [PRIM_COLOR, face]);
    vector prisonerThreatColor = llList2Vector(colorList,0);
    integer index = llListFindList(colors, [prisonerThreatColor]);
    string stateName = llList2String(names, index); 
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonTag, stateName]), "");
    return stateName;
}

setPrisonerClass(string prisonerClass) {
    integer classi = llListFindList(classNames, [prisonerClass]);
    prisonerClassColor = llList2Vector(classColors, classi);
    prisonerClassLong = llList2String(classNamesLong, classi);

    setTextColor(prisonerClassColor);
            
    // set the blinky color
    llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinkyClass, prisonerClassColor, 1.0]);
            
    // set the collar frame texture, reflectivity, and bumpiness
    llSetPrimitiveParams([PRIM_TEXTURE, FaceFrame, llList2Key(classTextures, classi), <1,1,0>, <0,0,0>, 0]);
    llSetPrimitiveParams([PRIM_SPECULAR, FaceFrame, llList2Key(classSpeculars, classi), <1,1,0>, <0,0,0>, 0, <1,1,1>,255, 75]);
    llSetPrimitiveParams([PRIM_NORMAL, FaceFrame, llList2Key(classBumpmaps, classi), <1,1,0>, <0,0,0>, 0]);
    displayTitler();
}


// try to recover some settings based on colors of faces
attachStartup() {
    prisonerMood = blinkyFaceColorToMeaning(FaceAlphanumFrame, moodColors, moodNames, "prisonerMood");
    prisonerClass = blinkyFaceColorToMeaning(FaceBlinkyClass, classColors, classNames, "prisonerClass");
    prisonerThreat = blinkyFaceColorToMeaning(FaceBlinkyThreat, threatColors, threatLevels, "prisonerThreat");
    // set up the responder
    responderChannel = uuidToInteger(llGetOwner());
    responderListen = llListen(responderChannel,"", "", "");
    }

default
{
    state_entry() // reset
    {
        llSetObjectName("BG L-CON Collar V4 "+version);
        sayDebug("state_entry");
        
        // set up lists and shit
        moodNames = ["OOC","Submissive","Versatile","Dominant","Nonsexual","Story", "DnD"];
        moodColors = [LIGHT_GRAY, GREEN, YELLOW, ORANGE, CYAN, PURPLE, GRAY];
        prisonerMood = "OOC";
        
        touchTones = [touchTone0, touchTone1, touchTone2, touchTone3, touchTone4, 
            touchTone5, touchTone6, touchTone7, touchTone8, touchTone9];        

        classNames = ["white","pink","red","orange","green","blue","black"];
        classNamesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental","Unknown"];
        classColors = [WHITE, MAGENTA, RED, ORANGE, GREEN, CYAN, GRAY];
        classTextures = [BG_CollarV4_DiffuseCLN, BG_CollarV4_DiffusePRPL, BG_CollarV4_DiffuseRED, 
            BG_CollarV4_DiffuseORNG, BG_CollarV4_DiffuseGRN, BG_CollarV4_DiffuseBLU, BG_CollarV4_DiffuseBLK];
        classSpeculars = [BG_CollarV4_SpecularCLN, BG_CollarV4_SpecularPRPL, BG_CollarV4_SpecularRED, 
            BG_CollarV4_SpecularORNG, BG_CollarV4_SpecularGRN, BG_CollarV4_SpecularBLU, BG_CollarV4_SpecularBLK];
        classBumpmaps = [BG_CollarV4_NormalCln, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, 
            BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol];
        
        // LinksAlphanum
        integer i;
        for (i = 0; i < 12; i++) {
            string linkname = "D"+(string)i;
            integer link = getLinkWithName(linkname);
            sayDebug("init linking "+linkname+" to "+(string)link);
            LinksAlphanum = LinksAlphanum + [link];
            }        
        linkTitler = getLinkWithName("Titler");
        LinkBlinky = getLinkWithName("BG_CollarV4_LightsMesh");
        LinkAlphanumFrame = getLinkWithName("BG_CollarV4_LightsMesh");
        batteryIconLink = getLinkWithName("powerDisplay");
        //linkTitler = getLinkWithName("powerHoseNozzle");
        //linkTitler = getLinkWithName("leashPoint");
        
        llSetLinkAlpha(linkTitler, 0, ALL_SIDES);

        // turn off lingering battery animations
        llSetLinkTextureAnim(batteryIconLink, 0, batteryIconFace, 1, 1, 0.0, 0.0, 0.0);

        // Initialize the world
        batteryCharge = "Unknown"; 
        prisonerCrime = "Unknown";
        if (llGetAttached() != 0) {
            attachStartup();
        } else {
            assetNumber = "P-00000";
            prisonerMood = "OOC";
            prisonerClass = "white";
            prisonerClassColor = WHITE;
            prisonerThreat = "none";
            
            setPrisonerClass(prisonerClass);
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinkyZap, BLACK, 1.0]);            
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinkyLock, BLACK, 1.0]);            
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinkyThreat, BLACK, 1.0]);
            llSetLinkPrimitiveParamsFast(LinkAlphanumFrame,[PRIM_COLOR, FaceAlphanumFrame, LIGHT_GRAY, 1.0]);
        }
        displayTitler();
        displayCentered(assetNumber);
    }
    
    attach(key theAvatar) {
        avatar = theAvatar;
        attachStartup();
        displayTitler();
    }

    link_message( integer sender_num, integer num, string json, key id ){ 
        sayDebug("link_message "+json);

        // IC/OOC Mood sets frame color 
        string value = llJsonGetValue(json, ["prisonerMood"]);
        if (value != JSON_INVALID) {
            prisonerMood = value;
            integer moodi = llListFindList(moodNames, [prisonerMood]);
            vector moodColor = llList2Vector(moodColors, moodi);
            llSetLinkPrimitiveParamsFast(LinkAlphanumFrame,[PRIM_COLOR, FaceAlphanumFrame, moodColor, 1.0]);
            llSetLinkPrimitiveParamsFast(LinkAlphanumFrame, [PRIM_GLOW, FaceAlphanumFrame, 0.3]);
            displayTitler();
        }

        // Prisoner Class sets text color and blinky 3
        value = llJsonGetValue(json, ["prisonerClass"]);
        if (value != JSON_INVALID) {
            prisonerClass = value;
            setPrisonerClass(prisonerClass);
            sayDebug("link_message "+(string)num+" "+prisonerClass+"->prisonerClass");
            
        }
        
        // Zap Level sets blinky 1
        value = llJsonGetValue(json, ["zapLevels"]);
        if (value != JSON_INVALID) {
            zapLevelsJSON = value;
            list zapLevels = llJson2List(zapLevelsJSON);
            sayDebug("link_message "+(string)num+" "+(string)zapLevels+"->message");
            sayDebug("zapLevels list:"+(string)zapLevels);
            vector lightcolor = BLACK;
            if (assetNumber != "P-00000") {
                // color tells the highest allowed zap level
                if (llList2Integer(zapLevels,0)) lightcolor = YELLOW;
                if (llList2Integer(zapLevels,1)) lightcolor = ORANGE;
                if (llList2Integer(zapLevels,2)) lightcolor = RED;
            }
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinkyZap, lightcolor, 1.0]);            
        }
        
        // Lock level sets blinky 2
        value = llJsonGetValue(json, ["prisonerLockLevel"]);
        if (value != JSON_INVALID) {
            prisonerLockLevel = value;
            integer locki = llListFindList(lockLevels, [prisonerLockLevel]);
            vector lockcolor = llList2Vector(lockColors, locki);
            sayDebug("lock level message:"+prisonerLockLevel+" locki:"+(string)locki+" lockColors:"+(string)lockcolor);
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinkyLock, lockcolor, 1.0]);
        }
        
        // Threat level sets blinky 4
        value = llJsonGetValue(json, ["prisonerThreat"]);
        if (value != JSON_INVALID) {
            prisonerThreat = value;
            integer threati = llListFindList(threatLevels, [prisonerThreat]);
            vector threatcolor = llList2Vector(threatColors, threati);
            sayDebug("threat level json:"+json+" threati:"+(string)threati+" threatcolor:"+(string)threatcolor);
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinkyThreat, threatcolor, 1.0]);
            displayTitler();
        }
        
        // Battery Level Report
        value = llJsonGetValue(json, ["batteryCharge"]);
        if (value != JSON_INVALID) {
            batteryCharge = value;
            sayDebug("batteryCharge "+batteryCharge);
            displayBattery((integer)batteryCharge);
        }
        
        // Prisoner Crime
        string newPrisonerCrime = getJSONstring(json, "prisonerCrime", prisonerCrime);
        if (newPrisonerCrime != prisonerCrime) {
            prisonerCrime = newPrisonerCrime;
            displayTitler();
            }

        string newAssetNumber = getJSONstring(json, "assetNumber", assetNumber);
        if (newAssetNumber != assetNumber) {
            assetNumber = newAssetNumber;
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
                "batteryCharge", batteryCharge, 
                "prisonerLockLevel", prisonerLockLevel, 
                "zapLevels", zapLevelsJSON]);
            sayDebug("listen("+name+","+message+") responds with " + statusJsonList);
            llSay(responderChannel, statusJsonList);
        }
    }

    timer() {
        sayDebug("timer()");
            if (TIMER_REDISPLAY > 0) {
                if (assetNumber == "P-00000") {
                    sendJSON("database", "getupdate", llGetOwner());
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
                llSetLinkColor(LinkBlinky, RED, 0);
                llSetLinkPrimitiveParamsFast(LinkAlphanumFrame,[PRIM_COLOR, FaceAlphanumFrame, RED, 1.0]);
                TIMER_BADWORDS = - TIMER_BADWORDS;
            } else if (TIMER_BADWORDS < 0) {
                sayDebug("timer TIMER_BADWORDS:"+(string)TIMER_BADWORDS);
                displayBattery((integer)batteryCharge);
                llSetLinkPrimitiveParamsFast(LinkAlphanumFrame,[PRIM_COLOR, FaceAlphanumFrame, BLACK, 1.0]);
                TIMER_BADWORDS = -TIMER_BADWORDS - 1;
                if (TIMER_BADWORDS == 0) {
                    llSetLinkPrimitiveParamsFast(LinkAlphanumFrame,[PRIM_COLOR, FaceAlphanumFrame, moodColor, 1.0]);
                    llSetTimerEvent(0);  
                }
            }
        }
    }
