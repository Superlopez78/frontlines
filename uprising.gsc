#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	if(getdvar("mapname") == "mp_background")
		return;

	level.tem_koth = true;

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 5, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 0, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 10, 0, 30 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 1, 0, 10 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( level.gameType, 1, 0, 1 );
	
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
	//game["dialog"]["offense_obj"] = "capture_obj";
	game["dialog"]["defense_obj"] = "objs_defend";
}


onPrecacheGameType()
{
	precacheShader("compass_waypoint_target");
	precacheShader("waypoint_target");

	precacheShader("compass_waypoint_defend");	
	precacheShader("waypoint_defend");
	
	precacheModel( "prop_suitcase_bomb" );
	
	//sounds
	
	game["commander_killed"] = "mp_enemy_obj_captured";
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";		
	game["hack_alarm"] = "hack_alarm";
	game["nuke_alarm"] = "nuke_alarm";
}


onStartGameType()
{
	//garante que sempre tera todas as armas
	level.HajasWeap = 0;

	level.terminal_hacked = false;
	level.espera_rescue = randomIntRange ( 10,30 );

	// armas disponíveis
	level.AK = 0;
	level.rifle = 0;
	level.shotgun = 0;
	level.pistol = 0;
	level.faca = 0;

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
	
	level.zulu_point_smoke	= loadfx("smoke/signal_smoke_green");
		
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_UPRISING_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_UPRISING_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_UPRISING_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_UPRISING_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_UPRISING_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_UPRISING_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_UPRISING_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_UPRISING_DEFENDER_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	level.defender_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );

	// calcula distancia entre spawns pra saber se mapa é pequeno
	level.showdist = distance(level.attack_spawn,level.defender_spawn);
	//logprint("Dist = " + level.showdist );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "hq";
	allowed[1] = "sd";
	allowed[2] = "bombzone";
	allowed[3] = "sab";	
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	level.iconoffset = (0,0,32);
	
	// seta mensagens
	SetaMensagens();
	
	// seto todos o radios
    SetupRadios();	
    
	if ( level.tem_koth == false )
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}    
	
	// Define Zulu
	thread bombs();
	
    // seleciono o radio mais perto da posição e libero ele
	RadioAttack();
	
	GeraListaTerminais();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
	
	// toca alarme de fuga
	thread TocaAlarme();
}

GeraListaTerminais() // gera terminais ativos pros bots
{
	level.ActiveRadios = [];

	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		
		if ( level.radio_one != radio && ( isDefined(level.radio_two) && level.radio_two != radio ))
			level.ActiveRadios[level.ActiveRadios.size] = radio;
	}
	
	if ( level.ActiveRadios.size == 0 )
	{
		for ( i = 0; i < level.radios.size; i++ )
		{
			radio = level.radios[i];
			level.ActiveRadios[level.ActiveRadios.size] = radio;
		}	
	}
}

TocaAlarme()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	wait 10;
	maps\mp\_utility::playSoundOnPlayers( game["nuke_alarm"] );
}

// ==================================================================================================================
//   Terminal Control
// ==================================================================================================================

