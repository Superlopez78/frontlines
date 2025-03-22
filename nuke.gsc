#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar 
registerNukeGTDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.NukegtDvar = dvarString;
	level.NukegtMin = minValue;
	level.NukegtMax = maxValue;
	level.Nukegt = getDvarInt( level.NukegtDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	registerNukeGTDvar( "scr_nuke_gt", 0, 0, 1 );

	if ( level.Nukegt == 0 )
		init();
	else if ( level.Nukegt == 1 )
	{
		maps\mp\gametypes\countdown::init();
		return;
	}
}

init()
{
	level.LiveVIP = false;
	level.Salvador = undefined;
	level.tem_koth = true;
	
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 5, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 0, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 10, 0, 30 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 0, 0, 1000 );
	maps\mp\gametypes\_globallogic::registerTypeDvar( level.gameType, 0, 0, 3 );
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( level.gameType, 1, 0, 1 );
	maps\mp\gametypes\_globallogic::registerNextVIPDvar( level.gameType, 2, 0, 2 );
	maps\mp\gametypes\_globallogic::registerVIPNameDvar( "scr_nuke_name", 1, 0, 1 );
	
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
	game["dialog"]["offense_obj"] = "sabotage";
	game["dialog"]["defense_obj"] = "obj_defend";
}


onPrecacheGameType()
{
	game["nuke_01"] = "nuke";
	game["nuke_02"] = "nuke_impact";
	game["nuke_incoming"] = "nuke_incoming";
	game["nuke_alarm"] = "nuke_alarm";

	game["nuke_03"] = "nuke_longe";
	game["nuke_04"] = "nuke_impact_longe";
	game["nuke_passed"] = "nuke_passed";

	precacheShader( "specialty_detectexplosive" );
	precacheStatusIcon( "specialty_detectexplosive" );	
	
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );

	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
	precacheShader( "waypoint_escort" );	
	
	precacheModel( "prop_suitcase_bomb" );	
	
	//sounds
	
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";	
}


onStartGameType()
{
	level.nuke_revealed = false;
	level.nuke_disarmed = false;
	level.nuke_exploded = false;
	level.nuke_started = false;

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
		
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_NUKE_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_NUKE_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_NUKE_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_NUKE_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_NUKE_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_NUKE_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_NUKE_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_NUKE_DEFENDER" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
	
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "sab";
	allowed[3] = "hq";
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	level.iconoffset = (0,0,32);
	
	// pega local da bomba q tera o controle perto
	Bombs();
	
	// com a posição, deleto objs de outros gametypes e libero os do hq
	DeleteSabBombs();
	
	// seto todos o radios
    SetupRadios();
    
	if ( level.tem_koth == false )
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}       

    // seleciono o radio mais perto da posição e libero ele
	ControlRoom();

    // Nuke FX
    level.nuke			= loadfx("explosions/nuke_explosion");
    level.nuke_flash	= loadfx("explosions/nuke_flash");
    
	// calcula tempo pro Nuke
	tempo_max = getDvarInt( level.timeLimitDvar );
	tempo_max = ( (tempo_max - 1) * 60 );
	tempo_min = tempo_max - 30;
	tempo_nuke = randomintrange ( tempo_min, tempo_max );
	//level.chega_nuke = gettime() + tempo_reinf * 1000;
	
	thread NukeStrike( tempo_nuke );
	
	// seta mensagens
	SetaMensagens();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );
}

// ==================================================================================================================
//  Define onde será o Nuke Control, quando aparecerá, etc...
// ==================================================================================================================

