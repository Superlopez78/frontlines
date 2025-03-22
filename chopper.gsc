#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "chopper", 3, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "chopper", 3, 3, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "chopper", 6, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "chopper", 0, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "chopper", 1, 1, 50 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchSpawnDvar( "chopper", 2, 0, 9 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "chopper", 1, 0, 1 );
	
	level.teamBased = true;
	level.overrideTeamScore = true;
	
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit; 
	level.onRoundSwitch = ::onRoundSwitch;
	level.onRoundSwitchSpawn = ::onRoundSwitchSpawn;
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["offense_obj"] = "obj_destroy";
	game["dialog"]["defense_obj"] = "obj_defend";	
	
	game["ChopperDown"] = false;
}

onStartGameType()
{
	// se não tem chopper no mapa, retorna como TDM
	if ( !isDefined( level.heli_paths ) || !level.heli_paths.size )
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );
		return;
	}

	//garante que sempre tera todas as armas
	level.HajasWeap = 0;
	
	level.defesa_morta = false;	

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

	setClientNameMode("manual_change");

	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_CHOPPER_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_CHOPPER_DEFENDER" );
	
	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_CHOPPER_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_CHOPPER_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_CHOPPER_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_CHOPPER_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_CHOPPER_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_CHOPPER_DEFENDER_HINT" );
			
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	
	//level.EhSD = isDefined( getEnt( "mp_sd_spawn_attacker", "targetname" ) );
	
	level.EhSD = true;
	level.spawn_all = getentarray( "mp_sd_spawn_attacker", "classname" );
	if ( !level.spawn_all.size )
	{
		level.EhSD = false;
	}
	
	if ( level.EhSD == true )
	{
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	}
	else
	{
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
	}
	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "chopper";
	
	if ( getDvarInt( "scr_oldHardpoints" ) > 0 )
		allowed[1] = "hardpoint";
	
	level.displayRoundEndText = false;
	maps\mp\gametypes\_gameobjects::main(allowed);

	SetaMensagens();
		
	// chama heli
	thread maps\mp\gametypes\_hardpoints::chopper( game["defenders"] );
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );		
}

onSpawnPlayer()
{
	self.usingObj = undefined;

	if ( level.EhSD == true )
	{
		if(self.pers["team"] == game["attackers"])
			spawnPointName = "mp_sd_spawn_attacker";
		else
			spawnPointName = "mp_sd_spawn_defender";
		
		if ( !isDefined( game["switchedspawnsides"] ) )
			game["switchedspawnsides"] = false;
		
		if ( game["switchedspawnsides"] )
		{
			if ( spawnPointName == "mp_sd_spawn_defender")
			{
				spawnPointName = "mp_sd_spawn_attacker";
			}
			else
			{
				spawnPointName = "mp_sd_spawn_defender";
			}
		}		
	}
	else
	{
		if(self.pers["team"] == game["attackers"])
			spawnPointName = "mp_tdm_spawn_allies_start";
		else
			spawnPointName = "mp_tdm_spawn_axis_start";
		
		if ( !isDefined( game["switchedspawnsides"] ) )
			game["switchedspawnsides"] = false;
		
		if ( game["switchedspawnsides"] )
		{
			if ( spawnPointName == "mp_tdm_spawn_axis_start")
			{
				spawnPointName = "mp_tdm_spawn_allies_start";
			}
			else
			{
				spawnPointName = "mp_tdm_spawn_axis_start";
			}
		}			
	}

	spawnPoints = getEntArray( spawnPointName, "classname" );
	assert( spawnPoints.size );
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	
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

	if ( level.SidesMSG == 1 )
	{	
		if ( self.pers["team"] != game["defenders"] )
			self iPrintLnbold( level.attack_msg );
		else
			self iPrintLnbold( level.defend_msg );
	}	
}

onOneLeftEvent( team )
{
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


onTimeLimit()
{
	// da vitoria aos defenders em caso de empate
	winner = undefined;

	if ( game["defenders"] == "allies" )
		winner = "allies";
	else
		winner = "axis";

	logString( "time limit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );

	// i think these two lines are obsolete
	makeDvarServerInfo( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	setDvar( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	
	thread maps\mp\gametypes\_globallogic::endGame( winner, game["strings"]["time_limit_reached"] );
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

onDeadEvent( team )
{
	if ( game["ChopperDown"] )
		return;

	if ( team == "all" )
	{
		Chopper_EndGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["attackers"] )
	{
		Chopper_EndGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		// se a defesa for eliminada, ataque tenta a sorte contra heli sozinhos
		// libera todos para spec
		thread free_spec();
		return;
	}
}

free_spec()
{
	level.defesa_morta = true;

	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		player allowSpectateTeam( "allies", true );
		player allowSpectateTeam( "axis", true );
		player allowSpectateTeam( "freelook", true );
		player allowSpectateTeam( "none", true );
	}
}

Chopper_EndGame( winningTeam, endReasonText )
{
	setGameEndTime( 0 );
		
	// termina o round
	level.overrideTeamScore = true;
	level.displayRoundEndText = true;
	
	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );	
}

heliDead( chopper_down )
{
	level.endtext = "";
	
	level notify("chopper_end");
	setGameEndTime( 0 );
		
	// termina o round
	level.overrideTeamScore = true;
	level.displayRoundEndText = true;
	
	if ( chopper_down == true )
	{
		level.endtext = level.chopper_shot;
		Chopper_EndGame( game["attackers"], level.endtext );
	}
	else
	{
		level.endtext = level.chopper_safe;
		Chopper_EndGame( game["defenders"], level.endtext );
	}	

	makeDvarServerInfo( "ui_text_endreason", level.endtext );
	setDvar( "ui_text_endreason", level.endtext );
}

SetaMensagens()
{
	if ( getDvar( "scr_chopper_attack" ) == "" )
	{
		level.attack_msg =  "^7Shoot down the ^9Chopper^7!";
	}
	else
	{
		level.attack_msg = getDvar( "scr_chopper_attack" );
	}
	
	if ( getDvar( "scr_chopper_defend" ) == "" )
	{
		level.defend_msg =  "^7Protect the ^9Chopper^7!";
	}
	else
	{
		level.defend_msg = getDvar( "scr_chopper_defend" );
	}
	
	if ( getDvar( "scr_chopper_safe" ) == "" )
	{
		level.chopper_safe =  "^7The ^3Chopper ^7is safe!";
	}
	else
	{
		level.chopper_safe = getDvar( "scr_chopper_safe" );
	}	
	
	if ( getDvar( "scr_chopper_destroyed" ) == "" )
	{
		level.chopper_shot =  "^7The ^3Chopper ^7was shot down!";
	}
	else
	{
		level.chopper_shot = getDvar( "scr_chopper_destroyed" );
	}	
}