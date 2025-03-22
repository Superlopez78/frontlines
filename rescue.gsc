#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar RescueNoob
registerRescueNoobDvar( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_type");
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );
		
	
	level.RescueNoobDvar = dvarString;
	level.RescueNoobMin = minValue;
	level.RescueNoobMax = maxValue;
	level.RescueNoob = getDvarInt( level.RescueNoobDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
		
	level.LiveVIP = false;
	level.Prisoner_preso = true;
	level.prison = undefined;
	level.pri_weap = "colt45_mp";
	
	level.Prisoner_killer = undefined;
	level.Prisoner_player = undefined;
	
	// controla mortes por claymores
	level.Prisoner_mod = false;
	
	// contra msg "you are the Prisoner" pra só aparecer no 1o spawn
	level.mostra_msg_Prisoner = true;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 5, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 0, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 10, 0, 30 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 1, 0, 10 );
	maps\mp\gametypes\_globallogic::registerTypeDvar( level.gameType, 0, 0, 3 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( level.gameType, 1, 0, 1 );
	maps\mp\gametypes\_globallogic::registerNextVIPDvar( level.gameType, 2, 0, 2 );
	maps\mp\gametypes\_globallogic::registerVIPNameDvar( "scr_rescue_name", 1, 0, 1 );
	
	registerRescueNoobDvar( "scr_rescue_noob", 1, 0, 1 );
	
	// 0 = Random
	// 1 = A
	// 2 = B
	// 3 = Sab
	
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
	
	// controlar morte vip/commandante
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPlayerDisconnect = ::onPlayerDisconnect;		
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["offense_obj"] = "capture_obj";
	game["dialog"]["defense_obj"] = "obj_defend";
}


onPrecacheGameType()
{
	precacheShader("compass_waypoint_target");
	precacheShader("waypoint_target");
	precacheShader("waypoint_defend");
	precacheShader("compass_waypoint_defend");	
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_escort" );

	precacheShader( "specialty_fastreload" );
	precacheStatusIcon( "specialty_fastreload" );	
	
	precacheModel( "prop_suitcase_bomb" );	
	
	//sounds
	
	game["commander_killed"] = "mp_enemy_obj_captured";
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";	
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

onStartGameType()
{
	if ( level.HajasWeap == 6 || (level.HajasWeap >= 11 && level.HajasWeap <= 14))
		level.HajasWeap = 0;

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
		
	level.zulu_point_smoke	= loadfx("smoke/signal_smoke_green");
	
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_RESCUE_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_RESCUE_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_RESCUE_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_RESCUE_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_RESCUE_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_RESCUE_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_RESCUE_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_RESCUE_DEFENDER" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );	
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "sab";
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	// seta mensagens
	SetaMensagens();
	
	novos_sd_init();
	
	if ( level.novos_objs )
	{
		thread DeleteSabBombs();
		thread bombs();
	}
	else
		thread bombsRELOAD();
		
	spawns_Prisoner();
	
	// cria prison - depois essa posição é atualizada lá em baixo!
	level.prison_mark = maps\mp\gametypes\_objpoints::createTeamObjpoint( "objpoint_next_hq", level.prison.origin + (0,0,70), "all", "waypoint_defend" );
	level.prison_mark setWayPoint( true, "waypoint_defend" );
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );	
	
	thread ControlaRescueTeam( game["attackers"] );
}

ControlaRescueTeam( team )
{
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );	

	// tempo pra nego se conectar		
	wait 35;		
	
	while(1)
	{
		wait 5;
		// se só tem 1 vivo no ataque
		if ( level.everExisted[team] && level.aliveCount[team] == 1 )
		{
			// se ele está preso ou ele está em LS = fim de jogo!
			if ( level.Prisoner_preso == true || ( isDefined(level.Prisoner_player) && isDefined(level.Prisoner_player.lastStand) ) )
			{
				// termina o round
				level.overrideTeamScore = true;
				level.displayRoundEndText = true;
				
				msg_final = game["strings"][game["attackers"]+"_eliminated"];

				iPrintLn( msg_final );
				makeDvarServerInfo( "ui_text_endreason", msg_final );
				setDvar( "ui_text_endreason", msg_final );
				
				sd_endGame( game["defenders"], msg_final );
				return;			
			}
		}
	}
}

