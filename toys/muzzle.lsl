key avatarKey;

integer menuChannel;
integer menuHandle;
string level;

integer modeChannel;
integer modeHandle;

integer muzzleChannel;
integer muzzleHandle;


list SimpleIn = [];
list SimpleOut = [];
list BlendIn = [];
list BlendOut = [];

string intro = "";

// severe muffling
list severeSimpleIn  = ["a","e","i","o","u","y","w", "b","d","f","g","h","j","k","l","m","n","p","r","s","t","v","x", "z"];
list severeSimpleOut = ["u","u","u","u","u","u","u", "g","g","f","g","f","g","k","m","m","m","k","m","f","k","m","kf","f"]; 
//
list severeBlendIn =  ["ca","ce","ci","co","cu","cy","ch","qu","sh","th","ph"];
list severeBlendOut = ["ku","fu","fu","ku","ku","fu","f", "k", "f", "f", "f"];

// bit
list bitSimpleIn  = ["a","e","i","o","u","y","w", "b","d","f","g","h","j","k","l","m","n","p","r","s","t","v","x", "z"];
list bitSimpleOut = ["a","e","i","o","u","y","w", "bw","d","fw","g","h","j","kh","l","m","ng","pw","r","sh","t","vw","xsh","zh"]; 


// slurd
list slurdSimpleIn  = ["f","k","p","s","t","x"];
list slurdSimpleOut = ["v","g","p","z","d","gs"]; 
//
list slurdBlendIn =  ["ca","ce","ci","co","cu","cy","ch","qu","sh","th","ph"];
list slurdBlendOut = ["ga","ze","zi","go","gu","zy","j", "gw","j", "dh", "v"];


// sagarass
list sagafrassSimpleIn  = ["a","e","i","o","u","y","w", "b","d","f","g","h","j","k","l","m","n","p","r","s","t","v","x","z",".","!","?"];
list sagafrassSimpleOut = ["", "", "", "", "", "", "",  "bagga","dagga","fagga","gagga","hagga","jagga","kagga","lagga","magga",
    "nagga","pagga","ragga","sagga","tagga","vagga","sagga","zagga","frass.","frass!","frass?"]; 
//
list sagafrassBlendIn =  ["ca","ce","ci","co","cu","cy","ch","qu","sh","th","ph"];
list sagafrassBlendOut = ["kagga","sagga","sagga","kagga","kagga","sagga","chagga", "quagga","shagga", "thagga", "fagga"];

// hairlift
list hairliftSimpleIn  = ["B","b","P","p","M","m"];
list hairliftSimpleOut = ["V","v","F","f","V","v"]; 
//
list noneBlendIn =  [];
list noneBlendOut = [];

//cathtilian
list cathtilianSimpleIn  = ["S","s","Z","z","X","x"];
list cathtilianSimpleOut = ["Th","th","Th","th","Kth","kth"]; 
//
//list BlendIn =  [];
//list BlendOut = [];

// thfeech imfedivent (hairlift + cathtillian + more evil
list imfediventSimpleIn  = ["B","b","P","p","M","m","S","s","Z","z"];
list imfediventSimpleOut = ["V","v","F","f","V","v","Th","th","Th","th"]; 

list imfediventBlendIn =  ["ch","sh","Ch","Sh"];
list imfediventBlendOut = ["sl","sl","Sl","Sl"];

// facecloth: labials become fricatives, plosives become voiceless unarticulated stops
list faceclothSimpleIn  = ["a","e","i","o","u","y","w", "b","d","f","g","h","j","k","l","m","n","p","r","s","t","v","x", "z"];
list faceclothSimpleOut = ["a","e","i","o","u","y","w", "v","v","h","h","h","j","-","l","m","n","-","r","h","-","h","k","h"]; 
//
list faceclothBlendIn =  ["ca","ce","ci","co","cu","cy","ch","qu","sh","th","ph"];
list faceclothBlendOut = ["-a","he","hi","-o","-u","hy","h", "-", "h", "h", "h"];

// dog
list dogSimpleIn  = ["a","e","i","o","u","y","w", "b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","x","z"];
list dogSimpleOut = ["arf ","erf ","yip ","bow ","wow ","yip ","aroo ", "","","","","","","","","","","","","","","","","",""]; 
//
//list BlendIn =  [];
//list BlendOut = [];

