#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// SAVAGE

init()
{
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "savage", 6, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "savage", 0, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "savage", 10, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "savage", 100, 100, 100 );	
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "savage", 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchSpawnDvar( "savage", 2, 0, 9 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "savage", 1, 0, 1 );
	maps\mp\gametypes\_globallogic::registerTypeDvar( "savage", 1, 0, 3 );

	SetDvar( "scr_savage_playerrespawndelay", -1 );
	SetDvar( "scr_savage_waverespawndelay", -1 );

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onRoundSwitch = ::onRoundSwitch;
	level.onRoundSwitchSpawn = ::onRoundSwitchSpawn;
	level.onTimeLimit = ::onTimeLimit; 
	level.endGameOnScoreLimit = false;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPrecacheGameType = ::onPrecacheGameType;
		
	game["dialog"]["gametype"] = "team_hardcore";
}

onPrecacheGameType()
{
	precacheStatusIcon( "killiconmelee" );
	precacheShader("compass_waypoint_target");
	precacheShader("waypoint_target");	
	precacheStatusIcon( "specialty_longersprint" );
}

onStartGameType()
{
	//garante que sempre tera todas as armas
	level.HajasWeap = 0;
	
	level.ZuluRevealed = false;
	level.Eliminados = false;
	level.rescue = false;

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
	else // se não for war e for BOT-COOP players somente atacam!
	{
		if ( getDvarInt("fl_bots") == 1 && getDvarInt("fl_bots_coop") > 0)
		{
			setDvar( "scr_savage_roundswitch", 0 ); // não mudar de lado
			setDvar( "scr_savage_roundlimit", 1 ); // só um round
			if ( getDvarInt("fl_bots_coop") == 1 ) //allies
			{
				if ( game["defenders"] == "allies" )
					game["switchedsides"] = true;
			}
			else if ( getDvarInt("fl_bots_coop") == 2 ) //axis
			{
				if ( game["defenders"] == "axis" )
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

	setClientNameMode("manual_change");
	
	level.zulu_point_smoke	= loadfx("smoke/signal_smoke_green");	

	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_SAVAGE_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_SAVAGE_DEFENDER" );
	
	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_SAVAGE_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_SAVAGE_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_SAVAGE_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_SAVAGE_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_SAVAGE_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_SAVAGE_DEFENDER_HINT" );
			
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );		

	level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	
	// calcula tamanho do mapa
	level.tamanho = distance( level.attack_spawn, level.defend_spawn );
	level.spread = int(level.tamanho/2);
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );	
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	

	allowed[0] = "savage"; // nada
		
	level.displayRoundEndText = false;
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	//elimination style
	level.overrideTeamScore = true;
	level.displayRoundEndText = true;

	SetaMensagens();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
	
	thread ZuluSmoke();	
	
	level.chopperhelp = "none"; // "air" "land" "gone"
}


// ==================================================================================================================
//   Escape Zone
// ==================================================================================================================

ZuluSmoke() 
{
	level.pos_zulu = SelecionaSpawn();
	
	CalculaSpawnsDefesa();
	thread HeliResgate();

	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	wait 10;
	
	level.zulu = maps\mp\gametypes\_objpoints::createTeamObjpoint( "objpoint_next_hq", level.pos_zulu + (0,0,70), game["attackers"], "waypoint_target" );
	level.zulu setWayPoint( true, "waypoint_target" );		

	thread playSoundinSpace( "smokegrenade_explode_default", level.pos_zulu );
	
	rot = randomfloat(360);	
	zulupoint = spawnFx( level.zulu_point_smoke, level.pos_zulu, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( zulupoint );
	
	level.ZuluRevealed = true;

	thread ZuluRevealed();
}

ZuluRevealed()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		player iPrintLn( level.msg_zulu );
	}
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
}


PlayerSafe()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while(1)
	{
		if ( level.ZuluRevealed == true )
		{
			if ( distance(self.origin,level.pos_zulu) < 100 )
			{
				maps\mp\gametypes\_globallogic::HajasDaScore( self, 10 );
				self.retreat = "hold"; // "retreat" "safe" "left"
				self thread Hold();
				return;
			} 
			if ( level.chopperhelp == "air" )
			{
				self thread Hold();
				return;
			}			
		}
		wait 1;
	}
}

