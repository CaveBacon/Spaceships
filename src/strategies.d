module strategies;

/*
Copyright (c) 2020, Logan Freesh
All rights reserved.

See "License.txt"
*/


import strategy;
import unit;
import team;
import capture_point;
import gamestateinfo;

import std.conv;
import std.math; // square
import std.exception; // assumeUnique



const Strategy[] g_strategies = [
	strat_attack_mothership, 
	strat_attack_economy,
	strat_attack_weakest_enemy_force,
	strat_capture_least_guarded,
	strat_guard_mothership,
	strat_guard_economy,
	strat_guard_most_threatened,
	strat_contest_caps,
	strat_stay_safe,
	strat_spread_out,
	strat_expand_safe,
	strat_kite_and_snipe,
	strat_decap_least_gaurded,
	strat_attack_countered_units
];

const Behavior behv_stay_put = new Behavior(&qual_all, &prop_distance_to_unit, false);

int index_of_strat(const Strategy strat)
{
	foreach (int i, strat_iter ; g_strategies)
	{
		if( strat == strat_iter)
			return i;
	}
	return -1;
}

///////////////
//strategies:
///////////////

//strat_attack_mothership
const Strategy strat_attack_mothership = new Strategy("AMsh", [
	new Behavior(&qual_has_enemy_mothership, &prop_threat_diff, true, &prop_distance_to_unit, false),
	to!(const Evaluable)(strat_attack_weakest_enemy_force)
]);

//strat_attack_economy
const Strategy strat_attack_economy = new Strategy("AEco", [
	new Behavior(&qual_has_enemy_miners, &prop_threat_diff, true, &prop_distance_to_unit, false),
	new Behavior(&qual_is_enemy, &prop_threat_diff, true, &prop_distance_to_unit, false),
	to!(const Evaluable)(strat_attack_weakest_enemy_force)
]);

//strat_attack_weakest_enemy_force
const Strategy strat_attack_weakest_enemy_force = new Strategy("ASm", [
	new Behavior(&qual_has_enemies, &prop_threat, false, &prop_distance_to_unit, false),
	behv_stay_put
]);

//strat_capture_least_guarded
const Strategy strat_capture_least_guarded = new Strategy("Cap", [
	new Behavior(&qual_not_friendly, &prop_threat, false, &prop_distance_to_unit, false),
	behv_stay_put
]);

//strat_guard_mothership
const Strategy strat_guard_mothership = new Strategy("GMsh", [
	new Behavior(&qual_has_friendly_mothership_and_enemies, &prop_distance_to_unit, false),
	new Behavior(&qual_has_friendly_mothership_and_is_threatened, &prop_threat_diff, false, &prop_distance_to_unit, false),
	to!(const Evaluable)(strat_guard_most_threatened)
]);

//strat_guard_economy
const Strategy strat_guard_economy = new Strategy("GEco", [
	new Behavior(&qual_has_friendly_miners_and_enemies, &prop_distance_to_unit, false),
	new Behavior(&qual_is_friendly_and_has_enemies, &prop_distance_to_unit, false),
	new Behavior(&qual_has_friendly_miners_and_is_threatened, &prop_threat_diff, false, &prop_distance_to_unit, false),
	new Behavior(&qual_is_friendly, &prop_threat_diff, false, &prop_distance_to_unit, false),
	to!(const Evaluable)(strat_capture_least_guarded)
]);

//strat_guard_most_threatened
const Strategy strat_guard_most_threatened = new Strategy("GThr", [
	new Behavior(&qual_is_friendly_and_has_enemies, &prop_distance_to_unit, false),
	new Behavior(&qual_is_friendly, &prop_threat_diff, false, &prop_distance_to_unit, false),
	to!(const Evaluable)(strat_capture_least_guarded)
]);

//strat_contest_caps
const Strategy strat_contest_caps = new Strategy("StCp", [
	new Behavior(&qual_is_friendly_or_neutral_and_has_enemies, &prop_distance_to_unit, false),
	new Behavior(&qual_is_neutral, &prop_threat_diff, false, &prop_distance_to_unit, false), //TODO: once I've added epsilons, maybe swap that around.
	to!(const Evaluable)(strat_guard_most_threatened)
]);

//strat_stay_safe  //TODO: if things are running into bad places, maybe prioritize friendly/neutral with no threat
const Strategy strat_stay_safe = new Strategy("Run!", [
	new Behavior(&qual_all, &prop_threat, false, &prop_distance_to_unit, false)
]);