SetupRadios()
{
	maperrors = [];

	radios = getentarray( "hq_hardpoint", "targetname" );
	
	if ( radios.size < 2 )
	{
		maperrors[maperrors.size] = "There are not at least 2 entities with targetname \"radio\"";
	}
	else
	{
		trigs = getentarray("radiotrigger", "targetname");
		
		//logPrint("radio size = " + radios.size + "\n");
		for ( i = 0; i < radios.size; i++ )
		{
			errored = false;
			
			radio = radios[i];
			radio.trig = undefined;
			for ( j = 0; j < trigs.size; j++ )
			{
				if ( radio istouching( trigs[j] ) )
				{
					if ( isdefined( radio.trig ) )
					{
						maperrors[maperrors.size] = "Radio at " + radio.origin + " is touching more than one \"radiotrigger\" trigger";
						errored = true;
						break;
					}
					radio.trig = trigs[j];
					break;
				}
			}
			
			if ( !isdefined( radio.trig ) )
			{
				if ( !errored )
				{
					maperrors[maperrors.size] = "Radio at " + radio.origin + " is not inside any \"radiotrigger\" trigger";
					continue;
				}
				
				// possible fallback (has been tested)
				//radio.trig = spawn( "trigger_radius", radio.origin, 0, 128, 128 );
				//errored = false;
			}
			
			assert( !errored );
			
			radio.trigorigin = radio.trig.origin;
			
			visuals = [];
			visuals[0] = radio;
			
			otherVisuals = getEntArray( radio.target, "targetname" );
			for ( j = 0; j < otherVisuals.size; j++ )
			{
				visuals[visuals.size] = otherVisuals[j];
			}

			// caso tenha 8 radios, os 2 últimos serao excluídos
			if ( radios.size == 8 && i == ( radios.size - 1 ) )
			{
				// sem radio
			}
			else
			{
				radio.gameObject = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], radio.trig, visuals, (radio.origin - radio.trigorigin) + level.iconoffset );
				radio.gameObject maps\mp\gametypes\_gameobjects::disableObject();
				radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( false );
				radio.trig.useObj = radio.gameObject;
			}		
		}
	}	
	
	if (maperrors.size > 0)
	{
		level.tem_koth = false;
	
		logPrint("^1------------ Map Errors ------------\n");
		for(i = 0; i < maperrors.size; i++)
			logPrint(maperrors[i] + "\n");
		logPrint("^1------------------------------------\n");
		
		maps\mp\_utility::error("Map errors. See above");
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}
	
	level.radios = radios;
	
	return true;
}

RadioAttack()
{
	// define qual é o mais perto	
	level.radio_one = undefined;
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];

		//dist =  distance(radio.origin,level.attack_spawn);
		//logPrint("radio[" + i + "] Dist = " + dist + "\n");
		
		if ( i == 0 )
		{
			level.radio_one = radio;
		}
		if ( i != 0 )
		{
			if ( distance(level.radio_one.origin,level.attack_spawn) > distance(radio.origin,level.attack_spawn) )
			{
				level.radio_one = radio;
			}
		}
	}
	//logPrint("radio one[" + level.radio_one.origin + "] Dist = " + distance(level.radio_one.origin,level.attack_spawn) + "\n");
	
	// testa se custom map com muitos HQs para tirar o mais perto do escolhido
	if ( level.radios.size > 5 )
	{
		for ( i = 0; i < level.radios.size; i++ )
		{
			radio = level.radios[i];

			if ( i == 0 )
			{
				level.radio_two = radio;
			}
			
			if ( level.radio_one != radio )
			{
				if ( i != 0 )
				{
					if ( distance(level.radio_two.origin,level.radio_one.origin) > distance(radio.origin,level.radio_one.origin) )
					{
						level.radio_two = radio;
					}
				}
			}		
		}	
	}
	
	// seta os flags pra cada um deles fazendo eles ficarem visíveis
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		if ( level.radio_one == radio )
		{
			// mantem invisível o mais perto
			/*
			radio.gameObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
			radio.gameObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" );
			radio.gameObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" );		
			*/
		}
		else 
		{
			if ( level.radios.size > 5 )
			{
				if ( level.radio_two != radio )
				{
					if ( isDefined(radio.gameObject) )
					{
						radio.gameObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
						radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
						radio.gameObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
						radio.gameObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );		
					}
				}
			}
			else
			{
				radio.gameObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
				radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
				if ( distance(level.radio_one.origin,radio.origin) > level.uprising_limit )
				{
					radio.gameObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
					radio.gameObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
				}
			}
		}
	}	
}

TerminalViolated( origin ) //origin, zone
{
	wait 5;
	
	thread maps\mp\gametypes\_globallogic::HajasPlay3D ( game["hack_alarm"], origin, 7.0 );
	wait 2;
	maps\mp\gametypes\_globallogic::leaderDialog( "move_to_new",  game["defenders"] );
}

