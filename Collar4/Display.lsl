// Display.lsl
// Display script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019
// version: 2020-02-23

// This script handles all display elements of Black Gazza Collar 4.
// • alphanumeric display
// • blinky lights
// • battery display

integer OPTION_DEBUG = 0;

vector BLACK = <0,0,0>;
vector DARK_GRAY = <0.2, 0.2, 0.2>;
vector GRAY = <0.5, 0.5, 0.5>;
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
vector PURPLE = <0.5, 0.0, 1.0>;
        
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

integer LinkFrame = 1;
integer FaceFrame = 0;
integer FacePadding = 1;

integer LinkBlinky = 17;
integer FaceBlinky1 = 1;
integer FaceBlinky2 = 2;
integer FaceBlinky3 = 3;
integer FaceBlinky4 = 4;

integer LinkAlphanumFrame = 17;
integer FaceAlphanumFrame = 5;
integer FaceAlphanum = 1;
list LinksAlphanum = [];

integer linkTitler = 0;

// BG_CollarV4_PowerDisplay_PNG
integer batteryLevel;
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

string prisonerClass;
string prisonerClassLong;
list classNames;
list classNamesLong;
list classColors;
list classTextures;
list classSpeculars;
list classBumpmaps;
vector prisonerClassColor;

string prisonerCrime;
string prisonerThreat;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Display:"+message);
    }
}

integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) 
            return i; // Found it! Exit loop early with result
    return -1; // No prim with that name, return -1.
}

