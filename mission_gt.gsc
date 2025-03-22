#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 1, 1, 1 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 30, 0, 100 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 0, 0, 0 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 2, 1, 2 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 0, 0, 1000 );
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
	
	// controlar morte Commander
	level.onPlayerKilled = ::onPlayerKilled;
	level.onPlayerDisconnect = ::onPlayerDisconnect;
	
	level.endGameOnScoreLimit = false;
	
	game["dialog"]["gametype"] = "team_hardcore";
	game["dialog"]["offense_obj"] = "capture_objs";
	game["dialog"]["defense_obj"] = "objs_defend";
	
	// se não definido controle, cria como false
	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;
	
	if( game["roundsplayed"] == 0 )
	{
		SetDvar( "mission_time_A", 0 );
		SetDvar( "mission_time_B", 0 );
		
		SetDvar( "mission_time_A_full", 0 );
		SetDvar( "scr_mission_timelimit_original", getDvarFloat("scr_mission_timelimit") );
	}

	level.pode_AB = false;	
	if ( TestaAirborne( level.script, "^" ) )
		level.pode_AB = true;
}


onPrecacheGameType()
{
	// Commander
	thread defineIcons();
	
	// Commander Sounds
	game["commander_killed"] = "mp_enemy_obj_captured";
	game["our_commander_is_dead"] = "mp_enemy_obj_taken";
	
	game["bomb_dropped_sound"] = "mp_war_objective_lost";
	game["bomb_recovered_sound"] = "mp_war_objective_taken";
	precacheModel( "prop_suitcase_bomb" );	

	precacheShader("hud_suitcase_bomb");
	precacheStatusIcon( "hud_suitcase_bomb" );	

	precacheShader( "waypoint_targetneutral" );
	precacheShader( "waypoint_kill" );
	
	precacheShader("waypoint_target_a");
	precacheShader("waypoint_target_b");
	precacheShader("waypoint_defend");
	precacheShader("waypoint_defend_a");
	precacheShader("waypoint_defend_b");
	precacheShader("waypoint_defuse");
	precacheShader("compass_waypoint_target");
	precacheShader("compass_waypoint_target_a");
	precacheShader("compass_waypoint_target_b");
	precacheShader("compass_waypoint_defend");
	precacheShader("compass_waypoint_defend_a");
	precacheShader("compass_waypoint_defend_b");
	precacheShader("compass_waypoint_defuse");

	precacheString( &"MP_PLANTING_EXPLOSIVE" );	
	precacheString( &"MP_DEFUSING_EXPLOSIVE" );	
	precacheString( &"MP_CAPTURING_FLAG" );
	
	// airborne
	maps\mp\gametypes\_airborne::init();
	
	// nuke
	game["nuke_01"] = "nuke";
	game["nuke_02"] = "nuke_impact";
	game["nuke_incoming"] = "nuke_incoming";	
	
	precacheStatusIcon( "specialty_longersprint" );
}

onStartGameType()
{
	// inicia clock pra salvar tempo exato
	level.CompleteClock = 0;
	
	level.mission_state = "lz";
	
	// "bombs"
	// "general"
	// "docs"
	// "retreat"

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

	level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");
	
	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"HAJAS_MISSION_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"HAJAS_MISSION_DEFENDER" );

	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"HAJAS_MISSION_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"HAJAS_MISSION_DEFENDER" );

	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"HAJAS_MISSION_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"HAJAS_MISSION_DEFENDER_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );	
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	// inicia com landing zone da defesa!
	level.landing_zone_secured = false;
	
	// posição spawns para marcar spawns da defesa/ataque!
	level.attack_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_attacker" );
	level.defender_spawn = maps\mp\gametypes\_spawnlogic::CalculaOriginSpawns( "mp_sd_spawn_defender" );
	
	// define pos Zulu
	if ( level.script == "mp_cdi_mision_bunker" )
		level.EscapeZone = (792.287,39.3419,496.125);
	else
		level.EscapeZone = level.attack_spawn;
	
	// diz que Zulu ainda não foi marcada
	level.ZuluRevealed = false;
	level.ZuluRevealedStartou = false;
	
	// carrega fumaça
	level.zulu_point_smoke	= loadfx("smoke/signal_smoke_green");	
	
	// calcular spawns chão!
	CalculaSpawnsAtaque();
	CalculaSpawnsDefesa();
	
    // Nuke FX
    level.nuke			= loadfx("explosions/nuke_explosion");
    level.nuke_flash	= loadfx("explosions/nuke_flash");		

	level.nuke_exploded = false;
	level.nuke_started = false;

	// airborne 
	maps\mp\gametypes\_airborne::StartGametype();
	
	allowed = [];
	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	allowed[3] = "dom";
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	thread updateGametypeDvars();
	
	level.bomb_hab = false;
	
	novos_flag_init();
	novos_sd_init();
	
	// assim da merda com random, invertido da merda sem! tem q acertar!
	LandingZone();
	bombs();
		
	SetaMensagens();
	
	maps\mp\gametypes\_globallogic::DeletaOutrosSpawns( "sd,tdm" );	
}

// ==================================================================================================================
//   Flag - Landing Zone
// ==================================================================================================================

LandingZone()
{
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;
	
	game["flagmodels"] = [];
	game["flagmodels"]["neutral"] = "prop_flag_neutral";

	if ( game["allies"] == "marines" )
		game["flagmodels"]["allies"] = "prop_flag_american";
	else
		game["flagmodels"]["allies"] = "prop_flag_brit";
	
	if ( game["axis"] == "russian" ) 
		game["flagmodels"]["axis"] = "prop_flag_russian";
	else
		game["flagmodels"]["axis"] = "prop_flag_opfor";
	
	precacheModel( game["flagmodels"]["allies"] );
	precacheModel( game["flagmodels"]["axis"] );
	
	primaryFlags = getEntArray( "flag_primary", "targetname" );
	secondaryFlags = getEntArray( "flag_secondary", "targetname" );
	
	if ( (primaryFlags.size + secondaryFlags.size) < 2 )
	{
		logPrint( "^1Not enough domination flags found in level!" );
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}
		
	level.flags = [];
	for ( index = 0; index < primaryFlags.size; index++ )
		level.flags[level.flags.size] = primaryFlags[index];
	
	for ( index = 0; index < secondaryFlags.size; index++ )
		level.flags[level.flags.size] = secondaryFlags[index];
		
	if ( level.novos_objs )
		move_flag();		
		
	FlagCentral = SelecionaFlag();
	
	if ( level.script == "mp_cdi_mision_bunker" )
	{
		pos = (-25.2337,715.5,436.125);
		obj_a_origin = pos + (0, 0, 0);
	
		FlagCentral.origin = obj_a_origin;
		
		if ( isDefined( FlagCentral.target ) )
		{
			a_obj_entire = getent( FlagCentral.target, "targetname" );
			a_obj_entire.origin = obj_a_origin;
		}	
	}
	else if ( level.script == "mp_gold_rush" )
	{
		pos = (-311.565,-1958.64,733.625);
		obj_a_origin = pos + (0, 0, 0);
	
		FlagCentral.origin = obj_a_origin;
		
		if ( isDefined( FlagCentral.target ) )
		{
			a_obj_entire = getent( FlagCentral.target, "targetname" );
			a_obj_entire.origin = obj_a_origin;
		}	
	}
	else if ( level.script == "mp_gb_bunker_b1" )
	{
		pos = (-389.213,-112.378,32.125);
		obj_a_origin = pos + (0, 0, 0);
	
		FlagCentral.origin = obj_a_origin;
		
		if ( isDefined( FlagCentral.target ) )
		{
			a_obj_entire = getent( FlagCentral.target, "targetname" );
			a_obj_entire.origin = obj_a_origin;
		}	
	}
	
	level.flags = [];
	level.flags[0] = FlagCentral;	
	
	level.domFlags = [];
	for ( index = 0; index < level.flags.size; index++ )
	{
		trigger = level.flags[index];
		if ( isDefined( trigger.target ) )
			visuals[0] = getEnt( trigger.target, "targetname" );
		else
		{
			visuals[0] = spawn( "script_model", trigger.origin );
			visuals[0].angles = trigger.angles;
		}

		visuals[0] setModel( game["flagmodels"][game["defenders"]] );

		domFlag = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,100) );
		domFlag maps\mp\gametypes\_gameobjects::setOwnerTeam( game["defenders"] );
		domFlag.visuals[0] setModel( game["flagmodels"][game["defenders"]] );		
		
		domFlag maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		domFlag maps\mp\gametypes\_gameobjects::setUseTime( 10.0 );
		domFlag maps\mp\gametypes\_gameobjects::setUseText( &"MP_CAPTURING_FLAG" );
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );
		domFlag maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		domFlag.onUse = ::onUse;
		domFlag.onBeginUse = ::onBeginUse;
		domFlag.onUseUpdate = ::onUseUpdate;
		domFlag.onEndUse = ::onEndUse;
		
		traceStart = visuals[0].origin + (0,0,32);
		traceEnd = visuals[0].origin + (0,0,-32);
		trace = bulletTrace( traceStart, traceEnd, false, undefined );
	
		upangles = vectorToAngles( trace["normal"] );
		domFlag.baseeffectforward = anglesToForward( upangles );
		domFlag.baseeffectright = anglesToRight( upangles );
		
		domFlag.baseeffectpos = trace["position"];

		// legacy spawn code support
		level.flags[index].useObj = domFlag;
		level.flags[index].adjflags = [];
		level.flags[index].nearbyspawns = [];
		
		domFlag.levelFlag = level.flags[index];
		
		level.domFlags[level.domFlags.size] = domFlag;
	}
	
	flagSetup();
}

