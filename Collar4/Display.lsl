// Display.lsl
// Display script for Black Gazza Collar 4
// Timberwoof Lupindo
// June 2019

// This script handles all display elements of Black Gazza Collar 4.
// • alphanumeric display
// • blinky lights
// • battery display

key crimeRequest;
string scrollText;
integer scrollPos;
integer scrollLimit;
string fontID = "fc55ee0b-62b5-667c-043d-46d822249ee0";
    
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
        llSetLinkPrimitiveParamsFast(linkNumber,[PRIM_TEXTURE, 0, fontID, <0.1, 0.15, 0.0>, <x, y, 0.0>, 0.0]);
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
    llSetTimerEvent(0.5);
}

default
{
    state_entry()
    {
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
            displayText(number);
            
            // this tests the scrolling display function
            if (theKey == llGetOwner()) {
                displayScroll(number+" *"+name+"* "+crime+". ");
            }
            else {
                displayCentered("Key Error");
            }
        }
        else {
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
    }
}
