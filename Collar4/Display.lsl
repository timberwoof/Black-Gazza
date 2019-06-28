// Display.lsl
// Display script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019

// This script handles all display elements of Black Gazza Collar 4.
// • alphanumeric display
// • blinky lights
// • battery display

vector BLACK = <0,0,0>;
vector DARK_GRAY = <0.2, 0.2, 0.2>;
vector DARK_BLUE = <0.0, 0.0, 0.2>;
vector BLUE = <0.0, 0.0, 1.0>;
vector MAGENTA = <1.0, 0.0, 1.0>;
vector CYAN = <0.0, 1.0, 1.0>;
vector WHITE = <1.0, 1.0, 1.0>;
vector RED = <1.0, 0.0, 0.0>;
vector REDORANGE = <1.0, 0.25, 0.0>;
vector ORANGE = <1.0, 0.5, 0.0>;
vector YELLOW = <1.0, 1.0, 0.0>;
vector GREEN = <0.0, 1.0, 0.0>;
vector PURPLE = <0.5, 0.0, 1.0>;

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

// BG_CollarV4_PowerDisplay_PNG
key batteryIconID = "ef369716-ead2-b691-8f5c-8253f79e690a";
integer batteryIconLink = 16;
integer batteryIconFace = 0;
float batteryIconHScale = 0.2;
float batteryIconVScale = 0.75;
float batteryIconRotation = 90.0;
float batteryIconHoffset = -0.4;
vector batteryIconColor = <0.0, 0.5, 1.0>;
vector batteryLightColor = <1.0, 0.0, 0.0>;
 

key crimeRequest;
string scrollText;
integer scrollPos;
integer scrollLimit;
string fontID = "fc55ee0b-62b5-667c-043d-46d822249ee0";

string Mood;
list moodNames;
list moodColors;

string Class;
list classNames;
list classColors;
vector classColor;

integer debugBatteryLevel;
    
// Display a string of 12 characters on the collar display. 
// If you supply less than 12 characters, the last ones don't get reset. 
// Anything after 12 characters gets truncated. 
displayText(string text){
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
        j = llSubStringIndex(textMap,letter);   // find it in the boitmap
        integer ix = (j % 10);                  // find the x coordinates
        float x = ix * 0.1 + .05;

        integer iy = 7 - j / 10;                // find the y coordinates
        float y = iy * 0.1429;

        integer linkNumber = 15 - i;            // shift the appropriate textmap
        llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_TEXTURE, 0, fontID, <0.1, 0.15, 0.0>, <x, y, 0.0>, 0.0]);
    }
}

setTextColor(vector classColor){
    integer i;
    for (i = 0; i < 12; i++){
        integer linkNumber = 15 - i; 
        llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_COLOR, 0, classColor, 0.5]);
        llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_GLOW, 0, 0.0]);
    }
}

// display a string of less than 12 characters on the alphanumeric display, more or less centered
displayCentered(string text){
    integer pad = (12 - llStringLength(text)) / 2; 
    displayText(llInsertString("            ", pad, text));
}

displayScroll(string text){
    string displayText = "            "; // 12 spaces
    //llMessageLinked(LINK_ALL_CHILDREN, 555, displayText, "");
    scrollText = llToUpper(text) + " " + llToUpper(text) + " " ;
    scrollPos = 0;
    scrollLimit = llStringLength(text);
    llSetTimerEvent(1);
}

// based on the percentage, display the correct icon and color
displayBattery(integer percent)
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
    }
    else if (percent > 8) {
        batteryIconColor = <1.0, 0.5, 0>; // orange empty
        batteryLightColor = <1.0, 0.5, 0>;
    }
    else if (percent > 4) {
        batteryIconColor = <1.0, 0.0, 0.0>; // red empty
        batteryLightColor = <1.0, 0.0, 0.0>;
    }
    else {
        batteryIconColor = <0.0, 0.0, 0.0>; // black empty
        batteryLightColor = <0.0, 0.0, 0.0>;
    }
    llSetLinkColor(LinkBlinky, batteryLightColor, 0);
    llSetLinkPrimitiveParamsFast(batteryIconLink,[PRIM_TEXTURE, batteryIconFace, batteryIconID, <0.2, 0.75, 0.0>, <batteryIconHoffset, 0.0, 0.0>, 1.5708]);
    llSetLinkPrimitiveParamsFast(batteryIconLink,[PRIM_COLOR, batteryIconFace, batteryIconColor, 1.0]);
}