SelecionaFlag()
{
	flag_center = undefined;
	
	if ( level.flags.size == 3 )
	{
		flag_ataque = FlagPertoSpawn( level.attack_spawn );
		flag_defesa = FlagPertoSpawn( level.defender_spawn );
		
		flag_center = RetornaFlagRestante( flag_ataque, flag_defesa );
	}
	else 
	{
		flag_ataque = FlagPertoSpawn( level.attack_spawn );
		flag_defesa = FlagPertoSpawn( level.defender_spawn );
		
		flag_center = RetornaFlagMaisAlta( flag_ataque, flag_defesa );	
	}

	return flag_center;
}

FlagPertoSpawn( ponto )
{
	flag_perto = undefined;
	for ( index = 0; index < level.flags.size; index++ )
	{	
		flag = level.flags[index];
		if ( index == 0 )
			flag_perto = flag;
		else
		{
			if ( distance( flag_perto.origin, ponto ) > distance( flag.origin , ponto ) )
				flag_perto = flag;
		}
	}
	return flag_perto;
}

RetornaFlagRestante( flag1, flag2 )
{
	for ( index = 0; index < level.flags.size; index++ )
	{	
		flag = level.flags[index];
		if ( flag != flag1 && flag != flag2 )
			return flag;
	}
}

RetornaFlagMaisAlta( flag1, flag2 )
{
	flag_alta = undefined;
	
	novasFlags = [];
	novo_index = 0;
	
	for ( index = 0; index < level.flags.size; index++ )
	{	
		flag = level.flags[index];
		if ( flag != flag1 && flag != flag2 )
		{
			novasFlags[novo_index] = flag;
			novo_index++;
		}
	}

	for ( index = 0; index < novasFlags.size; index++ )
	{	
		flag = novasFlags[index];
		
		if ( level.novos_objs == true )
		{
			if ( isDefined ( level.bomb_pos ) )
			{
				if ( distance( level.bomb_pos[0], flag.origin ) > 500 && distance( level.bomb_pos[1], flag.origin ) > 500 )
				{
					if ( !isDefined( flag_alta ) )
						flag_alta = flag;
					else
					{
						if ( flag.origin[2] > flag_alta.origin[2] )
						{
							flagA = PhysicsTrace( flag.origin , flag.origin + (0,0,1000) );
							flagB = PhysicsTrace( flag_alta.origin , flag_alta.origin + (0,0,1000) );
							
							flagA_max = int(flagA[2]);
							flagB_max = int(flagB[2]);
						
							// se tem espaço acima (ver céu!)	
							if ( flagA_max > flagB_max )
								flag_alta = flag;
						}
						else if ( level.script == "mp_ksfact" )
							flag_alta = flag;
					}
				}			
			}
			else
			{
				if ( !isDefined( flag_alta ) )
					flag_alta = flag;
				else
				{
					if ( flag.origin[2] > flag_alta.origin[2] )
					{
						flagA = PhysicsTrace( flag.origin , flag.origin + (0,0,1000) );
						flagB = PhysicsTrace( flag_alta.origin , flag_alta.origin + (0,0,1000) );
						
						flagA_max = int(flagA[2]);
						flagB_max = int(flagB[2]);
					
						// se tem espaço acima (ver céu!)	
						if ( flagA_max > flagB_max )
							flag_alta = flag;
					}
					else if ( level.script == "mp_ksfact" )
						flag_alta = flag;
				}
			}
		}
		else
		{
			if ( !isDefined( flag_alta ) )
				flag_alta = flag;
			else
			{
				if ( flag.origin[2] > flag_alta.origin[2] )
				{
					flagA = PhysicsTrace( flag.origin , flag.origin + (0,0,1000) );
					flagB = PhysicsTrace( flag_alta.origin , flag_alta.origin + (0,0,1000) );
					
					flagA_max = int(flagA[2]);
					flagB_max = int(flagB[2]);
				
					// se tem espaço acima (ver céu!)	
					if ( flagA_max > flagB_max )
						flag_alta = flag;
				}
				else if ( level.script == "mp_ksfact" )
					flag_alta = flag;
			}
		}
	}
	if ( !isDefined( flag_alta ) )
		flag_alta = novasFlags[0];

	return flag_alta;
}

flagSetup()
{
	closestdist = undefined;
	closestdesc = undefined;
	maperrors = [];
	descriptorsByLinkname = [];

	// (find each flag_descriptor object)
	descriptors = getentarray("flag_descriptor", "targetname");
	
	flags = level.flags;
	
	for (j = 0; j < descriptors.size; j++)
	{
		dist = distance(flags[0].origin, descriptors[j].origin);
		if (!isdefined(closestdist) || dist < closestdist) {
			closestdist = dist;
			closestdesc = descriptors[j];
		}
	}
	
	descriptors = [];
	descriptors[0] = closestdesc;
	
	for (i = 0; i < level.domFlags.size; i++)
	{
		closestdist = undefined;
		closestdesc = undefined;
		for (j = 0; j < descriptors.size; j++)
		{
			dist = distance(flags[i].origin, descriptors[j].origin);
			if (!isdefined(closestdist) || dist < closestdist) {
				closestdist = dist;
				closestdesc = descriptors[j];
			}
		}
		
		if (!isdefined(closestdesc)) {
			maperrors[maperrors.size] = "there is no flag_descriptor in the map! see explanation in dom.gsc";
			break;
		}
		if (isdefined(closestdesc.flag)) {
			maperrors[maperrors.size] = "flag_descriptor with script_linkname \"" + closestdesc.script_linkname + "\" is nearby more than one flag; is there a unique descriptor near each flag?";
			continue;
		}
		flags[i].descriptor = closestdesc;
		closestdesc.flag = flags[i];
		descriptorsByLinkname[closestdesc.script_linkname] = closestdesc;
	}
	
	if (maperrors.size > 0)
	{
		logPrint("^1------------ Map Errors ------------\n");
		for(i = 0; i < maperrors.size; i++)
			logPrint(maperrors[i]);
		logPrint("^1------------------------------------\n");
		
		//maps\mp\_utility::error("Map errors. See above");
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );
		
		return;
	}
}

onBeginUse( player )
{
	ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel() + "_flash", 1 );	
	self.didStatusNotify = false;

	if ( ownerTeam == "neutral" )
	{
		self.objPoints[player.pers["team"]] thread maps\mp\gametypes\_objpoints::startFlashing();
		return;
	}
		
	if ( ownerTeam == "allies" )
		otherTeam = "axis";
	else
		otherTeam = "allies";

	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::startFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::startFlashing();
}


onUseUpdate( team, progress, change )
{
	if ( progress > 0.05 && change && !self.didStatusNotify )
	{
		ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
		if ( ownerTeam != "neutral" )
		{
			statusDialog( "flag_taken", ownerTeam );
			statusDialog( "enemy_flag_taken", team );		
		}

		self.didStatusNotify = true;
	}
}

onEndUse( team, player, success )
{
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel() + "_flash", 0 );

	self.objPoints["allies"] thread maps\mp\gametypes\_objpoints::stopFlashing();
	self.objPoints["axis"] thread maps\mp\gametypes\_objpoints::stopFlashing();
}

onUse( player )
{
	team = player.pers["team"];
	oldTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	label = self maps\mp\gametypes\_gameobjects::getLabel();
	
	player logString( "flag captured the flag!" );
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );
	self.visuals[0] setModel( game["flagmodels"][team] );
	setDvar( "scr_obj" + self maps\mp\gametypes\_gameobjects::getLabel(), team );	
	
	level.useStartSpawns = false;
	
	assert( team != "neutral" );
	
	thread printAndSoundOnEveryone( team, oldTeam, level.mission_pro_lz + " | ", level.mission_sec_lz + " | ", "mp_war_objective_taken", "mp_war_objective_lost", player );
		
	statusDialog( "enemy_flag_captured", team );
	statusDialog( "flag_captured", oldTeam );	

	thread giveFlagCaptureXP( self.touchList[team] );

	thread LZ_Secured();
}

LZ_Secured()
{
	ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	
	if ( ownerTeam == game["attackers"] )
	{
		level.landing_zone_secured = true;
		// toca alarme
		thread TocaAlarme();
		// habilita bombas
		if ( level.bomb_hab == false )
			thread HabilitaBombas();
	}
	else
		level.landing_zone_secured = false;
}

