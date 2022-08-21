// Dominatech RLV Relay Script 2.0
// Copyright (C) 2009 Julia Banshee
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// See http://www.gnu.org/licenses/gpl.html for terms of this license.
//
// Version 2021-12-23 Timberwoof Lupindo for Black Gazza
// Modifications:
// lit and updateStatus() are deleted
// internal documentation
// changed permissions dialog timeout to 60 seconds
// single variable operatingState to keep three operating states
// more sophisticated startup behavior
// communicates to otehr modules with json

integer OPTION_DEBUG = 0;

integer relayChannel = -1812221819;
string version = "1030";
string implversion = "Dominatech Relay 2.0";

integer backChannel; // for @getsitid
key sitting;

list objects;
list restrictions;

list pingObjects;
list pingRestrictions;
key pingSitting;
integer pingSitRetry;

string operatingState = "Off";
string RelayOFF = "Off";
string RelayASK = "Ask";
string RelayON = "On";
list allowedObjects;
list rejectedObjects;
list pendingObjects;
list pendingCommands;

// variables for the dialog that asks wearer permission for RLV control
integer permChannel;
integer permListener;
integer permClose; // timer

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("Relay: "+message);
    }
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

clear(key obj)
{
    integer o = llListFindList(objects, [obj]);
    if (o >= 0)
    {
        integer i;
        while ((i = llListFindList(restrictions, [o])) >= 0)
        {
            string restr = llList2String(restrictions, i + 1);
            restrictions = llDeleteSubList(restrictions, i, i + 1);
            if (llListFindList(restrictions, [restr]) < 0)
                llOwnerSay("@" + restr + "=y");
        }
    }
    if (llGetListLength(restrictions) == 0)
    {
        objects = [];
    }
}

clearSome(key obj, string param)
{
    integer o = llListFindList(objects, [obj]);
    if (o >= 0)
    {
        integer len = llGetListLength(restrictions);
        integer i;
        for (i = 0 ; i < len ; i += 2)
        {
            if (llList2Integer(restrictions, i) == o)
            {
                string restr = llList2String(restrictions, i + 1);
                if (llSubStringIndex(restr, param) >= 0)
                {
                    restrictions = llDeleteSubList(restrictions, i, i + 1);
                    if (llListFindList(restrictions, [restr]) < 0)
                        llOwnerSay("@" + restr + "=y");
                    i -= 2;
                    len -= 2;
                }
            }
        }
    }
    if (llGetListLength(restrictions) == 0)
    {
        objects = [];
    }
}

rlvCommand(key id, string cmd)
{
    integer e = llSubStringIndex(cmd, "=");
    if (e >= 0)
    {
        string restr = llGetSubString(cmd, 1, e - 1);
        string param = llGetSubString(cmd, e + 1, -1);
        if (param == "n" || param == "add")
        {
            llOwnerSay(cmd);
            integer i;
            integer o = llListFindList(objects, [id]);
            if (o < 0)
            {
                o = llGetListLength(objects);
                objects += id;
                i = -1;
            }
            else i = llListFindList(restrictions, [o, restr]);
            if (i < 0)
            {
                restrictions += [o, restr];
            }
            if (restr == "unsit")
                llOwnerSay("@getsitid=" + (string)backChannel);
        }
        else if (param == "y" || param == "rem")
        {
            integer o = llListFindList(objects, [id]);
            if (o >= 0)
            {
                integer i = llListFindList(restrictions, [o, restr]);
                if (i >= 0)
                {
                    restrictions = llDeleteSubList(restrictions, i, i + 1);
                    if (llGetListLength(restrictions) == 0)
                    {
                        objects = [];
                    }
                }
            }
            if (llListFindList(restrictions, [restr]) < 0)
                llOwnerSay(cmd);
        }
        else
        {
            if (restr == "clear")
                clearSome(id, param);
            else
                llOwnerSay(cmd);
        }
    }
    else
    {
        if (cmd == "@clear")
            clear(id);
        else
            llOwnerSay(cmd);
    }
}

string getStatus(integer o) // it's okay if o is not an existing object, or -1, we just result an empty string
{
    string result = "";
    integer len = llGetListLength(restrictions);
    integer i;
    for (i = 0 ; i < len ; i += 2)
        if (llList2Integer(restrictions, i) == o)
            result += "/" + llList2String(restrictions, i + 1);
    return result;
}

integer allowCommand(key id, string cmd)
{
    if (operatingState == RelayON) return TRUE;                 // not in ask mode, automatically allow
    if (llListFindList(allowedObjects, [id]) >= 0) return TRUE; // this object has permission
    if (llGetOwnerKey(id) == llGetOwner()) return TRUE;         // owner's own objects always have permission
    if (llGetSubString(cmd, -2, -1) == "=n") return FALSE;      // adding restrictions not allowed without permission
    if (llGetSubString(cmd, -4, -1) == "=add") return FALSE;    // adding restrictions not allowed without permission
    if (llGetSubString(cmd, -6, -1) == "=force") return FALSE;  // forcing actions not allowed without permission
    return TRUE;                                                  // anything else is okay (e.g. @version)
}

