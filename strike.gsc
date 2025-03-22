#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "strike", 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "strike", 8, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "strike", 0, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "strike", 6, 0, 300 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "strike", 0, 0, 1000 );

	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "searchdestroy";
	game["dialog"]["offense_obj"] = "objs_destroy";
	game["dialog"]["defense_obj"] = "objs_defend";
}

onPrecacheGameType()
{
	game["bomb_dropped_sound"] = "mp_war_objective_lost";
	game["bomb_recovered_sound"] = "mp_war_objective_taken";

	precacheShader("waypoint_bomb");
	precacheShader("hud_suitcase_bomb");
	precacheShader("waypoint_target");
	precacheShader("waypoint_target_a");
	precacheShader("waypoint_target_b");
	precacheShader("waypoint_target_c");
	precacheShader("waypoint_target_d");
	precacheShader("waypoint_defend");
	precacheShader("waypoint_defend_a");
	precacheShader("waypoint_defend_b");
	precacheShader("waypoint_defend_c");
	precacheShader("waypoint_defend_d");
	precacheShader("waypoint_defuse");
	precacheShader("waypoint_defuse_a");
	precacheShader("waypoint_defuse_b");
	precacheShader("waypoint_defuse_c");
	precacheShader("waypoint_defuse_d");
	precacheShader("compass_waypoint_target");
	precacheShader("compass_waypoint_target_a");
	precacheShader("compass_waypoint_target_b");
	precacheShader("compass_waypoint_target_c");
	precacheShader("compass_waypoint_target_d");
	precacheShader("compass_waypoint_defend");
	precacheShader("compass_waypoint_defend_a");
	precacheShader("compass_waypoint_defend_b");
	precacheShader("compass_waypoint_defend_c");
	precacheShader("compass_waypoint_defend_d");
	precacheShader("compass_waypoint_defuse");
	precacheShader("compass_waypoint_defuse_a");
	precacheShader("compass_waypoint_defuse_b");
	precacheShader("compass_waypoint_defuse_c");
	precacheShader("compass_waypoint_defuse_d");
	
	precacheStatusIcon( "hud_suitcase_bomb" );
	
	precacheString( &"MP_EXPLOSIVES_RECOVERED_BY" );
	precacheString( &"MP_EXPLOSIVES_DROPPED_BY" );
	precacheString( &"MP_EXPLOSIVES_PLANTED_BY" );
	precacheString( &"MP_EXPLOSIVES_DEFUSED_BY" );
	precacheString( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
	precacheString( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	precacheString( &"MP_CANT_PLANT_WITHOUT_BOMB" );	
	precacheString( &"MP_PLANTING_EXPLOSIVE" );	
	precacheString( &"MP_DEFUSING_EXPLOSIVE" );	
}

onStartGameType()
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	

	if ( !isDefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	// war server - fazer o ataque sempre atacar
	if ( getDvarInt ( "war_server" ) == 1 && getDvarInt ( "ws_start" ) == 2 && getDvarInt ( "ws_real") > 0 )
	{	
		if( getDvar("ws_attackers") != "")
		{
			if ( getDvar("ws_attackers") == "blue" )
			{
				if ( maps\mp\gametypes\_warserver::Testa_Cor ( game["attackers"] ) == "red" )
				{
					game["switchedsides"] = true;
				}
			}
			else if ( getDvar("ws_attackers") == "red" )
			{
				if ( maps\mp\gametypes\_warserver::Testa_Cor ( game["attackers"] ) == "blue" )
				{
					game["switchedsides"] = true;
				}
			}
		}
	}
	
	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}
	
	setClientNameMode( "manual_change" );
	
	// targets_destroyed
	if ( getDvar( "scr_targets_endtext" ) == "" )
	{
		level.targets_destroyed = "Targets Destroyed";
	}
	else
	{
		level.targets_destroyed = getDvar( "scr_targets_endtext" );
	}	

	level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");
	
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_STRIKE_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_TARGETS_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_STRIKE_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_TARGETS_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_STRIKE_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_TARGETS_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_TARGETS_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_TARGETS_DEFENDER_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// posição spawns para marcar spawns da defesa/ataque!
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	level.defender_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );		
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	allowed[3] = "sab";
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	thread updateGametypeDvars();
	
	CalculaSpawnsDefesa();
	
	level.pos_maleta_sab = undefined;
	level.pos_sab_move = undefined;	
	
	novos_sd_init();
	
	if ( level.novos_objs )
	{
		//thread DeleteSabBombs();
		thread bombs();
	}
	else
		thread bombsRELOAD();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
}

CalculaSpawnsDefesa()
{
	// inicia spaws da defesa
	level.DefesaSpawns = [];

	// distancia maxima para spawn ser válido!
	dist_max = distance(level.attack_spawn, level.defender_spawn)/3;
	
	// pega spawn SD
	spawnPoints = getEntArray( "mp_sd_spawn_defender", "classname" );
	assert( spawnPoints.size );
		
	for (i = 0; i < spawnpoints.size; i++)
	{
		level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
	}

	// pega spawns tdm
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( game["defenders"] );
	assert( spawnPoints.size );	
	
	// loop control
	tudo_ok = false;	
	
	// spawn_count
	spawn_count = 0;	
	
	if ( level.script == "mp_beltot_2" )
	{
		return;			
	}	
	
	// calcula distancia ideal pra cada mapa
	while( tudo_ok == false )
	{
		if ( spawnpoints.size < 3 )
		{
			logPrint( "Warning! spawnPoints Extras with low Size = " + spawnPoints.size + "\n");
			tudo_ok = true;
		}	
	
		for (i = 0; i < spawnpoints.size; i++)
		{
			dist = distance(level.defender_spawn, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist < dist_max)
				spawn_count++;
		}
		if ( spawn_count < 3 )
		{
			dist_max = dist_max + 500;
			spawn_count = 0;
		}
		else
			tudo_ok = true;
	}
	
	// cria lista de spawns
	for (i = 0; i < spawnpoints.size; i++)
	{
		dist = distance(level.defender_spawn, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist < dist_max)
			level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
	}	
}

onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	if ( game["teamScores"]["allies"] == level.scorelimit - 1 && game["teamScores"]["axis"] == level.scorelimit - 1 )
	{
		// overtime! team that's ahead in kills gets to defend.
		aheadTeam = getBetterTeam();
		if ( aheadTeam != game["defenders"] )
		{
			game["switchedsides"] = !game["switchedsides"];
		}
		else
		{
			level.halftimeSubCaption = "";
		}
		level.halftimeType = "overtime";
	}
	else
	{
		level.halftimeType = "halftime";
		game["switchedsides"] = !game["switchedsides"];
	}
}

