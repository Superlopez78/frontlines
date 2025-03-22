#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// funcao pra registrar 
registerDocsGTDvar( dvarString, defaultValue, minValue, maxValue )
{
	if ( getDvar( dvarString ) == "" )
		setDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		setDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		setDvar( dvarString, minValue );

	level.DocsgtDvar = dvarString;
	level.DocsgtMin = minValue;
	level.DocsgtMax = maxValue;
	level.Docsgt = getDvarInt( level.DocsgtDvar );
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	registerDocsGTDvar( "scr_docs_gt", 0, 0, 1 );

	if ( level.Docsgt == 0 )
		init();
	else if ( level.Docsgt == 1 )
	{
		maps\mp\gametypes\overcome::init();
		return;
	}
}

init()
{
	level.DocsTeam = "neutral";
	level.tem_koth = true;
	
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( "docs", 5, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( "docs", 6, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( "docs", 10, 0, 12 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( "docs", 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchSpawnDvar( "docs", 2, 0, 9 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( "docs", 0, 0, 1000 );	
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( "docs", 1, 0, 1 );
	
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onRoundSwitch = ::onRoundSwitch;
	level.onRoundSwitchSpawn = ::onRoundSwitchSpawn;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["offense_obj"] = "capture_obj";
	game["dialog"]["defense_obj"] = "capture_obj";
}


onPrecacheGameType()
{
	precacheShader( "compass_waypoint_capture" );
	precacheShader( "compass_waypoint_defend" );
	precacheShader("compass_waypoint_target");

	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
	precacheShader("waypoint_target");	
	
	precacheShader("waypoint_kill");
	precacheShader("hud_suitcase_bomb");
	precacheStatusIcon( "hud_suitcase_bomb" );		
	
	precacheModel( "prop_suitcase_bomb" );
	
	//sounds
	
	game["bomb_dropped_sound"] = "mp_war_objective_lost";
	game["bomb_recovered_sound"] = "mp_war_objective_taken";	
	
	/*
	. quando terminamos upload diz pro time
	game["dialog"]["obj_taken"] = "securedobj";
	
	. quando pegamos diz pro time
	game["dialog"]["obj_defend"] = "obj_defend";
	
	. quando perdemos os docs diz pro time
	game["dialog"]["obj_lost"] = "lostobj";
	
	*/
}


onStartGameType()
{
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
		
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_DOCS_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_DOCS_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_DOCS_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_DOCS_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_DOCS_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_DOCS_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_DOCS_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_DOCS_DEFENDER" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sab_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sab_spawn_axis_start" );
	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	if ( !isDefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;	
		
	level.timeat = "mp_sab_spawn_axis_start";
	
	if ( game["attackers"] == "axis" )
	{
		level.timeat = "mp_sab_spawn_axis_start";
		level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sab_spawn_axis_start" );
		level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sab_spawn_allies_start" );
	}
	else if ( game["attackers"] == "allies" )
	{
		level.timeat = "mp_sab_spawn_allies_start";
		level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sab_spawn_allies_start" );
		level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sab_spawn_axis_start" );
	}
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// airborne 
	if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		maps\mp\gametypes\_airborne::StartGametype();	
			
	allowed[0] = "hq";
	allowed[1] = "sab";
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	level.iconoffset = (0,0,32);

	// seta mensagens
	SetaMensagens();
	
	// testa se tem sab
	trigger = getEnt( "sab_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) ) 
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}	
	
	// SAB
	SetupSab();
	DeleteSabBombs();
	
	VerificaLados();
	
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
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sab,tdm" );
}

SetupSab()
{

	trigger = getEnt( "sab_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) ) 
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		error( "No sab_bomb_pickup_trig trigger found in map." );
		return;
	}

	visuals[0] = getEnt( "sab_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) ) 
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		error( "No sab_bomb script_model found in map." );
		return;
	}
		
	visuals[0] setModel( "prop_suitcase_bomb" );
	level.sabBomb = maps\mp\gametypes\_gameobjects::createCarryObject( "neutral", trigger, visuals, (0,0,32) );
	level.sabBomb maps\mp\gametypes\_gameobjects::allowCarry( "any" );
	level.sabBomb maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
	level.sabBomb maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );
	level.sabBomb maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_capture" );
	level.sabBomb maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_capture" );
	level.sabBomb maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
	level.sabBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	level.sabBomb.objIDPingEnemy = true;
	level.sabBomb.onPickup = ::onPickup;
	level.sabBomb.onDrop = ::onDrop;
	level.sabBomb.allowWeapons = true;
	level.sabBomb.objPoints["allies"].archived = true;
	level.sabBomb.objPoints["axis"].archived = true;
	level.sabBomb.autoResetTime = 60.0;
	
}

DeleteSabBombs()
{
	clips = getentarray( "script_brushmodel" , "classname" );
	
	// bomba axis
	trigger = getEnt( "sab_bomb_axis", "targetname" );
	visuals = getEntArray( trigger.target, "targetname" );

	// deleta clips
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].origin ) )
		{	
			if( distance( clips[i].origin , trigger.origin ) < 100 )
				clips[i] delete();
		}
	}

	// deleta visual
	for ( i = 0; i < visuals.size; i++ )
	{
		if( distance( visuals[i].origin , trigger.origin ) < 100 )
			visuals[i] delete();
	}	

	// bomba allies
	trigger = getEnt( "sab_bomb_allies", "targetname" );
	visuals = getEntArray( trigger.target, "targetname" );

	// deleta clips
	for(i=0 ; i<clips.size ; i++)
	{
		if ( isDefined ( clips[i].origin ) )
		{
			if( distance( clips[i].origin , trigger.origin ) < 100 )
				clips[i] delete();
		}
	}

	// deleta visual
	for ( i = 0; i < visuals.size; i++ )
	{
		if( distance( visuals[i].origin , trigger.origin ) < 100 )
			visuals[i] delete();
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
			radio.gameObject = maps\mp\gametypes\_gameobjects::createUseObject( game["attackers"], radio.trig, visuals, (radio.origin - radio.trigorigin) + level.iconoffset );
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
		
		return;
	}
	
	level.radios = radios;
	
	return true;
}

