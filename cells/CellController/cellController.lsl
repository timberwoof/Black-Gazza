// cell controller
// Script for Black Gazza cells described here: 
// http://blackgazza.com/cellblock/cells
//
// This is Timberwoof's attempt at object-based programming without language support for it. 
// All functions related to a specific aspect of the cell are placed together

// Every cell block must have its elements properly named. 
// The cell on the left must be called {A|B|C|D}{1|3|5|...}
// The cell on the left must be called {A|B|C|D}{2|4|6|...}
// The cell controller box must be named the same as the cell on the left. 
// This supports 32 cells. 

// *** marks unimplemented features and things such as llSay calls not to be commented out for production 
// http://wiki.secondlife.com/wiki/LSL_Script_Efficiency suggests that one script may be better than two
// but we don't have real object-orientedness and all variables would have to be duplicated. 
// The efficiency gains would not be worth the complexity. 

// version 1.5 new features: optimizations
// • removes unnecessarily burdensome logging and state-saving
// • reduces unnecessary function calls for menu generation
// • factors if-statements out of function calls in timer() and sensor()
// • turns off unneeded timers
// • avoids unnecessary llMessageLinked() calls

// Really Global variables
string gThisCell = ""; // this cell's name determined in iniitialize. 
string gPosition = "";  // "Left" or "Right" determined in initialize. 
integer gLinkChannel = 50001; // 50001 or 50002 determined in initialize. 

integer CELL_TIMER_INTERVAL = 5; 
integer CELL_SENSOR_INTERVAL = 5; 


// main ********************************
initialize() {
    // Set the name of the cell. 
    // The name of the prim that is this cell must be set to {A|B|C|D}{1,3,5...9} (A1 or B5 or C7 etc)
    gThisCell = llKey2Name(llGetKey()); // get this cell's name
    integer cell_number = (integer)llGetSubString(gThisCell,1,1); 
    integer cell_number_side = cell_number % 2;
    if ( cell_number_side == 0 ) {
        gPosition = "Right";
        gLinkChannel = 5002;
    } else {
        gPosition = "Left";
        gLinkChannel = 5001;
    }
    
    unreserveCell(llGetOwner()); // unreserve cell, dammit
    setCellSafe();
    resetDoorTimer();
    resetReservationTimer(); 
    gDoorState = "CLOSED";
    gKeyInCell = NULL_KEY;
    //gSecure = FALSE; //  *** opened to all
    setNoBed();
    gBedsMade = 0;
    closeCell();
    initCellAlpha(); 
    setCellAlphaIn("CLEAR");
    openCell();
    setEdgeTextures();
    //closeCell();
    
    // range 3.0 seems optimum: That way no matter which corner you're in it still knows you're there
    // someone really small can squeeze himself into a corner and stop the clock. 
    llSensorRepeat("","",AGENT,3.0,PI,CELL_SENSOR_INTERVAL); 
    
    // ***
    //llSetSitText("Patdown");
    //llSitTarget(<0, 0, 0>, <0, 0, 0, 0>); // <90,180,90>
    //llSetCameraEyeOffset(<1.4, 0.0, 1.0>); // where the camera is
    //llSetCameraAtOffset(<-1.4, 0.0, 0>); // where it's looking
        
    //llSay(0,gThisCell+" initialize done ---"); // debug
}


// cell door timer  ********************************
// This timer controls how long the door stays shut
// This works like a kitchen timer: "30 minutes from now"
// It has non-obvious states that need to be announced and displayed
integer gDoorTimeRemaining = 0; // seconds remaining on timer
integer gPrevousToorTimeRemaining = 0;
string gPreviousDisplayTime;
integer gDoorTimeRunning = 0; // 0 = stopped; 1 = running
integer gDoorTimeStart = 1800; // seconds it was set to so we can set it again 
    // *** set to 20 for debug, 1800 for production

string displayDoorTimer() {
    // parameter: gDoorTimeRemaining global
    // returns: a string in the form of "1 Days 3 Hours 5 Minutes 7 Seconds"
    // or "(no timer)" if seconds is less than zero
    
    if (gDoorTimeRemaining <= 0) {
        return "Timer not set.";
    } else {
        
    // check against cached result
    if (gDoorTimeRemaining == gPrevousToorTimeRemaining) {
        // spare us all this needless work
        return gPreviousDisplayTime;
    } else {
        
    // Calculate
    string display_time = "Opens in ";
    integer days = gDoorTimeRemaining/86400;
    integer hours;
    integer minutes;
    integer seconds;
    
    if (days > 0) {
        display_time += (string)days+" Days ";   
    }
    
    integer carry_over_hours = gDoorTimeRemaining - (86400 * days);
    hours = carry_over_hours / 3600;
    if (hours > 0) {
        display_time += (string)hours+" Hours ";
    }
    
    integer carry_over_minutes = carry_over_hours - (hours * 3600);
    
    minutes = carry_over_minutes / 60;
    if (minutes > 0) {
        display_time += (string)minutes+" Minutes ";
    }
    
    if (gDoorTimeRemaining < 60) {
        seconds = carry_over_minutes - (minutes * 60);
        display_time += (string)seconds+" Seconds";
    }
    
    if (gDoorTimeRunning == 1) {
        display_time += " …";
    } else {
        display_time += " .";
    }    
    
    //cache the result
    gPrevousToorTimeRemaining = gDoorTimeRemaining;
    gPreviousDisplayTime = display_time;
    
    return display_time; 
    }
    }
}

