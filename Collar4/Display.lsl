key crimeRequest;
string scrollText;
integer scrollPos;
integer scrollLimit;
string fontID = "c25aac96-92e1-e27e-670a-b8f34946f5cb";
    
displayText(string text){
    llWhisper(0,"displayText("+text+")");
    string textMap = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz .,:;-#*";
    integer i;
    integer j;
    string letter;
    for (i = 0; i < 12; i++){
        letter =  llGetSubString(text,i,i); 
        j = llSubStringIndex(textMap,letter);
        integer ix = (j % 10);
        if (ix < 5) ix = ix + 5;
        else ix = ix - 5;
        float x = ix * 0.1;

        integer iy = 7 - j / 7;
        if (iy < 4) iy = iy + 4;
        else iy = iy - 4;
        float y = iy * 0.14;

        integer linkNumber = 15 - i;
        llWhisper(0,(string)linkNumber+" "+letter+" "+(string)j+" "+(string)x+" "+(string)y);
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
    llSetTimerEvent(1);
}

default
{
    state_entry()
    {
        //llMessageLinked(LINK_ALL_CHILDREN, 555, "INITIALIZING", "");
        //displayText("INITIALIZING");
        //string URL = "http://sl.blackgazza.com/read_inmate.cgi?key=" + (string)llGetOwner();
        //crimeRequest= llHTTPRequest(URL,[],"");
        displayText("001234567899");
        //llSleep(10);
        //displayText("ABCDEFGHIJAB");
        //llSleep(10);
        //displayText("KLMNOPQRSTKL");
        //llSleep(10);
        //displayText("UVWXYZabcdUV");
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
                displayCentered(crime);
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
