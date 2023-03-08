// Speech.lsl
// Speech script for Black Gazza Collar 4
// Timberwoof Lupindo
// March 2020
// version: 2020-11-23

// Handles all speech-related functions for the collar
// Renamer - Gag - Bad Words 

integer OPTION_DEBUG = FALSE;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Speech: "+message);
    }
}


//string prisonerLockLevel = "";
integer renameSpeechChannel = 5;
integer renameSpeechListen = 0;
integer renameEmoteChannel = 6;
integer renameEmoteListen = 0;
integer textboxChannel = 0;
integer textboxListen = 0;

integer renamerActive = FALSE;
integer DisplayTokActive = FALSE;
integer badWordsActive = FALSE;

integer speechPenaltyDisplay = FALSE;
integer speechPenaltyGarbleWord = FALSE;
integer speechPenaltyGarbleTime = FALSE;
integer speechPenaltyBuzz = FALSE;
integer speechPenaltyZap = FALSE;

integer batteryLevel = FALSE;
integer rlvPresent = FALSE;

list badWords;
list listWordsSpoken; // needed globally for displaytok
integer numWordsDisplayed = 0;
string stringWordsSpoken;
integer numTimesToZap = 0;
integer numTimesToBuzz = 0;

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
    sayDebug("processSpeech("+speech+")");
    if (badWordsActive | DisplayTokActive) {
        sayDebug("processSpeech listWordsSpoken");
        listWordsSpoken = llParseString2List(llToLower(speech), 
            [" "], [",", ".", ";", ":", "!", "?", "'", "\""]);
    }
        
    // parse the speech for bad words
    if(badWordsActive) {
        sayDebug("processSpeech badWordsActive");
        integer countBadWords = 0;
        integer i;
        
        for (i = 0; i < llGetListLength(listWordsSpoken); i++) {
            string aWord = llList2String(listWordsSpoken, i);
            integer where = llListFindList(badWords, [aWord]);
            if (where >= 0) {
                countBadWords++;
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
        sayDebug("processSpeech DisplayTokActive(\""+speech+"\")");
        stringWordsSpoken = "";
        llSetTimerEvent(1); // start the display cycle
    } else {
        llSay(0,speech);
    }
    
}

sendRLVRestrictCommand(string why) {
    renameSpeechListen = llListen(renameSpeechChannel, llKey2Name(llGetOwner()), llGetOwner(), "");
    renameEmoteListen = llListen(renameEmoteChannel, llKey2Name(llGetOwner()), llGetOwner(), "");
    string rlvcommand = "@redirchat:"+(string)renameSpeechChannel+"=add,rediremote:"+(string)renameEmoteChannel+"=add";
    sayDebug("sendRLVRestrictCommand "+why+" rlvcommand:"+rlvcommand);
    llOwnerSay(rlvcommand);
    renamerActive  = TRUE;
}

sendRLVReleaseCommand(string why) {
    llListenRemove(renameSpeechListen);
    llListenRemove(renameEmoteListen);
    string rlvcommand = "@redirchat:"+(string)renameSpeechChannel+"=rem,rediremote:"+(string)renameEmoteChannel+"=rem";
    sayDebug("sendRLVReleaseCommand "+why+" rlvcommand:"+rlvcommand);
    llOwnerSay(rlvcommand);
    renamerActive = FALSE;
}

default
{
    state_entry() // reset
    {
        sayDebug("state_entry");
        string ownerName = llToLower(llKey2Name(llGetOwner()));
        string displayName = llToLower(llGetDisplayName(llGetOwner()));
        if (ownerName != displayName) {
            ownerName = ownerName + " " + displayName;
        }
        badWords = llParseString2List(ownerName, [" "], [""]);
        badWords = badWords + ["pink","fluffy","unicorns","dancing","rainbows"];
        sayDebug("state_entry done");
    }

     attach(key id) // log in
     {
        if (id) {
            sayDebug("attach(id)");
        } else {
            sayDebug("attach(null_key)");
        }
        sayDebug("attach done");
    }

    link_message(integer sender_num, integer num, string json, key avatarKey){
        string speechCommand = getJSONstring(json, "Speech", "");
        if (speechCommand != "") {
            sayDebug("link_message:"+speechCommand);
        }
                
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
            if (rlvPresent) {
                //sendRLVReleaseCommand("link_message RenamerON"); // why ws this here? 
                sendRLVRestrictCommand("link_message RenamerON");
            } else {
                sayDebug("link_message got RenamerON command but rlvPresent = 0");
            }
        }
        if (speechCommand == "BadWordsOFF") {
            badWordsActive = FALSE;
        } else if (speechCommand == "BadWordsON") {
            badWordsActive = TRUE;
        } else  if (speechCommand == "DisplayTokOFF") {
            DisplayTokActive = FALSE;
        } else if (speechCommand == "DisplayTokON") {
            DisplayTokActive = TRUE;
        }
        
        string penaltyCommand = getJSONstring(json, "Penalties", "");
        if (penaltyCommand == "DisplayON") {
            speechPenaltyDisplay = TRUE;
        } else if (penaltyCommand == "DisplayOFF") {
            speechPenaltyDisplay = FALSE;
        } else if (penaltyCommand == "GarbleWordON") {
            speechPenaltyGarbleWord = TRUE;
        } else if (penaltyCommand == "GarbleWordOFF") {
            speechPenaltyGarbleWord = FALSE;
        } else if (penaltyCommand == "GarbleTimeON") {
            speechPenaltyGarbleTime = TRUE;
        } else if (penaltyCommand == "GarbleTimeOFF") {
            speechPenaltyGarbleTime = FALSE;
        } else if (penaltyCommand == "BuzzON") {
            speechPenaltyBuzz = TRUE;
        } else if (penaltyCommand == "BuzzOFF") {
            speechPenaltyBuzz = FALSE;
        } else if (penaltyCommand == "ZapON") {
            speechPenaltyZap = TRUE;
        } else if (penaltyCommand == "ZapOFF") {
            speechPenaltyZap = FALSE;
        }

        batteryLevel = getJSONinteger(json, "batteryLevel", batteryLevel);
        
        // handle a change in rlvPresent
        string value = llJsonGetValue(json, ["rlvPresent"]);
        if (value != JSON_INVALID) {
            rlvPresent = getJSONinteger(json, "rlvPresent", rlvPresent);
            // reset any speech settings
            if (rlvPresent && renamerActive) {
                sendRLVRestrictCommand("resetRenamer");
            }
        }        
    }
    
    listen(integer channel, string name, key avatarKey, string message){
        sayDebug("listen("+(string)channel+", '"+message+"')");
        // handle player's redirected speech
        if (channel == renameSpeechChannel && name == llKey2Name(llGetOwner()) && avatarKey == llGetOwner()) {
            processSpeech(message, avatarKey);
        }
        
        // handle player's emotes
        if (channel == renameEmoteChannel && name == llKey2Name(llGetOwner()) && avatarKey == llGetOwner()) {
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
        if (speechPenaltyZap & numTimesToZap > 0) {
            sendJSON("RLV", "Zap Low", llGetOwner());
            numTimesToZap = numTimesToZap - 1;
        }
        if (speechPenaltyBuzz & !speechPenaltyZap & numTimesToBuzz > 0) {
            sendJSON("RLV", "Buzz Low", llGetOwner());
            numTimesToBuzz = numTimesToBuzz -1;
        }
        if (numTimesToZap == 0 & numTimesToBuzz == 0) {
            llSetTimerEvent(0);
        }
        if (textboxListen != 0) {
            llListenRemove(textboxListen);
            textboxListen = 0;
            textboxChannel = 0;
        }
        if (DisplayTokActive) {
            if (llGetListLength(listWordsSpoken) > 0) {
                string nextWord = llList2String(listWordsSpoken,0);
                sayDebug("timer displaytok nextWord:"+nextWord);
                sendJSON("DisplayTemp", nextWord, "");
                stringWordsSpoken = stringWordsSpoken + " " + nextWord;
                listWordsSpoken = llDeleteSubList(listWordsSpoken, 0, 0);
                llSetTimerEvent(1); // need to reset it because other handlers kill it
            } else {
                llSay(0,"'s collar display reads: " + stringWordsSpoken);
                llSetTimerEvent(0);
            }
        }
    }
}