// cat
list catSimpleIn  = ["a","e","i","o","u","y","w", "b","c","d","f","g","h","j","k","l","m","n","p","r","s","t","v","x","z"];
list catSimpleOut = ["maw ","mew ","miw ","mow ","meuw ","miaow ","miaow ", "","","","","","","","","","","","","","","","","","",""]; 
//
//list BlendIn =  [];
//list BlendOut = [];

list raccoonSimpleIn  = ["a","e","i","o","u","y","w", "b","c","d","f","g","h","j","k","l","m","n","p","r","s","t","v","x","z"];
list raccoonSimpleOut = ["chatter ","chettter ","chitter ","chotter ","chutter ","chytter ","", "","","","","","","","","","","","","","","","","","",""]; 

// SoundShift
list SoundShiftSimpleIn  = ["a","e","i","o","u","y","w", "b","d","f","g","h","j","k","l","m","n","p","r","s","t","v","x", "z"];
list SoundShiftSimpleOut = ["e","i","a","w","o","u","y", "d","g","th","g","g","j","k","l","n","m","t","r","s","p","th","x","z"]; 
//
list SoundShiftBlendIn =  ["th","ph"];
list SoundShiftBlendOut = ["f", "th"];


// common cole
list CobbodCodeSimpleIn  = ["m","n","v"];
list CobbodCodeSimpleOut = ["b","d","b"]; 
//
list CobbodCodeBlendIn =  ["ng","th"];
list CobbodCodeBlendOut = ["g","d"];



// lips
list LipsSimpleIn  = ["p","b","f","v","m"];
list LipsSimpleOut = ["h","h","h","h","ng"]; 
//
list LipsBlendIn =  ["ph"];
list LipsBlendOut = ["h"];

// tongue
list TongueSimpleIn  = ["t","d","s","z","n"];
list TongueSimpleOut = ["ch","g","ch","j","ng"]; 
//
list TongueBlendIn =  ["th","sh","ch"];
list TongueBlendOut = ["ga","ze","zi"];

// tongue
list LipsTongueSimpleIn  = [];
list LipsTongueSimpleOut = [];
//
list LipsTongueBlendIn =  [];
list LipsTongueBlendOut = [];


// throat
list ThroatSimpleIn  = ["k","g"];
list ThroatSimpleOut = ["h","h"]; 
//
list ThroatBlendIn =  ["ca","ce","ci","co","cu","cy","ch","qu","sh","th","ph"];
list ThroatBlendOut = ["ga","ze","zi","go","gu","zy","j", "gw","j", "dh", "v"];

// mouth
list MouthSimpleIn  = ["a","e","i","o","u","y","I"];
list MouthSimpleOut = ["uh","uh","uh","uh","uh","uh","uh"]; 
//
list MouthBlendIn =  ["ae","ai","ao","au","aw","ay",
                    "ea","ei","eo","eo","ey",
                    "ia","ie","io","iu",
                    "oa","oe","oi","oo","ou","oy",
                    "ua","ue","ui","uo","uy"];
list MouthBlendOut = ["uh","uh","uh","uh","uh","uh",
                    "uh","uh","uh","uh","uh",
                    "uh","uh","uh","uh",
                    "uh","uh","uh","uh","uh","uh",
                    "uh","uh","uh","uh","uh"];




list BlendIndex = [];

makeindex() {
    // make an index of the ist of two-letter substitutions
    BlendIndex = [];
    integer inputLength = llGetListLength(BlendIn);
    integer index;
    for (index == 0; index < inputLength; index++) {
         BlendIndex += [llGetSubString(llList2String(BlendIn, index),0,0)];
    }    
}

