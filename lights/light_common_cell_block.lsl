// this script listens on a chanel for a set of key words , shine light in a cupple colors.
// created by drayiss zessinthal (moded by Dober)


// Returns TRUE if the string is a decimal
integer strIsDecimal(string str)
{
    str = llStringTrim(str, STRING_TRIM);

    integer strLen = llStringLength(str);
    if(!strLen){return FALSE;}

    if(str != (string)((integer)str)) return FALSE;

    return TRUE;
}

// "<255,255,255>"
integer strIsVector(string str)
{
    str = llStringTrim(str, STRING_TRIM);

    if(llGetSubString(str, 0, 0) != "<" || llGetSubString(str, -1, -1) != ">")
        return FALSE;

    integer commaIndex = llSubStringIndex(str, ",");

    if(commaIndex == -1 || commaIndex == 1)
        return FALSE;

    if( !strIsDecimal(llGetSubString(str, 1, commaIndex - 1)) || llGetSubString(str, commaIndex - 1, commaIndex - 1) == " " )
        return FALSE;

    str = llDeleteSubString(str, 1, commaIndex);

    commaIndex = llSubStringIndex(str, ",");

    if(commaIndex == -1 || commaIndex == 1 || commaIndex == llStringLength(str) - 2 ||
        
        !strIsDecimal(llGetSubString(str, 1, commaIndex - 1)) || llGetSubString(str, commaIndex - 1, commaIndex - 1) == " " ||
        
        !strIsDecimal(llGetSubString(str, commaIndex + 1, -2)) ||  llGetSubString(str, -2, -2) == " ")
            
            return FALSE;

    return TRUE;
}

vector rgb2sl( vector rgb )
{
    return rgb / 255;        
}

list colors = 
[
    "white", "255,255,255",
    "red", "255,0,0",
    "yellow", "255,220,0",
    "blue", "0,0,255",
    "green", "0,255,0"
];

vector findColorByName(string nameColor)
{
    return rgb2sl((vector)llList2String(colors, llListFindList(colors, [nameColor])+1));
}


default
{
    state_entry()
    {
        llSetColor(<1,1,1>, 1);
        llSetPrimitiveParams([PRIM_POINT_LIGHT, FALSE, <1,1,1>,
                            0.0, 0.0, 0.0,
                            PRIM_GLOW, ALL_SIDES, 0.0,
                            PRIM_FULLBRIGHT, 1, FALSE]);
        llListen(2,"","",""); //is the channelfor any ones controle
        llListen(-765489,"","",""); // channel for lock down
    }

    listen(integer channel, string name, key id, string message)
    {
        list items = llParseString2List(message, [" "], []);
        vector color = <1,1,1>;

        if(llList2String(items, 0) == "light")
        {
            if(llList2String(items, 1) == "off")
            {
                llSetPrimitiveParams([PRIM_POINT_LIGHT, FALSE, <1,1,1>,
                                    0.0, 0.0, 0.0,
                                    PRIM_GLOW, 1, 0.0,
                                    PRIM_FULLBRIGHT,1, FALSE]);
                llSetColor(<1,1,1>, 1);
                return;
            }
            else if(llList2String(items, 1) == "on")
            {
                color = findColorByName("white");
            }
            else if(strIsVector(llList2String(items, 1))) // /2 light <23,43,255>
            {
                color = rgb2sl((vector)llList2String(items, 1));
            }
            else return;
        }
        else if(llList2String(items, 0) == "LOCKDOWN")
        {
            color = findColorByName("red");
        }
        else if(llList2String(items, 0) == "RELEASE")
        {
            color = findColorByName("white");
        }
        else return;

        llSetPrimitiveParams([PRIM_POINT_LIGHT, TRUE, color, 1.0, 15.0, 0.75, 
        //  color of light 0 to 1.0 <r,g,b>, intensity 0 to 1.0, radius .1 to 20.0, falloff .01 to 2.0
      
                            PRIM_GLOW, 1, 0.05,//face, glow amount
                            PRIM_FULLBRIGHT, 1, TRUE]); //face, on/off  for full brite
        llSetColor(color,1 ); // <color to red>,<face>
        llPlaySound("dec4e122-f527-3004-8197-8821dc9da9ef",1);//sound uuid, loudness
    }
    
}