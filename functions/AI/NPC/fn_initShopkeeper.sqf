private ["_unit"];

_unit = _this select 0;

(group _unit) setVariable ["VCM_Disable",true];

private _firstname = OT_firstNames_local call BIS_fnc_selectRandom;
private _lastname = OT_lastNames_local call BIS_fnc_selectRandom;
private _fullname = [format["%1 %2",_firstname,_lastname],_firstname,_lastname];
[_unit,_fullname] remoteExecCall ["setName",0,_unit];
_unit allowDamage false;

[_unit, (OT_faces_local call BIS_fnc_selectRandom)] remoteExecCall ["setFace", 0, _unit];
[_unit, "NoVoice"] remoteExecCall ["setSpeaker", 0, _unit];

removeAllWeapons _unit;
removeAllAssignedItems _unit;
removeGoggles _unit;
removeBackpack _unit;
removeHeadgear _unit;
removeVest _unit;

_unit forceAddUniform (OT_clothes_shops call BIS_fnc_selectRandom);

[_unit,"self"] call OT_fnc_setOwner;

_unit disableAI "MOVE";