getBetterTeam()
{
	kills["allies"] = 0;
	kills["axis"] = 0;
	deaths["allies"] = 0;
	deaths["axis"] = 0;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		team = player.pers["team"];
		if ( isDefined( team ) && (team == "allies" || team == "axis") )
		{
			kills[ team ] += player.kills;
			deaths[ team ] += player.deaths;
		}
	}
	
	if ( kills["allies"] > kills["axis"] )
		return "allies";
	else if ( kills["axis"] > kills["allies"] )
		return "axis";
	
	// same number of kills

	if ( deaths["allies"] < deaths["axis"] )
		return "allies";
	else if ( deaths["axis"] < deaths["allies"] )
		return "axis";
	
	// same number of deaths
	
	if ( randomint(2) == 0 )
		return "allies";
	return "axis";
}

onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
	
	//mp_bo2turbine
	/* 
	timeSpawn = self.pers["team"];
	atac = game["attackers"];
	logPrint( " attackers = " + atac + "\n");	
	logPrint( self.name + " = " + timeSpawn + " | Atac = " + atac + "\n");	
	*/

	if(self.pers["team"] == game["attackers"])
		spawnPointName = "mp_sd_spawn_attacker";
	else
		spawnPointName = "mp_sd_spawn_defender";

	if ( !isDefined( self.carryIcon ) && self.pers["team"] == game["attackers"] )
	{
		if ( level.splitscreen )
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 35, 35 );
			self.carryIcon setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -10, -50 );
			self.carryIcon.alpha = 0.75;
		}
		else
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 35, 35 );
			self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
			self.carryIcon.alpha = 0.75;
		}
	}

	if(self.pers["team"] == game["attackers"])
	{
		spawnPoints = getEntArray( spawnPointName, "classname" );
		assert( spawnPoints.size );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.DefesaSpawns );
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if ( self.pers["team"] == game["attackers"] )
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
		}
		else
		{
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			self spawn( spawnpoint.origin, spawnpoint.angles );
		}
	}
	else
		self spawn( spawnpoint.origin, spawnpoint.angles );

	level notify ( "spawned_player" );
}

dem_score()
{
	// atualiza score
	[[level._setTeamScore]]( game["attackers"], [[level._getTeamScore]]( game["attackers"] ) + 1 );
}

sd_endGame( winningTeam, endReasonText )
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	

	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

onDeadEvent( team )
{
	if ( level.bombExploded == 4 )
		return;

	if ( team == "all" )
	{
		while(1)
		{	
			if ( level.bombExploded == 2 && ( level.planted_A == false && level.planted_B == false && level.planted_C == false && level.planted_D == false ))	
				sd_endGame( "tie", game["strings"]["round_draw"] );
			else if ( level.bombExploded == 2 && ( level.planted_A == true || level.planted_B == true || level.planted_C == true || level.planted_D == true ) )
				sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
			else if ( level.bombExploded <= 2 && ( level.planted_A == true || level.planted_B == true || level.planted_C == true || level.planted_D == true ) )
				wait 1;
			else
				sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
		}
	}
	else if ( team == game["attackers"] )
	{
		while(1)
		{
			if ( level.bombExploded <= 2 && ( level.planted_A == true || level.planted_B == true || level.planted_C == true || level.planted_D == true ) )
			{
				wait 1;
			}				
			else if ( level.bombExploded == 2 && ( level.planted_A == false && level.planted_B == false && level.planted_C == false && level.planted_D == false ))
			{
				sd_endGame( "tie", game["strings"]["round_draw"] );
				return;
			}
			else if ( level.bombExploded >= 3 )
			{
				return;
			}
			else
			{
				sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
				return;
			}
		}
	}
	else if ( team == game["defenders"] )
	{
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
}


onOneLeftEvent( team )
{
	if ( level.bombExploded == 4 )
		return;
	
	//if ( team == game["attackers"] )
	warnLastPlayer( team );
}


onTimeLimit()
{
	// 2 bombas explodiram = ataque vence
	// 1 bomba explodiu = empate
	// 0 bombas = defesa vence
	
	if ( getDvarInt ( "war_server" ) == 1 && getDvarInt ( "ws_start" ) == 2 )	
		[[level._setTeamScore]]( game["defenders"], [[level._getTeamScore]]( game["defenders"] ) + 3 );
	
	if ( level.bombExploded >= 3 )
		sd_endGame( game["attackers"], game["strings"]["time_limit_reached"] );
	else if ( level.bombExploded == 2 )
		sd_endGame( "tie", game["strings"]["time_limit_reached"] );
	else
		sd_endGame( game["defenders"], game["strings"]["time_limit_reached"] );
}


warnLastPlayer( team )
{
	if ( !isdefined( level.warnedLastPlayer ) )
		level.warnedLastPlayer = [];
		
	if ( isDefined( level.warnedLastPlayer[team] ) )
		return;
		
	level.warnedLastPlayer[team] = true;

	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if ( isDefined( player.pers["team"] ) && player.pers["team"] == team && isdefined( player.pers["class"] ) )
		{
			if ( player.sessionstate == "playing" && !player.afk )
				break;
		}
	}
	
	if ( i == players.size )
		return;
	
	players[i] thread giveLastAttackerWarning();
}


giveLastAttackerWarning()
{
	self endon("death");
	self endon("disconnect");
		
	fullHealthTime = 0;
	interval = .05;
	
	while(1)
	{
		if ( self.health != self.maxhealth )
			fullHealthTime = 0;
		else
			fullHealthTime += interval;
		
		wait interval;
		
		if (self.health == self.maxhealth && fullHealthTime >= 3)
			break;
	}
	
	//self iprintlnbold(&"MP_YOU_ARE_THE_ONLY_REMAINING_PLAYER");
	self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "last_alive" );
	
	self maps\mp\gametypes\_missions::lastManSD();
	
	// hajas duel
	if ( level.HajasDuel > 0 )
	{
		self maps\mp\gametypes\_globallogic::HajasDuel();
	}	
}

updateGametypeDvars()
{
	level.plantTime = dvarFloatValue( "scr_strike_planttime", 5, 0, 20 );
	level.defuseTime = dvarFloatValue( "scr_strike_defusetime", 10, 0, 20 );
	level.bombTimer = dvarFloatValue( "scr_strike_bombtimer", 45, 1, 300 );
}

