// Display.lsl
// Display script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019

// This script handles all display elements of Black Gazza Collar 4.
// • alphanumeric display
// • blinky lights
// • battery display

integer OPTION_DEBUG = 1;

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
list classTextures;
list classSpeculars;
list classBumpmaps;
vector classColor;

    
sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Display:"+message);
    }
}

displayText(string text){
// Display a string of 12 characters on the collar display. 
// If you supply less than 12 characters, the last ones don't get reset. 
// Anything after 12 characters gets truncated. 

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
    sayDebug("setTextColor "+(string)classColor);
    integer i;
    for (i = 0; i < 12; i++){
        integer linkNumber = 15 - i; 
        llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_COLOR, 0, classColor, 0.5]);
        llSetLinkPrimitiveParamsFast(linkNumber, [PRIM_GLOW, 0, 0.3]);
    }
}

displayCentered(string text){
// display a string of less than 12 characters on the alphanumeric display, more or less centered
    integer pad = (12 - llStringLength(text)) / 2; 
    displayText(llInsertString("            ", pad, text));
}

displayScroll(string text){
// display a string of more than 12 characters in a lovely scrolling manner. 
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
string registrationNumber;
string crime;
string class;
string shocks;
string rank;
string specialty;


// fire off a request to the crime database for this wearer. 
sendDatabaseQuery() {
    displayCentered("Accessing DB");
    // Old DB
    //string URL = "http://sl.blackgazza.com/read_inmate.cgi?key=" + (string)llGetOwner();
    // New DB
    string UUID = (string)llGetOwner();
    // test uuids
    // 00000000-0000-0000-0000-000000000010 Loot Boplace
    // 00000000-0000-0000-0000-000000000011 Marmour Bovinecow
    // 00000000-0000-0000-0000-000000000012 LUP-8462
    // 00000000-0000-0000-0000-000000000013 Melkor Schmerzlos
    //UUID = "00000000-0000-0000-0000-000000000013";
    string URL = "https://api.blackgazza.com/asset/?identity=" + UUID;
    crimeRequest= llHTTPRequest(URL,[],"");
}

string getListThing(list theList, string theKey){
    return llList2String(theList, llListFindList(theList, [theKey])+1);
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
        
        // set up lists and shit
        moodNames = ["OOC","Submissive","Versatile","Dominant","Nonsexual","Story", "DnD"];
        moodColors = [DARK_GRAY, GREEN, YELLOW, ORANGE, CYAN, BLUE, BLACK];
        Mood = "OOC";
        
        classNames = ["White","Pink","Red","Orange","Green","Blue","Black"];
        classColors = [WHITE, MAGENTA, RED, ORANGE, GREEN, CYAN, WHITE];
        classTextures = [BG_CollarV4_DiffuseCLN, BG_CollarV4_DiffusePRPL, BG_CollarV4_DiffuseRED, 
            BG_CollarV4_DiffuseORNG, BG_CollarV4_DiffuseGRN, BG_CollarV4_DiffuseBLU, BG_CollarV4_DiffuseBLK];
        classSpeculars = [BG_CollarV4_SpecularCLN, BG_CollarV4_SpecularPRPL, BG_CollarV4_SpecularRED, 
            BG_CollarV4_SpecularORNG, BG_CollarV4_SpecularGRN, BG_CollarV4_SpecularBLU, BG_CollarV4_SpecularBLK];
        classBumpmaps = [BG_CollarV4_NormalCln, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, 
            BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol, BG_CollarV4_NormalCol];
        Class = "White";
        classColor = WHITE;
        setTextColor(CYAN);

        // turn off lingering battery animations
        llSetLinkTextureAnim(batteryIconLink, 0, batteryIconFace, 1, 1, 0.0, 0.0, 0.0);

        batteryLevel = 0; // remove when we do "real" battery levels
                
        if (llGetAttached() != 0) {
            sendDatabaseQuery();
            llSetObjectName(llGetDisplayName(llGetOwner())+"'s LOC-4");
        }
    }

    attach(key id)
    {
        if (id) {
            sendDatabaseQuery();
            llSetObjectName(llGetDisplayName(llGetOwner())+"'s LOC-4");
            batteryLevel = 0;  // remove when we do "real" battery levels      
        }
    }

    http_response(key request_id, integer status, list metadata, string message)
    // handle the response from the crime database
    {
        displayCentered("status "+(string)status);        
        if (status == 200) {
            // body looks like 
            // {"roles": 
            //      {"inmate": 
            //      {"P-60361": 
            //          {"name": "Timberwoof Lupindo", 
            //          "start_date": "2008-12-28 03:30:58", 
            //          "crime": "Piracy"}}}, 
            //  "_name_": "Timberwoof Lupindo", 
            //  "_start_date_": "2008-12-28 03:30:58"}"
            //
            // keys: 
            // roles - inmate mechanic medic guard
            //  inmate - name, start_date, crime, class, shocks
            //  guard - name, star_date
            //  medic - name, start_date, specialty
            //  mechanic - name, start_date
            // _name_
            // _start_date_
            
            //sayDebug("http_response got message from server: " + message);
            
            list list1 = llJson2List(message);
            
            // debug the first-level list
            integer i;
            //sayDebug("------------------------------");
            //sayDebug("http_response first-level list");
            for (i=0; i < llGetListLength(list1); i++){
                string item = llList2String(list1,i);
                //sayDebug("list1 item "+(string)i+":"+item);
            }
            
            // find the canonical name: first finr the _name_ key
            integer nameIndex = llListFindList(list1, ["_name_"]);
            if (nameIndex < 0) {
                sayDebug("Error: did not find key _name_ in returned JSON");
                displayCentered("Key Error");
                return;
                }
            string nameInDB = llList2String(list1, nameIndex+1);
            string ownerName = llKey2Name(llGetOwner());
            if (nameInDB != ownerName) {
                sayDebug("Error: returned name "+nameInDB+" did not match owner name "+ownerName);
                displayCentered("Name Error");
                return;
                }
            
            // find the roles. 
            integer rolesIndex = llListFindList(list1, ["roles"]);
            list list2 = llJson2List(llList2String(list1, rolesIndex+1));
            //sayDebug("------------------------------");
            //sayDebug("http_response second-level list");
            for (i=0; i < llGetListLength(list2); i=i+2){
                string item = llList2String(list2,i);
                list list3 = llJson2List(llList2String(list2,i+1));
                //sayDebug("raw list3:"+(string)list3);
                
                string registrationNumber = llList2String(list3,0);
                //sayDebug("registrationNumber="+registrationNumber);
                list list4 =llJson2List(llList2String(list3,1));
                
                integer j;
                for (j = 0; j < llGetListLength(list4); j=j+2){
                    string theKey = llList2String(list4,j);
                    string theValue = llList2String(list4,j+1);
                    //sayDebug("Key:"+theKey+"="+theValue);
                }
                
                name = getListThing(list4, "name");
                start_date = getListThing(list4, "start_date");
                
                if (item == "inmate") {
                    crime = getListThing(list4, "crime");
                    class = getListThing(list4, "class");
                    shocks = getListThing(list4, "shocks");
                    sayDebug("inmate "+name+" "+registrationNumber+" Class:"+class+" Crime:"+crime+" "+shocks+" shocks "+start_date);
                } else if (item == "guard") {
                    rank = getListThing(list4, "rank");
                    sayDebug("guard "+rank+" "+name+" "+registrationNumber+" "+start_date);
                } else if (item == "medic") {
                    specialty = getListThing(list4, "specialty");
                    sayDebug("medic "+name+" "+specialty+" "+registrationNumber+" "+start_date);
                } else if (item == "mechanic") {
                    sayDebug("mechanic "+name+" "+registrationNumber+" "+start_date);
                } else if (item == "robot") {
                    sayDebug("robot "+name+" "+registrationNumber+" "+start_date);
                }
                
            }
                

            
            string number = "P-00000";
            displayCentered(number);
                // test the scrolling display function
                //displayScroll(number+" *"+name+"* "+crime+". ");

        }
    }
    
    link_message( integer sender_num, integer num, string message, key id ){ 
        sayDebug("link_message "+(string)num+" "+message);

        // IC/OOC Mood sets frame color
        if (num == 1100) {
            Mood = message;
            integer moodi = llListFindList(moodNames, [Mood]);
            vector moodColor = llList2Vector(moodColors, moodi);
            llSetLinkPrimitiveParamsFast(LinkAlphanumFrame,[PRIM_COLOR, FaceAlphanumFrame, moodColor, 1.0]);
            llSetLinkPrimitiveParamsFast(LinkAlphanumFrame, [PRIM_GLOW, FaceAlphanumFrame, 0.3]);
        }
        
        // Prisoner Class sets text color and blinky 3
        else if (num == 1200) {
            Class = message;
            integer classi = llListFindList(classNames, [Class]);
            classColor = llList2Vector(classColors, classi);
            setTextColor(classColor);
            // set the blinky color
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinky3, classColor, 1.0]);
            
            // set the collar frame texture, reflectivity, and bumpiness
            llSetPrimitiveParams([PRIM_TEXTURE, FaceFrame, llList2Key(classTextures, classi), <1,1,0>, <0,0,0>, 0]);
            llSetPrimitiveParams([PRIM_SPECULAR, FaceFrame, llList2Key(classSpeculars, classi), <1,1,0>, <0,0,0>, 0, <1,1,1>,255, 75]);
            llSetPrimitiveParams([PRIM_NORMAL, FaceFrame, llList2Key(classBumpmaps, classi), <1,1,0>, <0,0,0>, 0]);
            }
        
        // Zap Level sets blinky 1
        else if (num == 1300) {
            // message contains a json list of settings
            sayDebug("zaplevel message:"+message);
            list zapLevels = llJson2List(message);
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
            list threatLevels = ["None", "Moderate", "Dangerous", "Extreme"];
            list threatColors = [GREEN, YELLOW, ORANGE, RED];
            integer threati = llListFindList(threatLevels, [message]);
            vector threatcolor = llList2Vector(threatColors, threati);
            sayDebug("threat level message:"+message+" threati:"+(string)threati+" threatcolor:"+(string)threatcolor);
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinky4, threatcolor, 1.0]);
        }
        
        // Lock level sets blinky 2
        else if (num == 1400) {
            list threatLevels = ["Safeword", "Off", "Light", "Medium", "Heavy", "Hardcore"];
            list threatColors = [GREEN, BLACK, GREEN, YELLOW, ORANGE, RED];
            integer threati = llListFindList(threatLevels, [message]);
            vector threatcolor = llList2Vector(threatColors, threati);
            sayDebug("threat level message:"+message+" threati:"+(string)threati+" threatcolor:"+(string)threatcolor);
            llSetLinkPrimitiveParamsFast(LinkBlinky,[PRIM_COLOR, FaceBlinky2, threatcolor, 1.0]);
        }
        
        // Battery Level Report
        else if (num == 1700) {
            sayDebug("link_message "+(string)num+" "+message);
            sayDebug("battery "+message);
            displayBattery((integer)message);
        }
        
        // Someone wants database update
        else if (num == 2002) {
            sayDebug("link_message "+(string)num+" "+message);
            sendDatabaseQuery();
        }
    }
}