HabilitaBombas()
{
	level.bomb_hab = true;
	level.bombZones[0] maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	level.bombZones[1] maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	
	level.mission_state = "bombs";
	
	Pontua( 10 );
}

giveFlagCaptureXP( touchList )
{
	wait .05;
	maps\mp\gametypes\_globallogic::WaitTillSlowProcessAllowed();
	
	players = getArrayKeys( touchList );
	for ( index = 0; index < players.size; index++ )
	{
		touchList[players[index]].player thread [[level.onXPEvent]]( "capture" );
		maps\mp\gametypes\_globallogic::givePlayerScore( "capture", touchList[players[index]].player );
	}
}

// ==================================================================================================================
//   Player
// ==================================================================================================================

CalculaSpawnsDefesa()
{
	// inicia spaws da defesa
	level.DefesaSpawns = [];

	// distancia maxima para spawn ser válido!
	dist_max = distance(level.attack_spawn, level.defender_spawn)/3;
	//logPrint( "dist_max = " + dist_max + "\n");
	
	// pega spawn SD
	spawnPoints = getEntArray( "mp_sd_spawn_defender", "classname" );
	assert( spawnPoints.size );
		
	for (i = 0; i < spawnpoints.size; i++)
	{
		level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
	}

	// pega spawns tdm
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( game["defenders"] );
	assert( spawnPoints.size );	
	
	// loop control
	tudo_ok = false;	
	
	// spawn_count
	spawn_count = 0;	
	
	if ( level.script == "mp_beltot_2" )
	{
		/*
		spawnPoints = getEntArray( "mp_sd_spawn_defender", "classname" );
		assert( spawnPoints.size );
		
		for (i = 0; i < spawnpoints.size; i++)
		{
			level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
		}	
		*/
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
			dist = distance(level.defender_spawn, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist < dist_max)
				spawn_count++;
		}
		if ( spawn_count < 3 )
		{
			dist_max = dist_max + 500;
			spawn_count = 0;
		}
		else
			tudo_ok = true;
	}
	
	// cria lista de spawns
	for (i = 0; i < spawnpoints.size; i++)
	{
		dist = distance(level.defender_spawn, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist < dist_max)
			level.DefesaSpawns[level.DefesaSpawns.size] = spawnpoints[i];
	}	
}

CalculaSpawnsAtaque()
{
	// inicia spaws da defesa
	level.AtaqueSpawns = [];

	// distancia maxima para spawn ser válido!
	dist_max = distance(level.attack_spawn, level.defender_spawn)/3;
	
	// pega spawn SD
	spawnPoints = getEntArray( "mp_sd_spawn_attacker", "classname" );
	assert( spawnPoints.size );
	
	for (i = 0; i < spawnpoints.size; i++)
	{
		level.AtaqueSpawns[level.AtaqueSpawns.size] = spawnpoints[i];
	}		
	
	// pega spawns tdm
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( game["attackers"] );
	assert( spawnPoints.size );	
	
	// loop control
	tudo_ok = false;	
	
	// spawn_count
	spawn_count = 0;	
	
	if ( level.script == "mp_cdi_mision_bunker" )
	{
		level.AtaqueSpawns = [];
		heli = (824,-1752,7517);
		dist_max = 300; // só dentro heli!
		
		for (i = 0; i < spawnpoints.size; i++)
		{
			dist = distance(heli, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist < dist_max)
			{
				level.AtaqueSpawns[level.AtaqueSpawns.size] = spawnpoints[i];
			}
		}	
		return;		
	}
	
	if ( level.script == "mp_beltot_2" )
	{
		/*
		spawnPoints = getEntArray( "mp_sd_spawn_attacker", "classname" );
		assert( spawnPoints.size );
		
		for (i = 0; i < spawnpoints.size; i++)
		{
			level.AtaqueSpawns[level.AtaqueSpawns.size] = spawnpoints[i];
		}
		*/
		return;			
	}
	
	//logPrint("spawnpoints.size = " + spawnpoints.size + "\n");
	
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
			dist = distance(level.attack_spawn, spawnpoints[i].origin);
			//logPrint("dist[ " + i + " ] = " + dist + "\n");
			if ( dist < dist_max)
				spawn_count++;
		}
		if ( spawn_count < 3 )
		{
			dist_max = dist_max + 500;
			spawn_count = 0;
			if ( dist_max > 10000 )
				tudo_ok = true;
		}
		else
			tudo_ok = true;
	}
	
	// cria lista de spawns
	for (i = 0; i < spawnpoints.size; i++)
	{
		dist = distance(level.attack_spawn, spawnpoints[i].origin);
		//logPrint("dist[ " + i + " ] = " + dist + "\n");
		if ( dist < dist_max)
		{
			level.AtaqueSpawns[level.AtaqueSpawns.size] = spawnpoints[i];
		}
	}	
}

onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
	self.isCommander = false;
	
	// se tem os docs
	self.docs = false;
	
	// mata hud bomba
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();	
		
	// mata statusicon
	self.statusicon = "";
	
	// deleta skin do commander se sobrou do round anterior
	if ( self.pers["class"] == "CLASS_COMMANDER" || self.pers["class"] == "CLASS_VIP" )
		VIPloadModelBACK();
	
	if ( level.inGracePeriod )
		MissionSpawnStart();
	else
		MissionSpawnMeio();
}
	
MissionSpawnStart()
{
	if(self.pers["team"] == game["attackers"])
		spawnPointName = "mp_sd_spawn_attacker";
	else
		spawnPointName = "mp_sd_spawn_defender";
		
	spawnPoints = getEntArray( spawnPointName, "classname" );
	assert( spawnPoints.size );
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );

	self spawn( spawnpoint.origin, spawnpoint.angles );

	level notify ( "spawned_player" );

	// remove hardpoints
	HajasRemoveHardpoints_player( self );			
	
	MsgPlayer( self );
}

MissionSpawnMeio()
{
	if(self.pers["team"] == game["defenders"])
	{
		// ================== Spawn Commander/Soldado ==========================

		if ( level.GeneralMorto == false && level.LiveVIP == false && self.pers["team"] == game["defenders"] && level.bombExploded == 2)
		{
			SpawnVIP();
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.DefesaSpawns );
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );				
			CriaDocs( spawnpoint.origin ); // cria docs para pegar assim q nascer!
			self spawn( spawnpoint.origin, spawnpoint.angles );
		}
		else
		{
			SpawnSoldado();
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.DefesaSpawns );
			maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );
			self spawn( spawnpoint.origin, spawnpoint.angles );
		}
	}
	else
	{
		if ( getDvarInt ( "frontlines_abmode" ) == 1 )
		{
			// testa se é airborne ou não
			if ( level.landing_zone_secured == true )
			{
				if ( !isDefined( self.carryIcon ) && level.bombExploded != 2 )
				{
					self.carryIcon = createIcon( "hud_suitcase_bomb", 35, 35 );
					self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
					self.carryIcon.alpha = 0.75;
				}
				
				self.isBombCarrier = true;
				
				// chão!
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.AtaqueSpawns );

				self spawn( spawnpoint.origin, spawnpoint.angles );
				
				maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );

				MsgPlayer( self );				
			}
			else
			{
				self.isBombCarrier = false;
				
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
				assert( spawnPoints.size );
				
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
				
				if ( !level.pode_AB )
					self spawn( spawnpoint.origin, spawnpoint.angles );
					
				maps\mp\gametypes\_airborne::SpawnPlayer( level.pode_AB, spawnPoint, false );
				
				// airborne!
				if ( level.abfire == 1 )
					self enableWeapons();
			}
		}
		else
		{
			// testa se é airborne ou não
			if ( level.landing_zone_secured == true )
			{
				if ( !isDefined( self.carryIcon ) && level.bombExploded != 2 )
				{
					self.carryIcon = createIcon( "hud_suitcase_bomb", 35, 35 );
					self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
					self.carryIcon.alpha = 0.75;
				}		
				
				self.isBombCarrier = true;
				
				spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
				assert( spawnPoints.size );
				
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
				
				if ( !level.pode_AB )
					self spawn( spawnpoint.origin, spawnpoint.angles );
				
				maps\mp\gametypes\_airborne::SpawnPlayer( level.pode_AB, spawnPoint, false );
				
				// airborne!
				if ( level.abfire == 1 )
					self enableWeapons();
			}
			else
			{
				self.isBombCarrier = false;
				
				// chão!
				spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( level.AtaqueSpawns );

				self spawn( spawnpoint.origin, spawnpoint.angles );
				
				maps\mp\gametypes\_airborne::SpawnPlayer( false, spawnPoint, false );

				MsgPlayer( self );
			}
		}

		// se já ordenou retreat testa se se salvou
		if ( level.mission_state == "retreat" )	
			self thread	PlayerRetreat();
	}
	level notify ( "spawned_player" );	
}

SpawnSoldado()
{
	self.isCommander = false;

	MsgPlayer( self );

	if ( level.mission_state == "general" )
		thread ShowVipName();
}