bombs()
{
	// controles
	level.bombExploded = 0;
	level.planted_A = false;
	level.planted_B = false;
	level.planted_C = false;
	level.planted_D = false;
	level.exploded_A = false;
	level.exploded_B = false;
	level.exploded_C = false;
	level.exploded_D = false;
	level.prorroga = false;
	level.sound_A = false;
	level.sound_B = false;
	level.sound_C = false;
	level.sound_D = false;
	
	novos_sd();	
	
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
	
	sab_bomb_target = undefined;
	sab_bomb_visuals = undefined;	

	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) )
	{
		maps\mp\_utility::error("No sd_bomb_pickup_trig trigger found in map.");
		return;
	}
	
	// salva trigger da maleta pra achar bomba correta
	maleta = trigger;
	
	visuals[0] = getEnt( "sd_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) )
	{
		maps\mp\_utility::error("No sd_bomb script_model found in map.");
		return;
	}	
	
	// inicia dizendo que tem sab
	level.sab_ok = true;
	
	// testa se tem sab
	testa_sab = getEnt( "sab_bomb_pickup_trig", "targetname" );
	if ( !isDefined( testa_sab ) ) 
	{
		level.sab_ok = false;
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );		
	}	
	
	if ( level.sab_ok == true )
	{	
		// deleta maleta sab
		sab_bomb_visuals[0] = getEnt( "sab_bomb", "targetname" );
		sab_bomb_visuals[0] delete();	
		testa_sab delete();

		novos_sab( true );
	}

	precacheModel( "prop_suitcase_bomb" );	
	visuals[0] setModel( "prop_suitcase_bomb" );
	
	trigger delete();
	visuals[0] delete();	
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	bombZones[bombZones.size] = getEnt( "sab_bomb_allies", "targetname" );
	bombZones[bombZones.size] = getEnt( "sab_bomb_axis", "targetname" );
	
	// A e B	// sd bombs
	for ( index = 0; index < bombZones.size; index++ )
	{
		trigger = bombZones[index];
		visuals = getEntArray( bombZones[index].target, "targetname" );
		
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
		bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
		bombZone maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
		label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
		if ( index == 0 )
			label = "_a";
		else if ( index == 1 )
			label = "_b";
		else if ( index == 2 )
			label = "_c";
		else if ( index == 3 )
			label = "_d";
		bombZone.label = label;
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		if ( index == 0 )
		{
			bombZone.onUse = ::onUsePlantObject_A;
			bombZone.onBeginUse = ::onBeginUse_A;
			bombZone.onEndUse = ::onEndUse_A;				
		}
		else if ( index == 1 )
		{
			bombZone.onUse = ::onUsePlantObject_B;
			bombZone.onBeginUse = ::onBeginUse_B;
			bombZone.onEndUse = ::onEndUse_B;
		}
		else if ( index == 2 )
		{
			bombZone.onUse = ::onUsePlantObject_C;
			bombZone.onBeginUse = ::onBeginUse_C;
			bombZone.onEndUse = ::onEndUse_C;
		}
		else if ( index == 3 )
		{
			bombZone.onUse = ::onUsePlantObject_D;
			bombZone.onBeginUse = ::onBeginUse_D;
			bombZone.onEndUse = ::onEndUse_D;
		}
		bombZone.onCantUse = ::onCantUse;
		bombZone.useWeapon = "briefcase_bomb_mp";
		
		for ( i = 0; i < visuals.size; i++ )
		{
			if ( isDefined( visuals[i].script_exploder ) )
			{
				bombZone.exploderIndex = visuals[i].script_exploder;
				break;
			}
		}
		
		level.bombZones[level.bombZones.size] = bombZone;
	}

	for ( index = 0; index < level.bombZones.size; index++ )
	{
		array = [];
		for ( otherindex = 0; otherindex < level.bombZones.size; otherindex++ )
		{
			if ( otherindex != index )
				array[ array.size ] = level.bombZones[otherindex];
		}
		level.bombZones[index].otherBombZones = array;
	}		
}

bombsRELOAD()
{
	// controles
	level.bombExploded = 0;
	level.planted_A = false;
	level.planted_B = false;
	level.planted_C = false;
	level.planted_D = false;
	level.exploded_A = false;
	level.exploded_B = false;
	level.exploded_C = false;
	level.exploded_D = false;
	level.prorroga = false;
	level.sound_A = false;
	level.sound_B = false;
	level.sound_C = false;
	level.sound_D = false;
	
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
	
	sab_bomb_visuals = undefined;	

	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) )
	{
		maps\mp\_utility::error("No sd_bomb_pickup_trig trigger found in map.");
		return;
	}
	
	// salva trigger da maleta pra achar bomba correta
	maleta = trigger;
	
	visuals[0] = getEnt( "sd_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) )
	{
		maps\mp\_utility::error("No sd_bomb script_model found in map.");
		return;
	}	

	// inicia dizendo que tem sab
	level.sab_ok = true;
	
	// testa se tem sab
	testa_sab = getEnt( "sab_bomb_pickup_trig", "targetname" );
	if ( !isDefined( testa_sab ) ) 
	{
		level.sab_ok = false;
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );		
	}	
	
	if ( level.sab_ok == true )
	{
		// pos da maleta do sab para mover o target pra lá
		maleta_sab = getEnt( "sab_bomb_pickup_trig", "targetname" );
		level.pos_maleta_sab = maleta_sab.origin;
		level.pos_maleta_sab = level.pos_maleta_sab + (0, 0, 60);
		
		// deleta maleta sab
		sab_bomb_visuals[0] = getEnt( "sab_bomb", "targetname" );
		
		sab_bomb_visuals[0] delete();	
		testa_sab delete();
	
		// pos do target mais perto do spawn inimigo que será movido para pos maleta sab acima
		level.pos_sab_move = DefineSabBomb( maleta );	
		
		novos_sab( false );
	}

	// desenha maleta SD
	precacheModel( "prop_suitcase_bomb" );	
	visuals[0] setModel( "prop_suitcase_bomb" );
	
	// deleta maleta SD
	trigger delete();
	visuals[0] delete();
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	bombZones[bombZones.size] = getEnt( "sab_bomb_allies", "targetname" );
	bombZones[bombZones.size] = getEnt( "sab_bomb_axis", "targetname" );
		
	// A e B	// sd bombs
	for ( index = 0; index < bombZones.size; index++ )
	{
		trigger = bombZones[index];
		visuals = getEntArray( bombZones[index].target, "targetname" );
		
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
		bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
		bombZone maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
		label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
		if ( index == 0 )
			label = "_a";
		else if ( index == 1 )
			label = "_b";
		else if ( index == 2 )
			label = "_c";
		else if ( index == 3 )
			label = "_d";
		bombZone.label = label;
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		if ( index == 0 )
		{
			bombZone.onUse = ::onUsePlantObject_A;
			bombZone.onBeginUse = ::onBeginUse_A;
			bombZone.onEndUse = ::onEndUse_A;				
		}
		else if ( index == 1 )
		{
			bombZone.onUse = ::onUsePlantObject_B;
			bombZone.onBeginUse = ::onBeginUse_B;
			bombZone.onEndUse = ::onEndUse_B;
		}
		else if ( index == 2 )
		{
			bombZone.onUse = ::onUsePlantObject_C;
			bombZone.onBeginUse = ::onBeginUse_C;
			bombZone.onEndUse = ::onEndUse_C;
		}
		else if ( index == 3 )
		{
			bombZone.onUse = ::onUsePlantObject_D;
			bombZone.onBeginUse = ::onBeginUse_D;
			bombZone.onEndUse = ::onEndUse_D;
		}				
		bombZone.onCantUse = ::onCantUse;
		bombZone.useWeapon = "briefcase_bomb_mp";
		
		for ( i = 0; i < visuals.size; i++ )
		{
			if ( isDefined( visuals[i].script_exploder ) )
			{
				bombZone.exploderIndex = visuals[i].script_exploder;
				break;
			}
		}
		
		level.bombZones[level.bombZones.size] = bombZone;
	}

	for ( index = 0; index < level.bombZones.size; index++ )
	{
		array = [];
		for ( otherindex = 0; otherindex < level.bombZones.size; otherindex++ )
		{
			if ( otherindex != index )
				array[ array.size ] = level.bombZones[otherindex];
		}
		level.bombZones[index].otherBombZones = array;
	}		
}