RadioAttack()
{
	spawn_ataque = level.attack_spawn;

	// define qual é o mais perto	
	level.radio_one = undefined;
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];

		dist =  distance(radio.origin,spawn_ataque);
		//logPrint("radio[" + i + "] Dist = " + dist + "\n");
		
		if ( i == 0 )
		{
			level.radio_one = radio;
		}
		if ( i != 0 )
		{
			if ( distance(level.radio_one.origin,spawn_ataque) > distance(radio.origin,spawn_ataque) )
			{
				level.radio_one = radio;
			}
		}
	}
	//logPrint("radio one[" + level.radio_one.origin + "] Dist = " + distance(level.radio_one.origin,spawn_ataque) + "\n");
	
	// seta os flags do radio da defesa
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		
		if ( level.radio_one == radio )
		{
			radio.gameObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
			radio.gameObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
			radio.gameObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
		}
	}	
}

// ==================================================================================================================
//   Docs
// ==================================================================================================================


onPickup( player )
{
	level notify ( "bomb_picked_up" );
	
	player.statusicon = "hud_suitcase_bomb";
	player.docs = true;
	
	self.autoResetTime = 60.0;
	
	level.useStartSpawns = false;
	
	team = player.pers["team"];
	
	if ( team == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";
	
	// inicia teste de upload
	if ( team == game["attackers"] )
		player thread PlayerUpload();	

	player playLocalSound( "mp_suitcase_pickup" );
	player logString( "bomb taken" );

	excludeList[0] = player;
	maps\mp\gametypes\_globallogic::leaderDialog( "obj_defend", team, "bomb", excludeList );
	maps\mp\gametypes\_globallogic::leaderDialog( "obj_lost", otherTeam );

	// recovered the bomb before abandonment timer elapsed
	if ( team == self maps\mp\gametypes\_gameobjects::getOwnerTeam() )
	{
		printOnTeamArg( &"HAJAS_DOCS_RECOVERED_BY", team, player );
		playSoundOnPlayers( game["bomb_recovered_sound"], team );
	}
	else
	{
		printOnTeamArg( &"HAJAS_DOCS_RECOVERED_BY", team, player );
		playSoundOnPlayers( game["bomb_recovered_sound"] );
	}
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	
	level.DocsTeam = team;
	   	
   	// localizador apenas pro ataque
   	if ( team == game["defenders"] )
   	{
		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_kill" );   	
   	}
   	else
   	{
   		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
   	}
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );

	if ( team == "allies" )
	{
		if ( team == game["attackers"] )
		{
			player iPrintLn( level.docs_retrieve );
			player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "goodtogo", "bomb" );
		}
		else
		{
			player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "boost", "bomb" );
		}
	}
	else
	{
		if ( team == game["attackers"] )
		{
			player iPrintLn( level.docs_retrieve );
			player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "ready_to_move", "bomb" );
		}
		else
		{
			player maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "move_to_new", "bomb" );
		}
	}
	
	if ( player.pickupScore == false )
	{
		player.pickupScore = true;
		maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", player );
		player thread [[level.onXPEvent]]( "pickup" );	
	}
}


