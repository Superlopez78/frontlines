#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar 
registerSurvivorsGTDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.SurvivorsgtDvar = dvarString;
	level.SurvivorsgtMin = minValue;
	level.SurvivorsgtMax = maxValue;
	level.Survivorsgt = getDvarInt( level.SurvivorsgtDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	registerSurvivorsGTDvar( "scr_survivors_gt", 0, 0, 1 );
	
	if ( level.Survivorsgt == 0 )
		init();
	else if ( level.Survivorsgt == 1 )
	{
		maps\mp\gametypes\officers::init();
		return;
	}
}

init()
{
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "survivors", 3, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "survivors", 8, 4, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "survivors", 6, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "survivors", 10, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "survivors", 1, 1, 50 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchSpawnDvar( "survivors", 2, 0, 9 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "survivors", 1, 0, 1 );
	
	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onRoundSwitch = ::onRoundSwitch;
	level.onRoundSwitchSpawn = ::onRoundSwitchSpawn;
	level.onTimeLimit = ::onTimeLimit;
	level.onDeadEvent = ::onDeadEvent; 
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["defense_obj"] = "defense";
}

onPrecacheGameType()
{
}

onStartGameType()
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	
	
	level.hunt_liberado = false;
	level.SurProtected = false;

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

	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_SURVIVORS_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_SURVIVORS_DEFENDER" );
	
	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_SURVIVORS_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_SURVIVORS_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_SURVIVORS_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_SURVIVORS_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_SURVIVORS_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_SURVIVORS_DEFENDER_HINT" );
			
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
		
		// posição spawns para marcar spawns da defesa/ataque!
		level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
		level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );		
	}
	else
	{
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );

		// posição spawns para marcar spawns da defesa/ataque!
		if ( game["attackers"] == "allies" )
		{
			level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_tdm_spawn_allies_start" );
			level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_tdm_spawn_axis_start" );		
		}
		else if ( game["attackers"] == "axis" )
		{
			level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_tdm_spawn_axis_start" );
			level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_tdm_spawn_allies_start" );		
		}
	}
	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
		
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "war";
	
	if ( getDvarInt( "scr_oldHardpoints" ) > 0 )
		allowed[1] = "hardpoint";
	
	level.displayRoundEndText = false;
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	// calcula tempo pra reinforcements
	tempo_max = getDvarInt( level.timeLimitDvar );
	level.tempo_bombing = (tempo_max - 3);
	
	//elimination style
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		level.onEndGame = ::onEndGame;

	// self.pers["team"] = allied / axis
	// game["allies"], game["axis"] = marines, opfor...
	//  game["attackers"] = saber quem tá atacando

	SetaMensagens();
	
	if ( level.EhSD == true )
	{
		maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );	}
	else
	{
		maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "tdm" );
	}	
	
	thread SurvivorsLiberaAtaque();
	
	thread SafeHousesBots();
}

SafeHousesBots()
{
	if ( getDvarInt("fl_bots") != 1 )
		return;
		
	level.safehouses = [];
	
	while(!isdefined(level.waypoints) )
		wait 1;
	
	while(level.waypoints.size <= 1 )
		wait 1;				
		
	ataque_ini = level.attack_spawn;
	if ( isDefined( game["switchedspawnsides"] ) && game["switchedspawnsides"] )
		ataque_ini = level.defend_spawn;		
	
	for(i = 0; i < level.waypoints.size; i++)
	{
		ceu = level.waypoints[i].origin + ( 0, 0, 600 );
		teto = PhysicsTrace( level.waypoints[i].origin + ( 0, 0, 50), ceu );
		
		if ( int(ceu[2]) > int(teto[2]) && ( distance(ataque_ini, level.waypoints[i].origin) > 1500 ))
		{
			level.safehouses[level.safehouses.size] = level.waypoints[i];
		}		
	}
	
	if ( level.safehouses.size <= 1 )
	{
		for(i = 0; i < level.waypoints.size; i++)
		{
			if ( distance(ataque_ini, level.waypoints[i].origin) > 6000 )
			{
				level.safehouses[level.safehouses.size] = level.waypoints[i];
			}
		}		
	}	
	
	if ( level.safehouses.size <= 1 )
	{
		for(i = 0; i < level.waypoints.size; i++)
		{
			if ( distance(ataque_ini, level.waypoints[i].origin) > 4000 )
			{
				level.safehouses[level.safehouses.size] = level.waypoints[i];
			}
		}		
	}
	
	if ( level.safehouses.size <= 1 )
	{
		for(i = 0; i < level.waypoints.size; i++)
		{
			if ( distance(ataque_ini, level.waypoints[i].origin) > 2000 )
			{
				level.safehouses[level.safehouses.size] = level.waypoints[i];
			}
		}		
	}

	if ( level.safehouses.size <= 1 )
	{
		for(i = 0; i < level.waypoints.size; i++)
		{
			if ( distance(ataque_ini, level.waypoints[i].origin) > 1000 )
			{
				level.safehouses[level.safehouses.size] = level.waypoints[i];
			}
		}		
	}		
}