//strat_spread_out
const Strategy strat_spread_out = new Strategy("Sprd", [
	new Behavior(&qual_not_threatened, &prop_number_of_this_friendly_unit_type, false, &prop_distance_to_unit, false),
	to!(const Evaluable)(strat_stay_safe)
]);

//strat_expand_safe
const Strategy strat_expand_safe = new Strategy("CpEx", [
	new Behavior(&qual_not_friendly_and_not_threatened, &prop_same_team_units_going_to, false, &prop_distance_to_unit, false),
	to!(const Evaluable)(strat_capture_least_guarded)
]);

//strat_kite_and_snipe
const Strategy strat_kite_and_snipe = new Strategy("Kite", [
	new Behavior(&qual_has_no_enemies, &prop_threat_diff, false, &prop_distance_to_unit, false),
	to!(const Evaluable)(strat_attack_weakest_enemy_force)
]);

//strat_decap_least_gaurded
const Strategy strat_decap_least_gaurded = new Strategy("DCap", [
	new Behavior(&qual_is_enemy, &prop_threat, false, &prop_distance_to_unit, false),
	to!(const Evaluable)(strat_contest_caps)
]);

//strat_attack_countered_units
const Strategy strat_attack_countered_units = new Strategy("Hunt", [
	new Behavior(&qual_has_countered_unit, &prop_threat, false, &prop_distance_to_unit, false),
	to!(const Evaluable)(strat_attack_weakest_enemy_force)
]);


///////////////
//qualifiers:
///////////////

//qual_all
bool qual_all (StateInfo gamestate, int i)
{
	return true; //ez
}

//qual_has_enemy_mothership
bool qual_has_enemy_mothership (StateInfo gamestate, int i)
{
	return gamestate._team._opponent._unit_counts[i][UnitType.Mothership] > 0;
}

//qual_has_enemy_miners
bool qual_has_enemy_miners (StateInfo gamestate, int i)
{
	return gamestate._team._opponent._unit_counts[i][UnitType.Miner] > 0;
}

//qual_has_enemies
bool qual_has_enemies (StateInfo gamestate, int i)
{
	return gamestate._team._opponent._unit_total_cost_at_points[i] > 0.0001;
}

//qual_has_no_enemies
bool qual_has_no_enemies (StateInfo gamestate, int i)
{
	return !qual_has_enemies(gamestate, i);
}

//qual_not_friendly
bool qual_not_friendly (StateInfo gamestate, int i)
{
	// gee, that point is a jerk!
	return !qual_is_friendly(gamestate, i);
}

//qual_is_enemy
bool qual_is_enemy (StateInfo gamestate, int i)
{
	TeamID opponent_id = gamestate._team._opponent._id;
	CapturePoint point = gamestate._points[i];
	return point._team_id == opponent_id;
}

//qual_is_friendly_or_unguarded_neutral
bool qual_is_friendly_or_unguarded_neutral (StateInfo gamestate, int i)
{
	return qual_is_friendly(gamestate, i) || (qual_is_neutral(gamestate, i) && !qual_is_threatened(gamestate, i));
}

//qual_is_friendly
bool qual_is_friendly (StateInfo gamestate, int i)
{
	TeamID friendly_id = gamestate._team._id;
	CapturePoint point = gamestate._points[i];
	return point._team_id == friendly_id;
}

//qual_is_neutral
bool qual_is_neutral (StateInfo gamestate, int i)
{
	CapturePoint point = gamestate._points[i];
	return point._team_id == TeamID.Neutral;
}

//qual_has_friendly_miners_and_enemies
bool qual_has_friendly_miners_and_enemies (StateInfo gamestate, int i)
{
	return qual_has_friendly_miners(gamestate, i) && qual_has_enemies(gamestate, i);
}

//qual_is_friendly_and_has_enemies
bool qual_is_friendly_and_has_enemies (StateInfo gamestate, int i)
{
	return qual_is_friendly(gamestate, i) && qual_has_enemies(gamestate, i);
}

//qual_has_friendly_miners_and_is_threatened
bool qual_has_friendly_miners_and_is_threatened (StateInfo gamestate, int i)
{
	return qual_has_friendly_miners(gamestate, i) && qual_is_threatened(gamestate, i);
}

//qual_has_friendly_mothership_and_enemies
bool qual_has_friendly_mothership_and_enemies (StateInfo gamestate, int i)
{
	return qual_has_friendly_mothership(gamestate, i) && qual_has_enemies(gamestate, i);
}

