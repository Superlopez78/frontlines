#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
main()
{
	if(getdvar("mapname") == "mp_background")
		return;
		
	level.LiveVIP = false;
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
	maps\mp\gametypes\_globallogic::registerNextVIPDvar( level.gameType, 2, 0, 2 );
	maps\mp\gametypes\_globallogic::registerVIPNameDvar( "scr_hack_name", 1, 0, 1 );
	
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
	game["dialog"]["defense_obj"] = "objs_defend";
}


onPrecacheGameType()
{
	precacheShader( "specialty_gpsjammer" );
	precacheStatusIcon( "specialty_gpsjammer" );	
	
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );
	precacheShader( "waypoint_escort" );
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );	
	
	//sounds
	
	game["commander_killed"] = "mp_enemy_obj_captured";
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";		
	game["hack_alarm"] = "hack_alarm";
}


onStartGameType()
{
	level.terminal_hacked = false;
	level.terminal_violated = false;
	level.terminal_uploaded = false;

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
		
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_HACK_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_HACK_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_HACK_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_HACK_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_HACK_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_HACK_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_HACK_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_HACK_DEFENDER" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	level.defender_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );
	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	

	// calcula distancia entre spawns pra saber se mapa é pequeno
	level.showdist = distance(level.attack_spawn,level.defender_spawn);
	//logprint("Dist = " + level.showdist );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "hq";
	
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

    // seleciono o radio mais perto da posição e libero ele
	RadioAttack();
	
	GeraListaTerminais();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
}