setUpListens() {
    llListen(relayChannel, "", NULL_KEY, "");
    llListen(backChannel = 16777216 + (integer)llFrand(16777216.0), "", llGetOwner(), "");
    llSetTimerEvent(5.0);
}

default
{
    state_entry()
    {
        operatingState = RelayOFF;
        sayDebug("state_entry operatingState:"+operatingState);
    }

    attach(key avatar) {
        sayDebug("attach operatingState:"+operatingState);
        if (avatar) {
            llWhisper(relayChannel, "uniquecheck," + (string)avatar + ",!version");
        }
        if (operatingState == RelayON || operatingState == RelayASK) {
            setUpListens();
        }
        sendJSON("RelayLockState", operatingState, avatar);
    }

    listen(integer ch, string name, key id, string msg)
    {
        sayDebug("listen:"+name+":"+msg);
        if (ch == relayChannel)
        {
            list pack = llCSV2List(msg);
            key target = llList2String(pack, 1);
            if (target == llGetOwner())
            {
                string cmdid = llList2String(pack, 0);
                list cmds = llParseString2List(llList2String(pack, 2), ["|"], []);
                integer len = llGetListLength(cmds);
                integer i;
                for (i = 0 ; i < len ; ++i)
                {
                    string cmd = llList2String(cmds, i);
                    if (llGetSubString(cmd, 0, 0) == "@")
                    {
                        if (allowCommand(id, cmd))
                        {
                            rlvCommand(id, cmd);
                            llShout(relayChannel, cmdid + "," + (string)id + "," + cmd + ",ok");
                        }
                        else if (llListFindList(rejectedObjects, [id]) >= 0)
                        {
                            llShout(relayChannel, cmdid + "," + (string)id + "," + cmd + ",ko");
                        }
                        else
                        {
                            integer p = llListFindList(pendingObjects, [id]);
                            if (p < 0)
                            {
                                p = llGetListLength(pendingObjects);
                                pendingObjects += id;

                                list buttons;
                                if (p)
                                    buttons = ["Yes " + (string)p, "No " + (string)p];
                                else
                                    buttons = ["Yes", "No"];
                                string object = llKey2Name(id);
                                string ownedby = llKey2Name(llGetOwnerKey(id));
                                if (ownedby) object += " (owned by " + ownedby + ")";
                                if (! permListener)
                                    permListener = llListen(permChannel = -16777216 - (integer)llFrand(16777216.0), "", llGetOwner(), "");
                                llDialog(llGetOwner(), "The object " + object
                                    + " is attempting to use your Restrained Life Viewer relay.  Do you wish to allow it?", buttons, permChannel);
                                permClose = llGetUnixTime() + 60;
                            }
                            if (llListFindList(pendingCommands, [p, cmdid, cmd]) < 0) // some devices spam the same command over and over, don't keep growing list
                                pendingCommands += [p, cmdid, cmd];
                        }
                    }
                    else if (cmd == "!release")
                    {
                        clear(id);
                        llShout(relayChannel, cmdid + "," + (string)id + "," + cmd + ",ok");
                    }
                    else if (cmd == "!getstatus")
                    {
                        integer o = llListFindList(objects, [id]);
                        llShout(relayChannel, cmdid + "," + (string)id + "," + cmd + "," + getStatus(o));
                    }
                    else if (cmd == "!version")
                    {
                        llShout(relayChannel, cmdid + "," + (string)id + "," + cmd + "," + version);
                    }
                    else if (cmd == "!implversion")
                    {
                        llShout(relayChannel, cmdid + "," + (string)id + "," + cmd + "," + implversion);
                    }
                    else if (cmd == "!pong")
                    {
                        integer p = llListFindList(pingObjects, [id]);
                        if (p >= 0)
                        {
                            llOwnerSay("Got pong, you're out of luck.  Reapplying restrictions from " + name + "...");
                            integer o = llListFindList(objects, [id]);
                            if (o < 0)
                            {
                                o = llGetListLength(objects);
                                objects += id;
                            }
                            string cmd = "";
                            string pre = "@";
                            integer i;
                            while ((i = llListFindList(pingRestrictions, [p])) >= 0)
                            {
                                string restr = llList2String(pingRestrictions, i + 1);
                                if (restr == "unsit")
                                {
                                    if (pingSitting)
                                    {
                                        llOwnerSay("@sit:" + (string)pingSitting + "=force");
                                        pingSitRetry = 12; // keep trying for a minute -- it can take that long for things to rez
                                    }
                                }
                                cmd += pre + restr + "=n";
                                pre = ",";
                                restrictions += [o, restr];
                                pingRestrictions = llDeleteSubList(pingRestrictions, i, i + 1);
                            }
                            if (cmd)
                                llOwnerSay(cmd);
                            if (llGetListLength(pingRestrictions) == 0)
                                pingObjects = [];
                        }
                    }
                }
            }
            else if (target == llGetKey())
            {
                string cmdid = llList2String(pack, 0);
                if (cmdid == "uniquecheck")
                    llOwnerSay("You are wearing another RLV relay (" + name + ").  Remove it.  You should never wear more than one RLV relay at a time.");
            }
            return;
        }

        if (ch == permChannel)
        {
            integer o = (integer) llGetSubString(msg, -2, -1);
            key obj = llList2Key(pendingObjects, o);
            if (llGetSubString(msg, 0, 2) == "Yes")
            {
                allowedObjects = obj + llList2List(allowedObjects, 0, 8);
                integer i;
                while ((i = llListFindList(pendingCommands, [o])) >= 0)
                {
                    string cmd = llList2String(pendingCommands, i + 2);
                    rlvCommand(obj, cmd);
                    llShout(relayChannel, llList2String(pendingCommands, i + 1) + "," + (string)obj + "," + cmd + ",ok");
                    pendingCommands = llDeleteSubList(pendingCommands, i, i + 2);
                }
                if (llGetListLength(pendingCommands) == 0)
                    pendingObjects = [];
            }
            else
            {
                rejectedObjects = obj + llList2List(rejectedObjects, 0, 8);
                integer i;
                while ((i = llListFindList(pendingCommands, [o])) >= 0)
                {
                    string cmd = llList2String(pendingCommands, i + 2);
                    llShout(relayChannel, llList2String(pendingCommands, i + 1) + "," + (string)obj + "," + cmd + ",ko");
                    pendingCommands = llDeleteSubList(pendingCommands, i, i + 2);
                }
                if (llGetListLength(pendingCommands) == 0)
                    pendingObjects = [];
            }
            return;
        }

        if (ch == backChannel)
        {
            sitting = msg;
            return;
        }
    }

    on_rez(integer param)
    {
        if (objects)
        {
            integer len = llGetListLength(objects);
            integer i;
            for (i = 0 ; i < len ; ++i)
                if (llListFindList(restrictions, [i]) >= 0)
                    llShout(relayChannel, "ping," + (string)llList2Key(objects, i) + ",ping,ping");
        }

        pingObjects = objects;
        pingRestrictions = restrictions;
        pingSitting = sitting;
        pingSitRetry = 0;

        objects = [];
        restrictions = [];
        sitting = NULL_KEY;

        allowedObjects = [];
        rejectedObjects = [];
        pendingObjects = [];
        pendingCommands = [];
    }

    timer()
    {
        if (llGetAgentInfo(llGetOwner()) & AGENT_ON_OBJECT)
        {
            llOwnerSay("@getsitid=" + (string)backChannel);
            pingSitRetry = 0;
        }
        else
        {
            sitting = NULL_KEY;
            if (pingSitRetry)
            {
                llOwnerSay("@sit:" + (string)pingSitting + "=force");
                --pingSitRetry;
            }
        }

        if (permListener)
        {
            if (llGetUnixTime() >= permClose)
            {
                pendingObjects = [];
                pendingCommands = [];
                llListenRemove(permListener);
                permListener = 0;
            }
        }
    }

    link_message(integer src, integer num, string json, key id)
    {
        string relayCommand = getJSONstring(json, "relayCommand", ""); 
        if (relayCommand == RelayON)
        {
            sayDebug("link_message msg:"+json);
            operatingState = RelayON;
            setUpListens();
            allowedObjects = objects;
            rejectedObjects = [];
            pendingObjects = [];
            pendingCommands = [];
            sendJSON("RelayLockState", operatingState, id);
        }

        if (relayCommand == RelayASK)
        {
            sayDebug("link_message msg:"+json);
            operatingState = RelayASK;
            setUpListens();
            if (permListener)
            {
                allowedObjects = [];
                rejectedObjects = [];
                pendingObjects = [];
                pendingCommands = [];
                llListenRemove(permListener);
                permListener = 0;
            }
            sendJSON("RelayLockState", operatingState, id);
        }

        if (relayCommand == "status")
        {
            sayDebug("link_message msg:"+json);
            integer len = llGetListLength(objects);
            if (len)
            {
                integer i;
                for (i = 0 ; i < len ; ++i) {
                    llMessageLinked(LINK_SET, 0, getStatus(i), llList2Key(objects, i));
                }
            } else {
                sayDebug("link_message else");
                llMessageLinked(LINK_SET, 0, "", NULL_KEY);
            }
            sendJSON("RelayLockState", operatingState,id);
        }

        if (relayCommand == RelayOFF)
        {
            sayDebug("link_message msg:"+json);
            operatingState = RelayOFF;
            integer len = llGetListLength(objects);
            integer i;
            for (i = 0 ; i < len ; ++i)
                llShout(relayChannel, "safeword," + (string)llList2Key(objects, i) + ",!release,ok");
            sendJSON("RelayLockState", operatingState, id);
            llResetScript();
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
            llResetScript();
    }
}