DefineSabBomb( maleta )
{
	// retorna sab target mais longe da maleta do SD

	sab_bomb_al = getEnt( "sab_bomb_allies", "targetname" );
	sab_bomb_ax = getEnt( "sab_bomb_axis", "targetname" );

	// como agora move a que tá longe, isso inverte no Strike!
	if ( distance(maleta.origin,sab_bomb_al.origin) < distance(maleta.origin,sab_bomb_ax.origin) )
	{
		return 1; // allies
	}
	else
	{
		return 0; // axis
	}
}

DeleteSabBombs()
{
	allowed = [];
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";

	maps\mp\gametypes\_gameobjects::main(allowed);
}

SabBombPosFinal( bomb )
{
	nova_origem = PhysicsTrace( bomb , bomb + ( 0, 0, -100 ) );
	
	//logPrint("distance = " + distance(nova_origem, bomb ) + "\n");
	
	if ( distance(nova_origem, bomb ) > 80 )
	{
		return bomb;
	}
	else
	{
		return nova_origem;
	}
}

onBeginUse_A( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;
		level.sound_A = true;

		if ( isDefined( level.sdBombModel_A ) )
			level.sdBombModel_A hide();
	}
	else
	{
		player.isPlanting = true;
		statusDialog( "securing"+self.label, game["attackers"] );	
	}
}

onBeginUse_B( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;
		level.sound_B = true;
		
		if ( isDefined( level.sdBombModel_B ) )
			level.sdBombModel_B hide();
	}
	else
	{
		player.isPlanting = true;
		statusDialog( "securing"+self.label, game["attackers"] );	
	}
}

onBeginUse_C( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;
		level.sound_C = true;

		if ( isDefined( level.sdBombModel_C ) )
			level.sdBombModel_C hide();
	}
	else
	{
		player.isPlanting = true;
		statusDialog( "securing"+self.label, game["attackers"] );	
	}
}

onBeginUse_D( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;
		level.sound_D = true;

		if ( isDefined( level.sdBombModel_D ) )
			level.sdBombModel_D hide();
	}
	else
	{
		player.isPlanting = true;
		statusDialog( "securing"+self.label, game["attackers"] );	
	}
}



onEndUse_A( team, player, result )
{
	if ( !isAlive( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel_A ) && !result )
		{
			level.sdBombModel_A show();
		}
	}
}

onEndUse_B( team, player, result )
{
	if ( !isAlive( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel_B ) && !result )
		{
			level.sdBombModel_B show();
		}
	}
}

onEndUse_C( team, player, result )
{
	if ( !isAlive( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel_C ) && !result )
		{
			level.sdBombModel_C show();
		}
	}
}

onEndUse_D( team, player, result )
{
	if ( !isAlive( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel_D ) && !result )
		{
			level.sdBombModel_D show();
		}
	}
}

onCantUse( player )
{
	player iPrintLnBold( &"MP_CANT_PLANT_WITHOUT_BOMB" );
}

onUsePlantObject_A( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted_A( self, player, self.label );
		player logString( "bomb planted!" );
		
		// gerencia bomba A
		level thread VoltaBomb_A( self );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );
		if ( !level.hardcoreMode )
			iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
	}
}

onUsePlantObject_B( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted_B( self, player, self.label );
		player logString( "bomb planted!" );
		
		// gerencia bomba B
		level thread VoltaBomb_B( self );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );
		if ( !level.hardcoreMode )
			iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
	}
}

onUsePlantObject_C( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted_C( self, player, self.label );
		player logString( "bomb planted!" );
		
		// gerencia bomba C
		level thread VoltaBomb_C( self );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );
		if ( !level.hardcoreMode )
			iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
	}
}

onUsePlantObject_D( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted_D( self, player, self.label );
		player logString( "bomb planted!" );
		
		// gerencia bomba D
		level thread VoltaBomb_D( self );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );
		if ( !level.hardcoreMode )
			iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
	}
}

// --------------------------------------- DEFUSING ONLY - INICIO --------------------------------------------

onUseDefuseObject_A( player )
{
	wait .05;
	
	player notify ( "bomb_defused_A" );
	player logString( "bomb defused!" );
	level thread bombDefused_A();
	
	if ( !level.hardcoreMode )
		iPrintLn( &"MP_EXPLOSIVES_DEFUSED_BY", player );

	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}

onUseDefuseObject_B( player )
{
	wait .05;
	
	player notify ( "bomb_defused_B" );
	player logString( "bomb defused!" );
	level thread bombDefused_B();

	if ( !level.hardcoreMode )
		iPrintLn( &"MP_EXPLOSIVES_DEFUSED_BY", player );

	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}

onUseDefuseObject_C( player )
{
	wait .05;
	
	player notify ( "bomb_defused_C" );
	player logString( "bomb defused!" );
	level thread bombDefused_C();
	
	if ( !level.hardcoreMode )
		iPrintLn( &"MP_EXPLOSIVES_DEFUSED_BY", player );

	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}

onUseDefuseObject_D( player )
{
	wait .05;
	
	player notify ( "bomb_defused_D" );
	player logString( "bomb defused!" );
	level thread bombDefused_D();
	
	if ( !level.hardcoreMode )
		iPrintLn( &"MP_EXPLOSIVES_DEFUSED_BY", player );

	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}

// --------------------------------------- DEFUSING ONLY - FIM --------------------------------------------