Bombs()
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

	visuals[0] = getEnt( "sd_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) )
	{
		maps\mp\_utility::error("No sd_bomb script_model found in map.");
		return;
	}		

	// salva trigger da maleta pra achar bomba correta
	maleta = trigger;
	
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
		
		// zulu point
		level.pos_zulu = trigger.origin;
		
		// deleta visual
		for ( i = 0; i < visuals.size; i++ )
		{
			visuals[i] delete();
		}		
		
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
								
				// zulu point
				level.pos_zulu = trigger.origin;
						        
				// deleta visual
				for ( i = 0; i < visuals.size; i++ )
				{
					visuals[i] delete();
				}
		        
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

DeleteSabBombs()
{
	allowed = [];
	allowed[0] = "hq";

	maps\mp\gametypes\_gameobjects::main(allowed);
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

PickRadioToSpawn()
{
	level.radio_one = undefined;
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		dist =  distance(radio.origin,level.pos_zulu);
		
		//logPrint("radio[" + i + "] Dist = " + dist + "\n");
		
		if ( i == 0 )
		{
			level.radio_one = radio;
		}
		if ( i != 0 )
		{
			if ( distance(level.radio_one.origin,level.pos_zulu) > distance(radio.origin,level.pos_zulu) )
			{
				level.radio_one = radio;
			}
		}
	}
	//logPrint("radio[" + level.radio_one.origin + "] Dist = " + distance(level.radio_one.origin,level.pos_zulu) + "\n");

	return level.radio_one;
}

ControlRoom()
{
	//locationObjID = maps\mp\gametypes\_gameobjects::getNextObjID();
	//objective_add( locationObjID, "invisible", (0,0,0) );
	
	radio = PickRadioToSpawn();	
	
	level.control = radio.origin;

	radioObject = radio.gameobject;
	level.radioObject = radioObject;
	radioObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
	
	radioObject maps\mp\gametypes\_gameobjects::enableObject();
	
	radioObject maps\mp\gametypes\_gameobjects::setUseTime( 20 );
	radioObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	radioObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );

	radioObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	radioObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
	
	thread NukeControl( level.control, radioObject );	
}

NukeControl( origin, zone ) 
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	zulutime = randomIntRange( 20, 60 );
	wait zulutime;

	zone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
	zone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );

	thread NukeControlRevealed();
}

NukeControlRevealed()
{
	level.nuke_revealed = true;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == game["attackers"] )
		{
			player iPrintLn( level.nuke_located );
		}
	}
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
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

// ==================================================================================================================
//   Nuke
// ==================================================================================================================

NukeDisarmed()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	wait 1;
	
	if ( distance(self.origin,level.control) > 50 )
		return false;
		
	if ( level.HelpMode == 1 && isDefined(self.lastStand) )		
		return false;
	
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
	self.link_msg setText( level.nuke_sabotage );	
	
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
	
	if ( self.isCommander == false )
		tempo_espera = tempo_espera * 4;
		
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

	thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_1" );

	self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
	
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
		
		if ( distance(self.origin,level.control) > 50 )
		{
			// se distanciou dos controles
			self iprintln ( level.nuke_abort );
			
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
			self iprintln ( level.nuke_abort );
			
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
				self iprintln ( level.nuke_weapon );
				
				self.linkingBG destroy();
				self.linkingInfo destroy();
				self enableWeapons();
				self.computing = false;
				thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
				return false;		
			}
		}
		
		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		
		if ( level.nuke_exploded == true )
		{
			self.linkingBG destroy();
			self.linkingInfo destroy();
			self enableWeapons();
			self.computing = false;
			return false;			
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
	thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
	return true;	
}

NukeStrike( tempo )
{
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	wait tempo;

	level.nuke_exploded = Nuke();
	
	if ( level.nuke_exploded == true )
	{
		level.endtext = level.nuke_hit;
		
		setGameEndTime( 0 );
		
		// termina o round
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;

		sd_endGame( game["defenders"], level.endtext );
	}
	else
	{
		level.endtext = level.nuke_disabled;
		
		//maps\mp\gametypes\_globallogic::HajasDaScore( level.Salvador, 100 );
		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", level.Salvador );
		level.Salvador thread [[level.onXPEvent]]( "plant" );				
		
		setGameEndTime( 0 );
		
		// termina o round
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
		
		sd_endGame( game["attackers"], level.endtext );	
	}
}

