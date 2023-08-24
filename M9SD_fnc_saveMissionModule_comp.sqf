comment "/*
	======================================================
	File Name: M9SD_fnc_saveMissionModule_comp.sqf
	Script Name: SAVE Mission Module
	Script Code: Module-SaveLoad-1-v3-c
	Script Type: Composition
	Script Desc: 

		Current features:

			- Saves the following types of objects (within the given radius):

				- Simple objects (static objects spawned with createSimpleObject)
				- Mission objects (Structures and other objects placed by Zeus)
				- Vehicles (every dynamic vehicle and their respective crews)
				- Units (all units and their respective groupings)

			- Saves the following attributes of objects (within the given radius):

				- Object/Vehicle/Unit Position
				- Object/Vehicle/Unit Orientation
				- Object/Vehicle/Unit Hidden State
				- Object/Vehicle/Unit Materials/Textures
				- Object/Vehicle/Unit Damage Values
				- Vehicle Fuel Values
				- Vehicle Attributes/Appearance (i.e. camo nets)
				- Unit-Vehicle Seating Positions (driver, gunner, commander, etc.)
				- Unit Loadouts/Identities/Faces/Voices

		Directions: 

			1. Create your mission in 3DEN or Zeus.
			2. Select this module-composition in Zeus.
			3. Place the module at center of your mission.
			4. Define a radius (in meters) for the mission zone.
			5. Give the mission a unique name to be saved as.
			6. Save the objects within the radius (in meters).
			7. Use the 'LOAD Mission Module' to do any of the following:

				- View all the missions saved on your profile.
				- Delete any mission from your profile.
				- View/copy the SQF that creates the mission.
				- Load the mission into the game (run the SQF server-side).

		WARNING:

			The mission SQF will be saved in your profile data.
			It also stores the loadouts, paths, and other stats.
			Over time, saving many large missions will bloat
			your profile size, potentially causing lag when
			pausing/unpausing the game (or anywhere else the
			script command `saveProfileNamespace` is utilized.
			Because of this, I recommend you only store up to 
			10 normal sized missions in your profile before 
			saving them into a seperate text file on your PC,
			and subsequently deleting them from your profile 
			with the menu from the 'LOAD Mission Module'.
			
		DEPENDENCIES:

			(1) LOAD Mission Module
				- https://steamcommunity.com/sharedfiles/filedetails/?id=3024873677

	GitHub: https://github.com/M9-SD/A3_M9SD_SAVE_LOAD_Mission_Modules
	License: https://github.com/M9-SD/A3_M9SD_SAVE_LOAD_Mission_Modules/blob/main/LICENSE
	Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=3024869633
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
	comment "Initialize Save Mission Module";
	_initSaveMissionModule = [] spawn {
		if !(isNil 'M9_EZM_fnc_saveMissionToProfile_V3') exitWith {};
		M9_EZM_fnc_createMissionSQF_V3 = {
			params 
			[
				["_position", screenToWorld [0.5, 0.5]], 
				['_radius', getObjectViewDistance # 0], 
				["_display", findDisplay 312], 
				["_mapName", 'Unknown'], 
				["_missionName", format ['Unnamed_mission_%1', count 
				(profileNameSpace getVariable ['EZM_savedMissions',
				[["Empty","_empty = 'Land_HelipadEmpty_F' createVehicleLocal [0,0,0];
				deleteVehicle _empty;","Altis"]]])]], 
				['_includeUnits', true]
			];
			M9_MissionSQF_centerPos = _position;
			M9_MissionSQF_radius = _radius;
			_includeMarkers = true;
			M9_MissionSQF_objBlacklist = [
				'Eagle_F',
				'CamCurator'
			];
			M9_fnc_addMissionSQF = {
				M9_MissionSQF = M9_MissionSQF + _this + endl;
			};
			M9_MissionSQF = '';
			M9_mSQF_vehArr = [];
			M9_mSQF_crewedVics = [];
			M9_mSQF_crewedVicCount = 0;
			M9_MissionName = 'Test Scenario';
			endl call M9_fnc_addMissionSQF;
			format ["Comment '======= Mission: %1 =======';", M9_MissionName] call M9_fnc_addMissionSQF;
			endl call M9_fnc_addMissionSQF;
			"
				params [['_curatorLogicEntity', objNull], ['_missionObjects', []]];
				if !(isNull _curatorLogicEntity) then {
					_missionObjects = (allMissionObjects 'all') + vehicles + allUnits;
				};
			" call M9_fnc_addMissionSQF;
			endl call M9_fnc_addMissionSQF;
			"Comment '======= Simple Objects =======';" call M9_fnc_addMissionSQF;
			M9_MissionSQF;
			{
				if (_x distance M9_MissionSQF_centerPos > M9_MissionSQF_radius) then { continue };
				if (isNull _x) then { continue };
				private _className = typeOf _x;
				private _modelPath = getText (configFile >> "cfgVehicles" >> _className >> "model");
				private _soClassOrP3D = if (_modelPath == '') then {_className} else {_modelPath};
				comment "TODO: Maybe need to use https://community.bistudio.com/wiki/getModelInfo select 1";
				private _posASL = getPosWorld _x;
				private _orientation = [vectorDir _x, vectorUp _x];
				(format [
				"
					private _sObj = createSimpleObject ['%1', %2, false];
					_sObj setPosWorld %2;
					_sObj setVectorDirAndUp %3;
				",
				_soClassOrP3D,
				_posASL,
				_orientation
				]) call M9_fnc_addMissionSQF;
			} forEach allSimpleObjects [];
			M9_MissionSQF;
			"Comment '======= Structures/Misc =======';" call M9_fnc_addMissionSQF;
			comment "TODO: make this loop ignore men";
			{
				if (_x distance M9_MissionSQF_centerPos > M9_MissionSQF_radius) then { continue };
				if (isNull _x) then { continue };
				if (isSimpleObject _x) then { continue };
				if (typeOf _x in M9_MissionSQF_objBlacklist) then { continue };
				if (_x isKindOf 'CAManBase') then {
					if (isAgent teamMember _x) then { 
						comment "TODO: Handle agents (non-animal)";
					} else {
						comment "Units iterated through each group.";
					};
				} else {
					if (_x isKindOf 'allVehicles') then {
						if (_x isKindOf 'animal') then {
							comment "skip animals for now (TODO)";
							comment "some animals are agents, others may be units";
						} else {
							comment "actual vehicle";
							M9_mSQF_vehArr pushBack _x;
						};
					} else {
						if (_x isKindOf 'logic') then {
							comment "ignore logic objects (TODO: or maybe not?)";
						} else {
							comment "What is it?";
							comment "Anything else...
								buildings, props, static objects, etc.
							";
							private _className = typeOf _x;
							private _posASL = getPosWorld _x;
							private _orientation = [vectorDir _x, vectorUp _x];
							private _allowDamage = isDamageAllowed _x;
							private _damageTotal = damage _x;
							private _materials = getObjectMaterials _x;
							private _textures = getObjectTextures _x;
							(format [
							"
								private _uObj = createVehicle ['%1', %2, [], 0, 'can_collide'];
								_uObj setPosWorld %2;
								_uObj setVectorDirAndUp %3;
								_uObj allowDamage %4;
								_uObj setDamage %5;
								private _mtrls = %7;
								if (count _mtrls > 0) then {
									{
										[_uObj, [_forEachIndex, _x]] remoteExec ['setObjectMaterialGlobal', 2];
									} forEach _mtrls;
								};
								private _txtrs = %6;
								if (count _txtrs > 0) then {
									{
										[_uObj, [_forEachIndex, _x]] remoteExec ['setObjectTextureGlobal', 2];
									} forEach _txtrs;
								};
							",
							_className,
							_posASL,
							_orientation,
							_allowDamage,
							_damageTotal,
							_textures,
							_materials
							]) call M9_fnc_addMissionSQF;
						};
					};
				};
			} forEach allMissionObjects '';
			"Comment '======= All Vehicles =======';" call M9_fnc_addMissionSQF;
			comment "Iterate through vehicles";
			{
				private _className = typeOf _x;
				private _posASL = getPosWorld _x;
				private _orientation = [vectorDir _x, vectorUp _x];
				private _allowDamage = isDamageAllowed _x;
				private _damageTotal = damage _x;
				private _materials = getObjectMaterials _x;
				private _textures = getObjectTextures _x;
				private _fuel = fuel _x;
				private _vehicleCustomization = [_x] call BIS_fnc_getVehicleCustomization;
				private _lockState = locked _x;
				private _vCrew = crew _x;
				private _vCrewCount = count _vCrew;
				private _vicVarName = "_vObj";
				if (_vCrewCount > 0) then {
					M9_mSQF_crewedVics pushBack _x;
					M9_mSQF_crewedVicCount = M9_mSQF_crewedVicCount + 1;
					_vicVarName = format ["M9_mSQF_crewedVehicle_", M9_mSQF_crewedVicCount];
					{
						_x setVariable ['M9_mSQF_vehVarName', _vicVarName];
					} forEach _vCrew;
				};
				(format [
				"
					%9 = createVehicle ['%1', %2, [], 0, 'can_collide'];
					%9 setPosWorld %2;
					%9 setVectorDirAndUp %3;
					%9 allowDamage %4;
					%9 setDamage %5;
					[%9, false, %8, false] call BIS_fnc_initVehicle;
					private _mtrls = %10;
					if (count _mtrls > 0) then {
						{
							[%9, [_forEachIndex, _x]] remoteExec ['setObjectMaterialGlobal', 2];
						} forEach _mtrls;
					};
					private _txtrs = %6;
					if (count _txtrs > 0) then {
						{
							[%9, [_forEachIndex, _x]] remoteExec ['setObjectTextureGlobal', 2];
						} forEach _txtrs;
					};
					%9 setFuel %7;
					%9 lock %11;
				",
				_className,
				_posASL,
				_orientation,
				_allowDamage,
				_damageTotal,
				_textures,
				_fuel,
				_vehicleCustomization # 1,
				_vicVarName,
				_materials,
				_lockState
				]) call M9_fnc_addMissionSQF;
			} forEach M9_mSQF_vehArr;
			IF (_includeUnits) THEN {
				"Comment '======= All AI Units =======';" call M9_fnc_addMissionSQF;
				comment "Iterate through units";
				M9SD_fnc_isPlayerGroup = {
					private _group = _this;
					private _units = units _group;
					private _unitCount = count _units;
					private _unitPlayerCount = 0;
					{
						if (isPlayer _x) then {
							_unitPlayerCount = _unitPlayerCount + 1;
						};
					} forEach _units;
					if (_unitPlayerCount == _unitCount) then {true} else {false};
				};
				private _squads = allGroups;
				private _groupCount = count _squads;
				{
					private _squad = _x;
					private _squadMembers = units _squad;
					private _squadSize = count _squadMembers;
					if (_squadSize == 0) then {continue};
					if (_squad call M9SD_fnc_isPlayerGroup) then {continue};
					private _side = side _squad;
					private _squadLeader = leader _squad;
					private _groupVarName = format ["M9_group_mSQF_%1", _forEachIndex];
					(format ["private _aiGroup = createGroup [%1, true];", _side]) call M9_fnc_addMissionSQF;
					{
						if (_x distance M9_MissionSQF_centerPos > M9_MissionSQF_radius) then { continue };
						private _unit = _x;
						private _group = _squad;
						private _className = typeOf _unit;
						private _posASL = getPosWorld _unit;
						private _orientation = [vectorDir _unit, vectorUp _unit];
						private _allowDamage = isDamageAllowed _unit;
						comment "TODO: make this work: private _hpDmgSpread = getAllHitPointsDamage _unit;";
						private _damageTotal = damage _unit;
						private _loadout = getUnitLoadout _unit;
						private _materials = getObjectMaterials _unit;
						private _textures = getObjectTextures _unit;
						private _facewear = goggles _unit;
						private _face = face _unit;
						private _hidden = isObjectHidden _unit;
						private _speaker = speaker _x;
						private _nameSound = nameSound _x;
						private _pitch  = pitch _x;
						private _name = name _x;
						comment "private _group = group _unit;";
						comment "private _side = side _group;";
						(format [
						"
							private _aiObj = _aiGroup createUnit ['%2', %3, [], 0, 'can_collide'];
							_aiObj setPosWorld %3;
							_aiObj setVectorDirAndUp %4;
							_aiObj allowDamage %5;
							_aiObj setDamage %6;
							_aiObj setUnitLoadout %7;
							private _mtrls = %11;
							if (count _mtrls > 0) then {
								{
									[_aiObj, [_forEachIndex, _x]] remoteExec ['setObjectMaterialGlobal', 2];
								} forEach _mtrls;
							};
							private _txtrs = %8;
							if (count _txtrs > 0) then {
								{
									[_aiObj, [_forEachIndex, _x]] remoteExec ['setObjectTextureGlobal', 2];
								} forEach _txtrs;
							};
							_aiObj addGoggles '%9';
							[_aiObj, '%10'] remoteExec ['setFace', 0, _aiObj];
							[_aiObj, %12] remoteExec ['hideObjectGlobal', 2];
							_aiObj setSpeaker '%13';
							_aiObj setNameSound '%14';
							_aiObj setPitch %15;
							_aiObj setName '%16';
						",
						_side,
						_className,
						_posASL,
						_orientation,
						_allowDamage,
						_damageTotal,
						_loadout,
						_textures,
						_facewear,
						_face,
						_materials,
						_hidden,
						_speaker,
						_nameSound,
						_pitch,
						_name
						]) call M9_fnc_addMissionSQF;
						if (_unit == _squadLeader) then {
							(format ["%1 selectLeader _aiObj;", _groupVarName]) call M9_fnc_addMissionSQF;
						};
						private _unitVeh = vehicle _unit;
						private _isInVeh = if (_unit == _unitVeh) then {false} else {true};
						if (_isInVeh) then {
							private _vehVarName = _unit getVariable ['M9_mSQF_vehVarName', ''];
							if (_vehVarName != '') then {
								private _turretIdx = _unitVeh unitTurret _unit;
								(switch (_turretIdx) do {
									case []: {
										private _cargoIdx = _unitVeh getCargoIndex _unit;
										format ["_aiObj moveInCargo [%2, %1];", _cargoIdx, _vehVarName];
									};
									case [-1]: {format ["_aiObj moveInDriver %1;", _vehVarName]};
									default {
										format ["_aiObj moveInTurret [%2, %1]; _aiObj moveInAny %2;", _turretIdx, _vehVarName];
									};
								}) call M9_fnc_addMissionSQF;
							};
						};
					} forEach _squadMembers;
					(format 
					[
						"
							_aiGroup setFormation '%1';
							_aiGroup setCombatMode '%2';
							_aiGroup setBehaviour '%3';
							_aiGroup setSpeedMode '%4';
						",
						(formation _squad),
						(combatMode _squad),
						(behaviour (leader _squad)),
						(speedMode _squad)
					]) call M9_fnc_addMissionSQF;
					{
						if (_forEachIndex == 0) then {continue};
						private _wayPoint = _x;
						(format 
						[
							"private _newWaypoint = _newGroup addWaypoint [%1, %2]; _newWaypoint setWaypointType '%3';%4 %5 %6",
							(waypointPosition _wayPoint),
							0,
							(waypointType _wayPoint),
							if ((waypointSpeed _wayPoint) != 'UNCHANGED') then { "_newWaypoint setWaypointSpeed '" + (waypointSpeed _wayPoint) + "'; " } else { "" },
							if ((waypointFormation _wayPoint) != 'NO CHANGE') then { "_newWaypoint setWaypointFormation '" + (waypointFormation _wayPoint) + "'; " } else { "" },
							if ((waypointCombatMode _wayPoint) != 'NO CHANGE') then { "_newWaypoint setWaypointCombatMode '" + (waypointCombatMode _wayPoint) + "'; " } else { "" }
						]) call M9_fnc_addMissionSQF;
					} forEach (waypoints _squad);
				} forEach _squads;
			};
			if (_includeMarkers) then
			{
				"Comment '======= All Map Markers =======';" call M9_fnc_addMissionSQF;
				comment "Iterate through map markers";
				{
					_markerName = "M9_mSQF_marker_" + str(_forEachIndex);
					(format [
						"private _newMarker = createMarker ['%1', %2]; _newMarker setMarkerShape '%3'; _newMarker setMarkerType '%4'; _newMarker setMarkerDir %5; _newMarker setMarkerColor '%6'; _newMarker setMarkerAlpha %7; %8 %9",
						_markerName,
						(getMarkerPos _x),
						(markerShape _x),
						(markerType _x),
						(markerDir _x),
						(getMarkerColor _x),
						(markerAlpha _x),
						if ((markerShape _x) == "RECTANGLE" ||(markerShape _x) == "ELLIPSE") then { "_newMarker setMarkerSize " + str(markerSize _x) + "; "; } else { ""; },
						if ((markerShape _x) == "RECTANGLE" || (markerShape _x) == "ELLIPSE") then { "_newMarker setMarkerBrush " + str(markerBrush _x) + "; "; } else { ""; }
					]) call M9_fnc_addMissionSQF;
				} forEach allMapMarkers;
			};
			comment "TODO: Figure out how to handle attached objects.";
			comment "Update Zeus interface";
			"
				if (!isNull _curatorLogicEntity) then {
					private _newMissionObjects = [];
					{
						if (_x in _missionObjects) then {continue};
						_newMissionObjects pushBack _x;
					} forEach ((allMissionObjects 'all') + vehicles + allUnits);
					_curatorLogicEntity addCuratorEditableObjects [_newMissionObjects, true];
				};
			" call M9_fnc_addMissionSQF;
			M9_MissionSQF_fnc = compile M9_MissionSQF;
			_missionSQF = str M9_MissionSQF_fnc;
			_missionSQF = _missionSQF splitstring '';
			_missionSQF deleteAt 0;
			_missionSQF deleteAt ((count _missionSQF) - 1);
			_missionSQF = _missionSQF joinString '';
			with uiNamespace do 
			{
				if (_missionSQF != '') then 
				{
					_missions = profileNameSpace getVariable ['EZM_savedMissions',[["Empty","_empty = 'Land_HelipadEmpty_F' createVehicleLocal [0,0,0];deleteVehicle _empty;","Altis"]]];
					_missions pushBackUnique [_missionName, _missionSQF, _mapName];
					profileNameSpace setVariable ['EZM_savedMissions', _missions];
					saveProfileNamespace;
					_display closeDisplay 0;
					_feedbackMessage = format ["Mission: [%1] has been saved to your profile.", _missionName];
					[getAssignedCuratorLogic player, _feedbackMessage] call BIS_fnc_showCuratorFeedbackMessage;
				};
			};
			_missionSQF;
		};
		M9_EZM_fnc_saveMissionToProfile_V3 = {
			M9_EZM_posSaveMissionCenter = screenToWorld getMousePosition;
			with uiNamespace do
			{
				disableSerialization;
				_saveMissionDisplay = (findDisplay 312) createDisplay "RscDisplayEmpty";
				showchat true;
				_ctrl_background_1 = _saveMissionDisplay ctrlCreate ["RscStructuredText",-1];
				_ctrl_background_1 ctrlSetPosition [0.412344 * safezoneW + safezoneX,0.269 * safezoneH + safezoneY,0.175313 * safezoneW,0.022 * safezoneH];
				_ctrl_background_1 ctrlSetBackgroundColor [-1,-1,-1,0.8];
				_ctrl_background_1 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='center'>[ EZM ]  Save Objects As New Mission</t>");
				_ctrl_background_1 ctrlCommit 0;
				_ctrl_background_2 = _saveMissionDisplay ctrlCreate ["RscText",-1];
				_ctrl_background_2 ctrlSetPosition [0.412344 * safezoneW + safezoneX,0.302 * safezoneH + safezoneY,0.175313 * safezoneW,0.176 * safezoneH];
				_ctrl_background_2 ctrlSetBackgroundColor [-1,-1,-1,0.8];
				_ctrl_background_2 ctrlCommit 0;
				_ctrl_txt1 = _saveMissionDisplay ctrlCreate ["RscStructuredText",-1];
				_ctrl_txt1 ctrlSetPosition [0.4175 * safezoneW + safezoneX,0.313 * safezoneH + safezoneY,0.061875 * safezoneW,0.022 * safezoneH];
				_ctrl_txt1 ctrlSetBackgroundColor [-1,-1,-1,0];
				_ctrl_txt1 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='center'>Radius:</t>");
				_ctrl_txt1 ctrlCommit 0;
				_ctrl_txt2 = _saveMissionDisplay ctrlCreate ["RscStructuredText",-1];
				_ctrl_txt2 ctrlSetPosition [0.4175 * safezoneW + safezoneX,0.357 * safezoneH + safezoneY,0.061875 * safezoneW,0.022 * safezoneH];
				_ctrl_txt2 ctrlSetBackgroundColor [-1,-1,-1,0];
				_ctrl_txt2 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='center'>Name:</t>");
				_ctrl_txt2 ctrlCommit 0;
				_ctrl_pic = _saveMissionDisplay ctrlCreate ["RscStructuredText",-1];
				_ctrl_pic ctrlSetPosition [0.484844 * safezoneW + safezoneX,0.314 * safezoneH + safezoneY,0.0973437 * safezoneW,0.119 * safezoneH];
				_ctrl_pic ctrlSetBackgroundColor [-1,-1,-1,0];
				_ctrl_pic ctrlSetStructuredText parseText ("<t size='" + (str (5 * (0.5 * safezoneH))) + "' align='center'><img image='\a3\ui_f_curator\Data\Logos\arma3_zeus_icon_hover_ca.paa'/></t>");
				_ctrl_pic ctrlCommit 0;
				EZM_saveMission_ctrl_edit_missionRadius = _saveMissionDisplay ctrlCreate ["RscEdit",-1];
				EZM_saveMission_ctrl_edit_missionRadius ctrlSetPosition [0.4175 * safezoneW + safezoneX,0.335 * safezoneH + safezoneY,0.061875 * safezoneW,0.022 * safezoneH];
				EZM_saveMission_ctrl_edit_missionRadius ctrlSetBackgroundColor [-1,-1,-1,0.33];
				EZM_saveMission_ctrl_edit_missionRadius ctrlSetText str (0);
				EZM_saveMission_ctrl_edit_missionRadius ctrlCommit 0;
				EZM_saveMission_ctrl_edit_missionName = _saveMissionDisplay ctrlCreate ["RscEdit",-1];
				EZM_saveMission_ctrl_edit_missionName ctrlSetPosition [0.4175 * safezoneW + safezoneX,0.379 * safezoneH + safezoneY,0.061875 * safezoneW,0.022 * safezoneH];
				EZM_saveMission_ctrl_edit_missionName ctrlSetBackgroundColor [-1,-1,-1,0.33];
				EZM_saveMission_ctrl_edit_missionName ctrlSetText "";
				EZM_saveMission_ctrl_edit_missionName ctrlCommit 0;
				_ctrl_btn1 = _saveMissionDisplay ctrlCreate ["RscButtonMenu",-1];
				_ctrl_btn1 ctrlSetPosition [0.4175 * safezoneW + safezoneX,0.445 * safezoneH + safezoneY,0.04125 * safezoneW,0.022 * safezoneH];
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
				_ctrl_btn2 = _saveMissionDisplay ctrlCreate ["RscButtonMenu",-1];
				_ctrl_btn2 ctrlSetPosition [0.54125 * safezoneW + safezoneX,0.445 * safezoneH + safezoneY,0.04125 * safezoneW,0.022 * safezoneH];
				_ctrl_btn2 ctrlSetStructuredText parseText ("<t size='" + (str (0.5 * safezoneH)) + "' align='center'>SAVE</t>");
				_ctrl_btn2 ctrladdEventHandler ["ButtonClick", 
				{
					params ["_control"];
					private ["_mapName"];
					_mapName = worldName;
					with uiNamespace do 
					{
						_display = ctrlParent _control;
						_ctrl_missionRadius = uiNamespace getVariable 'EZM_saveMission_ctrl_edit_missionRadius';
						_ctrl_missionName = uiNamespace getVariable 'EZM_saveMission_ctrl_edit_missionName';
						_missionRadius = parseNumber ctrlText _ctrl_missionRadius;
						_missionName = ctrlText _ctrl_missionName;
						if ((_missionRadius != 0) && (_missionName != "") && (not (_missionName in ['Altis','Stratis','Malden','Tanoa','Livonia','Enoch']))) then 
						{
							comment "_feedbackMessage = format ['Mission: [%1] is being saved...',_missionName];";
							comment "[getAssignedCuratorLogic player, _feedbackMessage] call BIS_fnc_showCuratorFeedbackMessage;";
							[missionNameSpace getVariable 'M9_EZM_posSaveMissionCenter',_missionRadius,_display,_mapName,_missionName] spawn (missionNameSpace getVariable 'M9_EZM_fnc_createMissionSQF_V3');
						};
					};
				}];
				_ctrl_btn2 ctrlCommit 0;
			};
		};
	};
	waitUntil {scriptDone _initSaveMissionModule};
	comment "Run Save Mission Module";
	0 = [] spawn M9_EZM_fnc_saveMissionToProfile_V3;
};