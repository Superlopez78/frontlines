#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
		
	level.DocsTeam = "neutral";
	level.tem_koth = true;

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 10, 0, 1440 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 0, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 4, 0, 12 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 1, 0, 9 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchSpawnDvar( level.gameType, 2, 0, 9 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 0, 0, 50 );	
	maps\mp\gametypes\_globallogic::registerSidesMSGDvar( level.gameType, 1, 0, 1 );
	maps\mp\gametypes\_globallogic::registerTypeDvar( level.gameType, 2, 0, 3 );
	
	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	level.onRoundSwitchSpawn = ::onRoundSwitchSpawn;
	
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPlayerDisconnect = ::onPlayerDisconnect;
	
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["offense_obj"] = "capture_objs";
	game["dialog"]["defense_obj"] = "capture_objs";
}


onPrecacheGameType()
{
    // scored!
    precacheString(&"MP_TEAM_SCORED");    
    precacheString(&"MP_ENEMY_SCORED");
	
	precacheShader( "waypoint_capture" );
	precacheShader( "waypoint_defend" );
	precacheShader( "waypoint_targetneutral" );
	precacheShader( "waypoint_kill" );
	precacheShader( "compass_waypoint_target" );
	precacheShader( "compass_waypoint_defend" );

	precacheModel( "prop_suitcase_bomb" );	
	precacheShader( "hud_suitcase_bomb" );
	precacheStatusIcon( "hud_suitcase_bomb" );	
	
	precacheShader( "compass_waypoint_captureneutral" );
	precacheShader( "compass_waypoint_capture_a" );
	precacheShader( "compass_waypoint_defend_a" );
	precacheShader( "compass_waypoint_capture_b" );
	precacheShader( "compass_waypoint_defend_b" );
	precacheShader( "compass_waypoint_capture_c" );
	precacheShader( "compass_waypoint_defend_c" );

	precacheShader( "waypoint_capture_a" );
	precacheShader( "waypoint_defend_a" );
	precacheShader( "waypoint_capture_b" );
	precacheShader( "waypoint_defend_b" );
	precacheShader( "waypoint_capture_c" );
	precacheShader( "waypoint_defend_c" );
	
	maps\mp\gametypes\_airborne::init();
}

onStartGameType()
{
	// pro status dialog
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
	
	// zera placar por round pra saber quantos docs faltam
	level.docs_recuperados["allies"] = 0;
	level.docs_recuperados["axis"] = 0;

	// zera todo round para decidir nova zona de escape	
	level.EscapeZone = 0;
	
	// diz que Zulu ainda não foi marcada
	level.ZuluRevealed = false;
	level.ZuluRevealedStartou = false;
	
	// carrega fumaça
	level.zulu_point_smoke	= loadfx("smoke/signal_smoke_green");

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
		
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_AIRBORNE_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_AIRBORNE_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_AIRBORNE_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_AIRBORNE_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_AIRBORNE_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_AIRBORNE_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_AIRBORNE_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_AIRBORNE_DEFENDER" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	
	if ( !isDefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;	
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_tdm_spawn_allies_start" );
	level.defender_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_tdm_spawn_axis_start" );

	// calcula distancia entre spawns pra saber se mapa é pequeno
	level.showdist = distance(level.attack_spawn,level.defender_spawn);
	//logprint("Dist = " + level.showdist );	
	
	// airborne 
	maps\mp\gametypes\_airborne::StartGametype();
	
	// posições posiveis pros docs
	level.pos = [];
	// apenas posições dos docs
	level.docs = [];	
	
	allowed[0] = "hq";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	level.iconoffset = (0,0,32);

	// seta mensagens
	SetaMensagens();
	
	// definos os spawns
	DefineSpawns();
	
	// seto todos o radios
    SetupRadios();
    
	if ( level.tem_koth == false )
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );
		return;
	}      
	
	// seleciono o radio randomico LONGE do Zulu point
	RadioDefend();	

	// starta docs
	criaDocs();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "tdm" );
	
	// toca alarme
	thread TocaAlarme();
}