default
{
    state_entry()
    {
        // set up lists and shit
        moodNames = ["OOC","Submissive","Versatile","Dominant","Nonsexual","Story", "DnD"];
        moodColors = [DARK_GRAY, GREEN, YELLOW, ORANGE, CYAN, BLUE, BLACK];
        
        classNames = ["White","Pink","Red","Orange","Green","Blue","Black"];
        classColors = [WHITE, CYAN, RED, ORANGE, GREEN, BLUE, BLACK];
        classColor = WHITE;
        
        // Test the displaytext functions
        displayText("INITIALIZING");
        displayText("*0123456789*");
        displayText("*ABCDEFGHIJ*");
        displayText("*KLMNOPQRST*");
        displayText("*UVWXYZabcd*");
        displayText("*efghijklmn*");
        displayText("*opqrstuvwx*");
        displayText("*yz .,:;-#**");
        displayCentered("");
        displayCentered("*");
        displayCentered("**");
        displayCentered("***");
        displayCentered("****");
        displayCentered("*****");
        displayCentered("******");
        displayCentered("*******");
        displayCentered("********");
        displayCentered("*********");
        displayCentered("**********");
        displayCentered("***********");
        displayCentered("************");
        
        // fire off a request tot he crime database for this wearer. 
        string URL = "http://sl.blackgazza.com/read_inmate.cgi?key=" + (string)llGetOwner();
        crimeRequest= llHTTPRequest(URL,[],"");
        
        debugBatteryLevel = 0;
    }

    // handle the response from the crime database
    http_response( key request_id, integer status, list metadata, string body )
    {
        if (status == 200) {
            // body looks like "Timberwoof Lupindo,0,Piracy,284ba63f-378b-4be6-84d9-10db6ae48b8d,P-60361"
            list returned = llParseString2List(body, [","], []);
            string name = llList2String(returned, 0);
            string crime = llList2String(returned, 2);
            string theKey = llList2Key(returned, 3);
            string number = llList2String(returned, 4);
            
            if (theKey == llGetOwner()) {
                displayCentered(number);
                // test the scrolling display function
                displayScroll(number+" *"+name+"* "+crime+". ");
            }
            else {
                displayCentered("Key Error");
            }
        }
        else {
        }
    }
    
    link_message( integer sender_num, integer num, string message, key id ){ 
        if (num == 1100) {
            Mood = message;
            integer moodi = llListFindList(moodNames, [message]);
            vector moodColor = llList2Vector(moodColors, moodi);
            llSetLinkPrimitiveParamsFast(LinkAlphanumFrame,[PRIM_COLOR, FaceAlphanumFrame, moodColor, 1.0]);
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinky1, moodColor, 1.0]);
        }
        else if (num == 1200) {
            Mood = message;
            integer classi = llListFindList(moodNames, [message]);
            classColor = llList2Vector(moodColors, classi);
            setTextColor(classColor);
        }
    }
    
    
    timer()
    {
        // Scrolling Text handler works for text longer than 12 characters. 
        displayText(llGetSubString(scrollText, scrollPos, scrollPos+12) + "            ");
        scrollPos = scrollPos + 1;
        if (scrollPos >= scrollLimit) {
            scrollPos = 0;
        }
        
        displayBattery(debugBatteryLevel);
        debugBatteryLevel = debugBatteryLevel + 1;
        if (debugBatteryLevel > 100) debugBatteryLevel = 0;
    }
}