GeraListaTerminais() // gera terminais ativos pros bots
{
	level.ActiveRadios = [];

	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		
		if ( level.radio_one != radio && ( distance(level.radio_one.origin,radio.origin) >= level.hack_limit ))
			level.ActiveRadios[level.ActiveRadios.size] = radio;
	}
}

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
			
			radio.gameObject = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], radio.trig, visuals, (radio.origin - radio.trigorigin) + level.iconoffset );
			radio.gameObject maps\mp\gametypes\_gameobjects::disableObject();
			radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( false );
			radio.trig.useObj = radio.gameObject;
		}
	}
	
	if (maperrors.size > 0)
	{
		logPrint("^1------------ Map Errors ------------\n");
		for(i = 0; i < maperrors.size; i++)
			logPrint(maperrors[i] + "\n");
		logPrint("^1------------------------------------\n");
		
		level.tem_koth = false;
		
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
			level.radio_one = radio;
			
		if ( i != 0 )
		{
			if ( distance(level.radio_one.origin,level.attack_spawn) > distance(radio.origin,level.attack_spawn) )
				level.radio_one = radio;
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
				level.radio_two = radio;
			
			if ( level.radio_one != radio )
			{
				if ( i != 0 )
				{
					if ( distance(level.radio_two.origin,level.radio_one.origin) > distance(radio.origin,level.radio_one.origin) )
						level.radio_two = radio;
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
			radio.gameObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
			radio.gameObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" );
			radio.gameObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" );		
		}
		else 
		{
			if ( level.radios.size > 5 )
			{
				if ( level.radio_two != radio )
				{
					radio.gameObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
					radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
					radio.gameObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
					radio.gameObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );		
				}
			}
			else
			{
				radio.gameObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
				radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
				if ( distance(level.radio_one.origin,radio.origin) > level.hack_limit )
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
	wait 4.5;
	thread maps\mp\gametypes\_globallogic::HajasPlay3D ( game["hack_alarm"], origin, 7.0 );
	wait 6.5;
	thread maps\mp\gametypes\_globallogic::HajasPlay3D ( game["hack_alarm"], origin, 7.0 );
}

TerminalLostIntel()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == game["defenders"] )
		{
			player iPrintLn( level.hack_violated );
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
	
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
	{
		if ( self.pers["team"] == game["defenders"] )
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

SpawnVIP()
{
	self.isCommander = true;
	
	if ( level.SidesMSG == 1 )
		self iPrintLnbold( level.hack_you );
	
	self thread createVipIcon();

	// diz q o mapa já tem um vip/commander vivo
	level.LiveVIP = true;	
	
	// seta nome do Commander para mostrar na tela
	level.ShowName = self.name;	

	// safe?
	thread PlayerHacker();

	// icone defend!
	thread CriaTriggers( self );		
}

CriaTriggers( player )
{
	while ( !self.hasSpawned )
		wait ( 0.01 );

	while ( self.sessionstate != "playing" )
		wait ( 0.01 );

	wait ( 0.1 );
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
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_escort" );
}

SpawnSoldado()
{
	self.isCommander = false;

	if ( self.pers["team"] == game["attackers"])
	{
		if ( level.VIPName == 1 )
			thread ShowVipName();
	}
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
						player iPrintLn( level.hack_intel );
					}
				}
				wait 1;
				maps\mp\gametypes\_globallogic::leaderDialog( "obj_taken",  game["attackers"] );
				thread TerminalLostIntel(); // avisa a defesa que conseguiram roubar os dados
				wait 2;
				maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
			}
			else if ( hacked == true && level.terminal_hacked == true )
			{
				// diz que terminou o upload
				level.terminal_uploaded = true;

				wait 1;
				level.endtext = level.hack_stolen;
				
				maps\mp\gametypes\_globallogic::givePlayerScore( "plant", self );
				self thread [[level.onXPEvent]]( "plant" );						
					
				setGameEndTime( 0 );
					
				// termina o round
				level.overrideTeamScore = true;
				level.displayRoundEndText = true;
					
				sd_endGame( game["attackers"], level.endtext );	
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
	
	if ( level.terminal_hacked == true )
	{
		hack_msg = level.hack_uploading;
		if ( distance(self.origin,level.radio_one.origin) > 50 )
			return false;		
	}
	else
	{
		hack_msg = level.hack_hacking;
		if ( TestaHacking( self ) == false )
			return false;
		thread TerminalViolated( self.origin ); //origin, zone
	}
	
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

	tempo_espera = randomIntRange(10, 20);
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
			self iprintln ( level.hack_abort );
			
			self.linkingBG destroy();
			self.linkingInfo destroy();
			self enableWeapons();
			self.computing = false;
			thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
			return false;		
		}
		
		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		
		if ( level.HelpMode == 1 && isDefined(self.lastStand) )
		{
			// ferido
			self iprintln ( level.hack_abort );
			
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
				self iprintln ( level.hack_weapon );
				
				self.linkingBG destroy();
				self.linkingInfo destroy();
				self enableWeapons();
				self.computing = false;
				thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
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
	return true;	
}

TestaHacking( player )
{
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		
		// é o radio de ataque, usado para upload
		if ( level.radio_one == radio )
		{
			if ( level.terminal_hacked == true )
			{
				if ( distance(player.origin,level.radio_one.origin) < 50 )
				{
					return true;
				}
			}
			else
			{
				if ( distance(player.origin,level.radio_one.origin) < 50 )
				{
					self iPrintLn( level.hack_getfirst );
					thread maps\mp\gametypes\_globallogic::HajasPlay3D ( "som_uav_2" , player.origin, 1.0 );
					wait 5;
				}
			}
		}
		else
		{
			if ( level.terminal_hacked == false )
			{
				if ( distance(player.origin,radio.origin) < 50 )
				{
					if ( distance(level.radio_one.origin,radio.origin) < level.hack_limit )
					{
						self iPrintLn( level.hack_damaged );
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
					self iPrintLn( level.hack_retrieve );
					thread maps\mp\gametypes\_globallogic::HajasPlay3D ( "som_uav_2" , player.origin, 1.0 );
					wait 5;
				}			
			}
		}
	}	
	// se passou por tudo e não retornou, diz que não achou nada, e retorna falso
	return false;
}


// ==================================================================================================================
//   Hacker
// ==================================================================================================================

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
		msg_info = "^9" + level.ShowName + "^7 " + level.hack_is;
		self iPrintLn( msg_info );
	}
}

createVipIcon()
{
	self.carryIcon = createIcon( "specialty_gpsjammer", 35, 35 );
	
	self.carryIcon setPoint( "CENTER", "CENTER", 220, 160 );
	self.carryIcon.alpha = 0.75;
	
	// carrega icon no placar
	self.statusicon = "specialty_gpsjammer";
}

onPlayerDisconnect()
{
	self vipDead();
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self vipDead();
}