// ==================================================================================================================
//   Terminal para Upload
// ==================================================================================================================

SetupRadios()
{
	maperrors = [];

	radios = getentarray( "hq_hardpoint", "targetname" );
	
	if ( radios.size < 2 )
		maperrors[maperrors.size] = "There are not at least 2 entities with targetname \"radio\"";
	else
	{
		trigs = getentarray("radiotrigger", "targetname");
		
		// decide qual será o radio da defesa
		// fica em loop até achar um radio longe o suficiente do zulu point
		
		dist = 1000;
		if ( level.showdist > 2500 )
			dist = 2000;
		if ( level.showdist > 5000 )
			dist = 3000;
		
		level.the_one = randomInt(radios.size);
		while ( distance(level.EscapeZone,radios[level.the_one].origin) < dist )
			level.the_one = randomInt(radios.size);
		
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
			
			if ( i == level.the_one )
			{
				level.radio_one = radio;
			
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

RadioDefend()
{
	//logPrint("level.radios.size = " + level.radios.size + "\n");
	//logPrint("level.the_one = " + level.the_one + "\n");
	
	// seta os flags do radio da defesa
	for ( i = 0; i < level.radios.size; i++ )
	{
		radio = level.radios[i];
		
		if ( level.the_one == i )
		{
			radio.gameObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
			radio.gameObject maps\mp\gametypes\_gameobjects::setModelVisibility( true );
			radio.gameObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_captureneutral" );
			radio.gameObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_targetneutral" );			
			radio.trig.useObj = radio.gameObject;
			
		}
		else
		{
			// salva posições pros docs
			level.pos[level.pos.size] = radio.origin;
		}
	}	
}

// ==================================================================================================================
//   Docs
// ==================================================================================================================

criaDocs()
{
	// completa posição dos docs
	posDocs();
	
	pastaModel = "prop_suitcase_bomb";
	
	level.pastas = [];
	
	// pasta 1
	pasta_caida[1]["pasta_trigger"] = spawn( "trigger_radius", level.docs[0], 0, 20, 100 );
	pasta_caida[1]["pasta"][0] = spawn( "script_model", level.docs[0]);
	pasta_caida[1]["zone_trigger"] = spawn( "trigger_radius", level.docs[0], 0, 50, 100 );
	
	pasta_caida[1]["pasta"][0] setModel( pastaModel );
	level.pastas[0] = criaDocsCarregavel( 1, pasta_caida[1]["pasta_trigger"], pasta_caida[1]["pasta"] );
	
	// pasta 2
	pasta_caida[2]["pasta_trigger"] = spawn( "trigger_radius", level.docs[1], 0, 20, 100 );
	pasta_caida[2]["pasta"][0] = spawn( "script_model", level.docs[1]);
	pasta_caida[2]["zone_trigger"] = spawn( "trigger_radius", level.docs[1], 0, 50, 100 );
	
	pasta_caida[2]["pasta"][0] setModel( pastaModel );
	level.pastas[1] = criaDocsCarregavel( 2, pasta_caida[2]["pasta_trigger"], pasta_caida[2]["pasta"] );
	
	// pasta 3
	pasta_caida[3]["pasta_trigger"] = spawn( "trigger_radius", level.docs[2], 0, 20, 100 );
	pasta_caida[3]["pasta"][0] = spawn( "script_model", level.docs[2]);
	pasta_caida[3]["zone_trigger"] = spawn( "trigger_radius", level.docs[2], 0, 50, 100 );
	
	pasta_caida[3]["pasta"][0] setModel( pastaModel );
	level.pastas[2] = criaDocsCarregavel( 3, pasta_caida[3]["pasta_trigger"], pasta_caida[3]["pasta"] );
	
}

criaDocsCarregavel( num, trigger, visuals )
{
	if ( num == 1 )
	{
		label = "_a";
		
		pastaObject = maps\mp\gametypes\_gameobjects::createCarryObject( game["attackers"], trigger, visuals, (0,0,100) );
		pastaObject.label = label;
		pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_capture" + label );
		pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_capture" + label );
		pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" + label );
		pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + label );
		
		if ( level.Type < 3 )
			pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
		else
			pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
			
		pastaObject maps\mp\gametypes\_gameobjects::allowCarry( "any" );
		pastaObject maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
	   
		pastaObject.onPickup = ::onPickupPasta;
		pastaObject.onDrop = ::onDropPasta;
		pastaObject.allowWeapons = true;
	   
		return pastaObject;	
	}
	else if ( num == 2 )
	{
		label = "_b";
		
		pastaObject = maps\mp\gametypes\_gameobjects::createCarryObject( game["attackers"], trigger, visuals, (0,0,100) );
		pastaObject.label = label;
		pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_capture" + label );
		pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_capture" + label );
		pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" + label );
		pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + label );
		
		if ( level.Type < 3 )
			pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
		else
			pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
			
		pastaObject maps\mp\gametypes\_gameobjects::allowCarry( "any" );
		pastaObject maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
	   
		pastaObject.onPickup = ::onPickupPasta;
		pastaObject.onDrop = ::onDropPasta;
		pastaObject.allowWeapons = true;
	   
		return pastaObject;	
	}
	else if ( num == 3 )
	{
		label = "_c";
		
		pastaObject = maps\mp\gametypes\_gameobjects::createCarryObject( game["attackers"], trigger, visuals, (0,0,100) );
		pastaObject.label = label;
		pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_capture" + label );
		pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_capture" + label );
		pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" + label );
		pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + label );
		
		if ( level.Type < 3 )
			pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
		else
			pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
			
		pastaObject maps\mp\gametypes\_gameobjects::allowCarry( "any" );
		pastaObject maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
	   
		pastaObject.onPickup = ::onPickupPasta;
		pastaObject.onDrop = ::onDropPasta;
		pastaObject.allowWeapons = true;
	   
		return pastaObject;	
	}
}