Hold()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	if ( level.chopperhelp == "none" )
		level.chopperhelp = "air";
	
	if ( level.HelpMode == 1 )		
	{
		while(1)
		{
			if ( level.chopperhelp == "air" )
			{
				if ( distance(self.origin,level.pos_zulu) > 600 )
					self iprintln( level.msg_out );
				
				wait 1;
			}
			else if ( level.chopperhelp == "land" )
			{ 
				if ( distance(self.origin,level.pos_zulu) < 600 && self.salvo == true )
				{
					maps\mp\gametypes\_globallogic::HajasDaScore( self, 5 );
					thread EscapeUpdateScore( self.team );
					self.retreat = "safe"; // "retreat" "hold" "left"
					self thread Salvo();
					return;
				} 
			}
			else if ( level.chopperhelp == "gone" )
			{
				self.retreat = "left"; // "retreat" "hold" "safe"
				self iprintlnbold( level.msg_left );
				return;
			}		
			wait 1;
		}
	
	}
	else if ( level.HelpMode == 0 )	
	{
		while(1)
		{
			if ( level.chopperhelp == "air" )
			{
				if ( distance(self.origin,level.pos_zulu) > 600 )
					self iprintln( level.msg_out );
				
				wait 1;
			}
			else if ( level.chopperhelp == "land" )
			{ 
				if ( distance(self.origin,level.pos_zulu) < 600 )
				{
					maps\mp\gametypes\_globallogic::HajasDaScore( self, 5 );
					thread EscapeUpdateScore( self.team );
					self.retreat = "safe"; // "retreat" "hold" "left"
					self thread Salvo();
					return;
				} 
			}
			else if ( level.chopperhelp == "gone" )
			{
				self.retreat = "left"; // "retreat" "hold" "safe"
				self iprintlnbold( level.msg_left );
				return;
			}		
			wait 1;
		}
	}	
}

Salvo()
{
	if ( level.starstreak > 0 )
		self.fl_stars_pts = self.fl_stars_pts + 3;
	
	// houve resgate
	level.rescue = true;
	
	// foi salvo
	[[level.spawnSpectator]]();
	
	// troca icon
	self.statusicon = "specialty_longersprint";	
}
	
HeliResgate()
{
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait 5;

	if ( !isDefined(level.chopperhelp) )
		level.chopperhelp = "none"; // "air" "land" "gone"
		
	while ( level.chopperhelp == "none" )
		wait 1;
		
	// se chegou aqui ele tá chegando!
	
	// inicia HELI de resgate!
	thread MsgTime( game["attackers"], level.msg_secure );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "secure_all", game["attackers"] );
	maps\mp\gametypes\_globallogic::leaderDialog( "move_to_new", game["defenders"] );
	wait 4;
	maps\mp\gametypes\_globallogic::leaderDialog( "helicopter_inbound", game["attackers"] );
	wait 30;
	thread MsgTime( game["attackers"], level.msg_60 );
	maps\mp\gametypes\_globallogic::leaderDialog( "keepfighting" );
	wait 20;
	thread maps\mp\gametypes\_hardpoints::SavageHeli( game["attackers"] );
	wait 10;
	thread MsgTime( game["attackers"], level.msg_30 );
	maps\mp\gametypes\_globallogic::leaderDialog( "keepfighting" );
	wait 30;
	thread MsgTime( game["attackers"], level.msg_go );
	maps\mp\gametypes\_globallogic::leaderDialog( "goodtogo", game["attackers"] );
		
	// aterrizou!
	level.chopperhelp = "land";
	wait 5;

	// foi embora!
	level.chopperhelp = "gone";
	
	thread MsgTime( game["attackers"], level.msg_pilot );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "obj_taken", game["attackers"] );
	
	thread TestaPlayers();
}

MsgTime( time, texto )
{
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == time )
		{
			player iPrintLn( texto );
		}
	}
}

// ========================================================================
//		Player
// ========================================================================

TestaPlayers()
{
	jogadores_salvos = 0;
	jogadores_mortos = 0;
	jogadores_deixados = 0;
	SavageWinner = game["defenders"];
	SavageMsg = level.rescue_fail;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == game["attackers"] )
		{
			if ( isAlive( player ) )
			{
				if( player.retreat == "safe" )
					jogadores_salvos++;
				else
					jogadores_deixados++;
			}
			else
				jogadores_mortos++;
		}
	}
	
	level.rescue = true;
	
	if ( jogadores_salvos >= (jogadores_deixados + jogadores_mortos) )
	{
		SavageWinner = game["attackers"];
		SavageMsg = level.rescue_ok;
	}
	
	if ( jogadores_deixados > 0 )
	{
		x = 0;
		time = game["attackers"];
		
		while ( x < 60 )
		{
			wait 1;
			x++;
			if ( level.everExisted[time] && level.aliveCount[time] == 0 )
				x = 70;
		}
	}
	
	sd_endGame( SavageWinner, SavageMsg );
}