Nuke()
{
	tempo_impacto = 0;
	
	if ( level.nuke_disarmed == true )
	{
		return false;
	}

	level.nuke_started = false;
	
	city = randomInt( 2 );
	rot = randomfloat(360);
	
	if ( city == 1 )
    {
		maps\mp\_utility::playSoundOnPlayers( game["nuke_alarm"] );
	}	
	
	while ( tempo_impacto <= 15 )
	{
		if ( level.nuke_disarmed == true )
		{
			return false;
		}
		tempo_impacto++;
		wait 1;
	}
	
	if ( city == 0 )
    {
		level.nuke_started = true;
		maps\mp\_utility::playSoundOnPlayers( game["nuke_passed"] );
		wait 10;
	}
	else
    {
		while ( tempo_impacto <= 25 )
		{
			if ( level.nuke_disarmed == true )
			{
				return false;
			}
			tempo_impacto++;
			wait 1;
		}
	}    

	// neste momento JÁ ERA! :P   
    level.nuke_started = true;

	// som
    if ( city == 1 )
    {
		maps\mp\_utility::playSoundOnPlayers( game["nuke_incoming"] );
		setExpFog(0, 17000, 0.678352, 0.498765, 0.372533, 0.5);
		wait 1.5;
		level.chopperNuke = true;
		maps\mp\_utility::playSoundOnPlayers( game["nuke_01"] );
		maps\mp\_utility::playSoundOnPlayers( game["nuke_02"] );
		
		thread nuke_earthquakeGERAL();
   
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( isDefined(player.carryIcon) )
			{
				player.carryIcon.alpha = 0;
			}
			//thread nuke_earthquake( player );
		}
	}
	else
	{
		maps\mp\_utility::playSoundOnPlayers( game["nuke_03"] );
		maps\mp\_utility::playSoundOnPlayers( game["nuke_04"] );
		
		thread nuke_earthquake_longeGERAL();
	}

	if ( level.script != "mp_apesgorod" || getDvar( "apesgorod" ) != "" )
	{
		// Nuke FX
		if ( city == 1 )
		{
			nuke = spawnFx( level.nuke, level.control, (0,0,1), (cos(rot),sin(rot),0) );
			triggerFx( nuke );
		}
		
		// Flash FX
		flash = spawnFx( level.nuke_flash, level.control, (0,0,1), (cos(rot),sin(rot),0) );
		triggerFx( flash );
	}

	// stun + morte
    if ( city == 1 )
    {
		// stun
		wait 3;

		// diz q explodiu pra nao dar som de morte do Engineer e pra parar sabotagem		
		level.nuke_exploded = true;
		
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			player shellShock( "concussion_grenade_mp", 10 );
			player.concussionEndTime = getTime() + (10 * 1000);		
		}	
		
		// morte
		wait 3;
		thread NukeDestruction(level.control, 50000, 500, 400);	
		wait 5;		
	}
	
	if ( city == 0 )
    {
		wait 5;
	}	
	
	level.nuke_started = false;
	return true;
}

NukeDestruction( alvo, radius, max, min )
{
	// origin dos alvos
	alvos = [];

	// players
	players = level.players;
	for (i = 0; i < players.size; i++)
	{
		if (!isalive(players[i]) || players[i].sessionstate != "playing")
			continue;
		
		playerpos = players[i].origin + (0,0,32);
		dist = distance(alvo, playerpos);
		if (dist < radius )
			alvos[alvos.size] = playerpos;
	}
	
	// carros e barris
	destructibles = getentarray("destructible", "targetname");
	for (i = 0; i < destructibles.size; i++)
	{
		entpos = destructibles[i].origin;
		dist = distance(alvo, entpos);
		if (dist < radius)
			alvos[alvos.size] = entpos;
	}

	destructables = getentarray("destructable", "targetname");
	for (i = 0; i < destructables.size; i++)
	{
		entpos = destructables[i].origin;
		dist = distance(alvo, entpos);
		if (dist < radius)
			alvos[alvos.size] = entpos;
	}		
	
	//logPrint("alvos.size = " + alvos.size + "\n");
	
	raio_ant = 0;
	raio = 1000;
	
	while(1)
	{
		for (i = 0; i < alvos.size; i++)
		{
			dist = distance(alvo, alvos[i]);
			
			if ( (dist >= raio_ant) && (dist <= raio) )
				radiusDamage( alvos[i], 512, max, min );
		}	
		
		wait 0.5;
		
		if ( raio == 1000 )
		{
			raio_ant = 0;
			raio = 3000;
		}
		else if ( raio == 3000 )
		{
			raio_ant = 3000;
			raio = 7000;
		}		
		else if ( raio == 7000 )
		{
			raio_ant = 7000;
			raio = 15000;
		}			
		else if ( raio == 15000 )
		{
			raio_ant = 15000;
			raio = 30000;
		}		
		else if ( raio == 30000 )
		{
			raio_ant = 30000;
			raio = 50000;
		}
		else if ( raio == 50000 )
		{
			return;
		}
	}
}