TerminalLostIntel()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == game["defenders"] )
		{
			player iPrintLn( level.uprising_violated );
		}
	}
	maps\mp\gametypes\_globallogic::leaderDialog( "obj_lost",  game["defenders"] );
	wait 2;
	maps\mp\gametypes\_globallogic::leaderDialog( "attack",  game["defenders"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "boost",  game["defenders"] );
}

// ==================================================================================================================
//   Player
// ==================================================================================================================

onSpawnPlayer()
{
	self.computing = false;

	if(self.pers["team"] == game["attackers"])
		spawnPointName = "mp_sd_spawn_attacker";
	else
		spawnPointName = "mp_sd_spawn_defender";

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
	
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints_player( self );

	if(self.pers["team"] == game["attackers"])
	{
		thread PlayerHacker();
		thread PrisonerEscaped();
	}
}

CalculaArmas()
{
	weapon = EscolheArma();
	
	if ( weapon != "none" )
	{
		self giveWeapon( weapon );

		// se for desert, é só na faca!
		if ( weapon == "deserteagle_mp" )
			self maps\mp\gametypes\_class::setWeaponAmmoOverall( weapon, 0 );
		else
			self giveMaxAmmo( weapon );
		
		self switchToWeapon( weapon );	
	}
}

EscolheArma()
{
	arma_sorte = 0;
	weapon = "none";

	if ( level.players.size <= 10 )
	{
		arma_sorte = randomInt(5);
	}
	else if ( level.players.size > 10 && level.players.size <= 20 )
	{
		arma_sorte = randomIntRange(10,16);
	}
	else if ( level.players.size > 20 && level.players.size <= 30 )
	{
		arma_sorte = randomIntRange(20,26);
	}
	else if ( level.players.size > 30 && level.players.size <= 40 )
	{
		arma_sorte = randomIntRange(30,36);
	}
	else if ( level.players.size > 40 && level.players.size <= 50 )
	{
		arma_sorte = randomIntRange(40,46);
	}
	else if ( level.players.size > 50 )
	{
		arma_sorte = randomIntRange(50,56);
	}
	
	/*
	level.AK = 0;
	level.rifle = 0;
	level.shotgun = 0;
	level.pistol = 0;
	level.faca = 0;
	*/
	
	switch( arma_sorte )
	{
		// ate 10 players
		case 4:
			if ( level.rifle == 0 )
			{
				weapon = "m14_mp";
				level.rifle++;
			}
			break;
		case 1:
			if ( level.shotgun == 0 )
			{
				weapon = "winchester1200_mp";
				level.shotgun++;
			}		
			break;			
		case 2:
			if ( level.pistol == 0 )
			{
				weapon = "beretta_mp";
				level.pistol++;
			}		
			break;
		case 3:
			if ( level.faca == 2 )
			{
				weapon = "deserteagle_mp";
				level.faca++;
			}		
			break;
			
		// de 11 ate 20
		case 15:
			if ( level.rifle == 0 )
			{
				weapon = "m14_mp";
				level.rifle++;
			}
			break;
		case 11:
			if ( level.shotgun == 0 )
			{
				weapon = "winchester1200_mp";
				level.shotgun++;
			}		
			break;			
		case 12:
			if ( level.pistol == 0 )
			{
				weapon = "beretta_mp";
				level.pistol++;
			}		
			break;
		case 13:
			if ( level.faca < 16 )
			{
				weapon = "deserteagle_mp";
				level.faca++;
			}		
			break;		
		case 14:
			if ( level.AK == 0 )
			{
				weapon = "ak47_mp";
				level.AK++;
			}		
			break;		
		
		// de 21 ate 30
		
		case 25:
			if ( level.rifle == 0 )
			{
				weapon = "m14_mp";
				level.rifle++;
			}
			break;
		case 21:
			if ( level.shotgun == 0 )
			{
				weapon = "winchester1200_mp";
				level.shotgun++;
			}		
			break;			
		case 22:
			if ( level.pistol < 2 )
			{
				weapon = "beretta_mp";
				level.pistol++;
			}		
			break;
		case 23:
			if ( level.faca < 25 )
			{
				weapon = "deserteagle_mp";
				level.faca++;
			}		
			break;		
		case 24:
			if ( level.AK == 0 )
			{
				weapon = "ak47_mp";
				level.AK++;
			}		
			break;		
		
		// de 31 ate 40	
		
		case 35:
			if ( level.rifle < 2 )
			{
				weapon = "m14_mp";
				level.rifle++;
			}
			break;
		case 31:
			if ( level.shotgun < 2 )
			{
				weapon = "winchester1200_mp";
				level.shotgun++;
			}		
			break;			
		case 32:
			if ( level.pistol < 3 )
			{
				weapon = "beretta_mp";
				level.pistol++;
			}		
			break;
		case 33:
			if ( level.faca < 22 )
			{
				weapon = "deserteagle_mp";
				level.faca++;
			}		
			break;		
		case 34:
			if ( level.AK < 2 )
			{
				weapon = "ak47_mp";
				level.AK++;
			}		
			break;		
		
		
		// de 41 ate 50
		
		case 45:
			if ( level.rifle < 3 )
			{
				weapon = "m14_mp";
				level.rifle++;
			}
			break;
		case 41:
			if ( level.shotgun < 3 )
			{
				weapon = "winchester1200_mp";
				level.shotgun++;
			}		
			break;			
		case 42:
			if ( level.pistol < 6 )
			{
				weapon = "beretta_mp";
				level.pistol++;
			}		
			break;
		case 43:
			if ( level.faca < 30 )
			{
				weapon = "deserteagle_mp";
				level.faca++;
			}		
			break;		
		case 44:
			if ( level.AK < 3 )
			{
				weapon = "ak47_mp";
				level.AK++;
			}		
			break;			
		
		// maior q 50
		
		case 55:
			if ( level.rifle < 3 )
			{
				weapon = "m14_mp";
				level.rifle++;
			}
			break;
		case 51:
			if ( level.shotgun < 3 )
			{
				weapon = "winchester1200_mp";
				level.shotgun++;
			}		
			break;			
		case 52:
			if ( level.pistol < 8 )
			{
				weapon = "beretta_mp";
				level.pistol++;
			}		
			break;
		case 53:
			if ( level.faca < 36 )
			{
				weapon = "deserteagle_mp";
				level.faca++;
			}		
			break;		
		case 54:
			if ( level.AK < 4 )
			{
				weapon = "ak47_mp";
				level.AK++;
			}		
			break;			
		
		default:
			weapon = "none";
			break;
	}
	
	return weapon;
	
	// armas
	// ak47_mp
	// m14_mp
	// winchester1200_mp
	// beretta_mp
	// deserteagle_mp (vazia, só pra faca!)

	// definições
	
	// ate 10 players
	// 0 AK
	// 1 rifle
	// 1 shotgun
	// 1 pistol
	// 2 facas

	// de 11 ate 20
	// 1 AK
	// 1 rifle
	// 1 shotgun
	// 1 pistols
	// 6 facas 
	
	// de 21 ate 30
	// 1 AK
	// 1 rifle
	// 1 shotgun
	// 2 pistols
	// 10 facas 

	// de 31 ate 40
	// 2 AK
	// 2 rifle
	// 2 shotgun
	// 2 pistols
	// 12 facas 

	// de 41 ate 50
	// 3 AK
	// 3 rifle
	// 3 shotgun
	// 3 pistols
	// 13 facas 

	// maior q 51
	// 4 AK
	// 3 rifle
	// 3 shotgun
	// 6 pistols
	// 16 facas 
}