// ==================================================================================================================
//   Prisoner
// ==================================================================================================================

// starta Prisoner
Prisoner()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	//iprintln( "^3Prisoner" );		
	
	// inicia testes de salvamento
	thread PrisonerFree();	
	
	level.mostra_msg_Prisoner = false;
	
	while ( level.Prisoner_preso == true )
	{
		if(isDefined(self.bIsBot) && self.bIsBot) 
		{
			self TakeAllWeapons();
			self.weaponPrefix = "none";
			self.pers["weapon"] = "none";
		}	
	
		if ( distance( level.prison.origin, self.origin ) > 1 )
		{
			self setorigin(level.prison.origin);
			self setplayerangles(level.prison.angles);	
			if ( level.SidesMSG == 1 )
				self iprintlnbold ( level.tied_msg );
		}
		wait 0.1;
	}
}

// controla prisão para libertá-lo
PrisonerFree()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	//iprintln( "^1PrisonerFree" );

	while(1)
	{
		wait 2;
		for ( i = 0; i < level.players.size; i++ )
		{
			outro = level.players[i].origin;

			if ( level.players[i].team == self.team && isAlive( level.players[i] ) )
			{
				// so faz se não for ele mesmo
				if ( self.name != level.players[i].name )
				{
					dist = distance( outro, self.origin );
					if ( dist < 50 )
					{
						level.Prisoner_preso = false;
						if ( level.SidesMSG == 1 )
							self iprintlnbold ( level.free_msg );
						maps\mp\gametypes\_globallogic::givePlayerScore( "save", level.players[i] );
						thread PrisonerEscaped();
						thread AntiStupid();
						thread maps\mp\gametypes\_hardpoints::WavesReinf( game["attackers"] );
						return;
					}
				}
			}
		}
	}
}

// se ferido, controla seu salvamento
PrisonerSaved()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	//iprintln( "^1PrisonerFree" );
	
	if(isDefined(self.bIsBot) && self.bIsBot) 
	{
		self TakeAllWeapons();
		self.weaponPrefix = "none";
		self.pers["weapon"] = "none";
	}

	while(1)
	{
		wait 3;
		for ( i = 0; i < level.players.size; i++ )
		{
			outro = level.players[i].origin;

			if ( level.players[i].team == self.team && isAlive( level.players[i] ) )
			{
				// so faz se não for ele mesmo
				if ( self.name != level.players[i].name )
				{
					dist = distance( outro, self.origin );
					if ( dist < 50 ) 
					{
						PrisonerRevive();
						if ( level.SidesMSG == 1 )
							self iprintlnbold ( level.saved_msg );
						maps\mp\gametypes\_globallogic::givePlayerScore( "save", level.players[i] );
						maps\mp\gametypes\_globallogic::leaderDialog( "keepfighting",  game["attackers"] );
						return;
					}
				}
			}
		}
	}
}

// revive o Prisoner caso salvo quando ferido
PrisonerRevive()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	self.lastStand = undefined;
	self.useLastStandParams = false;
	
	self.pers["class"] = "CLASS_VIP";
	self.class = "CLASS_VIP";
	
	self spawn( self.origin, self.angles );
	
	self.pers["primary"] = 0;
	self.pers["weapon"] = undefined;

	self maps\mp\gametypes\_class::setClass( self.pers["class"] );
	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
	self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );	

	self.salvo = true;
	
	self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
	self maps\mp\gametypes\_globallogic::ExecClientCommand("goprone");	
	
	if(isDefined(self.bIsBot) && self.bIsBot) 
	{
		self TakeAllWeapons();
		self.weaponPrefix = level.pri_weap;
		self.pers["weapon"] = level.pri_weap;
	}	
	
	//iprintlnbold ("reviveu! full gear!");
}