onPlayerDisconnect()
{
	// o prox a dar respawn será o novo Commander
	if ( isDefined( self.isCommander ) )
	{
		if ( self.isCommander == true )
		{
			DeletaDoc();
			self.isCommander = false;
			level.LiveVIP = false;
		}
	}
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	// mata hud bomba
	if ( isDefined( self.carryIcon ) )
		self.carryIcon destroyElem();	

	self thread CommanderDead();
}

// ==================================================================================================================
//   Docs
// ==================================================================================================================

CriaDocs( pos )
{
	level.FalaDocs = 0;

	pastaModel = "prop_suitcase_bomb";

	// pasta 1
	docs["pasta_trigger"] = spawn( "trigger_radius", pos, 0, 20, 100 );
	docs["pasta"][0] = spawn( "script_model", pos);
	docs["zone_trigger"] = spawn( "trigger_radius", pos, 0, 50, 100 );
	
	docs["pasta"][0] setModel( pastaModel );
	level.Docs = SpawnDocs( docs["pasta_trigger"], docs["pasta"] );	
}

SpawnDocs( trigger, visuals )
{
	pastaObject = maps\mp\gametypes\_gameobjects::createCarryObject( game["defenders"], trigger, visuals, (0,0,100) );
	pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
	pastaObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
	pastaObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );
		
	pastaObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" ); 
			
	pastaObject maps\mp\gametypes\_gameobjects::allowCarry( "any" );
	pastaObject maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
	   
	pastaObject.onPickup = ::onPickupDocs;
	pastaObject.onDrop = ::onDropDocs;
	pastaObject.allowWeapons = true;
	   
	return pastaObject;	
}

onPickupDocs( player )
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
	
	if ( team == game["attackers"] )
		player thread PlayerEscaped();

	player playLocalSound( "mp_suitcase_pickup" );
	
	// só fala
	if ( level.FalaDocs > 1 )
	{
		statusDialog( "hajas_control_won", team );	
		statusDialog( "hajas_control_lost", level.otherTeam[team] );
	}		
	level.FalaDocs++;
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	
	level.DocsTeam = team;
	
	// muda pro time que pegou
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
	
	if ( isDefined( player.isCommander ) && player.isCommander == false )
	{
		// muda pro outro time
		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_kill" );
	}
	
	if ( level.SidesMSG == 1 )
	{
		if ( team == game["attackers"] )
			player iPrintLnbold( level.mission_retreat );
	}


	if ( player.pickupScore == false )
	{
		player.pickupScore = true;
		maps\mp\gametypes\_globallogic::givePlayerScore( "pickup", player );
		player thread [[level.onXPEvent]]( "pickup" );	
	}
}

onDropDocs( player )
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

	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" ); 
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_capture" );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" );
}

DeletaDoc()
{
	level.Docs maps\mp\gametypes\_gameobjects::setDropped();
	level.Docs maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" ); 
	level.Docs maps\mp\gametypes\_gameobjects::allowCarry( "none" );
	level.Docs maps\mp\gametypes\_gameobjects::setModelVisibility( false );
}

// ==================================================================================================================
//   Escape Zone - Zulu
// ==================================================================================================================

ZuluSmoke() 
{
	// se já foi revelada aborta!
	if ( level.ZuluRevealedStartou == true )
		return;
		
	level.ZuluRevealedStartou = true;

	wait 2;
	
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
	if ( level.SidesMSG == 1 )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( player.pers["team"] == game["attackers"] )
				player iPrintLn( level.mission_retreat );
		}
	}
	playSoundOnPlayers( "mp_suitcase_pickup", game["attackers"] );
	wait 1;
	maps\mp\gametypes\_globallogic::leaderDialog( "ready_to_move",  game["attackers"] );
}

PlayerEscaped()
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
				DeletaDoc();
				Pontua( 10 );
				
				thread Retreat( self );	// todos agora podem fugir! nuke strike!
				
				if ( isDefined( self.carryIcon ) )
					self.carryIcon destroyElem();
				self.statusicon = "";
				if ( level.starstreak > 0 )
					self.fl_stars_pts = self.fl_stars_pts + 3;	
				self thread Salvo();
				maps\mp\gametypes\_globallogic::HajasDaScore( self, 50 );
				level.domFlags[0] maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
				return;
			} 
		}
		wait 1;
	}
}

PlayerRetreat()
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
				maps\mp\gametypes\_globallogic::HajasDaScore( self, 30 );
				self thread Salvo();
				return;
			} 
		}
		wait 1;
	}
}

// ==================================================================================================================
//   Retreat - Nuke
// ==================================================================================================================

Retreat( player )
{
	level endon ( "game_ended" );
	
	level.mission_state = "retreat";

	for ( index = 0; index < level.players.size; index++ )
	{
		if ( player != level.players[index] )
			level.players[index] notify("force_spawn");
	
		if ( level.players[index].team == game["attackers"] )
		{
			level.players[index] thread maps\mp\gametypes\_hud_message::oldNotifyMessage( level.mission_retreat, level.mission_hurry, undefined, (1, 0, 0), "mp_last_stand" );
			if ( player != level.players[index] )
			{
				level.players[index] thread	PlayerRetreat();
				MsgPlayer( level.players[index] );
			}
		}
	}

	maps\mp\gametypes\_globallogic::leaderDialog( "mission_success", game["attackers"] );
	maps\mp\gametypes\_globallogic::leaderDialog( "mission_failure", game["defenders"] );
	
	thread TocaAlarme();
		
	thread NukeStrike( player );
}

NukeStrike( player )
{
	level endon ( "game_ended" );
	
	level.CompleteClock = maps\mp\gametypes\_globallogic::getTimePassed();

	level.timeLimitOverride = true;
	level.inOvertime = true;

	espera = randomIntRange ( 40, 60 );
	
	waitTime = 0;
	while ( waitTime < 90 )
	{
		// clock
		waitTime += 1;
		setGameEndTime( getTime() + ((90-waitTime)*1000) );
		wait ( 1.0 );		
		
		// se tempo da bomba, executa bomba!
		if ( espera == waitTime )
			thread maps\mp\gametypes\_hardpoints::Nuke_doArtillery( level.defender_spawn, player, game["attackers"] );
	}	
}