PlayerHacker()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
	
	hacked = false;
	
	while(1)
	{
		if ( TestaHacking( self ) == true )
		{
			hacked = Hacking();
			
			if ( level.gameEnded == true )
				return;
			
			if ( hacked == true && level.terminal_hacked == false )
			{
				// diz que hackeou
				level.terminal_hacked = true;
				
				maps\mp\gametypes\_globallogic::givePlayerScore( "plant", self );
				self thread [[level.onXPEvent]]( "plant" );					
				
				for ( i = 0; i < level.players.size; i++ )
				{
					player = level.players[i];
					if ( player.pers["team"] == game["attackers"] )
					{
						player iPrintLn( level.uprising_zulu );
					}
				}
				wait 1;
				thread TerminalLostIntel(); // avisa a defesa que conseguiram roubar os dados
				maps\mp\gametypes\_globallogic::leaderDialog( "helicopter_inbound", game["attackers"] );
				wait 1;
				maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
				thread maps\mp\gametypes\_hardpoints::RescueTeam( game["attackers"], self );
				return;
			}
			else if ( level.terminal_hacked == true )
			{
				// se já chamou ajuda, aborta teste pra todos
				return;
			}
		}	
		wait 1;
	} 
}

Hacking()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	if ( level.HelpMode == 1 && isDefined(self.lastStand) )		
		return false;	
		
	hack_msg = "";
	
	hack_msg = level.uprising_support;
	if ( TestaHacking( self ) == false )
		return false;
	thread TerminalViolated( self.origin ); //origin, zone
	
	// pega pra saber nossa arma
	myweapon = self getCurrentWeapon();
	
	// dropa arma
	self disableWeapons();
	
	if(isDefined(self.bIsBot) && self.bIsBot)
	{
		//nada
	}
	else	
		self thread maps\mp\gametypes\_weapons::MonitoraWeapon();	
	
	self.computing = true;
	
	// cria texto
	self.link_msg = newClientHudElem(self);
	self.link_msg.x = 320;
	self.link_msg.alignX = "center";
 	self.link_msg.y = 454;
	self.link_msg.alignY = "bottom";
	self.link_msg.sort = -3;
	self.link_msg setPulseFX( 100, 10000, 1000 );
	self.link_msg.alpha = 1;
	self.link_msg.fontScale = 1.4;
	self.link_msg.hideWhenInMenu = true;
	self.link_msg.archived = true;		
	self.link_msg setText( hack_msg );	
	
	// Background HUD Element (First, because of Z-Ordering)
	self.linkingBG = newClientHudElem(self);
	self.linkingBG.horzAlign = "center";
	self.linkingBG.vertAlign = "bottom";
	self.linkingBG.x = -52;
	self.linkingBG.y = -22;
	self.linkingBG.archived = true;
	self.linkingBG.alpha = 0.75; // Transparent
	self.linkingBG.color = (0.0, 0.0, 0.0); // Black
	self.linkingBG setShader("black", 104, 14); // Set the Shader
	   
	// Initialize the HUD Element
	self.linkingInfo = newClientHudElem(self);
	self.linkingInfo.horzAlign = "center";
	self.linkingInfo.vertAlign = "bottom";
	self.linkingInfo.x = -50;
	self.linkingInfo.y = -20; 
	self.linkingInfo.archived = true;
	self.linkingInfo.alpha = 0.75; // Transparent
	self.linkingInfo.color = (1.0, 1.0, 1.0); // White
	self.linkingInfo setShader("white", 1, 10); // Set the Shader
	
	temp = 1;

	tempo_espera = randomIntRange(8, 15);
	tempo_espera = 1 + tempo_espera;
	
	if ( self.pers["rank"] >= 20 && self.pers["rank"] < 40 )
		tempo_espera--;
	if ( self.pers["rank"] >= 40 && self.pers["rank"] < 60 )
		tempo_espera--;
	if ( self.pers["rank"] >= 60 && self.pers["rank"] < 100 )
		tempo_espera--;
	if ( self.pers["rank"] >= 100 && self.pers["rank"] < 150 )
		tempo_espera--;
	if ( self.pers["rank"] >= 150 )
		tempo_espera--;	
	
	bar_parte = int ( 100 / tempo_espera + 1 );
	bar_inc = 0;

	self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
	
	thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_1" );
	
	wait 1;
	
	while ( temp <= tempo_espera )
	{
		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		// atualiza barra
		bar_inc = temp * bar_parte;
		
		// garante q barra não vai estourar
		if ( bar_inc > 100 )
		{
			bar_inc = 100;
		}
		self.linkingInfo setShader("white", bar_inc, 10);	
		
		if ( TestaHacking( self ) == false )
		{
			// se distanciou dos controles
			self iprintln ( level.uprising_abort );
			
			self.linkingBG destroy();
			self.linkingInfo destroy();
			self enableWeapons();
			self.computing = false;
			thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
			
			if ( myweapon == "deserteagle_mp" )
			{
				self giveWeapon( myweapon );
				self maps\mp\gametypes\_class::setWeaponAmmoOverall( myweapon, 0 );			
			}
				
			return false;		
		}
		
		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		
		if ( level.HelpMode == 1 && isDefined(self.lastStand) )
		{
			// ferido
			self iprintln ( level.uprising_abort );
			
			self.linkingBG destroy();
			self.linkingInfo destroy();
			self enableWeapons();
			self.computing = false;
			thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
			return false;			
		}		
		
		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		
		if(isDefined(self.bIsBot) && self.bIsBot)
		{
		}
		else
		{		
			uav_arma = self getCurrentWeapon();
			if ( uav_arma != "none" )
			{
				// se distanciou dos controles
				self iprintln ( level.uprising_weapon );
				
				self.linkingBG destroy();
				self.linkingInfo destroy();
				self enableWeapons();
				self.computing = false;
				thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
				
				if ( myweapon == "deserteagle_mp" )
				{
					self giveWeapon( myweapon );
					self maps\mp\gametypes\_class::setWeaponAmmoOverall( myweapon, 0 );			
				}
							
				return false;		
			}
		}
		
		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		
		if ( level.gameEnded == true )
		{
			self.linkingBG destroy();
			self.linkingInfo destroy();
			self enableWeapons();
			self.computing = false;
			return false;
		}		
		temp++;
		wait 1;
	}
	
	self.linkingBG destroy();
	self.linkingInfo destroy();
	self enableWeapons();
	self.computing = false;
	thread playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	
	if ( myweapon == "deserteagle_mp" )
	{
		self giveWeapon( myweapon );
		self maps\mp\gametypes\_class::setWeaponAmmoOverall( myweapon, 0 );			
	}
				
	return true;	
}

