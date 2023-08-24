comment "/*
	======================================================
	File Name: M9SD_fnc_loadMissionModule_comp.sqf
	Script Name: LOAD Mission Module
	Script Code: Module-SaveLoad-2-v3-c
	Script Type: Composition
	Script Desc: 

		Current features:

			- View all the missions saved on your profile.
			- Delete any mission from your profile.
			- View/copy the SQF that creates the mission.
			- Load the mission into the game (run the SQF server-side).

		Directions: 

			1. Select this module-composition in Zeus.
			2. Place the module anywhere.
			3. Select the desired mission.
			4. Click the LOAD mission button.

		NOTE:

			After selecting LOAD mission, it will run the SQF server-side.
			Depending on server performance, this may not be instantaneous.
			The mission will spawn at the exact position it was saved.
			All mission objects/vehicles/units will be added to the interface.
			
		DEPENDENCIES:

			(1) SAVE Mission Module
				- https://steamcommunity.com/sharedfiles/filedetails/?id=3024869633

	GitHub: https://github.com/M9-SD/A3_M9SD_SAVE_LOAD_Mission_Modules
	License: https://github.com/M9-SD/A3_M9SD_SAVE_LOAD_Mission_Modules/blob/main/LICENSE
	Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=3024873677
	Author: M9-SD
	Discord: m9_sd

	======================================================