DeletaDoc( label )
{
	if ( label == "_a" )
	{
		level.pastas[0] maps\mp\gametypes\_gameobjects::setDropped();
		level.pastas[0] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
		level.pastas[0] maps\mp\gametypes\_gameobjects::allowCarry( "none" );
		level.pastas[0] maps\mp\gametypes\_gameobjects::setModelVisibility( false );
	}
	else if ( label == "_b" )
	{
		level.pastas[1] maps\mp\gametypes\_gameobjects::setDropped();
		level.pastas[1] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
		level.pastas[1] maps\mp\gametypes\_gameobjects::allowCarry( "none" );
		level.pastas[1] maps\mp\gametypes\_gameobjects::setModelVisibility( false );
	}
	else if ( label == "_c" )
	{
		level.pastas[2] maps\mp\gametypes\_gameobjects::setDropped();
		level.pastas[2] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
		level.pastas[2] maps\mp\gametypes\_gameobjects::allowCarry( "none" );
		level.pastas[2] maps\mp\gametypes\_gameobjects::setModelVisibility( false );
	}
}


onPickupPasta( player )
{
	player.docs = true;
	
	player.statusicon = "hud_suitcase_bomb";

	team = player.pers["team"];
	
	if ( team == game["attackers"] )
		thread ZuluSmoke();

	self.autoResetTime = 90.0;
	
	if ( team == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";
	
	// inicia teste de upload se defesa que pegou
	// inicia teste de chegar no Zulu se ataque que pegou
	if ( team == game["defenders"] )
		player thread PlayerUpload(self.label);
	else if ( team == game["attackers"] )
		player thread PlayerEscaped(self.label);

	player playLocalSound( "mp_suitcase_pickup" );
	
	statusDialog( "securing"+self.label, team );	
	statusDialog( "losing"+self.label, otherTeam );
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	
	level.DocsTeam = team;
	
	if ( level.Type < 3 )
	{
		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
		
	   	// muda pro time que pegou
		self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + self.label );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + self.label );
		
		if ( level.Type < 2 )
		{
			// muda pro outro time
			self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
			self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_kill" );
		}
		else
			self maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
	}
	else
		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 	

	if ( team == game["attackers"] )
		player iPrintLn( level.docs_retrieve_a );
	else if ( team == game["defenders"] )
		player iPrintLn( level.docs_retrieve_d );
	
	if ( player.pickupScore == false )
	{
		player.pickupScore = true;
		maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", player );
		player thread [[level.onXPEvent]]( "pickup" );	
	}
}

