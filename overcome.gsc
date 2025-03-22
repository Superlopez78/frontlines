#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "overcome", 5, 0, 1440 ); 
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "overcome", 0, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "overcome", 8, 0, 10 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "overcome", 0, 0, 10000 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "overcome", 1, 0, 1 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "overcome", 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchSpawnDvar( "overcome", 2, 0, 9 );	
	
	// tem q setar fixo pro Resist
	SetDvar( "scr_overcome_playerrespawndelay", -1 );
	SetDvar( "scr_overcome_waverespawndelay", -1 );		
	
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPrecacheGameType = ::onPrecacheGameType;
	
	level.onTimeLimit = ::onTimeLimit;
	level.onRespawnDelay = ::getRespawnDelay;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onRoundSwitch = ::onRoundSwitch;	
	level.onRoundSwitchSpawn = ::onRoundSwitchSpawn;	

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
		SetDvar( "overcome_allies_score", 0 );
		SetDvar( "overcome_axis_score", 0 );
	}	
	
	level.ControlaRespawn = false;
	level.ControlaDominion = false;		
}

onTimeLimit()
{
	numFlags = getTeamFlagCount( game["attackers"] );
	ExtraPts = numFlags * 50;
	[[level._setTeamScore]]( game["attackers"], [[level._getTeamScore]]( game["attackers"] ) + ExtraPts );

	if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
		winner = "tie";
	else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
		winner = "axis";
	else
		winner = "allies";

	makeDvarServerInfo( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	setDvar( "ui_text_endreason", game["strings"]["time_limit_reached"] );

	sd_endGame( winner, game["strings"]["time_limit_reached"] );
}

sd_endGame( winningTeam, endReasonText )
{
	SetDvar( "overcome_allies_score",  getDvarInt("overcome_allies_score") + [[level._getTeamScore]]( "allies" ) );
	SetDvar( "overcome_axis_score", getDvarInt("overcome_axis_score") + [[level._getTeamScore]]( "axis" ) );	
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

getRespawnDelay()
{
	flagsOwned = 0;
	myTeam = self.pers["team"];
	
	if ( myTeam != game["defenders"] ) // se for ataque não tem isso!
		return;
		
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
	else if ( flagsOwned == 1 )
	{
		timeRemaining = 15;
		return (int(timeRemaining));	
	}
	else if ( flagsOwned == 2 )
	{
		timeRemaining = 10;
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
				[[level._setTeamScore]]( game["attackers"], [[level._getTeamScore]]( game["attackers"] ) + 200 );
				
				sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
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

onDeadEvent( team )
{
	if ( team == game["defenders"] )
	{
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
}

onOneLeftEvent( team )
{
	if ( team == game["defenders"] )
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

onRoundSwitchSpawn()
{
	// switch spawn sides
	
	if ( !isdefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;
	
	if ( game["teamScores"]["allies"] == level.scorelimit - 1 && game["teamScores"]["axis"] == level.scorelimit - 1 )
	{
		// overtime! team that's ahead in kills gets to defend.
		aheadTeam = getBetterTeam();
		if ( aheadTeam != game["defenders"] )
		{
			game["switchedspawnsides"] = !game["switchedspawnsides"];
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
		game["switchedspawnsides"] = !game["switchedspawnsides"];
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


onPrecacheGameType()
{
	precacheShader( "compass_waypoint_captureneutral" );
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );
	precacheShader( "compass_waypoint_captureneutral_a" );
	precacheShader( "compass_waypoint_capture_a" );
	precacheShader( "compass_waypoint_defend_a" );
	precacheShader( "compass_waypoint_captureneutral_b" );
	precacheShader( "compass_waypoint_capture_b" );
	precacheShader( "compass_waypoint_defend_b" );
	precacheShader( "compass_waypoint_captureneutral_c" );
	precacheShader( "compass_waypoint_capture_c" );
	precacheShader( "compass_waypoint_defend_c" );
	precacheShader( "compass_waypoint_captureneutral_d" );
	precacheShader( "compass_waypoint_capture_d" );
	precacheShader( "compass_waypoint_defend_d" );
	precacheShader( "compass_waypoint_captureneutral_e" );
	precacheShader( "compass_waypoint_capture_e" );
	precacheShader( "compass_waypoint_defend_e" );

	precacheShader( "waypoint_captureneutral" );
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
	precacheShader( "waypoint_captureneutral_a" );
	precacheShader( "waypoint_capture_a" );
	precacheShader( "waypoint_defend_a" );
	precacheShader( "waypoint_captureneutral_b" );
	precacheShader( "waypoint_capture_b" );
	precacheShader( "waypoint_defend_b" );
	precacheShader( "waypoint_captureneutral_c" );
	precacheShader( "waypoint_capture_c" );
	precacheShader( "waypoint_defend_c" );
	precacheShader( "waypoint_captureneutral_d" );
	precacheShader( "waypoint_capture_d" );
	precacheShader( "waypoint_defend_d" );
	precacheShader( "waypoint_captureneutral_e" );
	precacheShader( "waypoint_capture_e" );
	precacheShader( "waypoint_defend_e" );

	flagBaseFX = [];
	flagBaseFX["marines"] = "misc/ui_flagbase_silver";
	flagBaseFX["sas"    ] = "misc/ui_flagbase_black";
	flagBaseFX["russian"] = "misc/ui_flagbase_red";
	flagBaseFX["opfor"  ] = "misc/ui_flagbase_gold";
	
	if ( !isDefined(flagBaseFX[ game[ "allies" ] ]) )
		return;	
	
	//level.flagBaseFXid[ "allies" ] = loadfx( flagBaseFX[ game[ "allies" ] ] );
	//level.flagBaseFXid[ "axis"   ] = loadfx( flagBaseFX[ game[ "axis"   ] ] );
}


onStartGameType()
{	
	if ( !isDefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
		
	if ( !isDefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;			
	
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
		
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_OVERCOME_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_OVERCOME_DEFENDER" );

	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_OVERCOME_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_OVERCOME_DEFENDER" );

	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_OVERCOME_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_OVERCOME_DEFENDER" );

	setClientNameMode("auto_change");

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dom_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_dom_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dom_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_dom_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	level.spawn_all = getentarray( "mp_dom_spawn", "classname" );

	if ( game["switchedspawnsides"] )
	{
		level.spawn_ataque_start = getentarray("mp_dom_spawn_allies_start", "classname" );
		level.spawn_defesa_start = getentarray("mp_dom_spawn_axis_start", "classname" );
	}		
	else
	{
		level.spawn_ataque_start = getentarray("mp_dom_spawn_axis_start", "classname" );
		level.spawn_defesa_start = getentarray("mp_dom_spawn_allies_start", "classname" );
	}

	level.startPos["ataque"] = level.spawn_ataque_start[0].origin;
	level.startPos["defesa"] = level.spawn_defesa_start[0].origin;
	
	dist_spawns = distance( level.startPos["ataque"] , level.startPos["defesa"] );
	//logPrint(  "dist_spawns = " + dist_spawns + "\n");	
	level.dist_inicial = dist_spawns / 5;
	if ( level.script == "mp_cdi_mision_bunker" )
		level.dist_inicial = dist_spawns / 8;
		
	// seta mensagens
	SetaMensagens();		
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();
	
	allowed[0] = "dom";
//	allowed[1] = "hardpoint";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	novos_flag_init();
	
	thread domFlags();
	thread updateDomScores();

	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "dom,tdm" );	
}

CalculaSpawnsDefesa(spawnPointName)
{
	// inicia spaws da defesa
	level.DefesaSpawns = [];

	// distancia maxima para spawn ser válido!
	dist_max = distance(level.startPos["ataque"], level.startPos["defesa"])/3;
	
	assert( spawnPointName.size );
		
	level.DefesaSpawns[level.DefesaSpawns.size] = spawnPointName[0];
	level.DefesaSpawns[level.DefesaSpawns.size] = spawnPointName[1];
	level.DefesaSpawns[level.DefesaSpawns.size] = spawnPointName[2];
	
	//logPrint("level.DefesaSpawns.size ANTES = " + level.DefesaSpawns.size + "\n");

	// pega spawns dom
	assert( level.spawn_all.size );	
	
	// loop control
	tudo_ok = false;	
	
	// spawn_count
	spawn_count = 0;	
	
	if ( level.script == "mp_beltot_2" )
	{
		return;			
	}	
	
	//logPrint("dist_max = " + dist_max + "\n");
	// calcula distancia ideal pra cada mapa
	while( tudo_ok == false )
	{
		if ( level.spawn_all.size < 3 )
		{
			logPrint( "Warning! spawnPoints Extras with low Size = " + level.spawn_all.size + "\n");
			tudo_ok = true;
		}	
		
		for (i = 0; i < level.spawn_all.size; i++)
		{
			dist = distance(level.startPos["defesa"], level.spawn_all[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist < dist_max)
				spawn_count++;
		}
		if ( spawn_count < 3 )
		{
			dist_max = dist_max + 500;
			//logPrint("dist_max = " + dist_max + "\n");
			spawn_count = 0;
		}
		else
			tudo_ok = true;
	}
	
	// cria lista de spawns
	for (i = 0; i < level.spawn_all.size; i++)
	{
		dist = distance(level.startPos["defesa"], level.spawn_all[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist < dist_max)
			level.DefesaSpawns[level.DefesaSpawns.size] = level.spawn_all[i];
	}	
	
	//logPrint("level.DefesaSpawns.size DEPOIS = " + level.DefesaSpawns.size + "\n");
}


onSpawnPlayer()
{
	spawnpoint = undefined;
	
	if(self.pers["team"] == game["attackers"])
		spawnPointName = level.spawn_ataque_start;
	else
		spawnPointName = level.spawn_defesa_start;
		
	if ( !isDefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;
		
	CalculaSpawnsDefesa(spawnPointName);			
	
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
	
	if ( level.SidesMSG == 1 )
	{
		if(self.pers["team"] == game["attackers"])
		{
			if ( flagsOwned == 2 )
				self iPrintLnbold( level.kill_msg );
		}
		else
		{
			if ( flagsOwned != 2 )
				self iPrintLnbold( level.recover_msg );
		}
	}	
	

	if(self.pers["team"] == game["attackers"])
	{
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnPointName);
	}
	else
	{
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.DefesaSpawns );
	}
	
	if ( !isdefined( spawnpoint ) )
	{
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnPointName);
	}
	
	assert( isDefined(spawnpoint) );
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if(self.pers["team"] == game["attackers"])
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


domFlags()
{
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
	
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
	//precacheString( &"MP_LOSING_LAST_FLAG" );
	precacheString( &"MP_DOM_YOUR_FLAG_WAS_CAPTURED" );
	precacheString( &"MP_DOM_ENEMY_FLAG_CAPTURED" );
	precacheString( &"MP_DOM_NEUTRAL_FLAG_CAPTURED" );

	precacheString( &"MP_ENEMY_FLAG_CAPTURED_BY" );
	precacheString( &"MP_NEUTRAL_FLAG_CAPTURED_BY" );
	precacheString( &"MP_FRIENDLY_FLAG_CAPTURED_BY" );
	
	primaryFlags = getEntArray( "flag_primary", "targetname" );
	secondaryFlags = getEntArray( "flag_secondary", "targetname" );
	
	if ( (primaryFlags.size + secondaryFlags.size) < 2 )
	{
		printLn( "^1Not enough domination flags found in level!" );
		//logPrint( "Not enough domination flags found in level!\n" );
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

	// deleta todas as flags mais perto do ataque até sobrarem 2!
	while ( level.flags.size != 2 )
		RetornaFlagAtaqueParaDELETAR();
	
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
		
		label = "_a";
		if ( index == 1 )
			label = "_b";

		domFlag = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,100) );
		domFlag maps\mp\gametypes\_gameobjects::setOwnerTeam( game["defenders"] );
		domFlag.visuals[0] setModel( game["flagmodels"][game["defenders"]] );		
		domFlag maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		domFlag maps\mp\gametypes\_gameobjects::setUseTime( 10.0 );
		domFlag maps\mp\gametypes\_gameobjects::setUseText( &"MP_CAPTURING_FLAG" );
		//label = domFlag maps\mp\gametypes\_gameobjects::getLabel();
		domFlag.label = label;
		domFlag.script_label = label;
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
	level.bestSpawnFlag[ game["defenders"] ] = getUnownedFlagNearestStart( game["defenders"], undefined );
	
	flagSetup();
}

RetornaFlagAtaqueParaDELETAR()
{
	if ( level.novos_objs )
	{
		// deletar SEMPRE a última pois AB serao movidas corretamente e se tiver mais deletara até ficar só 2
		level.flags = removeFlagArray( level.flags, level.flags.size-1 );
		return;
	}

	flag_attack = 0;
	for ( index = 0; index < level.flags.size; index++ )
	{	
		flag = level.flags[index];
		if ( index == 0 )
			flag_attack = index;
		else
		{
			if ( distance( level.flags[flag_attack].origin , level.startPos["ataque"] ) > distance( flag.origin , level.startPos["ataque"] ) )
			{
				flag_attack = index;
			}
		}
	}
	
	level.flags = removeFlagArray( level.flags, flag_attack );
}

getUnownedFlagNearestStart( team, excludeFlag )
{
	best = undefined;
	bestdistsq = undefined;
	for ( i = 0; i < level.flags.size; i++ )
	{
		flag = level.flags[i];
		
		if ( flag getFlagTeam() != "neutral" )
			continue;
		
		if ( game["attackers"] == "axis" )
		{
			if ( team == "axis" )
				distsq = distanceSquared( flag.origin, level.startPos["ataque"] );
			else
				distsq = distanceSquared( flag.origin, level.startPos["defesa"] );
		}
		else
		{
			if ( team == "allies" )
				distsq = distanceSquared( flag.origin, level.startPos["ataque"] );
			else
				distsq = distanceSquared( flag.origin, level.startPos["defesa"] );		
		}
		
		if ( (!isDefined( excludeFlag ) || flag != excludeFlag) && (!isdefined( best ) || distsq < bestdistsq) )
		{
			bestdistsq = distsq;
			best = flag;
		}
	}
	return best;
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
			else
				statusDialog( "enemyflag", team );			
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
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" + self.label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + self.label );
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
		else
		{
			statusDialog( "enemyflag_capt", team );
			statusDialog( "ourflag_capt", otherTeam );			
		}
	}
	else
	{
		thread printAndSoundOnEveryone( team, oldTeam, &"MP_ENEMY_FLAG_CAPTURED_BY", &"MP_FRIENDLY_FLAG_CAPTURED_BY", "mp_war_objective_taken", "mp_war_objective_lost", player );
		
//		thread delayedLeaderDialogBothTeams( "obj_lost", oldTeam, "obj_taken", team );

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

updateDomScores()
{
	// disable score limit check to allow both axis and allies score to be processed
	level.endGameOnScoreLimit = false;

	while ( !level.gameEnded )
	{

		numFlags = getTeamFlagCount( "allies" );
		if ( numFlags )
			[[level._setTeamScore]]( "allies", [[level._getTeamScore]]( "allies" ) + numFlags );

		numFlags = getTeamFlagCount( "axis" );
		if ( numFlags )
			[[level._setTeamScore]]( "axis", [[level._getTeamScore]]( "axis" ) + numFlags );

		level.endGameOnScoreLimit = true;
		maps\mp\gametypes\_globallogic::checkScoreLimit();
		level.endGameOnScoreLimit = false;
		wait ( 5.0 );
	}
}


onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if ( self.touchTriggers.size && isPlayer( attacker ) && attacker.pers["team"] != self.pers["team"] )
	{
		triggerIds = getArrayKeys( self.touchTriggers );
		ownerTeam = self.touchTriggers[triggerIds[0]].useObj.ownerTeam;
		team = self.pers["team"];
		
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

flagSetup()
{
	maperrors = [];
	descriptorsByLinkname = [];

	// (find each flag_descriptor object)
	descriptors = getentarray("flag_descriptor", "targetname");
	
	//logPrint("=-=-=-=-=-=-=flagSetup - descriptors.size = " + descriptors.size + "\n");
	
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
		if (isdefined(closestdesc.flag)) 
		//	//logPrint("------------ !!! DARIA MERDA !!! ------------\n");
		{
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
				if (adjflag == flags[i]) {
					maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + flags[i].descriptor.script_linkname + "\" linked to itself";
					continue;
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
			printLn(maperrors[i] + "\n");
		printLn("^1------------------------------------\n");
		
		maps\mp\_utility::error("Map errors. See above");
		//SetDvar( "fl", "war" );
		
		//return;
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
	{
		if ( ( distance( primaryFlags[index].origin , level.startPos["ataque"] ) > distance( primaryFlags[index].origin , level.startPos["defesa"] ) ) 
			&& ( distance( primaryFlags[index].origin , level.startPos["defesa"] ) > 1000 ) )
		{
			level.flags[level.flags.size] = primaryFlags[index].origin + (0, 0, 60);
		}
	}
	
	for ( index = 0; index < secondaryFlags.size; index++ )
	{
		if ( ( distance( secondaryFlags[index].origin , level.startPos["ataque"] ) > distance( secondaryFlags[index].origin , level.startPos["defesa"] ) ) 
			&& ( distance( secondaryFlags[index].origin , level.startPos["defesa"] ) > 1000 ) )
		{	
			level.flags[level.flags.size] = secondaryFlags[index].origin + (0, 0, 60);
		}
	}		
		
	gerando = true;
	index = 0;

	// gera array apenas com flags válidas!	
	while (gerando)
	{
		temp = GetDvar ( "xflag_" + index );
		if ( temp == "eof" )
			gerando = false;
		else
		{
			temp = strtok( temp, "," );
			pos = (int(temp[0]),int(temp[1]),int(temp[2]));
						
			if ( ( distance( pos, level.startPos["ataque"] ) > distance( pos , level.startPos["defesa"] ) ) 
				&& ( distance( pos, level.startPos["defesa"] ) > 1000 ) )
			{
				level.flags[level.flags.size] = pos;
			}				
		}	
		index++;
	}
	
	// escolhe flags AB
	
	
	if ( getDvarInt("fl_bots") == 1 && getDvarInt("bot_ok") == true )
	{
		id_a = RandomInt(level.flags.size);
		while ( ObjValido(level.flags[id_a]) == false )
		{
			id_a = RandomInt(level.flags.size);
			logprint( "======================== Não Válido A!!! " + "\n");
		}
		level.xflag_selected[0] = level.flags[id_a];
		level.flags = removeFlagArray(level.flags, id_a);	
		
		segunda = true;
		while(segunda)
		{
			id_b = RandomInt(level.flags.size);
			while ( ObjValido(level.flags[id_b]) == false )
			{
				level.flags = removeFlagArray(level.flags, id_b);
				id_b = RandomInt(level.flags.size);
				logprint( "======================== Não Válido B!!! " + "\n");
			}		
			if ( distance( level.xflag_selected[0], level.flags[id_b] ) > level.dist_inicial )
			{
				level.xflag_selected[1] = level.flags[id_b];
				segunda = false;
			}
			level.flags = removeFlagArray(level.flags, id_b);
		}			
	}
	else
	{
		id_a = RandomInt(level.flags.size);
		level.xflag_selected[0] = level.flags[id_a];
		level.flags = removeFlagArray(level.flags, id_a);
		
		segunda = true;
		while(segunda)
		{
			id_b = RandomInt(level.flags.size);
			if ( distance( level.xflag_selected[0], level.flags[id_b] ) > level.dist_inicial )
			{
				level.xflag_selected[1] = level.flags[id_b];
				segunda = false;
			}
			level.flags = removeFlagArray(level.flags, id_b);
		}
	}
	
	/*
	level.flags = [];
	level.flags[level.flags.size] = level.xflag_selected[0];
	level.flags[level.flags.size] = level.xflag_selected[1];
	*/
	
	StartNewFlags(); //	cria novas flags
}

StartNewFlags()
{
	thread update_linkName();	
	
	level.labels = [];
	level.labels[0] = "a";
	level.labels[1] = "b";
		
	thread update_linkTo();
}

move_flag()
{
	exeflag( level.xflag_selected[0], 0 );
	exeflag( level.xflag_selected[1], 1 );
	//exeflag( level.xflag_selected[2], 2 );
}

exeflag( pos, flag )
{
	trig_a = undefined;
	trig_b = undefined;
	
	//logPrint("=-=-=-=-=-=-= pos = " + pos + " | flag = " + flag + "\n");
	
	pos = (int(pos[0]),int(pos[1]),int(pos[2]));
	
	for(i=0 ; i<level.flags.size ; i++)
	{
		//logPrint("=-=-=-=-=-=-= level.flags[i].script_label = " + level.flags[i].script_label + "\n");
		
		if ( i == 0 )
			trig_a = level.flags[i];
		else if ( i == 1 ) 
			trig_b = level.flags[i];
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
}

update_linkName()
{
	label = level.labels;
	
	flags = getentarray( "flag_primary", "targetname" );
	descriptors = getentarray( "flag_descriptor", "targetname" );
	
	//logPrint("=-=-=-=-=-=-=update_linkName - descriptors.size = " + descriptors.size + "\n");
	
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
		default : num = "flag9";
	}
	
	return num;
}

update_linkTo()
{
	descriptors = getentarray( "flag_descriptor", "targetname" );
	dist = [];
	
	//logPrint("=-=-=-=-=-=-=update_linkTo - descriptors.size = " + descriptors.size + "\n");
	
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

SetaMensagens()
{
	if ( getDvar( "scr_overcome_recover" ) == "" )
		level.recover_msg = "^7Recover our ^9Territory^7!";
	else
		level.recover_msg = getDvar( "scr_overcome_recover" );
	
	if ( getDvar( "scr_overcome_kill" ) == "" )
		level.kill_msg = "^7Eliminate Any ^9Resistance^7!";
	else
		level.kill_msg = getDvar( "scr_overcome_kill" );
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