resetDoorTimer() {
    // reset the timer to the value previously set for it. init and finish countdown. 
    gDoorTimeRemaining = gDoorTimeStart; 
    gDoorTimeRunning = 0; // timer is stopped
    //llSay(0,gThisCell+" Timelock Has Been Cleared.");
}

setDoorTimer(integer set_time) {
    // set the timer to the desired time, remember that time
    gDoorTimeRemaining = set_time; // set it to that 
    gDoorTimeStart = set_time; // remember what it was set to
    gDoorTimeRunning = 1;
    llSetTimerEvent(CELL_TIMER_INTERVAL);
    //llSay(0,gThisCell+" Timelock Has Been Set.");
}

startDoorTimer() {
    // make the timer run. Init and finish countdown. 
    gDoorTimeRunning = 1; // timer is running
    llSetTimerEvent(CELL_TIMER_INTERVAL);
    //llSay(0,gThisCell+" Timer has started.");
}

stopDoorTimer() {
    // stop the timer.
    // *** perhaps use this while prisoner is being schoked
    gDoorTimeRunning = 0; // timer is stopped
    //llSay(0,gThisCell+" Timer has stopped.");
}

// *** not called
//decDoorTimer() {
//    // tick
//    gDoorTimeRemaining -= CELL_TIMER_INTERVAL;
//}

// *** not called
//incDoorTimer(integer interval) {
//    gDoorTimeRemaining += interval;
//    // *** use this to increase the time every time someone gets shocked for touching the box
//    // perhaps ... incDoorTimer(gDoorTimeRemaining / 10);
//}

updateDoorTimer() {
        //llSay(0, "updateDoorTimer gDoorTimeRunning=" + (string)gDoorTimeRunning + " gDoorTimeRemaining=" + (string)gDoorTimeRemaining);
        if (gDoorTimeRemaining <= 0) {
            // time has run out...
            //llSay(0,gThisCell+" has finished timelock. Opening.");
            openCell();
            resetDoorTimer();
            }   

        if (gDoorState == "CLOSED" && gPopulationNum != 0) {
            // timer's on, door's closed, someone's in here
            //decDoorTimer(); // optimization
            gDoorTimeRemaining -= CELL_TIMER_INTERVAL;
        }
}

// cell door clock  ********************************
// This clock controls when the door opens
// This works like an alarm clock: "Open the door at 7:36 pm"
// It has non-obvious states that need to be announced and displayed. 
// It uses the server's seconds-since-midnight counter. 
// If time has not yet occurred today, it will open today. 
// If the time set has already occurred today, it will open tomorrow. 
integer gDoorClockRunning = 0; // 0 = stopped; 1 = running
integer gDoorClockEnd = 1; // midnight:00:01
integer gPreviousDoorClockEnd;
integer gDoorClockPassed = 1; // 1 = the time has already occurred today; open tomorrow
// This configuration is pretty much always true. It is likely that it's after midnight, 
// so we have to wait until that time tomorrow

string CLOCK_UNSET_BUTTON = "Unset Clock";
string CLOCK_SET_BUTTON = "Set Clock…";
string gDoorClockButton = CLOCK_SET_BUTTON;

string displayDoorClock() {
    // implied parameter: gDoorClockEnd global
    // returns: a string in the form of "19:30:00"
    // or "(not set)" if not set
    string display_time = "Opens at ";
    
    if (gDoorClockRunning == 0) {
        return "Clock not set.";
    } else {

    // check against cached result
    if (gDoorClockEnd == gPreviousDoorClockEnd) {
        // spare us all this needless work
        return gPreviousDisplayTime;
    } else {
        
    // Calculate
    integer hours;
    integer minutes;
    integer seconds;
    
    hours = gDoorClockEnd / 3600;
    if (hours < 10) {
        display_time += "0";
    }
    display_time += (string)hours + ":";
    
    integer carry_over_minutes = gDoorClockEnd - (hours * 3600);
    
    minutes = carry_over_minutes / 60;
    if (minutes < 10) {
        display_time += "0";
    }
    display_time += (string)minutes+":";
    
    seconds = carry_over_minutes - (minutes * 60);
    
    if (seconds < 10) {
        display_time += "0";
    }
    display_time += (string)seconds;

    // cache the result
    gPreviousDoorClockEnd = gDoorClockEnd;
    gPreviousDisplayTime = display_time;
    return display_time; 
    }
    }
}

setDoorClock(integer set_time) {
    // set the timer to the desired time, remember that time
    integer now = (integer) llGetWallclock();    // what time is it now? 
    if (set_time < now) {
        gDoorClockPassed = 1;    // end happens tomorow
    } else {
        gDoorClockPassed = 0;     // end happens today
    }
    gDoorClockEnd = set_time; // remember what it was set to
    gDoorClockRunning = 1; 
    llSetTimerEvent(CELL_TIMER_INTERVAL);
    gDoorClockButton = CLOCK_UNSET_BUTTON;
    //llSay(0,gThisCell+" "+displayDoorClock()); // debug
}

resetDoorClock() {
    gDoorClockRunning = 0; // turn off the clock
    gDoorClockButton = CLOCK_SET_BUTTON;
    gDoorTimeRunning = 1; // turn on the timer
    llSetTimerEvent(CELL_TIMER_INTERVAL);
    //llSay(0,gThisCell+" Clock is unset."); // debug
}

// *** not called
//incDoorClock(integer interval) {
//    // use this to increase the time every time someone gets shocked for touching the box
//    gDoorClockEnd += interval;
//    if (gDoorClockEnd > 86400) {
//        gDoorClockEnd -= 86400;
//    }
//    // There's actually a bug here: touch it enough and you set the time to just minutes from now. 
//    // This is hard to fix and is thus an eventual bit of cage-fu for the smart and pain-tolerant
//}