Nuke( tempo )
{
	level endon( "game_ended" );
	
	wait tempo;
	
	level.nuke_started = true;
	
	rot = randomfloat(360);
	
	maps\mp\_utility::playSoundOnPlayers( game["nuke_incoming"] );
	setExpFog(0, 17000, 0.678352, 0.498765, 0.372533, 0.5);
	wait 1.5;
	level.chopperNuke = true;
	maps\mp\_utility::playSoundOnPlayers( game["nuke_01"] );
	maps\mp\_utility::playSoundOnPlayers( game["nuke_02"] );

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( isDefined(player.carryIcon) )
			player.carryIcon.alpha = 0;
	}
	
	thread nuke_earthquake();

	// Nuke FX
	nuke = spawnFx( level.nuke, level.defender_spawn, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( nuke );

	// Flash FX
	flash = spawnFx( level.nuke_flash, level.defender_spawn, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( flash );
		
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
	thread NukeDestruction(level.defender_spawn, 50000, 500, 400);	
	wait 5;
	
	level.nuke_started = false;
	
	MissionComplete();
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


nuke_earthquake()
{
	tempo = 0;
	while ( int(tempo) < 2 )
	{
		earthquake( .08, .05, level.defender_spawn, 80000);
		wait(.05);
		tempo = tempo + 0.1;
	}
	while( level.nuke_started == true )
	{
		earthquake( .5, 1, level.defender_spawn, 80000);
		wait(.05);
		earthquake( .25, .05, level.defender_spawn, 80000);
	}
}

Salvo()
{
	wait 0.5;
	[[level.spawnSpectator]]();
	
	Pontua( 1 );
	self allowSpectateTeam( "freelook", true );
	if ( level.starstreak > 0 )
		self.fl_stars_pts = self.fl_stars_pts + 3;
	
	self.statusicon = "specialty_longersprint";
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

// ==================================================================================================================
//   Game Over
// ==================================================================================================================

MissionComplete()
{
	// controle tempo
	if( game["roundsplayed"] == 0 )
	{
		SetDvar( "mission_time_A", Int( level.CompleteClock  / 1000) );
		SetDvar( "mission_time_A_full", ( level.CompleteClock / 1000) );
	}	
	else if( game["roundsplayed"] == 1 )
		SetDvar( "mission_time_B", Int( level.CompleteClock  / 1000) );
	
	setGameEndTime( 0 );
	sd_endGame( game["attackers"], level.assault_succeed + RelogioInt( level.CompleteClock  ) );
}

sd_endGame( winningTeam, endReasonText )
{
	setDvar( "ui_bomb_timer", 0 );
	
	maps\mp\gametypes\_globallogic::HajasRemoveHardpoints();
		
	if( getDvarInt("mission_time_A") > 0 && getDvarInt("mission_time_B") > 0 )	
	{
		Amin = Int(getDvarInt("mission_time_A")/60); 
		Bmin = Int(getDvarInt("mission_time_B")/60);
	
		if ( getDvarInt("mission_time_A") > getDvarInt("mission_time_B") )
		{
			bonus = 1 + Amin - Bmin;
			[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + bonus );
		}
		else if ( getDvarInt("mission_time_A") < getDvarInt("mission_time_B") )
		{
			bonus = 1 + Bmin - Amin;
			[[level._setTeamScore]]( level.otherTeam[winningTeam], [[level._getTeamScore]]( level.otherTeam[winningTeam] ) + bonus );
		}
	}

	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}

onTimeLimit()
{
	sd_endGame( game["defenders"], level.assault_failed );
}

onDeadEvent( team )
{
	if ( level.mission_state != "retreat" )
	{		
		if ( team == "all" )
			sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
		else if ( team == game["attackers"] )
			sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
		else if ( team == game["defenders"] )
			sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
	else
	{
		thread free_spec();
		return;		
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

onOneLeftEvent( team )
{
	if ( level.bombExploded == 2 )
		return;

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
	
	self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "last_alive" );
	
	self maps\mp\gametypes\_missions::lastManSD();
}

updateGametypeDvars()
{
	level.plantTime = dvarFloatValue( "planttime", 5, 0, 20 );
	level.defuseTime = dvarFloatValue( "defusetime", 10, 0, 20 );
	level.bombTimer = dvarFloatValue( "bombtimer", 45, 1, 300 );
}

// ==================================================================================================================
//   Bombing
// ==================================================================================================================

bombs()
{
	// controles
	level.bombExploded = 0;
	level.planted_A = false;
	level.planted_B = false;
	level.exploded_A = false;
	level.exploded_B = false;
	level.prorroga = false;
	level.sound_A = false;
	level.sound_B = false;
	
	if ( level.novos_objs )
		novos_sd();		
	
	level.bomb_pos = [];
	
	// define Commander
	level.commander = false;
	level.commander_vivo = true;
	
	level.lastStatus["allies"] = 0;
	level.lastStatus["axis"] = 0;

	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) )
	{
		//maps\mp\_utility::error("No sd_bomb_pickup_trig trigger found in map.");
		return;
	}

	visuals[0] = getEnt( "sd_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) )
	{
		//maps\mp\_utility::error("No sd_bomb script_model found in map.");
		return;
	}
	
	visuals[0] setModel( "prop_suitcase_bomb" );
	
	trigger delete();
	visuals[0] delete();	
	
	level.bombZones = [];
	
	bombZones = getEntArray( "bombzone", "targetname" );
	
	// A e B	// sd bombs
	for ( index = 0; index < bombZones.size; index++ )
	{
		trigger = bombZones[index];
		
		level.bomb_pos[level.bomb_pos.size] = trigger.origin;
		
		visuals = getEntArray( bombZones[index].target, "targetname" );
		
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
		bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
		label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
		bombZone.label = label;
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
		if ( index == 0 )
		{
			bombZone.onUse = ::onUsePlantObject_A;
			bombZone.onBeginUse = ::onBeginUse_A;
			bombZone.onEndUse = ::onEndUse_A;				
		}
		else
		{
			bombZone.onUse = ::onUsePlantObject_B;
			bombZone.onBeginUse = ::onBeginUse_B;
			bombZone.onEndUse = ::onEndUse_B;
		}
		bombZone.useWeapon = "briefcase_bomb_mp";
		
		for ( i = 0; i < visuals.size; i++ )
		{
			if ( isDefined( visuals[i].script_exploder ) )
			{
				bombZone.exploderIndex = visuals[i].script_exploder;
				break;
			}
		}
		
		level.bombZones[level.bombZones.size] = bombZone;
		
		bombZone.bombDefuseTrig = getent( visuals[0].target, "targetname" );
		assert( isdefined( bombZone.bombDefuseTrig ) );
		bombZone.bombDefuseTrig.origin += (0,0,-10000);
		bombZone.bombDefuseTrig.label = label;
	}

	for ( index = 0; index < level.bombZones.size; index++ )
	{
		array = [];
		for ( otherindex = 0; otherindex < level.bombZones.size; otherindex++ )
		{
			if ( otherindex != index )
				array[ array.size ] = level.bombZones[otherindex];
		}
		level.bombZones[index].otherBombZones = array;
	}		
	
	// inverte controle
	if( game["roundsplayed"] == 1 )
	{
		// trata tempo
		if( getDvarInt("mission_time_A") > 0 )
			setDvar( "ui_bomb_timer", 1 );
	}	
}

onBeginUse_A( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;
		level.sound_A = true;

		if ( isDefined( level.sdBombModel_A ) )
			level.sdBombModel_A hide();
	}
	else
	{
		player.isPlanting = true;
		statusDialog( "securing"+self.label, game["attackers"] );	
	}
}

onBeginUse_B( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;
		level.sound_B = true;
		
		if ( isDefined( level.sdBombModel_B ) )
			level.sdBombModel_B hide();
	}
	else
	{
		player.isPlanting = true;
		statusDialog( "securing"+self.label, game["attackers"] );	
	}
}

onEndUse_A( team, player, result )
{
	if ( !isAlive( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel_A ) && !result )
			level.sdBombModel_A show();
	}
}

onEndUse_B( team, player, result )
{
	if ( !isAlive( player ) )
		return;
		
	player.isDefusing = false;
	player.isPlanting = false;

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel_B ) && !result )
			level.sdBombModel_B show();
	}
}

onUsePlantObject_A( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted_A( self, player, self.label );
		player logString( "bomb planted!" );
		
		// gerencia bomba A
		level thread VoltaBomb_A( self );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
	}
}

onUsePlantObject_B( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted_B( self, player, self.label );
		player logString( "bomb planted!" );
		
		// gerencia bomba B
		level thread VoltaBomb_B( self );
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
	}
}

// --------------------------------------- DEFUSING ONLY - INICIO --------------------------------------------

onUseDefuseObject_A( player )
{
	wait .05;
	
	player notify ( "bomb_defused_A" );
	player logString( "bomb defused!" );
	level thread bombDefused_A();
	
	// disable this bomb zone
	self maps\mp\gametypes\_gameobjects::allowUse( "none" );
	self maps\mp\gametypes\_gameobjects::disableObject();
	
	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}

onUseDefuseObject_B( player )
{
	wait .05;
	
	player notify ( "bomb_defused_B" );
	player logString( "bomb defused!" );
	level thread bombDefused_B();

	// disable this bomb zone
	self maps\mp\gametypes\_gameobjects::allowUse( "none" );
	self maps\mp\gametypes\_gameobjects::disableObject();
		
	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}

// --------------------------------------- DEFUSING ONLY - FIM --------------------------------------------

onReset()
{
}

bombPlanted_A( destroyedObj_A, player, label )
{
	level.planted_A = true;
	statusDialog( "losing"+label, game["defenders"] );

	destroyedObj_A.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();
	level.tickingObject_A = destroyedObj_A.visuals[0];

	setDvar( "ui_bomb_timer", 1 );
	
	// calcula e faz a suitcase cair, etc...
	trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
	
	tempAngle = randomfloat( 360 );
	forward = (cos( tempAngle ), sin( tempAngle ), 0);
	forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );
	
	level.sdBombModel_A = spawn( "script_model", trace["position"] );
	level.sdBombModel_A.angles = dropAngles;
	level.sdBombModel_A setModel( "prop_suitcase_bomb" );

	// bomba por ser desarmada
	destroyedObj_A maps\mp\gametypes\_gameobjects::allowUse( "none" );
	destroyedObj_A maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	
	// create a new object to defuse with.
	trigger = destroyedObj_A.bombDefuseTrig;
	trigger.origin = level.sdBombModel_A.origin;

	visuals = [];
	defuseObject_A = maps\mp\gametypes\_gameobjects::createUseObjectMission( game["defenders"], trigger, visuals, (0,0,32), "A" );
	defuseObject_A maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	defuseObject_A maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	defuseObject_A maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	defuseObject_A maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	defuseObject_A maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" );
	defuseObject_A maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" );
	defuseObject_A maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" );
	defuseObject_A maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" );
	defuseObject_A.onBeginUse = ::onBeginUse_A;
	defuseObject_A.onEndUse = ::onEndUse_A;
	defuseObject_A.onUse = ::onUseDefuseObject_A;
	defuseObject_A.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.defuseObject_A = defuseObject_A;
	
	BombTimerWait_A();
	
	// se desarmaram a bomba, não explode
	if ( level.planted_A == false )
		return;
	
	level.exploded_A = true;
	
	setDvar( "ui_bomb_timer", 0 );
	
	destroyedObj_A.visuals[0] maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.gameEnded )
		return;
	
	level.bombExploded++;
	
	if ( level.bombExploded == 2 )
		thread LimpaIcons();
	
	explosionOrigin = level.sdBombModel_A.origin;
	level.sdBombModel_A hide();
	
	if ( isdefined( player ) )
		destroyedObj_A.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
	else
		destroyedObj_A.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread smokeFX(explosionOrigin,rot);
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj_A.exploderIndex ) )
		exploder( destroyedObj_A.exploderIndex );
	
	defuseObject_A maps\mp\gametypes\_gameobjects::disableObject();
		
	// diz q não tem mais nada plantado!
	level.planted_A = false;
	
	// dá 1 ponto a cada objetivo conquistado
	Pontua( 10 );	

	wait 1;	
	statusDialog( "secured"+label, game["attackers"] );
	statusDialog( "lost"+label, game["defenders"] );
}

