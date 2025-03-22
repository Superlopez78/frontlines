#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar 
registerFlagsUnityDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.FlagsUnityDvar = dvarString;
	level.FlagsUnityMin = minValue;
	level.FlagsUnityMax = maxValue;
	level.FlagsUnity = getDvarInt( level.FlagsUnityDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	registerFlagsUnityDvar( "scr_flags_unity", 0, 0, 1 );
	
	level.onPrecacheGameType = maps\mp\gametypes\sd::onPrecacheGameType;

	if ( level.FlagsUnity == 0 )
		init();
	else if ( level.FlagsUnity == 1 )
	{
		maps\mp\gametypes\unity::init();
		return;
	}
}

// funcao pra registrar o scr_flags_attackers_army
registerFlagsAttackDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.FlagsAttackDvar = dvarString;
	level.FlagsAttackMin = minValue;
	level.FlagsAttackMax = maxValue;
	level.FlagsAttack = getDvarInt( level.FlagsAttackDvar );
}

// funcao pra registrar o scr_flags_defenders_army
registerFlagsDefendDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.FlagsDefendDvar = dvarString;
	level.FlagsDefendMin = minValue;
	level.FlagsDefendMax = maxValue;
	level.FlagsDefend = getDvarInt( level.FlagsDefendDvar );
}

// funcao pra registrar o scr_flags_reinf
registerFlagsReinfDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.FlagsReinfDvar = dvarString;
	level.FlagsReinfMin = minValue;
	level.FlagsReinfMax = maxValue;
	level.FlagsReinf = getDvarInt( level.FlagsReinfDvar );
}


// funcao pra registrar o scr_flags_hold
registerFlagsHoldDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.FlagsHoldDvar = dvarString;
	level.FlagsHoldMin = minValue;
	level.FlagsHoldMax = maxValue;
	level.FlagsHold = getDvarInt( level.FlagsHoldDvar );
}

init()
{
	level.tem_koth = true;

	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "flags", 15, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "flags", 0, 0, 50000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "flags", 2, 1, 20 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "flags", 0, 0, 10 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "flags", 1, 1, 10 );
	registerFlagsAttackDvar( "scr_flags_attackers_army", 1000, 100, 5000 );
	registerFlagsDefendDvar( "scr_flags_defenders_army", 800, 100, 5000 );
	registerFlagsReinfDvar( "scr_flags_reinf", 50, 10, 500 );
	registerFlagsHoldDvar( "scr_flags_hold", 3, 1, 50 );
		
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPrecacheGameType = ::onPrecacheGameType;
	
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onRoundSwitch = ::onRoundSwitch;	
	level.onRespawnDelay = ::getRespawnDelay;
	
	level.onTimeLimit = ::onTimeLimit;

	game["dialog"]["gametype"] = "capturehold";
	game["dialog"]["offense_obj"] = "capture_objs";
	game["dialog"]["defense_obj"] = "objs_defend";
	
	game["dialog"]["ourflag"] = "ourflag";
	game["dialog"]["ourflag_capt"] = "ourflag_capt";
	game["dialog"]["enemyflag"] = "enemyflag";
	game["dialog"]["enemyflag_capt"] = "enemyflag_capt";
	
	// sounds
	// ourflag "the enemy has our flag!"
	// ourflag_capt "the enemy captured our flag!"
	// enemyflag "we have the enemy flag!"
	// enemyflag_capt "we captured the enemy flag!"

	// se não definido controle, cria como false
	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;
	
	if( game["roundsplayed"] == 0 )
	{
		SetDvar( "flags_allies_score", 0 );
		SetDvar( "flags_axis_score", 0 );
	}
	
	level.ControlaRespawn = false;
	level.ControlaDominion = false;
}


onPrecacheGameType()
{
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );
	precacheShader( "compass_waypoint_capture_a" );
	precacheShader( "compass_waypoint_defend_a" );
	precacheShader( "compass_waypoint_capture_b" );
	precacheShader( "compass_waypoint_defend_b" );
	precacheShader( "compass_waypoint_capture_c" );
	precacheShader( "compass_waypoint_defend_c" );
	precacheShader( "compass_waypoint_capture_d" );
	precacheShader( "compass_waypoint_defend_d" );
	precacheShader( "compass_waypoint_capture_e" );
	precacheShader( "compass_waypoint_defend_e" );

	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
	precacheShader( "waypoint_capture_a" );
	precacheShader( "waypoint_defend_a" );
	precacheShader( "waypoint_capture_b" );
	precacheShader( "waypoint_defend_b" );
	precacheShader( "waypoint_capture_c" );
	precacheShader( "waypoint_defend_c" );
	precacheShader( "waypoint_capture_d" );
	precacheShader( "waypoint_defend_d" );
	precacheShader( "waypoint_capture_e" );
	precacheShader( "waypoint_defend_e" );
	
	game["flagmodels"] = [];
	game["flagmodels"]["neutral"] = "prop_flag_neutral";

	if ( game["allies"] == "marines" )
		game["flagmodels"]["allies"] = "prop_flag_american";
	else
		game["flagmodels"]["allies"] = "prop_flag_brit";
	
	if ( game["axis"] == "russian" ) 
		game["flagmodels"]["axis"] = "prop_flag_russian";
	else
		game["flagmodels"]["axis"] = "prop_flag_opfor";
	
	precacheModel( game["flagmodels"]["neutral"] );
	precacheModel( game["flagmodels"]["allies"] );
	precacheModel( game["flagmodels"]["axis"] );
	
	precacheString( &"MP_CAPTURING_FLAG" );
	precacheString( &"MP_LOSING_FLAG" );
	precacheString( &"MP_DOM_YOUR_FLAG_WAS_CAPTURED" );
	precacheString( &"MP_DOM_ENEMY_FLAG_CAPTURED" );
	precacheString( &"MP_DOM_NEUTRAL_FLAG_CAPTURED" );

	precacheString( &"MP_ENEMY_FLAG_CAPTURED_BY" );
	precacheString( &"MP_NEUTRAL_FLAG_CAPTURED_BY" );
	precacheString( &"MP_FRIENDLY_FLAG_CAPTURED_BY" );

	flagBaseFX = [];
	flagBaseFX["marines"] = "misc/ui_flagbase_silver";
	flagBaseFX["sas"    ] = "misc/ui_flagbase_black";
	flagBaseFX["russian"] = "misc/ui_flagbase_red";
	flagBaseFX["opfor"  ] = "misc/ui_flagbase_gold";

	if ( !isDefined(flagBaseFX[ game[ "allies" ] ]) )
		return;	
		
	if ( !isDefined(flagBaseFX[ game[ "axis" ] ]) )
		return;			
	
	level.flagBaseFXid[ "allies" ] = loadfx( flagBaseFX[ game[ "allies" ] ] );
	level.flagBaseFXid[ "axis"   ] = loadfx( flagBaseFX[ game[ "axis"   ] ] );	
}

onStartGameType()
{	
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
					game["switchedsides"] = true;
			}
			else if ( getDvar("ws_attackers") == "red" )
			{
				if ( maps\mp\gametypes\_warserver::Testa_Cor ( game["attackers"] ) == "blue" )
					game["switchedsides"] = true;
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
		
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_FLAGS_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_FLAGS_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_FLAGS_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_FLAGS_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_FLAGS_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_FLAGS_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_FLAGS_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_FLAGS_DEFENDER" );

	setClientNameMode("auto_change");

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dom_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dom_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dom_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_dom_spawn" );
	
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	level.spawn_all = getentarray( "mp_dom_spawn", "classname" );
	level.spawn_axis_start = getentarray("mp_dom_spawn_axis_start", "classname" );
	level.spawn_allies_start = getentarray("mp_dom_spawn_allies_start", "classname" );
	
	level.startPos["allies"] = level.spawn_allies_start[0].origin;
	level.startPos["axis"] = level.spawn_axis_start[0].origin;
	
	dist_spawns = distance( level.startPos["allies"] , level.startPos["axis"] );
	//logPrint(  "dist_spawns = " + dist_spawns + "\n");	
	level.dist_inicial = dist_spawns / 5;	
	if ( level.script == "mp_cdi_mision_bunker" )
		level.dist_inicial = dist_spawns / 8;
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();		
	
	allowed[0] = "dom";
	allowed[1] = "sd";
	allowed[2] = "bombzone";
	allowed[3] = "hq";
	maps\mp\gametypes\_gameobjects::main(allowed);

	// testa se tem SD no mapa, senão aborta
	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) )
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}

	level.flagsErro = 0;

	novos_flag_init();	
	
	if ( !level.novos_objs )
	{
		getRadios();
		getBombs();
		getFlags();
	}
	else
	{
		allowed = [];
		allowed[0] = "dom";

		maps\mp\gametypes\_gameobjects::main(allowed);	
	}
	
	if ( level.flagsErro == 1 )
	{
		return;
	}
	
	if ( !level.novos_objs )
		StartNewFlags();
	
	thread domFlags();
	thread updateDomScores();	
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,dom" );
}