// controla se ele chegou ao Zulu e termina o round (iniciado em PrisonerFree assim q ele é salvo)
PrisonerEscaped()
{
	self.Safe = false;
	
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	//iprintln( "^4PrisonerEscaped" );	
	
	if(isDefined(self.bIsBot) && self.bIsBot) 
	{
		self TakeAllWeapons();
		self.weaponPrefix = level.pri_weap;
		self.pers["weapon"] = level.pri_weap;
	}
	
	// inicia ordens de voz
	thread Defesa_PrisEsc();
	thread Ataque_PrisEsc();
	
	// deleta prisão
	level.prison_mark destroy();
	
	// icone escort/capture!
	thread CriaTriggers( self );	

	while(1)
	{
		if ( level.ZuluRevealed == true )
		{
			if ( distance(self.origin,level.pos_zulu) < 100 )
			{
					self.Safe = true;
					maps\mp\gametypes\_globallogic::givePlayerScore( "safe", self );
					// pontos extras por ser o VIP
					maps\mp\gametypes\_globallogic::givePlayerScore( "safe", self );
					
					// termina o round
					level.overrideTeamScore = true;
					level.displayRoundEndText = true;

					iPrintLn( level.rescue_escaped );
					makeDvarServerInfo( "ui_text_endreason", level.rescue_escaped );
					setDvar( "ui_text_endreason", level.rescue_escaped );
						
					sd_endGame( game["attackers"], level.rescue_escaped_score );		
					return;		
			} 
		}
		wait 1;
	}
}

CriaTriggers( player )
{
	while ( !self.hasSpawned )
		wait ( 0.1 );

	//wait ( 0.01 );
	pos = player.origin + (0,0,-60);

	if ( !isDefined ( level.Docs ) )
	{
		docs["pasta_trigger"] = spawn( "trigger_radius", pos, 0, 20, 100 );
		docs["pasta"][0] = spawn( "script_model", pos);
		docs["zone_trigger"] = spawn( "trigger_radius", pos, 0, 50, 100 );	
		level.Docs = SpawnDocs( docs["pasta_trigger"], docs["pasta"] );	
	}
	else
	{
		level.Docs.trigger.origin = pos;
		level.Docs maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" ); 
		level.Docs maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );		
	}
	level.Docs maps\mp\gametypes\_gameobjects::setPickedUp( player );
}

SpawnDocs( trigger, visuals )
{
	pastaObject = maps\mp\gametypes\_gameobjects::createCarryObject( game["attackers"], trigger, visuals, (0,0,100) );
	pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_escort" );
	pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" ); 
	pastaObject maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );

	pastaObject.onPickup = ::onPickupDocs;	   
	pastaObject.onDrop = ::onDropDocs;
	pastaObject.allowWeapons = true;
	   
	return pastaObject;	
}

onDropDocs( player )
{
	level.Docs maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
	level.Docs maps\mp\gametypes\_gameobjects::allowCarry( "none" );
}

onPickupDocs( player )
{
	team = player.pers["team"];
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
}


Defesa_PrisEsc()
{
	level endon( "game_ended" );

	maps\mp\gametypes\_globallogic::leaderDialog( "obj_lost",  game["defenders"] );
	wait 2;
	maps\mp\gametypes\_globallogic::leaderDialog( "attack",  game["defenders"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "boost",  game["defenders"] );
}

Ataque_PrisEsc()
{
	level endon( "game_ended" );
	
	maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
	wait 3;
	maps\mp\gametypes\_globallogic::leaderDialog( "obj_defend",  game["attackers"] );
}

// controla se o Prisoner está vivo, se morto quem matou perde o round
// iniciado assim q ele dá spawn
PrisonerVivo()
{
	level endon( "game_ended" );
	
	teamk = undefined;
	
	while(1)
	{
		if ( !isAlive(level.Prisoner_player) )
		{
			// mataram o Prisoner
			
			// sounds
			maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], game["defenders"] );
			maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["attackers"] );

			game["VIPname"] = "";

			level.endtext = level.rescue_dead_score;

			// diz q nao tem mais vip/Commander vivo
			level.LiveVIP = false;
			
			//  pega o time do matador
			if ( isDefined(level.Prisoner_killer) )
			{
				teamk = level.Prisoner_killer.team;
			}			

			// deixa de ser Prisoner
			if ( isDefined(level.Prisoner_player) )
			{
				level.Prisoner_player.isPrisoner = false;
			}			
			level.Prisoner_player = undefined;

			level notify("vip_is_dead");
			setGameEndTime( 0 );
		
			// termina o round
			level.overrideTeamScore = true;
			level.displayRoundEndText = true;
		
			iPrintLn( level.rescue_dead );
			makeDvarServerInfo( "ui_text_endreason", level.rescue_dead );
			setDvar( "ui_text_endreason", level.rescue_dead );


			if ( level.Prisoner_mod == true )
			{
				// prisioneiro se matou com clay
				sd_endGame( game["defenders"], level.endtext );	
			}
			else 
			{
				if ( level.HelpMode != 1 )
				{
					maps\mp\gametypes\_globallogic::HajasDaScore( level.Prisoner_killer, -50 );
				}
				if ( getDvar( "scr_rescue_killed" ) != "" )
				{
					printOnTeam( "^9" + level.Prisoner_killer.name + "^7 " + getDvar( "scr_rescue_killed" ), teamk );
				}				
			
				if ( isDefined(teamk) && teamk == game["defenders"] )
				{
					sd_endGame( game["attackers"], level.endtext );
				}
				else
				{
					sd_endGame( game["defenders"], level.endtext );		
				}
			}
		}
		wait ( 0.5 );
	}
}