nuke_earthquakeGERAL()
{
	tempo = 0;
	while ( int(tempo) < 2 )
	{
		earthquake( .08, .05, level.control, 80000);
		wait(.05);
		tempo = tempo + 0.1;
	}
	while( level.nuke_started == true )
	{
		earthquake( .5, 1, level.control, 80000);
		wait(.05);
		earthquake( .25, .05, level.control, 80000);
	}
}

nuke_earthquake_longeGERAL()
{
	earthquake( 0.7, 0.5, level.control, 80000 );
	wait(.05);
	earthquake( 0.4, 0.6, level.control, 80000 );
}

nuke_earthquake( player )
{
	tempo = 0;
	while ( int(tempo) < 2 )
	{
		earthquake( .08, .05, player.origin, 80000);
		wait(.05);
		tempo = tempo + 0.1;
	}
	while( level.nuke_started == true )
	{
		earthquake( .5, 1, player.origin, 80000);
		wait(.05);
		earthquake( .25, .05, player.origin, 80000);
	}
}

nuke_earthquake_longe( player )
{
	earthquake( 0.7, 0.5, player.origin, 800 );
	wait(.05);
	earthquake( 0.4, 0.6, player.origin, 700 );
}

// ==================================================================================================================
//   Player
// ==================================================================================================================

onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
	
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();		

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
}

SpawnVIP()
{
	self.isCommander = true;
	
	if ( level.SidesMSG == 1 )
		self iPrintLnbold( level.nuke_you );
	
	self thread createVipIcon();

	// diz q o mapa já tem um vip/commander vivo
	level.LiveVIP = true;	
	
	// seta nome do Commander para mostrar na tela
	level.ShowName = self.name;	

	// safe?
	thread PlayerDesarmaNuke();
	
	// icone defend!
	thread CriaTriggers( self );		
}

CriaTriggers( player )
{
	while ( !self.hasSpawned )
		wait ( 0.1 );

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
}


SpawnSoldado()
{
	self.isCommander = false;
	
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();		

	if ( self.pers["team"] == game["attackers"])
	{
		if ( level.VIPName == 1 )
			thread ShowVipName();

		// todos podem desativar Nuke
		thread PlayerDesarmaNuke();
	}
}

PlayerDesarmaNuke()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	sabotou = false;
	
	while(1)
	{
		if ( distance(self.origin,level.control) < 50 )
		{
			sabotou = NukeDisarmed();
			
			if ( level.gameEnded == true )
				return;			
			
			if ( level.nuke_disarmed == true )
			{
				return;
			}			
			
			if ( sabotou == true )
			{
				// diz que terminou o desarme
				level.nuke_disarmed = true;
				
				// diz quem foi o salvador pra dar pontos no FINAL
				level.Salvador = self;

				for ( i = 0; i < level.players.size; i++ )
				{
					player = level.players[i];
					if ( player.pers["team"] == game["attackers"] )
					{
						player iPrintLn( level.nuke_pray );
					}
				}
				wait 1;
				maps\mp\gametypes\_globallogic::leaderDialog( "obj_taken",  game["attackers"] );	
				
				// se nuke nao iniciou, dá vitória direta sem espera
				if( level.nuke_started == false )
				{
					wait 1;
					level.endtext = "^7The ^3Nuke ^7was Sabotaged!";
					
					//maps\mp\gametypes\_globallogic::HajasDaScore( level.Salvador, 100 );
					maps\mp\gametypes\_globallogic::givePlayerScore( "plant", level.Salvador );
					level.Salvador thread [[level.onXPEvent]]( "plant" );						
					
					setGameEndTime( 0 );
					
					// termina o round
					level.overrideTeamScore = true;
					level.displayRoundEndText = true;
					
					sd_endGame( game["attackers"], level.endtext );					
				}
				return;		
			}
		} 
		wait 1;
	}
}