// ========================================================================
//		Player
// ========================================================================

onSpawnPlayer()
{
	flagsOwned = 0;
	enemyFlagsOwned = 0;
	myTeam = self.pers["team"];
	enemyTeam = getOtherTeam( myTeam );
	for ( i = 0; i < level.flags.size; i++ )
	{
		team = level.flags[i] getFlagTeam();
		if ( team == myTeam )
			flagsOwned++;
		else if ( team == enemyTeam )
			enemyFlagsOwned++;
	}
			
	if ( level.inGracePeriod )
	{
		if(self.pers["team"] == game["attackers"])
			spawnPointName = "mp_sd_spawn_attacker";
		else
			spawnPointName = "mp_sd_spawn_defender";

		spawnPoints = getEntArray( spawnPointName, "classname" );
		assert( spawnPoints.size );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

		self spawn( spawnpoint.origin, spawnpoint.angles );

		level notify ( "spawned_player" );
	}
	else
	{
		spawnpoint = undefined;
		
		if ( !level.useStartSpawns )
		{
			if ( flagsOwned == level.flags.size )
			{
				// own all flags! pretend we don't own the last one we got, so enemies can spawn there
				enemyBestSpawnFlag = level.bestSpawnFlag[ getOtherTeam( self.pers["team"] ) ];
				
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, getSpawnsBoundingFlag( enemyBestSpawnFlag ) );
			}
			else if ( flagsOwned > 0 )
			{
				// spawn near any flag we own that's nearish something we can capture
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, getBoundaryFlagSpawns( myTeam ) );
			}
			else
			{
				// own no flags!
				bestFlag = undefined;
				if ( enemyFlagsOwned > 0 && enemyFlagsOwned < level.flags.size )
				{
					// there should be an unowned one to use
					bestFlag = getUnownedFlagNearestStart( myTeam );
				}
				if ( !isdefined( bestFlag ) )
				{
					// pretend we still own the last one we lost
					bestFlag = level.bestSpawnFlag[ self.pers["team"] ];
				}
				level.bestSpawnFlag[ self.pers["team"] ] = bestFlag;
				
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.spawn_all, bestFlag.nearbyspawns );
			}
		}
		
		if ( !isdefined( spawnpoint ) )
		{
			if(self.pers["team"] == game["attackers"])
				spawnPointName = "mp_sd_spawn_attacker";
			else
				spawnPointName = "mp_sd_spawn_defender";		
		
			spawnPoints = getEntArray( spawnPointName, "classname" );
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
		}
		
		assert( isDefined(spawnpoint) );
		
		if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		{
			if ( flagsOwned < enemyFlagsOwned )
			{
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(level.spawn_all);
				maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
			}
			else
			{
				maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
				self spawn(spawnpoint.origin, spawnpoint.angles);
			}
		}
		else
			self spawn(spawnpoint.origin, spawnpoint.angles);		
	}
}
			
getRespawnDelay()
{
	flagsOwned = 0;
	myTeam = self.pers["team"];
	for ( i = 0; i < level.flags.size; i++ )
	{
		team = level.flags[i] getFlagTeam();
		if ( team == myTeam )
			flagsOwned++;
	}
	if ( flagsOwned == 0 )
	{
		level thread ControlaRespawn( myTeam ); 
		timeRemaining = 1000;
		return (int(timeRemaining));
	}
}

ControlaRespawn( myTeam )
{
	level endon("game_ended");

	// garante só uma thread
	if( level.ControlaRespawn == true )
		return;
		
	// diz que thread iniciou
	level.ControlaRespawn = true;

	// inicia controle de domínio
	thread ControlaDominion( myTeam );		
	
	while(1)
	{
		wait 2;
	
		// se morreram todos e não tem mais bandeiras
		if ( level.ControlaDominion == true )
			return; 
	
		flagsOwned = 0;
		for ( i = 0; i < level.flags.size; i++ )
		{
			team = level.flags[i] getFlagTeam();
			if ( team == myTeam )
				flagsOwned++;
		}
		if ( flagsOwned > 0 )
		{
			forceSpawnTeam( myTeam );
			level.ControlaRespawn = false;
			return;
		}
	}
}

ControlaDominion( myTeam )
{
	level endon("game_ended");
	
	while(1)
	{
		wait 3;

		flagsOwned = 0;
		for ( i = 0; i < level.flags.size; i++ )
		{
			team = level.flags[i] getFlagTeam();
			if ( team == myTeam )
				flagsOwned++;
		}
		if ( flagsOwned == 0 )
		{
			if ( level.everExisted[myTeam] && level.aliveCount[myTeam] == 0 )
			{
				level.ControlaDominion = true;
				[[level._setTeamScore]]( myTeam, 0 );
				return;
			}			
		}
	}
}

forceSpawnTeam( team )
{
	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		if ( !isdefined( player ) )
			continue;
		
		if ( player.pers["team"] == team )
		{
			player.lowerMessageOverride = undefined;
			player notify( "force_spawn" );
			wait .1;
		}
	}
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	team = self.pers["team"];
	if ( self.touchTriggers.size && isPlayer( attacker ) && attacker.pers["team"] != self.pers["team"] )
	{
		triggerIds = getArrayKeys( self.touchTriggers );
		ownerTeam = self.touchTriggers[triggerIds[0]].useObj.ownerTeam;
		
		if ( team == ownerTeam )
		{
			attacker thread [[level.onXPEvent]]( "assault" );
			maps\mp\gametypes\_globallogic::givePlayerScore( "assault", attacker );
		}
		else
		{
			attacker thread [[level.onXPEvent]]( "defend" );
			maps\mp\gametypes\_globallogic::givePlayerScore( "defend", attacker );
		}
	}
	
	if ( team == game["attackers"] )
	{
		[[level._setTeamScore]]( game["attackers"], [[level._getTeamScore]]( game["attackers"] ) - 1 );
	}
	else if ( team == game["defenders"] )
	{
		[[level._setTeamScore]]( game["defenders"], [[level._getTeamScore]]( game["defenders"] ) - 1 );
	}
}


// ========================================================================
//		Sound
// ========================================================================

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

delayedLeaderDialogBothTeams( sound1, team1, sound2, team2 )
{
	wait .1;
	maps\mp\gametypes\_globallogic::WaitTillSlowProcessAllowed();
	
	maps\mp\gametypes\_globallogic::leaderDialogBothTeams( sound1, team1, sound2, team2 );
}

// ========================================================================
//		Score
// ========================================================================

updateDomScores()
{
	// disable score limit check to allow both axis and allies score to be processed
	level.endGameOnScoreLimit = false;
	
	// inicia score
	[[level._setTeamScore]]( game["attackers"], level.FlagsAttack );
	[[level._setTeamScore]]( game["defenders"], level.FlagsDefend );

	while ( level.inPrematchPeriod )
		wait ( 0.05 );	

	while ( !level.gameEnded )
	{

		numFlags = getTeamFlagCount( game["attackers"] );
		if ( numFlags )
			[[level._setTeamScore]]( game["defenders"], [[level._getTeamScore]]( game["defenders"] ) - (numFlags * level.FlagsHold) );

		numFlags = getTeamFlagCount( game["defenders"] );
		if ( numFlags )
			[[level._setTeamScore]]( game["attackers"], [[level._getTeamScore]]( game["attackers"] ) - (numFlags * level.FlagsHold) );

		CheckFlagsFinal();
		level.endGameOnScoreLimit = false;
		wait ( 5.0 );
	}
}