// ==================================================================================================================
//   Spawns
// ==================================================================================================================

spawns_Prisoner()
{
	// define time
	if ( game["attackers"] == "axis" )
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( "axis" );
	else
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( "allies" );
	
	// cria array com spawns válidos
	PrisonerSpawns = [];
	
	// distancia minima pra valer
	nearestdist = 8000;
	
	// spawns dos 2 lados
	//level.attack_spawn 
	//level.defend_spawn 
	
	// loop control
	tudo_ok = false;
	
	// spawn_count
	spawn_count = 0;
	
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
			dist1 = distance(level.attack_spawn, spawnpoints[i].origin);
			dist2 = distance(level.defend_spawn, spawnpoints[i].origin);
			if ( dist1 > nearestdist && dist2 > nearestdist )
			{
				spawn_count++;
			}
		}
		if ( spawn_count < 2 )
		{
			nearestdist = nearestdist - 1000;
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
		dist1 = distance(level.attack_spawn, spawnpoints[i].origin);
		dist2 = distance(level.defend_spawn, spawnpoints[i].origin);
		
		if ( dist1 > nearestdist && dist2 > nearestdist )
		{
			PrisonerSpawns[PrisonerSpawns.size] = spawnpoints[i];
		}
	}
	
	//logPrint("spawnsize = " + PrisonerSpawns.size + "\n");
	if ( PrisonerSpawns.size == 0 )
	{
		logPrint( "Warning! Not spawnPoints available for Prisoner! = " + PrisonerSpawns.size + "\n");
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );	
		wait 10; // segura até mudar gametype ou vai dar erro antes da troca
	}
	level.prison = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( PrisonerSpawns );	
}

onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;

	// inverte spawns!!!
	if(self.pers["team"] == game["attackers"])
		spawnPointName = "mp_sd_spawn_attacker";
	else
		spawnPointName = "mp_sd_spawn_defender";
	
	// deleta skin do vip/commander se sobrou do round anterior
	if ( self.pers["class"] == "CLASS_COMMANDER" || self.pers["class"] == "CLASS_VIP" )
		VIPloadModelBACK();
	
	// caso mude de lado, o próximo VIP será o primeiro spawn do novo time
	if ( isDefined ( game["VIPteam"] ) )
	{
		if ( game["VIPteam"] == game["defenders"] )
			game["VIPname"] = "";
	}
	else
		game["VIPname"] = "";

	if ( level.LiveVIP == false && self.pers["team"] == game["attackers"])
	{
		// next = 0 : último ìd
		// next = 1 : melhor score 
		// next = 2 : random
		
		if ( level.NextVIP > 0 )
		{
			// caso não volte nada, será o primeiro sempre...
			if ( game["VIPname"] == "" )
				SpawnVIP();
			else
			{
				if ( game["VIPname"] == self.name )
					SpawnVIP();
				else
					SpawnSoldado();
			}
		}
		else
			SpawnVIP();
	}
	else
		SpawnSoldado();

	spawnPoints = getEntArray( spawnPointName, "classname" );
	assert( spawnPoints.size );		
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );	

	// seta prisao
	if ( self.isPrisoner == true )	
	{
		self spawn( level.prison.origin, level.prison.angles );	
		if ( getDvarInt ( "frontlines_abmode" ) == 1 )
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );

		if(isDefined(self.bIsBot) && self.bIsBot) 
		{
			self TakeAllWeapons();
			self.weaponPrefix = "none";
			self.pers["weapon"] = "none";
		}			
			
		level thread PrisonerVivo();
	}
	else
	{
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
	}

	level notify ( "spawned_player" );
}