vipDead()
{
	if ( isDefined( self.isCommander ) && self.isCommander == true )
	{
		maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["attackers"] );
		maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], game["defenders"] );
		
		game["VIPname"] = "";
		
		level.endtext = level.hack_dead_score;

		// deixa de ser vip/commander
		self.isCommander = false;

		// diz q nao tem mais vip/Commander vivo
		level.LiveVIP = false;

		level notify("vip_is_dead");
		setGameEndTime( 0 );
		
		// termina o round
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		
		iPrintLn( level.hack_dead );
		makeDvarServerInfo( "ui_text_endreason", level.hack_dead );
		setDvar( "ui_text_endreason", level.hack_dead );

		sd_endGame( game["defenders"], level.endtext );		
	}
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
	
	maps\mp\gametypes\_globallogic::proxVIP( game["attackers"] );		
	
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
	
	// hajas duel
	if ( level.HajasDuel > 0 )
	{
		self maps\mp\gametypes\_globallogic::HajasDuel();
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

SetaMensagens()
{
	// limit			
	if ( getDvar( "scr_hack_limit" ) == "" )
	{
		level.hack_limit = 2000;
	}
	else
	{
		level.hack_limit = getDvarInt( "scr_hack_limit" );
	}
	
	if ( level.showdist < 3300 )
		level.hack_limit = 1300;
	
	// damaged			
	if ( getDvar( "scr_hack_damaged" ) == "" )
	{
		level.hack_damaged = "^1Warning ^0: ^7This Terminal is Damaged! Find another one!";
	}
	else
	{
		level.hack_damaged = getDvar( "scr_hack_damaged" );
	}		

	// hacking			
	if ( getDvar( "scr_hack_hacking" ) == "" )
	{
		level.hack_hacking = "Hacking...";
	}
	else
	{
		level.hack_hacking = getDvar( "scr_hack_hacking" );
	}	
	
	// uploading			
	if ( getDvar( "scr_hack_uploading" ) == "" )
	{
		level.hack_uploading = "Uploading...";
	}
	else
	{
		level.hack_uploading = getDvar( "scr_hack_uploading" );
	}

	// intel
	if ( getDvar( "scr_hack_intel" ) == "" )
	{
		level.hack_intel = "^1Warning ^0: ^7We've got the Enemy's Data!";
	}
	else
	{
		level.hack_intel = getDvar( "scr_hack_intel" );
	}

	// weapon			
	if ( getDvar( "scr_hack_weapon" ) == "" )
	{
		level.hack_weapon = "^1Warning ^0: ^7Put down your weapon to use the Computer!";
	}
	else
	{
		level.hack_weapon = getDvar( "scr_hack_weapon" );
	}
	
	// abort			
	if ( getDvar( "scr_hack_abort" ) == "" )
	{
		level.hack_abort = "^1Warning ^0: ^7You didn't finished your task!";
	}
	else
	{
		level.hack_abort = getDvar( "scr_hack_abort" );
	}	

	// hack_violated
	if ( getDvar( "scr_hack_violated" ) == "" )
	{
		level.hack_violated = "^1Warning ^0: ^7Our Terminal was Hacked! Don't let them Escape alive!";
	}
	else
	{
		level.hack_violated = getDvar( "scr_hack_violated" );
	}
	
	// hack_getfirst			
	if ( getDvar( "scr_hack_getfirst" ) == "" )
	{
		level.hack_getfirst = "^1Warning ^0: ^7You need to Hack the Enemy's Data first!";
	}
	else
	{
		level.hack_getfirst = getDvar( "scr_hack_getfirst" );
	}
	
	// hack_retrieve			
	if ( getDvar( "scr_hack_retrieve" ) == "" )
	{
		level.hack_retrieve = "^1Warning ^0: ^7Comeback and upload the stolen data to our Intel!";
	}
	else
	{
		level.hack_retrieve = getDvar( "scr_hack_retrieve" );
	}		
	
	// --------------------------------------
	
	// hack_you			
	if ( getDvar( "scr_hack_you" ) == "" )
	{
		level.hack_you = "^7You are the ^9Hacker^7!";
	}
	else
	{
		level.hack_you = getDvar( "scr_hack_you" );
	}
	
	// hack_stolen			
	if ( getDvar( "scr_hack_stolen" ) == "" )
	{
		level.hack_stolen = "^7The ^3Data ^7was stolen!";
	}
	else
	{
		level.hack_stolen = getDvar( "scr_hack_stolen" );
	}		
	
	// hack_dead_score			
	if ( getDvar( "scr_hack_dead_score" ) == "" )
	{
		level.hack_dead_score = "^7The ^3Hacker ^7is Dead!";
	}
	else
	{
		level.hack_dead_score = getDvar( "scr_hack_dead_score" );
	}		
	
	// hack_dead			
	if ( getDvar( "scr_hack_dead" ) == "" )
	{
		level.hack_dead = "^7The ^9Hacker ^7is Dead!";
	}
	else
	{
		level.hack_dead = getDvar( "scr_hack_dead" );
	}
	
	// hack_is			
	if ( getDvar( "scr_hack_is" ) == "" )
	{
		level.hack_is = "is the ^9Hacker^7!";
	}
	else
	{
		level.hack_is = getDvar( "scr_hack_is" );
	}		
}