CheckFlagsFinal()
{
	if ( [[level._getTeamScore]]( game["defenders"] ) <= 0 )
	{
		if ( [[level._getTeamScore]]( game["defenders"] ) < 0 )
		{
			[[level._setTeamScore]]( game["defenders"], 0 );
		}
			
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
	else if ( [[level._getTeamScore]]( game["attackers"] ) <= 0 )
	{
		if ( [[level._getTeamScore]]( game["attackers"] ) < 0 )
		{
			[[level._setTeamScore]]( game["attackers"], 0 );
		}
			
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
}

onTimeLimit()
{
	if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
		winner = "tie";
	else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
		winner = "axis";
	else
		winner = "allies";

	makeDvarServerInfo( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	setDvar( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	
		// help mode
		if ( level.HelpMode == 1 )
		{
			if ( winner == "axis" )
				SetDvar( "HM_Axis", getDvarInt("HM_Axis") + 1 );
			else if ( winner == "allies" )
				SetDvar( "HM_Allies", getDvarInt("HM_Allies") + 1 );	
				
			[[level._setTeamScore]]( "axis", getDvarInt("HM_Axis") );
			[[level._setTeamScore]]( "allies", getDvarInt("HM_Allies") );				
		}	

	sd_endGame( winner, game["strings"]["time_limit_reached"] );
}

getTeamFlagCount( team )
{
	score = 0;
	for (i = 0; i < level.flags.size; i++) 
	{
		if ( level.domFlags[i] maps\mp\gametypes\_gameobjects::getOwnerTeam() == team )
			score++;
	}	
	return score;
}

getFlagTeam()
{
	return self.useObj maps\mp\gametypes\_gameobjects::getOwnerTeam();
}

// ========================================================================
//		Dead Control
// ========================================================================

sd_endGame( winningTeam, endReasonText )
{
	if ( level.HelpMode == 0 )
	{
		SetDvar( "flags_allies_score",  getDvarInt("flags_allies_score") + [[level._getTeamScore]]( "allies" ) );
		SetDvar( "flags_axis_score", getDvarInt("flags_axis_score") + [[level._getTeamScore]]( "axis" ) );	
	}
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

onDeadEvent( team )
{
	if ( team == "all" )
	{
		[[level._setTeamScore]]( game["attackers"], 0 );
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["attackers"] )
	{
		[[level._setTeamScore]]( game["attackers"], 0 );
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		[[level._setTeamScore]]( game["defenders"], 0 );
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
}

onOneLeftEvent( team )
{
	//if ( team == game["attackers"] )
	warnLastPlayer( team );
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

// ========================================================================
//		Side Control
// ========================================================================

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

// ========================================================================
//		Spawn por Flags
// ========================================================================

getUnownedFlagNearestStart( team, excludeFlag )
{
	best = undefined;
	bestdistsq = undefined;
	for ( i = 0; i < level.flags.size; i++ )
	{
		flag = level.flags[i];
		
		if ( flag getFlagTeam() != "neutral" )
			continue;
		
		distsq = distanceSquared( flag.origin, level.startPos[team] );
		if ( (!isDefined( excludeFlag ) || flag != excludeFlag) && (!isdefined( best ) || distsq < bestdistsq) )
		{
			bestdistsq = distsq;
			best = flag;
		}
	}
	return best;
}

getBoundaryFlags()
{
	// get all flags which are adjacent to flags that aren't owned by the same team
	bflags = [];
	for (i = 0; i < level.flags.size; i++)
	{
		for (j = 0; j < level.flags[i].adjflags.size; j++)
		{
			if (level.flags[i].useObj maps\mp\gametypes\_gameobjects::getOwnerTeam() != level.flags[i].adjflags[j].useObj maps\mp\gametypes\_gameobjects::getOwnerTeam() )
			{
				bflags[bflags.size] = level.flags[i];
				break;
			}
		}
	}
	
	return bflags;
}

getBoundaryFlagSpawns(team)
{
	spawns = [];
	
	bflags = getBoundaryFlags();
	for (i = 0; i < bflags.size; i++)
	{
		if (isdefined(team) && bflags[i] getFlagTeam() != team)
			continue;
		
		for (j = 0; j < bflags[i].nearbyspawns.size; j++)
			spawns[spawns.size] = bflags[i].nearbyspawns[j];
	}
	
	return spawns;
}

getSpawnsBoundingFlag( avoidflag )
{
	spawns = [];

	for (i = 0; i < level.flags.size; i++)
	{
		flag = level.flags[i];
		if ( flag == avoidflag )
			continue;
		
		isbounding = false;
		for (j = 0; j < flag.adjflags.size; j++)
		{
			if ( flag.adjflags[j] == avoidflag )
			{
				isbounding = true;
				break;
			}
		}
		
		if ( !isbounding )
			continue;
		
		for (j = 0; j < flag.nearbyspawns.size; j++)
			spawns[spawns.size] = flag.nearbyspawns[j];
	}
	
	return spawns;
}

// gets an array of all spawnpoints which are near flags that are
// owned by the given team, or that are adjacent to flags owned by the given team.
getOwnedAndBoundingFlagSpawns(team)
{
	spawns = [];

	for (i = 0; i < level.flags.size; i++)
	{
		if ( level.flags[i] getFlagTeam() == team )
		{
			// add spawns near this flag
			for (s = 0; s < level.flags[i].nearbyspawns.size; s++)
				spawns[spawns.size] = level.flags[i].nearbyspawns[s];
		}
		else
		{
			for (j = 0; j < level.flags[i].adjflags.size; j++)
			{
				if ( level.flags[i].adjflags[j] getFlagTeam() == team )
				{
					// add spawns near this flag
					for (s = 0; s < level.flags[i].nearbyspawns.size; s++)
						spawns[spawns.size] = level.flags[i].nearbyspawns[s];
					break;
				}
			}
		}
	}
	
	return spawns;
}

// gets an array of all spawnpoints which are near flags that are
// owned by the given team
getOwnedFlagSpawns(team)
{
	spawns = [];

	for (i = 0; i < level.flags.size; i++)
	{
		if ( level.flags[i] getFlagTeam() == team )
		{
			// add spawns near this flag
			for (s = 0; s < level.flags[i].nearbyspawns.size; s++)
				spawns[spawns.size] = level.flags[i].nearbyspawns[s];
		}
	}
	
	return spawns;
}

// ========================================================================
//		Flags
// ========================================================================

getFlags()
{
	primaryFlags = getEntArray( "flag_primary", "targetname" );
	secondaryFlags = getEntArray( "flag_secondary", "targetname" );

	default_flags = [];
	for ( index = 0; index < primaryFlags.size; index++ )
		default_flags[default_flags.size] = primaryFlags[index];
	
	for ( index = 0; index < secondaryFlags.size; index++ )
		default_flags[default_flags.size] = secondaryFlags[index];
	
	////logPrint("NewFlag0 = " + level.newFlags[0] + "\n");	
	////logPrint("NewFlag1 = " + level.newFlags[1] + "\n");
	
	level.flags_size = default_flags.size;

	/*if(getdvar("mapname") == "mp_citystreets")
		level.dist_inicial = 1000;
	else
		level.dist_inicial = 500;
	*/

	// inicia vars finais
	level.pos_01_final = undefined;
	level.pos_02_final = undefined;
	
	// pega um dos 2 do SD random
	level.NewSpot = randomInt( 2 );
	
	if ( default_flags.size == 3 )
	{
		Add_2_Flags( default_flags );
		
		// atualiza flags finais
		level.newFlags[0] = level.pos_01_final;
		level.newFlags[1] = level.pos_02_final;
	}
	else if ( default_flags.size == 4 )
	{
		Add_1_Flag( default_flags );
		
		// ambas recebem o mesmo valor pois é uma só
		level.newFlags[0] = level.pos_01_final;
		level.newFlags[1] = level.pos_01_final;
	}
	
	////logPrint("NewFlag0 = " + level.newFlags[0] + "\n");	
	////logPrint("NewFlag1 = " + level.newFlags[1] + "\n");	
}

Add_1_Flag( default_flags )
{
	Pos01 = level.newFlags[level.NewSpot];
	Pos02 = level.newFlags[!level.NewSpot];

	// inicia dizendo q os 2 estao ok
	pos_1 = 1;
	pos_2 = 1;

	// testa pos 1
	for ( index = 0; index < default_flags.size; index++ )
	{	
		flag = default_flags[index];
		if ( distance( flag.origin, Pos01 ) < level.dist_inicial )
		{
			// diz que posição é inválida
			pos_1 = 0; 
		}
	}
	
	// se ok, deixa ela como única válida e sai
	if ( pos_1 == 1 )
	{
		level.pos_01_final = Pos01;
		return;
	}
	else if ( pos_1 == 0 ) // caso a 1a esteja ruin, testa a 2a
	{
		// testa pos 2
		for ( index = 0; index < default_flags.size; index++ )
		{	
			flag = default_flags[index];
			if ( distance( flag.origin, Pos02 ) < level.dist_inicial )
			{
				// diz que posição é inválida
				pos_2 = 0; 
			}
		}
	}	
	
	// se ok, deixa ela como única válida e sai
	if ( pos_2 == 1 )
	{
		level.pos_01_final = Pos02;
		return;
	}
	else if ( getdvar("mapname") == "mp_pipeline" )
	{
		level.pos_01_final = (-1129,-798,264);
		return;
	}
	else if ( level.tem_koth == true )
	{
		// ambas são ruins, tem q procurar uma do koth caso tenha koth no mapa
		
		// pega lista de radios
		FlagRadiosTemp = level.FlagRadios;

		test = 0;
		while( test == 0 )
		{
			if ( FlagRadiosTemp.size == 0 )
			{
				test = 1;
			}
			else
			{		
				// seleciona um random
				radio_index = randomInt(FlagRadiosTemp.size);
				radio = FlagRadiosTemp[radio_index];
				
				// remove ele da lista pra não procurar novamente
				FlagRadiosTemp = maps\mp\gametypes\_globallogic::removeArray( FlagRadiosTemp, radio_index );
				
				pode = 1;
				for ( index = 0; index < default_flags.size; index++ )
				{	
					flag = default_flags[index];
					if ( distance( radio, flag.origin ) < 500 || distance( radio, level.attack_spawn ) < 1500 )
					{
						pode = 0;
					}								
				}
				
				// se passou por todas as flags sem problema, é este! senão vamos para prox HQ
				if ( pode == 1 )
				{
					level.pos_01_final = radio;
					return;
				}				
			}
		}
		// se sair do while diz q NENHUM hq é longe o suficiente
		logPrint("map is too short to this gametype" + "\n");
		level.flagsErro = 1;
		//maps\mp\_utility::error("Map errors. See above");
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;		
	}
	else
	{
		// adiciona no spawn da defesa
		level.pos_01_final = level.defend_spawn;
		return;
	}
}

Add_Outra_Flag( default_flags )
{
	// testa se um dos SD sites foi o escolhido
	if ( level.newFlags[level.NewSpot] != level.pos_01_final && level.newFlags[!level.NewSpot] != level.pos_01_final )
	{
		// foi escolhido um koth, vamos escolher outro koth
		
		// pega lista de radios
		FlagRadiosTemp = level.FlagRadios;

		test = 0;
		while( test == 0 )
		{
			if ( FlagRadiosTemp.size == 0 )
			{
				test = 1;
			}
			else
			{		
				// seleciona um random
				radio_index = randomInt(FlagRadiosTemp.size);
				radio = FlagRadiosTemp[radio_index];
				
				// remove ele da lista pra não procurar novamente
				FlagRadiosTemp = maps\mp\gametypes\_globallogic::removeArray( FlagRadiosTemp, radio_index );
				
				pode = 1;
				for ( index = 0; index < default_flags.size; index++ )
				{	
					flag = default_flags[index];
					if ( distance( radio, flag.origin ) < 500 || distance( radio, level.pos_01_final ) < 500 || distance( radio, level.attack_spawn ) < 1500 )
					{
						pode = 0;
					}								
				}
				
				// se passou por todas as flags sem problema, é este! senão vamos para prox HQ
				if ( pode == 1 )
				{
					level.pos_02_final = radio;
					return;
				}				
			}
		}
		
		// se sair do while diz q NENHUM hq é longe o suficiente
		logPrint("map is too small to this gametype" + "\n");
		maps\mp\_utility::error("Map errors. See above");
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}
	else
	{
		// apenas um SD foi escolhido, vamos tentar usar o prox, senão voltamos pro koth
		
		// acha qual é o q está sobrando
		if ( level.newFlags[level.NewSpot] == level.pos_01_final )
			Pos02 = level.newFlags[!level.NewSpot];
		else
			Pos02 = level.newFlags[level.NewSpot];

		// inicia dizendo q está ok
		pos_2 = 1;

		// testa Pos02
		for ( index = 0; index < default_flags.size; index++ )
		{	
			flag = default_flags[index];
			if ( distance( flag.origin, Pos02 ) < level.dist_inicial )
			{
				// diz que posição é inválida
				pos_2 = 0; 
			}
		}
		
		// se ok, é ela!
		if ( pos_2 == 1 )
		{
			level.pos_02_final = Pos02;
			return;
		}
		else if (getdvar("mapname") == "mp_pipeline")
		{
			level.pos_02_final = (-1129,-798,264);
			return;
		}
		else if ( level.tem_koth == true )
		{
			// pega lista de radios
			FlagRadiosTemp = level.FlagRadios;

			test = 0;
			while( test == 0 )
			{
				if ( FlagRadiosTemp.size == 0 )
				{
					test = 1;
				}
				else
				{		
					// seleciona um random
					radio_index = randomInt(FlagRadiosTemp.size);
					radio = FlagRadiosTemp[radio_index];
					
					// remove ele da lista pra não procurar novamente
					FlagRadiosTemp = maps\mp\gametypes\_globallogic::removeArray( FlagRadiosTemp, radio_index );
					
					pode = 1;
					for ( index = 0; index < default_flags.size; index++ )
					{	
						flag = default_flags[index];
						if ( distance( radio, flag.origin ) < 500 || distance( radio, level.pos_01_final ) < 500 || distance( radio, level.attack_spawn ) < 1500 )
						{
							pode = 0;
						}								
					}
					
					// se passou por todas as flags sem problema, é este! senão vamos para prox HQ
					if ( pode == 1 )
					{
						level.pos_02_final = radio;
						return;
					}				
				}
			}
			
			// se sair do while diz q NENHUM hq é longe o suficiente
			logPrint("map is too small to this gametype" + "\n");
			maps\mp\_utility::error("Map errors. See above");
			temp = strtok( level.BasicGametypes, " " );
			SetDvar( "fl", temp[RandomInt(temp.size)] );

			return;
		}
		else
		{
			// adiciona no spawn da defesa
			level.pos_02_final = level.defend_spawn;
			return;
		}
	}
}

Add_2_Flags( default_flags )
{
	Add_1_Flag( default_flags );
	if ( level.flagsErro == 1 )
		return;
	Add_Outra_Flag( default_flags );
}

getBombs()
{
	bombZones = getEntArray( "bombzone", "targetname" );
	level.newFlags = [];
	
	// sd bombs
	for ( index = 0; index < bombZones.size; index++ )
	{	
		level.newFlags[index] = bombZones[index].origin;
	}

	// sd bomb
	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	level.maleta = trigger.origin;
	////logPrint("level.maleta = " + level.maleta + "\n");

	allowed = [];
	allowed[0] = "dom";

	maps\mp\gametypes\_gameobjects::main(allowed);	
}

getRadios()
{
	maperrors = [];

	radios = getentarray( "hq_hardpoint", "targetname" );
	
	if ( radios.size < 2 )
	{
		maperrors[maperrors.size] = "There are not at least 2 entities with targetname \"radio\"";
	}
		
	////logPrint("radio size = " + radios.size + "\n");
	
	if (maperrors.size > 0)
	{
		printLn("^1------------ Map Errors ------------\n");
		for(i = 0; i < maperrors.size; i++)
			printLn(maperrors[i] + "\n");
		printLn("^1------------------------------------\n");
		
		level.tem_koth = false;
		
		maps\mp\_utility::error("Map errors. See above");
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		
		return;
	}
	level.radios = radios;

	SetaRadioFlag();
	
	return true;
}

SetaRadioFlag()
{
	// define qual é o mais Longe	
	level.FlagRadios = [];
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		level.FlagRadios[level.FlagRadios.size] = radio.origin + (0,0,-30);
	}
}


domFlags()
{
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
	
	primaryFlags = getEntArray( "flag_primary", "targetname" );
	secondaryFlags = getEntArray( "flag_secondary", "targetname" );
	
	if ( (primaryFlags.size + secondaryFlags.size) < 2 )
	{
		printLn( "^1Not enough domination flags found in level!" );
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}
	
	level.flags = [];
	for ( index = 0; index < primaryFlags.size; index++ )
		level.flags[level.flags.size] = primaryFlags[index];
	
	for ( index = 0; index < secondaryFlags.size; index++ )
		level.flags[level.flags.size] = secondaryFlags[index];
		
	if ( level.novos_objs )
		move_flag();		
	
	// acha flag do ataque
	flag_attack = undefined;
	for ( index = 0; index < level.flags.size; index++ )
	{	
		flag = level.flags[index];
		if ( index == 0 )
		{
			flag_attack = level.flags[index];
		}
		else
		{
			if ( distance( flag_attack.origin, level.attack_spawn ) > distance( flag.origin , level.attack_spawn ) )
			{
				flag_attack = level.flags[index];
			}
		}
	}
	
	level.domFlags = [];
	for ( index = 0; index < level.flags.size; index++ )
	{
			trigger = level.flags[index];
			if ( isDefined( trigger.target ) )
			{
				visuals[0] = getEnt( trigger.target, "targetname" );
			}
			else
			{
				visuals[0] = spawn( "script_model", trigger.origin );
				visuals[0].angles = trigger.angles;
			}

			visuals[0] setModel( game["flagmodels"]["neutral"] );
			
			if ( flag_attack == trigger )
			{
				domFlag = maps\mp\gametypes\_gameobjects::createUseObject( game["attackers"], trigger, visuals, (0,0,100) );
				domFlag maps\mp\gametypes\_gameobjects::setOwnerTeam( game["attackers"] );
				domFlag.visuals[0] setModel( game["flagmodels"][game["attackers"]] );
			}
			else
			{
				domFlag = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,100) );
				domFlag maps\mp\gametypes\_gameobjects::setOwnerTeam( game["defenders"] );
				domFlag.visuals[0] setModel( game["flagmodels"][game["defenders"]] );
			}
			
			domFlag maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			domFlag maps\mp\gametypes\_gameobjects::setUseTime( 10.0 );
			domFlag maps\mp\gametypes\_gameobjects::setUseText( &"MP_CAPTURING_FLAG" );
			label = domFlag maps\mp\gametypes\_gameobjects::getLabel();
			domFlag.label = label;
			domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
			domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
			domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" + label );
			domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + label );
			domFlag maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			domFlag.onUse = ::onUse;
			domFlag.onBeginUse = ::onBeginUse;
			domFlag.onUseUpdate = ::onUseUpdate;
			domFlag.onEndUse = ::onEndUse;
			
			
			traceStart = visuals[0].origin + (0,0,32);
			traceEnd = visuals[0].origin + (0,0,-32);
			trace = bulletTrace( traceStart, traceEnd, false, undefined );
		
			upangles = vectorToAngles( trace["normal"] );
			domFlag.baseeffectforward = anglesToForward( upangles );
			domFlag.baseeffectright = anglesToRight( upangles );
			
			domFlag.baseeffectpos = trace["position"];

			// legacy spawn code support
			level.flags[index].useObj = domFlag;
			level.flags[index].adjflags = [];
			level.flags[index].nearbyspawns = [];
			
			domFlag.levelFlag = level.flags[index];
			
			level.domFlags[level.domFlags.size] = domFlag;
	}
	
	// level.bestSpawnFlag is used as a last resort when the enemy holds all flags.
	level.bestSpawnFlag = [];
	level.bestSpawnFlag[ "allies" ] = getUnownedFlagNearestStart( "allies", undefined );
	level.bestSpawnFlag[ "axis" ] = getUnownedFlagNearestStart( "axis", level.bestSpawnFlag[ "allies" ] );
	
	flagSetup();
}

onBeginUse( player )
{
	while ( level.inPrematchPeriod )
		wait 1;

	ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel() + "_flash", 1 );	
	self.didStatusNotify = false;

	if ( ownerTeam == "neutral" )
	{
		if ( self.label != "_d" && self.label != "_e" )
		{
			statusDialog( "securing"+self.label, player.pers["team"] );
		}
		self.objPoints[player.pers["team"]] thread maps\mp\gametypes\_objpoints::startFlashing();
		return;
	}
		
	if ( ownerTeam == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";

	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::startFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::startFlashing();
}


onUseUpdate( team, progress, change )
{
	while ( level.inPrematchPeriod )
		wait 1;
		
	if ( progress > 0.05 && change && !self.didStatusNotify )
	{
		ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
		if ( ownerTeam == "neutral" )
		{
			if ( self.label != "_d" && self.label != "_e" )
				statusDialog( "securing"+self.label, team );
		}
		else
		{
			if ( self.label != "_d" && self.label != "_e" )
			{
				statusDialog( "losing"+self.label, ownerTeam );
				statusDialog( "securing"+self.label, team );
			}
			else
			{
				statusDialog( "ourflag", ownerTeam );
				statusDialog( "enemyflag", team );			
			}
			
		}

		self.didStatusNotify = true;
	}
}

onEndUse( team, player, success )
{
	while ( level.inPrematchPeriod )
		wait 1;
		
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel() + "_flash", 0 );

	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::stopFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::stopFlashing();
}

onUse( player )
{
	while ( level.inPrematchPeriod )
		wait 1;

	team = player.pers["team"];
	oldTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	label = self maps\mp\gametypes\_gameobjects::getLabel();
	
	player logString( "flag captured: " + self.label );
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" + label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + label );
	self.visuals[0] setModel( game["flagmodels"][team] );
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel(), team );	
	
	level.useStartSpawns = false;
	
	assert( team != "neutral" );
	
	if ( oldTeam == "neutral" )
	{
		otherTeam = getOtherTeam( team );
		thread printAndSoundOnEveryone( team, otherTeam, &"MP_NEUTRAL_FLAG_CAPTURED_BY", &"MP_NEUTRAL_FLAG_CAPTURED_BY", "mp_war_objective_taken", undefined, player );
		
		if ( self.label != "_d" && self.label != "_e" )
		{
			statusDialog( "secured"+self.label, team );
			statusDialog( "enemy_has"+self.label, otherTeam );
		}
	}
	else
	{
		thread printAndSoundOnEveryone( team, oldTeam, &"MP_ENEMY_FLAG_CAPTURED_BY", &"MP_FRIENDLY_FLAG_CAPTURED_BY", "mp_war_objective_taken", "mp_war_objective_lost", player );
		
		[[level._setTeamScore]]( team, [[level._getTeamScore]]( team ) + level.FlagsReinf );

		if ( getTeamFlagCount( team ) == level.flags.size )
		{
			statusDialog( "secure_all", team );
			statusDialog( "lost_all", oldTeam );
		}
		else
		{	
			if ( self.label != "_d" && self.label != "_e" )
			{
				statusDialog( "secured"+self.label, team );
				statusDialog( "lost"+self.label, oldTeam );
			}
			else
			{
				statusDialog( "enemyflag_capt", team );
				statusDialog( "ourflag_capt", oldTeam );			
			}
		}
		
		level.bestSpawnFlag[ oldTeam ] = self.levelFlag;
	}

	thread giveFlagCaptureXP( self.touchList[team] );
}

giveFlagCaptureXP( touchList )
{
	wait .05;
	maps\mp\gametypes\_globallogic::WaitTillSlowProcessAllowed();
	
	players = getArrayKeys( touchList );
	for ( index = 0; index < players.size; index++ )
	{
		touchList[players[index]].player thread [[level.onXPEvent]]( "capture" );
		maps\mp\gametypes\_globallogic::givePlayerScore( "capture", touchList[players[index]].player );
	}
}

flagSetup()
{
	maperrors = [];
	descriptorsByLinkname = [];

	// (find each flag_descriptor object)
	descriptors = getentarray("flag_descriptor", "targetname");
	
	flags = level.flags;
	
	for (i = 0; i < level.domFlags.size; i++)
	{
		closestdist = undefined;
		closestdesc = undefined;
			for (j = 0; j < descriptors.size; j++)
		{
			dist = distance(flags[i].origin, descriptors[j].origin);
			if (!isdefined(closestdist) || dist < closestdist) {
				closestdist = dist;
				closestdesc = descriptors[j];
			}
		}
		
		if (!isdefined(closestdesc)) {
			maperrors[maperrors.size] = "there is no flag_descriptor in the map! see explanation in dom.gsc";
			break;
		}
		if (isdefined(closestdesc.flag)) {
			maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + closestdesc.script_linkname + "\" is nearby more than one flag; is there a unique descriptor near each flag?";
			continue;
		}
		flags[i].descriptor = closestdesc;
		closestdesc.flag = flags[i];
		descriptorsByLinkname[closestdesc.script_linkname] = closestdesc;
	}
	
	if (maperrors.size == 0)
	{
		// find adjacent flags
		for (i = 0; i < flags.size; i++)
		{
			if (isdefined(flags[i].descriptor.script_linkto))
				adjdescs = strtok(flags[i].descriptor.script_linkto, " ");
			else
				adjdescs = [];
			for (j = 0; j < adjdescs.size; j++)
			{
				otherdesc = descriptorsByLinkname[adjdescs[j]];
				if (!isdefined(otherdesc) || otherdesc.targetname != "flag_descriptor") {
					maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + flags[i].descriptor.script_linkname + "\" linked to \"" + adjdescs[j] + "\" which does not exist as a script_linkname of any other entity with a targetname of flag_descriptor (or, if it does, that flag_descriptor has not been assigned to a flag)";
					continue;
				}
				adjflag = otherdesc.flag;
				if(getdvar("mapname") != "mp_convoy")
				{
					if (adjflag == flags[i]) {
						maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + flags[i].descriptor.script_linkname + "\" linked to itself";
						continue;
					}
				}
				flags[i].adjflags[flags[i].adjflags.size] = adjflag;
			}
		}
	}
	
	// assign each spawnpoint to nearest flag
	spawnpoints = getentarray("mp_dom_spawn", "classname");
	for (i = 0; i < spawnpoints.size; i++)
	{
		if (isdefined(spawnpoints[i].script_linkto)) {
			desc = descriptorsByLinkname[spawnpoints[i].script_linkto];
			if (!isdefined(desc) || desc.targetname != "flag_descriptor") {
				maperrors[maperrors.size] = "Spawnpoint at " + spawnpoints[i].origin + "\" linked to \"" + spawnpoints[i].script_linkto + "\" which does not exist as a script_linkname of any entity with a targetname of flag_descriptor (or, if it does, that flag_descriptor has not been assigned to a flag)";
				continue;
			}
			nearestflag = desc.flag;
		}
		else {
			nearestflag = undefined;
			nearestdist = undefined;
			for (j = 0; j < flags.size; j++)
			{
				dist = distancesquared(flags[j].origin, spawnpoints[i].origin);
				if (!isdefined(nearestflag) || dist < nearestdist)
				{
					nearestflag = flags[j];
					nearestdist = dist;
				}
			}
		}
		nearestflag.nearbyspawns[nearestflag.nearbyspawns.size] = spawnpoints[i];
	}
	
	if (maperrors.size > 0)
	{
		printLn("^1------------ Map Errors ------------\n");
		for(i = 0; i < maperrors.size; i++)
			printLn(maperrors[i]+"\n");
		printLn("^1------------------------------------\n");
		
		maps\mp\_utility::error("Map errors. See above");
		//SetDvar( "fl", "war" );
		
		//return;
	}
}

// ========================================================================
//		Novas Flags
// ========================================================================

// level.newFlags[0]
// level.newFlags[1]

StartNewFlags()
{
	if ( level.flags_size == 5 )
		return;

	thread update_linkName();
	
	level.labels = [];
	level.labels[0] = "a";
	level.labels[1] = "b";
	level.labels[2] = "c";
	level.labels[3] = "d";
	level.labels[4] = "e";
	
	label = level.labels;
	
	flags = getentarray( "flag_primary", "targetname" );
	flag_count = flags.size;
	descriptors = getentarray( "flag_descriptor", "targetname" );
		
	thread update_linkTo();
	
	if ( level.flags_size == 3 )
	{
		thread add_dom( 2 );
	}	
	else if ( level.flags_size == 4 )
	{
		thread add_dom( 1 );
	}
}

add_dom( num )
{
	label = [];
	if ( num  == 1 )
	{
		label[0] = "e";
	}
	else if ( num  == 2 )
	{
		label[0] = "d";
		label[1] = "e";
	}
	
//--------------------
	
	flags = getentarray( "flag_primary", "targetname" );
	
	for(i=0 ; i<label.size ; i++)
	{
			new_origin = level.newFlags[i];
			new_angles = (0,-90,0);
			
			flag = spawn( "trigger_radius", new_origin, 4, 160, 128 );
			flag.origin = new_origin;
			flag.angles = new_angles;
			flag.script_gameobjectname = "dom onslaught";
			flag.targetname = "flag_primary";
			
			new_label = label[i];
	
			flag.script_label = "_"+new_label;
			
			descriptor = spawn( "script_origin", new_origin, 4 );
			descriptor.origin = new_origin;
			descriptor.script_linkName = "flag"+(i+(flags.size+1));
			descriptor.script_linkTo = "flag"+((i+(flags.size+1))-1);
			descriptor.targetname = "flag_descriptor";
	}
}

update_linkName()
{
	label = level.labels;
	
	flags = getentarray( "flag_primary", "targetname" );
	descriptors = getentarray( "flag_descriptor", "targetname" );
	
	for(i=0 ; i<flags.size ; i++)
	{
		for(j=0 ; j<descriptors.size ; j++)
		{
			if( distance( flags[i].origin, descriptors[j].origin ) <= 200 )
			{
				descriptors[j].script_linkName = get_flag_number( flags[i].script_label );
				break;
			}
		}
	}
}

get_flag_number( label )
{
	switch( label )
	{
		case "_a" : num = "flag1"; break;
		case "_b" : num = "flag2"; break;
		case "_c" : num = "flag3"; break;
		case "_d" : num = "flag4"; break;
		case "_e" : num = "flag5"; break;
		default : num = "flag9";
	}
	
	return num;
}

update_linkTo()
{
	descriptors = getentarray( "flag_descriptor", "targetname" );
	dist = [];
	
	for(i=0 ; i<descriptors.size ; i++)
	{
		for(j=0 ; j<descriptors.size ; j++)
		{
			if( j != i )
				dist[i][j] = distance( descriptors[i].origin, descriptors[j].origin );
			else
				dist[i][j] = 100000;
		}
		
		nearest = undefined;
		
		for(j=0 ; j<dist[i].size ; j++)
		{
			if( isdefined( dist[i][j] ) )
			{
				if( !isdefined( nearest ) )
					nearest = (dist[i][j], 0, 100);
				
				if( dist[i][j] < nearest[0] )
					nearest = (dist[i][j], j, 100);		
			}
		}
		
		for(j=0 ; j<dist[i].size ; j++)
		{
			if( isdefined( dist[i][j] ) && j != nearest[1] )
			{
				if( dist[i][j] <= (110*nearest[0]/100) )
					nearest = (nearest[0], nearest[1], j);
			}
		}
		
		linkto = "";
		
		if( nearest[2] == 100 )
			linkto = descriptors[int(nearest[1])].script_linkName;
		
		else if( nearest[2] < 100 )
			linkto = descriptors[int(nearest[1])].script_linkName+" "+descriptors[int(nearest[2])].script_linkName;
			
		descriptors[i].script_linkTo = linkto;
	}
}

// ============ RANDOM =======================

novos_flag_init()
{
	level.novos_objs = true;

	temp = GetDvar ( "xflag_" + 0 );
	if ( temp == "" )
	{
		level.novos_objs = false;	
		return;
	}
	
	xflag(); // cria listas com pos
		
	StartNewFlagsX(); //	cria novas flags
	
	//logPrint("=-=-=-=-=-=-=level.xflag_selected[0] = " + level.xflag_selected[0] + "\n");
	//logPrint("=-=-=-=-=-=-=level.xflag_selected[1] = " + level.xflag_selected[1] + "\n");
	//logPrint("=-=-=-=-=-=-=level.xflag_selected[2] = " + level.xflag_selected[2] + "\n");
	//if ( level.NumFlagsOri > 3 )
		//logPrint("=-=-=-=-=-=-=level.xflag_selected[3] = " + level.xflag_selected[3] + "\n");
	//if ( level.NumFlagsOri > 4 )
		//logPrint("=-=-=-=-=-=-=level.xflag_selected[4] = " + level.xflag_selected[4] + "\n");
}

xflag()
{
	primaryFlags = getEntArray( "flag_primary", "targetname" );
	secondaryFlags = getEntArray( "flag_secondary", "targetname" );
	
	if ( (primaryFlags.size + secondaryFlags.size) < 2 )
	{
		printLn( "^1Not enough domination flags found in level!" );
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}
	
	level.flags = [];
	for ( index = 0; index < primaryFlags.size; index++ )
		level.flags[level.flags.size] = primaryFlags[index];
	
	for ( index = 0; index < secondaryFlags.size; index++ )
		level.flags[level.flags.size] = secondaryFlags[index];
		
	level.NumFlagsOri = level.flags.size;
		
	level.xflag_a = [];
	level.xflag_b = [];
	level.xflag_c = [];
	if ( level.NumFlagsOri > 3 )
		level.xflag_d = [];
	if ( level.NumFlagsOri > 4 )
		level.xflag_e = [];	
			
	level.xflag_selected = [];
	
	flag_a = level.flags[0];
	flag_b = level.flags[1];
	flag_c = level.flags[2];
	if ( level.NumFlagsOri > 3 )
		flag_d = level.flags[3];
	else
		flag_d = undefined;		
	if ( level.NumFlagsOri > 4 )	
		flag_e = level.flags[4];
	else
		flag_e = undefined;		
		
	
	level.xflag_a[0] = flag_a.origin + (0, 0, 60);
	level.xflag_b[0] = flag_b.origin + (0, 0, 60);
	level.xflag_c[0] = flag_c.origin + (0, 0, 60);
	if ( level.NumFlagsOri > 3 && isDefined(flag_d) )
		level.xflag_d[0] = flag_d.origin + (0, 0, 60);
	if ( level.NumFlagsOri > 4 && isDefined(flag_e) )
		level.xflag_e[0] = flag_e.origin + (0, 0, 60);

	level.flags = [];

	gerando = true;
	index = 0;
	
	// 3 flags
	if ( level.NumFlagsOri == 3 )	
	{
		while (gerando)
		{
			temp = GetDvar ( "xflag_" + index );
			if ( temp == "eof" )
				gerando = false;
			else
			{
				temp = strtok( temp, "," );
				pos = (int(temp[0]),int(temp[1]),int(temp[2]));
							
				if ( ( distance( pos, flag_a.origin) < distance( pos, flag_b.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_c.origin) )
				)
					level.xflag_a[level.xflag_a.size] = pos;
				else if ( ( distance( pos, flag_b.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_c.origin) )
						)
						level.xflag_b[level.xflag_b.size] = pos;
				else 
					level.xflag_c[level.xflag_c.size] = pos;
					
			}	
			index++;
		}
	}
	// 4 flags
	else if ( level.NumFlagsOri == 4 )	
	{
		while (gerando)
		{
			temp = GetDvar ( "xflag_" + index );
			if ( temp == "eof" )
				gerando = false;
			else
			{
				temp = strtok( temp, "," );
				pos = (int(temp[0]),int(temp[1]),int(temp[2]));
							
				if ( ( distance( pos, flag_a.origin) < distance( pos, flag_b.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_c.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_d.origin) )
				)
					level.xflag_a[level.xflag_a.size] = pos;
				else if ( ( distance( pos, flag_b.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_c.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_d.origin) )
						)
						level.xflag_b[level.xflag_b.size] = pos;
				else if ( ( distance( pos, flag_c.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_c.origin) < distance( pos, flag_b.origin) ) &&
			     		( distance( pos, flag_c.origin) < distance( pos, flag_d.origin) )
						)
						level.xflag_c[level.xflag_c.size] = pos;
				else 
					level.xflag_d[level.xflag_d.size] = pos;					
					
			}	
			index++;
		}
	}	
	// 5 flags
	else if ( level.NumFlagsOri == 5 )	
	{
		while (gerando)
		{
			temp = GetDvar ( "xflag_" + index );
			if ( temp == "eof" )
				gerando = false;
			else
			{
				temp = strtok( temp, "," );
				pos = (int(temp[0]),int(temp[1]),int(temp[2]));
							
				if ( ( distance( pos, flag_a.origin) < distance( pos, flag_b.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_c.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_d.origin) ) &&
					( distance( pos, flag_a.origin) < distance( pos, flag_e.origin) )
				)
					level.xflag_a[level.xflag_a.size] = pos;
				else if ( ( distance( pos, flag_b.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_c.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_d.origin) ) &&
			     		( distance( pos, flag_b.origin) < distance( pos, flag_e.origin) )
						)
						level.xflag_b[level.xflag_b.size] = pos;
				else if ( ( distance( pos, flag_c.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_c.origin) < distance( pos, flag_b.origin) ) &&
			     		( distance( pos, flag_c.origin) < distance( pos, flag_d.origin) ) &&
			     		( distance( pos, flag_c.origin) < distance( pos, flag_e.origin) )
						)
						level.xflag_c[level.xflag_c.size] = pos;
				else if ( ( distance( pos, flag_d.origin) < distance( pos, flag_a.origin) ) &&
			     		( distance( pos, flag_d.origin) < distance( pos, flag_b.origin) ) &&
			     		( distance( pos, flag_d.origin) < distance( pos, flag_c.origin) ) &&
			     		( distance( pos, flag_d.origin) < distance( pos, flag_e.origin) )
						)
						level.xflag_d[level.xflag_d.size] = pos;
				else 
					level.xflag_e[level.xflag_e.size] = pos;								
			}	
			index++;
		}
	}	
	
	//logPrint(  " = listas formadas = " + "\n");
	//logPrint(  "level.xflag_a = " + level.xflag_a.size + "\n");
	//logPrint(  "level.xflag_b = " + level.xflag_b.size + "\n");
	//logPrint(  "level.xflag_c = " + level.xflag_c.size + "\n");
	//if ( level.NumFlagsOri > 3 )
		//logPrint(  "level.xflag_d = " + level.xflag_d.size + "\n");
	//if ( level.NumFlagsOri > 4 )
		//logPrint(  "level.xflag_e = " + level.xflag_e.size + "\n");
	
	// escolhe flags ABC

	if ( getDvarInt("fl_bots") == 1 && getDvarInt("bot_ok") == true )
	{
		id_a = RandomInt(level.xflag_a.size);
		while ( ObjValido(level.xflag_a[id_a]) == false )
		{
			id_a = RandomInt(level.xflag_a.size);
			logprint( "======================== Não Válido A!!! " + "\n");
		}
		level.xflag_selected[0] = level.xflag_a[id_a];
		level.xflag_a = removeFlagArray(level.xflag_a, id_a);	
		
		id_b = RandomInt(level.xflag_b.size);
		while ( ObjValido(level.xflag_b[id_b]) == false )
		{
			id_b = RandomInt(level.xflag_b.size);
			logprint( "======================== Não Válido B!!! " + "\n");
		}
		level.xflag_selected[1] = level.xflag_b[id_b];
		level.xflag_b = removeFlagArray(level.xflag_b, id_b);	
		
		id_c = RandomInt(level.xflag_c.size);
		while ( ObjValido(level.xflag_c[id_c]) == false )
		{
			id_c = RandomInt(level.xflag_c.size);
			logprint( "======================== Não Válido C!!! " + "\n");
		}
		level.xflag_selected[2] = level.xflag_c[id_c];
		level.xflag_c = removeFlagArray(level.xflag_c, id_c);
		
		if ( level.NumFlagsOri > 3 )
		{
			id_d = RandomInt(level.xflag_d.size);
			while ( ObjValido(level.xflag_d[id_d]) == false )
			{
				id_d = RandomInt(level.xflag_d.size);
				logprint( "======================== Não Válido D!!! " + "\n");
			}			
			level.xflag_selected[3] = level.xflag_d[id_d];
			level.xflag_d = removeFlagArray(level.xflag_d, id_d);	
		}	
		if ( level.NumFlagsOri > 4 )
		{
			id_e = RandomInt(level.xflag_e.size);
			while ( ObjValido(level.xflag_e[id_e]) == false )
			{
				id_e = RandomInt(level.xflag_e.size);
				logprint( "======================== Não Válido E!!! " + "\n");
			}			
			level.xflag_selected[4] = level.xflag_e[id_e];
			level.xflag_e = removeFlagArray(level.xflag_e, id_e);	
		}							
		
	}		
	else
	{
		id_a = RandomInt(level.xflag_a.size);
		level.xflag_selected[0] = level.xflag_a[id_a];
		level.xflag_a = removeFlagArray(level.xflag_a, id_a);
		
		id_b = RandomInt(level.xflag_b.size);
		level.xflag_selected[1] = level.xflag_b[id_b];
		level.xflag_b = removeFlagArray(level.xflag_b, id_b);
		
		id_c = RandomInt(level.xflag_c.size);
		level.xflag_selected[2] = level.xflag_c[id_c];
		level.xflag_c = removeFlagArray(level.xflag_c, id_c);	
		
		if ( level.NumFlagsOri > 3 )
		{
			id_d = RandomInt(level.xflag_d.size);
			level.xflag_selected[3] = level.xflag_d[id_d];
			level.xflag_d = removeFlagArray(level.xflag_d, id_d);	
		}
		
		if ( level.NumFlagsOri > 4 )
		{
			id_e = RandomInt(level.xflag_e.size);
			level.xflag_selected[4] = level.xflag_e[id_e];
			level.xflag_e = removeFlagArray(level.xflag_e, id_e);	
		}
	}
	
	//logPrint(  " = listas -ABC - 1 de cada lista + lista selecionada que tem q ser 3 = " + "\n");
	//logPrint(  "level.xflag_a = " + level.xflag_a.size + "\n");
	//logPrint(  "level.xflag_b = " + level.xflag_b.size + "\n");
	//logPrint(  "level.xflag_c = " + level.xflag_c.size + "\n");
	//if ( level.NumFlagsOri > 3 )	
		//logPrint(  "level.xflag_d = " + level.xflag_d.size + "\n");
	//if ( level.NumFlagsOri > 4 )	
		//logPrint(  "level.xflag_e = " + level.xflag_e.size + "\n");
	//logPrint(  "level.xflag_selected = " + level.xflag_selected.size + "\n");	
}

StartNewFlagsX()
{
	thread update_linkName();	
	
	level.labels = [];
	level.labels[0] = "a";
	level.labels[1] = "b";
	level.labels[2] = "c";
	level.labels[3] = "d";
	level.labels[4] = "e";
		
	thread update_linkTo();

	NewFlags = 2; // sempre 5 flags!
	
	if ( level.NumFlagsOri == 4 )
		NewFlags = 1;  // 5 sempre!
	else if ( level.NumFlagsOri == 5 )
		NewFlags = 0; // 5 sempre!
	
	if ( NewFlags > 0 )
	{
		level.newFlags = [];
		DecideFlagsEF(NewFlags);
	
		exec_add( NewFlags );
	}
}

DecideFlagsEF(num)
{
	while ( num > 0 )
	{
		level.newFlags[level.newFlags.size] = CalculaDist();	
		num--;
	}
	
	//logPrint(  " = level.newFlags montada com 2 pos = " + "\n");
	//logPrint(  "level.newFlags = " + level.newFlags.size + "\n");	
	//logPrint(  " = level.xflags tem -2 pos removidas que foram para level.newFlags= " + "\n");
	//logPrint(  "level.xflag_a = " + level.xflag_a.size + "\n");
	//logPrint(  "level.xflag_b = " + level.xflag_b.size + "\n");
	//logPrint(  "level.xflag_c = " + level.xflag_c.size + "\n");
	//if ( level.NumFlagsOri > 3 )
		//logPrint(  "level.xflag_d = " + level.xflag_d.size + "\n");
	//if ( level.NumFlagsOri > 4 )
		//logPrint(  "level.xflag_e = " + level.xflag_e.size + "\n");
}

CalculaDist()
{
	while(1)
	{
		Lista = randomInt(3);
		
		pode = true;

		if ( Lista == 0 ) // A
		{
			id_a = RandomInt(level.xflag_a.size);

			nova =  level.xflag_a[id_a];		
			//nova = (int(nova[0]),int(nova[1]),int(nova[2]));		
			
			for ( i = 0; i < level.xflag_selected.size; i++ )
			{			
				velha = level.xflag_selected[i];
				//velha = (int(velha[0]),int(velha[1]),int(velha[2]));	
					
				if ( distance( nova, velha ) < level.dist_inicial )
					pode = false;
				if ( isDefined(level.newFlags[0]) )
				{
					flag_E = level.newFlags[0];
					if ( distance( nova, flag_E ) < level.dist_inicial )
						pode = false;
				}
			}
			
			if ( pode == true )
			{
				level.xflag_a = removeFlagArray(level.xflag_a, id_a);
				return nova;
			}
		}
		else if ( Lista == 1 ) // B
		{
			id_b = RandomInt(level.xflag_b.size);

			nova =  level.xflag_b[id_b];		
			//nova = (int(nova[0]),int(nova[1]),int(nova[2]));		

			for ( i = 0; i < level.xflag_selected.size; i++ )
			{			
				velha = level.xflag_selected[i];
				//velha = (int(velha[0]),int(velha[1]),int(velha[2]));
						
				if ( distance( nova, velha ) < level.dist_inicial )
					pode = false;
				if ( isDefined(level.newFlags[0]) )
				{
					flag_E = level.newFlags[0];
					if ( distance( nova, flag_E ) < level.dist_inicial )
						pode = false;
				}					
			}
			if ( pode == true )
			{
				level.xflag_b = removeFlagArray(level.xflag_b, id_b);
				return nova;
			}					
		}
		else if ( Lista == 2 ) // C
		{
			id_c = RandomInt(level.xflag_c.size);
			
			nova =  level.xflag_c[id_c];		
			//nova = (int(nova[0]),int(nova[1]),int(nova[2]));		
			
			for ( i = 0; i < level.xflag_selected.size; i++ )
			{			
				velha = level.xflag_selected[i];
				//velha = (int(velha[0]),int(velha[1]),int(velha[2]));			

				if ( distance( nova, velha ) < level.dist_inicial )
					pode = false;
				if ( isDefined(level.newFlags[0]) )
				{
					flag_E = level.newFlags[0];
					if ( distance( nova, flag_E ) < level.dist_inicial )
						pode = false;
				}					
			}				
			if ( pode == true )
			{
				level.xflag_c = removeFlagArray(level.xflag_c, id_c);
				return nova;
			}			
		}
	}
}

exec_add( num )
{
	label = [];
	if ( num  == 1 )
	{
		label[0] = "d";
	}
	else if ( num  == 2 )
	{
		label[0] = "d";
		label[1] = "e";
	}
	
	flags = getentarray( "flag_primary", "targetname" );
	
	count = 4;
	for(i=0 ; i<label.size ; i++)
	{
			if ( !isDefined(level.newFlags[i]) )
				continue;

			pos = level.newFlags[i];
			pos = (int(pos[0]),int(pos[1]),int(pos[2]));				
	
			new_origin = pos + (0, 0, -60);
			//logPrint("=-=-=-=-=-=-=new_origin = " + new_origin + "\n");
			new_angles = (0,-90,0);
			
			flag = spawn( "trigger_radius", new_origin, count, 160, 128 );
			flag.origin = new_origin;
			flag.angles = new_angles;
			flag.script_gameobjectname = "dom onslaught";
			flag.targetname = "flag_primary";
			
			new_label = label[i];
	
			flag.script_label = "_"+new_label;
			
			descriptor = spawn( "script_origin", new_origin, count );
			descriptor.origin = new_origin;
			descriptor.script_linkName = "flag"+(i+(flags.size+1));
			descriptor.script_linkTo = "flag"+((i+(flags.size+1))-1);
			descriptor.targetname = "flag_descriptor";
			count++;
	}
}

move_flag()
{
	exeflag( level.xflag_selected[0], 0 );
	exeflag( level.xflag_selected[1], 1 );
	exeflag( level.xflag_selected[2], 2 );
	if ( level.NumFlagsOri > 3 )
		exeflag( level.xflag_selected[3], 3 );
	if ( level.NumFlagsOri > 4 )
		exeflag( level.xflag_selected[4], 4 );
	
	/*
	if ( NewFlags == 0 ) // não tem +3, mapas com +3 tem q ser removidas!
	{
		if ( level.flags.size == 5 )
			level.flags = removeFlagArray(level.flags, 4);
		if ( level.flags.size == 4 )
			level.flags = removeFlagArray(level.flags, 3);
	}
	*/
}

exeflag( pos, flag )
{
	trig_a = undefined;
	trig_b = undefined;
	trig_c = undefined;
	trig_d = undefined;
	trig_e = undefined;
	
	////logPrint("=-=-=-=-=-=-= pos = " + pos + " | flag = " + flag + "\n");
	
	pos = (int(pos[0]),int(pos[1]),int(pos[2]));
	
	for(i=0 ; i<level.flags.size ; i++)
	{
		if ( i == 0 )
			trig_a = level.flags[i];
		else if ( i == 1 ) 
			trig_b = level.flags[i];
		else if ( i == 2 ) 
			trig_c = level.flags[i];
		else if ( i == 3 ) 
			trig_d = level.flags[i];
		else if ( i == 4 ) 
			trig_e = level.flags[i];		
		
		/*
		if( level.flags[i].script_label == "_a" )
			trig_a = level.flags[i];
		else if( level.flags[i].script_label == "_b" )
			trig_b = level.flags[i];
		else if( level.flags[i].script_label == "_c" )
			trig_c = level.flags[i];
		else if( level.flags[i].script_label == "_d" )
			trig_d = level.flags[i];
		else if( level.flags[i].script_label == "_e" )
			trig_e = level.flags[i];			
		*/
	}
	
	if ( flag == 0 ) // a
	{
		obj_a_origin = pos + (0, 0, -60);
	
		trig_a.origin = obj_a_origin;
		
		if ( isDefined( trig_a.target ) )
		{
			a_obj_entire = getent( trig_a.target, "targetname" );
			a_obj_entire.origin = obj_a_origin;
		}
	}
	else if ( flag == 1 ) // b
	{
		obj_b_origin = pos + (0, 0, -60);
	
		trig_b.origin = obj_b_origin;
		
		if ( isDefined( trig_b.target ) )
		{
			b_obj_entire = getent( trig_b.target, "targetname" );
			b_obj_entire.origin = obj_b_origin;		
		}
	}
	else if ( flag == 2 ) // c
	{
		obj_c_origin = pos + (0, 0, -60);
	
		trig_c.origin = obj_c_origin;
		
		if ( isDefined( trig_c.target ) )
		{
			c_obj_entire = getent( trig_c.target, "targetname" );
			c_obj_entire.origin = obj_c_origin;		
		}
	}	
	else if ( flag == 3 ) // d
	{
		obj_d_origin = pos + (0, 0, -60);
	
		trig_d.origin = obj_d_origin;
		
		if ( isDefined( trig_d.target ) )
		{
			d_obj_entire = getent( trig_d.target, "targetname" );
			d_obj_entire.origin = obj_d_origin;		
		}
	}		
	else if ( flag == 4 ) // e
	{
		obj_e_origin = pos + (0, 0, -60);
	
		trig_e.origin = obj_e_origin;
		
		if ( isDefined( trig_e.target ) )
		{
			e_obj_entire = getent( trig_e.target, "targetname" );
			e_obj_entire.origin = obj_e_origin;		
		}
	}		
}

removeFlagArray( array, index )
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