updateDoorClock() {
    // call this every clock cycle
    integer now = (integer) llGetWallclock();    // what time is it now? 

    // first account for rolling over midnight
    if (gDoorClockPassed == 1 && now <= gDoorClockEnd) {
        gDoorClockPassed = 0;
        }

    if (gDoorClockPassed == 0 && gDoorClockEnd <= now) {
        //llSay(0,gThisCell+" updateDoorClock Opening.");
        openCell();
        setDoorClock(gDoorClockEnd);    // resets gDoorClockPassed
        // don't reset gDoorClockRunning
    }
}



// Door **********************************
// Door has obvious state, open and closed, and does not need to announce its state
// *** rewrite this so it's time-based insted of animation-based. 
//llSetPrimitiveParams([PRIM_TYPE, 0, 0, <0.001,1.0,0.0>, 0.95, <0,0,0>,<1,1,0>, <0,0,0>]);    // closed
//llSetPrimitiveParams([PRIM_TYPE, 0, 0, <0.249,1.0,0.0>, 0.95, <0,0,0>,<1,1,0>, <0,0,0>]);   // open
string gDoorState = "CLOSED";
string gdoorButton = "Open";

openCell() {
    if (gDoorState == "CLOSED"){
        releaseRLV(gKeyInCell);
        llPlaySound("B5door",1.0);
        gDoorState = "OPEN";
        gdoorButton = "Close";
        setCellSafe(); // reset the trap so it doesn't instantly close again
        float doorstart = 0.001;
        float doorfinish = 0.249; // this keeps that face existing. 
        integer steps = 7;
        float doordelta = (doorfinish - doorstart) / steps;
        for (; doorstart <= doorfinish; doorstart = doorstart + doordelta) {
            llSetPrimitiveParams([PRIM_TYPE, 0, 0, <doorstart,1.0,0.0>, 0.90, <0,0,0>,<1,1,0>, <0,0,0>]);
        }
        setEdgeTextures();  // seems to be a FOL that this is needed
    }
}

closeCell() {
// *** rewrite this so it's time-based insted of animation-based. 
//llSetPrimitiveParams([PRIM_TYPE, 0, 0, <0.249,1.0,0.0>, 0.95, <0,0,0>,<1,1,0>, <0,0,0>]);   // open
//llSetPrimitiveParams([PRIM_TYPE, 0, 0, <0.001,1.0,0.0>, 0.95, <0,0,0>,<1,1,0>, <0,0,0>]);    // closed
    if (gDoorState == "OPEN"){
        llPlaySound("B5door",1.0);
        gDoorState = "CLOSED";
        gdoorButton = "Open";
        float doorstart = 0.249; // this keeps that face existing. 
        float doorfinish = 0.001;
        integer steps = 7;
        float doordelta = (doorstart - doorfinish) / steps;
        for (; doorstart >= doorfinish; doorstart = doorstart - doordelta) {
            llSetPrimitiveParams([PRIM_TYPE, 0, 0, <doorstart,1.0,0.0>, 0.90, <0,0,0>,<1,1,0>, <0,0,0>]);
        }

        if (gDoorClockRunning == 1) {
            stopDoorTimer();        // no countdown time if the clock is running
        } else if (gDoorTimeRemaining > 0) {
            startDoorTimer();      // start the timer
        }
        initRLV(gKeyInCell);
    }
}

// opacity ********************************
// Cell opacity has two obvious states, opaque and transparent; cell does not need to annnouce this state.
// For this to work, the cell inventory must contain the textures. 
// This needs different sets of prims assigned to different faces.
string gCellAlphaIn = "SOLID";   // or "CLEAR" 1 makes door transparent
string gCellAlphaOut = "SOLID";   // or "CLEAR" 1 makes door transparent
string ALPHA_IN_BUTTON_CLEAR = "+See In";
string ALPHA_IN_BUTTON_SOLID = "-See In";
string ALPHA_OUT_BUTTON_CLEAR = "+See Out";
string ALPHA_OUT_BUTTON_SOLID = "-See Out";
string TEXTURE_CELL_CLEAR = "grate_floor2" ; 
string TEXTURE_CELL_SOLID = "grate_floor2" ; 
string gcellAlphaInButton = ALPHA_IN_BUTTON_CLEAR;
string gcellAlphaOutButton = ALPHA_OUT_BUTTON_CLEAR;

// *** useful debug code
//debugCellAlphaState() {
//    integer i = 0;
//    integer max = llGetNumberOfSides();
//    while(i < max)
//    {
//        //llSay(0,"Face "+(string)i+"  texture: " + llGetTexture(i));
//        //llSay(0,"Face "+(string)i+"    scale: " + (string)llGetTextureScale(i));
//        //llSay(0,"Face "+(string)i+" rotation: " + (string)llGetTextureRot(i));
//        //llSay(0,"Face "+(string)i+"   offset: " + (string)llGetTextureOffset(i));
//        ++i;
//    }
//}

initCellAlpha() {
    // set initial state of textures all around the cell
    //debugCellAlphaState(); // debug
    llSetTexture(TEXTURE_CELL_SOLID,ALL_SIDES);

    llScaleTexture(1.0, 1.0, ALL_SIDES);
    llOffsetTexture(0.0, 0.0, ALL_SIDES);
    
    llScaleTexture(1.0, 1.0, 1);
    llOffsetTexture(0.0, 0.0, 1);
    
    llScaleTexture(4.21, 1.0, 5);
    llOffsetTexture(-0.23994, 0.0, 5);
    
    setCellAlphaOut("SOLID");
    setCellAlphaIn("SOLID");
}

