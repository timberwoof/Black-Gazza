// Speech.lsl
// Speech script for Black Gazza Collar 4
// Timberwoof Lupindo
// March 2020
// version: 2020-04-11

// Handles all speech-related functions for the collar
// Renamer - Gag - Bad Words 

integer OPTION_DEBUG = 0;

string assetNumber;

integer rlvPresent = 0;
string prisonerLockLevel = "";
integer renamerActive = 0;
integer renameSpeechChannel = 0;
integer renameSpeechListen = 0;
integer renameEmoteChannel = 0;
integer renameEmoteListen = 0;
integer textboxChannel = 0;
integer textboxListen = 0;

integer DisplayTokActive = 0;
integer badWordsActive = 0;
integer gagActive = 0;

integer speechPenaltyDisplay = 0;
integer speechPenaltyGarbleWord = 0;
integer speechPenaltyGarbleTime = 0;
integer speechPenaltyBuzz = 0;
integer speechPenaltyZap = 0;

integer batteryLevel = 0;

list badWords;
list listWordsSpoken; // needed globally for displaytok
integer numWordsSpoken = 0; // needed globally for displaytok
integer numWordsDisplayed = 0;
string stringWordsSpoken;
integer numTimesToZap = 0;
integer numTimesToBuzz = 0;

// Basic drug-induced Muffling
list SimpleIn = [];
list SimpleOut = [];
list BlendIn = [];
list BlendOut = [];

// slurd
list slurdSimpleIn  = ["f","k","p","s","t","x"];
list slurdSimpleOut = ["v","g","p","z","d","gs"]; 
//
list slurdBlendIn =  ["ca","ce","ci","co","cu","cy","ch","qu","sh","th","ph"];
list slurdBlendOut = ["ga","ze","zi","go","gu","zy","j", "gw","j", "dh", "v"];

// hairlift
list hairliftSimpleIn  = ["B","b","P","p","M","m"];
list hairliftSimpleOut = ["V","v","F","f","V","v"]; 

// thfeech imfedivent (hairlift + cathtillian + more evil
list imfediventSimpleIn  = ["B","b","P","p","M","m","S","s","Z","z"];
list imfediventSimpleOut = ["V","v","F","f","V","v","Th","th","Th","th"]; 

list imfediventBlendIn =  ["ch","sh","Ch","Sh"];
list imfediventBlendOut = ["sl","sl","Sl","Sl"];

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

// throat
list ThroatSimpleIn  = ["k","g"];
list ThroatSimpleOut = ["h","h"]; 
//
list ThroatBlendIn =  ["ca","ce","ci","co","cu","cy","ch","qu","sh","th","ph"];
list ThroatBlendOut = ["ga","ze","zi","go","gu","zy","j", "gw","j", "dh", "v"];

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

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Speech:"+message);
    }
}

sendJSONinteger(string jsonKey, integer value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, (string)value]), avatarKey);
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
    
integer getJSONinteger(string jsonValue, string jsonKey, integer valueNow){
    integer result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = (integer)value;
        }
    return result;
    }

processSpeech(string speech, key avatarKey){
    if (badWordsActive | DisplayTokActive) {
        sayDebug("processSpeech listWordsSpoken");
        listWordsSpoken = llParseString2List(llToLower(speech), 
            [" "], [",", ".", ";", ":", "!", "?", "'", "\""]);
        numWordsSpoken = llGetListLength(listWordsSpoken);
    }
        
    // parse the speech for bad words
    if(badWordsActive) {
        sayDebug("processSpeech badWordsActive");
        integer countBadWords = 0;
        integer i;
        for (i = 0; i < numWordsSpoken; i++) {
            string aWord = llList2String(listWordsSpoken, i);
            integer where = llListFindList(badWords, [aWord]);
            if (where >= 0) {
                countBadWords++;
                // *** replace words for displaytok here
                
                if (speechPenaltyGarbleWord) {
                }
            }
        }
        sayDebug("detected "+(string)countBadWords+" bad words");
        
        if (countBadWords > 0) {
            // inform Display
            sendJSONinteger("badWordCount", countBadWords, avatarKey);
            
            if (speechPenaltyBuzz) {
                numTimesToBuzz = countBadWords;
                llSetTimerEvent(3); // start the buzz cycle
            }
            if (speechPenaltyZap) {
                numTimesToZap = countBadWords;
                llSetTimerEvent(3); // start the zap cycle
            }
        }
    }
    
    if(DisplayTokActive) {
        //if (batteryLevel > 0) {
            sayDebug("processSpeech DisplayTokActive");
            string firstWord = llList2String(listWordsSpoken, 0);
            sendJSON("DisplayTemp", firstWord, "");
            numWordsDisplayed = 1;
            stringWordsSpoken = firstWord;
            llSetTimerEvent(1); // start the display cycle
        //} else {
        //    sayDebug("processSpeech DisplayTokActive batterylevel:"+(string)batteryLevel);
        //    sendJSON("DisplayTemp", "---", "");
        //}
    } else {
        llSay(0,speech);
    }
    
}