onDropPasta( player )
{
	if ( isDefined( player ) )
	{
		// remove icon se player perde a bomba
        if ( isAlive( player ) ) 
		{
			player.statusicon = "";
			player.docs = false;
		}			
	}		
	
	if ( level.Type < 3 )
	{
		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
		self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_capture" + self.label );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_capture" + self.label );
		self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" + self.label );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + self.label );
	}
	else
		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 	
}

posDocs()
{
	// decide lado
	lado =  randomInt(2);
	ladoteam = "axis";
	
	if ( lado == 0 )
		ladoteam = "axis";
	else
		ladoteam = "allies";

	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( ladoteam );
	assert( spawnPoints.size );
	
	for (i = 0; i < spawnPoints.size; i++)
		level.pos[level.pos.size] = spawnPoints[i].origin;

	/*
	// printa todos as possíveis posições dos docs
	for (x = 0; x < level.pos.size; x++)
	{
		posDocs = level.pos[x];
		logPrint("posDocs[" + x + "] = " + posDocs + "\n");
	}
	*/
	
	doc_a = 0;
	doc_b = 1;
	doc_c = 2;
	
	// seleciona 3 posições pros 3 docs
	
	// define DOC A
	doc_a = randomInt(level.pos.size);
	// salva pos DOC A
	level.docs[0] = level.pos[doc_a];
	// remove DOC A da lista e atualiza
	level.pos = removeArray( level.pos, doc_a );
	
	// define DOC B
	doc_b = randomInt(level.pos.size);
	// salva pos DOC B
	level.docs[1] = level.pos[doc_b];
	// remove DOC B da lista e atualiza
	level.pos = removeArray( level.pos, doc_b );

	// define DOC C
	doc_c = randomInt(level.pos.size);
	// salva pos DOC C
	level.docs[2] = level.pos[doc_c];
	// remove DOC C da lista e atualiza
	level.pos = removeArray( level.pos, doc_c );
	
	/*
	// printa as 3 posições dos docs
	for (x = 0; x < level.docs.size; x++)
	{
		posDocs = level.docs[x];
		logPrint("posDocsFinais[" + x + "] = " + posDocs + "\n");
	}
	*/
}

// ==================================================================================================================
//   Escape Zone - Zulu
// ==================================================================================================================

SelionaEscapeZone( spawnPointName )
{
	// se não tiver zerado já foi escolhido = aborta
	if ( level.EscapeZone != 0 )
		return;

	EscapeZone = "";

	if ( spawnPointName == "mp_tdm_spawn_axis_start" )
		EscapeZone = "mp_tdm_spawn_allies_start";
	else
		EscapeZone = "mp_tdm_spawn_axis_start";

	level.EscapeZone = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( EscapeZone );			
}

ZuluSmoke() 
{
	// se já foi revelada aborta!
	if ( level.ZuluRevealedStartou == true )
		return;
		
	level.ZuluRevealedStartou = true;

	zulutime = randomIntRange( 5, 10 );
	wait zulutime;
	
	level.ZuluRevealed = true;
	
	level.zulu_mark = maps\mp\gametypes\_objpoints::createTeamObjpoint( "objpoint_next_hq", level.EscapeZone + (0,0,70), game["attackers"], "waypoint_targetneutral" );
	level.zulu_mark setWayPoint( true, "waypoint_targetneutral" );	

	thread playSoundinSpace( "smokegrenade_explode_default", level.EscapeZone );

	rot = randomfloat(360);
	zulupoint = spawnFx( level.zulu_point_smoke, level.EscapeZone, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( zulupoint );

	thread ZuluRevealed();
}

ZuluRevealed()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.pers["team"] == game["attackers"] )
		{
			//player iPrintLn( "leve os docs pro Zulu" );
		}
	}
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
}