setCellAlphaIn(string in) {
    // set cell transparency
    // parameters:
    // in = "CLEAR" or "SOLID" or ""
    if (in != gCellAlphaIn) {
        if (in == "CLEAR") {
            llSetTexture(TEXTURE_CELL_CLEAR,1);
            gCellAlphaIn = in;
            gcellAlphaInButton = ALPHA_IN_BUTTON_SOLID;
        } else if (in == "SOLID") {
            llSetTexture(TEXTURE_CELL_SOLID,1);
            gCellAlphaIn = in;
            gcellAlphaInButton = ALPHA_IN_BUTTON_CLEAR;
        }
    }
    //debugCellAlphaState(); // debug
}


setCellAlphaOut(string out) {
    // set cell transparency
    // parameters:
    // in = "CLEAR" or "SOLID" or ""
    // out = "CLEAR" or "SOLID" or ""
    if (out != gCellAlphaOut) {
        if (out == "CLEAR") {
            llSetTexture(TEXTURE_CELL_CLEAR,5);
            gCellAlphaOut = out;
            gcellAlphaOutButton = ALPHA_OUT_BUTTON_SOLID; 
        } else if (out == "SOLID") {
            llSetTexture(TEXTURE_CELL_SOLID,5);
            gCellAlphaOut = out;
            gcellAlphaOutButton = ALPHA_OUT_BUTTON_CLEAR; 
        }
    }
    //debugCellAlphaState(); // debug
}


setEdgeTextures() {
    llSetTexture("st_wallg_2",7);
    llScaleTexture(5.0, 0.4, 7);
    llOffsetTexture(0.76, 0.0, 7);
    llRotateTexture(1.570796,7);
    llSetTexture("st_wallg_2",8);
    llScaleTexture(5.0, 0.4, 8);
    llOffsetTexture(0.76, 0.0, 8);
    llRotateTexture(1.570796,8);
}

// trap  ********************************
// when "trap" is set, the cell closes when someone walks into it. 
// Makes cells self-service: you can walk in and have it close the door behind you. 
// cell trap has two states, safe and ready, and should annoucne state changes, but doesn't need to appear in display
string gTrapState = "SAFE"; // or "SET" closes when you walk in
string gtrapButton = "Set Trap";
 
setCellSafe() {
    gTrapState = "SAFE";
    gtrapButton = "Set Trap";
}

setCellTrap() {
    gTrapState = "SET";
    gtrapButton = "Make Safe";
}


// reservation ********************************
// Remembers and announces who is occupying a cell.
// reservation has non-obvious states that need to be announced and displayed
//   free - cell is not reserved for anyone
//   ready - cell is ready to be reserved for the first prisoner who walks in
//   occupied - cell is occupied and reserved for that prisoner
//   reserved - cell is empty but reserved for someone
integer gPopulationNum = 0; // number of Prisoners
list gPopulationList; // UUIDs of gPrisoners
string gReservedState = "FREE"; // fives tates: FREE, READY, HERE, GONE, GUEST 
string gReservationName = ""; 
key gReservationKey = NULL_KEY;
string gNamesInCell = ""; // a list of names of peope in the cell
key gKeyInCell = NULL_KEY;
//integer gSecure = FALSE; //set to true to only answer to group members *** opened to all
string greserveButton = "Reserve";
string gReservedForname = "";

unreserveCell(key who) {
    // initialize the reservation system
    // if it's not reserved or it's reserved for y ou or it's reserved for me the owner... 
    if ( (gReservationName == "") || (who == gReservationKey) || (who == llGetOwner()) ){  
        gReservedState = "FREE";
        greserveButton = "Reserve";
        gReservedForname = "";  
        gReservationName = "Not Reserved";
        gReservationKey = NULL_KEY;
        gNamesInCell = "";
        gPopulationNum = 0;
        resetReservationTimer();
    } else {
        llSay(0,"Only " + gReservationName + " can unreserve this cell."); 
        llSay(-106969,(string)who); // *** This is not a debug statement
    }
}

reserveCell() {
    // make cell ready for reservation
    gReservedState = "READY";
    gReservedForname = "Ready for Reservation";
    greserveButton = "Unreserve";
    gReservationName = "";
    gReservationKey = NULL_KEY;
}

