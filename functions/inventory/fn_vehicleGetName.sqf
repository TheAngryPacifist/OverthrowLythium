private _name = _this;
private _return = "";
private _cfgVehicles = configFile >> "CfgVehicles";

if (isText(_cfgVehicles >> _name >> "displayName")) then {
    _return = getText(_cfgVehicles >> _name >> "displayName");
};

// Lythium fix
if (_return isEqualTo "" && worldName == "Lythium") then {
    _name = _name select [5];

    if (isText(_cfgVehicles >> _name >> "displayName")) then {
        _return = getText(_cfgVehicles >> _name >> "displayName");
    };
};

_return