onDrop( player )
{
	level.DocsTeam = "neutral";

	if ( isDefined( player ) )
	{
		printOnTeamArg( &"HAJAS_DOCS_DROPPED_BY", self maps\mp\gametypes\_gameobjects::getOwnerTeam(), player );
		// remove icon se player perde a bomba
        if ( isAlive( player ) ) 
		{
			player.statusicon = "";
			player.docs = false;
		}			
	}

	playSoundOnPlayers( game["bomb_dropped_sound"], self maps\mp\gametypes\_gameobjects::getOwnerTeam() );
	if ( isDefined( player ) )
		player logString( "bomb dropped" );
	else
		logString( "bomb dropped" );

	thread abandonmentThink( 0.0 );
}

abandonmentThink( delay )
{
	level endon ( "bomb_picked_up" );
	
	wait ( delay );

	if ( isDefined( self.carrier ) )
		return;

	if ( self maps\mp\gametypes\_gameobjects::getOwnerTeam() == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";

	playSoundOnPlayers( game["bomb_dropped_sound"], otherTeam );

	self maps\mp\gametypes\_gameobjects::setOwnerTeam( "neutral" );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_capture" );
}

// ==================================================================================================================
//   Player
// ==================================================================================================================

// verifica lados pra mudar o terminal de lugar
VerificaLados()
{
	if ( !isDefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;

	if ( game["switchedspawnsides"] )
	{
		if ( level.attack_spawn == maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sab_spawn_axis_start" ))
		{
			level.timeat = "mp_sab_spawn_allies_start";
			level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sab_spawn_allies_start" );
			level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sab_spawn_axis_start" );
		}
		else
		{
			level.timeat = "mp_sab_spawn_axis_start";
			level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sab_spawn_axis_start" );
			level.defend_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sab_spawn_allies_start" );
		}
	}	
}

onSpawnPlayer()
{
	self.computing = false;
	self.docs = false;

	spawnPointName = "mp_sab_spawn_axis_start";
	if ( level.timeat == "mp_sab_spawn_axis_start" )
	{
		if(self.pers["team"] == game["attackers"])
			spawnPointName = "mp_sab_spawn_axis_start";
		else
			spawnPointName = "mp_sab_spawn_allies_start";	
	}
	else if ( level.timeat == "mp_sab_spawn_allies_start" )
	{
		if(self.pers["team"] == game["attackers"])
			spawnPointName = "mp_sab_spawn_allies_start";
		else
			spawnPointName = "mp_sab_spawn_axis_start";		
	}
	
	if ( !isDefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;
	
	if ( level.SidesMSG == 1 )
	{
		if(self.pers["team"] == game["attackers"])
			self iPrintLnbold( level.docs_recover );
		else
			self iPrintLnbold( level.docs_protect );
	}

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
			spawnPoints = getEntArray( spawnPointName, "classname" );
			assert( spawnPoints.size );
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );		
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			self spawn( spawnpoint.origin, spawnpoint.angles );
		}
	}
	else
	{
		spawnPoints = getEntArray( spawnPointName, "classname" );
		assert( spawnPoints.size );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );	
		self spawn( spawnpoint.origin, spawnpoint.angles );
	}

	level notify ( "spawned_player" );
}

PlayerUpload()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
	
	if ( self.docs == false )
		return;
	
	uploaded = false;
	
	while(1)
	{
		if ( distance(self.origin,level.radio_one.origin) < 50 )
		{
			uploaded = Uploading();
			
			if ( level.gameEnded == true )
				return;
			
			if ( uploaded == true  )
			{
				maps\mp\gametypes\_globallogic::leaderDialog( "obj_taken", self.team );
				
				if ( isDefined( self.carryIcon ) )
					self.carryIcon destroyElem();
					
				self.statusicon = "";
				self.docs = false;					
						
				level.endtext = level.docs_recovered;
					
				maps\mp\gametypes\_globallogic::givePlayerScore( "plant", self );
				self thread [[level.onXPEvent]]( "plant" );						
						
				setGameEndTime( 0 );
						
				// termina o round
				level.overrideTeamScore = true;
				level.displayRoundEndText = true;
					
				thread sd_endGame( game["attackers"], level.endtext );	
				return;					
			}
		}	
		wait 1;
	} 
}