reserve_sensor(integer num_detected) {
    // someone's in here. Make a list of everyone in the cell
    //llOwnerSay((string)num_detected);
    gNamesInCell = "";
    gKeyInCell = NULL_KEY;
    gPopulationList = []; // clear UUID list
    gPopulationNum = num_detected;
    integer counter;
    for (counter = 0; counter < num_detected; counter++) {
        gNamesInCell += llDetectedName(counter)+"\n";
        gPopulationList += [llDetectedKey(counter)];  // uuid
        //llSay(0, "making" + (string)gPopulationList + " --- " + (string)gReservationKey );
    }
    string prisoner_name = llDetectedName(0);
    gKeyInCell = llDetectedKey(0);

    // depending on what state the system is in, react to someone being in the cell. 
    if (gReservedState == "FREE") {
        // someone's here, no reservation
        gReservedState = "GUEST";
        greserveButton = "Reserve";
        gReservationName = ""; 
        gReservedForname = gNamesInCell;
        gReservationKey = NULL_KEY;
        //gSecure = FALSE; //  *** opened to all
        stopReservationTimer();
    } else if (gReservedState == "READY") {
        // ah! A prisoner has arrived! Reserve the cell for him. 
        gReservedState = "HERE";
        greserveButton = "Unreserve";
        gReservationName = prisoner_name;
        gReservationKey = gKeyInCell;
        gReservedForname = "Reserved for " + gReservationName + " (present)";
        // gSecure = llSameGroup(gKeyInCell);  // if a member has used the cell, only a member can mess with it *** opened to all
        stopReservationTimer();
        resetReservationTimer();
    } else if (gReservedState == "GONE") {
        if (gKeyInCell == gReservationKey) { // (prisoner_name == gReservationName)
            // prisoner has returned
            gReservedState = "HERE"; 
            greserveButton = "Unreserve";
            gReservedForname = "Reserved for " + gReservationName + " (present)";
            stopReservationTimer();
            resetReservationTimer();
        } else {
            // someone else is in the cell
            llSay(0,prisoner_name + "! This cell is reserved for " + gReservationName); // *** This is not a debug statement
            llSay(-106969,(string)gKeyInCell); // *** This is not a debug statement
        }
    } else if (gReservedState == "HERE") {
        // somebody's here; make sure that the prisoner is one of the people in the cell
        //llSay (0, (string)gPopulationList + " --- " + (string)gReservationKey );
        integer find = llListFindList(gPopulationList,[gReservationKey]); 
        //llSay (0, (string)find );
        if ( find < 0) {
            gReservedState = "GONE";
            greserveButton = "Unreserve";
            gReservedForname = "Reserved for " + gReservationName + " (not present)";
        }
    } else if (gReservedState == "GUEST") {
        ; // we knew about this already: nothing to do
    } else {
        //llSay(0,"error: reserve_sensor reports impossible state in cell reservation: " + gReservedState); // debug
        gReservedState = "FREE";
        greserveButton = "Reserve";
        gReservedForname = "Not Reserved";
    }
}

reserve_no_sensor() {
    gPopulationNum = 0;
    gPopulationList = [];
    gKeyInCell = NULL_KEY;
    // depending on what state the system is in, react to no one being in the cell. 
    if (gReservedState == "FREE") {
        gReservedForname = "Not Reserved";
    } else if (gReservedState == "GUEST") {
        // no reservation, no one here
        gReservedState = "FREE";
        greserveButton = "Reserve";
        gReservedForname = "Not Reserved";
        // gSecure = FALSE; //  *** opened to all
        stopReservationTimer();
    } else if (gReservedState == "READY") {
        ; // we knew about this already: nothing to do
    } else if (gReservedState == "HERE") {
        // someone was here but he's gone now
        gReservedState = "GONE";
        greserveButton = "Unreserve";
        gReservedForname = "Reserved for " + gReservationName + " (not present)";
        resetReservationTimer();
        startReservationTimer();
    } else if (gReservedState == "GONE") {
        startReservationTimer();    // make for damn sure
    } else {
        //llSay(0,"error: reserve_sensor reports impossible state in cell reservation: " + gReservedState); // debug
        gReservedState = "FREE";
        greserveButton = "Reserve";
        gReservedForname = "Not Reserved";
    }
    
}

// cell reservation timer  ********************************
// This timer controls how long the cell stays reserved for someone.
// We don't want someone hogging a cell by reserving it and not showing up. 
// *** needs to be rewritten to alarm-clock model
// It has non-obvious states that need to be announced and displayed
integer gReservationTimeRemaining = 0; // seconds remaining on timer
integer gReservationTimerIsRunning = 0; // 0 = stopped; 1 = running
integer RESERVATION_TIME = 270000; // seconds it was set to so we can set it again 
// 180000 = ~ 2 days, too short
// 270000 = ~ 3 days, just right
// 360000 = ~ 4 days, too long
// *** set to 20 for debug; 180,000 for production. That's just over two days. 
// *** set to 20 for debug; 360,000 for production. That's just over four days. 
// (180,000 second = 3000 minutes =  50 hours = two days and two hours) 

resetReservationTimer() {
    // reset the timer to the value previously set for it. init and finish countdown. 
    gReservationTimeRemaining = RESERVATION_TIME; 
    gReservationTimerIsRunning = 0; // timer is stopped
    //llSay(0,gThisCell+" Reservation timer has been reset.");
}

startReservationTimer() {
    // make the timer run. Finsh countdown. 
    gReservationTimerIsRunning = 1; // timer is running
    llSetTimerEvent(CELL_TIMER_INTERVAL);
}

stopReservationTimer() {
    // stop the timer. 
    gReservationTimerIsRunning = 0; // timer is stopped
}

updateReservationTimer() {
    // time has run out...
    if (gReservationTimeRemaining <= 0) {
        //llSay(0,gThisCell+" has been reserved and unoccupied for more than three days. Opening and clearing reservation."); 
        // *** this is not a debug statement
        // *** but no one's ever around to hear the announcement
        openCell();
        resetDoorTimer();
        unreserveCell(gReservationKey); // gotta be authorized to unreserve it
        resetReservationTimer();
    }   
    // timer's on, no one's in here: count down to expire reservation
    if (gPopulationNum == 0) {
        if (gReservationTimeRemaining > RESERVATION_TIME) {
            gReservationTimeRemaining = RESERVATION_TIME;
            }
        gReservationTimeRemaining -= CELL_TIMER_INTERVAL;
        }
    }



// beds ********************************
// when set in the menu, makes a bed when prisoner enters cell and deletes it when he leaves. 
integer gBedCommandChannel = 32683; // bogus value gets replaced
integer gMakeBed = 0;
integer gBedsMade = 0;

string NO_BED_BUTTON = "No Bed";
string BED_BUTTON = "Bed";
string gbedbutton = BED_BUTTON;