SpawnVIP()
{
	self.isPrisoner = true;
	
	level.Prisoner_player = self;
	
	if ( level.SidesMSG == 1 )
	{
		if ( level.mostra_msg_Prisoner == true )
			self iPrintLnbold( level.rescue_you );
	}
	
	self thread createVipIcon();

	// troca a skin pra VIP/Commander
	VIPloadModel(); 	
	
	// diz q o mapa já tem um vip/commander vivo
	level.LiveVIP = true;	
	
	// icone defend!
	//self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
	
	// seta nome do Commander para mostrar na tela
	level.ShowName = self.name;	

	// inicia Prisoner
	if ( level.Prisoner_preso == true )
		thread Prisoner();
}

ShowVipName()
{
	self endon ("disconnect");
	self endon ("death");
	self endon ( "game_ended" );
	
	wait 5;
	if ( !isDefined( level.ShowName ) )
	{
		wait 5;
	}
	if ( isDefined( level.ShowName ) )
	{
		msg_info = "^9" + level.ShowName + "^7 " + level.rescue_is;
		self iPrintLn( msg_info );
	}
}

VIPloadModel()
{
	// salva classe original
	game["original_class"] = self.pers["class"];

	self.pers["class"] = "CLASS_VIP";
	self.class = "CLASS_VIP";
	self.pers["primary"] = 0;
	self.pers["weapon"] = undefined;

	self maps\mp\gametypes\_class::setClass( self.pers["class"] );
	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
	//self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
}

VIPloadModelPrisao()
{
	self.pers["class"] = "CLASS_VIP";
	self.class = "CLASS_VIP";
	self.pers["primary"] = 0;
	self.pers["weapon"] = undefined;

	self maps\mp\gametypes\_class::setClass( self.pers["class"] );
	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
	//self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
}

VIPloadModelBACK()
{
	// volta sempre pra assault caso não ache sua anterior
	if (isDefined ( game["original_class_atual"] ) )
	{
		self.pers["class"] = game["original_class_atual"];
		self.class = game["original_class_atual"];
	}
	else
	{
		self.pers["class"] = "CLASS_ASSAULT";
		self.class = "CLASS_ASSAULT";
	}
		
	self.pers["primary"] = 0;
	self.pers["weapon"] = undefined;

	self maps\mp\gametypes\_class::setClass( self.pers["class"] );
	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
	self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
}

createVipIcon()
{
	self.carryIcon = createIcon( "specialty_fastreload", 35, 35 );
	self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
	self.carryIcon.alpha = 0.75;
	
	// carrega icon no placar
	self.statusicon = "specialty_fastreload";
}

SpawnSoldado()
{
	self.isPrisoner = false;

	if ( self.pers["team"] == game["attackers"])
	{
		if ( level.SidesMSG == 1 )
			self iPrintLnbold( level.rescue_msg );

		if ( level.VIPName == 1 )
			thread ShowVipName();
	}
	else
	{
		if ( level.SidesMSG == 1 )
			self iPrintLnbold( level.defend_msg );
	}
}

// ==================================================================================================================
//   Death Control
// ==================================================================================================================

onPlayerDisconnect()
{
	self vipDead();
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	// self vipDead();
	// ver func PrisonerVivo()
}

vipDead()
{
	if ( isDefined( self.isPrisoner ) && self.isPrisoner == true )
	{
		// sounds
		maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], game["defenders"] );
		maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["attackers"] );

		game["VIPname"] = "";

		level.endtext = level.rescue_dead_score;
		
		// deixa de ser vip/commander
		self.isPrisoner = false;

		// diz q nao tem mais vip/Commander vivo
		level.LiveVIP = false;

		level notify("vip_is_dead");
		setGameEndTime( 0 );
		
		// termina o round
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
				
		iPrintLn( level.rescue_dead );
		makeDvarServerInfo( "ui_text_endreason", level.rescue_dead );
		setDvar( "ui_text_endreason", level.rescue_dead );

		sd_endGame( game["defenders"], level.endtext );
	}
}

// ==================================================================================================================
//   Game Over
// ==================================================================================================================