Uploading()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	if ( level.HelpMode == 1 && isDefined(self.lastStand) )		
		return false;

	if ( isDefined( self.lastStand ) )
			return false;
	
	docs_msg = "";
	
	docs_msg = level.docs_uploading;
	if ( distance(self.origin,level.radio_one.origin) > 50 )
			return false;		
	
	// dropa arma
	self disableWeapons();
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
	self.link_msg setText( docs_msg );	
	
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

	thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_1" );
	
	self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");	
	
	wait 1;
	
	while ( temp <= tempo_espera )
	{
		if ( isDefined( self.lastStand ) )
		{
			self.linkingBG destroy();
			self.linkingInfo destroy();
			self enableWeapons();
			self.computing = false;
			thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
			return false;		
		}		

		self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		// atualiza barra
		bar_inc = temp * bar_parte;
		
		// garante q barra não vai estourar
		if ( bar_inc > 100 )
		{
			bar_inc = 100;
		}
		self.linkingInfo setShader("white", bar_inc, 10);
		
		if(isDefined(self.bIsBot) && self.bIsBot)
		{
		}
		else
		{
			if ( distance(self.origin,level.radio_one.origin) > 50 )
			{
				// se distanciou dos controles
				self iprintln ( level.docs_abort );
				
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
				self iprintln ( level.docs_abort );
				
				self.linkingBG destroy();
				self.linkingInfo destroy();
				self enableWeapons();
				self.computing = false;
				thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
				return false;			
			}
			
			self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
			
			uav_arma = self getCurrentWeapon();
			if ( uav_arma != "none" )
			{
				// se distanciou dos controles
				self iprintln ( level.docs_weapon );
				
				self.linkingBG destroy();
				self.linkingInfo destroy();
				self enableWeapons();
				self.computing = false;
				thread maps\mp\gametypes\_globallogic::HajasSelf3DSound ( "som_uav_2" );
				return false;		
			}
			
			self maps\mp\gametypes\_globallogic::ExecClientCommand("gocrouch");
		}			
		
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

// ==================================================================================================================
//   Game Over
// ==================================================================================================================

sd_endGame( winningTeam, endReasonText )
{
	// hajas duel
	// zera tudo no final de cada round
	game["hajas_duel_exec"] = 0;
	game["hajas_duel"] = 0;	
	
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

SetaMensagens()
{
	// uploading			
	if ( getDvar( "scr_docs_uploading" ) == "" )
	{
		level.docs_uploading = "Uploading...";
	}
	else
	{
		level.docs_uploading = getDvar( "scr_docs_uploading" );
	}

	// retrieve			
	if ( getDvar( "scr_docs_retrieve" ) == "" )
	{
		level.docs_retrieve = "^1Warning ^0: ^7Comeback and upload the Docs to our Intel!";
	}
	else
	{
		level.docs_retrieve = getDvar( "scr_docs_retrieve" );
	}		

	// weapon			
	if ( getDvar( "scr_docs_weapon" ) == "" )
	{
		level.docs_weapon = "^1Warning ^0: ^7Put down your weapon to use the Computer!";
	}
	else
	{
		level.docs_weapon = getDvar( "scr_docs_weapon" );
	}
	
	// abort			
	if ( getDvar( "scr_docs_abort" ) == "" )
	{
		level.docs_abort = "^1Warning ^0: ^7You didn't finished your task!";
	}
	else
	{
		level.docs_abort = getDvar( "scr_docs_abort" );
	}	

	// recover!			
	if ( getDvar( "scr_docs_recover" ) == "" )
	{
		level.docs_recover = "^7Recover the ^9Docs^7!";
	}
	else
	{
		level.docs_recover = getDvar( "scr_docs_recover" );
	}

	// protect!			
	if ( getDvar( "scr_docs_protect" ) == "" )
	{
		level.docs_protect = "^7Protect the ^9Docs^7!";
	}
	else
	{
		level.docs_protect = getDvar( "scr_docs_protect" );
	}	
	
	// recovered
	if ( getDvar( "scr_docs_recovered" ) == "" )
	{
		level.docs_recovered = "^7The ^3Docs ^7were Recovered!";
	}
	else
	{
		level.docs_recovered = getDvar( "scr_docs_recovered" );
	}	
}