//qual_has_friendly_mothership_and_is_threatened
bool qual_has_friendly_mothership_and_is_threatened (StateInfo gamestate, int i)
{
	return qual_has_friendly_mothership(gamestate, i) && qual_is_threatened(gamestate, i);
}

//qual_is_friendly_or_neutral_and_has_enemies
bool qual_is_friendly_or_neutral_and_has_enemies (StateInfo gamestate, int i)
{
	return (qual_is_friendly(gamestate, i) || qual_is_neutral(gamestate, i)) && qual_has_enemies(gamestate, i);
}

//qual_has_friendly_mothership
bool qual_has_friendly_mothership (StateInfo gamestate, int i)
{
	return gamestate._team._unit_counts[i][UnitType.Mothership] > 0;
}

//qual_has_friendly_miners
bool qual_has_friendly_miners (StateInfo gamestate, int i)
{
	return gamestate._team._unit_counts[i][UnitType.Miner] > 0;
}

//qual_is_threatened
bool qual_is_threatened (StateInfo gamestate, int i)
{
	TeamID opponent_id = gamestate._team._opponent._id;
	CapturePoint point = gamestate._points[i];
	return point.getThreatAmountForTeam(opponent_id) >= 0.00001;
}

//qual_not_friendly_and_not_threatened
bool qual_not_friendly_and_not_threatened (StateInfo gamestate, int i)
{
	return !qual_is_friendly(gamestate, i) && !qual_is_threatened(gamestate, i);
}

//qual_not_threatened
bool qual_not_threatened (StateInfo gamestate, int i)
{
	return !qual_is_threatened(gamestate, i);
}


immutable UnitType[][UnitType] counter_table; // static-init of an associative array is awkward
shared static this() 
{
	UnitType[][UnitType] temp;
		temp[UnitType.Interceptor] = [UnitType.Destroyer  , UnitType.Miner     ];
		temp[UnitType.Destroyer  ] = [UnitType.Battleship , UnitType.Mothership];
		temp[UnitType.Cruiser    ] = [UnitType.Interceptor, UnitType.Miner     ];
		temp[UnitType.Battleship ] = [UnitType.Cruiser    , UnitType.Mothership];
		temp[UnitType.Mothership ] = [];
		temp[UnitType.Miner      ] = [];
		
	counter_table = assumeUnique(temp);                            
}

//qual_has_countered_unit
bool qual_has_countered_unit (StateInfo gamestate, int i)
{
	
	UnitType unit_type = gamestate._unit._type;
	if (counter_table[unit_type].length == 0)
		return false;
	TeamObj opponent = gamestate._team._opponent;
	foreach(type; counter_table[unit_type])
	{
		if(opponent._unit_counts[i][to!int(type)] > 0)
		{
			return true;
		}
	}
	return false;
}



///////////////
//properties:
///////////////

//prop_distance_to_unit
double prop_distance_to_unit (StateInfo gamestate, int i)
{
	CapturePoint point = gamestate._points[i];
	return pow(point._pos.x - gamestate._unit._pos.x, 2) + pow(point._pos.y - gamestate._unit._pos.y, 2);
}

//prop_threat
double prop_threat (StateInfo gamestate, int i)
{
	TeamID opponent_id = gamestate._team._opponent._id;
	CapturePoint point = gamestate._points[i];
	return point.getThreatAmountForTeam(opponent_id);
}

//prop_threat_diff
double prop_threat_diff (StateInfo gamestate, int i)
{
	CapturePoint point = gamestate._points[i];
	return point.getThreatDiffForTeam(gamestate._team._id);
}

//prop_enemy_presence
double prop_enemy_presence (StateInfo gamestate, int i)
{
	return gamestate._team._opponent._unit_total_cost_at_points[i];
}

//prop_number_of_this_friendly_unit_type
double prop_number_of_this_friendly_unit_type (StateInfo gamestate, int i)
{
	UnitType type = gamestate._unit._type;
	return gamestate._team._unit_destination_counts[i][type];
}


//prop_same_team_units_going_to
double prop_same_team_units_going_to (StateInfo gamestate, int i)
{
	int sum = 0;
	for( UnitType iter = UnitType.min; iter < UnitType.max; ++iter )
	{
		sum += gamestate._team._unit_destination_counts[i][iter];
	}
	return sum;
}


//prop_same_team_threat
double prop_same_team_threat (StateInfo gamestate, int i)
{
	TeamID team_id = gamestate._team._id;
	CapturePoint point = gamestate._points[i];
	return point.getThreatAmountForTeam(team_id);
}