onDrop( player )
{
		if ( isDefined( player ) && isDefined( player.name ) )
			printOnTeamArg( &"MP_EXPLOSIVES_DROPPED_BY", game["attackers"], player );
			
//		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_lost", player.pers["team"] );
		if ( isDefined( player ) )
		 	player logString( "bomb dropped" );
		 else
		 	logString( "bomb dropped" );

	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );
	
	maps\mp\_utility::playSoundOnPlayers( game["bomb_dropped_sound"], game["attackers"] );
}


onPickup( player )
{
	player.isBombCarrier = true;
	
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );

	if ( isDefined( player ) && isDefined( player.name ) )
		printOnTeamArg( &"MP_EXPLOSIVES_RECOVERED_BY", game["attackers"], player );
			
	maps\mp\gametypes\_globallogic::leaderDialog( "bomb_taken", player.pers["team"] );
	player logString( "bomb taken" );

	maps\mp\_utility::playSoundOnPlayers( game["bomb_recovered_sound"], game["attackers"] );
	
	if ( player.pickupScore == false )
	{
		player.pickupScore = true;
		maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", player );
		player thread [[level.onXPEvent]]( "pickup" );	
	}
}


onReset()
{
}

bombPlanted_A( destroyedObj_A, player, label )
{
	level.planted_A = true;
	statusDialog( "losing"+label, game["defenders"] );

	destroyedObj_A.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();
	level.tickingObject_A = destroyedObj_A.visuals[0];

	// acerta o tempo / caso falte menos q o tempo da bomba explodir, tempo restante será o tempo da bomba.
	if ( (maps\mp\gametypes\_globallogic::getTimeRemaining() / 1000) < level.bombTimer )
	{
		maps\mp\gametypes\_globallogic::pauseTimer();
		level.timeLimitOverride = true;
		setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
		thread ExecProrroga();
	}
	setDvar( "ui_bomb_timer", 1 );

	// calcula e faz a suitcase cair, etc...
	trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
	
	tempAngle = randomfloat( 360 );
	forward = (cos( tempAngle ), sin( tempAngle ), 0);
	forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );
	
	level.sdBombModel_A = spawn( "script_model", trace["position"] );
	level.sdBombModel_A.angles = dropAngles;
	level.sdBombModel_A setModel( "prop_suitcase_bomb" );

	// bomba por ser desarmada
	destroyedObj_A setUpForDefusing( "_a" );
	destroyedObj_A.onUse = ::onUseDefuseObject_A;
	destroyedObj_A.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.destroyedObj_A = destroyedObj_A;
	
	BombTimerWait_A();
	
	// se desarmaram a bomba, não explode
	if ( level.planted_A == false )
		return;
	
	level.exploded_A = true;
	
	setDvar( "ui_bomb_timer", 0 );
	
	destroyedObj_A.visuals[0] maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.gameEnded )
		return;
	
	level.bombExploded++;
	
	explosionOrigin = level.sdBombModel_A.origin;
	level.sdBombModel_A hide();
	
	if ( isdefined( player ) && level.starstreak == 0 )
		destroyedObj_A.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
	else
		destroyedObj_A.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread smokeFX(explosionOrigin,rot);
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj_A.exploderIndex ) )
		exploder( destroyedObj_A.exploderIndex );
	
	destroyedObj_A maps\mp\gametypes\_gameobjects::disableObject();

	// diz q não tem mais nada plantado!
	level.planted_A = false;

	wait 1;	
	statusDialog( "secured"+label, game["attackers"] );
	statusDialog( "lost"+label, game["defenders"] );
	
	thread dem_score();

	if ( level.bombExploded == 4 )
	{
		setGameEndTime( 0 );
		wait 2;
		sd_endGame( game["attackers"], level.targets_destroyed );
	}
}

bombPlanted_B( destroyedObj_B, player, label )
{
	level.planted_B = true;
	statusDialog( "losing"+label, game["defenders"] );

	destroyedObj_B.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();
	level.tickingObject_B = destroyedObj_B.visuals[0];

	// acerta o tempo / caso falte menos q o tempo da bomba explodir, tempo restante será o tempo da bomba.
	if ( (maps\mp\gametypes\_globallogic::getTimeRemaining() / 1000) < level.bombTimer )
	{
		maps\mp\gametypes\_globallogic::pauseTimer();
		level.timeLimitOverride = true;
		setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
		thread ExecProrroga();
	}
	setDvar( "ui_bomb_timer", 1 );

	// calcula e faz a suitcase cair, etc...
	trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
	
	tempAngle = randomfloat( 360 );
	forward = (cos( tempAngle ), sin( tempAngle ), 0);
	forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );
	
	level.sdBombModel_B = spawn( "script_model", trace["position"] );
	level.sdBombModel_B.angles = dropAngles;
	level.sdBombModel_B setModel( "prop_suitcase_bomb" );

	// bomba por ser desarmada
	destroyedObj_B setUpForDefusing( "_b" );
	destroyedObj_B.onUse = ::onUseDefuseObject_B;
	destroyedObj_B.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.destroyedObj_B = destroyedObj_B;

	BombTimerWait_B();
	
	// se desarmaram a bomba, não explode
	if ( level.planted_B == false )
		return;	
	
	level.exploded_B = true;
	
	setDvar( "ui_bomb_timer", 0 );
	
	destroyedObj_B.visuals[0] maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.gameEnded )
		return;
	
	level.bombExploded++;
	
	explosionOrigin = level.sdBombModel_B.origin;
	level.sdBombModel_B hide();
	
	if ( isdefined( player ) && level.starstreak == 0 )
		destroyedObj_B.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
	else
		destroyedObj_B.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread smokeFX(explosionOrigin,rot);
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj_B.exploderIndex ) )
		exploder( destroyedObj_B.exploderIndex );
	
	destroyedObj_B maps\mp\gametypes\_gameobjects::disableObject();
	
	// diz q não tem mais nada plantado!
	level.planted_B = false;
	
	wait 1;
	statusDialog( "secured"+label, game["attackers"] );
	statusDialog( "lost"+label, game["defenders"] );	
	
	thread dem_score();
	
	if ( level.bombExploded == 4 )
	{
		setGameEndTime( 0 );
		wait 2;
		sd_endGame( game["attackers"], level.targets_destroyed );
	}
}