string replace (string input)
{
    integer inputLength;
    integer inputIndex = 0;
    integer listIndex; 
    string output = ""; //"mumbles, \"";

    inputLength = llStringLength(input);
    while (inputIndex < inputLength){
        // get the character and eat it
        string inchar = llGetSubString(input, inputIndex, inputIndex++);
        
        // default is this character
        string outchar = inchar;
        
        // is it the first letter of a pair? 
        listIndex = llListFindList( BlendIndex, [inchar]);
        if (listIndex >= 0) {   // yes
            string twochar = inchar + llGetSubString(input, inputIndex, inputIndex);    // get the next letter
            listIndex = llListFindList(BlendIn, [twochar]);    // look up the pair in the BlendIn list
            if (listIndex >= 0) {
                outchar = llList2String(BlendOut, listIndex);    // add the resulting letter form the BlendOut list
                //llWhisper(0,"pair " + twochar + "->" + outchar);    // debug
                inputIndex ++; // eat the character
            } 
        }

        if (outchar == inchar) {
            // no, it is not a pair
            // find it in the single-letter subtitution list
            listIndex = llListFindList(SimpleIn, [inchar]);       // look the letter up in the single list
            if (listIndex >= 0) {
                // found it
                outchar = llList2String(SimpleOut, listIndex);  // add the resulting letter form the BlendOut list
                //llWhisper(0,"single " + inchar + "->" + outchar);    // debug
            }
        }
        // add the character(s) to the string
        output += outchar;   
    }     
    //output += "\"";
    //return input + " => " + output; //  
    return output; //  
}

setoff(){
    level = "OFF";
    llOwnerSay("@clear");
    saylevel();
}

setloose(){
    level = "LOOSE";
    llOwnerSay("@chatshout=n");
    llOwnerSay("@redirchat:" + (string)muzzleChannel + "=add");
    saylevel();
}

settight(){
    level = "TIGHT";
    llOwnerSay("@chatshout=n");
    llOwnerSay("@chatnormal=n");
    llOwnerSay("@redirchat:" + (string)muzzleChannel + "=add");
    saylevel();
}

setmax(){
    level = "MAX";
    llOwnerSay("@chatshout=n");
    llOwnerSay("@chatnormal=n");
    llOwnerSay("@chatwhisper=n");
    saylevel();
}


saylevel()
{
    //llSay(0,"Level: " + level);
}
init() {
    level = "OFF";
    llOwnerSay("@clear");
    makeindex();
    muzzleChannel = (integer)llFrand(8999)+1000;
    muzzleHandle = llListen(muzzleChannel,"","","");
    
    // tongue
    LipsTongueSimpleIn  = LipsSimpleIn + TongueSimpleIn;
    LipsTongueSimpleOut = LipsSimpleOut + TongueSimpleOut;
//
    LipsTongueBlendIn =  LipsBlendIn + TongueBlendIn;
    LipsTongueBlendOut = LipsBlendOut + TongueBlendOut;


    }
    
setmode() {
    modeChannel = (integer)llFrand(8999)+1000;
    modeHandle = llListen(modeChannel,"",avatarKey,"");
    llSetTimerEvent(60);
    llDialog(avatarKey,"What mode do you want to inflict on your poor victim?",["Lips", "Tongue", "LipsTongue", "Throat", "Mouth"],modeChannel);
    }

