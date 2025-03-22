#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "exterminate", 10, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "exterminate", 500, 0, 5000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "exterminate", 1, 0, 10 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "exterminate", 1, 1, 10 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "exterminate", 2, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTypeDvar( "exterminate", 1, 0, 3 );

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onOneLeftEvent = ::onOneLeftEvent;

	level.onRoundSwitch = ::onRoundSwitch;
	level.onTimeLimit = ::onTimeLimit; 
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "hardcore_tm_death";
}

onStartGameType()
{
	setClientNameMode("auto_change");
	
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

	maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"HAJAS_EXT_MENU" );
	maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"HAJAS_EXT_MENU" );
	
	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_EXT_MENU" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_EXT_MENU" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_EXT_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_EXT_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"HAJAS_EXT_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"HAJAS_EXT_HINT" );
			
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "exterminate";
	
	if ( getDvarInt( "scr_oldHardpoints" ) > 0 )
		allowed[1] = "hardpoint";
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	// elimination style
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		level.onEndGame = ::onEndGame;
		
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "tdm" );
}

onSpawnPlayer()
{
	self.usingObj = undefined;

	if ( level.inGracePeriod )
	{
		if ( game["switchedsides"] )
		{
			spawnPoints = getentarray("mp_tdm_spawn_" + getOtherTeam( self.pers["team"] ) + "_start", "classname");
			
			if ( !spawnPoints.size )
				spawnPoints = getentarray("mp_sab_spawn_" + getOtherTeam( self.pers["team"] ) + "_start", "classname");
				
			if ( !spawnPoints.size )
			{
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( getOtherTeam( self.pers["team"] ) );
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
			}
			else
			{
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			}		
		}
		else
		{
			spawnPoints = getentarray("mp_tdm_spawn_" + self.pers["team"] + "_start", "classname");
			
			if ( !spawnPoints.size )
				spawnPoints = getentarray("mp_sab_spawn_" + self.pers["team"] + "_start", "classname");
				
			if ( !spawnPoints.size )
			{
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
			}
			else
			{
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			}		
		}
	}
	else
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
	}
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if ( game["switchedsides"] )
		{
			if ( self.pers["team"] == "allies" )
			{
				maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
				self spawn( spawnPoint.origin, spawnPoint.angles );
			}
			else
			{
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );			
				maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
			}
		}
		else
		{
			if ( self.pers["team"] == "axis" )
			{
				maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
				self spawn( spawnPoint.origin, spawnPoint.angles );
			}
			else
			{
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );			
				maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
			}			
		}
	}
	else
		self spawn( spawnPoint.origin, spawnPoint.angles );
}


onEndGame( winningTeam )
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	

	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
		
}

onTimeLimit()
{
	if ( level.inOvertime )
		return;

	thread onOvertime();
}

onOvertime()
{
	level endon ( "game_ended" );

	if( level.Type > 0 && level.HajasWeap != 12 && level.HajasWeap != 13 )
	{
		level.timeLimitOverride = true;
		level.inOvertime = true;
	
		for ( index = 0; index < level.players.size; index++ )
		{
			level.players[index] notify("force_spawn");
			if( getDvarInt( "scr_exterminate_numlives" ) > 1 )
			{
				level.players[index] thread maps\mp\gametypes\_hud_message::oldNotifyMessage( &"MP_SUDDEN_DEATH", &"MP_NO_RESPAWN", undefined, (1, 0, 0), "mp_last_stand" );
			}
			else
			{
				level.players[index] thread maps\mp\gametypes\_hud_message::oldNotifyMessage( &"MP_SUDDEN_DEATH", &"MP_TIE_BREAKER", undefined, (1, 0, 0), "mp_last_stand" );
			}

			level.players[index] setClientDvars("cg_deadChatWithDead", 1,
								"cg_deadChatWithTeam", 0,
								"cg_deadHearTeamLiving", 0,
								"cg_deadHearAllLiving", 0,
								"cg_everyoneHearsEveryone", 0,
								"g_compassShowEnemies", 1 );
			
			if( level.Type == 2 )
			{
				game["hajas_duel_exec"] = 1;
				NaFacaExec( level.players[index] );
			}
		}
		
		if( level.Type == 2 )
		{
			thread maps\mp\gametypes\_globallogic::HajasRemoveClaysC4();
			thread maps\mp\gametypes\_globallogic::removeMGs();
		}
		
	    maps\mp\gametypes\_globallogic::leaderDialogBothTeams( "overtime", "allies", "overtime", "axis");		
	
		waitTime = 0;
		while ( waitTime < 60 )
		{
			waitTime += 1;
			setGameEndTime( getTime() + ((60-waitTime)*1000) );
			wait ( 1.0 );
		}	
		
		// se 3, tem 2 sudden deaths, sendo a segunda só com facas!
		if( level.Type == 3 )
		{
			for ( index = 0; index < level.players.size; index++ )
			{
				level.players[index] notify("force_spawn");
				level.players[index] thread maps\mp\gametypes\_hud_message::oldNotifyMessage( &"MP_SUDDEN_DEATH", getDvar( "scr_exterminate_msg" ), undefined, (1, 0, 0), "mp_last_stand" );

				level.players[index] setClientDvars("cg_deadChatWithDead", 1,
									"cg_deadChatWithTeam", 0,
									"cg_deadHearTeamLiving", 0,
									"cg_deadHearAllLiving", 0,
									"cg_everyoneHearsEveryone", 0,
									"g_compassShowEnemies", 1 );
				
				game["hajas_duel_exec"] = 1;
				NaFacaExec( level.players[index] );
			}
			
			thread maps\mp\gametypes\_globallogic::HajasRemoveClaysC4();
			thread maps\mp\gametypes\_globallogic::removeMGs();
			
			maps\mp\gametypes\_globallogic::leaderDialogBothTeams( "losing", "allies", "losing", "axis");					
		
			waitTime = 0;
			while ( waitTime < 60 )
			{
				waitTime += 1;
				setGameEndTime( getTime() + ((60-waitTime)*1000) );
				wait ( 1.0 );
			}	
		}
	}
	
	//============= EMPATE =================

	// caso acabe o tempo (nenhum time ser eliminado) dá EMPATE
	winner = "tie";

	logString( "time limit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );

	// i think these two lines are obsolete
	makeDvarServerInfo( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	setDvar( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	
	thread maps\mp\gametypes\_globallogic::endGame( winner, game["strings"]["time_limit_reached"] );
}

NaFacaExec( player )
{
	player endon ("disconnect");
	player endon ("death");
	player endon ( "game_ended" );
	
	if ( isAlive( player ) )
	{
		player.pers["primary"] = 0;
		player.pers["weapon"] = undefined;
		player maps\mp\gametypes\_class::setClass( player.pers["class"] );
		player.tag_stowed_back = undefined;
		player.tag_stowed_hip = undefined;
		player maps\mp\gametypes\_class::giveLoadout( player.pers["team"], player.pers["class"] );
	}
}

onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	if ( game["teamScores"]["allies"] == level.scorelimit - 1 && game["teamScores"]["axis"] == level.scorelimit - 1 )
	{
		level.halftimeType = "overtime";
	}
	else
	{
		level.halftimeType = "halftime";
		game["switchedsides"] = !game["switchedsides"];
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