bombPlanted_C( destroyedObj_C, player, label )
{
	level.planted_C = true;
	statusDialog( "losing"+label, game["defenders"] );

	destroyedObj_C.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();
	level.tickingObject_C = destroyedObj_C.visuals[0];

	// acerta o tempo / caso falte menos q o tempo da bomba explodir, tempo restante será o tempo da bomba.
	if ( (maps\mp\gametypes\_globallogic::getTimeRemaining() / 1000) < level.bombTimer )
	{
		maps\mp\gametypes\_globallogic::pauseTimer();
		level.timeLimitOverride = true;
		setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
		thread ExecProrroga();
	}
	setDvar( "ui_bomb_timer", 1 );

	// calcula e faz a suitcase cair, etc...
	trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
	
	tempAngle = randomfloat( 360 );
	forward = (cos( tempAngle ), sin( tempAngle ), 0);
	forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );
	
	level.sdBombModel_C = spawn( "script_model", trace["position"] );
	level.sdBombModel_C.angles = dropAngles;
	level.sdBombModel_C setModel( "prop_suitcase_bomb" );

	// bomba por ser desarmada
	destroyedObj_C setUpForDefusing( "_c" );
	destroyedObj_C.onUse = ::onUseDefuseObject_C;
	destroyedObj_C.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.destroyedObj_C = destroyedObj_C;
	
	BombTimerWait_C();
	
	// se desarmaram a bomba, não explode
	if ( level.planted_C == false )
		return;
	
	level.exploded_C = true;
	
	setDvar( "ui_bomb_timer", 0 );
	
	destroyedObj_C.visuals[0] maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.gameEnded )
		return;
	
	level.bombExploded++;
	
	explosionOrigin = level.sdBombModel_C.origin;
	level.sdBombModel_C hide();
	
	if ( isdefined( player ) && level.starstreak == 0 )
		destroyedObj_C.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
	else
		destroyedObj_C.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread smokeFX(explosionOrigin,rot);
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj_C.exploderIndex ) )
		exploder( destroyedObj_C.exploderIndex );
	
	destroyedObj_C maps\mp\gametypes\_gameobjects::disableObject();

	// diz q não tem mais nada plantado!
	level.planted_C = false;

	wait 1;	
	statusDialog( "secured"+label, game["attackers"] );
	statusDialog( "lost"+label, game["defenders"] );
	
	thread dem_score();

	if ( level.bombExploded == 4 )
	{
		setGameEndTime( 0 );
		wait 2;
		sd_endGame( game["attackers"], level.targets_destroyed );
	}
}

bombPlanted_D( destroyedObj_D, player, label )
{
	level.planted_D = true;
	statusDialog( "losing"+label, game["defenders"] );

	destroyedObj_D.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();
	level.tickingObject_D = destroyedObj_D.visuals[0];

	// acerta o tempo / caso falte menos q o tempo da bomba explodir, tempo restante será o tempo da bomba.
	if ( (maps\mp\gametypes\_globallogic::getTimeRemaining() / 1000) < level.bombTimer )
	{
		maps\mp\gametypes\_globallogic::pauseTimer();
		level.timeLimitOverride = true;
		setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
		thread ExecProrroga();
	}
	setDvar( "ui_bomb_timer", 1 );

	// calcula e faz a suitcase cair, etc...
	trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
	
	tempAngle = randomfloat( 360 );
	forward = (cos( tempAngle ), sin( tempAngle ), 0);
	forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );
	
	level.sdBombModel_D = spawn( "script_model", trace["position"] );
	level.sdBombModel_D.angles = dropAngles;
	level.sdBombModel_D setModel( "prop_suitcase_bomb" );

	// bomba por ser desarmada
	destroyedObj_D setUpForDefusing( "_d" );
	destroyedObj_D.onUse = ::onUseDefuseObject_D;
	destroyedObj_D.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.destroyedObj_D = destroyedObj_D;
	
	BombTimerWait_D();
	
	// se desarmaram a bomba, não explode
	if ( level.planted_D == false )
		return;
	
	level.exploded_D = true;
	
	setDvar( "ui_bomb_timer", 0 );
	
	destroyedObj_D.visuals[0] maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.gameEnded )
		return;
	
	level.bombExploded++;
	
	explosionOrigin = level.sdBombModel_D.origin;
	level.sdBombModel_D hide();
	
	if ( isdefined( player ) && level.starstreak == 0 )
		destroyedObj_D.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
	else
		destroyedObj_D.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread smokeFX(explosionOrigin,rot);
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj_D.exploderIndex ) )
		exploder( destroyedObj_D.exploderIndex );
	
	destroyedObj_D maps\mp\gametypes\_gameobjects::disableObject();

	// diz q não tem mais nada plantado!
	level.planted_D = false;

	wait 1;	
	statusDialog( "secured"+label, game["attackers"] );
	statusDialog( "lost"+label, game["defenders"] );
	
	thread dem_score();

	if ( level.bombExploded == 4 )
	{
		setGameEndTime( 0 );
		wait 2;
		sd_endGame( game["attackers"], level.targets_destroyed );
	}
}

ExecProrroga()
{
	wait 1;

	waitTime = 0;
	level.prorroga = true;
	
	// aguarda o tempo da bomba
	while ( waitTime < level.bombTimer )
	{
		waitTime += 1;
		wait ( 1.0 );
	}		

	// após o tempo termina o jogo se não tiver bombas plantadas
	if ( level.planted_A == false && level.planted_B == false )
	{
		wait 2;
		thread onTimeLimit();
	}
}

BombTimerWait_A()
{
	level endon("game_ended");
	level endon("bomb_defused_A");
	wait level.bombTimer;
}

BombTimerWait_B()
{
	level endon("game_ended");
	level endon("bomb_defused_B");
	wait level.bombTimer;
}

BombTimerWait_C()
{
	level endon("game_ended");
	level endon("bomb_defused_C");
	wait level.bombTimer;
}

BombTimerWait_D()
{
	level endon("game_ended");
	level endon("bomb_defused_D");
	wait level.bombTimer;
}


playSoundinSpace( alias, origin )
{
	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 10; // MP doesn't have "sounddone" notifies =(
	org delete();
}

bombDefused_A()
{
	level.planted_A = false;

	level.tickingObject_A maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.sound_A == true )
	{
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_defused" );
	}
	level.sound_A = false;
	
	if ( isDefined( level.sdBombModel_A ) )
		level.sdBombModel_A hide();	

	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused_A");
}

bombDefused_B()
{
	level.planted_B = false; 

	level.tickingObject_B maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.sound_B == true )
	{
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_defused" );
	}
	level.sound_B = false;
	
	if ( isDefined( level.sdBombModel_B ) )
		level.sdBombModel_B hide();		

	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused_B");
}

bombDefused_C()
{
	level.planted_C = false;

	level.tickingObject_C maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.sound_C == true )
	{
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_defused" );
	}
	level.sound_C = false;
	
	if ( isDefined( level.sdBombModel_C ) )
		level.sdBombModel_C hide();		

	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused_C");
}