setMakeBed() {
    // respond to button click
    gMakeBed  = 1;
    gbedbutton = NO_BED_BUTTON;
}

setNoBed() {
    // respond to button click
    gMakeBed = 0;
    gbedbutton = BED_BUTTON;
}

setBeds(integer numberOfBeds) {
    // *** This looks like it could eventualy make more than one bed. 
    // That is the intent, but for now, just one bed. 
    if (gMakeBed > 0 && gBedsMade < numberOfBeds) {
        integer make = numberOfBeds - gBedsMade;
        vector cell_position = llGetPos();
        rotation cell_rotation = llGetRot();
        vector bed_pos_delta;
        //if (gPosition == "Left") {
            bed_pos_delta = < 0.3, 0, -2>; // left cell, bed by controller box
        //} else {
        //    bed_pos_delta = <-0.3, 0, -2>; // right cell, bed by controller box
        //}
        vector bed_position = cell_position + (bed_pos_delta * cell_rotation);
        gBedCommandChannel = (integer)llFrand(864000) + 1;
        llRezObject ("CellBed", bed_position, ZERO_VECTOR, cell_rotation, gBedCommandChannel); 
        gBedsMade = numberOfBeds;
    } else if (gBedsMade > numberOfBeds) { 
        integer break = gBedsMade - numberOfBeds;
        llSay(gBedCommandChannel,"die"); // *** this is not a deug statement
        gBedsMade = numberOfBeds;
    }
}

// RLV ********************************
// this talks to the RLV Simple Module
    // @chatshout=n,chatnormal=n,chatwhisper=y, -- specialized not in simple RLV
    // tplm=n,tploc=n,tplure=n,sittp=n,fartouch=n, -- TP, ADMIN
    // showworldmap=n,showminimap=n,showloc=n,fly=n, -- MAPS, FLY
    // edit=n,rez=n, -- ADMIN
    // attach:BGInmate=force,detach:right hand=n,detach:left hand=n
// globals
integer gRLVon = 0;
string RLV_ON_BUTTON = "RLV On";
string RLV_OFF_BUTTON = "RLV Off";
integer rlv_channel = -1812221819;
string gRLVButton = RLV_ON_BUTTON;

setRLVOff() {
    gRLVon = 0;
    gRLVButton = RLV_ON_BUTTON;
    if (gKeyInCell != NULL_KEY) {
        releaseRLV(gKeyInCell);
    }
}

setRLVOn() {
    gRLVon = 1;
    gRLVButton = RLV_OFF_BUTTON;
    if (gKeyInCell != NULL_KEY) {
        initRLV(gKeyInCell);
    }
}

initRLV(key agent) {
    if (gRLVon == 1) {
        llMessageLinked(LINK_THIS, rlv_channel, "INIT", agent);
    }
}

releaseRLV(key agent) {
    llMessageLinked(LINK_THIS, rlv_channel, "RELEASE", agent);
}



// Safeword ***************************
integer gSafeword;
integer gSafewordChannel;
integer gSafewordChannelHandle;
integer gSafewordChannelExpires;

SendSafewordInstructions(key prisonerKey) {
    if (gSafewordChannel != 0) {
        llListenRemove(gSafewordChannel);
    }
    gSafeword = (integer)llFrand(899999)+100000; // generate 6-digit number
    gSafewordChannel = (integer)llFrand(8999)+1000; 
    gSafewordChannelHandle = llListen(gSafewordChannel, "", prisonerKey, "" );
    gSafewordChannelExpires = llGetUnixTime() + 60;
            
    if (gRLVon == 1) {
        llSay(0,"To safeword out of RLV restrictions, say " + (string)gSafeword + 
        " on channel " +  (string)gSafewordChannel + " within 60 seconds.");
        // *** This is not a debug statement
    } else {
        llSay(0,"To safeword out of the cell, say " + (string)gSafeword + 
        " on channel " +  (string)gSafewordChannel + " within 60 seconds.");
        // *** This is not a debug statement
    }
    llSetTimerEvent(CELL_TIMER_INTERVAL);
}

safewordListen(integer incoming_channel, key incoming_key, string incoming_message) {
    if ((incoming_channel == gSafewordChannel) && (incoming_key == gKeyInCell) ) {
        if (incoming_message == (string)gSafeword) {
            SafewordSucceeded(gKeyInCell);
        } else {
            SafewordFailed(gKeyInCell,"Sorry, wrong safeword.");
        }
    }
}

SafewordFailed(key prisonerKey, string reason) {
    llSay(0,reason); // *** This is not a debug statement 
    llListenRemove(gSafewordChannelHandle);
    gSafewordChannelHandle = 0;
}

SafewordSucceeded(key prisonerKey) {
    llListenRemove(gSafewordChannelHandle);
    gSafewordChannelHandle = 0;
    if (gRLVon == 1) {
        setRLVOff();
        llShout (0,llKey2Name(prisonerKey) + " has safeworded out of RLV restrictions."); 
        // *** This is not a debug statement 
    } else {
        openCell();
        llShout (0,llKey2Name(prisonerKey) + " has safeworded out of their cell."); 
        // *** This is not a debug statement 
    }
}

SafewordTimer() {
    if (llGetUnixTime() > gSafewordChannelExpires) {
        SafewordFailed(gKeyInCell,"Sorry, safeword timed out.");
    }
}

// Owner's Status menu *************
string STATUS_MENU_BUTTON = "Status";

list AddOwnerStatusMenuButton(list menu, key agent) {
    if (agent == llGetOwner()) {
        return menu + [STATUS_MENU_BUTTON];
    } else {
        return menu;
    }
}