PlayerEscaped( doc )
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );
	
	while(1)
	{
		if ( level.ZuluRevealed == true )
		{
			if ( distance(self.origin,level.EscapeZone) < 100 )
			{
				if ( isDefined( self.carryIcon ) )
					self.carryIcon destroyElem();
				self.statusicon = "";
				thread DeletaDoc( doc );
				maps\mp\gametypes\_globallogic::givePlayerScore( "plant", self );
				self thread [[level.onXPEvent]]( "plant" );				
				thread AirborneUpdateScore( self.team );
				thread DizScore( self.team, doc );
				return;
			} 
		}
		wait 1;
	}
}

// ==================================================================================================================
//   Score
// ==================================================================================================================

AirborneUpdateScore ( team )
{
	// diz q doc foi recuperado por time
	level.docs_recuperados[team]++;
	
	// atualiza score
	[[level._setTeamScore]]( team, [[level._getTeamScore]]( team ) + 1 );

	// acha outro time
	otherTeam = "axis";
	if ( team == "axis" )
		otherTeam = "allies";
		
	thread printAndSoundOnEveryone( team, otherTeam, &"MP_TEAM_SCORED", &"MP_ENEMY_SCORED", "plr_new_rank", "mp_obj_taken", "" );
	
	// se todos docs recuperados, fim de jogo!
	if ( level.docs_recuperados["allies"] + level.docs_recuperados["axis"] == 3 )
	{
		wait 1;
		
		winner = game["defenders"];
		if ( level.docs_recuperados["allies"] > level.docs_recuperados["axis"] )
			winner = "allies";
		else
			winner = "axis";
	
		setGameEndTime( 0 );
			
		// termina o round
		level.overrideTeamScore = true;
		level.displayRoundEndText = true;
			
		sd_endGame( winner, level.docs_recovered );	
	}
}

// ==================================================================================================================
//   Sound
// ==================================================================================================================

TocaAlarme()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	maps\mp\_utility::playSoundOnPlayers( game["nuke_alarm"] );
}

DizScore( team, doc )
{	
	otherTeam = "axis";
	if ( team == "axis" )
		otherTeam = "allies";

	statusDialog( "secured"+doc, team );
	statusDialog( "lost"+doc, otherTeam );
}

statusDialog( dialog, team )
{
	time = getTime();
	if ( getTime() < level.lastStatus[team] + 6000 )
		return;
		
	thread delayedLeaderDialog( dialog, team );
	level.lastStatus[team] = getTime();	
}