bombDefused_D()
{
	level.planted_D = false;

	level.tickingObject_D maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.sound_D == true )
	{
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_defused" );
	}
	level.sound_D = false;
	
	if ( isDefined( level.sdBombModel_D ) )
		level.sdBombModel_D hide();		

	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused_D");
}

VoltaBomb_A( bomb )
{
	level endon("game_ended");
	
	while ( 1 )
	{
		if ( level.exploded_A == true )
		{
			return;
		}
		if ( level.planted_A == false )
		{
			// volta bomba
			bomb resetBombsite( "_a" );
			bomb.onUse = ::onUsePlantObject_A;
			return;
		}
		wait 1;
	}
}

VoltaBomb_B( bomb )
{
	level endon("game_ended");
	
	while ( 1 )
	{
		if ( level.exploded_B == true )
		{
			return;
		}
		if ( level.planted_B == false )
		{
			// volta bomba
			bomb resetBombsite( "_b" );
			bomb.onUse = ::onUsePlantObject_B;
			return;
		}
		wait 1;
	}
}

VoltaBomb_C( bomb )
{
	level endon("game_ended");
	
	while ( 1 )
	{
		if ( level.exploded_C == true )
		{
			return;
		}
		if ( level.planted_C == false )
		{
			// volta bomba
			bomb resetBombsite( "_c" );
			bomb.onUse = ::onUsePlantObject_C;
			return;
		}
		wait 1;
	}
}

VoltaBomb_D( bomb )
{
	level endon("game_ended");
	
	while ( 1 )
	{
		if ( level.exploded_D == true )
		{
			return;
		}
		if ( level.planted_D == false )
		{
			// volta bomba
			bomb resetBombsite( "_d" );
			bomb.onUse = ::onUsePlantObject_D;
			return;
		}
		wait 1;
	}
}

statusDialog( dialog, team )
{
	time = getTime();
	if ( getTime() < level.lastStatus[team] + 6000 )
		return;
		
	thread delayedLeaderDialog( dialog, team );
	level.lastStatus[team] = getTime();	
}
delayedLeaderDialog( sound, team )
{
	wait .1;
	maps\mp\gametypes\_globallogic::WaitTillSlowProcessAllowed();
	
	maps\mp\gametypes\_globallogic::leaderDialog( sound, team );
}

smokeFX( alvo, rot )
{
	alvo = alvo + (0,0,-100);
	smoke = spawnFx( level.smoke_tm, alvo, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( smoke );
	earthquake( 1, 1.5, alvo, 8000 );
}

// ================= SAB ====================

resetBombsite( label )
{
	self maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
	self maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
	self maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
	self maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
	self maps\mp\gametypes\_gameobjects::setKeyObject( level.sabBomb );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	self.useWeapon = "briefcase_bomb_mp";
}

setUpForDefusing( label )
{
	self maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	self maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	self maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	self maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	self maps\mp\gametypes\_gameobjects::setKeyObject( undefined );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" + label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" + label );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" + label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" + label );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
}

// ============ RANDOM =======================

novos_sd_init()
{
	level.novos_objs = true;
	temp = GetDvar ( "xsd_" + 0 );
	if ( temp == "" )
	{
		level.novos_objs = false;	
		return;
	}
		
	xsd(); // cria listas com pos
}

xsd()
{
	level.xsd_a = [];
	level.xsd_b = [];

	destroyed_models = getentarray("exploder", "targetname");
	trig_plant = getentarray("bombzone", "targetname");
	trig_plant_a = undefined;
	trig_plant_b = undefined;
	
	for(i=0 ; i<trig_plant.size ; i++)
	{
		if( trig_plant[i].script_label == "_a" )
			trig_plant_a = trig_plant[i];
		else if( trig_plant[i].script_label == "_b" )
			trig_plant_b = trig_plant[i];
	}

	level.xsd_a[0] = trig_plant_a.origin + (0, 0, 50);
	level.xsd_b[0] = trig_plant_b.origin + (0, 0, 50);

	gerando = true;
	index = 0;

	while (gerando)
	{
		temp = GetDvar ( "xsd_" + index );
		if ( temp == "eof" )
			gerando = false;
		else
		{
			temp = strtok( temp, "," );
			pos = (int(temp[0]),int(temp[1]),int(temp[2]));
			
			if ( distance( pos, level.xsd_a[0]) < distance( pos, level.xsd_b[0]) )
				level.xsd_a[level.xsd_a.size] = pos;
			else
				level.xsd_b[level.xsd_b.size] = pos;
				
		}	
		index++;
	}
}

novos_sd()
{
	if ( getDvarInt("fl_bots") == 1 && getDvarInt("bot_ok") == true )
	{
		id_a = RandomInt(level.xsd_a.size);
		while ( ObjValido(level.xsd_a[id_a]) == false )
		{
			id_a = RandomInt(level.xsd_a.size);
			logprint( "======================== Não Válido A!!! " + "\n");
		}
		exesd( level.xsd_a[id_a], 1 );
		level.xsd_a_sab = removeArray( level.xsd_a, id_a );
		
		id_b = RandomInt(level.xsd_b.size);
		while ( ObjValido(level.xsd_b[id_b]) == false )
		{
			id_b = RandomInt(level.xsd_b.size);
			logprint( "======================== Não Válido B!!! " + "\n");
		}
		exesd( level.xsd_b[id_b], 2 );
		level.xsd_b_sab = removeArray( level.xsd_b, id_b );	
	}
	else
	{
		bombA = RandomInt(level.xsd_a.size);
		exesd( level.xsd_a[bombA], 1 );
		level.xsd_a_sab = removeArray( level.xsd_a, bombA );

		bombB = RandomInt(level.xsd_b.size);
		exesd( level.xsd_b[bombB], 2 );
		level.xsd_b_sab = removeArray( level.xsd_b, bombB );
	}
}

exesd( pos, bomb )
{
	angles = (0,0,0);
	
	destroyed_models = getentarray("exploder", "targetname");
	trig_plant = getentarray("bombzone", "targetname");
	trig_plant_a = undefined;
	trig_plant_b = undefined;
	
	for(i=0 ; i<trig_plant.size ; i++)
	{
		if( trig_plant[i].script_label == "_a" )
			trig_plant_a = trig_plant[i];
		else if( trig_plant[i].script_label == "_b" )
			trig_plant_b = trig_plant[i];
	}

	a_destroyed_model = undefined;
	b_destroyed_model = undefined;
	
	if (IsDefined(destroyed_models))
	{
		for( i=0 ; i<destroyed_models.size ; i++ )
		{
			if( distance( destroyed_models[i].origin , trig_plant_a.origin ) <= 100 )
				a_destroyed_model = destroyed_models[i];
			
			if( distance( destroyed_models[i].origin , trig_plant_b.origin ) <= 100 )
				b_destroyed_model = destroyed_models[i];
		}
	}
	
//--------------------------------

	clips = getentarray( "script_brushmodel","classname" );
	obja_clip = undefined;
	objb_clip = undefined;
	
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{	
			if( clips[i].script_gameobjectname == "bombzone" )
			{
				if( distance( clips[i].origin , trig_plant_a.origin ) <= 100 )
					obja_clip = clips[i];
				
				if( distance( clips[i].origin , trig_plant_b.origin ) <= 100 )
					objb_clip = clips[i];
			}
		}
	}
	