ReportStatus() {
    llOwnerSay("door timer running: " + (string)gDoorTimeRunning);
    llOwnerSay("door timer remaining: " + (string)gDoorTimeRemaining);
    llOwnerSay("door timer start: " + (string)gDoorTimeStart);
    llOwnerSay("door clock running: " + (string)gDoorClockRunning);
    llOwnerSay("door clock end: " + (string)gDoorClockEnd);
    llOwnerSay("door clock passed: " + (string)gDoorClockPassed);
    llOwnerSay("reservation time remaining: " + (string)gReservationTimeRemaining);
    llOwnerSay("reservation timer running: " + (string)gReservationTimerIsRunning);
    llOwnerSay("reserved: " + (string)gReservedState);
    llOwnerSay("reserved for: " + (string)gReservationName);
    llOwnerSay("door: " + (string)gDoorState);
    //llOwnerSay("secure: " + (string)gSecure); *** opened to all
    }


// Command menu ***************************

integer gCommandChannel;
integer gCommandChannelHandle;
integer gCommandChannelExpires;

showCommandMenu (key controller) {
    // Dynamically builds cell menu based on current state.
    list full_menu = [];

    full_menu += [gcellAlphaInButton]; // 
    full_menu += [gcellAlphaOutButton];//
    full_menu += [gRLVButton];         // inmate control

    full_menu += ["Set Timer…"];        //
    full_menu += [gDoorClockButton];   //
    full_menu += [gtrapButton];        //

    full_menu += [gdoorButton];        //
    full_menu += [greserveButton];     //
    full_menu += ["Other Cell"];        // this should immediately do it
    
    full_menu = AddOwnerStatusMenuButton(full_menu, controller);
    
    if (gCommandChannelHandle != 0) {
        llListenRemove(gCommandChannelHandle);
        }
    gCommandChannel = -1 * ((integer)llFrand(1000000)+1000000);
    gCommandChannelHandle = llListen(gCommandChannel,"",NULL_KEY,"");
    gCommandChannelExpires = llGetUnixTime( ) + 60; 
    llDialog(controller,"Select A Function For This Cell",full_menu,gCommandChannel);
    llSetTimerEvent(CELL_TIMER_INTERVAL);
}

commandMenuListen(integer incoming_channel, key incoming_key, string incoming_message) {
        if (incoming_channel == gCommandChannel) {
            //llSay(0,incoming_message); 

            if (incoming_message == "Other Cell") {
                llMessageLinked(LINK_SET,5003,"Other",incoming_key);
            } else if (incoming_message == "Open") {
                openCell();
            } else if (incoming_message == "Close") {
                closeCell();
            } else if (incoming_message == "Make Safe") {
                setCellSafe();
            } else if (incoming_message == "Set Trap") {
                setCellTrap();
            } else if (incoming_message == ALPHA_IN_BUTTON_CLEAR) {
                setCellAlphaIn("CLEAR"); 
            } else if (incoming_message == ALPHA_IN_BUTTON_SOLID) {
                setCellAlphaIn("SOLID"); 
            } else if (incoming_message == ALPHA_OUT_BUTTON_CLEAR) {
                setCellAlphaOut("CLEAR"); 
            } else if (incoming_message == ALPHA_OUT_BUTTON_SOLID) {
                setCellAlphaOut("SOLID"); 
            } else if (incoming_message == "Reserve") {
                reserveCell();
            } else if (incoming_message == "Unreserve") {
                unreserveCell(incoming_key);
            } else if (incoming_message == NO_BED_BUTTON) {
                setNoBed();
            } else if (incoming_message == BED_BUTTON) {
                setMakeBed();
            } else if (incoming_message == "Set Timer…") {
                llMessageLinked(LINK_THIS, 1000, "TIMER MODE",incoming_key);
            } else if (incoming_message == CLOCK_SET_BUTTON) {
                llMessageLinked(LINK_THIS, 1000, "CLOCK MODE",incoming_key);
            } else if (incoming_message == CLOCK_UNSET_BUTTON) {  
                resetDoorClock();
            } else if (incoming_message == RLV_ON_BUTTON) {
                setRLVOn();
            } else if (incoming_message == RLV_OFF_BUTTON) {
                setRLVOff();
            } else if (incoming_message == STATUS_MENU_BUTTON) {
                ReportStatus();
            }
            llListenRemove(gCommandChannelHandle);
            gCommandChannelHandle = 0;
        }
        
    llMessageLinked(LINK_SET,gLinkChannel, gThisCell+" "+time_display()+"\n"+gReservedForname,NULL_KEY); 
    llMessageLinked(LINK_SET,5004,llList2CSV(gPopulationList),NULL_KEY);
}

CommandMenuTimer() {
    // expire the command menu listen
    if (llGetUnixTime() > gCommandChannelExpires) {
        llListenRemove(gCommandChannelHandle);
        gCommandChannelHandle = 0;
    }
}

// Prisoner menu ***************************

integer gPrisonerChannel;
integer gPrisonerChannelHandle;
integer gPrisonerChannelExpires;

showPrisonerMenu (key prisoner) {
    list prisonerMenu = [gbedbutton];
    if (gRLVon == 0) {
        prisonerMenu += ["RLV"];
    }
    prisonerMenu += ["Safeword"];
    prisonerMenu += [gdoorButton];

    if (gCommandChannelHandle != 0) {
        llListenRemove(gCommandChannelHandle);
        }
    gPrisonerChannel = -1 * ((integer)llFrand(1000000)+1000000);
    gPrisonerChannelHandle = llListen(gPrisonerChannel,"",NULL_KEY,"");
    gPrisonerChannelExpires = llGetUnixTime( ) + 60; 
    llDialog(prisoner,"What do you want, prisoner?!",prisonerMenu,gPrisonerChannel);
    llSetTimerEvent(CELL_TIMER_INTERVAL);
}