// ========================================================================
//		Players
// ========================================================================

onSpawnPlayer()
{
	self.SeuSpawn = undefined;

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
		maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
	
	self spawn( spawnpoint.origin, spawnpoint.angles );

	level notify ( "spawned_player" );
	
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints_player( self );

	// msg
	if ( level.SidesMSG == 1 )
	{	
		if ( self.pers["team"] == game["defenders"] )
			self iPrintLnbold( level.defend_msg );
	}	
	
	// controla ataque
	if ( self.pers["team"] == game["attackers"] )
	{
		self.SeuSpawn = spawnpoint.origin;
		self thread SurSeguraAtaque();
		self thread SurDaHPs();
	}
	else
		self thread MovePorra();
}

SurvivorsLiberaAtaque()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	maps\mp\gametypes\_globallogic::leaderDialog( "goodtogo", game["attackers"] );

	strike_wait = level.tempo_bombing * 60;
	dura_timer = int(( strike_wait - 5 )*1000);
	
	if ( dura_timer > 180000 )
		dura_timer = 180000;	
	
	//iprintln ("duration = " + dura_timer );
		
	// texto "Waiting for the Strike orders!"
	waves_strike = createServerFontString(  "objective", 2, game["attackers"] );
	waves_strike setPoint( "TOP", "TOP", 0, 120 );
	waves_strike.glowColor = (0.52,0.28,0.28);
	waves_strike.glowAlpha = 1;
	waves_strike setText( level.waiting_msg );
	waves_strike.hideWhenInMenu = true;
	waves_strike.archived = false;
	waves_strike setPulseFX( 100, dura_timer, 1000 );	
	
	// deleta quando termina o jogo
	thread SurRemoveTexto(waves_strike);
	
	// timer
	timerDisplay = [];
	timerDisplay[game["attackers"]] = createServerTimer( "objective", 4, game["attackers"] );
	timerDisplay[game["attackers"]] setPoint( "TOP", "TOP", 0, 150 );
	timerDisplay[game["attackers"]].glowColor = (0.52,0.28,0.28);
	timerDisplay[game["attackers"]].glowAlpha = 1;
	timerDisplay[game["attackers"]].alpha = 1;
	timerDisplay[game["attackers"]].archived = false;
	timerDisplay[game["attackers"]].hideWhenInMenu = true;
	timerDisplay[game["attackers"]] setTimer( strike_wait );
	
	// deleta quando termina o jogo
	thread SurRemoveClock( timerDisplay[game["attackers"]] );

	wait strike_wait;
	
	// deleta timer
	if ( isDefined( waves_strike ) )
		waves_strike destroyElem();		
	timerDisplay[game["attackers"]].alpha = 0;		

	level.hunt_liberado = true;
	thread SurProtection();

	for ( index = 0; index < level.players.size; index++ )
	{
		if ( level.players[index].team == game["attackers"] )
		{
			if ( level.SidesMSG == 1 )
				level.players[index] iPrintLnbold( level.attack_msg );
			level.players[index] maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "attack" );
		}
	}
	maps\mp\gametypes\_globallogic::leaderDialog( "offense_obj", game["attackers"], "introboost" );
	maps\mp\gametypes\_globallogic::leaderDialog( "secure_all", game["defenders"], "secure_all" );
}

