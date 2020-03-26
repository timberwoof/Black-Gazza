// Speech.lsl
// Speech script for Black Gazza Collar 4
// Timberwoof Lupindo
// March 2020
// version: 2020-03-25

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

list badWords;
list listWordsSpoken; // needed globally for displaytok
integer numWordsToSpeak = 0; // needed globally for displaytok
integer numWordsSpoken = 0;
string stringWordsSpoken;

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
            [" ", ",", ".", ";", ":", "!", "?", "'", "\""], []);
        numWordsToSpeak = llGetListLength(listWordsSpoken);
    }
        
    // parse the speech for bad words
    if(badWordsActive) {
        sayDebug("processSpeech badWordsActive");
        integer countBadWords = 0;
        integer i;
        for (i = 0; i < numWordsToSpeak; i++) {
            string aWord = llList2String(listWordsSpoken, i);
            integer where = llListFindList(badWords, [aWord]);
            if (where >= 0) {
                countBadWords++;
                // *** replace words for displaytok here
            }
        }
        sayDebug("detected "+(string)countBadWords+" bad words");
        if (countBadWords > 0) {
            sendJSONinteger("badWordCount", countBadWords, avatarKey);
        }
    }
    
    if(DisplayTokActive) {
        sayDebug("processSpeech DisplayTokActive");
        string firstWord = llList2String(listWordsSpoken, 0);
        sendJSON("DisplayTemp", firstWord, "");
        numWordsSpoken = 1;
        stringWordsSpoken = firstWord;
        llSetTimerEvent(1); // start the display cycle
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
        sayDebug("link_message "+json);
        
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

        string renamerCommand = JSON_INVALID;
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
        }
        if (speechCommand == "BadWordsON") {
            badWordsActive = 1;
        }

        if (speechCommand == "GagOFF") {
            gagActive = 0;
        }
        if (speechCommand == "GagON") {
            gagActive = 1;
        }

        if (speechCommand == "DisplayTokOFF") {
            DisplayTokActive = 0;
        }
        if (speechCommand == "DisplayTokON") {
            DisplayTokActive = 1;
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
        if (numWordsSpoken < numWordsToSpeak) {
            string nextWord = llList2String(listWordsSpoken, numWordsSpoken);
            numWordsSpoken = numWordsSpoken + 1;
            sendJSON("DisplayTemp", nextWord, "");
            stringWordsSpoken = stringWordsSpoken + " " + nextWord;
        } else {
            llSay(0,"'s collar display reads: " + stringWordsSpoken);
            llSetTimerEvent(0);
        }
        if (textboxListen != 0) {
            llListenRemove(textboxListen);
            textboxListen = 0;
            textboxChannel = 0;
        }
    }
}