TestaHacking( player )
{
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		if ( level.terminal_hacked == false )
		{
			if ( distance(player.origin,radio.origin) < 50 )
			{
				if ( distance(level.radio_one.origin,radio.origin) < level.uprising_limit )
				{
					self iPrintLn( level.uprising_damaged );
					thread maps\mp\gametypes\_globallogic::HajasPlay3D ( "som_uav_2" , player.origin, 1.0 );
					wait 5;
				}
				else
				{
					if ( level.radios.size > 5 )
					{
						// só áceita se NÃO é o radio deletado
						if ( level.radio_two != radio )
							return true;
					}
					else
					{
						return true;
					}
				}
			}
		}
		else
		{
			if ( distance(player.origin,radio.origin) < 50 )
			{
				self iPrintLn( level.uprising_zulu );
				thread maps\mp\gametypes\_globallogic::HajasPlay3D ( "som_uav_2" , player.origin, 1.0 );
				wait 5;
			}			
		}
	}	
	// se passou por tudo e não retornou, diz que não achou nada, e retorna falso
	return false;
}

// controla se ele chegou ao Zulu e termina o round (iniciado em PrisonerFree assim q ele é salvo)
PrisonerEscaped()
{
	self.Safe = false;
	
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	//iprintln( "^4PrisonerEscaped" );	

	while(1)
	{
		if ( level.ZuluRevealed == true )
		{
			if ( distance(self.origin,level.pos_zulu) < 100 )
			{
					self.Safe = true;
					maps\mp\gametypes\_globallogic::givePlayerScore( "safe", self );
					
					// termina o round
					level.overrideTeamScore = true;
					level.displayRoundEndText = true;

					iPrintLn( level.uprising_escaped );
					makeDvarServerInfo( "ui_text_endreason", level.uprising_escaped );
					setDvar( "ui_text_endreason", level.uprising_escaped );

					sd_endGame( game["attackers"], level.uprising_escaped );		
					return;		
			} 
		}
		wait 1;
	}
}



