// Speech.lsl
// Speech script for Black Gazza Collar 4
// Timberwoof Lupindo
// March 2020
// version 2020-03-02

// Handles all speech-related functions for the collar
// Renamer - Gag - Bad Words 

integer OPTION_DEBUG = 1;

integer rlvPresent = 0;
integer renamerActive = 0;
integer renameSpeechChannel = 0;
integer renameSpeechListen = 0;
integer renameEmoteChannel = 0;
integer renameEmoteListen = 0;

integer textboxChannel = 0;
integer textboxListen = 0;

integer badWordsActive = 0;

string assetNumber;

list badWords;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"Speech:"+message);
    }
}

integer detectBadWords(string speech){
    if (badWordsActive) {
        llParseString2List(speech, [" "], [""]);
    }
    return 1;
}

default
{
    state_entry()
    {
        string ownerName = llToLower(llKey2Name(llGetOwner()));
        string displayName = llToLower(llGetDisplayName(llGetOwner()));
        if (ownerName != displayName) {
            ownerName = ownerName + " " + displayName;
        }
        badWords = llParseString2List(ownerName, [" "], [""]);
    }

    link_message(integer sender_num, integer num, string message, key avatarKey){ 
        if (num == 2101) {
            renamerActive = (integer)message;
            if (renamerActive) {
                sayDebug("link_message renamer on");
                renameSpeechChannel = llFloor(llFrand(10000)+1000);
                renameSpeechListen = llListen(renameSpeechChannel, "", llGetOwner(), "");
                renameEmoteChannel = llFloor(llFrand(10000)+1000);
                renameEmoteListen = llListen(renameEmoteChannel, "", llGetOwner(), "");
                string rlvcommand;
                rlvcommand = "@redirchat:"+(string)renameSpeechChannel+"=add,rediremote:"+(string)renameEmoteChannel+"=add";
                sayDebug("link_message renamer rlvcommand:"+rlvcommand);
                llOwnerSay(rlvcommand);
            } else {
                sayDebug("link_message renamer off");
                string rlvcommand = "@redirchat:"+(string)renameSpeechChannel+"=rem,rediremote:"+(string)renameEmoteChannel+"=rem";
                sayDebug("link_message renamer rlvcommand:"+rlvcommand);
                llOwnerSay(rlvcommand);
                llListenRemove(renameSpeechChannel);
                renameSpeechChannel = 0;
                renameEmoteListen = 0;
            }
        }
        
        if (num == 2110) {
            string badWordString = llDumpList2String(badWords,", ");
            string message = "The bad word list is\n"+badWordString+"\n\n"+
                "Add or remove bad words with\n"+
                "badWordToAdd -badWordToRemove";
            textboxChannel = -llFloor(llFrand(10000)+1000);
            textboxListen = llListen(textboxChannel, "", avatarKey, "");
            llTextBox(avatarKey, message, textboxChannel);
            llSetTimerEvent(30);
        }
        
        if (num == 2111) {
            badWordsActive = 0;
        }
        if (num == 2112) {
            badWordsActive = 1;
        }

        if (num == 1400) {
            // RLV Presence
            if (message == "Off") {
                rlvPresent = 0;
                renamerActive = 0;
            } else {
                rlvPresent = 1;
            }    
            sayDebug("link_message set rlvPresent:"+(string)rlvPresent);
        }
        
        if (num == 2000) {
            assetNumber = message;
            sayDebug("link_message set "+message);
        }
    }
    
    listen(integer channel, string name, key avatarKey, string message){
        if (channel == renameSpeechChannel) {
            detectBadWords(message);
            llSay(0,message);
            }
        if (channel == renameEmoteChannel) {
            llSay(0,message);
            }
            
        if (channel = textboxChannel) {
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
        llListenRemove(textboxListen);
        textboxListen = 0;
        textboxChannel = 0;
    }
}