sd_endGame( winningTeam, endReasonText )
{
	maps\mp\gametypes\_globallogic::proxVIP( game["attackers"] );		

	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}


onDeadEvent( team )
{
	wait 1;
	if ( team == "all" )
	{
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["attackers"] )
	{
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
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

bombs()
{
	level.ZuluSafe = false;
	level.ZuluChopper = false;
	level.ZuluRevealed = false;
	
	sab_bomb_target = undefined;
	sab_bomb_visuals = undefined;	
	
	novos_sd();

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

	visuals[0] setModel( "prop_suitcase_bomb" );
	
	trigger delete();
	visuals[0] delete();
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	//logPrint("obj_index = " + obj_index + "\n");
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	obj_trigger = [];
	
	// sd bombs
	obj_index = randomInt ( bombZones.size );
	for ( index = 0; index < bombZones.size; index++ )
	{	
		if ( index == obj_index )
		{
			trigger = bombZones[index];
			visuals = getEntArray( bombZones[index].target, "targetname" );    
				
			bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
			bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "enemy" );
		    
			// zulu point
			level.pos_zulu = trigger.origin;
			thread ZuluSmoke( level.pos_zulu, bombZone );
						    
			// deleta visual
			for ( i = 0; i < visuals.size; i++ )
			{
				visuals[i] delete();
			}
		    
			level.bombZones[level.bombZones.size] = bombZone;
		}
		else
		{
			// destroi outra bomba

			trigger = bombZones[index];
			visuals = getEntArray( bombZones[index].target, "targetname" );    
	
			//logPrint("visuals.size = " + visuals.size + "\n");
			
			// deleta visual
			for ( i = 0; i < visuals.size; i++ )
			{
				visuals[i] delete();
			}
			
			// deleta trigger
			trigger delete();
		}
	}	

	// deleta clips longe do trigger
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{
			clips[i] delete();
		}
	}
}

