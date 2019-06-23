key crimeRequest;
string scrollText;
integer scrollPos;
integer scrollLimit;

displayCentered(string text){
    string displayText = "            "; // 12 spaces
    integer pad = (12 - llStringLength(text)) / 2;
    displayText = llInsertString(displayText, pad, llToUpper(text));
    llMessageLinked(LINK_ALL_CHILDREN, 555, displayText, "");   
}

displayScroll(string text){
    string displayText = "            "; // 12 spaces
    llMessageLinked(LINK_ALL_CHILDREN, 555, displayText, "");
    scrollText = llToUpper(text) + " " + llToUpper(text) + " " ;
    scrollPos = 0;
    scrollLimit = llStringLength(text);
    llSetTimerEvent(1);
}

default
{
    state_entry()
    {
        llMessageLinked(LINK_ALL_CHILDREN, 555, "INITIALIZING", "");
        string URL = "http://sl.blackgazza.com/read_inmate.cgi?key=" + (string)llGetOwner();
        crimeRequest= llHTTPRequest(URL,[],"");
        llSleep(10);
    }

    touch_start(integer total_number)
    {
        llSay(0, "Touched.");
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
                displayCentered(number);
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
        string displayText = llGetSubString(scrollText, scrollPos, scrollPos+11) + "            ";
        llMessageLinked(LINK_ALL_CHILDREN, 555, displayText, "");  
        scrollPos = scrollPos + 1;
        if (scrollPos >= scrollLimit) {
            scrollPos = 0;
        }
    }
}
