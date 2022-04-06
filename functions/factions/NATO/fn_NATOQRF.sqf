params ["_pos","_strength","_success","_fail","_params","_garrison"];
private _totalStrength = _strength;
private _numPlayers = count([] call CBA_fnc_players);
private _popControl = call OT_fnc_getControlledPopulation;

if(_strength < 150) then {_strength = 150};
if(_strength > 2500) then {_strength = 2500};

if(_numPlayers > 2) then {
	_strength = round(_strength * 1.2);
};
if(_numPlayers > 4) then {
	_strength = round(_strength * 1.5);
};
private _diff = server getVariable ["OT_difficulty",1];
if(_diff isEqualTo 0) then {
	_strength = round(_strength * 0.5);
};
if(_diff isEqualTo 2) then {
	_strength = round(_strength * 2);
};
if(_popControl > 3000) then {
	_strength = round(_strength * 1.5);
};

spawner setVariable ["NATOattackforce",[],false];
//determine possible vectors && distribute strength to each
private _town = _pos call OT_fnc_nearestTown;
private _region = server getVariable format["region_%1",_town];

_ground = [];
_air = [];
_abandoned = server getvariable ["NATOabandoned",[]];

([_pos] call OT_fnc_NATOGetAttackVectors) params ["_ground","_air"];

//Send ground forces by air
private _count = 0;
{
	_x params ["_obpos","_name","_pri"];

	_dir = [_pos,_obpos] call BIS_fnc_dirTo;
	_ao = [_pos,_dir] call OT_fnc_getAO;
	[_obpos,_ao,_pos,true,300] spawn OT_fnc_NATOGroundForces;
	diag_log format["Overthrow: NATO Sent ground forces by air from %1 %2",_name,str _obpos];
	_strength = _strength - 150;

	if(_pri > 600 && _strength >= 500) then {
		_ao = [_pos,_dir] call OT_fnc_getAO;
		[_obpos,_ao,_pos,true,420] spawn OT_fnc_NATOGroundForces;
		_strength = _strength - 150;
		diag_log format["Overthrow: NATO Sent extra ground forces by air from %1 %2",_name,str _obpos];
	};
	_count = _count + 1;

	if(_strength <=0 || _count isEqualTo 4) exitWith {};
}foreach(_air);
sleep 2;

//Send ground forces by land
if(_strength >= 150) then {
	{
		_x params ["_obpos","_name","_pri"];

		_dir = [_pos,_obpos] call BIS_fnc_dirTo;
		_ao = [_pos,_dir] call OT_fnc_getAO;

		if(_pri > 100 && _popControl > 1000 && _popControl > (random 2000)) then {
			[_obpos,_ao,_pos,0] spawn OT_fnc_NATOAPCInsertion;
		}else{
			[_obpos,_ao,_pos,false,0] spawn OT_fnc_NATOGroundForces;
		};

		diag_log format["Overthrow: NATO Sent ground forces from %1 %2",_name,str _obpos];
		_strength = _strength - 200;
		if(_strength >= 150) then {
			_ao = [_pos,_dir] call OT_fnc_getAO;
			[_obpos,_ao,_pos,false,120] spawn OT_fnc_NATOGroundForces;
			_strength = _strength - 200;
			diag_log format["Overthrow: NATO Sent extra ground forces from %1 %2",_name,str _obpos];
		};
		if(_strength <=0) exitWith {};
	}foreach(_ground);
};
sleep 2;

if(_strength > 500 && (count _air) > 0) then {
	//Send CAS
	_obpos = (_air select 0) select 0;
	_name = (_air select 0) select 1;
	[_obpos,_pos,10] spawn OT_fnc_NATOAirSupport;
	_strength = _strength - 300;
	diag_log format["Overthrow: NATO Sent CAS from %1 %2",_name,str _obpos];
};
sleep 2;

if(_popControl > 1000 && _strength > 1000 && (count _air) > 0) then {
	//Send more CAS
	private _from = _air call BIS_fnc_selectRandom;
	_obpos = _from select 0;
	_name = _from select 1;
	[_obpos,_pos,120] spawn OT_fnc_NATOAirSupport;
	_strength = _strength - 300;
	diag_log format["Overthrow: NATO Sent extra CAS from %1 %2",_name,str _obpos];
};
sleep 2;

if(_popControl > 2000 && _strength > 1500) then {
	//Send delayed fixed-wing CAS
	[nil,_pos,400] spawn OT_fnc_NATOScrambleJet;
};

//Send ground support
if((count _ground > 0) && (_strength > 250)) then {
	_obpos = (_ground select 0) select 0;
	_name = (_ground select 0) select 1;
	_send = 100;
	if(_strength > 1000) then {
		_send = 300;
	};
	if(_strength > 1500) then {
		_send = 500;
	};
	_strength = _strength - _send;
	[_obpos,_pos,_send,0] spawn OT_fnc_NATOGroundSupport;
	diag_log format["Overthrow: NATO Sent ground support from %1 %2",_name,str _obpos];
};
sleep 2;

//Send tanks
if((count _ground > 0) && (_strength > 1500) && (_popControl > 500)) then {
	_obpos = (_ground select 0) select 0;
	_name = (_ground select 0) select 1;
	[_obpos,_pos,100,0] spawn OT_fnc_NATOTankSupport;
	_strength = _strength - 500;
	diag_log format["Overthrow: NATO Sent tank from %1 %2",_name,str _obpos];
};
sleep 2;

