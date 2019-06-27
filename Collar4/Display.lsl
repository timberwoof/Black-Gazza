key crimeRequest;
string scrollText;
integer scrollPos;
integer scrollLimit;
string fontID = "fc55ee0b-62b5-667c-043d-46d822249ee0";
    
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
        letter =  llGetSubString(text,i,i); 
        j = llSubStringIndex(textMap,letter);
        integer ix = (j % 10);
        float x = ix * 0.1 + .05;

        integer iy = 7 - j / 10;
        float y = iy * 0.1429;

        integer linkNumber = 15 - i;
        llSetLinkPrimitiveParamsFast(linkNumber,[PRIM_TEXTURE, 0, fontID, <0.1, 0.15, 0.0>, <x, y, 0.0>, 0.0]);
    }
}




displayCentered(string text){
    string displayText = "            "; // 12 spaces
    integer pad = (12 - llStringLength(text)) / 2;
    displayText(llInsertString(displayText, pad, llToUpper(text)));
    //llMessageLinked(LINK_ALL_CHILDREN, 555, displayText, "");   
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
        //llMessageLinked(LINK_ALL_CHILDREN, 555, "INITIALIZING", "");
        displayText("INITIALIZING");
        llSleep(2);
        displayText("*0123456789*");
        llSleep(2);
        displayText("*ABCDEFGHIJ*");
        llSleep(2);
        displayText("*KLMNOPQRST*");
        llSleep(2);
        displayText("*UVWXYZabcd*");
        llSleep(2);
        displayText("*efghijklmn*");
        llSleep(2);
        displayText("*opqrstuvwx*");
        llSleep(2);
        displayText("*yz .,:;-#**");
        llSleep(2);
        string URL = "http://sl.blackgazza.com/read_inmate.cgi?key=" + (string)llGetOwner();
        crimeRequest= llHTTPRequest(URL,[],"");
        
    }

    http_response( key request_id, integer status, list metadata, string body )
    {
        if (status == 200) {
            // body looks like Timberwoof Lupindo,0,Piracy,284ba63f-378b-4be6-84d9-10db6ae48b8d,P-60361
            list returned = llParseString2List(body, [","], []);
            string name = llList2String(returned, 0);
            string crime = llList2String(returned, 2);
            string theKey = llList2Key(returned, 3);
            string number = llList2String(returned, 4);
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
        displayText(llGetSubString(scrollText, scrollPos, scrollPos+12) + "            ");
        //llMessageLinked(LINK_ALL_CHILDREN, 555, displayText, "");  
        scrollPos = scrollPos + 1;
        if (scrollPos >= scrollLimit) {
            scrollPos = 0;
        }
    }
}
