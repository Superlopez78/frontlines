#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar 
registerWrathSavageDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.WrathSavageDvar = dvarString;
	level.WrathSavageMin = minValue;
	level.WrathSavageMax = maxValue;
	level.WrathSavage = getDvarInt( level.WrathSavageDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
		
	//garante que sempre tera todas as armas
	level.HajasWeap = 0;		
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
		
	registerWrathSavageDvar( "scr_wrath_savage", 0, 0, 1 );

	if ( level.WrathSavage == 0 )
		init();
	else if ( level.WrathSavage == 1 )
	{
		maps\mp\gametypes\savage::init();
		return;
	}
}

init()
{
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 10, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 500, 0, 5000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 1, 0, 10 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 10, 10, 100 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 2, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTypeDvar( level.gameType, 1, 0, 1 );

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onOneLeftEvent = ::onOneLeftEvent;

	level.onRoundSwitch = ::onRoundSwitch;
	level.onTimeLimit = ::onTimeLimit; 
	level.endGameOnScoreLimit = false;
	
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPrecacheGameType = ::onPrecacheGameType;	
	
	game["dialog"]["gametype"] = "hardcore_tm_death";
	
	// se não definido controle, cria como false
	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;
	
	if( game["roundsplayed"] == 0 )
	{
		SetDvar( "wrath_allies_score", 0 );
		SetDvar( "wrath_axis_score", 0 );
	}	
}

onPrecacheGameType()
{
	precacheStatusIcon( "killiconmelee" );
	game["wrath_sound"] = "playground_memory";
}

onStartGameType()
{
	// zera placar por round
	[[level._setTeamScore]]( "axis", 0 );
	[[level._setTeamScore]]( "allies", 0 );

	setClientNameMode("auto_change");
	
	level.eliminados = true;
	
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

	maps\mp\gametypes\_globallogic::setObjectiveText( "allies", &"HAJAS_WRATH_OBJ" );
	maps\mp\gametypes\_globallogic::setObjectiveText( "axis", &"HAJAS_WRATH_OBJ" );
	
	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_WRATH_OBJ" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_WRATH_OBJ" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "allies", &"HAJAS_WRATH_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( "axis", &"HAJAS_WRATH_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "allies", &"HAJAS_WRATH_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( "axis", &"HAJAS_WRATH_HINT" );
			
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
		//level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		level.onEndGame = ::onEndGame;
		
	// seta mensagens
	SetaMensagens();		
		
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "tdm" );
}