//Send delayed APC in mid-game
if(_popControl > 1000) then {
	{
		_x params ["_obpos","_name","_pri"];
		if(_strength >= 200) then {
			_dir = [_pos,_obpos] call BIS_fnc_dirTo;
			_ao = [_pos,_dir] call OT_fnc_getAO;
			[_obpos,_ao,_pos,300] spawn OT_fnc_NATOAPCInsertion;
			diag_log format["Overthrow: NATO Sent APC reinforcements from %1",_name];
			_strength = _strength - 200;
		};
	}foreach(_ground);
};
sleep 2;

private _isCoastal = false;
private _seaAO = [];

//Sea?

_pos call {
	private _p = [_this,500,0] call BIS_fnc_relPos;
	if(surfaceIsWater _p) exitWith {
		_isCoastal = true;
		_seaAO = _p;
	};
	_p = [_this,500,90] call BIS_fnc_relPos;
	if(surfaceIsWater _p) exitWith {
		_isCoastal = true;
		_seaAO = _p;
	};
	_p = [_this,500,180] call BIS_fnc_relPos;
	if(surfaceIsWater _p) exitWith {
		_isCoastal = true;
		_seaAO = _p;
	};
	_p = [_this,500,270] call BIS_fnc_relPos;
	if(surfaceIsWater _p) exitWith {
		_isCoastal = true;
		_seaAO = _p;
	};
};

diag_log format["Overthrow: Attack start on %1",_pos];
private _delay = 0;

if(_isCoastal && !(OT_NATO_Navy_HQ in _abandoned) && (random 100) > 70) then {
	private _numgroups = 1;
	if(_strength > 100) then {_numgroups = 2};
	if(_strength > 200) then {_numgroups = 3};

	private _p = getMarkerPos OT_NATO_Navy_HQ;
	private _count = 0;
	while {_count < _numgroups} do {
		diag_log format["Overthrow: NATO Sent navy support from %1",OT_NATO_Navy_HQ];
		[[_p,[0,100],random 360] call SHK_pos_fnc_pos,_seaAO,_delay] spawn OT_fnc_NATOSeaSupport;
		_count = _count + 1;
		_delay = _delay + 20;
	};
};
private _start = round(time);
server setVariable ["QRFpos",_pos,true];
["OT_QRFstart", []] call CBA_fnc_globalEvent;
server setVariable ["QRFprogress",0,true];

waitUntil {(time - _start) > 600};

private _timeout = time + 800;
private _maxTime = time + 1800;

private _over = false;
private _progress = 0;

while {sleep 5; !_over} do {
	_alive = 0;
	_enemy = 0;
	_alivein = 0;
	_enemyin = 0;
	{
		if(_x distance _pos < 200) then {
			if((side _x isEqualTo west) && (alive _x)) then {
				_alive = _alive + 1;
			};
			if((side _x isEqualTo resistance || captive _x) && (alive _x) && !(_x getvariable ["ace_isunconscious",false])) then {
				if(isPlayer _x) then {
					_enemy = _enemy + 2;
				} else {
					_enemy = _enemy + 1;
				};
			};
		};
	}foreach(allunits);
	if(_alive == 0) then {_enemy = _enemy * 2}; //If no NATO present, cap it faster
	if(time > _timeout && _alive isEqualTo 0 && _enemy isEqualTo 0) then {_enemy = 1};
	_progresschange = (_alive - _enemy);
	if(_progresschange < -20) then {_progresschange = -20};
	if(_progresschange > 10) then {_progresschange = 10};
	_progress = _progress + _progresschange;
	_progressPercent = 0;
	if(_progress != 0) then {_progressPercent = _progress/1500};
	server setVariable ["QRFprogress",_progressPercent,true];
	if((abs _progress) >= 1500 || time > _maxTime) then {
		//Someone has won
		_over = true;
	};
};

if(_progress > 0) then {
	//Nato has won
	_params call _success;

	//Recover resources
	server setVariable ["NATOresources",round(_strength * 0.5),true];
	{
		if(side _x isEqualTo west) then {
			if(count (units _x) > 0) then {
				_lead = (units _x) select 0;
				private _g = (_lead getVariable ["garrison",""]);
				if(typename _g != "STRING") then {_g = "HQ"};
				if(_g isEqualTo "HQ") then {
					if((vehicle _lead) != _lead) then {
						[vehicle _lead] call OT_fnc_cleanup;
					}else{
						if((getpos _lead) call OT_fnc_inSpawnDistance) then {
							{
								_x setVariable ["garrison",_garrison,true];
							}foreach(units _x);
						}else{
							[_x] call OT_fnc_cleanup;
						};
					};
				};
			}else{
				deleteGroup _x;
			};
		}
	}foreach(allgroups);
	{
		if(side _x isEqualTo west) then {
			if(_x getVariable ["garrison",""] isEqualTo "HQ") then {
				[_x] call OT_fnc_cleanup;
			};
		}
	}foreach(vehicles);
}else{
	_params call _fail;
	//Nato gets pushed back
	server setVariable ["NATOresources",-_strength,true];
	server setVariable ["NATOresourceGain",0,true];
};
server setVariable ["NATOlastattack",time,true]; //Ensures NATO takes some time after a QRF to recover (even if they win)
server setVariable ["QRFpos",nil,true];
["OT_QRFend", []] call CBA_fnc_globalEvent;
server setVariable ["QRFprogress",nil,true];
server setVariable ["NATOattacking","",true];