bombPlanted_B( destroyedObj_B, player, label )
{
	level.planted_B = true;
	statusDialog( "losing"+label, game["defenders"] );

	destroyedObj_B.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();
	level.tickingObject_B = destroyedObj_B.visuals[0];

	setDvar( "ui_bomb_timer", 1 );
	
	// calcula e faz a suitcase cair, etc...
	trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
	
	tempAngle = randomfloat( 360 );
	forward = (cos( tempAngle ), sin( tempAngle ), 0);
	forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );
	
	level.sdBombModel_B = spawn( "script_model", trace["position"] );
	level.sdBombModel_B.angles = dropAngles;
	level.sdBombModel_B setModel( "prop_suitcase_bomb" );

	// bomba por ser desarmada
	destroyedObj_B maps\mp\gametypes\_gameobjects::allowUse( "none" );
	destroyedObj_B maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	
	// create a new object to defuse with.
	trigger = destroyedObj_B.bombDefuseTrig;
	trigger.origin = level.sdBombModel_B.origin;

	visuals = [];
	defuseObject_B = maps\mp\gametypes\_gameobjects::createUseObjectMission( game["defenders"], trigger, visuals, (0,0,32), "B" );
	defuseObject_B maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	defuseObject_B maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	defuseObject_B maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	defuseObject_B maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	defuseObject_B maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" );
	defuseObject_B maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" );
	defuseObject_B maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" );
	defuseObject_B maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" );
	defuseObject_B.onBeginUse = ::onBeginUse_B;
	defuseObject_B.onEndUse = ::onEndUse_B;
	defuseObject_B.onUse = ::onUseDefuseObject_B;
	defuseObject_B.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.defuseObject_B = defuseObject_B;	
	
	BombTimerWait_B();
	
	// se desarmaram a bomba, não explode
	if ( level.planted_B == false )
		return;	
	
	level.exploded_B = true;
	
	setDvar( "ui_bomb_timer", 0 );
	
	destroyedObj_B.visuals[0] maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.gameEnded )
		return;
	
	level.bombExploded++;
	
	if ( level.bombExploded == 2 )
		thread LimpaIcons();	
	
	explosionOrigin = level.sdBombModel_B.origin;
	level.sdBombModel_B hide();
	
	if ( isdefined( player ) && level.starstreak == 0 )
		destroyedObj_B.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
	else
		destroyedObj_B.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread smokeFX(explosionOrigin,rot);
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj_B.exploderIndex ) )
		exploder( destroyedObj_B.exploderIndex );
	
	defuseObject_B maps\mp\gametypes\_gameobjects::disableObject();
	
	// diz q não tem mais nada plantado!
	level.planted_B = false;
	
	// dá 1 ponto a cada objetivo conquistado
	Pontua( 10 );
	
	wait 1;
	statusDialog( "secured"+label, game["attackers"] );
	statusDialog( "lost"+label, game["defenders"] );	
}

ExecProrroga()
{
	wait 1;

	waitTime = 0;
	level.prorroga = true;
	
	// aguarda o tempo da bomba
	while ( waitTime < level.bombTimer )
	{
		waitTime += 1;
		wait ( 1.0 );
	}		

	// após o tempo termina o jogo se não tiver bombas plantadas
	if ( level.planted_A == false && level.planted_B == false )
	{
		wait 2;
		thread onTimeLimit();
	}
}

BombTimerWait_A()
{
	level endon("game_ended");
	level endon("bomb_defused_A");
	wait level.bombTimer;
}

BombTimerWait_B()
{
	level endon("game_ended");
	level endon("bomb_defused_B");
	wait level.bombTimer;
}

bombDefused_A()
{
	level.planted_A = false;

	level.tickingObject_A maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.sound_A == true )
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_defused" );

	level.sound_A = false;

	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused_A");
}

bombDefused_B()
{
	level.planted_B = false; 

	level.tickingObject_B maps\mp\gametypes\_globallogic::stopTickingSound();
	
	if ( level.sound_B == true )
		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_defused" );

	level.sound_B = false;

	setDvar( "ui_bomb_timer", 0 );
	
	level notify("bomb_defused_B");
}

VoltaBomb_A( bomb )
{
	level endon("game_ended");
	
	// disable this bomb zone
	bomb maps\mp\gametypes\_gameobjects::disableObject();
	
	while ( 1 )
	{
		if ( level.exploded_A == true )
			return;

		if ( level.planted_A == false )
		{
			// volta bomba
			bomb maps\mp\gametypes\_gameobjects::enableObject();
			bomb maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			bomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			return;
		}
		wait 1;
	}
}

VoltaBomb_B( bomb )
{
	level endon("game_ended");
	
	// disable this bomb zone
	bomb maps\mp\gametypes\_gameobjects::disableObject();
	
	while ( 1 )
	{
		if ( level.exploded_B == true )
			return;

		if ( level.planted_B == false )
		{
			// volta bomba
			bomb maps\mp\gametypes\_gameobjects::enableObject();
			bomb maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			bomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
			return;
		}
		wait 1;
	}
}