SurProtection()
{
	level.SurProtected = true;
	wait 5;
	level.SurProtected = false;
}

SurRemoveTexto( sur_texto )
{
	level waittill("game_ended");
	if ( isDefined( sur_texto ) )
		sur_texto destroyElem();	
}

SurSeguraAtaque()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );	
		
	while ( level.hunt_liberado == false )
	{
		if ( distance(self.origin,self.SeuSpawn) > 50 )
		{
			self setorigin(self.SeuSpawn);
		}
		wait ( 0.05 );
	}
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
		maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, true );
		level.SurProtected = false;			
	}		
}

SurDaHPs()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );	
		
	wait randomint(10,15);
		
	while ( level.hunt_liberado == false )
	{
		tipo = randomInt(10);
		
		if ( tipo <= 2 )
		{
			self iprintln("^1UAV ^7Stand by");
			self maps\mp\gametypes\_hardpoints::giveHardpointItem( "radar_mp" );
		}
		else if ( tipo == 3 )
		{
			self iprintln("^1Strike Support ^7Stand by");
			self maps\mp\gametypes\_hardpoints::giveHardpointItem( "airstrike_mp" );
		}
		else if ( tipo == 4 )
		{
			self iprintln("^1Helicopter Support ^7Stand by");
			self maps\mp\gametypes\_hardpoints::giveHardpointItem( "helicopter_mp" );
		}
		else
		{
			self iprintln("^1Strike Support ^7Stand by");
			self maps\mp\gametypes\_hardpoints::giveHardpointItem( "airstrike_mp" );
		}
		
		self playLocalSound("mp_suitcase_pickup");
		
		espera = randomIntRange(35,60);
		wait espera;
	}		
}


SurRemoveClock( timerDisplay )
{
	level waittill("game_ended");
	timerDisplay.alpha = 0;
}

MovePorra()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );	

	wait 5;
	self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "move_to_new" );
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

	// hajas duel
	if ( level.HajasDuel > 0 )
		maps\mp\gametypes\_globallogic::HajasDuel();
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
	
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();
	
	thread maps\mp\gametypes\_globallogic::endGame( winner, game["strings"]["time_limit_reached"] );
}

onDeadEvent( team )
{
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();
	
	if ( team == "all" )
		thread maps\mp\gametypes\_globallogic::endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	else if ( team == game["attackers"] )
		thread maps\mp\gametypes\_globallogic::endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	else if ( team == game["defenders"] )
		thread maps\mp\gametypes\_globallogic::endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
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
			game["switchedspawnsides"] = !game["switchedspawnsides"];
		else
			level.halftimeSubCaption = "";

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
			game["switchedsides"] = !game["switchedsides"];
		else
			level.halftimeSubCaption = "";

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

onEndGame( winningTeam )
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	
	
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();
	
	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
}

// ========================================================================
//		Msgs
// ========================================================================

SetaMensagens()
{
	if ( getDvar( "scr_survivors_msg_strike" ) == "" )
		level.waiting_msg =  "Waiting the Support do his Job!";
	else
		level.waiting_msg = getDvar( "scr_survivors_msg_strike" );
	
	if ( getDvar( "scr_survivors_msg_hunt" ) == "" )
		level.attack_msg =  "^7Hunt the ^9Survivors^7!";
	else
		level.attack_msg = getDvar( "scr_survivors_msg_hunt" );
	
	if ( getDvar( "scr_survivors_msg_defense" ) == "" )
		level.defend_msg =  "Spread & Keep Moving! Stay Alive!";
	else
		level.defend_msg = getDvar( "scr_survivors_msg_defense" );
}