default
{
    on_rez(integer start_param)
    {
        init();
    }
    state_entry()
    {
        init();
    }
    touch_start(integer total_number)
    {
        //llSay(0, "Touched: "+(string)total_number);
        avatarKey = llDetectedKey(0);
        menuChannel = (integer)llFrand(8999)+1000;
        menuHandle = llListen(menuChannel,"",avatarKey,"");
        llSetTimerEvent(60);
        llDialog(avatarKey,"How locked do you want it?",["Off","Loose","Tighter","Tightest","Mode"], menuChannel);
    }
    timer()
    {
        //llSay(0,"sorry, took too long!");
        llListenRemove(menuHandle);
        llListenRemove(modeHandle);
        llSetTimerEvent(0);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == menuChannel){
            if (message == "Off") {
                setoff();
            }
            else if (message =="Loose") {
                setloose();
            }
            else if (message =="Tighter") {
                settight();
            }
            else if (message =="Tighest") {
                setmax();
            }
            else if (message == "Mode") {
                setmode();
            }
            llSetTimerEvent(0);
            llListenRemove(menuHandle);
        }
        else if (channel == modeChannel) {
            llWhisper(0,"setting filter to " + message);
            if (message == "Severe") {
                SimpleIn = severeSimpleIn;
                SimpleOut = severeSimpleOut;
                BlendIn = severeBlendIn;
                BlendOut = severeBlendOut;
                makeindex();
            }
            else if (message == "Hareliffed") {
                SimpleIn = hairliftSimpleIn;
                SimpleOut = hairliftSimpleOut;
                BlendIn = noneBlendIn;
                BlendOut = noneBlendOut;
                makeindex();
            }
            else if (message == "Cathtilian") {
                SimpleIn = cathtilianSimpleIn;
                SimpleOut = cathtilianSimpleOut;
                BlendIn = noneBlendIn;
                BlendOut = noneBlendOut;
                makeindex();
            }
            else if (message == "Imfedivent") {
                SimpleIn = imfediventSimpleIn;
                SimpleOut = imfediventSimpleOut;
                BlendIn = imfediventBlendIn;
                BlendOut = imfediventBlendOut;
                makeindex();
            }
            else if (message == "Facecloth") {
                SimpleIn = faceclothSimpleIn;
                SimpleOut = faceclothSimpleOut;
                BlendIn = faceclothBlendIn;
                BlendOut = faceclothBlendOut;
                makeindex();
            }
            else if (message == "Dog") {
                SimpleIn = dogSimpleIn;
                SimpleOut = dogSimpleOut;
                BlendIn = noneBlendIn;
                BlendOut = noneBlendOut;
                makeindex();
            }
            else if (message == "Cat") {
                SimpleIn = catSimpleIn;
                SimpleOut = catSimpleOut;
                BlendIn = noneBlendIn;
                BlendOut = noneBlendOut;
                makeindex();
            }
            else if (message == "Raccoon") {
                SimpleIn = raccoonSimpleIn;
                SimpleOut = raccoonSimpleOut;
                BlendIn = noneBlendIn;
                BlendOut = noneBlendOut;
                makeindex();
            }
            else if (message == "Bit") {
                SimpleIn = bitSimpleIn;
                SimpleOut = bitSimpleOut;
                BlendIn = noneBlendIn;
                BlendOut = noneBlendOut;
                makeindex();
            }
            else if (message == "Slurd") {
                SimpleIn = slurdSimpleIn;
                SimpleOut = slurdSimpleOut;
                BlendIn = slurdBlendIn;
                BlendOut = slurdBlendOut;
                makeindex();
            }
            else if (message == "Sagafrass") {
                SimpleIn = sagafrassSimpleIn;
                SimpleOut = sagafrassSimpleOut;
                BlendIn = sagafrassBlendIn;
                BlendOut = sagafrassBlendOut;
                makeindex();
            }
            else if (message == "Lips") {
                SimpleIn = LipsSimpleIn;
                SimpleOut = LipsSimpleOut;
                BlendIn = LipsBlendIn;
                BlendOut = LipsBlendOut;
                makeindex();
            }
            else if (message == "Tongue") {
                SimpleIn = TongueSimpleIn;
                SimpleOut = TongueSimpleOut;
                BlendIn = TongueBlendIn;
                BlendOut = TongueBlendOut;
                makeindex();
            }
            else if (message == "LipsTongue") {
                SimpleIn = LipsTongueSimpleIn;
                SimpleOut = LipsTongueSimpleOut;
                BlendIn = LipsTongueBlendIn;
                BlendOut = LipsTongueBlendOut;
                makeindex();
            }
            else if (message == "Throat") {
                SimpleIn = ThroatSimpleIn;
                SimpleOut = ThroatSimpleOut;
                BlendIn = ThroatBlendIn;
                BlendOut = ThroatBlendOut;
                makeindex();
            }
            else if (message == "Mouth") {
                SimpleIn = MouthSimpleIn;
                SimpleOut = MouthSimpleOut;
                BlendIn = MouthBlendIn;
                BlendOut = MouthBlendOut;
                makeindex();
            }
            llListenRemove(modeHandle);
            llSetTimerEvent(0);
        }
        else if (channel == muzzleChannel) {
            if (level = "LOOSE") {
                llSay(0,replace(message));
            } else if (level = "TIGHT") {
                llWhisper(0,replace(message));
            }
        }
    }
} 
