params ["_town",["_spawn",true]];

//get a camp position
private _townpos = server getVariable _town;
private _possible = spawner getVariable [format["gangpositions%1",_town],[]];
private _gangs = OT_civilians getVariable [format["gangs%1",_town],[]];
private _gangid = -1;
if((count _possible) > 0) then {
    _home = selectRandom _possible;
    _home set [2,0];

    _gangid = (OT_civilians getVariable ["autogangid",-1]) + 1;
    OT_civilians setVariable ["autogangid",_gangid];
    _vest = selectRandom OT_allProtectiveVests;
    _weapon = selectRandom (OT_CRIM_Weapons + OT_allCheapRifles);
    _loadout = [(format["gang%1",_gangid]),OT_CRIMBaseLoadout,[[_weapon]]] call OT_fnc_getRandomLoadout;
    (_loadout#4) set [0,_vest];

    //Gang format [members,leader,town,vest,camp pos,loadout,resources,level,name]

    private _name = format[selectRandom OT_gangNames,_town,OT_nation];

    OT_civilians setVariable [format["gang%1",_gangid],[[],-1,_town,_vest,_home,_loadout,0,1,_name],true];
    _gangs pushback _gangid;

    if(_spawn && _townpos call OT_fnc_inSpawnDistance) then {
        //Spawn the camp
        private _veh = createVehicle ["Campfire_burning_F",_home,[],0,"CAN_COLLIDE"];

        private _spawnid = spawner getvariable [format["townspawnid%1",_town],-1];
        private _groups = spawner getvariable [_spawnid,[]];
        _groups pushback _veh;

        _numtents = 2 + round(random 3);
        _count = 0;

        while {_count < _numtents} do {
            //this code is in tents
            _d = random 360;
            _p = [_home,[2,9],_d] call SHK_pos_fnc_pos;
            _p = _p findEmptyPosition [1,40,"Land_TentDome_F"];
            _veh = createVehicle ["Land_TentDome_F",_p,[],0,"CAN_COLLIDE"];
            _veh setDir _d;
            _groups pushback _veh;
            _count = _count + 1;
        };

        //And the gang leader in his own group
        private _leaderGroup = creategroup [opfor,true];
        _leaderGroup setVariable ["VCM_TOUGHSQUAD",true,true];
		_leaderGroup setVariable ["VCM_NORESCUE",true,true];
        private _pos = [_home,10] call SHK_pos_fnc_pos;
        _civ = _leaderGroup createUnit [OT_CRIM_Unit, _pos, [],0, "NONE"];
        _civ setRank "COLONEL";
        _civ setVariable ["NOAI",true,false];
        _civ setBehaviour "SAFE";
        [_civ] joinSilent nil;
        [_civ] joinSilent _leaderGroup;
        _civ setVariable ["OT_gangid",_gangid,true];
        [_civ,_town,_gangid] call OT_fnc_initCrimLeader;

        _wp = _leaderGroup addWaypoint [_home,0];
        _wp setWaypointType "GUARD";
        _wp = _leaderGroup addWaypoint [_home,0];
        _wp setWaypointType "CYCLE";

        private _group = creategroup [opfor,true];
        _group setVariable ["VCM_TOUGHSQUAD",true,true];
		_group setVariable ["VCM_NORESCUE",true,true];
        spawner setVariable [format["gangspawn%1",_gangid],_group,true];
        _groups pushback _group;
        _groups pushback _leaderGroup;
        spawner setvariable [_spawnid,_groups,false];

        [_group,_townpos] call OT_fnc_initCriminalGroup;

        {
            _x addCuratorEditableObjects [[_civ]];
        }foreach(allCurators);
    };
    OT_civilians setVariable [format["gangs%1",_town],_gangs,true];
};
_gangid
