// CylinderTorusTube
// by Timberwoof Lupindo, 2018-04-05
//
// Converts a prim between Cylinder, Torus, and Tube. 
//
// Maintains: 
// prim coordinates (by not doing anything to them)
// prim size (corrects for axis flips between shapes)
// prim rotation (by flipping axes in a way that maintains path cuts)
// Path Cut Begin and End
//
// Properly Converts: 
// Cylinder Hollow <-> Torus/Tube Hole Size
//
// Whacks when converting between Cylinder and Tube/Torus: 
// Tube Hole Shape, Twist, Taper, Shear, Slice
// Torus/Tube Hollow, Skew, Twist, Shear, Profile Cut, Taper, Revolutions, Radius
// … because these parameters don't mean anything in the other shape. 
//
// Cylinders are symmetrical about their Z axis. 
// Toruses and Tubes are symmetrical about their X axes. 
// If a conversion is made between these, 
// this script correctly handles the new shape's dimensions
// and rotates the new shape to the correct orientation. 
//
// Ignores:
// Textures 
// There's no single "correct" way to do this. 
// Cut-face, outer and inner surfaces are straightforward but mathy. 
// Top and bottom surfaces are not. 

rotation cylinderToTorus;
rotation torusToCylinder;

key avatar;
integer avatarListen;
integer avatarChannel;

string CYLINDER = "Cylinder";
string TORUS = "Torus";
string TUBE = "Tube";
string BLANK = "-";
list MESSAGES;
list PRIMTYPES;


convertCylinderTo(vector prim_size, 
    rotation prim_rotation, 
    list prim_params, 
    integer primType) // Torus or Tube
{
    // parameters to maintain or convert
    vector cut = llList2Vector(prim_params, 2);
    float hollow = llList2Float(prim_params, 3);
    vector hole_size = <1,0,0>;
    hole_size.y = (1-hollow)/2.0;

    // parameters to whack
    vector advanced_cut = <0,1,0>;
    integer hole_shape = PRIM_HOLE_DEFAULT;
    hollow = 0;
    vector twist = <0,0,0>;
    vector taper = <0,0,0>;
    vector top_shear = <0,0,0>;
    float revolutions = 1;
    float radius_offset = 0;
    float skew = 0;
    
    list primParameters = [PRIM_TYPE, 
        primType, 
        hole_shape, 
        cut, 
        hollow, 
        twist, 
        hole_size, 
        top_shear, 
        advanced_cut, 
        taper, 
        revolutions, 
        radius_offset, 
        skew];
        
    llSetPrimitiveParams([PRIM_SIZE, <prim_size.z, prim_size.x, prim_size.y>]);
    llSetPrimitiveParams(primParameters);
    llSetRot(cylinderToTorus*prim_rotation);
}

convertTorusOrTubeToCylinder(vector prim_size, 
    rotation prim_rotation, 
    list prim_params) 
{
    // parameters to maintain or convert
    vector cut = llList2Vector(prim_params, 2);
    vector hole_size = llList2Vector(prim_params, 5);
    float hollow = 1-2*hole_size.y;

    // parameters to whack
    vector twist = <0,0,0>;
    vector top_size = <1,1,0>; // "taper"
    vector top_shear = <0,0,0>;
    integer hole_shape = PRIM_HOLE_DEFAULT;

    list primParameters = [PRIM_TYPE, 
        PRIM_TYPE_CYLINDER, 
        hole_shape, 
        cut, 
        hollow, 
        twist, 
        top_size, 
        top_shear];
        
    llSetPrimitiveParams([PRIM_SIZE, <prim_size.y, prim_size.z, prim_size.x>]);
    llSetPrimitiveParams(primParameters);
    llSetRot(torusToCylinder*prim_rotation);
}

convertTorusOrTubeTo(list prim_params, 
    integer primType) // Torus or Tube
{
    // parameters to maintain
    integer hole_shape = PRIM_HOLE_DEFAULT;
    vector cut = llList2Vector(prim_params, 2);
    float hollow = llList2Float(prim_params, 3);
    vector twist = llList2Vector(prim_params, 4);
    vector hole_size = llList2Vector(prim_params, 5);
    vector top_shear = llList2Vector(prim_params, 6);
    vector advanced_cut = llList2Vector(prim_params, 7);
    vector taper = llList2Vector(prim_params, 8);
    float revolutions = llList2Float(prim_params, 9);
    float radius_offset = llList2Float(prim_params, 10);
    float skew = llList2Float(prim_params, 11);

    list primParameters = [PRIM_TYPE, 
        primType, 
        hole_shape, 
        cut, 
        hollow, 
        twist, 
        hole_size, 
        top_shear, 
        advanced_cut, 
        taper, 
        revolutions, 
        radius_offset, 
        skew];
    llSetPrimitiveParams(primParameters);
}

integer get_prim_type()
{
    list prim_params = llGetPrimitiveParams([PRIM_TYPE ]);
    return llList2Integer(prim_params,0);
}

default
{
    state_entry()
    {
        cylinderToTorus = llEuler2Rot(<270,0,270>*DEG_TO_RAD);
        torusToCylinder = llEuler2Rot(<0,90,90>*DEG_TO_RAD);
        MESSAGES = [CYLINDER, TORUS, TUBE];
        PRIMTYPES = [PRIM_TYPE_CYLINDER, PRIM_TYPE_TORUS, PRIM_TYPE_TUBE];
    }
    
    touch_start(integer total_number)
    {
        avatar = llDetectedKey(0);
        avatarChannel = llFloor(llFrand(10000)+1000);
        avatarListen = llListen(avatarChannel,"",avatar,"");
        
        // get info on the prim

        integer index = llListFindList(PRIMTYPES,[get_prim_type()]);
        string prim_name = llList2String(MESSAGES, index);
        list menu = llListReplaceList(MESSAGES, [BLANK], index, index);
        string message = "You have a "+prim_name+". Convert it to a…";
        llDialog(avatar, message, menu, avatarChannel);
        llSetTimerEvent(30);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        llListenRemove(avatarListen);
        
        // convert message to newPrimType
        integer newPrimType = llList2Integer(PRIMTYPES, llListFindList(MESSAGES,[message]));
        
        // gather up prim parameters
        list prim_params = llGetPrimitiveParams([PRIM_SIZE]);
        vector prim_size = llList2Vector(prim_params,0);
        rotation prim_rotation = llGetRot();
        integer primType = get_prim_type();
        prim_params = llGetPrimitiveParams([PRIM_TYPE ]);
        
        if (primType == PRIM_TYPE_CYLINDER) 
        {
            convertCylinderTo(prim_size, prim_rotation, prim_params, newPrimType);
        }
        if (primType == PRIM_TYPE_TORUS | primType == PRIM_TYPE_TUBE)
        {
            if (newPrimType == PRIM_TYPE_CYLINDER)
            {
                convertTorusOrTubeToCylinder(prim_size, prim_rotation, prim_params);
            }
            else
            {
                convertTorusOrTubeTo(prim_params, newPrimType);
            }
        }
        llResetScript();
    }
}