//--------------------------------
	
	if ( bomb == 1 )
	{
		obj_a_origin = pos + (0, 0, -60);
		//obj_a_angles = trig_plant_a.angles;
		
		trig_plant_a.origin = obj_a_origin;
		
		if (IsDefined(a_destroyed_model))
			a_destroyed_model.origin = obj_a_origin;
		//a_destroyed_model.angles = obj_a_angles;
		
		a_obj_entire = getent( trig_plant_a.target, "targetname" );
		a_obj_entire.origin = obj_a_origin;
		//a_obj_entire.angles = obj_a_angles;
		
		obja_clip.origin = obj_a_origin + (0, 0, 30);
		//obja_clip rotateto( obj_a_angles, 0.1 );
	}
	else
	{
		obj_b_origin = pos + (0, 0, -60);
		//obj_b_angles = trig_plant_b.angles;
		
		trig_plant_b.origin = obj_b_origin;
		
		if (IsDefined(b_destroyed_model))
			b_destroyed_model.origin = obj_b_origin;
		//b_destroyed_model.angles = obj_b_angles;
		
		b_obj_entire = getent( trig_plant_b.target, "targetname" );
		b_obj_entire.origin = obj_b_origin;
		//b_obj_entire.angles = obj_b_angles;
		
		objb_clip.origin = obj_b_origin + (0, 0, 30);
		//objb_clip rotateto( obj_b_angles, 0.1 );
	}
}

// ================= SAB BOMBS =========================

novos_sab( todos )
{
	if ( todos == false )
		exesab( level.pos_maleta_sab, level.pos_sab_move ); // allies = 1, axis = 0
	else if ( todos == true )
	{
		if ( getDvarInt("fl_bots") == 1 && getDvarInt("bot_ok") == true )
		{
			id_a = RandomInt(level.xsd_a_sab.size);
			while ( ObjValido(level.xsd_a_sab[id_a]) == false )
			{
				id_a = RandomInt(level.xsd_a_sab.size);
				logprint( "======================== Não Válido A!!! " + "\n");
			}
			exesab( level.xsd_a_sab[id_a], 1 );	
			
			id_b = RandomInt(level.xsd_b_sab.size);
			while ( ObjValido(level.xsd_b_sab[id_b]) == false )
			{
				id_b = RandomInt(level.xsd_b_sab.size);
				logprint( "======================== Não Válido B!!! " + "\n");
			}
			exesab( level.xsd_b_sab[id_b], 0 );		
		}
		else
		{	
			exesab( level.xsd_a_sab[RandomInt(level.xsd_a_sab.size)], 1 );
			exesab( level.xsd_b_sab[RandomInt(level.xsd_b_sab.size)], 0 );	
		}
	}
		
}

exesab( pos, bomb )
{
	angles = (0,0,0);
	
	destroyed_models = getentarray("exploder", "targetname");
	trig_plant_allies = getent("sab_bomb_allies", "targetname");
	trig_plant_axis = getent("sab_bomb_axis", "targetname");
	allies_destroyed_model = undefined;
	axis_destroyed_model = undefined;
	
	for( i=0 ; i<destroyed_models.size ; i++ )
	{
		if( isdefined( trig_plant_allies ) && isdefined( trig_plant_axis ) )
		{
			if( distance( destroyed_models[i].origin , trig_plant_allies.origin ) <= 100 )
				allies_destroyed_model = destroyed_models[i];
			
			if( distance( destroyed_models[i].origin , trig_plant_axis.origin ) <= 100 )
				axis_destroyed_model = destroyed_models[i];
		}
	}
	
	clips = getentarray( "script_brushmodel" , "classname" );
	allies_clip = undefined;
	axis_clip = undefined;
	
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{	
			if( clips[i].script_gameobjectname == "sab" )
			{
				if( distance( clips[i].origin , trig_plant_allies.origin ) <= 100 )
					allies_clip = clips[i];
				
				if( distance( clips[i].origin , trig_plant_axis.origin ) <= 100 )
					axis_clip = clips[i];
			}
		}
	}
	

	if( bomb == 1 )
	{
		obj_allies_origin = pos + (0, 0, -60);
		//obj_allies_angles = angles;
		
		trig_plant_allies.origin = obj_allies_origin;
		
		allies_destroyed_model.origin = obj_allies_origin;
		//allies_destroyed_model.angles = obj_allies_angles;
		
		allies_obj_entire = getent(trig_plant_allies.target , "targetname" );
		allies_obj_entire.origin = obj_allies_origin;
		//allies_obj_entire.angles = obj_allies_angles;
		
		allies_clip.origin = obj_allies_origin + (0, 0, 30);
		//allies_clip rotateto( obj_allies_angles, 0.1 );
	}
	else
	{
		obj_axis_origin = pos + (0, 0, -60);
		//obj_axis_angles = angles;
		
		trig_plant_axis.origin = obj_axis_origin;
		
		axis_destroyed_model.origin = obj_axis_origin;
		//axis_destroyed_model.angles = obj_axis_angles;
		
		axis_obj_entire = getent(trig_plant_axis.target , "targetname" );
		axis_obj_entire.origin = obj_axis_origin;
		//axis_obj_entire.angles = obj_axis_angles;
		
		axis_clip.origin = obj_axis_origin + (0, 0, 30);
		//axis_clip rotateto( obj_axis_angles, 0.1 );
	}
}

// remove elemento do array e reorganiza.
removeArray( array, index )
{
    novoArray = [];

    for(i = 0; i < array.size; i++)
    {
        if(i < index)
			novoArray[i] = array[i];
        else if(i > index) 
			novoArray[i - 1] = array[i];
    }
    return novoArray;
}

ObjValido(pos)
{
    if(!isDefined(level.waypoints) || level.waypointCount == 0)
    {
		logprint( "======================== level.waypoints ZERADO! " + "\n");
        return -1;
    }

    if ( level.novos_objs == false )
		return true;
		
    nearestDistance = 200;
    for(i = 0; i < level.waypointCount; i++)
    {
        distance = Distance(pos, level.waypoints[i].origin);
    
        if(distance < nearestDistance)
			return true;
	}
	return false;
}