sendRLVRestrictCommand(string why) {
    renameSpeechChannel = llFloor(llFrand(10000)+1000);
    renameSpeechListen = llListen(renameSpeechChannel, "", llGetOwner(), "");
    renameEmoteChannel = llFloor(llFrand(10000)+1000);
    renameEmoteListen = llListen(renameEmoteChannel, "", llGetOwner(), "");
    string rlvcommand;
    rlvcommand = "@redirchat:"+(string)renameSpeechChannel+"=add,rediremote:"+(string)renameEmoteChannel+"=add";
    sayDebug("sendRLVRestrictCommand "+why+" rlvcommand:"+rlvcommand);
    llOwnerSay(rlvcommand);
    renamerActive = 1;
}

sendRLVReleaseCommand(string why) {
    string rlvcommand = "@redirchat:"+(string)renameSpeechChannel+"=rem,rediremote:"+(string)renameEmoteChannel+"=rem";
    sayDebug("sendRLVReleaseCommand "+why+" rlvcommand:"+rlvcommand);
    llOwnerSay(rlvcommand);
    llListenRemove(renameSpeechChannel);
    renameSpeechChannel = 0;
    renameEmoteListen = 0;
    renamerActive = 0;
}

default
{
    state_entry() // reset
    {
        string ownerName = llToLower(llKey2Name(llGetOwner()));
        string displayName = llToLower(llGetDisplayName(llGetOwner()));
        if (ownerName != displayName) {
            ownerName = ownerName + " " + displayName;
        }
        badWords = llParseString2List(ownerName, [" "], [""]);
        badWords = badWords + ["pink","fluffy","unicorns","dancing","rainbows"];
        makeindex();
    }

     attach(key id) // log in
     {
        if (id) {
            sayDebug("attach");
            sayDebug("attach done");
        } else {
            sayDebug("detach");
            sayDebug("detach done");
        }
    }

    link_message(integer sender_num, integer num, string json, key avatarKey){
        string speechCommand = getJSONstring(json, "Speech", "");
        if (speechCommand == "WordList") {
            string badWordString = llDumpList2String(badWords,", ");
            string message = "The bad word list is\n"+badWordString+"\n\n"+
                "Add or remove bad words with\n"+
                "badWordToAdd -badWordToRemove";
            textboxChannel = -llFloor(llFrand(10000)+1000);
            textboxListen = llListen(textboxChannel, "", avatarKey, "");
            llTextBox(avatarKey, message, textboxChannel);
            llSetTimerEvent(30);
        }
        if (speechCommand == "RenamerOFF"){
            sendRLVReleaseCommand("link_message RenamerOFF");
        }
        if (speechCommand == "RenamerON") {
            if (prisonerLockLevel != "Off") {
                sendRLVReleaseCommand("link_message RenamerON");
                sendRLVRestrictCommand("link_message RenamerON");
            }
        }
        if (speechCommand == "resetRenamer") {
            if (renamerActive == 1) {
                sendRLVReleaseCommand("link_message resetRenamer");
                sendRLVRestrictCommand("link_message resetRenamer");
            }
        }
        if (speechCommand == "BadWordsOFF") {
            badWordsActive = 0;
        } else if (speechCommand == "BadWordsON") {
            badWordsActive = 1;
        } else  if (speechCommand == "GagOFF") {
            gagActive = 0;
        } else if (speechCommand == "GagON") {
            gagActive = 1;
        } else  if (speechCommand == "DisplayTokOFF") {
            DisplayTokActive = 0;
        } else if (speechCommand == "DisplayTokON") {
            DisplayTokActive = 1;
        }
        
        string penaltyCommand = getJSONstring(json, "Penalties", "");
        if (penaltyCommand == "DisplayON") {
            speechPenaltyDisplay = 1;
        } else if (penaltyCommand == "DisplayOFF") {
            speechPenaltyDisplay = 0;
        } else if (penaltyCommand == "GarbleWordON") {
            speechPenaltyGarbleWord = 1;
        } else if (penaltyCommand == "GarbleWordOFF") {
            speechPenaltyGarbleWord = 0;
        } else if (penaltyCommand == "GarbleTimeON") {
            speechPenaltyGarbleTime = 1;
        } else if (penaltyCommand == "GarbleTimeOFF") {
            speechPenaltyGarbleTime = 0;
        } else if (penaltyCommand == "BuzzON") {
            speechPenaltyBuzz = 1;
        } else if (penaltyCommand == "BuzzOFF") {
            speechPenaltyBuzz = 0;
        } else if (penaltyCommand == "ZapON") {
            speechPenaltyZap = 1;
        } else if (penaltyCommand == "ZapOFF") {
            speechPenaltyZap = 0;
        }

        prisonerLockLevel = getJSONstring(json, "prisonerLockLevel", prisonerLockLevel);
        string RLVCommand = getJSONstring(json, "prisonerLockLevel", "");
        if (RLVCommand == "Off") {
            sendRLVReleaseCommand("link_message prisonerLockLevel OFF");
            DisplayTokActive = 0;
            badWordsActive = 0;
            gagActive = 0;
            renamerActive = 0;
        }
        rlvPresent = getJSONinteger(json, "rlvPresent", rlvPresent);
                
        string assetCommand = getJSONstring(json, "assetNumber", "");
        if (assetCommand != "") {
            assetNumber = assetCommand;
            sayDebug("link_message set assetNumber"+assetNumber);
        }
        
        batteryLevel = getJSONinteger(json, "batteryLevel", batteryLevel);
    }
    
    listen(integer channel, string name, key avatarKey, string message){
        // handle player's redirected speech
        if (channel == renameSpeechChannel) {
            processSpeech(message, avatarKey);
        }
        
        // handle player's emotes
        if (channel == renameEmoteChannel) {
            llSay(0,message);
            }
            
        // handle the bad word list dialog
        if (channel == textboxChannel) {
            sayDebug("listen "+message);
            list incomingWords = llParseString2List(llToLower(message), [" ", ","], [""]);
            integer i;
            for (i = 0; i < llGetListLength(incomingWords); i++) {
                string word = llList2String(incomingWords, i);
                sayDebug("listen processing '"+word+"'");
                if (llGetSubString(word, 0, 0) != "-") {
                    // adding the word
                    sayDebug("listen searching for '"+word+"' for add");
                    integer j = llListFindList(badWords, [word]);
                    if (j < 0) {
                        // not already there
                        sayDebug("listen adding '"+word+"'");
                        badWords = badWords + [word];
                    } else {
                        sayDebug("listen '"+word+"' was already in the list");
                    }
                } else {
                    // removing the word
                    word = llGetSubString(word, 1, -1);
                    sayDebug("listen searching for '"+word+"' for remove");
                    integer j = llListFindList(badWords, [word]);
                    if (j < 0) {
                        // not already where
                        sayDebug("listen '"+word+"' was not in the list");
                    } else {
                        sayDebug("listen removing "+word);
                        badWords = llListReplaceList(badWords, [], j, j);
                    }
                }
            }
        }
    }
        
    timer() {
        sayDebug("timer");
        if (DisplayTokActive & numWordsDisplayed < numWordsSpoken) {
            string nextWord = llList2String(listWordsSpoken, numWordsDisplayed);
            numWordsDisplayed = numWordsDisplayed + 1;
            sendJSON("DisplayTemp", nextWord, "");
            stringWordsSpoken = stringWordsSpoken + " " + nextWord;
        }
        if (speechPenaltyZap & numTimesToZap > 0) {
            sendJSON("RLV", "Zap Low", llGetOwner());
            numTimesToZap = numTimesToZap - 1;
        }
        if (speechPenaltyBuzz & numTimesToBuzz > 0) {
            llPlaySound("d679e663-bba3-9caa-08f7-878f65966194",1);
            numTimesToBuzz = numTimesToBuzz -1;
        }
        if (DisplayTokActive & stringWordsSpoken != "") {
            llSay(0,"'s collar display reads: " + stringWordsSpoken);
            stringWordsSpoken = "";
            llSetTimerEvent(0);
        }
        if (numTimesToZap == 0 & numTimesToBuzz == 0) {
            llSetTimerEvent(0);
        }
        if (textboxListen != 0) {
            llListenRemove(textboxListen);
            textboxListen = 0;
            textboxChannel = 0;
        }
    }
}