delayedLeaderDialog( sound, team )
{
	wait .1;
	maps\mp\gametypes\_globallogic::WaitTillSlowProcessAllowed();
	
	maps\mp\gametypes\_globallogic::leaderDialog( sound, team );
}
delayedLeaderDialogBothTeams( sound1, team1, sound2, team2 )
{
	wait .1;
	maps\mp\gametypes\_globallogic::WaitTillSlowProcessAllowed();
	
	maps\mp\gametypes\_globallogic::leaderDialogBothTeams( sound1, team1, sound2, team2 );
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


// ==================================================================================================================
//   Player
// ==================================================================================================================

DefineSpawns()
{
	if( game["attackers"] == "allies" )
		level.spawnPointName = "mp_tdm_spawn_allies_start";
	else
		level.spawnPointName = "mp_tdm_spawn_axis_start";
	
	if ( !isDefined( game["switchedspawnsides"] ) )
		game["switchedspawnsides"] = false;
	
	if ( game["switchedspawnsides"] )
	{
		if ( level.spawnPointName == "mp_tdm_spawn_allies_start")
		{
			level.spawnPointName = "mp_tdm_spawn_axis_start";
		}
		else
		{
			level.spawnPointName = "mp_tdm_spawn_allies_start";
		}
	}

	SelionaEscapeZone( level.spawnPointName );
}

onSpawnPlayer()
{
	self.computing = false;
	self.docs = false;
	
	if ( level.SidesMSG == 1 )
	{
		if( self.pers["team"] != game["attackers"] && getDvarInt ( "frontlines_abmode" ) == 0 )
			self iPrintLnbold( level.docs_recover );
		else if( self.pers["team"] != game["defenders"] && getDvarInt ( "frontlines_abmode" ) == 1 )
			self iPrintLnbold( level.docs_recover );
	}

	if ( getDvarInt ( "frontlines_abmode" ) == 0 )
	{
		// airborne
		if(self.pers["team"] == game["attackers"])
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			assert( spawnPoints.size );
			
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
			if ( level.SidesMSG == 1 )
				self thread MsgChao();
		}
		else // defesa
		{
			if ( level.inGracePeriod )
				spawnPoints = getEntArray( level.spawnPointName, "classname" );
			else
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			
			assert( spawnPoints.size );
			
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			
			self spawn( spawnpoint.origin, spawnpoint.angles );
		}
	}
	else
	{
		// ataque
		if(self.pers["team"] == game["attackers"])
		{
			if ( level.inGracePeriod )
				spawnPoints = getEntArray( level.spawnPointName, "classname" );
			else
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			
			assert( spawnPoints.size );
			
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			
			self spawn( spawnpoint.origin, spawnpoint.angles );
		}
		else // airborne defesa
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
			assert( spawnPoints.size );
			
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			maps\mp\gametypes\_airborne::SpawnPlayer( true, spawnPoint, false );
			if ( level.SidesMSG == 1 )
				self thread MsgChao();
		}
	}
	
	level notify ( "spawned_player" );
	
	// remove hardpoints
	HajasRemoveHardpoints_player( self );
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
		removePQplayer();
}

onPlayerDisconnect()
{
		removePQplayer();
}

// ==================================================================================================================
//   Player - Upload
// ==================================================================================================================

PlayerUpload( doc )
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
				if ( isDefined( self.carryIcon ) )
					self.carryIcon destroyElem();
					
				self.statusicon = "";
				self.docs = false;				
				
				thread DeletaDoc( doc );
				
				maps\mp\gametypes\_globallogic::givePlayerScore( "plant", self );
				self thread [[level.onXPEvent]]( "plant" );				
						
				thread AirborneUpdateScore( self.team );
				thread DizScore( self.team, doc );
				
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
	
	docs_msg = "";
	
	docs_msg = level.docs_uploading;
	if ( distance(self.origin,level.radio_one.origin) > 50 )
			return false;
			
	if ( isDefined( self.lastStand ) )
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
	
	self ExecClientCommand("gocrouch");	
	
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

		self ExecClientCommand("gocrouch");
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
			
			self ExecClientCommand("gocrouch");
			
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
			
			self ExecClientCommand("gocrouch");		
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
	thread playSoundOnPlayers( "mp_suitcase_pickup", game["defenders"] );
	return true;	
}

// ==================================================================================================================
//   Game Over
// ==================================================================================================================

sd_endGame( winningTeam, endReasonText )
{
	HajasRemoveHardpoints();
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}


onDeadEvent( team )
{
	if ( team == "all" )
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	else if ( team == game["attackers"] )
		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	else if ( team == game["defenders"] )
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
}

onOneLeftEvent( team )
{
	warnLastPlayer( team );
}

onTimeLimit()
{
	winner = "tie";
		
	if ( level.docs_recuperados["allies"] > level.docs_recuperados["axis"] )
		winner = "allies";
	else if ( level.docs_recuperados["allies"] < level.docs_recuperados["axis"] )
		winner = "axis";

	logString( "time limit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
	
	HajasRemoveHardpoints();

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

MsgChao()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );	
	
	while (self.air == false)
		wait (0.05);
	
	self iPrintLnbold( level.docs_recover );
}