bombsRELOAD()
{
	level.ZuluSafe = false;
	level.ZuluChopper = false;
	level.ZuluRevealed = false;
	
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
	}

	if ( level.sab_ok == true )
	{
		// adiciona a origem da bomba do SAB correta
		sab_bomb_target = DefineSabBomb( maleta ) GetOrigin();		
	}
	
	visuals[0] setModel( "prop_suitcase_bomb" );
	
	trigger delete();
	visuals[0] delete();
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	if ( level.sab_ok == true )
	{
		// define posição final da bomba
		sab_bomb_visuals = SabBombPosFinal ( sab_bomb_target );
		//logPrint("sab_bomb_target = " + sab_bomb_target + "\n");
	}

	// depois de pegar posição, deleta todos os objs do sab
	thread DeleteSabBombs();	

	switch( level.Type )
	{
		case 0:
			obj_index = randomInt ( bombZones.size + 1 );
			break;
		case 1:
			obj_index = 0;
			break;
		case 2:
			obj_index = 1;
			break;
		case 3:
			obj_index = 2;
			break;
		default:
			obj_index = randomInt ( bombZones.size + 1 );
			break;
	}
	
	//logPrint("obj_index = " + obj_index + "\n");
	
	// pega arrays do clip e explosao FX
	clips = getentarray( "script_brushmodel","classname" );
	destroyed_models = getentarray("exploder", "targetname");
	
	obj_trigger = [];
	
	
	if ( level.sab_ok == false )
	{
		if ( level.Type == 0  || level.Type == 3 )
		{
			obj_index = randomInt ( bombZones.size );
		}
	}
		
	// sab bomb	
	if ( obj_index == 2 )
	{
		trigger_a = bombZones[0];
		trigger_b = bombZones[1];
		a_bomb = randomInt(bombZones.size);

		trigger = bombZones[a_bomb];
		visuals = getEntArray( bombZones[a_bomb].target, "targetname" );    

		if ( distance(trigger_a.origin,sab_bomb_target) > 100 && distance(trigger_b.origin,sab_bomb_target) > 100 )
		{
			// se distancia > 50, temos novo bombsite = move bomba
			
			// move clip
			novo_obj = undefined;
			for(i=0 ; i<clips.size ; i++)
			{
				if ( isDefined ( clips[i].script_gameobjectname ) )
				{
					if( clips[i].script_gameobjectname == "bombzone" )
					{
						if( distance( clips[i].origin , trigger.origin ) <= 100 )
							novo_obj = clips[i];
					}
				}
			}
			novo_obj.origin = sab_bomb_target + (0, 0, 30);
			
			// move visuals
			novo_visual = undefined;
			for( i=0 ; i<visuals.size ; i++ )
			{
				if( distance( visuals[i].origin , trigger.origin ) <= 100 )
					novo_visual = visuals[i];
			}
			novo_visual.origin = sab_bomb_visuals;
			
			// move trigger
			trigger.origin = sab_bomb_target;
		}
		
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "enemy" );

		// zulu point
		level.pos_zulu = trigger.origin;
		thread ZuluSmoke( level.pos_zulu, bombZone );		
		
		// deleta visual
		for ( i = 0; i < visuals.size; i++ )
		{
			visuals[i] delete();
		}		
		
		level.bombZones[level.bombZones.size] = bombZone;
		
		// seta a bomba obj
		obj_trigger = trigger;

		// destroi outra bomba

		trigger_del = bombZones[!a_bomb];
		visuals_del = getEntArray( bombZones[!a_bomb].target, "targetname" );    

		//logPrint("visuals_del.size = " + visuals_del.size + "\n");
		
		// deleta visual
		for ( i = 0; i < visuals_del.size; i++ )
		{
			visuals_del[i] delete();
		}
		
		// deleta trigger
		trigger_del delete();
	}
	else
	{
		// sd bombs
		for ( index = 0; index < bombZones.size; index++ )
		{	
			if ( index == obj_index )
			{
				trigger = bombZones[index];
				visuals = getEntArray( bombZones[index].target, "targetname" );    
					
				bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
				bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
				bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "enemy" );
		        
				// zulu point
				level.pos_zulu = trigger.origin;
				thread ZuluSmoke( level.pos_zulu, bombZone );
						        
				// deleta visual
				for ( i = 0; i < visuals.size; i++ )
				{
					visuals[i] delete();
				}
		        
				level.bombZones[level.bombZones.size] = bombZone;
			}
			else
			{
				// destroi outra bomba

				trigger = bombZones[index];
				visuals = getEntArray( bombZones[index].target, "targetname" );    
		
				//logPrint("visuals.size = " + visuals.size + "\n");
				
				// deleta visual
				for ( i = 0; i < visuals.size; i++ )
				{
					visuals[i] delete();
				}
				
				// deleta trigger
				trigger delete();
			}
		}	
	}

	// deleta clips longe do trigger
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{
			clips[i] delete();
		}
	}
}

DefineSabBomb( maleta )
{
	sab_bomb_al = getEnt( "sab_bomb_allies", "targetname" );
	sab_bomb_ax = getEnt( "sab_bomb_axis", "targetname" );

	if ( distance(maleta.origin,sab_bomb_al.origin) > distance(maleta.origin,sab_bomb_ax.origin) )
	{
		return sab_bomb_al;
	}
	else
	{
		return sab_bomb_ax;		
	}
}

DeleteSabBombs()
{
	allowed = [];
	allowed[0] = "sd";
	allowed[1] = "bombzone";

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

playSoundinSpace( alias, origin )
{
	level endon( "game_ended" );

	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 6; // MP doesn't have "sounddone" notifies =(
	org delete();
}

ZuluSmoke( origin, zone ) 
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	while ( level.Prisoner_preso == true )
		wait 1;

	wait 2;
	
	zone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
	zone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" );
		
	thread playSoundinSpace( "smokegrenade_explode_default", origin );

	rot = randomfloat(360);
	zulupoint = spawnFx( level.zulu_point_smoke, origin, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( zulupoint );
	
	level.ZuluRevealed = true;

	thread ZuluRevealed();
}

ZuluRevealed()
{
	if ( isDefined(level.Prisoner_player) )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( player.pers["team"] == game["attackers"] )
			{
				if ( player != level.Prisoner_player )
					player iPrintLn( level.escape_msg );
			}
		}
	}
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
}