onSpawnPlayer()
{
	self.retreat = "retreat"; // "hold" "safe" "left"

	if(self.pers["team"] == game["attackers"])
		thread PlayerSafe();

	if ( level.inPrematchPeriod )
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

		spawnPoints = getEntArray( spawnPointName, "classname" );
		assert( spawnPoints.size );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

		self spawn( spawnpoint.origin, spawnpoint.angles );
	}
	else
	{
		if(self.pers["team"] == game["attackers"])
		{
			spawnPointName = "mp_sd_spawn_attacker";
			
			if ( !isDefined( game["switchedspawnsides"] ) )
				game["switchedspawnsides"] = false;
			
			if ( game["switchedspawnsides"] )
			{
				if ( spawnPointName == "mp_sd_spawn_defender")
					spawnPointName = "mp_sd_spawn_attacker";
				else
					spawnPointName = "mp_sd_spawn_defender";
			}

			spawnPoints = getEntArray( spawnPointName, "classname" );
			assert( spawnPoints.size );
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			
			if ( getDvarInt ( "frontlines_abmode" ) == 1 )
			{
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
				maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );			
			}
			else
				self spawn( spawnpoint.origin, spawnpoint.angles );			
		}
		else
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.DefesaSpawns );
			self spawn( spawnpoint.origin, spawnpoint.angles );
		}
	}
	
	level notify ( "spawned_player" );

	// msg
	if ( level.SidesMSG == 1 )
	{	
		if ( self.pers["team"] != game["defenders"] )
			self iPrintLnbold( level.defend_msg );
		else
			self iPrintLnbold( level.attack_msg );
	}	
	
	// voice order se civis
	if ( self.pers["team"] == game["defenders"] )
		self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "attack" );
}