displayTitler() {
    integer classIndex = llListFindList(classNames, [prisonerClass]);
    string description = "Class " + prisonerClass + ": " + llList2String(classNamesLong, classIndex);
    string title = assetNumber + "\n" + description + "\nCrime: " + prisonerCrime + "\nThreat: " + prisonerThreat + "\nMood: " + prisonerMood ;
    llSetLinkPrimitiveParamsFast(linkTitler, [PRIM_TEXT, title, prisonerClassColor, 1.0]);
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

string name;
string start_date;
string assetNumber;
string crime;
string class;
string shocks;
string rank;
string specialty;

default
{
    state_entry()
    {
        sayDebug("state_entry");
        
        // set up lists and shit
        moodNames = ["OOC","Submissive","Versatile","Dominant","Nonsexual","Story", "DnD"];
        moodColors = [DARK_GRAY, GREEN, YELLOW, ORANGE, CYAN, BLUE, BLACK];
        prisonerMood = "OOC";
        
        classNames = ["white","pink","red","orange","green","blue","black"];
        classNamesLong = ["Unassigned Transfer", "Sexual Deviant", "Mechanic", "General Population", "Medical Experiment", "Violent or Hopeless", "Mental"];
        classColors = [WHITE, MAGENTA, RED, ORANGE, GREEN, CYAN, WHITE];
        classTextures = [BG_CollarV4_DiffuseCLN, BG_CollarV4_DiffusePRPL, BG_CollarV4_DiffuseRED, 
            BG_CollarV4_DiffuseORNG, BG_CollarV4_DiffuseGRN, BG_CollarV4_DiffuseBLU, BG_CollarV4_DiffuseBLK];
        classSpeculars = [BG_CollarV4_SpecularCLN, BG_CollarV4_SpecularPRPL, BG_CollarV4_SpecularRED, 
            BG_CollarV4_SpecularORNG, BG_CollarV4_SpecularGRN, BG_CollarV4_SpecularBLU, BG_CollarV4_SpecularBLK];
        classBumpmaps = [BG_CollarV4_NormalCln, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, 
            BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol];
        prisonerClass = "White";
        prisonerClassColor = WHITE;
        setTextColor(CYAN);
        
        linkTitler = getLinkWithName("Titler");
        
        // LinksAlphanum
        integer i;
        for (i = 0; i < 12; i++) {
            string linkname = "D"+(string)i;
            integer link = getLinkWithName(linkname);
            sayDebug("init linking "+linkname+" to "+(string)link);
            LinksAlphanum = LinksAlphanum + [link];
            }        
        
        linkTitler = getLinkWithName("powerHoseNozzle");
        linkTitler = getLinkWithName("Titler");
        linkTitler = getLinkWithName("leashPoint");
        LinkBlinky = getLinkWithName("BG_CollarV4_LightsMesh");
        LinkAlphanumFrame = getLinkWithName("BG_CollarV4_LightsMesh");
        batteryIconLink = getLinkWithName("powerDisplay");
        linkTitler = getLinkWithName("D0");
        linkTitler = getLinkWithName("Titler");
        linkTitler = getLinkWithName("Titler");
        
        llSetLinkAlpha(linkTitler, 0, ALL_SIDES);

        // turn off lingering battery animations
        llSetLinkTextureAnim(batteryIconLink, 0, batteryIconFace, 1, 1, 0.0, 0.0, 0.0);

        batteryLevel = 0; // remove when we do "real" battery levels
                
        if (llGetAttached() != 0) {
            llSetObjectName(llGetDisplayName(llGetOwner())+"'s LOC-4");
        }
    }

    attach(key id)
    {
        sayDebug("attach");
        if (id) {
            llSetObjectName(llGetDisplayName(llGetOwner())+"'s LOC-4");
            batteryLevel = 0;  // remove when we do "real" battery levels      
        }
    }

    link_message( integer sender_num, integer num, string message, key id ){ 
        sayDebug("link_message "+(string)num+" "+message);

        // IC/OOC Mood sets frame color 
        if (num == 1100) {
            prisonerMood = message;
            sayDebug("link_message "+(string)num+" "+prisonerMood+"->prisonerMood");
            integer moodi = llListFindList(moodNames, [prisonerMood]);
            vector moodColor = llList2Vector(moodColors, moodi);
            llSetLinkPrimitiveParamsFast(LinkAlphanumFrame,[PRIM_COLOR, FaceAlphanumFrame, moodColor, 1.0]);
            llSetLinkPrimitiveParamsFast(LinkAlphanumFrame, [PRIM_GLOW, FaceAlphanumFrame, 0.3]);
            displayTitler();
        }
        
        // Prisoner Class sets text color and blinky 3
        else if (num == 1200) {
            prisonerClass = message;
            sayDebug("link_message "+(string)num+" "+prisonerClass+"->prisonerClass");
            integer classi = llListFindList(classNames, [prisonerClass]);
            prisonerClassColor = llList2Vector(classColors, classi);
            prisonerClassLong = llList2String(classNamesLong, classi);
            setTextColor(prisonerClassColor);
            
            // set the blinky color
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinky3, prisonerClassColor, 1.0]);
            
            // set the collar frame texture, reflectivity, and bumpiness
            llSetPrimitiveParams([PRIM_TEXTURE, FaceFrame, llList2Key(classTextures, classi), <1,1,0>, <0,0,0>, 0]);
            llSetPrimitiveParams([PRIM_SPECULAR, FaceFrame, llList2Key(classSpeculars, classi), <1,1,0>, <0,0,0>, 0, <1,1,1>,255, 75]);
            llSetPrimitiveParams([PRIM_NORMAL, FaceFrame, llList2Key(classBumpmaps, classi), <1,1,0>, <0,0,0>, 0]);
            displayTitler();
            }
        
        // Zap Level sets blinky 1
        else if (num == 1300) {
            // message contains a json list of settings
            list zapLevels = llJson2List(message);
            sayDebug("link_message "+(string)num+" "+(string)zapLevels+"->message");
            sayDebug("zapLevels list:"+(string)zapLevels);
            vector lightcolor = BLACK;
            // color tells the highest allowed zap level
            if (llList2Integer(zapLevels,0)) lightcolor = YELLOW;
            if (llList2Integer(zapLevels,1)) lightcolor = ORANGE;
            if (llList2Integer(zapLevels,2)) lightcolor = RED;
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinky1, lightcolor, 1.0]);            
        }
        
        // Threat level sets blinky 4
        else if (num == 1500) {
            prisonerThreat = message;
            list threatLevels = ["None", "Moderate", "Dangerous", "Extreme"];
            list threatColors = [GREEN, YELLOW, ORANGE, RED];
            integer threati = llListFindList(threatLevels, [prisonerThreat]);
            vector threatcolor = llList2Vector(threatColors, threati);
            sayDebug("threat level message:"+message+" threati:"+(string)threati+" threatcolor:"+(string)threatcolor);
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinky4, threatcolor, 1.0]);
            displayTitler();
        }
        
        // Lock level sets blinky 2
        else if (num == 1400) {
            list lockLevels = ["Safeword", "Off", "Light", "Medium", "Heavy", "Hardcore"];
            list lockColors = [GREEN, BLACK, GREEN, YELLOW, ORANGE, RED];
            integer locki = llListFindList(lockLevels, [message]);
            vector lockcolor = llList2Vector(lockColors, locki);
            sayDebug("lock level message:"+message+" locki:"+(string)locki+" lockColors:"+(string)lockcolor);
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinky2, lockcolor, 1.0]);
        }
        
        // Battery Level Report
        else if (num == 1700) {
            sayDebug("battery "+message);
            displayBattery((integer)message);
        }
        
        // Prisoner Crime
        else if (num == 1800) {
            prisonerCrime = message;
            displayTitler();
        }

        // set and display asset number
        else if (num == 2000) {
            assetNumber = message;
            if (assetNumber == "") {
                llOwnerSay("Please select Settings > Asset.");
            } else {
                sayDebug("set and display assetNumber \""+assetNumber+"\"");
                displayCentered(assetNumber);
                displayTitler();
            }
        }
        
        // temporarily display a message
        else if (num == 2001) {
            sayDebug("display "+message);
            displayCentered(message);
            llSetTimerEvent(5);
        }
    }
    
    timer() {
        sayDebug("timer(): display assetNumber "+assetNumber);
            if (assetNumber == "") {
                llOwnerSay("Please select Settings > Asset.");
            } else {
                sayDebug("set and display assetNumber \""+assetNumber+"\"");
                displayCentered(assetNumber);
            }
        llSetTimerEvent(0);  
    }
}