SetaMensagens()
{
	// uploading			
	if ( getDvar( "scr_airborne_uploading" ) == "" )
		level.docs_uploading = "Uploading...";
	else
		level.docs_uploading = getDvar( "scr_airborne_uploading" );

	// retrieve	defense		
	if ( getDvar( "scr_airborne_retrieve_d" ) == "" )
		level.docs_retrieve_d = "^1Warning ^0: ^7Comeback and upload the Docs to our Intel!";
	else
		level.docs_retrieve_d = getDvar( "scr_airborne_retrieve_d" );
	
	// retrieve	attack	
	if ( getDvar( "scr_airborne_retrieve_a" ) == "" )
		level.docs_retrieve_a = "^1Warning ^0: ^7Take the Docs to the Extraction Zone!";
	else
		level.docs_retrieve_a = getDvar( "scr_airborne_retrieve_a" );

	// weapon			
	if ( getDvar( "scr_airborne_weapon" ) == "" )
		level.docs_weapon = "^1Warning ^0: ^7Put down your weapon to use the Computer!";
	else
		level.docs_weapon = getDvar( "scr_airborne_weapon" );
	
	// abort			
	if ( getDvar( "scr_airborne_abort" ) == "" )
		level.docs_abort = "^1Warning ^0: ^7You didn't finished your task!";
	else
		level.docs_abort = getDvar( "scr_airborne_abort" );

	// recover!			
	if ( getDvar( "scr_airborne_recover" ) == "" )
		level.docs_recover = "^7Recover the ^9Docs^7!";
	else
		level.docs_recover = getDvar( "scr_airborne_recover" );

	// recovered
	if ( getDvar( "scr_airborne_recovered" ) == "" )
		level.docs_recovered = "^7All ^3Docs ^7were Recovered!";
	else
		level.docs_recovered = getDvar( "scr_airborne_recovered" );
}

// remove elemento do array e reorganiza.
removeArray( array, index )
{
    novoArray = [];

    for(i = 0; i < array.size; i++)
    {
        if(i < index)
			novoArray[i] = array[i];
        else if(i > index) 
			novoArray[i - 1] = array[i];
    }
    return novoArray;
}

HajasRemoveHardpoints()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
	
		if ( level.starstreak > 0 )
		{
			player.fl_stars = 0;
			if ( isDefined( player.fl_stars_pts ) && player.fl_stars_pts > 0 )
				player.fl_stars_pts = 0;	
		}
		
		if( player HasWeapon( "radar_mp" ) ) 
		{
			player takeWeapon( "radar_mp" );
			player setActionSlot( 4, "" );
			player.pers["hardPointItem"] = undefined;	
		}
		if( player HasWeapon( "airstrike_mp" ) ) 
		{
			player takeWeapon( "airstrike_mp" );
			player setActionSlot( 4, "" );
			player.pers["hardPointItem"] = undefined;	
		}
		if( player HasWeapon( "helicopter_mp" ) ) 
		{
			player takeWeapon( "helicopter_mp" );
			player setActionSlot( 4, "" );
			player.pers["hardPointItem"] = undefined;	
		}									
	}	
}

HajasRemoveHardpoints_player( player )
{
	if( player HasWeapon( "radar_mp" ) ) 
	{
		player takeWeapon( "radar_mp" );
		player setActionSlot( 4, "" );
		player.pers["hardPointItem"] = undefined;	
	}
	if( player HasWeapon( "airstrike_mp" ) ) 
	{
		player takeWeapon( "airstrike_mp" );
		player setActionSlot( 4, "" );
		player.pers["hardPointItem"] = undefined;	
	}
	if( player HasWeapon( "helicopter_mp" ) ) 
	{
		player takeWeapon( "helicopter_mp" );
		player setActionSlot( 4, "" );
		player.pers["hardPointItem"] = undefined;	
	}									
}

removePQplayer()
{
		dono = self.clientid;
		thread deleta_para(dono);
		self.treme = false;
}

deleta_para( id , player)
{
	wait 1;
	if ( isDefined(player) )
		player unlink();
	if ( isDefined (level.pqmodel) && isDefined (level.pqmodel[id]) )
		level.pqmodel[id] delete();
}

// executa comando no cliente
ExecClientCommand( cmd )
{
	self setClientDvar( game["menu_clientcmd"], cmd );
	self openMenu( game["menu_clientcmd"] );
	self closeMenu( game["menu_clientcmd"] );
}