// ==================================================================================================================
//   Engineer
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
		msg_info = "^9" + level.ShowName + "^7 " + level.nuke_is;
		self iPrintLn( msg_info );
	}
}

createVipIcon()
{
	self.carryIcon = createIcon( "specialty_detectexplosive", 35, 35 );
	
	self.carryIcon setPoint( "CENTER", "CENTER", 220, 160 );
	self.carryIcon.alpha = 0.75;
	
	// carrega icon no placar
	self.statusicon = "specialty_detectexplosive";
}

onPlayerDisconnect()
{
	self vipDead();
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();		

	self vipDead();
}

vipDead()
{
	if ( isDefined( self.isCommander ) && self.isCommander == true )
	{
		if ( level.nuke_exploded == false )
		{
			maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["attackers"] );
		}
		
		game["VIPname"] = "";

		// deixa de ser vip/commander
		self.isCommander = false;

		// diz q nao tem mais vip/Commander vivo
		level.LiveVIP = false;

		level notify("vip_is_dead");
		
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( player.pers["team"] == game["attackers"] )
			{
				player iPrintLn( level.nuke_dead );
			}
		}		
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
	if ( level.nuke_started == true )
		return;
		
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
		thread free_spec();
		return;	
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

free_spec()
{
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

SetaMensagens()
{
	// located
	if ( getDvar( "scr_nuke_located" ) == "" )
	{
		level.nuke_located = "^1Intel Information ^0: ^7Nuke Control Located!";
	}
	else
	{
		level.nuke_located = getDvar( "scr_nuke_located" );
	}

	// sabotage			
	if ( getDvar( "scr_nuke_sabotage" ) == "" )
	{
		level.nuke_sabotage = "Disabling the Missle";
	}
	else
	{
		level.nuke_sabotage = getDvar( "scr_nuke_sabotage" );
	}	
	
	// weapon			
	if ( getDvar( "scr_nuke_weapon" ) == "" )
	{
		level.nuke_weapon = "^1Warning ^0: ^7Put down your weapon to use the Computer!";
	}
	else
	{
		level.nuke_weapon = getDvar( "scr_nuke_weapon" );
	}
	
	// abort			
	if ( getDvar( "scr_nuke_abort" ) == "" )
	{
		level.nuke_abort = "^1Warning ^0: ^7You didn't finished the Disable procedure!";
	}
	else
	{
		level.nuke_abort = getDvar( "scr_nuke_abort" );
	}	

	// pray
	if ( getDvar( "scr_nuke_pray" ) == "" )
	{
		level.nuke_pray = "^1Missle Disabled ^0: ^7Ok, let's pray to it works!";
	}
	else
	{
		level.nuke_pray = getDvar( "scr_nuke_pray" );
	}
	
	// ----------------------------
	
	// nuke_hit
	if ( getDvar( "scr_nuke_hit" ) == "" )
	{
		level.nuke_hit = "^7The ^3Nuke ^7has hit the target!";
	}
	else
	{
		level.nuke_hit = getDvar( "scr_nuke_hit" );
	}

	// nuke_disabled
	if ( getDvar( "scr_nuke_disabled" ) == "" )
	{
		level.nuke_disabled = "^7The ^3Nuke ^7was Sabotaged!";
	}
	else
	{
		level.nuke_disabled = getDvar( "scr_nuke_disabled" );
	}
	
	// nuke_you
	if ( getDvar( "scr_nuke_you" ) == "" )
	{
		level.nuke_you = "^7You are the ^9Engineer^7!";
	}
	else
	{
		level.nuke_you = getDvar( "scr_nuke_you" );
	}	

	// nuke_is
	if ( getDvar( "scr_nuke_is" ) == "" )
	{
		level.nuke_is = "is the ^9Engineer^7!";
	}
	else
	{
		level.nuke_is = getDvar( "scr_nuke_is" );
	}

	// nuke_dead
	if ( getDvar( "scr_nuke_dead" ) == "" )
	{
		level.nuke_dead = "^7Our ^9Engineer^7 is Dead!";
	}
	else
	{
		level.nuke_dead = getDvar( "scr_nuke_dead" );
	}

}