// ==================================================================================================================
//   Hacker
// ==================================================================================================================


onPlayerDisconnect()
{
	//self vipDead();
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	//self vipDead();
}

// ==================================================================================================================
//   Game Over
// ==================================================================================================================

sd_endGame( winningTeam, endReasonText )
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	
	
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();
	
	if ( isdefined( winningTeam ) && (winningTeam == "allies" || winningTeam == "axis") )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );	
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}


onDeadEvent( team )
{
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

onOneLeftEvent( team )
{
	warnLastPlayer( team );
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

// ==================================================================================================================
//   Zulu Control
// ==================================================================================================================

bombs()
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
	
	level.Type = 0;

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
		deleto = 1;
		if ( isDefined ( clips[i].script_gameobjectname ) )
		{
			for ( k = 0; k < level.radios.size; k++ )
			{
				if( distance( clips[i].origin , level.radios[k].origin ) <= 100 )
					deleto = 0;
			}
			if ( deleto == 1 )
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
	allowed[0] = "hq";
	allowed[1] = "sd";
	allowed[2] = "bombzone";

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

	while ( level.terminal_hacked == false )
		wait 1;

	wait level.espera_rescue;
	
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
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == game["attackers"] )
		{
			player iPrintLn( level.uprising_zulu );
		}
	}
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
}