prisonerMenuListen(integer incoming_channel, key incoming_key, string incoming_message) {
        if (incoming_channel == gPrisonerChannel) {
            //llSay(0,incoming_message); 
            if (incoming_message == NO_BED_BUTTON) {
                setNoBed();
                setBeds(0);
            } else if (incoming_message == BED_BUTTON) {
                setMakeBed();
            } else if (incoming_message == "Safeword") {
                SendSafewordInstructions(gKeyInCell);
            } else if (incoming_message == "RLV") {  
                setRLVOn();
            } else if (incoming_message == "Open") { 
                llSay(0,"What, are you kidding? I'm not going to open until your time is up!"); // *** This is not a debug statement
                llSay(-106969,(string)gKeyInCell); // *** This is not a debug statement
            } else if (incoming_message == "Close") {
                closeCell();
            }
            llListenRemove(gPrisonerChannelHandle);
            gPrisonerChannelHandle = 0;
        }
}

PrisonerMenuTimer() {
    // expire the prisoner menu listen
    if (llGetUnixTime() > gPrisonerChannelExpires) {
        llListenRemove(gPrisonerChannelHandle);
        gPrisonerChannelHandle = 0;
    }
}

string time_display() {
        if (gDoorClockRunning == 1) {
            return displayDoorClock();
        } else {
            return displayDoorTimer();
        }
}

string gPreviousDisplay = "";
string gPreviousList = "";

conditionalMessages(string display, string populationList) {
    if (display != gPreviousDisplay) {
        gPreviousDisplay = display;
        llMessageLinked(LINK_SET,gLinkChannel, display,NULL_KEY);
    }
    if (populationList != gPreviousList) {
        gPreviousList = populationList;
        llMessageLinked(LINK_SET,5004,populationList,NULL_KEY);
    }
}

// Main ***************************

default
{
    state_entry()
    {
        initialize();
    }

    link_message(integer sender_num, integer sender_integer, string sender_string, key sender_key) {
        if (sender_integer == 5000) {
            if (sender_string == gThisCell+"…") {
                //if(!gSecure || llSameGroup(sender_key)) //  *** opened to all
                //{
                    showCommandMenu(sender_key);
                //}
                //else
                //{
                //    llSay(0, "Sorry, this cell is reserved by a Black Gazza member. " +
                //        "Only Black Gazza members can control this cell"); // *** This is not a debug statement
                //    llMessageLinked(LINK_SET, 5003, "Release", sender_key);
                //}
            }
        }
        if (sender_integer == 1002) {
            if (sender_string == "") {
                resetDoorTimer();
            } else {
                setDoorTimer((integer)sender_string);
            }
            displayDoorTimer();
        }
        if (sender_integer == 1003) {
            if (sender_string == "") {
                resetDoorClock();
            } else {
                setDoorClock((integer)sender_string);
            }
            displayDoorClock();
        }
    }
    
    touch_start(integer num_detected) {
        if (llDetectedKey(0) == gKeyInCell) {
            showPrisonerMenu(gKeyInCell);    
            }
        }
    
    sensor(integer num_detected) {
        // someone's here
        gPopulationNum = num_detected;
        reserve_sensor(num_detected); // reserve cell for first prisoner who entered
        setBeds(num_detected);
        
        conditionalMessages(gThisCell+" "+time_display()+"\n"+gReservedForname, llList2CSV(gPopulationList));
        
        if (num_detected > 0 && 
            gTrapState == "SET" && 
            gDoorState == "OPEN" && 
            gReservedState != "GONE") {
                closeCell();
            }
        }
    
    no_sensor() {
        // No one's in here. 
        if (gPopulationNum != 0) {
            // only do this work if someone just left
            reserve_no_sensor();
            setBeds(0);
        }

        string time_display;
        if (gDoorClockRunning == 1) {
            time_display = displayDoorClock();
        } else {
            time_display = displayDoorTimer();
        }

        conditionalMessages(gThisCell+" "+time_display+"\n"+gReservedForname, "");
    }
    
    // receive commands from the lockbox
    listen(integer incoming_channel, string incoming_name, key incoming_key, string incoming_message) {
        commandMenuListen(incoming_channel,incoming_key,incoming_message);
        prisonerMenuListen(incoming_channel,incoming_key,incoming_message);
        safewordListen(incoming_channel,incoming_key,incoming_message);
    }

    timer() {
        integer timerisNeeded = FALSE;
        
        // cheaper to make IFs here than make unneeded function calls
        if (gDoorTimeRunning == 1) {
            updateDoorTimer();
            timerisNeeded = TRUE;
        }
        if (gDoorClockRunning == 1) {
            updateDoorClock(); 
            timerisNeeded = TRUE;
        }
        if (gReservationTimerIsRunning == 1) {
            updateReservationTimer();
            timerisNeeded = TRUE;
        }
        if  (gCommandChannelHandle != 0) {
            CommandMenuTimer();
            timerisNeeded = TRUE;
        }
        if (gPrisonerChannelHandle != 0) {
            PrisonerMenuTimer();
            timerisNeeded = TRUE;
        }
        if (gSafewordChannelHandle != 0) {
            SafewordTimer();
            timerisNeeded = TRUE;
        }
        
        // if we don't need a timer, turn it off
        if (!timerisNeeded) {
            llSetTimerEvent(0);
        }
    }
}