AntiStupid()
{
	level endon( "game_ended" );
	
	if ( getDvar( "scr_rescue_released" ) != "" )
	{
		// diz que escapou (embaixo)
		printOnTeam( getDvar( "scr_rescue_released" ), game["defenders"]);
		playSoundOnPlayers( "mp_suitcase_pickup", game["defenders"] );
	}
	
	// diz pra não matar ( na cara )
	if ( getDvar( "scr_rescue_notkill" ) != "" )
	{
		printBoldOnTeam( getDvar( "scr_rescue_notkill" ), game["defenders"]);
		wait 3;
		
		if ( getDvar( "scr_rescue_notkillfull" ) != "" )
		{
			while (1)
			{
				printOnTeam( getDvar( "scr_rescue_notkillfull" ), game["defenders"]);
				wait 10;
			}
		}
	}
}


SetaMensagens()
{
	if ( getDvar( "scr_rescue_escaped_score" ) == "" )
	{
		level.rescue_escaped_score =  "^7The ^3Prisoner^7 escaped!";
	}
	else
	{
		level.rescue_escaped_score = getDvar( "scr_rescue_escaped_score" );
	}
	
	if ( getDvar( "scr_rescue_escaped" ) == "" )
	{
		level.rescue_escaped =  "^7The ^9Prisoner^7 escaped!";
	}
	else
	{
		level.rescue_escaped = getDvar( "scr_rescue_escaped" );
	}	
	
	if ( getDvar( "scr_rescue_dead_score" ) == "" )
	{
		level.rescue_dead_score =  "^7The ^3Prisoner ^7is Dead!";
	}
	else
	{
		level.rescue_dead_score = getDvar( "scr_rescue_dead_score" );
	}
	
	if ( getDvar( "scr_rescue_dead" ) == "" )
	{
		level.rescue_dead =  "^7The ^9Prisoner ^7is Dead!";
	}
	else
	{
		level.rescue_dead = getDvar( "scr_rescue_dead" );
	}	

	if ( getDvar( "scr_rescue_is" ) == "" )
	{
		level.rescue_is =  "is the ^9Prisoner^7!";
	}
	else
	{
		level.rescue_is = getDvar( "scr_rescue_is" );
	}	

	//------------------------------------

	if ( getDvar( "scr_rescue_you" ) == "" )
	{
		level.rescue_you =  "^7You are the ^9Prisoner^7!";
	}
	else
	{
		level.rescue_you = getDvar( "scr_rescue_you" );
	}
	
	if ( getDvar( "scr_rescue_attack" ) == "" )
	{
		level.rescue_msg =  "^7Rescue the ^9Prisoner^7!";
	}
	else
	{
		level.rescue_msg = getDvar( "scr_rescue_attack" );
	}

	if ( getDvar( "scr_rescue_defend" ) == "" )
	{
		level.defend_msg =  "^7Guard the ^9Prisoner^7! We need him ^9Alive^7!";
	}
	else
	{
		level.defend_msg = getDvar( "scr_rescue_defend" );
	}
	
	if ( getDvar( "scr_rescue_mark" ) == "" )
	{
		level.escape_msg =  "^1Warning ^0: ^7Extraction Point Marked!";
	}
	else
	{
		level.escape_msg = getDvar( "scr_rescue_mark" );
	}	

	if ( getDvar( "scr_rescue_tied" ) == "" )
	{
		level.tied_msg =  "You are ^1Tied^7! Wait for the Rescue!";
	}
	else
	{
		level.tied_msg = getDvar( "scr_rescue_tied" );
	}
	
	if ( getDvar( "scr_rescue_free" ) == "" )
	{
		level.free_msg =  "You are ^2Free^7! Move to the Escape Zone!";
	}
	else
	{
		level.free_msg = getDvar( "scr_rescue_free" );
	}

	if ( getDvar( "scr_rescue_saved" ) == "" )
	{
		level.saved_msg =  "You were ^2Healed^7! Run to the Escape Zone!";
	}
	else
	{
		level.saved_msg = getDvar( "scr_rescue_saved" );
	}	
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
		
		id_b = RandomInt(level.xsd_b.size);
		while ( ObjValido(level.xsd_b[id_b]) == false )
		{
			id_b = RandomInt(level.xsd_b.size);
			logprint( "======================== Não Válido B!!! " + "\n");
		}
		exesd( level.xsd_b[id_b], 2 );		
	}
	else
	{
		exesd( level.xsd_a[RandomInt(level.xsd_a.size)], 1 );
		exesd( level.xsd_b[RandomInt(level.xsd_b.size)], 2 );
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