*/";
comment "Determine if execution context is composition and delete the helipad."; 
if ((!isNull (findDisplay 312)) && (!isNil 'this')) then { 
	if (!isNull this) then { 
		if (typeOf this == 'Land_HelipadEmpty_F') then { 
			deleteVehicle this; 
		}; 
	}; 
};
0 = [] spawn {
	private ['_initREpack', '_initSaveMissionModule'];
	comment "Initialize Remote-Execution Package";
	_initREpack = [] spawn {
		if (!isNil 'M9SD_fnc_RE2_V2') exitWith {};
		comment "Initialize Remote-Execution Package";
		M9SD_fnc_initRE2_V2 = {
			M9SD_fnc_initRE2Functions_V2 = {
				comment "Prep RE2 functions.";
				M9SD_fnc_REinit2_V2 = {
					if (isNil {_this}) exitWith {false};
					if !(_this isEqualType []) exitWith {false};
					if (count _this == 0) exitWith {false};
					private _functionNames = _this;
					private _aString = "";
					private _namespaces = [missionNamespace, uiNamespace];
					{
						if !(_x isEqualType _aString) then {continue};
						private _functionName = _x;
						private _functionNameRE2 = format ["RE2_%1", _functionName];
						{
							private _namespace = _x;
							with _namespace do {
								if (!isNil _functionName) then {
									private _fnc = _namespace getVariable [_functionName, {}];
									private _fncStr = str _fnc;
									private _fncStr2 = "{" + 
										"removeMissionEventHandler ['EachFrame', _thisEventHandler];" + 
										"_thisArgs call " + _fncStr + 
									"}";
									private _fncStrArr = _fncStr2 splitString '';
									_fncStrArr deleteAt (count _fncStrArr - 1);
									_fncStrArr deleteAt 0;
									_namespace setVariable [_functionNameRE2, _fncStrArr, true];
								};
							};
						} forEach _namespaces;
					} forEach _functionNames;
					true;
				};
				M9SD_fnc_RE2_V2 = {
					params [["_REarguments", []], ["_REfncName2", ""], ["_REtarget", player], ["_JIPparam", false]];
					if (!((missionnamespace getVariable [_REfncName2, []]) isEqualType []) && !((uiNamespace getVariable [_REfncName2, []]) isEqualType [])) exitWith {
						systemChat "::Error:: remoteExec failed (invalid _REfncName2 - not an array).";
					};
					if ((count (missionnamespace getVariable [_REfncName2, []]) == 0) && (count (uiNamespace getVariable [_REfncName2, []]) == 0)) exitWith {
						systemChat "::Error:: remoteExec failed (invalid _REfncName2 - empty array).";
					};
					[[_REfncName2, _REarguments],{ 
						addMissionEventHandler ["EachFrame", (missionNamespace getVariable [_this # 0, ['']]) joinString '', _this # 1]; 
					}] remoteExec ['call', _REtarget, _JIPparam];
				};
				comment "systemChat '[ RE2 Package ] : RE2 functions initialized.';";
			};
			M9SD_fnc_initRE2FunctionsGlobal_V2 = {
				comment "Prep RE2 functions on all clients+jip.";
				private _fncStr = format ["{
					removeMissionEventHandler ['EachFrame', _thisEventHandler];
					_thisArgs call %1
				}", M9SD_fnc_initRE2Functions_V2];
				_fncStr = _fncStr splitString '';
				_fncStr deleteAt (count _fncStr - 1);
				_fncStr deleteAt 0;
				missionNamespace setVariable ["RE2_M9SD_fnc_initRE2Functions_V2", _fncStr, true];
				[["RE2_M9SD_fnc_initRE2Functions_V2", []],{ 
					addMissionEventHandler ["EachFrame", (missionNamespace getVariable ["RE2_M9SD_fnc_initRE2Functions_V2", ['']]) joinString '', _this # 1]; 
				}] remoteExec ['call', 0, 'RE2_M9SD_JIP_initRE2Functions_V2'];
				comment "Delete from jip queue: remoteExec ['', 'RE2_M9SD_JIP_initRE2Functions_V2'];";
			};
			call M9SD_fnc_initRE2FunctionsGlobal_V2;
		};
		call M9SD_fnc_initRE2_V2;
		waitUntil {!isNil 'M9SD_fnc_RE2_V2'};
		if (true) exitWith {true};
	};
	waitUntil {scriptDone _initREpack};
	comment "Initialize Load Mission Module";
	_initLoadMissionModule = [] spawn {
		if !(isNil 'M9_EZM_fnc_loadMissionFromProfile_V3') exitWith {};
		M9_EZM_fnc_loadMissionFromProfile_V3 = {
			with uiNamespace do
			{
				disableSerialization;
				createDialog "RscDisplayEmpty";
				showchat true;
				_loadMissionDisplay = (findDisplay -1);
				showchat true;
				_ctrl_background_1 = _loadMissionDisplay ctrlCreate ["RscStructuredText",-1];
				_ctrl_background_1 ctrlSetPosition [0.381406 * safezoneW + safezoneX,0.225 * safezoneH + safezoneY,0.237187 * safezoneW,0.022 * safezoneH];
				_ctrl_background_1 ctrlSetBackgroundColor [0,0,0,0.7];
				_ctrl_background_1 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='center'>[ EZM ]  <  |  >  Load Saved Mission From User Profile  <  |  ></t>");
				_ctrl_background_1 ctrlCommit 0;
				_ctrl_background_2 = _loadMissionDisplay ctrlCreate ["RscText",-1];
				_ctrl_background_2 ctrlSetPosition [0.381406 * safezoneW + safezoneX,0.258 * safezoneH + safezoneY,0.237187 * safezoneW,0.33 * safezoneH];
				_ctrl_background_2 ctrlSetBackgroundColor [0,0,0,0.5];
				_ctrl_background_2 ctrlCommit 0;
				_ctrl_background_3 = _loadMissionDisplay ctrlCreate ["RscText",-1];
				_ctrl_background_3 ctrlSetPosition [0.386562 * safezoneW + safezoneX,0.269 * safezoneH + safezoneY,0.226875 * safezoneW,0.308 * safezoneH];
				_ctrl_background_3 ctrlSetBackgroundColor [0,0,0,0.5];
				_ctrl_background_3 ctrlCommit 0;
				_ctrl_txt1 = _loadMissionDisplay ctrlCreate ["RscStructuredText",-1];
				_ctrl_txt1 ctrlSetPosition [0.396875 * safezoneW + safezoneX,0.291 * safezoneH + safezoneY,0.0979687 * safezoneW,0.022 * safezoneH];
				_ctrl_txt1 ctrlSetBackgroundColor [-1,-1,-1,0.33];
				_ctrl_txt1 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='center'>Saved Missions:</t>");
				_ctrl_txt1 ctrlCommit 0;
				_ctrl_txt2 = _loadMissionDisplay ctrlCreate ["RscStructuredText",-1];
				_ctrl_txt2 ctrlSetPosition [0.505156 * safezoneW + safezoneX,0.291 * safezoneH + safezoneY,0.0979687 * safezoneW,0.022 * safezoneH];
				_ctrl_txt2 ctrlSetBackgroundColor [-1,-1,-1,0.33];
				_ctrl_txt2 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='center'>Selected Mission:</t>");
				_ctrl_txt2 ctrlCommit 0;
				_ctrl_btn1 = _loadMissionDisplay ctrlCreate ["RscButtonMenu",-1];
				_ctrl_btn1 ctrlSetPosition [0.396875 * safezoneW + safezoneX,0.533 * safezoneH + safezoneY,0.0464063 * safezoneW,0.022 * safezoneH];
				_ctrl_btn1 ctrlSetBackgroundColor [-1,-1,-1,0.33];
				_ctrl_btn1 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='center'>CANCEL</t>");
				_ctrl_btn1 ctrladdEventHandler ["ButtonClick", 
				{
					params ["_control"];
					with uiNamespace do 
					{
						_display = ctrlParent _control;
						_display closeDisplay 0;
					};
				}];
				_ctrl_btn1 ctrlCommit 0;
				_ctrl_btn3 = _loadMissionDisplay ctrlCreate ["RscButtonMenu",-1];
				_ctrl_btn3 ctrlSetPosition [0.448438 * safezoneW + safezoneX,0.533 * safezoneH + safezoneY,0.0464063 * safezoneW,0.022 * safezoneH];
				_ctrl_btn3 ctrlSetBackgroundColor [-1,-1,-1,0.33];
				_ctrl_btn3 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='center'>DELETE</t>");
				_ctrl_btn3 ctrladdEventHandler ["ButtonClick", 
				{
					params ["_control"];
					with uiNamespace do 
					{
						_ctrl_missionName = uiNamespace getVariable 'EZM_loadMission_ctrl_edit_missionName';
						_missionName = ctrlText _ctrl_missionName;
						_missions = profileNameSpace getVariable ['EZM_savedMissions',[["Empty","_empty = 'Land_HelipadEmpty_F' createVehicleLocal [0,0,0];deleteVehicle _empty;","Altis"]]];
						_missionsNew = _missions;
						{
							if (_x select 0 == _missionName) then 
							{
								_display = ctrlParent _control;
								_display closeDisplay 0;
								_missionsNew deleteAt _forEachIndex; 
								profileNameSpace setVariable ['EZM_savedMissions',_missionsNew];
								saveProfileNamespace;
								_feedbackMessage = format ["Mission: [%1] deleted from user profile.",_missionName];
								[getAssignedCuratorLogic player, _feedbackMessage] call BIS_fnc_showCuratorFeedbackMessage;
								[] spawn (missionNameSpace getVariable 'M9_EZM_fnc_loadMissionFromProfile_V3');
							};
						} forEach _missions;
					};
				}];
				_ctrl_btn3 ctrlCommit 0;
				_ctrl_background_4 = _loadMissionDisplay ctrlCreate ["RscText",-1];
				_ctrl_background_4 ctrlSetPosition [0.505156 * safezoneW + safezoneX,0.313 * safezoneH + safezoneY,0.0979687 * safezoneW,0.22 * safezoneH];
				_ctrl_background_4 ctrlSetBackgroundColor [-1,-1,-1,0.4];
				_ctrl_background_4 ctrlCommit 0;
				_ctrl_txt3 = _loadMissionDisplay ctrlCreate ["RscStructuredText",-1];
				_ctrl_txt3 ctrlSetPosition [0.510312 * safezoneW + safezoneX,0.324 * safezoneH + safezoneY,0.0360937 * safezoneW,0.022 * safezoneH];
				_ctrl_txt3 ctrlSetBackgroundColor [-1,-1,-1,0.33];
				_ctrl_txt3 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='left'>Name</t>");
				_ctrl_txt3 ctrlCommit 0;
				_ctrl_txt4 = _loadMissionDisplay ctrlCreate ["RscStructuredText",-1];
				_ctrl_txt4 ctrlSetPosition [0.510312 * safezoneW + safezoneX,0.368 * safezoneH + safezoneY,0.0360937 * safezoneW,0.022 * safezoneH];
				_ctrl_txt4 ctrlSetBackgroundColor [-1,-1,-1,0.33];
				_ctrl_txt4 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='left'>SQF</t>");
				_ctrl_txt4 ctrlCommit 0;
				_missions = [];
				_missionName = "";
				_missionSQF = "";
				_missionMap = "";
				_missions = profileNameSpace getVariable ['EZM_savedMissions',[["Empty","_empty = 'Land_HelipadEmpty_F' createVehicleLocal [0,0,0];deleteVehicle _empty;","Altis"]]];
				profileNameSpace setVariable ['EZM_savedMissions',_missions];
				saveProfileNamespace;
				_mission = ["Empty","_empty = 'Land_HelipadEmpty_F' createVehicleLocal [0,0,0];deleteVehicle _empty;","Altis"];
				_missionName = _mission select 0;
				_missionSQF = _mission select 1;
				_missionMap = _mission select 2;
				_EZM_loadMission_ctrl_edit_missionName = _loadMissionDisplay ctrlCreate ["RscEdit",-1];
				uiNamespace setVariable ['EZM_loadMission_ctrl_edit_missionName', _EZM_loadMission_ctrl_edit_missionName];
				_EZM_loadMission_ctrl_edit_missionName ctrlSetPosition [0.510312 * safezoneW + safezoneX,0.346 * safezoneH + safezoneY,0.0876563 * safezoneW,0.022 * safezoneH];
				_EZM_loadMission_ctrl_edit_missionName ctrlSetBackgroundColor [-1,-1,-1,0.33];
				_EZM_loadMission_ctrl_edit_missionName ctrlSetText _missionName;
				_EZM_loadMission_ctrl_edit_missionName ctrlCommit 0;
				_EZM_loadMission_ctrl_edit_missionSQF = _loadMissionDisplay ctrlCreate ["RscEditMulti",-1];
				uinamespace setVariable ['EZM_loadMission_ctrl_edit_missionSQF', _EZM_loadMission_ctrl_edit_missionSQF];
				_EZM_loadMission_ctrl_edit_missionSQF ctrlSetPosition [0.510312 * safezoneW + safezoneX,0.39 * safezoneH + safezoneY,0.0876563 * safezoneW,0.132 * safezoneH];
				_EZM_loadMission_ctrl_edit_missionSQF ctrlSetBackgroundColor [-1,-1,-1,0.33];
				_EZM_loadMission_ctrl_edit_missionSQF ctrlSetText _missionSQF;
				_EZM_loadMission_ctrl_edit_missionSQF ctrlCommit 0;
				_ctrl_btn2 = _loadMissionDisplay ctrlCreate ["RscButtonMenu",-1];
				_ctrl_btn2 ctrlSetPosition [0.505156 * safezoneW + safezoneX,0.533 * safezoneH + safezoneY,0.0979687 * safezoneW,0.022 * safezoneH];
				_ctrl_btn2 ctrlSetBackgroundColor [-1,-1,-1,0.33];
				_ctrl_btn2 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='center'>LOAD SELECTED</t>");
				_ctrl_btn2 ctrladdEventHandler ["ButtonClick", 
				{
					params ["_control"];
					with uiNamespace do 
					{
						_ctrl_missionName = uiNamespace getVariable 'EZM_loadMission_ctrl_edit_missionName';
						_ctrl_missionSQF = uiNamespace getVariable 'EZM_loadMission_ctrl_edit_missionSQF';
						_missionName = ctrlText _ctrl_missionName;
						_missionSQF = ctrlText _ctrl_missionSQF;
						with missionNamespace do 
						{
							0 = _missionSQF spawn {
								_missionSQFCode = compile _this;
								private _randomMissionFunctionID = round (random 999999);
								private _randomMissionFunctionName = format ['M9_fnc_loadMissionSQF_%1', _randomMissionFunctionID];
								private _randomMissionFunctionName_RE2 = format ['RE2_M9_fnc_loadMissionSQF_%1', _randomMissionFunctionID];
								missionNamespace setVariable [_randomMissionFunctionName, _missionSQFCode];
								[_randomMissionFunctionName] call M9SD_fnc_REinit2_V2;
								waitUntil {sleep 0.1; !isNil _randomMissionFunctionName_RE2};
								[[getAssignedCuratorLogic player], _randomMissionFunctionName_RE2, 2] call M9SD_fnc_RE2_V2;
							};
						};
						_feedbackMessage = format ["Mission: [%1] is being spawned in...",_missionName];
						_display = ctrlParent _control;
						_display closeDisplay 0;
						[getAssignedCuratorLogic player, _feedbackMessage] call BIS_fnc_showCuratorFeedbackMessage;
					};
				}];
				_ctrl_btn2 ctrlCommit 0;
				comment "_ctrl_missionsList = _loadMissionDisplay ctrlCreate ['RscListBox', -1];
				{_index = _ctrl_missionsList lbAdd (_x select 0);} forEach _missions;
				_ctrl_missionsList ctrlSetPosition [0.396875 * safezoneW + safezoneX,0.313 * safezoneH + safezoneY,0.0979687 * safezoneW,0.22 * safezoneH];
				_ctrl_missionsList ctrladdEventHandler ['LBSelChanged', 
				{
					params ['_control', '_selectedIndex'];
					with uiNamespace do 
					{
						_ctrl_missionName = uiNamespace getVariable 'EZM_loadMission_ctrl_edit_missionName';
						_ctrl_missionSQF = uiNamespace getVariable 'EZM_loadMission_ctrl_edit_missionSQF';
						_missionName = _control lbText (lbCurSel _control);
						_missions = profileNameSpace getVariable ['EZM_savedMissions',[['Empty','_empty = 'Land_HelipadEmpty_F' createVehicleLocal [0,0,0];deleteVehicle _empty;','Altis']]];
						_missionSQF = '';
						{
							if (_x select 0 == _missionName) then 
							{
								_missionSQF = _x select 1;
							};
						} forEach _missions;
						_ctrl_missionName ctrlSetText _missionName;
						_ctrl_missionName ctrlCommit 0;
						_ctrl_missionSQF ctrlSetText _missionSQF;
						_ctrl_missionSQF ctrlCommit 0;
					};
				}];
				_ctrl_missionsList lbSetSelected [0, true];
				_ctrl_missionsList ctrlCommit 0;";
				_EZM_loadMission_ctrl_tree_missionsList = _loadMissionDisplay ctrlCreate ["RscTree",-1];
				uiNamespace setVariable ['EZM_loadMission_ctrl_tree_missionsList', _EZM_loadMission_ctrl_tree_missionsList];
				_EZM_loadMission_ctrl_tree_missionsList ctrlSetPosition [0.396875 * safezoneW + safezoneX,0.313 * safezoneH + safezoneY,0.0979687 * safezoneW,0.22 * safezoneH];
				_EZM_loadMission_ctrl_tree_missionsList ctrlAddEventHandler ["TreeSelChanged",
				{
					params ["_control", "_selectedIndex"];
					comment "systemChat str _selectedIndex;";
					with uiNamespace do {EZM_loadMission_LastIndex = _selectedIndex;};
					_tree = controlNull;
					_tree = uiNamespace getVariable 'EZM_loadMission_ctrl_tree_missionsList';
					_index = tvCurSel _tree;
					_missionName = _tree tvData _index;
					_missions = profileNameSpace getVariable ['EZM_savedMissions',
					[["Empty","_empty = 'Land_HelipadEmpty_F' createVehicleLocal [0,0,0];
					deleteVehicle _empty;","Altis"]]];
					_missionMaps = [];
					{
						_missionMaps pushBackUnique (_x select 2);
					} forEach _missions;
					if ((not (_missionName in _missionMaps)) && (_missionName != '')) then 
					{
						comment "_container = _tree tvData [(_index select 0),(_index select 1)];
						_sentence = _tree tvData _index;";
						with uiNamespace do 
						{
							_ctrl_missionName = uiNamespace getVariable 'EZM_loadMission_ctrl_edit_missionName';
							_ctrl_missionSQF = uiNamespace getVariable 'EZM_loadMission_ctrl_edit_missionSQF';
							_missions = profileNameSpace getVariable ['EZM_savedMissions',
							[["Empty","_empty = 'Land_HelipadEmpty_F' createVehicleLocal [0,0,0];
							deleteVehicle _empty;","Altis"]]];
							_missionSQF = '';
							{
								if (_x select 0 == _missionName) then 
								{
									_missionSQF = _x select 1;
								};
							} forEach _missions;
							_ctrl_missionName ctrlSetText _missionName;
							_ctrl_missionName ctrlCommit 0;
							_ctrl_missionSQF ctrlSetText _missionSQF;
							_ctrl_missionSQF ctrlCommit 0;
						};
					};
				}];
				if (str _missions != '[]') then 
				{
					_mapsToAdd = [];
					{
						_mapsToAdd pushBackUnique (_x select 2);
					} forEach _missions;
					{
						_topic = _x;
						_pindex = _EZM_loadMission_ctrl_tree_missionsList tvAdd [[],_topic];
						_EZM_loadMission_ctrl_tree_missionsList tvSetData [[_pindex],_topic];
						{
							if (_topic == _x select 2) then 
							{
								_container = _x select 0;
								_cindex = _EZM_loadMission_ctrl_tree_missionsList tvAdd [[_pindex], _container];
								_EZM_loadMission_ctrl_tree_missionsList tvSetData [[_pindex,_cindex], _container];
								_EZM_loadMission_ctrl_tree_missionsList tvSetTooltip [[_pindex,_cindex], _container];
							};
						} forEach _missions;
					} forEach _mapsToAdd;
				};
				_EZM_loadMission_ctrl_tree_missionsList ctrlCommit 0;
			};
			_missions = profileNameSpace getVariable ['EZM_savedMissions',
				[["Empty","_empty = 'Land_HelipadEmpty_F' createVehicleLocal [0,0,0];
				deleteVehicle _empty;","Altis"]]];
			profileNameSpace setVariable ['EZM_savedMissions', _missions];
			saveProfileNamespace;
		};
	};
	waitUntil {scriptDone _initLoadMissionModule};
	comment "Run Load Mission Module";
	0 = [] spawn M9_EZM_fnc_loadMissionFromProfile_V3;
};