onSpawnPlayer()
{
	self.usingObj = undefined;
	
	self.wrath = false;

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
	
	if ( level.eliminados == true )
	{
		Seguranca = [[level._getTeamScore]]( "allies" ) + [[level._getTeamScore]]( "axis" );
		
		if ( Seguranca < 1 )
			Seguranca = 1;
			
		if ( level.HelpMode == 0 )
		{
			if ( winningTeam == "allies" )
			{
				SetDvar( "wrath_allies_score",  getDvarInt("wrath_allies_score") + Seguranca );
				[[level._setTeamScore]]( "allies", Seguranca );			
				[[level._setTeamScore]]( "axis", 0 );
			}
			else if ( winningTeam == "axis" )
			{
				SetDvar( "wrath_axis_score", getDvarInt("wrath_axis_score") + Seguranca );	
				[[level._setTeamScore]]( "axis", Seguranca );
				[[level._setTeamScore]]( "allies", 0 );
			}
		}
		else
		{
			if ( winningTeam == "axis" )
				SetDvar( "HM_Axis", getDvarInt("HM_Axis") + 1 );
			else if ( winningTeam == "allies" )
				SetDvar( "HM_Allies", getDvarInt("HM_Allies") + 1 );
		
			[[level._setTeamScore]]( "axis", getDvarInt("HM_Axis") );
			[[level._setTeamScore]]( "allies", getDvarInt("HM_Allies") );		
		}
	}
	else
	{
		// ninguém foi eliminado!
		SetDvar( "wrath_allies_score",  getDvarInt("wrath_allies_score") + [[level._getTeamScore]]( "allies" ) );
		SetDvar( "wrath_axis_score", getDvarInt("wrath_axis_score") + [[level._getTeamScore]]( "axis" ) );	
	}
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

	level.timeLimitOverride = true;
	level.inOvertime = true;
	
	thread maps\mp\gametypes\_globallogic::HajasRemoveClaysC4();
	thread maps\mp\gametypes\_globallogic::removeMGs();

	for ( index = 0; index < level.players.size; index++ )
	{
		level.players[index] notify("force_spawn");
		level.players[index] thread maps\mp\gametypes\_hud_message::oldNotifyMessage( &"MP_SUDDEN_DEATH", &"MP_NO_RESPAWN", undefined, (1, 0, 0), "mp_last_stand" );

		level.players[index] setClientDvars("cg_deadChatWithDead", 1,
							"cg_deadChatWithTeam", 0,
							"cg_deadHearTeamLiving", 0,
							"cg_deadHearAllLiving", 0,
							"cg_everyoneHearsEveryone", 0,
							"g_compassShowEnemies", 1 );
		
		game["hajas_duel_exec"] = 1;
		NaFacaExec( level.players[index] );
	}		

    maps\mp\gametypes\_globallogic::leaderDialogBothTeams( "overtime", "allies", "overtime", "axis");		
	
	waitTime = 0;
	while ( waitTime < 60 )
	{
		waitTime += 1;
		setGameEndTime( getTime() + ((60-waitTime)*1000) );
		wait ( 1.0 );
	}	
	
	// acha vencedor
	if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
		winner = "tie";
	else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
		winner = "axis";
	else
		winner = "allies";

	logString( "time limit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );

	// i think these two lines are obsolete
	makeDvarServerInfo( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	setDvar( "ui_text_endreason", game["strings"]["time_limit_reached"] );
	
	level.eliminados = false;
	
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
		
		if (isDefined(player.bIsBot) && player.bIsBot)
		{
			player takeAllWeapons();
			player.weaponPrefix = "deserteagle_mp";
		}
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

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if ( sMeansOfDeath == "MOD_MELEE" || sMeansOfDeath == "MOD_SUICIDE" || ( ( isDefined( self.lastStand ) && self.lastStand == true ) && attacker == self  ) )
	{
		self.pers["lives"] = 0;
		self.statusicon = "killiconmelee";
	}
		
	self StopLocalSound( game["wrath_sound"] );		
}

getRespawnDelay()
{
	if ( self.pers["team"] == game["defenders"] )
	{
		if ( level.reinf == false )
		{
			self.lowerMessageOverride = undefined;
			self.lowerMessageOverride = &"HAJAS_WAVES_WAITING";
			
			timeRemaining = 1000;
			
			return (int(timeRemaining));
		}
	}
}

// -------------------- WRATH --------------------

Wrath()
{
	self endon("death");
	self endon("disconnect");
	
	self thread maps\mp\gametypes\_hud_message::oldNotifyMessage( level.wrath_tittle, level.wrath_msg, undefined, (1, 0, 0), "mp_last_stand" );
	
	self thread WrathControl();
	
	self playLocalSound( game["wrath_sound"] );

	while ( self.wrath == true )
	{
		self.health = 2;
		earthquake( 0.1, 0.5, self.origin, 800 );
		wait .05;
		earthquake( 0.1, 0.5, self.origin, 800 );
		wait .05;
		earthquake( 0.1, 0.5, self.origin, 800 );
		earthquake( 0.1, 0.5, self.origin, 800 );
		self.health = 1;
		earthquake( 0.1, 0.5, self.origin, 800 );
		wait .05;
		earthquake( 0.1, 0.5, self.origin, 800 );
		earthquake( 0.1, 0.5, self.origin, 800 );
		wait .05;
		earthquake( 0.1, 0.5, self.origin, 800 );
	}
	
	self.health = self.maxhealth;
	
	self StopLocalSound( game["wrath_sound"] );
}

WrathControl()
{
	self endon("death");
	self endon("disconnect");
	
	espera = randomIntRange(35,45);
	//iprintlnbold("espera = " + espera);
	
	wait espera;
	
	self.wrath = false;
	
	//iprintlnbold("acabou wrath!");
}

SetaMensagens()
{
	if ( getDvar( "scr_wrath_tittle" ) == "" )
	{
		level.wrath_tittle =  "Wrath";
	}
	else
	{
		level.wrath_tittle = getDvar( "scr_wrath_tittle" );
	}	

	if ( getDvar( "scr_wrath_msg" ) == "" )
	{
		level.wrath_msg =  "Put some Blood in your Blade";
	}
	else
	{
		level.wrath_msg = getDvar( "scr_wrath_msg" );
	}	
}