// ==================================================================================================================
//   MSG Control
// ==================================================================================================================


SetaMensagens()
{
	// limit			
	if ( getDvar( "scr_uprising_limit" ) == "" )
	{
		level.uprising_limit = 1500;
	}
	else
	{
		level.uprising_limit = getDvarInt( "scr_uprising_limit" );
	}
	
	if ( level.showdist < 3300 )
		level.uprising_limit = 1300;
	
	// damaged			
	if ( getDvar( "scr_uprising_damaged" ) == "" )
	{
		level.uprising_damaged = "^1Warning ^0: ^7This Terminal is Damaged! Find another one!";
	}
	else
	{
		level.uprising_damaged = getDvar( "scr_uprising_damaged" );
	}		

	// Support			
	if ( getDvar( "scr_uprising_support" ) == "" )
	{
		level.uprising_support = "Calling Support...";
	}
	else
	{
		level.uprising_support = getDvar( "scr_uprising_support" );
	}	
	
	// Rescue Team arrived			
	if ( getDvar( "scr_uprising_rescue" ) == "" )
	{
		level.uprising_rescue = "The ^3Rescue Team ^7has Arrived!";
	}
	else
	{
		level.uprising_rescue = getDvar( "scr_uprising_rescue" );
	}

	// weapon			
	if ( getDvar( "scr_uprising_weapon" ) == "" )
	{
		level.uprising_weapon = "^1Warning ^0: ^7Put down your weapon to use the Computer!";
	}
	else
	{
		level.uprising_weapon = getDvar( "scr_uprising_weapon" );
	}
	
	// abort			
	if ( getDvar( "scr_uprising_abort" ) == "" )
	{
		level.uprising_abort = "^1Warning ^0: ^7You didn't finished your task!";
	}
	else
	{
		level.uprising_abort = getDvar( "scr_uprising_abort" );
	}	

	// violated
	if ( getDvar( "scr_uprising_violated" ) == "" )
	{
		level.uprising_violated = "^1Warning ^0: ^7Our Terminal was Violated! Don't let them Escape alive!";
	}
	else
	{
		level.uprising_violated = getDvar( "scr_uprising_violated" );
	}

	// escaped
	if ( getDvar( "scr_uprising_escaped" ) == "" )
	{
		level.uprising_escaped = "A ^3Prisoner ^7has Escaped!";
	}
	else
	{
		level.uprising_escaped = getDvar( "scr_uprising_escaped" );
	}
	
	// zulu
	if ( getDvar( "scr_uprising_zulu" ) == "" )
	{
		level.uprising_zulu = "^1Warning ^0: ^7Wait the support then move to the Extraction Point!";
	}
	else
	{
		level.uprising_zulu = getDvar( "scr_uprising_zulu" );
	}	
}