SelecionaSpawn()
{
	// acha lado da defesa
	spawns_final = undefined;
	
	spawns_final = level.defend_spawn;
	
	if ( !isDefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;	
	
	if ( game["switchedspawnsides"] )
	{
		spawns_final = level.attack_spawn;
	}
	else
	{
		spawns_final = level.defend_spawn;
	}
	
	return spawns_final;
}

CalculaSpawnsDefesa()
{
	// inicia spaws da defesa
	level.DefesaSpawns = [];

	// distancia mínima para spawn ser válido! pra não nascer dentro da hold line, por isso = 600
	dist_min = 1000;

	// distancia maxima para spawn ser válido!
	dist_max = level.spread;

	// pega spawns tdm
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( game["defenders"] );
	assert( spawnPoints.size );	
	
	// loop control
	tudo_ok = false;	
	
	// spawn_count
	spawn_count = 0;	
	
	if ( level.script == "mp_beltot_2" )
	{
		spawnPoints = getEntArray( "mp_sd_spawn_defender", "classname" );
		assert( spawnPoints.size );
		
		for (i = 0; i < spawnpoints.size; i++)
		{
			level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
		}	
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
			dist = distance(level.pos_zulu, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist > dist_min && dist < dist_max )
			{
				spawn_count++;
			}
		}
		if ( spawn_count < 3 )
		{
			dist_max = dist_max + 200;
			spawn_count = 0;
		}
		else
		{
			tudo_ok = true;
		}
	}
	
	// cria lista de spawns
	for (i = 0; i < spawnpoints.size; i++)
	{
		dist = distance(level.pos_zulu, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist > dist_min && dist < dist_max )
		{
			level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
		}
	}	
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if ( level.HelpMode == 0 )	
	{
		// apenas time armado não pode morrer na faca!
		if ( self.pers["team"] == game["attackers"] )
		{
			if ( sMeansOfDeath == "MOD_MELEE" || sMeansOfDeath == "MOD_SUICIDE" || ( ( isDefined( self.lastStand ) && self.lastStand == true ) && attacker == self  ) )
			{
				self.pers["lives"] = 0;
				self.statusicon = "killiconmelee";
				if ( level.rescue == true )
					EscapeUpdateScore ( game["defenders"] );
				
			}
		}
	}
	else if ( level.HelpMode == 1 )	
	{
		// apenas time armado não pode morrer na faca!
		if ( self.pers["team"] == game["attackers"] )
		{
			if ( level.rescue == true )
			{
				self.pers["lives"] = 0;
				self.statusicon = "killiconmelee";
				EscapeUpdateScore ( game["defenders"] );
			}
		}
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

// ========================================================================
//		Weapons
// ========================================================================

DaFaca()
{
	weapon = "deserteagle_mp";
	
	self giveWeapon( weapon );
	self maps\mp\gametypes\_class::setWeaponAmmoOverall( weapon, 0 );
	self switchToWeapon( weapon );	
}

// ========================================================================
//		Game Over
// ========================================================================

EscapeUpdateScore ( team )
{
	[[level._setTeamScore]]( team, [[level._getTeamScore]]( team ) + 1 );
}

EliminaScore( team )
{
	[[level._setTeamScore]]( team, [[level._getTeamScore]]( team ) + 10 );
}

sd_endGame( winningTeam, endReasonText )
{
	// da 10 pontos pra defesa se eliminar o ataque
	if ( level.Eliminados == true )
		EliminaScore( game["defenders"] );

	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

onDeadEvent( team )
{
	if ( level.rescue == false )
		level.Eliminados = true;

	if ( team == "all" )
	{
		// vitória da defesa pois eliminou todos inimigos
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );		
	}
	else if ( team == game["attackers"] )
	{
		// vitória da defesa pois eliminou todos inimigos
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		// vítoria do ataque, e calcula quantos pontos fizeram com os vivos
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
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
	
	sd_endGame( winner, game["strings"]["time_limit_reached"] );
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

// ========================================================================
//		Sound
// ========================================================================

playSoundinSpace( alias, origin )
{
	level endon( "game_ended" );

	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 6; // MP doesn't have "sounddone" notifies =(
	org delete();
}

// ========================================================================
//		Mensagens
// ========================================================================

SetaMensagens()
{
	// spawn

	if ( getDvar( "scr_savage_msg_attack" ) == "" )
	{
		level.attack_msg =  "^9Attack^7! ^9Kill'em All^7!";
	}
	else
	{
		level.attack_msg = getDvar( "scr_savage_msg_attack" );
	}
	
	if ( getDvar( "scr_savage_msg_retreat" ) == "" )
	{
		level.defend_msg =  "^9Retreat^7!";
	}
	else
	{
		level.defend_msg = getDvar( "scr_savage_msg_retreat" );
	}
	
	// heli
	
	if ( getDvar( "scr_savage_msg_zulu" ) == "" )
	{
		level.msg_zulu =  "^1Warning ^0: ^7Zulu Point Marked!";
	}
	else
	{
		level.msg_zulu = getDvar( "scr_savage_msg_zulu" );
	}
	
	if ( getDvar( "scr_savage_msg_out" ) == "" )
	{
		level.msg_out =  "^1Warning ^0: ^7You are ^1OUT ^7of the Extraction Zone!";
	}
	else
	{
		level.msg_out = getDvar( "scr_savage_msg_out" );
	}
	
	if ( getDvar( "scr_savage_msg_left" ) == "" )
	{
		level.msg_left =  "^1Warning ^0: ^7You were ^1LEFT ^7behind!";
	}
	else
	{
		level.msg_left = getDvar( "scr_savage_msg_left" );
	}	
	
	if ( getDvar( "scr_savage_msg_secure" ) == "" )
	{
		level.msg_secure =  "^1Warning ^0: ^7Secure the ^1Extraction Zone ^7for pickup!";
	}
	else
	{
		level.msg_secure = getDvar( "scr_savage_msg_secure" );
	}	
	
	if ( getDvar( "scr_savage_msg_60" ) == "" )
	{
		level.msg_60 =  "^1Warning ^0: ^7Pickup in ^160 ^7seconds!";
	}
	else
	{
		level.msg_60 = getDvar( "scr_savage_msg_60" );
	}	

	if ( getDvar( "scr_savage_msg_30" ) == "" )
	{
		level.msg_30 =  "^1Warning ^0: ^7Pickup in ^130 ^7seconds!";
	}
	else
	{
		level.msg_30 = getDvar( "scr_savage_msg_30" );
	}
	
	if ( getDvar( "scr_savage_msg_go" ) == "" )
	{
		level.msg_go =  "^1Warning ^0: ^7Go Go Go! ^1Run^7! Get to the chopper!";
	}
	else
	{
		level.msg_go = getDvar( "scr_savage_msg_go" );
	}	
	
	if ( getDvar( "scr_savage_msg_pilot" ) == "" )
	{
		level.msg_pilot =  "^1Warning ^0: ^7Let's go ^1Pilot^7! Take Off!";
	}
	else
	{
		level.msg_pilot = getDvar( "scr_savage_msg_pilot" );
	}		
		
	// rescue
	
	if ( getDvar( "scr_savage_msg_rescue" ) == "" )
	{
		level.rescue_ok =  "Rescue Succeed";
	}
	else
	{
		level.rescue_ok = getDvar( "scr_savage_msg_rescue" );
	}	

	if ( getDvar( "scr_savage_msg_fail" ) == "" )
	{
		level.rescue_fail =  "Rescue Failed";
	}
	else
	{
		level.rescue_fail = getDvar( "scr_savage_msg_fail" );
	}	
}