smokeFX( alvo, rot )
{
	alvo = alvo + (0,0,-100);
	smoke = spawnFx( level.smoke_tm, alvo, (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( smoke );
	earthquake( 1, 1.5, alvo, 8000 );
}

// ==================================================================================================================
//   Score
// ==================================================================================================================

Pontua( ponto )
{
	[[level._setTeamScore]]( game["attackers"], [[level._getTeamScore]]( game["attackers"] ) + ponto );
}

// ==================================================================================================================
//   Sound
// ==================================================================================================================

DizScore( team )
{	
	statusDialog( "obj_taken", team );
	statusDialog( "obj_lost", level.otherTeam[team] );
}

TocaAlarme()
{
	while ( level.inPrematchPeriod )
		wait ( 0.05 );
		
	wait 2;
		
	maps\mp\_utility::playSoundOnPlayers( game["nuke_alarm"] );
}

playSoundinSpace( alias, origin )
{
	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 10; // MP doesn't have "sounddone" notifies =(
	org delete();
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

// ==================================================================================================================
//   General
// ==================================================================================================================

defineIcons()
{
	// seta commander icons
	if( game["allies"] == "marines" )
	{
		level.hudcommander_allies = "faction_128_usmc";
		precacheStatusIcon( "faction_128_usmc" );
	}
	else
	{
		level.hudcommander_allies = "faction_128_sas";
		precacheStatusIcon( "faction_128_sas" );
	}
	
	if( game["axis"] == "russian" )
	{
		level.hudcommander_axis = "faction_128_ussr";
		precacheStatusIcon( "faction_128_ussr" );	
	}
	else
	{
		level.hudcommander_axis = "faction_128_arab";
		precacheStatusIcon( "faction_128_arab" );
	}
}

createVipIcon()
{
	wait 0.5;
	
	if ( isDefined( self.carryIcon ) )
			self.carryIcon destroyElem();	

	if( game["defenders"] == "allies" )
	{
		self.carryIcon = createIcon( level.hudcommander_allies, 50, 50 );
		level.status_icon = level.hudcommander_allies;
	}
	else
	{
		self.carryIcon = createIcon( level.hudcommander_axis, 50, 50 );
		level.status_icon = level.hudcommander_axis;
	}				
	
	self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
	self.carryIcon.alpha = 0.75;
	
	statusDialog( "boost", game["attackers"] );
	statusDialog( "losing", game["defenders"] );
	
	// carrega icon no placar
	self.statusicon = level.status_icon;
	
	if(isDefined(self.bIsBot) && self.bIsBot) 
	{
		wait 0.5;
		self TakeAllWeapons();
		self.weaponPrefix = "m4_reflex_mp";
		self.pers["weapon"] = "m4_reflex_mp";
	}		
}

CommanderDead()
{
	if ( isDefined( self.isCommander ) && self.isCommander == true )
	{
		//diz pro jogo que general está morto pra evitar que tenha outro!
		level.GeneralMorto = true;
		
		level.mission_state = "docs";
	
		// sounds
		maps\mp\_utility::playSoundOnPlayers( game["commander_killed"], game["attackers"] );
		maps\mp\_utility::playSoundOnPlayers( game["our_commander_is_dead"], game["defenders"] );

		// deixa de ser vip/commander
		self.isCommander = false;

		// diz q nao tem mais vip/Commander vivo
		level.LiveVIP = false;
		
		level.Docs maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		
		level notify("vip_is_dead");
		Pontua( 10 );		
	}
}

LimpaIcons()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( player.team == game["attackers"] )
		{
			if ( isDefined( player.carryIcon ) )
				player.carryIcon destroyElem();	
		}
	}
}

SpawnVIP()
{
	level.mission_state = "general";

	self.isCommander = true;
	
	if ( level.SidesMSG == 1 )
		self iPrintLnbold( level.assault_general );
	
	self thread defineIcons();

	// troca a skin pra VIP/Commander
	VIPloadModel(); 	
	
	// diz q o mapa já tem um vip/commander vivo
	level.LiveVIP = true;	
	
	// icone defend!
	//self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );
	
	// seta nome do Commander para mostrar na tela
	level.ShowName = self.name;	
	
	self thread createVipIcon();
}

ShowVipName()
{
	self endon ("disconnect");
	self endon ("death");
	self endon ( "game_ended" );

	wait 5;
	if ( !isDefined( level.ShowName ) )
		wait 5;

	if ( isDefined( level.ShowName ) )
	{
		msg_info = "^9" + level.ShowName + "^7 " + level.assault_is;
		self iPrintLn( msg_info );
	}
}

VIPloadModel()
{
	// salva classe original
	game["original_class_atual"] = self.pers["class"];

	self.pers["class"] = "CLASS_COMMANDER";
	self.class = "CLASS_COMMANDER";
	self.pers["primary"] = 0;
	self.pers["weapon"] = undefined;

	self maps\mp\gametypes\_class::setClass( self.pers["class"] );
	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
	self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
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

RelogioInt ( tempo )
{
	tempo = Int(tempo / 1000);
	minutos = int(tempo / 60);
	segundos = tempo - (minutos * 60);
	if ( segundos < 10 )
		segundos = "0" + segundos;

	relogio = minutos + ":" + segundos;
	return relogio;
}

Relogio( tempo )
{
	minutos = int(tempo / 60);
	segundos = tempo - (minutos * 60);
	if ( segundos < 10 )
		segundos = "0" + segundos;

	relogio = minutos + ":" + segundos;
	return relogio;
}

// ==================================================================================================================
//   Mensagens
// ==================================================================================================================

MsgPlayer( player )
{
	if ( level.SidesMSG == 1 )
	{
		team = player.team;
		
		if ( level.mission_state == "lz" )
		{
			if ( team == game["attackers"] )
				player iPrintLnbold( level.mission_sec_lz );
			else if ( team == game["defenders"] )
				player iPrintLnbold( level.mission_pro_lz );
		}
		else if ( level.mission_state == "bombs" )
		{
		
		}
		else if ( level.mission_state == "general" )
		{
			if ( team == game["attackers"] )
			{
				if ( isDefined( self.carryIcon ) )
					self.carryIcon destroyElem();		
			
				player iPrintLnbold( level.assault_kill );
			}
			else if ( team == game["defenders"] )
				player iPrintLnbold( level.assault_protect );
		}
		else if ( level.mission_state == "docs" )
		{
			if ( team == game["attackers"] )
			{
				if ( isDefined( self.carryIcon ) )
					self.carryIcon destroyElem();		
			
				player iPrintLnbold( level.mission_docs_get );
			}
			else if ( team == game["defenders"] )
				player iPrintLnbold( level.mission_docs_pro );
		}
		else if ( level.mission_state == "retreat" )
		{
			if ( team == game["attackers"] )
			{
				if ( isDefined( self.carryIcon ) )
					self.carryIcon destroyElem();		
			
				player iPrintLnbold( level.mission_retreat );
			}		
		}
	}
}

SetaMensagens()
{
	if ( getDvar( "scr_mission_general" ) == "" )
		level.assault_general =  "^7You are the ^9General^7!";
	else
		level.assault_general = getDvar( "scr_mission_general" );
	
	if ( getDvar( "scr_mission_protect" ) == "" )
		level.assault_protect =  "^7Protect the ^9General^7!";
	else
		level.assault_protect = getDvar( "scr_mission_protect" );

	if ( getDvar( "scr_mission_kill" ) == "" )
		level.assault_kill =  "^7Kill the ^9General^7!";
	else
		level.assault_kill = getDvar( "scr_mission_kill" );

	if ( getDvar( "scr_mission_is" ) == "" )
		level.assault_is =  "is the ^9General^7!";
	else
		level.assault_is = getDvar( "scr_mission_is" );
	
	if ( getDvar( "scr_mission_succeed" ) == "" )
		level.assault_succeed =  "Mission Succeed in ";
	else
		level.assault_succeed = getDvar( "scr_mission_succeed" ) + " ";
	
	if ( getDvar( "scr_mission_failed" ) == "" )
		level.assault_failed =  "Mission Failed";
	else
		level.assault_failed = getDvar( "scr_mission_failed" );

	if ( getDvar( "scr_mission_sec_lz" ) == "" )
		level.mission_sec_lz =  "^7Secure the ^9Drop Zone^7!";
	else
		level.mission_sec_lz = getDvar( "scr_mission_sec_lz" );
	
	if ( getDvar( "scr_mission_pro_lz" ) == "" )
		level.mission_pro_lz =  "^7Defend the ^9Drop Zone^7!";
	else
		level.mission_pro_lz = getDvar( "scr_mission_pro_lz" );
	
	if ( getDvar( "scr_mission_docs_pro" ) == "" )
		level.mission_docs_pro =  "^7Protect our ^9Docs^7!";
	else
		level.mission_docs_pro = getDvar( "scr_mission_docs_pro" );
	
	if ( getDvar( "scr_mission_docs_get" ) == "" )
		level.mission_docs_get =  "^7Get Enemy's ^9Intel^7!";
	else
		level.mission_docs_get = getDvar( "scr_mission_docs_get" );
	
	if ( getDvar( "scr_mission_retreat" ) == "" )
		level.mission_retreat =  "Retreat!";
	else
		level.mission_retreat = getDvar( "scr_mission_retreat" );

	if ( getDvar( "scr_mission_hurry" ) == "" )
		level.mission_hurry =  "Go Go Go! Move Out!";
	else
		level.mission_hurry = getDvar( "scr_mission_hurry" );
}

HajasRemoveHardpoints()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
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

TestaAirborne( map, gt )
{
	// se mapa está na lista tem problema
	if( getDvar( map ) != "" )
	{
		// le GTs do respectivo mapa
		map_gts = getDvar( map );
		
		// se não estiver vazio testa se GT é válido
		if ( map_gts != "" )
		{
			// testa se tem * pra ver se é excessão
			if( isSubstr( map_gts , "*" ) )
			{
				// se mapa está na lista, tem q trocar
				if( isSubstr( map_gts , gt ) )
					return false;
			}
			else
			{
				// se mapa NÃO está na lista, tem q trocar
				if( !isSubstr( map_gts , gt ) )
					return false;
			}
		}
	}
	return true;
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
	if ( level.flags.size == 0 ) // sem flag muda gt
	{
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );
		return;	
	}

	if ( getDvarInt("fl_bots") == 1 && getDvarInt("bot_ok") == true )
	{
		id_a = RandomInt(level.xsd_a.size);
		while ( ObjValido(level.xsd_a[id_a]) == false || distance( level.xsd_a[id_a], level.flags[0].origin ) < 500 )
		{
			id_a = RandomInt(level.xsd_a.size);
			//logprint( "======================== Não Válido A!!! " + "\n");
		}
		exesd( level.xsd_a[id_a], 1 );	
		
		id_b = RandomInt(level.xsd_b.size);
		while ( ObjValido(level.xsd_b[id_b]) == false || distance( level.xsd_b[id_b], level.flags[0].origin ) < 500 )
		{
			id_b = RandomInt(level.xsd_b.size);
			//logprint( "======================== Não Válido B!!! " + "\n");
		}
		exesd( level.xsd_b[id_b], 2 );		
	}
	else
	{
		posA = level.xsd_a[RandomInt(level.xsd_a.size)];
		posB = level.xsd_b[RandomInt(level.xsd_b.size)];
		
		while ( distance( posA, level.flags[0].origin ) < 500 )
			posA = level.xsd_a[RandomInt(level.xsd_a.size)];
			
		while ( distance( posB, level.flags[0].origin ) < 500 )
			posB = level.xsd_b[RandomInt(level.xsd_b.size)];
			
		exesd( posA, 1 );
		exesd( posB, 2 );
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

novos_flag_init()
{
	level.novos_objs = true;

	temp = GetDvar ( "xflag_" + 0 );
	if ( temp == "" )
	{
		level.novos_objs = false;	
		return;
	}
	
	xflag(); // cria listas com pos
		
	StartNewFlags(); //	cria novas flags
}

xflag()
{
	dist_max = distance(level.attack_spawn, level.defender_spawn)/5;
	dist_max = dist_max * 2;
	
	primaryFlags = getEntArray( "flag_primary", "targetname" );
	secondaryFlags = getEntArray( "flag_secondary", "targetname" );
	
	if ( (primaryFlags.size + secondaryFlags.size) < 2 )
	{
		printLn( "^1Not enough domination flags found in level!" );
		temp = strtok( level.BasicGametypes, " " );
		SetDvar( "fl", temp[RandomInt(temp.size)] );

		return;
	}
	
	level.flags = [];
	for ( index = 0; index < primaryFlags.size; index++ )
		level.flags[level.flags.size] = primaryFlags[index];
	
	for ( index = 0; index < secondaryFlags.size; index++ )
		level.flags[level.flags.size] = secondaryFlags[index];
		
	level.NumFlagsOri = level.flags.size;
	level.xflag_unica = [];		
	level.xflag_selected = [];
	
	flag_a = level.flags[0];
	flag_b = level.flags[1];
	flag_c = level.flags[2];
	if ( level.NumFlagsOri > 3 )
		flag_d = level.flags[3];
	else
		flag_d = undefined;		
	if ( level.NumFlagsOri > 4 )	
		flag_e = level.flags[4];
	else
		flag_e = undefined;		
		
	FlagCentral = SelecionaFlag();
	if ( level.script == "mp_burg" )
	{
		level.xflag_unica[level.xflag_unica.size] = FlagCentral.origin + (0, 0, 60);
	}
	else
	{
		if( ( distance ( flag_a.origin, level.attack_spawn) > dist_max ) && ( distance ( flag_a.origin, level.defender_spawn) > dist_max ) )
			level.xflag_unica[level.xflag_unica.size] = flag_a.origin + (0, 0, 60);
		if( ( distance ( flag_b.origin, level.attack_spawn) > dist_max ) && ( distance ( flag_b.origin, level.defender_spawn) > dist_max ) )
			level.xflag_unica[level.xflag_unica.size] = flag_b.origin + (0, 0, 60);		
		if( ( distance ( flag_c.origin, level.attack_spawn) > dist_max ) && ( distance ( flag_c.origin, level.defender_spawn) > dist_max ) )
			level.xflag_unica[level.xflag_unica.size] = flag_c.origin + (0, 0, 60);	
			
		if ( level.NumFlagsOri > 3 )		
		{
			if( ( distance ( flag_d.origin, level.attack_spawn) > dist_max ) && ( distance ( flag_d.origin, level.defender_spawn) > dist_max ) )
				level.xflag_unica[level.xflag_unica.size] = flag_d.origin + (0, 0, 60);		
		
			if ( level.NumFlagsOri > 4 )
			{
				if( ( distance ( flag_e.origin, level.attack_spawn) > dist_max ) && ( distance ( flag_e.origin, level.defender_spawn) > dist_max ) )
					level.xflag_unica[level.xflag_unica.size] = flag_e.origin + (0, 0, 60);		
			}
		}
	}

	level.flags = [];

	gerando = true;
	index = 0;
	
	while (gerando)
	{
		temp = GetDvar ( "xflag_" + index );
		if ( temp == "eof" )
			gerando = false;
		else
		{
			temp = strtok( temp, "," );
			pos = (int(temp[0]),int(temp[1]),int(temp[2]));
						
			if ( level.script == "mp_burg" )
			{
				if( ( distance ( pos, FlagCentral.origin) < 2000 ) )
					level.xflag_unica[level.xflag_unica.size] = pos;
			}				
			else
			{
				if( ( distance ( pos, level.attack_spawn) > dist_max ) && ( distance ( pos, level.defender_spawn) > dist_max ) )
					level.xflag_unica[level.xflag_unica.size] = pos;
			}
		}	
		index++;
	}
	
	// escolhe flags ABC
	
	if( game["roundsplayed"] == 0 )
	{
		game["mission_flag"] = RandomInt(level.xflag_unica.size);
		id_a = game["mission_flag"];
	}
	else
	{
		id_a = game["mission_flag"];
	}
		
	level.xflag_selected[0] = level.xflag_unica[id_a];
	level.xflag_unica = removeFlagArray(level.xflag_unica, id_a);
}

StartNewFlags()
{
	thread update_linkName();	
	
	level.labels = [];
	level.labels[0] = "a";
	level.labels[1] = "b";
	level.labels[2] = "c";
	level.labels[3] = "d";
	level.labels[4] = "e";
		
	thread update_linkTo();
}

move_flag()
{
	exeflag( level.xflag_selected[0], 0 );
}

exeflag( pos, flag )
{
	trig_a = undefined;
	trig_b = undefined;
	trig_c = undefined;
	trig_d = undefined;
	trig_e = undefined;
	
	//logPrint("=-=-=-=-=-=-= pos = " + pos + " | flag = " + flag + "\n");
	
	pos = (int(pos[0]),int(pos[1]),int(pos[2]));
	
	for(i=0 ; i<level.flags.size ; i++)
	{
		if ( i == 0 )
			trig_a = level.flags[i];
		else if ( i == 1 ) 
			trig_b = level.flags[i];
		else if ( i == 2 ) 
			trig_c = level.flags[i];
		else if ( i == 3 ) 
			trig_d = level.flags[i];
		else if ( i == 4 ) 
			trig_e = level.flags[i];
	}
	
	if ( flag == 0 ) // a
	{
		obj_a_origin = pos + (0, 0, -60);
	
		trig_a.origin = obj_a_origin;
		
		if ( isDefined( trig_a.target ) )
		{
			a_obj_entire = getent( trig_a.target, "targetname" );
			a_obj_entire.origin = obj_a_origin;
		}
	}
	else if ( flag == 1 ) // b
	{
		obj_b_origin = pos + (0, 0, -60);
	
		trig_b.origin = obj_b_origin;
		
		if ( isDefined( trig_b.target ) )
		{
			b_obj_entire = getent( trig_b.target, "targetname" );
			b_obj_entire.origin = obj_b_origin;		
		}
	}
	else if ( flag == 2 ) // c
	{
		obj_c_origin = pos + (0, 0, -60);
	
		trig_c.origin = obj_c_origin;
		
		if ( isDefined( trig_c.target ) )
		{
			c_obj_entire = getent( trig_c.target, "targetname" );
			c_obj_entire.origin = obj_c_origin;		
		}
	}	
	else if ( flag == 3 ) // d
	{
		obj_d_origin = pos + (0, 0, -60);
	
		trig_d.origin = obj_d_origin;
		
		if ( isDefined( trig_d.target ) )
		{
			d_obj_entire = getent( trig_d.target, "targetname" );
			d_obj_entire.origin = obj_d_origin;		
		}
	}		
	else if ( flag == 4 ) // e
	{
		obj_e_origin = pos + (0, 0, -60);
	
		trig_e.origin = obj_e_origin;
		
		if ( isDefined( trig_e.target ) )
		{
			e_obj_entire = getent( trig_e.target, "targetname" );
			e_obj_entire.origin = obj_e_origin;		
		}
	}		
}

update_linkName()
{
	label = level.labels;
	
	flags = getentarray( "flag_primary", "targetname" );
	descriptors = getentarray( "flag_descriptor", "targetname" );
	
	//logPrint("=-=-=-=-=-=-=update_linkName - descriptors.size = " + descriptors.size + "\n");
	
	for(i=0 ; i<flags.size ; i++)
	{
		for(j=0 ; j<descriptors.size ; j++)
		{
			if( distance( flags[i].origin, descriptors[j].origin ) <= 200 )
			{
				descriptors[j].script_linkName = get_flag_number( flags[i].script_label );
				break;
			}
		}
	}
}

get_flag_number( label )
{
	switch( label )
	{
		case "_a" : num = "flag1"; break;
		case "_b" : num = "flag2"; break;
		case "_c" : num = "flag3"; break;
		case "_d" : num = "flag4"; break;
		case "_e" : num = "flag5"; break;
		default : num = "flag9";
	}
	
	return num;
}

update_linkTo()
{
	descriptors = getentarray( "flag_descriptor", "targetname" );
	dist = [];
	
	//logPrint("=-=-=-=-=-=-=update_linkTo - descriptors.size = " + descriptors.size + "\n");
	
	for(i=0 ; i<descriptors.size ; i++)
	{
		for(j=0 ; j<descriptors.size ; j++)
		{
			if( j != i )
				dist[i][j] = distance( descriptors[i].origin, descriptors[j].origin );
			else
				dist[i][j] = 100000;
		}
		
		nearest = undefined;
		
		for(j=0 ; j<dist[i].size ; j++)
		{
			if( isdefined( dist[i][j] ) )
			{
				if( !isdefined( nearest ) )
					nearest = (dist[i][j], 0, 100);
				
				if( dist[i][j] < nearest[0] )
					nearest = (dist[i][j], j, 100);		
			}
		}
		
		for(j=0 ; j<dist[i].size ; j++)
		{
			if( isdefined( dist[i][j] ) && j != nearest[1] )
			{
				if( dist[i][j] <= (110*nearest[0]/100) )
					nearest = (nearest[0], nearest[1], j);
			}
		}
		
		linkto = "";
		
		if( nearest[2] == 100 )
			linkto = descriptors[int(nearest[1])].script_linkName;
		
		else if( nearest[2] < 100 )
			linkto = descriptors[int(nearest[1])].script_linkName+" "+descriptors[int(nearest[2])].script_linkName;
			
		descriptors[i].script_linkTo = linkto;
	}
}

removeFlagArray( array, index )
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